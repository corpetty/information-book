// Ontology viewer — Phase 25 (view presets + search + type filter).
//
// State model: a single `state` object holds {view, search, typeOverrides}.
// The URL hash is the source of truth for sharing; every state change writes
// to the hash, every hash change re-renders. Filtering is pure:
// computeVisibleElements(state) returns the cytoscape elements array, and
// applyState() runs the cytoscape layout against that result.

const DATA = '../data';

// Register vendored layout extensions (loaded as UMD globals in index.html,
// before this module). Guarded so a missing/forgotten vendor file degrades to
// cytoscape's built-in layouts rather than throwing before the app mounts.
for (const ext of ['cytoscapeDagre', 'cytoscapeFcose']) {
  try { if (window[ext]) cytoscape.use(window[ext]); }
  catch (e) { console.warn(`layout extension ${ext} failed to register`, e); }
}

// How many of the highest-degree nodes always carry a label (on top of the
// structural anchors — Parts and Chapters — which are always labelled). Keeps
// the skeleton readable without painting every concept/claim label into mud.
const HUB_LABELS = 14;

// ---------------------------------------------------------------- views

// Each view is a filter spec. `nodeTypes: null` means all types. `predicates:
// null` means all predicates. `layout` is the cytoscape layout name to use
// when this view is active.
const VIEWS = {
  overview: {
    label: 'Book overview',
    desc: 'Parts and chapters as a structural map of the book.',
    nodeTypes: ['Part', 'Chapter'],
    predicates: ['partOf', 'supersedes'],
    // Layered tree: edges run Chapter→Part (partOf), so rankDir 'BT' lifts the
    // four Parts to the top with their chapters ranked beneath them.
    layout: 'dagre',
    rankDir: 'BT',
  },
  argument: {
    label: 'Argument map',
    desc: 'Chapters, claims, concepts/mechanisms, and how the argument depends on itself.',
    nodeTypes: ['Chapter', 'Claim', 'Concept', 'Mechanism', 'Note', 'CaseStudy'],
    predicates: ['argues', 'covers', 'dependsOn', 'definedIn', 'derivesFrom', 'supersedes', 'representedBy'],
    layout: 'fcose',
  },
  sources: {
    label: 'Source map',
    desc: 'Where claims and concepts get their evidence; which sources support and pressure-test what.',
    nodeTypes: ['Source', 'Claim', 'Concept', 'Mechanism', 'Author', 'Tradition'],
    predicates: ['supports', 'pressureTests', 'evidencedBy', 'cites', 'authoredBy', 'partOfTradition'],
    layout: 'fcose',
  },
  questions: {
    label: 'Open questions',
    desc: 'Foundational questions and the chapters whose final shape depends on them.',
    nodeTypes: ['Question', 'Chapter', 'Note', 'Status'],
    predicates: ['flagsOpenQuestion', 'hasStatus'],
    layout: 'fcose',
  },
  contested: {
    label: 'What\'s contested',
    desc: 'Open questions, tensions the book holds with sources, and the frames it has revised. The dialectical layer.',
    nodeTypes: ['Question', 'Tension', 'Claim', 'Source', 'Concept', 'Mechanism', 'Chapter', 'Note'],
    predicates: ['flagsOpenQuestion', 'tensionWith', 'contradicts', 'supersedes', 'mentions'],
    layout: 'fcose',
    connectedOnly: true,
  },
  drafting: {
    label: 'Drafting status',
    desc: 'Where each chapter sits in the workflow — drafted, in-workshop, skeleton, not yet drafted.',
    nodeTypes: ['Chapter', 'Part', 'Status', 'Note'],
    predicates: ['partOf', 'hasStatus', 'representedBy'],
    // Left-to-right layered: chapters flow rightward to the Status they carry.
    layout: 'dagre',
    rankDir: 'LR',
    authorOnly: true, // workflow/meta view — not for readers
  },
  full: {
    label: 'Full graph',
    desc: 'Everything — every node, every edge. Use this when you know what you are looking for.',
    nodeTypes: null,
    predicates: null,
    layout: 'fcose',
    authorOnly: true, // the raw everything-at-once dump
  },
};

const DEFAULT_VIEW = 'overview';

// Reader-facing names for the node types — the schema's type keys (Mechanism,
// CaseStudy, …) are authoring jargon. Tooltips fall back to graph-meta's
// per-type description. Sensible defaults; tune to taste.
const PLAIN_TYPES = {
  Part: 'Part of the book',
  Chapter: 'Chapter',
  Note: 'Note / essay',
  Mechanism: 'Mechanism',
  PipelineStage: 'Pipeline stage',
  Gate: 'Selection gate',
  Concept: 'Concept',
  Question: 'Open question',
  Claim: 'Claim',
  Source: 'Source',
  Author: 'Author',
  Tradition: 'Tradition',
  CaseStudy: 'Example',
  Tension: 'Tension',
  Status: 'Drafting status',
};
function plainType(type) { return PLAIN_TYPES[type] || type; }
function typeDesc(type) { return GRAPH.meta?.nodeTypes?.[type]?.description || ''; }

// ---------------------------------------------------------------- state

const state = {
  // mode: 'reader' (default — curated views, plain-language key, no jargon) or
  // 'author' (the full audit tools: every view, type/predicate toggles).
  mode: 'reader',
  view: DEFAULT_VIEW,
  search: '',
  // typeOverrides: {[type]: boolean} — when present, overrides the view's
  // nodeTypes membership (true = force on, false = force off).
  typeOverrides: {},
  // showWeak: weak edges (wiki-links, passing mentions) are navigational noise
  // in an overview, so they're hidden until the reader opts in via the toolbar.
  showWeak: false,
  // focusId: the node the reader has spotlighted. When set, its closed
  // neighbourhood is highlighted and everything else dims — the core
  // "look at one thing at a time" move that tames a dense view.
  focusId: null,
  // showLanding: true when the user hasn't picked a view yet. URL hash with
  // any state hides it (so shared/bookmarked URLs deep-link); clicking the
  // brand title brings it back.
  showLanding: true,
};

