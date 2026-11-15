#!/usr/bin/env node
// Interlink the prose with the card layer.
//
// Every Concept / Mechanism / CaseStudy in the graph has a short page (a
// "card"). This script walks the chapters and notes and turns the first
// mention of each card's name into a link to it, so a reader can step out of
// the narrative into any idea at the point it comes up. The term list is the
// ontology's: each card's label and aliases, steered per node by `autolink`
// in the catalogs (false = never; an array = exactly these terms).
//
// Rules (conservative on purpose — a wrong link is worse than a missing one):
//   - House rule (EDITORIAL-PLAN.md, D2): link the first use of a card in
//     each chapter or note, never the rest. So: one link per card per file.
//   - A card already linked anywhere in the file, by hand or by an earlier
//     run, is left alone.
//   - Longest term wins; matches never overlap; matching is case-insensitive
//     on word boundaries and the original wording is kept as the link text.
//   - Never touched: frontmatter, headings, code, block quotes, the generated
//     chapter-map block, existing links, HTML, LaTeX, and **bold** spans
//     (bold sentences are the claim-harvester's anchors — see
//     harvest-claims.js — and must stay byte-stable).
//   - A note is never linked to the card that shares its slug.
//
// Idempotent: a second run finds every card already linked and changes
// nothing. Run `make interlink` after adding prose or cards; `--dry` reports
// what would change without writing.
//
// Inputs:  data/nodes.jsonl (run `make build` first), content/*.md
// Output:  content/*.md edited in place

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const contentDir = resolve(repoRoot, 'content');
const DRY = process.argv.includes('--dry');
const VERBOSE = process.argv.includes('--verbose');

const nodes = readFileSync(resolve(repoRoot, 'data', 'nodes.jsonl'), 'utf8')
  .split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
const nodeById = new Map(nodes.map(n => [n.id, n]));
const edges = readFileSync(resolve(repoRoot, 'data', 'edges.jsonl'), 'utf8')
  .split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
// card id → Set(note ids that define it)
const homeNotes = new Map();
for (const e of edges) {
  if (e.predicate !== 'definedIn') continue;
  if (!homeNotes.has(e.source)) homeNotes.set(e.source, new Set());
  homeNotes.get(e.source).add(e.target);
}

// Which notes get interlinked. The outline (author-facing), the landing page
// (hand-curated), transcripts and generated hubs are left alone.
const TARGET_ROLES = new Set(['chapter-draft', 'foundational-note', 'interlude', 'companion-essay', 'glossary', 'distillation']);
const LINK_TYPES = new Set(['Concept', 'Mechanism', 'CaseStudy']);
const MIN_TERM_LENGTH = 5;

const slugOf = (id) => id.slice(id.indexOf(':') + 1);
const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// ---------------------------------------------------------------- term table

