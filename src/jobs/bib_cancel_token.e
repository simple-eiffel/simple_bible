note
	description: "[
		A cancel request shared between a face and one job. It lives on its own
		SCOOP processor, so setting it never waits on the job's work (A-006).
		Monotone: once requested it stays requested (no reset feature exists).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CANCEL_TOKEN

create
	make

feature {NONE} -- Initialization

	make
		do
		ensure
			not_requested: not is_cancel_requested
		end

feature -- Status

	is_cancel_requested: BOOLEAN

feature -- Command

	request_cancel
			-- Ask the job to stop at its next chunk boundary.
		do
			is_cancel_requested := True
		ensure
			requested: is_cancel_requested
		end

end
