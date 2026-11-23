import Complexity.Counting
import Complexity.CostAlgebra
import Complexity.Invariance
import Complexity.Profile

/-!
# Dynamics: what a deterministic process can and cannot add

Let `f : X → X` be a deterministic law of motion. A state on a trajectory can be described
by an earlier state together with the elapsed time.

* `K_iterate_le`      – **logarithmic growth law**: `K(fᵗ x) ≤ K(x) + log t`. A closed
                        deterministic system adds description complexity no faster than
                        the logarithm of elapsed time;
* `exists_const_K_iterate_le` – the same in any description language that can express
                        iteration, up to a constant depending only on the law;
* `card_times_compressible_lt` – conversely, on a trajectory that does not repeat, fewer
                        than `2 ^ m` of the times have `K(fᵗ x) < m`: typically the bound
                        is attained;
* `image_profile_iterate` – in the two-resource profile, `t` steps of dynamics move the
                        trade-off frontier by `(+ log t, + t)`: description length grows
                        logarithmically while *depth* (time) grows linearly.

This separates the two things people call "complexity" in dynamical systems. Elaborate
structure produced by simple rules (cellular automata, development, fractals) is **deep**,
not long to describe; description complexity can enter only through initial conditions,
noise, or the clock.

**Review note.** The bounds here are for the purpose-built system `iterate`, which adds the
length of the time to the length of the state description with no delimiter between
them. No unambiguous bit-string language dominates that system over itself: for the
universal machine of `Instances/Kolmogorov.lean`, `K(fᵗ x) ≤ K(x) + log t + c` is *false*
(`Limits.not_iterate_bound_kolmogorov`). The hypothesis of `exists_const_K_iterate_le` is
satisfiable only when `S` is a weaker (for instance self-delimiting) language than `U`;
see `Limits.exists_binary_iterate` and `Prefix.iterate` (`K(fᵗ x) ≤ K(x) + 2 log t + 1` among
self-delimiting systems) for the correct forms. `image_profile_iterate` is an
upper bound on achievable cost vectors, true by construction; nothing here shows that a
state is *deep* (needs long running time), and `card_times_compressible_lt` matches only
the `log t` term, not `K(x)`.
-/

namespace Complexity

namespace Dynamics

open DescSystem

variable {D X : Type*}

/-- Describe a state by an earlier state and the number of steps since. The elapsed time
is paid for at its binary length. -/
def iterate (S : DescSystem D X ℕ∞) (f : X → X) : DescSystem (D × ℕ) X ℕ∞ where
  cost d := S.cost d.1 + Nat.size d.2
  realizes d y := ∃ x, S.realizes d.1 x ∧ f^[d.2] x = y

theorem iterate_functional {S : DescSystem D X ℕ∞} (hS : S.Functional) (f : X → X) :
    (iterate S f).Functional := by
  rintro ⟨d, t⟩ y y' ⟨x, hx, rfl⟩ ⟨x', hx', rfl⟩
  rw [hS hx hx']

/-- **Logarithmic growth law.** Running a deterministic law for `t` steps raises
complexity by at most the binary length of `t`. -/
theorem K_iterate_le (S : DescSystem D X ℕ∞) (f : X → X) (x : X) (t : ℕ) :
    (iterate S f).K (f^[t] x) ≤ S.K x + Nat.size t := by
  rcases eq_or_ne (S.K x) ⊤ with h | h
  · simp [h]
  obtain ⟨d, hd, hc⟩ := S.exists_cost_eq_K h
  rw [← hc]
  exact (iterate S f).K_le_cost (d := (d, t)) ⟨x, hd, rfl⟩

/-- The same law in **any description language expressive enough to say "run `f` for `t`
steps"** – formally, any system dominating the iterate system: complexity along a
trajectory exceeds the complexity of the starting state by at most `log t` plus a constant
that depends on the law of motion but not on the state or the time. -/
theorem exists_const_K_iterate_le {D' : Type*} (S : DescSystem D X ℕ∞) (f : X → X)
    (U : DescSystem D' X ℕ∞) (hU : DescSystem.Dominates U (iterate S f)) :
    ∃ c : ℕ, ∀ (x : X) (t : ℕ), U.K (f^[t] x) ≤ S.K x + Nat.size t + c := by
  obtain ⟨c, hc⟩ := hU
  exact ⟨c, fun x t => (hc _).trans (add_le_add (K_iterate_le S f x t) le_rfl)⟩

/-- **The bound is typically attained.** On a non-repeating stretch of trajectory, fewer
than `2 ^ m` of the times carry a state of complexity below `m`, in any unambiguous binary
description system. -/
theorem card_times_compressible_lt (S : DescSystem (List Bool) X ℕ∞) (hb : S.IsBinary)
    (hS : S.Functional) (f : X → X) (x : X) (T m : ℕ)
    (hinj : Set.InjOn (fun t => f^[t] x) (Finset.range T : Set ℕ))
    [DecidablePred fun t => S.K (f^[t] x) < m] :
    ((Finset.range T).filter fun t => S.K (f^[t] x) < m).card < 2 ^ m := by
  classical
  have hinj' : Set.InjOn (fun t => f^[t] x)
      (((Finset.range T).filter fun t => S.K (f^[t] x) < m) : Finset ℕ) :=
    hinj.mono fun t ht => (Finset.mem_filter.1 ht).1
  rw [← Finset.card_image_of_injOn hinj']
  refine lt_of_le_of_lt (S.card_le_of_K_lt hS m (2 ^ m - 1) (hb.growth m) _ fun y hy => ?_)
    (Nat.sub_one_lt (by positivity))
  obtain ⟨t, ht, rfl⟩ := Finset.mem_image.1 hy
  exact (Finset.mem_filter.1 ht).2

/-- The two-resource version: cost vectors are `(length, time)`; `t` steps of dynamics add
`log t` to the length and `t` to the time. -/
def iterate₂ (S : DescSystem D X (ℕ × ℕ)) (f : X → X) : DescSystem (D × ℕ) X (ℕ × ℕ) where
  cost d := ((S.cost d.1).1 + Nat.size d.2, (S.cost d.1).2 + d.2)
  realizes d y := ∃ x, S.realizes d.1 x ∧ f^[d.2] x = y

/-- **Dynamics shift the profile by `(+ log t, + t)`**: length grows logarithmically and
depth linearly. -/
theorem image_profile_iterate (S : DescSystem D X (ℕ × ℕ)) (f : X → X) (x : X) (t : ℕ) :
    (fun v : ℕ × ℕ => (v.1 + Nat.size t, v.2 + t)) '' S.profile x ⊆
      (iterate₂ S f).profile (f^[t] x) := by
  rintro _ ⟨v, ⟨d, hd, rfl⟩, rfl⟩
  exact ⟨(d, t), ⟨x, hd, rfl⟩, rfl⟩

end Dynamics

end Complexity
