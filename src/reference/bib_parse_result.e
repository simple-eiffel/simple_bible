note
	description: "[
		Outcome of parsing reference text: exactly one of valid, ambiguous (with
		at least two candidates) or invalid (with a position). Never a guess
		(FR-020, AC-1a-15).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PARSE_RESULT

create
	make_valid, make_ambiguous, make_invalid

feature {NONE} -- Initialization

	make_valid (a_reference: BIB_REF; a_range_end: detachable BIB_REF)
			-- A valid reference (and optional range end) in the system the parser named.
		do
			is_valid := True
			ref := a_reference
			range_end := a_range_end
			system := a_reference.system
			create candidates.make (0)
			create error_message.make_empty
		ensure
			valid: is_valid
			reference_set: ref = a_reference
			range_end_set: range_end = a_range_end
		end

	make_ambiguous (a_candidates: ARRAYED_LIST [BIB_REF])
			-- Ambiguous text with every candidate (two or more).
		require
			two_or_more: a_candidates.count >= 2
		do
			is_ambiguous := True
			create candidates.make (2)
			across a_candidates as c loop
				candidates.extend (c)
			end
			create error_message.make_empty
		ensure
			ambiguous: is_ambiguous
			choices: candidate_count >= 2
		end

	make_invalid (a_position: INTEGER; a_message: READABLE_STRING_GENERAL)
			-- Invalid text, failing at `a_position'.
		require
			position_positive: a_position >= 1
			message_not_empty: not a_message.is_empty
		do
			is_invalid := True
			error_position := a_position
			error_message := a_message.to_string_32
			create candidates.make (0)
		ensure
			invalid: is_invalid
			position_set: error_position = a_position
		end

feature -- Status

	is_valid: BOOLEAN
	is_ambiguous: BOOLEAN
	is_invalid: BOOLEAN

feature -- Access

	ref: detachable BIB_REF
	range_end: detachable BIB_REF
	system: detachable BIB_VERSIFICATION_SYSTEM
			-- The system the parser assumed, named (FR-020).
	error_position: INTEGER
	error_message: STRING_32

	candidate_count: INTEGER
		do
			Result := candidates.count
		ensure
			model_agrees: Result = candidates_model.count
		end

	candidate (i: INTEGER): BIB_REF
		require
			in_range: i >= 1 and i <= candidate_count
		do
			Result := candidates [i]
		ensure
			model_agrees: Result = candidates_model [i]
		end

feature -- Model

	candidates_model: MML_SEQUENCE [BIB_REF]
			-- Every reading of ambiguous text.
		do
			create Result
			across candidates as c loop
				Result := Result & c
			end
		end

feature {NONE} -- Representation

	candidates: ARRAYED_LIST [BIB_REF]

invariant
	exactly_one_state: (is_valid.to_integer + is_ambiguous.to_integer + is_invalid.to_integer) = 1
	valid_has_reference: is_valid implies (ref /= Void and system /= Void)
	ambiguous_has_choices: is_ambiguous implies candidate_count >= 2
	invalid_located: is_invalid implies error_position >= 1
	only_ambiguous_has_candidates: not is_ambiguous implies candidate_count = 0

end
