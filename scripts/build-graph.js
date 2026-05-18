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

import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const META_PATH = resolve(dataDir, 'graph-meta.json');

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
    phase: 0,
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
validateEdges();
emit();
