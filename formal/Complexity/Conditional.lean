import Complexity.Levin

/-!
# Conditional prefix complexity and the additive laws for the universal machine

`Prefix.lean` proves the additive laws of self-delimiting description between *suitable*
systems: the composite system is built for the occasion. This file transfers them to the
one universal prefix machine `U` of `Instances/PrefixMachine.lean`, where each holds up to
an additive constant.

Two constructions do the work.

* **A universal conditional prefix machine** `condU a`: read a unary program index, then
  run the prefix-free restriction of that program *with `a` supplied* (by the s-m-n
  function `Code.curry`) on the rest of the input. `condK a y`, written `K(y | a)`, is the
  complexity of `y` relative to `condU a`.
* **The dependent-pair machine** `depM`: read a program for `a` on one prefix machine, then
  hand the rest of the input to a second machine that knows `a`. If the second machine is
  prefix-free for every `a`, so is the composite.

Results (all for `U`, all with a constant that does not depend on the arguments):

* `condU_simulates`, `condK_le` – `condU` is optimal among conditional prefix machines;
* `K_pair_le_add_condK`         – the **chain rule**, easy half:
                                  `K(⟨x, y⟩) ≤ K(x) + K(y | x) + c`;
* `K_le_add_condK`              – `K(y) ≤ K(x) + K(y | x) + c`;
* `condK_le_K`                  – conditioning does not hurt: `K(y | x) ≤ K(y) + c`;
* `condK_map_le`                – `K(f x | x) ≤ c` for computable `f`;
* `condK_le_length`, `K_twoPart_le` – the **two-part code**: if `e a` enumerates a set of at
                                  most `2 ^ ℓ a` elements, each element `y` of it has
                                  `K(y | a) ≤ ℓ a + c` and `K(y) ≤ K(a) + ℓ a + c`. This is
                                  "micro ≤ macro + log W" for the universal machine;
* `exists_condK_ge`, `card_condK_lt` – and that is tight given the macrostate: some element
                                  has `K(y | a) ≥ ℓ a`, and fewer than `2 ^ m` numbers have
                                  `K(y | a) < m` (counting; true for every machine);
* `K_iterate_le`, `K_iterate_le_log` – the **logarithmic growth law**:
                                  `K(fᵗ x) ≤ K(x) + K(t) + c ≤ K(x) + 2 log₂ (t + 1) + c'`
                                  for computable `f`.

Only upper bounds are proved in this file. The reverse of the chain rule holds with the
condition `⟨x, K(x)⟩` in place of `x`; that is symmetry of information, proved in
`Symmetry.lean` with Levin's request list re-issued for each condition.
-/

namespace Complexity

namespace Conditional

open Nat.Partrec (Code)
open Nat.Partrec.Code (evaln)
open Encodable Primrec
open Kolmogorov (sys run header index payload)
open PrefixMachine

/-! ### Conditional prefix machines and the universal one -/

/-- A **conditional prefix machine**: partial recursive in the condition and the input
together, with a prefix-free domain for every condition. -/
def IsCondPrefixMachine (ψ : ℕ → List Bool →. ℕ) : Prop :=
  Partrec₂ ψ ∧ ∀ (a : ℕ) (w z : List Bool), (ψ a w).Dom → (ψ a (w ++ z)).Dom → z = []

/-- The **universal conditional prefix machine**: read a unary program index, then run the
prefix-free restriction of that program, with the condition `a` supplied, on the rest. -/
def condU (a : ℕ) : List Bool →. ℕ := fun l =>
  Nat.rfindOpt fun t =>
    bif wf l then step (Code.curry (Denumerable.ofNat Code (index l)) a) (payload l) t
    else none

theorem condU_of_wf (a : ℕ) {l : List Bool} (h : wf l = true) :
    condU a l = pf (Code.curry (Denumerable.ofNat Code (index l)) a) (payload l) := by
  simp only [condU, h, Bool.cond_true]
  rfl

theorem condU_not_dom (a : ℕ) {l : List Bool} (h : wf l = false) : ¬(condU a l).Dom := by
  intro hd
  obtain ⟨t, y, hy⟩ := Nat.rfindOpt_dom.1 hd
  simp [h] at hy

