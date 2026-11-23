import Mathlib

/-!
# Description systems and complexity

The single definition on which everything else rests.

A **description system** consists of a type `D` of *descriptions* (programs, circuits,
assembly pathways, codes, models, proofs, strategies, histories …), a type `X` of
*objects* (strings, functions, molecules, states, distributions, behaviours …), a *cost*
`D → Γ` valued in a complete lattice, and a *realization* relation `D → X → Prop` saying
which descriptions produce which objects.

The **complexity** of an object is the least cost of a realization:

  `K x = ⨅ { cost d | d realizes x }`.

Every scalar complexity measure in use is this infimum for some choice of the four dials

* **generators** – which descriptions exist (`D`),
* **cost**       – what is paid and how payments are compared (`cost`, `Γ`),
* **fidelity**   – what counts as having produced the object (`realizes`),
* **context**    – what is already in hand (conditional systems, see `Metric.lean`).

This file develops what is true for *every* setting of the dials:

* `K_relax`     – relaxing fidelity replaces `K` by its infimum over the admissible class;
* `Sim.K_le`    – complexity is (lax) natural with respect to simulations;

Every function is the `K` of some description system (`Limits.exists_system_K_eq`), so
the representation statement above has content only once the dials are constrained.
-/

namespace Complexity

universe u v w u' v' w'

/-- A **description system**: descriptions `D` carrying a cost in `Γ`, together with a
relation saying which descriptions realize which objects of `X`. -/
structure DescSystem (D : Type u) (X : Type v) (Γ : Type w) where
  /-- The cost of a description. -/
  cost : D → Γ
  /-- `realizes d x`: the description `d` produces (denotes, computes, assembles, …) `x`. -/
  realizes : D → X → Prop

namespace DescSystem

section Lattice

variable {D : Type u} {X : Type v} {Γ : Type w} [CompleteLattice Γ]

/-- **Complexity**: the least cost of a realization. Unrealizable objects get `⊤`. -/
def K (S : DescSystem D X Γ) (x : X) : Γ :=
  ⨅ (d : D) (_ : S.realizes d x), S.cost d

variable (S : DescSystem D X Γ)

/-- Upper bounds are witnesses: any realization bounds the complexity from above. -/
theorem K_le_cost {d : D} {x : X} (h : S.realizes d x) : S.K x ≤ S.cost d :=
  iInf₂_le d h

/-- Lower bounds are statements about *all* realizations. -/
theorem le_K_iff {x : X} {c : Γ} : c ≤ S.K x ↔ ∀ d, S.realizes d x → c ≤ S.cost d :=
  le_iInf₂_iff

theorem K_eq_top {x : X} (h : ∀ d, ¬ S.realizes d x) : S.K x = ⊤ :=
  top_unique <| S.le_K_iff.2 fun d hd => absurd hd (h d)

/-- A system is **functional** if a description realizes at most one object
(descriptions are unambiguous). -/
def Functional : Prop := ∀ ⦃d x y⦄, S.realizes d x → S.realizes d y → x = y

/-! ### The fidelity dial -/

