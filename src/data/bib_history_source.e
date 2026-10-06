note
	description: "[
		history.db (v2): the world-timeline database, read-only, `v_shippable'
		export only. Deferred-only in Release 1a: there is no effective
		descendant, and SIMPLE_BIBLE.has_history is always False (RQ-07).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_HISTORY_SOURCE

inherit
	BIB_DATA_SOURCE

feature -- Access

	alias_name: STRING_8
		do
			Result := "history"
		end

feature -- Status

	is_shippable_view_only: BOOLEAN
			-- Does this source read only `v_shippable' (11 section 6)?
		deferred
		ensure
			always: Result
		end

end
