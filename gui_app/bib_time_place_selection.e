note
	description: "[
		What the River of Time and the Atlas share (Plan 22, spike S9 decision,
		2026-10-31): the year shown (the needle), the event chosen, the place
		chosen. Each view tells it what the reader did and listens for what
		changed; neither view knows the other. The year is told only when it
		moves, which ends the round trip of two views that follow each other
		(the Atlas picks a place, the timeline's cursor moves there and tells
		the year back, the Atlas follows; the timeline hears its own year and
		stops).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TIME_PLACE_SELECTION

create
	make

feature {NONE} -- Initialization

	make
		do
			create event_id.make_empty
			create place_id.make_empty
			create year_listeners.make (2)
			create event_listeners.make (2)
			create place_listeners.make (2)
		ensure
			nothing_chosen: not has_year and event_id.is_empty and place_id.is_empty
		end

feature -- Access

	year: INTEGER
			-- The year shown, when `has_year'.

	has_year: BOOLEAN

	event_id: STRING_32
			-- The event chosen; empty for none.

	place_id: STRING_32
			-- The place chosen; empty for none.

feature -- Listening

	year_listeners: ARRAYED_LIST [PROCEDURE [INTEGER]]
	event_listeners: ARRAYED_LIST [PROCEDURE [STRING_32]]
	place_listeners: ARRAYED_LIST [PROCEDURE [STRING_32]]

	on_year (a_action: PROCEDURE [INTEGER])
		do
			year_listeners.extend (a_action)
		end

	on_event (a_action: PROCEDURE [STRING_32])
		do
			event_listeners.extend (a_action)
		end

	on_place (a_action: PROCEDURE [STRING_32])
		do
			place_listeners.extend (a_action)
		end

feature -- Choosing

	set_year (a_year: INTEGER)
			-- The needle at `a_year'; the year listeners told when it moved.
		do
			if not has_year or else year /= a_year then
				year := a_year
				has_year := True
				across year_listeners as ic loop
					ic.call (a_year)
				end
			end
		ensure
			set: has_year and year = a_year
		end

	select_event (a_id: READABLE_STRING_GENERAL; a_year: INTEGER)
			-- Event `a_id' chosen, at `a_year': the event listeners told, then the year's.
		do
			create event_id.make_from_string_general (a_id)
			across event_listeners as ic loop
				ic.call (event_id)
			end
			set_year (a_year)
		ensure
			chosen: event_id.same_string_general (a_id) and year = a_year
		end

	select_place (a_id: READABLE_STRING_GENERAL)
			-- Place `a_id' chosen: the place listeners told.
		do
			create place_id.make_from_string_general (a_id)
			across place_listeners as ic loop
				ic.call (place_id)
			end
		ensure
			chosen: place_id.same_string_general (a_id)
		end

end
