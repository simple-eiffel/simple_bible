note
	description: "A cross-reference from a verse to a target, with its source and vote count (OpenBible votes may be negative)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CROSS_REFERENCE

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_source_hub_id: INTEGER_64; a_target: BIB_REF; a_target_hub_id: INTEGER_64; a_votes: INTEGER; a_provenance: BIB_PROVENANCE)
		require
			source_positive: a_source_hub_id > 0
			target_positive: a_target_hub_id > 0
		do
			source_hub_id := a_source_hub_id
			target := a_target
			target_hub_id := a_target_hub_id
			votes := a_votes
			provenance := a_provenance
		ensure
			votes_set: votes = a_votes
		end

feature -- Access

	source_hub_id: INTEGER_64
	target: BIB_REF
	target_hub_id: INTEGER_64
	votes: INTEGER
	provenance: BIB_PROVENANCE

invariant
	source_positive: source_hub_id > 0
	target_positive: target_hub_id > 0

end
