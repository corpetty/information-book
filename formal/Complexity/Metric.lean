import Complexity.Basic
import Complexity.CostAlgebra

/-!
# Generative distance: complexity when descriptions compose

When descriptions are *paths* – sequences of primitive moves, each with a cost – the least
cost of getting from `a` to `b` is a generalized (Lawvere) metric

  `dist a b = ⨅ { cost p | p : a ⟶* b }`.

`dist a b` is the **conditional complexity** of `b` given `a`: the context dial. Absolute
complexity is distance from whatever is free.

Everything in this file holds over any cost algebra.

* `dist_triangle`       – the chain rule / triangle inequality;
* `IsPotential.le_dist` – **weak duality**: every potential (monotone, Lyapunov function,
                          formal complexity measure, entropy-like quantity) is a lower bound;
* `isGreatest_dist`     – **strong duality**: complexity is itself the greatest potential.
                          Upper bounds are paths; lower bounds are potentials; they meet;
* `dist_comm`           – in reversible systems the distance is symmetric
                          (**information distance**);
* `KI_conservation`     – the **conservation law**: complexity cannot grow by more than the
                          cost of the process applied. Data-processing inequalities, slow-growth
                          laws and second-law-type statements are instances;
* `card_le_of_hop_le`   – **volume growth** (Moore bound): at most `Σ deg^k` states lie
                          within `n` moves, so in a large space almost everything is far;
* `nsmul_le_dist`       – a per-move loss accumulates at least linearly in hop distance.

**Review note.** `dist` is exactly as general as a Lawvere metric (`Limits.dist_complete_eq`).
Reading it as conditional Kolmogorov complexity is an analogy: plain `K(· ∣ ·)` satisfies
the triangle inequality only up to logarithmic terms. `dist_comm` is symmetry of
undirected path metrics, not the information-distance theorem. "Strong duality" is
witnessed by the distance itself; and not every lower bound is a potential.
-/

namespace Complexity

open Quiver

universe u v w

variable {X : Type u} [Quiver.{v} X] {Γ : Type w}

/-- A **weighting** assigns a cost to every primitive move of a quiver. -/
abbrev Weight (X : Type u) [Quiver.{v} X] (Γ : Type w) := ∀ ⦃a b : X⦄, (a ⟶ b) → Γ

section Monoid

variable [AddCommMonoid Γ]

/-- The cost of a path is the sum of the costs of its moves. -/
def pathCost (w : Weight X Γ) {a : X} : ∀ {b : X}, Path a b → Γ
  | _, .nil => 0
  | _, .cons p e => pathCost w p + w e

@[simp] theorem pathCost_nil (w : Weight X Γ) (a : X) :
    pathCost w (Path.nil : Path a a) = 0 := rfl

@[simp] theorem pathCost_cons (w : Weight X Γ) {a b c : X} (p : Path a b) (e : b ⟶ c) :
    pathCost w (p.cons e) = pathCost w p + w e := rfl

/-- Cost is additive under composition of paths: cost is a functor to the monoid `Γ`. -/
theorem pathCost_comp (w : Weight X Γ) {a b : X} (p : Path a b) :
    ∀ {c : X} (q : Path b c), pathCost w (p.comp q) = pathCost w p + pathCost w q
  | _, .nil => by simp
  | _, .cons q e => by
      rw [Path.comp_cons, pathCost_cons, pathCost_comp w p q, pathCost_cons, add_assoc]

@[simp] theorem pathCost_toPath (w : Weight X Γ) {a b : X} (e : a ⟶ b) :
    pathCost w e.toPath = w e := by
  simp [Hom.toPath]

/-- In a reversible system with symmetric prices, a path and its reverse cost the same. -/
theorem pathCost_reverse [HasReverse X] (w : Weight X Γ)
    (hw : ∀ ⦃a b : X⦄ (e : a ⟶ b), w (Quiver.reverse e) = w e) {a : X} :
    ∀ {b : X} (p : Path a b), pathCost w p.reverse = pathCost w p
  | _, .nil => rfl
  | _, .cons p e => by
      show pathCost w ((Quiver.reverse e).toPath.comp p.reverse) = pathCost w p + w e
      rw [pathCost_comp, pathCost_toPath, hw, pathCost_reverse w hw p, add_comm]

end Monoid

section Dist

variable [CompleteLattice Γ] [AddCommMonoid Γ] [IsCostAlgebra Γ]

/-- **Generative distance** = conditional complexity `K(b | a)`: the least cost of a path
from `a` to `b`. -/
def dist (w : Weight X Γ) (a b : X) : Γ := ⨅ p : Path a b, pathCost w p

variable (w : Weight X Γ)

