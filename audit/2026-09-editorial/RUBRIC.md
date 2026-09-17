# Audit rubric (apply to each assigned file)

Repo: /home/petty/Github/corpetty/information-book. The book is "Lossy" — a working draft of a nonfiction book about how ideas get compressed (transport) and filtered (selection) as they travel from reality to a general audience. Chapters live in `content/*.md`; reading order and status in `data/chapters.json`; canonical claims in `data/claims.json`; sources in `data/sources.json`; glossary in `content/glossary.md`; concept landing pages under `content/concepts/`, `content/cases/`, `content/mechanisms/`, `content/questions/`. Read `content/the-information-landscape.md` first as the calibration example of the voice the author is aiming for: plain, first-person, direct, no self-narration.

You are a hard-nosed developmental editor. Read the WHOLE assigned file with `cat -n` so you can cite line numbers. Do NOT edit any file. Write your report to the output path given, in markdown, under ~1800 words per file. Be concrete: quote, cite `file:line`, and propose rewrites. Prefer the 20 highest-value findings over exhaustive lists.

For each file, produce these sections:

## 1. Argument
- Thesis in one sentence, in your words.
- Does the chapter earn it? Where does it sag, loop back, or restate? Where does the argument depend on a term the reader doesn't have yet?
- The single most valuable structural change (merge/cut/reorder/split), with rationale.

## 2. Voice — AI-isms and self-narration
Cite line numbers and quote. Categories:
- (a) Self-narration / book-as-artifact: "this chapter argues", "the book has committed", "said plain", "I should be honest", "I should mark a tension", "the chapter, whole", "Chapter N worked out", meta about drafting/revision/extraction. Count total occurrences of "this chapter|the chapter|the book|Ch N" and list the 8 worst.
- (b) Reversal constructions: "not X but Y", "isn't X; it's Y", "X is not a Y. It is a Z." Count and list the worst 6.
- (c) Rule-of-three triads and cascading colon sentences ("X: Y: Z"), parenthetical asides that read like a replaced em-dash. Give 5 examples.
- (d) Tic vocabulary: load-bearing, exactly, quietly, substrate, at scale, precisely, "the honest version", "does real work", "sharpens", "collapses into", "names". Counts + worst 5.
- (e) Paragraph-closing aphorisms / punchline sentences; rhetorical question-then-answer. 5 examples.
- (f) The "Where I'm still uncertain" (or similar) section: length in words, what in it is genuine epistemic honesty vs production notes; recommend keep/trim/move.
Then give FULL rewrites of the 4 worst paragraphs (quote original, then rewrite), keeping the author's voice from Chapter 1 and cutting length by 30–50%.

## 3. Evidence
- List every empirical, historical, statistical, or attributed-to-a-thinker claim that is asserted without a citation or with a vague one ("studies show", "Postman says" without page). `file:line`, the claim, and either (i) the existing source in `data/sources.json` that could back it, or (ii) a specific real published work that would (author, title, year) — only name works you are confident exist. Mark any claim you think is factually wrong or overstated with ⚠.
- Which of the chapter's bold sentences are the actual load-bearing claims, and which are ornamentation?

## 4. Concision
- Passages that repeat something said earlier in the same file (cite both line numbers).
- Passages that restate something another chapter owns (name the chapter).
- Estimated % of the file that could be cut without losing argument. List the 6 biggest cuts (line ranges) with a one-line reason.

## 5. Interlinking and searchability
- Terms used that have a glossary entry or a page under content/{concepts,cases,mechanisms,questions}/ but are not `[[wikilinked]]` at first use in this file (ls those dirs; match by slug/alias). List term + line.
- Case studies mentioned but not linked to their `content/cases/*.md` page.
- Sources named in prose but not linked to `content/citations/*.md`.
- Propose frontmatter for this file: a 1–2 sentence `description:` (plain language, for search results and social previews) and 5–8 `aliases:`/keywords a reader might search for.

## 6. Reader-facing defects
- Terms used cold before their home chapter (no gloss).
- Forward references in perfect tense ("Chapter 10 worked out").
- Stale facts / internal contradictions with other chapters (name them).
- Anything a general reader would trip on (jargon, unexplained acronym, inside references to the outline/graph/tooling).

End with a **Top 5 actions for this file** ranked by value/effort.
