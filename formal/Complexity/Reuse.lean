import Complexity.Generative
import Complexity.Metric

/-!
# Reuse: complexity when parts can be shared

Tree complexity charges for every occurrence of a part. If a part, once built, can be used
again for free – if information can be copied – the right notion is **DAG complexity**:
circuit size rather than formula size, straight-line program length, grammar size,
addition-chain length, assembly index.

DAG complexity is *path* complexity in a lifted space. A **pool** is the set of objects
built so far; a move adds one object obtained by applying an operation to members of the
pool; the DAG complexity of `x` is the least cost of a pool containing `x`, starting from
the empty pool. So reuse is not a new kind of complexity – it is the generative distance
of `Metric.lean` on pools, and the description-system complexity of `Basic.lean` with
construction histories as descriptions.

Main results:

* `poolK_union_le`     – joint complexity is subadditive; the defect is shared structure
                         (mutual information, integration, "organization");
* `dagK_alg_range_le`  – a composite costs one step more than its *distinct* parts;
* `dagK_alg_const_le`  – **copying is free**: `K(x·x) ≤ K(x) + 1`;
* `dagK_isPotential`   – DAG complexity is a potential for the size rule, hence by duality
* `dagK_le_treeK`      – **reuse never hurts**: DAG complexity ≤ tree complexity;
* `mul_le_pow_of_dagK_le` – **logarithmic law**: any extensive (subadditive) measure `μ`
                         satisfies `μ x ≤ r ^ (K x - 1)`; size can at most multiply by the
                         arity at each step, so complexity is at least `log_r` of size.
-/

namespace Complexity

namespace Sig

open Quiver

universe u v w

variable {S : Sig.{u, v}} {X : Type w}

/-- A **pool**: the set of objects built so far. -/
structure Pool (alg : S.Alg X) where
  /-- The objects in the pool. -/
  set : Set X

/-- One **construction step**: apply an operation to members of the pool and add the
result. -/
structure PoolStep (alg : S.Alg X) (P Q : Pool alg) where
  /-- The operation applied. -/
  op : S.Op
  /-- Its arguments … -/
  args : S.Ar op → X
  /-- … which must already be in the pool. -/
  mem : ∀ b, args b ∈ P.set
  /-- The new pool is the old one plus the result. -/
  eq : Q.set = insert (alg op args) P.set

instance (alg : S.Alg X) : Quiver (Pool alg) := ⟨PoolStep alg⟩

/-- A construction step costs the weight of the operation it applies. -/
def poolWeight (alg : S.Alg X) (wt : S.Op → ℕ∞) : Weight (Pool alg) ℕ∞ :=
  fun _ _ e => wt (PoolStep.op e)

variable {alg : S.Alg X} {wt : S.Op → ℕ∞}

/-- Pools only grow. -/
theorem Pool.subset_of_path {P : Pool alg} :
    ∀ {Q : Pool alg} (_ : Path P Q), P.set ⊆ Q.set
  | _, .nil => subset_rfl
  | _, .cons p e => (Pool.subset_of_path p).trans (by
      rw [PoolStep.eq e]
      exact Set.subset_insert _ _)

