import Complexity.Symmetry
import Complexity.Semicomputable

/-!
# Complexity cannot be guessed: `K(K(x) | x)` is unbounded

Symmetry of information (`Symmetry.symmetry_of_information`) conditions on
`x* = ⟨x, K(x)⟩`, not on `x`. This file shows that the difference is real.

**No bounded list of guesses contains the complexity** (`exists_wrong_guess`). Let `a` be a
computable injective sequence, and let `ℓ` be a computable table that shows, for each `n`,
at most `N` different values over all stages. Then some `n` has `K(a n)` missing from its
list. For `N = 1` this is the non-computability of `K` (`K_U_not_computable`).

The proof is an induction on `N` that strikes one guess per round. Suppose every list
contains the complexity. Complexity is unbounded along `a`, so the lists show arbitrarily
large values. Search for a sequence of positions `n₀ < n₁ < …` and guesses `vᵢ` in the list
of `nᵢ` with `vᵢ ≥ 2 i + 2`, and ask for a description of `a nᵢ` of length `vᵢ - 1 - i`. The
requested weights sum to at most `∑ 2 ^ -(i + 1)`, so by minimality of `K_U`
(`Upper.K_U_le_of_computable`) there is a constant `c` with
`K(a nᵢ) ≤ vᵢ - 1 - i + c`. From `i = c` on this is below `vᵢ`: the guess `vᵢ` is wrong.
Strike it. The subsequence from `c` on has lists with at most `N - 1` values that still
contain the complexity, which the induction hypothesis forbids.

**Consequences.**

* `condK_K_unbounded` – `K(K(x) | x)` is unbounded: the outputs of the programs of length
  at most `c`, run with `x` as the condition, are a list of at most `2 ^ (c + 1)` guesses.
  This is the qualitative form of a theorem of Gács, who proved a logarithmic lower bound;
  the logarithmic bound is not formalized here.
* `condK_star_add_lt` – for every `c` there are `x, y` with `K(y | x*) + c < K(y | x)`.
* `not_symmetry_bare` – symmetry of information fails, by more than any constant, when the
  condition `x*` is replaced by `x`.
-/

namespace Complexity

namespace Guessing

open Nat.Partrec (Code)
open Nat.Partrec.Code (evaln)
open Encodable
open Kolmogorov (sys)
open PrefixMachine Conditional Symmetry Upper
open Prefix (wt)
open scoped ENNReal

/-! ### The search for large guesses -/

/-- Candidate `m = ⟨offset, stage⟩`, at step `i` and from position `p`, shows a guess of at
least `2 i + 2`. -/
def Big (ℓ : ℕ → ℕ → Option ℕ) (i p m : ℕ) : Prop :=
  2 * i + 2 ≤ (ℓ (p + m.unpair.1) m.unpair.2).getD 0

instance (ℓ : ℕ → ℕ → Option ℕ) (i p : ℕ) : DecidablePred (Big ℓ i p) :=
  fun _ => Nat.decLe _ _

theorem big_computable {ℓ : ℕ → ℕ → Option ℕ} (hℓ : Computable₂ ℓ) :
    Computable fun q : (ℕ × ℕ) × ℕ => decide (Big ℓ q.1.1 q.1.2 q.2) := by
  have hv : Computable fun q : (ℕ × ℕ) × ℕ =>
      (ℓ (q.1.2 + q.2.unpair.1) q.2.unpair.2).getD 0 :=
    Computable.option_getD
      (hℓ.comp
        (Primrec.nat_add.to_comp.comp (Computable.snd.comp Computable.fst)
          (Computable.fst.comp (Computable.unpair.comp Computable.snd)))
        (Computable.snd.comp (Computable.unpair.comp Computable.snd)))
      (Computable.const 0)
  have ht : Computable fun q : (ℕ × ℕ) × ℕ => 2 * q.1.1 + 2 :=
    (Primrec.nat_add.comp
      (Primrec.nat_mul.comp (Primrec.const 2) (Primrec.fst.comp Primrec.fst))
      (Primrec.const 2)).to_comp
  exact Primrec.nat_le.decide.to_comp.comp ht hv

