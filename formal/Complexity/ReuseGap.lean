import Complexity.Binary
import Complexity.Instances.Monoid
import Complexity.Instances.Circuit
import Mathlib.Combinatorics.Enumerative.Catalan.Tree

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
* `Monomial.exists_slK_gt` – but some monomial with exponents from `1` to `m` needs about
                        `k log m / log (k log m)` steps.
* `Monomial.exists_slK_gt_mul` – hence for every constant `C` some monomial costs more than
                        `C · (#atoms + log₂ (largest exponent))`. The support bound and
                        the growth bound are **not** jointly tight.
* `MonoidGen.slK_prod_pow_add_one_le` – Straus's method: tabulate the products of all
                        subsets of the atoms, then share the squarings. `k` atoms with
                        exponents below `2 ^ L` cost fewer than `2 ^ k + 2 L` steps.
* `Monomial.slK_add_one_le_grouped`, `Monomial.slK_add_one_le_log` – in groups of `g`
                        atoms: fewer than `(k / g + 1) (2 ^ g + 2 L)` steps, hence at
                        most `3 L (k / log₂ L + 1)`.
* `Monomial.exists_slK_between` – both sides for `k = 2 ^ j` atoms and exponents up to
                        `2 ^ k`: the worst case lies between about `k² / (10 log₂ k)` and
                        `3 k² / log₂ k`.
* `Monomial.exists_slK_between_general` – both sides for any `k` atoms and exponents up to
                        `2 ^ L`: the same order whenever `log₂ L ≤ k ≤ L ^ c`.

* `Circuit.circuitK_le_shannon` – the same idea for Boolean circuits (Shannon): tabulate
                        every function of `k` variables, then select with the other
                        `n - k`. Every function of `n` variables costs at most
                        `n + 2 ^ 2 ^ k (5 + 2 ^ k (4 k + 7)) + 4 · 2 ^ (n - k)` steps.
* `Circuit.exists_circuitK_between` – with the counting bound: the hardest function of
                        `n` variables costs between about `2ⁿ / (4 n)` and `8 · 2ⁿ / n`.
* `Str.strK_le_blocks`, `Str.exists_strK_between` – and for binary strings: a table of
                        all blocks of length `g`, then one concatenation per block. The
                        hardest string of length `L` costs between about
                        `L / (4 log₂ L)` and `2 L / log₂ L`.

* `MonoidGen.slK_list_prod_le_blocks` – the block table in any monoid with `σ` generators:
                        a product of `L` generators costs at most
                        `g · σ ^ g · 2 g + L / g` steps. Where size is additive, sharing
                        always saves a factor of order `log L`.

In all three cases the worst case with sharing has the order of the counting bound,
`log N / log log N` for a population of `N` objects, and the upper bound is the same
construction: a shared table of everything small, then one step per use. This is the
classical Shannon effect and each case is a known theorem (Berstel and Brlek for strings,
Straus and Pippenger for monomials, Shannon and Lupanov for circuits).

* `SetUnion.counting_not_tight` – it is not a general law: in the free semilattice the
                        hardest object costs `2k - 1` by the support bound, more than any
                        constant times what counting can show.
* `Binary.depth_add_one_le` – the depth bound: any `φ` that is `0` on generators and grows
                        by at most one per operation is a lower bound, with sharing. The
                        growth bound is the case `φ = ⌈log₂ size⌉`.
* `Comb.binK_comb`, `Comb.counting_misses_depth` – a comb-shaped binary tree with `n` nodes
                        costs exactly `n + 1` steps; support, growth and counting give
                        `1`, `log₂ (n + 1)` and about `n / log n`.
* `Comb.card_sub_le_cost`, `Comb.obstructions_incomplete` – a binary tree costs at least
                        its number of distinct subtrees, and some tree with one atom and
                        logarithmic height has almost as many of those as nodes. Support,
                        depth and counting together do not decide the cost.
* `Comb.cost_eq_card_sub`, `Comb.cost_perfect` – in fact exactly that number. A perfect
                        tree with `2 ^ d - 1` nodes costs `d + 1` steps; a comb with `n`
                        nodes costs `n + 1`.

What is *not* here: the exact constant for monomials and the order outside the range
`log₂ L ≤ k ≤ L` (Pippenger's theorem on vector addition chains); the exact constant for
circuits (Lupanov); and any lower bound for an explicit Boolean function beyond the
trivial one. There a function can have small support and no additive size, both measures
are silent, and the gap is the formula-versus-circuit problem, which is open.
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

/-! ### Shared squarings

The binary method spends `2 log₂ m` steps on each atom. Straus's method spends them once:
tabulate the products of all nonempty sets of atoms, then read the exponents one binary
digit at a time, squaring the running product and multiplying by the table entry for the
atoms whose digit is one. -/

/-- The products over the nonempty subsets of `I`. -/
def subsetProds {ι : Type*} {M : Type*} [CommMonoid M] (x : ι → M) (I : Finset ι) : Set M :=
  {y | ∃ s ⊆ I, s.Nonempty ∧ y = ∏ i ∈ s, x i}

/-- **One digit, two steps.** Once the products over all nonempty subsets of `I` are in the
pool, a product of powers with exponents below `2 ^ L` costs `2 L` further steps. -/
theorem poolK_insert_prod_pow_le {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (x : ι → M) (I : Finset ι) (T : Set M) (hT : subsetProds x I ⊆ T) :
    ∀ (L : ℕ) (e : ι → ℕ), (∀ i ∈ I, e i < 2 ^ L) → (∃ i ∈ I, e i ≠ 0) →
      poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (∏ i ∈ I, x i ^ e i) T) ≤
        poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((2 * L : ℕ) : ℕ∞) := by
  classical
  intro L
  induction L with
  | zero =>
    rintro e he ⟨i, hi, hne⟩
    have := he i hi
    omega
  | succ L ih =>
    intro e he hne
    have hsplit : (∏ i ∈ I, x i ^ e i) =
        (∏ i ∈ I, x i ^ (e i / 2)) * (∏ i ∈ I, x i ^ (e i / 2)) *
          ∏ i ∈ I.filter (fun i => e i % 2 = 1), x i := by
      rw [Finset.prod_filter, ← Finset.prod_mul_distrib, ← Finset.prod_mul_distrib]
      refine Finset.prod_congr rfl fun i _ => ?_
      rcases Nat.mod_two_eq_zero_or_one (e i) with h | h
      · have h' : ¬e i % 2 = 1 := by omega
        simp only [h', ite_false, mul_one]
        rw [← pow_add]
        congr 1
        omega
      · simp only [h, ite_true]
        rw [← pow_add, ← pow_succ]
        congr 1
        omega
    by_cases hhalf : ∃ i ∈ I, e i / 2 ≠ 0
    · have ih' := ih (fun i => e i / 2)
        (fun i hi => by
          have := he i hi
          rw [pow_succ] at this
          omega) hhalf
      generalize (∏ i ∈ I, x i ^ (e i / 2)) = q at hsplit ih'
      have h1 : poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (q * q) (insert q T)) ≤
          poolK (binAlg gen (· * ·)) (fun _ => 1) (insert q T) + 1 :=
        poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1) (insert q T) none
          ![q, q] (fun b => by fin_cases b <;> simp)
      by_cases hodd : (I.filter fun i => e i % 2 = 1).Nonempty
      · have hy : ∏ i ∈ I.filter (fun i => e i % 2 = 1), x i ∈ T :=
          hT ⟨_, Finset.filter_subset _ _, hodd, rfl⟩
        generalize (∏ i ∈ I.filter (fun i => e i % 2 = 1), x i) = y at hsplit hy
        have h2 : poolK (binAlg gen (· * ·)) (fun _ => 1)
            (insert (q * q * y) (insert (q * q) (insert q T))) ≤
            poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (q * q) (insert q T)) + 1 :=
          poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1)
            (insert (q * q) (insert q T)) none ![q * q, y]
            (fun b => by fin_cases b <;> simp [hy])
        have hsub : insert (∏ i ∈ I, x i ^ e i) T ⊆
            insert (q * q * y) (insert (q * q) (insert q T)) := by
          rw [hsplit]
          exact Set.insert_subset_insert fun z hz => by simp [hz]
        calc poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (∏ i ∈ I, x i ^ e i) T)
            ≤ _ := poolK_mono hsub
          _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((2 * L : ℕ) : ℕ∞) + 1 + 1 :=
              h2.trans (add_le_add (h1.trans (add_le_add ih' le_rfl)) le_rfl)
          _ = poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((2 * (L + 1) : ℕ) : ℕ∞) := by
              push_cast
              ring
      · rw [Finset.not_nonempty_iff_eq_empty] at hodd
        rw [hodd, Finset.prod_empty, mul_one] at hsplit
        have hsub : insert (∏ i ∈ I, x i ^ e i) T ⊆ insert (q * q) (insert q T) := by
          rw [hsplit]
          exact Set.insert_subset_insert (Set.subset_insert _ _)
        calc poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (∏ i ∈ I, x i ^ e i) T)
            ≤ _ := poolK_mono hsub
          _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((2 * L : ℕ) : ℕ∞) + 1 :=
              h1.trans (add_le_add ih' le_rfl)
          _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((2 * L : ℕ) : ℕ∞) + 1 + 1 :=
              le_self_add
          _ = poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((2 * (L + 1) : ℕ) : ℕ∞) := by
              push_cast
              ring
    · push Not at hhalf
      have hq : ∏ i ∈ I, x i ^ (e i / 2) = 1 :=
        Finset.prod_eq_one fun i hi => by rw [hhalf i hi, pow_zero]
      obtain ⟨i, hi, hne⟩ := hne
      have hodd : (I.filter fun i => e i % 2 = 1).Nonempty :=
        ⟨i, Finset.mem_filter.2 ⟨hi, by have := hhalf i hi; omega⟩⟩
      have hmem : ∏ i ∈ I, x i ^ e i ∈ T := by
        rw [hsplit, hq, one_mul, one_mul]
        exact hT ⟨_, Finset.filter_subset _ _, hodd, rfl⟩
      rw [Set.insert_eq_of_mem hmem]
      exact le_self_add

private theorem poolK_union_image_le {ι : Type*} {M : Type*} [CommMonoid M] [DecidableEq ι]
    (gen : ι → M) (a : ι) (Q : Set M) (ha : gen a ∈ Q) (𝒮 : Finset (Finset ι)) :
    (∀ s ∈ 𝒮, a ∉ s ∧ ∏ i ∈ s, gen i ∈ Q) →
    poolK (binAlg gen (· * ·)) (fun _ => 1)
        (Q ∪ (fun s => ∏ i ∈ insert a s, gen i) '' (𝒮 : Set (Finset ι))) ≤
      poolK (binAlg gen (· * ·)) (fun _ => 1) Q + (𝒮.card : ℕ∞) := by
  induction 𝒮 using Finset.induction_on with
  | empty => intro _; simp
  | insert s 𝒮 hs ih =>
    intro h𝒮
    have hs' := h𝒮 s (Finset.mem_insert_self s 𝒮)
    have ih' := ih fun s' hs'' => h𝒮 s' (Finset.mem_insert_of_mem hs'')
    rw [Finset.coe_insert, Set.image_insert_eq, Set.union_insert, Finset.card_insert_of_notMem hs]
    have hprod : ∏ i ∈ insert a s, gen i = gen a * ∏ i ∈ s, gen i := Finset.prod_insert hs'.1
    simp only [hprod]
    have h1 : poolK (binAlg gen (· * ·)) (fun _ => 1)
        (insert (gen a * ∏ i ∈ s, gen i)
          (Q ∪ (fun s => ∏ i ∈ insert a s, gen i) '' (𝒮 : Set (Finset ι)))) ≤
        poolK (binAlg gen (· * ·)) (fun _ => 1)
          (Q ∪ (fun s => ∏ i ∈ insert a s, gen i) '' (𝒮 : Set (Finset ι))) + 1 :=
      poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1) _ none
        ![gen a, ∏ i ∈ s, gen i] (fun b => by
          fin_cases b
          · exact Or.inl ha
          · exact Or.inl hs'.2)
    calc _ ≤ _ := h1
      _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) Q + (𝒮.card : ℕ∞) + 1 :=
          add_le_add ih' le_rfl
      _ = poolK (binAlg gen (· * ·)) (fun _ => 1) Q + ((𝒮.card + 1 : ℕ) : ℕ∞) := by
          push_cast
          ring

/-- **The table.** The products of all nonempty sets of generators from `I` cost at most
`2 ^ |I| - 1` steps together: one step per set. -/
theorem poolK_subsetProds_le {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (I : Finset ι) :
    poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I) + 1 ≤
      ((2 ^ I.card : ℕ) : ℕ∞) := by
  classical
  induction I using Finset.induction_on with
  | empty =>
    have h : subsetProds gen (∅ : Finset ι) = ∅ :=
      Set.eq_empty_iff_forall_notMem.2 fun y ⟨s, hs, hne, _⟩ =>
        hne.ne_empty (Finset.subset_empty.1 hs)
    rw [h, poolK_empty]
    simp
  | insert a I ha ih =>
    have hsub : subsetProds gen (insert a I) ⊆ (subsetProds gen I ∪ {gen a}) ∪
        (fun s => ∏ i ∈ insert a s, gen i) '' ((I.powerset.erase ∅ : Finset (Finset ι)) :
          Set (Finset ι)) := by
      rintro y ⟨s, hs, hne, rfl⟩
      by_cases has : a ∈ s
      · by_cases hs' : s.erase a = ∅
        · rcases (Finset.erase_eq_empty_iff s a).1 hs' with h | h
          · exact absurd h hne.ne_empty
          · left; right
            rw [h, Finset.prod_singleton]
            rfl
        · right
          refine ⟨s.erase a, ?_, by simp only [Finset.insert_erase has]⟩
          exact Finset.mem_coe.2 (Finset.mem_erase.2
            ⟨hs', Finset.mem_powerset.2 (Finset.subset_insert_iff.1 hs)⟩)
      · left; left
        exact ⟨s, (Finset.subset_insert_iff_of_notMem has).1 hs, hne, rfl⟩
    have hQ : poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I ∪ {gen a}) ≤
        poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I) + 1 :=
      (poolK_union_le _ _).trans (add_le_add le_rfl (slK_gen_le gen a))
    have himg := poolK_union_image_le gen a (subsetProds gen I ∪ {gen a}) (Or.inr rfl)
      (I.powerset.erase ∅) fun s hs => by
        obtain ⟨hne, hsI⟩ := Finset.mem_erase.1 hs
        have hsI' := Finset.mem_powerset.1 hsI
        exact ⟨fun h => ha (hsI' h),
          Or.inl ⟨s, hsI', Finset.nonempty_iff_ne_empty.2 hne, rfl⟩⟩
    have hcard : (I.powerset.erase ∅).card = 2 ^ I.card - 1 := by
      rw [Finset.card_erase_of_mem (Finset.empty_mem_powerset I), Finset.card_powerset]
    have hN : 1 ≤ 2 ^ I.card := Nat.one_le_two_pow
    rw [Finset.card_insert_of_notMem ha]
    calc poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen (insert a I)) + 1
        ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I) + 1 +
            ((2 ^ I.card - 1 : ℕ) : ℕ∞) + 1 := by
          rw [← hcard]
          exact add_le_add ((poolK_mono hsub).trans (himg.trans (add_le_add hQ le_rfl))) le_rfl
      _ = (poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I) + 1) +
            ((2 ^ I.card - 1 + 1 : ℕ) : ℕ∞) := by
          push_cast
          ring
      _ ≤ ((2 ^ I.card : ℕ) : ℕ∞) + ((2 ^ I.card - 1 + 1 : ℕ) : ℕ∞) := add_le_add ih le_rfl
      _ = ((2 ^ (I.card + 1) : ℕ) : ℕ∞) := by
          rw [← Nat.cast_add]
          congr 1
          rw [pow_succ]
          omega

/-- **Straus's method, one group.** A product of powers of the generators in `I`, with
exponents below `2 ^ L`, costs fewer than `2 ^ |I| + 2 L` steps: the squarings are shared
by all the atoms. -/
theorem slK_prod_pow_add_one_le {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (I : Finset ι) (L : ℕ) (e : ι → ℕ) (he : ∀ i ∈ I, e i < 2 ^ L) (hne : ∃ i ∈ I, e i ≠ 0) :
    slK gen (∏ i ∈ I, gen i ^ e i) + 1 ≤ ((2 ^ I.card + 2 * L : ℕ) : ℕ∞) := by
  have h1 := poolK_insert_prod_pow_le gen gen I (subsetProds gen I) subset_rfl L e he hne
  have h2 := poolK_subsetProds_le gen I
  calc slK gen (∏ i ∈ I, gen i ^ e i) + 1
      ≤ poolK (binAlg gen (· * ·)) (fun _ => 1)
          (insert (∏ i ∈ I, gen i ^ e i) (subsetProds gen I)) + 1 :=
        add_le_add (poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))) le_rfl
    _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I) +
          ((2 * L : ℕ) : ℕ∞) + 1 := add_le_add h1 le_rfl
    _ = (poolK (binAlg gen (· * ·)) (fun _ => 1) (subsetProds gen I) + 1) +
          ((2 * L : ℕ) : ℕ∞) := by ring
    _ ≤ ((2 ^ I.card : ℕ) : ℕ∞) + ((2 * L : ℕ) : ℕ∞) := add_le_add h2 le_rfl
    _ = ((2 ^ I.card + 2 * L : ℕ) : ℕ∞) := by push_cast; rfl

/-- **Straus's method, in groups of `g` atoms.** A product of powers of `n` generators,
with exponents from `1` to below `2 ^ L`, costs fewer than `(n / g + 1) (2 ^ g + 2 L)`
steps. -/
theorem slK_prod_pow_add_one_le_grouped {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (L g : ℕ) (hg : 1 ≤ g) (e : ι → ℕ) :
    ∀ (n : ℕ) (s : Finset ι), s.card = n → s.Nonempty →
      (∀ i ∈ s, 1 ≤ e i ∧ e i < 2 ^ L) →
      slK gen (∏ i ∈ s, gen i ^ e i) + 1 ≤ (((n / g + 1) * (2 ^ g + 2 * L) : ℕ) : ℕ∞) := by
  classical
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
    intro s hs hne he
    have hgroup : ∀ t : Finset ι, t ⊆ s → t.Nonempty → t.card ≤ g →
        slK gen (∏ i ∈ t, gen i ^ e i) + 1 ≤ ((2 ^ g + 2 * L : ℕ) : ℕ∞) := by
      intro t hts htne htc
      obtain ⟨i, hi⟩ := htne
      refine (slK_prod_pow_add_one_le gen t L e (fun j hj => (he j (hts hj)).2)
        ⟨i, hi, by have := (he i (hts hi)).1; omega⟩).trans ?_
      have : 2 ^ t.card ≤ 2 ^ g := Nat.pow_le_pow_right (by norm_num) htc
      exact_mod_cast Nat.add_le_add_right this _
    rcases le_or_gt n g with hle | hgt
    · refine (hgroup s subset_rfl hne (hs ▸ hle)).trans ?_
      exact_mod_cast Nat.le_mul_of_pos_left _ (Nat.succ_pos _)
    · obtain ⟨t, hts, htc⟩ := Finset.exists_subset_card_eq (s := s) (n := g) (by omega)
      have htne : t.Nonempty := Finset.card_pos.1 (by omega)
      have hcard : (s \ t).card = n - g := by
        rw [Finset.card_sdiff_of_subset hts, hs, htc]
      have h1 := ih (n - g) (by omega) (s \ t) hcard
        (Finset.card_pos.1 (by omega)) fun i hi => he i (Finset.mem_sdiff.1 hi).1
      have h2 := hgroup t hts htne htc.le
      have hdiv : n / g = (n - g) / g + 1 := by
        conv_lhs => rw [← Nat.sub_add_cancel hgt.le]
        exact Nat.add_div_right _ hg
      rw [← Finset.prod_sdiff hts]
      calc slK gen ((∏ i ∈ s \ t, gen i ^ e i) * ∏ i ∈ t, gen i ^ e i) + 1
          ≤ slK gen (∏ i ∈ s \ t, gen i ^ e i) + slK gen (∏ i ∈ t, gen i ^ e i) + 1 + 1 :=
            add_le_add (slK_mul_le gen _ _) le_rfl
        _ = (slK gen (∏ i ∈ s \ t, gen i ^ e i) + 1) +
              (slK gen (∏ i ∈ t, gen i ^ e i) + 1) := by ring
        _ ≤ ((((n - g) / g + 1) * (2 ^ g + 2 * L) : ℕ) : ℕ∞) +
              ((2 ^ g + 2 * L : ℕ) : ℕ∞) := add_le_add h1 h2
        _ = (((n / g + 1) * (2 ^ g + 2 * L) : ℕ) : ℕ∞) := by
            rw [hdiv, ← Nat.cast_add]
            congr 1
            ring

end MonoidGen

/-- **Some monomial is hard.** Among the monomials in `k` atoms with exponents from `1` to
`m` there is one that needs more than `n` steps, whenever `n · ((k+1) n²)ⁿ < mᵏ`. Such `n`
grow like `k log m / log (k log m)`: more than both the support bound `k` and the growth
bound `log m`.

Every exponent of the witness is at least `1`, so when `k > 0` the witness can be built and
its cost is finite (`Monomial.slK_add_one_le`). For `k = 0` the hypothesis forces `n = 0`. An earlier version allowed the exponent `0`; the empty
monomial cannot be built from the atoms at all, so it satisfied that statement trivially. -/
theorem Monomial.exists_slK_gt (k m n : ℕ) (h : n * ((k + 1) * n ^ 2) ^ n < m ^ k) :
    ∃ e : Fin k → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ m) ∧
      (n : ℕ∞) < MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) := by
  classical
  let A : Finset (Multiplicative (Fin k → ℕ)) :=
    (Fintype.piFinset fun _ : Fin k => Finset.Icc 1 m).image Multiplicative.ofAdd
  have hA : A.card = m ^ k := by
    rw [Finset.card_image_of_injective _ Multiplicative.ofAdd.injective, Fintype.card_piFinset]
    simp
  obtain ⟨x, hx, hK⟩ := Binary.exists_binK_gt
    (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) (· * ·) n A
    (by rw [hA, Fintype.card_fin]; exact h)
  obtain ⟨e, he, rfl⟩ := Finset.mem_image.1 hx
  exact ⟨e, fun i => Finset.mem_Icc.1 (Fintype.mem_piFinset.1 he i), hK⟩

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

