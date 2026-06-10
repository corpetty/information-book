---
title: Objective capture
tags:
  - concept
  - graph-node
aliases:
  - RLHF capture
  - reward-signal capture
  - alignment-objective capture
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

> **Concept**

Capture of an LLM by the training objective (loss function, RLHF reward signal). A captured objective produces outputs that score well on the captured proxy and badly on whatever the actual desideratum was. Uniquely bad in the capture-taxonomy because it self-reinforces across model generations — the model's outputs go on to influence what data is generated downstream (the internet itself), which then feeds the next model's training corpus, baking the captured objective's effects across model generations. The substrate with the worst recovery dynamics in the book.

## Connections

- **Defined in:** [[capture-taxonomy|Capture Taxonomy]]
- **Discussed in:** [[ai-as-new-node|Ch 11 — AI as a New Kind of Node]], [[infrastructure-for-integration|Ch 12 — Infrastructure for Integration]]

<em>This is a graph landing page. Use the local graph and backlinks (right) to explore, or open the <a href="../graph/" data-routerIgnore="true">interactive ontology</a>.</em>

