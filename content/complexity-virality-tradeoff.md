---
title: The Complexity / Virality Trade-off
tags:
  - information
---

I've been chewing on this one for years and I don't think I've ever stated it cleanly. Here goes.

**How easily a piece of information spreads across a social network is inversely related to how complex it is.**

That's the whole claim. Everything else in this chapter is me defining the terms carefully enough that the claim either holds up or shows me where it breaks.

## What I mean by "complex"

Complexity here isn't "fancy." It's not "uses big words." It's the number of preconditions a receiver needs to have already internalized for the idea to land as intended.

A few examples to anchor this:

- "Bitcoin is internet money" requires basically nothing. You have a concept of money, you have a concept of the internet. Done.
- "Bitcoin is a credibly neutral, fixed-supply settlement layer for value transfer that derives its security from a proof-of-work consensus mechanism designed to be expensive to attack and cheap to verify" requires that you've already absorbed maybe five or six distinct concepts before the sentence parses as anything other than noise.

Both sentences point at the same object. They are not equivalent. The first one is missing almost everything that matters, but it's also the only one that has any chance of reaching someone who hasn't done the homework.

The same gap shows up everywhere. "Climate change is real" vs. the actual contents of an IPCC working group report. "Inflation is bad" vs. the mechanics of monetary aggregates, velocity, and supply shocks. "AI is dangerous" vs. a specific argument about specification gaming in reward-modeled systems.

I'm going to call the high-precondition version the *complex* form and the low-precondition version the *compressed* form. Compression is lossy (information is lost in the process). Always.

## The receiver has a budget

Go back to [[info-time-limit|the time-limit piece]] for a second. A human gets a tablespoon of weeks. Of those weeks, a fraction is spent on coherent thought. Of that fraction, a much smaller piece is available for absorbing genuinely new and difficult information. That's the budget.

Now consider what happens when a piece of information shows up in front of that receiver.

The compressed form costs almost nothing to process. It plugs into existing mental structures. It evokes a feeling and moves on. The receiver can re-transmit it without having understood much of anything, because there isn't much to understand. We've built massive and perverse structures for making distribution and sharing of those "feelings around ideas" incredibly simple. It's called social media. 

The complex form costs real budget. It requires the receiver to actually load the preconditions, work through the implications, and decide whether the new structure fits with everything else they believe. If any of the preconditions are missing, the budget gets spent on building those first, and then the original idea has to wait. Often it doesn't get its turn.

This asymmetry is the whole engine. Compressed ideas are free to receivers. Complex ideas are expensive. In a network where attention is finite and constantly contested, the free thing wins on volume. Social media has been _very_ successful. 

Harari makes basically the same observation from the sender side in [[nexus-book|Nexus]]: anyone can say an untruth in an instant, and it takes much longer to prove it wrong or right. Cheap to fabricate, expensive to verify. Same asymmetry, viewed from the other end of the wire.

## The network has a ceiling

Here's where it gets interesting, and where I think the claim earns its keep as a *function* rather than a vibe.

For an idea to spread across a network, it has to survive every hop. Every hop is a re-encoding by a new sender with their own budget, their own preconditions, and their own audience. At each hop, the idea is either preserved, compressed, or distorted.

The probability of clean preservation across a single hop is some number less than one. Across N hops, it goes as roughly that probability to the Nth power. The bigger the network the idea has to cross, the more hops, the more aggressive the compression has to be just to survive transit.

Said differently: **the maximum complexity an idea can carry is bounded by the size of the network it needs to traverse.** Bigger network, lower complexity ceiling.

This is why the same paper that took someone 20 years to write shows up on Twitter as "scientists say X" within a day, and then becomes "X = good guys" or "X = bad guys" within a week. That's not a failure of journalism (maybe it is, that's a different post). That's the network doing exactly what it has to do for the content to fit through it.

Harari makes the same point with a pair of books from the early printing-press era. _The Hammer of the Witches_, a short and emotionally loaded manual for finding and prosecuting witches, sold out instantly, ran through edition after edition, and shaped the cultural image of witches so successfully that you can still feel its outlines today. _On the Revolutions of the Heavenly Bodies_, Copernicus's case for heliocentrism, came out in roughly the same window and got called by Arthur Koestler "an all-time worst seller." Same press, same century. The compressed form traveled, the complex form sat. The trade-off was operating in deep history, well before social media existed to amplify it.

## Same trade-off, different room

The [[optionality vs access|matplotlib/seaborn piece]] is this same dynamic in a different room. Matplotlib is the complex form. It can do anything, requires you to know what you're doing, has a high ceiling. Seaborn is the compressed form. It makes choices for you, loses some of the expressive surface, and in exchange becomes usable by people who would have bounced off the complex form entirely.

