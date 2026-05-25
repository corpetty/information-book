---
title: Transport vs. Selection
tags:
  - information
---

Working note. The [[outline]] flagged transport-vs-selection as the foundational question I need to pick a side on before more of the book can be drafted. So here goes. The question: is compression at scale driven by *transport* (each hop loses something) or by *selection* (what survives is whatever wins on a fitness landscape)? My current answer is selection, with caveats. Here's the work that gets me there.

A quick note on the word *selection*. The term is loaded — it carries connotations from natural selection on one side (impersonal, fitness-driven, no agency required) and from gatekeeping on the other (deliberate, exclusionary, owned by someone). The book uses *selection* in the technical sense — *a mechanism that ranks candidates against criteria and passes only some forward* — and that mechanism turns up in both impersonal forms (a recommendation algorithm tuned by aggregate behavior) and deliberate forms (an editor choosing what to publish). The connotations matter, and I will surface them where they bite; but the term is the right one for the underlying mechanism, and renaming it (*memetic fitness*, *attention dynamics*, *gating*) would buy clarity in one place at the cost of obscuring that the same mechanism is operating across very different surfaces. Keep the word, distrust the connotation, attend to which kind of selection is at work in each specific case.

## The two views in plain language

**Transport view.** Information has some inherent complexity. Networks have hops. Each hop is a re-encoding by a receiver who may lose, distort, or compress. The complexity that arrives at the far end is bounded by cumulative loss across hops. Bigger network, more hops, more compression forced by transit. The current [[complexity-virality-tradeoff|Chapter 5]] is a transport argument. The canonical example is the telephone game — ten kids pass a sentence around a circle and the output barely resembles the input. Pure transport, pure loss.

**Selection view.** Information enters an attention ecosystem. Receivers don't pass everything they get; they pass what's worth passing, for their own reasons. What survives is whatever wins on a fitness landscape: emotional resonance, identity reinforcement, status signaling, action affordance, novelty, controversy, narrative shape. What wins selection tends to be compact and resonant, so compression emerges from selection rather than from transit. Transport is a substrate. Selection is the dynamic. In the telephone-game frame: the parlor game forces every player to pass the message, so transport loss is the only operating mechanism. Real social networks don't have that rule. Players choose whether to pass at all, and what they choose to pass is what the selection view is pointing at.

## Test cases that distinguish them

If the two views made the same predictions, the choice wouldn't matter. They don't.

**Case 1: Specialist paper to "scientists say X" headline.**
- Transport says: the journalist had to compress to publish, the headline writer compressed further, the reader received the compressed form. Lossy hops did the work.
- Selection says: of all the findings in the paper, the headline writer *selected* the one with the highest fitness against attention-economy criteria. The rest is still in the paper.

Both explain the observed compression. Selection makes a sharper prediction: the surviving fragment isn't the *most important* finding, it's the *most fitness-fit* one. That matches reality. The fragment that escapes is usually the most surprising or actionable, not the most load-bearing.

**Case 2: Conspiracy theories spread faster than corrections.**
- Transport struggles. Both items have similar complexity. Both fit in a sentence. Transport cost is roughly the same.
- Selection explains it cleanly. Conspiracy theories offer in-group identity, action affordance, narrative shape, emotional payload. Corrections offer none of those. Same transport cost, very different fitness.

This is the case that pushed me toward selection as primary. Transport can't account for it without smuggling in selection through the back door.

**Case 3: Long-form podcasts carry complexity at scale.**
- Transport says: smaller, denser audience, self-selected for high budget. The complexity makes it through because per-hop loss is low.
- Selection says: hosts are selected for ability to make complexity feel like community membership and identity. Complexity survives because it's been re-encoded into a socially fit form, not because transport got cheaper.

The hosts-as-selected-for-charisma point matches the actual industry better. The complexity that survives is the complexity packaged into parasocial trust, not the complexity packaged into expository clarity. Selection wins.

**Case 4: Academic institutions preserve complex truth.**
- Transport says: institutions are infrastructure that lowers per-hop loss.
- Selection says: institutions impose alternative selection criteria (peer review, methodological rigor, credibility) that override the default attention-economy fitness landscape.

Selection again. The transport isn't cheaper inside academia; the selection rules are different. They favor rigor and replicability over virality.

**Case 5: Religions persist with full theology over millennia.**
- Transport says: bureaucracy as infrastructure for low-loss transit across generations.
- Selection says: religious memes have extraordinary fitness (meaning, community, identity, hierarchy, fear, hope) and have been selected over millennia for that fitness.

Both views work here, but the selection view explains *which* religions survived and *why* they look the way they do. The most successful religions are the ones with the highest social and emotional fitness, not the ones with the lowest transport costs.

