import Complexity.Instances.Channel
import Complexity.Limits
import Mathlib.Topology.MetricSpace.CoveringNumbers

/-!
# A lossy layer: landing an idea within a tolerance

`Instances/Channel.lean` asks whether an idea lands *exactly*. Here the space of ideas has a
distance, and an idea lands *within tolerance* `ε` if what the receiver arrives at is at
most `ε` away from it. The general statements use Mathlib's extended distance `edist` and
its covering numbers (`Metric.externalCoveringNumber`); the worked case on `ℕ` is stated in
plain arithmetic, and `Nat.edist_le_iff`, `Nat.delivers_iff` connect the two.

**Load at a tolerance.** `loadWithin dec ε x` is the length of the shortest message that
makes the receiver `dec` arrive within `ε` of `x`.

* `loadWithin_anti`, `loadWithin_le_load` – more tolerance never costs more, and the exact
  load is an upper bound at every tolerance. (That the two agree at `ε = 0` is not proved
  and is false in a pseudo-metric space, where distinct ideas can be at distance `0`.)
* `loadWithin_eq_iInf_load` – load at a tolerance is the least exact load of a point within
  the tolerance. This is the rate–distortion function of an individual object in the sense
  of Vereshchagin and Vitányi, with an arbitrary decoder in place of a universal machine;
  only the definition is reproduced here, none of their theorems.
* `loadWithin_le_add_of_prefix` – a receiver who reads like the expert after a preamble `p`
  pays at most `|p|` more, at every tolerance: a fixed additive cost per message.
* `delivers_iff_loadWithin` – a restatement, not a result: a set of ideas can be delivered
  within `ε` through the receiver `dec` on budget `B` exactly when each of them has load at
  most `B` at that tolerance.

**The exchange rate between budget and tolerance.**

* `exists_relay_iff` – **exact**: some relay with budget `B` delivers every idea of `A`
  within `ε` if and only if `A` is covered by fewer than `2 ^ (B + 1)` balls of radius `ε`.
  The relay, and in particular the receiver's decoder, is chosen for the set `A`; the
  statement is about a repertoire of ideas, not about one idea.
* `externalCoveringNumber_lt_of_delivers_chain` – **weakest link**: the necessary half
  holds for a chain that contains one relay of budget `B`, whatever happens before and
  after. The tightest hop bounds what the chain can deliver; it does not determine it
  (`Limits.leak_iterate`).

So the best tolerance a budget can buy on a set of ideas, for a receiver chosen for that
set, is the one at which the covering number drops below `2 ^ (B + 1)`. This is Kolmogorov
and Tikhomirov's `ε`-entropy, `log₂` of the covering number, read as a statement about
relays. (The attribution is from search summaries; the paper was not read.)

* `Nat.budget_iff` – a worked case, exact: every number below `N` can be delivered within
  `±e` on budget `B` if and only if `N ≤ (2e + 1) · (2 ^ (B + 1) - 1)`. So one further bit
  roughly halves the error needed, up to rounding.

**What depth does and does not force.**

* `edist_le_of_merged`, `not_both_delivered` – **merging is irreversible**: if a step sends
  two ideas to the same thing, nothing later along that chain can separate them, and for
  every later reading the two readings coincide, so one of the two ideas is off by at least
  half their distance.
* `edist_chain_le` – if every hop moves the idea by at most `δ`, `n` hops move it by at
  most `n δ`. This is the triangle inequality; the bound `δ` per hop is a hypothesis, not
  something the budget model supplies.
* `orbit_repeats` – **one relay, iterated, stops producing new versions**: among the first
  `2 ^ (B + 1) + 1` versions two coincide, and the chain cycles from there. Depth beyond
  `2 ^ (B + 1)` adds no loss that was not already reached.
* `Nat.decRelay_iterate` – within that limit loss can grow by one unit per hop: a relay
  within budget whose `n`-fold retelling moves a number by exactly `n`, for `n` up to
  `2 ^ B`. Along an orbit that has not reached `0` the step is a shift; the same relay
  merges one more number with `0` at every step (`Nat.decRelay_merges_late`).
* `Nat.swapRelay_pass` – loss is not monotone in depth: one retelling moves `0` to `1`, the
  second moves it back.
* `Nat.exists_drifting_chain` – for a chain of *different* relays there is no limit at all:
  on budget `0`, hop `k` can pass on `k` whatever it hears.

* `merging_stops` – **one relay, iterated, stops merging**: there is a step
  `N < 2 ^ (B + 1)` after which two ideas still apart stay apart for ever; from then on the
  relay permutes what survives. `Nat.decRelay_merges_late` shows merging can go on for
  `2 ^ B` steps.

Counted as distinctions lost, loss through functions is monotone in depth (what is merged
stays merged) and, for one relay, over after finitely many steps. For one pair of ideas
through one fixed chain there is no partial loss; partial distinguishability needs
randomness: see `Noisy.lean`.

With `Limits.relay_iterate_saturates` (a stable relay moves nothing after the first pass),
the picture for one relay is: displacement after `n` retellings can be anything between `0`
and the number of steps, is not monotone, and is settled by step `2 ^ (B + 1)`. For
heterogeneous chains the budget says nothing about depth.

None of this is new mathematics. The covering statement is the definition of `ε`-entropy
turned into a theorem about encoders and decoders; the irreversibility statement is the
triangle inequality; the orbit statement is the pigeonhole principle.
-/

namespace Complexity

namespace Lossy

open Channel DescSystem Metric
open scoped ENNReal NNReal

variable {X : Type*} [PseudoEMetricSpace X]

/-! ### Delivering within a tolerance -/

