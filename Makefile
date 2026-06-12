# Information-book ontology — semantic-triple graph
#
# `make` (default = `make build`) rebuilds the graph from data/graph-meta.json
# and the parsers/seeds in scripts/build-graph.js.
#
# Quick reference:
#   make           rebuild graph
#   make serve     build then serve viewer at localhost:$(PORT)
#   make stats     print build counts
#   make sources   print the per-source catalog dashboard
#   make harvest   scan content/ for candidate claims
#   make catalog   regenerate extraction-catalog.json from current graph
#   make aggregate-interpretive   merge per-PDF extractions
#   make extract-build   aggregate + rebuild (run after extraction agents)
#   make context CENTER=<id>   emit a markdown context bundle for a node
#   make citation-pages  regenerate content/citations/*.md from data/sources.json
#   make concept-pages   regenerate content/{concepts,cases,mechanisms,questions}/*.md from the graph
#   make site-build  rebuild graph + citation pages + Quartz site + stage viewer at /graph/
#   make site-serve  build and serve the Quartz site at localhost:8080
#   make site-clean  remove the site build output and cache
#   make viewer-stage  copy src/ + data/*.json into site/public/{graph,data}
#   make test      run the graph regression tests (snapshot + invariants)
#   make check     strict build (warnings fatal) + tests — what CI gates on
#   make accept-stats  refresh data/expected-stats.json after an intentional graph change
#   make clean     remove generated artifacts
#   make help      list targets

PORT ?= 8765

DATA    := data
SCRIPTS := scripts

NODES_OUT := $(DATA)/nodes.jsonl
EDGES_OUT := $(DATA)/edges.jsonl
STATS_OUT := $(DATA)/build-stats.json

CATALOGS := $(DATA)/mechanisms.json $(DATA)/concepts.json $(DATA)/questions.json \
            $(DATA)/traditions.json $(DATA)/sources.json $(DATA)/case-studies.json \
            $(DATA)/slug-aliases.json

.DEFAULT_GOAL := all
.PHONY: all build serve stats sources clean help harvest catalog aggregate-interpretive extract-build context citation-pages concept-pages site-build site-serve site-clean viewer-stage test check accept-stats

all: build

# build-graph.js is fast (sub-second) — always run it rather than tracking
# file staleness. Guarantees the graph reflects every input on every
# invocation: catalogs, interpretive-triples.jsonl, and the prose
# the note parser reads. (Staleness tracking previously skipped rebuilds
# after `make aggregate-interpretive` rewrote interpretive-triples.jsonl.)
build:
	@node $(SCRIPTS)/build-graph.js

serve: build
	@echo "Serving at http://localhost:$(PORT)/src/"
	@python3 -m http.server $(PORT)

stats: build
	@cat $(STATS_OUT)

# Regression tests: golden snapshot (counts vs data/expected-stats.json)
# plus structural invariants. The test file runs the build itself.
test:
	@node --test $(SCRIPTS)/*.test.js

# What CI runs before building the site: a strict build (warnings are
# fatal) plus the regression tests. Local `make build` stays lenient.
check:
	@STRICT=1 node $(SCRIPTS)/build-graph.js
	@node --test $(SCRIPTS)/*.test.js

# After an INTENTIONAL graph change (new claim, concept, edge, …), refresh
# the committed snapshot the tests compare against. Commit it with the change.
accept-stats: build
	@node -e "const fs=require('node:fs');const s=JSON.parse(fs.readFileSync('$(STATS_OUT)','utf8'));delete s.builtAt;fs.writeFileSync('$(DATA)/expected-stats.json',JSON.stringify(s,null,2)+'\n');console.log('expected-stats.json accepted:',JSON.stringify(s.counts))"

sources: build
	@node $(SCRIPTS)/sources-report.js

harvest:
	@node $(SCRIPTS)/harvest-claims.js

catalog: build
	@node $(SCRIPTS)/build-catalog.js

aggregate-interpretive: catalog
	@node $(SCRIPTS)/aggregate-interpretive.js

# Aggregate per-PDF extractions, then rebuild so the graph picks up the
# fresh interpretive triples.
extract-build: aggregate-interpretive
	@node $(SCRIPTS)/build-graph.js

context: build
	@node $(SCRIPTS)/context-bundle.js --center=$(CENTER) $(ARGS)

# Copy the viewer files + the current graph data into the Quartz build
# output. The viewer lives at site/public/graph/, the data at site/public/data/.
# The viewer fetches via ../data, so the paths line up under the published
# /graph/ subpath. Idempotent; depends on site/public/ existing.
viewer-stage:
	@mkdir -p site/public/graph site/public/data
	@cp src/index.html src/app.js src/styles.css site/public/graph/
	@cp data/graph-meta.json data/nodes.jsonl data/edges.jsonl site/public/data/

# Regenerate citation pages from data/sources.json. Idempotent — files
# carrying the generator marker get overwritten, hand-written ones are
# left alone. Depends on `build` so the back-pointer pass can read
# fresh edges from data/edges.jsonl.
citation-pages: build
	@node $(SCRIPTS)/generate-citation-pages.js

# Regenerate landing pages for concept / case / mechanism / question nodes
# that have no prose page of their own. Idempotent (generator marker), and
# hand-written overrides are left alone. Depends on `build` so it reads fresh
# nodes/edges. These pages are committed (part of content/).
concept-pages: build
	@node $(SCRIPTS)/generate-concept-pages.js

# Full site build: rebuild the graph (so the data the viewer ships is fresh),
# regenerate citation + concept landing pages, build the Quartz output,
# then stage the viewer on top. This is what CI runs.
site-build: citation-pages concept-pages
	@cd site && npx quartz build
	@$(MAKE) viewer-stage

# Quartz dev server (hot-reloads prose). Note: subsequent rebuilds wipe
# site/public, so the staged viewer won't survive here — use `make serve`
# for viewer-only dev, or `make site-build` then a static server for the
# integrated experience.
site-serve:
	@cd site && npx quartz build --serve

site-clean:
	@rm -rf site/public site/.quartz-cache

clean:
	@rm -f $(NODES_OUT) $(EDGES_OUT) $(STATS_OUT) \
	       $(DATA)/extraction-catalog.json $(DATA)/interpretive-triples.jsonl \
	       $(DATA)/interpretive-notes.json $(DATA)/claim-candidates.jsonl

help:
	@awk '/^# / { sub(/^# ?/, ""); print } /^[a-zA-Z_-]+:/ && !/^\..*$$/ { sub(/:.*$$/, ""); print "  → " $$0 }' Makefile
