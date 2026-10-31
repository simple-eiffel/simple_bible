note
	description: "[
		A place on the Atlas (Plan 22 phase 3, 2026-10-31): its id, name, kind,
		the zoom its label shows from, and its location as claims in order;
		several claims make it disputed (Sinai, Bethsaida, Golgotha).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PLACE

create
	make

feature {NONE} -- Initialization

	make (a_id, a_name, a_kind: READABLE_STRING_GENERAL; a_min_zoom: REAL_64)
		require
			id_given: not a_id.is_empty
			name_given: not a_name.is_empty
			zoom_sane: a_min_zoom >= 1.0
		do
			create id.make_from_string_general (a_id)
			create name.make_from_string_general (a_name)
			create kind.make_from_string_general (a_kind)
			min_zoom := a_min_zoom
			create claims.make (1)
		ensure
			no_claim_yet: claims.is_empty
		end

feature -- Access

	id, name, kind: STRING_32

	min_zoom: REAL_64
			-- The Atlas zoom its label shows from.

	claims: ARRAYED_LIST [BIB_PLACE_CLAIM]
			-- Where it was, in order.

	is_disputed: BOOLEAN
			-- Is its location claimed in more than one place?
		do
			Result := claims.count > 1
		end

feature -- Element change

	add_claim (a_claim: BIB_PLACE_CLAIM)
		do
			claims.extend (a_claim)
		ensure
			added: claims.count = old claims.count + 1 and claims.last = a_claim
		end

invariant
	zoom_sane: min_zoom >= 1.0

end
