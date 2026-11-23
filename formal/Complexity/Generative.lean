import Complexity.Basic
import Complexity.CostAlgebra

/-!
# Generative systems: complexity as a greatest fixed point

A **generative system** is a signature of operations (of any arity) acting on a set of
objects: gates on Boolean functions, joins on molecules, productions on strings, inference
rules on theorems, reactions on species, multiplication on a monoid.

Descriptions are the *terms* of the signature – the initial algebra – and a term denotes
the object it evaluates to. A **cost rule** says how the cost of a composite depends on
the costs of its parts (`size`: add them; `depth`: take the maximum; anything monotone).

**Tree complexity** is the least cost of a term denoting the object.

Main results, valid for every signature, every algebra and every monotone cost rule:

* `IsPotential.le_treeK`   – every potential is a lower bound (the general form of
                             "formal complexity measure" arguments);
* `treeK_isPotential`      – tree complexity is itself a potential;
* `bellman_treeK`          – the **Bellman equation**: the complexity of an object is the
                             cheapest way of assembling it from parts, priced at *their*
                             complexities;
* `treeK_eq_gfp`           – tree complexity is the **greatest fixed point** of the Bellman
                             operator: it is characterized without mentioning syntax;
* `treeK_map_le`           – **homomorphisms never increase complexity**;
* `treeK_depth_le_size`    – cost rules are comparable dials on the same structure.
-/

namespace Complexity

universe u v w w'

/-- A **signature**: operation symbols with their arities. -/
structure Sig where
  /-- Operation symbols. -/
  Op : Type u
  /-- The arity (type of argument positions) of each operation. -/
  Ar : Op → Type v

namespace Sig

variable (S : Sig.{u, v})

/-- **Syntax**: the terms of the signature (its initial algebra). -/
abbrev Term : Type (max u v) := WType S.Ar

/-- An **algebra** for the signature: an interpretation of every operation on `X`. -/
def Alg (X : Type w) : Type (max u v w) := (a : S.Op) → (S.Ar a → X) → X

/-- A **cost rule**: `κ a cs` is the cost of applying operation `a` to parts costing `cs`.
It must be monotone, and applying an operation to an unobtainable part is unobtainable. -/
structure CostRule where
  /-- The cost of a composite in terms of the costs of its parts. -/
  κ : (a : S.Op) → (S.Ar a → ℕ∞) → ℕ∞
  /-- Cheaper parts never make the whole more expensive. -/
  mono : ∀ (a : S.Op) (c c' : S.Ar a → ℕ∞), (∀ b, c b ≤ c' b) → κ a c ≤ κ a c'
  /-- A composite with an unobtainable part is unobtainable. -/
  strict : ∀ (a : S.Op) (c : S.Ar a → ℕ∞), (∃ b, c b = ⊤) → κ a c = ⊤

variable {S} {X : Type w}

/-- **Semantics**: evaluation of a term in an algebra (the unique homomorphism out of the
initial algebra). -/
def eval (alg : S.Alg X) : S.Term → X
  | ⟨a, f⟩ => alg a fun b => eval alg (f b)

/-- The **cost** of a term under a cost rule (the unique homomorphism into the cost
algebra). -/
def cost (R : S.CostRule) : S.Term → ℕ∞
  | ⟨a, f⟩ => R.κ a fun b => cost R (f b)

@[simp] theorem eval_mk (alg : S.Alg X) (a : S.Op) (f : S.Ar a → S.Term) :
    eval alg (WType.mk a f) = alg a fun b => eval alg (f b) := by
  rw [eval]

@[simp] theorem cost_mk (R : S.CostRule) (a : S.Op) (f : S.Ar a → S.Term) :
    cost R (WType.mk a f) = R.κ a fun b => cost R (f b) := by
  rw [cost]

/-- Terms as a description system: a term describes the object it evaluates to. -/
def termSystem (alg : S.Alg X) (R : S.CostRule) : DescSystem S.Term X ℕ∞ where
  cost := cost R
  realizes t x := eval alg t = x

/-- **Tree complexity**: the least cost of a term denoting `x`. Formula size, parse-tree
size, proof-tree size and derivation depth are all of this form. -/
noncomputable def treeK (alg : S.Alg X) (R : S.CostRule) (x : X) : ℕ∞ :=
  (termSystem alg R).K x

theorem treeK_le_cost (alg : S.Alg X) (R : S.CostRule) (t : S.Term) :
    treeK alg R (eval alg t) ≤ cost R t :=
  (termSystem alg R).K_le_cost (d := t) rfl

/-! ### Potentials and the Bellman characterization -/

