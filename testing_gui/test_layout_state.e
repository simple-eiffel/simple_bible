note
	description: "[
		BIB_LAYOUT_STATE (research/23 phase 2, 2026-10-31): each fact told once
		per real change; joining tells the present (the size buttons were stale
		at start, risk 2); the text size kept to a tenth inside its range with
		its two "can" queries; a new layout puts the river workspace away.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_LAYOUT_STATE

inherit
	TEST_SET_BASE

feature -- Tests

	test_layout_told_once_per_change
		local
			s: BIB_LAYOUT_STATE
		do
			create s.make (False, 1.0, False)
			told := 0
			s.layout_changed.subscribe (agent (a_study: BOOLEAN) do told := told + 1 end)
			s.set_study (True)
			s.set_study (True)
			s.toggle_study
			assert_integers_equal ("two real changes", 2, told)
			assert_false ("back to Simple", s.is_study)
		end

	test_joining_tells_the_present
			-- A listener joining late learns every fact at once (the size buttons, set only when the
			-- size changed, were stale at start: risk 2).
		local
			s: BIB_LAYOUT_STATE
		do
			create s.make (True, 2.0, True)
			told := 0
			s.on_text_scale (agent (a_scale: REAL_64) do told := told + 1; last_scale := a_scale end)
			assert_integers_equal ("told on joining", 1, told)
			assert_reals_equal ("the size now", 2.0, last_scale, 0.0001)
			assert_false ("at the largest the larger button is off", s.can_grow_text)
			assert_true ("and the smaller on", s.can_shrink_text)
			told := 0
			s.on_layout (agent (a_study: BOOLEAN) do if a_study then told := told + 1 end end)
			s.on_theme (agent (a_dark: BOOLEAN) do if a_dark then told := told + 1 end end)
			assert_integers_equal ("layout and theme told on joining", 2, told)
		end

	test_text_size_kept_to_a_tenth_in_range
		local
			s: BIB_LAYOUT_STATE
		do
			create s.make (False, 1.0, False)
			told := 0
			s.text_scale_changed.subscribe (agent (a_scale: REAL_64) do told := told + 1 end)
			s.step_text_scale (1)
			assert_reals_equal ("a tenth larger", 1.1, s.text_scale, 0.0001)
			s.set_text_scale (5.0)
			assert_reals_equal ("kept to the largest", 2.0, s.text_scale, 0.0001)
			s.step_text_scale (1)
			assert_integers_equal ("a step past the largest is no change", 2, told)
			s.set_text_scale (0.1)
			assert_reals_equal ("kept to the smallest", 0.8, s.text_scale, 0.0001)
		end

	test_a_new_layout_puts_the_river_away
		local
			s: BIB_LAYOUT_STATE
		do
			create s.make (True, 1.0, False)
			s.set_river_workspace (True)
			told := 0
			s.workspace_changed.subscribe (agent (a_river: BOOLEAN) do if not a_river then told := told + 1 end end)
			s.set_study (False)
			assert_false ("the river put away", s.is_river_workspace)
			assert_integers_equal ("and told", 1, told)
		end

feature {NONE} -- Recording

	told: INTEGER
	last_scale: REAL_64

end
