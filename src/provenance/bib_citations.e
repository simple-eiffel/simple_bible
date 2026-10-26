note
	description: "[
		Building an answer's citation list: each provenance once, by reference
		(design scan 29: the same `cite' was written in BIB_CONC_PACK and
		BIB_WORD_LOOKUP). Stateless; inherit it beside the class's real parent.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CITATIONS

feature {NONE} -- Citing

	cite (a_citations: ARRAYED_LIST [BIB_PROVENANCE]; a_provenance: BIB_PROVENANCE)
			-- Add `a_provenance' to `a_citations' unless it is already there.
		do
			if not across a_citations as ic some ic = a_provenance end then
				a_citations.extend (a_provenance)
			end
		ensure
			cited: across a_citations as ic some ic = a_provenance end
			at_most_one_more: a_citations.count <= old a_citations.count + 1
		end

end
