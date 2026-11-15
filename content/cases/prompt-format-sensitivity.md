---
title: Prompt formatting and the 76-point swing
description: "Changing only spacing, separators or capital letters in the wording given to an AI model moved its test accuracy by as much as 76 points."
tags:
  - case-study
  - graph-node
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

*Example · part of [[frameworks|Thinking inside frameworks]]*

<!-- card -->
Take a test question for an AI language model and change only its layout: a different separator, different spacing, a capital letter. The meaning stays the same. Sclar, Choi, Tsvetkov and Suhr (2024) did this across more than 50 tasks with several widely used open-source models. For one model, LLaMA-2-13B, accuracy differed by up to 76 points between formats. The median spread was 7.5 points.

How well a format worked on one model only weakly predicted how it worked on another, which undermines comparisons made with a single, arbitrarily chosen format. The sensitivity also persisted with larger models, more examples in the prompt, and instruction tuning.

A prompt format is a [[default-setting|default]] nobody thinks of as a choice, and this is [[framework-pricing|framework pricing]] measured in a machine. The book calls steering a model through its prompts and settings, with the model itself unchanged, [[deployment-capture|deployment capture]], one of the [[llm-design-moment-collapse|many design choices an AI owner holds at once]]. The authors' advice is a form of [[framework-rotation|framework rotation]]: report a range across plausible formats.

The tests were few-shot tasks on open-source models, and 76 points is the largest gap found.
<!-- /card -->

**How solid is this?** A direct measurement across 50+ tasks and several open-source models in few-shot settings; the 76-point figure is the maximum for one model, against a median spread of 7.5 points.

## Read the full argument

- [[thinking-inside-frameworks#The clearest case is a machine|Thinking Inside Frameworks]], section "The clearest case is a machine"

## How it connects

- **What it shows:** [[default-setting|Defaults]], [[deployment-capture|Deployment capture]], [[framework-pricing|Framework pricing]], [[framework-rotation|Framework rotation]]
- **See also:** [[ai-benchmarks|AI benchmarks as milestones]], [[inductive-bias|Inductive bias]]
- **Evidence:** [[frameworks-report|Frameworks That Shape the Thoughts Built Inside Them]], [[quantifying-prompt-sensitivity|Quantifying Language Models' Sensitivity to Spurious Features in Prompt Design]]
- **Where the book discusses it:** [[ai-as-new-node|Chapter 11: AI as a New Kind of Node]], [[thinking-inside-frameworks|Thinking Inside Frameworks]]

---

← [[inductive-bias|Inductive bias]] · [[frameworks|Thinking inside frameworks]] (21 of 21)

<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>
