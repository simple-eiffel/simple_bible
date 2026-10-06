note
	description: "A user tag on a verse."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TAG_ASSIGNMENT

inherit
	BIB_USER_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_tag: READABLE_STRING_GENERAL)
		require
			hub_positive: a_hub_id > 0
			tag_given: not a_tag.is_empty
		do
			hub_id := a_hub_id
			tag := a_tag.to_string_32
		ensure
			keyed: hub_id = a_hub_id
		end

feature -- Access

	tag: STRING_32

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_tag
		end

invariant
	hub_positive: hub_id > 0
	tag_given: not tag.is_empty

end
