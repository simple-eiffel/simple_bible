note
	description: "User data keyed to hub ids; append-only; the Markdown note store (AC-1a-39..43)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_USER_STORE

inherit
	TEST_SET_BASE

feature -- Tests

	test_hub_id_is_english_numbering
			-- Larry, 2026-10-27: the verse identity user items anchor to is the verse's place in
			-- English (KJV) numbering.
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			assert_true ("Jude 1:5", l_hub.hub_id (65, 1, 5) = 65001005)
			assert_true ("John 3:16", l_hub.hub_id (43, 3, 16) = 43003016)
			assert_true ("Psalm 119:176 and back", l_hub.book_of (19119176) = 19 and l_hub.chapter_of (19119176) = 119 and l_hub.verse_of (19119176) = 176)
			assert_false ("verse 0 is no verse", l_hub.is_valid_hub (43003000))
			assert_false ("chapter 0 is no verse", l_hub.is_valid_hub (43000016))
		end

	test_notes_keep_every_version
			-- T2's store: a note on a verse is saved, changed into a new version with the old one
			-- kept, soft-deleted and restored with its history, listed by verse, and still there
			-- after user.db is closed and opened again; settings too.
		local
			l_user: BIB_USER_STORE
			l_notes: BIB_DB_NOTE_STORE
			l_note, l_topic: BIB_NOTE
			l_hub: INTEGER_64
			l_id: INTEGER_64
		do
			clean_user_file
			create l_user.make (User_file)
			l_user.open
			assert_true ("created and open", l_user.is_open and l_user.schema_version = 1)
			create l_notes.make (l_user)
			assert_true ("writable", l_notes.is_writable)
			l_hub := (create {BIB_HUB_ID}).hub_id (43, 3, 16)
			create l_note.make (l_hub, "", "God so loved")
			l_notes.add_note (l_note)
			assert_true ("saved", l_notes.last_error = Void and l_note.is_stored)
			l_id := l_note.id
			assert_integers_equal ("one note on the verse", 1, l_notes.note_count (l_hub))
			l_notes.update_note (l_id, "God so loved the world")
			assert_integers_equal ("two versions", 2, l_notes.version_count (l_id))
			assert_strings_equal ("the first kept", "God so loved", l_notes.version_body (l_id, 1))
			assert_strings_equal ("the current", "God so loved the world", l_notes.current_body (l_id))
			l_notes.remove_note (l_id)
			assert_true ("soft deleted", l_notes.is_deleted (l_id) and l_notes.note_count (l_hub) = 0)
			assert_integers_equal ("history kept", 2, l_notes.version_count (l_id))
			l_notes.restore_note (l_id)
			assert_true ("restored", not l_notes.is_deleted (l_id) and l_notes.note_count (l_hub) = 1)
			create l_topic.make_topical ("Covenant", "a topical note")
			l_notes.add_note (l_topic)
			assert_integers_equal ("topical notes apart", 1, l_notes.note_count (0))
			assert_integers_equal ("three versions in all", 3, l_notes.total_note_versions)
			l_user.set_setting ("layout", "study")
			l_user.close
			create l_user.make (User_file)
			l_user.open
			create l_notes.make (l_user)
			assert_true ("kept across a reopen", l_notes.notes_for (l_hub).count = 1 and then l_notes.notes_for (l_hub).first.body.same_string ("God so loved the world"))
			assert_true ("setting kept", l_user.has_setting ("layout") and then l_user.setting ("layout").same_string ("study"))
			l_user.close
			clean_user_file
		end

	test_notes_export_and_import_never_overwrite
			-- Debate 02: every live note exported as its own Markdown file (id-based name, `id' and
			-- `hub_id' front matter, written atomically, the folder made); a deleted note is not
			-- exported. Importing: a changed file becomes a new version, an unknown file a new note,
			-- an untouched one changes nothing; nothing is ever overwritten.
		local
			l_user: BIB_USER_STORE
			l_notes: BIB_DB_NOTE_STORE
			l_kept, l_gone: BIB_NOTE
			l_hub: INTEGER_64
			l_file: SIMPLE_FILE
			l_ok: BOOLEAN
		do
			clean_user_file
			clean_export_folder
			create l_user.make (User_file)
			l_user.open
			create l_notes.make (l_user)
			l_hub := (create {BIB_HUB_ID}).hub_id (65, 1, 5)
			create l_kept.make (l_hub, "Remind: 5-7", "Once saved, then destroyed")
			l_notes.add_note (l_kept)
			create l_gone.make (l_hub, "", "to be deleted")
			l_notes.add_note (l_gone)
			l_notes.remove_note (l_gone.id)
			l_notes.export_notes (Export_folder)
			assert_integers_equal ("one live note, one file", 1, l_notes.files_written)
			assert_integers_equal ("no failure", 0, l_notes.failures)
			assert_strings_equal ("id-based name", "note-" + l_kept.id.out + ".md", l_notes.written_names.first)
			assert_true ("front matter", l_notes.has_front_matter_keys (Export_folder, l_notes.written_names.first))
				-- The reader edits the exported file and writes a new one beside it.
			create l_file.make ({STRING_32} "" + Export_folder + {STRING_32} "\" + l_notes.written_names.first)
			l_ok := l_file.write_text_utf_8 ("---%Nid: " + l_kept.id.out + "%Nhub_id: " + l_hub.out + "%N---%NOnce saved, then destroyed: Numbers 14.%N")
			create l_file.make (Export_folder + "\fresh.md")
			l_ok := l_file.write_text_utf_8 ("---%Nhub_id: " + l_hub.out + "%N---%NA new thought on verse 5.%N")
			l_notes.import_notes (Export_folder)
			assert_integers_equal ("two files read", 2, l_notes.imported_count)
			assert_integers_equal ("one new version", 1, l_notes.new_versions_count)
			assert_integers_equal ("one new note", 1, l_notes.new_notes_count)
			assert_integers_equal ("nothing overwritten", 0, l_notes.versions_rewritten)
			assert_strings_equal ("the old version kept", "Once saved, then destroyed", l_notes.version_body (l_kept.id, 1))
			assert_strings_equal ("the new version", "Once saved, then destroyed: Numbers 14.", l_notes.current_body (l_kept.id))
			assert_integers_equal ("two live notes on the verse", 2, l_notes.note_count (l_hub))
			l_notes.import_notes (Export_folder)
			assert_true ("again: nothing new from the edited file", l_notes.new_versions_count = 0 and l_notes.unchanged_count >= 1)
			l_user.close
			clean_export_folder
			clean_user_file
		end

	test_a_topical_title_survives_export_and_import
			-- Scan 39: a topical note's title is exported in its front matter; importing it into a
			-- fresh store keeps that title. Before: the file name ("note-1") came back instead.
		local
			l_user: BIB_USER_STORE
			l_notes: BIB_DB_NOTE_STORE
			l_topic: BIB_NOTE
		do
			clean_user_file
			clean_export_folder
			create l_user.make (User_file)
			l_user.open
			create l_notes.make (l_user)
			create l_topic.make_topical ("Covenant: a theme", "Notes on covenant.")
			l_notes.add_note (l_topic)
			l_notes.export_notes (Export_folder)
			l_user.close
			clean_user_file
			create l_user.make (User_file)
			l_user.open
			create l_notes.make (l_user)
			l_notes.import_notes (Export_folder)
			assert_integers_equal ("one new note", 1, l_notes.new_notes_count)
			assert_strings_equal ("its title kept", "Covenant: a theme", l_notes.notes_for (0).first.title)
			l_user.close
			clean_export_folder
			clean_user_file
		end

	test_user_store_refuses_another_schema
			-- A user.db of a schema this program does not read is refused and left as it is.
		local
			l_user: BIB_USER_STORE
			l_db: SIMPLE_SQL_DATABASE
		do
			clean_user_file
			create l_db.make (User_file)
			l_db.execute ("PRAGMA user_version = 9")
			l_db.close
			create l_user.make (User_file)
			l_user.open
			assert_false ("not open", l_user.is_open)
			assert_true ("says why", attached l_user.last_error as al_e and then al_e.code = {BIB_ERROR}.Schema_mismatch)
			clean_user_file
		end

feature {NONE} -- User file

	Export_folder: STRING = "test_notes_export"

	clean_export_folder
			-- Delete the folder the export test writes.
		local
			l_ok: BOOLEAN
			l_folder: SIMPLE_FILE
		do
			create l_folder.make (Export_folder)
			if l_folder.is_directory then
				l_ok := l_folder.delete_directory_recursive
			end
		end

	User_file: STRING = "test_user_store.db"

	clean_user_file
			-- Delete the file these tests write, its handles collected first.
		local
			l_memory: MEMORY
			l_fixture: CONC_FIXTURE
		do
			create l_memory
			l_memory.full_collect
			create l_fixture
			l_fixture.delete_file (User_file)
		end

feature -- Tests (continued)

	test_notes_keyed_by_hub_id
		local
			n: BIB_NOTE
		do
			create n.make (2501, "", "God so loved")
			assert ("keyed", n.hub_id = 2501 and not n.is_topical)
			assert ("unstored", not n.is_stored)
			create n.make_topical ("Covenant", "notes")
			assert ("topical", n.is_topical)
		end

	test_user_items_carry_no_version
			-- A highlight is keyed by hub id only; there is no version field to diverge (AC-1a-39).
		local
			h: BIB_HIGHLIGHT
		do
			create h.make (2501, "promise")
			assert ("hub id", h.hub_id = 2501)
			assert ("kind", h.kind = {BIB_USER_STORE}.Kind_highlight)
		end

	test_user_store_is_the_only_writer
		local
			u: BIB_USER_STORE
			c: BIB_CONTENT_SOURCE
		do
			create u.make ("user.db")
			create c.make ("content.db")
			assert ("user store writes", not u.is_read_only)
			assert ("content read-only", c.is_read_only)
		end

	test_note_export_names_are_file_safe
			-- Debate 02: export file names are id-based or sanitized, never a raw
			-- title; a title like "Romans 8:28" is not a file name.
		local
			l_notes: BIB_DB_NOTE_STORE
		do
			create l_notes.make (create {BIB_USER_STORE}.make ("user.db"))
			assert ("id-based name", l_notes.is_file_safe_name ("note-42.md"))
			assert ("CONSOLE is not a device", l_notes.is_file_safe_name ("CONSOLE.md"))
			assert ("colon refused", not l_notes.is_file_safe_name ("Romans 8:28.md"))
			assert ("pipe refused", not l_notes.is_file_safe_name ("a|b.md"))
			assert ("device name refused", not l_notes.is_file_safe_name ("CON.md"))
			assert ("device name in lower case refused", not l_notes.is_file_safe_name ("prn"))
			assert ("COM1 with an extension refused", not l_notes.is_file_safe_name ("COM1.txt"))
			assert ("trailing dot refused", not l_notes.is_file_safe_name ("notes."))
			assert ("trailing space refused", not l_notes.is_file_safe_name ("notes "))
			assert ("tab refused", not l_notes.is_file_safe_name ({STRING_32} "a%Tb"))
			assert ("empty refused", not l_notes.is_file_safe_name (""))
			assert ("nothing written yet", l_notes.files_written = 0)
		end

	test_file_safe_name_scan23_gaps
			-- Scan 23: names Windows also refuses that the first rule let through.
		local
			l_notes: BIB_DB_NOTE_STORE
		do
			create l_notes.make (create {BIB_USER_STORE}.make ("user.db"))
			assert ("COM0 refused", not l_notes.is_file_safe_name ("COM0.md"))
			assert ("LPT0 refused", not l_notes.is_file_safe_name ("lpt0"))
			assert ("COM superscript one refused", not l_notes.is_file_safe_name ({STRING_32} "COM%/185/.md"))
			assert ("LPT superscript three refused", not l_notes.is_file_safe_name ({STRING_32} "LPT%/179/"))
			assert ("CONIN$ refused", not l_notes.is_file_safe_name ("CONIN$"))
			assert ("CONOUT$ refused", not l_notes.is_file_safe_name ("conout$.txt"))
			assert ("device name before a spaced extension refused", not l_notes.is_file_safe_name ("NUL .md"))
			assert ("less-than refused", not l_notes.is_file_safe_name ("a<b"))
			assert ("greater-than refused", not l_notes.is_file_safe_name ("a>b"))
			assert ("quote refused", not l_notes.is_file_safe_name ("a%"b"))
			assert ("slash refused", not l_notes.is_file_safe_name ("a/b"))
			assert ("backslash refused", not l_notes.is_file_safe_name ("a\b"))
			assert ("question mark refused", not l_notes.is_file_safe_name ("a?b"))
			assert ("asterisk refused", not l_notes.is_file_safe_name ("a*b"))
			assert ("COM10 is not a device", l_notes.is_file_safe_name ("COM10.md"))
		end

	test_highlight_shows_in_every_version
			-- Skeletal (Phase 5, AC-1a-39): a BSB highlight on John 3:16 appears on John 3:16 in every version.
		do
		end

	test_edit_appends_and_delete_is_soft
			-- Skeletal (Phase 5, AC-1a-40): an edit writes a new version; a delete is soft; both restore.
		do
		end

	test_backup_on_exit_restores
			-- Skeletal (Phase 5, AC-1a-40): a rotating backup is written on exit and restores.
		do
		end

	test_previous_schema_migrates
			-- Skeletal (Phase 5, AC-1a-41): the previous-schema fixture migrates with every setting, layout and note.
		do
		end

	test_markdown_store_is_default_with_index
			-- Skeletal (Phase 5, AC-1a-42; RQ-06 gate): notes as Markdown files, user.db as index, plain verse links.
		do
		end

	test_markdown_external_edit_gets_conflict_copy
			-- Skeletal (Phase 5, AC-1a-43): a file changed outside the program is never overwritten.
		do
		end

	test_markdown_second_instance_read_only
			-- Skeletal (Phase 5, AC-1a-43): a second instance opens read-only.
		do
		end

	test_markdown_rename_leaves_no_dangling_row
			-- Skeletal (Phase 5, AC-1a-43): a renamed or deleted file leaves no dangling index row.
		do
		end

end
