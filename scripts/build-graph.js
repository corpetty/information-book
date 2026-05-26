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
    { slug: 'case-studies-and-three-realities',     part: 'pipeline',    ordinal: 2,   number: '2',  title: 'Case Studies and Three Realities',       status: 'in-workshop',     draftNote: 'note:case-studies-and-three-realities', summary: 'Brings Ch 1\'s abstract pipeline structure to ground through four case studies illustrating four pipeline exits — Power Posing (made it to meme, survived the corrective), arsenic-life (died at consensus), Stanford Prison Experiment correctives (died at curation despite passing consensus), astrology (no theory at all — manufactured content occupying late stages without entering early ones). Reads the four cases as samples drawn from one continuous failure surface whose gradient runs systematically against corrective signal. Second half introduces Harari\'s three-realities frame (objective / subjective / intersubjective) and pulls out what changes for the book\'s diagnostic vocabulary across reality types — particularly that intersubjective realities are partly constituted by the pipeline rather than transmitted through it, which means the truth-loss-in-transit analysis works differently for them. The four cases become a recurring touchstone subsequent chapters can reference by name.' },
    { slug: 'human-time-budget',                    part: 'lossy',       ordinal: 3,   number: '3',  title: 'The Human Time Budget',                  status: 'in-workshop',     draftNote: 'note:info-time-limit',                summary: 'Tablespoon of weeks; effective mental hours less than nominal. Budget is not fixed — education, vocabulary, accumulated engagement expand it. Want is the prime mover.' },
    { slug: 'optionality-vs-access',                part: 'lossy',       ordinal: 4,   number: '4',  title: 'Optionality vs. Access',                 status: 'in-workshop',     draftNote: 'note:optionality-vs-access',          summary: 'The general-vs-usable trade-off. Drafted using matplotlib vs. seaborn. Needs generalization beyond software: religions, political platforms, scientific popularization, legal codes.' },
    { slug: 'complexity-virality-tradeoff',         part: 'lossy',       ordinal: 5,   number: '5',  title: 'The Complexity / Virality Trade-off',    status: 'in-workshop',     draftNote: 'note:complexity-virality-tradeoff',   summary: 'The transport half of the two-mechanism structure. Within-stage compression dynamics, most visible at the meme stage. Reframes Hammer/Copernicus as selection-fit rather than transport-cost.' },
    { slug: 'selection-as-other-engine',            part: 'lossy',       ordinal: 5.1, number: '5b', title: 'Selection As The Other Engine',          status: 'in-workshop',     draftNote: 'note:selection-as-other-engine',      summary: 'The selection half of the two-mechanism structure: the three-operation stage model (transport generates, the medium bounds, selection picks), selection as the tunable mechanism, and the medium as frozen selection. Engages Mercier and O\'Connor & Weatherall.' },
    { slug: 'truth-compression-and-when-each-wins', part: 'lossy',       ordinal: 5.2, number: '5c', title: 'Truth, Compression, and When Each Wins', status: 'in-workshop', draftNote: 'note:truth-compression-and-when-each-wins',                                                                  summary: 'When does compressed form preserve approximate truth, when invert, when orthogonal? Closes the moral-neutrality gap and gives the book its actual stakes.' },
    { slug: 'bridge-zone-distortion',               part: 'bridge-zone', ordinal: 6,   number: '6',  title: 'Where It All Gets Fucked Up',            status: 'in-workshop',     draftNote: 'note:bridge-zone-distortion',         summary: 'Chapter 6 draft. The bridge zone — News and Meme stages where specialist content reaches mass audiences via journalists, popularizers, influencers, educators, and AI summarizers. Active reshaping for audience effect, not passive transport compression; accountability runs through audience-or-employer relationships rather than through the specialist community whose findings get translated. Three worked cases of catastrophic distortion (COVID epi, nutrition science, monetary policy) plus the four Ch 2 cases relocated to their bridge-zone stage. Names pseudo-context (per Postman) as a distinctive bridge-zone failure mode. Connects to capture-taxonomy substrates (gate-criteria + receiver-training as the captured pair) and to Ch 9 bridge-node + Ch 11 LLM + Ch 12 infrastructure as the prescriptive landing zone. The angriest chapter in the book by design.' },
    { slug: 'emotional-memetics',                   part: 'bridge-zone', ordinal: 7,   number: '7',  title: 'Emotional Memetics As The Floor',        status: 'in-workshop',     draftNote: 'note:emotional-memetics',             summary: 'Chapter 7 draft. The floor argument: once a mass network with engagement-tuned gates has run long enough, the propagation equilibrium converges on raw strong emotion as the floor of what reliably spreads. Three lines of evidence (Psychology of Virality on attentional substrate + Ukraine before/after invasion shift; paradox of virality as diagnostic anchor; Postman on television-medium form). Engages Mercier\'s epistemic-vigilance challenge head-on — argues that vigilance protects against believing not attending, is one criterion among many, and has been trained down by long medium exposure. Floor is medium-conditional, substrate-anchored, capture-tuned within the emotional-payload set. Names three structural design moves Part IV engages — sub-networks with different gates, gate-tuning of mass network, decompression-on-demand softening the per-claim cost.' },
    { slug: 'preservation-vs-training',             part: 'integration', ordinal: 8,   number: '8',  title: 'Preservation vs. Training',              status: 'in-workshop',     draftNote: 'note:preservation-vs-training',       summary: 'Splits what Harari\'s "bureaucracy" was bundling. Preservation keeps the un-compressed form alive; training re-installs the decoding key in receivers. Either alone fails — preservation without training is an inaccessible archive, training without preservation is competence pointed at the wrong target. The two halves are asymmetric under capture: captured training does more damage and recovers more slowly than captured preservation. Working diagnosis of the modern collapse: training has hollowed under the cover of a still-mostly-functional preservation half.' },
    { slug: 'integration-problem',                  part: 'integration', ordinal: 9,   number: '9',  title: 'The Integration Problem',                status: 'in-workshop',     draftNote: 'note:integration-problem',            summary: 'Integration between networks that don\'t share preconditions runs through versatile experts (deep specialists with paired metacognitive flexibility) inhabiting curation-layer institutions. The polarization-via-distrust trap and the transferable-vs-specialized question collapse into one mechanism — the bridge-node thesis disarms both.' },
    { slug: 'political-economy-of-attention',       part: 'integration', ordinal: 10,  number: '10', title: 'Political Economy of Attention',         status: 'in-workshop',     draftNote: 'note:political-economy-of-attention', summary: 'Selection has an owner because it is criterial; the medium\'s owner is the most powerful selection-setter in the system. Engagement is a proxy for revenue dressed up as a proxy for user benefit. Postman\'s Orwell/Huxley axis gives the modern failure mode as Huxley — drowning in irrelevance, harder to fight than censorship because there is nothing to oppose. Cost-shifting from producers to consumers is the structural move that keeps the political economy invisible. Names two flavors of capture: external (an adversarial selection-tuner) and self (the institution\'s own business model as the captured tuner) — and argues self-capture is more stable because there is no adversary to fight, only an equilibrium to dismantle. Out-competition rather than suppression is how platforms hollow institutional carriers.' },
    { slug: 'ai-as-new-node',                       part: 'integration', ordinal: 11,  number: '11', title: 'AI as a New Kind of Node',               status: 'in-workshop',     draftNote: 'note:ai-as-new-node',                summary: 'An LLM is the first node to collapse gate + option-space + content-generator + training-corpus + training-objective + deployment-configuration + pricing-tier into one design moment owned by one party — the most concentrated selection-design surface any medium has had. Decompression-on-demand is the first structural way out of the receiver-budget constraint; aggressive-compression-becoming-authoritative is its inverse failure mode. Names three new flavors of capture (corpus, objective, deployment) that compose with Ch 8 and Ch 10 capture and need unification in a forthcoming taxonomy note. Salvation case is technically realizable and economically marginal; worst case is the revenue-maximizing default. The political economy Ch 10 diagnosed determines which lands.' },
    { slug: 'infrastructure-for-integration',       part: 'integration', ordinal: 12,  number: '12', title: 'Infrastructure for Integration',         status: 'in-workshop',     draftNote: 'note:infrastructure-for-integration', summary: 'Synthesis chapter for Part IV. Reframes the prescriptive target as survival rather than victory — institutions that hold against the political-economic gradient by routing around the attention market rather than trying to clear it. Commits to three design principles: decouple funding from attention markets (counters Ch 10 out-competition); defend consumer-key substrates first per the capture taxonomy; build for survivable polarization rather than restored trust. Conditional fourth principle: LLMs as capability extenders inside the institution\'s own substrate custody (corpus, objective, deployment), salvation case technically realizable but economically marginal and politically blocked. Closes with the work-of-generations reframe: integration institutions are civilization-scale investments on the timescale of universities and journals, not platform launches.' },
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
    { slug: 'index',                        file: 'index.md',                        subtype: 'prose',        title: 'The Information Book (landing page)',                       role: 'landing-page',        summary: 'Plain-language landing page for the published site. Frames the problem the book takes on, the transport+selection diagnosis, the three working conclusions, and a reading map. Written for someone arriving cold; the outline and foundational notes are the next layer of depth.' },
    { slug: 'glossary',                     file: 'glossary.md',                     subtype: 'reference',    title: 'Glossary',                                                  role: 'glossary',            summary: 'Plain-language definitions of the load-bearing terms across the book, grouped by where each term enters the argument. The accessibility companion to the dense working outline.' },
    { slug: 'the-information-landscape',    file: 'the-information-landscape.md',    subtype: 'prose',        title: 'The Information Landscape',                                 role: 'chapter-draft',       summary: 'Chapter 1 draft. Walks through the transport and selection pipelines side by side.' },
    { slug: 'transport-vs-selection',       file: 'transport-vs-selection.md',       subtype: 'prose',        title: 'Transport vs. Selection',                                   role: 'foundational-note',   summary: 'Foundational note working through the transport-vs-selection question. Provisional answer: both parallel mechanisms, with want as prime mover.' },
    { slug: 'complexity-virality-tradeoff', file: 'complexity-virality-tradeoff.md', subtype: 'prose',        title: 'The Complexity / Virality Trade-off',                       role: 'chapter-draft',       summary: 'Chapter 5 draft, re-engaged with all dependent work resolved. The transport half of the two-mechanism structure, scoped to objective claims (Ch 2\'s three-realities frame). Complexity-doing-two-jobs question now settled per Ch 5b (transport-complexity = precondition count; selection-complexity = handle-ability; this chapter is about the first). Receiver-budget capacity is trainable per Ch 3; same constraint refracted into artifact design per Ch 4 (optionality-vs-access curve, same in five domains). Power Posing and SPE-corrective now serve as worked modern cases of the same Hammer-of-the-Witches dynamic, with the corrective always losing on transport-complexity grounds even when consensus has ratified it. Manipulation surface connects to capture-taxonomy substrates; institutional-carrier framing connects to Ch 8\'s preservation-and-training pair; decompression-on-demand (Ch 11) is named as the first structural softening of the per-claim cost conditional on Ch 11/12 substrate custody.' },
    { slug: 'info-time-limit',              file: 'info-time-limit.md',              subtype: 'prose',        title: 'The limit on how much information a human can incorporate', role: 'chapter-draft',       summary: 'Chapter 3 draft. First half: tablespoon-of-weeks framing of finite lifetime as the absorption-time constraint. Second half: receiver-budget capacity is partly trainable (pre-existing structure makes new absorption cheaper), want is the gate on what the budget gets spent on (the medium-shapes-want loop runs through the budget at receiver-lifetime and population scales), and decompression-on-demand from Ch 11 is the first structural softening of the per-claim cost the book has been able to point at. Hands forward to Ch 4/5 for the resulting trade-offs and Ch 11/12 for the political-economic conditions the softening depends on.' },
    { slug: 'optionality-vs-access',        file: 'optionality vs access.md',        subtype: 'prose',        title: 'Optionality vs. Access',                                    role: 'chapter-draft',       summary: 'Chapter 4 draft. The general-vs-usable trade-off generalized across five domains — software (matplotlib vs. seaborn), religion (Latin Mass vs. vernacular liturgy), political platforms (broad-tent coalitions vs. narrow specialist parties), scientific popularization (Hawking\'s A Brief History of Time vs. the actual GR papers), and legal codes (statutes vs. plain-language summaries). The reframe: the curve is the receiver-budget constraint reflected in artifact design — high optionality buys precision at the cost of access, high access buys reach at the cost of precision, you cannot have both at once for a given artifact. Ties the chapter into Ch 5 (the receiver-side mechanism behind complexity-virality), Ch 8 (preservation holds high-optionality, training expands receiver-budgets so more can access it), and Ch 11 (decompression-on-demand is in principle the first technology that could let a single artifact serve both ends of the curve).' },
    { slug: 'general-theme',                file: 'general-theme.md',                subtype: 'conversation', title: 'General Theme',                                             role: 'conversation-source', summary: 'Conversation transcript. The book concept explained to someone in real time. The conclusion of Part IV lives raw here.' },
    { slug: 'medium-and-manipulation', file: 'medium-and-manipulation.md', subtype: 'prose', title: 'Medium and Manipulation', role: 'foundational-note', summary: 'Foundational note on what the medium does to the selection gates. Provisional answer: the medium is the selection criteria — it sets the capacity, the criteria, and the want cultivated at every gate.' },
    { slug: 'three-layer-message', file: 'three-layer-message.md', subtype: 'prose', title: 'The Three Layers of a Message', role: 'foundational-note', summary: 'Foundational note adapting the frame/outer/inner message model from Hofstadter. The outer message — the decoding mechanism — is what the book calls preconditions, and it lives in the medium.' },
    { slug: 'truth-compression-and-when-each-wins', file: 'truth-compression-and-when-each-wins.md', subtype: 'prose', title: 'Truth, Compression, and When Each Wins', role: 'chapter-draft', summary: 'Chapter 5c draft. Resolves the truth-value-placement question — compression strips the decoding key, and truth is preserved, inverted, or rendered orthogonal depending on the key-gap and which compressed variant the selection gate picks.' },
    { slug: 'myths-scale-and-bureaucracy', file: 'myths-scale-and-bureaucracy.md', subtype: 'prose', title: 'Myths, Scale, and Bureaucracy', role: 'foundational-note', summary: 'Foundational note. Works out the loop: network scale forces myth compression, compression widens interpretive latitude, latitude segments the network, and segmentation forces the bureaucracy that re-supplies the dropped decoding key.' },
    { slug: 'selection-as-other-engine', file: 'selection-as-other-engine.md', subtype: 'prose', title: 'Selection As The Other Engine', role: 'chapter-draft', summary: 'Chapter 5b draft. The selection half of the two-mechanism structure: the three-operation stage model (transport generates, the medium bounds, selection picks), selection as the tunable mechanism, and the medium as frozen selection.' },
    { slug: 'bridge-nodes-and-versatile-expertise', file: 'bridge-nodes-and-versatile-expertise.md', subtype: 'prose', title: 'Bridge Nodes and Versatile Expertise', role: 'foundational-note', summary: 'Foundational note resolving the transferable-vs-specialized question. A bridge node is not a generalist with field-general skills but a deep specialist who has paired their depth with metacognitive flexibility (versatile expertise). The curse of expertise is the cognitive substrate of polarization-via-distrust, so the same agent resolves both open questions for Chapter 9.' },
    { slug: 'integration-problem', file: 'integration-problem.md', subtype: 'prose', title: 'The Integration Problem', role: 'chapter-draft', summary: 'Chapter 9 skeleton. Integration runs through versatile experts inhabiting curation-layer institutions; the prescription is the design of environments that produce both.' },
    { slug: 'preservation-vs-training', file: 'preservation-vs-training.md', subtype: 'prose', title: 'Preservation vs. Training', role: 'chapter-draft', summary: 'Chapter 8 draft. Splits Harari\'s "bureaucracy" into preservation (keep the un-compressed form alive) and training (re-install the decoding key in receivers). Names the capture and decay-rate asymmetries between the two halves and reads the modern collapse as preservation-mostly-held, training-hollowed.' },
    { slug: 'political-economy-of-attention', file: 'political-economy-of-attention.md', subtype: 'prose', title: 'Political Economy of Attention', role: 'chapter-draft', summary: 'Chapter 10 draft. Names ownership of selection as structurally unavoidable once selection is centered: criteria have setters. Engagement-maximization is the captured equilibrium of the platform business model; cost-shifting plus zero-marginal-cost attention is how the political economy stays invisible. Introduces the self-capture vs. external-capture distinction (self-capture is more stable — no adversary, only an arrangement) and names out-competition as the mechanism that produces Ch 8\'s asymmetric institutional collapse.' },
    { slug: 'ai-as-new-node', file: 'ai-as-new-node.md', subtype: 'prose', title: 'AI as a New Kind of Node', role: 'chapter-draft', summary: 'Chapter 11 draft. Structural characterization of LLMs as the first node collapsing five selection-design surfaces (corpus, objective, deployment, runtime gate, option space) into one design moment owned by one party. Names decompression-on-demand as the first structural way out of the receiver-budget constraint, and aggressive-compression-becoming-authoritative as its inverse failure mode. Introduces three new flavors of capture (corpus, objective, deployment) that compose with Ch 8 capture-asymmetry and Ch 10 self-vs-external capture and need unification in a forthcoming foundational note.' },
    { slug: 'capture-taxonomy', file: 'capture-taxonomy.md', subtype: 'prose', title: 'Capture Taxonomy', role: 'foundational-note', summary: 'Unifies capture across Ch 8, Ch 10, Ch 11. Three-axis taxonomy: substrate (gate-criteria / option-space / training-corpus / training-objective / deployment-configuration / receiver-training / preservation-archive), source (external / self / composite), target asymmetry (recovery dynamics determined by substrate). Names two cross-cutting principles: consumer-key captures are harder to recover from than surface captures (generalizing Ch 8\'s asymmetry); training-objective capture is uniquely bad because it self-reinforces across model generations. Composition rule: self-capture creates the gradient external capture rides; composite capture is the empirically dominant mode.' },
    { slug: 'infrastructure-for-integration', file: 'infrastructure-for-integration.md', subtype: 'prose', title: 'Infrastructure for Integration', role: 'chapter-draft', summary: 'Chapter 12 draft. Synthesis chapter for Part IV. Reframes the integration project as survival-not-victory and commits to three design principles: decouple funding from attention markets; defend consumer-key substrates first per the capture taxonomy; build for survivable polarization. Conditional fourth: LLMs as capability extenders inside the institution\'s substrate custody. Closes with the work-of-generations reframe — integration institutions are civilization-scale investments on the timescale of universities and journals, not platform launches.' },
    { slug: 'case-studies-and-three-realities', file: 'case-studies-and-three-realities.md', subtype: 'prose', title: 'Case Studies and Three Realities', role: 'chapter-draft', summary: 'Chapter 2 draft. Grounds Ch 1\'s pipeline structure in four case studies illustrating four pipeline exits (made-to-meme + corrective-survival, died-at-consensus, died-at-curation, no-theory injection), then introduces Harari\'s three-realities frame and works out which parts of the book\'s diagnostic vocabulary apply to objective vs. intersubjective content.' },
    { slug: 'bridge-zone-distortion', file: 'bridge-zone-distortion.md', subtype: 'prose', title: 'Where It All Gets Fucked Up', role: 'chapter-draft', summary: 'Chapter 6 draft. The bridge-zone stage where specialist findings get reshaped for mass audiences. Five operator populations (journalists, popularizers, influencers, educators, AI summarizers); three worked catastrophic-distortion cases (COVID, nutrition, monetary policy); pseudo-context as a distinctive bridge-zone failure mode; the bridge node and curation layer prescriptions from Part IV landing here.' },
    { slug: 'emotional-memetics', file: 'emotional-memetics.md', subtype: 'prose', title: 'Emotional Memetics As The Floor', role: 'chapter-draft', summary: 'Chapter 7 draft. The structural floor argument — mass-network propagation equilibrium converges on raw strong emotion under engagement-tuned gates. Three lines of evidence (attentional-substrate exploitation, paradox of virality, Postman entertainment-form selection). Direct engagement with Mercier\'s epistemic-vigilance challenge — vigilance is real but protects against believing, not attending; is one criterion among many at the action moment; has been trained down by long medium exposure. Floor is medium-conditional, substrate-anchored, capture-tuned within the emotional-payload set.' },
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

  // Extraction-completeness: any Source with a file declared should have
  // at least one interpretive edge by now — supports / pressureTests /
  // evidencedBy / interpretive-mentions. Zero means the extraction agent
  // has not been run against this PDF yet, which is the easiest authoring
  // task to forget. Warning, not error: a freshly added source legitimately
  // has zero edges between sources.json edit and the first extraction.
  const interpretiveBySource = new Map();
  for (const e of edges) {
    if (!e.interpretive) continue;
    if (e.source?.startsWith('source:')) {
      interpretiveBySource.set(e.source, (interpretiveBySource.get(e.source) || 0) + 1);
    }
    if (e.target?.startsWith('source:')) {
      interpretiveBySource.set(e.target, (interpretiveBySource.get(e.target) || 0) + 1);
    }
  }
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
