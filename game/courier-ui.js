import { ROUNDS, READERS, STAMPS, CARDS, QUOTES, COPY } from './courier-data.js';
import * as engine from './courier-engine.js';

let state = engine.initialState();
const app = document.getElementById('app');

const fmt = (n) => n.toLocaleString('en-US');

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

// Focus follows the view: toggling a chip keeps focus on that chip;
// anything that changes the view moves focus to its heading.
const viewKey = (s) => `${s.screen}:${s.roundIndex}:${s.hopIndex}`;

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
const claimEl = (claim) => h('p', { class: 'claim' + (isCaps(claim) ? ' caps' : '') }, claim);
const chipTexts = (round, ids) => round.chips.filter((c) => ids.includes(c.id)).map((c) => c.text);
const keptLine = (round, ids) => h('p', { class: 'kept-line' }, chipTexts(round, ids).join(' · '));
const stampSpan = (stamp) => h('span', { class: 'stamp tone-' + STAMPS[stamp].tone }, STAMPS[stamp].label);

function totals(round, tallies) {
  return h('p', { class: 'totals' },
    round.stamps.filter((s) => tallies[s] > 0).map((s) =>
      h('span', {}, `${STAMPS[s].label}: ${fmt(tallies[s])}`)));
}

function card(c) {
  return h('div', { class: 'card' },
    h('h3', {}, c.title),
    h('p', {}, c.text),
    h('a', { href: c.href }, 'Read the card'));
}

function quote(q) {
  return h('blockquote', {}, q.text, h('span', { class: 'attr' }, '— ' + q.attr));
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
  const round = ROUNDS[state.roundIndex];
  return [
    title(round.title),
    h('p', {}, round.brief),
    state.replay && h('p', { class: 'note' }, COPY.end.replayNote),
    h('div', { class: 'actions' }, btn(COPY.brief.button, { type: 'BEGIN_ROUND' }, 'primary')),
  ];
}

function screenChoose() {
  const round = ROUNDS[state.roundIndex];
  const options = round.hops[state.hopIndex].options;
  return [
    title(COPY.choose.heading),
    h('div', { class: 'stack' }, options.map((o) =>
      h('button', { type: 'button', onclick: () => dispatch({ type: 'CHOOSE_OPTION', id: o.id }) },
        h('span', { class: 'opt-to' }, o.to),
        h('span', { class: 'opt-claim' + (isCaps(o.claim) ? ' caps' : '') }, o.claim),
        h('span', { class: 'opt-meta' }, fill(COPY.choose.option, { budget: o.budget, reach: fmt(o.reach) }))))),
  ];
}

function screenHop() {
  const round = ROUNDS[state.roundIndex];
  const option = engine.getOption(round, state.hopIndex, state.optionId);
  const used = engine.cost(round, state.kept);
  const fit = engine.fits(round, state.kept, option.budget);
  const multi = round.hops[state.hopIndex].options.length > 1;
  return [
    title(fill(COPY.hop.heading, { n: state.hopIndex + 1, total: round.hops.length, to: option.to })),
    claimEl(option.claim),
    h('p', { class: 'meter' + (fit ? '' : ' over') }, fill(COPY.hop.room, { used, budget: option.budget })),
    h('p', { class: 'note' }, COPY.hop.help),
    state.lens && h('p', { class: 'note' }, COPY.hop.lens),
    h('div', { class: 'chips' }, round.chips.map((c) => {
      const alive = state.entryKept.includes(c.id);
      const kept = state.kept.includes(c.id);
      return h('button', {
        type: 'button',
        class: 'chip',
        'data-id': c.id,
        'aria-pressed': kept ? 'true' : 'false',
        disabled: !alive,
        onclick: () => dispatch({ type: 'TOGGLE_CHIP', id: c.id }),
      },
      c.text,
      h('span', { class: 'cost' }, String(c.cost)),
      state.lens && h('span', { class: 'mark' }, c.role === 'corrective' ? COPY.hop.lensKey : COPY.hop.lensDetail));
    })),
    !fit && h('p', { class: 'over-line' }, fill(COPY.hop.over, { k: used - option.budget })),
    h('div', { class: 'actions' },
      h('button', { type: 'button', class: 'primary', disabled: !fit, onclick: () => dispatch({ type: 'HAND_ON' }) }, COPY.hop.button),
      multi && btn(COPY.hop.back, { type: 'BACK' }, 'link')),
  ];
}

