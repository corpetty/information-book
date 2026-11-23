import Complexity

/-!
# Axiom audit

Run with `./lake.sh env lean Audit.lean`. Every line should report only Lean's three
standard axioms (`propext`, `Classical.choice`, `Quot.sound`) – no `sorryAx`, nothing else.

The `#print axioms` lines cover the headline results. The `#audit_library` command at the
end covers *every* declaration of the library and fails if any of them depends on anything
else, or if the library declares an axiom or an opaque constant.
-/

open Complexity

-- The laws
#print axioms Law.fidelity
#print axioms Law.transport
#print axioms Law.conservation
#print axioms Law.duality
#print axioms Law.bellman
#print axioms Law.counting
#print axioms Law.reuse
#print axioms Law.logarithm
#print axioms Law.counting_reuse
#print axioms Law.invariance

-- Core results not restated in `Laws`
#print axioms DescSystem.IsBinary.exists_incompressible
#print axioms DescSystem.exists_index_system
#print axioms dist_triangle
#print axioms dist_comm
#print axioms isGreatest_dist
#print axioms exists_hop_gt
#print axioms nsmul_le_dist
#print axioms Sig.bellman_treeK
#print axioms Sig.treeK_map_le
#print axioms Sig.poolK_union_le
#print axioms DescSystem.profile_eq_K
#print axioms DescSystem.slackMin_anti
#print axioms Thermo.pow_le_Z_of_K_le
#print axioms Thermo.card_le_two_pow_of_K_le
#print axioms Thermo.Z_le_tail
#print axioms Dynamics.K_iterate_le
#print axioms Dynamics.card_times_compressible_lt

-- Instances
#print axioms Kolmogorov.U_mem_range
#print axioms Kolmogorov.K_U_le
#print axioms Kolmogorov.invariance
#print axioms Kolmogorov.exists_incompressible
#print axioms Shannon.entropy_le_K_le
#print axioms Circuit.circuitK_le_formulaK
#print axioms Circuit.exists_hard_function
#print axioms Chain.chainK_two_pow_le
#print axioms Chain.two_mul_le_two_pow
#print axioms Chain.two_pow_le_treeK
#print axioms Str.length_mul_two_le
#print axioms CoarseGraining.exists_twoPart
#print axioms Causal.K_eq_ncard
#print axioms Regulator.requisite_variety
#print axioms Learning.vcDim_le_of_K_le
#print axioms Channel.card_lt_of_load_le
#print axioms Channel.Relay.card_image_chain_lt
#print axioms Channel.exists_loss_ge

-- The limits (results proved against the theory)
#print axioms Limits.exists_system_K_eq
#print axioms Limits.dist_complete_eq
#print axioms Limits.exists_binary_iff
#print axioms Limits.dominates_iff_pointwise
#print axioms Limits.not_iterate_bound_kolmogorov
#print axioms Limits.not_twoPart_bound_kolmogorov
#print axioms Limits.exists_complex_probable
#print axioms Limits.relay_iterate_saturates

-- The repair pass: translations, self-delimiting systems, the reuse gap
#print axioms DescSystem.invariance_of_simulates
#print axioms DescSystem.exists_dominates_not_simulates
#print axioms DescSystem.not_exists_universal
#print axioms Prefix.exists_prefix_iff
#print axioms Prefix.exists_coding
#print axioms Prefix.coding_of_dominates
#print axioms Prefix.pair
#print axioms Prefix.iterate
#print axioms Prefix.twoPart_card
#print axioms Prefix.not_exists_universal
#print axioms Binary.binTreeK_add_one_le_two_pow
#print axioms Binary.binTreeK_add_one_eq
#print axioms Chain.treeK_eq
#print axioms Str.treeK_eq
#print axioms Str.exists_low_gain
#print axioms Binary.two_mul_card_support_le_binK
#print axioms Binary.binK_eq_binTreeK_of_le
#print axioms Binary.gain_le_multiplicity
#print axioms SetUnion.binK_add_one_eq
#print axioms Str.strK_add_one_eq_of_nodup
#print axioms Circuit.two_mul_card_essential_le
#print axioms MonoidGen.slK_pow_le
#print axioms Monomial.slK_add_one_le
#print axioms Monomial.exists_slK_gt
#print axioms KraftChaitin.exists_machine
#print axioms PrefixMachine.U_isPrefixMachine
#print axioms PrefixMachine.U_simulates
#print axioms PrefixMachine.dominates
#print axioms PrefixMachine.invariance
#print axioms PrefixMachine.K_pair_le
#print axioms PrefixMachine.K_U_lt_top
#print axioms Levin.exists_coding_machine
#print axioms Levin.levin
#print axioms Levin.P_le_two_pow_mul_wt
#print axioms Levin.P_pos

/-! ### Every declaration -/

open Lean Elab Command in
/-- Collect the axioms behind every constant declared in a `Complexity.*` module and fail
unless all of them are among Lean's three standard axioms. -/
elab "#audit_library" : command => do
  let env ← getEnv
  let std : List Name := [``propext, ``Classical.choice, ``Quot.sound]
  let mut total : Nat := 0
  let mut theorems : Nat := 0
  let mut bad : Array String := #[]
  for (c, ci) in env.constants.map₁.toList do
    let some idx := env.getModuleIdxFor? c | continue
    unless (`Complexity).isPrefixOf env.header.moduleNames[idx.toNat]! do continue
    total := total + 1
    match ci with
    | .axiomInfo _ => bad := bad.push s!"axiom declared: {c}"
    | .opaqueInfo _ => bad := bad.push s!"opaque declared: {c}"
    | .thmInfo _ => theorems := theorems + 1
    | _ => pure ()
    let extra := (← liftCoreM (Lean.collectAxioms c)).toList.filter fun a => !std.contains a
    unless extra.isEmpty do bad := bad.push s!"{c} depends on {extra}"
  unless bad.isEmpty do
    throwError "audit failed:\n{String.intercalate "\n" bad.toList}"
  logInfo m!"audit passed: {total} declarations ({theorems} theorems, including generated \
    ones) depend only on propext, Classical.choice and Quot.sound"

#audit_library
