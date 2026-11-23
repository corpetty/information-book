import Complexity.Binary
import Complexity.Instances.Monoid
import Complexity.Instances.Circuit

/-!
# The reuse gap: how much can sharing parts buy?

Tree complexity charges for every occurrence of a part; DAG complexity charges once.
`Reuse.lean` shows `dagK ≤ treeK`. This file starts the classification of the gap.

* `binTreeK_add_one_le_two_pow` – **the ceiling**: in *every* algebra with one binary
                        operation, `treeK(x) + 1 ≤ 2 ^ dagK(x)`. Reuse never buys more than
                        an exponential. (Unfold the construction into a tree.)
* `binTreeK_add_one_eq` – **rigidity**: if the domain has an *additive size* `μ` (`μ = 1` on
                        generators, `μ (x ∘ y) = μ x + μ y`), then for every constructible
                        `x`, `treeK(x) = 2 μ(x) - 1` exactly. In extensive domains tree
                        complexity carries no information beyond size: every difference
                        in complexity between two objects of the same size is a
                        difference in reuse.
* `gain_window`       – hence in an extensive domain the gain `treeK / dagK` is pinned by
                        `dagK` alone: `2 μ(x) ≤ 2 ^ dagK(x)` and `dagK(x) < 2 μ(x)`.
* `Chain.treeK_eq`, `Str.treeK_eq` – numbers under addition and strings under
                        concatenation are extensive: tree complexity is `2n - 1` and
                        `2|w| - 1`.
* `Str.exists_low_gain` – the exponential gain is exceptional: some string of each length
                        `L` needs about `L / log L` steps even with reuse, so a typical
                        string gains only a logarithmic factor.

A second lower bound on DAG complexity, independent of size:

* `two_mul_card_support_le_binK` – **the support bound**: if `σ` assigns finite sets of
                        atoms with `|σ(gen)| ≤ 1` and `σ (x ∘ y) ⊆ σ x ∪ σ y`, then
                        `2 |σ x| - 1 ≤ dagK(x)`. Distinct atoms cannot be shared.
* `binK_eq_binTreeK_of_le` – **zero-gain criterion**: if some tree uses each atom once
                        (`treeK x ≤ 2 |σ x| - 1`), reuse buys nothing.
* `gain_le_multiplicity` – in an extensive domain, `(treeK + 1) · |σ x| ≤ μ x · (dagK + 1)`:
                        **the gain is at most the mean multiplicity of an atom**.
* `SetUnion.binK_add_one_eq` – in the free semilattice (finite sets under union) DAG and
                        tree complexity are both exactly `2|s| - 1`: idempotence removes
                        the gain entirely.
* `Str.strK_add_one_eq_of_nodup`, `Str.gain_le_multiplicity` – a string without repeated
                        letters gains nothing; in general the gain is at most
                        `|w| / #letters`.
* `Circuit.two_mul_card_essential_le` – for Boolean functions the support bound is the
                        trivial lower bound: `m` essential variables need `m` inputs and
                        `m - 1` gates.

All of these are elementary (a tree with `μ` leaves has `2μ - 1` nodes; a DAG of `n` nodes
unfolds to a tree of fewer than `2 ^ n`; `m` atoms need `m - 1` joins). Together they say:
reuse pays for *repetition* and for nothing else that these two measures can see. The gain
is at most `min (2 ^ dagK / dagK, μ / |σ|)`.

Upper bounds, and the limit of the two obstructions:

* `MonoidGen.slK_pow_le` – binary exponentiation: `x ^ m` costs `2 log₂ m` steps beyond `x`.
* `Monomial.slK_add_one_le` – so a monomial with `k` atoms and exponents `e i` costs at most
                        `∑ (2 log₂ (e i) + 2) - 1` steps: every monomial comes within a
                        logarithm of the multiplicity bound.
* `Monomial.exists_slK_gt` – but some monomial with exponents below `m` needs about
                        `k log m / log (k log m)` steps, more than the support bound `k`
                        and the growth bound `log m` together. The two obstructions are
                        **not** jointly tight.

What is *not* here: the exact order for monomials (Pippenger's theorem on vector addition
chains), and anything about Boolean functions beyond the trivial bound. There a function
can have small support and no additive size, both measures are silent, and the gap is the
formula-versus-circuit problem, which is open.
-/

namespace Complexity

namespace Binary

open Sig Quiver

universe u

variable {ι : Type u} {M : Type*} (gen : ι → M) (op : M → M → M)

/-- A generator is a one-node tree. -/
theorem binTreeK_gen_le (i : ι) : binTreeK gen op (gen i) ≤ 1 := by
  have h := treeK_isPotential (binAlg gen op) (sizeRule (binSig ι) fun _ => 1) (some i)
    (fun b : Fin 0 => b.elim0)
  have h' : binTreeK gen op (gen i) ≤
      1 + ∑ b : Fin 0, binTreeK gen op ((fun b : Fin 0 => (b.elim0 : M)) b) := h
  simpa using h'

/-- A composite tree costs one node more than its two subtrees. -/
theorem binTreeK_op_le (x y : M) :
    binTreeK gen op (op x y) ≤ 1 + (binTreeK gen op x + binTreeK gen op y) := by
  have h := treeK_isPotential (binAlg gen op) (sizeRule (binSig ι) fun _ => 1) none ![x, y]
  have h' : binTreeK gen op (op x y) ≤ 1 + ∑ b : Fin 2, binTreeK gen op (![x, y] b) := h
  rw [Fin.sum_univ_two] at h'
  simpa using h'

