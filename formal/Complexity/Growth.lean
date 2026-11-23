import Complexity.Reuse

/-!
# The counting law for generative systems with reuse

Shannon's counting argument – "there are far more Boolean functions than small circuits,
so almost every function needs a large circuit" – uses nothing about Boolean functions.
It only uses that a circuit is built step by step, each step being one of finitely many
choices. This file states and proves the argument for *every* finitely generated
generative system with reuse: circuits, straight-line programs, grammars, assembly
pathways, addition chains.

Let the signature have `m` operation symbols, each of arity at most `r`, and let every
construction step cost one. Then:

* `card_reach_le`       – at most `(m · n^r)^k` pools can be reached from the empty pool in
                          `k ≤ n` steps (the growth function of construction histories);
* `card_le_of_dagK_le`  – **counting law**: at most `n · (m · n^r)^n` objects have DAG
                          complexity at most `n`;
* `exists_dagK_gt`      – **almost everything is complex**: any population larger than
                          that bound contains an object of DAG complexity greater than `n`.

The bound depends only on `m`, `r` and `n` – not on the objects, not on what the
operations do. In a space of `N` objects, complexity `n` is reachable for at most
`2^{O(n log n)}` of them, so all but a vanishing fraction have complexity
`Ω(log N / log log N)`: with `N = 2^(2^k)` Boolean functions this is Shannon's
`2^k / k` lower bound; for addition chains it is weaker than the logarithmic law and says nothing
new. It needs single-valued operations and a finite signature, so it does not apply as
stated to molecular assembly, where a join of two fragments is multi-valued. The proof
counts pools directly; it does not go through `card_le_of_K_lt`.
-/

namespace Complexity

namespace Sig

open Quiver

universe u v w

variable {S : Sig.{u, v}} {X : Type w} {alg : S.Alg X}

section Reach

open scoped Classical

variable [Fintype S.Op] [∀ a, Fintype (S.Ar a)]

/-- The finite pools that can be reached from the empty pool in exactly `k` construction
steps: at each step choose a pool reached so far, an operation, and arguments from that
pool, and add the result. -/
noncomputable def reach (alg : S.Alg X) : ℕ → Finset (Finset X)
  | 0 => {∅}
  | k + 1 => (reach alg k).biUnion fun Q =>
      Finset.univ.biUnion fun a : S.Op =>
        (Fintype.piFinset fun _ : S.Ar a => Q).image fun xs => insert (alg a xs) Q

@[simp] theorem reach_zero : reach alg 0 = {∅} := rfl

theorem mem_reach_succ {k : ℕ} {Q : Finset X} :
    Q ∈ reach alg (k + 1) ↔ ∃ Q₀ ∈ reach alg k, ∃ (a : S.Op) (xs : S.Ar a → X),
      (∀ b, xs b ∈ Q₀) ∧ Q = insert (alg a xs) Q₀ := by
  simp only [reach, Finset.mem_biUnion, Finset.mem_univ, true_and, Finset.mem_image,
    Fintype.mem_piFinset]
  constructor
  · rintro ⟨Q₀, h₀, a, xs, hxs, rfl⟩
    exact ⟨Q₀, h₀, a, xs, hxs, rfl⟩
  · rintro ⟨Q₀, h₀, a, xs, hxs, rfl⟩
    exact ⟨Q₀, h₀, a, xs, hxs, rfl⟩

/-- A pool reached in `k` steps holds at most `k` objects. -/
theorem card_le_of_mem_reach : ∀ {k : ℕ} {Q : Finset X}, Q ∈ reach alg k → Q.card ≤ k
  | 0, Q, h => by
      have hQ : Q = ∅ := by simpa using h
      simp [hQ]
  | k + 1, Q, h => by
      obtain ⟨Q₀, h₀, a, xs, -, rfl⟩ := mem_reach_succ.1 h
      exact (Finset.card_insert_le _ _).trans (Nat.succ_le_succ (card_le_of_mem_reach h₀))

/-- **Padding.** After the first step a construction can always idle by repeating its last
step, so a pool reached in `k + 1` steps is also reached in `k + 2`. -/
theorem reach_succ_subset (k : ℕ) : reach alg (k + 1) ⊆ reach alg (k + 2) := by
  intro Q hQ
  obtain ⟨Q₀, h₀, a, xs, hxs, rfl⟩ := mem_reach_succ.1 hQ
  refine mem_reach_succ.2 ⟨insert (alg a xs) Q₀, hQ, a, xs,
    fun b => Finset.mem_insert_of_mem (hxs b), ?_⟩
  exact (Finset.insert_eq_of_mem (Finset.mem_insert_self _ _)).symm

