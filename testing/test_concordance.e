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

	test_pack_accepts_the_fixture
			-- A v1 pack is accepted once, at attach; its corpora, layers and edition label are
			-- then read without SQL (Task 3, FR-164, FR-158).
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
		do
			create l_fixture
			l_set := attached_set (l_fixture, Pack_file, {CONC_FIXTURE}.Pack_version, "")
			create l_pack.make (l_set)
			l_pack.check_pack
			assert_true ("accepted", l_pack.is_available and l_pack.pack_error = Void)
			assert_true ("lxx corpus", l_pack.has_corpus ("LXX-RAHLFS"))
			assert_false ("unknown corpus", l_pack.has_corpus ("XYZ"))
			assert_true ("lxx layer", l_pack.has_layer ("lxx"))
			assert_true ("bsb layer", l_pack.has_layer ("bsb"))
			assert_true ("dictionaries layer", l_pack.has_layer ("dictionaries"))
			assert_false ("unknown layer", l_pack.has_layer ("targum"))
			assert_strings_equal ("edition from the pack", {CONC_FIXTURE}.Edition_label, l_pack.edition_label)
			close_and_clean (l_set, l_fixture)
		end

	test_pack_refuses_an_old_version
			-- A pack at another user_version is refused with the reason (FR-164, FR-165).
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
		do
			create l_fixture
			l_set := attached_set (l_fixture, Pack_file, 0, "")
			create l_pack.make (l_set)
			l_pack.check_pack
			assert_false ("refused", l_pack.is_available)
			assert_true ("version named", attached l_pack.pack_error as al_error and then al_error.code = {BIB_ERROR}.Schema_mismatch and then al_error.message.has_substring ("version 0"))
			close_and_clean (l_set, l_fixture)
		end

	test_pack_refuses_a_missing_table
			-- A pack without one of the v1 tables is refused, naming the table.
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
		do
			create l_fixture
			l_set := attached_set (l_fixture, Pack_file, {CONC_FIXTURE}.Pack_version, "lemma_english")
			create l_pack.make (l_set)
			l_pack.check_pack
			assert_false ("refused", l_pack.is_available)
			assert_true ("table named", attached l_pack.pack_error as al_error and then al_error.message.has_substring ("lemma_english"))
			close_and_clean (l_set, l_fixture)
		end

	test_pack_refuses_a_file_that_is_not_a_database
			-- A text file attached as the pack is refused, at attach or at the check.
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
			l_file: PLAIN_TEXT_FILE
		do
			create l_fixture
			l_fixture.build_main (Main_file)
			create l_file.make_create_read_write (Pack_file)
			l_file.put_string ("This is not a SQLite database, only text long enough to fill a page header.")
			l_file.close
			create l_set.make
			l_set.open_core (Main_file)
			l_set.attach ({BIB_CONC_PACK}.Pack_alias, Pack_file)
			if l_set.last_error = Void then
				create l_pack.make (l_set)
				l_pack.check_pack
				assert_false ("refused at the check", l_pack.is_available)
				assert_true ("reason given", l_pack.pack_error /= Void)
			else
				assert_integers_equal ("refused at attach", 0, l_set.attached_count)
			end
			close_and_clean (l_set, l_fixture)
		end

	test_reattached_pack_needs_a_new_check
			-- After `check_pack' accepts a pack, detaching it through the shared source set and
			-- attaching another file under "conc" leaves the reader unavailable until it is
			-- checked again (design scan 25).
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
		do
			create l_fixture
			l_set := attached_set (l_fixture, Pack_file, {CONC_FIXTURE}.Pack_version, "")
			l_fixture.build (Other_pack_file)
			create l_pack.make (l_set)
			l_pack.check_pack
			assert_true ("first accepted", l_pack.is_available)
			l_set.detach ({BIB_CONC_PACK}.Pack_alias)
			l_set.attach ({BIB_CONC_PACK}.Pack_alias, Other_pack_file)
			assert_true ("other attached", l_set.last_error = Void and l_pack.is_attached)
			assert_false ("not available until checked", l_pack.is_available)
			l_pack.check_pack
			assert_true ("available after its own check", l_pack.is_available)
			close_and_clean (l_set, l_fixture)
		end

	test_same_path_reattach_needs_a_new_check
			-- A pack rebuilt at the same path and attached again is a different pack: the
			-- reader is unavailable until it checks it (design scan 27; scan 25 compared paths only).
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
		do
			create l_fixture
			l_set := attached_set (l_fixture, Pack_file, {CONC_FIXTURE}.Pack_version, "")
			create l_pack.make (l_set)
			l_pack.check_pack
			assert_true ("first accepted", l_pack.is_available)
			l_set.detach ({BIB_CONC_PACK}.Pack_alias)
			l_fixture.build_variant (Pack_file, 0, "")
			l_set.attach ({BIB_CONC_PACK}.Pack_alias, Pack_file)
			assert_true ("same path attached", l_set.last_error = Void and l_pack.is_attached)
			assert_false ("not available until checked", l_pack.is_available)
			l_pack.check_pack
			assert_false ("the rebuilt pack is refused", l_pack.is_available)
			close_and_clean (l_set, l_fixture)
		end

	test_pack_refuses_unreadable_facts
			-- A pack whose facts cannot be read (the corpus table lacks its code column) is
			-- refused, never accepted with an empty corpus list (design scan 27).
		local
			l_fixture: CONC_FIXTURE
			l_set: BIB_SOURCE_SET
			l_pack: BIB_CONC_PACK
			l_db: SIMPLE_SQL_DATABASE
		do
			create l_fixture
			l_fixture.build_main (Main_file)
			l_fixture.build (Pack_file)
			create l_db.make (Pack_file)
			l_db.execute ("ALTER TABLE corpus RENAME COLUMN code TO corpus_code")
			l_db.close
			create l_set.make
			l_set.open_core (Main_file)
			l_set.attach ({BIB_CONC_PACK}.Pack_alias, Pack_file)
			create l_pack.make (l_set)
			l_pack.check_pack
			assert_false ("refused", l_pack.is_available)
			assert_true ("reason given", attached l_pack.pack_error as al_error and then al_error.code = {BIB_ERROR}.Database_problem)
			close_and_clean (l_set, l_fixture)
		end

	test_word_entry_reads_the_heading
			-- An original headword comes back with its transliteration, pronunciation and the
			-- provenance of the corpus it is tagged in; English lemmas and unknown ids give Void.
		local
			l_fixture: CONC_FIXTURE
			l_pack: BIB_CONC_PACK
		do
			create l_fixture
			l_pack := checked_pack (l_fixture)
			if attached l_pack.word_entry ({CONC_FIXTURE}.Create_lemma) as al_entry then
				assert_strings_equal ("headword", "BRA", al_entry.headword)
				assert_strings_equal ("translit", "bara", al_entry.translit)
				assert_strings_equal ("pron", "baw-RAW", al_entry.pron)
				assert_strings_equal ("provenance from its corpus", "conc:WLC-MACULA", al_entry.provenance.source_key)
			else
				assert_true ("entry found", False)
			end
			assert_true ("english lemma is no headword", l_pack.word_entry ({CONC_FIXTURE}.English_lemma) = Void)
			assert_true ("unknown id", l_pack.word_entry (999) = Void)
			close_and_clean (last_pack_set, l_fixture)
		end

	test_headwords_for_strongs_go_through_xref
			-- A Strong's number finds its headwords only through lemma_xref (FR-153); padding does
			-- not matter; an unknown number is a successful empty answer.
		local
			l_fixture: CONC_FIXTURE
			l_pack: BIB_CONC_PACK
			l_answer: BIB_LIST_RESULT [BIB_WORD_ENTRY]
		do
			create l_fixture
			l_pack := checked_pack (l_fixture)
			l_answer := l_pack.headwords_for_strongs (create {BIB_STRONGS_KEY}.make_from_text ("H01254"))
			assert_true ("found", l_answer.is_success and then l_answer.count = 1 and then l_answer.item (1).lemma_id = {CONC_FIXTURE}.Create_lemma)
			assert_true ("cited", l_answer.is_fact_closed)
			l_answer := l_pack.headwords_for_strongs (create {BIB_STRONGS_KEY}.make_from_text ("H9999"))
			assert_true ("unknown is empty success", l_answer.is_success and l_answer.count = 0)
			close_and_clean (last_pack_set, l_fixture)
		end

	test_strongs_key_text
			-- Padding-insensitive, sense suffix kept, zero refused (conc.db holds "G0").
		local
			l_key: BIB_STRONGS_KEY
		do
			create l_key.make_from_text ("H0001")
			assert_strings_equal ("unpadded", "H1", l_key.text)
			create l_key.make_from_text ("H6743a")
			assert_strings_equal ("suffix kept", "a", l_key.sense_suffix)
			assert_strings_equal ("canonical", "H6743a", l_key.text)
			assert_false ("zero refused", l_key.is_strongs_text ("G0"))
			assert_false ("bad prefix", l_key.is_strongs_text ("X12"))
			assert_false ("too many digits", l_key.is_strongs_text ("H123456"))
		end

	test_places_page_by_offset_and_by_keyset
			-- The article's 251 places come back 200 then 51, in token order; the keyset page after
			-- the first page is the same rows as the offset page (spike R1); totals come from the
			-- builder's counts; every row carries its corpus's provenance.
		local
			l_fixture: CONC_FIXTURE
			l_pack: BIB_CONC_PACK
			l_first, l_second, l_after: BIB_LIST_RESULT [BIB_PLACE_ROW]
			l_same: BOOLEAN
			i: INTEGER
		do
			create l_fixture
			l_pack := checked_pack (l_fixture)
			assert_integers_equal ("total", {CONC_FIXTURE}.Article_places, l_pack.place_total ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS").value.to_integer_32)
			l_first := l_pack.place_page ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS", 0, 200)
			assert_true ("first page", l_first.is_success and then l_first.count = 200)
			assert_true ("first place", l_first.item (1).token_id = 4)
			assert_strings_equal ("reference", "Genesis 1:1", l_first.item (1).reference_text)
			assert_strings_equal ("restricted corpus cited", "restricted_nc (RESEARCH ONLY)", l_first.citation (1).caveat)
			l_second := l_pack.place_page ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS", 200, 200)
			assert_integers_equal ("second page", 51, l_second.count)
			l_after := l_pack.place_page_after ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS", l_first.item (200).token_id, 200)
			l_same := l_after.count = l_second.count
			from i := 1 until not l_same or i > l_after.count loop
				l_same := l_after.item (i).token_id = l_second.item (i).token_id
				i := i + 1
			end
			assert_true ("keyset equals offset", l_same)
			assert_strings_equal ("method", "place_page_after", l_after.method.engine_feature)
			assert_true ("no place in another corpus", l_pack.place_page ({CONC_FIXTURE}.Article_lemma, "WLC-MACULA", 0, 200).count = 0)
			close_and_clean (last_pack_set, l_fixture)
		end

	test_english_rows_bible_by_bible
			-- "created" (any case) leads to Hebrew "bara" in the BSB, Genesis, once (FR-151).
		local
			l_fixture: CONC_FIXTURE
			l_pack: BIB_CONC_PACK
			l_rows: BIB_LIST_RESULT [BIB_ENGLISH_ROW]
		do
			create l_fixture
			l_pack := checked_pack (l_fixture)
			l_rows := l_pack.english_rows ("Created")
			assert_true ("one row", l_rows.is_success and then l_rows.count = 1)
			assert_strings_equal ("bible", "ENG-BSB", l_rows.item (1).bible)
			assert_true ("headword", l_rows.item (1).lemma_id = {CONC_FIXTURE}.Create_lemma and l_rows.item (1).book_id = 1 and l_rows.item (1).count = 1)
			assert_true ("cited", l_rows.is_fact_closed)
			assert_true ("unknown word", l_pack.english_rows ("zzz").count = 0)
			close_and_clean (last_pack_set, l_fixture)
		end

	test_verse_words_every_corpus
			-- Genesis 1:1 in the Hebrew corpus: two words in order, the second with an empty
			-- surface; in the BSB: one English word with the basis kind "computed".
		local
			l_fixture: CONC_FIXTURE
			l_pack: BIB_CONC_PACK
			l_ref: BIB_REF
			l_words: BIB_LIST_RESULT [BIB_VERSE_WORD]
		do
			create l_fixture
			l_pack := checked_pack (l_fixture)
			create l_ref.make (1, 1, 1, create {BIB_VERSIFICATION_SYSTEM}.make_kjv)
			l_words := l_pack.verse_words (l_ref, "WLC-MACULA")
			assert_true ("two hebrew words", l_words.is_success and then l_words.count = 2)
			assert_strings_equal ("basis kind", "tagged", l_words.item (1).lemma_basis)
			assert_true ("empty surface", l_words.item (2).surface.is_empty and l_words.item (2).has_door)
			l_words := l_pack.verse_words (l_ref, "ENG-BSB")
			assert_true ("one english word", l_words.is_success and then l_words.count = 1)
			assert_strings_equal ("computed", "computed", l_words.item (1).lemma_basis)
			close_and_clean (last_pack_set, l_fixture)
		end

	test_verse_word_takes_real_hebrew_rows
			-- A verse word and a place row build from conc.db's real Hebrew shape: an empty
			-- surface and no transliteration (6,435 such tokens, WLC-MACULA), basis kind
			-- "tagged" (Phase 2 rulings 1.1 and 1.2; the creators before the review refused it).
		local
			l_word: BIB_VERSE_WORD
			l_row: BIB_PLACE_ROW
		do
			create l_word.make (2, "hbo", "", "", {CONC_FIXTURE}.Unwritten_lemma, "tagged", test_provenance)
			assert_true ("empty surface kept", l_word.surface.is_empty and l_word.translit.is_empty)
			assert_true ("door to the word view", l_word.has_door)
			create l_row.make (2, "hbo", "Gen 1:1", "", "", test_provenance)
			assert_true ("place row too", l_row.surface.is_empty and l_row.meaning = Void)
		end

	test_verse_word_takes_english_computed_rows
			-- An English token (basis kind "computed", no transliteration) builds a verse word
			-- and a place row (rulings 1.1 and 1.2).
		local
			l_word: BIB_VERSE_WORD
			l_row: BIB_PLACE_ROW
		do
			create l_word.make (1, "eng", "created", "", {CONC_FIXTURE}.English_lemma, "computed", test_provenance)
			assert_strings_equal ("basis kind", "computed", l_word.lemma_basis)
			assert_strings_equal ("language", "eng", l_word.language)
			create l_row.make (3, "eng", "Gen 1:1", "created", "", test_provenance)
			assert_strings_equal ("surface", "created", l_row.surface)
		end

	test_value_creators_pin_every_field
			-- Every field lands where it was given (ruling 1.3); a place row's context is
			-- optional and set together.
		local
			l_entry: BIB_WORD_ENTRY
			l_row: BIB_PLACE_ROW
			l_english: BIB_ENGLISH_ROW
			l_provenance: BIB_PROVENANCE
		do
			l_provenance := test_provenance
			create l_entry.make ({CONC_FIXTURE}.Create_lemma, "hbo", "BRA", "bara", "baw-RAW", 1, l_provenance)
			assert_strings_equal ("headword", "BRA", l_entry.headword)
			assert_strings_equal ("translit", "bara", l_entry.translit)
			assert_strings_equal ("pron", "baw-RAW", l_entry.pron)
			assert_true ("provenance", l_entry.provenance = l_provenance)
			create l_row.make (1, "hbo", "Gen 1:1", "BRA", "bara", l_provenance)
			l_row.set_context ("to bring into being", "qal", "created", Void, Void)
			assert_true ("meaning set", attached l_row.meaning as al_m and then al_m.same_string ("to bring into being"))
			assert_true ("kjv absent", l_row.kjv = Void)
			create l_english.make ("created", "ENG-BSB", {CONC_FIXTURE}.Create_lemma, "BRA", "bara", 1, 1, l_provenance)
			assert_strings_equal ("bible", "ENG-BSB", l_english.bible)
			assert_strings_equal ("english", "created", l_english.english)
			assert_strings_equal ("headword not swapped", "BRA", l_english.headword)
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
	Other_pack_file: STRING = "conc_test_other_pack.db"

	last_pack_set: BIB_SOURCE_SET
			-- The source set `checked_pack' opened last.
		attribute
			create Result.make
		end

	checked_pack (a_fixture: CONC_FIXTURE): BIB_CONC_PACK
			-- A pack reader over the fixture, attached and accepted; its set is `last_pack_set'.
		do
			last_pack_set := attached_set (a_fixture, Pack_file, {CONC_FIXTURE}.Pack_version, "")
			create Result.make (last_pack_set)
			Result.check_pack
		ensure
			accepted: Result.is_available
		end

	attached_set (a_fixture: CONC_FIXTURE; a_pack: STRING; a_version: INTEGER; a_omitted_table: STRING): BIB_SOURCE_SET
			-- An open source set with a fixture pack built from the arguments attached as "conc".
		do
			a_fixture.build_main (Main_file)
			a_fixture.build_variant (a_pack, a_version, a_omitted_table)
			create Result.make
			Result.open_core (Main_file)
			Result.attach ({BIB_CONC_PACK}.Pack_alias, a_pack)
		end

	close_and_clean (a_set: BIB_SOURCE_SET; a_fixture: CONC_FIXTURE)
			-- Close `a_set' and delete every file these tests write.
		do
			if a_set.is_open then
				a_set.close
			end
			a_fixture.delete_file (Main_file)
			a_fixture.delete_file (Pack_file)
			a_fixture.delete_file (Old_pack_file)
			a_fixture.delete_file (Other_pack_file)
		end

	test_provenance: BIB_PROVENANCE
			-- A provenance for values built by hand.
		do
			create Result.make (1, "conc_test", "fixture", create {BIB_LICENSE}.make ("CC BY 4.0", False, False, False, "test fixture"), "")
		end

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
