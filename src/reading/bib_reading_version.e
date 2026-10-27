note
	description: "[
		One Bible version as the reading pane lists it (content.db `version_info`):
		its code, name, language, writing direction, numbering and caveat, with
		the source it came from. The spec's BIB_VERSION_INFO (with canon coverage
		and the versification hub) grows from this; the reading slice needs only
		these (fold 2026-10-26, Larry: "Reading slice now").
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_READING_VERSION

create
	make

feature {NONE} -- Initialization

	make (a_code: READABLE_STRING_8; a_name: READABLE_STRING_GENERAL; a_language, a_direction, a_versification: READABLE_STRING_8;
			a_caveat: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Version `a_code' called `a_name'; `a_direction' is "rtl" for right-to-left scripts.
		require
			code_not_empty: not a_code.is_empty
			name_not_empty: not a_name.is_empty
		do
			code := a_code.to_string_8
			name := a_name.to_string_32
			language := a_language.to_string_8
			is_right_to_left := a_direction.same_string ("rtl")
			versification := a_versification.to_string_8
			caveat := a_caveat.to_string_32
			provenance := a_provenance
		ensure
			code_set: code.same_string (a_code)
			name_set: name.same_string_general (a_name)
			direction_read: is_right_to_left = a_direction.same_string ("rtl")
			provenance_set: provenance = a_provenance
		end

feature -- Access

	code: STRING_8
			-- The version's code ("KJV", "WLC").

	name: STRING_32
			-- What a reader calls it.

	language: STRING_8
			-- Its language code ("eng", "hbo", "grc").

	is_right_to_left: BOOLEAN
			-- Is it written right to left (Hebrew, Aramaic, Syriac)?

	numbers_like_hebrew: BOOLEAN
			-- Does this version number verses as the Hebrew Bible does?
		do
			Result := versification.same_string ({BIB_NUMBERING}.Hebrew)
		end

	numbers_like_septuagint: BOOLEAN
			-- Does this version number verses as the Septuagint does?
		do
			Result := versification.same_string ({BIB_NUMBERING}.Septuagint)
		end

	numbers_like_vulgate: BOOLEAN
			-- Does this version number verses as the Vulgate does?
		do
			Result := versification.same_string ({BIB_NUMBERING}.Vulgate)
		end

	numbers_like_english: BOOLEAN
			-- Does this version number verses the English way (the KJV family)?
		do
			Result := versification.same_string ({BIB_NUMBERING}.English)
		end

	versification: STRING_8
			-- Its own numbering ("kjv", "hebrew", "lxx", "vulgate").

	caveat: STRING_32
			-- What a reader should know about this text; may be empty.

	provenance: BIB_PROVENANCE
			-- Where the text came from and under what licence.

invariant
	code_not_empty: not code.is_empty
	name_not_empty: not name.is_empty

end
