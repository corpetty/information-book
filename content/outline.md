---
title: Information Book — Outline
tags:
  - information
---

Working table of contents. Living doc. Recently restructured in response to a first-principles critique of the original frame (see "Foundational questions still being worked out" below). Earlier version was more confident than the work currently justifies.

## Thesis (provisional)

Something has broken in how complex ideas move through our information environment, and it's worth a book. The original framing — virality is inversely related to complexity, with institutional carriers preserving the complex form — points at the right phenomenon but may be using the wrong primary mechanism. Two foundational questions need to be resolved before the thesis can be stated cleanly:

1. Is the right model **transport** (complexity dissipates in transit through lossy hops) or **selection** (what survives is whatever is compressible-and-resonant, and transport is downstream)? Could be both, in which case the book has to integrate them.
2. Where does **truth value** enter the model? Compression sometimes preserves approximate truth, sometimes inverts it, sometimes is orthogonal to it. The original frame is silent on this and is therefore morally neutral when the book wants to be alarmed.

The prescriptive arc is also being rebuilt. The hard problem appears to be **integration between networks that don't share preconditions**, not fragmentation into smaller ones.

## Status

Drafted: [[info-time-limit]] (Chapter 3, partial), [[optionality vs access]] (Chapter 4, software-only), [[the-information-landscape]] (Chapter 1, now fleshed out with both transport and sibling selection pipelines), [[complexity-virality-tradeoff]] (Chapter 5, full draft in workshop, gaps now flagged inline at the end of that file). The conclusion lives raw in [[general-theme]] (a conversation transcript) and needs to be unpacked into Part IV. Most of Parts III and IV are unwritten and the structure of Part IV has been substantially revised.

## Foundational questions still being worked out

These need to be resolved (or at least committed to provisionally) before more chapters get drafted, because the answers reshape multiple later chapters.

