---
title: Inductive bias
description: "A system that learns from examples has to make assumptions that go beyond those examples, and the assumptions shape everything it concludes."
tags:
  - concept
  - graph-node
aliases:
  - inductive biases
  - tokenization
---

<!-- generated from the ontology graph — edit the node in data/*.json and rebuild, or replace this file with hand-written prose (delete this comment) to override -->

*Concept · part of [[frameworks|Thinking inside frameworks]]*

<!-- card -->
Show a child three dogs and she can spot a fourth. To do that she had to assume something the three dogs did not strictly prove: that fur, four legs and a bark matter, and that the color of the carpet they stood on does not. Learning from examples is impossible without assumptions of that kind.

Machine-learning researchers call these assumptions **inductive bias**. Every learning system has them. An image model assumes that nearby pixels belong together. A language model reasons over whatever units its text was chopped into, which is why irregular chunking makes arithmetic harder for it, much as Roman numerals did for people ([[notation-as-tool-of-thought]]).

This is the one field that treats a [[framework]]'s bias as unavoidable and chooses it on purpose, the attitude the book recommends everywhere else. It is also the field that has shown most clearly how fast unexamined frameworks take over. A model's answers can swing wildly with the formatting of the question ([[prompt-format-sensitivity]]), and a few test suites steer what the whole field builds ([[ai-benchmarks]]). In the book's account of AI these are dials the model's builder controls ([[llm-design-moment-collapse|one owner, every dial]]).
<!-- /card -->

## Read the full argument

- [[thinking-inside-frameworks#A framework is a medium you think in|Thinking Inside Frameworks]], section "A framework is a medium you think in"
- [[thinking-inside-frameworks#The clearest case is a machine|Thinking Inside Frameworks]], section "The clearest case is a machine"

## How it connects

- **See also:** [[ai-benchmarks|AI benchmarks as milestones]], [[corpus-capture|Corpus capture]], [[llm-design-moment-collapse|LLM as collapsed selection-design moment]], [[notation-as-tool-of-thought|Notation as a tool of thought]], [[prompt-format-sensitivity|Prompt formatting and the 76-point swing]]
- **Evidence:** [[frameworks-report|Frameworks That Shape the Thoughts Built Inside Them]]
- **Where the book discusses it:** [[ai-as-new-node|Chapter 11: AI as a New Kind of Node]], [[thinking-inside-frameworks|Thinking Inside Frameworks]]

---

← [[law-of-the-instrument|Law of the instrument]] · [[frameworks|Thinking inside frameworks]] (20 of 21) · [[prompt-format-sensitivity|Prompt formatting and the 76-point swing]] →

<em>[[explore|Explore all the ideas]] · [[reading-path|Read the book in order]] · <a href="../graph/" data-router-ignore="true">Open the interactive map</a></em>
