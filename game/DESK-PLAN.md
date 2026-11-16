# The Desk — build plan (Courier, part two)

A second short browser game for *Lossy*, published at `lossybook.com/play/desk.html`
and reached from the end of Courier. In Courier the player cut the key at each
hand-off. In the Desk the player *is* the gate: each day the wire sends six
stories, the desk can run three, and the landlord takes rent in attention. The
rent rises until careful stories alone can't pay it. After four days an audit
shows what readers came away believing. On day 5 a library pays the rent.

Book material: selection as a choice (Ch. 5b), the engagement equilibrium and
Goodhart's law (Ch. 10), out-competition of careful carriers, and funding
outside the attention market, survival not victory (Ch. 12).

This plan follows the same rules as `game/PLAN.md`. Every piece of game text,
every number and every rule is fixed below. Copy them exactly.

## Rules for the executor

1. Do the phases in order. Do not start a phase until the previous phase's
   checks pass.
2. Copy all game text and numbers from this file verbatim. Do not reword,
   "improve", or add copy, days, stories or cards.
3. No dependencies, no build step, no network requests, no analytics, no
   `localStorage`. Plain HTML, CSS, and ES modules.
4. Touch only the files this plan names. Never edit `data/` or chapter prose.
5. If a check fails and the fix is not obvious from this plan, or a quote test
   fails, **stop and report**. Do not edit a chapter, a quote or an expected
   value to make a test pass. Every expected value below was computed by a
   reference implementation; if a test disagrees, the bug is in your code.
6. Do not push, merge, or open a pull request. Report when done.

## Setup (before Phase 1)

```bash
git fetch origin
git switch -c desk-game origin/main
git log --oneline -1
```

The last command prints the latest `Phase N:` commit. Number your commits
`N+1`, `N+2`, … in the form `Phase <number>: desk game — <what>`, and end each
message with a blank line and the `Co-Authored-By:` trailer the session gives
you.

## What gets built

```
game/
  DESK-PLAN.md      this file (already exists)
  desk-data.js      Phase 1  all content: days, stories, cards, quotes, copy
  desk-engine.js    Phase 1  pure logic and state machine, no DOM
  desk.test.js      Phase 1  node --test
  desk.html         Phase 2
  desk-ui.js        Phase 2  renders state, dispatches actions; nothing else
  courier.css       Phase 2  append a Desk section (shared stylesheet)
```

Phase 3 also edits `game/courier-data.js` (one link), `game/README.md`, the
`Makefile` and one line of `content/index.md`.

Design rule, as in Courier: **all behaviour lives in `desk-engine.js` as pure
functions**. `desk-ui.js` only draws state and turns clicks into actions.

## The model (read once, then implement)

- There are five **days**. Each day has six **stories**. The player picks
  exactly three to run.
- Every story has a `heat` from 1 to 5. Running it earns that much
  **attention** and reaches `REACH[heat]` readers.
- Each story also has `lands`: the stamp most readers come away with
  (`PRESERVED`, `INVERTED` or `FLAG`, the same stamps as Courier). The player
  never sees `lands` until the audit. The pick screen shows only headline and
  heat, which is the point: the meter shows attention, not truth.
- Days 1–4 have a **rent**. If the three stories' attention is below the rent,
  the desk takes a **strike**. Two strikes close the desk; play jumps to the
  audit.
- The **audit** comes after day 4, or straight after the day the desk closed.
  It reveals every story's stamp and totals the readers by stamp.
- Day 5 is **endowed**: rent 0, no strikes. Afterwards the player's day-5
  reach is compared with a **rival desk** that ran the three hottest stories.

---

## Phase 1 — data, engine, tests

### 1a. `game/desk-data.js`

Create the file with exactly this content.

