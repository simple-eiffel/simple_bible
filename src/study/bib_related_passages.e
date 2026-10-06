note
	description: "[
		Related passages with reasons from core.db (cross-reference votes, shared
		rare lemmas) and, when ai_data.db is present, labeled AI-made neighbors
		(FR-111). Without ai_data.db the answer degrades, never fails.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RELATED_PASSAGES

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_has_ai_data: BOOLEAN)
		do
			sources := a_sources
			has_ai_data := a_has_ai_data
		ensure
			ai_data_set: has_ai_data = a_has_ai_data
		end

feature -- Status

	has_ai_data: BOOLEAN

feature -- Query

	related (a_mapped: BIB_MAPPED_REF): BIB_LIST_RESULT [BIB_RELATED_PASSAGE]
		do
			check implemented_in_phase_4: False then end
		ensure
			ai_only_with_ai_data: not has_ai_data implies across 1 |..| Result.count as i all not Result.item (i).is_ai_made end
			not_self: across 1 |..| Result.count as i all Result.item (i).target_hub_id /= a_mapped.hub_id end
			method_recorded: Result.method.engine_feature.same_string_general ("related")
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
