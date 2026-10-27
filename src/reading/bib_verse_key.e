note
	description: "[
		The key of a verse in `verse_fts', the verse search index (bible_build
		0.3.0): the version's `sort_order' times `Place_span', plus the place
		packed as a hub id is (BIB_PLACE_PACKING), in the version's own
		numbering. A version is one key range, so a search filters by range
		(spec 07, SB-1), and a hit names its place without a join. Not a hub id:
		user records anchor to BIB_HUB_ID, never to this key.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_KEY

inherit
	BIB_PLACE_PACKING

feature -- Conversion

	verse_key (a_order, a_book, a_chapter, a_verse: INTEGER): INTEGER_64
			-- The key of verse `a_book' `a_chapter':`a_verse' in the version ordered `a_order'.
		require
			order_not_negative: a_order >= 0
			numbered: a_book >= 1 and a_chapter >= 1 and a_verse >= 1
			parts_in_range: a_book <= Max_part and a_chapter <= Max_part and a_verse <= Max_part
		do
			Result := first_key (a_order) + packed_place (a_book, a_chapter, a_verse)
		ensure
			in_its_version_range: Result >= first_key (a_order) and Result <= last_key (a_order)
			book_back: book_part (Result) = a_book
			chapter_back: chapter_part (Result) = a_chapter
			verse_back: verse_part (Result) = a_verse
		end

	first_key (a_order: INTEGER): INTEGER_64
			-- The first key of the version ordered `a_order'.
		require
			order_not_negative: a_order >= 0
		do
			Result := a_order.to_integer_64 * Place_span
		end

	last_key (a_order: INTEGER): INTEGER_64
			-- The last key of the version ordered `a_order'.
		require
			order_not_negative: a_order >= 0
		do
			Result := first_key (a_order) + Place_span - 1
		end

	is_indexable (a_book, a_chapter, a_verse: INTEGER): BOOLEAN
			-- Can verse `a_book' `a_chapter':`a_verse' take a key (a numbered verse in range)?
		do
			Result := a_book >= 1 and a_book <= Max_part and a_chapter >= 1 and a_chapter <= Max_part and a_verse >= 1 and a_verse <= Max_part
		end

end