/-- **Straus's method for monomials.** In the free commutative monoid on `k` atoms, a
monomial with exponents from `1` to below `2 ^ L` costs fewer than
`(k / g + 1) (2 ^ g + 2 L)` steps, for every group size `g ≥ 1`. -/
theorem Monomial.slK_add_one_le_grouped {k : ℕ} (hk : 0 < k) (L g : ℕ) (hg : 1 ≤ g)
    (e : Fin k → ℕ) (he : ∀ i, 1 ≤ e i ∧ e i < 2 ^ L) :
    MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤ (((k / g + 1) * (2 ^ g + 2 * L) : ℕ) : ℕ∞) := by
  have hprod : ∏ i, (Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) ^ e i
      = Multiplicative.ofAdd e := by
    simp_rw [← ofAdd_nsmul]
    rw [← ofAdd_sum]
    congr 1
    funext j
    simp [Finset.sum_apply, Pi.single_apply]
  rw [← hprod]
  exact MonoidGen.slK_prod_pow_add_one_le_grouped _ L g hg e k Finset.univ (by simp)
    (Finset.univ_nonempty_iff.2 ⟨⟨0, hk⟩⟩) fun i _ => he i

/-- **Every monomial costs at most `3 L (k / log₂ L + 1)`**, where the exponents lie
between `1` and `2 ^ L`. With `Monomial.exists_slK_gt`, which needs about
`k L / log (k L)` steps for some monomial, this fixes the order of the worst case whenever
`log₂ L ≤ k ≤ L`. -/
theorem Monomial.slK_add_one_le_log {k : ℕ} (hk : 0 < k) (L : ℕ) (hL : 2 ≤ L)
    (e : Fin k → ℕ) (he : ∀ i, 1 ≤ e i ∧ e i < 2 ^ L) :
    MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤ (((k / Nat.log 2 L + 1) * (3 * L) : ℕ) : ℕ∞) := by
  have hg : 1 ≤ Nat.log 2 L := Nat.log_pos (by norm_num) hL
  have hpow : 2 ^ Nat.log 2 L ≤ L := Nat.pow_log_le_self 2 (by omega)
  refine (Monomial.slK_add_one_le_grouped hk L (Nat.log 2 L) hg e he).trans ?_
  exact_mod_cast Nat.mul_le_mul_left _ (by omega)

private theorem refute_pow (a j : ℕ) (h : a + (j + 1 + 2 * a) * 2 ^ a < 2 ^ j * 2 ^ j) :
    2 ^ a * ((2 ^ j + 1) * (2 ^ a) ^ 2) ^ 2 ^ a < (2 ^ 2 ^ j) ^ 2 ^ j := by
  have hk1 : 2 ^ j + 1 ≤ 2 ^ (j + 1) := by
    have := Nat.one_le_two_pow (n := j)
    rw [pow_succ]; omega
  have e : 2 ^ a * (2 ^ (j + 1) * (2 ^ a) ^ 2) ^ 2 ^ a = 2 ^ (a + (j + 1 + 2 * a) * 2 ^ a) := by
    have e2 : 2 ^ (2 * a) = (2 ^ a) ^ 2 := by rw [← pow_mul, mul_comm]
    rw [pow_add 2 a, pow_mul, pow_add 2 (j + 1), e2]
  calc 2 ^ a * ((2 ^ j + 1) * (2 ^ a) ^ 2) ^ 2 ^ a
      ≤ 2 ^ a * (2 ^ (j + 1) * (2 ^ a) ^ 2) ^ 2 ^ a := by gcongr
    _ = 2 ^ (a + (j + 1 + 2 * a) * 2 ^ a) := e
    _ < 2 ^ (2 ^ j * 2 ^ j) := Nat.pow_lt_pow_right (by norm_num) h
    _ = _ := by rw [pow_mul]

private theorem refute_arith (C : ℕ) :
    2 ^ (3 * C + 13) * ((2 ^ (2 * C + 12) + 1) * (2 ^ (3 * C + 13)) ^ 2) ^ 2 ^ (3 * C + 13)
      < (2 ^ 2 ^ (2 * C + 12)) ^ 2 ^ (2 * C + 12) := by
  apply refute_pow
  have hC : C < 2 ^ C := Nat.lt_two_pow_self
  have haa : 3 * C + 13 < 2 ^ (3 * C + 13) := Nat.lt_two_pow_self
  have e1 : 2 ^ (2 * C + 12) * 2 ^ (2 * C + 12) = 2 ^ (C + 11) * 2 ^ (3 * C + 13) := by
    rw [← pow_add, ← pow_add]; congr 1; omega
  have e2 : (8 * C + 40) * 2 ^ (3 * C + 13) < 2 ^ (C + 11) * 2 ^ (3 * C + 13) := by
    apply Nat.mul_lt_mul_of_pos_right _ (by positivity)
    have : 2 ^ (C + 11) = 2048 * 2 ^ C := by rw [pow_add]; ring
    omega
  have e3 : 2 * C + 12 + 1 + 2 * (3 * C + 13) = 8 * C + 39 := by omega
  rw [e1, e3]
  calc 3 * C + 13 + (8 * C + 39) * 2 ^ (3 * C + 13)
      ≤ 2 ^ (3 * C + 13) + (8 * C + 39) * 2 ^ (3 * C + 13) := by omega
    _ = (8 * C + 40) * 2 ^ (3 * C + 13) := by ring
    _ < _ := e2

/-- **The sharing cost of monomials is not `O(#atoms + log (max multiplicity))`.** For every
constant `C` there is a monomial, with at least one atom and every exponent at least `1`,
whose cost with sharing exceeds `C` times the number of its atoms plus the binary logarithm
of its largest exponent. So the support bound and the growth bound, each attained on its
own, are not attained together.

The condition `0 < k` matters: with no atoms the cost is `⊤` and the statement would be
trivially true. A second version of this theorem required every exponent to be at least
`1` and still allowed `k = 0`; an independent review caught that. -/
theorem Monomial.exists_slK_gt_mul (C : ℕ) :
    ∃ (k : ℕ) (e : Fin k → ℕ), 0 < k ∧ (∀ i, 1 ≤ e i) ∧
      ((C * ((Finset.univ.filter fun i => e i ≠ 0).card + Nat.log 2 (Finset.univ.sup e)) : ℕ) : ℕ∞)
        < MonoidGen.slK
          (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
          (Multiplicative.ofAdd e) := by
  obtain ⟨e, he, hK⟩ := Monomial.exists_slK_gt (2 ^ (2 * C + 12)) (2 ^ 2 ^ (2 * C + 12))
    (2 ^ (3 * C + 13)) (refute_arith C)
  refine ⟨_, e, by positivity, fun i => (he i).1, lt_of_le_of_lt ?_ hK⟩
  have h1 : (Finset.univ.filter fun i => e i ≠ 0).card ≤ 2 ^ (2 * C + 12) := by
    simpa using Finset.card_filter_le (Finset.univ : Finset (Fin (2 ^ (2 * C + 12)))) fun i => e i ≠ 0
  have h2 : Nat.log 2 (Finset.univ.sup e) ≤ 2 ^ (2 * C + 12) := by
    calc Nat.log 2 (Finset.univ.sup e) ≤ Nat.log 2 (2 ^ 2 ^ (2 * C + 12)) :=
          Nat.log_mono_right (Finset.sup_le fun i _ => (he i).2)
      _ = _ := Nat.log_pow (by norm_num) _
  have hC : C ≤ 2 ^ C := Nat.lt_two_pow_self.le
  have h3 : C * ((Finset.univ.filter fun i => e i ≠ 0).card + Nat.log 2 (Finset.univ.sup e))
      ≤ 2 ^ (3 * C + 13) := by
    calc _ ≤ 2 ^ C * (2 ^ (2 * C + 12) + 2 ^ (2 * C + 12)) := by gcongr
      _ = 2 ^ (3 * C + 13) := by rw [← two_mul, ← pow_succ', ← pow_add]; congr 1; omega
  exact_mod_cast h3

/-- **The worst case, from both sides.** With `k = 2 ^ j` atoms and exponents from `1` to
`2 ^ k`, some monomial needs more than `2 ^ a` steps whenever
`a + (j + 1 + 2 a) 2 ^ a < 4 ^ j`, and the same monomial, like every other, costs fewer
than `(k / j + 1) (3 k + 2)` steps by Straus's method with groups of `j` atoms. The first
is about `k² / (10 log₂ k)` and the second about `3 k² / log₂ k`. -/
theorem Monomial.exists_slK_between (j a : ℕ) (hj : 1 ≤ j)
    (h : a + (j + 1 + 2 * a) * 2 ^ a < 2 ^ j * 2 ^ j) :
    ∃ e : Fin (2 ^ j) → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ 2 ^ j) ∧
      ((2 ^ a : ℕ) : ℕ∞) < MonoidGen.slK
        (fun i : Fin (2 ^ j) => Multiplicative.ofAdd (Pi.single i 1 : Fin (2 ^ j) → ℕ))
        (Multiplicative.ofAdd e) ∧
      MonoidGen.slK
        (fun i : Fin (2 ^ j) => Multiplicative.ofAdd (Pi.single i 1 : Fin (2 ^ j) → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤ (((2 ^ j / j + 1) * (3 * 2 ^ j + 2) : ℕ) : ℕ∞) := by
  obtain ⟨e, he, hK⟩ := Monomial.exists_slK_gt (2 ^ j) (2 ^ 2 ^ j) (2 ^ a) (refute_pow a j h)
  refine ⟨e, he, hK, ?_⟩
  have hup := Monomial.slK_add_one_le_grouped (k := 2 ^ j) (by positivity) (2 ^ j + 1) j hj e
    fun i => ⟨(he i).1, lt_of_le_of_lt (he i).2
      (Nat.pow_lt_pow_right (by norm_num) (Nat.lt_succ_self _))⟩
  refine hup.trans (le_of_eq ?_)
  congr 1
  ring

/-- The instance `j = 10`: among the monomials in `1024` atoms with exponents from `1` to
`2 ^ 1024`, one needs more than `16384` steps, and it costs fewer than `316622`. The binary
method alone allows about two million steps. -/
theorem Monomial.exists_slK_between_1024 :
    ∃ e : Fin (2 ^ 10) → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ 2 ^ 10) ∧
      ((2 ^ 14 : ℕ) : ℕ∞) < MonoidGen.slK
        (fun i : Fin (2 ^ 10) => Multiplicative.ofAdd (Pi.single i 1 : Fin (2 ^ 10) → ℕ))
        (Multiplicative.ofAdd e) ∧
      MonoidGen.slK
        (fun i : Fin (2 ^ 10) => Multiplicative.ofAdd (Pi.single i 1 : Fin (2 ^ 10) → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤ ((316622 : ℕ) : ℕ∞) := by
  obtain ⟨e, he, hlo, hup⟩ := Monomial.exists_slK_between 10 14 (by norm_num) (by norm_num)
  exact ⟨e, he, hlo, hup.trans (le_of_eq (by norm_num))⟩

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

/-! ### The shared table: Shannon's upper bound

The normal form (`circuitK_le`) costs about `4 n 2ⁿ` steps and shares almost nothing.
Shannon's construction shares a table: build every function of `k` chosen variables once,
then select among table entries with the other `n - k` variables, four gates per
selection. The table has `2 ^ 2 ^ k` entries and there are fewer than `2 ^ (n - k)`
selections, so with `k` about `log₂ n` the cost is of order `2ⁿ / n`, the order of the
counting lower bound (`exists_hard_function`). -/

open Binary Sig

/-- `f` depends only on the variables in `V`. -/
def DependsOn {n : ℕ} (f : BoolFn n) (V : Finset (Fin n)) : Prop :=
  ∀ w w' : Fin n → Bool, (∀ i ∈ V, w i = w' i) → f w = f w'

/-- A disjunction of partial minterms on the variables `J`, one for each pattern in `S`. -/
theorem circuitK_pattern_le {n : ℕ} (hn : 0 < n) (J : Finset (Fin n))
    (S : Finset (Fin n → Bool)) :
    circuitK (fun w : Fin n → Bool => decide (∃ v ∈ S, ∀ i ∈ J, w i = v i)) ≤
      ((5 + S.card * (4 * J.card + 7) : ℕ) : ℕ∞) := by
  induction S using Finset.induction_on with
  | empty =>
    have h : (fun w : Fin n → Bool =>
        decide (∃ v ∈ (∅ : Finset (Fin n → Bool)), ∀ i ∈ J, w i = v i)) = fun _ => false := by
      funext w
      simp
    rw [h]
    simpa using circuitK_false_le hn
  | insert v S hv ih =>
    have h : (fun w : Fin n → Bool => decide (∃ v' ∈ insert v S, ∀ i ∈ J, w i = v' i)) =
        fun w => decide (∀ i ∈ J, w i = v i) || decide (∃ v' ∈ S, ∀ i ∈ J, w i = v' i) := by
      funext w
      simp
    rw [h, Finset.card_insert_of_notMem hv]
    have e : (S.card + 1) * (4 * J.card + 7) = S.card * (4 * J.card + 7) + (4 * J.card + 7) := by
      ring
    exact (circuitK_or_le (circuitK_minterm_le hn v J) ih).trans (Nat.cast_le.2 (by omega))

/-- Extend an assignment of the variables in `V` by `false` elsewhere. -/
def extend {n : ℕ} (V : Finset (Fin n)) (u : V → Bool) : Fin n → Bool :=
  fun i => if h : i ∈ V then u ⟨i, h⟩ else false

theorem extend_restrict {n : ℕ} (V : Finset (Fin n)) (w : Fin n → Bool) :
    ∀ i ∈ V, extend V (fun i : V => w i) i = w i := fun i hi => by simp [extend, hi]

/-- **A function of few variables has a small circuit**: `5 + 2 ^ |V| (4 |V| + 7)` steps
if it depends only on the variables in `V`. -/
theorem circuitK_le_of_dependsOn {n : ℕ} (hn : 0 < n) {f : BoolFn n} {V : Finset (Fin n)}
    (hf : DependsOn f V) :
    circuitK f ≤ ((5 + 2 ^ V.card * (4 * V.card + 7) : ℕ) : ℕ∞) := by
  have hS : (((Finset.univ : Finset (V → Bool)).image (extend V)).filter
      fun v => f v = true).card ≤ 2 ^ V.card := by
    refine (Finset.card_filter_le _ _).trans (Finset.card_image_le.trans ?_)
    simp
  have h : f = fun w => decide (∃ v ∈ ((Finset.univ : Finset (V → Bool)).image
      (extend V)).filter (fun v => f v = true), ∀ i ∈ V, w i = v i) := by
    funext w
    by_cases hw : f w = true
    · have hex : ∃ v ∈ ((Finset.univ : Finset (V → Bool)).image (extend V)).filter
          (fun v => f v = true), ∀ i ∈ V, w i = v i :=
        ⟨extend V (fun i : V => w i), Finset.mem_filter.2
          ⟨Finset.mem_image_of_mem _ (Finset.mem_univ _),
            (hf _ w (extend_restrict V w)).trans hw⟩,
          fun i hi => (extend_restrict V w i hi).symm⟩
      rw [hw]
      exact (decide_eq_true hex).symm
    · have hw' : f w = false := by simpa using hw
      have hnex : ¬∃ v ∈ ((Finset.univ : Finset (V → Bool)).image (extend V)).filter
          (fun v => f v = true), ∀ i ∈ V, w i = v i := by
        rintro ⟨v, hv, hag⟩
        exact hw ((hf w v hag).trans (Finset.mem_filter.1 hv).2)
      rw [hw']
      exact (decide_eq_false hnex).symm
  rw [congrArg circuitK h]
  exact (circuitK_pattern_le hn V _).trans
    (Nat.cast_le.2 (Nat.add_le_add_left (Nat.mul_le_mul_right _ hS) _))

/-- **The table.** All the functions that depend only on the variables in `V` can be built
together in at most `2 ^ 2 ^ |V|` times the cost of one. -/
theorem poolK_dependsOn_le {n : ℕ} (hn : 0 < n) (V : Finset (Fin n)) :
    poolK (binAlg (proj n) nand) (fun _ => 1) {f | DependsOn f V} ≤
      ((2 ^ 2 ^ V.card * (5 + 2 ^ V.card * (4 * V.card + 7)) : ℕ) : ℕ∞) := by
  have hdep : ∀ g : (V → Bool) → Bool,
      DependsOn (fun w : Fin n → Bool => g fun i : V => w i) V := fun g w w' h => by
    have e : (fun i : V => w i) = fun i : V => w' i := funext fun i => h i i.2
    show g _ = g _
    rw [e]
  have hsub : {f : BoolFn n | DependsOn f V} ⊆
      ⋃ g ∈ (Finset.univ : Finset ((V → Bool) → Bool)),
        {(fun w : Fin n → Bool => g fun i : V => w i)} := by
    intro f hf
    refine Set.mem_iUnion₂.2 ⟨fun u => f (extend V u), Finset.mem_univ _, ?_⟩
    rw [Set.mem_singleton_iff]
    funext w
    exact (hf _ w (extend_restrict V w)).symm
  have hsum : ∑ g ∈ (Finset.univ : Finset ((V → Bool) → Bool)),
      dagK (binAlg (proj n) nand) (fun _ => 1) (fun w : Fin n → Bool => g fun i : V => w i) ≤
      (Finset.univ : Finset ((V → Bool) → Bool)).card •
        ((5 + 2 ^ V.card * (4 * V.card + 7) : ℕ) : ℕ∞) :=
    Finset.sum_le_card_nsmul _ _ _ fun g _ => circuitK_le_of_dependsOn hn (hdep g)
  have hcard : (Finset.univ : Finset ((V → Bool) → Bool)).card = 2 ^ 2 ^ V.card := by
    simp
  calc poolK (binAlg (proj n) nand) (fun _ => 1) {f | DependsOn f V}
      ≤ _ := poolK_mono hsub
    _ ≤ _ := poolK_le_sum_dagK _ _
    _ ≤ _ := hsum
    _ = ((2 ^ 2 ^ V.card * (5 + 2 ^ V.card * (4 * V.card + 7)) : ℕ) : ℕ∞) := by
        rw [hcard, nsmul_eq_mul]
        push_cast
        rfl

/-- **Selection costs four gates.** Over a pool that contains the inputs and every function
of the variables in `V`, a function of the variables in `V ∪ J` costs at most
`4 (2 ^ |J| - 1)` further steps. -/
theorem poolK_insert_select_le {n : ℕ} (V : Finset (Fin n)) :
    ∀ (J : Finset (Fin n)) (T : Set (BoolFn n)), (∀ i, proj n i ∈ T) →
      {f | DependsOn f V} ⊆ T → ∀ f : BoolFn n, DependsOn f (V ∪ J) →
      poolK (binAlg (proj n) nand) (fun _ => 1) (insert f T) ≤
        poolK (binAlg (proj n) nand) (fun _ => 1) T + ((4 * (2 ^ J.card - 1) : ℕ) : ℕ∞) := by
  intro J
  induction J using Finset.induction_on with
  | empty =>
    intro T _ hT f hf
    rw [Finset.union_empty] at hf
    rw [Set.insert_eq_of_mem (hT hf)]
    simp
  | insert j J hj ih =>
    intro T hproj hT f hf
    have hdep : ∀ b : Bool, DependsOn (fun w => f (Function.update w j b)) (V ∪ J) := by
      intro b w w' h
      refine hf _ _ fun i hi => ?_
      by_cases hij : i = j
      · subst hij
        simp
      · rw [Function.update_of_ne hij, Function.update_of_ne hij]
        refine h i ?_
        rcases Finset.mem_union.1 hi with h1 | h2
        · exact Finset.mem_union_left _ h1
        · exact Finset.mem_union_right _ ((Finset.mem_insert.1 h2).resolve_left hij)
    generalize hf1 : (fun w => f (Function.update w j true) : BoolFn n) = f1 at *
    generalize hf0 : (fun w => f (Function.update w j false) : BoolFn n) = f0 at *
    have hd1 : DependsOn f1 (V ∪ J) := hf1 ▸ hdep true
    have hd0 : DependsOn f0 (V ∪ J) := hf0 ▸ hdep false
    have hfeq : f = nand (nand (proj n j) f1) (nand (nand (proj n j) (proj n j)) f0) := by
      funext w
      rw [← hf1, ← hf0]
      rcases Bool.eq_false_or_eq_true (w j) with h | h
      · have e : Function.update w j true = w := by
          rw [← h]
          exact Function.update_eq_self j w
        simp [nand, proj, h, e]
      · have e : Function.update w j false = w := by
          rw [← h]
          exact Function.update_eq_self j w
        simp [nand, proj, h, e]
    have h1 := ih T hproj hT f1 hd1
    have h0 := ih (insert f1 T) (fun i => Set.mem_insert_of_mem _ (hproj i))
      (hT.trans (Set.subset_insert _ _)) f0 hd0
    have hx : proj n j ∈ T := hproj j
    have g1 : poolK (binAlg (proj n) nand) (fun _ => 1)
        (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T))) ≤
        poolK (binAlg (proj n) nand) (fun _ => 1) (insert f0 (insert f1 T)) + 1 :=
      poolK_insert_alg_le (alg := binAlg (proj n) nand) (wt := fun _ => 1) _ none
        ![proj n j, proj n j] (fun b => by fin_cases b <;> simp [hx])
    have g2 : poolK (binAlg (proj n) nand) (fun _ => 1)
        (insert (nand (proj n j) f1)
          (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T)))) ≤
        poolK (binAlg (proj n) nand) (fun _ => 1)
          (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T))) + 1 :=
      poolK_insert_alg_le (alg := binAlg (proj n) nand) (wt := fun _ => 1) _ none
        ![proj n j, f1] (fun b => by fin_cases b <;> simp [hx])
    have g3 : poolK (binAlg (proj n) nand) (fun _ => 1)
        (insert (nand (nand (proj n j) (proj n j)) f0)
          (insert (nand (proj n j) f1)
            (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T))))) ≤
        poolK (binAlg (proj n) nand) (fun _ => 1)
          (insert (nand (proj n j) f1)
            (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T)))) + 1 :=
      poolK_insert_alg_le (alg := binAlg (proj n) nand) (wt := fun _ => 1) _ none
        ![nand (proj n j) (proj n j), f0] (fun b => by fin_cases b <;> simp)
    have g4 : poolK (binAlg (proj n) nand) (fun _ => 1)
        (insert (nand (nand (proj n j) f1) (nand (nand (proj n j) (proj n j)) f0))
          (insert (nand (nand (proj n j) (proj n j)) f0)
            (insert (nand (proj n j) f1)
              (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T)))))) ≤
        poolK (binAlg (proj n) nand) (fun _ => 1)
          (insert (nand (nand (proj n j) (proj n j)) f0)
            (insert (nand (proj n j) f1)
              (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T))))) + 1 :=
      poolK_insert_alg_le (alg := binAlg (proj n) nand) (wt := fun _ => 1) _ none
        ![nand (proj n j) f1, nand (nand (proj n j) (proj n j)) f0]
        (fun b => by fin_cases b <;> simp)
    have hsub : insert f T ⊆
        insert (nand (nand (proj n j) f1) (nand (nand (proj n j) (proj n j)) f0))
          (insert (nand (nand (proj n j) (proj n j)) f0)
            (insert (nand (proj n j) f1)
              (insert (nand (proj n j) (proj n j)) (insert f0 (insert f1 T))))) := by
      rw [← hfeq]
      exact Set.insert_subset_insert fun z hz => by simp [hz]
    have hN : 1 ≤ 2 ^ J.card := Nat.one_le_two_pow
    rw [Finset.card_insert_of_notMem hj]
    calc poolK (binAlg (proj n) nand) (fun _ => 1) (insert f T)
        ≤ _ := poolK_mono hsub
      _ ≤ poolK (binAlg (proj n) nand) (fun _ => 1) T + ((4 * (2 ^ J.card - 1) : ℕ) : ℕ∞) +
            ((4 * (2 ^ J.card - 1) : ℕ) : ℕ∞) + 1 + 1 + 1 + 1 :=
          g4.trans (add_le_add (g3.trans (add_le_add (g2.trans (add_le_add (g1.trans
            (add_le_add (h0.trans (add_le_add h1 le_rfl)) le_rfl)) le_rfl)) le_rfl)) le_rfl)
      _ = poolK (binAlg (proj n) nand) (fun _ => 1) T +
            ((4 * (2 ^ J.card - 1) + 4 * (2 ^ J.card - 1) + 4 : ℕ) : ℕ∞) := by
          push_cast
          ring
      _ = poolK (binAlg (proj n) nand) (fun _ => 1) T +
            ((4 * (2 ^ (J.card + 1) - 1) : ℕ) : ℕ∞) := by
          congr 2
          rw [pow_succ]
          omega

