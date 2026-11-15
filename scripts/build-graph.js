#!/usr/bin/env node
// Build the information-book semantic-triple graph.
//
// Inputs (data/):
//   graph-meta.json   schema contract (node types, predicates, statuses)
//
// Outputs (data/):
//   nodes.jsonl       one node per line
//   edges.jsonl       one edge per line
//   build-stats.json  counts + warnings
//
// Phase 0: seeds the structural skeleton only —
//   4 Part nodes, 5 Status nodes, 6 PipelineStage nodes + their
//   succeedsStage edges, 5 Gate nodes + their gateFor edges.
//
// Later phases plug in: outline parser, hand-authored catalogs
// (mechanisms/concepts/questions/traditions/sources/claims), note
// parser with wiki-link extraction, claim harvester, and LLM
// interpretive triples from sources/*.pdf.

import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, extname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const META_PATH = resolve(dataDir, 'graph-meta.json');
const NOTES_DIR = resolve(repoRoot, 'content');

const meta = JSON.parse(readFileSync(META_PATH, 'utf8'));

const nodes = new Map();
const edges = [];
const edgeKeys = new Set();
const warnings = [];
let edgeCounter = 0;

function addNode(node) {
  if (!node.id) throw new Error('node missing id');
  if (!node.type) throw new Error(`node ${node.id} missing type`);
  if (!meta.nodeTypes[node.type]) throw new Error(`unknown node type ${node.type} on ${node.id}`);
  const prior = nodes.get(node.id);
  if (prior) {
    nodes.set(node.id, {
      ...prior,
      ...node,
      props: { ...(prior.props || {}), ...(node.props || {}) },
      provenance: [...(prior.provenance || []), ...(node.provenance || [])],
    });
  } else {
    nodes.set(node.id, { ...node, provenance: node.provenance || [] });
  }
}

function addEdge(source, target, predicate, props = {}) {
  if (!meta.predicates[predicate]) throw new Error(`unknown predicate ${predicate}`);
  // Undirected predicates (tensionWith, contradicts, relatedTo) de-dup on the
  // unordered pair, so A—B declared from both ends is one edge, not two.
  const undirected = meta.predicates[predicate].directed === false;
  const key = undirected
    ? `${[source, target].sort().join('|')}|${predicate}`
    : `${source}|${predicate}|${target}`;
  if (source === target) return;
  if (edgeKeys.has(key)) return;
  edgeKeys.add(key);
  edges.push({ id: `e${++edgeCounter}`, source, target, predicate, ...props });
}

function validateEdges() {
  const ok = [];
  for (const e of edges) {
    if (!nodes.has(e.source)) {
      warnings.push(`edge dropped: missing source ${e.source} → ${e.target} (${e.predicate})`);
      continue;
    }
    if (!nodes.has(e.target)) {
      warnings.push(`edge dropped: missing target ${e.source} → ${e.target} (${e.predicate})`);
      continue;
    }
    ok.push(e);
  }
  edges.length = 0;
  edges.push(...ok);
}

// ---------------------------------------------------------------- seeds

function seedStatuses() {
  const summaries = {
    'drafted':         'A full draft exists in the notes.',
    'in-workshop':     'Draft exists and is being actively revised.',
    'skeleton':        'Only an outline-level description exists.',
    'not-yet-drafted': 'Named in the outline but no draft exists yet.',
    'superseded':      'Replaced by a later version; kept for history.',
  };
  for (const s of meta.statuses) {
    addNode({
      id: `status:${s}`,
      type: 'Status',
      label: s,
      props: { summary: summaries[s] || '' },
      provenance: [{ source: 'graph-meta.json', kind: 'seed' }],
    });
  }
}

function seedParts() {
  // Parts live in data/parts.json (like every other catalog) so the site's
  // navigation can read the same labels the graph uses.
  const { parts } = JSON.parse(readFileSync(resolve(dataDir, 'parts.json'), 'utf8'));
  for (const p of parts) {
    addNode({
      id: `part:${p.slug}`,
      type: 'Part',
      label: p.label,
      props: { ordinal: p.ordinal, summary: p.summary },
      provenance: [{ source: 'outline.md', kind: 'seed' }],
    });
  }
}

