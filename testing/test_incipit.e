note
	description: "[
		The incipit pack (research 26 and 27, 2026-11-11): its schema makes
		every table on a new file, and the closed lists its columns take refuse
		a word that is not on them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_INCIPIT

inherit
	TEST_SET_BASE

feature -- The schema

	test_incipit_schema_makes_every_table
			-- Every statement runs on a new file, and every table the schema names is there.
		local
			l_schema: BIB_INCIPIT_SCHEMA
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_file
			create l_schema
			create l_db.make (Schema_file)
			across l_schema.schema_statements as ic loop
				l_db.execute (ic)
				assert_false ("ran: " + ic, l_db.has_error)
			end
			across l_schema.Table_names as ic loop
				assert_integers_equal ("table " + ic, 1, l_db.run_query ("SELECT name FROM sqlite_master WHERE type = 'table' AND name = '" + ic + "'").count)
			end
			assert_integers_equal ("version 1", 1, l_db.run_query ("PRAGMA user_version").first.integer_value ("user_version"))
			l_db.close
			remove_file
		end

	test_incipit_schema_refuses_a_word_off_its_lists
			-- A declared kind is taken and an undeclared one refused; a link with a loudness off
			-- the list is refused; a scene story must name its scene.
		local
			l_schema: BIB_INCIPIT_SCHEMA
			l_db: SIMPLE_SQL_DATABASE
		do
			remove_file
			create l_schema
			create l_db.make (Schema_file)
			across l_schema.schema_statements as ic loop
				l_db.execute (ic)
			end
			l_db.execute ("INSERT INTO link_kind VALUES ('incipit', 'incipit', 'opening words that name the whole passage', 'the words are not the opening', 'solid', 'author', 1)")
			assert_false ("a declared kind taken", l_db.has_error)
			l_db.execute ("INSERT INTO link_kind VALUES ('hint', 'hint', 'x', 'y', 'solid', 'author', 1)")
			assert_true ("an undeclared kind refused", l_db.has_error)
			l_db.execute ("INSERT INTO source_provenance VALUES (1, 'ubs', 'v1', 'CC BY-SA 4.0', 0, 1, 0, 'UBS', '')")
			l_db.execute ("INSERT INTO source_unit VALUES (1, 'PSA', 21, 1, 21, 32, 'Psalm 22', 'Psalm 22', 'My God, my God', 'hebrew_canon', 1, 'trusted')")
			assert_false ("a source unit taken", l_db.has_error)
			l_db.execute ("INSERT INTO incipit_link VALUES (1, 'MAT', 27, 46, 46, 'PSA', 21, 2, 2, 1, 'incipit', 50.0, 'loud', 'both', NULL, 19, 22, 1, 1, 'trusted')")
			assert_false ("a loud link taken", l_db.has_error)
			l_db.execute ("INSERT INTO incipit_link VALUES (2, 'MRK', 15, 34, 34, 'PSA', 21, 2, 2, 1, 'incipit', 50.0, 'deafening', 'both', NULL, NULL, NULL, NULL, 1, 'trusted')")
			assert_true ("a loudness off the list refused", l_db.has_error)
			l_db.execute ("INSERT INTO story VALUES (1, 1, NULL, 'scene', 'Matthew 27', 'Incipit/Psalm 22/01 - Matthew 27.md', 'author', 1)")
			assert_true ("a scene story without its scene refused", l_db.has_error)
			l_db.close
			remove_file
		end

	test_incipit_schema_vocabulary
			-- The queries answer from the same lists the constraints are built from.
		local
			l_schema: BIB_INCIPIT_SCHEMA
		do
			create l_schema
			assert_true ("allusion is a kind", l_schema.is_kind ("allusion"))
			assert_false ("hint is not a kind", l_schema.is_kind ("hint"))
			assert_true ("theme is a loudness", l_schema.is_loudness ("theme"))
			assert_true ("claude_take is a status", l_schema.is_section_status ("claude_take"))
			assert_true ("share-alike", l_schema.pack_license.is_share_alike)
		end

