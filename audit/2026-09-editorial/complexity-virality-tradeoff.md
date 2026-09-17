# Audit: `content/complexity-virality-tradeoff.md` (Ch 5) — 4,096 words

## 1. Argument

**Thesis.** The easier an idea is to spread, the fewer preconditions it can carry, because every hop across a network costs receiver budget and losses compound; so the compressed, slightly-wrong version reliably out-travels the accurate one.

**Does it earn it?** The core (l.15–58: definition of complexity, receiver budget, the N-hop ceiling) is tight, concrete, and in the Chapter 1 voice. It is ~900 words. The remaining ~3,200 words are almost entirely handoffs: Ch 4 restated (l.64–66), Ch 8 previewed (l.68, again l.105), Ch 11 previewed (l.70, again l.111), the Hammer case told and then deferred to 5b (l.72–82), the manipulation surface told three ways (l.86–92) with the capture taxonomy imported from Part IV, and a closing section (l.113–121) that is a table of contents. The sentence "this is the transport half; selection is 5b" appears at l.9, 46, 60, 82, 90, 115, 117, 119. The transport/selection split of "complexity" is done at l.30 *and* l.119, and 5b does it again in full (5b l.79–85).

Terms the reader lacks: "intersubjective" (l.13, fourth paragraph, before any definition in this chapter), "outer message / decoding key" (l.30), "substrate custody" (l.70), "consumer-key," "training-corpus, training-objective" (l.92), "three-regime model" (l.119), "corpus capture" (l.121).

**Single most valuable structural change.** Cut the chapter to its transport core: l.7, 15–58, one Hammer paragraph (l.74 + two sentences of l.76), the four counter-example bullets (l.100–103), and a 5-line "what this sets up." Everything that begins "the version that includes selection" or "the capture taxonomy then adds" is already in 5b or Part IV. Target ~1,800 words.

## 2. Voice

**(a) Self-narration.** 69 hits, the highest of the three files. Worst 8:
- l.9 "for most of that time I treated the complexity/virality trade-off as load-bearing for the whole book. It isn't, not quite, and seeing why it isn't turned out to matter."
- l.30 "Splitting the term along the transport/selection seam fixed the slide; this chapter uses *complexity* to mean transport-complexity"
- l.60 "I'm developing the transport math here because it's the half this chapter is about."
- l.82 "I'll keep using examples like this in the transport chapter because the compression intuition is real and useful."
- l.90 "The version that includes selection (the one the book is actually arguing)"
- l.107 "The combined picture is darker than the original chapter implied." (refers to a draft the reader never saw)
- l.111 "for the first time in the book's history"
- l.113–121 the whole "What this chapter is and isn't doing" section; l.123 "ten chapters from now, which happens to be where the book ends"

**(b) Reversals.** 12 by regex. Worst 6:
- l.17 "Complexity here isn't 'fancy.' It's not 'uses big words.' It's the number of preconditions"
- l.86 "Compressed ideas are not just easier to spread, they are easier to *weaponize*."
- l.90 "These are selection criteria, not natural laws."
- l.94 "an inherent property of mass networks whose gates have been tuned this way, not of mass networks as such"
- l.109 "this is not an accident but the captured equilibrium"
- l.117 "not because it is causally upstream of transport but because it is the only one of the two with a steering wheel"

**(c) Triads / colons / parentheticals.**
- l.52 "preserved, compressed, or distorted" and "their own budget, their own preconditions, and their own audience" (two in one paragraph)
- l.90 "Recommendation algorithms, editorial standards, platform mechanics, advertising incentives."
- l.92 "low complexity ceiling + tunable gates + consumer-key-substrate capture = the modern manipulation surface"
- l.105 "Universities, religious orders, scientific journals, apprenticeship lineages: these are all *infrastructure for complexity*."
- l.107 "starved (no preservation), starved (no training), or captured" (also a copy error: "starved" twice)
- Parentheticals as dashes: l.7 "(the rule that the easier an idea is to spread...)", l.13 "(currencies, brands, religions, nations, ...)", l.80 "(complex form expensive, compressed form cheap)", l.115 "(with capacity trainable per Ch 3)"

**(d) Tic vocabulary.** load-bearing 4 (l.9, 64, 117, 121); substrate 7 (l.70, 92×3, 107, 111: "substrate custody," "consumer-key substrate"); exactly 2 (l.50, 58); sharpens 1 (l.105); "do work" 1 (l.9); said plain 1 (l.11). Worst: l.92 uses "substrate" three times in one paragraph; l.121 "prescriptions Ch 10 / Ch 12 commit to load-bearing."

**(e) Punchlines / Q-then-A.**
- l.36 "It's called social media."
- l.40 "In a network where attention is finite and constantly contested, the free thing wins on volume."
- l.42 "Same asymmetry, viewed from the other end of the wire."
- l.58 "Whether journalism failed there is a different discussion."
- l.109 "So the ceiling drops and nothing catches it."

