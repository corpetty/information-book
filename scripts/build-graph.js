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

import { readFileSync, writeFileSync, existsSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, extname } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const META_PATH = resolve(dataDir, 'graph-meta.json');
const NOTES_DIR = resolve(repoRoot, '..', 'quartz', 'content', 'notes', 'information-book');

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
  const key = `${source}|${predicate}|${target}`;
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
  const parts = [
    { slug: 'pipeline',    ordinal: 1, label: 'Part I — The Pipeline',
      summary: 'How information moves from reality to people.' },
    { slug: 'lossy',       ordinal: 2, label: 'Part II — Why It Has To Be Lossy (And Selective)',
      summary: 'The structural reasons compression and selection both operate.' },
    { slug: 'bridge-zone', ordinal: 3, label: 'Part III — The Bridge Zone',
      summary: 'Where complex specialist knowledge gets transformed (and often destroyed) on its way to mass audiences.' },
    { slug: 'integration', ordinal: 4, label: 'Part IV — A Way Through',
      summary: 'Hypothesis territory. Rebuilt around integration between networks that don\'t share preconditions.' },
  ];
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

function seedChapters() {
  const chapters = [
    { slug: 'information-landscape',                part: 'pipeline',    ordinal: 1,   number: '1',  title: 'The Information Landscape',              status: 'drafted',         draftNote: 'note:the-information-landscape',     summary: 'Walks through the transport pipeline (The Out There → Raw Data → Insight → Theory → News → Meme) stage by stage, then introduces the sibling selection pipeline. Closes with where the medium fits and a note that the gates are tunable institutional choices.' },
    { slug: 'case-studies-and-three-realities',     part: 'pipeline',    ordinal: 2,   number: '2',  title: 'Case Studies and Three Realities',       status: 'skeleton',                                                                          summary: 'Brings the abstract structure to ground with case studies of specific pipelines. Also the right home for Harari\'s three-realities framework (objective / subjective / intersubjective).' },
    { slug: 'human-time-budget',                    part: 'lossy',       ordinal: 3,   number: '3',  title: 'The Human Time Budget',                  status: 'in-workshop',     draftNote: 'note:info-time-limit',                summary: 'Tablespoon of weeks; effective mental hours less than nominal. Budget is not fixed — education, vocabulary, accumulated engagement expand it. Want is the prime mover.' },
    { slug: 'optionality-vs-access',                part: 'lossy',       ordinal: 4,   number: '4',  title: 'Optionality vs. Access',                 status: 'in-workshop',     draftNote: 'note:optionality-vs-access',          summary: 'The general-vs-usable trade-off. Drafted using matplotlib vs. seaborn. Needs generalization beyond software: religions, political platforms, scientific popularization, legal codes.' },
    { slug: 'complexity-virality-tradeoff',         part: 'lossy',       ordinal: 5,   number: '5',  title: 'The Complexity / Virality Trade-off',    status: 'in-workshop',     draftNote: 'note:complexity-virality-tradeoff',   summary: 'The transport half of the two-mechanism structure. Within-stage compression dynamics, most visible at the meme stage. Reframes Hammer/Copernicus as selection-fit rather than transport-cost.' },
    { slug: 'selection-as-other-engine',            part: 'lossy',       ordinal: 5.1, number: '5b', title: 'Selection As The Other Engine',          status: 'in-workshop',     draftNote: 'note:selection-as-other-engine',      summary: 'The selection half of the two-mechanism structure: the three-operation stage model (transport generates, the medium bounds, selection picks), selection as the tunable mechanism, and the medium as frozen selection. Engages Mercier and O\'Connor & Weatherall.' },
    { slug: 'truth-compression-and-when-each-wins', part: 'lossy',       ordinal: 5.2, number: '5c', title: 'Truth, Compression, and When Each Wins', status: 'in-workshop', draftNote: 'note:truth-compression-and-when-each-wins',                                                                  summary: 'When does compressed form preserve approximate truth, when invert, when orthogonal? Closes the moral-neutrality gap and gives the book its actual stakes.' },
    { slug: 'bridge-zone-distortion',               part: 'bridge-zone', ordinal: 6,   number: '6',  title: 'Where It All Gets Fucked Up',            status: 'skeleton',                                                                          summary: 'The space between deep specialists and mass audiences. Journalism, popularizers, influencers, AI summarizers. Where selection pressures are most intense and active reshaping happens.' },
    { slug: 'emotional-memetics',                   part: 'bridge-zone', ordinal: 7,   number: '7',  title: 'Emotional Memetics As The Floor',        status: 'skeleton',                                                                          summary: 'Once the network is big enough, what propagates is what evokes raw strong emotions. Must engage Mercier\'s challenge that humans have robust epistemic vigilance.' },
    { slug: 'preservation-vs-training',             part: 'integration', ordinal: 8,   number: '8',  title: 'Preservation vs. Training',              status: 'not-yet-drafted',                                                                  summary: 'Splits what Harari\'s "bureaucracy" was bundling. Preservation keeps the complex form alive; training expands receiver budgets. Different infrastructure for each.' },
    { slug: 'integration-problem',                  part: 'integration', ordinal: 9,   number: '9',  title: 'The Integration Problem',                status: 'not-yet-drafted',                                                                  summary: 'How does complex truth move between networks that don\'t share preconditions? Nguyen on epistemic bubbles vs. echo chambers. Bridge nodes carrying transferable preconditions stitch.' },
    { slug: 'political-economy-of-attention',       part: 'integration', ordinal: 10,  number: '10', title: 'Political Economy of Attention',         status: 'not-yet-drafted',                                                                  summary: 'Who owns the infrastructure, what they optimize for, why engagement maximization exists, why institutional carriers are being defunded. Cost-shifting from producers to consumers.' },
    { slug: 'ai-as-new-node',                       part: 'integration', ordinal: 11,  number: '11', title: 'AI as a New Kind of Node',               status: 'not-yet-drafted',                                                                  summary: 'LLMs violate the receiver-budget model. Decompress on demand, compress aggressively. Both new node and new selection engine. Salvation and worst-case depending on deployment.' },
    { slug: 'infrastructure-for-integration',       part: 'integration', ordinal: 12,  number: '12', title: 'Infrastructure for Integration',         status: 'not-yet-drafted',                                                                  summary: 'Synthesis. What would tech look like if it preserved integrity across networks rather than flattening it? Curation layer, Wikipedia editorial, Stack Overflow reputation, preprint + peer review hybrids.' },
  ];
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
        ...(c.draftNote ? { draftNote: c.draftNote } : {}),
      },
      provenance: [{ source: 'outline.md', kind: 'seed' }],
    });
    addEdge(`chapter:${c.slug}`, `part:${c.part}`, 'partOf');
    addEdge(`chapter:${c.slug}`, `status:${c.status}`, 'hasStatus');
  }
}

