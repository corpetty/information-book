import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { MESSENGERS, FRAMINGS, TOWNS, CONNECTIONS, CARDS, QUOTES } from './bridge-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './bridge-engine.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const [LOW, RIDGE] = TOWNS;

test('outcome table', () => {
  const want = {
    lowmill: { safe: 'FLAG', risk: 'INVERTED', gauges: 'PRESERVED' },
    ridgeton: { safe: 'INVERTED', risk: 'FLAG', gauges: 'PRESERVED' },
  };
  for (const t of TOWNS) {
    for (const f of Object.keys(FRAMINGS)) {
      assert.equal(engine.outcome(t, t.local, f).lands, want[t.id][f]);
      assert.equal(engine.outcome(t, t.local, f).cause, 'framing');
      for (const m of ['you', 'host']) {
        assert.equal(engine.outcome(t, m, f).lands, 'BOUNCED');
        assert.equal(engine.outcome(t, m, f).cause, 'messenger');
      }
    }
  }
  assert.throws(() => engine.outcome(LOW, 'sam', 'gauges'), /bad pick/);
  assert.throws(() => engine.outcome(LOW, 'ana', 'nope'), /bad pick/);
});

test('finalLands', () => {
  for (const s of Object.keys(STAMPS)) {
    assert.equal(engine.finalLands(s, 'forum'), 'FLAG');
    assert.equal(engine.finalLands(s, 'apart'), s);
    assert.equal(engine.finalLands(s, 'panel'), s === 'BOUNCED' ? 'PRESERVED' : s);
  }
});

test('every path', () => {
  let total = 0;
  const good = { forum: 0, apart: 0, panel: 0 };
  for (const m1 of engine.offered(LOW)) for (const f1 of Object.keys(FRAMINGS))
    for (const m2 of engine.offered(RIDGE)) for (const f2 of Object.keys(FRAMINGS))
      for (const c of Object.keys(CONNECTIONS)) {
        total++;
        const a = engine.finalLands(engine.outcome(LOW, m1, f1).lands, c);
        const b = engine.finalLands(engine.outcome(RIDGE, m2, f2).lands, c);
        if (a === 'PRESERVED' && b === 'PRESERVED') good[c]++;
      }
  assert.equal(total, 243);
  assert.deepEqual(good, { forum: 0, apart: 1, panel: 49 });
  assert.equal(good.forum + good.apart + good.panel, 50);
});

test('data invariants', () => {
  assert.equal(TOWNS.length, 2);
  for (const t of TOWNS) {
    assert.ok(t.local in MESSENGERS);
    assert.deepEqual(Object.keys(t.outsiders).sort(), ['host', 'you']);
    const all = [...Object.values(t.outsiders), ...Object.values(t.framings)];
    for (const o of all) assert.ok(o.lands in STAMPS, `${t.id} lands ${o.lands}`);
  }
  const ids = new Set();
  for (const c of CARDS) {
    assert.ok(!ids.has(c.id), `dup card ${c.id}`);
    ids.add(c.id);
    assert.ok(['towns', 'epilogue'].includes(c.at), `card ${c.id} at`);
  }
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

const pm = (id) => ({ type: 'PICK_MESSENGER', id });
const pf = (id) => ({ type: 'PICK_FRAMING', id });
const pc = (id) => ({ type: 'PICK_CONNECTION', id });
const START = { type: 'START' };
const NEXT = { type: 'NEXT' };
const BACK = { type: 'BACK' };

function play(freeze, ...actions) {
  let s = engine.initialState();
  for (const x of actions) s = engine.step(freeze ? deepFreeze(s) : s, x);
  return s;
}

for (const freeze of [false, true]) {
  const sfx = freeze ? ' (frozen)' : '';
  test(`playthrough A, the bridge${sfx}`, () => {
    const mid = play(freeze, START, pm('ana'), pf('gauges'), NEXT, pm('sam'), pf('gauges'), NEXT);
    assert.equal(mid.screen, 'connect');
    assert.equal(mid.newCards.length, 2);
    const ep = engine.step(freeze ? deepFreeze(mid) : mid, pc('panel'));
    assert.equal(ep.newCards.length, 3);
    const end = engine.step(freeze ? deepFreeze(ep) : ep, NEXT);
    assert.equal(end.screen, 'end');
    assert.equal(end.cards.length, 5);
    assert.deepEqual(end.results.map((r) => r.lands), ['PRESERVED', 'PRESERVED']);
  });

  test(`playthrough B, the expert${sfx}`, () => {
    const ep = play(freeze, START, pm('you'), pf('gauges'), NEXT, pm('you'), pf('gauges'), NEXT, pc('forum'));
    assert.deepEqual(ep.results.map((r) => r.lands), ['BOUNCED', 'BOUNCED']);
    assert.deepEqual(ep.results.map((r) => engine.finalLands(r.lands, ep.connection)), ['FLAG', 'FLAG']);
  });
}

test('edge cases', () => {
  const fr = play(false, START, pm('ana'));
  assert.equal(fr.screen, 'framing');
  const back = engine.step(fr, BACK);
  assert.equal(back.screen, 'town');
  assert.equal(back.messenger, null);
  assert.deepEqual(back.results, []);
  const town = play(false, START);
  assert.equal(engine.step(town, pm('sam')), town);
  assert.equal(engine.step(town, NEXT), town);
  const end = play(false, START, pm('ana'), pf('gauges'), NEXT, pm('sam'), pf('gauges'), NEXT, pc('panel'), NEXT);
  const r = engine.step(end, { type: 'REPLAY' });
  assert.equal(r.screen, 'town');
  assert.deepEqual(r.results, []);
  assert.deepEqual(r.cards, []);
});
