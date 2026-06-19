---
title: Deployment capture
tags:
  - concept
  - graph-node
aliases:
  - inference-time capture
  - system-prompt capture
  - post-training capture
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

> **Concept**

Capture of an LLM at inference time through system prompts, fine-tunes, distillations, refusal policies, and tool-use constraints. The cheapest of the LLM capture surfaces because it changes nothing about the model — same weights, used differently per request — and per the capture-taxonomy a surface capture rather than a consumer-key capture. Most opaque in practice because the configurations are typically not published and can change silently between requests.

## Connections

- **Defined in:** [[capture-taxonomy|Capture Taxonomy]]
- **Discussed in:** [[ai-as-new-node|Ch 11 — AI as a New Kind of Node]], [[infrastructure-for-integration|Ch 12 — Infrastructure for Integration]]

<em>This is a graph landing page. Use the local graph and backlinks (right) to explore, or open the <a href="../graph/" data-router-ignore="true">interactive ontology</a>.</em>

