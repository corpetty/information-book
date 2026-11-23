import Complexity.Counting
import Complexity.CostAlgebra

/-!
# Invariance: when is complexity intrinsic?

A complexity measure depends on the description system. It is *intrinsic to a domain*
exactly when the domain has a description system that simulates every other admissible one
at bounded additive overhead: then any two such **universal** systems agree up to an
additive constant, and the constant is the only arbitrariness left.

* `Sim.K_le_add`            – an additive-overhead simulation shifts complexity by at most
                              the constant;
* `Dominates`               – the additive-constant preorder on description systems;
* `invariance`              – **abstract invariance theorem**: systems that each dominate a
                              class containing both are equivalent up to a constant;
* `Interp.K_le_add_of_prefix` – the concrete mechanism for interpreters: a simulation by a
                              fixed prefix costs the length of the prefix;
* `Interp.Universal.invariance` – the Kolmogorov–Solomonoff invariance theorem in its
                              description-system form.

The theorem also says where intrinsic complexity *fails*: a domain with no universal
system (no description language into which all others translate at bounded cost) has no
observer-independent complexity, only a family of mutually distorted ones.

**Review note.** `Dominates` is *defined* as the inequality between complexities, so
`invariance` is two instances of its hypotheses with the larger constant; and a system
with all costs zero dominates everything. The theorem has content only relative to a
class of admissible systems fixed from outside (`Limits.dominates_iff_pointwise`). Only
the "if" direction of "exactly when" above is proved. `Translation.lean` gives the
non-circular form (`invariance_of_simulates`, with domination replaced by simulation
through admissible translations) and proves that without a restricted class there is no
universal system at all (`not_exists_universal`).
-/

namespace Complexity

namespace DescSystem

universe u v w u' v'

section Additive

variable {D : Type u} {X : Type v} {D' : Type u'} {X' : Type v'} {Γ : Type w}
  [CompleteLattice Γ] [AddCommMonoid Γ] [IsCostAlgebra Γ]

