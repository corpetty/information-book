# Courier — build plan

A ten-minute browser game for *Lossy*, published at `lossybook.com/play/`.
The player carries three findings from the lab to the feed, decides what to cut
at each hand-off, and sees how each one lands.

This plan is written to be executed step by step by a model that makes **no
design decisions**. Every piece of game text, every number, and every rule is
fixed below. Copy them exactly.

## Rules for the executor

1. Do the phases in order. One commit per phase. Do not start a phase until the
   previous phase's checks pass.
2. Copy all game text and numbers from this file verbatim. Do not reword,
   "improve", or add copy. Do not add rounds, readers, chips, or cards.
3. No dependencies, no build step, no network requests, no analytics, no
   `localStorage`. Plain HTML, CSS, and ES modules.
4. Touch only the files this plan names. In `content/`, the only permitted
   change is the one line in `content/index.md` (Phase 4). Never edit `data/`.
5. If a check fails and the fix is not obvious from this plan, or a quote test
   fails, **stop and report**. Do not edit a chapter or a quote to make a test
   pass.
6. Do not push, merge, or open a pull request. Report when done.

## Setup (before Phase 1)

```bash
git fetch origin
git switch -c courier-game origin/main
git log --oneline -1
```

The last command prints the latest `Phase N:` commit. Number your commits
`N+1`, `N+2`, … in the form `Phase <number>: courier game — <what>`.

## What gets built

```
game/
  PLAN.md             this file (already exists)
  README.md           Phase 4
  courier-data.js     Phase 1  all content: readers, rounds, cards, quotes, copy
  courier-engine.js   Phase 1  pure logic and state machine, no DOM
  courier.test.js     Phase 1  node --test
  index.html          Phase 2
  courier.css         Phase 2
  courier-ui.js       Phase 2  renders state, dispatches actions; nothing else
```

Design rule: **all behaviour lives in `courier-engine.js` as pure functions**.
`courier-ui.js` only draws the current state and turns clicks into actions. That
is what lets Phase 1's tests cover the whole game without a browser.

## The model (read once, then implement)

- A **round** is one finding carried over three **hops** (hand-offs).
- The finding is a **claim** plus **chips**. A chip is one piece of the manual
  for reading the claim (scope, method, doubt). Each chip has a `cost`. The
  claim always travels and has a fixed `claimCost`.
- Each hop has one or more **options**. An option has a `budget`. The player
  must cut chips until `claimCost + sum(kept chip costs) <= budget`.
  A chip cut at one hop is gone for every later hop.
- Chips have a `role`: `corrective` (the reader gets the claim wrong without
  it) or `elaboration` (detail).
- The last hop's option also has a `reach` (people) and a `mix` (percent of
  each reader type). Three reader types: `A`, `B`, `C`.
- Each reader type lands by a **rule**:
  - `fixed`: everyone of that type gets one stamp.
  - `byChips`: the share who get the `fail` stamp equals
    (corrective chips missing) / (corrective chips in the round). The rest get
    the `pass` stamp.
- Stamps: `PRESERVED`, `INVERTED`, `FLAG`, `BOUNCED`.
- After round `r2` the player gains the **lens**: chips show their role.
- Finishing a round unlocks that round's **cards**.

---

## Phase 1 — data, engine, tests

### 1a. `game/courier-data.js`

Create the file with exactly this content.

