---
title: Compressed form becoming authoritative
tags:
  - concept
  - graph-node
aliases:
  - LLM compression as substitution
  - authoritative compression
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

> **Concept**

The inverse failure mode of decompression-on-demand: at scale, the LLM-compressed summary of a source substitutes for the source itself in the network's working memory, with the LLM's authority backing the compressed version. The original is technically still there; nobody reads it. The summary is technically not the original; everybody reads it. Compression becomes substitution rather than abstraction — the receiver does not in practice go back and check, because the compressed form arrived with epistemic credentials no prior compression had.

## Connections

- **Defined in:** [[ai-as-new-node|AI as a New Kind of Node]]
- **Discussed in:** [[ai-as-new-node|Ch 11 — AI as a New Kind of Node]], [[truth-compression-and-when-each-wins|Ch 5c — Truth, Compression, and When Each Wins]]
- **Enabled by:** [[llm-design-moment-collapse|LLM as collapsed selection-design moment]]

<em>This is a graph landing page. Use the local graph and backlinks (right) to explore, or open the <a href="../graph/" data-routerIgnore="true">interactive ontology</a>.</em>

