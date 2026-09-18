# Editorial plan — September 2026

The output of a full-manuscript editorial pass (September 17, 2026). Every
content file was read against one rubric: argument, voice, evidence,
concision, interlinking, reader-facing defects. The per-file reports live in
[`audit/2026-09-editorial/`](audit/2026-09-editorial/); this file is the plan
that comes out of them. It follows [`PROSE-DECISIONS.md`](PROSE-DECISIONS.md)
in spirit: decisions for the author, with the recommended option first.

A few items were applied in the same pass so the plan has a worked example
(see **What already landed** at the end). Everything else is proposed, not
done.

## Where the book stands

`make lint-prose` now prints the numbers below for every content file. The
whole-corpus line, before this pass:

| measure | value |
|---|---|
| words in content/ (26 files) | 104,500 |
| self-narration hits ("this chapter", "the book has", "said plain", "I should be honest" …) | 507 |
| raw "Ch N" mentions | ~950 |
| tic words (load-bearing, exactly, quietly, substrate, at scale, precisely …) | 517 |
| reversal constructions ("not X but Y", "isn't X; it's Y") | 62 |
| words inside "Where I'm still uncertain" tails | 14,215 (14%) |
| active claims with zero source edges | 20 of 36 |
| sources with an extraction file | 7 of 29 (now 32) |
| content files with `description:` / `aliases:` frontmatter | 0 (now 24) |
| graph-node terms used in a chapter but never wikilinked | ~250 term–file pairs |

The argument is in good shape. Chapter 1 is the voice target and hits it;
5b, 5c, 10, and 12 are the strongest chapters. The problems are almost all
*surface* problems that compound: the prose narrates itself as a manuscript
under revision, every chapter re-argues its neighbours, and the evidence
layer stopped being maintained after the claims were promoted. The editors'
consensus estimate is that **35–45% of the chapter text can go without losing
argument**, most of it restatement, roadmap, and production notes.

## Workstream A — Structure (do first; everything else is cheaper afterwards)

**A1. Settle the reading order.** Seven foundational notes sit outside the
numbered spine while nine chapters lean on them. The structure report
([audit](audit/2026-09-editorial/foundational-notes-structure.md)) recommends:

- [x] **(done — Phase 123, scoped down)** The recommendation was to fold three
  notes; on inspection only one was foldable. Folded `three-layer-message` →
  Ch 5 (a "What a message is made of" section, Voyager included; the slug
  redirects). Kept `transport-vs-selection` (→ 5b) and
  `bridge-nodes-and-versatile-expertise` (→ 9) as depth notes: Chs 5b and 9
  already carry their cores and have diverged past the notes (Ch 9 now argues a
  three-leg prescription to the note's two), so folding would lose the
  working-through and orphan claim anchors.
- [x] **(done — Phase 122)** Make two interludes: *Myths at Scale* between Ch 7 and Ch 8
  (four chapters gloss the dilution loop in a parenthetical; none argues it),
  and *Capture* between Ch 11 and Ch 12 (only Ch 12 uses the full taxonomy; the
  LLM surfaces don't exist before Ch 11). Promote the consumer-key-vs-surface
  principle into Ch 8 so Chs 5–9's forward references resolve to a chapter.
- [x] **(done — Phase 122)** Promote `intersubjective-truth` to a numbered chapter (8b,
  "Truth the Network Makes"). It carries the book's second thesis and nine
  chapters defer to it rather than restate it; an appendix can't hold a thesis.
- [x] **(done — Phase 122; chose the interlude)** *Medium and manipulation*: interlude after 5b, or fold its two remaining
  levers (capacity, want) into 5b's option-space section. Author's call; the
  fold is cheaper, the interlude is cleaner.
- [x] **(done — Phase 122)** Resulting order: 1 · 2 · 3 · 4 · 5 · 5b · [Medium] · 5c · 6 · 7 ·
  [Myths] · 8 · 8b · 9 · 10 · 11 · [Capture] · 12. Update `data/chapters.json`,
  `data/notes.json`, prev/next nav, `outline.md`, and the talk's act map.

**A2. Chapter-level cuts and reorders** (line numbers as of this audit; each
per-file report lists the six biggest cuts):

- [ ] Ch 2: end at L80 ("the pipeline doesn't break at random. It fails in a
  *direction*"); L114–150 is a changelog for other chapters. (−40%)
- [ ] Ch 3: rewritten in this pass as the exemplar (2,870 → 1,470 words).
- [ ] Ch 5: keep the transport core (L15–58); L105–121 is previews of Ch 8–12.
  Say "this is the transport half" once, not eight times. (−45%)
- [ ] Ch 5b: move "The medium is frozen selection" up to follow "Three
  operations" (the chapter confesses the misordering at L25/L53).
- [ ] Ch 7: split the Mercier engagement (L39–85, ~2,100 words) into its own
  note; the chapter then makes the floor argument and points at it.
- [ ] Ch 8: move the Soviet-science / Reformation evidence out of the
  uncertainty tail into the body after L73, as the test of the asymmetry.
- [ ] Ch 9: put the five operational problems (L75–142) *before* the
  three-pillar prescription (L63), so the prescription is what survives them.
  Delete the technical twin of every plain-language paragraph (L27/31, L37/39).
- [ ] Ch 10: move the 1,400-word "Pressure-tests" section (L99–125) to a
  note and keep one paragraph. (−45%)
- [ ] Ch 11: move the 1,040-word encyclical section (L27–43) after the
  chapter's own argument and halve it; give the "captured model as generator of
  shared reality" idea (buried at L101) its own section.
- [ ] Ch 12: close once (it closes at L29–37, L125–131, L133–137) and drop
  the two recap paragraphs at L9–11.
- [ ] Every chapter: delete "Chapter N, Part X" scaffold openers, "What this
  changes for the book" sections, and "Where I land / The chapter, said
  plain" restatements. Bold one load-bearing sentence per section; the
  harvester needs it, the reader doesn't need forty.

**A3. Uncertainty tails.** 14% of the book. Keep the genuinely open bullets
(typically 2–3 per chapter), move production notes out, and move the best
ideas *up* into the body: Ch 2's consensus-inattention-vs-rejection, Ch 3's
reflective-vs-operative want (done), Ch 6's "is the bridge zone a distinct
thing" (answer it at L15), Ch 8's capture evidence.

## Workstream B — Voice pass v2 (the AI-isms)

**Status: done, with a caveat (Phases 99–118 rewrites + Phase 128).** Rule 1
(self-narration) is delivered to target: 507 → 50 hits, every content file at
or under 1 per 1,000 words. Rule 2 (forward references) resolved in the
rewrites (perfect-tense forward refs 1 → 0). Rule 3 (tics): the *exactly* tic
was trimmed (288 → 243 tic words in Phase 128); the rest were left by decision
— `substrate` (74) is kept consistent across all chapters rather than renamed,
and *load-bearing / quietly / precisely* were left where they carry meaning,
which is most of their remaining uses. Rules 4–6 (reversals, aphorisms,
parenthetical/colon density) were largely handled in the rewrites and are not
pushed further: the reversal is the book's signature move and usually the
argument itself, so a mechanical cut would flatten the voice for little gain.
The raw residual counts (243 tics, 42 reversals) overstate the remaining
AI-ism problem because most instances are legitimate.

Phase 95 removed em-dashes and produced the current colon/parenthesis density;
the tics that remain are structural, not typographic. House rules, in priority
order, with the lint column that tracks each:

1. **No self-narration** (`self`). The prose never refers to itself as a
   chapter, note, draft, or book, and never to the graph, extraction, triples,
   passes, or the outline. Say the thing; don't announce that the chapter is
   about to say it. Target: under 1 per 1,000 words (Ch 1 is at 1.3).
2. **Chapters are places, referenced sparingly and in present tense**
   (`ChN`, `fwd`). One forward pointer per hand-off, never "Chapter 10 worked
   out". Target: under 3 "Ch N" per 1,000 words.
3. **Retire the tic vocabulary** (`tics`): *load-bearing* (64), *exactly*
   (105), *quietly* (39), *substrate* (195, and it means two opposite things:
   physical carrier in the medium note, selection surface in the taxonomy;
   rename the taxonomy sense), *at scale*, *precisely*, *the honest version*,
   *names/sharpens/collapses into*.
4. **One reversal per section at most** (`rev`). "Not X but Y" is the book's
   signature move and it is used 60+ times; keep it where the reversal *is* the
   argument (5b's modality point), cut it where it is rhythm.
5. **No paragraph-closing aphorism unless it's the sentence people will
   quote.** The short version already collected those; everything else is
   ornament.
6. **Parentheticals and colon-chains** (`paren`, `colon`): where an em-dash was
   replaced by parentheses, the sentence usually wants to be two sentences.

Process: run `make lint-prose FILE=<slug> VERBOSE=1`, work the hits top to
bottom, re-run. The Ch 3 rewrite went from 5.6 self-narration per 1,000 words
to 0.7, 15 tic words to 2, and half the length, with the same three claims and
better evidence. Suggested order: Ch 2, 5, 9, 10, 11 (worst density), then
the rest.

## Workstream C — Evidence

The evidence layer is the biggest gap relative to the book's ambition. Full
detail in [`evidence-layer.md`](audit/2026-09-editorial/evidence-layer.md).

- [ ] **C1. Gap pass (cheapest, highest value).** Seven unbacked claims point
  at sources that are *already extracted* (`misinformation-age`,
  `not-born-yesterday`, `psychology-of-virality`, `amusing-ourselves-to-death`,
  `info-evolution-social-media`); they were promoted after the extraction pass.
  `make catalog`, then re-run the extraction agent over those five PDFs for
  the seven claims, then `make extract-build`.
- [ ] **C2. Extract the free sources.** `magnifica-humanitas` (open text, 48
  mentions, backs a tension node), the three author-owned posts
  (`democratization-paradox`, `double-edged-sword-of-expertise`,
  `anatomy-of-exposure`, which carries every number in Ch 10's transparent-
  money section), then `nexus` (10 chapters), GEB ch. VI, McLuhan.
- [x] **C3. Enter the works the book argues with but never cites.** *(done —
  Phase 127, edges deferred.)* The 15 works in evidence-layer.md §3 (with the
  Guess/Nyhan pair split into two, so 16) are entered as external sources with
  authors, three new traditions (`attention-economy`, `empirical-social-media`,
  `institutional-analysis`), and generated citation pages that record each
  work's claim and direction (supports / pressureTests). No quote-backed
  supports/pressureTests graph edges were added: all 164 existing interpretive
  edges carry a verbatim quote and these PDFs are unextracted, so fabricating
  quotes was declined and the edges await an extraction pass over the real
  texts. Still to enter (named here but outside §3): Weng et al. 2012, Berger &
  Milkman 2012, Rathje et al. 2021, Kyrychenko et al. 2024, Sumner et al. 2014,
  Allport & Postman 1947, Converse 1964, Kuran 1995, Burt 2004, Tetlock 2005,
  Kahan et al. 2017, Salganik/Dodds/Watts 2006.
  <!-- original list retained below -->
  The
  strongest pressure-tests: Boxell/Gentzkow/Shapiro 2017 and Guess et al.
  2023 (against the timescale-distinction claim); Guilbeault/Baronchelli/
  Centola 2021 (scale produces *convergence*, against the dilution loop);
  Collins & Evans 2007 (interactional expertise, against the bridge-node
  claim); Nyhan et al. 2023 (against adding-channel-accelerates-divergence);
  Weng et al. 2012 (a content-neutral null the floor argument has to beat).
  Supports: Brady et al. 2017, Berger & Milkman 2012, Rathje et al. 2021,
  Kyrychenko et al. 2024 (the Ukraine primary), Sumner et al. 2014 (caveat
  loss at the press-release hop), Allport & Postman 1947, Converse 1964,
  Kuran 1995, Burt 2004, Tetlock 2005, Kahan et al. 2017, Salganik/Dodds/
  Watts 2006, Zuboff 2019. Each is mapped to a claim in the report.
- [ ] **C4. Chapter-local citations.** Ch 1: Rosenthal 1979 (file drawer),
  Ioannidis 2005; cut the climate-reporting claim at L173. Ch 2: the five
  primary case papers (Carney/Cuddy/Yap 2010, Ranehill 2015, Wolfe-Simon 2010,
  Blum 2018, Le Texier 2018/2019). Ch 4: Duverger/Downs for the politics
  section; soften Vatican II. Ch 6: zero sources for its three headline cases
  (COVID, nutrition, monetary policy); give each a `cases/` page and one
  primary. Ch 11: Shumailov et al. 2024 (model collapse), Sharma et al. 2023
  (sycophancy); expand "RLHF". Ch 7: verify the Mercier p. 254 and Sperber
  p. 152 quotes (not in the extraction); add Sperber to `sources.json`.
- [ ] **C5. Factual corrections still open** (the ones fixed are listed at
  the end): invented numbers stated as fact (Ch 8 L81 "twenty or thirty
  years", Ch 9 L81/L83 "additional decade", "ten specialists per versatile
  expert"; Ch 4 L104 "under ten thousand" readers); overstatements (Ch 8 L89
  "contact hours collapsed", L91 newsroom training "all but collapsed", Ch 9
  L120 Wikipedia trust story, L132 "editor population aging"); Ch 10 L109 reads
  Adamic et al.'s Yule process as neutral drift (it isn't); Ch 10's transparent-
  money numbers ("billions siphoned" from sandwiching is overstated); bridge-
  nodes L25 "15–20 moves ahead"; myths L57 "Hammer-era Church" conflates a
  private text with Church bureaucracy; Ch 2 L78 says power posing "lost at
  consensus" against its own case heading; Ch 5c L69 vs Ch 1 on whether
  manufactured content has a regime.
- [ ] **C6. Experiments.** The interpretive-latitude design is good; add
  Hamilton et al. 2016 (frequency confound) and Guilbeault 2021 as the
  pre-registered adversary. Two cheap new ones: a caveat-loss-per-hop study
  (Sumner 2014's method on the book's own pipeline) and an age-period-cohort
  analysis for the floor claim, which Ch 7 says it owes.

## Workstream D — Interlinking and searchability

- [x] **D1. Search metadata.** `description:` and de-duplicated `aliases:`
  added to 24 files (done in this pass; Quartz's description plugin and
  note-properties block now show them, and `[[alias]]` links resolve).
  Still to write: the seven `cases/` pages Ch 6 needs, and descriptions for
  `general-theme.md` and `outline.md` if they stay published.
- [x] **D2. First-use links.** *(done — Phase 124; 113 links added, one per node-term per file, bold anchors skipped for drift safety.)* ~250 term–file pairs where a chapter uses a
  term that has a `concepts/`, `cases/`, `mechanisms/`, or `questions/` page
  and never links it (`make lint-prose VERBOSE=1` lists them per file).
  Worst: `selection` and `transport` (20 and 14 files), `compressed-form`
  (15), `memetic-fitness` (12), `self-vs-external-capture` (9). Rule: link the
  first use in each chapter, never the rest. Chapters 10, 11, 12 link zero of
  the concept pages they define.
- [x] **D3. Sources named in prose, unlinked.** *(done — Phase 125; the chapter rewrites had already linked all but one, Harari/Nexus in the intersubjective note, now fixed.)* Ch 5b names nine works and
  links none of their citation pages; Ch 9 names Nguyen and Zollman; Ch 6
  credits Postman's pseudo-context through other notes instead of
  `[[amusing-ourselves-to-death]]`. The intersubjective note never links the
  six social-ontology sources it says are "unengaged" (they're in
  `sources.json` with pages).
- [x] **D4. Glossary.** *(done — Phases 120 + 126; ### headings, See pointers, wrong-home and handle-ability fixes in 120; five graph-node links and the frozen-selection and seven-capture-surfaces entries in 126.)* Turn bold headwords into `###` headings so search and
  the TOC can anchor on them; add the missing "See" pointers (12 entries) and
  fix the 8 that point to the wrong home (superspreader and credibility
  weighting → "Ch 10", which never discusses them); link each entry to its
  `concepts/` page so the glossary is visible to the graph; add the missing
  coinages: *decoding key* (16 files use it), *the corrective*, *salvation/
  worst case*, *preserve-and-retrain*, *frozen selection*, *trust-bootstrap*,
  the seven capture surfaces, *constitutive transmission*. Fix the entry
  assigning handle-ability to Ch 5 (5b owns it).
- [ ] **D5. Case pages.** COVID epi, nutrition science, monetary policy
  (Ch 6), GDPR / plain-language law already exists; common-law courts and
  Stack Overflow (Ch 9/12) need pages so the five "worked examples" are
  navigable.
- [ ] **D6. The abyss.** The working tree moves the essay off-site; the
  chapters now link an external URL where `[[abyss]]` (the concept page)
  exists. Link the concept page in-text and put the external URL on the
  concept page.

## Workstream E — Reader-facing defects

- [ ] `index.md` L15 argues "what's changed is the speed", a history no
  chapter makes and Ch 5's Hammer/Copernicus case rejects; L19–45 duplicates
  `the-short-version.md` nearly line for line. Shrink the index to a teaser
  plus the three ways in, and let the short version be the summary.
- [ ] `the-short-version.md`: attribute its eight chapter quotes with links;
  drop "(Editor-drafted distillation, provisional.)".
- [ ] `outline.md` L29–44 still reports the retracted "selection-primary"
  answer; `transport-vs-selection.md` argues it for 100 lines before
  retracting at L112 (PROSE-DECISIONS A1, still open).
- [ ] `medium-and-manipulation.md:41` still has `[NEED EVIDENCE HERE]`.
- [ ] Perfect-tense forward references survive the Phase 80–83 sweep in
  Ch 6 (~10), Ch 5c (L71, L88 "leave to 5b", which precedes it), Ch 7, Ch 9.
- [ ] Cold terms: "institutional carriers" (Ch 1 L71, presented as *the*
  explanation of the consensus stage), "captured equilibrium" (Ch 6),
  "Huxley mode" (Ch 7, owned by Ch 10), "consumer-key" (Ch 12 never defines
  it in-chapter).
- [ ] Ch 3's old text said the budget was "fixed" in the glossary while
  arguing it was trainable (fixed in this pass). Same check for every
  glossary entry against its home chapter.
- [ ] Keep the Ch 6 title's profanity or don't, but decide once for the nav.

## Workstream F — Keep it fixed

- [x] `make lint-prose` (report-only dashboard; `FILE=`, `VERBOSE=1`).
- [ ] Once a chapter has been through voice pass v2, add a threshold test for
  it (self-narration < 1.5/1k, forward refs = 0) so it can't regress; the
  numbers are already in `--json`.
- [ ] Add a `frontmatter` invariant to `graph.test.js`: every published
  content file has `description:`.
- [ ] Add "sources named in prose but not linked" and "alias collisions" to
  the lint.
- [ ] Keep `data/claims.json` anchors in step with edits (`make harvest` after
  each chapter; the drift check is local-only by design).

## Suggested sequence

| phase | work | rough effort |
|---|---|---|
| 98 | A1 reading order + the three folds; retire the notes' "What this changes" sections | 1–2 days |
| 99 | C1 gap pass + C2 free-source extractions (`make extract-build`) | half a day of agent runs |
| 100–104 | B voice pass v2 + A2 cuts, one chapter per phase, worst-density first (2, 5, 9, 10, 11), harvesting anchors after each | ~half a day per chapter |
| 105 | D2/D3 first-use link pass (mechanical; the lint lists every hit) | half a day |
| 106 | D4 glossary restructure + D5 case pages | 1 day |
| 107 | E index / short version / outline cleanup | half a day |
| 108 | C3–C5 source entries and factual corrections, per chapter | ongoing |

## What already landed in this pass

- `scripts/lint-prose.js` + `make lint-prose` + README entry.
- Chapter 3 rewritten as the exemplar (voice, cuts, evidence, links, tail).
- `description:` + `aliases:` frontmatter on 24 content files.
- Factual fixes: arsenic-life refutation history (Ch 2), Le Texier translation
  year and name (Ch 2), seaborn confidence band and GDPR article/recital
  counts (Ch 4), Luria–Delbrück "eighty years" → seventy (Ch 5b), Postman's
  foreword sets *1984* against *Brave New World* not *Revisited* (Ch 10),
  Adamic et al.'s real title (Ch 10, `sources.json`), Stack Overflow's funding
  history and the LLM-substitution cause of its decline (Ch 9, Ch 12),
  Hammer/Copernicus dates and the Koestler/Gingerich point (`case-studies.json`).
- `index.md` no longer states the retired "selection is the stronger force";
  the glossary's receiver-budget entry no longer says "fixed".
- Three sources and one tradition added (Ericsson et al. 1993, Chi et al.
  1981, Gladwell 2008; *expertise research*), citation pages regenerated,
  graph snapshot re-blessed (263 nodes / 1187 edges / 0 warnings).

## Where the audit reports are wrong (so you don't chase them)

- Ch 12 L45 was flagged as contradicting Ch 8's "preservation mostly held".
  Ch 8 L87 already carries the elite/broad softening, so Ch 12 is consistent.
  Left as is.
- The reports' cut percentages are estimates by different readers; treat
  35–45% as the band, not the per-chapter figures as targets.
- Several suggested works were checked only for existence and relevance, not
  read; extract before citing.