function seedPipeline() {
  // The canonical pipeline from the-information-landscape.md.
  const stages = [
    { slug: 'out-there', ordinal: 0, label: 'The Out There',
      summary: 'Reality independent of any observer. The only node we can never see directly.' },
    { slug: 'raw-data',  ordinal: 1, label: 'Raw Data',
      summary: 'First abstraction: what to measure, at what resolution, with what instruments.' },
    { slug: 'insight',   ordinal: 2, label: 'Insight',
      summary: 'Patterns, relationships, models, statistics, inference.' },
    { slug: 'theory',    ordinal: 3, label: 'Theory',
      summary: 'What survives consensus-formation across a community of practitioners.' },
    { slug: 'news',      ordinal: 4, label: 'News / Journalism',
      summary: 'Translation from specialist language to general language.' },
    { slug: 'meme',      ordinal: 5, label: 'Meme',
      summary: 'Final compression. Shareable, emotionally-charged unit traveling through informal networks.' },
  ];
  const transformations = {
    'raw-data': 'Measurement',
    'insight':  'Analysis',
    'theory':   'Consensus',
    'news':     'Abstraction / Curation',
    'meme':     'Abstraction / Emote',
  };
  for (const s of stages) {
    addNode({
      id: `stage:${s.slug}`,
      type: 'PipelineStage',
      label: s.label,
      props: { ordinal: s.ordinal, summary: s.summary },
      provenance: [{ source: 'the-information-landscape.md', kind: 'seed' }],
    });
  }
  for (let i = 1; i < stages.length; i++) {
    addEdge(
      `stage:${stages[i - 1].slug}`,
      `stage:${stages[i].slug}`,
      'succeedsStage',
      { transformation: transformations[stages[i].slug] },
    );
  }

  // The sibling selection pipeline — one Gate per non-Out-There stage.
  const gates = [
    { slug: 'measurement', pairedWith: 'raw-data', label: 'Measurement gate',
      summary: 'Funding / research agenda / instrumentation. What gets measured at all.' },
    { slug: 'analysis',    pairedWith: 'insight',  label: 'Analysis gate',
      summary: 'Methodological fit / publishability / file-drawer pressure.' },
    { slug: 'consensus',   pairedWith: 'theory',   label: 'Consensus gate',
      summary: 'Peer review / career incentives / institutional fit.' },
    { slug: 'curation',    pairedWith: 'news',     label: 'Curation gate',
      summary: 'Newsworthiness / narrative shape / audience interest.' },
    { slug: 'memetic',     pairedWith: 'meme',     label: 'Memetic gate',
      summary: 'Memetic fitness / emotional valence / identity resonance.' },
  ];
  for (const g of gates) {
    addNode({
      id: `gate:${g.slug}`,
      type: 'Gate',
      label: g.label,
      props: { summary: g.summary },
      provenance: [{ source: 'the-information-landscape.md', kind: 'seed' }],
    });
    addEdge(`gate:${g.slug}`, `stage:${g.pairedWith}`, 'gateFor');
  }
}

// ---------------------------------------------------------------- chapter + note seeds
//
// Chapters and notes live in data/chapters.json and data/notes.json (like
// every other catalog) rather than inline here — adding or editing one is a
// data edit, not a code change, and the note/chapter summaries have a single
// home. The loops below are unchanged from when the arrays were inline.

function seedChapters() {
  const { chapters } = loadJsonCatalog('chapters.json');
  for (const c of chapters) {
    addNode({
      id: `chapter:${c.slug}`,
      type: 'Chapter',
      label: `Ch ${c.number} — ${c.title}`,
      props: {
        ordinal: c.ordinal,
        number: c.number,
        title: c.title,
        part: c.part,
        status: c.status,
        summary: c.summary,
        ...(c.plain ? { plain: c.plain } : {}),
        ...(c.draftNote ? { draftNote: c.draftNote } : {}),
      },
      provenance: [{ source: 'outline.md', kind: 'seed' }],
    });
    addEdge(`chapter:${c.slug}`, `part:${c.part}`, 'partOf');
    addEdge(`chapter:${c.slug}`, `status:${c.status}`, 'hasStatus');
  }
}

function seedNotes() {
  const { notes } = loadJsonCatalog('notes.json');
  for (const n of notes) {
    addNode({
      id: `note:${n.slug}`,
      type: 'Note',
      label: n.slug,
      props: {
        file: n.file,
        subtype: n.subtype,
        title: n.title,
        role: n.role,
        summary: n.summary,
        ...(n.plain ? { plain: n.plain } : {}),
        ...(n.generated ? { generated: true } : {}),
        ...(n.readAfter ? { readAfter: n.readAfter } : {}),
        ...(n.navTitle ? { navTitle: n.navTitle } : {}),
      },
      provenance: [{ source: n.file, kind: 'seed' }],
    });
  }
}

// ---------------------------------------------------------------- catalog loaders

function loadJsonCatalog(filename) {
  return JSON.parse(readFileSync(resolve(dataDir, filename), 'utf8'));
}

// ---------------------------------------------------------------- cards
//
// Mechanisms, Concepts, CaseStudies and Questions are the book's "cards":
// each gets a short, reader-facing, interlinked page (see
// scripts/generate-concept-pages.js). The catalog fields below are the
// card layer of the ontology:
//   plain      one plain-language sentence (hub pages, popovers, chapter maps)
//   passages   [{ note, section }] — the H2 section(s) where the idea is argued
//              in full; validated against the note's real headings
//   related    typed ids → undirected `relatedTo` (curated see-also)
//   instanceOf typed ids → `instanceOf` (X is a special case of Y)
//   autolink   false, or an explicit list of terms, to steer scripts/interlink.js
const CARD_TYPES = ['Mechanism', 'Concept', 'CaseStudy', 'Question'];
const CARD_DIRS = { Mechanism: 'mechanisms', Concept: 'concepts', CaseStudy: 'cases', Question: 'questions' };

function cardProps(x) {
  return {
    ...(x.plain ? { plain: x.plain } : {}),
    ...(x.passages?.length ? { passages: x.passages } : {}),
    ...(x.autolink !== undefined ? { autolink: x.autolink } : {}),
    // Optional external URL: an idea published in full off-site (e.g. a
    // companion essay). The card page renders it as "Read it in full".
    ...(x.url ? { url: x.url } : {}),
  };
}

function cardEdges(id, x) {
  for (const target of x.related || []) addEdge(id, target, 'relatedTo');
  for (const target of x.instanceOf || []) addEdge(id, target, 'instanceOf');
}