/-- **Shannon's upper bound.** For any set `V` of variables, every Boolean function of
`n ≥ 1` variables costs at most the inputs, the table of all functions of `V`, and four
gates for each selection on the other variables. -/
theorem circuitK_le_table {n : ℕ} (hn : 0 < n) (V : Finset (Fin n)) (f : BoolFn n) :
    circuitK f ≤ ((n + 2 ^ 2 ^ V.card * (5 + 2 ^ V.card * (4 * V.card + 7)) +
      4 * (2 ^ (n - V.card) - 1) : ℕ) : ℕ∞) := by
  have hproj : poolK (binAlg (proj n) nand) (fun _ => 1)
      (⋃ i ∈ (Finset.univ : Finset (Fin n)), {proj n i}) ≤ (n : ℕ∞) := by
    refine (poolK_le_sum_dagK _ _).trans ?_
    refine (Finset.sum_le_card_nsmul _ _ 1 fun i _ => circuitK_proj_le n i).trans ?_
    simp
  have hT : poolK (binAlg (proj n) nand) (fun _ => 1)
      ((⋃ i ∈ (Finset.univ : Finset (Fin n)), {proj n i}) ∪ {f | DependsOn f V}) ≤
      (n : ℕ∞) + ((2 ^ 2 ^ V.card * (5 + 2 ^ V.card * (4 * V.card + 7)) : ℕ) : ℕ∞) :=
    (poolK_union_le _ _).trans (add_le_add hproj (poolK_dependsOn_le hn V))
  have hsel := poolK_insert_select_le V Vᶜ
    ((⋃ i ∈ (Finset.univ : Finset (Fin n)), {proj n i}) ∪ {f | DependsOn f V})
    (fun i => Or.inl (Set.mem_iUnion₂.2 ⟨i, Finset.mem_univ i, rfl⟩))
    Set.subset_union_right f
    (fun w w' h => by
      have e : w = w' := funext fun i => h i (by simp)
      rw [e])
  have hcard : (Vᶜ : Finset (Fin n)).card = n - V.card := by
    rw [Finset.card_compl, Fintype.card_fin]
  rw [hcard] at hsel
  calc circuitK f
      ≤ poolK (binAlg (proj n) nand) (fun _ => 1)
          (insert f ((⋃ i ∈ (Finset.univ : Finset (Fin n)), {proj n i}) ∪
            {f | DependsOn f V})) :=
        poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))
    _ ≤ _ := hsel
    _ ≤ (n : ℕ∞) + ((2 ^ 2 ^ V.card * (5 + 2 ^ V.card * (4 * V.card + 7)) : ℕ) : ℕ∞) +
          ((4 * (2 ^ (n - V.card) - 1) : ℕ) : ℕ∞) := add_le_add hT le_rfl
    _ = _ := by push_cast; rfl

/-- Shannon's upper bound with a table on `k` variables:
`n + 2 ^ 2 ^ k (5 + 2 ^ k (4 k + 7)) + 4 · 2 ^ (n - k)`. -/
theorem circuitK_le_shannon {n : ℕ} (hn : 0 < n) (k : ℕ) (hk : k ≤ n) (f : BoolFn n) :
    circuitK f ≤ ((n + 2 ^ 2 ^ k * (5 + 2 ^ k * (4 * k + 7)) + 4 * 2 ^ (n - k) : ℕ) : ℕ∞) := by
  obtain ⟨V, -, hV⟩ := Finset.exists_subset_card_eq
    (s := (Finset.univ : Finset (Fin n))) (n := k) (by simpa using hk)
  have h := circuitK_le_table hn V f
  rw [hV] at h
  exact h.trans (Nat.cast_le.2 (by omega))

private theorem count_pow (a b m N : ℕ) (hm : m ≤ 2 ^ b) (h : a + (b + 2 * a) * 2 ^ a < N) :
    2 ^ a * (m * (2 ^ a) ^ 2) ^ 2 ^ a < 2 ^ N := by
  have e : 2 ^ a * (2 ^ b * (2 ^ a) ^ 2) ^ 2 ^ a = 2 ^ (a + (b + 2 * a) * 2 ^ a) := by
    have e2 : 2 ^ (2 * a) = (2 ^ a) ^ 2 := by rw [← pow_mul, mul_comm]
    rw [pow_add 2 a, pow_mul, pow_add 2 b, e2]
  calc 2 ^ a * (m * (2 ^ a) ^ 2) ^ 2 ^ a
      ≤ 2 ^ a * (2 ^ b * (2 ^ a) ^ 2) ^ 2 ^ a := by gcongr
    _ = 2 ^ (a + (b + 2 * a) * 2 ^ a) := e
    _ < 2 ^ N := Nat.pow_lt_pow_right (by norm_num) h

/-- **The hardest function, from both sides.** If `n + 1 ≤ 2 ^ b` and
`a + (b + 2 a) 2 ^ a < 2 ^ n`, some function of `n` variables needs more than `2 ^ a`
steps, and it costs at most Shannon's bound for every table size `k ≤ n`. With `k` about
`log₂ n - 1` the first is about `2ⁿ / (4 n)` and the second about `8 · 2ⁿ / n`. -/
theorem exists_circuitK_between (n k a b : ℕ) (hn : 0 < n) (hk : k ≤ n) (hb : n + 1 ≤ 2 ^ b)
    (h : a + (b + 2 * a) * 2 ^ a < 2 ^ n) :
    ∃ f : BoolFn n, ((2 ^ a : ℕ) : ℕ∞) < circuitK f ∧
      circuitK f ≤
        ((n + 2 ^ 2 ^ k * (5 + 2 ^ k * (4 * k + 7)) + 4 * 2 ^ (n - k) : ℕ) : ℕ∞) := by
  obtain ⟨f, hf⟩ := exists_hard_function n (2 ^ a) (count_pow a b (n + 1) (2 ^ n) hb h)
  exact ⟨f, hf, circuitK_le_shannon hn k hk f⟩

/-- The instance `n = 32`, with a table on four variables: some function of 32 variables
needs more than `2 ^ 26` (about 67 million) steps, and none needs more than
`1,098,186,784`. The normal form allows about 580 billion. -/
theorem exists_circuitK_between_32 :
    ∃ f : BoolFn 32, ((2 ^ 26 : ℕ) : ℕ∞) < circuitK f ∧
      circuitK f ≤ ((1098186784 : ℕ) : ℕ∞) := by
  obtain ⟨f, hlo, hup⟩ := exists_circuitK_between 32 4 26 6 (by norm_num) (by norm_num)
    (by norm_num) (by norm_num)
  exact ⟨f, hlo, hup.trans (le_of_eq (by norm_num))⟩

end Circuit

/-! ### Strings: a table of blocks

The same construction once more. Build every nonempty binary string of length at most `g`,
then cut the target into blocks of length `g` and concatenate them, one step per block.
With `g` about `½ log₂ L` every string of length `L` costs about `2 L / log₂ L` steps,
the order of the counting bound `Str.exists_low_gain`. -/

namespace Str

open Binary Sig

/-- The table: all nonempty binary strings of length at most `g` cost at most
`g · 2 ^ g · 2 g` steps together. -/
theorem poolK_blocks_le (g : ℕ) :
    poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1)
        (⋃ j ∈ Finset.Icc 1 g, ⋃ v ∈ (Finset.univ : Finset (List.Vector Bool j)),
          {FreeMonoid.ofList v.1}) ≤ ((g * (2 ^ g * (2 * g)) : ℕ) : ℕ∞) := by
  have hone : ∀ j ∈ Finset.Icc 1 g, ∀ v : List.Vector Bool j,
      dagK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1)
        (FreeMonoid.ofList v.1) ≤ ((2 * g : ℕ) : ℕ∞) := by
    intro j hj v
    have hj' := Finset.mem_Icc.1 hj
    have hne : FreeMonoid.ofList v.1 ≠ (1 : FreeMonoid Bool) := by
      intro h
      have hlen := congrArg (fun w : FreeMonoid Bool => w.toList.length) h
      simp at hlen
      omega
    have ht := Str.treeK_eq hne
    have hle : Binary.binK (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)
        (FreeMonoid.ofList v.1) ≤ 2 * ((FreeMonoid.ofList v.1).toList.length : ℕ∞) :=
      (Binary.binK_le_binTreeK _ _ _).trans (le_self_add.trans ht.le)
    refine hle.trans ?_
    have hlen : (FreeMonoid.ofList v.1).toList.length = j := by simp
    rw [hlen]
    exact_mod_cast Nat.mul_le_mul_left 2 hj'.2
  have hinner : ∀ j ∈ Finset.Icc 1 g,
      poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1)
        (⋃ v ∈ (Finset.univ : Finset (List.Vector Bool j)), {FreeMonoid.ofList v.1}) ≤
      ((2 ^ g * (2 * g) : ℕ) : ℕ∞) := by
    intro j hj
    have hj' := Finset.mem_Icc.1 hj
    refine (poolK_le_sum_dagK _ _).trans ?_
    refine (Finset.sum_le_card_nsmul _ _ _ fun v _ => hone j hj v).trans ?_
    rw [Finset.card_univ, card_vector, Fintype.card_bool, nsmul_eq_mul]
    have hp : 2 ^ j ≤ 2 ^ g := Nat.pow_le_pow_right (by norm_num) hj'.2
    exact_mod_cast Nat.mul_le_mul_right _ hp
  refine (poolK_biUnion_le _ _).trans ?_
  refine (Finset.sum_le_card_nsmul _ _ _ hinner).trans ?_
  rw [Nat.card_Icc, nsmul_eq_mul]
  simp

/-- **One step per block.** Over a pool that contains every nonempty string of length at
most `g`, a string of length `L` costs at most `L / g` further steps. -/
theorem poolK_insert_le_div (g : ℕ) (hg : 1 ≤ g) (T : Set (FreeMonoid Bool))
    (hT : ∀ l : List Bool, l ≠ [] → l.length ≤ g → FreeMonoid.ofList l ∈ T) :
    ∀ (L : ℕ) (l : List Bool), l.length = L → l ≠ [] →
      poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1)
          (insert (FreeMonoid.ofList l) T) ≤
        poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1) T +
          ((L / g : ℕ) : ℕ∞) := by
  intro L
  induction L using Nat.strong_induction_on with
  | _ L ih =>
    intro l hl hne
    rcases le_or_gt L g with hle | hgt
    · rw [Set.insert_eq_of_mem (hT l hne (hl ▸ hle))]
      exact le_self_add
    · have hdrop : (l.drop g).length = L - g := by rw [List.length_drop, hl]
      have htake : (l.take g).length = g := by
        rw [List.length_take, hl]
        omega
      have hdne : l.drop g ≠ [] := fun h => by
        rw [h] at hdrop
        simp at hdrop
        omega
      have htne : l.take g ≠ [] := fun h => by
        rw [h] at htake
        simp at htake
        omega
      have hmem : FreeMonoid.ofList (l.take g) ∈ T := hT _ htne htake.le
      have ih' := ih (L - g) (by omega) (l.drop g) hdrop hdne
      have hsplit : FreeMonoid.ofList l =
          FreeMonoid.ofList (l.take g) * FreeMonoid.ofList (l.drop g) := by
        rw [← FreeMonoid.ofList_append, List.take_append_drop]
      have hstep : poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·))
          (fun _ => 1)
          (insert (FreeMonoid.ofList (l.take g) * FreeMonoid.ofList (l.drop g))
            (insert (FreeMonoid.ofList (l.drop g)) T)) ≤
          poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1)
            (insert (FreeMonoid.ofList (l.drop g)) T) + 1 :=
        poolK_insert_alg_le (alg := binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·))
          (wt := fun _ => 1) _ none
          ![FreeMonoid.ofList (l.take g), FreeMonoid.ofList (l.drop g)]
          (fun b => by fin_cases b <;> simp [hmem])
      have hdiv : L / g = (L - g) / g + 1 := by
        conv_lhs => rw [← Nat.sub_add_cancel hgt.le]
        exact Nat.add_div_right _ hg
      have hsub : insert (FreeMonoid.ofList l) T ⊆
          insert (FreeMonoid.ofList (l.take g) * FreeMonoid.ofList (l.drop g))
            (insert (FreeMonoid.ofList (l.drop g)) T) := by
        rw [hsplit]
        exact Set.insert_subset_insert (Set.subset_insert _ _)
      calc poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1)
            (insert (FreeMonoid.ofList l) T)
          ≤ _ := poolK_mono hsub
        _ ≤ poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1) T +
              (((L - g) / g : ℕ) : ℕ∞) + 1 := hstep.trans (add_le_add ih' le_rfl)
        _ = poolK (binAlg (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)) (fun _ => 1) T +
              ((L / g : ℕ) : ℕ∞) := by
            rw [hdiv]
            push_cast
            ring

/-- **Every binary string costs at most `g · 2 ^ g · 2 g + L / g` steps**, for every block
length `g ≥ 1`: a table of blocks, then one concatenation per block. -/
theorem strK_le_blocks (g : ℕ) (hg : 1 ≤ g) (l : List Bool) (hl : l ≠ []) :
    Str.strK (FreeMonoid.ofList l) ≤
      ((g * (2 ^ g * (2 * g)) + l.length / g : ℕ) : ℕ∞) := by
  have hT : ∀ l' : List Bool, l' ≠ [] → l'.length ≤ g →
      FreeMonoid.ofList l' ∈ (⋃ j ∈ Finset.Icc 1 g,
        ⋃ v ∈ (Finset.univ : Finset (List.Vector Bool j)),
          ({FreeMonoid.ofList v.1} : Set (FreeMonoid Bool))) := by
    intro l' hne hlen
    refine Set.mem_iUnion₂.2 ⟨l'.length, Finset.mem_Icc.2 ⟨?_, hlen⟩, ?_⟩
    · exact List.length_pos_iff.2 hne
    · exact Set.mem_iUnion₂.2 ⟨⟨l', rfl⟩, Finset.mem_univ _, rfl⟩
  have h := poolK_insert_le_div g hg _ hT l.length l rfl hl
  calc Str.strK (FreeMonoid.ofList l)
      ≤ _ := poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))
    _ ≤ _ := h
    _ ≤ ((g * (2 ^ g * (2 * g)) : ℕ) : ℕ∞) + ((l.length / g : ℕ) : ℕ∞) :=
        add_le_add (poolK_blocks_le g) le_rfl
    _ = _ := by push_cast; rfl

