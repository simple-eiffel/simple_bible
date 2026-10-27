note
	description: "A morphology code in its scheme (OSHB, MACULA, Robinson); expanded to English by BIB_MORPH_EXPANDER."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MORPH_CODE

inherit
	BIB_KEY

create
	make

feature {NONE} -- Initialization

	make (a_scheme: READABLE_STRING_8; a_code: READABLE_STRING_GENERAL)
			-- Create code `a_code' in `a_scheme'.
		require
			scheme_not_empty: not a_scheme.is_empty
			code_not_empty: not a_code.is_empty
			code_text: is_code_text (a_code)
		do
			scheme := a_scheme.to_string_8
			code := a_code.to_string_32
			text := scheme.to_string_32 + {STRING_32} ":" + code
		ensure
			scheme_set: scheme.same_string (a_scheme)
			code_set: code.same_string_general (a_code)
		end

feature -- Access

	scheme: STRING_8
	code: STRING_32

	kind_label: STRING_32
		do
			Result := {STRING_32} "morphology"
		end

	is_prefix: BOOLEAN
			-- Does `code' end in *, matching every code it begins?
		do
			Result := code [code.count] = '*'
		end

feature -- Schemes (B05)

	Every_scheme: STRING_8 = "every"
			-- A code searched in every corpus (design scan 49: a scheme guessed from letter case read
			-- morph:V* as Hebrew). Safe because no Greek New Testament code (Robinson: N-NSF, V-AAI-3S,
			-- CONJ) equals a Hebrew Bible code (OSHB: Ncfsa, Vqp3ms, R), checked against both corpora
			-- on 2026-10-27; a hit says which corpus it came from.

	is_code_text (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_text' a code: ASCII letters, digits and dashes with at least one letter, then an
			-- optional final * (nothing a GLOB pattern could read as more than a prefix)? Codes match
			-- as the corpora write them, letter case included.
		local
			i, l_last: INTEGER
		do
			l_last := a_text.count
			if l_last > 0 and then a_text [l_last] = '*' then
				l_last := l_last - 1
			end
			Result := l_last >= 1
			from i := 1 until i > l_last or not Result loop
				Result := a_text [i].natural_32_code < 128 and then (a_text [i].is_alpha_numeric or a_text [i] = '-')
				i := i + 1
			end
			Result := Result and then across 1 |..| l_last as ic some a_text [ic].is_alpha end
		end


end