/-- **Frame rule.** A construction can be replayed on top of any larger starting pool, at
the same cost. -/
theorem Pool.exists_lift {P : Pool alg} :
    ∀ {Q : Pool alg} (p : Path P Q) (P' : Pool alg), P.set ⊆ P'.set →
      ∃ (Q' : Pool alg) (q : Path P' Q'), Q'.set = Q.set ∪ P'.set ∧
        pathCost (poolWeight alg wt) q = pathCost (poolWeight alg wt) p
  | _, .nil, P', h => ⟨P', .nil, (Set.union_eq_self_of_subset_left h).symm, rfl⟩
  | _, .cons p e, P', h => by
      obtain ⟨Q₁, q, hQ, hc⟩ := Pool.exists_lift p P' h
      refine ⟨⟨insert (alg (PoolStep.op e) (PoolStep.args e)) Q₁.set⟩,
        q.cons ⟨PoolStep.op e, PoolStep.args e, fun b => ?_, rfl⟩, ?_, ?_⟩
      · rw [hQ]
        exact Or.inl (PoolStep.mem e b)
      · show insert _ Q₁.set = _ ∪ P'.set
        rw [hQ, PoolStep.eq e, Set.insert_union]
      · rw [pathCost_cons, pathCost_cons, hc]
        rfl

/-- `Builds alg wt P Q c`: starting from the pool `P`, the pool `Q` can be reached at cost
at most `c`. -/
def Builds (alg : S.Alg X) (wt : S.Op → ℕ∞) (P Q : Set X) (c : ℕ∞) : Prop :=
  ∃ p : Path (⟨P⟩ : Pool alg) ⟨Q⟩, pathCost (poolWeight alg wt) p ≤ c

theorem Builds.refl (P : Set X) : Builds alg wt P P 0 := ⟨.nil, le_rfl⟩

theorem Builds.mono {P Q : Set X} {c c' : ℕ∞} (h : Builds alg wt P Q c) (hc : c ≤ c') :
    Builds alg wt P Q c' :=
  let ⟨p, hp⟩ := h
  ⟨p, hp.trans hc⟩

theorem Builds.subset {P Q : Set X} {c : ℕ∞} (h : Builds alg wt P Q c) : P ⊆ Q :=
  let ⟨p, _⟩ := h
  Pool.subset_of_path p

theorem Builds.trans {P Q R : Set X} {c c' : ℕ∞} (h : Builds alg wt P Q c)
    (h' : Builds alg wt Q R c') : Builds alg wt P R (c + c') := by
  obtain ⟨p, hp⟩ := h
  obtain ⟨q, hq⟩ := h'
  exact ⟨p.comp q, by rw [pathCost_comp]; exact add_le_add hp hq⟩

/-- One more construction step. -/
theorem Builds.step {P Q : Set X} {c : ℕ∞} (h : Builds alg wt P Q c) (a : S.Op)
    (xs : S.Ar a → X) (hxs : ∀ b, xs b ∈ Q) :
    Builds alg wt P (insert (alg a xs) Q) (c + wt a) := by
  obtain ⟨p, hp⟩ := h
  refine ⟨p.cons ⟨a, xs, hxs, rfl⟩, ?_⟩
  rw [pathCost_cons]
  exact add_le_add hp le_rfl

theorem Builds.frame {P Q P' : Set X} {c : ℕ∞} (h : Builds alg wt P Q c) (hP : P ⊆ P') :
    Builds alg wt P' (Q ∪ P') c := by
  obtain ⟨p, hp⟩ := h
  obtain ⟨⟨Q's⟩, q, hQ, hc⟩ := Pool.exists_lift (wt := wt) p ⟨P'⟩ hP
  have hQ' : Q's = Q ∪ P' := hQ
  subst hQ'
  exact ⟨q, hc.le.trans hp⟩

/-- Two constructions from scratch can be run one after the other. -/
theorem Builds.union {Q₁ Q₂ : Set X} {c₁ c₂ : ℕ∞} (h₁ : Builds alg wt ∅ Q₁ c₁)
    (h₂ : Builds alg wt ∅ Q₂ c₂) : Builds alg wt ∅ (Q₂ ∪ Q₁) (c₁ + c₂) :=
  h₁.trans (h₂.frame (Set.empty_subset _))

variable (alg wt)

/-- Construction histories as a description system: a history describes every set of
objects contained in the pool it ends with. -/
def poolSystem : DescSystem (Σ Q : Pool alg, Path (⟨∅⟩ : Pool alg) Q) (Set X) ℕ∞ where
  cost d := pathCost (poolWeight alg wt) d.2
  realizes d T := T ⊆ d.1.set

/-- **Joint DAG complexity** of a set of targets: the least cost of a construction whose
final pool contains all of them. -/
noncomputable def poolK (T : Set X) : ℕ∞ := (poolSystem alg wt).K T

/-- **DAG complexity** of a single object: circuit size, straight-line program length,
assembly index. -/
noncomputable def dagK (x : X) : ℕ∞ := poolK alg wt {x}

variable {alg wt}

theorem poolK_le_of_builds {Q T : Set X} {c : ℕ∞} (h : Builds alg wt ∅ Q c) (hT : T ⊆ Q) :
    poolK alg wt T ≤ c := by
  obtain ⟨p, hp⟩ := h
  exact ((poolSystem alg wt).K_le_cost (d := ⟨⟨Q⟩, p⟩) hT).trans hp

theorem poolK_le_coe_iff {T : Set X} {n : ℕ} :
    poolK alg wt T ≤ n ↔ ∃ Q, T ⊆ Q ∧ Builds alg wt ∅ Q n := by
  constructor
  · intro h
    obtain ⟨⟨⟨Q⟩, p⟩, hT, hc⟩ := (poolSystem alg wt).K_le_coe_iff.1 h
    exact ⟨Q, hT, p, hc⟩
  · rintro ⟨Q, hT, h⟩
    exact poolK_le_of_builds h hT

/-- DAG complexity is path complexity on pools: the generative distance from the empty
pool to the nearest pool containing the targets. -/
theorem poolK_eq_iInf_dist (T : Set X) :
    poolK alg wt T = ⨅ (Q : Pool alg) (_ : T ⊆ Q.set), dist (poolWeight alg wt) ⟨∅⟩ Q := by
  apply le_antisymm
  · exact le_iInf₂ fun Q hQ => le_iInf fun p =>
      (poolSystem alg wt).K_le_cost (d := ⟨Q, p⟩) hQ
  · refine (poolSystem alg wt).le_K_iff.2 fun d hd => ?_
    exact iInf₂_le_of_le d.1 hd (iInf_le _ d.2)

theorem poolK_mono {T T' : Set X} (h : T ⊆ T') : poolK alg wt T ≤ poolK alg wt T' :=
  (poolSystem alg wt).le_K_iff.2 fun _ hd =>
    (poolSystem alg wt).K_le_cost (x := T) (h.trans hd)

@[simp] theorem poolK_empty : poolK alg wt (∅ : Set X) = 0 :=
  le_antisymm (poolK_le_of_builds (Builds.refl ∅) subset_rfl) (CostAlgebra.zero_le _)

/-! ### Subadditivity and shared structure -/

/-- **Subadditivity.** Building two sets of targets together costs at most the sum of
building them apart. The gap `K(T₁) + K(T₂) - K(T₁ ∪ T₂)` is the structure they share. -/
theorem poolK_union_le (T₁ T₂ : Set X) :
    poolK alg wt (T₁ ∪ T₂) ≤ poolK alg wt T₁ + poolK alg wt T₂ := by
  rcases eq_or_ne (poolK alg wt T₁) ⊤ with h1 | h1
  · simp [h1]
  rcases eq_or_ne (poolK alg wt T₂) ⊤ with h2 | h2
  · simp [h2]
  obtain ⟨n₁, hn₁⟩ := ENat.ne_top_iff_exists.1 h1
  obtain ⟨n₂, hn₂⟩ := ENat.ne_top_iff_exists.1 h2
  obtain ⟨Q₁, hT₁, hb₁⟩ := poolK_le_coe_iff.1 hn₁.ge
  obtain ⟨Q₂, hT₂, hb₂⟩ := poolK_le_coe_iff.1 hn₂.ge
  rw [← hn₁, ← hn₂]
  exact poolK_le_of_builds (hb₁.union hb₂)
    (Set.union_subset (hT₁.trans Set.subset_union_right) (hT₂.trans Set.subset_union_left))

/-- Subadditivity over a finite family of target sets. -/
theorem poolK_biUnion_le {ι : Type*} (s : Finset ι) (T : ι → Set X) :
    poolK alg wt (⋃ i ∈ s, T i) ≤ ∑ i ∈ s, poolK alg wt (T i) := by
  classical
  induction s using Finset.induction_on with
  | empty => simp
  | insert i s hi ih =>
    rw [Finset.set_biUnion_insert, Finset.sum_insert hi]
    exact (poolK_union_le _ _).trans (add_le_add le_rfl ih)

/-- **Integration is non-negative.** The parts of a system never cost less separately
than the system costs jointly. -/
theorem poolK_le_sum_dagK {ι : Type*} (s : Finset ι) (x : ι → X) :
    poolK alg wt (⋃ i ∈ s, {x i}) ≤ ∑ i ∈ s, dagK alg wt (x i) :=
  poolK_biUnion_le s fun i => {x i}

/-! ### One more step, and the price of copies -/

/-- Adding one object that is obtained by an operation from targets already present
costs one step. -/
theorem poolK_insert_alg_le (T : Set X) (a : S.Op) (xs : S.Ar a → X) (hxs : ∀ b, xs b ∈ T) :
    poolK alg wt (insert (alg a xs) T) ≤ poolK alg wt T + wt a := by
  rcases eq_or_ne (poolK alg wt T) ⊤ with h | h
  · simp [h]
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 h
  obtain ⟨Q, hT, hb⟩ := poolK_le_coe_iff.1 hn.ge
  rw [← hn]
  exact poolK_le_of_builds (hb.step a xs fun b => hT (hxs b)) (Set.insert_subset_insert hT)

/-- **A composite costs one step more than its distinct parts.** -/
theorem dagK_alg_range_le (a : S.Op) (xs : S.Ar a → X) :
    dagK alg wt (alg a xs) ≤ poolK alg wt (Set.range xs) + wt a :=
  (poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))).trans
    (poolK_insert_alg_le (Set.range xs) a xs fun b => Set.mem_range_self b)

/-- **Copying is free.** Applying an operation to copies of a single object costs one
step more than the object – not one step more than the copies. -/
theorem dagK_alg_const_le (a : S.Op) (x : X) :
    dagK alg wt (alg a fun _ => x) ≤ dagK alg wt x + wt a :=
  (poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))).trans
    (poolK_insert_alg_le {x} a (fun _ => x) fun _ => rfl)

