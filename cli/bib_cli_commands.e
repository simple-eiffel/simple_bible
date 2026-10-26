note
	description: "[
		The command line's commands as text (Phase 4, Task 9; FR-061): word view,
		English lookup, verse lookup and Strong's lookup over an open SIMPLE_BIBLE.
		No argument parsing and no printing here, so the tests read the same text
		the program prints. Readers see corpus names through the engine's own
		labels; the codes appear only where the command line takes them as input.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CLI_COMMANDS

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
			-- Commands over `a_bible'.
		require
			open: a_bible.is_open
		do
			bible := a_bible
		ensure
			bible_set: bible = a_bible
		end

feature -- Access

	bible: SIMPLE_BIBLE
			-- The engine the commands ask.

	banner: STRING_32
			-- The first line: the edition the pack names (FR-157), or why there is no concordance.
		require
			open: bible.is_open
		do
			if bible.conc_pack.is_available then
				Result := bible.conc_pack.edition_label
			elseif attached bible.conc_error as al_error then
				Result := {STRING_32} "No concordance: " + al_error.message
			else
				Result := {STRING_32} "No concordance pack is configured."
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Commands

	word (a_lemma_id: INTEGER_64; a_corpus: READABLE_STRING_8): STRING_32
			-- The word view of headword `a_lemma_id' in corpus `a_corpus' (empty: the corpus where it occurs most).
		require
			available: bible.conc_pack.is_available
			id_positive: a_lemma_id > 0
		local
			l_corpus: STRING_8
			l_view: BIB_WORD_VIEW
			i: INTEGER
		do
			create Result.make (2000)
			if attached bible.conc_pack.word_entry (a_lemma_id) as al_entry then
				l_corpus := a_corpus.to_string_8
				if l_corpus.is_empty then
						-- The corpus where the headword occurs most (its provenance).
					l_corpus := bible.conc_pack.corpus_of (al_entry.provenance)
				end
				if not bible.conc_pack.has_corpus (l_corpus) then
					Result.append_string_general ("The concordance has no corpus " + l_corpus + ".")
				else
					l_view := bible.word_lookup.view (a_lemma_id, l_corpus)
					if attached l_view.error as al_error then
						Result.append (al_error.message)
					elseif attached l_view.entry as al_heading and attached l_view.place_total as al_total and attached l_view.first_places as al_places then
						Result.append (al_heading.translit)
						Result.append_string_general (" - ")
						Result.append (al_heading.headword)
						if not al_heading.pron.is_empty then
							Result.append_string_general ("  (" )
							Result.append (al_heading.pron)
							Result.append_string_general (")")
						end
						Result.append_string_general ("%N" + al_total.value.out + " places in " + l_corpus + "%N")
						from i := 1 until i > al_places.count or i > Places_shown loop
							Result.append_string_general ("  ")
							Result.append (al_places.item (i).reference_text)
							Result.append_string_general ("  ")
							Result.append (al_places.item (i).surface)
							Result.append_string_general ("  ")
							Result.append (al_places.item (i).translit)
							Result.append_string_general ("%N")
							i := i + 1
						end
						if al_total.value > Places_shown then
							Result.append_string_general ("  ... and " + (al_total.value - Places_shown).out + " more%N")
						end
					end
				end
			else
				Result.append_string_general ("The concordance has no Hebrew, Aramaic or Greek headword " + a_lemma_id.out + ".")
			end
		ensure
			not_empty: not Result.is_empty
		end

	english (a_word: READABLE_STRING_GENERAL): STRING_32
			-- The original words behind English `a_word', Bible by Bible, with counts (FR-151).
		require
			available: bible.conc_pack.is_available
			word_not_empty: not a_word.is_empty
		local
			l_rows: BIB_LIST_RESULT [BIB_ENGLISH_ROW]
			l_totals: HASH_TABLE [INTEGER_64, STRING_32]
			l_keys: ARRAYED_LIST [STRING_32]
			l_key: STRING_32
			i: INTEGER
		do
			create Result.make (2000)
			l_rows := bible.english_index.rows (a_word)
			if attached l_rows.error as al_error then
				Result.append (al_error.message)
			elseif l_rows.count = 0 then
				Result.append_string_general ("No original word stands behind %"")
				Result.append_string_general (a_word)
				Result.append_string_general ("%" in the concordance.")
			else
					-- One line per Bible and headword, the books summed.
				create l_totals.make (l_rows.count)
				create l_keys.make (l_rows.count)
				from i := 1 until i > l_rows.count loop
					l_key := l_rows.item (i).bible.to_string_32 + {STRING_32} "  " + l_rows.item (i).translit + {STRING_32} " - " + l_rows.item (i).headword
					if l_totals.has (l_key) then
						l_totals.force (l_totals.item (l_key) + l_rows.item (i).count, l_key)
					else
						l_totals.force (l_rows.item (i).count, l_key)
						l_keys.extend (l_key)
					end
					i := i + 1
				end
				across l_keys as ic loop
					Result.append (ic)
					Result.append_string_general ("  x" + l_totals.item (ic).out + "%N")
				end
			end
		ensure
			not_empty: not Result.is_empty
		end

	verse (a_book, a_chapter, a_verse: INTEGER; a_corpus: READABLE_STRING_8): STRING_32
			-- Every word of the verse in corpus `a_corpus', each with its headword number (FR-152).
		require
			available: bible.conc_pack.is_available
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_positive: a_verse > 0
		local
			l_words: BIB_LIST_RESULT [BIB_VERSE_WORD]
			i: INTEGER
		do
			create Result.make (1000)
			if not bible.conc_pack.has_corpus (a_corpus) then
				Result.append_string_general ("The concordance has no corpus " + a_corpus + ".")
			else
				l_words := bible.verse_word_lookup.words (create {BIB_REF}.make (a_book, a_chapter, a_verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), a_corpus)
				if attached l_words.error as al_error then
					Result.append (al_error.message)
				elseif l_words.count = 0 then
					Result.append_string_general ("No words for that verse in " + a_corpus + ".")
				else
					from i := 1 until i > l_words.count loop
						Result.append_string_general (l_words.item (i).position.out + "  ")
						Result.append (l_words.item (i).surface)
						Result.append_string_general ("  ")
						Result.append (l_words.item (i).translit)
						if l_words.item (i).has_door then
							Result.append_string_general ("  [word " + l_words.item (i).lemma_id.out + "]")
						end
						Result.append_string_general ("%N")
						i := i + 1
					end
				end
			end
		ensure
			not_empty: not Result.is_empty
		end

	strongs (a_text: READABLE_STRING_GENERAL): STRING_32
			-- The headwords behind a Strong's number (FR-153: through lemma_xref only).
		require
			available: bible.conc_pack.is_available
		local
			l_key: BIB_STRONGS_KEY
			l_entries: BIB_LIST_RESULT [BIB_WORD_ENTRY]
			i: INTEGER
		do
			create Result.make (500)
			create l_key.make_from_text ("H1")
			if not l_key.is_strongs_text (a_text) then
				Result.append_string_general ("Not a Strong's number: ")
				Result.append_string_general (a_text)
			else
				create l_key.make_from_text (a_text)
				l_entries := bible.conc_pack.headwords_for_strongs (l_key)
				if attached l_entries.error as al_error then
					Result.append (al_error.message)
				elseif l_entries.count = 0 then
					Result.append_string_general ("No headword behind " + l_key.text.to_string_8 + ".")
				else
					from i := 1 until i > l_entries.count loop
						Result.append_string_general ("[word " + l_entries.item (i).lemma_id.out + "]  ")
						Result.append (l_entries.item (i).translit)
						Result.append_string_general (" - ")
						Result.append (l_entries.item (i).headword)
						Result.append_string_general ("  (" + l_entries.item (i).token_total.out + " places)%N")
						i := i + 1
					end
				end
			end
		ensure
			not_empty: not Result.is_empty
		end

feature -- Constants

	Places_shown: INTEGER = 20
			-- Places the word command lists before "and N more".

end