function loadMechanisms() {
  const { mechanisms } = loadJsonCatalog('mechanisms.json');
  for (const m of mechanisms) {
    addNode({
      id: `mechanism:${m.id}`,
      type: 'Mechanism',
      label: m.label,
      props: { summary: m.summary, aliases: m.aliases || [], ...cardProps(m) },
      provenance: [{ source: 'mechanisms.json', kind: 'catalog' }],
    });
    cardEdges(`mechanism:${m.id}`, m);
    for (const srcSlug of m.evidencedBy || []) {
      addEdge(`mechanism:${m.id}`, `source:${srcSlug}`, 'evidencedBy');
    }
    for (const noteSlug of m.definedIn || []) {
      addEdge(`mechanism:${m.id}`, `note:${noteSlug}`, 'definedIn');
    }
    for (const chSlug of m.coveredBy || []) {
      addEdge(`chapter:${chSlug}`, `mechanism:${m.id}`, 'covers');
    }
    for (const other of m.derivesFrom || []) {
      addEdge(`mechanism:${m.id}`, other.includes(':') ? other : `mechanism:${other}`, 'derivesFrom');
    }
    for (const target of m.enables || []) {
      addEdge(`mechanism:${m.id}`, target, 'enables');
    }
  }
}

function loadConcepts() {
  const { concepts } = loadJsonCatalog('concepts.json');
  for (const c of concepts) {
    addNode({
      id: `concept:${c.id}`,
      type: 'Concept',
      label: c.label,
      props: { summary: c.summary, aliases: c.aliases || [], ...cardProps(c) },
      provenance: [{ source: 'concepts.json', kind: 'catalog' }],
    });
    cardEdges(`concept:${c.id}`, c);
    for (const other of c.derivesFrom || []) {
      addEdge(`concept:${c.id}`, other.includes(':') ? other : `concept:${other}`, 'derivesFrom');
    }
    for (const noteSlug of c.definedIn || []) {
      addEdge(`concept:${c.id}`, `note:${noteSlug}`, 'definedIn');
    }
    for (const chSlug of c.coveredBy || []) {
      addEdge(`chapter:${chSlug}`, `concept:${c.id}`, 'covers');
    }
    for (const srcSlug of c.evidencedBy || []) {
      addEdge(`concept:${c.id}`, `source:${srcSlug}`, 'evidencedBy');
    }
    for (const target of c.enables || []) {
      addEdge(`concept:${c.id}`, target, 'enables');
    }
  }
}

function loadQuestions() {
  const { questions } = loadJsonCatalog('questions.json');
  for (const q of questions) {
    addNode({
      id: `question:${q.id}`,
      type: 'Question',
      label: q.label,
      props: {
        summary: q.summary,
        aliases: q.aliases || [],
        status: q.status || 'open',
        workingAnswer: q.workingAnswer || null,
        ...cardProps(q),
      },
      provenance: [{ source: 'questions.json', kind: 'catalog' }],
    });
    cardEdges(`question:${q.id}`, q);
    for (const noteSlug of q.flaggedIn || []) {
      addEdge(`note:${noteSlug}`, `question:${q.id}`, 'flagsOpenQuestion');
    }
    for (const chSlug of q.blocksChapters || []) {
      addEdge(`chapter:${chSlug}`, `question:${q.id}`, 'flagsOpenQuestion');
    }
    for (const otherQ of q.dependsOn || []) {
      addEdge(`question:${q.id}`, `question:${otherQ}`, 'dependsOn');
    }
  }
}

function loadTraditions() {
  const { traditions } = loadJsonCatalog('traditions.json');
  for (const t of traditions) {
    addNode({
      id: `tradition:${t.id}`,
      type: 'Tradition',
      label: t.label,
      props: { summary: t.summary },
      provenance: [{ source: 'traditions.json', kind: 'catalog' }],
    });
  }
}

function loadSources() {
  const { sources, authors } = loadJsonCatalog('sources.json');
  for (const a of authors || []) {
    addNode({
      id: `author:${a.id}`,
      type: 'Author',
      label: a.label,
      props: { summary: a.summary || '' },
      provenance: [{ source: 'sources.json', kind: 'catalog' }],
    });
  }
  for (const s of sources) {
    addNode({
      id: `source:${s.id}`,
      type: 'Source',
      label: s.label,
      props: {
        kind: s.kind || 'book',
        summary: s.summary || '',
        engagement: s.engagement || '',
        availability: s.availability || 'external',
        tags: s.tags || [],
        ...(s.file ? { file: s.file } : {}),
      },
      provenance: [{ source: 'sources.json', kind: 'catalog' }],
    });
    if (s.author) addEdge(`source:${s.id}`, `author:${s.author}`, 'authoredBy');
    for (const a of s.coauthors || []) {
      addEdge(`source:${s.id}`, `author:${a}`, 'authoredBy');
    }
    if (s.tradition) addEdge(`source:${s.id}`, `tradition:${s.tradition}`, 'partOfTradition');
    if (s.representedBy) addEdge(`source:${s.id}`, `note:${s.representedBy}`, 'representedBy');
    // A secondary source (e.g. a research report) relaying primary ones.
    for (const other of s.cites || []) addEdge(`source:${s.id}`, `source:${other}`, 'cites');
  }
}