/-- The map `f` (a retelling, or a whole chain) delivers every idea of `A` within `ε`. -/
def Delivers (f : X → X) (ε : ℝ≥0) (A : Set X) : Prop := ∀ x ∈ A, edist x (f x) ≤ ε

theorem isCover_iff {ε : ℝ≥0} {s N : Set X} :
    IsCover ε s N ↔ ∀ a ∈ s, ∃ c ∈ N, edist a c ≤ ε := by
  simp [IsCover, SetRel.IsCover]

/-! ### Load at a tolerance -/

/-- The **load of `x` at tolerance `ε`** on the receiver `dec`: the length of the shortest
message the receiver decodes to something within `ε` of `x`. -/
noncomputable def loadWithin (dec : List Bool → X) (ε : ℝ≥0) (x : X) : ℕ∞ :=
  ⨅ (w : List Bool) (_ : edist x (dec w) ≤ ε), (w.length : ℕ∞)

theorem loadWithin_le_iff {dec : List Bool → X} {ε : ℝ≥0} {x : X} {B : ℕ} :
    loadWithin dec ε x ≤ B ↔ ∃ w : List Bool, w.length ≤ B ∧ edist x (dec w) ≤ ε := by
  constructor
  · intro h
    by_contra hcon
    push Not at hcon
    have hlt : ((B + 1 : ℕ) : ℕ∞) ≤ loadWithin dec ε x :=
      le_iInf₂ fun w hw => by
        have := hcon w
        exact_mod_cast Nat.succ_le_of_lt (lt_of_not_ge fun hle => absurd hw (not_le.2 (this hle)))
    have : ((B + 1 : ℕ) : ℕ∞) ≤ B := hlt.trans h
    have h' : B + 1 ≤ B := by exact_mod_cast this
    omega
  · rintro ⟨w, hw, hd⟩
    exact (iInf₂_le w hd).trans (by exact_mod_cast hw)

/-- More tolerance never costs more. -/
theorem loadWithin_anti (dec : List Bool → X) {ε δ : ℝ≥0} (h : ε ≤ δ) (x : X) :
    loadWithin dec δ x ≤ loadWithin dec ε x :=
  le_iInf₂ fun w hw => iInf₂_le w (hw.trans (by exact_mod_cast h))

