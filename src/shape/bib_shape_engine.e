note
	description: "[
		Runs shapes (build time, through the build's precompute) and returns
		their evidence (run time). Refuses T3 as evidence (AC-1a-25). Every
		answer carries all four buckets, sealed.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_ENGINE

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
			create registry.make
		end

feature -- Access

	registry: BIB_SHAPE_REGISTRY

feature -- Evidence (run time)

	evidence (a_shape: BIB_SHAPE): BIB_SHAPE_RUN
			-- All four buckets for `a_shape', read from the shape tables.
		require
			not_judgment: not a_shape.tier.is_judgment
			registered: registry.has_slug (a_shape.slug)
		do
			check implemented_in_phase_4: False then end
		ensure
			all_buckets: Result.buckets.is_sealed
			tier_carried: Result.tier ~ a_shape.tier
			same_shape: Result.slug.same_string (a_shape.slug)
			method_recorded: Result.method.engine_feature.same_string_general ("shape")
			fact_closure: Result.is_fact_closed
		end

feature -- Execution (build time)

	run (a_shape: BIB_SHAPE; a_corpus: BIB_SEARCH_SCOPE): BIB_SHAPE_RUN
			-- Classify every candidate of `a_corpus' (T3 runs never produce evidence).
		require
			registered: registry.has_slug (a_shape.slug)
		do
			check implemented_in_phase_4: False then end
		ensure
			all_buckets: Result.buckets.is_sealed
			tier_carried: Result.tier ~ a_shape.tier
			t3_never_evidence: a_shape.tier.is_judgment implies Result.has_no_evidence_findings
			counted_per_hub_id: Result.buckets.distinct_hub_count = Result.buckets.total
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
