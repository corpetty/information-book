import Complexity.Instances.Kolmogorov
import Complexity.Prefix

/-!
# Instance: a universal prefix machine

`Instances/Kolmogorov.lean` builds a universal interpreter for *plain* complexity; its
domain is not prefix-free, and `Limits.lean` shows that the additive laws fail for it.
`Prefix.lean` shows that the additive laws hold among prefix-free systems but that no
system dominates all of them. This file supplies the missing object: a **partial recursive
function with prefix-free domain that simulates every partial recursive function with
prefix-free domain**.

The construction is the standard one.

* `pf c`     – the *prefix-free restriction* of program `c`. Run `c` in stages; an input
               `w` is accepted at a stage where `c` has halted on `w` and on no other
               string comparable with `w`. Whatever `c` is, the domain of `pf c` is
               prefix-free (`pf_prefixFree`); if the domain of `c` already was, nothing is
               lost (`pf_eq_of_prefixFree`).
* `U`        – read a unary program index, then run the prefix-free restriction of that
               program on the rest of the input.

Results:

* `U_partrec`, `U_prefixFree`    – `U` is partial recursive with prefix-free domain;
* `U_simulates`                  – `U` runs every partial recursive function with
                                   prefix-free domain from a fixed prefix;
* `K_U_le`, `dominates`          – optimality: prefix complexity relative to `U` is minimal
                                   up to an additive constant;
* `invariance`                   – any two optimal prefix machines agree up to a constant;
* `K_U_le_linear`, `K_U_lt_top` – the machine is not empty: every number has a program;
* `K_pair_le`                    – subadditivity: `K(⟨x, y⟩) ≤ K(x) + K(y) + c`.
-/

namespace Complexity

namespace PrefixMachine

open Nat.Partrec (Code)
open Nat.Partrec.Code (evaln)
open Encodable Primrec
open Kolmogorov (sys run header index payload)
open Limits (PrefixFree)

/-! ### The prefix-free restriction of a program -/

/-- `o` is a string different from `w` and comparable with it. -/
def clash (o : Option (List Bool)) (w : List Bool) : Bool :=
  Option.casesOn (motive := fun _ => Bool) o false fun q =>
    (!decide (q = w)) && (decide (q = w.take q.length) || decide (w = q.take w.length))

theorem clash_eq_true {o : Option (List Bool)} {w : List Bool} :
    clash o w = true ↔ ∃ q, o = some q ∧ q ≠ w ∧ (q <+: w ∨ w <+: q) := by
  rcases o with _ | q
  · simp [clash]
  · simp [clash, List.prefix_iff_eq_take]

/-- By stage `t`, program `c` has halted on a string comparable with `w` other than `w`. -/
def blocked (c : Code) (w : List Bool) (t : ℕ) : Bool :=
  (List.range t).any fun n => (evaln t c n).isSome && clash (decode₂ (List Bool) n) w

theorem blocked_eq_true {c : Code} {w : List Bool} {t : ℕ} :
    blocked c w t = true ↔
      ∃ q, q ≠ w ∧ (q <+: w ∨ w <+: q) ∧ encode q < t ∧ (evaln t c (encode q)).isSome := by
  simp only [blocked, List.any_eq_true, List.mem_range, Bool.and_eq_true, clash_eq_true]
  constructor
  · rintro ⟨n, hn, hs, q, hq, h1, h2⟩
    obtain rfl := decode₂_eq_some.1 hq
    exact ⟨q, h1, h2, hn, hs⟩
  · rintro ⟨q, h1, h2, hn, hs⟩
    exact ⟨encode q, hn, hs, q, decode₂_encode q, h1, h2⟩

/-- Stage `t` of the restricted program: the output of `c` on `w`, if it has appeared and
`w` is not blocked. -/
def step (c : Code) (w : List Bool) (t : ℕ) : Option ℕ :=
  bif blocked c w t then none else evaln t c (encode w)

theorem step_eq_some {c : Code} {w : List Bool} {t y : ℕ} :
    step c w t = some y ↔ blocked c w t = false ∧ evaln t c (encode w) = some y := by
  unfold step
  cases blocked c w t <;> simp

