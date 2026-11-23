import Complexity.Basic
import Complexity.CostAlgebra
import Complexity.Counting
import Complexity.Metric
import Complexity.Generative
import Complexity.Reuse
import Complexity.Growth
import Complexity.Invariance

/-!
# The laws of complexity

The theory in one file. Each statement below is a restatement, in its most general form,
of a theorem proved elsewhere in the library; together they are the content of the claim
that "complexity" is one notion.

| Law | Statement | Classical shadows |
|-----|-----------|-------------------|
| 0 Definition    | `K x = ⨅ cost of realizations`                      | every scalar measure |
| I Fidelity      | `K(class) = ⨅ K(members)`                           | rate–distortion, macrostates |
| II Transport    | `K'(T x) ≤ f (K x)` along a simulation              | reductions, compilers, coarse-graining |
| III Conservation| `K(c) ≤ K(b) + K(c ∣ b)`                            | data processing, slow growth, second laws |
| IV Duality      | `K` is the greatest potential / Bellman fixed point | lower-bound methods, monotones, entropy |
| V Counting      | `#{K < c} ≤ #{cost < c}`                            | incompressibility, Shannon, Ashby, Boltzmann |
| VI Reuse        | `K_dag ≤ K_tree`, copies are free                   | circuits vs formulas, assembly, hierarchy |
| VII Logarithm   | `μ ≤ r ^ (K − 1)` for extensive `μ`                 | addition chains, grammar bounds, depth |
| VIII Invariance | universal systems agree up to a constant            | Kolmogorov invariance |

**Review note.** An adversarial pass (see `Limits.lean` and the README) found that these laws
do not "hold for every setting of the dials": each needs its own structure (III and IV a
path or term structure, V unambiguity, VII a size rule), I and II are bookkeeping, VIII is
true by the definition of `Dominates`, and the strong half of IV is witnessed by `K`
itself. The laws that carry reused content are V, its finitely-generated form, VI, VII and
weak duality.
-/

namespace Complexity

namespace Law

open Quiver

universe u v w u' v' w'

/-- **Law 0 – Definition.** Complexity is the least cost of a realization. -/
theorem definition {D : Type u} {X : Type v} {Γ : Type w} [CompleteLattice Γ]
    (S : DescSystem D X Γ) (x : X) : S.K x = ⨅ (d : D) (_ : S.realizes d x), S.cost d := rfl

