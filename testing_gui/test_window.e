note
	description: "[
		The whole Simple Bible window, built offscreen by BIB_GUI_APP.make_harness
		and driven as a reader would (research/23, 2026-10-31). Run with
		LOCALAPPDATA naming a data folder (the snapshots' scratch copy). Each test
		builds its own window and shuts it down.

		Phase 2's window risks, pinned after their fix (the harness came after
		phase 2; from phase 3 on each risk's test is written and seen failing
		first): entering Study fills the Study panes (1); the size buttons follow
		the size (2); the dark switch follows a Windows theme swap (11); each
		workspace keeps its own east width (13); the Focus button says what a
		press will do (18).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_WINDOW

inherit
	TEST_SET_BASE

	BIB_WINDOW_HARNESS_CLIENT
			-- BIB_GUI_APP exports its harness features to it, selectively
		undefine
			default_create
		end

feature -- Phase 2

	test_entering_study_fills_the_study_panes
		local
			app: BIB_GUI_APP
		do
			create app.make_harness
			app.harness_state.set_study (False)
			app.harness_go_to (43, 3, 16)
			app.harness_state.set_study (True)
			assert_true ("the Notes pane speaks of John 3: " + app.harness_notes_heading.to_string_8, app.harness_notes_heading.has_substring ("John 3"))
			app.shut_down
		end

	test_size_buttons_follow_the_size
		local
			app: BIB_GUI_APP
		do
			create app.make_harness
			app.harness_state.set_text_scale (2.0)
			assert_false ("at the largest, Larger is off", app.harness_larger_enabled)
			assert_true ("and Smaller on", app.harness_smaller_enabled)
			app.harness_state.set_text_scale (0.8)
			assert_false ("at the smallest, Smaller is off", app.harness_smaller_enabled)
			app.harness_state.set_text_scale (1.0)
			app.shut_down
		end

	test_dark_switch_follows_windows
		local
			app: BIB_GUI_APP
			l_dark: BOOLEAN
		do
			create app.make_harness
			l_dark := not app.harness_window_dark
			app.harness_theme_swapped_by_windows (l_dark)
			assert_true ("the window wears it", app.harness_window_dark = l_dark)
			assert_true ("and the switch shows it", app.harness_dark_switch_on = l_dark)
			app.shut_down
		end

	test_each_workspace_keeps_its_east_width
		local
			app: BIB_GUI_APP
			l_reading: REAL_64
		do
			create app.make_harness
			app.harness_state.set_study (True)
			app.harness_set_east_fraction (0.25)
			l_reading := app.harness_east_fraction
			app.harness_show_timeline
			app.harness_set_east_fraction (0.5)
			app.harness_select_tab (1)
			assert_reals_equal ("back to the Bible: the reading width the reader had", l_reading, app.harness_east_fraction, 0.001)
			app.harness_show_timeline
			assert_reals_equal ("back to the river: its own width", 0.5, app.harness_east_fraction, 0.001)
			app.shut_down
		end

	test_focus_button_says_what_it_will_do
		local
			app: BIB_GUI_APP
		do
			create app.make_harness
			app.harness_state.set_study (True)
			assert_strings_equal ("before: Focus", "Focus", app.harness_focus_label)
			app.harness_toggle_focus
			assert_strings_equal ("focused: Sides back", "Sides back", app.harness_focus_label)
			app.harness_toggle_focus
			assert_strings_equal ("and back", "Focus", app.harness_focus_label)
			app.shut_down
		end

end
