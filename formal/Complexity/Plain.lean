import Complexity.Limits
import Complexity.Conditional

/-!
# Just outside the laws: three counterexamples that were only asserted

The ladder of restrictions claims, for each law, a stage where it holds and a failure one
stage earlier. Three of the failures were stated without proof. They are proved here.

* `exists_ambiguous_binary` – **counting needs unambiguous descriptions.** A binary
  description system (cost = length) in which every object has complexity `0`: one
  description stands for everything. The counting law (`card_le_of_K_lt`) assumes that a
  description realizes at most one object, and this is why.
* `P_plain_eq_top` – **the coding theorem cannot hold for the plain machine.** For the
  plain universal machine `Kolmogorov.U`, the algorithmic probability of every number is
  infinite: a program that ignores its input can be padded with any bits, and there are
  `2 ^ n` paddings of length `n`, each of weight `2 ^ -n`. Prefix machines exclude this.
* `not_chain_rule_plain` – **the chain rule fails for plain complexity, even its easy
  half.** With plain conditional complexity `condC` defined from a universal conditional
  machine, no constant gives `C(x, y) ≤ C(x) + C(y | x) + c`. For prefix complexity this
  half holds (`Conditional.K_pair_le_add_condK`). The failure is the missing delimiter
  between the two programs (`Limits.not_forall_K_obj_le`); the classical statement has an
  `O(log)` term instead of the constant.
-/

namespace Complexity

namespace Plain

open Nat.Partrec (Code)
open Encodable
open Kolmogorov (sys run header index payload)
open scoped ENNReal

/-! ### Counting needs unambiguous descriptions -/

/-- **One description for everything.** On any type there is a binary description system,
with cost equal to length, in which every object has complexity `0`. It is not functional:
the empty description realizes every object. So no counting law holds for binary systems
without the assumption that a description realizes at most one object. -/
theorem exists_ambiguous_binary (X : Type*) :
    ∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ ∀ x, S.K x = 0 := by
  refine ⟨⟨fun l => l.length, fun _ _ => True⟩, fun _ => rfl, fun x => ?_⟩
  refine le_antisymm ?_ bot_le
  have h := DescSystem.K_le_cost
    (S := (⟨fun l => l.length, fun _ _ => True⟩ : DescSystem (List Bool) X ℕ∞))
    (d := ([] : List Bool)) (x := x) trivial
  simpa using h

/-- In that system two objects have complexity below `1`, where a functional binary system
allows only one (there is one description of length `0`). -/
theorem exists_two_cheap :
    ∃ S : DescSystem (List Bool) Bool ℕ∞, S.IsBinary ∧ ∀ b : Bool, S.K b < 1 := by
  obtain ⟨S, hb, hK⟩ := exists_ambiguous_binary Bool
  exact ⟨S, hb, fun b => by rw [hK b]; exact zero_lt_one⟩

/-! ### The plain machine has infinite algorithmic probability -/

