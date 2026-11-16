import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { WEEKS, STOPS, HOP_COST, TUTOR_COST, CARDS, QUOTES } from './reader-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './reader-engine.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const W1 = engine.getWeek('week1');
const W2 = engine.getWeek('week2');

test('costToDepth', () => {
  assert.deepEqual([0, 1, 2, 3, 4].map(engine.costToDepth), [0, 2, 7, 17, 32]);
});

// Every route for a claim: [label, cost, lands].
function routes(week, claim) {
  const out = [['shrug', 0, 'BOUNCED']];
  for (let d = 0; d <= 4; d++) out.push([`believe${d}`, engine.costToDepth(d), engine.formAt(claim, d).lands]);
  if (week.tools) {
    out.push(['assistant', 0, claim.assistant.lands]);
    out.push(['tutor', TUTOR_COST, claim.hops[3].lands]);
  }
  return out;
}

function cheapestPreserved(week, claim) {
  return routes(week, claim)
    .filter((r) => r[2] === 'PRESERVED')
    .sort((a, b) => a[1] - b[1])[0];
}

test('week 1 cheapest routes to PRESERVED', () => {
  const got = W1.claims.map((c) => cheapestPreserved(W1, c)[1]);
  assert.deepEqual(got, [0, 7, 2, 7, 32]);
  assert.equal(got.reduce((a, b) => a + b, 0), 48);
  assert.ok(48 <= W1.minutes);
});

test('week 1 forest is only right at the measurement', () => {
  const forest = W1.claims.find((c) => c.id === 'forest');
  for (let d = 0; d <= 3; d++) assert.equal(engine.formAt(forest, d).lands, 'INVERTED');
  assert.equal(engine.formAt(forest, 4).lands, 'PRESERVED');
});

test('week 2 cheapest routes to PRESERVED', () => {
  const got = W2.claims.map((c) => cheapestPreserved(W2, c));
  assert.deepEqual(got.map((r) => r[1]), [0, 4, 4]);
  assert.deepEqual(got.map((r) => r[0]), ['assistant', 'tutor', 'tutor']);
  assert.ok(8 <= W2.minutes);
});

test('week 2 over-tracing does not fit', () => {
  assert.equal(2 * engine.costToDepth(2), 14);
  assert.ok(14 > W2.minutes);
});

function enumerate(week) {
  let affordable = 0;
  let allGood = 0;
  const rec = (i, cost, good) => {
    if (cost > week.minutes) return;
    if (i === week.claims.length) {
      affordable++;
      if (good) allGood++;
      return;
    }
    for (const [, c, lands] of routes(week, week.claims[i])) rec(i + 1, cost + c, good && lands === 'PRESERVED');
  };
  rec(0, 0, true);
  return { affordable, allGood };
}

test('route enumeration', () => {
  assert.deepEqual(enumerate(W1), { affordable: 4309, allGood: 2 });
  assert.deepEqual(enumerate(W2), { affordable: 169, allGood: 1 });
});

test('default readers', () => {
  assert.deepEqual(engine.tally(engine.defaultBeliefs(W1, 'accept')), { PRESERVED: 1, INVERTED: 3, FLAG: 1 });
  assert.deepEqual(engine.tally(engine.defaultBeliefs(W1, 'shrug')), { BOUNCED: 5 });
  assert.deepEqual(engine.tally(engine.defaultBeliefs(W2, 'assistant')), { PRESERVED: 1, INVERTED: 2 });
});

test('data invariants', () => {
  const ids = new Set();
  for (const w of WEEKS) {
    for (const c of w.claims) {
      assert.ok(!ids.has(c.id), `dup claim ${c.id}`);
      ids.add(c.id);
      assert.ok(c.meme && c.hops.length === 4, `${c.id} forms`);
      for (const f of [c.meme, ...c.hops, ...(c.assistant ? [c.assistant] : [])]) {
        assert.ok(f.lands in STAMPS, `${c.id} lands ${f.lands}`);
      }
      assert.equal(!!c.assistant, w.tools, `${c.id} assistant`);
    }
  }
  const cardIds = new Set();
  const weekIds = WEEKS.map((w) => w.id);
  for (const c of CARDS) {
    assert.ok(!cardIds.has(c.id), `dup card ${c.id}`);
    cardIds.add(c.id);
    assert.ok(weekIds.includes(c.week), `card ${c.id} week`);
  }
  assert.equal(STOPS.length, 5);
  assert.equal(HOP_COST.length, 4);
});

test('quotes match the chapters', () => {
  for (const [key, q] of Object.entries(QUOTES)) {
    const raw = fs.readFileSync(path.join(root, q.source), 'utf8');
    const norm = raw
      .replace(/\[\[[^\]|]*\|([^\]]*)\]\]/g, '$1')
      .replace(/\[\[([^\]]*)\]\]/g, '$1')
      .replace(/\*\*/g, '')
      .replace(/\s+/g, ' ');
    assert.ok(norm.includes(q.text), `quote ${key} not found in ${q.source}`);
  }
});

