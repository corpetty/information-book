import { FINDING, MESSENGERS, FRAMINGS, TOWNS, CONNECTIONS, CARDS, QUOTES, COPY } from './bridge-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './bridge-engine.js';

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
const viewKey = (s) => `${s.screen}:${s.townIndex}`;

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
const stampSpan = (stamp) => h('span', { class: 'stamp tone-' + STAMPS[stamp].tone }, STAMPS[stamp].label);
const finding = () => h('p', { class: 'finding' }, FINDING);

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

function screenIntro() {
  return [
    h('p', { class: 'kicker' }, COPY.intro.kicker),
    title(COPY.intro.title),
    h('p', { class: 'lead' }, COPY.intro.body),
    h('h2', {}, COPY.intro.findingLabel),
    finding(),
    h('div', { class: 'actions' }, btn(COPY.intro.button, { type: 'START' }, 'primary')),
  ];
}

function screenTown() {
  const town = TOWNS[state.townIndex];
  return [
    title(fill(COPY.town.heading, { name: town.name })),
    h('p', {}, town.about),
    h('h2', {}, COPY.town.heard),
    h('ul', { class: 'heard' }, town.heard.map((t) => h('li', {}, t))),
    finding(),
    h('h2', {}, fill(COPY.town.pick, { name: town.name })),
    h('div', { class: 'stack' }, engine.offered(town).map((id) =>
      h('button', {
        type: 'button',
        class: 'item',
        'data-id': id,
        onclick: () => dispatch({ type: 'PICK_MESSENGER', id }),
      }, h('strong', {}, MESSENGERS[id].name), ' ', MESSENGERS[id].about))),
  ];
}

function screenFraming() {
  return [
    title(fill(COPY.framing.heading, { messenger: MESSENGERS[state.messenger].name })),
    h('div', { class: 'stack' }, Object.entries(FRAMINGS).map(([id, f]) =>
      h('button', {
        type: 'button',
        class: 'item',
        'data-id': id,
        onclick: () => dispatch({ type: 'PICK_FRAMING', id }),
      }, h('strong', {}, f.label), ' ', f.text))),
    h('div', { class: 'actions' }, btn(COPY.framing.back, { type: 'BACK' }, 'link')),
  ];
}

function screenReaction() {
  const town = TOWNS[state.townIndex];
  const r = state.results[state.results.length - 1];
  const last = state.townIndex === TOWNS.length - 1;
  return [
    title(fill(COPY.reaction.heading, { name: town.name })),
    h('div', { class: 'story-line' },
      h('p', { class: 'stamp-line' }, `${MESSENGERS[r.messenger].name} · ${FRAMINGS[r.framing].label}`),
      h('p', { class: 'stamp-line' }, stampSpan(r.lands)),
      h('p', { class: 'headline' }, r.text)),
    h('div', { class: 'actions' }, btn(last ? COPY.reaction.last : COPY.reaction.next, { type: 'NEXT' }, 'primary')),
  ];
}

function screenConnect() {
  return [
    title(COPY.connect.heading),
    h('p', {}, COPY.connect.body),
    quote(QUOTES.peer),
    newCards(COPY.connect.cards),
    h('div', { class: 'stack' }, Object.entries(CONNECTIONS).map(([id, c]) =>
      h('button', {
        type: 'button',
        class: 'item',
        'data-id': id,
        onclick: () => dispatch({ type: 'PICK_CONNECTION', id }),
      }, h('strong', {}, c.label), ' ', c.about))),
  ];
}

function screenEpilogue() {
  const finals = state.results.map((r) => engine.finalLands(r.lands, state.connection));
  const both = finals.every((s) => s === 'PRESERVED');
  return [
    title(COPY.epilogue.heading),
    h('p', {}, CONNECTIONS[state.connection].epilogue),
    state.results.map((r, i) => {
      const town = engine.getTown(r.townId);
      return [
        h('h3', {}, fill(COPY.epilogue.town, { name: town.name })),
        h('p', { class: 'stamp-line' }, stampSpan(finals[i])),
      ];
    }),
    h('p', {}, both ? COPY.epilogue.both : COPY.epilogue.notBoth),
    quote(QUOTES.channel),
    quote(QUOTES.audit),
    newCards(COPY.epilogue.cards),
    h('div', { class: 'actions' }, btn(COPY.epilogue.button, { type: 'NEXT' }, 'primary')),
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
  town: screenTown,
  framing: screenFraming,
  reaction: screenReaction,
  connect: screenConnect,
  epilogue: screenEpilogue,
  end: screenEnd,
};

function render() {
  app.replaceChildren(...SCREENS[state.screen]().flat(Infinity).filter((n) => n));
}

render();
