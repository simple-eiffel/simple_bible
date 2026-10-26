note
	description: "[
		SIMPLE_BIBLE.open for real (Phase 4, Task 7a): content.db v1 is checked
		(research/18) and required; the concordance pack attaches by `conc_path',
		and a missing or refused pack leaves the Bible open with the reason in
		`conc_error' (Larry, 2026-10-26). The databases are made here and deleted.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_FACADE_OPEN

inherit
	TEST_SET_BASE

feature -- Tests

	test_open_with_content_and_concordance
			-- content.db and the pack open; the lookups answer through the facade.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.build (Pack_file)
			l_bible := bible (Pack_file, "")
			l_bible.open
			assert_true ("open", l_bible.is_open and l_bible.last_error = Void)
			assert_strings_equal ("edition is the latest build", {CONC_FIXTURE}.Content_edition, l_bible.database_edition)
			assert_true ("concordance available", l_bible.conc_error = Void and l_bible.conc_pack.is_available)
			assert_true ("word view", l_bible.word_lookup.view ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS").is_success)
			assert_integers_equal ("english", 1, l_bible.english_index.rows ("created").count)
			assert_false ("no ai rows in v1", l_bible.has_ai_data)
			l_bible.close
			assert_false ("closed", l_bible.is_open)
			remove_test_files
		end

	test_open_without_a_concordance
			-- No `conc_path': the Bible opens and the concordance is simply absent.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			l_bible := bible ("", "")
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("no reason needed", l_bible.conc_error = Void)
			assert_false ("not available", l_bible.conc_pack.is_available)
			l_bible.close
			remove_test_files
		end

	test_missing_concordance_keeps_the_bible_open
			-- A `conc_path' with no file: open, with the reason (Larry's policy).
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.delete_file (Pack_file)
			l_bible := bible (Pack_file, "")
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("reason", attached l_bible.conc_error as al_e and then al_e.code = {BIB_ERROR}.Source_unavailable)
			l_bible.close
			remove_test_files
		end

	test_refused_concordance_keeps_the_bible_open
			-- A pack at another version: open, refused with the reason, and detached.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.build_variant (Pack_file, 0, "")
			l_bible := bible (Pack_file, "")
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("refused", attached l_bible.conc_error as al_e and then al_e.code = {BIB_ERROR}.Schema_mismatch)
			assert_false ("detached", l_bible.conc_pack.is_attached)
			l_bible.close
			remove_test_files
		end

	test_content_at_another_version_is_refused
			-- content.db is required: a wrong version leaves the engine closed with the reason.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, 0, False)
			l_bible := bible ("", "")
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("version named", attached l_bible.last_error as al_e and then al_e.code = {BIB_ERROR}.Schema_mismatch and then al_e.message.has_substring ("version 0"))
			remove_test_files
		end

	test_content_without_provenance_is_refused
			-- K7-A: a content table without a provenance column bound to source_provenance.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, True)
			l_bible := bible ("", "")
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("provenance named", attached l_bible.last_error as al_e and then al_e.message.has_substring ("provenance_key"))
			remove_test_files
		end

	test_missing_content_is_refused
			-- No content.db: the engine stays closed and says so.
		local
			l_bible: SIMPLE_BIBLE
		do
			fixture.delete_file (Content_file)
			l_bible := bible ("", "")
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("named", attached l_bible.last_error as al_e and then al_e.code = {BIB_ERROR}.Source_unavailable)
		end

	test_pack_folder_scan_skips_the_concordance
			-- FR-166: conc.db inside the pack folder is found by `conc_path', not counted as a pack.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			fixture.build (Folder_pack_file)
			l_bible := bible (Folder_pack_file, Folder)
			assert_integers_equal ("not a generic pack", 0, l_bible.pack_count)
			l_bible.open
			assert_true ("open with the concordance", l_bible.is_open and l_bible.conc_pack.is_available)
			l_bible.close
			remove_test_files
		end

	test_pack_folder_scan_compares_files_not_spellings
			-- FR-166 again, with the paths spelled differently: a relative pack folder and an absolute
			-- `conc_path', then a `conc_path' through "..". Still one file, still not a generic pack
			-- (design scan 29: the scan compared spellings, so conc.db counted and `open' refused).
		local
			l_bible: SIMPLE_BIBLE
			l_absolute: STRING_32
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			fixture.build (Folder_pack_file)
			l_absolute := (create {SIMPLE_FILE}.make (Folder_pack_file)).absolute_path
			l_bible := bible (l_absolute.to_string_8, Folder)
			assert_integers_equal ("absolute conc_path is the folder's file", 0, l_bible.pack_count)
			l_bible.open
			assert_true ("open", l_bible.is_open and l_bible.conc_pack.is_available)
			l_bible.close
			l_bible := bible ("facade_test_packs\..\facade_test_packs\conc.db", Folder)
			assert_integers_equal ("dotted conc_path is the folder's file", 0, l_bible.pack_count)
			remove_test_files
		end

	test_generic_pack_waits_for_task_7b
			-- Until Task 7b, a generic pack in the folder makes `open' refuse with a named reason.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			fixture.build_main (Folder_other_file)
			l_bible := bible ("", Folder)
			assert_integers_equal ("one generic pack", 1, l_bible.pack_count)
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("named", attached l_bible.last_error as al_e and then al_e.message.has_substring ("Generic private packs"))
			remove_test_files
		end

	test_book_catalog_reads_content_db
			-- The catalog reads content.db's book_catalog: a name, a code and a prefix find their book;
			-- an unknown name finds none (research/18; the verse box's books).
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			l_bible := bible ("", "")
			l_bible.open
			assert_integers_equal ("books", 3, l_bible.books.book_count)
			assert_strings_equal ("name", "Matthew", l_bible.books.book (40).name)
			assert_true ("by name", l_bible.books.candidates_for_name ("Genesis").count = 1 and then l_bible.books.candidates_for_name ("Genesis").first = 1)
			assert_true ("by code", l_bible.books.candidates_for_name ("mat").first = 40)
			assert_true ("by prefix", l_bible.books.candidates_for_name ("Exo").first = 2)
			assert_true ("dotted abbreviation", l_bible.books.candidates_for_name ("Gen.").first = 1)
			assert_true ("unknown", l_bible.books.candidates_for_name ("Zzz").is_empty)
			l_bible.close
			remove_test_files
		end

	test_edition_swap_needs_no_code
			-- FR-158, V-54: the same engine reads either pack by `conc_path' alone; the edition shown
			-- is the pack's own label, so no engine code tests the edition.
		local
			l_personal, l_distribution: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.build (Pack_file)
			fixture.build (Other_pack_file)
			create l_db.make (Other_pack_file)
			l_db.execute ("UPDATE meta SET value = 'DISTRIBUTION TEST' WHERE key = 'edition_label'")
			l_db.close
			l_personal := bible (Pack_file, "")
			l_personal.open
			assert_strings_equal ("personal label", {CONC_FIXTURE}.Edition_label, l_personal.conc_pack.edition_label)
			l_personal.close
			l_distribution := bible (Other_pack_file, "")
			l_distribution.open
			assert_strings_equal ("distribution label", "DISTRIBUTION TEST", l_distribution.conc_pack.edition_label)
			assert_true ("same lookups", l_distribution.word_lookup.view ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS").is_success)
			l_distribution.close
			fixture.delete_file (Other_pack_file)
			remove_test_files
		end

feature {NONE} -- Fixture

	Other_pack_file: STRING = "facade_test_other_pack.db"

	Content_file: STRING = "facade_test_content.db"
	Pack_file: STRING = "facade_test_pack.db"
	Folder: STRING = "facade_test_packs"
	Folder_pack_file: STRING = "facade_test_packs\conc.db"
	Folder_other_file: STRING = "facade_test_packs\other.db"

	fixture: CONC_FIXTURE
			-- The shared test-file helpers.
		once
			create Result
		end

	opened_bibles: ARRAYED_LIST [SIMPLE_BIBLE]
			-- Every engine these tests made, so one that a failed test left open is closed.
		once
			create Result.make (4)
		end

	close_leftovers
			-- Close any engine a failed test left open.
		do
			across opened_bibles as ic loop
				if ic.is_open then
					ic.close
				end
			end
			opened_bibles.wipe_out
		ensure
			none_left: opened_bibles.is_empty
		end

	bible (a_conc_path, a_pack_folder: STRING): SIMPLE_BIBLE
			-- An unopened engine over `Content_file' with these paths.
		local
			l_config: BIB_CONFIG
		do
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_conc_path (a_conc_path)
			l_config := l_config.set_pack_folder (a_pack_folder)
			create Result.make (l_config)
			opened_bibles.extend (Result)
		end

	make_folder
			-- Create `Folder' when absent, and empty it of the files these tests write.
		local
			l_ok: BOOLEAN
		do
			fixture.delete_file (Folder_pack_file)
			fixture.delete_file (Folder_other_file)
			if not (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).create_directory
			end
		end

	remove_test_files
			-- Delete every file and the folder these tests write.
		local
			l_ok: BOOLEAN
		do
			close_leftovers
			fixture.delete_file (Content_file)
			fixture.delete_file (Pack_file)
			fixture.delete_file (Folder_pack_file)
			fixture.delete_file (Folder_other_file)
			if (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).delete_directory
			end
		end

end
