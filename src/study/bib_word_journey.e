note
	description: "Witnesses in time order with a method on every row (I-P07): ekklesia as Tyndale's 'congregation' and the KJV's 'church'."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_JOURNEY

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_versification: BIB_VERSIFICATION_MAP)
		do
			sources := a_sources
			versification := a_versification
		end

feature -- Query

	journey (a_key: BIB_KEY): BIB_JOURNEY_RESULT
		do
			check implemented_in_phase_4: False then end
		ensure
			same_key: Result.key ~ a_key
			time_ordered: Result.is_time_ordered
			method_recorded: Result.method.engine_feature.same_string_general ("journey")
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
	versification: BIB_VERSIFICATION_MAP

end
