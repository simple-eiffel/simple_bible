note
	description: "[
		The canonical verse identity the reader's own records anchor to (the
		spec's hub id): the verse's place in English (KJV) numbering, book times
		a million plus chapter times a thousand plus verse. Jude 1:5 is
		65001005; John 3:16 is 43003016. Larry, 2026-10-27 ("Take your
		recommend"): notes, highlights and bookmarks are built on it now; the
		Hebrew, Septuagint and other numberings map onto it later through the
		versification map, so a note made in any version lands on the same verse.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_HUB_ID

inherit
	BIB_PLACE_PACKING

feature -- Conversion

	hub_id (a_book, a_chapter, a_verse: INTEGER): INTEGER_64
			-- The hub id of verse `a_book' `a_chapter':`a_verse' in English numbering.
		require
			book_valid: a_book >= 1 and a_book <= Max_part
			chapter_valid: a_chapter >= 1 and a_chapter <= Max_part
			verse_valid: a_verse >= 1 and a_verse <= Max_part
		do
			Result := packed_place (a_book, a_chapter, a_verse)
		ensure
			valid: is_valid_hub (Result)
			book_back: book_of (Result) = a_book
			chapter_back: chapter_of (Result) = a_chapter
			verse_back: verse_of (Result) = a_verse
		end

	book_of (a_hub: INTEGER_64): INTEGER
		require
			valid: is_valid_hub (a_hub)
		do
			Result := book_part (a_hub)
		end

	chapter_of (a_hub: INTEGER_64): INTEGER
		require
			valid: is_valid_hub (a_hub)
		do
			Result := chapter_part (a_hub)
		end

	verse_of (a_hub: INTEGER_64): INTEGER
		require
			valid: is_valid_hub (a_hub)
		do
			Result := verse_part (a_hub)
		end

	is_valid_hub (a_hub: INTEGER_64): BOOLEAN
			-- Does `a_hub' name a verse: a book, chapter and verse each 1 to `Max_part'?
		do
			Result := a_hub >= Book_unit + Chapter_unit + 1 and a_hub <= Max_part.to_integer_64 * Book_unit + Max_part.to_integer_64 * Chapter_unit + Max_part
				and (a_hub // Chapter_unit) \\ Chapter_unit >= 1 and a_hub \\ Chapter_unit >= 1
		end

end