```js
// Courier — all game content. Text and numbers are fixed by game/PLAN.md.
// Reader counts are invented to show a shape; they are not data.

export const READERS = {
  A: { name: 'The trained reader', key: 'a finding is provisional and scoped' },
  B: { name: 'The busy reader', key: 'a stated fact is a settled fact' },
  C: { name: 'The team reader', key: 'who is saying this?' },
};

export const STAMPS = {
  PRESERVED: { tone: 'ok', label: 'Roughly right' },
  INVERTED: { tone: 'bad', label: 'Flipped' },
  FLAG: { tone: 'flag', label: 'Read as a team flag' },
  BOUNCED: { tone: 'dim', label: 'Changes nothing' },
};

const R2_LANDING = {
  A: { rule: 'fixed', stamp: 'PRESERVED', text: 'In mice, at absurd doses, unreplicated. Worth watching.' },
  B: {
    rule: 'byChips',
    pass: { stamp: 'PRESERVED', text: 'A mouse result at huge doses. Not worried.' },
    fail: { stamp: 'INVERTED', text: 'X will hurt me. Never buying it again.' },
  },
};

export const ROUNDS = [
  {
    id: 'r1',
    title: 'Delivery 1 · The easy one',
    brief: 'An old finding, long settled. Carry it from the observatory to the dinner table. Every hand-off gives you less room. Cut what you must.',
    claimCost: 2,
    predict: false,
    stamps: ['PRESERVED'],
    chips: [
      { id: 'e1', text: 'the orbit is an ellipse, not a circle', cost: 2, role: 'elaboration' },
      { id: 'e2', text: 'one orbit takes about 365.25 days', cost: 1, role: 'elaboration' },
      { id: 'e3', text: 'strictly, both circle a shared center of mass', cost: 3, role: 'elaboration' },
      { id: 'e4', text: 'confirmed by stellar parallax in 1838', cost: 2, role: 'elaboration' },
    ],
    hops: [
      { options: [{ id: 'textbook', to: 'Textbook', budget: 9, claim: 'The Earth orbits the Sun.' }] },
      { options: [{ id: 'column', to: 'Science column', budget: 6, claim: 'The Earth goes around the Sun.' }] },
      {
        options: [{
          id: 'table', to: 'Dinner table', budget: 3, claim: 'The Earth goes around the Sun.',
          reach: 1000000, mix: { A: 20, B: 80, C: 0 },
          landing: {
            A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Knows the fine print exists and where to find it.' },
            B: { rule: 'fixed', stamp: 'PRESERVED', text: 'Believes the Earth goes around the Sun. Correct.' },
          },
        }],
      },
    ],
    result: {
      ifStamp: null,
      then: '',
      else: 'Everything you cut was detail. The bare claim still lands in the right place. Most compression is like this: lossy and honest.',
    },
    quote: 'preservation',
  },
  {
    id: 'r2',
    title: 'Delivery 2 · Compound X',
    brief: 'A new lab result. Compound X is the made-up example from Chapter 5c of the book; no such substance exists. Same job: lab to readers.',
    claimCost: 2,
    predict: true,
    stamps: ['INVERTED', 'PRESERVED'],
    chips: [
      { id: 'c1', text: 'in mice', cost: 1, role: 'corrective' },
      { id: 'c2', text: 'at about 1,000× any real human dose', cost: 2, role: 'corrective' },
      { id: 'd1', text: 'one study', cost: 1, role: 'elaboration' },
      { id: 'd2', text: 'not yet replicated', cost: 2, role: 'elaboration' },
      { id: 'd3', text: 'full methods in the supplement', cost: 3, role: 'elaboration' },
    ],
    hops: [
      { options: [{ id: 'journal', to: 'Journal', budget: 11, claim: 'Compound X is carcinogenic.' }] },
      { options: [{ id: 'newsroom', to: 'Newsroom', budget: 7, claim: 'Study links Compound X to cancer.' }] },
      {
        options: [
          {
            id: 'feed', to: 'The feed', budget: 3, claim: 'COMPOUND X CAUSES CANCER',
            reach: 4000000, mix: { A: 10, B: 90, C: 0 }, landing: R2_LANDING,
          },
          {
            id: 'longread', to: 'A long read', budget: 7, claim: 'What the Compound X study found, and what it didn’t',
            reach: 40000, mix: { A: 50, B: 50, C: 0 }, landing: R2_LANDING,
          },
        ],
      },
    ],
    result: {
      ifStamp: 'INVERTED',
      then: 'About {n} people now believe Compound X will hurt them. Every word you handed on was true.',
      else: 'Everyone you reached got the key. You reached {reach} people.',
    },
    rival: {
      optionId: 'feed',
      kept: [],
      text: 'Meanwhile, another courier took the bare claim to the feed. It did not need you.',
    },
    quote: 'inversion',
  },
  {
    id: 'r3',
    title: 'Delivery 3 · The correction',
    brief: 'In 2010 a study of 42 people said two minutes of “power posing” raises testosterone, lowers cortisol and improves performance on a risk-taking task. A TED talk about it has more than 70 million views. In 2015 a replication with 200 people found no hormone effect and no behavioral one. You are carrying the replication.',
    claimCost: 2,
    predict: true,
    stamps: ['INVERTED', 'BOUNCED', 'FLAG', 'PRESERVED'],
    chips: [
      { id: 'p1', text: '200 people this time; the original had 42', cost: 2, role: 'corrective' },
      { id: 'p2', text: 'the original’s lead author disavowed it in 2016', cost: 2, role: 'corrective' },
      { id: 'q1', text: 'one author still defends a narrower “felt power” effect', cost: 3, role: 'elaboration' },
      { id: 'q2', text: 'now a standard case of the replication crisis', cost: 1, role: 'elaboration' },
    ],
    hops: [
      { options: [{ id: 'journal', to: 'Journal', budget: 10, claim: 'A larger replication finds no effect of power posing on hormones or behavior.' }] },
      { options: [{ id: 'newsroom', to: 'Newsroom', budget: 6, claim: 'Power posing doesn’t work, bigger study finds.' }] },
      {
        options: [
          {
            id: 'faithful', to: 'Post it straight', budget: 4,
            claim: 'Power posing does not change your hormones or your behavior.',
            reach: 40000, mix: { A: 30, B: 50, C: 20 },
            landing: {
              A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Updates. Drops the pose.' },
              B: {
                rule: 'byChips',
                pass: { stamp: 'PRESERVED', text: 'Bigger study, and the author backed off. Fair enough.' },
                fail: { stamp: 'BOUNCED', text: 'One study says yes, one says no. Keeps the pose.' },
              },
              C: { rule: 'fixed', stamp: 'FLAG', text: 'Who is posting this, and what are they selling?' },
            },
          },
          {
            id: 'punchy', to: 'Punch it up', budget: 2,
            claim: 'POWER POSING WAS A LIE',
            reach: 2000000, mix: { A: 10, B: 50, C: 40 },
            landing: {
              A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Looks up the replication. Winces at the headline.' },
              B: { rule: 'fixed', stamp: 'INVERTED', text: 'So psychology is a scam. Good to know.' },
              C: { rule: 'fixed', stamp: 'FLAG', text: 'Shares it to dunk on TED people.' },
            },
          },
          {
            id: 'upbeat', to: 'Find the good news', budget: 2,
            claim: 'Science confirms: power posing makes you feel more powerful!',
            reach: 6000000, mix: { A: 10, B: 80, C: 10 },
            landing: {
              A: { rule: 'fixed', stamp: 'PRESERVED', text: 'Reads past the headline. Notes that only the feeling survived.' },
              B: { rule: 'fixed', stamp: 'INVERTED', text: 'Knew it. Keeps the pose.' },
              C: { rule: 'fixed', stamp: 'FLAG', text: 'Posts it under a gym selfie.' },
            },
          },
        ],
      },
    ],
    result: {
      ifStamp: 'INVERTED',
      then: 'The version that travelled says something the study didn’t. {n} people took it that way.',
      else: 'You kept it straight. {reach} people saw it.',
    },
    compare: { label: 'The original’s TED talk', count: 70000000, suffix: 'views, and counting' },
    quote: 'fitness',
  },
];

export const CARDS = [
  { id: 'compressed-form', round: 'r1', title: 'Compressed form', href: '../concepts/compressed-form',
    text: 'The short version of an idea, cut to fit the next reader’s room. You just made three of them.' },
  { id: 'receiver-budget', round: 'r1', title: 'Receiver budget', href: '../concepts/receiver-budget',
    text: 'The room shrank at every hand-off because every reader has a finite amount of attention to give. No fix changes that.' },
  { id: 'three-layer-message', round: 'r2', title: 'The key', href: '../concepts/three-layer-message',
    text: 'A message has a claim and a key for reading it: the scope, the method, the doubt. The claim travels. The key is what you cut.' },
  { id: 'truth-compression-regimes', round: 'r2', title: 'Three ways to land', href: '../concepts/truth-compression-regimes',
    text: 'Strip the key and the bare claim can land roughly right, flipped, or as a team flag. Which one depends on the key the reader supplies.' },
  { id: 'optionality-vs-access', round: 'r2', title: 'Faithful or easy', href: '../optionality-vs-access',
    text: 'The long read had room for the key and reached a hundredth of the people. One object can’t be both faithful and easy.' },
  { id: 'memetic-fitness', round: 'r3', title: 'Memetic fitness', href: '../concepts/memetic-fitness',
    text: 'How well a version does at the gates, whatever its truth. The pose is easy, flattering and free. The correction is none of those.' },
  { id: 'selection', round: 'r3', title: 'Selection', href: '../mechanisms/selection',
    text: 'At every hand-off something chose which version moved on. Every version of the correction that travelled far said something the study didn’t.' },
];

// Verbatim from the chapters. courier.test.js checks each against its source file.
export const QUOTES = {
  preservation: {
    text: 'Preservation is when the stripped key was elaboration rather than correction, and the bare claim still decodes to roughly the right place.',
    attr: 'Lossy, Ch. 5c', source: 'content/truth-compression-and-when-each-wins.md',
  },
  inversion: {
    text: 'Inversion is when a true inner message, decoded with the wrong key, yields a false belief, and it is the dangerous regime precisely because nothing was lied about.',
    attr: 'Lossy, Ch. 5c', source: 'content/truth-compression-and-when-each-wins.md',
  },
  fitness: {
    text: 'The pipeline can run its full length and leave a persistent meme even when the finding is wrong, because the correction has worse curation fitness than the thing it corrects.',
    attr: 'Lossy, Ch. 2', source: 'content/case-studies-and-three-realities.md',
  },
  aim: {
    text: 'You cannot aim a cost. You can aim a choice.',
    attr: 'Lossy, Ch. 5b', source: 'content/selection-as-other-engine.md',
  },
};

export const COPY = {
  intro: {
    title: 'Courier',
    kicker: 'A ten-minute game from Lossy',
    body: 'You carry findings from the people who measured them to the people who will repeat them. Every hand-off gives you less room. You decide what to cut.',
    button: 'Start',
  },
  brief: { button: 'Pick it up' },
  hop: {
    heading: 'Hand-off {n} of {total}: to {to}',
    room: 'Room: {used} / {budget}',
    help: 'Tap a part to cut it or put it back. Parts cut at an earlier hand-off are gone.',
    over: 'Over by {k}. Cut something.',
    button: 'Hand it on',
    back: 'Choose a different route',
    lens: 'You can now see which parts are the key (◆) and which are detail (·).',
    lensKey: '◆ key',
    lensDetail: '· detail',
  },
  choose: { heading: 'Where does it go?', option: 'Room {budget} · reaches about {reach} people' },
  predict: { heading: 'Before it lands: how will most readers take it?' },
  result: {
    heading: 'How it landed',
    reader: '{name} · default key: “{key}”',
    called: 'You called it.',
    missed: 'You expected “{expected}”. Most readers: “{actual}”.',
    cards: 'New cards',
    next: 'Next delivery',
    finish: 'See the chain of custody',
  },
  end: {
    heading: 'Chain of custody',
    ledgerKept: 'kept',
    ledgerCut: 'cut',
    carryHeading: 'What you carry out',
    carry: [
      'How many hand-offs is this from the people who measured it?',
      'What part of the key is missing: the scope, the method, or the doubt?',
      'Who chose this version to reach me, and what were they choosing for?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Every count of readers here is invented to show a shape. The power-posing facts and the 70 million views are from Chapter 2.',
      'Real readers come in more than three kinds, and one person is all three on different days.',
      'Compound X is the book’s made-up example.',
      'This game covers transport and a first look at selection. The rest of the argument is in the chapters.',
    ],
    replay: 'Carry Compound X again',
    replayNote: 'This time you can see which parts are the key.',
    links: [
      { label: 'Read Chapter 1', href: '../the-information-landscape' },
      { label: 'The short version', href: '../the-short-version' },
      { label: 'Explore the ideas', href: '../explore' },
    ],
  },
};
```

