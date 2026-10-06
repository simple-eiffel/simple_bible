note
	description: "[
		Every engine answer: method, citations (the sources consulted), success
		xor error. Immutable once created.

		Fact closure (RQ-02, AC-1a-32): every value a result exposes is a
		BIB_SOURCED listed by `facts_model'; `is_fact_closed' says every such
		value's provenance is among the citations. Engine features state it as
		a POSTCONDITION (`fact_closure: Result.is_fact_closed'), never as an
		invariant, because it is O(n) (C-019).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_ENGINE_RESULT

feature {NONE} -- Initialization (for descendants)

	set_success (a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
			-- Make this a successful answer recorded by `a_method', citing `a_citations'.
		require
			cited: across a_citations as c some True end
		do
			method := a_method
			create citations.make (4)
			across a_citations as c loop
				citations.extend (c)
			end
			is_success := True
			error := Void
		ensure
			success: is_success
			no_error: error = Void
			method_set: method = a_method
			cited: citation_count > 0
		end

	set_failure (a_method: BIB_METHOD; a_error: BIB_ERROR)
			-- Make this a failed answer with `a_error'.
		do
			method := a_method
			create citations.make (0)
			is_success := False
			error := a_error
		ensure
			failed: not is_success
			error_set: error = a_error
			method_set: method = a_method
		end

feature -- Access

	is_success: BOOLEAN
			-- Did the engine answer?

	error: detachable BIB_ERROR
			-- Why not, when not.

	method: BIB_METHOD
			-- How the answer was produced (re-runnable, FR-032).

	citation_count: INTEGER
			-- Number of sources consulted.
		do
			Result := citations.count
		end

	citation (i: INTEGER): BIB_PROVENANCE
			-- The `i'-th source consulted.
		require
			in_range: i >= 1 and i <= citation_count
		do
			Result := citations [i]
		ensure
			model_agrees: Result = citations_model [i]
		end

	cites (a_provenance: BIB_PROVENANCE): BOOLEAN
			-- Is `a_provenance' among the citations?
		do
			Result := citations_model.has (a_provenance)
		ensure
			definition: Result = citations_model.has (a_provenance)
		end

feature -- Status

	is_fact_closed: BOOLEAN
			-- Is the provenance of every fact this result carries among its citations? (RQ-02)
		local
			l_facts: like facts_model
			i: INTEGER
		do
			l_facts := facts_model
			Result := True
			from
				i := 1
			until
				i > l_facts.count or not Result
			loop
				Result := cites (l_facts [i].provenance)
				i := i + 1
			end
		end

	has_ai_made_citation: BOOLEAN
			-- Is any cited source AI-made?
		do
			Result := across citations as c some c.is_ai_made end
		end

	has_share_alike_citation: BOOLEAN
			-- Does any cited source require share-alike?
		do
			Result := across citations as c some c.is_share_alike end
		end

feature -- Model

	citations_model: MML_SEQUENCE [BIB_PROVENANCE]
			-- Sources consulted, in order.
		do
			create Result
			across citations as c loop
				Result := Result & c
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- Every value this result carries, each with its provenance.
		deferred
		end

feature {NONE} -- Representation

	citations: ARRAYED_LIST [BIB_PROVENANCE]

invariant
	success_xor_error: is_success xor (error /= Void)
	success_is_cited: is_success implies citation_count > 0
	citation_count_non_negative: citation_count >= 0

end
