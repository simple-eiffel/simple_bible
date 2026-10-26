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