// term (lowercase) → { slug, id }
const terms = new Map();
const collisions = [];
for (const node of nodes) {
  if (!LINK_TYPES.has(node.type)) continue;
  const auto = node.props?.autolink;
  if (auto === false) continue;
  let list;
  if (Array.isArray(auto)) {
    list = auto;
  } else {
    // Label without its parenthesis / colon gloss, plus the aliases.
    const bare = node.label.split(/ \(|: /)[0].trim();
    list = [bare, ...(node.props?.aliases || [])];
  }
  for (const raw of list) {
    const term = raw.trim().toLowerCase();
    if (term.length < MIN_TERM_LENGTH) continue;
    if (terms.has(term) && terms.get(term).id !== node.id) {
      collisions.push(`"${term}": ${terms.get(term).id} vs ${node.id}`);
      continue;
    }
    terms.set(term, { slug: slugOf(node.id), id: node.id, words: term.split(/\s+/).length });
  }
}
const ordered = [...terms.keys()].sort((a, b) => b.length - a.length);
// One alternation, longest first, on word-ish boundaries. A trailing "s" is
// allowed so plurals link ("selection gates"); possessives are left alone.
const TERM_RE = new RegExp(`(?<![\\w-])(${ordered.map(escapeRe).join('|')})(s?)(?![\\w-]|'s|’s)`, 'gi');

// ---------------------------------------------------------------- masking

// Spans inside a line that must not be touched or matched.
const PROTECTED = [
  /\[\[[^\]]*\]\]/g,              // wikilinks
  /!?\[[^\]]*\]\([^)]*\)/g,       // markdown links / images
  /`[^`]*`/g,                     // inline code
  /<[^>]+>/g,                     // html tags
  /\$[^$\n]+\$/g,                 // inline LaTeX
  /\*\*[^*]+\*\*/g,               // bold spans (claim anchors)
  /https?:\/\/\S+/g,              // bare urls
];

function protectedRanges(line) {
  const ranges = [];
  for (const re of PROTECTED) {
    re.lastIndex = 0;
    let m;
    while ((m = re.exec(line)) !== null) ranges.push([m.index, m.index + m[0].length]);
  }
  return ranges;
}
const inRanges = (ranges, start, end) => ranges.some(([a, b]) => start < b && end > a);

// Slugs already linked on a line (to honour hand-placed links).
function linkedSlugs(line) {
  const out = [];
  const re = /\[\[([^\]|#]+)(?:#[^\]|]*)?(?:\|[^\]]*)?\]\]/g;
  let m;
  while ((m = re.exec(line)) !== null) out.push(m[1].trim().toLowerCase().replace(/\s+/g, '-'));
  return out;
}

// ---------------------------------------------------------------- per note

let totalLinks = 0, filesChanged = 0;
const perTerm = new Map();

for (const note of nodes.filter(n => n.type === 'Note' && TARGET_ROLES.has(n.props?.role))) {
  const path = resolve(contentDir, note.props.file);
  if (!existsSync(path)) continue;
  const ownSlug = slugOf(note.id);
  const homeCards = new Set([...homeNotes].filter(([, notes]) => notes.has(note.id)).map(([id]) => id));
  const lines = readFileSync(path, 'utf8').split('\n');

  // Pass 1: classify lines and collect what is already linked, per scope.
  const kind = new Array(lines.length).fill('text');
  const sectionOf = new Array(lines.length).fill(0);
  let inFront = false, inCode = false, inMap = false, section = 0;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (i === 0 && line === '---') { inFront = true; kind[i] = 'skip'; continue; }
    if (inFront) { kind[i] = 'skip'; if (line === '---') inFront = false; continue; }
    if (/^```/.test(line)) { inCode = !inCode; kind[i] = 'skip'; continue; }
    if (inCode) { kind[i] = 'skip'; continue; }
    if (line.startsWith('<!-- chapter-map:begin')) inMap = true;
    if (inMap) { kind[i] = 'skip'; if (line.startsWith('<!-- chapter-map:end')) inMap = false; continue; }
    if (/^##\s/.test(line)) section++;
    sectionOf[i] = section;
    if (/^#{1,6}\s/.test(line) || /^\s*>/.test(line) || /^\s*<!--/.test(line)) kind[i] = 'skip';
    // Chapter prev/next footers and other pure-navigation lines.
    else if (/[←→]/.test(line) && /\[\[/.test(line)) kind[i] = 'skip';
  }
  const linkedInNote = new Set();
  const linkedInSection = new Map(); // section → Set(slug)
  for (let i = 0; i < lines.length; i++) {
    if (kind[i] === 'skip' && !/^\s*>/.test(lines[i])) continue;
    for (const slug of linkedSlugs(lines[i])) {
      linkedInNote.add(slug);
      if (!linkedInSection.has(sectionOf[i])) linkedInSection.set(sectionOf[i], new Set());
      linkedInSection.get(sectionOf[i]).add(slug);
    }
  }

  // Pass 2: link first mentions.
  let changed = 0;
  for (let i = 0; i < lines.length; i++) {
    if (kind[i] !== 'text') continue;
    const line = lines[i];
    if (!line.trim()) continue;
    const ranges = protectedRanges(line);
    const inSection = linkedInSection.get(sectionOf[i]) || new Set();
    let out = '', last = 0, m;
    TERM_RE.lastIndex = 0;
    while ((m = TERM_RE.exec(line)) !== null) {
      const start = m.index, end = start + m[0].length;
      if (inRanges(ranges, start, end)) continue;
      const t = terms.get(m[1].toLowerCase());
      if (!t || t.slug === ownSlug) continue;
      // First use per file only.
      const seen = linkedInNote;
      if (seen.has(t.slug)) continue;
      out += line.slice(last, start) + `[[${t.slug}|${m[0]}]]`;
      last = end;
      linkedInNote.add(t.slug);
      inSection.add(t.slug);
      linkedInSection.set(sectionOf[i], inSection);
      changed++;
      perTerm.set(m[1].toLowerCase(), (perTerm.get(m[1].toLowerCase()) || 0) + 1);
      if (VERBOSE) console.log(`  ${note.props.file}:${i + 1}  "${m[0]}" → ${t.slug}`);
    }
    if (last > 0) lines[i] = out + line.slice(last);
  }

  if (changed) {
    totalLinks += changed;
    filesChanged++;
    if (!DRY) writeFileSync(path, lines.join('\n'));
    console.log(`  ${note.props.file}: ${changed} link${changed === 1 ? '' : 's'}`);
  }
}

console.log(`interlink: ${totalLinks} links ${DRY ? 'would be added' : 'added'} across ${filesChanged} notes (${terms.size} terms from ${new Set([...terms.values()].map(t => t.id)).size} cards)`);
if (collisions.length) {
  console.log('  ambiguous terms skipped:');
  for (const c of collisions) console.log(`    ${c}`);
}
if (DRY || VERBOSE) {
  const top = [...perTerm.entries()].sort((a, b) => b[1] - a[1]);
  console.log('  by term:');
  for (const [t, n] of top) console.log(`    ${String(n).padStart(3)}  ${t} → ${terms.get(t).slug}`);
}
