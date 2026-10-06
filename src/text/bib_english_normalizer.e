note
	description: "English (and Latin) search form: lowercased, punctuation variants folded; stemming is separate."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ENGLISH_NORMALIZER

inherit
	BIB_NORMALIZER

create
	make

feature -- Access

	language: STRING_8
		do
			Result := "eng"
		end

feature -- Normalization

	normalized (a_text: READABLE_STRING_GENERAL): STRING_32
			-- Lowercase search form.
		do
			check implemented_in_phase_4: False then end
		ensure then
			lowercase: across Result as c all unicode.simple_lower (c) = c end
		end

end