## Where I land

Selection is primary. Transport is real but increasingly downstream.

Here's the version of the claim I'll commit to provisionally: **In modern digital networks, the cost of transport has collapsed to near zero, so selection becomes the dominant constraint on what spreads. In earlier eras with expensive transit (manuscripts, geographically limited print), transport was a binding constraint and a transport-style argument had real force. The relevant constraint has shifted as the medium has changed.**

That's a substantive historical claim and probably worth its own treatment. It also gives the book a sharper diagnosis of *why now*: not because human nature changed, but because the constraint that used to limit memetic chaos (slow expensive transport) has effectively vanished, exposing the underlying selection dynamics that were always there.

Four reasons selection wins for me, if the case studies weren't enough:

1. **Selection explains cases transport can't** (conspiracy vs. correction is the clearest).
2. **Selection explains the form of what survives transport, not just whether it survives.** Transport says "something got through." Selection says which version got through, and why.
3. **Selection accommodates transport as a special case.** If selection were uniform (everything gets passed equally), then what survives would be purely a function of transport cost. We don't see this. The asymmetry of what spreads tells us selection is active.
4. **The successful counter-examples involve modified selection rules, not modified transport.** Universities, peer review, religious bureaucracy — these all change what gets selected, not how cheaply it travels.

## What this changes for the book

This isn't a small reframing. It rewrites several chapters and sharpens the diagnosis.

**Chapter 5 rework.** The N-hop probability math in [[complexity-virality-tradeoff|the existing Chapter 5]] isn't wrong, but it's misleading. Each hop isn't just a re-encoding with loss. It's a selection event. The probability of being passed depends on memetic fitness at that hop, which depends on the receiver's environment, audience, and incentives. The "complexity ceiling" is a real phenomenon but it's produced by accumulated selection pressure, not accumulated transport loss.

**Hammer of the Witches vs. Copernicus reinterpreted.** Both used the same press. Hammer had massively higher *selection fitness* against contemporary criteria: fear, urgency, identity (good vs. evil), action affordance (find the witches), narrative completeness. Copernicus had no fitness against the selection landscape of his time. The complexity argument was hiding a selection argument the whole time.

**The manipulation surface gets stronger.** Original: bigger network → lower complexity ceiling → easier to weaponize. Selection version: the fitness landscape is itself a manipulable structure, and the bigger the network, the more value there is in tuning what gets selected. Recommendation algorithms aren't lossy transport. They're selection engines with adjustable weights. More dangerous claim, more accurate.

**Institutional carriers reframed.** They're not low-transport infrastructure. They're alternative-selection infrastructure. Peer review, editorial standards, apprenticeship lineages — these are all mechanisms for *what gets selected* rather than *how cheaply it travels*. This sharpens Chapter 8 (preservation vs. training): preservation might really mean "maintaining an institution with alternative selection criteria," and training might really mean "expanding the set of receivers for whom non-default criteria feel native."

**Part IV is sharper.** The integration problem isn't "how do we move complex truth across networks despite transport loss." It's "how do we build infrastructure where alternative selection criteria can operate without being eaten by the dominant fitness landscape." That's a more tractable question, even if the answers are harder.

**Political economy becomes load-bearing instead of optional.** If selection is primary and selection criteria are tunable, then *who tunes them* is the central political question. Current platforms tune for engagement because their business model demands it. A book about this can't skip political economy, because political economy is the mechanism by which the selection landscape gets set.

**AI as a new selection engine.** LLMs aren't just nodes with infinite budget. They're also selection engines: they choose what to surface, what to summarize, what to omit. The selection criteria they encode become the selection criteria of the people who use them. Either the biggest opportunity (build selection engines that favor truth and complexity) or the biggest risk (selection criteria of a handful of companies become the selection criteria of everyone). Probably both.

## Where I'm still uncertain

A few things I haven't worked out, and that the next pass should pressure-test:

- **Is the transport-to-selection shift really historical, or did selection always dominate?** I'm claiming selection became dominant as transport costs fell. Maybe selection always dominated and the "transport mattered historically" argument is wrong in retrospect. Need to read more memetics literature here.
- **How does selection work *inside* a single receiver?** I've been talking about selection at hops between receivers. But selection also happens within a receiver: what gets attended to, what gets remembered, what gets re-transmitted. The receiver-budget piece in [[info-time-limit]] is partly about within-receiver selection. The two need to be integrated.
- **Can the fitness landscape be characterized rigorously?** The book has a lot of leverage if we can enumerate or formalize the fitness criteria. O'Connor and Weatherall's models do some of this. Engage properly.
- **The name "selection" carries connotations I have to manage rather than fix.** I have now flagged the connotation issue in the opening of the note and committed to keeping the term anyway — renaming would buy clarity in one place at the cost of obscuring that the same mechanism is operating across both impersonal (algorithmic) and deliberate (editorial) surfaces. The remaining work is per-chapter discipline: each use of "selection" should make clear which kind of selection is operating where. Not a research item; a writing-discipline item.

