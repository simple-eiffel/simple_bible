note
	description: "[
		The chiasm pack (research 28, 2026-11-11): its schema makes every table,
		the builder writes Bullinger's flood structure and one nested level, the
		reader finds them innermost first with their pairs, and a broken manifest
		is refused by name.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CHIASM

inherit
	TEST_SET_BASE

feature -- Tests

	test_chiasm_schema_makes_every_table
			-- Every statement runs on a new file, and every table the schema names is there.
		local
			l_schema: BIB_CHIASM_SCHEMA
			l_db: SIMPLE_SQL_DATABASE
		do
			fixture.delete_file (Schema_file)
			create l_schema
			create l_db.make (Schema_file)
			across l_schema.schema_statements as ic loop
				l_db.execute (ic)
				assert_false ("ran: " + ic, l_db.has_error)
			end
			across l_schema.Table_names as ic loop
				assert_integers_equal ("table " + ic, 1, l_db.run_query ("SELECT name FROM sqlite_master WHERE type = 'table' AND name = '" + ic + "'").count)
			end
			l_db.execute ("INSERT INTO source_provenance VALUES (1, 'b', 'v', 'public domain', 0, 0, 0, 'B', '')")
			l_db.execute ("INSERT INTO structure VALUES (1, NULL, '', 1, 6, 9, 9, 29, 'Noah', 'Introversion', 'chiasm', 'bullinger', 'strong', NULL, NULL, NULL, 0, 'hold loosely (datum only)', 1)")
			assert_true ("an unknown pattern refused", l_db.has_error)
			l_db.execute ("INSERT INTO structure VALUES (2, NULL, '', 19, 8, 1, 8, 9, 'Psalm 8', 'Larry (settled)', 'inclusio', 'larry', 'strong', NULL, NULL, NULL, 0, 'author', 1)")
			assert_false ("a frame (inclusio) from Larry taken in the author's voice", l_db.has_error)
			l_db.close
			fixture.delete_file (Schema_file)
		end

	test_chiasm_pack_builds_attaches_and_reads
			-- Noah (Genesis 6:9-9:29, A-E E-A) and a nested level under E: built, attached, read.
		local
			l_builder: BIB_CHIASM_BUILDER
			l_bible: SIMPLE_BIBLE
			l_ok: BOOLEAN
		do
			prepare
			l_ok := (create {SIMPLE_FILE}.make (Manifest_file)).write_text_utf_8 (Good_manifest)
			create l_builder.make
			l_builder.build (Manifest_file, Pack_file)
			assert_true ("built: " + (if attached l_builder.last_error as al_e then al_e.to_string_8 else "" end), l_builder.last_error = Void)
			assert_integers_equal ("two structures", 2, l_builder.structure_count)
			assert_integers_equal ("twelve members", 12, l_builder.member_count)
			assert_integers_equal ("one graded", 1, l_builder.graded_count)
			l_bible := bible
			l_bible.open
			assert_true ("open with the pack", l_bible.is_open and l_bible.pack_errors.is_empty)
			assert_integers_equal ("one chiasm pack", 1, l_bible.chiasm_packs.count)
			if attached l_bible.chiasm_packs.first as al_pack then
				assert_integers_equal ("two structures read", 2, al_pack.structure_count)
				assert_integers_equal ("Genesis 7:5 lies in both", 2, al_pack.structures_at (1, 7, 5).count)
				assert_strings_equal ("the nested level first", "E", al_pack.structures_at (1, 7, 5).first.under_letter)
				assert_integers_equal ("Genesis 9:28 lies in one", 1, al_pack.structures_at (1, 9, 28).count)
				assert_strings_equal ("graded strong", "strong", al_pack.structures_at (1, 9, 28).first.grade)
				assert_true ("Genesis 10:1 lies in none", al_pack.structures_at (1, 10, 1).is_empty)
				if attached al_pack.members_of (al_pack.structures_at (1, 9, 28).first.structure_id) as al_m then
					assert_integers_equal ("ten members", 10, al_m.count)
					assert_integers_equal ("A pairs with the last A", 10, al_m.first.pair_seq)
					assert_integers_equal ("B reads 6:10", 10, al_m [2].v_from)
				end
			end
			l_bible.close
			cleanup
		end

	test_chiasm_builder_refuses_a_broken_manifest
			-- An unknown pattern, a member outside its range, a parent not given before, a
			-- partner that does not name back: each refuses the build by name.
		do
			refuses ("%"pattern%": %"alternation%"", "%"pattern%": %"spiral%"", "unknown pattern")
			refuses ("%"from%": [9, 28], %"to%": [9, 29]", "%"from%": [9, 28], %"to%": [10, 3]", "outside its range")
			refuses ("%"parent_key%": %"b1%"", "%"parent_key%": %"b9%"", "not given before")
			refuses ("%"pair_seq%": 9", "%"pair_seq%": 8", "does not name it back")
		end