/-- Landing exactly is landing within every tolerance. -/
theorem loadWithin_le_load (dec : List Bool → X) (ε : ℝ≥0) (x : X) :
    loadWithin dec ε x ≤ load dec x := by
  refine (Channel.sys dec).le_K_iff.2 fun w hw => ?_
  have hw' : dec w = x := hw
  exact iInf₂_le w (by rw [hw', edist_self]; exact zero_le)

/-- Load at a tolerance is the least exact load of a point within the tolerance. This is the
rate–distortion function of an individual idea, relative to the receiver `dec`. -/
theorem loadWithin_eq_iInf_load (dec : List Bool → X) (ε : ℝ≥0) (x : X) :
    loadWithin dec ε x = ⨅ (y : X) (_ : edist x y ≤ ε), load dec y := by
  apply le_antisymm
  · refine le_iInf₂ fun y hy => (Channel.sys dec).le_K_iff.2 fun w hw => ?_
    have hw' : dec w = y := hw
    exact iInf₂_le w (by rw [hw']; exact hy)
  · refine le_iInf₂ fun w hw => (iInf₂_le (dec w) hw).trans ?_
    exact (load_le_iff (B := w.length)).2 ⟨w, le_rfl, rfl⟩

/-- **Shipping the key costs its length, at every tolerance.** If the receiver `dec'`, once
given the preamble `p`, decodes exactly as `dec` does, then every idea loads `dec'` by at
most `|p|` more than it loads `dec`. -/
theorem loadWithin_le_add_of_prefix (dec dec' : List Bool → X) (p : List Bool)
    (h : ∀ l, dec' (p ++ l) = dec l) (ε : ℝ≥0) (x : X) :
    loadWithin dec' ε x ≤ loadWithin dec ε x + p.length := by
  rcases eq_or_ne (loadWithin dec ε x) ⊤ with htop | htop
  · rw [htop, top_add]
    exact le_top
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 htop
  obtain ⟨w, hw, hd⟩ := (loadWithin_le_iff (B := n)).1 hn.ge
  have h1 : loadWithin dec' ε x ≤ ((n + p.length : ℕ) : ℕ∞) :=
    (loadWithin_le_iff (B := n + p.length)).2
      ⟨p ++ w, by rw [List.length_append]; omega, by rw [h]; exact hd⟩
  rw [← hn]
  exact h1.trans (by push_cast; exact le_rfl)

/-- **Deliverable means affordable.** A set of ideas can be delivered within `ε` through
the receiver `dec` on budget `B` exactly when each idea in it has load at most `B` at
tolerance `ε`. -/
theorem delivers_iff_loadWithin (dec : List Bool → X) (B : ℕ) (ε : ℝ≥0) (A : Set X) :
    (∃ h : Relay X B, h.dec = dec ∧ Delivers h.pass ε A) ↔
      ∀ x ∈ A, loadWithin dec ε x ≤ B := by
  classical
  constructor
  · rintro ⟨h, rfl, hd⟩ x hx
    exact loadWithin_le_iff.2 ⟨h.enc x, h.short x, hd x hx⟩
  · intro hA
    refine ⟨⟨fun x => if hx : ∃ w : List Bool, w.length ≤ B ∧ edist x (dec w) ≤ ε
        then hx.choose else [], dec, fun x => ?_⟩, rfl, fun x hx => ?_⟩
    · by_cases hx : ∃ w : List Bool, w.length ≤ B ∧ edist x (dec w) ≤ ε
      · simp only [hx, ↓reduceDIte]
        exact hx.choose_spec.1
      · simp [hx]
    · have hex := loadWithin_le_iff.1 (hA x hx)
      show edist x (dec (dite _ _ _)) ≤ ε
      simp only [hex, ↓reduceDIte]
      exact hex.choose_spec.2

/-! ### The exchange rate: budget against tolerance -/

/-- Fewer than `2 ^ (B + 1)` bit strings have length at most `B`. -/
theorem encard_length_le_lt (B : ℕ) :
    ({l : List Bool | l.length ≤ B} : Set (List Bool)).encard < ((2 ^ (B + 1) : ℕ) : ℕ∞) := by
  have hfin := List.finite_length_le Bool B
  rw [hfin.encard_eq_coe_toFinset_card]
  exact_mod_cast card_lt_two_pow_of_length_lt (B + 1) _ fun l hl =>
    Nat.lt_succ_of_le (by simpa using hl)

/-- **Weakest link, with a tolerance.** If a chain that contains a relay of budget `B`
delivers every idea of `A` within `ε`, whatever happens before and after that relay, then
`A` is covered by fewer than `2 ^ (B + 1)` balls of radius `ε`. -/
theorem externalCoveringNumber_lt_of_delivers_chain {B : ℕ} (h : Relay X B)
    (before after : X → X) (ε : ℝ≥0) (A : Set X)
    (hd : Delivers (after ∘ h.pass ∘ before) ε A) :
    externalCoveringNumber ε A < ((2 ^ (B + 1) : ℕ) : ℕ∞) := by
  have hcover : IsCover ε A ((fun l => after (h.dec l)) '' {l : List Bool | l.length ≤ B}) :=
    isCover_iff.2 fun a ha =>
      ⟨after (h.dec (h.enc (before a))), ⟨h.enc (before a), h.short _, rfl⟩, hd a ha⟩
  exact (hcover.externalCoveringNumber_le_encard.trans (Set.encard_image_le _ _)).trans_lt
    (encard_length_le_lt B)

/-- **A budget buys a covering.** If one relay with budget `B` delivers every idea of `A`
within `ε`, then `A` is covered by fewer than `2 ^ (B + 1)` balls of radius `ε`. -/
theorem externalCoveringNumber_lt_of_delivers {B : ℕ} (h : Relay X B) (ε : ℝ≥0) (A : Set X)
    (hd : Delivers h.pass ε A) : externalCoveringNumber ε A < ((2 ^ (B + 1) : ℕ) : ℕ∞) :=
  externalCoveringNumber_lt_of_delivers_chain h id id ε A hd

/-! #### Numbering the strings of length at most `B` -/

/-- The `i`-th bit string in order of length: `code 0 = []`, then the two strings of length
one, and so on. The strings of length at most `B` are exactly `code i` for
`i + 1 < 2 ^ (B + 1)`. -/
def code (i : ℕ) : List Bool :=
  Nat.bits (i + 1 - 2 ^ Nat.log 2 (i + 1)) ++
    List.replicate (Nat.log 2 (i + 1) - (Nat.bits (i + 1 - 2 ^ Nat.log 2 (i + 1))).length) false

/-- The position of a bit string in that order. -/
def decode (l : List Bool) : ℕ := 2 ^ l.length - 1 + Limits.numeral l

theorem numeral_append_replicate_false (l : List Bool) (k : ℕ) :
    Limits.numeral (l ++ List.replicate k false) = Limits.numeral l := by
  have hz : ∀ k : ℕ, Nat.ofDigits 2 (List.replicate k 0) = 0 := by
    intro k
    induction k with
    | zero => rfl
    | succ k ih => rw [List.replicate_succ, Nat.ofDigits_cons, ih]
  simp only [Limits.numeral, List.map_append, List.map_replicate, Bool.cond_false, Nat.ofDigits_append,
    hz, mul_zero, add_zero]

theorem length_code (i : ℕ) : (code i).length = Nat.log 2 (i + 1) := by
  have h1 : 2 ^ Nat.log 2 (i + 1) ≤ i + 1 := Nat.pow_log_le_self 2 (by omega)
  have h2 : i + 1 < 2 ^ (Nat.log 2 (i + 1) + 1) := Nat.lt_pow_succ_log_self (by norm_num) _
  have hv : i + 1 - 2 ^ Nat.log 2 (i + 1) < 2 ^ Nat.log 2 (i + 1) := by
    rw [pow_succ] at h2
    omega
  have hsize : (Nat.bits (i + 1 - 2 ^ Nat.log 2 (i + 1))).length ≤ Nat.log 2 (i + 1) := by
    rw [Nat.size_eq_bits_len]
    exact Nat.size_le.2 hv
  rw [code, List.length_append, List.length_replicate]
  omega

theorem decode_code (i : ℕ) : decode (code i) = i := by
  have h1 : 2 ^ Nat.log 2 (i + 1) ≤ i + 1 := Nat.pow_log_le_self 2 (by omega)
  have hpos : 0 < 2 ^ Nat.log 2 (i + 1) := Nat.pos_of_ne_zero (by positivity)
  rw [decode, length_code]
  rw [code, numeral_append_replicate_false, Limits.numeral_bits]
  omega

theorem length_code_le {B i : ℕ} (h : i + 1 < 2 ^ (B + 1)) : (code i).length ≤ B := by
  rw [length_code]
  have := Nat.log_lt_of_lt_pow (by omega : i + 1 ≠ 0) h
  omega

/-- **A covering is a relay.** If finitely many points, fewer than `2 ^ (B + 1)` of them,
come within `ε` of every idea of `A`, some relay with budget `B` delivers all of `A` within
`ε`: send the name of a nearby point. -/
theorem exists_relay_of_cover [Nonempty X] {B : ℕ} (ε : ℝ≥0) (A : Set X) (C : Finset X)
    (hC : IsCover ε A (C : Set X)) (hcard : C.card < 2 ^ (B + 1)) :
    ∃ h : Relay X B, Delivers h.pass ε A := by
  classical
  have hcov := isCover_iff.1 hC
  obtain ⟨x0⟩ := ‹Nonempty X›
  -- the index of a nearby centre
  let idx : X → ℕ := fun x =>
    if hx : ∃ c ∈ (C : Set X), edist x c ≤ ε
      then (C.equivFin ⟨hx.choose, Finset.mem_coe.1 hx.choose_spec.1⟩ : ℕ) else 0
  have hidx : ∀ x, idx x + 1 < 2 ^ (B + 1) := fun x => by
    by_cases hx : ∃ c ∈ (C : Set X), edist x c ≤ ε
    · simp only [idx, hx, ↓reduceDIte]
      have := Fin.is_lt (C.equivFin ⟨hx.choose, Finset.mem_coe.1 hx.choose_spec.1⟩)
      omega
    · simp only [idx, hx, ↓reduceDIte]
      have : 2 ≤ 2 ^ (B + 1) := by
        calc 2 = 2 ^ 1 := by norm_num
          _ ≤ 2 ^ (B + 1) := Nat.pow_le_pow_right (by norm_num) (by omega)
      omega
  refine ⟨⟨fun x => code (idx x),
      fun l => if hl : decode l < C.card
        then (C.equivFin.symm ⟨decode l, hl⟩ : X) else x0, fun x => length_code_le (hidx x)⟩,
      fun x hx => ?_⟩
  have hex := hcov x hx
  have hidxx : idx x = (C.equivFin ⟨hex.choose, Finset.mem_coe.1 hex.choose_spec.1⟩ : ℕ) := by
    simp only [idx, hex, ↓reduceDIte]
  show edist x (dite _ _ _) ≤ ε
  rw [decode_code]
  have hlt : idx x < C.card := by
    rw [hidxx]
    exact Fin.is_lt _
  simp only [hlt, ↓reduceDIte]
  have hback : (C.equivFin.symm ⟨idx x, hlt⟩ : X) = hex.choose := by
    have e : (⟨idx x, hlt⟩ : Fin C.card) =
        C.equivFin ⟨hex.choose, Finset.mem_coe.1 hex.choose_spec.1⟩ := Fin.ext hidxx
    rw [e, Equiv.symm_apply_apply]
  rw [hback]
  exact hex.choose_spec.2

/-- The same, stated with Mathlib's covering number. -/
theorem exists_relay_of_externalCoveringNumber_lt [Nonempty X] {B : ℕ} (ε : ℝ≥0) (A : Set X)
    (h : externalCoveringNumber ε A < ((2 ^ (B + 1) : ℕ) : ℕ∞)) :
    ∃ r : Relay X B, Delivers r.pass ε A := by
  classical
  rw [externalCoveringNumber, iInf_lt_iff] at h
  obtain ⟨C, hC⟩ := h
  rw [iInf_lt_iff] at hC
  obtain ⟨hcov, hcard⟩ := hC
  have hfin : C.Finite := Set.encard_lt_top_iff.1 (lt_of_lt_of_le hcard le_top)
  have hcard' : hfin.toFinset.card < 2 ^ (B + 1) := by
    rw [hfin.encard_eq_coe_toFinset_card] at hcard
    exact_mod_cast hcard
  exact exists_relay_of_cover ε A hfin.toFinset (by simpa using hcov) hcard'

/-- **The exchange rate, exactly.** Some relay with budget `B` delivers every idea of `A`
within `ε` if and only if `A` is covered by fewer than `2 ^ (B + 1)` balls of radius `ε`.
The relay, and in particular the receiver's decoder, is chosen for the set `A`. -/
theorem exists_relay_iff [Nonempty X] {B : ℕ} (ε : ℝ≥0) (A : Set X) :
    (∃ r : Relay X B, Delivers r.pass ε A) ↔
      externalCoveringNumber ε A < ((2 ^ (B + 1) : ℕ) : ℕ∞) :=
  ⟨fun ⟨r, hr⟩ => externalCoveringNumber_lt_of_delivers r ε A hr,
    exists_relay_of_externalCoveringNumber_lt ε A⟩

/-- **What fits in a budget is coarse.** The ideas a receiver can take in within tolerance
`ε` on budget `B` are covered by fewer than `2 ^ (B + 1)` balls of radius `ε`. -/
theorem externalCoveringNumber_loadWithin_lt (dec : List Bool → X) (B : ℕ) (ε : ℝ≥0) :
    externalCoveringNumber ε {x | loadWithin dec ε x ≤ B} < ((2 ^ (B + 1) : ℕ) : ℕ∞) := by
  obtain ⟨h, -, hd⟩ := (delivers_iff_loadWithin dec B ε {x | loadWithin dec ε x ≤ B}).2
    fun x hx => hx
  exact externalCoveringNumber_lt_of_delivers h ε _ hd

/-- **Too many ideas that are far apart cannot all survive.** If `A` contains `2 ^ (B + 1)`
points that are pairwise more than `2 ε` apart (its packing number at `2 ε` is that large),
then no chain containing a relay of budget `B` delivers all of `A` within `ε`: some idea
lands more than `ε` away from where it started. -/
theorem exists_not_delivered_of_packing {B : ℕ} (h : Relay X B) (before after : X → X)
    (ε : ℝ≥0) (A : Set X) (hpack : ((2 ^ (B + 1) : ℕ) : ℕ∞) ≤ packingNumber (2 * ε) A) :
    ∃ x ∈ A, (ε : ℝ≥0∞) < edist x (after (h.pass (before x))) := by
  by_contra hcon
  push Not at hcon
  have hd : Delivers (after ∘ h.pass ∘ before) ε A := fun x hx => hcon x hx
  have h1 := externalCoveringNumber_lt_of_delivers_chain h before after ε A hd
  have h2 := packingNumber_two_mul_le_externalCoveringNumber ε A
  exact absurd (hpack.trans h2) (not_le.2 h1)

/-! ### What depth does and does not do -/

/-- **Merging is irreversible.** If a step `f` sends `x` and `x'` to the same thing, then
for any later reading `g` the two losses add up to at least the distance between them. -/
theorem edist_le_of_merged {Y : Type*} (f : X → Y) (g : Y → X) {x x' : X} (h : f x = f x') :
    edist x x' ≤ edist x (g (f x)) + edist x' (g (f x')) := by
  calc edist x x' ≤ edist x (g (f x)) + edist (g (f x)) x' := edist_triangle _ _ _
    _ = edist x (g (f x)) + edist x' (g (f x')) := by rw [h, edist_comm (g (f x')) x']

/-- Two ideas more than `2 ε` apart that some step has merged cannot both be delivered
within `ε`, whatever comes after. -/
theorem not_both_delivered {Y : Type*} (f : X → Y) (g : Y → X) {x x' : X} {ε : ℝ≥0}
    (h : f x = f x') (hfar : 2 * (ε : ℝ≥0∞) < edist x x') :
    (ε : ℝ≥0∞) < edist x (g (f x)) ∨ (ε : ℝ≥0∞) < edist x' (g (f x')) := by
  by_contra hcon
  push Not at hcon
  have h1 := edist_le_of_merged f g h
  have h2 : edist x (g (f x)) + edist x' (g (f x')) ≤ 2 * (ε : ℝ≥0∞) := by
    rw [two_mul]
    exact add_le_add hcon.1 hcon.2
  exact absurd (h1.trans h2) (not_le.2 hfar)

/-- **Loss adds up at most.** Along any sequence of versions, if each step moves the idea by
at most `δ`, then `n` steps move it by at most `n δ`. -/
theorem edist_chain_le (s : ℕ → X) (n : ℕ) (δ : ℝ≥0∞)
    (h : ∀ i < n, edist (s i) (s (i + 1)) ≤ δ) : edist (s 0) (s n) ≤ n * δ := by
  have h1 := edist_le_range_sum_of_edist_le (f := s) n (d := fun _ => δ) fun {k} hk => h k hk
  simpa using h1

/-- **One relay, retold through itself, runs out of new versions.** For every relay with
budget `B` and every starting idea, two of the first `2 ^ (B + 1) + 1` versions coincide, so
from then on the chain only repeats. Whatever loss one relay causes by iteration is reached
within `2 ^ (B + 1)` retellings. -/
theorem orbit_repeats {X : Type*} {B : ℕ} (h : Relay X B) (x : X) :
    ∃ i j, i < j ∧ j ≤ 2 ^ (B + 1) ∧ h.pass^[i] x = h.pass^[j] x := by
  classical
  have hfin := List.finite_length_le Bool B
  have hc : hfin.toFinset.card < (Finset.range (2 ^ (B + 1))).card := by
    rw [Finset.card_range]
    exact card_lt_two_pow_of_length_lt (B + 1) _ fun l hl =>
      Nat.lt_succ_of_le (by simpa using hl)
  obtain ⟨i, hi, j, hj, hne, heq⟩ :=
    Finset.exists_ne_map_eq_of_card_lt_of_maps_to hc
      (f := fun i => h.enc (h.pass^[i] x)) (fun i _ => by simpa using h.short _)
  have key : ∀ a b : ℕ, h.enc (h.pass^[a] x) = h.enc (h.pass^[b] x) →
      h.pass^[a + 1] x = h.pass^[b + 1] x := by
    intro a b hab
    rw [Function.iterate_succ_apply', Function.iterate_succ_apply']
    show h.dec _ = h.dec _
    rw [hab]
  rw [Finset.mem_range] at hi hj
  rcases Nat.lt_or_gt_of_ne hne with hlt | hlt
  · exact ⟨i + 1, j + 1, by omega, by omega, key i j heq⟩
  · exact ⟨j + 1, i + 1, by omega, by omega, key j i heq.symm⟩

/-- A non-increasing sequence of positive numbers that starts at most `M` repeats a value
within its first `M` steps. -/
theorem exists_eq_succ_of_antitone {a : ℕ → ℕ} {M : ℕ} (hanti : ∀ n, a (n + 1) ≤ a n)
    (hpos : ∀ n, 1 ≤ a n) (h0 : a 0 ≤ M) : ∃ n < M, a (n + 1) = a n := by
  by_contra hno
  push Not at hno
  have key : ∀ n ≤ M, a n + n ≤ M := by
    intro n hn
    induction n with
    | zero => simpa using h0
    | succ n ih =>
      have h1 := ih (by omega)
      have h2 := hanti n
      have h3 := hno n (by omega)
      omega
  have h4 := key M le_rfl
  have h5 := hpos M
  omega

/-- A map with at most `M` values stops merging within `M` iterations: whatever it has not
merged by step `N ≤ M` it never merges. After that it permutes what survives. -/
theorem merging_stops_of_finite {X : Type*} (f : X → X) {M : ℕ}
    (hfin : (Set.range f).Finite) (hcard : (Set.range f).ncard ≤ M) :
    ∃ N ≤ M, ∀ k x y, f^[N + k] x = f^[N + k] y → f^[N] x = f^[N] y := by
  rcases isEmpty_or_nonempty X with hX | ⟨⟨x0⟩⟩
  · exact ⟨0, Nat.zero_le _, fun _ x => (hX.false x).elim⟩
  have hsub0 : ∀ n, Set.range (f^[n + 1]) ⊆ Set.range f := by
    rintro n _ ⟨x, rfl⟩
    exact ⟨f^[n] x, (Function.iterate_succ_apply' f n x).symm⟩
  have hfinS : ∀ n, (Set.range (f^[n + 1])).Finite := fun n => hfin.subset (hsub0 n)
  have hsub : ∀ n, Set.range (f^[n + 1 + 1]) ⊆ Set.range (f^[n + 1]) := by
    rintro n _ ⟨x, rfl⟩
    exact ⟨f x, (Function.iterate_succ_apply f (n + 1) x).symm⟩
  obtain ⟨n, hn, heq⟩ := exists_eq_succ_of_antitone (M := M)
    (a := fun n => (Set.range (f^[n + 1])).ncard)
    (fun n => Set.ncard_le_ncard (hsub n) (hfinS n))
    (fun n => (Set.ncard_pos (hfinS n)).2 ⟨_, ⟨x0, rfl⟩⟩)
    (by simpa using hcard)
  have hS : Set.range (f^[n + 1 + 1]) = Set.range (f^[n + 1]) :=
    Set.eq_of_subset_of_ncard_le (hsub n) (le_of_eq heq.symm) (hfinS n)
  have hmaps : Set.MapsTo f (Set.range (f^[n + 1])) (Set.range (f^[n + 1])) := by
    rintro _ ⟨x, rfl⟩
    rw [← hS]
    exact ⟨x, Function.iterate_succ_apply' f (n + 1) x⟩
  have hsurj : Set.SurjOn f (Set.range (f^[n + 1])) (Set.range (f^[n + 1])) := by
    intro y hy
    rw [← hS] at hy
    obtain ⟨x, rfl⟩ := hy
    exact ⟨f^[n + 1] x, ⟨x, rfl⟩, (Function.iterate_succ_apply' f (n + 1) x).symm⟩
  have hinj : Set.InjOn f (Set.range (f^[n + 1])) :=
    (((hfinS n).surjOn_iff_bijOn_of_mapsTo hmaps).1 hsurj).injOn
  have hiter : ∀ k, Set.InjOn (f^[k]) (Set.range (f^[n + 1])) ∧
      Set.MapsTo (f^[k]) (Set.range (f^[n + 1])) (Set.range (f^[n + 1])) := by
    intro k
    induction k with
    | zero => exact ⟨Set.injOn_id _, Set.mapsTo_id _⟩
    | succ k ih =>
      rw [Function.iterate_succ']
      exact ⟨hinj.comp ih.1 ih.2, hmaps.comp ih.2⟩
  refine ⟨n + 1, hn, fun k x y hxy => ?_⟩
  have e : ∀ z, f^[n + 1 + k] z = f^[k] (f^[n + 1] z) := fun z => by
    rw [add_comm, Function.iterate_add_apply]
  rw [e x, e y] at hxy
  exact (hiter k).1 ⟨x, rfl⟩ ⟨y, rfl⟩ hxy

/-- If a relay has stopped merging by step `N`, it permutes the versions that survive `N`
retellings. -/
theorem bijOn_of_merging_stops {X : Type*} {B : ℕ} (h : Relay X B) (N : ℕ)
    (hN : ∀ k x y, h.pass^[N + k] x = h.pass^[N + k] y → h.pass^[N] x = h.pass^[N] y) :
    Set.BijOn h.pass (Set.range h.pass^[N]) (Set.range h.pass^[N]) := by
  classical
  have hfinL := List.finite_length_le Bool B
  have hsub : Set.range h.pass ⊆ h.dec '' {l : List Bool | l.length ≤ B} := by
    rintro _ ⟨x, rfl⟩
    exact ⟨h.enc x, h.short x, rfl⟩
  have hfin : (Set.range h.pass).Finite := (hfinL.image h.dec).subset hsub
  have hmaps : Set.MapsTo h.pass (Set.range h.pass^[N]) (Set.range h.pass^[N]) := by
    rintro _ ⟨x, rfl⟩
    exact ⟨h.pass x, (Function.iterate_succ_apply h.pass N x).symm.trans
      (Function.iterate_succ_apply' h.pass N x)⟩
  have hinj : Set.InjOn h.pass (Set.range h.pass^[N]) := by
    rintro _ ⟨x, rfl⟩ _ ⟨y, rfl⟩ hxy
    apply hN 1 x y
    rw [Function.iterate_succ_apply', Function.iterate_succ_apply']
    exact hxy
  have hS : (Set.range h.pass^[N]).Finite := by
    cases N with
    | zero =>
      have hinj' : Function.Injective h.pass := fun x y hxy => by
        have := hinj ⟨x, rfl⟩ ⟨y, rfl⟩ hxy
        simpa using this
      have : Finite (Set.range h.pass) := hfin
      have : Finite X := Finite.of_injective_finite_range hinj'
      exact Set.toFinite _
    | succ n =>
      refine hfin.subset ?_
      rintro _ ⟨x, rfl⟩
      exact ⟨h.pass^[n] x, (Function.iterate_succ_apply' h.pass n x).symm⟩
  exact (hS.injOn_iff_bijOn_of_mapsTo hmaps).1 hinj

/-- **One relay stops merging.** For every relay with budget `B` there is a step
`N < 2 ^ (B + 1)` after which nothing more is merged: two ideas that are still apart after
`N` retellings stay apart for ever, and the relay permutes the versions that survive `N`
retellings. Whatever further change there is, is drift and can be undone. -/
theorem merging_stops {X : Type*} {B : ℕ} (h : Relay X B) :
    ∃ N < 2 ^ (B + 1),
      (∀ k x y, h.pass^[N + k] x = h.pass^[N + k] y → h.pass^[N] x = h.pass^[N] y) ∧
      Set.BijOn h.pass (Set.range h.pass^[N]) (Set.range h.pass^[N]) := by
  classical
  have hfinL := List.finite_length_le Bool B
  have hsub : Set.range h.pass ⊆ h.dec '' {l : List Bool | l.length ≤ B} := by
    rintro _ ⟨x, rfl⟩
    exact ⟨h.enc x, h.short x, rfl⟩
  have hfin : (Set.range h.pass).Finite := (hfinL.image h.dec).subset hsub
  have hc : hfinL.toFinset.card < 2 ^ (B + 1) :=
    card_lt_two_pow_of_length_lt (B + 1) _ fun l hl =>
      Nat.lt_succ_of_le (by simpa using hl)
  have hcard : (Set.range h.pass).ncard ≤ 2 ^ (B + 1) - 1 := by
    have h1 := Set.ncard_le_ncard hsub (hfinL.image h.dec)
    have h2 := Set.ncard_image_le (f := h.dec) hfinL
    rw [Set.ncard_eq_toFinset_card _ hfinL] at h2
    omega
  obtain ⟨N, hN, hmerge⟩ := merging_stops_of_finite h.pass hfin hcard
  have hpos : 0 < 2 ^ (B + 1) := Nat.pos_of_ne_zero (by positivity)
  exact ⟨N, by omega, hmerge, bijOn_of_merging_stops h N hmerge⟩

end Lossy

/-! ### A worked exchange rate: numbers within `±e` -/

namespace Lossy.Nat

open Channel

/-- **Necessary budget.** If a relay with budget `B` delivers every number below `N` within
`±e`, then `N ≤ (2 e + 1) (2 ^ (B + 1) - 1)`. -/
theorem budget_necessary {B N e : ℕ} (h : Relay ℕ B)
    (hd : ∀ x < N, x ≤ h.pass x + e ∧ h.pass x ≤ x + e) :
    N ≤ (2 * e + 1) * (2 ^ (B + 1) - 1) := by
  have himg := h.card_image_lt (Finset.range N)
  have hfib : ∀ v ∈ (Finset.range N).image h.pass,
      ((Finset.range N).filter fun x => h.pass x = v).card ≤ 2 * e + 1 := by
    intro v _
    have hsub : ((Finset.range N).filter fun x => h.pass x = v) ⊆ Finset.Icc (v - e) (v + e) := by
      intro x hx
      obtain ⟨hxN, hxv⟩ := Finset.mem_filter.1 hx
      have := hd x (Finset.mem_range.1 hxN)
      rw [hxv] at this
      exact Finset.mem_Icc.2 ⟨by omega, by omega⟩
    refine (Finset.card_le_card hsub).trans ?_
    rw [Nat.card_Icc]
    omega
  have hcard := Finset.card_le_mul_card_image (Finset.range N) (2 * e + 1) hfib
  rw [Finset.card_range] at hcard
  exact hcard.trans (Nat.mul_le_mul_left _ (by omega))

/-- **Sufficient budget.** If `N ≤ (2 e + 1) (2 ^ (B + 1) - 1)`, some relay with budget `B`
delivers every number below `N` within `±e`: name the block of `2 e + 1` numbers and decode
to its middle. -/
theorem budget_sufficient {B N e : ℕ} (hN : N ≤ (2 * e + 1) * (2 ^ (B + 1) - 1)) :
    ∃ h : Relay ℕ B, ∀ x < N, x ≤ h.pass x + e ∧ h.pass x ≤ x + e := by
  have hq : ∀ x < N, x / (2 * e + 1) + 1 < 2 ^ (B + 1) := fun x hx => by
    have h1 : x / (2 * e + 1) < 2 ^ (B + 1) - 1 :=
      Nat.div_lt_of_lt_mul (lt_of_lt_of_le hx hN)
    generalize 2 ^ (B + 1) = P at h1 ⊢
    generalize x / (2 * e + 1) = q at h1 ⊢
    omega
  refine ⟨⟨fun x => if x < N then Lossy.code (x / (2 * e + 1)) else [],
      fun l => Lossy.decode l * (2 * e + 1) + e, fun x => ?_⟩, fun x hx => ?_⟩
  · by_cases hx : x < N
    · simp only [hx, ite_true]
      exact Lossy.length_code_le (hq x hx)
    · simp [hx]
  · show x ≤ Lossy.decode (if x < N then Lossy.code (x / (2 * e + 1)) else []) * (2 * e + 1)
        + e + e ∧
      Lossy.decode (if x < N then Lossy.code (x / (2 * e + 1)) else []) * (2 * e + 1) + e
        ≤ x + e
    simp only [hx, ite_true, Lossy.decode_code]
    have h1 := Nat.div_add_mod x (2 * e + 1)
    have h2 := Nat.mod_lt x (by omega : 0 < 2 * e + 1)
    have e3 : x / (2 * e + 1) * (2 * e + 1) = (2 * e + 1) * (x / (2 * e + 1)) := by ring
    constructor <;> omega

/-- **The exchange rate for numbers, exactly.** A relay with budget `B` can deliver every
number below `N` within `±e` if and only if `N ≤ (2 e + 1) (2 ^ (B + 1) - 1)`. -/
theorem budget_iff {B N e : ℕ} :
    (∃ h : Relay ℕ B, ∀ x < N, x ≤ h.pass x + e ∧ h.pass x ≤ x + e) ↔
      N ≤ (2 * e + 1) * (2 ^ (B + 1) - 1) :=
  ⟨fun ⟨h, hd⟩ => budget_necessary h hd, budget_sufficient⟩

/-- The arithmetic form used above is delivery within `e` for the usual distance on `ℕ`. -/
theorem edist_le_iff (x y e : ℕ) :
    edist x y ≤ (((e : ℕ) : NNReal) : ENNReal) ↔ x ≤ y + e ∧ y ≤ x + e := by
  rw [edist_dist, Nat.dist_eq, ENNReal.ofReal_le_iff_le_toReal (by simp)]
  simp only [ENNReal.coe_toReal, NNReal.coe_natCast]
  rw [abs_le]
  constructor
  · rintro ⟨h1, h2⟩
    have h1' : (x : ℝ) ≤ y + e := by linarith
    have h2' : (y : ℝ) ≤ x + e := by linarith
    exact ⟨by exact_mod_cast h1', by exact_mod_cast h2'⟩
  · rintro ⟨h1, h2⟩
    have h1' : (x : ℝ) ≤ y + e := by exact_mod_cast h1
    have h2' : (y : ℝ) ≤ x + e := by exact_mod_cast h2
    exact ⟨by linarith, by linarith⟩

/-- `budget_iff` in the language of the rest of the file. -/
theorem delivers_iff {B N e : ℕ} :
    (∃ h : Relay ℕ B, Lossy.Delivers h.pass ((e : ℕ) : NNReal) {x : ℕ | x < N}) ↔
      N ≤ (2 * e + 1) * (2 ^ (B + 1) - 1) := by
  rw [← budget_iff]
  refine exists_congr fun h => ⟨fun hd x hx => (edist_le_iff _ _ _).1 (hd x hx),
    fun hd x hx => (edist_le_iff _ _ _).2 (hd x hx)⟩

/-- **A chain of different relays can drift without limit on no budget at all.** There are
relays with budget `0`, one for each hop, such that hop `k` passes on `k` whatever it hears.
After `n` hops the idea is `n`. (For one relay iterated this is impossible:
`Lossy.orbit_repeats`.) -/
theorem exists_drifting_chain : ∃ r : ℕ → Relay ℕ 0, ∀ k x, (r k).pass x = k :=
  ⟨fun k => ⟨fun _ => [], fun _ => k, fun _ => by simp⟩, fun _ _ => rfl⟩

/-- A relay with budget `1` that swaps `0` and `1`. -/
def swapRelay : Relay ℕ 1 where
  enc x := if x = 0 then [true] else []
  dec l := if l = [] then 0 else 1
  short x := by split_ifs <;> simp

/-- **Loss is not monotone in depth.** Through `swapRelay`, `0` is one unit off after one
retelling and back where it started after two. -/
theorem swapRelay_pass : swapRelay.pass 0 = 1 ∧ swapRelay.pass (swapRelay.pass 0) = 0 := by
  simp [Relay.pass, swapRelay]

/-- A relay within budget `B` that moves a number down by one at every retelling. -/
def decRelay (B : ℕ) : Relay ℕ B where
  enc x := if x - 1 < 2 ^ B then Nat.bits (x - 1) else []
  dec := Limits.numeral
  short x := by
    by_cases hx : x - 1 < 2 ^ B
    · simp only [hx, ite_true]
      rw [Nat.size_eq_bits_len]
      exact Nat.size_le.2 hx
    · simp [hx]

/-- **Loss that grows with depth, within budget, up to a point.** From any `x ≤ 2 ^ B`,
`n` retellings through `decRelay B` give `x - n` (truncated at `0`): one unit per hop for
the first `x` hops, then nothing more. So with steps of size one every total displacement
from `0` to `min n (2 ^ B)` occurs, and none beyond `2 ^ B` can, by `Lossy.orbit_repeats`.
The shift is reversible: nothing is merged until the chain reaches `0`. -/
theorem decRelay_iterate (B n x : ℕ) (hx : x ≤ 2 ^ B) : (decRelay B).pass^[n] x = x - n := by
  induction n with
  | zero => rfl
  | succ n ih =>
    rw [Function.iterate_succ_apply', ih]
    have h1 : x - n - 1 < 2 ^ B := by
      have : 0 < 2 ^ B := Nat.pos_of_ne_zero (by positivity)
      omega
    show Limits.numeral (if x - n - 1 < 2 ^ B then Nat.bits (x - n - 1) else []) = x - (n + 1)
    simp only [h1, ite_true, Limits.numeral_bits]
    omega

/-- **Merging can go on for `2 ^ B` retellings.** Through `decRelay B`, the numbers `n` and
`0` are still apart after `n - 1` retellings and merged after `n`, for every
`1 ≤ n ≤ 2 ^ B`. So the bound `2 ^ (B + 1)` of `Lossy.merging_stops` is within a factor of
two of what happens. -/
theorem decRelay_merges_late (B n : ℕ) (h1 : 1 ≤ n) (hn : n ≤ 2 ^ B) :
    (decRelay B).pass^[n - 1] n ≠ (decRelay B).pass^[n - 1] 0 ∧
      (decRelay B).pass^[n] n = (decRelay B).pass^[n] 0 := by
  rw [decRelay_iterate B (n - 1) n hn, decRelay_iterate B (n - 1) 0 (Nat.zero_le _),
    decRelay_iterate B n n hn, decRelay_iterate B n 0 (Nat.zero_le _)]
  omega

end Lossy.Nat

end Complexity
