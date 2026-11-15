#!/usr/bin/env node
// Generate the site's exploration layer from the ontology graph.
//
// The book has two reading modes. The chapters are the narrative: long,
// linear, one argument. The cards are the chunks: every Concept, Mechanism,
// CaseStudy and Question in the graph gets a short, self-contained, heavily
// interlinked page, so a reader can wander idea to idea in any order. This
// script builds everything that makes the second mode work, and the signposts
// that keep the first one easy to follow:
//
//   1. Card pages      content/{concepts,mechanisms,cases,questions}/<slug>.md
//   2. Theme pages     content/themes/<slug>.md      (an ordered trail of cards)
//   3. Explore hub     content/explore.md            (every theme, every card)
//   4. Reading path    content/reading-path.md       (the chapters in order,
//                                                     each in two sentences)
//   5. Chapter maps    a generated block at the top of each chapter / note:
//                      the cards it contains
//   6. Reading nav     a generated previous / next footer on every chapter
//                      and interlude, in reading order
//   7. Folder indexes  content/<folder>/index.md — gives each folder a
//                      reader-facing name ("Ideas", not "concepts") in the
//                      sidebar, breadcrumbs and folder page
//
// Inputs:
//   data/nodes.jsonl        graph nodes (built by scripts/build-graph.js)
//   data/edges.jsonl        graph edges — every link below is read from here
//   data/slug-aliases.json  reverse-lookup for extra alias slugs
//
// Card pages: generated frame, hand-written body.
//   The frame (frontmatter, the plain-sentence callout, "Read the full
//   argument", "How it connects", the trail nav) is regenerated on every run.
//   The body between `<!-- card -->` and `<!-- /card -->` is PROSE and is
//   preserved verbatim — edit it in place. build-graph.js reads the links in
//   that body back into the graph, and warns when a card has no body, no
//   `plain` sentence, no theme, or too few links out.
//
// Skip rules:
//   - A node whose slug already has a content page elsewhere (a collision,
//     e.g. concept:capture-taxonomy ↔ capture-taxonomy.md) is left to that
//     page — generating a duplicate slug would break wikilink resolution.
//   - A target file that exists and lacks GENERATOR_MARKER is treated as
//     fully hand-written and left alone.

import { readFileSync, writeFileSync, existsSync, mkdirSync, readdirSync, unlinkSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, basename, extname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const contentDir = resolve(repoRoot, 'content');

const GENERATOR_MARKER = '<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->';
const CARD_OPEN = '<!-- card -->';
const CARD_CLOSE = '<!-- /card -->';
const CARD_REGION = /<!-- card -->\n?([\s\S]*?)\n?<!-- \/card -->/;
const MAP_BEGIN = '<!-- chapter-map:begin (generated from the ontology by scripts/generate-concept-pages.js; edit data/chapters.json, data/notes.json or the catalogs, not this block) -->';
const MAP_END = '<!-- chapter-map:end -->';
const MAP_REGION = /<!-- chapter-map:begin[\s\S]*?<!-- chapter-map:end -->\n*/;
const NAV_BEGIN = '<!-- chapter-nav:begin (generated from the ontology by scripts/generate-concept-pages.js; reading order comes from data/chapters.json and data/notes.json) -->';
const NAV_END = '<!-- chapter-nav:end -->';
const NAV_REGION = /\n*<!-- chapter-nav:begin[\s\S]*?<!-- chapter-nav:end -->\n*$/;
// The hand-written footer this block replaces: a rule, then one line of
// "← previous · next →" wikilinks at the very end of the file.
const LEGACY_NAV = /\n+---\n+(?:\[\[[^\]]+\]\](?: · )?){1,2}\s*$/;

// type → { dir, tag, badge }
const TYPE_CONFIG = {
  Concept:   { dir: 'concepts',   tag: 'concept',    badge: 'Concept' },
  CaseStudy: { dir: 'cases',      tag: 'case-study', badge: 'Example' },
  Mechanism: { dir: 'mechanisms', tag: 'mechanism',  badge: 'Mechanism' },
  Question:  { dir: 'questions',  tag: 'question',   badge: 'Open question' },
};
const THEME_DIR = 'themes';
const GENERATED_DIRS = new Set([...Object.values(TYPE_CONFIG).map(c => c.dir), THEME_DIR]);

// Node types that have (or will have) a renderable page — only these get
// rendered as wikilinks, so we never introduce a NEW dead link.
const LINKABLE = new Set(['Note', 'Chapter', 'Source', 'Concept', 'CaseStudy', 'Mechanism', 'Question', 'Theme']);

