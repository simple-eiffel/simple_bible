note
	description: "[
		Waiting for a job without polling: each feature takes the mailbox as a
		separate argument and states what it waits for as a precondition, which
		SCOOP turns into a wait condition. The caller's processor sleeps until
		the job changes the mailbox; no heartbeat, no busy loop.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_JOB_WAITER

feature -- Waiting

	await_change (a_mailbox: separate BIB_JOB_MAILBOX; a_seen: INTEGER_64): INTEGER_64
			-- Wait until `a_mailbox' changed since `a_seen'; its change count then.
		require
			changed: a_mailbox.change_count > a_seen
		do
			Result := a_mailbox.change_count
		ensure
			newer: Result > a_seen
		end

	await_closed (a_mailbox: separate BIB_JOB_MAILBOX)
			-- Wait until the job has ended (done, cancelled or failed).
		require
			closed: a_mailbox.is_closed
		do
		ensure
			closed: a_mailbox.is_closed
		end

	page_count_of (a_mailbox: separate BIB_JOB_MAILBOX): INTEGER
			-- Pages currently held by `a_mailbox'.
		do
			Result := a_mailbox.page_count
		end

	was_cancelled (a_mailbox: separate BIB_JOB_MAILBOX): BOOLEAN
			-- Did the job end cancelled?
		do
			Result := a_mailbox.is_cancelled
		end

end
