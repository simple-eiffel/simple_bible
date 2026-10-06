note
	description: "[
		License of a source: identifier, clauses (non-commercial, share-alike,
		restricted) and credit line. Unknown and restricted licenses never ship
		(D-002); non-commercial texts may ship because the tool is free.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LICENSE

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_identifier: READABLE_STRING_GENERAL; a_non_commercial, a_share_alike, a_restricted: BOOLEAN; a_credit: READABLE_STRING_GENERAL)
			-- Create license `a_identifier' with its clauses and credit line.
		require
			identifier_not_empty: not a_identifier.is_empty
		do
			identifier := a_identifier.to_string_32
			is_non_commercial := a_non_commercial
			is_share_alike := a_share_alike
			is_restricted := a_restricted
			credit_line := a_credit.to_string_32
		ensure
			identifier_set: identifier.same_string_general (a_identifier)
			non_commercial_set: is_non_commercial = a_non_commercial
			share_alike_set: is_share_alike = a_share_alike
			restricted_set: is_restricted = a_restricted
			credit_set: credit_line.same_string_general (a_credit)
		end

feature -- Access

	identifier: STRING_32
			-- License identifier, e.g. "CC-BY-SA-4.0", "PD", "UNKNOWN".

	credit_line: STRING_32
			-- Attribution line required by the license (may be empty for PD).

feature -- Status

	is_unknown: BOOLEAN
			-- Is the license not yet identified? (D-002: unknown is restricted.)
		do
			Result := identifier.same_string_general (Unknown_identifier)
		end

	is_non_commercial: BOOLEAN
			-- Does the license carry an NC clause?

	is_share_alike: BOOLEAN
			-- Does the license carry an SA clause (derived tables under the same license)?

	is_restricted: BOOLEAN
			-- Copyrighted without a license to share, or held under terms the tool cannot meet.

	may_ship_in_free_tool: BOOLEAN
			-- D-002: attribution always; NC allowed (free tool); unknown and restricted never.
		do
			Result := not is_unknown and not is_restricted
		ensure
			unknown_never_ships: is_unknown implies not Result
			restricted_never_ships: is_restricted implies not Result
			nc_allowed_free: (is_non_commercial and not is_unknown and not is_restricted) implies Result
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same identifier and clauses?
		do
			Result := identifier.same_string (other.identifier)
				and is_non_commercial = other.is_non_commercial
				and is_share_alike = other.is_share_alike
				and is_restricted = other.is_restricted
		end

feature -- Constants

	Unknown_identifier: STRING_8 = "UNKNOWN"
			-- Identifier of a license that has not been identified.

invariant
	id_not_empty: not identifier.is_empty

end
