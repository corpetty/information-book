import Complexity.Limits

/-!
# Self-delimiting descriptions: where the additive laws are true

`Limits.lean` showed that for plain bit-string systems the additive bounds
(`K(fᵗ x) ≤ K(x) + log t + c`, `K(micro) ≤ K(macro) + log₂ W + c`, subadditivity of pairs)
fail, and that "every function is a complexity". This file restricts the dials to
**prefix-free** (self-delimiting) unambiguous binary systems and proves that there the
theory has content.

* `exists_prefix_iff`    – **representation theorem**: a function `f : X → ℕ∞` is the
                           complexity of a prefix-free unambiguous binary system *if and
                           only if* `∑ₓ 2^(-f x) ≤ 1` (Kraft's inequality and its converse
                           for arbitrary index sets). Prefix complexities are exactly the
                           negative logarithms of dyadic semimeasures;
* `exists_coding`        – **coding theorem, existence form**: for every prefix-free system
                           `S` there is a prefix-free system `T` with
                           `K_T(x) = ⌈-log₂ P_S(x)⌉`, where `P_S` is the algorithmic
                           probability of `S`;
* `coding_of_dominates`  – in any system `U` dominating that `T`,
                           `K_U(x) ≤ ⌈-log₂ P_U(x)⌉ + c`. This is little more than the
                           definition of domination unfolded: `T` is hidden behind an
                           existential, so the hypothesis cannot be discharged without
                           already having the conclusion. It is not used; `Levin.lean`
                           proves the statement for the universal prefix machine directly;
* `pair`, `iterate`, `twoPart` – the class is **closed under composition at exact additive
                           cost**: `K(x, y) ≤ K(x) + K(y)`, `K(fᵗ x) ≤ K(x) + 2 log t + 1`,
                           `K(x) ≤ K(π x) + ⌈log₂ W(π x)⌉`, each realized by a system that
                           is again prefix-free and unambiguous;
* `not_exists_universal` – but no system is universal for the class of *all* prefix-free
                           systems: invariance and the coding theorem need the further
                           restriction to computable systems
                           (`Instances/PrefixMachine.lean`).
-/

namespace Complexity

namespace Prefix

open DescSystem
open Limits (PrefixFree glue)

variable {X Y : Type*}

/-! ### Fixed-width numerals -/

/-- The `n`-bit numeral of `a`, most significant bit first. -/
def enc : ℕ → ℕ → List Bool
  | 0, _ => []
  | n + 1, a => enc n (a / 2) ++ [decide (a % 2 = 1)]

@[simp] theorem length_enc (n a : ℕ) : (enc n a).length = n := by
  induction n generalizing a with
  | zero => rfl
  | succ n ih => simp [enc, ih]

theorem enc_inj {n a b : ℕ} (ha : a < 2 ^ n) (hb : b < 2 ^ n) (h : enc n a = enc n b) :
    a = b := by
  induction n generalizing a b with
  | zero => simp at ha hb; omega
  | succ n ih =>
    simp only [enc] at h
    have h' := List.append_inj' h rfl
    have hp := pow_succ 2 n
    have h1 := ih (a := a / 2) (b := b / 2) (by omega) (by omega) h'.1
    have h2 : (a % 2 = 1) ↔ (b % 2 = 1) := by simpa using h'.2
    omega

