note
	description: "[
		Library entries by verse, lemma, topic and date (FR-116). In 1a the
		resources are Strong's and the STEPBible glosses; content packs and rich
		text arrive in 1b (Q-01, GW-13).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LIBRARY

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
		end

feature -- Query

	entries_for_verse (a_mapped: BIB_MAPPED_REF; a_resource: STRING_8): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
		do
			check implemented_in_phase_4: False then end
		ensure
			one_resource: across 1 |..| Result.count as i all Result.item (i).resource_code.same_string (a_resource) end
			fact_closure: Result.is_fact_closed
		end

	entries_for_lemma (a_key: BIB_KEY; a_resource: STRING_8): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
		do
			check implemented_in_phase_4: False then end
		ensure
			one_resource: across 1 |..| Result.count as i all Result.item (i).resource_code.same_string (a_resource) end
			fact_closure: Result.is_fact_closed
		end

	entries_for_topic (a_topic: READABLE_STRING_GENERAL; a_resource: STRING_8): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
		require
			topic_not_empty: not a_topic.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			fact_closure: Result.is_fact_closed
		end

	entries_for_date (a_month, a_day: INTEGER; a_resource: STRING_8): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
		require
			month_valid: a_month >= 1 and a_month <= 12
			day_valid: a_day >= 1 and a_day <= 31
		do
			check implemented_in_phase_4: False then end
		ensure
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
