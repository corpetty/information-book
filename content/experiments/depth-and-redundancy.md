---
title: Depth and Redundancy
tags:
  - information
  - experiments
---

**Evidences** — the network-ceiling claim: that the detail an idea can carry falls with the number of retellings it has to cross, so "the bigger the network, the lower the ceiling". Theory in [[complexity-virality-tradeoff|Chapter 5]]; the companion measurement on what is lost first is [[caveat-loss-per-hop|Caveat Loss Per Hop]].
**Status** — open (logged 2026-11-24). Design only; no data from people. A formal model and simulations exist.
**Cheapest first move** — one text, the same number of receivers, three shapes of network: a star, a chain-like tree of depth 3, and one of depth 6.

The claim that needs evidence: Chapter 5 says per-hop losses compound, so what survives N retellings goes as a per-hop number to the Nth power, and a bigger network means a lower ceiling. The chapter asserts the compounding; nothing in it measures it, and "bigger" runs together two things that pull in opposite directions, depth and the number of routes.

## What the formal model and the simulations say

A machine-checked model and seven simulations are in `formal/` in this book's repository. None of it is evidence about people.

Machine-checked:

- **The power law is a ceiling on telling originals apart.** If no single retelling lets a reader tell any two versions apart with an edge of more than c, then N retellings allow an edge of at most c to the Nth power. It is exact for a reteller who sometimes falls back on something of their own and otherwise repeats faithfully, and can be far from exact otherwise. It is not a statement about the chance of arriving intact, which has a floor: ideas can be lost and come back. And c is not the chance of clean preservation; a reteller who preserves well has a c near 1.
- **A budget alone neither forces compounding nor forbids it.** A reteller whose retelling is stable, so that retelling their own version changes nothing, loses what the first pass loses and then nothing more. A fixed reteller who is not stable can go on losing a little per hop, but only for a number of hops set by the budget, after which nothing more is merged.
- **The compounding can come from people differing.** A crowd in which some repeat faithfully and the rest always say their own thing, met at random, is the same hop as one noisy reteller. Rerunning the same chain with the same people can tell the two apart.
- **One receiver, several routes.** For one receiver at depth N the ceiling holds whatever the size of the audience. A second independent route adds at most a(1 − a) when one route gives an edge of a. It adds nothing when there are only two candidates and a forgetful reteller picks between them by a fair coin.

From simulation and the literature, not machine-checked:

- **A whole generation of a tree.** In the model with two candidates and a fair-coin fallback, the literature gives a threshold: the generation as a whole keeps a trace of which original was sent, at any depth, once each teller tells more than 1/c² people, and loses it below that. My simulations at depths 6 to 12 are consistent with this and do not locate the threshold. No single member of the generation is better off; the trace is in the pooled generation. When what people fall back on can never be mistaken for the original, one surviving copy settles the matter and the threshold is the branching-process one, more than 1/c.
- **Local change is slow and uneven.** For retellers who only shift an idea a little, the proved ceiling says nothing, and simulated loss is slow: versions that started close are confused within a hop or two, and versions that started far apart stay distinguishable for a long time.

## The measurement move

1. Fix a set of near-identical originals (the same finding with different caveats, or the same story with different particulars) and a line-up task: shown the version that reached them, a receiver picks which original it came from. The measure at each depth is how far above chance they are.
2. Deliver one original to the same number of receivers through a star, a tree of depth 3 and a tree of depth 6. The ceiling predicts the edge depends on a receiver's depth, not on the size of the audience.
3. Give some receivers two independent routes to the same original. The model predicts a gain unless the candidates are two and symmetric.
4. Rerun the same chains with the same people on the same original. If outcomes repeat, the loss is in who the retellers are; if they vary, it is noise in each person.
5. Vary how different the candidate originals are. Equal confusion of close and distant candidates means forgetting; close ones going first means drift.

By a power calculation (exact binomial test, 5% one-sided, 80% power), seeing that receivers beat chance in a two-way line-up at depth 10 takes about 50 chains when c is 0.9 and several thousand when c is 0.7, so the design has to stay shallow or the per-hop edge has to be high.

## Confounds / threats to validity

- **Selection at each hop is not transport.** Receivers who choose whether to pass something on are filtering, and filtering changes what survives without any loss in the retelling. A forced-pass design measures transport alone; a free-pass arm measures the mix. See [[selection-as-other-engine|Chapter 5b]].
- **The line-up sets the answer.** Which candidates a receiver chooses among decides what "above chance" means. Close candidates make the task hard and distant ones make it trivial; report both.
- **A model is not a person.** The simulations and the language-model runs say what the mathematics allows and whether the instrument works. They say nothing about how people retell.
- **An easy line-up shows nothing.** In 1,440 language-model retellings over six hops, with two candidate originals that shared no condition, every retelling kept at least one condition of its own original and none of the other's, even in the arms where only one message in ten arrived intact. Read off the coding (no reader was tested), the edge over chance did not move, so that run says nothing about how it decays. Candidates have to differ in one particular, or the chains have to be much longer.

## Status & next step

Open. The scripted language-model chains were run on 2026-11-25 (see [[caveat-loss-per-hop|Caveat Loss Per Hop]]): the instrument works for whether a condition is present, and the line-up was too easy to test the ceiling. Next: a language-model run with candidates that differ in a single condition and longer chains, then a small human study on the star-against-depth-3 comparison with a line-up of four near-identical findings.
