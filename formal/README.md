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

[Section 7](#7-after-the-review-restricting-the-dials-until-something-is-excluded) is
later work: the dials restricted to self-delimiting systems, where a representation
theorem and the additive laws do hold, and then to computable ones, where a universal
prefix machine exists and Levin's coding theorem is proved for it.

---

## 1. What the review found

### Refuted (the first version said these; they are false)

| claim | what is true | evidence |
|---|---|---|
| `K(fᵗx) ≤ K(x) + log t + c` for the universal machine, "classical" | False for plain Kolmogorov complexity, for the library's own `U` and a primitive recursive `f`. Two description lengths were added with no delimiter. Correct forms: `+ O(log log t)` more, or a self-delimiting description of the state | `Limits.not_iterate_bound_kolmogorov`; correct form `Limits.exists_binary_iterate` |
| `K(micro) ≤ K(macro) + ⌈log₂ W⌉ + c` for the universal machine | False for the same reason | `Limits.not_twoPart_bound_kolmogorov`; correct form `Limits.exists_binary_twoPart` |
| "typical microstates attain" `K(macro) + log₂ W` | Not proved. The lower bound proved is `log₂ W − c`, with no `K(macro)` term; the upper bound holds by construction of the two-part cost | `CoarseGraining` review note |
| "complex implies improbable"; frequency falls off exponentially in complexity | Not a law of description systems: prefix-free systems exist where objects of complexity `n+1` have probability ½. The real result (simplicity bias) rests on Levin's coding theorem for universal prefix machines, which was not in the reviewed version and is proved in section 7 (`Levin.levin`) | `Limits.exists_complex_probable` |
| "every lower bound is a potential" | The converse is what is proved. A three-node counterexample exists | reviewer proof, summarized in `Metric` review note |
| measures agree "exactly when" each system simulates the other | Only "object-fixing simulation ⇒ domination" is proved. As worded, both directions have counterexamples | `Invariance` review note |
| a budget below `|p|` plus the claim's load "cannot carry both" (*Lossy*) | `load_le_add_of_prefix` is an upper bound; it implies no such thing | `Channel` review note |
| loss "scales with cascade depth" as a result of the model | It is the hypothesis `lam ≤ w e`. Under the budget model alone, a chain loses what its tightest hop loses, at any length | `Limits.relay_iterate_saturates` |

### Empty (true, but saying nothing at the generality claimed)

- **"Every measure is this infimum for some dial setting."** Every function into a
  complete lattice is `K` of an unambiguous description system
  (`Limits.exists_system_K_eq`). The same holds at the other two levels: any `d` with
  `d a a = 0` and the triangle inequality is a generative distance
  (`Limits.dist_complete_eq`), and any function is a tree or DAG complexity over a large
  enough signature.
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
the circuit-counting bound and of the generic reuse laws. The reviewer rates the
mathematical items as short generalizations. The search was about 55 queries; absence
from it is not proof of novelty.

### Held

- **Formal integrity.** All declarations of the library, not a sample, depend only on
  `propext`, `Classical.choice` and `Quot.sound` (`#audit_library` in
  [`Audit.lean`](Audit.lean)). No reviewer found a Lean statement that is false or true
  only by a junk value.
- **The counting lemma** (`card_le_of_K_lt`) and its binary form. Reused by the
  Kolmogorov, learning, channel, coarse-graining and regulator instances.
- **The level-2 theory**: DAG ≤ tree, copying is free, the logarithmic law, weak duality,
  and the finitely generated counting bound. Circuits, addition chains and string
  grammars are derived from it with no field-specific argument.
- **The Kolmogorov instance** is faithful: the class dominated by `U` is exactly the
  partial recursive description methods.
- **The Moore bound** and the conservation (triangle) inequality, as mathematics.

---

## 2. The definition

A **description system** ([`Basic.lean`](Complexity/Basic.lean)) is a type `D` of
descriptions, a type `X` of objects, `cost : D → Γ` in a complete lattice, and
`realizes : D → X → Prop`.

```lean
def K (S : DescSystem D X Γ) (x : X) : Γ := ⨅ (d : D) (_ : S.realizes d x), S.cost d
```

Read as choices, the fields are four dials: which descriptions exist, what is paid, what
counts as producing `x`, and what is free. This is a normal form, not a hypothesis. Two
further structures are used:

| level | descriptions are | complexity is | file |
|---|---|---|---|
| 0 | anything | `K` | `Basic`, `Counting`, `Invariance`, `Profile`, `Thermo` |
| 1 | paths of priced moves | a Lawvere metric `dist` | `Metric` |
| 2 | terms over operations | least term cost; with sharing, `dist` on pools | `Generative`, `Reuse`, `Growth`, `Binary` |

Levels 1 and 2 are each instances of level 0. DAG complexity is level 1 on pools
(`Reuse.poolK_eq_iInf_dist`). Tree complexity is not shown to be a path distance.

## 3. The laws, with what each one needs and whether it carries content

All are restated in [`Laws.lean`](Complexity/Laws.lean).

| | law | needs | content |
|---|---|---|---|
| I | Fidelity: `K(class) = ⨅ K(members)` | nothing | bookkeeping |
| II | Transport: `K'(T x) ≤ f (K x)` along a simulation | a simulation | bookkeeping; used only as "a fixed prefix costs its length" |
| III | Conservation: `dist a c ≤ dist a b + dist b c` | path structure | the triangle inequality. It is *not* the chain rule for Kolmogorov complexity, which holds only up to log terms |
| IV | Duality: every potential is a lower bound | path or term structure | weak half used (DAG ≤ tree, formula lower bounds). Strong half witnessed by `K` |
| V | Counting: no more cheap objects than cheap descriptions | unambiguous descriptions | **carries content**; complete for binary systems |
| V′ | At most `n·(m·nʳ)ⁿ` values have DAG complexity ≤ `n` | finite signature, arity ≤ `r`, single-valued operations | **carries content**; a separate direct count, not an instance of V |
| VI | Reuse: `K_dag ≤ K_tree`; a repeated part is paid once | term structure, size rule | **carries content** |
| VII | Logarithm: `μ(x) ≤ r^(K(x)−1)` | subadditive size `μ`, arity ≤ `r` | **carries content** for `r ≥ 2` |
| VIII | Invariance | a class of admissible systems | true by definition of `Dominates`; the content is the existence of a universal member |

## 4. Instances

"Proved" here means the listed theorems hold of the library's definition. That the
definition is the field's is by inspection, except for Kolmogorov complexity.

| measure | what is actually proved | general laws used |
|---|---|---|
| **Kolmogorov complexity** (plain, of natural numbers) | a universal interpreter over Mathlib's `Nat.Partrec.Code`; optimality, invariance, incompressibility. No conditional complexity, chain rule or prefix version | II (prefix lemma), V, VIII |
| **Shannon source coding** | one-shot `H ≤ L* ≤ H + 1` for Kraft-admissible length functions. `L*` equals `H` only for dyadic sources. No block limit, no Kraft–McMillan | none (textbook Gibbs argument) |
| **Circuit and formula size** (NAND, inputs counted) | circuits ≤ formulas; soundness of formal complexity measures; a hard function exists once `s·((n+1)s²)ˢ < 2^(2ⁿ)` (order `2ⁿ/2n`, existence only, no upper bound) | IV weak, V′, VI |
| **Addition chains** | doubling upper bound and `l(n) ≥ log₂ n` | VI, VII |
| **String straight-line programs** | `|w| ≤ 2^(K−1)`; squaring upper bound; exponential tree/DAG gap | VI, VII, IV weak |
| **Molecular assembly** | nothing specific. V′ does not apply as stated: a join of two fragments is multi-valued | — |
| **Two-part codes** | `log₂ W − c` lower bound for all but `2⁻ᶜ` of `W` candidates (Hartley); a two-part cost that equals `K(macro) + ⌈log₂ W⌉` by construction | V |
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
   `1 + log_r μ` joins. Whether a physical object was built that way, and how many joins
   were available, must be shown independently; `μ/K` is not measurable when `K` is
   uncomputable.
3. **Deterministic dynamics.** `K(fᵗx) ≤ K(x) + log t + O(log log t)` in a universal
   language (Aaronson 2011). Practical compressors cannot test it: Rule 30 from one cell
   compresses to 100% of raw at every size tried, while its true description is about 22
   bits. "Faster growth means noise or input" was wrong as a diagnostic. That such states
   are deep is not proved.
4. **Regulators and learners.** Ashby's law and `VC ≤ log₂|class|` are instances of one
   pigeonhole lemma. That is a unification of proofs, not a prediction.
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
| budget ceiling | within `B` bits fewer than `2^(B+1)` distinct ideas can land |
| preamble | a receiver who decodes like the expert after a preamble `p` carries at most `|p|` more load (upper bound only) |
| bottleneck | a chain of retellings emits fewer than `2^(B+1)` distinct versions, `B` the tightest budget. Independent of chain length |
| hop distance | with ≤ `deg` onward contacts each, an audience above `1 + deg + ⋯ + degⁿ` contains someone more than `n` hops away |
| assumed, not derived | every hop loses at least `λ`, additively |

What the review established about the chapter's argument:

- **The model undercuts the "network ceiling" as stated.** The chapter's illustration
  uses ten to a hundred retellings. The hop bound gives 3 hops for an audience of a
  million and 5 for a billion at 150 contacts each, and 2 hops once any account has 10⁵
  followers. At 0.9 survival per hop the bound moves from 0.87 to 0.65 across six orders
  of magnitude of audience. Forcing ten hops at degree 150 needs an audience above
  `3.9 × 10¹⁹`.
- **Budgets alone do not make loss grow with depth.** A stable relay iterated any number
  of times loses what one pass loses. Depth dependence in the model comes only from the
  assumed per-hop loss.
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

Two questions survive as testable, and both belong to the book, not to the library:

1. *Depth versus size.* Deliver one text to the same number of receivers through a star,
   and through trees of depth 3 and 6, with and without access to the original. Does
   retention depend on depth alone? Does a second route add nothing beyond the better
   single route? The model says yes to both; the second is likely false.
2. *Key before claim.* Annotate claim units and context units, run chains, estimate
   per-hop survival of each.

## 7. After the review: restricting the dials until something is excluded

The review's diagnosis was that nothing is excluded: every function is a complexity. Six
modules added afterwards restrict the systems and prove what then follows. Each item is
labelled with its real strength.

### Self-delimiting systems ([`Prefix.lean`](Complexity/Prefix.lean))

Restrict to unambiguous binary systems in which no description is a proper prefix of
another.

| result | statement | strength |
|---|---|---|
| `exists_prefix_iff` | `f` is the complexity of such a system **iff** `∑ₓ 2^(−f x) ≤ 1` | Kraft's inequality and its converse for arbitrary index sets. Classical. It is the representation theorem the first version lacked: it excludes functions |
| `exists_coding` | for every such `S` there is a `T` with `K_T(x) = ⌈−log₂ P_S(x)⌉` | coding theorem, existence form. Follows from the converse above |
| `coding_of_dominates` | if `U` dominates that `T`, then `K_U(x) ≤ ⌈−log₂ P_U(x)⌉ + c` | "complex implies improbable", conditional on a domination hypothesis. For the universal prefix machine the conclusion is now proved outright: see `Levin.levin` below |
| `pair`, `iterate`, `twoPart_card` | `K(x,y) ≤ K(x)+K(y)`; `K(fᵗx) ≤ K(x)+2 log t+1`; `K(x) ≤ K(πx)+⌈log₂ W⌉` | the additive bounds that are false for plain complexity hold here exactly, and the composed system is again self-delimiting |
| `not_exists_universal` | on an infinite set no system dominates all self-delimiting systems | invariance needs a further restriction (computability) |

### The effective layer ([`PrefixMachine.lean`](Complexity/Instances/PrefixMachine.lean), [`KraftChaitin.lean`](Complexity/KraftChaitin.lean), [`Levin.lean`](Complexity/Levin.lean))

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
- **Boolean functions.** The support bound specializes to the trivial circuit lower bound:
  `m` essential variables need `m` inputs and `m − 1` gates
  (`Circuit.two_mul_card_essential_le`). Nothing stronger is claimed.

- **Upper bound.** Binary exponentiation: `x^m` costs `2 log₂ m` steps beyond `x`
  (`MonoidGen.slK_pow_le`). So in the free commutative monoid a monomial with `k` atoms
  and exponents `eᵢ` costs at most `∑(2 log₂ eᵢ + 2) − 1` steps
  (`Monomial.slK_add_one_le`) against `2∑eᵢ − 1` nodes for the tree. With all exponents
  equal to `m`, the gain is at least `m / (log₂ m + 1)` and at most `m`: the multiplicity
  bound is attained up to a logarithm.
- **The two obstructions are not jointly tight.** Some monomial with exponents below `m`
  needs more than `n` steps whenever `n·((k+1)n²)ⁿ < mᵏ` (`Monomial.exists_slK_gt`), which
  is about `k log m / log(k log m)`. That exceeds `k + log m`. An earlier draft of this
  section conjectured `dagK = Θ(#atoms + log(max multiplicity))`; that conjecture is
  false. The theorem refutes it once parameters are chosen (`m = 2^k` with `k` large);
  that last arithmetic step is done by hand, not machine-checked.

Read together: **reuse pays for repetition**. The gain is bounded by
`min(2^dagK / dagK, μ/|σ|)`, it is zero when nothing repeats, and idempotent operations
remove it because repeating an argument produces nothing new. For monomials the cost with
sharing lies between `k log m / log(k log m)` (for some) and `2k(log₂ m + 1)` (for all).
All of this is elementary, and none of it is new mathematics.

### Still open

- **The other additive laws for `U`.** Subadditivity is proved with a constant. The
  iteration bound `K(fᵗx) ≤ K(x) + 2 log t + c` (for computable `f`) and the two-part bound
  are proved between suitable prefix-free systems (`Prefix.iterate`, `Prefix.twoPart_card`)
  but not yet transferred to `U`; each needs one more machine shown partial recursive.
- **Symmetry of information** (`K(x,y) = K(x) + K(y | x, K(x)) + O(1)`), and with it the
  two-sided form of "micro = macro + log W". Conditional prefix complexity is not defined
  here.
- **The exact order for monomials.** The bounds here differ by a factor of about
  `log(k log m)`. Pippenger's theorem on vector addition chains closes it
  (`log m + (1+o(1))·k log m / log(k log m)`); it is not formalized, and I am quoting it
  from memory.
- **Boolean functions.** Small support and no additive size, so both obstructions are
  silent beyond the trivial bound. The gap there is formula size versus circuit size,
  which is open in complexity theory.
- **Tightness of the counting bound** for general finitely generated algebras.
- **Prior art for this section.** The mathematics is textbook throughout. Two web searches
  (not a literature review) turned up earlier formalizations of neighbouring results: the
  Kraft inequalities for prefix-free complexity in HOL4 (Catt and Norrish, CPP 2021) and a
  proof of the Kraft–Chaitin theorem in Isabelle. They did not turn up a formalization of
  the coding theorem itself. That is not evidence that none exists.
- The machine's outputs are natural numbers, its program index is read in unary, and the
  constants are whatever the constructions give. None of this affects the statements, which
  are up to additive constants.

## Status

**Proved.** Every theorem in the library, including those in `Limits.lean` that refute
earlier claims and those of section 7. `Audit.lean` checks every declaration (986, of
which 673 are theorems including generated ones; 29 module files, 7,071 lines).

**Not established.** That any real domain satisfies a theorem's hypotheses. Novelty of
the pieces not found by the prior-art search. Any empirical claim.

**Scope.** Description-type complexity only. Measures of organization (statistical
complexity, effective complexity, depth) appear as definitions without theorems.
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
  Instances/
    Kolmogorov.lean  Shannon.lean  Circuit.lean  Monoid.lean  CoarseGraining.lean
    Causal.lean      Regulator.lean  Learning.lean  Channel.lean
    PrefixMachine.lean   universal prefix machine: optimality, invariance, subadditivity
Audit.lean           axiom audit of every declaration
```
