import Complexity.Counting

/-!
# Instance: Ashby's law of requisite variety

A regulator faces disturbances `d`, answers each with a response `ρ d`, and the world
returns the outcome `T d (ρ d)`. Ashby's law: *only variety can destroy variety* – if for a
fixed response distinct disturbances give distinct outcomes, then

  `#disturbances ≤ #responses · #outcomes`,   i.e.   `V_O ≥ V_D − V_R`.

This is the counting law applied to one situation. The pair
`(response, outcome)` is a *description* of the disturbance, the hypothesis on `T` says
that descriptions are unambiguous, and the conclusion is the counting law of
`Counting.lean`: there are never more objects than descriptions.

The theorem is the cardinality inequality above, under the separation hypothesis. Reading
it as a statement about controllers, models, immune repertoires or institutions is an
interpretation and is not proved here.
-/

namespace Complexity

namespace Regulator

open DescSystem

variable {Dst R O : Type*}

/-- **Law of requisite variety.** If each response separates disturbances, then the number
of disturbances is at most the number of responses times the number of outcomes that
actually occur. -/
theorem requisite_variety [Fintype Dst] [Fintype R] [DecidableEq O] (T : Dst → R → O)
    (hT : ∀ r, Function.Injective fun d => T d r) (ρ : Dst → R) :
    Fintype.card Dst ≤ Fintype.card R * (Finset.univ.image fun d => T d (ρ d)).card := by
  classical
  -- A disturbance is described by the pair (response given, outcome obtained).
  let S : DescSystem (R × (Finset.univ.image fun d => T d (ρ d))) Dst ℕ∞ :=
    ⟨fun _ => 0, fun ro d => ρ d = ro.1 ∧ T d ro.1 = ro.2.1⟩
  have hS : S.Functional := by
    rintro ⟨r, o⟩ d d' ⟨_, h2⟩ ⟨_, h2'⟩
    exact hT r (h2.trans h2'.symm)
  have hK : ∀ d ∈ (Finset.univ : Finset Dst), S.K d < 1 := by
    intro d _
    have hd : S.realizes
        (ρ d, ⟨T d (ρ d), Finset.mem_image_of_mem _ (Finset.mem_univ d)⟩) d := ⟨rfl, rfl⟩
    exact lt_of_le_of_lt (S.K_le_cost hd) (by simp [S])
  have h := S.card_le_of_K_lt hS 1
    (Fintype.card R * (Finset.univ.image fun d => T d (ρ d)).card)
    (fun B _ => by
      calc B.card ≤ Fintype.card (R × (Finset.univ.image fun d => T d (ρ d))) :=
            Finset.card_le_univ B
        _ = Fintype.card R * (Finset.univ.image fun d => T d (ρ d)).card := by
            rw [Fintype.card_prod, Fintype.card_coe])
    Finset.univ hK
  simpa using h

/-- **Requisite variety, logarithmic form**: `V_D ≤ V_R + V_O` in bits. The regulator's
variety must make up whatever the tolerated outcome variety does not absorb. -/
theorem requisite_variety_log [Fintype Dst] [Fintype R] [DecidableEq O] [Nonempty Dst]
    (T : Dst → R → O) (hT : ∀ r, Function.Injective fun d => T d r) (ρ : Dst → R) :
    Real.logb 2 (Fintype.card Dst) ≤
      Real.logb 2 (Fintype.card R) +
        Real.logb 2 ((Finset.univ.image fun d => T d (ρ d)).card) := by
  have h := requisite_variety T hT ρ
  have hD : 0 < Fintype.card Dst := Fintype.card_pos
  have hpos : 0 < Fintype.card R * (Finset.univ.image fun d => T d (ρ d)).card :=
    lt_of_lt_of_le hD h
  have hR : 0 < Fintype.card R := Nat.pos_of_ne_zero fun h0 => by simp [h0] at hpos
  have hO : 0 < (Finset.univ.image fun d => T d (ρ d)).card :=
    Nat.pos_of_ne_zero fun h0 => by simp [h0] at hpos
  rw [← Real.logb_mul (by exact_mod_cast hR.ne') (by exact_mod_cast hO.ne')]
  refine Real.logb_le_logb_of_le (by norm_num) (by exact_mod_cast hD) ?_
  exact_mod_cast h

/-- **Perfect regulation needs full variety.** If the outcome is held constant, the
regulator must have at least as many responses as there are disturbances. -/
theorem card_le_of_constant_outcome [Fintype Dst] [Fintype R] [DecidableEq O]
    (T : Dst → R → O) (hT : ∀ r, Function.Injective fun d => T d r) (ρ : Dst → R) (o : O)
    (ho : ∀ d, T d (ρ d) = o) : Fintype.card Dst ≤ Fintype.card R := by
  have h := requisite_variety T hT ρ
  have h1 : (Finset.univ.image fun d => T d (ρ d)).card ≤ 1 := by
    refine Finset.card_le_one.2 fun a ha b hb => ?_
    obtain ⟨d, -, rfl⟩ := Finset.mem_image.1 ha
    obtain ⟨d', -, rfl⟩ := Finset.mem_image.1 hb
    rw [ho d, ho d']
  calc Fintype.card Dst ≤ Fintype.card R * (Finset.univ.image fun d => T d (ρ d)).card := h
    _ ≤ Fintype.card R * 1 := Nat.mul_le_mul_left _ h1
    _ = Fintype.card R := Nat.mul_one _

end Regulator

end Complexity
