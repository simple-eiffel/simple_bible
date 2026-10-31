note
	description: "[
		BIB_TIME_PLACE_SELECTION, the state the Timeline and the Atlas share
		(research/23 phase 1, 2026-10-31): the year is told once per real
		change; an event is told before its year; and a listener that joins
		late learns the present at once (risk 15: the Atlas, filled after an
		event was chosen, was told the year only).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_TIME_PLACE_SELECTION

inherit
	TEST_SET_BASE

feature -- Tests

	test_year_told_once_per_change
		local
			s: BIB_TIME_PLACE_SELECTION
		do
			create s.make
			years.wipe_out
			s.on_year (agent years.extend)
			s.set_year (-700)
			s.set_year (-700)
			s.set_year (-701)
			assert_integers_equal ("told twice: the repeat is not a change", 2, years.count)
			assert_integers_equal ("the last year told", -701, years.last)
		end

	test_event_told_before_its_year
		local
			s: BIB_TIME_PLACE_SELECTION
		do
			create s.make
			told.wipe_out
			s.on_event (agent (a_id: STRING_32) do told.extend ({STRING_32} "event " + a_id) end)
			s.on_year (agent (a_year: INTEGER) do told.extend ({STRING_32} "year " + a_year.out) end)
			s.select_event ("sennacherib", -700)
			assert_integers_equal ("two told", 2, told.count)
			assert_strings_equal ("the event first", "event sennacherib", told.first)
			assert_strings_equal ("then its year", "year -700", told.last)
		end

	test_a_late_listener_learns_the_present
			-- A view that subscribes after a year, an event and a place were chosen is told them at
			-- once, so it never shows a stale state until the next change.
		local
			s: BIB_TIME_PLACE_SELECTION
		do
			create s.make
			s.select_event ("sennacherib", -700)
			s.select_place ("lachish")
			told.wipe_out
			years.wipe_out
			s.on_year (agent years.extend)
			s.on_event (agent (a_id: STRING_32) do told.extend ({STRING_32} "event " + a_id) end)
			s.on_place (agent (a_id: STRING_32) do told.extend ({STRING_32} "place " + a_id) end)
			assert_integers_equal ("the year learned on joining", 1, years.count)
			assert_integers_equal ("which year", -700, years.first)
			assert_true ("the event learned on joining", told.has ({STRING_32} "event sennacherib"))
			assert_true ("the place learned on joining", told.has ({STRING_32} "place lachish"))
		end

feature {NONE} -- Recording

	years: ARRAYED_LIST [INTEGER]
		attribute
			create Result.make (4)
		end

	told: ARRAYED_LIST [STRING_32]
			-- Compared by content: `has' is identity otherwise (oracle gotcha).
		attribute
			create Result.make (4)
			Result.compare_objects
		end

end
