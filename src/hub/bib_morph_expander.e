note
	description: "Morphology code to English from the TEHMC/TEGMC tables in core.db."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MORPH_EXPANDER

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
		end

feature -- Conversion

	has_expansion (a_code: BIB_MORPH_CODE): BOOLEAN
			-- Does core.db expand `a_code'?
		do
			-- Phase 4
		end

	english (a_code: BIB_MORPH_CODE): STRING_32
			-- English reading of `a_code', e.g. "noun, common, masculine, singular, absolute".
		require
			known: has_expansion (a_code)
		do
			check implemented_in_phase_4: False then end
		ensure
			not_empty: not Result.is_empty
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