Same pattern with religions. Harari's framing in [[nexus-book|Nexus]] is useful here. He argues that information networks are bound by two things, *myths* and *bureaucracy*. The myth is the compressed form, the version a billion people can hold. The bureaucracy is the institutional machinery that keeps the complex form alive somewhere: the actual theology, with its nuance and contradictions and traditions of interpretation. Both have to be present for the network to last. The trouble starts when the myth gets confused for the theology, or when the bureaucracy forgets what it was supposed to be protecting.

Same pattern with political platforms. The white paper version has tradeoffs and constraints. The bumper sticker version has neither.

I think this is one trade-off, not many. The cost of generality is accessibility. The cost of accessibility is generality. Whether the medium is a software library, a religion, a scientific theory, or a piece of news, you are sitting on the same curve.

## The manipulation surface

Here's the part that started this whole project for me.

Compressed ideas are not just easier to spread, they are easier to *weaponize*. A complex argument has too many handles to be reliably pushed in one direction. A compressed one has, at most, a couple of emotional valences, and an attacker only needs to attach themselves to the right one.

If you accept the first two sections of this chapter, the third one is just math. The bigger the network you're trying to influence, the lower the complexity ceiling, the closer the prevailing ideas sit to pure emotional payload, the higher the manipulation surface. A friend put it cleaner than I could in the conversation that ended up in [[general-theme|the general theme note]]: "good memetics reduces down to evoking raw strong emotions." Yeah. That's a feature of the medium, not a flaw in the people using it.

This is, I think, why our current information environment feels the way it does. The population didn't get dumber. The networks got bigger, the complexity ceiling dropped, and the prevailing ideas drifted toward whatever fits through that smaller opening. Same people, lower-resolution ideas.

## Where I'm uncertain

I'm calling this a function. I'm not sure that's the right word. It might be a strong statistical regularity rather than a clean mathematical relationship. I'd love for someone with better tools than mine to push on this, because if it really is a function, you could in principle measure the complexity ceiling of a given network and predict what it can and can't hold.

Some honest counter-examples I keep thinking about:

- **Wikipedia.** Long-form, complex, and somehow it propagates. My current read: Wikipedia isn't viral in the network-traversal sense. It sits in place and gets visited. That's a different dynamic, and worth its own chapter.
- **Long-form podcasts.** They carry complexity across millions of listeners. But they do it slowly, in hours-long chunks, and the audience self-selects for the budget required. That looks like a smaller, denser network masquerading as a big one.
- **Religions over centuries.** Christianity in its full theological form has reached billions, but it took two thousand years and a stack of institutions whose entire job is to carry the complexity through time. So maybe the claim is really *the maximum complexity an idea can carry across a network in a given window of time is bounded by the size of the network*. Add institutional carriers and you can stretch the window.
- **Harari's truth/order trade-off.** [[nexus-book|Nexus]] argues that information networks balance between truth and order, and that optimizing in one direction compromises the other. There's a tempting overlap with what I'm describing here. Truth-seeking requires holding complexity. Order requires shared simple myths. But Harari treats truth/order as a property of the network's *design* (decentralized vs. centralized, self-correcting vs. not), while my complexity/virality claim feels more like a transport constraint that sits underneath both. Related, possibly entangled, but I don't think they're the same axis. Not committing to a mapping yet.

I think the institutional carriers point is the right refinement. Universities, religious orders, scientific journals, apprenticeship lineages: these are all *infrastructure for complexity*. Harari calls this bureaucracy. Bureaucracy gets read as the enemy of truth, but the reframe from [[nexus-book|Nexus]] is that it's also the apparatus that lets a network hold complex truth for longer than a single human lifespan. It expands the budget on the receiver side by pre-loading preconditions over years. It doesn't violate the trade-off, it shifts where the constraint binds.

Which is interesting, because most of our current information technology does the opposite. It expands the size of the network without expanding the budget. So the ceiling drops and nothing catches it.

## Why this is the load-bearing chapter

Everything else in this book either sets up this claim or follows from it.

The [[info-time-limit|time-limit piece]] tells you why the receiver budget exists. The [[optionality vs access|optionality/access piece]] tells you why compression is structurally unavoidable. The [[the-information-landscape|information landscape piece]] tells you the specific pipeline by which compression happens at scale. The [[general-theme|conclusion]] tells you what to do about it.

This chapter is the joint. If the function holds, the rest of the book is forced. If it doesn't, the rest of the book needs to be rebuilt around whatever the real relationship is.

So if you've read this far and you think I've got the relationship wrong, I'd really like to hear it. Hit me up. I'd rather find out now than ten chapters from now.
