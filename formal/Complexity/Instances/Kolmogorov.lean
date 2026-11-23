import Complexity.Counting
import Complexity.Invariance

/-!
# Instance: Kolmogorov complexity

Genuine algorithmic complexity, built on Mathlib's partial recursive codes
`Nat.Partrec.Code`, as an instance of the one definition.

A **description method** is a partial map from bit strings to natural numbers. Each one is
a description system (programs are strings, cost is length, a program describes its
output), and its complexity is `K`. The *computable* description methods are those of the
form `run c` for a code `c`.

Nothing about the theory of this file is special to computation; what computation
contributes is one existence statement – a universal interpreter:

* `U`                    – read a unary program index (that many `true`s, then `false`),
                           then run that program on the rest of the input;
* `U_header_append`      – `U` runs every program from a fixed prefix;
* `U_mem_range`          – and `U` is itself a computable description method.

Everything else is then a corollary of the general results:

* `K_U_le`               – **Kolmogorov's optimality theorem**, from the prefix-simulation
                           transport lemma;
* `invariance`           – the **invariance theorem**, from `DescSystem.invariance`;
* `exists_incompressible` – **incompressible numbers exist**, from the counting law;
* `K_U_lt_top`, `K_U_encode_le` – every number is describable, and a string's code costs
                           at most its length plus a constant.

This is the pattern the unified theory predicts for every domain: complexity is intrinsic
to a domain (well defined up to an additive constant) when the domain's class of
admissible description systems contains a member that simulates all the others.

**Review note.** This is *plain* complexity of natural numbers (the domain of `U` is not
prefix-free). Only the "if" direction of the last sentence above is a theorem. Earlier
formalizations of the same results exist (HOL4, Coq, and a Lean 4 library).
-/

namespace Complexity

namespace Kolmogorov

open Nat.Partrec (Code)

/-- The description system of a partial interpreter on bit strings with natural-number
outputs: programs are strings, the cost of a program is its length, and a program
describes the number it outputs. -/
def sys (U : List Bool → Part ℕ) : DescSystem (List Bool) ℕ ℕ∞ where
  cost l := l.length
  realizes l x := x ∈ U l

theorem sys_isBinary (U : List Bool → Part ℕ) : (sys U).IsBinary := fun _ => rfl

theorem sys_functional (U : List Bool → Part ℕ) : (sys U).Functional :=
  fun _ _ _ hx hy => Part.mem_unique hx hy

/-- **Description complexity** relative to the description method `U`. -/
noncomputable def K (U : List Bool → Part ℕ) (x : ℕ) : ℕ∞ := (sys U).K x

/-- Upper bounds are programs: a program for `x` bounds its complexity by its length. -/
theorem K_le_length {U : List Bool → Part ℕ} {l : List Bool} {x : ℕ} (h : x ∈ U l) :
    K U x ≤ l.length :=
  (sys U).K_le_cost (d := l) h

/-- If `U` runs `V` from the prefix `p`, `U`-complexity exceeds `V`-complexity by at most
`|p|`. -/
theorem K_le_add_of_prefix (U V : List Bool → Part ℕ) (p : List Bool)
    (h : ∀ l, U (p ++ l) = V l) (x : ℕ) : K U x ≤ K V x + p.length := by
  let s : DescSystem.Sim (sys V) (sys U) (· + (p.length : ℕ∞)) :=
    { tr := fun l => p ++ l
      ob := id
      realizes' := fun {l x} hl => by
        show x ∈ U (p ++ l)
        rw [h l]
        exact hl
      cost_le := fun l => by
        show ((p ++ l).length : ℕ∞) ≤ (l.length : ℕ∞) + (p.length : ℕ∞)
        rw [List.length_append]
        push_cast
        rw [add_comm] }
  exact s.K_le_add x

/-! ### Computable description methods and the universal interpreter -/

/-- The description method computed by a program: run the code on the encoded input
string. -/
def run (c : Code) : List Bool → Part ℕ := fun l => c.eval (Encodable.encode l)

/-- The program index announced by an input: its number of leading `true`s. -/
def index (l : List Bool) : ℕ := (l.takeWhile id).length

/-- The payload of an input: what follows the leading `true`s and the `false` that ends
them. -/
def payload (l : List Bool) : List Bool := (l.dropWhile id).tail

