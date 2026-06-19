#!/usr/bin/env node
// Generate Quartz-renderable landing pages for argument-layer graph nodes
// that have no prose page of their own: Concepts, CaseStudies, Mechanisms,
// and Questions.
//
// Why: the prose is full of [[wikilinks]] to these nodes (e.g.
// [[justification-market]], [[power-posing]]). They resolve in the ontology
// graph, but Quartz had no page at those slugs, so a wiki reader clicking
// them got a 404. Each generated page carries the node's summary, a link to
// its canonical prose home (definedIn), and its graph connections — turning
// every concept/case/mechanism/question into a real, navigable hub. Quartz's
// per-page local graph + backlinks panel handle the rest.
//
// Inputs:
//   data/nodes.jsonl        graph nodes (built by scripts/build-graph.js)
//   data/edges.jsonl        graph edges — connections are read from here
//   data/slug-aliases.json  reverse-lookup for extra alias slugs
//
// Output (one folder per type, so the Explorer can collapse them):
//   content/concepts/<slug>.md
//   content/cases/<slug>.md
//   content/mechanisms/<slug>.md
//   content/questions/<slug>.md
//
// Skip rules:
//   - A node whose slug already has a content page elsewhere (a collision,
//     e.g. concept:capture-taxonomy ↔ capture-taxonomy.md) is left to that
//     page — generating a duplicate slug would break wikilink resolution.
//   - A target file that exists and lacks GENERATOR_MARKER is treated as
//     hand-written and left alone (idempotent override, like the citation
//     generator).

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, unlinkSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, basename, extname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const contentDir = resolve(repoRoot, 'content');

const GENERATOR_MARKER = '<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->';

// type → { dir, tag, badge }
const TYPE_CONFIG = {
  Concept:   { dir: 'concepts',   tag: 'concept',    badge: 'Concept' },
  CaseStudy: { dir: 'cases',      tag: 'case-study', badge: 'Case study' },
  Mechanism: { dir: 'mechanisms', tag: 'mechanism',  badge: 'Mechanism' },
  Question:  { dir: 'questions',  tag: 'question',   badge: 'Open question' },
};

// Node types that have (or will have) a renderable page — only these get
// rendered as wikilinks, so we never introduce a NEW dead link.
const LINKABLE = new Set(['Note', 'Chapter', 'Source', 'Concept', 'CaseStudy', 'Mechanism', 'Question']);

// Predicate → how to phrase an edge, by direction relative to the page node.
// `out` = page is the edge source; `in` = page is the edge target.
// Weak/structural predicates (mentions, wikiLinks, cites, hasStatus, partOf,
// representedBy, authoredBy, partOfTradition, succeedsStage, gateFor) are
// intentionally omitted — Quartz's backlinks panel already surfaces those.
const PHRASING = {
  definedIn:         { out: 'Defined in' },
  covers:            { in:  'Discussed in' },
  argues:            { in:  'Argued in' },
  evidencedBy:       { out: 'Evidenced by' },
  supports:          { in:  'Supported by' },
  pressureTests:     { in:  'Pressure-tested by' },
  dependsOn:         { in:  'Built on by', out: 'Depends on' },
  enables:           { out: 'Enables', in: 'Enabled by' },
  precondition:      { out: 'Precondition for', in: 'Has precondition' },
  supersedes:        { out: 'Supersedes', in: 'Superseded by' },
  tensionWith:       { out: 'In tension with', in: 'In tension with' },
  contradicts:       { out: 'Contradicts', in: 'Contradicted by' },
  flagsOpenQuestion: { in: 'Raised in' },
  selectsFor:        { out: 'Selects for', in: 'Selected for by' },
  derivesFrom:       { out: 'Derives from', in: 'Derived from by' },
};

// Order sections deterministically and readably.
const SECTION_ORDER = [
  'Defined in', 'Discussed in', 'Argued in', 'Raised in',
  'Supported by', 'Pressure-tested by', 'Evidenced by',
  'Depends on', 'Built on by', 'Enables', 'Enabled by',
  'Precondition for', 'Has precondition', 'Selects for', 'Selected for by',
  'Derives from', 'Derived from by',
  'In tension with', 'Contradicts', 'Contradicted by',
  'Supersedes', 'Superseded by',
];

// ---------------------------------------------------------------- load

const nodes = readFileSync(resolve(dataDir, 'nodes.jsonl'), 'utf8')
  .split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
const edges = readFileSync(resolve(dataDir, 'edges.jsonl'), 'utf8')
  .split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
