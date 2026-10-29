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
			open: bible.is_open
			available: bible.conc_pack.is_available
			word_not_empty: not a_word.is_empty
		local
			l_lookup: BIB_LOOKUP
			l_totals: like {BIB_LOOKUP}.english_totals
		do
			create Result.make (2000)
				-- One line per Bible and headword, the books summed: the window's totals (design scan 32).
			create l_lookup.make (bible)
			l_totals := l_lookup.english_totals (a_word)
			if attached l_lookup.last_error as al_error then
				Result.append (al_error.message)
			elseif l_totals.is_empty then
				Result.append_string_general ("No original word stands behind %"")
				Result.append_string_general (a_word)
				Result.append_string_general ("%" in the concordance.")
			else
				across l_totals as ic loop
					Result.append (bible.conc_pack.corpus_name (ic.corpus))
					Result.append_string_general ("  ")
					Result.append (ic.translit)
					Result.append_string_general (" - ")
					Result.append (ic.headword)
					Result.append_string_general ("  x" + ic.places.out + "%N")
				end
			end
		ensure
			not_empty: not Result.is_empty
		end

	verse (a_book, a_chapter, a_verse: INTEGER; a_corpus: READABLE_STRING_8): STRING_32
			-- Every word of the verse in corpus `a_corpus' (empty: the book's own, as the window
			-- chooses it), each with its headword number (FR-152).
		require
			open: bible.is_open
			available: bible.conc_pack.is_available
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_positive: a_verse > 0
		local
			l_words: BIB_LIST_RESULT [BIB_VERSE_WORD]
			l_corpus: STRING_8
			i: INTEGER
		do
			create Result.make (1000)
			if a_corpus.is_empty then
				l_corpus := (create {BIB_LOOKUP}.make (bible)).corpus_for_book (a_book)
			else
				l_corpus := a_corpus.to_string_8
			end
			if not bible.conc_pack.has_corpus (l_corpus) then
				Result.append_string_general ("The concordance has no corpus " + l_corpus + ".")
			else
				l_words := bible.verse_word_lookup.words (create {BIB_REF}.make (a_book, a_chapter, a_verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), l_corpus)
				if attached l_words.error as al_error then
					Result.append (al_error.message)
				elseif l_words.count = 0 then
					Result.append_string_general ({STRING_32} "No words for that verse in the " + bible.conc_pack.corpus_name (l_corpus) + {STRING_32} ".")
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

	writings (a_query: READABLE_STRING_GENERAL; a_fuzzy: BOOLEAN; a_kind, a_within: READABLE_STRING_GENERAL): STRING_32
			-- What `a_query' finds in Larry's writings (research/20): one line a hit, its pack, address,
			-- where it stands and its words, tab-separated; then how many.
		require
			query_given: not a_query.is_empty
		local
			l_search: BIB_WRITINGS_SEARCH
			l_snippet: STRING_32
		do
			create Result.make (4000)
			l_search := bible.writings_search
			if l_search.pack_count = 0 then
				Result.append_string_general ("No commentary, frameworks or books pack is attached (--packs).")
			else
				l_search.search (a_query, a_fuzzy, a_kind, a_within)
				if not l_search.error_message.is_empty then
					Result.append_string_general ("The query does not read at " + l_search.error_position.out + ": ")
					Result.append (l_search.error_message)
				else
					across l_search.packs_without_search as ic loop
						Result.append (ic + {STRING_32} ": built before search existed; rebuild it to search it.%N")
					end
					across l_search.packs_failed as ic loop
						Result.append (ic + {STRING_32} ": its search failed.%N")
					end
					across l_search.packs_cut_short as ic loop
						Result.append (ic + {STRING_32} ": holds more than " + l_search.Max_rows_per_pack.out + {STRING_32} " matching rows; only the best are listed.%N")
					end
					across l_search.hits as ic loop
						l_snippet := ic.snippet.twin
						l_snippet.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
						Result.append (ic.pack_kind + {STRING_32} "%T" + ic.address + {STRING_32} "%T" + ic.place + {STRING_32} "%T" + l_snippet + {STRING_32} "%N")
					end
					Result.append_string_general (l_search.hits.count.out + " found.")
				end
			end
		ensure
			not_empty: not Result.is_empty
		end

	names (a_kind: READABLE_STRING_GENERAL): STRING_32
			-- Every name a reader may write for Larry's writings, one a line, tab-separated: the pack's
			-- kind, the name, the link it opens (0.7.31, for NEEDLE's tool data): each book's and essay
			-- series' title, each chapter's or essay's title, every alias, every framework spelling.
			-- `a_kind' empty for every pack, else "books", "essays" or "frameworks".
		local
			i: INTEGER
		do
			create Result.make (40000)
			across bible.text_packs as ic loop
				if ic.is_available and then (a_kind.is_empty or else ic.schema.Pack_kind.same_string_general (a_kind)) and then attached ic.books as al_books
					and then al_books.is_success
				then
					from i := 1 until i > al_books.count loop
						Result.append (name_line (ic.schema.Pack_kind, al_books.item (i).title, ic.schema.link_text (al_books.item (i).id, 0, 0)))
						if attached ic.book (al_books.item (i).id) as al_book and then al_book.is_success and then al_book.count = 1 then
							across al_book.item (1).chapters as ic_chapter loop
								if ic_chapter.chapter <= ic.schema.Max_part then
									Result.append (name_line (ic.schema.Pack_kind, ic_chapter.title, ic.schema.link_text (al_books.item (i).id, ic_chapter.chapter, 0)))
								end
							end
						end
						i := i + 1
					end
					across ic.name_links as al_name loop
						Result.append (name_line (ic.schema.Pack_kind, al_name.spelling, al_name.id))
					end
				end
			end
			if a_kind.is_empty or else a_kind.same_string ({BIB_FRAMEWORK_SCHEMA}.Pack_kind) then
				across bible.framework_packs as ic loop
					if ic.is_available and then attached ic.aliases as al_spellings and then al_spellings.is_success then
						from i := 1 until i > al_spellings.count loop
							Result.append (name_line ({BIB_FRAMEWORK_SCHEMA}.Pack_kind, al_spellings.item (i).spelling, {BIB_FRAMEWORK_SCHEMA}.Link_prefix + al_spellings.item (i).id))
							i := i + 1
						end
					end
				end
			end
			if Result.is_empty then
				Result.append_string_general ("No books, essays or frameworks pack is attached (--packs).")
			end
		ensure
			not_empty: not Result.is_empty
		end

	name_line (a_kind, a_name, a_link: READABLE_STRING_GENERAL): STRING_32
			-- "essays<TAB>JESUS 06<TAB>essay:jesus/6" and a new line; a tab or new line inside the name
			-- read as a space.
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32
			l_name.replace_substring_all ({STRING_32} "%T", {STRING_32} " ")
			l_name.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			Result := a_kind.to_string_32 + {STRING_32} "%T" + l_name + {STRING_32} "%T" + a_link.to_string_32 + {STRING_32} "%N"
		end

feature -- Constants

	Places_shown: INTEGER = 20
			-- Places the word command lists before "and N more".

end
