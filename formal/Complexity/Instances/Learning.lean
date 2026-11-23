import Complexity.Counting

/-!
# Instance: learning – description complexity bounds VC dimension

A hypothesis class shatters a set of `d` points only if it contains `2 ^ d` hypotheses
that behave differently on them. By the counting law, a class all of whose members have
description complexity at most `n` has fewer than `2 ^ (n + 1)` members. Hence

  `VC dimension ≤ maximal description complexity`.

This is the deterministic core of Occam's razor in learning theory: restricting to simple
hypotheses restricts capacity, and capacity is what sample complexity is measured against.
-/

namespace Complexity

namespace Learning

open DescSystem Finset

variable {α : Type*} [DecidableEq α]

/-- A shattered set forces exponentially many hypotheses. -/
theorem two_pow_card_le_of_shatters {𝒜 : Finset (Finset α)} {s : Finset α}
    (h : 𝒜.Shatters s) : 2 ^ s.card ≤ 𝒜.card := by
  rw [← Finset.card_powerset, ← Finset.shatters_iff.1 h]
  exact Finset.card_image_le

omit [DecidableEq α] in
/-- **Simple hypothesis classes are small.** -/
theorem card_lt_of_K_le (S : DescSystem (List Bool) (Finset α) ℕ∞) (hb : S.IsBinary)
    (hS : S.Functional) (n : ℕ) (𝒜 : Finset (Finset α)) (h𝒜 : ∀ A ∈ 𝒜, S.K A ≤ n) :
    𝒜.card < 2 ^ (n + 1) := by
  have h := S.card_le_of_K_lt hS ((n + 1 : ℕ) : ℕ∞) (2 ^ (n + 1) - 1) (hb.growth (n + 1)) 𝒜
    fun A hA => lt_of_le_of_lt (h𝒜 A hA) (by exact_mod_cast Nat.lt_succ_self n)
  exact lt_of_le_of_lt h (Nat.sub_one_lt (by positivity))

/-- **VC dimension is at most description complexity.** If every hypothesis in a class can
be described within `n` bits (in any unambiguous binary description system), the class
cannot shatter more than `n` points. -/
theorem vcDim_le_of_K_le (S : DescSystem (List Bool) (Finset α) ℕ∞) (hb : S.IsBinary)
    (hS : S.Functional) (n : ℕ) (𝒜 : Finset (Finset α)) (h𝒜 : ∀ A ∈ 𝒜, S.K A ≤ n) :
    𝒜.vcDim ≤ n := by
  refine Finset.sup_le fun s hs => ?_
  have hsh : 𝒜.Shatters s := Finset.mem_shatterer.1 hs
  have h1 : 2 ^ s.card < 2 ^ (n + 1) :=
    lt_of_le_of_lt (two_pow_card_le_of_shatters hsh) (card_lt_of_K_le S hb hS n 𝒜 h𝒜)
  exact Nat.lt_succ_iff.1 ((Nat.pow_lt_pow_iff_right (by norm_num)).1 h1)

end Learning

end Complexity