- **Transport vs. selection.** Originally framed as "which mechanism is primary?" Worked through in [[transport-vs-selection]] (provisional answer there: selection-primary, with *want* as the prime mover). Refined further by the fleshed-out [[the-information-landscape|Chapter 1]], which actually walks through both pipelines side by side. Updated answer: the original framing was wrong. Transport (lossy re-encoding) and selection (gates with local criteria) are parallel mechanisms operating in series at every stage of the abstraction pipeline. Both do work at every stage. Neither is downstream of the other. Chapter 1 also surfaced a third source the original framing missed: manufactured content that bypasses measurement entirely and gets injected at later stages (astrology, propaganda, AI-generated text). Implications still stand: Chapter 5 needs rework (its N-hop math is one slice of the picture, mostly visible at the meme stage); the manipulation surface argument gets sharper because the gates are tunable; political economy is load-bearing because *who tunes the gates* is the central question; AI moves from optional to central because it operates as both a new kind of node and a new kind of selection engine.
- **The medium and manipulation.** Can core truths survive a medium that allows a lot of manipulation? The medium isn't a neutral substrate that selection happens on top of; it's part of the selection mechanism. Different media expose different selection criteria, allow different manipulation surfaces, and shape what kinds of want they cultivate in receivers. McLuhan's "the medium is the message" is the canonical reference; the sharper question is *which media let core truth survive which kinds of manipulation*. Probably the next foundational note to draft.
- **Transferable vs. specialized preconditions.** Some preconditions are field-general (statistical literacy, critical reading, the disposition to look for evidence) and help receivers engage with many domains. Others are field-specific and don't transfer. People with transferable preconditions are the natural bridge nodes between specialist communities. Lives under Chapter 8 (preservation vs. training) and Chapter 9 (integration problem) for now, not its own chapter.
- **Where does truth value live?** Compression doesn't always degrade truth. Sometimes it preserves a good approximation. Sometimes it inverts. Sometimes it wanders into orthogonal territory. The book needs a story about when each happens. Currently there isn't one, which means the worry the book wants to express doesn't follow from the formal structure.
- **Is "complexity" doing two jobs?** Chapter 5 defines complexity as "preconditions a receiver needs" and then slides into using it for nuance, depth, informational entropy. The real gating variable might be *handle-ability* (emotional/identity/action-affordance fit) rather than precondition count. If so, the frame needs renaming and parts of Chapter 5 reworking.
- **Are receiver budgets fixed or trainable?** The current model treats budget as a constraint. Education, training, and shared vocabulary expand budget. "Institutional carriers" was hiding two distinct functions: preserving the complex form AND training receivers to handle it. These need separate chapters.
- **Part IV: integration or fragmentation?** The original prescription was "multiple smaller networks." The critique points out that small networks have their own internal compression dynamics, tend toward echo chambers rather than bubbles (C. Thi Nguyen's distinction), and that the real hard problem is how complex truth moves *between* networks that don't share preconditions. Part IV is being rebuilt around integration.

## Structure (working revision)

### Part I. The Pipeline

How information moves from reality to people.

**Chapter 1: The Information Landscape.** Fleshed out at [[the-information-landscape]]. Walks through the transport pipeline (The Out There → Raw Data → Insight → Theory → News → Meme) stage by stage, then introduces the sibling selection pipeline (each transport stage has a corresponding gate with local criteria: funding/agenda → publishability → peer review → newsworthiness → memetic fitness). Closes with how the two pipelines fit together, where the medium fits, and a note that the gates are tunable institutional choices, not laws of nature. Still pressure-testable, but the structural machinery is now in place.

**Chapter 2: Case Studies and Three Realities.** Chapter 1 did the abstract structural work. Chapter 2 should bring it to ground with case studies of specific pipelines: a scientific finding that made it all the way to meme (with the distortions traced), a finding that died at consensus, a finding that died at curation, a meme that traveled with no underlying theory at all. Also the right home for Harari's three-realities framework (objective / subjective / intersubjective) from [[nexus-book]] — the pipeline operates differently on each kind of reality, and being explicit about that matters before the rest of the book.

### Part II. Why It Has To Be Lossy (And Selective)

The structural reasons compression and selection both operate.

**Chapter 3: The Human Time Budget.** Tablespoon of weeks, lens shaped by trauma and culture, asymmetry between nominal and effective mental hours. Drafted as [[info-time-limit]], first half only. Needs the "How much information can we take in?" section. After the critique: must note that budget isn't fixed, it's trainable through shared vocabulary, education, and cultural priors. This sets up a key distinction Part IV will rely on.

**Chapter 4: Optionality vs. Access.** The general-vs-usable trade-off. Drafted as [[optionality vs access]] using matplotlib/seaborn. Needs generalization beyond software: religions, political platforms, scientific popularization, legal codes. Same curve everywhere.

**Chapter 5: The Complexity / Virality Trade-off.** Was billed as load-bearing. Now *provisionally* load-bearing pending resolution of foundational questions. Drafted as [[complexity-virality-tradeoff]] with Harari worked in. Gaps now flagged at the end of that file. Likely needs significant rework once transport-vs-selection and the complexity definition are resolved.

**Chapter 5b (now needed): Selection As The Other Engine.** Selection has been confirmed (in [[transport-vs-selection]] and in [[the-information-landscape|Chapter 1]]) as a real mechanism operating in parallel with transport at every stage. Needs its own chapter. Memetic fitness, status signaling, identity reinforcement, action affordance, novelty, confirmation. Engage with Cailin O'Connor and James Owen Weatherall's *The Misinformation Age* and Hugo Mercier's *Not Born Yesterday*. Likely framing: Chapter 5 stays as the transport-focused argument (within-stage compression dynamics, most visible at the meme stage), Chapter 5b runs alongside as the selection-focused argument (cross-stage gates with local criteria). The two together replace the original load-bearing claim about a single mechanism.

**Chapter 5c (new, possible): Truth, Compression, and When Each Wins.** When does the compressed form preserve approximate truth, when does it invert, when is it orthogonal? Probably the right home for Harari's truth/order axis re-examined. Closes the moral-neutrality gap and gives the book its actual stakes.

### Part III. The Bridge Zone

Where complex specialist knowledge gets transformed (and often destroyed) on its way to mass audiences.

**Chapter 6: Where It All Gets Fucked Up.** Skeleton. The space between deep specialists and mass audiences. Journalism, popularizers, influencers, AI summarizers. Who lives in this zone, what incentives shape what they do, examples of catastrophic distortion (COVID epidemiology, nutrition science, monetary policy popularization). After the critique: this is also where *selection pressures are most intense*. The bridge zone is less about passive lossy compression and more about active reshaping for audience effect.

**Chapter 7: Emotional Memetics As The Floor.** Skeleton. Once the network is big enough, what propagates is what evokes raw strong emotions. Argument for why this is the stable equilibrium under whatever dynamics turn out to be primary. Must engage with Hugo Mercier's challenge that humans have more robust epistemic vigilance than the easy-manipulation narrative implies. If Mercier is largely right, this chapter needs serious revision.

### Part IV. A Way Through (rebuilt around integration)

Hypothesis territory. Substantially restructured after the critique. Originally about fragmenting into smaller networks; now about integration between networks that don't share preconditions.

**Chapter 8: Preservation vs. Training — Two Functions of Institutional Carriers.** New chapter. Splits what Harari's "bureaucracy" was bundling. *Preservation* = keeping the complex form alive somewhere. *Training* = expanding receiver budgets so they can engage with it. These need different infrastructure. Universities did both. Modern equivalents will have to as well. Open sub-thread: training in *transferable* preconditions (statistical literacy, critical reading) is a different intervention than training in *specialized* preconditions (becoming a physicist). The book's prescription should probably tilt toward transferable, since specialized training scales badly and integration depends on transferable.

**Chapter 9: The Integration Problem.** New chapter, replaces the old "Multiple Small Networks > One Big One." How does complex truth move *between* networks that don't share preconditions? C. Thi Nguyen on epistemic bubbles vs. echo chambers is foundational here. The argument for plural participation in small groups (from [[general-theme]]) is still in play but no longer the headline. The headline is what stitches those groups together without flattening them. Open sub-thread: people carrying transferable preconditions are the natural bridge nodes between specialist communities; the integration problem is largely about cultivating and protecting those bridge nodes.

**Chapter 10: Political Economy of Attention.** New chapter. Who owns the infrastructure, what they optimize for, why engagement maximization exists, why institutional carriers are being defunded and out-competed. Should pick up the *cost-shifting from producers to consumers* framing from [[the-democratization-paradox|the democratization paradox post]] — when barriers fall, the cost of quality assessment doesn't disappear, it transfers from producers to consumers, reviewers, and maintainers who have no more time. The current information environment isn't an emergent property of network size, it's a designed system reflecting specific incentives. Any prescription has to engage with this or it reads as naive.

**Chapter 11: AI as a New Kind of Node.** New chapter. LLMs violate the receiver-budget model. They can decompress on demand (expand a compressed prompt into a full explanation with preconditions pre-loaded) and compress aggressively (summarize anything into a one-liner). Salvation or worst-case depending on deployment. Probably both. Must engage with the *creation cheap / review expensive* asymmetry from [[the-democratization-paradox]] — when content generation scales faster than curation infrastructure, the noise wins regardless of how many gems are in the flood. LLMs accelerate the asymmetry on both sides.

**Chapter 12: Infrastructure for Integration.** Synthesis chapter. What would tech look like if it preserved integrity across networks rather than flattening it? Pulls together preservation-and-training (Ch 8), integration tooling (Ch 9), responses to political economy (Ch 10), and AI as a potential carrier (Ch 11). The *curation layer* concept from [[the-democratization-paradox]] is the right frame here — systems that decouple access from quality assurance, combining low barriers to enter with robust mechanisms to surface the best work. Examples to engage with: Wikipedia's editorial apparatus, Stack Overflow's reputation-weighted moderation, academic preprint + peer review hybrid models.

## Prior art the book needs to engage with

Not just citations. These authors have already worked through specific gaps in the original frame and the book gets stronger by engaging with them.

- **[[the-democratization-paradox|Corey's own democratization paradox post]].** Covers the same territory from the barriers/volume angle. Treat as a primary source the book draws from rather than separate work. Concepts that feed directly into book chapters: *curation layer* (= institutional carriers / alternative-selection infrastructure), *feedback loop test* (when selection criteria can self-correct vs. produce persistent noise), *cost-shifting from producers to consumers* (what breaks when curation can't keep up with production), *inverted-U relationship* (refines the binary "small vs. large" thinking — there's an optimum), *creation cheap / review expensive* (the book's diagnosis in one line). Also references Sturgeon, Simon's attention economy, Keen/Lanier/Nichols, Christensen, von Hippel, Tim Wu — much of which the book will want to engage with directly.
- **Neil Postman, *Amusing Ourselves to Death*.** This argument applied to television, decades ago. The book needs to know what it's adding past Postman.
- **Hugo Mercier, *Not Born Yesterday*.** Direct challenge to the "people are easily manipulated by simple memes" thread. If he's right, the manipulation surface argument needs serious revision.
- **Cailin O'Connor & James Owen Weatherall, *The Misinformation Age*.** Formal network models of belief propagation. Shows that what kills truth in networks is selection on credibility plus social pressure to conform, not lossy hops. Directly relevant to transport-vs-selection.
- **C. Thi Nguyen on epistemic bubbles vs. echo chambers.** Foundational for the rebuilt Part IV. Small networks tend toward chambers (active discrediting of outside info), not bubbles (just missing info). Changes what "infrastructure for integration" has to do.
- **Marshall McLuhan, *Understanding Media*.** The medium-as-message claim is in the bloodstream of any book on this topic. Worth engaging explicitly.
- **Richard Dawkins / Susan Blackmore on memetics.** The selection-side view already has a literature. Use it.
- **Yuval Noah Harari, *Nexus*.** Already in play via [[nexus-book]]. Myths/bureaucracy framing, truth/order axis, naive view of information.

## What to write next

The previous "highest leverage" answer (finish Chapter 3, generalize Chapter 4) is no longer right. Those are still worth doing, but the higher-leverage work right now is resolving the foundational questions, because they reshape later chapters before those chapters get drafted.

Best next moves, ranked:

1. ~~**Pick a side on transport vs. selection.**~~ Drafted as [[transport-vs-selection]] and refined further in [[the-information-landscape|Chapter 1]]. Working answer: both are real, parallel mechanisms operating in series at every stage. The "is one primary?" framing was wrong. Still pressure-testable, but the resolution has held through several rounds.
2. **Draft the medium-and-manipulation note.** The natural next foundational question after transport-vs-selection. Hook into McLuhan and into the question "can core truths survive a medium that allows a lot of manipulation?" Once drafted, the implications cascade through Chapters 5, 7, 10, 11, and 12.
3. **Draft Chapter 5c (truth, compression, and when each wins).** Closes the moral-neutrality gap and gives the book its actual stakes. Probably the highest-impact new chapter.
4. **Re-engage Chapter 5 with everything resolved.** Once 2 and 3 are settled and the want/medium refinements hold, Chapter 5 can be rewritten to reflect the resolved foundations rather than papered-over uncertainty.
5. **Sketch Chapter 9 (the integration problem).** New prescriptive core of Part IV, currently zero draft. Even a skeleton would unblock thinking about Chapters 8, 10, 11, and 12.
6. **Finish Chapter 3 second half.** Receiver-budget stuff, with the "budget is trainable" and "want is the prime mover" notes added.
7. **Generalize Chapter 4 beyond software.** Still right, still load-bearing.
