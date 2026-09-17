#!/usr/bin/env node
// Prose lint for the book's reader-facing markdown.
//
// Report-only (exit 0). Scans every top-level content/*.md and prints, per
// file, the density of the tics a September 2026 editorial audit found
// running through the drafts:
//
//   self-narration    the prose talking about itself as an artifact —
//                     "this chapter argues", "the book has committed",
//                     "the X claim, said plain", "I should be honest" …
//   reversal          "not X but Y" / "isn't X; it's Y" / "X is not a Y. It is a Z."
//   tic vocabulary    load-bearing, exactly, quietly, substrate, at scale,
//                     precisely, the honest version, does real work …
//   perfect-tense forward refs
//                     "Chapter 10 worked out" written in a chapter the
//                     reader meets *before* Chapter 10 (house style: signpost
//                     forward in present tense — see PROSE-DECISIONS.md §G2)
//   bold / parens / colons
//                     per-1000-word density of **bold sentences**,
//                     parenthetical asides, and colon-joined clauses
//   uncertainty       words inside the "Where I'm still uncertain" tail
//   unlinked terms    graph-node terms (concepts/cases/mechanisms/questions)
//                     used in the file but never [[wikilinked]]
//   frontmatter       whether `description:` / `aliases:` are present
//
// Usage:
//   node scripts/lint-prose.js                 summary table, all files
//   node scripts/lint-prose.js --verbose       + every hit with line numbers
//   node scripts/lint-prose.js --file=<name>   one file (basename, .md optional)
//   node scripts/lint-prose.js --json          machine-readable
//
// Via make: `make lint-prose`, `make lint-prose FILE=political-economy-of-attention`.

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, basename, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const contentDir = resolve(repoRoot, 'content');
const dataDir = resolve(repoRoot, 'data');

const args = process.argv.slice(2);
const VERBOSE = args.includes('--verbose') || args.includes('-v');
const JSON_OUT = args.includes('--json');
const fileArg = (args.find(a => a.startsWith('--file=')) || '').slice(7);

// Author-facing or non-prose files: reported, but flagged as such.
const AUTHOR_FACING = new Set(['outline.md', 'general-theme.md']);
const SKIP = new Set([]);

// ------------------------------------------------------------ pattern sets

