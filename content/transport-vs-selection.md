---
title: Transport vs. Selection
description: "Why ideas get simpler as they spread: not because each retelling loses a little, but because at every step something chooses which version travels. Transport is a cost; selection is a choice; only a choice can be steered."
aliases:
  - selection vs transport
  - lossy transport
  - frozen selection
  - generate bound pick
tags:
  - information
---

The foundational question the book had to pick a side on: is compression at scale driven by *transport* (each hop loses something) or by *selection* (what survives is whatever wins on a fitness landscape)? The short answer is selection, and this note is the work that gets there, including a wrong turn worth keeping in view, because the word I first reached for, *primary*, turned out to be doing too much and had to be walked back to something more precise.

A word on *selection* first. The term is loaded: it carries connotations from natural selection (impersonal, fitness-driven, no agency) and from gatekeeping (deliberate, exclusionary, owned). The book uses it in the technical sense, *a mechanism that ranks candidates against criteria and passes only some forward*, and that mechanism turns up in both impersonal forms (a recommendation algorithm tuned by aggregate behavior) and deliberate ones (an editor choosing what to publish). Renaming it (*memetic fitness*, *gating*) would buy clarity in one place at the cost of obscuring that the same mechanism runs across very different surfaces. Keep the word, distrust the connotation, attend to which kind of selection is at work in each case.

## The two views

**Transport view.** Information has some inherent complexity, networks have hops, and each hop is a re-encoding that may lose or compress. The complexity that arrives is bounded by cumulative loss across hops: bigger network, more hops, more compression. [[complexity-virality-tradeoff|Chapter 5]] is a transport argument, and its canonical example is the [[telephone-game|telephone game]], ten kids passing a sentence around a circle until the output barely resembles the input. Pure transport, pure loss.

**Selection view.** Information enters an attention ecosystem, and receivers don't pass everything; they pass what's worth passing, for their own reasons. What survives is whatever wins on a fitness landscape (emotional resonance, identity reinforcement, status, action affordance, novelty), so compression *emerges from* selection rather than from transit. In the telephone-game frame: the parlor game forces every player to pass the message, so transport loss is the only mechanism, but real networks don't have that rule. Players choose whether to pass at all, and what they choose is what the selection view points at.

## Test cases that distinguish them

If the two views made the same predictions the choice wouldn't matter. They don't.

- **Specialist paper to "scientists say X" headline.** Transport says lossy hops compressed it. Selection makes a sharper prediction: of all the findings, the one that escapes is the *most fitness-fit*, not the most load-bearing, which is what we see (the surviving fragment is the surprising or actionable one).
- **Conspiracy theories spread faster than corrections.** Transport struggles: both fit in a sentence, so transport cost is roughly equal. Selection explains it cleanly: the conspiracy offers in-group identity, action, and emotional payload, the correction offers none. This is the case that pushed me toward selection; transport can't account for it without smuggling selection in the back door. (The empirical version is real: false news demonstrably spreads faster and wider than true news, per Vosoughi, Roy, and Aral, 2018.)
- **Long-form podcasts carry complexity at scale.** Transport says a small dense audience keeps per-hop loss low. Selection says hosts are selected for making complexity feel like community membership, so what survives is complexity packaged into parasocial trust, not expository clarity, which matches the industry better.
- **Academic institutions preserve complex truth.** Transport isn't cheaper inside academia; the selection *rules* are different (peer review, methodological rigor) and favor rigor over virality.
- **Religions persist with full theology over millennia.** Both views work, but selection explains *which* religions survived and why they look as they do: the ones with the highest social and emotional fitness, not the lowest transport cost.

## First answer, and the word that broke

