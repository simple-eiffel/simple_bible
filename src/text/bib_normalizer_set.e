note
	description: "The three normalizers, chosen by language; one instance shared by the build and the query path."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NORMALIZER_SET

create
	make

feature {NONE} -- Initialization

	make (a_unicode: BIB_UNICODE_SERVICE)
			-- Create the three normalizers over `a_unicode'.
		do
			create hebrew.make (a_unicode)
			create greek.make (a_unicode)
			create english.make (a_unicode)
		ensure
			shared_unicode: hebrew.unicode = a_unicode and greek.unicode = a_unicode and english.unicode = a_unicode
		end

feature -- Access

	hebrew: BIB_HEBREW_NORMALIZER
	greek: BIB_GREEK_NORMALIZER
	english: BIB_ENGLISH_NORMALIZER

	for_language (a_language: READABLE_STRING_8): BIB_NORMALIZER
			-- Normalizer for `a_language' ("hbo"/"arc" Hebrew script, "grc" Greek, others English).
		require
			language_not_empty: not a_language.is_empty
		do
			if a_language.same_string ("hbo") or a_language.same_string ("arc") then
				Result := hebrew
			elseif a_language.same_string ("grc") then
				Result := greek
			else
				Result := english
			end
		ensure
			hebrew_script: (a_language.same_string ("hbo") or a_language.same_string ("arc")) implies Result = hebrew
			greek_script: a_language.same_string ("grc") implies Result = greek
		end

end
