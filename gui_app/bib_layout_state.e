note
	description: "[
		The window's layout and look, one copy of each fact (research/23 phase 2,
		2026-10-31): Simple or Study, whether the Timeline's river workspace has
		the east zone, the text size, and light or dark. Each has one door that
		tells its listeners only on a real change, and joining tells a listener
		the present at once.

		Before this, "Study" lived in three places (a flag, the mode switch, the
		saved setting), the text size in four (the setting, two themes, two
		buttons) and "dark" in two (the switch and the window), each kept equal
		by hand; the size buttons were stale at start (risk 2) and following the
		Windows theme left the switch behind (risk 11).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LAYOUT_STATE

create
	make

feature {NONE} -- Initialization

	make (a_study: BOOLEAN; a_text_scale: REAL_64; a_dark: BOOLEAN)
		require
			scale_in_range: a_text_scale >= Min_text_scale and a_text_scale <= Max_text_scale
		do
			is_study := a_study
			text_scale := a_text_scale
			is_dark := a_dark
			create layout_changed.make
			create workspace_changed.make
			create text_scale_changed.make
			create theme_changed.make
		ensure
			kept: is_study = a_study and text_scale = a_text_scale and is_dark = a_dark
			no_workspace: not is_river_workspace
		end

feature -- Access

	is_study: BOOLEAN
			-- The Study layout (else Simple)?

	is_river_workspace: BOOLEAN
			-- Has the Atlas the east zone beside the Timeline tab?

	text_scale: REAL_64
			-- All the window's text, as a share of its normal size.

	is_dark: BOOLEAN
			-- The dark theme (else light)?

	Min_text_scale: REAL_64 = 0.8
	Max_text_scale: REAL_64 = 2.0

	can_grow_text: BOOLEAN
		do
			Result := text_scale < Max_text_scale
		end

	can_shrink_text: BOOLEAN
		do
			Result := text_scale > Min_text_scale
		end

feature -- Events

	layout_changed: SW_EVENT [TUPLE [study: BOOLEAN]]
	workspace_changed: SW_EVENT [TUPLE [river: BOOLEAN]]
	text_scale_changed: SW_EVENT [TUPLE [scale: REAL_64]]
	theme_changed: SW_EVENT [TUPLE [dark: BOOLEAN]]

feature -- Joining (subscribe, and be told the present)

	on_layout (a_action: PROCEDURE [BOOLEAN])
		do
			layout_changed.subscribe (a_action)
			a_action.call ([is_study])
		end

	on_workspace (a_action: PROCEDURE [BOOLEAN])
		do
			workspace_changed.subscribe (a_action)
			a_action.call ([is_river_workspace])
		end

	on_text_scale (a_action: PROCEDURE [REAL_64])
		do
			text_scale_changed.subscribe (a_action)
			a_action.call ([text_scale])
		end

	on_theme (a_action: PROCEDURE [BOOLEAN])
		do
			theme_changed.subscribe (a_action)
			a_action.call ([is_dark])
		end

feature -- Doors

	set_study (a_study: BOOLEAN)
			-- Study (or Simple); a new layout puts the river workspace away first.
		do
			if a_study /= is_study then
				set_river_workspace (False)
				is_study := a_study
				layout_changed.call ([a_study])
			end
		ensure
			set: is_study = a_study
		end

	toggle_study
		do
			set_study (not is_study)
		ensure
			flipped: is_study /= old is_study
		end

	set_river_workspace (a_on: BOOLEAN)
			-- The east zone to the Atlas (only in Study), or back to the lexicon and commentary.
		require
			study_for_the_river: a_on implies is_study
		do
			if a_on /= is_river_workspace then
				is_river_workspace := a_on
				workspace_changed.call ([a_on])
			end
		ensure
			set: is_river_workspace = a_on
		end

	set_text_scale (a_scale: REAL_64)
			-- `a_scale' to a tenth, kept inside Min_text_scale .. Max_text_scale.
		local
			l_scale: REAL_64
		do
			l_scale := ((a_scale * 10.0).rounded / 10.0).max (Min_text_scale).min (Max_text_scale)
			if l_scale /= text_scale then
				text_scale := l_scale
				text_scale_changed.call ([l_scale])
			end
		ensure
			in_range: text_scale >= Min_text_scale and text_scale <= Max_text_scale
		end

	step_text_scale (a_step: INTEGER)
			-- A tenth larger (1) or smaller (-1).
		do
			set_text_scale (text_scale + 0.1 * a_step)
		end

	set_dark (a_dark: BOOLEAN)
		do
			if a_dark /= is_dark then
				is_dark := a_dark
				theme_changed.call ([a_dark])
			end
		ensure
			set: is_dark = a_dark
		end

invariant
	river_only_in_study: is_river_workspace implies is_study
	scale_in_range: text_scale >= Min_text_scale and text_scale <= Max_text_scale

end
