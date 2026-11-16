# The Keeper — build plan (part five)

The fifth and last short browser game for *Lossy*, published at
`lossybook.com/play/keeper.html` and reached from the end of the Bridge. The
player keeps a library through four generations, spending each generation's
funds on copying the texts (preservation) or teaching readers (training). The
archive fades slowly; every reader retires each generation. A patron offers an
endowment at the start; in generation 3 a summary engine offers easy readers
who cannot read the texts.

Book material: the preservation and training pair, differential decay rates and
the capture asymmetry (Ch. 8), funding outside the attention market and the work
of generations (Ch. 12).

Same rules as the earlier plans (`game/PLAN.md`, `DESK-PLAN.md`,
`READER-PLAN.md`, `BRIDGE-PLAN.md`): every piece of text, every number and every
rule is fixed below; copy them exactly.

## Rules for the executor

1. Do the phases in order; do not start one until the previous one's checks pass.
2. Copy all game text and numbers verbatim. Add nothing.
3. No dependencies, no build step, no network requests, no `localStorage`.
4. Touch only the files this plan names. Never edit `data/` or chapter prose.
5. If a check fails and the fix is not obvious, or a quote test fails, **stop and
   report**. Never change a quote or an expected value to make a test pass;
   every expected value was computed by a reference implementation.
6. Do not push, merge, or open a pull request.

## Setup

The Keeper builds on the Bridge, which may not be merged yet:

```bash
git fetch origin
git switch -c keeper-game origin/bridge-game
git log --oneline -1
```

Number commits from the last `Phase N:` as `Phase <number>: keeper game — <what>`,
ending each message with a blank line and the `Co-Authored-By:` trailer the
session gives you.

## Files

```
game/
  KEEPER-PLAN.md    this file (already exists)
  keeper-data.js    Phase 1
  keeper-engine.js  Phase 1  pure logic and state machine, no DOM
  keeper.test.js    Phase 1
  keeper.html       Phase 2
  keeper-ui.js      Phase 2
```

No CSS changes: reuse the classes already in `courier.css`.

## The model

All numbers live in `RULES` and `FUNDING` in the data file.

- The player first picks a **funding**: `endowed` or `donations`. A
  generation's funds are `FUNDING[funding].funds[g - 1]`, plus `offerBonus` in
  the offer generation if the player accepted the summary engine.
- In generation `offerGeneration` (3), before spending, the player accepts or
  declines the **summary engine**.
- Each generation the player picks `copy` from 0 to the funds; `teach` is the
  rest. Then, from the previous generation's `archive` and `readers` (the
  starting values are `archiveStart` and `readersStart`):
  - `archive` = clamp to 0–100 of (previous archive − `archiveDecay` + `copyGain` × copy);
  - if this is the offer generation and the engine was accepted:
    `readers = 0` and `summary = summaryPerPoint × teach`;
  - otherwise `readers = min(teach, studentsPerReader × previous readers)` and
    `summary = 0`.
- After generation 4, the **verdict**: `kept` if archive ≥ `keepArchive` and
  readers ≥ `keepReaders`; `locked` if only the archive is; `nobooks` if only
  the readers are; else `lost`.

---

## Phase 1 — data, engine, tests

### 1a. `game/keeper-data.js`

Create the file with exactly this content.

