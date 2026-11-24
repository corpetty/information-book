import Complexity.KraftChaitin
import Complexity.Instances.PrefixMachine

/-!
# Levin's coding theorem

`Prefix.coding_of_dominates` reduced "complex implies improbable" for a self-delimiting
system `U` to one hypothesis: `U` dominates the system built from its own algorithmic
probability. This file discharges that hypothesis for the universal prefix machine of
`Instances/PrefixMachine.lean`, by showing that the system can be built **computably**.

Fix a prefix machine `φ = run c`. Its algorithmic probability
`P x = ∑ {2 ^ (-|w|) : φ w = x}` is approximated from below by running `c` in stages:
`W s x` is the weight of the programs below `s` that have produced `x` within `s` steps.

* A **request** `(x, k + 1)` is issued at the first stage `s` with `2 ^ (-k) ≤ W s x`
  (`req`). The list of requests is primitive recursive (`req_primrec`).
* Requests for `x` have distinct `k`, each with `2 ^ (-k) ≤ P x`, so their weights sum to at
  most `P x`; over all `x` they sum to at most `∑ P x ≤ 1` (`tsum_req_le`).
* The Kraft–Chaitin machine of the request list serves each request with a program of
  length `k + 2`, and is a prefix machine (`KraftChaitin.exists_machine`).
* Every `k` with `2 ^ (-k) < P x` is eventually requested (`exists_cross`).

Results:

* `exists_coding_machine` – for every prefix machine `φ` there is a prefix machine `M` with
                            `K_M x ≤ n + 3` whenever `2 ^ (-n) ≤ P_φ x`, and
                            `2 ^ (-K_M x) ≤ P_φ x`;
* `levin`                 – **Levin's coding theorem**: for the universal prefix machine,
                            `K x ≤ n + c` whenever `2 ^ (-n) ≤ P x`;
* `P_le_two_pow_mul_wt`   – equivalently `P x ≤ 2 ^ c * 2 ^ (-K x)`. With
                            `Prefix.wt_K_le_P` (`2 ^ (-K x) ≤ P x`), algorithmic probability
                            and `2 ^ (-K)` agree up to a constant factor;
* `P_pos`                 – every number has positive algorithmic probability;
* `K_U_le_log`            – `K x ≤ 2 log₂ (x + 1) + c`, from a second use of the
                            Kraft–Chaitin machine.
-/

namespace Complexity

namespace Levin

open Nat.Partrec (Code)
open Nat.Partrec.Code (evaln)
open Encodable Primrec
open Kolmogorov (sys run)
open PrefixMachine (IsPrefixMachine U)
open Prefix (P wt)
open scoped ENNReal

/-! ### Powers of one half in `ℝ≥0∞` -/

theorem two_pow_mul_inv (a b : ℕ) : (2 : ℝ≥0∞) ^ (a + b) * 2⁻¹ ^ b = 2 ^ a := by
  rw [pow_add, mul_assoc, ← mul_pow, ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top,
    one_pow, mul_one]

theorem two_pow_mul_inv' (a b : ℕ) : (2 : ℝ≥0∞) ^ b * 2⁻¹ ^ (a + b) = 2⁻¹ ^ a := by
  rw [pow_add, mul_comm ((2⁻¹ : ℝ≥0∞) ^ a), ← mul_assoc, ← mul_pow,
    ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top, one_pow, one_mul]

theorem inv_pow_succ_add (N : ℕ) : (2⁻¹ : ℝ≥0∞) ^ (N + 1) + 2⁻¹ ^ (N + 1) = 2⁻¹ ^ N := by
  rw [pow_succ, ← mul_add, ENNReal.inv_two_add_inv_two, mul_one]

theorem inv_pow_succ_lt (n : ℕ) : (2⁻¹ : ℝ≥0∞) ^ (n + 1) < 2⁻¹ ^ n := by
  have h0 : (2⁻¹ : ℝ≥0∞) ^ n ≠ 0 := pow_ne_zero _ (by simp)
  have ht : (2⁻¹ : ℝ≥0∞) ^ n ≠ ⊤ := ENNReal.pow_ne_top (by simp)
  have h := (ENNReal.mul_lt_mul_iff_right h0 ht).2
    (ENNReal.inv_lt_one.2 ENNReal.one_lt_two)
  rwa [mul_one, ← pow_succ] at h

theorem inv_pow_le_wt {K : ℕ∞} {m : ℕ} (h : K ≤ m) : (2⁻¹ : ℝ≥0∞) ^ m ≤ wt K := by
  lift K to ℕ using ne_top_of_le_ne_top (ENat.natCast_ne_top m) h
  rw [Prefix.wt_coe]
  exact pow_le_pow_right_of_le_one' (by simp) (by exact_mod_cast h)

