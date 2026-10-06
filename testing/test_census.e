note
	description: "Census definitions (written before counting), four buckets, cancelled runs (AC-1a-17, 24, 25, 37)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CENSUS

inherit
	TEST_SET_BASE

feature -- Tests

	test_definition_starts_editable
		local
			d: BIB_CENSUS_DEFINITION
		do
			d := new_definition
			assert_integers_equal ("version 1", 1, d.version)
			assert ("editable", not d.is_frozen)
			assert ("unstored", not d.is_stored)
			assert ("seeded", d.control_seed /= 0)
		end

	test_setters_keep_frames
		local
			d: BIB_CENSUS_DEFINITION
		do
			d := new_definition
			d.add_control (create {BIB_LEMMA_KEY}.make ("grc", "synagoge"))
			d.set_question ("Does ekklesia cluster in Paul beyond its band?")
			assert_integers_equal ("control kept", 1, d.controls_count)
			assert ("question set", d.question.has_substring ("Paul"))
			d.set_holds_if ("target rate exceeds every control's rate")
			d.set_fails_if ("target rate within the controls' range")
			assert ("holds kept", d.holds_if.has_substring ("exceeds"))
		end

	test_definition_completeness
		local
			d: BIB_CENSUS_DEFINITION
		do
			d := complete_definition
			assert ("complete", d.is_complete)
		end

	test_mark_stored_starts_lineage
		local
			d: BIB_CENSUS_DEFINITION
		do
			d := new_definition
			d.mark_stored (12, 12)
			assert ("stored", d.is_stored)
			assert ("lineage", d.lineage_id = 12)
		end

	test_bucketed_result_has_four_buckets
		local
			b: BIB_BUCKETED_RESULT [BIB_FINDING]
		do
			create b.make (12)
			assert_integers_equal ("fits", 0, b.count (create {BIB_VERDICT}.make_fits))
			assert_integers_equal ("partial", 0, b.count (create {BIB_VERDICT}.make_partial))
			assert_integers_equal ("fails", 0, b.count (create {BIB_VERDICT}.make_fails))
			assert_integers_equal ("no data", 0, b.count (create {BIB_VERDICT}.make_no_data))
			assert_integers_equal ("total", 0, b.total)
			assert_integers_equal ("reporting order", 4, b.all_verdicts.count)
		end

	test_cancelled_run_has_no_findings
		local
			d: BIB_CENSUS_DEFINITION
			r: BIB_CENSUS_RUN
		do
			d := complete_definition
			d.mark_stored (5, 5)
			create r.make_cancelled (d, fx.method ("census"))
			assert ("cancelled", r.was_cancelled)
			assert ("not a success", not r.is_success)
			assert_integers_equal ("no findings", 0, r.buckets.total)
			assert ("no verdict", r.control_verdict = Void)
		end

	test_freeze_at_first_run
			-- Skeletal (Phase 5, AC-1a-24): the first run freezes; any setter then violates `not_frozen'.
		do
		end

	test_new_version_increments
			-- Skeletal (Phase 5, AC-1a-24): new_version = version + 1, same lineage, editable.
		do
		end

	test_rerun_identical_counts_and_controls
			-- Skeletal (Phase 5, AC-1a-24): same definition, same edition, identical counts and controls.
		do
		end

	test_no_data_kept_apart_from_fails
			-- Skeletal (Phase 5, AC-1a-25): the Heb 11:3 / Eph 4:12 regression keeps NO_DATA apart from FAILS.
		do
		end

	test_counts_per_canonical_hub
			-- Skeletal (Phase 5, AC-1a-17): Num 16/17, Joel 2-3, Mal 3/4, psalm titles counted once per hub id.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

	scope: BIB_SEARCH_SCOPE
		do
			create Result.make ("Pauline letters, SBLGNT, word tokens", <<"SBLGNT">>, 45, 57, "word tokens")
		end

	new_definition: BIB_CENSUS_DEFINITION
		do
			create Result.make ("Does ekklesia cluster in Paul?", scope)
		end

	complete_definition: BIB_CENSUS_DEFINITION
		local
			l_target: BIB_LEMMA_KEY
		do
			Result := new_definition
			create l_target.make ("grc", "ekklesia")
			Result.set_criteria (create {BIB_QUERY}.make_valid ("lemma:ekklesia",
				<<create {BIB_QUERY_CLAUSE}.make_key ({BIB_QUERY_CLAUSE}.Lemma, l_target)>>, scope))
			Result.add_control (create {BIB_LEMMA_KEY}.make ("grc", "synagoge"))
			Result.set_holds_if ("target rate exceeds every control's rate")
			Result.set_fails_if ("target rate within the controls' range")
		end

end