const nodeById = new Map(nodes.map(n => [n.id, n]));

const aliasesPath = resolve(dataDir, 'slug-aliases.json');
const slugAliases = existsSync(aliasesPath)
  ? (JSON.parse(readFileSync(aliasesPath, 'utf8')).aliases || {})
  : {};

// Existing content page slugs (everything except the folders we generate
// into) — used to detect collisions where a node slug already has a page.
function walk(dir) {
  let out = [];
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    if (e.name.startsWith('.')) continue;
    const p = resolve(dir, e.name);
    if (e.isDirectory()) {
      if (Object.values(TYPE_CONFIG).some(c => c.dir === e.name)) continue; // skip our own output
      out = out.concat(walk(p));
    } else if (extname(e.name) === '.md') {
      out.push(p);
    }
  }
  return out;
}
const existingSlugs = new Set(
  walk(contentDir).map(p => basename(p, '.md').toLowerCase().replace(/\s+/g, '-')),
);

// ---------------------------------------------------------------- helpers

const slugOf = (id) => id.slice(id.indexOf(':') + 1);

// Resolve the slug a node's page lives at (chapters have no page of their
// own — they live in their draftNote).
function pageSlugFor(node) {
  if (node.type === 'Chapter') {
    const dn = node.props?.draftNote;
    return dn ? slugOf(dn) : null;
  }
  return slugOf(node.id);
}

function labelFor(node) {
  if (node.type === 'Chapter') {
    const n = node.props?.number, t = node.props?.title;
    if (n && t) return `Ch ${n} — ${t}`;
  }
  return node.props?.title || node.label || slugOf(node.id);
}

// Render a reference to another node: a wikilink if it has a page, else bold
// plain text (so we never emit a dead link).
function refTo(id) {
  const node = nodeById.get(id);
  if (!node) return null;
  const label = labelFor(node);
  if (!LINKABLE.has(node.type)) return `**${label}**`;
  const slug = pageSlugFor(node);
  if (!slug) return `**${label}**`;
  return `[[${slug}|${label}]]`;
}

function aliasSlugsFor(nodeId) {
  const out = [];
  for (const [aliasSlug, target] of Object.entries(slugAliases)) {
    if (target === nodeId) out.push(aliasSlug);
  }
  return out;
}

