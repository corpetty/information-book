#!/usr/bin/env node
// Source dashboard. Reads the built graph (data/nodes.jsonl, data/edges.jsonl)
// and prints a status line for every Source node — catalog metadata plus
// extraction counts derived from the graph. Run via `make sources`.
//
// Extraction status is never hand-maintained: it is the count of
// interpretive edges incident to each source, computed fresh every run.

import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const dataDir = resolve(__dirname, '..', 'data');
const nodesPath = resolve(dataDir, 'nodes.jsonl');
const edgesPath = resolve(dataDir, 'edges.jsonl');

if (!existsSync(nodesPath) || !existsSync(edgesPath)) {
  console.error('No build outputs found — run `make build` first.');
  process.exit(1);
}

const readJsonl = (p) =>
  readFileSync(p, 'utf8').split('\n').filter(l => l.trim()).map(l => JSON.parse(l));

const nodes = readJsonl(nodesPath);
const edges = readJsonl(edgesPath);

const sources = nodes
  .filter(n => n.type === 'Source')
  .sort((a, b) => a.id.localeCompare(b.id));

const counts = {};
for (const s of sources) counts[s.id] = { triples: 0, supports: 0, pressureTests: 0 };

for (const e of edges) {
  const subj = counts[e.source];
  const obj = counts[e.target];
  if (e.predicate === 'supports' && subj) subj.supports++;
  if (e.predicate === 'pressureTests' && subj) subj.pressureTests++;
  if (e.interpretive) {
    if (subj) subj.triples++;
    else if (obj) obj.triples++;
  }
}

const padR = (v, n) => String(v).padEnd(n);
const padL = (v, n) => String(v).padStart(n);

const header =
  padR('SOURCE', 29) + padR('KIND', 23) + padR('AVAILABILITY', 13) +
  padR('TAGS', 24) + padR('FILE', 6) +
  padL('TRIPLES', 8) + padL('SUPP', 6) + padL('PTEST', 7);
console.log(header);
console.log('-'.repeat(header.length));

for (const s of sources) {
  const p = s.props || {};
  const c = counts[s.id];
  console.log(
    padR(s.id.replace(/^source:/, ''), 29) +
    padR(p.kind || '', 23) +
    padR(p.availability || '', 13) +
    padR((p.tags || []).join(','), 24) +
    padR(p.file ? 'yes' : '—', 6) +
    padL(c.triples, 8) + padL(c.supports, 6) + padL(c.pressureTests, 7)
  );
}

console.log('-'.repeat(header.length));
const byAvail = {};
for (const s of sources) {
  const a = s.props?.availability || 'external';
  byAvail[a] = (byAvail[a] || 0) + 1;
}
const extracted = sources.filter(s => counts[s.id].triples > 0).length;
console.log(
  `${sources.length} sources · ${extracted} with extracted triples · ` +
  Object.entries(byAvail).sort().map(([k, v]) => `${k}:${v}`).join('  ')
);
