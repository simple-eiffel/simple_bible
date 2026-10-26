note
	description: "[
		The public build has no private code (2026-10-26 spec fold, debate 03
		pathway B'): no plug-in classes, no lens, no private names. Private
		material arrives only as data packs (FR-NEW-010, AC-1a-57). Name proposed
		by the fold (was TEST_PLUGIN_PURITY); fixed in Phase 4.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_PACK_PURITY

inherit
	TEST_SET_BASE

feature -- Tests

	test_no_plugin_classes
			-- The plug-in seam is gone: no class named BIB_PLUGIN, BIB_PLUGIN_REGISTRY,
			-- BIB_LENS or BIB_LENS_RESULT in the sources.
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
				assert ("no plug-in class: " + f, not f.has_substring ("bib_plugin") and not f.has_substring ("bib_lens"))
			end
		end

	test_private_source_is_one_generic_class
			-- BIB_PRIVATE_SOURCE is the one generic pack reader: nothing inherits it.
		local
			s: SOURCE_SCAN
		do
			create s
			across s.source_files as f loop
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
			-- Skeletal (app phase, AC-1a-57): scan the public executable for private names.
		do
		end

end