**(f) "Counter-examples and what's still uncertain"** (l.96–111): ~1,050 words. The four bullets (l.100–103, ~330 words) are genuine and good: Wikipedia, podcasts, religions over centuries, Harari's truth/order axis. l.105–111 (~700 words) is not uncertainty; it is four paragraphs previewing Ch 8, the capture taxonomy, Ch 10/12, and Ch 11, each of which is already stated earlier in this file (l.68, l.92, l.109 ↔ l.94, l.70). Recommend: keep the bullets, delete l.105–111.

**Rewrites (4 worst paragraphs).**

*l.9 (original, 111 words):* "I've been chewing on this one for years, and for most of that time I treated the complexity/virality trade-off as load-bearing for the whole book. It isn't, not quite, and seeing why it isn't turned out to matter. The actual structure (laid out in Chapter 1) is two parallel mechanisms ... Both are real, both do work, but they're easier to see one at a time."
*Rewrite (41 words):* "Chapter 1 split the pipeline into two mechanisms: transport, which reshapes an idea in transit, and selection, which decides whether it moves at all. This chapter is transport. [[selection-as-other-engine|The next]] is selection. They are easier to see one at a time."

*l.30 (original, 231 words):* "'Complexity' is a word that wants to do two jobs here, and they aren't the same axis. The split lives in Ch 5b, which carves the term cleanly. *Transport-complexity* is precondition count ... In this chapter, a *complex* idea just means one that asks you to already know a lot before it makes sense, nothing more loaded than that."
*Rewrite (48 words):* "One warning. 'Complex' is going to mean *precondition count* and nothing else here: how much you must already know for the idea to land. Whether an idea is emotionally grabby, or tells you what to do, is a different property, and [[selection-as-other-engine|the next chapter]] handles it."

*l.92 (original, 143 words):* "The capture taxonomy later in the book makes this precise. Manipulation of the selection-design surfaces is what the taxonomy calls *capture* ... and each layer makes the others worse."
*Rewrite (36 words):* "Later, when the book gets to who owns the gates, this gets a name: *capture*. For now the point is that the gates are the bigger surface, and the easiest ones to reach are the ones that live inside people."

*l.117–119 (original, 226 words):* "It's not the whole story. The other half is selection ... This chapter sits at its proper scope: the transport half of the two-mechanism story."
*Rewrite (52 words):* "That's transport. It has no preference; it scrambles whatever it carries. Selection is the half with a steering wheel, and it is where the manipulation, the money, and any repair all live. That's next. What compression does to *truth*, as opposed to detail, is [[truth-compression-and-when-each-wins|Chapter 5c]]."

## 3. Evidence

| Line | Claim | Backing |
|---|---|---|
| l.42, 68, 103 | Harari on cheap untruth, myths/bureaucracy, truth/order | `citations/nexus-book` (linked). Add chapter references. |
| l.54 | 0.9^10 ≈ 1/3; 0.9^100 ≈ 0 | Arithmetic checks (0.349; 2.7e-5). |
| l.74 | *Hammer* "sold out instantly"; Copernicus "an all-time worst seller" (Koestler); "roughly the same window ... same century" | ⚠ Malleus Maleficarum 1486/7; *De revolutionibus* 1543: 57 years apart and different centuries. ⚠ Koestler's quip (*The Sleepwalkers*, 1959) was refuted by Owen Gingerich, *The Book Nobody Read* (2004): the first edition sold out and copies were heavily annotated by working astronomers. Keep the contrast as *popular* reach vs. specialist reach, and credit Gingerich. "Sold out instantly" is embellishment; the Malleus ran ~30 editions by 1669 (Broedel, *The Malleus Maleficarum and the Construction of Witchcraft*, 2003). Same error is baked into `cases/hammer-vs-copernicus`. |
| l.78 | Carney/Cuddy/Yap 2010; Ranehill et al. 2015; Carney 2016 disavowal; ~70M TED views; "consensus settled to *the original was wrong*" | Dates correct. ⚠ Slight overstatement: Cuddy, Schultz & Fosse 2018 (*Psych Science*) p-curve claims the self-reported "feeling of power" effect survives; the hormonal claim did not. Case page linked. |
| l.78 | SPE: 1971; 2018/2019 critiques; "textbooks did not get updated" | Le Texier 2019 (*American Psychologist*); Blum 2018. Textbook claim: Griggs 2014, *Teaching of Psychology*. Case page linked. |
| l.50 | "A friend pointed that out" (telephone game) | `general-theme` conversation note; link or drop the friend. |
| l.94 | gates "tuned for ad revenue" | Ch 10's job; fine as forward pointer. |
| l.100–101 | Wikipedia, podcasts | Opinion; fine unhedged as "current read." |

