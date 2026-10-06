note
	description: "Author library status and the publication-scope rule (AC-1a-14, 34)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_AUTHOR_LIBRARY

inherit
	TEST_SET_BASE

feature -- Tests

	test_withdrawn_document_carries_banner
		local
			d: BIB_AUTHOR_DOC
		do
			create d.make (77, "An essay", "Rix/Substack Essays/an essay.md", "Substack Essays",
				create {BIB_DOC_STATUS}.make ({BIB_DOC_STATUS}.Withdrawn),
				"Withdrawn by the author. Kept for the record; not authority.", <<{INTEGER_64} 2501>>, fx.provenance (50, "RIX"))
			assert ("withdrawn", d.status.is_withdrawn)
			assert ("banner", not d.banner_text.is_empty)
			assert ("author voice", d.voice.is_author)
			assert ("cites John 3:16", d.cites (2501))
		end

	test_publication_rule_seals_on_approval
			-- The rule object only; no list content is assumed (synthetic patterns).
		local
			r: BIB_PUBLICATION_SCOPE_RULE
		do
			create r.make ("synthetic test list")
			r.add_exclusion ("Example/Private Folder/")
			r.add_exclusion ("Example/one file.md")
			assert ("unapproved", not r.is_approved)
			assert_integers_equal ("two patterns", 2, r.exclusion_count)
			assert ("folder pattern", r.is_folder_pattern ("Example/Private Folder/"))
			r.approve ("approver", "2026-10-06")
			assert ("approved", r.is_approved)
			assert_integers_equal ("list kept", 2, r.exclusion_count)
		end

	test_search_excludes_withdrawn_by_default
			-- Skeletal (Phase 5, AC-1a-34): search without "Include withdrawn" returns no withdrawn document.
		do
		end

	test_include_withdrawn_returns_banner
			-- Skeletal (Phase 5, AC-1a-34): with "Include withdrawn", withdrawn documents come last, with banners.
		do
		end

	test_publication_rule_excludes_listed_paths
			-- Skeletal (Phase 5, AC-1a-14): `is_excluded' on folder and exact patterns; differential fixture in bible_build.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

end
