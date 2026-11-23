import Mathlib

/-!
# Cost algebras

A **cost algebra** is where costs live when descriptions can be *composed*: a complete
lattice (to take least costs) that is also a commutative monoid (to add the costs of
successive or juxtaposed steps), in which addition distributes over arbitrary infima and
`0` is the least cost.

This is exactly a commutative unital quantale with the order reversed – Lawvere's base of
enrichment for generalized metric spaces. Sizes and step counts (`ℕ∞`), and energies,
code lengths and surprisals `-log p` (`ℝ≥0∞`) are all cost algebras, which is why
"complexity" in so many fields obeys the same triangle-inequality-shaped laws.
-/

namespace Complexity

open scoped ENNReal

/-- A **cost algebra**: addition distributes over arbitrary infima, and `0` is least. -/
class IsCostAlgebra (Γ : Type*) [CompleteLattice Γ] [AddCommMonoid Γ] : Prop where
  /-- Addition distributes over arbitrary infima (including the empty one: `⊤ + a = ⊤`). -/
  sInf_add : ∀ (s : Set Γ) (a : Γ), sInf s + a = ⨅ b ∈ s, b + a
  /-- Costs are non-negative. -/
  zero_le : ∀ a : Γ, 0 ≤ a

namespace CostAlgebra

variable {Γ : Type*} [CompleteLattice Γ] [AddCommMonoid Γ] [IsCostAlgebra Γ]

theorem zero_le (a : Γ) : (0 : Γ) ≤ a := IsCostAlgebra.zero_le a

theorem bot_eq_zero : (⊥ : Γ) = 0 := le_antisymm bot_le (zero_le ⊥)

theorem iInf_add {ι : Sort*} (f : ι → Γ) (a : Γ) : (⨅ i, f i) + a = ⨅ i, f i + a := by
  have := IsCostAlgebra.sInf_add (Set.range f) a
  rw [iInf_range] at this
  exact this

theorem add_iInf {ι : Sort*} (a : Γ) (f : ι → Γ) : (a + ⨅ i, f i) = ⨅ i, a + f i := by
  rw [add_comm, iInf_add]
  exact iInf_congr fun i => add_comm _ _

theorem iInf_add_iInf {ι κ : Sort*} (f : ι → Γ) (g : κ → Γ) :
    (⨅ i, f i) + ⨅ j, g j = ⨅ (i) (j), f i + g j := by
  rw [iInf_add]
  simp only [add_iInf]

theorem top_add (a : Γ) : (⊤ : Γ) + a = ⊤ := by
  have := IsCostAlgebra.sInf_add (∅ : Set Γ) a
  simpa using this

theorem add_top (a : Γ) : a + (⊤ : Γ) = ⊤ := by rw [add_comm, top_add]

/-- Addition is monotone in a cost algebra (a consequence of distributivity). -/
theorem add_le_add_right {a b : Γ} (h : a ≤ b) (c : Γ) : a + c ≤ b + c := by
  have h1 := IsCostAlgebra.sInf_add ({a, b} : Set Γ) c
  rw [sInf_pair, inf_eq_left.2 h] at h1
  rw [h1]
  exact iInf₂_le b (by simp)

theorem add_le_add_left {a b : Γ} (h : a ≤ b) (c : Γ) : c + a ≤ c + b := by
  rw [add_comm c a, add_comm c b]
  exact add_le_add_right h c

theorem add_le_add {a b c d : Γ} (h₁ : a ≤ b) (h₂ : c ≤ d) : a + c ≤ b + d :=
  (add_le_add_right h₁ c).trans (add_le_add_left h₂ b)

theorem le_add_right (a b : Γ) : a ≤ a + b := by
  simpa using add_le_add_left (zero_le b) a

theorem le_add_left (a b : Γ) : a ≤ b + a := by
  rw [add_comm]
  exact le_add_right a b

theorem nsmul_le_nsmul_left {m n : ℕ} (h : m ≤ n) (a : Γ) : m • a ≤ n • a := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_add_of_le h
  rw [add_nsmul]
  exact le_add_right _ _

theorem nsmul_le_nsmul_right {a b : Γ} (h : a ≤ b) (n : ℕ) : n • a ≤ n • b := by
  induction n with
  | zero => simp
  | succ n ih => rw [succ_nsmul, succ_nsmul]; exact add_le_add ih h

end CostAlgebra

instance : IsCostAlgebra ℕ∞ where
  sInf_add _ _ := ENat.sInf_add
  zero_le a := by simp

instance : IsCostAlgebra ℝ≥0∞ where
  sInf_add _ _ := ENNReal.sInf_add
  zero_le a := by simp

end Complexity
