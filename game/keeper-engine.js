import { RULES, FUNDING, CARDS } from './keeper-data.js';

export function funds(fundingId, g, accepted) {
  const bonus = accepted && g === RULES.offerGeneration ? RULES.offerBonus : 0;
  return FUNDING[fundingId].funds[g - 1] + bonus;
}

export function nextGeneration(prev, fundingId, g, accepted, copy) {
  const total = funds(fundingId, g, accepted);
  if (!Number.isInteger(copy) || copy < 0 || copy > total) throw new Error('bad copy');
  const teach = total - copy;
  const archive = Math.max(0, Math.min(100, prev.archive - RULES.archiveDecay + RULES.copyGain * copy));
  const engineOn = accepted && g === RULES.offerGeneration;
  const readers = engineOn ? 0 : Math.min(teach, RULES.studentsPerReader * prev.readers);
  const summary = engineOn ? RULES.summaryPerPoint * teach : 0;
  return { g, funds: total, copy, teach, archive, readers, summary };
}

export function verdict(last) {
  const a = last.archive >= RULES.keepArchive;
  const r = last.readers >= RULES.keepReaders;
  if (a && r) return 'kept';
  if (a) return 'locked';
  if (r) return 'nobooks';
  return 'lost';
}

export function current(state) {
  if (state.ledger.length === 0) return { archive: RULES.archiveStart, readers: RULES.readersStart };
  return state.ledger[state.ledger.length - 1];
}

export function initialState() {
  return {
    screen: 'intro',
    funding: null,
    g: 1,
    accepted: false,
    ledger: [],
    cards: [],
    newCards: [],
  };
}

export function step(state, action) {
  switch (state.screen) {
    case 'intro':
      if (action.type === 'START') return { ...state, screen: 'fund' };
      return state;
    case 'fund':
      if (action.type === 'PICK_FUNDING' && typeof action.id === 'string' && Object.hasOwn(FUNDING, action.id)) {
        return { ...state, funding: action.id, g: 1, screen: 'gen' };
      }
      return state;
    case 'offer':
      if (action.type === 'ACCEPT') return { ...state, accepted: true, screen: 'gen' };
      if (action.type === 'DECLINE') return { ...state, accepted: false, screen: 'gen' };
      return state;
    case 'gen':
      if (action.type === 'SPEND') {
        const total = funds(state.funding, state.g, state.accepted);
        if (!Number.isInteger(action.copy) || action.copy < 0 || action.copy > total) return state;
        const record = nextGeneration(current(state), state.funding, state.g, state.accepted, action.copy);
        return { ...state, ledger: [...state.ledger, record], screen: 'result' };
      }
      return state;
    case 'result':
      if (action.type === 'NEXT') {
        if (state.g < RULES.generations) {
          const g = state.g + 1;
          return { ...state, g, screen: g === RULES.offerGeneration ? 'offer' : 'gen' };
        }
        const newCards = CARDS.map((c) => c.id).filter((id) => !state.cards.includes(id));
        return { ...state, newCards, cards: [...state.cards, ...newCards], screen: 'verdict' };
      }
      return state;
    case 'verdict':
      if (action.type === 'NEXT') return { ...state, screen: 'end' };
      return state;
    case 'end':
      if (action.type === 'REPLAY') return { ...initialState(), screen: 'fund' };
      return state;
    default:
      return state;
  }
}
