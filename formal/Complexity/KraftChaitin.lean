import Complexity.Prefix

/-!
# The effective converse of Kraft's inequality (Kraft–Chaitin)

`Prefix.exists_prefix_of_tsum_le` builds a self-delimiting code with prescribed lengths
whenever the weights sum to at most one, but the construction sorts the requests by length,
which no machine can do for an infinite list. Here the requests arrive one at a time, the
code word of each is fixed when it arrives, and the resulting decoder is a **partial
recursive function**.

A request is a pair `(x, n)`: "give `x` a description whose weight is `2 ^ (-n)`". The
request list is `r : ℕ → Option (ℕ × ℕ)` (`none` = no request at this index).

The allocation is the Shannon–Fano–Elias one. Request `i` owns the real interval
`[s i, s i + 2 ^ (-n))`, where `s i` is the total weight of the earlier requests. Every
interval of length `2 ^ (-n)` contains an aligned dyadic interval of length `2 ^ (-(n+1))`;
its `n + 1` bits are the code word. Distinct requests own disjoint intervals, so no code
word is a prefix of another. The price is **one bit**: the word has length `n + 1`.

* `machine r`            – the decoder: find the request that owns the input;
* `machine_partrec`      – it is partial recursive when `r` is primitive recursive;
* `machine_prefixFree`   – its domain is prefix-free;
* `exists_program`       – if the weights sum to at most one, every request `(x, n)` is
                           served by a program of length `n + 1`;
* `exists_machine`       – the packaged statement.

The cumulative weight is kept exactly, as a pair `(T, B)` meaning `T / 2 ^ B`, so that the
slot `⌈s i * 2 ^ (n+1)⌉` is natural-number arithmetic.
-/

namespace Complexity

namespace KraftChaitin

open Primrec

theorem primrec_pow : Primrec₂ ((· ^ ·) : ℕ → ℕ → ℕ) :=
  Primrec₂.unpaired'.1 Nat.Primrec.pow

/-! ### Bit strings as numerals -/

/-- The number written by a bit string, most significant bit first. -/
def val (w : List Bool) : ℕ := w.foldl (fun a b => 2 * a + b.toNat) 0

@[simp] theorem val_nil : val [] = 0 := rfl

theorem val_concat (w : List Bool) (b : Bool) : val (w ++ [b]) = 2 * val w + b.toNat := by
  simp [val, List.foldl_append]

theorem val_append (w z : List Bool) : val (w ++ z) = val w * 2 ^ z.length + val z := by
  induction z using List.reverseRecOn with
  | nil => simp
  | append_singleton z b ih =>
    rw [← List.append_assoc, val_concat, ih, val_concat, List.length_append,
      List.length_singleton, pow_succ]
    ring

theorem val_lt (z : List Bool) : val z < 2 ^ z.length := by
  induction z using List.reverseRecOn with
  | nil => simp
  | append_singleton z b ih =>
    rw [val_concat, List.length_append, List.length_singleton, pow_succ]
    have : b.toNat ≤ 1 := Bool.toNat_le b
    omega

/-- Every number below `2 ^ n` is written by a string of exactly `n` bits. -/
theorem exists_val (n a : ℕ) (h : a < 2 ^ n) : ∃ w : List Bool, w.length = n ∧ val w = a := by
  induction n generalizing a with
  | zero =>
    refine ⟨[], rfl, ?_⟩
    simp at h
    simp [h]
  | succ n ih =>
    obtain ⟨w, hw, hv⟩ := ih (a / 2) (by rw [pow_succ] at h; omega)
    refine ⟨w ++ [decide (a % 2 = 1)], by simp [hw], ?_⟩
    rw [val_concat, hv]
    rcases Nat.mod_two_eq_zero_or_one a with h2 | h2 <;> simp [h2] <;> omega

theorem val_primrec : Primrec val :=
  (list_foldl Primrec.id (const 0)
    (nat_add.comp (nat_double.comp (fst.comp snd))
      ((dom_bool Bool.toNat).comp (snd.comp snd))).to₂).of_eq fun _ => rfl

/-! ### The allocation -/

/-- Add one request to the running total `T / 2 ^ B`. -/
def upd (o : Option (ℕ × ℕ)) (s : ℕ × ℕ) : ℕ × ℕ :=
  Option.casesOn (motive := fun _ => ℕ × ℕ) o s fun xn =>
    (s.1 * 2 ^ xn.2 + 2 ^ s.2, s.2 + xn.2)

