note
	description: "An explicit reference found in free text: the reference and where it was found."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REF_MATCH

create
	make

feature {NONE} -- Initialization

	make (a_reference: BIB_REF; a_start, a_finish: INTEGER; a_period_form: BOOLEAN)
			-- Match of `a_reference' at `a_start'..`a_finish'.
		require
			start_positive: a_start >= 1
			ordered: a_finish >= a_start
		do
			ref := a_reference
			start := a_start
			finish := a_finish
			is_period_form := a_period_form
		ensure
			reference_set: ref = a_reference
			start_set: start = a_start
			finish_set: finish = a_finish
		end

feature -- Access

	ref: BIB_REF
	start: INTEGER
	finish: INTEGER

	is_period_form: BOOLEAN
			-- Written "John 3.16" rather than "John 3:16" (R12 period form).

invariant
	start_positive: start >= 1
	ordered: finish >= start

end
