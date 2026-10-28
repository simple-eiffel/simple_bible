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
			assert_integers_equal ("books", 8, l_bible.books.book_count)
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

feature -- Frameworks pack (2026-10-28)

	test_framework_pack_builds_attaches_and_answers
			-- Two framework sidecars become a frameworks pack (BIB_FRAMEWORK_BUILDER) whose uses come
			-- from the commentary pack's "Frameworks at work"; the pack folder's packs attach with
			-- their rules checked; the reader lists them by tier, reads one whole, and gives the
			-- spellings, which link: a marked name only with its mark.
		local
			l_commentary: BIB_COMMENTARY_BUILDER
			l_frameworks: BIB_FRAMEWORK_BUILDER
			l_bible: SIMPLE_BIBLE
			l_linker: BIB_REFERENCE_LINKER
			l_out: STRING_32
			l_ok: BOOLEAN
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			l_ok := (create {SIMPLE_FILE}.make (Sidecar_file)).write_text_utf_8 (Sidecar_text)
			create l_commentary.make
			l_commentary.build (<<Sidecar_file>>, Folder_other_file)
			assert_true ("the commentary built", l_commentary.last_error = Void)
			l_ok := (create {SIMPLE_FILE}.make (Kacc_file)).write_text_utf_8 (Kacc_text)
			l_ok := (create {SIMPLE_FILE}.make (Zakar_file)).write_text_utf_8 (Zakar_text)
			create l_frameworks.make
			l_frameworks.build (<<Kacc_file, Zakar_file>>, Folder_frameworks_file, Folder_other_file)
			assert_true ("built", l_frameworks.last_error = Void)
			assert_true ("counts", l_frameworks.framework_count = 2 and l_frameworks.alias_count = 3 and l_frameworks.section_count = 6
				and l_frameworks.related_count = 2)
			assert_integers_equal ("ZAKAR is named in the introduction's Frameworks at work", 1, l_frameworks.use_count)
			l_bible := bible ("", Folder)
			l_bible.open
			assert_true ("open with both packs", l_bible.is_open and l_bible.pack_errors.is_empty and l_bible.private_packs.count = 2)
			assert_integers_equal ("one frameworks pack", 1, l_bible.framework_packs.count)
			if attached l_bible.framework_packs.first as al_pack then
				assert_strings_equal ("titled", "Larry Rix: Frameworks", al_pack.title)
				assert_integers_equal ("both listed", 2, al_pack.frameworks.count)
				assert_strings_equal ("a master lens before a recovery framework", "kacc", al_pack.frameworks.item (1).id)
				assert_true ("KACC is a draft", al_pack.frameworks.item (1).is_draft)
					-- Design scan 58: the answer cites the pack's own provenance row, as written.
				assert_strings_equal ("cited from the pack's own provenance", "frameworks sidecars", al_pack.frameworks.citation (1).source_key)
				assert_true ("with its caveat", al_pack.frameworks.citation (1).caveat.has_substring ("draft until Larry approves"))
				assert_true ("marked", al_pack.frameworks.item (1).has_mark and al_pack.frameworks.item (1).display_name.ends_with ({STRING_32} "%/8482/"))
				if attached al_pack.framework ("zakar") as al_one and then al_one.count = 1 then
					assert_integers_equal ("its sections", 3, al_one.item (1).sections.count)
					assert_strings_equal ("in order", "What it is", al_one.item (1).sections.first.heading)
					assert_strings_equal ("related", "kacc", al_one.item (1).related.first)
					assert_integers_equal ("one use", 1, al_one.item (1).uses.count)
					assert_strings_equal ("the introduction", "jude-intro", al_one.item (1).uses.first.section_id)
					assert_integers_equal ("its verses", 25, al_one.item (1).uses.first.end_verse)
				else
					assert_true ("ZAKAR read whole", False)
				end
				assert_integers_equal ("no such framework", 0, al_pack.framework ("none").count)
				assert_integers_equal ("three spellings", 3, al_pack.aliases.count)
				assert_strings_equal ("the longest first", "the Kingdom lens", al_pack.aliases.item (1).spelling)
				create l_linker.make (l_bible.books)
				l_linker.set_framework_names (create {BIB_FRAMEWORK_NAMES}.make_from_spellings (al_pack.aliases))
				l_out := l_linker.linked ({STRING_32} "KACC%/8482/ and ZAKAR, not KACC alone; see the Kingdom lens and Jude 9.")
				assert_true ("a marked name with its mark", l_out.has_substring ({STRING_32} "[KACC%/8482/](framework:kacc)"))
				assert_true ("an unmarked name as written", l_out.has_substring ("[ZAKAR](framework:zakar)"))
				assert_true ("a marked name without its mark stays prose", l_out.has_substring ("not KACC alone"))
				assert_true ("an alias", l_out.has_substring ("[the Kingdom lens](framework:kacc)"))
				assert_true ("references still link", l_out.has_substring ("[Jude 9](bible:65.1.9)"))
					-- COMMENTARY, 2026-10-28: a mark inside a spelling; an essay title is not a framework.
				l_out := l_linker.linked ({STRING_32} "see the Kingdom%/8482/ lens; KACC 09: an essay.")
				assert_true ("a mark after a word inside a spelling", l_out.has_substring ({STRING_32} "[the Kingdom%/8482/ lens](framework:kacc)"))
				assert_true ("a marked name without its mark is an essay title", l_out.has_substring ("KACC 09: an essay"))
			end
			l_bible.close
			fixture.delete_file (Sidecar_file)
			fixture.delete_file (Kacc_file)
			fixture.delete_file (Zakar_file)
			remove_test_files
		end

	test_framework_sidecar_breaking_a_rule_is_refused
			-- A hover longer than 280 characters, a spelling another framework has: each refuses the
			-- build, naming the file and the rule, and no pack is written. A related id the pack does
			-- not hold yet is left out with a warning (frameworks come in batches).
		local
			l_frameworks: BIB_FRAMEWORK_BUILDER
			l_ok: BOOLEAN
		do
			close_leftovers
			make_folder
			create l_frameworks.make
			l_ok := (create {SIMPLE_FILE}.make (Kacc_file)).write_text_utf_8 (Kacc_text_with_long_hover)
			l_ok := (create {SIMPLE_FILE}.make (Zakar_file)).write_text_utf_8 (Zakar_text)
			l_frameworks.build (<<Kacc_file, Zakar_file>>, Folder_frameworks_file, "")
			assert_true ("a long hover refused, by file", attached l_frameworks.last_error as al_e and then al_e.has_substring (Kacc_file) and then al_e.has_substring ("hover"))
			assert_false ("no pack written", (create {SIMPLE_FILE}.make (Folder_frameworks_file)).exists)
			l_ok := (create {SIMPLE_FILE}.make (Kacc_file)).write_text_utf_8 (Kacc_text)
			l_ok := (create {SIMPLE_FILE}.make (Zakar_file)).write_text_utf_8 (Zakar_text_with_kacc_alias)
			l_frameworks.build (<<Kacc_file, Zakar_file>>, Folder_frameworks_file, "")
			assert_true ("a spelling taken refused", attached l_frameworks.last_error as al_e and then al_e.has_substring (Zakar_file) and then al_e.has_substring ("already names"))
			l_ok := (create {SIMPLE_FILE}.make (Zakar_file)).write_text_utf_8 (Zakar_text_relating_none)
			l_frameworks.build (<<Kacc_file, Zakar_file>>, Folder_frameworks_file, "")
			assert_true ("an unknown related id does not refuse the build", l_frameworks.last_error = Void)
			assert_true ("it is left out, with a warning", l_frameworks.related_count = 1 and l_frameworks.warnings.count = 1
				and then l_frameworks.warnings.first.has_substring ("none"))
			fixture.delete_file (Kacc_file)
			fixture.delete_file (Zakar_file)
			remove_test_files
		end