/-- The total weight of the requests before index `i`, as `(T, B)` meaning `T / 2 ^ B`. -/
def st (r : ℕ → Option (ℕ × ℕ)) (i : ℕ) : ℕ × ℕ :=
  Nat.rec (motive := fun _ => ℕ × ℕ) (0, 0) (fun j s => upd (r j) s) i

theorem st_succ (r : ℕ → Option (ℕ × ℕ)) (i : ℕ) : st r (i + 1) = upd (r i) (st r i) := rfl

/-- The slot of a request of weight `2 ^ (-n)` arriving at index `i`: the least multiple of
`2 ^ (-(n+1))` not below the running total. -/
def slot (r : ℕ → Option (ℕ × ℕ)) (i n : ℕ) : ℕ :=
  ((st r i).1 * 2 ^ (n + 1) + 2 ^ (st r i).2 - 1) / 2 ^ (st r i).2

/-- Request `i` **owns** the string `w` for the object `x`. -/
def Own (r : ℕ → Option (ℕ × ℕ)) (i : ℕ) (w : List Bool) (x : ℕ) : Prop :=
  ∃ n, r i = some (x, n) ∧ w.length = n + 1 ∧ val w = slot r i n

/-- What request `i` says about the input `w`. -/
def hit (r : ℕ → Option (ℕ × ℕ)) (w : List Bool) (i : ℕ) : Option ℕ :=
  (r i).bind fun xn =>
    if w.length = xn.2 + 1 ∧ val w = slot r i xn.2 then some xn.1 else none

theorem hit_eq_some {r : ℕ → Option (ℕ × ℕ)} {w : List Bool} {i x : ℕ} :
    hit r w i = some x ↔ Own r i w x := by
  unfold hit Own
  rcases h : r i with _ | ⟨x', n⟩
  · simp
  · simp only [Option.bind_some, Option.some.injEq, Prod.mk.injEq]
    constructor
    · intro h'
      split_ifs at h' with hc
      · exact ⟨n, ⟨Option.some.inj h', rfl⟩, hc.1, hc.2⟩
    · rintro ⟨m, ⟨rfl, rfl⟩, h1, h2⟩
      simp [h1, h2]

/-- The decoder: search for the request that owns the input, and output its object. -/
def machine (r : ℕ → Option (ℕ × ℕ)) : List Bool →. ℕ := fun w => Nat.rfindOpt (hit r w)

/-! ### Computability -/

theorem upd_primrec : Primrec₂ upd :=
  (option_casesOn fst snd
    (Primrec.pair
      (nat_add.comp
        (nat_mul.comp (fst.comp (snd.comp fst)) (primrec_pow.comp (const 2) (snd.comp snd)))
        (primrec_pow.comp (const 2) (snd.comp (snd.comp fst))))
      (nat_add.comp (snd.comp (snd.comp fst)) (snd.comp snd))).to₂).of_eq fun p => by
    rcases p with ⟨_ | _, _⟩ <;> rfl

theorem st_primrec {r : ℕ → Option (ℕ × ℕ)} (hr : Primrec r) : Primrec (st r) :=
  (nat_rec' Primrec.id (const (0, 0))
    (upd_primrec.comp (hr.comp (fst.comp snd)) (snd.comp snd)).to₂).of_eq fun _ => rfl

theorem slot_primrec {r : ℕ → Option (ℕ × ℕ)} (hr : Primrec r) : Primrec₂ (slot r) :=
  have hs := st_primrec hr
  (nat_div.comp
    (nat_sub.comp
      (nat_add.comp
        (nat_mul.comp (fst.comp (hs.comp fst)) (primrec_pow.comp (const 2) (succ.comp snd)))
        (primrec_pow.comp (const 2) (snd.comp (hs.comp fst))))
      (const 1))
    (primrec_pow.comp (const 2) (snd.comp (hs.comp fst)))).to₂

theorem hit_primrec {r : ℕ → Option (ℕ × ℕ)} (hr : Primrec r) : Primrec₂ (hit r) :=
  (option_bind (hr.comp snd)
    (Primrec.ite
      (PrimrecPred.and
        (Primrec.eq.comp (list_length.comp (fst.comp fst)) (succ.comp (snd.comp snd)))
        (Primrec.eq.comp (val_primrec.comp (fst.comp fst))
          ((slot_primrec hr).comp (snd.comp fst) (snd.comp snd))))
      (option_some.comp (fst.comp snd)) (const none)).to₂).to₂

