note
	description: "Facade and configuration tests (fleet LIB_TESTS)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Tests

	test_config_builder_chains_and_frames
		local
			l_config: BIB_CONFIG
		do
			create l_config.make_with_core ("core.db")
			l_config := l_config.set_ai_data_path ("ai_data.db").set_rix_path ("rix.db").set_user_path ("user.db").set_default_version ("KJV")
			assert ("core kept", l_config.core_path.same_string_general ("core.db"))
			assert ("ai set", l_config.ai_data_path.same_string_general ("ai_data.db"))
			assert ("rix set", l_config.rix_path.same_string_general ("rix.db"))
			assert ("user set", l_config.user_path.same_string_general ("user.db"))
			assert ("default version", l_config.default_version.same_string ("KJV"))
			assert ("valid", l_config.is_valid)
		end

	test_facade_starts_unopened
		local
			l_bible: SIMPLE_BIBLE
		do
			create l_bible.make (create {BIB_CONFIG}.make_with_core ("core.db"))
			assert ("not open", not l_bible.is_open)
			assert ("no error", l_bible.last_error = Void)
			assert ("no author library", not l_bible.has_author_library)
		end

	test_facade_has_no_history
		local
			l_bible: SIMPLE_BIBLE
		do
			create l_bible.make (create {BIB_CONFIG}.make_with_core ("core.db"))
			assert ("history is v2", not l_bible.has_history)
		end

	test_portable_config
		local
			l_config: BIB_CONFIG
		do
			create l_config.make_portable
			assert ("portable", l_config.is_portable)
			assert ("no plug-ins", l_config.plugin_registry.plugin_count = 0)
		end

	test_open_checks_core_schema
			-- Skeletal (Phase 5, AC-1a-04 read side): open the core.db fixture; a table without its
			-- provenance column makes `open' fail with Schema_mismatch.
		do
		end

	test_rerun_gives_identical_counts
			-- Skeletal (Phase 5, AC-1a-31): every recorded method re-runs to identical counts.
		do
		end

end
