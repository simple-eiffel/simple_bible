note
	description: "[
		One prayer on the reader's list (E06): a title, the request, a verse it
		rests on (hub id, 0 for none), the day it was written, and once answered,
		the day and the answer. Kept in user.db's prayer table (schema 2); removed
		prayers stay, soft-deleted and restorable.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PRAYER

inherit
	BIB_LISTED

create
	make

feature {NONE} -- Initialization

	make (a_title, a_body: READABLE_STRING_GENERAL; a_hub_id: INTEGER_64)
			-- A prayer titled `a_title' asking `a_body', resting on verse `a_hub_id' (0: none).
		require
			title_not_empty: not a_title.is_empty
			hub_not_negative: a_hub_id >= 0
		do
			title := a_title.to_string_32
			body := a_body.to_string_32
			hub_id := a_hub_id
			create created_on.make_empty
			create answered_on.make_empty
			create answer.make_empty
		ensure
			title_set: title.same_string_general (a_title)
			open: not is_answered
		end

feature -- Access

	id: INTEGER_64
			-- 0 until stored.

	title: STRING_32
	body: STRING_32

	hub_id: INTEGER_64
			-- The verse it rests on; 0 for none.

	created_on: STRING_32
			-- When it was written (ISO date and time); empty until stored.

	answered_on: STRING_32
			-- When it was answered; empty while it is open.

	answer: STRING_32
			-- How it was answered, in the reader's words.

	is_answered: BOOLEAN
			-- Has it been answered?
		do
			Result := not answered_on.is_empty
		end

feature {BIB_USER_STORE} -- Store bookkeeping

	mark_stored (a_id: INTEGER_64; a_created_on: READABLE_STRING_GENERAL)
		require
			id_positive: a_id > 0
		do
			id := a_id
			created_on := a_created_on.to_string_32
		ensure
			stored: id = a_id
		end

	mark_answered (a_on, a_answer: READABLE_STRING_GENERAL)
		require
			on_given: not a_on.is_empty
		do
			answered_on := a_on.to_string_32
			answer := a_answer.to_string_32
		ensure
			answered: is_answered
		end

invariant
	title_not_empty: not title.is_empty
	hub_not_negative: hub_id >= 0

end