/-- The self-delimiting header that selects program number `n`: `n` times `true`, then
`false`. -/
def header (n : ℕ) : List Bool := List.replicate n true ++ [false]

/-- A **universal interpreter**: read a unary-coded program index, then run that program
on the rest of the input. -/
def U : List Bool → Part ℕ := fun l =>
  (Denumerable.ofNat Code (index l)).eval (Encodable.encode (payload l))

theorem header_succ_append (n : ℕ) (l : List Bool) :
    header (n + 1) ++ l = true :: (header n ++ l) := by
  simp [header, List.replicate_succ]

theorem takeWhile_header_append (n : ℕ) (l : List Bool) :
    (header n ++ l).takeWhile id = List.replicate n true := by
  induction n with
  | zero => simp [header]
  | succ n ih => rw [header_succ_append, List.takeWhile_cons]; simp [ih, List.replicate_succ]

theorem dropWhile_header_append (n : ℕ) (l : List Bool) :
    (header n ++ l).dropWhile id = false :: l := by
  induction n with
  | zero => simp [header]
  | succ n ih => rw [header_succ_append, List.dropWhile_cons]; simp [ih]

@[simp] theorem index_header_append (n : ℕ) (l : List Bool) : index (header n ++ l) = n := by
  rw [index, takeWhile_header_append, List.length_replicate]

@[simp] theorem payload_header_append (n : ℕ) (l : List Bool) :
    payload (header n ++ l) = l := by
  rw [payload, dropWhile_header_append, List.tail_cons]

@[simp] theorem length_header (n : ℕ) : (header n).length = n + 1 := by
  simp [header]

/-- **`U` runs every program from a fixed prefix**: its header. -/
theorem U_header_append (c : Code) (l : List Bool) :
    U (header (Encodable.encode c) ++ l) = run c l := by
  simp only [U, run, index_header_append, payload_header_append, Denumerable.ofNat_encode]

theorem U_prefix (c : Code) : ∃ p : List Bool, ∀ l, U (p ++ l) = run c l :=
  ⟨header (Encodable.encode c), U_header_append c⟩

theorem index_primrec : Primrec index :=
  Primrec.list_length.comp (Primrec.list_takeWhile Primrec.id)

theorem payload_primrec : Primrec payload :=
  Primrec.list_tail.comp (Primrec.list_dropWhile Primrec.id)

/-- The universal interpreter is partial recursive. -/
theorem U_partrec : Partrec (U : List Bool →. ℕ) :=
  Nat.Partrec.Code.eval_part.comp ((Computable.ofNat Code).comp index_primrec.to_comp)
    (Computable.encode.comp payload_primrec.to_comp)

/-- **`U` is itself a computable description method**: some program computes it. -/
theorem U_mem_range : U ∈ Set.range run := by
  have h : Nat.Partrec fun n =>
      Part.bind (Encodable.decode (α := List Bool) n) fun a => (U a).map Encodable.encode :=
    U_partrec
  obtain ⟨c, hc⟩ := Nat.Partrec.Code.exists_code.1 h
  refine ⟨c, funext fun l => ?_⟩
  show c.eval (Encodable.encode l) = U l
  rw [hc]
  simp only [Encodable.encodek, Part.coe_some, Part.bind_some]
  exact Part.map_id' Encodable.encode_nat _

/-! ### Optimality, invariance, incompressibility -/

/-- **Kolmogorov's optimality theorem.** The universal interpreter describes everything at
most a constant more expensively than any computable description method. The constant is
the length of the method's header. -/
theorem K_U_le (c : Code) : ∃ k : ℕ, ∀ x, K U x ≤ K (run c) x + k :=
  ⟨(header (Encodable.encode c)).length, fun x =>
    K_le_add_of_prefix U (run c) _ (U_header_append c) x⟩

/-- The explicit constant in the optimality theorem: one more than the program's index. -/
theorem K_U_le_add_encode (c : Code) (x : ℕ) :
    K U x ≤ K (run c) x + ((Encodable.encode c + 1 : ℕ) : ℕ∞) := by
  have h := K_le_add_of_prefix U (run c) _ (U_header_append c) x
  rwa [length_header] at h

/-- The class of computable description methods, as description systems. -/
def computable : Set (DescSystem (List Bool) ℕ ℕ∞) := Set.range fun c : Code => sys (run c)

