import Complexity.Binary

/-!
# Instance: Boolean circuits and formulas

Boolean functions of `n` variables, generated from the `n` projections by NAND, form a
binary generative system. Its complexity with reuse is **circuit size**; without reuse it
is **formula size**. Three cornerstones of circuit complexity are then corollaries of the
general theory, with no circuit-specific argument:

* `circuitK_le_formulaK`   – circuits are never larger than formulas (reuse never hurts);
* `le_formulaK`            – the **formal-complexity-measure method** for formula lower
                             bounds (weak duality);
* `exists_hard_function`   – **Shannon's counting theorem**: if
                             `s · ((n + 1) · s²)ˢ < 2 ^ 2ⁿ` then some function of `n`
                             variables has circuit size greater than `s` (counting law).

The same three statements, with the same proofs, hold for molecules under joining, strings
under concatenation and numbers under addition.
-/

namespace Complexity

namespace Circuit

open Binary

/-- Boolean functions of `n` variables. -/
abbrev BoolFn (n : ℕ) : Type := (Fin n → Bool) → Bool

/-- The `i`-th input variable. -/
def proj (n : ℕ) (i : Fin n) : BoolFn n := fun v => v i

/-- The NAND gate. -/
def nand {n : ℕ} (f g : BoolFn n) : BoolFn n := fun v => !(f v && g v)

/-- **Circuit size** over the NAND basis: gates and inputs, with fan-out (reuse). -/
noncomputable def circuitK {n : ℕ} (f : BoolFn n) : ℕ∞ := binK (proj n) nand f

/-- **Formula size** over the NAND basis: nodes of an expression tree (no reuse). -/
noncomputable def formulaK {n : ℕ} (f : BoolFn n) : ℕ∞ := binTreeK (proj n) nand f

/-- Circuits are never larger than formulas. -/
theorem circuitK_le_formulaK {n : ℕ} (f : BoolFn n) : circuitK f ≤ formulaK f :=
  binK_le_binTreeK _ _ f

/-- An input costs one step; a gate costs one more step than its inputs. -/
theorem circuitK_proj_le (n : ℕ) (i : Fin n) : circuitK (proj n i) ≤ 1 := binK_gen_le _ _ i

theorem circuitK_nand_le {n : ℕ} (f g : BoolFn n) :
    circuitK (nand f g) ≤ circuitK f + circuitK g + 1 := binK_op_le _ _ f g

/-- Negation, `¬f = f NAND f`, costs one gate: the argument is shared. -/
theorem circuitK_not_le {n : ℕ} (f : BoolFn n) : circuitK (nand f f) ≤ circuitK f + 1 :=
  binK_op_self_le _ _ f

/-- **Formal complexity measures bound formula size.** -/
theorem le_formulaK {n : ℕ} (φ : BoolFn n → ℕ∞) (hproj : ∀ i, φ (proj n i) ≤ 1)
    (hnand : ∀ f g, φ (nand f g) ≤ 1 + (φ f + φ g)) (f : BoolFn n) : φ f ≤ formulaK f :=
  le_binTreeK _ _ φ hproj hnand f

/-- **Shannon's counting theorem.** There are `2 ^ 2ⁿ` Boolean functions of `n` variables
but at most `s · ((n + 1) · s²)ˢ` of them have circuit size at most `s`; so whenever the
latter is smaller, some function is hard. -/
theorem exists_hard_function (n s : ℕ) (h : s * ((n + 1) * s ^ 2) ^ s < 2 ^ 2 ^ n) :
    ∃ f : BoolFn n, (s : ℕ∞) < circuitK f := by
  have hcard : (Finset.univ : Finset (BoolFn n)).card = 2 ^ 2 ^ n := by
    simp [Finset.card_univ]
  obtain ⟨f, -, hf⟩ := exists_binK_gt (proj n) nand s (Finset.univ : Finset (BoolFn n))
    (by rw [hcard, Fintype.card_fin]; exact h)
  exact ⟨f, hf⟩

/-- A concrete case: some Boolean function of five variables needs more than four steps. -/
theorem exists_hard_five : ∃ f : BoolFn 5, (4 : ℕ∞) < circuitK f := by
  have := exists_hard_function 5 4 (by norm_num)
  simpa using this

end Circuit

end Complexity
