---
title: Corpus capture
description: "An AI trained on a lopsided selection of text gives lopsided answers, however carefully it is handled afterward."
tags:
  - concept
  - graph-node
aliases:
  - training-corpus capture
  - training-set selection
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

*Concept · part of [[ai-as-a-node|AI in the chain]]*

<!-- card -->
Before trusting someone's judgment, you might ask what they were raised on. The book asks the same of an AI model. Its answers are built from the text it was trained on, and somebody chose that text: what went in, in what proportions, with what filtered out.

**Corpus capture** is the book's name for a training set tilted against faithfulness: one tradition over-represented, its critics thinned out, inconvenient evidence missing. No learner can generalize without [[inductive-bias|starting assumptions]], and for a language model the training text supplies many of them. Careful handling afterward cannot restore what the model never saw. The tilt also reaches the reader. People lean on the model for the background needed to interpret a field, so the slanted background arrives inside every answer.

The book files this as [[consumer-key-vs-surface-capture|damage to the reader's own equipment]], which is slow to undo: the fix is retraining on different text, the most expensive step in building a model. The book expects a revenue-seeking owner to default to a cheap web scrape, biases included. Its sibling problems are [[objective-capture|what the model was rewarded for]] and [[deployment-capture|how it is configured]]. The proposed defense is an [[llm-as-capability-extender|institution holding its own published corpus]].
<!-- /card -->

## Read the full argument

- [[ai-as-new-node#Three new flavors of capture|Chapter 11: AI as a New Kind of Node]], section "Three new flavors of capture"
- [[capture-taxonomy#Axis 1: which substrate is captured, and how it recovers|Capture Taxonomy]], section "Axis 1: which substrate is captured, and how it recovers"
- [[infrastructure-for-integration#Principle 2: defend consumer-key substrates first|Chapter 12: Infrastructure for Integration]], section "Principle 2: defend consumer-key substrates first"

## How it connects

- **See also:** [[capture-taxonomy|Capture taxonomy (substrate × source × target asymmetry)]], [[consumer-key-vs-surface-capture|Consumer-key vs. surface capture]], [[deployment-capture|Deployment capture]], [[inductive-bias|Inductive bias]], [[llm-as-capability-extender|LLM as capability extender (inside substrate custody)]], [[llm-design-moment-collapse|LLM as collapsed selection-design moment]], [[objective-capture|Objective capture]]
- **Where the book discusses it:** [[ai-as-new-node|Chapter 11: AI as a New Kind of Node]], [[infrastructure-for-integration|Chapter 12: Infrastructure for Integration]], [[capture-taxonomy|Capture Taxonomy]]

---

← [[compressed-form-as-authority|Compressed form becoming authoritative]] · [[ai-as-a-node|AI in the chain]] (4 of 7) · [[objective-capture|Objective capture]] →

<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>
