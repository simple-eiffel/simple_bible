note
	description: "[
		Chunked long work on its own SCOOP processor (A-005, A-006): one chunk is
		one book or one guide section. It reports through a separate mailbox and
		stops through a separate token, read once per chunk boundary. A cancelled
		job yields no result object, and its mailbox holds zero pages (AC-1a-37);
		partial results are never findings.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_JOB [R -> BIB_ENGINE_RESULT]

feature -- Status

	is_started: BOOLEAN
	is_done: BOOLEAN
	is_cancelled: BOOLEAN
	has_result: BOOLEAN
	chunks_done: INTEGER
	chunk_total: INTEGER

	last_chunk_bounded: BOOLEAN
			-- Did the last `step' stay within one chunk (one book or one section)?

feature -- Execution

	run_to_completion (a_token: separate BIB_CANCEL_TOKEN; a_mailbox: separate BIB_JOB_MAILBOX)
			-- Run chunk by chunk, reading `a_token' between chunks and reporting to `a_mailbox'.
		require
			not_started: not is_started
		do
			-- Phase 4 (template, 07): start; until done: if the token is set, mark cancelled and
			-- close the mailbox cancelled; else `step' and report the page and progress; then close done.
		ensure
			finished: is_done
			cancel_observed: is_cancelled implies not has_result
			reported: a_mailbox.is_closed
			cancelled_mailbox_empty: is_cancelled implies (a_mailbox.is_cancelled and a_mailbox.page_count = 0)
			completed_mailbox_done: (not is_cancelled and has_result) implies a_mailbox.is_done
		end

	step
			-- Process exactly one bounded chunk.
		require
			started: is_started
			not_finished: not is_done
		deferred
		ensure
			progressed: chunks_done = old chunks_done + 1 or is_done
			bounded: last_chunk_bounded
		end

feature -- Result

	result_value: R
		require
			done: is_done
			not_cancelled: not is_cancelled
			succeeded: has_result
		deferred
		end

feature {NONE} -- Token access (one short separate call per chunk boundary)

	cancel_requested (a_token: separate BIB_CANCEL_TOKEN): BOOLEAN
		do
			Result := a_token.is_cancel_requested
		end

invariant
	progress_bounded: chunks_done >= 0 and chunks_done <= chunk_total
	cancelled_has_no_result: is_cancelled implies not has_result
	done_after_start: is_done implies is_started
	result_only_when_done: has_result implies is_done

end
