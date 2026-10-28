note
	description: "[
		The "bible:" link grammar (2026-10-28, from BIB_REFERENCE_LINKER): a place
		"bible:65.1.5" (verse 0: the chapter) or a passage "bible:48.2.15-2.21",
		written by `target_text' and `range_target_text' and read back by
		`target_place' and `target_range'. It needs no book catalog, so a builder
		writes the commentary's addresses with it (research/20); the linker
		inherits it and so writes the same links.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BIBLE_LINK

feature -- Places

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

	Max_number: INTEGER = 176
			-- No chapter or verse number exceeds Psalm 119's 176.

end
