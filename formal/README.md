# Complexity as least cost of realization: a machine-checked framework, after adversarial review

This directory is a Lean 4 library (Mathlib v4.36.0, no `sorry`, standard axioms only).
It was first written as "a unified theory of complexity". It was then attacked: by the
author, and by four independent reviewers covering the core statements, the instances,
the prior art and the empirical predictions. This README is the corrected account. The
first version is not kept here; what it claimed and what happened to each claim is in
[section 1](#1-what-the-review-found).

**What this is, stated at its actual strength.**

> `K(x) = ⨅ { cost d | d realizes x }` is a common *language* for description-type
> complexity measures, not a theory of them. Every function is `K` for some choice of
> descriptions. The content is in a small number of laws that hold once the choice is
> constrained, and those laws are classical in the fields they come from.

What the library adds is that the laws are stated once and proved once, formally, with the
circuit, addition-chain, string-grammar, regulator, learning and channel bounds derived
from the same lemmas, and that the limits of the framework are proved too
([`Limits.lean`](Complexity/Limits.lean)).

For a non-technical account, open [`overview.html`](overview.html): it has a
plain-language explanation of the whole project, a ladder showing where each law holds, a
ledger of every claim with its status, and a glossary of 83 terms.

[Section 7](#7-after-the-review-restricting-the-dials-until-something-is-excluded) is
later work: the dials restricted to self-delimiting systems, where a representation
theorem and the additive laws do hold, and then to computable ones, where a universal
prefix machine exists and Levin's coding theorem is proved for it.

---

## 1. What the review found

### Refuted (the first version said these; they are false)

| claim | what is true | evidence |
|---|---|---|
| `K(fᵗx) ≤ K(x) + log t + c` for the universal machine, "classical" | False for plain Kolmogorov complexity, for the library's own `U` and a primitive recursive `f`. Two description lengths were added with no delimiter. Correct forms: `+ O(log log t)` more, or a self-delimiting description of the state. (That `tick` is primitive recursive is evident and not machine-checked) | `Limits.not_iterate_bound_kolmogorov`; for the universal prefix machine `Conditional.K_iterate_le_log`; `Limits.exists_binary_iterate` only shows that a glued system with the bound exists |
| `K(micro) ≤ K(macro) + ⌈log₂ W⌉ + c` for the universal machine | False for the same reason | `Limits.not_twoPart_bound_kolmogorov`; for the universal prefix machine `Conditional.K_twoPart_le`; `Limits.exists_binary_twoPart` only shows that a glued system with the bound exists |
| "typical microstates attain" `K(macro) + log₂ W` | Not proved. The lower bound proved is `log₂ W − c`, with no `K(macro)` term; the upper bound `≤` holds by construction of the two-part cost; section 7 proves both halves for the universal prefix machine (`Symmetry.micro_eq_macro_add_log`) | `CoarseGraining` review note |
| "complex implies improbable"; frequency falls off exponentially in complexity | Not a law of description systems: there is one prefix-free system in which the number `n` has complexity `2n + 1` and probability `2^(−(n+1))`, so no constant `c` gives `P ≤ 2^c · 2^(−K)` (`Plain.not_coding_self_delimiting`). The older witness, `Limits.exists_complex_probable`, used a different two-object system for each `n` and refutes only a constant uniform across systems. The real result (simplicity bias) rests on Levin's coding theorem for universal prefix machines, proved in section 7 (`Levin.levin`) | `Plain.not_coding_self_delimiting` |
| "every lower bound is a potential" | The converse is what is proved. A three-node counterexample exists | reviewer proof, summarized in `Metric` review note |
| measures agree "exactly when" each system simulates the other | Only "object-fixing simulation ⇒ domination" is proved. As worded, both directions have counterexamples | `Invariance` review note |
| a budget below `|p|` plus the claim's load "cannot carry both" (*Lossy*) | `Channel.load_le_add_of_prefix` is an upper bound; it implies no such thing | `Channel` review note |
| loss "scales with cascade depth" as a result of the model | It is the hypothesis `lam ≤ w e`. The budget model alone decides nothing about depth: a stable relay iterated any number of times loses what one pass loses (`Limits.relay_iterate_saturates`), and a relay that drops one bit per retelling stays within budget and loses `n` bits in `n` hops (`Limits.leak_iterate`). What the budget does force is the bottleneck: a chain emits no more distinct versions than its tightest hop allows. This row used to claim "a chain loses what its tightest hop loses, at any length" for the model as such; that is false without the stability hypothesis | `Limits.relay_iterate_saturates`, `Limits.leak_iterate`, `Channel.Relay.card_image_chain_lt` |

### Empty (true, but saying nothing at the generality claimed)

- **"Every measure is this infimum for some dial setting."** Every function into a
  complete lattice is `K` of an unambiguous description system
  (`Limits.exists_system_K_eq`). The same holds at the other two levels: any `d` with
  `d a a = 0` and the triangle inequality is a generative distance
  (`Limits.dist_complete_eq`), and any function is a tree or DAG complexity over a large
  enough signature (this last one is not formalized).
- **Invariance (law VIII).** `Dominates` is defined as the inequality the theorem
  concludes, and a zero-cost system dominates everything. The law has content only
  relative to a class of admissible systems fixed from outside, such as the computable
  ones (`Limits.dominates_iff_pointwise`).
- **Strong duality.** "Complexity is the greatest potential" is witnessed by complexity
  itself. Only weak duality (every potential is a lower bound) is used anywhere.
- **Fidelity and transport (laws I, II).** Commutation and monotonicity of infima.
- **The laws do not "hold for every setting of the dials".** Each needs its own
  structure: unambiguous descriptions for counting, a path or term structure for
  conservation and duality, a size rule for the logarithm.

### Complete (a sharper statement than the first version made)

- **Counting is the only general fact about binary descriptions.** A function is the
  complexity of an unambiguous binary system if and only if each level set `{f = n}` has
  at most `2ⁿ` members (`Limits.exists_binary_iff`). Nothing else follows from
  "descriptions are bit strings and cost is length".

### Already known (prior art; the first version said no search had been done)

| part | closest prior work |
|---|---|
| the definition, with arbitrary description method | Kolmogorov 1965; Uspensky & Shen 1996 ("description modes": any binary relation between descriptions and objects); Burgin's dual complexity measures (1982, restated 2004), with arbitrary cost and with Kolmogorov variants and Boolean circuit size as named instances |
| invariance, transport | Kolmogorov 1965; Burgin 2004; descriptional complexity (Meyer & Fischer 1971; Gruber, Holzer, Kutrib 2009) |
| level 1: shortest-path generalized metric, potentials | Lawvere 1973 ("work required to get from a to b"); textbook shortest-path duality (e.g. Schrijver); cost and yield monotones in resource theories |
| level 2: least-cost derivation, greatest fixed point | Knuth 1977 (lightest derivation); semiring Datalog; "formula size is the largest formal complexity measure" (Wegener 1987) |
| reuse, log law, circuits = grammars = chains = assembly | straight-line programs over algebras (Bertoni & Radicioni 2010; Bürgisser & Clausen); word chains (Berstel & Brlek 1987); assembly spaces (Marshall et al. 2022) and their critiques |
| temperature | Tadaki 2008; Baez & Stay 2010; simplicity bias: Dingle, Camargo & Louis 2018 |
| profiles; depth and sophistication as one construction | Vereshchagin & Shen 2017, who prove the two profiles coincide to `O(log n)`; Antunes et al. |
| the dynamics observation | Aaronson 2011 |
| Lean formalizations | an existing Lean 4 Kolmogorov-complexity library and a Lean Kraft / source-coding development; earlier HOL4 and Coq work |

Not found in one place by the search: the whole set under one roof; the counting bound
`n·(m·nʳ)ⁿ` for an arbitrary finitely generated algebra; reuse complexity as
shortest-path distance on pools with DAG ≤ tree by a potential argument; formal proofs of
the generic reuse laws. The reviewer rates the mathematical items as short
generalizations. The search was about 55 queries; absence from it is not proof of
novelty. **Correction, November 2026:** this list used to include "formal proofs of the
circuit-counting bound". That is no longer true: CSLib has Shannon's lower bound, generic
over finite carriers and signatures of arity at most 2, and Lupanov's upper bound, both in
Lean 4 since September 2026. See "Prior art for the reuse results" in section 7.

### Held

- **Formal integrity.** All declarations of the library, not a sample, depend only on
  `propext`, `Classical.choice` and `Quot.sound` (`#audit_library` in
  [`Audit.lean`](Audit.lean)). No reviewer has found a false Lean statement. Statements
  true only by a junk value have been found since, five of them in section 7, and
  restated; `Circuit.exists_hard_function` still admits one at `n = 0` and says so in its
  docstring.
- **The counting lemma** (`DescSystem.card_le_of_K_lt`) and its binary form. Reused by the
  Kolmogorov, learning, channel, coarse-graining and regulator instances.
- **The level-2 theory**: DAG ≤ tree, copying is free, the logarithmic law, weak duality,
  and the finitely generated counting bound. Circuits, addition chains and string
  grammars are derived from it with no field-specific argument.
- **The Kolmogorov instance**: `U` dominates every partial recursive description method
  (`Kolmogorov.U_dominates`). This line used to say the dominated class is "exactly" those
  methods. It is strictly larger (`Plain.dominated_not_all_partrec`): for any set `A` of
  strings, "output 0 on `A`" is dominated, and there are uncountably many such methods.
  That the programs `Set.range run` are exactly the partial recursive methods was asserted
  without proof until a review asked; it is now `Plain.mem_range_run_iff`.
- **The Moore bound** and the conservation (triangle) inequality, as mathematics.

---

## 2. The definition

A **description system** ([`Basic.lean`](Complexity/Basic.lean)) is a type `D` of
descriptions, a type `X` of objects, `cost : D → Γ` in a complete lattice, and
`realizes : D → X → Prop`.

```lean
def K (S : DescSystem D X Γ) (x : X) : Γ := ⨅ (d : D) (_ : S.realizes d x), S.cost d
```

The structure has two fields, cost and realization. Read as choices there are four
dials: which descriptions exist (the type), what is paid, what counts as producing `x`,
and what is free (not a field: it is the set of free starting points in `Metric.lean`). This is a normal form, not a hypothesis. Two
further structures are used:

| level | descriptions are | complexity is | file |
|---|---|---|---|
| 0 | anything | `K` | `Basic`, `Counting`, `Invariance`, `Profile`, `Thermo` |
| 1 | paths of priced moves | a Lawvere metric `dist` | `Metric` |
| 2 | terms over operations | least term cost; with sharing, `dist` on pools | `Generative`, `Reuse`, `Growth`, `Binary` |

Levels 1 and 2 are each instances of level 0. DAG complexity is level 1 on pools
(`Sig.poolK_eq_iInf_dist`). Tree complexity is not shown to be a path distance.

## 3. The laws, with what each one needs and whether it carries content

All are restated in [`Laws.lean`](Complexity/Laws.lean).

| | law | needs | content |
|---|---|---|---|
| I | Fidelity: `K(class) = ⨅ K(members)` | nothing | bookkeeping |
| II | Transport: `K'(T x) ≤ f (K x)` along a simulation | a simulation, and an overhead `f` that preserves infima | bookkeeping; used only as "a fixed prefix costs its length" |
| III | Conservation: `dist a c ≤ dist a b + dist b c` | path structure | the triangle inequality. It is *not* the chain rule for Kolmogorov complexity, which holds only up to log terms |
| IV | Duality: every potential is a lower bound | path or term structure | weak half used (DAG ≤ tree, formula lower bounds). Strong half witnessed by `K` |
| V | Counting: no more cheap objects than cheap descriptions | unambiguous descriptions | **carries content**; complete for binary systems |
| V′ | At most `n·(m·nʳ)ⁿ` values have DAG complexity ≤ `n` | finite signature, arity ≤ `r`, single-valued operations | **carries content**; a separate direct count, not an instance of V |
| VI | Reuse: `K_dag ≤ K_tree`; a repeated part is paid once | term structure, size rule | **carries content** |
| VII | Logarithm: `μ(x) ≤ r^(K(x)−1)` | subadditive size `μ`, arity ≤ `r` | **carries content** for `r ≥ 2` |
| VIII | Invariance | a class of admissible systems | true by definition of `Dominates`; the content is the existence of a universal member |

## 4. Instances

"Proved" here means the listed theorems hold of the library's definition. That the
definition is the field's is by inspection. For Kolmogorov complexity one piece of that is
a theorem: the description methods ranged over are exactly the partial recursive ones
(`Plain.mem_range_run_iff`).

| measure | what is actually proved | general laws used |
|---|---|---|
| **Kolmogorov complexity** (plain, of natural numbers) | a universal interpreter over Mathlib's `Nat.Partrec.Code`; optimality, invariance, incompressibility. The plain instance has no conditional complexity, chain rule or prefix version; those are in section 7 for the prefix machine | II (prefix lemma), V, VIII |
| **Shannon source coding** | one-shot `H ≤ L* ≤ H + 1` for Kraft-admissible length functions, for sources with full support. (`L*` equals `H` only for dyadic sources; that remark is not formalized.) No block limit, no Kraft–McMillan | none (textbook Gibbs argument) |
| **Circuit and formula size** (NAND, inputs counted) | circuits ≤ formulas; soundness of formal complexity measures; a hard function exists once `s·((n+1)s²)ˢ < 2^(2ⁿ)` (order `2ⁿ/2n`); with `n ≥ 1` variables every function has a circuit of size at most `5 + 2ⁿ(4n + 7)` (`Circuit.circuitK_le`, disjunctive normal form), so the hard function's size is finite (`Circuit.exists_hard_function_between`). Section 7 sharpens the upper bound to the order `2ⁿ/n` (`Circuit.circuitK_le_shannon`); the exact constant (Lupanov 1958) is not proved | IV weak, V′, VI |
| **Addition chains** | doubling upper bound and `l(n) ≥ log₂ n` | VI, VII |
| **String straight-line programs** | `|w| ≤ 2^(K−1)`; squaring upper bound; exponential tree/DAG gap | VI, VII, IV weak |
| **Molecular assembly** | nothing specific. V′ does not apply as stated: a join of two fragments is multi-valued | — |
| **Two-part codes** | `log₂ W − c` lower bound for all but `2⁻ᶜ` of `W` candidates (Hartley); a two-part cost that is at most `K(macro) + ⌈log₂ W⌉` by construction, `W` an upper bound on the fibre size | V |
| **Causal states** | least number of values of a sufficient statistic = number of distinct futures. Not Myhill–Nerode, not `C_μ` | none |
| **Requisite variety** | `#disturbances ≤ #responses × #outcomes` if each response separates disturbances | V (bare pigeonhole) |
| **VC dimension** | a class each of whose members is describable in ≤ `n` bits has VC dimension ≤ `n` | V |
| **Partition function** | `q^K ≤ Z`; Kraft counting; `Z(1)` counts descriptions. Not applicable to the plain machine above, where `Z(½) = ⊤` | — |
| **Logical depth, sophistication** | definitions only (Bennett's tentative definition; sophistication without the totality restriction it needs) | — |
| **Transmission** (*Lossy*) | see section 6 | II, V |

Not formalized: information distance, quantum circuit complexity, integration, Krylov
complexity, thermodynamic depth, growth rates (fractal dimension, KS entropy), uniform
complexity classes.

## 5. Cross-domain consequences

The first version called these predictions. The review's verdict: none is a risky
prediction made by the framework. Each is a theorem plus a mapping, the mapping is
untested, and where an item has empirical bite it is an existing result of the field.

1. **Few objects are cheap.** With `m` single-valued operations of arity ≤ `r`, at most
   `n·(m·nʳ)ⁿ` objects can be built in `n` steps. The exponential fall-off of frequency
   with complexity is the published simplicity-bias result; it is not derived here and
   has known exceptions. Inferring a directed process from abundance needs the generator
   set known independently, and is disputed in the assembly-theory literature.
2. **Size needs steps.** An object of size `μ` built by `r`-ary joins needs at least
   `1 + log_r μ` construction steps, generators included, so at least `log_r μ` joins. Whether a physical object was built that way, and how many joins
   were available, must be shown independently; `μ/K` is not measurable when `K` is
   uncomputable.
3. **Deterministic dynamics.** `K(fᵗx) ≤ K(x) + log t + O(log log t)` in a universal
   language (Aaronson 2011). Practical compressors cannot test it: Rule 30 from one cell
   compresses to 100% of raw at every size tried, while its true description is about 22
   bits. "Faster growth means noise or input" was wrong as a diagnostic. That such states
   are deep is not proved.
4. **Regulators and learners.** Ashby's law and the bound "a class whose members are
   describable in `n` bits has VC dimension at most `n`" are instances of one pigeonhole
   lemma. (`VC ≤ log₂|class|` itself is a separate two-line count, and neither is the
   sample-complexity bound that "the VC bound" usually means.) That is a unification of
   proofs, not a prediction.
5. **Coarse-graining.** Typical members of a set of `W` candidates need `log₂ W − c`
   bits. The split into "structure" and "entropy" is a convention set by the choice of
   coarse-graining.
6. **Agreement of measures.** Mutual domination is agreement up to a constant, by
   definition.
7. **Profiles.** Depth and sophistication can be written as one construction. No relation
   between their values is proved here; the literature proves one.

## 6. What this says about *Lossy*

[`Instances/Channel.lean`](Complexity/Instances/Channel.lean) models a receiver as a
decoder from bit strings to ideas and defines the **load** of an idea as the shortest
message that receiver decodes to it. This is a stipulated model; nothing in it says that
an idea with more preconditions has a higher load.

| proved | statement |
|---|---|
| budget ceiling | within `B` bits fewer than `2^(B+1)` distinct ideas can land exactly (for landing within a tolerance, see below) |
| preamble | a receiver who decodes like the expert after a preamble `p` carries at most `|p|` more load (upper bound only) |
| bottleneck | a chain of retellings emits fewer than `2^(B+1)` distinct versions, `B` the tightest budget. Independent of chain length |
| hop distance | with ≤ `deg` onward contacts each, an audience above `1 + deg + ⋯ + degⁿ` contains someone more than `n` hops away, or not reachable at all |
| assumed, not derived | every hop loses at least `λ`, additively |

What the review established about the chapter's argument:

- **The model undercuts the "network ceiling" as stated.** The chapter's illustration
  uses ten to a hundred retellings. The hop bound gives 3 hops for an audience of a
  million and 5 for a billion at 150 contacts each, and 2 hops once any account has 10⁵
  followers. At 0.9 survival per hop the bound moves from 0.87 to 0.65 across six orders
  of magnitude of audience. Forcing ten hops at degree 150 needs an audience above
  `3.9 × 10¹⁹`.
- **Budgets alone neither force nor forbid loss that grows with depth.** A stable relay
  iterated any number of times loses what one pass loses
  (`Limits.relay_iterate_saturates`); a leaking relay within the same budget loses one
  more bit at every hop (`Limits.leak_iterate`). Depth dependence in the chapter's model
  comes only from the assumed per-hop loss.
- **The budget is on the wrong axis.** The chapter's budget is time and effort; the
  model's is message length. At measured speech rates one minute is hundreds to thousands
  of bits, so the ceiling `2^(B+1)` never binds.
- **Field evidence complicates a many-retellings mechanism.** Large diffusion studies
  find most adoption within one hop of a seed and even the largest events dominated by
  broadcast (Goel, Watts & Goldstein 2012; Goel et al. 2016). Depth differences between
  true and false news disappear when cascades are matched on size (Juul & Ugander 2021).
  Reshares are verbatim copies with no per-hop loss. In transmission-chain experiments
  loss is front-loaded and saturating. These four sources were checked against the
  papers; the rest of the reviewer's citations were not independently re-read.
- **"Why the key goes first" is the book's hypothesis, not the model's.** Chain
  experiments on summaries report the conclusion distorted most, which leans against it.
- **"The counter-examples are the one-hop cases" is a relabelling** unless hops, per-hop
  loss and preamble length are measured independently.

### With a tolerance ([`Lossy.lean`](Complexity/Lossy.lean))

The model above asks whether an idea lands *exactly*. The chapter is about ideas that land
*approximately*. `Lossy.lean` gives the space of ideas a distance (Mathlib's `edist`) and
says an idea is delivered within tolerance `ε` if what the receiver arrives at is at most
`ε` away. The distance is supplied from outside; nothing here says what the distance
between two real ideas is.

| Lean name | Statement | What it says about the chapter |
|---|---|---|
| `Lossy.loadWithin`, `Lossy.loadWithin_eq_iInf_load` | the load of `x` at tolerance `ε` is the shortest message the receiver decodes to something within `ε` of `x`; it equals the least exact load of a point within `ε` of `x` | "can land approximately" is a complexity too. (`Lossy.delivers_iff_loadWithin` restates delivery on budget `B` as "every idea has load at most `B`"; that is a restatement, not a result) |
| `Lossy.exists_relay_iff` | some relay with budget `B` delivers every idea of `A` within `ε` **if and only if** `A` is covered by fewer than `2^(B+1)` balls of radius `ε` | **the exchange rate, exactly.** It is a statement about a repertoire `A` of ideas and a receiver chosen for that repertoire, not about one idea: a single idea can always be delivered on budget `0` by a receiver who already has it. "The easier to spread, the less it can carry" holds in this sense, at a rate set by the covering numbers of the repertoire. How those numbers behave for real ideas is not something the model supplies |
| `Lossy.exists_not_delivered_of_packing` | if `A` contains `2^(B+1)` points pairwise more than `2ε` apart, any chain containing a relay of budget `B` leaves some idea more than `ε` from where it started | **compression is forced, with a tolerance**: too many ideas that are far apart cannot all survive |
| `Lossy.externalCoveringNumber_lt_of_delivers_chain` | the necessary half of the exchange rate holds for a chain containing one relay of budget `B`, whatever happens before and after | **weakest link**: the tightest hop bounds the best tolerance for the whole chain, independent of the chain's length. It bounds; it does not determine (`Limits.leak_iterate`: a chain can lose more than any single hop does) |
| `Lossy.Nat.budget_iff`, `Lossy.Nat.delivers_iff` | every number below `N` can be delivered within `±e` on budget `B` if and only if `N ≤ (2e+1)(2^(B+1) − 1)` | a worked exchange rate, exact: one further bit roughly halves the error needed, up to rounding |
| `Lossy.loadWithin_le_add_of_prefix` | a receiver who decodes like the expert after a preamble `p` pays at most `|p|` more at every tolerance | shipping the key is a fixed additive cost per message. Upper bound only, as before: nothing says a key must be long, or that senders drop it |
| `Lossy.edist_le_of_merged`, `Lossy.not_both_delivered` | if a step sends two ideas to the same thing, every later reading along that chain is the same for both, so one of them is off by at least half their distance | **merging is irreversible.** Distinctions lost at one hop do not come back along that chain |
| `Lossy.orbit_repeats` | for one relay with budget `B` retold through itself, two of the first `2^(B+1) + 1` versions coincide; the chain cycles from there | **depth runs out for a single relay.** Whatever loss iteration causes is reached within `2^(B+1)` retellings |
| `Lossy.merging_stops`, `Lossy.Nat.decRelay_merges_late` | for one relay with budget `B` there is a step `N < 2^(B+1)` after which two ideas still apart stay apart for ever, and the relay is a bijection of the set of versions that survive `N` retellings onto itself; an example keeps merging new pairs for `2^B` steps | **merging runs out too.** After step `N` the relay permutes the surviving versions: any further change is drift and can be undone. Counted as distinctions lost, loss through one relay never reverses and is over after finitely many steps |
| `Lossy.edist_chain_le`, `Lossy.Nat.decRelay_iterate`, `Lossy.Nat.swapRelay_pass` | if each hop moves the idea by at most `δ`, `n` hops move it by at most `nδ` (triangle inequality; `δ` is a hypothesis); a relay within budget moves a number by exactly `n` in `n` retellings for `n ≤ 2^B`; another moves `0` to `1` and back | within the limit above, loss can add up fully, not at all (`Limits.relay_iterate_saturates`, for a stable relay), or go up and come down. along an orbit that has not reached `0`, `decRelay` is a shift; the same relay merges one more number with `0` at every step |
| `Lossy.Nat.exists_drifting_chain` | there are relays with budget `0`, one per hop, such that hop `k` passes on `k` whatever it hears | **for a chain of different relays the budget says nothing about depth**: displacement without limit, on no budget |

What this adds to the review of the chapter's argument:

- **The trade-off is real and has a shape, for a repertoire.** Budget against tolerance is
  governed exactly by covering numbers. That is Kolmogorov and Tikhomirov's `ε`-entropy,
  and `loadWithin_eq_iInf_load` is the definition of Vereshchagin and Vitányi's
  rate–distortion function for an individual object, with an arbitrary decoder in place of
  a universal machine; their theorems are not formalized here. Both attributions are from
  search summaries, not from the papers. Neither says anything about ideas until someone
  supplies a distance between them.
- **"Compounding" does not follow from a budget.** The chapter's `pᴺ` is the survival
  probability of independent per-hop failures. The budget model forces four things: what a
  hop merges stays merged along that chain; the tightest hop bounds the whole chain; one
  relay iterated stops producing new versions after `2^(B+1)` retellings; and it stops
  merging before then. It does not force a per-hop loss, does not make distance from the
  original monotone, and for chains of different relays it puts no limit on drift. Nor
  does it forbid a fixed loss per hop (`Limits.leak_iterate_length`). A hypothesis under
  which a law of the shape `pᴺ` is a theorem is in the next subsection.
- **"What a hop strips is the key" is consistent with the model, not derived from it.**
  The model shows that the key is the part with a fixed additive cost; it does not show
  that a sender under a budget drops the key first, or that keys are long.
- **The budget is still on the wrong axis**: bits, not time and effort.

Prior art in proof assistants: Mathlib has covering and packing numbers, which this file
uses. A search found no formalization of rate–distortion theory or of `ε`-entropy as a
statement about encoders. The search was four queries.

### With noise ([`Noisy.lean`](Complexity/Noisy.lean))

The relays above are functions. Through one fixed chain of functions a given pair of ideas
is either merged or kept perfectly apart; for a pair there is no partial loss.
`Noisy.lean` makes a hop a row-stochastic matrix on a finite set of ideas (Mathlib's
`Matrix.rowStochastic`): `P x z` is the probability that a receiver told `x` passes on
`z`. A *test* is a set `A` of outcomes, and its *advantage* between two originals `x` and
`x'` is the difference in the probability that what comes out of the chain lies in `A`.
Advantage `1` for some test means the two can be told apart with certainty; advantage `0`
for every test means the outcome says nothing about which it was.

| Lean name | Statement | What it says about the chapter |
|---|---|---|
| `Noisy.Forgets`, `Noisy.advantage_le`, `Noisy.advantage_le_pow`, `Noisy.survive_le` | say hop `k` *forgets with probability at least `1 − c_k`* (with `0 ≤ c_k ≤ 1`) if there is a fixed distribution `ν_k` with `P_k x z ≥ (1 − c_k) ν_k z` for every `x` and `z`. Then after `n` hops no test has advantage more than `c_0 ⋯ c_{n−1}`; with one constant, `cⁿ`. In particular `x` arrives intact at most `cⁿ` more often than it would have come out had something else been sent | **a law of the chapter's shape, `pᴺ`, under a sufficient hypothesis.** It is about distinguishability, and its constant is the chance of not falling back; see "which quantity" below. Upper bound |
| `Noisy.guess_le` | if the original is one of two equally likely ideas, a receiver after those `n` hops guesses it with probability at most `(1 + c_0 ⋯ c_{n−1}) / 2` | the same in plain terms: the bound on the edge over a coin flip shrinks by the factor `c` at every hop |
| `Noisy.fade`, `Noisy.fade_mem`, `Noisy.fade_forgets`, `Noisy.chain_fade`, `Noisy.advantage_fade` | the fading hop passes the idea on unchanged with probability `c` and otherwise passes on a draw from `ν`. For `0 ≤ c ≤ 1` it is a hop and forgets with `c`; `n` fading hops are one fading hop with `cⁿ`, and the test "the outcome is `x`" has advantage exactly `cⁿ` | **the bound is attained** |
| `Noisy.Contracts`, `Noisy.advantage_le_of_contracts`, `Noisy.Forgets.contracts`, `Noisy.lazyCycle_contracts`, `Noisy.lazyCycle_not_forgets` | say hop `k` *contracts with `c_k`* if no test tells any two things it might be told apart with advantage more than `c_k` (the least such constant is Dobrushin's coefficient; for `c_k ≥ 1` this is no condition). Then after `n` hops no test has advantage more than `c_0 ⋯ c_{n−1}`. Forgetting implies contracting and is not needed: the lazy cycle on three ideas (stay nine times in ten, else move on) forgets nothing in one step and contracts with `9/10` | **the general one-hop form of the law: the one-hop bounds multiply.** The hypothesis is about one hop at a time and is the conclusion itself for `n = 1`. It is a worst case over every pair of versions a hop might receive, so experiments on single retellings bound `c` from below; the theorem needs a bound from above |
| `Noisy.lazyCycle_least`, `Noisy.lazyCycle_two_hops`, `Noisy.lazyFour_not_contracts`, `Noisy.lazyFour_two_hops` | the lazy cycle on three ideas contracts with `9/10` and no less, yet two of its hops contract with `4/5 < (9/10)²`; on four ideas one hop does not contract at all (`c ≥ 1`), yet two hops contract with `49/50` | **the product is a bound, not the truth, and the one-hop condition is not necessary for decay.** It is necessary and sufficient for the bound `cⁿ` at every depth; a hop with one-hop constant 1 can still lose distinguishability geometrically over pairs of hops |
| `Noisy.intact_prod_le_chain`, `Noisy.prob_fade_self`, `Noisy.two_mul_sub_one_le_of_contracts`, `Noisy.swap_keeps_nothing` | for any hops, the chance of arriving intact after `n` hops is at least the product of the chances of being passed on unchanged; for the fading hop it is `cⁿ + (1 − cⁿ) ν x`; a hop that passes two ideas on unchanged with probability at least `p` contracts only with `c ≥ 2p − 1` (which says something for `p > 1/2`); the hop that swaps two ideas leaves nothing unchanged and contracts only with `c ≥ 1` | **which quantity**: "intact at every hop", "arrives intact" and "advantage" are three different things. The chance `p` of clean preservation bounds the constant `c` from below and says nothing from above |
| `Noisy.forgets_detHop`, `Noisy.forgets_const`, `Noisy.chain_detHop`, `Noisy.detHop_dichotomy` | a hop that is a function forgets with `c < 1` exactly when it is constant; a chain of functions is a function; through it, for a given pair of originals, either no test has any advantage or some test has advantage `1` | **one fixed chain of functions, one pair: all or nothing.** A fractional advantage needs randomness somewhere |
| `Noisy.fade_eq_mixture`, `Limits.leak_iterate_length` | the fading hop is a random choice among functions: the identity with probability `c`, otherwise a constant drawn from `ν`. And one function relay sends every idea of `B` bits to one of `B − n` bits after `n ≤ B` retellings | **the randomness need not be noise in a person**: the fading hop is also a population of retellers who are each a fixed function, met at random (a share `c` of faithful repeaters, the rest always saying their own thing). And over a repertoire a single function relay can halve what is left at every hop, for up to `B` hops (the count is not formalized; the lengths are) |
| `Noisy.two_routes`, `Noisy.two_routes_beat_one`, `Noisy.two_routes_no_gain_bool`, `Noisy.two_routes_le` | through two independent chains of `n` fading hops, the test "neither route delivered `x`" has advantage `cⁿ + cⁿ(1 − cⁿ)(1 − 2 ν x)`. For `0 < c < 1`, `n ≥ 1` and `ν x < 1/2` that is more than the `cⁿ` bounding every test on one chain. For two ideas with a fair-coin fallback no test on the pair has advantage above `cⁿ`. For any chain, if no test on one copy has advantage above `a ≤ 1`, no test on two independent copies has advantage above `1 − (1 − a)²` | **a second route can help, need not, and adds at most `a(1 − a)`.** That maximum is attained by the fading hop when the fallback never produces `x`; the gain is zero only when the fallback is a fair coin between the two candidates. It changes the constant, not the rate. Independence of the routes is built into the definition, not derived |

What this settles and what it does not:

- **Which quantity the law is about.** The chapter's `pᴺ` is "the probability of clean
  preservation across one hop" to the `N`th power. Read literally, as the chance of being
  passed on unchanged at every hop, it needs only that what a hop passes on depends on
  nothing but what it was told, and it is a *lower* bound on arriving intact
  (`Noisy.intact_prod_le_chain`): an idea can be lost and come back. What is proved is an
  upper bound of the chapter's shape on something else, distinguishability: the advantage
  after `n` hops is at most the product of the worst-case one-hop advantages
  (`Noisy.advantage_le_of_contracts`). The constant of that bound is the one-hop advantage
  `c`, not the chance `p` of clean preservation. The two are related one way only,
  `c ≥ 2p − 1`: a hop that preserves well cannot contract fast, while a hop that preserves
  nothing may not contract at all (`Noisy.swap_keeps_nothing`). The true advantage can be
  well below the bound (`Noisy.lazyCycle_two_hops`). For the fading hop arriving intact
  tends to `ν x`, not to zero (`Noisy.prob_fade_self`); when the fallback never produces
  `x`, the three quantities coincide and all equal `cⁿ`.
- **Noise or a mix of people.** Through one fixed chain of functions nothing fades for a
  given pair. But the fading hop is a mixture of functions (`Noisy.fade_eq_mixture`), and
  one function relay can lose half a repertoire per hop (`Limits.leak_iterate_length`).
  So measuring, hop by hop, how far above chance receivers pick the original out of a
  fixed line-up cannot separate "people are noisy" from "people differ" or from "the
  repertoire is being cut".
  Repeating the same chain with the same people, and seeing whether the outcome varies,
  can.
- **Whether real retellers forget in this sense** is an empirical question. Models of
  serial reproduction with Bayesian agents predict that a chain converges to the
  receivers' prior (Griffiths and Kalish 2007; Xu and Griffiths 2010), which is what
  chains of contracting hops do; whether one retelling contracts is not what those models
  state. I have those two only from search summaries, not from the papers.
- **Depth, size and redundancy.** In a tree, one receiver at depth `n`, tested on their
  own version, sits at the end of one chain, so the bound `cⁿ` applies to them whatever
  the size of the audience. A second route can raise that, by `cⁿ(1 − cⁿ)(1 − 2 ν x)` for
  the test above, and never by more than `a(1 − a)` when one route allows `a`
  (`Noisy.two_routes_le`): a second route changes the constant, not the rate. (For `k`
  independent routes the bound `1 − (1 − cⁿ)^k ≤ k cⁿ` is standard and not proved here.) What a whole generation of a tree jointly retains is the "broadcasting on
  trees" problem. For a symmetric binary channel on a tree with branching `d`, the root
  can be told from generation `n` with advantage bounded away from zero as `n` grows if
  and only if `d λ² > 1`, where `λ` is the second eigenvalue of the hop; at `d λ² ≤ 1`
  nothing is retained in the limit. The bound is Kesten and Stigum's; that it is the
  threshold in the symmetric binary case is attributed to Bleher, Ruiz and Zagrebnov
  (1995) and to Evans, Kenyon, Peres and Schulman (2000). For the fading hop on two ideas
  with a uniform fallback, `λ = c`. All of this paragraph's literature is from search
  summaries and memory, the papers were not read, and none of it is formalized here.
- **Routes and the chapter.** The chapter does not discuss routes; its picture is one
  chain. It is the library's first model that left no room for a second route to help
  (`Channel.exists_loss_ge` measures loss along the best single route).
- **Limits of the formal statement.** The chain law is an upper bound; it is attained by
  the fading hop and can be far from attained, and for hops whose one-hop constant is 1 it
  says nothing although distinguishability may still decay (`Noisy.lazyFour_two_hops`). `Contracts` is stated with a constant, not
  with Dobrushin's coefficient as a number. The set of ideas is finite. Tests are sets of outcomes (`Noisy.spread_chain_le` covers tests with values in
  an interval). There are no entropies. Nothing connects the budget `B` of a relay to the
  constant `c` of a hop, and no lemma identifies a `Channel.Relay` with a function hop.

Prior art: the contraction is classical. That the one-hop total-variation constant
(Dobrushin's coefficient) is submultiplicative along a chain is a textbook fact, the
total-variation case of the strong data-processing inequality; Doeblin's minorization is
the standard sufficient condition for it. In Lean, Mathlib has row-stochastic matrices, Markov kernels and
total variation of measures; a search of its source for "Dobrushin" and "Doeblin" found
nothing. A third-party project, `MarkovSemigroups`, lists a file `Doeblin.lean` described
as "Doeblin's condition, n-step mixing"; I did not read it and do not know whether it is
complete. The search was three queries. The statements here are elementary and on finite
sets; they are not a contribution to that literature.

Two questions survive as testable, and both belong to the book, not to the library:

1. *Depth versus size.* Deliver one text to the same number of receivers through a star,
   and through trees of depth 3 and 6, with and without access to the original. Does the
   excess over chance, of the share who pick the original out of a fixed line-up, shrink
   by at least a constant factor per hop? If it does, rerun the same chains with the same
   people: if outcomes repeat, the loss is in who the retellers are, not in noise. Does a
   second independent route help? The fading model says yes unless the fallback is a fair
   coin between the two candidates.
2. *Key before claim.* Annotate claim units and context units, run chains, estimate
   per-hop survival of each.

### Simulations ([`sim/README.md`](sim/README.md))

Six simulations probe what the theorems leave open. None of it is evidence about people.
In short:

- The chain law is exact for the fading hop and silent for hops that only move ideas
  locally once the space of ideas is large (one-hop constant 1); there distinguishability
  still decays, slowly, and close originals are confused long before distant ones.
- Distance from the original and distinguishability of originals come apart, and the way
  they come apart separates forgetting from drift.
- For one receiver the routes needed to hold a given advantage grow exponentially with
  depth. On a tree, simulation at depths 6 to 12 is consistent with the threshold the
  literature reports for the two-idea, fair-coin case (branching above `1/c²`) without
  locating it; when the fallback can never pass for the original the threshold is the
  branching-process one, `1/c`. Neither is machine-checked.
- Noisy retellers and the mix of fixed ones in `Noisy.fade_eq_mixture` give the same
  curves; rerunning the same chain separates them. The 30-chain caveat pilot can see a
  per-hop retention gap of 0.2, not 0.1.
- With a lexical distance, the budget needed for the book's own claims rises steadily, by
  about one bit per 0.05 of tolerance, and the claims are provably more compressible than
  unstructured points at tolerance 0.2 and below.
- A small language model used as reteller cut the text once at the first retelling, eroded
  conditions slowly for two more hops and then settled. It was noisy at the first pass, not
  a fixed function. Conditions survived about as well as claims, and the three losses of a
  claim were all in originals that stated it last (not statistically significant). That is
  a pilot of 32 chains run in four batches with one coder, and says nothing about people.

## 7. After the review: restricting the dials until something is excluded

The review's diagnosis was that nothing is excluded: every function is a complexity. The
modules added afterwards (eleven by now) restrict the systems and prove what then follows. Each item is
labelled with its real strength.

### Self-delimiting systems ([`Prefix.lean`](Complexity/Prefix.lean))

Restrict to unambiguous binary systems in which no description is a proper prefix of
another.

| result | statement | strength |
|---|---|---|
| `exists_prefix_iff` | `f` is the complexity of such a system **iff** `∑ₓ 2^(−f x) ≤ 1` | Kraft's inequality and its converse for arbitrary index sets. Classical. It is the representation theorem the first version lacked: it excludes functions |
| `exists_coding` | for every such `S` there is a `T` with `K_T(x) = ⌈−log₂ P_S(x)⌉` | coding theorem, existence form. Follows from the converse above |
| `coding_of_dominates` | if `U` dominates that `T`, then `K_U(x) ≤ ⌈−log₂ P_U(x)⌉ + c` | little more than the definition of domination unfolded: `T` is hidden behind an existential, so the hypothesis cannot be discharged without already having the conclusion, and nothing uses it. Kept for the record. For the universal prefix machine the conclusion is proved outright: see `Levin.levin` below |
| `pair`, `iterate`, `twoPart_card` | `K(x,y) ≤ K(x)+K(y)`; `K(fᵗx) ≤ K(x)+2 log t+1`; `K(x) ≤ K(πx)+⌈log₂ W⌉` | the additive bounds that are false for plain complexity hold here exactly, and the composed system is again self-delimiting |
| `not_exists_universal` | on an infinite set no system dominates all self-delimiting systems | invariance needs a further restriction (computability) |

### The effective layer ([`PrefixMachine.lean`](Complexity/Instances/PrefixMachine.lean), [`KraftChaitin.lean`](Complexity/KraftChaitin.lean), [`Levin.lean`](Complexity/Levin.lean), [`Conditional.lean`](Complexity/Conditional.lean), [`Symmetry.lean`](Complexity/Symmetry.lean), [`Semicomputable.lean`](Complexity/Semicomputable.lean), [`Guessing.lean`](Complexity/Guessing.lean), [`Plain.lean`](Complexity/Plain.lean))

Restrict further to **prefix machines**: partial recursive functions (Mathlib's
`Nat.Partrec.Code`) from bit strings to numbers whose domain is prefix-free. In this class
a universal member exists, and the conditional results above become unconditional.

| result | statement | strength |
|---|---|---|
| `pf_prefixFree`, `pf_eq_of_prefixFree` | every program has a prefix-free restriction, computable uniformly in the program, which changes nothing if the domain already was prefix-free | the standard construction (run in stages; reject an input once a comparable one has halted) |
| `U_isPrefixMachine`, `U_simulates`, `dominates` | `U` is a prefix machine and runs every prefix machine from a fixed prefix, so `K_U ≤ K_φ + c` | optimality for prefix complexity. Classical |
| `invariance` | two optimal prefix machines agree up to a constant | from the general invariance lemma. The restricted class is the one `not_exists_universal` shows to be necessary |
| `K_U_lt_top`, `P_pos` | every number has a `U`-program and positive probability | non-vacuity: the theorems are not about an empty machine |
| `K_pair_le` | `K(⟨x,y⟩) ≤ K(x) + K(y) + c` | subadditivity, **unconditional**. False for plain complexity (`Limits.lean`) |
| `K_map_le'`, `K_map_le` | for partial recursive `f`: `K(y) ≤ K(x) + c_f` whenever `f x = y` | computation creates no information (the algorithmic data-processing inequality). Classical; the proof is one line of universality once `(U ·).bind f` is seen to be a prefix machine |
| `K_map_equiv`, `K_fst_le`, `K_snd_le`, `K_pair_comm`, `K_pair_map_le` | computable bijections preserve `K` up to a constant; `K(x) ≤ K(⟨x,y⟩) + c`; `K(⟨y,x⟩) ≤ K(⟨x,y⟩) + c`; `K(⟨x, f x⟩) ≤ K(x) + c` | corollaries. The last says a computable function of `x` adds nothing to `x` |
| `K_U_le_log` | `K(x) ≤ 2 log₂(x+1) + c` | logarithmic upper bound, from a length-prefixed request list fed to the Kraft–Chaitin machine. The lower side for most `x` is the counting law (`card_le_two_pow_of_K_le`); the two are not combined into one statement |
| `condU`, `condK`, `condU_simulates`, `condK_le` | a universal conditional prefix machine (the s-m-n function supplies the condition to the prefix-free restriction of a program); `K(y \| a)` is complexity relative to it, and it is optimal among conditional prefix machines, uniformly in the condition | the definition the symmetry-of-information statement needs. Classical |
| `exists_dep_machine` | a prefix machine followed by a conditional prefix machine that is told the first output is again a prefix machine | the construction behind the next four rows; generalizes the pairing machine |
| `K_pair_le_add_condK`, `K_le_add_condK` | `K(⟨x,y⟩) ≤ K(x) + K(y \| x) + c` and `K(y) ≤ K(x) + K(y \| x) + c` | the **chain rule, easy half**. The reverse inequality is not proved (see below) |
| `condK_le_K`, `condK_map_le` | `K(y \| x) ≤ K(y) + c`; `K(f x \| x) ≤ c` for computable `f` | conditioning does not hurt; a computable function of the condition is free |
| `condK_le_length`, `K_twoPart_le` | if `e a` enumerates at most `2^(ℓ a)` elements (`e`, `ℓ` computable) then each element `y` has `K(y \| a) ≤ ℓ a + c` and `K(y) ≤ K(a) + ℓ a + c` | the **two-part code on `U`**: "micro ≤ macro + log W", with `log W` exact rather than doubled |
| `exists_condK_ge`, `card_condK_lt` | if the `2^(ℓ a)` elements are distinct, one has `K(y \| a) ≥ ℓ a`; fewer than `2^m` numbers have `K(y \| a) < m` | tightness of the conditional bound, by counting. True for every machine, so it says nothing special about `U` |
| `K_iterate_le`, `K_iterate_le_log` | for computable `f`: `K(fᵗx) ≤ K(x) + K(t) + c ≤ K(x) + 2 log₂(t+1) + c'` | the **logarithmic growth law on `U`**: a computable dynamics adds at most the information in the clock |
| `symmetry_of_information` | `K(⟨x,y⟩) = K(x) + K(y \| x*) ± c` with `x* = ⟨x, K(x)⟩`, both directions | **symmetry of information** (Levin, Gács, Chaitin), unconditional. Easy direction: a shortest program for `x` yields `x*`. Hard direction: Levin's request list for pairs, re-issued for each condition `⟨x, k⟩` with weights scaled by `2^(k−C)`; the weights fit when `k = K(x)`, and the Kraft–Chaitin decoder is prefix-free regardless (`KraftChaitin.machine_partrec₂`, `tsum_creq_le`) |
| `symmetry` | `K(x) + K(y \| x*) ≤ K(y) + K(x \| y*) + c` | the information `x` carries about `y` equals the information `y` carries about `x`, up to a constant |
| `K_macro_add_condK_le`, `card_K_lt_macro_add` | for computable `π`: `K(π x) + K(x \| (π x)*) ≤ K(x) + c`; in any set of microstates of one macrostate `a`, fewer than `2^m` have `K(x) + c < K(a) + m` | the **lower half of "micro = macro + log W"**: all but a fraction `2^(−d)` of `W` microstates have `K(x) ≥ K(a) + log₂ W − d − c`. The upper half for enumerable macrostates is `K_twoPart_le` |
| `micro_eq_macro_add_log` | for a family of macrostates with `2^(ℓ a)` microstates listed without repetition by a computable `e a`, and a computable `π` recovering the macrostate: every microstate has `K(x) ≤ K(a) + ℓ a + c`, and fewer than `2^m` have `K(x) + c < K(a) + m` | **"micro = macro + log W", both halves in one statement**. All but a fraction `2^(−d)` of the microstates lie within `d + 2c` of `K(a) + log₂ W` |
| `Upper.exists_approx`, `Upper.exists_machine_K_eq`, `Upper.prefix_complexity_iff` | call `f` approximable from above if it is the least value shown by a primitive recursive table. Every `K_φ` is; conversely if `∑ 2^(−f x) ≤ 1` then `f + 2` is exactly `K_M` for a prefix machine `M`; so `f + c` is a prefix-machine complexity for some `c` **iff** `∑ 2^(−f x) < ∞` | the **representation theorem for prefix machines**, the counterpart of `exists_binary_iff` and `exists_prefix_iff` one restriction further. Classical (Levin) |
| `Upper.K_U_le_of_summable` | `K_U ≤ f + c` for every such `f` | `K_U` is, up to a constant, the least function approximable from above with summable weights |
| `Upper.exists_primrec_table`, `Upper.exists_table_iff_re` | a computable table has the same limit as some primitive recursive table; `f` is such a limit iff `{(x, n) \| f x ≤ n}` is recursively enumerable (`REPred`) | "approximable from above" does not depend on the kind of table, and agrees with Mathlib's notion of a recursively enumerable set. `prefix_complexity_iff_of_computable` and `K_U_le_of_computable` restate the two theorems above for computable tables |
| `KraftChaitin.exists_machine` | a primitive recursive list of requests `(x, n)` with `∑ 2^(−n) ≤ 1` has a partial recursive prefix-free decoder giving each request a program of length `n + 1` | the effective converse of Kraft's inequality, with one bit of slack. The allocation is Shannon–Fano–Elias (an aligned half-length interval inside each request's own interval), which needs no free-list bookkeeping |
| `exists_coding_machine` | for every prefix machine `φ` there is a prefix machine `M` with `2^(−K_M x) ≤ P_φ x` and `K_M x ≤ n + 3` whenever `2^(−n) ≤ P_φ x` | `exists_coding` with the built system computable |
| `levin` | for `U`: `K(x) ≤ n + c` whenever `2^(−n) ≤ P(x)` | **Levin's coding theorem** (1974), unconditional |
| `P_le_two_pow_mul_wt` | `2^(−K x) ≤ P(x) ≤ 2^c · 2^(−K x)` (with `wt_K_le_P`) | algorithmic probability equals `2^(−K)` up to a constant factor |

What this does to the review's findings: "simplicity bias" was refuted as a statement
about description systems in general (`Limits.exists_complex_probable`) and is now a
theorem about one specific class. The framework did not supply it. The restriction to
computable self-delimiting systems did.

### Domination with a mechanism ([`Translation.lean`](Complexity/Translation.lean))

`Simulates 𝒯 S' S` says one translation from an admissible class `𝒯` carries
`S`-descriptions to `S'`-descriptions at constant extra cost. Invariance is then a theorem
about translators (`invariance_of_simulates`). The notion is strictly stronger than the
inequality: two systems with equal complexity functions, neither prefix-translatable into
the other (`exists_dominates_not_simulates`).

### The reuse gap ([`ReuseGap.lean`](Complexity/ReuseGap.lean))

How much does sharing parts buy, and what decides it?

- **Ceiling.** `treeK(x) + 1 ≤ 2^dagK(x)` in every algebra with one binary operation
  (`binTreeK_add_one_le_two_pow`). Reuse never buys more than an exponential.
- **Rigidity.** If the domain has an additive size `μ`, every constructible `x` has
  `treeK(x) = 2μ(x) − 1` (`binTreeK_add_one_eq`). In extensive domains (numbers under
  addition, strings, anything assembled from countable parts) tree complexity is size
  and nothing else; all differences between objects of one size are differences in reuse.
- **Typical gain is logarithmic.** Some binary string of each length `L` needs about
  `L / log L` steps even with reuse (`Str.exists_low_gain`), against `2L − 1` without.
  And not just one: if `a + (2 + 2a)·2^a + d < L`, fewer than `2^(L−d)` binary strings of
  any length cost at most `2^a` steps (`Str.card_cheap_lt`), so all but a fraction `2^(−d)`
  of the strings of length `L` cost more than about `L / (4 log₂ L)`. Until this round
  "typical" was claimed here with only the existence of one such string proved.
- **Support bound.** Give each object a finite set of atoms `σ`, at most one atom per
  generator, with `σ(x∘y) ⊆ σx ∪ σy`. Then `dagK(x) ≥ 2|σx| − 1`
  (`two_mul_card_support_le_binK`): `m` distinct atoms need `m` introductions and `m − 1`
  joins, shared or not.
- **Zero-gain criterion.** If some tree uses each atom once, reuse buys nothing
  (`binK_eq_binTreeK_of_le`). In the free semilattice (finite sets under union) DAG and
  tree complexity are both exactly `2|s| − 1` (`SetUnion.binK_add_one_eq`). A string with
  no repeated letter costs `2|w| − 1` either way (`Str.strK_add_one_eq_of_nodup`).
- **The gain is at most the multiplicity.** In an extensive domain,
  `(treeK+1)·|σx| ≤ μ(x)·(dagK+1)` (`gain_le_multiplicity`): sharing improves on the tree
  by at most the mean number of times an atom is repeated. For strings that is
  `|w| / #letters`.
- **Upper bound.** Binary exponentiation: `x^m` costs `2 log₂ m` steps beyond `x`
  (`MonoidGen.slK_pow_le`). So in the free commutative monoid a monomial with `k` atoms
  and exponents `eᵢ` costs at most `∑(2 log₂ eᵢ + 2) − 1` steps
  (`Monomial.slK_add_one_le`) against `2∑eᵢ − 1` nodes for the tree. With all exponents
  equal to `m`, the gain is at least `m / (log₂ m + 1)` and at most `m`: the multiplicity
  bound is attained up to a logarithm.
- **The two obstructions are not jointly tight.** Some monomial with exponents from `1`
  to `m` needs more than `n` steps whenever `n·((k+1)n²)ⁿ < mᵏ`
  (`Monomial.exists_slK_gt`), which is about `k log m / log(k log m)`. That exceeds
  `k + log m` once both `k` and `log m` are large. An earlier draft of this section conjectured
  `dagK = Θ(#atoms + log(max multiplicity))`; that conjecture is false, and the refutation
  is machine-checked: for every constant `C` some monomial with at least one atom and all
  exponents at least `1` costs more than `C · (#atoms + log₂(largest exponent))` (`Monomial.exists_slK_gt_mul`,
  with `k = 2^(2C+12)` atoms and exponents up to `2^k`).
- **Two corrections to those theorems.** At first both allowed the exponent `0`. The empty
  monomial cannot be built from the atoms at all, so its cost is `⊤` and it satisfied both
  statements trivially: as stated, they proved nothing. Requiring every exponent to be at
  least `1` was not enough for the second one: with `k = 0` atoms the condition is vacuous
  and the cost is again `⊤`. An independent review found that, with a checked trivial
  proof. `Monomial.exists_slK_gt_mul` now also states `0 < k`. The counting argument was
  sound both times; the statements were too weak to show it.
- **Shared squarings.** The binary method spends `2 log₂ m` steps on each atom. Straus's
  method (Straus 1964, as cited by Pippenger 1980) spends them once: tabulate the products of all nonempty
  sets of atoms (`2^k − 1` steps, `MonoidGen.poolK_subsetProds_le`), then read the
  exponents one binary digit at a time, squaring the running product and multiplying by
  one table entry (`MonoidGen.poolK_insert_prod_pow_le`). So `k` atoms with exponents
  below `2^L` cost fewer than `2^k + 2L` steps (`MonoidGen.slK_prod_pow_add_one_le`), and
  in groups of `g` atoms fewer than `(k/g + 1)(2^g + 2L)` (`Monomial.slK_add_one_le_grouped`).
  With `g = log₂ L` that is at most `3L(k / log₂ L + 1)` (`Monomial.slK_add_one_le_log`).
- **The worst case from both sides.** For `k = 2^j` atoms and exponents from `1` to `2^k`,
  one monomial needs more than `2^a` steps whenever `a + (j + 1 + 2a)·2^a < 4^j` and costs
  fewer than `(k/j + 1)(3k + 2)` (`Monomial.exists_slK_between`). That is between about
  `k² / (10 log₂ k)` and `3k² / log₂ k`: the order `k log m / log log m` is right when
  `k = log₂ m`, with a factor of 15 to 30 between the constants. For `k = 1024`: more than
  16,384 steps and fewer than 316,622 (`Monomial.exists_slK_between_1024`), where the
  binary method allows about two million.
- **The same for any shape.** With `k` atoms and exponents up to `2^L`, one monomial needs
  more than `2^a` steps whenever `k + 1 ≤ 2^b` and `a + (b + 2a)·2^a < kL`, and costs fewer
  than `(k/g + 1)(2^g + 2(L + 1))` for every `g` (`Monomial.exists_slK_between_general`).
  That is at least about `kL / (6 log₂(kL))` against about `3kL / log₂ L`, the same order
  whenever `log₂ L ≤ k ≤ L^c`, with a constant depending on `c`. For 4,096 atoms and
  exponents up to `2^1024`: more than 65,536 steps and fewer than 1,168,272
  (`Monomial.exists_slK_between_4096`), where the binary method allows about eight
  million.
- **Many atoms: group the digits instead.** Straus groups the atoms and is good when
  exponents are long. With many atoms, group the binary digits of the exponents: within a
  block of `h` digit positions, multiply together the atoms whose digits agree (at most
  `2^h` classes), then each digit position is a product of classes
  (`MonoidGen.pk_digit_block_le`), and Horner's rule finishes in `2L` steps
  (`MonoidGen.pk_insert_prod_pow_of_digits_le`). A monomial costs at most
  `k + (L/h + 1)(k + h·2^h) + 2L` steps (`Monomial.slK_le_digits`), which with
  `h = ½ log₂ k` is about `3k + 2L + 4kL / log₂ k` (`Monomial.slK_le_many_atoms`).
- **Every shape.** One monomial carries four bounds at once
  (`Monomial.exists_slK_every_shape`): more than `2^a` by counting, at least `2k − 1` by
  support (`Monomial.two_mul_le_slK_add_one`), and at most the two upper bounds above.
- **The order, as theorems.** Write `κ = ⌊log₂ k⌋` and `ℓ = ⌊log₂ L⌋`, with `k ≥ 4` atoms
  and exponents up to `2^L`, `L ≥ 2`.
  - Every monomial costs at most `12kL/(κ + ℓ) + 6(k + L)` steps
    (`Monomial.slK_le_order`, for exponents below `2^L`).
  - Some monomial costs more than `kL / (8(κ + ℓ + 2))` (`Monomial.exists_slK_gt_order`).
  - Every monomial with all exponents at least `1` costs at least `2k − 1`
    (`Monomial.two_mul_le_slK_add_one`).
  - Some monomial costs more than `L` (`Monomial.exists_slK_gt_exponent`).

  So the hardest monomial costs `k + L + kL / log(kL)` up to a constant, for every `k`
  and `L`. The four bounds are machine-checked with these explicit constants. By my
  arithmetic, which is not machine-checked, the upper side is less than 170 times the
  largest lower bound for all sizes and about 100 times for large ones; I have not tried
  to tighten it. An earlier draft made the whole comparison by hand.
- **Boolean functions.** The support bound specializes to the trivial circuit lower bound:
  `m` essential variables need `m` inputs and `m − 1` gates
  (`Circuit.two_mul_card_essential_le`). Nothing stronger is claimed for any explicit
  function.
- **The same table, for circuits.** Shannon's construction (1949): build
  every function of `k` chosen variables once (`Circuit.poolK_dependsOn_le`), then select
  among table entries with the other `n − k` variables at four gates per selection
  (`Circuit.poolK_insert_select_le`). Every function of `n ≥ 1` variables costs at most
  `n + 2^(2^k)·(5 + 2^k(4k + 7)) + 4·2^(n−k)` steps (`Circuit.circuitK_le_shannon`). With
  the counting bound, the hardest function costs between about `2ⁿ/4n` and `8·2ⁿ/n`
  (`Circuit.exists_circuitK_between`). For 32 variables: more than 67 million steps and at
  most 1,098,186,784 (`Circuit.exists_circuitK_between_32`), where the normal form allows
  about 580 billion.
- **The same table, for strings.** Build every nonempty binary string of length at most
  `g` (`Str.poolK_blocks_le`), then concatenate blocks, one step per block
  (`Str.poolK_insert_le_div`). Every binary string of length `L` costs at most
  `g·2^g·2g + L/g` steps (`Str.strK_le_blocks`), so the hardest costs between about
  `L / (4 log₂ L)` and `2L / log₂ L` (`Str.exists_strK_between`). For a million letters:
  more than 16,384 steps and at most 163,840 (`Str.exists_strK_between_million`), against
  about two million without sharing.

Read together: **reuse pays for repetition**. The gain is bounded by
`min(2^dagK / dagK, μ/|σ|)`, it is zero when nothing repeats, and idempotent operations
remove it because repeating an argument produces nothing new.

**What sharing buys, by the laws the operation obeys.** The same results arranged as a
second ladder. Costs count steps; "without" rebuilds every part each time it is used.

| Law added | Example | Without sharing | With sharing, cheapest | With sharing, dearest |
|---|---|---|---|---|
| none | binary trees with `n` pairings | `2n + 1`, whatever the shape (`Comb.binTreeK_tree`) | a perfect tree of depth `d` (`2^d − 1` pairings) costs `d + 1` (`Comb.cost_perfect`, `Comb.binTreeK_perfect`) | a comb costs `n + 1` and no tree costs more (`Comb.binK_comb`, `Comb.cost_le`); in general exactly the number of distinct subtrees (`Comb.cost_eq_card_sub`) |
| grouping does not matter | strings of length `L` over two letters | `2L − 1` (`Str.treeK_eq`) | a block repeated `2^k` times costs `k` more than the block; nothing of length `L` costs less than about `log₂ L` (`Str.strK_pow_two_pow_le`, `Str.length_mul_two_le`) | about `L / log L` up to a constant, and most strings are like that (`Str.strK_le_blocks`, `Str.card_cheap_lt`) |
| order does not matter either | products of powers of `k` variables, exponents up to `2^L` | twice the total degree minus one, up to about `2k·2^L` | at least `2k − 1`, and more than `log₂` of the degree (`Monomial.two_mul_le_slK_add_one`, `Monomial.sum_mul_two_le_two_pow`) | `k + L + kL / log(kL)` up to a constant (`Monomial.slK_le_order`, `Monomial.exists_slK_gt_order`) |
| repeating changes nothing | sets of `m` elements under union | `2m − 1` | `2m − 1` | `2m − 1` (`SetUnion.binK_add_one_eq`) |

With no laws, sharing can save almost nothing or almost everything, and the shape
decides. Once grouping stops mattering, every long object repeats short blocks, so the
dearest cost drops from `n` to about `n / log n`. Once order stops mattering too, an object
is its exponents, and the cost falls to about the number of their digits. Once repeating
changes nothing, size disappears and so does the saving. The "about" sizes are read off
the theorems by hand.

**In three populations the worst case is the counting bound.** The hardest object costs,
up to a constant between 8 and 32, what the general counting law
(`Sig.card_le_of_dagK_le`) says it must: `log N / log log N` steps for a population of `N`
objects.

| Population | `N` | Hardest object, lower | Upper | Known as |
|---|---|---|---|---|
| binary strings of length `L` | `2^L` | `L / (4 log₂ L)` | `2L / log₂ L` | Berstel and Brlek 1987: `Θ(n / log_σ n)` for word chains |
| monomials, `k` atoms, exponents up to `2^k` | `2^(k²)` | `k² / (10 log₂ k)` | `3k² / log₂ k` | Straus 1964; Pippenger 1980 gives the exact asymptotics |
| Boolean functions of `n` variables | `2^(2ⁿ)` | `2ⁿ / 4n` | `8·2ⁿ / n` | Shannon 1949; Lupanov 1958 gives `(1 + o(1))·2ⁿ/n` |

The three upper bounds are one construction: a shared table of everything small, then one
step per use. The literature calls the phenomenon the **Shannon effect**: the hardest
object of a class costs asymptotically what almost all of them cost. Every row is a known
theorem with better constants than here. The approximate forms in the table are read off
the exact inequalities in the Lean theorems and are not themselves machine-checked. They
are asymptotic: at the worked sizes the proved bounds are larger, for example 163,840
against `2L / log₂ L ≈ 104,858` for strings of length `2^20`.

**It is not a general law** (`SetUnion.counting_not_tight`). In the free semilattice on `k`
atoms the hardest object costs `2k − 1` by the support bound, while counting over the
`2^k − 1` nonempty sets can only show about `k / log₂ k`. For every constant `C`, from
some `k₀` on, the true cost is above `C` times anything the counting law yields. (The
first version said "for some `k`", which `k = 1` satisfies trivially; the review caught
it. The same flaw was in `Comb.counting_misses_depth`, fixed the same way.) An earlier draft of
this section listed "a general theorem that the counting bound is attained" as open; it is
false as stated.

**Depth, of which growth is a shadow** (`Binary.depth_add_one_le`). Any `φ` that is `0`
on generators and grows by at most one per operation, `φ(x∘y) ≤ max(φx, φy) + 1`, is a
lower bound on cost with sharing. One such `φ` is `⌈log₂ size⌉` for any subadditive size,
which gives the growth bound back (`Binary.clog_add_one_le`). Where the operation is not associative it can be far larger: for binary
trees it is the height. A comb-shaped tree with `n` nodes costs exactly `n + 1` steps
(`Comb.binK_comb`), while support gives `1`, growth gives `log₂(n + 1)`, and for every
constant `C` the cost eventually exceeds `C` times anything counting over all trees with
`n` nodes can show (`Comb.counting_misses_depth`).

**The list of obstructions is not complete** (`Comb.obstructions_incomplete`). Support,
depth and counting are each a lower bound and each binds somewhere: support in the free
semilattice, depth for combs and for powers of one generator, counting for strings,
circuits and dense monomials. Last round I left open whether the largest of them always
gives the order of the hardest object. It does not. In binary trees nothing is equal by
accident, so a tree costs exactly its number of distinct subtrees
(`Comb.cost_eq_card_sub`; an earlier draft of this paragraph said so with only "at least"
proved). With the same number of nodes that runs from logarithmic to linear: a perfect
tree with `2^d − 1` nodes costs `d + 1` steps (`Comb.cost_perfect`), a comb with `n` nodes
costs `n + 1`. And for every constant `C` there is a tree with one atom whose
cost exceeds `C` times its depth bound and `C` times anything counting can show. The
witness is a bush: a complete tree of depth `d` with a different chain at each leaf. It
has fewer than `6d·2^d` nodes, height at most `3d + 1`, and at least `d·2^d` distinct
subtrees (`Comb.card_sub_bush`). In an algebra with relations, "the number of parts that
must really be built" has no such simple description; finding it for one explicit Boolean
function is the circuit lower bound problem.

**In a monoid with finitely many generators, sharing always saves a logarithm**
(`MonoidGen.slK_list_prod_le_blocks`). With `σ` generators, a product of `L` generators
costs at most `g·σ^g·2g + L/g` steps for every block length `g`, which is about
`2L / log_σ L`. Without sharing the cost is exactly `2L − 1` when size is additive
(`Binary.binTreeK_add_one_eq`). So every large object gains a factor of order `log L`
from sharing, and among binary strings most gain no more (`Str.card_cheap_lt`). This is
the Berstel–Brlek bound, carried to any such monoid.

Both conditions are needed. This paragraph used to be headed "where size is additive",
which is false: binary trees have an additive size (the number of leaves) and a comb gains
less than a factor of 2, `n + 1` steps against `2n + 1` (`Comb.binK_comb`,
`Comb.binTreeK_comb`). Associativity is what lets a product be cut into blocks. And with
unboundedly many generators a string with no repeated letter gains nothing
(`Str.strK_add_one_eq_of_nodup`). The independent review found this one.

All of this is elementary, and none of it is new mathematics.

### Complexity cannot be guessed ([`Guessing.lean`](Complexity/Guessing.lean))

Symmetry of information conditions on `x* = ⟨x, K(x)⟩`. The condition cannot be weakened
to `x`.

| Lean name | Statement | What it is |
|---|---|---|
| `Guessing.exists_wrong_guess` | along a computable injective sequence `a`, if a computable table shows at most `N` different values for each `n`, then for some `n` none of them is `K(a n)` | **no bounded list of guesses contains the complexity.** Induction on `N`, striking one guess per round: find guesses `vᵢ ≥ 2i + 2`, request a description of length `vᵢ − 1 − i`, and use minimality of `K_U` (`Upper.K_U_le_of_computable`) to make `vᵢ` wrong from some stage on |
| `Guessing.K_U_not_computable` | no computable `f` has `f x = K(x)` for all `x` | the case `N = 1`. The library had this only for plain complexity |
| `Guessing.condK_K_unbounded` | for every `c` some `x` has `K(K(x) \| x) > c` | the qualitative form of a theorem of Gács. The programs of length at most `c` give at most `2^(c+1)` guesses. Gács's logarithmic lower bound is **not** formalized |
| `Guessing.condK_star_add_lt` | for every `c` there are `x, y` with `K(y \| x*) + c < K(y \| x)` | conditioning on `x` is strictly weaker than conditioning on `x*` |
| `Guessing.not_symmetry_bare` | no `c` gives `K(x) + K(y \| x) ≤ K(⟨x,y⟩) + c` for all `x, y` | **symmetry of information fails for the bare condition**, by more than any constant. The other direction, `K(⟨x,y⟩) ≤ K(x) + K(y \| x) + c`, holds (`K_pair_le_add_condK`) |
| `Conditional.condK_chain_le` | `K(y \| x) ≤ K(z \| x) + K(y \| ⟨x, z⟩) + c` | the **chain rule for conditional complexity**, from a conditional prefix machine that reads a program for `z` and then one that uses it (`Conditional.exists_cond_dep_machine`) |
| `Guessing.condK_le_condK_star_add`, `Guessing.symmetry_bare_log` | `K(y \| x) ≤ K(y \| x*) + K(K(x) \| x) + c`, hence `K(x) + K(y \| x) ≤ K(⟨x,y⟩) + 2 log₂(K(x) + 1) + c` | **the defect is small**: symmetry with the bare condition fails by more than any constant and by at most about `2 log₂ K(x)`. Classical; Milovanov's library has a related prefix statement with a logarithmic slack (`KP_mutual_symm_le_of_complexity_budget`), so this is not new in Lean either |

### Just outside each law ([`Plain.lean`](Complexity/Plain.lean))

The ladder claims, for each law, a stage where it holds and a failure one stage earlier.
Three of those failures had been asserted without a proof.

| Lean name | Statement | What it is |
|---|---|---|
| `Plain.exists_ambiguous_binary` | on any type there is a binary system (cost = length) in which every object has complexity `0` | **counting needs unambiguous descriptions**: the empty description realizes everything. `card_le_of_K_lt` assumes a description realizes at most one object, and this is why |
| `Plain.P_plain_eq_top` | for the plain universal machine `Kolmogorov.U`, the algorithmic probability of every number is `∞` | **the coding theorem cannot be stated for the plain machine**: a program that ignores its input can be padded, and the `2ⁿ` paddings of length `n` weigh `2⁻ⁿ` each. The textbook reason for prefix machines |
| `Plain.not_subadditive_plain` | no `c` gives `C(x, y) ≤ C(x) + C(y) + c` for the plain machine | **plain complexity is not subadditive**, stated literally. The ladder used to cite the counting lemma `Limits.not_forall_K_obj_le` for this |
| `Plain.card_le_two_pow_of_prefixFree` | in an unambiguous prefix-free binary system at most `2ⁿ` objects have complexity at most `n` | the counting law at the self-delimiting stage, stated for description systems. The ladder used to cite `Thermo.card_le_two_pow_of_K_le`, whose hypothesis is a Kraft sum over all descriptions and does not apply directly |
| `Plain.not_coding_self_delimiting` | one unambiguous prefix-free binary system in which, for every `c`, some object has probability above `2^c · 2^(−K)`: the number `n` has `2ⁿ` descriptions of length `2n + 1` | **"complex implies improbable" fails among self-delimiting systems, within a single system.** The ladder used to cite `Limits.exists_complex_probable`, which needs a different system for each constant |
| `Plain.dominated_not_all_partrec` | the plain universal machine dominates description methods that are not partial recursive | the class dominated by `U` is strictly larger than the computable methods; an earlier line said "exactly" |
| `Plain.not_chain_rule_plain` | with plain conditional complexity `condC` from a universal conditional machine, no `c` gives `C(x, y) ≤ C(x) + C(y \| x) + c` | **the chain rule fails for plain complexity, even its easy half**. For prefix complexity that half holds (`K_pair_le_add_condK`). Follows from `Limits.not_forall_K_obj_le` and `C(y \| x) ≤ C(y) + c` |

Prior art, checked against the clone of Milovanov's library after proving these, which is
the wrong order: it has a **stronger** form of the third, `not_plainK_pair_le_add_single_log`
(Shen, Uspensky and Vereshchagin, Exercise 17): for plain complexity not even
`C(x, y) ≤ C(x) + log C(x) + C(y) + c` holds. The statement here and
`Limits.not_forall_K_obj_le` are weaker than that. A search of its source for the infinite
plain a priori probability found nothing. All three are textbook remarks.

### Comparison with `kolmogorov-complexity-lean`

Alexey Milovanov's Lean 4 library (`AlexeyMilovanov/kolmogorov-complexity-lean`, commit
`77b47ac` of 23 November 2026, Lean v4.35.0) formalizes Shen, Uspensky and Vereshchagin's
book. It has 1,811 files and about 800,000 lines; this library has 35 and about 12,600. Its
statements were read from a clone of the source by a subagent, which copied the signatures
and searched for `sorry` and `axiom` (none found); I spot-checked the main ones. The
proofs were not read and nothing was compiled. "Not found" means not found by searching
names and statements, not by reading everything.

| Topic | There | Here |
|---|---|---|
| Universal prefix machine | concrete, on `Nat.Partrec.Code`; theorems hold for **every** optimal prefix machine (`IsOptimalPrefixConditional U`), on bit strings | concrete, on `Nat.Partrec.Code`; theorems for the one machine `U`, on numbers. Theirs is more general |
| Kraft and Kraft–Chaitin | Kraft's inequality; an online free-list allocator giving each request a code of exactly the requested length (`exists_online_prefixFree_of_kraft_le_one`) | Kraft's inequality for arbitrary index sets; a Shannon–Fano–Elias allocator with one bit of slack. Theirs is sharper |
| Coding theorem | `2^(−K)` against the a priori measure, against a universal semimeasure, and conditionally | against the a priori measure of a prefix machine only |
| Symmetry of information | `K(x,y) = K(x) + K(y \| x, K(x)) ± c`, both directions (`KPPair_symmetryOfInformation_staged`), and relativized to a third string (`KPCondPair_symmetryOfInformation_staged`) | the same statement, unrelativized (`symmetry_of_information`). **Not new** |
| Which functions are prefix complexities | every finite Kraft sum at most 1 and a recursively enumerable upper graph; exact realization as `F + 1` (`exists_exact_prefixDecompressor`) | the same, realized as `F + 2`. **Not new**, and theirs has the better constant |
| Two-part code and counting | for finite sets, with the complexity of the set (`KP_le_setComplexity_add_condKP`, `fraction_deficiency_gt_le`) | for computably enumerated families (`micro_eq_macro_add_log`) |
| `K(K(x) \| x)` | for **plain** complexity, the tight bound `log n ± c` by the Kalinina–Bauwens game (`exists_condK_cVal_within_log_length`). For prefix complexity: not found | for **prefix** complexity, unbounded, with no rate (`condK_K_unbounded`). Theirs is quantitative; the two are about different complexities |
| `K(y \| x)` against `K(y \| x, K(x))`; failure of symmetry with the bare condition | not found; a docstring remarks that the bare lower bound "is not the standard prefix symmetry theorem" | proved (`condK_star_add_lt`, `not_symmetry_bare`) |
| Non-computability | plain complexity, including no unbounded computable lower bound. For prefix complexity: not found | prefix complexity (`K_U_not_computable`), and no bounded list of guesses (`exists_wrong_guess`). No lower-bound form |
| General description systems, the refuted and empty laws, the reuse gap | description modes for bit strings: an arbitrary relation between descriptions and objects, cost = length, with regularity restrictions that give plain, prefix, monotone and decision complexity (`GeneralScheme`: `IsDescriptionMode`, `modeComplexity`, `IsOptimalDescriptionMode`). An earlier version of this row said "not found"; a review found it. Not found: arbitrary costs, "every function is a `K`", the refuted and empty laws, anything on reuse (no match for addition chains or Straus) | sections 1 to 6 and the reuse gap above |

So the effective layer here is a small, independent re-proof of results that library
already has in greater generality, and its general scheme of description modes overlaps
the starting point of sections 1 to 6. Three things I could not find there: the
failure of symmetry for the bare condition, the non-computability of prefix complexity,
and the bounded-guess theorem behind both. Those three are textbook mathematics too.

### Prior art for the reuse results

Searched on 24 November 2026: about a dozen web searches by me, then a subagent that
opened the sources. I spot-checked the two CSLib theorems against the source files.
"Not found" is a negative result from a limited search.

| Result here | The mathematics | Formalized elsewhere? |
|---|---|---|
| Hardest string: `Str.strK_le_blocks`, `Str.exists_strK_between` | Berstel and Brlek, "On the length of word chains", *Inf. Process. Lett.* 26 (1987): the worst case over words of length `n` on `σ` letters is `Θ(n / log_σ n)`, as stated by Bannai et al., "The smallest grammar problem revisited". Brlek's 1988 notes give the constant `1 + ε` | not found. Hucke (arXiv 2609.12106) formalizes straight-line grammars in Lean 4, for a lower bound on the Greedy compressor, without this bound |
| Hardest monomial: `Monomial.slK_add_one_le_grouped`, `Monomial.exists_slK_between` | Straus, "Addition chains of vectors", *Amer. Math. Monthly* (1964); Yao (1976) for several powers of one base; Pippenger (1980): `L(p, q, N) = min{p, q}·log N + H/log H + o(H/log H)` with `H = pq·log(N + 1)`, for `p = (N+1)^{o(q)}` and `q = (N+1)^{o(p)}`. Read from the abstract and from Bernstein's survey; the papers themselves could not be opened | not found. `coq-addition-chains` (Castéran and Bertot) proves chain algorithms for `x^n` correct, with no length bounds and no vectors |
| Hardest circuit: `Circuit.circuitK_le_shannon`, `Circuit.exists_circuitK_between` | Shannon (1949); Lupanov (1958) gives `(1 + o(1))·2ⁿ/n` | **yes, and sharper.** CSLib, `Cslib/Computability/Circuit/Boolean/Shannon.lean` (`exists_hard_function`: more than `2ⁿ/n` gates for large `n`) and `Lupanov.lean` (`exists_circuit`: at most `(1 + ε)·2ⁿ/n`), by Samuel Schlesinger. A subagent reported from the repository's history that these landed in September 2026 and that the lower bound specializes a version generic over finite carriers; I checked only the two Boolean files. Compared with those, the lower constant here is 4 times worse and the upper constant 8 times worse, in a different basis (NAND, inputs counted) |
| The pattern "hardest = counting bound" | the **Shannon effect**, named by Lupanov (1970) and proved measure by measure: circuits, formulas, straight-line programs for finite languages (Goodrich, Ladner and Fischer 1977), regular expressions (Serna 1989) | no general criterion found, in mathematics or in a prover |
| `SetUnion.counting_not_tight` | elementary; not found stated, and not searched for specifically | not found |
| `Binary.depth_add_one_le` | folklore: a circuit is at least as large as it is deep | not searched for |
| `Comb.cost_eq_card_sub`, `Comb.obstructions_incomplete` | the cost of a tree with sharing is the size of its minimal DAG, the number of distinct subtrees. Stated without proof as standard in the literature (for example "Investigations into Proof Structures", arXiv 2304.12827); one search found no machine-checked version. The setting is the common subexpression problem (Downey, Sethi and Tarjan 1980; Flajolet, Sipala and Steyaert 1990 for the average case, which I could not open). The bush example is elementary and I did not find it stated | not found |
| what decides compressibility in general | Thumm and Weiß, "Efficient Compression in Semigroups" (STACS 2026): a class of finite semigroups admits efficient straight-line programs exactly when it avoids three named obstructions. Read from the abstract only | not found |
| Assembly index as straight-line cost | Bieniawski (arXiv 2608.19228) reports that the assembly index of a string **equals** the size of its smallest straight-line program, citing Masierak (2026), and that for `a^N` it is the shortest addition chain | not found |

So the circuit results of this section are a weaker duplicate of CSLib. The string and
monomial results are textbook mathematics that the search did not find formalized. Nothing
in this section is new mathematics.

### Still open

- **The additive laws for `U` are closed.** Subadditivity, monotonicity under computable
  maps, the chain rule in both directions (symmetry of information), the two-part code in
  both directions (`micro_eq_macro_add_log`) and the logarithmic growth law are all proved
  for the universal prefix machine, and the class of prefix-machine complexities is
  characterized (`Upper.prefix_complexity_iff`).
- **`K(y | x)` versus `K(y | x*)`: bounded on both sides.** The gap exceeds every constant
  (`Guessing.condK_star_add_lt`) and is at most `K(K(x) | x) + c ≤ 2 log₂(K(x) + 1) + c`
  (`Guessing.condK_le_condK_star_add`, `Guessing.condK_K_le_log`). How close to that
  logarithm it actually gets is not formalized here. For plain complexity
  the tight bound `log |x| ± c` is formalized in Milovanov's library, whose source
  attributes the result to Gács and the game proof to Kalinina and Bauwens.
- **Approximable from above** now has three equivalent forms: the limit of a primitive
  recursive table, the limit of a computable table (`Upper.exists_primrec_table`), and a
  recursively enumerable upper graph `{(x, n) | f x ≤ n}` in Mathlib's sense
  (`Upper.exists_table_iff_re`). Still unconnected: `micro_eq_macro_add_log` and the
  abstract `Prefix.twoPart_card`, whose macrostate map is arbitrary.
- **The exact constant for monomials.** The order of the hardest monomial is settled for
  every shape, `k + L + kL / log(kL)`, with machine-checked constants that differ by a
  factor below 170 (`Monomial.slK_le_order`, `Monomial.exists_slK_gt_order`). Pippenger (*On the evaluation of powers and
  monomials*, SIAM J. Comput. 1980) gives the exact asymptotics:
  `L(p, q, N) = min{p, q}·log N + H / log H` plus lower-order terms, with
  `H = pq·log(N + 1)`, under growth conditions on `p`, `q`, `N`. Read from the abstract and
  a survey, not from the paper; not formalized. The two constructions here (grouping
  atoms, grouping digits) are the standard ones as far as I know, but I did not read
  Pippenger's proof and cannot say how close they are to it.
- **Boolean functions.** Small support and no additive size, so both obstructions are
  silent beyond the trivial bound. The gap there is formula size versus circuit size,
  which is open in complexity theory.
- **What decides the cost in general.** Not any short list of simple obstructions: support,
  depth and counting are jointly insufficient (`Comb.obstructions_incomplete`). In a free
  algebra the answer is the number of distinct parts. For finite semigroups, Thumm and
  Weiß (STACS 2026) characterize which classes admit short straight-line programs at all.
  Nothing general is claimed here beyond the counterexamples.
- **Prior art for this section.** The mathematics is textbook throughout, and the
  formalization is **not the first in Lean**; see the comparison below. Earlier work in
  other systems: the Kraft inequalities for prefix-free complexity in HOL4 (Catt and
  Norrish, CPP 2021), Kraft–Chaitin in Isabelle, synthetic Kolmogorov complexity in Coq
  (ITP 2022). Nothing in the effective layer of this library should be described as a
  first formalization.
- The machine's outputs are natural numbers, its program index is read in unary, and the
  constants are whatever the constructions give. None of this affects the statements, which
  are up to additive constants.

## Status

**Proved.** Every theorem in the library, including those in `Limits.lean` that refute
earlier claims and those of section 7. `Audit.lean` checks every declaration (1673, of
which 1255 are theorems including generated ones; 36 module files and the root file,
13,870 lines).

**Not established.** That any real domain satisfies a theorem's hypotheses. Novelty of
the pieces not found by the prior-art search. Any empirical claim.

**Scope.** Description-type complexity only. Measures of organization (effective
complexity, depth) appear as definitions without theorems; statistical complexity has one
(`Causal.K_eq_ncard`).
Criticality, emergence and uniform complexity classes are outside it.

## Build and audit

```bash
./lake.sh build
```

```bash
./lake.sh env lean Audit.lean
```

`lake.sh` uses a system `lake` if one is on `PATH`; otherwise it runs elan through an
ephemeral `nix shell` with a toolchain kept in `./.elan`. `./.lake` (≈7.5 GB) and
`./.elan` (≈3 GB) are git-ignored.

## File map

```
Complexity/
  Basic.lean         description systems, K, fidelity, simulations
  CostAlgebra.lean   cost algebras; ℕ∞ and ℝ≥0∞
  Counting.lean      counting law, binary systems, Hartley
  Metric.lean        paths, dist, triangle inequality, potentials, Moore bound
  Generative.lean    signatures, terms, tree complexity, Bellman fixed point
  Reuse.lean         pools, DAG complexity, copying is free, logarithmic law
  Growth.lean        counting for finitely generated systems with reuse
  Binary.lean        generators plus one binary operation
  Invariance.lean    domination, invariance, interpreters
  Profile.lean       multi-resource profiles; depth and sophistication (definitions)
  Thermo.lean        partition functions, Kraft counting
  Dynamics.lean      iterate system (see its review note)
  Laws.lean          the laws in one file
  Limits.lean        what the framework does not say; refutations; corrected forms
  Translation.lean   simulation by admissible translations; invariance; no universal system
  Prefix.lean        self-delimiting systems: Kraft and converse, coding, additive laws
  ReuseGap.lean      ceiling on reuse; rigidity in extensive domains; support bound; zero gain
  KraftChaitin.lean  effective converse of Kraft's inequality: a computable decoder
  Levin.lean         Levin's coding theorem for the universal prefix machine
  Conditional.lean   conditional prefix complexity; chain rule, two-part code, growth law on U
  Symmetry.lean      symmetry of information; micro = macro + log W
  Semicomputable.lean  which functions are prefix-machine complexities; K_U is the least
  Guessing.lean      no bounded list of guesses contains K; K(K(x)|x) unbounded; bare symmetry fails
  Plain.lean         failures one stage early: ambiguous counting, infinite plain probability, no plain chain rule
  Lossy.lean         landing within a tolerance: load, budget against tolerance (covering numbers), what depth forces
  Noisy.lean         hops as stochastic matrices: one-hop bounds on advantage multiply along a chain of noisy hops (forgetting hops as the special case); one chain of functions is all-or-nothing; what a second route can add
  Instances/
    Kolmogorov.lean  Shannon.lean  Circuit.lean  Monoid.lean  CoarseGraining.lean
    Causal.lean      Regulator.lean  Learning.lean  Channel.lean
    PrefixMachine.lean   universal prefix machine: optimality, invariance, subadditivity
Audit.lean           axiom audit of every declaration
sim/                 six simulations of the retelling model, with a report (sim/README.md)
```