theorem reach_mono {k n : ℕ} (hk : 1 ≤ k) (hkn : k ≤ n) : reach alg k ⊆ reach alg n := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hkn
  induction d with
  | zero => exact subset_rfl
  | succ d ih =>
    obtain ⟨j, hj⟩ : ∃ j, k + d = j + 1 := ⟨k + d - 1, by omega⟩
    have h1 : reach alg (k + d) ⊆ reach alg (k + (d + 1)) := by
      rw [← add_assoc, hj]
      exact reach_succ_subset j
    exact (ih (Nat.le_add_right _ _)).trans h1

/-- One more step multiplies the number of reachable pools by at most
`m · (max 1 k)^r`: choose an operation, then at most `r` arguments from a pool of at most
`k` objects. -/
theorem card_reach_succ_le (r : ℕ) (har : ∀ a, Fintype.card (S.Ar a) ≤ r) (k : ℕ) :
    (reach alg (k + 1)).card ≤
      (reach alg k).card * (Fintype.card S.Op * (max 1 k) ^ r) := by
  show ((reach alg k).biUnion fun Q =>
      Finset.univ.biUnion fun a : S.Op =>
        (Fintype.piFinset fun _ : S.Ar a => Q).image fun xs => insert (alg a xs) Q).card ≤ _
  refine Finset.card_biUnion_le_card_mul _ _ _ fun Q hQ => ?_
  have hQk : Q.card ≤ max 1 k := (card_le_of_mem_reach hQ).trans (le_max_right _ _)
  calc (Finset.univ.biUnion fun a : S.Op =>
          (Fintype.piFinset fun _ : S.Ar a => Q).image fun xs => insert (alg a xs) Q).card
      ≤ ∑ a : S.Op,
          ((Fintype.piFinset fun _ : S.Ar a => Q).image fun xs => insert (alg a xs) Q).card :=
        Finset.card_biUnion_le
    _ ≤ ∑ _a : S.Op, (max 1 k) ^ r := Finset.sum_le_sum fun a _ => by
        refine Finset.card_image_le.trans ?_
        rw [Fintype.card_piFinset, Finset.prod_const, Finset.card_univ]
        exact (Nat.pow_le_pow_left hQk _).trans
          (Nat.pow_le_pow_right (lt_of_lt_of_le Nat.zero_lt_one (le_max_left 1 k)) (har a))
    _ = Fintype.card S.Op * (max 1 k) ^ r := by
        rw [Finset.sum_const, Finset.card_univ, smul_eq_mul]

/-- **Growth of construction histories.** At most `(m · n^r)^k` pools are reachable in
`k ≤ n` steps. -/
theorem card_reach_le (r : ℕ) (har : ∀ a, Fintype.card (S.Ar a) ≤ r) (n : ℕ) :
    ∀ k, k ≤ n → (reach alg k).card ≤ (Fintype.card S.Op * n ^ r) ^ k
  | 0, _ => by simp
  | k + 1, hk => by
      have ih := card_reach_le r har n k (Nat.le_of_succ_le hk)
      have hmax : max 1 k ≤ n := max_le (by omega) (by omega)
      calc (reach alg (k + 1)).card
          ≤ (reach alg k).card * (Fintype.card S.Op * (max 1 k) ^ r) :=
            card_reach_succ_le r har k
        _ ≤ (Fintype.card S.Op * n ^ r) ^ k * (Fintype.card S.Op * n ^ r) :=
            Nat.mul_le_mul ih (Nat.mul_le_mul_left _ (Nat.pow_le_pow_left hmax r))
        _ = (Fintype.card S.Op * n ^ r) ^ (k + 1) := (pow_succ _ _).symm