omit [IsCostAlgebra Γ] in
theorem dist_le_pathCost {a b : X} (p : Path a b) : dist w a b ≤ pathCost w p :=
  iInf_le _ p

omit [IsCostAlgebra Γ] in
theorem dist_le_edge {a b : X} (e : a ⟶ b) : dist w a b ≤ w e := by
  simpa using dist_le_pathCost w e.toPath

@[simp] theorem dist_self (a : X) : dist w a a = 0 :=
  le_antisymm (by simpa using dist_le_pathCost w (Path.nil : Path a a)) (CostAlgebra.zero_le _)

/-- **Chain rule / triangle inequality.** `K(c | a) ≤ K(b | a) + K(c | b)`. -/
theorem dist_triangle (a b c : X) : dist w a c ≤ dist w a b + dist w b c := by
  unfold dist
  rw [CostAlgebra.iInf_add_iInf]
  exact le_iInf fun p => le_iInf fun q =>
    (iInf_le _ (p.comp q)).trans (pathCost_comp w p q).le

omit [IsCostAlgebra Γ] in
/-- **Information distance.** When every move can be undone at the same price (reversible
computation, unitary gates, edit operations, reversible reactions), the generative
distance is symmetric – a genuine pseudometric on the space of objects. -/
theorem dist_comm [HasReverse X] (hw : ∀ ⦃a b : X⦄ (e : a ⟶ b), w (Quiver.reverse e) = w e)
    (a b : X) : dist w a b = dist w b a := by
  apply le_antisymm
  · exact le_iInf fun p => (dist_le_pathCost w p.reverse).trans (pathCost_reverse w hw p).le
  · exact le_iInf fun p => (dist_le_pathCost w p.reverse).trans (pathCost_reverse w hw p).le

/-- Paths out of `a`, viewed as a description system for the objects they reach. Its
complexity is the generative distance: `dist` is an instance of the one definition. -/
def pathSystem (a : X) : DescSystem (Σ b : X, Path a b) X Γ where
  cost d := pathCost w d.2
  realizes d x := d.1 = x

omit [IsCostAlgebra Γ] in
theorem pathSystem_K (a b : X) : (pathSystem w a).K b = dist w a b := by
  apply le_antisymm
  · exact le_iInf fun p => (pathSystem w a).K_le_cost (d := ⟨b, p⟩) rfl
  · refine le_iInf₂ fun d hd => ?_
    obtain ⟨b', p⟩ := d
    obtain rfl : b' = b := hd
    exact iInf_le _ p

/-! ### Duality: lower bounds are potentials -/

/-- A **potential** for a weighting: a quantity that no move can raise by more than the
move costs. Entropy under adiabatic processes, Lyapunov functions, resource monotones,
formal complexity measures and amortized-analysis potentials are all of this form. -/
def IsPotential (φ : X → Γ) : Prop := ∀ ⦃a b : X⦄ (e : a ⟶ b), φ b ≤ φ a + w e

variable {w}

theorem IsPotential.le_pathCost {φ : X → Γ} (h : IsPotential w φ) {a : X} :
    ∀ {b : X} (p : Path a b), φ b ≤ φ a + pathCost w p
  | _, .nil => by simp
  | _, .cons p e => by
      rw [pathCost_cons, ← add_assoc]
      exact (h e).trans (CostAlgebra.add_le_add_right (h.le_pathCost p) _)

/-- **Weak duality.** A potential cannot rise along any route by more than the distance. -/
theorem IsPotential.le_dist {φ : X → Γ} (h : IsPotential w φ) (a b : X) :
    φ b ≤ φ a + dist w a b := by
  unfold dist
  rw [CostAlgebra.add_iInf]
  exact le_iInf fun p => h.le_pathCost p

variable (w)

/-- Distance from a fixed origin is itself a potential. -/
theorem dist_isPotential (a : X) : IsPotential w (dist w a) := fun b c e =>
  (dist_triangle w a b c).trans (CostAlgebra.add_le_add_left (dist_le_edge w e) _)

/-- **Strong duality.** The generative distance is the *greatest* value at `b` of a
potential vanishing at `a`: the best lower bound is always tight. -/
theorem isGreatest_dist (a b : X) :
    IsGreatest {c | ∃ φ : X → Γ, IsPotential w φ ∧ φ a = 0 ∧ φ b = c} (dist w a b) := by
  refine ⟨⟨dist w a, dist_isPotential w a, dist_self w a, rfl⟩, ?_⟩
  rintro c ⟨φ, hφ, h0, rfl⟩
  simpa [h0] using hφ.le_dist a b

