note
	description: "[
		What a canonical verse is called in another system: every target (one
		to many, many to one) with the rule that produced it, and a note (RQ-12,
		AC-1a-16/17). Target `i' has `rule_for_target (i)' (Void only for an
		identity pairing). Counts are always taken per hub id, never per target.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PAIRING

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_hub_id: INTEGER_64; a_system: BIB_VERSIFICATION_SYSTEM; a_targets: ARRAYED_LIST [BIB_REF]; a_rules: ARRAYED_LIST [detachable BIB_MAPPING_RULE];
			a_note: READABLE_STRING_GENERAL; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
			-- Pairing of `a_hub_id' into `a_system'; target `i' produced by rule `i'.
		require
			hub_positive: a_hub_id > 0
			cited: across a_citations as c some True end
			aligned: a_targets.count = a_rules.count
		do
			hub_id := a_hub_id
			target_system := a_system
			note_text := a_note.to_string_32
			create targets.make (1)
			across a_targets as t loop
				targets.extend (t)
			end
			create target_rules.make (1)
			across a_rules as r loop
				target_rules.extend (r)
			end
			set_success (a_method, a_citations)
		ensure
			success: is_success
			hub_set: hub_id = a_hub_id
		end

	make_failure (a_hub_id: INTEGER_64; a_system: BIB_VERSIFICATION_SYSTEM; a_method: BIB_METHOD; a_error: BIB_ERROR)
			-- No pairing (e.g. the target system lacks the verse).
		require
			hub_positive: a_hub_id > 0
		do
			hub_id := a_hub_id
			target_system := a_system
			create note_text.make_empty
			create targets.make (0)
			create target_rules.make (0)
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
		end

feature -- Access

	hub_id: INTEGER_64
	target_system: BIB_VERSIFICATION_SYSTEM
	note_text: STRING_32

	target_count: INTEGER
		do
			Result := targets.count
		ensure
			model_agrees: Result = targets_model.count
		end

	target (i: INTEGER): BIB_REF
		require
			in_range: i >= 1 and i <= target_count
		do
			Result := targets [i]
		end

	rule_for_target (i: INTEGER): detachable BIB_MAPPING_RULE
			-- Rule that produced target `i' (Void for identity).
		require
			in_range: i >= 1 and i <= target_count
		do
			Result := target_rules [i]
		end

	rules_count: INTEGER
			-- Number of targets reached through a rule.
		do
			across target_rules as r loop
				if r /= Void then
					Result := Result + 1
				end
			end
		ensure
			bounded: Result >= 0 and Result <= target_count
		end

feature -- Model

	targets_model: MML_SEQUENCE [BIB_REF]
		do
			create Result
			across targets as t loop
				Result := Result & t
			end
		end

	target_rules_model: MML_SEQUENCE [detachable BIB_MAPPING_RULE]
		do
			create Result
			across target_rules as r loop
				Result := Result & r
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
			-- The rules used are the facts of a pairing.
		do
			create Result
			across target_rules as r loop
				if attached r as l_rule then
					Result := Result & l_rule
				end
			end
		end

feature {NONE} -- Representation

	targets: ARRAYED_LIST [BIB_REF]
	target_rules: ARRAYED_LIST [detachable BIB_MAPPING_RULE]

invariant
	hub_positive: hub_id > 0
	aligned: target_rules.count = targets.count
	note_when_targets: target_count > 0 implies not note_text.is_empty
	failure_is_empty: not is_success implies target_count = 0

end
