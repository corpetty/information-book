# Prose & authorial decisions — for the author to rule on

This file is the output of the June 2026 repo audit. Sections A–F were
*flagged, not fixed*, and wait on your call. Section G (the editorial
content audit) was **applied at the author's direction** in Phases 80–83
(June 12, 2026) — its boxes are ticked below, with one structural decision
left open. The mechanical build/site/graph fixes from the same audit
(Tracks A, B, D) were applied directly.

Each item: **where**, **what's there now**, **why it matters**, and one or
more **options** (the recommended one first). Check a box when you've decided.

---

## A. Consistency of the argument

### A1. Residual "selection is primary" language
- **Where:** `content/transport-vs-selection.md:53` ("Selection is primary.
  Transport is real but increasingly downstream."), reinforced at `:80` and
  `:99`; and `content/outline.md:34` (parenthetical "provisional answer there:
  selection-primary").
- **What's there:** The note *itself* retracts this later — `:105` says *"One
  word in this note has been doing too much work: primary. 'Selection is
  primary' was really four claims wearing one coat,"* and the settled position
  across the book is **modality, not primacy** (transport and selection are
  parallel mechanisms in series). So a reader hitting `:53` meets the
  superseded claim stated flatly ~50 lines before the walk-back.
- **Why it matters:** This is the one place the corpus states, unqualified, a
  position the book elsewhere rejects. The graph already models the retraction
  (`claim:selection-is-primary` is `supersedes`-superseded). The prose is the
  last layer still carrying the old framing at face value.
- **Options:**
  - [ ] **(rec) Keep the journey, signpost it.** Add a one-line forward
    pointer at `:53` ("— but see below; this word is about to cause trouble")
    so a linear reader knows the retraction is coming. Preserves the
    working-note character you've cultivated.
  - [ ] Rewrite `:53` to open in the settled modality framing; demote the
    "primary" discussion to the explicit retraction at `:105`.
  - [ ] Leave as-is (the note is explicitly a working note; the retraction is
    part of its honesty).

### A2. "Bureaucracy" vs "institutional carriers"
- **Where:** `content/preservation-vs-training.md:9,11,19`,
  `content/myths-scale-and-bureaucracy.md`, `content/glossary.md:101`.
- **What's there:** "Bureaucracy" is used narrowly *by stipulation* (= the
  preserve + retrain repair function), and all three places say so and name
  the honest alternative — *institutional carriers* — explicitly
  (`glossary.md:101`, `preservation-vs-training.md:9`). It's consistent because
  every use cross-references the stipulation, but it's a known terminological
  debt you keep paying interest on.
- **Why it matters:** A term that needs a glossary disclaimer every time it
  appears is a friction point for new readers, and you've already written the
  replacement name.
- **Options:**
  - [ ] **(rec) Keep "bureaucracy" but lean on the glossary** (status quo) —
    it's inherited from Harari's *Nexus* and the cross-refs are disciplined.
  - [ ] Do a find-and-replace to *institutional carriers* in the narrow sense,
    reserving "bureaucracy" for Harari's broad sense. Touches Ch 8, the myths
    note, and ~3 glossary entries.

### A3. "Preservation mostly held" → "elite preservation held"
- **Where:** strong version in `content/preservation-vs-training.md` (Ch 8);
  the walk-back is already written in `content/political-economy-of-attention.md:79`
  and `:143`.
- **What's there:** Ch 10 explicitly proposes that Ch 8's "preservation mostly
  held" should become *"elite preservation mostly held, broad preservation also
  in collapse"* (local journalism, regional universities, adult education have
  collapsed). This is a live disagreement **between two chapters**, with Ch 10
  already supplying the fix.
- **Why it matters:** A linear reader meets the strong claim in Ch 8 and its
  softening in Ch 10. The graph would benefit from a `Tension` node or a Ch8→
  Ch10 `supersedes`/`tensionWith` edge once you decide.
- **Options:**
  - [ ] **(rec) Adopt the Ch 10 softening into Ch 8** and add a forward
    pointer; then record it as resolved in the graph (`tensions.json` or a
    claim revision).
  - [ ] Keep both and frame Ch 8's claim as deliberately provisional
    ("refined in Ch 10").

### A4. Receiver "want" — reflective vs operative
- **Where:** `content/info-time-limit.md:79` (flags it elides the distinction)
  vs `content/emotional-memetics.md` (leans hard on reflective vs intuitive
  belief).
