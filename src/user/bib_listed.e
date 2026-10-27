note
	description: "[
		A row of the reader's own that a list shows and Remove takes away softly:
		an id, and the verse it rests on (0 for none). User items, prayers and
		memory cards all are one (design scan 54), so BIB_ITEM_LIST_PANEL serves
		every such list.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_LISTED

feature -- Access

	id: INTEGER_64
			-- 0 until stored.
		deferred
		end

	hub_id: INTEGER_64
			-- The verse it rests on; 0 for none.
		deferred
		end

end
