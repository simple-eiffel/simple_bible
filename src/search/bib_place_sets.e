note
	description: "[
		Sets of verse places kept as ascending lists, each place once: union,
		intersection and difference by merging. One copy for the verse search and
		the concordance (design scan 48: the merge was written twice). Inherited
		side by side with BIB_PLACE_PACKING. The ascending law is checked where a
		list is made, not at every merge: the merges run in hot loops.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PLACE_SETS

feature -- Status

	is_ascending (a_places: LIST [INTEGER_64]): BOOLEAN
			-- Does each place in `a_places' follow the one before it?
		local
			i: INTEGER
		do
			Result := True
			from i := 2 until i > a_places.count or not Result loop
				Result := a_places.i_th (i - 1) < a_places.i_th (i)
				i := i + 1
			end
		end

feature -- Set algebra

	sorted_once (a_places: ARRAYED_LIST [INTEGER_64]): ARRAYED_LIST [INTEGER_64]
			-- `a_places' ascending, each once. An insertion sort: the lists it gets are nearly sorted
			-- (Hebrew places moved to English numbers shift only locally), so it runs near linear.
		local
			l_sorted: ARRAYED_LIST [INTEGER_64]
			i, j: INTEGER
			l_place: INTEGER_64
		do
			l_sorted := a_places.twin
			from i := 2 until i > l_sorted.count loop
				l_place := l_sorted.i_th (i)
				from j := i - 1 until j < 1 or else l_sorted.i_th (j) <= l_place loop
					l_sorted.put_i_th (l_sorted.i_th (j), j + 1)
					j := j - 1
				end
				l_sorted.put_i_th (l_place, j + 1)
				i := i + 1
			end
			create Result.make (l_sorted.count)
			across l_sorted as ic loop
				if Result.is_empty or else Result.last /= ic then
					Result.extend (ic)
				end
			end
		ensure
			ascending_once: is_ascending (Result)
		end

	union (a, b: ARRAYED_LIST [INTEGER_64]): ARRAYED_LIST [INTEGER_64]
			-- Every place in `a' or `b' (each ascending), ascending, once.
		local
			i, j: INTEGER
		do
			create Result.make (a.count + b.count)
			from i := 1; j := 1 until i > a.count and j > b.count loop
				if j > b.count or else (i <= a.count and then a.i_th (i) < b.i_th (j)) then
					Result.extend (a.i_th (i))
					i := i + 1
				elseif i > a.count or else b.i_th (j) < a.i_th (i) then
					Result.extend (b.i_th (j))
					j := j + 1
				else
					Result.extend (a.i_th (i))
					i := i + 1
					j := j + 1
				end
			end
		ensure
			no_smaller: Result.count >= a.count.max (b.count)
		end

	intersection (a, b: ARRAYED_LIST [INTEGER_64]): ARRAYED_LIST [INTEGER_64]
			-- Every place in both `a' and `b' (each ascending), ascending.
		local
			i, j: INTEGER
		do
			create Result.make (a.count.min (b.count))
			from i := 1; j := 1 until i > a.count or j > b.count loop
				if a.i_th (i) < b.i_th (j) then
					i := i + 1
				elseif b.i_th (j) < a.i_th (i) then
					j := j + 1
				else
					Result.extend (a.i_th (i))
					i := i + 1
					j := j + 1
				end
			end
		ensure
			no_larger: Result.count <= a.count.min (b.count)
		end

	difference (a, b: ARRAYED_LIST [INTEGER_64]): ARRAYED_LIST [INTEGER_64]
			-- Every place in `a' and not in `b' (each ascending), ascending.
		local
			i, j: INTEGER
		do
			create Result.make (a.count)
			from i := 1; j := 1 until i > a.count loop
				if j > b.count or else a.i_th (i) < b.i_th (j) then
					Result.extend (a.i_th (i))
					i := i + 1
				elseif b.i_th (j) < a.i_th (i) then
					j := j + 1
				else
					i := i + 1
					j := j + 1
				end
			end
		ensure
			no_larger: Result.count <= a.count
		end

end
