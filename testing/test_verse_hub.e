note
	description: "Version labels, verse counts, seals and typed omissions (AC-1a-19, 20, 31, 35)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_VERSE_HUB

inherit
	TEST_SET_BASE

feature -- Tests

	test_kjv_label
		local
			v: BIB_VERSION_INFO
		do
			v := fx.version_info ("KJV", {BIB_TRUST_LABELS}.Kjv_label, "1769 Blayney", "eng", False, False)
			assert ("kjv label", v.display_label.same_string ({BIB_TRUST_LABELS}.Kjv_label))
		end

	test_septuagint_label_names_edition
		local
			v: BIB_VERSION_INFO
		do
			v := fx.version_info ("SWETE", "LXX (Swete)", "Swete", "grc", True, True)
			assert ("not bare", not v.display_label.same_string ({BIB_TRUST_LABELS}.Bare_lxx))
			assert ("edition in label", v.display_label.has_substring (v.edition))
			assert ("quality caveat", not v.text_quality_caveat.is_empty)
		end

	test_version_reports_count_and_seal
		local
			v: BIB_VERSION_INFO
		do
			v := fx.version_info ("BSB", "BSB", "2020", "eng", False, False)
			assert ("counted", v.verse_count > 0)
			assert_integers_equal ("sealed", 64, v.seal.count)
			assert ("has genesis", v.has_book (1))
		end

	test_omission_is_typed_never_empty
			-- Matt 17:21 in WH: "omitted in this edition".
		local
			t: BIB_VERSE_TEXT
			v: BIB_VERSION_INFO
			o: BIB_OMISSION
		do
			v := fx.version_info ("WH", "Westcott-Hort", "1881", "grc", False, False)
			create o.make ({BIB_OMISSION}.Edition_omitted, "omitted in this edition (WH)")
			create t.make_omission (fx.ref (40, 17, 21), 23677, v, o, fx.provenance (11, "WH"))
			assert ("no text", t.display_text = Void)
			assert ("omission shown", attached t.omission as l_o and then l_o.reason_text.has_substring ({BIB_TRUST_LABELS}.Omitted_in_edition))
		end

	test_not_in_canon_omission
		local
			t: BIB_VERSE_TEXT
			o: BIB_OMISSION
		do
			create o.make ({BIB_OMISSION}.Not_in_canon, "not in this canon")
			create t.make_omission (fx.ref (67, 1, 1), 40001, fx.version_info ("BSB", "BSB", "2020", "eng", False, False), o, fx.provenance (12, "BSB"))
			assert ("typed", attached t.omission as l_o and then l_o.code = {BIB_OMISSION}.Not_in_canon)
		end

	test_display_text_kept_exactly
			-- AC-1a-20 shape: the stored display text is the source text, NBSP before paseq included.
		local
			s: STRING_32
			t: BIB_VERSE_TEXT
		do
			create s.make_empty
			s.append_character ((0x05D1).to_character_32)
			s.append_character ((0x00A0).to_character_32)
			s.append_character ((0x05C0).to_character_32)
			s.append_character ((0x05E8).to_character_32)
			create t.make_text (fx.ref (1, 1, 1), 1, fx.version_info ("WLC", "WLC", "4.20", "hbo", False, False), s,
				create {BIB_REPAIR_STATE}.make_not_applicable, fx.provenance (13, "WLC"))
			assert ("byte-equal", attached t.display_text as d and then d.same_string (s))
		end

	test_matt_17_21_in_wh
			-- Skeletal (Phase 5, AC-1a-19): hub.verse on the fixture returns the WH omission for Matt 17:21.
		do
		end

	test_tobit_in_bsb
			-- Skeletal (Phase 5, AC-1a-19): Tobit in the BSB answers "not in this canon".
		do
		end

	test_every_version_answers
			-- Skeletal (Phase 5, AC-1a-19/31): one text or typed omission per requested version, never "".
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
