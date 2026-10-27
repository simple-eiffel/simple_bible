note
	description: "[
		What BIB_CONC_PACK.key_places finds for one key: the verse places of its
		Hebrew side (in Hebrew verse numbers) and of its Greek side, each packed,
		ascending, once each; their union; and whether a query failed. A value,
		so finding the places changes nothing (design scan 48). The Hebrew side
		stays apart so a search can move it to English verse numbers
		(BIB_VERSIFICATION_MAP) before the union.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ROOT_PLACES

inherit
	BIB_PLACE_SETS

create
	make, make_failed

feature {NONE} -- Initialization

	make (a_hebrew, a_greek: ARRAYED_LIST [INTEGER_64])
			-- Places in the Hebrew Bible `a_hebrew' and in the Greek New Testament `a_greek'.
		do
			hebrew_places := a_hebrew
			greek_places := a_greek
			places := union (a_hebrew, a_greek)
		ensure
			hebrew_set: hebrew_places = a_hebrew
			greek_set: greek_places = a_greek
			not_failed: not has_failed
		end

	make_failed
			-- A concordance query failed.
		do
			create hebrew_places.make (0)
			create greek_places.make (0)
			create places.make (0)
			has_failed := True
		ensure
			failed: has_failed
			empty: places.is_empty
		end

feature -- Access

	hebrew_places: ARRAYED_LIST [INTEGER_64]
			-- The places in the Hebrew Bible, in Hebrew verse numbers.

	greek_places: ARRAYED_LIST [INTEGER_64]
			-- The places in the Greek New Testament.

	places: ARRAYED_LIST [INTEGER_64]
			-- Both sides, ascending, once each (merged once, when made).

	has_hebrew: BOOLEAN
			-- Did Hebrew places come?
		do
			Result := not hebrew_places.is_empty
		end

	has_greek: BOOLEAN
			-- Did Greek places come (in the concordance's critical Greek text)?
		do
			Result := not greek_places.is_empty
		end

	has_failed: BOOLEAN
			-- Did a concordance query fail?

invariant
	failed_is_empty: has_failed implies (hebrew_places.is_empty and greek_places.is_empty)

end