/-- **Law I – Fidelity.** Relaxing what counts as "the object" replaces complexity by its
infimum over everything that now counts. -/
theorem fidelity {D : Type u} {X : Type v} {Y : Type v'} {Γ : Type w} [CompleteLattice Γ]
    (S : DescSystem D X Γ) (R : X → Y → Prop) (y : Y) :
    (S.relax R).K y = ⨅ (x : X) (_ : R x y), S.K x := S.K_relax R y

/-- **Law II – Transport.** Complexity is lax natural along simulations: upper bounds
travel forward, lower bounds travel backward. -/
theorem transport {D : Type u} {X : Type v} {Γ : Type w} {D' : Type u'} {X' : Type v'}
    {Γ' : Type w'} [CompleteLattice Γ] [CompleteLattice Γ'] {S : DescSystem D X Γ}
    {S' : DescSystem D' X' Γ'} (f : sInfHom Γ Γ') (h : DescSystem.Sim S S' f) (x : X) :
    S'.K (h.ob x) ≤ f (S.K x) := h.K_le f x

/-- **Law III – Conservation.** No process raises complexity by more than its own cost. -/
theorem conservation {X : Type u} [Quiver.{v} X] {Γ : Type w} [CompleteLattice Γ]
    [AddCommMonoid Γ] [IsCostAlgebra Γ] (w : Weight X Γ) (I : Set X) (b c : X) :
    KI w I c ≤ KI w I b + dist w b c := KI_conservation w I b c

/-- **Law IV – Duality (paths).** Complexity is the greatest potential vanishing on what
is free: the best lower bound is always tight. -/
theorem duality {X : Type u} [Quiver.{v} X] {Γ : Type w} [CompleteLattice Γ]
    [AddCommMonoid Γ] [IsCostAlgebra Γ] (w : Weight X Γ) (I : Set X) (b : X) :
    IsGreatest {c | ∃ φ : X → Γ, IsPotential w φ ∧ (∀ a ∈ I, φ a = 0) ∧ φ b = c}
      (KI w I b) := isGreatest_KI w I b

/-- **Law IV – Duality (terms).** Tree complexity is the greatest fixed point of the
Bellman operator of the generative system. -/
theorem bellman {S : Sig.{u, v}} {X : Type w} (alg : S.Alg X) (R : S.CostRule) :
    Sig.treeK alg R = OrderHom.gfp ⟨Sig.bellman alg R, Sig.bellman_mono alg R⟩ :=
  Sig.treeK_eq_gfp alg R

/-- **Law V – Counting.** There are never more cheap objects than cheap descriptions. -/
theorem counting {D : Type u} {X : Type v} {Γ : Type w} [CompleteLinearOrder Γ]
    (S : DescSystem D X Γ) (hS : S.Functional) (c : Γ) (N : ℕ)
    (hN : ∀ B : Finset D, (∀ d ∈ B, S.cost d < c) → B.card ≤ N)
    (A : Finset X) (hA : ∀ x ∈ A, S.K x < c) : A.card ≤ N :=
  S.card_le_of_K_lt hS c N hN A hA

/-- **Law VI – Reuse.** Sharing parts never hurts, and a part used many times is paid for
once. -/
theorem reuse {S : Sig.{u, v}} {X : Type w} [∀ a, Fintype (S.Ar a)] (alg : S.Alg X)
    (wt : S.Op → ℕ∞) :
    (∀ x, Sig.dagK alg wt x ≤ Sig.treeK alg (Sig.sizeRule S wt) x) ∧
      ∀ (a : S.Op) (x : X), Sig.dagK alg wt (alg a fun _ => x) ≤ Sig.dagK alg wt x + wt a :=
  ⟨fun x => Sig.dagK_le_treeK x, fun a x => Sig.dagK_alg_const_le a x⟩

/-- **Law VII – Logarithm.** An extensive measure can at most multiply by the arity at each
step, so complexity is at least the logarithm of size. -/
theorem logarithm {S : Sig.{u, v}} {X : Type w} [∀ a, Fintype (S.Ar a)] {alg : S.Alg X}
    (μ : X → ℕ) (r : ℕ) (hr : 1 ≤ r) (har : ∀ a, Fintype.card (S.Ar a) ≤ r)
    (hμ : ∀ (a : S.Op) (xs : S.Ar a → X), μ (alg a xs) ≤ max 1 (∑ b, μ (xs b)))
    {x : X} {n : ℕ} (h : Sig.dagK alg (fun _ => 1) x ≤ n) : μ x * r ≤ r ^ n :=
  Sig.mul_le_pow_of_dagK_le μ r hr har hμ h

/-- **Law V′ – Counting with reuse.** In a finitely generated system almost everything is
complex: at most `n · (m · nʳ)ⁿ` objects have DAG complexity at most `n`. -/
theorem counting_reuse {S : Sig.{u, v}} {X : Type w} {alg : S.Alg X} [Fintype S.Op]
    [∀ a, Fintype (S.Ar a)] (r : ℕ) (har : ∀ a, Fintype.card (S.Ar a) ≤ r) (n : ℕ)
    (A : Finset X) (hA : ∀ x ∈ A, Sig.dagK alg (fun _ => 1) x ≤ n) :
    A.card ≤ n * (Fintype.card S.Op * n ^ r) ^ n :=
  Sig.card_le_of_dagK_le r har n A hA

/-- **Law VIII – Invariance.** Description systems that each dominate a class containing
both define the same complexity up to an additive constant. -/
theorem invariance {D : Type u} {X : Type v} (𝓒 : Set (DescSystem D X ℕ∞))
    {U U' : DescSystem D X ℕ∞} (hU : U ∈ 𝓒) (hU' : U' ∈ 𝓒)
    (h : ∀ S ∈ 𝓒, DescSystem.Dominates U S) (h' : ∀ S ∈ 𝓒, DescSystem.Dominates U' S) :
    ∃ c : ℕ, ∀ x, U.K x ≤ U'.K x + c ∧ U'.K x ≤ U.K x + c :=
  DescSystem.invariance 𝓒 hU hU' h h'

end Law

end Complexity
