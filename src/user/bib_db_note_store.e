note
	description: "[
		Notes in user.db: the Release 1a store (2026-10-26 spec fold, debate 02
		pathway B, PREFERRED). It exports every live note as a Markdown file the
		program never reads back (a read-only copy, outside the vault by default)
		and imports Markdown notes as new rows or new versions, never overwriting.
		BIB_MARKDOWN_NOTE_STORE is the Release 1b candidate. Which class finally
		holds export and import is a Phase 4 design item (settlement G3).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_DB_NOTE_STORE

inherit
	BIB_NOTE_STORE

create
	make

feature {NONE} -- Initialization

	make (a_store: BIB_USER_STORE)
		do
			store := a_store
			create written_names.make (0)
			written_names.compare_objects
			create atomic_names.make (0)
			atomic_names.compare_objects
			create export_errors.make (0)
		ensure
			store_set: store = a_store
			nothing_written: written_names.is_empty
		end

feature -- Access

	store: BIB_USER_STORE

	note_count (a_hub_id: INTEGER_64): INTEGER
		do
			if store.is_open then
				Result := store.count_of (store.connection.query_with_args ("SELECT count(*) AS n FROM note WHERE hub_id = ? AND deleted = 0", <<a_hub_id>>))
			end
		end

	version_count (a_id: INTEGER_64): INTEGER
		do
			if store.is_open then
				Result := store.count_of (store.connection.query_with_args ("SELECT count(*) AS n FROM note_version WHERE note_id = ?", <<a_id>>))
			end
		end

	version_body (a_id: INTEGER_64; a_version: INTEGER): STRING_32
		do
			Result := store.first_text (store.connection.query_with_args ("SELECT body FROM note_version WHERE note_id = ? AND version = ?", <<a_id, a_version>>))
		end

	current_body (a_id: INTEGER_64): STRING_32
			-- The body of note `a_id''s latest version; empty when there is no such note.
		do
			create Result.make_empty
			if store.is_open then
				Result := store.first_text (store.connection.query_with_args ("SELECT body FROM note_version WHERE note_id = ? ORDER BY version DESC LIMIT 1", <<a_id>>))
			end
		end

	notes_for (a_hub_id: INTEGER_64): ARRAYED_LIST [BIB_NOTE]
			-- Live notes on `a_hub_id', oldest first, each with its current body.
		local
			l_note: BIB_NOTE
		do
			create Result.make (4)
			if store.is_open then
				across store.connection.query_with_args ("SELECT n.note_id, n.title, n.created_at, (SELECT v.body FROM note_version v WHERE v.note_id = n.note_id ORDER BY v.version DESC LIMIT 1) AS body FROM note n WHERE n.hub_id = ? AND n.deleted = 0 ORDER BY n.note_id", <<a_hub_id>>).rows as ic loop
					if a_hub_id > 0 then
						create l_note.make (a_hub_id, ic.string_value ("title"), ic.string_value ("body"))
					else
						create l_note.make_topical (ic.string_value ("title"), ic.string_value ("body"))
					end
					l_note.mark_stored (ic.integer_64_value ("note_id"), time_of (ic.string_value ("created_at")))
					Result.extend (l_note)
				end
			end
		end

	notes_between (a_first_hub, a_last_hub: INTEGER_64): ARRAYED_LIST [BIB_NOTE]
			-- Live notes on the verses `a_first_hub' to `a_last_hub' (a chapter: BIB_HUB_ID's verse 1
			-- to 999), in verse order, then oldest first; each with its current body.
		require
			ordered: 0 < a_first_hub and a_first_hub <= a_last_hub
		local
			l_note: BIB_NOTE
		do
			create Result.make (8)
			if store.is_open then
				across store.connection.query_with_args ("SELECT n.note_id, n.hub_id, n.title, n.created_at, (SELECT v.body FROM note_version v WHERE v.note_id = n.note_id ORDER BY v.version DESC LIMIT 1) AS body FROM note n WHERE n.hub_id BETWEEN ? AND ? AND n.deleted = 0 ORDER BY n.hub_id, n.note_id", <<a_first_hub, a_last_hub>>).rows as ic loop
					create l_note.make (ic.integer_64_value ("hub_id"), ic.string_value ("title"), ic.string_value ("body"))
					l_note.mark_stored (ic.integer_64_value ("note_id"), time_of (ic.string_value ("created_at")))
					Result.extend (l_note)
				end
			end
		ensure
			in_range: across Result as ic all ic.hub_id >= a_first_hub and ic.hub_id <= a_last_hub and not ic.is_deleted end
		end