private theorem pool_treeK_add_one_le :
    ∀ {Q : Pool (binAlg gen op)} (p : Path (⟨∅⟩ : Pool (binAlg gen op)) Q), ∀ x ∈ Q.set,
      binTreeK gen op x + 1 ≤ 2 ^ p.length
  | _, .nil => fun x hx => absurd hx (Set.notMem_empty x)
  | _, .cons p e => by
      intro x hx
      have ih := pool_treeK_add_one_le p
      rw [Path.length_cons, pow_succ]
      have hone : (1 : ℕ∞) ≤ 2 ^ p.length := one_le_pow₀ (by norm_num)
      obtain ⟨o, args, hmem, heq⟩ := e
      rw [heq] at hx
      rcases hx with rfl | hx
      · rcases o with _ | i
        · have h := binTreeK_op_le gen op (args (0 : Fin 2)) (args (1 : Fin 2))
          have h0 := ih _ (hmem (0 : Fin 2))
          have h1 := ih _ (hmem (1 : Fin 2))
          show binTreeK gen op (op (args (0 : Fin 2)) (args (1 : Fin 2))) + 1 ≤ _
          calc binTreeK gen op (op (args (0 : Fin 2)) (args (1 : Fin 2))) + 1
              ≤ 1 + (binTreeK gen op (args (0 : Fin 2)) + binTreeK gen op (args (1 : Fin 2))) + 1 :=
                add_le_add h le_rfl
            _ = (binTreeK gen op (args (0 : Fin 2)) + 1) + (binTreeK gen op (args (1 : Fin 2)) + 1) := by
                ring
            _ ≤ 2 ^ p.length + 2 ^ p.length := add_le_add h0 h1
            _ = 2 ^ p.length * 2 := by ring
        · show binTreeK gen op (gen i) + 1 ≤ _
          calc binTreeK gen op (gen i) + 1 ≤ 1 + 1 := add_le_add (binTreeK_gen_le gen op i) le_rfl
            _ = 1 * 2 := by norm_num
            _ ≤ 2 ^ p.length * 2 := by gcongr
      · calc binTreeK gen op x + 1 ≤ 2 ^ p.length := ih x hx
          _ = 2 ^ p.length * 1 := (mul_one _).symm
          _ ≤ 2 ^ p.length * 2 := by gcongr; norm_num

/-- **The ceiling on reuse.** Anything built in `n` steps with sharing has an expression
tree of fewer than `2 ^ n` nodes: reuse buys at most an exponential, in every algebra. -/
theorem binTreeK_add_one_le_two_pow {x : M} {n : ℕ} (h : binK gen op x ≤ n) :
    binTreeK gen op x + 1 ≤ 2 ^ n := by
  obtain ⟨Q, hx, p, hp⟩ := poolK_le_coe_iff.1 h
  rw [pathCost_poolWeight_one] at hp
  have hlen : p.length ≤ n := by exact_mod_cast hp
  exact (pool_treeK_add_one_le gen op p x (hx rfl)).trans
    (pow_le_pow_right₀ (by norm_num) hlen)

/-- With an additive size, every expression tree for `x` has exactly `2 μ(x) - 1` nodes. -/
theorem cost_add_one_eq (μ : M → ℕ) (hgen : ∀ i, μ (gen i) = 1)
    (hop : ∀ x y, μ (op x y) = μ x + μ y) :
    ∀ t : (binSig ι).Term, cost (sizeRule (binSig ι) fun _ => 1) t + 1
      = 2 * (μ (eval (binAlg gen op) t) : ℕ∞)
  | ⟨some i, f⟩ => by
      rw [cost_mk, eval_mk]
      show (1 : ℕ∞) + ∑ b : Fin 0, cost (sizeRule (binSig ι) fun _ => 1) (f b) + 1
        = 2 * ((μ (gen i) : ℕ) : ℕ∞)
      rw [hgen]
      simp
      norm_num
  | ⟨none, f⟩ => by
      have h0 := cost_add_one_eq μ hgen hop (f (0 : Fin 2))
      have h1 := cost_add_one_eq μ hgen hop (f (1 : Fin 2))
      rw [cost_mk, eval_mk]
      show (1 : ℕ∞) + ∑ b : Fin 2, cost (sizeRule (binSig ι) fun _ => 1) (f b) + 1
        = 2 * ((μ (op (eval (binAlg gen op) (f (0 : Fin 2)))
            (eval (binAlg gen op) (f (1 : Fin 2)))) : ℕ) : ℕ∞)
      rw [Fin.sum_univ_two, hop]
      push_cast
      calc (1 : ℕ∞) + (cost (sizeRule (binSig ι) fun _ => 1) (f (0 : Fin 2))
            + cost (sizeRule (binSig ι) fun _ => 1) (f (1 : Fin 2))) + 1
          = (cost (sizeRule (binSig ι) fun _ => 1) (f (0 : Fin 2)) + 1)
            + (cost (sizeRule (binSig ι) fun _ => 1) (f (1 : Fin 2)) + 1) := by ring
        _ = 2 * (μ (eval (binAlg gen op) (f (0 : Fin 2))) : ℕ∞)
            + 2 * (μ (eval (binAlg gen op) (f (1 : Fin 2))) : ℕ∞) := by rw [h0, h1]
        _ = _ := by ring

/-- **Rigidity of tree complexity in extensive domains.** If `μ` is an additive size, then
every constructible `x` has `treeK(x) + 1 = 2 μ(x)`: tree complexity *is* size. -/
theorem binTreeK_add_one_eq (μ : M → ℕ) (hgen : ∀ i, μ (gen i) = 1)
    (hop : ∀ x y, μ (op x y) = μ x + μ y) {x : M} (hx : binTreeK gen op x ≠ ⊤) :
    binTreeK gen op x + 1 = 2 * (μ x : ℕ∞) := by
  obtain ⟨t, ht, hc⟩ :=
    (termSystem (binAlg gen op) (sizeRule (binSig ι) fun _ => 1)).exists_cost_eq_K hx
  have ht' : eval (binAlg gen op) t = x := ht
  have hc' : cost (sizeRule (binSig ι) fun _ => 1) t = binTreeK gen op x := hc
  rw [← hc', ← ht']
  exact cost_add_one_eq gen op μ hgen hop t