function parseHash() {
  const h = (location.hash || '').replace(/^#/, '');
  if (!h) {
    state.showLanding = true;
    return;
  }
  state.showLanding = false;
  const params = new URLSearchParams(h);
  if (params.has('view') && VIEWS[params.get('view')]) {
    state.view = params.get('view');
  }
  if (params.has('q')) state.search = params.get('q');
  if (params.has('on')) {
    for (const t of params.get('on').split(',').filter(Boolean)) {
      state.typeOverrides[t] = true;
    }
  }
  if (params.has('off')) {
    for (const t of params.get('off').split(',').filter(Boolean)) {
      state.typeOverrides[t] = false;
    }
  }
  if (params.get('weak') === '1') state.showWeak = true;
  if (params.get('mode') === 'author') state.mode = 'author';
}

function serializeHash() {
  if (state.showLanding) {
    if (location.hash) history.replaceState(null, '', `${location.pathname}${location.search}`);
    return;
  }
  const params = new URLSearchParams();
  params.set('view', state.view);
  if (state.search) params.set('q', state.search);
  const on = [];
  const off = [];
  for (const [t, v] of Object.entries(state.typeOverrides)) {
    if (v === true) on.push(t);
    else if (v === false) off.push(t);
  }
  if (on.length) params.set('on', on.join(','));
  if (off.length) params.set('off', off.join(','));
  if (state.showWeak) params.set('weak', '1');
  if (state.mode === 'author') params.set('mode', 'author');
  const str = params.toString();
  const target = `#${str}`;
  if (location.hash !== target) {
    history.replaceState(null, '', `${location.pathname}${location.search}${target}`);
  }
}

// ---------------------------------------------------------------- filtering

function effectiveTypes(meta) {
  // The set of node types currently visible: view's defaults, with overrides.
  const all = Object.keys(meta.nodeTypes);
  const viewSpec = VIEWS[state.view];
  const baseline = new Set(viewSpec.nodeTypes ?? all);
  for (const t of all) {
    if (state.typeOverrides[t] === true) baseline.add(t);
    if (state.typeOverrides[t] === false) baseline.delete(t);
  }
  return baseline;
}

function effectivePredicates(meta) {
  const viewSpec = VIEWS[state.view];
  return viewSpec.predicates ? new Set(viewSpec.predicates) : null; // null = all
}

function matchesSearch(node, q) {
  if (!q) return true;
  const ql = q.toLowerCase();
  if ((node.label || '').toLowerCase().includes(ql)) return true;
  if ((node.id || '').toLowerCase().includes(ql)) return true;
  const aliases = node.props?.aliases || [];
  for (const a of aliases) if (a.toLowerCase().includes(ql)) return true;
  const summary = node.props?.summary || '';
  if (summary.toLowerCase().includes(ql)) return true;
  return false;
}

function isWeakPred(meta, pred) {
  return meta.predicates[pred]?.category === 'weak';
}

// Node diameter from its visible degree. sqrt scale + a cap so a degree-40 hub
// reads as a hub without dwarfing everything; structural anchors (Part,
// Chapter) override this with a fixed size in buildStyle.
function nodeSize(deg) {
  const d = Math.max(0, Math.min(deg, 16));
  return Math.round(22 + 34 * Math.sqrt(d / 16));
}

// Which nodes/edges exist in the current view. Search no longer filters here —
// it highlights in context (see refreshEmphasis), so typing never collapses
// the graph or forces a re-layout.
function computeVisible(meta, nodes, edges) {
  const types = effectiveTypes(meta);
  const preds = effectivePredicates(meta); // null = all predicates

  // Stage 1: type filter
  let visibleNodes = nodes.filter(n => types.has(n.type));
  const visibleIds = new Set(visibleNodes.map(n => n.id));

  // Stage 2: edge filter — predicate allowed by the view, both endpoints
  // visible, and (unless the reader opted in) not a weak navigational edge.
  const visibleEdges = edges.filter(e =>
    (!preds || preds.has(e.predicate)) &&
    (state.showWeak || !isWeakPred(meta, e.predicate)) &&
    visibleIds.has(e.source) &&
    visibleIds.has(e.target),
  );

  // Stage 3 (opt-in): some views (e.g. contested) are noisy unless we drop
  // nodes with no visible edges, so the rendering shows only the part of the
  // graph the predicate filter is actually exposing.
  if (VIEWS[state.view].connectedOnly) {
    const connected = new Set();
    for (const e of visibleEdges) { connected.add(e.source); connected.add(e.target); }
    visibleNodes = visibleNodes.filter(n => connected.has(n.id));
  }

  // Degree over the *visible* edge set — drives node size and label survival.
  const degree = new Map(visibleNodes.map(n => [n.id, 0]));
  for (const e of visibleEdges) {
    if (degree.has(e.source)) degree.set(e.source, degree.get(e.source) + 1);
    if (degree.has(e.target)) degree.set(e.target, degree.get(e.target) + 1);
  }

  return { visibleNodes, visibleEdges, degree };
}

// ---------------------------------------------------------------- rendering

function buildStyle(meta) {
  const sheet = [
    {
      selector: 'node',
      style: {
        'label': 'data(label)',
        'font-size': 9,
        'text-valign': 'bottom',
        'text-margin-y': 4,
        'color': '#0f172a',
        'width': 'data(size)',
        'height': 'data(size)',
        'border-width': 1,
        'border-color': '#0f172a',
        'border-opacity': 0.35,
        // Labels are hidden by default; the level-of-detail pass (.lbl) reveals
        // anchors, hubs, and whatever the reader is focused on. A white text
        // halo keeps the revealed labels readable over a busy edge field.
        'text-opacity': 0,
        'text-outline-color': '#f8fafc',
        'text-outline-width': 2.4,
        'text-outline-opacity': 0.9,
        'min-zoomed-font-size': 7,
      },
    },
    {
      selector: 'edge',
      style: {
        'curve-style': 'bezier',
        'width': 1.3,
        'opacity': 0.6,
        'target-arrow-shape': 'triangle',
        'arrow-scale': 0.75,
      },
    },

    // --- label level-of-detail: anything carrying .lbl shows its label -----
    { selector: 'node.lbl', style: { 'text-opacity': 1 } },

    // --- emphasis (search match / focus neighbourhood) --------------------
    { selector: 'node.matched', style: { 'border-width': 3, 'border-color': '#facc15', 'border-opacity': 1, 'text-opacity': 1 } },
    { selector: 'node.nbr', style: { 'text-opacity': 1 } },
    { selector: 'node:selected', style: { 'border-width': 3, 'border-color': '#0f172a', 'border-opacity': 1, 'text-opacity': 1 } },
    { selector: 'node.focused', style: { 'border-width': 4, 'border-color': '#0f172a', 'border-opacity': 1, 'text-opacity': 1, 'z-index': 9999 } },
    { selector: 'edge.focus-edge', style: { 'opacity': 0.95, 'width': 2.2 } },

    // --- weak navigational edges (wiki-links, mentions), opt-in ----------
    { selector: 'edge.weak', style: { 'line-style': 'dashed', 'opacity': 0.3, 'width': 1, 'arrow-scale': 0.6 } },

    // --- dimmed (out of focus / non-match): defined late so it wins -------
    { selector: '.dim', style: { 'opacity': 0.12 } },
    { selector: 'node.dim', style: { 'text-opacity': 0, 'border-opacity': 0.15 } },
    { selector: 'edge.dim', style: { 'opacity': 0.04 } },

    // --- hover always reveals a label, even on a dimmed node (last wins) --
    { selector: 'node.hover-lbl', style: { 'text-opacity': 1, 'opacity': 0.97, 'z-index': 9998 } },
  ];

  for (const [type, t] of Object.entries(meta.nodeTypes)) {
    sheet.push({
      selector: `node[type = "${type}"]`,
      style: {
        'background-color': t.color,
        'shape': t.shape,
      },
    });
  }

  // Structural anchors get a stable, prominent size regardless of degree so
  // the book's skeleton stays legible as the reader moves between views.
  sheet.push({ selector: 'node[type = "Part"]', style: { 'width': 54, 'height': 54, 'font-size': 11 } });
  sheet.push({ selector: 'node[type = "Chapter"]', style: { 'width': 40, 'height': 40, 'font-size': 10 } });

  for (const [pred, p] of Object.entries(meta.predicates)) {
    sheet.push({
      selector: `edge[predicate = "${pred}"]`,
      style: {
        'line-color': p.color,
        'target-arrow-color': p.color,
        'target-arrow-shape': p.directed ? 'triangle' : 'none',
      },
    });
  }

  return sheet;
}

function renderTabs() {
  const nav = document.getElementById('view-tabs');
  nav.innerHTML = Object.entries(VIEWS)
    .filter(([, v]) => state.mode === 'author' || !v.authorOnly)
    .map(([key, v]) =>
      `<button class="tab${key === state.view ? ' active' : ''}" data-view="${key}" title="${escapeHtml(v.desc)}">${escapeHtml(v.label)}</button>`
    ).join('');
}

function renderViewDesc() {
  const el = document.getElementById('view-desc');
  const base = VIEWS[state.view].desc;
  if (state.mode === 'reader') {
    el.innerHTML = `${escapeHtml(base)} <span class="reader-tip">Each dot is an idea; each line a relationship. Click any dot to focus it and read more.</span>`;
  } else {
    el.textContent = base;
  }
}

function renderLegend(meta, statsByType, statsByPredicate) {
  if (state.mode === 'reader') { renderReaderKey(meta); return; }
  const el = document.getElementById('legend');
  const baseline = new Set(VIEWS[state.view].nodeTypes ?? Object.keys(meta.nodeTypes));
  const effective = effectiveTypes(meta);

  const typeRows = Object.entries(meta.nodeTypes).map(([type, t]) => {
    const total = statsByType[type] || 0;
    const visible = effective.has(type);
    const inBaseline = baseline.has(type);
    const cls = ['legend-row', 'toggle'];
    if (total === 0) cls.push('empty');
    if (!visible) cls.push('off');
    if (!inBaseline && visible) cls.push('forced-on');
    if (inBaseline && !visible) cls.push('forced-off');
    return `<button class="${cls.join(' ')}" data-type="${type}" title="Click to toggle">
      <span class="swatch" style="background:${t.color}"></span>
      <span class="legend-label">${type}</span>
      <span class="legend-count">${total}</span>
    </button>`;
  }).join('');

  const byCategory = {};
  for (const [pred, p] of Object.entries(meta.predicates)) {
    (byCategory[p.category] ||= []).push([pred, p]);
  }

  const activePreds = effectivePredicates(meta); // null = all

  const predSections = Object.entries(byCategory).map(([cat, preds]) => {
    const rows = preds.map(([pred, p]) => {
      const n = statsByPredicate[pred] || 0;
      const active = activePreds === null ? true : activePreds.has(pred);
      const cls = ['legend-row'];
      if (n === 0) cls.push('empty');
      if (!active) cls.push('off');
      return `<div class="${cls.join(' ')}">
        <span class="line" style="background:${p.color}"></span>
        <span class="legend-label">${pred}</span>
        <span class="legend-count">${n}</span>
      </div>`;
    }).join('');
    return `<div class="legend-subcat"><h3>${cat}</h3>${rows}</div>`;
  }).join('');

  el.innerHTML = `
    <section>
      <h2>Node types <span class="hint">click to toggle</span></h2>
      ${typeRows}
    </section>
    <section>
      <h2>Predicates <span class="hint">set by view</span></h2>
      ${predSections}
    </section>
    ${hasOverrides() ? `<button id="reset-overrides" class="reset-btn">Reset filters</button>` : ''}
  `;
}

function hasOverrides() {
  return Object.keys(state.typeOverrides).length > 0;
}

// Reader-mode legend: a plain-language key of the kinds of things on screen.
// Non-interactive — orientation, not controls.
function renderReaderKey(meta) {
  const el = document.getElementById('legend');
  const effective = effectiveTypes(meta);
  const rows = Object.entries(meta.nodeTypes)
    .filter(([type]) => effective.has(type) && (GRAPH.statsByType[type] || 0) > 0)
    .map(([type, t]) => `
      <div class="reader-key-row" title="${escapeHtml(t.description || '')}">
        <span class="swatch" style="background:${t.color}"></span>
        <span class="reader-key-label">${escapeHtml(plainType(type))}</span>
      </div>`).join('');
  el.innerHTML = `
    <section class="reader-key">
      <h2>What you're looking at</h2>
      <p class="reader-key-intro">A map of the book's ideas and how they connect. Each dot is one idea; lines join ideas that relate. Click a dot to focus it and read more.</p>
      <div class="reader-key-rows">${rows}</div>
    </section>`;
}

// Construct a Quartz-relative URL for a Note/Chapter's prose page.
// Viewer is expected to live at <site>/graph/, prose pages at <site>/<slug>/.
// In local dev (served by python http.server at /src/) the URL won't resolve;
// Phase 28 puts the viewer on the actual Quartz site where it does.
function proseUrlFor(node) {
  if (node.type === 'Note') {
    const file = node.props?.file;
    if (!file) return null;
    // Match Quartz's pretty-URL form: ../<slug> (no extension, no trailing
    // slash). Quartz slugifies spaces to hyphens, so a filename like
    // "optionality vs access.md" publishes at ".../optionality-vs-access";
    // mirror that here or the link 404s. GitHub Pages resolves to the .html.
    return `../${file.replace(/\.md$/, '').replace(/\s+/g, '-')}`;
  }
  if (node.type === 'Chapter') {
    const draft = node.props?.draftNote;
    if (!draft) return null;
    const noteNode = GRAPH.nodeById.get(draft);
    return noteNode ? proseUrlFor(noteNode) : null;
  }
  return null;
}

// Returns the Status node id linked from a Chapter (if any).
function chapterStatusId(nodeId) {
  for (const e of GRAPH.outByNode.get(nodeId) || []) {
    if (e.predicate === 'hasStatus') return e.target;
  }
  return null;
}

const STATUS_PROP_BY_TYPE = {
  Claim: 'status',
  Question: 'status',
  Source: 'availability',
};

function statusBadgeFor(node) {
  // 1) From a directly-stored prop (Claim.status, Question.status, Source.availability)
  const propKey = STATUS_PROP_BY_TYPE[node.type];
  if (propKey && node.props?.[propKey]) {
    return { label: node.props[propKey], kind: propKey };
  }
  // 2) From a hasStatus edge (Chapter → Status)
  if (node.type === 'Chapter') {
    const statusId = chapterStatusId(node.id);
    if (statusId) {
      const statusNode = GRAPH.nodeById.get(statusId);
      const label = statusNode?.label || statusId.replace(/^status:/, '');
      return { label, kind: 'status' };
    }
  }
  return null;
}

// Render the neighbour list as predicate-grouped clickable items.
// Direction = 'out' means edges starting at this node; 'in' means ending at it.
function renderNeighbourGroup(nodeId, direction) {
  const list = direction === 'out'
    ? (GRAPH.outByNode.get(nodeId) || [])
    : (GRAPH.inByNode.get(nodeId) || []);
  if (!list.length) return '';
  // Group by predicate
  const byPred = {};
  for (const e of list) (byPred[e.predicate] ||= []).push(e);
  const groups = Object.entries(byPred).sort(([a], [b]) => a.localeCompare(b)).map(([pred, edges]) => {
    const rows = edges.map(e => {
      const otherId = direction === 'out' ? e.target : e.source;
      const other = GRAPH.nodeById.get(otherId);
      if (!other) return '';
      return `<li>
        <button class="node-link" data-id="${escapeHtml(otherId)}">
          <span class="node-link-type type-badge tiny" title="${escapeHtml(typeDesc(other.type))}">${escapeHtml(other.type)}</span>
          <span class="node-link-label">${escapeHtml(other.label || otherId)}</span>
        </button>
      </li>`;
    }).join('');
    return `<div class="predicate-group">
      <h4>${escapeHtml(pred)} <span class="pred-count">${edges.length}</span></h4>
      <ul>${rows}</ul>
    </div>`;
  }).join('');
  return `<section class="neighbours-section">
    <h3>${direction === 'out' ? 'Outgoing' : 'Incoming'} <span class="dir-count">${list.length}</span></h3>
    ${groups}
  </section>`;
}

// Pick which props to surface in the detail panel, and which to suppress
// because we've already rendered them above (summary, file, draftNote, etc.).
const HIDDEN_PROPS_BY_TYPE = {
  '*': new Set(['summary']),
  Note:    new Set(['summary', 'file', 'title', 'subtype', 'role']),
  Chapter: new Set(['summary', 'title', 'draftNote', 'ordinal', 'number', 'part']),
  Claim:   new Set(['summary', 'status', 'argues', 'arguedInChapters', 'dependsOn', 'harvestedFrom']),
  Question:new Set(['summary', 'status', 'workingAnswer', 'flaggedIn', 'blocksChapters']),
  Source:  new Set(['summary', 'availability', 'label']),
};

function renderProps(node) {
  const props = node.props || {};
  const hidden = HIDDEN_PROPS_BY_TYPE[node.type] || HIDDEN_PROPS_BY_TYPE['*'];
  const rows = Object.entries(props)
    .filter(([k]) => !hidden.has(k))
    .map(([k, v]) => {
      let displayed;
      if (Array.isArray(v)) {
        if (v.length === 0) return '';
        displayed = v.map(x => `<code>${escapeHtml(String(x))}</code>`).join(' ');
      } else if (typeof v === 'object' && v !== null) {
        displayed = `<code>${escapeHtml(JSON.stringify(v))}</code>`;
      } else {
        displayed = escapeHtml(String(v));
      }
      return `<dt>${escapeHtml(k)}</dt><dd>${displayed}</dd>`;
    })
    .filter(Boolean)
    .join('');
  return rows ? `<dl class="props">${rows}</dl>` : '';
}

function renderDetail(node) {
  const panel = document.getElementById('detail');
  const props = node.props || {};
  const summary = props.summary || props.workingAnswer || '';
  const badge = statusBadgeFor(node);
  const proseUrl = proseUrlFor(node);

  const metaPieces = [`<span class="type-badge" title="${escapeHtml(typeDesc(node.type))}">${escapeHtml(plainType(node.type))}</span>`];
  if (state.mode === 'author') metaPieces.push(`<code>${escapeHtml(node.id)}</code>`);
  if (badge) metaPieces.push(`<span class="status-badge status-${escapeHtml(badge.kind)} status-val-${escapeHtml(badge.label.replace(/\s+/g, '-').toLowerCase())}">${escapeHtml(badge.label)}</span>`);

  const proseLink = proseUrl
    ? `<a class="prose-link" href="${escapeHtml(proseUrl)}" target="_blank" rel="noopener">Read the prose →</a>`
    : '';

  const subtitleBits = [];
  if (props.title && props.title !== node.label) subtitleBits.push(escapeHtml(props.title));
  if (props.role) subtitleBits.push(`<span class="role">${escapeHtml(props.role)}</span>`);
  const subtitle = subtitleBits.length ? `<div class="subtitle">${subtitleBits.join(' · ')}</div>` : '';

  // For Questions and resolved-question working answers
  const workingAnswerBlock = (node.type === 'Question' && props.workingAnswer && props.status !== 'open')
    ? `<div class="working-answer"><strong>Working answer:</strong> ${escapeHtml(props.workingAnswer)}</div>`
    : '';

  panel.innerHTML = `
    <h2>${escapeHtml(node.label || node.id)}</h2>
    ${subtitle}
    <div class="meta">${metaPieces.join(' ')}</div>
    ${summary ? `<p class="summary">${escapeHtml(summary)}</p>` : ''}
    ${workingAnswerBlock}
    ${proseLink}
    ${state.mode === 'author' ? renderProps(node) : ''}
    ${renderNeighbourGroup(node.id, 'out')}
    ${renderNeighbourGroup(node.id, 'in')}
  `;
}

// Select and inspect a node by id — used by neighbour-link buttons.
function focusNode(nodeId) {
  const node = GRAPH.nodeById.get(nodeId);
  if (!node) return;
  // If the node isn't in the current view, switch to Full graph so it is.
  const types = effectiveTypes(GRAPH.meta);
  if (!types.has(node.type)) {
    state.view = 'full';
    state.typeOverrides = {};
    state.focusId = null;
    applyState({ relayout: true });
  }
  renderDetail(node);
  setFocus(nodeId);
}

function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, c => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[c]));
}