/-- Raising the price of moves raises distances. -/
theorem dist_mono {w w' : Weight X Γ} (h : ∀ ⦃a b : X⦄ (e : a ⟶ b), w e ≤ w' e) (a b : X) :
    dist w a b ≤ dist w' a b := by
  have key : ∀ {b : X} (p : Path a b), pathCost w p ≤ pathCost w' p := by
    intro b p
    induction p with
    | nil => simp
    | cons p e ih => exact CostAlgebra.add_le_add ih (h e)
  exact le_iInf fun p => (dist_le_pathCost w p).trans (key p)

/-! ### Absolute complexity and the conservation law -/

/-- **Complexity relative to a free set `I`**: the least cost of reaching `b` from
anything that is available for nothing. -/
def KI (I : Set X) (b : X) : Γ := ⨅ a ∈ I, dist w a b

omit [IsCostAlgebra Γ] in
theorem KI_le_dist {I : Set X} {a : X} (ha : a ∈ I) (b : X) : KI w I b ≤ dist w a b :=
  iInf₂_le a ha

theorem KI_eq_zero {I : Set X} {a : X} (ha : a ∈ I) : KI w I a = 0 :=
  le_antisymm (by simpa using KI_le_dist w ha a) (CostAlgebra.zero_le _)

/-- **Conservation law.** No process can raise complexity by more than its own cost:
`K(c) ≤ K(b) + K(c | b)`. -/
theorem KI_conservation (I : Set X) (b c : X) : KI w I c ≤ KI w I b + dist w b c := by
  unfold KI
  simp only [CostAlgebra.iInf_add]
  exact le_iInf₂ fun a ha => (iInf₂_le a ha).trans (dist_triangle w a b c)

/-- **Requisite cost.** Any single move from `b` to `c` must pay for the complexity gap. -/
theorem KI_le_add_edge (I : Set X) {b c : X} (e : b ⟶ c) : KI w I c ≤ KI w I b + w e :=
  (KI_conservation w I b c).trans (CostAlgebra.add_le_add_left (dist_le_edge w e) _)

theorem KI_isPotential (I : Set X) : IsPotential w (KI w I) := fun _ _ e => KI_le_add_edge w I e

/-- **Strong duality, absolute form.** Complexity is the greatest potential that vanishes
on everything free. -/
theorem isGreatest_KI (I : Set X) (b : X) :
    IsGreatest {c | ∃ φ : X → Γ, IsPotential w φ ∧ (∀ a ∈ I, φ a = 0) ∧ φ b = c}
      (KI w I b) := by
  refine ⟨⟨KI w I, KI_isPotential w I, fun a ha => KI_eq_zero w ha, rfl⟩, ?_⟩
  rintro c ⟨φ, hφ, h0, rfl⟩
  refine le_iInf₂ fun a ha => ?_
  simpa [h0 a ha] using hφ.le_dist a b

end Dist

/-! ### Hop distance, volume growth, and accumulated loss -/

section Hop

/-- **Hop distance**: every move costs one. -/
noncomputable def hop (a b : X) : ℕ∞ := dist (fun _ _ _ => (1 : ℕ∞)) a b

theorem pathCost_one {a b : X} (p : Path a b) :
    pathCost (fun _ _ _ => (1 : ℕ∞)) p = p.length := by
  induction p with
  | nil => simp
  | cons p e ih => simp [ih]

theorem hop_le_length {a b : X} (p : Path a b) : hop a b ≤ p.length := by
  rw [← pathCost_one p]
  exact dist_le_pathCost _ p

theorem hop_le_iff {a b : X} {n : ℕ} : hop a b ≤ n ↔ ∃ p : Path a b, p.length ≤ n := by
  rw [hop, ← pathSystem_K, DescSystem.K_le_coe_iff]
  constructor
  · rintro ⟨⟨b', p⟩, hb, hc⟩
    obtain rfl : b' = b := hb
    refine ⟨p, ?_⟩
    have : ((p.length : ℕ) : ℕ∞) ≤ n := by rw [← pathCost_one p]; exact hc
    exact_mod_cast this
  · rintro ⟨p, hp⟩
    refine ⟨⟨b, p⟩, rfl, ?_⟩
    show pathCost (fun _ _ _ => (1 : ℕ∞)) p ≤ n
    rw [pathCost_one p]
    exact_mod_cast hp

