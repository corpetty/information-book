import Complexity.Basic

/-!
# The counting law

There are never more cheap objects than cheap descriptions.

This single pigeonhole statement is used in the library for

* the incompressibility theorem of algorithmic information theory,
* the converse of noiseless source coding (Hartley: selecting one of `N` costs `log N`),
* the `log W - c` lower bound for most of `W` candidates (`Instances/CoarseGraining.lean`),
* Ashby's law of requisite variety, under his separation hypothesis
  (`Instances/Regulator.lean`),
* a bound on VC dimension (`Instances/Learning.lean`).

It is *not* what proves Shannon's counting lower bound for circuits: that is a separate
direct count of construction histories (`Growth.lean`). An earlier version of this list
also named quantum-circuit and Cayley-graph complexity, which are not formalized here.

The law is parametric in the **growth function** of the description system – the number
of descriptions below a given cost. Each domain plugs in its own growth function; the
conclusion is always the same.
-/

namespace Complexity

namespace DescSystem

universe u v w

variable {D : Type u} {X : Type v}

section Linear

variable {Γ : Type w} [CompleteLinearOrder Γ] (S : DescSystem D X Γ)

/-- **Counting law.** In a functional system, if at most `N` descriptions cost less than
`c`, then at most `N` objects have complexity less than `c`. -/
theorem card_le_of_K_lt (hS : S.Functional) (c : Γ) (N : ℕ)
    (hN : ∀ B : Finset D, (∀ d ∈ B, S.cost d < c) → B.card ≤ N)
    (A : Finset X) (hA : ∀ x ∈ A, S.K x < c) : A.card ≤ N := by
  classical
  choose g hg using fun (x : A) => S.K_lt_iff.1 (hA x.1 x.2)
  have hinj : Function.Injective g := fun x y hxy =>
    Subtype.ext (hS (hg x).1 (hxy ▸ (hg y).1))
  calc A.card = A.attach.card := Finset.card_attach.symm
    _ = (A.attach.image g).card := (Finset.card_image_of_injective _ hinj).symm
    _ ≤ N := hN _ fun d hd => by
        obtain ⟨x, -, rfl⟩ := Finset.mem_image.1 hd
        exact (hg x).2

/-- Among any finite population, at most `N` members are cheaper than `c`. -/
theorem card_filter_K_lt_le (hS : S.Functional) (c : Γ) (N : ℕ)
    (hN : ∀ B : Finset D, (∀ d ∈ B, S.cost d < c) → B.card ≤ N)
    (A : Finset X) [DecidablePred fun x => S.K x < c] :
    (A.filter fun x => S.K x < c).card ≤ N :=
  S.card_le_of_K_lt hS c N hN _ fun _ hx => (Finset.mem_filter.1 hx).2

/-- **Incompressibility, general form.** Any population larger than the number of cheap
descriptions contains an object that is not cheap. -/
theorem exists_le_K (hS : S.Functional) (c : Γ) (N : ℕ)
    (hN : ∀ B : Finset D, (∀ d ∈ B, S.cost d < c) → B.card ≤ N)
    (A : Finset X) (hA : N < A.card) : ∃ x ∈ A, c ≤ S.K x := by
  by_contra h
  simp only [not_exists, not_and, not_le] at h
  exact absurd (S.card_le_of_K_lt hS c N hN A h) (not_le.2 hA)

end Linear

/-! ### Growth functions -/

/-- `S` has **growth at most `N`**: fewer than… precisely, at most `N n` descriptions
cost strictly less than `n`. -/
def GrowthLE (S : DescSystem D X ℕ∞) (N : ℕ → ℕ) : Prop :=
  ∀ (n : ℕ) (B : Finset D), (∀ d ∈ B, S.cost d < n) → B.card ≤ N n

theorem GrowthLE.card_filter_le {S : DescSystem D X ℕ∞} {N : ℕ → ℕ} (hN : S.GrowthLE N)
    (hS : S.Functional) (n : ℕ) (A : Finset X) [DecidablePred fun x => S.K x < n] :
    (A.filter fun x => S.K x < n).card ≤ N n :=
  S.card_filter_K_lt_le hS n (N n) (hN n) A

theorem GrowthLE.exists_le_K {S : DescSystem D X ℕ∞} {N : ℕ → ℕ} (hN : S.GrowthLE N)
    (hS : S.Functional) (n : ℕ) (A : Finset X) (hA : N n < A.card) :
    ∃ x ∈ A, (n : ℕ∞) ≤ S.K x :=
  S.exists_le_K hS n (N n) (hN n) A hA

/-! ### Binary descriptions -/

