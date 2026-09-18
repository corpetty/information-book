---
title: Caveat Loss Per Hop
tags:
  - information
  - experiments
---

**Evidences** — the `transport` claim directly: that a lossy hop strips the [[three-layer-message|outer message]] (scope conditions, caveats, the "we're not sure yet") while the bare claim survives. Theory in [[complexity-virality-tradeoff|Chapter 5]] and [[truth-compression-and-when-each-wins|Chapter 5c]]; the stage model in [[the-information-landscape|Chapter 1]].
**Status** — open (logged 2026-09-18). Design only; no data gathered.
**Cheapest first move** — replicate Sumner et al. 2014's coding on a fresh paper → press-release → news sample, then extend one hop downstream to social posts.

The claim that needs evidence: [[transport|transport]] does not degrade the claim so much as strip the *conditions under which the claim holds*. The book asserts this on instinct and on anecdote (the "scientists say X" headline). Sumner and colleagues already built the instrument to measure it; this doc tracks how to point it at the book's own pipeline.

## The prior art it borrows

Sumner et al. (2014, *BMJ*) coded a matched sample of biomedical journal articles, their university press releases, and the news stories that followed, scoring each for exaggeration along three axes: causal claims stated beyond the study's design, advice to readers the study did not license, and inference from animals to humans. The finding that matters here is *where* the exaggeration entered: most of it was already present in the **press release**, not introduced by journalists downstream. The distortion was a bridge-zone artifact one hop earlier than the usual "lazy journalist" story assumes, which is exactly the [[bridge-zone-distortion|Chapter 6]] claim that reshaping is active construction for a downstream gate, not passive blur.

## The measurement move

Sumner measured exaggeration as a binary per article. The book needs the *rate of caveat retention per hop*, so the unit changes: **for each scope condition attached to a finding at stage N, is it present, weakened, or absent at stage N+1?**

1. Sample findings that carry explicit, enumerable caveats at the source (an effect size with a confidence interval, an "in mice" boundary, a "correlational, not causal" line, a subgroup restriction).
2. Trace each finding forward through its actual retellings: paper → abstract → press release → news story → social post → the version a lay reader repeats.
3. At each hop, code every source caveat as retained / weakened / dropped, and code any caveat *added* (rare, and itself interesting).
4. Plot retention against hop number. The transport model predicts a roughly multiplicative decay: retention across N hops going as the per-hop retention rate to the Nth power, the same compounding the [[telephone-game|telephone-game]] math in Chapter 5 describes for the claim itself, but measured on the *key* rather than the claim.

The distinctive prediction, and the one that separates transport from ordinary summarization: **the inner claim survives at a far higher rate than its outer message.** If both decay at the same rate, "compression is just lossy" wins and the book's key/claim split is unearned. If the claim persists while the caveats fall away hop by hop, the [[truth-compression-and-when-each-wins|Chapter 5c]] mechanism is observed directly.

## Evidence in the wild (no new collection)

- **Sumner's own corpus** is public; re-coding it for per-caveat retention rather than per-article exaggeration is a desk study.
- **Retraction Watch / press-release archives** (EurekAlert!) give matched source-and-release pairs at scale.
- **Preprint-to-headline pairs** from COVID are an unusually clean natural experiment: fast pipelines, archived at every stage, and the [[covid-mask-guidance|mask-guidance case]] shows the failure mode the coding should catch (the supply-rationing condition dropped at the first hop).

## Confounds / threats to validity

- **Caveat salience is not caveat importance.** A dropped hedge that did not bear on the reader's decision is not the same failure as a dropped scope condition that inverts the claim; the coding needs an importance weight, not just a count.
- **Selection at each hop is not transport.** A retelling that drops a caveat may have been *selected* precisely because it dropped it (the punchier version travels), so per-hop retention conflates transport loss with [[selection|selection]] pressure. Branching the trace (many downstream versions per source, per the latitude study) separates the two: transport predicts symmetric loss, selection predicts the surviving versions cluster on the alarming reading.
- **Source caveats are themselves compressed.** The journal abstract has already dropped conditions the full paper stated, so "stage 0" is not the un-compressed form; the study measures pipeline loss from an already-lossy origin and should say so.

## Status & next step

Open. Next: pull Sumner's public sample and re-code a pilot of ~30 finding-chains for per-caveat retention across the paper → release → news hops, then decide whether extending the chain to social posts is worth fresh collection. If the claim/caveat retention gap is real and widens with hop count, it is the first direct measurement under the transport half of the book.
