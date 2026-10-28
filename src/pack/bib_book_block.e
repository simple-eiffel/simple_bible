note
	description: "[
		One block of a book (BIB_BOOK_SCHEMA): a heading, paragraph, quote, list item
		or code block of one chapter, its address "book:<id>/<chapter>#<block>", and
		the names of its book and chapter, so a list of blocks from several books
		(the paragraphs citing a verse, or naming a framework) reads on its own.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_BLOCK

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_book: READABLE_STRING_GENERAL; a_chapter, a_block: INTEGER; a_kind: READABLE_STRING_GENERAL; a_level: INTEGER;
			a_markdown, a_book_title, a_chapter_title: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Block `a_block' of chapter `a_chapter' of book `a_book'.
		require
			book_usable: (create {BIB_BOOK_SCHEMA}).is_book_id (a_book)
			placed: a_chapter >= 1 and a_block >= 1
			within_four_digits: a_chapter <= {BIB_BOOK_SCHEMA}.Max_part and a_block <= {BIB_BOOK_SCHEMA}.Max_part
		do
			book := a_book.to_string_32
			chapter := a_chapter
			block := a_block
			kind := a_kind.to_string_32
			level := a_level
			markdown := a_markdown.to_string_32
			book_title := a_book_title.to_string_32
			chapter_title := a_chapter_title.to_string_32
			provenance := a_provenance
		ensure
			placed: book.same_string_general (a_book) and chapter = a_chapter and block = a_block
		end

feature -- Access

	book: STRING_32
	chapter: INTEGER
	block: INTEGER
	kind: STRING_32
			-- heading, paragraph, quote, item or code.
	level: INTEGER
			-- A heading's level (1 to 6); 0 otherwise.
	markdown: STRING_32
			-- A heading's text; any other block's Markdown as written.
	book_title: STRING_32
	chapter_title: STRING_32

	provenance: BIB_PROVENANCE

	link: STRING_32
			-- "book:zakar/4#12".
		do
			Result := (create {BIB_BOOK_SCHEMA}).link_text (book, chapter, block)
		end

	snippet (a_count: INTEGER): STRING_32
			-- The block's first `a_count' characters, on one line, its emphasis marks and a quote's or
			-- item's leading mark gone, "..." when cut.
		require
			positive: a_count > 3
		do
			Result := markdown.twin
			Result.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			Result.prune_all ('*')
			Result.prune_all ('`')
			if Result.starts_with ({STRING_32} "> ") or Result.starts_with ({STRING_32} "- ") then
				Result.remove_head (2)
			end
			if Result.count > a_count then
				Result.keep_head (a_count - 3)
				Result.append ({STRING_32} "...")
			end
		ensure
			bounded: Result.count <= a_count
		end

invariant
	book_present: not book.is_empty
	placed: chapter >= 1 and block >= 1
	within_four_digits: chapter <= {BIB_BOOK_SCHEMA}.Max_part and block <= {BIB_BOOK_SCHEMA}.Max_part

end
