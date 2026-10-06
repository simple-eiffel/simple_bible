note
	description: "A shape finding: a finding with its tier, scale and tag-level evidence. A T3 finding is never evidence."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SHAPE_FINDING

inherit
	BIB_FINDING

create
	make_shape

feature {NONE} -- Initialization

	make_shape (a_reference: BIB_REF; a_hub_id: INTEGER_64; a_verdict: BIB_VERDICT; a_grounds, a_evidence: READABLE_STRING_GENERAL; a_near_miss: BOOLEAN;
			a_provenance: BIB_PROVENANCE; a_tier: BIB_SHAPE_TIER; a_scale, a_tag_evidence: READABLE_STRING_GENERAL)
		require
			hub_positive: a_hub_id > 0
			grounds_given: not a_grounds.is_empty
		do
			make (a_reference, a_hub_id, a_verdict, a_grounds, a_evidence, a_near_miss, a_provenance)
			tier := a_tier
			scale := a_scale.to_string_32
			tag_evidence := a_tag_evidence.to_string_32
			is_evidence := not a_tier.is_judgment
		ensure
			tier_set: tier = a_tier
			t3_not_evidence: a_tier.is_judgment implies not is_evidence
		end

feature -- Access

	tier: BIB_SHAPE_TIER
	scale: STRING_32
	tag_evidence: STRING_32

	is_evidence: BOOLEAN
			-- May this finding score a claim?

invariant
	tier_not_judgment_if_evidence: is_evidence implies not tier.is_judgment

end