function seedNotes() {
  const notes = [
    { slug: 'outline',                      file: 'outline.md',                      subtype: 'prose',        title: 'Information Book — Outline',                                role: 'outline',             summary: 'The book\'s working outline and table of contents. Living doc.' },
    { slug: 'the-information-landscape',    file: 'the-information-landscape.md',    subtype: 'prose',        title: 'The Information Landscape',                                 role: 'chapter-draft',       summary: 'Chapter 1 draft. Walks through the transport and selection pipelines side by side.' },
    { slug: 'transport-vs-selection',       file: 'transport-vs-selection.md',       subtype: 'prose',        title: 'Transport vs. Selection',                                   role: 'foundational-note',   summary: 'Foundational note working through the transport-vs-selection question. Provisional answer: both parallel mechanisms, with want as prime mover.' },
    { slug: 'complexity-virality-tradeoff', file: 'complexity-virality-tradeoff.md', subtype: 'prose',        title: 'The Complexity / Virality Trade-off',                       role: 'chapter-draft',       summary: 'Chapter 5 draft. The transport half of the two-mechanism structure.' },
    { slug: 'info-time-limit',              file: 'info-time-limit.md',              subtype: 'prose',        title: 'The limit on how much information a human can incorporate', role: 'chapter-draft',       summary: 'Chapter 3 draft (partial). Receiver budget: tablespoon of weeks.' },
    { slug: 'optionality-vs-access',        file: 'optionality vs access.md',        subtype: 'prose',        title: 'Optionality vs. Access',                                    role: 'chapter-draft',       summary: 'Chapter 4 draft (software-only). The general-vs-usable trade-off through matplotlib vs. seaborn.' },
    { slug: 'general-theme',                file: 'general-theme.md',                subtype: 'conversation', title: 'General Theme',                                             role: 'conversation-source', summary: 'Conversation transcript. The book concept explained to someone in real time. The conclusion of Part IV lives raw here.' },
    { slug: 'medium-and-manipulation', file: 'medium-and-manipulation.md', subtype: 'prose', title: 'Medium and Manipulation', role: 'foundational-note', summary: 'Foundational note on what the medium does to the selection gates. Provisional answer: the medium is the selection criteria — it sets the capacity, the criteria, and the want cultivated at every gate.' },
    { slug: 'three-layer-message', file: 'three-layer-message.md', subtype: 'prose', title: 'The Three Layers of a Message', role: 'foundational-note', summary: 'Foundational note adapting the frame/outer/inner message model from Hofstadter. The outer message — the decoding mechanism — is what the book calls preconditions, and it lives in the medium.' },
    { slug: 'truth-compression-and-when-each-wins', file: 'truth-compression-and-when-each-wins.md', subtype: 'prose', title: 'Truth, Compression, and When Each Wins', role: 'chapter-draft', summary: 'Chapter 5c draft. Resolves the truth-value-placement question — compression strips the decoding key, and truth is preserved, inverted, or rendered orthogonal depending on the key-gap and which compressed variant the selection gate picks.' },
    { slug: 'myths-scale-and-bureaucracy', file: 'myths-scale-and-bureaucracy.md', subtype: 'prose', title: 'Myths, Scale, and Bureaucracy', role: 'foundational-note', summary: 'Foundational note. Works out the loop: network scale forces myth compression, compression widens interpretive latitude, latitude segments the network, and segmentation forces the bureaucracy that re-supplies the dropped decoding key.' },
    { slug: 'selection-as-other-engine', file: 'selection-as-other-engine.md', subtype: 'prose', title: 'Selection As The Other Engine', role: 'chapter-draft', summary: 'Chapter 5b draft. The selection half of the two-mechanism structure: the three-operation stage model (transport generates, the medium bounds, selection picks), selection as the tunable mechanism, and the medium as frozen selection.' },
  ];
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
      },
      provenance: [{ source: n.file, kind: 'seed' }],
    });
  }
}

