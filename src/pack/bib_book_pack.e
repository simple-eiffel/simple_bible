note
	description: "[
		A books pack, read (BIB_BOOK_SCHEMA): every book in the pack's order, one book
		with its chapters, one chapter's blocks, the blocks that cite a verse (from
		the passage index, the narrowest passage first) and the blocks that name a
		framework. Attached read-only by BIB_PRIVATE_SOURCE, which checked its
		version, voice and provenance columns. T6's Author Library, T5's "In the
		books" and the frameworks' "Where the books discuss it" are built on it
		(2026-10-28).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_PACK

inherit
	BIB_PRIVATE_PACK_READER

create
	make

feature -- Access

	books: BIB_LIST_RESULT [BIB_AUTHOR_BOOK]
			-- Every book, without its chapters, in the pack's order.
		require
			available: is_available
		local
			l_sql: STRING_8
			l_list: ARRAYED_LIST [BIB_AUTHOR_BOOK]
			l_provenance: BIB_PROVENANCE
		do
			l_provenance := pack_provenance
			l_sql := "SELECT book_id, title, subtitle, status, edition, year, description FROM " + pack_alias + ".book ORDER BY ordinal"
			run_query (l_sql, {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				create l_list.make (al_rows.rows.count)
				across al_rows.rows as ic loop
					if attached book_of_row (ic, l_provenance) as al_book then
						l_list.extend (al_book)
					end
				end
				create Result.make_success (method ("books", l_sql, pack_alias, "all", l_list.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_list)
			else
				create Result.make_failure (method ("books", l_sql, pack_alias, "all", 0), query_error)
			end
		end

	book (a_id: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_AUTHOR_BOOK]
			-- Book `a_id' with its chapters, or no item when the pack has none by that id.
		require
			available: is_available
		local
			l_sql: STRING_8
			l_list: ARRAYED_LIST [BIB_AUTHOR_BOOK]
			l_provenance: BIB_PROVENANCE
			l_book: detachable BIB_AUTHOR_BOOK
		do
			l_provenance := pack_provenance
			l_sql := "SELECT book_id, title, subtitle, status, edition, year, description FROM " + pack_alias + ".book WHERE book_id = ?"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_id.to_string_32>>)
			if attached last_rows as al_rows then
				create l_list.make (1)
				across al_rows.rows as ic loop
					l_book := book_of_row (ic, l_provenance)
				end
				if attached l_book as al_book then
					run_query ("SELECT chapter, title, kind FROM " + pack_alias + ".book_chapter WHERE book_id = ? ORDER BY chapter", {ARRAY [detachable ANY]} <<al_book.id>>)
					if attached last_rows as al_chapters then
						across al_chapters.rows as ic loop
							al_book.chapters.extend ([ic.integer_value ("chapter"), ic.string_value ("title"), ic.string_value ("kind")])
						end
						l_list.extend (al_book)
					end
				end
				if l_book = Void or else not l_list.is_empty then
					create Result.make_success (method ("book", l_sql, pack_alias, a_id, l_list.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_list)
				else
					create Result.make_failure (method ("book", l_sql, pack_alias, a_id, 0), query_error)
				end
			else
				create Result.make_failure (method ("book", l_sql, pack_alias, a_id, 0), query_error)
			end
		ensure
			at_most_one: Result.count <= 1
		end

	chapter_blocks (a_book: READABLE_STRING_GENERAL; a_chapter: INTEGER): BIB_LIST_RESULT [BIB_BOOK_BLOCK]
			-- Every block of chapter `a_chapter' of book `a_book', in order.
		require
			available: is_available
			chapter_positive: a_chapter >= 1
		local
			l_sql: STRING_8
		do
			l_sql := blocks_sql + "WHERE b.book_id = ? AND b.chapter = ? ORDER BY b.block"
			Result := blocks_answer ("chapter_blocks", l_sql, {ARRAY [detachable ANY]} <<a_book.to_string_32, a_chapter>>, a_book.to_string_32 + {STRING_32} "/" + a_chapter.out.to_string_32)
		end

	blocks_citing (a_book, a_chapter, a_verse: INTEGER): BIB_LIST_RESULT [BIB_BOOK_BLOCK]
			-- The blocks whose Bible references cover `a_book' `a_chapter':`a_verse' (English
			-- numbering), the narrowest passage first, each block once.
		require
			available: is_available
			place: (create {BIB_HUB_ID}).is_place (a_book, a_chapter, a_verse)
		local
			l_sql: STRING_8
		do
			l_sql := blocks_sql + "JOIN (SELECT book_id, chapter, block, min(end_hub - start_hub) AS width FROM " + pack_alias
				+ ".book_passage WHERE ? BETWEEN start_hub AND end_hub GROUP BY book_id, chapter, block) p ON p.book_id = b.book_id AND p.chapter = b.chapter AND p.block = b.block "
				+ "ORDER BY p.width, k.ordinal, b.chapter, b.block"
			Result := blocks_answer ("blocks_citing", l_sql, {ARRAY [detachable ANY]} <<(create {BIB_HUB_ID}).hub_id (a_book, a_chapter, a_verse)>>,
				a_book.out.to_string_32 + {STRING_32} " " + a_chapter.out.to_string_32 + {STRING_32} ":" + a_verse.out.to_string_32)
		end

	blocks_naming (a_framework: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_BOOK_BLOCK]
			-- The blocks that name framework `a_framework', in the books' order.
		require
			available: is_available
		local
			l_sql: STRING_8
		do
			l_sql := blocks_sql + "JOIN " + pack_alias + ".book_framework f ON f.book_id = b.book_id AND f.chapter = b.chapter AND f.block = b.block WHERE f.framework_id = ? ORDER BY k.ordinal, b.chapter, b.block"
			Result := blocks_answer ("blocks_naming", l_sql, {ARRAY [detachable ANY]} <<a_framework.to_string_32>>, a_framework)
		end

feature {NONE} -- Implementation

	blocks_sql: STRING_8
			-- The blocks with their book's and chapter's titles, before a WHERE.
		do
			Result := "SELECT b.book_id, b.chapter, b.block, b.kind, b.level, b.body_markdown, k.title AS book_title, c.title AS chapter_title FROM "
				+ pack_alias + ".book_block b JOIN " + pack_alias + ".book k ON k.book_id = b.book_id JOIN " + pack_alias
				+ ".book_chapter c ON c.book_id = b.book_id AND c.chapter = b.chapter "
		end

	blocks_answer (a_feature, a_sql: STRING_8; a_args: ARRAY [detachable ANY]; a_scope: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_BOOK_BLOCK]
			-- The blocks `a_sql' selects, as an answer.
		local
			l_list: ARRAYED_LIST [BIB_BOOK_BLOCK]
			l_provenance: BIB_PROVENANCE
		do
			l_provenance := pack_provenance
			run_query (a_sql, a_args)
			if attached last_rows as al_rows then
				create l_list.make (al_rows.rows.count)
				across al_rows.rows as ic loop
						-- BIB_BOOK_BLOCK's preconditions, so a row a link could not name is passed over (scan 60)
					if (create {BIB_BOOK_SCHEMA}).is_book_id (ic.string_value ("book_id")) and then ic.integer_value ("chapter") >= 1 and then ic.integer_value ("block") >= 1
						and then ic.integer_value ("chapter") <= {BIB_BOOK_SCHEMA}.Max_part and then ic.integer_value ("block") <= {BIB_BOOK_SCHEMA}.Max_part
					then
						l_list.extend (create {BIB_BOOK_BLOCK}.make (ic.string_value ("book_id"), ic.integer_value ("chapter"), ic.integer_value ("block"),
							ic.string_value ("kind"), ic.integer_value ("level"), ic.string_value ("body_markdown"), ic.string_value ("book_title"),
							ic.string_value ("chapter_title"), l_provenance))
					end
				end
				create Result.make_success (method (a_feature, a_sql, pack_alias, a_scope, l_list.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_list)
			else
				create Result.make_failure (method (a_feature, a_sql, pack_alias, a_scope, 0), query_error)
			end
		end

	book_of_row (a_row: SIMPLE_SQL_ROW; a_provenance: BIB_PROVENANCE): detachable BIB_AUTHOR_BOOK
			-- The book a row names; Void when the row breaks BIB_AUTHOR_BOOK's preconditions.
		do
			if (create {BIB_BOOK_SCHEMA}).is_book_id (a_row.string_value ("book_id")) and then not a_row.string_value ("title").is_empty then
				create Result.make (a_row.string_value ("book_id"), a_row.string_value ("title"), a_row.string_value ("subtitle"), a_row.string_value ("status"),
					a_row.string_value ("edition"), a_row.integer_value ("year"), a_row.string_value ("description"), a_provenance)
			end
		end

	query_failed_message: STRING_8 = "A books query failed."
	not_open_message: STRING_8 = "The books pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "books pack"
		end

end