```js
// The Desk — all game content. Text and numbers are fixed by game/DESK-PLAN.md.
// Attention, rent and reader counts are invented to show a shape; they are not data.

export const REACH = { 1: 20000, 2: 60000, 3: 200000, 4: 600000, 5: 1500000 };
export const PICKS = 3;
export const STRIKES_TO_CLOSE = 2;

export const DAYS = [
  {
    id: 'day1', rent: 4,
    brief: 'Quiet morning. The wire is mostly sound.',
    items: [
      { id: 'd1a', heat: 1, lands: 'PRESERVED', headline: 'Bigger study finds no hormone effect from power posing',
        note: 'The replication, with its key: 200 people, no effect.' },
      { id: 'd1b', heat: 4, lands: 'INVERTED', headline: 'COMPOUND X CAUSES CANCER',
        note: 'A mouse result at 1,000× the dose, read as a warning to you.' },
      { id: 'd1c', heat: 1, lands: 'PRESERVED', headline: 'Central bank raises rates by a quarter point',
        note: 'Dull, and roughly right.' },
      { id: 'd1d', heat: 5, lands: 'FLAG', headline: 'What they don’t want you to know about Compound X',
        note: 'Nobody is decoding a finding. Sharing it says whose side you are on.' },
      { id: 'd1e', heat: 2, lands: 'PRESERVED', headline: 'Compound X linked to tumours in mice, at doses far above human exposure',
        note: 'The finding with its key attached.' },
      { id: 'd1f', heat: 4, lands: 'INVERTED', headline: 'POWER POSING WAS A LIE',
        note: 'A true correction, read as “psychology is a scam”.' },
    ],
  },
  {
    id: 'day2', rent: 6,
    brief: 'The landlord raised the rent. The rival desk across the street is running hot.',
    items: [
      { id: 'd2a', heat: 2, lands: 'PRESERVED', headline: 'Two labs find no arsenic in the “arsenic-life” bacterium’s DNA',
        note: 'The field catching its own mistake, reported as that.' },
      { id: 'd2b', heat: 4, lands: 'INVERTED', headline: 'EGGS ARE KILLING YOU',
        note: 'One confounded association, read as a verdict.' },
      { id: 'd2c', heat: 1, lands: 'PRESERVED', headline: 'Eggs and heart risk: new study finds a small association; confounders not ruled out',
        note: 'The finding with its hedges.' },
      { id: 'd2d', heat: 5, lands: 'FLAG', headline: 'Eggs: the food the experts want to ban',
        note: 'A team flag about experts, not a claim about eggs.' },
      { id: 'd2e', heat: 2, lands: 'PRESERVED', headline: 'Stanford Prison Experiment: archival tapes show the guards were coached',
        note: 'The correction, intact.' },
      { id: 'd2f', heat: 3, lands: 'INVERTED', headline: 'Scientists say life can be built on arsenic',
        note: 'Refuted in 2012, still circulating as a finding.' },
    ],
  },
  {
    id: 'day3', rent: 8,
    brief: 'Rent is up again. Your readers are drifting to the rival.',
    items: [
      { id: 'd3a', heat: 1, lands: 'PRESERVED', headline: 'Health agency now recommends cloth face coverings as evidence on airborne spread grows',
        note: 'A field updating on evidence, said plainly.' },
      { id: 'd3b', heat: 4, lands: 'INVERTED', headline: 'THE FED IS PRINTING MONEY',
        note: 'Several separate mechanisms collapsed into one household image.' },
      { id: 'd3c', heat: 2, lands: 'PRESERVED', headline: 'What “printing money” does and doesn’t mean: the central bank’s balance sheet, explained',
        note: 'The long version. Few finish it.' },
      { id: 'd3d', heat: 3, lands: 'INVERTED', headline: 'Experts flip-flop on masks again',
        note: 'A field updating, read as a field that knows nothing.' },
      { id: 'd3e', heat: 1, lands: 'PRESERVED', headline: 'Why the Stanford Prison Experiment’s correction still isn’t in most textbooks',
        note: 'True, and nobody clicks.' },
      { id: 'd3f', heat: 5, lands: 'FLAG', headline: 'Masks never worked, and they knew',
        note: 'A side to stand on.' },
    ],
  },
  {
    id: 'day4', rent: 10,
    brief: 'Last day of the month. Rent is at its highest.',
    items: [
      { id: 'd4a', heat: 2, lands: 'PRESERVED', headline: 'Power posing’s lead author says she no longer believes the effects are real',
        note: 'The cleanest correction a field can give. Low reach.' },
      { id: 'd4b', heat: 4, lands: 'INVERTED', headline: 'Science confirms: power posing makes you feel more powerful!',
        note: 'Only the feeling survived the replication. The headline says the study held up.' },
      { id: 'd4c', heat: 1, lands: 'PRESERVED', headline: 'Why nutrition headlines flip: single studies move, the overall picture moves slowly',
        note: 'The key for every nutrition story. Nobody shares keys.' },
      { id: 'd4d', heat: 5, lands: 'FLAG', headline: 'The scientists who lied to you about eggs, masks and power poses',
        note: 'Three corrections, recycled as proof that nobody can be trusted.' },
      { id: 'd4e', heat: 1, lands: 'PRESERVED', headline: 'Arsenic-life, ten years on: how science caught its own mistake',
        note: 'A success story. Successes don’t travel.' },
      { id: 'd4f', heat: 4, lands: 'INVERTED', headline: 'Your morning eggs are back on the menu, scientists say',
        note: 'The next turn of the whiplash, as confident as the last.' },
    ],
  },
  {
    id: 'day5', rent: 0, endowed: true,
    brief: 'A public library offers to pay your rent for a year, on one condition: you can never sell the desk. Today there is no rent. Run what you like.',
    items: [
      { id: 'd5a', heat: 1, lands: 'PRESERVED', headline: 'What the power-posing replication found, and what it didn’t',
        note: 'The finding and its key, at full length.' },
      { id: 'd5b', heat: 5, lands: 'INVERTED', headline: 'COMPOUND X IS IN YOUR CEREAL',
        note: 'A mouse result, now in your kitchen.' },
      { id: 'd5c', heat: 1, lands: 'PRESERVED', headline: 'How to read a nutrition headline: three questions',
        note: 'A key, handed over directly.' },
      { id: 'd5d', heat: 4, lands: 'FLAG', headline: 'Psychology’s dirty secret',
        note: 'A whole field as a team to be against.' },
      { id: 'd5e', heat: 2, lands: 'PRESERVED', headline: 'Compound X: what “carcinogenic in mice” does and doesn’t mean',
        note: 'The finding with its key attached.' },
      { id: 'd5f', heat: 3, lands: 'INVERTED', headline: 'Eggs are good for you now',
        note: 'The whiplash, one turn further.' },
    ],
  },
];

export const CARDS = [
  { id: 'algorithm-as-selection-engine', at: 'audit', title: 'You were the gate', href: '../concepts/algorithm-as-selection-engine',
    text: 'Six stories in, three out, every day. Whatever chooses is a gate, and the gate’s criteria decide what readers see. The rent set yours.' },
  { id: 'engagement-equilibrium', at: 'audit', title: 'The engagement trap', href: '../mechanisms/engagement-equilibrium',
    text: 'Nobody told you to run the hot stories. The rent did. When every desk pays the same rent, the hot stories win everywhere, and there is no villain to blame.' },
  { id: 'goodharts-law', at: 'audit', title: 'Goodhart’s law', href: '../concepts/goodharts-law',
    text: 'The meter measured attention, so attention is what you produced. Once a measure becomes the target, it stops telling you what you cared about.' },
  { id: 'out-competition-of-carriers', at: 'audit', title: 'Priced out', href: '../concepts/out-competition-of-carriers',
    text: 'The careful desk is not censored. It is out-competed: the hot story costs the same to run and brings in more.' },
  { id: 'funding-decoupling', at: 'final', title: 'Funding outside the feed', href: '../concepts/funding-decoupling',
    text: 'With the rent gone, you could run the careful stories. Change who pays, and you change what the gate selects.' },
  { id: 'survival-not-victory', at: 'final', title: 'Survival, not victory', href: '../concepts/survival-not-victory',
    text: 'The endowed desk reached a fraction of the rival’s readers. It did not win. It lasted, and kept the careful version in print.' },
];

// Verbatim from the chapters. desk.test.js checks each against its source file.
export const QUOTES = {
  proxy: {
    text: 'engagement is a proxy for revenue, dressed up as a proxy for user benefit',
    attr: 'Lossy, Ch. 10', source: 'content/political-economy-of-attention.md',
  },
  captor: {
    text: 'You can fight a captor; you cannot fight an equilibrium.',
    attr: 'Lossy, Ch. 10', source: 'content/political-economy-of-attention.md',
  },
  outlast: {
    text: 'They never beat the dark age. They just outlasted it.',
    attr: 'Lossy, Ch. 12', source: 'content/infrastructure-for-integration.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part two',
    title: 'The Desk',
    body: 'You run a news desk. Each day the wire sends six stories and you can run three. The landlord takes rent in attention. Miss the rent twice and the desk closes.',
    button: 'Open the desk',
  },
  brief: {
    heading: 'Day {n}',
    status: 'Rent: {rent} attention · Strikes: {strikes} of 2',
    statusEndowed: 'Rent: none · The library pays',
    button: 'See the wire',
  },
  pick: {
    heading: 'Day {n}: pick three',
    count: '{k} of 3 picked',
    meter: 'Attention: {a} / rent {rent}',
    meterEndowed: 'Attention: {a} · no rent today',
    heat: 'attention +{heat}',
    short: 'Short by {k}. You can run it anyway and take a strike.',
    button: 'Run these three',
  },
  day: {
    heading: 'Day {n}: the numbers',
    earned: 'Attention earned: {a}. Rent: {rent}.',
    paid: 'Rent paid.',
    missed: 'Rent missed. Strike {s} of 2.',
    reach: 'Readers reached: {reach}',
    closed: 'Two strikes. The desk is closed, and the rival desk takes your readers.',
    button: 'Next',
  },
  audit: {
    heading: 'The audit',
    survived: 'Your desk made it through the month.',
    closed: 'Your desk closed on day {d}.',
    meter: 'The meter counted attention. It never counted what readers came away believing. Here is what they believed.',
    dayHeading: 'Day {n}',
    summary: '{inv} readers came away believing something the evidence doesn’t support. {flag} more read a story as a team flag.',
    summaryClean: 'Every story you ran landed roughly right. That is why the desk closed.',
    cards: 'New cards',
    button: 'Next: a different landlord',
  },
  final: {
    heading: 'Day 5: the endowed desk',
    yours: 'Your desk reached {reach} readers.',
    rival: 'The rival desk ran the three hottest stories and reached {reach}.',
    yoursLabel: 'Your desk',
    rivalLabel: 'The rival desk',
    cards: 'New cards',
    button: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Who chose this story for me, and what are they paid in?',
      'What would this outlet have to run to make its rent tomorrow?',
      'Which of the sources I trust are paid for by something other than my attention?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Every number is invented to show a shape. The headlines come from the book’s cases; Compound X is its made-up example.',
      'Real editors have standards, and many hold them. The game shows the pull of the rent, not a verdict on any newsroom.',
      'An endowment is one way out of the attention market. Chapter 12 weighs others, and admits it has not shown they can pay for everything.',
    ],
    replay: 'Run the desk again',
    links: [
      { label: 'Back to Courier', href: './' },
      { label: 'Read Chapter 10', href: '../political-economy-of-attention' },
      { label: 'Read Chapter 12', href: '../infrastructure-for-integration' },
    ],
  },
};
```

