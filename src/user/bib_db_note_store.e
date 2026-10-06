note
	description: "Notes in user.db (the fallback store if the RQ-06 gate is not met)."
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
		ensure
			store_set: store = a_store
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

end
