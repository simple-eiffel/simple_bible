note
	description: "[
		Whether a Markdown line stands inside a code fence (design scan 66): a fence
		opens with a run of three or more backticks or tildes, and closes only with
		a run of the same character at least as long with nothing after it, so a
		four-backtick fence can hold a three-backtick line. The block splitter
		(BIB_MARKDOWN_BLOCKS) and the notes importer (BIB_NOTE_IMPORTER) read fences
		by this one rule (they had disagreed: the importer took tildes, the
		splitter did not, and neither counted lengths).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FENCE_TRACKER

feature -- Status

	is_inside: BOOLEAN
			-- Is the last line fed inside a fence (its opening and closing lines included)?

	was_fence_line: BOOLEAN
			-- Did the last line fed open or close a fence?

feature -- Reading

	feed (a_line: READABLE_STRING_GENERAL)
			-- Read the next line; `is_inside' and `was_fence_line' follow. `a_line' is left as it is.
		local
			l_char: CHARACTER_32
			l_run: INTEGER
			l_line: STRING_32
		do
			was_fence_line := False
				-- a copy: `to_string_32' is the caller's own string when it is one (scan 67: the
				-- caller's line lost its indentation)
			create l_line.make_from_string_general (a_line)
			l_line.prune_all ('%R')
			l_line.left_adjust
			if not l_line.is_empty and then (l_line [1] = '`' or l_line [1] = '~') then
				l_char := l_line [1]
				from until l_run = l_line.count or else l_line [l_run + 1] /= l_char loop
					l_run := l_run + 1
				end
			end
			if closes_on_next then
				is_inside := False
				closes_on_next := False
			end
			if is_inside then
				if l_run >= fence_length and then l_char = fence_char and then l_run >= 3
					and then is_blank (l_line.substring (l_run + 1, l_line.count))
				then
					was_fence_line := True
					closes_on_next := True
				end
			elseif l_run >= 3 then
				is_inside := True
				was_fence_line := True
				fence_char := l_char
				fence_length := l_run
			end
		ensure
			fence_lines_inside: was_fence_line implies is_inside
		end

	reset
			-- Outside any fence.
		do
			is_inside := False
			was_fence_line := False
			closes_on_next := False
			fence_length := 0
		ensure
			outside: not is_inside
		end

feature {NONE} -- Implementation

	fence_char: CHARACTER_32
	fence_length: INTEGER
			-- The open fence's character and run.

	closes_on_next: BOOLEAN
			-- Was the last line the open fence's closing line (so the next one is outside)?

	is_blank (a_text: STRING_32): BOOLEAN
		do
			Result := across a_text as ic all ic.is_space end
		end

end
