note
	description: "[
		The window's lookup box: a single-line text box where Enter runs the
		lookup. SW_TEXT_BOX drops Enter in single-line mode, and a window
		accelerator needs a modifier for it, so the box catches it here.

		It keeps Ctrl+Z and Ctrl+Y for its own typing only while what it
		shows was typed and not yet sent (2026-11-03): this box holds the
		keyboard most of the time, so once a lookup is sent (or the program
		sets the text), Ctrl+Z is the program's Undo again.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LOOKUP_BOX

inherit
	SW_TEXT_BOX
		redefine
			handle_char, takes_typing, set_text
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
				settled_text := text.twin
				if attached on_enter as al_action then
					al_action.call (Void)
				end
			else
				Precursor (a_code)
			end
		end

	takes_typing: BOOLEAN
			-- Only what was typed and not yet sent keeps Ctrl+Z here.
		do
			Result := Precursor and then not text.same_string (settled_text)
		end

	set_text (a_text: READABLE_STRING_GENERAL)
			-- Text the program sets is settled, not typing.
		do
			Precursor (a_text)
			settled_text := text.twin
		end

feature {NONE} -- Implementation

	on_enter: detachable PROCEDURE
			-- What Enter does.

	settled_text: STRING_32
			-- What the box showed when last sent or set by the program.
		attribute
			create Result.make_empty
		end

end