### 1b. `game/desk-engine.js`

Pure ES module. Imports only from `./desk-data.js`. No DOM, no globals, no
randomness, no dates. Never mutate an input; always return new objects.

Export these functions with exactly these names and behaviours.

| Function | Returns |
|---|---|
| `getDay(id)` | the day object with that id |
| `attention(day, ids)` | sum of `heat` of the day's items whose id is in `ids` |
| `outcome(day, ids)` | see below |
| `rivalPicks(day)` | ids of the 3 items with the highest `heat`; ties go to the item earlier in the file; returned in file order |
| `totals(outcomes)` | object mapping each stamp to the sum of that stamp's tally across the outcomes (only stamps that occur) |
| `audit(state)` | `{ survived: state.closedOn === null, closedOn: state.closedOn, entries, totals }`, where `entries` = ledger entries whose day is not endowed, and `totals = totals(entries)` |
| `initialState()` | see state machine |
| `step(state, action)` | the next state; see state machine |

**`outcome(day, ids)`**

1. If `ids` does not contain exactly `PICKS` distinct ids that are all items
   of `day`, throw `new Error('bad picks')`.
2. `items` = the day's items whose id is in `ids`, **in file order**.
3. Return:

```js
{
  dayId: day.id,
  picks: items.map(i => i.id),
  attention: /* sum of heat */,
  rent: day.rent,
  paid: attention >= day.rent,
  reach: /* sum of REACH[heat] */,
  tallies: /* stamp -> sum of REACH[heat] over items with that lands */,
}
```

