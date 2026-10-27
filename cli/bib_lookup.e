note
	description: "[
		What a reader types into a lookup box, turned into choices (FR-150 to FR-153):
		a Strong's number ("H1254"), a verse ("Gen 1:1", "Matthew 5:3": every word, a
		prefix and its word joined as one choice), or a word (Hebrew, Greek or plain
		letters: the headwords; English: the original words behind it). Face-neutral,
		so the window and the tests share it; it reads the engine only.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LOOKUP

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- Lookups over `a_bible'.
		require
			open: a_bible.is_open
		do
			bible := a_bible
			create note_text.make_empty
		ensure
			bible_set: bible = a_bible
		end

feature -- Access

	bible: SIMPLE_BIBLE
			-- The engine asked.

	note_text: STRING_32
			-- What the last `choices_for' understood, or why it found nothing, for a status line.

	last_error: detachable BIB_ERROR
			-- Why the last lookup's engine query failed; Void when none did. A failure is told as
			-- the database's own words, never as "Nothing found" (design scan 32).

	last_verse: detachable TUPLE [book, chapter, verse: INTEGER]
			-- The verse the last `choices_for' named ("Gen 1:1"); Void when it named none.

	english_corpus_for_version (a_version: READABLE_STRING_8): STRING_8
			-- The concordance's per-word English corpus that is version `a_version' ("ENG-KJV" for
			-- "KJV"), so a word clicked in its text finds the original behind it; empty when none is.
		do
			if a_version.same_string ("KJV") then
				Result := "ENG-KJV"
			elseif a_version.same_string ("BSB") then
				Result := "ENG-BSB"
			else
				create Result.make_empty
			end
			if not Result.is_empty and then not bible.conc_pack.has_corpus (Result) then
				create Result.make_empty
			end
		ensure
			known_or_empty: not Result.is_empty implies bible.conc_pack.has_corpus (Result)
		end

	original_corpus_for_version (a_version: READABLE_STRING_8; a_book: INTEGER): STRING_8
			-- The tagged corpus a Hebrew or Greek version's words are matched in (the Hebrew Bible for
			-- WLC and MapM, the Greek New Testament for TR, Byz and WH, the Septuagint for LXX); empty
			-- when `a_version' is no original-language text the concordance tags.
		require
			book_positive: a_book > 0
		do
			if a_version.same_string ("WLC") or a_version.same_string ("MapM") then
				Result := "WLC-MACULA"
			elseif a_version.same_string ("TR") or a_version.same_string ("Byz") or a_version.same_string ("WH") then
				Result := "NT-MACULA"
			elseif a_version.same_string ("LXX") and a_book <= Last_old_testament_book then
				Result := "LXX-RAHLFS"
			else
				create Result.make_empty
			end
			if not Result.is_empty and then not bible.conc_pack.has_corpus (Result) then
				create Result.make_empty
			end
		ensure
			known_or_empty: not Result.is_empty implies bible.conc_pack.has_corpus (Result)
		end

	corpus_for_book (a_book: INTEGER): STRING_8
			-- The corpus a verse of book `a_book' is read in: the Hebrew Bible for books 1 to 39,
			-- the Greek New Testament after (one rule for every face, design scan 32).
		require
			book_positive: a_book > 0
		do
			if a_book <= Last_old_testament_book then
				Result := "WLC-MACULA"
			else
				Result := "NT-MACULA"
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Lookup

	choices_for (a_text: READABLE_STRING_GENERAL): ARRAYED_LIST [BIB_LOOKUP_CHOICE]
			-- The choices `a_text' leads to; empty, with the reason in `note_text', when none.
		require
			available: bible.conc_pack.is_available
		local
			l_text: STRING_32
			l_key: BIB_STRONGS_KEY
		do
			create Result.make (20)
			last_error := Void
			last_verse := Void
			l_text := a_text.to_string_32
			l_text.left_adjust
			l_text.right_adjust
			create l_key.make_from_text ("H1")
			if l_text.is_empty then
				note_text := {STRING_32} "Type a Hebrew, Greek or English word, a verse such as Gen 1:1, or a Strong's number such as H1254."
			elseif l_key.is_strongs_text (l_text) then
				add_strongs (l_text, Result)
			elseif is_verse_text (l_text) then
				add_verse (l_text, Result)
			else
				add_word (l_text, Result)
			end
		ensure
			reason_when_empty: Result.is_empty implies not note_text.is_empty
		end

	verse_choices (a_book, a_chapter, a_verse: INTEGER): ARRAYED_LIST [BIB_LOOKUP_CHOICE]
			-- Every word of verse `a_book' `a_chapter':`a_verse' in its book's corpus, a prefix
			-- joined to its word; the reason in `note_text' (the reading pane's verse click).
		require
			available: bible.conc_pack.is_available
			book_known: bible.books.has_book (a_book)
			chapter_positive: a_chapter > 0
			verse_positive: a_verse > 0
		do
			create Result.make (20)
			last_error := Void
			add_verse_words (a_book, a_chapter, a_verse, Result)
		ensure
			reason_when_empty: Result.is_empty implies not note_text.is_empty
		end

	place_named (a_text: READABLE_STRING_GENERAL): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The place a reference box holds: "John 3:16", "Gen 1 1", "John 3" or "1 John 4" (verse 0:
			-- the whole chapter); Void when the text names no book the catalog knows.
		local
			l_text, l_book: STRING_32
			l_words: LIST [STRING_32]
			l_last, l_before: STRING_32
			l_colon: INTEGER
		do
			l_text := a_text.to_string_32
			l_text.left_adjust
			l_text.right_adjust
			l_words := l_text.split (' ')
			from until l_words.is_empty or else not l_words.last.is_empty loop
				l_words.finish
				l_words.remove
			end
			if l_words.count >= 2 then
				l_last := l_words.last
				l_before := l_words.i_th (l_words.count - 1)
				l_colon := l_last.index_of (':', 1)
				if l_colon > 1 and l_colon < l_last.count then
					l_book := joined_words (l_words, l_words.count - 1)
					Result := resolved (l_book, l_last.substring (1, l_colon - 1), l_last.substring (l_colon + 1, l_last.count))
				elseif l_words.count >= 3 and then l_last.is_integer and then l_before.is_integer then
					Result := resolved (joined_words (l_words, l_words.count - 2), l_before, l_last)
				end
				if Result = Void and then l_last.is_integer then
					Result := resolved (joined_words (l_words, l_words.count - 1), l_last, "0")
				end
			end
		ensure
			place_positive: attached Result implies (Result.book > 0 and Result.chapter > 0 and Result.verse >= 0)
		end

	is_verse_text (a_text: READABLE_STRING_32): BOOLEAN
			-- Is `a_text' "<book> <chapter>:<verse>" with a book the catalog knows?
		do
			Result := attached verse_parts (a_text) as al_parts and then al_parts.book > 0
		end

