note
	description: "[
		Bible references in Markdown made into links a reading pane follows:
		"Numbers 14:11" becomes [Numbers 14:11](bible:4.14.11), "Jude 5" (a book
		of one chapter: the number is the verse) [Jude 5](bible:65.1.5), and
		"Matthew 5" the chapter, [Matthew 5](bible:40.5.0). A range keeps its
		text, and its link names where it ends too: [Galatians 2:15-21]
		(bible:48.2.15-2.21), so a hover card can show the whole passage
		(2026-10-28); `target_place' reads the first verse of either form. Larry's rule (2026-02-15): every
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

	framework_names: detachable BIB_FRAMEWORK_NAMES
			-- The frameworks `linked' also links (2026-10-28): "KACC(TM)" becomes
			-- [KACC(TM)](framework:kacc); Void links references only.

	set_framework_names (a_names: detachable BIB_FRAMEWORK_NAMES)
			-- Link the frameworks `a_names' finds too (Void: references only).
		do
			framework_names := a_names
		ensure
			set: framework_names = a_names
		end

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

	range_target_text (a_book, a_chapter, a_verse, a_end_chapter, a_end_verse: INTEGER): STRING_32
			-- The link target of a passage: `target_text' when it is one place, else that and where it
			-- ends: "bible:48.2.15-2.21".
		do
			Result := target_text (a_book, a_chapter, a_verse)
			if a_end_chapter /= a_chapter or a_end_verse /= a_verse then
				Result.append ({STRING_32} "-" + a_end_chapter.out + {STRING_32} "." + a_end_verse.out)
			end
		ensure
			first_place_read_back: attached target_place (Result) as r and then (r.book = a_book and r.chapter = a_chapter and r.verse = a_verse)
		end

	target_place (a_target: READABLE_STRING_GENERAL): detachable TUPLE [book, chapter, verse: INTEGER]
			-- The place a "bible:" link target names (a passage's first); Void for any other target.
		do
			if attached target_range (a_target) as al_range then
				Result := [al_range.book, al_range.chapter, al_range.verse]
			end
		end

	target_range (a_target: READABLE_STRING_GENERAL): detachable TUPLE [book, chapter, verse, end_chapter, end_verse: INTEGER]
			-- The passage a "bible:" link target names, where it starts and ends (one place ends where
			-- it starts); Void for any other target.
		local
			l_text, l_start, l_end: STRING_32
			l_parts, l_end_parts: LIST [STRING_32]
			l_dash: INTEGER
		do
			l_text := a_target.to_string_32
			if l_text.starts_with (Target_prefix) then
				l_text := l_text.substring (Target_prefix.count + 1, l_text.count)
				l_dash := l_text.index_of ('-', 1)
				if l_dash > 0 then
					l_start := l_text.substring (1, l_dash - 1)
					l_end := l_text.substring (l_dash + 1, l_text.count)
				else
					l_start := l_text
					create l_end.make_empty
				end
				l_parts := l_start.split ('.')
				if l_parts.count = 3 and then is_small_number (l_parts.i_th (1)) and then is_small_number (l_parts.i_th (2))
					and then is_small_number (l_parts.i_th (3))
				then
					Result := [l_parts.i_th (1).to_integer, l_parts.i_th (2).to_integer, l_parts.i_th (3).to_integer,
						l_parts.i_th (2).to_integer, l_parts.i_th (3).to_integer]
					if not l_end.is_empty then
						l_end_parts := l_end.split ('.')
						if l_end_parts.count = 2 and then is_small_number (l_end_parts.i_th (1)) and then is_small_number (l_end_parts.i_th (2)) then
							Result.end_chapter := l_end_parts.i_th (1).to_integer
							Result.end_verse := l_end_parts.i_th (2).to_integer
						else
							Result := Void
						end
					end
				end
				if attached Result as al_range and then not (al_range.book >= 1 and al_range.chapter >= 1
					and al_range.end_chapter >= al_range.chapter and (al_range.end_chapter > al_range.chapter or al_range.end_verse >= al_range.verse))
				then
						-- scan 57: a target no reference writes (a book 0, a passage running backward) is none
					Result := Void
				end
			end
		ensure
			a_passage: attached Result as r implies (r.book >= 1 and r.chapter >= 1 and r.chapter <= Max_number
				and r.verse >= 0 and r.verse <= Max_number and r.end_chapter <= Max_number and r.end_verse <= Max_number
				and (r.end_chapter > r.chapter or (r.end_chapter = r.chapter and r.end_verse >= r.verse)))
		end

	is_small_number (a_part: READABLE_STRING_32): BOOLEAN
			-- Is `a_part' digits only, at most `Max_number' (a book number too: 66 books)?
		do
			Result := not a_part.is_empty and then a_part.count <= 3 and then across a_part as al_c all al_c.is_digit end
				and then a_part.to_integer <= Max_number
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
			l_framework: detachable TUPLE [last: INTEGER; id: STRING_32]
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
					l_framework := Void
					if attached framework_names as al_names then
						l_framework := al_names.match_at (l_text, i)
					end
					if l_framework = Void and then (i = 1 or else not is_word_character (l_text [i - 1])) then
						l_found := reference_at (l_text, i)
					end
					if attached l_framework as al_framework then
						Result.append ({STRING_32} "[" + l_text.substring (i, al_framework.last) + {STRING_32} "](" + {BIB_FRAMEWORK_SCHEMA}.Link_prefix + al_framework.id + {STRING_32} ")")
						i := al_framework.last + 1
					elseif attached l_found as al_found then
						l_end := al_found.last
						Result.append ({STRING_32} "[" + l_text.substring (i, l_end) + {STRING_32} "](" + range_target_text (al_found.book, al_found.chapter, al_found.verse, al_found.end_chapter, al_found.end_verse) + {STRING_32} ")")
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

	reference_at (a_text: STRING_32; a_start: INTEGER): detachable TUPLE [last, book, chapter, verse, end_chapter, end_verse: INTEGER]
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
			-- The book `a_name' names, or 0: the catalog's exact name or code, else a standard short
			-- form ("Heb", "1 Kgs", "1Cor", "Psalm": BIB_BOOK_ABBREVIATIONS, 2026-10-28), else, for a
			-- box only (`is_forgiving'), the first book it begins, in any case. Prose must write a name
			-- as a name is written; a box may write "gn 1" or "rom 8". Scan 59: both faces ask in this
			-- one order (before, a box never asked the short forms).
		local
			l_short: INTEGER
		do
			if is_forgiving or else starts_like_a_name (a_name) then
				Result := books.book_named_exactly (a_name)
				if Result = 0 then
					if is_forgiving then
						l_short := abbreviations.book_of (capitalized (a_name))
					else
						l_short := abbreviations.book_of (a_name)
					end
					if books.has_book (l_short) then
						Result := l_short
					elseif is_forgiving and then not a_name.is_empty and then attached books.candidates_for_name (a_name) as al_candidates
						and then not al_candidates.is_empty
					then
						Result := al_candidates.first
					end
				end
			end
		end

	abbreviations: BIB_BOOK_ABBREVIATIONS
			-- The standard short forms.
		once
			create Result
		end

	capitalized (a_name: STRING_32): STRING_32
			-- `a_name' with its first letter a capital: "gn" "Gn", "1cor" "1Cor", "1 jn" "1 Jn".
		local
			i: INTEGER
			l_done: BOOLEAN
		do
			Result := a_name.twin
			from i := 1 until i > Result.count or l_done loop
				if Result [i].is_alpha then
					Result [i] := Result [i].as_upper
					l_done := True
				end
				i := i + 1
			end
		ensure
			same_length: Result.count = a_name.count
		end

	numbers_at (a_text: STRING_32; a_start, a_book: INTEGER): detachable TUPLE [last, book, chapter, verse, end_chapter, end_verse: INTEGER]
			-- "14:11", "5-7", "2:4-9", "5:1-6:2" or "5" at `a_start' after book `a_book', with where
			-- a range ends (a place without one ends where it starts; verse 0: a whole chapter).
		local
			i, l_first, l_second, l_third, l_fourth: INTEGER
			l_has_colon, l_has_range, l_range_colon: BOOLEAN
			l_start_chapter, l_start_verse, l_end_chapter, l_end_verse: INTEGER
			l_number: TUPLE [value, next: INTEGER]
		do
			l_number := number_at (a_text, a_start)
			l_first := l_number.value
			i := l_number.next
			if i + 1 <= a_text.count and then a_text [i] = ':' and then a_text [i + 1].is_digit then
				l_has_colon := True
				l_number := number_at (a_text, i + 1)
				l_second := l_number.value
				i := l_number.next
			end
				-- A range ("5-7", "2:4-9", "5:1-6:2") keeps its text; its end is read too.
			if i + 1 <= a_text.count and then (a_text [i] = '-' or a_text [i].natural_32_code = 0x2013) and then a_text [i + 1].is_digit then
				l_has_range := True
				l_number := number_at (a_text, i + 1)
				l_third := l_number.value
				i := l_number.next
				if i + 1 <= a_text.count and then a_text [i] = ':' and then a_text [i + 1].is_digit then
					l_range_colon := True
					l_number := number_at (a_text, i + 1)
					l_fourth := l_number.value
					i := l_number.next
				end
			end
			if l_has_colon then
				l_start_chapter := l_first
				l_start_verse := l_second
			elseif books.is_single_chapter_book (a_book) then
				l_start_chapter := 1
				l_start_verse := l_first
			else
				l_start_chapter := l_first
			end
			l_end_chapter := l_start_chapter
			l_end_verse := l_start_verse
			if l_has_range and l_range_colon then
					-- "5:1-6:2"
				l_end_chapter := l_third
				l_end_verse := l_fourth
			elseif l_has_range and (l_has_colon or books.is_single_chapter_book (a_book)) then
					-- "2:4-9", "Jude 5-7": verses of the chapter
				l_end_verse := l_third
			elseif l_has_range then
					-- "5-7": whole chapters
				l_end_chapter := l_third
			end
			if l_end_chapter < l_start_chapter or else (l_end_chapter = l_start_chapter and l_end_verse < l_start_verse)
				or else l_end_chapter > Max_number or else l_end_verse > Max_number
			then
					-- a range that runs backward or past any book is read as its first place
				l_end_chapter := l_start_chapter
				l_end_verse := l_start_verse
			end
			if l_start_chapter >= 1 and l_start_chapter <= Max_number and l_start_verse >= 0 and l_start_verse <= Max_number
				and (l_has_colon implies l_start_verse >= 1) and (books.is_single_chapter_book (a_book) implies l_start_verse >= 1)
			then
				Result := [i - 1, a_book, l_start_chapter, l_start_verse, l_end_chapter, l_end_verse]
			end
		ensure
			ends_after_it_starts: attached Result as r implies (r.end_chapter > r.chapter or (r.end_chapter = r.chapter and r.end_verse >= r.verse))
		end

	number_at (a_text: STRING_32; a_start: INTEGER): TUPLE [value, next: INTEGER]
			-- The digits from `a_start' read as a number, held at `Max_number' + 1 once past it (a long
			-- run never overflows: scan 57), and the index after them.
		require
			in_text: a_start >= 1 and a_start <= a_text.count + 1
		local
			i, l_value: INTEGER
		do
			from i := a_start until i > a_text.count or else not a_text [i].is_digit loop
				l_value := (l_value * 10 + a_text [i].code - ('0').code).min (Max_number + 1)
				i := i + 1
			end
			Result := [l_value, i]
		ensure
			bounded: Result.value >= 0 and Result.value <= Max_number + 1
			after_the_digits: Result.next >= a_start and Result.next <= a_text.count + 1
		end

	starts_like_a_name (a_name: STRING_32): BOOLEAN
			-- Does `a_name' begin as a book name is written: a capital, or a digit and a capital with or
			-- without a space between ("1 John", "1Cor": scan 59)?
		do
			if not a_name.is_empty then
				if a_name [1].is_upper then
					Result := True
				elseif a_name [1].is_digit and then a_name.count >= 2 and then a_name [2].is_upper then
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