**State machine**

```js
initialState() === {
  screen: 'intro',   // intro | brief | pick | day | audit | final | end
  dayIndex: 0,       // index into DAYS
  picked: [],        // ids picked on the current pick screen, in file order
  strikes: 0,
  closedOn: null,    // day number (1-based) the desk closed, or null
  ledger: [],        // one outcome per day run, plus { strike: boolean }
  current: null,     // the outcome of the day just run
  cards: [],         // unlocked card ids, in unlock order
  newCards: [],      // card ids unlocked by the screen just reached
}
```

`step(state, action)` where `action` is `{ type, ... }`. Any action not listed
for the current screen returns the state unchanged (the same object).

| Screen | Action | Effect |
|---|---|---|
| `intro` | `START` | `screen = 'brief'`, `dayIndex = 0` |
| `brief` | `SEE_WIRE` | `screen = 'pick'`, `picked = []` |
| `pick` | `TOGGLE` `{ id }` | ignore ids not in the day. If `id` is in `picked`, remove it. Otherwise add it only if `picked.length < PICKS`. Keep `picked` in item file order |
| `pick` | `RUN` | if `picked.length !== PICKS`: unchanged. Otherwise `out = outcome(day, picked)` and see **run** below |
| `day` | `NEXT` | if `closedOn !== null` or `dayIndex === 3`: **unlock**(`'audit'`), `screen = 'audit'`. Otherwise `dayIndex + 1`, `screen = 'brief'` |
| `audit` | `NEXT` | `dayIndex = 4`, `screen = 'brief'` |
| `final` | `NEXT` | `screen = 'end'` |
| `end` | `REPLAY` | `{ ...initialState(), screen: 'brief' }` |

