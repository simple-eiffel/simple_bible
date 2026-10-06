note
	description: "[
		A parsed reference in one versification system: book, chapter, verse
		and an optional letter suffix (3 Kgdms 2:35a). Not comparable across
		versions until the versification map turns it into a BIB_MAPPED_REF.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REF

inherit
	ANY
		redefine
			is_equal
		end

create
	make, make_with_suffix

feature {NONE} -- Initialization

	make (a_book_id, a_chapter, a_verse: INTEGER; a_system: BIB_VERSIFICATION_SYSTEM)
			-- Create a reference with no suffix.
		require
			book_positive: a_book_id > 0
			chapter_non_negative: a_chapter >= 0
			verse_non_negative: a_verse >= 0
		do
			book_id := a_book_id
			chapter := a_chapter
			verse := a_verse
			system := a_system
			create suffix.make_empty
		ensure
			book_set: book_id = a_book_id
			chapter_set: chapter = a_chapter
			verse_set: verse = a_verse
			system_set: system = a_system
			no_suffix: suffix.is_empty
		end

	make_with_suffix (a_book_id, a_chapter, a_verse: INTEGER; a_suffix: READABLE_STRING_8; a_system: BIB_VERSIFICATION_SYSTEM)
			-- Create a lettered reference such as 3 Kgdms 2:35a.
		require
			book_positive: a_book_id > 0
			chapter_non_negative: a_chapter >= 0
			verse_non_negative: a_verse >= 0
			suffix_letters: across a_suffix as c all c.is_lower end
		do
			make (a_book_id, a_chapter, a_verse, a_system)
			suffix := a_suffix.to_string_8
		ensure
			book_set: book_id = a_book_id
			suffix_set: suffix.same_string (a_suffix)
		end

feature -- Access

	book_id: INTEGER
			-- Canonical book id (FR-105).

	chapter: INTEGER
			-- Chapter; 0 allowed for prologue chapters (Swete Esther).

	verse: INTEGER
			-- Verse; 0 allowed for unnumbered titles.

	suffix: STRING_8
			-- "" or lowercase letters for lettered verses.

	system: BIB_VERSIFICATION_SYSTEM
			-- Numbering system this reference is written in.

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same book, chapter, verse, suffix and system?
		do
			Result := book_id = other.book_id and chapter = other.chapter and verse = other.verse
				and suffix.same_string (other.suffix) and system ~ other.system
		end

invariant
	book_positive: book_id > 0
	chapter_non_negative: chapter >= 0
	verse_non_negative: verse >= 0
	suffix_letters: across suffix as c all c.is_lower end

end