/-- A simulation with additive overhead `c` raises complexity by at most `c`. -/
theorem Sim.K_le_add {S : DescSystem D X Γ} {S' : DescSystem D' X' Γ} {c : Γ}
    (h : Sim S S' (· + c)) (x : X) : S'.K (h.ob x) ≤ S.K x + c := by
  have := h.K_le_iInf x
  simpa only [K, CostAlgebra.iInf_add] using this

end Additive

variable {D : Type u} {D' : Type u'} {X : Type v}

/-- `S'` **dominates** `S`: it describes everything at most a constant more expensively. -/
def Dominates (S' : DescSystem D' X ℕ∞) (S : DescSystem D X ℕ∞) : Prop :=
  ∃ c : ℕ, ∀ x, S'.K x ≤ S.K x + c

theorem Dominates.refl (S : DescSystem D X ℕ∞) : Dominates S S := ⟨0, fun x => by simp⟩

theorem Dominates.trans {D'' : Type*} {S₃ : DescSystem D'' X ℕ∞} {S₂ : DescSystem D' X ℕ∞}
    {S₁ : DescSystem D X ℕ∞} (h₃₂ : Dominates S₃ S₂) (h₂₁ : Dominates S₂ S₁) :
    Dominates S₃ S₁ := by
  obtain ⟨c, hc⟩ := h₃₂
  obtain ⟨c', hc'⟩ := h₂₁
  refine ⟨c' + c, fun x => ?_⟩
  calc S₃.K x ≤ S₂.K x + c := hc x
    _ ≤ S₁.K x + c' + c := add_le_add (hc' x) le_rfl
    _ = S₁.K x + ((c' + c : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]

/-- An additive simulation that fixes the objects yields domination. -/
theorem Sim.dominates {S : DescSystem D X ℕ∞} {S' : DescSystem D' X ℕ∞} {c : ℕ}
    (h : Sim S S' (· + (c : ℕ∞))) (hob : ∀ x, h.ob x = x) : Dominates S' S :=
  ⟨c, fun x => by simpa [hob x] using h.K_le_add x⟩

/-- **Abstract invariance theorem.** If `U` and `U'` both belong to a class of description
systems and each dominates every member of the class, their complexities differ by at
most a constant. -/
theorem invariance (𝓒 : Set (DescSystem D X ℕ∞)) {U U' : DescSystem D X ℕ∞}
    (hU : U ∈ 𝓒) (hU' : U' ∈ 𝓒) (h : ∀ S ∈ 𝓒, Dominates U S) (h' : ∀ S ∈ 𝓒, Dominates U' S) :
    ∃ c : ℕ, ∀ x, U.K x ≤ U'.K x + c ∧ U'.K x ≤ U.K x + c := by
  obtain ⟨c, hc⟩ := h U' hU'
  obtain ⟨c', hc'⟩ := h' U hU
  refine ⟨max c c', fun x => ⟨(hc x).trans ?_, (hc' x).trans ?_⟩⟩
  · exact add_le_add le_rfl (by exact_mod_cast le_max_left c c')
  · exact add_le_add le_rfl (by exact_mod_cast le_max_right c c')

/-- Domination transfers lower bounds: what is incompressible for the dominating system is
incompressible, up to the constant, for the dominated one. -/
theorem Dominates.le_of_le {S' : DescSystem D' X ℕ∞} {S : DescSystem D X ℕ∞}
    (h : Dominates S' S) : ∃ c : ℕ, ∀ x (n : ℕ), (n : ℕ∞) + c ≤ S'.K x → (n : ℕ∞) ≤ S.K x := by
  obtain ⟨c, hc⟩ := h
  refine ⟨c, fun x n hn => ?_⟩
  have h1 : (n : ℕ∞) + c ≤ S.K x + c := hn.trans (hc x)
  exact (ENat.add_le_add_iff_right (ENat.natCast_ne_top c)).1 h1

end DescSystem

/-! ### Interpreters -/

namespace Interp

variable {X : Type*}

/-- The description system of an **interpreter**: programs are bit strings, the cost of a
program is its length, and a program describes its output. -/
def sys (U : List Bool → Option X) : DescSystem (List Bool) X ℕ∞ where
  cost l := l.length
  realizes l x := U l = some x

theorem sys_isBinary (U : List Bool → Option X) : (sys U).IsBinary := fun _ => rfl

theorem sys_functional (U : List Bool → Option X) : (sys U).Functional :=
  fun _ _ _ hx hy => Option.some.inj (hx.symm.trans hy)

/-- **Description complexity** relative to the interpreter `U` (Kolmogorov complexity when
`U` is a universal machine). -/
noncomputable def K (U : List Bool → Option X) (x : X) : ℕ∞ := (sys U).K x

/-- If `U` runs `V` when given the prefix `p`, then `U`-complexity exceeds `V`-complexity
by at most the length of `p`. -/
theorem K_le_add_of_prefix (U V : List Bool → Option X) (p : List Bool)
    (h : ∀ l, U (p ++ l) = V l) (x : X) : K U x ≤ K V x + p.length := by
  let s : DescSystem.Sim (sys V) (sys U) (· + (p.length : ℕ∞)) :=
    { tr := fun l => p ++ l
      ob := id
      realizes' := fun {l x} hl => (h l).trans hl
      cost_le := fun l => by
        show ((p ++ l).length : ℕ∞) ≤ (l.length : ℕ∞) + (p.length : ℕ∞)
        rw [List.length_append]
        push_cast
        rw [add_comm] }
  exact s.K_le_add x

/-- `U` is **universal** for a class of interpreters: it belongs to the class and runs every
member of the class from a fixed prefix. -/
def Universal (U : List Bool → Option X) (𝓒 : Set (List Bool → Option X)) : Prop :=
  U ∈ 𝓒 ∧ ∀ V ∈ 𝓒, ∃ p : List Bool, ∀ l, U (p ++ l) = V l

/-- **Invariance theorem.** The complexities defined by two universal interpreters differ
by at most an additive constant. -/
theorem Universal.invariance {U U' : List Bool → Option X} {𝓒 : Set (List Bool → Option X)}
    (hU : Universal U 𝓒) (hU' : Universal U' 𝓒) :
    ∃ c : ℕ, ∀ x, K U x ≤ K U' x + c ∧ K U' x ≤ K U x + c := by
  obtain ⟨p, hp⟩ := hU.2 U' hU'.1
  obtain ⟨p', hp'⟩ := hU'.2 U hU.1
  refine ⟨max p.length p'.length, fun x => ⟨?_, ?_⟩⟩
  · exact (K_le_add_of_prefix U U' p hp x).trans
      (add_le_add le_rfl (by exact_mod_cast le_max_left _ _))
  · exact (K_le_add_of_prefix U' U p' hp' x).trans
      (add_le_add le_rfl (by exact_mod_cast le_max_right _ _))

/-- **Incompressibility** for every interpreter: among any `2 ^ n` objects, one has
description complexity at least `n`. -/
theorem exists_incompressible (U : List Bool → Option X) (n : ℕ) (A : Finset X)
    (hA : 2 ^ n ≤ A.card) : ∃ x ∈ A, (n : ℕ∞) ≤ K U x :=
  (sys_isBinary U).exists_incompressible (sys_functional U) n A hA

/-- Compressible objects are exponentially rare for every interpreter. -/
theorem card_compressible_lt (U : List Bool → Option X) (m : ℕ) (A : Finset X)
    [DecidablePred fun x => (sys U).K x < m] :
    (A.filter fun x => (sys U).K x < m).card < 2 ^ m :=
  (sys_isBinary U).card_compressible_lt (sys_functional U) m A

end Interp

end Complexity