// ---------------------------------------------------------------- catalog loaders

function loadJsonCatalog(filename) {
  return JSON.parse(readFileSync(resolve(dataDir, filename), 'utf8'));
}

function loadMechanisms() {
  const { mechanisms } = loadJsonCatalog('mechanisms.json');
  for (const m of mechanisms) {
    addNode({
      id: `mechanism:${m.id}`,
      type: 'Mechanism',
      label: m.label,
      props: { summary: m.summary, aliases: m.aliases || [] },
      provenance: [{ source: 'mechanisms.json', kind: 'catalog' }],
    });
    for (const noteSlug of m.definedIn || []) {
      addEdge(`mechanism:${m.id}`, `note:${noteSlug}`, 'definedIn');
    }
    for (const chSlug of m.coveredBy || []) {
      addEdge(`chapter:${chSlug}`, `mechanism:${m.id}`, 'covers');
    }
    for (const otherSlug of m.derivesFrom || []) {
      addEdge(`mechanism:${m.id}`, `mechanism:${otherSlug}`, 'derivesFrom');
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
      props: { summary: c.summary, aliases: c.aliases || [] },
      provenance: [{ source: 'concepts.json', kind: 'catalog' }],
    });
    for (const noteSlug of c.definedIn || []) {
      addEdge(`concept:${c.id}`, `note:${noteSlug}`, 'definedIn');
    }
    for (const chSlug of c.coveredBy || []) {
      addEdge(`chapter:${chSlug}`, `concept:${c.id}`, 'covers');
    }
    for (const srcSlug of c.evidencedBy || []) {
      addEdge(`concept:${c.id}`, `source:${srcSlug}`, 'evidencedBy');
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
      },
      provenance: [{ source: 'questions.json', kind: 'catalog' }],
    });
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
  }
}

