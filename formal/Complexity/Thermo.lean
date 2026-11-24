import Complexity.Basic
import Complexity.CostAlgebra
import Complexity.Counting

/-!
# The temperature dial: partition functions over descriptions

Complexity takes a *hard* minimum over the descriptions of an object. Replacing the
minimum by a Boltzmann sum gives the **partition function**

  `Z q x = ∑ { q ^ len d | d realizes x }`,   `q = e^{-β}` the fugacity,

which interpolates between the measures that different fields use:

* `q → 0`   – only the shortest description survives: `Z ≈ q ^ K x`, least-cost complexity;
* `q = 1/2` – `Z` is the **algorithmic probability** of `x`, the chance that a random
              description produces it (Solomonoff–Levin; simplicity bias in
              genotype–phenotype and other input–output maps);
* `q = 1`   – `Z` counts the descriptions of `x`: degeneracy, redundancy, neutral-set
              size, Boltzmann's `W`.

So least-cost complexity is the ground-state energy of a "description Hamiltonian",
algorithmic probability is its partition function, and multiplicity is its
infinite-temperature limit. This file proves what holds for every description system:

* `pow_len_le_Z`            – every description contributes its weight;
* `pow_le_Z_of_K_le`        – **simple implies probable** (the easy half of the coding
                              theorem): `q ^ K x ≤ Z q x`;
* `tsum_Z_le`               – for unambiguous descriptions the objects share out the total
                              partition function;
* `card_mul_le_one`         – **probable objects are few**: under a Kraft bound at most
                              `1 / t` objects have `Z ≥ t`;
* `card_le_two_pow_of_K_le` – the **Kraft counting law**: with prefix-free descriptions at
                              most `2 ^ n` objects have complexity at most `n`;
* `Z_le_tail`               – **complex implies improbable**: `Z q x` is at most the total
                              weight of the descriptions at least `K x` long, so objects
                              of high complexity are exponentially rare under undirected
                              generation – and finding many copies of one is evidence of a
                              process that is not undirected (selection, design, copying);
* `Z_one`                   – at `q = 1` the partition function is the number of
                              descriptions.

**Review note.** The inequalities below are true but much weaker than the prose above suggests.
"Complex implies improbable" is **not** a consequence of them: there is a prefix-free
unambiguous system in which no constant relates complexity and weight
(`Plain.not_coding_self_delimiting`; the older `Limits.exists_complex_probable` uses a
different two-object system for each constant and shows less). `Z_le_tail` bounds `Z x` by the weight of *all* long
descriptions; for bit strings at `q = 1/2` that bound is `⊤`, and for the plain universal
machine of `Instances/Kolmogorov.lean` `Z (1/2) x = ⊤` for every `x`. The upper half of
the coding theorem (simplicity bias) is a theorem about universal prefix machines.
`Prefix.lean` proves its existence form (`Prefix.exists_coding`); its
`Prefix.coding_of_dominates` is little more than the definition of domination unfolded and
is not used;
`Levin.lean` proves the statement itself for the universal prefix machine of
`Instances/PrefixMachine.lean`.
-/

namespace Complexity

namespace Thermo

open scoped ENNReal

universe u v

variable {D : Type u} {X : Type v}

/-- The description system with lengths `len` and realization `r`. -/
def ofLen (len : D → ℕ) (r : D → X → Prop) : DescSystem D X ℕ∞ := ⟨fun d => (len d : ℕ∞), r⟩

/-- **Partition function** at fugacity `q`: the total Boltzmann weight of the descriptions
of `x`. -/
noncomputable def Z (len : D → ℕ) (r : D → X → Prop) (q : ℝ≥0∞) (x : X) : ℝ≥0∞ :=
  ∑' d : {d // r d x}, q ^ len d.1

