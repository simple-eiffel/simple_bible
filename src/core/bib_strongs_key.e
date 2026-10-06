note
	description: "[
		A Strong's number with an optional sense suffix (A-024, AC-1a-22):
		"H1", "H0001" and "H00001" are one key (padding-insensitive); split
		senses such as "H6743a" stay distinct.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_STRONGS_KEY

inherit
	BIB_KEY

create
	make_from_text

feature {NONE} -- Initialization

	make_from_text (a_text: READABLE_STRING_GENERAL)
			-- Parse `a_text' ("H1", "H0001", "G3056", "H6743a").
		require
			well_formed: is_strongs_text (a_text)
		do
			check implemented_in_phase_4: False then end
		ensure
			padding_insensitive: number = numeric_value_without_padding (a_text)
			sense_kept: sense_suffix.same_string (suffix_of (a_text))
			canonical_text: text.same_string_general (canonical_form (testament, number, sense_suffix))
		end

feature -- Access

	testament: CHARACTER_8
			-- 'H' (Hebrew/Aramaic) or 'G' (Greek).

	number: INTEGER
			-- Number without padding.

	sense_suffix: STRING_8
			-- "" or a sense letter ("a" in H6743a).

	kind_label: STRING_32
		do
			Result := {STRING_32} "strongs"
		end

feature -- Status

	is_strongs_text (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_text' an H or G prefix, 1 to 5 digits (zero padding allowed), and an optional lowercase letter?
		do
			-- Phase 4
		end

	numeric_value_without_padding (a_text: READABLE_STRING_GENERAL): INTEGER
			-- Digits of `a_text' as a number (leading zeros ignored).
		require
			well_formed: is_strongs_text (a_text)
		do
			-- Phase 4
		ensure
			positive: Result > 0
		end

	suffix_of (a_text: READABLE_STRING_GENERAL): STRING_8
			-- Trailing sense letter of `a_text', or "".
		require
			well_formed: is_strongs_text (a_text)
		do
			check implemented_in_phase_4: False then end
		ensure
			short: Result.count <= 1
		end

	canonical_form (a_testament: CHARACTER_8; a_number: INTEGER; a_suffix: READABLE_STRING_8): STRING_8
			-- Unpadded canonical text, e.g. "H6743a".
		do
			create Result.make (8)
			Result.append_character (a_testament)
			Result.append (a_number.out)
			Result.append (a_suffix)
		end

invariant
	testament_known: testament = 'H' or testament = 'G'
	number_positive: number > 0

end
