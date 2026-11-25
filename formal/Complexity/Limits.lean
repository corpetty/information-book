import Complexity.Counting
import Complexity.Metric
import Complexity.Invariance
import Complexity.Thermo
import Complexity.Dynamics
import Complexity.Instances.Kolmogorov
import Complexity.Instances.CoarseGraining
import Complexity.Instances.Channel

/-!
# Limits: theorems proved *against* the theory

The output of an adversarial pass over this library. Each result here either shows that
a claim made for the framework has no content at the generality at which it was made, or
refutes a claim outright.

**The representation claims are empty.**

* `exists_system_K_eq`   – *every* function `X → Γ` is the complexity `K` of some
                           (unambiguous) description system. "Measure `M` is `K` for some
                           setting of the dials" is therefore true of every `M` and says
                           nothing;
* `dist_complete_eq`     – level 1 is exactly as general as Lawvere metrics: every `d` with
                           `d a a = 0` and the triangle inequality is a generative distance.
                           `dist_self` and `dist_triangle` are the whole content of that
                           level;
* `exists_binary_iff`    – a function is the complexity of an unambiguous binary system iff
                           every level set `{f = n}` has at most `2 ^ n` members. The
                           counting law is not merely true of such systems; it is the
                           *only* thing true of all of them;
* `dominates_iff_pointwise` – "there is a simulation with constant overhead" is equivalent
                           to "each description can be matched, object by object". Without a
                           restriction on which translations are admissible (computable,
                           physical, …) the transport and invariance laws are restatements
                           of the inequality they conclude.

**Two advertised bounds fail for the universal machine.**

* `not_iterate_bound`, `not_iterate_bound_kolmogorov`, `not_dominates_iterate` – no
                           unambiguous binary system that describes numerals at their
                           length dominates its own iterate system:
                           `K(fᵗ x) ≤ K(x) + log t + c` is *false* for plain Kolmogorov
                           complexity, so `Dynamics.exists_const_K_iterate_le` cannot be
                           applied with `S = U`;
* `not_twoPart_bound`, `not_twoPart_bound_kolmogorov`, `not_dominates_twoPart` – likewise
                           `K(x) ≤ K(π x) + ⌈log₂ W⌉ + c` is false for plain complexity.
  Both bounds add the lengths of two parts with no delimiter between them. The true
  statements carry a logarithmic correction, or use a self-delimiting description of one
  part.

**"Complex implies improbable" is not a general law.**

* `exists_complex_probable` – for every `n` there is a prefix-free unambiguous system in
                           which each object has complexity `n + 1` and algorithmic
                           probability `1/2`. The upper half of the coding theorem is a fact
                           about universal machines, not about description systems.

**A receiver budget alone produces no depth-dependent loss.**

* `relay_iterate_saturates`, `truncRelay_iterate` – retelling through a stable relay any
                           number of times loses exactly what one retelling loses.

**Where the two failed bounds do hold.**

* `exists_binary_iterate`, `exists_binary_twoPart` – if the first part has a
                           self-delimiting (prefix-free) description system, the two parts
                           glue into one unambiguous binary system at exactly the sum of
                           their lengths.
-/

namespace Complexity

namespace Limits

open DescSystem

universe u w

/-! ### 1. Every function is a complexity -/

/-- **The representation claim has no content.** Any function into a complete lattice is
the complexity of an unambiguous description system: take the objects themselves as
descriptions and the function as their cost. -/
theorem exists_system_K_eq {X : Type u} {Γ : Type w} [CompleteLattice Γ] (f : X → Γ) :
    ∃ S : DescSystem X X Γ, S.Functional ∧ ∀ x, S.K x = f x := by
  refine ⟨⟨f, fun d x => d = x⟩, fun _ _ _ hx hy => hx.symm.trans hy, fun x => ?_⟩
  show (⨅ (d : X) (_ : d = x), f d) = f x
  exact iInf_iInf_eq_left

/-! ### 2. Generative distance is exactly as general as a Lawvere metric -/

/-- `X` with exactly one arrow between any two points. -/
structure Complete (X : Type u) : Type u where
  /-- The underlying point. -/
  out : X

instance (X : Type u) : Quiver (Complete X) := ⟨fun _ _ => Unit⟩

/-- Price the unique arrow `a ⟶ b` of the complete quiver at `d a b`. -/
def completeWeight {X : Type u} {Γ : Type w} (d : X → X → Γ) : Weight (Complete X) Γ :=
  fun a b _ => d a.out b.out

/-- **Level 1 says nothing beyond `d a a = 0` and the triangle inequality.** Every such `d`
is the generative distance of a weighted quiver (the complete one, priced by `d`). -/
theorem dist_complete_eq {X : Type u} {Γ : Type w} [CompleteLattice Γ] [AddCommMonoid Γ]
    [IsCostAlgebra Γ] (d : X → X → Γ) (h0 : ∀ a, d a a = 0)
    (htri : ∀ a b c, d a c ≤ d a b + d b c) (a b : Complete X) :
    dist (completeWeight d) a b = d a.out b.out := by
  apply le_antisymm
  · exact dist_le_edge (completeWeight d) (() : a ⟶ b)
  · refine le_iInf fun p => ?_
    induction p with
    | nil => rw [pathCost_nil, h0]
    | cons p e ih =>
      rw [pathCost_cons]
      exact (htri _ _ _).trans (CostAlgebra.add_le_add ih le_rfl)

/-! ### 3. The counting law is the only general fact about binary systems -/