### 1b. `game/courier-engine.js`

Pure ES module. Imports only from `./courier-data.js`. No DOM, no globals, no
randomness, no dates. Never mutate an input; always return new objects.

Export these functions with exactly these names and behaviours.

| Function | Returns |
|---|---|
| `getRound(id)` | the round object with that id |
| `cost(round, keptIds)` | `round.claimCost` + sum of `cost` for chips whose id is in `keptIds` |
| `fits(round, keptIds, budget)` | `cost(round, keptIds) <= budget` |
| `getOption(round, hopIndex, optionId)` | the option at that hop with that id; throws if absent |
| `missingShare(round, keptIds)` | (corrective chips not in `keptIds`) / (corrective chips in round); `0` if the round has none |
| `resolve(round, optionId, keptIds)` | see below |
| `resultLine(round, outcome)` | see below |
| `cardsFor(roundId)` | array of `CARDS` entries whose `round` equals `roundId`, in file order |
| `initialState()` | see state machine |
| `step(state, action)` | the next state; see state machine |

**`resolve(round, optionId, keptIds)`**

1. `option` = the option with `optionId` in the round's **last** hop.
2. If `!fits(round, keptIds, option.budget)`, throw `new Error('over budget')`.
3. `share = missingShare(round, keptIds)`.
4. For each reader type in order `A`, `B`, `C`:
   - `count = Math.round(option.reach * (option.mix[type] || 0) / 100)`. If `count` is 0, skip.
   - If the rule is `fixed`: add group `{ reader: type, count, stamp, text }`.
   - If the rule is `byChips`: `fail = Math.round(count * share)`, `pass = count - fail`.
     Add the `pass` group if `pass > 0`, then the `fail` group if `fail > 0`.
