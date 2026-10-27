note
	description: "[
		Named search scopes (NEEDLE run 7's search_text scope, 2026-10-27): the
		Old and New Testaments, the Gospels, Paul's letters, or one book named
		as a reference box names it. Each becomes a BIB_SEARCH_SCOPE book range;
		BIB_VERSE_SEARCH keeps only the verses inside it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SEARCH_SCOPES

create
	make

feature {NONE} -- Initialization

	make (a_books: BIB_BOOK_CATALOG)
			-- Scopes over the books of `a_books'.
		do
			books := a_books
		ensure
			books_set: books = a_books
		end

feature -- Access

	books: BIB_BOOK_CATALOG

	scope_named (a_name: READABLE_STRING_GENERAL; a_version: READABLE_STRING_8): detachable BIB_SEARCH_SCOPE
			-- The scope `a_name' names in `a_version': a name of BIB_SCOPE_NAMES (Old Testament, OT,
			-- Gospels, Paul's letters, ...) or a book ("Romans", "Psalms", "1 John"); Void when it names
			-- none or several books.
		require
			version_not_empty: not a_version.is_empty
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32
			l_name.left_adjust
			l_name.right_adjust
			if attached (create {BIB_SCOPE_NAMES}).range_named (l_name) as al_range then
				create Result.make (al_range.name, <<a_version>>, al_range.from_book, al_range.to_book, "verses")
			elseif not l_name.is_empty and then attached books.candidates_for_name (l_name) as al_books and then al_books.count = 1 then
				create Result.make (books.book (al_books.first).name, <<a_version>>, al_books.first, al_books.first, "verses")
			end
		end

	whole_bible (a_version: READABLE_STRING_8): BIB_SEARCH_SCOPE
			-- Every book.
		require
			version_not_empty: not a_version.is_empty
		do
			create Result.make ({BIB_SCOPE_NAMES}.Whole_bible_name, <<a_version>>, {BIB_CANON}.First_book, {BIB_CANON}.Last_book, "verses")
		end

end
