# The Bridge — build plan (part four)

The fourth short browser game for *Lossy*, published at
`lossybook.com/play/bridge.html` and reached from the end of the Reader. The
player holds one finding two towns both need, and the towns don't trust each
other. For each town the player picks a messenger and a framing; then picks
how the towns talk for the next ten years.

Book material: versatile expertise and the curse of expertise (Ch. 9 and the
bridge-node note), polarization via distrust and the Zollman effect ("just
connect them" fails, Ch. 9), and survivable polarization (Ch. 12).

Same rules as `game/PLAN.md`, `game/DESK-PLAN.md` and `game/READER-PLAN.md`:
every piece of text, every outcome and every rule is fixed below; copy them
exactly.

## Rules for the executor

1. Do the phases in order; do not start one until the previous one's checks pass.
2. Copy all game text and outcomes verbatim. Add nothing.
3. No dependencies, no build step, no network requests, no `localStorage`.
4. Touch only the files this plan names. Never edit `data/` or chapter prose.
5. If a check fails and the fix is not obvious, or a quote test fails, **stop and
   report**. Never change a quote or an expected value to make a test pass;
   every expected value was computed by a reference implementation.
6. Do not push, merge, or open a pull request.

## Setup

```bash
git fetch origin
git switch -c bridge-game origin/main
git log --oneline -1
```

Number commits from the last `Phase N:` as `Phase <number>: bridge game — <what>`,
ending each message with a blank line and the `Co-Authored-By:` trailer the
session gives you.

## Files

```
game/
  BRIDGE-PLAN.md    this file (already exists)
  bridge-data.js    Phase 1
  bridge-engine.js  Phase 1  pure logic and state machine, no DOM
  bridge.test.js    Phase 1
  bridge.html       Phase 2
  bridge-ui.js      Phase 2
  courier.css       Phase 2  append a Bridge section
```

## The model

- Two **towns**, played in order. Each town is offered three messengers:
  `you`, `host` and the town's `local` (`ana` for Lowmill, `sam` for Ridgeton).
- After picking a messenger the player picks one of three **framings**
  (`safe`, `risk`, `gauges`).
- **outcome(town, messenger, framing)**: if the messenger is the town's
  `local`, the result is `town.framings[framing]`; otherwise it is
  `town.outsiders[messenger]` (the framing doesn't matter: an outsider is
  discounted at the door). Each result has `lands` and `text`.
- Then the player picks one **connection** (`forum`, `apart`, `panel`). Each
  town's **final** stamp is: `forum` (rule `flag`) → `FLAG`; `apart` (rule
  `keep`) → unchanged; `panel` (rule `audit`) → `PRESERVED` if the town's
  stamp was `BOUNCED`, otherwise unchanged.

---

## Phase 1 — data, engine, tests

### 1a. `game/bridge-data.js`

Create the file with exactly this content.

