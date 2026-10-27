note
	description: "[
		One packing of a place into a number: book times a million, chapter
		times a thousand, verse; one place below `Place_span'. BIB_HUB_ID (the
		canonical verse) and BIB_VERSE_KEY (a verse in one version's search
		index) both pack this way (design scan 47: the units and decoders were
		written twice). Inherited side by side with each one's own rules.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PLACE_PACKING

feature -- Packing

	packed_place (a_book, a_chapter, a_verse: INTEGER): INTEGER_64
			-- `a_book' `a_chapter':`a_verse' as one number below `Place_span'.
		require
			parts_in_range: a_book >= 0 and a_book <= Max_part and a_chapter >= 0 and a_chapter <= Max_part and a_verse >= 0 and a_verse <= Max_part
		do
			Result := a_book.to_integer_64 * Book_unit + a_chapter.to_integer_64 * Chapter_unit + a_verse.to_integer_64
		ensure
			below_span: Result >= 0 and Result < Place_span
		end

	book_part (a_packed: INTEGER_64): INTEGER
			-- The book of the place packed in `a_packed' (any multiple of `Place_span' above it ignored).
		do
			Result := ((a_packed \\ Place_span) // Book_unit).to_integer_32
		end

	chapter_part (a_packed: INTEGER_64): INTEGER
		do
			Result := ((a_packed \\ Book_unit) // Chapter_unit).to_integer_32
		end

	verse_part (a_packed: INTEGER_64): INTEGER
		do
			Result := (a_packed \\ Chapter_unit).to_integer_32
		end

feature -- Constants

	Place_span: INTEGER_64 = 1_000_000_000
	Book_unit: INTEGER_64 = 1_000_000
	Chapter_unit: INTEGER_64 = 1_000
	Max_part: INTEGER = 999
			-- No book, chapter or verse number reaches a thousand.

end
