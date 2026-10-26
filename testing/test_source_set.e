note
	description: "[
		BIB_SOURCE_SET for real (Phase 4, Task 1): content.db opens read-only,
		packs attach read-only through simple_sql, and every failure carries
		SQLite's own message (FR-138, FR-160, Phase 2 ruling 3.1). The test
		databases are made here and deleted after; none is committed.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SOURCE_SET

inherit
	TEST_SET_BASE

feature -- Tests

	test_open_attach_detach_close
			-- content.db opens read-only and reports SQLite's version; a pack attaches
			-- read-only, SQLite refuses a write into it, and it detaches and closes cleanly.
		local
			l_set: BIB_SOURCE_SET
		do
			fixture.build_main (Main_file)
			fixture.build_main (Pack_file)
			create l_set.make
			l_set.open_core (Main_file)
			assert_true ("open", l_set.is_open)
			assert_true ("no error", l_set.last_error = Void)
			assert_strings_equal ("engine version", "3.53.4", l_set.sqlite_version)
			l_set.attach ("pk", Pack_file)
			assert_true ("attach no error", l_set.last_error = Void)
			assert_integers_equal ("one attached", 1, l_set.attached_count)
			assert_true ("path recorded", attached l_set.attached_path ("pk") as al_path and then al_path.same_string_general (Pack_file))
			if attached l_set.database as al_db then
				assert_integers_equal ("pack readable", 1, al_db.query ("SELECT count(*) AS n FROM pk.t").rows.first.integer_value ("n"))
				al_db.query ("INSERT INTO pk.t (id) VALUES (2)").do_nothing
				assert_true ("write refused", al_db.has_error and al_db.is_readonly_error)
			else
				assert_true ("connection when open", False)
			end
			l_set.detach ("pk")
			assert_true ("detach no error", l_set.last_error = Void)
			assert_integers_equal ("none attached", 0, l_set.attached_count)
			l_set.close
			assert_false ("closed", l_set.is_open)
			assert_true ("connection released", l_set.database = Void)
			fixture.delete_file (Main_file)
			fixture.delete_file (Pack_file)
		end

	test_open_core_missing_file_reports
			-- A missing content.db leaves the set closed with a reason naming the file.
		local
			l_set: BIB_SOURCE_SET
		do
			fixture.delete_file (Missing_file)
			create l_set.make
			l_set.open_core (Missing_file)
			assert_false ("not open", l_set.is_open)
			assert_true ("reported", attached l_set.last_error as al_error and then al_error.code = {BIB_ERROR}.Source_unavailable and then al_error.details.same_string_general (Missing_file))
		end

	test_open_core_not_a_database_reports
			-- A file that is not a database fails at open with SQLite's own message, not later.
		local
			l_set: BIB_SOURCE_SET
			l_file: PLAIN_TEXT_FILE
		do
			create l_file.make_create_read_write (Garbage_file)
			l_file.put_string ("This is not a SQLite database, only text long enough to fill a page header.")
			l_file.close
			create l_set.make
			l_set.open_core (Garbage_file)
			assert_false ("not open", l_set.is_open)
			assert_true ("reported with SQLite's words", attached l_set.last_error as al_error and then al_error.code = {BIB_ERROR}.Database_problem and then al_error.details.has_substring ("not a database"))
			fixture.delete_file (Garbage_file)
		end

	test_open_core_folder_reports
			-- A path SQLite cannot open (here a folder, which passes the exists check) is
			-- reported, not raised (design scan 26: make_read_only raises on open failure).
		local
			l_set: BIB_SOURCE_SET
			l_dir: DIRECTORY
		do
			create l_dir.make_with_name (Folder_path)
			if not l_dir.exists then
				l_dir.create_dir
			end
			create l_set.make
			l_set.open_core (Folder_path)
			assert_false ("not open", l_set.is_open)
			assert_true ("reported", attached l_set.last_error as al_error and then al_error.code = {BIB_ERROR}.Database_problem)
			l_dir.delete
		end

	test_close_forgets_the_connection
			-- After close, the path and the engine version of the closed connection are gone.
		local
			l_set: BIB_SOURCE_SET
		do
			fixture.build_main (Main_file)
			create l_set.make
			l_set.open_core (Main_file)
			l_set.close
			assert_true ("path cleared", l_set.core_path.is_empty)
			assert_true ("version cleared", l_set.sqlite_version.is_empty)
			fixture.delete_file (Main_file)
		end

	test_attach_missing_pack_reports_sqlite_message
			-- A pack that cannot attach leaves the alias table unchanged and carries SQLite's message.
		local
			l_set: BIB_SOURCE_SET
		do
			fixture.build_main (Main_file)
			fixture.delete_file (Missing_file)
			create l_set.make
			l_set.open_core (Main_file)
			l_set.attach ("pk", Missing_file)
			assert_true ("reported", attached l_set.last_error as al_error and then al_error.code = {BIB_ERROR}.Source_unavailable and then not al_error.details.same_string_general (Missing_file))
			assert_integers_equal ("nothing attached", 0, l_set.attached_count)
			assert_false ("not created", (create {RAW_FILE}.make_with_name (Missing_file)).exists)
			l_set.close
			fixture.delete_file (Main_file)
		end

	test_detach_refused_while_a_cursor_is_open
			-- SQLite refuses to detach a pack while a statement on it is still open; the
			-- alias stays recorded and the reason is reported. Closing the cursor lets it go.
		local
			l_set: BIB_SOURCE_SET
			l_cursor: SIMPLE_SQL_CURSOR
		do
			fixture.build_main (Main_file)
			fixture.build_main (Pack_file)
			create l_set.make
			l_set.open_core (Main_file)
			l_set.attach ("pk", Pack_file)
			if attached l_set.database as al_db then
				l_cursor := al_db.query_cursor ("SELECT id FROM pk.t")
				l_cursor.start
				assert_false ("cursor mid walk", l_cursor.after)
				l_set.detach ("pk")
				assert_true ("refused and reported", attached l_set.last_error as al_error and then al_error.code = {BIB_ERROR}.Database_problem)
				assert_integers_equal ("alias kept", 1, l_set.attached_count)
				l_cursor.close
				l_set.detach ("pk")
				assert_true ("detached after close", l_set.last_error = Void)
				assert_integers_equal ("none attached", 0, l_set.attached_count)
			else
				assert_true ("connection when open", False)
			end
			l_set.close
			fixture.delete_file (Main_file)
			fixture.delete_file (Pack_file)
		end

feature {NONE} -- Fixture

	Main_file: STRING = "srcset_main.db"
	Pack_file: STRING = "srcset_pack.db"
	Missing_file: STRING = "srcset_missing.db"
	Garbage_file: STRING = "srcset_garbage.db"
	Folder_path: STRING = "srcset_folder.db"

	fixture: CONC_FIXTURE
			-- The test-file helpers shared with TEST_CONCORDANCE (design scan 27).
		once
			create Result
		end

end
