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
				-- Design scan 32: the Bible by name, never its code (FR-156), as the window shows it.
			assert_true ("bible and headword", l_text.has_substring ("Berean Standard Bible  bara - BRA  x1"))
			assert_false ("no corpus code", l_text.has_substring ("ENG-BSB"))
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
				-- Design scan 32: no corpus given, the book chooses it (the window's rule), not a fixed Hebrew default.
			assert_true ("corpus from the book", commands.verse (1, 1, 1, "").starts_with ("1  B  b  [word 5]"))
			finish
		end

	test_strongs_command
			-- FR-153: through lemma_xref only; not a number, a plain answer.
		do
			assert_true ("bara", commands.strongs ("H01254").has_substring ("[word 1]  bara - BRA"))
			assert_true ("not a number", commands.strongs ("X12").has_substring ("Not a Strong's number"))
			finish
		end

	test_lookup_choices
			-- What a reader types becomes choices (the window's lookup box): a headword, an English
			-- word, a verse with a prefix joined to its word, a Strong's number, nothing.
		local
			l_lookup: BIB_LOOKUP
			l_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE]
		do
			create l_lookup.make (commands.bible)
			l_choices := l_lookup.choices_for ("bara")
			assert_true ("headword", l_choices.count = 1 and then l_choices.first.lemma_id = {CONC_FIXTURE}.Create_lemma)
			l_choices := l_lookup.choices_for ("created")
			assert_true ("english", l_choices.count = 1 and then l_choices.first.lemma_id = {CONC_FIXTURE}.Create_lemma and then l_choices.first.detail.has_substring ("behind"))
			l_choices := l_lookup.choices_for ("Gen 1:1")
			assert_integers_equal ("two words in the verse", 2, l_choices.count)
			assert_strings_equal ("prefix joined", "BBRA", l_choices.first.label)
			assert_strings_equal ("transliterations joined", "b-bara", l_choices.first.detail)
			assert_true ("opens the word, not the prefix", l_choices.first.lemma_id = {CONC_FIXTURE}.Create_lemma)
			assert_true ("verse note", l_lookup.note_text.has_substring ("Genesis 1:1 in the Hebrew Bible"))
			assert_true ("the verse named", attached l_lookup.last_verse as al_v and then (al_v.book = 1 and al_v.chapter = 1 and al_v.verse = 1))
			assert_integers_equal ("the same words by number (a verse clicked in S1)", 2, l_lookup.verse_choices (1, 1, 1).count)
			assert_integers_equal ("strongs", 1, l_lookup.choices_for ("H1254").count)
			assert_true ("no verse named", l_lookup.last_verse = Void)
				-- The reference box (C4): a verse, a chapter, numbers without a colon, a two-word book.
			assert_true ("Gen 1:1", attached l_lookup.place_named ("Gen 1:1") as al_p and then (al_p.book = 1 and al_p.chapter = 1 and al_p.verse = 1))
			assert_true ("Genesis 1, the whole chapter", attached l_lookup.place_named ("Genesis 1") as al_p and then (al_p.book = 1 and al_p.chapter = 1 and al_p.verse = 0))
			assert_true ("Gen 1 1", attached l_lookup.place_named (" Gen 1 1 ") as al_p and then al_p.verse = 1)
			assert_true ("Exodus 2", attached l_lookup.place_named ("Exodus 2") as al_p and then al_p.book = 2)
			assert_true ("not a place", l_lookup.place_named ("bara") = Void and l_lookup.place_named ("Zzz 3") = Void)
			assert_true ("empty", l_lookup.choices_for ("  ").is_empty and not l_lookup.note_text.is_empty)
			assert_true ("nothing", l_lookup.choices_for ("zzz").is_empty and l_lookup.note_text.has_substring ("Nothing found"))
			finish
		end

	test_corpus_names_and_headword_corpus
			-- Readers see corpus names, never codes (FR-156); a headword opens where it occurs most.
		do
			assert_strings_equal ("name", "Hebrew Bible", commands.bible.conc_pack.corpus_name ("WLC-MACULA"))
			assert_strings_equal ("unknown code shown as is", "XYZ", commands.bible.conc_pack.corpus_name ("XYZ"))
			assert_strings_equal ("a short name has nothing to cut", "Hebrew Bible", commands.bible.conc_pack.corpus_short_name ("WLC-MACULA"))
			if attached commands.bible.conc_pack.word_entry ({CONC_FIXTURE}.Create_lemma) as al_entry then
				assert_strings_equal ("top corpus", "WLC-MACULA", commands.bible.conc_pack.corpus_of (al_entry.provenance))
			else
				assert_true ("entry", False)
			end
			finish
		end

	test_lookup_reports_a_broken_pack
			-- Design scan 32: a query that fails reads as the database's own words, not as
			-- "Nothing found" or "0 headwords". Before: the window's note said "Strong's H1254:
			-- 0 headwords" while the command line printed the error; after: both print the error.
		local
			l_fixture: CONC_FIXTURE
			l_db: SIMPLE_SQL_DATABASE
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_lookup: BIB_LOOKUP
			l_cli: BIB_CLI_COMMANDS
			l_memory: MEMORY
		do
			create l_fixture
			l_fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			l_fixture.build (Pack_file)
				-- The table is still there, so the pack opens; its column is not, so the query fails.
			create l_db.make (Pack_file)
			l_db.execute ("ALTER TABLE lemma_xref RENAME COLUMN value TO value_gone")
			l_db.close
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("the pack opened", l_bible.is_open and then l_bible.conc_pack.is_available)
			create l_lookup.make (l_bible)
			create l_cli.make (l_bible)
			assert_true ("no choices", l_lookup.choices_for ("H1254").is_empty)
			assert_false ("not read as zero headwords", l_lookup.note_text.has_substring ("0 headwords"))
			assert_true ("the window says what the command line says", l_cli.strongs ("H1254").has_substring (l_lookup.note_text))
			assert_true ("the error is kept", l_lookup.last_error /= Void)
			l_bible.close
				-- SQLite lets go of a file when its last statement is collected (close_v2).
			create l_memory
			l_memory.full_collect
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
