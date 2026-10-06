note
	description: "[
		One run of a frozen definition version: the four buckets (always all
		four), the target against every control, the control verdict and the
		method. A cancelled run has no findings and no verdict (A-005).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CENSUS_RUN

inherit
	BIB_ENGINE_RESULT

create
	make_completed, make_cancelled

feature {NONE} -- Initialization

	make_completed (a_run_id: INTEGER_64; a_definition: BIB_CENSUS_DEFINITION; a_buckets: BIB_BUCKETED_RESULT [BIB_FINDING];
			a_comparisons: ITERABLE [BIB_CONTROL_COMPARISON]; a_verdict: BIB_VERDICT; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			run_positive: a_run_id > 0
			stored_definition: a_definition.is_stored
			bound: a_buckets.definition_id = a_definition.id
			sealed: a_buckets.is_sealed
			cited: across a_citations as c some True end
		do
			id := a_run_id
			definition_id := a_definition.id
			definition_version := a_definition.version
			buckets := a_buckets
			control_verdict := a_verdict
			create comparisons.make (4)
			across a_comparisons as c loop
				comparisons.extend (c)
			end
			set_success (a_method, a_citations)
		ensure
			success: is_success
			not_cancelled: not was_cancelled
		end

	make_cancelled (a_definition: BIB_CENSUS_DEFINITION; a_method: BIB_METHOD)
			-- A run stopped by its cancel token: no findings, no verdict.
		require
			stored_definition: a_definition.is_stored
		do
			definition_id := a_definition.id
			definition_version := a_definition.version
			create buckets.make (a_definition.id)
			create comparisons.make (0)
			was_cancelled := True
			set_failure (a_method, create {BIB_ERROR}.make ({BIB_ERROR}.Cancelled, {STRING_32} "Census cancelled; no findings."))
		ensure
			cancelled: was_cancelled
			empty: buckets.total = 0
		end

feature -- Access

	id: INTEGER_64
	definition_id: INTEGER_64
	definition_version: INTEGER
	buckets: BIB_BUCKETED_RESULT [BIB_FINDING]
	was_cancelled: BOOLEAN
	control_verdict: detachable BIB_VERDICT

	control_count: INTEGER
		do
			Result := comparisons.count
		end

feature -- Model

	comparisons_model: MML_SEQUENCE [BIB_CONTROL_COMPARISON]
		do
			create Result
			across comparisons as c loop
				Result := Result & c
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- Every finding and every control comparison.
		local
			l_findings: MML_SEQUENCE [BIB_FINDING]
			i: INTEGER
		do
			create Result
			l_findings := buckets.findings_model
			from
				i := 1
			until
				i > l_findings.count
			loop
				Result := Result & l_findings [i]
				i := i + 1
			end
			across comparisons as c loop
				Result := Result & c
			end
		end

feature {NONE} -- Representation

	comparisons: ARRAYED_LIST [BIB_CONTROL_COMPARISON]

invariant
	bound: buckets.definition_id = definition_id
	cancelled_empty: was_cancelled implies buckets.total = 0
	verdict_only_when_complete: control_verdict /= Void implies not was_cancelled
	cancelled_is_not_success: was_cancelled implies not is_success
	version_positive: definition_version >= 1

end
