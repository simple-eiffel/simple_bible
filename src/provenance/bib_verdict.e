note
	description: "[
		FITS, PARTIAL, FAILS, NO_DATA. NO_DATA means the tagging is silent; it
		is not evidence of absence and never collapses into FAILS (DR-005).
		Reporting order is always FITS, PARTIAL, FAILS, NO_DATA.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERDICT

inherit
	BIB_ENUMERATION

create
	make, make_fits, make_partial, make_fails, make_no_data

feature {NONE} -- Initialization

	make (a_code: INTEGER)
			-- Create verdict `a_code'.
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

	make_fits
		do
			code := Fits
		ensure
			fits: is_fits
		end

	make_partial
		do
			code := Partial
		ensure
			partial: is_partial
		end

	make_fails
		do
			code := Fails
		ensure
			fails: is_fails
		end

	make_no_data
		do
			code := No_data
		ensure
			no_data: is_no_data
		end

feature -- Access

	label: STRING_32
			-- "FITS", "PARTIAL", "FAILS" or "NO_DATA".
		do
			inspect code
			when Fits then
				Result := {STRING_32} "FITS"
			when Partial then
				Result := {STRING_32} "PARTIAL"
			when Fails then
				Result := {STRING_32} "FAILS"
			else
				Result := {STRING_32} "NO_DATA"
			end
		end

feature -- Status

	is_fits: BOOLEAN
		do
			Result := code = Fits
		end

	is_partial: BOOLEAN
		do
			Result := code = Partial
		end

	is_fails: BOOLEAN
		do
			Result := code = Fails
		end

	is_no_data: BOOLEAN
		do
			Result := code = No_data
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
			-- Is `a_code' one of the four verdicts?
		do
			Result := a_code >= Fits and a_code <= No_data
		end

feature -- Constants

	Fits: INTEGER = 1
	Partial: INTEGER = 2
	Fails: INTEGER = 3
	No_data: INTEGER = 4

end
