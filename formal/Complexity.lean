import Complexity.Basic
import Complexity.CostAlgebra
import Complexity.Counting
import Complexity.Metric
import Complexity.Generative
import Complexity.Reuse
import Complexity.Growth
import Complexity.Binary
import Complexity.Invariance
import Complexity.Profile
import Complexity.Thermo
import Complexity.Dynamics
import Complexity.Laws
import Complexity.Limits
import Complexity.Translation
import Complexity.Prefix
import Complexity.ReuseGap
import Complexity.KraftChaitin
import Complexity.Levin
import Complexity.Conditional
import Complexity.Symmetry
import Complexity.Semicomputable
import Complexity.Guessing
import Complexity.Plain
import Complexity.Lossy
import Complexity.Noisy
import Complexity.Instances.Kolmogorov
import Complexity.Instances.PrefixMachine
import Complexity.Instances.Shannon
import Complexity.Instances.Circuit
import Complexity.Instances.Monoid
import Complexity.Instances.CoarseGraining
import Complexity.Instances.Causal
import Complexity.Instances.Regulator
import Complexity.Instances.Learning
import Complexity.Instances.Channel

/-!
# Complexity as least cost of description

The common definition is

  `K x = ⨅ { cost d | d realizes x }`.

Many notions of complexity are this infimum for some choice of what a description is, what
it costs and what "realizes" means. The definition is a common language, not a theory:
every function is `K` for some choice (`Limits.exists_system_K_eq`), so no law holds for
every choice. What the library does is locate, for each law, the restriction on
descriptions under which it holds, and prove a counterexample without it. See `README.md`.

An earlier version of this docstring was titled "A unified theory of complexity" and said
that the laws each field discovered "hold for every setting". That claim was refuted by
the review recorded in `Limits.lean` and the README.

## Layout

* `Basic`       – description systems, `K`, fidelity, simulations (transport).
* `CostAlgebra` – where costs live when descriptions compose (Lawvere quantales).
* `Counting`    – the counting law; binary descriptions; Hartley.
* `Metric`      – paths: conditional complexity, chain rule, potential duality,
                  conservation, volume growth.
* `Generative`  – operations of any arity: tree complexity as the greatest fixed point of
                  the Bellman operator; homomorphisms.
* `Reuse`       – shared parts: DAG complexity as path complexity on pools; copying is
                  free; the logarithmic law.
* `Growth`      – the counting law for finitely generated systems with reuse.
* `Binary`      – generators plus one binary operation.
* `Invariance`  – domination, universality, the invariance theorem.
* `Profile`     – several resources: the profile is `K` in a lattice of sets; depth and
                  sophistication as sections.
* `Thermo`      – the temperature dial: partition functions, simplicity bias.
* `Dynamics`    – iteration systems. That a deterministic law adds at most `log t + c` is
                  false for the plain machine (`Limits`); `2 log t` holds for the universal
                  prefix machine (`Conditional`).
* `Laws`        – the general statements in one file.
* `Limits`      – theorems proved *against* the theory: what the framework does not say,
                  and two advertised bounds that fail for the universal machine.
* `Translation` – domination with a mechanism: simulation by admissible translations;
                  invariance from translators; no universal system without a restricted
                  class.
* `Prefix`      – self-delimiting systems: the representation theorem (Kraft and its
                  converse), the coding theorem in existence form, and composition at
                  exact additive cost.
* `ReuseGap`    – how much sharing parts can buy: the exponential ceiling, rigidity of
                  tree complexity in domains with an additive size, and the support
                  bound (the gain is at most the multiplicity of atoms; zero in the free
                  semilattice).
* `KraftChaitin` – the effective converse of Kraft's inequality: a partial recursive
                  decoder for a primitive recursive list of requests.
* `Levin`       – Levin's coding theorem for the universal prefix machine:
                  `2^(-K x) ≤ P x ≤ 2^c * 2^(-K x)`.
* `Conditional` – conditional prefix complexity `K(y | x)` and the additive laws for the
                  universal machine: the chain rule (easy half), the two-part code, the
                  logarithmic growth law.
* `Symmetry`    – symmetry of information, `K(⟨x, y⟩) = K(x) + K(y | x, K(x)) + O(1)`,
                  and "micro = macro + log W" for typical microstates.
* `Semicomputable` – which functions are prefix complexities: those approximable from
                  above with summable weights, up to a constant; `K_U` is the least.
* `Guessing`    – no bounded list of guesses contains `K`: `K` is not computable,
                  `K(K(x) | x)` is unbounded, and symmetry fails for the bare condition `x`.
* `Plain`       – failures one stage before each law: counting without unambiguity,
                  infinite probability and no chain rule for the plain machine.
* `Lossy`       – landing an idea within a tolerance: load at a tolerance, the exchange
                  rate between budget and tolerance (covering numbers), and what the
                  depth of a chain of retellings does and does not force.
* `Noisy`       – hops as stochastic matrices: one-hop bounds on the advantage of a test
                  multiply along a chain (Dobrushin), with forgetting hops (Doeblin) as a
                  special case and exactly `cⁿ` for the fading hop; one fixed chain of
                  functions is all-or-nothing for a pair; what a second route can add.

## Instances

`Kolmogorov` (algorithmic information theory) · `PrefixMachine` (a universal prefix
machine: optimality, invariance, subadditivity) · `Shannon` (entropy as source complexity) ·
`Circuit` (Boolean circuits and formulas) · `Monoid` (addition chains, grammars, assembly
of strings) · `CoarseGraining` (two-part codes, Boltzmann entropy) · `Causal` (causal
states, statistical complexity) · `Regulator` (Ashby's requisite variety) · `Learning`
(VC dimension) · `Channel` (transmission of ideas: load, budgets, network ceiling).
-/
