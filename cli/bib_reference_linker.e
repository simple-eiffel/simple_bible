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
		range. Prose is never touched by a guess ("is 5" is not Isaiah 5), nor
		text already inside a link or inline code. An interim reader until the
		reference grammar (research/15) is vendored.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REFERENCE_LINKER

create
	make

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
		do
			books := a_books
		ensure
			books_set: books = a_books
		end

feature -- Access

	books: BIB_BOOK_CATALOG

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
						Result.append ({STRING_32} "[" + l_text.substring (i, l_end) + {STRING_32} "](bible:"
							+ al_found.book.out + {STRING_32} "." + al_found.chapter.out + {STRING_32} "." + al_found.verse.out + {STRING_32} ")")
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
				if l_name.ends_with ({STRING_32} ".") then
					l_name.remove_tail (1)
				end
				l_book := 0
				if starts_like_a_name (l_name) then
					l_book := books.book_named_exactly (l_name)
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

end