const SELF_NARRATION = [
  /\b(this|the) chapter('s)?\b/gi,
  /\bthe book('s)? (has|had|is|was|will|needs|wants|argues|commits|committed|treats|calls|lands|leans|says|said|does|did|cares|gets)\b/gi,
  /\bthe (\S+ )?claim, said plain\b/gi,
  /\bsaid plain\b/gi,
  /\bI should (be honest|mark|say|flag|note)\b/gi,
  /\bthe chapter, whole\b/gi,
  /\b(this|the) (note|section)('s)? (argues|has|is going to|wants|needs|does|will)\b/gi,
  /\b(flag|flagged) for (later|a later pass)\b/gi,
  /\b(earlier|previous|prior) drafts? of this\b/gi,
  /\bthe outline (calls|wants|says|has)\b/gi,
  /\binterpretive triples?\b/gi,
  /\bextraction (agent|pass)\b/gi,
];

const REVERSAL = [
  /\bnot (a |an |the )?[\w' -]{3,40}? but (a |an |the )?\w/gi,
  /\b(is|are|was|were)n'?t (a |an |the )?[\w' -]{3,40}?; (it|they|that)('s| is| are)\b/gi,
  /\b(is|are) not (a |an |the )?[\w' -]{3,40}?\. (It|They|That) (is|are)\b/g,
  /\bless (a |an )?[\w' -]{3,30}? than (a |an )?\w/gi,
];

const TICS = {
  'load-bearing': /\bload-bearing\b/gi,
  'exactly': /\bexactly\b/gi,
  'quietly': /\bquietly\b/gi,
  'substrate': /\bsubstrate\b/gi,
  'at scale': /\bat (population |planetary |industrial |network |civilization(al)? )?scale\b/gi,
  'precisely': /\bprecisely\b/gi,
  'the honest': /\bthe honest (version|answer|part|reading|form|name|move)\b/gi,
  'real work': /\b(does|doing|do|did) (real|the|its|all the) work\b/gi,
  'sharpens': /\bsharpen(s|ed)?\b/gi,
  'collapses into': /\bcollapses? (into|to)\b/gi,
  'names': /\b(names|naming) (this|that|the|it|exactly)\b/gi,
  'the whole game': /\bthe whole (game|point|story)\b/gi,
  'in practice': /\bin practice\b/gi,
};

const UNCERTAIN_HEADING = /^##+ .*(uncertain|open (question|thread|edge)|still (open|working)|where I)/i;

// ------------------------------------------------------------ chapter order

function loadChapterOrder() {
  // file basename -> reading ordinal (5b/5c count as 5.x). Foundational notes
  // have no ordinal; their forward refs are not checked for tense.
  const chapters = JSON.parse(readFileSync(join(dataDir, 'chapters.json'), 'utf8'));
  const notes = JSON.parse(readFileSync(join(dataDir, 'notes.json'), 'utf8'));
  const noteFile = new Map();
  for (const n of (notes.notes || notes)) noteFile.set('note:' + n.slug, n.file || `${n.slug}.md`);
  const byFile = new Map();
  for (const c of (chapters.chapters || chapters)) {
    const file = noteFile.get(c.draftNote) || null;
    if (!file) continue;
    const m = String(c.number).match(/^(\d+)([a-z]?)$/);
    const ord = m ? Number(m[1]) + (m[2] ? (m[2].charCodeAt(0) - 96) / 10 : 0) : null;
    byFile.set(basename(file), { number: String(c.number), ord });
  }
  return byFile;
}

// ------------------------------------------------------------ node terms

function loadNodeTerms() {
  const pages = [];
  for (const d of ['concepts', 'cases', 'mechanisms', 'questions']) {
    const dir = join(contentDir, d);
    if (!existsSync(dir)) continue;
    for (const f of readdirSync(dir)) {
      if (!f.endsWith('.md')) continue;
      const t = readFileSync(join(dir, f), 'utf8');
      const slug = f.replace(/\.md$/, '');
      const fm = t.match(/^---\n([\s\S]*?)\n---/);
      let aliases = [];
      let title = slug;
      if (fm) {
        const m = fm[1].match(/aliases:\n((?:  - .*\n?)+)/);
        if (m) aliases = m[1].split('\n').filter(Boolean).map(s => s.replace(/^  - /, '').replace(/^"|"$/g, ''));
        const tm = fm[1].match(/title: "?(.*?)"?\n/);
        if (tm) title = tm[1];
      }
      const terms = [...new Set([title, ...aliases])].filter(x => x.length > 4);
      pages.push({ slug, dir: d, terms });
    }
  }
  return pages;
}

const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// ------------------------------------------------------------ analysis

function splitFrontmatter(raw) {
  const m = raw.match(/^---\n([\s\S]*?)\n---\n?/);
  return m ? { fm: m[1], body: raw.slice(m[0].length), fmLines: m[0].split('\n').length - 1 } : { fm: '', body: raw, fmLines: 0 };
}

function countHits(body, regexes, offset) {
  const hits = [];
  const lines = body.split('\n');
  let inCode = false;
  lines.forEach((line, i) => {
    if (/^```/.test(line)) { inCode = !inCode; return; }
    if (inCode) return;
    for (const re of regexes) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(line)) !== null) {
        hits.push({ line: i + 1 + offset, text: m[0] });
        if (!re.global) break;
      }
    }
  });
  return hits;
}

function forwardRefs(body, ord, offset) {
  if (ord == null) return [];
  const re = /\b(Ch(?:apter)?\.? ?(\d+)([a-z])?)(?:'s)? (?:(?:argument|story|answer|claim|prescription|design principles?)\s+)?(worked out|argued|showed|told|said|made|established|laid out|gave|did|closed|resolved|settled|diagnosed|built|described|named|set up|introduced|was|were|had)\b/g;
  const hits = [];
  body.split('\n').forEach((line, i) => {
    let m;
    re.lastIndex = 0;
    while ((m = re.exec(line)) !== null) {
      const n = Number(m[2]) + (m[3] ? (m[3].charCodeAt(0) - 96) / 10 : 0);
      if (n > ord) hits.push({ line: i + 1 + offset, text: m[0] });
    }
  });
  return hits;
}

function uncertaintyWords(body) {
  let inSec = false, w = 0;
  for (const line of body.split('\n')) {
    if (/^##+ /.test(line)) inSec = UNCERTAIN_HEADING.test(line);
    else if (/^---\s*$/.test(line)) inSec = false; // nav separator ends the section
    if (inSec) w += line.split(/\s+/).filter(Boolean).length;
  }
  return w;
}

function unlinkedTerms(body, pages) {
  const linked = new Set([...body.matchAll(/\[\[([^\]|#]+)/g)].map(m => m[1].trim().toLowerCase()));
  const out = [];
  for (const p of pages) {
    if (linked.has(p.slug)) continue;
    for (const term of p.terms) {
      const re = new RegExp('\\b' + esc(term) + '\\b', 'gi');
      const n = (body.match(re) || []).length;
      if (n) { out.push({ node: `${p.dir}/${p.slug}`, term, n }); break; }
    }
  }
  return out.sort((a, b) => b.n - a.n);
}

function analyse(file, order, pages) {
  const raw = readFileSync(join(contentDir, file), 'utf8');
  const { fm, body, fmLines } = splitFrontmatter(raw);
  const words = body.split(/\s+/).filter(Boolean).length;
  const per1k = n => words ? +(n * 1000 / words).toFixed(1) : 0;
  const ch = order.get(file);

  const selfNarr = countHits(body, SELF_NARRATION, fmLines);
  const chRefs = (body.match(/\bCh(?:apter)?\.? ?\d+[a-z]?\b/g) || []).length;
  const reversal = countHits(body, REVERSAL, fmLines);
  const tics = {};
  let ticTotal = 0;
  for (const [k, re] of Object.entries(TICS)) {
    const h = countHits(body, [re], fmLines);
    if (h.length) { tics[k] = h; ticTotal += h.length; }
  }
  const fwd = forwardRefs(body, ch?.ord ?? null, fmLines);
  const bold = (body.match(/\*\*[^*\n]{30,}\*\*/g) || []).length;
  const parens = (body.match(/\([^)\n]{12,}\)/g) || []).length;
  const colons = (body.match(/[a-z]: [a-z]/gi) || []).length;
  const unc = uncertaintyWords(body);
  const links = (body.match(/\[\[/g) || []).length;
  const unlinked = unlinkedTerms(body, pages);
  const hasDesc = /^description:/m.test(fm);
  const hasAliases = /^aliases:/m.test(fm);

  return {
    file, chapter: ch?.number ?? (AUTHOR_FACING.has(file) ? 'author' : 'note'), words,
    selfNarration: selfNarr.length, selfNarrationPer1k: per1k(selfNarr.length), chapterRefs: chRefs,
    reversal: reversal.length, reversalPer1k: per1k(reversal.length),
    tics: ticTotal, ticsPer1k: per1k(ticTotal),
    forwardRefs: fwd.length,
    boldPer1k: per1k(bold), parensPer1k: per1k(parens), colonsPer1k: per1k(colons),
    uncertaintyWords: unc, uncertaintyPct: words ? Math.round(unc * 100 / words) : 0,
    links, linksPer1k: per1k(links), unlinkedTerms: unlinked.length,
    hasDescription: hasDesc, hasAliases,
    _hits: { selfNarr, reversal, tics, fwd, unlinked },
  };
}

// ------------------------------------------------------------ main

const order = loadChapterOrder();
const pages = loadNodeTerms();
let files = readdirSync(contentDir).filter(f => f.endsWith('.md') && !SKIP.has(f));
if (fileArg) {
  const want = fileArg.endsWith('.md') ? fileArg : fileArg + '.md';
  files = files.filter(f => f === want || f.replace(/\s+/g, '-') === want);
  if (!files.length) { console.error(`lint-prose: no content file matches "${fileArg}"`); process.exit(1); }
}
files.sort((a, b) => {
  const oa = order.get(a)?.ord ?? 99, ob = order.get(b)?.ord ?? 99;
  return oa - ob || a.localeCompare(b);
});

const results = files.map(f => analyse(f, order, pages));

if (JSON_OUT) {
  console.log(JSON.stringify(results.map(({ _hits, ...r }) => ({ ...r, hits: VERBOSE ? _hits : undefined })), null, 2));
  process.exit(0);
}

const pad = (s, n, right = false) => right ? String(s).padStart(n) : String(s).padEnd(n);
console.log(pad('file', 42) + pad('ch', 7) + pad('words', 7, true) + pad('self', 6, true) + pad('/1k', 6, true)
  + pad('ChN', 5, true) + pad('rev', 5, true) + pad('tics', 6, true) + pad('fwd', 5, true)
  + pad('bold', 6, true) + pad('paren', 7, true) + pad('colon', 7, true) + pad('unc%', 6, true)
  + pad('links', 7, true) + pad('unlnk', 7, true) + '  desc alias');
console.log('-'.repeat(150));
for (const r of results) {
  console.log(pad(r.file, 42) + pad(r.chapter, 7) + pad(r.words, 7, true) + pad(r.selfNarration, 6, true) + pad(r.selfNarrationPer1k, 6, true)
    + pad(r.chapterRefs, 5, true) + pad(r.reversal, 5, true) + pad(r.tics, 6, true) + pad(r.forwardRefs, 5, true)
    + pad(r.boldPer1k, 6, true) + pad(r.parensPer1k, 7, true) + pad(r.colonsPer1k, 7, true) + pad(r.uncertaintyPct, 6, true)
    + pad(r.linksPer1k, 7, true) + pad(r.unlinkedTerms, 7, true) + '  ' + (r.hasDescription ? 'y' : '-') + '    ' + (r.hasAliases ? 'y' : '-'));
}
const tot = results.reduce((a, r) => ({ words: a.words + r.words, self: a.self + r.selfNarration, rev: a.rev + r.reversal, tics: a.tics + r.tics, fwd: a.fwd + r.forwardRefs, unc: a.unc + r.uncertaintyWords }), { words: 0, self: 0, rev: 0, tics: 0, fwd: 0, unc: 0 });
console.log('-'.repeat(150));
console.log(`${results.length} files, ${tot.words} words. self-narration ${tot.self}, reversals ${tot.rev}, tic words ${tot.tics}, perfect-tense forward refs ${tot.fwd}, uncertainty-section words ${tot.unc} (${Math.round(tot.unc * 100 / tot.words)}%).`);
console.log('Columns: per-1000-word densities for self-narration (self /1k), **bold sentences**, (parenthetical asides), colon-joined clauses, [[links]]; ChN = raw "Ch N" mentions; rev = reversal constructions; fwd = perfect-tense references to LATER chapters; unc% = share of words in the uncertainty tail; unlnk = graph-node terms used but never linked.');

if (VERBOSE) {
  for (const r of results) {
    const h = r._hits;
    console.log(`\n=== ${r.file}`);
    const show = (label, arr, max = 12) => {
      if (!arr.length) return;
      console.log(`  ${label} (${arr.length}):`);
      for (const x of arr.slice(0, max)) console.log(`    L${x.line}: ${x.text}`);
      if (arr.length > max) console.log(`    … +${arr.length - max} more`);
    };
    show('self-narration', h.selfNarr);
    show('reversal', h.reversal, 8);
    for (const [k, arr] of Object.entries(h.tics)) show(`tic "${k}"`, arr, 4);
    show('perfect-tense forward refs', h.fwd);
    if (h.unlinked.length) {
      console.log(`  unlinked node terms (${h.unlinked.length}):`);
      console.log('    ' + h.unlinked.slice(0, 15).map(u => `${u.node} (${u.n}× "${u.term}")`).join('; '));
    }
  }
}
