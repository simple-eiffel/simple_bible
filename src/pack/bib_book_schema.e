note
	description: "[
		The books pack, version 1 (2026-10-28): Larry's books, one pack for all of them
		(research/19-BOOKS-PACK.md). The builder writes these tables and the reader
		reads them; this class is the one place they are named.

		THE PACK RULES IT KEEPS (BIB_PRIVATE_SOURCE checks them at attach):
		`user_version' 1; a `meta' table (pack_kind "books", title);
		`source_provenance' in the same file; every other table carries a NOT NULL
		`voice' and a NOT NULL `provenance_key'.

		WHAT IT HOLDS: each book and the spellings that link to it, its chapters in
		reading order, every chapter as BLOCKS (heading, paragraph, quote, list
		item, code) - the unit a link points at, "book:<id>/<chapter>#<block>" -
		and two indexes the build works out: the Bible passages each block cites
		(by hub id, so a verse finds the paragraphs about it) and the frameworks
		each block names.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "books"
			-- `meta.pack_kind' of a books pack.

	Pack_file_name: STRING_8 = "books.db"
			-- The books pack's file in the packs folder.

	Pack_title: STRING_8 = "Larry Rix: Books"

	Schema_version: INTEGER = 1
			-- The pack's `user_version'.

	Link_prefix: STRING_32 = "book:"
			-- A link to a book, a chapter or a block: "book:zakar", "book:zakar/4", "book:zakar/4#12".

	Statuses: ARRAY [STRING_8]
			-- A book's status: in print, finished but unpublished, or still being written.
		once
			Result := <<"published", "manuscript", "draft">>
		end

	Chapter_kinds: ARRAY [STRING_8]
			-- What a chapter is: front matter, the book's text, or back matter.
		once
			Result := <<"front", "chapter", "back">>
		end

	Block_kinds: ARRAY [STRING_8]
			-- What a block is.
		once
			Result := <<"heading", "paragraph", "quote", "item", "code">>
		end

	is_one_of (a_word: READABLE_STRING_GENERAL; a_words: ARRAY [STRING_8]): BOOLEAN
			-- Is `a_word' one of `a_words'?
		do
			Result := across a_words as ic some ic.same_string_general (a_word) end
		end

	is_book_id (a_id: READABLE_STRING_GENERAL): BOOLEAN
			-- Lowercase ASCII letters and digits, at least one.
		do
			Result := not a_id.is_empty and then across a_id.to_string_32 as al_c all (al_c >= 'a' and al_c <= 'z') or (al_c >= '0' and al_c <= '9') end
		end

	link_text (a_book: READABLE_STRING_GENERAL; a_chapter, a_block: INTEGER): STRING_32
			-- "book:zakar", "book:zakar/4" (`a_block' 0) or "book:zakar/4#12" (`a_chapter' 0: the book).
		require
			book_usable: is_book_id (a_book)
			not_negative: a_chapter >= 0 and a_block >= 0
			block_in_a_chapter: a_block > 0 implies a_chapter > 0
		do
			Result := Link_prefix + a_book.to_string_32
			if a_chapter > 0 then
				Result.append ({STRING_32} "/" + a_chapter.out.to_string_32)
				if a_block > 0 then
					Result.append ({STRING_32} "#" + a_block.out.to_string_32)
				end
			end
		ensure
			read_back: attached link_place (Result) as r and then (r.book.same_string_general (a_book) and r.chapter = a_chapter and r.block = a_block)
		end

	link_place (a_target: READABLE_STRING_GENERAL): detachable TUPLE [book: STRING_32; chapter, block: INTEGER]
			-- The book, chapter (0: the book) and block (0: the chapter) a "book:" target names; Void
			-- for any other target.
		local
			l_text, l_book: STRING_32
			l_slash, l_hash, l_chapter, l_block: INTEGER
			l_ok: BOOLEAN
		do
			l_text := a_target.to_string_32
			if l_text.starts_with (Link_prefix) then
				l_text := l_text.substring (Link_prefix.count + 1, l_text.count)
				l_slash := l_text.index_of ('/', 1)
				l_hash := l_text.index_of ('#', 1)
				l_ok := True
				if l_slash = 0 then
					l_book := l_text
					l_ok := l_hash = 0
				else
					l_book := l_text.substring (1, l_slash - 1)
					if l_hash = 0 then
						l_ok := is_count (l_text.substring (l_slash + 1, l_text.count))
						if l_ok then
							l_chapter := l_text.substring (l_slash + 1, l_text.count).to_integer
						end
					else
						l_ok := l_hash > l_slash and then is_count (l_text.substring (l_slash + 1, l_hash - 1)) and then is_count (l_text.substring (l_hash + 1, l_text.count))
						if l_ok then
							l_chapter := l_text.substring (l_slash + 1, l_hash - 1).to_integer
							l_block := l_text.substring (l_hash + 1, l_text.count).to_integer
						end
					end
				end
				if l_ok and then is_book_id (l_book) then
					Result := [l_book, l_chapter, l_block]
				end
			end
		ensure
			sane: attached Result as r implies (is_book_id (r.book) and r.chapter >= 0 and r.block >= 0 and (r.block > 0 implies r.chapter > 0))
		end

	is_count (a_text: READABLE_STRING_32): BOOLEAN
			-- Is `a_text' 1 to 4 digits, not zero?
		do
			Result := not a_text.is_empty and then a_text.count <= 4 and then across a_text as al_c all al_c.is_digit end
				and then a_text.to_integer > 0
		end

	Schema_statements: ARRAY [STRING_8]
			-- The tables of a new books pack, then its version.
		once
			Result := <<
				"CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)",
				"CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)",
				"CREATE TABLE book(book_id TEXT PRIMARY KEY, ordinal INTEGER NOT NULL, title TEXT NOT NULL, subtitle TEXT NOT NULL, author TEXT NOT NULL, status TEXT NOT NULL CHECK (status IN ('published', 'manuscript', 'draft')), edition TEXT NOT NULL, year INTEGER NOT NULL, description TEXT NOT NULL, source TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE book_alias(alias TEXT PRIMARY KEY, book_id TEXT NOT NULL REFERENCES book(book_id), voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE book_chapter(book_id TEXT NOT NULL REFERENCES book(book_id), chapter INTEGER NOT NULL, title TEXT NOT NULL, kind TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter))",
				"CREATE TABLE book_block(book_id TEXT NOT NULL, chapter INTEGER NOT NULL, block INTEGER NOT NULL, kind TEXT NOT NULL, level INTEGER NOT NULL, body_markdown TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter, block))",
				"CREATE TABLE book_passage(book_id TEXT NOT NULL, chapter INTEGER NOT NULL, block INTEGER NOT NULL, ordinal INTEGER NOT NULL, start_book INTEGER NOT NULL, start_chapter INTEGER NOT NULL, start_verse INTEGER NOT NULL, end_chapter INTEGER NOT NULL, end_verse INTEGER NOT NULL, start_hub INTEGER NOT NULL, end_hub INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter, block, ordinal))",
				"CREATE INDEX ix_book_passage_hub ON book_passage(start_hub, end_hub)",
				"CREATE TABLE book_framework(book_id TEXT NOT NULL, chapter INTEGER NOT NULL, block INTEGER NOT NULL, framework_id TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter, block, framework_id))",
				"CREATE INDEX ix_book_framework ON book_framework(framework_id)",
				"PRAGMA user_version = 1">>
		end

end
