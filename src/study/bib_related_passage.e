note
	description: "[
		A related passage with the reasons it is listed (at least one); AI-made
		neighbors are always labeled, with method and model id in their
		provenance (D-016, AC-1a-33).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RELATED_PASSAGE

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_target: BIB_REF; a_target_hub_id: INTEGER_64; a_reasons: ITERABLE [READABLE_STRING_GENERAL]; a_provenance: BIB_PROVENANCE)
		require
			hub_positive: a_target_hub_id > 0
			has_reason: across a_reasons as r some not r.is_empty end
		do
			target := a_target
			target_hub_id := a_target_hub_id
			provenance := a_provenance
			is_ai_made := a_provenance.is_ai_made
			if is_ai_made then
				ai_label := {BIB_TRUST_LABELS}.Ai_made_label
			else
				create ai_label.make_empty
			end
			create reasons.make (2)
			across a_reasons as r loop
				if not r.is_empty then
					reasons.extend (r.to_string_32)
				end
			end
		ensure
			ai_flag_from_provenance: is_ai_made = a_provenance.is_ai_made
		end

feature -- Access

	target: BIB_REF
	target_hub_id: INTEGER_64
	ai_label: STRING_32
	provenance: BIB_PROVENANCE

	reason_count: INTEGER
		do
			Result := reasons.count
		end

	reason (i: INTEGER): STRING_32
			-- "cross-reference (OpenBible, 57 votes)", "shares a rare word", "AI-made: meaning neighbor".
		require
			in_range: i >= 1 and i <= reason_count
		do
			Result := reasons [i]
		end

feature -- Status

	is_ai_made: BOOLEAN

feature -- Model

	reasons_model: MML_SEQUENCE [STRING_32]
		do
			create Result
			across reasons as r loop
				Result := Result & r
			end
		end

feature {NONE} -- Representation

	reasons: ARRAYED_LIST [STRING_32]

invariant
	has_reason: reason_count >= 1
	ai_made_has_label: is_ai_made implies (ai_label.same_string ({BIB_TRUST_LABELS}.Ai_made_label) and provenance.is_ai_made)
	ai_flag_matches_provenance: is_ai_made = provenance.is_ai_made

end
