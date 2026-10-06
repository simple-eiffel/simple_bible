note
	description: "[
		Progress, pages and the final outcome of one job, as copied plain values;
		written by the job, read by a face. Lives on its own processor. Every
		change bumps `change_count', so a face waits for news with a SCOOP wait
		condition (BIB_JOB_WAITER) instead of polling. A job ends in exactly one
		of done, cancelled or failed; a cancelled job leaves zero pages
		(AC-1a-37, ER-10).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_JOB_MAILBOX

create
	make

feature {NONE} -- Initialization

	make
		do
			create pages.make (8)
			create error_text.make_empty
		ensure
			open: not is_closed
			empty: page_count = 0
			no_progress: progress = 0.0
		end

feature -- Status

	progress: REAL_64
	is_closed: BOOLEAN
	is_done: BOOLEAN
	is_cancelled: BOOLEAN
	is_failed: BOOLEAN
	error_text: STRING_32

	change_count: INTEGER_64
			-- Number of changes so far (posts, progress, close).

	page_count: INTEGER
		do
			Result := pages.count
		ensure
			model_agrees: Result = pages_model.count
		end

feature -- Access

	page (n: INTEGER): BIB_JOB_PAGE
		require
			in_range: n >= 1 and n <= page_count
		do
			Result := pages [n]
		end

feature -- Model

	pages_model: MML_SEQUENCE [BIB_JOB_PAGE]
		do
			create Result
			across pages as p loop
				Result := Result & p
			end
		end

feature -- Commands (called by the job)

	post_page (a_page: separate BIB_JOB_PAGE)
			-- Store a copy of `a_page' (pages arrive numbered 1, 2, 3 ...).
		require
			open: not is_closed
		do
			pages.extend (create {BIB_JOB_PAGE}.make_from_separate (a_page))
			change_count := change_count + 1
		ensure
			grown: page_count = old page_count + 1
			in_order: page (page_count).number = page_count
			earlier_unchanged: pages_model.but_last |=| old pages_model
			progress_unchanged: progress = old progress
			changed: change_count = old change_count + 1
		end

	set_progress (a_fraction: REAL_64)
		require
			open: not is_closed
			in_range: a_fraction >= 0.0 and a_fraction <= 1.0
			monotone: a_fraction >= progress
		do
			progress := a_fraction
			change_count := change_count + 1
		ensure
			set: progress = a_fraction
			pages_unchanged: pages_model |=| old pages_model
		end

	close_done
		require
			open: not is_closed
		do
			is_closed := True
			is_done := True
			change_count := change_count + 1
		ensure
			closed: is_closed and is_done
			pages_kept: pages_model |=| old pages_model
		end

	close_cancelled
			-- Close as cancelled; partial pages are dropped (never findings).
		require
			open: not is_closed
		do
			pages.wipe_out
			is_closed := True
			is_cancelled := True
			change_count := change_count + 1
		ensure
			closed: is_closed and is_cancelled
			cancelled_discards: page_count = 0
		end

	close_failed (a_message: separate READABLE_STRING_32)
		require
			open: not is_closed
		do
			error_text := create {STRING_32}.make_from_separate (a_message)
			is_closed := True
			is_failed := True
			change_count := change_count + 1
		ensure
			closed: is_closed and is_failed
			pages_kept: pages_model |=| old pages_model
		end

feature {NONE} -- Representation

	pages: ARRAYED_LIST [BIB_JOB_PAGE]

invariant
	progress_bounded: progress >= 0.0 and progress <= 1.0
	outcome_exclusive: is_closed implies (is_done.to_integer + is_cancelled.to_integer + is_failed.to_integer) = 1
	no_outcome_while_open: not is_closed implies not (is_done or is_cancelled or is_failed)
	cancelled_discards: is_cancelled implies page_count = 0
	changes_non_negative: change_count >= 0

end