// Predicate → which "How it connects" row an edge lands in, by direction
// relative to the page node (`out` = page is the edge source). Rows are
// phrased for a reader deciding where to go next, not for an ontologist.
// Structural predicates with their own section (definedIn, covers, inTheme)
// and weak ones (mentions, wikiLinks) are handled separately or omitted.
const PHRASING = {
  derivesFrom:       { out: 'Builds on', in: 'Leads to' },
  instanceOf:        { out: 'A special case of', in: 'Special cases' },
  enables:           { out: 'Leads to', in: 'Builds on' },
  precondition:      { out: 'Leads to', in: 'Builds on' },
  dependsOn:         { out: 'Builds on', in: 'Leads to' },
  illustrates:       { out: 'What it shows', in: 'Examples' },
  relatedTo:         { out: 'See also', in: 'See also' },
  tensionWith:       { out: 'In tension with', in: 'In tension with' },
  contradicts:       { out: 'In tension with', in: 'In tension with' },
  supersedes:        { out: 'Replaces', in: 'Replaced by' },
  flagsOpenQuestion: { in: 'Raised in' },
  selectsFor:        { out: 'Selects for', in: 'Selected for by' },
  argues:            { in: 'Argued in' },
  supports:          { in: 'Supported by' },
  pressureTests:     { in: 'Pressure-tested by' },
  evidencedBy:       { out: 'Evidence' },
};

const SECTION_ORDER = [
  'A special case of', 'Builds on', 'Leads to', 'Special cases',
  'What it shows', 'Examples', 'See also', 'In tension with',
  'Replaces', 'Replaced by', 'Selects for', 'Selected for by',
  'Raised in', 'Argued in',
  'Evidence', 'Supported by', 'Pressure-tested by',
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
      if (GENERATED_DIRS.has(e.name)) continue; // skip our own output
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
const outEdges = (id, pred) => edges.filter(e => e.source === id && e.predicate === pred);
const inEdges = (id, pred) => edges.filter(e => e.target === id && e.predicate === pred);

// Resolve the slug a node's page lives at (chapters have no page of their
// own — they live in their draftNote).
function pageSlugFor(node) {
  if (node.type === 'Chapter') {
    const dn = node.props?.draftNote;
    return dn ? slugOf(dn) : null;
  }
  return slugOf(node.id);
}

// Reader-facing label. Generated text follows the prose voice rules: no
// em-dashes, so "Ch 5b — Title" becomes "Chapter 5b: Title".
function labelFor(node) {
  if (node.type === 'Chapter') {
    const n = node.props?.number, t = node.props?.title;
    if (n && t) return `Chapter ${n}: ${t}`;
  }
  return (node.props?.title || node.label || slugOf(node.id)).replace(/\s+—\s+/g, ': ');
}

// Chip label: the part of a label before a parenthesis or colon gloss, so
// "Arsenic-life (Wolfe-Simon et al. 2010): died at consensus" reads as
// "Arsenic-life" in a row of chips. Full labels stay on the pages themselves.
function shortLabel(node) {
  const full = labelFor(node);
  if (node.type === 'Chapter' || node.type === 'Question') return full;
  const cut = full.split(/ \(|: /)[0].trim();
  return cut.length >= 4 ? cut : full;
}
const chip = (id) => { const n = nodeById.get(id); return n ? refTo(id, shortLabel(n)) : null; };

// Wikilink display text can't contain `|` or `]]`.
const safe = (s) => String(s).replace(/\|/g, '/').replace(/\]\]/g, ']');

