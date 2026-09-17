# Foundational notes: fold, interlude, or appendix?

Method: for each note, I counted the numbered chapters that wikilink it (excluding `outline.md`, `glossary.md`, `index.md`, and generated concept pages), then read each linking sentence to judge whether the chapter *restates* the note's content or *defers* to it ("worked out in…"). Restated content can be folded or left as a back-reference; deferred content needs a home in the reading order. Current order: 1, 2, 3, 4, 5, 5b, 5c, 6, 7, 8, 9, 10, 11, 12 (`data/chapters.json`).

| Note | Chapters linking it | Restated in chapters? | Verdict |
|---|---|---|---|
| transport-vs-selection | 4 (3, 5b, 5c, 7) | Yes, fully, by 5b | **(a) fold** into 5b |
| medium-and-manipulation | 8 (3, 5, 5b, 5c, 6, 7, 8, 10) | Partly (5b, 5c, 7, 10) | **(b) interlude** after 5b, or fold into 5b |
| three-layer-message | 5 (5, 5b, 5c, 8, 11) | Yes (5c:27 restates the model) | **(a) fold** into 5 |
| myths-scale-and-bureaucracy | 6 (5c, 8, 9, 10, 11, 12) | Loop restated in one-sentence glosses ×4; outcomes not | **(b) interlude** before 8 |
| bridge-nodes | 5 (4, 6, 8, 9, 12) | Yes (9:45 restates the short version) | **(a) fold** into 9 |
| capture-taxonomy | 9 (2, 5, 6, 7, 8, 9, 10, 11, 12) | Definition + consumer-key principle restated; axes/hierarchy/composition not | **(b) interlude** after 11 **+ (a)** promote consumer-key principle into 8 |
| intersubjective-truth | 9 (2, 5, 5b, 5c, 8, 9, 10, 11, 12) | Regime names and fork restated; all else deferred | **(b) numbered chapter** after 8 |

## Per-note rationale

### transport-vs-selection → fold into Ch 5b

Ch 5b is already the chapter-grade version of this note: it restates generate/bound/pick (`selection-as-other-engine.md:25`), the modality argument (`:39`), and the retraction of "selection is primary" (`:39`, "worked through why that is wrong"). What 5b lacks is the note's *evidence*: the five test cases (L21–49), which are the only place the book shows selection and transport making different predictions. Move the test cases into 5b as its evidence section and the historical claim (L55: transport cost collapsed) into 5b or Ch 1. Discard the rest (the retracted "Where I land," the executed "What this changes"). Fix `outline.md:35`, which still reports the retracted answer. Zero chapters depend on anything in this note that 5b does not already state.

### medium-and-manipulation → interlude after Ch 5b (fallback: fold into 5b)

The most-borrowed sentence in the book is L37's manipulation definition (used by `capture-taxonomy.md:13`, `political-economy-of-attention.md:65`, `myths-scale-and-bureaucracy.md:49`, `intersubjective-truth.md:59`). The three-lever structure (capacity/criteria/want) is not stated as a unit anywhere in the chapters; 5b restates the option-space lever (`:55`), 5c restates "medium supplies the key" (`:37`) and cashes the "truth-correlated" condition (`:57`), Ch 7 restates the want-loop (`:53`) and the medium-relative floor (`:93`), Ch 10 restates the definition. So four chapters each carry one piece, and no reader meets the whole. Eight chapters depend on it, more than any note except the two Part IV hubs. Recommend a short numbered interlude ("The Medium") between 5b and 5c: three levers, manipulation definition, two conditions, the casting-director hedge, ~1,500 words. If the book wants fewer interludes, 5b already opens the option-space argument at `:55–61` and could absorb the other two levers in ~600 words; the cost is that 5b becomes the longest chapter in Part II.

### three-layer-message → fold into Ch 5

Ch 5c says "I will restate only the part I need" and then restates the model (`truth-compression-and-when-each-wins.md:27`); Ch 5, 5b, and 8 use "outer message" as a bare synonym for decoding key (`complexity-virality-tradeoff.md:30`, `selection-as-other-engine.md:83`, `preservation-vs-training.md:15,27,41`). The note's one move is "outer message = preconditions," and *preconditions* is defined in Ch 5. Put the model where the definition is: a ~600-word section in Ch 5 ("What a message is made of"), Voyager included, then 5c's restatement becomes a back-reference. The two derived definitions (manipulation corrupts the key, L43; manufactured content forges the frame, L45) go to 5c and Ch 1's manufactured-content section respectively. This is the shortest note and the cleanest fold; nothing is lost.

### myths-scale-and-bureaucracy → interlude between Ch 7 and Ch 8

The tell is that four chapters carry the same parenthetical gloss of the dilution loop: `preservation-vs-training.md:63` "(scale forces a network's binding myth to compress, compression widens…)", `political-economy-of-attention.md:59` "(scale compresses a network's binding myth; the compressed myth reads many ways; the readings segment the network)", `integration-problem.md:21`, `truth-compression-and-when-each-wins.md:49`. A reader meets the loop four times as a gloss and never once as an argument. Ch 8 opens by saying the note "reached this chapter's problem statement and stopped" (`:11`) — Ch 8 literally begins where the note ends. The three loop outcomes (neutral / weak / captured) are restated in one sentence at 8:63 and 10:59 but the argument for *why capture is the stable one* (L57–61) exists only here, and Ch 8, 10, 12 all lean on it. Six chapters depend on it; PROSE-DECISIONS G4 already proposes "before Ch 8." Trimmed to ~1,900 words (see its report) it is the natural Part III→IV hinge: "Interlude: Myths at Scale."

