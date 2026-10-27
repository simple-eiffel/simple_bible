note
	description: "[
		bible_build's builder (Phase 4, Task 10): content.db v1 from a bible.db
		book list, checked by the engine before it replaces anything. The input
		bible.db is a small one made here; nothing from the vault is committed.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CONTENT_BUILDER

inherit
	TEST_SET_BASE

feature -- Tests

	test_builds_a_content_db_the_engine_opens
			-- The built file opens as SIMPLE_BIBLE's main database, with the concordance beside it.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("books", 3, l_builder.books_written)
			assert_integers_equal ("versions", 3, l_builder.versions_written)
			assert_integers_equal ("verses", 4, l_builder.verses_written)
			assert_integers_equal ("cross-references, a book outside 1 to 66 left out", 1, l_builder.cross_references_written)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("opens", l_bible.is_open and l_bible.conc_pack.is_available)
			assert_strings_equal ("edition", "test-build", l_bible.database_edition)
			assert_true ("Hebrew reads right to left", attached l_bible.text_reader.version ("WLC") as al_wlc and then al_wlc.is_right_to_left and then al_wlc.language.same_string ("hbo"))
			assert_true ("personal only is restricted", attached l_bible.text_reader.version ("NWT2013") as al_nwt and then al_nwt.provenance.license.is_restricted)
			assert_integers_equal ("Genesis 1 in the KJV", 2, l_bible.text_reader.chapter ("KJV", 1, 1).count)
			assert_true ("a single-verse target", l_bible.text_reader.cross_references (1, 1, 1).count = 1 and then not l_bible.text_reader.cross_references (1, 1, 1).item (1).is_range)
			l_bible.close
			remove_test_files
		end

	test_verse_index_finds_words_phrases_and_pointed_hebrew
			-- bible_build 0.3.0 writes verse_fts; the reader finds every word, a quoted phrase, a
			-- prefix, any letter case, and pointed Hebrew from unpointed typing.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
			l_found: BIB_LIST_RESULT [BIB_READING_VERSE]
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_db.make (Bible_file)
			l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 3, 'And God said, Let there be light: and there was light.')")
			l_db.execute_with_args ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (16, 1, 1, 2, ?)", {ARRAY [detachable ANY]} <<codes (<<0x05D5, 0x05B0, 0x05D4, 0x05B8, 0x05D0, 0x05B8, 0x0597, 0x05E8, 0x05B6, 0x05E5>>)>>)
			l_db.close
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("every verse indexed", 6, l_builder.verses_indexed)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("an index", l_bible.text_reader.has_verse_index)
			l_found := l_bible.text_reader.verses_matching ("KJV", "light", 50)
			assert_true ("a word", l_found.is_success and then l_found.count = 1 and then l_found.item (1).verse = 3)
			assert_integers_equal ("every verse with the word, in order", 2, l_bible.text_reader.verses_matching ("KJV", "the", 50).count)
			assert_integers_equal ("a phrase", 1, l_bible.text_reader.verses_matching ("KJV", "%"the earth%"", 50).count)
			assert_integers_equal ("any case", 1, l_bible.text_reader.verses_matching ("KJV", "BEGINNING", 50).count)
			assert_integers_equal ("a prefix", 1, l_bible.text_reader.verses_matching ("KJV", "begin*", 50).count)
			assert_integers_equal ("every word must be there", 0, l_bible.text_reader.verses_matching ("KJV", "light beginning", 50).count)
			assert_integers_equal ("one version only", 0, l_bible.text_reader.verses_matching ("WLC", "light", 50).count)
			assert_integers_equal ("pointed Hebrew from unpointed typing", 1, l_bible.text_reader.verses_matching ("WLC", codes (<<0x05D5, 0x05D4, 0x05D0, 0x05E8, 0x05E5>>), 50).count)
			assert_integers_equal ("the limit", 1, l_bible.text_reader.verses_matching ("KJV", "the", 1).count)
			assert_integers_equal ("counted", 2, l_bible.text_reader.matching_count ("KJV", "the"))
			assert_true ("punctuation alone finds nothing, without failing", l_bible.text_reader.verses_matching ("KJV", "?!", 50).is_success)
			l_bible.close
			remove_test_files
		end

	test_verse_index_keeps_to_numbered_verses
			-- Scan 47: a heading row (verse 0) is not indexed, so the count and the list agree, and the
			-- build says how many rows it left out; a hostile query cannot break the expression; a
			-- quoted phrase can end in a prefix. Before: matching_count counted the heading (2) while
			-- verses_matching dropped it (1).
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_db.make (Bible_file)
			l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 3, 'And God said, Let there be light.'), (12, 1, 1, 0, 'The light of creation (a heading)')")
			l_db.close
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("numbered verses indexed", 5, l_builder.verses_indexed)
			assert_integers_equal ("the heading left out", 1, l_builder.verses_not_indexed)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_integers_equal ("counted as listed", l_bible.text_reader.verses_matching ("KJV", "light", 50).count, l_bible.text_reader.matching_count ("KJV", "light"))
			assert_integers_equal ("one verse", 1, l_bible.text_reader.matching_count ("KJV", "light"))
			assert_true ("operators are words", l_bible.text_reader.verses_matching ("KJV", "NEAR(light) OR %" AND *", 50).is_success)
			assert_integers_equal ("a phrase ending in a prefix", 1, l_bible.text_reader.verses_matching ("KJV", "%"the ear%"*", 50).count)
			l_bible.close
			remove_test_files
		end

	test_boolean_and_root_word_search
			-- B02 and B03 end to end: Strong's numbers and lemmas from the concordance, words from the
			-- verse index, joined by AND, OR, NOT and parentheses, read in the KJV.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_db.make (Bible_file)
			l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 3, 'And God said, Let there be light.')")
			l_db.close
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_integers_equal ("a root: bara in Genesis 1:1", 1, found (l_bible, "H1254"))
			assert_true ("Hebrew numbering told", l_bible.verse_search.has_hebrew_roots)
			assert_true ("read in the KJV", l_bible.verse_search.verses ("KJV", 1, 10).item (1).text.same_string ("In the beginning"))
			assert_integers_equal ("a root and a word", 1, found (l_bible, "strongs:H1254 AND beginning"))
			assert_integers_equal ("a root or a word", 2, found (l_bible, "H1254 OR light"))
			assert_integers_equal ("a word without another", 1, found (l_bible, "the NOT earth"))
			assert_integers_equal ("grouped", 1, found (l_bible, "(light OR earth) AND the"))
			assert_integers_equal ("a lemma by its plain letters", 1, found (l_bible, "lemma:bara"))
			assert_integers_equal ("a root the pack has no corpus for", 0, found (l_bible, "G3588"))
			assert_false ("no failure", l_bible.verse_search.has_failed)
			assert_integers_equal ("a root nowhere with a word", 0, found (l_bible, "H1254 AND light"))
			l_bible.close
			remove_test_files
		end

	found (a_bible: SIMPLE_BIBLE; a_query: STRING_8): INTEGER
			-- How many verses `a_query' names in the KJV.
		local
			l_query: BIB_QUERY
		do
			l_query := a_bible.query_parser.parsed (a_query, create {BIB_SEARCH_SCOPE}.make ("verses", <<"KJV">>, 1, 66, "verses"))
			assert_true ({STRING_8} "valid: " + a_query, l_query.is_valid)
			a_bible.verse_search.find (l_query, "KJV")
			Result := a_bible.verse_search.places.count
		end

	test_rebuild_is_byte_identical
			-- Two builds from the same inputs, build id and build time are the same bytes (FR-130's direction).
		local
			l_builder: BIB_CONTENT_BUILDER
			l_first, l_second: ARRAY [NATURAL_8]
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_builder.make
			l_builder.set_built_at ("2026-10-26T12:00:00Z")
			l_builder.build (Bible_file, Out_file)
			l_first := (create {SIMPLE_FILE}.make (Out_file)).read_bytes
			l_builder.build (Bible_file, Out_file)
			l_second := (create {SIMPLE_FILE}.make (Out_file)).read_bytes
			assert_true ("not empty", l_first.count > 0)
			assert_true ("same bytes", l_first ~ l_second)
			remove_test_files
		end

	test_missing_bible_is_reported
			-- No bible.db: a reason, and no content.db written.
		local
			l_builder: BIB_CONTENT_BUILDER
		do
			remove_test_files
			create l_builder.make
			l_builder.build (Bible_file, Out_file)
			assert_true ("reported", l_builder.last_error /= Void)
			assert_false ("nothing written", (create {SIMPLE_FILE}.make (Out_file)).exists)
		end

	test_failed_build_leaves_nothing_behind
			-- A bible.db without its book list: a reason, no content.db, no temporary file.
		local
			l_builder: BIB_CONTENT_BUILDER
		do
			remove_test_files
			make_bible_db (Bible_file, False)
			create l_builder.make
			l_builder.build (Bible_file, Out_file)
			assert_true ("reported", attached l_builder.last_error as al_e and then al_e.has_substring ("bible_books"))
			assert_false ("no content.db", (create {SIMPLE_FILE}.make (Out_file)).exists)
			assert_false ("no temporary file", (create {SIMPLE_FILE}.make (Out_file + ".tmp")).exists)
			remove_test_files
		end

	test_failed_move_leaves_no_temporary_file
			-- When the built file cannot be moved into place (here the output names a folder), the
			-- reason is given and the temporary file is gone (design scan 31: it leaked).
		local
			l_builder: BIB_CONTENT_BUILDER
			l_ok: BOOLEAN
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			l_ok := (create {SIMPLE_FILE}.make (Folder_out)).create_directory
			create l_builder.make
			l_builder.build (Bible_file, Folder_out)
			assert_true ("reported", l_builder.last_error /= Void)
			assert_false ("no temporary file", (create {SIMPLE_FILE}.make (Folder_out + ".tmp")).exists)
			l_ok := (create {SIMPLE_FILE}.make (Folder_out)).delete_directory
			remove_test_files
		end

feature {NONE} -- Fixture

	Folder_out: STRING = "builder_test_out_folder"

	Bible_file: STRING = "builder_test_bible.db"
	Out_file: STRING = "builder_test_content.db"
	Pack_file: STRING = "builder_test_pack.db"

	fixture: CONC_FIXTURE
			-- The shared test-file helpers.
		once
			create Result
		end

	make_bible_db (a_path: STRING; a_with_books: BOOLEAN)
			-- A small bible.db: the vault's `bible_books' shape with three books, or none at all.
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			fixture.delete_file (a_path)
			create l_db.make (a_path)
			if a_with_books then
				l_db.execute ("CREATE TABLE bible_books(id INTEGER PRIMARY KEY, name TEXT, abbreviation TEXT, testament INTEGER)")
				l_db.execute ("INSERT INTO bible_books VALUES (1, 'Genesis', 'Gen', 0), (2, 'Exodus', 'Exod', 0), (40, 'Matthew', 'Matt', 1)")
				l_db.execute ("CREATE TABLE bible_versions(id INTEGER PRIMARY KEY, abbreviation TEXT, name TEXT, license TEXT, caveat TEXT)")
				l_db.execute ("INSERT INTO bible_versions VALUES (12, 'KJV', 'KJV', 'MIT', ''), (16, 'WLC', 'WLC', 'MIT', 'HEBREW versification'), (31, 'NWT2013', 'New World Translation', 'personal_only (see source_provenance)', '')")
				l_db.execute ("CREATE TABLE cross_references(id INTEGER PRIMARY KEY, from_book_id INTEGER, from_chapter INTEGER, from_verse INTEGER, to_book_id INTEGER, to_chapter INTEGER, to_verse_start INTEGER, to_verse_end INTEGER, votes INTEGER, source TEXT)")
				l_db.execute ("INSERT INTO cross_references (from_book_id, from_chapter, from_verse, to_book_id, to_chapter, to_verse_start, to_verse_end, votes, source) VALUES (1, 1, 1, 40, 1, 1, NULL, 5, 'openbible'), (1, 1, 1, 99, 1, 1, 1, 9, 'openbible')")
				l_db.execute ("CREATE TABLE bible_verses(id INTEGER PRIMARY KEY, version_id INTEGER, book_id INTEGER, chapter INTEGER, verse INTEGER, text TEXT)")
				l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 1, 'In the beginning'), (12, 1, 1, 2, 'And the earth'), (16, 1, 1, 1, 'BRASYT'), (31, 40, 1, 1, 'The book')")
			else
				l_db.execute ("CREATE TABLE other(id INTEGER)")
			end
			l_db.close
		end

	codes (a_codes: ARRAY [INTEGER]): STRING_32
			-- Text from code points (the sources stay ASCII).
		do
			create Result.make (a_codes.count)
			across a_codes as ic loop
				Result.append_character (ic.to_character_32)
			end
		end

	remove_test_files
			-- Delete every file these tests write.
		do
			fixture.delete_file (Bible_file)
			fixture.delete_file (Out_file)
			fixture.delete_file (Out_file + ".tmp")
			fixture.delete_file (Pack_file)
			fixture.delete_file (Folder_out + ".tmp")
		end

end
