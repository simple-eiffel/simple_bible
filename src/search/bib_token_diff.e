note
	description: "Word diff over normalized token keys (simple_diff's Myers LCS underneath, Phase 4)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TOKEN_DIFF

feature -- Comparison

	diff (a_base, a_other: ARRAYED_LIST [STRING_32]; a_provenance: BIB_PROVENANCE): ARRAYED_LIST [BIB_DIFF_SPAN]
			-- Runs that turn `a_base' into `a_other'.
		do
			check implemented_in_phase_4: False then end
		ensure
			identical_is_same: a_base ~ a_other implies across Result as d all d.kind = {BIB_DIFF_SPAN}.Same end
			sourced: across Result as d all d.provenance = a_provenance end
		end

end
