import { TOWNS, FRAMINGS, CONNECTIONS, CARDS } from './bridge-data.js';

export function getTown(id) {
  return TOWNS.find((t) => t.id === id);
}

export function offered(town) {
  return ['you', 'host', town.local];
}

export function outcome(town, messengerId, framingId) {
  if (!offered(town).includes(messengerId) || !(framingId in FRAMINGS)) throw new Error('bad pick');
  if (messengerId === town.local) return { ...town.framings[framingId], cause: 'framing' };
  return { ...town.outsiders[messengerId], cause: 'messenger' };
}

export function finalLands(lands, connectionId) {
  const rule = CONNECTIONS[connectionId].rule;
  if (rule === 'flag') return 'FLAG';
  if (rule === 'audit') return lands === 'BOUNCED' ? 'PRESERVED' : lands;
  return lands;
}

export function initialState() {
  return {
    screen: 'intro',
    townIndex: 0,
    messenger: null,
    results: [],
    connection: null,
    cards: [],
    newCards: [],
  };
}

function unlock(state, at) {
  const newCards = CARDS.filter((c) => c.at === at && !state.cards.includes(c.id)).map((c) => c.id);
  return { newCards, cards: [...state.cards, ...newCards] };
}

export function step(state, action) {
  const town = TOWNS[state.townIndex];
  switch (state.screen) {
    case 'intro':
      if (action.type === 'START') return { ...state, screen: 'town', townIndex: 0 };
      return state;
    case 'town':
      if (action.type === 'PICK_MESSENGER' && offered(town).includes(action.id)) {
        return { ...state, messenger: action.id, screen: 'framing' };
      }
      return state;
    case 'framing':
      if (action.type === 'BACK') return { ...state, messenger: null, screen: 'town' };
      if (action.type === 'PICK_FRAMING' && action.id in FRAMINGS) {
        const result = {
          townId: town.id,
          messenger: state.messenger,
          framing: action.id,
          ...outcome(town, state.messenger, action.id),
        };
        return { ...state, results: [...state.results, result], screen: 'reaction' };
      }
      return state;
    case 'reaction':
      if (action.type === 'NEXT') {
        if (state.townIndex + 1 < TOWNS.length) {
          return { ...state, townIndex: state.townIndex + 1, messenger: null, screen: 'town' };
        }
        return { ...state, ...unlock(state, 'towns'), screen: 'connect' };
      }
      return state;
    case 'connect':
      if (action.type === 'PICK_CONNECTION' && action.id in CONNECTIONS) {
        return { ...state, connection: action.id, ...unlock(state, 'epilogue'), screen: 'epilogue' };
      }
      return state;
    case 'epilogue':
      if (action.type === 'NEXT') return { ...state, screen: 'end' };
      return state;
    case 'end':
      if (action.type === 'REPLAY') return { ...initialState(), screen: 'town' };
      return state;
    default:
      return state;
  }
}
