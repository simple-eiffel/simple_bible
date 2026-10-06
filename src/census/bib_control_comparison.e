note
	description: "One control's count and rate against the target's, with the provenance of the counted edition."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONTROL_COMPARISON

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_control: BIB_KEY; a_control_count: INTEGER_64; a_control_rate, a_target_rate: REAL_64; a_provenance: BIB_PROVENANCE)
		require
			count_non_negative: a_control_count >= 0
			rates_non_negative: a_control_rate >= 0.0 and a_target_rate >= 0.0
		do
			control := a_control
			control_count := a_control_count
			control_rate := a_control_rate
			target_rate := a_target_rate
			provenance := a_provenance
		end

feature -- Access

	control: BIB_KEY
	control_count: INTEGER_64
	control_rate: REAL_64
	target_rate: REAL_64
	provenance: BIB_PROVENANCE

feature -- Status

	target_exceeds_control: BOOLEAN
		do
			Result := target_rate > control_rate
		end

invariant
	count_non_negative: control_count >= 0

end
