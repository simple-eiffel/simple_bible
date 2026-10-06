note
	description: "A bookmark on a verse."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOKMARK

inherit
	BIB_USER_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_label: READABLE_STRING_GENERAL)
		require
			hub_positive: a_hub_id > 0
		do
			hub_id := a_hub_id
			label := a_label.to_string_32
		ensure
			keyed: hub_id = a_hub_id
		end

feature -- Access

	label: STRING_32

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_bookmark
		end

invariant
	hub_positive: hub_id > 0

end
