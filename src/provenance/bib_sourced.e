note
	description: "[
		Anything the engine hands out that carries its own provenance (RQ-02).
		Every value an engine result exposes is a BIB_SOURCED, so the result's
		`facts_model' can be checked against its citations (fact closure,
		AC-1a-32). Effective descendants define `provenance' as an attribute.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_SOURCED

feature -- Access

	provenance: BIB_PROVENANCE
			-- Where this value came from.
		deferred
		end

end
