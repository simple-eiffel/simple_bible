note
	description: "Hebrew search form: consonants only, final forms folded, points and accents removed."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_HEBREW_NORMALIZER

inherit
	BIB_NORMALIZER

create
	make

feature -- Access

	language: STRING_8
		do
			Result := "hbo"
		end

feature -- Normalization

	normalized (a_text: READABLE_STRING_GENERAL): STRING_32
			-- Consonantal search form.
		do
			check implemented_in_phase_4: False then end
		ensure then
			consonants_only: across Result as c all is_hebrew_base_letter (c) or not is_hebrew_letter (c) end
			finals_folded: not across Result as c some is_final_form (c) end
		end

feature -- Status

	is_hebrew_letter (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' a Hebrew letter (U+05D0..U+05EA)?
		do
			Result := a_char.natural_32_code >= 0x05D0 and a_char.natural_32_code <= 0x05EA
		end

	is_final_form (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' a final letter form (kaf, mem, nun, pe, tsadi)?
		local
			n: NATURAL_32
		do
			n := a_char.natural_32_code
			Result := n = 0x05DA or n = 0x05DD or n = 0x05DF or n = 0x05E3 or n = 0x05E5
		end

	is_hebrew_base_letter (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' a Hebrew letter in its non-final form?
		do
			Result := is_hebrew_letter (a_char) and not is_final_form (a_char)
		end

end