/-- **Completeness of the counting law.** A function `f : X → ℕ∞` is the complexity of an
unambiguous binary description system if and only if, for every `n`, at most `2 ^ n`
objects have `f = n` (they embed into the bit strings of length `n`). So counting is the
entire content of "descriptions are bit strings and cost is length". -/
theorem exists_binary_iff {X : Type u} (f : X → ℕ∞) :
    (∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧ ∀ x, S.K x = f x) ↔
      ∀ n : ℕ, Nonempty ({x // f x = n} ↪ List.Vector Bool n) := by
  constructor
  · rintro ⟨S, hb, hfun, hK⟩ n
    have h : ∀ x : {x // f x = n}, ∃ l : List Bool, S.realizes l x.1 ∧ l.length = n := by
      rintro ⟨x, hx⟩
      have hne : S.K x ≠ ⊤ := by rw [hK, hx]; exact ENat.natCast_ne_top n
      obtain ⟨l, hl, hc⟩ := S.exists_cost_eq_K hne
      refine ⟨l, hl, ?_⟩
      have h1 : ((l.length : ℕ) : ℕ∞) = n := by rw [← hb l, hc, hK, hx]
      exact_mod_cast h1
    choose g hg using h
    refine ⟨⟨fun x => ⟨g x, (hg x).2⟩, fun x y hxy => ?_⟩⟩
    have hgl : g x = g y := congrArg Subtype.val hxy
    exact Subtype.ext (hfun (hg x).1 (hgl ▸ (hg y).1))
  · intro h
    have e : ∀ n : ℕ, {x // f x = n} ↪ List.Vector Bool n := fun n => (h n).some
    let S : DescSystem (List Bool) X ℕ∞ :=
      ⟨fun l => l.length, fun l x => ∃ (n : ℕ) (hx : f x = n), (e n ⟨x, hx⟩).toList = l⟩
    refine ⟨S, fun _ => rfl, ?_, fun x => ?_⟩
    · rintro l x y ⟨n, hx, h1⟩ ⟨m, hy, h2⟩
      have hn : n = m := by
        have := congrArg List.length (h1.trans h2.symm)
        simpa using this
      subst hn
      have := (e n).injective (List.Vector.toList_injective (h1.trans h2.symm))
      exact congrArg Subtype.val this
    · rcases eq_or_ne (f x) ⊤ with htop | hfin
      · rw [htop]
        refine S.K_eq_top fun l hl => ?_
        obtain ⟨n, hx, -⟩ := hl
        exact ENat.natCast_ne_top n (hx.symm.trans htop)
      · obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 hfin
        have hx : f x = n := hn.symm
        apply le_antisymm
        · have hr : S.realizes (e n ⟨x, hx⟩).toList x := ⟨n, hx, rfl⟩
          refine (S.K_le_cost hr).trans ?_
          show (((e n ⟨x, hx⟩).toList.length : ℕ) : ℕ∞) ≤ f x
          rw [List.Vector.toList_length, hx]
        · refine S.le_K_iff.2 fun l hl => ?_
          obtain ⟨m, hx', rfl⟩ := hl
          show f x ≤ (((e m ⟨x, hx'⟩).toList.length : ℕ) : ℕ∞)
          rw [List.Vector.toList_length, hx']

/-! ### 4. A simulation exists whenever the inequality it would prove is true -/

/-- **Transport is complete, hence empty without a notion of admissible translation.**
For systems with finite costs, `S'` dominates `S` iff every `S`-description of every
object can be matched by an `S'`-description of the same object at constant extra cost.
Nothing constrains *how* the match is found, so the abstract invariance theorem has
content only relative to a class of translations fixed from outside (for Kolmogorov
complexity: the computable ones). -/
theorem dominates_iff_pointwise {D D' X : Type*} (S : DescSystem D X ℕ∞)
    (S' : DescSystem D' X ℕ∞) (hfin : ∀ d, S.cost d ≠ ⊤) :
    Dominates S' S ↔
      ∃ c : ℕ, ∀ d x, S.realizes d x → ∃ d', S'.realizes d' x ∧ S'.cost d' ≤ S.cost d + c := by
  constructor
  · rintro ⟨c, hc⟩
    refine ⟨c, fun d x hd => ?_⟩
    have h1 : S'.K x ≤ S.cost d + c := (hc x).trans (add_le_add (S.K_le_cost hd) le_rfl)
    have hne : S'.K x ≠ ⊤ :=
      ne_top_of_le_ne_top (WithTop.add_ne_top.2 ⟨hfin d, ENat.natCast_ne_top c⟩) h1
    obtain ⟨d', hd', hc'⟩ := S'.exists_cost_eq_K hne
    exact ⟨d', hd', hc' ▸ h1⟩
  · rintro ⟨c, h⟩
    refine ⟨c, fun x => ?_⟩
    rcases eq_or_ne (S.K x) ⊤ with htop | hne
    · simp [htop]
    · obtain ⟨d, hd, hcd⟩ := S.exists_cost_eq_K hne
      obtain ⟨d', hd', hc'⟩ := h d x hd
      rw [← hcd]
      exact (S'.K_le_cost hd').trans hc'

/-! ### 5. Undelimited pairs: the logarithmic growth law fails for the universal machine -/

section Pairing

variable {X : Type*}

private theorem iterate_obj (f : X → X) (obj : ℕ → ℕ → X)
    (hf : ∀ a t, f (obj a t) = obj a (t + 1)) (a t : ℕ) : f^[t] (obj a 0) = obj a t := by
  induction t with
  | zero => rfl
  | succ t ih => rw [Function.iterate_succ_apply', ih, hf]

/-- The pairs `(a, t)` with `2 ^ (i - 1) ≤ a < 2 ^ i` and `t < 2 ^ (n - i)`: here `a` has
exactly `i` binary digits and `t` at most `n - i`. -/
private def band (n i : ℕ) : Finset (ℕ × ℕ) :=
  Finset.Ico (2 ^ (i - 1)) (2 ^ i) ×ˢ Finset.range (2 ^ (n - i))

private theorem card_band {n i : ℕ} (hi : i ∈ Finset.Icc 1 n) :
    (band n i).card = 2 ^ (n - 1) := by
  obtain ⟨h1, h2⟩ := Finset.mem_Icc.1 hi
  have e : 2 ^ i = 2 ^ (i - 1) + 2 ^ (i - 1) := by
    rw [← Nat.mul_two, ← pow_succ]
    congr 1
    omega
  rw [band, Finset.card_product, Nat.card_Ico, Finset.card_range, e, Nat.add_sub_cancel,
    ← pow_add]
  congr 1
  omega

private theorem band_disjoint (n : ℕ) {i j : ℕ} (hij : i ≠ j) :
    Disjoint (band n i) (band n j) := by
  rw [Finset.disjoint_left]
  rintro ⟨a, t⟩ hi hj
  simp only [band, Finset.mem_product, Finset.mem_Ico, Finset.mem_range] at hi hj
  rcases Nat.lt_or_gt_of_ne hij with h | h
  · have : 2 ^ i ≤ 2 ^ (j - 1) := Nat.pow_le_pow_right (by norm_num) (by omega)
    omega
  · have : 2 ^ j ≤ 2 ^ (i - 1) := Nat.pow_le_pow_right (by norm_num) (by omega)
    omega

/-- The union of the bands `1, …, n`: it has `n * 2 ^ (n - 1)` members, and every member
`(a, t)` has `size a + size t ≤ n`. -/
private def bands (n : ℕ) : Finset (ℕ × ℕ) := (Finset.Icc 1 n).biUnion (band n)

private theorem card_bands (n : ℕ) : (bands n).card = n * 2 ^ (n - 1) := by
  rw [bands, Finset.card_biUnion fun i _ j _ hij => band_disjoint n hij,
    Finset.sum_congr rfl fun i hi => card_band hi, Finset.sum_const, Nat.card_Icc,
    smul_eq_mul, Nat.add_sub_cancel]

private theorem size_add_size_le {n : ℕ} {p : ℕ × ℕ} (hp : p ∈ bands n) :
    Nat.size p.1 + Nat.size p.2 ≤ n := by
  obtain ⟨i, hi, hp⟩ := Finset.mem_biUnion.1 hp
  simp only [band, Finset.mem_product, Finset.mem_Ico, Finset.mem_range] at hp
  obtain ⟨h1, h2⟩ := Finset.mem_Icc.1 hi
  have ha : Nat.size p.1 ≤ i := Nat.size_le.2 hp.1.2
  have ht : Nat.size p.2 ≤ n - i := Nat.size_le.2 hp.2
  omega

/-- **No constant-overhead pairing.** In an unambiguous binary system, an injective family
of objects indexed by pairs of numbers cannot satisfy `K(obj a t) ≤ size a + size t + C`:
there are `n * 2 ^ (n - 1)` pairs with `size a + size t ≤ n` but fewer than `2 ^ (n+C+1)`
objects that cheap. This is the classical failure of subadditivity of plain complexity. -/
theorem not_forall_K_obj_le (T : DescSystem (List Bool) X ℕ∞) (hb : T.IsBinary)
    (hfun : T.Functional) (obj : ℕ → ℕ → X)
    (hinj : Function.Injective fun p : ℕ × ℕ => obj p.1 p.2) (C : ℕ) :
    ¬ ∀ a t : ℕ, T.K (obj a t) ≤ ((Nat.size a + Nat.size t + C : ℕ) : ℕ∞) := by
  classical
  intro key
  obtain ⟨n, hn⟩ : ∃ n, n = 2 ^ (C + 2) := ⟨_, rfl⟩
  have hn1 : 1 ≤ n := hn ▸ Nat.one_le_two_pow
  let A : Finset X := (bands n).image fun p => obj p.1 p.2
  have hAcard : A.card = n * 2 ^ (n - 1) := by
    rw [Finset.card_image_of_injective _ hinj, card_bands]
  have hA : ∀ x ∈ A, T.K x < ((n + C + 1 : ℕ) : ℕ∞) := by
    intro x hx
    obtain ⟨⟨a, t⟩, hp, rfl⟩ := Finset.mem_image.1 hx
    have hsz : Nat.size a + Nat.size t ≤ n := size_add_size_le hp
    refine lt_of_le_of_lt (key a t) ?_
    exact_mod_cast (show Nat.size a + Nat.size t + C < n + C + 1 by omega)
  have hlt : A.card < 2 ^ (n + C + 1) := by
    have h := hb.card_compressible_lt hfun (n + C + 1) A
    rwa [Finset.filter_true_of_mem hA] at h
  have hpow : 2 ^ (n + C + 1) = n * 2 ^ (n - 1) := by
    have : n + C + 1 = (C + 2) + (n - 1) := by omega
    rw [this, pow_add, ← hn]
  rw [hAcard, hpow] at hlt
  exact lt_irrefl _ hlt

/-- **The logarithmic growth law fails without a delimiter.** Let `T` be an unambiguous
binary system that describes the starting states `obj a 0` within `size a + c₁` bits, and
let `f` advance a counter (`f (obj a t) = obj a (t + 1)`). Then no constant `c` gives
`K(fᵗ x) ≤ K(x) + size t + c`. -/
theorem not_iterate_bound (T : DescSystem (List Bool) X ℕ∞) (hb : T.IsBinary)
    (hfun : T.Functional) (f : X → X) (obj : ℕ → ℕ → X)
    (hinj : Function.Injective fun p : ℕ × ℕ => obj p.1 p.2)
    (hf : ∀ a t, f (obj a t) = obj a (t + 1)) (c₁ : ℕ)
    (hT : ∀ a, T.K (obj a 0) ≤ (Nat.size a : ℕ∞) + c₁) :
    ¬ ∃ c : ℕ, ∀ (x : X) (t : ℕ), T.K (f^[t] x) ≤ T.K x + Nat.size t + c := by
  rintro ⟨c, hc⟩
  refine not_forall_K_obj_le T hb hfun obj hinj (c₁ + c) fun a t => ?_
  have h2 := hc (obj a 0) t
  rw [iterate_obj f obj hf] at h2
  calc T.K (obj a t)
      ≤ (T.K (obj a 0) + Nat.size t) + c := h2
    _ ≤ (((Nat.size a : ℕ∞) + c₁) + Nat.size t) + c :=
        add_le_add (add_le_add (hT a) le_rfl) le_rfl
    _ = ((Nat.size a + Nat.size t + (c₁ + c) : ℕ) : ℕ∞) := by push_cast; ring

/-- Consequently such a `T` does **not** dominate its own iterate system, so
`Dynamics.exists_const_K_iterate_le` cannot be applied with `S = U = T`. -/
theorem not_dominates_iterate (T : DescSystem (List Bool) X ℕ∞) (hb : T.IsBinary)
    (hfun : T.Functional) (f : X → X) (obj : ℕ → ℕ → X)
    (hinj : Function.Injective fun p : ℕ × ℕ => obj p.1 p.2)
    (hf : ∀ a t, f (obj a t) = obj a (t + 1)) (c₁ : ℕ)
    (hT : ∀ a, T.K (obj a 0) ≤ (Nat.size a : ℕ∞) + c₁) :
    ¬ Dominates T (Dynamics.iterate T f) := fun h =>
  not_iterate_bound T hb hfun f obj hinj hf c₁ hT (Dynamics.exists_const_K_iterate_le T f T h)

end Pairing

/-! #### The same, for the library's own universal machine -/

open Nat.Partrec (Code)

private theorem bits_injective : Function.Injective Nat.bits := fun a a' h =>
  Nat.digits.injective 2 (by rw [Nat.digits_two_eq_bits, Nat.digits_two_eq_bits, h])

/-- A primitive recursive law of motion on (codes of) pairs: advance the second
component. -/
def tick (m : ℕ) : ℕ := Nat.pair (Nat.unpair m).1 ((Nat.unpair m).2 + 1)

/-- **`K(fᵗ x) ≤ K(x) + log t + c` is false for Kolmogorov complexity.** For the universal
interpreter `Kolmogorov.U` of this library and the primitive recursive map `tick`, no
constant works. (The true statements: `+ O(log log t)` more, or a self-delimiting
description of one of the two parts.) -/
theorem not_iterate_bound_kolmogorov :
    ¬ ∃ c : ℕ, ∀ x t : ℕ, Kolmogorov.K Kolmogorov.U (tick^[t] x) ≤
        Kolmogorov.K Kolmogorov.U x + Nat.size t + c := by
  obtain ⟨k, hk⟩ := Kolmogorov.K_U_le (Code.pair Code.id Code.zero)
  refine not_iterate_bound (Kolmogorov.sys Kolmogorov.U) (Kolmogorov.sys_isBinary _)
    (Kolmogorov.sys_functional _) tick (fun a t => Nat.pair (Encodable.encode (Nat.bits a)) t)
    ?_ ?_ k ?_
  · rintro ⟨a, t⟩ ⟨a', t'⟩ h
    obtain ⟨h1, h2⟩ := Nat.pair_eq_pair.1 h
    have h3 : a = a' := bits_injective (Encodable.encode_injective h1)
    exact Prod.ext h3 h2
  · intro a t
    simp [tick]
  · intro a
    have hmem : Nat.pair (Encodable.encode (Nat.bits a)) 0 ∈
        Kolmogorov.run (Code.pair Code.id Code.zero) (Nat.bits a) := by
      show _ ∈ (Code.pair Code.id Code.zero).eval (Encodable.encode (Nat.bits a))
      simp [Nat.Partrec.Code.eval, Seq.seq]
      exact Part.mem_some 0
    have h1 := Kolmogorov.K_le_length hmem
    rw [Nat.size_eq_bits_len] at h1
    exact (hk _).trans (add_le_add h1 le_rfl)

/-- `Kolmogorov.U` does not dominate its own iterate system for `tick`. -/
theorem not_dominates_iterate_kolmogorov :
    ¬ Dominates (Kolmogorov.sys Kolmogorov.U)
        (Dynamics.iterate (Kolmogorov.sys Kolmogorov.U) tick) := fun h =>
  not_iterate_bound_kolmogorov
    (Dynamics.exists_const_K_iterate_le (Kolmogorov.sys Kolmogorov.U) tick _ h)

/-! ### 6. Undelimited pairs: the two-part bound fails for the universal machine -/

/-- Padded index length: `k + padLen k` is the least power of two exceeding `k`. -/
def padLen (k : ℕ) : ℕ := 2 ^ Nat.size k - k

/-- **Microstates**: a macrostate (a bit string `u`) together with an index of exactly
`padLen |u|` bits. The fibre over `u` has `2 ^ padLen |u|` members and the index is the
fixed-length code of a microstate within its fibre, of length `log₂ W`. -/
def Micro : Type := {p : List Bool × List Bool // p.2.length = padLen p.1.length}

private theorem size_eq_of_mem_Ico {m k : ℕ} (hm : 1 ≤ m)
    (hk : k ∈ Finset.Ico (2 ^ (m - 1)) (2 ^ m)) : Nat.size k = m := by
  obtain ⟨h1, h2⟩ := Finset.mem_Ico.1 hk
  have a : Nat.size k ≤ m := Nat.size_le.2 h2
  have b : m - 1 < Nat.size k := Nat.lt_size.2 h1
  omega

/-- **The two-part bound fails without a delimiter.** Let `S` describe every macrostate
`u` within `|u| + c₁` bits and let `T` be any unambiguous binary system on microstates.
Then no constant `c` gives `K(x) ≤ K(π x) + log₂ W(π x) + c`. -/
theorem not_twoPart_bound {D : Type*} (T : DescSystem (List Bool) Micro ℕ∞) (hb : T.IsBinary)
    (hfun : T.Functional) (S : DescSystem D (List Bool) ℕ∞) (c₁ : ℕ)
    (hS : ∀ u : List Bool, S.K u ≤ (u.length : ℕ∞) + c₁) :
    ¬ ∃ c : ℕ, ∀ x : Micro, T.K x ≤ S.K x.1.1 + (x.1.2.length : ℕ∞) + c := by
  classical
  rintro ⟨c, hc⟩
  obtain ⟨C, hC⟩ : ∃ C, C = c₁ + c := ⟨_, rfl⟩
  have key : ∀ x : Micro, T.K x ≤ ((x.1.1.length + x.1.2.length + C : ℕ) : ℕ∞) := by
    intro x
    calc T.K x ≤ (S.K x.1.1 + (x.1.2.length : ℕ∞)) + c := hc x
      _ ≤ (((x.1.1.length : ℕ∞) + c₁) + x.1.2.length) + c :=
          add_le_add (add_le_add (hS _) le_rfl) le_rfl
      _ = ((x.1.1.length + x.1.2.length + C : ℕ) : ℕ∞) := by rw [hC]; push_cast; ring
  obtain ⟨m, hm⟩ : ∃ m, m = C + 2 := ⟨_, rfl⟩
  obtain ⟨L, hL⟩ : ∃ L, L = 2 ^ m := ⟨_, rfl⟩
  have hm1 : 1 ≤ m := by omega
  let I : Finset (ℕ × List.Vector Bool L) := Finset.Ico (2 ^ (m - 1)) (2 ^ m) ×ˢ Finset.univ
  have hlen : ∀ p ∈ I, (p.2.toList.take p.1).length = p.1 ∧
      (p.2.toList.drop p.1).length = L - p.1 := by
    rintro ⟨k, w⟩ hp
    have hk := Finset.mem_Ico.1 (Finset.mem_product.1 hp).1
    have hkL : k ≤ L := by rw [hL]; exact hk.2.le
    constructor
    · show (w.toList.take k).length = k
      rw [List.length_take, List.Vector.toList_length, min_eq_left hkL]
    · show (w.toList.drop k).length = L - k
      rw [List.length_drop, List.Vector.toList_length]
  have hval : ∀ p ∈ I, (p.2.toList.drop p.1).length = padLen (p.2.toList.take p.1).length := by
    intro p hp
    have hsz := size_eq_of_mem_Ico hm1 (Finset.mem_product.1 hp).1
    rw [(hlen p hp).1, (hlen p hp).2, padLen, hsz, ← hL]
  let g : {p // p ∈ I} → Micro := fun p =>
    ⟨(p.1.2.toList.take p.1.1, p.1.2.toList.drop p.1.1), hval p.1 p.2⟩
  have hg : Function.Injective g := by
    rintro ⟨⟨k, w⟩, hp⟩ ⟨⟨k', w'⟩, hp'⟩ h
    have h' : (w.toList.take k, w.toList.drop k) = (w'.toList.take k', w'.toList.drop k') :=
      congrArg Subtype.val h
    obtain ⟨ht, hd⟩ := Prod.mk.inj h'
    have h1 : (w.toList.take k).length = k := (hlen _ hp).1
    have h1' : (w'.toList.take k').length = k' := (hlen _ hp').1
    have hkk : k = k' := by rw [← h1, ← h1', ht]
    subst hkk
    have hw : w.toList = w'.toList := by
      rw [← List.take_append_drop k w.toList, ← List.take_append_drop k w'.toList, ht, hd]
    have hww : w = w' := List.Vector.toList_injective hw
    subst hww
    rfl
  let A : Finset Micro := I.attach.image g
  have hAcard : A.card = 2 ^ (m - 1) * 2 ^ L := by
    have e : 2 ^ m = 2 ^ (m - 1) + 2 ^ (m - 1) := by
      rw [← Nat.mul_two, ← pow_succ]
      congr 1
      omega
    rw [Finset.card_image_of_injective _ hg, Finset.card_attach, Finset.card_product,
      Nat.card_Ico, Finset.card_univ, card_vector, Fintype.card_bool, e, Nat.add_sub_cancel]
  have hA : ∀ x ∈ A, T.K x < ((L + C + 1 : ℕ) : ℕ∞) := by
    intro x hx
    obtain ⟨⟨⟨k, w⟩, hp⟩, -, rfl⟩ := Finset.mem_image.1 hx
    have hk := Finset.mem_Ico.1 (Finset.mem_product.1 hp).1
    have hkL : k ≤ L := by rw [hL]; exact hk.2.le
    have h1 : (w.toList.take k).length = k := (hlen _ hp).1
    have h2 : (w.toList.drop k).length = L - k := (hlen _ hp).2
    refine lt_of_le_of_lt (key _) ?_
    show (((w.toList.take k).length + (w.toList.drop k).length + C : ℕ) : ℕ∞) < _
    rw [h1, h2]
    exact_mod_cast (show k + (L - k) + C < L + C + 1 by omega)
  have hlt : A.card < 2 ^ (L + C + 1) := by
    have h := hb.card_compressible_lt hfun (L + C + 1) A
    rwa [Finset.filter_true_of_mem hA] at h
  have hpow : 2 ^ (L + C + 1) = 2 ^ (m - 1) * 2 ^ L := by
    rw [← pow_add]
    congr 1
    omega
  rw [hAcard, hpow] at hlt
  exact lt_irrefl _ hlt

/-- Consequently no such `T` dominates the two-part system over `S`, so
`CoarseGraining.exists_const_K_le_macro_add` cannot be applied to it. -/
theorem not_dominates_twoPart {D : Type*} (T : DescSystem (List Bool) Micro ℕ∞)
    (hb : T.IsBinary) (hfun : T.Functional) (S : DescSystem D (List Bool) ℕ∞) (c₁ : ℕ)
    (hS : ∀ u : List Bool, S.K u ≤ (u.length : ℕ∞) + c₁) :
    ¬ Dominates T (CoarseGraining.twoPart S (fun x : Micro => x.1.1) fun x => x.1.2) := fun h =>
  not_twoPart_bound T hb hfun S c₁ hS
    (CoarseGraining.exists_const_K_le_macro_add S (fun x : Micro => x.1.1) (fun x => x.1.2) T h)

/-- Describe the objects of `Y` through an injective numbering into the objects of `S`. -/
def comap {D X Y Γ : Type*} (S : DescSystem D X Γ) (e : Y → X) : DescSystem D Y Γ where
  cost := S.cost
  realizes d y := S.realizes d (e y)

theorem comap_K {D X Y Γ : Type*} [CompleteLattice Γ] (S : DescSystem D X Γ) (e : Y → X)
    (y : Y) : (comap S e).K y = S.K (e y) := rfl

/-- **`K(x) ≤ K(π x) + log₂ W + c` is false for Kolmogorov complexity**, whatever
injective numbering `e` of the microstates is used. -/
theorem not_twoPart_bound_kolmogorov (e : Micro → ℕ) (he : Function.Injective e) :
    ¬ ∃ c : ℕ, ∀ x : Micro, Kolmogorov.K Kolmogorov.U (e x) ≤
        Kolmogorov.K Kolmogorov.U (Encodable.encode x.1.1) + (x.1.2.length : ℕ∞) + c := by
  obtain ⟨k, hk⟩ := Kolmogorov.K_U_encode_le
  exact not_twoPart_bound (comap (Kolmogorov.sys Kolmogorov.U) e)
    (Kolmogorov.sys_isBinary Kolmogorov.U)
    (fun _ _ _ hx hy => he (Kolmogorov.sys_functional Kolmogorov.U hx hy))
    (comap (Kolmogorov.sys Kolmogorov.U) (Encodable.encode : List Bool → ℕ)) k hk

/-! ### 7. "Complex implies improbable" is not a law of description systems -/

section Probable

open scoped ENNReal

/-- Bit vectors of length `n + 1` with a prescribed first bit correspond to bit vectors of
length `n`. -/
def headEquiv (n : ℕ) (b : Bool) :
    {v : List.Vector Bool (n + 1) // v.head = b} ≃ List.Vector Bool n where
  toFun v := v.1.tail
  invFun w := ⟨b ::ᵥ w, List.Vector.head_cons b w⟩
  left_inv := by
    rintro ⟨v, hv⟩
    apply Subtype.ext
    show b ::ᵥ v.tail = v
    rw [← hv]
    exact List.Vector.cons_head_tail v
  right_inv w := List.Vector.tail_cons b w

/-- **Complex and probable.** For every `n` there is an unambiguous, prefix-free (Kraft
sum exactly `1`) description system with two objects, each of complexity `n + 1` and each
of algorithmic probability `1/2`. So `Z ≤ 2 ^ (-K + O(1))`, the upper half of the coding
theorem, is not a consequence of the framework: it is a theorem about universal machines.
`Thermo.Z_le_tail` is the only upper bound available in general, and it bounds `Z x` by
the weight of *all* long descriptions, which here is `1`. -/
theorem exists_complex_probable (n : ℕ) :
    ∃ r : List.Vector Bool (n + 1) → Bool → Prop,
      (Thermo.ofLen (fun _ => n + 1) r).Functional ∧
      (∑' _ : List.Vector Bool (n + 1), (2⁻¹ : ℝ≥0∞) ^ (n + 1)) = 1 ∧
      ∀ b : Bool, (Thermo.ofLen (fun _ => n + 1) r).K b = (n + 1 : ℕ) ∧
        Thermo.Z (fun _ => n + 1) r 2⁻¹ b = 2⁻¹ := by
  have h2 : (2 : ℝ≥0∞) * 2⁻¹ = 1 := ENNReal.mul_inv_cancel two_ne_zero ENNReal.ofNat_ne_top
  refine ⟨fun v b => v.head = b, fun _ _ _ hx hy => hx.symm.trans hy, ?_, fun b => ⟨?_, ?_⟩⟩
  · rw [tsum_fintype, Finset.sum_const, Finset.card_univ, card_vector, Fintype.card_bool,
      nsmul_eq_mul]
    push_cast
    rw [← mul_pow, h2, one_pow]
  · apply le_antisymm
    · exact (Thermo.ofLen (fun _ => n + 1) fun (v : List.Vector Bool (n + 1)) b => v.head = b).K_le_cost
        (d := b ::ᵥ List.Vector.replicate n false) (List.Vector.head_cons _ _)
    · exact (DescSystem.le_K_iff _).2 fun _ _ => le_rfl
  · show (∑' _ : {v : List.Vector Bool (n + 1) // v.head = b}, (2⁻¹ : ℝ≥0∞) ^ (n + 1)) = 2⁻¹
    rw [tsum_fintype, Finset.sum_const, Finset.card_univ, Fintype.card_congr (headEquiv n b),
      card_vector, Fintype.card_bool, nsmul_eq_mul, pow_succ, ← mul_assoc]
    push_cast
    rw [← mul_pow, h2, one_pow, one_mul]

end Probable

/-! ### 8. A receiver budget alone neither forces nor forbids depth-dependent loss -/

/-- **Retelling saturates.** If a relay re-encodes what it understood into the message it
received (`enc (pass x) = enc x`), then any number of retellings through it changes an
idea exactly as much as one retelling. So the budget model of `Channel.Relay` does not
*force* loss to grow with the length of the chain; the growth with depth in
`Channel.exists_loss_ge` comes entirely from its separate hypothesis that every hop loses
at least `lam`. The stability hypothesis is essential: without it loss can grow with
depth inside the same budget (`leak_iterate` below). -/
theorem relay_iterate_saturates {X : Type*} {B : ℕ} (h : Channel.Relay X B)
    (hstable : ∀ x, h.enc (h.pass x) = h.enc x) (n : ℕ) (x : X) :
    h.pass^[n + 1] x = h.pass x := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih]
    show h.dec (h.enc (h.pass x)) = h.dec (h.enc x)
    rw [hstable]

/-- The relay that keeps the first `B` bits. -/
def truncRelay (B : ℕ) : Channel.Relay (List Bool) B where
  enc := List.take B
  dec := id
  short x := List.length_take_le B x

/-- Stable relays exist at every budget: a chain of `n + 1` truncating relays loses what
one does. -/
theorem truncRelay_iterate (B n : ℕ) (x : List Bool) :
    (truncRelay B).pass^[n + 1] x = x.take B :=
  relay_iterate_saturates (truncRelay B)
    (fun x => by simp [truncRelay, Channel.Relay.pass, List.take_take]) n x

/-- A relay within budget `B` that drops one more bit at every retelling. -/
def leakRelay (B : ℕ) : Channel.Relay (List Bool) B where
  enc x := (x.take B).tail
  dec := id
  short x := by
    have := List.length_take_le B x
    simp only [List.length_tail]
    omega

/-- **The budget model does not forbid loss that grows with depth either.** Through the
same budget-`B` relay, `n ≤ B` retellings of a `B`-bit idea leave `B - n` bits: one more is
lost at every hop. So the model alone says neither "loss grows with depth" nor "loss is set
by the tightest hop"; `relay_iterate_saturates` needs its stability hypothesis. An earlier
note here claimed the second without that hypothesis; an independent review supplied this
counterexample. -/
theorem leak_iterate (B n : ℕ) (hn : n ≤ B) :
    ((leakRelay B).pass^[n] (List.replicate B true)).length = B - n := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Function.iterate_succ_apply']
    have := ih (by omega)
    simp only [Channel.Relay.pass, leakRelay, id, List.length_tail, List.length_take] at this ⊢
    omega

/-- **A function relay can lose a fixed share of a repertoire per hop.** Through the same
relay, every idea of `B` bits is an idea of `B - n` bits after `n ≤ B` retellings. There are
`2 ^ B` of the former and `2 ^ (B - n)` of the latter, so at most a share `2 ^ (-n)` of the
versions is left: one half per hop, with no randomness anywhere. -/
theorem leak_iterate_length (B n : ℕ) (x : List Bool) (hx : x.length = B) (hn : n ≤ B) :
    ((leakRelay B).pass^[n] x).length = B - n := by
  induction n with
  | zero => simpa using hx
  | succ n ih =>
    rw [Function.iterate_succ_apply']
    have := ih (by omega)
    simp only [Channel.Relay.pass, leakRelay, id, List.length_tail, List.length_take] at this ⊢
    omega

/-! ### 9. With a delimiter, both bounds hold

The failures in sections 5 and 6 are failures of *undelimited* concatenation, not of the
idea. If the first part is described by a self-delimiting (prefix-free) system, the two
parts can be glued into one unambiguous binary system at exactly the sum of their
lengths. So the correct forms are

  `K(fᵗ x) ≤ K_prefix(x) + log t`   and   `K(x) ≤ K_prefix(π x) + log₂ W`

up to the constant of whatever machine runs the glued system. -/

section Delimited

variable {X Y : Type*}

/-- A binary system is **prefix-free** (self-delimiting): no description is a proper prefix
of another. -/
def PrefixFree (S : DescSystem (List Bool) Y ℕ∞) : Prop :=
  ∀ ⦃p q : List Bool⦄ ⦃y y' : Y⦄, S.realizes p y → S.realizes (p ++ q) y' → q = []

/-- **Glue**: read a self-delimiting description of some `y`, then let the rest of the input
`q` select an object related to `y` by `F`. -/
def glue (S : DescSystem (List Bool) Y ℕ∞) (F : Y → List Bool → X → Prop) :
    DescSystem (List Bool) X ℕ∞ where
  cost l := l.length
  realizes l x := ∃ p q y, l = p ++ q ∧ S.realizes p y ∧ F y q x

theorem glue_isBinary (S : DescSystem (List Bool) Y ℕ∞) (F : Y → List Bool → X → Prop) :
    (glue S F).IsBinary := fun _ => rfl

/-- Glued descriptions parse uniquely when the first part is prefix-free. -/
theorem glue_functional {S : DescSystem (List Bool) Y ℕ∞} (hS : S.Functional)
    (hpf : PrefixFree S) {F : Y → List Bool → X → Prop}
    (hF : ∀ y q x x', F y q x → F y q x' → x = x') : (glue S F).Functional := by
  rintro l x x' ⟨p, q, y, rfl, hp, hx⟩ ⟨p', q', y', h, hp', hx'⟩
  have hpp : p = p' ∧ q = q' := by
    rcases List.append_eq_append_iff.1 h with ⟨a, rfl, rfl⟩ | ⟨a, rfl, rfl⟩
    · have ha : a = [] := hpf hp hp'
      subst ha
      simp
    · have ha : a = [] := hpf hp' hp
      subst ha
      simp
  obtain ⟨rfl, rfl⟩ := hpp
  obtain rfl : y = y' := hS hp hp'
  exact hF _ _ _ _ hx hx'

/-- The glued system describes `x` within the cost of `y` plus the length of the selector. -/
theorem K_glue_le (S : DescSystem (List Bool) Y ℕ∞) (hb : S.IsBinary)
    {F : Y → List Bool → X → Prop} {y : Y} {q : List Bool} {x : X} (h : F y q x) :
    (glue S F).K x ≤ S.K y + q.length := by
  rcases eq_or_ne (S.K y) ⊤ with htop | hne
  · simp [htop]
  obtain ⟨p, hp, hc⟩ := S.exists_cost_eq_K hne
  rw [← hc, hb p]
  refine ((glue S F).K_le_cost (d := p ++ q) ⟨p, q, y, rfl, hp, h⟩).trans ?_
  show (((p ++ q).length : ℕ) : ℕ∞) ≤ (p.length : ℕ∞) + (q.length : ℕ∞)
  rw [List.length_append]
  push_cast
  exact le_rfl

/-- Read a binary numeral (least significant bit first). -/
def numeral (q : List Bool) : ℕ := Nat.ofDigits 2 (q.map fun b => cond b 1 0)

theorem numeral_bits (t : ℕ) : numeral (Nat.bits t) = t := by
  rw [numeral, ← Nat.digits_two_eq_bits, Nat.ofDigits_digits]

/-- **The logarithmic growth law, correctly stated.** If the starting states have a
self-delimiting description system `S`, there is an unambiguous binary system in which
`K(fᵗ x) ≤ S.K(x) + size t` exactly: append the binary numeral of `t`. -/
theorem exists_binary_iterate (S : DescSystem (List Bool) X ℕ∞) (hb : S.IsBinary)
    (hS : S.Functional) (hpf : PrefixFree S) (f : X → X) :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧
      ∀ x t, T.K (f^[t] x) ≤ S.K x + Nat.size t := by
  refine ⟨glue S fun y q x => f^[numeral q] y = x, glue_isBinary _ _,
    glue_functional hS hpf fun _ _ _ _ h h' => h.symm.trans h', fun x t => ?_⟩
  have h := K_glue_le S hb (F := fun y q x => f^[numeral q] y = x) (y := x) (q := Nat.bits t)
    (x := f^[t] x) (by rw [numeral_bits])
  rwa [Nat.size_eq_bits_len] at h

/-- **The two-part bound, correctly stated.** If the macrostates have a self-delimiting
description system `S` and `code` separates the microstates of each fibre, there is an
unambiguous binary system in which `K(x) ≤ S.K(π x) + |code x|` exactly. -/
theorem exists_binary_twoPart (S : DescSystem (List Bool) Y ℕ∞) (hb : S.IsBinary)
    (hS : S.Functional) (hpf : PrefixFree S) (π : X → Y) (code : X → List Bool)
    (hcode : ∀ x x', π x = π x' → code x = code x' → x = x') :
    ∃ T : DescSystem (List Bool) X ℕ∞, T.IsBinary ∧ T.Functional ∧
      ∀ x, T.K x ≤ S.K (π x) + (code x).length := by
  refine ⟨glue S fun y q x => π x = y ∧ code x = q, glue_isBinary _ _,
    glue_functional hS hpf ?_, fun x => K_glue_le S hb ⟨rfl, rfl⟩⟩
  rintro y q x x' ⟨h1, h2⟩ ⟨h1', h2'⟩
  exact hcode x x' (h1.trans h1'.symm) (h2.trans h2'.symm)

end Delimited

end Limits

end Complexity
