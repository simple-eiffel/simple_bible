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
			-- Skeletal (Phase 5, AC-1a-23; needs LG-01): normalized (normalized (s)) = normalized (s) for all three.
		do
		end

	test_trap_corpus_has_no_combining_mark
			-- Skeletal (Phase 5, AC-1a-23; needs LG-01): no combining mark survives on the trap corpus.
		do
		end

	test_normalized_column_finds_display_phrase
			-- Skeletal (Phase 5, AC-1a-20): MapM NBSP kept in display; the phrase found through the normalized column.
		do
		end

end