/-- DAG complexity obeys the size rule's inequality … -/
theorem dagK_alg_le [∀ a, Fintype (S.Ar a)] (a : S.Op) (xs : S.Ar a → X) :
    dagK alg wt (alg a xs) ≤ wt a + ∑ b, dagK alg wt (xs b) := by
  rw [add_comm]
  refine (dagK_alg_range_le a xs).trans (add_le_add ?_ le_rfl)
  refine (poolK_mono ?_).trans (poolK_le_sum_dagK Finset.univ xs)
  rintro _ ⟨b, rfl⟩
  simp only [Set.mem_iUnion, Set.mem_singleton_iff, Finset.mem_univ, exists_prop, true_and]
  exact ⟨b, rfl⟩

/-- … so it is a potential for the size rule … -/
theorem dagK_isPotential [∀ a, Fintype (S.Ar a)] :
    IsPotential alg (sizeRule S wt) (dagK alg wt) := fun a xs => dagK_alg_le a xs

/-- … and therefore, by duality: **reuse never hurts.** DAG complexity is at most tree
complexity (circuit size ≤ formula size, assembly index ≤ assembly tree size). -/
theorem dagK_le_treeK [∀ a, Fintype (S.Ar a)] (x : X) :
    dagK alg wt x ≤ treeK alg (sizeRule S wt) x :=
  dagK_isPotential.le_treeK x

