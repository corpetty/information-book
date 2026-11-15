#!/usr/bin/env node
// Repair smart quotes in the built site (site/public/).
//
// Why this exists: Quartz 5.1's Markdown pipeline (GitHubFlavoredMarkdown 2.x
// SmartyPants + ObsidianFlavoredMarkdown 2.x wikilinks) curls quotes one text
// node at a time, so a quote that touches a link is decided without its
// neighbour. On this site that produced, against the 5.0 build:
//   - a backwards apostrophe after a link:   [[x|Chapter 10]]'s  →  Chapter 10‘s
//   - a backwards quote before a link or at the start of a heading:
//                                            "[[x|bridge nodes]] …"  →  ”bridge nodes …
//   - straight apostrophes left inside link text:  Goodhart's law
// The prose is written with straight quotes and relies on the build to curl
// them, so the fix is applied to the output, not the source.
//
// What it does: walks every HTML page, and for each quote character in body
// text decides its direction from the visible characters on either side,
// looking across inline tags. Code, scripts, styles and math are skipped;
// attributes are never touched. Idempotent. Remove this step (and its line
// in the Makefile's site-build) once upstream curls across inline nodes.
//
// Usage: node scripts/fix-typography.js [--check]
//   --check   report what would change and exit 1 if anything would

import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join, relative } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const publicDir = resolve(__dirname, '..', 'site', 'public');
const CHECK = process.argv.includes('--check');

if (!existsSync(publicDir)) {
  console.error('fix-typography: site/public/ not found — run the Quartz build first');
  process.exit(1);
}

// Staged apps (the ontology viewer, the talk) and Quartz's own assets are not prose.
const SKIP_DIRS = new Set(['graph', 'talk', 'data', 'static']);
// Elements whose text is not prose.
const SKIP_TAGS = new Set(['script', 'style', 'code', 'pre', 'kbd', 'samp', 'textarea', 'svg', 'math', 'template']);
// Tags that start a new run of text: a quote right after one is at the start.
const BLOCK_TAGS = new Set([
  'p', 'div', 'li', 'ul', 'ol', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'td', 'th', 'tr', 'table',
  'section', 'article', 'header', 'footer', 'nav', 'aside', 'main', 'br', 'hr', 'dd', 'dt', 'dl', 'figure',
  'figcaption', 'summary', 'details', 'body', 'button', 'label', 'title',
]);