theorem condU_header_append (c : Code) (a : ℕ) (l : List Bool) :
    condU a (header (encode c) ++ l) = pf (Code.curry c a) l := by
  rw [condU_of_wf a (wf_header _ _), Kolmogorov.index_header_append,
    Kolmogorov.payload_header_append, Denumerable.ofNat_encode]

/-- For every condition the domain of `condU` is prefix-free. -/
theorem condU_prefixFree (a : ℕ) {w z : List Bool} (h : (condU a w).Dom)
    (h' : (condU a (w ++ z)).Dom) : z = [] := by
  have hw : wf w = true := by
    by_contra hh
    exact condU_not_dom a (by simpa using hh) h
  have e := eq_header_of_wf hw
  rw [condU_of_wf a hw] at h
  have e' : w ++ z = header (index w) ++ (payload w ++ z) := by
    rw [← List.append_assoc, ← e]
  rw [e', condU_of_wf a (wf_header _ _), Kolmogorov.index_header_append,
    Kolmogorov.payload_header_append] at h'
  exact pf_prefixFree _ h h'

theorem condU_partrec : Partrec₂ condU :=
  Partrec.rfindOpt
    (f := fun (x : ℕ × List Bool) t =>
      bif wf x.2 then step (Code.curry (Denumerable.ofNat Code (index x.2)) x.1) (payload x.2) t
      else none)
    (Primrec.cond (wf_primrec.comp (snd.comp fst))
      (step_primrec.comp
        (((Nat.Partrec.Code.primrec₂_curry.comp
            ((Primrec.ofNat Code).comp (Kolmogorov.index_primrec.comp (snd.comp fst)))
            (fst.comp fst)).pair
          (Kolmogorov.payload_primrec.comp (snd.comp fst))).pair snd))
      (const none)).to_comp

theorem condU_isCondPrefixMachine : IsCondPrefixMachine condU :=
  ⟨condU_partrec, fun a _ _ => condU_prefixFree a⟩

/-- Every partial recursive two-argument description method is computed by a program. -/
theorem exists_code₂ {ψ : ℕ → List Bool →. ℕ} (hψ : Partrec₂ ψ) :
    ∃ d : Code, ∀ a l, d.eval (encode (a, l)) = ψ a l := by
  have h : Nat.Partrec fun n =>
      Part.bind (decode (α := ℕ × List Bool) n) fun x : ℕ × List Bool =>
        (ψ x.1 x.2).map encode := hψ
  obtain ⟨d, hd⟩ := Nat.Partrec.Code.exists_code.1 h
  refine ⟨d, fun a l => ?_⟩
  rw [hd]
  simp only [encodek, Part.coe_some, Part.bind_some]
  exact Part.map_id' (fun _ => rfl) _

/-- **Universality.** `condU` runs every conditional prefix machine from a fixed prefix,
the same for all conditions. -/
theorem condU_simulates {ψ : ℕ → List Bool →. ℕ} (hψ : IsCondPrefixMachine ψ) :
    ∃ p : List Bool, ∀ a l, condU a (p ++ l) = ψ a l := by
  obtain ⟨d, hd⟩ := exists_code₂ hψ.1
  have hev : ∀ a l, (Code.curry d a).eval (encode l) = ψ a l := fun a l => by
    rw [Nat.Partrec.Code.eval_curry]
    exact hd a l
  refine ⟨header (encode d), fun a l => ?_⟩
  rw [condU_header_append, pf_eq_of_prefixFree (fun w z h h' => ?_), hev]
  rw [hev] at h h'
  exact hψ.2 a w z h h'

/-- **Conditional prefix complexity** `K(y | a)`: the length of the shortest program from
which the universal conditional machine, given `a`, produces `y`. -/
noncomputable def condK (a y : ℕ) : ℕ∞ := Kolmogorov.K (condU a) y

/-- **Optimality.** Conditional complexity is at most a constant above complexity relative
to any conditional prefix machine, uniformly in the condition. -/
theorem condK_le {ψ : ℕ → List Bool →. ℕ} (hψ : IsCondPrefixMachine ψ) :
    ∃ k : ℕ, ∀ a y, condK a y ≤ Kolmogorov.K (ψ a) y + k := by
  obtain ⟨p, hp⟩ := condU_simulates hψ
  exact ⟨p.length, fun a => Kolmogorov.K_le_add_of_prefix (condU a) (ψ a) p (hp a)⟩

/-! ### The dependent-pair machine -/

/-- Stage `⟨j, t⟩` of the dependent-pair machine: split the input after `j` bits, run the
first program on the first part for `t` steps, and the second program on its output
together with the second part. -/
def depStep (c d : Code) (w : List Bool) (n : ℕ) : Option ℕ :=
  (evaln n.unpair.2 c (encode (w.take n.unpair.1))).bind fun a =>
    evaln n.unpair.2 d (encode (a, w.drop n.unpair.1))

/-- The **dependent-pair machine**: read a program for `a`, then let a second machine that
knows `a` read the rest. -/
def depM (c d : Code) : List Bool →. ℕ := fun w => Nat.rfindOpt (depStep c d w)

theorem depStep_primrec (c d : Code) : Primrec₂ (depStep c d) :=
  have hj : Primrec fun a : List Bool × ℕ => a.2.unpair.1 := fst.comp (Primrec.unpair.comp snd)
  have ht : Primrec fun a : List Bool × ℕ => a.2.unpair.2 := snd.comp (Primrec.unpair.comp snd)
  have hT : Primrec fun a : List Bool × ℕ => evaln a.2.unpair.2 c (encode (a.1.take a.2.unpair.1)) :=
    Nat.Partrec.Code.primrec_evaln.comp
      ((ht.pair (const c)).pair (Primrec.encode.comp (list_take.comp hj fst)))
  have hD : Primrec fun b : (List Bool × ℕ) × ℕ =>
      evaln b.1.2.unpair.2 d (encode (b.2, b.1.1.drop b.1.2.unpair.1)) :=
    Nat.Partrec.Code.primrec_evaln.comp
      (((ht.comp fst).pair (const d)).pair
        (Primrec.encode.comp (snd.pair (list_drop.comp (hj.comp fst) (fst.comp fst)))))
  (option_bind hT hD.to₂).to₂

theorem depM_partrec (c d : Code) : Partrec (depM c d) :=
  Partrec.rfindOpt (depStep_primrec c d).to_comp

theorem mem_depM {c d : Code} {w : List Bool} {v : ℕ} (h : v ∈ depM c d w) :
    ∃ p q a, w = p ++ q ∧ a ∈ run c p ∧ v ∈ d.eval (encode (a, q)) := by
  obtain ⟨n, hn⟩ := Nat.rfindOpt_spec h
  simp only [depStep, Option.mem_def, Option.bind_eq_some_iff] at hn
  obtain ⟨a, ha, hv⟩ := hn
  exact ⟨w.take n.unpair.1, w.drop n.unpair.1, a, (List.take_append_drop _ _).symm,
    Nat.Partrec.Code.evaln_sound ha, Nat.Partrec.Code.evaln_sound hv⟩

theorem dep_mem_depM {c d : Code}
    (hc : ∀ w z : List Bool, (run c w).Dom → (run c (w ++ z)).Dom → z = [])
    {p q : List Bool} {a v : ℕ} (ha : a ∈ run c p) (hv : v ∈ d.eval (encode (a, q))) :
    v ∈ depM c d (p ++ q) := by
  obtain ⟨t1, h1⟩ := Nat.Partrec.Code.evaln_complete.1 ha
  obtain ⟨t2, h2⟩ := Nat.Partrec.Code.evaln_complete.1 hv
  have h1' := Nat.Partrec.Code.evaln_mono (le_max_left t1 t2) h1
  have h2' := Nat.Partrec.Code.evaln_mono (le_max_right t1 t2) h2
  have hdom : (depM c d (p ++ q)).Dom := by
    refine Nat.rfindOpt_dom.2 ⟨Nat.pair p.length (max t1 t2), v, ?_⟩
    simp only [depStep, Nat.unpair_pair, List.take_left', List.drop_left', Option.mem_def,
      Option.bind_eq_some_iff]
    exact ⟨a, h1', h2'⟩
  obtain ⟨p', q', a', hw, ha', hv'⟩ := mem_depM (Part.get_mem hdom)
  have hpp : p = p' :=
    prefix_unique hc (List.prefix_append p q) (hw ▸ List.prefix_append p' q')
      (Part.dom_iff_mem.2 ⟨a, ha⟩) (Part.dom_iff_mem.2 ⟨a', ha'⟩)
  subst hpp
  obtain rfl : q = q' := List.append_cancel_left hw
  obtain rfl := Part.mem_unique ha ha'
  obtain rfl := Part.mem_unique hv hv'
  exact Part.get_mem hdom

theorem depM_prefixFree {c d : Code}
    (hc : ∀ w z : List Bool, (run c w).Dom → (run c (w ++ z)).Dom → z = [])
    (hd : ∀ (a : ℕ) (w z : List Bool), (d.eval (encode (a, w))).Dom →
      (d.eval (encode (a, w ++ z))).Dom → z = [])
    {w z : List Bool} (h : (depM c d w).Dom) (h' : (depM c d (w ++ z)).Dom) : z = [] := by
  obtain ⟨p, q, a, rfl, ha, hv⟩ := mem_depM (Part.get_mem h)
  obtain ⟨p', q', a', hw, ha', hv'⟩ := mem_depM (Part.get_mem h')
  have hpp : p = p' :=
    prefix_unique hc (l := p ++ q ++ z) (by rw [List.append_assoc]; exact List.prefix_append _ _)
      (hw ▸ List.prefix_append p' q') (Part.dom_iff_mem.2 ⟨a, ha⟩) (Part.dom_iff_mem.2 ⟨a', ha'⟩)
  subst hpp
  rw [List.append_assoc] at hw
  obtain rfl : q ++ z = q' := List.append_cancel_left hw
  obtain rfl := Part.mem_unique ha ha'
  exact hd a q z (Part.dom_iff_mem.2 ⟨_, hv⟩) (Part.dom_iff_mem.2 ⟨_, hv'⟩)

/-- **Composition of a prefix machine with a conditional one.** There is a prefix machine
that reads a program for `a` and then a conditional program given `a`. -/
theorem exists_dep_machine {φ : List Bool →. ℕ} (hφ : IsPrefixMachine φ)
    {ψ : ℕ → List Bool →. ℕ} (hψ : IsCondPrefixMachine ψ) :
    ∃ M : List Bool →. ℕ, IsPrefixMachine M ∧
      ∀ (p q : List Bool) (a v : ℕ), a ∈ φ p → v ∈ ψ a q → v ∈ M (p ++ q) := by
  obtain ⟨c, rfl⟩ := exists_run_eq hφ.1
  obtain ⟨d, hd⟩ := exists_code₂ hψ.1
  refine ⟨depM c d, ⟨depM_partrec c d, fun _ _ => depM_prefixFree hφ.2 fun a w z h h' => ?_⟩,
    fun p q a v ha hv => dep_mem_depM hφ.2 ha (by rw [hd]; exact hv)⟩
  rw [hd] at h h'
  exact hψ.2 a w z h h'

/-- The complexity bound that the dependent-pair machine gives: a program for `a` followed
by a conditional program for `v` given `a` describes `v`. -/
theorem K_U_le_add_of_cond {ψ : ℕ → List Bool →. ℕ} (hψ : IsCondPrefixMachine ψ) :
    ∃ c : ℕ, ∀ a v, Kolmogorov.K U v ≤ Kolmogorov.K U a + Kolmogorov.K (ψ a) v + c := by
  obtain ⟨M, hM, hdep⟩ := exists_dep_machine U_isPrefixMachine hψ
  obtain ⟨k, hk⟩ := K_U_le hM
  refine ⟨k, fun a v => (hk _).trans (add_le_add ?_ le_rfl)⟩
  rcases eq_or_ne (Kolmogorov.K U a) ⊤ with ha | ha
  · simp [ha]
  rcases eq_or_ne (Kolmogorov.K (ψ a) v) ⊤ with hv | hv
  · simp [hv]
  obtain ⟨p, hp, hpc⟩ := (sys U).exists_cost_eq_K ha
  obtain ⟨q, hq, hqc⟩ := (sys (ψ a)).exists_cost_eq_K hv
  have h := Kolmogorov.K_le_length (hdep p q a v hp hq)
  have e : Kolmogorov.K U a + Kolmogorov.K (ψ a) v = ((p ++ q).length : ℕ∞) := by
    rw [List.length_append, Nat.cast_add]
    exact (congrArg₂ (· + ·) hpc hqc).symm
  rw [e]
  exact h

/-! ### The chain rule -/

/-- **The chain rule**, easy half: `K(⟨x, y⟩) ≤ K(x) + K(y | x) + c`. -/
theorem K_pair_le_add_condK :
    ∃ c : ℕ, ∀ x y, Kolmogorov.K U (Nat.pair x y) ≤ Kolmogorov.K U x + condK x y + c := by
  have hψ : IsCondPrefixMachine fun a w => (condU a w).map (Nat.pair a) :=
    ⟨Partrec.map condU_partrec (Primrec₂.natPair.comp (fst.comp fst) snd).to_comp.to₂,
      fun a w z h h' => condU_prefixFree a h h'⟩
  obtain ⟨c, hc⟩ := K_U_le_add_of_cond hψ
  refine ⟨c, fun x y => (hc x (Nat.pair x y)).trans (add_le_add (add_le_add le_rfl ?_) le_rfl)⟩
  refine (sys (condU x)).le_K_iff.2 fun q hq => ?_
  have hq' : Nat.pair x y ∈ (condU x q).map (Nat.pair x) := Part.mem_map _ hq
  exact Kolmogorov.K_le_length hq'

/-- `K(y) ≤ K(x) + K(y | x) + c`: knowing `x` and how to get `y` from it is knowing `y`. -/
theorem K_le_add_condK :
    ∃ c : ℕ, ∀ x y, Kolmogorov.K U y ≤ Kolmogorov.K U x + condK x y + c :=
  K_U_le_add_of_cond condU_isCondPrefixMachine

/-- **Conditioning does not hurt**: `K(y | x) ≤ K(y) + c`. -/
theorem condK_le_K : ∃ c : ℕ, ∀ x y, condK x y ≤ Kolmogorov.K U y + c :=
  condK_le (ψ := fun _ => U)
    ⟨(U_partrec.comp Computable.snd).to₂, fun _ _ _ => U_prefixFree⟩

/-- **A computable function of the condition is free**: `K(f x | x) ≤ c`. -/
theorem condK_map_le {f : ℕ → ℕ} (hf : Computable f) : ∃ c : ℕ, ∀ x, condK x (f x) ≤ c := by
  have hψ : IsCondPrefixMachine fun (a : ℕ) (w : List Bool) =>
      ((if w = [] then some (f a) else none : Option ℕ) : Part ℕ) := by
    have hcomp : Computable fun x : ℕ × List Bool =>
        (if x.2 = [] then some (f x.1) else none : Option ℕ) :=
      (Computable.cond (Primrec.eq.decide.comp snd (const [])).to_comp
        (Computable.option_some.comp (hf.comp Computable.fst)) (Computable.const none)).of_eq
          fun x => by by_cases h : x.2 = [] <;> simp [h]
    refine ⟨(Computable.ofOption hcomp).to₂, fun a w z h h' => ?_⟩
    by_contra hz
    have hne : w ++ z ≠ [] := fun e => hz (List.append_eq_nil_iff.1 e).2
    simp [hne] at h'
  obtain ⟨k, hk⟩ := condK_le hψ
  refine ⟨k, fun x => (hk x (f x)).trans ?_⟩
  have h0 : Kolmogorov.K (fun w : List Bool =>
      ((if w = [] then some (f x) else none : Option ℕ) : Part ℕ)) (f x) ≤ (([] : List Bool).length : ℕ∞) :=
    Kolmogorov.K_le_length (by simp)
  simpa using add_le_add h0 (le_refl (k : ℕ∞))

/-! ### The two-part code -/

/-- Given the macrostate `a`, an element of a set of at most `2 ^ ℓ a` elements enumerated
by `e a` costs `ℓ a` bits: `K(e a i | a) ≤ ℓ a + c`. -/
theorem condK_le_length {e : ℕ → ℕ → ℕ} {ℓ : ℕ → ℕ} (he : Computable₂ e) (hℓ : Computable ℓ) :
    ∃ c : ℕ, ∀ a i, i < 2 ^ ℓ a → condK a (e a i) ≤ ((ℓ a + c : ℕ) : ℕ∞) := by
  have hψ : IsCondPrefixMachine fun (a : ℕ) (w : List Bool) =>
      ((if w.length = ℓ a then some (e a (KraftChaitin.val w)) else none : Option ℕ) :
        Part ℕ) := by
    have hcomp : Computable fun x : ℕ × List Bool =>
        (if x.2.length = ℓ x.1 then some (e x.1 (KraftChaitin.val x.2)) else none : Option ℕ) :=
      (Computable.cond
        (Primrec.eq.decide.to_comp.comp (Computable.list_length.comp Computable.snd)
          (hℓ.comp Computable.fst))
        (Computable.option_some.comp
          (he.comp Computable.fst (KraftChaitin.val_primrec.to_comp.comp Computable.snd)))
        (Computable.const none)).of_eq
          fun x => by by_cases h : x.2.length = ℓ x.1 <;> simp [h]
    refine ⟨(Computable.ofOption hcomp).to₂, fun a w z h h' => ?_⟩
    have hw : w.length = ℓ a := by
      by_contra hne
      simp [hne] at h
    have hwz : w.length + z.length = ℓ a := by
      by_contra hne
      simp [hne] at h'
    exact List.length_eq_zero_iff.1 (by omega)
  obtain ⟨k, hk⟩ := condK_le hψ
  refine ⟨k, fun a i hi => (hk a (e a i)).trans ?_⟩
  obtain ⟨w, hw, hval⟩ := KraftChaitin.exists_val (ℓ a) i hi
  have h0 : Kolmogorov.K (fun w : List Bool =>
      ((if w.length = ℓ a then some (e a (KraftChaitin.val w)) else none : Option ℕ) :
        Part ℕ)) (e a i) ≤ (w.length : ℕ∞) :=
    Kolmogorov.K_le_length (by simp [hw, hval])
  rw [hw] at h0
  exact (add_le_add h0 le_rfl).trans (le_of_eq (by push_cast; rfl))

/-- **The two-part code for the universal machine**: `K(y) ≤ K(a) + ℓ a + c` for every `y`
in the set of at most `2 ^ ℓ a` elements that `e a` enumerates. With `a` a macrostate and
`2 ^ ℓ a` its multiplicity this is "micro ≤ macro + log W". -/
theorem K_twoPart_le {e : ℕ → ℕ → ℕ} {ℓ : ℕ → ℕ} (he : Computable₂ e) (hℓ : Computable ℓ) :
    ∃ c : ℕ, ∀ a i, i < 2 ^ ℓ a →
      Kolmogorov.K U (e a i) ≤ Kolmogorov.K U a + ((ℓ a + c : ℕ) : ℕ∞) := by
  obtain ⟨c1, h1⟩ := K_le_add_condK
  obtain ⟨c2, h2⟩ := condK_le_length he hℓ
  refine ⟨c2 + c1, fun a i hi => (h1 a (e a i)).trans ?_⟩
  calc Kolmogorov.K U a + condK a (e a i) + c1
      ≤ Kolmogorov.K U a + ((ℓ a + c2 : ℕ) : ℕ∞) + c1 := by
        gcongr
        exact h2 a i hi
    _ = Kolmogorov.K U a + ((ℓ a + (c2 + c1) : ℕ) : ℕ∞) := by push_cast; ring

/-- **The two-part code is tight given the macrostate.** If `e a` enumerates `2 ^ ℓ a`
distinct elements, one of them has `K(y | a) ≥ ℓ a`: no conditional code beats `log W` on
the whole set. With `condK_le_length`, `ℓ a ≤ K(y | a) ≤ ℓ a + c` for that element. This is
plain counting and holds for every description method. -/
theorem exists_condK_ge (e : ℕ → ℕ → ℕ) (ℓ : ℕ → ℕ) (a : ℕ)
    (hinj : Set.InjOn (e a) (Finset.range (2 ^ ℓ a) : Set ℕ)) :
    ∃ i < 2 ^ ℓ a, (ℓ a : ℕ∞) ≤ condK a (e a i) := by
  classical
  obtain ⟨y, hy, h⟩ := (Kolmogorov.sys_isBinary (condU a)).exists_incompressible
    (Kolmogorov.sys_functional (condU a)) (ℓ a) ((Finset.range (2 ^ ℓ a)).image (e a))
    (by rw [Finset.card_image_of_injOn hinj]; simp)
  obtain ⟨i, hi, rfl⟩ := Finset.mem_image.1 hy
  exact ⟨i, Finset.mem_range.1 hi, h⟩

/-- **Compressible elements are rare, whatever the condition**: fewer than `2 ^ m` numbers
have `K(y | a) < m`. -/
theorem card_condK_lt (a m : ℕ) (A : Finset ℕ) [DecidablePred fun y => condK a y < m] :
    (A.filter fun y => condK a y < m).card < 2 ^ m := by
  classical
  have h := (Kolmogorov.sys_isBinary (condU a)).card_compressible_lt
    (Kolmogorov.sys_functional (condU a)) m A
  convert h using 3
  exact Iff.rfl

/-! ### The logarithmic growth law -/

theorem iterate_computable {f : ℕ → ℕ} (hf : Computable f) :
    Computable fun n : ℕ => f^[n.unpair.1] n.unpair.2 := by
  have h := Computable.nat_rec (f := fun n : ℕ => n.unpair.1) (g := fun n : ℕ => n.unpair.2)
    (h := fun (_ : ℕ) (p : ℕ × ℕ) => f p.2)
    (Computable.fst.comp Computable.unpair) (Computable.snd.comp Computable.unpair)
    (hf.comp (Computable.snd.comp Computable.snd)).to₂
  refine h.of_eq fun n => ?_
  induction n.unpair.1 with
  | zero => rfl
  | succ t ih => rw [Function.iterate_succ_apply', ← ih]

/-- **Iteration costs the step count**: `K(fᵗ x) ≤ K(x) + K(t) + c` for computable `f`. -/
theorem K_iterate_le {f : ℕ → ℕ} (hf : Computable f) :
    ∃ c : ℕ, ∀ x t, Kolmogorov.K U (f^[t] x) ≤ Kolmogorov.K U x + Kolmogorov.K U t + c := by
  obtain ⟨c1, h1⟩ := K_map_le (iterate_computable hf)
  obtain ⟨c2, h2⟩ := K_pair_le
  refine ⟨c2 + c1, fun x t => ?_⟩
  have h := h1 (Nat.pair t x)
  simp only [Nat.unpair_pair] at h
  calc Kolmogorov.K U (f^[t] x) ≤ Kolmogorov.K U (Nat.pair t x) + c1 := h
    _ ≤ Kolmogorov.K U t + Kolmogorov.K U x + c2 + c1 := by
        gcongr
        exact h2 t x
    _ = Kolmogorov.K U x + Kolmogorov.K U t + ((c2 + c1 : ℕ) : ℕ∞) := by push_cast; ring

/-- **The logarithmic growth law for the universal machine**:
`K(fᵗ x) ≤ K(x) + 2 log₂ (t + 1) + c` for computable `f`. Running a computable dynamics
for `t` steps adds at most the information in the clock. -/
theorem K_iterate_le_log {f : ℕ → ℕ} (hf : Computable f) :
    ∃ c : ℕ, ∀ x t,
      Kolmogorov.K U (f^[t] x) ≤ Kolmogorov.K U x + ((2 * Nat.log 2 (t + 1) + c : ℕ) : ℕ∞) := by
  obtain ⟨c1, h1⟩ := K_iterate_le hf
  obtain ⟨c2, h2⟩ := Levin.K_U_le_log
  refine ⟨c2 + c1, fun x t => (h1 x t).trans ?_⟩
  calc Kolmogorov.K U x + Kolmogorov.K U t + c1
      ≤ Kolmogorov.K U x + ((2 * Nat.log 2 (t + 1) + c2 : ℕ) : ℕ∞) + c1 := by
        gcongr
        exact h2 t
    _ = Kolmogorov.K U x + ((2 * Nat.log 2 (t + 1) + (c2 + c1) : ℕ) : ℕ∞) := by
        push_cast; ring

end Conditional

end Complexity
