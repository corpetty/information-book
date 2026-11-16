# The Reader — build plan (part three)

The third short browser game for *Lossy*, published at
`lossybook.com/play/reader.html` and reached from the end of the Desk. In
Courier the player cut the key; in the Desk the player was the gate. In the
Reader the player is at the end of the pipe. Claims arrive as memes, and the
player has a week's worth of focused minutes to believe them, shrug them off,
or trace them upstream: to the news, the field, the paper, and the
measurement. Each stop costs more than the last, so the skill is triage. In
week 2 a free assistant and a library tutor join the feed.

Book material: the five-stage pipeline and "raw data is the first
compression" (Ch. 1), the receiver budget (Ch. 3), open vigilance (Ch. 7),
legibility (Ch. 1 and the forestry case), and decompression on demand versus
the summary that replaces the source, plus corpus capture (Ch. 11).

This plan follows the same rules as `game/PLAN.md` and `game/DESK-PLAN.md`.
Every piece of game text, every number and every rule is fixed below. Copy
them exactly.

## Rules for the executor

1. Do the phases in order. Do not start a phase until the previous phase's
   checks pass.
2. Copy all game text and numbers from this file verbatim. Do not reword,
   "improve", or add copy, claims, weeks or cards.
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
git switch -c reader-game origin/main
git log --oneline -1
```

The last command prints the latest `Phase N:` commit. Number your commits
`N+1`, `N+2`, … in the form `Phase <number>: reader game — <what>`, and end
each message with a blank line and the `Co-Authored-By:` trailer the session
gives you.

## What gets built

```
game/
  READER-PLAN.md    this file (already exists)
  reader-data.js    Phase 1  all content: weeks, claims, cards, quotes, copy
  reader-engine.js  Phase 1  pure logic and state machine, no DOM
  reader.test.js    Phase 1  node --test
  reader.html       Phase 2
  reader-ui.js      Phase 2  renders state, dispatches actions; nothing else
  courier.css       Phase 2  append a Reader section (shared stylesheet)
```

Phase 3 also edits `game/desk-data.js` (one link), `game/README.md`, the
`Makefile` and one line of `content/index.md`.

Design rule, as before: **all behaviour lives in `reader-engine.js` as pure
functions**. `reader-ui.js` only draws state and turns clicks into actions.

## The model (read once, then implement)

- There are two **weeks**. Each has a minute budget and a list of **claims**.
- A claim has five **forms**, one per stop. `depth` 0 is the `meme` (what
  reaches you, "the feed"); depths 1–4 are `hops[0..3]` (the news, the field,
  the paper, the measurement). Each form has `text` and `lands`: the stamp a
  reader gets if they believe *having read down to that depth*. Knowledge
  accumulates, so a deeper form's `lands` is never worse because of what was
  above it.
- Going from depth `d` to `d + 1` costs `HOP_COST[d]` minutes, paid from the
  week's budget. The minutes to reach depth `d` from the top are
  `costToDepth(d)` = 0, 2, 7, 17, 32.
- On each claim the player chooses one route:
  - **believe** the form in front of them (at depth 0 this is "Believe it",
    deeper it is "Believe this version"), so belief = that form's `lands`;
  - **shrug** (depth 0 only), so belief = `BOUNCED`, shown as "No belief";
  - **trace** one stop further, if the minutes allow, then choose again;
  - in weeks with `tools`, at depth 0 only: ask the **free assistant**
    (0 minutes, belief = the claim's `assistant.lands`), or ask the **library
    tutor** (`TUTOR_COST` minutes, belief = the deepest form's `lands`).
- After the last claim of a week, a **reveal** shows each claim's route,
  minutes and belief, the lesson line, and two default readers for comparison.

---

## Phase 1 — data, engine, tests

### 1a. `game/reader-data.js`

Create the file with exactly this content.

```js
// The Reader — all game content. Text and numbers are fixed by game/READER-PLAN.md.
// Minutes and costs are invented to show a shape; they are not data.

// The stops on the way upstream. depth 0 is what reaches you; depth 4 is the measurement.
export const STOPS = ['the feed', 'the news', 'the field', 'the paper', 'the measurement'];

// HOP_COST[d] is the minutes it takes to go from depth d to depth d + 1.
export const HOP_COST = [2, 5, 10, 15];
export const TUTOR_COST = 4;

