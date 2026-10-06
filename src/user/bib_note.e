note
	description: "A note on a verse (by hub id) or a topical note; its history lives in the note store (append-only)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NOTE

inherit
	BIB_USER_ITEM

create
	make, make_topical

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_title, a_body: READABLE_STRING_GENERAL)
			-- A note on verse `a_hub_id'.
		require
			hub_positive: a_hub_id > 0
		do
			hub_id := a_hub_id
			title := a_title.to_string_32
			body := a_body.to_string_32
		ensure
			keyed: hub_id = a_hub_id and not is_topical
			unstored: id = 0
		end

	make_topical (a_title, a_body: READABLE_STRING_GENERAL)
			-- A note on a topic rather than a verse.
		require
			title_not_empty: not a_title.is_empty
		do
			title := a_title.to_string_32
			body := a_body.to_string_32
		ensure
			topical: is_topical
			unstored: id = 0
		end

feature -- Access

	title: STRING_32
	body: STRING_32

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_note
		end

feature -- Status

	is_topical: BOOLEAN
		do
			Result := hub_id = 0
		end

invariant
	topical_has_title: is_topical implies not title.is_empty

end
