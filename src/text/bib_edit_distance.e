note
	description: "[
		How many single-letter edits turn one word into another (research/20's
		fuzzy search): an insertion, a deletion, a change, or two neighbors
		swapped, each counting one (the optimal string alignment distance). It
		stops counting past a limit, so a long vocabulary is cheap to sweep.
		(It fills the harvest's S-30/X-06 stub, which was never implemented.)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EDIT_DISTANCE

feature -- Measurement

	distance (a_first, a_second: READABLE_STRING_32; a_limit: INTEGER): INTEGER
			-- The edits between `a_first' and `a_second'; `a_limit' + 1 once it is past `a_limit'.
		require
			limit_not_negative: a_limit >= 0
		local
			l_rows: ARRAY [ARRAY [INTEGER]]
			l_n, l_m, i, j, l_cost, l_row_best: INTEGER
		do
			l_n := a_first.count
			l_m := a_second.count
			if (l_n - l_m).abs > a_limit then
				Result := a_limit + 1
			else
				create l_rows.make_filled (create {ARRAY [INTEGER]}.make_empty, 0, l_n)
				from i := 0 until i > l_n loop
					l_rows [i] := create {ARRAY [INTEGER]}.make_filled (0, 0, l_m)
					l_rows [i] [0] := i
					i := i + 1
				end
				from j := 0 until j > l_m loop
					l_rows [0] [j] := j
					j := j + 1
				end
				from i := 1 until i > l_n or Result > a_limit loop
					l_row_best := l_rows [i] [0]
					from j := 1 until j > l_m loop
						if a_first [i] = a_second [j] then
							l_cost := 0
						else
							l_cost := 1
						end
						l_rows [i] [j] := (l_rows [i - 1] [j] + 1).min (l_rows [i] [j - 1] + 1).min (l_rows [i - 1] [j - 1] + l_cost)
						if i > 1 and j > 1 and then a_first [i] = a_second [j - 1] and then a_first [i - 1] = a_second [j] then
							l_rows [i] [j] := l_rows [i] [j].min (l_rows [i - 2] [j - 2] + 1)
						end
						l_row_best := l_row_best.min (l_rows [i] [j])
						j := j + 1
					end
					if l_row_best > a_limit then
						Result := a_limit + 1
					end
					i := i + 1
				end
				if Result = 0 then
					Result := l_rows [l_n] [l_m].min (a_limit + 1)
				end
			end
		ensure
			bounded: Result >= 0 and Result <= a_limit + 1
			zero_iff_equal: (Result = 0) = a_first.same_string (a_second)
			length_gap: Result >= (a_first.count - a_second.count).abs.min (a_limit + 1)
		end

	limit_for (a_word: READABLE_STRING_32): INTEGER
			-- The edits fuzzy search allows `a_word': one up to five letters, two beyond, none under
			-- three.
		do
			if a_word.count >= 6 then
				Result := 2
			elseif a_word.count >= 3 then
				Result := 1
			end
		ensure
			small: Result >= 0 and Result <= 2
		end

end