/-- The thresholds `2 ^ (-k)` below `p`, each counted at half its value, sum to at most
`p`. -/
theorem tsum_half_le (p : ℝ≥0∞) :
    ∑' k : ℕ, (if (2⁻¹ : ℝ≥0∞) ^ k ≤ p then (2⁻¹ : ℝ≥0∞) ^ (k + 1) else 0) ≤ p := by
  classical
  by_cases h : ∃ k : ℕ, (2⁻¹ : ℝ≥0∞) ^ k ≤ p
  · obtain ⟨k0, hk0, hmin⟩ : ∃ k0 : ℕ, (2⁻¹ : ℝ≥0∞) ^ k0 ≤ p ∧
        ∀ k < k0, ¬(2⁻¹ : ℝ≥0∞) ^ k ≤ p :=
      ⟨Nat.find h, Nat.find_spec h, fun k hk => Nat.find_min h hk⟩
    let g : ℕ → ℝ≥0∞ := fun k => if k0 ≤ k then (2⁻¹ : ℝ≥0∞) ^ (k + 1) else 0
    have hg : ∀ j, ∑ k ∈ Finset.range (k0 + j), g k + 2⁻¹ ^ (k0 + j) = 2⁻¹ ^ k0 := by
      intro j
      induction j with
      | zero =>
        rw [add_zero, Finset.sum_eq_zero, zero_add]
        intro k hk
        have : ¬k0 ≤ k := not_le.2 (Finset.mem_range.1 hk)
        simp [g, this]
      | succ j ih =>
        have hgj : g (k0 + j) = 2⁻¹ ^ (k0 + j + 1) := by simp [g]
        rw [← add_assoc, Finset.sum_range_succ, add_assoc, hgj, inv_pow_succ_add]
        exact ih
    rw [ENNReal.tsum_eq_iSup_nat]
    refine iSup_le fun N => ?_
    calc ∑ k ∈ Finset.range N, (if (2⁻¹ : ℝ≥0∞) ^ k ≤ p then (2⁻¹ : ℝ≥0∞) ^ (k + 1) else 0)
        ≤ ∑ k ∈ Finset.range N, g k := Finset.sum_le_sum fun k _ => by
          by_cases hk : k0 ≤ k
          · simp only [g, hk, ↓reduceIte]
            split_ifs
            · exact le_rfl
            · exact zero_le
          · have := hmin k (not_le.1 hk)
            simp [g, hk, this]
      _ ≤ ∑ k ∈ Finset.range (k0 + N), g k :=
          Finset.sum_le_sum_of_subset (Finset.range_mono (Nat.le_add_left _ _))
      _ ≤ 2⁻¹ ^ k0 := (le_add_right le_rfl).trans (hg N).le
      _ ≤ p := hk0
  · have h0 : ∀ k : ℕ,
        (if (2⁻¹ : ℝ≥0∞) ^ k ≤ p then (2⁻¹ : ℝ≥0∞) ^ (k + 1) else 0) = 0 := fun k => by
      have : ¬(2⁻¹ : ℝ≥0∞) ^ k ≤ p := fun hk => h ⟨k, hk⟩
      simp [this]
    simp [h0]