function loadCaseStudies() {
  const { caseStudies } = loadJsonCatalog('case-studies.json');
  // `illustrates` holds mechanism slugs (legacy) or typed ids; the two
  // sibling fields are concept / claim slugs.
  const typed = (v, ns) => (v.includes(':') ? v : `${ns}:${v}`);
  for (const cs of caseStudies) {
    addNode({
      id: `case:${cs.id}`,
      type: 'CaseStudy',
      label: cs.label,
      props: {
        summary: cs.summary || '',
        aliases: cs.aliases || [],
        ...(cs.evidence ? { evidence: cs.evidence } : {}),
        ...cardProps(cs),
      },
      provenance: [{ source: 'case-studies.json', kind: 'catalog' }],
    });
    cardEdges(`case:${cs.id}`, cs);
    for (const m of cs.illustrates || []) {
      addEdge(`case:${cs.id}`, typed(m, 'mechanism'), 'illustrates');
    }
    for (const c of cs.illustratesConcepts || []) {
      addEdge(`case:${cs.id}`, typed(c, 'concept'), 'illustrates');
    }
    for (const cl of cs.illustratesClaims || []) {
      addEdge(`case:${cs.id}`, typed(cl, 'claim'), 'illustrates');
    }
    for (const ch of cs.appearsIn || []) {
      addEdge(`chapter:${ch}`, `case:${cs.id}`, 'covers');
    }
    for (const noteSlug of cs.definedIn || []) {
      addEdge(`case:${cs.id}`, `note:${noteSlug}`, 'definedIn');
    }
    for (const srcSlug of cs.evidencedBy || []) {
      addEdge(`case:${cs.id}`, `source:${srcSlug}`, 'evidencedBy');
    }
  }
}

// ---------------------------------------------------------------- themes
//
// A Theme is a reader-facing cluster of cards with an ordered trail through
// its members. Themes are ordered along the book's arc, so the Explore hub
// built from them follows the narrative while staying browsable.

function loadThemes() {
  const path = resolve(dataDir, 'themes.json');
  if (!existsSync(path)) return;
  const { themes } = JSON.parse(readFileSync(path, 'utf8'));
  const seen = new Map();
  for (const t of themes) {
    addNode({
      id: `theme:${t.id}`,
      type: 'Theme',
      label: t.label,
      props: {
        ordinal: t.ordinal,
        plain: t.plain || '',
        summary: t.summary || '',
        chapters: t.chapters || [],
        members: t.members || [],
      },
      provenance: [{ source: 'themes.json', kind: 'catalog' }],
    });
    (t.members || []).forEach((m, i) => {
      if (seen.has(m)) warnings.push(`theme membership: ${m} is in both theme:${seen.get(m)} and theme:${t.id} — a card has one home theme`);
      seen.set(m, t.id);
      addEdge(m, `theme:${t.id}`, 'inTheme', { order: i });
    });
  }
}

// ---------------------------------------------------------------- claims

function loadTensions() {
  const path = resolve(dataDir, 'tensions.json');
  if (!existsSync(path)) return; // catalog is optional
  const { tensions } = JSON.parse(readFileSync(path, 'utf8'));
  if (!tensions || !tensions.length) return;
  for (const t of tensions) {
    addNode({
      id: `tension:${t.id}`,
      type: 'Tension',
      label: t.label,
      props: {
        summary: t.summary,
        kind: t.kind || 'tensionWith',
        resolution: t.resolution || null,
      },
      provenance: [{ source: 'tensions.json', kind: 'catalog' }],
    });
    if (Array.isArray(t.endpoints) && t.endpoints.length === 2) {
      addEdge(t.endpoints[0], t.endpoints[1], t.kind || 'tensionWith');
    }
    for (const chSlug of t.acknowledgedInChapters || []) {
      addEdge(`chapter:${chSlug}`, `tension:${t.id}`, 'mentions');
    }
    for (const noteSlug of t.acknowledgedInNotes || []) {
      addEdge(`note:${noteSlug}`, `tension:${t.id}`, 'mentions');
    }
  }
}

function loadClaims() {
  const claimsPath = resolve(dataDir, 'claims.json');
  if (!existsSync(claimsPath)) return; // claims populated over time; absent is fine
  const { claims } = JSON.parse(readFileSync(claimsPath, 'utf8'));
  if (!claims || !claims.length) return;
  for (const c of claims) {
    addNode({
      id: `claim:${c.id}`,
      type: 'Claim',
      label: c.label,
      props: {
        summary: c.summary,
        aliases: c.aliases || [],
        status: c.status || 'working',
        harvestedFrom: c.harvestedFrom || [],
      },
      provenance: [{ source: 'claims.json', kind: 'catalog' }],
    });
    for (const slug of c.argues || []) {
      addEdge(`note:${slug}`, `claim:${c.id}`, 'argues');
    }
    for (const slug of c.arguedInChapters || []) {
      addEdge(`chapter:${slug}`, `claim:${c.id}`, 'argues');
    }
    for (const dep of c.dependsOn || []) {
      const target = dep.includes(':') ? dep : `claim:${dep}`;
      addEdge(`claim:${c.id}`, target, 'dependsOn');
    }
    for (const slug of c.supersedes || []) {
      addEdge(`claim:${c.id}`, `claim:${slug}`, 'supersedes');
    }
    for (const slug of c.evidencedBy || []) {
      const target = slug.includes(':') ? slug : `source:${slug}`;
      addEdge(`claim:${c.id}`, target, 'evidencedBy');
    }
  }
}

