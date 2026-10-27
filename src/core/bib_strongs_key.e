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
	BIB_ROOT_KEY

create
	make_from_text

feature {NONE} -- Initialization

	make_from_text (a_text: READABLE_STRING_GENERAL)
			-- Parse `a_text' ("H1", "H0001", "G3056", "H6743a").
		require
			well_formed: is_strongs_text (a_text)
		do
			testament := a_text.item (1).to_character_8
			number := numeric_value_without_padding (a_text)
			sense_suffix := suffix_of (a_text)
			text := canonical_form (testament, number, sense_suffix).to_string_32
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
			-- The number must be positive: "G0" (two rows in conc.db) is not a key.
		local
			l_last_digit: INTEGER
		do
			if a_text.count >= 2 and then (a_text.item (1) = {CHARACTER_32} 'H' or a_text.item (1) = {CHARACTER_32} 'G') then
				l_last_digit := last_digit_index (a_text)
				Result := l_last_digit >= 2 and l_last_digit <= 6
					and then (l_last_digit = a_text.count or else (l_last_digit + 1 = a_text.count and is_ascii_lower (a_text.item (a_text.count))))
					and then digits_value (a_text, l_last_digit) > 0
			end
		end

	numeric_value_without_padding (a_text: READABLE_STRING_GENERAL): INTEGER
			-- Digits of `a_text' as a number (leading zeros ignored).
		require
			well_formed: is_strongs_text (a_text)
		do
			Result := digits_value (a_text, last_digit_index (a_text))
		ensure
			positive: Result > 0
		end

	suffix_of (a_text: READABLE_STRING_GENERAL): STRING_8
			-- Trailing sense letter of `a_text', or "".
		require
			well_formed: is_strongs_text (a_text)
		do
			create Result.make_empty
			if is_ascii_lower (a_text.item (a_text.count)) then
				Result.append_character (a_text.item (a_text.count).to_character_8)
			end
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

feature {NONE} -- Implementation

	last_digit_index (a_text: READABLE_STRING_GENERAL): INTEGER
			-- Index of the last digit of the run that starts at position 2 (1 when there is none).
		do
			from
				Result := 1
			until
				Result + 1 > a_text.count or else not is_ascii_digit (a_text.item (Result + 1))
			loop
				Result := Result + 1
			end
		end

	digits_value (a_text: READABLE_STRING_GENERAL; a_last: INTEGER): INTEGER
			-- The number written in positions 2 to `a_last' of `a_text'.
		require
			short_enough: a_last <= 6
		local
			i: INTEGER
		do
			from
				i := 2
			until
				i > a_last
			loop
				Result := Result * 10 + (a_text.item (i).natural_32_code - 48).to_integer_32
				i := i + 1
			end
		end

	is_ascii_digit (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' one of 0 to 9?
		do
			Result := a_char.natural_32_code >= 48 and a_char.natural_32_code <= 57
		end

	is_ascii_lower (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' one of a to z?
		do
			Result := a_char.natural_32_code >= 97 and a_char.natural_32_code <= 122
		end

invariant
	testament_known: testament = 'H' or testament = 'G'
	number_positive: number > 0

end
