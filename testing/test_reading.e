note
	description: "[
		The reading slice (fold 2026-10-26): content.db v2's versions and
		chapters through BIB_TEXT_READER, and place rows that know their verse
		so the reading pane can open them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_READING

inherit
	TEST_SET_BASE

feature -- Tests

	test_versions_and_a_chapter
			-- The versions in content.db's order, a chapter verse by verse, an omission told as
			-- one, the last chapter, and a chapter a version lacks read as empty, not failed.
		local
			l_reader: BIB_TEXT_READER
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
		do
			l_reader := bible.text_reader
			assert_integers_equal ("two versions", 2, l_reader.versions.count)
			assert_strings_equal ("in their order", "KJV", l_reader.versions.first.code)
			assert_true ("Hebrew right to left", attached l_reader.version ("WLC") as al_wlc and then al_wlc.is_right_to_left)
			assert_false ("English left to right", attached l_reader.version ("KJV") as al_kjv and then al_kjv.is_right_to_left)
			l_chapter := l_reader.chapter ("KJV", 1, 1)
			assert_true ("succeeded", l_chapter.is_success)
			assert_integers_equal ("three verses", 3, l_chapter.count)
			assert_strings_equal ("verse 1", "In the beginning God created the heaven and the earth.", l_chapter.item (1).text)
			assert_true ("verse 3 omitted", l_chapter.item (3).is_omitted and then l_chapter.item (3).display_text.has_substring ("omits"))
			assert_integers_equal ("last chapter", 2, l_reader.last_chapter ("KJV", 1))
			assert_integers_equal ("a book the version lacks", 0, l_reader.last_chapter ("KJV", 2))
			l_chapter := l_reader.chapter ("KJV", 2, 1)
			assert_true ("absent chapter: success, empty", l_chapter.is_success and l_chapter.count = 0)
			assert_integers_equal ("Hebrew Genesis 1", 1, l_reader.chapter ("WLC", 1, 1).count)
			finish
		end

	test_place_rows_know_their_verse
			-- A place opens in the reading pane: it carries its book, chapter and verse as numbers.
		local
			l_places: BIB_LIST_RESULT [BIB_PLACE_ROW]
		do
			l_places := bible.conc_pack.place_page ({CONC_FIXTURE}.Create_lemma, "WLC-MACULA", 0, 10)
			assert_true ("found", l_places.is_success and l_places.count >= 1)
			assert_true ("Genesis 1:1", l_places.item (1).book_id = 1 and l_places.item (1).chapter = 1 and l_places.item (1).verse = 1)
			assert_true ("readable", l_places.item (1).is_readable)
			finish
		end

	test_a_failing_chapter_query_says_why
			-- Design scan 33: the reader's queries go through the shared BIB_SQLITE_QUERYING, so a
			-- broken table is a failure with the reader's message and SQLite's own words.
		local
			l_db: SIMPLE_SQL_DATABASE
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_config: BIB_CONFIG
			l_reopened: SIMPLE_BIBLE
			l_memory: MEMORY
		do
			l_chapter := bible.text_reader.chapter ("KJV", 1, 1)
			assert_true ("reads before", l_chapter.is_success)
			bible.close
			create l_memory
			l_memory.full_collect
			create l_db.make (Content_file)
			l_db.execute ("ALTER TABLE verse_text RENAME COLUMN text TO text_gone")
			l_db.close
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_reopened.make (l_config)
			l_reopened.open
			assert_true ("opens: the table is there", l_reopened.is_open)
			l_chapter := l_reopened.text_reader.chapter ("KJV", 1, 1)
			assert_false ("fails", l_chapter.is_success)
			assert_true ("the reader's words", attached l_chapter.error as al_e and then al_e.message.has_substring ("Bible text query failed"))
			assert_true ("the method is recorded", l_chapter.method.engine_feature.same_string_general ("chapter"))
			l_reopened.close
			finish
		end

feature {NONE} -- Fixture

	Content_file: STRING = "reading_test_content.db"
	Pack_file: STRING = "reading_test_pack.db"

	bible_cache: detachable SIMPLE_BIBLE

	bible: SIMPLE_BIBLE
			-- A fresh engine on the fixture files.
		local
			l_fixture: CONC_FIXTURE
			l_config: BIB_CONFIG
		do
			if attached bible_cache as al_bible then
				Result := al_bible
			else
				create l_fixture
				l_fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
				l_fixture.build (Pack_file)
				create l_config.make_with_core (Content_file)
				l_config := l_config.set_conc_path (Pack_file)
				create Result.make (l_config)
				Result.open
				bible_cache := Result
			end
		end

	finish
			-- Close the engine and delete the fixture files.
		local
			l_fixture: CONC_FIXTURE
			l_memory: MEMORY
		do
			if attached bible_cache as al_bible and then al_bible.is_open then
				al_bible.close
			end
			bible_cache := Void
			create l_memory
			l_memory.full_collect
			create l_fixture
			l_fixture.delete_file (Content_file)
			l_fixture.delete_file (Pack_file)
		end

end
