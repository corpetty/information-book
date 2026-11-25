# Simulations of the retelling model

Seven simulations around [`Complexity/Lossy.lean`](../Complexity/Lossy.lean) and
[`Complexity/Noisy.lean`](../Complexity/Noisy.lean). The theorems there are bounds. These
runs show where the bounds are tight, where they are silent, what happens in settings that
are not formalized (trees, many routes), and whether the experiments proposed for the book
could tell the models apart. The last two use a language model as the reteller. None of
them is evidence about how people retell things.

Run any of them with `python3 s1_tightness.py` and so on (numpy, scipy, matplotlib). Numbers
land in `out/*.json`, figures in `out/*.png`. Random seeds are fixed. Simulation 5 reads the
book's own text, so its numbers change when the book does.

Vocabulary: a *hop* is one retelling; the *advantage* between two originals is how much
better than chance the best test on the outcome tells which one was sent (1 is certainty,
0 is nothing); a hop's *one-hop constant* is its worst advantage over all pairs of inputs.

## What came out, in short

| | Question | Answer |
|---|---|---|
| 1 | How loose is the proved law "advantage after n hops ≤ product of one-hop constants"? | Exact for the fading hop. Silent for hops that change ideas only locally once the space of ideas is large: there the one-hop constant is 1, yet distinguishability does decay, slowly, at a rate set by the size of the idea space |
| 2 | Do distance from the original and distinguishability move together? | No. Forgetting makes distance level off while distinguishability collapses, equally for all pairs. Drift makes distance creep up while close originals are confused within a hop or two and distant ones stay apart for a long time |
| 3 | What does redundancy buy against depth? | For one receiver, the routes needed to hold the line grow like c^(−2n) or c^(−n) with depth n. On a tree, simulation is consistent with the threshold reported in the literature for the two-idea case (branching above 1/c²), without locating it; when the fallback can never pass for the original the threshold is branching above 1/c |
| 4 | Can the proposed experiments separate the models, and how big must they be? | Noisy people and one particular mix of fixed people give the same curve; rerunning the same chain separates them. A 30-chain caveat pilot sees a retention gap of 0.2 per hop, not one of 0.1 |
| 5 | What does the budget-against-tolerance curve look like for real text? | With a lexical distance the budget rises steadily across the usable range of tolerance, about one bit per 0.05. The book's claims need fewer balls than unstructured points, provably so at tolerance 0.2 and below |
| 6 | What does a language model do as reteller? (pilot, 160 retellings) | It cuts the text at the first retelling and is noisy, not a fixed function. Conditions survived about as well as the claim. Its "erosion that stops after two hops" recurred at 20 words in the larger run and did not hold at a tighter limit or under other instructions |
| 7 | The same with 1,440 retellings, three word limits and two other instructions | With words to spare almost no condition disappears in six hops (none at 40 words, 3 of 144 at 20), though some lose their specifics. Under a tight limit or a "punchy" instruction, a condition is lost at 2.6 to 2.8% per hop after the first and was still being lost at hops 4 to 6. In those two arms messages arriving intact fall to about one in ten, while by the coding the source stays identifiable in every one of the 1,440. The claim outlasts its conditions by 11 to 15 points there, and is never stripped of them. In one coder's sample, 16 of 150 retellings say something materially different from the source, 13 of them with every item still coded present; 11 of the 16 come from two originals |

## 1. How loose is the product law? (`s1_tightness.py`)

![](out/s1_tightness.png)

True advantage for the worst pair of originals, computed exactly from matrix powers, against
`c^n` with `c` the one-hop constant, and against the asymptotic rate (second eigenvalue).

| hop | one-hop constant | second eigenvalue | true advantage at 10 hops | bound at 10 hops | hops until true advantage < 1/2 |
|---|---|---|---|---|---|
| fading, c = 0.9, 20 ideas | 0.90 | 0.90 | 0.349 | 0.349 | 7 |
| lazy cycle, 3 ideas, stay 0.9 | 0.90 | 0.854 | 0.211 | 0.349 | 6 |
| lazy cycle, 10 ideas | 1 | 0.983 | 0.997 | 1 | 55 |
| lazy cycle, 50 ideas | 1 | 0.9993 | 1.000 | 1 | more than 200 |
| drift on a line, 50 ideas, stay 0.8 | 1 | 0.9996 | 1.000 | 1 | more than 200 |
| random dense, 20 ideas | 0.68 | 0.21 | 0.000 | 0.022 | 2 |
| random sparse, 20 ideas | 1 | 0.66 | 0.053 | 1 | 5 |
| half fading (0.9), half drift, 50 ideas | 0.95 | 0.95 | 0.599 | 0.599 | 14 |

