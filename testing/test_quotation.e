note
	description: "They Chose (AC-1a-27)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_QUOTATION

inherit
	TEST_SET_BASE

feature -- Tests

	test_no_data_answer_names_edition
		local
			r: BIB_QUOTATION_RESULT
		do
			create r.make_no_data (Void, "Computed against Swete; not aligned.", fx.method ("quote"), <<fx.provenance (30, "UBS-PARALLELS")>>)
			assert ("no data", r.agreement.is_no_data)
			assert ("edition named", r.edition_note.has_substring ("Swete"))
			assert ("a successful answer", r.is_success)
		end

	test_hebrews_8_they_chose
			-- Skeletal (Phase 5, AC-1a-27): Heb 8:8-12 / LXX (Swete) Jer 38:31-34 / MT Jer 31:31-34 gives a computed
			-- agreement class with an edition note naming Swete and the OCR note, on a hand-verified span.
		do
		end

	test_unaligned_quotation_is_no_data
			-- Skeletal (Phase 5, AC-1a-27): an unaligned quotation yields NO_DATA.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
