note
	description: "[
		One value the engine asserts, bound to its provenance. A fact cannot
		exist without provenance: the only creation procedure takes one and the
		type is attached (void safety makes `has_provenance' a type guarantee).
		Values are copied, never separate.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FACT [G]

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_value: G; a_provenance: BIB_PROVENANCE)
			-- Bind `a_value' to `a_provenance'.
		do
			value := a_value
			provenance := a_provenance
		ensure
			value_set: value ~ a_value
			provenance_set: provenance = a_provenance
		end

feature -- Access

	value: G
			-- The asserted value.

	provenance: BIB_PROVENANCE
			-- Its source.

end