feature -- Status

	is_writable: BOOLEAN
		do
			Result := store.is_open and not store.is_read_only
		end

	is_deleted (a_id: INTEGER_64): BOOLEAN
		do
			if store.is_open then
				Result := store.count_of (store.connection.query_with_args ("SELECT count(*) AS n FROM note WHERE note_id = ? AND deleted = 1", <<a_id>>)) = 1
			end
		end

feature -- Commands

	add_note (a_note: BIB_NOTE)
			-- Store `a_note' and its body as version 1, in one transaction.
		local
			l_db: SIMPLE_SQL_DATABASE
			l_at: STRING_8
			l_id: INTEGER_64
		do
			last_error := Void
			l_db := store.connection
			l_at := store.now_text
			l_db.begin_transaction
			l_db.execute_with_args ("INSERT INTO note(hub_id, title, created_at, changed_at) VALUES (?, ?, ?, ?)", <<a_note.hub_id, a_note.title, l_at, l_at>>)
			if not l_db.has_error then
				l_id := l_db.last_insert_rowid
				l_db.execute_with_args ("INSERT INTO note_version(note_id, version, body, written_at) VALUES (?, 1, ?, ?)", <<l_id, a_note.body, l_at>>)
			end
			finish (l_db, "The note could not be saved.")
			if last_error = Void then
				a_note.mark_stored (l_id, time_of (l_at))
			end
		end

	update_note (a_id: INTEGER_64; a_body: READABLE_STRING_GENERAL)
			-- `a_body' becomes note `a_id''s next version; every earlier one is kept.
		local
			l_db: SIMPLE_SQL_DATABASE
			l_at: STRING_8
		do
			last_error := Void
			l_db := store.connection
			l_at := store.now_text
			l_db.begin_transaction
			l_db.execute_with_args ("INSERT INTO note_version(note_id, version, body, written_at) VALUES (?, (SELECT coalesce(max(version), 0) + 1 FROM note_version WHERE note_id = ?), ?, ?)",
				<<a_id, a_id, a_body.to_string_32, l_at>>)
			if not l_db.has_error then
				l_db.execute_with_args ("UPDATE note SET changed_at = ? WHERE note_id = ?", <<l_at, a_id>>)
			end
			finish (l_db, "The note could not be changed.")
		end

	remove_note (a_id: INTEGER_64)
			-- Soft delete: the note and its history stay, restorable.
		do
			set_deleted (a_id, True)
		end

	restore_note (a_id: INTEGER_64)
		do
			set_deleted (a_id, False)
		end


