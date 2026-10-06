note
	description: "A passage: start and end references in one system, in canonical order."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_REF_RANGE

create
	make, make_single

feature {NONE} -- Initialization

	make (a_start, a_finish: BIB_REF)
			-- Create the range `a_start' .. `a_finish'.
		require
			same_system: a_start.system ~ a_finish.system
			ordered: is_ordered (a_start, a_finish)
		do
			start := a_start
			finish := a_finish
		ensure
			start_set: start = a_start
			finish_set: finish = a_finish
		end

	make_single (a_ref: BIB_REF)
			-- Create a one-verse range.
		do
			start := a_ref
			finish := a_ref
		ensure
			single: start = a_ref and finish = a_ref
		end

feature -- Access

	start: BIB_REF
	finish: BIB_REF

feature -- Status

	is_single_verse: BOOLEAN
			-- Does the range hold one verse?
		do
			Result := start ~ finish
		end

	is_ordered (a_start, a_finish: BIB_REF): BOOLEAN
			-- Does `a_start' come no later than `a_finish' (book, chapter, verse)?
		do
			Result := a_start.book_id < a_finish.book_id
				or else (a_start.book_id = a_finish.book_id and then
					(a_start.chapter < a_finish.chapter
					or else (a_start.chapter = a_finish.chapter and then a_start.verse <= a_finish.verse)))
		end

invariant
	same_system: start.system ~ finish.system
	ordered: is_ordered (start, finish)

end