/-- **The hardest string, from both sides.** If `a + (2 + 2 a) 2 ^ a < L`, some binary
string of length `L` needs more than `2 ^ a` steps, and it costs at most
`g · 2 ^ g · 2 g + L / g` for every block length `g`. With `g` about `½ log₂ L` the first
is about `L / (4 log₂ L)` and the second about `2 L / log₂ L`. -/
theorem exists_strK_between (L g a : ℕ) (hg : 1 ≤ g) (hL : 1 ≤ L)
    (h : a + (2 + 2 * a) * 2 ^ a < L) :
    ∃ w : FreeMonoid Bool, w.toList.length = L ∧ ((2 ^ a : ℕ) : ℕ∞) < Str.strK w ∧
      Str.strK w ≤ ((g * (2 ^ g * (2 * g)) + L / g : ℕ) : ℕ∞) := by
  obtain ⟨w, hw, hK⟩ := Str.exists_low_gain L (2 ^ a)
    (Circuit.count_pow a 2 3 L (by norm_num) h)
  refine ⟨w, hw, hK, ?_⟩
  have hne : w.toList ≠ [] := fun e => by
    rw [e] at hw
    simp at hw
    omega
  have hb := strK_le_blocks g hg w.toList hne
  rw [hw] at hb
  simpa using hb

/-- The instance `L = 2 ^ 20`, with blocks of eight letters: some binary string of about a
million letters needs more than `16384` steps, and none needs more than `163840`. Without
sharing each needs about two million. -/
theorem exists_strK_between_million :
    ∃ w : FreeMonoid Bool, w.toList.length = 2 ^ 20 ∧ ((2 ^ 14 : ℕ) : ℕ∞) < Str.strK w ∧
      Str.strK w ≤ ((163840 : ℕ) : ℕ∞) := by
  obtain ⟨w, hw, hlo, hup⟩ := exists_strK_between (2 ^ 20) 8 14 (by norm_num) (by norm_num)
    (by norm_num)
  exact ⟨w, hw, hlo, hup.trans (le_of_eq (by norm_num))⟩

end Str

/-! ### The counting bound is not always attained

In the three populations above the hardest object costs what counting says. That is not a
general law. In the free semilattice the support bound binds instead. -/

/-- **Counting is not always what binds.** In the free semilattice on `k` atoms the full set
costs `2k - 1` steps (`SetUnion.binK_add_one_eq`), while the counting law
(`Binary.exists_binK_gt`) applied to the `2 ^ k - 1` nonempty sets only yields an object
needing more than `n` steps for `n` with `n · ((k+1) n²)ⁿ < 2 ^ k - 1`, and every such `n`
is below `k / log₂ (k + 1)`. So for every constant `C`, from some `k₀` on, the hardest
object costs more than `C` times anything counting can show.

The statement is for all `k ≥ k₀`. An earlier version said "for some `k`", which `k = 1`
satisfies trivially because then no `n ≥ 1` meets the counting hypothesis. -/
theorem SetUnion.counting_not_tight (C : ℕ) :
    ∃ k₀ : ℕ, ∀ k : ℕ, k₀ ≤ k → ∀ n : ℕ, n * ((k + 1) * n ^ 2) ^ n < 2 ^ k - 1 →
      ((C * n : ℕ) : ℕ∞) <
        Binary.binK (fun a : Fin k => ({a} : Finset (Fin k))) (· ∪ ·) Finset.univ := by
  refine ⟨2 ^ C, fun k hk n hn => ?_⟩
  have hk0 : 0 < k := lt_of_lt_of_le (by positivity) hk
  have : Nonempty (Fin k) := ⟨⟨0, hk0⟩⟩
  have hcost := (SetUnion.binK_add_one_eq (α := Fin k)
    (s := Finset.univ) Finset.univ_nonempty).1
  rw [Finset.card_univ, Fintype.card_fin] at hcost
  have hCn : C * n + 1 ≤ k := by
    rcases Nat.eq_zero_or_pos n with rfl | hpos
    · omega
    · have h1 : (k + 1) ^ n ≤ ((k + 1) * n ^ 2) ^ n :=
        Nat.pow_le_pow_left (Nat.le_mul_of_pos_right _ (by positivity)) n
      have h2 : ((k + 1) * n ^ 2) ^ n ≤ n * ((k + 1) * n ^ 2) ^ n :=
        Nat.le_mul_of_pos_left _ hpos
      have h3 : (2 ^ C) ^ n ≤ (k + 1) ^ n := Nat.pow_le_pow_left (by omega) n
      have h4 : 2 ^ (C * n) < 2 ^ k := by
        rw [pow_mul]
        omega
      have := (Nat.pow_lt_pow_iff_right (by norm_num : 1 < 2)).1 h4
      omega
  refine lt_of_not_ge fun hle => ?_
  have h := add_le_add hle (le_refl (1 : ℕ∞))
  rw [hcost] at h
  have h' : 2 * k ≤ C * n + 1 := by exact_mod_cast h
  omega

/-- The counting hypothesis of `SetUnion.counting_not_tight` is not empty: for `k ≥ 5` it
holds with `n = 1`. -/
theorem SetUnion.counting_hypothesis_one (k : ℕ) (hk : 5 ≤ k) :
    1 * ((k + 1) * 1 ^ 2) ^ 1 < 2 ^ k - 1 := by
  have h : k + 3 ≤ 2 ^ k := by
    induction k, hk using Nat.le_induction with
    | base => norm_num
    | succ k _ ih =>
      rw [pow_succ]
      omega
  simp only [one_pow, mul_one, pow_one, one_mul]
  omega

/-! ### Blocks in any monoid

The table of blocks does not need the free monoid. In any monoid, a product of `L`
generators can be cut into blocks of `g` factors, and the products of all blocks of at most
`g` factors form a table. So where size is additive, sharing always saves a factor of
order `log L`: without sharing the cost is exactly `2 L - 1` (`binTreeK_add_one_eq`). -/

namespace MonoidGen

open Binary Sig

/-- A product of `j ≥ 1` generators costs at most `2 j - 1` steps. -/
theorem slK_list_prod_add_one_le {ι : Type*} {M : Type*} [Monoid M] (gen : ι → M) :
    ∀ l : List ι, l ≠ [] → slK gen (l.map gen).prod + 1 ≤ ((2 * l.length : ℕ) : ℕ∞)
  | [], h => absurd rfl h
  | [a], _ => by
    have h := add_le_add (slK_gen_le gen a) (le_refl (1 : ℕ∞))
    simpa [one_add_one_eq_two] using h
  | a :: b :: t, _ => by
    have ih := slK_list_prod_add_one_le gen (b :: t) (by simp)
    have h1 : slK gen (gen a) + 1 ≤ 2 := by
      have h := add_le_add (slK_gen_le gen a) (le_refl (1 : ℕ∞))
      rwa [one_add_one_eq_two] at h
    rw [List.map_cons, List.prod_cons]
    calc slK gen (gen a * ((b :: t).map gen).prod) + 1
        ≤ slK gen (gen a) + slK gen ((b :: t).map gen).prod + 1 + 1 :=
          add_le_add (slK_mul_le gen _ _) le_rfl
      _ = (slK gen (gen a) + 1) + (slK gen ((b :: t).map gen).prod + 1) := by ring
      _ ≤ 2 + ((2 * (b :: t).length : ℕ) : ℕ∞) := add_le_add h1 ih
      _ = ((2 * (a :: b :: t).length : ℕ) : ℕ∞) := by
          simp only [List.length_cons]
          push_cast
          ring

/-- The table: the products of all blocks of at most `g` generators cost at most
`g · σ ^ g · 2 g` steps together, where `σ` is the number of generators. -/
theorem poolK_prod_blocks_le {ι : Type*} {M : Type*} [Fintype ι] [Monoid M] (gen : ι → M)
    (g : ℕ) :
    poolK (binAlg gen (· * ·)) (fun _ => 1)
        (⋃ j ∈ Finset.Icc 1 g, ⋃ v ∈ (Finset.univ : Finset (List.Vector ι j)),
          {(v.1.map gen).prod}) ≤ ((g * (Fintype.card ι ^ g * (2 * g)) : ℕ) : ℕ∞) := by
  have hone : ∀ j ∈ Finset.Icc 1 g, ∀ v : List.Vector ι j,
      dagK (binAlg gen (· * ·)) (fun _ => 1) ((v.1.map gen).prod) ≤ ((2 * g : ℕ) : ℕ∞) := by
    intro j hj v
    have hj' := Finset.mem_Icc.1 hj
    have hne : v.1 ≠ [] := fun h => by
      have := v.2
      rw [h] at this
      simp at this
      omega
    have h := slK_list_prod_add_one_le gen v.1 hne
    rw [v.2] at h
    exact (le_self_add.trans h).trans (by exact_mod_cast Nat.mul_le_mul_left 2 hj'.2)
  have hinner : ∀ j ∈ Finset.Icc 1 g,
      poolK (binAlg gen (· * ·)) (fun _ => 1)
        (⋃ v ∈ (Finset.univ : Finset (List.Vector ι j)), {(v.1.map gen).prod}) ≤
      ((Fintype.card ι ^ g * (2 * g) : ℕ) : ℕ∞) := by
    intro j hj
    have hj' := Finset.mem_Icc.1 hj
    refine (poolK_le_sum_dagK _ _).trans ?_
    refine (Finset.sum_le_card_nsmul _ _ _ fun v _ => hone j hj v).trans ?_
    rw [Finset.card_univ, card_vector, nsmul_eq_mul]
    have hp : Fintype.card ι ^ j ≤ Fintype.card ι ^ g := by
      rcases Nat.eq_zero_or_pos (Fintype.card ι) with h0 | hpos
      · rw [h0, zero_pow (by omega)]
        exact Nat.zero_le _
      · exact Nat.pow_le_pow_right hpos hj'.2
    exact_mod_cast Nat.mul_le_mul_right _ hp
  refine (poolK_biUnion_le _ _).trans ?_
  refine (Finset.sum_le_card_nsmul _ _ _ hinner).trans ?_
  rw [Nat.card_Icc, nsmul_eq_mul]
  simp

/-- One step per block, over a pool that contains the product of every block of at most `g`
generators. -/
theorem poolK_insert_prod_le_div {ι : Type*} {M : Type*} [Monoid M] (gen : ι → M) (g : ℕ)
    (hg : 1 ≤ g) (T : Set M)
    (hT : ∀ l : List ι, l ≠ [] → l.length ≤ g → (l.map gen).prod ∈ T) :
    ∀ (L : ℕ) (l : List ι), l.length = L → l ≠ [] →
      poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (l.map gen).prod T) ≤
        poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((L / g : ℕ) : ℕ∞) := by
  intro L
  induction L using Nat.strong_induction_on with
  | _ L ih =>
    intro l hl hne
    rcases le_or_gt L g with hle | hgt
    · rw [Set.insert_eq_of_mem (hT l hne (hl ▸ hle))]
      exact le_self_add
    · have hdrop : (l.drop g).length = L - g := by rw [List.length_drop, hl]
      have htake : (l.take g).length = g := by
        rw [List.length_take, hl]
        omega
      have hdne : l.drop g ≠ [] := fun h => by
        rw [h] at hdrop
        simp at hdrop
        omega
      have htne : l.take g ≠ [] := fun h => by
        rw [h] at htake
        simp at htake
        omega
      have hmem : ((l.take g).map gen).prod ∈ T := hT _ htne htake.le
      have ih' := ih (L - g) (by omega) (l.drop g) hdrop hdne
      have hsplit : (l.map gen).prod =
          ((l.take g).map gen).prod * ((l.drop g).map gen).prod := by
        rw [← List.prod_append, ← List.map_append, List.take_append_drop]
      have hstep : poolK (binAlg gen (· * ·)) (fun _ => 1)
          (insert (((l.take g).map gen).prod * ((l.drop g).map gen).prod)
            (insert ((l.drop g).map gen).prod T)) ≤
          poolK (binAlg gen (· * ·)) (fun _ => 1) (insert ((l.drop g).map gen).prod T) + 1 :=
        poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1) _ none
          ![((l.take g).map gen).prod, ((l.drop g).map gen).prod]
          (fun b => by
            fin_cases b
            · exact Or.inr hmem
            · exact Or.inl rfl)
      have hdiv : L / g = (L - g) / g + 1 := by
        conv_lhs => rw [← Nat.sub_add_cancel hgt.le]
        exact Nat.add_div_right _ hg
      have hsub : insert (l.map gen).prod T ⊆
          insert (((l.take g).map gen).prod * ((l.drop g).map gen).prod)
            (insert ((l.drop g).map gen).prod T) := by
        rw [hsplit]
        exact Set.insert_subset_insert (Set.subset_insert _ _)
      calc poolK (binAlg gen (· * ·)) (fun _ => 1) (insert (l.map gen).prod T)
          ≤ _ := poolK_mono hsub
        _ ≤ poolK (binAlg gen (· * ·)) (fun _ => 1) T + (((L - g) / g : ℕ) : ℕ∞) + 1 :=
            hstep.trans (add_le_add ih' le_rfl)
        _ = poolK (binAlg gen (· * ·)) (fun _ => 1) T + ((L / g : ℕ) : ℕ∞) := by
            rw [hdiv]
            push_cast
            ring

/-- **Sharing always saves a logarithm where size is additive.** In any monoid with `σ`
generators, a product of `L ≥ 1` generators costs at most `g · σ ^ g · 2 g + L / g` steps,
for every block length `g ≥ 1`. With `g` about `½ log_σ L` this is about
`2 L / log_σ L`, against exactly `2 L - 1` without sharing when size is additive. -/
theorem slK_list_prod_le_blocks {ι : Type*} {M : Type*} [Fintype ι] [Monoid M] (gen : ι → M)
    (g : ℕ) (hg : 1 ≤ g) (l : List ι) (hl : l ≠ []) :
    slK gen (l.map gen).prod ≤
      ((g * (Fintype.card ι ^ g * (2 * g)) + l.length / g : ℕ) : ℕ∞) := by
  have hT : ∀ l' : List ι, l' ≠ [] → l'.length ≤ g →
      (l'.map gen).prod ∈ (⋃ j ∈ Finset.Icc 1 g,
        ⋃ v ∈ (Finset.univ : Finset (List.Vector ι j)), ({(v.1.map gen).prod} : Set M)) := by
    intro l' hne hlen
    refine Set.mem_iUnion₂.2 ⟨l'.length, Finset.mem_Icc.2 ⟨?_, hlen⟩, ?_⟩
    · exact List.length_pos_iff.2 hne
    · exact Set.mem_iUnion₂.2 ⟨⟨l', rfl⟩, Finset.mem_univ _, rfl⟩
  have h := poolK_insert_prod_le_div gen g hg _ hT l.length l rfl hl
  calc slK gen (l.map gen).prod
      ≤ _ := poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))
    _ ≤ _ := h
    _ ≤ ((g * (Fintype.card ι ^ g * (2 * g)) : ℕ) : ℕ∞) + ((l.length / g : ℕ) : ℕ∞) :=
        add_le_add (poolK_prod_blocks_le gen g) le_rfl
    _ = _ := by push_cast; rfl

end MonoidGen

/-! ### Depth: the obstruction that growth is a shadow of

The growth bound (`mul_two_le_two_pow`) says that a size which at most doubles per step
needs `log₂` of it steps. That is one instance of a more general bound: any `φ` that grows
by at most one per operation is a lower bound. In a monoid the best such `φ` is
`⌈log₂ size⌉`. Where the operation is not associative it can be much larger: in binary
trees it is the height. -/

namespace Binary

open Sig Quiver

section Depth

variable {ι : Type*} {M : Type*} (gen : ι → M) (op : M → M → M)

private theorem pool_depth (φ : M → ℕ) (hgen : ∀ i, φ (gen i) = 0)
    (hop : ∀ x y, φ (op x y) ≤ max (φ x) (φ y) + 1) :
    ∀ {Q : Pool (binAlg gen op)} (p : Path (⟨∅⟩ : Pool (binAlg gen op)) Q),
      ∀ x ∈ Q.set, φ x + 1 ≤ p.length
  | _, .nil => fun x hx => absurd hx (Set.notMem_empty x)
  | _, .cons p e => by
      intro x hx
      have ih := pool_depth φ hgen hop p
      obtain ⟨o', args, hmem, heq⟩ := e
      rw [heq] at hx
      rw [Path.length_cons]
      rcases hx with rfl | hx
      · rcases o' with _ | i
        · have h0 := ih _ (hmem (0 : Fin 2))
          have h1 := ih _ (hmem (1 : Fin 2))
          have h2 := hop (args (0 : Fin 2)) (args (1 : Fin 2))
          show φ (op (args (0 : Fin 2)) (args (1 : Fin 2))) + 1 ≤ p.length + 1
          omega
        · show φ (gen i) + 1 ≤ p.length + 1
          rw [hgen i]
          omega
      · have := ih x hx
        omega

/-- **The depth bound.** If `φ` is `0` on generators and grows by at most one per
operation, `φ (x ∘ y) ≤ max (φ x) (φ y) + 1`, then anything built in `n` steps, with
sharing, has `φ + 1 ≤ n`. Sharing shortens a construction but never flattens it. -/
theorem depth_add_one_le (φ : M → ℕ) (hgen : ∀ i, φ (gen i) = 0)
    (hop : ∀ x y, φ (op x y) ≤ max (φ x) (φ y) + 1) {x : M} {n : ℕ}
    (h : binK gen op x ≤ n) : φ x + 1 ≤ n := by
  obtain ⟨Q, hx, p, hp⟩ := poolK_le_coe_iff.1 h
  rw [pathCost_poolWeight_one] at hp
  have hlen : p.length ≤ n := by exact_mod_cast hp
  exact (pool_depth gen op φ hgen hop p x (hx rfl)).trans hlen

/-- The depth bound, as an inequality on complexity. -/
theorem depth_add_one_le_binK (φ : M → ℕ) (hgen : ∀ i, φ (gen i) = 0)
    (hop : ∀ x y, φ (op x y) ≤ max (φ x) (φ y) + 1) (x : M) :
    ((φ x + 1 : ℕ) : ℕ∞) ≤ binK gen op x := by
  rcases eq_or_ne (binK gen op x) ⊤ with h | h
  · rw [h]
    exact le_top
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 h
  rw [← hn]
  exact_mod_cast depth_add_one_le gen op φ hgen hop hn.ge

end Depth

end Binary

/-! ### Combs: where depth binds and nothing else does

Binary trees, built from the leaf by "make a node". A comb with `n` nodes has one atom,
`n + 1` leaves and height `n`. Support gives a lower bound of 1, growth gives
`log₂ (n + 1)`, counting over all `catalan n` trees with `n` nodes gives about
`n / log n`, and the true cost is `n + 1`. -/

namespace Comb

open Binary Sig

/-- The right comb with `n` nodes. -/
def comb : ℕ → BinaryTree Unit
  | 0 => .nil
  | n + 1 => .node () .nil (comb n)

@[simp] theorem height_comb (n : ℕ) : (comb n).height = n := by
  induction n with
  | zero => rfl
  | succ n ih => simp [comb, ih]

@[simp] theorem numNodes_comb (n : ℕ) : (comb n).numNodes = n := by
  induction n with
  | zero => rfl
  | succ n ih => simp [comb, ih]