// ---------------------------------------------------------------- landing

// Per-view summary counts. Reads from the loaded graph, not hard-coded.
function tileSummary(viewKey) {
  const v = VIEWS[viewKey];
  const types = new Set(v.nodeTypes ?? Object.keys(GRAPH.meta.nodeTypes));
  // Pick 2–3 "headline" types for each view to summarise its contents.
  const headlineTypes = {
    overview: ['Part', 'Chapter'],
    argument: ['Chapter', 'Claim', 'Concept'],
    sources: ['Source', 'Claim'],
    questions: ['Question'],
    contested: ['Tension', 'Question', 'Claim'],
    drafting: ['Chapter', 'Status'],
    full: ['Node', 'Edge'],
  }[viewKey] || [];
  if (viewKey === 'full') {
    return `${GRAPH.nodes.length} nodes · ${GRAPH.edges.length} edges`;
  }
  if (viewKey === 'questions') {
    const open = GRAPH.nodes.filter(n => n.type === 'Question' && n.props?.status === 'open').length;
    const resolved = GRAPH.nodes.filter(n => n.type === 'Question' && n.props?.status === 'provisionally-resolved').length;
    return `${GRAPH.statsByType.Question || 0} questions · ${open} still open · ${resolved} provisionally resolved`;
  }
  if (viewKey === 'contested') {
    const tensions = GRAPH.statsByType.Tension || 0;
    const supersedes = GRAPH.edges.filter(e => e.predicate === 'supersedes').length;
    const openQ = GRAPH.nodes.filter(n => n.type === 'Question' && n.props?.status === 'open').length;
    return `${tensions} tensions · ${supersedes} supersessions · ${openQ} still-open question${openQ === 1 ? '' : 's'}`;
  }
  return headlineTypes
    .filter(t => types.has(t))
    .map(t => `${GRAPH.statsByType[t] || 0} ${t.toLowerCase()}${(GRAPH.statsByType[t] || 0) === 1 ? '' : 's'}`)
    .join(' · ');
}

