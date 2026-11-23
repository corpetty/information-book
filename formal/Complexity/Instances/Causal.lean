import Complexity.Basic

/-!
# Instance: causal states – statistical complexity as model size

Computational mechanics asks for the smallest model that predicts a process optimally. Let
`fut : H → F` send each history to its future behaviour (for a stochastic process: its
conditional distribution over futures). A **model** is a state map `H → Fin n` together
with a readout `Fin n → F` that reproduces `fut`: its states are a sufficient statistic of
the past for the future.

With models as descriptions and the number of states as cost, the complexity of the
process is exactly the number of **causal states** – the classes of histories with the
same future. This is the counting core of Myhill–Nerode and of ε-machine minimality
(see the review note below for what is missing).

* `Model.refines`      – every sufficient model refines the causal partition;
* `Model.card_range_le` – so it has at least as many states as there are causal states;
* `exists_minimal`     – and the causal states themselves form a model;
* `K_eq_ncard`         – hence `K(process) = #causal states`.

**Review note.** What is proved is that the least number of values of a sufficient statistic
of the past equals the number of distinct futures. Histories carry no sequence structure
and models no transition map, so this is neither Myhill–Nerode nor ε-machine minimality,
and the cost is a count, not the entropy `C_μ`. No general law is used.
-/

namespace Complexity

namespace Causal

variable {H F : Type*}

/-- A **model** of `fut` with `n` states: a state map and a readout reproducing `fut`. -/
structure Model (fut : H → F) (n : ℕ) where
  /-- The state the model is in after a history. -/
  state : H → Fin n
  /-- The prediction made from a state. -/
  readout : Fin n → F
  /-- The model predicts correctly. -/
  sound : ∀ h, readout (state h) = fut h

/-- Every sufficient model **refines the causal partition**: histories it does not
distinguish have the same future. -/
theorem Model.refines {fut : H → F} {n : ℕ} (M : Model fut n) {h h' : H}
    (hh : M.state h = M.state h') : fut h = fut h' := by
  rw [← M.sound h, ← M.sound h', hh]

/-- A model has at least as many states as there are causal states. -/
theorem Model.card_range_le {fut : H → F} {n : ℕ} (M : Model fut n) :
    (Set.range fut).ncard ≤ n := by
  have hsub : Set.range fut ⊆ Set.range M.readout := by
    rintro _ ⟨h, rfl⟩
    exact ⟨M.state h, M.sound h⟩
  calc (Set.range fut).ncard ≤ (Set.range M.readout).ncard :=
        Set.ncard_le_ncard hsub (Set.finite_range _)
    _ = (M.readout '' Set.univ).ncard := by rw [Set.image_univ]
    _ ≤ (Set.univ : Set (Fin n)).ncard := Set.ncard_image_le Set.finite_univ
    _ = n := by simp

/-- The causal states form a model: the minimal one. -/
theorem exists_minimal (fut : H → F) (hfin : (Set.range fut).Finite) :
    Nonempty (Model fut (Set.range fut).ncard) := by
  have : Finite (Set.range fut) := hfin
  have e : Set.range fut ≃ Fin (Set.range fut).ncard := Finite.equivFin (Set.range fut)
  exact ⟨⟨fun h => e ⟨fut h, h, rfl⟩, fun i => (e.symm i).1, fun h => by simp⟩⟩

/-- Models as descriptions of the process; the cost of a model is its number of states. -/
def modelSystem (fut : H → F) : DescSystem (Σ n : ℕ, Model fut n) Unit ℕ∞ where
  cost d := d.1
  realizes _ _ := True

/-- **Statistical complexity (topological form).** The complexity of a process, measured
by the size of its smallest sufficient model, is the number of its causal states. -/
theorem K_eq_ncard (fut : H → F) (hfin : (Set.range fut).Finite) :
    (modelSystem fut).K () = (Set.range fut).ncard := by
  apply le_antisymm
  · obtain ⟨M⟩ := exists_minimal fut hfin
    exact (modelSystem fut).K_le_cost (d := ⟨_, M⟩) trivial
  · refine (modelSystem fut).le_K_iff.2 fun d _ => ?_
    show ((Set.range fut).ncard : ℕ∞) ≤ (d.1 : ℕ∞)
    exact_mod_cast d.2.card_range_le

end Causal

end Complexity
