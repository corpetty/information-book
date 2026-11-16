import { DAYS, REACH, CARDS, QUOTES, COPY } from './desk-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './desk-engine.js';

let state = engine.initialState();
const app = document.getElementById('app');

const fmt = (n) => n.toLocaleString('en-US');
const STAMP_ORDER = ['INVERTED', 'FLAG', 'PRESERVED'];

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

// Focus follows the view: a pick keeps focus on the story just pressed;
// anything that changes the view moves focus to its heading.
const viewKey = (s) => `${s.screen}:${s.dayIndex}`;

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
const isCaps = (claim) => claim === claim.toUpperCase();
const stampSpan = (stamp) => h('span', { class: 'stamp tone-' + STAMPS[stamp].tone }, STAMPS[stamp].label);
const itemById = (day, id) => day.items.find((i) => i.id === id);

function card(c) {
  return h('div', { class: 'card' },
    h('h3', {}, c.title),
    h('p', {}, c.text),
    h('a', { href: c.href }, 'Read the card'));
}

function quote(q) {
  return h('blockquote', {}, q.text, h('span', { class: 'attr' }, '— ' + q.attr));
}

function totalsLine(tallies) {
  return h('p', { class: 'totals' },
    STAMP_ORDER.filter((s) => tallies[s] > 0).map((s) =>
      h('span', {}, `${STAMPS[s].label}: ${fmt(tallies[s])}`)));
}

function storyLine(day, id) {
  const item = itemById(day, id);
  return h('div', { class: 'story-line' },
    h('p', { class: 'headline' }, item.headline),
    h('p', { class: 'stamp-line' }, stampSpan(item.lands), ` · ${fmt(REACH[item.heat])}`),
    h('p', { class: 'story-note' }, item.note));
}

function newCards(heading) {
  if (!state.newCards.length) return [];
  return [
    h('h2', {}, heading),
    state.newCards.map((id) => card(CARDS.find((c) => c.id === id))),
  ];
}

function screenIntro() {
  return [
    h('p', { class: 'kicker' }, COPY.intro.kicker),
    title(COPY.intro.title),
    h('p', { class: 'lead' }, COPY.intro.body),
    h('div', { class: 'actions' }, btn(COPY.intro.button, { type: 'START' }, 'primary')),
  ];
}

function screenBrief() {
  const day = DAYS[state.dayIndex];
  const status = day.endowed
    ? COPY.brief.statusEndowed
    : fill(COPY.brief.status, { rent: day.rent, strikes: state.strikes });
  return [
    title(fill(COPY.brief.heading, { n: state.dayIndex + 1 })),
    h('p', { class: 'status' }, status),
    h('p', {}, day.brief),
    h('div', { class: 'actions' }, btn(COPY.brief.button, { type: 'SEE_WIRE' }, 'primary')),
  ];
}

function screenPick() {
  const day = DAYS[state.dayIndex];
  const n = state.dayIndex + 1;
  const full = state.picked.length === 3;
  const att = engine.attention(day, state.picked);
  const short = full && !day.endowed && att < day.rent;
  const meterText = day.endowed
    ? fill(COPY.pick.meterEndowed, { a: att })
    : fill(COPY.pick.meter, { a: att, rent: day.rent });
  return [
    title(fill(COPY.pick.heading, { n })),
    h('p', {}, fill(COPY.pick.count, { k: state.picked.length })),
    h('p', { class: 'meter' + (short ? ' over' : '') }, meterText),
    h('div', { class: 'stack' }, day.items.map((item) => {
      const picked = state.picked.includes(item.id);
      return h('button', {
        type: 'button',
        class: 'item',
        'data-id': item.id,
        'aria-pressed': picked ? 'true' : 'false',
        disabled: full && !picked,
        onclick: () => dispatch({ type: 'TOGGLE', id: item.id }),
      },
      h('span', { class: 'headline' + (isCaps(item.headline) ? ' caps' : '') }, item.headline),
      h('span', { class: 'heat' }, fill(COPY.pick.heat, { heat: item.heat })));
    })),
    short && h('p', { class: 'over-line' }, fill(COPY.pick.short, { k: day.rent - att })),
    h('div', { class: 'actions' },
      h('button', { type: 'button', class: 'primary', disabled: !full, onclick: () => dispatch({ type: 'RUN' }) }, COPY.pick.button)),
  ];
}

function screenDay() {
  const day = DAYS[state.dayIndex];
  const out = state.current;
  const att = engine.attention(day, out.picks);
  return [
    title(fill(COPY.day.heading, { n: state.dayIndex + 1 })),
    h('ul', {}, out.picks.map((id) => h('li', {}, itemById(day, id).headline))),
    h('p', {}, fill(COPY.day.earned, { a: att, rent: day.rent })),
    h('p', {}, out.paid ? COPY.day.paid : fill(COPY.day.missed, { s: state.strikes })),
    h('p', {}, fill(COPY.day.reach, { reach: fmt(out.reach) })),
    state.closedOn !== null && h('p', {}, COPY.day.closed),
    h('div', { class: 'actions' }, btn(COPY.day.button, { type: 'NEXT' }, 'primary')),
  ];
}

function screenAudit() {
  const a = engine.audit(state);
  const nodes = [
    title(COPY.audit.heading),
    h('p', {}, a.survived ? COPY.audit.survived : fill(COPY.audit.closed, { d: a.closedOn })),
    h('p', {}, COPY.audit.meter),
  ];
  for (const entry of a.entries) {
    const idx = DAYS.findIndex((d) => d.id === entry.dayId);
    nodes.push(h('h3', {}, fill(COPY.audit.dayHeading, { n: idx + 1 })));
    for (const id of entry.picks) nodes.push(storyLine(DAYS[idx], id));
  }
  nodes.push(totalsLine(a.totals));
  nodes.push(h('p', {}, a.totals.INVERTED || a.totals.FLAG
    ? fill(COPY.audit.summary, { inv: fmt(a.totals.INVERTED || 0), flag: fmt(a.totals.FLAG || 0) })
    : COPY.audit.summaryClean));
  nodes.push(quote(QUOTES.proxy));
  nodes.push(quote(QUOTES.captor));
  nodes.push(...newCards(COPY.audit.cards));
  nodes.push(h('div', { class: 'actions' }, btn(COPY.audit.button, { type: 'NEXT' }, 'primary')));
  return nodes;
}

function screenFinal() {
  const day = DAYS[state.dayIndex];
  const rivalIds = engine.rivalPicks(day);
  const r = engine.outcome(day, rivalIds);
  return [
    title(COPY.final.heading),
    h('h2', {}, COPY.final.yoursLabel),
    state.current.picks.map((id) => storyLine(day, id)),
    h('p', {}, fill(COPY.final.yours, { reach: fmt(state.current.reach) })),
    h('h2', {}, COPY.final.rivalLabel),
    rivalIds.map((id) => storyLine(day, id)),
    h('p', {}, fill(COPY.final.rival, { reach: fmt(r.reach) })),
    quote(QUOTES.outlast),
    newCards(COPY.final.cards),
    h('div', { class: 'actions' }, btn(COPY.final.button, { type: 'NEXT' }, 'primary')),
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
  brief: screenBrief,
  pick: screenPick,
  day: screenDay,
  audit: screenAudit,
  final: screenFinal,
  end: screenEnd,
};

function render() {
  app.replaceChildren(...SCREENS[state.screen]().flat(Infinity).filter((n) => n));
}

render();
