note
	description: "[
		The spaced-repetition schedule of memory cards (FR-118: deterministic,
		given the dates): SuperMemo 2. A review is graded 0 to 5; below 3 the card
		starts again tomorrow; otherwise the interval grows (1 day, 6 days, then
		the last interval times the ease) and the ease moves with the grade,
		never below 130 percent. The same grades on the same days always give the
		same next date.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_MEMORY_SCHEDULE

feature -- Schedule

	next_repetitions (a_repetitions, a_grade: INTEGER): INTEGER
			-- Good reviews in a row after grade `a_grade'.
		require
			grade_valid: is_valid_grade (a_grade)
		do
			if a_grade < Passing_grade then
				Result := 0
			else
				Result := a_repetitions + 1
			end
		ensure
			reset_on_failure: a_grade < Passing_grade implies Result = 0
		end

	next_interval (a_repetitions, a_interval, a_ease, a_grade: INTEGER): INTEGER
			-- Days until the next review after grade `a_grade'.
		require
			grade_valid: is_valid_grade (a_grade)
			ease_floor: a_ease >= Least_ease
		do
			if a_grade < Passing_grade then
				Result := 1
			elseif a_repetitions = 0 then
				Result := 1
			elseif a_repetitions = 1 then
				Result := 6
			else
				Result := ((a_interval * a_ease + 50) // 100).max (1)
			end
		ensure
			at_least_a_day: Result >= 1
		end

	next_ease (a_ease, a_grade: INTEGER): INTEGER
			-- The ease (percent) after grade `a_grade': SM-2's EF + (0.1 - (5 - q)(0.08 + (5 - q)0.02)),
			-- in hundredths, never below `Least_ease'.
		require
			grade_valid: is_valid_grade (a_grade)
		local
			l_miss: INTEGER
		do
			l_miss := 5 - a_grade
			Result := (a_ease + 10 - l_miss * (8 + l_miss * 2)).max (Least_ease)
		ensure
			floor: Result >= Least_ease
		end

feature -- Status

	is_valid_grade (a_grade: INTEGER): BOOLEAN
			-- Is `a_grade' a grade, `Lowest_grade' to `Highest_grade'?
		do
			Result := a_grade >= Lowest_grade and a_grade <= Highest_grade
		end

feature -- Constants

	Lowest_grade: INTEGER = 0
	Highest_grade: INTEGER = 5
			-- SM-2's grades.

	Grade_again: INTEGER = 1
	Grade_hard: INTEGER = 3
	Grade_good: INTEGER = 4
	Grade_easy: INTEGER = 5
			-- The four buttons. Hard is the lowest passing grade (`Passing_grade').

	First_ease: INTEGER = 250
	Least_ease: INTEGER = 130
	Passing_grade: INTEGER = 3

end