/-- **The gain window in an extensive domain.** For constructible `x` of size `μ x`,
built with sharing in `n` steps: `2 μ(x) ≤ 2 ^ n`, while the tree needs exactly
`2 μ(x) - 1` nodes. The gain from reuse is `(2 μ - 1) / dagK`, between `1` and
`(2 μ - 1) / (1 + log₂ μ)`. -/
theorem gain_window (μ : M → ℕ) (hgen : ∀ i, μ (gen i) = 1)
    (hop : ∀ x y, μ (op x y) = μ x + μ y) {x : M} (hx : binTreeK gen op x ≠ ⊤) {n : ℕ}
    (h : binK gen op x ≤ n) :
    binTreeK gen op x + 1 = 2 * (μ x : ℕ∞) ∧ 2 * μ x ≤ 2 ^ n ∧
      binK gen op x + 1 ≤ 2 * (μ x : ℕ∞) := by
  have h1 := binTreeK_add_one_eq gen op μ hgen hop hx
  refine ⟨h1, ?_, ?_⟩
  · have h2 := binTreeK_add_one_le_two_pow gen op h
    rw [h1] at h2
    exact_mod_cast h2
  · rw [← h1]
    exact add_le_add (binK_le_binTreeK gen op x) le_rfl

theorem binTreeK_op_ne_top {x y : M} (hx : binTreeK gen op x ≠ ⊤) (hy : binTreeK gen op y ≠ ⊤) :
    binTreeK gen op (op x y) ≠ ⊤ := by
  refine ne_top_of_le_ne_top ?_ (binTreeK_op_le gen op x y)
  simp [hx, hy]

theorem binTreeK_gen_ne_top (i : ι) : binTreeK gen op (gen i) ≠ ⊤ :=
  ne_top_of_le_ne_top (by simp) (binTreeK_gen_le gen op i)

/-! ### The support bound: what reuse cannot share

A **support** assigns to each object a finite set of atoms, at most one atom to a
generator, with `σ (x ∘ y) ⊆ σ x ∪ σ y`. An object whose support has `m` atoms needs `m`
generator steps to introduce them and `m - 1` operations to connect them, shared or not.

The proof colours the atoms. Introducing a generator adds at most one atom, in a fresh
colour. An operation merges at most two colours. Every object in the pool is
monochromatic. So `#atoms - #colours ≤ #operations`, and a support of `m` atoms in one
colour forces `m - 1` operations. -/

section Support

variable {S : Type*} [DecidableEq S]

/-- Every object of `T` has its support inside `D`, in one colour. -/
private def Mono (σ : M → Finset S) (T : Set M) (D : Finset S) (c : S → ℕ) : Prop :=
  ∀ v ∈ T, σ v ⊆ D ∧ ∀ s ∈ σ v, ∀ t ∈ σ v, c s = c t