5. `tallies` = object mapping each stamp to the sum of `count` over its groups
   (only stamps that occur).
6. `majority` = the stamp with the largest tally. On a tie, the one that comes
   first in `round.stamps`.
7. Return `{ optionId, reach: option.reach, groups, tallies, majority }`.

**`resultLine(round, outcome)`**

- If `round.result.ifStamp` is set and `outcome.tallies[ifStamp] > 0`, use
  `round.result.then`; otherwise use `round.result.else`.
- Replace `{n}` with `outcome.tallies[ifStamp]` and `{reach}` with
  `outcome.reach`, both formatted with `toLocaleString('en-US')`.

**State machine**

```js
initialState() === {
  screen: 'intro',      // intro | brief | choose | hop | predict | result | end
  roundIndex: 0,
  hopIndex: 0,
  entryKept: [],        // chip ids alive when this hop began
  kept: [],             // chip ids currently kept
  optionId: null,       // chosen option at the current hop
  prediction: null,
  lens: false,
  cards: [],            // unlocked card ids, in unlock order
  newCards: [],         // card ids unlocked by the round just finished
  current: null,        // { roundId, hops: [] } for the round in play
  outcome: null,        // result of resolve() for the round just finished
  ledger: [],           // finished rounds
  replay: false,
}
```