The bound was never exceeded. It is attained by the fading hop, and by the one mixture
tried here in which half the hop is a fade, because the fade sets the worst pair. It is far
from attained by a random dense hop, which also forgets in the library's sense. For hops
that only move ideas to neighbours, once the space is large enough that two ideas share no
neighbour (four or more on a cycle), the one-hop constant is 1 and the law says nothing;
what then governs loss is how long it takes to mix across the whole space of ideas, which
grows with that space. On three ideas the lazy cycle still contracts with 0.9
(`Noisy.lazyCycle_contracts`). The long-run rate is the second eigenvalue, which can be far
below the one-hop constant and is not what the theorem uses. This matches
`Noisy.lazyCycle_two_hops` and `Noisy.lazyFour_two_hops`.

## 2. Distance against distinguishability (`s2_distance.py`)

![](out/s2_distance.png)

Ideas on a line of 101 points, original at 30.

| reteller | expected distance at hops 1, 10, 100, 400 | advantage against an original 1 / 10 / 40 places away, at 10 hops | smallest separation still told apart (advantage ≥ 1/2) at hops 1, 10, 100 |
|---|---|---|---|
| fading to a uniform fallback, c = 0.9 | 2.9, 19, 29, 29 | 0.35 / 0.35 / 0.35 | 1, none, none |
| fading to one prototype, c = 0.9 | 4, 26, 40, 40 | 0.35 / 0.35 / 0.35 | 1, none, none |
| unbiased drift, stay 0.5 | 0.5, 1.8, 5.6, 11 | 0.18 / 0.97 / 1.00 | 1, 4, 10 |
| drift pulled to a prototype | 0.5, 2.4, 20, 40 | 0.18 / 0.98 / 1.00 | 1, 3, 10 |
| function: one step towards the prototype | 1, 10, 40, 40 | 1 / 1 / 1 | 1, 1, none (all merged on arrival) |

Three signatures that an experiment could look for:

- **Forgetting**: how well two originals can be told apart does not depend on how different
  they were. Distance from the original levels off early.
- **Drift**: close originals are confused within a hop or two (advantage 0.5 after one hop
  for neighbours, 0.18 after ten), distant ones stay apart; the separation that survives
  grows like the square root of the depth. Distance from the original grows slowly and
  keeps growing.
- **A fixed function**: every pair is all or nothing at every depth
  (`Noisy.detHop_dichotomy`). In the one function tried here, a step towards a prototype,
  pairs merge as they arrive at it.

A claim with and without one of its conditions is a pair of *close* originals. So drift
alone predicts that whether a condition was there is the first thing a reader can no longer
tell, with no separate mechanism for "keys". (Unbiased drift adds a condition as often as it
removes one, so this is about telling the versions apart, not about conditions vanishing.)
That is a suggestion from the model, not a finding.

## 3. Trees and several routes (`s3_trees.py`)

![](out/s3_trees.png)

**A whole generation of a tree**, every edge a fading hop on two ideas with a fair-coin
fallback. Advantage of the exact Bayes test on generation n (6,000 sampled trees per point,
standard error about 0.013), against one chain of the same depth:

| branching d, depth | d·c² = 0.5–0.6 | ≈ 0.85 | 1.0 | ≈ 1.2 | ≈ 1.5–1.7 | one chain, same depth and c |
|---|---|---|---|---|---|---|
| 2, depth 12 | 0.01 | 0.18 | 0.34 | 0.50 | 0.81 | 0.001 to 0.16 |
| 3, depth 8 | 0.03 | 0.22 | 0.36 | 0.49 | 0.78 | 0.001 to 0.08 |
| 4, depth 6 | 0.06 | 0.22 | 0.38 | 0.53 | 0.76 | 0.002 to 0.08 |

The rows at `d·c²` of 1.5 to 1.7 level off; the rows at 0.5 to 0.85 keep falling. At 1.0 and
at 1.2 the curves are still falling at the last depth simulated, so these runs are
consistent with a threshold at `d·c² = 1`, as reported in the literature for this two-idea,
fair-coin case, but they do not locate it. (The attribution is in the library's README and
is known to me only from summaries. None of this is machine-checked.) A plain majority vote
over the generation does almost as well as the exact test. What is retained is one bit,
which of two originals was sent, and only by pooling the whole generation: each single
member is still under `c^n`.

**When the fallback cannot imitate the original** (everything forgotten turns into
"something else"), one surviving copy proves which original was sent, and the advantage is
the survival probability of a branching process. Exact recursion: at `d·c = 0.9` it goes to
0, at `d·c = 1.1` it levels at 0.33 (d = 2), at `d·c = 1.41` at 0.83. The threshold is
`d·c = 1`, not `d·c² = 1`. For `c = 0.6` that is the difference between needing three
listeners per teller and needing two.

**k independent chains to one receiver**, each of n fading hops with c = 0.9, exact:

