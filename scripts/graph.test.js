// Graph regression tests — the safety net around build-graph.js.
//
// Two layers:
//   1. Golden snapshot — the built graph's counts (per node type, per
//      predicate, warning count) must match data/expected-stats.json.
//      Any intentional graph change updates that file in the same commit
//      (`make accept-stats`), so an unintentional change turns CI red.
//   2. Invariants — properties that must hold regardless of content:
//      edge direction conventions, dedup, endpoint existence, note files
//      on disk, chapter structure, and the Quartz Explorer reading order
//      staying in sync with chapter ordinals.
//
// Run via `make test` (or `node --test scripts/`). The build itself runs
// once, up front — it is sub-second and tests always see fresh output.

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');

// ---------------------------------------------------------------- build once

execFileSync(process.execPath, [resolve(__dirname, 'build-graph.js')], {
  cwd: repoRoot,
  stdio: ['ignore', 'ignore', 'inherit'], // surface warnings, hide the count line
});

const readJsonl = (name) =>
  readFileSync(resolve(dataDir, name), 'utf8')
    .split('\n').filter(l => l.trim()).map(l => JSON.parse(l));

const nodes = readJsonl('nodes.jsonl');
const edges = readJsonl('edges.jsonl');
const stats = JSON.parse(readFileSync(resolve(dataDir, 'build-stats.json'), 'utf8'));
const nodeById = new Map(nodes.map(n => [n.id, n]));

// ---------------------------------------------------------------- snapshot

test('golden snapshot: counts match data/expected-stats.json', () => {
  const expected = JSON.parse(readFileSync(resolve(dataDir, 'expected-stats.json'), 'utf8'));
  const actual = {
    counts: stats.counts,
    byNodeType: stats.byNodeType,
    byPredicate: stats.byPredicate,
    warnings: stats.warnings,
  };
  assert.deepEqual(
    actual,
    expected,
    'built graph differs from expected-stats.json — if the change is intentional, run `make accept-stats` and commit it',
  );
});

test('build emits zero warnings', () => {
  assert.deepEqual(stats.warnings, [], `build warnings:\n  ${stats.warnings.join('\n  ')}`);
});

test('README headline stats match the built graph', () => {
  const readme = readFileSync(resolve(repoRoot, 'README.md'), 'utf8');
  const m = readme.match(/\*\*(\d+) nodes \/ (\d+) edges \/ (\d+) warnings\*\*/);
  assert.ok(m, 'could not find the "**N nodes / N edges / N warnings**" line in README.md');
  assert.deepEqual(
    { nodes: +m[1], edges: +m[2], warnings: +m[3] },
    { nodes: stats.counts.nodes, edges: stats.counts.edges, warnings: stats.counts.warnings },
    'README headline stats are stale — update the line in README.md to match the build',
  );
});

// ---------------------------------------------------------------- edge invariants

test('edge direction conventions hold', () => {
  const bad = [];
  for (const e of edges) {
    if (e.predicate === 'supports' || e.predicate === 'pressureTests') {
      if (!e.source.startsWith('source:')) bad.push(`${e.predicate} subject must be source:* — ${e.source} → ${e.target}`);
      if (!/^(claim|mechanism|concept):/.test(e.target)) bad.push(`${e.predicate} object must be claim/mechanism/concept — ${e.source} → ${e.target}`);
    }
    if (e.predicate === 'evidencedBy' && !/^(source|note):/.test(e.target)) {
      bad.push(`evidencedBy object must be source/note — ${e.source} → ${e.target}`);
    }
    if (e.predicate === 'argues' && !/^(note|chapter):/.test(e.source)) {
      bad.push(`argues subject must be note/chapter — ${e.source} → ${e.target}`);
    }
    if (e.predicate === 'covers' && !e.source.startsWith('chapter:')) {
      bad.push(`covers subject must be chapter — ${e.source} → ${e.target}`);
    }
  }
  assert.deepEqual(bad, []);
});

test('no duplicate (subject, predicate, object) triples', () => {
  const seen = new Set();
  const dups = [];
  for (const e of edges) {
    const key = `${e.source}|${e.predicate}|${e.target}`;
    if (seen.has(key)) dups.push(key);
    seen.add(key);
  }
  assert.deepEqual(dups, []);
});

test('every edge endpoint is an existing node', () => {
  const dangling = edges
    .filter(e => !nodeById.has(e.source) || !nodeById.has(e.target))
    .map(e => `${e.source} -[${e.predicate}]-> ${e.target}`);
  assert.deepEqual(dangling, []);
});

// ---------------------------------------------------------------- node invariants

test('every Note declares a file that exists in content/', () => {
  const missing = nodes
    .filter(n => n.type === 'Note' && n.props?.file)
    .filter(n => !existsSync(resolve(repoRoot, 'content', n.props.file)))
    .map(n => `${n.id} → content/${n.props.file}`);
  assert.deepEqual(missing, []);
});

test('every Chapter has partOf and hasStatus edges and a resolvable draftNote', () => {
  const problems = [];
  for (const n of nodes.filter(n => n.type === 'Chapter')) {
    if (!edges.some(e => e.source === n.id && e.predicate === 'partOf')) problems.push(`${n.id}: no partOf`);
    if (!edges.some(e => e.source === n.id && e.predicate === 'hasStatus')) problems.push(`${n.id}: no hasStatus`);
    if (n.props?.draftNote && !nodeById.has(n.props.draftNote)) problems.push(`${n.id}: draftNote ${n.props.draftNote} missing`);
  }
  assert.deepEqual(problems, []);
});

// NOTE: the "Quartz Explorer reading order matches chapter ordinals" test was
// removed in the Quartz v5 migration. It guarded the custom reading-order
// Explorer sortFn (a hardcoded ORDER array in site/quartz.layout.ts), which v5
// dropped — YAML config can't hold a JS sort function, so the sidebar now uses
// v5's default sort. See project_quartz_v5_migration for context.