- **What's there:** Ch 3 knowingly uses a looser notion of "want" than the
  vocabulary Ch 7 later establishes. Not a contradiction; an
  earlier-chapter-is-looser seam.
- **Options:**
  - [ ] **(rec) Add a one-line forward pointer in Ch 3** to the Ch 7
    refinement. Cheap, preserves reading order.
  - [ ] Harmonize Ch 3's "want" language to the Ch 7 distinction.

---

## B. Voice & reader experience

### B1. Voice asymmetry (Ch 3 / Ch 4 vs Part IV)
- **Where:** self-flagged at `content/info-time-limit.md:83` and
  `content/optionality vs access.md:156`.
- **What's there:** Ch 3 and Ch 4 are in a looser, more conversational register
  than the dense Part IV chapters; both note this as an open question.
- **Options:**
  - [ ] **(rec) Leave for a dedicated voice-harmonization pass** once the
    argument is frozen — premature now.
  - [ ] Tighten Ch 3/Ch 4 toward Part IV's register now.

### B2. "Where I'm still uncertain" sections
- **Where:** the tail of most chapters.
- **What's there:** Each chapter ends with a substantial uncertainty section.
  Excellent for the workshop posture; for a *book* reader they accumulate into
  a lot of hedging and read as author notes.
- **Options:**
  - [ ] **(rec) Keep while drafting; revisit at "book-ready" time** — consider
    moving them behind a collapsible or into per-chapter "workshop" notes that
    the serial reading path skips.
  - [ ] Trim/fold into prose now.

---

## C. Mechanical prose hygiene (still prose → flagged, not touched)

These are unambiguous and quick, but they live *in* prose so the audit left
them for you. All are one-liners.

- [ ] **`[NEED EVIDENCE HERE]` placeholder** — `content/medium-and-manipulation.md:41`.
  A literal placeholder in otherwise-finished prose. Either cite the source
  (Mercier / the want-loop material) or cut the bracket.
- [ ] **Stray pasted-image embed** — `content/the-information-landscape.md:13`
  embeds `![[Pasted image 20240922201821.png]]` directly above a clean Mermaid
  diagram of (apparently) the same thing. The PNG exists and renders, but it
  looks like an Obsidian leftover duplicating the diagram below it. Decide:
  keep the PNG, keep the Mermaid, or keep both intentionally.
- [x] **`matplotplib.png` misspelling** — `content/optionality vs access.md:55`
  embeds `![[matplotplib.png]]` and the image file is also misspelled
  `matplotplib.png`, so it renders. Rename both to `matplotlib.png` for
  correctness, or leave (cosmetic). *(Done in Phase 83: file renamed, embed
  fixed.)*
