note
	description: "[
		Greek search form: NFD, marks removed, lowercased, final sigma folded.
		Depends on LG-01 (NFD and general category in simple_encoding).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GREEK_NORMALIZER

inherit
	BIB_NORMALIZER

create
	make

feature -- Access

	language: STRING_8
		do
			Result := "grc"
		end

feature -- Normalization

	normalized (a_text: READABLE_STRING_GENERAL): STRING_32
			-- Accentless lowercase search form.
		local
			i: INTEGER
		do
			Result := folded (a_text)
			from i := 1 until i > Result.count loop
				if Result.code (i) = 0x03C2 then
					Result [i] := (0x03C3).to_character_32
				end
				i := i + 1
			end
		ensure then
			lowercase: across Result as c all unicode.simple_lower (c) = c end
			final_sigma_folded: not across Result as c some c.natural_32_code = 0x03C2 end
		end

end
