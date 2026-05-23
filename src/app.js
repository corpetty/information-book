// Ontology viewer — Phase 25 (view presets + search + type filter).
//
// State model: a single `state` object holds {view, search, typeOverrides}.
// The URL hash is the source of truth for sharing; every state change writes
// to the hash, every hash change re-renders. Filtering is pure:
// computeVisibleElements(state) returns the cytoscape elements array, and
// applyState() runs the cytoscape layout against that result.

const DATA = '../data';

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
    layout: 'breadthfirst',
  },
  argument: {
    label: 'Argument map',
    desc: 'Chapters, claims, concepts/mechanisms, and how the argument depends on itself.',
    nodeTypes: ['Chapter', 'Claim', 'Concept', 'Mechanism', 'Note', 'CaseStudy'],
    predicates: ['argues', 'covers', 'dependsOn', 'definedIn', 'derivesFrom', 'supersedes', 'representedBy'],
    layout: 'cose',
  },
  sources: {
    label: 'Source map',
    desc: 'Where claims and concepts get their evidence; which sources support and pressure-test what.',
    nodeTypes: ['Source', 'Claim', 'Concept', 'Mechanism', 'Author', 'Tradition'],
    predicates: ['supports', 'pressureTests', 'evidencedBy', 'cites', 'authoredBy', 'partOfTradition'],
    layout: 'cose',
  },
  questions: {
    label: 'Open questions',
    desc: 'Foundational questions and the chapters whose final shape depends on them.',
    nodeTypes: ['Question', 'Chapter', 'Note', 'Status'],
    predicates: ['flagsOpenQuestion', 'hasStatus'],
    layout: 'cose',
  },
  drafting: {
    label: 'Drafting status',
    desc: 'Where each chapter sits in the workflow — drafted, in-workshop, skeleton, not yet drafted.',
    nodeTypes: ['Chapter', 'Part', 'Status', 'Note'],
    predicates: ['partOf', 'hasStatus', 'representedBy'],
    layout: 'breadthfirst',
  },
  full: {
    label: 'Full graph',
    desc: 'Everything — every node, every edge. Use this when you know what you are looking for.',
    nodeTypes: null,
    predicates: null,
    layout: 'cose',
  },
};

const DEFAULT_VIEW = 'overview';

// ---------------------------------------------------------------- state

const state = {
  view: DEFAULT_VIEW,
  search: '',
  // typeOverrides: {[type]: boolean} — when present, overrides the view's
  // nodeTypes membership (true = force on, false = force off).
  typeOverrides: {},
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

function computeVisible(meta, nodes, edges) {
  const types = effectiveTypes(meta);
  const preds = effectivePredicates(meta);
  const q = state.search.trim();

  // Stage 1: type filter
  let visibleNodes = nodes.filter(n => types.has(n.type));

  // Stage 2: search filter — keep matches AND their direct neighbours (so a
  // match isn't a floating dot with no context).
  if (q) {
    const direct = new Set(visibleNodes.filter(n => matchesSearch(n, q)).map(n => n.id));
    if (direct.size === 0) {
      visibleNodes = [];
    } else {
      const keep = new Set(direct);
      for (const e of edges) {
        if (preds && !preds.has(e.predicate)) continue;
        if (direct.has(e.source) || direct.has(e.target)) {
          keep.add(e.source);
          keep.add(e.target);
        }
      }
      visibleNodes = visibleNodes.filter(n => keep.has(n.id));
    }
  }

  const visibleIds = new Set(visibleNodes.map(n => n.id));

  // Stage 3: edge filter — predicate must be allowed, both endpoints visible.
  const visibleEdges = edges.filter(e =>
    (!preds || preds.has(e.predicate)) &&
    visibleIds.has(e.source) &&
    visibleIds.has(e.target),
  );

  // Stage 4: mark search-matched nodes for highlight (vs neighbour-context).
  const matched = q ? new Set(visibleNodes.filter(n => matchesSearch(n, q)).map(n => n.id)) : null;

  return { visibleNodes, visibleEdges, matched };
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
        'color': '#1f2937',
        'width': 32,
        'height': 32,
        'border-width': 1,
        'border-color': '#0f172a',
        'border-opacity': 0.35,
      },
    },
    {
      selector: 'edge',
      style: {
        'curve-style': 'bezier',
        'width': 1.4,
        'opacity': 0.75,
        'target-arrow-shape': 'triangle',
        'arrow-scale': 0.8,
      },
    },
    {
      selector: ':selected',
      style: {
        'border-width': 3,
        'border-color': '#0f172a',
        'border-opacity': 1,
      },
    },
    {
      selector: 'node[?matched]',
      style: {
        'border-width': 3,
        'border-color': '#facc15',
        'border-opacity': 1,
      },
    },
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
  nav.innerHTML = Object.entries(VIEWS).map(([key, v]) =>
    `<button class="tab${key === state.view ? ' active' : ''}" data-view="${key}" title="${v.desc}">${v.label}</button>`
  ).join('');
}

function renderViewDesc() {
  document.getElementById('view-desc').textContent = VIEWS[state.view].desc;
}

