#!/usr/bin/env node
// Generate Quartz-renderable citation pages from data/sources.json.
//
// Inputs:
//   data/sources.json       canonical source catalog (id, author, summary, …)
//   data/slug-aliases.json  manual wikilink overrides — used to detect when
//                           a hand-written citation file lives at an alias
//                           slug rather than at <source.id>.md
//   data/edges.jsonl        graph edges; back-pointers are computed from
//                           `cites` edges pointing at each source
//   data/nodes.jsonl        used to resolve back-pointer targets to titles
//
// Output:
//   content/citations/<source.id>.md   one page per source
//
// Skip rule: a citation file is treated as hand-written (and left alone) if
// it exists and does NOT contain GENERATOR_MARKER. Generated files always
// contain the marker as the first body line, so re-running this script is
// idempotent and only touches files it previously wrote.

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const citationsDir = resolve(repoRoot, 'content', 'citations');

const GENERATOR_MARKER = '<!-- generated from data/sources.json — edit data/sources.json to update structured metadata, or replace this file with hand-written prose (delete this comment) to override -->';

// ---------------------------------------------------------------- load

if (!existsSync(citationsDir)) mkdirSync(citationsDir, { recursive: true });

const { sources, authors } = JSON.parse(readFileSync(resolve(dataDir, 'sources.json'), 'utf8'));
const authorById = new Map((authors || []).map(a => [a.id, a]));

const aliasesPath = resolve(dataDir, 'slug-aliases.json');
const aliases = existsSync(aliasesPath)
  ? (JSON.parse(readFileSync(aliasesPath, 'utf8')).aliases || {})
  : {};

const edgesPath = resolve(dataDir, 'edges.jsonl');
const nodesPath = resolve(dataDir, 'nodes.jsonl');
const edges = existsSync(edgesPath)
  ? readFileSync(edgesPath, 'utf8').split('\n').filter(l => l.trim()).map(l => JSON.parse(l))
  : [];
const nodes = existsSync(nodesPath)
  ? readFileSync(nodesPath, 'utf8').split('\n').filter(l => l.trim()).map(l => JSON.parse(l))
  : [];
const nodeById = new Map(nodes.map(n => [n.id, n]));

// ---------------------------------------------------------------- helpers

function aliasesForSource(sourceId) {
  // Reverse-lookup: which wikilink slugs resolve to this source?
  const out = [];
  for (const [aliasSlug, target] of Object.entries(aliases)) {
    if (target === `source:${sourceId}`) out.push(aliasSlug);
  }
  return out;
}

function isGenerated(path) {
  if (!existsSync(path)) return false;
  return readFileSync(path, 'utf8').includes(GENERATOR_MARKER);
}

// Returns a hand-written file path that overrides this source, if any.
function handWrittenFileFor(source) {
  const candidates = [`${source.id}.md`, ...aliasesForSource(source.id).map(s => `${s}.md`)];
  for (const c of candidates) {
    const p = resolve(citationsDir, c);
    if (existsSync(p) && !isGenerated(p)) return p;
  }
  return null;
}

function notesCiting(sourceId) {
  return edges
    .filter(e => e.predicate === 'cites' && e.target === `source:${sourceId}`)
    .map(e => nodeById.get(e.source))
    .filter(n => n && n.type === 'Note');
}

// Prefer the chapter context for a note: if a Chapter has draftNote pointing
// at this note, render "Ch N — Title" instead of the note's own title.
function chapterForNote(noteId) {
  return nodes.find(n => n.type === 'Chapter' && n.props?.draftNote === noteId);
}

function backPointerLine(note) {
  const slug = note.id.replace(/^note:/, '');
  const chapter = chapterForNote(note.id);
  if (chapter) {
    return `- [[${slug}|Ch ${chapter.props.number} — ${chapter.props.title}]]`;
  }
  const role = note.props?.role || 'note';
  const title = note.props?.title || note.label;
  return `- [[${slug}|${title}]] *(${role})*`;
}