function renderLanding() {
  const el = document.getElementById('landing');
  const tiles = Object.entries(VIEWS)
    .filter(([, v]) => state.mode === 'author' || !v.authorOnly)
    .map(([key, v]) => `
    <button class="landing-tile" data-view="${key}">
      <span class="tile-title">${escapeHtml(v.label)}</span>
      <span class="tile-desc">${escapeHtml(v.desc)}</span>
      <span class="tile-counts">${escapeHtml(tileSummary(key))}</span>
    </button>
  `).join('');
  el.innerHTML = `
    <div class="landing-inner">
      <h2>Where do you want to start?</h2>
      <p class="landing-intro">The ontology for <em>Lossy</em> has ${GRAPH.nodes.length} nodes across ${Object.keys(GRAPH.meta.nodeTypes).length} categories — chapters, claims, sources, concepts, open questions, and the edges between them. Pick a view that matches what you want to look at.</p>
      <div class="landing-tiles">${tiles}</div>
      <p class="landing-foot">You can switch views any time from the tabs in the header. To come back here, click the title.</p>
    </div>
  `;
}

function showLanding() {
  state.showLanding = true;
  serializeHash();
  document.getElementById('landing').hidden = false;
  document.getElementById('view-desc').hidden = true;
  document.querySelector('main').hidden = true;
  document.querySelectorAll('#view-tabs .tab').forEach(b => b.classList.remove('active'));
  document.getElementById('stats').textContent = `${GRAPH.nodes.length} nodes · ${GRAPH.edges.length} edges`;
  applyModeChrome();
  renderLanding();
}

