# Audit: `content/capture-taxonomy.md` (3,530 words)

## 1. Argument

**Thesis (mine):** Capture is one mechanism (tuning a selection-design surface against what it was supposed to serve) that varies along three axes: which surface, who does it (outsider, the institution itself, or an outsider riding the institution's own gradient), and how recoverable the damage is (surfaces that install keys in people are worst; a captured training objective is worst of all because it feeds the next model's data).

**Does it earn it?** As a reference document, mostly. The definition (L15) and the two principles (consumer-key vs. surface, L61; objective self-reinforces, L63) are earned. The recovery hierarchy (L59) is asserted ordinal with no evidence, which L105 admits. The composition rules (L65–79) are the most speculative section and read as engineering notes. L81–97 restate the whole note twice (a 130-word bold paragraph at L83, then per-chapter bullets), and every "what this changes" item is already done in the chapters (`political-economy-of-attention.md:61`, `ai-as-new-node.md:69`, `infrastructure-for-integration.md:19,59,67`).

**The single biggest defect is one word.** "Substrate" appears **58 times**. Beyond the density, the term collides head-on with `medium-and-manipulation.md:11` ("The medium is not the substrate"), where *substrate* means the physical carrier the medium is *not*, and with `glossary.md:29`. Here it means a selection-design surface. Two foundational notes give one word opposite referents. The note's own definition at L13 uses "surface"; rename throughout.

**Depends on terms the reader doesn't have:** *desideratum* (L13, L15: jargon; "what it was for"), *gradient* (L39, L43, L69: unexplained metaphor), *selection-design surface* (L13, glossary-only), *credibly neutral* (implied L41).

**Single most valuable change:** rename substrate → surface; cut to definition, three axes, a seven-row table (surface / who owns it / what it damages / how it recovers), and the two principles in bold; move L65–79 to an appendix or cut; delete L81–97. ~1,500 words. Then see the structure file for where it goes.

## 2. Voice

**(a) Self-narration.** "Chapter N/Ch N" ×42 (the highest of the seven), "the book" ×22, "this note/the note" ×7, "this chapter/the chapter" ×4. Worst 8: L7 "By the time the book reached Chapter 11 it was naming capture in three different vocabularies across three different chapters and the vocabularies had stopped agreeing … This note unifies it."; L9 "The unification is straightforward, which is part of why it has been waiting"; L13 "The substitution is faithful to medium-and-manipulation's original definition and lets the same word carry across the book's three chapters"; L19 "The book has named seven so far, across three chapters"; L41 "The asymmetry the book has been carrying in different vocabularies, said plainly"; L61 "Some structural results fall out of the hierarchy that the per-chapter treatments did not show"; L85 "This subsumes the book's three earlier capture stories without contradiction"; L95 "Ch 11 should cross-reference and downgrade the 'needs unification in a forthcoming note' deferrals that this note discharges."

**(b) Reversals (~9).** Worst 6: L29 "capture is not a single thing per chapter but a *site*"; L41 "You can defeat a captor; you cannot defeat an equilibrium." (good; keep); L43 "not because they are cleverer"; L61 "it is not that 'training capture is worse than preservation capture' in general; it is that *consumer-key captures are worse than surface captures*"; L71 "not two independent problems"; L109 "a negative theory … not a positive theory."

**(c) Triads / cascades / parentheticals.** L13 seven-item parenthetical list of surfaces; L37 "(a propaganda operation, a state actor, a sophisticated ad-tech firm, a coordinated influence campaign, a competitor)"; L41 "fight them, regulate them, expose them, sanction them"; L83 the entire bold paragraph is one colon cascade; L87 three quoted "diagnostic format" sentences.

**(d) Tics.** substrate ×58 ⚠, "the book" ×22, exactly ×2, precisely ×1, "said plainly" ×1, "structurally" ×5.

