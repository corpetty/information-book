#!/usr/bin/env node
// Generate data/extraction-catalog.json from the current graph state.
// The extraction agents read this file to know which subject/object ids
// they're allowed to use in interpretive triples.
//
// Run via `make catalog`. The catalog is regenerated whenever the graph
// expands (new mechanisms, concepts, claims, etc.), so agents always
// have an up-to-date id set to validate against.

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');

const NODES_PATH = resolve(dataDir, 'nodes.jsonl');
const META_PATH = resolve(dataDir, 'graph-meta.json');
const OUT_PATH = resolve(dataDir, 'extraction-catalog.json');

if (!existsSync(NODES_PATH)) {
  console.error('build-catalog: data/nodes.jsonl missing — run `make build` first');
  process.exit(1);
}

const meta = JSON.parse(readFileSync(META_PATH, 'utf8'));
const nodeLines = readFileSync(NODES_PATH, 'utf8').split('\n').filter(l => l.trim());
const nodes = nodeLines.map(l => JSON.parse(l));

// Types worth listing for extraction. Status / Part / PipelineStage / Gate
// rarely appear in extracted academic-paper triples; included anyway for
// completeness so the agent can recognise them if needed.
const ALL_TYPES = [
  'Claim', 'Mechanism', 'Concept', 'Question', 'CaseStudy',
  'Source', 'Author', 'Tradition',
  'Chapter', 'Note',
  'Part', 'Status', 'PipelineStage', 'Gate', 'Tension',
];

const byType = {};
for (const t of ALL_TYPES) byType[t] = [];
for (const n of nodes) {
  if (!byType[n.type]) byType[n.type] = [];
  byType[n.type].push({
    id: n.id,
    label: n.label,
    summary: n.props?.summary || n.props?.title || '',
    aliases: n.props?.aliases || [],
  });
}

const predicateMeta = {};
for (const [name, p] of Object.entries(meta.predicates)) {
  predicateMeta[name] = {
    category: p.category,
    directed: p.directed,
    description: p.description,
  };
}

const catalog = {
  _doc: 'Generated catalog of valid subject/object ids and predicate definitions for the interpretive-extraction agents. Regenerate via `make catalog` after the graph expands.',
  generated: new Date().toISOString(),
  predicateGuidance: {
    primary: ['supports', 'pressureTests', 'evidencedBy'],
    secondary: ['mentions', 'cites'],
    advanced: ['derivesFrom', 'enables', 'tensionWith', 'contradicts'],
  },
  predicates: predicateMeta,
  byType,
};

writeFileSync(OUT_PATH, JSON.stringify(catalog, null, 2));

const totalIds = Object.values(byType).reduce((acc, l) => acc + l.length, 0);
const nonEmpty = Object.entries(byType).filter(([_, l]) => l.length).map(([k, l]) => `${k}=${l.length}`).join(' ');
console.log(`build-catalog: ${totalIds} ids → data/extraction-catalog.json`);
console.log(`  ${nonEmpty}`);
