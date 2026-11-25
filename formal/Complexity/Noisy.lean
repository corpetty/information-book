import Mathlib.LinearAlgebra.Matrix.Stochastic
import Mathlib.Basic.Real.Basic
import Mathlib.Tactic

/-!
# Noisy hops: when distinguishability decays with depth

`Lossy.lean` and `Instances/Channel.lean` model a hop as a function. Through one fixed chain
of functions the only loss is merging: two ideas are merged or kept perfectly apart. The
chapter this library serves says something stronger, that a share `p` survives each hop and
`pᴺ` survives `N` hops. This file gives a sufficient hypothesis for a law of that shape, and
says which quantity it is a law about.

A hop is a row-stochastic matrix `P` on a finite set of ideas: `P x z` is the probability
that a receiver who is told `x` passes on `z`. Mathlib's `Matrix.rowStochastic` is used.
The *advantage* of a test `A` (a set of outcomes) between two originals is the difference
in the probability that the outcome lies in `A`.

* `Forgets c P` – the hop **forgets with probability at least `1 - c`** (meant for
  `0 ≤ c ≤ 1`): there is a fixed distribution `ν` (what the receiver falls back on) such
  that `P x z ≥ (1 - c) ν z` for every `x`. This is Doeblin's minorization condition. For
  `c ≥ 1` it is no condition at all (`forgets_of_one_le`).
* `advantage_le` – **distinguishability decays**: after hops that forget with
  `c 0, …, c (n-1)`, no test has advantage more than the product `c 0 ⋯ c (n-1)`. With the
  same `c` at every hop this is `cⁿ`. `survive_le` is the reading as survival: the original
  arrives intact at most `cⁿ` more often than it would have arrived had something else been
  sent.
* `guess_le` – the same as a guessing bound: told that the original was one of two equally
  likely ideas, a receiver at depth `n` is right with probability at most `(1 + cⁿ) / 2`.
* `fade`, `fade_mem`, `fade_forgets`, `chain_fade`, `advantage_fade` – **the bound is
  attained**: the hop that passes the idea on unchanged with probability `c` and otherwise
  replaces it by a draw from `ν` has advantage exactly `cⁿ` after `n` hops.