// Render a reference to another node: a wikilink if it has a page, else bold
// plain text (so we never emit a dead link).
function refTo(id, labelOverride) {
  const node = nodeById.get(id);
  if (!node) return null;
  const label = safe(labelOverride || labelFor(node));
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
  if (/[:#&*!|>'"%@`,\[\]\{\}]/.test(s) || /^\s|\s$/.test(s)) return JSON.stringify(s);
  return s;
}

function writeIfChanged(path, text) {
  if (existsSync(path) && readFileSync(path, 'utf8') === text) return false;
  writeFileSync(path, text);
  return true;
}

const byLabel = (a, b) => labelFor(a).localeCompare(labelFor(b));

// ---------------------------------------------------------------- themes

const themes = nodes.filter(n => n.type === 'Theme').sort((a, b) => (a.props.ordinal ?? 0) - (b.props.ordinal ?? 0));
// card id → { theme, index }
const trail = new Map();
for (const t of themes) {
  const members = (t.props.members || []).filter(id => nodeById.has(id));
  members.forEach((id, i) => trail.set(id, { theme: t, index: i, members }));
}

const TYPE_TAG = { Mechanism: 'mechanism', CaseStudy: 'example', Question: 'open question' };

// Every slug that is (or will be) a real page: existing content pages, every
// card, every theme, the two hubs. Aliases may not shadow any of them.
const aliasSlug = (a) => a.trim().toLowerCase().replace(/\s+/g, '-');
const takenSlugs = new Set([
  ...existingSlugs,
  ...nodes.filter(n => TYPE_CONFIG[n.type] || n.type === 'Theme').map(n => slugOf(n.id)),
  'explore', 'reading-path',
]);
const claimedAliases = new Map(); // alias slug → node id that emits it

// ---------------------------------------------------------------- 1. card pages

function renderFrontmatter(title, tags, { aliases = [], description } = {}) {
  const lines = ['---'];
  lines.push(`title: ${escapeYaml(title)}`);
  if (description) lines.push(`description: ${JSON.stringify(description)}`);
  lines.push('tags:');
  for (const t of tags) lines.push(`  - ${t}`);
  if (aliases.length) {
    lines.push('aliases:');
    for (const a of aliases) lines.push(`  - ${escapeYaml(a)}`);
  }
  lines.push('---');
  return lines.join('\n');
}

function connectionsFor(nodeId) {
  // section label → de-duped set of node ids
  const sections = new Map();
  const push = (label, targetId) => {
    if (!sections.has(label)) sections.set(label, new Set());
    sections.get(label).add(targetId);
  };
  for (const e of edges) {
    const phr = PHRASING[e.predicate];
    if (!phr) continue;
    if (e.source === nodeId && phr.out) push(phr.out, e.target);
    if (e.target === nodeId && phr.in) push(phr.in, e.source);
  }
  return sections;
}

function passageRefs(node) {
  // "Read the full argument": the declared passages (note + H2 section) if
  // any, else the notes the node is definedIn.
  const out = [];
  const chapterOfNote = (noteId) => nodes.find(n => n.type === 'Chapter' && n.props?.draftNote === noteId);
  const noteLabel = (noteId) => {
    const ch = chapterOfNote(noteId);
    return safe(ch ? labelFor(ch) : labelFor(nodeById.get(noteId)));
  };
  const seenNotes = new Set();
  for (const p of node.props?.passages || []) {
    const noteId = `note:${p.note}`;
    if (!nodeById.has(noteId)) continue;
    seenNotes.add(noteId);
    out.push(`[[${p.note}#${p.section}|${noteLabel(noteId)}]], section "${p.section}"`);
  }
  if (!out.length) {
    for (const e of outEdges(node.id, 'definedIn')) {
      if (!nodeById.has(e.target) || seenNotes.has(e.target)) continue;
      out.push(`[[${slugOf(e.target)}|${noteLabel(e.target)}]]`);
    }
  }
  return out;
}

function discussedIn(node) {
  // Chapters that cover the node, in reading order, then notes that define
  // it and are not themselves a chapter's draft.
  const chapters = inEdges(node.id, 'covers').map(e => nodeById.get(e.source)).filter(Boolean)
    .sort((a, b) => (a.props.ordinal ?? 0) - (b.props.ordinal ?? 0));
  const draftNotes = new Set(chapters.map(c => c.props?.draftNote));
  const notes = outEdges(node.id, 'definedIn').map(e => nodeById.get(e.target)).filter(Boolean)
    .filter(n => !draftNotes.has(n.id))
    .filter(n => !nodes.some(c => c.type === 'Chapter' && c.props?.draftNote === n.id && chapters.includes(c)));
  return [...chapters, ...notes].map(n => refTo(n.id)).filter(Boolean);
}

function trailNav(node) {
  const t = trail.get(node.id);
  if (!t) return null;
  const prev = t.members[t.index - 1], next = t.members[t.index + 1];
  const bits = [];
  if (prev) bits.push(`← ${refTo(prev)}`);
  bits.push(`${refTo(t.theme.id)} (${t.index + 1} of ${t.members.length})`);
  if (next) bits.push(`${refTo(next)} →`);
  return bits.join(' · ');
}

function renderCardPage(node, cfg, existingBody) {
  const plain = node.props?.plain;
  // Aliases become Quartz redirect pages at the site root (so [[the menu]]
  // resolves). An alias whose slug is already a real page — a chapter, a
  // note, another card, a theme, a citation — must NOT be emitted: the
  // redirect would overwrite that page (alias "the abyss" on this card used
  // to replace the essay at /the-abyss with a redirect to the card). Likewise
  // an alias another card already claimed. The catalog keeps such aliases;
  // they still drive scripts/interlink.js.
  const aliasList = [...new Set([...(node.props?.aliases || []), ...aliasSlugsFor(node.id)])]
    .filter(a => a && aliasSlug(a) !== slugOf(node.id))
    .filter(a => {
      const slug = aliasSlug(a);
      if (takenSlugs.has(slug)) return false;
      if (claimedAliases.has(slug) && claimedAliases.get(slug) !== node.id) return false;
      claimedAliases.set(slug, node.id);
      return true;
    });
  const t = trail.get(node.id);

  const lines = [
    renderFrontmatter(node.label, [cfg.tag, 'graph-node'], { aliases: aliasList, description: plain }),
    '',
    GENERATOR_MARKER,
    '',
  ];

  // What kind of page this is and where it sits. The one-sentence plain
  // statement is the frontmatter `description:`, which the site's properties
  // block renders at the top of every page (the house convention for all
  // content files), so it is not repeated here.
  const where = t ? `${cfg.badge} · part of ${refTo(t.theme.id)}` : cfg.badge;
  lines.push(`*${where}*`, '');

  // The hand-written body, preserved verbatim. With no body yet, fall back
  // to the catalog summary OUTSIDE the card region, so the build still
  // reports the card as unwritten.
  if (existingBody != null) {
    lines.push(CARD_OPEN, existingBody.trim(), CARD_CLOSE, '');
  } else if (node.props?.summary) {
    lines.push(node.props.summary, '');
  }

  // Optional external URL: an idea published in full somewhere off-site
  // (e.g. a companion essay). Rendered as a plain outbound link so the card
  // points at the full text.
  if (node.props?.url) {
    lines.push(`**Read it in full:** [${node.label}](${node.props.url})`, '');
  }

  if (node.type === 'CaseStudy' && node.props?.evidence) {
    lines.push(`**How solid is this?** ${node.props.evidence}`, '');
  }

  if (node.type === 'Question') {
    if (node.props?.status) lines.push(`**Status:** ${node.props.status.replace(/-/g, ' ')}.`, '');
    if (node.props?.workingAnswer) {
      lines.push("> [!note]- The working answer, in the author's words", `> ${node.props.workingAnswer}`, '');
    }
  }

  const passages = passageRefs(node);
  if (passages.length) {
    lines.push('## Read the full argument', '');
    for (const p of passages) lines.push(`- ${p}`);
    lines.push('');
  }

  const sections = connectionsFor(node.id);
  const ordered = SECTION_ORDER.filter(s => sections.has(s));
  const discussed = discussedIn(node);
  if (ordered.length || discussed.length) {
    lines.push('## How it connects', '');
    // "See also" is the catch-all: drop anything a more specific row already lists.
    const specific = new Set(ordered.filter(l => l !== 'See also').flatMap(l => [...sections.get(l)]));
    for (const label of ordered) {
      const refs = [...sections.get(label)]
        .filter(id => label !== 'See also' || !specific.has(id))
        .map(id => nodeById.get(id)).filter(Boolean)
        .sort(byLabel).map(n => refTo(n.id)).filter(Boolean);
      if (refs.length) lines.push(`- **${label}:** ${refs.join(', ')}`);
    }
    if (discussed.length) lines.push(`- **Where the book discusses it:** ${discussed.join(', ')}`);
    lines.push('');
  }

  // Footer. The viewer link is a raw anchor: relative `../graph/` (every
  // output folder is one level deep) so it survives the project base path,
  // and data-router-ignore so Quartz's SPA router does a full load — the
  // Cytoscape app won't boot under SPA body-injection. The attribute MUST be
  // kebab-case: Quartz checks `"routerIgnore" in a.dataset`, which the HTML
  // parser only populates from `data-router-ignore` (camelCased), not from
  // `data-routerIgnore` (lowercased to `data-routerignore` → never matches).
  lines.push('---', '');
  const nav = trailNav(node);
  if (nav) lines.push(nav, '');
  lines.push('<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>', '');

  return lines.join('\n').replace(/\n{3,}/g, '\n\n').replace(/\n*$/, '\n');
}

let written = 0, skippedCollision = 0, skippedHand = 0;
const collisions = [], handWritten = [];

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

  let existingBody = null;
  if (existsSync(targetPath)) {
    const current = readFileSync(targetPath, 'utf8');
    // Idempotency / override: leave fully hand-written files (no marker) alone.
    if (!current.includes(GENERATOR_MARKER)) {
      skippedHand++;
      handWritten.push(`${cfg.dir}/${slug}.md`);
      continue;
    }
    const m = current.match(CARD_REGION);
    if (m) existingBody = m[1];
  }

  if (writeIfChanged(targetPath, renderCardPage(node, cfg, existingBody))) written++;
}

// Prune: a marker-bearing page whose slug no longer matches any current node
// of that folder's type is an orphan (the node was renamed or removed). Delete
// it so a rename doesn't leave a stale, published, dead-link-bearing page —
// UNLESS it carries a written card body, which is prose worth a human look.
// Hand-written files (no marker) are never touched.
const validSlugsByDir = { [THEME_DIR]: new Set(themes.map(t => slugOf(t.id))) };
for (const cfg of Object.values(TYPE_CONFIG)) (validSlugsByDir[cfg.dir] ||= new Set());
for (const node of nodes) {
  const cfg = TYPE_CONFIG[node.type];
  if (cfg) validSlugsByDir[cfg.dir].add(slugOf(node.id));
}
let pruned = 0;
const prunedFiles = [], strandedCards = [];
for (const dir of GENERATED_DIRS) {
  const outDir = resolve(contentDir, dir);
  if (!existsSync(outDir)) continue;
  for (const name of readdirSync(outDir)) {
    if (!name.endsWith('.md') || name === 'index.md') continue; // index.md: see section 6
    const slug = basename(name, '.md');
    if (validSlugsByDir[dir].has(slug)) continue;
    const path = resolve(outDir, name);
    const text = readFileSync(path, 'utf8');
    if (!text.includes(GENERATOR_MARKER)) continue; // hand-written
    if (CARD_REGION.test(text)) { strandedCards.push(`${dir}/${name}`); continue; }
    unlinkSync(path);
    pruned++;
    prunedFiles.push(`${dir}/${name}`);
  }
}

// ---------------------------------------------------------------- 2. theme pages

const cardLine = (id) => {
  const n = nodeById.get(id);
  if (!n) return null;
  const tag = TYPE_TAG[n.type] ? ` *(${TYPE_TAG[n.type]})*` : '';
  return `${refTo(id)}${tag}${n.props?.plain ? `: ${n.props.plain}` : ''}`;
};

function chaptersOfTheme(t) {
  return (t.props.chapters || [])
    .map(slug => nodeById.get(`chapter:${slug}`) || nodeById.get(`note:${slug}`))
    .filter(Boolean).map(n => refTo(n.id)).filter(Boolean);
}

let themesWritten = 0;
if (themes.length) {
  const outDir = resolve(contentDir, THEME_DIR);
  if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });
  themes.forEach((t, i) => {
    const members = (t.props.members || []).filter(id => nodeById.has(id));
    const lines = [
      renderFrontmatter(t.label, ['theme', 'graph-node'], { description: t.props.plain }),
      '',
      GENERATOR_MARKER,
      '',
      `*Theme ${i + 1} of ${themes.length} · ${members.length} ideas*`,
      '',
    ];
    if (t.props.summary) lines.push(t.props.summary, '');
    const chs = chaptersOfTheme(t);
    if (chs.length) lines.push(`**The same ground, told as a story:** ${chs.join(', ')}.`, '');
    lines.push('## The ideas', '', 'Each one is a short page. Walk them in this order, or start with whichever catches your eye.', '');
    members.forEach((id, k) => { const l = cardLine(id); if (l) lines.push(`${k + 1}. ${l}`); });
    lines.push('', '---', '');
    const nav = [];
    if (themes[i - 1]) nav.push(`← ${refTo(themes[i - 1].id)}`);
    nav.push('[[explore|All themes]]');
    if (themes[i + 1]) nav.push(`${refTo(themes[i + 1].id)} →`);
    lines.push(nav.join(' · '), '');
    const text = lines.join('\n').replace(/\n{3,}/g, '\n\n').replace(/\n*$/, '\n');
    if (writeIfChanged(resolve(outDir, `${slugOf(t.id)}.md`), text)) themesWritten++;
  });
}

