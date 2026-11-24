import Complexity.Reuse
import Complexity.Growth

/-!
# Binary generative systems

The commonest shape of generative system: a family of **generators** and **one binary
operation**. Multiplication in a monoid, a NAND gate on Boolean functions, the join of two
fragments, concatenation of strings, application of one term to another.

This file specializes the general theory of `Generative.lean`, `Reuse.lean` and
`Growth.lean` to that shape once, so that addition chains, grammars and Boolean circuits
are literally the same theorems. Assembly pathways fit only when a join of two fragments
has a single result; the counting law in particular needs that.

* `binK` / `binTreeK`   – complexity with reuse (DAG) and without (tree), unit step cost;
* `binK_op_self_le`     – using something twice costs one step;
* `binK_le_binTreeK`    – reuse never hurts;
* `mul_two_le_two_pow`  – **logarithmic law**: `μ x ≤ 2 ^ (K x - 1)` for subadditive `μ`;
* `le_binTreeK`         – **formal complexity measures**: every `φ` with `φ(gen) ≤ 1` and
                          `φ(op x y) ≤ 1 + φ x + φ y` is a lower bound on tree complexity;
* `exists_binK_gt`      – **counting law**: any population of more than
                          `n · ((#gens + 1) · n²)ⁿ` objects contains one of complexity
                          greater than `n`.
-/

namespace Complexity

namespace Binary

open Sig

universe u

/-- The signature with constants indexed by `ι` (`some i`, arity `0`) and one binary
operation (`none`, arity `2`). -/
abbrev binSig (ι : Type u) : Sig.{u, 0} where
  Op := Option ι
  Ar o := Fin (o.elim 2 fun _ => 0)

variable {ι : Type u} {M : Type*}

/-- Generators and a binary operation, as an algebra for `binSig`. -/
def binAlg (gen : ι → M) (op : M → M → M) : (binSig ι).Alg M
  | some i, _ => gen i
  | none, xs => op (xs (0 : Fin 2)) (xs (1 : Fin 2))

/-- **Complexity with reuse**: the least number of steps – introducing a generator, or
applying the operation to two things already built – that produces `x`. -/
noncomputable def binK (gen : ι → M) (op : M → M → M) (x : M) : ℕ∞ :=
  dagK (binAlg gen op) (fun _ => 1) x

/-- **Complexity without reuse**: the least number of nodes of an expression tree for
`x`. -/
noncomputable def binTreeK (gen : ι → M) (op : M → M → M) (x : M) : ℕ∞ :=
  treeK (binAlg gen op) (sizeRule (binSig ι) fun _ => 1) x

variable (gen : ι → M) (op : M → M → M)

/-- A generator costs one step. -/
theorem binK_gen_le (i : ι) : binK gen op (gen i) ≤ 1 := by
  have h : dagK (binAlg gen op) (fun _ => 1) (gen i) ≤
      poolK (binAlg gen op) (fun _ => 1) (Set.range fun b : Fin 0 => (b.elim0 : M)) + 1 :=
    dagK_alg_range_le (alg := binAlg gen op) (wt := fun _ => 1) (some i)
      fun b : Fin 0 => b.elim0
  have hr : (Set.range fun b : Fin 0 => (b.elim0 : M)) = ∅ := Set.range_eq_empty _
  rw [hr, poolK_empty, zero_add] at h
  exact h

/-- Applying the operation costs one step more than building the two arguments. -/
theorem binK_op_le (x y : M) : binK gen op (op x y) ≤ binK gen op x + binK gen op y + 1 := by
  have h : dagK (binAlg gen op) (fun _ => 1) (op x y) ≤
      poolK (binAlg gen op) (fun _ => 1) (Set.range ![x, y]) + 1 :=
    dagK_alg_range_le (alg := binAlg gen op) (wt := fun _ => 1) none ![x, y]
  refine h.trans (add_le_add ?_ le_rfl)
  have hr : Set.range ![x, y] = {x} ∪ {y} := by
    ext z
    simp [eq_comm]
  rw [hr]
  exact poolK_union_le _ _