function screenPredict() {
  const round = ROUNDS[state.roundIndex];
  const option = engine.getOption(round, state.hopIndex, state.optionId);
  return [
    title(COPY.predict.heading),
    claimEl(option.claim),
    keptLine(round, state.kept),
    h('div', { class: 'stack' }, round.stamps.map((s) =>
      btn(STAMPS[s].label, { type: 'PREDICT', stamp: s }))),
  ];
}

function screenResult() {
  const round = ROUNDS[state.roundIndex];
  const out = state.outcome;
  const option = engine.getOption(round, round.hops.length - 1, out.optionId);
  const last = state.replay || state.roundIndex === ROUNDS.length - 1;
  const nodes = [
    title(COPY.result.heading),
    claimEl(option.claim),
    keptLine(round, state.kept),
    out.groups.map((g) =>
      h('div', { class: 'group' },
        h('p', { class: 'who' }, fill(COPY.result.reader, { name: READERS[g.reader].name, key: READERS[g.reader].key })),
        h('p', {}, h('span', { class: 'count' }, fmt(g.count)), ' ', stampSpan(g.stamp)),
        h('p', { class: 'said' }, `“${g.text}”`))),
    totals(round, out.tallies),
    h('p', {}, engine.resultLine(round, out)),
  ];
  if (round.predict) {
    nodes.push(h('p', {}, state.prediction === out.majority
      ? COPY.result.called
      : fill(COPY.result.missed, { expected: STAMPS[state.prediction].label, actual: STAMPS[out.majority].label })));
  }
  if (round.rival) {
    const rv = engine.resolve(round, round.rival.optionId, round.rival.kept);
    nodes.push(h('div', { class: 'rival' }, h('p', {}, round.rival.text), totals(round, rv.tallies)));
  }
  if (round.compare) {
    nodes.push(h('p', { class: 'compare' }, `${round.compare.label}: ${fmt(round.compare.count)} ${round.compare.suffix}`));
  }
  nodes.push(quote(QUOTES[round.quote]));
  if (state.newCards.length) {
    nodes.push(h('h2', {}, COPY.result.cards));
    for (const id of state.newCards) nodes.push(card(CARDS.find((c) => c.id === id)));
  }
  nodes.push(h('div', { class: 'actions' },
    btn(last ? COPY.result.finish : COPY.result.next, { type: 'NEXT' }, 'primary')));
  return nodes;
}

function screenEnd() {
  const nodes = [title(COPY.end.heading)];
  for (const entry of state.ledger) {
    const round = ROUNDS.find((r) => r.id === entry.roundId);
    nodes.push(h('div', { class: 'ledger-entry' },
      h('h3', {}, round.title),
      h('ul', {}, entry.hops.map((hop) => {
        const kept = chipTexts(round, hop.kept).join(' · ') || 'nothing';
        const cut = chipTexts(round, hop.cut).join(' · ') || 'nothing';
        return h('li', {}, `${hop.to} — ${COPY.end.ledgerKept}: ${kept} — ${COPY.end.ledgerCut}: ${cut}`);
      })),
      totals(round, entry.outcome.tallies)));
  }
  nodes.push(h('ul', { class: 'card-list' }, state.cards.map((id) => {
    const c = CARDS.find((x) => x.id === id);
    return h('li', {}, h('a', { href: c.href }, c.title));
  })));
  nodes.push(h('h2', {}, COPY.end.carryHeading));
  nodes.push(h('ol', {}, COPY.end.carry.map((q) => h('li', {}, q))));
  nodes.push(quote(QUOTES.aim));
  nodes.push(h('h2', {}, COPY.end.cutHeading));
  nodes.push(h('ul', {}, COPY.end.cut.map((t) => h('li', {}, t))));
  nodes.push(h('div', { class: 'actions' }, btn(COPY.end.replay, { type: 'REPLAY_R2' }, 'primary')));
  nodes.push(h('p', { class: 'note' }, COPY.end.replayNote));
  nodes.push(h('ul', {}, COPY.end.links.map((l) => h('li', {}, h('a', { href: l.href }, l.label)))));
  return nodes;
}

const SCREENS = {
  intro: screenIntro,
  brief: screenBrief,
  choose: screenChoose,
  hop: screenHop,
  predict: screenPredict,
  result: screenResult,
  end: screenEnd,
};

function render() {
  app.replaceChildren(...SCREENS[state.screen]().flat().filter((n) => n));
}

render();