export const WEEKS = [
  {
    id: 'week1', minutes: 50, tools: false,
    brief: 'Five things reach you this week. You have 50 focused minutes to check them. Each stop upstream costs more than the last. You can believe what you see, shrug it off, or trace it.',
    claims: [
      {
        id: 'earth',
        meme: { text: 'The Earth goes around the Sun.', lands: 'PRESERVED' },
        hops: [
          { text: 'Astronomers confirm: Earth completes one orbit of the Sun about every 365.25 days.', lands: 'PRESERVED' },
          { text: 'Settled astronomy for centuries: the planets, Earth included, orbit the Sun on ellipses.', lands: 'PRESERVED' },
          { text: 'Kepler’s laws of planetary motion, fitted to decades of observations.', lands: 'PRESERVED' },
          { text: 'Tycho Brahe’s naked-eye records of planetary positions, and in 1838 the first measured stellar parallax.', lands: 'PRESERVED' },
        ],
        lesson: 'The short version was right. Tracing it would have cost minutes you needed elsewhere.',
      },
      {
        id: 'power',
        meme: { text: 'Stand like Wonder Woman for two minutes and you’ll ace the interview.', lands: 'INVERTED' },
        hops: [
          { text: 'TED talk: two minutes of “power posing” changes your hormones.', lands: 'INVERTED' },
          { text: 'A 200-person replication found no effect on hormones or behavior, and the original lead author disavowed the work.', lands: 'PRESERVED' },
          { text: 'The 2010 paper: 42 people; poses raised testosterone and lowered cortisol. You already know it didn’t replicate.', lands: 'PRESERVED' },
          { text: 'Saliva samples and risk-task scores from 42 participants.', lands: 'PRESERVED' },
        ],
        lesson: 'Two stops up, the field had already corrected it.',
      },
      {
        id: 'masks',
        meme: { text: 'Masks never worked, and they knew.', lands: 'FLAG' },
        hops: [
          { text: 'Health agency reverses early advice and recommends cloth face coverings as evidence on airborne spread grows.', lands: 'PRESERVED' },
          { text: 'The early advice bundled two things: saving scarce medical masks for hospitals, and an early reading of the evidence that favored droplets.', lands: 'PRESERVED' },
          { text: 'Evidence through spring 2020 made airborne spread clearer.', lands: 'PRESERVED' },
          { text: 'Outbreak reports and lab measurements of how the virus spreads, gathered in the first months of 2020.', lands: 'PRESERVED' },
        ],
        lesson: 'One stop up, the team flag turned back into a claim: advice that changed with the evidence.',
      },
      {
        id: 'eggs',
        meme: { text: 'EGGS ARE KILLING YOU', lands: 'INVERTED' },
        hops: [
          { text: 'Study links eating eggs to heart disease.', lands: 'INVERTED' },
          { text: 'Nutrition science: single diet studies find small, confounded associations; the overall picture moves slowly.', lands: 'PRESERVED' },
          { text: 'One cohort study: a small association between eggs and heart risk; confounders not ruled out.', lands: 'PRESERVED' },
          { text: 'Food questionnaires: people recalling what they ate, then followed for years.', lands: 'PRESERVED' },
        ],
        lesson: 'Two stops up: small, confounded, and one study among many.',
      },
      {
        id: 'forest',
        meme: { text: 'Old German forestry: tidy rows of spruce, more wood. Why don’t we do this everywhere?', lands: 'INVERTED' },
        hops: [
          { text: 'Historians: Prussian and Saxon foresters’ new plantations produced impressive timber yields.', lands: 'INVERTED' },
          { text: 'Forestry science of the time: a standardized tree let a forest’s wood be calculated and planned; managed plantations beat wild forest.', lands: 'INVERTED' },
          { text: 'The yield tables: the first rotation of planted spruce produced more saleable wood.', lands: 'INVERTED' },
          { text: 'The ledgers had columns for saleable wood, and none for underbrush, soil life or the mix of species. Losses of 20 to 30 percent came two or three generations later.', lands: 'PRESERVED' },
        ],
        lesson: 'Every stop above the measurement repeated the same mistake. Only the ledger shows what was never counted.',
      },
    ],
  },
  {
    id: 'week2', minutes: 10, tools: true,
    brief: 'A new week, and only 10 minutes. Two helpers are now on offer. The free assistant built into your feed answers instantly. The library’s tutor takes 4 minutes and walks you through the source.',
    claims: [
      {
        id: 'arsenic',
        meme: { text: 'NASA found alien life on Earth.', lands: 'INVERTED' },
        hops: [
          { text: 'NASA: a bacterium builds its DNA with arsenic.', lands: 'INVERTED' },
          { text: 'Two independent refutations: the bacterium’s DNA held no arsenic, and the original measurement was contaminated.', lands: 'PRESERVED' },
          { text: 'The 2010 paper in Science: a Mono Lake bacterium swaps arsenic for phosphorus. You already know it was refuted.', lands: 'PRESERVED' },
          { text: 'Arsenic readings from the DNA of cells grown in an arsenic-rich medium.', lands: 'PRESERVED' },
        ],
        assistant: { text: 'The 2010 “arsenic life” claim was refuted; later studies found no arsenic in the bacterium’s DNA.', lands: 'PRESERVED' },
        lesson: 'The free assistant gets this one right: the refutation is all over its training text.',
      },
      {
        id: 'prison',
        meme: { text: 'Give ordinary people power and they turn cruel. Stanford proved it.', lands: 'INVERTED' },
        hops: [
          { text: 'Stanford study: student guards turned abusive within days.', lands: 'INVERTED' },
          { text: '2018 archival work showed the guards were coached and a prisoner’s breakdown was performed; the field largely accepted the critique.', lands: 'PRESERVED' },
          { text: 'Zimbardo’s 1971 account of the experiment. You already know what the tapes showed.', lands: 'PRESERVED' },
          { text: 'Tapes and notes from the Stanford basement, reread in 2018.', lands: 'PRESERVED' },
        ],
        assistant: { text: 'The Stanford Prison Experiment (1971) showed that ordinary people can become abusive when given power over others.', lands: 'INVERTED' },
        lesson: 'Ask the free assistant and you get the textbook version, because that is most of what it read.',
      },
      {
        id: 'compoundx',
        meme: { text: 'COMPOUND X CAUSES CANCER', lands: 'INVERTED' },
        hops: [
          { text: 'Study links Compound X to cancer.', lands: 'INVERTED' },
          { text: 'One mouse study at about 1,000× any human dose; not yet replicated; no human data.', lands: 'PRESERVED' },
          { text: 'The paper: tumours in mice fed Compound X at very high doses.', lands: 'PRESERVED' },
          { text: 'Tumour counts in two groups of lab mice.', lands: 'PRESERVED' },
        ],
        assistant: { text: 'Studies have linked Compound X to cancer.', lands: 'INVERTED' },
        lesson: 'The free assistant’s one line is true and drops the key: in mice, at huge doses.',
      },
    ],
  },
];