/-- Fewer than `2 ^ n` bit strings are shorter than `n`. -/
theorem card_lt_two_pow_of_length_lt (n : ℕ) (B : Finset (List Bool))
    (hB : ∀ l ∈ B, l.length < n) : B.card < 2 ^ n := by
  classical
  have hsub : B ⊆ (Finset.range n).biUnion fun k =>
      (Finset.univ : Finset (List.Vector Bool k)).map
        ⟨List.Vector.toList, List.Vector.toList_injective⟩ := by
    intro l hl
    exact Finset.mem_biUnion.2 ⟨l.length, Finset.mem_range.2 (hB l hl),
      Finset.mem_map.2 ⟨(⟨l, rfl⟩ : List.Vector Bool l.length), Finset.mem_univ _, rfl⟩⟩
  have hF : ((Finset.range n).biUnion fun k =>
      (Finset.univ : Finset (List.Vector Bool k)).map
        ⟨List.Vector.toList, List.Vector.toList_injective⟩).card ≤
          ∑ k ∈ Finset.range n, 2 ^ k := by
    refine Finset.card_biUnion_le.trans (Finset.sum_le_sum fun k _ => ?_)
    rw [Finset.card_map, Finset.card_univ, card_vector, Fintype.card_bool]
  have hgeo : ∑ k ∈ Finset.range n, 2 ^ k < 2 ^ n :=
    Nat.geomSum_lt le_rfl fun k hk => Finset.mem_range.1 hk
  exact (Finset.card_le_card hsub).trans_lt (hF.trans_lt hgeo)

/-- A system is **binary** if its descriptions are bit strings and cost is length. -/
def IsBinary (S : DescSystem (List Bool) X ℕ∞) : Prop := ∀ l, S.cost l = l.length

/-- Binary systems have growth `2 ^ n - 1`. -/
theorem IsBinary.growth {S : DescSystem (List Bool) X ℕ∞} (hb : S.IsBinary) :
    S.GrowthLE fun n => 2 ^ n - 1 := by
  intro n B hB
  refine Nat.le_sub_one_of_lt (card_lt_two_pow_of_length_lt n B fun l hl => ?_)
  have := hB l hl
  rw [hb l] at this
  exact_mod_cast this

/-- **Incompressibility theorem.** For a functional binary system, every population of at
least `2 ^ n` objects contains one of complexity at least `n`. -/
theorem IsBinary.exists_incompressible {S : DescSystem (List Bool) X ℕ∞} (hb : S.IsBinary)
    (hS : S.Functional) (n : ℕ) (A : Finset X) (hA : 2 ^ n ≤ A.card) :
    ∃ x ∈ A, (n : ℕ∞) ≤ S.K x :=
  hb.growth.exists_le_K hS n A (lt_of_lt_of_le (Nat.sub_one_lt (by positivity)) hA)

/-- **Compressible objects are exponentially rare.** Fewer than `2 ^ m` objects have
complexity below `m`; in a population of `2 ^ n`, the fraction compressible by `c` bits is
below `2 ^ (-c)`. -/
theorem IsBinary.card_compressible_lt {S : DescSystem (List Bool) X ℕ∞} (hb : S.IsBinary)
    (hS : S.Functional) (m : ℕ) (A : Finset X) [DecidablePred fun x => S.K x < m] :
    (A.filter fun x => S.K x < m).card < 2 ^ m :=
  lt_of_le_of_lt (hb.growth.card_filter_le hS m A) (Nat.sub_one_lt (by positivity))

/-! ### Hartley's law: selecting one of `N` costs `log N`

The two halves below pin the minimax complexity of a finite population between
`⌊log₂ N⌋` and `⌈log₂ N⌉`. Boltzmann entropy `log W` is this statement for the `W`
microstates compatible with a macrostate. -/

/-- **Lower half.** In every functional binary system some member of the population needs
at least `⌊log₂ N⌋` bits. -/
theorem IsBinary.exists_log_le_K {S : DescSystem (List Bool) X ℕ∞} (hb : S.IsBinary)
    (hS : S.Functional) (A : Finset X) (hA : A.Nonempty) :
    ∃ x ∈ A, (Nat.log 2 A.card : ℕ∞) ≤ S.K x :=
  hb.exists_incompressible hS _ A (Nat.pow_log_le_self 2 (Finset.card_ne_zero.2 hA))

/-- **Upper half.** Some functional binary system describes every member of the
population within `⌈log₂ N⌉` bits (a fixed-length index code). -/
theorem exists_index_system (A : Finset X) :
    ∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧
      ∀ x ∈ A, S.K x ≤ Nat.clog 2 A.card := by
  classical
  set k := Nat.clog 2 A.card with hk
  have hcard : Fintype.card A ≤ Fintype.card (List.Vector Bool k) := by
    rw [Fintype.card_coe, card_vector, Fintype.card_bool]
    exact Nat.le_pow_clog (by norm_num) _
  obtain ⟨e⟩ := Function.Embedding.nonempty_of_card_le hcard
  let S : DescSystem (List Bool) X ℕ∞ :=
    ⟨fun l => l.length, fun l x => ∃ h : x ∈ A, (e ⟨x, h⟩).1 = l⟩
  refine ⟨S, fun _ => rfl, ?_, ?_⟩
  · rintro l x y ⟨hx, rfl⟩ ⟨hy, hxy⟩
    have := e.injective (Subtype.ext hxy)
    exact (Subtype.mk.inj this).symm
  · intro x hx
    have h1 : S.realizes (e ⟨x, hx⟩).1 x := ⟨hx, rfl⟩
    refine (S.K_le_cost h1).trans ?_
    show (((e ⟨x, hx⟩).1.length : ℕ) : ℕ∞) ≤ k
    exact_mod_cast (e ⟨x, hx⟩).2.le

end DescSystem

end Complexity