```js
// The Bridge — all game content. Text and outcomes are fixed by game/BRIDGE-PLAN.md.
// The towns, people and ten-year outcomes are invented to show the book's argument.

export const FINDING = 'Today the river’s Compound X is far below any dose that harmed mice. If the works upstream doubles its output, as it plans to, the level could climb into the range worth watching within about ten years.';

export const MESSENGERS = {
  you: { name: 'You', about: 'A toxicologist from the university in the city, with your field’s slides.' },
  host: { name: 'Jules', about: 'Hosts a popular science channel. Clear, friendly, and famous.' },
  ana: { name: 'Ana', about: 'A river ecologist who grew up fishing in Lowmill and still lives there.' },
  sam: { name: 'Sam', about: 'A chemist on the works floor in Ridgeton who trained in toxicology.' },
};

export const FRAMINGS = {
  safe: { label: 'Lead with the reassurance', text: 'Today’s river is safe.' },
  risk: { label: 'Lead with the warning', text: 'The river could be in trouble within ten years.' },
  gauges: { label: 'Bring the readings', text: 'Here are the readings, taken where you live. Today’s are far below any harmful dose. Here is the line they would cross if the works doubles output, and here is how you can check it yourselves every month.' },
};

export const TOWNS = [
  {
    id: 'lowmill', name: 'Lowmill', local: 'ana',
    about: 'A fishing town downstream of the works.',
    heard: [
      '“The works has told us everything’s fine before.”',
      '“My father fished this river for forty years.”',
      '“We listen to people who’ve stood in this river.”',
    ],
    outsiders: {
      you: { lands: 'BOUNCED', text: 'Polite applause for the university slides, then the first question: “Who paid for this study?” Nobody’s mind changed.' },
      host: { lands: 'BOUNCED', text: '“Seen Jules on my phone. Didn’t know Jules fished.” They watched, and went home.' },
    },
    framings: {
      safe: { lands: 'FLAG', text: '“Safe. That’s what the works always says.” As far as the hall is concerned, Ana is on the works’ side now.' },
      risk: { lands: 'INVERTED', text: '“Ten years? It’s poisoning us now.” By the weekend people are buying bottled water and the fish market is empty.' },
      gauges: { lands: 'PRESERVED', text: 'Ana spreads the readings on a table and people find their own fishing spots on the map. “So we’re fine now, and we watch it.”' },
    },
  },
  {
    id: 'ridgeton', name: 'Ridgeton', local: 'sam',
    about: 'The town that works the plant upstream.',
    heard: [
      '“Every few years someone from the city tries to shut us down.”',
      '“Half this town works the line.”',
      '“Show me numbers from someone who’s been on the floor.”',
    ],
    outsiders: {
      you: { lands: 'BOUNCED', text: '“Another expert from the city.” The questions are all about jobs, and your charts go unread.' },
      host: { lands: 'BOUNCED', text: '“Jules makes videos.” The shift crowd is polite and unmoved.' },
    },
    framings: {
      safe: { lands: 'INVERTED', text: '“Told you it was nothing.” The planned expansion is now proof that the river can take anything.' },
      risk: { lands: 'FLAG', text: '“So Sam’s come to shut the works.” Sam is an outsider now, and the river is an argument about jobs.' },
      gauges: { lands: 'PRESERVED', text: 'Sam pins the readings by the time clock, next to the line they would cross. “Fine now. Let’s keep it fine when we expand.”' },
    },
  },
];

export const CONNECTIONS = {
  forum: {
    label: 'One shared online forum for both towns', about: 'Everyone in, all the time.', rule: 'flag',
    epilogue: 'The first confident post set the tone, and every post after it was read by which town it came from. Within a year the forum was two camps, and the river was a flag.',
  },
  apart: {
    label: 'Keep the towns apart', about: 'Each town gets its own yearly briefing.', rule: 'keep',
    epilogue: 'Each town kept what it had heard, and heard every later reading from its own side. Nothing got worse between them. Nothing got better.',
  },
  panel: {
    label: 'A joint river panel', about: 'Two people from each town read the gauges together every month and publish the readings.', rule: 'audit',
    epilogue: 'Nobody had to trust the other town, or you. Anyone could check the gauges. When the readings began to climb, both towns saw the same numbers in the same month.',
  },
};

export const CARDS = [
  { id: 'versatile-expertise', at: 'towns', title: 'The bridge', href: '../concepts/versatile-expertise',
    text: 'Ana and Sam were heard because each was a peer at home and knew the field deeply. Depth gets a bridge through the door; flexibility lets it translate.' },
  { id: 'curse-of-expertise', at: 'towns', title: 'The curse of expertise', href: '../concepts/curse-of-expertise',
    text: 'Your field’s slides felt perfectly clear to you. That is the trap: the deeper you are in one way of seeing, the harder it is to notice it is only one way.' },
  { id: 'polarization-via-distrust', at: 'epilogue', title: 'Just connect them?', href: '../concepts/polarization-via-distrust',
    text: 'Two reasonable towns, each trusting the other a little less, can drift apart faster once you put them in one room.' },
  { id: 'zollman-effect', at: 'epilogue', title: 'The stampede', href: '../concepts/zollman-effect',
    text: 'In a densely connected crowd, the first confident claim spreads before the evidence is in. There is a best amount of connection, and it is not the most.' },
  { id: 'survivable-polarization', at: 'epilogue', title: 'Built for partial trust', href: '../concepts/survivable-polarization',
    text: 'The panel did not need the towns to trust each other. It let a skeptic check the part they cared about.' },
];

// Verbatim from the chapters. bridge.test.js checks each against its source file.
export const QUOTES = {
  peer: {
    text: 'The depth is what gets them admitted as a peer on either side; the flexibility is what lets them see and translate the structural analogy across.',
    attr: 'Lossy, Ch. 9', source: 'content/integration-problem.md',
  },
  channel: {
    text: 'Adding a channel between distrustful communities can accelerate divergence, not reconcile it.',
    attr: 'Lossy, Ch. 9', source: 'content/integration-problem.md',
  },
  audit: {
    text: 'an institution whose reasoning and evidence are published can be partially trusted by doubters who verify the parts that matter to them',
    attr: 'Lossy, Ch. 12', source: 'content/infrastructure-for-integration.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part four',
    title: 'The Bridge',
    body: 'You hold a finding two towns both need, and the towns do not trust each other. Choose who carries it to each town, how it is framed, and how the towns talk afterwards.',
    findingLabel: 'Your finding',
    button: 'Go to the first town',
  },
  town: {
    heading: '{name}',
    heard: 'Overheard in the town hall',
    pick: 'Who carries the finding to {name}?',
  },
  framing: {
    heading: 'How does {messenger} put it?',
    back: 'Choose a different messenger',
  },
  reaction: {
    heading: 'How {name} took it',
    next: 'Next town',
    last: 'Decide how the towns talk',
  },
  connect: {
    heading: 'Ten years is a long time',
    body: 'Both towns will keep hearing about the river. How should they talk about it from here?',
    cards: 'New cards',
  },
  epilogue: {
    heading: 'Ten years on',
    town: '{name}, ten years on',
    both: 'Both towns read the river the same way, and roughly right.',
    notBoth: 'The towns do not read the river the same way.',
    cards: 'New cards',
    button: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Who would this audience hear it from, and is that person a peer there?',
      'Am I leading with the half of the truth this audience will flip?',
      'Can a skeptic check it without having to trust me?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Lowmill, Ridgeton, Ana, Sam and Jules are invented. Compound X is the book’s made-up example.',
      'Real towns are not of one mind, and real bridges take years to build, not one choice.',
      'The ten-year outcomes are fixed to show the book’s argument. The research behind them is modelling, not a forecast.',
    ],
    replay: 'Build the bridge again',
    links: [
      { label: 'Back to Courier', href: './' },
      { label: 'The Reader', href: './reader.html' },
      { label: 'Read Chapter 9', href: '../integration-problem' },
      { label: 'Read Chapter 12', href: '../infrastructure-for-integration' },
    ],
  },
};
```

