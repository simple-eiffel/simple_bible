note
	description: "[
		Unicode services the normalizers need: normalization forms, general
		category and simple case mapping.

		FLEET DEPENDENCY LG-01 (widened, RQ-04): simple_encoding has codecs and
		simplified character properties but no NFD/NFC/NFKD/NFKC, no general
		category (Mn, Mc, Me) and no Python-parity simple case mapping. This
		deferred class is the seam: the normalizers are written against it, and
		the effective class (an adapter over simple_encoding) arrives when LG-01
		lands. No workaround lives in simple_bible (C-013).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_UNICODE_SERVICE

feature -- Normalization forms

	nfd (a_text: READABLE_STRING_32): STRING_32
			-- Canonical decomposition.
		deferred
		ensure
			idempotent: nfd (Result).same_string (Result)
		end

	nfc (a_text: READABLE_STRING_32): STRING_32
			-- Canonical composition.
		deferred
		ensure
			idempotent: nfc (Result).same_string (Result)
			through_nfd: Result.same_string (nfc (nfd (a_text)))
		end

	nfkc (a_text: READABLE_STRING_32): STRING_32
			-- Compatibility composition (bge-m3 tokenizer parity, LG-05).
		deferred
		ensure
			idempotent: nfkc (Result).same_string (Result)
		end

feature -- Character properties

	general_category (a_char: CHARACTER_32): STRING_8
			-- Two-letter UCD general category, e.g. "Lu", "Mn".
		deferred
		ensure
			two_letters: Result.count = 2
		end

	is_combining_mark (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' in category Mn, Mc or Me?
		deferred
		ensure
			definition: Result = (general_category (a_char) [1] = 'M')
		end

	simple_lower (a_char: CHARACTER_32): CHARACTER_32
			-- Single-code-point lowercase (Python parity).
		deferred
		end

	simple_upper (a_char: CHARACTER_32): CHARACTER_32
			-- Single-code-point uppercase (Python parity; rix.db walk order, R2).
		deferred
		end

feature -- Text queries

	has_combining_mark (a_text: READABLE_STRING_32): BOOLEAN
			-- Does `a_text' contain a combining mark?
		do
			Result := across a_text as c some is_combining_mark (c) end
		end

end
