note
	description: "Swete repair state of a verse (A-001): as-imported OCR, repaired, collated; not applicable elsewhere."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REPAIR_STATE

inherit
	BIB_ENUMERATION

create
	make, make_not_applicable

feature {NONE} -- Initialization

	make (a_code: INTEGER)
		require
			valid: is_valid_code (a_code)
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

	make_not_applicable
		do
			code := Not_applicable
		ensure
			not_applicable: is_not_applicable
		end

feature -- Access

	label: STRING_32
		do
			inspect code
			when As_imported_ocr then
				Result := {STRING_32} "as imported (OCR)"
			when Repaired then
				Result := {STRING_32} "repaired"
			when Collated then
				Result := {STRING_32} "collated"
			else
				Result := {STRING_32} "not applicable"
			end
		end

feature -- Status

	is_not_applicable: BOOLEAN
		do
			Result := code = Not_applicable
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
		do
			Result := a_code >= Not_applicable and a_code <= Collated
		end

feature -- Constants

	Not_applicable: INTEGER = 1
	As_imported_ocr: INTEGER = 2
	Repaired: INTEGER = 3
	Collated: INTEGER = 4

end
