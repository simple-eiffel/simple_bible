note
	description: "An unnamed quotation candidate found by shingles; a candidate is never evidence until read."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUOTATION_MATCH

create
	make

feature {NONE} -- Initialization

	make (a_hub_id: INTEGER_64; a_start, a_length, a_match_length: INTEGER)
			-- Candidate quotation of verse `a_hub_id' at `a_start' (characters) matching `a_match_length' tokens.
		require
			hub_positive: a_hub_id > 0
			start_positive: a_start >= 1
			length_positive: a_length >= 1
			long_enough: a_match_length >= {BIB_QUOTATION_DETECTOR}.Min_n
		do
			hub_id := a_hub_id
			start := a_start
			length := a_length
			match_length := a_match_length
		ensure
			hub_set: hub_id = a_hub_id
			match_length_set: match_length = a_match_length
		end

feature -- Access

	hub_id: INTEGER_64
	start: INTEGER
	length: INTEGER
	match_length: INTEGER
			-- Matching tokens.

	is_evidence: BOOLEAN
			-- Never: a detector candidate is not evidence until read.
		do
		ensure
			never: not Result
		end

invariant
	long_enough: match_length >= {BIB_QUOTATION_DETECTOR}.Min_n

end
