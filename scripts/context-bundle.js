#!/usr/bin/env node
// Context bundle exporter — given a center node, emit a markdown packet
// of the surrounding graph neighbourhood, ready to paste into a drafting
// prompt or attach to a PR comment.
//
// Usage:
//   node scripts/context-bundle.js --center=chapter:selection-as-other-engine
//   node scripts/context-bundle.js --center=claim:selection-primary --hop=3
//   make context CENTER=chapter:selection-as-other-engine
//   make context CENTER=chapter:selection-as-other-engine ARGS="--hop=3 -o /tmp/c5b.md"

import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(__dirname, '..');
const dataDir = resolve(repoRoot, 'data');
const NOTES_DIR = resolve(repoRoot, '..', 'quartz', 'content', 'notes', 'information-book');

// Tracks cases shown inline under claims so the standalone "Case studies"
// section doesn't duplicate them.
const inlineCaseIds = new Set();

// ---------------------------------------------------------------- CLI

const HELP = `Context bundle exporter for the information-book ontology

Usage:
  node scripts/context-bundle.js --center=<id> [options]
  make context CENTER=<id>

Required:
  --center=<id>         Focus node id (e.g. chapter:selection-as-other-engine,
                        claim:selection-primary, concept:memetic-fitness).
                        Accepts short slug or chapter number for fuzzy match.

Options:
  --hop=<n>             BFS depth (default 2)
  --token-budget=<n>    Approximate token cap; warns if exceeded (default 20000)
  --format=md|json      Output format (default md)
  -o <path>             Write to file instead of stdout
  -h, --help            Show this help

Examples:
  node scripts/context-bundle.js --center=chapter:selection-as-other-engine
  make context CENTER=claim:selection-primary
  make context CENTER=chapter:complexity-virality-tradeoff ARGS="-o /tmp/c5.md"
`;

function parseArgs() {
  const args = { hop: 2, 'token-budget': 20000, format: 'md' };
  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-h' || a === '--help') { args.help = true; continue; }
    if (a === '-o' || a === '--output') { args.output = argv[++i]; continue; }
    const m = a.match(/^--([\w-]+)=(.*)$/);
    if (m) {
      let v = m[2];
      if (m[1] === 'hop' || m[1] === 'token-budget') v = parseInt(v, 10);
      args[m[1]] = v;
    }
  }
  return args;
}

const args = parseArgs();
if (args.help) { console.log(HELP); process.exit(0); }
if (!args.center) { console.error('error: --center is required\n'); console.error(HELP); process.exit(1); }

// ---------------------------------------------------------------- load graph

function readJsonl(filename) {
  const path = resolve(dataDir, filename);
  if (!existsSync(path)) {
    console.error(`error: ${filename} not found — run \`make build\` first`);
    process.exit(1);
  }
  return readFileSync(path, 'utf8').split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
}

const nodes = readJsonl('nodes.jsonl');
const edges = readJsonl('edges.jsonl');
const nodeById = new Map(nodes.map(n => [n.id, n]));

// ---------------------------------------------------------------- resolve center

function resolveCenterId(input) {
  if (nodeById.has(input)) return input;
  const namespaces = ['chapter', 'claim', 'concept', 'mechanism', 'question', 'note', 'source', 'case', 'tradition', 'author', 'part'];
  for (const ns of namespaces) {
    if (nodeById.has(`${ns}:${input}`)) return `${ns}:${input}`;
  }
  // Fuzzy fallback: match by chapter number, then by label/id substring
  const numberMatch = nodes.filter(n => n.props?.number === input);
  if (numberMatch.length === 1) return numberMatch[0].id;
  const lower = input.toLowerCase();
  const fuzzy = nodes.filter(n =>
    (n.label && n.label.toLowerCase().includes(lower)) ||
    n.id.toLowerCase().includes(lower)
  );
  if (fuzzy.length === 1) return fuzzy[0].id;
  if (fuzzy.length > 1) {
    console.error(`error: ambiguous center "${input}". Candidates:`);
    for (const c of fuzzy.slice(0, 12)) console.error(`  ${c.id}  (${c.label})`);
    process.exit(1);
  }
  return null;
}

const centerId = resolveCenterId(args.center);
if (!centerId) {
  console.error(`error: center "${args.center}" not found.`);
  process.exit(1);
}
const center = nodeById.get(centerId);

// ---------------------------------------------------------------- BFS

const HUB_TRANSIT_TYPES = new Set(['Status', 'Part']);

