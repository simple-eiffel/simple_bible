note
	description: "[
		The key of a verse in `verse_fts', the verse search index (bible_build
		0.3.0): the version's `sort_order' times `Version_unit', then book times a
		million, chapter times a thousand and verse, in the version's own
		numbering. A version is one key range, so a search filters by range
		(spec 07, SB-1), and a hit names its place without a join. Not a hub id:
		user records anchor to BIB_HUB_ID, never to this key.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_KEY

feature -- Conversion

	verse_key (a_order, a_book, a_chapter, a_verse: INTEGER): INTEGER_64
			-- The key of verse `a_book' `a_chapter':`a_verse' in the version ordered `a_order'.
		require
			order_not_negative: a_order >= 0
			parts_in_range: a_book >= 0 and a_book < 100 and a_chapter >= 0 and a_chapter < 1000 and a_verse >= 0 and a_verse < 1000
		do
			Result := a_order.to_integer_64 * Version_unit + a_book.to_integer_64 * Book_unit + a_chapter.to_integer_64 * Chapter_unit + a_verse.to_integer_64
		ensure
			in_its_version_range: Result // Version_unit = a_order.to_integer_64
			book_back: book_of (Result) = a_book
			chapter_back: chapter_of (Result) = a_chapter
			verse_back: verse_of (Result) = a_verse
		end

	first_key (a_order: INTEGER): INTEGER_64
			-- The first key of the version ordered `a_order'.
		require
			order_not_negative: a_order >= 0
		do
			Result := a_order.to_integer_64 * Version_unit
		end

	last_key (a_order: INTEGER): INTEGER_64
			-- The last key of the version ordered `a_order'.
		require
			order_not_negative: a_order >= 0
		do
			Result := first_key (a_order) + Version_unit - 1
		end

	book_of (a_key: INTEGER_64): INTEGER
		do
			Result := ((a_key \\ Version_unit) // Book_unit).to_integer_32
		end

	chapter_of (a_key: INTEGER_64): INTEGER
		do
			Result := ((a_key \\ Book_unit) // Chapter_unit).to_integer_32
		end

	verse_of (a_key: INTEGER_64): INTEGER
		do
			Result := (a_key \\ Chapter_unit).to_integer_32
		end

feature -- Constants

	Version_unit: INTEGER_64 = 100_000_000
	Book_unit: INTEGER_64 = 1_000_000
	Chapter_unit: INTEGER_64 = 1_000
			-- No book reaches 100, no chapter or verse 1,000.

end
