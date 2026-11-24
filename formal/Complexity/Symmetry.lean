import Complexity.Conditional

/-!
# Symmetry of information

The chain rule for prefix complexity is an equality up to a constant, provided the
condition carries its own complexity:

  `K(⟨x, y⟩) = K(x) + K(y | x, K(x)) + O(1)`

(Levin, Gács, Chaitin). `Conditional.lean` proved the upper bound with the weaker condition
`x`. This file proves both directions with the condition `x* = ⟨x, K(x)⟩`.

**The easy direction** (`K_pair_le_add_condK_star`). A shortest program `p` for `x` tells a
machine both `x` and `K(x) = |p|`. So the machine that outputs `⟨U p, |p|⟩` is a prefix
machine producing `x*` from `p`, and the dependent-pair machine of `Conditional.lean` does
the rest.

**The hard direction** (`K_add_condK_star_le`). Fix a program `c` for `U`.

* The algorithmic probabilities of the pairs `⟨x, y⟩`, summed over `y`, are at most the
  probability that the machine `fst ∘ U` outputs `x` (`tsum_P_pair_le`), which by the
  coding theorem is at most `2 ^ c₀ · 2 ^ (-K x)` (`Levin.P_le_two_pow_mul_wt_of`).
* Levin's request list for `U` asks for a description of `⟨x, y⟩` of weight `2 ^ (-m)` only
  when `m` is above `-log P ⟨x, y⟩`. Given the condition `⟨x, k⟩`, re-issue each such
  request as a request for `y` of weight `2 ^ (k - C) · 2 ^ (-m)` (`creq`).
* When `k = K(x)` these weights sum to at most `2 ^ (c₀ - C) ≤ 1` (`tsum_creq_le`). When
  `k` is wrong nothing is claimed, and nothing needs to be: the Kraft–Chaitin decoder is
  prefix-free for every request list, and partial recursive uniformly in the condition
  (`KraftChaitin.machine_partrec₂`).
* So the decoders form a conditional prefix machine, which given `x*` serves `y` with a
  program of length `K(⟨x, y⟩) - K(x) + O(1)`.

Results:

* `symmetry_of_information` – `K(⟨x, y⟩) = K(x) + K(y | x*) + O(1)`, both directions;
* `symmetry`                – hence `K(x) + K(y | x*) = K(y) + K(x | y*) + O(1)`: what `x`
                              says about `y` is what `y` says about `x`;
* `K_macro_add_condK_le`, `card_K_lt_macro_add` – for a computable coarse-graining, all
                              but a fraction `2 ^ (-d)` of the microstates of a macrostate
                              `a` with `W` members have `K(x) ≥ K(a) + log₂ W - d - c`:
                              the lower half of "micro = macro + log W";
* `micro_eq_macro_add_log` – both halves, for one enumerated family of macrostates.
-/

namespace Complexity

namespace Symmetry

open Nat.Partrec (Code)
open Encodable Primrec
open Kolmogorov (sys run)
open PrefixMachine Conditional
open Prefix (P wt)
open Levin (req)
open scoped ENNReal

/-! ### The marginal of the pair distribution -/

/-- The machine that outputs the first component of what `U` outputs. -/
def fstM : List Bool →. ℕ := fun w => (U w).map fun z => z.unpair.1

theorem fstM_isPrefixMachine : IsPrefixMachine fstM :=
  ⟨Partrec.map U_partrec (Computable.fst.comp (Computable.unpair.comp Computable.snd)).to₂,
    fun _ _ h h' => U_prefixFree h h'⟩

theorem mem_fstM {d : List Bool} {x y : ℕ} (h : Nat.pair x y ∈ U d) : x ∈ fstM d := by
  exact (Part.mem_map_iff _).2 ⟨Nat.pair x y, h, by simp⟩

