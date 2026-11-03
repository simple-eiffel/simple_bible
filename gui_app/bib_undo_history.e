note
	description: "[
		The reader's Undo and Redo for Favorites (Larry, 2026-11-03: an Undo in
		the notice; Ctrl+Z and Ctrl+Y). Each step is a name and two actions:
		one puts the change back, one does it again. Steps 1 to `position'
		are done; the ones after it were undone and can be redone, until a
		new step is recorded. At most `limit' steps are kept (the oldest go
		first).

		Replaying a step must not record new steps: `is_replaying' is True
		while one runs, and `record' does nothing then.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_UNDO_HISTORY

create
	make

feature {NONE} -- Initialization

	make (a_limit: INTEGER)
			-- At most `a_limit' steps kept.
		require
			positive: a_limit > 0
		do
			limit := a_limit
			create steps.make (a_limit)
		ensure
			kept: limit = a_limit
			empty: steps.is_empty and position = 0
		end

feature -- Access

	limit: INTEGER
			-- Steps kept at most.

	steps: ARRAYED_LIST [TUPLE [name: STRING_32; undo, redo: PROCEDURE]]
			-- Every step, oldest first.

	position: INTEGER
			-- Steps 1 to `position' are done.

	changes: INTEGER
			-- Counts every record, join, undo and redo: a notice's Undo acts
			-- only if nothing changed since it was shown.

	is_replaying: BOOLEAN
			-- Is a step's undo or redo running now?

	can_undo: BOOLEAN
		do
			Result := position > 0
		end

	can_redo: BOOLEAN
		do
			Result := position < steps.count
		end

	undo_name: STRING_32
			-- What Undo would put back.
		require
			can_undo: can_undo
		do
			Result := steps.i_th (position).name
		end

	redo_name: STRING_32
			-- What Redo would do again.
		require
			can_redo: can_redo
		do
			Result := steps.i_th (position + 1).name
		end

feature -- Element change

	record (a_name: READABLE_STRING_GENERAL; a_undo, a_redo: PROCEDURE)
			-- A change just made: `a_undo' puts it back, `a_redo' does it again. The steps undone
			-- before it can no longer be redone. Nothing while a step replays.
		do
			if not is_replaying then
				from
				until
					steps.count = position
				loop
					steps.finish
					steps.remove
				end
				steps.extend ([a_name.to_string_32, a_undo, a_redo])
				if steps.count > limit then
					steps.start
					steps.remove
				end
				position := steps.count
				changes := changes + 1
			end
		ensure
			recorded: not old is_replaying implies (position = steps.count and then steps.last.name.same_string_general (a_name))
			nothing_to_redo: not old is_replaying implies not can_redo
			within_limit: steps.count <= limit
		end

	join_last (a_count: INTEGER; a_name: READABLE_STRING_GENERAL)
			-- The last `a_count' steps become one named `a_name' (a drop that made a folder and kept
			-- a quotation in it is one change): its undo runs theirs newest first, its redo oldest
			-- first.
		require
			enough: a_count >= 2 and a_count <= position
			at_the_end: position = steps.count
		local
			l_undos, l_redos: ARRAYED_LIST [PROCEDURE]
			i: INTEGER
		do
			create l_undos.make (a_count)
			create l_redos.make (a_count)
			from
				i := position - a_count + 1
			until
				i > position
			loop
				l_redos.extend (steps.i_th (i).redo)
				l_undos.put_front (steps.i_th (i).undo)
				i := i + 1
			end
			from
				i := 1
			until
				i > a_count
			loop
				steps.finish
				steps.remove
				i := i + 1
			end
			steps.extend ([a_name.to_string_32, agent run_all (l_undos), agent run_all (l_redos)])
			position := steps.count
			changes := changes + 1
		ensure
			one_step: steps.count = old steps.count - a_count + 1
			at_the_end: position = steps.count
		end

feature -- Undo and redo

	undo
			-- Put the last step done back.
		require
			can_undo: can_undo
		local
			l_step: TUPLE [name: STRING_32; undo, redo: PROCEDURE]
		do
			l_step := steps.i_th (position)
			position := position - 1
			changes := changes + 1
			is_replaying := True
			l_step.undo.call
			is_replaying := False
		ensure
			one_back: position = old position - 1
			redo_ready: can_redo
		end

	redo
			-- Do the last step undone again.
		require
			can_redo: can_redo
		local
			l_step: TUPLE [name: STRING_32; undo, redo: PROCEDURE]
		do
			l_step := steps.i_th (position + 1)
			position := position + 1
			changes := changes + 1
			is_replaying := True
			l_step.redo.call
			is_replaying := False
		ensure
			one_on: position = old position + 1
			undo_ready: can_undo
		end

feature {NONE} -- Implementation

	run_all (a_actions: ARRAYED_LIST [PROCEDURE])
			-- Each action in order.
		do
			across a_actions as ic loop
				ic.call
			end
		end

invariant
	position_in_range: position >= 0 and position <= steps.count
	within_limit: steps.count <= limit

end
