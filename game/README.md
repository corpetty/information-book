# Courier — the ten-minute game

`index.html` is a small browser game for *Lossy*. The player carries three findings
from the lab to the feed, decides what to cut at each hand-off, and sees how each
one lands with its readers. No dependencies, no network, no build step, no saved state.

**Published at [lossybook.com/play/](https://lossybook.com/play/)** — `make site-build`
stages it as `site/public/play/` (the `play-stage` target), the same post-build
pattern as the `/talk/` deck and the `/graph/` viewer. It is deliberately NOT in
`content/`: Quartz strips `.html` extensions from content assets. Links to it from
prose need `data-router-ignore="true"`.

## Layout

```
game/
  PLAN.md             the build plan this was written from
  courier-data.js     all content: readers, rounds, cards, quotes, copy
  courier-engine.js   pure logic and state machine, no DOM
  courier.test.js     node --test
  index.html          page shell
  courier.css         styles (shared by both games)
  courier-ui.js       renders state, dispatches actions; nothing else

  DESK-PLAN.md        the build plan for part two
  desk-data.js        all Desk content: days, stories, cards, quotes, copy
  desk-engine.js      pure logic and state machine, no DOM
  desk.test.js        node --test
  desk.html           page shell
  desk-ui.js          renders state, dispatches actions; nothing else

  READER-PLAN.md      the build plan for part three
  reader-data.js      all Reader content: weeks, claims, cards, quotes, copy
  reader-engine.js    pure logic and state machine, no DOM
  reader.test.js      node --test
  reader.html         page shell
  reader-ui.js        renders state, dispatches actions; nothing else

  BRIDGE-PLAN.md      the build plan for part four
  bridge-data.js      all Bridge content: towns, messengers, framings, cards, copy
  bridge-engine.js    pure logic and state machine, no DOM
  bridge.test.js      node --test
  bridge.html         page shell
  bridge-ui.js        renders state, dispatches actions; nothing else
```

All behaviour lives in the four engines as pure functions; the UIs only draw
the current state and turn clicks into actions.

## Part two: the Desk

`desk.html` is reached from Courier's end screen and published at
[lossybook.com/play/desk.html](https://lossybook.com/play/desk.html). The player runs a
news desk: six stories a day, three slots, rent paid in attention. The rent rises until
careful stories alone can't pay it; an audit then shows what readers came away
believing, and on day 5 a library pays the rent. It covers selection (Ch. 5b), the
engagement equilibrium and Goodhart's law (Ch. 10), and funding outside the attention
market (Ch. 12). `DESK-PLAN.md` fixes every story, number and line of copy;
`desk.test.js` checks the outcome table, the rent squeeze (careful stories pay day 1,
not days 2–4), both scripted playthroughs, and every quote against its chapter.

## Part three: the Reader

`reader.html` is reached from the Desk's end screen and published at
[lossybook.com/play/reader.html](https://lossybook.com/play/reader.html). The player is
at the end of the pipe: claims arrive as memes, and a week's minutes buy tracing them
upstream (the news, the field, the paper, the measurement), each stop dearer than the
last. Week 2 adds a free assistant and a library tutor. It covers the five-stage
pipeline and "raw data is the first compression" (Ch. 1), the receiver budget (Ch. 3),
open vigilance (Ch. 7) and decompression on demand versus the summary that replaces
the source (Ch. 11). `READER-PLAN.md` fixes every claim, cost and line of copy;
`reader.test.js` checks the costs, that the budgets admit exactly the intended
all-correct routes (2 in week 1, 1 in week 2), three scripted playthroughs, and every
quote against its chapter.

## Part four: the Bridge

`bridge.html` is reached from the Reader's end screen and published at
[lossybook.com/play/bridge.html](https://lossybook.com/play/bridge.html). The player
holds one finding two distrustful towns both need, picks a messenger and a framing for
each town, then picks how the towns talk for ten years. It covers versatile expertise
and the curse of expertise, polarization via distrust and the Zollman effect (Ch. 9),
and survivable polarization (Ch. 12). `BRIDGE-PLAN.md` fixes every line and outcome;
`bridge.test.js` checks the outcome table, all 243 paths (50 end with both towns
roughly right: 49 through the panel, 1 kept apart, none through the shared forum), two
playthroughs, and every quote against its chapter.

## Tests

```bash
node --test game/*.test.js
```

`make test` and `make check` run these too. All text and numbers are fixed in
`courier-data.js`; the tests check every quote verbatim against the chapters and
that every card link resolves to a page in `content/`.

## Serve locally

ES modules do not load from `file://`, so serve the folder:

```bash
cd game && python3 -m http.server 8000
```

then open `http://localhost:8000/`.
