note
	description: "[
		The reader's own choices, kept between runs in a small text file of
		key=value lines (settings.txt in %LOCALAPPDATA%\simple_bible): for now
		the text size of the whole window (Larry, 2026-10-26: A+ and A- should
		size all the text, menus too, and the window should open at that size
		next time). A missing, unreadable or odd file gives the defaults.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SETTINGS

create
	make,
	make_at

feature {NONE} -- Initialization

	make
			-- Settings kept in the reader's own data folder.
		do
			make_at ((create {BIB_DATA_LOCATION}).settings_path)
		end

	make_at (a_path: READABLE_STRING_GENERAL)
			-- Settings kept in `a_path', at their defaults until `load'.
		require
			path_not_empty: not a_path.is_empty
		do
			path := a_path.to_string_32
			text_scale := 1.0
		ensure
			path_set: path.same_string_general (a_path)
			default_scale: text_scale = 1.0
		end

feature -- Access

	path: STRING_32
			-- The settings file.

	text_scale: REAL_64
			-- How large all the window's text is (1.0: as designed).

	is_study_layout: BOOLEAN
			-- Does the window open in the Study layout (C7)?

feature -- Element change

	set_text_scale (a_scale: REAL_64)
			-- Keep `a_scale' as the text size.
		require
			in_range: a_scale >= Min_text_scale and a_scale <= Max_text_scale
		do
			text_scale := a_scale
		ensure
			set: text_scale = a_scale
		end

	set_study_layout (a_study: BOOLEAN)
			-- Keep the layout the window opens in.
		do
			is_study_layout := a_study
		ensure
			set: is_study_layout = a_study
		end

feature -- Storage

	load
			-- Read the file; a missing file, an unknown key or a value out of range keeps the default.
		local
			l_file: SIMPLE_FILE
			l_line, l_value: STRING_32
			l_equals: INTEGER
		do
			create l_file.make (path)
			if l_file.is_file then
				across l_file.read_text.split ('%N') as ic loop
					l_line := ic.twin
					l_line.left_adjust
					l_line.right_adjust
					l_equals := l_line.index_of ('=', 1)
					if l_equals > 1 and then l_line.substring (1, l_equals - 1).same_string ("text_scale") then
						l_value := l_line.substring (l_equals + 1, l_line.count)
						if l_value.is_double and then l_value.to_double >= Min_text_scale and then l_value.to_double <= Max_text_scale then
							text_scale := l_value.to_double
						end
					elseif l_equals > 1 and then l_line.substring (1, l_equals - 1).same_string ("layout") then
						is_study_layout := l_line.substring (l_equals + 1, l_line.count).same_string ("study")
					end
				end
			end
		ensure
			in_range: text_scale >= Min_text_scale and text_scale <= Max_text_scale
		end

	save: BOOLEAN
			-- Write the file, making its folder when it is missing. Did it work?
		local
			l_file, l_folder: SIMPLE_FILE
			l_made: BOOLEAN
		do
			create l_file.make (path)
			if not l_file.parent_path.is_empty then
				create l_folder.make (l_file.parent_path)
				if not l_folder.exists then
					l_made := l_folder.create_directory_recursive
				end
			end
			Result := l_file.write_text ({STRING_32} "text_scale=" + scale_text + {STRING_32} "%Nlayout=" + layout_name + {STRING_32} "%N")
		end

feature {NONE} -- Implementation

	scale_text: STRING_32
			-- `text_scale' with two decimals ("1.6" is written "1.60", never "1.6000000000000001").
		local
			l_hundredths: INTEGER
		do
			l_hundredths := (text_scale * 100.0).rounded
			Result := (l_hundredths // 100).out.to_string_32 + {STRING_32} "."
			if l_hundredths \\ 100 < 10 then
				Result.append_character ('0')
			end
			Result.append ((l_hundredths \\ 100).out)
		ensure
			two_decimals: Result.count >= 4
		end

	layout_name: STRING_32
			-- "study" or "simple".
		do
			if is_study_layout then
				Result := {STRING_32} "study"
			else
				Result := {STRING_32} "simple"
			end
		end

feature -- Constants

	Min_text_scale: REAL_64 = 0.8
	Max_text_scale: REAL_64 = 2.0
			-- The text sizes A- and A+ step between.

invariant
	path_not_empty: not path.is_empty
	scale_in_range: text_scale >= Min_text_scale and text_scale <= Max_text_scale

end