/-- A comb and the leaf together cost at most `n + 1` steps. -/
theorem poolK_comb_le (n : ℕ) :
    poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ()))
      (fun _ => 1) {comb n, BinaryTree.nil} ≤ ((n + 1 : ℕ) : ℕ∞) := by
  induction n with
  | zero =>
    have h : ({comb 0, BinaryTree.nil} : Set (BinaryTree Unit)) = {BinaryTree.nil} := by
      simp [comb]
    rw [h]
    have hg : poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ())) (fun _ => 1) {BinaryTree.nil} ≤ 1 :=
      binK_gen_le (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ()) ()
    simpa using hg
  | succ n ih =>
    have hstep : poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ())) (fun _ => 1)
        (insert (BinaryTree.node () BinaryTree.nil (comb n)) {comb n, BinaryTree.nil}) ≤
        poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
          (BinaryTree.node ())) (fun _ => 1) {comb n, BinaryTree.nil} + 1 :=
      poolK_insert_alg_le (alg := binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ())) (wt := fun _ => 1) _ none ![BinaryTree.nil, comb n]
        (fun b => by
          fin_cases b
          · exact Or.inr rfl
          · exact Or.inl rfl)
    have hsub : ({comb (n + 1), BinaryTree.nil} : Set (BinaryTree Unit)) ⊆
        insert (BinaryTree.node () BinaryTree.nil (comb n)) {comb n, BinaryTree.nil} := by
      rintro y (rfl | rfl)
      · exact Or.inl rfl
      · exact Or.inr (Or.inr rfl)
    calc _ ≤ _ := poolK_mono hsub
      _ ≤ _ := hstep
      _ ≤ ((n + 1 : ℕ) : ℕ∞) + 1 := add_le_add ih le_rfl
      _ = ((n + 1 + 1 : ℕ) : ℕ∞) := by push_cast; rfl

/-- **A comb with `n` nodes costs exactly `n + 1` steps**: the leaf, then one step per
node. The depth bound is attained. -/
theorem binK_comb (n : ℕ) :
    binK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ()) (comb n) =
      ((n + 1 : ℕ) : ℕ∞) := by
  refine le_antisymm ((poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))).trans
    (poolK_comb_le n)) ?_
  have h := depth_add_one_le_binK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
    (BinaryTree.node ()) BinaryTree.height (fun _ => rfl) (fun x y => by simp) (comb n)
  rwa [height_comb] at h

/-- **Counting misses depth.** For every constant `C`, from some `n₀` on, the comb with `n`
nodes costs more than `C` times anything the counting law can show for the population of
all binary trees with `n` nodes. Its support is one atom and its size is `n + 1`, so the
support and growth bounds give `1` and `log₂ (n + 1)`.

The statement is for all `n ≥ n₀`. An earlier version said "for some `n`", which `n = 0`
satisfies trivially. -/
theorem counting_misses_depth (C : ℕ) :
    ∃ n₀ : ℕ, ∀ n : ℕ, n₀ ≤ n →
      ∀ m : ℕ, m * (2 * m ^ 2) ^ m < (BinaryTree.treesOfNumNodesEq n).card →
      ((C * m : ℕ) : ℕ∞) <
        binK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
          (comb n) := by
  refine ⟨C * 2 ^ C, fun n hn m hm => ?_⟩
  rw [binK_comb]
  have hcat : (BinaryTree.treesOfNumNodesEq n).card ≤ 4 ^ n := by
    rw [BinaryTree.treesOfNumNodesEq_card_eq_catalan, catalan_eq_centralBinom_div]
    exact (Nat.div_le_self _ _).trans (Nat.centralBinom_le_four_pow _)
  have hle : C * m ≤ n := by
    rcases lt_or_ge m (2 ^ C) with hlt | hge
    · exact (Nat.mul_le_mul_left C hlt.le).trans hn
    · have hpos : 0 < m := lt_of_lt_of_le (by positivity) hge
      have e : 4 ^ (C * m) = ((2 ^ C) ^ 2) ^ m := by
        rw [← pow_mul, ← pow_mul, show (4 : ℕ) = 2 ^ 2 by norm_num, ← pow_mul]
        congr 1
        ring
      have h1 : ((2 ^ C) ^ 2) ^ m ≤ (2 * m ^ 2) ^ m :=
        Nat.pow_le_pow_left ((Nat.pow_le_pow_left hge 2).trans (Nat.le_mul_of_pos_left _
          (by norm_num))) m
      have h2 : (2 * m ^ 2) ^ m ≤ m * (2 * m ^ 2) ^ m := Nat.le_mul_of_pos_left _ hpos
      have h3 : 4 ^ (C * m) < 4 ^ n := by
        rw [e]
        omega
      exact ((Nat.pow_lt_pow_iff_right (by norm_num : 1 < 4)).1 h3).le
  exact_mod_cast Nat.lt_succ_of_le hle

/-- Without sharing a comb with `n` nodes costs `2 n + 1` steps; with sharing, `n + 1`
(`binK_comb`). Size (the number of leaves) is additive here, and the gain from sharing
stays below `2`: the logarithmic gain of `MonoidGen.slK_list_prod_le_blocks` needs
associativity. -/
theorem binTreeK_comb (n : ℕ) :
    binTreeK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
      (comb n) + 1 = 2 * ((n + 1 : ℕ) : ℕ∞) := by
  have hfin : ∀ n, binTreeK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
      (BinaryTree.node ()) (comb n) ≠ ⊤ := by
    intro n
    induction n with
    | zero => exact binTreeK_gen_ne_top _ _ ()
    | succ n ih => exact binTreeK_op_ne_top _ _ (binTreeK_gen_ne_top _ _ ()) ih
  have h := binTreeK_add_one_eq
    (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
    (fun t => t.numNodes + 1) (fun _ => by simp) (fun x y => by simp; omega) (hfin n)
  simpa using h

end Comb

/-! ### Distinct parts: why no short list of obstructions is complete

In binary trees nothing is ever equal by accident, so the cost with sharing is the number
of distinct subtrees. A tree can be shallow, have one atom, and still have almost as many
distinct subtrees as nodes. So support, depth and counting together do not decide the
cost: there is a fourth quantity, and in an algebra with relations it has no such simple
description. -/

namespace Comb

open Binary Sig Quiver

/-- Cost with sharing of a binary tree, built from the leaf by "make a node". -/
noncomputable abbrev cost (t : BinaryTree Unit) : ℕ∞ :=
  binK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ()) t

/-- All subtrees of a tree. -/
def sub : BinaryTree Unit → Finset (BinaryTree Unit)
  | .nil => {.nil}
  | .node _ l r => insert (.node () l r) (sub l ∪ sub r)

theorem self_mem_sub (t : BinaryTree Unit) : t ∈ sub t := by
  cases t with
  | nil => simp [sub]
  | node v l r => cases v; simp [sub]

private theorem pool_sub :
    ∀ {Q : Pool (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ()))}
      (p : Path (⟨∅⟩ : Pool (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ()))) Q),
      Q.set.Finite ∧ Q.set.ncard ≤ p.length ∧
        ∀ x ∈ Q.set, ((sub x : Finset (BinaryTree Unit)) : Set (BinaryTree Unit)) ⊆ Q.set
  | _, .nil => ⟨Set.finite_empty, by simp, fun x hx => absurd hx (Set.notMem_empty x)⟩
  | _, .cons p e => by
      obtain ⟨hfin, hcard, hcl⟩ := pool_sub p
      obtain ⟨o', args, hmem, heq⟩ := e
      rw [heq, Path.length_cons]
      refine ⟨hfin.insert _, (Set.ncard_insert_le _ _).trans (Nat.succ_le_succ hcard), ?_⟩
      rintro x (rfl | hx)
      · rcases o' with _ | i
        · show ((sub (BinaryTree.node () (args (0 : Fin 2)) (args (1 : Fin 2))) :
            Finset (BinaryTree Unit)) : Set (BinaryTree Unit)) ⊆ _
          intro y hy
          rw [sub, Finset.coe_insert, Finset.coe_union] at hy
          rcases hy with rfl | hy | hy
          · exact Or.inl rfl
          · exact Or.inr (hcl _ (hmem (0 : Fin 2)) hy)
          · exact Or.inr (hcl _ (hmem (1 : Fin 2)) hy)
        · show ((sub BinaryTree.nil : Finset (BinaryTree Unit)) : Set (BinaryTree Unit)) ⊆ _
          intro y hy
          rw [sub, Finset.coe_singleton, Set.mem_singleton_iff] at hy
          exact Or.inl hy
      · exact (hcl x hx).trans (Set.subset_insert _ _)

/-- **Distinct parts.** A binary tree costs at least as many steps as it has distinct
subtrees: a pool that contains a tree contains all its subtrees, and each step adds one
object. -/
theorem card_sub_le_cost (t : BinaryTree Unit) : ((sub t).card : ℕ∞) ≤ cost t := by
  rcases eq_or_ne (cost t) ⊤ with h | h
  · rw [h]
    exact le_top
  obtain ⟨n, hn⟩ := ENat.ne_top_iff_exists.1 h
  rw [← hn]
  obtain ⟨Q, hx, p, hp⟩ := poolK_le_coe_iff.1 hn.ge
  rw [pathCost_poolWeight_one] at hp
  have hlen : p.length ≤ n := by exact_mod_cast hp
  obtain ⟨hfin, hcard, hcl⟩ := pool_sub p
  have hfin' : Q.Finite := hfin
  have hcard' : Q.ncard ≤ p.length := hcard
  have hsub : ((sub t : Finset (BinaryTree Unit)) : Set (BinaryTree Unit)) ⊆ Q :=
    hcl t (hx rfl)
  have h1 : (sub t).card ≤ Q.ncard := by
    rw [← Set.ncard_coe_finset]
    exact Set.ncard_le_ncard hsub hfin'
  exact_mod_cast h1.trans (hcard'.trans hlen)

/-- A decoration: the leaf, or a single node. -/
def dec : Bool → BinaryTree Unit
  | false => .nil
  | true => .node () .nil .nil

/-- A chain that spells a list of bits in its decorations. -/
def cat : List Bool → BinaryTree Unit
  | [] => .nil
  | b :: bs => .node () (dec b) (cat bs)

theorem cat_injective : Function.Injective cat := by
  intro w
  induction w with
  | nil =>
    intro v h
    cases v with
    | nil => rfl
    | cons b bs => simp [cat] at h
  | cons a as ih =>
    intro v h
    cases v with
    | nil => simp [cat] at h
    | cons b bs =>
      simp only [cat, BinaryTree.node.injEq, true_and] at h
      have hab : a = b := by
        cases a <;> cases b <;> simp_all [dec]
      rw [hab, ih h.2]

theorem cat_suffix_mem_sub (w v : List Bool) : cat v ∈ sub (cat (w ++ v)) := by
  induction w with
  | nil => exact self_mem_sub _
  | cons b w ih =>
    rw [List.cons_append, cat, sub]
    exact Finset.mem_insert_of_mem (Finset.mem_union_right _ ih)

theorem numNodes_cat_le (w : List Bool) : (cat w).numNodes ≤ 2 * w.length := by
  induction w with
  | nil => simp [cat]
  | cons b bs ih =>
    have hb : (dec b).numNodes ≤ 1 := by cases b <;> simp [dec]
    simp only [cat, BinaryTree.numNodes, List.length_cons]
    omega

theorem height_cat_le (w : List Bool) : (cat w).height ≤ w.length + 1 := by
  induction w with
  | nil => simp [cat]
  | cons b bs ih =>
    have hb : (dec b).height ≤ 1 := by cases b <;> simp [dec]
    simp only [cat, BinaryTree.height, List.length_cons]
    omega

/-- A bush: a complete binary tree of depth `k` whose leaves are chains. The chain at the
leaf reached by the path `q` spells `d` zeros followed by `q`. -/
def bush (d : ℕ) : ℕ → List Bool → BinaryTree Unit
  | 0, q => cat (List.replicate d false ++ q)
  | k + 1, q => .node () (bush d k (q ++ [false])) (bush d k (q ++ [true]))

theorem mem_sub_bush (d : ℕ) :
    ∀ (k : ℕ) (q r : List Bool), r.length = k → ∀ i ≤ d,
      cat (List.replicate i false ++ (q ++ r)) ∈ sub (bush d k q)
  | 0, q, r, hr, i, hi => by
    have hr' : r = [] := List.length_eq_zero_iff.1 hr
    subst hr'
    rw [List.append_nil, bush]
    have e : List.replicate d false ++ q =
        List.replicate (d - i) false ++ (List.replicate i false ++ q) := by
      rw [← List.append_assoc, ← List.replicate_add, Nat.sub_add_cancel hi]
    rw [e]
    exact cat_suffix_mem_sub _ _
  | k + 1, q, r, hr, i, hi => by
    cases r with
    | nil => simp at hr
    | cons b r' =>
      have hr' : r'.length = k := by simpa using hr
      have e : q ++ b :: r' = (q ++ [b]) ++ r' := by simp
      rw [e, bush, sub]
      refine Finset.mem_insert_of_mem ?_
      cases b
      · exact Finset.mem_union_left _ (mem_sub_bush d k (q ++ [false]) r' hr' i hi)
      · exact Finset.mem_union_right _ (mem_sub_bush d k (q ++ [true]) r' hr' i hi)

theorem numNodes_bush_add_one_le (d : ℕ) :
    ∀ (k : ℕ) (q : List Bool),
      (bush d k q).numNodes + 1 ≤ 2 ^ k * (2 * (d + q.length + k) + 2)
  | 0, q => by
    have h := numNodes_cat_le (List.replicate d false ++ q)
    simp only [List.length_append, List.length_replicate] at h
    simp only [bush, pow_zero, one_mul]
    omega
  | k + 1, q => by
    have h0 := numNodes_bush_add_one_le d k (q ++ [false])
    have h1 := numNodes_bush_add_one_le d k (q ++ [true])
    simp only [List.length_append, List.length_singleton] at h0 h1
    have e : d + (q.length + 1) + k = d + q.length + (k + 1) := by omega
    rw [e] at h0 h1
    simp only [bush, BinaryTree.numNodes]
    have e2 : 2 ^ (k + 1) * (2 * (d + q.length + (k + 1)) + 2) =
        2 * (2 ^ k * (2 * (d + q.length + (k + 1)) + 2)) := by ring
    rw [e2]
    generalize 2 ^ k * (2 * (d + q.length + (k + 1)) + 2) = B at h0 h1 ⊢
    omega

theorem height_bush_le (d : ℕ) :
    ∀ (k : ℕ) (q : List Bool), (bush d k q).height ≤ d + q.length + 2 * k + 1
  | 0, q => by
    have h := height_cat_le (List.replicate d false ++ q)
    simp only [List.length_append, List.length_replicate] at h
    simp only [bush]
    omega
  | k + 1, q => by
    have h0 := height_bush_le d k (q ++ [false])
    have h1 := height_bush_le d k (q ++ [true])
    simp only [List.length_append, List.length_singleton] at h0 h1
    simp only [bush, BinaryTree.height]
    omega

/-- The bush of depth `d` has at least `d · 2 ^ d` distinct subtrees. -/
theorem card_sub_bush (d : ℕ) : d * 2 ^ d ≤ (sub (bush d d [])).card := by
  have hinj : Function.Injective fun x : Fin d × List.Vector Bool d =>
      cat (List.replicate (x.1 : ℕ) false ++ x.2.1) := by
    rintro ⟨i, v⟩ ⟨i', v'⟩ h
    have h' : List.replicate (i : ℕ) false ++ v.1 = List.replicate (i' : ℕ) false ++ v'.1 :=
      cat_injective h
    have hlen := congrArg List.length h'
    simp only [List.length_append, List.length_replicate] at hlen
    have hi : (i : ℕ) = i' := by
      have := v.2
      have := v'.2
      omega
    have hi' : i = i' := Fin.ext hi
    subst hi'
    have hv : v.1 = v'.1 := List.append_cancel_left h'
    rw [Prod.mk.injEq]
    exact ⟨rfl, Subtype.ext hv⟩
  have hsub : (Finset.univ : Finset (Fin d × List.Vector Bool d)).image
      (fun x => cat (List.replicate (x.1 : ℕ) false ++ x.2.1)) ⊆ sub (bush d d []) := by
    intro t ht
    obtain ⟨⟨i, v⟩, -, rfl⟩ := Finset.mem_image.1 ht
    have h := mem_sub_bush d d [] v.1 v.2 i i.2.le
    simpa using h
  have hcard := Finset.card_le_card hsub
  rw [Finset.card_image_of_injective _ hinj, Finset.card_univ, Fintype.card_prod,
    Fintype.card_fin, card_vector, Fintype.card_bool] at hcard
  exact hcard

/-- **Support, depth and counting together do not decide the cost.** For every constant
`C` there is a binary tree, with a single atom, whose cost with sharing exceeds `C` times
its depth bound and `C` times anything the counting law can show for the population of all
trees with as many nodes. What binds is the number of distinct subtrees. -/
theorem obstructions_incomplete (C : ℕ) :
    ∃ t : BinaryTree Unit,
      ((C * (t.height + 1) : ℕ) : ℕ∞) < cost t ∧
      ∀ m : ℕ, m * (2 * m ^ 2) ^ m < (BinaryTree.treesOfNumNodesEq t.numNodes).card →
        ((C * m : ℕ) : ℕ∞) < cost t := by
  -- depth of the bush
  obtain ⟨d, hd⟩ : ∃ d, d = 6 * C + 1 := ⟨_, rfl⟩
  have hd1 : 1 ≤ d := by omega
  have hpow : 6 * C + 1 < 2 ^ d := by
    rw [hd]
    exact Nat.lt_two_pow_self
  have hcost : ((d * 2 ^ d : ℕ) : ℕ∞) ≤ cost (bush d d []) :=
    (by exact_mod_cast card_sub_bush d : ((d * 2 ^ d : ℕ) : ℕ∞) ≤ _).trans
      (card_sub_le_cost _)
  have hN := numNodes_bush_add_one_le d d []
  have hH := height_bush_le d d []
  simp only [List.length_nil, add_zero] at hN hH
  generalize hP : 2 ^ d = P at hpow hcost hN
  refine ⟨bush d d [], lt_of_lt_of_le ?_ hcost, fun m hm => lt_of_lt_of_le ?_ hcost⟩
  · have h1 : C * ((bush d d []).height + 1) ≤ C * (5 * d) :=
      Nat.mul_le_mul_left C (by omega)
    have h2 : C * (5 * d) < d * P := by
      have : C * (5 * d) = d * (5 * C) := by ring
      rw [this]
      exact Nat.mul_lt_mul_of_pos_left (by omega) (by omega)
    exact_mod_cast lt_of_le_of_lt h1 h2
  · have hcat : (BinaryTree.treesOfNumNodesEq (bush d d []).numNodes).card ≤
        4 ^ (bush d d []).numNodes := by
      rw [BinaryTree.treesOfNumNodesEq_card_eq_catalan, catalan_eq_centralBinom_div]
      exact (Nat.div_le_self _ _).trans (Nat.centralBinom_le_four_pow _)
    have hNle : (bush d d []).numNodes < 6 * (d * P) := by
      have e : P * (2 * (d + d) + 2) = 4 * (d * P) + 2 * P := by ring
      rw [e] at hN
      have hP1 : P ≤ d * P := Nat.le_mul_of_pos_left _ (by omega)
      omega
    have key : C * m < d * P := by
      rcases lt_or_ge m (2 ^ (6 * C)) with hlt | hge
      · have h1 : C * m ≤ C * 2 ^ (6 * C) := Nat.mul_le_mul_left C hlt.le
        have h2 : 2 ^ (6 * C) < P := by
          rw [← hP, hd]
          exact Nat.pow_lt_pow_right (by norm_num) (Nat.lt_succ_self _)
        have h3 : C * 2 ^ (6 * C) ≤ d * 2 ^ (6 * C) := Nat.mul_le_mul_right _ (by omega)
        have h4 : d * 2 ^ (6 * C) < d * P := Nat.mul_lt_mul_of_pos_left h2 (by omega)
        omega
      · have hpos : 0 < m := lt_of_lt_of_le (by positivity) hge
        have e : 4 ^ (6 * C * m) = ((2 ^ (6 * C)) ^ 2) ^ m := by
          rw [← pow_mul, ← pow_mul, show (4 : ℕ) = 2 ^ 2 by norm_num, ← pow_mul]
          congr 1
          ring
        have h1 : ((2 ^ (6 * C)) ^ 2) ^ m ≤ (2 * m ^ 2) ^ m :=
          Nat.pow_le_pow_left ((Nat.pow_le_pow_left hge 2).trans
            (Nat.le_mul_of_pos_left _ (by norm_num))) m
        have h2 : (2 * m ^ 2) ^ m ≤ m * (2 * m ^ 2) ^ m := Nat.le_mul_of_pos_left _ hpos
        have h3 : 4 ^ (6 * C * m) < 4 ^ (bush d d []).numNodes := by
          rw [e]
          omega
        have h4 := (Nat.pow_lt_pow_iff_right (by norm_num : 1 < 4)).1 h3
        have h5 : 6 * (C * m) < 6 * (d * P) := by
          have : 6 * (C * m) = 6 * C * m := by ring
          omega
        omega
    exact_mod_cast key

