note
	description: "[
		SIMPLE_BIBLE.open for real (Phase 4, Task 7a): content.db v1 is checked
		(research/18) and required; the concordance pack attaches by `conc_path',
		and a missing or refused pack leaves the Bible open with the reason in
		`conc_error' (Larry, 2026-10-26). The databases are made here and deleted.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_FACADE_OPEN

inherit
	TEST_SET_BASE

feature -- Tests

	test_open_with_content_and_concordance
			-- content.db and the pack open; the lookups answer through the facade.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.build (Pack_file)
			l_bible := bible (Pack_file, "")
			l_bible.open
			assert_true ("open", l_bible.is_open and l_bible.last_error = Void)
			assert_strings_equal ("edition is the latest build", {CONC_FIXTURE}.Content_edition, l_bible.database_edition)
			assert_true ("concordance available", l_bible.conc_error = Void and l_bible.conc_pack.is_available)
			assert_true ("word view", l_bible.word_lookup.view ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS").is_success)
			assert_integers_equal ("english", 1, l_bible.english_index.rows ("created").count)
			assert_false ("no ai rows in v1", l_bible.has_ai_data)
			l_bible.close
			assert_false ("closed", l_bible.is_open)
			remove_test_files
		end

	test_open_without_a_concordance
			-- No `conc_path': the Bible opens and the concordance is simply absent.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			l_bible := bible ("", "")
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("no reason needed", l_bible.conc_error = Void)
			assert_false ("not available", l_bible.conc_pack.is_available)
			l_bible.close
			remove_test_files
		end

	test_missing_concordance_keeps_the_bible_open
			-- A `conc_path' with no file: open, with the reason (Larry's policy).
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.delete_file (Pack_file)
			l_bible := bible (Pack_file, "")
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("reason", attached l_bible.conc_error as al_e and then al_e.code = {BIB_ERROR}.Source_unavailable)
			l_bible.close
			remove_test_files
		end

	test_refused_concordance_keeps_the_bible_open
			-- A pack at another version: open, refused with the reason, and detached.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.build_variant (Pack_file, 0, "")
			l_bible := bible (Pack_file, "")
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("refused", attached l_bible.conc_error as al_e and then al_e.code = {BIB_ERROR}.Schema_mismatch)
			assert_false ("detached", l_bible.conc_pack.is_attached)
			l_bible.close
			remove_test_files
		end

	test_content_at_another_version_is_refused
			-- content.db is required: a wrong version leaves the engine closed with the reason.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, 0, False)
			l_bible := bible ("", "")
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("version named", attached l_bible.last_error as al_e and then al_e.code = {BIB_ERROR}.Schema_mismatch and then al_e.message.has_substring ("version 0"))
			remove_test_files
		end

	test_content_without_provenance_is_refused
			-- K7-A: a content table without a provenance column bound to source_provenance.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, True)
			l_bible := bible ("", "")
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("provenance named", attached l_bible.last_error as al_e and then al_e.message.has_substring ("provenance_key"))
			remove_test_files
		end

	test_missing_content_is_refused
			-- No content.db: the engine stays closed and says so.
		local
			l_bible: SIMPLE_BIBLE
		do
			fixture.delete_file (Content_file)
			l_bible := bible ("", "")
			l_bible.open
			assert_false ("not open", l_bible.is_open)
			assert_true ("named", attached l_bible.last_error as al_e and then al_e.code = {BIB_ERROR}.Source_unavailable)
		end

	test_pack_folder_scan_skips_the_concordance
			-- FR-166: conc.db inside the pack folder is found by `conc_path', not counted as a pack.
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			fixture.build (Folder_pack_file)
			l_bible := bible (Folder_pack_file, Folder)
			assert_integers_equal ("not a generic pack", 0, l_bible.pack_count)
			l_bible.open
			assert_true ("open with the concordance", l_bible.is_open and l_bible.conc_pack.is_available)
			l_bible.close
			remove_test_files
		end

	test_pack_folder_scan_compares_files_not_spellings
			-- FR-166 again, with the paths spelled differently: a relative pack folder and an absolute
			-- `conc_path', then a `conc_path' through "..". Still one file, still not a generic pack
			-- (design scan 29: the scan compared spellings, so conc.db counted and `open' refused).
		local
			l_bible: SIMPLE_BIBLE
			l_absolute: STRING_32
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			fixture.build (Folder_pack_file)
			l_absolute := (create {SIMPLE_FILE}.make (Folder_pack_file)).absolute_path
			l_bible := bible (l_absolute.to_string_8, Folder)
			assert_integers_equal ("absolute conc_path is the folder's file", 0, l_bible.pack_count)
			l_bible.open
			assert_true ("open", l_bible.is_open and l_bible.conc_pack.is_available)
			l_bible.close
			l_bible := bible ("facade_test_packs\..\facade_test_packs\conc.db", Folder)
			assert_integers_equal ("dotted conc_path is the folder's file", 0, l_bible.pack_count)
			remove_test_files
		end

	test_commentary_pack_builds_attaches_and_answers
			-- 2026-10-27, Task 7b's first customer: a commentary sidecar becomes a pack
			-- (BIB_COMMENTARY_BUILDER), the pack folder's pack attaches read-only with its rules
			-- checked, and a verse finds the sections covering it, the narrowest first, each claim
			-- labelled SOURCED or DEDUCED, a restricted quotation kept apart, the author voice.
		local
			l_builder: BIB_COMMENTARY_BUILDER
			l_bible: SIMPLE_BIBLE
			l_sections: BIB_LIST_RESULT [BIB_COMMENTARY_SECTION]
			l_ok: BOOLEAN
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			l_ok := (create {SIMPLE_FILE}.make (Sidecar_file)).write_text_utf_8 (Sidecar_text)
			create l_builder.make
			l_builder.build (<<Sidecar_file>>, Folder_other_file)
			assert_true ("built", l_builder.last_error = Void)
			assert_true ("counts", l_builder.section_count = 2 and l_builder.claim_count = 2 and l_builder.term_count = 1 and l_builder.restricted_count = 1)
			l_bible := bible ("", Folder)
			l_bible.open
			assert_true ("open with the pack", l_bible.is_open and l_bible.pack_errors.is_empty and l_bible.private_packs.count = 1)
			assert_integers_equal ("one commentary", 1, l_bible.commentary_packs.count)
			assert_strings_equal ("titled", "Larry Rix: Commentaries", l_bible.commentary_packs.first.title)
			l_sections := l_bible.commentary_packs.first.sections_for_verse (65, 1, 6)
			assert_true ("two sections cover Jude 6", l_sections.is_success and l_sections.count = 2)
			assert_strings_equal ("the narrowest first", "jude-5-7", l_sections.item (1).section_id)
			assert_strings_equal ("then the whole letter", "jude-intro", l_sections.item (2).section_id)
			assert_true ("a deduction says so", attached l_sections.item (1).claim ("D5.1") as al_claim and then not al_claim.is_sourced)
			assert_true ("a sourced claim says so", attached l_sections.item (2).claim ("S1.1") as al_claim2 and then al_claim2.is_sourced)
			assert_strings_equal ("a field", "Saved, then destroyed [D5.1].", l_sections.item (1).field ("teaser"))
			assert_integers_equal ("the restricted quotation apart", 1, l_sections.item (1).restricted_quotes.count)
			assert_strings_equal ("the author voice, provisional", "author", l_sections.item (1).voice)
			assert_integers_equal ("Jude 2: the introduction only", 1, l_bible.commentary_packs.first.sections_for_verse (65, 1, 2).count)
			assert_integers_equal ("John 3:16: nothing", 0, l_bible.commentary_packs.first.sections_for_verse (43, 3, 16).count)
			l_bible.close
			fixture.delete_file (Sidecar_file)
			remove_test_files
		end

	test_one_commentary_pack_holds_every_book
			-- Larry, 2026-10-27: one commentary database for every book. Two books' sidecars make one
			-- pack; each book answers its own verses; a claim id may repeat across books (claims are
			-- keyed by section and id). The builder finds every book under a Commentaries folder.
		local
			l_builder: BIB_COMMENTARY_BUILDER
			l_bible: SIMPLE_BIBLE
			l_ok: BOOLEAN
			l_root: SIMPLE_FILE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			create l_root.make (Commentaries_folder)
			if l_root.is_directory then
				l_ok := l_root.delete_directory_recursive
			end
			l_ok := (create {SIMPLE_FILE}.make (Commentaries_folder + "\Jude\_build")).create_directory_recursive
			l_ok := (create {SIMPLE_FILE}.make (Commentaries_folder + "\Revelation\_build")).create_directory_recursive
			l_ok := (create {SIMPLE_FILE}.make (Commentaries_folder + "\Jude\_build\jude.sections.json")).write_text_utf_8 (Sidecar_text)
			l_ok := (create {SIMPLE_FILE}.make (Commentaries_folder + "\Revelation\_build\rev.sections.json")).write_text_utf_8 (Second_sidecar_text)
			create l_builder.make
			assert_integers_equal ("both books found", 2, l_builder.sidecars_in (Commentaries_folder).count)
			l_builder.build (l_builder.sidecars_in (Commentaries_folder), Folder_other_file)
			assert_true ("built", l_builder.last_error = Void and l_builder.book_count = 2 and l_builder.section_count = 3)
			l_bible := bible ("", Folder)
			l_bible.open
			assert_integers_equal ("one pack", 1, l_bible.commentary_packs.count)
			assert_integers_equal ("Jude 6", 2, l_bible.commentary_packs.first.sections_for_verse (65, 1, 6).count)
			assert_true ("Revelation 1:1, its own S1.1", l_bible.commentary_packs.first.sections_for_verse (66, 1, 1).count = 1
				and then attached l_bible.commentary_packs.first.sections_for_verse (66, 1, 1).item (1).claim ("S1.1") as al_claim
				and then al_claim.summary.same_string ("unveiling"))
			l_bible.close
			l_ok := l_root.delete_directory_recursive
			remove_test_files
		end

	test_a_claim_without_an_id_is_refused
			-- Scan 39: a claim the text could never cite (no id) is refused by the builder, never
			-- written and then dropped unseen by the reader.
		local
			l_builder: BIB_COMMENTARY_BUILDER
			l_ok: BOOLEAN
		do
			close_leftovers
			make_folder
			l_ok := (create {SIMPLE_FILE}.make (Sidecar_file)).write_text_utf_8 (Sidecar_text_without_claim_id)
			create l_builder.make
			l_builder.build (<<Sidecar_file>>, Folder_other_file)
			assert_true ("refused", attached l_builder.last_error as al_error and then al_error.has_substring ("no id"))
			fixture.delete_file (Sidecar_file)
			remove_test_files
		end

	test_a_pack_breaking_the_rules_is_refused_and_named
			-- A database in the pack folder without the pack rules (no meta, no voice column) is
			-- refused with its reason, and the Bible still opens (was: until Task 7b, every generic
			-- pack made `open' refuse).
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			fixture.build_main (Folder_other_file)
			l_bible := bible ("", Folder)
			assert_integers_equal ("one generic pack", 1, l_bible.pack_count)
			l_bible.open
			assert_true ("open", l_bible.is_open)
			assert_true ("refused and named", l_bible.pack_errors.count = 1 and then l_bible.pack_errors.first.code = {BIB_ERROR}.Schema_mismatch)
			assert_true ("not attached", l_bible.private_packs.is_empty and l_bible.commentary_packs.is_empty)
			l_bible.close
			remove_test_files
		end

	test_book_catalog_reads_content_db
			-- The catalog reads content.db's book_catalog: a name, a code and a prefix find their book;
			-- an unknown name finds none (research/18; the verse box's books).
		local
			l_bible: SIMPLE_BIBLE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			l_bible := bible ("", "")
			l_bible.open
			assert_integers_equal ("books", 6, l_bible.books.book_count)
			assert_strings_equal ("name", "Matthew", l_bible.books.book (40).name)
			assert_true ("by name", l_bible.books.candidates_for_name ("Genesis").count = 1 and then l_bible.books.candidates_for_name ("Genesis").first = 1)
			assert_true ("by code", l_bible.books.candidates_for_name ("mat").first = 40)
			assert_true ("by prefix", l_bible.books.candidates_for_name ("Exo").first = 2)
			assert_true ("dotted abbreviation", l_bible.books.candidates_for_name ("Gen.").first = 1)
			assert_true ("unknown", l_bible.books.candidates_for_name ("Zzz").is_empty)
			l_bible.close
			remove_test_files
		end

	test_edition_swap_needs_no_code
			-- FR-158, V-54: the same engine reads either pack by `conc_path' alone; the edition shown
			-- is the pack's own label, so no engine code tests the edition.
		local
			l_personal, l_distribution: SIMPLE_BIBLE
			l_db: SIMPLE_SQL_DATABASE
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			fixture.build (Pack_file)
			fixture.build (Other_pack_file)
			create l_db.make (Other_pack_file)
			l_db.execute ("UPDATE meta SET value = 'DISTRIBUTION TEST' WHERE key = 'edition_label'")
			l_db.close
			l_personal := bible (Pack_file, "")
			l_personal.open
			assert_strings_equal ("personal label", {CONC_FIXTURE}.Edition_label, l_personal.conc_pack.edition_label)
			l_personal.close
			l_distribution := bible (Other_pack_file, "")
			l_distribution.open
			assert_strings_equal ("distribution label", "DISTRIBUTION TEST", l_distribution.conc_pack.edition_label)
			assert_true ("same lookups", l_distribution.word_lookup.view ({CONC_FIXTURE}.Article_lemma, "LXX-RAHLFS").is_success)
			l_distribution.close
			fixture.delete_file (Other_pack_file)
			remove_test_files
		end

feature {NONE} -- Fixture

	Other_pack_file: STRING = "facade_test_other_pack.db"

	Content_file: STRING = "facade_test_content.db"
	Pack_file: STRING = "facade_test_pack.db"
	Folder: STRING = "facade_test_packs"
	Folder_pack_file: STRING = "facade_test_packs\conc.db"
	Folder_other_file: STRING = "facade_test_packs\other.db"
	Sidecar_file: STRING = "facade_test_sidecar.json"

	Sidecar_text_without_claim_id: STRING
			-- The test sidecar with its first claim's id emptied.
		once
			Result := "{%"meta%":{%"book%":%"Jude%",%"book_id%":65,%"versification%":%"kjv%",%"status%":%"TEST%"},%"sections%":[{%"section_id%":%"jude-intro%",%"heading%":%""
				+ "Jude 1-25%",%"start%":{%"book%":65,%"chapter%":1,%"verse%":1},%"end%":{%"book%":65,%"chapter%":1,%"verse%":25},%"versification%":%"kjv%",%"voice%":nul"
				+ "l,%"fields%":{%"teaser%":%"The whole letter [S1.1].%",%"text%":%"%",%"commentary%":%"Read it whole.%"},%"frameworks%":[%"ZAKAR%"],%"questions%":[%"Wha"
				+ "t is Jude about?%"],%"further_reading%":[],%"terms%":[],%"claims%":[{%"id%":%"%",%"field%":%"teaser%",%"label%":%"SOURCED%",%"text%":%"The whole l"
				+ "etter.%",%"summary%":%"whole%",%"source%":%"test:1%"}],%"restricted_quotes%":[]},{%"section_id%":%"jude-5-7%",%"heading%":%"Jude 5-7%",%"start%":{%"bo"
				+ "ok%":65,%"chapter%":1,%"verse%":5},%"end%":{%"book%":65,%"chapter%":1,%"verse%":7},%"versification%":%"kjv%",%"voice%":null,%"fields%":{%"teaser%":%"S"
				+ "aved, then destroyed [D5.1].%",%"variants%":%"- v5: Jesus or the Lord.%"},%"frameworks%":[],%"questions%":[%"Who saved the people?%",%"Who was destroy"
				+ "ed?%"],%"further_reading%":[%"[Essay](https://example.org/essay)%"],%"terms%":[{%"script%":%"pistis%",%"translit%":%"pistis%",%"pron%":%"PIS-tis%",%"e"
				+ "nglish%":%"faithfulness%",%"language%":%"grc%",%"lemma_key%":null,%"strongs%":null}],%"claims%":[{%"id%":%"D5.1%",%"field%":%"teaser%",%"label%":%"DED"
				+ "UCED%",%"text%":%"Saved, then destroyed.%",%"summary%":%"saved%",%"source%":%"Basis: test%"}],%"restricted_quotes%":[{%"source%":%"Test edition%",%"sh"
				+ "ip_class%":%"research_only%",%"note%":%"reference only%",%"markdown%":%"A quoted line.%"}]}]}"
		end

	Commentaries_folder: STRING = "facade_test_commentaries"

	Second_sidecar_text: STRING
			-- A one-section Revelation sidecar whose claim id repeats one of Jude's.
		once
			Result := "{%"meta%":{%"book%":%"Revelation%",%"book_id%":66,%"versification%":%"kjv%",%"status%":%"TEST%"},%"sections%":[{%"section_id%":%"rev-1-1%",%""
				+ "heading%":%"Revelation 1:1%",%"start%":{%"book%":66,%"chapter%":1,%"verse%":1},%"end%":{%"book%":66,%"chapter%":1,%"verse%":1},%"versificati"
				+ "on%":%"kjv%",%"voice%":null,%"fields%":{%"teaser%":%"The unveiling [S1.1].%"},%"frameworks%":[],%"questions%":[],%"further_reading%":[],%"te"
				+ "rms%":[],%"claims%":[{%"id%":%"S1.1%",%"field%":%"teaser%",%"label%":%"SOURCED%",%"text%":%"The unveiling.%",%"summary%":%"unveiling%",%"sou"
				+ "rce%":%"test:2%"}],%"restricted_quotes%":[]}]}"
		end

	Sidecar_text: STRING
			-- A two-section commentary sidecar (BIB_COMMENTARY_BUILDER's input).
		once
			Result := "{%"meta%":{%"book%":%"Jude%",%"book_id%":65,%"versification%":%"kjv%",%"status%":%"TEST%"},%"sections%":[{%"section_id%":%"jude-intro%",%"heading%":%""
				+ "Jude 1-25%",%"start%":{%"book%":65,%"chapter%":1,%"verse%":1},%"end%":{%"book%":65,%"chapter%":1,%"verse%":25},%"versification%":%"kjv%",%"voice%":nul"
				+ "l,%"fields%":{%"teaser%":%"The whole letter [S1.1].%",%"text%":%"%",%"commentary%":%"Read it whole.%"},%"frameworks%":[%"ZAKAR%"],%"questions%":[%"Wha"
				+ "t is Jude about?%"],%"further_reading%":[],%"terms%":[],%"claims%":[{%"id%":%"S1.1%",%"field%":%"teaser%",%"label%":%"SOURCED%",%"text%":%"The whole l"
				+ "etter.%",%"summary%":%"whole%",%"source%":%"test:1%"}],%"restricted_quotes%":[]},{%"section_id%":%"jude-5-7%",%"heading%":%"Jude 5-7%",%"start%":{%"bo"
				+ "ok%":65,%"chapter%":1,%"verse%":5},%"end%":{%"book%":65,%"chapter%":1,%"verse%":7},%"versification%":%"kjv%",%"voice%":null,%"fields%":{%"teaser%":%"S"
				+ "aved, then destroyed [D5.1].%",%"variants%":%"- v5: Jesus or the Lord.%"},%"frameworks%":[],%"questions%":[%"Who saved the people?%",%"Who was destroy"
				+ "ed?%"],%"further_reading%":[%"[Essay](https://example.org/essay)%"],%"terms%":[{%"script%":%"pistis%",%"translit%":%"pistis%",%"pron%":%"PIS-tis%",%"e"
				+ "nglish%":%"faithfulness%",%"language%":%"grc%",%"lemma_key%":null,%"strongs%":null}],%"claims%":[{%"id%":%"D5.1%",%"field%":%"teaser%",%"label%":%"DED"
				+ "UCED%",%"text%":%"Saved, then destroyed.%",%"summary%":%"saved%",%"source%":%"Basis: test%"}],%"restricted_quotes%":[{%"source%":%"Test edition%",%"sh"
				+ "ip_class%":%"research_only%",%"note%":%"reference only%",%"markdown%":%"A quoted line.%"}]}]}"
		end

	fixture: CONC_FIXTURE
			-- The shared test-file helpers.
		once
			create Result
		end

	opened_bibles: ARRAYED_LIST [SIMPLE_BIBLE]
			-- Every engine these tests made, so one that a failed test left open is closed.
		once
			create Result.make (4)
		end

	close_leftovers
			-- Close any engine a failed test left open.
		do
			across opened_bibles as ic loop
				if ic.is_open then
					ic.close
				end
			end
			opened_bibles.wipe_out
		ensure
			none_left: opened_bibles.is_empty
		end

	bible (a_conc_path, a_pack_folder: STRING): SIMPLE_BIBLE
			-- An unopened engine over `Content_file' with these paths.
		local
			l_config: BIB_CONFIG
		do
			create l_config.make_with_core (Content_file)
			l_config := l_config.set_conc_path (a_conc_path)
			l_config := l_config.set_pack_folder (a_pack_folder)
			create Result.make (l_config)
			opened_bibles.extend (Result)
		end

	make_folder
			-- Create `Folder' when absent, and empty it of the files these tests write.
		local
			l_ok: BOOLEAN
		do
			fixture.delete_file (Folder_pack_file)
			fixture.delete_file (Folder_other_file)
			if not (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).create_directory
			end
		end

	remove_test_files
			-- Delete every file and the folder these tests write.
		local
			l_ok: BOOLEAN
		do
			close_leftovers
			fixture.delete_file (Content_file)
			fixture.delete_file (Pack_file)
			fixture.delete_file (Folder_pack_file)
			fixture.delete_file (Folder_other_file)
			if (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).delete_directory
			end
		end

end
