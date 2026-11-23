import Complexity.Basic
import Complexity.CostAlgebra

/-!
# Shannon entropy is a complexity

Shannon entropy is not a rival notion to description complexity: it is within one bit of the complexity
`K` of the one definition in `Basic.lean`, for a particular setting of the dials.

* **objects**      – a source: a probability distribution `p` on a finite alphabet `α`
                     (there is one object, so `X = Unit`);
* **descriptions** – codes for the source, represented by their code-length assignments
                     `l : α → ℕ` satisfying **Kraft's inequality** `∑ 2^(-l a) ≤ 1`
                     (exactly the length profiles of prefix codes);
* **cost**         – the *expected* code length `∑ p a · l a`, valued in `ℝ≥0∞`;
* **fidelity**     – every admissible code describes the source.

For this description system the least cost is the entropy, up to one bit:

  `H(p) ≤ K ≤ H(p) + 1`.

* `entropy_le_expLen`      – the **converse** of noiseless source coding (Gibbs'
                             inequality): no Kraft-admissible code beats the entropy;
* `exists_kraft_expLen_lt` – **achievability** (the Shannon code `l a = ⌈-log₂ p a⌉`):
                             some admissible code is within one bit of the entropy;
* `entropy_le_K_le`        – the two together, as a statement about `DescSystem.K`.

So "entropy" is what the cost dial reads when cost is *expected* length over an ensemble,
where Kolmogorov-style measures read the length of a description of one individual.

**Review note.** The `K` of `sourceSystem` is the optimal one-shot expected code length `L*`,
with `H ≤ L* ≤ H + 1`; it equals `H` only for dyadic sources (on two letters `L* = 1`
whatever `H` is). Descriptions are Kraft-admissible length functions, not codes
(Kraft–McMillan is not formalized), and the block-coding limit `L*(pⁿ)/n → H` is absent.
The proof is the textbook Gibbs argument and uses none of the general laws.
-/

namespace Complexity

namespace Shannon

open scoped ENNReal

variable {α : Type*} [Fintype α]

/-- Shannon entropy in bits. -/
noncomputable def entropy (p : α → ℝ) : ℝ := -∑ a, p a * Real.logb 2 (p a)

/-- Kraft's inequality for a code-length assignment. -/
def Kraft (l : α → ℕ) : Prop := ∑ a, (2 : ℝ)⁻¹ ^ l a ≤ 1

/-- Expected code length. -/
noncomputable def expLen (p : α → ℝ) (l : α → ℕ) : ℝ := ∑ a, p a * l a

/-! ### Gibbs' inequality -/

/-- The pointwise inequality behind Gibbs' inequality: `p (log q - log p) ≤ q - p`. -/
theorem mul_log_sub_log_le {p q : ℝ} (hp : 0 ≤ p) (hq : 0 < q) :
    p * (Real.log q - Real.log p) ≤ q - p := by
  rcases hp.eq_or_lt with h0 | hpos
  · rw [← h0, zero_mul, sub_zero]
    exact hq.le
  · have h1 : Real.log (q / p) ≤ q / p - 1 := Real.log_le_sub_one_of_pos (div_pos hq hpos)
    rw [Real.log_div hq.ne' hpos.ne'] at h1
    have hne : p ≠ 0 := hpos.ne'
    calc p * (Real.log q - Real.log p) ≤ p * (q / p - 1) :=
          mul_le_mul_of_nonneg_left h1 hpos.le
      _ = q - p := by field_simp

/-- **Gibbs' inequality**, unnormalized form: for non-negative weights `p` and positive
weights `q`, `∑ p (log q - log p) ≤ ∑ q - ∑ p`. -/
theorem sum_mul_log_sub_log_le (p q : α → ℝ) (hp : ∀ a, 0 ≤ p a) (hq : ∀ a, 0 < q a) :
    ∑ a, p a * (Real.log (q a) - Real.log (p a)) ≤ ∑ a, q a - ∑ a, p a := by
  rw [← Finset.sum_sub_distrib]
  exact Finset.sum_le_sum fun a _ => mul_log_sub_log_le (hp a) (hq a)

/-- Entropy is non-negative. -/
theorem entropy_nonneg (p : α → ℝ) (hp : ∀ a, 0 ≤ p a) (hsum : ∑ a, p a = 1) :
    0 ≤ entropy p := by
  unfold entropy
  rw [neg_nonneg]
  refine Finset.sum_nonpos fun a _ => mul_nonpos_of_nonneg_of_nonpos (hp a) ?_
  exact Real.logb_nonpos one_lt_two (hp a)
    ((Finset.single_le_sum (fun i _ => hp i) (Finset.mem_univ a)).trans_eq hsum)

/-! ### The converse: no admissible code beats the entropy -/

