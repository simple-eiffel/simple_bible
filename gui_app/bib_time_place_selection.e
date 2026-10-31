note
	description: "[
		What the River of Time and the Atlas share (Plan 22, spike S9 decision,
		2026-10-31): the year shown (the needle), the event chosen, the place
		chosen. Each view tells it what the reader did and listens for what
		changed; neither view knows the other.

		STATE BY AGENTS (research/23, phase 1): each fact has an SW_EVENT, the
		library's agent collection, fired only when the fact really changes
		(the year), or when the reader chooses (an event, a place). Joining
		(`on_year', `on_event', `on_place') subscribes AND tells the listener
		the present at once, so a view that joins late is never stale (risk
		15: the Atlas, filled after an event was chosen, learned the year
		only). The year told only when it moves also ends the round trip of
		two views that follow each other.
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
			create year_changed.make
			create event_chosen.make
			create place_chosen.make
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

feature -- Events

	year_changed: SW_EVENT [TUPLE [year: INTEGER]]
			-- Fired when the year moves.

	event_chosen: SW_EVENT [TUPLE [event_id: STRING_32]]
			-- Fired when the reader chooses an event.

	place_chosen: SW_EVENT [TUPLE [place_id: STRING_32]]
			-- Fired when the reader chooses a place.

feature -- Joining

	on_year (a_action: PROCEDURE [INTEGER])
			-- `a_action' told every move of the year, and the year now, if there is one.
		do
			year_changed.subscribe (a_action)
			if has_year then
				a_action.call ([year])
			end
		ensure
			joined: year_changed.count = old year_changed.count + 1
		end

	on_event (a_action: PROCEDURE [STRING_32])
			-- `a_action' told every event chosen, and the one chosen now, if any.
		do
			event_chosen.subscribe (a_action)
			if not event_id.is_empty then
				a_action.call ([event_id])
			end
		ensure
			joined: event_chosen.count = old event_chosen.count + 1
		end

	on_place (a_action: PROCEDURE [STRING_32])
			-- `a_action' told every place chosen, and the one chosen now, if any.
		do
			place_chosen.subscribe (a_action)
			if not place_id.is_empty then
				a_action.call ([place_id])
			end
		ensure
			joined: place_chosen.count = old place_chosen.count + 1
		end

feature -- Choosing

	set_year (a_year: INTEGER)
			-- The needle at `a_year'; the year's listeners told when it moved.
		do
			if not has_year or else year /= a_year then
				year := a_year
				has_year := True
				year_changed.call ([a_year])
			end
		ensure
			set: has_year and year = a_year
		end

	select_event (a_id: READABLE_STRING_GENERAL; a_year: INTEGER)
			-- Event `a_id' chosen, at `a_year': the event's listeners told, then the year's.
		do
			create event_id.make_from_string_general (a_id)
			event_chosen.call ([event_id])
			set_year (a_year)
		ensure
			chosen: event_id.same_string_general (a_id) and year = a_year
		end

	select_place (a_id: READABLE_STRING_GENERAL)
			-- Place `a_id' chosen: the place's listeners told.
		do
			create place_id.make_from_string_general (a_id)
			place_chosen.call ([place_id])
		ensure
			chosen: place_id.same_string_general (a_id)
		end

end
