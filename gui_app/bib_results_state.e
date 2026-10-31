note
	description: "[
		The search results' state (research/23 phase 4, 2026-10-31): how many
		dictionary choices and verses the last search listed, and whether the
		reader closed them. One definition of "has results" (there were three:
		the Window menu asked for choices only, so a search that found only
		verses left it greyed, risk 4) and one of "wanted" (results the reader
		has not closed), which the panel, its dot and the menu follow. Every
		change is told to the listeners, and joining tells the present.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RESULTS_STATE

create
	make

feature {NONE} -- Initialization

	make
		do
			create changed.make
		ensure
			none: not has_results and not is_closed
		end

feature -- Access

	choices_count: INTEGER
			-- Dictionary choices listed.

	verse_count: INTEGER
			-- Verses listed.

	is_closed: BOOLEAN
			-- Did the reader close the results?

	has_results: BOOLEAN
			-- Is anything listed?
		do
			Result := choices_count > 0 or verse_count > 0
		end

	is_wanted: BOOLEAN
			-- Results the reader has not closed: the panel shows them and its dot says so.
		do
			Result := has_results and not is_closed
		end

feature -- Events

	changed: SW_EVENT [TUPLE]
			-- Told after every change; listeners read the queries.

	on_change (a_action: PROCEDURE)
			-- `a_action' told every change, and now.
		do
			changed.subscribe (a_action)
			a_action.call (Void)
		end

feature -- Doors

	set_found (a_choices, a_verses: INTEGER)
			-- A search listed `a_choices' choices and `a_verses' verses: new results, not closed.
		require
			non_negative: a_choices >= 0 and a_verses >= 0
		do
			choices_count := a_choices
			verse_count := a_verses
			is_closed := False
			changed.call (Void)
		ensure
			set: choices_count = a_choices and verse_count = a_verses and not is_closed
		end

	close
			-- The reader closed the results (they stay listed, to open again from the Window menu).
		do
			if not is_closed then
				is_closed := True
				changed.call (Void)
			end
		ensure
			closed: is_closed
		end

	reopen
			-- The results shown again.
		do
			if is_closed then
				is_closed := False
				changed.call (Void)
			end
		ensure
			open: not is_closed
		end

	clear
			-- Nothing listed.
		do
			if has_results or is_closed then
				choices_count := 0
				verse_count := 0
				is_closed := False
				changed.call (Void)
			end
		ensure
			none: not has_results and not is_closed
		end

invariant
	non_negative: choices_count >= 0 and verse_count >= 0

end