end Comb

/-! ### Monomials: both sides for any number of atoms and any exponent size -/

/-- **The hardest monomial, from both sides, for general parameters.** With `k` atoms and
exponents from `1` to `2 ^ L`: if `k + 1 ≤ 2 ^ b` and `a + (b + 2 a) 2 ^ a < k L`, some
monomial needs more than `2 ^ a` steps, and it costs fewer than
`(k / g + 1) (2 ^ g + 2 (L + 1))` for every group size `g ≥ 1`. The first is at least
about `k L / (6 log₂ (k L))` and, with `g = log₂ L`, the second is about
`3 k L / log₂ L`: the same order whenever `log₂ L ≤ k ≤ L ^ c`, with a constant that
depends on `c`. -/
theorem Monomial.exists_slK_between_general (k L g a b : ℕ) (hk : 0 < k) (hg : 1 ≤ g)
    (hb : k + 1 ≤ 2 ^ b) (h : a + (b + 2 * a) * 2 ^ a < k * L) :
    ∃ e : Fin k → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ L) ∧
      ((2 ^ a : ℕ) : ℕ∞) < MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) ∧
      MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤
          (((k / g + 1) * (2 ^ g + 2 * (L + 1)) : ℕ) : ℕ∞) := by
  have hcount : 2 ^ a * ((k + 1) * (2 ^ a) ^ 2) ^ 2 ^ a < (2 ^ L) ^ k := by
    have e : (2 ^ L) ^ k = 2 ^ (k * L) := by rw [← pow_mul, mul_comm]
    rw [e]
    exact Circuit.count_pow a b (k + 1) (k * L) hb h
  obtain ⟨e, he, hK⟩ := Monomial.exists_slK_gt k (2 ^ L) (2 ^ a) hcount
  refine ⟨e, he, hK, ?_⟩
  exact Monomial.slK_add_one_le_grouped hk (L + 1) g hg e fun i =>
    ⟨(he i).1, lt_of_le_of_lt (he i).2
      (Nat.pow_lt_pow_right (by norm_num) (Nat.lt_succ_self _))⟩

