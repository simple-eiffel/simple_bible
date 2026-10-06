note
	description: "One canonical book: id (the vault's bible_books id, FR-105), code and English name."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_id: INTEGER; a_code: READABLE_STRING_GENERAL; a_name: READABLE_STRING_GENERAL; a_deuterocanonical: BOOLEAN)
			-- Create book `a_id'.
		require
			id_positive: a_id > 0
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
		do
			id := a_id
			code := a_code.to_string_32
			name := a_name.to_string_32
			is_deuterocanonical := a_deuterocanonical
		ensure
			id_set: id = a_id
			code_set: code.same_string_general (a_code)
			name_set: name.same_string_general (a_name)
			deutero_set: is_deuterocanonical = a_deuterocanonical
		end

feature -- Access

	id: INTEGER
			-- Canonical id, equal to the vault's `bible_books.id' (AC-1a-08).

	code: STRING_32
			-- Short code, e.g. "GEN".

	name: STRING_32
			-- English name.

feature -- Status

	is_deuterocanonical: BOOLEAN
			-- First-class wherever a shipped text contains it (RQ-10).

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same canonical book?
		do
			Result := id = other.id
		end

invariant
	id_positive: id > 0
	code_not_empty: not code.is_empty
	name_not_empty: not name.is_empty

end
