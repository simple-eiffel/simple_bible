note
	description: "[
		The books pack (research/19-BOOKS-PACK.md, 2026-10-28): Larry's books, one
		pack for all of them, "book:<id>/<chapter>#<block>". Its tables and link
		grammar are BIB_TEXT_PACK_SCHEMA's.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_SCHEMA

inherit
	BIB_TEXT_PACK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "books"
			-- `meta.pack_kind' of a books pack.

	Pack_file_name: STRING_8 = "books.db"
			-- The books pack's file in the packs folder.

	Pack_title: STRING_8 = "Larry Rix: Books"

	Link_prefix: STRING_32 = "book:"
			-- "book:zakar/4#12".

	Manifest_extension: STRING_8 = ".book.json"

	Builder_command: STRING_8 = "bible_build --books"

	Starts_at_title: BOOLEAN = False
			-- A book's chapter is read whole (its front matter and status line aside).

end
