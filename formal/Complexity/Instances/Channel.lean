import Complexity.Counting
import Complexity.Metric
import Complexity.Invariance

/-!
# Instance: transmission – receiver load, relay budgets and the network ceiling

The domain of *Lossy*: ideas passing between people.

A **receiver** is a decoder from what is said (a bit string) to what is understood (an
idea). Everything the receiver already holds – vocabulary, background, the "outer
message" – lives in the decoder. The **load** of an idea on a receiver is the fewest bits
that make *this* receiver arrive at it: complexity as precondition count is conditional
complexity given the receiver.

* `load_le_add_of_prefix` – **preconditions are a one-off additive cost**: a novice who
                          becomes the expert after a preamble `p` carries at most `|p|`
                          more load, for every idea;
* `card_lt_of_load_le`  – **budget ceiling**: within a budget of `B` bits a receiver can be
                          brought to fewer than `2 ^ (B + 1)` distinct ideas;
* `exists_load_gt`      – so any larger repertoire contains ideas that cannot land;
* `Relay.card_image_chain_lt` – **weakest-link law** (the telephone game): the number of
                          distinct versions leaving a chain of retellings is capped by the
                          tightest budget on the route, whatever the other hops do;
* `exists_loss_ge`      – **network ceiling**: with at most `deg` onward contacts per
                          person, an audience larger than `1 + deg + ⋯ + deg ^ n` contains
                          someone more than `n` retellings away, and if each retelling
                          loses at least `lam`, at least `(n + 1) • lam` is lost on the way
                          to them. Loss grows like `log(audience) / log(deg)`.

**Review note.** The two halves of this file are not connected by any theorem. The budget
results (`card_lt_of_load_le`, `Relay.card_image_chain_lt`) are counting bounds that do
not depend on the length of a chain: a stable relay iterated any number of times loses
what one pass loses (`Limits.relay_iterate_saturates`). `exists_loss_ge` is a Moore bound
on hop distance plus the *assumption* that every hop loses at least `lam`; it mentions no
idea, load or budget. `load_le_add_of_prefix` is an upper bound only: it does not say that
a budget below `|p|` plus the claim's load cannot carry both.
-/

namespace Complexity

namespace Channel

open DescSystem Quiver

variable {X : Type*}

/-- A receiver, as a description system: messages are bit strings, the cost of a message
is its length, and a message describes the idea the receiver decodes it to. -/
def sys (dec : List Bool → X) : DescSystem (List Bool) X ℕ∞ where
  cost l := l.length
  realizes l x := dec l = x

theorem sys_isBinary (dec : List Bool → X) : (sys dec).IsBinary := fun _ => rfl

theorem sys_functional (dec : List Bool → X) : (sys dec).Functional :=
  fun _ _ _ hx hy => hx.symm.trans hy

/-- The **load** of an idea on a receiver: the length of the shortest message that makes
the receiver arrive at it. -/
noncomputable def load (dec : List Bool → X) (x : X) : ℕ∞ := (sys dec).K x

/-- An idea lands within a budget iff some message that short decodes to it. -/
theorem load_le_iff {dec : List Bool → X} {x : X} {B : ℕ} :
    load dec x ≤ B ↔ ∃ l : List Bool, l.length ≤ B ∧ dec l = x := by
  rw [load, DescSystem.K_le_coe_iff]
  constructor
  · rintro ⟨l, hl, hc⟩
    have hc' : ((l.length : ℕ) : ℕ∞) ≤ B := hc
    exact ⟨l, by exact_mod_cast hc', hl⟩
  · rintro ⟨l, hc, hl⟩
    refine ⟨l, hl, ?_⟩
    show ((l.length : ℕ) : ℕ∞) ≤ B
    exact_mod_cast hc

