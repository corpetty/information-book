---
title: The Complexity / Virality Trade-off
tags:
  - information
---

I've been chewing on this one for years, and earlier drafts of this chapter put the complexity/virality trade-off as load-bearing for the whole book. Workshop pressure and a first-principles read together made clear that wasn't quite right. The actual structure (laid out in [[the-information-landscape|Chapter 1]]) is two parallel mechanisms: transport (lossy re-encoding) and selection (gates with local criteria), operating in series at every stage of an abstraction pipeline. This chapter is the transport half. Chapter 5b (still being drafted) is the selection half. Both are real, both do work, but they're easier to see one at a time.

The transport claim, said plain: **how easily a piece of information spreads across a social network is inversely related to how complex it is.** That's the intuition this chapter formalizes. The rest of it defines the terms carefully enough that the claim either holds up or shows me where it breaks.

## What I mean by "complex"

Complexity here isn't "fancy." It's not "uses big words." It's the number of preconditions a receiver needs to have already internalized for the idea to land as intended.

A few examples to anchor this:

- "Bitcoin is internet money" requires basically nothing. You have a concept of money, you have a concept of the internet. Done.
- "Bitcoin is a credibly neutral, fixed-supply settlement layer for value transfer that derives its security from a proof-of-work consensus mechanism designed to be expensive to attack and cheap to verify" requires that you've already absorbed maybe five or six distinct concepts before the sentence parses as anything other than noise.

Both sentences point at the same object. They are not equivalent. The first one is missing almost everything that matters, but it's also the only one that has any chance of reaching someone who hasn't done the homework.

The same gap shows up everywhere. "Climate change is real" vs. the actual contents of an IPCC working group report. "Inflation is bad" vs. the mechanics of monetary aggregates, velocity, and supply shocks. "AI is dangerous" vs. a specific argument about specification gaming in reward-modeled systems.

I'm going to call the high-precondition version the *complex* form and the low-precondition version the *compressed* form. Compression is lossy. Information is lost in the process.

Worth flagging up front: "preconditions a receiver needs" might be doing two jobs in this chapter that aren't the same axis. Sometimes complexity means precondition count (how much do you have to already know to follow). Sometimes it means depth, subtlety, informational entropy. Sometimes the real gating variable isn't preconditions at all but *handle-ability*: how many existing mental models the idea plugs into, how much emotional or identity-relevant content it carries, whether it tells the receiver what to do. If handle-ability is the real gating variable, "complexity ceiling" is the wrong frame and parts of this chapter need rebuilding. I'm leaving the precondition framing for now because it's the one I can be precise about, but the resolution probably belongs more to Chapter 5b (where selection-side variables are the focus) than to this chapter.

## The receiver has a budget

Go back to [[info-time-limit|the time-limit piece]] for a second. A human gets a tablespoon of weeks. Of those weeks, a fraction is spent on coherent thought. Of that fraction, a much smaller piece is available for absorbing genuinely new and difficult information. That's the budget.

The compressed form costs almost nothing to process. It plugs into existing mental structures. It evokes a feeling and moves on. The receiver can re-transmit it without having understood much of anything, because there isn't much to understand. We've built massive and perverse infrastructure for the distribution and sharing of those "feelings around ideas." It's called social media.

The complex form costs real budget. It requires the receiver to actually load the preconditions, work through the implications, and decide whether the new structure fits with everything else they believe. If any of the preconditions are missing, the budget gets spent on building those first, and then the original idea has to wait. Often it doesn't get its turn.

This asymmetry is part of the transport engine. Compressed ideas are free to receivers. Complex ideas are expensive. In a network where attention is finite and constantly contested, the free thing wins on volume.

Harari makes basically the same observation from the sender side in [[nexus-book|Nexus]]: anyone can say an untruth in an instant, and it takes much longer to prove it wrong or right. Cheap to fabricate, expensive to verify. Same asymmetry, viewed from the other end of the wire.

A refinement that's easy to miss the first time through: budget isn't fixed. Education, training, shared vocabulary, and accumulated engagement all expand what a receiver can absorb cheaply. Beneath that, *want* is the prime mover. Someone wants to engage with X → engages → preconditions accumulate → wants to engage with deeper X → preconditions deepen. Capacity, preconditions, and the selection criteria a receiver applies to future content are all downstream of cumulative wanting. This is part of why selection (Chapter 5b) ends up being inseparable from transport in practice: the receiver who can absorb the complex form is the receiver whose past wanting built the budget.

