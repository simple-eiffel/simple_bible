note
	description: "A span of characters in one text (hit, mark, diff run, script run), with an optional tag."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TEXT_SPAN

inherit
	ANY
		redefine
			is_equal
		end

create
	make

feature {NONE} -- Initialization

	make (a_start, a_length, a_tag: INTEGER)
			-- Span of `a_length' characters from `a_start' (1-based), tagged `a_tag'.
		require
			start_positive: a_start >= 1
			length_non_negative: a_length >= 0
		do
			start := a_start
			length := a_length
			tag := a_tag
		ensure
			start_set: start = a_start
			length_set: length = a_length
			tag_set: tag = a_tag
		end

feature -- Access

	start: INTEGER
	length: INTEGER
	tag: INTEGER

	finish: INTEGER
			-- Last character position (start - 1 when empty).
		do
			Result := start + length - 1
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
		do
			Result := start = other.start and length = other.length and tag = other.tag
		end

invariant
	start_positive: start >= 1
	length_non_negative: length >= 0

end