function loadCaseStudies() {
  const { caseStudies } = loadJsonCatalog('case-studies.json');
  for (const cs of caseStudies) {
    addNode({
      id: `case:${cs.id}`,
      type: 'CaseStudy',
      label: cs.label,
      props: { summary: cs.summary || '' },
      provenance: [{ source: 'case-studies.json', kind: 'catalog' }],
    });
    for (const m of cs.illustrates || []) {
      addEdge(`case:${cs.id}`, `mechanism:${m}`, 'mentions');
    }
    for (const c of cs.illustratesConcepts || []) {
      addEdge(`case:${cs.id}`, `concept:${c}`, 'mentions');
    }
    for (const cl of cs.illustratesClaims || []) {
      addEdge(`case:${cs.id}`, `claim:${cl}`, 'mentions');
    }
    for (const ch of cs.appearsIn || []) {
      addEdge(`chapter:${ch}`, `case:${cs.id}`, 'covers');
    }
  }
}

// ---------------------------------------------------------------- claims

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
        .filter(f => SOURCE_EXTS.includes(extname(f).toLowerCase())),
    );
  };
  const committed = stagedFilesIn(committedDir);
  const local = stagedFilesIn(localDir);
  const claimed = new Set();

  for (const node of nodes.values()) {
    if (node.type !== 'Source') continue;
    const file = node.props?.file;
    if (!file) continue;
    claimed.add(file);
    const availability = node.props?.availability || 'external';
    if (availability === 'restricted') {
      if (committed.has(file)) {
        warnings.push(`source ${node.id}: in-copyright file "${file}" is in the committed sources/ folder — move it to sources-local/`);
      }
      if (!local.has(file)) {
        warnings.push(`source ${node.id}: file "${file}" not found in sources-local/`);
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
    'mechanism', 'question', 'case', 'tradition',
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
    // Strip YAML frontmatter so its tags don't bleed into wikilink scanning.
    const body = content.replace(/^---\n[\s\S]*?\n---\n?/, '');

    // Extract H2 section anchors → store on the note for navigation.
    const sections = [];
    const sectionRegex = /^##\s+(.+)$/gm;
    let sm;
    while ((sm = sectionRegex.exec(body)) !== null) {
      sections.push(sm[1].trim());
    }
    addNode({ id: node.id, type: 'Note', props: { sections } });

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

// ---------------------------------------------------------------- interpretive

function loadInterpretive() {
  const path = resolve(dataDir, 'interpretive-triples.jsonl');
  if (!existsSync(path)) return;
  const lines = readFileSync(path, 'utf8').split('\n').filter(l => l.trim());
  for (const line of lines) {
    const t = JSON.parse(line);
    addEdge(t.subject, t.object, t.predicate, {
      interpretive: true,
      quote: t.quote,
      pageApprox: t.pageApprox,
      confidence: t.confidence,
      rationale: t.rationale,
      sourceFile: t.sourceFile,
    });
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
    phase: 11,
    builtAt: new Date().toISOString(),
    counts: { nodes: nodes.size, edges: edges.length, warnings: warnings.length },
    byNodeType: byType,
    byPredicate,
    warnings,
  };
  writeFileSync(statsPath, JSON.stringify(stats, null, 2));

  console.log(`build-graph: ${nodes.size} nodes, ${edges.length} edges, ${warnings.length} warnings`);
  for (const w of warnings) console.error('  ' + w);
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
checkClaimDrift();
parseNotes();
loadInterpretive();
checkSources();
validateEdges();
emit();