function escapeYaml(s) {
  if (s == null) return '';
  if (/[:#&*!|>'"%@`,\[\]\{\}]/.test(s)) return JSON.stringify(s);
  return s;
}

// ---------------------------------------------------------------- render

function renderFrontmatter(node, cfg) {
  const lines = ['---'];
  lines.push(`title: ${escapeYaml(node.label)}`);
  lines.push('tags:');
  lines.push(`  - ${cfg.tag}`);
  lines.push('  - graph-node');
  // Aliases: node-declared synonyms + any reverse slug-aliases. These become
  // Quartz redirect pages, so [[post-hoc rationalization]] etc. also resolve.
  const aliasList = [...new Set([...(node.props?.aliases || []), ...aliasSlugsFor(node.id)])]
    .filter(a => a && a.toLowerCase().replace(/\s+/g, '-') !== slugOf(node.id));
  if (aliasList.length) {
    lines.push('aliases:');
    for (const a of aliasList) lines.push(`  - ${escapeYaml(a)}`);
  }
  lines.push('---');
  return lines.join('\n');
}

function connectionsFor(nodeId) {
  // section label → ordered, de-duped list of refs
  const sections = new Map();
  const pushRef = (label, targetId) => {
    const ref = refTo(targetId);
    if (!ref) return;
    if (!sections.has(label)) sections.set(label, new Set());
    sections.get(label).add(ref);
  };
  for (const e of edges) {
    const phr = PHRASING[e.predicate];
    if (!phr) continue;
    if (e.source === nodeId && phr.out) pushRef(phr.out, e.target);
    if (e.target === nodeId && phr.in) pushRef(phr.in, e.source);
  }
  return sections;
}

function renderBody(node, cfg) {
  const lines = [GENERATOR_MARKER, ''];
  lines.push(`> **${cfg.badge}**`);
  lines.push('');

  if (node.props?.summary) {
    lines.push(node.props.summary);
    lines.push('');
  }

  // Questions carry a status + working answer worth surfacing prominently.
  if (node.type === 'Question') {
    if (node.props?.status) {
      lines.push(`**Status.** ${node.props.status.replace(/-/g, ' ')}`);
      lines.push('');
    }
    if (node.props?.workingAnswer) {
      lines.push(`**Where the book lands.** ${node.props.workingAnswer}`);
      lines.push('');
    }
  }

  const sections = connectionsFor(node.id);
  const ordered = SECTION_ORDER.filter(s => sections.has(s));
  if (ordered.length) {
    lines.push('## Connections');
    lines.push('');
    for (const label of ordered) {
      const refs = [...sections.get(label)].sort();
      lines.push(`- **${label}:** ${refs.join(', ')}`);
    }
    lines.push('');
  }

  // Footer. The viewer link is a raw anchor: relative `../graph/` (every
  // output folder is one level deep) so it survives the project base path,
  // and data-router-ignore so Quartz's SPA router does a full load — the
  // Cytoscape app won't boot under SPA body-injection. The attribute MUST be
  // kebab-case: Quartz checks `"routerIgnore" in a.dataset`, which the HTML
  // parser only populates from `data-router-ignore` (camelCased), not from
  // `data-routerIgnore` (lowercased to `data-routerignore` → never matches).
  lines.push('<em>This is a graph landing page. Use the local graph and backlinks (right) to explore, or open the <a href="../graph/" data-router-ignore="true">interactive ontology</a>.</em>');
  lines.push('');
  return lines.join('\n');
}

function renderPage(node, cfg) {
  return `${renderFrontmatter(node, cfg)}\n\n${renderBody(node, cfg)}`
    .replace(/\n{3,}/g, '\n\n') + '\n';
}

// ---------------------------------------------------------------- main

let written = 0, skippedCollision = 0, skippedHand = 0;
const collisions = [], handWritten = [], wrote = [];

for (const node of nodes) {
  const cfg = TYPE_CONFIG[node.type];
  if (!cfg) continue;
  const slug = slugOf(node.id);

  // Collision: a page at this slug already exists outside our output folders.
  if (existingSlugs.has(slug)) {
    skippedCollision++;
    collisions.push(`${node.id} (slug "${slug}" already has a page)`);
    continue;
  }

  const outDir = resolve(contentDir, cfg.dir);
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });
  const targetPath = resolve(outDir, `${slug}.md`);

  // Idempotency / override: leave hand-written files (no marker) alone.
  if (existsSync(targetPath) && !readFileSync(targetPath, 'utf8').includes(GENERATOR_MARKER)) {
    skippedHand++;
    handWritten.push(`${cfg.dir}/${slug}.md`);
    continue;
  }

  writeFileSync(targetPath, renderPage(node, cfg));
  written++;
  wrote.push(`${cfg.dir}/${slug}`);
}

// Prune: a marker-bearing page whose slug no longer matches any current node
// of that folder's type is an orphan (the node was renamed or removed). Delete
// it so a rename doesn't leave a stale, published, dead-link-bearing page.
// Hand-written files (no marker) are never touched.
const validSlugsByDir = {};
for (const [type, cfg] of Object.entries(TYPE_CONFIG)) (validSlugsByDir[cfg.dir] ||= new Set());
for (const node of nodes) {
  const cfg = TYPE_CONFIG[node.type];
  if (cfg) validSlugsByDir[cfg.dir].add(slugOf(node.id));
}
let pruned = 0;
const prunedFiles = [];
for (const cfg of Object.values(TYPE_CONFIG)) {
  const outDir = resolve(contentDir, cfg.dir);
  if (!existsSync(outDir)) continue;
  for (const name of readdirSync(outDir)) {
    if (!name.endsWith('.md')) continue;
    const slug = basename(name, '.md');
    if (validSlugsByDir[cfg.dir].has(slug)) continue;
    const path = resolve(outDir, name);
    if (!readFileSync(path, 'utf8').includes(GENERATOR_MARKER)) continue; // hand-written
    unlinkSync(path);
    pruned++;
    prunedFiles.push(`${cfg.dir}/${name}`);
  }
}

console.log(`generate-concept-pages: ${written} written, ${skippedCollision} collision-skipped, ${skippedHand} hand-written skipped, ${pruned} orphan-pruned`);
if (prunedFiles.length) {
  console.log('  pruned (node renamed/removed):');
  for (const p of prunedFiles) console.log(`    ${p}`);
}
if (collisions.length) {
  console.log('  collisions (left to existing pages):');
  for (const c of collisions) console.log(`    ${c}`);
}
if (handWritten.length) {
  console.log('  hand-written (left alone):');
  for (const h of handWritten) console.log(`    ${h}`);
}