theorem sys_U_mem_computable : sys U ∈ computable := by
  obtain ⟨c, hc⟩ := U_mem_range
  exact ⟨c, congrArg sys hc⟩

/-- In the language of the general theory: `U` dominates every computable system. -/
theorem U_dominates {S : DescSystem (List Bool) ℕ ℕ∞} (hS : S ∈ computable) :
    DescSystem.Dominates (sys U) S := by
  obtain ⟨c, rfl⟩ := hS
  exact K_U_le c

/-- **Invariance theorem.** Any other optimal computable interpreter agrees with `U` up to
an additive constant: Kolmogorov complexity is intrinsic. This is
`DescSystem.invariance` applied to the class of computable description methods. -/
theorem invariance (U' : List Bool → Part ℕ) (hU' : U' ∈ Set.range run)
    (hopt : ∀ c : Code, ∃ p : List Bool, ∀ l, U' (p ++ l) = run c l) :
    ∃ k : ℕ, ∀ x, K U x ≤ K U' x + k ∧ K U' x ≤ K U x + k := by
  have hmem : sys U' ∈ computable := by
    obtain ⟨c, rfl⟩ := hU'
    exact ⟨c, rfl⟩
  have hdom : ∀ S ∈ computable, DescSystem.Dominates (sys U') S := by
    rintro _ ⟨c, rfl⟩
    obtain ⟨p, hp⟩ := hopt c
    exact ⟨p.length, K_le_add_of_prefix U' (run c) p hp⟩
  exact DescSystem.invariance computable sys_U_mem_computable hmem
    (fun S hS => U_dominates hS) hdom

/-- **Incompressibility**, for every description method: among the numbers below `2 ^ n`
one has complexity at least `n`. -/
theorem exists_incompressible_of (V : List Bool → Part ℕ) (n : ℕ) :
    ∃ x < 2 ^ n, (n : ℕ∞) ≤ K V x := by
  obtain ⟨x, hx, h⟩ := (sys_isBinary V).exists_incompressible (sys_functional V) n
    (Finset.range (2 ^ n)) (by simp)
  exact ⟨x, Finset.mem_range.1 hx, h⟩

/-- **Incompressibility**: for every `n` some number below `2 ^ n` has Kolmogorov
complexity at least `n`. -/
theorem exists_incompressible (n : ℕ) : ∃ x < 2 ^ n, (n : ℕ∞) ≤ K U x :=
  exists_incompressible_of U n

/-- **Compressible numbers are exponentially rare**: fewer than `2 ^ m` numbers have
Kolmogorov complexity below `m`. -/
theorem card_compressible_lt (m : ℕ) (A : Finset ℕ) [DecidablePred fun x => (sys U).K x < m] :
    (A.filter fun x => (sys U).K x < m).card < 2 ^ m :=
  (sys_isBinary U).card_compressible_lt (sys_functional U) m A

/-- The constant program for `x` describes `x` with the empty input. -/
theorem K_run_const (x : ℕ) : K (run (Code.const x)) x = 0 := by
  have h : x ∈ run (Code.const x) [] := by
    show x ∈ (Code.const x).eval (Encodable.encode ([] : List Bool))
    rw [Nat.Partrec.Code.eval_const]
    exact Part.mem_some x
  have h1 := K_le_length h
  simpa using h1

/-- **Every number is describable**: Kolmogorov complexity is finite. -/
theorem K_U_lt_top (x : ℕ) : K U x < ⊤ := by
  have h := K_U_le_add_encode (Code.const x) x
  rw [K_run_const, zero_add] at h
  exact lt_of_le_of_lt h (ENat.natCast_lt_top _)

/-- **A string's code costs at most its length plus a constant** (the literal description:
"print this"). -/
theorem K_U_encode_le : ∃ k : ℕ, ∀ l : List Bool, K U (Encodable.encode l) ≤ l.length + k := by
  obtain ⟨k, hk⟩ := K_U_le Code.id
  refine ⟨k, fun l => (hk (Encodable.encode l)).trans (add_le_add ?_ le_rfl)⟩
  refine K_le_length ?_
  show Encodable.encode l ∈ Code.id.eval (Encodable.encode l)
  rw [Nat.Partrec.Code.eval_id]
  exact Part.mem_some _

end Kolmogorov

end Complexity
