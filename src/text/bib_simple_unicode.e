note
	description: "[
		BIB_UNICODE_SERVICE over simple_encoding's SIMPLE_UNICODE (LG-01, landed
		2026-10-27): the Unicode 15.1.0 tables, NFD/NFC/NFKC, general category and
		simple case mapping.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SIMPLE_UNICODE

inherit
	BIB_UNICODE_SERVICE

create
	make

feature {NONE} -- Initialization

	make
			-- Create the adapter.
		do
			create unicode.make
		end

feature -- Normalization forms

	nfd (a_text: READABLE_STRING_32): STRING_32
		do
			Result := unicode.nfd (a_text)
		end

	nfc (a_text: READABLE_STRING_32): STRING_32
		do
			Result := unicode.nfc (a_text)
		end

	nfkc (a_text: READABLE_STRING_32): STRING_32
		do
			Result := unicode.nfkc (a_text)
		end

feature -- Character properties

	general_category (a_char: CHARACTER_32): STRING_8
		do
			Result := unicode.general_category (a_char)
		end

	is_combining_mark (a_char: CHARACTER_32): BOOLEAN
		do
			Result := unicode.is_combining_mark (a_char)
		end

	simple_lower (a_char: CHARACTER_32): CHARACTER_32
		do
			Result := unicode.simple_lower (a_char)
		end

	simple_upper (a_char: CHARACTER_32): CHARACTER_32
		do
			Result := unicode.simple_upper (a_char)
		end

feature {NONE} -- Implementation

	unicode: SIMPLE_UNICODE
			-- simple_encoding's Unicode service.

end