private theorem mono_op {σ : M → Finset S} (hop : ∀ x y, σ (op x y) ⊆ σ x ∪ σ y)
    {T : Set M} {D : Finset S} {c : S → ℕ} (h : Mono σ T D c) {a b : M} (ha : a ∈ T)
    (hb : b ∈ T) :
    ∃ c' : S → ℕ, Mono σ (insert (op a b) T) D c' ∧ (D.image c).card ≤ (D.image c').card + 1 := by
  have hv := hop a b
  obtain ⟨ha1, ha2⟩ := h a ha
  obtain ⟨hb1, hb2⟩ := h b hb
  rcases (σ a).eq_empty_or_nonempty with hae | ⟨sa, hsa⟩
  · refine ⟨c, ?_, Nat.le_succ _⟩
    rintro v (rfl | hv')
    · have hsub : σ (op a b) ⊆ σ b := by rwa [hae, Finset.empty_union] at hv
      exact ⟨hsub.trans hb1, fun s hs t ht => hb2 s (hsub hs) t (hsub ht)⟩
    · exact h v hv'
  rcases (σ b).eq_empty_or_nonempty with hbe | ⟨sb, hsb⟩
  · refine ⟨c, ?_, Nat.le_succ _⟩
    rintro v (rfl | hv')
    · have hsub : σ (op a b) ⊆ σ a := by rwa [hbe, Finset.union_empty] at hv
      exact ⟨hsub.trans ha1, fun s hs t ht => ha2 s (hsub hs) t (hsub ht)⟩
    · exact h v hv'
  -- recolour the colour of `b` as the colour of `a`
  refine ⟨fun s => if c s = c sb then c sa else c s, ?_, ?_⟩
  · rintro v (rfl | hv')
    · refine ⟨hv.trans (Finset.union_subset ha1 hb1), ?_⟩
      have key : ∀ s ∈ σ (op a b), (if c s = c sb then c sa else c s) = c sa := by
        intro s hs
        rcases Finset.mem_union.1 (hv hs) with h' | h'
        · have e : c s = c sa := ha2 s h' sa hsa
          split_ifs
          · rfl
          · exact e
        · have e : c s = c sb := hb2 s h' sb hsb
          simp [e]
      intro s hs t ht
      show (if c s = c sb then c sa else c s) = if c t = c sb then c sa else c t
      rw [key s hs, key t ht]
    · obtain ⟨h1, h2⟩ := h v hv'
      refine ⟨h1, fun s hs t ht => ?_⟩
      show (if c s = c sb then c sa else c s) = if c t = c sb then c sa else c t
      rw [h2 s hs t ht]
  · have hsub : (D.image c).erase (c sb) ⊆ D.image fun s => if c s = c sb then c sa else c s := by
      intro γ hγ
      obtain ⟨hne, hmemγ⟩ := Finset.mem_erase.1 hγ
      obtain ⟨s, hs, rfl⟩ := Finset.mem_image.1 hmemγ
      exact Finset.mem_image.2 ⟨s, hs, by simp [hne]⟩
    have h1 := Finset.card_le_card hsub
    have h2 := Finset.pred_card_le_card_erase (s := D.image c) (a := c sb)
    omega

private theorem mono_gen {σ : M → Finset S} {T : Set M} {D : Finset S} {c : S → ℕ}
    (h : Mono σ T D c) {x0 : M} (hx0 : (σ x0).card ≤ 1) :
    ∃ (D' : Finset S) (c' : S → ℕ), Mono σ (insert x0 T) D' c' ∧ D'.card ≤ D.card + 1 ∧
      D'.card + (D.image c).card ≤ (D'.image c').card + D.card := by
  have hone := Finset.card_le_one.1 hx0
  by_cases hsub : σ x0 ⊆ D
  · refine ⟨D, c, ?_, Nat.le_succ _, le_of_eq (add_comm _ _)⟩
    rintro v (rfl | hv')
    · exact ⟨hsub, fun s hs t ht => by rw [hone s hs t ht]⟩
    · exact h v hv'
  · obtain ⟨s0, hs0, hs0D⟩ := Finset.not_subset.1 hsub
    obtain ⟨fresh, hfresh⟩ := Infinite.exists_notMem_finset (D.image c)
    have hcong : ∀ s ∈ D, Function.update c s0 fresh s = c s := fun s hs =>
      Function.update_of_ne (fun e : s = s0 => hs0D (e ▸ hs)) _ _
    refine ⟨insert s0 D, Function.update c s0 fresh, ?_, ?_, ?_⟩
    · rintro v (rfl | hv')
      · refine ⟨fun s hs => ?_, fun s hs t ht => by rw [hone s hs t ht]⟩
        rw [hone s hs s0 hs0]
        exact Finset.mem_insert_self _ _
      · obtain ⟨h1, h2⟩ := h v hv'
        refine ⟨h1.trans (Finset.subset_insert _ _), fun s hs t ht => ?_⟩
        rw [hcong s (h1 hs), hcong t (h1 ht)]
        exact h2 s hs t ht
    · rw [Finset.card_insert_of_notMem hs0D]
    · have himg : (insert s0 D).image (Function.update c s0 fresh) = insert fresh (D.image c) := by
        rw [Finset.image_insert, Function.update_self, Finset.image_congr hcong]
      rw [himg, Finset.card_insert_of_notMem hfresh, Finset.card_insert_of_notMem hs0D]
      omega

private theorem pool_support (σ : M → Finset S) (hgen : ∀ i, (σ (gen i)).card ≤ 1)
    (hop : ∀ x y, σ (op x y) ⊆ σ x ∪ σ y) :
    ∀ {Q : Pool (binAlg gen op)} (p : Path (⟨∅⟩ : Pool (binAlg gen op)) Q),
      ∃ (D : Finset S) (c : S → ℕ) (g o : ℕ), g + o = p.length ∧ Mono σ Q.set D c ∧
        D.card ≤ g ∧ D.card ≤ (D.image c).card + o
  | _, .nil => ⟨∅, fun _ => 0, 0, 0, rfl, fun v hv => absurd hv (Set.notMem_empty v), le_rfl,
      by simp⟩
  | _, .cons p e => by
      obtain ⟨D, c, g, o, hlen, hinv, hDg, hDo⟩ := pool_support σ hgen hop p
      obtain ⟨o', args, hmem, heq⟩ := e
      rcases o' with _ | i
      · obtain ⟨c', hI, hc⟩ := mono_op op hop hinv (hmem (0 : Fin 2)) (hmem (1 : Fin 2))
        refine ⟨D, c', g, o + 1, by rw [Path.length_cons]; omega, ?_, hDg, by omega⟩
        rw [heq]
        exact hI
      · obtain ⟨D', c', hI, h1, h2⟩ := mono_gen hinv (x0 := gen i) (hgen i)
        refine ⟨D', c', g + 1, o, by rw [Path.length_cons]; omega, ?_, by omega, by omega⟩
        rw [heq]
        exact hI

/-- **The support bound.** Anything built in `n` steps, with sharing, has at most
`(n + 1) / 2` atoms in its support. -/
theorem two_mul_card_support_le (σ : M → Finset S) (hgen : ∀ i, (σ (gen i)).card ≤ 1)
    (hop : ∀ x y, σ (op x y) ⊆ σ x ∪ σ y) {x : M} {n : ℕ} (h : binK gen op x ≤ n) :
    2 * (σ x).card ≤ n + 1 := by
  obtain ⟨Q, hx, p, hp⟩ := poolK_le_coe_iff.1 h
  rw [pathCost_poolWeight_one] at hp
  have hlen : p.length ≤ n := by exact_mod_cast hp
  obtain ⟨D, c, g, o, hgo, hinv, hDg, hDo⟩ := pool_support gen op σ hgen hop p
  obtain ⟨hsub, hconst⟩ := hinv x (hx rfl)
  have h1 : (σ x).card ≤ D.card := Finset.card_le_card hsub
  rcases (σ x).eq_empty_or_nonempty with he | ⟨s0, hs0⟩
  · rw [he]
    simp
  have h2 : (D.image c).card + (σ x).card ≤ D.card + 1 := by
    have hsplit : D.image c ⊆ (D \ σ x).image c ∪ {c s0} := by
      intro γ hγ
      obtain ⟨s, hs, rfl⟩ := Finset.mem_image.1 hγ
      by_cases hsx : s ∈ σ x
      · exact Finset.mem_union_right _ (Finset.mem_singleton.2 (hconst s hsx s0 hs0))
      · exact Finset.mem_union_left _
          (Finset.mem_image.2 ⟨s, Finset.mem_sdiff.2 ⟨hs, hsx⟩, rfl⟩)
    have ha := Finset.card_le_card hsplit
    have hb := Finset.card_union_le ((D \ σ x).image c) {c s0}
    have hc := Finset.card_image_le (s := D \ σ x) (f := c)
    have hd := Finset.card_sdiff_add_card_eq_card hsub
    rw [Finset.card_singleton] at hb
    omega
  omega

/-- The support bound as an inequality between complexities:
`2 |σ x| - 1 ≤ dagK x`. -/
theorem two_mul_card_support_le_binK (σ : M → Finset S) (hgen : ∀ i, (σ (gen i)).card ≤ 1)
    (hop : ∀ x y, σ (op x y) ⊆ σ x ∪ σ y) (x : M) :
    2 * ((σ x).card : ℕ∞) ≤ binK gen op x + 1 := by
  rcases eq_or_ne (binK gen op x) ⊤ with h | h
  · simp [h]
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 h
  rw [← hn]
  exact_mod_cast two_mul_card_support_le gen op σ hgen hop (x := x) (n := n) hn.ge

/-- **Zero-gain criterion.** If an expression tree for `x` uses each atom of the support
once – `treeK x ≤ 2 |σ x| - 1` – then sharing cannot improve on it. -/
theorem binK_eq_binTreeK_of_le (σ : M → Finset S) (hgen : ∀ i, (σ (gen i)).card ≤ 1)
    (hop : ∀ x y, σ (op x y) ⊆ σ x ∪ σ y) {x : M}
    (h : binTreeK gen op x + 1 ≤ 2 * ((σ x).card : ℕ∞)) :
    binK gen op x = binTreeK gen op x :=
  le_antisymm (binK_le_binTreeK gen op x)
    ((ENat.add_le_add_iff_right (by simp)).1
      (h.trans (two_mul_card_support_le_binK gen op σ hgen hop x)))

/-- **The gain is at most the multiplicity.** In an extensive domain with size `μ` and
support `σ`, `(treeK + 1) · |σ x| ≤ μ x · (dagK + 1)`: sharing improves on the tree by at
most the average number of times an atom is repeated. -/
theorem gain_le_multiplicity (σ : M → Finset S) (hgen : ∀ i, (σ (gen i)).card ≤ 1)
    (hop : ∀ x y, σ (op x y) ⊆ σ x ∪ σ y) (μ : M → ℕ) (hμgen : ∀ i, μ (gen i) = 1)
    (hμop : ∀ x y, μ (op x y) = μ x + μ y) {x : M} (hx : binTreeK gen op x ≠ ⊤) :
    (binTreeK gen op x + 1) * ((σ x).card : ℕ∞) ≤ (μ x : ℕ∞) * (binK gen op x + 1) := by
  rw [binTreeK_add_one_eq gen op μ hμgen hμop hx]
  calc 2 * (μ x : ℕ∞) * ((σ x).card : ℕ∞) = (μ x : ℕ∞) * (2 * ((σ x).card : ℕ∞)) := by ring
    _ ≤ (μ x : ℕ∞) * (binK gen op x + 1) := by
        gcongr
        exact two_mul_card_support_le_binK gen op σ hgen hop x

end Support

end Binary

/-- **Numbers under addition are extensive**: as a sum of ones, `n` costs exactly `2n - 1`
nodes, whatever its arithmetic structure; all structure is in the addition chain. -/
theorem Chain.treeK_eq {n : ℕ} (hn : 1 ≤ n) :
    Binary.binTreeK Chain.one (· * ·) (Multiplicative.ofAdd n) + 1 = 2 * (n : ℕ∞) := by
  have hfin : ∀ m : ℕ,
      Binary.binTreeK Chain.one (· * ·) (Multiplicative.ofAdd (m + 1)) ≠ ⊤ := by
    intro m
    induction m with
    | zero => exact Binary.binTreeK_gen_ne_top Chain.one _ ()
    | succ m ih =>
      have h : Multiplicative.ofAdd (m + 1 + 1)
          = Multiplicative.ofAdd (m + 1) * Chain.one () := rfl
      rw [h]
      exact Binary.binTreeK_op_ne_top _ _ ih (Binary.binTreeK_gen_ne_top Chain.one _ ())
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  exact Binary.binTreeK_add_one_eq Chain.one (· * ·) (fun x => x.toAdd) (fun _ => rfl)
    (fun _ _ => rfl) (hfin m)

/-- **Strings under concatenation are extensive**: without reuse a non-empty string costs
exactly `2|w| - 1` nodes; every string of a given length has the same tree complexity. -/
theorem Str.treeK_eq {α : Type*} {w : FreeMonoid α} (hw : w ≠ 1) :
    Binary.binTreeK (FreeMonoid.of : α → FreeMonoid α) (· * ·) w + 1
      = 2 * (w.toList.length : ℕ∞) := by
  have hfin : ∀ w : FreeMonoid α, w ≠ 1 →
      Binary.binTreeK (FreeMonoid.of : α → FreeMonoid α) (· * ·) w ≠ ⊤ := by
    intro w
    induction w using FreeMonoid.inductionOn' with
    | one => exact fun h => absurd rfl h
    | of_mul a w ih =>
      intro _
      rcases eq_or_ne w 1 with rfl | hw'
      · rw [mul_one]
        exact Binary.binTreeK_gen_ne_top _ _ a
      · exact Binary.binTreeK_op_ne_top _ _ (Binary.binTreeK_gen_ne_top _ _ a) (ih hw')
  exact Binary.binTreeK_add_one_eq FreeMonoid.of (· * ·) (fun w => w.toList.length)
    (fun _ => by simp) (fun a b => by simp) (hfin w hw)

/-- **Typical strings gain little.** Every string of length `L` has the same tree
complexity `2L - 1`, yet for any `n` with `n · (3n²)ⁿ < 2 ^ L` some binary string of
length `L` needs more than `n` steps even with reuse. Since such `n` grow like
`L / log L`, reuse buys a typical string only a logarithmic factor; the exponential gain
of `ChainK`-like objects is the exception. -/
theorem Str.exists_low_gain (L n : ℕ) (h : n * (3 * n ^ 2) ^ n < 2 ^ L) :
    ∃ w : FreeMonoid Bool, w.toList.length = L ∧ (n : ℕ∞) < Str.strK w := by
  classical
  let A : Finset (FreeMonoid Bool) :=
    (Finset.univ : Finset (List.Vector Bool L)).image fun v => FreeMonoid.ofList v.1
  have hinj : Function.Injective fun v : List.Vector Bool L => FreeMonoid.ofList v.1 :=
    fun v v' hv => Subtype.ext (by simpa using congrArg FreeMonoid.toList hv)
  have hA : A.card = 2 ^ L := by
    rw [Finset.card_image_of_injective _ hinj, Finset.card_univ, card_vector,
      Fintype.card_bool]
  obtain ⟨w, hw, hK⟩ := Binary.exists_binK_gt (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)
    n A (by rw [hA, Fintype.card_bool]; exact h)
  obtain ⟨v, -, rfl⟩ := Finset.mem_image.1 hw
  exact ⟨_, by simp, hK⟩

/-! ### Instances of the support bound -/

/-- **In the free semilattice reuse buys nothing.** A finite set built from singletons by
unions costs exactly `2|s| - 1` steps, with or without sharing. -/
theorem SetUnion.binK_add_one_eq {α : Type*} [DecidableEq α] {s : Finset α} (hs : s.Nonempty) :
    Binary.binK (fun a : α => ({a} : Finset α)) (· ∪ ·) s + 1 = 2 * (s.card : ℕ∞) ∧
      Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) s + 1 = 2 * (s.card : ℕ∞) := by
  have htree : ∀ s : Finset α, s.Nonempty →
      Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) s + 1 ≤ 2 * (s.card : ℕ∞) := by
    intro s
    induction s using Finset.induction_on with
    | empty => exact fun h => absurd h (by simp)
    | insert a t hat ih =>
      intro _
      rcases t.eq_empty_or_nonempty with rfl | ht
      · have h1 := Binary.binTreeK_gen_le (fun a : α => ({a} : Finset α)) (· ∪ ·) a
        have e : insert a (∅ : Finset α) = {a} := rfl
        rw [e, Finset.card_singleton]
        calc Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) {a} + 1 ≤ 1 + 1 :=
              add_le_add h1 le_rfl
          _ = 2 * ((1 : ℕ) : ℕ∞) := by norm_num
      · have h1 := Binary.binTreeK_gen_le (fun a : α => ({a} : Finset α)) (· ∪ ·) a
        have h2 := Binary.binTreeK_op_le (fun a : α => ({a} : Finset α)) (· ∪ ·) {a} t
        rw [Finset.insert_eq, ← Finset.insert_eq, Finset.card_insert_of_notMem hat,
          Finset.insert_eq]
        calc Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) ({a} ∪ t) + 1
            ≤ 1 + (Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) {a}
                + Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) t) + 1 :=
              add_le_add h2 le_rfl
          _ ≤ 1 + (1 + Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) t) + 1 := by
              gcongr
          _ = 2 + (Binary.binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) t + 1) := by ring
          _ ≤ 2 + 2 * (t.card : ℕ∞) := by gcongr; exact ih ht
          _ = 2 * ((t.card + 1 : ℕ) : ℕ∞) := by push_cast; ring
  have hsupp := Binary.two_mul_card_support_le_binK (fun a : α => ({a} : Finset α)) (· ∪ ·)
    (fun s : Finset α => s) (fun a => by simp) (fun x y => le_rfl) s
  have hle := add_le_add (Binary.binK_le_binTreeK (fun a : α => ({a} : Finset α)) (· ∪ ·) s)
    (le_refl (1 : ℕ∞))
  exact ⟨le_antisymm (hle.trans (htree s hs)) hsupp,
    le_antisymm (htree s hs) (hsupp.trans hle)⟩