function hideLanding() {
  state.showLanding = false;
  document.getElementById('landing').hidden = true;
  document.getElementById('view-desc').hidden = false;
  document.querySelector('main').hidden = false;
  // Cytoscape needs to know its container resized when revealed.
  if (GRAPH.cy) GRAPH.cy.resize();
}

// ---------------------------------------------------------------- state ops

function setView(view) {
  if (!VIEWS[view]) return;
  const wasOnLanding = state.showLanding;
  state.view = view;
  state.typeOverrides = {};
  state.focusId = null; // the focused node may not exist in the new view
  if (wasOnLanding) hideLanding();
  applyState({ relayout: true });
}

function toggleType(type) {
  const baseline = new Set(VIEWS[state.view].nodeTypes ?? Object.keys(GRAPH.meta.nodeTypes));
  const currentlyIn = state.typeOverrides[type] === true
    ? true
    : state.typeOverrides[type] === false
      ? false
      : baseline.has(type);
  if (currentlyIn) {
    // Turning off. If baseline had it, store an explicit false; otherwise clear the override.
    if (baseline.has(type)) state.typeOverrides[type] = false;
    else delete state.typeOverrides[type];
  } else {
    if (baseline.has(type)) delete state.typeOverrides[type];
    else state.typeOverrides[type] = true;
  }
  state.focusId = null; // node set changed; a stale focus would be misleading
  applyState({ relayout: true });
}