## The network has a ceiling

If you want the intuition before the structure: this is the telephone game. The one you played as a kid where ten people pass a sentence around a circle and what comes out the other end barely resembles what went in. Someone reading an early draft of this chapter pointed that out and they're right. It's exactly what's happening, just formalized.

For an idea to spread across a network, it has to survive every hop. Every hop is a re-encoding by a new sender with their own budget, their own preconditions, and their own audience. At each hop, the idea is either preserved, compressed, or distorted.

The probability of clean preservation across a single hop is some number less than one. Across N hops, it goes as roughly that probability to the Nth power. The bigger the network the idea has to cross, the more hops, the more aggressive the compression has to be just to survive transit.

Said differently: **the maximum complexity an idea can carry is bounded by the size of the network it needs to traverse.** Bigger network, lower complexity ceiling.

This is why the same paper that took someone 20 years to write shows up on Twitter as "scientists say X" within a day, and then becomes "X = good guys" or "X = bad guys" within a week. That's transport doing exactly what transport does for content to fit through. Whether journalism failed there is a different discussion.

One thing the telephone game gets right that the chapter has to be honest about: in the parlor game, every player is required to pass the message. That's pure transport. In real social networks, players choose whether to pass at all, and that choice is the selection step operating alongside transport at every hop. The transport math above tells you what happens to what gets passed. The selection math (Chapter 5b territory) tells you what gets passed at all. Both are real, both are operating, and neither is sufficient on its own. I'm developing the transport math here because it's the half this chapter is about.

## Same trade-off, different room

The [[optionality vs access|matplotlib/seaborn piece]] is this same dynamic in a different room. Matplotlib is the complex form. It can do anything, requires you to know what you're doing, has a high ceiling. Seaborn is the compressed form. It makes choices for you, loses some of the expressive surface, and in exchange becomes usable by people who would have bounced off the complex form entirely.

Same pattern with religions. Harari's framing in [[nexus-book|Nexus]] is useful here. He argues that information networks are bound by two things, *myths* and *bureaucracy*. The myth is the compressed form, the version a billion people can hold. The bureaucracy is the institutional machinery that keeps the complex form alive somewhere: the actual theology, with its nuance and contradictions and traditions of interpretation. Both have to be present for the network to last. The trouble starts when the myth gets confused for the theology, or when the bureaucracy forgets what it was supposed to be protecting.

Same pattern with political platforms. The white paper version has tradeoffs and constraints. The bumper sticker version has neither.

I think this is one trade-off, not many. The cost of generality is accessibility. The cost of accessibility is generality. Whether the medium is a software library, a religion, a scientific theory, or a piece of news, you are sitting on the same curve. (Which curve, precisely, is the open question flagged in the complexity section.)

## Hammer of the Witches, revisited

Harari has a useful pair of books from the early printing-press era. _The Hammer of the Witches_, a short and emotionally loaded manual for finding and prosecuting witches, sold out instantly, ran through edition after edition, and shaped the cultural image of witches so successfully that you can still feel its outlines today. _On the Revolutions of the Heavenly Bodies_, Copernicus's case for heliocentrism, came out in roughly the same window and got called by Arthur Koestler "an all-time worst seller." Same press, same century.

The pure-transport reading: the *Hammer* was compressed, Copernicus was complex, the compressed form traveled. That reading isn't wrong, but it isn't the deeper one. Both books were printed on the same press. Their physical transport costs were identical. What differed was *selection fitness* against contemporary criteria. The *Hammer* offered fear, urgency, in-group identity (good vs. evil), action affordance (find the witches), and narrative completeness. Copernicus offered a redrawn cosmology with no immediate action implications and no emotional payload. The compressed/complex distinction is real but it's downstream of the selection asymmetry that already favored the *Hammer*.

I'll keep using examples like this in the transport chapter because the compression intuition is real and useful. But the deeper read of any specific historical case usually requires both pipelines together, and the full Hammer/Copernicus treatment lives in Chapter 5b.

## The manipulation surface

Compressed ideas are not just easier to spread, they are easier to *weaponize*. A complex argument has too many handles to be reliably pushed in one direction. A compressed one has, at most, a couple of emotional valences, and an attacker only needs to attach themselves to the right one.