/-- The **prefix-free restriction** of a program. -/
def pf (c : Code) : List Bool →. ℕ := fun w => Nat.rfindOpt (step c w)

/-- The restriction only removes programs. -/
theorem pf_sound {c : Code} {w : List Bool} {y : ℕ} (h : y ∈ pf c w) :
    y ∈ c.eval (encode w) := by
  obtain ⟨t, ht⟩ := Nat.rfindOpt_spec h
  exact Nat.Partrec.Code.evaln_sound (step_eq_some.1 ht).2

/-- The domain of a restricted program is **prefix-free**, whatever the program. -/
theorem pf_prefixFree (c : Code) {w z : List Bool} (h : (pf c w).Dom)
    (h' : (pf c (w ++ z)).Dom) : z = [] := by
  obtain ⟨t, y, ht⟩ := Nat.rfindOpt_dom.1 h
  obtain ⟨t', y', ht'⟩ := Nat.rfindOpt_dom.1 h'
  obtain ⟨hb, he⟩ := step_eq_some.1 ht
  obtain ⟨hb', he'⟩ := step_eq_some.1 ht'
  by_contra hz
  have hne : w ≠ w ++ z := fun h => hz (by simpa using h)
  rcases le_total t t' with hle | hle
  · have hbl : blocked c (w ++ z) t' = true :=
      blocked_eq_true.2 ⟨w, hne, Or.inl (List.prefix_append w z),
        lt_of_lt_of_le (Nat.Partrec.Code.evaln_bound he) hle, by
          rw [Nat.Partrec.Code.evaln_mono hle he]; rfl⟩
    rw [hb'] at hbl
    cases hbl
  · have hbl : blocked c w t = true :=
      blocked_eq_true.2 ⟨w ++ z, hne.symm, Or.inr (List.prefix_append w z),
        lt_of_lt_of_le (Nat.Partrec.Code.evaln_bound he') hle, by
          rw [Nat.Partrec.Code.evaln_mono hle he']; rfl⟩
    rw [hb] at hbl
    cases hbl

/-- A program whose domain is already prefix-free is **unchanged** by the restriction. -/
theorem pf_eq_of_prefixFree {c : Code}
    (hc : ∀ w z : List Bool, (c.eval (encode w)).Dom → (c.eval (encode (w ++ z))).Dom → z = [])
    (w : List Bool) : pf c w = c.eval (encode w) := by
  have key : ∀ y, y ∈ c.eval (encode w) → (pf c w).Dom := by
    intro y hy
    obtain ⟨t, ht⟩ := Nat.Partrec.Code.evaln_complete.1 hy
    refine Nat.rfindOpt_dom.2 ⟨t, y, step_eq_some.2 ⟨?_, ht⟩⟩
    by_contra hb
    rw [Bool.not_eq_false] at hb
    obtain ⟨q, hne, hcmp, -, hs⟩ := blocked_eq_true.1 hb
    obtain ⟨y', hy'⟩ := Option.isSome_iff_exists.1 hs
    have hq : (c.eval (encode q)).Dom :=
      Part.dom_iff_mem.2 ⟨y', Nat.Partrec.Code.evaln_sound hy'⟩
    have hw : (c.eval (encode w)).Dom := Part.dom_iff_mem.2 ⟨y, hy⟩
    rcases hcmp with ⟨z, rfl⟩ | ⟨z, rfl⟩
    · exact hne (by rw [hc q z hq hw, List.append_nil])
    · exact hne (by rw [hc w z hw hq, List.append_nil])
  refine Part.ext fun y => ⟨pf_sound, fun hy => ?_⟩
  have hd := key y hy
  have hu := Part.mem_unique (pf_sound (Part.get_mem hd)) hy
  rw [← hu]
  exact Part.get_mem hd

/-! ### Computability of the restriction -/

theorem clash_primrec : Primrec₂ clash :=
  (option_casesOn fst (const false)
    (Primrec.and.comp
      (Primrec.not.comp (Primrec.eq.decide.comp snd (snd.comp fst)))
      (Primrec.or.comp
        (Primrec.eq.decide.comp snd
          (list_take.comp (list_length.comp snd) (snd.comp fst)))
        (Primrec.eq.decide.comp (snd.comp fst)
          (list_take.comp (list_length.comp (snd.comp fst)) snd)))).to₂).of_eq fun p => by
    rcases p with ⟨_ | _, _⟩ <;> rfl

theorem blocked_primrec :
    Primrec fun a : (Code × List Bool) × ℕ => blocked a.1.1 a.1.2 a.2 :=
  list_any (list_range.comp snd)
    (Primrec.and.comp
      (option_isSome.comp (Nat.Partrec.Code.primrec_evaln.comp
        (((snd.comp fst).pair (fst.comp (fst.comp fst))).pair snd)))
      (clash_primrec.comp (Primrec.decode₂.comp snd) (snd.comp (fst.comp fst)))).to₂

theorem step_primrec : Primrec fun a : (Code × List Bool) × ℕ => step a.1.1 a.1.2 a.2 :=
  Primrec.cond blocked_primrec (const none)
    (Nat.Partrec.Code.primrec_evaln.comp
      ((snd.pair (fst.comp fst)).pair (Primrec.encode.comp (snd.comp fst))))

/-- The prefix-free restriction is partial recursive, jointly in the program and the
input. -/
theorem pf_partrec : Partrec₂ pf :=
  Partrec.rfindOpt (f := fun (a : Code × List Bool) t => step a.1 a.2 t) step_primrec.to_comp

/-! ### The universal prefix machine -/

/-- The input has a complete header: some `false` ends the leading `true`s. -/
def wf (l : List Bool) : Bool := !decide (l.dropWhile id = [])

/-- A **universal prefix machine**: read a unary program index, then run the prefix-free
restriction of that program on the rest of the input. Inputs with no complete header are
rejected. -/
def U : List Bool →. ℕ := fun l =>
  Nat.rfindOpt fun t =>
    bif wf l then step (Denumerable.ofNat Code (index l)) (payload l) t else none

theorem U_of_wf {l : List Bool} (h : wf l = true) :
    U l = pf (Denumerable.ofNat Code (index l)) (payload l) := by
  simp only [U, h, Bool.cond_true]
  rfl

theorem U_not_dom {l : List Bool} (h : wf l = false) : ¬(U l).Dom := by
  intro hd
  obtain ⟨t, y, hy⟩ := Nat.rfindOpt_dom.1 hd
  simp [h] at hy

theorem wf_header (n : ℕ) (l : List Bool) : wf (header n ++ l) = true := by
  simp [wf, Kolmogorov.dropWhile_header_append]

theorem eq_header_of_wf {l : List Bool} (h : wf l = true) :
    l = header (index l) ++ payload l := by
  have hd : l.dropWhile id ≠ [] := by simpa [wf] using h
  have h1 : l.takeWhile id = List.replicate (index l) true :=
    List.eq_replicate_iff.2 ⟨rfl, fun b hb => by simpa using List.mem_takeWhile_imp hb⟩
  have h2 : l.dropWhile id = false :: payload l := by
    have h3 := List.head_dropWhile_not id hd
    simp only [id] at h3
    conv_lhs => rw [← List.cons_head_tail hd]
    rw [h3]
    rfl
  calc l = l.takeWhile id ++ l.dropWhile id := List.takeWhile_append_dropWhile.symm
    _ = header (index l) ++ payload l := by rw [h1, h2]; simp [header]

/-- **`U` runs the prefix-free restriction of every program from its header.** -/
theorem U_header_append (c : Code) (l : List Bool) : U (header (encode c) ++ l) = pf c l := by
  rw [U_of_wf (wf_header _ _), Kolmogorov.index_header_append,
    Kolmogorov.payload_header_append, Denumerable.ofNat_encode]

/-- The domain of `U` is **prefix-free**. -/
theorem U_prefixFree {w z : List Bool} (h : (U w).Dom) (h' : (U (w ++ z)).Dom) : z = [] := by
  have hw : wf w = true := by
    by_contra hh
    exact U_not_dom (by simpa using hh) h
  have e := eq_header_of_wf hw
  rw [U_of_wf hw] at h
  have e' : w ++ z = header (index w) ++ (payload w ++ z) := by
    rw [← List.append_assoc, ← e]
  rw [e', U_of_wf (wf_header _ _), Kolmogorov.index_header_append,
    Kolmogorov.payload_header_append] at h'
  exact pf_prefixFree _ h h'

theorem wf_primrec : Primrec wf :=
  Primrec.not.comp (Primrec.eq.decide.comp (list_dropWhile Primrec.id) (const []))

/-- The universal prefix machine is **partial recursive**. -/
theorem U_partrec : Partrec U :=
  Partrec.rfindOpt
    (f := fun (l : List Bool) t =>
      bif wf l then step (Denumerable.ofNat Code (index l)) (payload l) t else none)
    (Primrec.cond (wf_primrec.comp fst)
      (step_primrec.comp
        ((((Primrec.ofNat Code).comp (Kolmogorov.index_primrec.comp fst)).pair
          (Kolmogorov.payload_primrec.comp fst)).pair snd))
      (const none)).to_comp

/-! ### Universality -/

/-- Every partial recursive description method is computed by a program. -/
theorem exists_run_eq {φ : List Bool →. ℕ} (hφ : Partrec φ) : ∃ c : Code, run c = φ := by
  have h : Nat.Partrec fun n =>
      Part.bind (decode (α := List Bool) n) fun a => (φ a).map encode := hφ
  obtain ⟨c, hc⟩ := Nat.Partrec.Code.exists_code.1 h
  refine ⟨c, funext fun l => ?_⟩
  show c.eval (encode l) = φ l
  rw [hc]
  simp only [encodek, Part.coe_some, Part.bind_some]
  exact Part.map_id' encode_nat _

/-- A description method is a **prefix machine** if it is partial recursive and its domain
is prefix-free. -/
def IsPrefixMachine (φ : List Bool →. ℕ) : Prop :=
  Partrec φ ∧ ∀ w z : List Bool, (φ w).Dom → (φ (w ++ z)).Dom → z = []

theorem U_isPrefixMachine : IsPrefixMachine U := ⟨U_partrec, fun _ _ => U_prefixFree⟩

/-- **Universality.** `U` runs every prefix machine from a fixed prefix. -/
theorem U_simulates {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ) :
    ∃ p : List Bool, ∀ l, U (p ++ l) = φ l := by
  obtain ⟨c, rfl⟩ := exists_run_eq hφ.1
  exact ⟨header (encode c), fun l => by
    rw [U_header_append, pf_eq_of_prefixFree hφ.2]
    rfl⟩

/-- **Optimality.** Prefix complexity relative to `U` is at most a constant above prefix
complexity relative to any prefix machine. -/
theorem K_U_le {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ) :
    ∃ k : ℕ, ∀ x, Kolmogorov.K U x ≤ Kolmogorov.K φ x + k := by
  obtain ⟨p, hp⟩ := U_simulates hφ
  exact ⟨p.length, Kolmogorov.K_le_add_of_prefix U φ p hp⟩

/-- The description system of a prefix machine is self-delimiting. -/
theorem sys_prefixFree {φ : List Bool →. ℕ}
    (hφ : ∀ w z : List Bool, (φ w).Dom → (φ (w ++ z)).Dom → z = []) : PrefixFree (sys φ) :=
  fun _ _ _ _ h h' => hφ _ _ (Part.dom_iff_mem.2 ⟨_, h⟩) (Part.dom_iff_mem.2 ⟨_, h'⟩)

theorem sys_U_prefixFree : PrefixFree (sys U) := sys_prefixFree fun _ _ => U_prefixFree

/-- The class of prefix machines, as description systems. -/
def prefixMachines : Set (DescSystem (List Bool) ℕ ℕ∞) :=
  {S | ∃ φ, IsPrefixMachine φ ∧ S = sys φ}

theorem sys_U_mem : sys U ∈ prefixMachines := ⟨U, U_isPrefixMachine, rfl⟩

/-- In the language of the general theory: `U` dominates every prefix machine. This is the
restricted class that `Prefix.not_exists_universal` shows to be necessary. -/
theorem dominates {S : DescSystem (List Bool) ℕ ℕ∞} (hS : S ∈ prefixMachines) :
    DescSystem.Dominates (sys U) S := by
  obtain ⟨φ, hφ, rfl⟩ := hS
  exact K_U_le hφ

/-- **Invariance for prefix complexity.** Any other optimal prefix machine agrees with `U`
up to an additive constant. -/
theorem invariance {U' : List Bool →. ℕ} (hU' : IsPrefixMachine U')
    (hopt : ∀ S ∈ prefixMachines, DescSystem.Dominates (sys U') S) :
    ∃ k : ℕ, ∀ x, Kolmogorov.K U x ≤ Kolmogorov.K U' x + k ∧
      Kolmogorov.K U' x ≤ Kolmogorov.K U x + k :=
  DescSystem.invariance prefixMachines sys_U_mem ⟨U', hU', rfl⟩ (fun _ hS => dominates hS) hopt

/-! ### The machine is not empty

Every statement above would hold for a machine that accepts nothing. It does not: the
unary numerals form a prefix machine, so every number has a `U`-program. -/

/-- The unary machine: `n` times `true`, then `false`, describes `n`. -/
def unaryM : List Bool →. ℕ := fun l =>
  ((if wf l = true ∧ payload l = [] then some (index l) else none : Option ℕ) : Part ℕ)

theorem mem_unaryM {l : List Bool} {x : ℕ} :
    x ∈ unaryM l ↔ (wf l = true ∧ payload l = []) ∧ index l = x := by
  unfold unaryM
  rw [Part.mem_coe]
  split_ifs with h
  · simp [h]
  · simp [h]

theorem unaryM_isPrefixMachine : IsPrefixMachine unaryM := by
  refine ⟨Computable.ofOption (Primrec.ite
    (PrimrecPred.and (Primrec.eq.comp wf_primrec (const true))
      (Primrec.eq.comp Kolmogorov.payload_primrec (const [])))
    (option_some.comp Kolmogorov.index_primrec) (const none)).to_comp, fun w z h h' => ?_⟩
  obtain ⟨⟨hw, hp⟩, -⟩ := mem_unaryM.1 (Part.get_mem h)
  obtain ⟨⟨-, hp'⟩, -⟩ := mem_unaryM.1 (Part.get_mem h')
  have e := eq_header_of_wf hw
  rw [hp, List.append_nil] at e
  rw [e, Kolmogorov.payload_header_append] at hp'
  exact hp'

/-- **Every number has a program**: `K(x) ≤ x + c` for the universal prefix machine. -/
theorem K_U_le_linear : ∃ c : ℕ, ∀ x : ℕ, Kolmogorov.K U x ≤ ((x + c : ℕ) : ℕ∞) := by
  obtain ⟨k, hk⟩ := K_U_le unaryM_isPrefixMachine
  refine ⟨1 + k, fun x => (hk x).trans ?_⟩
  have hx : x ∈ unaryM (header x) := by
    refine mem_unaryM.2 ⟨⟨?_, ?_⟩, ?_⟩
    · simpa using wf_header x []
    · simpa using Kolmogorov.payload_header_append x []
    · simpa using Kolmogorov.index_header_append x []
  have h := Kolmogorov.K_le_length hx
  rw [Kolmogorov.length_header] at h
  refine (add_le_add h le_rfl).trans (le_of_eq ?_)
  push_cast
  ring

theorem K_U_lt_top (x : ℕ) : Kolmogorov.K U x < ⊤ := by
  obtain ⟨c, hc⟩ := K_U_le_linear
  exact lt_of_le_of_lt (hc x) (ENat.natCast_lt_top _)

/-! ### Subadditivity

The additive law `K(x, y) ≤ K(x) + K(y) + c` is false for plain complexity
(`Limits.not_forall_K_obj_le`) and holds exactly, between suitable systems, for
self-delimiting ones (`Prefix.pair`). For the universal prefix machine it holds with a
constant, because the machine that reads two programs one after the other is itself a
prefix machine. -/

/-- Stage `⟨j, t⟩` of the pairing machine: split the input after `j` bits and run the
program on both halves for `t` steps. -/
def pairStep (c : Code) (w : List Bool) (n : ℕ) : Option ℕ :=
  (evaln n.unpair.2 c (encode (w.take n.unpair.1))).bind fun x =>
    (evaln n.unpair.2 c (encode (w.drop n.unpair.1))).map fun y => Nat.pair x y

/-- The **pairing machine** of a program: read two programs, output the pair of their
outputs. -/
def pairM (c : Code) : List Bool →. ℕ := fun w => Nat.rfindOpt (pairStep c w)

theorem pairStep_primrec (c : Code) : Primrec₂ (pairStep c) :=
  have hj : Primrec fun a : List Bool × ℕ => a.2.unpair.1 := fst.comp (Primrec.unpair.comp snd)
  have ht : Primrec fun a : List Bool × ℕ => a.2.unpair.2 := snd.comp (Primrec.unpair.comp snd)
  have hT : Primrec fun a : List Bool × ℕ => evaln a.2.unpair.2 c (encode (a.1.take a.2.unpair.1)) :=
    Nat.Partrec.Code.primrec_evaln.comp
      ((ht.pair (const c)).pair (Primrec.encode.comp (list_take.comp hj fst)))
  have hD : Primrec fun a : List Bool × ℕ => evaln a.2.unpair.2 c (encode (a.1.drop a.2.unpair.1)) :=
    Nat.Partrec.Code.primrec_evaln.comp
      ((ht.pair (const c)).pair (Primrec.encode.comp (list_drop.comp hj fst)))
  (option_bind hT
    (option_map (hD.comp fst) (Primrec₂.natPair.comp (snd.comp fst) snd).to₂).to₂).to₂

theorem pairM_partrec (c : Code) : Partrec (pairM c) :=
  Partrec.rfindOpt (pairStep_primrec c).to_comp

theorem mem_pairM {c : Code} {w : List Bool} {v : ℕ} (h : v ∈ pairM c w) :
    ∃ p q x y, w = p ++ q ∧ x ∈ run c p ∧ y ∈ run c q ∧ v = Nat.pair x y := by
  obtain ⟨n, hn⟩ := Nat.rfindOpt_spec h
  simp only [pairStep, Option.mem_def, Option.bind_eq_some_iff, Option.map_eq_some_iff] at hn
  obtain ⟨x, hx, y, hy, rfl⟩ := hn
  exact ⟨w.take n.unpair.1, w.drop n.unpair.1, x, y, (List.take_append_drop _ _).symm,
    Nat.Partrec.Code.evaln_sound hx, Nat.Partrec.Code.evaln_sound hy, rfl⟩

/-- In a prefix-free domain, a string has at most one prefix that is a program. -/
theorem prefix_unique {φ : List Bool →. ℕ}
    (hφ : ∀ w z : List Bool, (φ w).Dom → (φ (w ++ z)).Dom → z = []) {p p' l : List Bool}
    (hp : p <+: l) (hp' : p' <+: l) (hd : (φ p).Dom) (hd' : (φ p').Dom) : p = p' := by
  rcases List.prefix_or_prefix_of_prefix hp hp' with ⟨z, rfl⟩ | ⟨z, rfl⟩
  · rw [hφ p z hd hd', List.append_nil]
  · rw [hφ p' z hd' hd, List.append_nil]

theorem pair_mem_pairM {c : Code}
    (hc : ∀ w z : List Bool, (run c w).Dom → (run c (w ++ z)).Dom → z = [])
    {p q : List Bool} {x y : ℕ} (hx : x ∈ run c p) (hy : y ∈ run c q) :
    Nat.pair x y ∈ pairM c (p ++ q) := by
  obtain ⟨t1, h1⟩ := Nat.Partrec.Code.evaln_complete.1 hx
  obtain ⟨t2, h2⟩ := Nat.Partrec.Code.evaln_complete.1 hy
  have h1' := Nat.Partrec.Code.evaln_mono (le_max_left t1 t2) h1
  have h2' := Nat.Partrec.Code.evaln_mono (le_max_right t1 t2) h2
  have hdom : (pairM c (p ++ q)).Dom := by
    refine Nat.rfindOpt_dom.2 ⟨Nat.pair p.length (max t1 t2), Nat.pair x y, ?_⟩
    simp only [pairStep, Nat.unpair_pair, List.take_left', List.drop_left', Option.mem_def,
      Option.bind_eq_some_iff, Option.map_eq_some_iff]
    exact ⟨x, h1', y, h2', rfl⟩
  obtain ⟨p', q', x', y', hw, hx', hy', hv⟩ := mem_pairM (Part.get_mem hdom)
  have hpp : p = p' :=
    prefix_unique hc (List.prefix_append p q) (hw ▸ List.prefix_append p' q')
      (Part.dom_iff_mem.2 ⟨x, hx⟩) (Part.dom_iff_mem.2 ⟨x', hx'⟩)
  subst hpp
  obtain rfl : q = q' := List.append_cancel_left hw
  obtain rfl := Part.mem_unique hx hx'
  obtain rfl := Part.mem_unique hy hy'
  rw [← hv]
  exact Part.get_mem hdom

theorem pairM_prefixFree {c : Code}
    (hc : ∀ w z : List Bool, (run c w).Dom → (run c (w ++ z)).Dom → z = [])
    {w z : List Bool} (h : (pairM c w).Dom) (h' : (pairM c (w ++ z)).Dom) : z = [] := by
  obtain ⟨p, q, x, y, rfl, hx, hy, -⟩ := mem_pairM (Part.get_mem h)
  obtain ⟨p', q', x', y', hw, hx', hy', -⟩ := mem_pairM (Part.get_mem h')
  have hpp : p = p' :=
    prefix_unique hc (l := p ++ q ++ z) (by rw [List.append_assoc]; exact List.prefix_append _ _)
      (hw ▸ List.prefix_append p' q') (Part.dom_iff_mem.2 ⟨x, hx⟩) (Part.dom_iff_mem.2 ⟨x', hx'⟩)
  subst hpp
  rw [List.append_assoc] at hw
  obtain rfl : q ++ z = q' := List.append_cancel_left hw
  exact hc q z (Part.dom_iff_mem.2 ⟨y, hy⟩) (Part.dom_iff_mem.2 ⟨y', hy'⟩)

/-- For every prefix machine there is a prefix machine that runs it twice and pairs the
outputs. -/
theorem exists_pair_machine {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ) :
    ∃ M : List Bool →. ℕ, IsPrefixMachine M ∧
      ∀ (p q : List Bool) (x y : ℕ), x ∈ φ p → y ∈ φ q → Nat.pair x y ∈ M (p ++ q) := by
  obtain ⟨c, rfl⟩ := exists_run_eq hφ.1
  exact ⟨pairM c, ⟨pairM_partrec c, fun _ _ => pairM_prefixFree hφ.2⟩,
    fun _ _ _ _ => pair_mem_pairM hφ.2⟩

/-- **Subadditivity of prefix complexity**: `K(⟨x, y⟩) ≤ K(x) + K(y) + c` for the universal
prefix machine. -/
theorem K_pair_le :
    ∃ c : ℕ, ∀ x y, Kolmogorov.K U (Nat.pair x y) ≤ Kolmogorov.K U x + Kolmogorov.K U y + c := by
  obtain ⟨M, hM, hpair⟩ := exists_pair_machine U_isPrefixMachine
  obtain ⟨k, hk⟩ := K_U_le hM
  refine ⟨k, fun x y => (hk _).trans (add_le_add ?_ le_rfl)⟩
  rcases eq_or_ne (Kolmogorov.K U x) ⊤ with hx | hx
  · simp [hx]
  rcases eq_or_ne (Kolmogorov.K U y) ⊤ with hy | hy
  · simp [hy]
  obtain ⟨p, hp, hpc⟩ := (sys U).exists_cost_eq_K hx
  obtain ⟨q, hq, hqc⟩ := (sys U).exists_cost_eq_K hy
  have h := Kolmogorov.K_le_length (hpair p q x y hp hq)
  have e : Kolmogorov.K U x + Kolmogorov.K U y = ((p ++ q).length : ℕ∞) := by
    rw [List.length_append, Nat.cast_add]
    exact (congrArg₂ (· + ·) hpc hqc).symm
  rw [e]
  exact h

end PrefixMachine

end Complexity
