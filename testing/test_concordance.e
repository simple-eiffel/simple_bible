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

	test_word_view_lists_every_fact
			-- Skeletal (Phase 5, scan 23): a word view's facts_model holds its entry,
			-- its place total and every row of its first page, so fact closure is
			-- tested against real facts. (The value classes cannot be built until
			-- Phase 4, so this cannot run yet.)
		do
		end

	test_pack_not_valid_until_checked
			-- A new pack reader has validated nothing, so it is unavailable even before
			-- anything is attached (Phase 2 review, ruling 3.3: `check_pack' runs once,
			-- at attach; `is_available' runs no SQL).
		local
			l_pack: BIB_CONC_PACK
		do
			create l_pack.make (create {BIB_SOURCE_SET}.make)
			assert ("not validated", not l_pack.is_pack_valid)
			assert ("not available", not l_pack.is_available)
		end

	test_fixture_has_the_reviewed_shapes
			-- The fixture pack (Task 2) attaches read-only and holds what the Phase 2
			-- review named: version 1, every v1 table, an empty Hebrew surface, an
			-- English computed basis, a Strong's row and more than a page of places.
			-- The refusal variant really lacks its table and its version.
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_schema: SIMPLE_SQL_SCHEMA
		do
			create l_fixture
			l_fixture.build_main (Main_file)
			l_fixture.build (Pack_file)
			l_fixture.build_variant (Old_pack_file, 0, "lemma_english")
			create l_set.make
			l_set.open_core (Main_file)
			l_set.attach ("conc", Pack_file)
			l_set.attach ("old", Old_pack_file)
			assert_true ("both attached", l_set.last_error = Void and l_set.attached_count = 2)
			if attached l_set.database as al_db then
				create l_schema.make (al_db)
				assert_integers_equal ("version", {CONC_FIXTURE}.Pack_version, l_schema.user_version_of ("conc"))
				assert_true ("v1 table", l_schema.table_exists_in ("conc", "lemma_english"))
				assert_integers_equal ("old version", 0, l_schema.user_version_of ("old"))
				assert_false ("old lacks table", l_schema.table_exists_in ("old", "lemma_english"))
				assert_integers_equal ("empty hebrew surface", 1, count_of (al_db, "SELECT count(*) AS n FROM conc.token WHERE language = 'hbo' AND surface = ''"))
				assert_integers_equal ("english computed", 1, count_of (al_db, "SELECT count(*) AS n FROM conc.token WHERE language = 'eng' AND lemma_basis LIKE 'computed:%%'"))
				assert_integers_equal ("strongs row", 1, count_of (al_db, "SELECT count(*) AS n FROM conc.lemma_xref WHERE scheme = 'strongs' AND value = 'H1254'"))
				assert_integers_equal ("article places", {CONC_FIXTURE}.Article_places, count_of (al_db, "SELECT count(*) AS n FROM conc.token WHERE lemma_id = 2"))
				assert_true ("more than a page", {CONC_FIXTURE}.Article_places > {BIB_CONC_PACK}.Max_page_size)
				assert_integers_equal ("counts table agrees", {CONC_FIXTURE}.Article_places, count_of (al_db, "SELECT n FROM conc.lemma_corpus_count WHERE lemma_id = 2"))
			else
				assert_true ("connection when open", False)
			end
			l_set.close
			l_fixture.delete_file (Main_file)
			l_fixture.delete_file (Pack_file)
			l_fixture.delete_file (Old_pack_file)
		end

	test_language_codes
			-- One table of language codes (design scan 25): Hebrew and Aramaic are Hebrew
			-- script, the three originals are original, English is held but not original.
		local
			l_codes: BIB_LANGUAGE_CODES
		do
			create l_codes
			assert ("hbo hebrew script", l_codes.is_hebrew_script ("hbo"))
			assert ("arc hebrew script", l_codes.is_hebrew_script ("arc"))
			assert ("grc not hebrew script", not l_codes.is_hebrew_script ("grc"))
			assert ("grc original", l_codes.is_original ("grc"))
			assert ("eng not original", not l_codes.is_original ("eng"))
			assert ("eng held", l_codes.is_concordance_language ("eng"))
			assert ("lat not held", not l_codes.is_concordance_language ("lat"))
		end

	test_reattached_pack_needs_a_new_check
			-- Skeletal (Phase 4, Task 3; design scan 25): after `check_pack' accepts a pack,
			-- detaching it through the shared source set and attaching another file under
			-- "conc" leaves the reader unavailable until `check_pack' runs again. Needs the
			-- real `attach' (Task 1), so it cannot run on the skeleton.
		do
		end

	test_verse_word_takes_real_hebrew_rows
			-- Skeletal (Phase 4, Phase 2 review rulings 1.1 and 1.2): a verse word builds
			-- from conc.db's real shapes: a Hebrew token with an empty surface and no
			-- transliteration (6,435 such tokens, WLC-MACULA), and the stored basis
			-- "tagged:MACULA-Hebrew" mapped to the kind "tagged". The creators that came
			-- before the review refused both.
		do
		end

	test_verse_word_takes_english_computed_rows
			-- Skeletal (Phase 4, rulings 1.1 and 1.2): an English token (language "eng",
			-- basis "computed:spacy-lemma" mapped to "computed", no transliteration)
			-- builds a verse word and a place row.
		do
		end

	test_edition_swap_needs_no_code
			-- Skeletal (Phase 5, FR-158, V-54): the same executable reads conc.db and
			-- conc_dist.db by `conc_path' alone; no engine code tests the edition.
		do
		end

feature {NONE} -- Fixture

	Main_file: STRING = "conc_test_main.db"
	Pack_file: STRING = "conc_test_pack.db"
	Old_pack_file: STRING = "conc_test_old_pack.db"

	count_of (a_db: SIMPLE_SQL_DATABASE; a_sql: STRING): INTEGER
			-- The single integer `a_sql' returns (its column is named n).
		local
			l_result: SIMPLE_SQL_RESULT
		do
			l_result := a_db.query (a_sql)
			if not l_result.rows.is_empty and then attached l_result.rows.first as al_row then
				Result := al_row.integer_value ("n")
			end
		end

end