/-! ### The logarithmic law -/

theorem pathCost_poolWeight_one {P : Pool alg} :
    ∀ {Q : Pool alg} (p : Path P Q), pathCost (poolWeight alg fun _ => 1) p = p.length
  | _, .nil => by simp
  | _, .cons p e => by
      rw [pathCost_cons, pathCost_poolWeight_one p, Path.length_cons]
      simp [poolWeight]

/-- Along any construction from scratch, an extensive measure can at most multiply by the
arity bound at each step. -/
theorem Pool.mul_le_pow [∀ a, Fintype (S.Ar a)] (μ : X → ℕ) (r : ℕ) (hr : 1 ≤ r)
    (har : ∀ a, Fintype.card (S.Ar a) ≤ r)
    (hμ : ∀ (a : S.Op) (xs : S.Ar a → X), μ (alg a xs) ≤ max 1 (∑ b, μ (xs b))) :
    ∀ {Q : Pool alg} (p : Path (⟨∅⟩ : Pool alg) Q), ∀ x ∈ Q.set, μ x * r ≤ r ^ p.length
  | _, .nil => fun x hx => absurd hx (Set.notMem_empty x)
  | _, .cons (b := M) p e => by
      intro x hx
      have ih := Pool.mul_le_pow μ r hr har hμ p
      rw [PoolStep.eq e] at hx
      rw [Path.length_cons]
      rcases hx with rfl | hx
      · have h1 := hμ (PoolStep.op e) (PoolStep.args e)
        have h2 : (∑ b, μ (PoolStep.args e b)) * r ≤ r ^ (p.length + 1) := by
          rw [Finset.sum_mul]
          calc ∑ b, μ (PoolStep.args e b) * r
              ≤ ∑ _b : S.Ar (PoolStep.op e), r ^ p.length :=
                Finset.sum_le_sum fun b _ => ih _ (PoolStep.mem e b)
            _ = Fintype.card (S.Ar (PoolStep.op e)) * r ^ p.length := by
                rw [Finset.sum_const, Finset.card_univ, smul_eq_mul]
            _ ≤ r * r ^ p.length := Nat.mul_le_mul_right _ (har _)
            _ = r ^ (p.length + 1) := by rw [pow_succ, mul_comm]
        have h3 : 1 * r ≤ r ^ (p.length + 1) := by
          rw [one_mul]
          exact Nat.le_self_pow (Nat.succ_ne_zero _) r
        have h4 : max 1 (∑ b, μ (PoolStep.args e b)) * r ≤ r ^ (p.length + 1) := by
          rcases max_cases 1 (∑ b, μ (PoolStep.args e b)) with ⟨hm, _⟩ | ⟨hm, _⟩
          · rw [hm]; exact h3
          · rw [hm]; exact h2
        exact (Nat.mul_le_mul_right r h1).trans h4
      · exact (ih x hx).trans (Nat.pow_le_pow_right hr (Nat.le_succ _))

