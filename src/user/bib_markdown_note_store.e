note
	description: "[
		Notes as Markdown files in a user folder (Obsidian-compatible), indexed
		into user.db for search and backlinks (Q-11, RQ-06; AC-1a-42/43,
		conditional on the RQ-06 gate). Rules: reconcile at start and on window
		focus (mtime and SHA-256 scan), the file wins and the index is rebuilt
		from the files; a file changed outside the program since its last read
		is never overwritten (a conflict copy is written); a renamed or deleted
		file leaves no dangling index row; a second instance opens read-only
		(single-instance lock). Verse links are plain references found by
		BIB_REFERENCE_DETECTOR. Front matter, if any, is read with simple_yaml in
		Phase 4 (this store only).
		Fleet dependency LG-09: simple_hash takes 8-bit paths; note paths with
		characters outside Latin-1 need it fixed before the SHA-256 scan.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MARKDOWN_NOTE_STORE

inherit
	BIB_NOTE_STORE

create
	make

feature {NONE} -- Initialization

	make (a_folder: READABLE_STRING_GENERAL; a_index: BIB_USER_STORE; a_detector: BIB_REFERENCE_DETECTOR)
		require
			folder_chosen: not a_folder.is_empty
		do
			folder := a_folder.to_string_32
			index := a_index
			detector := a_detector
		ensure
			folder_set: folder.same_string_general (a_folder)
			no_lock_yet: not is_lock_holder
		end

feature -- Access

	folder: STRING_32
	index: BIB_USER_STORE
	detector: BIB_REFERENCE_DETECTOR

	conflict_copy_count: INTEGER
			-- Conflict copies written so far.

	dangling_index_rows: INTEGER
			-- Index rows whose file no longer exists.
		do
			-- Phase 4
		ensure
			non_negative: Result >= 0
		end

	file_hash (a_id: INTEGER_64): STRING_8
			-- SHA-256 of note `a_id''s file as last read.
		require
			stored: a_id > 0
		do
			check implemented_in_phase_4: False then end
		ensure
			sha256_hex: Result.count = 64
		end

	links_of (a_id: INTEGER_64): ARRAYED_LIST [BIB_REF_MATCH]
			-- Verse links in note `a_id' (plain references).
		require
			stored: a_id > 0
		do
			Result := detector.detected (current_body (a_id))
		end

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

	is_lock_holder: BOOLEAN
			-- Does this instance hold the folder's single-instance lock?

	is_writable: BOOLEAN
		do
			Result := is_lock_holder and index.is_open
		end

	is_deleted (a_id: INTEGER_64): BOOLEAN
		do
			-- Phase 4
		end

	file_changed_externally (a_id: INTEGER_64): BOOLEAN
			-- Has note `a_id''s file changed outside the program since its last read?
		require
			stored: a_id > 0
		do
			-- Phase 4: mtime and SHA-256 against the index row.
		end

feature -- Commands

	acquire_lock
			-- Take the single-instance lock if no other instance holds it.
		require
			not_held: not is_lock_holder
		do
			-- Phase 4
		ensure
			second_instance_read_only: not is_lock_holder implies not is_writable
		end

	reconcile
			-- Rescan the folder (start, window focus): the file wins; rebuild the index rows.
		do
			-- Phase 4
		ensure
			no_dangling_rows: last_error = Void implies dangling_index_rows = 0
			conflicts_unchanged: conflict_copy_count = old conflict_copy_count
		end

	add_note (a_note: BIB_NOTE)
		do
			-- Phase 4: write <folder>/<title>.md, then index it.
		end

	update_note (a_id: INTEGER_64; a_body: READABLE_STRING_GENERAL)
		do
			-- Phase 4
		ensure then
			never_overwrites_external_change: old file_changed_externally (a_id) implies
				(conflict_copy_count = old conflict_copy_count + 1 and file_hash (a_id).same_string (old file_hash (a_id)))
		end

	remove_note (a_id: INTEGER_64)
		do
			-- Phase 4: move to the store's trash folder (restorable).
		end

	restore_note (a_id: INTEGER_64)
		do
			-- Phase 4
		end

invariant
	folder_chosen: not folder.is_empty
	read_only_without_lock: not is_lock_holder implies not is_writable
	conflicts_non_negative: conflict_copy_count >= 0

end
