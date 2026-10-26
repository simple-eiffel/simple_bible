note
	description: "[
		The command line's commands (Phase 4, Task 9; FR-061), read as the text the
		program prints, over the fixture content.db and pack.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CLI_COMMANDS

inherit
	TEST_SET_BASE

feature -- Tests

	test_banner_is_the_pack_edition
			-- FR-157: the first line is the pack's own edition label.
		do
			assert_strings_equal ("banner", {CONC_FIXTURE}.Edition_label, commands.banner)
			finish
		end

	test_word_command
			-- The word view: heading, total and places; without a corpus, the one where it occurs most.
		local
			l_text: STRING_32
		do
			l_text := commands.word ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS")
			assert_true ("total", l_text.has_substring ("251 places in LXX-RAHLFS"))
			assert_true ("first place", l_text.has_substring ("Genesis 1:1"))
			assert_true ("the rest counted", l_text.has_substring ("and 231 more"))
			assert_true ("top corpus by default", commands.word ({CONC_FIXTURE}.Create_lemma, "").has_substring ("1 places in WLC-MACULA"))
			assert_true ("unknown headword", commands.word (999, "").has_substring ("no Hebrew, Aramaic or Greek headword"))
			finish
		end

	test_english_command
			-- FR-151: Bible by Bible, headword and count.
		local
			l_text: STRING_32
		do
			l_text := commands.english ("created")
			assert_true ("bible and headword", l_text.has_substring ("ENG-BSB  bara - BRA  x1"))
			assert_true ("unknown word", commands.english ("zzz").has_substring ("No original word"))
			finish
		end

	test_verse_command
			-- FR-152: every word of the verse, the prefix first, each a door.
		local
			l_text: STRING_32
		do
			l_text := commands.verse (1, 1, 1, "WLC-MACULA")
			assert_true ("prefix first", l_text.starts_with ("1  B  b  [word 5]"))
			assert_true ("door to bara", l_text.has_substring ("[word 1]"))
			assert_true ("unknown corpus", commands.verse (1, 1, 1, "XYZ").has_substring ("no corpus XYZ"))
			finish
		end

	test_strongs_command
			-- FR-153: through lemma_xref only; not a number, a plain answer.
		do
			assert_true ("bara", commands.strongs ("H01254").has_substring ("[word 1]  bara - BRA"))
			assert_true ("not a number", commands.strongs ("X12").has_substring ("Not a Strong's number"))
			finish
		end

feature {NONE} -- Fixture

	Content_file: STRING = "cli_test_content.db"
	Pack_file: STRING = "cli_test_pack.db"

	commands_cache: detachable BIB_CLI_COMMANDS

	commands: BIB_CLI_COMMANDS
			-- Commands over a fresh engine on the fixture files.
		local
			l_fixture: CONC_FIXTURE
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
		do
			if attached commands_cache as al_commands then
				Result := al_commands
			else
				create l_fixture
				l_fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
				l_fixture.build (Pack_file)
				create l_config.make_with_core (Content_file)
				l_config := l_config.set_conc_path (Pack_file)
				create l_bible.make (l_config)
				l_bible.open
				create Result.make (l_bible)
				commands_cache := Result
			end
		end

	finish
			-- Close the engine and delete the fixture files.
		local
			l_fixture: CONC_FIXTURE
		do
			if attached commands_cache as al_commands and then al_commands.bible.is_open then
				al_commands.bible.close
			end
			commands_cache := Void
			create l_fixture
			l_fixture.delete_file (Content_file)
			l_fixture.delete_file (Pack_file)
		end

end