`step(state, action)` where `action` is `{ type, ... }`. Any action not listed
for the current screen returns the state unchanged.

Helper used below, **enterHop(state, hopIndex, alive)**: set `hopIndex`,
`entryKept = alive`, `kept = alive`. If that hop has exactly one option, set
`optionId` to its id and `screen = 'hop'`. Otherwise set `optionId = null` and
`screen = 'choose'`.

| Screen | Action | Effect |
|---|---|---|
| `intro` | `START` | `screen = 'brief'`, `roundIndex = 0` |
| `brief` | `BEGIN_ROUND` | `current = { roundId, hops: [] }`, `prediction = null`, `outcome = null`, `newCards = []`, then **enterHop**(0, all chip ids of the round in file order) |
| `choose` | `CHOOSE_OPTION` `{ id }` | if `id` is an option of this hop: `optionId = id`, `kept = entryKept`, `screen = 'hop'` |
| `hop` | `TOGGLE_CHIP` `{ id }` | if `id` is in `entryKept`: remove it from `kept` if present, else add it. Keep `kept` in the round's chip file order |
| `hop` | `BACK` | only if this hop has more than one option: `optionId = null`, `kept = entryKept`, `screen = 'choose'` |
| `hop` | `HAND_ON` | if the kept chips do not fit the option's budget: unchanged. Otherwise append `{ to: option.to, optionId, kept, cut }` to `current.hops`, where `cut` = ids in `entryKept` not in `kept`. Then: if this is not the last hop, **enterHop**(hopIndex + 1, kept). If it is the last hop and `round.predict` is true, `screen = 'predict'`. If it is the last hop and `round.predict` is false, **finish** |
| `predict` | `PREDICT` `{ stamp }` | if `stamp` is in `round.stamps`: `prediction = stamp`, then **finish** |
| `result` | `NEXT` | if `replay` is true or this was the last round: `screen = 'end'`. Otherwise `roundIndex + 1`, `screen = 'brief'` |
| `end` | `REPLAY_R2` | `replay = true`, `roundIndex` = index of `r2`, `screen = 'brief'` |

**finish**: `outcome = resolve(round, optionId, kept)`. Append to `ledger`:
`{ roundId, hops: current.hops, optionId, outcome, prediction, replay }`.
`newCards` = ids from `cardsFor(round.id)` not already in `cards`; append them
to `cards`. If `round.id === 'r2'`, `lens = true`. `screen = 'result'`.

### 1c. `game/courier.test.js`

Use `node:test` and `node:assert/strict`. Write these tests.

**Resolve table.** Each row must match exactly (`tallies` deep-equal, and
`majority`).

| Round | Option | Kept | Tallies | Majority |
|---|---|---|---|---|
| r1 | table | `[]` | PRESERVED 1000000 | PRESERVED |
| r2 | feed | `['c1']` | PRESERVED 2200000, INVERTED 1800000 | PRESERVED |
| r2 | feed | `[]` | PRESERVED 400000, INVERTED 3600000 | INVERTED |
| r2 | feed | `['d1']` | PRESERVED 400000, INVERTED 3600000 | INVERTED |
| r2 | longread | `['c1','c2','d1']` | PRESERVED 40000 | PRESERVED |
| r2 | longread | `['c1']` | PRESERVED 30000, INVERTED 10000 | PRESERVED |
| r3 | faithful | `['p1']` | PRESERVED 22000, BOUNCED 10000, FLAG 8000 | PRESERVED |
| r3 | faithful | `[]` | PRESERVED 12000, BOUNCED 20000, FLAG 8000 | BOUNCED |
| r3 | punchy | `[]` | PRESERVED 200000, INVERTED 1000000, FLAG 800000 | INVERTED |
| r3 | upbeat | `[]` | PRESERVED 600000, INVERTED 4800000, FLAG 600000 | INVERTED |

**Other engine tests.**

