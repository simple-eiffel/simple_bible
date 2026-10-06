note
	description: "Study engines: related passages, divine names, journey, guides, export (AC-1a-28..33, 38, 51)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_STUDY

inherit
	TEST_SET_BASE

feature -- Tests

	test_ai_made_related_passage_is_labeled
		local
			r: BIB_RELATED_PASSAGE
		do
			create r.make (fx.ref (19, 23, 1), 15000, <<"AI-made: meaning neighbor">>, fx.ai_provenance)
			assert ("ai", r.is_ai_made)
			assert ("labeled", r.ai_label.same_string ({BIB_TRUST_LABELS}.Ai_made_label))
			assert ("model id", not r.provenance.model_id.is_empty)
		end

	test_plain_related_passage_has_reason
		local
			r: BIB_RELATED_PASSAGE
		do
			create r.make (fx.ref (19, 23, 1), 15000, <<"cross-reference (OpenBible, 57 votes)">>, fx.provenance (40, "OB-XREF"))
			assert ("not ai", not r.is_ai_made)
			assert_integers_equal ("one reason", 1, r.reason_count)
			assert ("no ai label", r.ai_label.is_empty)
		end

	test_surface_form_mark_is_labeled
		local
			m: BIB_NAME_MARK
		do
			create m.make (create {BIB_TEXT_SPAN}.make (1, 6, 0), "Kyrios", "Kyrios (surface-form match)", True, fx.swete_provenance)
			assert ("surface", m.is_surface_form_match)
			assert ("labeled", m.legend_reason.has_substring ({BIB_TRUST_LABELS}.Surface_form_label))
		end

	test_journey_row_carries_method
		local
			r: BIB_JOURNEY_ROW
		do
			create r.make ("Tyndale 1526", 1526, "congregation", 112, "count of the rendering over ekklesia tokens", fx.provenance (41, "TYNDALE"))
			assert ("method on row", not r.method_label.is_empty)
			assert ("rendering", r.rendering.same_string_general ("congregation"))
		end

	test_text_first_guide_holds_text
		local
			g: BIB_GUIDE
			s: BIB_GUIDE_SECTION
			l: BIB_LIST_RESULT [BIB_FACT [INTEGER_64]]
			p: BIB_PROVENANCE
		do
			p := fx.provenance (42, "BSB")
			create l.make_success (fx.method ("verse"), <<p>>, <<create {BIB_FACT [INTEGER_64]}.make (1, p)>>)
			create s.make (1, {BIB_GUIDE_SECTION}.Section_text, "Text", l)
			create g.make ({BIB_GUIDE}.Passage_guide, True, s, fx.method ("guide"))
			assert ("text first", g.is_text_first)
			assert ("no library", not g.has_section_kind ({BIB_GUIDE_SECTION}.Section_library))
			assert ("cited", g.citation_count >= 1)
			assert ("closed", g.is_fact_closed)
		end

	test_share_alike_notice_exists
		do
			assert ("notice", not (create {BIB_ATTRIBUTION}).share_alike_notice.is_empty)
		end

	test_ekklesia_journey
			-- Skeletal (Phase 5, AC-1a-28): Tyndale "congregation" and KJV "church", counts and a method on every row.
		do
		end

	test_gen_7_16_divine_names
			-- Skeletal (Phase 5, AC-1a-29): Elohim and YHWH marked; Swete-side marks labeled "surface-form match".
		do
		end

	test_range_fifty_lemma_sample
			-- Skeletal (Phase 5, AC-1a-30): every distinct gloss with counts for the fixed 50-lemma sample.
		do
		end

	test_fact_closure_every_engine
			-- Skeletal (Phase 5, AC-1a-32): every engine result in the suite is fact-closed.
		do
		end

	test_ai_neighbors_gated_by_tokenizer_golden
			-- Skeletal (Phase 5, AC-1a-33, RQ-04): AI-made neighbors ship only if the bge-m3 tokenizer golden passes.
		do
		end

	test_text_first_job_excludes_commentary
			-- Skeletal (Phase 5, AC-1a-38): a text-first passage guide has no library, author or lens section.
		do
		end

	test_export_keeps_attribution_and_labels
			-- Skeletal (Phase 5, AC-1a-51): Swete export carries attribution and the CC BY-SA notice; AI-made items keep their label.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