function setSearch(q) {
  state.search = q;
  // A search while focused clears the focus, so matches outside the focused
  // neighbourhood aren't hidden. Emphasis-only: no re-filter, no re-layout.
  if (q && state.focusId) { state.focusId = null; updateFocusHint(); }
  applyEmphasisOnly();
}

function toggleWeak() {
  state.showWeak = !state.showWeak;
  // Edge set changes but the node set doesn't — keep positions, don't relayout.
  applyState({ relayout: false });
}

function setMode(mode) {
  if ((mode !== 'reader' && mode !== 'author') || mode === state.mode) return;
  state.mode = mode;
  state.typeOverrides = {}; // author-only filters shouldn't linger into reader
  // Reader mode hides author-only views — fall back if we're sitting on one.
  if (state.mode === 'reader' && VIEWS[state.view]?.authorOnly) {
    state.view = DEFAULT_VIEW;
    state.focusId = null;
  }
  renderTabs(); // the available tab set changes with the mode
  if (state.showLanding) {
    serializeHash();
    showLanding();
  } else {
    applyState({ relayout: true });
  }
}

// Sync the mode-dependent chrome (title, toggle button, body hook, which
// toolbar controls are reader-appropriate). Cheap; safe to call on any render.
function applyModeChrome() {
  document.body.dataset.mode = state.mode;
  const h1 = document.querySelector('header .brand h1');
  if (h1) h1.textContent = state.mode === 'reader' ? 'Lossy — map of the book' : 'Lossy — Ontology';
  const btn = document.getElementById('mode-toggle');
  if (btn) {
    btn.textContent = state.mode === 'reader' ? 'Author tools' : '← Reader view';
    btn.setAttribute('aria-pressed', state.mode === 'author' ? 'true' : 'false');
    btn.title = state.mode === 'reader'
      ? 'Switch to the full author tools — every view, type and predicate filters'
      : 'Back to the simplified reader view';
  }
  // "weak links" is author jargon; readers get a cleaner toolbar.
  const weak = document.getElementById('btn-weak');
  if (weak) weak.hidden = state.mode === 'reader';
}

// ---------------------------------------------------------------- mounting

const GRAPH = {
  meta: null,
  nodes: [],
  edges: [],
  nodeById: null,
  outByNode: null, // Map<nodeId, edge[]> — outgoing edges (this node is source)
  inByNode: null,  // Map<nodeId, edge[]> — incoming edges (this node is target)
  cy: null,
  statsByType: {},
  statsByPredicate: {},
};

// Refresh the chrome around the graph (tabs, view description, legend,
// toolbar) — cheap, pure-DOM, no cytoscape work.
function refreshChrome() {
  applyModeChrome();
  document.querySelectorAll('#view-tabs .tab').forEach(b => {
    b.classList.toggle('active', b.dataset.view === state.view);
  });
  renderViewDesc();
  renderLegend(GRAPH.meta, GRAPH.statsByType, GRAPH.statsByPredicate);
  syncToolbar();
  updateFocusHint();
}

function syncToolbar() {
  const w = document.getElementById('btn-weak');
  if (w) {
    w.setAttribute('aria-pressed', state.showWeak ? 'true' : 'false');
    w.textContent = state.showWeak ? '− weak links' : '+ weak links';
  }
}

// Structural change (view / type / weak toggle): rebuild the element set and,
// when relayout is true, run the view's layout. Search and focus do NOT come
// through here — see applyEmphasisOnly.
function applyState({ relayout = true } = {}) {
  serializeHash();
  refreshChrome();
  rebuildElements({ relayout });
}

// Search / focus changed: re-weight emphasis only. The node set and their
// positions (including anything the reader dragged) are untouched, so there is
// no layout thrash.
function applyEmphasisOnly() {
  serializeHash();
  refreshEmphasis();
  fitToEmphasis();
}