section Search

variable {ℓ : ℕ → ℕ → Option ℕ} (H : ∀ i p, ∃ m, Big ℓ i p m)

/-- The first candidate that shows a large guess. -/
def pick (i p : ℕ) : ℕ := Nat.find (H i p)

/-- The position from which step `i` searches: one past the position used at step `i - 1`. -/
def pos : ℕ → ℕ
  | 0 => 0
  | i + 1 => pos i + (pick H i (pos i)).unpair.1 + 1

/-- The position chosen at step `i`. -/
def idx (i : ℕ) : ℕ := pos H i + (pick H i (pos H i)).unpair.1

/-- The guess found at step `i`. -/
def val (i : ℕ) : ℕ := (ℓ (idx H i) (pick H i (pos H i)).unpair.2).getD 0

theorem val_ge (i : ℕ) : 2 * i + 2 ≤ val H i := Nat.find_spec (H i (pos H i))

theorem val_mem (i : ℕ) : ∃ s, ℓ (idx H i) s = some (val H i) := by
  refine ⟨(pick H i (pos H i)).unpair.2, ?_⟩
  have h := val_ge H i
  unfold val at h ⊢
  cases hℓ : ℓ (idx H i) (pick H i (pos H i)).unpair.2 with
  | none =>
    rw [hℓ] at h
    simp at h
  | some v => simp

theorem idx_strictMono : StrictMono (idx H) :=
  strictMono_nat_of_lt_succ fun i =>
    lt_of_lt_of_le (Nat.lt_succ_self (idx H i)) (Nat.le_add_right (pos H (i + 1)) _)

theorem pick_computable (hℓ : Computable₂ ℓ) : Computable₂ (pick H) := by
  have h : Partrec fun q : ℕ × ℕ =>
      Nat.rfind fun m => (Part.some (decide (Big ℓ q.1 q.2 m)) : Part Bool) :=
    Partrec.rfind (big_computable hℓ).partrec
  show Partrec fun q : ℕ × ℕ => (Part.some (pick H q.1 q.2) : Part ℕ)
  refine h.of_eq fun q => Part.eq_some_iff.2 (Nat.mem_rfind.2 ⟨?_, fun {m} hm => ?_⟩)
  · exact Part.mem_some_iff.2 (decide_eq_true (Nat.find_spec (H q.1 q.2))).symm
  · exact Part.mem_some_iff.2 (decide_eq_false (Nat.find_min (H q.1 q.2) hm)).symm

theorem pos_computable (hℓ : Computable₂ ℓ) : Computable (pos H) := by
  have h := Computable.nat_rec (f := fun n : ℕ => n) (g := fun _ : ℕ => 0)
    (h := fun (_ : ℕ) (p : ℕ × ℕ) => p.2 + (pick H p.1 p.2).unpair.1 + 1)
    Computable.id (Computable.const 0)
    (Primrec.nat_add.to_comp.comp
      (Primrec.nat_add.to_comp.comp (Computable.snd.comp Computable.snd)
        (Computable.fst.comp (Computable.unpair.comp
          ((pick_computable H hℓ).comp (Computable.fst.comp Computable.snd)
            (Computable.snd.comp Computable.snd)))))
      (Computable.const 1)).to₂
  refine h.of_eq fun n => ?_
  induction n with
  | zero => rfl
  | succ t ih => rw [pos, ← ih]

theorem pick_pos_computable (hℓ : Computable₂ ℓ) :
    Computable fun i => pick H i (pos H i) :=
  (pick_computable H hℓ).comp Computable.id (pos_computable H hℓ)

theorem idx_computable (hℓ : Computable₂ ℓ) : Computable (idx H) :=
  Primrec.nat_add.to_comp.comp (pos_computable H hℓ)
    (Computable.fst.comp (Computable.unpair.comp (pick_pos_computable H hℓ)))

