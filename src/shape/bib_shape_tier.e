note
	description: "Shape tiers: T1 (surface), T2 (tag-level), T3 (judgment: frames a question, never scores one)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_TIER

inherit
	BIB_ENUMERATION

create
	make

feature {NONE} -- Initialization

	make (a_code: INTEGER)
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

feature -- Access

	label: STRING_32
		do
			Result := {STRING_32} "T" + code.out
		end

feature -- Status

	is_judgment: BOOLEAN
			-- Is this T3?
		do
			Result := code = T3
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
		do
			Result := a_code >= T1 and a_code <= T3
		end

feature -- Constants

	T1: INTEGER = 1
	T2: INTEGER = 2
	T3: INTEGER = 3

end