### 1b. `game/bridge-engine.js`

Pure ES module importing only from `./bridge-data.js`. No DOM, no globals, no
randomness. Never mutate an input.

| Export | Returns |
|---|---|
| `getTown(id)` | the town with that id |
| `offered(town)` | `['you', 'host', town.local]` |
| `outcome(town, messengerId, framingId)` | `{ lands, text, cause }` where `cause` is `'framing'` when the messenger is the local, else `'messenger'`; throws `new Error('bad pick')` if the messenger is not offered or the framing is not a key of `FRAMINGS` |
| `finalLands(lands, connectionId)` | per the rule in **The model** |
| `initialState()` | see below |
| `step(state, action)` | see below |

```js
initialState() === {
  screen: 'intro',   // intro | town | framing | reaction | connect | epilogue | end
  townIndex: 0,
  messenger: null,
  results: [],       // { townId, messenger, framing, lands, text, cause }
  connection: null,
  cards: [],
  newCards: [],
}
```

Any action not listed for the current screen, or whose id is not valid there,
returns the same state object.

| Screen | Action | Effect |
|---|---|---|
| `intro` | `START` | `screen = 'town'`, `townIndex = 0` |
| `town` | `PICK_MESSENGER` `{ id }` | if `id` is in `offered(town)`: `messenger = id`, `screen = 'framing'` |
| `framing` | `BACK` | `messenger = null`, `screen = 'town'` |
| `framing` | `PICK_FRAMING` `{ id }` | if `id` is a key of `FRAMINGS`: append `{ townId, messenger, framing: id, ...outcome(...) }` to `results`, `screen = 'reaction'` |
| `reaction` | `NEXT` | if another town follows: `townIndex + 1`, `messenger = null`, `screen = 'town'`. Otherwise **unlock**(`'towns'`), `screen = 'connect'` |
| `connect` | `PICK_CONNECTION` `{ id }` | if `id` is a key of `CONNECTIONS`: `connection = id`, **unlock**(`'epilogue'`), `screen = 'epilogue'` |
| `epilogue` | `NEXT` | `screen = 'end'` |
| `end` | `REPLAY` | `{ ...initialState(), screen: 'town' }` |

