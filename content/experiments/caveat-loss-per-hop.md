---
title: Caveat Loss Per Hop
tags:
  - information
  - experiments
---

**Evidences** — the `transport` claim directly: that a lossy hop strips the [[three-layer-message|outer message]] (scope conditions, caveats, the "we're not sure yet") while the bare claim survives. Theory in [[complexity-virality-tradeoff|Chapter 5]] and [[truth-compression-and-when-each-wins|Chapter 5c]]; the stage model in [[the-information-landscape|Chapter 1]].
**Status** — open (logged 2026-09-18). Design only; no data from people. Simulated, and piloted with a language model as the reteller, on 2026-11-24.
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

## What simulation and a language-model pilot add

Run on 2026-11-24; code, data and a fuller write-up are in `formal/sim/` in this book's repository. None of it is evidence about people.

**How big the pilot has to be.** Simulating the design, with claims retained at 0.9 per hop and three caveats per finding, the planned ~30 finding-chains detect a caveat retention of 0.7 per hop with about 90% power over two hops and 97% over three, and a retention of 0.8 with only 39% and 54% (a one-sided test at 2.5%). Ten chains are too few for anything but a large gap; a hundred catch the small one. Loss concentrated at the first hop (0.6, then 0.85), which is what Sumner's result suggests, is told from steady loss with 98% power at 30 chains. These figures assume each caveat is lost independently. If caveats on one finding are lost together, the real power is lower, so 30 is a floor, not a target.

**What to measure.** Two changes to the measurement move above.

- *Ask for a choice, not a recall.* The share of versions that still "have" a caveat has a floor: a caveat can be lost and reintroduced. The cleaner measure is whether a reader can pick the source out of a line-up of near-identical findings that differ only in their caveats, and how far above chance that sits at each hop. In a formal model of noisy retelling, that edge is the quantity with a ceiling that shrinks by a factor per hop.
- *Vary how different the candidates are.* If close and distant candidates are confused at the same rate, retellers are forgetting. If close ones go first, they are drifting. A finding with and without one caveat is a pair of close candidates, so drift alone predicts that whether a caveat was there is the first thing a reader can no longer tell, with no special role for the key. That is a rival to the transport reading, and this design can separate them.

**A pilot with a language model as reteller.** Eight invented findings, each with a headline claim and three caveats (who it was shown for, how strong the evidence is or under what circumstances, how big or limited the effect is), went down 32 chains of five retellings. The chains ran in four batches of eight: at each hop a fresh small model retold a batch of eight findings in at most 20 words each, seeing only their previous versions. A larger model, blind to depth, coded the result. The batches, not the chains, are the independent units, and there was one coder.

- The cut in length came at the first hop (33 words to 19), and so did all three losses of a claim. After that the wording settled: between an eighth and a third of the versions at hops two to five were word-for-word copies of the one before.
- The caveats were not stripped, but they kept eroding for a while. Of 96 caveats, 92 were still present after one hop and 87 after five, with 4, 3 and 3 lost at the first three hops and almost none after. Caveats kept in full fell from 85 to 70. The claim was present in 29 of 32 versions after the first hop and 29 after the fifth.
- All three claim losses were in findings that stated the caveats first and the claim last (3 of 16, against 0 of 16 when the claim came first). That is two distinct findings and not statistically distinguishable from chance, so it is a hint. In each case the retelling kept every caveat and cut the headline.
- By kind, after five hops: who it was shown for survived in 97% of cases, the other two kinds in 88% each.
- The reteller was noisy, not a fixed function: two chains from the same finding never produced the same first retelling.

So the distinctive prediction above, claim persists while caveats fall away, did not appear. I would not read that as evidence against it. A model asked to retell within a word budget has the previous version in front of it and compresses carefully; a person retells from memory, to an audience, with reasons to be punchy. What the pilot shows is that the pipeline runs end to end, that a word budget on its own cuts once and then erodes caveats slowly for a couple of hops before settling, and that the coding needs a second coder: a spot check found a handful of doubtful codes. Position in the message deserves a controlled comparison. A larger scripted run that varies the word budget and the instruction ("make it punchy", "you only remember the gist") is written and not yet run.

## Status & next step

Open. Next: pull Sumner's public sample and re-code a pilot of ~30 finding-chains for per-caveat retention across the paper → release → news hops, then decide whether extending the chain to social posts is worth fresh collection. If the claim/caveat retention gap is real and widens with hop count, it is the first direct measurement under the transport half of the book.