/-- **Volume growth (Moore bound).** If every state has at most `deg` successors, at most
`1 + deg + ⋯ + deg ^ n` states can be reached within `n` moves. -/
theorem exists_ball_finset [DecidableEq X] (succ : X → Finset X)
    (hsucc : ∀ ⦃a b : X⦄, (a ⟶ b) → b ∈ succ a) (deg : ℕ)
    (hdeg : ∀ a, (succ a).card ≤ deg) (a : X) (n : ℕ) :
    ∃ B : Finset X, (∀ (b : X) (p : Path a b), p.length ≤ n → b ∈ B) ∧
      B.card ≤ ∑ k ∈ Finset.range (n + 1), deg ^ k := by
  induction n with
  | zero =>
    refine ⟨{a}, fun b p hp => ?_, by simp⟩
    have := p.eq_of_length_zero (Nat.le_zero.1 hp)
    simp [this]
  | succ n ih =>
    obtain ⟨B, hB, hcard⟩ := ih
    refine ⟨insert a (B.biUnion succ), ?_, ?_⟩
    · intro b p hp
      cases p with
      | nil => exact Finset.mem_insert_self _ _
      | cons q e =>
        refine Finset.mem_insert_of_mem (Finset.mem_biUnion.2 ⟨_, hB _ q ?_, hsucc e⟩)
        simpa [Path.length_cons] using hp
    · have h1 : (B.biUnion succ).card ≤ B.card * deg :=
        Finset.card_biUnion_le_card_mul _ _ _ fun y _ => hdeg y
      calc (insert a (B.biUnion succ)).card
          ≤ (B.biUnion succ).card + 1 := Finset.card_insert_le _ _
        _ ≤ B.card * deg + 1 := Nat.add_le_add_right h1 1
        _ ≤ (∑ k ∈ Finset.range (n + 1), deg ^ k) * deg + 1 :=
            Nat.add_le_add_right (Nat.mul_le_mul_right deg hcard) 1
        _ = ∑ k ∈ Finset.range (n + 1 + 1), deg ^ k := by
            rw [Finset.sum_range_succ' _ (n + 1), Finset.sum_mul]
            simp [pow_succ]

/-- **Counting law for reachability.** A population all of whose members lie within `n`
moves of `a` has at most `Σ_{k ≤ n} deg ^ k` members. -/
theorem card_le_of_hop_le [DecidableEq X] (succ : X → Finset X)
    (hsucc : ∀ ⦃a b : X⦄, (a ⟶ b) → b ∈ succ a) (deg : ℕ)
    (hdeg : ∀ a, (succ a).card ≤ deg) (a : X) (n : ℕ) (A : Finset X)
    (hA : ∀ b ∈ A, hop a b ≤ n) : A.card ≤ ∑ k ∈ Finset.range (n + 1), deg ^ k := by
  obtain ⟨B, hB, hcard⟩ := exists_ball_finset succ hsucc deg hdeg a n
  refine (Finset.card_le_card fun b hb => ?_).trans hcard
  obtain ⟨p, hp⟩ := hop_le_iff.1 (hA b hb)
  exact hB b p hp

/-- **Almost everything is far.** A population larger than the ball of radius `n` contains
a member more than `n` moves away. -/
theorem exists_hop_gt [DecidableEq X] (succ : X → Finset X)
    (hsucc : ∀ ⦃a b : X⦄, (a ⟶ b) → b ∈ succ a) (deg : ℕ)
    (hdeg : ∀ a, (succ a).card ≤ deg) (a : X) (n : ℕ) (A : Finset X)
    (hA : ∑ k ∈ Finset.range (n + 1), deg ^ k < A.card) : ∃ b ∈ A, (n : ℕ∞) < hop a b := by
  by_contra h
  simp only [not_exists, not_and, not_lt] at h
  exact absurd (card_le_of_hop_le succ hsucc deg hdeg a n A h) (not_le.2 hA)

variable [CompleteLattice Γ] [AddCommMonoid Γ] [IsCostAlgebra Γ]

/-- **Accumulated loss.** If every move costs at least `lam`, then reaching something `n`
hops away costs at least `n • lam`, whatever route is taken. -/
theorem nsmul_le_dist (w : Weight X Γ) (lam : Γ) (hw : ∀ ⦃a b : X⦄ (e : a ⟶ b), lam ≤ w e)
    {a b : X} {n : ℕ} (hn : (n : ℕ∞) ≤ hop a b) : n • lam ≤ dist w a b := by
  have key : ∀ {b : X} (p : Path a b), p.length • lam ≤ pathCost w p := by
    intro b p
    induction p with
    | nil => simp
    | cons p e ih =>
      rw [Path.length_cons, succ_nsmul, pathCost_cons]
      exact CostAlgebra.add_le_add ih (hw e)
  refine le_iInf fun p => ?_
  have hlen : n ≤ p.length := by exact_mod_cast hn.trans (hop_le_length p)
  exact (CostAlgebra.nsmul_le_nsmul_left hlen lam).trans (key p)

end Hop

end Complexity