* `Contracts c P`, `advantage_le_of_contracts` – **the general one-hop condition**:
  `Contracts c P` says that no test tells any two inputs of the one hop `P` apart with
  advantage more than `c` (the least such `c` is Dobrushin's coefficient). Then the
  advantage after `n` hops is at most the product of the one-hop constants: the bounds
  multiply. Forgetting implies it (`Forgets.contracts`) and is not needed: `lazyCycle`
  forgets nothing in one step and contracts with `9/10`, and no less (`lazyCycle_least`).
* `lazyCycle_two_hops`, `lazyFour_not_contracts`, `lazyFour_two_hops` – the product is a
  bound, not the truth: two lazy-cycle hops contract with `4/5 < (9/10)²`; and on four
  ideas one hop does not contract at all while two hops do. The one-hop condition is
  necessary and sufficient for the bound `cⁿ` at every depth, not for geometric decay.

**Which quantity.** Three things could be meant by "what survives `n` hops".

* Intact at every hop: the product of the `P k x x`, with no forgetting needed, and it is a
  *lower* bound on arriving intact (`intact_prod_le_chain`, `intact_pow_le_chain`).
* Arrives intact: for the fading hop this is `cⁿ + (1 - cⁿ) ν x` (`prob_fade_self`), which
  tends to `ν x`, not to `0`.
* Advantage: this is what is bounded by `cⁿ`, and `c` is the worst one-hop advantage, not
  the chance `p` of passing the idea on unchanged. The two are related one way only:
  `c ≥ 2p - 1` (`two_mul_sub_one_le_of_contracts`, which says something only for
  `p > 1/2`), while a hop that leaves nothing unchanged can need `c = 1`
  (`swap_keeps_nothing`).

For the fading hop with a fallback that never produces `x`, all three are `cⁿ`.

**Functions and randomness.**

* `forgets_detHop`, `forgets_const` – a hop that is a function forgets with `c < 1` exactly
  when it is constant.
* `detHop_dichotomy` – through one fixed chain of functions, a given pair of originals is
  either merged (no test has any advantage) or told apart with certainty.
* `fade_eq_mixture` – but the fading hop *is* a random choice among functions: the identity
  with probability `c`, a constant otherwise. So a fractional advantage needs randomness,
  and that randomness may be noise inside one reteller or not knowing which reteller one
  gets. And over a repertoire of ideas a single function relay can lose a fixed share per
  hop (`Limits.leak_iterate_length`).

**A second route.**

* `two_routes` – through two independent chains of `n` fading hops, the test "neither route
  delivered `x`" has advantage `cⁿ + cⁿ (1 - cⁿ) (1 - 2 ν x)`.
* `two_routes_beat_one` – for `0 < c < 1` and `n ≥ 1` that is more than any test on one
  chain can have, when the fallback produces `x` less than half the time.
* `two_routes_no_gain_bool` – for two ideas with a fair-coin fallback, no test on the pair
  beats one chain.
* `two_routes_le` – in general, if one copy of a chain allows advantage at most `a`, two
  independent copies allow at most `1 - (1 - a)²`: a second route adds at most `a (1 - a)`,
  which `two_routes` attains. It changes the constant, not the rate.

Independence of the two routes is built into the definition `prob2`, not derived.

None of this is new mathematics. That Dobrushin's coefficient is submultiplicative along a
chain is the total-variation case of the strong data-processing inequality; Doeblin's
minorization is the standard sufficient condition (`advantage_le`). What
happens on a tree, where redundancy grows with depth, is the "broadcasting on trees"
problem and is not formalized here.
-/

namespace Complexity

namespace Noisy

open Matrix Finset

variable {α : Type*} [Fintype α] [DecidableEq α]

/-! ### Hops that forget -/

/-- The hop `P` forgets with probability at least `1 - c`: whatever it is told, with that
probability it passes on a draw from a fixed distribution `ν`. (Doeblin's condition.) Meant
for `0 ≤ c ≤ 1`; for `c ≥ 1` every hop satisfies it (`forgets_of_one_le`). -/
def Forgets (c : ℝ) (P : Matrix α α ℝ) : Prop :=
  ∃ ν : α → ℝ, (∀ z, 0 ≤ ν z) ∧ ∑ z, ν z = 1 ∧ ∀ x z, (1 - c) * ν z ≤ P x z

/-- The probability that the hop (or chain) `K`, told `x`, passes on something in `A`. -/
def prob (K : Matrix α α ℝ) (x : α) (A : Finset α) : ℝ := ∑ z ∈ A, K x z

theorem prob_eq_mulVec (K : Matrix α α ℝ) (x : α) (A : Finset α) :
    prob K x A = (K *ᵥ fun z => if z ∈ A then (1 : ℝ) else 0) x := by
  simp [prob, mulVec, dotProduct, Finset.sum_ite_mem]

theorem prob_compl {K : Matrix α α ℝ} (hK : K ∈ rowStochastic ℝ α) (x : α) (A : Finset α) :
    prob K x Aᶜ = 1 - prob K x A := by
  have h := Finset.sum_compl_add_sum A (fun z => K x z)
  rw [(mem_rowStochastic_iff_sum.1 hK).2 x] at h
  simp only [prob]
  linarith

/-- **One forgetting hop shrinks every test's spread by the factor `c`.** If a test `g` of
the outcome varies by at most `D`, its expectation after the hop varies by at most `c D`
over what the hop was told. -/
theorem spread_mulVec_le {c : ℝ} {P : Matrix α α ℝ} (hP : P ∈ rowStochastic ℝ α)
    (hc : Forgets c P) {g : α → ℝ} {D : ℝ} (hg : ∀ z z', g z - g z' ≤ D) (x x' : α) :
    (P *ᵥ g) x - (P *ᵥ g) x' ≤ c * D := by
  obtain ⟨ν, _, hν1, hmin⟩ := hc
  have hsum := (mem_rowStochastic_iff_sum.1 hP).2
  obtain ⟨zM, -, hM⟩ := Finset.exists_max_image univ g ⟨x, mem_univ x⟩
  obtain ⟨zm, -, hm⟩ := Finset.exists_min_image univ g ⟨x, mem_univ x⟩
  have hRsum : ∀ y, ∑ z, (P y z - (1 - c) * ν z) = c := by
    intro y
    rw [sum_sub_distrib, ← mul_sum, hν1, hsum]
    ring
  have hc0 : 0 ≤ c := by
    rw [← hRsum x]
    exact sum_nonneg fun z _ => sub_nonneg.2 (hmin x z)
  have key : ∀ y, (P *ᵥ g) y
      = ∑ z, (P y z - (1 - c) * ν z) * g z + (1 - c) * ∑ z, ν z * g z := by
    intro y
    simp only [mulVec, dotProduct, sub_mul, sum_sub_distrib, mul_sum, mul_assoc]
    ring
  have up : ∑ z, (P x z - (1 - c) * ν z) * g z ≤ c * g zM := by
    calc ∑ z, (P x z - (1 - c) * ν z) * g z
        ≤ ∑ z, (P x z - (1 - c) * ν z) * g zM :=
          sum_le_sum fun z _ =>
            mul_le_mul_of_nonneg_left (hM z (mem_univ z)) (sub_nonneg.2 (hmin x z))
      _ = c * g zM := by rw [← sum_mul, hRsum]
  have lo : c * g zm ≤ ∑ z, (P x' z - (1 - c) * ν z) * g z := by
    calc c * g zm = ∑ z, (P x' z - (1 - c) * ν z) * g zm := by rw [← sum_mul, hRsum]
      _ ≤ ∑ z, (P x' z - (1 - c) * ν z) * g z :=
          sum_le_sum fun z _ =>
            mul_le_mul_of_nonneg_left (hm z (mem_univ z)) (sub_nonneg.2 (hmin x' z))
  rw [key x, key x']
  have h3 := mul_le_mul_of_nonneg_left (hg zM zm) hc0
  linarith

/-! ### Chains -/

/-- The chain made of the hops `P 0`, `P 1`, …, `P (n - 1)`, in that order. -/
def chain (P : ℕ → Matrix α α ℝ) : ℕ → Matrix α α ℝ
  | 0 => 1
  | n + 1 => chain P n * P n

theorem chain_mem {P : ℕ → Matrix α α ℝ} (n : ℕ) (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) :
    chain P n ∈ rowStochastic ℝ α := by
  induction n with
  | zero => exact Submonoid.one_mem _
  | succ n ih =>
    exact Submonoid.mul_mem _ (ih fun k hk => hP k (by omega)) (hP n (by omega))

theorem spread_chain_le {P : ℕ → Matrix α α ℝ} {c : ℕ → ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Forgets (c k) (P k))
    {g : α → ℝ} {D : ℝ} (hg : ∀ z z', g z - g z' ≤ D) (x x' : α) :
    (chain P n *ᵥ g) x - (chain P n *ᵥ g) x' ≤ (∏ k ∈ range n, c k) * D := by
  induction n generalizing g D with
  | zero => simpa [chain] using hg x x'
  | succ n ih =>
    show ((chain P n * P n) *ᵥ g) x - ((chain P n * P n) *ᵥ g) x' ≤ _
    rw [← mulVec_mulVec, prod_range_succ, mul_assoc]
    exact ih (fun k hk => hP k (by omega)) (fun k hk => hc k (by omega))
      (fun z z' => spread_mulVec_le (hP n (by omega)) (hc n (by omega)) hg z z')

/-- **Distinguishability decays through forgetting hops.** After `n` hops, the `k`-th of which forgets
with probability at least `1 - c k`, no test `A` of the outcome distinguishes two originals
`x` and `x'` with advantage more than `c 0 * ⋯ * c (n - 1)`. -/
theorem advantage_le {P : ℕ → Matrix α α ℝ} {c : ℕ → ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Forgets (c k) (P k))
    (x x' : α) (A : Finset α) :
    |prob (chain P n) x A - prob (chain P n) x' A| ≤ ∏ k ∈ range n, c k := by
  have hg : ∀ z z' : α, (if z ∈ A then (1 : ℝ) else 0) - (if z' ∈ A then 1 else 0) ≤ 1 := by
    intro z z'
    split_ifs <;> norm_num
  rw [prob_eq_mulVec, prob_eq_mulVec, abs_le]
  have h1 := spread_chain_le n hP hc hg x x'
  have h2 := spread_chain_le n hP hc hg x' x
  constructor <;> linarith

/-- The same with one constant: `n` hops that each forget with probability at least `1 - c`
leave an advantage of at most `c ^ n`. -/
theorem advantage_le_pow {P : ℕ → Matrix α α ℝ} {c : ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Forgets c (P k))
    (x x' : α) (A : Finset α) :
    |prob (chain P n) x A - prob (chain P n) x' A| ≤ c ^ n := by
  have h := advantage_le (c := fun _ => c) n hP hc x x' A
  rwa [prod_const, card_range] at h

/-- **Guessing at depth `n`.** The original is `x` or `x'`, each with probability `1/2`. A
receiver at the end of the chain who answers `x` when the outcome is in `A` and `x'`
otherwise is right with probability at most `(1 + c 0 * ⋯ * c (n - 1)) / 2`. -/
theorem guess_le {P : ℕ → Matrix α α ℝ} {c : ℕ → ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Forgets (c k) (P k))
    (x x' : α) (A : Finset α) :
    (prob (chain P n) x A + prob (chain P n) x' Aᶜ) / 2 ≤ (1 + ∏ k ∈ range n, c k) / 2 := by
  rw [prob_compl (chain_mem n hP)]
  have h := (abs_le.1 (advantage_le n hP hc x x' A)).2
  linarith

/-- **Survival, read off the advantage.** After `n` forgetting hops the original `x` arrives
intact at most `c 0 * ⋯ * c (n - 1)` more often than `x` would have come out had `x'` been
sent. -/
theorem survive_le {P : ℕ → Matrix α α ℝ} {c : ℕ → ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Forgets (c k) (P k))
    (x x' : α) :
    prob (chain P n) x {x} ≤ prob (chain P n) x' {x} + ∏ k ∈ range n, c k := by
  have h := (abs_le.1 (advantage_le n hP hc x x' {x})).2
  linarith

/-- For `c ≥ 1` the condition `Forgets c` says nothing: every hop satisfies it. -/
theorem forgets_of_one_le [Nonempty α] {c : ℝ} (hc : 1 ≤ c) {P : Matrix α α ℝ}
    (hP : P ∈ rowStochastic ℝ α) : Forgets c P := by
  obtain ⟨x0⟩ := ‹Nonempty α›
  refine ⟨fun z => if z = x0 then 1 else 0, fun z => by dsimp only; split_ifs <;> norm_num,
    by simp, fun x z => ?_⟩
  have h1 := (mem_rowStochastic_iff_sum.1 hP).1 x z
  have h2 : (0 : ℝ) ≤ if z = x0 then 1 else 0 := by split_ifs <;> norm_num
  nlinarith

/-- **Intact at every hop needs no forgetting, and bounds survival from below.** For any
hop with non-negative entries, the chance of arriving intact after `n` hops is at least
`(P x x) ^ n`, the chance of being passed on unchanged at every hop. -/
theorem intact_pow_le_chain (P : Matrix α α ℝ) (h0 : ∀ x z, 0 ≤ P x z) (x : α) (n : ℕ) :
    (P x x) ^ n ≤ chain (fun _ => P) n x x ∧ ∀ z, 0 ≤ chain (fun _ => P) n x z := by
  induction n with
  | zero =>
    refine ⟨by simp [chain], fun z => ?_⟩
    simp only [chain, Matrix.one_apply]
    split_ifs <;> norm_num
  | succ n ih =>
    have hstep : ∀ z, chain (fun _ => P) (n + 1) x z = ∑ y, chain (fun _ => P) n x y * P y z :=
      fun z => by simp [chain, Matrix.mul_apply]
    refine ⟨?_, fun z => ?_⟩
    · rw [hstep, pow_succ]
      calc P x x ^ n * P x x ≤ chain (fun _ => P) n x x * P x x :=
            mul_le_mul_of_nonneg_right ih.1 (h0 x x)
        _ ≤ ∑ y, chain (fun _ => P) n x y * P y x :=
            Finset.single_le_sum (f := fun y => chain (fun _ => P) n x y * P y x)
              (fun y _ => mul_nonneg (ih.2 y) (h0 y x)) (mem_univ x)
    · rw [hstep]
      exact Finset.sum_nonneg fun y _ => mul_nonneg (ih.2 y) (h0 y z)

/-- The same for different hops: the chance of arriving intact is at least the product of
the chances of being passed on unchanged at each hop. -/
theorem intact_prod_le_chain (P : ℕ → Matrix α α ℝ) (h0 : ∀ k x z, 0 ≤ P k x z) (x : α)
    (n : ℕ) : ∏ k ∈ range n, P k x x ≤ chain P n x x ∧ ∀ z, 0 ≤ chain P n x z := by
  induction n with
  | zero =>
    refine ⟨by simp [chain], fun z => ?_⟩
    simp only [chain, Matrix.one_apply]
    split_ifs <;> norm_num
  | succ n ih =>
    have hstep : ∀ z, chain P (n + 1) x z = ∑ y, chain P n x y * P n y z :=
      fun z => by simp [chain, Matrix.mul_apply]
    refine ⟨?_, fun z => ?_⟩
    · rw [hstep, prod_range_succ]
      calc (∏ k ∈ range n, P k x x) * P n x x ≤ chain P n x x * P n x x :=
            mul_le_mul_of_nonneg_right ih.1 (h0 n x x)
        _ ≤ ∑ y, chain P n x y * P n y x :=
            Finset.single_le_sum (f := fun y => chain P n x y * P n y x)
              (fun y _ => mul_nonneg (ih.2 y) (h0 n y x)) (mem_univ x)
    · rw [hstep]
      exact Finset.sum_nonneg fun y _ => mul_nonneg (ih.2 y) (h0 n y z)

omit [DecidableEq α] in
/-- A hop that never sends some input to `z`, for each `z`, forgets nothing in one step. -/
theorem one_le_of_forgets_of_zero {c : ℝ} {P : Matrix α α ℝ} (h : Forgets c P)
    (hz : ∀ z, ∃ x, P x z = 0) : 1 ≤ c := by
  obtain ⟨ν, hν0, hν1, hmin⟩ := h
  by_contra hc
  push Not at hc
  have h0 : ∀ z, ν z = 0 := fun z => by
    obtain ⟨x, hx⟩ := hz z
    have h1 := hmin x z
    rw [hx] at h1
    have h2 : 0 < 1 - c := by linarith
    nlinarith [hν0 z]
  simp [h0] at hν1

/-! ### The bound is attained: the fading hop -/

/-- The hop that ignores what it is told and passes on a draw from `ν`. -/
def prior (ν : α → ℝ) : Matrix α α ℝ := of fun _ z => ν z

/-- The fading hop: with probability `c` pass the idea on unchanged, otherwise pass on a
draw from `ν`. -/
def fade (c : ℝ) (ν : α → ℝ) : Matrix α α ℝ := c • (1 : Matrix α α ℝ) + (1 - c) • prior ν

omit [Fintype α] in
theorem fade_apply (c : ℝ) (ν : α → ℝ) (x z : α) :
    fade c ν x z = c * (if x = z then 1 else 0) + (1 - c) * ν z := by
  simp [fade, prior, Matrix.one_apply]

omit [DecidableEq α] in
theorem prior_mul_prior {ν : α → ℝ} (hν : ∑ z, ν z = 1) : prior ν * prior ν = prior ν := by
  ext x z
  simp [prior, Matrix.mul_apply, ← Finset.sum_mul, hν]

theorem fade_mul_fade {ν : α → ℝ} (hν : ∑ z, ν z = 1) (a b : ℝ) :
    fade a ν * fade b ν = fade (a * b) ν := by
  simp only [fade, add_mul, mul_add, smul_mul_assoc, mul_smul_comm, one_mul, mul_one,
    prior_mul_prior hν, smul_smul, smul_add]
  module

theorem fade_mem {c : ℝ} (hc0 : 0 ≤ c) (hc1 : c ≤ 1) {ν : α → ℝ} (hν0 : ∀ z, 0 ≤ ν z)
    (hν : ∑ z, ν z = 1) : fade c ν ∈ rowStochastic ℝ α := by
  refine mem_rowStochastic_iff_sum.2 ⟨fun x z => ?_, fun x => ?_⟩
  · rw [fade_apply]
    exact add_nonneg (mul_nonneg hc0 (by split_ifs <;> norm_num))
      (mul_nonneg (by linarith) (hν0 z))
  · simp [fade_apply, sum_add_distrib, ← mul_sum, hν]

theorem fade_forgets {c : ℝ} (hc0 : 0 ≤ c) {ν : α → ℝ} (hν0 : ∀ z, 0 ≤ ν z)
    (hν : ∑ z, ν z = 1) : Forgets c (fade c ν) := by
  refine ⟨ν, hν0, hν, fun x z => ?_⟩
  rw [fade_apply]
  have : 0 ≤ c * (if x = z then (1 : ℝ) else 0) := mul_nonneg hc0 (by split_ifs <;> norm_num)
  linarith

/-- `n` fading hops are one fading hop with `c ^ n`. -/
theorem chain_fade {ν : α → ℝ} (hν : ∑ z, ν z = 1) (c : ℝ) (n : ℕ) :
    chain (fun _ => fade c ν) n = fade (c ^ n) ν := by
  induction n with
  | zero => simp [chain, fade]
  | succ n ih =>
    show chain (fun _ => fade c ν) n * fade c ν = _
    rw [ih, fade_mul_fade hν, pow_succ]

/-- **The bound is attained.** Through `n` fading hops, the test "the outcome is `x`"
distinguishes `x` from any other original `x'` with advantage exactly `c ^ n`. -/
theorem advantage_fade {ν : α → ℝ} (hν : ∑ z, ν z = 1) (c : ℝ) (n : ℕ) {x x' : α}
    (hne : x ≠ x') :
    prob (chain (fun _ => fade c ν) n) x {x} - prob (chain (fun _ => fade c ν) n) x' {x}
      = c ^ n := by
  simp [prob, chain_fade hν, fade_apply, Ne.symm hne]

/-- **Arriving intact is not `c ^ n`.** Through `n` fading hops the original `x` arrives
intact with probability `c ^ n + (1 - c ^ n) * ν x`: it can be lost and come back from the
fallback. -/
theorem prob_fade_self {ν : α → ℝ} (hν : ∑ z, ν z = 1) (c : ℝ) (n : ℕ) (x : α) :
    prob (chain (fun _ => fade c ν) n) x {x} = c ^ n + (1 - c ^ n) * ν x := by
  simp [prob, chain_fade hν, fade_apply]

/-! ### Functions and randomness -/

/-- A hop that is a function: told `x`, it passes on `f x` with certainty. A relay of
`Instances/Channel.lean`, restricted to a finite set of ideas that it maps into itself, is
such a hop; no lemma here makes that link. -/
def detHop (f : α → α) : Matrix α α ℝ := of fun x z => if f x = z then 1 else 0

theorem detHop_mem (f : α → α) : detHop f ∈ rowStochastic ℝ α := by
  refine mem_rowStochastic_iff_sum.2 ⟨fun x z => ?_, fun x => ?_⟩
  · simp only [detHop, of_apply]
    split_ifs <;> norm_num
  · simp [detHop]

theorem detHop_mul (f g : α → α) : detHop f * detHop g = detHop (g ∘ f) := by
  ext x z
  simp only [detHop, Matrix.mul_apply, of_apply, ite_mul, one_mul, zero_mul]
  rw [Finset.sum_ite_eq]
  simp

/-- The composite of the functions `f 0`, …, `f (n - 1)`, applied in that order. -/
def through (f : ℕ → α → α) : ℕ → α → α
  | 0 => id
  | n + 1 => f n ∘ through f n

/-- A chain of functions is a function. -/
theorem chain_detHop (f : ℕ → α → α) (n : ℕ) :
    chain (fun k => detHop (f k)) n = detHop (through f n) := by
  induction n with
  | zero =>
    ext x z
    show (1 : Matrix α α ℝ) x z = if id x = z then 1 else 0
    rw [Matrix.one_apply]
    rfl
  | succ n ih =>
    show chain (fun k => detHop (f k)) n * detHop (f n) = _
    rw [ih, detHop_mul]
    rfl

omit [Fintype α] in
/-- **Through functions, what is not merged is told apart with certainty.** If the chain
`F` sends `x` and `x'` to different things, the test "the outcome is `F x`" has advantage
`1`, at any depth. -/
theorem advantage_detHop (F : α → α) {x x' : α} (h : F x ≠ F x') :
    prob (detHop F) x {F x} - prob (detHop F) x' {F x} = 1 := by
  simp [prob, detHop, Ne.symm h]

omit [Fintype α] in
/-- And what is merged cannot be told apart at all. -/
theorem prob_detHop_eq (F : α → α) {x x' : α} (h : F x = F x') (A : Finset α) :
    prob (detHop F) x A = prob (detHop F) x' A := by
  simp [prob, detHop, h]

/-- **A function that forgets is constant.** A hop that is a function satisfies `Forgets c`
with `c < 1` only if it sends everything to the same thing. -/
theorem forgets_detHop {c : ℝ} (hc : c < 1) {f : α → α} (h : Forgets c (detHop f))
    (x x' : α) : f x = f x' := by
  obtain ⟨ν, hν0, hν1, hmin⟩ := h
  have hex : ∃ z, 0 < ν z := by
    by_contra hno
    push Not at hno
    have : ∑ z, ν z = 0 := sum_eq_zero fun z _ => le_antisymm (hno z) (hν0 z)
    linarith
  obtain ⟨z, hz⟩ := hex
  have hall : ∀ y, f y = z := by
    intro y
    by_contra hy
    have h1 := hmin y z
    simp only [detHop, of_apply, hy, ite_false] at h1
    have : 0 < (1 - c) * ν z := mul_pos (by linarith) hz
    linarith
  rw [hall x, hall x']

/-- A constant function does forget, completely. -/
theorem forgets_const (z0 : α) : Forgets 0 (detHop (fun _ : α => z0)) := by
  refine ⟨fun z => if z0 = z then 1 else 0, fun z => by dsimp only; split_ifs <;> norm_num,
    by simp, fun x z => ?_⟩
  simp [detHop]

/-- **Through one fixed chain of functions, a pair is merged or told apart with
certainty.** Either no test has any advantage between `x` and `x'`, or some test has
advantage `1`. -/
theorem detHop_dichotomy (f : ℕ → α → α) (n : ℕ) (x x' : α) :
    (∀ A, prob (chain (fun k => detHop (f k)) n) x A
        = prob (chain (fun k => detHop (f k)) n) x' A) ∨
    (∃ A, prob (chain (fun k => detHop (f k)) n) x A
        - prob (chain (fun k => detHop (f k)) n) x' A = 1) := by
  rw [chain_detHop]
  by_cases h : through f n x = through f n x'
  · exact Or.inl (prob_detHop_eq _ h)
  · exact Or.inr ⟨_, advantage_detHop _ h⟩

/-- **The fading hop is a random choice among functions**: the identity with probability
`c`, and otherwise the constant function at a draw `z` from `ν`. So the fading hop is also
this population of retellers, each a fixed function, met at random: a share `c` of faithful
repeaters, the rest people who always say their own thing. -/
theorem fade_eq_mixture (c : ℝ) (ν : α → ℝ) :
    fade c ν = c • detHop (id : α → α) + (1 - c) • ∑ z, ν z • detHop (fun _ : α => z) := by
  ext x y
  simp [fade_apply, detHop, Matrix.sum_apply]

/-! ### A second route -/

/-- Two independent copies of the chain `K`, both told `x0`: the probability that the pair
of outcomes lies in `S`. -/
def prob2 (K : Matrix α α ℝ) (x0 : α) (S : Finset (α × α)) : ℝ :=
  ∑ p ∈ S, K x0 p.1 * K x0 p.2

/-- The event that neither of two routes delivers `x`. -/
def neither (x : α) : Finset (α × α) := (univ.erase x) ×ˢ (univ.erase x)

theorem prob2_neither {K : Matrix α α ℝ} (hK : K ∈ rowStochastic ℝ α) (x0 x : α) :
    prob2 K x0 (neither x) = (1 - K x0 x) ^ 2 := by
  have h1 : ∑ z ∈ univ.erase x, K x0 z = 1 - K x0 x := by
    rw [Finset.sum_erase_eq_sub (mem_univ x), (mem_rowStochastic_iff_sum.1 hK).2 x0]
  rw [prob2, neither, Finset.sum_product, ← Finset.sum_mul_sum, h1]
  ring

theorem prob2_eq_sum_univ (K : Matrix α α ℝ) (x0 : α) (S : Finset (α × α)) :
    prob2 K x0 S = ∑ p : α × α, if p ∈ S then K x0 p.1 * K x0 p.2 else 0 := by
  simp [prob2, Finset.sum_ite_mem]

/-- **Two routes.** Through two independent chains of `n` fading hops, the test "neither
route delivered `x`" tells `x` from another original `x'` with advantage
`c ^ n + c ^ n * (1 - c ^ n) * (1 - 2 * ν x)`. -/
theorem two_routes {c : ℝ} (hc0 : 0 ≤ c) (hc1 : c ≤ 1) (n : ℕ) {ν : α → ℝ}
    (hν0 : ∀ z, 0 ≤ ν z) (hν : ∑ z, ν z = 1) {x x' : α} (hne : x ≠ x') :
    prob2 (chain (fun _ => fade c ν) n) x' (neither x)
        - prob2 (chain (fun _ => fade c ν) n) x (neither x)
      = c ^ n + c ^ n * (1 - c ^ n) * (1 - 2 * ν x) := by
  have hmem : ∀ k < n, (fun _ : ℕ => fade c ν) k ∈ rowStochastic ℝ α :=
    fun _ _ => fade_mem hc0 hc1 hν0 hν
  rw [prob2_neither (chain_mem n hmem), prob2_neither (chain_mem n hmem), chain_fade hν,
    fade_apply, fade_apply]
  simp only [Ne.symm hne, ite_false, ite_true]
  ring

/-- **A second route can help.** Take two independent chains of `n ≥ 1` fading hops with
`0 < c < 1`, and a fallback that produces the original `x` less than half the time. Every
test on one chain has advantage at most `c ^ n` between `x` and another original `x'`; the
test "neither route delivered `x`" on the pair has more. (With the roles of `x` and `x'`
exchanged the same holds when the fallback produces `x'` less than half the time, so the
only case without a gain is a fair coin between the two.) -/
theorem two_routes_beat_one {c : ℝ} (hc0 : 0 < c) (hc1 : c < 1) {n : ℕ} (hn : 1 ≤ n)
    {ν : α → ℝ} (hν0 : ∀ z, 0 ≤ ν z) (hν : ∑ z, ν z = 1) {x x' : α} (hne : x ≠ x')
    (hνx : ν x < 1 / 2) :
    (∀ A : Finset α, |prob (chain (fun _ => fade c ν) n) x A
        - prob (chain (fun _ => fade c ν) n) x' A| ≤ c ^ n) ∧
    c ^ n < prob2 (chain (fun _ => fade c ν) n) x' (neither x)
        - prob2 (chain (fun _ => fade c ν) n) x (neither x) := by
  have hmem : ∀ k < n, (fun _ : ℕ => fade c ν) k ∈ rowStochastic ℝ α :=
    fun _ _ => fade_mem hc0.le hc1.le hν0 hν
  have hpos : 0 < c ^ n := pow_pos hc0 n
  have hlt : c ^ n < 1 := pow_lt_one₀ hc0.le hc1 (by omega)
  refine ⟨fun A => advantage_le_pow n hmem (fun _ _ => fade_forgets hc0.le hν0 hν) x x' A,
    ?_⟩
  rw [two_routes hc0.le hc1.le n hν0 hν hne]
  have h1 : 0 < c ^ n * (1 - c ^ n) := mul_pos hpos (by linarith)
  have h2 : 0 < c ^ n * (1 - c ^ n) * (1 - 2 * ν x) := mul_pos h1 (by linarith)
  linarith

/-- **And sometimes it adds nothing.** For two ideas with a fair-coin fallback, no test on
the outcomes of two independent chains of `n` fading hops has advantage above `c ^ n`,
which one chain already attains (`advantage_fade`). -/
theorem two_routes_no_gain_bool (c : ℝ) (hc0 : 0 ≤ c) (hc1 : c ≤ 1) (n : ℕ)
    (S : Finset (Bool × Bool)) :
    |prob2 (chain (fun _ => fade c (fun _ : Bool => (1 / 2 : ℝ))) n) true S
      - prob2 (chain (fun _ => fade c (fun _ : Bool => (1 / 2 : ℝ))) n) false S| ≤ c ^ n := by
  rw [chain_fade (by simp)]
  have ha0 : 0 ≤ c ^ n := pow_nonneg hc0 n
  have ha1 : c ^ n ≤ 1 := pow_le_one₀ hc0 hc1
  generalize c ^ n = a at ha0 ha1
  rw [prob2_eq_sum_univ, prob2_eq_sum_univ]
  simp only [Fintype.sum_prod_type, Fintype.sum_bool, fade_apply]
  by_cases h1 : (true, true) ∈ S <;> by_cases h2 : (true, false) ∈ S <;>
    by_cases h3 : (false, true) ∈ S <;> by_cases h4 : (false, false) ∈ S <;>
    simp only [h1, h2, h3, h4, Bool.true_eq_false, Bool.false_eq_true,
      ↓reduceIte] <;>
    rw [abs_le] <;> constructor <;> nlinarith

/-! ### The general one-hop condition -/

/-- Through the hop `P`, no test tells any two things it might be told apart with advantage
more than `c`. On a non-empty set of ideas the least such `c` is Dobrushin's coefficient of
the hop, and `c ≥ 0` (`contracts_nonneg`). For `c ≥ 1` it is no condition
(`contracts_one`). It is a worst case over all pairs of inputs, including versions that only
arise in the middle of a chain. -/
def Contracts (c : ℝ) (P : Matrix α α ℝ) : Prop :=
  ∀ (x x' : α) (A : Finset α), prob P x A - prob P x' A ≤ c

/-- Every hop contracts with `1`: the condition says something only for `c < 1`. -/
theorem contracts_one {P : Matrix α α ℝ} (hP : P ∈ rowStochastic ℝ α) : Contracts 1 P := by
  intro x x' A
  have h0 := (mem_rowStochastic_iff_sum.1 hP).1
  have h1 := (mem_rowStochastic_iff_sum.1 hP).2
  have a : prob P x A ≤ 1 := by
    rw [← h1 x]
    exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _) fun z _ _ => h0 x z
  have b : 0 ≤ prob P x' A := Finset.sum_nonneg fun z _ => h0 x' z
  linarith

omit [Fintype α] [DecidableEq α] in
theorem contracts_nonneg {c : ℝ} {P : Matrix α α ℝ} (x : α) (h : Contracts c P) : 0 ≤ c := by
  simpa [prob] using h x x ∅

/-- A hop that forgets with probability at least `1 - c` has one-hop advantage at most
`c`. -/
theorem Forgets.contracts {c : ℝ} {P : Matrix α α ℝ} (hP : P ∈ rowStochastic ℝ α)
    (h : Forgets c P) : Contracts c P := by
  intro x x' A
  have hg : ∀ z z' : α, (if z ∈ A then (1 : ℝ) else 0) - (if z' ∈ A then 1 else 0) ≤ 1 := by
    intro z z'
    split_ifs <;> norm_num
  have := spread_mulVec_le hP h hg x x'
  rw [prob_eq_mulVec, prob_eq_mulVec]
  linarith

/-- **One hop with advantage at most `c` shrinks every test's spread by the factor `c`.** -/
theorem spread_mulVec_le_of_contracts {c : ℝ} {P : Matrix α α ℝ}
    (hP : P ∈ rowStochastic ℝ α) (hc : Contracts c P) {g : α → ℝ} {D : ℝ}
    (hg : ∀ z z', g z - g z' ≤ D) (x x' : α) :
    (P *ᵥ g) x - (P *ᵥ g) x' ≤ c * D := by
  classical
  have hsum := (mem_rowStochastic_iff_sum.1 hP).2
  obtain ⟨zM, -, hM⟩ := Finset.exists_max_image univ g ⟨x, mem_univ x⟩
  obtain ⟨zm, -, hm⟩ := Finset.exists_min_image univ g ⟨x, mem_univ x⟩
  set d : α → ℝ := fun z => P x z - P x' z with hd
  set A : Finset α := univ.filter fun z => 0 ≤ d z with hA
  set t : ℝ := ∑ z ∈ A, d z with ht
  have ht0 : 0 ≤ t := sum_nonneg fun z hz => (Finset.mem_filter.1 hz).2
  have htc : t ≤ c := by
    have := hc x x' A
    simp only [prob] at this
    rw [ht]
    simp only [hd, sum_sub_distrib]
    exact this
  have hcompl : ∑ z ∈ Aᶜ, d z = -t := by
    have h1 := Finset.sum_compl_add_sum A d
    have h2 : ∑ z, d z = 0 := by
      simp only [hd, sum_sub_distrib, hsum]
      ring
    rw [h2] at h1
    linarith
  have hdiff : (P *ᵥ g) x - (P *ᵥ g) x' = ∑ z ∈ Aᶜ, d z * g z + ∑ z ∈ A, d z * g z := by
    rw [Finset.sum_compl_add_sum A fun z => d z * g z]
    simp only [mulVec, dotProduct, hd, sub_mul, sum_sub_distrib]
  have hup : ∑ z ∈ A, d z * g z ≤ t * g zM := by
    rw [ht, sum_mul]
    exact sum_le_sum fun z hz =>
      mul_le_mul_of_nonneg_left (hM z (mem_univ z)) (Finset.mem_filter.1 hz).2
  have hlo : ∑ z ∈ Aᶜ, d z * g z ≤ -t * g zm := by
    rw [← hcompl, sum_mul]
    refine sum_le_sum fun z hz => ?_
    have hneg : d z ≤ 0 := by
      have : ¬ 0 ≤ d z := fun h0 => (Finset.mem_compl.1 hz) (Finset.mem_filter.2 ⟨mem_univ z, h0⟩)
      linarith
    nlinarith [hm z (mem_univ z)]
  have hD0 : 0 ≤ D := by simpa using hg x x
  have hMm := hg zM zm
  rw [hdiff]
  nlinarith [mul_le_mul_of_nonneg_left hMm ht0, mul_le_mul_of_nonneg_right htc hD0]

theorem spread_chain_le_of_contracts {P : ℕ → Matrix α α ℝ} {c : ℕ → ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Contracts (c k) (P k))
    {g : α → ℝ} {D : ℝ} (hg : ∀ z z', g z - g z' ≤ D) (x x' : α) :
    (chain P n *ᵥ g) x - (chain P n *ᵥ g) x' ≤ (∏ k ∈ range n, c k) * D := by
  induction n generalizing g D with
  | zero => simpa [chain] using hg x x'
  | succ n ih =>
    show ((chain P n * P n) *ᵥ g) x - ((chain P n * P n) *ᵥ g) x' ≤ _
    rw [← mulVec_mulVec, prod_range_succ, mul_assoc]
    exact ih (fun k hk => hP k (by omega)) (fun k hk => hc k (by omega))
      (fun z z' => spread_mulVec_le_of_contracts (hP n (by omega)) (hc n (by omega)) hg z z')

/-- **The one-hop bounds multiply along a chain.** If no test tells two inputs of hop `k`
apart with advantage more than `c k`, then no test tells two originals apart after hops
`0, …, n - 1` with advantage more than `c 0 * ⋯ * c (n - 1)`. No forgetting is assumed: the
hypothesis is about one hop at a time and is exactly the conclusion for `n = 1`. It is an
upper bound, and the true advantage can be strictly smaller than the product
(`lazyCycle_two_hops`); conversely a hop with one-hop constant `1` can still contract over
two hops (`lazyFour_two_hops`). -/
theorem advantage_le_of_contracts {P : ℕ → Matrix α α ℝ} {c : ℕ → ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Contracts (c k) (P k))
    (x x' : α) (A : Finset α) :
    |prob (chain P n) x A - prob (chain P n) x' A| ≤ ∏ k ∈ range n, c k := by
  have hg : ∀ z z' : α, (if z ∈ A then (1 : ℝ) else 0) - (if z' ∈ A then 1 else 0) ≤ 1 := by
    intro z z'
    split_ifs <;> norm_num
  rw [prob_eq_mulVec, prob_eq_mulVec, abs_le]
  have h1 := spread_chain_le_of_contracts n hP hc hg x x'
  have h2 := spread_chain_le_of_contracts n hP hc hg x' x
  constructor <;> linarith

/-- With one constant: `n` hops of one-hop advantage at most `c` leave at most `c ^ n`. -/
theorem advantage_le_pow_of_contracts {P : ℕ → Matrix α α ℝ} {c : ℝ} (n : ℕ)
    (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Contracts c (P k))
    (x x' : α) (A : Finset α) :
    |prob (chain P n) x A - prob (chain P n) x' A| ≤ c ^ n := by
  have h := advantage_le_of_contracts (c := fun _ => c) n hP hc x x' A
  rwa [prod_const, card_range] at h

/-! ### Preservation and the decay constant -/

/-- **A hop that preserves well cannot contract fast.** If the hop passes `x` and `x'` on
unchanged with probability at least `p` each, its one-hop advantage is at least `2 p - 1`:
the test "the outcome is `x`" already has that much. -/
theorem two_mul_sub_one_le {P : Matrix α α ℝ} (hP : P ∈ rowStochastic ℝ α) {p : ℝ}
    {x x' : α} (hne : x ≠ x') (hx : p ≤ P x x) (hx' : p ≤ P x' x') :
    2 * p - 1 ≤ prob P x {x} - prob P x' {x} := by
  have h0 := (mem_rowStochastic_iff_sum.1 hP).1
  have h1 := (mem_rowStochastic_iff_sum.1 hP).2 x'
  have h2 : P x' x + P x' x' ≤ 1 := by
    rw [← h1, ← Finset.sum_pair hne]
    exact Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _) fun z _ _ => h0 x' z
  simp only [prob, Finset.sum_singleton]
  linarith

theorem two_mul_sub_one_le_of_contracts {P : Matrix α α ℝ} (hP : P ∈ rowStochastic ℝ α)
    {c p : ℝ} (hc : Contracts c P) {x x' : α} (hne : x ≠ x') (hx : p ≤ P x x)
    (hx' : p ≤ P x' x') : 2 * p - 1 ≤ c :=
  (two_mul_sub_one_le hP hne hx hx').trans (hc x x' {x})

omit [Fintype α] in
/-- And a hop that preserves nothing need not contract at all: a function that keeps two
inputs apart has one-hop advantage `1`, whether or not it leaves anything unchanged. -/
theorem one_le_of_contracts_detHop {c : ℝ} {f : α → α} {x x' : α} (h : f x ≠ f x')
    (hc : Contracts c (detHop f)) : 1 ≤ c := by
  have := hc x x' {f x}
  rwa [advantage_detHop f h] at this

omit [DecidableEq α] in
/-- The one-hop advantage is at most the total of the positive parts of the difference of
two rows. -/
theorem prob_sub_le_sum_max (P : Matrix α α ℝ) (x x' : α) (A : Finset α) :
    prob P x A - prob P x' A ≤ ∑ z, max (P x z - P x' z) 0 := by
  simp only [prob, ← sum_sub_distrib]
  calc ∑ z ∈ A, (P x z - P x' z) ≤ ∑ z ∈ A, max (P x z - P x' z) 0 :=
        sum_le_sum fun z _ => le_max_left _ _
    _ ≤ ∑ z, max (P x z - P x' z) 0 :=
        Finset.sum_le_sum_of_subset_of_nonneg (Finset.subset_univ _)
          fun z _ _ => le_max_right _ _

/-- The lazy cycle on three ideas: pass the idea on unchanged nine times in ten, otherwise
pass on the next one. -/
noncomputable def lazyCycle : Matrix (Fin 3) (Fin 3) ℝ :=
  (9 / 10 : ℝ) • (1 : Matrix (Fin 3) (Fin 3) ℝ) + (1 / 10 : ℝ) • detHop (fun i : Fin 3 => i + 1)

theorem lazyCycle_mem : lazyCycle ∈ rowStochastic ℝ (Fin 3) := by
  refine mem_rowStochastic_iff_sum.2 ⟨fun x z => ?_, fun x => ?_⟩
  · fin_cases x <;> fin_cases z <;> simp [lazyCycle, detHop] <;> norm_num
  · fin_cases x <;> simp [lazyCycle, detHop, Matrix.one_apply, Fin.sum_univ_three] <;> norm_num

/-- The lazy cycle forgets nothing in one step (Doeblin's condition fails for every
`c < 1`), yet its one-hop advantage is at most `9 / 10`, so through `n` such hops the
advantage is at most `(9 / 10) ^ n`. The general one-hop condition sees what the special
one misses. -/
theorem lazyCycle_contracts : Contracts (9 / 10) lazyCycle := by
  intro x x' A
  refine (prob_sub_le_sum_max _ x x' A).trans ?_
  fin_cases x <;> fin_cases x' <;>
    simp [lazyCycle, detHop, Matrix.one_apply, Fin.sum_univ_three] <;> norm_num

theorem lazyCycle_not_forgets {c : ℝ} (h : Forgets c lazyCycle) : 1 ≤ c :=
  one_le_of_forgets_of_zero h fun z => ⟨z + 1, by
    fin_cases z <;> simp [lazyCycle, detHop]⟩

theorem advantage_lazyCycle (n : ℕ) (x x' : Fin 3) (A : Finset (Fin 3)) :
    |prob (chain (fun _ => lazyCycle) n) x A - prob (chain (fun _ => lazyCycle) n) x' A|
      ≤ (9 / 10) ^ n :=
  advantage_le_pow_of_contracts n (fun _ _ => lazyCycle_mem) (fun _ _ => lazyCycle_contracts)
    x x' A

/-- `9 / 10` is the least constant with which the lazy cycle contracts. -/
theorem lazyCycle_least {c : ℝ} (h : Contracts c lazyCycle) : 9 / 10 ≤ c := by
  have := h 0 1 {0}
  simp [prob, lazyCycle, detHop] at this
  linarith

/-- **The product of the one-hop constants is not the truth.** Two hops of the lazy cycle
contract with `4 / 5`, less than `(9 / 10) ^ 2`. -/
theorem lazyCycle_two_hops : Contracts (4 / 5) (chain (fun _ => lazyCycle) 2) := by
  intro x x' A
  refine (prob_sub_le_sum_max _ x x' A).trans ?_
  have e : chain (fun _ => lazyCycle) 2 = lazyCycle * lazyCycle := by simp [chain]
  rw [e]
  fin_cases x <;> fin_cases x' <;>
    simp [lazyCycle, detHop, Matrix.mul_apply, Matrix.one_apply, Fin.sum_univ_three] <;> norm_num

/-- The lazy cycle on four ideas. -/
noncomputable def lazyFour : Matrix (Fin 4) (Fin 4) ℝ :=
  (9 / 10 : ℝ) • (1 : Matrix (Fin 4) (Fin 4) ℝ) + (1 / 10 : ℝ) • detHop (fun i : Fin 4 => i + 1)

/-- On four ideas the lazy cycle does not contract at all in one hop: the one-hop condition
gives no bound. -/
theorem lazyFour_not_contracts {c : ℝ} (h : Contracts c lazyFour) : 1 ≤ c := by
  have := h 0 2 {0, 1}
  rw [prob, prob, Finset.sum_pair (by decide), Finset.sum_pair (by decide)] at this
  simp [lazyFour, detHop] at this
  norm_num at this
  linarith

/-- **The one-hop condition is not necessary for decay.** Two hops of the lazy cycle on four
ideas contract with `49 / 50`, although one hop does not contract. So the chain law, applied
to pairs of hops, still gives geometric decay where the one-hop law is silent. -/
theorem lazyFour_two_hops : Contracts (49 / 50) (lazyFour * lazyFour) := by
  intro x x' A
  refine (prob_sub_le_sum_max _ x x' A).trans ?_
  fin_cases x <;> fin_cases x' <;>
    simp [lazyFour, detHop, Matrix.mul_apply, Matrix.one_apply, Fin.sum_univ_four] <;> norm_num

/-- A hop that leaves nothing unchanged and does not contract: swapping two ideas. -/
theorem swap_keeps_nothing :
    (∀ x : Bool, detHop (fun b : Bool => !b) x x = 0) ∧
      ∀ c, Contracts c (detHop (fun b : Bool => !b)) → 1 ≤ c := by
  refine ⟨fun x => by cases x <;> simp [detHop], fun c h => ?_⟩
  exact one_le_of_contracts_detHop (x := true) (x' := false) (by simp) h

/-! ### What a second route can add -/

omit [DecidableEq α] in
theorem sum_prod_sub_le (μ ν m : α → ℝ) (hm0 : ∀ z, 0 ≤ m z) (hμ : ∀ z, m z ≤ μ z)
    (hν : ∀ z, m z ≤ ν z) (hμ0 : ∀ z, 0 ≤ μ z) (hν0 : ∀ z, 0 ≤ ν z) (S : Finset (α × α)) :
    ∑ p ∈ S, (μ p.1 * μ p.2 - ν p.1 * ν p.2) ≤ (∑ z, μ z) ^ 2 - (∑ z, m z) ^ 2 := by
  have tot : ∑ p : α × α, (μ p.1 * μ p.2 - m p.1 * m p.2)
      = (∑ z, μ z) ^ 2 - (∑ z, m z) ^ 2 := by
    rw [sum_sub_distrib, Fintype.sum_prod_type, Fintype.sum_prod_type,
      ← Finset.sum_mul_sum, ← Finset.sum_mul_sum]
    ring
  rw [← tot]
  have s1 : ∑ p ∈ S, (μ p.1 * μ p.2 - ν p.1 * ν p.2)
      ≤ ∑ p ∈ S, (μ p.1 * μ p.2 - m p.1 * m p.2) := by
    refine sum_le_sum fun p _ => ?_
    have := mul_le_mul (hν p.1) (hν p.2) (hm0 p.2) (hν0 p.1)
    linarith
  refine s1.trans ?_
  refine Finset.sum_le_univ_sum_of_nonneg fun p => ?_
  have := mul_le_mul (hμ p.1) (hμ p.2) (hm0 p.2) (hμ0 p.1)
  linarith

/-- **What two routes can give.** If no test on one copy of the chain `K` tells `x` from
`x'` with advantage more than `a ≤ 1`, no test on two independent copies does so with
advantage more than `1 - (1 - a) ^ 2 = a + a (1 - a)`. A second route adds at most
`a (1 - a)`: it changes the constant, not the rate. `two_routes` attains this when the
fallback never produces `x`. -/
theorem two_routes_le {K : Matrix α α ℝ} (hK : K ∈ rowStochastic ℝ α) {a : ℝ} {x x' : α}
    (ha : ∀ A : Finset α, prob K x A - prob K x' A ≤ a) (ha1 : a ≤ 1)
    (S : Finset (α × α)) :
    prob2 K x S - prob2 K x' S ≤ 1 - (1 - a) ^ 2 := by
  classical
  have h0 := (mem_rowStochastic_iff_sum.1 hK).1
  have h1 := (mem_rowStochastic_iff_sum.1 hK).2
  have ht : 1 - ∑ z, min (K x z) (K x' z) ≤ a := by
    have h := ha (univ.filter fun z => K x' z < K x z)
    simp only [prob] at h
    have e : 1 - ∑ z, min (K x z) (K x' z)
        = ∑ z ∈ univ.filter (fun z => K x' z < K x z), K x z
          - ∑ z ∈ univ.filter (fun z => K x' z < K x z), K x' z := by
      rw [← h1 x, ← sum_sub_distrib, ← sum_sub_distrib, Finset.sum_filter]
      refine sum_congr rfl fun z _ => ?_
      by_cases hz : K x' z < K x z
      · simp [hz, min_eq_right hz.le]
      · simp [hz, min_eq_left (not_lt.1 hz)]
    rw [e]
    exact h
  have step := sum_prod_sub_le (K x) (K x') (fun z => min (K x z) (K x' z))
    (fun z => le_min (h0 x z) (h0 x' z)) (fun z => min_le_left _ _) (fun z => min_le_right _ _)
    (h0 x) (h0 x') S
  rw [h1 x] at step
  have e2 : prob2 K x S - prob2 K x' S
      = ∑ p ∈ S, (K x p.1 * K x p.2 - K x' p.1 * K x' p.2) := by
    simp only [prob2, ← sum_sub_distrib]
  rw [e2]
  have hp := pow_le_pow_left₀ (by linarith : (0 : ℝ) ≤ 1 - a)
    (by linarith : 1 - a ≤ ∑ z, min (K x z) (K x' z)) 2
  linarith

/-- For contracting hops: two independent chains of `n` hops allow advantage at most
`1 - (1 - c ^ n) ^ 2`. -/
theorem two_routes_le_pow {P : ℕ → Matrix α α ℝ} {c : ℝ} (hc0 : 0 ≤ c) (hc1 : c ≤ 1)
    (n : ℕ) (hP : ∀ k < n, P k ∈ rowStochastic ℝ α) (hc : ∀ k < n, Contracts c (P k))
    (x x' : α) (S : Finset (α × α)) :
    prob2 (chain P n) x S - prob2 (chain P n) x' S ≤ 1 - (1 - c ^ n) ^ 2 :=
  two_routes_le (chain_mem n hP)
    (fun A => (abs_le.1 (advantage_le_pow_of_contracts n hP hc x x' A)).2)
    (pow_le_one₀ hc0 hc1) S

end Noisy

end Complexity
