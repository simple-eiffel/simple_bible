note
	description: "The three normalizers, chosen by language; one instance shared by the build and the query path."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NORMALIZER_SET

inherit
	BIB_LANGUAGE_CODES
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (a_unicode: BIB_UNICODE_SERVICE)
			-- Create the three normalizers over `a_unicode'.
		do
			unicode := a_unicode
			create hebrew.make (a_unicode)
			create greek.make (a_unicode)
			create english.make (a_unicode)
		ensure
			shared_unicode: hebrew.unicode = a_unicode and greek.unicode = a_unicode and english.unicode = a_unicode
			unicode_set: unicode = a_unicode
		end

feature -- Access

	unicode: BIB_UNICODE_SERVICE
			-- The Unicode service every normalizer shares.

	pack_token_form (a_word: READABLE_STRING_GENERAL): STRING_32
			-- `a_word' as the concordance pack's `token.search' holds it: the one fold (marks and
			-- format characters dropped, lowercase), Greek final sigma as sigma, every character that
			-- is not a letter or a digit dropped. Hebrew final letters are KEPT: the pack keeps them
			-- (41,291 tokens end in final mem, checked 2026-10-27), where the search index folds them.
			-- Design scan 47: a second, hand-made Greek table did this before and dropped letters.
		do
			create Result.make (a_word.count)
			across greek.folded (a_word) as ic loop
				if ic.natural_32_code = 0x03C2 then
					Result.append_character ((0x03C3).to_character_32)
				elseif unicode.is_letter_or_digit (ic) then
					Result.append_character (ic)
				end
			end
		ensure
			no_longer: Result.count <= a_word.count
			searchable_only: across Result as ic all unicode.is_letter_or_digit (ic) end
		end

	hebrew: BIB_HEBREW_NORMALIZER
	greek: BIB_GREEK_NORMALIZER
	english: BIB_ENGLISH_NORMALIZER

	for_language (a_language: READABLE_STRING_8): BIB_NORMALIZER
			-- Normalizer for `a_language' ("hbo"/"arc" Hebrew script, "grc" Greek, others English).
		require
			language_not_empty: not a_language.is_empty
		do
			if is_hebrew_script (a_language) then
				Result := hebrew
			elseif a_language.same_string ("grc") then
				Result := greek
			else
				Result := english
			end
		ensure
			hebrew_script: is_hebrew_script (a_language) implies Result = hebrew
			greek_script: a_language.same_string ("grc") implies Result = greek
		end

end