/-- The weights `2 ^ -|l|` of all bit strings sum to infinity: each length contributes
`1`. -/
theorem tsum_inv_pow_length : ∑' l : List Bool, (2⁻¹ : ℝ≥0∞) ^ l.length = ⊤ := by
  have h2 : (2 : ℝ≥0∞) * 2⁻¹ = 1 := ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top
  have hterm : ∀ c : (Σ n : ℕ, {l : List Bool // l.length = n}),
      (2⁻¹ : ℝ≥0∞) ^ ((Equiv.sigmaFiberEquiv (List.length : List Bool → ℕ)) c).length
        = 2⁻¹ ^ c.1 := fun c => by
    show (2⁻¹ : ℝ≥0∞) ^ c.2.1.length = 2⁻¹ ^ c.1
    rw [c.2.2]
  rw [← (Equiv.sigmaFiberEquiv (List.length : List Bool → ℕ)).tsum_eq, tsum_congr hterm,
    tsum_sigma (fun (n : ℕ) (_ : {l : List Bool // l.length = n}) => (2⁻¹ : ℝ≥0∞) ^ n)]
  have hfib : ∀ n : ℕ, ∑' _ : List.Vector Bool n, (2⁻¹ : ℝ≥0∞) ^ n = 1 := by
    intro n
    rw [tsum_fintype, Finset.sum_const, Finset.card_univ, card_vector, Fintype.card_bool,
      nsmul_eq_mul]
    push_cast
    rw [← mul_pow, h2, one_pow]
  show ∑' n : ℕ, ∑' _ : List.Vector Bool n, (2⁻¹ : ℝ≥0∞) ^ n = ⊤
  simp_rw [hfib]
  exact ENNReal.tsum_const_eq_top_of_ne_zero one_ne_zero

/-- **For the plain universal machine the algorithmic probability of every number is
infinite.** So "probability is `2 ^ -K` up to a constant" cannot even be stated for it. -/
theorem P_plain_eq_top (x : ℕ) : Prefix.P (sys Kolmogorov.U) x = ⊤ := by
  have hrun : ∀ l : List Bool,
      x ∈ Kolmogorov.U (header (encode (Code.const x)) ++ l) := fun l => by
    rw [Kolmogorov.U_header_append]
    show x ∈ (Code.const x).eval (encode l)
    rw [Nat.Partrec.Code.eval_const]
    exact Part.mem_some x
  have hinj : Function.Injective fun l : List Bool =>
      (⟨header (encode (Code.const x)) ++ l, hrun l⟩ :
        {d : List Bool // (sys Kolmogorov.U).realizes d x}) := fun l l' h =>
    List.append_cancel_left (Subtype.ext_iff.1 h)
  have hle := tsum_comp_le_tsum_of_injective hinj
    (fun d : {d : List Bool // (sys Kolmogorov.U).realizes d x} =>
      (2⁻¹ : ℝ≥0∞) ^ d.1.length)
  have hsum : ∑' l : List Bool,
      (2⁻¹ : ℝ≥0∞) ^ (header (encode (Code.const x)) ++ l).length = ⊤ := by
    simp_rw [List.length_append, pow_add]
    rw [ENNReal.tsum_mul_left, tsum_inv_pow_length]
    exact ENNReal.mul_top (by simp)
  exact top_le_iff.1 (hsum ▸ hle)

/-! ### Plain conditional complexity and the chain rule -/

/-- The **universal conditional plain machine**: read a unary program index, then run that
program on the condition and the rest of the input. No prefix-freeness is imposed. -/
def condPlain (a : ℕ) : List Bool →. ℕ := fun l =>
  (Code.curry (Denumerable.ofNat Code (index l)) a).eval (encode (payload l))

/-- `condPlain` runs every partial recursive conditional description method from a fixed
prefix. -/
theorem condPlain_simulates {ψ : ℕ → List Bool →. ℕ} (hψ : Partrec₂ ψ) :
    ∃ p : List Bool, ∀ a l, condPlain a (p ++ l) = ψ a l := by
  obtain ⟨d, hd⟩ := Conditional.exists_code₂ hψ
  refine ⟨header (encode d), fun a l => ?_⟩
  simp only [condPlain, Kolmogorov.index_header_append, Kolmogorov.payload_header_append,
    Denumerable.ofNat_encode]
  rw [Nat.Partrec.Code.eval_curry]
  exact hd a l

/-- **Plain conditional complexity** `C(y | a)`. -/
noncomputable def condC (a y : ℕ) : ℕ∞ := Kolmogorov.K (condPlain a) y

/-- Conditioning never hurts by more than a constant: `C(y | x) ≤ C(y) + c`. -/
theorem condC_le : ∃ c : ℕ, ∀ x y, condC x y ≤ Kolmogorov.K Kolmogorov.U y + c := by
  obtain ⟨p, hp⟩ := condPlain_simulates (ψ := fun _ => Kolmogorov.U)
    (Kolmogorov.U_partrec.comp Computable.snd).to₂
  exact ⟨p.length, fun x =>
    Kolmogorov.K_le_add_of_prefix (condPlain x) Kolmogorov.U p (hp x)⟩

private theorem bits_injective : Function.Injective Nat.bits := fun a a' h =>
  Nat.digits.injective 2 (by rw [Nat.digits_two_eq_bits, Nat.digits_two_eq_bits, h])

/-- **The chain rule fails for plain complexity, even its easy half**: no constant `c`
gives `C(x, y) ≤ C(x) + C(y | x) + c` for all `x, y`. -/
theorem not_chain_rule_plain :
    ¬∃ c : ℕ, ∀ x y, Kolmogorov.K Kolmogorov.U (Nat.pair x y) ≤
      Kolmogorov.K Kolmogorov.U x + condC x y + c := by
  rintro ⟨c, hc⟩
  obtain ⟨c', hc'⟩ := condC_le
  obtain ⟨k, hk⟩ := Kolmogorov.K_U_le Code.id
  have hsize : ∀ a : ℕ, Kolmogorov.K Kolmogorov.U (encode (Nat.bits a)) ≤
      ((Nat.size a + k : ℕ) : ℕ∞) := by
    intro a
    have hmem : encode (Nat.bits a) ∈ run Code.id (Nat.bits a) := by
      show _ ∈ Code.id.eval (encode (Nat.bits a))
      rw [Nat.Partrec.Code.eval_id]
      exact Part.mem_some _
    have h1 := Kolmogorov.K_le_length hmem
    rw [Nat.size_eq_bits_len] at h1
    refine (hk _).trans ?_
    push_cast
    exact add_le_add h1 le_rfl
  refine Limits.not_forall_K_obj_le (sys Kolmogorov.U) (Kolmogorov.sys_isBinary _)
    (Kolmogorov.sys_functional _)
    (fun a t => Nat.pair (encode (Nat.bits a)) (encode (Nat.bits t))) ?_
    (k + k + c' + c) ?_
  · rintro ⟨a, t⟩ ⟨a', t'⟩ h
    obtain ⟨h1, h2⟩ := Nat.pair_eq_pair.1 h
    exact Prod.ext (bits_injective (encode_injective h1)) (bits_injective (encode_injective h2))
  · intro a t
    calc Kolmogorov.K Kolmogorov.U (Nat.pair (encode (Nat.bits a)) (encode (Nat.bits t)))
        ≤ Kolmogorov.K Kolmogorov.U (encode (Nat.bits a)) +
            condC (encode (Nat.bits a)) (encode (Nat.bits t)) + c := hc _ _
      _ ≤ ((Nat.size a + k : ℕ) : ℕ∞) +
            (Kolmogorov.K Kolmogorov.U (encode (Nat.bits t)) + c') + c := by
          gcongr
          · exact hsize a
          · exact hc' _ _
      _ ≤ ((Nat.size a + k : ℕ) : ℕ∞) + (((Nat.size t + k : ℕ) : ℕ∞) + c') + c := by
          gcongr
          exact hsize t
      _ = ((Nat.size a + Nat.size t + (k + k + c' + c) : ℕ) : ℕ∞) := by
          push_cast
          ring

/-- **Plain complexity is not subadditive**: no constant `c` gives
`C(x, y) ≤ C(x) + C(y) + c` for all `x, y`. -/
theorem not_subadditive_plain :
    ¬∃ c : ℕ, ∀ x y, Kolmogorov.K Kolmogorov.U (Nat.pair x y) ≤
      Kolmogorov.K Kolmogorov.U x + Kolmogorov.K Kolmogorov.U y + c := by
  rintro ⟨c, hc⟩
  obtain ⟨k, hk⟩ := Kolmogorov.K_U_le Code.id
  have hsize : ∀ a : ℕ, Kolmogorov.K Kolmogorov.U (encode (Nat.bits a)) ≤
      ((Nat.size a + k : ℕ) : ℕ∞) := by
    intro a
    have hmem : encode (Nat.bits a) ∈ run Code.id (Nat.bits a) := by
      show _ ∈ Code.id.eval (encode (Nat.bits a))
      rw [Nat.Partrec.Code.eval_id]
      exact Part.mem_some _
    have h1 := Kolmogorov.K_le_length hmem
    rw [Nat.size_eq_bits_len] at h1
    refine (hk _).trans ?_
    push_cast
    exact add_le_add h1 le_rfl
  refine Limits.not_forall_K_obj_le (sys Kolmogorov.U) (Kolmogorov.sys_isBinary _)
    (Kolmogorov.sys_functional _)
    (fun a t => Nat.pair (encode (Nat.bits a)) (encode (Nat.bits t))) ?_ (k + k + c) ?_
  · rintro ⟨a, t⟩ ⟨a', t'⟩ h
    obtain ⟨h1, h2⟩ := Nat.pair_eq_pair.1 h
    exact Prod.ext (bits_injective (encode_injective h1)) (bits_injective (encode_injective h2))
  · intro a t
    calc Kolmogorov.K Kolmogorov.U (Nat.pair (encode (Nat.bits a)) (encode (Nat.bits t)))
        ≤ Kolmogorov.K Kolmogorov.U (encode (Nat.bits a)) +
            Kolmogorov.K Kolmogorov.U (encode (Nat.bits t)) + c := hc _ _
      _ ≤ ((Nat.size a + k : ℕ) : ℕ∞) + ((Nat.size t + k : ℕ) : ℕ∞) + c := by
          gcongr
          · exact hsize a
          · exact hsize t
      _ = ((Nat.size a + Nat.size t + (k + k + c) : ℕ) : ℕ∞) := by
          push_cast
          ring

/-- **Counting for self-delimiting systems**: in an unambiguous prefix-free binary system
at most `2 ^ n` objects have complexity at most `n`. -/
theorem card_le_two_pow_of_prefixFree {X : Type*} (S : DescSystem (List Bool) X ℕ∞)
    (hb : S.IsBinary) (hS : S.Functional) (hpf : Limits.PrefixFree S) (n : ℕ)
    (A : Finset X) (hA : ∀ x ∈ A, S.K x ≤ n) : A.card ≤ 2 ^ n := by
  have hk := Prefix.kraft S hb hS hpf
  have h1 : (A.card : ℝ≥0∞) * (2⁻¹ : ℝ≥0∞) ^ n ≤ 1 := by
    calc (A.card : ℝ≥0∞) * (2⁻¹ : ℝ≥0∞) ^ n = ∑ _x ∈ A, (2⁻¹ : ℝ≥0∞) ^ n := by
          rw [Finset.sum_const, nsmul_eq_mul]
      _ ≤ ∑ x ∈ A, Prefix.wt (S.K x) :=
          Finset.sum_le_sum fun x hx => Levin.inv_pow_le_wt (hA x hx)
      _ ≤ ∑' x, Prefix.wt (S.K x) := sum_le_tsum A
      _ ≤ 1 := hk
  have h2 : (A.card : ℝ≥0∞) ≤ 2 ^ n := by
    have e : (2 : ℝ≥0∞) ^ n * 2⁻¹ ^ n = 1 := by simpa using Levin.two_pow_mul_inv 0 n
    calc (A.card : ℝ≥0∞) = (A.card : ℝ≥0∞) * 2⁻¹ ^ n * 2 ^ n := by
          rw [mul_assoc, mul_comm ((2⁻¹ : ℝ≥0∞) ^ n), e, mul_one]
      _ ≤ 1 * 2 ^ n := by gcongr
      _ = 2 ^ n := one_mul _
  exact_mod_cast h2

/-! ### What `U` dominates is more than the computable methods -/

/-- **The class dominated by the plain universal machine is strictly larger than the
partial recursive description methods.** For any set `A` of bit strings, the method
"output `0` on `A`, diverge elsewhere" is dominated by `U`, and there are uncountably many
such methods. So `Kolmogorov.U_dominates` is one inclusion only. (An earlier README line
said "exactly"; an independent review supplied this argument.) -/
theorem dominated_not_all_partrec :
    ¬∀ V : List Bool → Part ℕ,
        DescSystem.Dominates (sys Kolmogorov.U) (sys V) → V ∈ Set.range run := by
  classical
  intro h
  let F : Set (List Bool) → List Bool → Part ℕ :=
    fun A l => if l ∈ A then Part.some 0 else Part.none
  have hdom : ∀ A, DescSystem.Dominates (sys Kolmogorov.U) (sys (F A)) := by
    intro A
    obtain ⟨c, hc⟩ := ENat.ne_top_iff_exists.1 (Kolmogorov.K_U_lt_top 0).ne
    refine ⟨c, fun x => ?_⟩
    by_cases hx : x = 0
    · subst hx
      show Kolmogorov.K Kolmogorov.U 0 ≤ _
      rw [← hc]
      exact le_add_self
    · have : (sys (F A)).K x = ⊤ := by
        apply DescSystem.K_eq_top
        intro d hd
        have hd' : x ∈ F A d := hd
        simp only [F] at hd'
        split_ifs at hd' with hmem
        · exact hx (Part.mem_some_iff.1 hd')
        · exact Part.notMem_none _ hd'
      rw [this]
      simp
  choose g hg using fun A => h (F A) (hdom A)
  have hinj : Function.Injective g := by
    intro A B hAB
    have hF : F A = F B := by rw [← hg A, ← hg B, hAB]
    ext l
    have hl := congrFun hF l
    simp only [F] at hl
    by_cases hA : l ∈ A <;> by_cases hB : l ∈ B
    · simp [hA, hB]
    · simp [hA, hB] at hl
    · simp [hA, hB] at hl
    · simp [hA, hB]
  let e : Code → List Bool := fun c => List.replicate (encode c) true
  have he : Function.Injective e := fun a b hab => by
    have := congrArg List.length hab
    simpa [e] using this
  exact Function.cantor_injective (e ∘ g) (he.comp hinj)

/-- **The programs compute exactly the partial recursive description methods.** So
`Kolmogorov.U_dominates` does say that `U` dominates every partial recursive method, which
had been asserted without this identification. -/
theorem mem_range_run_iff (φ : List Bool →. ℕ) : φ ∈ Set.range run ↔ Partrec φ := by
  constructor
  · rintro ⟨c, rfl⟩
    exact Nat.Partrec.Code.eval_part.comp (Computable.const c) Computable.encode
  · intro h
    obtain ⟨c, hc⟩ := PrefixMachine.exists_run_eq h
    exact ⟨c, hc⟩

/-! ### A self-delimiting system in which complex does not mean improbable -/

/-- The system in which the number `n` is described by the header for `n` followed by any
`n` bits: `2 ^ n` descriptions, each of length `2 n + 1`. -/
def fat : DescSystem (List Bool) ℕ ℕ∞ where
  cost l := l.length
  realizes l n := ∃ w : List Bool, w.length = n ∧ l = header n ++ w

theorem fat_isBinary : fat.IsBinary := fun _ => rfl

theorem fat_functional : fat.Functional := by
  rintro l x y ⟨w, -, rfl⟩ ⟨w', -, h⟩
  have := congrArg index h
  simpa using this

theorem fat_prefixFree : Limits.PrefixFree fat := by
  rintro p q y y' ⟨w, hw, rfl⟩ ⟨w', hw', h⟩
  rw [List.append_assoc] at h
  have hy : y = y' := by
    have := congrArg index h
    simpa using this
  subst hy
  have hpay := congrArg payload h
  simp only [Kolmogorov.payload_header_append] at hpay
  have hlen := congrArg List.length hpay
  rw [List.length_append, hw, hw'] at hlen
  exact List.eq_nil_of_length_eq_zero (by omega)

theorem fat_K (n : ℕ) : fat.K n = ((2 * n + 1 : ℕ) : ℕ∞) := by
  refine le_antisymm ?_ (fat.le_K_iff.2 fun d hd => ?_)
  · have h := DescSystem.K_le_cost (S := fat) (d := header n ++ List.replicate n false) (x := n)
      ⟨List.replicate n false, by simp, rfl⟩
    refine h.trans (le_of_eq ?_)
    show ((header n ++ List.replicate n false).length : ℕ∞) = _
    simp only [List.length_append, Kolmogorov.length_header, List.length_replicate]
    congr 1
    omega
  · obtain ⟨w, hw, rfl⟩ := hd
    show _ ≤ ((header n ++ w).length : ℕ∞)
    simp only [List.length_append, Kolmogorov.length_header, hw]
    exact_mod_cast (by omega : 2 * n + 1 ≤ n + 1 + n)

theorem fat_P (n : ℕ) : Prefix.P fat n = (2⁻¹ : ℝ≥0∞) ^ (n + 1) := by
  have hbij : Function.Bijective fun v : List.Vector Bool n =>
      (⟨header n ++ v.1, ⟨v.1, v.2, rfl⟩⟩ : {d : List Bool // fat.realizes d n}) := by
    constructor
    · intro v v' h
      exact Subtype.ext (List.append_cancel_left (Subtype.ext_iff.1 h))
    · rintro ⟨d, w, hw, rfl⟩
      exact ⟨⟨w, hw⟩, rfl⟩
  show ∑' d : {d : List Bool // fat.realizes d n}, (2⁻¹ : ℝ≥0∞) ^ d.1.length = _
  rw [← (Equiv.ofBijective _ hbij).tsum_eq]
  have hterm : ∀ v : List.Vector Bool n,
      (2⁻¹ : ℝ≥0∞) ^ ((Equiv.ofBijective _ hbij v).1.length) = 2⁻¹ ^ (n + 1 + n) := fun v => by
    show (2⁻¹ : ℝ≥0∞) ^ (header n ++ v.1).length = _
    rw [List.length_append, Kolmogorov.length_header, v.2]
  rw [tsum_congr hterm, tsum_fintype, Finset.sum_const, Finset.card_univ, card_vector,
    Fintype.card_bool, nsmul_eq_mul]
  push_cast
  exact Levin.two_pow_mul_inv' (n + 1) n

/-- **"Complex implies improbable" is not a law of self-delimiting systems.** There is one
unambiguous, prefix-free binary system in which, for every constant `c`, some object has
algorithmic probability above `2 ^ c · 2 ^ (-K)`. The number `n` has complexity `2 n + 1`
and probability `2 ^ -(n + 1)`. For the universal prefix machine the bound holds with a
constant (`Levin.P_le_two_pow_mul_wt`). `Limits.exists_complex_probable` gave a different
system for each `n`, each with only two objects, which refutes only a constant uniform
across systems; an independent review pointed that out. -/
theorem not_coding_self_delimiting :
    ∃ S : DescSystem (List Bool) ℕ ℕ∞, S.IsBinary ∧ S.Functional ∧ Limits.PrefixFree S ∧
      ∀ c : ℕ, ∃ n : ℕ, (2 : ℝ≥0∞) ^ c * Prefix.wt (S.K n) < Prefix.P S n := by
  refine ⟨fat, fat_isBinary, fat_functional, fat_prefixFree, fun c => ⟨c + 1, ?_⟩⟩
  rw [fat_K, fat_P, Prefix.wt_coe]
  have e : 2 * (c + 1) + 1 = (c + 3) + c := by omega
  rw [e, Levin.two_pow_mul_inv' (c + 3) c]
  have e2 : (2⁻¹ : ℝ≥0∞) ^ (c + 3) = 2⁻¹ ^ (c + 1 + 1) / 2 := by
    rw [div_eq_mul_inv, ← pow_succ]
  rw [e2]
  exact ENNReal.half_lt_self (pow_ne_zero _ (by simp)) (ENNReal.pow_ne_top (by simp))

end Plain

end Complexity
