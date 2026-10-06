note
	description: "They Chose agreement class: MT against LXX, LXX against MT, both, neither, NO_DATA."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AGREEMENT_CLASS

inherit
	BIB_ENUMERATION

create
	make, make_no_data

feature {NONE} -- Initialization

	make (a_code: INTEGER)
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

	make_no_data
		do
			code := No_data
		ensure
			no_data: is_no_data
		end

feature -- Access

	label: STRING_32
		do
			inspect code
			when Agrees_with_mt then
				Result := {STRING_32} "agrees with the Hebrew against the Septuagint"
			when Agrees_with_lxx then
				Result := {STRING_32} "agrees with the Septuagint against the Hebrew"
			when Agrees_with_both then
				Result := {STRING_32} "agrees with both"
			when Agrees_with_neither then
				Result := {STRING_32} "agrees with neither"
			else
				Result := {STRING_32} "NO_DATA"
			end
		end

feature -- Status

	is_no_data: BOOLEAN
		do
			Result := code = No_data
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
		do
			Result := a_code >= Agrees_with_mt and a_code <= No_data
		end

feature -- Constants

	Agrees_with_mt: INTEGER = 1
	Agrees_with_lxx: INTEGER = 2
	Agrees_with_both: INTEGER = 3
	Agrees_with_neither: INTEGER = 4
	No_data: INTEGER = 5

end