```js
// The Keeper — all game content. Text and numbers are fixed by game/KEEPER-PLAN.md.
// Funds, decay and reader counts are invented to show a shape; they are not data.

export const RULES = {
  generations: 4,
  archiveStart: 100,     // percent of the full texts still legible
  archiveDecay: 25,      // lost each generation
  copyGain: 10,          // regained per point spent copying (archive never exceeds 100 or drops below 0)
  readersStart: 2,       // people who can read the full texts when you start
  studentsPerReader: 2,  // each reader can teach at most this many students
  offerGeneration: 3,    // the generation in which the summary engine makes its offer
  offerBonus: 2,         // extra funds that generation if you accept
  summaryPerPoint: 2,    // summary readers per teaching point if you accept
  keepArchive: 40,       // at the end, an archive at or above this counts as kept
  keepReaders: 2,        // at the end, this many full readers or more counts as kept
};

export const FUNDING = {
  endowed: {
    label: 'Take the endowment',
    about: 'This generation gets less to spend. Every generation after it is paid for.',
    funds: [3, 4, 4, 4],
  },
  donations: {
    label: 'Live off donations',
    about: 'More to spend now. Donations shrink as the feeds take your readers’ evenings.',
    funds: [5, 4, 3, 2],
  },
};

export const OUTCOMES = {
  kept: { title: 'The books and their readers both made it',
    text: 'There are still full texts on the shelves and people who can read them, and teach the next ones. You did not beat the age you lived in. You outlasted it.' },
  locked: { title: 'A library nobody can read',
    text: 'The archive held. The readers did not. The books are still there, and the people who could open them are gone.' },
  nobooks: { title: 'Readers without books',
    text: 'You kept training readers, and the texts they were trained on crumbled. They are teaching from memory now, and memory drifts.' },
  lost: { title: 'Both gone',
    text: 'The texts crumbled and the readers retired without successors.' },
};

export const CARDS = [
  { id: 'preservation-vs-training-pair', title: 'Two jobs, not one', href: '../concepts/preservation-vs-training-pair',
    text: 'Keeping hard knowledge alive takes an archive and people who can read it. Either alone fails: an archive nobody can read might as well be empty.' },
  { id: 'institutional-decay-rates', title: 'Books fade, readers retire', href: '../concepts/institutional-decay-rates',
    text: 'Your archive lost a quarter a generation. Your readers were all gone each generation unless you had trained new ones. Training is the half that decays fast.' },
  { id: 'capture-asymmetry', title: 'The corrupted generation', href: '../concepts/capture-asymmetry',
    text: 'Had the summary engine taught a generation, its students could not have read the books, or taught anyone who could. A bad copy can be replaced from another; a generation cannot.' },
  { id: 'work-of-generations', title: 'The work of generations', href: '../concepts/work-of-generations',
    text: 'Nothing you did paid off inside one generation. Institutions that hold hard knowledge are built, and lost, on that timescale.' },
];

// Verbatim from the chapters. keeper.test.js checks each against its source file.
export const QUOTES = {
  corrupted: {
    text: 'You can replace a corrupted book; you cannot replace a corrupted generation, not quickly and not from outside.',
    attr: 'Lossy, Ch. 8', source: 'content/preservation-vs-training.md',
  },
  outlast: {
    text: 'They never beat the dark age. They just outlasted it.',
    attr: 'Lossy, Ch. 12', source: 'content/infrastructure-for-integration.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part five',
    title: 'The Keeper',
    body: 'You keep a library through four generations. Each generation you spend its funds on copying the old texts before they crumble, or on teaching people who can read them. Every generation, a quarter of the archive fades and every reader retires. Each reader can teach at most two students.',
    button: 'Open the library',
  },
  fund: {
    heading: 'Before the first generation',
    body: 'A patron offers an endowment.',
  },
  offer: {
    heading: 'Generation 3: an offer',
    body: 'A company offers its summary engine. Put a point into teaching and it trains two readers, no teachers needed, and it adds 2 to your funds this generation. Its students learn the summaries, not the texts.',
    accept: 'Use the summary engine',
    decline: 'Keep teaching from the texts',
  },
  gen: {
    heading: 'Generation {n}',
    status: 'Funds: {p} · Archive: {a}% · Readers: {r}',
    pick: 'How do you spend the funds?',
    split: 'Copy {c} · Teach {t}',
    engine: 'The summary engine is teaching this generation.',
  },
  result: {
    heading: 'Generation {n}: what is left',
    archive: 'The archive stands at {a}%.',
    readers: '{r} people can read the full texts.',
    summary: '{s} people learned from the summaries. They cannot read the texts, or teach anyone who can.',
    locked: 'The books are on the shelves. Nobody left can read them.',
    crumbled: 'The last legible copies have crumbled.',
    next: 'Next generation',
    last: 'See what is left',
  },
  verdict: {
    heading: 'Four generations on',
    ledger: 'The ledger',
    row: 'Generation {n}: copy {c}, teach {t} → archive {a}%, readers {r}',
    rowSummary: 'Generation {n}: copy {c}, teach {t} → archive {a}%, readers {r}, summary readers {s}',
    cards: 'New cards',
    button: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Where is the full version of what I rely on kept, and who can still read it?',
      'Who is being trained to read it next, and who pays for that?',
      'When something offers to teach faster, what does it teach from?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Every number is invented to show a shape. Real archives can rot fast and real apprenticeships can last centuries; the book calls its rule of thumb a rule of thumb.',
      'The summary engine stands for any teaching that replaces the source, not for any one product.',
      'Four generations is a short run. The book’s timescale is universities and cathedrals.',
    ],
    replay: 'Keep the library again',
    links: [
      { label: 'Back to Courier', href: './' },
      { label: 'The Bridge', href: './bridge.html' },
      { label: 'Read Chapter 8', href: '../preservation-vs-training' },
      { label: 'Read Chapter 12', href: '../infrastructure-for-integration' },
    ],
  },
};
```