theorem val_computable (hℓ : Computable₂ ℓ) : Computable (val H) :=
  Computable.option_getD
    (hℓ.comp (idx_computable H hℓ)
      (Computable.snd.comp (Computable.unpair.comp (pick_pos_computable H hℓ))))
    (Computable.const 0)

/-! ### The requests -/

/-- Stage `i` asks for a description of `a (idx i)` of length `val i - 1 - i`. -/
def greq (a : ℕ → ℕ) (x i : ℕ) : Option ℕ :=
  if a (idx H i) = x then some (val H i - 1 - i) else none

theorem greq_computable {a : ℕ → ℕ} (ha : Computable a) (hℓ : Computable₂ ℓ) :
    Computable₂ (greq H a) :=
  (Computable.cond
    (Primrec.eq.decide.to_comp.comp (ha.comp ((idx_computable H hℓ).comp Computable.snd))
      Computable.fst)
    (Computable.option_some.comp
      (Primrec.nat_sub.to_comp.comp
        (Primrec.nat_sub.to_comp.comp ((val_computable H hℓ).comp Computable.snd)
          (Computable.const 1))
        Computable.snd))
    (Computable.const none)).of_eq fun q => by
      by_cases h : a (idx H q.2) = q.1 <;> simp [greq, h]

/-- The requested weights sum to at most one: stage `i` asks for at most `2 ^ -(i + 1)`. -/
theorem tsum_greq_le (a : ℕ → ℕ) : ∑' x, wt (lim (greq H a) x) ≤ 1 := by
  have hstage : ∀ i, ∑' x, (greq H a x i).elim 0 (fun n => wt n) ≤ (2⁻¹ : ℝ≥0∞) ^ (i + 1) := by
    intro i
    rw [tsum_eq_single (a (idx H i)) fun x hx => by simp [greq, hx.symm]]
    have h := val_ge H i
    simp only [greq, ite_true, Option.elim, Prefix.wt_coe]
    exact pow_le_pow_right_of_le_one' (by simp) (by omega)
  calc ∑' x, wt (lim (greq H a) x)
      ≤ ∑' x, ∑' i, (greq H a x i).elim 0 (fun n => wt n) :=
        tsum_le_tsum fun x => wt_lim_le _ x
    _ = ∑' i, ∑' x, (greq H a x i).elim 0 (fun n => wt n) := tsum_comm
    _ ≤ ∑' i : ℕ, (2⁻¹ : ℝ≥0∞) ^ (i + 1) := tsum_le_tsum hstage
    _ = 1 := by
        simp_rw [pow_succ]
        rw [ENNReal.tsum_mul_right, ENNReal.tsum_geometric, ENNReal.one_sub_inv_two, inv_inv,
          ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top]

/-- From some stage on, every guess found by the search is wrong: the complexity is below
it. -/
theorem exists_stage {a : ℕ → ℕ} (ha : Computable a) (hℓ : Computable₂ ℓ) :
    ∃ c : ℕ, ∀ i, c ≤ i → Kolmogorov.K U (a (idx H i)) < val H i := by
  obtain ⟨c, hc⟩ := K_U_le_of_computable (greq_computable H ha hℓ)
    (ne_top_of_le_ne_top ENNReal.one_ne_top (tsum_greq_le H a))
  refine ⟨c, fun i hi => ?_⟩
  have h1 : lim (greq H a) (a (idx H i)) ≤ ((val H i - 1 - i : ℕ) : ℕ∞) :=
    lim_le (t := i) (by simp [greq])
  have h2 := val_ge H i
  calc Kolmogorov.K U (a (idx H i)) ≤ lim (greq H a) (a (idx H i)) + c := hc _
    _ ≤ ((val H i - 1 - i : ℕ) : ℕ∞) + c := by gcongr
    _ = ((val H i - 1 - i + c : ℕ) : ℕ∞) := by push_cast; rfl
    _ < val H i := by exact_mod_cast (by omega : val H i - 1 - i + c < val H i)

