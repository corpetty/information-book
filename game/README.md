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
  courier.css         styles
  courier-ui.js       renders state, dispatches actions; nothing else
```

All behaviour lives in `courier-engine.js` as pure functions; the UI only draws
the current state and turns clicks into actions.

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
