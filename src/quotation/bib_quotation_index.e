note
	description: "Indexed NT quotations by verse (UBS Paratext parallels seed) and their alignments."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUOTATION_INDEX

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
		end

feature -- Status

	has_quotation (a_mapped: BIB_MAPPED_REF): BOOLEAN
			-- Is a quotation indexed at `a_mapped'?
		do
			-- Phase 4
		end

	is_aligned (a_mapped: BIB_MAPPED_REF): BOOLEAN
			-- Does the quotation at `a_mapped' have a hand-verified alignment?
		do
			-- Phase 4
		ensure
			only_indexed: Result implies has_quotation (a_mapped)
		end

feature -- Access

	quotation_at (a_mapped: BIB_MAPPED_REF): BIB_QUOTATION
		require
			indexed: has_quotation (a_mapped)
		do
			check implemented_in_phase_4: False then end
		ensure
			same_verse: Result.nt_hub_id = a_mapped.hub_id
		end

	alignment_for (a_mapped: BIB_MAPPED_REF): BIB_ALIGNMENT
		require
			aligned: is_aligned (a_mapped)
		do
			check implemented_in_phase_4: False then end
		ensure
			verified: Result.is_hand_verified
		end

	quotations_at (a_mapped: BIB_MAPPED_REF): BIB_LIST_RESULT [BIB_QUOTATION]
			-- Is this verse quoted, or quoting? (P01 menu)
		do
			check implemented_in_phase_4: False then end
		ensure
			fact_closure: Result.is_fact_closed
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