My first landing was flat: **Selection is primary. Transport is real but increasingly downstream.** Hold that loosely; the word *primary* is about to cause trouble. The durable part of it is a historical claim worth stating on its own: **In modern digital networks, the cost of transport has collapsed to near zero, so selection becomes the dominant constraint on what spreads.** In earlier eras with expensive transit (manuscripts, geographically limited print) transport was a binding constraint and a transport-style argument had real force; the relevant constraint has shifted as the medium changed. That gives the book a sharper *why now*: not that human nature changed, but that the constraint which used to limit memetic chaos, slow and expensive transport, has effectively vanished, exposing selection dynamics that were always there.

## Modality, not primacy

The trouble with "selection is primary" is that *primary* was four claims wearing one coat. That selection is causally *upstream* of transport, with transport as a downstream substrate, which is **false**: it contradicts the parallel-mechanisms picture, since if neither is downstream of the other, transport isn't downstream of selection either. That selection is the currently *binding* constraint, which is true but is the historical claim above and should stand on its own. That selection is where manipulation and repair have to act, true and not historical. And that selection carries the explanation of the breakage, since transport never broke, it only got cheaper, also true. The tell was the word *increasingly* in "increasingly downstream": the instinct was right (selection matters more and more) but it got encoded as causal order when what it tracked was a constraint that had shifted. So drop *primary*; it was always a ranking word, and the ranking is the wrong tool.

What survives, said plain: **transport and selection are co-equal and parallel, but they differ in modality: transport is an un-steerable cost, selection is a criterial choice, and only a criterial choice can be aimed, captured, or repaired.** Transport scrambles and has no preferred outcome; selection has a *what-it-rewards*. That asymmetry, not causal order, is what the book runs on, and it is why the book centers selection: it is the only one of the two with a steering wheel. The two are entangled through the want-loop (someone wants to engage, engages, accumulates preconditions, wants to engage more deeply), so **want is the prime mover** behind both, and the criteria selection runs on are themselves shaped by the cumulative history of past wants, which were outcomes of past selections on past media.

Landing on modality closes a gap the two-view framing stepped over: selection picks from a *set*, but nothing in "transport scrambles" says where the set comes from. Selection never generates its own options; something has to write the menu. **At every stage an idea is generated as variants by transport, bounded into an option space by the medium, and then picked from by selection: generate, bound, pick.** Transport is the scatter, the medium is the aperture, selection is the choice. And that puts the medium in a harder light than [[medium-and-manipulation|the medium note]] left it: the medium that writes the menu is doing a kind of selection too, done once, in advance. **The medium is frozen selection: a criterial choice made once and baked into the substrate, until it stops looking like a choice and starts looking like a law of nature.** A 280-character limit was somebody's decision; to everyone living inside it, it is simply the shape of the world. That makes the medium the most powerful gate of all and the least visible, because it pre-empts selection: you never have to suppress the long, careful argument if the option space was built so it cannot form. [[selection-as-other-engine|Chapter 5b]] runs the generate-bound-pick model out in full, and [[political-economy-of-attention|Chapter 10]] takes up who owns the frozen selection.

## Where I'm still uncertain

- **Is the transport-to-selection shift really historical, or did selection always dominate?** I claim selection became dominant as transport costs fell; maybe it always dominated and the "transport mattered historically" story is wrong in retrospect. (Eisenstein's account of print as an agent of change, 1979, is the case for transport-cost mattering historically, and worth engaging properly.)
- **How does selection work *inside* a single receiver?** I've discussed selection at hops between receivers, but it also happens within one: what gets attended to, remembered, re-transmitted. The [[info-time-limit|receiver-budget]] piece is partly about within-receiver selection, and the two need integrating.
- **Can the fitness landscape be characterized rigorously?** The book gets a lot of leverage if the fitness criteria can be enumerated or formalized; [[misinformation-age|O'Connor and Weatherall]]'s models do some of this.
- **The two conditions may be one system.** The want-loop is partly built out of what selection rewarded in the past, so "transport and selection, entangled through want" may be one feedback dynamic seen at several timescales rather than cleanly separable parts. If the boundary-versus-gradient difference between medium and runtime gate later needs its own slot, "the medium is frozen selection" is the seam to reopen.