**(e) Aphorisms.** L41 "You can defeat a captor; you cannot defeat an equilibrium."; L43 "the equilibrium is by far the harder of the two."; L77 "Composes 'by absence'"; L97 "That's a tractable design problem; the per-chapter framings were not."; L85 "three projections of the same taxonomy onto chapter-local concerns."

**(f) Uncertainty section (L99–111, ~750 words).** The best of the seven: all six bullets are genuine epistemic limits (list incomplete; source boundary blurry; hierarchy ordinal only; consumer-key may deserve its own note; no positive theory of a well-tuned surface; self-capture does dismantle sometimes). Bullet 4 is now done (`concepts/consumer-key-vs-surface-capture.md` exists); cut. Bullet 5 (no positive theory) should be promoted into the body as a stated limit, since Ch 12 designs against it. Trim each bullet by a third.

**Rewrites.**

*L13 (original, ~180 words):* "[[medium-and-manipulation|The medium note]] gave manipulation its definition … lets the same word carry across the book's three chapters."
*Rewrite (70 words):* "The medium note defined manipulation as tuning a gate's criteria against truth. Capture is that definition with two words widened. *Gate* becomes any surface that ranks, admits, or generates content: the criteria, the menu, a training corpus, a training objective, a deployment setting, a curriculum, an archive. *Truth* becomes whatever the surface was for: faithfulness, helpfulness, accuracy, the user's benefit. **Capture is tuning a surface against what it was for.**"

*L31 (original, ~130 words):* "A note on what unifies the list. Every substrate above is a place where *some entity ranks or admits or generates content according to criteria*…"
*Rewrite (50 words):* "What the seven have in common: each is a place where someone decides, by criteria, what reaches a consumer downstream, whether that consumer is a reader, a model, or a citizen. Selection has an owner because it runs on criteria. Capture is what happens when the owner tunes the criteria against the consumer."

*L41 (original, ~200 words):* "The asymmetry the book has been carrying in different vocabularies, said plainly: **self-capture is structurally more stable than external capture because there is no captor to defeat.** …"
*Rewrite (80 words):* "**Self-capture is more stable than external capture because there is no one to defeat.** An outside captor can be fought, regulated, exposed. A self-captured institution is just doing its job. You can beat a captor; you cannot beat an equilibrium. The only way out is to remove whatever pays for the captured state, usually a revenue stream, because incompetence alone doesn't hold an institution in place. A captured state that doesn't pay for itself drifts off on its own."

*L61 (original, ~280 words):* "Some structural results fall out of the hierarchy that the per-chapter treatments did not show. **Training-corpus capture (Ch 11) is structurally similar to receiver-training capture (Ch 8)** …"
*Rewrite (85 words):* "One principle falls out of the list. Some surfaces shape what a person *meets*: a feed's ranking, a platform's format, a system prompt, an archive. Others install the equipment a person *reads with*: a curriculum, a training corpus, a training objective. **Captures that install the key are harder to undo than captures that shape the surface**, because the damaged party is the reader, and a re-tuned reader reads even good evidence through the bad key. Ch 8's training-over-preservation asymmetry is the special case."

## 3. Evidence

| Line | Claim | Backing |
|---|---|---|
| L37 | "asymmetric arms race," *Misinformation Age* p.175 | Cited with page; linked. Good. |
| L39 | Propaganda rides engagement-tuned gates | Uncited. Benkler, Faris & Roberts, *Network Propaganda* (2018); Vosoughi et al. 2018. |
| L41 | "pure incompetence does not produce a stable captured state" | ⚠ Asserted; no argument given. |
| L52 | Receiver-training recovery "at least one full cohort cycle, typically a generation" | Asserted; `concepts/institutional-decay-rates.md` is the book's own version; cite or cross-link. |
| L53–54, L63, L73 | Captured objective pollutes the next corpus; compounds across generations | Shumailov et al., "AI models collapse when trained on recursively generated data," *Nature* 2024. Not in sources.json; the strongest available backing for the note's strongest claim. |
| L55 | Deployment configs change silently between requests | True in practice; fine as observation. |
| L59 | Recovery hierarchy | No evidence; L105 admits. Present as a default, in a table, not as a result. |
| L71 | "captured LLM trained on a captured corpus used as a tutor" | Internal (Ch 11). |