feature -- The builder and the reader

	test_incipit_pack_builds_attaches_and_reads
			-- Three links into Psalm 21 (LXX numbering): built, attached by SIMPLE_BIBLE, read
			-- from both ends (Matthew 27:46 makes the incipit; Psalm 21:19 receives Mark 15:24),
			-- credited to UBS under CC BY-SA 4.0 and to Huehn as public domain.
		local
			l_builder: BIB_INCIPIT_BUILDER
			l_bible: SIMPLE_BIBLE
			l_ok: BOOLEAN
		do
			prepare
			l_ok := (create {SIMPLE_FILE}.make (Manifest_file)).write_text_utf_8 (Good_manifest)
			create l_builder.make
			l_builder.build (Manifest_file, Pack_file)
			assert_true ("built: " + (if attached l_builder.last_error as al_e then al_e.to_string_8 else "" end), l_builder.last_error = Void)
			assert_integers_equal ("three links", 3, l_builder.link_count)
			assert_integers_equal ("one unit", 1, l_builder.unit_count)
			assert_integers_equal ("four witnesses", 4, l_builder.witness_count)
			assert_integers_equal ("two kinds", 2, l_builder.kind_count)
			l_bible := bible
			l_bible.open
			assert_true ("open with the pack", l_bible.is_open and l_bible.pack_errors.is_empty)
			assert_integers_equal ("one incipit pack", 1, l_bible.incipit_packs.count)
			if attached l_bible.incipit_packs.first as al_pack then
				assert_integers_equal ("three links read", 3, al_pack.link_count)
				assert_integers_equal ("Matthew 27:46 makes one link", 1, al_pack.links_from ("MAT", 27, 46).count)
				if attached al_pack.links_from ("MAT", 27, 46).first as al_link then
					assert_strings_equal ("an incipit", "incipit", al_link.kind)
					assert_strings_equal ("into Psalm 22", "Psalm 22", al_link.unit_title)
					assert_integers_equal ("LXX verse 2", 2, al_link.lxx_v)
					assert_true ("named by UBS and Huehn: " + al_link.witnesses.to_string_8, al_link.witnesses.has_substring ("ubs") and al_link.witnesses.has_substring ("huhn*"))
				end
				assert_integers_equal ("Psalm 21:19 receives one link", 1, al_pack.links_into ("PSA", 21, 19).count)
				assert_strings_equal ("from Mark 15:24", "MRK", al_pack.links_into ("PSA", 21, 19).first.nt_book)
				assert_true ("Romans 3:14 makes none", al_pack.links_from ("ROM", 3, 14).is_empty)
				assert_integers_equal ("English Psalm 22:18 receives one link", 1, al_pack.links_into_english (19, 22, 18).count)
				assert_integers_equal ("English Psalm 22:1 receives the cry", 1, al_pack.links_into_english (19, 22, 1).count)
				assert_integers_equal ("its English verse kept", 1, al_pack.links_from ("MAT", 27, 46).first.en_v)
				assert_integers_equal ("Matthew 27:43 has no English place", 0, al_pack.links_from ("MAT", 27, 43).first.en_book_id)
				assert_integers_equal ("every link listed", 3, al_pack.all_links (False).count)
				assert_integers_equal ("New Testament order: Matthew 27:43 first", 43, al_pack.all_links (False).first.nt_v)
				assert_strings_equal ("New Testament order: Mark last", "MRK", al_pack.all_links (False).last.nt_book)
				assert_integers_equal ("Old Testament order: Psalm 22:1 first", 1, al_pack.all_links (True).first.en_v)
				assert_integers_equal ("Old Testament order: no English place last", 0, al_pack.all_links (True).last.en_book_id)
			end
			l_bible.close
			assert_true ("credited to UBS, CC BY-SA 4.0", provenance_has ({BIB_INCIPIT_SCHEMA}.Ubs_source_name, "CC BY-SA 4.0"))
			assert_true ("Huehn is public domain", provenance_has ({STRING_32} "H%/252/hn 1899", "public domain"))
			cleanup
		end

	test_incipit_builder_refuses_a_broken_manifest
			-- An undeclared kind, a verse past its unit, a witness with no provenance yet, chance
			-- lines out of order, a pair given twice: each refuses the build by name.
		do
			refuses ("%"kind%": %"allusion%", %"loudness%": %"quiet%"", "%"kind%": %"hint%", %"loudness%": %"quiet%"", "undeclared kind")
			refuses ("%"lxx%": %"PSA 21:19%"", "%"lxx%": %"PSA 21:99%"", "past the end of its unit")
			refuses ("{%"witness%": %"huhn%", %"detail%": %"%"}", "{%"witness%": %"dittmar%", %"detail%": %"%"}", "no provenance in version 1")
			refuses ("%"chance_99%": 37.3", "%"chance_99%": 30.0", "do not run upward")
			refuses ("%"book_id%": 19, %"ch%": 22, %"v%": 18", "%"book_id%": 70, %"ch%": 22, %"v%": 18", "not a book 1 to 66")
			refuses ("%"nt%": %"MAT 27:43%", %"lxx%": %"PSA 21:9%"", "%"nt%": %"MAT 27:46%", %"lxx%": %"PSA 21:2%"", "given twice")
		end

