import Complexity.Binary

/-!
# Instance: monoids – addition chains, straight-line programs, assembly of strings

A monoid with a family of generators is a generative system: the generators are constants
and multiplication is the one binary operation. Its DAG complexity with unit step cost is

* the **addition-chain length** when the monoid is `(ℕ, +)` with generator `1`
  (number theory),
* the **straight-line program / smallest-grammar size** when the monoid is the free monoid
  of strings (data compression),
* the **assembly index** of a string or linear polymer (assembly theory).

The three fields prove the same three facts in three vocabularies; here they are one set
of corollaries of `Reuse.lean`:

* `slK_mul_le`           – concatenating costs one step;
* `slK_pow_two_pow_le`   – **doubling**: `K(x^(2^k)) ≤ K(x) + k` (repetition is cheap);
* `mul_two_le_two_pow`   – **logarithmic lower bound**: `K(x) ≥ 1 + log₂ μ(x)` for every
                           subadditive size `μ`;
* `le_treeK`             – without reuse the cost is at least the size itself, so
* `Chain.two_pow_le_treeK` / `Chain.chainK_two_pow_le` – reuse buys an **exponential**
                           saving: `2^k` costs `≥ 2^k` as a tree and `≤ k + 1` as a DAG.
-/

namespace Complexity

namespace MonoidGen

open Binary

universe u

variable {ι : Type u} {M : Type*} [Monoid M]

/-- **Straight-line complexity** of a monoid element: the least number of steps
(generator introductions and multiplications of already-built elements) producing it. -/
noncomputable def slK (gen : ι → M) (x : M) : ℕ∞ := binK gen (· * ·) x

/-- A generator costs one step. -/
theorem slK_gen_le (gen : ι → M) (i : ι) : slK gen (gen i) ≤ 1 := binK_gen_le gen _ i

/-- A product costs one step more than its factors. -/
theorem slK_mul_le (gen : ι → M) (x y : M) : slK gen (x * y) ≤ slK gen x + slK gen y + 1 :=
  binK_op_le gen _ x y

/-- **Squaring costs one step**: the factor is built once and used twice. -/
theorem slK_sq_le (gen : ι → M) (x : M) : slK gen (x * x) ≤ slK gen x + 1 :=
  binK_op_self_le gen _ x

/-- **Doubling.** `2^k`-fold repetition costs only `k` further steps. -/
theorem slK_pow_two_pow_le (gen : ι → M) (x : M) (k : ℕ) :
    slK gen (x ^ 2 ^ k) ≤ slK gen x + k := by
  induction k with
  | zero => simp
  | succ k ih =>
    have h : x ^ 2 ^ (k + 1) = x ^ 2 ^ k * x ^ 2 ^ k := by rw [pow_succ, pow_mul, sq]
    rw [h]
    calc slK gen (x ^ 2 ^ k * x ^ 2 ^ k) ≤ slK gen (x ^ 2 ^ k) + 1 := slK_sq_le gen _
      _ ≤ slK gen x + k + 1 := add_le_add ih le_rfl
      _ = slK gen x + ((k + 1 : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]

/-- **Logarithmic lower bound.** For every size function `μ` that is at most `1` on
generators and subadditive under multiplication, `μ x ≤ 2 ^ (K x - 1)`. -/
theorem mul_two_le_two_pow (gen : ι → M) (μ : M → ℕ) (hgen : ∀ i, μ (gen i) ≤ 1)
    (hmul : ∀ x y, μ (x * y) ≤ μ x + μ y) {x : M} {n : ℕ} (h : slK gen x ≤ n) :
    μ x * 2 ≤ 2 ^ n :=
  Binary.mul_two_le_two_pow gen _ μ hgen hmul h

/-- **Without reuse, cost is at least size.** -/
theorem le_treeK (gen : ι → M) (μ : M → ℕ) (hgen : ∀ i, μ (gen i) ≤ 1)
    (hmul : ∀ x y, μ (x * y) ≤ μ x + μ y) (x : M) :
    (μ x : ℕ∞) ≤ binTreeK gen (· * ·) x :=
  natCast_le_binTreeK gen _ μ hgen hmul x

end MonoidGen

/-! ### Addition chains -/

namespace Chain

open MonoidGen

/-- The generator `1` of the additive monoid of naturals, written multiplicatively. -/
def one : Unit → Multiplicative ℕ := fun _ => Multiplicative.ofAdd 1

/-- **Addition-chain complexity** of `n`: the least number of steps (introducing `1`, or
adding two numbers already obtained) that produces `n`. -/
noncomputable def chainK (n : ℕ) : ℕ∞ := slK one (Multiplicative.ofAdd n)

/-- Powers of two are reached by repeated doubling. -/
theorem chainK_two_pow_le (k : ℕ) : chainK (2 ^ k) ≤ k + 1 := by
  have h : Multiplicative.ofAdd (2 ^ k) = (one ()) ^ 2 ^ k := by
    rw [one, ← ofAdd_nsmul]
    simp
  rw [chainK, h, add_comm]
  exact (slK_pow_two_pow_le one (one ()) k).trans (add_le_add (slK_gen_le one ()) le_rfl)

/-- **`l(n) ≥ log₂ n`.** A chain of `k` steps reaches no number above `2 ^ (k - 1)`. -/
theorem two_mul_le_two_pow {n k : ℕ} (h : chainK n ≤ k) : n * 2 ≤ 2 ^ k :=
  mul_two_le_two_pow one (fun x => x.toAdd) (fun _ => le_rfl) (fun _ _ => le_rfl) h

/-- Without reuse (as a sum of ones) `2 ^ k` costs at least `2 ^ k`: with
`chainK_two_pow_le`, reuse is an exponential saving. -/
theorem two_pow_le_treeK (k : ℕ) :
    ((2 ^ k : ℕ) : ℕ∞) ≤
      Binary.binTreeK one (· * ·) (Multiplicative.ofAdd (2 ^ k)) :=
  le_treeK one (fun x => x.toAdd) (fun _ => le_rfl) (fun _ _ => le_rfl)
    (Multiplicative.ofAdd (2 ^ k))

end Chain

/-! ### Strings -/

namespace Str

open MonoidGen

variable {α : Type*}

/-- **Straight-line (grammar / assembly) complexity of a string**: the least number of
steps – writing a letter, or concatenating two strings already built – producing it. -/
noncomputable def strK (w : FreeMonoid α) : ℕ∞ := slK (FreeMonoid.of : α → FreeMonoid α) w

/-- A string built in `n` steps has length at most `2 ^ (n - 1)`. -/
theorem length_mul_two_le {w : FreeMonoid α} {n : ℕ} (h : strK w ≤ n) :
    w.toList.length * 2 ≤ 2 ^ n :=
  mul_two_le_two_pow FreeMonoid.of (fun w => w.toList.length) (fun _ => by simp)
    (fun a b => by simp) h

/-- Repetition is cheap: `w` repeated `2 ^ k` times costs `k` steps more than `w`. -/
theorem strK_pow_two_pow_le (w : FreeMonoid α) (k : ℕ) : strK (w ^ 2 ^ k) ≤ strK w + k :=
  slK_pow_two_pow_le _ w k

/-- Without reuse a string costs at least its length. -/
theorem length_le_treeK (w : FreeMonoid α) :
    (w.toList.length : ℕ∞) ≤
      Binary.binTreeK (FreeMonoid.of : α → FreeMonoid α) (· * ·) w :=
  le_treeK FreeMonoid.of (fun w => w.toList.length) (fun _ => by simp)
    (fun a b => by simp) w

end Str

end Complexity