/-- **A string needs its alphabet.** Building `w` takes at least `2k - 1` steps, where `k`
is the number of distinct letters in `w`, however much is shared. -/
theorem Str.two_mul_card_letters_le {α : Type*} [DecidableEq α] (w : FreeMonoid α) :
    2 * ((w.toList.toFinset.card : ℕ) : ℕ∞) ≤ Str.strK w + 1 :=
  Binary.two_mul_card_support_le_binK (FreeMonoid.of : α → FreeMonoid α) (· * ·)
    (fun w => w.toList.toFinset) (fun a => by simp)
    (fun x y => by simp [List.toFinset_append]) w

/-- **A string with no repeated letter gains nothing from reuse**: it costs `2|w| - 1`
steps with sharing, the same as without. Reuse needs repetition. -/
theorem Str.strK_add_one_eq_of_nodup {α : Type*} [DecidableEq α] {w : FreeMonoid α}
    (hw : w ≠ 1) (hnd : w.toList.Nodup) : Str.strK w + 1 = 2 * (w.toList.length : ℕ∞) := by
  have h1 := Str.two_mul_card_letters_le w
  rw [List.toFinset_card_of_nodup hnd] at h1
  have h2 := add_le_add
    (Binary.binK_le_binTreeK (FreeMonoid.of : α → FreeMonoid α) (· * ·) w) (le_refl (1 : ℕ∞))
  rw [Str.treeK_eq hw] at h2
  exact le_antisymm h2 h1

