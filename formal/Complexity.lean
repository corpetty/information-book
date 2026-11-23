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
# A unified theory of complexity

**Thesis.** Complexity is the least cost of realization,

  `K x = ⨅ { cost d | d realizes x }`,

and every notion of complexity in use is this infimum for some setting of four dials –
generators, cost, fidelity, context – plus a temperature. The laws each field discovered
separately are theorems about the infimum that hold for every setting.

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
* `Dynamics`    – deterministic laws add at most `log t`.
* `Laws`        – the theory in one file.
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

## Instances

`Kolmogorov` (algorithmic information theory) · `PrefixMachine` (a universal prefix
machine: optimality, invariance, subadditivity) · `Shannon` (entropy as source complexity) ·
`Circuit` (Boolean circuits and formulas) · `Monoid` (addition chains, grammars, assembly
of strings) · `CoarseGraining` (two-part codes, Boltzmann entropy) · `Causal` (causal
states, statistical complexity) · `Regulator` (Ashby's requisite variety) · `Learning`
(VC dimension) · `Channel` (transmission of ideas: load, budgets, network ceiling).
-/