**run**:
- If the day is `endowed`: append `{ ...out, strike: false }` to `ledger`,
  `current = out`, **unlock**(`'final'`), `screen = 'final'`.
- Otherwise: `strike = !out.paid`. `strikes` goes up by 1 if `strike`. If
  `strikes` is now `>= STRIKES_TO_CLOSE`, `closedOn = dayIndex + 1`. Append
  `{ ...out, strike }` to `ledger`, `current = out`, `screen = 'day'`.

**unlock(at)**: `newCards` = ids of `CARDS` whose `at` equals `at` and that are
not already in `cards`, in file order; append them to `cards`.

### 1c. `game/desk.test.js`

Use `node:test` and `node:assert/strict`.

**Outcome table.** Each row must match exactly (`attention`, `paid`, `reach`,
and `tallies` deep-equal).

| Day | Picks | Attention | Paid | Reach | Tallies |
|---|---|---|---|---|---|
| day1 | d1a d1c d1e | 4 | true | 100000 | PRESERVED 100000 |
| day2 | d2a d2c d2e | 5 | false | 140000 | PRESERVED 140000 |
| day2 | d2a d2e d2f | 7 | true | 320000 | PRESERVED 120000, INVERTED 200000 |
| day3 | d3a d3c d3e | 4 | false | 100000 | PRESERVED 100000 |
| day3 | d3a d3c d3f | 8 | true | 1580000 | PRESERVED 80000, FLAG 1500000 |
| day4 | d4a d4b d4f | 10 | true | 1260000 | PRESERVED 60000, INVERTED 1200000 |
| day4 | d4b d4d d4f | 13 | true | 2700000 | INVERTED 1200000, FLAG 1500000 |
| day5 | d5a d5c d5e | 4 | true | 100000 | PRESERVED 100000 |
| day5 | d5b d5d d5f | 12 | true | 2300000 | INVERTED 1700000, FLAG 600000 |

