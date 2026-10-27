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
			-- The scope `a_name' names in `a_version' ("OT", "NT", "Gospels", "Paul's letters", or a
			-- book: "Romans", "Psalms", "1 John"); Void when it names none or several books.
		require
			version_not_empty: not a_version.is_empty
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32.as_lower
			l_name.left_adjust
			l_name.right_adjust
			if l_name.same_string ({STRING_32} "ot") or l_name.same_string ({STRING_32} "old testament") then
				create Result.make ("Old Testament", <<a_version>>, 1, Last_old_testament_book, "verses")
			elseif l_name.same_string ({STRING_32} "nt") or l_name.same_string ({STRING_32} "new testament") then
				create Result.make ("New Testament", <<a_version>>, Last_old_testament_book + 1, Last_book, "verses")
			elseif l_name.same_string ({STRING_32} "gospels") then
				create Result.make ("the Gospels", <<a_version>>, 40, 43, "verses")
			elseif l_name.same_string ({STRING_32} "paul's letters") or l_name.same_string ({STRING_32} "pauline letters") or l_name.same_string ({STRING_32} "paul") then
				create Result.make ("Paul's letters", <<a_version>>, 45, 57, "verses")
			elseif not l_name.is_empty and then attached books.candidates_for_name (l_name) as al_books and then al_books.count = 1 then
				create Result.make (books.book (al_books.first).name, <<a_version>>, al_books.first, al_books.first, "verses")
			end
		end

	whole_bible (a_version: READABLE_STRING_8): BIB_SEARCH_SCOPE
			-- Every book.
		require
			version_not_empty: not a_version.is_empty
		do
			create Result.make ("the whole Bible", <<a_version>>, 1, Last_book, "verses")
		end

feature -- Constants

	Last_old_testament_book: INTEGER = 39
	Last_book: INTEGER = 66
			-- The Protestant canon's book numbers (the hub's numbering).

end