/-- Every description contributes: a realization of length `n` forces `q ^ n ≤ Z`. -/
theorem pow_len_le_Z (len : D → ℕ) (r : D → X → Prop) (q : ℝ≥0∞) {d : D} {x : X}
    (h : r d x) : q ^ len d ≤ Z len r q x :=
  le_tsum (fun d : {d // r d x} => q ^ len d.1) ⟨d, h⟩

/-- **Simple implies probable** (the easy half of the coding theorem): if `K x ≤ n` and
`q ≤ 1` then `q ^ n ≤ Z q x`. An object with a short description is produced by random
descriptions at least as often as that one description is drawn. -/
theorem pow_le_Z_of_K_le (len : D → ℕ) (r : D → X → Prop) (q : ℝ≥0∞) (hq : q ≤ 1) {x : X}
    {n : ℕ} (h : (ofLen len r).K x ≤ n) : q ^ n ≤ Z len r q x := by
  obtain ⟨d, hd, hc⟩ := (ofLen len r).K_le_coe_iff.1 h
  have hc' : ((len d : ℕ) : ℕ∞) ≤ n := hc
  have hlen : len d ≤ n := by exact_mod_cast hc'
  exact (pow_le_pow_right_of_le_one' hq hlen).trans (pow_len_le_Z len r q hd)

/-- The partition function is monotone in the fugacity: heating never removes weight. -/
theorem Z_mono (len : D → ℕ) (r : D → X → Prop) {q q' : ℝ≥0∞} (h : q ≤ q') (x : X) :
    Z len r q x ≤ Z len r q' x :=
  tsum_le_tsum fun d => pow_le_pow_left' h (len d.1)

/-- For a functional system the object-wise partition functions sum to at most the total
one: each description is counted for at most one object. -/
theorem tsum_Z_le (len : D → ℕ) (r : D → X → Prop) (hr : (ofLen len r).Functional)
    (q : ℝ≥0∞) : ∑' x, Z len r q x ≤ ∑' d, q ^ len d := by
  have hinj : Function.Injective (fun p : Σ x, {d // r d x} => p.2.1) := by
    rintro ⟨x, d, hd⟩ ⟨y, e, he⟩ hde
    have hde' : d = e := hde
    subst hde'
    have hxy : x = y := hr hd he
    subst hxy
    rfl
  calc ∑' x, Z len r q x
      = ∑' p : Σ x, {d // r d x}, q ^ len p.2.1 :=
        (tsum_sigma (β := fun x => {d // r d x}) fun _ d => q ^ len d.1).symm
    _ ≤ ∑' d, q ^ len d := tsum_comp_le_tsum_of_injective hinj fun d => q ^ len d

/-- **Probable objects are few.** Under a Kraft-type bound `∑' d, q ^ len d ≤ 1`, at most
`1 / t` objects have `Z ≥ t`. Stated multiplicatively. -/
theorem card_mul_le_one (len : D → ℕ) (r : D → X → Prop) (hr : (ofLen len r).Functional)
    (q : ℝ≥0∞) (hK : ∑' d, q ^ len d ≤ 1) (t : ℝ≥0∞) (A : Finset X)
    (hA : ∀ x ∈ A, t ≤ Z len r q x) : (A.card : ℝ≥0∞) * t ≤ 1 :=
  calc (A.card : ℝ≥0∞) * t = ∑ _x ∈ A, t := by rw [Finset.sum_const, nsmul_eq_mul]
    _ ≤ ∑ x ∈ A, Z len r q x := Finset.sum_le_sum hA
    _ ≤ ∑' x, Z len r q x := sum_le_tsum A
    _ ≤ ∑' d, q ^ len d := tsum_Z_le len r hr q
    _ ≤ 1 := hK

/-- **Kraft counting law.** With `∑' d, 2⁻¹ ^ len d ≤ 1` (prefix-free descriptions), at
most `2 ^ n` objects have complexity at most `n`. -/
theorem card_le_two_pow_of_K_le (len : D → ℕ) (r : D → X → Prop)
    (hr : (ofLen len r).Functional) (hK : ∑' d, (2⁻¹ : ℝ≥0∞) ^ len d ≤ 1) (n : ℕ)
    (A : Finset X) (hA : ∀ x ∈ A, (ofLen len r).K x ≤ n) : A.card ≤ 2 ^ n := by
  have hhalf : (2⁻¹ : ℝ≥0∞) ≤ 1 := ENNReal.inv_le_one.2 (by norm_num)
  have h1 : (A.card : ℝ≥0∞) * (2⁻¹ : ℝ≥0∞) ^ n ≤ 1 :=
    card_mul_le_one len r hr _ hK _ A fun x hx => pow_le_Z_of_K_le len r _ hhalf (hA x hx)
  rw [← ENNReal.inv_pow, ← ENNReal.le_inv_iff_mul_le, inv_inv] at h1
  exact_mod_cast h1

/-- **Complex implies improbable.** Every description of `x` is at least `K x` long, so the
weight of `x` is at most the total weight of descriptions that long. With a geometric
growth of descriptions this tail is exponentially small in `K x`. -/
theorem Z_le_tail (len : D → ℕ) (r : D → X → Prop) (q : ℝ≥0∞) (x : X) :
    Z len r q x ≤ ∑' d : {d // (ofLen len r).K x ≤ len d}, q ^ len d.1 := by
  let φ : {d // r d x} → {d // (ofLen len r).K x ≤ len d} :=
    fun d => ⟨d.1, (ofLen len r).K_le_cost d.2⟩
  have hφ : Function.Injective φ := by
    intro a b h
    have h' : (φ a).1 = (φ b).1 := congrArg Subtype.val h
    exact Subtype.ext h'
  exact tsum_comp_le_tsum_of_injective hφ
    fun d : {d // (ofLen len r).K x ≤ len d} => q ^ len d.1

/-- **Degeneracy.** At `q = 1` the partition function counts the descriptions of `x`:
redundancy, neutral-set size, Boltzmann's `W`. -/
theorem Z_one (len : D → ℕ) (r : D → X → Prop) (x : X) :
    Z len r 1 x = (ENat.card {d // r d x} : ℝ≥0∞) := by
  simp [Z]

end Thermo

end Complexity
