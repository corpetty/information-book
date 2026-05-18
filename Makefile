# Information-book ontology — semantic-triple graph
#
# `make` (default = `make build`) rebuilds the graph from data/graph-meta.json
# and the parsers/seeds in scripts/build-graph.js.
#
# Quick reference:
#   make           rebuild graph
#   make serve     build then serve viewer at localhost:$(PORT)
#   make stats     print build counts
#   make harvest   scan quartz notes for candidate claims
#   make clean     remove generated artifacts
#   make help      list targets

PORT ?= 8765

DATA    := data
SCRIPTS := scripts

NODES_OUT := $(DATA)/nodes.jsonl
EDGES_OUT := $(DATA)/edges.jsonl
STATS_OUT := $(DATA)/build-stats.json

CATALOGS := $(DATA)/mechanisms.json $(DATA)/concepts.json $(DATA)/questions.json \
            $(DATA)/traditions.json $(DATA)/sources.json $(DATA)/case-studies.json

.DEFAULT_GOAL := all
.PHONY: all build serve stats clean help harvest

all: $(NODES_OUT)
build: $(NODES_OUT)

$(NODES_OUT) $(EDGES_OUT) $(STATS_OUT) &: $(SCRIPTS)/build-graph.js $(DATA)/graph-meta.json $(CATALOGS)
	@node $(SCRIPTS)/build-graph.js

serve: $(NODES_OUT)
	@echo "Serving at http://localhost:$(PORT)/src/"
	@python3 -m http.server $(PORT)

stats: $(STATS_OUT)
	@cat $(STATS_OUT)

harvest:
	@node $(SCRIPTS)/harvest-claims.js

clean:
	@rm -f $(NODES_OUT) $(EDGES_OUT) $(STATS_OUT)

help:
	@awk '/^# / { sub(/^# ?/, ""); print } /^[a-zA-Z_-]+:/ && !/^\..*$$/ { sub(/:.*$$/, ""); print "  → " $$0 }' Makefile
