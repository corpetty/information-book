import Complexity.Basic

/-!
# Profiles: complexity with several resources

Descriptions usually cost several things at once: length *and* running time, model size
*and* residual, size *and* depth, matter *and* energy *and* time. With a vector-valued
cost there is no single least cost. The right invariant is the **profile**: the set of all
cost vectors at which the object can be realized. Its lower boundary is the Pareto
frontier of trade-offs.

* `profile_eq_K`       – the profile *is* the complexity `K`, computed in the lattice of
                         sets of cost vectors ordered by reverse inclusion. Nothing new had
                         to be defined;
* `K_mapCost`          – every scalar complexity is a **section** of the profile: the
                         infimum of one functional over it. Fields that disagree about "the"
                         complexity of an object are reading different coordinates of one
                         profile;
* `image_profile_subset` – transport: a simulation shifts profiles;
* `slackMin`           – the **slack-constrained secondary minimum**. Applied to
                         (length, time) it is Bennett's logical depth; applied to
                         (model + residual, model) it is sophistication / effective
                         complexity. "Depth" and "structure" are the same construction on
                         different coordinates.
-/

namespace Complexity

namespace DescSystem

universe u v w w'

variable {D : Type u} {X : Type v} {V : Type w}

/-- The **profile** of `x`: all cost vectors at which `x` can be realized. -/
def profile (S : DescSystem D X V) (x : X) : Set V :=
  {v | ∃ d, S.realizes d x ∧ S.cost d = v}

/-- Change the cost along a map: read one coordinate (or any functional) of the cost. -/
def mapCost {Γ : Type w'} (S : DescSystem D X V) (f : V → Γ) : DescSystem D X Γ where
  cost d := f (S.cost d)
  realizes := S.realizes

theorem mem_profile {S : DescSystem D X V} {x : X} {d : D} (h : S.realizes d x) :
    S.cost d ∈ S.profile x := ⟨d, h, rfl⟩

/-- **Every scalar complexity is a section of the profile.** -/
theorem K_mapCost {Γ : Type w'} [CompleteLattice Γ] (S : DescSystem D X V) (f : V → Γ) (x : X) :
    (S.mapCost f).K x = ⨅ v ∈ S.profile x, f v := by
  apply le_antisymm
  · refine le_iInf₂ fun v hv => ?_
    obtain ⟨d, hd, rfl⟩ := hv
    exact (S.mapCost f).K_le_cost (d := d) hd
  · exact (S.mapCost f).le_K_iff.2 fun d hd => iInf₂_le (S.cost d) (mem_profile hd)

/-- **The profile is the complexity**, taken in the lattice of sets of cost vectors under
reverse inclusion (where "smaller" means "achievable in more ways"). -/
theorem profile_eq_K (S : DescSystem D X V) (x : X) :
    S.profile x =
      OrderDual.ofDual ((S.mapCost fun v => OrderDual.toDual ({v} : Set V)).K x) := by
  ext v
  simp only [K, mapCost, ofDual_iInf, OrderDual.ofDual_toDual, Set.iSup_eq_iUnion,
    Set.mem_iUnion, Set.mem_singleton_iff, profile, Set.mem_ofPred_eq, exists_prop]
  constructor
  · rintro ⟨d, hd, rfl⟩
    exact ⟨d, hd, rfl⟩
  · rintro ⟨d, hd, rfl⟩
    exact ⟨d, hd, rfl⟩

/-- **Transport of profiles.** A translation of descriptions that preserves realization
and changes cost vectors by `f` maps the profile of `x` into that of its image. With
`f = (· + (c, t))` this is the profile form of slow-growth laws: processing shifts the
whole trade-off frontier by at most the cost of the process. -/
theorem image_profile_subset {D' : Type*} {X' : Type*} {V' : Type*} {S : DescSystem D X V}
    {S' : DescSystem D' X' V'} (tr : D → D') (ob : X → X') (f : V → V')
    (hr : ∀ d x, S.realizes d x → S'.realizes (tr d) (ob x))
    (hc : ∀ d, S'.cost (tr d) = f (S.cost d)) (x : X) :
    f '' S.profile x ⊆ S'.profile (ob x) := by
  rintro _ ⟨v, ⟨d, hd, rfl⟩, rfl⟩
  exact ⟨tr d, hr d x hd, hc d⟩

/-- **Slack-constrained secondary minimum**: among the realizations whose primary cost is
within `s` of the optimum, the least secondary cost.

* primary = length, secondary = time: **logical depth** at significance `s`;
* primary = model + residual, secondary = model: **sophistication** / effective complexity;
* primary = size, secondary = depth: the depth of near-minimal circuits. -/
noncomputable def slackMin (S : DescSystem D X V) (primary secondary : V → ℕ∞) (s : ℕ∞)
    (x : X) : ℕ∞ :=
  ⨅ v ∈ S.profile x, ⨅ (_ : primary v ≤ (S.mapCost primary).K x + s), secondary v

/-- The constrained minimum is at least the unconstrained one. -/
theorem K_secondary_le_slackMin (S : DescSystem D X V) (primary secondary : V → ℕ∞) (s : ℕ∞)
    (x : X) : (S.mapCost secondary).K x ≤ S.slackMin primary secondary s x := by
  rw [K_mapCost]
  exact le_iInf₂ fun v hv => le_iInf fun _ => iInf₂_le v hv

/-- More slack can only lower the secondary cost. -/
theorem slackMin_anti (S : DescSystem D X V) (primary secondary : V → ℕ∞) {s s' : ℕ∞}
    (h : s ≤ s') (x : X) :
    S.slackMin primary secondary s' x ≤ S.slackMin primary secondary s x := by
  refine le_iInf₂ fun v hv => le_iInf fun hs => ?_
  exact iInf₂_le_of_le v hv (iInf_le _ (hs.trans (add_le_add le_rfl h)))

/-- With unlimited slack the constraint disappears. -/
theorem slackMin_top (S : DescSystem D X V) (primary secondary : V → ℕ∞) (x : X) :
    S.slackMin primary secondary ⊤ x = (S.mapCost secondary).K x := by
  apply le_antisymm
  · rw [K_mapCost]
    exact le_iInf₂ fun v hv => iInf₂_le_of_le v hv (iInf_le _ (by simp))
  · exact K_secondary_le_slackMin S primary secondary ⊤ x

/-- **Logical depth** at significance `s` of a system whose cost vectors are
`(length, time)`: the least running time among descriptions within `s` of the shortest. -/
noncomputable def depth (S : DescSystem D X (ℕ × ℕ)) (s : ℕ∞) (x : X) : ℕ∞ :=
  S.slackMin (fun v => (v.1 : ℕ∞)) (fun v => (v.2 : ℕ∞)) s x

/-- **Sophistication** at significance `s` of a two-part system whose cost vectors are
`(model, residual)`: the least model size among descriptions within `s` of the shortest
total. -/
noncomputable def sophistication (S : DescSystem D X (ℕ × ℕ)) (s : ℕ∞) (x : X) : ℕ∞ :=
  S.slackMin (fun v => ((v.1 + v.2 : ℕ) : ℕ∞)) (fun v => (v.1 : ℕ∞)) s x

end DescSystem

end Complexity
