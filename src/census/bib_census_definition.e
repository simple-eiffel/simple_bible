note
	description: "[
		A question written down before counting (FR-025, I-002, DR-006). Editable
		until its first run; then frozen and only versioned (AC-1a-24): every
		setter requires `not is_frozen', and `freeze' is exported only to the
		census engine and job.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CENSUS_DEFINITION

create
	make

feature {NONE} -- Initialization

	make (a_question: READABLE_STRING_GENERAL; a_corpus: BIB_SEARCH_SCOPE)
			-- A new, unfrozen definition over `a_corpus'.
		require
			question_not_empty: not a_question.is_empty
		do
			question := a_question.to_string_32
			corpus := a_corpus
			corpus_label := a_corpus.label
			create criteria.make_empty (a_corpus)
			create holds_if.make_empty
			create fails_if.make_empty
			create controls.make (4)
			version := 1
			control_seed := Default_seed
		ensure
			first_version: version = 1
			editable: not is_frozen
			not_stored: not is_stored
			no_controls: controls_count = 0
			question_set: question.same_string_general (a_question)
		end

feature -- Access

	id: INTEGER_64
			-- 0 until stored.

	lineage_id: INTEGER_64
			-- Id of the first version of this definition (0 until stored).

	version: INTEGER
	question: STRING_32
	corpus_label: STRING_32
	corpus: BIB_SEARCH_SCOPE
	criteria: BIB_QUERY
	holds_if: STRING_32
	fails_if: STRING_32
	control_seed: INTEGER_64
	first_run_id: INTEGER_64

	controls_count: INTEGER
		do
			Result := controls.count
		ensure
			model_agrees: Result = controls_model.count
		end

feature -- Status

	is_frozen: BOOLEAN

	is_stored: BOOLEAN
		do
			Result := id > 0
		end

	has_control_named_by (a_criteria: BIB_QUERY): BOOLEAN
			-- Does `a_criteria' name one of the controls as a target?
		do
			Result := across controls as c some a_criteria.mentions_key (c) end
		end

	is_complete: BOOLEAN
		do
			Result := not question.is_empty and not corpus_label.is_empty and criteria.clause_count > 0
				and controls_count >= 1 and not holds_if.is_empty and not fails_if.is_empty
		end

feature -- Model

	controls_model: MML_SEQUENCE [BIB_KEY]
		do
			create Result
			across controls as c loop
				Result := Result & c
			end
		end

feature -- Element change (only before the first run)

	set_question (a_text: READABLE_STRING_GENERAL)
		require
			not_frozen: not is_frozen
			text_not_empty: not a_text.is_empty
		do
			question := a_text.to_string_32
		ensure
			set: question.same_string_general (a_text)
			criteria_unchanged: criteria = old criteria
			controls_unchanged: controls_model |=| old controls_model
		end

	set_corpus (a_corpus: BIB_SEARCH_SCOPE)
		require
			not_frozen: not is_frozen
		do
			corpus := a_corpus
			corpus_label := a_corpus.label
		ensure
			set: corpus = a_corpus and corpus_label.same_string (a_corpus.label)
			question_unchanged: question.same_string (old question)
			controls_unchanged: controls_model |=| old controls_model
		end

	set_criteria (a_criteria: BIB_QUERY)
		require
			not_frozen: not is_frozen
			criteria_valid: a_criteria.is_valid
			controls_not_targets: not has_control_named_by (a_criteria)
		do
			criteria := a_criteria
		ensure
			set: criteria = a_criteria
			controls_unchanged: controls_model |=| old controls_model
		end

	add_control (a_key: BIB_KEY)
		require
			not_frozen: not is_frozen
			not_target: not criteria.mentions_key (a_key)
			not_present: not controls_model.has (a_key)
		do
			controls.extend (a_key)
		ensure
			appended: controls_model |=| (old controls_model & a_key)
			criteria_unchanged: criteria = old criteria
		end

	remove_control (a_key: BIB_KEY)
		require
			not_frozen: not is_frozen
			present: controls_model.has (a_key)
		do
			-- Phase 4
		ensure
			removed: not controls_model.has (a_key)
			shrunk: controls_count = old controls_count - 1
		end

	set_holds_if (a_text: READABLE_STRING_GENERAL)
		require
			not_frozen: not is_frozen
			text_not_empty: not a_text.is_empty
		do
			holds_if := a_text.to_string_32
		ensure
			set: holds_if.same_string_general (a_text)
			fails_if_unchanged: fails_if.same_string (old fails_if)
		end

	set_fails_if (a_text: READABLE_STRING_GENERAL)
		require
			not_frozen: not is_frozen
			text_not_empty: not a_text.is_empty
		do
			fails_if := a_text.to_string_32
		ensure
			set: fails_if.same_string_general (a_text)
			holds_if_unchanged: holds_if.same_string (old holds_if)
		end

	set_control_seed (a_seed: INTEGER_64)
		require
			not_frozen: not is_frozen
			seed_given: a_seed /= 0
		do
			control_seed := a_seed
		ensure
			set: control_seed = a_seed
		end

	mark_stored (a_id, a_lineage_id: INTEGER_64)
			-- Record the ids the user store assigned (written down before the run).
		require
			not_stored: not is_stored
			id_positive: a_id > 0
			lineage_positive: a_lineage_id > 0
			first_version_starts_lineage: version = 1 implies a_lineage_id = a_id
		do
			id := a_id
			lineage_id := a_lineage_id
		ensure
			stored: is_stored and id = a_id and lineage_id = a_lineage_id
			content_unchanged: question.same_string (old question) and controls_model |=| old controls_model
		end

feature {BIB_CENSUS_ENGINE, BIB_CENSUS_JOB} -- Freezing

	freeze (a_run_id: INTEGER_64)
			-- Freeze at the first run.
		require
			complete: is_complete
			not_frozen: not is_frozen
			run_id_positive: a_run_id > 0
		do
			is_frozen := True
			first_run_id := a_run_id
		ensure
			is_frozen_now: is_frozen
			first_run_recorded: first_run_id = a_run_id
			content_unchanged: question.same_string (old question) and controls_model |=| old controls_model and criteria = old criteria
		end

feature -- Versioning

	new_version: like Current
			-- An editable copy with `version + 1' in the same lineage.
		require
			is_frozen_now: is_frozen
		do
			check implemented_in_phase_4: False then end
		ensure
			next_version: Result.version = version + 1
			same_lineage: Result.lineage_id = lineage_id
			editable: not Result.is_frozen
			not_stored: not Result.is_stored
			content_copied: Result.question.same_string (question) and Result.controls_model |=| controls_model
			current_unchanged: is_frozen and version = old version
		end

feature {NONE} -- Representation

	controls: ARRAYED_LIST [BIB_KEY]

feature -- Constants

	Default_seed: INTEGER_64 = 20261006
			-- Fixed generator seed recorded with every new definition.

invariant
	frozen_has_run: is_frozen implies first_run_id > 0
	frozen_was_stored: is_frozen implies is_stored
	version_positive: version >= 1
	seed_recorded: control_seed /= 0
	corpus_labeled: corpus_label.same_string (corpus.label)

end