const SINGLE = /^(?:'|&#x27;|&#39;|&apos;|‘|’)/;
const DOUBLE = /^(?:"|&quot;|&#34;|&#x22;|“|”)/;
const isWord = (c) => !!c && /[\p{L}\p{N}]/u.test(c);
const isOpenContext = (c) => !c || /[\s([{—–\-/]/.test(c) || c === '“' || c === '‘';

function walk(dir, out = []) {
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const p = join(dir, e.name);
    if (e.isDirectory()) {
      if (dir === publicDir && SKIP_DIRS.has(e.name)) continue;
      walk(p, out);
    } else if (e.name.endsWith('.html')) out.push(p);
  }
  return out;
}

// Split into tags and text. Comments and doctype count as tags. A tag may
// carry `>` inside a quoted attribute value (the explorer serialises arrow
// functions into data attributes), so attribute values are matched as units:
// stopping at the first `>` would treat the rest of the attribute as text and
// curl the quotes inside it.
const TOKEN = /<!--[\s\S]*?-->|<(?:[^>"']|"[^"]*"|'[^']*')*>|[^<]+/g;

function fixHtml(html) {
  const bodyAt = html.search(/<body[\s>]/i);
  if (bodyAt < 0) return { html, changes: 0 };
  const head = html.slice(0, bodyAt);
  const tokens = html.slice(bodyAt).match(TOKEN) || [];

  // Which text tokens are prose? Track skipped elements (by nesting depth of
  // the same tag name, so a skipped <span class="katex"> with spans inside
  // ends at the right place).
  const prose = new Array(tokens.length).fill(false);
  const blockBefore = new Array(tokens.length).fill(false);
  let skip = null; // { tag, depth }
  let sawBlock = true;
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (t[0] !== '<') {
      prose[i] = !skip;
      blockBefore[i] = sawBlock;
      if (!skip && t.trim()) sawBlock = false;
      continue;
    }
    const m = t.match(/^<\s*(\/)?\s*([a-zA-Z][\w-]*)/);
    if (!m) continue; // comment / doctype
    const closing = !!m[1], tag = m[2].toLowerCase(), selfClosing = /\/\s*>$/.test(t);
    if (skip) {
      if (tag === skip.tag && !selfClosing) {
        skip.depth += closing ? -1 : 1;
        if (skip.depth === 0) skip = null;
      }
      continue;
    }
    if (BLOCK_TAGS.has(tag)) sawBlock = true;
    if (!closing && !selfClosing && (SKIP_TAGS.has(tag) || /\bclass="[^"]*\bkatex\b/.test(t))) {
      skip = { tag, depth: 1 };
    }
  }

  // Next visible character after position `pos` in token `i`, across inline
  // tags, stopping at a block boundary.
  function nextVisible(i, pos) {
    let rest = tokens[i].slice(pos);
    for (let j = i; ; ) {
      if (rest) {
        const ent = rest.match(/^&(?:#x?[0-9a-f]+|[a-z]+);/i);
        return ent ? decode(ent[0]) : rest[0];
      }
      for (j++; j < tokens.length && tokens[j][0] === '<'; j++) {
        const m = tokens[j].match(/^<\s*\/?\s*([a-zA-Z][\w-]*)/);
        if (m && BLOCK_TAGS.has(m[1].toLowerCase())) return '';
      }
      if (j >= tokens.length || !prose[j]) return '';
      rest = tokens[j];
    }
  }

  let changes = 0;
  let prev = ''; // last visible character, '' at the start of a block
  for (let i = 0; i < tokens.length; i++) {
    if (tokens[i][0] === '<') continue;
    if (blockBefore[i]) prev = '';
    if (!prose[i]) { prev = 'x'; continue; }
    const text = tokens[i];
    let out = '';
    for (let pos = 0; pos < text.length; ) {
      const rest = text.slice(pos);
      const sm = rest.match(SINGLE), dm = sm ? null : rest.match(DOUBLE);
      if (!sm && !dm) {
        const ent = rest.match(/^&(?:#x?[0-9a-f]+|[a-z]+);/i);
        const piece = ent ? ent[0] : rest[0];
        out += piece;
        prev = ent ? decode(piece) : piece;
        pos += piece.length;
        continue;
      }
      const raw = (sm || dm)[0];
      const next = nextVisible(i, pos + raw.length);
      let want;
      if (sm) {
        // After a letter, digit or punctuation it is an apostrophe or a
        // closing quote; at the start of a run it opens a quote. (An elided
        // decade, '90s, would come out as an opening quote; the book has
        // none, and a quoted figure such as '10,000 hours' is far likelier.)
        want = (isWord(prev) || !isOpenContext(prev)) ? '’' : '‘';
      } else {
        // Opens at the start of a run (unless nothing follows it), closes otherwise.
        want = isOpenContext(prev) && next ? '“' : '”';
      }
      if (raw !== want) changes++;
      out += want;
      prev = want;
      pos += raw.length;
    }
    tokens[i] = out;
  }
  return { html: head + tokens.join(''), changes };
}

function decode(ent) {
  const named = { '&amp;': '&', '&lt;': '<', '&gt;': '>', '&quot;': '"', '&apos;': "'", '&nbsp;': ' ', '&#x27;': "'", '&#39;': "'" };
  if (named[ent]) return named[ent];
  const m = ent.match(/^&#(x?)([0-9a-f]+);$/i);
  return m ? String.fromCodePoint(parseInt(m[2], m[1] ? 16 : 10)) : 'x';
}

let total = 0, files = 0;
const touched = [];
for (const file of walk(publicDir)) {
  const before = readFileSync(file, 'utf8');
  const { html, changes } = fixHtml(before);
  if (!changes) continue;
  total += changes;
  files++;
  touched.push(`${relative(publicDir, file)} (${changes})`);
  if (!CHECK) writeFileSync(file, html);
}

console.log(`fix-typography: ${total} quote${total === 1 ? '' : 's'} ${CHECK ? 'would be corrected' : 'corrected'} in ${files} page${files === 1 ? '' : 's'}`);
if (process.argv.includes('--verbose')) for (const t of touched) console.log(`  ${t}`);
if (CHECK && total) process.exit(1);
