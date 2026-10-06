note
	description: "[
		SCOOP consumer compatibility test (Phase 1 mandatory gate): a SCOOP
		consumer declares the engine's main types as separate and uses them
		across processors without VUAR(2) errors. A worker's SIMPLE_BIBLE is
		created from a separate configuration (plain values copied); the job's
		token and mailbox live on their own processors.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SCOOP_CONSUMER

inherit
	TEST_SET_BASE

feature -- Test

	test_scoop_compatibility
		local
			l_config: BIB_CONFIG
			l_bible: separate SIMPLE_BIBLE
			l_token: separate BIB_CANCEL_TOKEN
			l_mailbox: separate BIB_JOB_MAILBOX
			l_waiter: BIB_JOB_WAITER
			l_page: BIB_JOB_PAGE
		do
			create l_config.make_with_core ("core.db")
			create l_bible.make_from_separate (l_config)
			assert ("worker engine unopened", not bible_is_open (l_bible))
			assert ("worker engine has the copied path", bible_core_path_is (l_bible, "core.db"))
			create l_token.make
			cancel_token (l_token)
			create l_mailbox.make
			create l_page.make (1)
			l_page.add_row (2501, "John 3:16")
			post_page (l_mailbox, l_page)
			fail_mailbox (l_mailbox)
			create l_waiter
			l_waiter.await_closed (l_mailbox)
			assert ("failed outcome keeps its page", l_waiter.page_count_of (l_mailbox) = 1)
		end

feature {NONE} -- Separate access

	bible_is_open (a_bible: separate SIMPLE_BIBLE): BOOLEAN
		do
			Result := a_bible.is_open
		end

	bible_core_path_is (a_bible: separate SIMPLE_BIBLE; a_path: STRING_8): BOOLEAN
		do
			Result := (create {STRING_32}.make_from_separate (a_bible.config.core_path)).same_string_general (a_path)
		end

	cancel_token (a_token: separate BIB_CANCEL_TOKEN)
		do
			a_token.request_cancel
		end

	post_page (a_mailbox: separate BIB_JOB_MAILBOX; a_page: BIB_JOB_PAGE)
		do
			a_mailbox.post_page (a_page)
		end

	fail_mailbox (a_mailbox: separate BIB_JOB_MAILBOX)
		do
			a_mailbox.close_failed ({STRING_32} "test failure")
		end

end
