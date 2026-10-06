note
	description: "[
		An engine answer holding an ordered list of sourced items: cross-references,
		related passages, library entries, author documents, names, verse texts
		and marks. Every item is a BIB_SOURCED (RQ-02), so plain values travel as
		BIB_FACT [G].
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LIST_RESULT [G -> BIB_SOURCED]

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE]; a_items: ITERABLE [G])
			-- Successful list answer.
		require
			cited: across a_citations as c some True end
		do
			create items.make (8)
			across a_items as i loop
				items.extend (i)
			end
			set_success (a_method, a_citations)
		ensure
			success: is_success
			method_set: method = a_method
		end

	make_failure (a_method: BIB_METHOD; a_error: BIB_ERROR)
			-- Failed list answer.
		do
			create items.make (0)
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
			error_set: error = a_error
			empty: count = 0
		end

feature -- Access

	count: INTEGER
			-- Number of items.
		do
			Result := items.count
		end

	item (i: INTEGER): G
			-- The `i'-th item.
		require
			in_range: i >= 1 and i <= count
		do
			Result := items [i]
		ensure
			model_agrees: Result = items_model [i]
		end

feature -- Model

	items_model: MML_SEQUENCE [G]
			-- Items, in order.
		do
			create Result
			across items as i loop
				Result := Result & i
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- Every item is a fact.
		do
			create Result
			across items as i loop
				Result := Result & i
			end
		end

feature {NONE} -- Representation

	items: ARRAYED_LIST [G]

invariant
	failure_is_empty: not is_success implies count = 0

end