| depth | one route | two routes, fair-coin fallback | three routes, fair coin | two routes, fallback never gives the original | bound proved for two routes, `1 − (1 − a)²` | routes needed for advantage 1/2: fair coin / never |
|---|---|---|---|---|---|---|
| 5 | 0.590 | 0.590 | 0.783 | 0.832 | 0.832 | 1 / 1 |
| 10 | 0.349 | 0.349 | 0.502 | 0.576 | 0.576 | 3 / 2 |
| 20 | 0.122 | 0.122 | 0.182 | 0.228 | 0.228 | 31 / 6 |
| 30 | 0.042 | 0.042 | 0.064 | 0.083 | 0.083 | 253 / 17 |
| 40 | 0.015 | 0.015 | 0.022 | 0.029 | 0.029 | 2083 / 47 |

Two routes with a fair-coin fallback give exactly what one gives
(`Noisy.two_routes_no_gain_bool`), though a third route does help; the proved bound
(`Noisy.two_routes_le`) is exactly attained when the fallback never gives the original
(`Noisy.two_routes`). The number of routes needed to hold the line grows like `c^(−2n)` in
the first case and `c^(−n)` in the second. Either way, redundancy has to grow exponentially
with depth.

## 4. What the proposed experiments can separate (`s4_design.py`)

![](out/s4_design.png)

- **Noisy people against a mix of fixed people.** The mix is the one in
  `Noisy.fade_eq_mixture`: a share c of people who repeat faithfully, the rest people who
  always say their own thing. Over 40,000 chains each (c = 0.8, ten ideas), the share ending
  on the original differs by at most 0.008 at any depth, and both follow
  `c^n + (1 − c^n)·ν(x)` (`Noisy.prob_fade_self`): it falls to a floor, not to zero. Nothing
  here covers a crowd of retellers who each compress in a different way.
- **Rerunning the same chain of people on the same original** (depth 6, c = 0.8, ten
  ideas). Two reruns end the same in 16% of chains when everyone is noisy, 32%, 50%, 73%
  when a quarter, half, three quarters of people are fixed, and always when all are. So
  reruns can estimate how much of the randomness is in who the retellers are.
- **How many chains to see anything at depth n.** A power calculation, not a simulation:
  the smallest number of chains for which an exact one-sided binomial test at 5% detects,
  with 80% power, that receivers pick the original out of a two-way line-up more often than
  chance.

  | | depth 1 | 3 | 6 | 10 |
  |---|---|---|---|---|
  | c = 0.9 | 8 | 11 | 23 | 51 |
  | c = 0.7 | 13 | 53 | 448 | 7,758 |

- **The caveat-loss pilot** ([`content/experiments/caveat-loss-per-hop.md`](../../content/experiments/caveat-loss-per-hop.md),
  about 30 finding-chains, three conditions each, claims retained at 0.9 per hop). Power of
  a one-sided test at 2.5% to see that conditions are lost faster:

  | finding-chains | hops | conditions 0.8 | 0.7 | 0.6 |
  |---|---|---|---|---|
  | 10 | 2 / 3 | 0.13 / 0.19 | 0.40 / 0.57 | 0.74 / 0.86 |
  | 30 | 2 / 3 | 0.39 / 0.54 | 0.90 / 0.97 | 1.00 / 1.00 |
  | 100 | 2 / 3 | 0.91 / 0.98 | 1.00 / 1.00 | 1.00 / 1.00 |

  Loss concentrated at the first hop (0.6, then 0.85) is told from constant loss with
  power 0.98 at 30 chains, with a false-alarm rate of 5%.

  These powers assume every condition is lost independently. If conditions of one finding
  are lost together, the real power is lower.

## 5. Covering numbers of real text (`s5_covering.py`)

![](out/s5_covering.png)

`Lossy.exists_relay_iff` says the least budget that lands every idea of a set within a
tolerance is `floor(log2 N)`, with `N` the covering number at that tolerance, centres
allowed anywhere. The model does not supply `N`. Here it is bracketed for 257 claims and
2,573 sentences of this book, with a **lexical** distance (tf-idf, 50 dimensions, angle
scaled to 0–1). Two sentences that say the same thing in different words are far apart
under it, so this is a stand-in. Most pairs of claims sit between 0.37 and 0.53 apart, so
the usable range of tolerance is narrow.

The inputs are the book's current text, so these numbers move whenever the book is edited;
the table is from the text as committed with this report. The claim candidates come from
`data/claim-candidates.jsonl`, a generated file that is not in the repository (`make
harvest` creates it); without it the script uses the 43 canonical claims only.

For the 257 claims and for 257 random directions in the same 50 dimensions: a lower bound
(a packing), an upper bound with centres restricted to the texts, and an upper bound with
centres anywhere.

