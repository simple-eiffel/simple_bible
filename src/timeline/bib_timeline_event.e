note
	description: "[
		An event on the River of Time (Plan 22): its id, lane, title, kind,
		importance (0 a period shown at every zoom, 1 a major event, 2 a
		detail), summary, and its claims - one when the date is settled, one
		per position when it is disputed.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TIMELINE_EVENT

create
	make

feature {NONE} -- Initialization

	make (a_id, a_lane, a_title, a_kind: READABLE_STRING_GENERAL; a_importance: INTEGER; a_summary: READABLE_STRING_GENERAL)
		require
			importance_known: a_importance >= 0 and a_importance <= 2
		do
			create id.make_from_string_general (a_id)
			create lane.make_from_string_general (a_lane)
			create title.make_from_string_general (a_title)
			create kind.make_from_string_general (a_kind)
			importance := a_importance
			create summary.make_from_string_general (a_summary)
			create claims.make (1)
		end

feature -- Access

	id, lane, title, kind, summary: STRING_32
	importance: INTEGER
	claims: ARRAYED_LIST [BIB_CLAIM]

	is_disputed: BOOLEAN
			-- More than one position?
		do
			Result := claims.count > 1
		end

	earliest: INTEGER
			-- The earliest year any claim allows.
		require
			claimed: not claims.is_empty
		do
			Result := claims.first.earliest
			across claims as c loop
				Result := Result.min (c.earliest)
			end
		end

	latest: INTEGER
		require
			claimed: not claims.is_empty
		do
			Result := claims.first.latest
			across claims as c loop
				Result := Result.max (c.latest)
			end
		end

feature -- Element change

	add_claim (a_claim: BIB_CLAIM)
		do
			claims.extend (a_claim)
		ensure
			added: claims.last = a_claim
		end

invariant
	importance_known: importance >= 0 and importance <= 2

end
