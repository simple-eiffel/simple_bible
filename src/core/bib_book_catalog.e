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
			-- Create a catalog over `a_sources' (loaded from core.db `book_catalog' in Phase 4).
		do
			sources := a_sources
			create books.make (90)
			create aliases.make (400)
		ensure
			sources_set: sources = a_sources
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
		do
			check implemented_in_phase_4: False then end
		ensure
			all_known: across Result as b all has_book (b) end
			alias_is_single: aliases_model.domain [a_name.to_string_32.as_lower] implies Result.count = 1
		end

	chapter_count (a_book_id: INTEGER; a_system: BIB_VERSIFICATION_SYSTEM): INTEGER
			-- Chapters of `a_book_id' in `a_system' (0 when the system lacks the book).
		require
			known: has_book (a_book_id)
		do
			-- Phase 4: from core.db `versification_system' rows.
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