feature -- Export and import (debate 02 pathway B)

	export_notes (a_folder: READABLE_STRING_GENERAL)
			-- Write one Markdown file per live note into `a_folder', creating it if
			-- missing: `id' and `hub_id' front matter, a file-safe name (id-based or
			-- sanitized, never a raw title), each written atomically (a temporary
			-- file in the same folder, flushed, moved over with write-through).
		require
			open: store.is_open
			folder_chosen: not a_folder.is_empty
		local
			l_folder, l_file: SIMPLE_FILE
			l_name: STRING_32
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
		do
			written_names.wipe_out
			atomic_names.wipe_out
			export_errors.wipe_out
			failures := 0
			failures_reported := 0
			create l_folder.make (a_folder)
			create l_rows.make (16)
			across store.connection.query (Live_notes_sql).rows as ic loop
				l_rows.extend (ic)
			end
			if not (l_folder.is_directory or else l_folder.create_directory_recursive) then
				failures := l_rows.count
				across l_rows as ic loop
					report_failure ({STRING_32} "note " + ic.integer_64_value ("note_id").out + {STRING_32} ": the folder could not be made: " + a_folder.to_string_32)
				end
			else
				across l_rows as ic loop
					l_name := {STRING_32} "note-" + ic.integer_64_value ("note_id").out + {STRING_32} ".md"
					create l_file.make (joined_path (a_folder, l_name))
					if l_file.write_text_utf_8 (note_file_text (ic)) then
							-- simple_file writes through a temporary file, flushed, moved over the target.
						written_names.extend (l_name)
						atomic_names.extend (l_name)
					else
						failures := failures + 1
						report_failure (l_name + {STRING_32} ": " + l_file.last_error)
					end
				end
			end
		ensure
			every_failure_reported: failures_reported = failures
			accounted_for: files_written + failures = live_note_count
			names_are_safe: across written_names as ic_name all is_file_safe_name (ic_name) end
			names_distinct: across written_names as ic_name all written_names.occurrences (ic_name) = 1 end
			front_matter_keys: across written_names as ic_name all has_front_matter_keys (a_folder, ic_name) end
			atomic: across written_names as ic_name all was_written_atomically (ic_name) end
			folder_created: folder_exists (a_folder) or failures > 0
			notes_unchanged: total_note_versions = old total_note_versions
		end

	import_notes (a_folder: READABLE_STRING_GENERAL)
			-- Read the Markdown notes in `a_folder': an unknown `id' becomes a new
			-- note; a changed body of a known `id' becomes a new version. Nothing is
			-- ever overwritten.
		require
			open: store.is_open
			writable: is_writable
			folder_chosen: not a_folder.is_empty
		local
			l_file: SIMPLE_FILE
			l_text, l_body, l_stem: STRING_32
			l_keys: HASH_TABLE [STRING_32, STRING_32]
			l_id, l_hub: INTEGER_64
			l_note: BIB_NOTE
			l_hubs: BIB_HUB_ID
		do
			imported_count := 0
			new_notes_count := 0
			new_versions_count := 0
			unchanged_count := 0
			skipped_count := 0
			versions_rewritten := 0
			export_errors.wipe_out
			create l_hubs
			across (create {SIMPLE_FILE}.make (a_folder)).files_with_extension ("md") as ic loop
				create l_file.make (joined_path (a_folder, ic))
				l_text := l_file.read_text_utf_8
				l_text.replace_substring_all ({STRING_32} "%R%N", {STRING_32} "%N")
				l_keys := front_matter (l_text)
				l_body := body_after_front_matter (l_text)
				l_id := key_number (l_keys, {STRING_32} "id")
				l_hub := key_number (l_keys, {STRING_32} "hub_id")
				if l_hub /= 0 and not l_hubs.is_valid_hub (l_hub) then
					skipped_count := skipped_count + 1
					report_failure (ic + {STRING_32} ": its hub_id names no verse.")
				elseif l_id > 0 and then note_exists (l_id) then
					imported_count := imported_count + 1
					if is_deleted (l_id) or else current_body (l_id).same_string (l_body) then
							-- A deleted note is never written into; the file is counted, nothing changes.
						unchanged_count := unchanged_count + 1
					else
						update_note (l_id, l_body)
						if last_error = Void then
							new_versions_count := new_versions_count + 1
						else
							imported_count := imported_count - 1
							skipped_count := skipped_count + 1
						end
					end
				else
					if l_hub > 0 then
						create l_note.make (l_hub, key_text (l_keys, {STRING_32} "title"), l_body)
					else
						l_stem := ic.twin
						l_stem.remove_tail (3)
						create l_note.make_topical (l_stem, l_body)
					end
					add_note (l_note)
					if last_error = Void then
						imported_count := imported_count + 1
						new_notes_count := new_notes_count + 1
					else
						skipped_count := skipped_count + 1
					end
				end
			end
		ensure
			never_overwrites: versions_rewritten = 0
			only_grows: total_note_versions >= old total_note_versions
			every_file_accounted_for: imported_count = new_notes_count + new_versions_count + unchanged_count
		end

feature -- Export and import: accounting

	written_names: ARRAYED_LIST [STRING_32]
			-- File names the last export wrote.

	files_written: INTEGER
			-- Files the last export wrote.
		do
			Result := written_names.count
		end

	failures: INTEGER
			-- Notes the last export could not write.

	failures_reported: INTEGER
			-- Failures the last export reported (each with its reason).

	live_note_count: INTEGER
			-- Notes not soft-deleted.
		require
			open: store.is_open
		do
			Result := store.count_of (store.connection.query ("SELECT count(*) AS n FROM note WHERE deleted = 0"))
		ensure
			non_negative: Result >= 0
		end

	total_note_versions: INTEGER
			-- Every version of every note, deleted ones included.
		do
			Result := store.total_note_versions
		ensure
			non_negative: Result >= 0
		end

	imported_count, new_notes_count, new_versions_count, unchanged_count, versions_rewritten: INTEGER
			-- Files the last import read; of those, the new notes, the new versions and
			-- the unchanged notes; and versions it overwrote (always 0).

	skipped_count: INTEGER
			-- Files the last import could not take (a hub_id naming no verse, a failed write).

	export_errors: ARRAYED_LIST [STRING_32]
			-- Why each failure of the last export or import happened, one line each.

	atomic_names: ARRAYED_LIST [STRING_32]
			-- File names the last export wrote through simple_file's atomic write.

	has_front_matter_keys (a_folder, a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the file `a_name' in `a_folder' carry `id' and `hub_id' front matter?
		local
			l_text: STRING_32
			l_keys: HASH_TABLE [STRING_32, STRING_32]
		do
			l_text := (create {SIMPLE_FILE}.make (joined_path (a_folder, a_name))).read_text_utf_8
			l_text.replace_substring_all ({STRING_32} "%R%N", {STRING_32} "%N")
			l_keys := front_matter (l_text)
			Result := l_keys.has ({STRING_32} "id") and l_keys.has ({STRING_32} "hub_id")
		end

	was_written_atomically (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Was `a_name' written through a temporary file and an atomic move?
		do
			Result := atomic_names.has (a_name.to_string_32)
		end

	folder_exists (a_folder: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_folder' exist?
		do
			Result := (create {SIMPLE_FILE}.make (a_folder)).is_directory
		end

feature {NONE} -- Export and import implementation

	Live_notes_sql: STRING_8 = "SELECT n.note_id, n.hub_id, n.title, n.changed_at, (SELECT v.body FROM note_version v WHERE v.note_id = n.note_id ORDER BY v.version DESC LIMIT 1) AS body FROM note n WHERE n.deleted = 0 ORDER BY n.note_id"

	note_file_text (a_row: SIMPLE_SQL_ROW): STRING_32
			-- A note as its Markdown file: front matter (`id', `hub_id', the title when it has one,
			-- when it last changed), then the body.
		do
			Result := {STRING_32} "---%Nid: " + a_row.integer_64_value ("note_id").out + {STRING_32} "%Nhub_id: " + a_row.integer_64_value ("hub_id").out
			if not a_row.string_value ("title").is_empty then
				Result.append ({STRING_32} "%Ntitle: " + quoted (a_row.string_value ("title")))
			end
			Result.append ({STRING_32} "%Nchanged: " + a_row.string_value ("changed_at") + {STRING_32} "%N---%N")
			Result.append (a_row.string_value ("body"))
			Result.append_character ('%N')
		end

	quoted (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' in double quotes, a quote or backslash inside escaped (a title may hold a colon).
		do
			create Result.make (a_text.count + 2)
			Result.append_character ('"')
			across a_text as ic loop
				if ic = '"' or ic = '\' then
					Result.append_character ('\')
				end
				Result.append_character (ic)
			end
			Result.append_character ('"')
		end

	front_matter (a_text: READABLE_STRING_32): HASH_TABLE [STRING_32, STRING_32]
			-- The `key: value' lines between a first line "---" and the next "---"; empty when the
			-- text has none.
		local
			l_lines: LIST [STRING_32]
			l_line: STRING_32
			l_colon, i: INTEGER
			l_done: BOOLEAN
		do
			create Result.make (6)
			Result.compare_objects
			l_lines := a_text.to_string_32.split ('%N')
			if not l_lines.is_empty and then l_lines.first.same_string ({STRING_32} "---") then
				from i := 2 until l_done or i > l_lines.count loop
					l_line := l_lines.i_th (i)
					if l_line.same_string ({STRING_32} "---") then
						l_done := True
					else
						l_colon := l_line.index_of (':', 1)
						if l_colon > 1 then
							Result.force (unquoted (l_line.substring (l_colon + 1, l_line.count)), l_line.substring (1, l_colon - 1))
						end
					end
					i := i + 1
				end
				if not l_done then
					Result.wipe_out
				end
			end
		end

	body_after_front_matter (a_text: READABLE_STRING_32): STRING_32
			-- The text after the front matter (all of it when there is none), its final line break
			-- dropped.
		local
			l_end: INTEGER
		do
			Result := a_text.to_string_32
			if Result.starts_with ({STRING_32} "---%N") then
				l_end := Result.substring_index ({STRING_32} "%N---%N", 4)
				if l_end > 0 then
					Result := Result.substring (l_end + 5, Result.count)
				elseif Result.ends_with ({STRING_32} "%N---") then
					create Result.make_empty
				end
			end
			if Result.ends_with ({STRING_32} "%N") then
				Result.remove_tail (1)
			end
		end

	unquoted (a_value: STRING_32): STRING_32
			-- `a_value' trimmed, its surrounding quotes and escapes removed.
		local
			i: INTEGER
		do
			Result := a_value.twin
			Result.left_adjust
			Result.right_adjust
			if Result.count >= 2 and then Result [1] = '"' and then Result [Result.count] = '"' then
				Result := Result.substring (2, Result.count - 1)
				from i := 1 until i > Result.count loop
					if Result [i] = '\' and i < Result.count then
						Result.remove (i)
					end
					i := i + 1
				end
			end
		end

	key_number (a_keys: HASH_TABLE [STRING_32, STRING_32]; a_key: STRING_32): INTEGER_64
			-- The whole number under `a_key'; 0 when absent or not a number.
		do
			if attached a_keys.item (a_key) as al_value and then al_value.is_integer_64 then
				Result := al_value.to_integer_64
			end
		end

	key_text (a_keys: HASH_TABLE [STRING_32, STRING_32]; a_key: STRING_32): STRING_32
			-- The text under `a_key'; empty when absent.
		do
			if attached a_keys.item (a_key) as al_value then
				Result := al_value
			else
				create Result.make_empty
			end
		end

	note_exists (a_id: INTEGER_64): BOOLEAN
			-- Is there a note `a_id', deleted or not?
		do
			Result := store.count_of (store.connection.query_with_args ("SELECT count(*) AS n FROM note WHERE note_id = ?", <<a_id>>)) = 1
		end

	joined_path (a_folder, a_name: READABLE_STRING_GENERAL): STRING_32
			-- `a_name' inside `a_folder'.
		do
			Result := a_folder.to_string_32
			if not Result.is_empty and then Result [Result.count] /= '\' and then Result [Result.count] /= '/' then
				Result.append_character ('\')
			end
			Result.append_string_general (a_name)
		end

	report_failure (a_reason: READABLE_STRING_GENERAL)
			-- Keep `a_reason' for the reader.
		do
			export_errors.extend (a_reason.to_string_32)
			failures_reported := failures_reported + 1
		end

feature {NONE} -- Implementation

	set_deleted (a_id: INTEGER_64; a_deleted: BOOLEAN)
			-- Mark note `a_id' deleted or live; its versions are untouched.
		local
			l_db: SIMPLE_SQL_DATABASE
			l_flag: INTEGER
		do
			last_error := Void
			l_db := store.connection
			if a_deleted then
				l_flag := 1
			end
			l_db.begin_transaction
			l_db.execute_with_args ("UPDATE note SET deleted = ?, changed_at = ? WHERE note_id = ?", <<l_flag, store.now_text, a_id>>)
			finish (l_db, "The note could not be deleted or restored.")
		end

	finish (a_db: SIMPLE_SQL_DATABASE; a_what: READABLE_STRING_GENERAL)
			-- Commit the open transaction, or roll it back and say `a_what' in `last_error'.
		do
			if a_db.has_error then
				create last_error.make ({BIB_ERROR}.Database_problem, error_text (a_db, a_what))
			elseif a_db.is_in_transaction then
				a_db.commit
				if a_db.has_error then
					create last_error.make ({BIB_ERROR}.Database_problem, error_text (a_db, a_what))
				end
			end
			if a_db.is_in_transaction then
				a_db.rollback
			end
		ensure
			ended: not a_db.is_in_transaction
		end

	error_text (a_db: SIMPLE_SQL_DATABASE; a_what: READABLE_STRING_GENERAL): STRING_32
			-- `a_what', with SQLite's own words when it has any.
		do
			Result := a_what.to_string_32
			if attached a_db.last_error_message as al_message then
				Result.append ({STRING_32} " " + al_message)
			end
		end

	time_of (a_text: READABLE_STRING_GENERAL): SIMPLE_DATE_TIME
			-- The time user.db stored as `a_text'.
		do
			create Result.make_from_iso8601 (a_text.to_string_8)
		end

feature -- Export and import: file names

	is_file_safe_name (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Can `a_name' be a Windows file name as is? Not empty; no control
			-- character and none of < > : " / \ | ? *; not a reserved device name
			-- (CON, PRN, AUX, NUL, COM0-COM9, LPT0-LPT9 and their superscript-digit
			-- forms, CONIN$, CONOUT$), with or without an extension, spaces before
			-- the extension ignored as Windows ignores them; no trailing dot or
			-- space. (Debate 02: a raw title such as "Romans 8:28" is never a file
			-- name. Scan 23 added COM0/LPT0, the superscripts, CONIN$/CONOUT$ and
			-- the spaced extension.)
		local
			i: INTEGER
			l_char: CHARACTER_32
			l_stem: STRING_32
		do
			Result := not a_name.is_empty
			from
				i := 1
			until
				not Result or i > a_name.count
			loop
				l_char := a_name [i]
				Result := l_char.natural_32_code >= 32 and not Reserved_characters.has (l_char)
				i := i + 1
			end
			if Result then
				l_char := a_name [a_name.count]
				Result := l_char /= {CHARACTER_32} '.' and l_char /= {CHARACTER_32} ' '
			end
			if Result then
				l_stem := a_name.to_string_32.as_upper
				if l_stem.has ('.') then
					l_stem := l_stem.substring (1, l_stem.index_of ('.', 1) - 1)
				end
				l_stem.right_adjust
				Result := not Reserved_names.has (l_stem)
			end
		ensure
			empty_unsafe: a_name.is_empty implies not Result
		end

	Reserved_characters: STRING_32 = "<>:%"/\|?*"
			-- Characters Windows forbids in a file name.

	Reserved_names: ARRAYED_LIST [STRING_32]
			-- Device names Windows reserves, with or without an extension.
		once
			create Result.make_from_array (<<{STRING_32} "CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$",
				"COM0", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
				"LPT0", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
				"COM%/185/", "COM%/178/", "COM%/179/", "LPT%/185/", "LPT%/178/", "LPT%/179/">>)
			Result.compare_objects
		end

end