function rebuildElements({ relayout }) {
  const { visibleNodes, visibleEdges, degree } = computeVisible(GRAPH.meta, GRAPH.nodes, GRAPH.edges);
  document.getElementById('stats').textContent =
    `${visibleNodes.length} / ${GRAPH.nodes.length} nodes · ${visibleEdges.length} / ${GRAPH.edges.length} edges`;

  const meta = GRAPH.meta;
  const elements = [
    ...visibleNodes.map(n => ({
      data: {
        id: n.id,
        label: n.label || n.id,
        type: n.type,
        deg: degree.get(n.id) || 0,
        size: nodeSize(degree.get(n.id) || 0),
      },
    })),
    ...visibleEdges.map(e => ({
      data: { id: e.id, source: e.source, target: e.target, predicate: e.predicate },
      classes: isWeakPred(meta, e.predicate) ? 'weak' : undefined,
    })),
  ];

  // Snapshot positions so a non-relayout rebuild (e.g. toggling weak edges)
  // keeps the existing arrangement instead of collapsing to the origin.
  const prevPos = {};
  GRAPH.cy.nodes().forEach(n => { prevPos[n.id()] = { ...n.position() }; });

  if (!elements.length) {
    GRAPH.cy.elements().remove();
    document.querySelector('#graph .placeholder')?.remove();
    const ph = document.createElement('div');
    ph.className = 'placeholder empty-graph';
    ph.textContent = `No nodes in this view. Try "Full graph" or toggle types in the legend.`;
    document.getElementById('graph').appendChild(ph);
    return;
  }
  document.querySelector('#graph .placeholder')?.remove();

  GRAPH.cy.stop(); // cancel any in-flight pan/zoom animation before re-laying out
  GRAPH.cy.elements().remove();
  GRAPH.cy.add(elements);

  if (relayout) {
    GRAPH.cy.layout(layoutFor(state.view)).run();
  } else {
    GRAPH.cy.nodes().forEach(n => { if (prevPos[n.id()]) n.position(prevPos[n.id()]); });
  }
  refreshEmphasis();
}

// The single source of truth for which nodes/edges are highlighted vs dimmed.
// Priority: an explicit focus wins; otherwise an active search; otherwise the
// resting state (anchors + hubs labelled, nothing dimmed).
function refreshEmphasis() {
  const cy = GRAPH.cy;
  if (!cy) return;
  cy.batch(() => {
    cy.elements().removeClass('dim nbr focused matched lbl focus-edge');
    markBaseLabels();

    if (state.focusId && cy.getElementById(state.focusId).nonempty()) {
      const node = cy.getElementById(state.focusId);
      const hood = node.closedNeighborhood();
      cy.elements().not(hood).addClass('dim');
      node.addClass('focused lbl');
      hood.nodes().addClass('nbr lbl');
      hood.edges().addClass('focus-edge');
      return;
    }

    const q = state.search.trim();
    if (q) {
      const matched = cy.nodes().filter(n => {
        const o = GRAPH.nodeById.get(n.id());
        return o && matchesSearch(o, q);
      });
      if (matched.nonempty()) {
        const hood = matched.closedNeighborhood();
        cy.elements().not(hood).addClass('dim');
        matched.addClass('matched lbl');
        hood.nodes().addClass('lbl');
      }
    }
  });
}

// Always-on labels: the structural skeleton (Parts, Chapters) plus the
// highest-degree hubs. Everything else stays unlabelled until focused/hovered.
function markBaseLabels() {
  const cy = GRAPH.cy;
  cy.nodes().forEach(n => {
    const o = GRAPH.nodeById.get(n.id());
    if (o && (o.type === 'Part' || o.type === 'Chapter')) n.addClass('lbl');
  });
  cy.nodes().sort((a, b) => (b.data('deg') || 0) - (a.data('deg') || 0))
    .slice(0, HUB_LABELS).forEach(n => n.addClass('lbl'));
}

// When a search is active, pan/zoom to frame the matches in context.
function fitToEmphasis() {
  const cy = GRAPH.cy;
  if (!cy || !state.search.trim()) return;
  const matched = cy.nodes('.matched');
  if (matched.nonempty()) {
    cy.animate({ fit: { eles: matched.closedNeighborhood(), padding: 60 } }, { duration: 320 });
  }
}

// Spotlight a node: highlight its neighbourhood, dim the rest, and frame the
// local subgraph (node + neighbours) so the reader sees the whole little story.
function setFocus(nodeId) {
  state.focusId = nodeId;
  refreshEmphasis();
  const ele = GRAPH.cy.getElementById(nodeId);
  if (ele && ele.nonempty()) {
    // Frame node + neighbours; cy.maxZoom (set at init) caps how far a small
    // neighbourhood can zoom in, so nodes never balloon.
    GRAPH.cy.animate({ fit: { eles: ele.closedNeighborhood(), padding: 80 } }, { duration: 300 });
  }
  updateFocusHint();
}

function clearFocus() {
  if (!state.focusId) return;
  state.focusId = null;
  refreshEmphasis();
  updateFocusHint();
}

function updateFocusHint() {
  const hint = document.getElementById('focus-hint');
  if (!hint) return;
  if (state.focusId) {
    const o = GRAPH.nodeById.get(state.focusId);
    hint.innerHTML = `Focused on <strong>${escapeHtml(o?.label || state.focusId)}</strong> · <button id="clear-focus" type="button">show all</button>`;
    hint.hidden = false;
  } else {
    hint.hidden = true;
  }
}

function layoutFor(view) {
  const spec = VIEWS[view];
  // animate:false — layouts snap into place. Animated layout (esp. dagre) could
  // leave cytoscape pinned in a never-ending render loop, which burns CPU on the
  // published site and prevents the canvas from ever reaching a stable frame.
  // The short focus/fit pans (cy.animate elsewhere) are finite and stay.
  const common = { animate: false, padding: 40, fit: true };
  switch (spec.layout) {
    case 'dagre':
      // Layered/hierarchical — reads as flow/containment, not a hairball.
      return { name: 'dagre', rankDir: spec.rankDir || 'TB', nodeSep: 24, edgeSep: 12, rankSep: 72, ...common };
    case 'fcose':
      // Fast compound spring embedder: well-separated organic clusters, far
      // cleaner than plain cose on dense graphs. randomize:true seeds a random
      // start and runs the full force phase — without it the spectral-only seed
      // collapses a dense graph into a diagonal line.
      return {
        name: 'fcose',
        quality: 'proof',
        randomize: true,
        nodeRepulsion: 9000,
        idealEdgeLength: 70,
        nodeSeparation: 110,
        gravity: 0.3,
        gravityRange: 3.2,
        numIter: 3000,
        packComponents: true,
        ...common,
      };
    case 'breadthfirst':
      return { name: 'breadthfirst', directed: true, spacingFactor: 1.3, ...common };
    default:
      return { name: 'cose', idealEdgeLength: 90, nodeOverlap: 18, ...common };
  }
}

