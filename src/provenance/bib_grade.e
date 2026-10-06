note
	description: "Source grade P1 (primary) to P4 (weakest), required for timeline and private sources."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GRADE

inherit
	BIB_ENUMERATION

create
	make

feature {NONE} -- Initialization

	make (a_code: INTEGER)
			-- Create grade `a_code' (P1 = 1 .. P4 = 4).
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

feature -- Access

	label: STRING_32
			-- "P1" .. "P4".
		do
			Result := {STRING_32} "P" + code.out
		end

feature -- Status

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code' one of P1..P4?
		do
			Result := a_code >= P1 and a_code <= P4
		end

feature -- Constants

	P1: INTEGER = 1
	P2: INTEGER = 2
	P3: INTEGER = 3
	P4: INTEGER = 4

end
