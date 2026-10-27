note
	description: "[
		Bible references in Markdown made into links a reading pane follows:
		"Numbers 14:11" becomes [Numbers 14:11](bible:4.14.11), "Jude 5" (a book
		of one chapter: the number is the verse) [Jude 5](bible:65.1.5), and
		"Matthew 5" the chapter, [Matthew 5](bible:40.5.0). A range keeps its
		text and links to its first verse. Larry's rule (2026-02-15): every
		reference is a doorway to its content; first used on the Commentaries
		tab (2026-10-27), whose text names references in plain words.

		WHAT COUNTS AS A REFERENCE: a book named exactly as content.db's catalog
		names it (its name or code, "Genesis" or "Gen", any case after a
		capital), followed by a chapter number, then perhaps ":verse" and a
		range. Prose is never touched by a guess ("is 5" is not Isaiah 5, and
		"Numbers. 5 people" ends a sentence), nor text already inside a link or
		inline code.

		ONE READER FOR BOTH FACES (scan 41): the reference box reads with
		`make_forgiving' and `place_in' - the same numbers, ranges, one-chapter
		books and bounds (1 to 176, never verse 0) - and differs only in naming
		a book: a box forgives a prefix or lowercase ("rom 8"), prose needs the
		exact name. The link target is written and read here only (`target_text',
		`target_place'). An interim reader until the reference grammar
		(research/15) is vendored.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REFERENCE_LINKER

create
	make,
	make_forgiving

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
			-- A reader for prose: a book named exactly.
		do
			books := a_books
		ensure
			books_set: books = a_books
			strict: not is_forgiving
		end

	make_forgiving (a_books: BIB_BOOK_CATALOG)
			-- A reader for a reference box: a book named by a prefix, in any case.
		do
			books := a_books
			is_forgiving := True
		ensure
			books_set: books = a_books
			forgiving: is_forgiving
		end

feature -- Access

	books: BIB_BOOK_CATALOG

	is_forgiving: BOOLEAN
			-- Does a book name a prefix or lowercase may give (the reference box)?

feature -- Places

	place_in (a_text: READABLE_STRING_GENERAL): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The one place `a_text' names, whole: "John 3:16", "John 3:16-18", "Jude 9", "John 3"
			-- (verse 0), "Gen 1 1", with one closing period allowed; Void when it names none or
			-- holds more. A forgiving reader also reads it as typed or spoken (`spoken_form').
		local
			l_text: STRING_32
			l_words: LIST [STRING_32]
		do
			l_text := a_text.to_string_32
			l_text.left_adjust
			l_text.right_adjust
			if l_text.ends_with ({STRING_32} ".") then
				l_text.remove_tail (1)
			end
			if is_forgiving then
				l_text := spoken_form (l_text)
			end
				-- "Gen 1 1": two numbers at the end are a chapter and a verse.
			l_words := l_text.split (' ')
			if l_words.count >= 3 and then l_words.last.is_natural and then l_words.i_th (l_words.count - 1).is_natural then
				l_text := l_text.substring (1, l_text.count - l_words.last.count - 1) + {STRING_32} ":" + l_words.last
			end
			if not l_text.is_empty and then attached reference_at (l_text, 1) as al_found and then al_found.last = l_text.count then
				Result := [al_found.book, al_found.chapter, al_found.verse]
			end
		ensure
			a_verse_or_a_chapter: attached Result as r implies (r.chapter >= 1 and r.chapter <= Max_number and r.verse >= 0 and r.verse <= Max_number)
		end

	target_text (a_book, a_chapter, a_verse: INTEGER): STRING_32
			-- The link target of a place: "bible:65.1.5" (verse 0: the chapter).
		do
			Result := Target_prefix + a_book.out + {STRING_32} "." + a_chapter.out + {STRING_32} "." + a_verse.out
		ensure
			read_back: attached target_place (Result) as r and then (r.book = a_book and r.chapter = a_chapter and r.verse = a_verse)
		end

	target_place (a_target: READABLE_STRING_GENERAL): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The place a "bible:" link target names; Void for any other target.
		local
			l_parts: LIST [STRING_32]
		do
			if a_target.to_string_32.starts_with (Target_prefix) then
				l_parts := a_target.to_string_32.substring (Target_prefix.count + 1, a_target.count).split ('.')
				if l_parts.count = 3 and then l_parts.i_th (1).is_integer and then l_parts.i_th (2).is_integer and then l_parts.i_th (3).is_integer then
					Result := [l_parts.i_th (1).to_integer, l_parts.i_th (2).to_integer, l_parts.i_th (3).to_integer]
				end
			end
		end

	Target_prefix: STRING_32 = "bible:"

feature -- Linking

	linked (a_markdown: READABLE_STRING_GENERAL): STRING_32
			-- `a_markdown' with each Bible reference outside links and inline code made a link.
		local
			l_text: STRING_32
			i, l_end: INTEGER
			l_in_code, l_in_label, l_in_target: BOOLEAN
			l_found: like reference_at
		do
			l_text := a_markdown.to_string_32
			create Result.make (l_text.count + l_text.count // 8)
			from i := 1 until i > l_text.count loop
				if l_in_code then
					l_in_code := l_text [i] /= '`'
					Result.append_character (l_text [i])
					i := i + 1
				elseif l_in_target then
					l_in_target := l_text [i] /= ')'
					Result.append_character (l_text [i])
					i := i + 1
				elseif l_in_label then
					if l_text [i] = ']' then
						l_in_label := False
						l_in_target := i < l_text.count and then l_text [i + 1] = '('
					end
					Result.append_character (l_text [i])
					i := i + 1
				elseif l_text [i] = '`' then
					l_in_code := True
					Result.append_character (l_text [i])
					i := i + 1
				elseif l_text [i] = '[' then
					l_in_label := True
					Result.append_character (l_text [i])
					i := i + 1
				else
					l_found := Void
					if i = 1 or else not is_word_character (l_text [i - 1]) then
						l_found := reference_at (l_text, i)
					end
					if attached l_found as al_found then
						l_end := al_found.last
						Result.append ({STRING_32} "[" + l_text.substring (i, l_end) + {STRING_32} "](" + target_text (al_found.book, al_found.chapter, al_found.verse) + {STRING_32} ")")
						i := l_end + 1
					else
						Result.append_character (l_text [i])
						i := i + 1
					end
				end
			end
		ensure
			nothing_lost: Result.count >= a_markdown.count
		end

	reference_at (a_text: STRING_32; a_start: INTEGER): detachable TUPLE [last, book, chapter, verse: INTEGER]
			-- The reference starting at `a_start' (its last character, book, chapter and verse; verse 0
			-- for a whole chapter); Void when none starts there.
		require
			in_text: a_start >= 1 and a_start <= a_text.count
		local
			l_words: ARRAYED_LIST [TUPLE [first, last: INTEGER]]
			l_pos, l_word_end, k, l_book, l_number_start: INTEGER
			l_name: STRING_32
			l_had_period: BOOLEAN
		do
				-- Up to three words ("1 John", "Song of Songs") that may name a book.
			create l_words.make (3)
			from l_pos := a_start until l_words.count = 3 or l_pos > a_text.count or else not is_word_character (a_text [l_pos]) loop
				l_word_end := l_pos
				from until l_word_end + 1 > a_text.count or else not is_word_character (a_text [l_word_end + 1]) loop
					l_word_end := l_word_end + 1
				end
				l_words.extend ([l_pos, l_word_end])
				if l_word_end + 2 <= a_text.count and then a_text [l_word_end + 1] = ' ' then
					l_pos := l_word_end + 2
				else
					l_pos := a_text.count + 1
				end
			end
			from k := l_words.count until k < 1 or Result /= Void loop
				l_name := a_text.substring (a_start, l_words.i_th (k).last)
				l_had_period := l_name.ends_with ({STRING_32} ".")
				if l_had_period then
					l_name.remove_tail (1)
				end
				l_book := book_named (l_name)
				if l_book > 0 and l_had_period and then books.book (l_book).name.as_lower.same_string (l_name.as_lower) then
						-- "Numbers. 5 people": a book's whole name before a period ends a sentence; only
						-- an abbreviation ("Gen.") takes a period (scan 41).
					l_book := 0
				end
				l_number_start := l_words.i_th (k).last + 2
				if l_book > 0 and then l_number_start <= a_text.count and then a_text [l_number_start - 1] = ' ' and then a_text [l_number_start].is_digit then
					Result := numbers_at (a_text, l_number_start, l_book)
				end
				k := k - 1
			end
		ensure
			after_start: attached Result as r implies r.last > a_start
		end

feature {NONE} -- Implementation

	book_named (a_name: STRING_32): INTEGER
			-- The book `a_name' names: exactly, written as a name is written (prose); or by a prefix
			-- or in any case, the first candidate (`is_forgiving'); 0 when none.
		do
			if is_forgiving then
				if not a_name.is_empty and then attached books.candidates_for_name (a_name) as al_candidates and then not al_candidates.is_empty then
					Result := al_candidates.first
				end
			elseif starts_like_a_name (a_name) then
				Result := books.book_named_exactly (a_name)
			end
		end

	numbers_at (a_text: STRING_32; a_start, a_book: INTEGER): detachable TUPLE [last, book, chapter, verse: INTEGER]
			-- "14:11", "5-7", "2:4-9" or "5" at `a_start' after book `a_book'.
		local
			i, l_first, l_second: INTEGER
			l_has_colon: BOOLEAN
		do
			i := a_start
			from until i > a_text.count or else not a_text [i].is_digit loop
				l_first := l_first * 10 + a_text [i].code - ('0').code
				i := i + 1
			end
			if i + 1 <= a_text.count and then a_text [i] = ':' and then a_text [i + 1].is_digit then
				l_has_colon := True
				i := i + 1
				from until i > a_text.count or else not a_text [i].is_digit loop
					l_second := l_second * 10 + a_text [i].code - ('0').code
					i := i + 1
				end
			end
				-- A range ("5-7", "2:4-9", "5:1-6:2") keeps its text; its link opens the first verse.
			if i + 1 <= a_text.count and then (a_text [i] = '-' or a_text [i].natural_32_code = 0x2013) and then a_text [i + 1].is_digit then
				i := i + 1
				from until i > a_text.count or else not (a_text [i].is_digit or (a_text [i] = ':' and then i < a_text.count and then a_text [i + 1].is_digit)) loop
					i := i + 1
				end
			end
			if l_has_colon then
				if l_first >= 1 and l_first <= Max_number and l_second >= 1 and l_second <= Max_number then
					Result := [i - 1, a_book, l_first, l_second]
				end
			elseif books.is_single_chapter_book (a_book) then
				if l_first >= 1 and l_first <= Max_number then
					Result := [i - 1, a_book, 1, l_first]
				end
			elseif l_first >= 1 and l_first <= Max_number then
				Result := [i - 1, a_book, l_first, 0]
			end
		end

	starts_like_a_name (a_name: STRING_32): BOOLEAN
			-- Does `a_name' begin as a book name is written: a capital, or a digit, a space and a
			-- capital ("1 John")?
		do
			if not a_name.is_empty then
				if a_name [1].is_upper then
					Result := True
				elseif a_name [1].is_digit and then a_name.count >= 3 and then a_name [2] = ' ' then
					Result := a_name [3].is_upper
				end
			end
		end

	is_word_character (a_character: CHARACTER_32): BOOLEAN
			-- A letter, digit or period inside a book name or abbreviation.
		do
			Result := a_character.is_alpha or a_character.is_digit or a_character = '.'
		end

	Max_number: INTEGER = 176
			-- No chapter or verse number exceeds Psalm 119's 176.

feature {NONE} -- Spoken forms

	spoken_form (a_text: STRING_32): STRING_32
			-- `a_text' with "chapter" and "verse" written out read as a reference box reads numbers
			-- (2026-10-27, from NEEDLE's run 6 misses): "Mark chapter 4", "John chapter 3 verse 16".
			-- A bare "verse N" after a book names a verse only in a book of one chapter ("Jude verse
			-- 9"); elsewhere it stays unread (design scan 50: "John verse 9" was read as chapter 9).
			-- Ordinal words and Roman numerals before a book are the catalog's
			-- (BIB_BOOK_CATALOG.candidates_for_name).
		local
			l_lower, l_book: STRING_32
			l_colon: INTEGER
		do
			Result := a_text.twin
			across Spelled_parts as ic loop
				from
					l_lower := Result.as_lower
				until
					not l_lower.has_substring (ic.word)
				loop
					Result := Result.substring (1, l_lower.substring_index (ic.word, 1) - 1) + ic.mark + Result.substring (l_lower.substring_index (ic.word, 1) + ic.word.count, Result.count)
					l_lower := Result.as_lower
				end
			end
			l_colon := Result.index_of (':', 1)
			if l_colon > 1 then
				l_book := Result.substring (1, l_colon - 1)
				l_book.right_adjust
				if not l_book.is_empty and then not l_book [l_book.count].is_digit and then attached books.candidates_for_name (l_book) as al_books and then al_books.count = 1 and then books.is_single_chapter_book (al_books.first) then
						-- "Jude:9": a lone number after a one-chapter book is its verse.
					Result.put (' ', l_colon)
				end
			end
		ensure
			not_longer: Result.count <= a_text.count
			settled: spoken_form (Result).same_string (Result)
		end

	Spelled_parts: ARRAY [TUPLE [word, mark: STRING_32]]
			-- "chapter" and "verse" written out, with the separator each stands for.
		once
			Result := <<[{STRING_32} " chapter ", {STRING_32} " "], [{STRING_32} " verses ", {STRING_32} ":"], [{STRING_32} " verse ", {STRING_32} ":"]>>
		end

end