**unlock(at)**: `newCards` = ids of `CARDS` with that `at` not already in
`cards`, in file order; append them to `cards`.

### 1c. `game/bridge.test.js`

- **Outcome table.** With the local messenger: Lowmill `safe` → `FLAG`,
  `risk` → `INVERTED`, `gauges` → `PRESERVED`; Ridgeton `safe` → `INVERTED`,
  `risk` → `FLAG`, `gauges` → `PRESERVED`. With `you` or `host`, every framing
  → `BOUNCED` in both towns. `outcome(lowmill, 'sam', 'gauges')` throws.
- **finalLands.** `forum` turns every stamp into `FLAG`; `apart` keeps every
  stamp; `panel` turns `BOUNCED` into `PRESERVED` and keeps the rest.
- **Every path.** Enumerate all paths (3 messengers × 3 framings per town, two
  towns, 3 connections): exactly 243. Exactly 50 end with both towns
  `PRESERVED`: 49 through `panel`, 1 through `apart`, 0 through `forum`.
- **Invariants.** Two towns; each town's `local` is a key of `MESSENGERS` and
  each town has `outsiders` for exactly `you` and `host`; every `lands` is a
  key of `STAMPS` from `./courier-data.js`; card ids unique; every card's `at`
  is `'towns'` or `'epilogue'`.
- **Quote check** and **card link check**: exactly as in `courier.test.js`.
- **Playthrough A, the bridge.** `START`, `PICK_MESSENGER ana`,
  `PICK_FRAMING gauges`, `NEXT`, `PICK_MESSENGER sam`, `PICK_FRAMING gauges`,
  `NEXT` (assert `screen === 'connect'`, `newCards.length === 2`),
  `PICK_CONNECTION panel` (assert `newCards.length === 3`), `NEXT`. Assert
  `screen === 'end'`, `cards.length === 5`, and both results `PRESERVED`.
- **Playthrough B, the expert.** `PICK_MESSENGER you`, `PICK_FRAMING gauges`,
  `NEXT`, `PICK_MESSENGER you`, `PICK_FRAMING gauges`, `NEXT`,
  `PICK_CONNECTION forum`. Both results are `BOUNCED`; both final stamps are
  `FLAG`.
- **Edge cases.** `BACK` from `framing` returns to `town` with
  `messenger === null` and `results` unchanged; `PICK_MESSENGER sam` in
  Lowmill returns the same state object; `REPLAY` gives `screen === 'town'`
  and empty `results` and `cards`; both playthroughs also run with the state
  deep-frozen before every `step`.

Checks: `node --test game/*.test.js` (all four games pass). Commit
`Phase <N>: bridge game — data, engine, tests`, including this plan.

---

## Phase 2 — the playable page

`game/bridge.html`: same shape as `game/reader.html`, with title
`The Bridge — a game from Lossy`, header word `The Bridge`, script
`./bridge-ui.js`.

Append to `game/courier.css`, after the Reader section and before the
`prefers-reduced-motion` block, a section headed `/* ---- The Bridge ---- */`:
`.finding` (a `var(--bg-raise)` box, 1px `var(--wire)` border, 8px radius,
14px padding, `var(--serif)` text); `.heard` (a list with no bullets, italic
`var(--serif)`, `var(--ink-dim)`). Reuse `.stack`, `.item`, `.story-line`,
`.card` and the rest for everything else.