function escapeYaml(s) {
  if (s == null) return '';
  // Quote if contains characters YAML would mangle
  if (/[:#&*!|>'"%@`,\[\]\{\}]/.test(s)) return JSON.stringify(s);
  return s;
}

// ---------------------------------------------------------------- render

function renderFrontmatter(source) {
  const lines = ['---'];
  lines.push(`title: ${escapeYaml(source.label)}`);
  const tags = ['citation', ...(source.tags || [])];
  lines.push('tags:');
  for (const t of tags) lines.push(`  - ${t}`);
  const aliasList = aliasesForSource(source.id);
  if (aliasList.length) {
    lines.push('aliases:');
    for (const a of aliasList) lines.push(`  - ${a}`);
  }
  lines.push('---');
  return lines.join('\n');
}

function renderBody(source) {
  const lines = [];
  lines.push(GENERATOR_MARKER);
  lines.push('');

  // Byline
  const authorLabel = source.author ? (authorById.get(source.author)?.label || source.author) : null;
  const coauthorLabels = (source.coauthors || []).map(a => authorById.get(a)?.label || a);
  const byline = [authorLabel, ...coauthorLabels].filter(Boolean).join(' / ');
  const kindLabel = source.kind || 'source';
  const headerBits = [`**${kindLabel}**`];
  if (byline) headerBits.push(byline);
  if (source.tradition) headerBits.push(`tradition: \`${source.tradition}\``);
  lines.push(`> ${headerBits.join(' · ')}`);
  lines.push('');

  // Summary
  if (source.summary) {
    lines.push(source.summary);
    lines.push('');
  }

  // Engagement — the book's stance toward this source
  if (source.engagement) {
    lines.push(`**The book's stance.** ${source.engagement}.`);
    lines.push('');
  }

  // Availability + file
  const availability = source.availability || 'external';
  if (source.file && (availability === 'open' || availability === 'unverified')) {
    const note = availability === 'unverified' ? ' *(licence not yet confirmed)*' : '';
    lines.push(`**Local copy.** [\`sources/${source.file}\`](../sources/${source.file})${note}`);
    lines.push('');
  } else if (availability === 'restricted') {
    lines.push(`**Availability.** In-copyright — not redistributed. Engaged from a local working copy held outside the repo; cited by reference here.`);
    lines.push('');
  } else if (availability === 'external') {
    lines.push(`**Availability.** Cited by reference; no local copy held in the repo.`);
    lines.push('');
  }

  // Represented-by — if this source IS a note (e.g. general-theme conversation)
  if (source.representedBy) {
    lines.push(`**Represented in the book by.** [[${source.representedBy}]]`);
    lines.push('');
  }

  // Back-pointers
  const citing = notesCiting(source.id);
  if (citing.length) {
    lines.push('## Where this is cited in the book');
    lines.push('');
    // Stable order: by note id
    citing.sort((a, b) => a.id.localeCompare(b.id));
    for (const note of citing) lines.push(backPointerLine(note));
    lines.push('');
  }

  return lines.join('\n');
}

function renderPage(source) {
  return `${renderFrontmatter(source)}\n\n${renderBody(source)}`.replace(/\n{3,}/g, '\n\n') + '\n';
}

// ---------------------------------------------------------------- main

let written = 0;
let skipped = 0;
const skippedFor = [];
const writtenFor = [];

for (const source of sources) {
  const handWritten = handWrittenFileFor(source);
  if (handWritten) {
    skipped++;
    skippedFor.push(`${source.id} → ${handWritten.replace(repoRoot + '/', '')}`);
    continue;
  }
  const targetPath = resolve(citationsDir, `${source.id}.md`);
  writeFileSync(targetPath, renderPage(source));
  written++;
  writtenFor.push(source.id);
}

console.log(`generate-citation-pages: ${written} written, ${skipped} hand-written skipped`);
if (writtenFor.length) {
  console.log(`  written: ${writtenFor.join(', ')}`);
}
if (skippedFor.length) {
  console.log(`  skipped:`);
  for (const s of skippedFor) console.log(`    ${s}`);
}
