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
#   make site-build  build the Quartz site from content/ into site/public/
#   make site-serve  build and serve the Quartz site at localhost:8080
#   make site-clean  remove the site build output and cache
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
.PHONY: all build serve stats sources clean help harvest catalog aggregate-interpretive extract-build context site-build site-serve site-clean

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

site-build:
	@cd site && npx quartz build

site-serve:
	@cd site && npx quartz build --serve

site-clean:
	@rm -rf site/public site/.quartz-cache

clean:
	@rm -f $(NODES_OUT) $(EDGES_OUT) $(STATS_OUT)

help:
	@awk '/^# / { sub(/^# ?/, ""); print } /^[a-zA-Z_-]+:/ && !/^\..*$$/ { sub(/:.*$$/, ""); print "  → " $$0 }' Makefile
