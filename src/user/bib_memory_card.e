note
	description: "[
		One verse the reader is learning by heart (E07): its hub id, when it is
		next due, and the spaced-repetition state BIB_MEMORY_SCHEDULE moves after
		each review (the interval in days, the ease as a percentage, and how many
		reviews in a row went well). Kept in user.db's memory_card table.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MEMORY_CARD

inherit
	BIB_LISTED

create
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_due_on: READABLE_STRING_GENERAL)
			-- A new card for verse `a_hub_id', first due on `a_due_on' (ISO date).
		require
			hub_positive: a_hub_id > 0
			an_iso_date: a_due_on.count = Iso_date_length
		do
			hub_id := a_hub_id
			due_on := a_due_on.to_string_32
			ease_percent := {BIB_MEMORY_SCHEDULE}.First_ease
		ensure
			hub_set: hub_id = a_hub_id
			new: repetitions = 0 and interval_days = 0
		end

feature -- Access

	id: INTEGER_64
			-- 0 until stored.

	hub_id: INTEGER_64
	due_on: STRING_32
			-- The ISO date it is next due.

	interval_days: INTEGER
	ease_percent: INTEGER
	repetitions: INTEGER

	is_due (a_today: READABLE_STRING_GENERAL): BOOLEAN
			-- Is it due on or before `a_today' (ISO date)?
		do
			Result := due_on <= a_today.to_string_32
		end

feature {BIB_USER_STORE} -- Store bookkeeping

	mark_stored (a_id: INTEGER_64)
		require
			id_positive: a_id > 0
		do
			id := a_id
		end

	set_state (a_due_on: READABLE_STRING_GENERAL; a_interval, a_ease, a_repetitions: INTEGER)
		require
			an_iso_date: a_due_on.count = Iso_date_length
			interval_not_negative: a_interval >= 0
			ease_floor: a_ease >= {BIB_MEMORY_SCHEDULE}.Least_ease
			repetitions_not_negative: a_repetitions >= 0
		do
			due_on := a_due_on.to_string_32
			interval_days := a_interval
			ease_percent := a_ease
			repetitions := a_repetitions
		end

feature -- Constants

	Iso_date_length: INTEGER = 10
			-- "2026-10-27": dates compare as text only in this one form (design scan 54).

invariant
	an_iso_date: due_on.count = Iso_date_length
	hub_positive: hub_id > 0
	interval_not_negative: interval_days >= 0
	ease_floor: ease_percent >= {BIB_MEMORY_SCHEDULE}.Least_ease
	repetitions_not_negative: repetitions >= 0

end
