import Complexity.Counting
import Complexity.CostAlgebra
import Complexity.Invariance

/-!
# Instance: coarse-graining, two-part codes and Boltzmann entropy

Let `π : X → Y` send microstates to macrostates. A microstate can be described in two
parts: describe its macrostate, then say *which* of the compatible microstates it is.

* `K_twoPart_le`     – the **two-part code**: `K(x) ≤ K(π x) + |index of x in its fibre|`;
* `exists_twoPart`   – if the fibre over `y` has at most `W y` members, an unambiguous
                       two-part system achieves `K(x) ≤ K(π x) + ⌈log₂ W(π x)⌉`;
* `card_fiber_compressible_lt` – conversely, in *any* unambiguous binary system fewer
                       than `2 ^ m` members of a fibre have complexity below `m`.

Together: for all but an exponentially small fraction of microstates,

  `K(microstate) ≈ K(macrostate) + log₂ W`.

The second term is Boltzmann's entropy; the first is the complexity of the regularities
(effective complexity, sophistication, the "model" half of an MDL code). Thermodynamic
entropy and algorithmic complexity are the two halves of one two-part description, and
"total information = effective complexity + entropy" (Gell-Mann–Lloyd; Zurek's physical
entropy) is the chain rule read at a coarse-graining.

**Review note.** `(twoPart S π code).K x = S.K (π x) + |code x|` holds by construction of the
cost, for any code. The lower bound `card_fiber_compressible_lt` gives `log₂ W - c` with
no `K(macrostate)` term, so "`K(micro) ≈ K(macro) + log₂ W`" is **not** proved here; it
needs symmetry of information (`Symmetry.card_K_lt_macro_add` proves the lower half for
the universal prefix machine and computable coarse-grainings). The transfer `exists_const_K_le_macro_add` cannot be
applied to the universal machine: `K(x) ≤ K(π x) + log₂ W + c` is false for plain
complexity (`Limits.not_twoPart_bound_kolmogorov`). The correct form uses a
self-delimiting description of the macrostate (`Limits.exists_binary_twoPart`,
`Prefix.twoPart_card`).
-/

namespace Complexity

namespace CoarseGraining

open DescSystem

variable {D X Y : Type*}

/-- **Two-part descriptions**: a description of the macrostate together with a code word
locating the microstate inside it. Costs add. -/
def twoPart (S : DescSystem D Y ℕ∞) (π : X → Y) (code : X → List Bool) :
    DescSystem (D × List Bool) X ℕ∞ where
  cost d := S.cost d.1 + d.2.length
  realizes d x := S.realizes d.1 (π x) ∧ code x = d.2

