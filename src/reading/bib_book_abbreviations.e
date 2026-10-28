note
	description: "[
		The abbreviations prose writes for the books of the Bible (2026-10-28), the
		standard short forms (the SBL Handbook's, and the common ones beside them)
		and the singular "Psalm": "Gen", "Exod", "Ex", "1 Sam", "1 Kgs", "Ps",
		"Psa", "Psalm", "Song", "Isa", "Matt", "1 Cor", "Heb", "Jas", "1 Pet",
		"Rev" and the rest, each to its book number (1 Genesis ... 66 Revelation).
		The prose reader (BIB_REFERENCE_LINKER) asks here when content.db's catalog
		does not know a name exactly: the commentary writes "Heb 13:8" and Larry's
		books "1 Kgs 19:18". Case counts ("Ex" yes, "ex" no), and no form here is
		an ordinary English word written with a capital and a number after it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_BOOK_ABBREVIATIONS

feature -- Access

	book_of (a_name: READABLE_STRING_GENERAL): INTEGER
			-- The book number `a_name' abbreviates; 0 for none.
		do
			if table.has (a_name.to_string_32) then
				Result := table.item (a_name.to_string_32)
			end
		ensure
			a_book: Result >= 0 and Result <= 66
		end

feature {NONE} -- Implementation

	table: HASH_TABLE [INTEGER, STRING_32]
			-- Every abbreviation, to its book.
		once
			create Result.make (200)
			put (Result, 1, "Gen Gn")
			put (Result, 2, "Exod Ex Exo")
			put (Result, 3, "Lev Lv")
			put (Result, 4, "Num Nm")
			put (Result, 5, "Deut Dt")
			put (Result, 6, "Josh")
			put (Result, 7, "Judg Jdg")
			put (Result, 8, "Ruth")
			put (Result, 9, "1_Sam 1_Samuel 1Sam")
			put (Result, 10, "2_Sam 2_Samuel 2Sam")
			put (Result, 11, "1_Kgs 1_Kings 1Kgs 1_Kgdms")
			put (Result, 12, "2_Kgs 2_Kings 2Kgs")
			put (Result, 13, "1_Chr 1_Chron 1Chr")
			put (Result, 14, "2_Chr 2_Chron 2Chr")
			put (Result, 15, "Ezra")
			put (Result, 16, "Neh")
			put (Result, 17, "Esth")
			put (Result, 18, "Job")
			put (Result, 19, "Ps Psa Pss Psalm")
			put (Result, 20, "Prov Prv")
			put (Result, 21, "Eccl Eccles Qoh")
			put (Result, 22, "Song Songs Cant Song_of_Sol")
			put (Result, 23, "Isa")
			put (Result, 24, "Jer")
			put (Result, 25, "Lam")
			put (Result, 26, "Ezek Ezk")
			put (Result, 27, "Dan Dn")
			put (Result, 28, "Hos")
			put (Result, 29, "Joel")
			put (Result, 30, "Amos")
			put (Result, 31, "Obad Ob")
			put (Result, 32, "Jonah Jon")
			put (Result, 33, "Mic")
			put (Result, 34, "Nah")
			put (Result, 35, "Hab")
			put (Result, 36, "Zeph")
			put (Result, 37, "Hag")
			put (Result, 38, "Zech")
			put (Result, 39, "Mal")
			put (Result, 40, "Matt Mt")
			put (Result, 41, "Mark Mk")
			put (Result, 42, "Luke Lk")
			put (Result, 43, "John Jn")
			put (Result, 44, "Acts")
			put (Result, 45, "Rom")
			put (Result, 46, "1_Cor 1Cor")
			put (Result, 47, "2_Cor 2Cor")
			put (Result, 48, "Gal")
			put (Result, 49, "Eph")
			put (Result, 50, "Phil")
			put (Result, 51, "Col")
			put (Result, 52, "1_Thess 1_Thes 1Thess")
			put (Result, 53, "2_Thess 2_Thes 2Thess")
			put (Result, 54, "1_Tim 1Tim")
			put (Result, 55, "2_Tim 2Tim")
			put (Result, 56, "Titus Tit")
			put (Result, 57, "Phlm Philem")
			put (Result, 58, "Heb")
			put (Result, 59, "Jas")
			put (Result, 60, "1_Pet 1Pet")
			put (Result, 61, "2_Pet 2Pet")
			put (Result, 62, "1_John 1_Jn 1John")
			put (Result, 63, "2_John 2_Jn 2John")
			put (Result, 64, "3_John 3_Jn 3John")
			put (Result, 65, "Jude")
			put (Result, 66, "Rev")
		end

	put (a_table: HASH_TABLE [INTEGER, STRING_32]; a_book: INTEGER; a_forms: STRING_32)
			-- Each of the space-separated `a_forms' (an underscore stands for a space) abbreviates
			-- book `a_book', into `a_table'.
		require
			a_book: a_book >= 1 and a_book <= 66
		local
			l_form: STRING_32
		do
			across a_forms.split (' ') as ic loop
				l_form := ic.twin
				l_form.replace_substring_all ({STRING_32} "_", {STRING_32} " ")
				a_table.force (a_book, l_form)
			end
		end

end