/-- **The marginal is a machine's output distribution**: the probabilities of the pairs
`⟨x, y⟩` sum over `y` to at most the probability that `fst ∘ U` outputs `x`. -/
theorem tsum_P_pair_le (x : ℕ) : ∑' y, P (sys U) (Nat.pair x y) ≤ P (sys fstM) x := by
  have hinj : Function.Injective
      (fun p : Σ y, {d // (sys U).realizes d (Nat.pair x y)} =>
        (⟨p.2.1, mem_fstM p.2.2⟩ : {d // (sys fstM).realizes d x})) := by
    rintro ⟨y, d, hd⟩ ⟨y', e, he⟩ hde
    have hde' : d = e := congrArg Subtype.val hde
    subst hde'
    have hp : Nat.pair x y = Nat.pair x y' := Part.mem_unique hd he
    obtain rfl : y = y' := (Nat.pair_eq_pair.1 hp).2
    rfl
  calc ∑' y, P (sys U) (Nat.pair x y)
      = ∑' p : Σ y, {d // (sys U).realizes d (Nat.pair x y)}, (2⁻¹ : ℝ≥0∞) ^ p.2.1.length :=
        (tsum_sigma (β := fun y => {d // (sys U).realizes d (Nat.pair x y)})
          fun _ d => (2⁻¹ : ℝ≥0∞) ^ d.1.length).symm
    _ ≤ P (sys fstM) x :=
        tsum_comp_le_tsum_of_injective hinj
          fun d : {d // (sys fstM).realizes d x} => (2⁻¹ : ℝ≥0∞) ^ d.1.length

/-! ### Conditional requests -/

/-- The request list for the condition `a = ⟨x, k⟩`: every request of Levin's list for a
pair `⟨x, y⟩`, of weight `2 ^ (-m)`, becomes a request for `y` of weight
`2 ^ (k - C) · 2 ^ (-m)`. Index `⟨y, j⟩` here is index `⟨⟨x, y⟩, j⟩` there. -/
def creq (c : Code) (C a i : ℕ) : Option (ℕ × ℕ) :=
  (req c (Nat.pair (Nat.pair a.unpair.1 i.unpair.1) i.unpair.2)).bind fun zm =>
    if a.unpair.2 ≤ zm.2 + C then some (i.unpair.1, zm.2 + C - a.unpair.2) else none

theorem creq_primrec (c : Code) (C : ℕ) : Primrec₂ (creq c C) :=
  (option_bind
    ((Levin.req_primrec c).comp (Primrec₂.natPair.comp
      (Primrec₂.natPair.comp (fst.comp (Primrec.unpair.comp fst))
        (fst.comp (Primrec.unpair.comp snd)))
      (snd.comp (Primrec.unpair.comp snd))))
    (Primrec.ite
      (nat_le.comp (snd.comp (Primrec.unpair.comp (fst.comp fst)))
        (nat_add.comp (snd.comp snd) (const C)))
      (option_some.comp (Primrec.pair (fst.comp (Primrec.unpair.comp (snd.comp fst)))
        (nat_sub.comp (nat_add.comp (snd.comp snd) (const C))
          (snd.comp (Primrec.unpair.comp (fst.comp fst))))))
      (const none)).to₂).to₂

/-- A conditional request weighs at most `2 ^ (k - C)` times the request it came from. -/
theorem wE_creq_le (c : Code) (C x k y m : ℕ) :
    KraftChaitin.wE (creq c C (Nat.pair x k) (Nat.pair y m)) ≤
      2 ^ k * 2⁻¹ ^ C * KraftChaitin.wE (req c (Nat.pair (Nat.pair x y) m)) := by
  simp only [creq, Nat.unpair_pair]
  rcases req c (Nat.pair (Nat.pair x y) m) with _ | ⟨z, n⟩
  · show (0 : ℝ≥0∞) ≤ _
    exact zero_le
  · simp only [Option.bind_some]
    split_ifs with h
    · show (2⁻¹ : ℝ≥0∞) ^ (n + C - k) ≤ 2 ^ k * 2⁻¹ ^ C * 2⁻¹ ^ n
      have e : C + n = (n + C - k) + k := by omega
      rw [mul_assoc, ← pow_add, e, Levin.two_pow_mul_inv']
    · show (0 : ℝ≥0∞) ≤ _
      exact zero_le

/-- The conditional requests weigh at most `2 ^ (k - C)` times the marginal probability. -/
theorem tsum_creq_le (c : Code) (C x k : ℕ) :
    ∑' i, KraftChaitin.wE (creq c C (Nat.pair x k) i) ≤
      2 ^ k * 2⁻¹ ^ C * ∑' y, P (sys (run c)) (Nat.pair x y) := by
  rw [Levin.tsum_pair fun i => KraftChaitin.wE (creq c C (Nat.pair x k) i),
    ← ENNReal.tsum_mul_left]
  refine tsum_le_tsum fun y => ?_
  calc ∑' m, KraftChaitin.wE (creq c C (Nat.pair x k) (Nat.pair y m))
      ≤ ∑' m, 2 ^ k * 2⁻¹ ^ C * KraftChaitin.wE (req c (Nat.pair (Nat.pair x y) m)) :=
        tsum_le_tsum fun m => wE_creq_le c C x k y m
    _ = 2 ^ k * 2⁻¹ ^ C * ∑' m, KraftChaitin.wE (req c (Nat.pair (Nat.pair x y) m)) :=
        ENNReal.tsum_mul_left
    _ ≤ 2 ^ k * 2⁻¹ ^ C * P (sys (run c)) (Nat.pair x y) := by
        gcongr
        exact (Levin.tsum_pair fun m =>
          KraftChaitin.wE (req c (Nat.pair (Nat.pair x y) m))).le.trans
            (Levin.tsum_req_obj_le c (Nat.pair x y))

/-! ### The two directions -/

/-- `x* = ⟨x, K(x)⟩`: an object together with its complexity. A shortest program for `x`
carries exactly this much. -/
noncomputable def star (x : ℕ) : ℕ := Nat.pair x (Kolmogorov.K U x).toNat

/-- **The hard direction**: `K(x) + K(y | x*) ≤ K(⟨x, y⟩) + c`. -/
theorem K_add_condK_star_le : ∃ c : ℕ, ∀ x y,
    Kolmogorov.K U x + condK (star x) y ≤ Kolmogorov.K U (Nat.pair x y) + c := by
  obtain ⟨c, hc⟩ := exists_run_eq U_partrec
  obtain ⟨c0, h0⟩ := Levin.P_le_two_pow_mul_wt_of fstM_isPrefixMachine
  obtain ⟨c1, h1⟩ := K_fst_le
  have hψ : IsCondPrefixMachine fun a w => KraftChaitin.machine (creq c (c1 + c0) a) w :=
    ⟨KraftChaitin.machine_partrec₂ (creq_primrec c (c1 + c0)),
      fun a _ _ => KraftChaitin.machine_prefixFree _⟩
  obtain ⟨k', hk'⟩ := condK_le hψ
  refine ⟨3 + (c1 + c0) + k', fun x y => ?_⟩
  obtain ⟨kx, hkx⟩ := ENat.ne_top_iff_exists.1 (K_U_lt_top x).ne
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 (K_U_lt_top (Nat.pair x y)).ne
  have hstar : star x = Nat.pair x kx := by
    rw [star, ← hkx]
    rfl
  -- with the right `k`, the conditional requests fit
  have e1 : (2 : ℝ≥0∞) ^ kx * 2⁻¹ ^ kx = 1 := by simpa using Levin.two_pow_mul_inv 0 kx
  have e2 : (2 : ℝ≥0∞) ^ c0 * 2⁻¹ ^ (c1 + c0) = 2⁻¹ ^ c1 := Levin.two_pow_mul_inv' c1 c0
  have hsum : ∑' i, KraftChaitin.wE (creq c (c1 + c0) (Nat.pair x kx) i) ≤ 1 := by
    refine (tsum_creq_le c (c1 + c0) x kx).trans ?_
    rw [hc]
    calc 2 ^ kx * 2⁻¹ ^ (c1 + c0) * ∑' y, P (sys U) (Nat.pair x y)
        ≤ 2 ^ kx * 2⁻¹ ^ (c1 + c0) * (2 ^ c0 * wt (Kolmogorov.K U x)) := by
          gcongr
          exact (tsum_P_pair_le x).trans (h0 x)
      _ = (2 ^ kx * 2⁻¹ ^ kx) * (2 ^ c0 * 2⁻¹ ^ (c1 + c0)) := by
          rw [← hkx, Prefix.wt_coe]
          ring
      _ = 2⁻¹ ^ c1 := by rw [e1, e2, one_mul]
      _ ≤ 1 := pow_le_one' (by simp) _
  -- the request for the pair is re-issued for `y`
  have hP : (2⁻¹ : ℝ≥0∞) ^ n ≤ P (sys (run c)) (Nat.pair x y) := by
    rw [hc]
    have h := Prefix.wt_K_le_P (sys U) (Kolmogorov.sys_isBinary U) (Nat.pair x y)
    have hK : (sys U).K (Nat.pair x y) = (n : ℕ∞) := hn.symm
    rwa [hK, Prefix.wt_coe] at h
  obtain ⟨s, hs⟩ := Levin.exists_req hP
  have hle : kx ≤ n + c1 := by
    have h := h1 x y
    rw [← hkx, ← hn] at h
    exact_mod_cast h
  have hreq : creq c (c1 + c0) (Nat.pair x kx) (Nat.pair y (Nat.pair (n + 1) s)) =
      some (y, n + 1 + 1 + (c1 + c0) - kx) := by
    simp only [creq, Nat.unpair_pair, hs, Option.bind_some]
    split_ifs with hg
    · rfl
    · omega
  obtain ⟨w, hw, hy⟩ :=
    KraftChaitin.exists_program (KraftChaitin.cum_le_one_of_tsum hsum) hreq
  obtain ⟨L, hL, hL'⟩ : ∃ L, n + 1 + 1 + (c1 + c0) - kx = L ∧ kx + L = n + 2 + (c1 + c0) :=
    ⟨_, rfl, by omega⟩
  have hK := Kolmogorov.K_le_length hy
  rw [hw, hL] at hK
  have hcond := (hk' (Nat.pair x kx) y).trans (add_le_add hK le_rfl)
  rw [hstar, ← hkx, ← hn]
  have e3 : kx + (L + 1) + k' = n + (3 + (c1 + c0) + k') := by omega
  calc (kx : ℕ∞) + condK (Nat.pair x kx) y
      ≤ kx + (((L + 1 : ℕ) : ℕ∞) + k') := by gcongr
    _ = ((kx + (L + 1) + k' : ℕ) : ℕ∞) := by push_cast; ring
    _ = ((n + (3 + (c1 + c0) + k') : ℕ) : ℕ∞) := by rw [e3]
    _ = (n : ℕ∞) + ((3 + (c1 + c0) + k' : ℕ) : ℕ∞) := Nat.cast_add _ _

/-- The machine that outputs what `U` outputs together with the length of the program. -/
def lenM : List Bool →. ℕ := fun p => (U p).map fun a => Nat.pair a p.length

theorem lenM_isPrefixMachine : IsPrefixMachine lenM :=
  ⟨Partrec.map U_partrec (Primrec₂.natPair.comp snd (list_length.comp fst)).to_comp.to₂,
    fun _ _ h h' => U_prefixFree h h'⟩

/-- **The easy direction**: `K(⟨x, y⟩) ≤ K(x) + K(y | x*) + c`. A shortest program for `x`
gives `x*`. -/
theorem K_pair_le_add_condK_star : ∃ c : ℕ, ∀ x y,
    Kolmogorov.K U (Nat.pair x y) ≤ Kolmogorov.K U x + condK (star x) y + c := by
  have hψ : IsCondPrefixMachine fun b w => (condU b w).map (Nat.pair b.unpair.1) :=
    ⟨Partrec.map condU_partrec
        (Primrec₂.natPair.comp (fst.comp (Primrec.unpair.comp (fst.comp fst))) snd).to_comp.to₂,
      fun b _ _ h h' => condU_prefixFree b h h'⟩
  obtain ⟨M, hM, hdep⟩ := exists_dep_machine lenM_isPrefixMachine hψ
  obtain ⟨k, hk⟩ := K_U_le hM
  refine ⟨k, fun x y => (hk _).trans (add_le_add ?_ le_rfl)⟩
  rcases eq_or_ne (condK (star x) y) ⊤ with hv | hv
  · simp [hv]
  obtain ⟨p, hp, hpc⟩ := (sys U).exists_cost_eq_K (K_U_lt_top x).ne
  obtain ⟨q, hq, hqc⟩ := (sys (condU (star x))).exists_cost_eq_K hv
  have hKx : Kolmogorov.K U x = (p.length : ℕ∞) := hpc.symm
  have hp' : star x ∈ lenM p := by
    have h := Part.mem_map (fun a => Nat.pair a p.length) hp
    have e : star x = Nat.pair x p.length := by
      rw [star, hKx]
      rfl
    rw [e]
    exact h
  have hq' : Nat.pair x y ∈ (condU (star x) q).map (Nat.pair (star x).unpair.1) := by
    have h := Part.mem_map (Nat.pair (star x).unpair.1) hq
    have e : (star x).unpair.1 = x := by simp [star]
    rw [e] at h
    rw [e]
    exact h
  have h := Kolmogorov.K_le_length (hdep p q (star x) (Nat.pair x y) hp' hq')
  have e : Kolmogorov.K U x + condK (star x) y = ((p ++ q).length : ℕ∞) := by
    rw [List.length_append, Nat.cast_add]
    exact (congrArg₂ (· + ·) hpc hqc).symm
  rw [e]
  exact h

/-- **Symmetry of information** (Levin, Gács, Chaitin): for the universal prefix machine,
`K(⟨x, y⟩) = K(x) + K(y | x, K(x))` up to an additive constant. -/
theorem symmetry_of_information : ∃ c : ℕ, ∀ x y,
    Kolmogorov.K U (Nat.pair x y) ≤ Kolmogorov.K U x + condK (star x) y + c ∧
      Kolmogorov.K U x + condK (star x) y ≤ Kolmogorov.K U (Nat.pair x y) + c := by
  obtain ⟨a, ha⟩ := K_pair_le_add_condK_star
  obtain ⟨b, hb⟩ := K_add_condK_star_le
  refine ⟨max a b, fun x y => ⟨(ha x y).trans ?_, (hb x y).trans ?_⟩⟩
  · gcongr
    exact le_max_left a b
  · gcongr
    exact le_max_right a b

/-- **The symmetry itself**: `K(x) + K(y | x*) ≤ K(y) + K(x | y*) + c`. Up to a constant,
the information `x` carries about `y`, `K(y) - K(y | x*)`, equals the information `y`
carries about `x`. -/
theorem symmetry : ∃ c : ℕ, ∀ x y,
    Kolmogorov.K U x + condK (star x) y ≤ Kolmogorov.K U y + condK (star y) x + c := by
  obtain ⟨c1, h1⟩ := K_add_condK_star_le
  obtain ⟨c2, h2⟩ := K_pair_comm
  obtain ⟨c3, h3⟩ := K_pair_le_add_condK_star
  refine ⟨c3 + c2 + c1, fun x y => (h1 x y).trans ?_⟩
  calc Kolmogorov.K U (Nat.pair x y) + c1
      ≤ Kolmogorov.K U (Nat.pair y x) + c2 + c1 := by
        gcongr
        exact h2 y x
    _ ≤ Kolmogorov.K U y + condK (star y) x + c3 + c2 + c1 := by
        gcongr
        exact h3 y x
    _ = Kolmogorov.K U y + condK (star y) x + ((c3 + c2 + c1 : ℕ) : ℕ∞) := by
        push_cast
        ring

/-! ### Micro = macro + log W -/

/-- **A microstate carries its macrostate**: for a computable coarse-graining `π`,
`K(π x) + K(x | (π x)*) ≤ K(x) + c`. The description of a microstate splits into the
description of its macrostate and the description of the microstate given the
macrostate, with nothing left over. -/
theorem K_macro_add_condK_le {π : ℕ → ℕ} (hπ : Computable π) : ∃ c : ℕ, ∀ x,
    Kolmogorov.K U (π x) + condK (star (π x)) x ≤ Kolmogorov.K U x + c := by
  obtain ⟨c1, h1⟩ := K_add_condK_star_le
  obtain ⟨c2, h2⟩ := K_map_le (f := fun x => Nat.pair (π x) x)
    (Primrec₂.natPair.to_comp.comp hπ Computable.id)
  refine ⟨c2 + c1, fun x => (h1 (π x) x).trans ?_⟩
  calc Kolmogorov.K U (Nat.pair (π x) x) + c1 ≤ Kolmogorov.K U x + c2 + c1 := by
        gcongr
        exact h2 x
    _ = Kolmogorov.K U x + ((c2 + c1 : ℕ) : ℕ∞) := by push_cast; ring

open Classical in
/-- **Typical microstates have `K(micro) ≥ K(macro) + log W - O(1)`.** For a computable
coarse-graining there is a constant `c` such that, in any set `A` of microstates of one
macrostate `a`, fewer than `2 ^ m` have `K(x) + c < K(a) + m`. With `m = log₂ |A| - d` all
but a fraction `2 ^ (-d)` of the microstates have `K(x) ≥ K(a) + log₂ |A| - d - c`. The
matching upper bound for enumerable macrostates is `Conditional.K_twoPart_le`. -/
theorem card_K_lt_macro_add {π : ℕ → ℕ} (hπ : Computable π) :
    ∃ c : ℕ, ∀ (a m : ℕ) (A : Finset ℕ), (∀ x ∈ A, π x = a) →
      (A.filter fun x => Kolmogorov.K U x + c < Kolmogorov.K U a + m).card < 2 ^ m := by
  obtain ⟨c, hc⟩ := K_macro_add_condK_le hπ
  refine ⟨c, fun a m A hA => lt_of_le_of_lt (Finset.card_le_card ?_)
    (card_condK_lt (star a) m A)⟩
  intro x hx
  rw [Finset.mem_filter] at hx ⊢
  refine ⟨hx.1, ?_⟩
  by_contra hge
  rw [not_lt] at hge
  have h1 := hc x
  rw [hA x hx.1] at h1
  exact absurd (lt_of_le_of_lt ((add_le_add le_rfl hge).trans h1) hx.2) (lt_irrefl _)

open Classical in
/-- **Micro = macro + log W**, both halves for one family of macrostates. Let the
macrostate `a` have `2 ^ ℓ a` microstates, listed without repetition by a computable `e a`,
and let a computable `π` recover the macrostate from each. Then there is a constant `c`
such that, for every macrostate:

* every microstate has `K(x) ≤ K(a) + ℓ a + c`;
* fewer than `2 ^ m` microstates have `K(x) + c < K(a) + m`.

With `m = ℓ a - d`: all but a fraction `2 ^ (-d)` of the microstates have
`K(a) + ℓ a - d - c ≤ K(x) ≤ K(a) + ℓ a + c`. -/
theorem micro_eq_macro_add_log {e : ℕ → ℕ → ℕ} {ℓ π : ℕ → ℕ} (he : Computable₂ e)
    (hℓ : Computable ℓ) (hπ : Computable π) (hmem : ∀ a i, i < 2 ^ ℓ a → π (e a i) = a)
    (hinj : ∀ a, Set.InjOn (e a) (Finset.range (2 ^ ℓ a) : Set ℕ)) :
    ∃ c : ℕ, ∀ a,
      (∀ i < 2 ^ ℓ a, Kolmogorov.K U (e a i) ≤ Kolmogorov.K U a + ((ℓ a + c : ℕ) : ℕ∞)) ∧
      ∀ m : ℕ, ((Finset.range (2 ^ ℓ a)).filter fun i =>
        Kolmogorov.K U (e a i) + c < Kolmogorov.K U a + m).card < 2 ^ m := by
  obtain ⟨c1, h1⟩ := K_twoPart_le he hℓ
  obtain ⟨c2, h2⟩ := card_K_lt_macro_add hπ
  refine ⟨max c1 c2, fun a => ⟨fun i hi => (h1 a i hi).trans ?_, fun m => ?_⟩⟩
  · gcongr
    exact le_max_left c1 c2
  · have hA : ∀ x ∈ (Finset.range (2 ^ ℓ a)).image (e a), π x = a := by
      intro x hx
      obtain ⟨i, hi, rfl⟩ := Finset.mem_image.1 hx
      exact hmem a i (Finset.mem_range.1 hi)
    refine lt_of_le_of_lt (Finset.card_le_card_of_injOn (e a) (fun i hi => ?_)
      ((hinj a).mono fun i hi => (Finset.mem_filter.1 hi).1)) (h2 a m _ hA)
    obtain ⟨hi1, hi2⟩ := Finset.mem_filter.1 hi
    refine Finset.mem_filter.2 ⟨Finset.mem_image_of_mem _ hi1, lt_of_le_of_lt ?_ hi2⟩
    gcongr
    exact le_max_right c1 c2

end Symmetry

end Complexity
