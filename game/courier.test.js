import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { ROUNDS, STAMPS, CARDS, QUOTES } from './courier-data.js';
import * as engine from './courier-engine.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

const TABLE = [
  ['r1', 'table', [], { PRESERVED: 1000000 }, 'PRESERVED'],
  ['r2', 'feed', ['c1'], { PRESERVED: 2200000, INVERTED: 1800000 }, 'PRESERVED'],
  ['r2', 'feed', [], { PRESERVED: 400000, INVERTED: 3600000 }, 'INVERTED'],
  ['r2', 'feed', ['d1'], { PRESERVED: 400000, INVERTED: 3600000 }, 'INVERTED'],
  ['r2', 'longread', ['c1', 'c2', 'd1'], { PRESERVED: 40000 }, 'PRESERVED'],
  ['r2', 'longread', ['c1'], { PRESERVED: 30000, INVERTED: 10000 }, 'PRESERVED'],
  ['r3', 'faithful', ['p1'], { PRESERVED: 22000, BOUNCED: 10000, FLAG: 8000 }, 'PRESERVED'],
  ['r3', 'faithful', [], { PRESERVED: 12000, BOUNCED: 20000, FLAG: 8000 }, 'BOUNCED'],
  ['r3', 'punchy', [], { PRESERVED: 200000, INVERTED: 1000000, FLAG: 800000 }, 'INVERTED'],
  ['r3', 'upbeat', [], { PRESERVED: 600000, INVERTED: 4800000, FLAG: 600000 }, 'INVERTED'],
];

for (const [rid, opt, kept, tallies, majority] of TABLE) {
  test(`resolve ${rid} ${opt} [${kept}]`, () => {
    const out = engine.resolve(engine.getRound(rid), opt, kept);
    assert.deepEqual(out.tallies, tallies);
    assert.equal(out.majority, majority);
  });
}

test('resolve throws when over budget', () => {
  assert.throws(() => engine.resolve(engine.getRound('r2'), 'feed', ['c1', 'c2']));
});

test('resultLine r2 feed []', () => {
  const r = engine.getRound('r2');
  assert.equal(
    engine.resultLine(r, engine.resolve(r, 'feed', [])),
    'About 3,600,000 people now believe Compound X will hurt them. Every word you handed on was true.',
  );
});

test('resultLine r2 longread full key', () => {
  const r = engine.getRound('r2');
  assert.equal(
    engine.resultLine(r, engine.resolve(r, 'longread', ['c1', 'c2', 'd1'])),
    'Everyone you reached got the key. You reached 40,000 people.',
  );
});