- [ ] **Filename with spaces** — `content/optionality vs access.md` is the only
  note whose filename has spaces. Quartz slugifies it to `optionality-vs-access`
  (which is why I fixed the viewer's prose-link to match — see Track B). Wiki-
  links `[[optionality vs access]]` work today.
  - [ ] **(rec) Rename** to `optionality-vs-access.md` and update the ~handful
    of inbound wikilinks + the prev/next nav. Removes a fragile special case.
    *(Was deliberately avoided in Phases 60/61; the viewer side is already
    safe either way.)*
  - [ ] Leave as-is.

---

## D. Metadata the three reading modes would benefit from

### D1. Add `status` / `order` frontmatter
- **What's there:** Every note has `title` + `tags: [information]` only. The
  whole project is organized around *drafting status* (the outline tracks
  "full draft / workshop / skeleton", the graph has a "Drafting status" view),
  but that status lives only in prose and the graph — **not** in queryable
  frontmatter.
- **Why it matters:** Quartz can surface a frontmatter `status` as a badge and
  sort/filter by it; a `order` field would make the serial reading order
  data-driven instead of hard-coded in `quartz.layout.ts` (where I currently
  keep it — see Track B). One source of truth for status across serial, wiki,
  and graph views.
- **Options:**
  - [ ] **(rec) Add `status:` (polished/draft/note/skeleton) and `order:`** to
    chapter/note frontmatter. I can generate these from the graph's existing
    `hasStatus` edges and chapter numbers if you want — say the word.
  - [ ] Keep ordering in the layout file (works today; just not data-driven).

---

## E. Author-facing artifacts living in reader space

- [ ] **`content/outline.md`** is explicitly author-facing and dense; the index
  already warns readers to skim the glossary first. Decide: keep it published
  with a "working doc" banner, or exclude it from the reading surface
  (Quartz `ignorePatterns` / a `draft: true` frontmatter).
- [ ] **`content/general-theme.md`** is a raw conversation transcript (the
  project's origin). It's intentionally raw, but it sits in the same folder as
  polished chapters and is reachable serially/by graph. Decide: add a "this is
  source material" banner, move it under a clearly-marked folder, or leave.

---

## F. Schema / data design calls (deferred from the build cleanup)

These aren't prose, but they're judgment calls, so they're here rather than
silently changed.

### F1. Three unwired ("dead") predicates
- **Where:** `data/graph-meta.json` defines `precondition`, `compresses`,
  `selectsFor` (all `category: causal`), but **no loader in
  `scripts/build-graph.js` ever emits them** — zero edges of these types exist.
- **What's there:** They encode the PipelineStage/Gate causal layer the book
  describes (a stage *compresses* into the next; a gate *selects for* a
  concept). They're scaffolding that was never wired.
- **Options:**
  - [ ] **(rec) Wire them** — author the `compresses` (stage→stage),
    `selectsFor` (gate→concept), and `precondition` edges. This makes the
    pipeline model in `the-information-landscape.md` a first-class part of the
    graph. I can draft the edges for your review.
  - [ ] Remove them from the schema to keep `graph-meta.json` honest.

### F2. Malformed triples in the committed per-PDF extractions — RESOLVED (deleted)
- **Where:** `data/interpretive/psychology-of-virality-gap.jsonl` (6 triples
  with a **Concept as the subject of `supports`/`pressureTests`** — direction
  violation) and `data/interpretive/misinformation-age.jsonl` (4 triples whose
  object is a `question`/`case`/`chapter` instead of a claim/mechanism/concept).
- **Resolution (Phase 69, June 2026):** deleted the 10 lines. The aggregator
  had rejected all of them on every run since extraction, so none was ever in
  the graph; git history keeps them recoverable if a future re-extraction wants
  to fix the direction and land the evidence properly. The same phase made the
  bare-build fallback warn on these conditions (it used to drop them silently),
  so a regression would now surface.

### F3. Chapter and note summaries overlap but are independently framed
- **Where:** `data/chapters.json` (chapter `summary`) and `data/notes.json`
  (the draft note's `summary`) for each chapter-draft pair.
- **What's there:** The audit's first pass flagged these as duplicated text to
  de-dupe. On close reading they are **not** mechanical copies: 13 of 14 pairs
  are independently-written paraphrases with different emphasis and detail (the
  `ai-as-new-node` note says "five selection-design surfaces" where the chapter
  lists seven; `emotional-memetics` drops a whole sentence and rephrases the
  evidence lines). Only `selection-as-other-engine` is near-verbatim (the note
  is the chapter summary minus its last sentence), and even that follows the
  consistent "Chapter Nx draft. …" note pattern.
- **Why it matters:** the maintenance concern (two strings to keep in sync) is
  largely resolved now that both live in `data/*.json` (Phase 74) rather than
  one being buried in code. What remains is an authorial question, not a
  mechanical one: do you *want* the note summary to be the chapter summary's
  short form, or to describe the note as a standalone artifact? No rewrite was
  done — changing 13 author-written framings on a subjective basis is out of
  the audit's no-touch-prose scope.
- **Options:**
  - [ ] **(rec) Leave as-is** — the framings are intentional and serve two
    surfaces (note-as-artifact vs chapter-as-argument).
  - [ ] Consciously make each note summary note-specific (describe the draft's
    state/scope, not restate the chapter's argument).

---

## G. Editorial content audit — June 2026 (consistency + timeline)

Full-manuscript editorial pass (all 14 spine chapters read). Method: every
explicit cross-chapter reference classified for a *linear* reader; every
load-bearing claim checked against the chapter that owns it. 182 forward
references exist against 165 backward — forward referencing is part of the
book's working-draft style and mostly fine; the items below are the cases
that break the linear reader or contradict the book's own canon.

> **Applied June 12, 2026 (Phases 80–83), at the author's direction.** All
> boxes below are ticked except the one structural decision (capture-
> taxonomy's place in the reading order), which stays open. House style
> adopted for cross-references: chapters are *places* — signpost forward in
> present tense ("Ch 10 makes this argument in full"), never perfect tense
> ("Ch 10 worked out"). Epistemic honesty (uncertainty sections, named open
> questions) kept throughout; what was removed is production metadata.
> Verbatim claim anchors in `data/claims.json` were updated wherever an
> anchored sentence changed; every phase verified drift-clean.

### G1. Hard contradictions (fix before anything else)

- [x] **Ch 8's capture asymmetry stated backwards once.**
  `preservation-vs-training.md:79` ends: training is "the more recoverable
  half on the capture axis (because cohorts come and go)". The chapter's own
  thesis (L69, L109), the glossary, and Ch 12 all say the opposite — captured
  training *recovers more slowly* ("you cannot replace a corrupted
  generation", L71). Likely a crossed clause: decay axis (training more
  fragile) vs capture axis (training *less* recoverable). One-line fix, but
  it's the book's single most load-bearing asymmetry.
- [x] **Ch 11's surface count is unstable.** The chapter's claim is "five
  selection-design surfaces", but `ai-as-new-node.md:119` ("The chapter,
  whole") lists **seven** (gate, option-space, content-generator, corpus,
  objective, deployment, pricing-tier) with no "plus increasingly" hedge;
  the outline's canonical form is 5 core + 2 "increasingly".
  `bridge-zone-distortion.md:87` enumerates six then says "All five".
  Decide the canonical enumeration once and conform all three sites.
- [x] **Ch 9 says "two things at once", then closes with three.**
  `integration-problem.md:63` (bold, load-bearing): "has to do **two** things
  at once"; L65 bolts on the third pillar in revision voice ("adds a third
  element the chapter should name explicitly"); L156 closes "does **three**
  things at once". Rewrite L63–65 to commit to three from the start.
- [x] **Ch 10's pressure-test count doesn't reconcile.**
  `political-economy-of-attention.md:85` announces "Five claims … are
  contested"; six bolded pressure-tests follow, and the tally at L107
  (2+1+1+2) omits the Mercier item. Recount.
- [x] **Ch 10 misattributes the Orwell/Huxley frame.**
  `political-economy-of-attention.md:37`: "Huxley's foreword to *Brave New
  World Revisited*" — *BNWR* (1958) is Huxley's own essay collection, not a
  foreword. Either "Huxley's *Brave New World Revisited*" or (more standard)
  Postman's foreword to *Amusing Ourselves to Death*. Verify and fix.
- [x] **Ch 12 contradicts Ch 8's diagnosis in passing.**
  `infrastructure-for-integration.md:43`: "broader preservation has collapsed
  without it" vs Ch 8's "preservation mostly held". This is the A3 decision
  (elite-preservation-held) surfacing again — whichever way A3 lands, make
  Ch 8 and Ch 12 agree.
- [x] **Ch 7 puts awe inside the floor, then below it.**
  `emotional-memetics.md:15/21` include awe in the floor bundle; L97 tunes
  "threat over awe" *below* the floor. The tension is admitted at L158 but
  the body should pick one placement.

### G2. Timeline: past-tense references to unread chapters (the big sweep)

The book's chapters were drafted in a different order than they are read,
and ~30 references betray it: a *later* chapter is cited in completed tense
as if the reader has been there ("Ch 10 worked out…", "the story Ch 8
told…", "Ch 9's argument was…"). A linear reader repeatedly arrives at
"as Chapter 12 worked out" eight chapters early. **Recommended policy:**
signpost forward, never perfect-tense forward — "Chapter 10 will work out"
/ "Chapter 10 works out (we'll get there)" / restructure the sentence to
own the claim locally. Worst clusters (line numbers from current drafts):

- [x] `bridge-zone-distortion.md` (Ch 6) — 6 sites: L9 ("Part IV gave"),
  L43, L69 ("Ch 10 worked out"), L73 ("story Ch 8 told"), L77 ("Ch 9's
  bridge-node argument was"), L83 ("what Ch 12 was implicitly describing").
  Also L77 conflates the foundational note with "Ch 9" by name.
- [x] `integration-problem.md` (Ch 9) — L57 ("Ch 12 worked out the design
  principles"), L87, L148 ("the conditions Ch 10 diagnosed" — Ch 10 is the
  *next* chapter).
- [x] `info-time-limit.md` (Ch 3) — L53, L63, L65, L69 (Ch 8/11/12 treated
  as finished work; "the most leveraged intervention the book has been able
  to point at" reads as completed-book retrospective).
- [x] `complexity-virality-tradeoff.md` (Ch 5) — L68 ("Ch 8 worked out"),
  L117 ("Ch 5b made that… the load-bearing claim"), L119.
- [x] `case-studies-and-three-realities.md` (Ch 2) — L70 ("Chapter 5b worked
  out the mechanism in detail").
- [x] `preservation-vs-training.md` (Ch 8) — L9 ("the answer turned on
  bridge nodes" — Ch 9 unread), L47.
- [x] `emotional-memetics.md` (Ch 7) — L127 ("Ch 10 said this").
- [x] `optionality vs access.md` (Ch 4) — L118 ("Chapter 10's cost-shifting"
  possessive-cite, concept undefined for the reader).

### G3. Workshop voice leaking into reader prose

Revision notes, drafting history, and authoring-pipeline vocabulary sit in
chapter bodies (outside the sanctioned "Where I'm still uncertain"
sections). The deliberate working-in-public register can carry *some* of
this, but the current density punctures otherwise strong chapters —
worst is Ch 10, where eight separate asides ("I have not done that work
here. Flag for later", "Reading my draft back, I had not", "that is the
extraction agent's call to make on the next pass") interrupt the book's
strongest argumentative surface. Decide a line: epistemic honesty stays,
*production* metadata moves to the uncertainty sections or out of the prose.

- [x] `political-economy-of-attention.md` L43, L47, L61, L93, L97, L99,
  L101, L105 — revision diary + extraction-pipeline meta.
- [x] `selection-as-other-engine.md` L97 — interpretive-triple counts
  ("contributes 19 triples (11 supports / 4 pressureTests…)") in body prose;
  graph tooling is meaningless to a book reader.
- [x] `emotional-memetics.md` L41 ("27 interpretive triples"), L11, L55,
  L57, L75 — extraction/drafting meta.
- [x] `complexity-virality-tradeoff.md` L9, L30, L50, L123 — "earlier
  drafts of this chapter" ×4.
- [x] `integration-problem.md` L9, L15, L45, L47, L77 — chapter narrates
  itself as an artifact under revision.
- [x] Outline cited as authority in body prose:
  `truth-compression-and-when-each-wins.md` L13, L61 ("The outline calls
  this…", "The outline wants this chapter to be…"),
  `preservation-vs-training.md` L37. The outline is scaffolding, not a
  citable source for the reader.
- [x] Blog-residue artifacts: `optionality vs access.md` L12 ("article
  topics I've wanted to work on"), L76 ("the point of another article in
  the future" — it's a book chapter now), ALL-CAPS "VERY" (L12), bare
  "NOTE:" aside (L80); `preservation-vs-training.md` L29 +
  `integration-problem.md` L51/L67 cite "the democratization-paradox
  *post*" / "double-edged-sword *post*" — for a book reader these need to
  be essays/appendices with a referent, not posts.

### G4. Concepts used before they exist (gloss-on-first-use gaps)

Recurring pattern: a later chapter's (or depth note's) term arrives cold,
ungloossed, chapters before its home. Recommended policy: **every
load-bearing term gets a one-clause plain gloss at its first appearance in
each chapter** (the term's home chapter still owns the full treatment).
Worst offenders, by term:

- [x] *captured equilibrium* — first cold use `bridge-zone-distortion.md:55`
  (home: Ch 10).
- [x] *consumer-key substrate / consumer-key-vs-surface* —
  `case-studies-and-three-realities.md:106`,
  `complexity-virality-tradeoff.md:92`, `bridge-zone-distortion.md:71`,
  `preservation-vs-training.md:69` (home: capture-taxonomy note, which is
  not in the reading order at all).
- [x] *substrate custody* — `info-time-limit.md:65`,
  `bridge-zone-distortion.md:87/103`, `integration-problem.md:89/150`
  (home: Ch 11/12). Not in the glossary either.
- [x] *integration problem / integration project* — `info-time-limit.md:59`,
  `optionality vs access.md:100` (home: Ch 9).
- [x] *cost-shifting* — `optionality vs access.md:118` (home: Ch 10).
- [x] *the dilution loop* — `preservation-vs-training.md:63`,
  `political-economy-of-attention.md:59` lean on the
  myths-scale-and-bureaucracy note's three-outcome cells with a
  parenthetical gloss carrying the whole load.
- [ ] **Structural decision implied:** the capture-taxonomy note is
  load-bearing for Chs 6, 8, 9, 10, 11, 12 but lives outside the reading
  order. Either promote its two principles (consumer-key-vs-surface;
  objective-capture-self-reinforces) into Ch 8/Ch 10 prose proper, or give
  the note a numbered interlude slot (e.g. "Interlude: Capture" after
  Ch 8). Same question, smaller, for myths-scale-and-bureaucracy before
  Ch 8. The current half-in-half-out status is the root cause of most G4
  items.
- [x] Glossary gaps: *substrate custody*, *modality argument*,
  *selection-design surface* have no entries; "Zollman effect" is used in
  Ch 12 (L81) with a one-clause gloss but gets its full gloss only in the
  glossary.

### G5. Stale facts (drafting state that moved on)

- [x] `ai-as-new-node.md:115` and `:131` — "A forthcoming foundational note
  will work the unification" / "the work the next foundational note will
  do; until it is done". The note exists (`capture-taxonomy.md`) and is
  cited at L71 *of the same chapter*. Also `:71` "now lives in
  capture-taxonomy" vs `:115` "forthcoming" — same chapter, both states.
- [x] `optionality vs access.md:122` — "Stand back from the four domains";
  the chapter has five (its own L9 and L148 say five).
- [x] `case-studies-and-three-realities.md:128` — "A revised Ch 5c (when
  the re-engagement pass comes)" — 5c is drafted and objective-scoped.
- [x] `truth-compression-and-when-each-wins.md:89` — treats
  precondition-count-vs-handle-ability as unresolved; Ch 5 (L30) closes it
  via the 5b split. (Inside an uncertainty section, but factually stale.)
- [x] `integration-problem.md:130` — "The book has been citing four
  candidates" vs L142 "the pattern across the five" (common-law courts
  added without updating the count). L11 also points at "the open-threads
  section", which doesn't exist under that name.

### G6. Small mechanical

- [x] "tecnocratic" ×2 (`ai-as-new-node.md:37`; also outline) — if this
  mirrors the encyclical's Italian *tecnocratico*, mark it [sic] once;
  otherwise spell "technocratic".
- [x] `content/images` figure filename "matplotplib.png" (typo is canonical
  in repo; renders, but will trip any future asset audit).
- [x] Ch 2 coins "publication gate" (L22, L34) — blurs Ch 1's
  analysis/publishability vs consensus/peer-review gate split; align names.
- [x] Ch 3 never states "time budget" = "receiver budget"
  (`info-time-limit.md:33→39`) — one equivalence sentence fixes the
  glossary↔chapter mismatch.
- [x] Want-loop naming drift: "medium-shapes-want" (Ch 7 L53) vs
  "want-loop" (Ch 7 L117/L140) vs "medium-and-want" (Ch 8 L91). Pick one.
- [x] Ch 7's closing nav renders the Ch 6 title's profanity
  (`emotional-memetics.md:163`) — fine if B1 keeps the title; noted so the
  choice is conscious in nav surfaces too.

### What the audit did NOT flag

Signposted forward handoffs ("Chapter 11 introduces…", "slated for
Chapter 5c") are working as designed — they're promises, not debts, and
they're one of the book's best structural habits. Ch 1 and Ch 12 are clean
end-to-end (Ch 1 glosses everything it uses; Ch 12 is the least
workshop-contaminated chapter in the book). The "Where I'm still
uncertain" sections are an asset throughout — nothing in them needs to
move; the G3 items are about *production* metadata, not epistemic honesty.

---

## Already handled by the audit (no action needed — listed for awareness)

- **Wiki dead-links fixed.** Heavily-referenced `[[wikilinks]]` to graph nodes
  (`justification-market`, `open-vigilance`, `power-posing`, `arsenic-life`, …)
  used to 404. They now resolve to generated landing pages under
  `content/{concepts,cases,mechanisms,questions}/` with summary + connections +
  backlinks. (`scripts/generate-concept-pages.js`.) `interpretive-latitude`
  now has a page too.
- **Source-evidence layer ships from a bare `make build`.** Was a half-graph;
  now 1051 edges / 0 warnings.
- **Viewer prose-link 404 for Chapter 4** (spaces slug) and the **SPA-intercept
  blank viewer** are fixed.
- **Explorer** now reads in chapter order; **interactive graph** no longer
  collapses into one `information`-tag hub.
- **README** brought current; `.trash/astrology.md` removed; `make clean`
  completed; `build-stats` phase un-hardcoded.
