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

One statement does need a circuit-specific argument:

* `circuitK_le`            – every function of `n ≥ 1` variables has a circuit, of size at
                             most `5 + 2ⁿ (4n + 7)` (disjunctive normal form). Without it
                             the counting theorem could be satisfied by a function that
                             cannot be built at all.

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

/-! ### Every function has a circuit

The counting theorem says that some function is hard. It would say nothing if hard meant
"cannot be built at all", so here is the other side: with at least one variable, every
Boolean function is built from the inputs by NAND, in at most `5 + 2ⁿ (4n + 7)` steps. The
construction is the disjunctive normal form, with each negation shared. -/

theorem circuitK_nand_le_nat {n : ℕ} {f g : BoolFn n} {a b : ℕ} (hf : circuitK f ≤ a)
    (hg : circuitK g ≤ b) : circuitK (nand f g) ≤ ((a + b + 1 : ℕ) : ℕ∞) :=
  (circuitK_nand_le f g).trans (by push_cast; gcongr)

theorem circuitK_not_le_nat {n : ℕ} {f : BoolFn n} {a : ℕ} (hf : circuitK f ≤ a) :
    circuitK (nand f f) ≤ ((a + 1 : ℕ) : ℕ∞) :=
  (circuitK_not_le f).trans (by push_cast; gcongr)

theorem nand_nand_self {n : ℕ} (f g : BoolFn n) :
    nand (nand f g) (nand f g) = fun v => f v && g v := by
  funext v
  simp only [nand]
  cases f v <;> cases g v <;> rfl

theorem nand_not_not {n : ℕ} (f g : BoolFn n) :
    nand (nand f f) (nand g g) = fun v => f v || g v := by
  funext v
  simp only [nand]
  cases f v <;> cases g v <;> rfl

/-- Conjunction costs two gates. -/
theorem circuitK_and_le {n : ℕ} {f g : BoolFn n} {a b : ℕ} (hf : circuitK f ≤ a)
    (hg : circuitK g ≤ b) : circuitK (fun v => f v && g v) ≤ ((a + b + 2 : ℕ) : ℕ∞) := by
  rw [← nand_nand_self]
  exact (circuitK_not_le_nat (circuitK_nand_le_nat hf hg)).trans (Nat.cast_le.2 (by omega))

/-- Disjunction costs three gates. -/
theorem circuitK_or_le {n : ℕ} {f g : BoolFn n} {a b : ℕ} (hf : circuitK f ≤ a)
    (hg : circuitK g ≤ b) : circuitK (fun v => f v || g v) ≤ ((a + b + 3 : ℕ) : ℕ∞) := by
  rw [← nand_not_not]
  exact (circuitK_nand_le_nat (circuitK_not_le_nat hf) (circuitK_not_le_nat hg)).trans
    (Nat.cast_le.2 (by omega))

theorem circuitK_proj_le_nat (n : ℕ) (i : Fin n) : circuitK (proj n i) ≤ ((1 : ℕ) : ℕ∞) := by
  exact_mod_cast circuitK_proj_le n i

theorem circuitK_true_le {n : ℕ} (hn : 0 < n) :
    circuitK (fun _ => true : BoolFn n) ≤ ((4 : ℕ) : ℕ∞) := by
  have h : (fun _ => true : BoolFn n) =
      nand (proj n ⟨0, hn⟩) (nand (proj n ⟨0, hn⟩) (proj n ⟨0, hn⟩)) := by
    funext v
    simp only [nand, proj]
    cases v ⟨0, hn⟩ <;> rfl
  rw [h]
  exact circuitK_nand_le_nat (circuitK_proj_le_nat n _)
    (circuitK_not_le_nat (circuitK_proj_le_nat n _))

theorem circuitK_false_le {n : ℕ} (hn : 0 < n) :
    circuitK (fun _ => false : BoolFn n) ≤ ((5 : ℕ) : ℕ∞) := by
  have h : (fun _ => false : BoolFn n) = nand (fun _ => true) (fun _ => true) := by
    funext v
    rfl
  rw [h]
  exact circuitK_not_le_nat (circuitK_true_le hn)

/-- A literal: the test `w i = b`. -/
theorem circuitK_lit_le {n : ℕ} (i : Fin n) (b : Bool) :
    circuitK (fun w : Fin n → Bool => decide (w i = b)) ≤ ((2 : ℕ) : ℕ∞) := by
  cases b
  · have h : (fun w : Fin n → Bool => decide (w i = false)) = nand (proj n i) (proj n i) := by
      funext w
      simp only [nand, proj]
      cases w i <;> rfl
    rw [h]
    exact circuitK_not_le_nat (circuitK_proj_le_nat n i)
  · have h : (fun w : Fin n → Bool => decide (w i = true)) = proj n i := by
      funext w
      simp only [proj]
      cases w i <;> rfl
    rw [h]
    exact (circuitK_proj_le_nat n i).trans (Nat.cast_le.2 (by omega))

