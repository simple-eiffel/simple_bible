note
	description: "Reference parse outcomes (FR-020, AC-1a-15) and the reference detector."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_REFERENCE_PARSER

inherit
	TEST_SET_BASE

feature -- Tests

	test_ambiguous_outcome_keeps_every_candidate
			-- "Ju 1": Judges 1 and Jude 1, never a guess.
		local
			r: BIB_PARSE_RESULT
			l: ARRAYED_LIST [BIB_REF]
		do
			create l.make (2)
			l.extend (fx.ref (7, 1, 1))
			l.extend (fx.ref (65, 1, 1))
			create r.make_ambiguous (l)
			assert ("ambiguous", r.is_ambiguous and not r.is_valid and not r.is_invalid)
			assert_integers_equal ("both candidates", 2, r.candidate_count)
			assert ("no reference chosen", r.ref = Void)
		end

	test_invalid_outcome_is_located
		local
			r: BIB_PARSE_RESULT
		do
			create r.make_invalid (4, "unknown book")
			assert ("invalid", r.is_invalid)
			assert_integers_equal ("position", 4, r.error_position)
		end

	test_valid_outcome_names_system
		local
			r: BIB_PARSE_RESULT
		do
			create r.make_valid (fx.ref (43, 3, 16), Void)
			assert ("valid", r.is_valid)
			assert ("system named", attached r.system as s and then s.code = {BIB_VERSIFICATION_SYSTEM}.Kjv)
		end

	test_parser_case_suite
			-- Skeletal (Phase 5, AC-1a-15): the 300+ case suite from testing/fixtures.
		do
		end

	test_ju_and_ph_are_ambiguous
			-- Skeletal (Phase 5, AC-1a-15): "Ju 1" and "Ph 1" give at least two candidates and no version text.
		do
		end

	test_detector_matches_r12_golden
			-- Skeletal (Phase 5, D-020): BIB_REFERENCE_DETECTOR equals build_rix_db.py R12 on the golden fixture.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