function checkClaimDrift() {
  // For each canonical Claim, verify its harvestedFrom anchors still appear
  // in the latest candidate set. If not, the prose has moved and the claim
  // may be stale — surface as a warning.
  const candidatesPath = resolve(dataDir, 'claim-candidates.jsonl');
  if (!existsSync(candidatesPath)) return;
  const text = readFileSync(candidatesPath, 'utf8');
  const candidates = text.split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
  const byNote = {};
  for (const c of candidates) (byNote[c.note] ||= []).push(c);
  for (const node of nodes.values()) {
    if (node.type !== 'Claim') continue;
    for (const anchor of node.props?.harvestedFrom || []) {
      const pool = byNote[anchor.note] || [];
      const prefix = (anchor.text || '').slice(0, 40);
      if (!prefix) continue;
      const match = pool.find(c =>
        c.text.includes(prefix) || prefix.includes(c.text.slice(0, 40))
      );
      if (!match) {
        warnings.push(`claim drift: ${node.id} anchor "${prefix}…" not found in ${anchor.note} candidates`);
      }
    }
  }
}

// ---------------------------------------------------------------- source folder checks

function checkSources() {
  // Guardrails for the two source folders. Every staged source file must
  // have a sources.json entry; every declared file must sit in the folder
  // its `availability` implies; no in-copyright file may land in the
  // committed (and Quartz-published) sources/ folder. Only extraction-ready
  // formats are tracked — raw archives (.epub) and partial downloads are
  // staging detritus and intentionally ignored.
  const SOURCE_EXTS = ['.pdf', '.md', '.txt'];
  const committedDir = resolve(NOTES_DIR, 'sources');
  const localDir = resolve(repoRoot, 'sources-local');
  const stagedFilesIn = (dir) => {
    if (!existsSync(dir)) return new Set();
    return new Set(
      readdirSync(dir, { withFileTypes: true })
        .filter(d => d.isFile() && !d.name.startsWith('.'))
        .map(d => d.name)
        // index.md is the folder's generated landing page, not a source.
        .filter(f => f !== 'index.md')
        .filter(f => SOURCE_EXTS.includes(extname(f).toLowerCase())),
    );
  };
  const committed = stagedFilesIn(committedDir);
  const local = stagedFilesIn(localDir);
  const claimed = new Set();

  // Interpretive-edge count per source (computed once, reused below). A
  // source with at least one interpretive edge has already been extracted.
  const interpretiveBySource = new Map();
  for (const e of edges) {
    if (!e.interpretive) continue;
    if (e.source?.startsWith('source:')) interpretiveBySource.set(e.source, (interpretiveBySource.get(e.source) || 0) + 1);
    if (e.target?.startsWith('source:')) interpretiveBySource.set(e.target, (interpretiveBySource.get(e.target) || 0) + 1);
  }

  for (const node of nodes.values()) {
    if (node.type !== 'Source') continue;
    const file = node.props?.file;
    if (!file) continue;
    claimed.add(file);
    const extracted = (interpretiveBySource.get(node.id) || 0) > 0;
    const availability = node.props?.availability || 'external';
    if (availability === 'restricted') {
      if (committed.has(file)) {
        warnings.push(`source ${node.id}: in-copyright file "${file}" is in the committed sources/ folder — move it to sources-local/`);
      }
      // Only nag about a missing in-copyright file if it hasn't been
      // extracted yet. Once interpretive edges exist the PDF no longer needs
      // to be staged — its absence on a fresh clone / CI is expected, not a
      // problem (sources-local/ is gitignored).
      if (!local.has(file) && !extracted) {
        warnings.push(`source ${node.id}: in-copyright file "${file}" not staged in sources-local/ and not yet extracted`);
      }
    } else if (availability === 'open' || availability === 'unverified') {
      if (!committed.has(file)) {
        warnings.push(`source ${node.id}: file "${file}" not found in sources/`);
      }
    } else {
      warnings.push(`source ${node.id}: declares file "${file}" but availability is "${availability}"`);
    }
  }
  for (const f of committed) {
    if (!claimed.has(f)) warnings.push(`orphan source file: sources/${f} has no sources.json entry`);
  }
  for (const f of local) {
    if (!claimed.has(f)) warnings.push(`orphan source file: sources-local/${f} has no sources.json entry`);
  }

  // Extraction-completeness: any Source with a file declared should have
  // at least one interpretive edge by now — supports / pressureTests /
  // evidencedBy / interpretive-mentions. Zero means the extraction agent
  // has not been run against this PDF yet, which is the easiest authoring
  // task to forget. Warning, not error: a freshly added source legitimately
  // has zero edges between sources.json edit and the first extraction.
  // (interpretiveBySource was computed at the top of this function.)
  for (const node of nodes.values()) {
    if (node.type !== 'Source') continue;
    if (!node.props?.file) continue;
    if ((interpretiveBySource.get(node.id) || 0) === 0) {
      warnings.push(`source unread: ${node.id} declares file "${node.props.file}" but has 0 interpretive edges — extraction agent has not been run`);
    }
  }
}

// ---------------------------------------------------------------- note parser

