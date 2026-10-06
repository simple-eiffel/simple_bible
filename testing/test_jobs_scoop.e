note
	description: "[
		Jobs on SCOOP processors: the cancel token and the mailbox live on their
		own processors; waiting uses wait conditions, not polling (AC-1a-37).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_JOBS_SCOOP

inherit
	TEST_SET_BASE

feature -- Tests

	test_cancel_token_across_processors
		local
			l_token: separate BIB_CANCEL_TOKEN
		do
			create l_token.make
			assert ("not yet", not is_requested (l_token))
			request (l_token)
			assert ("requested", is_requested (l_token))
		end

	test_cancelled_mailbox_holds_zero_pages
		local
			l_mailbox: separate BIB_JOB_MAILBOX
			l_waiter: BIB_JOB_WAITER
		do
			create l_mailbox.make
			post (l_mailbox, page (1))
			post (l_mailbox, page (2))
			cancel (l_mailbox)
			create l_waiter
			l_waiter.await_closed (l_mailbox)
			assert ("cancelled", l_waiter.was_cancelled (l_mailbox))
			assert_integers_equal ("no pages", 0, l_waiter.page_count_of (l_mailbox))
		end

	test_done_mailbox_keeps_pages_in_order
		local
			l_mailbox: separate BIB_JOB_MAILBOX
			l_waiter: BIB_JOB_WAITER
		do
			create l_mailbox.make
			post (l_mailbox, page (1))
			post (l_mailbox, page (2))
			finish (l_mailbox)
			create l_waiter
			l_waiter.await_closed (l_mailbox)
			assert_integers_equal ("two pages", 2, l_waiter.page_count_of (l_mailbox))
			assert ("not cancelled", not l_waiter.was_cancelled (l_mailbox))
		end

	test_waiter_wakes_on_change
		local
			l_mailbox: separate BIB_JOB_MAILBOX
			l_waiter: BIB_JOB_WAITER
			l_seen: INTEGER_64
		do
			create l_mailbox.make
			create l_waiter
			post (l_mailbox, page (1))
			l_seen := l_waiter.await_change (l_mailbox, 0)
			assert ("woke after one change", l_seen >= 1)
		end

	test_cancelled_job_yields_no_result
			-- Skeletal (Phase 5, AC-1a-37): a search or census job cancelled mid-run yields no result object
			-- and its mailbox holds zero pages.
		do
		end

feature {NONE} -- Separate access

	page (a_number: INTEGER): BIB_JOB_PAGE
		do
			create Result.make (a_number)
			Result.add_row (a_number * 100, "row")
		end

	post (a_mailbox: separate BIB_JOB_MAILBOX; a_page: BIB_JOB_PAGE)
		do
			a_mailbox.post_page (a_page)
		end

	cancel (a_mailbox: separate BIB_JOB_MAILBOX)
		do
			a_mailbox.close_cancelled
		end

	finish (a_mailbox: separate BIB_JOB_MAILBOX)
		do
			a_mailbox.close_done
		end

	request (a_token: separate BIB_CANCEL_TOKEN)
		do
			a_token.request_cancel
		end

	is_requested (a_token: separate BIB_CANCEL_TOKEN): BOOLEAN
		do
			Result := a_token.is_cancel_requested
		end

end