- `resolve(r2, 'feed', ['c1','c2'])` throws.
- `resultLine` for r2 feed `[]` equals
  `About 3,600,000 people now believe Compound X will hurt them. Every word you handed on was true.`
- `resultLine` for r2 longread `['c1','c2','d1']` equals
  `Everyone you reached got the key. You reached 40,000 people.`

**Data invariants** (loop over `ROUNDS`).

- Every option's `budget >= round.claimCost`.
- Every last-hop option's `mix` values sum to 100, and every reader type with a
  non-zero mix has a `landing` rule.
- Every stamp used in any landing rule is in `round.stamps` and in `STAMPS`.
- Chip ids are unique within a round. Card ids are unique.
- In r2, no set of kept chips containing both `c1` and `c2` fits the `feed` budget.
- Every `round.quote` is a key of `QUOTES`.

**Quote check.** For each entry in `QUOTES`: read `source` (path relative to
the repo root), then normalise the file text: replace `[[target|label]]` with
`label`, replace `[[target]]` with `target`, delete every `**`, collapse runs
of whitespace to one space. Assert the normalised text includes `text`.

**Card link check.** For each card, strip the leading `../` from `href` to get
`p`. Assert that `content/<p>.md` exists, or that `content/<p with every "-"
replaced by a space>.md` exists.

**Full playthrough.** Starting from `initialState()`, apply these actions in
order with `step`, then assert the final state.

```
START
BEGIN_ROUND                        (r1)
TOGGLE_CHIP e3 · HAND_ON           (textbook: cost 7 of 9)
TOGGLE_CHIP e1 · HAND_ON           (column: cost 5 of 6)
TOGGLE_CHIP e4 · HAND_ON           (table: cost 3 of 3) → result
NEXT
BEGIN_ROUND                        (r2)
HAND_ON                            (journal: cost 11 of 11)
TOGGLE_CHIP d3 · TOGGLE_CHIP d2 · HAND_ON   (newsroom: cost 6 of 7) → choose
CHOOSE_OPTION feed
TOGGLE_CHIP c2 · TOGGLE_CHIP d1 · HAND_ON   (feed: cost 3 of 3) → predict
PREDICT INVERTED                   → result
NEXT
BEGIN_ROUND                        (r3)
HAND_ON                            (journal: cost 10 of 10)
TOGGLE_CHIP q1 · TOGGLE_CHIP q2 · HAND_ON   (newsroom: cost 6 of 6) → choose
CHOOSE_OPTION upbeat
TOGGLE_CHIP p1 · TOGGLE_CHIP p2 · HAND_ON   (upbeat: cost 2 of 2) → predict
PREDICT INVERTED                   → result
NEXT                               → end
```

Assert at the end: `screen === 'end'`, `ledger.length === 3`,
`cards.length === 7`, `lens === true`,
`ledger[1].outcome.tallies` deep-equals `{ PRESERVED: 2200000, INVERTED: 1800000 }`,
`ledger[1].outcome.majority === 'PRESERVED'` (so that prediction was wrong),
`ledger[2].outcome.majority === 'INVERTED'`.

Also assert mid-run: after the r1 `NEXT`, `lens === false`; `HAND_ON` while
over budget returns a state deep-equal to the one passed in; `TOGGLE_CHIP` of a
chip cut at an earlier hop changes nothing.

Then `REPLAY_R2` from the end state: `screen === 'brief'`, `replay === true`,
and the round at `roundIndex` is r2.

### Phase 1 checks

```bash
node --test game/*.test.js
```

All tests pass. Commit: `Phase <N>: courier game — data, engine, tests`.

---

## Phase 2 — the playable page

### 2a. `game/index.html`

- `<!DOCTYPE html>`, `lang="en"`, charset, viewport meta.
- `<title>Courier — a game from Lossy</title>`
- `<link rel="stylesheet" href="./courier.css">`
- Body: `<header>` with a link `← Lossy` to `../` and the word `Courier`;
  `<main id="app" aria-live="polite"></main>`;
  `<script type="module" src="./courier-ui.js"></script>`.
- A `<noscript>` line: `This game needs JavaScript. The book does not: ` plus a
  link to `../the-short-version`.

### 2b. `game/courier.css`

- Copy the colour and font variables from the `:root` block at the top of
  `presentation/lossy-talk.html` (`--bg` through `--mono`). Use only those
  variables for colour. Dark theme only.
- Stamp tones: `ok` → `var(--ok)`, `bad` → `var(--bad)`, `flag` → `var(--flag)`,
  `dim` → `var(--ink-faint)`.
