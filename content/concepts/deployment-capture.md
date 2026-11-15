---
title: Deployment capture
description: "The company running an AI can change how it answers with hidden instructions, without retraining it and without users seeing the change."
tags:
  - concept
  - graph-node
aliases:
  - inference-time capture
  - system-prompt capture
  - post-training capture
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

*Concept · part of [[ai-as-a-node|AI in the chain]]*

<!-- card -->
Before trusting someone's advice, you might ask who is whispering in their ear right now. An AI chatbot usually runs under instructions you never see: a hidden prompt from the company operating it, rules about what to refuse, limits on which tools it may use.

**Deployment capture** is the book's name for tilting a model at this last stage. Nothing about the model changes. The same trained system is steered differently, request by request. Research on [[prompt-format-sensitivity|prompt formatting]] shows how far the wrapper around a question can move the output, and here the operator writes the wrapper. Its settings are the [[default-setting|defaults]] every user gets without choosing, and the book expects a commercial operator to tune them for its revenue.

The book rates this the cheapest capture and the easiest to reverse: a new prompt can fix it in minutes, if the operator wants to. Unlike [[corpus-capture|slanted training data]] or a [[objective-capture|slanted reward]], it [[consumer-key-vs-surface-capture|shapes a surface and leaves the model alone]]. Its weakness is secrecy. Configurations are rarely published and can change silently between requests, so it is auditable in principle and opaque in practice. That is why the book's [[llm-as-capability-extender|institution-run model]] keeps deployment in the institution's hands.
<!-- /card -->

## Read the full argument

- [[ai-as-new-node#Three new flavors of capture|Chapter 11: AI as a New Kind of Node]], section "Three new flavors of capture"
- [[capture-taxonomy#Axis 1: which substrate is captured, and how it recovers|Capture Taxonomy]], section "Axis 1: which substrate is captured, and how it recovers"

## How it connects

- **Examples:** [[prompt-format-sensitivity|Prompt formatting and the 76-point swing]]
- **See also:** [[consumer-key-vs-surface-capture|Consumer-key vs. surface capture]], [[corpus-capture|Corpus capture]], [[default-setting|Defaults]], [[llm-design-moment-collapse|LLM as collapsed selection-design moment]], [[objective-capture|Objective capture]]
- **Supported by:** [[frameworks-report|Frameworks That Shape the Thoughts Built Inside Them]]
- **Where the book discusses it:** [[ai-as-new-node|Chapter 11: AI as a New Kind of Node]], [[infrastructure-for-integration|Chapter 12: Infrastructure for Integration]], [[capture-taxonomy|Capture Taxonomy]]

---

← [[objective-capture|Objective capture]] · [[ai-as-a-node|AI in the chain]] (6 of 7) · [[llm-as-capability-extender|LLM as capability extender (inside substrate custody)]] →

<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>