/-- Source-coding converse (Gibbs). -/
theorem entropy_le_expLen (p : α → ℝ) (hp : ∀ a, 0 ≤ p a) (hsum : ∑ a, p a = 1)
    (l : α → ℕ) (hl : Kraft l) : entropy p ≤ expLen p l := by
  have hlog2 : 0 < Real.log 2 := Real.log_pos one_lt_two
  have hlog2' : Real.log 2 ≠ 0 := hlog2.ne'
  have hq : ∀ a, (0 : ℝ) < (2 : ℝ)⁻¹ ^ l a := fun a => by positivity
  have hgibbs := sum_mul_log_sub_log_le p (fun a => (2 : ℝ)⁻¹ ^ l a) hp hq
  have hle : ∑ a, p a * (Real.log ((2 : ℝ)⁻¹ ^ l a) - Real.log (p a)) ≤ 0 := by
    have hl' : ∑ a, (2 : ℝ)⁻¹ ^ l a ≤ 1 := hl
    linarith
  have hkey : entropy p - expLen p l =
      (∑ a, p a * (Real.log ((2 : ℝ)⁻¹ ^ l a) - Real.log (p a))) / Real.log 2 := by
    unfold entropy expLen
    rw [Finset.sum_div, ← Finset.sum_neg_distrib, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun a _ => ?_
    rw [Real.log_pow, Real.log_inv, Real.logb]
    field_simp
    ring
  have h3 : entropy p - expLen p l ≤ 0 := by
    rw [hkey]
    exact div_nonpos_of_nonpos_of_nonneg hle hlog2.le
  linarith

/-! ### Achievability: the Shannon code -/

/-- Shannon code: achievability within one bit. -/
theorem exists_kraft_expLen_lt (p : α → ℝ) (hp : ∀ a, 0 < p a) (hsum : ∑ a, p a = 1) :
    ∃ l : α → ℕ, Kraft l ∧ expLen p l < entropy p + 1 := by
  have hle1 : ∀ a, p a ≤ 1 := fun a =>
    (Finset.single_le_sum (fun i _ => (hp i).le) (Finset.mem_univ a)).trans_eq hsum
  have hnn : ∀ a, 0 ≤ -Real.logb 2 (p a) := fun a =>
    neg_nonneg.2 (Real.logb_nonpos one_lt_two (hp a).le (hle1 a))
  have hne : (Finset.univ : Finset α).Nonempty := by
    by_contra h
    rw [Finset.not_nonempty_iff_eq_empty] at h
    rw [h, Finset.sum_empty] at hsum
    exact zero_ne_one hsum
  -- the Shannon code words are short enough to be decodable …
  have hterm : ∀ a, (2 : ℝ)⁻¹ ^ ⌈-Real.logb 2 (p a)⌉₊ ≤ p a := by
    intro a
    have h1 : -((⌈-Real.logb 2 (p a)⌉₊ : ℕ) : ℝ) ≤ Real.logb 2 (p a) := by
      have := Nat.le_ceil (-Real.logb 2 (p a))
      linarith
    have h2 := (Real.le_logb_iff_rpow_le one_lt_two (hp a)).1 h1
    rwa [Real.rpow_neg zero_le_two, Real.rpow_natCast, ← inv_pow] at h2
  refine ⟨fun a => ⌈-Real.logb 2 (p a)⌉₊, ?_, ?_⟩
  · show ∑ a, (2 : ℝ)⁻¹ ^ ⌈-Real.logb 2 (p a)⌉₊ ≤ 1
    exact (Finset.sum_le_sum fun a _ => hterm a).trans_eq hsum
  · -- … and long by less than one bit each.
    show ∑ a, p a * ((⌈-Real.logb 2 (p a)⌉₊ : ℕ) : ℝ) < entropy p + 1
    have hlt : ∑ a, p a * ((⌈-Real.logb 2 (p a)⌉₊ : ℕ) : ℝ) <
        ∑ a, p a * (-Real.logb 2 (p a) + 1) :=
      Finset.sum_lt_sum_of_nonempty hne fun a _ =>
        mul_lt_mul_of_pos_left (Nat.ceil_lt_add_one (hnn a)) (hp a)
    have heq : ∑ a, p a * (-Real.logb 2 (p a) + 1) = entropy p + 1 := by
      unfold entropy
      have h : ∀ a, p a * (-Real.logb 2 (p a) + 1) = -(p a * Real.logb 2 (p a)) + p a :=
        fun a => by ring
      simp only [h]
      rw [Finset.sum_add_distrib, Finset.sum_neg_distrib, hsum]
    rw [← heq]
    exact hlt

/-! ### Entropy as the complexity of a description system -/

/-- Kraft-admissible codes as a description system for the source. -/
noncomputable def sourceSystem (p : α → ℝ) : DescSystem {l : α → ℕ // Kraft l} Unit ℝ≥0∞ where
  cost l := ENNReal.ofReal (expLen p l.1)
  realizes _ _ := True

/-- The entropy bounds the complexity of the source from below (no support hypothesis). -/
theorem entropy_le_K (p : α → ℝ) (hp : ∀ a, 0 ≤ p a) (hsum : ∑ a, p a = 1) :
    ENNReal.ofReal (entropy p) ≤ (sourceSystem p).K () :=
  (sourceSystem p).le_K_iff.2 fun l _ =>
    ENNReal.ofReal_le_ofReal (entropy_le_expLen p hp hsum l.1 l.2)

/-- The complexity of a full-support source is within one bit of its entropy. -/
theorem K_le_entropy_add_one (p : α → ℝ) (hp : ∀ a, 0 < p a) (hsum : ∑ a, p a = 1) :
    (sourceSystem p).K () ≤ ENNReal.ofReal (entropy p + 1) := by
  obtain ⟨l, hl, hlt⟩ := exists_kraft_expLen_lt p hp hsum
  exact ((sourceSystem p).K_le_cost (d := ⟨l, hl⟩) (x := ()) trivial).trans
    (ENNReal.ofReal_le_ofReal hlt.le)

/-- Entropy is the complexity of the source, within one bit. -/
theorem entropy_le_K_le (p : α → ℝ) (hp : ∀ a, 0 < p a) (hsum : ∑ a, p a = 1) :
    ENNReal.ofReal (entropy p) ≤ (sourceSystem p).K () ∧
      (sourceSystem p).K () ≤ ENNReal.ofReal (entropy p + 1) :=
  ⟨entropy_le_K p (fun a => (hp a).le) hsum, K_le_entropy_add_one p hp hsum⟩

end Shannon

end Complexity
