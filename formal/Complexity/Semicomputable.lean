import Complexity.Levin

/-!
# Which functions are prefix complexities?

Each restriction of the description systems came with a representation theorem: every
function for arbitrary systems (`Limits.exists_system_K_eq`), level sets of size at most
`2 ^ n` for unambiguous binary ones (`Limits.exists_binary_iff`), Kraft's inequality for
self-delimiting ones (`Prefix.exists_prefix_iff`). This file gives the one for prefix
*machines*.

A function `f : ℕ → ℕ∞` is **approximable from above** if it is the least value shown by a
primitive recursive table `g x t` (`lim g`). Then:

* `exists_approx`         – the complexity of every partial recursive description method is
                            approximable from above (run all programs in stages and keep the
                            shortest that has produced `x`);
* `exists_machine_K_eq`   – conversely, if `f` is approximable from above and
                            `∑ₓ 2 ^ (-f x) ≤ 1`, then `f + 2` is exactly the complexity of a
                            prefix machine (request a codeword each time the table shows a
                            new value; the Kraft–Chaitin decoder serves them);
* `prefix_complexity_iff` – so, for `f` approximable from above: `f + c` is the complexity
                            of a prefix machine for some `c` **iff** `∑ₓ 2 ^ (-f x)` is
                            finite;
* `K_U_le_of_summable`    – and the universal prefix machine is below all of them:
                            `K_U ≤ f + c`. Up to an additive constant, `K_U` is the least
                            function that is approximable from above and has summable
                            weights (Levin).

"Approximable from above" is stated with a primitive recursive table, which is the form
the request list needs. It is not connected here to Mathlib's `Partrec`-based notions of
semicomputability.
-/

namespace Complexity

namespace Upper

open Nat.Partrec (Code)
open Nat.Partrec.Code (evaln)
open Encodable Primrec
open Kolmogorov (sys run)
open PrefixMachine
open Prefix (wt)
open scoped ENNReal

/-! ### Limits from above -/

/-- The least value an approximation table ever shows for `x`; `⊤` if it shows none. -/
noncomputable def lim (g : ℕ → ℕ → Option ℕ) (x : ℕ) : ℕ∞ := ⨅ t, ⨅ n ∈ g x t, (n : ℕ∞)

theorem lim_le {g : ℕ → ℕ → Option ℕ} {x t n : ℕ} (h : g x t = some n) : lim g x ≤ n :=
  iInf_le_of_le t (iInf₂_le n h)

theorem le_lim_iff {g : ℕ → ℕ → Option ℕ} {x : ℕ} {k : ℕ∞} :
    k ≤ lim g x ↔ ∀ t n, g x t = some n → k ≤ n := by
  simp only [lim, le_iInf_iff]
  exact ⟨fun h t n hn => h t n hn, fun h t n hn => h t n hn⟩

