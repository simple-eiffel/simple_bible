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

	test_cross_references_most_voted_first
			-- P04's Cross-refs tab: the targets of a verse, most voted first, a range told as one,
			-- negative votes kept; a verse with none answers empty.
		local
			l_refs: BIB_LIST_RESULT [BIB_READING_CROSS_REF]
		do
			assert_true ("carried", bible.text_reader.has_cross_references)
			l_refs := bible.text_reader.cross_references (1, 1, 1)
			assert_true ("succeeded", l_refs.is_success)
			assert_integers_equal ("three", 3, l_refs.count)
			assert_true ("most voted first: John 1:1-3", l_refs.item (1).to_book = 43 and l_refs.item (1).votes = 950 and l_refs.item (1).is_range)
			assert_strings_equal ("range text", "1-3", l_refs.item (1).verses_text)
			assert_integers_equal ("negative votes kept", -3, l_refs.item (3).votes)
			assert_integers_equal ("none from Genesis 1:2", 0, bible.text_reader.cross_references (1, 1, 2).count)
			finish
		end

	test_lexicon_entries_and_gloss
			-- P05.5: every dictionary meaning, each source in its own words; and a one-line gloss.
		local
			l_entries: BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
		do
			l_entries := bible.conc_pack.lexicon_entries ({CONC_FIXTURE}.Create_lemma)
			assert_true ("succeeded", l_entries.is_success)
			assert_true ("one entry or more", l_entries.count >= 1)
			assert_false ("titles never empty", across 1 |..| l_entries.count as i some l_entries.item (i).title.is_empty end)
			assert_true ("an unknown headword: empty, not failed", bible.conc_pack.lexicon_entries (999).is_success)
			assert_true ("gloss never fails", bible.conc_pack.short_gloss (999).is_empty)
			finish
		end

	test_a_clicked_word_finds_its_original
			-- S4 (GW-08): the word "created" clicked in Genesis 1:1 of the BSB finds bara through the
			-- BSB's per-word link; a second "created" or an unlinked word finds nothing.
		local
			l_lookup: BIB_LOOKUP
			l_ref: BIB_REF
			l_found: BIB_LIST_RESULT [BIB_WORD_ENTRY]
		do
			create l_lookup.make (bible)
			assert_strings_equal ("the BSB's English corpus", "ENG-BSB", l_lookup.english_corpus_for_version ("BSB"))
			assert_true ("no English corpus for the Hebrew", l_lookup.english_corpus_for_version ("WLC").is_empty)
			create l_ref.make (1, 1, 1, create {BIB_VERSIFICATION_SYSTEM}.make_kjv)
			l_found := bible.conc_pack.headwords_behind_word ("ENG-BSB", l_ref, "created", 1)
			assert_true ("found", l_found.is_success and l_found.count = 1)
			assert_true ("bara", l_found.item (1).lemma_id = {CONC_FIXTURE}.Create_lemma)
			assert_integers_equal ("no second created", 0, bible.conc_pack.headwords_behind_word ("ENG-BSB", l_ref, "created", 2).count)
			assert_integers_equal ("an unlinked word", 0, bible.conc_pack.headwords_behind_word ("ENG-BSB", l_ref, "zzz", 1).count)
			finish
		end

	test_a_clicked_original_word_finds_its_headword
			-- The parallel view's Hebrew or Greek column: the clicked word, folded as the pack's search
			-- forms are, matched to the verse's tokens with a prefix joined to its word ("BBRA" is the
			-- prefix b and bara), finds the longer token's headword.
		local
			l_lookup: BIB_LOOKUP
			l_ref: BIB_REF
			l_found: BIB_LIST_RESULT [BIB_WORD_ENTRY]
		do
			create l_lookup.make (bible)
			assert_strings_equal ("WLC is tagged in the Hebrew Bible", "WLC-MACULA", l_lookup.original_corpus_for_version ("WLC", 1))
			assert_true ("an English version is no original", l_lookup.original_corpus_for_version ("KJV", 1).is_empty)
			create l_ref.make (1, 1, 1, create {BIB_VERSIFICATION_SYSTEM}.make_kjv)
			l_found := bible.conc_pack.headwords_behind_original_word ("WLC-MACULA", l_ref, "BBRA", 1)
			assert_true ("found", l_found.is_success and l_found.count = 1)
			assert_true ("bara, not the prefix", l_found.item (1).lemma_id = {CONC_FIXTURE}.Create_lemma)
			assert_integers_equal ("no second", 0, bible.conc_pack.headwords_behind_original_word ("WLC-MACULA", l_ref, "BBRA", 2).count)
			assert_integers_equal ("a word the verse lacks", 0, bible.conc_pack.headwords_behind_original_word ("WLC-MACULA", l_ref, "ZZZ", 1).count)
			finish
		end

	test_an_empty_chapter_says_why
			-- Scan 36: why a chapter shows nothing is said once, for the Bible tab and every Parallel
			-- column: nothing to say when it has verses; "... is not in this version." when it has none.
		local
			l_lookup: BIB_LOOKUP
		do
			create l_lookup.make (bible)
			assert_true ("verses: nothing to say", l_lookup.empty_chapter_text (bible.text_reader.chapter ("KJV", 1, 1), "Genesis 1").is_empty)
			assert_strings_equal ("none: said", {STRING_32} "Genesis 50 is not in this version.", l_lookup.empty_chapter_text (bible.text_reader.chapter ("KJV", 1, 50), "Genesis 50"))
			finish
		end

	test_every_claim_wears_its_label
			-- 2026-10-27: a claim tag in the commentary's text is shown with its label, and each
			-- section lists its claims by label; a DEDUCED claim never reads as Larry's words.
		local
			l_section: BIB_COMMENTARY_SECTION
			l_text: BIB_COMMENTARY_TEXT
			l_page: STRING_32
		do
			create l_section.make ("jude-5-7", "Jude 5-7", 65, 1, 5, 1, 7, "author",
				create {BIB_PROVENANCE}.make (1, "Larry Rix: Jude", "TEST", create {BIB_LICENSE}.make ("private", True, False, True, "Larry Rix"), ""))
			l_section.fields.extend (["teaser", {STRING_32} "Saved, then destroyed [D5.1]; he says so [S5.2]."])
			l_section.claims.extend (create {BIB_COMMENTARY_CLAIM}.make ("D5.1", "DEDUCED", "Saved, then destroyed.", "saved then destroyed", "Basis: ZAKAR"))
			l_section.claims.extend (create {BIB_COMMENTARY_CLAIM}.make ("S5.2", "SOURCED", "He says so.", "his words", "CL 1:2"))
			create l_text
			l_page := l_text.page ("Jude: A Commentary", <<l_section>>)
			assert_true ("the deduction labelled inline", l_page.has_substring ("**[DEDUCED D5.1]**"))
			assert_true ("the sourced claim labelled inline", l_page.has_substring ("**[SOURCED S5.2]**"))
			assert_false ("no bare tag left", l_page.has_substring (" [D5.1]"))
			assert_true ("listed by label", l_page.has_substring ("- **[DEDUCED D5.1]** saved then destroyed"))
			assert_true ("the banner says what the labels mean", l_page.has_substring ("not his words"))
		end

	test_references_become_links
			-- 2026-10-27: Bible references in Markdown become links a reading pane follows; a book of
			-- one chapter takes a lone number as its verse; prose and existing links are left alone.
		local
			l_linker: BIB_REFERENCE_LINKER
			l_out, l_text, l_list: STRING_32
		do
			create l_linker.make (bible.books)
			l_out := l_linker.linked ("See Genesis 1:1 and Exodus 3:14-15, Matthew 5, Jude 9; it is 5 words.")
			assert_true ("verse", l_out.has_substring ("[Genesis 1:1](bible:1.1.1)"))
			assert_true ("range keeps its text and names its end", l_out.has_substring ("[Exodus 3:14-15](bible:2.3.14-3.15)"))
			if attached l_linker.target_place ("bible:2.3.14-3.15") as al_first then
				assert_true ("a range opens its first verse", al_first.book = 2 and al_first.chapter = 3 and al_first.verse = 14)
			else
				assert_true ("a range's first verse is read", False)
			end
				-- 2026-10-28: where a passage ends, for the commentary's hover card.
			if attached l_linker.target_range ("bible:2.3.14-3.15") as al_range then
				assert_true ("Exodus 3:14-15 ends at 3:15", al_range.end_chapter = 3 and al_range.end_verse = 15)
			else
				assert_true ("a range is read", False)
			end
			if attached l_linker.target_range ("bible:1.1.1") as al_one then
				assert_true ("one verse ends where it starts", al_one.end_chapter = 1 and al_one.end_verse = 1)
			else
				assert_true ("one verse is read", False)
			end
			assert_true ("verses across chapters", l_linker.linked ("Exodus 5:1-6:2").has_substring ("](bible:2.5.1-6.2)"))
			assert_true ("whole chapters", l_linker.linked ("Matthew 5-7").has_substring ("](bible:40.5.0-7.0)"))
			assert_true ("a range in a book of one chapter", l_linker.linked ("Jude 5-7").has_substring ("](bible:65.1.5-1.7)"))
				-- 2026-10-28: the abbreviations prose writes (Larry's books, the commentary).
			assert_true ("1 Pet", l_linker.linked ("as 1 Pet 1:3 says").has_substring ("[1 Pet 1:3](bible:60.1.3)"))
			assert_true ("1 Jn", l_linker.linked ("1 Jn 1:9").has_substring ("[1 Jn 1:9](bible:62.1.9)"))
			assert_true ("Matt, Mt", l_linker.linked ("Matt 5:3 and Mt 5:4").has_substring ("](bible:40.5.3)") and l_linker.linked ("Mt 5:4").has_substring ("](bible:40.5.4)"))
			assert_true ("Isa", l_linker.linked ("Isa 53:5").has_substring ("](bible:23.53.5)"))
			assert_true ("an abbreviation's period", l_linker.linked ("Exod. 3:14").has_substring ("](bible:2.3.14)"))
				-- 2026-10-30 (Larry, the Unseen Realm guide): a list after a reference keeps its book.
			l_list := l_linker.linked ("Genesis 1:26; 3:5, 22; 6:1-4; 10-11; 15:1; 48:15-16 (p. 19): Listed")
			assert_true ("the first", l_list.has_substring ("[Genesis 1:26](bible:1.1.26)"))
			assert_true ("a chapter and verse after a semicolon", l_list.has_substring ("; [3:5](bible:1.3.5)"))
			assert_true ("a verse after a comma, same chapter", l_list.has_substring (", [22](bible:1.3.22)"))
			assert_true ("a verse range", l_list.has_substring ("[6:1-4](bible:1.6.1-6.4)"))
			assert_true ("whole chapters", l_list.has_substring ("[10-11](bible:1.10.0-11.0)"))
			assert_true ("one more verse", l_list.has_substring ("[15:1](bible:1.15.1)"))
			assert_true ("the last range, its page note left alone", l_list.has_substring ("[48:15-16](bible:1.48.15-48.16) (p. 19): Listed"))
			l_list := l_linker.linked ("Exodus 3:8-9 (pp. 19, 19n2); 3:17 (p. 19)")
			assert_true ("past a page note", l_list.has_substring ("; [3:17](bible:2.3.17)"))
			assert_true ("page numbers are no verses", not l_list.has_substring ("[19]"))
			assert_true ("a number in prose is no verse", not l_linker.linked ("Romans 8:28, 30 people came").has_substring ("[30]"))
			assert_true ("scan 70: a list in emphasis links each part", l_linker.linked ("**Genesis 1:26; 3:5**").has_substring ("; [3:5](bible:1.3.5)**"))
			assert_true ("scan 70: after a chapter, a comma names another chapter", l_linker.linked ("Genesis 1, 2.").has_substring (", [2](bible:1.2.0)."))
			assert_true ("a new book after a comma", l_linker.linked ("John 3:16, 1 John 4:8").has_substring (", [1 John 4:8](bible:62.4.8)"))
			assert_true ("a new book after a semicolon", l_linker.linked ("Genesis 1; Exodus 3").has_substring ("; [Exodus 3](bible:2.3.0)"))
				-- Scan 68: reading a reference leaves the caller's text as it was.
			l_text := {STRING_32} "  Jude 9. "
			assert_true ("a box reads it", (create {BIB_REFERENCE_LINKER}.make_forgiving (bible.books)).place_in (l_text) /= Void)
			assert_strings_equal ("and the text is untouched", {STRING_32} "  Jude 9. ", l_text)
				-- Scan 59: the compact forms link in prose, and a box reads the short forms too.
			assert_true ("1Pet", l_linker.linked ("as 1Pet 1:3 says").has_substring ("[1Pet 1:3](bible:60.1.3)"))
			assert_true ("1John", l_linker.linked ("1John 1:9").has_substring ("](bible:62.1.9)"))
			assert_true ("a box reads gn", attached (create {BIB_REFERENCE_LINKER}.make_forgiving (bible.books)).place_in ("gn 1:1") as al_gn
				and then (al_gn.book = 1 and al_gn.chapter = 1 and al_gn.verse = 1))
			assert_true ("a box reads Mt", attached (create {BIB_REFERENCE_LINKER}.make_forgiving (bible.books)).place_in ("Mt 5:3") as al_mt
				and then al_mt.book = 40)
			assert_true ("a box reads 1pet", attached (create {BIB_REFERENCE_LINKER}.make_forgiving (bible.books)).place_in ("1pet 1:3") as al_pet
				and then (al_pet.book = 60 and al_pet.chapter = 1 and al_pet.verse = 3))
			assert_false ("a book the content does not hold is no link", l_linker.linked ("Heb 13:8").has_substring ("bible:"))
			assert_false ("lowercase is prose", l_linker.linked ("the gen 1:1 line").has_substring ("bible:"))
			assert_true ("a range that runs backward is its first place", l_linker.linked ("Exodus 3:15-14").has_substring ("](bible:2.3.15)"))
				-- Design scan 57: a target no reference writes reads as none, so a hover never walks
				-- a thousand chapters; a long digit run never overflows into a link.
			assert_true ("a passage past any book is none", l_linker.target_range ("bible:1.1.1-999999999.1") = Void)
			assert_true ("a signed number is none", l_linker.target_range ("bible:-1.1.1") = Void)
			assert_true ("a passage running backward is none", l_linker.target_range ("bible:2.3.15-3.14") = Void)
			assert_true ("book 0 is none", l_linker.target_range ("bible:0.1.1") = Void)
			assert_false ("a long digit run is no reference", l_linker.linked ("Genesis 99999999999:1").has_substring ("bible:"))
			assert_true ("a chapter", l_out.has_substring ("[Matthew 5](bible:40.5.0)"))
			assert_true ("one chapter: the number is the verse", l_out.has_substring ("[Jude 9](bible:65.1.9)"))
			assert_true ("prose untouched", l_out.has_substring ("it is 5 words"))
			l_out := l_linker.linked ("[Genesis 1:1](https://example.org) and `Genesis 1:2`")
			assert_strings_equal ("links and code untouched", "[Genesis 1:1](https://example.org) and `Genesis 1:2`", l_out)
			finish
		end

	test_program_version_is_the_resource_version
			-- 2026-10-28: the caption and Help > About show BIB_RELEASE.Program_version; the installer
			-- reads bible_gui.rc's ProductVersion. One version, or the test says which one moved.
		local
			s: SOURCE_SCAN
			l_rc, l_numbers: STRING_8
		do
			l_numbers := {BIB_RELEASE}.Program_version.twin
			l_numbers.replace_substring_all (".", ",")
			create s
			l_rc := s.file_text ("bible_gui.rc")
			assert_true ("bible_gui.rc read", not l_rc.is_empty)
			assert_true ("ProductVersion is Program_version", l_rc.has_substring ("VALUE %"ProductVersion%", %"" + {BIB_RELEASE}.Program_version + "%""))
			assert_true ("FileVersion is Program_version", l_rc.has_substring ("VALUE %"FileVersion%", %"" + {BIB_RELEASE}.Program_version + "%""))
			if l_numbers.occurrences (',') = 2 then
					-- "0.7.31" is 0,7,31,0; a patch "0.7.31.1" (2026-10-29) is 0,7,31,1
				l_numbers.append (",0")
			end
			assert_true ("PRODUCTVERSION numbers are Program_version", l_rc.has_substring ("PRODUCTVERSION " + l_numbers))
		end

	test_reference_box_reads_ranges_and_one_chapter_books
			-- NEEDLE found, 2026-10-27: "Jude 9" was read as chapter 9 and a range was not read at all.
			-- Before: both Void or wrong; after: Jude 1:9, and a range's first verse.
		local
			l_lookup: BIB_LOOKUP
		do
			create l_lookup.make (bible)
			assert_true ("Jude 9 is verse 9", attached l_lookup.place_named ("Jude 9") as al_a and then (al_a.book = 65 and al_a.chapter = 1 and al_a.verse = 9))
			assert_true ("Jude 1:9 still", attached l_lookup.place_named ("Jude 1:9") as al_b and then (al_b.chapter = 1 and al_b.verse = 9))
			assert_true ("a range opens its first verse", attached l_lookup.place_named ("Genesis 1:2-5") as al_c and then (al_c.book = 1 and al_c.chapter = 1 and al_c.verse = 2))
			assert_true ("a chapter still a chapter", attached l_lookup.place_named ("Matthew 5") as al_d and then (al_d.chapter = 5 and al_d.verse = 0))
			finish
		end

	test_reference_box_reads_spoken_forms
			-- NEEDLE's run 6 misses, 2026-10-27: a box should read what people type. Ordinal words and
			-- Roman numerals before a book, and "chapter" and "verse" written out. Before: Void.
		local
			l_lookup: BIB_LOOKUP
		do
			create l_lookup.make (bible)
			assert_true ("First Peter 4:8", attached l_lookup.place_named ("First Peter 4:8") as al_a and then (al_a.book = 60 and al_a.chapter = 4 and al_a.verse = 8))
			assert_true ("Second Peter 3:8", attached l_lookup.place_named ("Second Peter 3:8") as al_b and then (al_b.book = 61 and al_b.chapter = 3 and al_b.verse = 8))
			assert_true ("II Peter 1:1", attached l_lookup.place_named ("II Peter 1:1") as al_c and then al_c.book = 61)
			assert_true ("I Peter 1:1", attached l_lookup.place_named ("I Peter 1:1") as al_d and then al_d.book = 60)
			assert_true ("1st Peter 2:9", attached l_lookup.place_named ("1st Peter 2:9") as al_e and then (al_e.book = 60 and al_e.verse = 9))
			assert_true ("1 Pet 3:15 by prefix", attached l_lookup.place_named ("1 Pet 3:15") as al_f and then (al_f.book = 60 and al_f.verse = 15))
			assert_true ("2 Pet 1:16-18", attached l_lookup.place_named ("2 Pet 1:16-18") as al_g and then (al_g.book = 61 and al_g.verse = 16))
			assert_true ("Matthew chapter 5", attached l_lookup.place_named ("Matthew chapter 5") as al_h and then (al_h.book = 40 and al_h.chapter = 5 and al_h.verse = 0))
			assert_true ("Matthew chapter 5 verse 3", attached l_lookup.place_named ("Matthew chapter 5 verse 3") as al_i and then (al_i.chapter = 5 and al_i.verse = 3))
			assert_true ("Jude verse 9", attached l_lookup.place_named ("Jude verse 9") as al_j and then (al_j.book = 65 and al_j.chapter = 1 and al_j.verse = 9))
			finish
		end

	test_spoken_names_live_in_the_catalog
			-- Scan 50: book-name variants have one home, the catalog's forgiving lookup, and nothing
			-- reads a spoken form falsely. Before: the catalog found no book for "First Peter" while the
			-- box found one, and "Matthew verse 9" was read as chapter 9.
		local
			l_lookup: BIB_LOOKUP
			l_strict: BIB_REFERENCE_LINKER
		do
			create l_lookup.make (bible)
			create l_strict.make (bible.books)
			assert_true ("the catalog reads First Peter", bible.books.candidates_for_name ("First Peter").has (60))
			assert_true ("and II Peter", bible.books.candidates_for_name ("II Peter").has (61))
			assert_true ("but not exactly: prose stays strict", bible.books.book_named_exactly ("First Peter") = 0)
			assert_true ("a strict reader reads no spoken form", l_strict.place_in ("First Peter 4:8") = Void)
			assert_true ("verse with no chapter on a book of many chapters", l_lookup.place_named ("Matthew verse 9") = Void)
			assert_true ("Isaiah is not I saiah", attached l_lookup.place_named ("Isaiah 5") as al_a and then (al_a.book = 23 and al_a.chapter = 5))
			assert_true ("I John 4:8", attached l_lookup.place_named ("I John 4:8") as al_b and then (al_b.book = 62 and al_b.verse = 8))
			assert_true ("a typed colon after a book of many chapters is no place", l_lookup.place_named ("Matthew:5") = Void)
			finish
		end

	test_the_reference_readers_agree
			-- Scan 41: the reference box and the reference links read numbers by one rule (ranges,
			-- one-chapter books, chapters and verses 1 to 176, no verse 0) and differ only in how a
			-- book is named (the box forgives a prefix or lowercase; prose needs the exact name).
			-- Before: the box opened "Jude 999" and "Genesis 1:0", refused "Genesis 1:1.", and the
			-- linker linked "Genesis. 5 words".
		local
			l_lookup: BIB_LOOKUP
			l_linker: BIB_REFERENCE_LINKER
		do
			create l_lookup.make (bible)
			create l_linker.make (bible.books)
			assert_true ("no verse 999", l_lookup.place_named ("Jude 999") = Void)
			assert_true ("no verse 0", l_lookup.place_named ("Genesis 1:0") = Void)
			assert_true ("a closing period", attached l_lookup.place_named ("Genesis 1:1.") as al_a and then (al_a.book = 1 and al_a.chapter = 1 and al_a.verse = 1))
			assert_true ("lowercase in the box", attached l_lookup.place_named ("genesis 1:2") as al_b and then al_b.verse = 2)
			assert_true ("Gen 1 1 still", attached l_lookup.place_named ("Gen 1 1") as al_c and then (al_c.book = 1 and al_c.verse = 1))
			assert_strings_equal ("a sentence end is prose", "Genesis. 5 words", l_linker.linked ("Genesis. 5 words"))
			assert_true ("an abbreviation's period still links", l_linker.linked ("Gen. 1:1").has_substring ("](bible:1.1.1)"))
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