// ---------------------------------------------------------------- 3. explore hub

const HUB_NOTE = '<!-- generated from the ontology graph by scripts/generate-concept-pages.js — edit data/themes.json, data/chapters.json or the catalogs and rebuild; do not edit this file -->';
let hubsWritten = 0;

if (themes.length) {
  const cardCount = [...trail.keys()].length;
  const lines = [
    renderFrontmatter('Explore the ideas', ['information'], {
      description: 'Every idea in the book as a short page, grouped into themes you can wander in any order.',
    }),
    '',
    HUB_NOTE,
    '',
    `*Lossy* is one long argument, but it is built out of about ${Math.round(cardCount / 10) * 10} separate ideas, and you do not have to meet them in order. Every idea has its own short page: one plain sentence, an example, a few paragraphs, and links to the ideas next to it. This page is the map of all of them.`,
    '',
    `The ${themes.length} themes below run in roughly the order of the argument, so reading down the page follows the story. Inside a theme, start anywhere. When an idea is worth the long version, its page points to where it is argued in full.`,
    '',
    'Prefer the story from the top? Take [[reading-path|the reading path]]: every chapter in order, each in a sentence or two. Short on time? [[the-short-version|The short version]] is the whole argument in a page.',
    '',
  ];
  themes.forEach((t, i) => {
    const members = (t.props.members || []).filter(id => nodeById.has(id));
    lines.push(`## ${i + 1}. ${t.label}`, '');
    lines.push(`${t.props.plain} ${refTo(t.id, 'Open this theme →')}`, '');
    const ideas = members.filter(id => ['Concept', 'Mechanism'].includes(nodeById.get(id).type)).map(chip);
    const cases = members.filter(id => nodeById.get(id).type === 'CaseStudy').map(chip);
    const qs = members.filter(id => nodeById.get(id).type === 'Question').map(chip);
    if (ideas.length) lines.push(`**Ideas:** ${ideas.join(' · ')}`, '');
    if (cases.length) lines.push(`**Examples:** ${cases.join(' · ')}`, '');
    if (qs.length) lines.push(`**Open questions:** ${qs.join(' · ')}`, '');
  });
  lines.push('---', '', '<em>Rather see it as a picture? <a href="./graph/" data-router-ignore="true">Open the interactive map</a> and pick "Idea map".</em>', '');
  if (writeIfChanged(resolve(contentDir, 'explore.md'), lines.join('\n').replace(/\n{3,}/g, '\n\n'))) hubsWritten++;
}

