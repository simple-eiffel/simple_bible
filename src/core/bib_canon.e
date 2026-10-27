note
	description: "[
		The book numbers of the canon the hub counts in (Genesis 1 to Revelation
		66, KJV order): the testaments, the Gospels and Paul's letters. One owner
		(design scan 51: 39 and 66 were declared in three classes and written as
		literals in four more). Read as {BIB_CANON}.Last_book.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CANON

feature -- Constants

	First_book: INTEGER = 1
	Last_old_testament_book: INTEGER = 39
	First_new_testament_book: INTEGER = 40
	Last_book: INTEGER = 66
			-- Genesis, Malachi, Matthew, Revelation.

	First_gospel: INTEGER = 40
	Last_gospel: INTEGER = 43
			-- Matthew to John.

	First_letter_of_paul: INTEGER = 45
	Last_letter_of_paul: INTEGER = 57
			-- Romans to Philemon.

end
