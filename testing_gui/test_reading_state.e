note
	description: "[
		BIB_READING_STATE (research/23 phase 3, 2026-11-01): a verse of the same
		chapter tells only the verse; a new chapter tells the chapter, then the
		verse; a new version tells the version and the chapter; the trail drops
		the steps ahead and never repeats the place read; joining tells the
		present.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_READING_STATE

inherit
	TEST_SET_BASE

feature -- Tests

	test_a_verse_tells_only_the_verse
		local
			s: BIB_READING_STATE
		do
			s := recorded_state
			s.go_to (43, 3, 16)
			told.wipe_out
			s.go_to (43, 3, 17)
			assert_true ("only the verse: " + told, told.same_string ("verse history "))
		end

	test_a_chapter_tells_the_chapter_then_the_verse
		local
			s: BIB_READING_STATE
		do
			s := recorded_state
			s.go_to (43, 3, 16)
			told.wipe_out
			s.go_to (43, 4, 1)
			assert_true ("chapter first: " + told, told.same_string ("chapter verse history "))
		end

	test_a_version_tells_the_version_and_the_chapter
		local
			s: BIB_READING_STATE
		do
			s := recorded_state
			s.set_version ("KJV")
			s.go_to (43, 3, 16)
			told.wipe_out
			s.set_version ("BSB")
			s.set_version ("BSB")
			assert_true ("once, version first: " + told, told.same_string ("version chapter verse "))
		end

	test_the_trail_drops_the_steps_ahead
		local
			s: BIB_READING_STATE
		do
			create s.make
			s.go_to (1, 1, 1)
			s.go_to (19, 23, 1)
			s.go_to (43, 3, 16)
			s.step_history (-1)
			s.step_history (-1)
			assert_true ("back at the start", s.is_at (1, 1, 1) and not s.can_go_back and s.can_go_forward)
			s.go_to (45, 8, 28)
			assert_integers_equal ("the steps ahead dropped", 2, s.history_count)
			assert_false ("nothing ahead", s.can_go_forward)
			s.go_to (45, 8, 28)
			assert_integers_equal ("the place read is no new step", 2, s.history_count)
		end

	test_joining_tells_the_present
		local
			s: BIB_READING_STATE
		do
			create s.make
			create told.make_empty
			s.on_chapter (agent do told.append ("chapter ") end)
			s.on_verse (agent do told.append ("verse ") end)
			assert_true ("nothing read: nothing told: " + told, told.same_string (""))
			s.go_to (43, 3, 16)
			told.wipe_out
			s.on_verse (agent do told.append ("late ") end)
			assert_true ("a late listener told at once: " + told, told.same_string ("late "))
		end

feature {NONE} -- Recording

	told: STRING_8
			-- The events told, in order.
		attribute
			create Result.make_empty
		end

	recorded_state: BIB_READING_STATE
			-- A new state whose every event is written in `told'.
		do
			create Result.make
			create told.make_empty
			Result.version_changed.subscribe (agent (a_code: STRING_8) do told.append ("version ") end)
			Result.chapter_changed.subscribe (agent do told.append ("chapter ") end)
			Result.verse_changed.subscribe (agent do told.append ("verse ") end)
			Result.history_changed.subscribe (agent do told.append ("history ") end)
		end

end