function loadSlugAliases() {
  const path = resolve(dataDir, 'slug-aliases.json');
  if (!existsSync(path)) return {};
  const data = JSON.parse(readFileSync(path, 'utf8'));
  return data.aliases || {};
}

function resolveWikilink(slug, aliases) {
  // Alias overrides take priority (lets the author redirect when default
  // resolution is wrong — e.g. nexus-book → source:nexus).
  if (aliases[slug]) return aliases[slug];
  const priorityNamespaces = [
    'note', 'source', 'chapter', 'claim', 'concept',
    'mechanism', 'question', 'case', 'tradition', 'theme',
  ];
  for (const ns of priorityNamespaces) {
    if (nodes.has(`${ns}:${slug}`)) return `${ns}:${slug}`;
  }
  return null;
}

function parseNotes() {
  const aliases = loadSlugAliases();
  // Snapshot the Note nodes before iteration — addNode merges back in.
  const noteNodes = Array.from(nodes.values()).filter(n => n.type === 'Note');
  for (const node of noteNodes) {
    const filename = node.props?.file;
    if (!filename) continue;
    const filePath = resolve(NOTES_DIR, filename);
    if (!existsSync(filePath)) {
      warnings.push(`note ${node.id} source file missing: ${filename}`);
      continue;
    }
    const content = readFileSync(filePath, 'utf8');
    // The frontmatter `description:` is the note's reader-facing summary
    // (shown by Quartz, and reused by the reading path and chapter maps).
    const fm = content.match(/^---\n([\s\S]*?)\n---/);
    const dm = fm && fm[1].match(/^description:\s*(.+)$/m);
    if (dm) {
      let description = dm[1].trim();
      if (/^".*"$/.test(description)) { try { description = JSON.parse(description); } catch { description = description.slice(1, -1); } }
      else if (/^'.*'$/.test(description)) description = description.slice(1, -1).replace(/''/g, "'");
      addNode({ id: node.id, type: 'Note', props: { description } });
    }
    // Strip YAML frontmatter so its tags don't bleed into wikilink scanning.
    // Also strip the generated chapter-map block: its links restate `covers`
    // / `definedIn` edges and would otherwise echo back in as wikiLinks.
    const body = content
      .replace(/^---\n[\s\S]*?\n---\n?/, '')
      .replace(/<!-- chapter-map:begin[\s\S]*?<!-- chapter-map:end -->\n?/g, '');

    // Extract H2 section anchors → store on the note for navigation.
    const sections = [];
    const sectionRegex = /^##\s+(.+)$/gm;
    let sm;
    while ((sm = sectionRegex.exec(body)) !== null) {
      sections.push(sm[1].trim());
    }
    addNode({ id: node.id, type: 'Note', props: { sections } });
    // Generated hub pages (explore, reading-path) link to everything by
    // construction; their links carry no authorial signal.
    if (node.props?.generated) continue;

    // Extract wikilinks. [[target]] or [[target|display text]].
    const wikilinkRegex = /\[\[([^\]\|]+)(?:\|[^\]]*)?\]\]/g;
    const seen = new Set();
    let m;
    while ((m = wikilinkRegex.exec(body)) !== null) {
      const target = m[1].trim();
      // Skip attachment refs (images, pdfs, etc.)
      if (/\.(png|jpg|jpeg|gif|pdf|svg|webp)$/i.test(target)) continue;
      // Normalise: lowercase, spaces → hyphens, trim
      const slug = target.toLowerCase().replace(/\s+/g, '-');
      if (`note:${slug}` === node.id) continue;  // self-ref
      if (seen.has(slug)) continue;
      seen.add(slug);

      const resolved = resolveWikilink(slug, aliases);
      if (!resolved) {
        warnings.push(`unresolved wikilink in ${node.id}: [[${target}]] (slug:${slug})`);
        continue;
      }
      const predicate = resolved.startsWith('source:') ? 'cites' : 'wikiLinks';
      addEdge(node.id, resolved, predicate);
    }
  }
}

// ---------------------------------------------------------------- card parser
//
// Card pages live at content/{concepts,mechanisms,cases,questions}/<slug>.md.
// The hand-written body sits between `<!-- card -->` and `<!-- /card -->`;
// everything around it is generated. Links inside the body are authorial
// signal — "a reader of this idea should go here next" — so they enter the
// graph as wikiLinks edges from the card's node. This is what makes the
// interlinking visible to (and checkable by) the ontology.

const CARD_REGION = /<!-- card -->\n?([\s\S]*?)\n?<!-- \/card -->/;
const MIN_CARD_LINKS = 3;

function hasOwnNotePage(node) {
  // A card node whose slug is also a top-level note has no card page: the
  // note is its page (e.g. concept:capture-taxonomy ↔ capture-taxonomy.md).
  return nodes.has(`note:${node.id.slice(node.id.indexOf(':') + 1)}`);
}

