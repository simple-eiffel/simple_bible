note
	description: "[
		A pack of Larry's own long texts, version 1 (2026-10-28): his books
		(BIB_BOOK_SCHEMA, research/19-BOOKS-PACK.md) and his essays
		(BIB_ESSAY_SCHEMA: a series is a book, an essay a chapter). One builder
		(BIB_BOOK_BUILDER) writes these tables and one reader (BIB_BOOK_PACK) reads
		them; this class is the one place they are named, and the heir names the
		kind, file, title, link prefix and manifest extension.

		THE PACK RULES IT KEEPS (BIB_PRIVATE_SOURCE checks them at attach):
		`user_version' 1; a `meta' table (its pack_kind, title);
		`source_provenance' in the same file; every other table carries a NOT NULL
		`voice' and a NOT NULL `provenance_key'.

		WHAT IT HOLDS: each book and the spellings that link to it, its chapters (and
		the names a chapter goes by: an essay's "JESUS 06: Isaac's Word") in
		reading order, every chapter as BLOCKS (heading, paragraph, quote, list
		item, code) - the unit a link points at, "book:<id>/<chapter>#<block>" or
		"essay:<series>/<essay>#<block>" -
		and two indexes the build works out: the Bible passages each block cites
		(by hub id, so a verse finds the paragraphs about it) and the frameworks
		each block names.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_TEXT_PACK_SCHEMA

inherit
	BIB_PRIVATE_PACK_SCHEMA
		rename
			is_lowercase_id as is_book_id
		end

feature -- Constants

	Link_prefix: STRING_32
			-- A link to a book, a chapter or a block: "book:zakar", "book:zakar/4", "book:zakar/4#12".
		deferred
		ensure
			a_prefix: Result.ends_with ({STRING_32} ":")
		end

	Manifest_extension: STRING_8
			-- The ending of a manifest the builder reads: ".book.json".
		deferred
		end

	Builder_command: STRING_8
			-- The command that builds the pack, for its `meta'.
		deferred
		end

	Starts_at_title: BOOLEAN
			-- Does a chapter's text begin at its first "# " title, what stands above it left out?
		deferred
		end

	Kind_noun: STRING_32
			-- What the library calls one entry's kind: "Book", "Essays".
		deferred
		ensure
			named: not Result.is_empty
		end

	Entries_noun: STRING_8
			-- What a build report calls the entries: "books", "series".
		deferred
		ensure
			named: not Result.is_empty
		end

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

	Max_part: INTEGER = 9999
			-- The highest chapter or block number a link names (four digits; blocks restart at 1 in
			-- each chapter, so this is generous: scan 59).

	link_text (a_book: READABLE_STRING_GENERAL; a_chapter, a_block: INTEGER): STRING_32
			-- "book:zakar", "book:zakar/4" (`a_block' 0) or "book:zakar/4#12" (`a_chapter' 0: the book).
		require
			book_usable: is_book_id (a_book)
			not_negative: a_chapter >= 0 and a_block >= 0
			within_four_digits: a_chapter <= Max_part and a_block <= Max_part
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
			sane: attached Result as r implies (is_book_id (r.book) and r.chapter >= 0 and r.block >= 0 and r.chapter <= Max_part and r.block <= Max_part
				and (r.block > 0 implies r.chapter > 0))
		end

	is_count (a_text: READABLE_STRING_32): BOOLEAN
			-- Is `a_text' 1 to 4 digits, 1 to `Max_part'?
		do
			Result := not a_text.is_empty and then a_text.count <= 4 and then across a_text as al_c all al_c.is_digit end
				and then a_text.to_integer > 0 and then a_text.to_integer <= Max_part
		end

	pack_tables: ARRAY [STRING_8]
			-- The books pack's own tables.
		once
			Result := <<
				"CREATE TABLE book(book_id TEXT PRIMARY KEY, ordinal INTEGER NOT NULL, title TEXT NOT NULL, subtitle TEXT NOT NULL, author TEXT NOT NULL, status TEXT NOT NULL CHECK (status IN ('published', 'manuscript', 'draft')), edition TEXT NOT NULL, year INTEGER NOT NULL, description TEXT NOT NULL, source TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE book_alias(alias TEXT PRIMARY KEY, book_id TEXT NOT NULL REFERENCES book(book_id), voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE chapter_alias(alias TEXT PRIMARY KEY, book_id TEXT NOT NULL REFERENCES book(book_id), chapter INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key))",
				"CREATE TABLE book_chapter(book_id TEXT NOT NULL REFERENCES book(book_id), chapter INTEGER NOT NULL, title TEXT NOT NULL, kind TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter))",
				"CREATE TABLE book_block(book_id TEXT NOT NULL, chapter INTEGER NOT NULL, block INTEGER NOT NULL, kind TEXT NOT NULL, level INTEGER NOT NULL, body_markdown TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter, block))",
				"CREATE TABLE book_passage(book_id TEXT NOT NULL, chapter INTEGER NOT NULL, block INTEGER NOT NULL, ordinal INTEGER NOT NULL, start_book INTEGER NOT NULL, start_chapter INTEGER NOT NULL, start_verse INTEGER NOT NULL, end_chapter INTEGER NOT NULL, end_verse INTEGER NOT NULL, start_hub INTEGER NOT NULL, end_hub INTEGER NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter, block, ordinal))",
				"CREATE INDEX ix_book_passage_hub ON book_passage(start_hub, end_hub)",
				"CREATE TABLE book_framework(book_id TEXT NOT NULL, chapter INTEGER NOT NULL, block INTEGER NOT NULL, framework_id TEXT NOT NULL, voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key), PRIMARY KEY (book_id, chapter, block, framework_id))",
				"CREATE INDEX ix_book_framework ON book_framework(framework_id)">>
		end

end