const edgeIndex = new Map();
for (const e of edges) {
  if (!edgeIndex.has(e.source)) edgeIndex.set(e.source, []);
  if (!edgeIndex.has(e.target)) edgeIndex.set(e.target, []);
  edgeIndex.get(e.source).push(e);
  edgeIndex.get(e.target).push(e);
}

function bfs(startId, maxHops) {
  const distances = new Map([[startId, 0]]);
  let frontier = [startId];
  for (let h = 0; h < maxHops; h++) {
    const next = new Set();
    for (const id of frontier) {
      const node = nodeById.get(id);
      // Don't transit through hub types (only allowed as endpoint)
      if (h > 0 && node && HUB_TRANSIT_TYPES.has(node.type)) continue;
      for (const e of edgeIndex.get(id) || []) {
        const other = e.source === id ? e.target : e.source;
        if (distances.has(other)) continue;
        distances.set(other, h + 1);
        next.add(other);
      }
    }
    frontier = Array.from(next);
  }
  return distances;
}

const distances = bfs(centerId, args.hop);

// ---------------------------------------------------------------- bucket

const buckets = {};
for (const [id, _dist] of distances) {
  if (id === centerId) continue;
  const node = nodeById.get(id);
  if (!node) continue;
  if (!buckets[node.type]) buckets[node.type] = [];
  buckets[node.type].push(node);
}
for (const t of Object.keys(buckets)) {
  buckets[t].sort((a, b) => {
    const da = distances.get(a.id) || 99;
    const db = distances.get(b.id) || 99;
    if (da !== db) return da - db;
    return (a.label || '').localeCompare(b.label || '');
  });
}

// ---------------------------------------------------------------- helpers

function outEdges(id, predicate) {
  return edges.filter(e => e.source === id && (!predicate || e.predicate === predicate));
}
function inEdges(id, predicate) {
  return edges.filter(e => e.target === id && (!predicate || e.predicate === predicate));
}
function labelOf(id) {
  const n = nodeById.get(id);
  return n ? (n.label || id) : id;
}

