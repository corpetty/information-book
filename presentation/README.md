# Lossy — the one-hour talk

`lossy-talk.html` is a self-contained interactive presentation of the whole book:
34 slides / ~58 scripted minutes / 7 interactive demos. No dependencies, no network,
no build step — open the file in any modern browser and present.

**Published at [lossybook.com/talk/](https://lossybook.com/talk/)** — `make site-build`
stages it as `site/public/talk/index.html` (the `talk-stage` target), the same
post-build pattern as the `/graph/` viewer. It is deliberately NOT in `content/`:
Quartz's asset slugifier strips `.html` extensions, so a content-routed copy would
publish extensionless and download instead of render. Links to it from prose need
`data-router-ignore="true"` so the SPA router doesn't intercept.

## Structure

| Act | Slides | Carries |
|---|---|---|
| Cold open | 1–4 | The power-posing debt: the correction is free, short, and true — why is it losing? |
| I · The Squeeze | 5–8 | Transport compression; the claim survives, the manual dies (The Stripper) |
| II · The Pick | 9–15 | The turn: selection gates; the failure has a direction (The Gate Race); "you cannot aim a cost" |
| III · The Tablespoon | 16–20 | The receiver budget (A Tablespoon of Weeks); the three truth regimes (Three Readers); nobody lied |
| IV · No Villain | 21–25 | The Feed Console; Huxley not Orwell; preservation held, training hollowed |
| V · One Box, Every Dial | 26–28 | The LLM as concentrated selection surface; The Ownership Lever |
| VI · Outlast | 29–34 | The Fix That Backfires; bridge people; three rules; the monastery close |

Two persistent devices: the **footer rail** (the pipeline diagram accumulates one
layer per act — slide 33 shows it full-screen: "this is the whole book, take a photo"),
and **five carry-out icons** (bottom-left) that light up as each dinner-retellable
sentence lands. Press `?` in the deck to see the five sentences.

## Keys

- `→` / `space` — next build-step or slide (interactives consume these first)
- `←` — previous slide (steps back inside The Stripper)
- `o` / `esc` — overview grid · `s` — speaker notes · `t` — talk timer · `?` — help
- Inside every interactive: `r` resets to seed, `p` panic-jumps to the pre-baked
  payoff frame. Each interactive slide shows its own keys in the footer hint.

## Presenting notes

- Every demo is deterministic (fixed seeds, no randomness, no network) — the same
  keystrokes always produce the same run. Rehearse the no-interaction path using
  the `p` frames if you want a ~50-minute lecture cut.
- The agent sim on slide 30 intentionally starts with the room's prediction:
  ask "connect or diverge?" before pressing `c`.
- The feed poll on slide 22 is tallied by hand: `y`/`n` per raised hand.
- All quotes on slides are verbatim from the book (verified against
  `content/*.md`) and attributed `— Lossy, Ch. N`.
- Append `?static` to the URL to disable all animation (also respects
  `prefers-reduced-motion`).

Timing target: 58.5 scripted minutes. The interactives carry ~20 of them.
