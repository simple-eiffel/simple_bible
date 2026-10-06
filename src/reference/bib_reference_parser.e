note
	description: "[
		Reference text to valid, ambiguous or invalid references (FR-020, harvest
		S-09). Names the system it assumed. "Ju 1" and "Ph 1" are ambiguous and
		return every candidate (AC-1a-15).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REFERENCE_PARSER

create
	make

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
			-- Create a parser over `a_books'.
		do
			books := a_books
		ensure
			books_set: books = a_books
		end

feature -- Access

	books: BIB_BOOK_CATALOG

feature -- Parsing

	parse (a_text: READABLE_STRING_GENERAL; a_default_system: BIB_VERSIFICATION_SYSTEM): BIB_PARSE_RESULT
			-- Parse `a_text', assuming `a_default_system' unless the text names one.
		require
			text_not_empty: not a_text.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			system_named: Result.is_valid implies Result.system /= Void
			never_guesses: Result.is_ambiguous implies Result.candidates_model.count >= 2
			error_located: Result.is_invalid implies (Result.error_position >= 1 and Result.error_position <= a_text.count + 1)
			books_known: Result.is_valid implies (attached Result.ref as r and then books.has_book (r.book_id))
			candidates_known: across 1 |..| Result.candidate_count as i all books.has_book (Result.candidate (i).book_id) end
		end

end