// ---------------------------------------------------------------- 4. reading path

// The cards a chapter (or a note) contains: what it covers, plus what is
// defined in its note. Ordered so the ideas native to the chapter come first.
function cardsIn(noteNode, chapterNode) {
  const ids = [];
  const add = (id) => { if (!ids.includes(id) && TYPE_CONFIG[nodeById.get(id)?.type]) ids.push(id); };
  if (noteNode) for (const e of inEdges(noteNode.id, 'definedIn')) add(e.source);
  if (chapterNode) {
    for (const e of outEdges(chapterNode.id, 'covers')) add(e.target);
    for (const e of outEdges(chapterNode.id, 'flagsOpenQuestion')) add(e.target);
  }
  if (noteNode) for (const e of outEdges(noteNode.id, 'flagsOpenQuestion')) add(e.target);
  const native = new Set(noteNode ? inEdges(noteNode.id, 'definedIn').map(e => e.source) : []);
  const rank = (id) => (native.has(id) ? 0 : 1);
  return ids.sort((a, b) => rank(a) - rank(b) || byLabel(nodeById.get(a), nodeById.get(b)));
}

const chapters = nodes.filter(n => n.type === 'Chapter').sort((a, b) => (a.props.ordinal ?? 0) - (b.props.ordinal ?? 0));
const parts = nodes.filter(n => n.type === 'Part').sort((a, b) => (a.props.ordinal ?? 0) - (b.props.ordinal ?? 0));

