note
	description: "[
		Derived Hebrew forms for learners (FR-113): full pointing, vowels only
		(cantillation removed) or consonants only. The stored text never changes.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_POINTING_REDUCER

feature -- Reduction

	reduced (a_text: READABLE_STRING_32; a_level: INTEGER): STRING_32
			-- `a_text' at pointing level `a_level'.
		require
			level_valid: is_valid_level (a_level)
		do
			check implemented_in_phase_4: False then end
		ensure
			full_is_identity: a_level = Level_full implies Result.same_string (a_text)
			not_longer: Result.count <= a_text.count
			no_cantillation: a_level /= Level_full implies not across Result as c some is_cantillation (c) end
			no_vowels: a_level = Level_consonants implies not across Result as c some is_vowel_point (c) end
		end

feature -- Status

	is_valid_level (a_level: INTEGER): BOOLEAN
		do
			Result := a_level >= Level_full and a_level <= Level_consonants
		end

	is_cantillation (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' a Hebrew accent (U+0591..U+05AF)?
		do
			Result := a_char.natural_32_code >= 0x0591 and a_char.natural_32_code <= 0x05AF
		end

	is_vowel_point (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' a Hebrew point (U+05B0..U+05BD, U+05BF, U+05C1, U+05C2, U+05C4, U+05C5, U+05C7)?
		local
			n: NATURAL_32
		do
			n := a_char.natural_32_code
			Result := (n >= 0x05B0 and n <= 0x05BD) or n = 0x05BF or n = 0x05C1 or n = 0x05C2
				or n = 0x05C4 or n = 0x05C5 or n = 0x05C7
		end

feature -- Constants

	Level_full: INTEGER = 1
	Level_vowels: INTEGER = 2
	Level_consonants: INTEGER = 3

end
