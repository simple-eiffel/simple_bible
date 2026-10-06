note
	description: "A highlight on a verse, recorded by its reason (not a color; the theme chooses the color)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_HIGHLIGHT

inherit
	BIB_USER_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_reason: READABLE_STRING_GENERAL)
		require
			hub_positive: a_hub_id > 0
			reason_given: not a_reason.is_empty
		do
			hub_id := a_hub_id
			reason := a_reason.to_string_32
		ensure
			keyed: hub_id = a_hub_id
		end

feature -- Access

	reason: STRING_32

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_highlight
		end

invariant
	hub_positive: hub_id > 0
	reason_given: not reason.is_empty

end