feature {NONE} -- Helpers

	refuses (a_old, a_new, a_reason: STRING)
			-- The good manifest with `a_old' made `a_new' refuses the build with `a_reason'.
		local
			l_builder: BIB_INCIPIT_BUILDER
			l_manifest: STRING
			l_ok: BOOLEAN
		do
			prepare
			l_manifest := Good_manifest.twin
			assert_true ("the change applies: " + a_old, l_manifest.has_substring (a_old))
			l_manifest.replace_substring_all (a_old, a_new)
			l_ok := (create {SIMPLE_FILE}.make (Manifest_file)).write_text_utf_8 (l_manifest)
			create l_builder.make
			l_builder.build (Manifest_file, Pack_file)
			assert_true ("refused for " + a_reason + ": " + (if attached l_builder.last_error as al_e then al_e.to_string_8 else "built" end),
				attached l_builder.last_error as al_e and then al_e.has_substring (a_reason))
			cleanup
		end

	provenance_has (a_source, a_license: READABLE_STRING_GENERAL): BOOLEAN
			-- Has the pack a provenance row for `a_source' under `a_license'?
		local
			l_db: SIMPLE_SQL_DATABASE
			l_rows: SIMPLE_SQL_RESULT
		do
			create l_db.make (Pack_file)
			l_rows := l_db.query_with_args ("SELECT COUNT(*) AS n FROM source_provenance WHERE source_key = ? AND license_id = ?", <<a_source.to_string_32, a_license.to_string_32>>)
			if not l_rows.rows.is_empty then
				Result := l_rows.rows.first.integer_value ("n") > 0
			end
			l_db.close
		end

	prepare
		local
			l_ok: BOOLEAN
		do
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			if not (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).create_directory
			end
			fixture.delete_file (Pack_file)
		end

	cleanup
		local
			l_ok: BOOLEAN
			l_memory: MEMORY
		do
				-- SQLite lets go of a file when its last statement is collected.
			create l_memory
			l_memory.full_collect
			fixture.delete_file (Pack_file)
			fixture.delete_file (Manifest_file)
			fixture.delete_file (Content_file)
			l_ok := (create {SIMPLE_FILE}.make (Folder)).delete_directory
		end

	bible: SIMPLE_BIBLE
		local
			l_config: BIB_CONFIG
		do
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_pack_folder (Folder)
			create Result.make (l_config)
		end

	fixture: CONC_FIXTURE
		once
			create Result
		end

	Content_file: STRING = "incipit_test_content.db"
	Folder: STRING = "incipit_test_packs"
	Pack_file: STRING = "incipit_test_packs\incipit.db"
	Manifest_file: STRING = "incipit_test.links.json"

	Good_manifest: STRING = "[
{"schema": "incipit.links/1",
 "kinds": [
  {"kind": "incipit", "label": "incipit", "mark_style": "solid", "definition_formal": "a psalm's opening line, listed as a quotation", "could_fail_if": "not the opening line"},
  {"kind": "allusion", "label": "allusion", "mark_style": "dotted", "definition_formal": "named by a list without a quotation mark", "could_fail_if": "a stock phrase"}],
 "units": [
  {"lxx_book": "PSA", "lxx_ch": 21, "lxx_v_to": 32, "hebrew_ref": "Psalm 22", "english_ref": "Psalm 22", "title": "Psalm 22", "book_class": "hebrew_canon"}],
 "measure_run": {"measure_version": "v0.3", "run_on": "2026-11-11", "nt_edition": "WH1881", "lxx_edition": "Rahlfs 1935", "candidates": 5977545,
  "chance_95": 33.3, "chance_99": 37.3, "chance_999": 42.2, "method": "test"},
 "links": [
  {"nt": "MAT 27:46", "lxx": "PSA 21:2", "kind": "incipit", "loudness": "loud", "volume": 43.14, "follows": "unknown", "book_class": "hebrew_canon", "english": {"book_id": 19, "ch": 22, "v": 1},
   "witnesses": [{"witness": "ubs", "detail": ""}, {"witness": "huhn", "detail": "*"}], "features": {"align": 14.2, "lex": 20.1}},
  {"nt": "MRK 15:24", "lxx": "PSA 21:19", "kind": "allusion", "loudness": "loud", "volume": 58.64, "follows": "unknown", "book_class": "hebrew_canon", "english": {"book_id": 19, "ch": 22, "v": 18},
   "witnesses": [{"witness": "huhn", "detail": ""}], "features": {"align": 22.0}},
  {"nt": "MAT 27:43", "lxx": "PSA 21:9", "kind": "allusion", "loudness": "quiet", "volume": 32.25, "follows": "unknown", "book_class": "hebrew_canon",
   "witnesses": [{"witness": "measure", "detail": ""}], "features": {}}]}
]"

	Schema_file: STRING = "incipit_schema_test.db"

	remove_file
			-- Delete `Schema_file' when it is there.
		local
			l_file: SIMPLE_FILE
			l_gone: BOOLEAN
		do
			create l_file.make (Schema_file)
			if l_file.exists then
				l_gone := l_file.delete
			end
		end

end
