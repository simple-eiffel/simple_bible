note
	description: "The public build has no plug-in, no effective lens or private source, and no private names (FR-NEW-010, AC-1a-57)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PLUGIN_PURITY

inherit
	TEST_SET_BASE

feature -- Tests

	test_public_registry_is_empty
		do
			assert_integers_equal ("no plug-ins", 0, (create {BIB_CONFIG}.make_with_core ("core.db")).plugin_registry.plugin_count)
		end

	test_registry_seals
		local
			r: BIB_PLUGIN_REGISTRY
		do
			create r.make
			r.seal
			assert ("sealed", r.is_sealed)
			assert_integers_equal ("still empty", 0, r.plugin_count)
		end

	test_no_effective_lens_or_private_source
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				assert ("no lens descendant: " + f, not s.inherits (f, "BIB_LENS") or f.has_substring ("bib_lens.e"))
				assert ("no private source descendant: " + f, not s.inherits (f, "BIB_PRIVATE_SOURCE") or f.has_substring ("bib_private_source.e"))
			end
		end

	test_no_private_names_in_sources
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				assert ("no scholars.db: " + f, not s.code_of (f).has_substring ("scholars.db"))
				assert ("no transcripts.db: " + f, not s.code_of (f).has_substring ("transcripts.db"))
				assert ("no podcast corpus: " + f, not s.code_of (f).as_lower.has_substring ("nakedbiblepodcast"))
			end
		end

	test_public_executable_has_no_private_strings
			-- Skeletal (app phase, AC-1a-57): scan the public executable for private names and effective lenses.
		do
		end

end