| tolerance | claims: at least | at most, centres among texts | at most, centres anywhere | bits between | random: at least | at most, among | at most, anywhere |
|---|---|---|---|---|---|---|---|
| 0.5 | 1 | 4 | 1 | 0 | 1 | 6 | 2 |
| 0.45 | 1 | 17 | 2 | 0 – 1 | 1 | 23 | 5 |
| 0.4 | 1 | 37 | 6 | 0 – 2 | 1 | 110 | 12 |
| 0.35 | 1 | 72 | 14 | 0 – 3 | 1 | 242 | 26 |
| 0.3 | 1 | 106 | 26 | 0 – 4 | 2 | 256 | 52 |
| 0.25 | 4 | 152 | 43 | 2 – 5 | 6 | 257 | 97 |
| 0.2 | 37 | 194 | 75 | 5 – 6 | 110 | 257 | 152 |
| 0.15 | 106 | 222 | 128 | 6 – 7 | 256 | 257 | 256 |
| 0.1 | 194 | 243 | 198 | 7 | 257 | 257 | 257 |
| exact | 257 | | | 8 | 257 | | |

For the 2,573 sentences only the first two bounds were computed: at tolerance 0.3 between 1
and 578 balls (0 to 9 bits), at 0.2 between 52 and 1,902 (5 to 10 bits), at 0.15 between
578 and 2,256 (9 to 11 bits); exact landing needs 11 bits.

The brackets are wide: the lower bound is only good to a factor of two in the tolerance.
Two things can still be said. The upper curve with centres anywhere rises by about one bit
for every 0.05 of tolerance across the whole usable range; an earlier version of this
report called the curve a cliff, which was an artefact of restricting centres to the texts.
And the real claims are more compressible than unstructured points: at tolerance 0.2 they
need at most 75 balls where random directions need at least 110, and at 0.15 at most 128
against at least 256. Above 0.2 the upper bounds differ by about a factor of two but the
brackets overlap, so nothing is proved there. A distance measured on readers could look
quite different; that measurement is what the exchange-rate theorem is waiting for.

## 6. A language model as reteller (`s6_materials.py`, `s6_prepare_judging.py`, `s6_analyze.py`)

![](out/s6_llm_chains.png)

A pilot. Eight invented findings, each in two variants that share a headline claim and
differ in three conditions (who it was shown for; how strong the evidence is, or under what
circumstances; how big or limited the effect is). Each original (26 to 43 words) went down
two chains of five retellings: 32 chains, 160 retellings.

How the calls were made matters for what the numbers mean. The chains ran in four batches
of eight (one batch per variant and replicate). At each hop, one fresh small model (Claude
Haiku) was given the eight previous versions of its batch and asked to pass each on in its
own words in at most 20 words; it saw nothing else. So the independent units are 4 batches
× 5 hops, not 32 chains, and style within a batch and hop is shared (in one batch six of
eight versions at hop 5 are verbatim copies, in another none at hop 4). A larger model
(Claude Sonnet), blind to depth and chain, judged which variant each retelling came from
and coded the claim and each condition as kept, weakened or dropped. There was one coder.
Texts and codings are in `llm/`.

| | hop 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| mean length in words (original 33) | 18.6 | 17.8 | 16.9 | 16.7 | 16.8 |
| word overlap with the previous version | 0.38 | 0.74 | 0.80 | 0.72 | 0.84 |
| copied word for word from the previous version | 0% | 13% | 19% | 13% | 31% |
| source variant identified (of 32) | 32 | 31 | 32 | 32 | 32 |
| claim coded present (of 32) | 29 | 29 | 30 | 30 | 29 |
| conditions present (of 96) | 92 | 89 | 87 | 88 | 87 |
| conditions kept in full (of 96) | 85 | 80 | 72 | 71 | 70 |
| per-hop retention of conditions that were still there | 0.96 | 0.97 | 0.97 | 1.00 | 0.99 |

- **The cut comes at the first hop; the erosion goes on for two more.** Length drops from
  33 words to 19 at the first hop, where the budget bites, and the wording changes most
  there. All three losses of a claim are at the first hop. Conditions, though, are lost at
  the same rate at hops 2 and 3 as at hop 1 (4, 3 and 3 of those still present), and then
  hardly at all; conditions kept in full fall by 11 at hop 1 and by 15 more by hop 5. The
  text then settles: between an eighth and a third of versions at hops 2 to 5 are verbatim
  copies of the one before.
- **The reteller is noisy, not a fixed function.** The two chains from the same original
  never produced the same first retelling (0 of 16 pairs), and they differ in content: one
  drops "48 people" and "3 points" where the other keeps both. By the criterion of
  simulation 4, that is noise in the reteller. What the data show is noise at the first
  pass, then something close to a stable relay (`Limits.relay_iterate_saturates` describes
  the stable part; it needs its stability hypothesis).