/-- A finite limit is attained. -/
theorem exists_eq_lim {g : ℕ → ℕ → Option ℕ} {x : ℕ} (h : lim g x ≠ ⊤) :
    ∃ t n, g x t = some n ∧ (n : ℕ∞) = lim g x := by
  classical
  have hex : ∃ n, ∃ t, g x t = some n := by
    by_contra hne
    push Not at hne
    exact h (top_le_iff.1 (le_lim_iff.2 fun t n hn => absurd hn (hne n t)))
  obtain ⟨t, ht⟩ := Nat.find_spec hex
  refine ⟨t, Nat.find hex, ht, le_antisymm (le_lim_iff.2 fun t' n hn => ?_) (lim_le ht)⟩
  exact_mod_cast Nat.find_min' hex ⟨t', hn⟩

/-- Shifting the table shifts the limit. -/
theorem lim_map_add (g : ℕ → ℕ → Option ℕ) (c x : ℕ) :
    lim (fun x t => (g x t).map (· + c)) x = lim g x + c := by
  refine le_antisymm ?_ (le_lim_iff.2 fun t n' hn' => ?_)
  · rcases eq_or_ne (lim g x) ⊤ with htop | htop
    · rw [htop, top_add]
      exact le_top
    obtain ⟨t, n, hn, hl⟩ := exists_eq_lim htop
    rw [← hl]
    have h : (fun x t => (g x t).map (· + c)) x t = some (n + c) := by simp [hn]
    exact (lim_le h).trans (le_of_eq (Nat.cast_add n c))
  · obtain ⟨n, hn, rfl⟩ := Option.map_eq_some_iff.1 hn'
    rw [Nat.cast_add]
    exact add_le_add (lim_le hn) le_rfl

theorem wt_add_nat (k : ℕ∞) (c : ℕ) : wt (k + c) = 2⁻¹ ^ c * wt k := by
  rcases eq_or_ne k ⊤ with rfl | h
  · simp
  lift k to ℕ using h
  rw [← Nat.cast_add, Prefix.wt_coe, Prefix.wt_coe, pow_add, mul_comm]

/-! ### Every complexity is approximable from above -/

/-- Stage `⟨w, s⟩` of the table for a program: if the program has produced `x` from the
input numbered `w` within `s` steps, show the length of that input. -/
def kApprox (c : Code) (x t : ℕ) : Option ℕ :=
  if evaln t.unpair.2 c t.unpair.1 = some x then
    (decode₂ (List Bool) t.unpair.1).map List.length
  else none

theorem kApprox_primrec (c : Code) : Primrec₂ (kApprox c) :=
  (Primrec.ite
    (Primrec.eq.comp
      (Nat.Partrec.Code.primrec_evaln.comp
        (((snd.comp (Primrec.unpair.comp snd)).pair (const c)).pair
          (fst.comp (Primrec.unpair.comp snd))))
      (option_some.comp fst))
    (option_map (Primrec.decode₂.comp (fst.comp (Primrec.unpair.comp snd)))
      (list_length.comp snd).to₂)
    (const none)).to₂

theorem lim_kApprox (c : Code) (x : ℕ) : lim (kApprox c) x = Kolmogorov.K (run c) x := by
  refine le_antisymm ((sys (run c)).le_K_iff.2 fun w hw => ?_) (le_lim_iff.2 fun t n hn => ?_)
  · obtain ⟨s, hs⟩ := Nat.Partrec.Code.evaln_complete.1 (show x ∈ c.eval (encode w) from hw)
    have hs' : evaln s c (encode w) = some x := hs
    have h : kApprox c x (Nat.pair (encode w) s) = some w.length := by
      simp [kApprox, hs', decode₂_encode]
    exact lim_le h
  · unfold kApprox at hn
    split_ifs at hn with he
    obtain ⟨w, hw, rfl⟩ := Option.map_eq_some_iff.1 hn
    have hx : x ∈ run c w := by
      show x ∈ c.eval (encode w)
      rw [decode₂_eq_some.1 hw]
      exact Nat.Partrec.Code.evaln_sound he
    exact Kolmogorov.K_le_length hx

/-- **Complexity is approximable from above**, for every partial recursive description
method. -/
theorem exists_approx {φ : List Bool →. ℕ} (hφ : Partrec φ) :
    ∃ g : ℕ → ℕ → Option ℕ, Primrec₂ g ∧ ∀ x, lim g x = Kolmogorov.K φ x := by
  obtain ⟨c, rfl⟩ := exists_run_eq hφ
  exact ⟨kApprox c, kApprox_primrec c, lim_kApprox c⟩

/-! ### The requests of an approximation -/

/-- Stage `t` is the first at which the table shows the value `n` for `x`. -/
def fresh (g : ℕ → ℕ → Option ℕ) (x n t : ℕ) : Bool :=
  decide (g x t = some n) && (List.range t).all fun t' => !decide (g x t' = some n)

theorem fresh_iff {g : ℕ → ℕ → Option ℕ} {x n t : ℕ} :
    fresh g x n t = true ↔ g x t = some n ∧ ∀ t' < t, g x t' ≠ some n := by
  simp [fresh]

theorem exists_fresh {g : ℕ → ℕ → Option ℕ} {x n : ℕ} (h : ∃ t, g x t = some n) :
    ∃ t, fresh g x n t = true := by
  classical
  exact ⟨Nat.find h, fresh_iff.2 ⟨Nat.find_spec h, fun t' ht' => Nat.find_min h ht'⟩⟩

theorem fresh_unique {g : ℕ → ℕ → Option ℕ} {x n t t' : ℕ} (h : fresh g x n t = true)
    (h' : fresh g x n t' = true) : t = t' := by
  obtain ⟨h1, h2⟩ := fresh_iff.1 h
  obtain ⟨h1', h2'⟩ := fresh_iff.1 h'
  by_contra hne
  rcases lt_or_gt_of_ne hne with hlt | hlt
  · exact h2' t hlt h1
  · exact h2 t' hlt h1'

/-- The request list of a table: each value `n` it shows for `x` is requested once, at
weight `2 ^ (-(n+1))`. Index `⟨x, ⟨n, t⟩⟩`. -/
def ureq (g : ℕ → ℕ → Option ℕ) (i : ℕ) : Option (ℕ × ℕ) :=
  bif fresh g i.unpair.1 i.unpair.2.unpair.1 i.unpair.2.unpair.2 then
    some (i.unpair.1, i.unpair.2.unpair.1 + 1)
  else none

theorem ureq_pair (g : ℕ → ℕ → Option ℕ) (x n t : ℕ) :
    ureq g (Nat.pair x (Nat.pair n t)) = bif fresh g x n t then some (x, n + 1) else none := by
  simp [ureq, Nat.unpair_pair]

theorem ureq_eq_some {g : ℕ → ℕ → Option ℕ} {i x m : ℕ} (h : ureq g i = some (x, m)) :
    ∃ n t, m = n + 1 ∧ fresh g x n t = true := by
  unfold ureq at h
  rcases hf : fresh g i.unpair.1 i.unpair.2.unpair.1 i.unpair.2.unpair.2 with _ | _
  · rw [hf] at h
    cases h
  · rw [hf] at h
    simp only [Bool.cond_true, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    exact ⟨_, _, rfl, hf⟩

theorem fresh_primrec {g : ℕ → ℕ → Option ℕ} (hg : Primrec₂ g) :
    Primrec fun a : ℕ × ℕ × ℕ => fresh g a.1 a.2.1 a.2.2 :=
  Primrec.and.comp
    (Primrec.eq.decide.comp (hg.comp fst (snd.comp snd)) (option_some.comp (fst.comp snd)))
    (list_all (list_range.comp (snd.comp snd))
      (Primrec.not.comp (Primrec.eq.decide.comp (hg.comp (fst.comp fst) snd)
        (option_some.comp (fst.comp (snd.comp fst))))).to₂)

theorem ureq_primrec {g : ℕ → ℕ → Option ℕ} (hg : Primrec₂ g) : Primrec (ureq g) :=
  have hx : Primrec fun i : ℕ => i.unpair.1 := fst.comp Primrec.unpair
  have hm : Primrec fun i : ℕ => i.unpair.2.unpair := Primrec.unpair.comp (snd.comp Primrec.unpair)
  Primrec.cond ((fresh_primrec hg).comp (hx.pair ((fst.comp hm).pair (snd.comp hm))))
    (option_some.comp (hx.pair (succ.comp (fst.comp hm)))) (const none)

/-- The requests for one object weigh at most `2 ^ (-f x)`. -/
theorem tsum_ureq_obj_le (g : ℕ → ℕ → Option ℕ) (x : ℕ) :
    ∑' (n : ℕ) (t : ℕ), KraftChaitin.wE (ureq g (Nat.pair x (Nat.pair n t))) ≤
      wt (lim g x) := by
  refine (tsum_le_tsum fun n => ?_).trans (Levin.tsum_half_le (wt (lim g x)))
  by_cases h : ∃ t, fresh g x n t = true
  · obtain ⟨t0, ht0⟩ := h
    have hP : (2⁻¹ : ℝ≥0∞) ^ n ≤ wt (lim g x) :=
      Levin.inv_pow_le_wt (lim_le (fresh_iff.1 ht0).1)
    rw [tsum_eq_single t0]
    · simp [ureq_pair, ht0, KraftChaitin.wE, hP]
    · intro t ht
      have hf : fresh g x n t = false := by
        by_contra hf
        exact ht (fresh_unique (by simpa using hf) ht0)
      simp [ureq_pair, hf, KraftChaitin.wE]
  · have h0 : ∀ t, KraftChaitin.wE (ureq g (Nat.pair x (Nat.pair n t))) = 0 := fun t => by
      have hf : fresh g x n t = false := by
        by_contra hf
        exact h ⟨t, by simpa using hf⟩
      simp [ureq_pair, hf, KraftChaitin.wE]
    simp [h0]

theorem tsum_ureq_le (g : ℕ → ℕ → Option ℕ) (hK : ∑' x, wt (lim g x) ≤ 1) :
    ∑' i, KraftChaitin.wE (ureq g i) ≤ 1 := by
  have e1 : ∑' i, KraftChaitin.wE (ureq g i) =
      ∑' (x : ℕ) (n : ℕ) (t : ℕ), KraftChaitin.wE (ureq g (Nat.pair x (Nat.pair n t))) :=
    (Levin.tsum_pair _).trans (tsum_congr fun x =>
      Levin.tsum_pair fun m => KraftChaitin.wE (ureq g (Nat.pair x m)))
  rw [e1]
  exact (tsum_le_tsum fun x => tsum_ureq_obj_le g x).trans hK

/-! ### The representation theorem -/

/-- **Every Kraft-summable function approximable from above is a prefix complexity**, two
bits up: there is a prefix machine `M` with `K_M = f + 2` exactly. -/
theorem exists_machine_K_eq {g : ℕ → ℕ → Option ℕ} (hg : Primrec₂ g)
    (hK : ∑' x, wt (lim g x) ≤ 1) :
    ∃ M : List Bool →. ℕ, IsPrefixMachine M ∧ ∀ x, Kolmogorov.K M x = lim g x + 2 := by
  obtain ⟨M, hM, hpf, hserve, hsound⟩ :=
    KraftChaitin.exists_machine (ureq g) (ureq_primrec hg) (tsum_ureq_le g hK)
  refine ⟨M, ⟨hM, hpf⟩, fun x => le_antisymm ?_ ((sys M).le_K_iff.2 fun w hw => ?_)⟩
  · rcases eq_or_ne (lim g x) ⊤ with htop | htop
    · simp [htop]
    obtain ⟨t, n, hgn, hn⟩ := exists_eq_lim htop
    obtain ⟨t1, ht1⟩ := exists_fresh ⟨t, hgn⟩
    have hreq : ureq g (Nat.pair x (Nat.pair n t1)) = some (x, n + 1) := by
      rw [ureq_pair, ht1]
      rfl
    obtain ⟨w, hw, hx⟩ := hserve _ _ _ hreq
    have hle := Kolmogorov.K_le_length hx
    rw [hw] at hle
    rw [← hn]
    exact hle.trans (le_of_eq (by push_cast; ring))
  · obtain ⟨i, m, hi, hlen⟩ := hsound w x hw
    obtain ⟨n, t, rfl, hf⟩ := ureq_eq_some hi
    have h1 : lim g x ≤ n := lim_le (fresh_iff.1 hf).1
    show lim g x + 2 ≤ (w.length : ℕ∞)
    rw [hlen]
    calc lim g x + 2 ≤ (n : ℕ∞) + 2 := by gcongr
      _ = ((n + 1 + 1 : ℕ) : ℕ∞) := by push_cast; ring

/-- **The representation theorem for prefix machines.** For a function approximable from
above, some shift `f + c` is the complexity of a prefix machine if and only if the weights
`2 ^ (-f x)` have a finite sum. -/
theorem prefix_complexity_iff {g : ℕ → ℕ → Option ℕ} (hg : Primrec₂ g) :
    (∑' x, wt (lim g x) ≠ ⊤) ↔
      ∃ M : List Bool →. ℕ, IsPrefixMachine M ∧ ∃ c : ℕ, ∀ x, Kolmogorov.K M x = lim g x + c := by
  constructor
  · intro hS
    obtain ⟨c, hc⟩ : ∃ c : ℕ, ∑' x, wt (lim g x) ≤ 2 ^ c := by
      obtain ⟨n, hn⟩ := ENNReal.exists_nat_gt hS
      refine ⟨n, hn.le.trans ?_⟩
      exact_mod_cast (Nat.lt_two_pow_self (n := n)).le
    have hg' : Primrec₂ fun x t => (g x t).map (· + c) :=
      (option_map hg (nat_add.comp snd (const c)).to₂).to₂
    have hK : ∑' x, wt (lim (fun x t => (g x t).map (· + c)) x) ≤ 1 := by
      simp_rw [lim_map_add, wt_add_nat]
      rw [ENNReal.tsum_mul_left]
      calc (2⁻¹ : ℝ≥0∞) ^ c * ∑' x, wt (lim g x) ≤ 2⁻¹ ^ c * 2 ^ c := by gcongr
        _ = 1 := by
            rw [mul_comm]
            simpa using Levin.two_pow_mul_inv 0 c
    obtain ⟨M, hM, hKM⟩ := exists_machine_K_eq hg' hK
    refine ⟨M, hM, c + 2, fun x => ?_⟩
    rw [hKM x, lim_map_add]
    push_cast
    ring
  · rintro ⟨M, hM, c, hc⟩
    have hterm : ∀ x, wt (lim g x) = 2 ^ c * wt (Kolmogorov.K M x) := fun x => by
      rw [hc x, wt_add_nat, ← mul_assoc]
      have e : (2 : ℝ≥0∞) ^ c * 2⁻¹ ^ c = 1 := by simpa using Levin.two_pow_mul_inv 0 c
      rw [e, one_mul]
    simp_rw [hterm]
    rw [ENNReal.tsum_mul_left]
    have hkraft : ∑' x, wt (Kolmogorov.K M x) ≤ 1 :=
      Prefix.kraft (sys M) (Kolmogorov.sys_isBinary M) (Kolmogorov.sys_functional M)
        (sys_prefixFree hM.2)
    refine ne_top_of_le_ne_top ?_ (mul_le_mul_right hkraft _)
    simp

/-- **`K_U` is the least of them** (Levin): the universal prefix machine is, up to an
additive constant, below every function that is approximable from above and has summable
weights. With `exists_approx` and Kraft's inequality, `K_U` is itself such a function. -/
theorem K_U_le_of_summable {g : ℕ → ℕ → Option ℕ} (hg : Primrec₂ g)
    (hS : ∑' x, wt (lim g x) ≠ ⊤) : ∃ c : ℕ, ∀ x, Kolmogorov.K U x ≤ lim g x + c := by
  obtain ⟨M, hM, c, hc⟩ := (prefix_complexity_iff hg).1 hS
  obtain ⟨k, hk⟩ := K_U_le hM
  refine ⟨c + k, fun x => (hk x).trans ?_⟩
  rw [hc x]
  push_cast
  rw [add_assoc]

/-! ### Computable tables

The table need not be primitive recursive: a computable table has the same limit as a
primitive recursive one, which waits for the computation of each entry to finish. -/

/-- A computable table can be replaced by a primitive recursive table with the same limit. -/
theorem exists_primrec_table {g : ℕ → ℕ → Option ℕ} (hg : Computable₂ g) :
    ∃ g' : ℕ → ℕ → Option ℕ, Primrec₂ g' ∧ ∀ x, lim g' x = lim g x := by
  have h : Nat.Partrec fun n =>
      Part.bind (decode (α := ℕ × ℕ) n) fun p : ℕ × ℕ =>
        (Part.some (g p.1 p.2)).map encode := hg
  obtain ⟨c, hc⟩ := Nat.Partrec.Code.exists_code.1 h
  have hev : ∀ x t, c.eval (Nat.pair x t) = Part.some (encode (g x t)) := fun x t => by
    have e : Nat.pair x t = encode (x, t) := rfl
    rw [hc, e]
    simp
  refine ⟨fun x m => (evaln m.unpair.2 c (Nat.pair x m.unpair.1)).bind fun r =>
      (decode (α := Option ℕ) r).bind id, ?_, fun x => le_antisymm ?_ ?_⟩
  · exact (option_bind
      (Nat.Partrec.Code.primrec_evaln.comp
        (((snd.comp (Primrec.unpair.comp snd)).pair (const c)).pair
          (Primrec₂.natPair.comp fst (fst.comp (Primrec.unpair.comp snd)))))
      (option_bind (Primrec.decode.comp snd) (snd.to₂)).to₂).to₂
  · refine le_lim_iff.2 fun t n hn => ?_
    have hmem : encode (g x t) ∈ c.eval (Nat.pair x t) := by rw [hev]; exact Part.mem_some _
    obtain ⟨s, hs⟩ := Nat.Partrec.Code.evaln_complete.1 hmem
    have hs' : evaln s c (Nat.pair x t) = some (encode (g x t)) := hs
    refine lim_le (t := Nat.pair t s) ?_
    simp only [Nat.unpair_pair, hs', Option.bind_some, encodek, id]
    exact hn
  · refine le_lim_iff.2 fun m n hn => ?_
    obtain ⟨r, hr, hd⟩ := Option.bind_eq_some_iff.1 hn
    have hmem := Nat.Partrec.Code.evaln_sound hr
    rw [hev] at hmem
    have hr' : r = encode (g x m.unpair.1) := Part.mem_some_iff.1 hmem
    rw [hr', encodek] at hd
    exact lim_le (t := m.unpair.1) (by simpa using hd)

/-- The representation theorem, for a computable table. -/
theorem prefix_complexity_iff_of_computable {g : ℕ → ℕ → Option ℕ} (hg : Computable₂ g) :
    (∑' x, wt (lim g x) ≠ ⊤) ↔
      ∃ M : List Bool →. ℕ, IsPrefixMachine M ∧ ∃ c : ℕ, ∀ x, Kolmogorov.K M x = lim g x + c := by
  obtain ⟨g', hg', h⟩ := exists_primrec_table hg
  simp_rw [← h]
  exact prefix_complexity_iff hg'

/-- Minimality of `K_U`, for a computable table. -/
theorem K_U_le_of_computable {g : ℕ → ℕ → Option ℕ} (hg : Computable₂ g)
    (hS : ∑' x, wt (lim g x) ≠ ⊤) : ∃ c : ℕ, ∀ x, Kolmogorov.K U x ≤ lim g x + c := by
  obtain ⟨g', hg', h⟩ := exists_primrec_table hg
  simp_rw [← h] at hS ⊢
  exact K_U_le_of_summable hg' hS

/-- The weight of the limit is at most the total weight of the entries shown. -/
theorem wt_lim_le (g : ℕ → ℕ → Option ℕ) (x : ℕ) :
    wt (lim g x) ≤ ∑' t, (g x t).elim 0 fun n => wt n := by
  rcases eq_or_ne (lim g x) ⊤ with h | h
  · simp [h]
  obtain ⟨t, n, hn, hl⟩ := exists_eq_lim h
  rw [← hl]
  refine le_trans (le_of_eq ?_) (le_tsum (fun t => (g x t).elim 0 fun n => wt n) t)
  simp [hn]

/-! ### In Mathlib's terms: a recursively enumerable upper graph -/

/-- **Approximable from above means that the upper graph is recursively enumerable.** A
function `f : ℕ → ℕ∞` is the limit of a primitive recursive table (or, by
`exists_primrec_table`, of a computable one) exactly when the set of pairs `(x, n)` with
`f x ≤ n` is recursively enumerable. -/
theorem exists_table_iff_re (f : ℕ → ℕ∞) :
    (∃ g : ℕ → ℕ → Option ℕ, Primrec₂ g ∧ ∀ x, lim g x = f x) ↔
      REPred fun p : ℕ × ℕ => f p.1 ≤ p.2 := by
  constructor
  · rintro ⟨g, hg, hf⟩
    have hb : Computable fun q : (ℕ × ℕ) × ℕ =>
        decide ((g q.1.1 q.2).getD (q.1.2 + 1) ≤ q.1.2) :=
      (Primrec.nat_le.decide.comp
        (Primrec.option_getD.comp (hg.comp (fst.comp fst) snd) (succ.comp (snd.comp fst)))
        (snd.comp fst)).to_comp
    have hre := (Partrec.rfind (p := fun (p : ℕ × ℕ) t =>
      (Part.some (decide ((g p.1 t).getD (p.2 + 1) ≤ p.2)) : Part Bool)) hb.partrec).dom_re
    refine hre.of_eq fun p => ?_
    refine Nat.rfind_dom.trans ?_
    rw [← hf]
    constructor
    · rintro ⟨t, ht, -⟩
      have ht' : (g p.1 t).getD (p.2 + 1) ≤ p.2 :=
        of_decide_eq_true (Part.mem_some_iff.1 ht).symm
      cases hgt : g p.1 t with
      | none =>
        rw [hgt] at ht'
        simp at ht'
      | some k =>
        rw [hgt] at ht'
        exact (lim_le hgt).trans (by exact_mod_cast ht')
    · intro h
      obtain ⟨t, k, hk, hl⟩ := exists_eq_lim (ne_top_of_le_ne_top (ENat.natCast_ne_top _) h)
      rw [← hl] at h
      refine ⟨t, Part.mem_some_iff.2 (decide_eq_true ?_).symm, fun _ => trivial⟩
      rw [hk]
      exact_mod_cast h
  · intro hre
    have h : Nat.Partrec fun n =>
        Part.bind (decode (α := ℕ × ℕ) n) fun p : ℕ × ℕ =>
          (Part.assert (f p.1 ≤ p.2) fun _ => Part.some ()).map encode := hre
    obtain ⟨c, hc⟩ := Nat.Partrec.Code.exists_code.1 h
    have hdom : ∀ x n, (c.eval (Nat.pair x n)).Dom ↔ f x ≤ n := fun x n => by
      have e : Nat.pair x n = encode (x, n) := rfl
      rw [hc, e]
      simp [Part.assert]
    refine ⟨fun x m => bif (evaln m.unpair.2 c (Nat.pair x m.unpair.1)).isSome
      then some m.unpair.1 else none, ?_, fun x => le_antisymm ?_ ?_⟩
    · exact (Primrec.cond
        (option_isSome.comp
          (Nat.Partrec.Code.primrec_evaln.comp
            (((snd.comp (Primrec.unpair.comp snd)).pair (const c)).pair
              (Primrec₂.natPair.comp fst (fst.comp (Primrec.unpair.comp snd))))))
        (option_some.comp (fst.comp (Primrec.unpair.comp snd))) (const none)).to₂
    · rcases eq_or_ne (f x) ⊤ with htop | htop
      · rw [htop]
        exact le_top
      obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 htop
      obtain ⟨v, hv⟩ := Part.dom_iff_mem.1 ((hdom x n).2 hn.ge)
      obtain ⟨s, hs⟩ := Nat.Partrec.Code.evaln_complete.1 hv
      have hs' : evaln s c (Nat.pair x n) = some v := hs
      rw [← hn]
      refine lim_le (t := Nat.pair n s) ?_
      simp [hs']
    · refine le_lim_iff.2 fun m k hk => ?_
      cases hsome : (evaln m.unpair.2 c (Nat.pair x m.unpair.1)).isSome with
      | false => simp [hsome] at hk
      | true =>
        simp only [hsome, Bool.cond_true, Option.some.injEq] at hk
        obtain ⟨v, hv⟩ := Option.isSome_iff_exists.1 hsome
        rw [← hk]
        exact (hdom x _).1 (Part.dom_iff_mem.2 ⟨v, Nat.Partrec.Code.evaln_sound hv⟩)

end Upper

end Complexity