async function loadJson(path) {
  const r = await fetch(path);
  if (!r.ok) throw new Error(`failed to load ${path}: ${r.status}`);
  return r.json();
}

async function loadJsonl(path) {
  const r = await fetch(path);
  if (!r.ok) throw new Error(`failed to load ${path}: ${r.status}`);
  const text = await r.text();
  return text.split('\n').filter(l => l.trim()).map(l => JSON.parse(l));
}

async function main() {
  parseHash();

  // All three are required. A failed fetch must surface as an error (caught
  // by main().catch below), not silently degrade to an empty graph that
  // looks like a legitimately-empty view — a staging mistake should look
  // broken, not blank.
  GRAPH.meta = await loadJson(`${DATA}/graph-meta.json`);
  GRAPH.nodes = await loadJsonl(`${DATA}/nodes.jsonl`);
  GRAPH.edges = await loadJsonl(`${DATA}/edges.jsonl`);
  GRAPH.nodeById = new Map(GRAPH.nodes.map(n => [n.id, n]));
  GRAPH.outByNode = new Map();
  GRAPH.inByNode = new Map();
  for (const e of GRAPH.edges) {
    (GRAPH.outByNode.get(e.source) || GRAPH.outByNode.set(e.source, []).get(e.source)).push(e);
    (GRAPH.inByNode.get(e.target) || GRAPH.inByNode.set(e.target, []).get(e.target)).push(e);
  }

  for (const n of GRAPH.nodes) GRAPH.statsByType[n.type] = (GRAPH.statsByType[n.type] || 0) + 1;
  for (const e of GRAPH.edges) GRAPH.statsByPredicate[e.predicate] = (GRAPH.statsByPredicate[e.predicate] || 0) + 1;

  renderTabs();

  // Event delegation — attach listeners once on stable containers, not on
  // re-rendered innerHTML (which would either drop listeners or stack them).
  document.getElementById('view-tabs').addEventListener('click', e => {
    const t = e.target.closest('button.tab');
    if (t) setView(t.dataset.view);
  });
  document.getElementById('legend').addEventListener('click', e => {
    const btn = e.target.closest('button.toggle[data-type]');
    if (btn) { toggleType(btn.dataset.type); return; }
    if (e.target.id === 'reset-overrides') {
      state.typeOverrides = {};
      state.focusId = null;
      applyState({ relayout: true });
    }
  });
  document.getElementById('landing').addEventListener('click', e => {
    const tile = e.target.closest('button.landing-tile');
    if (tile) setView(tile.dataset.view);
  });
  document.getElementById('home-link').addEventListener('click', () => {
    showLanding();
  });

  // Search wiring
  const searchInput = document.getElementById('search');
  searchInput.value = state.search;
  let searchTimer = null;
  searchInput.addEventListener('input', () => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => setSearch(searchInput.value), 150);
  });
  document.getElementById('search-clear').addEventListener('click', () => {
    searchInput.value = '';
    setSearch('');
    searchInput.focus();
  });

  // Initial cytoscape mount (empty; applyState fills it in)
  GRAPH.cy = cytoscape({
    container: document.getElementById('graph'),
    elements: [],
    style: buildStyle(GRAPH.meta),
    layout: { name: 'preset' },
    minZoom: 0.08,
    maxZoom: 2.2,
    wheelSensitivity: 0.2,
  });

  // Tap a node → inspect it and spotlight its neighbourhood.
  GRAPH.cy.on('tap', 'node', evt => {
    const id = evt.target.id();
    const orig = GRAPH.nodeById.get(id);
    if (orig) renderDetail(orig);
    setFocus(id);
  });
  // Tap empty canvas → drop the spotlight (show everything again).
  GRAPH.cy.on('tap', evt => { if (evt.target === GRAPH.cy) clearFocus(); });
  // Hover reveals a single label on demand, even for a dimmed node.
  GRAPH.cy.on('mouseover', 'node', evt => evt.target.addClass('hover-lbl'));
  GRAPH.cy.on('mouseout', 'node', evt => evt.target.removeClass('hover-lbl'));

  // Neighbour-link buttons in the detail panel jump to that node.
  document.getElementById('detail').addEventListener('click', e => {
    const btn = e.target.closest('button.node-link');
    if (btn) focusNode(btn.dataset.id);
  });

  // Graph toolbar: re-arrange, fit-to-screen, toggle weak links.
  document.getElementById('btn-relayout').addEventListener('click', () => {
    GRAPH.cy.layout(layoutFor(state.view)).run();
  });
  document.getElementById('btn-fit').addEventListener('click', () => {
    GRAPH.cy.animate({ fit: { padding: 40 } }, { duration: 320 });
  });
  document.getElementById('btn-weak').addEventListener('click', toggleWeak);
  document.getElementById('focus-hint').addEventListener('click', e => {
    if (e.target.id === 'clear-focus') clearFocus();
  });
  document.getElementById('mode-toggle').addEventListener('click', () => {
    setMode(state.mode === 'reader' ? 'author' : 'reader');
  });

  if (state.showLanding) {
    showLanding();
  } else {
    hideLanding();
    applyState({ relayout: true });
  }

  // Expose for browser-console debugging — read-only conventionally.
  window.__GRAPH = GRAPH;

  window.addEventListener('hashchange', () => {
    // External hash change (back button, etc.) — re-parse and re-render.
    state.mode = 'reader';
    state.view = DEFAULT_VIEW;
    state.search = '';
    state.typeOverrides = {};
    state.focusId = null;
    state.showWeak = false;
    state.showLanding = true;
    parseHash();
    renderTabs(); // available tabs depend on mode, which may have changed
    document.getElementById('search').value = state.search;
    if (state.showLanding) {
      showLanding();
    } else {
      hideLanding();
      applyState({ relayout: true });
    }
  });
}

main().catch(err => {
  console.error(err);
  const el = document.getElementById('graph');
  if (el) el.innerHTML = `<div class="empty-graph error">${escapeHtml(err.message)}</div>`;
});