## Refinement after feedback

The transport/selection dichotomy is less clean than I drew it above. Pushback I got back: preconditions, capacity, and *want* aren't independent variables. They're entangled through a feedback loop.

The loop: someone wants to engage with X → they engage → preconditions accumulate → they want to engage with deeper X → preconditions deepen → ... If the wanting stops, the loop dies and preconditions decay (or never form). If it keeps going, preconditions accumulate and the receiver's selection landscape for X-like material gets richer over time. **Want is the prime mover.** Both capacity (the transport piece) and selection criteria are downstream of it.

This collapses some of the apparent separability between transport and selection. They're aspects of one feedback dynamic, not two competing mechanisms. The selection-primary commitment still holds — what survives in a network is determined by selection criteria — but the criteria themselves are shaped by the cumulative history of past wants, and *those* are themselves outcomes of past selections operating on past media.

A new question opens at the medium level: what does the medium do to *want*? A medium that rewards shallow engagement cultivates want for shallow content, which trains preconditions for more shallow content. A medium that rewards sustained engagement cultivates want for complex content. The medium shapes the prime mover. That's a foundational question of its own, flagged in [[outline]] and probably deserving its own working note.

## Second refinement: modality, not primacy

One word in this note has been doing too much work: *primary*. "Selection is primary" was really four claims wearing one coat.

1. Selection is causally upstream of transport — transport is a "substrate," a thing that happens *downstream* of selection. **This one is false.** It contradicts the parallel-mechanisms picture the rest of the note commits to: if neither mechanism is downstream of the other, transport is not downstream of selection either.
2. Selection is the *currently binding* constraint. True — but that is the historical claim about transport-cost collapse, and it should stand on its own rather than hide inside "primary."
3. Selection is where manipulation, and any repair, has to act. True, and not historical at all.
4. Selection carries the explanation of the breakage — transport never broke, it only got cheaper. True.

The tell is the word *increasingly*, back in "Where I land": "transport is real but increasingly downstream." The instinct was right — selection matters more and more — but it got encoded as causal order when what it was tracking was a constraint that had shifted. So I'm dropping *primary*. It was always a ranking word, and this note already gave up the ranking.

What survives, said plain: **transport and selection are co-equal and parallel, but they differ in modality — transport is a directionless cost, selection is a criterial choice, and only a criterial choice can be aimed, captured, or repaired.** Transport scrambles; it has no preferred outcome. Selection has a *what-it-rewards*. That asymmetry — not causal order — is what the book actually runs on. The book centers selection because it is the only one of the two mechanisms with a steering wheel.

This also closes a gap I had been stepping over. Selection picks from a *set* — but nothing in "transport scrambles" says where the set comes from. Selection never generates its own options; it only ranks them. Something has to write the menu. **At every stage an idea is generated as variants by transport, bounded into an option space by the medium, and then picked from by selection — generate, bound, pick.** Transport is the scatter, the medium is the aperture, selection is the choice.

And that puts the medium in a harder light than [[medium-and-manipulation]] left it. The medium that writes the menu is doing a kind of selection too — it just did it once, in advance. **The medium is frozen selection: a criterial choice made once and baked into the substrate, until it stops looking like a choice and starts looking like a law of nature.** A 280-character limit was somebody's decision; to everyone living inside it, it is simply the shape of the world. That makes the medium the most powerful gate of all, and the least visible — it pre-empts selection. You never have to suppress the long, careful argument if the option space was built so the long, careful argument cannot form.

## Provisional commitment (current)

Transport and selection are co-equal, parallel, and entangled through the want-loop — but asymmetric in modality. Transport is a cost; selection is a choice. The medium and the runtime gate are one continuum of criterial constraint — frozen-and-slow at the medium end, live-and-fast at the gate end — with transport off that continuum entirely. The book is about the continuum, because the continuum is the part that can be tuned, and therefore captured, and therefore repaired.

One thing I am holding loosely: calling the medium "frozen selection" folds it into selection rather than naming it a third mechanism of its own. That keeps the modal picture clean — costs versus choices, two kinds of thing — and it buys the sharp point about invisibility. If the boundary-versus-gradient difference later needs its own slot, this is the seam to reopen.
