# Audit: `content/glossary.md` — light pass (sections 1, 2, 5, 6) plus glossary-specific checks

File: `/home/petty/Github/corpetty/information-book/content/glossary.md` (4,540 words, ~70 entries in 11 groups). Line numbers from `cat -n`.

## 1. Argument

**Purpose (thesis).** Plain-language definitions of the book's terms, ordered by where each enters the argument, each pointing at its home chapter or note.

**Does it earn it?** Partly. The definitions are mostly good and often better than the chapters' own. Where it sags:

- **Entries drift from definition into argument and drafting history.** L39 "The book's first guess at what makes someone a good bridge…; later refined into…"; L41 "The book's load-bearing move"; L111 (Bureaucracy) is a 120-word paragraph about why the book kept a word it admits is wrong; L121 "A shape that appears repeatedly in the book's argument"; L191 "The reframe at the heart of Part IV." A glossary entry should say what the thing is, then where to read more.
- **Length.** Intersubjective truth (L65, ~105 words), Bureaucracy (L111, ~120), Engineered loss (L143, ~110), The abyss (L177, ~120), Constitutive regimes (L67, ~95) are essays. Anything over ~60 words is not a lookup.
- **Duplicated headwords.** Selection gate (L17) is a subset of Selection (L15); Compression (L57) is Transport (L13) said again; Outer message (L43) is inside The three layers (L41) and the glossary itself says (L41) it is the same thing as Preconditions (L37). Four entries could be two.
- **Terms used before they are defined, or never defined.** "decoding key" is used at L13, L43, L57, L109 and is never a headword, though it is the chapters' most common name for the outer message (16 chapter files). "captured" is used at L63 before Capture at L147. "consumer-key" (L151, L165) rests on the "key" metaphor from L41 but is never tied to it.
- **Ordering vs the book.** "Compression and truth" (Ch 5c) precedes "Selection up close" (Ch 5b); "How people hold beliefs" (Ch 7) precedes "The bridge zone" (Ch 6); Ch 9's terms (bridge node, versatile expertise, curse of expertise, curation layer) land in the last group after Ch 10, 11 and the capture note. The stated promise, "reading top to bottom roughly follows the book's own path" (L9), is roughly false for Parts II–IV.

**Single structural change.** Add an A–Z index at the top (headword → anchor) and make each headword a `####` heading so Quartz gives it an id and a table of contents. Keep the grouped order underneath. This fixes the search-arrival problem without rewriting a word of definition.

## 2. Voice

**(a) Self-narration.** "the book" ×21 ("The book treats", "The book argues", "The book keeps the word", "the book inherited the term", "The book's diagnosis", "the book's alarm", "The book's framework", "The book's load-bearing move"). Worst: L111 Bureaucracy ("by stipulation, not by argument … The honest alternative would be to call the narrow function *institutional carriers* throughout, but the book inherited the term from Harari's Nexus and has kept it for continuity"); L39; L41; L25 "which is what makes the distinction load-bearing"; L51 "A rival to 'complexity'"; L121; L185 "The infrastructure side of the integration prescription"; L193 "The closing reframe."

**(b) Reversals.** ~12. Worst 6: L29 "Not the substrate … but the *gate-criteria*"; L43 "loss of the outer message, not the inner one"; L51 "not how many preconditions it needs, but how easily it plugs into"; L77 "isn't lossy transport; it's a selection gate"; L133 "isn't an outside attack …; it *is* the platform's business model"; L171 "not generalists but *versatile experts*."

**(c) Triads / cascades.** L21 six-item list "emotional charge, identity reinforcement, status, 'tells you what to do,' novelty, controversy"; L65 "The carving is per-claim, not per-artifact: a myth can be based in reality too, and most artifacts are mixed bundles"; L67 three parentheticals in one sentence; L69 "'money just *is* valuable,' 'the market decided,' 'the law is the law'"; L143 five clauses chained with "so … and … so." Parenthetical-as-em-dash: L45 "(a tablespoon of attention-weeks)", L99 "(below)", L149 "(a propaganda shop, a state, an ad-tech firm)".

**(d) Tics.** load-bearing ×2 (L25, L41), exactly ×2 (L69, L151 area), quietly ×1 (L161), sharpens ×1 (L97), honest ×1 (L111). Low, but "load-bearing" in a glossary that the index promises defines "every load-bearing term" (index L60) is a tell.

**(e) Punchlines.** L43 "The claim survives transit; the key it needed doesn't."; L65 "for this cargo, transmission is participation."; L71 "it determines how many truths there are now."; L73 "A stabilizer slower than the thing it stabilizes is a spectator with a title."; L131 "wherever there is a gate, someone owns its dial."; L151 "The first kind is the dangerous kind." These are good sentences; they belong in chapters, not lookups.

**(f)** None.

