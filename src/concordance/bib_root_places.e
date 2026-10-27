note
	description: "[
		What BIB_CONC_PACK.key_places finds for one root: its verse places
		(packed, ascending, once each), whether Hebrew or Greek places came, and
		whether a query failed. A value, so finding the places changes nothing
		(design scan 48: two flags were set as a side effect of the query).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ROOT_PLACES

create
	make, make_failed

feature {NONE} -- Initialization

	make (a_places: ARRAYED_LIST [INTEGER_64]; a_hebrew, a_greek: BOOLEAN)
			-- Places `a_places', Hebrew among them when `a_hebrew', Greek when `a_greek'.
		do
			places := a_places
			has_hebrew := a_hebrew
			has_greek := a_greek
		ensure
			places_set: places = a_places
			hebrew_set: has_hebrew = a_hebrew
			greek_set: has_greek = a_greek
			not_failed: not has_failed
		end

	make_failed
			-- A concordance query failed.
		do
			create places.make (0)
			has_failed := True
		ensure
			failed: has_failed
			empty: places.is_empty
		end

feature -- Access

	places: ARRAYED_LIST [INTEGER_64]
			-- The verses the root stands in.

	has_hebrew: BOOLEAN
			-- Did Hebrew places come (in Hebrew verse numbers)?

	has_greek: BOOLEAN
			-- Did Greek places come (in the concordance's critical Greek text)?

	has_failed: BOOLEAN
			-- Did a concordance query fail?

invariant
	failed_is_empty: has_failed implies places.is_empty

end
