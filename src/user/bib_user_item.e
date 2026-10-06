note
	description: "[
		Base of the reader's own records, keyed to the canonical hub id only (no
		version field exists), so a highlight made on John 3:16 in the BSB shows
		on John 3:16 in every version (AC-1a-39). Ids and dates are assigned by
		the store; deletes are soft (AC-1a-40).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_USER_ITEM

feature -- Access

	id: INTEGER_64
			-- 0 until stored.

	hub_id: INTEGER_64
			-- Canonical verse (0 for a topical note).

	created_at: detachable SIMPLE_DATE_TIME
	changed_at: detachable SIMPLE_DATE_TIME

	kind: INTEGER
			-- {BIB_USER_STORE}.Kind_* code.
		deferred
		end

feature -- Status

	is_stored: BOOLEAN
		do
			Result := id > 0
		end

	is_deleted: BOOLEAN
			-- Soft-deleted (restorable)?

feature {BIB_USER_STORE, BIB_NOTE_STORE} -- Store bookkeeping

	mark_stored (a_id: INTEGER_64; a_at: SIMPLE_DATE_TIME)
		require
			not_stored: not is_stored
			id_positive: a_id > 0
		do
			id := a_id
			created_at := a_at
			changed_at := a_at
		ensure
			stored: id = a_id and created_at = a_at
			hub_unchanged: hub_id = old hub_id
		end

	mark_deleted (a_at: SIMPLE_DATE_TIME)
		require
			stored: is_stored
		do
			is_deleted := True
			changed_at := a_at
		ensure
			deleted: is_deleted
			id_unchanged: id = old id
		end

	mark_restored (a_at: SIMPLE_DATE_TIME)
		require
			deleted: is_deleted
		do
			is_deleted := False
			changed_at := a_at
		ensure
			restored: not is_deleted
			id_unchanged: id = old id
		end

invariant
	id_non_negative: id >= 0
	hub_non_negative: hub_id >= 0
	stored_is_dated: is_stored implies created_at /= Void
	only_stored_deleted: is_deleted implies is_stored

end