feature {NONE} -- Kinds of lookup

	add_strongs (a_text: STRING_32; a_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE])
			-- The headwords behind a Strong's number (through lemma_xref only, FR-153).
		local
			l_key: BIB_STRONGS_KEY
			l_entries: BIB_LIST_RESULT [BIB_WORD_ENTRY]
			i: INTEGER
		do
			create l_key.make_from_text (a_text)
			l_entries := bible.conc_pack.headwords_for_strongs (l_key)
			note_failure (l_entries)
			if last_error = Void then
				from i := 1 until i > l_entries.count loop
					a_choices.extend (entry_choice (l_entries.item (i)))
					i := i + 1
				end
				note_text := {STRING_32} "Strong's " + l_key.text + {STRING_32} ": " + count_words (a_choices.count, "headword")
			end
		end

	add_verse (a_text: STRING_32; a_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE])
			-- Every word of the verse `a_text' names.
		do
			if attached verse_parts (a_text) as al_parts then
				last_verse := [al_parts.book, al_parts.chapter, al_parts.verse]
				add_verse_words (al_parts.book, al_parts.chapter, al_parts.verse, a_choices)
			end
		end

	add_verse_words (a_book, a_chapter, a_verse: INTEGER; a_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE])
			-- Every word of the verse, in the Hebrew Bible (books 1 to 39) or the Greek New Testament.
		local
			l_words: detachable BIB_LIST_RESULT [BIB_VERSE_WORD]
			l_corpus: STRING_8
			l_surface, l_translit: STRING_32
			l_lemma: INTEGER_64
			i, l_position: INTEGER
		do
			l_corpus := corpus_for_book (a_book)
			if not bible.conc_pack.has_corpus (l_corpus) then
				note_text := {STRING_32} "The concordance has no corpus for that book."
			else
				l_words := bible.verse_word_lookup.words (create {BIB_REF}.make (a_book, a_chapter, a_verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), l_corpus)
				note_failure (l_words)
			end
			if l_words /= Void and then last_error = Void then
					-- A word's morphemes share its position: join them into one choice that opens the word.
				from i := 1 until i > l_words.count loop
					l_position := l_words.item (i).position
					create l_surface.make_empty
					create l_translit.make_empty
					l_lemma := 0
					from until i > l_words.count or else l_words.item (i).position /= l_position loop
						l_surface.append (l_words.item (i).surface)
						if not l_translit.is_empty then
							l_translit.append_character ('-')
						end
						l_translit.append (l_words.item (i).translit)
						if l_words.item (i).has_door then
							l_lemma := l_words.item (i).lemma_id
						end
						i := i + 1
					end
					if l_surface.is_empty then
						l_surface := {STRING_32} "(not written)"
					end
					a_choices.extend (create {BIB_LOOKUP_CHOICE}.make (l_surface, l_translit, l_lemma))
				end
				note_text := bible.books.book (a_book).name + {STRING_32} " " + a_chapter.out + {STRING_32} ":" + a_verse.out + {STRING_32} " in the " + bible.conc_pack.corpus_short_name (l_corpus) + {STRING_32} ": " + count_words (a_choices.count, "word")
			end
		end

	add_word (a_text: STRING_32; a_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE])
			-- The headwords written or transliterated as `a_text', then the original words behind it
			-- as an English word, Bible by Bible.
		local
			l_entries: BIB_LIST_RESULT [BIB_WORD_ENTRY]
			i, l_headwords: INTEGER
		do
			l_entries := bible.conc_pack.headwords_for_text (a_text)
			note_failure (l_entries)
			from i := 1 until i > l_entries.count loop
				a_choices.extend (entry_choice (l_entries.item (i)))
				i := i + 1
			end
			l_headwords := a_choices.count
			if last_error = Void then
				across english_totals (a_text) as ic loop
					a_choices.extend (create {BIB_LOOKUP_CHOICE}.make (ic.headword,
						{STRING_32} "behind %"" + a_text + {STRING_32} "%" " + ic.places.out + {STRING_32} " times in the " + bible.conc_pack.corpus_short_name (ic.corpus),
						ic.lemma_id))
				end
			end
			if last_error /= Void then
					-- `note_failure' already told why.
			elseif a_choices.is_empty then
				note_text := {STRING_32} "Nothing found for %"" + a_text + {STRING_32} "%"."
			else
				note_text := {STRING_32} "%"" + a_text + {STRING_32} "%": " + count_words (l_headwords, "headword") + {STRING_32} ", " + count_words (a_choices.count - l_headwords, "original word") + {STRING_32} " behind it in English"
			end
		end

feature -- English

	english_totals (a_word: READABLE_STRING_GENERAL): ARRAYED_LIST [TUPLE [headword, translit: STRING_32; corpus: STRING_8; lemma_id, places: INTEGER_64]]
			-- The original words behind English `a_word': one per headword and Bible, the books
			-- summed, in the order first met; empty, with `last_error' set, when the index failed.
			-- The window's choices and the command line's lines both come from here (design scan 32).
		require
			available: bible.conc_pack.is_available
		local
			l_rows: BIB_LIST_RESULT [BIB_ENGLISH_ROW]
			l_seen: HASH_TABLE [INTEGER, STRING_32]
			l_key: STRING_32
			i: INTEGER
		do
			l_rows := bible.english_index.rows (a_word)
			note_failure (l_rows)
			create Result.make (l_rows.count)
			create l_seen.make (l_rows.count)
			from i := 1 until i > l_rows.count loop
				l_key := l_rows.item (i).headword + {STRING_32} "%T" + l_rows.item (i).bible.to_string_32
				if l_seen.has (l_key) then
					Result.i_th (l_seen.item (l_key)).places := Result.i_th (l_seen.item (l_key)).places + l_rows.item (i).count
				else
					Result.extend ([l_rows.item (i).headword, l_rows.item (i).translit, l_rows.item (i).bible, l_rows.item (i).lemma_id, l_rows.item (i).count])
					l_seen.force (Result.count, l_key)
				end
				i := i + 1
			end
		ensure
			empty_on_failure: last_error /= Void implies Result.is_empty
		end

feature {NONE} -- Implementation

	note_failure (a_result: BIB_ENGINE_RESULT)
			-- When `a_result' failed, keep its error and tell it in `note_text'.
		do
			if attached a_result.error as al_error then
				last_error := al_error
				note_text := al_error.message.twin
			end
		ensure
			told: attached a_result.error as al_error implies (last_error = al_error and note_text.same_string (al_error.message))
		end

	Last_old_testament_book: INTEGER = 39
			-- The vault's book ids: Genesis 1 to Malachi 39, Matthew 40 to Revelation 66 (FR-105).

	entry_choice (a_entry: BIB_WORD_ENTRY): BIB_LOOKUP_CHOICE
			-- A headword as a choice: the word, then its transliteration and how often.
		do
			create Result.make (a_entry.headword, a_entry.translit + {STRING_32} "  (" + a_entry.token_total.out + {STRING_32} " places)", a_entry.lemma_id)
		end

	verse_parts (a_text: READABLE_STRING_32): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The book, chapter and verse a text names; Void when it names no verse (a whole chapter
			-- is not one). One parser for both boxes (design scan 34: three had drifted apart).
		do
			if attached place_named (a_text) as al_place and then al_place.verse > 0 then
				Result := al_place
			end
		ensure
			a_verse: attached Result implies Result.verse > 0
		end

	joined_words (a_words: LIST [STRING_32]; a_count: INTEGER): STRING_32
			-- The first `a_count' words of `a_words', joined by spaces.
		local
			i: INTEGER
		do
			create Result.make (20)
			from i := 1 until i > a_count or i > a_words.count loop
				if not Result.is_empty then
					Result.append_character (' ')
				end
				Result.append (a_words.i_th (i))
				i := i + 1
			end
		end

	resolved (a_book, a_chapter, a_verse: STRING_32): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The place, when `a_book' is a known book and the numbers are whole (verse 0 allowed).
		local
			l_candidates: ARRAYED_LIST [INTEGER]
		do
			if not a_book.is_empty and then a_chapter.is_integer and then a_verse.is_integer
				and then a_chapter.to_integer > 0 and then a_verse.to_integer >= 0
			then
				l_candidates := bible.books.candidates_for_name (a_book)
				if not l_candidates.is_empty then
					Result := [l_candidates.first, a_chapter.to_integer, a_verse.to_integer]
				end
			end
		end

	count_words (a_count: INTEGER; a_noun: STRING_8): STRING_32
			-- "1 headword", "3 headwords".
		do
			Result := a_count.out.to_string_32 + {STRING_32} " " + a_noun.to_string_32
			if a_count /= 1 then
				Result.append_character ('s')
			end
		end

end
