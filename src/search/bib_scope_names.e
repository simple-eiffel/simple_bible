note
	description: "[
		The named search scopes and their book ranges, in the order a list shows
		them, with the other names readers use for them (OT, NT, Paul). The one
		table (design scan 52: the window kept its own list beside
		BIB_SEARCH_SCOPES, and a mismatch silently became the whole Bible).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SCOPE_NAMES

feature -- Access

	Whole_bible_name: STRING_32 = "Whole Bible"
			-- The scope of every book.

	names: ARRAYED_LIST [STRING_32]
			-- The named scopes, in order.
		once
			create Result.make (Ranges.count)
			across Ranges as ic loop
				Result.extend (ic.name)
			end
		end

	range_named (a_name: READABLE_STRING_GENERAL): detachable TUPLE [from_book, to_book: INTEGER; name: STRING_32]
			-- The range `a_name' (any case, or another name for it) names; Void when it names none.
		local
			l_name: STRING_32
		do
			l_name := a_name.to_string_32.as_lower
			l_name.left_adjust
			l_name.right_adjust
			across Other_names as ic loop
				if ic.spoken.same_string (l_name) then
					l_name := ic.name.as_lower
				end
			end
			across Ranges as ic until Result /= Void loop
				if ic.name.as_lower.same_string (l_name) then
					Result := [ic.from_book, ic.to_book, ic.name]
				end
			end
		end

feature {NONE} -- Tables

	Ranges: ARRAY [TUPLE [name: STRING_32; from_book, to_book: INTEGER]]
			-- The named scopes, from BIB_CANON.
		once
			Result := <<[{STRING_32} "Old Testament", {BIB_CANON}.First_book, {BIB_CANON}.Last_old_testament_book],
				[{STRING_32} "New Testament", {BIB_CANON}.First_new_testament_book, {BIB_CANON}.Last_book],
				[{STRING_32} "Gospels", {BIB_CANON}.First_gospel, {BIB_CANON}.Last_gospel],
				[{STRING_32} "Paul's letters", {BIB_CANON}.First_letter_of_paul, {BIB_CANON}.Last_letter_of_paul]>>
		end

	Other_names: ARRAY [TUPLE [spoken, name: STRING_32]]
			-- Other names readers use, lowercase.
		once
			Result := <<[{STRING_32} "ot", {STRING_32} "Old Testament"], [{STRING_32} "nt", {STRING_32} "New Testament"],
				[{STRING_32} "pauline letters", {STRING_32} "Paul's letters"], [{STRING_32} "paul", {STRING_32} "Paul's letters"]>>
		end

end
