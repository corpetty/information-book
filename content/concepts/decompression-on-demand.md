---
title: Decompression on demand
description: "An AI can unpack a dense paper into an explanation fitted to what you already know, as long as it stays faithful to the source."
tags:
  - concept
  - graph-node
aliases:
  - LLM as decompression service
  - receiver-budget shortcut
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

*Concept · part of [[ai-as-a-node|AI in the chain]]*

<!-- card -->
You open a peer-reviewed paper and stall on the second paragraph. The methods assume training you never had. You ask an AI model to expand it: define the terms, explain the method, chase the references, pitch it at what you already know.

The book calls this **decompression on demand**. Most of the book is about ideas being squeezed into a [[compressed-form|short, easy version]] that drops the instructions for reading them. This runs the other way: the [[complex-form|full version]] is unpacked to fit one reader. Your [[receiver-budget|hours of attention]] stay the same, yet each hour reaches further, because the model pays the unpacking cost you could not. The book calls it the first structural way out of that limit: a patient tutor at any scale.

Two conditions hold it back. The model has to be faithful. A made-up explanation hands you confident reading instructions that do not match the source, which the book judges worse than none. And the same tool will as readily shrink the paper to three bullets, the [[compressed-form-as-authority|summary that replaces the original]]. Which use wins depends on what the owner's business rewards, so the book's hopeful version is an [[llm-as-capability-extender|institution running its own model]].
<!-- /card -->

## Read the full argument

- [[ai-as-new-node#The receiver-budget shortcut|Chapter 11: AI as a New Kind of Node]], section "The receiver-budget shortcut"

## How it connects

- **Builds on:** [[llm-design-moment-collapse|LLM as collapsed selection-design moment]]
- **Leads to:** [[llm-as-capability-extender|LLM as capability extender (inside substrate custody)]]
- **See also:** [[budget-fixed-or-trainable|Are receiver budgets fixed or trainable?]], [[compressed-form-as-authority|Compressed form becoming authoritative]], [[receiver-budget|Receiver budget]]
- **Where the book discusses it:** [[preservation-vs-training|Chapter 8: Preservation vs. Training]], [[ai-as-new-node|Chapter 11: AI as a New Kind of Node]], [[infrastructure-for-integration|Chapter 12: Infrastructure for Integration]]

---

← [[llm-design-moment-collapse|LLM as collapsed selection-design moment]] · [[ai-as-a-node|AI in the chain]] (2 of 7) · [[compressed-form-as-authority|Compressed form becoming authoritative]] →

<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>
