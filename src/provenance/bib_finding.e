note
	description: "[
		One census or shape finding: the reference, its canonical hub id (counts
		are per hub id, RQ-12), the verdict, the grounds, a near-miss flag and the
		evidence text, with provenance.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FINDING

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_reference: BIB_REF; a_hub_id: INTEGER_64; a_verdict: BIB_VERDICT; a_grounds, a_evidence: READABLE_STRING_GENERAL; a_near_miss: BOOLEAN; a_provenance: BIB_PROVENANCE)
			-- Create a finding.
		require
			hub_positive: a_hub_id > 0
			grounds_given: not a_grounds.is_empty
		do
			ref := a_reference
			hub_id := a_hub_id
			verdict := a_verdict
			grounds := a_grounds.to_string_32
			evidence := a_evidence.to_string_32
			is_near_miss := a_near_miss
			provenance := a_provenance
		ensure
			reference_set: ref = a_reference
			hub_set: hub_id = a_hub_id
			verdict_set: verdict = a_verdict
			grounds_set: grounds.same_string_general (a_grounds)
			near_miss_set: is_near_miss = a_near_miss
			provenance_set: provenance = a_provenance
		end

feature -- Access

	ref: BIB_REF
	hub_id: INTEGER_64
	verdict: BIB_VERDICT
	grounds: STRING_32
	evidence: STRING_32
	is_near_miss: BOOLEAN
	provenance: BIB_PROVENANCE

invariant
	hub_positive: hub_id > 0
	grounds_given: not grounds.is_empty

end
