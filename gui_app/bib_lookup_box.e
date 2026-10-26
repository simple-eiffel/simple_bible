note
	description: "[
		The window's lookup box: a single-line text box where Enter runs the
		lookup. SW_TEXT_BOX drops Enter in single-line mode, and a window
		accelerator needs a modifier for it, so the box catches it here.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LOOKUP_BOX

inherit
	SW_TEXT_BOX
		redefine
			handle_char
		end

create
	make_lookup

feature {NONE} -- Initialization

	make_lookup
			-- An empty single-line lookup box.
		do
			make_single_line ("")
		end

feature -- Element change

	set_on_enter (a_action: PROCEDURE)
			-- Run `a_action' when the reader presses Enter.
		do
			on_enter := a_action
		ensure
			set: on_enter = a_action
		end

feature -- Events

	handle_char (a_code: INTEGER)
			-- Enter runs `on_enter'; every other key behaves as in any text box.
		do
			if a_code = 13 then
				if attached on_enter as al_action then
					al_action.call (Void)
				end
			else
				Precursor (a_code)
			end
		end

feature {NONE} -- Implementation

	on_enter: detachable PROCEDURE
			-- What Enter does.

end