feature {NONE} -- Helpers

	refuses (a_old, a_new, a_reason: STRING)
			-- The good manifest with `a_old' made `a_new' refuses the build with `a_reason'.
		local
			l_builder: BIB_CHIASM_BUILDER
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

	Content_file: STRING = "chiasm_test_content.db"
	Folder: STRING = "chiasm_test_packs"
	Pack_file: STRING = "chiasm_test_packs\chiasm.db"
	Manifest_file: STRING = "chiasm_test.structures.json"
	Schema_file: STRING = "chiasm_schema_test.db"

	Good_manifest: STRING = "[
{"schema": "chiasm.structures/1", "structures": [
 {"key": "b1", "parent_key": null, "under_letter": "", "book_id": 1, "from": [6, 9], "to": [9, 29], "title": "THE GENERATIONS OF NOAH",
  "kind_printed": "Introversion", "pattern": "introversion", "source": "bullinger", "grade": "strong", "whole": 0.288, "p_shape": 0.006, "p_pairing": 0.009, "repaired": 1,
  "members": [
   {"letter": "A", "letter_inferred": false, "from": [6, 9], "to": [6, 9], "label": "Noah before the Flood.", "pair_seq": 10, "pair_score": 0.176, "repair": ""},
   {"letter": "B", "letter_inferred": false, "from": [6, 10], "to": [6, 10], "label": "Noah's Family.", "pair_seq": 9, "pair_score": 0.348, "repair": "order"},
   {"letter": "C", "letter_inferred": false, "from": [6, 11], "to": [6, 13], "label": "The Earth corrupt.", "pair_seq": 8, "pair_score": 0.275, "repair": ""},
   {"letter": "D", "letter_inferred": false, "from": [6, 14], "to": [6, 22], "label": "The making of the Ark.", "pair_seq": 7, "pair_score": 0.193, "repair": ""},
   {"letter": "E", "letter_inferred": false, "from": [7, 1], "to": [7, 24], "label": "Noah entering the Ark.", "pair_seq": 6, "pair_score": 0.447, "repair": ""},
   {"letter": "E", "letter_inferred": false, "from": [8, 1], "to": [8, 19], "label": "Noah leaving the Ark.", "pair_seq": 5, "pair_score": 0.447, "repair": ""},
   {"letter": "D", "letter_inferred": false, "from": [8, 20], "to": [8, 20], "label": "The building of the Altar.", "pair_seq": 4, "pair_score": 0.193, "repair": ""},
   {"letter": "C", "letter_inferred": false, "from": [8, 21], "to": [9, 17], "label": "The Earth replenished.", "pair_seq": 3, "pair_score": 0.275, "repair": ""},
   {"letter": "B", "letter_inferred": false, "from": [9, 18], "to": [9, 27], "label": "Noah's Family.", "pair_seq": 2, "pair_score": 0.348, "repair": ""},
   {"letter": "A", "letter_inferred": false, "from": [9, 28], "to": [9, 29], "label": "Noah after the Flood.", "pair_seq": 1, "pair_score": 0.176, "repair": ""}]},
 {"key": "b1-E", "parent_key": "b1", "under_letter": "E", "book_id": 1, "from": [7, 1], "to": [7, 24], "title": "NOAH ENTERING THE ARK",
  "kind_printed": "Alternation", "pattern": "alternation", "source": "bullinger", "grade": "not_graded", "whole": null, "p_shape": null, "p_pairing": null, "repaired": 0,
  "members": [
   {"letter": "a", "letter_inferred": false, "from": [7, 1], "to": [7, 12], "label": "The entering.", "pair_seq": null, "pair_score": null, "repair": ""},
   {"letter": "b", "letter_inferred": false, "from": [7, 13], "to": [7, 24], "label": "The waters.", "pair_seq": null, "pair_score": null, "repair": ""}]}]}
]"

end
