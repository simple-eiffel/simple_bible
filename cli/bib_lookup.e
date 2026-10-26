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
			from i := 1 until i > l_entries.count loop
				a_choices.extend (entry_choice (l_entries.item (i)))
				i := i + 1
			end
			note_text := {STRING_32} "Strong's " + l_key.text + {STRING_32} ": " + count_words (a_choices.count, "headword")
		end

	add_verse (a_text: STRING_32; a_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE])
			-- Every word of the verse, in the Hebrew Bible (books 1 to 39) or the Greek New Testament.
		local
			l_words: BIB_LIST_RESULT [BIB_VERSE_WORD]
			l_corpus: STRING_8
			l_surface, l_translit: STRING_32
			l_lemma: INTEGER_64
			i, l_position: INTEGER
		do
			if attached verse_parts (a_text) as al_parts then
				if al_parts.book <= Last_old_testament_book then
					l_corpus := "WLC-MACULA"
				else
					l_corpus := "NT-MACULA"
				end
				if bible.conc_pack.has_corpus (l_corpus) then
					l_words := bible.verse_word_lookup.words (create {BIB_REF}.make (al_parts.book, al_parts.chapter, al_parts.verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), l_corpus)
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
				else
					note_text := {STRING_32} "The concordance has no corpus for that book."
				end
			end
		end

	add_word (a_text: STRING_32; a_choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE])
			-- The headwords written or transliterated as `a_text', then the original words behind it
			-- as an English word, Bible by Bible.
		local
			l_entries: BIB_LIST_RESULT [BIB_WORD_ENTRY]
			l_rows: BIB_LIST_RESULT [BIB_ENGLISH_ROW]
			l_totals: HASH_TABLE [INTEGER_64, STRING_32]
			l_lemmas: HASH_TABLE [INTEGER_64, STRING_32]
			l_keys: ARRAYED_LIST [STRING_32]
			l_key: STRING_32
			i, l_headwords: INTEGER
		do
			l_entries := bible.conc_pack.headwords_for_text (a_text)
			from i := 1 until i > l_entries.count loop
				a_choices.extend (entry_choice (l_entries.item (i)))
				i := i + 1
			end
			l_headwords := a_choices.count
			l_rows := bible.english_index.rows (a_text)
			create l_totals.make (l_rows.count)
			create l_lemmas.make (l_rows.count)
			create l_keys.make (l_rows.count)
			from i := 1 until i > l_rows.count loop
				l_key := l_rows.item (i).headword + {STRING_32} "%T" + bible.conc_pack.corpus_name (l_rows.item (i).bible)
				if l_totals.has (l_key) then
					l_totals.force (l_totals.item (l_key) + l_rows.item (i).count, l_key)
				else
					l_totals.force (l_rows.item (i).count, l_key)
					l_lemmas.force (l_rows.item (i).lemma_id, l_key)
					l_keys.extend (l_key)
				end
				i := i + 1
			end
			across l_keys as ic loop
				a_choices.extend (create {BIB_LOOKUP_CHOICE}.make (ic.substring (1, ic.index_of ('%T', 1) - 1),
					{STRING_32} "behind %"" + a_text + {STRING_32} "%" " + l_totals.item (ic).out + {STRING_32} " times in the " + ic.substring (ic.index_of ('%T', 1) + 1, ic.count),
					l_lemmas.item (ic)))
			end
			if a_choices.is_empty then
				note_text := {STRING_32} "Nothing found for %"" + a_text + {STRING_32} "%"."
			else
				note_text := {STRING_32} "%"" + a_text + {STRING_32} "%": " + count_words (l_headwords, "headword") + {STRING_32} ", " + count_words (a_choices.count - l_headwords, "original word") + {STRING_32} " behind it in English"
			end
		end

feature {NONE} -- Implementation

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
