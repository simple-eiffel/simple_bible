note
	description: "Normalizers (AC-1a-20, 21, 23); the full normalizers wait on LG-01 (simple_encoding)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_NORMALIZERS

inherit
	TEST_SET_BASE

feature -- Tests

	test_pointing_marks_classified
		local
			r: BIB_POINTING_REDUCER
		do
			create r
			assert ("etnahta is cantillation", r.is_cantillation ((0x0591).to_character_32))
			assert ("qamats is a vowel point", r.is_vowel_point ((0x05B8).to_character_32))
			assert ("bet is neither", not r.is_cantillation ((0x05D1).to_character_32) and not r.is_vowel_point ((0x05D1).to_character_32))
		end

	test_script_classifier
		local
			c: BIB_SCRIPT_CLASSIFIER
		do
			create c
			assert_integers_equal ("aleph", c.Script_hebrew, c.script_of ((0x05D0).to_character_32))
			assert_integers_equal ("alpha", c.Script_greek, c.script_of ((0x03B1).to_character_32))
			assert_integers_equal ("a", c.Script_latin, c.script_of ('a'))
			assert_integers_equal ("digit", c.Script_other, c.script_of ('7'))
		end

	test_normalizers_idempotent
			-- AC-1a-23 (LG-01 landed 2026-10-27): each normalizer gives its search form, and folding
			-- that form again changes nothing.
		local
			l_set: BIB_NORMALIZER_SET
			l_hebrew, l_greek, l_english: STRING_32
		do
			create l_set.make (create {BIB_SIMPLE_UNICODE}.make)
			l_hebrew := l_set.hebrew.normalized (codes (<<0x05D1, 0x05B0, 0x05BC, 0x05E8, 0x05B5, 0x05D0, 0x05E9, 0x05C1, 0x05B4, 0x0596, 0x05D9, 0x05EA, 0x20, 0x05D0, 0x05B1, 0x05DC, 0x05B9, 0x05D4, 0x05B4, 0x0591, 0x05D9, 0x05DD, 0x20, 0x05E2, 0x05B7, 0x05DC, 0x05BE, 0x05E4, 0x05BC, 0x05B0, 0x05E0, 0x05B5, 0x05D9>>))
			assert ("Hebrew: consonants, final mem folded, maqaf a space", l_hebrew.same_string (codes (<<0x05D1, 0x05E8, 0x05D0, 0x05E9, 0x05D9, 0x05EA, 0x20, 0x05D0, 0x05DC, 0x05D4, 0x05D9, 0x05DE, 0x20, 0x05E2, 0x05DC, 0x20, 0x05E4, 0x05E0, 0x05D9>>)))
			l_greek := l_set.greek.normalized (codes (<<0x1F18, 0x03BD, 0x20, 0x1F00, 0x03C1, 0x03C7, 0x1FC7, 0x20, 0x1F26, 0x03BD, 0x20, 0x1F41, 0x20, 0x03BB, 0x03CC, 0x03B3, 0x03BF, 0x03C2>>))
			assert ("Greek: accentless, lowercase, final sigma folded", l_greek.same_string (codes (<<0x03B5, 0x03BD, 0x20, 0x03B1, 0x03C1, 0x03C7, 0x03B7, 0x20, 0x03B7, 0x03BD, 0x20, 0x03BF, 0x20, 0x03BB, 0x03BF, 0x03B3, 0x03BF, 0x03C3>>)))
			l_english := l_set.english.normalized (codes (<<0x201C, 0x49, 0x6E, 0xA0, 0x47, 0x6F, 0x64, 0x2019, 0x73, 0x201D, 0x2014, 0x41, 0x6D, 0x65, 0x6E>>))
			assert ("English: quotes, no-break space and dash folded, lowercase", l_english.same_string ({STRING_32} "%"in god's%"-amen"))
			assert ("Hebrew idempotent", l_set.hebrew.normalized (l_hebrew).same_string (l_hebrew))
			assert ("Greek idempotent", l_set.greek.normalized (l_greek).same_string (l_greek))
			assert ("English idempotent", l_set.english.normalized (l_english).same_string (l_english))
		end

	test_trap_corpus_has_no_combining_mark
			-- AC-1a-23: no mark or format character survives: cantillation, a zero-width joiner, a
			-- Greek iota subscript, a combining acute after a Latin letter.
		local
			l_set: BIB_NORMALIZER_SET
			l_form: STRING_32
		do
			create l_set.make (create {BIB_SIMPLE_UNICODE}.make)
			l_form := l_set.hebrew.normalized (codes (<<0x05D9, 0x05B0, 0x05D4, 0x05B4, 0x0599, 0x200D, 0x05D9>>))
			assert ("Hebrew", not l_set.hebrew.has_combining_mark (l_form) and l_form.same_string (codes (<<0x05D9, 0x05D4, 0x05D9>>)))
			l_form := l_set.greek.normalized (codes (<<0x1FB3, 0x0345>>))
			assert ("Greek", not l_set.greek.has_combining_mark (l_form) and l_form.same_string (codes (<<0x03B1>>)))
			l_form := l_set.english.normalized (codes (<<0x65, 0x0301, 0x200B, 0x65>>))
			assert ("Latin", not l_set.english.has_combining_mark (l_form) and l_form.same_string ({STRING_32} "ee"))
		end

	test_normalized_column_finds_display_phrase
			-- Skeletal (Phase 5, AC-1a-20): MapM NBSP kept in display; the phrase found through the normalized column.
		do
		end

feature {NONE} -- Implementation

	codes (a_codes: ARRAY [INTEGER]): STRING_32
			-- Text from code points (the sources stay ASCII).
		do
			create Result.make (a_codes.count)
			across a_codes as ic loop
				Result.append_character (ic.to_character_32)
			end
		end

end