/-- Two-part descriptions are unambiguous when macro-descriptions are and code words are
distinct within each fibre. -/
theorem twoPart_functional {S : DescSystem D Y ℕ∞} (hS : S.Functional) {π : X → Y}
    {code : X → List Bool} (hcode : ∀ x x', π x = π x' → code x = code x' → x = x') :
    (twoPart S π code).Functional := by
  rintro ⟨d, i⟩ x x' ⟨h1, h2⟩ ⟨h1', h2'⟩
  exact hcode x x' (hS h1 h1') (h2.trans h2'.symm)

/-- **Two-part code.** The complexity of a microstate is at most the complexity of its
macrostate plus the length of its code word within the macrostate. -/
theorem K_twoPart_le (S : DescSystem D Y ℕ∞) (π : X → Y) (code : X → List Bool) (x : X) :
    (twoPart S π code).K x ≤ S.K (π x) + (code x).length := by
  rcases eq_or_ne (S.K (π x)) ⊤ with h | h
  · simp [h]
  obtain ⟨d, hd, hc⟩ := S.exists_cost_eq_K h
  rw [← hc]
  exact (twoPart S π code).K_le_cost (d := (d, code x)) ⟨hd, rfl⟩

/-- **Macro-complexity plus Boltzmann entropy bounds micro-complexity.** If every fibre
`π⁻¹ y` has at most `W y` members, there is an unambiguous two-part system with
`K(x) ≤ K(π x) + ⌈log₂ W(π x)⌉`. -/
theorem exists_twoPart (S : DescSystem D Y ℕ∞) (hS : S.Functional) (π : X → Y) (W : Y → ℕ)
    (hW : ∀ y, ∃ F : Finset X, (∀ x, π x = y → x ∈ F) ∧ F.card ≤ W y) :
    ∃ code : X → List Bool, (twoPart S π code).Functional ∧
      ∀ x, (twoPart S π code).K x ≤ S.K (π x) + Nat.clog 2 (W (π x)) := by
  classical
  choose F hF hcard using hW
  have hle : ∀ y, Fintype.card (F y) ≤ Fintype.card (List.Vector Bool (Nat.clog 2 (W y))) := by
    intro y
    rw [Fintype.card_coe, card_vector, Fintype.card_bool]
    exact (hcard y).trans (Nat.le_pow_clog (by norm_num) _)
  have e : ∀ y, F y ↪ List.Vector Bool (Nat.clog 2 (W y)) := fun y =>
    (Function.Embedding.nonempty_of_card_le (hle y)).some
  -- the code word of `x` inside the fibre over `y`
  let c : ∀ y x, π x = y → List Bool := fun y x hx => (e y ⟨x, hF y x hx⟩).toList
  have hc_eq : ∀ (x : X) (y : Y) (hx : π x = y), c (π x) x rfl = c y x hx := by
    intro x y hx
    subst hx
    rfl
  have hc_inj : ∀ (y : Y) (x x' : X) (hx : π x = y) (hx' : π x' = y),
      c y x hx = c y x' hx' → x = x' := by
    intro y x x' hx hx' h
    have h1 := (e y).injective (List.Vector.toList_injective h)
    exact Subtype.mk.inj h1
  have hc_len : ∀ x, (c (π x) x rfl).length = Nat.clog 2 (W (π x)) := fun x =>
    List.Vector.toList_length _
  refine ⟨fun x => c (π x) x rfl, twoPart_functional hS ?_, fun x => ?_⟩
  · intro x x' hπ h
    refine hc_inj (π x') x x' hπ rfl ?_
    rw [← hc_eq x (π x') hπ]
    exact h
  · have h := K_twoPart_le S π (fun x => c (π x) x rfl) x
    rw [hc_len x] at h
    exact h

/-- The two-part bound in **any description language expressive enough to run two-part
codes** – formally, any system dominating the two-part system: micro-complexity is at most
macro-complexity plus the index length plus a constant independent of the state. -/
theorem exists_const_K_le_macro_add {D' : Type*} (S : DescSystem D Y ℕ∞) (π : X → Y)
    (code : X → List Bool) (U : DescSystem D' X ℕ∞)
    (hU : DescSystem.Dominates U (twoPart S π code)) :
    ∃ c : ℕ, ∀ x : X, U.K x ≤ S.K (π x) + (code x).length + c := by
  obtain ⟨c, hc⟩ := hU
  exact ⟨c, fun x => (hc x).trans (add_le_add (K_twoPart_le S π code x) le_rfl)⟩

/-- **Typical microstates are incompressible.** In any unambiguous binary description
system, fewer than `2 ^ m` of the microstates in a population (for instance: a fibre of the
coarse-graining) have complexity below `m`. With a fibre of size `W`, all but a fraction
`2 ^ (-c)` need at least `log₂ W - c` bits. -/
theorem card_fiber_compressible_lt (S : DescSystem (List Bool) X ℕ∞) (hb : S.IsBinary)
    (hS : S.Functional) (F : Finset X) (m : ℕ) [DecidablePred fun x => S.K x < m] :
    (F.filter fun x => S.K x < m).card < 2 ^ m :=
  hb.card_compressible_lt hS m F

/-- The complexity of a macrostate is that of its simplest microstate. -/
theorem K_macro {Γ : Type*} [CompleteLattice Γ] (S : DescSystem D X Γ) (π : X → Y) (y : Y) :
    (S.push π).K y = ⨅ (x : X) (_ : π x = y), S.K x :=
  S.K_push π y

end CoarseGraining

end Complexity