theorem tsum_pair (F : ℕ → ℝ≥0∞) : ∑' i, F i = ∑' (a : ℕ) (b : ℕ), F (Nat.pair a b) := by
  rw [← Nat.pairEquiv.tsum_eq F, tsum_prod']
  rfl

theorem list_sum_range (f : ℕ → ℕ) (s : ℕ) :
    ((List.range s).map f).sum = ∑ n ∈ Finset.range s, f n := by
  induction s with
  | zero => simp
  | succ s ih => simp [List.range_succ, Finset.sum_range_succ, ih]

/-! ### Approximating algorithmic probability from below -/

/-- The weight that program number `n` contributes to `x` at stage `s`, times `2 ^ (s+k)`. -/
def gN (c : Code) (s x k n : ℕ) : ℕ :=
  if evaln s c n = some x then
    Option.casesOn (motive := fun _ => ℕ) (decode₂ (List Bool) n) 0
      fun w => 2 ^ (s + k - w.length)
  else 0

/-- The weight that program number `n` contributes to `x` at stage `s`. -/
noncomputable def gE (c : Code) (s x n : ℕ) : ℝ≥0∞ :=
  if evaln s c n = some x then
    Option.casesOn (motive := fun _ => ℝ≥0∞) (decode₂ (List Bool) n) 0
      fun w => (2⁻¹ : ℝ≥0∞) ^ w.length
  else 0

open Classical in
/-- The weight that program number `n` contributes to `x` in the limit. -/
noncomputable def gInf (φ : List Bool → Part ℕ) (x n : ℕ) : ℝ≥0∞ :=
  Option.casesOn (motive := fun _ => ℝ≥0∞) (decode₂ (List Bool) n) 0
    fun w => if x ∈ φ w then (2⁻¹ : ℝ≥0∞) ^ w.length else 0

/-- The stage-`s` approximation to the algorithmic probability of `x`. -/
noncomputable def W (c : Code) (s x : ℕ) : ℝ≥0∞ := ∑ n ∈ Finset.range s, gE c s x n

theorem cast_gN (c : Code) (s x k n : ℕ) :
    (gN c s x k n : ℝ≥0∞) = 2 ^ (s + k) * gE c s x n := by
  unfold gN gE
  by_cases h : evaln s c n = some x
  · rcases hd : decode₂ (List Bool) n with _ | w
    · simp
    · have hn : encode w = n := decode₂_eq_some.1 hd
      have hlen : w.length ≤ s + k := by
        have h1 := Encodable.length_le_encode w
        have h2 := Nat.Partrec.Code.evaln_bound h
        omega
      simp only [h, ↓reduceIte]
      show ((2 ^ (s + k - w.length) : ℕ) : ℝ≥0∞) = 2 ^ (s + k) * 2⁻¹ ^ w.length
      conv_rhs => rw [← Nat.sub_add_cancel hlen]
      rw [two_pow_mul_inv]
      push_cast
      rfl
  · simp [h]

theorem tsum_gInf (φ : List Bool → Part ℕ) (x : ℕ) : ∑' n, gInf φ x n = P (sys φ) x := by
  classical
  have hsupp : Function.support (gInf φ x) ⊆ Set.range (encode : List Bool → ℕ) := by
    intro n hn
    rcases hd : decode₂ (List Bool) n with _ | w
    · exact absurd (by simp [gInf, hd]) hn
    · exact ⟨w, decode₂_eq_some.1 hd⟩
  rw [← encode_injective.tsum_eq hsupp]
  have hind : ∀ w : List Bool, gInf φ x (encode w) =
      Set.indicator {w | x ∈ φ w} (fun w => (2⁻¹ : ℝ≥0∞) ^ w.length) w := by
    intro w
    by_cases hx : x ∈ φ w
    · rw [Set.indicator_of_mem (show w ∈ {w | x ∈ φ w} from hx)]
      simp [gInf, decode₂_encode, hx]
    · rw [Set.indicator_of_notMem (show w ∉ {w | x ∈ φ w} from hx)]
      simp [gInf, decode₂_encode, hx]
  simp_rw [hind]
  exact (tsum_subtype {w : List Bool | x ∈ φ w} fun w => (2⁻¹ : ℝ≥0∞) ^ w.length).symm

theorem gE_le_gInf (c : Code) (s x n : ℕ) : gE c s x n ≤ gInf (run c) x n := by
  unfold gE gInf
  by_cases h : evaln s c n = some x
  · rcases hd : decode₂ (List Bool) n with _ | w
    · simp
    · have hn : encode w = n := decode₂_eq_some.1 hd
      have hx : x ∈ run c w := by
        show x ∈ c.eval (encode w)
        rw [hn]
        exact Nat.Partrec.Code.evaln_sound h
      simp [h, hx]
  · simp [h]

/-- Every stage underestimates the algorithmic probability. -/
theorem W_le_P (c : Code) (s x : ℕ) : W c s x ≤ P (sys (run c)) x := by
  rw [← tsum_gInf]
  exact (Finset.sum_le_sum fun n _ => gE_le_gInf c s x n).trans (sum_le_tsum _)

/-- Finitely many halting computations have all halted by some stage. -/
theorem exists_stage (c : Code) (x N : ℕ) :
    ∃ s, N ≤ s ∧ ∀ n < N, x ∈ c.eval n → evaln s c n = some x := by
  induction N with
  | zero => exact ⟨0, le_rfl, fun n hn => absurd hn (Nat.not_lt_zero _)⟩
  | succ N ih =>
    obtain ⟨s, hs, h⟩ := ih
    by_cases hx : x ∈ c.eval N
    · obtain ⟨t, ht⟩ := Nat.Partrec.Code.evaln_complete.1 hx
      refine ⟨max (s + 1) t, by omega, fun n hn hxn => ?_⟩
      rcases Nat.lt_succ_iff_lt_or_eq.1 hn with h1 | rfl
      · exact Nat.Partrec.Code.evaln_mono (by omega) (h n h1 hxn)
      · exact Nat.Partrec.Code.evaln_mono (le_max_right _ _) ht
    · refine ⟨s + 1, by omega, fun n hn hxn => ?_⟩
      rcases Nat.lt_succ_iff_lt_or_eq.1 hn with h1 | rfl
      · exact Nat.Partrec.Code.evaln_mono (Nat.le_succ s) (h n h1 hxn)
      · exact absurd hxn hx

/-! ### The requests -/

/-- At stage `s` the approximation to the probability of `x` has reached `2 ^ (-k)`. -/
def cross (c : Code) (x k s : ℕ) : Bool :=
  decide (2 ^ s ≤ ((List.range s).map (gN c s x k)).sum)

theorem cross_iff (c : Code) (x k s : ℕ) :
    cross c x k s = true ↔ (2⁻¹ : ℝ≥0∞) ^ k ≤ W c s x := by
  have h1 : ((∑ n ∈ Finset.range s, gN c s x k n : ℕ) : ℝ≥0∞) = 2 ^ (s + k) * W c s x := by
    rw [W, Finset.mul_sum]
    push_cast
    exact Finset.sum_congr rfl fun n _ => cast_gN c s x k n
  have h0 : (2 : ℝ≥0∞) ^ (s + k) ≠ 0 := pow_ne_zero _ two_ne_zero
  have ht : (2 : ℝ≥0∞) ^ (s + k) ≠ ⊤ := ENNReal.pow_ne_top ENNReal.ofNat_ne_top
  calc cross c x k s = true ↔ 2 ^ s ≤ ∑ n ∈ Finset.range s, gN c s x k n := by
        rw [cross, decide_eq_true_eq, list_sum_range]
    _ ↔ ((2 ^ s : ℕ) : ℝ≥0∞) ≤ ((∑ n ∈ Finset.range s, gN c s x k n : ℕ) : ℝ≥0∞) :=
        Nat.cast_le.symm
    _ ↔ (2 : ℝ≥0∞) ^ (s + k) * 2⁻¹ ^ k ≤ 2 ^ (s + k) * W c s x := by
        rw [h1, two_pow_mul_inv]
        simp only [Nat.cast_pow, Nat.cast_ofNat]
    _ ↔ _ := ENNReal.mul_le_mul_iff_right h0 ht

/-- Every threshold strictly below the algorithmic probability is eventually reached. -/
theorem exists_cross {c : Code} {x k : ℕ} (h : (2⁻¹ : ℝ≥0∞) ^ k < P (sys (run c)) x) :
    ∃ s, cross c x k s = true := by
  rw [← tsum_gInf, ENNReal.tsum_eq_iSup_nat, lt_iSup_iff] at h
  obtain ⟨N, hN⟩ := h
  obtain ⟨s, hs, hst⟩ := exists_stage c x N
  have hterm : ∀ n ∈ Finset.range N, gInf (run c) x n ≤ gE c s x n := by
    intro n hn
    unfold gInf gE
    rcases hd : decode₂ (List Bool) n with _ | w
    · simp
    · by_cases hx : x ∈ run c w
      · have hw : encode w = n := decode₂_eq_some.1 hd
        have he : evaln s c n = some x :=
          hst n (Finset.mem_range.1 hn) (by rw [← hw]; exact hx)
        simp [he, hx]
      · simp [hx]
  refine ⟨s, (cross_iff c x k s).2 (hN.le.trans ?_)⟩
  exact (Finset.sum_le_sum hterm).trans
    (Finset.sum_le_sum_of_subset (Finset.range_mono hs))

/-- `s` is the first stage at which the threshold `2 ^ (-k)` is reached for `x`. -/
def first (c : Code) (x k s : ℕ) : Bool :=
  cross c x k s && (List.range s).all fun s' => !cross c x k s'

theorem first_iff {c : Code} {x k s : ℕ} :
    first c x k s = true ↔ cross c x k s = true ∧ ∀ s' < s, cross c x k s' = false := by
  simp [first]

theorem exists_first {c : Code} {x k : ℕ} (h : ∃ s, cross c x k s = true) :
    ∃ s, first c x k s = true := by
  classical
  refine ⟨Nat.find h, first_iff.2 ⟨Nat.find_spec h, fun s' hs' => ?_⟩⟩
  simpa using Nat.find_min h hs'

theorem first_unique {c : Code} {x k s s' : ℕ} (h : first c x k s = true)
    (h' : first c x k s' = true) : s = s' := by
  obtain ⟨h1, h2⟩ := first_iff.1 h
  obtain ⟨h1', h2'⟩ := first_iff.1 h'
  by_contra hne
  rcases lt_or_gt_of_ne hne with hlt | hlt
  · have := h2' s hlt
    rw [h1] at this
    cases this
  · have := h2 s' hlt
    rw [h1'] at this
    cases this

/-- The request list: index `⟨x, ⟨k, s⟩⟩` asks for a description of `x` of weight
`2 ^ (-(k+1))` if `s` is the first stage at which the probability of `x` reaches
`2 ^ (-k)`. -/
def req (c : Code) (i : ℕ) : Option (ℕ × ℕ) :=
  bif first c i.unpair.1 i.unpair.2.unpair.1 i.unpair.2.unpair.2 then
    some (i.unpair.1, i.unpair.2.unpair.1 + 1)
  else none

theorem req_pair (c : Code) (x k s : ℕ) :
    req c (Nat.pair x (Nat.pair k s)) = bif first c x k s then some (x, k + 1) else none := by
  simp [req, Nat.unpair_pair]

theorem req_eq_some {c : Code} {i x n : ℕ} (h : req c i = some (x, n)) :
    ∃ k s, n = k + 1 ∧ first c x k s = true := by
  unfold req at h
  rcases hf : first c i.unpair.1 i.unpair.2.unpair.1 i.unpair.2.unpair.2 with _ | _
  · rw [hf] at h
    cases h
  · rw [hf] at h
    simp only [Bool.cond_true, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    exact ⟨_, _, rfl, hf⟩

/-! ### The request list is primitive recursive -/

theorem gN_primrec (c : Code) :
    Primrec fun a : (ℕ × ℕ × ℕ) × ℕ => gN c a.1.1 a.1.2.1 a.1.2.2 a.2 :=
  Primrec.ite
    (Primrec.eq.comp
      (Nat.Partrec.Code.primrec_evaln.comp (((fst.comp fst).pair (const c)).pair snd))
      (option_some.comp (fst.comp (snd.comp fst))))
    (option_casesOn (Primrec.decode₂.comp snd) (const 0)
      (KraftChaitin.primrec_pow.comp (const 2)
        (nat_sub.comp
          (nat_add.comp (fst.comp (fst.comp fst)) (snd.comp (snd.comp (fst.comp fst))))
          (list_length.comp snd))).to₂)
    (const 0)

theorem cross_primrec (c : Code) : Primrec fun a : ℕ × ℕ × ℕ => cross c a.1 a.2.1 a.2.2 :=
  (nat_le.comp (KraftChaitin.primrec_pow.comp (const 2) (snd.comp snd))
    (list_sum (list_map (list_range.comp (snd.comp snd))
      ((gN_primrec c).comp
        (((snd.comp (snd.comp fst)).pair
          ((fst.comp fst).pair (fst.comp (snd.comp fst)))).pair snd)).to₂))).decide

theorem first_primrec (c : Code) : Primrec fun a : ℕ × ℕ × ℕ => first c a.1 a.2.1 a.2.2 :=
  Primrec.and.comp (cross_primrec c)
    (list_all (list_range.comp (snd.comp snd))
      (Primrec.not.comp ((cross_primrec c).comp
        ((fst.comp fst).pair ((fst.comp (snd.comp fst)).pair snd)))).to₂)

theorem req_primrec (c : Code) : Primrec (req c) :=
  have hx : Primrec fun i : ℕ => i.unpair.1 := fst.comp Primrec.unpair
  have hm : Primrec fun i : ℕ => i.unpair.2.unpair := Primrec.unpair.comp (snd.comp Primrec.unpair)
  Primrec.cond ((first_primrec c).comp (hx.pair ((fst.comp hm).pair (snd.comp hm))))
    (option_some.comp (hx.pair (succ.comp (fst.comp hm)))) (const none)

/-! ### The requests fit -/

/-- The requests for one object have total weight at most its algorithmic probability. -/
theorem tsum_req_obj_le (c : Code) (x : ℕ) :
    ∑' (k : ℕ) (s : ℕ), KraftChaitin.wE (req c (Nat.pair x (Nat.pair k s))) ≤
      P (sys (run c)) x := by
  refine (tsum_le_tsum fun k => ?_).trans (tsum_half_le (P (sys (run c)) x))
  by_cases h : ∃ s, first c x k s = true
  · obtain ⟨s0, hs0⟩ := h
    have hP : (2⁻¹ : ℝ≥0∞) ^ k ≤ P (sys (run c)) x :=
      ((cross_iff c x k s0).1 (first_iff.1 hs0).1).trans (W_le_P c s0 x)
    rw [tsum_eq_single s0]
    · simp [req_pair, hs0, KraftChaitin.wE, hP]
    · intro s hs
      have hf : first c x k s = false := by
        by_contra hf
        exact hs (first_unique (by simpa using hf) hs0)
      simp [req_pair, hf, KraftChaitin.wE]
  · have h0 : ∀ s, KraftChaitin.wE (req c (Nat.pair x (Nat.pair k s))) = 0 := fun s => by
      have hf : first c x k s = false := by
        by_contra hf
        exact h ⟨s, by simpa using hf⟩
      simp [req_pair, hf, KraftChaitin.wE]
    simp [h0]

/-- Every threshold at or below the algorithmic probability is requested, one step down. -/
theorem exists_req {c : Code} {x n : ℕ} (hn : (2⁻¹ : ℝ≥0∞) ^ n ≤ P (sys (run c)) x) :
    ∃ s, req c (Nat.pair x (Nat.pair (n + 1) s)) = some (x, n + 1 + 1) := by
  have hlt : (2⁻¹ : ℝ≥0∞) ^ (n + 1) < P (sys (run c)) x :=
    lt_of_lt_of_le (inv_pow_succ_lt n) hn
  obtain ⟨s1, hs1⟩ := exists_first (exists_cross hlt)
  exact ⟨s1, by rw [req_pair, hs1]; rfl⟩

/-- **The requests have total weight at most one.** Each threshold is requested at most
once, only thresholds below `P x` are requested, and `P` is a semimeasure. -/
theorem tsum_req_le (c : Code)
    (hc : ∀ w z : List Bool, (run c w).Dom → (run c (w ++ z)).Dom → z = []) :
    ∑' i, KraftChaitin.wE (req c i) ≤ 1 := by
  have e1 : ∑' i, KraftChaitin.wE (req c i) =
      ∑' (x : ℕ) (k : ℕ) (s : ℕ), KraftChaitin.wE (req c (Nat.pair x (Nat.pair k s))) :=
    (tsum_pair _).trans (tsum_congr fun x =>
      tsum_pair fun m => KraftChaitin.wE (req c (Nat.pair x m)))
  rw [e1]
  refine (tsum_le_tsum fun x => ?_).trans
    (Prefix.tsum_P_le_one (sys (run c)) (Kolmogorov.sys_functional _)
      (PrefixMachine.sys_prefixFree hc))
  exact tsum_req_obj_le c x

/-! ### The coding theorem -/

/-- **Coding theorem, effective form.** For every prefix machine `φ` there is a prefix
machine `M` whose complexity is the negative logarithm of the algorithmic probability of
`φ`, up to three bits: `2 ^ (-K_M x) ≤ P_φ x`, and `K_M x ≤ n + 3` whenever
`2 ^ (-n) ≤ P_φ x`. This is `Prefix.exists_coding` with the built system computable. -/
theorem exists_coding_machine {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ) :
    ∃ M : List Bool →. ℕ, IsPrefixMachine M ∧
      (∀ x, wt (Kolmogorov.K M x) ≤ P (sys φ) x) ∧
      ∀ x (n : ℕ), (2⁻¹ : ℝ≥0∞) ^ n ≤ P (sys φ) x → Kolmogorov.K M x ≤ ((n + 3 : ℕ) : ℕ∞) := by
  obtain ⟨c, rfl⟩ := PrefixMachine.exists_run_eq hφ.1
  obtain ⟨M, hM, hpf, hserve, hsound⟩ :=
    KraftChaitin.exists_machine (req c) (req_primrec c) (tsum_req_le c hφ.2)
  refine ⟨M, ⟨hM, hpf⟩, fun x => ?_, fun x n hn => ?_⟩
  · rcases eq_or_ne (Kolmogorov.K M x) ⊤ with htop | htop
    · rw [htop, Prefix.wt_top]
      exact zero_le
    obtain ⟨w, hw, hcost⟩ := (sys M).exists_cost_eq_K htop
    obtain ⟨i, m, hi, hlen⟩ := hsound w x hw
    obtain ⟨k, s, rfl, hf⟩ := req_eq_some hi
    have hP : (2⁻¹ : ℝ≥0∞) ^ k ≤ P (sys (run c)) x :=
      ((cross_iff c x k s).1 (first_iff.1 hf).1).trans (W_le_P c s x)
    have hK : Kolmogorov.K M x = ((k + 1 + 1 : ℕ) : ℕ∞) := by
      rw [← hlen]
      exact hcost.symm
    rw [hK, Prefix.wt_coe]
    exact (pow_le_pow_right_of_le_one' (by simp) (by omega)).trans hP
  · have hlt : (2⁻¹ : ℝ≥0∞) ^ (n + 1) < P (sys (run c)) x :=
      lt_of_lt_of_le (inv_pow_succ_lt n) hn
    obtain ⟨s1, hs1⟩ := exists_first (exists_cross hlt)
    have hreq : req c (Nat.pair x (Nat.pair (n + 1) s1)) = some (x, n + 1 + 1) := by
      rw [req_pair, hs1]
      rfl
    obtain ⟨w, hw, hx⟩ := hserve _ _ _ hreq
    have hle := Kolmogorov.K_le_length hx
    rwa [hw] at hle

/-- **The coding theorem against any prefix machine.** What a prefix machine `φ` produces
with probability `2 ^ (-n)` has complexity at most `n + c` on the universal machine. -/
theorem levin_of {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ) : ∃ c : ℕ, ∀ x (n : ℕ),
    (2⁻¹ : ℝ≥0∞) ^ n ≤ P (sys φ) x → Kolmogorov.K U x ≤ ((n + c : ℕ) : ℕ∞) := by
  obtain ⟨M, hM, -, h⟩ := exists_coding_machine hφ
  obtain ⟨k, hk⟩ := PrefixMachine.K_U_le hM
  refine ⟨3 + k, fun x n hn => (hk x).trans ?_⟩
  refine (add_le_add (h x n hn) (le_refl (k : ℕ∞))).trans (le_of_eq ?_)
  push_cast
  ring

/-- The algorithmic probability of any prefix machine is at most a constant times
`2 ^ (-K)` of the universal one. -/
theorem P_le_two_pow_mul_wt_of {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ) :
    ∃ c : ℕ, ∀ x, P (sys φ) x ≤ 2 ^ c * wt (Kolmogorov.K U x) := by
  classical
  obtain ⟨c, hc⟩ := levin_of hφ
  refine ⟨c + 1, fun x => ?_⟩
  by_cases h0 : P (sys φ) x = 0
  · rw [h0]
    exact zero_le
  have hex : ∃ n : ℕ, (2⁻¹ : ℝ≥0∞) ^ n ≤ P (sys φ) x := by
    obtain ⟨n, hn⟩ := ENNReal.exists_inv_two_pow_lt h0
    exact ⟨n, hn.le⟩
  obtain ⟨n0, hn0, hmin⟩ : ∃ n0 : ℕ, (2⁻¹ : ℝ≥0∞) ^ n0 ≤ P (sys φ) x ∧
      ∀ m < n0, ¬(2⁻¹ : ℝ≥0∞) ^ m ≤ P (sys φ) x :=
    ⟨Nat.find hex, Nat.find_spec hex, fun m hm => Nat.find_min hex hm⟩
  have hwt : (2⁻¹ : ℝ≥0∞) ^ (n0 + c) ≤ wt (Kolmogorov.K U x) := inv_pow_le_wt (hc x n0 hn0)
  have hp2 : P (sys φ) x ≤ 2 * 2⁻¹ ^ n0 := by
    rcases n0 with _ | m
    · rw [pow_zero, mul_one]
      have h1 : P (sys φ) x ≤ 1 :=
        (le_tsum (P (sys φ)) x).trans (Prefix.tsum_P_le_one _ (Kolmogorov.sys_functional _)
          (PrefixMachine.sys_prefixFree hφ.2))
      exact h1.trans one_le_two
    · have h2 : (2 : ℝ≥0∞) * 2⁻¹ ^ (m + 1) = 2⁻¹ ^ m := by
        rw [pow_succ', ← mul_assoc, ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top,
          one_mul]
      rw [h2]
      exact (not_le.1 (hmin m (Nat.lt_succ_self m))).le
  calc P (sys φ) x ≤ 2 * 2⁻¹ ^ n0 := hp2
    _ = 2 ^ (c + 1) * 2⁻¹ ^ (n0 + c) := by rw [pow_succ', mul_assoc, two_pow_mul_inv']
    _ ≤ 2 ^ (c + 1) * wt (Kolmogorov.K U x) := by gcongr

/-- **Levin's coding theorem.** For the universal prefix machine, complex implies
improbable: there is a constant `c` with `K x ≤ n + c` whenever `2 ^ (-n) ≤ P x`. -/
theorem levin : ∃ c : ℕ, ∀ x (n : ℕ),
    (2⁻¹ : ℝ≥0∞) ^ n ≤ P (sys U) x → Kolmogorov.K U x ≤ ((n + c : ℕ) : ℕ∞) :=
  levin_of PrefixMachine.U_isPrefixMachine

/-- **Algorithmic probability is `2 ^ (-K)` up to a constant factor**: with
`Prefix.wt_K_le_P`, `2 ^ (-K x) ≤ P x ≤ 2 ^ c * 2 ^ (-K x)` for the universal prefix
machine. -/
theorem P_le_two_pow_mul_wt :
    ∃ c : ℕ, ∀ x, P (sys U) x ≤ 2 ^ c * wt (Kolmogorov.K U x) :=
  P_le_two_pow_mul_wt_of PrefixMachine.U_isPrefixMachine

/-- Every number has positive algorithmic probability: the theorems above are not about
an empty machine. -/
theorem P_pos (x : ℕ) : 0 < P (sys U) x := by
  refine lt_of_lt_of_le ?_ (Prefix.wt_K_le_P (sys U) (Kolmogorov.sys_isBinary U) x)
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 (PrefixMachine.K_U_lt_top x).ne
  have hn' : (sys U).K x = (n : ℕ∞) := hn.symm
  rw [hn', Prefix.wt_coe]
  exact pos_iff_ne_zero.2 (pow_ne_zero _ (by simp))

/-! ### A logarithmic upper bound -/

/-- Requests for a length-prefixed code: `x = 2 ^ l - 1 + j` with `j < 2 ^ l` asks for a
program of length `2 l + 1`. -/
def logReq (i : ℕ) : Option (ℕ × ℕ) :=
  if i.unpair.2 < 2 ^ i.unpair.1 then some (2 ^ i.unpair.1 - 1 + i.unpair.2, 2 * i.unpair.1 + 1)
  else none

theorem logReq_primrec : Primrec logReq := by
  have hpow : Primrec fun i : ℕ => 2 ^ i.unpair.1 :=
    (Primrec₂.unpaired'.1 Nat.Primrec.pow).comp (Primrec.const 2)
      (Primrec.fst.comp Primrec.unpair)
  exact Primrec.ite (Primrec.nat_lt.comp (Primrec.snd.comp Primrec.unpair) hpow)
    (Primrec.option_some.comp (Primrec.pair
      (Primrec.nat_add.comp (Primrec.nat_sub.comp hpow (Primrec.const 1))
        (Primrec.snd.comp Primrec.unpair))
      (Primrec.nat_add.comp (Primrec.nat_mul.comp (Primrec.const 2)
        (Primrec.fst.comp Primrec.unpair)) (Primrec.const 1))))
    (Primrec.const none)

theorem tsum_logReq : ∑' i, KraftChaitin.wE (logReq i) ≤ 1 := by
  rw [tsum_pair]
  have hin : ∀ l : ℕ, ∑' j, KraftChaitin.wE (logReq (Nat.pair l j)) = (2⁻¹ : ℝ≥0∞) ^ (l + 1) := by
    intro l
    have hterm : ∀ j, KraftChaitin.wE (logReq (Nat.pair l j)) =
        if j ∈ Finset.range (2 ^ l) then (2⁻¹ : ℝ≥0∞) ^ (2 * l + 1) else 0 := by
      intro j
      simp only [logReq, Nat.unpair_pair, Finset.mem_range]
      split_ifs <;> rfl
    simp_rw [hterm]
    rw [tsum_eq_sum (s := Finset.range (2 ^ l)) (fun j hj => by simp [hj]),
      Finset.sum_ite_mem, Finset.inter_self, Finset.sum_const, Finset.card_range, nsmul_eq_mul]
    have e : 2 * l + 1 = (l + 1) + l := by omega
    rw [e]
    push_cast
    exact two_pow_mul_inv' (l + 1) l
  simp_rw [hin, pow_succ]
  rw [ENNReal.tsum_mul_right, ENNReal.tsum_geometric, ENNReal.one_sub_inv_two, inv_inv,
    ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top]

/-- **Logarithmic upper bound**: `K(x) ≤ 2 log₂ (x + 1) + c` for the universal prefix
machine. With the Kraft counting law this pins prefix complexity of most numbers between
`log₂ x` and `2 log₂ x`, up to constants. -/
theorem K_U_le_log : ∃ c : ℕ, ∀ x : ℕ,
    Kolmogorov.K U x ≤ ((2 * Nat.log 2 (x + 1) + c : ℕ) : ℕ∞) := by
  obtain ⟨M, hM, hpf, hserve, -⟩ := KraftChaitin.exists_machine logReq logReq_primrec tsum_logReq
  obtain ⟨k, hk⟩ := PrefixMachine.K_U_le (φ := M) ⟨hM, hpf⟩
  refine ⟨2 + k, fun x => (hk x).trans ?_⟩
  have h1 : 2 ^ Nat.log 2 (x + 1) ≤ x + 1 := Nat.pow_log_le_self 2 (by omega)
  have h2 : x + 1 < 2 ^ (Nat.log 2 (x + 1) + 1) := Nat.lt_pow_succ_log_self (by norm_num) _
  have hr : logReq (Nat.pair (Nat.log 2 (x + 1)) (x + 1 - 2 ^ Nat.log 2 (x + 1))) =
      some (x, 2 * Nat.log 2 (x + 1) + 1) := by
    rw [pow_succ] at h2
    simp only [logReq, Nat.unpair_pair]
    split_ifs with hlt
    · congr 2
      omega
    · omega
  obtain ⟨w, hw, hx⟩ := hserve _ _ _ hr
  have h := Kolmogorov.K_le_length hx
  rw [hw] at h
  refine (add_le_add h le_rfl).trans (le_of_eq ?_)
  push_cast
  ring

end Levin

end Complexity
