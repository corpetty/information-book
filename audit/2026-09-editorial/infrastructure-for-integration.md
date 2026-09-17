# Audit: `content/infrastructure-for-integration.md` (Ch 12) — full rubric

File: `/home/petty/Github/corpetty/information-book/content/infrastructure-for-integration.md` (5,275 words; "uncertain" section 560 words). Line numbers below are from `cat -n`.

## 1. Argument

**Thesis (my words).** Institutions that keep hard-won knowledge alive and teach people to read it cannot beat an engagement-tuned media environment, so they must be designed to survive beside it: funded outside attention markets, defended first at the surfaces that install in people and models, built to work under partial distrust, and, if they use an LLM, owning its corpus, objective, and deployment.

**Does it earn it?** The thesis is stated, restated, and re-summarized, but only Principle 3 (lines 73–85) and the concrete LLM picture (line 91) actually *argue* anything new; the rest imports conclusions from Ch 8–11 and the capture-taxonomy note and stacks them. Specific sags:

- Lines 9–11 are two paragraphs of table-of-contents recap before the chapter starts. Line 9 in particular ("Chapter 12, Part IV. The synthesis chapter.") reads as an outline heading pasted into prose.
- Lines 15–27 restate the four prior chapters, then line 25 restates the four problems as one bold sentence, then line 27 restates line 25 in plain English. Line 27 is the best paragraph in the chapter; 25 should not exist.
- "Survival, not victory" is stated at 7, 33, 35, 137, and again in glossary. The polarization problem is stated at 21 and again nearly verbatim at 73. The consumer-key priority is stated at 59, 67 (last sentence), and 69. "Technically realizable, economically marginal, politically blocked" appears at 107 and 135 (and in Ch 11's summary).
- Line 37 depends on five terms the reader does not have unless they read a depth note: "generator independence," "divergent constitution," "effective-but-owned cell," "the myth note's test," "keep the fork affordable." It also near-duplicates Ch 9 line 152.
- Principle 2 (59–69) is written in the capture taxonomy's cell names (gate-criteria, option-space, deployment-configuration, preservation-archive, receiver-training, training-corpus, training-objective) without ever saying in the chapter's own words what "consumer-key" means. A reader who arrives from Ch 11 without the note is lost for three pages.

**Single most valuable structural change.** Collapse the three closings into one. Delete lines 9–11 and 25; merge "Survival, not victory" (29–35), "The work of generations" (125–131), and "Where I land" (133–137) into a single ~350-word closing section placed after the worked examples. Rationale: the chapter currently opens with a reframe, runs the principles, then re-opens the reframe twice; a synthesis chapter that ends once will feel decisive rather than recursive. Secondary: move the concrete university-assistant picture (line 91) to the top of the LLM section, ahead of the abstract spec at 93–103.

## 2. Voice

**(a) Self-narration / book-as-artifact.** Counts: "this chapter / the chapter" 22; "the book" 15; "Ch N / Chapter N" 25 (4 are "Ch 12" naming itself). Worst 8:

1. L9 "Chapter 12, Part IV. The synthesis chapter. The book has spent Part IV building up to a design problem … Each handed something forward; Ch 12 has to take all of it and commit to what the design spec actually looks like."
2. L11 "This chapter is not a feature list … The book has spent enough time in the diagnostic mode … That is what this chapter commits to."
3. L35 "That is what Part IV has been moving toward without saying. The chapter says it now because…"
4. L59 "The capture taxonomy surfaced the principle the chapter cashes here."
5. L65 "one of the more important things Ch 12 has to flag as unsolved."
6. L89 "Ch 12 has to commit to what the salvation case looks like."
7. L107 "This is also where the chapter has to be most honest … Ch 12's job is to make the conditions explicit rather than wave them away."
8. L135/137 "The synthesis, said whole: … the one the chapter rests on … The book's contribution to the prescriptive question is a shape … what the book hands to its readers."

Also L129 "That is the final reframe the chapter wants to make explicit"; L131 "The chapter does not pretend to know."

**(b) Reversals.** ~12. Worst 6: L7 "the goal is not to win. It is to outlast."; L11 "not which specific institutions to build but which structural properties"; L33 "a survival problem, not a victory problem … survival design, not victory design"; L85 "institutions that work when trust is partial, not for institutions that require trust to be complete"; L103 "a capability extender, not a replacement"; L129 "a brief for … civilization-scale investment … not a recipe for next quarter."

**(c) Triads and colon cascades.** L7 "funded outside the chaos, walled off from it, doing the slow work"; L11 "not a feature list, not a platform proposal, not a policy memo … conditional, partial, and structurally constrained"; L93 "against its own preservation archive to do …, against its own quality-controlled materials to do …, against its own peer-reviewed sources to do …"; L105 five-clause semicolon chain "The corpus has to be curated; the weights have to be…; the objective…; the deployment…; and the result…"; L107/L135 "technically realizable, economically marginal, and politically blocked." Em-dash-replacement parentheticals: L45 "(with the caveat from Ch 8 that …)", L55 "(Wikipedia, the surviving research universities, the journals that have held their editorial autonomy, public broadcasting where it still exists)", L105 "(and lose ground to ones that have it) … (and inherit its capture into their own substrates)".

**(d) Tic vocabulary.** substrate 32 (!), exactly 7, honest 7, names/named 11, at scale 4, quietly 3, load-bearing 2. Worst 5: L47 "is doing load-bearing work"; L69 "the current commercial landscape exactly inverts"; L107 and L135 "exactly the same forces" (twice); L25 "an honest sentence falls out"; L131 "The honest version of the prescriptive arc." "Substrate" appears 15 times in lines 59–69 alone.

**(e) Paragraph-closing punchlines.** L7 "The goal is not to win. It is to outlast."; L25 "That is the problem statement."; L53 "the institution either drifts toward engagement-optimization or starves."; L105 "The political economy of all this is brutal:" (opening punchline); L129 "and it is generational work, period."; L131 "the diagnosis was the easy half." No question-then-answer tics.

**(f) "Where I'm still uncertain."** 560 words, six bullets. Genuine: 1 (reform vs displacement, but it duplicates Ch 10 L153 almost point for point; keep it in one chapter), 2 (funding scale), 5 (Western example set), 6 (who decides what counts as integration). Production notes: 3 restates body L107; 4 ("no intermediate-term prescription") is a hole the body should fill, not confess. Recommend: keep 1, 2, 5, 6 at ~250 words; cut 3; convert 4 into one body paragraph titled "What to do this decade."

**Four rewrites.**

*L9 original (170 words)* → rewrite (55 words):
> Part IV handed this chapter four things. Chapter 8: institutions have two jobs, keep the full form and train readers for it. Chapter 9: the people and institutions that do it. Chapter 10: why the market starves them. Chapter 11: a tool that could help or finish the job. What follows is the design spec those four add up to.

*L11 original (135 words)* → rewrite (45 words):
> This is not a platform proposal or a policy memo. I don't know which institutions to build. I think I know what properties any of them needs to survive the gradient running against it, and the examples at the end are there to show the properties, not to be copied.

*L33 original (150 words)* → rewrite (70 words):
> So the target changes. Integration institutions don't need to win the attention market; they need to survive being out-competed in it and keep doing preserve-and-retrain at whatever scale they can manage. That is a lower bar than displacing the platforms, and it produces a different institution: one that refuses to compete for attention at all and finds its money elsewhere. Monasteries, not startups.

*L135 original (175 words)* → rewrite (60 words):
> Three rules, one condition. Fund it outside the attention market. Defend first whatever installs in people and models. Build it to work when half the audience distrusts it. If it uses an LLM, own the corpus, the objective, and the deployment, or don't use one. None of this is a product launch; it is the kind of thing universities took centuries to become.

## 3. Evidence

| Line | Claim | Backing |
|---|---|---|
| 7 | Monasteries "quietly kept copying" Roman books, "funded outside the chaos, walled off from it" | ⚠ Romanticized: monastic scriptoria were embedded in patronage and land politics and many were sacked. Reynolds & Wilson, *Scribes and Scholars* (1968; 3rd ed. 1991). Not in `sources.json`. |
| 33 | "monasteries kept Latin alive through the medieval period" | ⚠ Latin was the living language of church and administration; monasteries preserved *classical texts*, not the language. Same source. |
| 45 | "the elite ones survive on this while broader preservation has collapsed without it" (attributed to Ch 8) | ⚠ **Contradicts Ch 8 L89/L113**, which says preservation *held* and *training* hollowed. Fix the attribution. |
| 45 | Wikipedia's "foundation model … distributed-donor" | Wikimedia Foundation annual reports; Wikimedia Endowment (est. 2016). Uncontroversial, but say "donor-funded" not "endowment-funded" (the endowment is small relative to annual giving). |
| 51 | Quadratic funding, retroactive funding | Buterin, Hitzig & Weyl, "A Flexible Design for Funding Public Goods," *Management Science* 2019; retroactive public-goods funding, Optimism/Buterin 2021. `ethical-infrastructure-talk` partially backs. |
| 55 | "VC-backed knowledge platforms, ad-supported journalism, freemium learning services … each tends to drift the same way" | No named case. Name one per category or cut. |
| 65 | "some open-source efforts approach" transparent corpus custody | Name them: The Pile (Gao et al., 2020); AI2's OLMo/Dolma (2024), which publish corpus and filtering. |
| 67 | "user-perceived helpfulness … is what current commercial RLHF is optimizing for" | Ouyang et al., "Training language models to follow instructions with human feedback" (2022); Sharma et al., "Towards Understanding Sycophancy in Language Models" (2023). |
| 69 | "deployment and gate are extensively governed; corpus and objective are nearly opaque" | Bommasani et al., *Foundation Model Transparency Index* (Stanford CRFM, 2023) documents exactly this pattern. |
| 83 | Zollman effect | Zollman, "The Communication Structure of Epistemic Communities," *Philosophy of Science* 2007; `misinformation-age` in sources. Not linked. |
| 113 | Wikipedia's "donor base and … editor recruitment, both of which are stressed" | Editor decline: Halfaker et al., "The Rise and Decline of an Open Collaboration System," 2013. ⚠ Donor revenue has grown year over year; "stressed" is not supported for the donor half. |
| 115 | Stack Overflow "decoupled from attention markets early … increasingly under ad-revenue pressure" | ⚠ Stack Overflow ran ads and a paid jobs board within its first year and took VC in 2010; it was never decoupled. Its 2023 traffic fall is usually attributed to ChatGPT, not ad pressure. Ch 9 L136's "originally subscription-style" is also wrong. Either find a real decoupled-then-drifted case or drop the drift claim. |
| 121 | "judicial appointment processes are increasingly captured by political pressure in many jurisdictions" | Vague; name two (US federal bench, Poland 2015–2023) or hedge. |
| 141 | Bell System breakup, "postwar broadcasting policy" as reform successes | Tim Wu, *The Master Switch* (2010) covers both. |

**Bold sentences.** Load-bearing: L25 (problem statement, but L27 says it better), L33, L53, L69, L85, L93. Ornament: L37 both bolds (imports from the intersubjective note), L127, L129 ("generational work, period" repeats L127), L135, L137 (repeats L33). The bulleted bold leads (45–51, 63–67, 77–83, 97–103, 113–121) are fine as headers.

## 4. Concision

**Internal repeats.** 9↔15–23; 25↔27; 21↔73 (near-verbatim: "even un-captured institutions get filtered out … discount evidence from out-group sources" and "across trust boundaries that will not be repaired in advance"); 59↔67 (last sentence)↔69; 63↔65 ("credibly neutral governance (no single party can change … without visible cost)" twice); 7↔33↔137 (survival/monastery); 105↔107 (nobody can afford it); 107↔135; 127↔129.

**Restates other chapters.** L17 (Ch 10 out-competition); L19, L59 (capture taxonomy); L21, L73 (Ch 9); L23, L89 (Ch 11); L31 (Ch 10 self-capture); L37 (Ch 9 L152 and the intersubjective note, nearly verbatim); L77 (Ch 9 L122, Wikipedia talk pages, same wording); L81 (bridge-nodes note); L111–121 (Ch 9 L130–136: same five examples, same verdicts).

**Estimated cuttable: 35–40%.** Six biggest cuts:
1. L9–11 (~300 words): recap; replace with the 55-word version above.
2. L111–123 (~600 words): the five examples already live in Ch 9; keep one paragraph mapping each to the principle it illustrates and link Ch 9.
3. L133–137 (~330 words): "Where I land" is the chapter a fourth time; fold into one closing.
4. L37 (~230 words): move to Ch 9 (where L152 already says it) or cut to two sentences.
5. L139–151 (560 → ~250 words): per §2(f).
6. L25 (~90 words) and the last sentence of L67: pure duplicates.

## 5. Interlinking and searchability

**Terms with a page, unlinked at first use** (all in `content/concepts/` unless noted): out-competition (L17 → `out-competition-of-carriers`); consumer-key (L19 → `consumer-key-vs-surface-capture`); polarization via distrust (L21 → `polarization-via-distrust`); selection-design surface (L23 → `llm-design-moment-collapse`); survival not victory (L29 → `survival-not-victory`); captured equilibrium / self-capture (L31 → `mechanisms/engagement-equilibrium`, `self-vs-external-capture`); curation layer (L37 → `curation-layer`); funding decoupling (L39 → `funding-decoupling`); option-space (L59 → `option-space`); receiver-training, corpus, objective capture (L63/65/67 → `corpus-capture`, `objective-capture`, `deployment-capture`); survivable polarization (L71 → `survivable-polarization`); versatile experts / curse of expertise (L81 → `versatile-expertise`, `curse-of-expertise`); Zollman effect (L83 → `zollman-effect`); capability extender (L87 → `llm-as-capability-extender`); decompression-on-demand (L93 → `decompression-on-demand`); work of generations (L125 → `work-of-generations`); "Ch 3" (L63) → `[[info-time-limit]]`. The chapter links only depth notes and sibling chapters, never a concept page.

**Cases.** None of Wikipedia, Stack Overflow, common-law courts, or the monastery has a `content/cases/` page; the monastery is now used in Ch 8, Ch 12 and the short version and deserves one. `cases/latin-mass-vs-vernacular.md` is the natural illustration for "dual structure" and is not mentioned.

**Sources.** Zero `[[citations/…]]` links in the chapter. Zollman/O'Connor–Weatherall (L83) → `citations/misinformation-age.md`; Ch 10 material (L17, L31) could link `citations/amusing-ourselves-to-death.md` where Huxley is invoked; public-goods funding (L51) → `citations/ethical-infrastructure-talk.md`.

**Proposed frontmatter.**
```yaml
description: "Design rules for institutions that keep hard-won knowledge alive in an attention economy they cannot beat: fund them outside the engagement market, protect what gets installed in people and models first, build them to work under distrust, and own any AI they use."
aliases: [infrastructure for integration, survival not victory, funding decoupling, institution-owned LLM, survivable polarization, curriculum custody, corpus custody, work of generations]
```

## 6. Reader-facing defects

- **Cold terms**: "consumer-key substrates" (L19) never defined in-chapter; "preserve-and-retrain" as a noun (L25); the seven taxonomy cells (L59); "captured outer message" (L65); "RLHF" (L67, L99) unexpanded; "credibly neutral" (L47, L63, L65) is crypto-economics jargon used as if standard; "non-rivalrous" (L51); "effective-but-owned cell," "myth note's test," "generator independence" (L37).
- **Tense / inside references**: L9 "the depth note running underneath all three" (four chapters listed, and "depth note" is tooling vocabulary); L37 "the myth note"; L65 "Ch 12 has to flag"; L9 "Chapter 12, Part IV."
- **Contradictions**: L45 vs Ch 8 (preservation collapsed vs held); L115 vs Ch 9 L136 (both wrong about Stack Overflow, differently); L37 duplicates Ch 9 L152; L141 duplicates Ch 10 L153; L33's "kept Latin alive" vs L7's "kept copying the books."
- **General-reader trips**: "open weights" (L65) half-glossed; "system prompts and refusal policies" (L101); "frontier model" (L69); the sentence at L23 runs 70 words with three "which."

## Top 5 actions for this file

1. **Cut L9–11 and L25; fold L29–37, L125–131, L133–137 into one closing** (~1,000 words gone, argument intact). High value, low effort.
2. **Fix the Ch 8 misattribution at L45 and the Stack Overflow history at L115** (and Ch 9 L136). Factual, cheap.
3. **Define "consumer-key" in one plain sentence at L19** and cut "substrate" by two-thirds in L59–69; move L91 above L93.
4. **Replace the worked-examples section with a one-paragraph map to Ch 9**, adding the three named sources for the LLM claims (Ouyang 2022; OLMo/Dolma; Transparency Index).
5. **Wikilink the 18 concept pages at first use** and add the proposed frontmatter; add `citations/misinformation-age` at L83.
