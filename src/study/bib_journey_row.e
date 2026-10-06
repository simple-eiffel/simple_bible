note
	description: "One witness on a word's journey: who, when, which rendering, how often, and how it was computed (AC-1a-28)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_JOURNEY_ROW

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_witness: READABLE_STRING_GENERAL; a_year: INTEGER; a_rendering: READABLE_STRING_GENERAL; a_count: INTEGER_64;
			a_method_label: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
		require
			witness_named: not a_witness.is_empty
			rendering_given: not a_rendering.is_empty
			count_non_negative: a_count >= 0
			method_on_row: not a_method_label.is_empty
		do
			witness := a_witness.to_string_32
			year := a_year
			rendering := a_rendering.to_string_32
			count := a_count
			method_label := a_method_label.to_string_32
			provenance := a_provenance
		end

feature -- Access

	witness: STRING_32
			-- e.g. "Tyndale 1526", "KJV (1769 Blayney)".
	year: INTEGER
	rendering: STRING_32
			-- e.g. "congregation", "church".
	count: INTEGER_64
	method_label: STRING_32
	provenance: BIB_PROVENANCE

invariant
	witness_named: not witness.is_empty
	method_on_row: not method_label.is_empty
	count_non_negative: count >= 0

end