function renderLegend(meta, statsByType, statsByPredicate) {
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

// Construct a Quartz-relative URL for a Note/Chapter's prose page.
// Viewer is expected to live at <site>/graph/, prose pages at <site>/<slug>/.
// In local dev (served by python http.server at /src/) the URL won't resolve;
// Phase 28 puts the viewer on the actual Quartz site where it does.
function proseUrlFor(node) {
  if (node.type === 'Note') {
    const file = node.props?.file;
    if (!file) return null;
    // file is like "outline.md" — strip the extension, prefix with ../
    return `../${file.replace(/\.md$/, '')}/`;
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
          <span class="node-link-type type-badge tiny">${other.type}</span>
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

  const metaPieces = [`<span class="type-badge">${node.type}</span>`, `<code>${escapeHtml(node.id)}</code>`];
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
    ${renderProps(node)}
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
    applyState({ relayout: true });
  }
  // Select in cytoscape if present
  const ele = GRAPH.cy.getElementById(nodeId);
  if (ele && ele.length) {
    GRAPH.cy.elements().unselect();
    ele.select();
    GRAPH.cy.animate({ center: { eles: ele }, zoom: Math.max(GRAPH.cy.zoom(), 0.7) }, { duration: 240 });
  }
  renderDetail(node);
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
  return headlineTypes
    .filter(t => types.has(t))
    .map(t => `${GRAPH.statsByType[t] || 0} ${t.toLowerCase()}${(GRAPH.statsByType[t] || 0) === 1 ? '' : 's'}`)
    .join(' · ');
}

function renderLanding() {
  const el = document.getElementById('landing');
  const tiles = Object.entries(VIEWS).map(([key, v]) => `
    <button class="landing-tile" data-view="${key}">
      <span class="tile-title">${escapeHtml(v.label)}</span>
      <span class="tile-desc">${escapeHtml(v.desc)}</span>
      <span class="tile-counts">${escapeHtml(tileSummary(key))}</span>
    </button>
  `).join('');
  el.innerHTML = `
    <div class="landing-inner">
      <h2>Where do you want to start?</h2>
      <p class="landing-intro">The Information Book's ontology has ${GRAPH.nodes.length} nodes across ${Object.keys(GRAPH.meta.nodeTypes).length} categories — chapters, claims, sources, concepts, open questions, and the edges between them. Pick a view that matches what you want to look at.</p>
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
  applyState({ relayout: true });
}

function setSearch(q) {
  state.search = q;
  applyState({ relayout: true });
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

function applyState({ relayout }) {
  serializeHash();

  // Refresh tabs (active class), view desc, legend
  document.querySelectorAll('#view-tabs .tab').forEach(b => {
    b.classList.toggle('active', b.dataset.view === state.view);
  });
  renderViewDesc();
  renderLegend(GRAPH.meta, GRAPH.statsByType, GRAPH.statsByPredicate);

  const { visibleNodes, visibleEdges, matched } = computeVisible(GRAPH.meta, GRAPH.nodes, GRAPH.edges);
  document.getElementById('stats').textContent =
    `${visibleNodes.length} / ${GRAPH.nodes.length} nodes · ${visibleEdges.length} / ${GRAPH.edges.length} edges`;

  const elements = [
    ...visibleNodes.map(n => ({
      data: {
        id: n.id,
        label: n.label || n.id,
        type: n.type,
        matched: matched && matched.has(n.id) ? 1 : 0,
      },
    })),
    ...visibleEdges.map(e => ({
      data: { id: e.id, source: e.source, target: e.target, predicate: e.predicate },
    })),
  ];

  if (!elements.length) {
    GRAPH.cy.elements().remove();
    document.querySelector('#graph .placeholder')?.remove();
    const ph = document.createElement('div');
    ph.className = 'placeholder empty-graph';
    ph.textContent = state.search
      ? `No nodes match "${state.search}" in this view. Try a different view or clear the search.`
      : `No nodes in this view. Try "Full graph" or toggle types in the legend.`;
    document.getElementById('graph').appendChild(ph);
    return;
  }
  document.querySelector('#graph .placeholder')?.remove();

  GRAPH.cy.elements().remove();
  GRAPH.cy.add(elements);
  if (relayout) {
    GRAPH.cy.layout(layoutFor(state.view)).run();
  }
}

function layoutFor(view) {
  const name = VIEWS[view].layout;
  if (name === 'breadthfirst') {
    return {
      name: 'breadthfirst',
      directed: true,
      padding: 30,
      spacingFactor: 1.4,
      animate: true,
      animationDuration: 320,
    };
  }
  return {
    name: 'cose',
    animate: true,
    animationDuration: 320,
    idealEdgeLength: 90,
    nodeOverlap: 18,
    padding: 30,
  };
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

  GRAPH.meta = await loadJson(`${DATA}/graph-meta.json`);
  GRAPH.nodes = await loadJsonl(`${DATA}/nodes.jsonl`).catch(() => []);
  GRAPH.edges = await loadJsonl(`${DATA}/edges.jsonl`).catch(() => []);
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
  });

  GRAPH.cy.on('tap', 'node', evt => {
    const orig = GRAPH.nodeById.get(evt.target.id());
    if (orig) renderDetail(orig);
  });

  // Neighbour-link buttons in the detail panel jump to that node.
  document.getElementById('detail').addEventListener('click', e => {
    const btn = e.target.closest('button.node-link');
    if (btn) focusNode(btn.dataset.id);
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
    state.view = DEFAULT_VIEW;
    state.search = '';
    state.typeOverrides = {};
    state.showLanding = true;
    parseHash();
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