{
  const lines = [
    renderFrontmatter('The reading path', ['information'], {
      description: 'The whole book in order: every chapter in two sentences, with the ideas you will meet in each.',
    }),
    '',
    HUB_NOTE,
    '',
    'Everything in the order it is meant to be read. Each chapter and interlude is summed up in a sentence or two, so you can see the whole arc before committing to any of it, and find your place again later. Under each are a few of the ideas it introduces; every one of them has its own short page if you would rather wander than read straight through.',
    '',
    'The argument in one line: ideas are compressed and filtered on their way to you; the filter is tuned for attention, not truth; here is what that does, and what could carry hard truths through anyway.',
    '',
  ];
  for (const part of parts) {
    lines.push(`## ${labelFor(part)}`, '');
    if (part.props?.summary) lines.push(`*${part.props.summary}*`, '');
    for (const ch of chapters.filter(c => c.props.part === slugOf(part.id))) {
      const note = ch.props?.draftNote ? nodeById.get(ch.props.draftNote) : null;
      lines.push(`### ${refTo(ch.id) || `**${labelFor(ch)}**`}`, '');
      lines.push(note?.props?.description || ch.props?.plain || ch.props?.summary || '', '');
      const cards = cardsIn(note, ch).filter(id => nodeById.get(id).type !== 'Question').slice(0, 8);
      if (cards.length) lines.push(`*Ideas you will meet:* ${cards.map(chip).join(' · ')}`, '');
      // Interludes: notes threaded into the linear read after this chapter.
      for (const il of nodes.filter(n => n.type === 'Note' && n.props?.readAfter === slugOf(ch.id))) {
        lines.push(`### ${refTo(il.id, il.props.navTitle || labelFor(il))}`, '');
        lines.push(il.props?.description || il.props?.summary || '', '');
        const ilCards = cardsIn(il, null).filter(id => nodeById.get(id).type !== 'Question').slice(0, 8);
        if (ilCards.length) lines.push(`*Ideas you will meet:* ${ilCards.map(chip).join(' · ')}`, '');
      }
    }
  }
  const draftNotes = new Set(chapters.map(c => c.props?.draftNote));
  const side = nodes.filter(n => n.type === 'Note' && !draftNotes.has(n.id)
    && !n.props?.readAfter
    && ['foundational-note', 'interlude', 'companion-essay'].includes(n.props?.role));
  if (side.length) {
    lines.push('## Side roads', '', 'Notes that work one question through at more depth than the chapters do. Read one when a chapter sends you there, or when its question is the one you came with.', '');
    for (const n of side) {
      const d = n.props?.description || n.props?.plain;
      lines.push(`- ${refTo(n.id)}${d ? `: ${d}` : ''}`);
    }
    lines.push('');
  }
  lines.push('---', '', '<em>[[explore|Explore the ideas instead]] · [[the-short-version|The short version]] · [[glossary|Glossary]]</em>', '');
  if (writeIfChanged(resolve(contentDir, 'reading-path.md'), lines.join('\n').replace(/\n{3,}/g, '\n\n'))) hubsWritten++;
}

