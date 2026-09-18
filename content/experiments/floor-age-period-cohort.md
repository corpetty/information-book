---
title: The Floor, by Age Period and Cohort
tags:
  - information
  - experiments
---

**Evidences** — the generational half of the floor claim: that raw emotional payload is not just what wins at an engagement-tuned gate today, but a *want* the medium trains into cohorts raised inside it. Theory in [[emotional-memetics|Chapter 7]] and [[medium-and-manipulation|the medium note]]; the mechanism is [[medium-shapes-want|medium-shapes-want]].
**Status** — open (logged 2026-09-18). Design only; no data gathered.
**Cheapest first move** — an age-period-cohort decomposition of existing long-run survey series on affective polarization and news-sharing preferences.

The claim that needs evidence: [[emotional-memetics|Chapter 7]] argues raw emotion is the *floor* of what spreads at scale, and [[medium-and-manipulation|the medium note]] pushes further, that a medium run for a generation may be a *co-writer* of wants, not just a casting director selecting among standing ones. The note flags the co-writer claim as unearned, because the within-campaign evidence (Mercier's mass-persuasion failures) cannot see decade-scale shaping. This doc tracks the analysis that could earn it.

## Why age-period-cohort

Any change in what people want over calendar time is a sum of three things that a raw trend cannot separate:

- **Age effects** — people may reach for emotional, identity-flagged content more at some life stages than others, independent of when they were born.
- **Period effects** — a given year's events (a war, an election, a pandemic) shift everyone at once, which is the casting-director reading the medium note already earns: [[psychology-of-virality|*Psychology of Virality*]] shows the viral slot flipping from out-group animosity to in-group solidarity around the 2022 invasion.
- **Cohort effects** — people born into and formed by a particular media regime carry wants no prior generation had, because what got amplified through their formative years is what they learned to want.

**The co-writer claim is precisely a cohort claim.** The casting-director claim (the safe one) predicts period effects; the co-writer claim (the strong one) predicts a cohort gradient: generations raised inside engagement-tuned media hold a *lower floor*, reaching for raw-emotional and identity content at a higher baseline that persists as they age. An age-period-cohort decomposition is the standard instrument for pulling those three apart, and it is the shape of evidence the floor claim owes.

## The measurement move

1. Assemble a long-run repeated cross-section with a stable measure of the outcome: affective polarization thermometers, self-reported sharing of high-arousal vs. considered content, or coded emotional content of what respondents say they pass on.
2. Fit an age-period-cohort model (with the usual identification caveats below), reading off the cohort term.
3. The strong prediction: **a monotone cohort gradient, with cohorts whose formative years fell after the engagement-tuned feed became dominant (roughly post-2010 adolescence) sitting at a higher emotional-sharing baseline, net of age and period.** A flat cohort term with all the action in the period term supports only the casting-director reading, and the medium note should retreat to it.

## Evidence in the wild (no new collection)

- **ANES / GSS** carry decades of affective-polarization and media-use items, enough for a cohort decomposition of the polarization outcome directly.
- **[[boxell-internet-polarization|Boxell, Gentzkow & Shapiro (2017)]]** is the sharpest existing adversary and asset at once: they found polarization grew *fastest* among the cohorts *least* exposed to the internet, which cuts against a naive "the feed did it" story and must be explained by any cohort model here, most likely as an age or period effect swamping a still-forming cohort signal.
- **[[brady-moralized-content|Brady et al. (2017)]]** and platform-shared retweet corpora give a behavioral (not self-report) emotional-content measure that could be cohort-tagged where age is observable.
- **Cross-country timing.** Engagement-tuned feeds arrived at different dates in different countries; the co-writer claim predicts the cohort gradient shifts with the local arrival date, a difference-in-differences the single-country series cannot give.

## Confounds / threats to validity

- **APC is not identified without a constraint.** Age, period, and cohort are linearly dependent (cohort = period − age), so the decomposition rests on an assumption (a constrained term, a nonlinearity, a proxy for the mechanism rather than raw cohort). The result is only as good as that constraint, and the write-up has to defend it, not bury it.
- **Self-reported wanting is not wanting.** The [[paradox-of-virality|paradox of virality]] is that people say they do not want high-arousal content to spread while it spreads anyway, so a survey measure of *stated* preference may move opposite to behavior; a behavioral outcome is safer but harder to cohort-tag.
- **Reverse causation within the cohort.** A cohort gradient is consistent with the medium shaping wants *and* with differentially emotional people selecting into heavy feed use; the cross-country timing test is what separates shaping from selection.
- **The outcome may be measuring polarization, not the floor.** Affective polarization is downstream of the emotional floor but not identical to it; a clean design needs a measure closer to "what emotional register does this person reach for," not just "how much do they dislike the out-group."

## Status & next step

Open. Next: pick the outcome series (start with ANES affective-polarization thermometers, which have the longest clean run), specify the identification constraint before looking at the data, and run the decomposition. If a cohort gradient survives Boxell's counter-pattern and the cross-country timing test, the medium note can promote its co-writer claim from plausible to earned; if not, it holds at casting-director and Part IV's cross-cohort prescriptions inherit that limit.