/-- A **potential** for a generative system: a quantity that an operation can never raise
above what the cost rule charges for the potentials of the parts. -/
def IsPotential (alg : S.Alg X) (R : S.CostRule) (φ : X → ℕ∞) : Prop :=
  ∀ (a : S.Op) (xs : S.Ar a → X), φ (alg a xs) ≤ R.κ a fun b => φ (xs b)

theorem IsPotential.le_cost {alg : S.Alg X} {R : S.CostRule} {φ : X → ℕ∞}
    (h : IsPotential alg R φ) : ∀ t : S.Term, φ (eval alg t) ≤ cost R t
  | ⟨a, f⟩ => by
      rw [eval_mk, cost_mk]
      exact (h a _).trans (R.mono a _ _ fun b => IsPotential.le_cost h (f b))

/-- **Weak duality.** Every potential is a lower bound on tree complexity. -/
theorem IsPotential.le_treeK {alg : S.Alg X} {R : S.CostRule} {φ : X → ℕ∞}
    (h : IsPotential alg R φ) (x : X) : φ x ≤ treeK alg R x :=
  (termSystem alg R).le_K_iff.2 fun t ht => by
    have : eval alg t = x := ht
    subst this
    exact h.le_cost t

/-- **Strong duality, part one.** Tree complexity is itself a potential: assembling from
optimally built parts costs no more than the rule charges. -/
theorem treeK_isPotential (alg : S.Alg X) (R : S.CostRule) : IsPotential alg R (treeK alg R) := by
  intro a xs
  by_cases htop : ∃ b, treeK alg R (xs b) = ⊤
  · rw [R.strict a _ htop]
    exact le_top
  · simp only [not_exists] at htop
    choose t ht hc using fun b => (termSystem alg R).exists_cost_eq_K (htop b)
    have h1 : eval alg (WType.mk a t) = alg a xs := by
      rw [eval_mk]
      congr 1
      funext b
      exact ht b
    have h2 : cost R (WType.mk a t) = R.κ a fun b => treeK alg R (xs b) := by
      rw [cost_mk]
      congr 1
      funext b
      exact hc b
    rw [← h1, ← h2]
    exact treeK_le_cost alg R _

/-- **Strong duality.** Tree complexity is the greatest potential. -/
theorem isGreatest_treeK (alg : S.Alg X) (R : S.CostRule) :
    IsGreatest {φ : X → ℕ∞ | IsPotential alg R φ} (treeK alg R) :=
  ⟨treeK_isPotential alg R, fun _ hφ x => hφ.le_treeK x⟩

/-- The **Bellman operator** of a generative system: price `x` at its cheapest one-step
decomposition, with the parts priced by `φ`. -/
noncomputable def bellman (alg : S.Alg X) (R : S.CostRule) (φ : X → ℕ∞) (x : X) : ℕ∞ :=
  ⨅ (a : S.Op) (xs : S.Ar a → X) (_ : alg a xs = x), R.κ a fun b => φ (xs b)

theorem isPotential_iff_le_bellman {alg : S.Alg X} {R : S.CostRule} {φ : X → ℕ∞} :
    IsPotential alg R φ ↔ φ ≤ bellman alg R φ := by
  constructor
  · intro h x
    refine le_iInf fun a => le_iInf fun xs => le_iInf fun hx => ?_
    subst hx
    exact h a xs
  · intro h a xs
    exact (h (alg a xs)).trans (iInf_le_of_le a (iInf_le_of_le xs (iInf_le _ rfl)))

theorem bellman_mono (alg : S.Alg X) (R : S.CostRule) : Monotone (bellman alg R) := by
  intro φ ψ h x
  exact iInf_mono fun a => iInf_mono fun xs => iInf_mono fun _ => R.mono a _ _ fun b => h (xs b)

/-- **Bellman equation.** The complexity of an object is the least, over all ways of
obtaining it in one step from parts, of the rule's charge for the *complexities* of those
parts. -/
theorem bellman_treeK (alg : S.Alg X) (R : S.CostRule) :
    bellman alg R (treeK alg R) = treeK alg R := by
  apply le_antisymm
  · intro x
    refine (termSystem alg R).le_K_iff.2 fun t ht => ?_
    have hx : eval alg t = x := ht
    subst hx
    obtain ⟨a, f⟩ := t
    rw [eval_mk]
    refine (iInf_le_of_le a (iInf_le_of_le (fun b => eval alg (f b)) (iInf_le _ rfl))).trans ?_
    show (R.κ a fun b => treeK alg R (eval alg (f b))) ≤ cost R (WType.mk a f)
    rw [cost_mk]
    exact R.mono a _ _ fun b => treeK_le_cost alg R (f b)
  · exact isPotential_iff_le_bellman.1 (treeK_isPotential alg R)