/-- **The gain of a string is at most its mean letter multiplicity**:
`2|w| · k ≤ |w| · (strK w + 1)` for a string with `k` distinct letters. -/
theorem Str.gain_le_multiplicity {α : Type*} [DecidableEq α] (w : FreeMonoid α) :
    2 * (w.toList.length : ℕ∞) * ((w.toList.toFinset.card : ℕ) : ℕ∞)
      ≤ (w.toList.length : ℕ∞) * (Str.strK w + 1) := by
  calc 2 * (w.toList.length : ℕ∞) * ((w.toList.toFinset.card : ℕ) : ℕ∞)
      = (w.toList.length : ℕ∞) * (2 * ((w.toList.toFinset.card : ℕ) : ℕ∞)) := by ring
    _ ≤ (w.toList.length : ℕ∞) * (Str.strK w + 1) := by
        gcongr
        exact Str.two_mul_card_letters_le w

/-! ### An upper bound: the binary method, and what it leaves open

The multiplicity bound says the gain is at most `μ / |σ|`. For products of powers of
generators the binary method comes within a logarithm of it: `x ^ m` costs `2 log₂ m`
steps beyond `x`, so a monomial with `k` atoms and exponents up to `m` costs about
`2 k log₂ m` steps against `2 k m` nodes for the tree. A counting argument shows that
`k log m / log (k log m)` steps are needed for some monomial, so the support and growth
bounds (`k` and `log m`) are **not** jointly tight. -/

