note
	description: "Reciprocal rank fusion of several rankings (harvest S-06, X-04)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RANK_FUSION

feature -- Fusion

	fused (a_rankings: ARRAYED_LIST [ARRAYED_LIST [INTEGER_64]]; a_k: INTEGER): ARRAYED_LIST [INTEGER_64]
			-- Ids ordered by summed 1 / (a_k + rank); ties broken by id.
		require
			k_positive: a_k > 0
		do
			check implemented_in_phase_4: False then end
		ensure
			no_duplicates: Result.count = distinct_count (Result)
			all_ranked: across a_rankings as r all across r as id all Result.has (id) end end
		end

	distinct_count (a_ids: ARRAYED_LIST [INTEGER_64]): INTEGER
		local
			l_set: MML_SET [INTEGER_64]
		do
			create l_set
			across a_ids as i loop
				l_set := l_set & i
			end
			Result := l_set.count
		end

feature -- Constants

	Default_k: INTEGER = 60

end
