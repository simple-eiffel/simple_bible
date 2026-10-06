note
	description: "Author-document status (D-019, Q-09): framework, verdict, draft, unmarked, withdrawn, ungated. Travels with every document."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_DOC_STATUS

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
			inspect code
			when Framework then
				Result := {STRING_32} "framework"
			when Verdict then
				Result := {STRING_32} "verdict"
			when Draft then
				Result := {STRING_32} "draft"
			when Unmarked then
				Result := {STRING_32} "unmarked"
			when Withdrawn then
				Result := {STRING_32} "withdrawn"
			else
				Result := {STRING_32} "ungated"
			end
		end

feature -- Status

	is_withdrawn: BOOLEAN
		do
			Result := code = Withdrawn
		end

	is_ungated: BOOLEAN
		do
			Result := code = Ungated
		end

	is_draft: BOOLEAN
		do
			Result := code = Draft
		end

	needs_banner: BOOLEAN
			-- Must the document show a banner (withdrawn, ungated, draft)?
		do
			Result := is_withdrawn or is_ungated or is_draft
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
		do
			Result := a_code >= Framework and a_code <= Ungated
		end

feature -- Constants

	Framework: INTEGER = 1
	Verdict: INTEGER = 2
	Draft: INTEGER = 3
	Unmarked: INTEGER = 4
	Withdrawn: INTEGER = 5
	Ungated: INTEGER = 6

end