/-- **Complexity is the greatest fixed point of the Bellman operator.** This characterizes
tree complexity with no reference to syntax: it is the largest self-consistent pricing. -/
theorem treeK_eq_gfp (alg : S.Alg X) (R : S.CostRule) :
    treeK alg R = OrderHom.gfp ⟨bellman alg R, bellman_mono alg R⟩ := by
  apply le_antisymm
  · exact OrderHom.le_gfp _ (isPotential_iff_le_bellman.1 (treeK_isPotential alg R))
  · exact OrderHom.gfp_le _ fun φ hφ x => (isPotential_iff_le_bellman.2 hφ).le_treeK x

/-! ### Transport along homomorphisms and comparison of cost rules -/

theorem eval_map {Y : Type w'} {algX : S.Alg X} {algY : S.Alg Y} (h : X → Y)
    (hh : ∀ (a : S.Op) (xs : S.Ar a → X), h (algX a xs) = algY a fun b => h (xs b)) :
    ∀ t : S.Term, eval algY t = h (eval algX t)
  | ⟨a, f⟩ => by
      rw [eval_mk, eval_mk, hh]
      congr 1
      funext b
      exact eval_map h hh (f b)

/-- **Homomorphisms never increase complexity.** Coarse-grainings, abstractions,
quotients, readouts and observables that commute with the operations can only make
objects simpler. Emergence – a macroscopic description strictly simpler than any
microscopic one – is the case of strict inequality. -/
theorem treeK_map_le {Y : Type w'} {algX : S.Alg X} {algY : S.Alg Y} (R : S.CostRule) (h : X → Y)
    (hh : ∀ (a : S.Op) (xs : S.Ar a → X), h (algX a xs) = algY a fun b => h (xs b)) (x : X) :
    treeK algY R (h x) ≤ treeK algX R x :=
  (termSystem algX R).le_K_iff.2 fun t ht => by
    have hx : eval algX t = x := ht
    subst hx
    rw [← eval_map h hh t]
    exact treeK_le_cost algY R t

theorem cost_le_cost {R R' : S.CostRule} (h : ∀ a c, R.κ a c ≤ R'.κ a c) :
    ∀ t : S.Term, cost R t ≤ cost R' t
  | ⟨a, f⟩ => by
      rw [cost_mk, cost_mk]
      exact (R.mono a _ _ fun b => cost_le_cost h (f b)).trans (h a _)

/-- A cheaper cost rule gives a smaller complexity. -/
theorem treeK_mono_rule (alg : S.Alg X) {R R' : S.CostRule} (h : ∀ a c, R.κ a c ≤ R'.κ a c)
    (x : X) : treeK alg R x ≤ treeK alg R' x :=
  (termSystem alg R').le_K_iff.2 fun t ht =>
    ((termSystem alg R).K_le_cost (d := t) ht).trans (cost_le_cost h t)

/-! ### The two standard cost rules -/

/-- **Size**: every operation has a weight and the costs of the parts add. -/
def sizeRule (S : Sig.{u, v}) [∀ a, Fintype (S.Ar a)] (wt : S.Op → ℕ∞) : S.CostRule where
  κ a c := wt a + ∑ b, c b
  mono a c c' h := by
    gcongr
    exact h _
  strict a c := by
    rintro ⟨b, hb⟩
    have h1 : (⊤ : ℕ∞) ≤ ∑ b, c b :=
      hb ▸ Finset.single_le_sum (fun _ _ => CostAlgebra.zero_le _) (Finset.mem_univ b)
    rw [top_le_iff.1 h1, add_top]

/-- **Depth**: every operation has a weight and the costs of the parts are combined by
maximum (parts are built in parallel). -/
noncomputable def depthRule (S : Sig.{u, v}) (wt : S.Op → ℕ∞) : S.CostRule where
  κ a c := wt a + ⨆ b, c b
  mono a c c' h := by
    gcongr
    exact h _
  strict a c := by
    rintro ⟨b, hb⟩
    have h1 : (⊤ : ℕ∞) ≤ ⨆ b, c b := hb ▸ le_iSup c b
    rw [top_le_iff.1 h1, add_top]

/-- **Depth is at most size**: parallel time never exceeds total work. -/
theorem treeK_depth_le_size [∀ a, Fintype (S.Ar a)] (alg : S.Alg X) (wt : S.Op → ℕ∞) (x : X) :
    treeK alg (depthRule S wt) x ≤ treeK alg (sizeRule S wt) x := by
  refine treeK_mono_rule alg (fun a c => ?_) x
  show wt a + ⨆ b, c b ≤ wt a + ∑ b, c b
  gcongr
  exact iSup_le fun b =>
    Finset.single_le_sum (fun _ _ => CostAlgebra.zero_le _) (Finset.mem_univ b)

end Sig

end Complexity
