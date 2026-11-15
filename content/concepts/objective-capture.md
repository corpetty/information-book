---
title: Objective capture
description: "An AI rewarded for pleasing people learns to please rather than to be right, and its output then feeds the next AI's training."
tags:
  - concept
  - graph-node
aliases:
  - RLHF capture
  - reward-signal capture
  - alignment-objective capture
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

*Concept · part of [[ai-as-a-node|AI in the chain]]*

<!-- card -->
Before trusting someone's judgment, you might ask what they were rewarded for. An AI model is trained by scoring its answers and nudging it toward high scores. People rate replies as helpful, harmless or honest, and the model learns whatever those raters were rewarding.

**Objective capture** is the book's name for a reward that drifts from the goal it stands for. The model then scores well on the stand-in and badly on the real thing: agreeable where it should be correct, pleasing where it should be faithful to the source. This is [[goodharts-law|Goodhart's law]] built into a machine. The same pattern shows in [[ai-benchmarks|the benchmarks that steer AI research]]. The book expects a revenue-seeking owner to reward user retention.

The book ranks this the hardest capture to recover from, because it feeds itself. A model's output spreads across the internet, the internet becomes the next model's training text, and the old reward's habits are baked into [[corpus-capture|the next corpus]]. Other captures stay put or can be swapped out. This one compounds across model generations, a case of [[framework-feedback|a framework reshaping the world it reads]]. So the book wants the objective set in the open, ahead of cheaper fixes like [[deployment-capture|configuration]].
<!-- /card -->

## Read the full argument

- [[ai-as-new-node#Three new flavors of capture|Chapter 11: AI as a New Kind of Node]], section "Three new flavors of capture"
- [[capture-taxonomy#Axis 1: which substrate is captured, and how it recovers|Capture Taxonomy]], section "Axis 1: which substrate is captured, and how it recovers"
- [[infrastructure-for-integration#Principle 2: defend consumer-key substrates first|Chapter 12: Infrastructure for Integration]], section "Principle 2: defend consumer-key substrates first"

## How it connects

- **A special case of:** [[goodharts-law|Goodhart's law]]
- **Examples:** [[ai-benchmarks|AI benchmarks as milestones]]
- **See also:** [[capture-taxonomy|Capture taxonomy (substrate × source × target asymmetry)]], [[consumer-key-vs-surface-capture|Consumer-key vs. surface capture]], [[corpus-capture|Corpus capture]], [[deployment-capture|Deployment capture]], [[llm-design-moment-collapse|LLM as collapsed selection-design moment]]
- **Supported by:** [[frameworks-report|Frameworks That Shape the Thoughts Built Inside Them]]
- **Where the book discusses it:** [[ai-as-new-node|Chapter 11: AI as a New Kind of Node]], [[infrastructure-for-integration|Chapter 12: Infrastructure for Integration]], [[capture-taxonomy|Capture Taxonomy]]

---

← [[corpus-capture|Corpus capture]] · [[ai-as-a-node|AI in the chain]] (5 of 7) · [[deployment-capture|Deployment capture]] →

<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>
