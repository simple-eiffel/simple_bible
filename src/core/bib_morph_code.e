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

	Robinson: STRING_8 = "robinson"
			-- Greek New Testament codes: N-NSF, V-AAI-3S, and CONJ, PREP, ADV, PRT, COND, HEB, ARAM, INJ.

	Oshb: STRING_8 = "oshb"
			-- Hebrew Bible codes (Westminster Hebrew): Ncfsa, Vqp3ms, and the single capitals R, C, D, T.

	is_code_text (a_text: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_text' a code: letters, digits and dashes with at least one letter, then an optional
			-- final * (nothing that a pattern could read as more than a prefix)?
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

	scheme_of (a_text: READABLE_STRING_GENERAL): STRING_8
			-- `Oshb' for a code holding a lowercase letter or one capital alone; `Robinson' otherwise
			-- (no shipped code fits both: checked against both corpora, 2026-10-27).
		require
			code_text: is_code_text (a_text)
		local
			l_letters: INTEGER
			l_lower: BOOLEAN
		do
			across 1 |..| a_text.count as ic loop
				if a_text [ic].is_alpha then
					l_letters := l_letters + 1
					l_lower := l_lower or a_text [ic].is_lower
				end
			end
			if l_lower or (l_letters = 1 and not a_text.has ('-')) then
				Result := Oshb
			else
				Result := Robinson
			end
		ensure
			one_of_two: Result = Oshb or Result = Robinson
		end

invariant
	scheme_not_empty: not scheme.is_empty
	code_not_empty: not code.is_empty

end
