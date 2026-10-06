note
	description: "Renderings of a lemma with counts and examples (I-P09): every distinct gloss, counted, before any ruling."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RANGE_VIEWER

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
		end

feature -- Query

	range (a_key: BIB_KEY): BIB_RANGE_RESULT
		do
			check implemented_in_phase_4: False then end
		ensure
			same_key: Result.key ~ a_key
			distinct_glosses: Result.is_success implies Result.has_distinct_glosses
			method_recorded: Result.method.engine_feature.same_string_general ("range")
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
