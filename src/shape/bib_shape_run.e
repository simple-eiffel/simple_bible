note
	description: "The evidence of one shape: four buckets of shape findings (always all four), raw candidate count, tier and method."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_RUN

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_slug: READABLE_STRING_GENERAL; a_tier: BIB_SHAPE_TIER; a_buckets: BIB_BUCKETED_RESULT [BIB_SHAPE_FINDING]; a_raw_candidates: INTEGER;
			a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			sealed: a_buckets.is_sealed
			candidates_cover_findings: a_raw_candidates >= a_buckets.total
			cited: across a_citations as c some True end
		do
			slug := a_slug.to_string_32
			tier := a_tier
			buckets := a_buckets
			raw_candidate_count := a_raw_candidates
			set_success (a_method, a_citations)
		ensure
			success: is_success
		end

	make_failure (a_slug: READABLE_STRING_GENERAL; a_tier: BIB_SHAPE_TIER; a_shape_id: INTEGER_64; a_method: BIB_METHOD; a_error: BIB_ERROR)
		require
			id_positive: a_shape_id > 0
		do
			slug := a_slug.to_string_32
			tier := a_tier
			create buckets.make (a_shape_id)
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
		end

feature -- Access

	slug: STRING_32
	tier: BIB_SHAPE_TIER
	buckets: BIB_BUCKETED_RESULT [BIB_SHAPE_FINDING]
	raw_candidate_count: INTEGER

	has_no_evidence_findings: BOOLEAN
			-- Is no finding marked as evidence (T3 runs)?
		local
			l_all: MML_SEQUENCE [BIB_SHAPE_FINDING]
			i: INTEGER
		do
			l_all := buckets.findings_model
			Result := True
			from
				i := 1
			until
				i > l_all.count or not Result
			loop
				Result := not l_all [i].is_evidence
				i := i + 1
			end
		end

feature -- Model

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		local
			l_all: MML_SEQUENCE [BIB_SHAPE_FINDING]
			i: INTEGER
		do
			create Result
			l_all := buckets.findings_model
			from
				i := 1
			until
				i > l_all.count
			loop
				Result := Result & l_all [i]
				i := i + 1
			end
		end

invariant
	failure_is_empty: not is_success implies buckets.total = 0

end
