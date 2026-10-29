note
	description: "[
		What a word is made of (design scan 63): a letter or digit in any script,
		Hebrew points and Greek letters included, never a space, punctuation, the
		Hebrew maqaf or sof pasuq, or general punctuation (U+2000-U+206F). The
		window's word selection and Ask's checks read words by this one rule (two
		copies had drifted: Ask's knew only ASCII letters and digits). Two matchers
		keep rules of their own on purpose: BIB_FRAMEWORK_NAMES (a mark (TM) after
		a name must not count as a letter) and BIB_REFERENCE_LINKER's
		`is_name_character' (a period belongs inside "Gen.").
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_CHARACTERS

feature -- Queries

	is_word_character (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' part of a word?
		do
			Result := a_char.is_alpha_numeric
				or else (a_char.natural_32_code > 127 and then not a_char.is_space
					and then a_char.natural_32_code /= 0x05BE and then a_char.natural_32_code /= 0x05C3
					and then not (a_char.natural_32_code >= 0x2000 and a_char.natural_32_code <= 0x206F))
		end

	has_whole_word (a_text, a_word: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_word' (one word or several) in `a_text' as whole words, in any case?
		local
			l_text, l_word: STRING_32
			i: INTEGER
		do
			l_text := a_text.to_string_32.as_lower
			l_word := a_word.to_string_32.as_lower
			if not l_word.is_empty then
				from i := l_text.substring_index (l_word, 1) until i = 0 or Result loop
					if (i = 1 or else not is_word_character (l_text [i - 1]))
						and then (i + l_word.count > l_text.count or else not is_word_character (l_text [i + l_word.count]))
					then
						Result := True
					else
						i := l_text.substring_index (l_word, i + 1)
					end
				end
			end
		ensure
			empty_never: a_word.is_empty implies not Result
		end

end
