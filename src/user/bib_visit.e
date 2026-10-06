note
	description: "One history entry (Back/Forward), keyed to the hub id."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VISIT

inherit
	BIB_USER_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_context: READABLE_STRING_GENERAL)
			-- Visit of `a_hub_id' from `a_context' (panel or command).
		require
			hub_positive: a_hub_id > 0
		do
			hub_id := a_hub_id
			context := a_context.to_string_32
		ensure
			keyed: hub_id = a_hub_id
		end

feature -- Access

	context: STRING_32

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_visit
		end

invariant
	hub_positive: hub_id > 0

end
