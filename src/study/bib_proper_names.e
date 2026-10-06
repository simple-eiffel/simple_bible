note
	description: "TIPNR people and places with references and relations (CLI `people')."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PROPER_NAMES

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
		end

feature -- Query

	person (a_name: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_PROPER_NAME]
		require
			name_not_empty: not a_name.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			people_only: across 1 |..| Result.count as i all Result.item (i).kind = {BIB_PROPER_NAME}.Person end
			fact_closure: Result.is_fact_closed
		end

	place (a_name: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_PROPER_NAME]
		require
			name_not_empty: not a_name.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			places_only: across 1 |..| Result.count as i all Result.item (i).kind = {BIB_PROPER_NAME}.Place end
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
