note
	description: "[
		A list of the reader's own items of one kind (highlights in T2, bookmarks
		in T1) with its Remove and Restore buttons: a click opens the item's
		verse; Remove takes the chosen item away softly and Restore brings back
		the last one removed; a failure is said, and the remembered item changes
		only on success. Scan 43 (2026-10-27): the same logic had been written
		for each list, and every copy kept a row number selected after Remove -
		pointing at the next item, its click doing nothing. The choice follows
		the item now, not its row.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ITEM_LIST_PANEL [G -> BIB_USER_ITEM]

create
	make

feature {NONE} -- Initialization

	make (a_store: BIB_USER_STORE; a_kind: INTEGER; a_grid: SW_DATA_GRID [G]; a_noun: READABLE_STRING_GENERAL)
			-- A panel over `a_grid' for items of `a_kind' in `a_store', called `a_noun' in what it says;
			-- `set_actions' gives it how to speak, redraw and read a verse.
		require
			kind_valid: a_store.is_valid_kind (a_kind) and a_kind /= {BIB_USER_STORE}.Kind_note
			named: not a_noun.is_empty
		do
			store := a_store
			kind := a_kind
			grid := a_grid
			noun := a_noun.to_string_32
			create rows.make (0)
			create remove_button.make ("Remove", Void)
			create restore_button.make ("Restore", Void)
				-- Agents on Current only once every attribute is set (VEVI).
			remove_button.set_on_click (agent remove)
			restore_button.set_on_click (agent restore)
			grid.set_on_select (agent on_row)
		ensure
			kind_set: kind = a_kind
			nothing_chosen: chosen_id = 0
		end

feature -- Access

	store: BIB_USER_STORE
	kind: INTEGER
	grid: SW_DATA_GRID [G]
	noun: STRING_32
	remove_button, restore_button: SW_BUTTON

	rows: ARRAYED_LIST [G]
			-- The items listed, in the grid's model order.

	chosen_id: INTEGER_64
			-- The item last clicked (0: none); Remove acts on it. An id, not the object: a generic
			-- `detachable G' cannot be set to Void (VJAR), and the id is what Remove needs.

	last_removed: INTEGER_64
			-- The item Remove took away last; Restore brings it back (0: none).

feature -- Element change

	set_actions (a_say: PROCEDURE [READABLE_STRING_GENERAL]; a_refresh: PROCEDURE; a_open: PROCEDURE [INTEGER_64])
			-- Speak through `a_say'; `a_refresh' redraws what an item change touches; `a_open' reads a
			-- verse (set after creation: the host's agents need the host whole).
		do
			say := a_say
			refresh := a_refresh
			open := a_open
		ensure
			set: say = a_say and refresh = a_refresh and open = a_open
		end

	set_rows (a_rows: ARRAYED_LIST [G])
			-- List `a_rows', the chosen item kept selected when it is still among them.
		local
			l_index, i: INTEGER
		do
			rows := a_rows
			grid.set_rows (rows)
			if chosen_id > 0 then
				from i := 1 until i > rows.count or l_index > 0 loop
					if rows.i_th (i).id = chosen_id then
						l_index := i
					end
					i := i + 1
				end
				if l_index = 0 then
					chosen_id := 0
				end
			end
			is_refilling := True
			grid.select_model_row (l_index)
			is_refilling := False
			remove_button.set_enabled (chosen_id > 0)
			restore_button.set_enabled (last_removed > 0)
		ensure
			listed: rows = a_rows
			chosen_listed: chosen_id > 0 implies across rows as ic some ic.id = chosen_id end
		end

feature {NONE} -- Commands

	on_row (a_row: INTEGER)
			-- An item clicked: chosen, and its verse read.
		do
			if not is_refilling and then a_row >= 1 and then a_row <= rows.count then
				chosen_id := rows.i_th (a_row).id
				remove_button.set_enabled (True)
				if attached open as al_open then
					al_open.call ([rows.i_th (a_row).hub_id])
				end
			end
		end

	remove
			-- Take the chosen item away (Restore brings it back).
		do
			if chosen_id > 0 and then store.is_open then
				store.remove_item (kind, chosen_id)
				if attached store.write_error as al_error then
					tell (al_error.message)
				else
					last_removed := chosen_id
					chosen_id := 0
					redraw
					tell (noun + {STRING_32} " removed. Restore brings it back.")
				end
			end
		end

	restore
			-- Bring back the item Remove took last.
		do
			if last_removed > 0 and then store.is_open and then store.is_deleted (last_removed) then
				store.restore_item (kind, last_removed)
				if attached store.write_error as al_error then
					tell (al_error.message)
				else
					last_removed := 0
					redraw
				end
			end
		end

feature {NONE} -- Implementation

	is_refilling: BOOLEAN
			-- Is `set_rows' selecting a row (no click to answer)?

	say: detachable PROCEDURE [READABLE_STRING_GENERAL]
	refresh: detachable PROCEDURE
	open: detachable PROCEDURE [INTEGER_64]
			-- The host's actions (`set_actions').

	tell (a_text: READABLE_STRING_GENERAL)
		do
			if attached say as al_say then
				al_say.call ([a_text])
			end
		end

	redraw
		do
			if attached refresh as al_refresh then
				al_refresh.call
			end
		end

invariant
	named: not noun.is_empty

end
