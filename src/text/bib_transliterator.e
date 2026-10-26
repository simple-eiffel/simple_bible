note
	description: "Transliteration and pronunciation (stress in capitals) for Hebrew and Greek (harvest C-01)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TRANSLITERATOR

inherit
	BIB_LANGUAGE_CODES
		export
			{NONE} all
		end

feature -- Conversion

	transliteration (a_text: READABLE_STRING_32; a_language: READABLE_STRING_8): STRING_32
			-- Academic transliteration of `a_text'.
		require
			language_known: is_supported_language (a_language)
		do
			check implemented_in_phase_4: False then end
		ensure
			empty_preserved: a_text.is_empty implies Result.is_empty
			not_empty_for_text: not a_text.is_empty implies not Result.is_empty
		end

	pronunciation (a_text: READABLE_STRING_32; a_language: READABLE_STRING_8): STRING_32
			-- Plain pronunciation with the stressed syllable in capitals.
		require
			language_known: is_supported_language (a_language)
		do
			check implemented_in_phase_4: False then end
		ensure
			empty_preserved: a_text.is_empty implies Result.is_empty
			not_empty_for_text: not a_text.is_empty implies not Result.is_empty
		end

feature -- Status

	is_supported_language (a_language: READABLE_STRING_8): BOOLEAN
			-- Can `a_language' be transliterated (the originals: Hebrew, Aramaic, Greek)?
		do
			Result := is_original (a_language)
		ensure
			originals_only: Result = is_original (a_language)
		end

end
