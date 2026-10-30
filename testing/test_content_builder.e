note
	description: "[
		bible_build's builder (Phase 4, Task 10): content.db v1 from a bible.db
		book list, checked by the engine before it replaces anything. The input
		bible.db is a small one made here; nothing from the vault is committed.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CONTENT_BUILDER

inherit
	TEST_SET_BASE

feature -- Tests

	test_builds_a_content_db_the_engine_opens
			-- The built file opens as SIMPLE_BIBLE's main database, with the concordance beside it.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("books", 3, l_builder.books_written)
			assert_integers_equal ("versions", 5, l_builder.versions_written)
			assert_integers_equal ("verses", 4, l_builder.verses_written)
			assert_integers_equal ("cross-references, a book outside 1 to 66 left out", 1, l_builder.cross_references_written)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("opens", l_bible.is_open and l_bible.conc_pack.is_available)
			assert_strings_equal ("edition", "test-build", l_bible.database_edition)
			assert_true ("Hebrew reads right to left", attached l_bible.text_reader.version ("WLC") as al_wlc and then al_wlc.is_right_to_left and then al_wlc.language.same_string ("hbo"))
			assert_true ("personal only is restricted", attached l_bible.text_reader.version ("NWT2013") as al_nwt and then al_nwt.provenance.license.is_restricted)
				-- 2026-10-30: the vault's source_provenance decides, not bible_versions' "MIT"
			assert_true ("the KJV is public domain, not MIT", attached l_bible.text_reader.version ("KJV") as al_kjv and then (al_kjv.provenance.license.identifier.starts_with ("Public Domain") and not al_kjv.provenance.license.is_restricted))
			assert_true ("the WLC is CC BY 4.0, free to share", attached l_bible.text_reader.version ("WLC") as al_wlc2 and then (al_wlc2.provenance.license.identifier.same_string ("CC BY 4.0") and al_wlc2.provenance.license.may_ship_in_free_tool))
			assert_true ("a non-commercial text is shared in the free tool", attached l_bible.text_reader.version ("TgO") as al_tgo and then (al_tgo.provenance.license.is_non_commercial and al_tgo.provenance.license.may_ship_in_free_tool))
			assert_true ("a version with no provenance row is unknown, not shared", attached l_bible.text_reader.version ("SP") as al_sp and then (al_sp.provenance.license.is_unknown and not al_sp.provenance.license.may_ship_in_free_tool))
			assert_integers_equal ("Genesis 1 in the KJV", 2, l_bible.text_reader.chapter ("KJV", 1, 1).count)
			assert_true ("a single-verse target", l_bible.text_reader.cross_references (1, 1, 1).count = 1 and then not l_bible.text_reader.cross_references (1, 1, 1).item (1).is_range)
			l_bible.close
			remove_test_files
		end

	test_verse_index_finds_words_phrases_and_pointed_hebrew
			-- bible_build 0.3.0 writes verse_fts; the reader finds every word, a quoted phrase, a
			-- prefix, any letter case, and pointed Hebrew from unpointed typing.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
			l_found: BIB_LIST_RESULT [BIB_READING_VERSE]
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_db.make (Bible_file)
			l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 3, 'And God said, Let there be light: and there was light.')")
			l_db.execute_with_args ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (16, 1, 1, 2, ?)", {ARRAY [detachable ANY]} <<codes (<<0x05D5, 0x05B0, 0x05D4, 0x05B8, 0x05D0, 0x05B8, 0x0597, 0x05E8, 0x05B6, 0x05E5>>)>>)
			l_db.close
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("every verse indexed", 6, l_builder.verses_indexed)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("an index", l_bible.text_reader.has_verse_index)
			assert_integers_equal ("a word", 1, found_in (l_bible, "KJV", "light"))
			l_found := l_bible.verse_search.verses ("KJV", 1, 50)
			assert_true ("read in the KJV", l_found.is_success and then l_found.count = 1 and then l_found.item (1).verse = 3)
			assert_integers_equal ("every verse with the word, in order", 2, found_in (l_bible, "KJV", "the"))
			assert_integers_equal ("the page limit", 1, l_bible.verse_search.verses ("KJV", 1, 1).count)
			assert_integers_equal ("a phrase", 1, found_in (l_bible, "KJV", "%"the earth%""))
			assert_integers_equal ("any case", 1, found_in (l_bible, "KJV", "BEGINNING"))
			assert_integers_equal ("a prefix", 1, found_in (l_bible, "KJV", "begin*"))
			assert_integers_equal ("every word must be there", 0, found_in (l_bible, "KJV", "light beginning"))
			assert_integers_equal ("one version only", 0, found_in (l_bible, "WLC", "light"))
			assert_integers_equal ("pointed Hebrew from unpointed typing", 1, found_in (l_bible, "WLC", codes (<<0x05D5, 0x05D4, 0x05D0, 0x05E8, 0x05E5>>)))
			assert_false ("punctuation alone is refused, not searched", l_bible.query_parser.parsed ("?!", kjv_scope).is_valid)
			l_bible.close
			remove_test_files
		end

	test_verse_index_keeps_to_numbered_verses
			-- Scan 47: a heading row (verse 0) is not indexed, so the count and the list agree, and the
			-- build says how many rows it left out; a hostile query cannot break the expression; a
			-- quoted phrase can end in a prefix. Before: matching_count counted the heading (2) while
			-- verses_matching dropped it (1).
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_db.make (Bible_file)
			l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 3, 'And God said, Let there be light.'), (12, 1, 1, 0, 'The light of creation (a heading)')")
			l_db.close
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("numbered verses indexed", 5, l_builder.verses_indexed)
			assert_integers_equal ("the heading left out", 1, l_builder.verses_not_indexed)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_integers_equal ("one verse", 1, found_in (l_bible, "KJV", "light"))
			assert_integers_equal ("counted as listed", l_bible.verse_search.places.count, l_bible.verse_search.verses ("KJV", 1, 50).count)
			assert_integers_equal ("an index operator is only a word", 0, found_in (l_bible, "KJV", "NEAR light"))
			assert_integers_equal ("a phrase ending in a prefix", 1, found_in (l_bible, "KJV", "%"the ear%"*"))
			l_bible.close
			remove_test_files
		end

	test_boolean_and_root_word_search
			-- B02 and B03 end to end: Strong's numbers and lemmas from the concordance, words from the
			-- verse index, joined by AND, OR, NOT and parentheses, read in the KJV.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_db.make (Bible_file)
			l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 3, 'And God said, Let there be light.')")
			l_db.close
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			fixture.build (Pack_file)
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_integers_equal ("a root: bara in Genesis 1:1", 1, found (l_bible, "H1254"))
			assert_true ("Hebrew numbering told", l_bible.verse_search.has_hebrew_roots)
			assert_true ("read in the KJV", l_bible.verse_search.verses ("KJV", 1, 10).item (1).text.same_string ("In the beginning"))
			assert_integers_equal ("a root and a word", 1, found (l_bible, "strongs:H1254 AND beginning"))
			assert_integers_equal ("a root or a word", 2, found (l_bible, "H1254 OR light"))
			assert_integers_equal ("a word without another", 1, found (l_bible, "the NOT earth"))
			assert_integers_equal ("grouped", 1, found (l_bible, "(light OR earth) AND the"))
			assert_integers_equal ("a lemma by its plain letters", 1, found (l_bible, "lemma:bara"))
			assert_integers_equal ("a root the pack has no corpus for", 0, found (l_bible, "G3588"))
			assert_false ("no failure", l_bible.verse_search.has_failed)
			assert_integers_equal ("a root nowhere with a word", 0, found (l_bible, "H1254 AND light"))
			assert_integers_equal ("scoped to the Old Testament", 2, found_scoped (l_bible, "the", "OT"))
			assert_integers_equal ("scoped to the New Testament", 0, found_scoped (l_bible, "the", "NT"))
			assert_integers_equal ("scoped to a book", 2, found_scoped (l_bible, "the", "Genesis"))
			assert_integers_equal ("scoped to the Gospels", 0, found_scoped (l_bible, "the", "Gospels"))
			assert_true ("a name that is no scope", l_bible.search_scopes.scope_named ("Hezekiah", "KJV") = Void)
				-- B05: give the fixture's bara a Hebrew morphology code (the pack is attached read-only).
			create l_db.make (Pack_file)
			l_db.execute ("UPDATE token SET morph = 'Vqp3ms' WHERE token_id = 5")
			l_db.close
			assert_integers_equal ("a grammar code", 1, found (l_bible, "morph:Vqp3ms"))
			assert_integers_equal ("a grammar prefix", 1, found (l_bible, "morph:Vq*"))
			assert_integers_equal ("another stem", 0, found (l_bible, "morph:Vn*"))
			assert_integers_equal ("a code and a word", 1, found (l_bible, "morph:Vqp3ms AND beginning"))
			assert_true ("a Hebrew code is told as Hebrew numbering", found (l_bible, "morph:Vq*") = 1 and then l_bible.verse_search.has_hebrew_roots)
			assert_integers_equal ("a root in that form", 1, found (l_bible, "H1254@Vqp3ms"))
			assert_integers_equal ("a root in a form it never takes", 0, found (l_bible, "H1254@Vn*"))
			assert_integers_equal ("a root in a family of forms", 1, found (l_bible, "H1254@Vq*"))
			assert_integers_equal ("a form by lemma letters", 1, found (l_bible, "lemma:bara@Vq*"))
			l_bible.close
			remove_test_files
		end

	test_morph_codes_search_both_corpora
			-- Scan 49: a grammar code is looked for in both corpora (no Greek code equals a Hebrew one),
			-- so morph:V* finds Greek and Hebrew verbs alike. Before: a starred capital was guessed
			-- Hebrew, and a Greek reader got Hebrew verbs only, with no word said.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			fixture.build (Pack_file)
			create l_db.make (Pack_file)
			l_db.execute ("INSERT INTO corpus(corpus_id, code, name, language, license, ship_class, lemma_basis) VALUES (2, 'NT-MACULA', 'Greek New Testament', 'grc', 'CC BY 4.0', 'attribution', 'tagged: MACULA Greek lemma')")
			l_db.execute ("INSERT INTO work(work_id, code, name) VALUES (40, 'MAT', 'Matthew')")
			l_db.execute ("INSERT INTO work_book(work_id, book_id) VALUES (40, 40)")
			l_db.execute ("INSERT INTO unit(unit_id, corpus_id, work_id, div1, div2, seq) VALUES (900, 2, 40, '1', '1', 1)")
			l_db.execute ("INSERT INTO token(token_id, corpus_id, unit_id, pos, surface, search, language, lemma_id, lemma_basis, translit, morph) VALUES (9000, 2, 900, 1, 'EGENNHSEN', 'egennhsen', 'grc', NULL, 'none', 'egennesen', 'V-AAI-3S')")
			l_db.execute ("UPDATE token SET morph = 'Vqp3ms' WHERE token_id = 5")
			l_db.close
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			assert_true ("opens", l_bible.is_open and l_bible.conc_pack.is_available)
			assert_integers_equal ("a starred capital: Greek and Hebrew verbs", 2, found (l_bible, "morph:V*"))
			assert_true ("both told", l_bible.verse_search.has_greek_roots and l_bible.verse_search.has_hebrew_roots)
			assert_integers_equal ("a Greek code", 1, found (l_bible, "morph:V-AAI*"))
			assert_true ("Greek only", l_bible.verse_search.has_greek_roots and not l_bible.verse_search.has_hebrew_roots)
			assert_integers_equal ("a Hebrew code", 1, found (l_bible, "morph:Vq*"))
			assert_true ("Hebrew only", l_bible.verse_search.has_hebrew_roots and not l_bible.verse_search.has_greek_roots)
				-- 2026-10-30: an "attribution" corpus is shared with its credit; only restricted, personal,
				-- unknown and to-verify classes are not (0.7.37 marked everything but "open")
			assert_true ("an attribution corpus is shared", l_bible.credits.has_substring ("- Greek New Testament (CC BY 4.0)%N"))
			assert_false ("and never marked not to be shared", l_bible.credits.has_substring ("Greek New Testament (CC BY 4.0; not to be shared)"))
			l_bible.close
			remove_test_files
		end

	test_versification_map_moves_hebrew_roots
			-- The versification map (STEPBible TVTMS, D-005): bible_build reads the Hebrew rows that move
			-- a verse, the map answers English places, and a Hebrew root read in the KJV stands at its
			-- English number (Malachi 3:19 is 4:1), in the Hebrew text at its own.
		local
			l_builder: BIB_CONTENT_BUILDER
			l_config: BIB_CONFIG
			l_bible: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
			l_keys: BIB_VERSE_KEY
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			assert_true ("TVTMS fixture written", (create {SIMPLE_FILE}.make (Tvtms_file)).write_text_utf_8 ("TVTMS test%N#DataStart(Expanded)%NSourceType%TSourceRef%TStandardRef%TAction%N"
				+ "Hebrew%TMal.3:19%TMal.4:1%TRenumber verse%Tx%N"
				+ "Hebrew+Latin%TPsa.3:2%TPsa.3:1%TRenumber verse%Tx%N"
				+ "Hebrew%TPsa.3:1%TPsa.3:Title%TRenumber title%Tx%N"
				+ "Hebrew%T1Sa.21:1%T1Sa.20:42!b%TDividedPrev verse%Tx%N"
				+ "Hebrew%TGen.1:1%TGen.1:1%TKeep verse%Tx%N"
				+ "Eng-KJV+Latin%TMal.4:1%TMal.4:1%TKeep verse%Tx%N"
				+ "Hebrew%TNum.25:19; 26:1%TNum.26:1%TConcatenation%Tx%N"
				+ "Greek%TMal.3:22%TMal.4:4%TRenumber verse%Tx%N#DataEnd(Expanded)%N"))
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.set_tvtms_path (Tvtms_file)
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
				-- Malachi, the Psalm's verse 2 and the divided verse; the Psalm title (Hebrew 3:1) is read
				-- as verse 1, where English Bibles print it, so it moves nowhere and needs no row.
			assert_integers_equal ("the Hebrew rows that move a verse", 3, l_builder.versification_rows_written)
			fixture.build (Pack_file)
			create l_db.make (Pack_file)
			l_db.execute ("INSERT INTO work(work_id, code, name) VALUES (39, 'MAL', 'Malachi')")
			l_db.execute ("INSERT INTO work_book(work_id, book_id) VALUES (39, 39)")
			l_db.execute ("INSERT INTO unit(unit_id, corpus_id, work_id, div1, div2, seq) VALUES (901, 1, 39, '3', '19', 1)")
			l_db.execute ("INSERT INTO token(token_id, corpus_id, unit_id, pos, surface, search, language, lemma_id, lemma_basis, translit) VALUES (9001, 1, 901, 1, 'BRA', 'bra', 'hbo', 1, 'tagged:MACULA-Hebrew', 'bara')")
			l_db.close
			create l_config.make_with_core (Out_file)
			l_config := l_config.set_conc_path (Pack_file)
			create l_bible.make (l_config)
			l_bible.open
			create l_keys
			assert_true ("a map", l_bible.versification.has_hebrew_map)
			assert_true ("Malachi 3:19 is 4:1", l_bible.versification.english_place (l_keys.packed_place (39, 3, 19)) = l_keys.packed_place (39, 4, 1))
			assert_true ("a Psalm's verse 2 is its verse 1", l_bible.versification.english_place (l_keys.packed_place (19, 3, 2)) = l_keys.packed_place (19, 3, 1))
			assert_true ("a divided verse to its first", l_bible.versification.english_place (l_keys.packed_place (9, 21, 1)) = l_keys.packed_place (9, 20, 42))
			assert_true ("an unmoved verse stays", l_bible.versification.english_place (l_keys.packed_place (1, 1, 1)) = l_keys.packed_place (1, 1, 1))
			assert_integers_equal ("bara twice", 2, found (l_bible, "H1254"))
			assert_true ("read in the KJV: Malachi 4:1", l_bible.verse_search.places.has (l_keys.packed_place (39, 4, 1)) and not l_bible.verse_search.places.has (l_keys.packed_place (39, 3, 19)))
			assert_true ("told as moved", l_bible.verse_search.has_moved_hebrew_roots and not l_bible.verse_search.has_hebrew_roots)
			assert_integers_equal ("bara twice in the Hebrew text", 2, found_in (l_bible, "WLC", "H1254"))
			assert_true ("read in the Hebrew text: Malachi 3:19", l_bible.verse_search.places.has (l_keys.packed_place (39, 3, 19)))
			l_bible.close
			remove_test_files
		end

	found (a_bible: SIMPLE_BIBLE; a_query: STRING_8): INTEGER
			-- How many verses `a_query' names in the KJV.
		do
			Result := found_in (a_bible, "KJV", a_query)
		end

	found_in (a_bible: SIMPLE_BIBLE; a_version: STRING_8; a_query: READABLE_STRING_GENERAL): INTEGER
			-- How many verses `a_query' names in `a_version' (the one search path).
		local
			l_query: BIB_QUERY
		do
			l_query := a_bible.query_parser.parsed (a_query, kjv_scope)
			assert_true ({STRING_32} "valid: " + a_query.to_string_32, l_query.is_valid)
			a_bible.verse_search.find (l_query, a_version)
			assert_false ("no failure", a_bible.verse_search.has_failed)
			Result := a_bible.verse_search.places.count
		end

	found_scoped (a_bible: SIMPLE_BIBLE; a_query, a_scope: STRING_8): INTEGER
			-- How many verses `a_query' names in the KJV within the scope named `a_scope'.
		local
			l_query: BIB_QUERY
		do
			if attached a_bible.search_scopes.scope_named (a_scope, "KJV") as al_scope then
				l_query := a_bible.query_parser.parsed (a_query, al_scope)
				assert_true ({STRING_8} "valid: " + a_query, l_query.is_valid)
				a_bible.verse_search.find (l_query, "KJV")
				Result := a_bible.verse_search.places.count
			else
				assert_true ({STRING_8} "a scope: " + a_scope, False)
			end
		end

	kjv_scope: BIB_SEARCH_SCOPE
			-- Every book.
		once
			create Result.make ("verses", <<"KJV">>, 1, 66, "verses")
		end

	test_versification_build_reports_what_it_drops
			-- Scan 53: a TVTMS file without its expanded section fails the build; a Hebrew row naming a
			-- book outside the Hebrew Bible, or a Hebrew verse already mapped, is counted, never silent;
			-- TVTMS's book codes reach the right books. Before: the empty file built with 0 rows and no
			-- word, and drops were not counted.
		local
			l_builder: BIB_CONTENT_BUILDER
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			assert_true ("no expanded section", (create {SIMPLE_FILE}.make (Tvtms_file)).write_text_utf_8 ("TVTMS without its data%N#DataStart(Condensed)%N#DataEnd(Condensed)%N"))
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.set_tvtms_path (Tvtms_file)
			l_builder.build (Bible_file, Out_file)
			assert_true ("refused", attached l_builder.last_error as al_error and then al_error.has_substring ("expanded"))
			assert_true ("TVTMS rows", (create {SIMPLE_FILE}.make (Tvtms_file)).write_text_utf_8 ("TVTMS%N#DataStart(Expanded)%NSourceType%TSourceRef%TStandardRef%TAction%N"
				+ "Hebrew%TJol.3:1%TJol.2:28%TRenumber verse%Tx%N"
				+ "Hebrew%TJol.3:1%TJol.2:29%TRenumber verse%Tx%N"
				+ "Hebrew%TEsg.1:1%TEst.1:1%TRenumber verse%Tx%N"
				+ "Hebrew%TSng.7:1%TSng.6:13%TRenumber verse%Tx%N#DataEnd(Expanded)%N"))
			create l_builder.make
			l_builder.set_build_id ("test-build")
			l_builder.set_tvtms_path (Tvtms_file)
			l_builder.build (Bible_file, Out_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_integers_equal ("Joel and the Song of Songs", 2, l_builder.versification_rows_written)
			assert_integers_equal ("a verse mapped twice: the first kept, the second counted", 1, l_builder.versification_rows_repeated)
			assert_integers_equal ("a book outside the Hebrew Bible counted", 1, l_builder.versification_rows_unplaced)
			remove_test_files
		end

	test_rebuild_is_byte_identical
			-- Two builds from the same inputs, build id and build time are the same bytes (FR-130's direction).
		local
			l_builder: BIB_CONTENT_BUILDER
			l_first, l_second: ARRAY [NATURAL_8]
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			create l_builder.make
			l_builder.set_built_at ("2026-10-26T12:00:00Z")
			l_builder.build (Bible_file, Out_file)
			l_first := (create {SIMPLE_FILE}.make (Out_file)).read_bytes
			l_builder.build (Bible_file, Out_file)
			l_second := (create {SIMPLE_FILE}.make (Out_file)).read_bytes
			assert_true ("not empty", l_first.count > 0)
			assert_true ("same bytes", l_first ~ l_second)
			remove_test_files
		end

	test_missing_bible_is_reported
			-- No bible.db: a reason, and no content.db written.
		local
			l_builder: BIB_CONTENT_BUILDER
		do
			remove_test_files
			create l_builder.make
			l_builder.build (Bible_file, Out_file)
			assert_true ("reported", l_builder.last_error /= Void)
			assert_false ("nothing written", (create {SIMPLE_FILE}.make (Out_file)).exists)
		end

	test_failed_build_leaves_nothing_behind
			-- A bible.db without its book list: a reason, no content.db, no temporary file.
		local
			l_builder: BIB_CONTENT_BUILDER
		do
			remove_test_files
			make_bible_db (Bible_file, False)
			create l_builder.make
			l_builder.build (Bible_file, Out_file)
			assert_true ("reported", attached l_builder.last_error as al_e and then al_e.has_substring ("bible_books"))
			assert_false ("no content.db", (create {SIMPLE_FILE}.make (Out_file)).exists)
			assert_false ("no temporary file", (create {SIMPLE_FILE}.make (Out_file + ".tmp")).exists)
			remove_test_files
		end

	test_failed_move_leaves_no_temporary_file
			-- When the built file cannot be moved into place (here the output names a folder), the
			-- reason is given and the temporary file is gone (design scan 31: it leaked).
		local
			l_builder: BIB_CONTENT_BUILDER
			l_ok: BOOLEAN
		do
			remove_test_files
			make_bible_db (Bible_file, True)
			l_ok := (create {SIMPLE_FILE}.make (Folder_out)).create_directory
			create l_builder.make
			l_builder.build (Bible_file, Folder_out)
			assert_true ("reported", l_builder.last_error /= Void)
			assert_false ("no temporary file", (create {SIMPLE_FILE}.make (Folder_out + ".tmp")).exists)
			l_ok := (create {SIMPLE_FILE}.make (Folder_out)).delete_directory
			remove_test_files
		end

feature {NONE} -- Fixture

	Folder_out: STRING = "builder_test_out_folder"

	Bible_file: STRING = "builder_test_bible.db"
	Out_file: STRING = "builder_test_content.db"
	Pack_file: STRING = "builder_test_pack.db"
	Tvtms_file: STRING = "builder_test_tvtms.txt"

	fixture: CONC_FIXTURE
			-- The shared test-file helpers.
		once
			create Result
		end

	make_bible_db (a_path: STRING; a_with_books: BOOLEAN)
			-- A small bible.db: the vault's `bible_books' shape with three books, or none at all.
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			fixture.delete_file (a_path)
			create l_db.make (a_path)
			if a_with_books then
				l_db.execute ("CREATE TABLE bible_books(id INTEGER PRIMARY KEY, name TEXT, abbreviation TEXT, testament INTEGER)")
				l_db.execute ("INSERT INTO bible_books VALUES (1, 'Genesis', 'Gen', 0), (2, 'Exodus', 'Exod', 0), (40, 'Matthew', 'Matt', 1)")
				l_db.execute ("CREATE TABLE bible_versions(id INTEGER PRIMARY KEY, abbreviation TEXT, name TEXT, license TEXT, caveat TEXT)")
				l_db.execute ("INSERT INTO bible_versions VALUES (12, 'KJV', 'KJV', 'MIT', ''), (16, 'WLC', 'WLC', 'MIT', 'HEBREW versification'), (31, 'NWT2013', 'New World Translation', 'personal_only (see source_provenance)', ''), (36, 'TgO', 'TgO', 'MIT', ''), (39, 'SP', 'SP', 'MIT', '')")
				l_db.execute ("CREATE TABLE source_provenance(id INTEGER PRIMARY KEY, target TEXT, kind TEXT, license TEXT, attribution TEXT, ship_class TEXT, ship_note TEXT)")
				l_db.execute ("INSERT INTO source_provenance VALUES (31, 'KJV', 'version', 'Public Domain (text); CrossWire tagging is GPL', 'King James Version (1769), public domain.', 'open', 'Public Domain text'), (1, 'WLC', 'version', 'CC BY 4.0', 'Westminster Leningrad Codex, via OpenScriptures morphhb', 'attribution', 'CC BY 4.0 (morphhb)'), (46, 'NWT2013', 'version', 'jw.org Terms of Use: personal, non-commercial use only', 'New World Translation of the Holy Scriptures. Copyright Watch Tower', 'personal_only', 'jw.org terms forbid distribution'), (36, 'TgO', 'version', 'CC BY-NC', 'Targum Onkelos, via Sefaria', 'restricted_nc', 'CC BY-NC (Sefaria / Metsudah 2009)')")
				l_db.execute ("CREATE TABLE cross_references(id INTEGER PRIMARY KEY, from_book_id INTEGER, from_chapter INTEGER, from_verse INTEGER, to_book_id INTEGER, to_chapter INTEGER, to_verse_start INTEGER, to_verse_end INTEGER, votes INTEGER, source TEXT)")
				l_db.execute ("INSERT INTO cross_references (from_book_id, from_chapter, from_verse, to_book_id, to_chapter, to_verse_start, to_verse_end, votes, source) VALUES (1, 1, 1, 40, 1, 1, NULL, 5, 'openbible'), (1, 1, 1, 99, 1, 1, 1, 9, 'openbible')")
				l_db.execute ("CREATE TABLE bible_verses(id INTEGER PRIMARY KEY, version_id INTEGER, book_id INTEGER, chapter INTEGER, verse INTEGER, text TEXT)")
				l_db.execute ("INSERT INTO bible_verses (version_id, book_id, chapter, verse, text) VALUES (12, 1, 1, 1, 'In the beginning'), (12, 1, 1, 2, 'And the earth'), (16, 1, 1, 1, 'BRASYT'), (31, 40, 1, 1, 'The book')")
			else
				l_db.execute ("CREATE TABLE other(id INTEGER)")
			end
			l_db.close
		end

	codes (a_codes: ARRAY [INTEGER]): STRING_32
			-- Text from code points (the sources stay ASCII).
		do
			create Result.make (a_codes.count)
			across a_codes as ic loop
				Result.append_character (ic.to_character_32)
			end
		end

	remove_test_files
			-- Delete every file these tests write.
		do
			fixture.delete_file (Bible_file)
			fixture.delete_file (Out_file)
			fixture.delete_file (Out_file + ".tmp")
			fixture.delete_file (Pack_file)
			fixture.delete_file (Tvtms_file)
			fixture.delete_file (Folder_out + ".tmp")
		end

end