The pure-transport version of the argument: the bigger the network you're trying to influence, the lower the complexity ceiling, the closer the prevailing ideas sit to pure emotional payload, the higher the manipulation surface.

The version that includes selection (the one the book is actually arguing): the *gates* are tunable. Recommendation algorithms, editorial standards, platform mechanics, advertising incentives. These are selection criteria, not natural laws. Manipulating a large network isn't only about exploiting the low complexity ceiling. It's also about tuning the gates that determine what passes through in the first place. That's a strictly bigger manipulation surface than the transport-only argument implies, and a more dangerous one.

A friend put part of it cleaner than I could in the conversation that ended up in [[general-theme|the general theme note]]: "good memetics reduces down to evoking raw strong emotions." Yeah. And that's true partly because the gates have been tuned for engagement, and the gates have been tuned for engagement partly because they've been tuned for ad revenue. The emotional-payload result isn't an inherent property of mass networks. It's an inherent property of mass networks whose gates have been tuned this way.

## Counter-examples and what's still uncertain

Honest counter-examples I keep thinking about, plus the open questions they expose:

- **Wikipedia.** Long-form, complex, and somehow it propagates. Current read: Wikipedia isn't viral in the network-traversal sense. It sits in place and gets visited. That's a different dynamic and deserves its own treatment.
- **Long-form podcasts.** They carry complexity across millions of listeners. But they do it slowly, in hours-long chunks, and the audience self-selects for the budget required. That looks like a smaller, denser network masquerading as a big one. In the selection frame: the gate is "audience that already wants to engage at this depth," which is a different criterion than mass virality optimizes for.
- **Religions over centuries.** Christianity in its full theological form has reached billions, but it took two thousand years and a stack of institutions whose entire job is to carry the complexity through time. So the claim is really: *the maximum complexity an idea can carry across a network in a given window of time is bounded by the size of the network.* Add institutional carriers and you can stretch the window.
- **Harari's truth/order trade-off.** [[nexus-book|Nexus]] argues that information networks balance between truth and order, and that optimizing in one direction compromises the other. There's a tempting overlap with the trade-off I'm describing. Truth-seeking requires holding complexity; order requires shared simple myths. But Harari treats truth/order as a property of the network's *design* (decentralized vs. centralized, self-correcting vs. not), while the complexity/virality claim feels more like a transport constraint that sits underneath both. Related, possibly entangled, but not the same axis.

The institutional-carriers point is the right refinement of the original argument. Universities, religious orders, scientific journals, apprenticeship lineages: these are all *infrastructure for complexity*. Harari calls this bureaucracy, which gets read as the enemy of truth, but the reframe from [[nexus-book|Nexus]] is that it's also the apparatus that lets a network hold complex truth for longer than a single human lifespan. It expands the budget on the receiver side by pre-loading preconditions over years. It doesn't violate the trade-off, it shifts where the constraint binds. And it does this partly by maintaining alternative selection criteria, which is the bridge into Chapter 5b.

Most of our current information technology does the opposite. It expands the size of the network without expanding the budget, and the gates are tuned for engagement rather than for complexity preservation. So the ceiling drops and nothing catches it.

## What this chapter is and isn't doing

This chapter is the transport half of the book's structural argument. It describes what happens to information as it travels and gets compressed across networks. The compression-at-scale picture, the receiver budget, the network ceiling, the telephone-game intuition. It's a real mechanism, well-grounded in everyday experience, useful for the parts of the argument it covers.

It's not the whole story. The other half is selection: what passes through the gates at all, by what criteria, who tunes them. That's Chapter 5b. Selection is in some ways the more powerful mechanism, especially in the digital era where physical transport costs have collapsed and the gates have become the binding constraint. The full Hammer-vs-Copernicus reading, the resolution of the complexity-doing-two-jobs question, the question of when compression preserves truth versus inverting it (Chapter 5c territory), and the engagement with prior art that directly challenges the transport-only framing (Postman, Mercier, O'Connor & Weatherall) all belong to other chapters.

There's also a third thread that neither chapter quite captures yet. Manufactured content (covered in [[the-information-landscape|Chapter 1]]) bypasses measurement entirely and gets injected into the pipeline at later stages. Transport and selection both operate on it the same as they operate on anything else, which means the downstream gates can't easily tell measured content from invented content. Worth keeping in view as you read the rest.

If you've read this far and you think I've got the relationship wrong, I'd really like to hear it. Hit me up. I'd rather find out now than ten chapters from now.