**Two rewrites.**

*L111 Bureaucracy (120 words)* → (45 words):
> **Bureaucracy (narrow sense).** The book's shorthand for two institutional jobs: *preservation* (keeping the full, uncompressed form of an idea somewhere) and *training* (teaching people to read it). Borrowed from Harari's *Nexus*; real bureaucracies do much more, and none of that is meant here. See [[preservation-vs-training|Chapter 8]].

*L177 The abyss (120 words)* → (55 words):
> **The abyss.** Everything a deep field could still ask or become, a space so large that no one, expert or machine, can see all of it. You need real competence just to notice it is there; beginners mistake the field for something finite. Not the same as a hard-to-use tool: a library is a map, not an abyss. See [[concepts/abyss]] and [The Abyss](https://bayesianpersuasion.com/posts/the-abyss).

## 5. Interlinking and searchability

**Concept pages are never linked.** 58 pages in `content/concepts/`, 9 in `mechanisms/`, 6 in `questions/` exist and match glossary headwords almost one-to-one (`concepts/receiver-budget`, `concepts/handle-ability`, `concepts/zollman-effect`, `mechanisms/transport`, `mechanisms/selection`, `mechanisms/myth-dilution`, `mechanisms/interpretive-latitude`, `mechanisms/medium-shapes-want`, `mechanisms/want-as-prime-mover`, `mechanisms/manufactured-injection`, `mechanisms/engagement-equilibrium`, `mechanisms/constitutive-transmission`, and so on). Every "See" points to a chapter or a depth note instead. Since the concept pages are the graph nodes, the glossary is invisible to backlinks and the local graph. Add the concept page to every "See."

**Entries with no "See" pointer (12).** Selection gate L17; Preconditions L37; Outer message L43; Compression L57; Network segmentation L113 (→ `mechanisms/myth-dilution`, `concepts/network-segmentation`); Echo chambers vs bubbles L115 (→ `integration-problem` Ch 9, `citations/nguyen-bubbles-vs-chambers`, `concepts/echo-chambers-vs-bubbles`); Polarization via distrust L117 (→ Ch 9, `citations/misinformation-age`); Zollman effect L119 (→ Ch 9, `citations/misinformation-age`); Inverted-U L121 (→ `citations/the-democratization-paradox`); Cost-shifting L137 (→ Ch 10, `citations/the-democratization-paradox`); Versatile expertise L173 (→ `bridge-nodes-and-versatile-expertise`); Curse of expertise L175 (→ `citations/double-edged-sword-of-expertise`).

**Pointers to the wrong home.**
- **Superspreader dynamics L81 → "Chapter 10."** No chapter file contains "superspreader"; only `concepts/superspreader-dynamics.md` does. Point at the concept page and `citations/epidemiological-virality`.
- **Credibility weighting L91 → "Chapter 10."** Ch 10 mentions credibility once in passing; the O'Connor–Weatherall machinery lives in Ch 5b and Ch 9 (5 mentions). Point at Ch 5b + `citations/misinformation-age`.
- **Technology vs. medium L31 → "Chapter 6."** Neither Ch 6 nor Ch 10 uses the phrase or draws the distinction in prose; the only home is `concepts/technology-vs-medium.md` and Postman. Point there and at `citations/amusing-ourselves-to-death`.
- **Option space L23 → `medium-and-manipulation`.** The three-operation model (transport generates / medium bounds / selection picks) is Ch 5b's (11 mentions vs 2). Point at Ch 5b.
- **Want L47 → `transport-vs-selection`.** `chapters.json` gives "want is the prime mover" to Ch 3; the note is the author-facing home. Point at Ch 3 (`info-time-limit`).
- **Curation layer L185 → `the-democratization-paradox`.** The chapter home is Ch 9 L51; the essay is the source. Point at both.
- **Three ways to capture an LLM L163 → `capture-taxonomy`.** These are Ch 11's terms; the taxonomy note unifies them. Point at Ch 11 first.
- **Transport L13 → `transport-vs-selection`.** Ch 5 is the chapter; the note is a working note the index itself calls author-facing.
- **The abyss L177** links externally only; `concepts/abyss.md` exists (and the in-repo `the-abyss.md` was deleted this cycle, so the external link is deliberate, but the concept page should still be linked).

**Chapter coinages (bold or italic in `content/*.md` chapters) with no glossary entry.**
- *Complexity/virality trade-off* — the name of Ch 5, used in 4 chapters; no headword (Complexity ceiling and Handle-ability orbit it).
- *The medium is frozen selection* — Ch 5b section heading, used in 4 chapters; the glossary's Medium entry does not say it.
- *Three-operation stage model* (transport generates / medium bounds / selection picks) — buried inside Option space.
- *Decoding key* — 16 chapter files; no headword, no "also called."
- *The corrective* — noun in 12 chapter files (Ch 2's four cases are sorted by whether the corrective survived); no entry.
- *Failure surface* / the four *pipeline exits* (made it to meme / died at consensus / died at curation / no theory at all) — Ch 2 bolds; no entry.
- *Salvation case / worst case* — 7 chapter files; only mentioned inside LLM as capability extender.
- *Preserve-and-retrain* — 6 chapter files as a compound noun; no headword.
- *Trust-bootstrap problem*, *selective isolation*, *bridge-node throughput* — Ch 9's operational problems (headings); none defined.
- *Displacement vs reform* — Ch 10 and Ch 12's "displacement-and-survival"; no entry.
- *Truth generators / generator criterion*, *objective shadow* — `concepts/truth-generators` exists; glossary only alludes inside Intersubjective truth.
- *Constitutive transmission* — `mechanisms/constitutive-transmission` exists; glossary has the sentence ("transmission is participation") but no headword.
- *De facto power exceeding formal authority*, *synodality*, *Babel / Jerusalem* — bolded in Ch 11 (encyclical) and used in Ch 9; no entries.
- *Emergent vs engineered tuning* (Ch 5b), *receiver-gate* (Ch 5b), *moral-neutrality gap* (`questions/truth-value-placement` alias) — minor, but each is a bolded coinage.
- The seven capture *substrates* as a set (gate-criteria, option-space, deployment-configuration, preservation-archive, receiver-training, training-corpus, training-objective) — Ch 12 leans on the list at L59; the Capture entry names "three axes" and never enumerates the surfaces.

**Grouping/ordering for a reader arriving via search.** It does not help them. Headwords are bold runs inside paragraphs, not headings, so there are no anchors, no TOC entries, and no way to deep-link; the only lookup route is browser find, which fails for every synonym ("decoding key," "tablespoon of weeks," "salvation case," "preserve-and-retrain," "bridge node" is only an alias on the versatile-expertise page). Group names ("Selection up close," "Capture, unified") describe the book's route, not the reader's question. Fix: A–Z index at the top; `####` headings per headword; an "Also called:" line per entry; `aliases:` frontmatter listing the synonyms so `[[decoding key]]` resolves.

**Proposed frontmatter.**
```yaml
description: "Plain-language definitions of every term Lossy coins or borrows: transport, selection, the receiver budget, outer message, capture, bridge nodes, survivable polarization, and the rest, each pointing at the chapter that works it through."
aliases: [glossary, definitions, terms, vocabulary, key terms, what does X mean, jargon, decoding key, outer message]
```

## 6. Reader-facing defects

- **Cold terms inside definitions**: "decoding key" (L13, L43, L57, L109); "captured" (L63) before Capture (L147); "the pipeline's gates" (L25) before Selection gate is read in order, fine, but "preserve-and-retrain" (L191) is used without the hyphenated form ever being introduced; "constituency/constituencies" (L67, L71) used as a technical term; "RLHF" does not appear here but the AI entries assume "training objective" means something to a lay reader.
- **Internal inconsistencies**: L15 "selection is the dominant force shaping what spreads" vs L131 (modality argument: selection is the *aimable* one) and `claims.json`; L19 pipeline stages "raw observation → formal finding → news → public discussion → meme" vs Ch 1's "Out There → Raw Data → Insight → Theory → News → Meme" and index L23's five-stage version, three different pipelines across three landing pages; L61 "Which regime occurs is set by the selection gate" vs index L43 "set by the medium"; L157 "five to seven" surfaces vs short version's five.
- **Stale**: L111 explicitly says the term is wrong and kept for continuity, which is a revision note, not a definition; L39 narrates a superseded first guess.
- **General-reader trips**: L73 "The transport collapse's second blade" assumes the reader has read the intersubjective note; L143 "The transparent-ledger case" is unexplained; L177 links to an external blog for a term the book uses in two chapters; L9 tells the reader to "use your browser's find," which is an admission the page has no index.

## Top 5 actions for this file

1. Add an A–Z index and per-headword headings (anchors), plus an "Also called" line; add `aliases:` frontmatter. One edit fixes search arrival.
2. Fix the eight wrong-home pointers (superspreader, credibility weighting, technology vs medium, option space, want, curation layer, LLM capture, transport) and add pointers to the 12 entries without one, linking concept pages throughout.
3. Add the missing headwords: complexity/virality trade-off, decoding key, the corrective, salvation/worst case, preserve-and-retrain, trust-bootstrap, the seven substrates, constitutive transmission, truth generators.
4. Cut Bureaucracy, Intersubjective truth, Engineered loss, The abyss, Constitutive regimes to ≤60 words each; merge Selection gate into Selection and Compression into Transport.
5. Reconcile the pipeline stage list (L19) and "selection is the dominant force" (L15) with Ch 1 and `claims.json`.
