# Lossy

*How Ideas Get Compressed, Filtered, and Twisted on the Way to You*

The book's repo. Three subsystems share one tree:

- **`content/`** — the prose. Outline, chapter drafts, foundational
  notes, conversation transcripts, and the `sources/` PDFs. This is
  what gets written.
- **`data/` + `scripts/` + `src/`** — the **authoring ontology**: a
  semantic-triple graph over the prose. Chapters, mechanisms, concepts,
  open questions, claims, sources, and the edges between them.
  Modeled on the [Logos whitepaper graph](https://github.com/0xc1c4da/logos-whitepaper)
  and reshaped around this book's argument structure. The graph
  surfaces what the prose implies — claims to make, sources backing
  them, questions still open, chapters with missing anchors — and
  bundles it into context packets ready to drop into a drafting
  prompt.
- **`site/`** — a Quartz 5.1 install whose `content/` symlinks to the
  prose. Builds the book as a static site.

The site has **two reading modes**, both driven by the ontology:

- **The narrative** — the chapters and interludes, in order.
  `content/reading-path.md` (generated) is the spine: each one in a sentence
  or two, taken from its own `description:` frontmatter.
- **The cards** — every Concept, Mechanism, CaseStudy and Question in the
  graph is a short, self-contained, interlinked page (one plain sentence, an
  example, a few paragraphs, links to its neighbours, a pointer to the chapter
  section that argues it in full). Cards are grouped into ordered **themes**;
  `content/explore.md` (generated) is the map of all of them. See
  **The card layer** below.

## Run it

Prerequisites: **Node ≥ 22** (declared in `package.json`; the scripts are
ESM), GNU Make, and Python 3 (only for `make serve`'s static server). The
site additionally needs npm (`cd site && npm ci` once).

```bash
# Ontology
make                                              # rebuild graph (default = make build)
make test                                         # regression tests: snapshot + invariants
make accept-stats                                 # bless a new snapshot after an intentional graph change
make serve                                        # serve viewer at localhost:8765/src/
make stats                                        # counts + warnings from last build
make harvest                                      # rescan content/ for candidate claims
make lint-prose [FILE=<slug>] [VERBOSE=1]          # voice / linking / metadata dashboard per content file
make catalog                                      # regenerate extraction-catalog.json for agents
make aggregate-interpretive                       # merge per-PDF extractions into one JSONL
make extract-build                                # aggregate + rebuild (after running extraction agents)
make context CENTER=chapter:<slug>                # emit drafting bundle to stdout
make context CENTER=claim:<slug> ARGS="-o foo.md" # write bundle to file

# Site
make citation-pages                               # regenerate content/citations/*.md from sources.json
make concept-pages                                # regenerate cards, theme pages, explore.md, reading-path.md, chapter maps
make interlink                                    # link the first use of each card's name in each file (ARGS=--dry previews)
make site-build                                   # build Quartz output into site/public/
make site-serve                                   # build and live-serve at localhost:8080
make site-preview                                 # serve site/public locally the way GitHub Pages does (after site-build)
make site-clean                                   # remove site/public + site/.quartz-cache

make help                                         # list targets
```

<!-- graph-stats: kept in sync with data/expected-stats.json by a test in scripts/graph.test.js -->
Current state: **410 nodes / 3223 edges / 0 warnings**.

A bare `make build` is now self-contained: it folds in the committed
per-PDF source extractions (`data/interpretive/*.jsonl`) directly, so the
`supports` / `pressureTests` / `evidencedBy` evidence layer ships on a fresh
clone without a separate aggregation step. `make extract-build` is still the
canonical path when you re-run extraction agents (it re-validates and
de-dupes into `data/interpretive-triples.jsonl`), but the two produce the
same graph.

## The drafting loop

This is what the tool is for. The graph exists to make this loop tight.

1. **Generate a context bundle** for the chapter you want to draft:
   ```bash
   make context CENTER=chapter:selection-as-other-engine ARGS="-o /tmp/c5b.md"
   ```
   (Pass script flags through `ARGS=`; a bare `-o` after the make goal is
   swallowed by make and never reaches the script.)
   Output (~20-25 KB / ~5,000-6,000 tokens) contains the chapter's
   summary, every claim it argues with full verbatim source quotes
   (supports + pressure-tests with page numbers, confidence, rationale),
   open questions still blocking it, anchored mechanisms / concepts /
   case studies, related notes, and editorial flags (drafting status,
   contested claims, source-backing gaps).

2. **Paste into a fresh Claude session** and start drafting against it.
   The bundle is self-contained — every claim has its evidence inline.

3. **As prose accumulates**, edit the chapter's backing note in
   `content/`.

4. `make harvest` — scans the notes for new **bold sentences** and
   marker phrases ("the X claim, said plain", "where I land",
   "working answer"). Writes `data/claim-candidates.jsonl` — the inbox.

5. **Promote** the load-bearing candidates by adding them to
   `data/claims.json` with a stable slug, status, aliases, and
   `harvestedFrom` anchor.

6. `make build` — new claims become Claim nodes; drift detection runs
   on every claim's `harvestedFrom` and warns if anchor prose has
   disappeared since promotion.

7. If new claims need source backing, run extraction agents over the
   next batch of source PDFs (see Phase 4 in the commit log for the
   per-PDF subagent pattern). Then `make extract-build`.

8. Loop.

## What's in the graph

Schema is the contract in [`data/graph-meta.json`](data/graph-meta.json).

**16 node types**, grouped by role (current counts in parentheses):

- **Outline scaffolding**: `Part` (4), `Chapter` (15), `Note` (28), `Status` (5)
- **Pipeline model**: `PipelineStage` (6), `Gate` (5) (from
  `the-information-landscape.md`)
- **Argument layer**: `Mechanism` (11), `Concept` (82), `Question` (9),
  `Claim` (43), `Tension` (5)
- **Source layer**: `Source` (64), `Author` (69), `Tradition` (18)
- **Illustration**: `CaseStudy` (33)
- **Exploration**: `Theme` (13) — ordered clusters of cards

**30 predicates** in 7 categories:

- **structural** — `partOf`, `covers`, `definedIn`, `succeedsStage`,
  `gateFor`, `hasStatus`, `representedBy`, `inTheme`
- **causal** — `derivesFrom`, `enables`, `precondition`, `compresses`,
  `selectsFor`, `instanceOf`
- **provenance** — `cites`, `authoredBy`, `partOfTradition`,
  `evidencedBy`
- **dialectical** — `tensionWith`, `contradicts`, `supersedes`,
  `flagsOpenQuestion`
- **claim** — `argues`, `supports`, `pressureTests`, `dependsOn`,
  `illustrates`
- **associative** — `relatedTo` (curated see-also between cards)
- **weak** — `mentions`, `wikiLinks`

**Direction conventions worth memorising:**

- `supports` / `pressureTests`: **Source → Claim**
- `evidencedBy`: **Concept/Mechanism/Claim → Source** (reversed)
- `argues`: **Chapter or Note → Claim**
- `covers`: **Chapter → Concept/Mechanism/Question/Claim/CaseStudy**
- `illustrates`: **CaseStudy → Mechanism/Concept/Claim**
- `inTheme`: **card → Theme** (edge `order` is the trail position)
- `instanceOf`: **special case → general case**
- `relatedTo`: undirected (de-duped on the unordered pair)

## The card layer

Every Concept, Mechanism, CaseStudy and Question is a **card**: a page under
`content/{concepts,mechanisms,cases,questions}/`. The ontology owns the
structure; the prose stays prose.

| What | Where it lives | Notes |
|---|---|---|
| One plain sentence (`plain`) | the node's catalog entry in `data/*.json` | ≤ 30 words, no jargon. Becomes the page's `description:` (shown in the properties block), and appears on theme pages and in the viewer. |
| The card body | `content/<type>/<slug>.md`, between `<!-- card -->` and `<!-- /card -->` | Hand-written, ≤ 240 words, example first, ≥ 3 links to other pages. Preserved verbatim by the generator; its links are read back into the graph as edges. |
| Where it is argued in full (`passages`) | catalog entry: `[{ "note", "section" }]` | Must be exact H2 headings; the build validates them, so a renamed section is caught. |
| See-also / special-case links | catalog entry: `related`, `instanceOf`, `derivesFrom` | Typed ids. |
| Home theme + position in its trail | `data/themes.json` | Exactly one theme per card. |
| Everything else on the page | generated | Frontmatter, "Read the full argument", "How it connects", prev/next trail. |

`make concept-pages` also writes the theme pages (`content/themes/`), the two
hubs (`content/explore.md`, `content/reading-path.md`) and a **chapter map**
at the top of every chapter, interlude and depth note (a collapsed list of the
cards on the page, between `<!-- chapter-map:begin … -->` and
`<!-- chapter-map:end -->`). Interludes take their place in the reading path
from `readAfter` / `navTitle` in `data/notes.json`. `make interlink` links the
first use of each card's name in each file (the D2 house rule), using the
catalogs' labels and aliases; steer a node with `"autolink": false` or an
explicit list of terms. It never touches bold spans, so claim anchors stay
stable. `make lint-prose` ignores the generated hubs and chapter maps.

The build warns (and `make check` fails) when a card has no `plain`, no theme,
no written body, fewer than three links out, a passage that points at a
heading that no longer exists, or a term claimed by two cards. The generator
refuses to emit an alias that would shadow a real page, and
`scripts/check-site-links.js` verifies heading anchors and that no note is
shadowed by an alias redirect in the built site.

## Phases landed

Each commit is one logical phase, so reverts have fine resolution.

| Phase | Commit | What landed |
|---|---|---|
| 0 | `0c2681c` | Scaffold: schema, build skeleton, minimal viewer, Makefile |
| 2 | `210aaf6` | Hand-authored catalogs (5 mechanisms, 16 concepts, 7 questions, 5 traditions, 15 sources + 11 authors, 6 case studies) + chapter/note seeds |
| 3 | `439026c` | Claim harvester: regex pass over notes for **bold sentences** + marker phrases ("Where I land", "Working answer") → `claim-candidates.jsonl`. 7 canonical claims promoted with `harvestedFrom` anchors + drift detection |
| 4 | `fe7f6f6` | LLM interpretive extraction: per-PDF subagent over the 4 academic papers in `sources/`. 73 triples (39 evidencedBy, 17 pressureTests, 12 supports). All 7 canonical claims now have source backing — selection-primary is contested 2-4 across all four papers |
| 5 | `e975f30` | Note parser: walks each markdown file, extracts `[[wikilinks]]` (→ `wikiLinks` / `cites` edges), H2 section anchors (as Note props for navigation), with `data/slug-aliases.json` for known mismatches |
| 6 | `9af7525` | Context-bundle exporter: `make context CENTER=<id>` emits a markdown packet of the surrounding neighbourhood, type-aware rendering, full verbatim source quotes, editorial flags |
| 7 | `c240ddb` | Context-bundle drafting-loop improvements: embed draft-note section openings, surface resolved questions, thread case studies into the claims they illustrate |
| 8 | `f4f8e2e` | Catalog gap-fill: 7 concepts the extraction agents flagged + a targeted re-extraction pass over the 4 PDFs for them |
| 9 | `75a6dd7` | Aggregator enforces edge-direction conventions: `supports` / `pressureTests` subject must be a Source; malformed triples dropped with a warning |
| 10 | `61e696a` | Wire `medium-and-manipulation.md` into the graph: seedNotes entry, `question:medium-and-manipulation` flipped to provisionally-resolved, claim `truth-survival-two-conditions` promoted |
| 11 | `6833ad1` | Integrate Hofstadter's three-layer message model (GEB): `source:godel-escher-bach` + `source:ethical-infrastructure-talk`, `tradition:information-theory`, `concept:three-layer-message`, `case:voyager-golden-record`, the `three-layer-message.md` note, two claims; concept loader gains a hand-authored `evidencedBy` field |
| 12 | `3152484` | Wire Chapter 5c (`truth-compression-and-when-each-wins.md`) and the `myths-scale-and-bureaucracy.md` foundational note into the graph |
| 13 | `6dbe9bd` | Reframe selection-primary as the tunable mechanism; draft Chapter 5b (`selection-as-other-engine.md`) |
| 14 | `99e0f0a` | Source-management system: `availability` field on Source nodes splits committed from in-copyright; `sources-local/` gitignored. Postman extraction + three concepts |
| 15 | `606f2f6` | Extract The Misinformation Age; gap-fill its five concepts |
| 16 | `293abe7` | **Merge prose subtree from quartz with history.** Imports `content/` (12 chapter and foundation notes + experiments/ + sources/), three referenced images under `content/images/`, and two citation notes under `content/citations/`. Extracted with `git filter-repo` from a temp clone of the quartz repo, preserving 33 commits of authoring history |
| 17 | `086e5da` | Rewire ontology scripts to read prose from local `content/` (NOTES_DIR change in `build-graph.js`, `harvest-claims.js`, `context-bundle.js`) |
| 18 | `ecdcd8a` | Add Quartz site at `site/` for publishing. Fresh upstream Quartz 4.5.2, `site/content` symlinks to `../content`, `quartz.config.ts` set up for the book. Makefile gains `site-build` / `site-serve` / `site-clean` |
| 19 | `c719a3b` | Rewrite README for the one-repo layout. Three subsystems framing: prose, ontology, publishing site |
| 21 | `8418628` | GitHub Pages deployment. `baseUrl` set to `corpetty.github.io/information-book`; `.github/workflows/deploy-site.yml` builds and deploys on push to `main` when `content/` or `site/` changes _(superseded June 2026 — site moved to the `lossybook.com` custom domain; see **CI & tests** below)_ |
| 22 | `e87c7b9` | Draft Ch9 foundation + skeleton. `content/bridge-nodes-and-versatile-expertise.md` resolves the transferable-vs-specialized question (bridge nodes = deep specialists + paired metacognitive flexibility; the curse of expertise is the cognitive substrate of polarization-via-distrust). `content/integration-problem.md` is the Ch9 skeleton built on it. `source:double-edged-sword-of-expertise`, `concept:versatile-expertise`, `concept:curse-of-expertise`, three claims, and `question:transferable-vs-specialized` flipped to provisionally-resolved |
| 23 | `54485c7` | Sync README and outline with Phase 22 |
| 24 | `6b3af0d` | Accessible landing page (`content/index.md` rewritten), glossary (`content/glossary.md` new with ~25 plain-language definitions), reader's note at the top of the outline |
| 25 | `d5b4128` | Viewer overhaul I: header view tabs (Book overview / Argument map / Source map / Open questions / Drafting status / Full graph), search box, clickable type-filter legend. State serialises to URL hash |
| 26 | `86d516b` | Viewer overhaul II: detail panel becomes readable — summary prose, status badges, working-answer block for resolved Questions, "Read the prose →" link for Note/Chapter, neighbours grouped by predicate with click-to-navigate |
| 27 | `7622326` | Viewer overhaul III: first-load tiled landing with one button per view (each tile shows label + description + live counts). Home button in header returns to landing |
| 28 | `69ed391` | Viewer embedded in Quartz site. `make site-build` chains build-graph → quartz build → viewer-stage (copies `src/` + `data/*.json` into `site/public/{graph,data}/`). Deploy workflow switched from `npx quartz build` to `make site-build`. `content/index.md` and `content/glossary.md` link to the live viewer |

### Phases 29–61 (condensed)

The per-phase table above is no longer maintained line-by-line; `git log
--oneline` is the authority. The major capabilities added since Phase 28:

- **Book drafted out.** Chapters 2, 6, 7, 8, 9, 10, 11, 12 went from skeleton
  to full draft; the book was **retitled "Lossy"** (Phase 58) and gained the
  *The Abyss* companion essay (Phase 59).
- **Dialectical + causal layer.** `data/tensions.json` and the `supersedes` /
  `evidencedBy` / `tensionWith` / `contradicts` edges (Phases 50–53), plus a
  "What's contested" viewer preset. 19 orphan concepts got a `definedIn` home.
- **Citation page generation.** `scripts/generate-citation-pages.js` emits
  `content/citations/*.md` from `sources.json` with computed back-pointers
  (`make citation-pages`).
- **Reader experience.** Sequential prev/next chapter nav (Phase 57), an
  accessible landing page + glossary, reader-inclusion passes across the
  chapters, and Explorer ordering by reading order (Phases 60–61).
- **Source set grew** to 20 sources (Mercier's *Not Born Yesterday*, the
  *Magnifica Humanitas* encyclical, and others) with per-PDF extractions in
  `data/interpretive/` (12 files).

### Audit pass (June 2026)

A repo-wide audit landed several cross-cutting fixes:

- **`make build` made self-contained** — folds in `data/interpretive/*.jsonl`
  directly, so the source-evidence layer (`supports` / `pressureTests` /
  `evidencedBy`) ships on a fresh clone. Bare build went from a partial
  897-edge / 10-warning graph to the full **1051 edges / 0 warnings**; the
  "source unread" false-negative warnings are gone, and in-copyright sources
  no longer warn once extracted.
- **Concept landing pages** — `scripts/generate-concept-pages.js` gives every
  Concept / CaseStudy / Mechanism / Question node a Quartz page (summary +
  graph connections + backlinks), fixing wiki-mode dead links to nodes like
  `justification-market` and `power-posing`.
- **Viewer fixes** — the Chapter-4 "Read the prose →" 404 (filename with
  spaces) and the SPA-router-eats-the-viewer-link bug are fixed.
- **Three reading modes tuned** — reading-order Explorer, an interactive graph
  that no longer collapses into one `information`-tag hub, and a "three ways
  in" entry on the landing page.
- Authorial / prose decisions surfaced by the audit are collected in
  [`PROSE-DECISIONS.md`](PROSE-DECISIONS.md) (flagged, not changed).

## Layout

```
information-book/
├── README.md                          this file
├── Makefile                           dependency-driven build / serve / context targets
├── content/                           PROSE — the book itself
│   ├── index.md                       plain-language landing page (the public face)
│   ├── glossary.md                    plain-language definitions of load-bearing terms
│   ├── outline.md                     working outline / TOC (dense; read after the landing page)
│   ├── *.md                           chapter drafts and foundational notes
│   ├── concepts/ cases/               CARD pages: generated frame, hand-written body
│   │   mechanisms/ questions/         (one folder per type; see "The card layer")
│   ├── themes/                        GENERATED theme pages (ordered trails of cards)
│   ├── explore.md  reading-path.md    GENERATED hubs: all the cards / the chapters in order
│   ├── experiments/                   experiment-tracker notes
│   ├── sources/                       open-licence academic PDFs (cited by the graph)
│   ├── images/                        figures referenced from prose
│   └── citations/                     reference notes for cross-cited sources (part generated)
├── data/                              ONTOLOGY catalogs + outputs
│   ├── graph-meta.json                schema contract — node types + predicates
│   ├── parts.json                     the 4 Parts (labels shared by the graph and the site's navigation)
│   ├── chapters.json                  14 chapters (outline spine; ordinal = reading order)
│   ├── notes.json                     25 tracked markdown notes
│   ├── mechanisms.json                8 named structural mechanisms
│   ├── concepts.json                  58 cross-cutting concepts
│   ├── questions.json                 7 foundational questions (provisionally-resolved / resolved)
│   ├── traditions.json                7 intellectual lineages
│   ├── sources.json                   23 sources + 18 authors
│   ├── case-studies.json              13 worked examples
│   ├── claims.json                    33 canonical claims (promoted from candidates)
│   ├── tensions.json                  3 dialectical tensions (tensionWith / contradicts edges)
│   ├── themes.json                    13 themes: ordered clusters of cards (the exploration layer)
│   ├── slug-aliases.json              wikilink-resolution overrides
│   ├── expected-stats.json            committed snapshot the tests compare against
│   ├── interpretive/<slug>.jsonl      per-PDF extraction outputs (committed)
│   ├── claim-candidates.jsonl         harvester output (gitignored)
│   ├── extraction-catalog.json        generated for agents (gitignored)
│   ├── interpretive-triples.jsonl     aggregated extractions (gitignored)
│   ├── interpretive-notes.json        aggregator warnings + agent notes (gitignored)
│   ├── nodes.jsonl                    generated (gitignored)
│   ├── edges.jsonl                    generated (gitignored)
│   └── build-stats.json               generated (gitignored)
├── scripts/                           ONTOLOGY tooling
│   ├── build-graph.js                 master build — markdown / JSON → triples
│   ├── harvest-claims.js              scan content/ for candidate claims
│   ├── lint-prose.js                  report-only voice / interlink / frontmatter lint
│   ├── build-catalog.js               emit extraction-catalog.json from nodes
│   ├── aggregate-interpretive.js      merge + validate per-PDF JSONLs
│   ├── context-bundle.js              graph → markdown drafting packet
│   ├── sources-report.js              per-source dashboard
│   ├── generate-citation-pages.js     sources.json → content/citations/*.md
│   ├── generate-concept-pages.js      graph → card pages, theme pages, hubs, chapter maps
│   ├── interlink.js                   link the first use of each card in each file
│   ├── check-site-links.js            built-site link, heading-anchor and shadowed-page checks
│   ├── fix-typography.js              post-build smart-quote repair (works around a Quartz 5.1 regression)
│   ├── serve-site.js                  local preview with GitHub Pages URL resolution
│   └── EXTRACTION_PROMPT.md           agent prompt for per-PDF extraction
├── src/                               ONTOLOGY viewer (Cytoscape)
│   ├── index.html                     viewer shell
│   ├── app.js                         Cytoscape wiring + side panel
│   └── styles.css
├── site/                              QUARTZ publishing site
│   ├── quartz.config.yaml             book-specific config and layout (plugins are npm packages)
│   ├── quartz.ts                      loads the YAML; passes the Explorer its reading-order sort,
│   │                                  names and filter, built from data/*.json
│   ├── lossy-nav.tsx                  header bar (ways in, position, continue), sidebar group labels,
│   │                                  theme trail on card pages
│   ├── quartz/styles/custom.scss      page chrome: lead sentence, page-kind colours (ours, not upstream's)
│   ├── quartz.lock.json               pins for Git/local-sourced plugins (none at present)
│   ├── quartz/                        vendored Quartz 5.1 engine (unmodified upstream)
│   ├── content -> ../content          symlink — prose has one canonical home
│   ├── package.json                   site deps
│   ├── public/                        build output (gitignored)
│   └── .quartz-cache/                 build cache (gitignored)
└── sources-local/                     in-copyright source PDFs (gitignored)
```

## Extending

- **New chapter** — add an entry to `data/chapters.json` (slug, part,
  ordinal, number, title, status, optional `draftNote`, summary), then
  `make build`. If it has a draft note, also add it to `data/notes.json`
  and list its slug in `site/quartz.layout.ts`'s reading-order `ORDER`
  (a test enforces that the two stay in sync). Run `make accept-stats`
  to bless the new counts.
- **New note** — add an entry to `data/notes.json` (slug, file, subtype,
  title, role, summary). The file must exist under `content/`; a
  top-level `content/*.md` with no entry triggers an "orphan note"
  warning.
- **New concept / mechanism / question / case study (a card)** — add the
  node to the relevant `data/*.json` with a `plain` sentence, add it to a
  theme's `members` in `data/themes.json`, then `make concept-pages` to
  create its page. Write the body between the `<!-- card -->` markers
  (example first, ≥ 3 links out), then `make interlink`, `make harvest`,
  `make build`. The build's warnings are the checklist.
- **New source** — edit `data/sources.json`, then `make build`. A secondary
  source that relays others (e.g. a research report) lists them in `cites`.
- **New canonical claim** — pick a candidate from
  `data/claim-candidates.jsonl`, write its entry into `data/claims.json`
  (id, label, summary, aliases, status, `argues` / `arguedInChapters`,
  `dependsOn`, `harvestedFrom`), then `make build`.
- **New source PDF** — drop it in `content/sources/` (if open-licence)
  or `sources-local/` (if in-copyright), add an entry to
  `data/sources.json` with the right `availability`, then `make catalog`.
  Run an extraction subagent using `scripts/EXTRACTION_PROMPT.md`; it
  writes to `data/interpretive/<slug>.jsonl`. Then `make extract-build`.
- **New wikilink slug that doesn't resolve** — `make build` will emit
  an "unresolved wikilink" warning; add the slug → graph-id mapping to
  `data/slug-aliases.json`.
- **New node type or predicate** — edit `data/graph-meta.json` (the
  schema contract is enforced by `build-graph.js`), then wire the
  parser / loader in `scripts/build-graph.js`.

## Drift detection

Every `make build` re-reads `data/claim-candidates.jsonl` (if present)
and checks each canonical claim's `harvestedFrom` anchors. If the
anchor text no longer appears in the candidates, the build emits a
`claim drift` warning. Fix by either: (a) re-running `make harvest`
after the prose change so a new candidate exists with matching text, or
(b) updating the claim's `harvestedFrom` to point at the new anchor
location.

`claim-candidates.jsonl` is gitignored, so drift detection is a
**local-only** check: it runs against whatever your last `make harvest`
produced and silently no-ops on a fresh clone / in CI (where the file is
absent). After a prose-editing session, run `make harvest` before
trusting a clean build — a stale candidates file checks claims against
stale prose. CI's `make check` enforces the *structural* invariants
(counts, edge directions, orphans, links); claim-drift stays the
author's local responsibility by design.

## Navigation

The sidebar, breadcrumbs and page headers are driven by the same catalogs as
the graph, so the site's shape follows the book's:

- **Sidebar order** — `site/quartz.ts` builds the Explorer's sort from
  `data/chapters.json` (ordinals), `data/notes.json` (`readAfter` /
  `navTitle` for interludes, `foundational-note` for depth notes) and
  `data/themes.json` (theme order). Start-here pages come first, then the read
  in order, then depth notes, the glossary, and the folders. Adding a chapter
  or an interlude to the catalogs places it; nothing else needs editing.
- **Sidebar groups** — the Explorer is a flat, ordered list; `site/lossy-nav.tsx`
  adds CSS labels on the first entry of each group (Start here, Part I … IV,
  Depth notes, Reference, Browse). Part names come from `data/parts.json`.
- **Header bar** — the same file renders a slim bar above every title: the
  ways in (Read / Explore / Map / Glossary) with the current one marked, and
  where the page sits ("Part II · 6 of 18" for a chapter or interlude; the
  theme and position for a card).
- **Continue** — on pages outside the read, the bar offers "Continue: Chapter
  5b →". The last chapter or interlude visited is remembered in the reader's
  own browser (`localStorage`); nothing is sent anywhere.
- **Theme trail** — on a card page, the top of the right sidebar lists the
  cards of its theme in trail order with the current one marked
  (`ThemeTrail` in `site/lossy-nav.tsx`).
- **Search results** — each result is labelled with its kind (Idea,
  Mechanism, Example, Open question, Theme, Source), read from its slug in
  `site/quartz/styles/custom.scss`.
- **Previous / next** — `make concept-pages` writes the footer on every
  chapter and interlude from the reading order (between
  `<!-- chapter-nav:begin … -->` and `<!-- chapter-nav:end -->`), so the chain
  cannot drift when the order changes.
- **Folder names** — `make concept-pages` writes an `index.md` into each
  content folder so readers see "Ideas", "Examples", "Open questions" and
  "Sources" instead of directory names. A hand-written `index.md` is left alone.
- **Hidden pages** — `unlisted: true` in a page's frontmatter keeps it out of
  the sidebar, search and graph while leaving it reachable by link (the
  outline and the conversation transcript use it).
- **Page header** — the frontmatter `description:` is set as the lead sentence
  and `aliases:` as an "Also called" line; tags are not shown. Ideas,
  mechanisms, examples, open questions, themes and sources each carry the
  accent colour the `/graph/` viewer uses for that node type. All of it is CSS
  keyed on the URL (`site/quartz/styles/custom.scss`); the Markdown carries no
  presentation.

The Explorer serialises its functions and runs them in the browser, so they
are built in `quartz.ts` from source text with the data inlined, and the
override has to be registered before `loadQuartzConfig()` runs. The header bar
is an ordinary build-time component, added through `loadQuartzLayout({ defaults:
{ header: […] } })`; the YAML layout leaves that slot empty.

Cards are not nested under their themes in the left sidebar: the Explorer
mirrors the folder tree, and cards live in one folder per type. The theme
trail on each card page, the theme pages and the Explore hub carry that
structure instead. `quartz.ts` adds the trail by inserting it into the layout
that `loadQuartzLayout()` returns, which is the live layout.

## Upgrading Quartz

`site/` is a vendored, unmodified copy of upstream Quartz inside this repo, so
`npx quartz upgrade` (which pulls from a Git remote) does not apply. To move to
a new release:

1. Clone the release tag of `jackyzha0/quartz` somewhere outside the repo.
2. Replace `site/quartz/` and `site/docs/` with the release's (`rsync -a
   --delete --exclude styles/custom.scss`), and copy its top-level files
   (`package.json`, `package-lock.json`, `quartz.config.default.yaml`,
   `tsconfig.json`, …). Leave the site-specific files alone:
   `site/quartz.config.yaml`, `site/quartz.ts` (the sidebar's reading order),
   `site/lossy-nav.tsx` (the header bar and sidebar labels),
   `site/quartz/styles/custom.scss` (the page chrome), `site/quartz.lock.json`,
   `site/CNAME`, and the `site/content` symlink. Compare `site/quartz.ts`
   against the release's by hand: ours adds to the stock file.
3. `cd site && npm ci`, then `npx quartz plugin doctor` (add `--fix` to let it
   migrate the config) and compare `quartz.config.yaml` against the new
   `quartz.config.default.yaml`.
4. Keep a copy of `site/public/` from before, run `make site-build`,
   `node scripts/check-site-links.js` and `make check`, and diff the rendered
   pages (text, heading ids, link targets) against the copy. The 5.0 → 5.1
   move changed nothing in the page set, anchors or links, but its new
   Markdown parser curled quotes the wrong way next to links; that is what
   `scripts/fix-typography.js` (run by `make site-build`) repairs.

`make site-serve` (Quartz's dev server) does not run the typography repair, so
quotes beside links look wrong there; `make site-build` + `make site-preview`
shows the site as deployed.

## CI & tests

`make test` runs the graph regression suite (golden snapshot in
`data/expected-stats.json` + structural invariants); `make check` adds a
**strict** build where warnings are fatal. After any intentional graph
change, run `make accept-stats` to bless the new snapshot and commit it
alongside. The deploy workflow runs `make check`, then `make site-build`,
then verifies committed generated pages are fresh (`git diff --exit-code
content/`) and every published internal link resolves
(`scripts/check-site-links.js`) — `make site-check` runs those last two
locally.

The site is served from the custom domain **lossybook.com** (apex);
`www.lossybook.com` redirects to it. The domain lives in two places that
must stay in sync: `baseUrl` in `site/quartz.config.ts` (drives canonical
URLs, the sitemap, RSS, and OG images) and `site/CNAME`, which
`make site-build` copies to `site/public/CNAME` so the deployed artifact
claims the domain on GitHub Pages.

## Licence

The tooling — everything under `scripts/`, `src/`, `Makefile`,
`data/*.json` — is MIT (see [`LICENSE`](LICENSE)). The book prose under
`content/` is © Corey Petty, all rights reserved: readable here and on
the published site, but not licensed for reuse or redistribution. Source
PDFs under `content/sources/` are redistributed under their own
open licences and remain the work of their respective authors.
