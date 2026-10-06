note
	description: "A morphology code in its scheme (OSHB, MACULA, Robinson); expanded to English by BIB_MORPH_EXPANDER."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MORPH_CODE

inherit
	BIB_KEY

create
	make

feature {NONE} -- Initialization

	make (a_scheme: READABLE_STRING_8; a_code: READABLE_STRING_GENERAL)
			-- Create code `a_code' in `a_scheme'.
		require
			scheme_not_empty: not a_scheme.is_empty
			code_not_empty: not a_code.is_empty
		do
			scheme := a_scheme.to_string_8
			code := a_code.to_string_32
			text := scheme.to_string_32 + {STRING_32} ":" + code
		ensure
			scheme_set: scheme.same_string (a_scheme)
			code_set: code.same_string_general (a_code)
		end

feature -- Access

	scheme: STRING_8
	code: STRING_32

	kind_label: STRING_32
		do
			Result := {STRING_32} "morphology"
		end

invariant
	scheme_not_empty: not scheme.is_empty
	code_not_empty: not code.is_empty

end
