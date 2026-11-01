note
	description: "[
		A folder of favorites (research/24 stage C, 2026-11-01), the reader's own
		categories on a notes app's model: folders in folders from a root. A
		removed folder hides everything inside it; restoring it brings it all
		back (deletes are soft, AC-1a-40).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FAVORITE_FOLDER

inherit
	BIB_USER_ITEM

create
	make

feature {NONE} -- Initialization

	make (a_parent_id: INTEGER_64; a_name: READABLE_STRING_GENERAL)
			-- A folder named `a_name' in folder `a_parent_id' (0: the root).
		require
			parent_non_negative: a_parent_id >= 0
			named: not a_name.is_empty
		do
			parent_id := a_parent_id
			name := a_name.to_string_32
		ensure
			placed: parent_id = a_parent_id
		end

feature -- Access

	parent_id: INTEGER_64
			-- The folder it is in (0: the root).

	name: STRING_32

	kind: INTEGER
		do
			Result := {BIB_USER_STORE}.Kind_favorite_folder
		end

feature {BIB_USER_STORE} -- Store bookkeeping

	set_parent (a_parent_id: INTEGER_64)
		require
			non_negative: a_parent_id >= 0
		do
			parent_id := a_parent_id
		ensure
			set: parent_id = a_parent_id
		end

	set_name (a_name: READABLE_STRING_GENERAL)
		require
			named: not a_name.is_empty
		do
			name := a_name.to_string_32
		end

invariant
	parent_non_negative: parent_id >= 0
	named: not name.is_empty
	no_verse: hub_id = 0

end
