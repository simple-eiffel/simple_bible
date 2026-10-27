note
	description: "[
		Search-form normalization shared by the build and the query path (D-009):
		the same class builds the normalized columns and normalizes the user's
		query, so a copied phrase always finds its verse (AC-1a-20, AC-1a-21).
		Display text never comes from it. Idempotent; leaves no combining mark;
		folds quote, dash and no-break-space variants (A-024).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_NORMALIZER

feature {NONE} -- Initialization

	make (a_unicode: BIB_UNICODE_SERVICE)
			-- Create a normalizer over `a_unicode' (LG-01).
		do
			unicode := a_unicode
		ensure
			unicode_set: unicode = a_unicode
		end

feature -- Access

	unicode: BIB_UNICODE_SERVICE
			-- Unicode services (LG-01).

	language: STRING_8
			-- Language code this normalizer serves ("hbo", "grc", "eng").
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Normalization

	normalized (a_text: READABLE_STRING_GENERAL): STRING_32
			-- Search form of `a_text'.
		deferred
		ensure
			idempotent: normalized (Result).same_string (Result)
			no_combining_marks: not has_combining_mark (Result)
			not_longer: Result.count <= a_text.count
			empty_preserved: a_text.is_empty implies Result.is_empty
			punctuation_folded: not has_punctuation_or_quote_variant (Result)
		end

feature -- Status

	has_combining_mark (a_text: READABLE_STRING_32): BOOLEAN
			-- Does `a_text' contain a nonspacing, spacing or enclosing mark (Mn/Mc/Me)?
		do
			Result := unicode.has_combining_mark (a_text)
		end

	has_punctuation_or_quote_variant (a_text: READABLE_STRING_32): BOOLEAN
			-- Does `a_text' contain a curly quote, a typographic dash or a no-break space?
		do
			Result := across a_text as c some is_variant_character (c) end
		end

	is_dropped (a_char: CHARACTER_32): BOOLEAN
			-- Does the search form drop `a_char' (a mark, Mn/Mc/Me, or a format character, Cf)?
		local
			l_category: STRING_8
		do
			l_category := unicode.general_category (a_char)
			Result := l_category [1] = 'M' or l_category.same_string ("Cf")
		end

	is_variant_character (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' one of the folded variants (U+00A0, U+2010-U+2015, U+2018-U+201F)?
		local
			n: NATURAL_32
		do
			n := a_char.natural_32_code
			Result := n = 0xA0 or (n >= 0x2010 and n <= 0x2015) or (n >= 0x2018 and n <= 0x201F)
		end

feature {NONE} -- Implementation

	folded (a_text: READABLE_STRING_GENERAL): STRING_32
			-- The fold every language shares (2026-10-27, LG-01 landed): NFD, marks and format
			-- characters dropped, variants folded (no-break space to space, dashes to '-', quotes
			-- to ' and "), simple lowercase. Recomposed when decomposition left it longer (Hangul).
		local
			l_code: NATURAL_32
		do
			create Result.make (a_text.count)
			across unicode.nfd (a_text.to_string_32) as ic loop
				if not is_dropped (ic) then
					l_code := ic.natural_32_code
					if l_code = 0xA0 then
						Result.append_character (' ')
					elseif l_code >= 0x2010 and l_code <= 0x2015 then
						Result.append_character ('-')
					elseif l_code >= 0x2018 and l_code <= 0x201B then
						Result.append_character ('%'')
					elseif l_code >= 0x201C and l_code <= 0x201F then
						Result.append_character ('"')
					else
						Result.append_character (unicode.simple_lower (ic))
					end
				end
			end
			if Result.count > a_text.count then
				Result := unicode.nfc (Result)
			end
		ensure
			no_combining_marks: not has_combining_mark (Result)
			punctuation_folded: not has_punctuation_or_quote_variant (Result)
		end

end
