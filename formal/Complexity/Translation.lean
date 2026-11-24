import Complexity.Invariance

/-!
# Translations: domination with a mechanism

`Dominates S' S` is *defined* as `K_{S'} ≤ K_S + c`, which makes the abstract invariance
theorem a restatement of its hypotheses (`Limits.dominates_iff_pointwise`). This file
replaces the inequality by its cause. Fix a class `𝒯` of **admissible translations** of
descriptions (prefixing by a fixed header; computable maps; compilers a given device can
run). `S'` *simulates* `S` when one admissible translation turns every `S`-description
into an `S'`-description of the same object at constant extra cost.

* `Simulates.dominates`   – simulation implies the inequality (transport);
* `Simulates.refl`, `Simulates.trans` – a preorder whenever `𝒯` contains the identity and
                            is closed under composition;
* `invariance_of_simulates` – **invariance**: two systems that each simulate the whole of a
                            class containing both differ by a constant. The hypothesis is
                            now a statement about translators, not about `K`;
* `exists_dominates_not_simulates` – the notion is strictly stronger than the inequality:
                            two systems with *equal* complexity functions, neither of
                            which simulates the other by prefixing;
* `not_exists_universal`  – and the restriction is necessary: among *all* unambiguous
                            binary systems on an infinite set none dominates the rest.
                            Intrinsic complexity exists only relative to a restricted
                            class of systems (computable ones, in the classical case).
-/

namespace Complexity

namespace DescSystem