end Search

/-! ### Striking a guess -/

/-- The lists along the positions `n`, with the value `v j` struck from the `j`-th. -/
def strike (ℓ : ℕ → ℕ → Option ℕ) (n v : ℕ → ℕ) (j s : ℕ) : Option ℕ :=
  if ℓ (n j) s = some (v j) then none else ℓ (n j) s

theorem strike_computable {ℓ : ℕ → ℕ → Option ℕ} {n v : ℕ → ℕ} (hℓ : Computable₂ ℓ)
    (hn : Computable n) (hv : Computable v) : Computable₂ (strike ℓ n v) := by
  have e : Computable fun q : ℕ × ℕ => ℓ (n q.1) q.2 :=
    hℓ.comp (hn.comp Computable.fst) Computable.snd
  exact (Computable.cond
    (Primrec.eq.decide.to_comp.comp e (Computable.option_some.comp (hv.comp Computable.fst)))
    (Computable.const none) e).of_eq fun q => by
      by_cases h : ℓ (n q.1) q.2 = some (v q.1) <;> simp [strike, h]

theorem strike_eq {ℓ : ℕ → ℕ → Option ℕ} {n v : ℕ → ℕ} {j s w : ℕ}
    (h : ℓ (n j) s = some w) (hw : w ≠ v j) : strike ℓ n v j s = some w := by
  unfold strike
  rw [h]
  simp [hw]

/-- Striking a value that is on the list shortens the list. -/
theorem encard_strike_le {ℓ : ℕ → ℕ → Option ℕ} {n v : ℕ → ℕ} {j N : ℕ}
    (hN : {w | ∃ s, ℓ (n j) s = some w}.encard ≤ ((N + 1 : ℕ) : ℕ∞))
    (hmem : ∃ s, ℓ (n j) s = some (v j)) :
    {w | ∃ s, strike ℓ n v j s = some w}.encard ≤ N := by
  have hsub : {w | ∃ s, strike ℓ n v j s = some w} ⊆
      {w | ∃ s, ℓ (n j) s = some w} \ {v j} := by
    rintro w ⟨s, hs⟩
    by_cases h : ℓ (n j) s = some (v j)
    · simp [strike, h] at hs
    · simp only [strike, h, ite_false] at hs
      exact ⟨⟨s, hs⟩, fun hv => h (hv ▸ hs)⟩
  have h1 := Set.encard_sdiff_singleton_add_one (s := {w | ∃ s, ℓ (n j) s = some w}) hmem
  rw [← h1] at hN
  push_cast at hN
  exact (Set.encard_le_encard hsub).trans ((ENat.add_le_add_iff_right ENat.one_ne_top).1 hN)

/-! ### No bounded list of guesses contains the complexity -/

