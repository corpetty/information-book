import { WEEKS, STOPS, HOP_COST, TUTOR_COST, CARDS, QUOTES, COPY } from './reader-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './reader-engine.js';

let state = engine.initialState();
const app = document.getElementById('app');

const STAMP_ORDER = ['PRESERVED', 'INVERTED', 'FLAG', 'BOUNCED'];

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
// button it came from (when it has a data-id); anything that changes the view,
// including every trace, moves focus to the heading.
const viewKey = (s) => `${s.screen}:${s.weekIndex}:${s.claimIndex}:${s.depth}`;

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
const stampLabel = (stamp) => (stamp === 'BOUNCED' ? COPY.reveal.noBelief : STAMPS[stamp].label);
const stampSpan = (stamp) => h('span', { class: 'stamp tone-' + STAMPS[stamp].tone }, stampLabel(stamp));

function card(c) {
  return h('div', { class: 'card' },
    h('h3', {}, c.title),
    h('p', {}, c.text),
    h('a', { href: c.href }, 'Read the card'));
}

function quote(q) {
  return h('blockquote', {}, q.text, h('span', { class: 'attr' }, '— ' + q.attr));
}

function tallyLine(tallies) {
  return h('p', { class: 'totals' },
    STAMP_ORDER.filter((s) => tallies[s] > 0).map((s) => h('span', {}, `${stampLabel(s)}: ${tallies[s]}`)));
}

const claimText = (text) => h('p', { class: 'claim' + (isCaps(text) ? ' caps' : '') }, text);

function screenIntro() {
  return [
    h('p', { class: 'kicker' }, COPY.intro.kicker),
    title(COPY.intro.title),
    h('p', { class: 'lead' }, COPY.intro.body),
    h('div', { class: 'actions' }, btn(COPY.intro.button, { type: 'START' }, 'primary')),
  ];
}

function screenBrief() {
  const week = WEEKS[state.weekIndex];
  return [
    title(fill(COPY.brief.heading, { n: state.weekIndex + 1 })),
    h('p', {}, week.brief),
    h('div', { class: 'actions' }, btn(COPY.brief.button, { type: 'BEGIN' }, 'primary')),
  ];
}

function screenClaim() {
  const week = WEEKS[state.weekIndex];
  const claim = week.claims[state.claimIndex];
  const depth = state.depth;
  const form = engine.formAt(claim, depth);
  const traceOk = engine.canTrace(state);
  const nodes = [
    title(fill(COPY.claim.heading, { i: state.claimIndex + 1, total: week.claims.length })),
    h('p', { class: 'status' }, fill(COPY.claim.minutes, { m: week.minutes - state.spent, total: week.minutes })),
    h('p', { class: 'where' }, fill(COPY.claim.where, { stop: STOPS[depth] })),
    claimText(form.text),
  ];
  if (depth > 0) {
    const above = [];
    for (let d = depth - 1; d >= 0; d--) above.push(d);
    nodes.push(
      h('h3', {}, COPY.claim.trail),
      h('ul', { class: 'trail' }, above.map((d) =>
        h('li', {}, h('span', { class: 'stop' }, STOPS[d]), engine.formAt(claim, d).text))));
  }
  nodes.push(h('div', { class: 'actions' },
    depth < 4 && h('button', {
      type: 'button',
      disabled: !traceOk,
      onclick: () => dispatch({ type: 'TRACE' }),
    }, fill(COPY.claim.trace, { next: STOPS[depth + 1], cost: HOP_COST[depth] })),
    btn(depth === 0 ? COPY.claim.accept : COPY.claim.settle, { type: 'SETTLE' }, 'primary'),
    depth === 0 && btn(COPY.claim.shrug, { type: 'SHRUG' })));
  if (depth === 4) nodes.push(h('p', {}, COPY.claim.bottom));
  else if (!traceOk) nodes.push(h('p', {}, COPY.claim.noTime));
  if (week.tools && depth === 0) {
    nodes.push(h('div', { class: 'tools' },
      btn(COPY.claim.assistant, { type: 'ASK_ASSISTANT' }),
      h('button', {
        type: 'button',
        disabled: !engine.canTutor(state),
        onclick: () => dispatch({ type: 'ASK_TUTOR' }),
      }, fill(COPY.claim.tutor, { cost: TUTOR_COST }))));
  }
  return nodes;
}

function screenAnswer() {
  const week = WEEKS[state.weekIndex];
  const claim = week.claims[state.claimIndex];
  const nodes = [];
  if (state.answer === 'assistant') {
    nodes.push(title(COPY.answer.assistantHeading), claimText(claim.assistant.text));
  } else {
    nodes.push(
      title(COPY.answer.tutorHeading),
      claimText(claim.meme.text),
      h('ol', { class: 'trail' }, claim.hops.map((hop, i) =>
        h('li', {}, h('span', { class: 'stop' }, STOPS[i + 1]), hop.text))));
  }
  nodes.push(h('div', { class: 'actions' }, btn(COPY.answer.button, { type: 'NEXT' }, 'primary')));
  return nodes;
}

function routeText(b) {
  switch (b.route) {
    case 'accept': return COPY.reveal.routeAccept;
    case 'shrug': return COPY.reveal.routeShrug;
    case 'trace': return fill(COPY.reveal.routeTrace, { stop: STOPS[b.depth] });
    case 'assistant': return COPY.reveal.routeAssistant;
    default: return COPY.reveal.routeTutor;
  }
}

function screenReveal() {
  const week = WEEKS[state.weekIndex];
  const beliefs = engine.weekBeliefs(state, week.id);
  const last = state.weekIndex === WEEKS.length - 1;
  const others = week.tools
    ? [[COPY.reveal.busy, 'accept'], [COPY.reveal.assistantOnly, 'assistant']]
    : [[COPY.reveal.busy, 'accept'], [COPY.reveal.shrugger, 'shrug']];
  const quotes = week.tools ? [QUOTES.summary, QUOTES.owner] : [QUOTES.raw, QUOTES.budget];
  return [
    title(fill(COPY.reveal.heading, { n: state.weekIndex + 1 })),
    h('p', {}, fill(COPY.reveal.spent, { used: state.spent, total: week.minutes })),
    h('h2', {}, COPY.reveal.you),
    beliefs.map((b) => {
      const claim = week.claims.find((c) => c.id === b.claimId);
      return h('div', { class: 'story-line route-line' },
        h('p', { class: 'headline' }, claim.meme.text),
        h('p', { class: 'stamp-line' },
          routeText(b), ' · ', fill(COPY.reveal.minutes, { m: b.minutes }), ' · ', stampSpan(b.lands)),
        h('p', { class: 'story-note' }, claim.lesson));
    }),
    tallyLine(engine.tally(beliefs)),
    h('h2', {}, COPY.reveal.others),
    others.map(([label, mode]) => h('div', {},
      h('p', {}, label),
      tallyLine(engine.tally(engine.defaultBeliefs(week, mode))))),
    quotes.map(quote),
    state.newCards.length > 0 && [
      h('h2', {}, COPY.reveal.cards),
      state.newCards.map((id) => card(CARDS.find((c) => c.id === id))),
    ],
    h('div', { class: 'actions' }, btn(last ? COPY.reveal.finish : COPY.reveal.next, { type: 'NEXT' }, 'primary')),
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
  claim: screenClaim,
  answer: screenAnswer,
  reveal: screenReveal,
  end: screenEnd,
};

function render() {
  app.replaceChildren(...SCREENS[state.screen]().flat(Infinity).filter((n) => n));
}

render();
