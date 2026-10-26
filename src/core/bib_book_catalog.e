note
	description: "[
		Resolves book names and aliases to canonical books (rix R12 alias table)
		and knows chapter counts per versification system. Never guesses: an
		ambiguous abbreviation ("Ju", "Ph") yields every candidate.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_CATALOG

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
			-- A catalog over `a_sources', read from content.db's `book_catalog' when it is open.
		do
			sources := a_sources
			create books.make (90)
			create aliases.make (400)
			if a_sources.is_open then
				load
			end
		ensure
			sources_set: sources = a_sources
		end

feature {NONE} -- Loading

	load
			-- Read every book of content.db's `book_catalog' (FR-105 ids), each known by its name
			-- and its code, lowercased (research/18).
		require
			open: sources.is_open
		local
			l_id: INTEGER
			l_code, l_name: STRING_32
		do
			books.wipe_out
			aliases.wipe_out
			if attached sources.database as al_db then
				across al_db.query ("SELECT book_id, code, name, is_deuterocanonical FROM main.book_catalog ORDER BY book_id").rows as ic loop
					l_id := ic.integer_value ("book_id")
					l_code := ic.string_value ("code")
					l_name := ic.string_value ("name")
					if l_id > 0 and not l_code.is_empty and not l_name.is_empty then
						books.force (create {BIB_BOOK}.make (l_id, l_code, l_name, ic.integer_value ("is_deuterocanonical") /= 0), l_id)
						aliases.force (l_id, l_name.as_lower)
						aliases.force (l_id, l_code.as_lower)
					end
				end
			end
		end

feature -- Access

	book_count: INTEGER
			-- Number of canonical books.
		do
			Result := books.count
		ensure
			model_agrees: Result = books_model.count
		end

	book (a_book_id: INTEGER): BIB_BOOK
			-- The book with id `a_book_id'.
		require
			known: has_book (a_book_id)
		do
			if attached books.item (a_book_id) as l_book then
				Result := l_book
			else
				check known: False then end
			end
		ensure
			model_agrees: Result = books_model [a_book_id]
		end

	candidates_for_name (a_name: READABLE_STRING_GENERAL): ARRAYED_LIST [INTEGER]
			-- Ids of every book `a_name' may denote (exact alias, then prefix); empty when none.
		require
			name_not_empty: not a_name.is_empty
		local
			l_key: STRING_32
			i: INTEGER
		do
			create Result.make (4)
			l_key := a_name.to_string_32.as_lower
			l_key.right_adjust
			l_key.left_adjust
			if aliases.has (l_key) then
				Result.extend (aliases.item (l_key))
			else
				if l_key.ends_with (".") then
					l_key.remove_tail (1)
				end
				if not l_key.is_empty then
					across aliases as a loop
						if (@a.key).starts_with (l_key) and not Result.has (a) then
								-- Keep the ids in order, so the same name always lists the same books (NFR-006).
							from i := 1 until i > Result.count or else Result.i_th (i) > a loop
								i := i + 1
							end
							Result.go_i_th (i)
							Result.put_left (a)
						end
					end
				end
			end
		ensure
			all_known: across Result as b all has_book (b) end
			alias_is_single: aliases_model.domain [a_name.to_string_32.as_lower] implies Result.count = 1
		end

	chapter_count (a_book_id: INTEGER; a_system: BIB_VERSIFICATION_SYSTEM): INTEGER
			-- Chapters of `a_book_id' in `a_system' (0 when the system lacks the book).
		require
			known: has_book (a_book_id)
		do
			-- Phase 4: from content.db `versification_system' rows.
		ensure
			non_negative: Result >= 0
		end

feature -- Status

	has_book (a_book_id: INTEGER): BOOLEAN
			-- Is `a_book_id' a canonical book?
		do
			Result := books.has (a_book_id)
		ensure
			model_agrees: Result = books_model.domain [a_book_id]
		end

feature -- Model

	books_model: MML_MAP [INTEGER, BIB_BOOK]
			-- Canonical id to book.
		do
			create Result
			across books as b loop
				Result := Result.updated (@b.key, b)
			end
		end

	aliases_model: MML_MAP [STRING_32, INTEGER]
			-- Lowercased alias to canonical id.
		do
			create Result
			across aliases as a loop
				Result := Result.updated (@a.key, a)
			end
		end

feature {NONE} -- Representation

	sources: BIB_SOURCE_SET
	books: HASH_TABLE [BIB_BOOK, INTEGER]
	aliases: HASH_TABLE [INTEGER, STRING_32]

invariant
	book_count_non_negative: book_count >= 0

end
