note
	description: "[
		Passages as a reader writes them, read into verse ranges (research/25,
		2026-11-01): "John 3:16", "1 Corinthians 2:10-16" (an en or em dash
		reads as a hyphen), "Psalm 23" (the whole chapter), and a list of them
		joined by semicolons or middle dots, where "Hebrews 3:6; 7:25" carries
		the book on. Each passage is read with the reference linker's
		`reference_at', as the books read theirs. The meme builder and the
		meme tool's Add meme both read passages here.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PASSAGE_TEXT

create
	make

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
			-- Read passages with the book names of `a_books'.
		do
			create linker.make (a_books)
		end

feature -- Reading

	range (a_text: READABLE_STRING_GENERAL): detachable TUPLE [hub_from, hub_to: INTEGER_64]
			-- The verses `a_text' names; Void when it does not read as one passage.
		local
			l_text: STRING_32
			l_hub: BIB_HUB_ID
		do
			l_text := plain (a_text)
			if not l_text.is_empty and then attached linker.reference_at (l_text, 1) as al_place then
				create l_hub
				if al_place.verse = 0 then
					if l_hub.is_place (al_place.book, al_place.chapter, 1) and then l_hub.is_place (al_place.book, al_place.end_chapter.max (al_place.chapter), l_hub.Max_part) then
						Result := [l_hub.hub_id (al_place.book, al_place.chapter, 1), l_hub.hub_id (al_place.book, al_place.end_chapter.max (al_place.chapter), l_hub.Max_part)]
					end
				elseif l_hub.is_place (al_place.book, al_place.chapter, al_place.verse) then
					Result := [l_hub.hub_id (al_place.book, al_place.chapter, al_place.verse), l_hub.hub_id (al_place.book, al_place.chapter, al_place.verse)]
					if l_hub.is_place (al_place.book, al_place.end_chapter, al_place.end_verse)
						and then l_hub.hub_id (al_place.book, al_place.end_chapter, al_place.end_verse) > Result.hub_from
					then
						Result.hub_to := l_hub.hub_id (al_place.book, al_place.end_chapter, al_place.end_verse)
					end
				end
			end
		ensure
			ordered: attached Result as al_range implies (al_range.hub_from > 0 and al_range.hub_to >= al_range.hub_from)
		end

	ranges (a_list: READABLE_STRING_GENERAL): TUPLE [read: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]]; unread: ARRAYED_LIST [STRING_32]]
			-- Each passage of `a_list' (semicolons or middle dots between), read, and those that do not
			-- read; a bare "7:25" takes the book of the passage before it.
		local
			l_read: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]]
			l_unread: ARRAYED_LIST [STRING_32]
			l_text, l_part, l_book: STRING_32
		do
			create l_read.make (4)
			create l_unread.make (0)
			create l_book.make_empty
			l_text := a_list.to_string_32
			l_text.replace_substring_all ({STRING_32} "%/183/", {STRING_32} ";")
			across l_text.split (';') as ic loop
				l_part := plain (ic)
				if not l_part.is_empty then
					if l_part.item (1).is_digit and l_part.has (':') and l_part.index_of (' ', 1) = 0 and not l_book.is_empty then
						l_part := l_book + {STRING_32} " " + l_part
					end
					if attached range (l_part) as al_range then
						l_read.extend ([al_range.hub_from, al_range.hub_to, l_part])
						l_book := book_words (l_part)
					else
						l_unread.extend (l_part)
					end
				end
			end
			Result := [l_read, l_unread]
		end

feature {NONE} -- Implementation

	linker: BIB_REFERENCE_LINKER

	plain (a_text: READABLE_STRING_GENERAL): STRING_32
			-- `a_text' trimmed, its en and em dashes read as hyphens.
		do
			Result := a_text.to_string_32
			Result.replace_substring_all ({STRING_32} "%/8211/", {STRING_32} "-")
			Result.replace_substring_all ({STRING_32} "%/8212/", {STRING_32} "-")
			Result.left_adjust
			Result.right_adjust
		end

	book_words (a_passage: STRING_32): STRING_32
			-- "1 Corinthians" of "1 Corinthians 2:10": everything before the last space.
		local
			i: INTEGER
		do
			i := a_passage.last_index_of (' ', a_passage.count)
			if i > 1 then
				Result := a_passage.substring (1, i - 1)
			else
				create Result.make_empty
			end
		end

end
