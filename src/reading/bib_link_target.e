note
	description: "[
		One link target read (design scan 59): "framework:<id>",
		"book:<id>[/<chapter>[#<block>]]" or "bible:<book>.<chapter>.<verse>[-<chapter>.<verse>]",
		or none of these. Whatever acts on a link - the window's click and hover card,
		the books builder's indexes - reads it here and asks `is_framework', `is_book'
		or `is_bible', so a new kind of link (essays next) is one more branch here and
		one where it is used. Each grammar is still parsed where it is written:
		BIB_FRAMEWORK_SCHEMA's id, BIB_BOOK_SCHEMA's `link_place',
		BIB_REFERENCE_LINKER's `target_range'.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LINK_TARGET

create
	make

feature {NONE} -- Initialization

	make (a_target: READABLE_STRING_GENERAL; a_books: BIB_BOOK_CATALOG)
			-- `a_target' read; a Bible passage counts only when `a_books' holds its book.
		local
			l_rest: STRING_32
		do
			text := a_target.to_string_32
			create id.make_empty
			if text.starts_with ({BIB_FRAMEWORK_SCHEMA}.Link_prefix) then
				l_rest := text.substring ({BIB_FRAMEWORK_SCHEMA}.Link_prefix.count + 1, text.count)
				if (create {BIB_FRAMEWORK_SCHEMA}).is_framework_id (l_rest) then
					is_framework := True
					id := l_rest
				end
			elseif attached (create {BIB_BOOK_SCHEMA}).link_place (text) as al_place then
				is_book := True
				id := al_place.book
				chapter := al_place.chapter
				block := al_place.block
			elseif attached (create {BIB_REFERENCE_LINKER}.make (a_books)).target_range (text) as al_range
				and then a_books.has_book (al_range.book) and then al_range.chapter >= 1
			then
				is_bible := True
				book := al_range.book
				chapter := al_range.chapter
				verse := al_range.verse
				end_chapter := al_range.end_chapter
				end_verse := al_range.end_verse
			end
		ensure
			text_kept: text.same_string_general (a_target)
		end

feature -- Access

	text: STRING_32
			-- The target as written.

	is_framework: BOOLEAN
			-- A framework: `id'.

	is_book: BOOLEAN
			-- A book (`chapter' 0), a chapter (`block' 0) or a block of Larry's books: `id'.

	is_bible: BOOLEAN
			-- A Bible passage: `book' `chapter':`verse' to `end_chapter':`end_verse' (verse 0: a
			-- whole chapter).

	is_none: BOOLEAN
			-- None of these: a link the window leaves alone.
		do
			Result := not is_framework and not is_book and not is_bible
		end

	id: STRING_32
			-- A framework's or a book's id; empty otherwise.

	book: INTEGER
			-- A Bible passage's book; 0 otherwise.

	chapter, block: INTEGER
			-- A Bible passage's first chapter, or a book link's chapter and block.

	verse, end_chapter, end_verse: INTEGER
			-- A Bible passage's first verse and where it ends.

invariant
	one_kind_at_most: not (is_framework and is_book) and not (is_framework and is_bible) and not (is_book and is_bible)
	named_by_id: (is_framework or is_book) = not id.is_empty
	bible_placed: is_bible = (book > 0)
	bible_has_a_chapter: is_bible implies chapter >= 1

end
