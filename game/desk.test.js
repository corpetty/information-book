import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DAYS, REACH, PICKS, CARDS, QUOTES } from './desk-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './desk-engine.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const TABLE = [
  ['day1', ['d1a', 'd1c', 'd1e'], 4, true, 100000, { PRESERVED: 100000 }],
  ['day2', ['d2a', 'd2c', 'd2e'], 5, false, 140000, { PRESERVED: 140000 }],
  ['day2', ['d2a', 'd2e', 'd2f'], 7, true, 320000, { PRESERVED: 120000, INVERTED: 200000 }],
  ['day3', ['d3a', 'd3c', 'd3e'], 4, false, 100000, { PRESERVED: 100000 }],
  ['day3', ['d3a', 'd3c', 'd3f'], 8, true, 1580000, { PRESERVED: 80000, FLAG: 1500000 }],
  ['day4', ['d4a', 'd4b', 'd4f'], 10, true, 1260000, { PRESERVED: 60000, INVERTED: 1200000 }],
  ['day4', ['d4b', 'd4d', 'd4f'], 13, true, 2700000, { INVERTED: 1200000, FLAG: 1500000 }],
  ['day5', ['d5a', 'd5c', 'd5e'], 4, true, 100000, { PRESERVED: 100000 }],
  ['day5', ['d5b', 'd5d', 'd5f'], 12, true, 2300000, { INVERTED: 1700000, FLAG: 600000 }],
];

for (const [did, picks, att, paid, reach, tallies] of TABLE) {
  test(`outcome ${did} [${picks}]`, () => {
    const o = engine.outcome(engine.getDay(did), picks);
    assert.equal(o.attention, att);
    assert.equal(o.paid, paid);
    assert.equal(o.reach, reach);
    assert.deepEqual(o.tallies, tallies);
  });
}

test('outcome rejects bad picks', () => {
  const d1 = engine.getDay('day1');
  assert.throws(() => engine.outcome(d1, ['d1a', 'd1c']), /bad picks/);
  assert.throws(() => engine.outcome(d1, ['d1a', 'd1c', 'd2a']), /bad picks/);
  assert.throws(() => engine.outcome(d1, ['d1a', 'd1a', 'd1c']), /bad picks/);
});

test('rivalPicks', () => {
  assert.deepEqual(engine.rivalPicks(engine.getDay('day5')), ['d5b', 'd5d', 'd5f']);
  assert.deepEqual(engine.rivalPicks(engine.getDay('day1')), ['d1b', 'd1d', 'd1f']);
});

function triples(day) {
  const ids = day.items.map((i) => i.id);
  const out = [];
  for (let a = 0; a < ids.length; a++)
    for (let b = a + 1; b < ids.length; b++)
      for (let c = b + 1; c < ids.length; c++) out.push([ids[a], ids[b], ids[c]]);
  return out;
}

const nonPreserved = (day, ids) =>
  day.items.filter((i) => ids.includes(i.id) && i.lands !== 'PRESERVED').length;

test('the squeeze', () => {
  const paying = (day) => triples(day).filter((t) => engine.outcome(day, t).paid);
  const d = (n) => engine.getDay(`day${n}`);
  assert.ok(paying(d(1)).some((t) => nonPreserved(d(1), t) === 0), 'day1 careful pays');
  for (const n of [2, 3]) {
    assert.ok(!paying(d(n)).some((t) => nonPreserved(d(n), t) === 0), `day${n} careful cannot pay`);
    assert.ok(paying(d(n)).some((t) => nonPreserved(d(n), t) === 1), `day${n} one hot story pays`);
  }
  assert.ok(!paying(d(4)).some((t) => nonPreserved(d(4), t) < 2), 'day4 needs two');
});

test('outcome is internally consistent for every set', () => {
  for (const day of DAYS) {
    for (const t of triples(day)) {
      const o = engine.outcome(day, t);
      assert.equal(o.reach, Object.values(o.tallies).reduce((a, b) => a + b, 0));
      assert.equal(o.paid, o.attention >= day.rent);
      assert.equal(o.attention, engine.attention(day, t));
    }
  }
});