### 1b. `game/keeper-engine.js`

Pure ES module importing only from `./keeper-data.js`. No DOM, no globals, no
randomness. Never mutate an input.

| Export | Returns |
|---|---|
| `funds(fundingId, g, accepted)` | per **The model** (`g` is 1-based) |
| `nextGeneration(prev, fundingId, g, accepted, copy)` | `{ g, funds, copy, teach, archive, readers, summary }`; throws `new Error('bad copy')` unless `copy` is an integer from 0 to the funds |
| `verdict(last)` | `'kept' \| 'locked' \| 'nobooks' \| 'lost'` from a generation record |
| `current(state)` | the last ledger entry, or `{ archive: RULES.archiveStart, readers: RULES.readersStart }` when the ledger is empty |
| `initialState()` | see below |
| `step(state, action)` | see below |

```js
initialState() === {
  screen: 'intro',   // intro | fund | offer | gen | result | verdict | end
  funding: null,
  g: 1,              // the generation being played
  accepted: false,   // whether the summary engine was accepted
  ledger: [],        // one nextGeneration() record per generation played
  cards: [],
  newCards: [],
}
```

Any action not listed for the current screen, or with an invalid id or value,
returns the same state object.

| Screen | Action | Effect |
|---|---|---|
| `intro` | `START` | `screen = 'fund'` |
| `fund` | `PICK_FUNDING` `{ id }` | if `id` is a key of `FUNDING`: `funding = id`, `g = 1`, `screen = 'gen'` |
| `offer` | `ACCEPT` | `accepted = true`, `screen = 'gen'` |
| `offer` | `DECLINE` | `accepted = false`, `screen = 'gen'` |
| `gen` | `SPEND` `{ copy }` | if valid: append `nextGeneration(current(state), funding, g, accepted, copy)` to `ledger`, `screen = 'result'` |
| `result` | `NEXT` | if `g < RULES.generations`: `g + 1`, and `screen = 'offer'` if the new `g` is `RULES.offerGeneration`, else `'gen'`. Otherwise `newCards` = every card id not already in `cards`, appended to `cards`; `screen = 'verdict'` |
| `verdict` | `NEXT` | `screen = 'end'` |
| `end` | `REPLAY` | `{ ...initialState(), screen: 'fund' }` |

### 1c. `game/keeper.test.js`

- **Every path.** Enumerate every funding, accept/decline, and every `copy`
  choice in each generation: exactly 2100 paths. Verdict counts by
  funding:decision: `endowed:decline` kept 111, locked 351, nobooks 33, lost 5;
  `endowed:accept` locked 662, lost 38; `donations:decline` kept 36, locked 279,
  nobooks 24, lost 21; `donations:accept` locked 495, lost 45. No accepted path
  is `kept`.
- **Playthroughs** (copy per generation → `copy/teach/archive/readers/summary`
  per generation, then the verdict):
  - A: endowed, decline, copies `[1,2,2,2]` → `1/2/85/2/0`, `2/2/80/2/0`,
    `2/2/75/2/0`, `2/2/70/2/0` → `kept`.
  - B: endowed, accept, copies `[1,2,2,2]` → `1/2/85/2/0`, `2/2/80/2/0`,
    `2/4/75/0/8`, `2/2/70/0/0` → `locked`.
  - C: donations, decline, `[5,4,3,2]` → `5/0/100/0/0`, `4/0/100/0/0`,
    `3/0/100/0/0`, `2/0/95/0/0` → `locked`.
  - D: donations, decline, `[0,0,0,0]` → `0/5/75/4/0`, `0/4/50/4/0`,
    `0/3/25/3/0`, `0/2/0/2/0` → `nobooks`.
  Run A and B through `step` as well (`START`, `PICK_FUNDING`, `SPEND`/`NEXT`
  per generation, with `ACCEPT` or `DECLINE` on the offer screen before
  generation 3): assert the offer screen appears exactly once, after
  generation 2; at the verdict `newCards.length === 4`; at the end
  `screen === 'end'` and `ledger.length === 4`.