export const CARDS = [
  { id: 'receiver-budget', week: 'week1', title: 'A week of focus', href: '../concepts/receiver-budget',
    text: 'You could not trace everything, and nobody can. The budget is fixed; what each minute buys depends on what you already know.' },
  { id: 'legibility', week: 'week1', title: 'The first compression', href: '../concepts/legibility',
    text: 'The forest ledgers had no column for soil. Nothing later in the pipeline could recover what the measurement never recorded.' },
  { id: 'open-vigilance', week: 'week1', title: 'Shrugging is a choice too', href: '../concepts/open-vigilance',
    text: 'People mostly err toward caution, refusing something true more often than swallowing something false. Shrug at everything and you lose the true ones.' },
  { id: 'decompression-on-demand', week: 'week2', title: 'The patient tutor', href: '../concepts/decompression-on-demand',
    text: 'The tutor did not give you more minutes. It made each one go further, by doing the unpacking you could not afford.' },
  { id: 'compressed-form-as-authority', week: 'week2', title: 'The answer that replaces the source', href: '../concepts/compressed-form-as-authority',
    text: 'The assistant’s answer arrived free and sure of itself, with no sign of what it dropped. That is what lets a summary stand in for the source.' },
  { id: 'corpus-capture', week: 'week2', title: 'What the assistant read', href: '../concepts/corpus-capture',
    text: 'An assistant answers from the text it was trained on. If most of that text repeats the old story, so does the answer.' },
];

