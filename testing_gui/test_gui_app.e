note
	description: "[
		Test runner for Simple Bible's GUI state (research/23, phase 1,
		2026-10-31): state objects and their bindings, built without showing a
		window. Every suite inherits TEST_SET_BASE; a failure prints the
		exception's class and tag.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_GUI_APP

create
	make

feature {NONE} -- Initialization

	make
		do
			print ("Running Simple Bible GUI state tests (research/23)...%N%N")
			run_selection_tests
			run_layout_tests
			run_window_tests
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Suites

	run_selection_tests
			-- The Timeline and the Atlas's shared selection.
		local
			t: TEST_TIME_PLACE_SELECTION
		do
			print ("TEST_TIME_PLACE_SELECTION%N")
			create t
			run_test (agent t.test_year_told_once_per_change, "test_year_told_once_per_change")
			run_test (agent t.test_event_told_before_its_year, "test_event_told_before_its_year")
			run_test (agent t.test_a_late_listener_learns_the_present, "test_a_late_listener_learns_the_present")
		end

	run_layout_tests
			-- The layout and the look (phase 2).
		local
			t: TEST_LAYOUT_STATE
		do
			print ("TEST_LAYOUT_STATE%N")
			create t
			run_test (agent t.test_layout_told_once_per_change, "test_layout_told_once_per_change")
			run_test (agent t.test_joining_tells_the_present, "test_joining_tells_the_present")
			run_test (agent t.test_text_size_kept_to_a_tenth_in_range, "test_text_size_kept_to_a_tenth_in_range")
			run_test (agent t.test_a_new_layout_puts_the_river_away, "test_a_new_layout_puts_the_river_away")
		end

	run_window_tests
			-- The whole window, offscreen (needs LOCALAPPDATA naming a data folder).
		local
			t: TEST_WINDOW
		do
			print ("TEST_WINDOW%N")
			create t
			run_test (agent t.test_entering_study_fills_the_study_panes, "test_entering_study_fills_the_study_panes")
			run_test (agent t.test_size_buttons_follow_the_size, "test_size_buttons_follow_the_size")
			run_test (agent t.test_dark_switch_follows_windows, "test_dark_switch_follows_windows")
			run_test (agent t.test_each_workspace_keeps_its_east_width, "test_each_workspace_keeps_its_east_width")
			run_test (agent t.test_focus_button_says_what_it_will_do, "test_focus_button_says_what_it_will_do")
			run_test (agent t.test_verse_search_listed_in_the_window_menu, "test_verse_search_listed_in_the_window_menu")
			run_test (agent t.test_closed_results_stay_closed_across_layouts, "test_closed_results_stay_closed_across_layouts")
			run_test (agent t.test_close_in_study_clears_the_results, "test_close_in_study_clears_the_results")
			run_test (agent t.test_results_dot_follows_closing, "test_results_dot_follows_closing")
		end

feature {NONE} -- Runner

	passed, failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name)
			if attached (create {EXCEPTION_MANAGER}).last_exception as al_exception then
				print (" [" + al_exception.generating_type.name)
				if attached al_exception.description as al_description then
					print (": ")
					print (al_description)
				end
				print ("]")
			end
			print ("%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
