note
	description: "[
		The reading slice (fold 2026-10-26): content.db v2's versions and
		chapters through BIB_TEXT_READER, and place rows that know their verse
		so the reading pane can open them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_READING

inherit
	TEST_SET_BASE

feature -- Tests

	test_versions_and_a_chapter
			-- The versions in content.db's order, a chapter verse by verse, an omission told as
			-- one, the last chapter, and a chapter a version lacks read as empty, not failed.
		local
			l_reader: BIB_TEXT_READER
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
		do
			l_reader := bible.text_reader
			assert_integers_equal ("two versions", 2, l_reader.versions.count)
			assert_strings_equal ("in their order", "KJV", l_reader.versions.first.code)
			assert_true ("Hebrew right to left", attached l_reader.version ("WLC") as al_wlc and then al_wlc.is_right_to_left)
			assert_false ("English left to right", attached l_reader.version ("KJV") as al_kjv and then al_kjv.is_right_to_left)
			l_chapter := l_reader.chapter ("KJV", 1, 1)
			assert_true ("succeeded", l_chapter.is_success)
			assert_integers_equal ("three verses", 3, l_chapter.count)
			assert_strings_equal ("verse 1", "In the beginning God created the heaven and the earth.", l_chapter.item (1).text)
			assert_true ("verse 3 omitted", l_chapter.item (3).is_omitted and then l_chapter.item (3).display_text.has_substring ("omits"))
			assert_integers_equal ("last chapter", 2, l_reader.last_chapter ("KJV", 1))
			assert_integers_equal ("a book the version lacks", 0, l_reader.last_chapter ("KJV", 2))
			l_chapter := l_reader.chapter ("KJV", 2, 1)
			assert_true ("absent chapter: success, empty", l_chapter.is_success and l_chapter.count = 0)
			assert_integers_equal ("Hebrew Genesis 1", 1, l_reader.chapter ("WLC", 1, 1).count)
			finish
		end

	test_cross_references_most_voted_first
			-- P04's Cross-refs tab: the targets of a verse, most voted first, a range told as one,
			-- negative votes kept; a verse with none answers empty.
		local
			l_refs: BIB_LIST_RESULT [BIB_READING_CROSS_REF]
		do
			assert_true ("carried", bible.text_reader.has_cross_references)
			l_refs := bible.text_reader.cross_references (1, 1, 1)
			assert_true ("succeeded", l_refs.is_success)
			assert_integers_equal ("three", 3, l_refs.count)
			assert_true ("most voted first: John 1:1-3", l_refs.item (1).to_book = 43 and l_refs.item (1).votes = 950 and l_refs.item (1).is_range)
			assert_strings_equal ("range text", "1-3", l_refs.item (1).verses_text)
			assert_integers_equal ("negative votes kept", -3, l_refs.item (3).votes)
			assert_integers_equal ("none from Genesis 1:2", 0, bible.text_reader.cross_references (1, 1, 2).count)
			finish
		end

	test_lexicon_entries_and_gloss
			-- P05.5: every dictionary meaning, each source in its own words; and a one-line gloss.
		local
			l_entries: BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
		do
			l_entries := bible.conc_pack.lexicon_entries ({CONC_FIXTURE}.Create_lemma)
			assert_true ("succeeded", l_entries.is_success)
			assert_true ("one entry or more", l_entries.count >= 1)
			assert_false ("titles never empty", across 1 |..| l_entries.count as i some l_entries.item (i).title.is_empty end)
			assert_true ("an unknown headword: empty, not failed", bible.conc_pack.lexicon_entries (999).is_success)
			assert_true ("gloss never fails", bible.conc_pack.short_gloss (999).is_empty)
			finish
		end

	test_a_clicked_word_finds_its_original
			-- S4 (GW-08): the word "created" clicked in Genesis 1:1 of the BSB finds bara through the
			-- BSB's per-word link; a second "created" or an unlinked word finds nothing.
		local
			l_lookup: BIB_LOOKUP
			l_ref: BIB_REF
			l_found: BIB_LIST_RESULT [BIB_WORD_ENTRY]
		do
			create l_lookup.make (bible)
			assert_strings_equal ("the BSB's English corpus", "ENG-BSB", l_lookup.english_corpus_for_version ("BSB"))
			assert_true ("no English corpus for the Hebrew", l_lookup.english_corpus_for_version ("WLC").is_empty)
			create l_ref.make (1, 1, 1, create {BIB_VERSIFICATION_SYSTEM}.make_kjv)
			l_found := bible.conc_pack.headwords_behind_word ("ENG-BSB", l_ref, "created", 1)
			assert_true ("found", l_found.is_success and l_found.count = 1)
			assert_true ("bara", l_found.item (1).lemma_id = {CONC_FIXTURE}.Create_lemma)
			assert_integers_equal ("no second created", 0, bible.conc_pack.headwords_behind_word ("ENG-BSB", l_ref, "created", 2).count)
			assert_integers_equal ("an unlinked word", 0, bible.conc_pack.headwords_behind_word ("ENG-BSB", l_ref, "zzz", 1).count)
			finish
		end

	test_a_clicked_original_word_finds_its_headword
			-- The parallel view's Hebrew or Greek column: the clicked word, folded as the pack's search
			-- forms are, matched to the verse's tokens with a prefix joined to its word ("BBRA" is the
			-- prefix b and bara), finds the longer token's headword.
		local
			l_lookup: BIB_LOOKUP
			l_ref: BIB_REF
			l_found: BIB_LIST_RESULT [BIB_WORD_ENTRY]
		do
			create l_lookup.make (bible)
			assert_strings_equal ("WLC is tagged in the Hebrew Bible", "WLC-MACULA", l_lookup.original_corpus_for_version ("WLC", 1))
			assert_true ("an English version is no original", l_lookup.original_corpus_for_version ("KJV", 1).is_empty)
			create l_ref.make (1, 1, 1, create {BIB_VERSIFICATION_SYSTEM}.make_kjv)
			l_found := bible.conc_pack.headwords_behind_original_word ("WLC-MACULA", l_ref, "BBRA", 1)
			assert_true ("found", l_found.is_success and l_found.count = 1)
			assert_true ("bara, not the prefix", l_found.item (1).lemma_id = {CONC_FIXTURE}.Create_lemma)
			assert_integers_equal ("no second", 0, bible.conc_pack.headwords_behind_original_word ("WLC-MACULA", l_ref, "BBRA", 2).count)
			assert_integers_equal ("a word the verse lacks", 0, bible.conc_pack.headwords_behind_original_word ("WLC-MACULA", l_ref, "ZZZ", 1).count)
			finish
		end

	test_an_empty_chapter_says_why
			-- Scan 36: why a chapter shows nothing is said once, for the Bible tab and every Parallel
			-- column: nothing to say when it has verses; "... is not in this version." when it has none.
		local
			l_lookup: BIB_LOOKUP
		do
			create l_lookup.make (bible)
			assert_true ("verses: nothing to say", l_lookup.empty_chapter_text (bible.text_reader.chapter ("KJV", 1, 1), "Genesis 1").is_empty)
			assert_strings_equal ("none: said", {STRING_32} "Genesis 50 is not in this version.", l_lookup.empty_chapter_text (bible.text_reader.chapter ("KJV", 1, 50), "Genesis 50"))
			finish
		end

	test_every_claim_wears_its_label
			-- 2026-10-27: a claim tag in the commentary's text is shown with its label, and each
			-- section lists its claims by label; a DEDUCED claim never reads as Larry's words.
		local
			l_section: BIB_COMMENTARY_SECTION
			l_text: BIB_COMMENTARY_TEXT
			l_page: STRING_32
		do
			create l_section.make ("jude-5-7", "Jude 5-7", 65, 1, 5, 1, 7, "author",
				create {BIB_PROVENANCE}.make (1, "Larry Rix: Jude", "TEST", create {BIB_LICENSE}.make ("private", True, False, True, "Larry Rix"), ""))
			l_section.fields.extend (["teaser", {STRING_32} "Saved, then destroyed [D5.1]; he says so [S5.2]."])
			l_section.claims.extend (create {BIB_COMMENTARY_CLAIM}.make ("D5.1", "DEDUCED", "Saved, then destroyed.", "saved then destroyed", "Basis: ZAKAR"))
			l_section.claims.extend (create {BIB_COMMENTARY_CLAIM}.make ("S5.2", "SOURCED", "He says so.", "his words", "CL 1:2"))
			create l_text
			l_page := l_text.page ("Jude: A Commentary", <<l_section>>)
			assert_true ("the deduction labelled inline", l_page.has_substring ("**[DEDUCED D5.1]**"))
			assert_true ("the sourced claim labelled inline", l_page.has_substring ("**[SOURCED S5.2]**"))
			assert_false ("no bare tag left", l_page.has_substring (" [D5.1]"))
			assert_true ("listed by label", l_page.has_substring ("- **[DEDUCED D5.1]** saved then destroyed"))
			assert_true ("the banner says what the labels mean", l_page.has_substring ("not his words"))
		end

	test_place_rows_know_their_verse
			-- A place opens in the reading pane: it carries its book, chapter and verse as numbers.
		local
			l_places: BIB_LIST_RESULT [BIB_PLACE_ROW]
		do
			l_places := bible.conc_pack.place_page ({CONC_FIXTURE}.Create_lemma, "WLC-MACULA", 0, 10)
			assert_true ("found", l_places.is_success and l_places.count >= 1)
			assert_true ("Genesis 1:1", l_places.item (1).book_id = 1 and l_places.item (1).chapter = 1 and l_places.item (1).verse = 1)
			assert_true ("readable", l_places.item (1).is_readable)
			finish
		end

	test_a_failing_chapter_query_says_why
			-- Design scan 33: the reader's queries go through the shared BIB_SQLITE_QUERYING, so a
			-- broken table is a failure with the reader's message and SQLite's own words.
		local
			l_db: SIMPLE_SQL_DATABASE
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_config: BIB_CONFIG
			l_reopened: SIMPLE_BIBLE
			l_memory: MEMORY
		do
			l_chapter := bible.text_reader.chapter ("KJV", 1, 1)
			assert_true ("reads before", l_chapter.is_success)
			bible.close
			create l_memory
			l_memory.full_collect
			create l_db.make (Content_file)
			l_db.execute ("ALTER TABLE verse_text RENAME COLUMN text TO text_gone")
			l_db.close
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_reopened.make (l_config)
			l_reopened.open
			assert_true ("opens: the table is there", l_reopened.is_open)
			l_chapter := l_reopened.text_reader.chapter ("KJV", 1, 1)
			assert_false ("fails", l_chapter.is_success)
			assert_true ("the reader's words", attached l_chapter.error as al_e and then al_e.message.has_substring ("Bible text query failed"))
			assert_true ("the method is recorded", l_chapter.method.engine_feature.same_string_general ("chapter"))
			l_reopened.close
			finish
		end

feature {NONE} -- Fixture

	Content_file: STRING = "reading_test_content.db"
	Pack_file: STRING = "reading_test_pack.db"

	bible_cache: detachable SIMPLE_BIBLE

	bible: SIMPLE_BIBLE
			-- A fresh engine on the fixture files.
		local
			l_fixture: CONC_FIXTURE
			l_config: BIB_CONFIG
		do
			if attached bible_cache as al_bible then
				Result := al_bible
			else
				create l_fixture
				l_fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
				l_fixture.build (Pack_file)
				create l_config.make_with_core (Content_file)
				l_config := l_config.set_conc_path (Pack_file)
				create Result.make (l_config)
				Result.open
				bible_cache := Result
			end
		end

	finish
			-- Close the engine and delete the fixture files.
		local
			l_fixture: CONC_FIXTURE
			l_memory: MEMORY
		do
			if attached bible_cache as al_bible and then al_bible.is_open then
				al_bible.close
			end
			bible_cache := Void
			create l_memory
			l_memory.full_collect
			create l_fixture
			l_fixture.delete_file (Content_file)
			l_fixture.delete_file (Pack_file)
		end

end
