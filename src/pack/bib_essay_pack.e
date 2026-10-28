note
	description: "[
		An essays pack, read (BIB_ESSAY_SCHEMA, 2026-10-28): the books pack's reader
		over a pack whose books are essay series and whose chapters are essays, its
		links "essay:<series>/<essay>#<block>".
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ESSAY_PACK

inherit
	BIB_BOOK_PACK
		redefine
			schema
		end

create
	make

feature -- Kind

	schema: BIB_TEXT_PACK_SCHEMA
			-- The essays'.
		do
			create {BIB_ESSAY_SCHEMA} Result
		end

end