/-- The first `k` bits of an `n`-bit numeral are the numeral of the quotient. -/
theorem take_enc {n k : ℕ} (hk : k ≤ n) (b : ℕ) :
    (enc n b).take k = enc k (b / 2 ^ (n - k)) := by
  induction n generalizing b with
  | zero =>
    obtain rfl : k = 0 := by omega
    simp [enc]
  | succ n ih =>
    rcases Nat.lt_or_ge k (n + 1) with h | h
    · have hk' : k ≤ n := by omega
      rw [enc, List.take_append_of_le_length (by simp [hk']), ih hk', Nat.div_div_eq_div_mul,
        ← pow_succ', Nat.succ_sub hk']
    · obtain rfl : k = n + 1 := by omega
      simp [List.take_of_length_le]

/-! ### The converse of Kraft's inequality, level by level -/

/-- First free position at level `n`, in units of `2 ^ (-n)`. -/
private def start (N : ℕ → ℕ) : ℕ → ℕ
  | 0 => 0
  | n + 1 => 2 * (start N n + N n)

private theorem start_add (N : ℕ → ℕ) (n : ℕ) :
    start N n + N n = ∑ k ∈ Finset.range (n + 1), N k * 2 ^ (n - k) := by
  induction n with
  | zero => simp [start]
  | succ n ih =>
    rw [Finset.sum_range_succ, start, ih, Finset.mul_sum, Nat.sub_self, pow_zero, mul_one]
    congr 1
    refine Finset.sum_congr rfl fun k hk => ?_
    have hk' : k ≤ n := Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)
    rw [Nat.succ_sub hk', pow_succ]
    ring

private theorem start_ge (N : ℕ → ℕ) (k d : ℕ) :
    2 ^ (d + 1) * (start N k + N k) ≤ start N (k + d + 1) := by
  induction d with
  | zero => simp [start]
  | succ d ih =>
    have h : start N (k + (d + 1) + 1) = 2 * (start N (k + d + 1) + N (k + d + 1)) := rfl
    rw [h, pow_succ]
    nlinarith [ih, Nat.zero_le (N (k + d + 1))]

private theorem exists_rank (L : Finset X) :
    ∃ r : X → ℕ, Set.InjOn r (L : Set X) ∧ ∀ x ∈ L, r x < L.card := by
  classical
  refine ⟨fun x => if h : x ∈ L then (L.equivFin ⟨x, h⟩ : ℕ) else 0, ?_, ?_⟩
  · intro x hx y hy hxy
    have hx' : x ∈ L := hx
    have hy' : y ∈ L := hy
    simp only [hx', hy', ↓reduceDIte] at hxy
    have := L.equivFin.injective (Fin.ext hxy)
    exact Subtype.mk.inj this
  · intro x hx
    simp only [hx, ↓reduceDIte]
    exact (L.equivFin ⟨x, hx⟩).2

/-- **Converse of Kraft's inequality**, combinatorial form. If the level sets
`L n = {x | f x = n}` are finite and satisfy Kraft's inequality at every level, then `f`
is the complexity of a prefix-free unambiguous binary system. -/
theorem exists_prefix_of_levels (f : X → ℕ∞) (L : ℕ → Finset X)
    (hL : ∀ n x, x ∈ L n ↔ f x = n)
    (hK : ∀ n, ∑ k ∈ Finset.range (n + 1), (L k).card * 2 ^ (n - k) ≤ 2 ^ n) :
    ∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧ PrefixFree S ∧
      ∀ x, S.K x = f x := by
  classical
  set N : ℕ → ℕ := fun n => (L n).card with hN
  choose r hrinj hrlt using fun n => exists_rank (L n)
  have hlt : ∀ (n : ℕ) (x : X), f x = (n : ℕ∞) → start N n + r n x < 2 ^ n := fun n x hx => by
    have h1 : r n x < N n := hrlt n x ((hL n x).2 hx)
    have h2 := start_add N n
    have h3 : ∑ k ∈ Finset.range (n + 1), N k * 2 ^ (n - k) ≤ 2 ^ n := hK n
    omega
  let S : DescSystem (List Bool) X ℕ∞ :=
    ⟨fun l => l.length, fun d x => ∃ n : ℕ, f x = n ∧ d = enc n (start N n + r n x)⟩
  have hreal : ∀ {d x}, S.realizes d x → f x = (d.length : ℕ) := by
    rintro d x ⟨n, hn, rfl⟩
    rw [length_enc, hn]
  refine ⟨S, fun _ => rfl, ?_, ?_, fun x => ?_⟩
  · rintro d x y ⟨n, hn, rfl⟩ ⟨m, hm, hd⟩
    have hnm : n = m := by simpa using congrArg List.length hd
    subst hnm
    have h := enc_inj (hlt n x hn) (hlt n y hm) hd
    exact hrinj n ((hL n x).2 hn) ((hL n y).2 hm) (Nat.add_left_cancel h)
  · rintro p q y y' ⟨n, hn, rfl⟩ ⟨m, hm, hd⟩
    by_contra hq
    have hlen : m = n + q.length := by simpa using (congrArg List.length hd).symm
    have hqpos : 0 < q.length := List.length_pos_iff.2 hq
    obtain ⟨d, hd'⟩ : ∃ d, q.length = d + 1 := ⟨q.length - 1, by omega⟩
    have hnm : n ≤ m := by omega
    have htake : enc n (start N n + r n y) = enc n ((start N m + r m y') / 2 ^ (m - n)) := by
      rw [← take_enc hnm, ← hd, List.take_left' (length_enc _ _)]
    have hb := hlt m y' hm
    have hpow : 2 ^ m = 2 ^ (m - n) * 2 ^ n := by rw [← pow_add]; congr 1; omega
    have hdiv : (start N m + r m y') / 2 ^ (m - n) < 2 ^ n :=
      Nat.div_lt_of_lt_mul (hpow ▸ hb)
    have heq := enc_inj (hlt n y hn) hdiv htake
    have hge := start_ge N n d
    have hmn : m = n + d + 1 := by omega
    have hmn' : m - n = d + 1 := by omega
    have hr : r n y < N n := hrlt n y ((hL n y).2 hn)
    rw [hmn'] at heq
    rw [← hmn] at hge
    have h1 : 2 ^ (d + 1) * (start N n + r n y + 1) ≤ start N m + r m y' :=
      (Nat.mul_le_mul_left _ (by omega)).trans (hge.trans (Nat.le_add_right _ _))
    have h2 : start N n + r n y + 1 ≤ (start N m + r m y') / 2 ^ (d + 1) :=
      (Nat.le_div_iff_mul_le (by positivity)).2 (by rw [mul_comm]; exact h1)
    omega
  · rcases eq_or_ne (f x) ⊤ with htop | hne
    · rw [htop]
      refine S.K_eq_top fun d hd => ?_
      have h := hreal hd
      rw [htop] at h
      exact ENat.top_ne_natCast _ h
    · obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 hne
      have hr : S.realizes (enc n (start N n + r n x)) x := ⟨n, hn.symm, rfl⟩
      apply le_antisymm
      · refine (S.K_le_cost hr).trans ?_
        show (((enc n (start N n + r n x)).length : ℕ) : ℕ∞) ≤ f x
        rw [length_enc, hn]
      · refine S.le_K_iff.2 fun d hd => ?_
        rw [hreal hd]

/-! ### Kraft's inequality and algorithmic probability -/

section Kraft

open scoped ENNReal

/-- The weight `2 ^ (-k)` of a complexity value, with `2 ^ (-∞) = 0`. -/
noncomputable def wt (k : ℕ∞) : ℝ≥0∞ := if k = ⊤ then 0 else (2⁻¹ : ℝ≥0∞) ^ k.toNat

@[simp] theorem wt_top : wt ⊤ = 0 := by simp [wt]

@[simp] theorem wt_coe (n : ℕ) : wt (n : ℕ∞) = (2⁻¹ : ℝ≥0∞) ^ n := by
  simp [wt]

private theorem sum_le_one_of_prefixFree (T : Finset (List Bool))
    (hT : InformationTheory.IsPrefixFree (T : Set (List Bool))) :
    ∑ w ∈ T, (2⁻¹ : ℝ≥0∞) ^ w.length ≤ 1 := by
  have h := hT.finsetSum_one_div_card_pow_length_le_one
  rw [Fintype.card_bool] at h
  have hterm : ∀ w : List Bool,
      (2⁻¹ : ℝ≥0∞) ^ w.length = ENNReal.ofReal ((1 / ((2 : ℕ) : ℝ)) ^ w.length) := by
    intro w
    rw [ENNReal.ofReal_pow (by positivity), one_div, ENNReal.ofReal_inv_of_pos (by norm_num)]
    simp
  simp_rw [hterm]
  rw [← ENNReal.ofReal_sum_of_nonneg (fun _ _ => by positivity)]
  exact ENNReal.ofReal_le_one.2 h

/-- The **algorithmic probability** of `x`: the chance that fair coin flips spell out a
description of `x`. -/
noncomputable def P (S : DescSystem (List Bool) X ℕ∞) (x : X) : ℝ≥0∞ :=
  Thermo.Z List.length S.realizes 2⁻¹ x

/-- **Kraft's inequality** for a self-delimiting unambiguous system: algorithmic
probabilities sum to at most one (they form a semimeasure). -/
theorem tsum_P_le_one (S : DescSystem (List Bool) X ℕ∞) (hS : S.Functional)
    (hpf : PrefixFree S) : ∑' x, P S x ≤ 1 := by
  classical
  have hinj : Function.Injective (fun p : Σ x, {d // S.realizes d x} => p.2.1) := by
    rintro ⟨x, d, hd⟩ ⟨y, e, he⟩ hde
    have hde' : d = e := hde
    subst hde'
    have hxy : x = y := hS hd he
    subst hxy
    rfl
  have h1 : ∑' x, P S x = ∑' p : Σ x, {d // S.realizes d x}, (2⁻¹ : ℝ≥0∞) ^ p.2.1.length :=
    (tsum_sigma (β := fun x => {d // S.realizes d x})
      fun _ d => (2⁻¹ : ℝ≥0∞) ^ d.1.length).symm
  rw [h1, tsum_eq_iSup_sum]
  refine iSup_le fun F => ?_
  rw [← Finset.sum_image (f := fun w : List Bool => (2⁻¹ : ℝ≥0∞) ^ w.length)
    (g := fun p : Σ x, {d // S.realizes d x} => p.2.1) fun a _ b _ h => hinj h]
  refine sum_le_one_of_prefixFree _ ?_
  intro a ha b hb hab
  obtain ⟨q, rfl⟩ := hab
  obtain ⟨⟨x, d, hd⟩, -, rfl⟩ := Finset.mem_image.1 (Finset.mem_coe.1 ha)
  obtain ⟨⟨y, e, he⟩, -, hq⟩ := Finset.mem_image.1 (Finset.mem_coe.1 hb)
  have hq' : e = d ++ q := hq
  subst hq'
  have := hpf hd he
  simp [this]

/-- **Simple implies probable**: `2 ^ (-K x) ≤ P x`. -/
theorem wt_K_le_P (S : DescSystem (List Bool) X ℕ∞) (hb : S.IsBinary) (x : X) :
    wt (S.K x) ≤ P S x := by
  rcases eq_or_ne (S.K x) ⊤ with h | h
  · simp [h]
  obtain ⟨d, hd, hc⟩ := S.exists_cost_eq_K h
  rw [← hc, hb d, wt_coe]
  exact Thermo.pow_len_le_Z List.length S.realizes _ hd

/-- **Kraft's inequality for complexities**: `∑ₓ 2^(-K x) ≤ 1`. -/
theorem kraft (S : DescSystem (List Bool) X ℕ∞) (hb : S.IsBinary) (hS : S.Functional)
    (hpf : PrefixFree S) : ∑' x, wt (S.K x) ≤ 1 :=
  (tsum_le_tsum (wt_K_le_P S hb)).trans (tsum_P_le_one S hS hpf)

/-- **Converse of Kraft's inequality** for an arbitrary index set: every `f` with
`∑ₓ 2^(-f x) ≤ 1` is the complexity of a prefix-free unambiguous binary system. -/
theorem exists_prefix_of_tsum_le (f : X → ℕ∞) (h : ∑' x, wt (f x) ≤ 1) :
    ∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧ PrefixFree S ∧
      ∀ x, S.K x = f x := by
  classical
  have hne : ∑' x, wt (f x) ≠ ⊤ := ne_top_of_le_ne_top ENNReal.one_ne_top h
  have hpos : ∀ n : ℕ, (2⁻¹ : ℝ≥0∞) ^ n ≠ 0 := fun n => pow_ne_zero _ (by simp)
  have hfin : ∀ n : ℕ, {x | f x = (n : ℕ∞)}.Finite := fun n =>
    (ENNReal.finite_const_le_of_tsum_ne_top hne (hpos n)).subset fun x hx => by
      have hx' : f x = n := hx
      show (2⁻¹ : ℝ≥0∞) ^ n ≤ wt (f x)
      rw [hx', wt_coe]
  let L : ℕ → Finset X := fun n => (hfin n).toFinset
  have hL : ∀ n x, x ∈ L n ↔ f x = n := fun n x => by simp [L]
  refine exists_prefix_of_levels f L hL fun n => ?_
  have hdisj : Set.PairwiseDisjoint (↑(Finset.range (n + 1)) : Set ℕ) L := by
    intro i _ j _ hij
    rw [Function.onFun, Finset.disjoint_left]
    intro x hi hj
    have := ((hL i x).1 hi).symm.trans ((hL j x).1 hj)
    exact hij (by exact_mod_cast this)
  have hsum : ∑ k ∈ Finset.range (n + 1), ((L k).card : ℝ≥0∞) * 2⁻¹ ^ k ≤ 1 := by
    calc ∑ k ∈ Finset.range (n + 1), ((L k).card : ℝ≥0∞) * 2⁻¹ ^ k
        = ∑ k ∈ Finset.range (n + 1), ∑ x ∈ L k, wt (f x) := by
          refine Finset.sum_congr rfl fun k _ => ?_
          rw [Finset.sum_congr rfl fun x hx => by rw [(hL k x).1 hx, wt_coe],
            Finset.sum_const, nsmul_eq_mul]
      _ = ∑ x ∈ (Finset.range (n + 1)).biUnion L, wt (f x) :=
          (Finset.sum_biUnion hdisj).symm
      _ ≤ ∑' x, wt (f x) := sum_le_tsum _
      _ ≤ 1 := h
  have hterm : ∀ k ∈ Finset.range (n + 1),
      ((L k).card : ℝ≥0∞) * 2 ^ (n - k) = 2 ^ n * (((L k).card : ℝ≥0∞) * 2⁻¹ ^ k) := by
    intro k hk
    have hk' : k ≤ n := Nat.lt_succ_iff.1 (Finset.mem_range.1 hk)
    have h2 : (2 : ℝ≥0∞) ^ n = 2 ^ (n - k) * 2 ^ k := by
      rw [← pow_add, Nat.sub_add_cancel hk']
    have h3 : (2 : ℝ≥0∞) ^ k * 2⁻¹ ^ k = 1 := by
      rw [← mul_pow, ENNReal.mul_inv_cancel (by norm_num) (by norm_num), one_pow]
    calc ((L k).card : ℝ≥0∞) * 2 ^ (n - k)
        = ((L k).card : ℝ≥0∞) * 2 ^ (n - k) * (2 ^ k * 2⁻¹ ^ k) := by rw [h3, mul_one]
      _ = 2 ^ n * (((L k).card : ℝ≥0∞) * 2⁻¹ ^ k) := by rw [h2]; ring
  have hfinal : ((∑ k ∈ Finset.range (n + 1), (L k).card * 2 ^ (n - k) : ℕ) : ℝ≥0∞)
      ≤ ((2 ^ n : ℕ) : ℝ≥0∞) := by
    push_cast
    rw [Finset.sum_congr rfl hterm, ← Finset.mul_sum]
    calc (2 : ℝ≥0∞) ^ n * ∑ k ∈ Finset.range (n + 1), ((L k).card : ℝ≥0∞) * 2⁻¹ ^ k
        ≤ 2 ^ n * 1 := by gcongr
      _ = 2 ^ n := mul_one _
  exact_mod_cast hfinal

/-- **Representation theorem for self-delimiting complexity.** A function is the
complexity of a prefix-free unambiguous binary system if and only if it satisfies Kraft's
inequality. Unlike `Limits.exists_system_K_eq`, this excludes functions: prefix
complexities are exactly the negative logarithms of dyadic semimeasures. -/
theorem exists_prefix_iff (f : X → ℕ∞) :
    (∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧ PrefixFree S ∧
      ∀ x, S.K x = f x) ↔ ∑' x, wt (f x) ≤ 1 := by
  refine ⟨?_, exists_prefix_of_tsum_le f⟩
  rintro ⟨S, hb, hS, hpf, hK⟩
  simpa only [hK] using kraft S hb hS hpf

/-- **Coding theorem, existence form.** For every self-delimiting unambiguous system `S`
there is another, `T`, whose complexity is the rounded-up negative logarithm of the
algorithmic probability of `S`: `2^(-K_T x) ≤ P_S x`, and `K_T x ≤ n` whenever
`2^(-n) ≤ P_S x`. -/
theorem exists_coding (S : DescSystem (List Bool) X ℕ∞) (hS : S.Functional)
    (hpf : PrefixFree S) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      (∀ x, wt (T.K x) ≤ P S x) ∧ ∀ x (n : ℕ), (2⁻¹ : ℝ≥0∞) ^ n ≤ P S x → T.K x ≤ n := by
  classical
  have hex : ∀ x, P S x ≠ 0 → ∃ n : ℕ, (2⁻¹ : ℝ≥0∞) ^ n ≤ P S x := fun x hx => by
    obtain ⟨n, hn⟩ := ENNReal.exists_inv_two_pow_lt hx
    exact ⟨n, hn.le⟩
  let f : X → ℕ∞ := fun x => if h : P S x = 0 then ⊤ else ((Nat.find (hex x h) : ℕ) : ℕ∞)
  have hf : ∀ x, wt (f x) ≤ P S x := fun x => by
    by_cases h : P S x = 0
    · simp [f, h]
    · simp only [f, h, ↓reduceDIte, wt_coe]
      exact Nat.find_spec (hex x h)
  obtain ⟨T, hb, hT, hTpf, hK⟩ := exists_prefix_of_tsum_le f
    ((tsum_le_tsum hf).trans (tsum_P_le_one S hS hpf))
  refine ⟨T, hb, hT, hTpf, fun x => (hK x).symm ▸ hf x, fun x n hn => ?_⟩
  have h : P S x ≠ 0 := fun h0 => by
    rw [h0] at hn
    exact pow_ne_zero n (by simp) (le_antisymm hn bot_le)
  rw [hK]
  simp only [f, h, ↓reduceDIte]
  exact_mod_cast Nat.find_min' (hex x h) hn

/-- **Complex implies improbable**, conditionally. If a self-delimiting system `U`
dominates the system built from its own algorithmic probability, then
`K_U(x) ≤ ⌈-log₂ P_U(x)⌉ + c`. For the universal prefix machine the domination hypothesis
is Levin's coding theorem (the built system is computable); it is proved, by a different
construction that is computable from the start, in `Levin.levin`. -/
theorem coding_of_dominates (U : DescSystem (List Bool) X ℕ∞) (hU : U.Functional)
    (hpf : PrefixFree U) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      (∀ x, wt (T.K x) ≤ P U x) ∧
      (Dominates U T → ∃ c : ℕ, ∀ x (n : ℕ), (2⁻¹ : ℝ≥0∞) ^ n ≤ P U x → U.K x ≤ n + c) := by
  obtain ⟨T, hb, hT, hTpf, h1, h2⟩ := exists_coding U hU hpf
  refine ⟨T, hb, hT, hTpf, h1, ?_⟩
  rintro ⟨c, hc⟩
  exact ⟨c, fun x n hn => (hc x).trans (add_le_add (h2 x n hn) le_rfl)⟩

end Kraft

/-! ### Closure under composition at exact additive cost -/

section Closure

variable {Z : Type*}

/-- Glued descriptions are again self-delimiting when both parts are. -/
theorem glue_prefixFree {S : DescSystem (List Bool) Y ℕ∞} (hS : S.Functional)
    (hpf : PrefixFree S) {F : Y → List Bool → X → Prop}
    (hF : ∀ y q q' x x', F y q x → F y (q ++ q') x' → q' = []) : PrefixFree (glue S F) := by
  rintro l e x x' ⟨p, q, y, rfl, hp, hx⟩ ⟨p', q', y', h, hp', hx'⟩
  have hpp : p = p' ∧ q ++ e = q' := by
    rw [List.append_assoc] at h
    rcases List.append_eq_append_iff.1 h with ⟨a, rfl, h2⟩ | ⟨a, rfl, rfl⟩
    · have ha : a = [] := hpf hp hp'
      subst ha
      exact ⟨by simp, by simpa using h2⟩
    · have ha : a = [] := hpf hp' hp
      subst ha
      simp
  obtain ⟨rfl, rfl⟩ := hpp
  obtain rfl : y = y' := hS hp hp'
  exact hF _ _ _ _ _ hx hx'

/-- **Composition.** Two self-delimiting unambiguous systems compose, along any way `g` of
combining their objects, into a self-delimiting unambiguous system in which costs add
exactly – no delimiter, no logarithmic correction, no constant. -/
theorem exists_comp (S : DescSystem (List Bool) Y ℕ∞) (hb : S.IsBinary) (hS : S.Functional)
    (hpf : PrefixFree S) (S' : DescSystem (List Bool) Z ℕ∞) (hb' : S'.IsBinary)
    (hS' : S'.Functional) (hpf' : PrefixFree S') (g : Y → Z → X) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      ∀ y z, T.K (g y z) ≤ S.K y + S'.K z := by
  let F : Y → List Bool → X → Prop := fun y q x => ∃ z, S'.realizes q z ∧ g y z = x
  refine ⟨glue S F, Limits.glue_isBinary _ _, Limits.glue_functional hS hpf ?_,
    glue_prefixFree hS hpf ?_, fun y z => ?_⟩
  · rintro y q x x' ⟨z, hz, rfl⟩ ⟨z', hz', rfl⟩
    rw [hS' hz hz']
  · rintro y q q' x x' ⟨z, hz, -⟩ ⟨z', hz', -⟩
    exact hpf' hz hz'
  · rcases eq_or_ne (S'.K z) ⊤ with h | h
    · simp [h]
    obtain ⟨q, hq, hc⟩ := S'.exists_cost_eq_K h
    rw [← hc, hb' q]
    exact Limits.K_glue_le S hb (F := F) ⟨z, hq, rfl⟩

/-- **Subadditivity**: `K(x, y) ≤ K(x) + K(y)` in a self-delimiting system built from the
two. (False with a constant for plain complexity.) -/
theorem pair (S : DescSystem (List Bool) Y ℕ∞) (hb : S.IsBinary) (hS : S.Functional)
    (hpf : PrefixFree S) (S' : DescSystem (List Bool) Z ℕ∞) (hb' : S'.IsBinary)
    (hS' : S'.Functional) (hpf' : PrefixFree S') :
    ∃ T : DescSystem (List Bool) (Y × Z) ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      ∀ y z, T.K (y, z) ≤ S.K y + S'.K z :=
  exists_comp S hb hS hpf S' hb' hS' hpf' Prod.mk

private theorem header_append_eq {n m : ℕ} {q : List Bool}
    (h : Kolmogorov.header n ++ q = Kolmogorov.header m) : n = m ∧ q = [] := by
  have h1 : n = m := by
    have := congrArg Kolmogorov.index h
    rw [Kolmogorov.index_header_append, ← List.append_nil (Kolmogorov.header m),
      Kolmogorov.index_header_append] at this
    exact this
  subst h1
  exact ⟨rfl, by simpa using h⟩

/-- Unary numerals: `n` is described by `n` ones and a zero. -/
def unary : DescSystem (List Bool) ℕ ℕ∞ :=
  ⟨fun l => l.length, fun d n => d = Kolmogorov.header n⟩

theorem unary_functional : unary.Functional := by
  rintro d x y hx hy
  have hx' : d = Kolmogorov.header x := hx
  have hy' : d = Kolmogorov.header y := hy
  exact (header_append_eq (q := []) (by rw [List.append_nil, ← hx', hy'])).1

theorem unary_prefixFree : PrefixFree unary := by
  rintro p q y y' hp hq
  have hp' : p = Kolmogorov.header y := hp
  have hq' : p ++ q = Kolmogorov.header y' := hq
  subst hp'
  exact (header_append_eq hq').2

/-- A self-delimiting numeral system: the length in unary, then the binary digits. -/
def natSys : DescSystem (List Bool) ℕ ℕ∞ :=
  glue unary fun n q t => q.length = n ∧ Limits.numeral q = t

theorem natSys_functional : natSys.Functional :=
  Limits.glue_functional unary_functional unary_prefixFree
    fun _ _ _ _ h h' => h.2.symm.trans h'.2

theorem natSys_prefixFree : PrefixFree natSys :=
  glue_prefixFree unary_functional unary_prefixFree fun y q q' x x' h h' => by
    have h1 := h.1
    have h2 := h'.1
    rw [List.length_append] at h2
    exact List.length_eq_zero_iff.1 (by omega)

/-- A number `t` has a self-delimiting description of `2 log t + 1` bits. -/
theorem natSys_K_le (t : ℕ) : natSys.K t ≤ ((2 * Nat.size t + 1 : ℕ) : ℕ∞) := by
  have h := Limits.K_glue_le unary (fun _ => rfl)
    (F := fun n q t => q.length = n ∧ Limits.numeral q = t) (y := Nat.size t)
    (q := Nat.bits t) (x := t) ⟨Nat.size_eq_bits_len t, Limits.numeral_bits t⟩
  have hu : unary.K (Nat.size t) ≤ ((Nat.size t + 1 : ℕ) : ℕ∞) := by
    refine (unary.K_le_cost (d := Kolmogorov.header (Nat.size t)) rfl).trans ?_
    show (((Kolmogorov.header (Nat.size t)).length : ℕ) : ℕ∞) ≤ _
    rw [Kolmogorov.length_header]
  refine h.trans ?_
  rw [Nat.size_eq_bits_len]
  calc unary.K (Nat.size t) + (Nat.size t : ℕ∞)
      ≤ ((Nat.size t + 1 : ℕ) : ℕ∞) + (Nat.size t : ℕ∞) := add_le_add hu le_rfl
    _ = ((2 * Nat.size t + 1 : ℕ) : ℕ∞) := by push_cast; ring

/-- **The logarithmic growth law** for self-delimiting systems:
`K(fᵗ x) ≤ K(x) + 2 log t + 1`, in a system that is again self-delimiting. -/
theorem iterate (S : DescSystem (List Bool) X ℕ∞) (hb : S.IsBinary) (hS : S.Functional)
    (hpf : PrefixFree S) (f : X → X) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      ∀ x t, T.K (f^[t] x) ≤ S.K x + ((2 * Nat.size t + 1 : ℕ) : ℕ∞) := by
  obtain ⟨T, h1, h2, h3, h4⟩ := exists_comp S hb hS hpf natSys (Limits.glue_isBinary _ _)
    natSys_functional natSys_prefixFree fun x t => f^[t] x
  exact ⟨T, h1, h2, h3, fun x t => (h4 x t).trans (add_le_add le_rfl (natSys_K_le t))⟩

/-- **The two-part code** for self-delimiting systems: with index words of one length per
macrostate, `K(x) ≤ K(π x) + |code x|` in a system that is again self-delimiting. -/
theorem twoPart (S : DescSystem (List Bool) Y ℕ∞) (hb : S.IsBinary) (hS : S.Functional)
    (hpf : PrefixFree S) (π : X → Y) (code : X → List Bool)
    (hcode : ∀ x x', π x = π x' → code x = code x' → x = x')
    (hlen : ∀ x x', π x = π x' → (code x).length = (code x').length) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      ∀ x, T.K x ≤ S.K (π x) + (code x).length := by
  refine ⟨glue S fun y q x => π x = y ∧ code x = q, Limits.glue_isBinary _ _,
    Limits.glue_functional hS hpf ?_, glue_prefixFree hS hpf ?_,
    fun x => Limits.K_glue_le S hb ⟨rfl, rfl⟩⟩
  · rintro y q x x' ⟨h1, h2⟩ ⟨h1', h2'⟩
    exact hcode x x' (h1.trans h1'.symm) (h2.trans h2'.symm)
  · rintro y q q' x x' ⟨h1, h2⟩ ⟨h1', h2'⟩
    have h := hlen x x' (h1.trans h1'.symm)
    rw [h2, h2', List.length_append] at h
    exact List.length_eq_zero_iff.1 (by omega)

/-- **Macro-complexity plus Boltzmann entropy**, self-delimiting form: if the fibre over
`y` has at most `W y` members then `K(x) ≤ K(π x) + ⌈log₂ W(π x)⌉`. -/
theorem twoPart_card (S : DescSystem (List Bool) Y ℕ∞) (hb : S.IsBinary) (hS : S.Functional)
    (hpf : PrefixFree S) (π : X → Y) (W : Y → ℕ)
    (hW : ∀ y, ∃ F : Finset X, (∀ x, π x = y → x ∈ F) ∧ F.card ≤ W y) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧ PrefixFree T ∧
      ∀ x, T.K x ≤ S.K (π x) + Nat.clog 2 (W (π x)) := by
  classical
  choose F hF hcard using hW
  have hle : ∀ y, Fintype.card (F y) ≤ Fintype.card (List.Vector Bool (Nat.clog 2 (W y))) := by
    intro y
    rw [Fintype.card_coe, card_vector, Fintype.card_bool]
    exact (hcard y).trans (Nat.le_pow_clog (by norm_num) _)
  have e : ∀ y, F y ↪ List.Vector Bool (Nat.clog 2 (W y)) := fun y =>
    (Function.Embedding.nonempty_of_card_le (hle y)).some
  let code : X → List Bool := fun x => (e (π x) ⟨x, hF (π x) x rfl⟩).toList
  have hc_len : ∀ x, (code x).length = Nat.clog 2 (W (π x)) := fun x =>
    List.Vector.toList_length _
  have hc_inj : ∀ x x', π x = π x' → code x = code x' → x = x' := by
    intro x x' hπ h
    have key : ∀ (y : Y) (hx : π x = y) (hx' : π x' = y),
        (e y ⟨x, hF y x hx⟩).toList = (e y ⟨x', hF y x' hx'⟩).toList → x = x' := by
      intro y hx hx' h'
      have h1 := (e y).injective (List.Vector.toList_injective h')
      exact Subtype.mk.inj h1
    have hx'' : (e (π x) ⟨x, hF (π x) x rfl⟩).toList
        = (e (π x') ⟨x, hF (π x') x hπ⟩).toList := by
      clear h key
      generalize π x' = y at hπ
      subst hπ
      rfl
    exact key (π x') hπ rfl (hx''.symm.trans h)
  obtain ⟨T, h1, h2, h3, h4⟩ := twoPart S hb hS hpf π code hc_inj
    fun x x' h => by rw [hc_len, hc_len, h]
  exact ⟨T, h1, h2, h3, fun x => by simpa [hc_len] using h4 x⟩

/-- **No universal self-delimiting system without a restricted class.** On an infinite
set, every unambiguous binary system `U` is beaten by more than any constant by some
prefix-free unambiguous system. The coding theorem and invariance are therefore
properties of a restricted class (the computable systems), not of prefix-freeness. -/
theorem not_exists_universal [Infinite X] (U : DescSystem (List Bool) X ℕ∞)
    (hb : U.IsBinary) (hU : U.Functional) :
    ∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧ PrefixFree S ∧
      ¬ Dominates U S := by
  classical
  have hex : ∀ k : ℕ, ∃ x, ((2 * k + 2 : ℕ) : ℕ∞) ≤ U.K x := fun k => by
    obtain ⟨A, hA⟩ := Finset.exists_card_eq (α := X) (2 ^ (2 * k + 2))
    obtain ⟨x, -, hx⟩ := hb.exists_incompressible hU (2 * k + 2) A hA.ge
    exact ⟨x, hx⟩
  choose g hg using hex
  let S : DescSystem (List Bool) X ℕ∞ :=
    ⟨fun l => l.length, fun d x => ∃ k, d = Kolmogorov.header k ∧ x = g k⟩
  refine ⟨S, fun _ => rfl, ?_, ?_, ?_⟩
  · rintro d x y ⟨k, rfl, rfl⟩ ⟨k', h, rfl⟩
    have hk : k = k' :=
      (header_append_eq (n := k) (m := k') (q := []) (by rw [List.append_nil]; exact h)).1
    rw [hk]
  · rintro p q y y' ⟨k, rfl, -⟩ ⟨k', h, -⟩
    exact (header_append_eq h).2
  · rintro ⟨c, hc⟩
    have h1 : S.K (g c) ≤ ((c + 1 : ℕ) : ℕ∞) := by
      refine (S.K_le_cost (d := Kolmogorov.header c) ⟨c, rfl, rfl⟩).trans ?_
      show (((Kolmogorov.header c).length : ℕ) : ℕ∞) ≤ _
      rw [Kolmogorov.length_header]
    have h2 : ((2 * c + 2 : ℕ) : ℕ∞) ≤ ((c + 1 + c : ℕ) : ℕ∞) := by
      calc ((2 * c + 2 : ℕ) : ℕ∞) ≤ U.K (g c) := hg c
        _ ≤ S.K (g c) + c := hc _
        _ ≤ ((c + 1 : ℕ) : ℕ∞) + c := add_le_add h1 le_rfl
        _ = ((c + 1 + c : ℕ) : ℕ∞) := by push_cast; rfl
    have h3 : 2 * c + 2 ≤ c + 1 + c := by exact_mod_cast h2
    omega

end Closure


end Prefix

end Complexity