`game/bridge-ui.js` imports
`{ FINDING, MESSENGERS, FRAMINGS, TOWNS, CONNECTIONS, CARDS, QUOTES, COPY }`
from `./bridge-data.js`, `{ STAMPS }` from `./courier-data.js`, and
`* as engine` from `./bridge-engine.js`. Copy the helpers from `reader-ui.js`
(`fill`, `h` with its disabled-click guard, `dispatch` with its focus rule,
`title`, `btn`, `card`, `quote`); use
`viewKey = (s) => \`${s.screen}:${s.townIndex}\``. Stamp labels and tones come
from `STAMPS` (no `BOUNCED` override in this game). The town is
`TOWNS[state.townIndex]`.

| Screen | Shows | Buttons |
|---|---|---|
| `intro` | `kicker`, `title` as `<h1>`, `body`, `COPY.intro.findingLabel` as `<h2>`, `FINDING` in a `.finding` box | `COPY.intro.button` → `START` |
| `town` | `COPY.town.heading` as `<h1>`; the town's `about`; `COPY.town.heard` as `<h2>` and `heard` as a `.heard` list; the `.finding` box; `COPY.town.pick` as `<h2>` | one `.item` button per `engine.offered(town)` in a `.stack`, showing the messenger's `name` (bold) and `about` → `PICK_MESSENGER` |
| `framing` | `COPY.framing.heading` as `<h1>` (`messenger` = the name) | one `.item` per framing in `FRAMINGS` order, showing `label` (bold) and `text` → `PICK_FRAMING`; `COPY.framing.back` → `BACK` as a link-style button |
| `reaction` | `COPY.reaction.heading` as `<h1>`; a `.story-line` with the messenger's name and framing label on one mono line, the stamp, and the result's `text` | `COPY.reaction.last` if this was the last town, else `COPY.reaction.next` → `NEXT` |
| `connect` | `COPY.connect.heading` as `<h1>`; `body`; the `peer` quote; if `newCards` is not empty, `COPY.connect.cards` as `<h2>` and the cards | one `.item` per connection in `CONNECTIONS` order, showing `label` (bold) and `about` → `PICK_CONNECTION` |
| `epilogue` | `COPY.epilogue.heading` as `<h1>`; the chosen connection's `epilogue`; for each result, `COPY.epilogue.town` as `<h3>` and the stamp of `engine.finalLands(result.lands, state.connection)`; `both` if both final stamps are `PRESERVED`, else `notBoth`; the `channel` quote, then the `audit` quote; new cards under `COPY.epilogue.cards` | `COPY.epilogue.button` → `NEXT` |
| `end` | `COPY.end.heading` as `<h1>`; the questions as an ordered list; `cutHeading` and the cut lines as a list | `COPY.end.replay` → `REPLAY`; the four links as plain links |

Checks: `node --test game/*.test.js`, `node --check game/bridge-ui.js`, and
`grep -n innerHTML game/bridge-ui.js` printing nothing. The reviewer does the
browser checks; leave Phase 2 uncommitted unless told otherwise.

---

## Phase 3 — wire it up

1. `game/reader-data.js`: in `COPY.end.links`, insert first:
   `{ label: 'Next: build the bridge', href: './bridge.html' },`
2. `Makefile` `play-stage`: append
   `game/bridge.html game/bridge-data.js game/bridge-engine.js game/bridge-ui.js`
   before `site/public/play/`.
3. `content/index.md`, in the line starting `- **<a href="./play/"`: replace
   `with a week's worth of minutes.` with
   `with a week's worth of minutes, then carry a finding between two towns that don't trust each other.`
4. `game/README.md`: add `## Part four: the Bridge` and the bridge files to the
   layout tree.

Commit `Phase <N>: bridge game — link from the Reader, stage at /play/`, then
run `make check`, `make site-build`, `make site-check`.

## Not in this plan

The Keeper seat, saved progress, and any change to chapter prose.
