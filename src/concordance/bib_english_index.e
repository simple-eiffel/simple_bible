note
	description: "The English lookup (D-021, debate 05b). An English word to the original words behind it, Bible by Bible, with counts."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ENGLISH_INDEX

create
	make

feature {NONE} -- Initialization

	make (a_pack: BIB_CONC_PACK)
		do
			pack := a_pack
		ensure
			pack_set: pack = a_pack
		end

feature -- Query

	rows (a_english: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_ENGLISH_ROW]
			-- Candidates behind `a_english', one row per original word and book.
		require
			available: pack.is_available
			word_not_empty: not a_english.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("english_rows")
			every_row_for_word: Result.is_success implies across 1 |..| Result.count as l_i all Result.item (l_i).english.same_string_general (a_english) end
			fact_closure: Result.is_fact_closed
		end

feature -- Access

	pack: BIB_CONC_PACK
			-- The pack read (exported: preconditions use it).

end