namespace MonoidGen

open Binary Sig

/-- **Binary exponentiation, with the base kept.** A pool containing `x ^ m` and `x` costs
at most `2 log₂ m` steps more than `x`. -/
theorem poolK_pow_le {ι : Type*} {M : Type*} [Monoid M] (gen : ι → M) (x : M) :
    ∀ m : ℕ, 1 ≤ m → poolK (binAlg gen (· * ·)) (fun _ => 1) {x ^ m, x} ≤
      slK gen x + ((2 * Nat.log 2 m : ℕ) : ℕ∞) := by
  intro m
  induction m using Nat.strong_induction_on with
  | _ m ih =>
    intro hm
    rcases Nat.eq_or_lt_of_le hm with rfl | hlt
    · simp only [pow_one, Set.pair_eq_singleton, Nat.log_one_right, mul_zero, Nat.cast_zero,
        add_zero]
      exact le_rfl
    · have hq : 1 ≤ m / 2 := by omega
      have ih' := ih (m / 2) (by omega) hq
      have hlog : Nat.log 2 m = Nat.log 2 (m / 2) + 1 :=
        Nat.log_of_one_lt_of_le (by norm_num) (by omega)
      have h1 : poolK (binAlg gen (· * ·)) (fun _ => 1)
          (insert (x ^ (m / 2) * x ^ (m / 2)) {x ^ (m / 2), x}) ≤
          poolK (binAlg gen (· * ·)) (fun _ => 1) {x ^ (m / 2), x} + 1 :=
        poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1) {x ^ (m / 2), x} none
          ![x ^ (m / 2), x ^ (m / 2)] (fun b => by fin_cases b <;> simp)
      have h2 : poolK (binAlg gen (· * ·)) (fun _ => 1)
          (insert (x ^ (m / 2) * x ^ (m / 2) * x)
            (insert (x ^ (m / 2) * x ^ (m / 2)) {x ^ (m / 2), x})) ≤
          poolK (binAlg gen (· * ·)) (fun _ => 1)
            (insert (x ^ (m / 2) * x ^ (m / 2)) {x ^ (m / 2), x}) + 1 :=
        poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1)
          (insert (x ^ (m / 2) * x ^ (m / 2)) {x ^ (m / 2), x}) none
          ![x ^ (m / 2) * x ^ (m / 2), x] (fun b => by fin_cases b <;> simp)
      have hsub : ({x ^ m, x} : Set M) ⊆ insert (x ^ (m / 2) * x ^ (m / 2) * x)
          (insert (x ^ (m / 2) * x ^ (m / 2)) {x ^ (m / 2), x}) := by
        rintro y (rfl | rfl)
        · rcases Nat.mod_two_eq_zero_or_one m with h | h
          · have e : m = m / 2 + m / 2 := by omega
            right; left
            conv_lhs => rw [e]
            exact pow_add x _ _
          · have e : m = m / 2 + m / 2 + 1 := by omega
            left
            conv_lhs => rw [e]
            rw [pow_succ, pow_add]
        · simp
      calc poolK (binAlg gen (· * ·)) (fun _ => 1) {x ^ m, x}
          ≤ _ := poolK_mono hsub
        _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) {x ^ (m / 2), x} + 1 + 1 :=
            h2.trans (add_le_add h1 le_rfl)
        _ ≤ slK gen x + ((2 * Nat.log 2 (m / 2) : ℕ) : ℕ∞) + 1 + 1 := by gcongr
        _ = slK gen x + ((2 * Nat.log 2 m : ℕ) : ℕ∞) := by
            rw [hlog]
            push_cast
            ring

/-- **Binary exponentiation**: `x ^ m` costs at most `2 log₂ m` steps more than `x`. -/
theorem slK_pow_le {ι : Type*} {M : Type*} [Monoid M] (gen : ι → M) (x : M) {m : ℕ}
    (hm : 1 ≤ m) : slK gen (x ^ m) ≤ slK gen x + ((2 * Nat.log 2 m : ℕ) : ℕ∞) :=
  (poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))).trans
    (poolK_pow_le gen x m hm)

