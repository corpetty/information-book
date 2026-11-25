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
#print axioms Monomial.exists_slK_gt_mul
#print axioms MonoidGen.poolK_insert_prod_pow_le
#print axioms MonoidGen.poolK_subsetProds_le
#print axioms MonoidGen.slK_prod_pow_add_one_le
#print axioms Monomial.slK_add_one_le_grouped
#print axioms Monomial.slK_add_one_le_log
#print axioms Monomial.exists_slK_between
#print axioms Monomial.exists_slK_between_1024
#print axioms Circuit.circuitK_le
#print axioms Circuit.exists_hard_function_between
#print axioms Circuit.circuitK_le_of_dependsOn
#print axioms Circuit.poolK_dependsOn_le
#print axioms Circuit.poolK_insert_select_le
#print axioms Circuit.circuitK_le_shannon
#print axioms Circuit.exists_circuitK_between
#print axioms Circuit.exists_circuitK_between_32
#print axioms Str.poolK_blocks_le
#print axioms Str.poolK_insert_le_div
#print axioms Str.strK_le_blocks
#print axioms Str.exists_strK_between
#print axioms Str.exists_strK_between_million
#print axioms SetUnion.counting_not_tight
#print axioms MonoidGen.poolK_prod_blocks_le
#print axioms MonoidGen.poolK_insert_prod_le_div
#print axioms MonoidGen.slK_list_prod_le_blocks
#print axioms Binary.depth_add_one_le
#print axioms Binary.depth_add_one_le_binK
#print axioms Comb.binK_comb
#print axioms Comb.counting_misses_depth
#print axioms Comb.card_sub_le_cost
#print axioms Comb.card_sub_bush
#print axioms Comb.obstructions_incomplete
#print axioms Monomial.exists_slK_between_general
#print axioms Monomial.exists_slK_between_4096
#print axioms Comb.poolK_closed_le
#print axioms Comb.cost_eq_card_sub
#print axioms Comb.cost_perfect
#print axioms Comb.binTreeK_perfect
#print axioms Comb.binTreeK_tree
#print axioms Comb.cost_le
#print axioms Binary.card_le_of_binK_le
#print axioms Str.card_cheap_lt
#print axioms MonoidGen.pk_digit_block_le
#print axioms MonoidGen.slK_prod_pow_le_digits
#print axioms Monomial.slK_le_digits
#print axioms Monomial.slK_le_many_atoms
#print axioms Monomial.two_mul_le_slK_add_one
#print axioms Monomial.exists_slK_every_shape
#print axioms SetUnion.counting_hypothesis_one
#print axioms Comb.binTreeK_comb
#print axioms Binary.clog_add_one_le
#print axioms Monomial.sum_mul_two_le_two_pow
#print axioms Plain.not_subadditive_plain
#print axioms Plain.card_le_two_pow_of_prefixFree
#print axioms Monomial.slK_le_order
#print axioms Monomial.exists_slK_gt_order
#print axioms Monomial.exists_slK_gt_exponent
#print axioms Limits.leak_iterate
#print axioms Plain.dominated_not_all_partrec
#print axioms Plain.mem_range_run_iff
#print axioms Plain.not_coding_self_delimiting
#print axioms Circuit.exists_hard_eight
#print axioms KraftChaitin.exists_machine
#print axioms PrefixMachine.U_isPrefixMachine
#print axioms PrefixMachine.U_simulates
#print axioms PrefixMachine.dominates
#print axioms PrefixMachine.invariance
#print axioms PrefixMachine.K_pair_le
#print axioms PrefixMachine.K_map_le'
#print axioms PrefixMachine.K_map_equiv
#print axioms PrefixMachine.K_fst_le
#print axioms PrefixMachine.K_pair_comm
#print axioms PrefixMachine.K_pair_map_le
#print axioms PrefixMachine.K_U_lt_top
#print axioms Levin.exists_coding_machine
#print axioms Levin.levin
#print axioms Levin.P_le_two_pow_mul_wt
#print axioms Levin.P_pos
#print axioms Levin.K_U_le_log
#print axioms Conditional.condU_simulates
#print axioms Conditional.condK_le
#print axioms Conditional.exists_dep_machine
#print axioms Conditional.K_pair_le_add_condK
#print axioms Conditional.K_le_add_condK
#print axioms Conditional.condK_le_K
#print axioms Conditional.condK_map_le
#print axioms Conditional.condK_le_length
#print axioms Conditional.K_twoPart_le
#print axioms Conditional.exists_condK_ge
#print axioms Conditional.K_iterate_le
#print axioms Conditional.K_iterate_le_log
#print axioms KraftChaitin.machine_partrec₂
#print axioms Levin.P_le_two_pow_mul_wt_of
#print axioms Symmetry.tsum_P_pair_le
#print axioms Symmetry.K_add_condK_star_le
#print axioms Symmetry.K_pair_le_add_condK_star
#print axioms Symmetry.symmetry_of_information
#print axioms Symmetry.symmetry
#print axioms Symmetry.K_macro_add_condK_le
#print axioms Symmetry.card_K_lt_macro_add
#print axioms Symmetry.micro_eq_macro_add_log
#print axioms Upper.exists_approx
#print axioms Upper.exists_machine_K_eq
#print axioms Upper.prefix_complexity_iff
#print axioms Upper.K_U_le_of_summable
#print axioms Upper.exists_primrec_table
#print axioms Upper.prefix_complexity_iff_of_computable
#print axioms Upper.K_U_le_of_computable
#print axioms Upper.exists_table_iff_re
#print axioms Guessing.exists_wrong_guess
#print axioms Guessing.K_U_not_computable
#print axioms Guessing.condK_K_unbounded
#print axioms Guessing.condK_star_add_lt
#print axioms Guessing.not_symmetry_bare
#print axioms Conditional.exists_cond_dep_machine
#print axioms Conditional.condK_chain_le
#print axioms Guessing.condK_le_condK_star_add
#print axioms Guessing.symmetry_bare_log
#print axioms Lossy.loadWithin_le_add_of_prefix
#print axioms Lossy.delivers_iff_loadWithin
#print axioms Lossy.externalCoveringNumber_lt_of_delivers_chain
#print axioms Lossy.exists_relay_iff
#print axioms Lossy.loadWithin_eq_iInf_load
#print axioms Lossy.orbit_repeats
#print axioms Lossy.merging_stops
#print axioms Lossy.exists_not_delivered_of_packing
#print axioms Lossy.not_both_delivered
#print axioms Lossy.edist_chain_le
#print axioms Lossy.Nat.budget_iff
#print axioms Lossy.Nat.delivers_iff
#print axioms Lossy.Nat.exists_drifting_chain
#print axioms Lossy.Nat.swapRelay_pass
#print axioms Lossy.Nat.decRelay_iterate
#print axioms Lossy.Nat.decRelay_merges_late
#print axioms Noisy.spread_mulVec_le
#print axioms Noisy.advantage_le
#print axioms Noisy.advantage_le_pow
#print axioms Noisy.guess_le
#print axioms Noisy.chain_fade
#print axioms Noisy.advantage_fade
#print axioms Noisy.chain_detHop
#print axioms Noisy.advantage_detHop
#print axioms Noisy.prob_detHop_eq
#print axioms Noisy.forgets_detHop
#print axioms Noisy.two_routes
#print axioms Noisy.two_routes_beat_one
#print axioms Noisy.two_routes_no_gain_bool
#print axioms Noisy.survive_le
#print axioms Noisy.intact_pow_le_chain
#print axioms Noisy.prob_fade_self
#print axioms Noisy.forgets_of_one_le
#print axioms Noisy.forgets_const
#print axioms Noisy.detHop_dichotomy
#print axioms Noisy.fade_eq_mixture
#print axioms Limits.leak_iterate_length
#print axioms Noisy.Forgets.contracts
#print axioms Noisy.spread_mulVec_le_of_contracts
#print axioms Noisy.advantage_le_of_contracts
#print axioms Noisy.advantage_le_pow_of_contracts
#print axioms Noisy.two_mul_sub_one_le_of_contracts
#print axioms Noisy.one_le_of_contracts_detHop
#print axioms Noisy.lazyCycle_contracts
#print axioms Noisy.lazyCycle_not_forgets
#print axioms Noisy.advantage_lazyCycle
#print axioms Noisy.two_routes_le
#print axioms Noisy.two_routes_le_pow
#print axioms Noisy.contracts_one
#print axioms Noisy.intact_prod_le_chain
#print axioms Noisy.lazyCycle_least
#print axioms Noisy.lazyCycle_two_hops
#print axioms Noisy.lazyFour_not_contracts
#print axioms Noisy.lazyFour_two_hops
#print axioms Noisy.swap_keeps_nothing
#print axioms Plain.exists_ambiguous_binary
#print axioms Plain.P_plain_eq_top
#print axioms Plain.condC_le
#print axioms Plain.not_chain_rule_plain

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
