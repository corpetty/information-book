---
title: Measuring Interpretive Latitude
tags:
  - information
  - experiments
---

**Evidences** — the `interpretive-latitude` mechanism, and through it the `myth-dilution` loop. Theory in [[myths-scale-and-bureaucracy]], with the per-receiver case in [[truth-compression-and-when-each-wins|Chapter 5c]].
**Status** — open (logged 2026-05-21). Construct is theory-only; no evidence gathered.
**Cheapest first move** — the diachronic word-embedding study (existing data, no collection).

The claim that needs evidence: a compressed claim is interpretively *underdetermined*, and the width of that underdetermination — its *latitude* — grows as the network the claim must cross grows. Latitude is the engine of the whole myth-dilution loop, and right now it is asserted on instinct. This doc tracks how it could be measured or evidenced, so we can attack it later.

## The construct

Latitude = the width of the distribution of decodings a given compressed claim supports across a population. The loop predicts latitude *increases with network size*, because scale forces compression and compression unpins the decoding key.

Two distinct things to measure: latitude itself, and latitude as a function of network size.

## The measurement move

Meaning is not directly observable, so latitude cannot be measured directly. Its measurable shadow: **latitude is the dispersion of a myth's _implications_, conditional on agreement about the myth itself.** Take a group who all endorse myth M, give them a battery of specific judgments M should bear on, and measure how far their answers scatter. Wide scatter among co-endorsers = wide latitude. This turns an unmeasurable into an inter-rater statistic.

The fingerprint that separates latitude from ordinary disagreement: **co-endorsers who scatter and do not know they scatter.** Plain disagreement is visible to the parties; latitude produces false consensus. So the latitude-specific signal is how badly co-endorsers of M predict each other's specific positions.

## Experiments we could run

- **Branching transmission chains.** Seed a claim, branch it through many parallel chains, measure dispersion across the leaves (not drift down one line). Cap length or time per hop and watch dispersion widen. Established paradigm — Bartlett's serial-reproduction studies, modern iterated-learning work.
- **Compression-controlled survey.** The same idea in a six-word vs. a six-hundred-word form; measure implication-dispersion and false consensus on each. Isolates compression → latitude.
- **The scale problem.** You cannot grow a real network in a lab. Proxy "scale" with instructed audience breadth — "write this so everyone in [a small group / the whole country] gets it" — which induces the compression that scale would force.

## Evidence in the wild (no experiment needed)

- **Symbolic vs. operational ideology.** Political science has a long-running finding that Americans are "symbolically conservative but operationally liberal" — a myth nearly everyone endorses, under which concrete positions scatter hard. That is interpretive latitude, already quantified (Free & Cantril in the 1960s; Ellis & Stimson more recently). ANES / GSS / World Values archives let conditional-dispersion be computed for any broad myth, and compared across polities of different size.
- **Diachronic word embeddings.** Terms that scaled from a small network to mass use — "gaslighting," "trauma," "meme," "literally" — leave a datable corpus trail. Time-sliced embeddings measure how a term's contextual variance grows as adoption grows (semantic-change-detection methods; Reddit partitioned by subreddit and era). **This is the first move:** it plots latitude directly against network size with no new data collection.
- **Religions as a natural scale gradient.** The same creed at house-church, megachurch, and global-communion scale — measure doctrinal dispersion among adherents at each. Schism history is the segmentation record, already written down.
- **Measure the consequence.** Latitude → segmentation → schism, and schism is highly observable: open-source forks (GitHub data; fork rate against README / mission-statement compression), denominational splits, party factionalization.
- **LLMs as a cheap instrument.** Sample "what does X mean / what would an X-believer say about [battery]" at temperature; the spread of completions proxies a population's decoding distribution. Calibrate against human data on a few myths, then scan hundreds. Caveat: it measures the training corpus's latitude — though that corpus is itself one enormous network's usage.

## Confounds / threats to validity

- Every method measures *expressed* readings, not internal decoding keys.
- Dispersion has three possible sources: latitude (the myth admits many readings), plain disagreement (same reading, different verdict), and population heterogeneity unrelated to the myth. Conditioning on shared endorsement controls some of it; the false-consensus signature is the real discriminator, because only latitude makes people disagree without noticing.
- "Network size" is itself multi-dimensional — raw count, hop depth, heterogeneity of members. Decide which is the operative variable before measuring against it.

## Status & next step

Open. Next: scope the diachronic-embedding study — pick ~5 terms with known small-network origins and later mass adoption, identify time-sliced corpora, define the contextual-variance metric. If latitude rises with adoption there, it is the first real anchor under the myth-dilution loop.
