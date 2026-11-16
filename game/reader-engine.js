import { WEEKS, HOP_COST, TUTOR_COST, CARDS } from './reader-data.js';

export function getWeek(id) {
  return WEEKS.find((w) => w.id === id);
}

export function costToDepth(d) {
  return HOP_COST.slice(0, d).reduce((a, b) => a + b, 0);
}

export function formAt(claim, depth) {
  return depth === 0 ? claim.meme : claim.hops[depth - 1];
}

export function canTrace(state) {
  if (state.screen !== 'claim') return false;
  const week = WEEKS[state.weekIndex];
  return state.depth < 4 && state.spent + HOP_COST[state.depth] <= week.minutes;
}

export function canTutor(state) {
  if (state.screen !== 'claim') return false;
  const week = WEEKS[state.weekIndex];
  return week.tools && state.depth === 0 && state.spent + TUTOR_COST <= week.minutes;
}

export function weekBeliefs(state, weekId) {
  return state.beliefs.filter((b) => b.weekId === weekId);
}

export function tally(beliefs) {
  const out = {};
  for (const b of beliefs) out[b.lands] = (out[b.lands] || 0) + 1;
  return out;
}

export function defaultBeliefs(week, mode) {
  return week.claims.map((c) => ({
    claimId: c.id,
    lands: mode === 'accept' ? c.meme.lands : mode === 'shrug' ? 'BOUNCED' : c.assistant.lands,
  }));
}

export function initialState() {
  return {
    screen: 'intro',
    weekIndex: 0,
    claimIndex: 0,
    depth: 0,
    spent: 0,
    beliefs: [],
    answer: null,
    cards: [],
    newCards: [],
  };
}

function record(state, week, claim, belief) {
  return [...state.beliefs, { weekId: week.id, claimId: claim.id, ...belief }];
}

function advance(state, beliefs, spent) {
  const week = WEEKS[state.weekIndex];
  if (state.claimIndex + 1 < week.claims.length) {
    return { ...state, beliefs, spent, answer: null, claimIndex: state.claimIndex + 1, depth: 0, screen: 'claim' };
  }
  const newCards = CARDS.filter((c) => c.week === week.id && !state.cards.includes(c.id)).map((c) => c.id);
  return {
    ...state,
    beliefs,
    spent,
    answer: null,
    newCards,
    cards: [...state.cards, ...newCards],
    screen: 'reveal',
  };
}

export function step(state, action) {
  const week = WEEKS[state.weekIndex];
  const claim = week && week.claims[state.claimIndex];
  switch (state.screen) {
    case 'intro':
      if (action.type === 'START') return { ...state, screen: 'brief', weekIndex: 0 };
      return state;
    case 'brief':
      if (action.type === 'BEGIN') {
        return { ...state, screen: 'claim', claimIndex: 0, depth: 0, spent: 0, newCards: [] };
      }
      return state;
    case 'claim':
      switch (action.type) {
        case 'TRACE':
          if (!canTrace(state)) return state;
          return { ...state, spent: state.spent + HOP_COST[state.depth], depth: state.depth + 1 };
        case 'SETTLE': {
          const beliefs = record(state, week, claim, {
            route: state.depth === 0 ? 'accept' : 'trace',
            depth: state.depth,
            minutes: costToDepth(state.depth),
            lands: formAt(claim, state.depth).lands,
          });
          return advance(state, beliefs, state.spent);
        }
        case 'SHRUG': {
          if (state.depth !== 0) return state;
          const beliefs = record(state, week, claim, { route: 'shrug', depth: 0, minutes: 0, lands: 'BOUNCED' });
          return advance(state, beliefs, state.spent);
        }
        case 'ASK_ASSISTANT': {
          if (!week.tools || state.depth !== 0) return state;
          const beliefs = record(state, week, claim, {
            route: 'assistant', depth: 0, minutes: 0, lands: claim.assistant.lands,
          });
          return { ...state, beliefs, answer: 'assistant', screen: 'answer' };
        }
        case 'ASK_TUTOR': {
          if (!canTutor(state)) return state;
          const beliefs = record(state, week, claim, {
            route: 'tutor', depth: 0, minutes: TUTOR_COST, lands: claim.hops[3].lands,
          });
          return { ...state, spent: state.spent + TUTOR_COST, beliefs, answer: 'tutor', screen: 'answer' };
        }
        default:
          return state;
      }
    case 'answer':
      if (action.type === 'NEXT') return advance(state, state.beliefs, state.spent);
      return state;
    case 'reveal':
      if (action.type === 'NEXT') {
        if (state.weekIndex === WEEKS.length - 1) return { ...state, screen: 'end' };
        return { ...state, weekIndex: state.weekIndex + 1, screen: 'brief' };
      }
      return state;
    case 'end':
      if (action.type === 'REPLAY') return { ...initialState(), screen: 'brief' };
      return state;
    default:
      return state;
  }
}