test('data invariants', () => {
  const seen = new Set();
  for (const day of DAYS) {
    assert.equal(day.items.length, 6, `${day.id} items`);
    for (const i of day.items) {
      assert.ok(!seen.has(i.id), `dup item ${i.id}`);
      seen.add(i.id);
      assert.ok(i.heat in REACH, `${i.id} heat`);
      assert.ok(i.lands in STAMPS, `${i.id} lands`);
    }
  }
  const cardIds = new Set();
  for (const c of CARDS) {
    assert.ok(!cardIds.has(c.id), `dup card ${c.id}`);
    cardIds.add(c.id);
    assert.ok(c.at === 'audit' || c.at === 'final', `card ${c.id} at`);
  }
  const endowed = DAYS.filter((d) => d.endowed);
  assert.equal(endowed.length, 1);
  assert.equal(endowed[0].id, 'day5');
  assert.equal(endowed[0].rent, 0);
  assert.equal(PICKS, 3);
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

const T = (id) => ({ type: 'TOGGLE', id });
const WIRE = { type: 'SEE_WIRE' };
const RUN = { type: 'RUN' };
const NEXT = { type: 'NEXT' };

function play(freeze, ...actions) {
  let s = engine.initialState();
  const states = [];
  for (const a of actions) {
    s = engine.step(freeze ? deepFreeze(s) : s, a);
    states.push(s);
  }
  return { s, states };
}

const dayRun = (ids) => [WIRE, ...ids.map(T), RUN];

const A = [
  { type: 'START' },
  ...dayRun(['d1a', 'd1c', 'd1e']), NEXT,
  ...dayRun(['d2a', 'd2c', 'd2e']), NEXT,
  ...dayRun(['d3a', 'd3c', 'd3e']), NEXT, // -> audit
  NEXT,
  ...dayRun(['d5a', 'd5c', 'd5e']), NEXT,
];

const B = [
  { type: 'START' },
  ...dayRun(['d1a', 'd1c', 'd1e']), NEXT,
  ...dayRun(['d2a', 'd2e', 'd2f']), NEXT,
  ...dayRun(['d3a', 'd3c', 'd3f']), NEXT,
  ...dayRun(['d4a', 'd4b', 'd4f']), NEXT, // -> audit
  NEXT,
  ...dayRun(['d5a', 'd5c', 'd5e']), NEXT,
];

for (const freeze of [false, true]) {
  test(`playthrough A, the careful desk${freeze ? ' (frozen)' : ''}`, () => {
    // up to the third RUN
    const idx3 = 17; // index of the third RUN
    const mid = play(freeze, ...A.slice(0, idx3 + 1));
    assert.equal(mid.s.screen, 'day');
    assert.equal(mid.s.strikes, 2);
    assert.equal(mid.s.closedOn, 3);
    const aud = play(freeze, ...A.slice(0, idx3 + 2));
    assert.equal(aud.s.screen, 'audit');
    assert.equal(aud.s.newCards.length, 4);
    assert.deepEqual(engine.audit(aud.s), {
      survived: false,
      closedOn: 3,
      entries: aud.s.ledger,
      totals: { PRESERVED: 340000 },
    });
    assert.equal(aud.s.ledger.length, 3);
    const br = play(freeze, ...A.slice(0, idx3 + 3));
    assert.equal(br.s.dayIndex, 4);
    assert.equal(br.s.screen, 'brief');
    const end = play(freeze, ...A);
    assert.equal(end.s.screen, 'end');
    assert.equal(end.s.ledger.length, 4);
    assert.equal(end.s.cards.length, 6);
  });

  test(`playthrough B, the desk that pays${freeze ? ' (frozen)' : ''}`, () => {
    const auditAt = 1 + 4 * 6; // actions up to and including the NEXT after day 4
    const aud = play(freeze, ...B.slice(0, auditAt));
    assert.equal(aud.s.screen, 'audit');
    assert.equal(aud.s.strikes, 0);
    assert.equal(aud.s.closedOn, null);
    const a = engine.audit(aud.s);
    assert.equal(a.survived, true);
    assert.deepEqual(a.totals, { PRESERVED: 360000, INVERTED: 1400000, FLAG: 1500000 });
    const end = play(freeze, ...B);
    assert.equal(end.s.screen, 'end');
    assert.equal(end.s.ledger.length, 5);
    assert.deepEqual(engine.audit(end.s).totals, a.totals);
  });
}

test('edge cases on the pick screen', () => {
  const { s } = play(false, { type: 'START' }, WIRE, T('d1a'), T('d1c'), T('d1e'));
  assert.deepEqual(s.picked, ['d1a', 'd1c', 'd1e']);
  assert.deepEqual(engine.step(s, T('d1b')).picked, s.picked);
  assert.deepEqual(engine.step(s, T('d1c')).picked, ['d1a', 'd1e']);
  assert.deepEqual(engine.step(s, T('zzz')).picked, s.picked);
  const two = play(false, { type: 'START' }, WIRE, T('d1c'), T('d1a')).s;
  assert.deepEqual(two.picked, ['d1a', 'd1c']);
  assert.equal(engine.step(two, RUN), two);
  assert.equal(engine.step(two, { type: 'NOPE' }), two);
});

test('REPLAY restarts at the first brief', () => {
  const end = play(false, ...A).s;
  const r = engine.step(end, { type: 'REPLAY' });
  assert.equal(r.screen, 'brief');
  assert.equal(r.dayIndex, 0);
  assert.deepEqual(r.ledger, []);
  assert.deepEqual(r.cards, []);
  assert.equal(r.strikes, 0);
  assert.equal(r.closedOn, null);
});
