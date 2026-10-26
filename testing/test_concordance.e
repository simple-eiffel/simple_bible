note
	description: "[
		The concordance cluster (D-021, debate 05b pathway B): the pack reader's
		fixed rules now; the three lookups once Phase 5 brings a small conc.db
		fixture. Name proposed by the 2026-10-26 spec fold; fixed in Phase 4.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CONCORDANCE

inherit
	TEST_SET_BASE

feature -- Tests

	test_pack_absent_until_attached
			-- With nothing attached as "conc", the pack reports itself unavailable,
			-- so no lookup can run (every lookup requires `is_available').
		local
			l_pack: BIB_CONC_PACK
		do
			create l_pack.make (create {BIB_SOURCE_SET}.make)
			assert ("not available", not l_pack.is_available)
		end

	test_pack_rules
			-- The pack attaches under one alias, and a page holds at most 200 rows
			-- (FR-159; the spike's first page of 200 took 25-28 ms).
		do
			assert_strings_equal ("alias", "conc", {BIB_CONC_PACK}.Pack_alias)
			assert_integers_equal ("page size", 200, {BIB_CONC_PACK}.Max_page_size)
		end

	test_word_view_in_pilot_order
			-- Skeletal (Phase 5, FR-150/FR-152 order): the word view's sections come in
			-- the pilot's approved order over the conc.db fixture.
		do
		end

	test_english_lookup_counts_per_bible
			-- Skeletal (Phase 5, FR-151): an English word lists the original words
			-- behind it, Bible by Bible, with counts that sum to the word's places.
		do
		end

	test_verse_lookup_every_corpus
			-- Skeletal (Phase 5, FR-152): a reference lists every word of the verse in
			-- every corpus the pack holds, each with its headword.
		do
		end

	test_edition_swap_needs_no_code
			-- Skeletal (Phase 5, FR-158, V-54): the same executable reads conc.db and
			-- conc_dist.db by `conc_path' alone; no engine code tests the edition.
		do
		end

end
