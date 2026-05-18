#!/usr/bin/env node
// Harvest candidate claims from prose in the information-book notes.
//
// Scans every markdown file in the quartz notes directory for two signals:
//   - **bold sentence** — full sentences enclosed in **...**
//   - marker phrases — "the X claim, said plain", "where I land",
//     "working answer", "current answer", "said differently", etc.
//
// Writes data/claim-candidates.jsonl, one candidate per line. This is the
// inbox: the author then promotes selected candidates into data/claims.json
// to give them stable slugs and load-bearing status. The build only emits
// Claim nodes for claims that live in claims.json.
//
// Run via `make harvest`. Re-run any time the prose changes — the build's
// drift check compares each canonical Claim's harvestedFrom anchor against
// the latest candidates and warns if a claim's anchoring prose is gone.

import { readFileSync, writeFileSync, readdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, basename, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const NOTES_DIR = resolve(repoRoot, '..', 'quartz', 'content', 'notes', 'information-book');
const OUT_PATH = resolve(dataDir, 'claim-candidates.jsonl');

const MARKER_PATTERNS = [
  /\bthe\s+[\w-]+\s+claim,?\s+said\s+plain\b\s*[:\.]?/i,
  /\bwhere I land\b\s*[:\.]?/i,
  /\b(my\s+)?(working|current)\s+answer\b\s*[:\.]?/i,
  /\bsaid differently\b\s*[:\.]?/i,
  /\bthe (point|claim|thesis) is\b\s*[:\.]?/i,
];

function noteSlugFromFilename(filename) {
  return basename(filename, '.md').replace(/\s+/g, '-').toLowerCase();
}

function isLikelySentence(text) {
  if (text.length < 30) return false;
  if (!/[a-z]/.test(text)) return false;                  // some lowercase
  if (!/[\.\?\!]\s*\*?\*?$/.test(text)) return false;     // ends in sentence terminator
  if (/^\[\[/.test(text)) return false;                    // not just a wikilink
  if (/^Chapter \d+[a-z]?\b/.test(text)) return false;     // chapter-title label
  if (/^Case \d+\b/.test(text)) return false;              // case-study label
  return true;
}

function findParagraph(lines, startLineIdx) {
  let start = startLineIdx;
  while (start > 0 && lines[start - 1].trim() !== '') start--;
  let end = startLineIdx;
  while (end < lines.length - 1 && lines[end + 1].trim() !== '') end++;
  return lines.slice(start, end + 1).join(' ').replace(/\s+/g, ' ').trim();
}

function harvest(content, noteSlug) {
  const candidates = [];
  const lines = content.split('\n');
  let inCodeBlock = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (/^```/.test(line)) {
      inCodeBlock = !inCodeBlock;
      continue;
    }
    if (inCodeBlock) continue;

    // Bold-sentence signal
    const boldRegex = /\*\*([^*]+)\*\*/g;
    let m;
    while ((m = boldRegex.exec(line)) !== null) {
      const text = m[1].trim();
      if (!isLikelySentence(text)) continue;
      candidates.push({
        text,
        note: noteSlug,
        lineApprox: i + 1,
        signal: 'bold-sentence',
        surroundingParagraph: findParagraph(lines, i),
      });
    }

    // Marker-phrase signal
    for (const re of MARKER_PATTERNS) {
      const mm = line.match(re);
      if (!mm) continue;
      const afterIdx = line.indexOf(mm[0]) + mm[0].length;
      let claimText = line.slice(afterIdx).trim();
      let claimLine = i + 1;
      // If nothing follows the marker on this line (heading-style usage),
      // walk forward to the next non-empty, non-heading line.
      if (claimText.length < 20) {
        for (let lookI = i + 1; lookI < lines.length; lookI++) {
          const next = lines[lookI].trim();
          if (!next) continue;
          if (next.startsWith('#')) break;
          claimText = next;
          claimLine = lookI + 1;
          break;
        }
      }
      if (claimText.length < 20) continue;
      const clean = claimText
        .replace(/^\*\*|\*\*$/g, '')
        .replace(/^["']|["']$/g, '')
        .trim();
      if (clean.length < 20) continue;
      candidates.push({
        text: clean,
        note: noteSlug,
        lineApprox: claimLine,
        signal: 'marker-phrase',
        marker: mm[0].trim(),
        surroundingParagraph: findParagraph(lines, claimLine - 1),
      });
    }
  }

  return candidates;
}

function* iterateMarkdownFiles(dir) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) continue;
    if (!name.endsWith('.md')) continue;
    yield path;
  }
}

function main() {
  const all = [];
  for (const filepath of iterateMarkdownFiles(NOTES_DIR)) {
    const slug = noteSlugFromFilename(filepath);
    if (slug === 'index') continue;
    const content = readFileSync(filepath, 'utf8');
    all.push(...harvest(content, slug));
  }

  const seen = new Set();
  const deduped = [];
  for (const c of all) {
    const key = `${c.note}|${c.lineApprox}|${c.text.slice(0, 60)}`;
    if (seen.has(key)) continue;
    seen.add(key);
    deduped.push(c);
  }

  deduped.sort((a, b) =>
    a.note < b.note ? -1 : a.note > b.note ? 1 : a.lineApprox - b.lineApprox
  );

  writeFileSync(OUT_PATH, deduped.map(c => JSON.stringify(c)).join('\n') + '\n');

  const bySignal = {};
  const byNote = {};
  for (const c of deduped) {
    bySignal[c.signal] = (bySignal[c.signal] || 0) + 1;
    byNote[c.note] = (byNote[c.note] || 0) + 1;
  }

  console.log(`harvest-claims: ${deduped.length} candidates → data/claim-candidates.jsonl`);
  console.log(`  by signal: ${JSON.stringify(bySignal)}`);
  console.log(`  by note:   ${JSON.stringify(byNote)}`);
  console.log('');
  console.log('Candidates (truncated to 120 chars each):');
  for (let i = 0; i < deduped.length; i++) {
    const c = deduped[i];
    const text = c.text.length > 120 ? c.text.slice(0, 117) + '…' : c.text;
    console.log(`  ${(i + 1).toString().padStart(3, ' ')}. [${c.signal}] ${c.note}:${c.lineApprox}`);
    console.log(`       ${text}`);
  }
}

main();
