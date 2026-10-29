note
	description: "[
		A suggested passage written on a line of its own (0.7.32, research/21):
		"{{suggest: Galatians 5:1 | the same freedom from the law}}" - a passage the
		text alludes to without citing, and why. The importer checks it and the
		builder stores it apart from the citations, reading it by this one rule.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SUGGESTION_LINE

feature -- Reading

	parsed (a_line: READABLE_STRING_GENERAL): detachable TUPLE [passage, reason: STRING_32]
			-- The reference and reason of `a_line' when it is one suggestion standing alone (spaces
			-- around it allowed); Void otherwise. A suggestion without a "|" has an empty reason.
		local
			l_line, l_inner: STRING_32
			l_bar: INTEGER
		do
			l_line := a_line.to_string_32
			l_line.left_adjust
			l_line.right_adjust
			if l_line.starts_with (Opening) and then l_line.ends_with ({STRING_32} "}}") and then l_line.occurrences ('{') = 2 and then l_line.occurrences ('}') = 2 then
				l_inner := l_line.substring (Opening.count + 1, l_line.count - 2)
				l_bar := l_inner.index_of ('|', 1)
				if l_bar > 0 then
					Result := [trimmed (l_inner.substring (1, l_bar - 1)), trimmed (l_inner.substring (l_bar + 1, l_inner.count))]
				else
					Result := [trimmed (l_inner), create {STRING_32}.make_empty]
				end
			end
		end

	mentions (a_line: READABLE_STRING_GENERAL): BOOLEAN
			-- Does `a_line' hold a suggestion's opening anywhere?
		do
			Result := a_line.to_string_32.has_substring (Opening)
		end

	Opening: STRING_32 = "{{suggest:"

feature {NONE} -- Implementation

	trimmed (a_text: STRING_32): STRING_32
		do
			Result := a_text.twin
			Result.left_adjust
			Result.right_adjust
		end

end