- **Edge cases.** `SPEND` with `copy` above the funds, negative, or not an
  integer returns the same state object; `nextGeneration` throws on the same;
  `PICK_FUNDING` with an unknown id returns the same state object; `REPLAY`
  gives `screen === 'fund'` with an empty ledger and cards; both step
  playthroughs also run deep-frozen.
- **Invariants.** `FUNDING.endowed.funds` and `FUNDING.donations.funds` each
  have `RULES.generations` entries; `OUTCOMES` has exactly the four verdict
  keys; card ids unique.
- **Quote check** and **card link check**: exactly as in `courier.test.js`.

Checks: `node --test game/*.test.js` (all five games pass). Commit
`Phase <N>: keeper game — data, engine, tests`, including this plan.

---

## Phase 2 — the playable page

`game/keeper.html`: same shape as `game/bridge.html`, with title
`The Keeper — a game from Lossy`, header word `The Keeper`, script
`./keeper-ui.js`.

`game/keeper-ui.js` imports `{ RULES, FUNDING, OUTCOMES, CARDS, QUOTES, COPY }`
from `./keeper-data.js` and `* as engine` from `./keeper-engine.js`. Copy the
helpers from `bridge-ui.js` (`fill`, `h` with its disabled-click guard,
`dispatch` with its focus rule, `title`, `btn`, `card`, `quote`); use
`viewKey = (s) => \`${s.screen}:${s.g}\``. All numbers shown come from the
engine or `RULES`/`FUNDING`; the UI computes nothing.

| Screen | Shows | Buttons |
|---|---|---|
| `intro` | `kicker`, `title` as `<h1>`, `body` | `COPY.intro.button` → `START` |
| `fund` | `COPY.fund.heading` as `<h1>`, `body` | one `.item` per funding in a `.stack`: `label` bold, `about`, then the funds per generation as a mono line (`3 · 4 · 4 · 4`) → `PICK_FUNDING` |
| `offer` | `COPY.offer.heading` as `<h1>`, a `.status` line as on the gen screen (using generation 3's funds *without* the bonus), `body` | `accept` → `ACCEPT`, `decline` → `DECLINE` |
| `gen` | `COPY.gen.heading` as `<h1>`; a `.status` line from `COPY.gen.status` (`p` = this generation's funds, `a`/`r` from `engine.current(state)`); if this is the offer generation and `accepted`, `COPY.gen.engine`; `COPY.gen.pick` as `<h2>` | one button per copy value 0..funds in a `.stack`, labelled `COPY.gen.split` → `SPEND { copy }` |
| `result` | `COPY.result.heading` as `<h1>`; `archive`; `readers`; `summary` when the record's `summary > 0`; `locked` when readers is 0 and archive > 0; `crumbled` when archive is 0 | `COPY.result.last` after generation 4, else `COPY.result.next` → `NEXT` |
| `verdict` | `COPY.verdict.heading` as `<h1>`; the verdict's `OUTCOMES` `title` as `<h2>` and `text`; `COPY.verdict.ledger` as `<h3>` and one line per ledger record (`row`, or `rowSummary` when `summary > 0`) in a list; the `corrupted` quote, then the `outlast` quote; `COPY.verdict.cards` as `<h2>` and the new cards | `COPY.verdict.button` → `NEXT` |
| `end` | `COPY.end.heading` as `<h1>`; the questions as an ordered list; `cutHeading` and the cut lines as a list | `COPY.end.replay` → `REPLAY`; the four links as plain links |

Checks: `node --test game/*.test.js`, `node --check game/keeper-ui.js`, and
`grep -n innerHTML game/keeper-ui.js` printing nothing. The reviewer does the
browser checks; leave Phase 2 uncommitted unless told otherwise.

---

## Phase 3 — wire it up

1. `game/bridge-data.js`: in `COPY.end.links`, insert first:
   `{ label: 'Next: keep the library', href: './keeper.html' },`
2. `Makefile` `play-stage`: append
   `game/keeper.html game/keeper-data.js game/keeper-engine.js game/keeper-ui.js`
   before `site/public/play/`.
3. `content/index.md`, in the line starting `- **<a href="./play/"`: replace
   `between two towns that don't trust each other.` with
   `between two towns that don't trust each other, and keep a library alive for four generations.`
4. `game/README.md`: add `## Part five: the Keeper` and the keeper files to the
   layout tree.

Commit `Phase <N>: keeper game — link from the Bridge, stage at /play/`, then
run `make check`, `make site-build`, `make site-check`.

## Not in this plan

Saved progress across the five parts, and any change to chapter prose.