/-- **Monomials by the binary method.** A product of powers of `k` generators with
exponents `e i ≥ 1` costs at most `∑ (2 log₂ (e i) + 2) - 1` steps. -/
theorem slK_prod_pow_le {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M) (e : ι → ℕ)
    {s : Finset ι} (hs : s.Nonempty) :
    (∀ i ∈ s, 1 ≤ e i) → slK gen (∏ i ∈ s, gen i ^ e i) + 1 ≤
      ∑ i ∈ s, ((2 * Nat.log 2 (e i) + 2 : ℕ) : ℕ∞) := by
  have hone : ∀ a, 1 ≤ e a → slK gen (gen a ^ e a) + 1 ≤ ((2 * Nat.log 2 (e a) + 2 : ℕ) : ℕ∞) := by
    intro a ha
    calc slK gen (gen a ^ e a) + 1 ≤ slK gen (gen a) + ((2 * Nat.log 2 (e a) : ℕ) : ℕ∞) + 1 :=
          add_le_add (slK_pow_le gen (gen a) ha) le_rfl
      _ ≤ 1 + ((2 * Nat.log 2 (e a) : ℕ) : ℕ∞) + 1 := by
          gcongr
          exact slK_gen_le gen a
      _ = _ := by push_cast; ring
  induction hs using Finset.Nonempty.cons_induction with
  | singleton a =>
    intro he
    rw [Finset.prod_singleton, Finset.sum_singleton]
    exact hone a (he a (Finset.mem_singleton_self a))
  | cons a s ha hs ih =>
    intro he
    rw [Finset.prod_cons, Finset.sum_cons]
    have h1 := hone a (he a (Finset.mem_cons_self a s))
    have h2 := ih fun i hi => he i (Finset.mem_cons.2 (Or.inr hi))
    calc slK gen (gen a ^ e a * ∏ i ∈ s, gen i ^ e i) + 1
        ≤ slK gen (gen a ^ e a) + slK gen (∏ i ∈ s, gen i ^ e i) + 1 + 1 :=
          add_le_add (slK_mul_le gen _ _) le_rfl
      _ = (slK gen (gen a ^ e a) + 1) + (slK gen (∏ i ∈ s, gen i ^ e i) + 1) := by ring
      _ ≤ _ := add_le_add h1 h2

end MonoidGen

/-- **Some monomial is hard.** Among the monomials in `k` atoms with exponents below `m`
there is one that needs more than `n` steps, whenever `n · ((k+1) n²)ⁿ < mᵏ`. Such `n` grow
like `k log m / log (k log m)`: more than both the support bound `k` and the growth bound
`log m`. -/
theorem Monomial.exists_slK_gt (k m n : ℕ) (h : n * ((k + 1) * n ^ 2) ^ n < m ^ k) :
    ∃ e : Fin k → ℕ, (∀ i, e i < m) ∧
      (n : ℕ∞) < MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) := by
  classical
  let A : Finset (Multiplicative (Fin k → ℕ)) :=
    (Fintype.piFinset fun _ : Fin k => Finset.range m).image Multiplicative.ofAdd
  have hA : A.card = m ^ k := by
    rw [Finset.card_image_of_injective _ Multiplicative.ofAdd.injective, Fintype.card_piFinset]
    simp
  obtain ⟨x, hx, hK⟩ := Binary.exists_binK_gt
    (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) (· * ·) n A
    (by rw [hA, Fintype.card_fin]; exact h)
  obtain ⟨e, he, rfl⟩ := Finset.mem_image.1 hx
  exact ⟨e, fun i => Finset.mem_range.1 (Fintype.mem_piFinset.1 he i), hK⟩

/-- **Every monomial is within a logarithm of the multiplicity bound.** In the free
commutative monoid on `k` atoms, the monomial with exponents `e i ≥ 1` costs at most
`∑ (2 log₂ (e i) + 2) - 1` steps with sharing, against `2 ∑ e i - 1` nodes without. -/
theorem Monomial.slK_add_one_le {k : ℕ} (hk : 0 < k) (e : Fin k → ℕ) (he : ∀ i, 1 ≤ e i) :
    MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤ ∑ i, ((2 * Nat.log 2 (e i) + 2 : ℕ) : ℕ∞) := by
  have hprod : ∏ i, (Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) ^ e i
      = Multiplicative.ofAdd e := by
    simp_rw [← ofAdd_nsmul]
    rw [← ofAdd_sum]
    congr 1
    funext j
    simp [Finset.sum_apply, Pi.single_apply]
  rw [← hprod]
  exact MonoidGen.slK_prod_pow_le _ e (Finset.univ_nonempty_iff.2 ⟨⟨0, hk⟩⟩) fun i _ => he i

namespace Circuit

open Classical in
/-- The **essential variables** of a Boolean function: those whose flip can change the
value. -/
noncomputable def essential {n : ℕ} (f : BoolFn n) : Finset (Fin n) :=
  Finset.univ.filter fun i => ∃ v, f v ≠ f (Function.update v i (!v i))

/-- **The trivial circuit lower bound**, as an instance of the support bound: a NAND
circuit for a function with `m` essential variables has at least `m` inputs and `m - 1`
gates. -/
theorem two_mul_card_essential_le {n : ℕ} (f : BoolFn n) :
    2 * (((essential f).card : ℕ) : ℕ∞) ≤ circuitK f + 1 := by
  classical
  refine Binary.two_mul_card_support_le_binK (proj n) nand essential (fun i => ?_)
    (fun x y => ?_) f
  · have hsub : essential (proj n i) ⊆ {i} := by
      intro j hj
      obtain ⟨v, hv⟩ := (Finset.mem_filter.1 hj).2
      by_contra hne
      have hij : i ≠ j := fun e => hne (by simp [e])
      exact hv (by simp [proj, Function.update_of_ne hij])
    exact (Finset.card_le_card hsub).trans (by simp)
  · intro j hj
    obtain ⟨v, hv⟩ := (Finset.mem_filter.1 hj).2
    by_contra hnot
    rw [Finset.mem_union, not_or] at hnot
    have hx : x v = x (Function.update v j (!v j)) := by
      by_contra hne
      exact hnot.1 (Finset.mem_filter.2 ⟨Finset.mem_univ _, v, hne⟩)
    have hy : y v = y (Function.update v j (!v j)) := by
      by_contra hne
      exact hnot.2 (Finset.mem_filter.2 ⟨Finset.mem_univ _, v, hne⟩)
    exact hv (by simp [nand, hx, hy])

end Circuit

end Complexity
