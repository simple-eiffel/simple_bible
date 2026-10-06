note
	description: "Attribution lines and share-alike notices for a set of provenances (FR-119, AC-1a-51)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ATTRIBUTION

feature -- Text

	lines_for (a_result: BIB_ENGINE_RESULT): STRING_32
			-- One credit line per distinct cited source, in citation order.
		require
			cited: a_result.citation_count > 0
		do
			check implemented_in_phase_4: False then end
		ensure
			every_source_credited: across 1 |..| a_result.citation_count as i all Result.has_substring (a_result.citation (i).source_key) end
		end

	share_alike_notice: STRING_32
			-- Notice required by CC BY-SA sources (Swete/First1KGreek, MorphGNT, UBS, Wycliffe).
		do
			Result := {STRING_32} "Portions licensed CC BY-SA 4.0; derived text is offered under the same license."
		ensure
			not_empty: not Result.is_empty
		end

end
