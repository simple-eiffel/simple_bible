note
	description: "Licenses, provenance, facts, methods, the license gate and fact closure (RQ-02)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PROVENANCE

inherit
	TEST_SET_BASE

feature -- Tests

	test_unknown_license_never_ships
		do
			assert ("unknown refused", not fx.unknown_license.may_ship_in_free_tool)
		end

	test_restricted_license_never_ships
		do
			assert ("restricted refused", not fx.ccat_restricted.may_ship_in_free_tool)
		end

	test_non_commercial_ships_in_free_tool
		do
			assert ("NC allowed (D-002)", fx.cc_by_nc.may_ship_in_free_tool)
			assert ("SA allowed", fx.cc_by_sa.may_ship_in_free_tool)
		end

	test_license_gate_rules
			-- AC-1a-03 engine side: unknown + ship fails; Rahlfs is ship = false; Swete ships.
		local
			l_gate: BIB_LICENSE_GATE
		do
			create l_gate.make
			assert ("unknown refused", not l_gate.ship_allowed (create {BIB_LICENSED_ITEM}.make ("MYSTERY", fx.unknown_license, True)))
			assert ("rahlfs not shipped", not l_gate.ship_allowed (create {BIB_LICENSED_ITEM}.make ("RAHLFS-CCAT", fx.ccat_restricted, False)))
			assert ("swete ships", l_gate.ship_allowed (create {BIB_LICENSED_ITEM}.make ("SWETE", fx.cc_by_sa, True)))
			assert ("unflagged pd not shipped", not l_gate.ship_allowed (create {BIB_LICENSED_ITEM}.make ("KJV", fx.public_domain, False)))
		end

	test_ai_provenance_carries_method_and_model
		local
			p: BIB_PROVENANCE
		do
			p := fx.ai_provenance
			assert ("ai", p.is_ai_made)
			assert ("method", not p.method_label.is_empty)
			assert ("model", p.model_id.same_string_general ("BAAI/bge-m3"))
		end

	test_fact_bound_to_provenance
		local
			f: BIB_FACT [INTEGER_64]
			p: BIB_PROVENANCE
		do
			p := fx.provenance (7, "SBLGNT")
			create f.make (114, p)
			assert ("value", f.value = 114)
			assert ("provenance", f.provenance = p)
		end

	test_method_states_scope
		local
			m: BIB_METHOD
		do
			m := fx.method ("concordance")
			assert ("scope stated", not m.scope_label.is_empty)
			assert ("rerunnable", m.is_rerunnable)
			assert ("counts equal self", m.counts_equal (fx.method ("concordance")))
		end

	test_fact_closure_holds_when_cited
		local
			r: BIB_LIST_RESULT [BIB_FACT [INTEGER_64]]
			p: BIB_PROVENANCE
		do
			p := fx.provenance (7, "SBLGNT")
			create r.make_success (fx.method ("concordance"), <<p>>, <<create {BIB_FACT [INTEGER_64]}.make (3, p)>>)
			assert ("success", r.is_success)
			assert ("closed", r.is_fact_closed)
		end

	test_fact_closure_detects_uncited_fact
		local
			r: BIB_LIST_RESULT [BIB_FACT [INTEGER_64]]
		do
			create r.make_success (fx.method ("concordance"), <<fx.provenance (7, "SBLGNT")>>,
				<<create {BIB_FACT [INTEGER_64]}.make (3, fx.provenance (8, "WLC"))>>)
			assert ("not closed", not r.is_fact_closed)
		end

	test_failed_result_carries_no_items
		local
			r: BIB_LIST_RESULT [BIB_FACT [INTEGER_64]]
		do
			create r.make_failure (fx.method ("concordance"), create {BIB_ERROR}.make ({BIB_ERROR}.Not_found, "nothing"))
			assert ("failed", not r.is_success)
			assert ("empty", r.count = 0)
			assert ("trivially closed", r.is_fact_closed)
		end

	test_license_gate_names_every_refusal
			-- Skeletal (Phase 5, AC-1a-02/03): check_items over a manifest-like list records every refused key
			-- and names each in the refusal message.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
