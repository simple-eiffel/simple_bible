note
	description: "Shape tiers and findings: T3 never evidence; absent tags give NO_DATA (AC-1a-25, 26)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SHAPES

inherit
	TEST_SET_BASE

feature -- Tests

	test_t3_is_judgment
		do
			assert ("T3 judgment", (create {BIB_SHAPE_TIER}.make ({BIB_SHAPE_TIER}.T3)).is_judgment)
			assert ("T2 not judgment", not (create {BIB_SHAPE_TIER}.make ({BIB_SHAPE_TIER}.T2)).is_judgment)
		end

	test_t3_finding_is_never_evidence
		local
			f: BIB_SHAPE_FINDING
		do
			create f.make_shape (fx.ref (58, 11, 3), 29900, create {BIB_VERDICT}.make_fits, "pattern holds", "", False,
				fx.provenance (21, "SHAPE"), create {BIB_SHAPE_TIER}.make ({BIB_SHAPE_TIER}.T3), "verse", "")
			assert ("not evidence", not f.is_evidence)
			create f.make_shape (fx.ref (58, 11, 3), 29900, create {BIB_VERDICT}.make_fits, "pattern holds", "", False,
				fx.provenance (21, "SHAPE"), create {BIB_SHAPE_TIER}.make ({BIB_SHAPE_TIER}.T1), "verse", "")
			assert ("T1 is evidence", f.is_evidence)
		end

	test_candidate_reports_missing_tags
		local
			c: BIB_SHAPE_CANDIDATE
		do
			create c.make (fx.ref (49, 4, 12), 29100)
			c.put_tag ("lemma", "katartismos")
			assert ("lemma present", c.has_required_tags (<<"lemma">>))
			assert ("domain absent", not c.has_required_tags (<<"lemma", "ln_domain">>))
		end

	test_registry_starts_empty
		local
			r: BIB_SHAPE_REGISTRY
		do
			create r.make
			assert_integers_equal ("empty", 0, r.count)
			assert ("no slug", not r.has_slug ("telos"))
		end

	test_evidence_refuses_t3
			-- Skeletal (Phase 5, AC-1a-25): BIB_SHAPE_ENGINE.evidence on a T3 shape violates `not_judgment'.
		do
		end

	test_shape_differential
			-- Skeletal (Phase 5, AC-1a-26): each shipped shape equals shape_db.py's golden on the frozen fixture;
			-- Louw-Nida domains from UBS SDGNT.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
