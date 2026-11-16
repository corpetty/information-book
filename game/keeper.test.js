import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { RULES, FUNDING, OUTCOMES, CARDS, QUOTES } from './keeper-data.js';
import * as engine from './keeper-engine.js';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

test('every path', () => {
  let total = 0;
  const counts = {};
  const walk = (fundingId, accepted, g, prev, key) => {
    if (g > RULES.generations) {
      const v = engine.verdict(prev);
      counts[key] ??= {};
      counts[key][v] = (counts[key][v] ?? 0) + 1;
      if (accepted) assert.notEqual(v, 'kept');
      total++;
      return;
    }
    for (let copy = 0; copy <= engine.funds(fundingId, g, accepted); copy++) {
      walk(fundingId, accepted, g + 1, engine.nextGeneration(prev, fundingId, g, accepted, copy), key);
    }
  };
  for (const fundingId of Object.keys(FUNDING)) {
    for (const accepted of [false, true]) {
      walk(fundingId, accepted, 1, engine.current({ ledger: [] }), `${fundingId}:${accepted ? 'accept' : 'decline'}`);
    }
  }
  assert.equal(total, 2100);
  assert.deepEqual(counts, {
    'endowed:decline': { kept: 111, locked: 351, nobooks: 33, lost: 5 },
    'endowed:accept': { locked: 662, lost: 38 },
    'donations:decline': { kept: 36, locked: 279, nobooks: 24, lost: 21 },
    'donations:accept': { locked: 495, lost: 45 },
  });
});

function run(fundingId, accepted, copies) {
  const ledger = [];
  copies.forEach((copy, i) => {
    ledger.push(engine.nextGeneration(engine.current({ ledger }), fundingId, i + 1, accepted, copy));
  });
  return ledger;
}

const row = (r) => [r.copy, r.teach, r.archive, r.readers, r.summary].join('/');

test('playthroughs, direct', () => {
  const cases = [
    ['A', 'endowed', false, [1, 2, 2, 2], ['1/2/85/2/0', '2/2/80/2/0', '2/2/75/2/0', '2/2/70/2/0'], 'kept'],
    ['B', 'endowed', true, [1, 2, 2, 2], ['1/2/85/2/0', '2/2/80/2/0', '2/4/75/0/8', '2/2/70/0/0'], 'locked'],
    ['C', 'donations', false, [5, 4, 3, 2], ['5/0/100/0/0', '4/0/100/0/0', '3/0/100/0/0', '2/0/95/0/0'], 'locked'],
    ['D', 'donations', false, [0, 0, 0, 0], ['0/5/75/4/0', '0/4/50/4/0', '0/3/25/3/0', '0/2/0/2/0'], 'nobooks'],
  ];
  for (const [name, fundingId, accepted, copies, rows, v] of cases) {
    const ledger = run(fundingId, accepted, copies);
    assert.deepEqual(ledger.map(row), rows, `playthrough ${name}`);
    assert.equal(engine.verdict(ledger[3]), v, `playthrough ${name} verdict`);
  }
});

test('data invariants', () => {
  assert.equal(FUNDING.endowed.funds.length, RULES.generations);
  assert.equal(FUNDING.donations.funds.length, RULES.generations);
  assert.deepEqual(Object.keys(OUTCOMES).sort(), ['kept', 'locked', 'lost', 'nobooks']);
  const ids = new Set();
  for (const c of CARDS) {
    assert.ok(!ids.has(c.id), `dup card ${c.id}`);
    ids.add(c.id);
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

const START = { type: 'START' };
const NEXT = { type: 'NEXT' };
const pf = (id) => ({ type: 'PICK_FUNDING', id });
const spend = (copy) => ({ type: 'SPEND', copy });

function playSteps(freeze, fundingId, decision, copies) {
  let s = engine.initialState();
  const go = (x) => { s = engine.step(freeze ? deepFreeze(s) : s, x); };
  go(START);
  go(pf(fundingId));
  let offers = 0;
  let offerAfter = null;
  copies.forEach((copy, i) => {
    if (s.screen === 'offer') {
      offers++;
      offerAfter = s.ledger.length;
      go({ type: decision });
    }
    assert.equal(s.screen, 'gen');
    go(spend(copy));
    assert.equal(s.screen, 'result');
    go(NEXT);
  });
  assert.equal(offers, 1);
  assert.equal(offerAfter, 2);
  return s;
}

for (const freeze of [false, true]) {
  const sfx = freeze ? ' (frozen)' : '';
  test(`playthrough A through step${sfx}`, () => {
    const s = playSteps(freeze, 'endowed', 'DECLINE', [1, 2, 2, 2]);
    assert.equal(s.screen, 'verdict');
    assert.equal(s.newCards.length, 4);
    assert.equal(engine.verdict(s.ledger[3]), 'kept');
    const end = engine.step(freeze ? deepFreeze(s) : s, NEXT);
    assert.equal(end.screen, 'end');
    assert.equal(end.ledger.length, 4);
  });

  test(`playthrough B through step${sfx}`, () => {
    const s = playSteps(freeze, 'endowed', 'ACCEPT', [1, 2, 2, 2]);
    assert.equal(s.screen, 'verdict');
    assert.equal(s.newCards.length, 4);
    assert.equal(engine.verdict(s.ledger[3]), 'locked');
    assert.deepEqual(s.ledger.map(row), ['1/2/85/2/0', '2/2/80/2/0', '2/4/75/0/8', '2/2/70/0/0']);
    const end = engine.step(freeze ? deepFreeze(s) : s, NEXT);
    assert.equal(end.screen, 'end');
    assert.equal(end.ledger.length, 4);
  });
}

test('edge cases', () => {
  const gen = engine.step(engine.step(engine.initialState(), START), pf('endowed'));
  assert.equal(gen.screen, 'gen');
  for (const bad of [4, -1, 1.5, '2', NaN, undefined]) {
    assert.equal(engine.step(gen, spend(bad)), gen);
    assert.throws(() => engine.nextGeneration(engine.current(gen), 'endowed', 1, false, bad), /bad copy/);
  }
  const fund = engine.step(engine.initialState(), START);
  assert.equal(engine.step(fund, pf('nope')), fund);
  assert.equal(engine.step(fund, pf('toString')), fund);
  assert.equal(engine.step(fund, NEXT), fund);
  const done = playSteps(false, 'endowed', 'DECLINE', [1, 2, 2, 2]);
  const r = engine.step(engine.step(done, NEXT), { type: 'REPLAY' });
  assert.equal(r.screen, 'fund');
  assert.deepEqual(r.ledger, []);
  assert.deepEqual(r.cards, []);
});