function parseCards() {
  const aliases = loadSlugAliases();
  const cardNodes = Array.from(nodes.values()).filter(n => CARD_TYPES.includes(n.type));
  for (const node of cardNodes) {
    if (hasOwnNotePage(node)) continue;
    const slug = node.id.slice(node.id.indexOf(':') + 1);
    const filePath = resolve(NOTES_DIR, CARD_DIRS[node.type], `${slug}.md`);
    if (!existsSync(filePath)) continue;
    const m = readFileSync(filePath, 'utf8').match(CARD_REGION);
    if (!m) continue;
    const body = m[1];
    const words = body.replace(/\[\[[^\]|]+\|([^\]]*)\]\]/g, '$1').split(/\s+/).filter(Boolean).length;
    const targets = new Set();
    const wikilinkRegex = /\[\[([^\]\|#]+)(?:#[^\]\|]*)?(?:\|[^\]]*)?\]\]/g;
    let wm;
    while ((wm = wikilinkRegex.exec(body)) !== null) {
      const linkSlug = wm[1].trim().toLowerCase().replace(/\s+/g, '-');
      const resolved = resolveWikilink(linkSlug, aliases);
      if (!resolved) {
        warnings.push(`unresolved wikilink in card ${node.id}: [[${wm[1].trim()}]]`);
        continue;
      }
      if (resolved === node.id) continue;
      targets.add(resolved);
    }
    for (const t of targets) {
      addEdge(node.id, t, t.startsWith('source:') ? 'cites' : 'wikiLinks', { fromCard: true });
    }
    addNode({ id: node.id, type: node.type, props: { hasCard: true, cardWords: words, cardLinks: targets.size } });
  }
}

function checkCards() {
  // The card layer's invariants. Each is a warning (fatal under STRICT):
  // every card has a plain sentence, a home theme, a written body that links
  // out to enough neighbours, and passages that point at real H2 sections.
  const themed = new Set(edges.filter(e => e.predicate === 'inTheme').map(e => e.source));
  for (const node of nodes.values()) {
    if (!CARD_TYPES.includes(node.type)) continue;
    if (!node.props?.plain) warnings.push(`card ${node.id}: no \`plain\` sentence in its catalog entry`);
    if (!themed.has(node.id)) warnings.push(`card ${node.id}: not a member of any theme (data/themes.json)`);
    for (const p of node.props?.passages || []) {
      const note = nodes.get(`note:${p.note}`);
      if (!note) {
        warnings.push(`card ${node.id}: passage points at unknown note "${p.note}"`);
      } else if (!(note.props?.sections || []).includes(p.section)) {
        warnings.push(`card ${node.id}: passage section "${p.section}" is not an H2 in ${p.note}`);
      }
    }
    if (hasOwnNotePage(node)) continue;
    if (!node.props?.hasCard) {
      warnings.push(`card ${node.id}: no written card body (<!-- card --> region) in content/${CARD_DIRS[node.type]}/`);
    } else if ((node.props.cardLinks || 0) < MIN_CARD_LINKS) {
      warnings.push(`card ${node.id}: body links to ${node.props.cardLinks || 0} other pages — needs at least ${MIN_CARD_LINKS}`);
    }
  }

  // Ambiguous terms: a label/alias claimed by two cards can't be auto-linked
  // and makes [[alias]] redirects collide. Compared case-insensitively.
  const owner = new Map();
  for (const node of nodes.values()) {
    if (!CARD_TYPES.includes(node.type)) continue;
    if (node.type === 'Question') continue; // question aliases are not link terms
    for (const term of new Set([node.label, ...(node.props?.aliases || [])].map(t => t.toLowerCase().trim()))) {
      if (owner.has(term) && owner.get(term) !== node.id) {
        warnings.push(`ambiguous term "${term}": claimed by ${owner.get(term)} and ${node.id}`);
      } else {
        owner.set(term, node.id);
      }
    }
  }
}

// ---------------------------------------------------------------- orphan notes

function checkOrphanNotes() {
  // Every top-level content/*.md should be seeded as a Note — the parser
  // only walks seeded notes, so an unseeded file is silently invisible to
  // the graph (no wikilinks, no claims scope, no context bundles).
  // Subdirectories (citations/, concepts/, experiments/, …) are
  // deliberately out of scope: generated pages and trackers live there,
  // not argument-bearing prose.
  const seeded = new Set();
  for (const n of nodes.values()) {
    if (n.type === 'Note' && n.props?.file) seeded.add(n.props.file);
  }
  for (const f of readdirSync(NOTES_DIR, { withFileTypes: true })) {
    if (!f.isFile() || !f.name.endsWith('.md')) continue;
    if (!seeded.has(f.name)) {
      warnings.push(`orphan note: content/${f.name} is not seeded as a Note — invisible to the graph`);
    }
  }
}

// ---------------------------------------------------------------- interpretive

// Direction conventions for interpretive predicates, mirrored from
// scripts/aggregate-interpretive.js (the canonical validator). Used only by
// the per-PDF fallback below so a bare `make build` can't admit malformed
// triples (e.g. a Concept as the subject of `supports`).
const INTERPRETIVE_DIRECTION_RULES = {
  supports:      { subject: ['source:'], object: ['claim:', 'mechanism:', 'concept:'] },
  pressureTests: { subject: ['source:'], object: ['claim:', 'mechanism:', 'concept:'] },
  evidencedBy:   { object: ['source:', 'note:'] },
};

function addInterpretiveEdge(t) {
  if (!meta.predicates[t.predicate]) return;
  addEdge(t.subject, t.object, t.predicate, {
    interpretive: true,
    quote: t.quote,
    pageApprox: t.pageApprox,
    confidence: t.confidence,
    rationale: t.rationale,
    sourceFile: t.sourceFile,
  });
}

function loadInterpretive() {
  // Fast path: the aggregated, validated, de-duped file produced by
  // `make aggregate-interpretive` / `make extract-build`.
  const aggregate = resolve(dataDir, 'interpretive-triples.jsonl');
  const perPdfDir = resolve(dataDir, 'interpretive');
  if (existsSync(aggregate)) {
    // Guard: the aggregate is gitignored and easy to forget. If any
    // committed per-PDF extraction is newer, the fast path would silently
    // build from stale data — warn and name the canonical refresh.
    if (existsSync(perPdfDir)) {
      const aggMtime = statSync(aggregate).mtimeMs;
      for (const f of readdirSync(perPdfDir).filter(f => f.endsWith('.jsonl')).sort()) {
        if (statSync(resolve(perPdfDir, f)).mtimeMs > aggMtime) {
          warnings.push(`stale aggregate: data/interpretive/${f} is newer than interpretive-triples.jsonl — run \`make extract-build\``);
        }
      }
    }
    const lines = readFileSync(aggregate, 'utf8').split('\n').filter(l => l.trim());
    for (const line of lines) addInterpretiveEdge(JSON.parse(line));
    return;
  }

  // Fallback: no aggregate present (it is gitignored, so absent on a fresh
  // clone). Read the committed per-PDF extractions directly so the
  // source-evidence layer (supports / pressureTests / evidencedBy) still
  // ships from a bare `make build`. Apply the same direction checks the
  // aggregator enforces — and surface the same conditions as warnings, so
  // the bare path is never quieter than `make extract-build` about bad
  // data. Node-existence and de-dup are handled downstream (validateEdges
  // drops dangling endpoints with a warning, addEdge de-dups by s|p|o).
  if (!existsSync(perPdfDir)) return;
  for (const f of readdirSync(perPdfDir).filter(f => f.endsWith('.jsonl')).sort()) {
    const slug = f.replace(/\.jsonl$/, '');
    for (const line of readFileSync(resolve(perPdfDir, f), 'utf8').split('\n')) {
      if (!line.trim()) continue;
      let t;
      try { t = JSON.parse(line); } catch {
        warnings.push(`interpretive ${f}: malformed JSON: ${line.slice(0, 80)}…`);
        continue;
      }
      if (t._note) continue; // trailing agent notes are expected, not data
      if (!t.subject || !t.predicate || !t.object) {
        warnings.push(`interpretive ${f}: missing s/p/o: ${line.slice(0, 120)}`);
        continue;
      }
      const rule = INTERPRETIVE_DIRECTION_RULES[t.predicate];
      if (rule) {
        if (rule.subject && !rule.subject.some(p => t.subject.startsWith(p))) {
          warnings.push(`interpretive ${f}: ${t.predicate} subject must be ${rule.subject.join(' / ')}* — got "${t.subject}"`);
          continue;
        }
        if (rule.object && !rule.object.some(p => t.object.startsWith(p))) {
          warnings.push(`interpretive ${f}: ${t.predicate} object must be ${rule.object.join(' / ')}* — got "${t.object}"`);
          continue;
        }
      }
      addInterpretiveEdge({ ...t, sourceFile: t.sourceFile || slug });
    }
  }
}

// ---------------------------------------------------------------- emit

function emit() {
  const nodesPath = resolve(dataDir, 'nodes.jsonl');
  const edgesPath = resolve(dataDir, 'edges.jsonl');
  const statsPath = resolve(dataDir, 'build-stats.json');

  const nodeLines = Array.from(nodes.values()).map(n => JSON.stringify(n)).join('\n');
  const edgeLines = edges.map(e => JSON.stringify(e)).join('\n');
  writeFileSync(nodesPath, nodeLines + (nodeLines ? '\n' : ''));
  writeFileSync(edgesPath, edgeLines + (edgeLines ? '\n' : ''));

  const byType = {};
  for (const n of nodes.values()) byType[n.type] = (byType[n.type] || 0) + 1;
  const byPredicate = {};
  for (const e of edges) byPredicate[e.predicate] = (byPredicate[e.predicate] || 0) + 1;

  const stats = {
    builtAt: new Date().toISOString(),
    counts: { nodes: nodes.size, edges: edges.length, warnings: warnings.length },
    byNodeType: byType,
    byPredicate,
    warnings,
  };
  writeFileSync(statsPath, JSON.stringify(stats, null, 2));

  console.log(`build-graph: ${nodes.size} nodes, ${edges.length} edges, ${warnings.length} warnings`);
  for (const w of warnings) console.error('  ' + w);

  // STRICT=1 (CI, make check) turns warnings into a failed build. Local
  // authoring stays lenient — warnings are the worklist, not a wall.
  if (process.env.STRICT && warnings.length) {
    console.error(`build-graph: STRICT — failing on ${warnings.length} warning(s)`);
    process.exitCode = 1;
  }
}

// ---------------------------------------------------------------- main

seedStatuses();
seedParts();
seedPipeline();
seedChapters();
seedNotes();
loadMechanisms();
loadConcepts();
loadQuestions();
loadTraditions();
loadSources();
loadCaseStudies();
loadClaims();
loadTensions();
loadThemes();
checkClaimDrift();
parseNotes();
parseCards();
checkOrphanNotes();
loadInterpretive();
checkSources();
validateEdges();
checkCards();
emit();