// ---------------------------------------------------------------- 5. chapter maps

// A generated block at the top of each chapter, interlude and depth note: a
// collapsed list of the cards the page contains, plus the two ways out. It is the
// bridge between the two reading modes — a linear reader can step out to a
// card at any point and a card reader can see what else lives in the chapter.
const MAP_ROLES = new Set(['chapter-draft', 'foundational-note', 'interlude', 'companion-essay']);
let mapsWritten = 0;

for (const note of nodes.filter(n => n.type === 'Note' && MAP_ROLES.has(n.props?.role))) {
  const path = resolve(contentDir, note.props.file);
  if (!existsSync(path)) continue;
  const chapter = chapters.find(c => c.props?.draftNote === note.id) || null;
  const cards = cardsIn(note, chapter);
  if (!cards.length) continue;

  // The page's one-paragraph summary is its frontmatter `description:`, shown
  // by the site's properties block; the map adds only what that cannot: the
  // cards on the page, and the two ways out.
  const block = [MAP_BEGIN];
  if (cards.length) {
    const native = new Set(inEdges(note.id, 'definedIn').map(e => e.source));
    const group = (types, pred = () => true) => cards
      .filter(id => types.includes(nodeById.get(id).type) && pred(id)).map(chip);
    const introduced = group(['Concept', 'Mechanism'], id => native.has(id));
    const ideas = group(['Concept', 'Mechanism'], id => !native.has(id));
    const cases = group(['CaseStudy']), qs = group(['Question']);
    block.push(`> [!example]- The ideas on this page (${cards.length}), each with its own short page`);
    const rows = [];
    if (introduced.length) rows.push(`> **Worked out here:** ${introduced.join(' · ')}`);
    if (ideas.length) rows.push(`> **${introduced.length ? 'Also used' : 'Ideas'}:** ${ideas.join(' · ')}`);
    if (cases.length) rows.push(`> **Examples:** ${cases.join(' · ')}`);
    if (qs.length) rows.push(`> **Open questions:** ${qs.join(' · ')}`);
    rows.push('> *[[reading-path|Where this sits in the book]] · [[explore|Explore all the ideas]]*');
    block.push(rows.join('\n>\n'), '');
  }
  while (block[block.length - 1] === '') block.pop();
  block.push(MAP_END);
  const blockText = block.join('\n') + '\n\n';

  const current = readFileSync(path, 'utf8');
  let next;
  if (MAP_REGION.test(current)) {
    next = current.replace(MAP_REGION, blockText);
  } else {
    const fm = current.match(/^---\n[\s\S]*?\n---\n+/);
    if (!fm) continue; // no frontmatter — leave it alone
    next = fm[0].replace(/\n+$/, '\n\n') + blockText + current.slice(fm[0].length);
  }
  if (next !== current) { writeFileSync(path, next); mapsWritten++; }
}

// ---------------------------------------------------------------- 6. reading nav