- **No loss of distinguishability over five hops.** 159 of 160 retellings were assigned to
  the right variant, and the one miss was the judge's (the retelling names "three
  startups"). Treating the 32 items at a depth as independent, which they are not, the
  advantage is at least 0.78 at every depth with 95% confidence (0.69 at hop 2 if the
  judge's error is counted). Two routes could add nothing to that.
- **Conditions were not stripped.** They were present about as often as the claim at every
  depth. What they lost was precision.
- **All three claim losses were in originals that stated the claim last** (3 of 16, against
  0 of 16 when the claim came first). That is two distinct originals, each original exists
  in one order only, and the difference is not statistically significant (Fisher's exact
  test, p = 0.23). In each case the retelling kept the conditions and cut the headline.
  Order made no visible difference to the conditions.
- **By kind of condition at hop 5**: who it was shown for 97%, the second kind 88%, size or
  limit of the effect 88%. The second kind is loosely labelled: it mixes strength of
  evidence with dose and circumstance.
- Two chains from the same original agreed on the fate of a condition 90% of the time;
  with 91% of conditions present, chance agreement would be 83%.

This does not show the book's predicted split (claim survives, conditions fall away), and
it should not be read as evidence against it. A model asked to retell within a word budget
has the previous version fully in view and compresses it carefully; a person retells from
memory, to an audience, with reasons to be punchy. What the pilot shows is that the
pipeline runs end to end. Its further reading, that a word budget alone produces one cut
and then a slow erosion that stops, recurred in simulation 7 at the same 20-word limit and
did not hold at a tighter limit or under other instructions. Its hint about position in
the message was not confirmed there, on too few losses to tell.

Limits. One model. Eight items per call, so chains within a batch are not independent. The
sampling temperature could not be set, so no fixed-function arm was run. One coder, no
second rating: a spot check of about sixteen codings found five wrong or doubtful (for
example a claim coded "weakened" in a version that does not mention it, and "call-centre
volunteers" coded as dropping the volunteer condition), identical texts were coded
differently in 2 of 96 unit codes, the claim-present row above goes from 29 to 30 and back
because of one such inconsistency, and "something was added" was never flagged although
some versions add "I heard". The coding needs a second coder before any number here is
leaned on. The chains were run with subagents because no API key was available and the
command-line login had expired.

## 7. The larger scripted run (`s7_llm_chains_cli.py`, `s7_more.py`)

![](out/s7_followup.png)

Run on 2026-11-25 through the `claude` command line: 1,440 retellings, each from one model
call that saw nothing but the previous version, and 1,440 blind judging calls. No call
failed and no retelling is missing. The script's defaults are Claude Haiku as reteller and
Claude Sonnet as judge; the result files of this run do not record which models answered
(later runs do, in `run_info.jsonl`).

Five arms: "pass it on in your own words" in at most 10, 20 and 40 words (`careful10`,
`careful20`, `careful40`); "short, striking and easy to repeat" in at most 20
(`punchy20`); "you remember the gist, not the details" in at most 20 (`gist20`). Each arm
has 48 chains of six retellings: the 16 originals of simulation 6, three chains each. The
judge coded the claim and the six conditions of both variants of the topic, in random
order, as kept, weakened or dropped. Below, a condition is *present* if kept or weakened,
*in full* if kept, and a retelling *arrived intact* if the claim is present and all three
conditions are in full.

The eight topics are the independent materials, so every interval below is a 95% bootstrap
interval that resamples topics (`s7_more.py`). With eight units these are rough, and
probably a little narrow.

**A correction first.** The summary the script printed at the end of the run had three
wrong lines. The judge saw the conditions in a random order, and the analysis compared
position *i* across hops and chains without undoing the shuffle, so "per-hop retention",
"conditions by kind" and "reruns" compared different conditions with each other. For
`careful10` it printed retention 0.94, 0.95, 0.92, 0.91, 0.87, 0.84 where the right figures
are 0.94, 0.99, 0.95, 0.98, 0.97, 0.97. The shares summed over the three conditions
(present, in full, advantage, claim) were not affected. The script is fixed (`load_run`)
and everything here is recomputed. The pilot of simulation 6 did not shuffle and is not
affected.

### The word limits were often exceeded

| arm | limit | words at hop 1 | at hop 6 | retellings over the limit |
|---|---|---|---|---|
| careful10 | 10 | 16.5 | 13.0 | 92% |
| careful20 | 20 | 21.4 | 19.1 | 36% |
| careful40 | 40 | 28.9 | 27.2 | 1% |
| punchy20 | 20 | 18.9 | 16.2 | 9% |
| gist20 | 20 | 22.8 | 19.5 | 44% |

The originals have 26 to 43 words, 33 on average. The arms are ordered by length as
intended, but "10 words" was really 13 to 17, and the 40-word limit did not bind: allowed
40, the model used 28.

### What survived

| arm | a condition is present: hop 1, 3, 6 | in full: hop 1, 3, 6 | arrived intact: hop 1, 3, 6 |
|---|---|---|---|
| careful10 | 94, 89, **83** (76–88) | 77, 62, **52** (42–62) | 46, 25, **8** (0–21) |
| careful20 | 99, 98, **98** (95–100) | 91, 84, **82** (72–92) | 73, 58, **52** (27–77) |
| careful40 | 100, 100, **100** | 99, 99, **95** (90–100) | 92, 98, **85** (73–96) |
| punchy20 | 99, 92, **85** (76–94) | 90, 66, **56** (46–64) | 75, 27, **12** (4–23) |
| gist20 | 100, 97, **94** (90–97) | 92, 77, **65** (51–77) | 79, 52, **35** (21–50) |

Percentages of 144 conditions, or of 48 retellings for the last column; intervals for
hop 6.

- **With words to spare, almost no condition disappeared in six hops.** In `careful40` all 144
  conditions were present at every hop, and in `careful20` 141 of 144 were present at
  hop 6, with a net loss per hop after the first of 0.3% (0 to 0.8). Specifics were still
  lost: conditions in full went from 91% to 82% in `careful20` and from 99% to 95% in
  `careful40`, and messages arriving intact from 73% to 52% and from 92% to 85%.
- **Under a tight limit or a "punchy" instruction, loss went on late into the chain.** Net loss
  of present conditions per hop: `careful10` 5.6% at the first hop (2.1 to 9.7), then 2.6%
  per hop (1.8 to 3.6); `punchy20` 1.4% (0 to 3.5), then 2.8% (1.0 to 4.9); `gist20` none
  at the first hop, then 1.1% (0.6 to 2.0). In `careful10` the loss at hops 4 to 6 is 2.4%
  per hop (1.3 to 3.5), against 3.0% at hops 2 and 3; the difference is −0.6 points (−3.0
  to 1.8). In `punchy20` it is 2.3% at hops 4 to 6 (1.0 to 4.1), with no change at hop 6
  itself (123 of 144 before and after). So in these arms conditions were still being lost
  late in the chain, and the run cannot tell a steady rate from one that is slowly falling.
  The pilot's "erodes for two more hops and then settles" recurred in the like-for-like arm:
  in `careful20` the conditions present were 143, 143, 141, 140, 141, 141 of 144. It did
  not hold at the tighter limit or under the punchy and gist instructions.
- **Specifics went faster than presence.** More conditions lost their specifics than
  disappeared. But a condition that disappeared mostly went in one step, not by way of a
  vaguer version: of 60 conditions ever coded gone, 44 had been coded in full at the hop
  before. Net loss of conditions in full per hop after the first: 7.5% (`careful10`),
  9.0% (`punchy20`), 6.6% (`gist20`), 2.0% (`careful20`), 0.8% (`careful40`). In `punchy20`
  and `gist20` this rate fell between hops 2–3 and hops 4–6 (by 8.6 and 3.2 points, both
  intervals clear of zero). The line between "in full" and "weakened" is the soft part of
  the coding; see below.
- **"Arrived intact" collapsed while "can be told apart" did not move.** By hop 6 a
  retelling had the claim and all three conditions with their specifics in 8% of chains in
  `careful10` and 12% in `punchy20` (39% over all five arms). Yet every one of the 1,440
  retellings kept at least one condition of its own variant, and the judge never coded a
  condition of the other variant as present (0 of 4,320 codes). So by the coding the source
  could be identified in every case: the advantage was 1 at every depth in every arm. No
  reader was tested; this is read off the codes. These are different quantities, and the
  theorems of `Noisy.lean` bound the second, not the first.
- **So this run does not test the chain law.** The line-up was too easy (two variants that
  share no condition) and six hops are too few. If each condition went on being lost
  independently at the rate of hops 2 to 6, half the retellings would have no condition
  left after about 59 hops in `careful10` (43 to 87 over the interval of the rate) and 55
  in `punchy20` (31 to 157). The kinds of condition are not lost at equal rates, so even
  that is rough: some tens of hops, perhaps 30 to 150. An extrapolation to plan with, not a
  result.
- **Across the arms survival rises with length, with one exception.** At hop 6: 13 words
  and 83% of conditions present (`careful10`), 16 and 85% (`punchy20`), 19 and 98%
  (`careful20`), 27 and 100% (`careful40`). "Punchy" shortened the text, and its effect
  cannot be separated from that. "Gist" can: at the same length as `careful20` (19.5 words
  against 19.1) it kept fewer conditions (94% against 98%, a difference of 3.5 points, 0.7
  to 5.6) and fewer specifics (65% against 82% in full, 17 points, 5 to 30). Nor does
  length alone fix survival: 16.5 words went with 94% at hop 1 of `careful10` and 16.2
  words with 85% at hop 6 of `punchy20`.
- **How many words the full message needs, and how much of the loss that explains.** For
  each original, the shortest version that the judge coded as claim kept and all three
  conditions kept has 10 to 27 words, median 16: about half the original. Ten of those
  sixteen shortest versions come from the two lossiest arms. `careful40` is clearly above
  that length and `careful10` at hop 6 clearly below it. Only part of the loss is a budget
  falling below what the content needs. Of the retellings that were not intact, those
  shorter than any intact version of their original were 166 of 224 in `careful10`, 86 of
  189 in `punchy20` and 24 of 140 in `gist20`: most of the loss at the tight limit, about
  half under "punchy", little under "gist". The rest happened at lengths that sufficed:
  the model could fit everything in and did not. These counts lean on a minimum taken over
  about 90 noisy codes per original, which picks up coding errors and so sets the bar low:
  one of the sixteen is "Volunteer firms, no control group, hours only fell 38 to 34:
  four-day-week burnout claims lack support", which has every item and, on my reading,
  turns the limits into a verdict against the claim (the second coder did not see it).
- **The reteller is noisy.** Two chains from the same original in the same arm produced
  the same first retelling in 6 of 240 pairs. With a single reteller, that is noise in the
  reteller by the criterion of simulation 4. How far the content decides which condition is
  lost is not pinned down. At hop 6, agreement between the three chains of an original on
  whether a given condition survived, beyond what chance would give, is 0.32 (−0.12 to
  0.65) in `careful10`, 0.33 (−0.04 to 0.56) in `punchy20` and 0.07 (−0.05 to 0.18) in
  `gist20`, where 1 would mean the content decides and 0 that each chain loses conditions
  independently. For specifics it is 0.24 to 0.39 in all five arms. So: weakly to
  moderately, and well short of a fixed function of the content.
- **The second kind of condition was lost most.** Pooled over arms at hop 6: who it was
  shown for 93%, strength of evidence or circumstance 87%, size or limit of the effect 96%;
  the second kind is 8 points below the other two (1 to 17). It is the lowest kind in four
  of the eight topics and the pooled gap leans on one of them. In `careful10` it is 71%
  against 85% and 92%, a gap whose interval includes zero (−41 to 1). The label is loose:
  this kind mixes study design with dose and setting.
- **The claim outlasted its conditions in the two lossy arms, without being stripped of
  them.** At hop 6 the claim was present more often than a condition by 11 points in
  `careful10` (94% against 83%; 2 to 21) and by 15 points in `punchy20` (100% against 85%;
  6 to 24), and by nothing measurable in the other three arms. That is the direction the
  book predicts. The strong form is absent: a claim with at most one condition left
  occurred in 1 and 2 of 48 chains in those arms and in none elsewhere.
- **A few chains went the other way, on shaky codes.** In `punchy20` the claim was coded
  present in all 288 retellings. In each other arm it was coded gone at some hop in 3 or 4
  of 48 chains, from five originals, and each time at least two conditions were still
  there: the headline cut, the small print kept ("A mouse study found eight daily coffees
  lasted about two hours"). Of 29 "gone" codes with a next hop, 10 were followed by
  "present" on the next version, usually a light rewording, and mostly where a condition
  implies the claim ("improved letter recognition but not story comprehension"). The
  second coder said "kept" for two of the first coder's four "gone" codes in its sample.
- **No detectable effect of where the claim stands, on too few losses to tell.** At hop 6
  the claim was coded gone in 3 of 120 chains that state it first and 5 of 120 that state
  it last (exact test swapping the order within topics, p = 0.88). Counting "gone" codes at
  any hop gives 9 against 28, which leans the pilot's way and is not significant either
  (p = 0.25): the 37 codes come from five originals. The pilot's hint is not confirmed and
  not refuted.

### A kind of change the coding does not see

A second coder (below) also judged, for a sample of 150 retellings, whether the retelling
still says what the source said. In 16 of 150 it judged the meaning shifted, and in 2 more
the finding was no longer stated. That judgement was made by one model and has no
reliability check of its own. The shifts were in every arm, including 3 of 30 in
`careful40`, but 11 of the 16 come from two originals (5 of the 10 sampled retellings of
one, 6 of the 8 of the other; 5 of 132 for the remaining fourteen), so the share is very
uncertain: 11%, or 4 to 20% resampling topics. They are mostly of two sorts. A limitation
becomes a verdict: "Study used volunteer firms with no control group; hours fell 4, so
burnout claim is unproven", where the source stated the finding and listed those limits.
Or a condition becomes the finding: "Cutting salt dropped office workers' blood pressure
11 points, but it's just correlation. Daily 20-minute walks help too", where the source
was about walking. In 13 of the 16, both coders coded the claim and all three conditions
as present. Counting which items survive misses this: little or nothing was dropped and
the message changed.

### How far to trust the coding

- The same text judged in two separate calls (72 pairs of retellings, 288 codes) got the
  same three-level code 94% of the time and the same present-or-absent code 99%.
- Information cannot come back, so a condition coded absent and then present at the next
  hop is a coding flip: 6 of 159 (4%). A condition coded weakened and then in full: 98 of
  575 (17%). Presence is coded steadily; "in full" is not. The net-loss figures above
  cancel flips only to the extent that they go both ways equally.
- **Second coder.** Another model (Claude Opus was requested, through a subagent), blind to the first
  coding, to arm and to hop, coded a stratified random sample of 150 retellings, five per
  arm and hop (`llm/cli_run/second_coder/`). On the 450 conditions the two agree on
  present or absent in 98% (Cohen's kappa 0.82) and on the three levels in 90% (kappa
  0.69); the first coder is the stricter about "in full" (29 codes weakened where the
  second says kept, 11 the other way). On whether a retelling arrived intact they agree in
  80% (kappa 0.60; 76 intact by the first coder, 86 by the second). On the claim they
  agree on present or absent in 98%, but with so few absences that kappa is only 0.56, and
  on the three levels in 75% (kappa 0.35). The second coder coded one condition of the
  other variant as present, in error. So the "present" columns are solid, the "in full"
  and "intact" columns are fair and somewhat strict, and nothing should be built on the
  claim's three-level code or on single "claim gone" codes. Both coders are language
  models; no person has coded any of this.
- "Something was added" was flagged in 32 of 1,440 retellings by the first coder and in
  none of 150 by the second, so that flag means little.

### What it changes

- For the model: with a generous limit no condition disappeared over six hops, and with a
  tight limit or a punchy instruction a noisy reteller kept losing conditions late in the
  chain. Recurring loss from a noisy reteller is the regime in which per-hop bounds
  compound, and the contrast between arms agrees with the correction made to the book's
  chapter: a budget alone neither forces compounding nor forbids it. Whether the advantage
  itself decays as a product is still untested here. A limit below what the content needs
  explains most of the loss at the tight limit and little of it under the gist
  instruction.
- For the pilot of simulation 6: its "one cut and then a slow erosion that stops" is what
  20 words give. It is not a general property of a word limit.
- For the book's prediction (claim survives, conditions fall away): a gap in the predicted
  direction of 11 to 15 points in the two lossy arms, and no stripping, even with a
  "punchy" instruction. A language model with the previous version in view is not a person
  retelling from memory to an audience, so this bears on the instrument, not on people.

Limits. One retelling model and one judging model, not recorded in the files. Eight
invented findings, and two of them (blood pressure with the salt condition, the four-day
week) account for most of the shifts of meaning. The reteller had the previous version in
full view. Both coders are models. Word counts here split on spaces; the script's own
summary counts "20-minute" as two words and so prints slightly higher lengths.

```
python3 s7_llm_chains_cli.py --smoke      # 8 retellings + 8 judgings, checks the login
python3 s7_llm_chains_cli.py              # the full run; safe to interrupt and rerun
python3 s7_llm_chains_cli.py --analyze    # redo the first analysis of what is on disk
python3 s7_more.py                        # the second pass: intervals, coding checks, second coder
```

## What this changes for the book's experiments

1. **Measure advantage, in a line-up.** Ask receivers to pick the original out of a fixed
   set, and look at the excess over chance. The share who "got it" has a floor and does not
   go to zero even when the model holds exactly.
2. **Vary how different the candidates are.** If close and distant candidates are confused
   at the same rate, retellers forget; if close ones go first, they drift. This is the
   cheapest way to tell the two apart, and it bears directly on whether conditions are lost
   because they are "keys" or simply because they are fine distinctions.
3. **Rerun the same chains.** It is the only design here that separates noise in a person
   from differences between people.
4. **Redundancy.** How much repeated exposure helps depends on whether what people fall
   back on can pass for the original: with two routes the gain runs from nothing to
   a(1 − a), and on a tree the threshold reported for the two-idea case is 1/c² against 1/c
   when the fallback cannot pass for the original. That is measurable.
5. **Size.** About 30 finding-chains are enough for a per-hop retention gap of 0.2 and too
   few for 0.1; depth-10 effects need tens of chains at c = 0.9 and thousands at c = 0.7.
6. **Pressure and coding.** Neither a word limit nor an instruction to be punchy or to
   remember only the gist reproduced the stripping of conditions in a language model; the
   claim outlasted its conditions by 11 to 15 points in the two lossy arms. Memory, delay,
   audience and selection between versions were not tried. Two model coders agree well on
   whether a condition is present (kappa 0.82), fairly on whether it kept its specifics
   (0.69) and poorly on the three-level state of the claim (0.35). Whether human coders
   show the same pattern is untested; it argues for making presence the primary code.
7. **Make the line-up hard, and the chain long or the budget tight.** With two variants
   that share no condition, the source stayed identifiable through six hops in every arm,
   so nothing was learned about how the advantage decays. Variants that differ in one
   condition, or a line-up of several, would put the measure where it can move.
8. **Code what the message says, not only which items survive.** In one coder's sample,
   16 of 150 retellings said something materially different from the source, 13 of them
   with the claim and every condition still coded present: a limitation turned into a
   verdict, or a condition turned into the finding. Most came from two originals, so the
   rate is uncertain (4 to 20%), but item counts miss it at any rate.
