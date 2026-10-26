note
	description: "[
		Timing on the real concordance pack (Phase 4, Task 8; NFR-002, NFR-019,
		Phase 2 verdict condition 5). The pack's path comes from the environment
		variable SIMPLE_BIBLE_CONC (the personal conc.db never enters this
		repository); without it these tests are reported as skeletal. Each
		measured call runs inside `without_contracts' (timing trumps contracts);
		judge the numbers from the lean build. "First" is the first call in this
		process (the operating system may still hold the file in memory).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CONC_TIMING

inherit
	TEST_SET_BASE

feature -- Status

	is_runnable: BOOLEAN
			-- Is SIMPLE_BIBLE_CONC set to a file?
		do
			Result := attached conc_path as al_path and then (create {SIMPLE_FILE}.make (al_path)).is_file
		end

feature -- Tests

	test_word_view_first_screen
			-- NFR-019: the word view's first screen (heading, how often, first page of 200) within
			-- 200 milliseconds warm, for the commonest words; NFR-002's 2 seconds for the first call.
		require
			runnable: is_runnable
		local
			l_bible: SIMPLE_BIBLE
			i: INTEGER
		do
			l_bible := opened_bible
			report ("word view, Greek article (LXX), first", agent view (l_bible, Greek_article, "LXX-RAHLFS"), 2000)
			from i := 1 until i > 3 loop
				report ("word view, Greek article (LXX), warm " + i.out, agent view (l_bible, Greek_article, "LXX-RAHLFS"), 200)
				i := i + 1
			end
			report ("word view, Hebrew 'and', first", agent view (l_bible, Hebrew_and, "WLC-MACULA"), 2000)
			report ("word view, Hebrew 'and', warm", agent view (l_bible, Hebrew_and, "WLC-MACULA"), 200)
			l_bible.close
			remove_test_files
		end

	test_deep_pages_offset_and_keyset
			-- Verdict condition 5: the deepest offset page of the Greek article. Under 125 milliseconds
			-- first-in-process, `place_page_after' may be dropped; the keyset page is the comparison.
		require
			runnable: is_runnable
		local
			l_bible: SIMPLE_BIBLE
			l_before: BIB_LIST_RESULT [BIB_PLACE_ROW]
		do
			l_bible := opened_bible
			report ("deepest offset page (row 88,200), first", agent offset_page (l_bible, 88200), 2000)
			report ("deepest offset page (row 88,200), warm", agent offset_page (l_bible, 88200), 2000)
			l_before := l_bible.conc_pack.place_page (Greek_article, "LXX-RAHLFS", 88000, 200)
			assert_true ("page before the deepest", l_before.is_success and then l_before.count = 200)
			report ("keyset page after row 88,200, warm", agent keyset_page (l_bible, l_before.item (200).token_id), 2000)
			l_bible.close
			remove_test_files
		end

	test_english_and_verse_lookups
			-- NFR-002: the English lookup of a common word and the verse lookup of Genesis 1:1.
		require
			runnable: is_runnable
		local
			l_bible: SIMPLE_BIBLE
		do
			l_bible := opened_bible
			report ("English lookup 'god', first", agent english (l_bible, "god"), 2000)
			report ("English lookup 'god', warm", agent english (l_bible, "god"), 2000)
			report ("verse lookup Genesis 1:1 (Hebrew), first", agent verse (l_bible), 2000)
			l_bible.close
			remove_test_files
		end

feature {NONE} -- Measured work

	view (a_bible: SIMPLE_BIBLE; a_lemma: INTEGER_64; a_corpus: STRING)
		do
			last_ok := a_bible.word_lookup.view (a_lemma, a_corpus).is_success
		end

	offset_page (a_bible: SIMPLE_BIBLE; a_offset: INTEGER)
		do
			last_ok := a_bible.conc_pack.place_page (Greek_article, "LXX-RAHLFS", a_offset, 200).is_success
		end

	keyset_page (a_bible: SIMPLE_BIBLE; a_after: INTEGER_64)
		do
			last_ok := a_bible.conc_pack.place_page_after (Greek_article, "LXX-RAHLFS", a_after, 200).is_success
		end

	english (a_bible: SIMPLE_BIBLE; a_word: STRING)
		do
			last_ok := a_bible.english_index.rows (a_word).is_success
		end

	verse (a_bible: SIMPLE_BIBLE)
		do
			last_ok := a_bible.verse_word_lookup.words (create {BIB_REF}.make (1, 1, 1, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), "WLC-MACULA").is_success
		end

	last_ok: BOOLEAN
			-- Did the last measured call answer successfully?

feature {NONE} -- Fixture

	Greek_article: INTEGER_64 = 9380
			-- The Greek article: 88,444 places in the LXX (review spike R1).

	Hebrew_and: INTEGER_64 = 8
			-- Hebrew "and": 50,272 places (debate 05b addendum).

	Content_file: STRING = "timing_test_content.db"

	conc_path: detachable STRING_32
			-- SIMPLE_BIBLE_CONC, the personal pack's path.
		do
			Result := (create {SIMPLE_ENV}).item ("SIMPLE_BIBLE_CONC")
		end

	opened_bible: SIMPLE_BIBLE
			-- An engine over a fixture content.db and the real pack, open.
		require
			runnable: is_runnable
		local
			l_config: BIB_CONFIG
			l_fixture: CONC_FIXTURE
		do
			create l_fixture
			l_fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			create l_config.make_with_core (Content_file)
			if attached conc_path as al_path then
				l_config := l_config.set_conc_path (al_path)
			end
			create Result.make (l_config)
			Result.open
			assert_true ("open with the real pack", Result.is_open and then Result.conc_pack.is_available)
		end

	report (a_label: STRING; a_work: PROCEDURE; a_budget_ms: INTEGER)
			-- Time `a_work' without contracts, print the line, and hold it to `a_budget_ms'.
		local
			l_clock: SIMPLE_MONOTONIC_CLOCK
			l_start, l_micro: INTEGER_64
		do
			create l_clock
			last_ok := False
			l_start := l_clock.microseconds
			without_contracts (a_work)
			l_micro := l_clock.microseconds - l_start
			print ("    " + a_label + ": " + (l_micro // 1000).out + "." + ((l_micro \\ 1000) // 100).out + " ms (budget " + a_budget_ms.out + " ms)%N")
			assert_true (a_label + " answered", last_ok)
			assert_true (a_label + " within budget", l_micro <= a_budget_ms.to_integer_64 * 1000)
		end

	remove_test_files
			-- Delete the fixture content.db.
		do
			(create {CONC_FIXTURE}).delete_file (Content_file)
		end

end