test('card links resolve to content files', () => {
  for (const c of CARDS) {
    const p = c.href.replace(/^\.\.\//, '');
    const a = path.join(root, 'content', `${p}.md`);
    const b = path.join(root, 'content', `${p.replaceAll('-', ' ')}.md`);
    assert.ok(fs.existsSync(a) || fs.existsSync(b), `card ${c.id} -> ${p}`);
  }
});

function deepFreeze(o) {
  if (o && typeof o === 'object' && !Object.isFrozen(o)) {
    Object.freeze(o);
    for (const v of Object.values(o)) deepFreeze(v);
  }
  return o;
}

const a = (type) => ({ type });
const [START, BEGIN, TRACE, SETTLE, SHRUG, NEXT] = ['START', 'BEGIN', 'TRACE', 'SETTLE', 'SHRUG', 'NEXT'].map(a);
const ASK_ASSISTANT = a('ASK_ASSISTANT');
const ASK_TUTOR = a('ASK_TUTOR');

function play(freeze, ...actions) {
  let s = engine.initialState();
  for (const x of actions) s = engine.step(freeze ? deepFreeze(s) : s, x);
  return s;
}

const WEEK1_A = [
  START, BEGIN,
  SETTLE,
  TRACE, TRACE, SETTLE,
  TRACE, SETTLE,
  TRACE, TRACE, SETTLE,
  TRACE, TRACE, TRACE, TRACE, SETTLE,
];
const WEEK2_A = [NEXT, BEGIN, ASK_ASSISTANT, NEXT, ASK_TUTOR, NEXT, ASK_TUTOR, NEXT];
const A = [...WEEK1_A, ...WEEK2_A, NEXT];

const B = [
  START, BEGIN,
  TRACE, TRACE, SETTLE,
  TRACE, TRACE, SETTLE,
  TRACE, SETTLE,
  TRACE, TRACE, SETTLE,
  TRACE, TRACE, TRACE,
];

for (const freeze of [false, true]) {
  const sfx = freeze ? ' (frozen)' : '';
  test(`playthrough A, the careful reader${sfx}`, () => {
    const r1 = play(freeze, ...WEEK1_A);
    assert.equal(r1.screen, 'reveal');
    assert.equal(r1.spent, 48);
    assert.equal(r1.newCards.length, 3);
    assert.deepEqual(engine.tally(engine.weekBeliefs(r1, 'week1')), { PRESERVED: 5 });
    const r2 = play(freeze, ...WEEK1_A, ...WEEK2_A);
    assert.equal(r2.screen, 'reveal');
    assert.equal(r2.spent, 8);
    assert.deepEqual(engine.tally(engine.weekBeliefs(r2, 'week2')), { PRESERVED: 3 });
    const end = play(freeze, ...A);
    assert.equal(end.screen, 'end');
    assert.equal(end.beliefs.length, 8);
    assert.equal(end.cards.length, 6);
  });

  test(`playthrough B, the curious reader${sfx}`, () => {
    const s = play(freeze, ...B);
    assert.equal(s.depth, 3);
    assert.equal(s.spent, 40);
    assert.equal(engine.canTrace(s), false);
    assert.equal(engine.step(s, TRACE), s);
    const done = engine.step(freeze ? deepFreeze(s) : s, SETTLE);
    const forest = done.beliefs[done.beliefs.length - 1];
    assert.equal(forest.lands, 'INVERTED');
    assert.deepEqual(engine.tally(engine.weekBeliefs(done, 'week1')), { PRESERVED: 4, INVERTED: 1 });
  });
}

test('playthrough C, the assistant reader', () => {
  let s = play(false, ...WEEK1_A, NEXT, BEGIN);
  for (let i = 0; i < 3; i++) s = engine.step(engine.step(s, ASK_ASSISTANT), NEXT);
  assert.equal(s.screen, 'reveal');
  assert.equal(s.spent, 0);
  assert.deepEqual(engine.tally(engine.weekBeliefs(s, 'week2')), { PRESERVED: 1, INVERTED: 2 });
});

test('edge cases', () => {
  const w1 = play(false, START, BEGIN);
  const traced = engine.step(w1, TRACE);
  assert.equal(engine.step(traced, SHRUG), traced);
  assert.equal(engine.step(w1, ASK_ASSISTANT), w1);
  assert.equal(engine.step(w1, ASK_TUTOR), w1);
  const w2 = play(false, ...WEEK1_A, NEXT, BEGIN);
  assert.equal(engine.step(engine.step(w2, TRACE), ASK_TUTOR).answer, null);
  const t = engine.step(w2, TRACE);
  assert.equal(engine.step(t, ASK_TUTOR), t);
  const sh = engine.step(w1, SHRUG);
  const b = sh.beliefs[0];
  assert.equal(b.route, 'shrug');
  assert.equal(b.depth, 0);
  assert.equal(b.minutes, 0);
  assert.equal(b.lands, 'BOUNCED');
  const r = engine.step(play(false, ...A), { type: 'REPLAY' });
  assert.equal(r.screen, 'brief');
  assert.equal(r.weekIndex, 0);
  assert.deepEqual(r.beliefs, []);
  assert.deepEqual(r.cards, []);
});
