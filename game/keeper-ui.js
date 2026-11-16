import { RULES, FUNDING, OUTCOMES, CARDS, QUOTES, COPY } from './keeper-data.js';
import * as engine from './keeper-engine.js';

let state = engine.initialState();
const app = document.getElementById('app');

function fill(template, values) {
  return template.replace(/\{(\w+)\}/g, (m, k) => (k in values ? String(values[k]) : m));
}

function h(tag, props = {}, ...children) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props)) {
    if (v === false || v == null) continue;
    if (k === 'class') el.className = v;
    else if (k === 'text') el.textContent = v;
    else if (k === 'onclick') el.addEventListener('click', (e) => { if (el.disabled) return; v(e); });
    else if (v === true) el.setAttribute(k, '');
    else el.setAttribute(k, v);
  }
  for (const c of children.flat()) {
    if (c == null || c === false) continue;
    el.append(c.nodeType ? c : document.createTextNode(c));
  }
  return el;
}

// Focus follows the view: an action that keeps the view keeps focus on the
// button it came from (when it has a data-id); anything that changes the view
// moves focus to the heading.
const viewKey = (s) => `${s.screen}:${s.g}`;

function dispatch(action) {
  const before = viewKey(state);
  state = engine.step(state, action);
  render();
  if (action.id && viewKey(state) === before) {
    const same = app.querySelector(`[data-id="${action.id}"]`);
    if (same) { same.focus(); return; }
  }
  const h1 = app.querySelector('h1');
  if (h1) h1.focus();
  window.scrollTo(0, 0);
}

const title = (text) => h('h1', { tabindex: '-1', text });
const btn = (label, action, cls) => h('button', { type: 'button', class: cls, onclick: () => dispatch(action) }, label);

function card(c) {
  return h('div', { class: 'card' },
    h('h3', {}, c.title),
    h('p', {}, c.text),
    h('a', { href: c.href }, 'Read the card'));
}

function quote(q) {
  return h('blockquote', {}, q.text, h('span', { class: 'attr' }, '— ' + q.attr));
}

function newCards(heading) {
  return state.newCards.length > 0 && [
    h('h2', {}, heading),
    state.newCards.map((id) => card(CARDS.find((c) => c.id === id))),
  ];
}

// The status line: funds for the generation being played, then the archive
// and readers the library starts it with.
function statusLine(p) {
  const cur = engine.current(state);
  return h('p', { class: 'status' }, fill(COPY.gen.status, { p, a: cur.archive, r: cur.readers }));
}

function screenIntro() {
  return [
    h('p', { class: 'kicker' }, COPY.intro.kicker),
    title(COPY.intro.title),
    h('p', { class: 'lead' }, COPY.intro.body),
    h('div', { class: 'actions' }, btn(COPY.intro.button, { type: 'START' }, 'primary')),
  ];
}

function screenFund() {
  return [
    title(COPY.fund.heading),
    h('p', {}, COPY.fund.body),
    h('div', { class: 'stack' }, Object.entries(FUNDING).map(([id, f]) =>
      h('button', {
        type: 'button',
        class: 'item',
        'data-id': id,
        onclick: () => dispatch({ type: 'PICK_FUNDING', id }),
      }, h('strong', {}, f.label), ' ', f.about, h('span', { class: 'opt-meta' }, f.funds.join(' · '))))),
  ];
}

function screenOffer() {
  return [
    title(COPY.offer.heading),
    statusLine(engine.funds(state.funding, state.g, false)),
    h('p', {}, COPY.offer.body),
    h('div', { class: 'stack' },
      btn(COPY.offer.accept, { type: 'ACCEPT' }, 'item'),
      btn(COPY.offer.decline, { type: 'DECLINE' }, 'item')),
  ];
}

function screenGen() {
  const total = engine.funds(state.funding, state.g, state.accepted);
  const copies = Array.from({ length: total + 1 }, (_, c) => c);
  return [
    title(fill(COPY.gen.heading, { n: state.g })),
    statusLine(total),
    state.g === RULES.offerGeneration && state.accepted && h('p', {}, COPY.gen.engine),
    h('h2', {}, COPY.gen.pick),
    h('div', { class: 'stack' }, copies.map((copy) =>
      h('button', {
        type: 'button',
        class: 'item',
        'data-id': String(copy),
        onclick: () => dispatch({ type: 'SPEND', copy }),
      }, fill(COPY.gen.split, { c: copy, t: total - copy })))),
  ];
}

function screenResult() {
  const r = state.ledger[state.ledger.length - 1];
  const last = state.g === RULES.generations;
  return [
    title(fill(COPY.result.heading, { n: state.g })),
    h('p', {}, fill(COPY.result.archive, { a: r.archive })),
    h('p', {}, fill(COPY.result.readers, { r: r.readers })),
    r.summary > 0 && h('p', {}, fill(COPY.result.summary, { s: r.summary })),
    r.readers === 0 && r.archive > 0 && h('p', {}, COPY.result.locked),
    r.archive === 0 && h('p', {}, COPY.result.crumbled),
    h('div', { class: 'actions' }, btn(last ? COPY.result.last : COPY.result.next, { type: 'NEXT' }, 'primary')),
  ];
}

function screenVerdict() {
  const out = OUTCOMES[engine.verdict(state.ledger[state.ledger.length - 1])];
  return [
    title(COPY.verdict.heading),
    h('h2', {}, out.title),
    h('p', {}, out.text),
    h('h3', {}, COPY.verdict.ledger),
    h('ul', {}, state.ledger.map((r) =>
      h('li', {}, fill(r.summary > 0 ? COPY.verdict.rowSummary : COPY.verdict.row,
        { n: r.g, c: r.copy, t: r.teach, a: r.archive, r: r.readers, s: r.summary })))),
    quote(QUOTES.corrupted),
    quote(QUOTES.outlast),
    newCards(COPY.verdict.cards),
    h('div', { class: 'actions' }, btn(COPY.verdict.button, { type: 'NEXT' }, 'primary')),
  ];
}

function screenEnd() {
  return [
    title(COPY.end.heading),
    h('ol', {}, COPY.end.carry.map((q) => h('li', {}, q))),
    h('h2', {}, COPY.end.cutHeading),
    h('ul', {}, COPY.end.cut.map((t) => h('li', {}, t))),
    h('div', { class: 'actions' }, btn(COPY.end.replay, { type: 'REPLAY' }, 'primary')),
    h('ul', {}, COPY.end.links.map((l) => h('li', {}, h('a', { href: l.href }, l.label)))),
  ];
}

const SCREENS = {
  intro: screenIntro,
  fund: screenFund,
  offer: screenOffer,
  gen: screenGen,
  result: screenResult,
  verdict: screenVerdict,
  end: screenEnd,
};

function render() {
  app.replaceChildren(...SCREENS[state.screen]().flat(Infinity).filter((n) => n));
}

render();
