note
	description: "[
		Runs a frozen definition version into a run (FR-025..027): freezes at the
		first run, counts per canonical hub id (RQ-12, AC-1a-17), always returns
		all four buckets and the controls (AC-1a-25), and re-running the same
		definition on the same edition gives identical counts (AC-1a-24).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CENSUS_ENGINE

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_concordance: BIB_CONCORDANCE)
		do
			sources := a_sources
			concordance := a_concordance
		ensure
			concordance_set: concordance = a_concordance
		end

feature -- Access

	concordance: BIB_CONCORDANCE

feature -- Controls

	proposed_controls (a_definition: BIB_CENSUS_DEFINITION; a_target: BIB_KEY): BIB_CONTROL_SET
			-- Frequency-matched controls for `a_target' with the definition's seed.
		require
			target_in_criteria: a_definition.criteria.mentions_key (a_target)
		do
			check implemented_in_phase_4: False then end
		ensure
			seeded: Result.seed = a_definition.control_seed
			target_excluded: not Result.keys_model.has (a_target)
		end

feature -- Execution

	run (a_definition: BIB_CENSUS_DEFINITION; a_token: separate BIB_CANCEL_TOKEN): BIB_CENSUS_RUN
			-- Freeze `a_definition' (first run), count chunk by chunk, compare controls.
		require
			complete: a_definition.is_complete
			stored: a_definition.is_stored
		do
			check implemented_in_phase_4: False then end
		ensure
			definition_frozen: a_definition.is_frozen
			bound: Result.definition_id = a_definition.id and Result.definition_version = a_definition.version
			four_buckets: Result.buckets.total = Result.buckets.count (create {BIB_VERDICT}.make_fits) + Result.buckets.count (create {BIB_VERDICT}.make_partial)
				+ Result.buckets.count (create {BIB_VERDICT}.make_fails) + Result.buckets.count (create {BIB_VERDICT}.make_no_data)
			cancelled_means_no_findings: Result.was_cancelled implies Result.buckets.total = 0
			counted_per_hub_id: not Result.was_cancelled implies Result.buckets.distinct_hub_count = Result.buckets.total
			controls_compared: not Result.was_cancelled implies Result.control_count = a_definition.controls_count
			scope_stated: Result.method.scope_label.same_string (a_definition.corpus.label)
			method_recorded: Result.method.engine_feature.same_string_general ("census")
			fact_closure: Result.is_fact_closed
		end

	start_run (a_definition: BIB_CENSUS_DEFINITION): BIB_CENSUS_JOB
			-- A new, unstarted job for `a_definition' (the freeze happens when the job runs).
		require
			complete: a_definition.is_complete
			stored: a_definition.is_stored
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
			definition_unchanged: a_definition.is_frozen = old a_definition.is_frozen
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
