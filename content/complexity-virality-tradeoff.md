---
title: "Chapter 5: The Complexity / Virality Trade-off"
description: "Why the easy-to-share version of an idea always wins over the accurate one: every retelling costs the listener effort and loses a little, and across a big enough network the losses compound until only the slogan is left."
aliases:
  - precondition count
  - viral vs accurate
tags:
  - information
---

Think about how a real discovery reaches you. A scientist spends twenty years on a result; you meet it as "scientists say X," and a week later it has hardened into "X is what the good guys believe." Each retelling made it a little easier to pass along and stripped a little more of the actual finding out of it. This chapter is about that exchange rate, the rule that the easier an idea is to spread, the less of the real thing it can carry, and about why the cheap, slightly-wrong version reliably out-travels the accurate one.

[[the-information-landscape|Chapter 1]] split the pipeline into two mechanisms: transport, which reshapes an idea in transit, and selection, which decides whether it moves at all. This chapter is transport. [[selection-as-other-engine|The next]] is selection. Both are real; they are easier to see one at a time. The transport claim, said plain: **how easily a piece of information spreads across a social network is inversely related to how complex it is.**

One scope note. The worked cases in [[case-studies-and-three-realities|Chapter 2]] are all *objective* claims, and transport applies to them cleanly. For [[three-realities|intersubjective]] truths (currencies, brands, nations, the truths made by a network's agreement rather than by reality) reach is not how far a truth travels but partly how much of it there is, since the billionth holder of a currency doesn't learn its value, they add to it. [[intersubjective-truth|The intersubjective note]] works that case; here I stay with the objective one.

## What "complex" means

Complexity here isn't "fancy" or "uses big words." It is the number of preconditions a receiver has to already hold for the idea to land as intended. Two sentences about the same object:

- "Bitcoin is [[bitcoin-internet-money|internet money]]" requires basically nothing: a concept of money, a concept of the internet, done.
- "Bitcoin is a credibly neutral, fixed-supply settlement layer whose security comes from proof-of-work consensus designed to be expensive to attack and cheap to verify" needs five or six absorbed concepts before the sentence parses as anything but noise.

Both point at the same thing. The first is missing almost everything that matters, and it is also the only one with any chance of reaching someone who hasn't done the homework. The same gap is everywhere: "climate change is real" versus an IPCC working-group report, "inflation is bad" versus the mechanics of monetary aggregates. I'll call the high-precondition version the [[complex-form|complex form]] and the low-precondition version the [[compressed-form|compressed form]]. Compression is lossy; information is lost in it.

One warning about the word. "Complex" here means *precondition count* and nothing else: how much you must already know for the idea to land. Whether an idea is emotionally grabby, or tells you what to do, is a different property, [[handle-ability|handle-ability]], and [[selection-as-other-engine|the next chapter]] handles it.

## The receiver has a budget

A human gets a [[receiver-budget|tablespoon of weeks]], a fraction of it spent on coherent thought, a much smaller piece available for absorbing genuinely new and difficult material. That is the budget, and the two forms draw on it very differently. The compressed form costs almost nothing: it plugs into structures you already have, evokes a feeling, and moves on, and you can pass it along without having understood much, because there isn't much to understand. We have built enormous infrastructure for sharing those feelings-around-ideas. It's called social media. The complex form costs real budget: you have to load the preconditions, work the implications, and fit the new structure against everything else you believe, and if a precondition is missing the budget goes to building that first while the original idea waits, often past its turn.

That asymmetry is the transport engine. In a network where attention is finite and contested, the free thing wins on volume. Harari makes the same point from the sender's side in [[nexus-book|Nexus]]: anyone can utter an untruth in an instant, and disproving it takes far longer. Cheap to fabricate, expensive to verify. And which form a receiver can afford is not fixed: [[info-time-limit|Chapter 3]] showed capacity per hour is trainable, so past [[want-as-prime-mover|wanting]] that built structure in a domain is what lets someone absorb its complex form at all. The receiver who can pay for depth is the one whose earlier wanting bought the budget, and that wanting was itself shaped by the [[medium-and-manipulation|medium that trained it]].

## The network has a ceiling

This is the [[telephone-game|telephone game]], the one where ten people pass a sentence around a circle and what comes out barely resembles what went in, just formalized. For an idea to cross a network it has to survive every hop, and every hop is a re-encoding by a new sender with their own budget and audience, at which the idea is preserved, compressed, or distorted. The probability of clean preservation across one hop is some number below one; across N hops it goes roughly as that probability to the Nth power. At 90% per hop, ten retellings leave about a one-in-three chance the idea survives intact, and a hundred retellings leave essentially none. Small per-hop losses compound into near-total loss across a big network, so the bigger the network an idea must cross, the more aggressive the compression has to be just to survive transit.

**The maximum complexity an idea can carry is bounded by the size of the network it needs to traverse.** Bigger network, lower complexity ceiling. This is why a paper that took twenty years to write shows up as "scientists say X" within a day and "X = good guys" within a week. That is transport doing what transport does to make content fit.

One thing the parlor game gets wrong: there, every player must pass the message, which is pure transport. In real networks players choose whether to pass at all, and that choice is selection operating alongside transport at every hop. The transport math tells you what happens to whatever gets passed; the selection math ([[selection-as-other-engine|Chapter 5b]]) tells you what gets passed at all. Neither is sufficient alone.

## The same curve, at design time

[[optionality vs access|Chapter 4]] walked this trade-off through five domains and landed the reframe that matters here: the curve is not a property of any medium or domain, it is the receiver-budget constraint reflected in artifact design. Transport describes what happens to an idea *in flight*; optionality-versus-access describes what its creators choose *at design time*, where on the curve to sit. Same constraint, two points. [[brief-history-of-time|A Brief History of Time]] is the clean case of deliberate optionality-shedding: Hawking's editor cut every equation past *E = mc²*, trading precision the reader's budget couldn't pay for the access that sold 25 million copies. The compressed form there was *designed* against the budget; this chapter is about what happens to a less deliberately compressed version when it has to travel.

It is one trade-off, not many. The cost of generality is accessibility and the cost of accessibility is generality, whether the artifact is a software library, a religion, a theory, or a news item. And until [[ai-as-new-node|Chapter 11]]'s decompression-on-demand, it has been a hard constraint: every artifact had to pick a point on the curve, and moving meant building a second artifact at the other end.

## Hammer of the Witches, revisited

A pair of books from the early printing press makes the point, with a caution. *The Hammer of the Witches* (1486), a short, emotionally loaded manual for finding and prosecuting witches, ran through edition after edition and burned its image of the witch so deep into European culture you can still feel the outline. *On the Revolutions of the Heavenly Bodies* (1543), Copernicus's case for heliocentrism, came two generations later and reached a tiny specialist readership; Arthur Koestler called it "an all-time worst seller," though Owen Gingerich later showed the first edition actually sold out and was annotated cover to cover by working astronomers. So the honest contrast is popular reach against specialist reach, not read against unread.

The pure-transport reading is that the *Hammer* was compressed and Copernicus was complex, so the compressed form traveled. That's not wrong, but it's incomplete: both used the same press, so their transport costs were identical. What differed was fitness against contemporary criteria. The *Hammer* offered fear, urgency, an in-group, and something to *do* (find the witches); Copernicus offered a redrawn cosmology with no emotional payload and nothing to act on. The compression gap is real but downstream of a selection gap that already favored the *Hammer*, which is why the full reading waits for [[selection-as-other-engine|Chapter 5b]]. The modern version is [[case-studies-and-three-realities|Chapter 2]]'s [[power-posing|power posing]]: the "stand like Wonder Woman" original is low-complexity and easy to pass; the correction ("the underpowered effect didn't replicate") costs more budget, so it keeps losing even after consensus ratified it.

## The manipulation surface

Compressed ideas are not just easier to spread; they are easier to weaponize. A complex argument has too many handles to be reliably pushed one way. A compressed one has at most a couple of emotional valences, and an attacker needs only to grab the right one. The transport-only version of the worry: the bigger the network, the lower the complexity ceiling, the closer the prevailing ideas sit to pure emotional payload, the larger the [[manipulation-surface|manipulation surface]].

The fuller version adds selection: the gates are tunable. Recommendation ranking, editorial standards, platform mechanics, ad incentives are selection criteria, not natural laws, so manipulating a large network means exploiting the low ceiling *and* tuning the gates that decide what passes. Later, when the book reaches who owns those gates, this gets a name, [[capture-taxonomy|capture]], and the hardest captures to recover from are the [[consumer-key-vs-surface-capture|consumer-key]] ones that install inside people rather than in front of them. A friend put the transport half plainly in the conversation behind [[general-theme|the general-theme note]]: "good memetics reduces down to evoking raw strong emotions." True, and true partly because the gates have been tuned for engagement, which [[political-economy-of-attention|Chapter 10]] argues is the captured equilibrium of the platform business model rather than an accident.

## Counter-examples

The honest counter-examples, and what they expose:

- **Wikipedia.** Long, complex, and it propagates anyway. But it isn't viral in the network-traversal sense; it sits in place and gets visited, a different dynamic that deserves its own treatment.
- **Long-form podcasts.** They carry complexity to millions, but slowly, in hours-long chunks, to an audience that self-selects for the budget required. That is a smaller, denser network wearing a big one's clothes.
- **Religions over centuries.** Christianity's full theology has reached billions, but it took two thousand years and a stack of institutions whose whole job is to carry complexity through time. So the sharper claim is that **the maximum complexity an idea can carry across a network in a given window of time is bounded by the size of the network**; add institutional carriers and you stretch the window.
- **Harari's truth/order trade-off.** [[nexus-book|Nexus]] argues networks balance truth against order, and there's a tempting overlap with this chapter. But Harari treats truth/order as a property of the network's *design*, while complexity/virality is a transport constraint sitting underneath. Related, maybe entangled, not the same axis.

The religions case names the right refinement: universities, orders, journals, and apprenticeship lineages are infrastructure for complexity, holding the un-compressed form and expanding the budget that can absorb it. [[preservation-vs-training|Chapter 8]] splits that work into preservation and training and reads the modern collapse through it. Most current information technology does the opposite: it grows the network without growing the budget and tunes the gates for engagement, so the ceiling drops and nothing catches it. What compression does to *truth*, as opposed to detail, is [[truth-compression-and-when-each-wins|Chapter 5c]]; who tunes the gates is [[political-economy-of-attention|Chapter 10]]; and whether a faithful LLM can soften the constraint itself, the first candidate for that the book has found, is [[ai-as-new-node|Chapter 11]]. If you think I have the relationship between transport and selection wrong, I would rather hear it now than late.

---

[[optionality vs access|← Chapter 4: Optionality vs. Access]] · [[selection-as-other-engine|Chapter 5b: Selection As The Other Engine →]]
