# Prose & authorial decisions — for the author to rule on

This file is the output of the June 2026 repo audit. Per the chosen scope,
the audit **did not touch any prose** — every item below is *flagged, not
fixed*, and waits on your call. The mechanical build/site/graph fixes from the
same audit (Tracks A, B, D) were applied directly; this file is only the
things that change the book's *content, voice, or argument*, plus two
schema/data calls that are really design decisions.

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
- [ ] **`matplotplib.png` misspelling** — `content/optionality vs access.md:55`
  embeds `![[matplotplib.png]]` and the image file is also misspelled
  `matplotplib.png`, so it renders. Rename both to `matplotlib.png` for
  correctness, or leave (cosmetic).
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

### F2. Malformed triples in the committed per-PDF extractions
- **Where:** `data/interpretive/psychology-of-virality-gap.jsonl` (6 triples
  with a **Concept as the subject of `supports`/`pressureTests`** — direction
  violation) and `data/interpretive/misinformation-age.jsonl` (4 triples whose
  object is a `question`/`case`/`chapter` instead of a claim/mechanism/concept).
- **What's there:** `make aggregate-interpretive` already drops these (logged
  to `data/interpretive-notes.json`), so the graph stays clean — but they keep
  getting re-dropped on every aggregate, and they represent extraction work
  that isn't landing.
- **Options:**
  - [ ] **(rec) Fix the direction** in those `*-gap.jsonl` lines (make the
    Source the subject) so the evidence actually lands in the graph.
  - [ ] Delete the malformed lines if the claims are redundant.
  - [ ] Leave (harmless; just lost evidence).

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
