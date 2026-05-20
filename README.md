# Information book · semantic-triple ontology

Authoring graph for the information book — chapters, mechanisms,
concepts, open questions, claims, sources, and the edges between them.
Modeled on the [Logos whitepaper graph](../../logos-co/logos-whitepaper/graph/)
but reshaped around the book's argument structure.

The graph is the **authoring tool**, not the prose. The prose lives in
quartz and gets edited there; the ontology surfaces what the prose
implies — claims to make, sources backing them, questions still open,
chapters with missing anchors — and bundles it into context packets
ready to drop into a drafting prompt.

## Where things live

| Path | Role |
|---|---|
| `../quartz/content/notes/information-book/` | **Prose** — the book's outline, chapter drafts, foundational notes, conversation transcripts, and the `sources/` PDFs. Edited here. Reference-only from this repo. |
| `../../logos-co/logos-whitepaper/graph/` | **Reference implementation** of the graph design. Read for patterns; don't modify. |
| `data/` here | **Hand-authored catalogs** (mechanisms, concepts, questions, traditions, sources, case studies, claims, slug-aliases) plus build outputs. |
| `scripts/` here | **Build, harvest, extract, aggregate, context-bundle** tooling. Plain Node 18+, no bundler. |
| `src/` here | **Cytoscape viewer**. Plain ES modules, Cytoscape from CDN. |

## Run it

```bash
make                                              # rebuild graph (default = make build)
make serve                                        # serve viewer at localhost:8765/src/
make stats                                        # counts + warnings from last build
make harvest                                      # rescan quartz notes for candidate claims
make catalog                                      # regenerate extraction-catalog.json for agents
make aggregate-interpretive                       # merge per-PDF extractions into one JSONL
make extract-build                                # aggregate + rebuild (after running extraction agents)
make context CENTER=chapter:<slug>                # emit drafting bundle to stdout
make context CENTER=claim:<slug> ARGS="-o foo.md" # write bundle to file
make help                                         # list targets
```

Current state: **122 nodes / 354 edges / 0 warnings**.

## The drafting loop

This is what the tool is for. The graph exists to make this loop tight.

1. **Generate a context bundle** for the chapter you want to draft:
   ```bash
   make context CENTER=chapter:selection-as-other-engine -o /tmp/c5b.md
   ```
   Output (~20-25 KB / ~5,000-6,000 tokens) contains the chapter's
   summary, every claim it argues with full verbatim source quotes
   (supports + pressure-tests with page numbers, confidence, rationale),
   open questions still blocking it, anchored mechanisms / concepts /
   case studies, related notes, and editorial flags (drafting status,
   contested claims, source-backing gaps).

2. **Paste into a fresh Claude session** and start drafting against it.
   The bundle is self-contained — every claim has its evidence inline.

3. **As prose accumulates**, edit the chapter's backing note in
   `quartz/content/notes/information-book/`.

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

**15 node types**, grouped by role:

- **Outline scaffolding**: `Part`, `Chapter`, `Note`, `Status`
- **Pipeline model**: `PipelineStage`, `Gate` (from
  `the-information-landscape.md`)
- **Argument layer**: `Mechanism`, `Concept`, `Question`, `Claim`,
  `Tension`
- **Source layer**: `Source`, `Author`, `Tradition`
- **Illustration**: `CaseStudy`

**26 predicates** in 6 categories:

- **structural** — `partOf`, `covers`, `definedIn`, `succeedsStage`,
  `gateFor`, `hasStatus`, `representedBy`
- **causal** — `derivesFrom`, `enables`, `precondition`, `compresses`,
  `selectsFor`
- **provenance** — `cites`, `authoredBy`, `partOfTradition`,
  `evidencedBy`
- **dialectical** — `tensionWith`, `contradicts`, `supersedes`,
  `flagsOpenQuestion`
- **claim** — `argues`, `supports`, `pressureTests`, `dependsOn`
- **weak** — `mentions`, `wikiLinks`

**Direction conventions worth memorising:**

- `supports` / `pressureTests`: **Source → Claim**
- `evidencedBy`: **Concept/Mechanism/Claim → Source** (reversed)
- `argues`: **Chapter or Note → Claim**
- `covers`: **Chapter → Concept/Mechanism/Question/Claim/CaseStudy**

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
| 10 | `(this commit)` | Wire `medium-and-manipulation.md` into the graph: seedNotes entry, `question:medium-and-manipulation` flipped to provisionally-resolved, claim `truth-survival-two-conditions` promoted |

## Layout

```
info-book-ontology/
├── README.md                          this file
├── Makefile                           dependency-driven build / serve / context targets
├── data/
│   ├── graph-meta.json                schema contract — node types + predicates
│   ├── mechanisms.json                5 named structural mechanisms
│   ├── concepts.json                  23 cross-cutting concepts
│   ├── questions.json                 7 foundational questions (open / provisionally-resolved / resolved)
│   ├── traditions.json                5 intellectual lineages
│   ├── sources.json                   15 sources + 11 authors
│   ├── case-studies.json              6 worked examples
│   ├── claims.json                    canonical claims (promoted from candidates)
│   ├── slug-aliases.json              wikilink-resolution overrides
│   ├── interpretive/<slug>.jsonl      per-PDF extraction outputs (8 files: 4 main + 4 gap, committed)
│   ├── claim-candidates.jsonl         harvester output (gitignored)
│   ├── extraction-catalog.json        generated for agents (gitignored)
│   ├── interpretive-triples.jsonl     aggregated extractions (gitignored)
│   ├── interpretive-notes.json        aggregator warnings + agent notes (gitignored)
│   ├── nodes.jsonl                    generated (gitignored)
│   ├── edges.jsonl                    generated (gitignored)
│   └── build-stats.json               generated (gitignored)
├── scripts/
│   ├── build-graph.js                 master build — markdown / JSON → triples
│   ├── harvest-claims.js              scan notes for candidate claims
│   ├── build-catalog.js               emit extraction-catalog.json from nodes
│   ├── aggregate-interpretive.js      merge + validate per-PDF JSONLs
│   ├── context-bundle.js              graph → markdown drafting packet
│   └── EXTRACTION_PROMPT.md           agent prompt for per-PDF extraction
└── src/
    ├── index.html                     viewer shell
    ├── app.js                         Cytoscape wiring + side panel
    └── styles.css
```

## Extending

- **New concept / mechanism / question / source / case study** — edit
  the relevant `data/*.json`, then `make build`. Aliases drive future
  alias-matching (planned).
- **New canonical claim** — pick a candidate from
  `data/claim-candidates.jsonl`, write its entry into `data/claims.json`
  (id, label, summary, aliases, status, `argues` / `arguedInChapters`,
  `dependsOn`, `harvestedFrom`), then `make build`.
- **New source PDF** — drop it in
  `quartz/content/notes/information-book/sources/`, add an entry to
  `data/sources.json`, then `make catalog`. Run an extraction subagent
  using `scripts/EXTRACTION_PROMPT.md`; it writes to
  `data/interpretive/<slug>.jsonl`. Then `make extract-build`.
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
