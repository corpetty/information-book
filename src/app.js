const DATA = '../data';

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

function renderLegend(meta, statsByType, statsByPredicate) {
  const el = document.getElementById('legend');
  const typeRows = Object.entries(meta.nodeTypes).map(([type, t]) => {
    const n = statsByType[type] || 0;
    return `<div class="legend-row${n === 0 ? ' empty' : ''}">
      <span class="swatch" style="background:${t.color}"></span>
      <span class="legend-label">${type}</span>
      <span class="legend-count">${n}</span>
    </div>`;
  }).join('');

  const byCategory = {};
  for (const [pred, p] of Object.entries(meta.predicates)) {
    (byCategory[p.category] ||= []).push([pred, p]);
  }

  const predSections = Object.entries(byCategory).map(([cat, preds]) => {
    const rows = preds.map(([pred, p]) => {
      const n = statsByPredicate[pred] || 0;
      return `<div class="legend-row${n === 0 ? ' empty' : ''}">
        <span class="line" style="background:${p.color}"></span>
        <span class="legend-label">${pred}</span>
        <span class="legend-count">${n}</span>
      </div>`;
    }).join('');
    return `<div class="legend-subcat"><h3>${cat}</h3>${rows}</div>`;
  }).join('');

  el.innerHTML = `
    <section>
      <h2>Node types</h2>
      ${typeRows}
    </section>
    <section>
      <h2>Predicates</h2>
      ${predSections}
    </section>
  `;
}

function renderDetail(node) {
  const panel = document.getElementById('detail');
  const props = node.props || {};
  const propRows = Object.entries(props).map(([k, v]) => `
    <tr><th>${k}</th><td>${typeof v === 'object' ? JSON.stringify(v) : String(v)}</td></tr>
  `).join('');
  const provRows = (node.provenance || []).map(p =>
    `<tr><th>provenance</th><td>${JSON.stringify(p)}</td></tr>`
  ).join('');
  panel.innerHTML = `
    <h2>${node.label || node.id}</h2>
    <div class="meta"><span class="type-badge">${node.type}</span> <code>${node.id}</code></div>
    ${propRows || provRows ? `<table>${propRows}${provRows}</table>` : '<div class="empty">(no props)</div>'}
  `;
}

async function main() {
  const meta = await loadJson(`${DATA}/graph-meta.json`);
  const nodes = await loadJsonl(`${DATA}/nodes.jsonl`).catch(() => []);
  const edges = await loadJsonl(`${DATA}/edges.jsonl`).catch(() => []);

  const nodeById = new Map(nodes.map(n => [n.id, n]));

  const statsByType = {};
  for (const n of nodes) statsByType[n.type] = (statsByType[n.type] || 0) + 1;
  const statsByPredicate = {};
  for (const e of edges) statsByPredicate[e.predicate] = (statsByPredicate[e.predicate] || 0) + 1;

  document.getElementById('stats').textContent =
    `${nodes.length} nodes · ${edges.length} edges`;

  renderLegend(meta, statsByType, statsByPredicate);

  const elements = [
    ...nodes.map(n => ({
      data: { id: n.id, label: n.label || n.id, type: n.type },
    })),
    ...edges.map(e => ({
      data: { id: e.id, source: e.source, target: e.target, predicate: e.predicate },
    })),
  ];

  if (!elements.length) {
    document.getElementById('graph').innerHTML =
      '<div class="empty-graph">Empty graph. Run <code>make build</code>.</div>';
    return;
  }

  const cy = cytoscape({
    container: document.getElementById('graph'),
    elements,
    style: buildStyle(meta),
    layout: {
      name: 'cose',
      animate: false,
      idealEdgeLength: 90,
      nodeOverlap: 18,
      padding: 30,
    },
  });

  cy.on('tap', 'node', evt => {
    const orig = nodeById.get(evt.target.id());
    if (orig) renderDetail(orig);
  });
}

main().catch(err => {
  console.error(err);
  const el = document.getElementById('graph');
  if (el) el.innerHTML = `<div class="empty-graph error">${err.message}</div>`;
});
