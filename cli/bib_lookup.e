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
			-- Every word of the verse, in the Hebrew Bible (books 1 to 39) or the Greek New Testament.
		local
			l_words: detachable BIB_LIST_RESULT [BIB_VERSE_WORD]
			l_corpus: STRING_8
			l_surface, l_translit: STRING_32
			l_lemma: INTEGER_64
			i, l_position: INTEGER
		do
			if attached verse_parts (a_text) as al_parts then
				l_corpus := corpus_for_book (al_parts.book)
				if not bible.conc_pack.has_corpus (l_corpus) then
					note_text := {STRING_32} "The concordance has no corpus for that book."
				else
					l_words := bible.verse_word_lookup.words (create {BIB_REF}.make (al_parts.book, al_parts.chapter, al_parts.verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), l_corpus)
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
					note_text := bible.books.book (al_parts.book).name + {STRING_32} " " + al_parts.chapter.out + {STRING_32} ":" + al_parts.verse.out + {STRING_32} " in the " + bible.conc_pack.corpus_name (l_corpus) + {STRING_32} ": " + count_words (a_choices.count, "word")
				end
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
						{STRING_32} "behind %"" + a_text + {STRING_32} "%" " + ic.places.out + {STRING_32} " times in the " + bible.conc_pack.corpus_name (ic.corpus),
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
			-- The book, chapter and verse of "<book> <chapter>:<verse>"; Void when it is not one.
		local
			l_space, l_colon: INTEGER
			l_book, l_chapter, l_verse: STRING_32
			l_candidates: ARRAYED_LIST [INTEGER]
		do
			l_space := a_text.last_index_of (' ', a_text.count)
			l_colon := a_text.last_index_of (':', a_text.count)
			if l_space > 1 and l_colon > l_space + 1 and l_colon < a_text.count then
				l_book := a_text.substring (1, l_space - 1)
				l_chapter := a_text.substring (l_space + 1, l_colon - 1)
				l_verse := a_text.substring (l_colon + 1, a_text.count)
				if l_chapter.is_integer and then l_verse.is_integer and then l_chapter.to_integer > 0 and then l_verse.to_integer > 0 then
					l_candidates := bible.books.candidates_for_name (l_book)
					if not l_candidates.is_empty then
						Result := [l_candidates.first, l_chapter.to_integer, l_verse.to_integer]
					end
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
