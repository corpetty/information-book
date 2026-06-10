---
title: Decompression on demand
tags:
  - concept
  - graph-node
aliases:
  - LLM as decompression service
  - receiver-budget shortcut
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

> **Concept**

An LLM, used as a faithful expansion service, can take a compressed claim or a complex source and re-expand it into a form pre-loaded with the preconditions a receiver needs to decode it. This is the first structural way out of the fixed receiver-budget constraint the book has named: the receiver's budget has not changed, but the amount of complex form they can engage per unit of budget has gone up, because the LLM is paying the decompression cost. Conditional on faithfulness — a hallucinating LLM supplies plausible-but-wrong outer messages, which is worse than no outer message at all.

## Connections

- **Defined in:** [[ai-as-new-node|AI as a New Kind of Node]]
- **Discussed in:** [[ai-as-new-node|Ch 11 — AI as a New Kind of Node]], [[infrastructure-for-integration|Ch 12 — Infrastructure for Integration]], [[preservation-vs-training|Ch 8 — Preservation vs. Training]]
- **Enables:** [[llm-as-capability-extender|LLM as capability extender (inside substrate custody)]]
- **Enabled by:** [[llm-design-moment-collapse|LLM as collapsed selection-design moment]]

<em>This is a graph landing page. Use the local graph and backlinks (right) to explore, or open the <a href="../graph/" data-routerIgnore="true">interactive ontology</a>.</em>