/-- The decoder of a primitive recursive request list is partial recursive. -/
theorem machine_partrec {r : ℕ → Option (ℕ × ℕ)} (hr : Primrec r) : Partrec (machine r) :=
  Partrec.rfindOpt (hit_primrec hr).to_comp

/-! ### Correctness, over the reals -/

/-- The weight `2 ^ (-n)` of a request. -/
noncomputable def wR (o : Option (ℕ × ℕ)) : ℝ :=
  Option.casesOn (motive := fun _ => ℝ) o 0 fun xn => (2⁻¹ : ℝ) ^ xn.2

theorem wR_nonneg (o : Option (ℕ × ℕ)) : 0 ≤ wR o := by
  rcases o with _ | xn
  · exact le_rfl
  · exact pow_nonneg (by norm_num) _

/-- The total weight of the requests before index `i`. -/
noncomputable def cum (r : ℕ → Option (ℕ × ℕ)) (i : ℕ) : ℝ := ∑ j ∈ Finset.range i, wR (r j)

theorem cum_succ (r : ℕ → Option (ℕ × ℕ)) (i : ℕ) : cum r (i + 1) = cum r i + wR (r i) :=
  Finset.sum_range_succ _ _

theorem cum_mono (r : ℕ → Option (ℕ × ℕ)) {i j : ℕ} (h : i ≤ j) : cum r i ≤ cum r j :=
  Finset.sum_le_sum_of_subset_of_nonneg (Finset.range_mono h) fun _ _ _ => wR_nonneg _

theorem st_eq (r : ℕ → Option (ℕ × ℕ)) (i : ℕ) :
    ((st r i).1 : ℝ) = cum r i * 2 ^ (st r i).2 := by
  induction i with
  | zero => simp [st, cum]
  | succ i ih =>
    rw [st_succ, cum_succ]
    rcases r i with _ | ⟨x, n⟩
    · simpa [upd, wR] using ih
    · have h2 : (2⁻¹ : ℝ) ^ n * 2 ^ n = 1 := by rw [← mul_pow]; norm_num
      simp only [upd, wR]
      push_cast
      rw [ih, pow_add]
      linear_combination (-(2 : ℝ) ^ (st r i).2) * h2

/-- The slot lies in the interval owned by the request, with room for a whole aligned
interval of half the length. -/
theorem slot_bounds (r : ℕ → Option (ℕ × ℕ)) (i n : ℕ) :
    cum r i * 2 ^ (n + 1) ≤ slot r i n ∧
      (slot r i n : ℝ) + 1 < (cum r i + 2⁻¹ ^ n) * 2 ^ (n + 1) := by
  have hst := st_eq r i
  have hD : 0 < 2 ^ (st r i).2 := by positivity
  have h1 : (st r i).1 * 2 ^ (n + 1) ≤ slot r i n * 2 ^ (st r i).2 ∧
      slot r i n * 2 ^ (st r i).2 < (st r i).1 * 2 ^ (n + 1) + 2 ^ (st r i).2 := by
    unfold slot
    generalize (st r i).1 * 2 ^ (n + 1) = q at *
    generalize 2 ^ (st r i).2 = D at *
    have a := Nat.div_mul_le_self (q + D - 1) D
    have b := Nat.lt_div_mul_add (a := q + D - 1) hD
    generalize (q + D - 1) / D * D = m at *
    constructor <;> omega
  have hDR : (0 : ℝ) < 2 ^ (st r i).2 := by positivity
  have h1a : ((st r i).1 : ℝ) * 2 ^ (n + 1) ≤ slot r i n * 2 ^ (st r i).2 := by
    exact_mod_cast h1.1
  have h1b : (slot r i n : ℝ) * 2 ^ (st r i).2 <
      ((st r i).1 : ℝ) * 2 ^ (n + 1) + 2 ^ (st r i).2 := by
    exact_mod_cast h1.2
  rw [hst] at h1a h1b
  have h2 : (2⁻¹ : ℝ) ^ n * 2 ^ (n + 1) = 2 := by
    rw [pow_succ, ← mul_assoc, ← mul_pow]; norm_num
  constructor
  · refine le_of_mul_le_mul_right ?_ hDR
    linarith
  · have h3 : (slot r i n : ℝ) < cum r i * 2 ^ (n + 1) + 1 := by
      refine lt_of_mul_lt_mul_right ?_ hDR.le
      linarith
    linarith

