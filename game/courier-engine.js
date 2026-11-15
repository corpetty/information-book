import { ROUNDS, CARDS } from './courier-data.js';

export function getRound(id) {
  return ROUNDS.find((r) => r.id === id);
}

export function cost(round, keptIds) {
  return round.chips.reduce(
    (sum, c) => (keptIds.includes(c.id) ? sum + c.cost : sum),
    round.claimCost,
  );
}

export function fits(round, keptIds, budget) {
  return cost(round, keptIds) <= budget;
}

export function getOption(round, hopIndex, optionId) {
  const hop = round.hops[hopIndex];
  const option = hop && hop.options.find((o) => o.id === optionId);
  if (!option) throw new Error('no such option');
  return option;
}

export function missingShare(round, keptIds) {
  const corrective = round.chips.filter((c) => c.role === 'corrective');
  if (corrective.length === 0) return 0;
  const missing = corrective.filter((c) => !keptIds.includes(c.id));
  return missing.length / corrective.length;
}

export function resolve(round, optionId, keptIds) {
  const option = getOption(round, round.hops.length - 1, optionId);
  if (!fits(round, keptIds, option.budget)) throw new Error('over budget');
  const share = missingShare(round, keptIds);
  const groups = [];
  for (const type of ['A', 'B', 'C']) {
    const count = Math.round((option.reach * (option.mix[type] || 0)) / 100);
    if (count === 0) continue;
    const rule = option.landing[type];
    if (rule.rule === 'fixed') {
      groups.push({ reader: type, count, stamp: rule.stamp, text: rule.text });
    } else {
      const fail = Math.round(count * share);
      const pass = count - fail;
      if (pass > 0) groups.push({ reader: type, count: pass, stamp: rule.pass.stamp, text: rule.pass.text });
      if (fail > 0) groups.push({ reader: type, count: fail, stamp: rule.fail.stamp, text: rule.fail.text });
    }
  }
  const tallies = {};
  for (const g of groups) tallies[g.stamp] = (tallies[g.stamp] || 0) + g.count;
  let majority = null;
  for (const stamp of round.stamps) {
    if (tallies[stamp] === undefined) continue;
    if (majority === null || tallies[stamp] > tallies[majority]) majority = stamp;
  }
  return { optionId, reach: option.reach, groups, tallies, majority };
}

export function resultLine(round, outcome) {
  const { ifStamp, then, else: other } = round.result;
  const hit = ifStamp && outcome.tallies[ifStamp] > 0;
  const n = ifStamp ? outcome.tallies[ifStamp] || 0 : 0;
  return (hit ? then : other)
    .replace('{n}', n.toLocaleString('en-US'))
    .replace('{reach}', outcome.reach.toLocaleString('en-US'));
}

export function cardsFor(roundId) {
  return CARDS.filter((c) => c.round === roundId);
}

export function initialState() {
  return {
    screen: 'intro',
    roundIndex: 0,
    hopIndex: 0,
    entryKept: [],
    kept: [],
    optionId: null,
    prediction: null,
    lens: false,
    cards: [],
    newCards: [],
    current: null,
    outcome: null,
    ledger: [],
    replay: false,
  };
}

function enterHop(state, hopIndex, alive) {
  const round = ROUNDS[state.roundIndex];
  const options = round.hops[hopIndex].options;
  const next = { ...state, hopIndex, entryKept: alive, kept: alive };
  if (options.length === 1) {
    next.optionId = options[0].id;
    next.screen = 'hop';
  } else {
    next.optionId = null;
    next.screen = 'choose';
  }
  return next;
}

function finish(state) {
  const round = ROUNDS[state.roundIndex];
  const outcome = resolve(round, state.optionId, state.kept);
  const entry = {
    roundId: round.id,
    hops: state.current.hops,
    optionId: state.optionId,
    outcome,
    prediction: state.prediction,
    replay: state.replay,
  };
  const newCards = cardsFor(round.id)
    .map((c) => c.id)
    .filter((id) => !state.cards.includes(id));
  return {
    ...state,
    outcome,
    ledger: [...state.ledger, entry],
    newCards,
    cards: [...state.cards, ...newCards],
    lens: round.id === 'r2' ? true : state.lens,
    screen: 'result',
  };
}

export function step(state, action) {
  const round = ROUNDS[state.roundIndex];
  switch (state.screen) {
    case 'intro':
      if (action.type === 'START') return { ...state, screen: 'brief', roundIndex: 0 };
      return state;
    case 'brief':
      if (action.type === 'BEGIN_ROUND') {
        const base = {
          ...state,
          current: { roundId: round.id, hops: [] },
          prediction: null,
          outcome: null,
          newCards: [],
        };
        return enterHop(base, 0, round.chips.map((c) => c.id));
      }
      return state;
    case 'choose':
      if (action.type === 'CHOOSE_OPTION') {
        const ok = round.hops[state.hopIndex].options.some((o) => o.id === action.id);
        if (!ok) return state;
        return { ...state, optionId: action.id, kept: state.entryKept, screen: 'hop' };
      }
      return state;
    case 'hop': {
      if (action.type === 'TOGGLE_CHIP') {
        if (!state.entryKept.includes(action.id)) return state;
        const set = new Set(state.kept);
        if (set.has(action.id)) set.delete(action.id);
        else set.add(action.id);
        const kept = round.chips.map((c) => c.id).filter((id) => set.has(id));
        return { ...state, kept };
      }
      if (action.type === 'BACK') {
        if (round.hops[state.hopIndex].options.length <= 1) return state;
        return { ...state, optionId: null, kept: state.entryKept, screen: 'choose' };
      }
      if (action.type === 'HAND_ON') {
        const option = getOption(round, state.hopIndex, state.optionId);
        if (!fits(round, state.kept, option.budget)) return state;
        const cut = state.entryKept.filter((id) => !state.kept.includes(id));
        const current = {
          ...state.current,
          hops: [...state.current.hops, { to: option.to, optionId: state.optionId, kept: state.kept, cut }],
        };
        const next = { ...state, current };
        if (state.hopIndex < round.hops.length - 1) {
          return enterHop(next, state.hopIndex + 1, state.kept);
        }
        if (round.predict) return { ...next, screen: 'predict' };
        return finish(next);
      }
      return state;
    }
    case 'predict':
      if (action.type === 'PREDICT' && round.stamps.includes(action.stamp)) {
        return finish({ ...state, prediction: action.stamp });
      }
      return state;
    case 'result':
      if (action.type === 'NEXT') {
        if (state.replay || state.roundIndex === ROUNDS.length - 1) return { ...state, screen: 'end' };
        return { ...state, roundIndex: state.roundIndex + 1, screen: 'brief' };
      }
      return state;
    case 'end':
      if (action.type === 'REPLAY_R2') {
        return { ...state, replay: true, roundIndex: ROUNDS.findIndex((r) => r.id === 'r2'), screen: 'brief' };
      }
      return state;
    default:
      return state;
  }
}