/-- **Preconditions are a one-off additive cost.** If the receiver `dec'`, once given the
preamble `p`, decodes exactly as `dec` does, then every idea loads `dec'` by at most
`|p|` more than it loads `dec`. -/
theorem load_le_add_of_prefix (dec dec' : List Bool → X) (p : List Bool)
    (h : ∀ l, dec' (p ++ l) = dec l) (x : X) : load dec' x ≤ load dec x + p.length := by
  let s : DescSystem.Sim (sys dec) (sys dec') (· + (p.length : ℕ∞)) :=
    { tr := fun l => p ++ l
      ob := id
      realizes' := fun {l x} hl => (h l).trans hl
      cost_le := fun l => by
        show ((p ++ l).length : ℕ∞) ≤ (l.length : ℕ∞) + (p.length : ℕ∞)
        rw [List.length_append]
        push_cast
        rw [add_comm] }
  exact s.K_le_add x

/-- **Budget ceiling.** Fewer than `2 ^ (B + 1)` distinct ideas can land within `B` bits. -/
theorem card_lt_of_load_le (dec : List Bool → X) (B : ℕ) (A : Finset X)
    (hA : ∀ x ∈ A, load dec x ≤ B) : A.card < 2 ^ (B + 1) := by
  have h := (sys dec).card_le_of_K_lt (sys_functional dec) ((B + 1 : ℕ) : ℕ∞)
    (2 ^ (B + 1) - 1) ((sys_isBinary dec).growth (B + 1)) A fun x hx =>
      lt_of_le_of_lt (hA x hx) (by exact_mod_cast Nat.lt_succ_self B)
  exact lt_of_le_of_lt h (Nat.sub_one_lt (by positivity))

/-- **Compression is forced.** A repertoire of at least `2 ^ (B + 1)` ideas contains one
that cannot land within the budget `B`: it must be dropped or replaced by a simpler
stand-in. -/
theorem exists_load_gt (dec : List Bool → X) (B : ℕ) (A : Finset X)
    (hA : 2 ^ (B + 1) ≤ A.card) : ∃ x ∈ A, (B : ℕ∞) < load dec x := by
  by_contra h
  simp only [not_exists, not_and, not_lt] at h
  exact absurd (card_lt_of_load_le dec B A h) (not_lt.2 hA)

/-- A **relay** with budget `B`: it re-encodes what it holds into at most `B` bits, and the
next person decodes. -/
structure Relay (X : Type*) (B : ℕ) where
  /-- What the relay says. -/
  enc : X → List Bool
  /-- What the next person makes of it. -/
  dec : List Bool → X
  /-- The relay stays within budget. -/
  short : ∀ x, (enc x).length ≤ B

/-- The effect of one retelling on an idea. -/
def Relay.pass {B : ℕ} (h : Relay X B) (x : X) : X := h.dec (h.enc x)

/-- One retelling within budget `B` leaves fewer than `2 ^ (B + 1)` distinct versions. -/
theorem Relay.card_image_lt [DecidableEq X] {B : ℕ} (h : Relay X B) (A : Finset X) :
    (A.image h.pass).card < 2 ^ (B + 1) := by
  classical
  have h1 : A.image h.pass = (A.image h.enc).image h.dec := by
    rw [Finset.image_image]
    rfl
  rw [h1]
  refine lt_of_le_of_lt Finset.card_image_le
    (card_lt_two_pow_of_length_lt (B + 1) _ fun l hl => ?_)
  obtain ⟨x, -, rfl⟩ := Finset.mem_image.1 hl
  exact Nat.lt_succ_of_le (h.short x)

/-- **Weakest-link law.** Whatever happens before and after, the number of distinct
versions that leave a chain of retellings is capped by any one relay's budget – hence by
the tightest budget on the route. -/
theorem Relay.card_image_chain_lt [DecidableEq X] {B : ℕ} (h : Relay X B)
    (before after : X → X) (A : Finset X) :
    (A.image (after ∘ h.pass ∘ before)).card < 2 ^ (B + 1) := by
  have h1 : A.image (after ∘ h.pass ∘ before) = ((A.image before).image h.pass).image after := by
    rw [Finset.image_image, Finset.image_image]
    rfl
  rw [h1]
  exact lt_of_le_of_lt Finset.card_image_le (h.card_image_lt _)

/-- **Network ceiling.** In a network where everyone passes things on to at most `deg`
others, any audience of more than `1 + deg + ⋯ + deg ^ n` people contains someone more
than `n` retellings from the source; if every retelling loses at least `lam`, at least
`(n + 1) • lam` is lost on the way to them, by whatever route. -/
theorem exists_loss_ge {V : Type*} [Quiver V] [DecidableEq V] (succ : V → Finset V)
    (hsucc : ∀ ⦃a b : V⦄, (a ⟶ b) → b ∈ succ a) (deg : ℕ) (hdeg : ∀ a, (succ a).card ≤ deg)
    {Γ : Type*} [CompleteLattice Γ] [AddCommMonoid Γ] [IsCostAlgebra Γ] (w : Weight V Γ)
    (lam : Γ) (hw : ∀ ⦃a b : V⦄ (e : a ⟶ b), lam ≤ w e) (src : V) (n : ℕ) (A : Finset V)
    (hA : ∑ k ∈ Finset.range (n + 1), deg ^ k < A.card) :
    ∃ b ∈ A, (n + 1) • lam ≤ dist w src b := by
  obtain ⟨b, hb, hfar⟩ := exists_hop_gt succ hsucc deg hdeg src n A hA
  refine ⟨b, hb, nsmul_le_dist w lam hw ?_⟩
  have h1 : (n : ℕ∞) + 1 ≤ hop src b := Order.add_one_le_of_lt hfar
  exact_mod_cast h1

end Channel

end Complexity
