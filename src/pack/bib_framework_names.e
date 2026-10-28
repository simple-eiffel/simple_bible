note
	description: "[
		Where a FRAMEWORK(TM) is named in a text (2026-10-28): the one rule the pack
		builder uses to find the commentary sections that name a framework and the
		linker uses to make its links. A spelling matches as written (case counts),
		standing as a word of its own; a framework prose marks (TM) matches by its
		name only when the mark follows ("LOVE(TM)", never the English "LOVE" of a
		heading in capitals, nor the essay title "JESUS 09"), and the mark is part
		of the match. A mark may also follow any word inside a spelling ("the
		JESUS(TM) Cornerstone"). Spellings are tried longest first, so "the JESUS
		Cornerstone" wins over "JESUS".
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FRAMEWORK_NAMES

create
	make,
	make_from_spellings

feature {NONE} -- Initialization

	make (a_spellings: ITERABLE [TUPLE [spelling, id: STRING_32; needs_mark: BOOLEAN]])
			-- Find the spellings of `a_spellings', longest first.
		do
			create spellings.make (16)
			across a_spellings as ic loop
				if not ic.spelling.is_empty then
					spellings.extend ([ic.spelling.twin, ic.id.twin, ic.needs_mark])
				end
			end
			sort_longest_first
		end

	make_from_spellings (a_spellings: BIB_LIST_RESULT [BIB_FRAMEWORK_SPELLING])
			-- Find the pack's spellings `a_spellings' (BIB_FRAMEWORK_PACK.aliases), longest first.
		local
			i: INTEGER
		do
			create spellings.make (a_spellings.count)
			from i := 1 until i > a_spellings.count loop
				spellings.extend ([a_spellings.item (i).spelling.twin, a_spellings.item (i).id.twin, a_spellings.item (i).needs_mark])
				i := i + 1
			end
			sort_longest_first
		end

feature -- Access

	spellings: ARRAYED_LIST [TUPLE [spelling, id: STRING_32; needs_mark: BOOLEAN]]
			-- The spellings found, the longest first.

	Mark: CHARACTER_32 = '%/8482/'
			-- (TM).

	match_at (a_text: READABLE_STRING_32; a_start: INTEGER): detachable TUPLE [last: INTEGER; id: STRING_32]
			-- The framework named at `a_start' (its last character, a following mark included, and
			-- its id); Void when none starts there.
		require
			in_text: a_start >= 1 and a_start <= a_text.count
		local
			i: INTEGER
			l_span: TUPLE [last: INTEGER; marked: BOOLEAN]
		do
			if a_start = 1 or else not is_word_character (a_text [a_start - 1]) then
				from i := 1 until i > spellings.count or Result /= Void loop
					l_span := span_of (a_text, a_start, spellings.i_th (i).spelling)
					if l_span.last > 0 and then (l_span.marked or not spellings.i_th (i).needs_mark)
						and then (l_span.last = a_text.count or else not is_word_character (a_text [l_span.last + 1]))
					then
						Result := [l_span.last, spellings.i_th (i).id]
					end
					i := i + 1
				end
			end
		ensure
			after_start: attached Result as r implies r.last >= a_start and r.last <= a_text.count
		end

	ids_in (a_text: READABLE_STRING_32): ARRAYED_LIST [STRING_32]
			-- The frameworks `a_text' names, each once, in the order first named.
		local
			i: INTEGER
		do
			create Result.make (4)
			Result.compare_objects
			from i := 1 until i > a_text.count loop
				if attached match_at (a_text, i) as al_match then
					if not Result.has (al_match.id) then
						Result.extend (al_match.id)
					end
					i := al_match.last + 1
				else
					i := i + 1
				end
			end
		ensure
			each_once: across Result as al_id all Result.occurrences (al_id) = 1 end
		end

	is_word_character (a_character: CHARACTER_32): BOOLEAN
			-- A letter or digit, which a name may not touch.
		do
			Result := a_character.is_alpha or a_character.is_digit
		end

feature {NONE} -- Implementation

	span_of (a_text: READABLE_STRING_32; a_start: INTEGER; a_spelling: STRING_32): TUPLE [last: INTEGER; marked: BOOLEAN]
			-- Where `a_spelling' written at `a_start' ends (a mark after a word inside it, or after
			-- it, taken in) and whether a mark was; `last' 0 when it is not written there.
		require
			in_text: a_start >= 1 and a_start <= a_text.count
			spelled: not a_spelling.is_empty
		local
			i, j: INTEGER
			l_marked, l_failed: BOOLEAN
		do
			from
				i := 1
				j := a_start
			until
				i > a_spelling.count or l_failed
			loop
				if j > a_text.count then
					l_failed := True
				elseif a_text [j] = Mark and then a_spelling [i] /= Mark and then j > a_start and then is_word_character (a_text [j - 1]) then
						-- a mark after a word inside the spelling: "the JESUS(TM) Cornerstone"
					l_marked := True
					j := j + 1
				elseif a_text [j] = a_spelling [i] then
					i := i + 1
					j := j + 1
				else
					l_failed := True
				end
			end
			if l_failed then
				Result := [0, False]
			else
				if j <= a_text.count and then a_text [j] = Mark then
					l_marked := True
					j := j + 1
				end
				Result := [j - 1, l_marked]
			end
		ensure
			within_text: Result.last = 0 or (Result.last >= a_start and Result.last <= a_text.count)
		end

	sort_longest_first
			-- `spellings' ordered by length, the longest first (a stable insertion sort: the lists
			-- are tens long).
		local
			i, j: INTEGER
			l_item: TUPLE [spelling, id: STRING_32; needs_mark: BOOLEAN]
		do
			from i := 2 until i > spellings.count loop
				l_item := spellings.i_th (i)
				from j := i - 1 until j < 1 or else spellings.i_th (j).spelling.count >= l_item.spelling.count loop
					spellings.put_i_th (spellings.i_th (j), j + 1)
					j := j - 1
				end
				spellings.put_i_th (l_item, j + 1)
				i := i + 1
			end
		ensure
			longest_first: across 2 |..| spellings.count as al_i all spellings.i_th (al_i - 1).spelling.count >= spellings.i_th (al_i).spelling.count end
		end

invariant
	spellings_attached: spellings /= Void

end