/-- **Using something twice costs one step**: the argument is built once. -/
theorem binK_op_self_le (x : M) : binK gen op (op x x) ≤ binK gen op x + 1 :=
  dagK_alg_const_le (alg := binAlg gen op) (wt := fun _ => 1) none x

/-- **Reuse never hurts.** -/
theorem binK_le_binTreeK (x : M) : binK gen op x ≤ binTreeK gen op x :=
  dagK_le_treeK x

theorem card_ar_le_two (a : (binSig ι).Op) : Fintype.card ((binSig ι).Ar a) ≤ 2 := by
  rcases a with _ | i
  · show Fintype.card (Fin 2) ≤ 2
    simp
  · show Fintype.card (Fin 0) ≤ 2
    simp

/-- **Logarithmic law.** For every size `μ` that is at most `1` on generators and
subadditive under the operation, anything built in `n` steps has `μ ≤ 2 ^ (n - 1)`. -/
theorem mul_two_le_two_pow (μ : M → ℕ) (hgen : ∀ i, μ (gen i) ≤ 1)
    (hop : ∀ x y, μ (op x y) ≤ μ x + μ y) {x : M} {n : ℕ} (h : binK gen op x ≤ n) :
    μ x * 2 ≤ 2 ^ n := by
  refine mul_le_pow_of_dagK_le (alg := binAlg gen op) μ 2 (by norm_num) card_ar_le_two ?_ h
  rintro (_ | i) xs
  · show μ (op (xs (0 : Fin 2)) (xs (1 : Fin 2))) ≤ max 1 (∑ b : Fin 2, μ (xs b))
    rw [Fin.sum_univ_two]
    exact le_max_of_le_right (hop _ _)
  · exact le_max_of_le_left (hgen i)

/-- **Formal complexity measures.** Any `φ` that is at most `1` on generators and satisfies
`φ (op x y) ≤ 1 + φ x + φ y` is a potential for the size rule, hence a lower bound on tree
complexity. -/
theorem le_binTreeK (φ : M → ℕ∞) (hgen : ∀ i, φ (gen i) ≤ 1)
    (hop : ∀ x y, φ (op x y) ≤ 1 + (φ x + φ y)) (x : M) : φ x ≤ binTreeK gen op x := by
  refine IsPotential.le_treeK (φ := φ) ?_ x
  rintro (_ | i) xs
  · show φ (op (xs (0 : Fin 2)) (xs (1 : Fin 2))) ≤ 1 + ∑ b : Fin 2, φ (xs b)
    rw [Fin.sum_univ_two]
    exact hop _ _
  · show φ (gen i) ≤ 1 + ∑ b : Fin 0, φ (xs b)
    simpa using hgen i

/-- **Without reuse, cost is at least size**: natural-valued subadditive sizes bound tree
complexity from below. -/
theorem natCast_le_binTreeK (μ : M → ℕ) (hgen : ∀ i, μ (gen i) ≤ 1)
    (hop : ∀ x y, μ (op x y) ≤ μ x + μ y) (x : M) : (μ x : ℕ∞) ≤ binTreeK gen op x := by
  refine le_binTreeK gen op (fun x => (μ x : ℕ∞)) (fun i => by exact_mod_cast hgen i)
    (fun x y => ?_) x
  have h1 : ((μ (op x y) : ℕ) : ℕ∞) ≤ ((μ x + μ y : ℕ) : ℕ∞) := by exact_mod_cast hop x y
  refine h1.trans ?_
  push_cast
  exact le_add_self

/-- **Counting law.** With finitely many generators, any population of more than
`n · ((#gens + 1) · n²)ⁿ` objects contains one whose complexity exceeds `n`. -/
theorem exists_binK_gt [Fintype ι] (n : ℕ) (A : Finset M)
    (hA : n * ((Fintype.card ι + 1) * n ^ 2) ^ n < A.card) :
    ∃ x ∈ A, (n : ℕ∞) < binK gen op x := by
  have hcard : Fintype.card (binSig ι).Op = Fintype.card ι + 1 := Fintype.card_option
  have := exists_dagK_gt (alg := binAlg gen op) 2 card_ar_le_two n A (by rw [hcard]; exact hA)
  exact this

end Binary

end Complexity
