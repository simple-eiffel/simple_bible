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
			run_reading_tests
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

	run_reading_tests
			-- The place read (phase 3).
		local
			t: TEST_READING_STATE
		do
			print ("TEST_READING_STATE%N")
			create t
			run_test (agent t.test_a_verse_tells_only_the_verse, "test_a_verse_tells_only_the_verse")
			run_test (agent t.test_a_chapter_tells_the_chapter_then_the_verse, "test_a_chapter_tells_the_chapter_then_the_verse")
			run_test (agent t.test_a_version_tells_the_version_and_the_chapter, "test_a_version_tells_the_version_and_the_chapter")
			run_test (agent t.test_the_trail_drops_the_steps_ahead, "test_the_trail_drops_the_steps_ahead")
			run_test (agent t.test_joining_tells_the_present, "test_joining_tells_the_present")
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
			run_test (agent t.test_notes_dot_follows_adding_and_deleting, "test_notes_dot_follows_adding_and_deleting")
			run_test (agent t.test_answered_waits_for_a_chosen_prayer, "test_answered_waits_for_a_chosen_prayer")
			run_test (agent t.test_one_verse_reads_as_one, "test_one_verse_reads_as_one")
			run_test (agent t.test_a_verse_click_keeps_the_chapter, "test_a_verse_click_keeps_the_chapter")
			run_test (agent t.test_a_click_on_the_verse_read_adds_no_step, "test_a_click_on_the_verse_read_adds_no_step")
			run_test (agent t.test_back_and_forward_follow_the_trail, "test_back_and_forward_follow_the_trail")
			run_test (agent t.test_previous_and_next_stop_at_the_ends, "test_previous_and_next_stop_at_the_ends")
			run_test (agent t.test_this_session_lists_every_verse_touched, "test_this_session_lists_every_verse_touched")
			run_test (agent t.test_kept_history_lists_each_verse_once, "test_kept_history_lists_each_verse_once")
			run_test (agent t.test_kept_history_follows_its_limit, "test_kept_history_follows_its_limit")
			run_test (agent t.test_a_favorite_verse_wears_the_star, "test_a_favorite_verse_wears_the_star")
			run_test (agent t.test_a_range_in_a_new_folder, "test_a_range_in_a_new_folder")
			run_test (agent t.test_a_removed_folder_hides_its_stars_until_restored, "test_a_removed_folder_hides_its_stars_until_restored")
			run_test (agent t.test_a_whole_chapter_stars_the_chapter_not_its_verses, "test_a_whole_chapter_stars_the_chapter_not_its_verses")
			run_test (agent t.test_the_filter_finds_favorites_in_folders, "test_the_filter_finds_favorites_in_folders")
			run_test (agent t.test_a_framework_quotation_is_marked_and_found_again, "test_a_framework_quotation_is_marked_and_found_again")
			run_test (agent t.test_a_favorite_document_marks_its_title_and_its_row, "test_a_favorite_document_marks_its_title_and_its_row")
			run_test (agent t.test_a_book_quotation_names_its_block, "test_a_book_quotation_names_its_block")
			run_test (agent t.test_a_verse_quotation_stars_marks_and_opens, "test_a_verse_quotation_stars_marks_and_opens")
			run_test (agent t.test_a_long_highlight_reason_wraps_in_its_box, "test_a_long_highlight_reason_wraps_in_its_box")
			run_test (agent t.test_a_chosen_highlight_reads_in_full, "test_a_chosen_highlight_reads_in_full")
			run_test (agent t.test_memes_answer_the_verse_read, "test_memes_answer_the_verse_read")
			run_test (agent t.test_the_meme_search_finds_titles_and_words, "test_the_meme_search_finds_titles_and_words")
			run_test (agent t.test_a_favorite_meme_stays_at_the_top, "test_a_favorite_meme_stays_at_the_top")
			run_test (agent t.test_copy_a_memes_words_and_picture, "test_copy_a_memes_words_and_picture")
			run_test (agent t.test_a_memes_picture_loads_only_when_hovered, "test_a_memes_picture_loads_only_when_hovered")
			run_test (agent t.test_a_folder_copies_its_references, "test_a_folder_copies_its_references")
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