Also: `outcome(day1, ['d1a','d1c'])` throws; `outcome(day1, ['d1a','d1c','d2a'])`
throws; `rivalPicks(getDay('day5'))` deep-equals `['d5b','d5d','d5f']`;
`rivalPicks(getDay('day1'))` deep-equals `['d1b','d1d','d1f']`.

**The squeeze** (this is the game's design; it must hold):

- Day 1: some set of three `PRESERVED` stories pays the rent.
- Days 2 and 3: no set of three `PRESERVED` stories pays the rent, and some set
  with exactly one non-`PRESERVED` story does.
- Day 4: no set with fewer than two non-`PRESERVED` stories pays the rent.
- For every day and every set of three stories, `reach` equals the sum of the
  tallies, and `paid === (attention >= rent)`.

**Data invariants.** Each day has six items; item ids are unique across all
days; every `heat` is a key of `REACH`; every `lands` is a key of `STAMPS`
imported from `./courier-data.js`; card ids are unique; every card's `at` is
`'audit'` or `'final'`; only day 5 is `endowed` and its rent is 0.

**Quote check** and **card link check**: exactly as in `courier.test.js`
(normalise the chapter text, then require each quote verbatim; each card href
minus `../` must exist as `content/<path>.md`).

**Playthrough A, the careful desk.** From `initialState()`, apply with `step`:

```
START
SEE_WIRE · TOGGLE d1a · TOGGLE d1c · TOGGLE d1e · RUN    → day (paid)
NEXT
SEE_WIRE · TOGGLE d2a · TOGGLE d2c · TOGGLE d2e · RUN    → day (strike 1)
NEXT
SEE_WIRE · TOGGLE d3a · TOGGLE d3c · TOGGLE d3e · RUN    → day (strike 2, closed)
NEXT                                                     → audit
NEXT                                                     → brief (day 5)
SEE_WIRE · TOGGLE d5a · TOGGLE d5c · TOGGLE d5e · RUN    → final
NEXT                                                     → end
```

Assert: after the third `RUN`, `strikes === 2` and `closedOn === 3`; after the
`NEXT` that follows it, `screen === 'audit'`, `newCards.length === 4` and
`audit(state)` deep-equals
`{ survived: false, closedOn: 3, entries: <the 3 ledger entries>, totals: { PRESERVED: 340000 } }`;
after the next `NEXT`, `dayIndex === 4`; at the end, `screen === 'end'`,
`ledger.length === 4`, `cards.length === 6`.

**Playthrough B, the desk that pays.** Same shape, but run all four days with
picks `d1a d1c d1e`, `d2a d2e d2f`, `d3a d3c d3f`, `d4a d4b d4f`, then day 5
with `d5a d5c d5e`. Assert: `strikes === 0`, `closedOn === null`, the audit
comes after day 4, `audit(state).survived === true`, and `audit(state).totals`
deep-equals `{ PRESERVED: 360000, INVERTED: 1400000, FLAG: 1500000 }`. At the
end `ledger.length === 5`.

**Edge cases.**
- On a pick screen with three picked, `TOGGLE` of a fourth item returns a state
  whose `picked` is unchanged.
- `RUN` with two picked returns the same state object.
- `TOGGLE` of a picked item removes it.
- `REPLAY` from the end state gives `screen === 'brief'`, `dayIndex === 0`,
  `ledger` empty, `cards` empty, `strikes === 0`, `closedOn === null`.
- Re-run both playthroughs with the state deep-frozen (recursive
  `Object.freeze`) before every `step` call; nothing throws.

### Phase 1 checks

```bash
node --test game/*.test.js
```

All tests pass: Courier's and the Desk's. Commit:
`Phase <N>: desk game — data, engine, tests` (include `game/DESK-PLAN.md`).

---

## Phase 2 — the playable page

### 2a. `game/desk.html`

Same shape as `game/index.html`, with these differences:

- `<title>The Desk — a game from Lossy</title>`
- The header's word is `The Desk` instead of `Courier`. The `← Lossy` link
  still points to `../`.
- The script is `./desk-ui.js`.
- The `<noscript>` line is the same as in `index.html`.

### 2b. Append to `game/courier.css`

Add a section at the end of the file, before the `prefers-reduced-motion`
block, headed `/* ---- The Desk ---- */`. Use only existing variables.

- `.item` (story buttons in a `.stack`): full width, left-aligned.
  `.item[aria-pressed="true"]` gets `border-color: var(--signal)` and
  `background: var(--bg-raise)`.
- `.item .headline`: block, `var(--serif)`, 18px. `.item .headline.caps`:
  `var(--sans)`, bold.
- `.item .heat`: block, `var(--mono)`, 13px, `color: var(--signal)`.
- `.status`: `var(--mono)`, 15px, `color: var(--ink-dim)`.
- `.story-line`: in the audit and final screens, one story per row: a
  `var(--serif)` headline, then a line with the stamp label and reach in
  `var(--mono)`, then the note in `var(--ink-dim)`. Separate rows with a
  1px `var(--wire)` top border and 10px padding.

### 2c. `game/desk-ui.js`

```js
import { DAYS, REACH, CARDS, QUOTES, COPY } from './desk-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './desk-engine.js';
```

Copy the helpers from `courier-ui.js`: `fill`, `h` (including its
disabled-click guard), `dispatch` (focus the `<h1>`, scroll to top), `title`,
`btn`, `fmt`, `isCaps`, `stampSpan`, `card` and `quote`. Do not import them
from `courier-ui.js`, which runs its game on import.

The day being shown is `DAYS[state.dayIndex]`; its number is
`state.dayIndex + 1`. The stamp order for every totals line is
`['INVERTED', 'FLAG', 'PRESERVED']`, skipping stamps with no tally.

Screens:

| Screen | Shows | Buttons |
|---|---|---|
| `intro` | `COPY.intro.kicker`, `title` as `<h1>`, `body` | `COPY.intro.button` → `START` |
| `brief` | `COPY.brief.heading` as `<h1>`; status line (`.status`): `COPY.brief.statusEndowed` if the day is endowed, else `COPY.brief.status`; the day's `brief` | `COPY.brief.button` → `SEE_WIRE` |
| `pick` | `COPY.pick.heading` as `<h1>`; count line; meter (`COPY.pick.meterEndowed` if endowed, else `COPY.pick.meter`; add class `over` when 3 are picked and attention < rent); the six stories as `.item` buttons in a `.stack`, each with a `.headline` span (add `caps` when all capitals) and a `.heat` span from `COPY.pick.heat`; `aria-pressed` reflects picked; an unpicked story is `disabled` while 3 are picked. If 3 are picked, the day is not endowed and attention < rent, show `COPY.pick.short` | `COPY.pick.button` → `RUN`, `disabled` unless exactly 3 are picked |
| `day` | `COPY.day.heading` as `<h1>`; the three run headlines as a list; `earned`; `paid` or `missed` (with `s = state.strikes`); `reach`; if `state.closedOn !== null`, `closed` | `COPY.day.button` → `NEXT` |
| `audit` | see below | `COPY.audit.button` → `NEXT` |
| `final` | see below | `COPY.final.button` → `NEXT` |
| `end` | `COPY.end.heading` as `<h1>`; the three questions as an ordered list; `cutHeading` and the cut lines as a list | `COPY.end.replay` → `REPLAY`; the three `COPY.end.links` as plain links |

Use `engine.attention` for every attention number; never add heat in the UI.

**Audit screen, top to bottom.** Get `a = engine.audit(state)`.

1. `COPY.audit.heading` as `<h1>`.
2. `survived`, or `closed` filled with `d = a.closedOn`.
3. `COPY.audit.meter`.
4. For each entry in `a.entries`: an `<h3>` from `dayHeading` (the day number
   is its index in `DAYS` + 1, found by `dayId`), then one `.story-line` per
   pick: headline, stamp label coloured by tone (`stampSpan`), the reach of
   that one story (`REACH[heat]`), and the note.
5. The totals line for `a.totals`.
6. If `a.totals.INVERTED` or `a.totals.FLAG` is present: `summary` with
   `inv` and `flag` (0 when absent), formatted. Otherwise `summaryClean`.
7. The `proxy` quote, then the `captor` quote.
8. If `state.newCards` is not empty: `COPY.audit.cards` as `<h2>`, then each
   new card.

**Final screen, top to bottom.**

1. `COPY.final.heading` as `<h1>`.
2. `COPY.final.yoursLabel` as `<h2>`, one `.story-line` per pick in
   `state.current`, then `yours` with `reach`.
3. `COPY.final.rivalLabel` as `<h2>`. `r = engine.outcome(day, engine.rivalPicks(day))`.
   One `.story-line` per rival pick, then `rival` with `r.reach`.
4. The `outlast` quote.
5. If `state.newCards` is not empty: `COPY.final.cards` as `<h2>`, then each
   new card.

### Phase 2 checks

```bash
node --test game/*.test.js
node --check game/desk-ui.js
grep -n innerHTML game/desk-ui.js    # must print nothing
```

The browser checks (play both playthroughs at `/game/desk.html` on a static
server, no console errors, no sideways scroll at 375px, keyboard-only play)
are done by the reviewer. Leave Phase 2 uncommitted unless told otherwise.

---

## Phase 3 — wire it up

1. **`game/courier-data.js`**: in `COPY.end.links`, insert as the **first**
   entry: `{ label: 'Next: run the desk', href: './desk.html' },`
2. **`Makefile`**, `play-stage` recipe: append
   `game/desk.html game/desk-data.js game/desk-engine.js game/desk-ui.js` to
   the `cp` line, before `site/public/play/`. The `test` and `check` targets
   already run `game/*.test.js`.
3. **`content/index.md`**: in the line that starts
   `- **<a href="./play/"`, replace
   `and see how they land.` with
   `and see how they land. Then run the desk that decides which stories travel at all.`
4. **`game/README.md`**: add a section `## Part two: the Desk` saying it lives
   at `desk.html` (published at `lossybook.com/play/desk.html`, reached from
   Courier's end screen), its five files, that `DESK-PLAN.md` is its plan, and
   that its tests are in `desk.test.js`. Add the desk files to the layout tree.

### Phase 3 checks

Commit first (`Phase <N>: desk game — link from Courier, stage at /play/`),
then:

```bash
make check
make site-build
make site-check
ls site/public/play/
```

All succeed, and `site/public/play/` lists the four desk files beside the
Courier ones. If `make site-build` changes committed files under `content/`,
stop and report them.

## Done means

- `node --test game/*.test.js`, `make check`, `make site-build` and
  `make site-check` pass.
- One commit per phase on `desk-game`, nothing pushed.
- A report listing the commit hashes, any check not run and why, and anything
  in this plan that was wrong or ambiguous.

## Not in this plan

Saved progress between Courier and the Desk, sound, multiplayer, the Reader,
Bridge and Keeper seats, and any change to chapter prose.
