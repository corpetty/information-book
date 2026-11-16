import { DAYS, REACH, CARDS, PICKS, STRIKES_TO_CLOSE } from './desk-data.js';

export function getDay(id) {
  return DAYS.find((d) => d.id === id);
}

export function attention(day, ids) {
  return day.items.reduce((sum, i) => (ids.includes(i.id) ? sum + i.heat : sum), 0);
}

export function outcome(day, ids) {
  const distinct = new Set(ids);
  if (
    !Array.isArray(ids) ||
    ids.length !== PICKS ||
    distinct.size !== PICKS ||
    !ids.every((id) => day.items.some((i) => i.id === id))
  ) {
    throw new Error('bad picks');
  }
  const items = day.items.filter((i) => ids.includes(i.id));
  const att = items.reduce((sum, i) => sum + i.heat, 0);
  const tallies = {};
  for (const i of items) tallies[i.lands] = (tallies[i.lands] || 0) + REACH[i.heat];
  return {
    dayId: day.id,
    picks: items.map((i) => i.id),
    attention: att,
    rent: day.rent,
    paid: att >= day.rent,
    reach: items.reduce((sum, i) => sum + REACH[i.heat], 0),
    tallies,
  };
}

export function rivalPicks(day) {
  const ranked = day.items
    .map((item, index) => ({ item, index }))
    .sort((a, b) => b.item.heat - a.item.heat || a.index - b.index)
    .slice(0, PICKS)
    .map((r) => r.item.id);
  return day.items.filter((i) => ranked.includes(i.id)).map((i) => i.id);
}

export function totals(outcomes) {
  const sum = {};
  for (const o of outcomes) {
    for (const [stamp, n] of Object.entries(o.tallies)) sum[stamp] = (sum[stamp] || 0) + n;
  }
  return sum;
}

export function audit(state) {
  const entries = state.ledger.filter((e) => !getDay(e.dayId).endowed);
  return {
    survived: state.closedOn === null,
    closedOn: state.closedOn,
    entries,
    totals: totals(entries),
  };
}

export function initialState() {
  return {
    screen: 'intro',
    dayIndex: 0,
    picked: [],
    strikes: 0,
    closedOn: null,
    ledger: [],
    current: null,
    cards: [],
    newCards: [],
  };
}

function unlock(state, at) {
  const newCards = CARDS.filter((c) => c.at === at && !state.cards.includes(c.id)).map((c) => c.id);
  return { ...state, newCards, cards: [...state.cards, ...newCards] };
}

export function step(state, action) {
  const day = DAYS[state.dayIndex];
  switch (state.screen) {
    case 'intro':
      if (action.type === 'START') return { ...state, screen: 'brief', dayIndex: 0 };
      return state;
    case 'brief':
      if (action.type === 'SEE_WIRE') return { ...state, screen: 'pick', picked: [] };
      return state;
    case 'pick':
      if (action.type === 'TOGGLE') {
        if (!day.items.some((i) => i.id === action.id)) return state;
        let set;
        if (state.picked.includes(action.id)) set = state.picked.filter((id) => id !== action.id);
        else if (state.picked.length < PICKS) set = [...state.picked, action.id];
        else return state;
        return { ...state, picked: day.items.map((i) => i.id).filter((id) => set.includes(id)) };
      }
      if (action.type === 'RUN') {
        if (state.picked.length !== PICKS) return state;
        const out = outcome(day, state.picked);
        if (day.endowed) {
          return unlock(
            { ...state, ledger: [...state.ledger, { ...out, strike: false }], current: out, screen: 'final' },
            'final',
          );
        }
        const strike = !out.paid;
        const strikes = state.strikes + (strike ? 1 : 0);
        return {
          ...state,
          strikes,
          closedOn: strikes >= STRIKES_TO_CLOSE ? state.dayIndex + 1 : state.closedOn,
          ledger: [...state.ledger, { ...out, strike }],
          current: out,
          newCards: [],
          screen: 'day',
        };
      }
      return state;
    case 'day':
      if (action.type === 'NEXT') {
        if (state.closedOn !== null || state.dayIndex === 3) {
          return { ...unlock(state, 'audit'), screen: 'audit' };
        }
        return { ...state, dayIndex: state.dayIndex + 1, screen: 'brief' };
      }
      return state;
    case 'audit':
      if (action.type === 'NEXT') return { ...state, dayIndex: 4, screen: 'brief', newCards: [] };
      return state;
    case 'final':
      if (action.type === 'NEXT') return { ...state, screen: 'end' };
      return state;
    case 'end':
      if (action.type === 'REPLAY') return { ...initialState(), screen: 'brief' };
      return state;
    default:
      return state;
  }
}