### bridge-nodes-and-versatile-expertise → fold into Ch 9

Ch 9 restates the whole short version at `integration-problem.md:45` ("**a bridge node is a deep specialist who has paired their depth with metacognitive flexibility**… The depth is what gets the bridge admitted…"), Ch 8 restates why generalists fail (`:37`) and who the trained receivers are (`:41`), Ch 12 restates the curse/polarization identity and already calls it "the Ch 9 bridge-node argument" (`:81`). The note's own last line says it exists to "unblock Chapter 9's spine" (L87). Nothing in it is deferred-to that Ch 9 doesn't already carry in compressed form; what Ch 9 lacks is the *argument* (why generalists fail two pressures, L11–17; the four failure modes and their link to polarization, L45–61; the two open problems, L73–79). Move those into Ch 9 as its agent-side section. The abyss paragraph (L63) belongs with the `[[abyss]]` concept, which the concept page says is discussed in Ch 4 and Ch 11.

### capture-taxonomy → interlude after Ch 11 (before 12), plus promote one principle into Ch 8

Nine chapters link it, the most of any note, and the pattern of use is split. Ch 5, 6, 7, 9 use only the *consumer-key vs. surface* principle (`complexity-virality-tradeoff.md:92,107`, `bridge-zone-distortion.md:71`, `integration-problem.md:23,105`), which is a one-paragraph idea that Ch 8's capture asymmetry already contains as a special case (the note says so, L61, L85). Ch 10 restates the source axis in a parenthetical (`:61`). Ch 11 restates the three LLM surfaces (`:69`) and their composition (`:79`). Only Ch 12 uses the full apparatus: the recovery hierarchy (`:19,59`), objective custody (`:67`), and the defense heuristic. So: (1) promote the consumer-key-vs-surface principle into Ch 8 prose proper, where capture asymmetry lives, so Ch 5–9's forward references resolve to a chapter; (2) place the unified taxonomy as an interlude between Ch 11 and Ch 12, where all seven surfaces have been introduced (gate/option space from 5b/10, training/preservation from 8, corpus/objective/deployment from 11) and the design chapter can draw on the whole. PROSE-DECISIONS G4 proposes "after Ch 8," but three of the seven surfaces don't exist until Ch 11; an interlude after 8 would have to introduce LLM surfaces before the LLM chapter. `complexity-virality-tradeoff.md:92` "the capture taxonomy later in the book" then becomes true.

### intersubjective-truth → numbered chapter between Ch 8 and Ch 9

This is the one note the chapters *defer* to rather than restate. Ch 2 links it six times and says "The fuller working-through lives in the note" (`case-studies-and-three-realities.md:132`); 5c scopes itself to objective claims "by decision" and hands the other case to the note (`:87`); Ch 9 says the chapter-grade treatment "remains future work" (`:146,182`); 10, 11, 12 each take one consequence. Nine chapters depend on it, it carries the book's second thesis (L87: the transport collapse "cuts twice"), and it is already written at chapter standard (opening experiment, six worked examples). An appendix cannot hold a thesis. Placement is constrained by its dependencies: it uses 5c's regimes (L47), the myths loop (L51), Ch 8's capture asymmetry (L63), and the capture taxonomy's consumer-key principle (L61–63). After Ch 8 (with the myths interlude before 8 and the consumer-key principle promoted into 8) all four are behind the reader, and Ch 9–12, which all use it, are ahead. Ch 2's and 5c's forward references become ordinary "Chapter 8b works this out" pointers. The alternative, 5d directly after 5c, would put it before the myths and bureaucracy material it leans on at L51 and L61.

## Resulting reading order

1 · 2 · 3 · 4 · 5 (+three-layer) · 5b (+transport test cases) · **Interlude: The Medium** · 5c · 6 · 7 · **Interlude: Myths at Scale** · 8 (+consumer-key principle) · **8b: Truth the Network Makes** (intersubjective) · 9 (+bridge nodes) · 10 · 11 · **Interlude: Capture** · 12

That is three interludes and one new chapter; if three interludes is too many, the Medium interlude is the one to fold (into 5b). Three notes retire entirely (transport, three-layer, bridge-nodes), which also retires three "Working note" openers, three "What this changes for the book" sections, and the stale outline entries that describe them.

## Cross-cutting findings

- All seven open with "Working note." and five have a "What this changes for the book" section whose every item has been executed in the chapters. These sections are the largest single source of self-narration in the corpus (capture-taxonomy alone has 42 "Chapter N" references). Delete all five.
- `medium-and-manipulation.md:73` and `myths-scale-and-bureaucracy.md:73` share a verbatim template sentence ("This note works out a mechanism several chapters depend on, so the implications fan out").
- "Substrate" means the physical carrier in `medium-and-manipulation.md:11` and a selection-design surface in `capture-taxonomy.md` (×58). Two foundational notes give one word opposite meanings; rename in the taxonomy.
- The uncertainties sections are the most honest prose in the set (capture-taxonomy's and intersubjective-truth's especially) but each carries one or two *production* bullets ("is now flagged in the prose," "may deserve its own note") that should go.
- Six social-ontology sources (Searle, Berger & Luckmann, Anderson, Hacking, Soros, Hirschman) exist in `data/sources.json` with citation pages saying "not yet engaged"; the intersubjective note's body never links them.
- `outline.md:29–44` still describes the notes under "Foundational questions still being worked out" with the transport note's retracted "selection-primary" answer.