variable {D D' D'' X : Type*}

/-- `S'` **simulates** `S` through the admissible translations `𝒯`: one translation in `𝒯`
carries every description to a description of the same object, at constant extra cost. -/
def Simulates (𝒯 : Set (D → D')) (S' : DescSystem D' X ℕ∞) (S : DescSystem D X ℕ∞) : Prop :=
  ∃ c : ℕ, ∃ tr ∈ 𝒯, ∀ d, (∀ x, S.realizes d x → S'.realizes (tr d) x) ∧
    S'.cost (tr d) ≤ S.cost d + c

/-- **Transport**: simulation implies domination. -/
theorem Simulates.dominates {𝒯 : Set (D → D')} {S' : DescSystem D' X ℕ∞}
    {S : DescSystem D X ℕ∞} (h : Simulates 𝒯 S' S) : Dominates S' S := by
  obtain ⟨c, tr, -, htr⟩ := h
  let s : Sim S S' (· + (c : ℕ∞)) :=
    { tr := tr
      ob := id
      realizes' := fun {d x} hd => (htr d).1 x hd
      cost_le := fun d => (htr d).2 }
  exact s.dominates fun _ => rfl

theorem Simulates.mono {𝒯 𝒯' : Set (D → D')} (h𝒯 : 𝒯 ⊆ 𝒯') {S' : DescSystem D' X ℕ∞}
    {S : DescSystem D X ℕ∞} (h : Simulates 𝒯 S' S) : Simulates 𝒯' S' S := by
  obtain ⟨c, tr, hmem, htr⟩ := h
  exact ⟨c, tr, h𝒯 hmem, htr⟩

theorem Simulates.refl {𝒯 : Set (D → D)} (hid : id ∈ 𝒯) (S : DescSystem D X ℕ∞) :
    Simulates 𝒯 S S :=
  ⟨0, id, hid, fun d => ⟨fun _ h => h, by simp⟩⟩

theorem Simulates.trans {𝒯₁ : Set (D → D')} {𝒯₂ : Set (D' → D'')} {𝒯₃ : Set (D → D'')}
    (hcomp : ∀ g ∈ 𝒯₂, ∀ f ∈ 𝒯₁, g ∘ f ∈ 𝒯₃) {S₃ : DescSystem D'' X ℕ∞}
    {S₂ : DescSystem D' X ℕ∞} {S₁ : DescSystem D X ℕ∞} (h₃₂ : Simulates 𝒯₂ S₃ S₂)
    (h₂₁ : Simulates 𝒯₁ S₂ S₁) : Simulates 𝒯₃ S₃ S₁ := by
  obtain ⟨c, g, hg, hg'⟩ := h₃₂
  obtain ⟨c', f, hf, hf'⟩ := h₂₁
  refine ⟨c' + c, g ∘ f, hcomp g hg f hf, fun d => ⟨fun x hx => (hg' _).1 x ((hf' d).1 x hx), ?_⟩⟩
  calc S₃.cost (g (f d)) ≤ S₂.cost (f d) + c := (hg' _).2
    _ ≤ S₁.cost d + c' + c := add_le_add (hf' d).2 le_rfl
    _ = S₁.cost d + ((c' + c : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]

/-- **Invariance theorem, with a mechanism.** If `U` and `U'` belong to a class of systems
and each simulates every member of the class by an admissible translation, their
complexities differ by at most a constant. -/
theorem invariance_of_simulates (𝓒 : Set (DescSystem D X ℕ∞)) (𝒯 : Set (D → D))
    {U U' : DescSystem D X ℕ∞} (hU : U ∈ 𝓒) (hU' : U' ∈ 𝓒)
    (h : ∀ S ∈ 𝓒, Simulates 𝒯 U S) (h' : ∀ S ∈ 𝓒, Simulates 𝒯 U' S) :
    ∃ c : ℕ, ∀ x, U.K x ≤ U'.K x + c ∧ U'.K x ≤ U.K x + c :=
  invariance 𝓒 hU hU' (fun S hS => (h S hS).dominates) fun S hS => (h' S hS).dominates

/-- Translations that put a fixed header in front of a program. -/
def prefixing : Set (List Bool → List Bool) := Set.range fun p l => p ++ l

private theorem K_of_code (e : List Bool → List Bool) (x : List Bool) :
    (⟨fun l => l.length, fun l x => l = e x⟩ : DescSystem (List Bool) (List Bool) ℕ∞).K x
      = (e x).length := by
  apply le_antisymm
  · exact DescSystem.K_le_cost _ (d := e x) rfl
  · refine (DescSystem.le_K_iff _).2 fun d hd => ?_
    have hd' : d = e x := hd
    rw [hd']

/-- **Simulation is strictly stronger than domination.** Two unambiguous binary systems
with the same complexity function, neither of which simulates the other by prefixing:
agreeing on `K` does not make one language translatable into the other by a fixed header.
(The two witnesses are translated into each other by flipping every bit, so the statement
is about prefixing only.) -/
theorem exists_dominates_not_simulates :
    ∃ S S' : DescSystem (List Bool) (List Bool) ℕ∞, S.IsBinary ∧ S'.IsBinary ∧
      S.Functional ∧ S'.Functional ∧ (∀ x, S'.K x = S.K x) ∧
      ¬ Simulates prefixing S' S ∧ ¬ Simulates prefixing S S' := by
  let S : DescSystem (List Bool) (List Bool) ℕ∞ := ⟨fun l => l.length, fun l x => l = id x⟩
  let S' : DescSystem (List Bool) (List Bool) ℕ∞ :=
    ⟨fun l => l.length, fun l x => l = (fun x => x.map not) x⟩
  have hinj : Function.Injective fun x : List Bool => x.map not :=
    List.map_injective_iff.2 fun a b h => by simpa using h
  refine ⟨S, S', fun _ => rfl, fun _ => rfl, ?_, ?_, fun x => ?_, ?_, ?_⟩
  · rintro d x y hx hy
    exact (hx : d = x).symm.trans hy
  · rintro d x y hx hy
    exact hinj ((hx : d = x.map not).symm.trans hy)
  · rw [K_of_code, K_of_code, List.length_map]
    rfl
  · rintro ⟨c, tr, ⟨p, rfl⟩, htr⟩
    have h0 : p ++ [] = ([] : List Bool).map not := (htr []).1 [] rfl
    have hp : p = [] := by simpa using h0
    subst hp
    have h1 : [] ++ [true] = [true].map not := (htr [true]).1 [true] rfl
    simp at h1
  · rintro ⟨c, tr, ⟨p, rfl⟩, htr⟩
    have h0 : p ++ [] = ([] : List Bool) := (htr []).1 [] rfl
    have hp : p = [] := by simpa using h0
    subst hp
    have h1 : [] ++ [false] = [true] := (htr [false]).1 [true] rfl
    simp at h1

/-- **No universal system without a restricted class.** On an infinite set, no unambiguous
binary system dominates every unambiguous binary system: for each `U` there is an `S` that
beats it by more than any constant. Invariance is a property of restricted classes
(computable systems), not of description systems as such. -/
theorem not_exists_universal [Infinite X] (U : DescSystem (List Bool) X ℕ∞)
    (hb : U.IsBinary) (hU : U.Functional) :
    ∃ S : DescSystem (List Bool) X ℕ∞, S.IsBinary ∧ S.Functional ∧ ¬ Dominates U S := by
  classical
  have hex : ∀ k : ℕ, ∃ x, ((2 * k + 1 : ℕ) : ℕ∞) ≤ U.K x := fun k => by
    obtain ⟨A, hA⟩ := Finset.exists_card_eq (α := X) (2 ^ (2 * k + 1))
    obtain ⟨x, -, hx⟩ := hb.exists_incompressible hU (2 * k + 1) A hA.ge
    exact ⟨x, hx⟩
  choose g hg using hex
  let S : DescSystem (List Bool) X ℕ∞ :=
    ⟨fun l => l.length, fun d x => x = g d.length ∧ d = List.replicate d.length true⟩
  refine ⟨S, fun _ => rfl, ?_, ?_⟩
  · rintro d x y ⟨hx, -⟩ ⟨hy, -⟩
    exact hx.trans hy.symm
  · rintro ⟨c, hc⟩
    have h1 : S.K (g c) ≤ c := by
      refine (S.K_le_cost (d := List.replicate c true) ⟨by simp, by simp⟩).trans ?_
      show (((List.replicate c true).length : ℕ) : ℕ∞) ≤ c
      simp
    have h2 : ((2 * c + 1 : ℕ) : ℕ∞) ≤ ((c + c : ℕ) : ℕ∞) := by
      calc ((2 * c + 1 : ℕ) : ℕ∞) ≤ U.K (g c) := hg c
        _ ≤ S.K (g c) + c := hc _
        _ ≤ (c : ℕ∞) + c := add_le_add h1 le_rfl
        _ = ((c + c : ℕ) : ℕ∞) := by push_cast; rfl
    have h3 : 2 * c + 1 ≤ c + c := by exact_mod_cast h2
    omega

end DescSystem

end Complexity
