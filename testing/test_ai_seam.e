note
	description: "The AI seam: the null adapter is bound; AI text exists only through the post-check, always labeled (AC-1a-54)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_AI_SEAM

inherit
	TEST_SET_BASE

feature -- Tests

	test_null_adapter_never_produces
		local
			a: BIB_NULL_AI_ADAPTER
		do
			create a
			assert ("nothing", a.explain (cited_result) = Void)
		end

	test_post_check_labels_and_fails_safe
		local
			c: BIB_AI_POST_CHECK
			t: BIB_AI_TEXT
			r: BIB_LIST_RESULT [BIB_FACT [INTEGER_64]]
		do
			r := cited_result
			create c
			t := c.checked ("It appears 114 times.", r, "test-model")
			assert ("labeled", t.is_labeled)
			assert ("basis kept", t.basis = r)
			assert ("withheld until the detectors exist", t.is_withheld and t.displayable_text.is_empty)
		end

	test_facade_binds_null_adapter
		local
			b: SIMPLE_BIBLE
		do
			create b.make (create {BIB_CONFIG}.make_with_core ("core.db"))
			assert ("null adapter", attached {BIB_NULL_AI_ADAPTER} b.ai_adapter)
		end

feature {NONE} -- Fixtures

	cited_result: BIB_LIST_RESULT [BIB_FACT [INTEGER_64]]
		local
			p: BIB_PROVENANCE
			fx: TEST_FIXTURES
		do
			create fx
			p := fx.provenance (7, "SBLGNT")
			create Result.make_success (fx.method ("concordance"), <<p>>, <<create {BIB_FACT [INTEGER_64]}.make (114, p)>>)
		end

end