The note has exactly one external citation for 3,500 words. That is acceptable for a taxonomy if it says so; it currently reads as if the hierarchy were a finding.

**Load-bearing bolds:** L15 (definition), L41 first bold, L61 second bold (consumer-key principle), L63 (objective self-reinforces), L79 (defense heuristic; Ch 12 uses it). **Ornamental:** L41 second bold, L61 first bold, L83 (restatement).

## 5. Interlinking and searchability

None of the concept pages generated *from* this note link back from it. Unlinked at first use: option space (L22 → `[[option-space]]`); corpus / objective / deployment capture (L23–25 → `[[corpus-capture]]`, `[[objective-capture]]`, `[[deployment-capture]]`); self vs. external (L35 → `[[self-vs-external-capture]]`); engagement equilibrium (L38 → `[[engagement-equilibrium]]`); capture asymmetry (L47 → `[[capture-asymmetry]]`); consumer-key vs. surface (L61 → `[[consumer-key-vs-surface-capture]]`); decay rates (L52 → `[[institutional-decay-rates]]`); cost-shifting (L79 → `[[cost-shifting]]`); LLM collapsed design moment (L95 → `[[llm-design-moment-collapse]]`); selection-design surface (L13 → glossary anchor). Manipulation definition (L13 → `[[manipulation-surface]]`).
Cases: none named. Sources: Misinformation Age linked.

**Frontmatter proposal:**
```yaml
description: "One definition of capture and three questions to ask of any case: which part of the system was rigged, who rigged it (an outsider, the institution itself, or both), and how hard it is to undo. Rigging what people read with is worse than rigging what they see."
aliases: [capture, capture taxonomy, self-capture, external capture, regulatory capture of media, consumer-key capture, surface capture, corpus capture, objective capture, deployment capture, captured equilibrium, who rigs the algorithm]
```

## 6. Reader-facing defects

- **Term collision:** "substrate" here vs. `medium-and-manipulation.md:11` and `glossary.md:29`. ⚠ Highest-priority fix in the set.
- "desideratum" (L13, L15), "gradient" (L39, L43, L69), "composite" (L39), "ordinal" (L105): jargon a general reader will trip on.
- `complexity-virality-tradeoff.md:92` says "The capture taxonomy *later in the book*" — the note has no position in the reading order, so "later" points nowhere.
- L7 narrates drafting order ("By the time the book reached Chapter 11"); L95 "Ch 11 should cross-reference and downgrade the … deferrals" is done (PROSE-DECISIONS G5); stale.
- L59 ranks preservation-archive as *more recoverable* than receiver-training, while `glossary.md:183` (differential decay rates) says preservation rots *slowly* and training within a generation. Different axes (recovery vs. decay) but adjacent readers will read them as a contradiction; one sentence separating them.
- L87's "diagnostic format" produces sentences like "self-captured by the business model, surface substrate, recoverable per gate-criteria but stably so given the resource flow" — unreadable to anyone outside the note.

## Top 5 actions

1. Rename "substrate" → "surface" throughout (58 instances) and reconcile with the medium note's use.
2. Replace L17–63 prose lists with one seven-row table; keep the two principles as the only bolds.
3. Delete L81–97; promote uncertainty bullet 5 (no positive theory) into the body.
4. Cite Shumailov et al. 2024 for the self-reinforcing-objective claim; mark the hierarchy as a default, not a finding.
5. Link every concept page derived from this note, and give it a place in the reading order so "later in the book" (Ch 5:92) resolves (see structure file).
