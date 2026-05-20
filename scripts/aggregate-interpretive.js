#!/usr/bin/env node
// Aggregate per-PDF interpretive extractions into a single validated JSONL.
//
// Reads each data/interpretive/<slug>.jsonl, validates every triple
// against the extraction catalog (subject and object must be known ids,
// predicate must be in the vocabulary), de-duplicates by
// (subject, predicate, object), writes the merged set to
// data/interpretive-triples.jsonl, and notes any drops or trailing
// agent notes to data/interpretive-notes.json.

import { readFileSync, writeFileSync, readdirSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, basename } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');

const CATALOG_PATH = resolve(dataDir, 'extraction-catalog.json');
const INPUT_DIR = resolve(dataDir, 'interpretive');
const OUT_PATH = resolve(dataDir, 'interpretive-triples.jsonl');
const NOTES_PATH = resolve(dataDir, 'interpretive-notes.json');

if (!existsSync(CATALOG_PATH)) {
  console.error('aggregate-interpretive: data/extraction-catalog.json missing — run `make catalog` first');
  process.exit(1);
}

const catalog = JSON.parse(readFileSync(CATALOG_PATH, 'utf8'));
const validIds = new Set();
for (const list of Object.values(catalog.byType)) {
  for (const item of list) validIds.add(item.id);
}
const validPreds = new Set(Object.keys(catalog.predicates));

// Direction conventions the extraction agents must respect. supports /
// pressureTests assert a Source's stance on an argument-bearing element
// (Claim / Mechanism / Concept) — the subject is ALWAYS a Source.
// evidencedBy points a graph node at a Source (or Note). Triples that
// violate these are dropped — the usual offender is a Concept emitted as
// the subject of `supports`, which conflates "paper supports X" with
// "paper engages concept". See scripts/EXTRACTION_PROMPT.md.
const DIRECTION_RULES = {
  supports:      { subject: ['source:'], object: ['claim:', 'mechanism:', 'concept:'] },
  pressureTests: { subject: ['source:'], object: ['claim:', 'mechanism:', 'concept:'] },
  evidencedBy:   { object: ['source:', 'note:'] },
};

if (!existsSync(INPUT_DIR)) {
  writeFileSync(OUT_PATH, '');
  writeFileSync(NOTES_PATH, JSON.stringify({
    generated: new Date().toISOString(),
    files: 0,
    triples: 0,
    warnings: [],
    fileNotes: [],
  }, null, 2));
  console.log('aggregate-interpretive: no data/interpretive/ directory — wrote empty aggregate');
  process.exit(0);
}

const triples = [];
const warnings = [];
const fileNotes = [];
const seen = new Set();
const perFileCounts = {};

const files = readdirSync(INPUT_DIR).filter(f => f.endsWith('.jsonl')).sort();
for (const filename of files) {
  const slug = basename(filename, '.jsonl');
  const path = resolve(INPUT_DIR, filename);
  const lines = readFileSync(path, 'utf8').split('\n').filter(l => l.trim());
  let kept = 0;
  let dropped = 0;

  for (const line of lines) {
    let obj;
    try {
      obj = JSON.parse(line);
    } catch (e) {
      warnings.push(`${filename}: malformed JSON: ${line.slice(0, 80)}…`);
      dropped++;
      continue;
    }
    if (obj._note) {
      fileNotes.push({ file: slug, note: obj._note });
      continue;
    }
    const { subject, predicate, object } = obj;
    if (!subject || !predicate || !object) {
      warnings.push(`${filename}: missing s/p/o: ${JSON.stringify(obj).slice(0, 120)}`);
      dropped++;
      continue;
    }
    if (!validPreds.has(predicate)) {
      warnings.push(`${filename}: unknown predicate "${predicate}"`);
      dropped++;
      continue;
    }
    if (!validIds.has(subject)) {
      warnings.push(`${filename}: unknown subject "${subject}"`);
      dropped++;
      continue;
    }
    if (!validIds.has(object)) {
      warnings.push(`${filename}: unknown object "${object}"`);
      dropped++;
      continue;
    }
    const rule = DIRECTION_RULES[predicate];
    if (rule) {
      if (rule.subject && !rule.subject.some(p => subject.startsWith(p))) {
        warnings.push(`${filename}: ${predicate} subject must be ${rule.subject.join(' / ')}* — got "${subject}"`);
        dropped++;
        continue;
      }
      if (rule.object && !rule.object.some(p => object.startsWith(p))) {
        warnings.push(`${filename}: ${predicate} object must be ${rule.object.join(' / ')}* — got "${object}"`);
        dropped++;
        continue;
      }
    }
    const key = `${subject}|${predicate}|${object}`;
    if (seen.has(key)) {
      dropped++;
      continue;
    }
    seen.add(key);
    triples.push({ ...obj, sourceFile: slug });
    kept++;
  }
  perFileCounts[slug] = { kept, dropped };
}

writeFileSync(OUT_PATH, triples.map(t => JSON.stringify(t)).join('\n') + (triples.length ? '\n' : ''));
writeFileSync(NOTES_PATH, JSON.stringify({
  generated: new Date().toISOString(),
  files: files.length,
  triples: triples.length,
  warnings,
  fileNotes,
  perFileCounts,
}, null, 2));

console.log(`aggregate-interpretive: ${triples.length} triples → data/interpretive-triples.jsonl (from ${files.length} files)`);
for (const [slug, c] of Object.entries(perFileCounts)) {
  console.log(`  ${slug}: ${c.kept} kept${c.dropped ? `, ${c.dropped} dropped` : ''}`);
}
if (warnings.length) console.error(`  ${warnings.length} warnings — see data/interpretive-notes.json`);
if (fileNotes.length) console.log(`  ${fileNotes.length} agent notes recorded`);