- The page scrolls normally (do **not** copy the talk's `overflow: hidden`).
- One centred column, `max-width: 720px`, `padding: 0 16px`. No horizontal
  scroll at 375px wide.
- Type roles: claim text in `var(--serif)`; a claim that is all capitals in the
  data is shown in bold `var(--sans)`; chips, the room meter and stamps in
  `var(--mono)`; everything else `var(--sans)`.
- Chips are `<button>`s at least 44px tall, wrapping freely. A cut chip is
  struck through and dimmed. A chip cut at an earlier hop is shown struck
  through, dimmed, and `disabled`.
- Visible `:focus-visible` outline in `var(--signal)` on every button and link.
- Inside `@media (prefers-reduced-motion: reduce)`, disable all transitions and
  animations.

### 2c. `game/courier-ui.js`

```js
import { ROUNDS, READERS, STAMPS, CARDS, QUOTES, COPY } from './courier-data.js';
import * as engine from './courier-engine.js';
```

- Hold one `state` variable, starting at `engine.initialState()`.
- `dispatch(action)`: `state = engine.step(state, action); render();` then move
  keyboard focus to the screen's `<h1>` (give it `tabindex="-1"`) and scroll to
  the top.
- `render()` clears `#app` and draws the screen for `state.screen`. Build DOM
  with `document.createElement` and `textContent`. Do not use `innerHTML` with
  data.
- Format every count with `toLocaleString('en-US')`.
- No game logic here. To know if the player is over budget, call
  `engine.cost` and `engine.fits`. To show the rival panel, call
  `engine.resolve`.

Screens:

| Screen | Shows | Buttons |
|---|---|---|
| `intro` | `COPY.intro.kicker`, `title` as `<h1>`, `body` | `COPY.intro.button` → `START` |
| `brief` | round `title` as `<h1>`, round `brief`. If `state.replay`, also `COPY.end.replayNote` | `COPY.brief.button` → `BEGIN_ROUND` |
| `choose` | `COPY.choose.heading` as `<h1>`; one button per option showing the option's `to`, its `claim`, and `COPY.choose.option` filled in | each → `CHOOSE_OPTION` |
| `hop` | heading from `COPY.hop.heading`; the option's `claim`; the room meter; the help line; every chip of the round as a button with its text and cost; if over budget, the `over` line. If `state.lens`, show `COPY.hop.lens` once and append `lensKey` to corrective chips and `lensDetail` to elaboration chips | chip → `TOGGLE_CHIP`; `COPY.hop.button` → `HAND_ON`, `disabled` while over budget; if the hop has several options, `COPY.hop.back` → `BACK` |
| `predict` | `COPY.predict.heading` as `<h1>`; the claim as it will be delivered and the kept chips | one button per stamp in `round.stamps`, labelled `STAMPS[stamp].label` → `PREDICT` |
| `result` | see below | `COPY.result.next` (or `COPY.result.finish` if the next screen is `end`) → `NEXT` |
| `end` | see below | `COPY.end.replay` → `REPLAY_R2`; the three `COPY.end.links` as plain links |

Chip button accessibility: `aria-pressed="true"` when kept, `"false"` when cut.

**Result screen, top to bottom:**

1. `COPY.result.heading` as `<h1>`.
2. The delivered claim and the kept chips.
3. One block per entry in `state.outcome.groups`: the reader line from
   `COPY.result.reader`, the count, the stamp label coloured by its tone, and
   the group's `text` in quotation marks.
4. A totals line: `state.outcome.tallies` as `label: count` pairs (label from
   `STAMPS`), in `round.stamps` order, skipping stamps with no tally.
5. `engine.resultLine(round, state.outcome)`.
6. If the round has `predict`: `COPY.result.called` when
   `state.prediction === state.outcome.majority`, otherwise
   `COPY.result.missed` filled with the two stamp labels.
7. If the round has `rival`: the rival `text`, then the tallies from
   `engine.resolve(round, rival.optionId, rival.kept)` shown as
   `label: count` pairs.
8. If the round has `compare`: `label`, `count`, `suffix` on one line.
9. The round's quote: `QUOTES[round.quote].text` in a `<blockquote>` with
   `— ` + `attr`.
10. If `state.newCards` is not empty: `COPY.result.cards`, then each new card
    as a block with `title`, `text`, and a link to `href` labelled
    `Read the card`.

**End screen, top to bottom:**

1. `COPY.end.heading` as `<h1>`.
2. For each ledger entry: the round title; one line per hop
   (`to` — `kept`: chip texts — `cut`: chip texts, or `nothing`); then the
   tallies as `label: count` pairs.
3. All unlocked cards (title + link).
4. `COPY.end.carryHeading` and the three questions as an ordered list.
5. The `aim` quote in a `<blockquote>` with its attribution.
6. `COPY.end.cutHeading` and the four lines as a list.
7. The replay button with `COPY.end.replayNote` beneath it, then the links.

### Phase 2 checks

```bash
node --test game/*.test.js
python3 -m http.server 8765
```

Open `http://localhost:8765/game/` and play the exact action sequence from the
Phase 1 playthrough. Confirm:

- The r2 result's totals line reads `Flipped: 1,800,000` and
  `Roughly right: 2,200,000`. Below it are the "You expected…" line and the
  rival panel with `Flipped: 3,600,000`.
- In r3 the chips carry `◆ key` / `· detail` marks; in r1 and r2 they did not.
- The end screen lists three deliveries and seven cards.
- No errors in the browser console.
- At 375px width nothing scrolls sideways.
- The whole game can be played with Tab, Enter and Space alone.

Card and chapter links will 404 on this local server. That is expected; they
resolve once staged (Phase 4).

If you have no browser, say so in your report and list which of these checks
were not run. Do not claim them.

Commit: `Phase <N>: courier game — playable page`.

---

## Phase 3 — hardening

1. Add a test: for **every** combination of last-hop option and every subset of
   chips that fits that option's budget, in every round, `resolve` returns
   groups whose counts sum to exactly `option.reach`, and `majority` is in
   `round.stamps`.
2. Add a test: `step` never mutates its input. Deep-freeze the state before
   each `step` call in the full playthrough (a small recursive
   `Object.freeze` helper) and assert no call throws.
3. In the UI, guard against double activation: ignore a click on a `disabled`
   button.
4. Re-run all Phase 2 checks.

Commit: `Phase <N>: courier game — hardening`.

---

## Phase 4 — publish path

The site stages standalone pages after the Quartz build (see the `talk-stage`
target and its comment in the `Makefile`). Follow the same pattern.

1. **`Makefile`**
   - Add `play-stage` to the `.PHONY` line.
   - Add this target after `talk-stage`:

     ```make
     # Stage the Courier game (game/) at /play/ in the built site. Same
     # post-build pattern as /talk/ and /graph/: kept out of content/ because
     # Quartz would strip the .html extension.
     play-stage:
     	@mkdir -p site/public/play
     	@cp game/index.html game/courier.css game/courier-data.js game/courier-engine.js game/courier-ui.js site/public/play/
     ```

     (Recipe lines start with a tab character.)
   - In `site-build`, add `@$(MAKE) play-stage` on the line after
     `@$(MAKE) talk-stage`.
   - In both `test` and `check`, add a second recipe line:
     `@node --test game/*.test.js`.
   - In the quick-reference comment at the top, add:
     `#   make play-stage  copy game/ into site/public/play`.
2. **`package.json`** (repo root): change the test script to
   `node --test scripts/*.test.js game/*.test.js`.
3. **`.github/workflows/deploy-site.yml`**: add `- "game/**"` to the `paths:`
   list, after `- "scripts/**"`.
4. **`content/index.md`**: directly after the line that starts
   `- **<a href="./talk/"`, add this line:

   ```
   - **<a href="./play/" data-router-ignore="true">Play Courier →</a>**: a ten-minute game. Carry three findings from the lab to the feed, decide what to cut at each hand-off, and see how they land.
   ```
5. **`game/README.md`**: short, modelled on `presentation/README.md`. Say what
   the game is, where it is published (`lossybook.com/play/`, staged by
   `make play-stage`), the file layout from this plan, how to run the tests,
   how to serve it locally, and that all text and numbers are fixed in
   `courier-data.js` with quotes checked against the chapters by the tests.

### Phase 4 checks

Commit first (`Phase <N>: courier game — stage at /play/`), because
`make site-check` fails on uncommitted changes under `content/`. Then:

```bash
make check
make site-build
make site-check
```

All three succeed. `make site-check` walks `site/public/play/index.html`, so it
also proves the page's own links resolve. (Card links are created by
JavaScript and are covered by the Phase 1 card link test instead.)

Then `make site-preview` and open `http://localhost:8766/play/`. Play one round
and follow one card link; it must open the card page.

If `make site-build` fails for a reason unrelated to `game/` (missing
`site/node_modules`, for example), run `cd site && npm ci` once and retry. If
it still fails, stop and report the error text.

---

## Done means

- `node --test game/*.test.js`, `make check`, `make site-build` and
  `make site-check` all pass.
- Four commits on `courier-game`, one per phase, nothing pushed.
- A report listing: the four commit hashes, any check that could not be run and
  why, and anything in this plan that turned out to be wrong or ambiguous.

## Not in this plan

Later seats (Reader, Gate, Bridge, Keeper), a persistent town, saved progress,
multiplayer, sound, and any change to chapter prose. Do not start them.