feature -- Books pack (2026-10-28)

	test_book_pack_builds_attaches_and_answers
			-- A book manifest and its two chapter files become a books pack (BIB_BOOK_BUILDER): the
			-- chapters split into blocks with the inventory's cleaning (front matter, a draft status
			-- line, rules, a skipped section, an image and a typesetting placeholder left out; a
			-- footnote and a wiki link read plainly), every reference and framework name indexed by
			-- the linker's own links; the pack attaches and answers a verse and a framework.
		local
			l_frameworks: BIB_FRAMEWORK_BUILDER
			l_books: BIB_BOOK_BUILDER
			l_bible: SIMPLE_BIBLE
			l_db_writer: SIMPLE_SQL_DATABASE
			l_ok: BOOLEAN
		do
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			make_book_folder
			l_ok := (create {SIMPLE_FILE}.make (Kacc_file)).write_text_utf_8 (Kacc_text)
			l_ok := (create {SIMPLE_FILE}.make (Zakar_file)).write_text_utf_8 (Zakar_text)
			create l_frameworks.make
			l_frameworks.build (<<Kacc_file, Zakar_file>>, Folder_frameworks_file, "")
			assert_true ("the frameworks built", l_frameworks.last_error = Void)
			l_bible := bible ("", "")
			l_bible.open
			create l_books.make (l_bible.books)
			l_books.build (<<Book_manifest_file>>, Folder_books_file, Folder_frameworks_file)
			l_bible.close
			assert_true ("built", l_books.last_error = Void)
			assert_integers_equal ("one book", 1, l_books.book_count)
			assert_integers_equal ("two chapters", 2, l_books.chapter_count)
			assert_integers_equal ("seven blocks, then two", 9, l_books.block_count)
			assert_integers_equal ("Jude 5-7 and Jude 9 cited", 2, l_books.passage_count)
			assert_integers_equal ("KACC named once", 1, l_books.framework_use_count)
			l_bible := bible ("", Folder)
			l_bible.open
			assert_true ("open with the packs", l_bible.is_open and l_bible.pack_errors.is_empty)
			assert_integers_equal ("one books pack", 1, l_bible.book_packs.count)
			if attached l_bible.book_packs.first as al_pack then
				assert_strings_equal ("titled", "Larry Rix: Books", al_pack.title)
				assert_integers_equal ("one book listed", 1, al_pack.books.count)
				assert_strings_equal ("its title", "Remember", al_pack.books.item (1).title)
				if attached al_pack.book ("zk") as al_book and then al_book.count = 1 then
					assert_integers_equal ("its chapters", 2, al_book.item (1).chapters.count)
					assert_strings_equal ("in order", "Two", al_book.item (1).chapter_title (2))
				else
					assert_true ("the book read whole", False)
				end
				if attached al_pack.chapter_blocks ("zk", 1) as al_blocks then
					assert_integers_equal ("chapter one's blocks", 7, al_blocks.count)
					assert_strings_equal ("the status line and rule left out: the heading first", "The Word", al_blocks.item (1).markdown)
					assert_strings_equal ("a footnote marker read plainly", {STRING_32} "Remember Jude 5-7 and KACC%/8482/ here.[1]", al_blocks.item (2).markdown)
					assert_strings_equal ("the working notes left out", "Real", al_blocks.item (3).markdown)
					assert_strings_equal ("a quote is a quote", "quote", al_blocks.item (4).kind)
					assert_strings_equal ("as written", "> A quote from Jude 9.", al_blocks.item (4).markdown)
					assert_strings_equal ("the note read plainly, its wiki link as its label", "[1] A note on the book.", al_blocks.item (7).markdown)
				end
				assert_integers_equal ("Jude 6: the paragraph citing Jude 5-7", 1, al_pack.blocks_citing (65, 1, 6).count)
				assert_strings_equal ("its address", "book:zk/1#2", al_pack.blocks_citing (65, 1, 6).item (1).link)
				assert_integers_equal ("Jude 9: the quote", 1, al_pack.blocks_citing (65, 1, 9).count)
				assert_integers_equal ("John 3:16: nothing", 0, al_pack.blocks_citing (43, 3, 16).count)
				assert_integers_equal ("KACC: one paragraph", 1, al_pack.blocks_naming ("kacc").count)
			end
			l_bible.close
				-- Scan 60: a row whose block no link can name (past 9999) is passed over, not a
				-- broken precondition; and every private schema writes the version the attach reads.
			l_db_writer := (create {SIMPLE_SQL_DATABASE}.make (Folder_books_file))
			l_db_writer.execute ("INSERT INTO book_block VALUES ('zk', 1, 10000, 'paragraph', 0, 'far', 'author', 1)")
			assert_false ("the far row written", l_db_writer.has_error)
			l_db_writer.close
			l_bible := bible ("", Folder)
			l_bible.open
			if attached l_bible.book_packs.first as al_pack then
				assert_integers_equal ("still chapter one's seven blocks", 7, al_pack.chapter_blocks ("zk", 1).count)
			end
			l_bible.close
			assert_integers_equal ("the books schema's version is the one read", {BIB_PRIVATE_SOURCE}.Pack_schema_version, (create {BIB_BOOK_SCHEMA}).Schema_version)
			assert_true ("and the version statement says it", (create {BIB_BOOK_SCHEMA}).schema_statements.item ((create {BIB_BOOK_SCHEMA}).schema_statements.upper).same_string ("PRAGMA user_version = " + {BIB_PRIVATE_SOURCE}.Pack_schema_version.out))
			l_ok := (create {SIMPLE_FILE}.make (Book_manifest_file)).write_text_utf_8 (Book_manifest_text_missing_file)
			l_bible := bible ("", "")
			l_bible.open
			create l_books.make (l_bible.books)
			l_books.build (<<Book_manifest_file>>, Folder_books_file, "")
			l_bible.close
			assert_true ("a missing chapter file refused, by name", attached l_books.last_error as al_e and then al_e.has_substring ("no chapter file"))
			fixture.delete_file (Kacc_file)
			fixture.delete_file (Zakar_file)
			remove_book_folder
			remove_test_files
		end

	test_writings_search_finds_plain_and_fuzzy
			-- Research/20: the frameworks and books packs carry a search table their builders fill and
			-- the attach rule lets pass; one query grammar finds words, prefixes, phrases, AND and NOT,
			-- within a pack kind or an address; fuzzy search finds a misspelt word from the pack's own
			-- vocabulary; a NOT with nothing beside it is told.
		local
			l_frameworks: BIB_FRAMEWORK_BUILDER
			l_books: BIB_BOOK_BUILDER
			l_bible: SIMPLE_BIBLE
			l_search: BIB_WRITINGS_SEARCH
			l_edits: BIB_EDIT_DISTANCE
			l_ok: BOOLEAN
		do
			create l_edits
			assert_integers_equal ("a swap is one edit", 1, l_edits.distance ("remmeber", "remember", 2))
			assert_integers_equal ("a missing letter is one", 1, l_edits.distance ("sabath", "sabbath", 2))
			assert_integers_equal ("past the limit stops counting", 3, l_edits.distance ("kitten", "sitting", 2))
			assert_integers_equal ("the same word is none", 0, l_edits.distance ("word", "word", 1))
			close_leftovers
			fixture.build_content (Content_file, {CONC_FIXTURE}.Content_version, False)
			make_folder
			make_book_folder
			l_ok := (create {SIMPLE_FILE}.make (Kacc_file)).write_text_utf_8 (Kacc_text)
			l_ok := (create {SIMPLE_FILE}.make (Zakar_file)).write_text_utf_8 (Zakar_text)
			create l_frameworks.make
			l_frameworks.build (<<Kacc_file, Zakar_file>>, Folder_frameworks_file, "")
			assert_true ("the frameworks built", l_frameworks.last_error = Void)
			assert_integers_equal ("two hovers and six sections searchable", 8, l_frameworks.search_row_count)
			l_bible := bible ("", "")
			l_bible.open
			create l_books.make (l_bible.books)
			l_books.build (<<Book_manifest_file>>, Folder_books_file, Folder_frameworks_file)
			l_bible.close
			assert_true ("the books built", l_books.last_error = Void)
			assert_integers_equal ("every block searchable", l_books.block_count, l_books.search_row_count)
			l_bible := bible ("", Folder)
			l_bible.open
			assert_true ("packs with search tables attach", l_bible.is_open and l_bible.pack_errors.is_empty)
			l_search := l_bible.writings_search
			assert_integers_equal ("two packs searched", 2, l_search.pack_count)
			l_search.search ("remember", False, "", "")
			assert_integers_equal ("a word: the one paragraph", 1, l_search.hits.count)
			assert_strings_equal ("its address", "book:zk/1#2", l_search.hits.first.address)
			assert_strings_equal ("its pack", "books", l_search.hits.first.pack_kind)
			assert_true ("its words marked", l_search.hits.first.snippet.has_substring ({STRING_32} "%/171/Remember%/187/"))
			l_search.search ("remember*", False, "", "")
			assert_integers_equal ("a prefix: ZAKAR (its hover and question, one place) and the paragraph", 2, l_search.hits.count)
			assert_strings_equal ("frameworks before books", "frameworks", l_search.hits.first.pack_kind)
			l_search.search ("remember*", False, "books", "")
			assert_integers_equal ("one pack kind", 1, l_search.hits.count)
			l_search.search ("remember*", False, "", "framework:zakar")
			assert_integers_equal ("within an address", 1, l_search.hits.count)
			l_search.search ("%"contested cosmos%"", False, "", "")
			assert_integers_equal ("a phrase", 1, l_search.hits.count)
			assert_strings_equal ("in KACC", "framework:kacc", l_search.hits.first.address)
			l_search.search ("cosmos NOT allegiance", False, "", "")
			assert_integers_equal ("NOT takes away", 1, l_search.hits.count)
			l_search.search ("contested AND allegiance", False, "", "")
			assert_integers_equal ("AND: no one row holds both", 0, l_search.hits.count)
			l_search.search ("remmeber", False, "", "")
			assert_integers_equal ("misspelt, plain: nothing", 0, l_search.hits.count)
			l_search.search ("remmeber", True, "", "")
			assert_integers_equal ("misspelt, fuzzy: the paragraph and ZAKAR's %"remembers%" (two edits)", 2, l_search.hits.count)
			assert_strings_equal ("ZAKAR first, then the paragraph", "book:zk/1#2", l_search.hits.last.address)
			assert_true ("widened from the pack's words", l_search.last_expression.has_substring ("%"remember%""))
			l_search.search ("NOT cosmos", False, "", "")
			assert_false ("NOT alone is told", l_search.error_message.is_empty)
			assert_true ("and finds nothing", l_search.hits.is_empty)
			l_bible.close
			fixture.delete_file (Kacc_file)
			fixture.delete_file (Zakar_file)
			remove_book_folder
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

	Folder_frameworks_file: STRING = "facade_test_packs\frameworks.db"
	Folder_books_file: STRING = "facade_test_packs\books.db"
	Book_folder: STRING = "facade_test_book"
	Book_manifest_file: STRING = "facade_test_zk.book.json"

	Book_manifest_text: STRING
			-- A book of two chapters, one section of working notes to skip.
		once
			Result := "{%"id%":%"zk%",%"title%":%"Remember%",%"subtitle%":%"A test%",%"author%":%"Larry Rix%",%"status%":%"published%",%"edition%":%"test%",%"year%":2026,"
				+ "%"aliases%":[%"Remember (the book)%"],%"description%":%"A test book.%",%"root%":%"facade_test_book%",%"chapters%":[{%"title%":%"The Word%",%"file%":%"ch1.md%",%"kind%":%"chapter%"},"
				+ "{%"title%":%"Two%",%"file%":%"ch2.md%",%"kind%":%"back%"}],%"skip_headings%":[%"Working notes%"],%"source%":%"test%"}"
		end

	Book_manifest_text_missing_file: STRING
			-- The same, naming a chapter file that is not there.
		once
			Result := Book_manifest_text.twin
			Result.replace_substring_all ("ch2.md", "nowhere.md")
		end

	Chapter_one_text: STRING_32
			-- Front matter, a draft status line and a rule before the heading; a reference range and a
			-- framework with a footnote; working notes to skip; a quote citing a verse; two items; an
			-- image and a placeholder to leave out; the footnote's note with a wiki link.
		once
			Result := {STRING_32} "---%Ntitle: test%N---%N*Draft %/8212/ first draft*%N%N---%N%N# The Word%N%NRemember Jude 5-7 and KACC%/8482/ here.[^1]%N%N## Working notes%N%Nsecret%N%N"
				+ {STRING_32} "## Real%N%N> A quote from Jude 9.%N%N- item one%N- item two%N%N![pic](a.png)%N%N*[Copyright page %/8212/ to be supplied.]*%N%N[^1]: A note on [[ZAKAR|the book]].%N"
		end

	Chapter_two_text: STRING_32
		once
			Result := {STRING_32} "# Two%N%NNothing cited.%N"
		end

	make_book_folder
			-- The test book's folder, chapters and manifest.
		local
			l_ok: BOOLEAN
		do
			if not (create {SIMPLE_FILE}.make (Book_folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Book_folder)).create_directory
			end
			l_ok := (create {SIMPLE_FILE}.make (Book_folder + "\ch1.md")).write_text_utf_8 (Chapter_one_text)
			l_ok := (create {SIMPLE_FILE}.make (Book_folder + "\ch2.md")).write_text_utf_8 (Chapter_two_text)
			l_ok := (create {SIMPLE_FILE}.make (Book_manifest_file)).write_text_utf_8 (Book_manifest_text)
		end

	remove_book_folder
			-- The test book's files and folder gone.
		local
			l_ok: BOOLEAN
		do
			fixture.delete_file (Book_folder + "\ch1.md")
			fixture.delete_file (Book_folder + "\ch2.md")
			fixture.delete_file (Book_manifest_file)
			if (create {SIMPLE_FILE}.make (Book_folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Book_folder)).delete_directory
			end
		end
	Kacc_file: STRING = "facade_test_kacc.framework.json"
	Zakar_file: STRING = "facade_test_zakar.framework.json"

	Kacc_text: STRING
			-- A marked master framework with one alias, related to ZAKAR.
		once
			Result := "{%"id%":%"kacc%",%"name%":%"KACC%",%"mark%":true,%"title%":%"Kingdom Allegiance in Contested Cosmos%",%"aliases%":[%"the Kingdom lens%"],"
				+ "%"tier%":%"master%",%"status%":%"draft%",%"hover%":%"HOVER%",%"sections%":[{%"heading%":%"What it is%",%"markdown%":%"A contested cosmos.%"},"
				+ "{%"heading%":%"Why it matters%",%"markdown%":%"Allegiance.%"},{%"heading%":%"The question it asks of a passage%",%"markdown%":%"Who rules here?%"}],"
				+ "%"related%":[%"zakar%"],%"source%":%"KACC test.md%"}"
		end

	Zakar_text: STRING
			-- An unmarked recovery framework, related to KACC.
		once
			Result := "{%"id%":%"zakar%",%"name%":%"ZAKAR%",%"mark%":false,%"title%":%"Governance-Memory%",%"aliases%":[],%"tier%":%"recovery%",%"status%":%"reviewed%","
				+ "%"hover%":%"Remembering as keeping covenant.%",%"sections%":[{%"heading%":%"What it is%",%"markdown%":%"Memory as governance.%"},"
				+ "{%"heading%":%"Why it matters%",%"markdown%":%"Identity.%"},{%"heading%":%"The question it asks of a passage%",%"markdown%":%"Who remembers?%"}],"
				+ "%"related%":[%"kacc%"],%"source%":%"ZAKAR test.md%"}"
		end

	Zakar_text_with_kacc_alias: STRING
			-- ZAKAR claiming KACC's alias.
		once
			Result := Zakar_text.twin
			Result.replace_substring_all ("%"aliases%":[]", "%"aliases%":[%"the Kingdom lens%"]")
		end

	Zakar_text_relating_none: STRING
			-- ZAKAR related to a framework the pack does not hold.
		once
			Result := Zakar_text.twin
			Result.replace_substring_all ("%"related%":[%"kacc%"]", "%"related%":[%"none%"]")
		end

	Kacc_text_with_long_hover: STRING
			-- KACC with a hover of 281 characters.
		local
			l_long: STRING
		once
			create l_long.make_filled ('a', 281)
			Result := Kacc_text.twin
			Result.replace_substring_all ("%"HOVER%"", "%"" + l_long + "%"")
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
			fixture.delete_file (Folder_frameworks_file)
			fixture.delete_file (Folder_books_file)
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
			fixture.delete_file (Folder_frameworks_file)
			fixture.delete_file (Folder_books_file)
			if (create {SIMPLE_FILE}.make (Folder)).is_directory then
				l_ok := (create {SIMPLE_FILE}.make (Folder)).delete_directory
			end
		end

end
