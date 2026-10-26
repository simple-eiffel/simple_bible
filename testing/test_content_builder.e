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
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("opens", l_bible.is_open and l_bible.conc_pack.is_available)
			assert_strings_equal ("edition", "test-build", l_bible.database_edition)
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

feature {NONE} -- Fixture

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
		end

end