// The linear read: chapters by ordinal, each followed by the interludes that
// name it in `readAfter`. Every page in it gets a generated footer linking
// the page before and the page after, so the chain cannot drift when the
// order changes (it used to be hand-written in every file).
const readingOrder = [];
for (const ch of chapters) {
  const note = ch.props?.draftNote ? nodeById.get(ch.props.draftNote) : null;
  if (note) readingOrder.push({ note, label: labelFor(ch) });
  for (const il of nodes.filter(n => n.type === 'Note' && n.props?.readAfter === slugOf(ch.id))) {
    readingOrder.push({ note: il, label: il.props.navTitle || labelFor(il) });
  }
}
let navsWritten = 0;
readingOrder.forEach((entry, i) => {
  const path = resolve(contentDir, entry.note.props.file);
  if (!existsSync(path)) return;
  const prev = readingOrder[i - 1], next = readingOrder[i + 1];
  const link = (e) => slugOf(e.note.id);
  const left = prev ? `[[${link(prev)}|← ${safe(prev.label)}]]` : '[[reading-path|← The reading path]]';
  const right = next ? `[[${link(next)}|${safe(next.label)} →]]` : '[[explore|Explore the ideas →]]';
  const block = `${NAV_BEGIN}\n---\n\n${left} · ${right}\n${NAV_END}\n`;
  const current = readFileSync(path, 'utf8');
  const body = current.replace(NAV_REGION, '').replace(LEGACY_NAV, '').replace(/\s*$/, '');
  const updated = `${body}\n\n${block}`;
  if (updated !== current) { writeFileSync(path, updated); navsWritten++; }
});

// ---------------------------------------------------------------- 7. folder indexes

// Quartz names a folder after the title of its index.md, in the sidebar, the
// breadcrumbs and the folder page. Without one a reader sees the directory
// name ("concepts", "cases"), which is authoring vocabulary. Each index is a
// title, a description and two sentences; the folder page lists the folder's
// pages underneath. A hand-written index.md (no generator note) is left alone.
const FOLDERS = [
  { dir: 'themes', title: 'Themes',
    text: `The book's ideas grouped into ${themes.length} themes, in the order of the argument. Each theme is a short trail of pages you can walk in order or dip into.` },
  { dir: 'concepts', title: 'Ideas',
    text: 'Every idea the argument uses, each on its own short page: one plain sentence, an example, and links to the ideas next to it.' },
  { dir: 'mechanisms', title: 'Mechanisms',
    text: 'The handful of processes the whole argument runs on. If you read only one folder, read this one.' },
  { dir: 'cases', title: 'Examples',
    text: 'Real cases that ground the ideas, each with a note on how far it can be trusted.' },
  { dir: 'questions', title: 'Open questions',
    text: 'Questions the book is still working out, each with where it currently lands and how settled that is.' },
  { dir: 'citations', title: 'Sources',
    text: 'The books, papers and essays the argument draws on or argues with, each with what it is used for.' },
  { dir: 'experiments', title: 'Experiments',
    text: "Designs for testing the book's empirical claims. Trackers, not results." },
  { dir: 'sources', title: 'Source files',
    text: 'Open-licence source documents held alongside the book. Each has a page under Sources that says how it is used.' },
];
let indexesWritten = 0;
for (const f of FOLDERS) {
  const dirPath = resolve(contentDir, f.dir);
  if (!existsSync(dirPath)) continue;
  const path = resolve(dirPath, 'index.md');
  if (existsSync(path) && !readFileSync(path, 'utf8').includes(HUB_NOTE)) continue; // hand-written
  const text = [
    renderFrontmatter(f.title, ['information'], { description: f.text }),
    '',
    HUB_NOTE,
    '',
    f.text,
    '',
    '<em>[[explore|Explore all the ideas by theme]] · [[reading-path|Read the book in order]]</em>',
    '',
  ].join('\n');
  if (writeIfChanged(path, text)) indexesWritten++;
}

// ---------------------------------------------------------------- report

console.log(`generate-concept-pages: ${written} card pages written, ${themesWritten} theme pages, ${hubsWritten} hub pages, ${indexesWritten} folder indexes, ${mapsWritten} chapter maps and ${navsWritten} reading-nav footers updated; ${skippedCollision} collision-skipped, ${skippedHand} hand-written skipped, ${pruned} orphan-pruned`);
if (prunedFiles.length) {
  console.log('  pruned (node renamed/removed):');
  for (const p of prunedFiles) console.log(`    ${p}`);
}
if (strandedCards.length) {
  console.log('  STRANDED (no matching node, but carries a written card body — move or delete by hand):');
  for (const p of strandedCards) console.log(`    ${p}`);
}
if (collisions.length) {
  console.log('  collisions (left to existing pages):');
  for (const c of collisions) console.log(`    ${c}`);
}
if (handWritten.length) {
  console.log('  hand-written (left alone):');
  for (const h of handWritten) console.log(`    ${h}`);
}
