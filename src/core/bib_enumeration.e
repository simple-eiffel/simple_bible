note
	description: "A closed set of codes with labels. Two members are equal when their codes are."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_ENUMERATION

inherit
	ANY
		redefine
			is_equal
		end

feature -- Access

	code: INTEGER
			-- Member code.

	label: STRING_32
			-- Display label.
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Status

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code' a member of this set?
		deferred
		end

	is_valid: BOOLEAN
			-- Is `code' a member?
		do
			Result := is_valid_code (code)
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same member?
		do
			Result := code = other.code
		end

invariant
	valid: is_valid_code (code)

end