test('data invariants', () => {
  const cardIds = new Set();
  for (const round of ROUNDS) {
    for (const hop of round.hops) {
      for (const o of hop.options) assert.ok(o.budget >= round.claimCost, `${round.id}/${o.id} budget`);
    }
    const chipIds = round.chips.map((c) => c.id);
    assert.equal(new Set(chipIds).size, chipIds.length, `${round.id} chip ids`);
    const last = round.hops[round.hops.length - 1];
    for (const o of last.options) {
      const sum = Object.values(o.mix).reduce((a, b) => a + b, 0);
      assert.equal(sum, 100, `${round.id}/${o.id} mix`);
      for (const [type, pct] of Object.entries(o.mix)) {
        if (pct > 0) assert.ok(o.landing[type], `${round.id}/${o.id} landing ${type}`);
      }
      for (const rule of Object.values(o.landing)) {
        const stamps = rule.rule === 'fixed' ? [rule.stamp] : [rule.pass.stamp, rule.fail.stamp];
        for (const s of stamps) {
          assert.ok(round.stamps.includes(s), `${round.id} stamp ${s} in round`);
          assert.ok(STAMPS[s], `stamp ${s} in STAMPS`);
        }
      }
    }
    assert.ok(round.quote in QUOTES, `${round.id} quote`);
  }
  for (const c of CARDS) {
    assert.ok(!cardIds.has(c.id), `dup card ${c.id}`);
    cardIds.add(c.id);
  }
  const r2 = engine.getRound('r2');
  const feed = engine.getOption(r2, 2, 'feed');
  const others = r2.chips.map((c) => c.id).filter((id) => id !== 'c1' && id !== 'c2');
  for (let m = 0; m < 1 << others.length; m++) {
    const kept = ['c1', 'c2', ...others.filter((_, i) => m & (1 << i))];
    assert.ok(!engine.fits(r2, kept, feed.budget));
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

test('resolve is exhaustive-safe for every fitting subset', () => {
  for (const round of ROUNDS) {
    const ids = round.chips.map((c) => c.id);
    const last = round.hops[round.hops.length - 1];
    for (const option of last.options) {
      for (let m = 0; m < 1 << ids.length; m++) {
        const kept = ids.filter((_, i) => m & (1 << i));
        if (!engine.fits(round, kept, option.budget)) continue;
        const out = engine.resolve(round, option.id, kept);
        const total = out.groups.reduce((a, g) => a + g.count, 0);
        assert.equal(total, option.reach, `${round.id}/${option.id} [${kept}] sums to reach`);
        assert.ok(round.stamps.includes(out.majority), `${round.id}/${option.id} [${kept}] majority`);
      }
    }
  }
});

function deepFreeze(o) {
  if (o && typeof o === 'object' && !Object.isFrozen(o)) {
    Object.freeze(o);
    for (const v of Object.values(o)) deepFreeze(v);
  }
  return o;
}

test('step never mutates its input', () => {
  const run = (s, ...actions) =>
    actions.reduce((st, a) => engine.step(deepFreeze(st), a), s);
  const T = (id) => ({ type: 'TOGGLE_CHIP', id });
  const H = { type: 'HAND_ON' };
  let s = engine.initialState();
  assert.doesNotThrow(() => {
    s = run(s, { type: 'START' }, { type: 'BEGIN_ROUND' }, T('e3'), H, T('e1'), H, T('e4'), H, { type: 'NEXT' });
    s = run(s, { type: 'BEGIN_ROUND' }, H, T('d3'), T('d2'), H, { type: 'CHOOSE_OPTION', id: 'feed' });
    s = run(s, H, T('d3'), T('c2'), T('d1'), { type: 'BACK' }, { type: 'CHOOSE_OPTION', id: 'feed' }, T('c2'), T('d1'), H);
    s = run(s, { type: 'PREDICT', stamp: 'INVERTED' }, { type: 'NEXT' });
    s = run(s, { type: 'BEGIN_ROUND' }, H, T('q1'), T('q2'), H, { type: 'CHOOSE_OPTION', id: 'upbeat' }, T('p1'), T('p2'), H);
    s = run(s, { type: 'PREDICT', stamp: 'INVERTED' }, { type: 'NEXT' });
    s = run(s, { type: 'REPLAY_R2' });
  });
  assert.equal(s.screen, 'brief');
});

test('full playthrough', () => {
  const run = (s, ...actions) => actions.reduce((st, a) => engine.step(st, a), s);
  const T = (id) => ({ type: 'TOGGLE_CHIP', id });
  const H = { type: 'HAND_ON' };
  let s = engine.initialState();
  s = run(s, { type: 'START' }, { type: 'BEGIN_ROUND' });
  assert.equal(s.screen, 'hop');
  s = run(s, T('e3'), H, T('e1'), H, T('e4'), H);
  assert.equal(s.screen, 'result');
  s = run(s, { type: 'NEXT' });
  assert.equal(s.lens, false);
  assert.equal(s.screen, 'brief');

  s = run(s, { type: 'BEGIN_ROUND' }, H);
  s = run(s, T('d3'), T('d2'), H);
  assert.equal(s.screen, 'choose');
  s = run(s, { type: 'CHOOSE_OPTION', id: 'feed' });
  // over budget: HAND_ON is a no-op
  assert.deepEqual(engine.step(s, H), s);
  // chip cut at an earlier hop cannot be toggled
  assert.deepEqual(engine.step(s, T('d3')), s);
  s = run(s, T('c2'), T('d1'), H);
  assert.equal(s.screen, 'predict');
  s = run(s, { type: 'PREDICT', stamp: 'INVERTED' });
  assert.equal(s.screen, 'result');
  s = run(s, { type: 'NEXT' });

  s = run(s, { type: 'BEGIN_ROUND' }, H, T('q1'), T('q2'), H);
  assert.equal(s.screen, 'choose');
  s = run(s, { type: 'CHOOSE_OPTION', id: 'upbeat' }, T('p1'), T('p2'), H);
  assert.equal(s.screen, 'predict');
  s = run(s, { type: 'PREDICT', stamp: 'INVERTED' }, { type: 'NEXT' });

  assert.equal(s.screen, 'end');
  assert.equal(s.ledger.length, 3);
  assert.equal(s.cards.length, 7);
  assert.equal(s.lens, true);
  assert.deepEqual(s.ledger[1].outcome.tallies, { PRESERVED: 2200000, INVERTED: 1800000 });
  assert.equal(s.ledger[1].outcome.majority, 'PRESERVED');
  assert.equal(s.ledger[2].outcome.majority, 'INVERTED');

  const r = engine.step(s, { type: 'REPLAY_R2' });
  assert.equal(r.screen, 'brief');
  assert.equal(r.replay, true);
  assert.equal(ROUNDS[r.roundIndex].id, 'r2');
});