/-- Relax the fidelity along a relation `R`: a description realizes `y` as soon as it
realizes some `x` with `R x y`. Covers approximation (`R x y := dist x y ≤ ε`),
coarse-graining (`R x y := π x = y`), properties (`R x P := P x`), and equivalence. -/
def relax {Y : Type v'} (R : X → Y → Prop) : DescSystem D Y Γ where
  cost := S.cost
  realizes d y := ∃ x, S.realizes d x ∧ R x y

/-- **The complexity of a class is the complexity of its simplest member.** -/
theorem K_relax {Y : Type v'} (R : X → Y → Prop) (y : Y) :
    (S.relax R).K y = ⨅ (x : X) (_ : R x y), S.K x := by
  apply le_antisymm
  · refine le_iInf₂ fun x hx => le_iInf₂ fun d hd => ?_
    exact (S.relax R).K_le_cost ⟨x, hd, hx⟩
  · refine le_iInf₂ fun d hd => ?_
    obtain ⟨x, hdx, hx⟩ := hd
    exact (iInf₂_le x hx).trans (S.K_le_cost hdx)

/-- Loosening the fidelity relation can only lower complexity. -/
theorem K_relax_mono {Y : Type v'} {R R' : X → Y → Prop} (h : ∀ x y, R x y → R' x y) (y : Y) :
    (S.relax R').K y ≤ (S.relax R).K y := by
  rw [K_relax, K_relax]
  exact le_iInf₂ fun x hx => iInf₂_le x (h x y hx)

/-- Coarse-graining along a map `π`: the pushed-forward system describes macrostates. -/
def push {Y : Type v'} (π : X → Y) : DescSystem D Y Γ := S.relax fun x y => π x = y

theorem K_push {Y : Type v'} (π : X → Y) (y : Y) :
    (S.push π).K y = ⨅ (x : X) (_ : π x = y), S.K x := S.K_relax _ y

/-- **Coarse-graining never increases complexity**: a macrostate is at most as complex
as any of its microstates. -/
theorem K_push_le {Y : Type v'} (π : X → Y) (x : X) : (S.push π).K (π x) ≤ S.K x := by
  rw [K_push]
  exact iInf₂_le (f := fun x' (_ : π x' = π x) => S.K x') x rfl

/-- Restricting the available descriptions can only raise complexity. -/
def restrict (p : D → Prop) : DescSystem D X Γ where
  cost := S.cost
  realizes d x := p d ∧ S.realizes d x

theorem K_le_K_restrict (p : D → Prop) (x : X) : S.K x ≤ (S.restrict p).K x :=
  (S.restrict p).le_K_iff.2 fun _ hd => S.K_le_cost hd.2

end Lattice

/-! ### Simulations: the morphisms of description systems -/

section Sim

variable {D : Type u} {X : Type v} {Γ : Type w}
  {D' : Type u'} {X' : Type v'} {Γ' : Type w'}

/-- A **simulation** of `S` in `S'` with overhead `f`: a translation of descriptions and of
objects that preserves realization and inflates cost by at most `f`.

Compilers, interpreters, reductions, encodings, coarse-grainings and physical
implementations are all simulations. -/
structure Sim [LE Γ'] (S : DescSystem D X Γ) (S' : DescSystem D' X' Γ') (f : Γ → Γ') where
  /-- Translation of descriptions. -/
  tr : D → D'
  /-- Translation of objects. -/
  ob : X → X'
  /-- Realization is preserved. -/
  realizes' : ∀ {d x}, S.realizes d x → S'.realizes (tr d) (ob x)
  /-- Cost is inflated by at most `f`. -/
  cost_le : ∀ d, S'.cost (tr d) ≤ f (S.cost d)

namespace Sim

variable [CompleteLattice Γ] [CompleteLattice Γ']
  {S : DescSystem D X Γ} {S' : DescSystem D' X' Γ'} {f : Γ → Γ'}

omit [CompleteLattice Γ] in
/-- **Transport, general form.** Along a simulation, the complexity of the image is bounded
by the infimum of the inflated costs. No hypothesis on the overhead is needed. -/
theorem K_le_iInf (h : Sim S S' f) (x : X) :
    S'.K (h.ob x) ≤ ⨅ (d : D) (_ : S.realizes d x), f (S.cost d) :=
  le_iInf₂ fun d hd => (S'.K_le_cost (h.realizes' hd)).trans (h.cost_le d)

/-- **Transport theorem.** If the overhead preserves infima then complexity is lax natural:
`K' (ob x) ≤ f (K x)`. Upper bounds travel forward along a simulation and lower bounds
travel backward. -/
theorem K_le (f : sInfHom Γ Γ') (h : Sim S S' f) (x : X) : S'.K (h.ob x) ≤ f (S.K x) := by
  have := h.K_le_iInf x
  simpa only [K, map_iInf] using this

/-- The identity simulation. -/
def refl (S : DescSystem D X Γ) : Sim S S id where
  tr := id
  ob := id
  realizes' := id
  cost_le _ := le_rfl

/-- Simulations compose, and overheads compose with them. -/
def comp {D'' : Type*} {X'' : Type*} {Γ'' : Type*} [CompleteLattice Γ'']
    {S'' : DescSystem D'' X'' Γ''} {g : Γ' → Γ''}
    (h₂ : Sim S' S'' g) (h₁ : Sim S S' f) (hg : Monotone g) : Sim S S'' (g ∘ f) where
  tr := h₂.tr ∘ h₁.tr
  ob := h₂.ob ∘ h₁.ob
  realizes' hd := h₂.realizes' (h₁.realizes' hd)
  cost_le d := (h₂.cost_le _).trans (hg (h₁.cost_le d))

end Sim

end Sim

/-! ### Extended-natural costs: infima are attained -/

section ENat

variable {D : Type u} {X : Type v} (S : DescSystem D X ℕ∞)

/-- With costs in `ℕ∞`, a finite complexity is attained by an optimal description. -/
theorem exists_cost_eq_K {x : X} (h : S.K x ≠ ⊤) : ∃ d, S.realizes d x ∧ S.cost d = S.K x := by
  by_contra hne
  simp only [not_exists, not_and] at hne
  have h1 : S.K x + 1 ≤ S.K x :=
    S.le_K_iff.2 fun d hd =>
      (ENat.add_one_le_iff h).2 (lt_of_le_of_ne (S.K_le_cost hd) (Ne.symm (hne d hd)))
  exact absurd ((ENat.add_one_le_iff h).1 h1) (lt_irrefl _)

/-- Sublevel characterization: `K x ≤ n` iff some realization costs at most `n`. -/
theorem K_le_coe_iff {x : X} {n : ℕ} : S.K x ≤ n ↔ ∃ d, S.realizes d x ∧ S.cost d ≤ n := by
  constructor
  · intro h
    have hne : S.K x ≠ ⊤ := ne_top_of_le_ne_top (ENat.natCast_ne_top n) h
    obtain ⟨d, hd, hc⟩ := S.exists_cost_eq_K hne
    exact ⟨d, hd, hc ▸ h⟩
  · rintro ⟨d, hd, hc⟩
    exact (S.K_le_cost hd).trans hc

theorem K_ne_top_iff {x : X} : S.K x ≠ ⊤ ↔ ∃ d, S.realizes d x ∧ S.cost d ≠ ⊤ := by
  constructor
  · intro h
    obtain ⟨d, hd, hc⟩ := S.exists_cost_eq_K h
    exact ⟨d, hd, hc ▸ h⟩
  · rintro ⟨d, hd, hc⟩
    exact ne_top_of_le_ne_top hc (S.K_le_cost hd)

/-- **Transport, sublevel form.** Along a simulation with a monotone overhead on naturals,
every budget that suffices for `x` suffices, after inflation, for its image. -/
theorem Sim.K_le_of_K_le {D' : Type u'} {X' : Type v'} {S : DescSystem D X ℕ∞}
    {S' : DescSystem D' X' ℕ∞} {f : ℕ∞ → ℕ∞} (h : Sim S S' f) (hf : Monotone f)
    {x : X} {n : ℕ} (hx : S.K x ≤ n) : S'.K (h.ob x) ≤ f n := by
  obtain ⟨d, hd, hc⟩ := S.K_le_coe_iff.1 hx
  exact (S'.K_le_cost (h.realizes' hd)).trans ((h.cost_le d).trans (hf hc))

end ENat

/-! ### Strict sublevels in linear cost orders -/

section Linear

variable {D : Type u} {X : Type v} {Γ : Type w} [CompleteLinearOrder Γ] (S : DescSystem D X Γ)

/-- In a linearly ordered cost lattice, `K x < c` iff some realization costs less than `c`. -/
theorem K_lt_iff {x : X} {c : Γ} : S.K x < c ↔ ∃ d, S.realizes d x ∧ S.cost d < c := by
  simp only [K, iInf_lt_iff, exists_prop]

end Linear

end DescSystem

end Complexity
