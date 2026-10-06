note
	description: "Levenshtein distance for fuzzy book and term matching (harvest S-30, X-06)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_EDIT_DISTANCE

feature -- Measurement

	distance (a, b: READABLE_STRING_GENERAL): INTEGER
			-- Edit distance between `a' and `b'.
		do
			-- Phase 4
		ensure
			non_negative: Result >= 0
			zero_iff_equal: (Result = 0) = a.same_string (b)
			bounded: Result <= a.count.max (b.count)
			length_gap: Result >= (a.count - b.count).abs
		end

end