/-- **Logarithmic law.** Let `μ` be any extensive measure: at most `1` on what an
operation produces from nothing, and subadditive under every operation. If operations
take at most `r` arguments, then with unit step costs

  `μ x · r ≤ r ^ K(x)`,   i.e.   `K(x) ≥ 1 + log_r μ(x)`.

Addition chains (`l(n) ≥ log₂ n`), grammar/straight-line compression (`≥ log₂ |w|`),
assembly index (`≥ log₂` of the number of bonds) and fan-in-bounded circuits are all this
one inequality. -/
theorem mul_le_pow_of_dagK_le [∀ a, Fintype (S.Ar a)] (μ : X → ℕ) (r : ℕ) (hr : 1 ≤ r)
    (har : ∀ a, Fintype.card (S.Ar a) ≤ r)
    (hμ : ∀ (a : S.Op) (xs : S.Ar a → X), μ (alg a xs) ≤ max 1 (∑ b, μ (xs b)))
    {x : X} {n : ℕ} (h : dagK alg (fun _ => 1) x ≤ n) : μ x * r ≤ r ^ n := by
  obtain ⟨Q, hx, p, hp⟩ := poolK_le_coe_iff.1 h
  rw [pathCost_poolWeight_one] at hp
  have hlen : p.length ≤ n := by exact_mod_cast hp
  exact (Pool.mul_le_pow μ r hr har hμ p x (hx rfl)).trans (Nat.pow_le_pow_right hr hlen)

end Sig

end Complexity
