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
		ensure
			store_set: store = a_store
			nothing_written: written_names.is_empty
		end

feature -- Access

	store: BIB_USER_STORE

	note_count (a_hub_id: INTEGER_64): INTEGER
		do
			-- Phase 4
		end

	version_count (a_id: INTEGER_64): INTEGER
		do
			-- Phase 4
		end

	version_body (a_id: INTEGER_64; a_version: INTEGER): STRING_32
		do
			check implemented_in_phase_4: False then end
		end

	current_body (a_id: INTEGER_64): STRING_32
		do
			check implemented_in_phase_4: False then end
		end

	notes_for (a_hub_id: INTEGER_64): ARRAYED_LIST [BIB_NOTE]
		do
			check implemented_in_phase_4: False then end
		end

feature -- Status

	is_writable: BOOLEAN
		do
			Result := store.is_open and not store.is_read_only
		end

	is_deleted (a_id: INTEGER_64): BOOLEAN
		do
			-- Phase 4
		end

feature -- Commands

	add_note (a_note: BIB_NOTE)
		do
			-- Phase 4
		end

	update_note (a_id: INTEGER_64; a_body: READABLE_STRING_GENERAL)
		do
			-- Phase 4
		end

	remove_note (a_id: INTEGER_64)
		do
			-- Phase 4
		end

	restore_note (a_id: INTEGER_64)
		do
			-- Phase 4
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
		do
			-- Phase 4
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
		do
			-- Phase 4
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
			-- Phase 4
		ensure
			non_negative: Result >= 0
		end

	total_note_versions: INTEGER
			-- Every version of every note, deleted ones included.
		do
			-- Phase 4
		ensure
			non_negative: Result >= 0
		end

	imported_count, new_notes_count, new_versions_count, unchanged_count, versions_rewritten: INTEGER
			-- Files the last import read; of those, the new notes, the new versions and
			-- the unchanged notes; and versions it overwrote (always 0).

	has_front_matter_keys (a_folder, a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Does the file `a_name' in `a_folder' carry `id' and `hub_id' front matter?
		do
			-- Phase 4
		end

	was_written_atomically (a_name: READABLE_STRING_GENERAL): BOOLEAN
			-- Was `a_name' written through a temporary file and an atomic move?
		do
			-- Phase 4
		end

	folder_exists (a_folder: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_folder' exist?
		do
			-- Phase 4: simple_file.
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