/-- An instance away from the square case: `4096` atoms and exponents up to `2 ^ 1024`. One
monomial needs more than `65536` steps and costs fewer than `1168272`; the binary method
allows about eight million. -/
theorem Monomial.exists_slK_between_4096 :
    ∃ e : Fin 4096 → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ 1024) ∧
      ((2 ^ 16 : ℕ) : ℕ∞) < MonoidGen.slK
        (fun i : Fin 4096 => Multiplicative.ofAdd (Pi.single i 1 : Fin 4096 → ℕ))
        (Multiplicative.ofAdd e) ∧
      MonoidGen.slK
        (fun i : Fin 4096 => Multiplicative.ofAdd (Pi.single i 1 : Fin 4096 → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤ ((1168272 : ℕ) : ℕ∞) := by
  obtain ⟨e, he, hlo, hup⟩ := Monomial.exists_slK_between_general 4096 1024 9 16 13
    (by norm_num) (by norm_num) (by norm_num) (by norm_num)
  exact ⟨e, he, hlo, hup.trans (le_of_eq (by norm_num))⟩

/-! ### In a free algebra the cost is exactly the number of distinct parts -/

namespace Comb

open Binary Sig Quiver

theorem mem_sub_cases {x y : BinaryTree Unit} (h : y ∈ sub x) :
    y = x ∨ y.numNodes < x.numNodes := by
  induction x with
  | nil =>
    rw [sub, Finset.mem_singleton] at h
    exact Or.inl h
  | node v l r ihl ihr =>
    rw [sub, Finset.mem_insert, Finset.mem_union] at h
    rcases h with h | h | h
    · exact Or.inl h
    · rcases ihl h with rfl | hlt
      · exact Or.inr (by simp)
      · exact Or.inr (by simp only [BinaryTree.numNodes]; omega)
    · rcases ihr h with rfl | hlt
      · exact Or.inr (by simp)
      · exact Or.inr (by simp only [BinaryTree.numNodes]; omega)

theorem sub_subset_of_mem {x t : BinaryTree Unit} (h : x ∈ sub t) : sub x ⊆ sub t := by
  induction t with
  | nil =>
    rw [sub, Finset.mem_singleton] at h
    rw [h]
  | node v l r ihl ihr =>
    rw [sub, Finset.mem_insert, Finset.mem_union] at h
    rcases h with h | h | h
    · rw [h]
    · exact (ihl h).trans (by
        rw [sub]
        exact (Finset.subset_union_left).trans (Finset.subset_insert _ _))
    · exact (ihr h).trans (by
        rw [sub]
        exact (Finset.subset_union_right).trans (Finset.subset_insert _ _))

/-- A set of trees closed under taking subtrees can be built in one step per member. -/
theorem poolK_closed_le :
    ∀ (n : ℕ) (S : Finset (BinaryTree Unit)), S.card = n → (∀ x ∈ S, sub x ⊆ S) →
      poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ()))
        (fun _ => 1) (S : Set (BinaryTree Unit)) ≤ (n : ℕ∞)
  | 0, S, hS, _ => by
    rw [Finset.card_eq_zero.1 hS]
    simp
  | n + 1, S, hS, hcl => by
    have hne : S.Nonempty := Finset.card_pos.1 (by omega)
    obtain ⟨t, ht, hmax⟩ := Finset.exists_max_image S BinaryTree.numNodes hne
    have hcard : (S.erase t).card = n := by rw [Finset.card_erase_of_mem ht, hS]; rfl
    have hcl' : ∀ x ∈ S.erase t, sub x ⊆ S.erase t := by
      intro x hx y hy
      have hxS := Finset.mem_of_mem_erase hx
      refine Finset.mem_erase.2 ⟨?_, hcl x hxS hy⟩
      rintro rfl
      rcases mem_sub_cases hy with h | h
      · exact (Finset.mem_erase.1 hx).1 h.symm
      · exact absurd (hmax x hxS) (by omega)
    have ih := poolK_closed_le n (S.erase t) hcard hcl'
    have hins : (S : Set (BinaryTree Unit)) =
        insert t ((S.erase t : Finset (BinaryTree Unit)) : Set (BinaryTree Unit)) := by
      rw [← Finset.coe_insert, Finset.insert_erase ht]
    have hstep : poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ())) (fun _ => 1)
        (insert t ((S.erase t : Finset (BinaryTree Unit)) : Set (BinaryTree Unit))) ≤
        poolK (binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
          (BinaryTree.node ())) (fun _ => 1)
          ((S.erase t : Finset (BinaryTree Unit)) : Set (BinaryTree Unit)) + 1 := by
      cases t with
      | nil =>
        exact poolK_insert_alg_le
          (alg := binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
            (BinaryTree.node ())) (wt := fun _ => 1) _ (some ()) (fun b => b.elim0)
          (fun b => b.elim0)
      | node v l r =>
        cases v
        have hl : l ∈ sub (BinaryTree.node () l r) := by
          rw [sub]
          exact Finset.mem_insert_of_mem (Finset.mem_union_left _ (self_mem_sub l))
        have hr : r ∈ sub (BinaryTree.node () l r) := by
          rw [sub]
          exact Finset.mem_insert_of_mem (Finset.mem_union_right _ (self_mem_sub r))
        have hl' : l ∈ S.erase (BinaryTree.node () l r) :=
          Finset.mem_erase.2 ⟨fun e => by
            have := congrArg BinaryTree.numNodes e
            simp at this
            omega, hcl _ ht hl⟩
        have hr' : r ∈ S.erase (BinaryTree.node () l r) :=
          Finset.mem_erase.2 ⟨fun e => by
            have := congrArg BinaryTree.numNodes e
            simp at this
            omega, hcl _ ht hr⟩
        exact poolK_insert_alg_le
          (alg := binAlg (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
            (BinaryTree.node ())) (wt := fun _ => 1) _ none ![l, r]
          (fun b => by
            fin_cases b
            · exact Finset.mem_coe.2 hl'
            · exact Finset.mem_coe.2 hr')
    rw [hins]
    calc _ ≤ _ := hstep
      _ ≤ (n : ℕ∞) + 1 := add_le_add ih le_rfl
      _ = ((n + 1 : ℕ) : ℕ∞) := by push_cast; rfl

/-- **In binary trees the cost with sharing is exactly the number of distinct subtrees.** -/
theorem cost_eq_card_sub (t : BinaryTree Unit) : cost t = ((sub t).card : ℕ∞) := by
  refine le_antisymm ?_ (card_sub_le_cost t)
  refine (poolK_mono (Set.singleton_subset_iff.2 (Finset.mem_coe.2 (self_mem_sub t)))).trans ?_
  exact poolK_closed_le _ (sub t) rfl fun x hx => sub_subset_of_mem hx

/-- The perfect tree of depth `d`: `2 ^ d - 1` nodes, all subtrees of one depth equal. -/
def perfect : ℕ → BinaryTree Unit
  | 0 => .nil
  | d + 1 => .node () (perfect d) (perfect d)

theorem numNodes_perfect_add_one (d : ℕ) : (perfect d).numNodes + 1 = 2 ^ d := by
  induction d with
  | zero => rfl
  | succ d ih =>
    simp only [perfect, BinaryTree.numNodes]
    rw [pow_succ]
    omega

theorem sub_perfect (d : ℕ) : sub (perfect d) = (Finset.range (d + 1)).image perfect := by
  induction d with
  | zero => rfl
  | succ d ih =>
    rw [perfect, sub, ih, Finset.union_self, ← perfect, Finset.range_add_one (n := d + 1),
      Finset.image_insert]

/-- **The perfect tree with `2 ^ d - 1` nodes costs `d + 1` steps**, against `n + 1` for the
comb with `n` nodes. With the same number of nodes, the cost with sharing runs from
logarithmic to linear, and the number of distinct subtrees decides where. -/
theorem cost_perfect (d : ℕ) : cost (perfect d) = ((d + 1 : ℕ) : ℕ∞) := by
  have hinj : Function.Injective perfect := by
    intro a b h
    have h1 := numNodes_perfect_add_one a
    have h2 := numNodes_perfect_add_one b
    rw [h] at h1
    exact Nat.pow_right_injective (le_refl 2) (h1.symm.trans h2)
  rw [cost_eq_card_sub, sub_perfect, Finset.card_image_of_injective _ hinj, Finset.card_range]

end Comb

/-! ### Most strings, not just one -/

/-- With `m` generators, at most `n · ((m + 1) n²)ⁿ` objects cost at most `n` steps. -/
theorem Binary.card_le_of_binK_le {ι : Type*} {M : Type*} [Fintype ι] (gen : ι → M)
    (op : M → M → M) (n : ℕ) (A : Finset M) (hA : ∀ x ∈ A, Binary.binK gen op x ≤ n) :
    A.card ≤ n * ((Fintype.card ι + 1) * n ^ 2) ^ n := by
  by_contra h
  obtain ⟨x, hx, hK⟩ := Binary.exists_binK_gt gen op n A (not_le.1 h)
  exact absurd (hA x hx) (not_le.2 hK)

/-- **Most strings gain only a logarithm.** If `a + (2 + 2 a) 2 ^ a + d < L`, fewer than
`2 ^ (L - d)` binary strings, of any length, cost at most `2 ^ a` steps. So among the
`2 ^ L` strings of length `L`, all but a fraction `2 ^ -d` cost more than `2 ^ a`, which is
about `L / (4 log₂ L)`, while every one of them costs at most about `2 L / log₂ L`
(`Str.strK_le_blocks`). -/
theorem Str.card_cheap_lt (L a d : ℕ) (h : a + (2 + 2 * a) * 2 ^ a + d < L)
    (A : Finset (FreeMonoid Bool)) (hA : ∀ w ∈ A, Str.strK w ≤ ((2 ^ a : ℕ) : ℕ∞)) :
    A.card < 2 ^ (L - d) := by
  have h1 := Binary.card_le_of_binK_le (FreeMonoid.of : Bool → FreeMonoid Bool) (· * ·)
    (2 ^ a) A hA
  rw [Fintype.card_bool] at h1
  exact lt_of_le_of_lt h1 (Circuit.count_pow a 2 3 (L - d) (by norm_num) (by omega))

/-! ### Monomials with many atoms: grouping the digits

Straus's method groups the atoms and is good when the exponents are long. When the atoms
are many, group the binary digits of the exponents instead. Within a block of `h` digit
positions, atoms whose digits agree are multiplied together first; there are at most
`2 ^ h` such classes, and each digit position is then a product of classes. With the two
methods together the cost of every monomial is of order `k + L + k L / log (k L)`. -/

namespace MonoidGen

open Binary Sig

/-- Shorthand for the cost of a set of targets over generators `gen`. -/
noncomputable abbrev pk {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M) (T : Set M) : ℕ∞ :=
  poolK (binAlg gen (· * ·)) (fun _ => 1) T

/-- A product of members of the pool costs at most one step per factor. -/
theorem pk_insert_prod_le {ι κ : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (y : κ → M) (T : Set M) (t : Finset κ) (ht : t.Nonempty) :
    (∀ c ∈ t, y c ∈ T) → pk gen (insert (∏ c ∈ t, y c) T) ≤ pk gen T + (t.card : ℕ∞) := by
  induction ht using Finset.Nonempty.cons_induction with
  | singleton a =>
    intro h
    rw [Finset.prod_singleton, Set.insert_eq_of_mem (h a (Finset.mem_singleton_self a))]
    exact le_self_add
  | cons a t ha _ ih =>
    intro h
    have ih' := ih fun c hc => h c (Finset.mem_cons.2 (Or.inr hc))
    have hstep : pk gen (insert (y a * ∏ c ∈ t, y c) (insert (∏ c ∈ t, y c) T)) ≤
        pk gen (insert (∏ c ∈ t, y c) T) + 1 :=
      poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1) _ none
        ![y a, ∏ c ∈ t, y c] (fun b => by
          fin_cases b
          · exact Or.inr (h a (Finset.mem_cons_self a t))
          · exact Or.inl rfl)
    rw [Finset.prod_cons, Finset.card_cons]
    calc pk gen (insert (y a * ∏ c ∈ t, y c) T)
        ≤ pk gen (insert (y a * ∏ c ∈ t, y c) (insert (∏ c ∈ t, y c) T)) :=
          poolK_mono (Set.insert_subset_insert (Set.subset_insert _ _))
      _ ≤ _ := hstep
      _ ≤ pk gen T + (t.card : ℕ∞) + 1 := add_le_add ih' le_rfl
      _ = pk gen T + ((t.card + 1 : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]

/-- A family of products of members of the pool costs at most the total number of
factors. -/
theorem pk_union_prods_le {ι κ γ : Type*} {M : Type*} [CommMonoid M] [DecidableEq γ]
    (gen : ι → M) (y : κ → M) (t : γ → Finset κ) :
    ∀ (C : Finset γ) (T : Set M), (∀ c ∈ C, (t c).Nonempty) →
      (∀ c ∈ C, ∀ a ∈ t c, y a ∈ T) →
      pk gen (T ∪ (fun c => ∏ a ∈ t c, y a) '' (C : Set γ)) ≤
        pk gen T + ((∑ c ∈ C, (t c).card : ℕ) : ℕ∞) := by
  intro C
  induction C using Finset.induction_on with
  | empty => intro T _ _; simp
  | insert c C hc ih =>
    intro T hne hmem
    have ih' := ih T (fun c' hc' => hne c' (Finset.mem_insert_of_mem hc'))
      (fun c' hc' => hmem c' (Finset.mem_insert_of_mem hc'))
    have hstep := pk_insert_prod_le gen y
      (T ∪ (fun c => ∏ a ∈ t c, y a) '' (C : Set γ)) (t c)
      (hne c (Finset.mem_insert_self c C))
      (fun a ha => Or.inl (hmem c (Finset.mem_insert_self c C) a ha))
    rw [Finset.coe_insert, Set.image_insert_eq, Set.union_insert, Finset.sum_insert hc]
    calc _ ≤ _ := hstep
      _ ≤ pk gen T + ((∑ c ∈ C, (t c).card : ℕ) : ℕ∞) + ((t c).card : ℕ∞) :=
          add_le_add ih' le_rfl
      _ = _ := by push_cast; ring

/-- **Horner's rule on a pool of digit products.** If, for every digit position `j < L`,
the product of the atoms whose exponent has digit `1` at `j` is in the pool, then the whole
product of powers costs `2 L` further steps. -/
theorem pk_insert_prod_pow_of_digits_le {ι : Type*} {M : Type*} [CommMonoid M]
    (gen : ι → M) (x : ι → M) (I : Finset ι) (T : Set M) :
    ∀ (L : ℕ) (e : ι → ℕ), (∀ i ∈ I, e i < 2 ^ L) → (∃ i ∈ I, e i ≠ 0) →
      (∀ j < L, (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty →
        ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), x i ∈ T) →
      pk gen (insert (∏ i ∈ I, x i ^ e i) T) ≤ pk gen T + ((2 * L : ℕ) : ℕ∞) := by
  intro L
  induction L with
  | zero =>
    rintro e he ⟨i, hi, hne⟩
    have := he i hi
    omega
  | succ L ih =>
    intro e he hne hcol
    have hsplit : (∏ i ∈ I, x i ^ e i) =
        (∏ i ∈ I, x i ^ (e i / 2)) * (∏ i ∈ I, x i ^ (e i / 2)) *
          ∏ i ∈ I.filter (fun i => e i % 2 = 1), x i := by
      rw [Finset.prod_filter, ← Finset.prod_mul_distrib, ← Finset.prod_mul_distrib]
      refine Finset.prod_congr rfl fun i _ => ?_
      rcases Nat.mod_two_eq_zero_or_one (e i) with h | h
      · have h' : ¬e i % 2 = 1 := by omega
        simp only [h', ite_false, mul_one]
        rw [← pow_add]
        congr 1
        omega
      · simp only [h, ite_true]
        rw [← pow_add, ← pow_succ]
        congr 1
        omega
    have h0 : (I.filter fun i => e i % 2 = 1).Nonempty →
        ∏ i ∈ I.filter (fun i => e i % 2 = 1), x i ∈ T := by
      have h := hcol 0 (Nat.succ_pos L)
      simpa using h
    by_cases hhalf : ∃ i ∈ I, e i / 2 ≠ 0
    · have hcol' : ∀ j < L, (I.filter fun i => e i / 2 / 2 ^ j % 2 = 1).Nonempty →
          ∏ i ∈ I.filter (fun i => e i / 2 / 2 ^ j % 2 = 1), x i ∈ T := by
        intro j hj
        have e1 : ∀ i, e i / 2 / 2 ^ j = e i / 2 ^ (j + 1) := fun i => by
          rw [Nat.div_div_eq_div_mul, pow_succ']
        simp only [e1]
        exact hcol (j + 1) (Nat.succ_lt_succ hj)
      have ih' := ih (fun i => e i / 2)
        (fun i hi => by
          have := he i hi
          rw [pow_succ] at this
          omega) hhalf hcol'
      generalize (∏ i ∈ I, x i ^ (e i / 2)) = q at hsplit ih'
      have h1 : pk gen (insert (q * q) (insert q T)) ≤ pk gen (insert q T) + 1 :=
        poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1) (insert q T) none
          ![q, q] (fun b => by fin_cases b <;> exact Or.inl rfl)
      by_cases hodd : (I.filter fun i => e i % 2 = 1).Nonempty
      · have hy := h0 hodd
        generalize (∏ i ∈ I.filter (fun i => e i % 2 = 1), x i) = y at hsplit hy
        have h2 : pk gen (insert (q * q * y) (insert (q * q) (insert q T))) ≤
            pk gen (insert (q * q) (insert q T)) + 1 :=
          poolK_insert_alg_le (alg := binAlg gen (· * ·)) (wt := fun _ => 1)
            (insert (q * q) (insert q T)) none ![q * q, y]
            (fun b => by
              fin_cases b
              · exact Or.inl rfl
              · exact Or.inr (Or.inr hy))
        have hsub : insert (∏ i ∈ I, x i ^ e i) T ⊆
            insert (q * q * y) (insert (q * q) (insert q T)) := by
          rw [hsplit]
          exact Set.insert_subset_insert fun z hz => Or.inr (Or.inr hz)
        calc pk gen (insert (∏ i ∈ I, x i ^ e i) T)
            ≤ _ := poolK_mono hsub
          _ ≤ pk gen T + ((2 * L : ℕ) : ℕ∞) + 1 + 1 :=
              h2.trans (add_le_add (h1.trans (add_le_add ih' le_rfl)) le_rfl)
          _ = pk gen T + ((2 * (L + 1) : ℕ) : ℕ∞) := by
              push_cast
              ring
      · rw [Finset.not_nonempty_iff_eq_empty] at hodd
        rw [hodd, Finset.prod_empty, mul_one] at hsplit
        have hsub : insert (∏ i ∈ I, x i ^ e i) T ⊆ insert (q * q) (insert q T) := by
          rw [hsplit]
          exact Set.insert_subset_insert (Set.subset_insert _ _)
        calc pk gen (insert (∏ i ∈ I, x i ^ e i) T)
            ≤ _ := poolK_mono hsub
          _ ≤ pk gen T + ((2 * L : ℕ) : ℕ∞) + 1 := h1.trans (add_le_add ih' le_rfl)
          _ ≤ pk gen T + ((2 * L : ℕ) : ℕ∞) + 1 + 1 := le_self_add
          _ = pk gen T + ((2 * (L + 1) : ℕ) : ℕ∞) := by
              push_cast
              ring
    · push Not at hhalf
      have hq : ∏ i ∈ I, x i ^ (e i / 2) = 1 :=
        Finset.prod_eq_one fun i hi => by rw [hhalf i hi, pow_zero]
      obtain ⟨i, hi, hne⟩ := hne
      have hodd : (I.filter fun i => e i % 2 = 1).Nonempty :=
        ⟨i, Finset.mem_filter.2 ⟨hi, by have := hhalf i hi; omega⟩⟩
      have hmem : ∏ i ∈ I, x i ^ e i ∈ T := by
        rw [hsplit, hq, one_mul, one_mul]
        exact h0 hodd
      rw [Set.insert_eq_of_mem hmem]
      exact le_self_add

end MonoidGen

namespace MonoidGen

open Binary Sig

/-- **One block of digit positions.** Over a pool that contains the atoms, the digit
products for the positions in a block `B` of at most `h` positions cost at most
`|I| + h · 2 ^ h` further steps: first the classes of atoms with equal digits on `B`, then
each digit product as a product of classes. -/
theorem pk_digit_block_le {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (I : Finset ι) (e : ι → ℕ) (h : ℕ) (B : Finset ℕ) (hB : B.card ≤ h) (T : Set M)
    (hT : ∀ i ∈ I, gen i ∈ T) :
    pk gen (T ∪ (fun j => ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), gen i) ''
        ((B.filter fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty : Finset ℕ) :
          Set ℕ)) ≤ pk gen T + ((I.card + h * 2 ^ h : ℕ) : ℕ∞) := by
  classical
  -- the digits of atom `i` on the block
  obtain ⟨typ, htyp⟩ : ∃ typ : ι → Finset ℕ,
      ∀ i, typ i = B.filter (fun j => e i / 2 ^ j % 2 = 1) := ⟨_, fun _ => rfl⟩
  have hmem_typ : ∀ i j, j ∈ typ i ↔ j ∈ B ∧ e i / 2 ^ j % 2 = 1 := fun i j => by
    rw [htyp, Finset.mem_filter]
  obtain ⟨𝒯, h𝒯⟩ : ∃ 𝒯 : Finset (Finset ℕ), 𝒯 = (I.image typ).erase ∅ := ⟨_, rfl⟩
  have hmem𝒯 : ∀ τ, τ ∈ 𝒯 ↔ τ ≠ ∅ ∧ ∃ i ∈ I, typ i = τ := fun τ => by
    rw [h𝒯, Finset.mem_erase, Finset.mem_image]
  -- classes of atoms
  have hFne : ∀ τ ∈ 𝒯, (I.filter fun i => typ i = τ).Nonempty := fun τ hτ => by
    obtain ⟨i, hi, hiτ⟩ := ((hmem𝒯 τ).1 hτ).2
    exact ⟨i, Finset.mem_filter.2 ⟨hi, hiτ⟩⟩
  have h1 := pk_union_prods_le gen gen (fun τ : Finset ℕ => I.filter fun i => typ i = τ) 𝒯 T
    hFne (fun τ _ a ha => hT a (Finset.mem_filter.1 ha).1)
  have hsum1 : ∑ τ ∈ 𝒯, (I.filter fun i => typ i = τ).card ≤ I.card := by
    rw [Finset.card_eq_sum_card_image typ I, h𝒯]
    exact Finset.sum_le_sum_of_subset (Finset.erase_subset _ _)
  -- digit products as products of classes
  have hcolmap : ∀ j ∈ B, ∀ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1),
      typ i ∈ 𝒯.filter (fun τ => j ∈ τ) := by
    intro j hj i hi
    obtain ⟨hiI, hbit⟩ := Finset.mem_filter.1 hi
    have hjt : j ∈ typ i := (hmem_typ i j).2 ⟨hj, hbit⟩
    exact Finset.mem_filter.2 ⟨(hmem𝒯 _).2 ⟨Finset.ne_empty_of_mem hjt, i, hiI, rfl⟩, hjt⟩
  have hne2 : ∀ j ∈ B.filter (fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty),
      (𝒯.filter fun τ => j ∈ τ).Nonempty := by
    intro j hj
    obtain ⟨hjB, i, hi⟩ := Finset.mem_filter.1 hj
    exact ⟨typ i, hcolmap j hjB i hi⟩
  have h2 := pk_union_prods_le gen (fun τ : Finset ℕ => ∏ i ∈ I.filter (fun i => typ i = τ), gen i)
    (fun j : ℕ => 𝒯.filter fun τ => j ∈ τ)
    (B.filter fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty)
    (T ∪ (fun τ : Finset ℕ => ∏ a ∈ I.filter (fun i => typ i = τ), gen a) '' (𝒯 : Set (Finset ℕ)))
    hne2 (fun j _ τ hτ => Or.inr ⟨τ, Finset.mem_coe.2 (Finset.mem_filter.1 hτ).1, rfl⟩)
  have h𝒯card : 𝒯.card ≤ 2 ^ h := by
    have hsub : 𝒯 ⊆ B.powerset := fun τ hτ => by
      obtain ⟨i, _, hiτ⟩ := ((hmem𝒯 τ).1 hτ).2
      rw [← hiτ, htyp]
      exact Finset.mem_powerset.2 (Finset.filter_subset _ _)
    calc 𝒯.card ≤ B.powerset.card := Finset.card_le_card hsub
      _ = 2 ^ B.card := Finset.card_powerset B
      _ ≤ 2 ^ h := Nat.pow_le_pow_right (by norm_num) hB
  have hsum2 : ∑ j ∈ B.filter (fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty),
      (𝒯.filter fun τ => j ∈ τ).card ≤ h * 2 ^ h := by
    refine (Finset.sum_le_card_nsmul _ _ (2 ^ h) fun j _ =>
      (Finset.card_filter_le _ _).trans h𝒯card).trans ?_
    rw [smul_eq_mul]
    exact Nat.mul_le_mul_right _ ((Finset.card_filter_le _ _).trans hB)
  have hident : ∀ j ∈ B.filter (fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty),
      ∏ τ ∈ 𝒯.filter (fun τ => j ∈ τ), ∏ i ∈ I.filter (fun i => typ i = τ), gen i =
        ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), gen i := by
    intro j hj
    have hjB := (Finset.mem_filter.1 hj).1
    rw [← Finset.prod_fiberwise_of_maps_to (hcolmap j hjB) fun i => gen i]
    refine Finset.prod_congr rfl fun τ hτ => ?_
    have hjτ : j ∈ τ := (Finset.mem_filter.1 hτ).2
    refine Finset.prod_congr ?_ fun _ _ => rfl
    ext i
    simp only [Finset.mem_filter]
    constructor
    · rintro ⟨hiI, hiτ⟩
      exact ⟨⟨hiI, ((hmem_typ i j).1 (hiτ ▸ hjτ)).2⟩, hiτ⟩
    · rintro ⟨⟨hiI, _⟩, hiτ⟩
      exact ⟨hiI, hiτ⟩
  have hsub : (T ∪ (fun j => ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), gen i) ''
      ((B.filter fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty : Finset ℕ) :
        Set ℕ)) ⊆
      (T ∪ (fun τ : Finset ℕ => ∏ a ∈ I.filter (fun i => typ i = τ), gen a) ''
        (𝒯 : Set (Finset ℕ))) ∪
      (fun j : ℕ => ∏ τ ∈ 𝒯.filter (fun τ => j ∈ τ),
        ∏ i ∈ I.filter (fun i => typ i = τ), gen i) ''
        ((B.filter fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty : Finset ℕ) :
          Set ℕ) := by
    rintro z (hz | ⟨j, hj, rfl⟩)
    · exact Or.inl (Or.inl hz)
    · exact Or.inr ⟨j, hj, hident j (Finset.mem_coe.1 hj)⟩
  calc _ ≤ _ := poolK_mono hsub
    _ ≤ _ := h2
    _ ≤ pk gen T + ((∑ τ ∈ 𝒯, (I.filter fun i => typ i = τ).card : ℕ) : ℕ∞) +
          ((∑ j ∈ B.filter (fun j => (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty),
            (𝒯.filter fun τ => j ∈ τ).card : ℕ) : ℕ∞) := add_le_add h1 le_rfl
    _ ≤ pk gen T + ((I.card : ℕ) : ℕ∞) + ((h * 2 ^ h : ℕ) : ℕ∞) := by
        gcongr
    _ = pk gen T + ((I.card + h * 2 ^ h : ℕ) : ℕ∞) := by push_cast; rw [add_assoc]

/-- All digit products below `n h`, block by block. -/
theorem pk_digits_le {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M) (I : Finset ι)
    (e : ι → ℕ) (h L : ℕ) (T : Set M) (hT : ∀ i ∈ I, gen i ∈ T) :
    ∀ n : ℕ, pk gen (T ∪ (fun j => ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), gen i) ''
        (((Finset.range L).filter fun j =>
          j < n * h ∧ (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty : Finset ℕ) : Set ℕ)) ≤
      pk gen T + ((n * (I.card + h * 2 ^ h) : ℕ) : ℕ∞) := by
  intro n
  induction n with
  | zero =>
    have hempty : ((Finset.range L).filter fun j =>
        j < 0 * h ∧ (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty) = ∅ := by
      refine Finset.filter_eq_empty_iff.2 fun j _ hj => ?_
      simp at hj
    rw [hempty]
    simp
  | succ n ih =>
    have hBcard : ((Finset.range L).filter fun j => n * h ≤ j ∧ j < (n + 1) * h).card ≤ h := by
      have hsub : ((Finset.range L).filter fun j => n * h ≤ j ∧ j < (n + 1) * h) ⊆
          Finset.Ico (n * h) ((n + 1) * h) := fun j hj =>
        Finset.mem_Ico.2 (Finset.mem_filter.1 hj).2
      refine (Finset.card_le_card hsub).trans ?_
      rw [Nat.card_Ico, Nat.succ_mul, Nat.add_sub_cancel_left]
    have hblock := pk_digit_block_le gen I e h
      ((Finset.range L).filter fun j => n * h ≤ j ∧ j < (n + 1) * h) hBcard
      (T ∪ (fun j => ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), gen i) ''
        (((Finset.range L).filter fun j =>
          j < n * h ∧ (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty : Finset ℕ) : Set ℕ))
      (fun i hi => Or.inl (hT i hi))
    refine (poolK_mono ?_).trans (hblock.trans ?_)
    · rintro z (hz | ⟨j, hj, rfl⟩)
      · exact Or.inl (Or.inl hz)
      · obtain ⟨hjL, hjn, hne⟩ := Finset.mem_filter.1 (Finset.mem_coe.1 hj)
        by_cases hlt : j < n * h
        · exact Or.inl (Or.inr ⟨j, Finset.mem_coe.2 (Finset.mem_filter.2 ⟨hjL, hlt, hne⟩), rfl⟩)
        · exact Or.inr ⟨j, Finset.mem_coe.2 (Finset.mem_filter.2
            ⟨Finset.mem_filter.2 ⟨hjL, not_lt.1 hlt, hjn⟩, hne⟩), rfl⟩
    · calc _ ≤ pk gen T + ((n * (I.card + h * 2 ^ h) : ℕ) : ℕ∞) +
            ((I.card + h * 2 ^ h : ℕ) : ℕ∞) := add_le_add ih le_rfl
        _ = _ := by push_cast; ring

/-- **Grouping the digits.** A product of powers of the generators in `I`, with exponents
below `2 ^ L`, costs at most `|I| + (L / h + 1) (|I| + h · 2 ^ h) + 2 L` steps, for every
block length `h ≥ 1`. -/
theorem slK_prod_pow_le_digits {ι : Type*} {M : Type*} [CommMonoid M] (gen : ι → M)
    (I : Finset ι) (L h : ℕ) (hh : 1 ≤ h) (e : ι → ℕ) (he : ∀ i ∈ I, e i < 2 ^ L)
    (hne : ∃ i ∈ I, e i ≠ 0) :
    slK gen (∏ i ∈ I, gen i ^ e i) ≤
      ((I.card + (L / h + 1) * (I.card + h * 2 ^ h) + 2 * L : ℕ) : ℕ∞) := by
  have hgens : pk gen (⋃ i ∈ I, {gen i}) ≤ (I.card : ℕ∞) := by
    refine (poolK_le_sum_dagK _ _).trans ?_
    refine (Finset.sum_le_card_nsmul _ _ 1 fun i _ => slK_gen_le gen i).trans ?_
    simp
  have hdig := pk_digits_le gen I e h L (⋃ i ∈ I, {gen i})
    (fun i hi => Set.mem_iUnion₂.2 ⟨i, hi, rfl⟩) (L / h + 1)
  have hlt : ∀ j < L, j < (L / h + 1) * h := fun j hj => by
    have h1 := Nat.div_add_mod L h
    have h2 := Nat.mod_lt L (by omega : 0 < h)
    have e3 : (L / h + 1) * h = h * (L / h) + h := by ring
    omega
  have hhorner := pk_insert_prod_pow_of_digits_le gen gen I
    ((⋃ i ∈ I, {gen i}) ∪
      (fun j => ∏ i ∈ I.filter (fun i => e i / 2 ^ j % 2 = 1), gen i) ''
        (((Finset.range L).filter fun j => j < (L / h + 1) * h ∧
          (I.filter fun i => e i / 2 ^ j % 2 = 1).Nonempty : Finset ℕ) : Set ℕ)) L e he hne
    (fun j hj hnej => Or.inr ⟨j, Finset.mem_coe.2 (Finset.mem_filter.2
      ⟨Finset.mem_range.2 hj, hlt j hj, hnej⟩), rfl⟩)
  calc slK gen (∏ i ∈ I, gen i ^ e i)
      ≤ _ := poolK_mono (Set.singleton_subset_iff.2 (Set.mem_insert _ _))
    _ ≤ _ := hhorner
    _ ≤ (I.card : ℕ∞) + (((L / h + 1) * (I.card + h * 2 ^ h) : ℕ) : ℕ∞) +
          ((2 * L : ℕ) : ℕ∞) := add_le_add (hdig.trans (add_le_add hgens le_rfl)) le_rfl
    _ = _ := by push_cast; rfl

end MonoidGen

/-! ### Monomials: every shape -/

/-- **Grouping the digits, for monomials.** With `k` atoms and exponents from `1` to below
`2 ^ L`, a monomial costs at most `k + (L / h + 1) (k + h · 2 ^ h) + 2 L` steps, for every
block length `h ≥ 1`. -/
theorem Monomial.slK_le_digits {k : ℕ} (hk : 0 < k) (L h : ℕ) (hh : 1 ≤ h) (e : Fin k → ℕ)
    (he : ∀ i, 1 ≤ e i ∧ e i < 2 ^ L) :
    MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) ≤
      ((k + (L / h + 1) * (k + h * 2 ^ h) + 2 * L : ℕ) : ℕ∞) := by
  have hprod : ∏ i, (Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) ^ e i
      = Multiplicative.ofAdd e := by
    simp_rw [← ofAdd_nsmul]
    rw [← ofAdd_sum]
    congr 1
    funext j
    simp [Finset.sum_apply, Pi.single_apply]
  have h := MonoidGen.slK_prod_pow_le_digits
    (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) Finset.univ L h hh e
    (fun i _ => (he i).2)
    ⟨⟨0, hk⟩, Finset.mem_univ _, by have := (he ⟨0, hk⟩).1; omega⟩
  rw [hprod] at h
  simpa using h

/-- **Many atoms.** With `k ≥ 4` atoms and blocks of `½ log₂ k` digits, a monomial costs at
most `k + (L / h + 1) · 2 k + 2 L` steps, where `h = ⌊log₂ k⌋ / 2`: about
`3 k + 2 L + 4 k L / log₂ k`. -/
theorem Monomial.slK_le_many_atoms {k : ℕ} (hk : 4 ≤ k) (L : ℕ) (e : Fin k → ℕ)
    (he : ∀ i, 1 ≤ e i ∧ e i < 2 ^ L) :
    MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) ≤
      ((k + (L / (Nat.log 2 k / 2) + 1) * (2 * k) + 2 * L : ℕ) : ℕ∞) := by
  have hlog : 2 ≤ Nat.log 2 k := by
    have := Nat.log_mono_right (b := 2) hk
    have h4 : Nat.log 2 4 = 2 := by
      rw [show (4 : ℕ) = 2 ^ 2 by norm_num, Nat.log_pow (by norm_num)]
    omega
  have hh : 1 ≤ Nat.log 2 k / 2 := by omega
  have hsmall : Nat.log 2 k / 2 * 2 ^ (Nat.log 2 k / 2) ≤ k := by
    have h1 : Nat.log 2 k / 2 ≤ 2 ^ (Nat.log 2 k / 2) := Nat.lt_two_pow_self.le
    have h2 : 2 ^ (Nat.log 2 k / 2) * 2 ^ (Nat.log 2 k / 2) ≤ 2 ^ Nat.log 2 k := by
      rw [← pow_add]
      exact Nat.pow_le_pow_right (by norm_num) (by omega)
    have h3 : 2 ^ Nat.log 2 k ≤ k := Nat.pow_log_le_self 2 (by omega)
    exact (Nat.mul_le_mul_right _ h1).trans (h2.trans h3)
  refine (Monomial.slK_le_digits (by omega) L (Nat.log 2 k / 2) hh e he).trans ?_
  exact_mod_cast Nat.add_le_add_right (Nat.add_le_add_left
    (Nat.mul_le_mul_left _ (by omega)) _) _

/-- **The support bound for monomials**: with every exponent at least `1`, a monomial in
`k` atoms costs at least `2 k - 1` steps. -/
theorem Monomial.two_mul_le_slK_add_one {k : ℕ} (e : Fin k → ℕ) (he : ∀ i, 1 ≤ e i) :
    (2 * k : ℕ∞) ≤ MonoidGen.slK
      (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
      (Multiplicative.ofAdd e) + 1 := by
  have h := Binary.two_mul_card_support_le_binK
    (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ)) (· * ·)
    (fun x : Multiplicative (Fin k → ℕ) =>
      Finset.univ.filter fun i => Multiplicative.toAdd x i ≠ 0)
    (fun i => by
      refine (Finset.card_le_card (t := {i}) fun j hj => ?_).trans (by simp)
      have hj' := (Finset.mem_filter.1 hj).2
      rw [Finset.mem_singleton]
      by_contra hne
      exact hj' (by simp [hne]))
    (fun x y j hj => by
      have hj' := (Finset.mem_filter.1 hj).2
      rw [Finset.mem_union, Finset.mem_filter, Finset.mem_filter]
      by_contra hcon
      rw [not_or] at hcon
      have hx : Multiplicative.toAdd x j = 0 := by
        by_contra hx
        exact hcon.1 ⟨Finset.mem_univ _, hx⟩
      have hy : Multiplicative.toAdd y j = 0 := by
        by_contra hy
        exact hcon.2 ⟨Finset.mem_univ _, hy⟩
      exact hj' (by simp [toAdd_mul, hx, hy]))
    (Multiplicative.ofAdd e)
  have hcard : (Finset.univ.filter fun i : Fin k =>
      Multiplicative.toAdd (Multiplicative.ofAdd e) i ≠ 0).card = k := by
    rw [Finset.filter_true_of_mem fun i _ => by
      have := he i
      simp only [toAdd_ofAdd]
      omega]
    simp
  rw [hcard] at h
  exact h

/-- **The hardest monomial, every shape.** With `k` atoms and exponents from `1` to
`2 ^ L`, under the counting hypothesis there is a monomial with two lower bounds and two
upper bounds on its cost: more than `2 ^ a` (counting), at least `2 k - 1` (support),
fewer than `(k / g + 1) (2 ^ g + 2 (L + 1))` (grouping atoms), and at most
`k + ((L + 1) / h + 1) (k + h · 2 ^ h) + 2 (L + 1)` (grouping digits). By hand, not in
Lean: with the best `g` and `h` the upper bounds are of order `k + L + k L / log (k L)`,
and the growth law (`Monomial.sum_mul_two_le_two_pow`) adds `L` to the lower bounds for a
monomial with an exponent `2 ^ L`. -/
theorem Monomial.exists_slK_every_shape (k L g h a b : ℕ) (hk : 0 < k) (hg : 1 ≤ g)
    (hh : 1 ≤ h) (hb : k + 1 ≤ 2 ^ b) (hcount : a + (b + 2 * a) * 2 ^ a < k * L) :
    ∃ e : Fin k → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ L) ∧
      ((2 ^ a : ℕ) : ℕ∞) < MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) ∧
      (2 * k : ℕ∞) ≤ MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) + 1 ∧
      MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) + 1 ≤
          (((k / g + 1) * (2 ^ g + 2 * (L + 1)) : ℕ) : ℕ∞) ∧
      MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) ≤
          ((k + ((L + 1) / h + 1) * (k + h * 2 ^ h) + 2 * (L + 1) : ℕ) : ℕ∞) := by
  obtain ⟨e, he, hlo, hup⟩ := Monomial.exists_slK_between_general k L g a b hk hg hb hcount
  have he' : ∀ i, 1 ≤ e i ∧ e i < 2 ^ (L + 1) := fun i =>
    ⟨(he i).1, lt_of_le_of_lt (he i).2
      (Nat.pow_lt_pow_right (by norm_num) (Nat.lt_succ_self _))⟩
  exact ⟨e, he, hlo, Monomial.two_mul_le_slK_add_one e fun i => (he i).1, hup,
    Monomial.slK_le_digits hk (L + 1) h hh e he'⟩

/-! ### Growth as an instance of depth, and the growth bound for monomials -/

/-- **Growth is the depth bound for `⌈log₂ size⌉`.** If a size is `1` on generators and
subadditive, then anything built in `n` steps has `⌈log₂ size⌉ + 1 ≤ n`: the function
`⌈log₂ size⌉` grows by at most one per operation, so `Binary.depth_add_one_le` applies. -/
theorem Binary.clog_add_one_le {ι : Type*} {M : Type*} (gen : ι → M) (op : M → M → M)
    (μ : M → ℕ) (hgen : ∀ i, μ (gen i) = 1) (hop : ∀ x y, μ (op x y) ≤ μ x + μ y) {x : M}
    {n : ℕ} (h : Binary.binK gen op x ≤ n) : Nat.clog 2 (μ x) + 1 ≤ n := by
  refine Binary.depth_add_one_le gen op (fun x => Nat.clog 2 (μ x))
    (fun i => by rw [hgen]; simp) (fun x y => ?_) h
  refine Nat.clog_le_of_le_pow ?_
  have hx : μ x ≤ 2 ^ max (Nat.clog 2 (μ x)) (Nat.clog 2 (μ y)) :=
    (Nat.le_pow_clog (by norm_num) _).trans
      (Nat.pow_le_pow_right (by norm_num) (le_max_left _ _))
  have hy : μ y ≤ 2 ^ max (Nat.clog 2 (μ x)) (Nat.clog 2 (μ y)) :=
    (Nat.le_pow_clog (by norm_num) _).trans
      (Nat.pow_le_pow_right (by norm_num) (le_max_right _ _))
  rw [pow_succ]
  have := hop x y
  omega

/-- **The growth bound for monomials**: a monomial of total degree `D` built in `n` steps
has `2 D ≤ 2 ^ n`. So a monomial with an exponent `2 ^ L` needs more than `L` steps. -/
theorem Monomial.sum_mul_two_le_two_pow {k : ℕ} (e : Fin k → ℕ) {n : ℕ}
    (h : MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
      (Multiplicative.ofAdd e) ≤ n) : (∑ i, e i) * 2 ≤ 2 ^ n := by
  have h' := MonoidGen.mul_two_le_two_pow
    (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
    (fun x : Multiplicative (Fin k → ℕ) => ∑ i, Multiplicative.toAdd x i)
    (fun i => by simp [Pi.single_apply]) (fun x y => by simp [Finset.sum_add_distrib])
    (x := Multiplicative.ofAdd e) h
  simpa using h'

/-! ### The order of the hardest monomial, as theorems

The comparison of the bounds above, done in Lean. Write `κ = log₂ k` and `ℓ = log₂ L`
(rounded down). Every monomial costs at most `12 k L / (κ + ℓ) + 6 (k + L)` steps; some
monomial costs more than `k L / (8 (κ + ℓ + 2))`; every monomial with all exponents at least
`1` costs at least `2 k - 1`; and some monomial costs more than `L`. -/

/-- **Every monomial is cheap.** With `k ≥ 4` atoms and exponents from `1` to below `2 ^ L`,
`L ≥ 2`, a monomial costs at most `12 k L / (log₂ k + log₂ L) + 6 (k + L)` steps: group the
atoms when `log₂ L ≥ log₂ k`, group the digits otherwise. -/
theorem Monomial.slK_le_order {k : ℕ} (hk : 4 ≤ k) (L : ℕ) (hL : 2 ≤ L) (e : Fin k → ℕ)
    (he : ∀ i, 1 ≤ e i ∧ e i < 2 ^ L) :
    MonoidGen.slK (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) ≤
      ((12 * (k * L) / (Nat.log 2 k + Nat.log 2 L) + 6 * (k + L) : ℕ) : ℕ∞) := by
  have hκ : 2 ≤ Nat.log 2 k := by
    have := Nat.log_mono_right (b := 2) hk
    have h4 : Nat.log 2 4 = 2 := by
      rw [show (4 : ℕ) = 2 ^ 2 by norm_num, Nat.log_pow (by norm_num)]
    omega
  have hℓ : 1 ≤ Nat.log 2 L := Nat.log_pos (by norm_num) hL
  have hpos : 0 < Nat.log 2 k + Nat.log 2 L := by omega
  have key : ∀ B Y : ℕ, B ≤ Y + 6 * (k + L) →
      Y * (Nat.log 2 k + Nat.log 2 L) ≤ 12 * (k * L) →
      B ≤ 12 * (k * L) / (Nat.log 2 k + Nat.log 2 L) + 6 * (k + L) := fun B Y h1 h2 =>
    h1.trans (Nat.add_le_add_right ((Nat.le_div_iff_mul_le hpos).2 h2) _)
  generalize hκdef : Nat.log 2 k = κ at hκ hpos key ⊢
  generalize hℓdef : Nat.log 2 L = ℓ at hℓ hpos key ⊢
  rcases le_or_gt κ ℓ with hcase | hcase
  · -- group the atoms
    have h := Monomial.slK_add_one_le_log (by omega : 0 < k) L hL e he
    rw [hℓdef] at h
    have hq : k / ℓ * ℓ ≤ k := Nat.div_mul_le_self k ℓ
    generalize k / ℓ = q at h hq
    have eB : (q + 1) * (3 * L) = q * (3 * L) + 3 * L := by ring
    have hY : q * (3 * L) * (κ + ℓ) ≤ 12 * (k * L) := by
      calc q * (3 * L) * (κ + ℓ) ≤ q * (3 * L) * (ℓ + ℓ) := Nat.mul_le_mul_left _ (by omega)
        _ = 6 * L * (q * ℓ) := by ring
        _ ≤ 6 * L * k := Nat.mul_le_mul_left _ hq
        _ = 6 * (k * L) := by ring
        _ ≤ 12 * (k * L) := by omega
    have hB := key ((q + 1) * (3 * L)) (q * (3 * L)) (by omega) hY
    exact (le_self_add.trans h).trans (by exact_mod_cast hB)
  · -- group the digits
    have h := Monomial.slK_le_many_atoms hk L e he
    rw [hκdef] at h
    have hh : 1 ≤ κ / 2 := by omega
    have hr : L / (κ / 2) * (κ / 2) ≤ L := Nat.div_mul_le_self L (κ / 2)
    have hκh : κ + ℓ ≤ 6 * (κ / 2) := by omega
    generalize κ / 2 = hgt at h hh hr hκh
    generalize L / hgt = r at h hr
    have eB : (r + 1) * (2 * k) = r * (2 * k) + 2 * k := by ring
    have hY : r * (2 * k) * (κ + ℓ) ≤ 12 * (k * L) := by
      calc r * (2 * k) * (κ + ℓ) ≤ r * (2 * k) * (6 * hgt) := Nat.mul_le_mul_left _ hκh
        _ = 12 * k * (r * hgt) := by ring
        _ ≤ 12 * k * L := Nat.mul_le_mul_left _ hr
        _ = 12 * (k * L) := by ring
    have hB := key (k + (r + 1) * (2 * k) + 2 * L) (r * (2 * k)) (by omega) hY
    exact h.trans (by exact_mod_cast hB)

/-- **Some monomial is expensive.** With `k ≥ 4` atoms and exponents from `1` to `2 ^ L`,
`L ≥ 2`, some monomial costs more than `k L / (8 (log₂ k + log₂ L + 2))` steps. -/
theorem Monomial.exists_slK_gt_order (k L : ℕ) (hk : 4 ≤ k) (hL : 2 ≤ L) :
    ∃ e : Fin k → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ L) ∧
      ((k * L / (8 * (Nat.log 2 k + Nat.log 2 L + 2)) : ℕ) : ℕ∞) < MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) := by
  have hkb : k + 1 ≤ 2 ^ (Nat.log 2 k + 1) := Nat.lt_pow_succ_log_self (by norm_num) k
  have hLb : L < 2 ^ (Nat.log 2 L + 1) := Nat.lt_pow_succ_log_self (by norm_num) L
  have hκk : Nat.log 2 k < k := Nat.log_lt_self 2 (by omega)
  generalize Nat.log 2 k = κ at hkb hκk ⊢
  generalize Nat.log 2 L = ℓ at hLb ⊢
  have hkL : k * L < 2 ^ (κ + ℓ + 2) := by
    have h1 : k < 2 ^ (κ + 1) := by omega
    calc k * L < 2 ^ (κ + 1) * 2 ^ (ℓ + 1) := Nat.mul_lt_mul'' h1 hLb
      _ = 2 ^ (κ + ℓ + 2) := by rw [← pow_add]; congr 1; omega
  have hkL8 : 8 ≤ k * L := by
    calc 8 = 4 * 2 := by norm_num
      _ ≤ k * L := Nat.mul_le_mul hk hL
  obtain ⟨Q, hQ⟩ : ∃ Q, Q = k * L / (4 * (κ + ℓ + 2)) := ⟨_, rfl⟩
  have hQmul : Q * (4 * (κ + ℓ + 2)) ≤ k * L := hQ ▸ Nat.div_mul_le_self _ _
  have hQle : Q ≤ k * L := hQ ▸ Nat.div_le_self _ _
  -- the counting parameter
  obtain ⟨a, ha⟩ : ∃ a, a = Nat.log 2 Q := ⟨_, rfl⟩
  have hQlt : Q < 2 ^ (a + 1) := ha ▸ Nat.lt_pow_succ_log_self (by norm_num) Q
  have haP : a < 2 ^ a := Nat.lt_two_pow_self
  have hcount : a + (κ + 1 + 2 * a) * 2 ^ a < k * L := by
    rcases Nat.eq_zero_or_pos Q with hQ0 | hQpos
    · have ha0 : a = 0 := by rw [ha, hQ0]; simp
      rw [ha0]
      simp only [pow_zero, mul_one, mul_zero, add_zero, zero_add]
      have : k * 2 ≤ k * L := Nat.mul_le_mul_left k hL
      omega
    · have hP : 2 ^ a ≤ Q := ha ▸ Nat.pow_log_le_self 2 (by omega)
      have ha' : a < κ + ℓ + 2 :=
        (Nat.pow_lt_pow_iff_right (by norm_num : 1 < 2)).1 (lt_of_le_of_lt (hP.trans hQle) hkL)
      generalize 2 ^ a = P at haP hP
      have h1 : a + (κ + 1 + 2 * a) * P ≤ (3 * κ + 2 * ℓ + 4) * P := by
        have h2 : (κ + 1 + 2 * a) * P ≤ (3 * κ + 2 * ℓ + 3) * P :=
          Nat.mul_le_mul_right _ (by omega)
        have e3 : (3 * κ + 2 * ℓ + 4) * P = (3 * κ + 2 * ℓ + 3) * P + P := by ring
        omega
      have h3 : (3 * κ + 2 * ℓ + 4) * P ≤ (3 * κ + 2 * ℓ + 4) * Q := Nat.mul_le_mul_left _ hP
      have h4 : (3 * κ + 2 * ℓ + 4) * Q < Q * (4 * (κ + ℓ + 2)) := by
        rw [mul_comm Q]
        exact Nat.mul_lt_mul_of_pos_right (by omega) hQpos
      omega
  obtain ⟨e, he, hlo, -⟩ := Monomial.exists_slK_between_general k L 1 a (κ + 1) (by omega)
    le_rfl hkb hcount
  refine ⟨e, he, lt_of_le_of_lt ?_ hlo⟩
  have hdiv : k * L / (8 * (κ + ℓ + 2)) ≤ 2 ^ a := by
    have e8 : 8 * (κ + ℓ + 2) = 4 * (κ + ℓ + 2) * 2 := by ring
    rw [e8, ← Nat.div_div_eq_div_mul, ← hQ]
    rw [pow_succ] at hQlt
    omega
  exact_mod_cast hdiv

/-- **Some monomial needs more than `L` steps**: the one with an exponent `2 ^ L`. -/
theorem Monomial.exists_slK_gt_exponent (k L : ℕ) (hk : 0 < k) :
    ∃ e : Fin k → ℕ, (∀ i, 1 ≤ e i ∧ e i ≤ 2 ^ L) ∧
      (L : ℕ∞) < MonoidGen.slK
        (fun i : Fin k => Multiplicative.ofAdd (Pi.single i 1 : Fin k → ℕ))
        (Multiplicative.ofAdd e) := by
  refine ⟨fun i => if i = ⟨0, hk⟩ then 2 ^ L else 1, fun i => ?_, ?_⟩
  · by_cases h : i = ⟨0, hk⟩
    · simp [h, Nat.one_le_two_pow]
    · simp [h, Nat.one_le_two_pow]
  · refine lt_of_not_ge fun hle => ?_
    have h := Monomial.sum_mul_two_le_two_pow _ hle
    have hsum : 2 ^ L ≤ ∑ i : Fin k, (if i = ⟨0, hk⟩ then 2 ^ L else 1) := by
      have := Finset.single_le_sum (f := fun i : Fin k => if i = ⟨0, hk⟩ then 2 ^ L else 1)
        (fun _ _ => Nat.zero_le _) (Finset.mem_univ (⟨0, hk⟩ : Fin k))
      simpa using this
    have hpos : 0 < 2 ^ L := Nat.pos_of_ne_zero (by positivity)
    omega

/-! ### The other end for trees: a perfect tree attains the exponential ceiling -/

/-- Without sharing a perfect tree of depth `d` costs `2 ^ (d + 1) - 1` steps; with sharing
it costs `d + 1` (`Comb.cost_perfect`). So in binary trees the gain from sharing runs from
below `2` (combs, `Comb.binTreeK_comb`) up to the exponential ceiling
(`Binary.binTreeK_add_one_le_two_pow`), which the perfect tree attains exactly. -/
theorem Comb.binTreeK_perfect (d : ℕ) :
    Binary.binTreeK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
      (Comb.perfect d) + 1 = ((2 ^ (d + 1) : ℕ) : ℕ∞) := by
  have hfin : ∀ d, Binary.binTreeK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
      (BinaryTree.node ()) (Comb.perfect d) ≠ ⊤ := by
    intro d
    induction d with
    | zero => exact Binary.binTreeK_gen_ne_top _ _ ()
    | succ d ih => exact Binary.binTreeK_op_ne_top _ _ ih ih
  have h := Binary.binTreeK_add_one_eq
    (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
    (fun t => t.numNodes + 1) (fun _ => by simp) (fun x y => by simp; omega) (hfin d)
  rw [h]
  show 2 * ((((Comb.perfect d).numNodes + 1 : ℕ)) : ℕ∞) = _
  rw [Comb.numNodes_perfect_add_one, pow_succ]
  push_cast
  ring

/-! ### Every tree: the cost without sharing, and the most sharing can cost -/

/-- **Without sharing every binary tree with `n` nodes costs `2 n + 1` steps.** -/
theorem Comb.binTreeK_tree (t : BinaryTree Unit) :
    Binary.binTreeK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
      t + 1 = 2 * ((t.numNodes + 1 : ℕ) : ℕ∞) := by
  have hfin : ∀ t : BinaryTree Unit,
      Binary.binTreeK (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit))
        (BinaryTree.node ()) t ≠ ⊤ := by
    intro t
    induction t with
    | nil => exact Binary.binTreeK_gen_ne_top _ _ ()
    | node v l r ihl ihr =>
      cases v
      exact Binary.binTreeK_op_ne_top _ _ ihl ihr
  exact Binary.binTreeK_add_one_eq
    (fun _ : Unit => (BinaryTree.nil : BinaryTree Unit)) (BinaryTree.node ())
    (fun t => t.numNodes + 1) (fun _ => by simp) (fun x y => by simp; omega) (hfin t)

theorem Comb.nil_mem_sub (t : BinaryTree Unit) : BinaryTree.nil ∈ Comb.sub t := by
  induction t with
  | nil => simp [Comb.sub]
  | node v l r ihl _ =>
    rw [Comb.sub]
    exact Finset.mem_insert_of_mem (Finset.mem_union_left _ ihl)

/-- A tree with `n` nodes has at most `n + 1` distinct subtrees. -/
theorem Comb.card_sub_le (t : BinaryTree Unit) : (Comb.sub t).card ≤ t.numNodes + 1 := by
  induction t with
  | nil => simp [Comb.sub]
  | node v l r ihl ihr =>
    rw [Comb.sub]
    have h1 := Finset.card_insert_le (BinaryTree.node () l r) (Comb.sub l ∪ Comb.sub r)
    have h2 := Finset.card_union_add_card_inter (Comb.sub l) (Comb.sub r)
    have h3 : 1 ≤ (Comb.sub l ∩ Comb.sub r).card :=
      Finset.card_pos.2 ⟨BinaryTree.nil,
        Finset.mem_inter.2 ⟨Comb.nil_mem_sub l, Comb.nil_mem_sub r⟩⟩
    simp only [BinaryTree.numNodes]
    omega

/-- **With sharing a tree with `n` nodes costs at most `n + 1` steps**, and the comb attains
it (`Comb.binK_comb`). -/
theorem Comb.cost_le (t : BinaryTree Unit) : Comb.cost t ≤ ((t.numNodes + 1 : ℕ) : ℕ∞) := by
  rw [Comb.cost_eq_card_sub]
  exact_mod_cast Comb.card_sub_le t

end Complexity