/-- A partial minterm: the test that `w` agrees with `v` on the variables in `J`. -/
theorem circuitK_minterm_le {n : ℕ} (hn : 0 < n) (v : Fin n → Bool) (J : Finset (Fin n)) :
    circuitK (fun w : Fin n → Bool => decide (∀ i ∈ J, w i = v i)) ≤
      ((4 + 4 * J.card : ℕ) : ℕ∞) := by
  induction J using Finset.induction_on with
  | empty =>
    have h : (fun w : Fin n → Bool => decide (∀ i ∈ (∅ : Finset (Fin n)), w i = v i)) =
        fun _ => true := by
      funext w
      simp
    rw [h]
    simpa using circuitK_true_le hn
  | insert i J hi ih =>
    have h : (fun w : Fin n → Bool => decide (∀ j ∈ insert i J, w j = v j)) =
        fun w => decide (w i = v i) && decide (∀ j ∈ J, w j = v j) := by
      funext w
      simp
    rw [h, Finset.card_insert_of_notMem hi]
    exact (circuitK_and_le (circuitK_lit_le i (v i)) ih).trans (Nat.cast_le.2 (by omega))

/-- The indicator of a set of assignments, as a disjunction of minterms. -/
theorem circuitK_indicator_le {n : ℕ} (hn : 0 < n) (S : Finset (Fin n → Bool)) :
    circuitK (fun w : Fin n → Bool => decide (w ∈ S)) ≤
      ((5 + S.card * (4 * n + 7) : ℕ) : ℕ∞) := by
  induction S using Finset.induction_on with
  | empty =>
    have h : (fun w : Fin n → Bool => decide (w ∈ (∅ : Finset (Fin n → Bool)))) =
        fun _ => false := by
      funext w
      simp
    rw [h]
    simpa using circuitK_false_le hn
  | insert v S hv ih =>
    have hm : circuitK (fun w : Fin n → Bool => decide (w = v)) ≤ ((4 + 4 * n : ℕ) : ℕ∞) := by
      have h : (fun w : Fin n → Bool => decide (w = v)) =
          fun w => decide (∀ i ∈ (Finset.univ : Finset (Fin n)), w i = v i) := by
        funext w
        simp [funext_iff]
      rw [h]
      simpa using circuitK_minterm_le hn v Finset.univ
    have h : (fun w : Fin n → Bool => decide (w ∈ insert v S)) =
        fun w => decide (w = v) || decide (w ∈ S) := by
      funext w
      simp [Finset.mem_insert]
    rw [h, Finset.card_insert_of_notMem hv]
    have e : (S.card + 1) * (4 * n + 7) = S.card * (4 * n + 7) + (4 * n + 7) := by ring
    exact (circuitK_or_le hm ih).trans (Nat.cast_le.2 (by omega))

/-- **Every Boolean function has a circuit.** With at least one variable, a function of `n`
variables costs at most `5 + 2ⁿ (4n + 7)` steps over NAND. -/
theorem circuitK_le {n : ℕ} (hn : 0 < n) (f : BoolFn n) :
    circuitK f ≤ ((5 + 2 ^ n * (4 * n + 7) : ℕ) : ℕ∞) := by
  have h : f = fun w => decide (w ∈ Finset.univ.filter fun w : Fin n → Bool => f w = true) := by
    funext w
    simp
  have hc : (Finset.univ.filter fun w : Fin n → Bool => f w = true).card ≤ 2 ^ n := by
    refine (Finset.card_filter_le _ _).trans ?_
    simp
  rw [congrArg circuitK h]
  exact (circuitK_indicator_le hn _).trans
    (Nat.cast_le.2 (Nat.add_le_add_left (Nat.mul_le_mul_right _ hc) _))

theorem circuitK_lt_top {n : ℕ} (hn : 0 < n) (f : BoolFn n) : circuitK f < ⊤ :=
  lt_of_le_of_lt (circuitK_le hn f) (ENat.natCast_lt_top _)

/-- **Shannon's counting theorem, with the other side.** Under the same hypothesis, and
with at least one variable, the hard function still has a circuit: its size is more than
`s` and at most `5 + 2ⁿ (4n + 7)`. -/
theorem exists_hard_function_between (n s : ℕ) (hn : 0 < n)
    (h : s * ((n + 1) * s ^ 2) ^ s < 2 ^ 2 ^ n) :
    ∃ f : BoolFn n, (s : ℕ∞) < circuitK f ∧
      circuitK f ≤ ((5 + 2 ^ n * (4 * n + 7) : ℕ) : ℕ∞) := by
  obtain ⟨f, hf⟩ := exists_hard_function n s h
  exact ⟨f, hf, circuitK_le hn f⟩

end Circuit

end Complexity