/-- **Distinct requests own incomparable strings.** -/
theorem own_prefix {r : ℕ → Option (ℕ × ℕ)} {i i' : ℕ} {w z : List Bool} {x x' : ℕ}
    (h : Own r i w x) (h' : Own r i' (w ++ z) x') : i = i' := by
  obtain ⟨n, hr, hl, hv⟩ := h
  obtain ⟨n', hr', hl', hv'⟩ := h'
  obtain ⟨b1, b2⟩ := slot_bounds r i n
  obtain ⟨b1', b2'⟩ := slot_bounds r i' n'
  rw [← hv] at b1 b2
  rw [← hv', val_append] at b1' b2'
  push_cast at b1' b2'
  have hn : n' + 1 = n + 1 + z.length := by
    rw [List.length_append, hl] at hl'
    omega
  have hZ : (0 : ℝ) < 2 ^ z.length := by positivity
  have hP : (2 : ℝ) ^ (n' + 1) = 2 ^ (n + 1) * 2 ^ z.length := by rw [hn, pow_add]
  have hu : (val z : ℝ) + 1 ≤ 2 ^ z.length := by exact_mod_cast val_lt z
  have hu0 : (0 : ℝ) ≤ val z := Nat.cast_nonneg _
  -- both intervals, scaled by `2 ^ (n' + 1)`, contain the longer slot
  have A : cum r i * 2 ^ (n' + 1) ≤ (val w : ℝ) * 2 ^ z.length + val z := by
    have := mul_le_mul_of_nonneg_right b1 hZ.le
    rw [hP]
    linarith
  have B : (val w : ℝ) * 2 ^ z.length + val z + 1 < (cum r i + 2⁻¹ ^ n) * 2 ^ (n' + 1) := by
    have := mul_lt_mul_of_pos_right b2 hZ
    rw [hP]
    linarith
  have hPpos : (0 : ℝ) < 2 ^ (n' + 1) := by positivity
  by_contra hne
  rcases lt_or_gt_of_ne hne with hlt | hlt
  · have hc : cum r i + 2⁻¹ ^ n ≤ cum r i' := by
      have := cum_mono r (Nat.succ_le_of_lt hlt)
      rwa [cum_succ, hr] at this
    have := mul_le_mul_of_nonneg_right hc hPpos.le
    linarith
  · have hc : cum r i' + 2⁻¹ ^ n' ≤ cum r i := by
      have := cum_mono r (Nat.succ_le_of_lt hlt)
      rwa [cum_succ, hr'] at this
    have := mul_le_mul_of_nonneg_right hc hPpos.le
    linarith

/-- The decoder has a **prefix-free domain**. -/
theorem machine_prefixFree (r : ℕ → Option (ℕ × ℕ)) {w z : List Bool}
    (h : (machine r w).Dom) (h' : (machine r (w ++ z)).Dom) : z = [] := by
  obtain ⟨i, x, hx⟩ := Nat.rfindOpt_dom.1 h
  obtain ⟨i', x', hx'⟩ := Nat.rfindOpt_dom.1 h'
  rw [Option.mem_def, hit_eq_some] at hx hx'
  obtain rfl := own_prefix hx hx'
  obtain ⟨n, hr, hl, -⟩ := hx
  obtain ⟨n', hr', hl', -⟩ := hx'
  rw [hr] at hr'
  obtain rfl : n = n' := congrArg Prod.snd (Option.some.inj hr')
  rw [List.length_append, hl] at hl'
  exact List.eq_nil_of_length_eq_zero (by omega)

/-- Every program of the decoder serves a request. -/
theorem machine_sound (r : ℕ → Option (ℕ × ℕ)) {w : List Bool} {x : ℕ} (h : x ∈ machine r w) :
    ∃ i n, r i = some (x, n) ∧ w.length = n + 1 := by
  obtain ⟨i, hi⟩ := Nat.rfindOpt_spec h
  rw [Option.mem_def, hit_eq_some] at hi
  obtain ⟨n, hr, hl, -⟩ := hi
  exact ⟨i, n, hr, hl⟩

/-- **Every request is served**, one bit over its weight, as long as the weights sum to at
most one. -/
theorem exists_program {r : ℕ → Option (ℕ × ℕ)} (hsum : ∀ i, cum r i ≤ 1) {i x n : ℕ}
    (h : r i = some (x, n)) : ∃ w : List Bool, w.length = n + 1 ∧ x ∈ machine r w := by
  obtain ⟨-, b2⟩ := slot_bounds r i n
  have hlt : slot r i n < 2 ^ (n + 1) := by
    have h1 := hsum (i + 1)
    rw [cum_succ, h] at h1
    have h2 : (slot r i n : ℝ) < 2 ^ (n + 1) := by
      have hP : (0 : ℝ) < 2 ^ (n + 1) := by positivity
      have := mul_le_mul_of_nonneg_right h1 hP.le
      simp only [wR] at this
      linarith
    exact_mod_cast h2
  obtain ⟨w, hw, hv⟩ := exists_val (n + 1) _ hlt
  refine ⟨w, hw, ?_⟩
  have hown : Own r i w x := ⟨n, h, hw, hv⟩
  have hdom : (machine r w).Dom := Nat.rfindOpt_dom.2 ⟨i, x, hit_eq_some.2 hown⟩
  obtain ⟨i', hi'⟩ := Nat.rfindOpt_spec (Part.get_mem hdom)
  rw [Option.mem_def, hit_eq_some] at hi'
  have hii : i = i' := own_prefix (z := []) hown (by simpa using hi')
  subst hii
  obtain ⟨n', hr', -, -⟩ := hi'
  rw [h] at hr'
  have hx : x = (machine r w).get hdom := congrArg Prod.fst (Option.some.inj hr')
  rw [hx]
  exact Part.get_mem hdom

/-! ### The packaged statement, with weights in `ℝ≥0∞` -/

open scoped ENNReal

/-- The weight `2 ^ (-n)` of a request, in `ℝ≥0∞`. -/
noncomputable def wE (o : Option (ℕ × ℕ)) : ℝ≥0∞ :=
  Option.casesOn (motive := fun _ => ℝ≥0∞) o 0 fun xn => (2⁻¹ : ℝ≥0∞) ^ xn.2

theorem wE_ne_top (o : Option (ℕ × ℕ)) : wE o ≠ ⊤ := by
  rcases o with _ | xn
  · exact ENNReal.zero_ne_top
  · exact ENNReal.pow_ne_top (by simp)

theorem toReal_wE (o : Option (ℕ × ℕ)) : (wE o).toReal = wR o := by
  rcases o with _ | xn
  · simp [wE, wR]
  · simp [wE, wR]

theorem cum_le_one_of_tsum {r : ℕ → Option (ℕ × ℕ)} (h : ∑' i, wE (r i) ≤ 1) (i : ℕ) :
    cum r i ≤ 1 := by
  have h1 : ∑ j ∈ Finset.range i, wE (r j) ≤ 1 := (sum_le_tsum _).trans h
  have h2 := ENNReal.toReal_mono ENNReal.one_ne_top h1
  rw [ENNReal.toReal_sum fun j _ => wE_ne_top _] at h2
  simpa [cum, toReal_wE] using h2

/-- **Kraft–Chaitin theorem** (with one bit of slack). For a primitive recursive list of
requests whose weights sum to at most one there is a partial recursive decoder with
prefix-free domain that gives every request `(x, n)` a program of length `n + 1`, and has no
other programs. -/
theorem exists_machine (r : ℕ → Option (ℕ × ℕ)) (hr : Primrec r) (hsum : ∑' i, wE (r i) ≤ 1) :
    ∃ M : List Bool →. ℕ, Partrec M ∧
      (∀ w z : List Bool, (M w).Dom → (M (w ++ z)).Dom → z = []) ∧
      (∀ i x n, r i = some (x, n) → ∃ w : List Bool, w.length = n + 1 ∧ x ∈ M w) ∧
      ∀ w x, x ∈ M w → ∃ i n, r i = some (x, n) ∧ w.length = n + 1 :=
  ⟨machine r, machine_partrec hr, fun _ _ => machine_prefixFree r,
    fun _ _ _ h => exists_program (cum_le_one_of_tsum hsum) h, fun _ _ => machine_sound r⟩

end KraftChaitin

end Complexity
