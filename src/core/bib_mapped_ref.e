note
	description: "[
		A reference that has passed the versification map: the canonical hub id,
		the origin reference and the rules applied. ONLY BIB_VERSIFICATION_MAP
		can create one (selective creation, I-003, AC-1a-18), and every pairing,
		hub, quotation and census feature accepts only this type, so an unmapped
		cross-version pairing cannot be written.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MAPPED_REF

inherit
	ANY
		redefine
			is_equal
		end

create {BIB_VERSIFICATION_MAP}
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_origin: BIB_REF; a_rules: ITERABLE [BIB_MAPPING_RULE])
			-- Create the canonical identity `a_hub_id' of `a_origin'.
		require
			hub_positive: a_hub_id > 0
		do
			hub_id := a_hub_id
			origin := a_origin
			create rules.make (2)
			across a_rules as r loop
				rules.extend (r)
			end
		ensure
			hub_set: hub_id = a_hub_id
			origin_set: origin = a_origin
		end

feature -- Access

	hub_id: INTEGER_64
			-- Canonical verse identity: the key for counts, notes and pairings.

	origin: BIB_REF
			-- The reference as entered, in its own system.

	rules_applied_count: INTEGER
			-- Versification rules applied to reach `hub_id'.
		do
			Result := rules.count
		ensure
			model_agrees: Result = rules_model.count
		end

feature -- Model

	rules_model: MML_SEQUENCE [BIB_MAPPING_RULE]
			-- Rules applied, in order.
		do
			create Result
			across rules as r loop
				Result := Result & r
			end
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same canonical verse?
		do
			Result := hub_id = other.hub_id
		end

feature {NONE} -- Representation

	rules: ARRAYED_LIST [BIB_MAPPING_RULE]

invariant
	hub_id_positive: hub_id > 0

end
