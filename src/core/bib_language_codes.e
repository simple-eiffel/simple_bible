note
	description: "[
		The Bible's language codes in one place (design scan 25): the originals,
		Hebrew "hbo", Aramaic "arc" and Greek "grc", and the English rendering
		"eng". Stateless; inherit it beside a class's real parent. The same test
		was written out by hand in the transliterator, the normalizer set, the
		version record and the concordance values before.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LANGUAGE_CODES

feature -- Status

	is_hebrew_script (a_language: READABLE_STRING_8): BOOLEAN
			-- Is `a_language' written in Hebrew script (Hebrew or Aramaic)?
		do
			Result := a_language.same_string ("hbo") or a_language.same_string ("arc")
		ensure
			greek_is_not: a_language.same_string ("grc") implies not Result
		end

	is_original (a_language: READABLE_STRING_8): BOOLEAN
			-- Is `a_language' an original-language code of the Bible (Hebrew, Aramaic or Greek)?
			-- English ("eng") is a rendering, not an original (Phase 2 review, ruling 1.2).
		do
			Result := is_hebrew_script (a_language) or a_language.same_string ("grc")
		ensure
			hebrew_script_is_original: is_hebrew_script (a_language) implies Result
			english_is_not: a_language.same_string ("eng") implies not Result
		end

	is_translit_complete (a_language: READABLE_STRING_8; a_surface, a_translit: READABLE_STRING_GENERAL): BOOLEAN
			-- Does a word in `a_language' written `a_surface' carry the transliteration every written
			-- original-language word needs (FR-155)? An empty surface and English need none (ruling 1.2).
			-- One home for the rule (design scan 28: it was written eight times).
		do
			Result := not (is_original (a_language) and not a_surface.is_empty) or else not a_translit.is_empty
		ensure
			english_always: not is_original (a_language) implies Result
			unwritten_always: a_surface.is_empty implies Result
		end

	is_concordance_language (a_language: READABLE_STRING_8): BOOLEAN
			-- Is `a_language' one the concordance holds (an original or English)?
		do
			Result := is_original (a_language) or a_language.same_string ("eng")
		ensure
			originals_held: is_original (a_language) implies Result
		end

end