// Verbatim from the chapters. reader.test.js checks each against its source file.
export const QUOTES = {
  raw: {
    text: 'Raw data is misnamed. The "raw" is the first compression, pretending to be the source.',
    attr: 'Lossy, Ch. 1', source: 'content/the-information-landscape.md',
  },
  budget: {
    text: 'The receiver budget is finite, but its capacity, how much complex form a unit of time can absorb, is partly a function of the structure the receiver has already built.',
    attr: 'Lossy, Ch. 3', source: 'content/info-time-limit.md',
  },
  summary: {
    text: 'The paper is technically still there; nobody reads it. The summary is technically not the paper; everybody reads it.',
    attr: 'Lossy, Ch. 11', source: 'content/ai-as-new-node.md',
  },
  owner: {
    text: 'Which mode a given model rewards, patient decompression or eager summary, is a design decision, and it sits with the owner.',
    attr: 'Lossy, Ch. 11', source: 'content/ai-as-new-node.md',
  },
};

export const COPY = {
  intro: {
    kicker: 'A game from Lossy · part three',
    title: 'The Reader',
    body: 'You carried findings and you ran a desk. Now you are at the end of the pipe, with a week’s worth of focused minutes and a feed that does not stop.',
    button: 'Open the feed',
  },
  brief: {
    heading: 'Week {n}',
    button: 'Start the week',
  },
  claim: {
    heading: 'Claim {i} of {total}',
    where: 'You are looking at it in {stop}.',
    minutes: 'Minutes left: {m} of {total}',
    trace: 'Trace it to {next} ({cost} min)',
    noTime: 'Not enough minutes left to go further.',
    bottom: 'This is as far up as it goes.',
    accept: 'Believe it',
    settle: 'Believe this version',
    shrug: 'Shrug it off',
    assistant: 'Ask the free assistant (0 min)',
    tutor: 'Ask the library tutor ({cost} min)',
    trail: 'On the way up',
  },
  answer: {
    assistantHeading: 'The free assistant says',
    tutorHeading: 'The library tutor walks you through it',
    button: 'Next claim',
  },
  reveal: {
    heading: 'Week {n}: what you came away believing',
    spent: 'You used {used} of {total} minutes.',
    routeAccept: 'Believed it as it reached you',
    routeShrug: 'Shrugged it off',
    routeTrace: 'Traced it to {stop}',
    routeAssistant: 'Asked the free assistant',
    routeTutor: 'Asked the library tutor',
    minutes: '{m} min',
    noBelief: 'No belief',
    you: 'You',
    others: 'Two other readers, same week',
    busy: 'Believed everything as it arrived: 0 minutes',
    shrugger: 'Shrugged at everything: 0 minutes',
    assistantOnly: 'Asked the free assistant about everything: 0 minutes',
    cards: 'New cards',
    next: 'Next week',
    finish: 'Finish',
  },
  end: {
    heading: 'What you carry out',
    carry: [
      'Is the short version likely to be roughly right anyway, or is this worth my minutes?',
      'Which stop upstream would settle it: the news, the field, the paper, or the measurement?',
      'When an assistant answers, who owns it, and what did it read?',
    ],
    cutHeading: 'What this game cut',
    cut: [
      'Minutes and costs are invented to show a shape. Real tracing takes longer, and a real week holds far more than eight claims.',
      'Every version of every claim is a simplification of what the book’s cases say. Compound X is the book’s made-up example.',
      'The tutor here is faithful because the game says so. Chapter 11 is about why that is the hard part.',
      'Not holding a view on something is often reasonable. The game counts a shrug as no belief, not as an error.',
    ],
    replay: 'Read the feed again',
    links: [
      { label: 'Back to Courier', href: './' },
      { label: 'The Desk', href: './desk.html' },
      { label: 'Read Chapter 1', href: '../the-information-landscape' },
      { label: 'Read Chapter 11', href: '../ai-as-new-node' },
    ],
  },
};
```

### 1b. `game/reader-engine.js`

Pure ES module. Imports only from `./reader-data.js`. No DOM, no globals, no
randomness, no dates. Never mutate an input; always return new objects.

Export these functions with exactly these names and behaviours.

| Function | Returns |
|---|---|
| `getWeek(id)` | the week with that id |
| `costToDepth(d)` | sum of `HOP_COST[0..d-1]` (0 for d = 0) |
| `formAt(claim, depth)` | `claim.meme` when depth is 0, else `claim.hops[depth - 1]` |
| `canTrace(state)` | true when the screen is `claim`, `depth < 4` and `spent + HOP_COST[depth] <= week.minutes` |
| `canTutor(state)` | true when the screen is `claim`, the week has `tools`, `depth === 0` and `spent + TUTOR_COST <= week.minutes` |
| `weekBeliefs(state, weekId)` | the beliefs whose `weekId` equals `weekId`, in order |
| `tally(beliefs)` | object mapping each `lands` value to how many beliefs have it (only values that occur) |
| `defaultBeliefs(week, mode)` | for `mode` `'accept'`: one `{ claimId, lands: claim.meme.lands }` per claim; `'shrug'`: `lands: 'BOUNCED'`; `'assistant'`: `lands: claim.assistant.lands` |
| `initialState()` | see state machine |
| `step(state, action)` | the next state; see state machine |

**State machine**

```js
initialState() === {
  screen: 'intro',   // intro | brief | claim | answer | reveal | end
  weekIndex: 0,
  claimIndex: 0,
  depth: 0,          // how far up the current claim the player has traced
  spent: 0,          // minutes spent this week
  beliefs: [],       // { weekId, claimId, route, depth, minutes, lands }
  answer: null,      // 'assistant' | 'tutor' while on the answer screen
  cards: [],         // unlocked card ids, in unlock order
  newCards: [],      // card ids unlocked by the reveal just reached
}
```

`route` is one of `'accept'`, `'trace'`, `'shrug'`, `'assistant'`,
`'tutor'`. `minutes` is what that claim cost: `costToDepth(depth)` for
`accept`/`trace`, 0 for `shrug` and `assistant`, `TUTOR_COST` for `tutor`.

`step(state, action)` where `action` is `{ type, ... }`. Any action not listed
for the current screen, or not allowed by its condition, returns the state
unchanged (the same object).

| Screen | Action | Condition | Effect |
|---|---|---|---|
| `intro` | `START` | | `screen = 'brief'`, `weekIndex = 0` |
| `brief` | `BEGIN` | | `screen = 'claim'`, `claimIndex = 0`, `depth = 0`, `spent = 0`, `newCards = []` |
| `claim` | `TRACE` | `canTrace(state)` | `spent += HOP_COST[depth]`, `depth += 1` |
| `claim` | `SETTLE` | | record belief: route `'accept'` if depth is 0, else `'trace'`; `lands = formAt(claim, depth).lands`. Then **advance** |
| `claim` | `SHRUG` | `depth === 0` | record belief: route `'shrug'`, `lands: 'BOUNCED'`, minutes 0. Then **advance** |
| `claim` | `ASK_ASSISTANT` | week has `tools` and `depth === 0` | record belief: route `'assistant'`, `lands = claim.assistant.lands`, minutes 0; `answer = 'assistant'`, `screen = 'answer'` |
| `claim` | `ASK_TUTOR` | `canTutor(state)` | `spent += TUTOR_COST`; record belief: route `'tutor'`, `lands = claim.hops[3].lands`, minutes `TUTOR_COST`; `answer = 'tutor'`, `screen = 'answer'` |
| `answer` | `NEXT` | | `answer = null`, then **advance** |
| `reveal` | `NEXT` | | if this is the last week: `screen = 'end'`. Otherwise `weekIndex + 1`, `screen = 'brief'` |
| `end` | `REPLAY` | | `{ ...initialState(), screen: 'brief' }` |

The belief's `depth` is the current `depth` (0 for shrug, assistant and tutor).

**advance**: if there is another claim this week, `claimIndex + 1`,
`depth = 0`, `screen = 'claim'`. Otherwise: `newCards` = ids of `CARDS` whose
`week` is this week's id and that are not already in `cards`, in file order;
append them to `cards`; `screen = 'reveal'`. (Recording a belief and advancing
happen in the same step.)

### 1c. `game/reader.test.js`

Use `node:test` and `node:assert/strict`.

**Costs and budgets** (the game's design; these must hold):

- `[0,1,2,3,4].map(costToDepth)` deep-equals `[0, 2, 7, 17, 32]`.
- Week 1, cheapest route to `PRESERVED` per claim, over the routes believe at
  depth 0–4 (cost `costToDepth(d)`) and shrug: earth 0 (depth 0), power 7
  (depth 2), masks 2 (depth 1), eggs 7 (depth 2), forest 32 (depth 4); total
  48, which is `<=` the week's 50 minutes.
- Week 1: believing the forest claim at depths 0–3 gives `INVERTED`; only
  depth 4 gives `PRESERVED`.
- Week 2, the same search plus the assistant (0) and the tutor
  (`TUTOR_COST`): arsenic 0 (assistant), prison 4 (tutor), compoundx 4
  (tutor); total 8, `<=` 10.
- Week 2: tracing both `prison` and `compoundx` to depth 2 costs 14, more than
  the week's 10 minutes.
- Enumerate every combination of routes in each week that fits the budget.
  Week 1 has exactly 4309 affordable combinations, of which exactly 2 make
  every claim `PRESERVED`. Week 2 has exactly 169, of which exactly 1 does.
  (Routes per claim: shrug; believe at depth 0, 1, 2, 3, 4; and in week 2 the
  assistant and the tutor.)

**Default readers.** `tally(defaultBeliefs(week1, 'accept'))` deep-equals
`{ PRESERVED: 1, INVERTED: 3, FLAG: 1 }`;
`tally(defaultBeliefs(week1, 'shrug'))` deep-equals `{ BOUNCED: 5 }`;
`tally(defaultBeliefs(week2, 'assistant'))` deep-equals
`{ PRESERVED: 1, INVERTED: 2 }`.

**Data invariants.** Every claim has a `meme` and exactly four `hops`; claim
ids are unique; every `lands` (in memes, hops and assistants) is a key of
`STAMPS` imported from `./courier-data.js`; every claim in a week with `tools`
has an `assistant`, and no claim in a week without `tools` does; card ids are
unique and every card's `week` is a week id; `STOPS` has five entries and
`HOP_COST` four.

**Quote check** and **card link check**: exactly as in `courier.test.js`.

**Playthrough A, the careful reader.** From `initialState()`, apply with
`step`:

```
START · BEGIN
SETTLE                                   earth: accept, 0 min
TRACE · TRACE · SETTLE                   power: trace to depth 2, 7 min
TRACE · SETTLE                           masks: trace to depth 1, 2 min
TRACE · TRACE · SETTLE                   eggs: trace to depth 2, 7 min
TRACE · TRACE · TRACE · TRACE · SETTLE   forest: trace to depth 4, 32 min → reveal
NEXT · BEGIN                             week 2
ASK_ASSISTANT · NEXT                     arsenic
ASK_TUTOR · NEXT                         prison
ASK_TUTOR · NEXT                         compoundx → reveal
NEXT                                     → end
```

Assert: at the week 1 reveal, `spent === 48`, `newCards.length === 3`, and
`tally(weekBeliefs(state, 'week1'))` deep-equals `{ PRESERVED: 5 }`; at the
week 2 reveal, `spent === 8` and `tally(weekBeliefs(state, 'week2'))`
deep-equals `{ PRESERVED: 3 }`; at the end, `screen === 'end'`,
`beliefs.length === 8`, `cards.length === 6`.

**Playthrough B, the curious reader** (over-traces early). Week 1:

```
START · BEGIN
TRACE · TRACE · SETTLE                   earth: 7 min
TRACE · TRACE · SETTLE                   power: 7 min
TRACE · SETTLE                           masks: 2 min
TRACE · TRACE · SETTLE                   eggs: 7 min   (spent 23)
TRACE · TRACE · TRACE                    forest: depth 3, spent 40
```

Assert: now `canTrace(state)` is false (40 + 15 > 50), and `TRACE` returns
the same state object. Then `SETTLE`: the forest belief is `INVERTED`, and
`tally(weekBeliefs(state, 'week1'))` deep-equals
`{ PRESERVED: 4, INVERTED: 1 }`.

**Playthrough C, the assistant reader.** Week 2 only (start from the week 1
reveal of playthrough A, then `NEXT · BEGIN`), `ASK_ASSISTANT · NEXT` three
times. Assert `spent === 0` and the week 2 tally deep-equals
`{ PRESERVED: 1, INVERTED: 2 }`.

**Edge cases.**
- `SHRUG` at depth 1 returns the same state object.
- `ASK_ASSISTANT` and `ASK_TUTOR` in week 1 return the same state object.
- `ASK_TUTOR` in week 2 after `TRACE` (depth 1) returns the same state object.
- `SHRUG` at depth 0 records `{ route: 'shrug', depth: 0, minutes: 0, lands: 'BOUNCED' }`.
- `REPLAY` from the end gives `screen === 'brief'`, `weekIndex === 0`,
  `beliefs` empty, `cards` empty.
- Re-run playthroughs A and B with the state deep-frozen (recursive
  `Object.freeze`) before every `step` call; nothing throws.

### Phase 1 checks

```bash
node --test game/*.test.js
```

All tests pass: Courier's, the Desk's and the Reader's. Commit:
`Phase <N>: reader game — data, engine, tests` (include
`game/READER-PLAN.md`).

---

## Phase 2 — the playable page

### 2a. `game/reader.html`

Same shape as `game/desk.html`, with: `<title>The Reader — a game from Lossy</title>`,
header word `The Reader`, script `./reader-ui.js`.

### 2b. Append to `game/courier.css`

Add a section after the Desk section, before the `prefers-reduced-motion`
block, headed `/* ---- The Reader ---- */`. Use only existing variables.

- `.trail`: a list with no bullets, `margin: 8px 0 16px`. `.trail li`:
  `var(--ink-dim)`, 15px, a 2px `var(--wire)` left border, `padding-left: 10px`,
  `margin-bottom: 8px`. `.trail .stop`: block, `var(--mono)`, 12px,
  uppercase, `letter-spacing: .12em`, `var(--ink-faint)`.
- `.where`: `var(--mono)`, 13px, uppercase, `letter-spacing: .12em`,
  `var(--signal-soft)`.
- `.tools`: like `.actions`, but with a 1px `var(--wire)` top border and
  `padding-top: 14px`.
- `.route-line`: one claim per row in the reveal: same look as `.story-line`
  (reuse it by giving rows both classes `story-line route-line`).

### 2c. `game/reader-ui.js`

```js
import { WEEKS, STOPS, HOP_COST, TUTOR_COST, CARDS, QUOTES, COPY } from './reader-data.js';
import { STAMPS } from './courier-data.js';
import * as engine from './reader-engine.js';
```

Copy these helpers from `desk-ui.js`: `fill`, `h` (with its disabled-click
guard), `dispatch` **with its focus rule** (keep focus on a button whose
`data-id` matches `action.id` when the view key is unchanged, otherwise focus
the `<h1>` and scroll to top), `title`, `btn`, `fmt`, `isCaps`, `card` and
`quote`. Use this view key:

```js
const viewKey = (s) => `${s.screen}:${s.weekIndex}:${s.claimIndex}:${s.depth}`;
```

Because `TRACE` changes `depth`, every trace moves focus to the `<h1>`, which
is what we want: the claim text has changed.

A stamp's label is `COPY.reveal.noBelief` for `BOUNCED`, else
`STAMPS[stamp].label`; colour by `STAMPS[stamp].tone`. Write a `stampSpan`
that does this. Every tally line lists stamps in the order
`['PRESERVED', 'INVERTED', 'FLAG', 'BOUNCED']`, skipping absent ones, as
`label: count`.

The week is `WEEKS[state.weekIndex]`; the claim is
`week.claims[state.claimIndex]`.

Screens:

| Screen | Shows | Buttons |
|---|---|---|
| `intro` | `COPY.intro.kicker`, `title` as `<h1>`, `body` | `COPY.intro.button` → `START` |
| `brief` | `COPY.brief.heading` as `<h1>` (`n` = week number); the week's `brief` | `COPY.brief.button` → `BEGIN` |
| `claim` | see below | see below |
| `answer` | see below | `COPY.answer.button` → `NEXT` |
| `reveal` | see below | `COPY.reveal.finish` on the last week, else `COPY.reveal.next` → `NEXT` |
| `end` | `COPY.end.heading` as `<h1>`; the three questions as an ordered list; `cutHeading` and the cut lines as a list | `COPY.end.replay` → `REPLAY`; the four `COPY.end.links` as plain links |

**Claim screen, top to bottom.**

1. `COPY.claim.heading` as `<h1>` (`i` = claim number, `total` = claims this week).
2. A `.status` line from `COPY.claim.minutes` (`m` = minutes left, `total` = the week's minutes).
3. A `.where` line from `COPY.claim.where` with `stop = STOPS[depth]`.
4. The current form's text in a `<p class="claim">` (add `caps` when all capitals).
5. If `depth > 0`: `COPY.claim.trail` as a small heading, then a `.trail` list of
   the forms above, from depth `depth - 1` up to 0, each `<li>` with a `.stop`
   span (`STOPS[d]`) and the form's text.
6. An `.actions` row:
   - if `depth < 4`: the trace button, label from `COPY.claim.trace` with
     `next = STOPS[depth + 1]` and `cost = HOP_COST[depth]`, `disabled` unless
     `engine.canTrace(state)`; dispatch `TRACE`;
   - the believe button: `COPY.claim.accept` at depth 0, else
     `COPY.claim.settle`; dispatch `SETTLE`;
   - at depth 0 only: `COPY.claim.shrug` → `SHRUG`.
7. If `depth === 4`: `COPY.claim.bottom`. Else if the trace button is disabled:
   `COPY.claim.noTime`.
8. If the week has `tools` and `depth === 0`: a `.tools` row with
   `COPY.claim.assistant` → `ASK_ASSISTANT` and `COPY.claim.tutor`
   (`cost = TUTOR_COST`) → `ASK_TUTOR`, the latter `disabled` unless
   `engine.canTutor(state)`.

**Answer screen.** The belief just recorded is the last entry of
`state.beliefs`; its claim is `week.claims[state.claimIndex]`.
- If `state.answer === 'assistant'`: `COPY.answer.assistantHeading` as `<h1>`,
  then the claim's `assistant.text` in a `<p class="claim">`.
- If `'tutor'`: `COPY.answer.tutorHeading` as `<h1>`, the meme text in a
  `<p class="claim">`, then an ordered list of the four hops, each with a
  `.stop` span (`STOPS[1..4]`) and its text.

**Reveal screen, top to bottom.** `beliefs = engine.weekBeliefs(state, week.id)`.

1. `COPY.reveal.heading` as `<h1>` (`n` = week number).
2. `COPY.reveal.spent` (`used = state.spent`, `total = week.minutes`).
3. `COPY.reveal.you` as `<h2>`. For each belief, a `story-line route-line`
   row: the claim's meme text (serif); a mono line with the route text
   (`routeAccept`, `routeShrug`, `routeTrace` with `stop = STOPS[depth]`,
   `routeAssistant`, `routeTutor`), ` · `, `COPY.reveal.minutes`, ` · `, and
   the stamp; then the claim's `lesson` in `.story-note`.
4. Your tally line.
5. `COPY.reveal.others` as `<h2>`. Two lines, each a label and its tally:
   week without tools: `busy` (`'accept'`) and `shrugger` (`'shrug'`); week
   with tools: `busy` (`'accept'`) and `assistantOnly` (`'assistant'`).
6. Week 1: the `raw` quote, then the `budget` quote. Week 2: the `summary`
   quote, then the `owner` quote.
7. If `state.newCards` is not empty: `COPY.reveal.cards` as `<h2>`, then each
   new card.

### Phase 2 checks

```bash
node --test game/*.test.js
node --check game/reader-ui.js
grep -n innerHTML game/reader-ui.js    # must print nothing
```

The browser checks are done by the reviewer. Leave Phase 2 uncommitted unless
told otherwise.

---

## Phase 3 — wire it up

1. **`game/desk-data.js`**: in `COPY.end.links`, insert as the **first** entry:
   `{ label: 'Next: be the reader', href: './reader.html' },`
2. **`Makefile`**, `play-stage` recipe: append
   `game/reader.html game/reader-data.js game/reader-engine.js game/reader-ui.js`
   to the `cp` line, before `site/public/play/`.
3. **`content/index.md`**: in the line that starts
   `- **<a href="./play/"`, replace
   `Then run the desk that decides which stories travel at all.` with
   `Then run the desk that decides which stories travel at all, and finally sit at the end of the pipe with a week's worth of minutes.`
4. **`game/README.md`**: add `## Part three: the Reader` after the Desk
   section, in the same style, and add the reader files to the layout tree.

### Phase 3 checks

Commit first (`Phase <N>: reader game — link from the Desk, stage at /play/`),
then `make check`, `make site-build`, `make site-check`, and
`ls site/public/play/`. All succeed, and the four reader files are staged. If
`make site-build` changes committed files under `content/`, stop and report.

## Done means

- `node --test game/*.test.js`, `make check`, `make site-build` and
  `make site-check` pass.
- One commit per phase on `reader-game`, nothing pushed.
- A report listing the commit hashes, any check not run and why, and anything
  in this plan that was wrong or ambiguous.

## Not in this plan

Carrying minutes or beliefs between weeks or games, an AI tutor that is
actually an AI, the Bridge and Keeper seats, and any change to chapter prose.