// Pull the first prose paragraph after an H2 heading. Skips images, code
// fences, and leading blockquote markers. Used to embed a section opening
// from a chapter's draft note into the bundle so the drafter sees the
// actual voice the chapter is being written in.
function firstParagraphOfSection(sectionBody) {
  const lines = sectionBody.split('\n');
  let started = false;
  const result = [];
  let inFence = false;
  for (const line of lines) {
    if (/^```/.test(line.trim())) { inFence = !inFence; if (started) break; continue; }
    if (inFence) continue;
    const trimmed = line.trim();
    if (!trimmed) {
      if (started) break;
      continue;
    }
    if (/^!\[/.test(trimmed)) { if (started) break; continue; }   // image
    if (/^>/.test(trimmed) && !started) continue;                  // skip leading blockquote
    started = true;
    result.push(trimmed);
  }
  return result.join(' ');
}

function loadNotePassages(note) {
  if (!note?.props?.file) return null;
  const filePath = resolve(NOTES_DIR, note.props.file);
  if (!existsSync(filePath)) return null;
  let content = readFileSync(filePath, 'utf8');
  content = content.replace(/^---\n[\s\S]*?\n---\n?/, ''); // strip frontmatter
  const sectionRegex = /^##\s+(.+?)\n+([\s\S]*?)(?=\n##\s+|$)/gm;
  const passages = [];
  let m;
  while ((m = sectionRegex.exec(content)) !== null) {
    const title = m[1].trim();
    const firstPara = firstParagraphOfSection(m[2]);
    if (firstPara) passages.push({ title, firstParagraph: firstPara });
  }
  return passages;
}

// Foundational questions in scope: combine BFS-reached questions with
// the questions that each in-scope claim depends on or that its
// harvestedFrom notes flag. This surfaces resolved questions even when
// they're more than 2 hops from the chapter center — the chapter's
// argument inherits the question's resolution via the claims it argues.
function questionsInScopeFromClaims(claims) {
  const ids = new Set();
  for (const claim of claims) {
    for (const e of outEdges(claim.id, 'dependsOn')) {
      if (e.target.startsWith('question:')) ids.add(e.target);
    }
    for (const anchor of claim.props?.harvestedFrom || []) {
      const noteId = `note:${anchor.note}`;
      for (const e of outEdges(noteId, 'flagsOpenQuestion')) {
        ids.add(e.target);
      }
    }
  }
  return Array.from(ids).map(id => nodeById.get(id)).filter(Boolean);
}

// ---------------------------------------------------------------- render

function renderEvidenceQuote(lines, e, kind) {
  const src = labelOf(e.source);
  const page = e.pageApprox ? `, p.${e.pageApprox}` : '';
  const conf = e.confidence ? `, ${e.confidence}` : '';
  lines.push(`- **${kind}** — ${src} (\`${e.source}\`${page}${conf})`);
  if (e.quote) lines.push(`  > "${e.quote}"`);
  if (e.rationale) lines.push(`  — ${e.rationale}`);
}

function renderClaim(lines, claim) {
  lines.push(`### ${claim.label}`);
  lines.push('');
  lines.push(`\`${claim.id}\` — *status: ${claim.props?.status || 'working'}*`);
  lines.push('');
  if (claim.props?.summary) { lines.push(claim.props.summary); lines.push(''); }
  const deps = outEdges(claim.id, 'dependsOn').map(e => e.target);
  if (deps.length) {
    lines.push(`*Depends on:* ${deps.map(d => `\`${d}\``).join(', ')}`);
    lines.push('');
  }
  // Illustrating case studies — show inline, then mark so the
  // standalone Case studies section knows to skip them.
  const illustratingCases = inEdges(claim.id, 'mentions')
    .filter(e => e.source.startsWith('case:'))
    .map(e => nodeById.get(e.source))
    .filter(Boolean);
  if (illustratingCases.length) {
    lines.push('**Illustrated by:**');
    lines.push('');
    for (const cs of illustratingCases) {
      lines.push(`- **${cs.label}** — ${cs.props?.summary || ''}`);
      inlineCaseIds.add(cs.id);
    }
    lines.push('');
  }
  const sup = inEdges(claim.id, 'supports');
  const pt = inEdges(claim.id, 'pressureTests');
  if (sup.length || pt.length) {
    lines.push(`**Source evidence** (${sup.length} supports, ${pt.length} pressure-tests):`);
    lines.push('');
    for (const e of sup) renderEvidenceQuote(lines, e, 'supports');
    for (const e of pt) renderEvidenceQuote(lines, e, 'pressure-tests');
    lines.push('');
  } else {
    lines.push('*No source backing yet.*');
    lines.push('');
  }
}

function renderMarkdown() {
  const lines = [];

  // Header
  lines.push(`# ${center.label || center.id}`);
  lines.push('');
  const headerBits = [`**${center.type}** \`${center.id}\``];
  if (center.props?.status) headerBits.push(`**Status** \`${center.props.status}\``);
  if (center.props?.part) headerBits.push(`**Part** \`${center.props.part}\``);
  if (center.props?.draftNote) headerBits.push(`**Draft note** \`${center.props.draftNote}\``);
  lines.push(`> ${headerBits.join(' · ')}`);
  lines.push('');

  // Summary
  if (center.props?.summary) {
    lines.push('## Summary');
    lines.push('');
    lines.push(center.props.summary);
    lines.push('');
  }
  if (center.type === 'Claim' && center.props?.aliases?.length) {
    lines.push(`*Aliases: ${center.props.aliases.map(a => `"${a}"`).join(', ')}*`);
    lines.push('');
  }

  // Draft note (for chapter centers with a draftNote prop)
  if (center.props?.draftNote && nodeById.has(center.props.draftNote)) {
    const dn = nodeById.get(center.props.draftNote);
    lines.push('## Draft note');
    lines.push('');
    lines.push(`\`${dn.id}\` — ${dn.props?.title || dn.label}`);
    lines.push('');
    if (dn.props?.summary) { lines.push(dn.props.summary); lines.push(''); }
    const passages = loadNotePassages(dn);
    if (passages?.length) {
      lines.push('**Section openings (first paragraph after each H2 in the draft):**');
      lines.push('');
      for (const p of passages) {
        lines.push(`#### ${p.title}`);
        lines.push('');
        const quoted = p.firstParagraph.split('\n').map(l => `> ${l}`).join('\n');
        lines.push(quoted);
        lines.push('');
      }
    } else if (dn.props?.sections?.length) {
      // Fallback if note's source file isn't accessible from where we run
      lines.push('**Section outline:**');
      for (const s of dn.props.sections) lines.push(`- ${s}`);
      lines.push('');
    }
    if (dn.props?.file) {
      lines.push(`*Source file: \`quartz/content/notes/information-book/${dn.props.file}\`*`);
      lines.push('');
    }
  }

  // Claims in scope — direct argues + BFS-reached, direct first
  const directClaimIds = new Set(outEdges(centerId, 'argues').map(e => e.target));
  // If center IS a claim, include itself + dependsOn + reverse-dependsOn
  if (center.type === 'Claim') {
    // Self-rendering already in summary; show downstream/upstream claim chain instead
    const upstream = outEdges(centerId, 'dependsOn').map(e => nodeById.get(e.target)).filter(n => n?.type === 'Claim');
    const downstream = inEdges(centerId, 'dependsOn').map(e => nodeById.get(e.source)).filter(n => n?.type === 'Claim');
    if (upstream.length || downstream.length) {
      lines.push('## Claim chain');
      lines.push('');
      if (upstream.length) {
        lines.push('**This claim depends on:**');
        for (const c of upstream) lines.push(`- \`${c.id}\` — ${c.label} (${c.props?.status})`);
        lines.push('');
      }
      if (downstream.length) {
        lines.push('**Claims that depend on this one:**');
        for (const c of downstream) lines.push(`- \`${c.id}\` — ${c.label} (${c.props?.status})`);
        lines.push('');
      }
    }
    // Render this claim's own source backing
    lines.push('## Source evidence for this claim');
    lines.push('');
    renderClaim(lines, center);
  } else {
    const claimsToShow = (buckets.Claim || []).slice().sort((a, b) => {
      const aDirect = directClaimIds.has(a.id) ? 0 : 1;
      const bDirect = directClaimIds.has(b.id) ? 0 : 1;
      return aDirect - bDirect;
    });
    if (claimsToShow.length) {
      lines.push('## Claims in scope');
      lines.push('');
      for (const c of claimsToShow) {
        if (!directClaimIds.has(c.id)) {
          lines.push(`*(via BFS — not directly argued by this center)*`);
        }
        renderClaim(lines, c);
      }
    }
  }

  // Questions in scope — combine BFS-reached with claim-scoped lookup
  // so foundational resolved questions surface even when more than 2
  // hops away from the center.
  const claimsForScope = center.type === 'Claim' ? [center] : (buckets.Claim || []);
  const scopedQs = questionsInScopeFromClaims(claimsForScope);
  const allQsMap = new Map();
  for (const q of (buckets.Question || [])) allQsMap.set(q.id, q);
  for (const q of scopedQs) allQsMap.set(q.id, q);
  const allQs = Array.from(allQsMap.values());
  const openQs = allQs.filter(q => q.props?.status === 'open');
  const resolvedQs = allQs.filter(q => q.props?.status && q.props.status !== 'open');

  if (openQs.length) {
    lines.push('## Open questions in scope');
    lines.push('');
    for (const q of openQs) {
      lines.push(`### ${q.label}`);
      lines.push('');
      lines.push(`\`${q.id}\` — *status: ${q.props?.status || 'open'}*`);
      lines.push('');
      if (q.props?.summary) { lines.push(q.props.summary); lines.push(''); }
      if (q.props?.workingAnswer) { lines.push(`**Working answer:** ${q.props.workingAnswer}`); lines.push(''); }
    }
  }
  if (resolvedQs.length) {
    lines.push('## Foundational questions resolved in scope');
    lines.push('');
    lines.push('*The chapter\'s argument rests on these provisional resolutions. Treat as committed unless explicitly reopened.*');
    lines.push('');
    for (const q of resolvedQs) {
      lines.push(`### ${q.label}`);
      lines.push('');
      lines.push(`\`${q.id}\` — *status: ${q.props?.status}*`);
      lines.push('');
      if (q.props?.summary) { lines.push(q.props.summary); lines.push(''); }
      if (q.props?.workingAnswer) {
        lines.push(`**Working answer:** ${q.props.workingAnswer}`);
        lines.push('');
      }
    }
  }

  // Mechanisms
  if (buckets.Mechanism?.length) {
    lines.push('## Anchored mechanisms');
    lines.push('');
    for (const m of buckets.Mechanism) {
      lines.push(`- **${m.label}** (\`${m.id}\`) — ${m.props?.summary || ''}`);
    }
    lines.push('');
  }

  // Concepts
  if (buckets.Concept?.length) {
    lines.push('## Anchored concepts');
    lines.push('');
    for (const c of buckets.Concept) {
      lines.push(`- **${c.label}** (\`${c.id}\`) — ${c.props?.summary || ''}`);
    }
    lines.push('');
  }

  // Case studies — only those not already shown inline under a claim,
  // so the section isn't a duplicate of what's threaded above.
  const standaloneCases = (buckets.CaseStudy || []).filter(cs => !inlineCaseIds.has(cs.id));
  if (standaloneCases.length) {
    lines.push('## Other case studies in neighbourhood');
    lines.push('');
    for (const cs of standaloneCases) {
      lines.push(`- **${cs.label}** (\`${cs.id}\`) — ${cs.props?.summary || ''}`);
    }
    lines.push('');
  }

  // Related notes (excluding draft note already shown)
  const draftNoteId = center.props?.draftNote;
  const relatedNotes = (buckets.Note || []).filter(n => n.id !== draftNoteId);
  if (relatedNotes.length) {
    lines.push('## Related notes');
    lines.push('');
    for (const n of relatedNotes) {
      const role = n.props?.role ? ` — *${n.props.role}*` : '';
      lines.push(`- **${n.props?.title || n.label}** (\`${n.id}\`)${role}`);
      if (n.props?.summary) lines.push(`  ${n.props.summary}`);
    }
    lines.push('');
  }

  // Sources in neighbourhood
  if (buckets.Source?.length) {
    lines.push('## Sources in neighbourhood');
    lines.push('');
    for (const s of buckets.Source) {
      const authors = outEdges(s.id, 'authoredBy').map(e => labelOf(e.target));
      const auth = authors.length ? ` (${authors.join(' / ')})` : '';
      lines.push(`- **${s.label}**${auth} — \`${s.id}\``);
      if (s.props?.engagement) lines.push(`  *${s.props.engagement}*`);
    }
    lines.push('');
  }

  // Traditions
  if (buckets.Tradition?.length) {
    lines.push('## Intellectual traditions');
    lines.push('');
    for (const t of buckets.Tradition) {
      lines.push(`- **${t.label}** — ${t.props?.summary || ''}`);
    }
    lines.push('');
  }

  // Editorial flags
  const flags = computeEditorialFlags();
  if (flags.length) {
    lines.push('## Editorial flags');
    lines.push('');
    for (const f of flags) lines.push(`- ${f}`);
    lines.push('');
  }

  return lines.join('\n');
}

function computeEditorialFlags() {
  const flags = [];
  if (center.type === 'Chapter') {
    if (center.props?.status === 'not-yet-drafted') flags.push('Chapter not yet drafted — no backing note exists.');
    if (center.props?.status === 'skeleton') flags.push('Chapter is a skeleton — only outline-level description exists.');
    if (center.props?.status === 'in-workshop') flags.push('Chapter is in active workshop — draft is being revised.');
  }
  const openQuestions = (buckets.Question || []).filter(q => q.props?.status === 'open');
  if (openQuestions.length) {
    flags.push(`${openQuestions.length} still-open question(s) gate resolution here: ${openQuestions.map(q => `\`${q.id}\``).join(', ')}.`);
  }
  if (center.type === 'Chapter') {
    const directClaims = outEdges(centerId, 'argues').map(e => nodeById.get(e.target)).filter(c => c?.type === 'Claim');
    for (const c of directClaims) {
      const sup = inEdges(c.id, 'supports').length;
      const pt = inEdges(c.id, 'pressureTests').length;
      if (sup === 0 && pt === 0) flags.push(`Claim \`${c.id}\` has no source backing yet (0 supports, 0 pressure-tests).`);
    }
  }
  if (center.type === 'Claim') {
    const sup = inEdges(centerId, 'supports').length;
    const pt = inEdges(centerId, 'pressureTests').length;
    if (sup === 0 && pt === 0) flags.push('This claim has no source backing yet — consider extracting more sources or downgrading status.');
    if (pt > sup + 1) flags.push(`This claim is contested: ${sup} supports vs. ${pt} pressure-tests.`);
  }
  return flags;
}

// ---------------------------------------------------------------- output

const output = args.format === 'json'
  ? JSON.stringify({
      center,
      reached: Array.from(distances.keys()),
      distances: Object.fromEntries(distances),
      buckets: Object.fromEntries(Object.entries(buckets).map(([k, v]) => [k, v.map(n => n.id)])),
    }, null, 2)
  : renderMarkdown();

if (args.output) {
  writeFileSync(args.output, output);
  console.error(`context bundle: ${output.length} chars / ~${Math.round(output.length / 4)} tokens → ${args.output}`);
} else {
  console.log(output);
}

const estTokens = Math.round(output.length / 4);
if (estTokens > args['token-budget']) {
  console.error(`note: bundle is ~${estTokens} tokens, over the budget of ${args['token-budget']}. Consider --hop=1 for a tighter focus.`);
}
