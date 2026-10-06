note
	description: "The Release 1 adapter: no model runs on the user's machine (D-016); it never produces text (AC-1a-54)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NULL_AI_ADAPTER

inherit
	BIB_AI_ADAPTER

feature -- Explanation

	explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
		do
		ensure then
			never_produces: Result = Void
		end

end