/-- **No bounded list of guesses contains the complexity.** Along a computable injective
sequence `a`, if a computable table `ℓ` shows at most `N` different values for each `n`,
then for some `n` none of them is `K(a n)`. -/
theorem exists_wrong_guess (N : ℕ) :
    ∀ {a : ℕ → ℕ} {ℓ : ℕ → ℕ → Option ℕ}, Computable a → Function.Injective a →
      Computable₂ ℓ → (∀ n, {v | ∃ s, ℓ n s = some v}.encard ≤ N) →
      ∃ n, ∀ s v, ℓ n s = some v → (v : ℕ∞) ≠ Kolmogorov.K U (a n) := by
  induction N with
  | zero =>
    intro a ℓ _ _ _ hN
    refine ⟨0, fun s v hv => ?_⟩
    have h0 := hN 0
    rw [Nat.cast_zero, nonpos_iff_eq_zero, Set.encard_eq_zero] at h0
    have hmem : v ∈ {v | ∃ s, ℓ 0 s = some v} := ⟨s, hv⟩
    rw [h0] at hmem
    exact absurd hmem (Set.notMem_empty v)
  | succ N ih =>
    intro a ℓ ha hinj hℓ hN
    by_contra hall
    push Not at hall
    -- every position range contains a number of high complexity, hence a large guess
    have H : ∀ i p, ∃ m, Big ℓ i p m := fun i p => by
      classical
      obtain ⟨x, hx, hK⟩ := (Kolmogorov.sys_isBinary U).exists_incompressible
        (Kolmogorov.sys_functional U) (2 * i + 2)
        ((Finset.range (2 ^ (2 * i + 2))).image fun δ => a (p + δ))
        (by
          rw [Finset.card_image_of_injective _ fun δ δ' h => by simpa using hinj h]
          simp)
      obtain ⟨δ, -, rfl⟩ := Finset.mem_image.1 hx
      obtain ⟨s, v, hv, hvK⟩ := hall (p + δ)
      have hK' : ((2 * i + 2 : ℕ) : ℕ∞) ≤ Kolmogorov.K U (a (p + δ)) := hK
      rw [← hvK] at hK'
      have hle : 2 * i + 2 ≤ v := by exact_mod_cast hK'
      refine ⟨Nat.pair δ s, ?_⟩
      simp [Big, hv, hle]
    obtain ⟨c, hc⟩ := exists_stage H ha hℓ
    have hsh : Computable fun j : ℕ => c + j :=
      Primrec.nat_add.to_comp.comp (Computable.const c) Computable.id
    obtain ⟨j, hj⟩ := ih (a := fun j => a (idx H (c + j)))
      (ℓ := strike ℓ (fun j => idx H (c + j)) fun j => val H (c + j))
      (ha.comp ((idx_computable H hℓ).comp hsh))
      (fun j j' h => by
        have h' := (idx_strictMono H).injective (hinj h)
        omega)
      (strike_computable hℓ ((idx_computable H hℓ).comp hsh) ((val_computable H hℓ).comp hsh))
      (fun j => encard_strike_le (hN _) (val_mem H (c + j)))
    obtain ⟨s, v, hv, hvK⟩ := hall (idx H (c + j))
    have hlt := hc (c + j) (Nat.le_add_right c j)
    have hne : v ≠ val H (c + j) := by
      rintro rfl
      rw [hvK] at hlt
      exact lt_irrefl _ hlt
    exact hj s v (strike_eq (n := fun j => idx H (c + j)) (v := fun j => val H (c + j)) hv hne) hvK

/-- **Prefix complexity is not computable.** -/
theorem K_U_not_computable :
    ¬∃ f : ℕ → ℕ, Computable f ∧ ∀ x, (f x : ℕ∞) = Kolmogorov.K U x := by
  rintro ⟨f, hf, hfK⟩
  obtain ⟨n, hn⟩ := exists_wrong_guess 1 (a := id) (ℓ := fun n _ => some (f n))
    Computable.id Function.injective_id
    (Computable.option_some.comp (hf.comp Computable.fst)).to₂
    (fun n => by
      have e : {v | ∃ _ : ℕ, some (f n) = some v} = {f n} := by
        ext v
        simp [eq_comm]
      rw [e, Set.encard_singleton]
      rfl)
  exact hn 0 (f n) rfl (hfK n)

/-! ### `K(K(x) | x)` is unbounded -/

/-- Stage `⟨w, t⟩` of the list of guesses for `x`: the output, if it has appeared within
`t` steps, of the conditional machine `e` given `x` on the input numbered `w`, provided
that input has length at most `c`. -/
def guesses (e : Code) (c x m : ℕ) : Option ℕ :=
  (decode (α := List Bool) m.unpair.1).bind fun w =>
    if w.length ≤ c then evaln m.unpair.2 e (encode (x, w)) else none

theorem guesses_computable (e : Code) (c : ℕ) : Computable₂ (guesses e c) :=
  (Primrec.option_bind
    (Primrec.decode.comp (Primrec.fst.comp (Primrec.unpair.comp Primrec.snd)))
    (Primrec.ite
      (Primrec.nat_le.comp (Primrec.list_length.comp Primrec.snd) (Primrec.const c))
      (Nat.Partrec.Code.primrec_evaln.comp
        (((Primrec.snd.comp (Primrec.unpair.comp (Primrec.snd.comp Primrec.fst))).pair
            (Primrec.const e)).pair
          (Primrec.encode.comp ((Primrec.fst.comp Primrec.fst).pair Primrec.snd))))
      (Primrec.const none)).to₂).to_comp.to₂

/-- Every guess is the output of a short program. -/
theorem guesses_sound {e : Code} {c x m v : ℕ} (h : guesses e c x m = some v) :
    ∃ w : List Bool, w.length ≤ c ∧ v ∈ e.eval (encode (x, w)) := by
  obtain ⟨w, -, hw⟩ := Option.bind_eq_some_iff.1 h
  split_ifs at hw with hlen
  exact ⟨w, hlen, Nat.Partrec.Code.evaln_sound hw⟩

/-- The output of every short program is a guess. -/
theorem guesses_complete {e : Code} {c x v : ℕ} {w : List Bool} (hlen : w.length ≤ c)
    (h : v ∈ e.eval (encode (x, w))) : ∃ m, guesses e c x m = some v := by
  obtain ⟨t, ht⟩ := Nat.Partrec.Code.evaln_complete.1 h
  have ht' : evaln t e (Nat.pair x (encode w)) = some v := ht
  exact ⟨Nat.pair (encode w) t, by simp [guesses, hlen, ht']⟩

/-- There are no more guesses than short programs. -/
theorem encard_guesses_le (e : Code) (c x : ℕ) :
    {v | ∃ m, guesses e c x m = some v}.encard ≤
      ((List.finite_length_le Bool c).toFinset.card : ℕ∞) := by
  classical
  rw [← Set.Finite.encard_eq_coe_toFinset_card]
  have hex : ∀ v, v ∈ {v | ∃ m, guesses e c x m = some v} →
      ∃ w : List Bool, w.length ≤ c ∧ v ∈ e.eval (encode (x, w)) :=
    fun v ⟨_, hm⟩ => guesses_sound hm
  refine Set.encard_le_encard_of_injOn
    (f := fun v => if h : ∃ w : List Bool, w.length ≤ c ∧ v ∈ e.eval (encode (x, w))
      then h.choose else []) (fun v hv => ?_) (fun v hv v' hv' hvv' => ?_)
  · show (dite _ _ _ : List Bool).length ≤ c
    simp only [hex v hv, ↓reduceDIte]
    exact (hex v hv).choose_spec.1
  · simp only [hex v hv, hex v' hv', ↓reduceDIte] at hvv'
    have h1 := (hex v hv).choose_spec.2
    have h2 := (hex v' hv').choose_spec.2
    rw [hvv'] at h1
    exact Part.mem_unique h1 h2

/-- **`K(K(x) | x)` is unbounded** (the qualitative form of a theorem of Gács): no constant
number of bits of advice turns `x` into its own complexity. -/
theorem condK_K_unbounded (c : ℕ) :
    ∃ x, (c : ℕ∞) < condK x (Kolmogorov.K U x).toNat := by
  by_contra hcon
  push Not at hcon
  obtain ⟨e, he⟩ := exists_code₂ condU_partrec
  obtain ⟨n, hn⟩ := exists_wrong_guess (List.finite_length_le Bool c).toFinset.card
    (a := id) (ℓ := guesses e c) Computable.id Function.injective_id (guesses_computable e c)
    (encard_guesses_le e c)
  have hK : condK n (Kolmogorov.K U n).toNat ≤ c := hcon n
  obtain ⟨w, hw, hwc⟩ := (sys (condU n)).exists_cost_eq_K
    (ne_top_of_le_ne_top (ENat.natCast_ne_top c) hK)
  have hlen : w.length ≤ c := by
    have h : ((w.length : ℕ) : ℕ∞) ≤ c := hwc.trans_le hK
    exact_mod_cast h
  have hmem : (Kolmogorov.K U n).toNat ∈ e.eval (encode (n, w)) := by
    rw [he]
    exact hw
  obtain ⟨m, hm⟩ := guesses_complete hlen hmem
  exact hn m _ hm (ENat.natCast_toNat (K_U_lt_top n).ne)

/-! ### The condition `x*` cannot be replaced by `x` -/

/-- `x*` costs no more than `x`: a shortest program for `x` also tells its own length. -/
theorem K_star_le : ∃ c : ℕ, ∀ x, Kolmogorov.K U (Symmetry.star x) ≤ Kolmogorov.K U x + c := by
  obtain ⟨c1, h1⟩ := K_pair_le_add_condK_star
  obtain ⟨c2, h2⟩ := condK_map_le (f := fun a : ℕ => a.unpair.2)
    (Computable.snd.comp Computable.unpair)
  refine ⟨c2 + c1, fun x => ?_⟩
  have h3 : condK (Symmetry.star x) (Kolmogorov.K U x).toNat ≤ c2 := by
    have h := h2 (Symmetry.star x)
    simpa [Symmetry.star] using h
  calc Kolmogorov.K U (Symmetry.star x)
      ≤ Kolmogorov.K U x + condK (Symmetry.star x) (Kolmogorov.K U x).toNat + c1 := h1 x _
    _ ≤ Kolmogorov.K U x + c2 + c1 := by gcongr
    _ = Kolmogorov.K U x + ((c2 + c1 : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]

/-- **Conditioning on `x` is strictly weaker than conditioning on `x*`**: the gap
`K(y | x) - K(y | x*)` exceeds every constant. -/
theorem condK_star_add_lt (c : ℕ) : ∃ x y, condK (Symmetry.star x) y + c < condK x y := by
  obtain ⟨c2, h2⟩ := condK_map_le (f := fun a : ℕ => a.unpair.2)
    (Computable.snd.comp Computable.unpair)
  obtain ⟨x, hx⟩ := condK_K_unbounded (c2 + c)
  refine ⟨x, (Kolmogorov.K U x).toNat, lt_of_le_of_lt ?_ hx⟩
  have h3 : condK (Symmetry.star x) (Kolmogorov.K U x).toNat ≤ c2 := by
    have h := h2 (Symmetry.star x)
    simpa [Symmetry.star] using h
  push_cast
  gcongr

/-- **Symmetry of information fails for the bare condition**: no constant `c` gives
`K(x) + K(y | x) ≤ K(x, y) + c` for all `x, y`. With `x*` in place of `x` it holds
(`Symmetry.symmetry_of_information`). -/
theorem not_symmetry_bare :
    ¬∃ c : ℕ, ∀ x y, Kolmogorov.K U x + condK x y ≤ Kolmogorov.K U (Nat.pair x y) + c := by
  rintro ⟨c, hc⟩
  obtain ⟨c1, h1⟩ := K_star_le
  obtain ⟨x, hx⟩ := condK_K_unbounded (c1 + c)
  have h : Kolmogorov.K U x + condK x (Kolmogorov.K U x).toNat ≤
      Kolmogorov.K U x + ((c1 + c : ℕ) : ℕ∞) :=
    calc Kolmogorov.K U x + condK x (Kolmogorov.K U x).toNat
        ≤ Kolmogorov.K U (Symmetry.star x) + c := hc x _
      _ ≤ Kolmogorov.K U x + c1 + c := by gcongr; exact h1 x
      _ = Kolmogorov.K U x + ((c1 + c : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]
  exact absurd ((ENat.add_le_add_iff_left (K_U_lt_top x).ne).1 h) (not_le.2 hx)

end Guessing

end Complexity
