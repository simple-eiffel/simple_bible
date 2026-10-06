note
	description: "Pairings name their rules; split and merged verses list every target (AC-1a-16/17/18)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_VERSIFICATION

inherit
	TEST_SET_BASE

feature -- Tests

	test_one_to_many_pairing_names_every_rule
		local
			p: BIB_PAIRING
			targets: ARRAYED_LIST [BIB_REF]
			rules: ARRAYED_LIST [detachable BIB_MAPPING_RULE]
			rule: BIB_MAPPING_RULE
			prov: BIB_PROVENANCE
		do
			prov := fx.provenance (5, "TVTMS")
			create rule.make (1, {BIB_MAPPING_RULE}.Kind_split, "Num 16/17 (Swete)", "MT 17:1-15 = LXX 16:36-50", prov)
			create targets.make (2)
			targets.extend (fx.ref (4, 16, 36))
			targets.extend (fx.ref (4, 16, 37))
			create rules.make (2)
			rules.extend (rule)
			rules.extend (rule)
			create p.make_success (100, fx.kjv, targets, rules, "Num 16/17 split", fx.method ("pair"), <<prov>>)
			assert_integers_equal ("two targets", 2, p.target_count)
			assert_integers_equal ("every target ruled", 2, p.rules_count)
			assert ("closed", p.is_fact_closed)
		end

	test_identity_pairing_needs_no_rule
		local
			p: BIB_PAIRING
			targets: ARRAYED_LIST [BIB_REF]
			rules: ARRAYED_LIST [detachable BIB_MAPPING_RULE]
		do
			create targets.make (1)
			targets.extend (fx.ref (43, 3, 16))
			create rules.make (1)
			rules.extend (Void)
			create p.make_success (2501, fx.kjv, targets, rules, "identity", fx.method ("pair"), <<fx.provenance (5, "TVTMS")>>)
			assert_integers_equal ("one target", 1, p.target_count)
			assert_integers_equal ("no rule", 0, p.rules_count)
		end

	test_regression_set
			-- Skeletal (Phase 5, AC-1a-16): Ps 23:1/LXX 22:1; Mal 4:1/MT 3:19 (+ Swete); Jer 31:31/LXX 38:31;
			-- Lev 5/6; Deut 23; Num 16/17; Joel 2-4; Ps 9/10 and 118/119; psalm titles. Each names its rule.
		do
		end

	test_split_verse_counted_once_per_hub
			-- Skeletal (Phase 5, AC-1a-17): one-to-many returns every target with its rule; counts per hub id.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