/-- Every construction history from the empty pool ends in one of the pools enumerated by
`reach`, at the index given by its length. -/
theorem exists_mem_reach :
    ∀ {Q : Pool alg} (p : Path (⟨∅⟩ : Pool alg) Q), ∃ Q' ∈ reach alg p.length, Q.set = ↑Q'
  | _, .nil => ⟨∅, by simp, by simp⟩
  | _, .cons p e => by
      obtain ⟨Q₀, h₀, hQ₀⟩ := exists_mem_reach p
      refine ⟨insert (alg (PoolStep.op e) (PoolStep.args e)) Q₀, ?_, ?_⟩
      · rw [Path.length_cons]
        refine mem_reach_succ.2 ⟨Q₀, h₀, PoolStep.op e, PoolStep.args e, fun b => ?_, rfl⟩
        have hb := PoolStep.mem e b
        rw [hQ₀] at hb
        exact_mod_cast hb
      · rw [PoolStep.eq e, hQ₀, Finset.coe_insert]

end Reach

/-- **Counting law for DAG complexity.** In a generative system with `m` operation
symbols of arity at most `r` and unit step costs, at most `n · (m · n^r)^n` objects have
DAG complexity at most `n`. This is Shannon's circuit-counting argument, for every
domain at once. -/
theorem card_le_of_dagK_le [Fintype S.Op] [∀ a, Fintype (S.Ar a)] (r : ℕ)
    (har : ∀ a, Fintype.card (S.Ar a) ≤ r) (n : ℕ) (A : Finset X)
    (hA : ∀ x ∈ A, dagK alg (fun _ => 1) x ≤ n) :
    A.card ≤ n * (Fintype.card S.Op * n ^ r) ^ n := by
  classical
  have hsub : A ⊆ (reach alg n).biUnion id := by
    intro x hx
    have hx' : poolK alg (fun _ => 1) {x} ≤ n := hA x hx
    obtain ⟨Q, hxQ, p, hp⟩ := poolK_le_coe_iff.1 hx'
    rw [pathCost_poolWeight_one] at hp
    have hlen : p.length ≤ n := by exact_mod_cast hp
    obtain ⟨Q', hQ', hQeq⟩ := exists_mem_reach p
    have hxQ' : x ∈ Q' := by
      have h1 : x ∈ (⟨Q⟩ : Pool alg).set := hxQ rfl
      rw [hQeq] at h1
      exact_mod_cast h1
    have hpos : 1 ≤ p.length := by
      by_contra hlt
      have h0 : p.length = 0 := by omega
      rw [h0, reach_zero, Finset.mem_singleton] at hQ'
      rw [hQ'] at hxQ'
      exact absurd hxQ' (Finset.notMem_empty x)
    exact Finset.mem_biUnion.2 ⟨Q', reach_mono hpos hlen hQ', hxQ'⟩
  calc A.card ≤ ((reach alg n).biUnion id).card := Finset.card_le_card hsub
    _ ≤ (reach alg n).card * n :=
        Finset.card_biUnion_le_card_mul _ _ _ fun Q hQ => card_le_of_mem_reach hQ
    _ ≤ (Fintype.card S.Op * n ^ r) ^ n * n :=
        Nat.mul_le_mul_right _ (card_reach_le r har n n le_rfl)
    _ = n * (Fintype.card S.Op * n ^ r) ^ n := Nat.mul_comm _ _

/-- **Almost everything is complex.** A population larger than the counting bound contains
an object of DAG complexity greater than `n`. -/
theorem exists_dagK_gt [Fintype S.Op] [∀ a, Fintype (S.Ar a)] (r : ℕ)
    (har : ∀ a, Fintype.card (S.Ar a) ≤ r) (n : ℕ) (A : Finset X)
    (hA : n * (Fintype.card S.Op * n ^ r) ^ n < A.card) :
    ∃ x ∈ A, (n : ℕ∞) < dagK alg (fun _ => 1) x := by
  by_contra h
  simp only [not_exists, not_and, not_lt] at h
  exact absurd (card_le_of_dagK_le r har n A h) (not_le.2 hA)

/-- The complex members of a population are the overwhelming majority: at most
`n · (m · n^r)^n` members of any finite population have DAG complexity at most `n`. -/
theorem card_filter_dagK_le [Fintype S.Op] [∀ a, Fintype (S.Ar a)] (r : ℕ)
    (har : ∀ a, Fintype.card (S.Ar a) ≤ r) (n : ℕ) (A : Finset X)
    [DecidablePred fun x => dagK alg (fun _ => 1) x ≤ n] :
    (A.filter fun x => dagK alg (fun _ => 1) x ≤ n).card ≤
      n * (Fintype.card S.Op * n ^ r) ^ n :=
  card_le_of_dagK_le r har n _ fun _ hx => (Finset.mem_filter.1 hx).2

end Sig

end Complexity