**Bold sentences.** Load-bearing: l.11 (the claim), l.56 (the ceiling). Ornament: l.78 "And the meme kept spreading anyway."

## 4. Concision

**Repeats within file.** Transport-half framing: l.9, 60, 82, 115, 119. Preservation/training: l.68 ↔ l.105. Capture taxonomy: l.92 ↔ l.107. Ch 11 decompression: l.70 ↔ l.111. Engagement-tuned gates: l.94 ↔ l.109. Complexity split: l.30 ↔ l.119. "Scientists say X" example: l.7 ↔ l.58. Pure-transport vs. selection reading of manipulation: l.88 ↔ l.90.

**Owned elsewhere.** l.64–66 (Ch 4, nearly verbatim from Ch 4 l.104, 124, 142); l.68 and l.105 (Ch 8); l.70 and l.111 (Ch 11); l.76 (5b's Hammer reading, which 5b gives again at l.63–69); l.78 (Ch 2's cases); l.44–46 (Ch 3's trainable capacity and want); l.30 and l.119 (5b's complexity split); l.92 and l.107 (capture taxonomy); l.13 (intersubjective-truth note).

**Estimated cut: 45%.** Biggest: (1) l.113–121, ~450 words, index of other chapters; (2) l.105–111, ~700 words, previews; (3) l.64–66, ~300 words, Ch 4 restated; (4) l.30, ~230 words → 2 sentences; (5) l.92, ~140 words; (6) l.13, ~170 words, move to a one-line scope note or footnote.

## 5. Interlinking

**Unlinked terms with pages.** compressed form / complex form (l.28, `concepts/compressed-form`, `complex-form`); receiver budget (l.34–40, `concepts/receiver-budget`); complexity ceiling (l.56, concept); handle-ability (l.30, concept); manipulation surface (l.84, concept); want as prime mover (l.46, `mechanisms/want-as-prime-mover`); budget fixed or trainable (l.44, `questions/budget-fixed-or-trainable`); complexity doing two jobs (l.119, `questions/complexity-doing-two-jobs`); decompression-on-demand (l.70, concept); consumer-key (l.92, `concepts/consumer-key-vs-surface-capture`); preservation/training (l.68, `concepts/preservation-vs-training-pair`); manufactured content (l.121, `mechanisms/manufactured-injection`); engagement equilibrium (l.94, 109, `mechanisms/engagement-equilibrium`).
**Cases unlinked.** `telephone-game` (l.50), `scientists-say-x` (l.7, 58), `bitcoin-internet-money` (l.21), `hammer-vs-copernicus` (l.74), `brief-history-of-time` linked (l.66); `power-posing` and `stanford-prison-experiment-corrective` linked.
**Sources unlinked.** Postman, Mercier, O'Connor & Weatherall (l.119) → `citations/amusing-ourselves-to-death`, `not-born-yesterday`, `misinformation-age`. Koestler (l.74) has no page. `nexus-book` linked.
**Frontmatter.**
```yaml
description: "Why the easy-to-share version of an idea always wins over the accurate one: every retelling costs the listener effort and loses a little, and across a big enough network the losses compound until only the slogan is left."
aliases: [complexity virality tradeoff, telephone game, complexity ceiling, compressed form, scientists say X, why simple ideas spread, precondition count, viral vs accurate]
```

## 6. Reader-facing defects

- Cold terms: "intersubjective" (l.13); "outer message," "decoding key" (l.30); "want-loop" implied (l.46); "optionality-shedding" (l.66); "substrate custody" (l.70); "consumer-key," "training-corpus, training-objective" (l.92); "asymmetry-of-modality" (l.117); "three-regime model," "strongest-objection section" (l.119); "corpus capture" (l.121).
- Perfect-tense forward refs: l.30 "Splitting the term ... fixed the slide" (5b comes later); l.64 "the load-bearing reframe Ch 4 lands"; l.107 "the original chapter implied"; l.111 "first time in the book's history."
- Contradictions/stale: glossary "Handle-ability ... See Chapter 5" while this chapter says the term belongs to 5b; l.107 "starved ... starved" copy error; l.74/5b l.65 "same century" is false (see Evidence); l.117 "in some ways the more powerful mechanism" vs. 5b l.9 "the more powerful half" (soften one).
- Inside references: l.123 "Hit me up" is fine in voice, but "ten chapters from now, which happens to be where the book ends" is drafting talk.

**Top 5 actions.** (1) Delete l.113–121 and l.105–111 (~1,150 words, no argument lost). (2) Fix the Hammer/Copernicus dating and cite Gingerich (l.74; also the case page). (3) Reduce l.30 to two sentences and leave the split to 5b. (4) Replace l.64–66 with two sentences pointing at Ch 4. (5) Link the concept pages for compressed form, receiver budget, complexity ceiling, and the four case pages.
