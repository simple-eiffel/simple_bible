note
	description: "[
		Optional AI phrasing of one engine answer (later releases). Its input is
		an engine result, never free text, so a question can never reach a model
		without an engine answer (I-001). Release 1 binds BIB_NULL_AI_ADAPTER.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_AI_ADAPTER

feature -- Explanation

	explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
		require
			engine_answer: a_result.is_success
			cited: a_result.citation_count > 0
		deferred
		ensure
			rests_on_input: attached Result implies Result.basis = a_result
			labeled: attached Result implies Result.is_labeled
		end

end
