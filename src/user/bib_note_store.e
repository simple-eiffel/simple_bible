note
	description: "[
		Where notes live (03 A-021, Q-11): faces see only this seam. Notes are
		append-only with history, soft delete and restore (AC-1a-40). Both
		stores keep the same contracts (Liskov). A second instance is read-only.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_NOTE_STORE

feature -- Access

	last_error: detachable BIB_ERROR

	note_count (a_hub_id: INTEGER_64): INTEGER
			-- Live notes on `a_hub_id' (0 for topical).
		deferred
		ensure
			non_negative: Result >= 0
		end

	version_count (a_id: INTEGER_64): INTEGER
			-- Versions of note `a_id' written so far.
		deferred
		ensure
			non_negative: Result >= 0
		end

	version_body (a_id: INTEGER_64; a_version: INTEGER): STRING_32
		require
			in_range: a_version >= 1 and a_version <= version_count (a_id)
		deferred
		end

	current_body (a_id: INTEGER_64): STRING_32
		require
			stored: a_id > 0
		deferred
		end

	notes_for (a_hub_id: INTEGER_64): ARRAYED_LIST [BIB_NOTE]
			-- Live notes on `a_hub_id', whatever version they were made in.
		deferred
		ensure
			keyed: across Result as n all n.hub_id = a_hub_id and not n.is_deleted end
			counted: Result.count = note_count (a_hub_id)
		end

feature -- Status

	is_writable: BOOLEAN
			-- Is this instance allowed to write (single-instance lock held)?
		deferred
		end

	is_deleted (a_id: INTEGER_64): BOOLEAN
		deferred
		end

feature -- Commands

	add_note (a_note: BIB_NOTE)
		require
			writable: is_writable
			not_stored: a_note.id = 0
			keyed: a_note.hub_id > 0 or a_note.is_topical
		deferred
		ensure
			stored: last_error = Void implies a_note.id > 0
			count_grown: last_error = Void implies note_count (a_note.hub_id) = old note_count (a_note.hub_id) + 1
			first_version: last_error = Void implies version_count (a_note.id) = 1
		end

	update_note (a_id: INTEGER_64; a_body: READABLE_STRING_GENERAL)
		require
			writable: is_writable
			stored: a_id > 0
			not_deleted: not is_deleted (a_id)
		deferred
		ensure
			history_grown: last_error = Void implies version_count (a_id) = old version_count (a_id) + 1
			previous_kept: last_error = Void implies version_body (a_id, old version_count (a_id)).same_string (old current_body (a_id))
			body_set: last_error = Void implies current_body (a_id).same_string_general (a_body)
		end

	remove_note (a_id: INTEGER_64)
		require
			writable: is_writable
			stored: a_id > 0
		deferred
		ensure
			soft_deleted: last_error = Void implies is_deleted (a_id)
			recoverable: last_error = Void implies version_count (a_id) = old version_count (a_id)
		end

	restore_note (a_id: INTEGER_64)
		require
			writable: is_writable
			deleted: is_deleted (a_id)
		deferred
		ensure
			restored: last_error = Void implies not is_deleted (a_id)
			history_kept: version_count (a_id) = old version_count (a_id)
		end

end
