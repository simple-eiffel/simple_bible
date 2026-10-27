note
	description: "[
		bible_gui: the simple_bible main window in the GUI guide's Simple layout
		("simple_bible GUI Mockups", Main window - Simple layout, board codes in
		the design pills): the title bar names the chapter and version (C1); the
		menu bar (C2); the toolbar with Back and Forward (C3), the reference box
		(C4), the version picker (C5), the search box (C6), the Simple | Study
		switch (C7), text size (C8) and Dark (C9); a dock host (C16) with the
		Bible text in the centre (S1, P01), the commentary east (S2, P04: its
		Cross-refs tab is live), the dictionary and lexicon south (S3, P05:
		renderings, lexicon entries, every place) and search results west (P07,
		only while there are results); and a status bar of sections (C11-C15).

		Lookups run on the window's thread (3 to 190 milliseconds on the real
		data). The every-place list streams in on the window's tick, a few pages
		at a time, so 88,444 rows never freeze it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GUI_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Open the engine, build the window, run it, close the engine.
		local
			l_config: BIB_CONFIG
			l_location: BIB_DATA_LOCATION
		do
			create l_location
			create l_config.make_with_core (l_location.content_path)
			l_config := l_config.set_conc_path (l_location.conc_path)
			l_config := l_config.set_pack_folder (l_location.pack_folder)
			create bible.make (l_config)
			bible.open
			create settings.make
			settings.load
			read_snapshot_arguments
			if is_snapshot then
					-- A snapshot never touches the reader's notes: its own user.db, emptied first.
				fresh_snapshot_user_file
				create user_store.make (snapshot_user_path)
			else
				create user_store.make ((create {BIB_DATA_LOCATION}).user_path)
			end
			user_store.open
			create note_store.make (user_store)
			create note_rows.make (0)
			create notes_list.make (60.0)
			create notes_heading.make_ui ("")
			create new_note_label.make_ui ("")
			create new_note_box.make ("")
			create add_note_button.make ("Add note", Void)
			create delete_note_button.make ("Delete", Void)
			create restore_note_button.make ("Restore", Void)
			create light_theme.make_light
			create dark_theme.make_dark
				-- The text size the reader chose last time, for all the window's text (C8).
			light_theme.set_text_scale (settings.text_scale)
			dark_theme.set_text_scale (settings.text_scale)
			create window.make ("simple_bible", window_x, window_y, window_width, window_height, light_theme)
			window.follow_system_theme (light_theme, dark_theme)
			window.enable_shaped_text
				-- Every attached attribute before any agent on Current (VEVI). Grid heights are minimums
				-- (a column never shrinks a child below its preferred height); small minimums grow to fill.
			create menu_bar.make
			create back_button.make ("<", Void)
			create forward_button.make (">", Void)
			create reference_box.make_lookup
			create version_select.make
			create search_box.make_lookup
			create mode_switch.make
			create smaller_button.make ("A-", Void)
			create larger_button.make ("A+", Void)
			create dark_switch.make ("Dark", False, Void)
			create reading_caption.make_ui ("BIBLE TEXT")
			create reading_title.make ("", {SW_PAINTER}.Role_ui, 14.0, True)
			create version_chip.make_ui ("")
			create reading_note.make_ui ("")
			reading_note := reading_note.with_wrap
			create previous_button.make ("< Previous", Void)
			create next_button.make ("Next >", Void)
			create reading_view.make (120.0)
			create reading_verses.make (0)
			create reading_version.make_empty
			create commentary_title.make ("", {SW_PAINTER}.Role_ui, 13.0, True)
			create commentary_tabs.make
			create commentary_view.make (200.0)
			create commentary_reader.make
			create cross_refs_grid.make (60.0)
			create cross_refs.make (0)
			create lexicon_heading.make ("", {SW_PAINTER}.Role_ui, 20.0, True)
			create lexicon_subtitle.make_ui ("")
			create lexicon_chip.make_ui ("")
			create search_word_button.make ("Search this word", Void)
			create word_study_button.make ("Word Study", Void)
			create lexicon_tabs.make
			create renderings_title.make_ui ("How the Bibles render it")
			create renderings_grid.make (60.0)
			create entries_title.make_ui ("Lexicon entries")
			create entries_list.make (60.0)
			create places_title.make_ui ("Every place")
			create places_grid.make (60.0)
			create results_note.make_ui ("")
			results_note := results_note.with_wrap
			create results_grid.make (60.0)
			create close_results_button.make ("Close", Void)
			create status_bar.make
			create numbering_label.make_ui ("")
			create link_label.make_ui ("Link A")
			create progress.make (0.0)
			create editions_label.make_ui ("")
			create choices.make (0)
			create renderings.make (0)
			create places.make (0)
			create study_corpus.make_empty
			create history.make (40)
			create center_holder.make
			create center_tabs.make
			create bible_page.make
			create parallel_view.make (200.0)
			create interlinear_view.make (200.0)
			create interlinear_note.make_ui ("")
			create interlinear_words.make (0)
			create analysis_title.make_ui ("")
			create analysis_grid.make (140.0)
			create analysis_rows.make (0)
			create analysis_uses.make (32)
			create results_holder.make
			create results_tabs.make
			create results_page.make
			create tools_holder.make
			create tools_strip.make
			create navigator_tree.make (80.0)
			reading_column := reading_pane.growing
			results_column := results_pane.growing
			center_tabs := center_tabs.growing
			results_tabs := results_tabs.growing
			create dock.make (center_holder)
			build_columns
			fill_versions
			mode_switch.add_segment ("Simple")
			mode_switch.add_segment ("Study")
			window.set_root (layout)
			add_menus
			add_accelerators
			wire_events
			show_start
			arrange (settings.is_study_layout)
				-- Genesis 1:1 selected, so the commentary has its cross-references from the start (Larry:
				-- T5 was empty until a verse was clicked).
			if bible.is_open and then not reading_version.is_empty and then bible.books.has_book (1) then
				go_to (1, 1, 1)
			end
			show_no_word
			dark_switch.set_on (window.theme.is_dark)
				-- Typing goes straight into the reference box (keys typed before a click were lost once).
			window.give_focus (reference_box)
			if is_snapshot then
				take_snapshot
			else
				window.run
			end
			if user_store.is_open then
				user_store.close
			end
			if bible.is_open then
				bible.close
			end
		end

feature {NONE} -- Snapshot (a picture of the window without a screen)

	is_snapshot: BOOLEAN
			-- Was the program started as `bible_gui --snapshot <png> <place> [tab]'? It then builds the
			-- window, goes to <place> in Study, opens <tab> (interlinear, parallel, commentary or notes:
			-- notes adds a sample note), writes the whole window to <png> and exits: no event loop, no
			-- settings saved, a user.db of its own. For checking a build when no screen can be captured
			-- (2026-10-27: the display was unavailable while Larry was away).

	snapshot_path, snapshot_place, snapshot_tab: STRING_32
			-- The snapshot's picture file, place and tab.
		attribute
			create Result.make_empty
		end

	read_snapshot_arguments
			-- `is_snapshot' and its arguments from the command line.
		local
			l_arguments: ARGUMENTS_32
		do
			create l_arguments
			if l_arguments.argument_count >= 3 and then l_arguments.argument (1).same_string ({STRING_32} "--snapshot") then
				is_snapshot := True
				snapshot_path := l_arguments.argument (2).to_string_32
				snapshot_place := l_arguments.argument (3).to_string_32
				if l_arguments.argument_count >= 4 then
					snapshot_tab := l_arguments.argument (4).to_string_32.as_lower
				end
			end
		end

	snapshot_user_path: STRING_32
			-- The snapshot's own user.db, in the temporary folder.
		do
			if attached (create {SIMPLE_ENV}).item ("TEMP") as al_temp then
				Result := al_temp.to_string_32 + {STRING_32} "\simple_bible_snapshot_user.db"
			else
				Result := {STRING_32} "simple_bible_snapshot_user.db"
			end
		end

	fresh_snapshot_user_file
			-- No user.db left from an earlier snapshot.
		local
			l_file: SIMPLE_FILE
			l_ok: BOOLEAN
		do
			create l_file.make (snapshot_user_path)
			if l_file.exists then
				l_ok := l_file.delete
			end
		end

	take_snapshot
			-- Go to `snapshot_place' in Study, open `snapshot_tab', draw the window into `snapshot_path'.
		local
			l_lookup: BIB_LOOKUP
			l_written: BOOLEAN
		do
			if bible.is_open then
				create l_lookup.make (bible)
				if attached l_lookup.place_named (snapshot_place) as al_place then
					go_to (al_place.book, al_place.chapter, al_place.verse)
				end
			end
			if not is_study then
				arrange (True)
			end
			if snapshot_tab.same_string ({STRING_32} "interlinear") then
				show_interlinear
			elseif snapshot_tab.same_string ({STRING_32} "parallel") then
				show_parallel
			elseif snapshot_tab.same_string ({STRING_32} "commentary") then
				commentary_tabs.select_tab (1)
			elseif snapshot_tab.same_string ({STRING_32} "notes") then
				new_note_box.set_text ("A sample note written by the snapshot run.")
				add_note
			end
			window.request_render
				-- The whole frame as drawn (the offscreen picture `render' made).
			l_written := window.write_frame (snapshot_path)
			if not l_written then
				l_written := (create {SIMPLE_FILE}.make (snapshot_path + {STRING_32} ".txt")).write_text ({STRING_32} "no frame written; root "
					+ layout.width.out + {STRING_32} " x " + layout.height.out)
				l_written := False
			end
			if not l_written then
				(create {EXCEPTIONS}).die (1)
			end
		end

	window_width: INTEGER
			-- The window opens at most of the main screen (Larry, 2026-10-26: "much larger"):
			-- 92 percent of its work area, or 1440 when the screen gives none.
		do
			Result := ((create {SW_SCREEN}).work_area_width * Window_share).rounded
			if Result < 800 then
				Result := 1440
			end
		end

	window_height: INTEGER
			-- 92 percent of the work area's height, or 920.
		do
			Result := ((create {SW_SCREEN}).work_area_height * Window_share).rounded
			if Result < 600 then
				Result := 920
			end
		end

	window_x: INTEGER
			-- Centred on the work area.
		do
			Result := (create {SW_SCREEN}).work_area_x + (((create {SW_SCREEN}).work_area_width - window_width) // 2).max (0)
		end

	window_y: INTEGER
		do
			Result := (create {SW_SCREEN}).work_area_y + (((create {SW_SCREEN}).work_area_height - window_height) // 2).max (0)
		end

	Window_share: REAL_64 = 0.92
			-- How much of the screen the window opens on.

	wire_events
			-- Every control's action.
		do
			back_button.set_on_click (agent move_in_history (-1))
			forward_button.set_on_click (agent move_in_history (1))
			reference_box.set_on_enter (agent on_reference)
			search_box.set_on_enter (agent on_search)
			version_select.set_on_change (agent on_version_change)
			mode_switch.set_on_change (agent on_mode)
			smaller_button.set_on_click (agent change_text_size (-1))
			larger_button.set_on_click (agent change_text_size (1))
			dark_switch.set_on_change (agent on_dark)
			previous_button.set_on_click (agent step_chapter (-1))
			next_button.set_on_click (agent step_chapter (1))
			reading_view.set_on_cell_click (agent on_verse_click)
			parallel_view.set_on_cell_click (agent on_parallel_click)
			interlinear_view.set_on_token_select (agent on_interlinear_word)
			analysis_grid.set_on_select (agent on_analysis_row)
			notes_list.set_gutter_renderer (agent draw_note_gutter)
			notes_list.set_on_activate (agent edit_note)
			notes_list.set_on_edit_commit (agent on_note_edited)
			notes_list.set_on_select (agent on_note_selected)
			add_note_button.set_on_click (agent add_note)
			delete_note_button.set_on_click (agent delete_note)
			restore_note_button.set_on_click (agent restore_note)
			cross_refs_grid.set_on_select (agent on_cross_ref)
			search_word_button.set_on_click (agent show_every_place)
			results_grid.set_on_select (agent on_choice)
			close_results_button.set_on_click (agent hide_results)
			places_grid.set_on_select (agent on_place)
			window.set_on_tick (agent load_more_places)
		end

feature {NONE} -- Window

	window: SW_WINDOW
	light_theme, dark_theme: SW_THEME
	menu_bar: SW_MENU_BAR
	back_button, forward_button: SW_BUTTON
	reference_box, search_box: BIB_LOOKUP_BOX
	version_select: SW_SELECT
	mode_switch: SW_SEGMENTED
	smaller_button, larger_button: SW_BUTTON
	dark_switch: SW_SWITCH
	dock: SW_DOCK_HOST
	results_panel, commentary_panel, lexicon_panel: INTEGER
			-- The dock's panels (C16): P07 west, P04 east, P05 south.
	status_bar: SW_STATUS_BAR
	numbering_label, link_label, editions_label: SW_LABEL
	progress: SW_PROGRESS

	bible: SIMPLE_BIBLE
			-- The engine, opened before the window so its title can name the edition.

	layout: SW_COLUMN
			-- Menu bar, toolbar, the dock host, status bar.
		local
			l_toolbar: SW_ROW
			l_spacer: SW_SPACER
		do
			create l_toolbar.make
			l_toolbar := l_toolbar.with_gap (8.0)
			l_toolbar.put (back_button)
			l_toolbar.put (forward_button)
			l_toolbar.put (reference_box.growing)
			l_toolbar.put (version_select)
			l_toolbar.put (search_box.growing)
			create l_spacer.make_weighted (0.2)
			l_toolbar.put (l_spacer)
			l_toolbar.put (mode_switch)
			l_toolbar.put (smaller_button)
			l_toolbar.put (larger_button)
			l_toolbar.put (dark_switch)

				-- One set of panels for both layouts: `arrange' moves them between zones (C7).
			results_panel := dock.add_panel ("SEARCH RESULTS", results_holder, dock.Zone_west)
			lexicon_panel := dock.add_panel ("DICTIONARY AND LEXICON", lexicon_pane, dock.Zone_south)
			commentary_panel := dock.add_panel ("COMMENTARY", commentary_pane, dock.Zone_east)
			navigator_panel := dock.add_panel ("NAVIGATOR", navigator_pane, dock.Zone_west)
			notes_panel := dock.add_panel ("NOTES", notes_pane, dock.Zone_west)
			build_study_parts

			status_bar.set_left ("")
			status_bar.add_widget (link_label, 70.0, False).do_nothing
			status_bar.add_widget (numbering_label, 170.0, False).do_nothing
			status_bar.add_widget (progress, 140.0, False).do_nothing
			status_bar.add_widget (editions_label, 460.0, True).do_nothing

			create Result.make
			Result := Result.with_padding (10.0).with_gap (8.0)
			Result.put (menu_bar)
			Result.put (l_toolbar)
				-- C10 sits on its own row under the toolbar in Study, so a large text size never
				-- squeezes it out (seen at 160 percent); empty in Simple.
			Result.put (tools_holder)
			Result.put (dock.growing)
			Result.put (status_bar)
		end

	reading_pane: SW_COLUMN
			-- S1, P01 Bible Text: its header, a note, and the chapter verse by verse.
		local
			l_bar: SW_ROW
		do
			create l_bar.make
			l_bar := l_bar.with_gap (10.0)
			l_bar.put (reading_caption.as_muted)
			l_bar.put (reading_title)
			l_bar.put (version_chip.as_muted.growing)
			l_bar.put (previous_button)
			l_bar.put (next_button)
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (l_bar)
			Result.put (reading_note.as_muted)
			Result.put (reading_view.growing)
		end

	commentary_pane: SW_COLUMN
			-- S2, P04 Commentary: Commentaries, Cross-refs (live) and Related.
		do
			commentary_tabs.add_page ("Commentaries", commentary_view)
			commentary_tabs.add_page ("Cross-refs", cross_refs_grid)
			commentary_tabs.add_page ("Related", create {SW_EMPTY_STATE}.make ("Related passages come later",
				"AI-made related passages are planned for a later release, always marked as AI-made."))
				-- Larry's commentary first when a pack holds one (2026-10-27), else the cross-references.
			if bible.is_open and then not bible.commentary_packs.is_empty then
				commentary_tabs.select_tab (1)
			else
				commentary_tabs.select_tab (2)
			end
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (commentary_title)
			Result.put (commentary_tabs.growing)
		end

	lexicon_pane: SW_COLUMN
			-- S3, P05 Dictionary and Lexicon: the word's heading and actions; Word (renderings and
			-- lexicon entries), Every place, Compare and Bible Dictionaries.
		local
			l_head: SW_ROW
			l_renderings, l_entries, l_places: SW_COLUMN
			l_word: SW_SPLITTER
		do
			create l_head.make
			l_head := l_head.with_gap (10.0)
			l_head.put (lexicon_heading)
			l_head.put (lexicon_subtitle.growing)
			l_head.put (lexicon_chip.as_muted)
			l_head.put (search_word_button)
			l_head.put (word_study_button)
			word_study_button.set_enabled (False)

			create l_renderings.make
			l_renderings := l_renderings.with_gap (6.0)
			l_renderings.put (renderings_title.as_muted)
			l_renderings.put (renderings_grid.growing)
			create l_entries.make
			l_entries := l_entries.with_gap (6.0)
			l_entries.put (entries_title.as_muted)
			l_entries.put (entries_list.growing)
			create l_word.make (l_renderings, l_entries)
			l_word.set_ratio (0.52)

			create l_places.make
			l_places := l_places.with_gap (6.0)
			l_places.put (places_title.as_muted)
			l_places.put (places_grid.growing)

			lexicon_tabs.add_page ("Word", l_word)
			lexicon_tabs.add_page ("Every place", l_places)
			lexicon_tabs.add_page ("Compare", create {SW_EMPTY_STATE}.make ("Compare comes later",
				"Two to four lexicon entries side by side (P05.6) is planned."))
			lexicon_tabs.add_page ("Bible Dictionaries", create {SW_EMPTY_STATE}.make ("No Bible dictionaries yet",
				"Easton, Smith, ISBE and Hitchcock come with the content pipeline."))

			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (l_head)
			Result.put (lexicon_tabs.growing)
		end

	results_pane: SW_COLUMN
			-- P07 Search results, docked west only while there are results.
		local
			l_head: SW_ROW
		do
			create l_head.make
			l_head := l_head.with_gap (8.0)
			l_head.put (results_note.growing)
			l_head.put (close_results_button)
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (l_head)
			Result.put (results_grid.growing)
		end

	build_columns
			-- The grids' columns and the reading view's one column.
		do
			results_grid.add_column (create {SW_GRID_COLUMN [BIB_LOOKUP_CHOICE]}.make ("Word", 150.0, agent {BIB_LOOKUP_CHOICE}.label))
			results_grid.add_column ((create {SW_GRID_COLUMN [BIB_LOOKUP_CHOICE]}.make ("Details", 200.0, agent {BIB_LOOKUP_CHOICE}.detail)).growing)
			cross_refs_grid.add_column ((create {SW_GRID_COLUMN [BIB_READING_CROSS_REF]}.make ("Reference", 180.0, agent cross_ref_text)).growing)
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("#", 40.0, agent analysis_position))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Word", 130.0, agent {BIB_INTERLINEAR_WORD}.surface))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Transliteration", 130.0, agent {BIB_INTERLINEAR_WORD}.translit))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Gloss", 150.0, agent {BIB_INTERLINEAR_WORD}.gloss))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Lemma", 130.0, agent {BIB_INTERLINEAR_WORD}.lemma_text))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Strong's", 120.0, agent {BIB_INTERLINEAR_WORD}.strongs))
			analysis_grid.add_column ((create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Morphology", 260.0, agent {BIB_INTERLINEAR_WORD}.morphology)).growing)
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Uses", 70.0, agent analysis_uses_text))
			cross_refs_grid.add_column (create {SW_GRID_COLUMN [BIB_READING_CROSS_REF]}.make ("Votes", 70.0, agent votes_text))
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Rendering", 150.0, agent {BIB_ENGLISH_GLANCE_ROW}.english))
			renderings_grid.add_column ((create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Version", 200.0, agent version_name)).growing)
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Count", 70.0, agent count_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Place", 150.0, agent {BIB_PLACE_ROW}.reference_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Word", 150.0, agent {BIB_PLACE_ROW}.surface))
			places_grid.add_column ((create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Transliteration", 160.0, agent {BIB_PLACE_ROW}.translit)).growing)
			reading_view.add_column ("").do_nothing
		end

feature {NONE} -- Menus and keys (C2)

	add_menus
			-- The guide's nine menus; what is not built yet is listed greyed, so the menus show the plan.
		do
			menu_bar.add_menu ("&File", agent file_menu)
			menu_bar.add_menu ("&Edit", agent edit_menu)
			menu_bar.add_menu ("&View", agent view_menu)
			menu_bar.add_menu ("&Go", agent go_menu)
			menu_bar.add_menu ("&Search", agent search_menu)
			menu_bar.add_menu ("S&tudy", agent study_menu)
			menu_bar.add_menu ("T&ools", agent tools_menu)
			menu_bar.add_menu ("&Window", agent window_menu)
			menu_bar.add_menu ("&Help", agent help_menu)
			window.set_menu_bar (menu_bar)
		end

	add_accelerators
			-- Keys that work wherever the focus is.
		do
			window.register_accelerator (Key_p, True, False, True, agent toggle_pills)
			window.register_accelerator (Key_left, False, True, False, agent move_in_history (-1))
			window.register_accelerator (Key_right, False, True, False, agent move_in_history (1))
			window.register_accelerator (Key_l, True, False, False, agent focus_reference)
			window.register_accelerator (Key_f, True, False, False, agent focus_search)
			window.register_accelerator (Key_plus, True, False, False, agent change_text_size (1))
			window.register_accelerator (Key_minus, True, False, False, agent change_text_size (-1))
			window.register_accelerator (Key_m, True, False, False, agent toggle_mode)
			window.register_accelerator (Key_i, True, False, False, agent show_interlinear)
		end

	file_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Export...", "", False, Void)
			Result.add_item ("Print...", "", False, Void)
			Result.add_separator
			Result.add_item ("Exit", "Alt+F4", True, agent window.close)
		end

	edit_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Copy verse", "", reading_verse > 0, agent copy_verse)
			Result.add_item ("Find in chapter...", "", False, Void)
		end

	view_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Simple layout", "Ctrl+M", is_study, agent arrange (False))
			Result.add_item ("Study layout", "Ctrl+M", not is_study, agent arrange (True))
			Result.add_separator
			Result.add_item ("Larger text", "Ctrl++", settings.text_scale < settings.Max_text_scale, agent change_text_size (1))
			Result.add_item ("Smaller text", "Ctrl+-", settings.text_scale > settings.Min_text_scale, agent change_text_size (-1))
			if window.theme.is_dark then
				Result.add_item ("Light theme", "", True, agent set_dark (False))
			else
				Result.add_item ("Dark theme", "", True, agent set_dark (True))
			end
			Result.add_separator
			if window.reference_marks_shown then
				Result.add_item ("Hide design pills", "Ctrl+Shift+P", True, agent toggle_pills)
			else
				Result.add_item ("Show design pills", "Ctrl+Shift+P", True, agent toggle_pills)
			end
		end

	go_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Back", "Alt+Left", history_index > 1, agent move_in_history (-1))
			Result.add_item ("Forward", "Alt+Right", history_index < history.count, agent move_in_history (1))
			Result.add_separator
			Result.add_item ("Previous chapter", "", previous_button.is_enabled, agent step_chapter (-1))
			Result.add_item ("Next chapter", "", next_button.is_enabled, agent step_chapter (1))
			Result.add_item ("Go to reference", "Ctrl+L", True, agent focus_reference)
		end

	search_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Search the Bible", "Ctrl+F", True, agent focus_search)
			Result.add_item ("Every place of this word", "", study_lemma > 0, agent show_every_place)
			Result.add_item ("Advanced search...", "", False, Void)
		end

	study_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Word Study", "", False, Void)
			Result.add_item ("Parallel", "", True, agent show_parallel)
			Result.add_item ("Interlinear", "Ctrl+I", True, agent show_interlinear)
			Result.add_item ("Guide", "", False, Void)
		end

	tools_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Count and census", "", False, Void)
			Result.add_item ("Settings", "", False, Void)
		end

	window_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Search results", "", not choices.is_empty, agent show_results)
			Result.add_item ("Commentary", "", True, agent dock.show_panel (commentary_panel))
			Result.add_item ("Dictionary and lexicon", "", True, agent dock.show_panel (lexicon_panel))
		end

	help_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Keyboard shortcuts", "", True, agent show_shortcuts)
			Result.add_item ("About simple_bible", "", True, agent show_about)
		end

	show_shortcuts
			-- The keys, as a toast.
		do
			window.toast ("Ctrl+L reference   Ctrl+F search   Alt+Left/Right back, forward   Ctrl+ +/- text size   Ctrl+Shift+P pills", 1)
		end

	show_about
			-- Which build and data are open.
		do
			window.toast ({STRING_32} "simple_bible, engine " + {BIB_RELEASE}.Engine_version + {STRING_32} ".  " + status_text, 1)
		end

feature {NONE} -- Toolbar (C3-C9)

	history: ARRAYED_LIST [TUPLE [book, chapter, verse: INTEGER]]
			-- Places read, for Back and Forward (C3).

	history_index: INTEGER
			-- Where Back and Forward stand in `history'.

	settings: BIB_SETTINGS
			-- The reader's choices kept between runs: the text size (C8).

	on_reference
			-- C4: a place goes to S1; anything else is searched.
		local
			l_lookup: BIB_LOOKUP
		do
			if bible.is_open and then not reading_version.is_empty then
				create l_lookup.make (bible)
				if attached l_lookup.place_named (reference_box.text) as al_place then
					go_to (al_place.book, al_place.chapter, al_place.verse)
				elseif not reference_box.text.is_empty then
					search_box.set_text (reference_box.text)
					on_search
				end
			end
		end

	on_search
			-- C6: a word, verse or Strong's number; several choices open P07, one word opens S3.
		local
			l_lookup: BIB_LOOKUP
		do
			if bible.is_open and then bible.conc_pack.is_available and then not search_box.text.is_empty then
				create l_lookup.make (bible)
				choices := l_lookup.choices_for (search_box.text)
				results_grid.set_rows (choices)
				results_note.set_text (l_lookup.note_text)
				if attached l_lookup.last_verse as al_verse and then not reading_version.is_empty then
					go_to (al_verse.book, al_verse.chapter, al_verse.verse)
				end
				if choices.count = 1 and then choices.first.opens_a_word then
					open_study (choices.first.lemma_id)
					hide_results
				else
					show_results
					if choices.count >= 1 and then choices.first.opens_a_word and then l_lookup.last_verse = Void then
						open_study (choices.first.lemma_id)
					end
				end
			end
		end

	on_version_change
			-- C5: read the same place in the version picked.
		do
			if version_select.selected_index >= 1 and version_select.selected_index <= bible.text_reader.versions.count then
				reading_version := bible.text_reader.versions.i_th (version_select.selected_index).code
				if reading_book > 0 then
					open_reading (reading_book, reading_chapter, reading_verse)
				end
				if study_lemma > 0 then
					renderings_grid.set_rows (renderings_for_version (renderings))
				end
			end
		end

	on_mode (a_index: INTEGER)
			-- C7: Simple (1) or Study (2); layout only, never data.
		do
			if (a_index = 2) /= is_study then
				arrange (a_index = 2)
			end
		end

	toggle_mode
			-- Ctrl+M.
		do
			arrange (not is_study)
		end

	change_text_size (a_step: INTEGER)
			-- C8: all the window's text larger (1) or smaller (-1), menus too, kept for the next run
			-- (Larry, 2026-10-26: not the Bible text alone).
		local
			l_scale: REAL_64
			l_saved: BOOLEAN
		do
			l_scale := ((settings.text_scale + 0.1 * a_step) * 10.0).rounded / 10.0
			l_scale := l_scale.max (settings.Min_text_scale).min (settings.Max_text_scale)
			settings.set_text_scale (l_scale)
			light_theme.set_text_scale (l_scale)
			dark_theme.set_text_scale (l_scale)
			smaller_button.set_enabled (l_scale > settings.Min_text_scale)
			larger_button.set_enabled (l_scale < settings.Max_text_scale)
			l_saved := settings.save
			window.request_render
			window.toast ({STRING_32} "Text size " + (l_scale * 100.0).rounded.out + {STRING_32} "%%", 1)
		end

	mark_selected_verse (a_view: SW_PARALLEL_TEXT; a_row, a_column: INTEGER; a_text: READABLE_STRING_32)
			-- Wash the selected verse's text `a_text' in cell `a_row', `a_column' of `a_view': the one
			-- mark the Bible and Parallel tabs both use (scan 36).
		local
			l_mark: SW_MARK
		do
			if not a_text.is_empty then
				create l_mark.make ({SW_MARK}.Hue_blue)
				a_view.cell_marks (a_row, a_column).mark_range_with (0, a_text.count, "selected verse", l_mark.with_wash).do_nothing
			end
		end

	Original_script_scale: REAL_64 = 1.35
			-- Hebrew and Aramaic read this much larger than the window's text, in every view.

	apply_reading_scale
			-- Hebrew and Aramaic read a little larger than the window's text.
		do
			if attached bible.text_reader.version (reading_version) as al_version and then al_version.is_right_to_left then
				reading_view.set_column_scale (1, Original_script_scale)
			else
				reading_view.set_column_scale (1, 1.0)
			end
		end

	on_dark
			-- C9: the theme the switch shows.
		do
			set_dark (dark_switch.is_on)
		end

	set_dark (a_dark: BOOLEAN)
			-- Wear the dark theme, or the light one (the reader's own choice: Windows no longer decides).
		do
			if a_dark then
				window.set_theme (dark_theme)
			else
				window.set_theme (light_theme)
			end
			if dark_switch.is_on /= a_dark then
				dark_switch.set_on (a_dark)
			end
		end

	focus_reference
			-- Ctrl+L: the reference box, its text selected even when it already has the focus, as a
			-- browser's address bar (2026-10-27: a second Ctrl+L typed into the middle of the place).
		do
			window.give_focus (reference_box)
			reference_box.select_all
		end

	focus_search
			-- Ctrl+F: the search box, its text selected, as Ctrl+L.
		do
			window.give_focus (search_box)
			search_box.select_all
		end

	copy_verse
			-- Edit > Copy verse: the selected verse with its reference.
		local
			l_text: STRING_32
		do
			across reading_verses as ic loop
				if ic.verse = reading_verse then
					l_text := ic.display_text + {STRING_32} " (" + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} " " + reading_version.to_string_32 + {STRING_32} ")"
					(create {SW_CLIPBOARD}).set_text (l_text)
					window.toast ("Verse copied.", 2)
				end
			end
		end

feature {NONE} -- Reading (S1, P01)

	reading_caption, reading_title, version_chip, reading_note: SW_LABEL
	previous_button, next_button: SW_BUTTON
	reading_view: SW_PARALLEL_TEXT

	reading_verses: ARRAYED_LIST [BIB_READING_VERSE]
			-- The chapter shown, verse by verse.

	reading_version: STRING_8
			-- The version S1 reads (C5's choice); empty when content.db holds none.

	reading_book, reading_chapter, reading_verse: INTEGER
			-- The chapter shown and its selected verse (0: none).

	fill_versions
			-- C5 lists every version content.db holds; the King James Version is chosen first.
		local
			i, l_chosen: INTEGER
		do
			if bible.is_open then
				across bible.text_reader.versions as ic loop
					version_select.add_option (ic.name)
				end
				from i := 1 until i > bible.text_reader.versions.count loop
					if l_chosen = 0 or else bible.text_reader.versions.i_th (i).code.same_string ("KJV") then
						l_chosen := i
					end
					i := i + 1
				end
				from i := 1 until i > bible.text_reader.versions.count loop
					if bible.text_reader.versions.i_th (i).code.same_string ("KJV") then
						l_chosen := i
					end
					i := i + 1
				end
				if l_chosen > 0 then
					version_select.select_index (l_chosen)
					reading_version := bible.text_reader.versions.i_th (l_chosen).code
				end
			end
		end

	go_to (a_book, a_chapter, a_verse: INTEGER)
			-- Read `a_book' `a_chapter' (verse `a_verse' selected, 0: none) and remember it for Back.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_not_negative: a_verse >= 0
		do
			from until history.count <= history_index loop
				history.finish
				history.remove
			end
			history.extend ([a_book, a_chapter, a_verse])
			history_index := history.count
			open_reading (a_book, a_chapter, a_verse)
		end

	move_in_history (a_step: INTEGER)
			-- C3: Back (-1) or Forward (1).
		do
			if history_index + a_step >= 1 and history_index + a_step <= history.count then
				history_index := history_index + a_step
				open_reading (history.i_th (history_index).book, history.i_th (history_index).chapter, history.i_th (history_index).verse)
			end
		end

	open_reading (a_book, a_chapter, a_verse: INTEGER)
			-- Show chapter `a_chapter' of book `a_book' in S1, verse `a_verse' marked (0: none); S2,
			-- the title and the status bar follow.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_not_negative: a_verse >= 0
		local
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_row, l_selected_row, i: INTEGER
			l_lookup: BIB_LOOKUP
		do
			if bible.text_reader.has_version (reading_version) then
				reading_book := a_book
				reading_chapter := a_chapter
				reading_verse := a_verse
				l_chapter := bible.text_reader.chapter (reading_version, a_book, a_chapter)
				create reading_verses.make (l_chapter.count)
				from i := 1 until i > l_chapter.count loop
					reading_verses.extend (l_chapter.item (i))
					i := i + 1
				end
				reading_title.set_text (place_text (a_book, a_chapter, 0))
				if attached bible.text_reader.version (reading_version) as al_version then
					version_chip.set_text (al_version.name)
					reading_note.set_text (numbering_note (al_version))
					numbering_label.set_text (numbering_name (al_version))
				end
				apply_reading_scale
				reading_view.wipe_out
				across reading_verses as ic loop
					l_row := reading_view.add_row (ic.verse.out)
					reading_view.set_cell (l_row, 1, ic.display_text)
					if ic.verse = a_verse then
						l_selected_row := l_row
						mark_selected_verse (reading_view, l_row, 1, ic.display_text)
					end
				end
				create l_lookup.make (bible)
				if l_chapter.count = 0 then
					reading_view.add_note (l_lookup.empty_chapter_text (l_chapter, place_text (a_book, a_chapter, 0))).do_nothing
				end
				if l_selected_row > 0 then
					reading_view.scroll_to_row (l_selected_row)
				end
				previous_button.set_enabled (a_chapter > 1 or a_book > 1)
				next_button.set_enabled (a_chapter < bible.text_reader.last_chapter (reading_version, a_book) or a_book < Last_book)
				back_button.set_enabled (history_index > 1)
				forward_button.set_enabled (history_index < history.count)
				show_cross_refs
					-- C4 shows the place S1 reads, however S1 got there (Larry, 2026-10-26: a verse
					-- or cross-reference click left it showing what was typed last).
				reference_box.set_text (place_text (a_book, a_chapter, a_verse))
				window.set_title (window_title)
				status_bar.set_left (place_text (a_book, a_chapter, a_verse) + {STRING_32} " (" + reading_version.to_string_32 + {STRING_32} ")")
				if is_study then
					fill_parallel
					if center_tabs.selected_index = Interlinear_tab then
						fill_interlinear
					end
					fill_notes
				end
			end
		end

	step_chapter (a_step: INTEGER)
			-- The chapter before (-1) or after (1), across books at their ends.
		local
			l_book, l_chapter: INTEGER
		do
			if reading_book > 0 then
				l_book := reading_book
				l_chapter := reading_chapter + a_step
				if l_chapter < 1 and l_book > 1 then
					l_book := l_book - 1
					l_chapter := bible.text_reader.last_chapter (reading_version, l_book)
				elseif l_chapter > bible.text_reader.last_chapter (reading_version, l_book) and l_book < Last_book then
					l_book := l_book + 1
					l_chapter := 1
				end
				if l_chapter >= 1 then
					go_to (l_book, l_chapter, 0)
				end
			end
		end

	on_verse_click (a_row, a_column: INTEGER)
			-- S4: the verse clicked is selected and S2 follows it; the word clicked opens its original
			-- in S3 (GW-08), or the verse's original words fill P07.
		local
			l_word: STRING_32
			l_occurrence: INTEGER
		do
			if a_row >= 1 and a_row <= reading_verses.count then
				l_word := clicked_word (reading_view, a_row)
				l_occurrence := last_word_occurrence
				go_to (reading_book, reading_chapter, reading_verses.i_th (a_row).verse)
				follow_word (reading_version, l_word, l_occurrence)
			end
		end

	on_parallel_click (a_row, a_column: INTEGER)
			-- T3 Parallel: a click in any column selects the verse in every column and in the Bible tab,
			-- and its word opens in T4 as in the Bible tab (Larry, 2026-10-26).
		local
			l_word: STRING_32
			l_occurrence: INTEGER
		do
			if a_row >= 1 and a_row <= reading_verses.count and a_column >= 1 and a_column <= parallel_codes.count then
				l_word := clicked_word (parallel_view, a_row)
				l_occurrence := last_word_occurrence
				go_to (reading_book, reading_chapter, reading_verses.i_th (a_row).verse)
				follow_word (parallel_codes.i_th (a_column), l_word, l_occurrence)
			end
		end

	follow_word (a_version: STRING_8; a_word: STRING_32; a_occurrence: INTEGER)
			-- The word `a_word' (its `a_occurrence'th in the selected verse of `a_version') opens its
			-- headword in S3: through the English words' links (KJV, BSB) or, in a Hebrew or Greek text,
			-- matched to the tagged tokens. Nothing found: the verse's original words fill P07.
		local
			l_lookup: BIB_LOOKUP
			l_english, l_original: STRING_8
			l_found: detachable BIB_LIST_RESULT [BIB_WORD_ENTRY]
			l_ref: BIB_REF
		do
			if bible.conc_pack.is_available and then bible.books.has_book (reading_book) and then reading_verse > 0 then
				create l_lookup.make (bible)
				create l_ref.make (reading_book, reading_chapter, reading_verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv)
				l_english := l_lookup.english_corpus_for_version (a_version)
				l_original := l_lookup.original_corpus_for_version (a_version, reading_book)
				if not a_word.is_empty and a_occurrence >= 1 then
					if not l_english.is_empty then
						l_found := bible.conc_pack.headwords_behind_word (l_english, l_ref, a_word, a_occurrence)
					elseif not l_original.is_empty then
						l_found := bible.conc_pack.headwords_behind_original_word (l_original, l_ref, a_word, a_occurrence)
					end
				end
				if attached l_found as al_found and then al_found.count >= 1 then
					open_study (al_found.item (1).lemma_id)
					hide_results
				else
					choices := l_lookup.verse_choices (reading_book, reading_chapter, reading_verse)
					results_grid.set_rows (choices)
					results_note.set_text (l_lookup.note_text)
					show_results
				end
			end
		end

	last_word_occurrence: INTEGER
			-- Which occurrence of its word in the verse the last `clicked_word' was (1 for the first).

	clicked_word (a_view: SW_PARALLEL_TEXT; a_row: INTEGER): STRING_32
			-- The word under the pointer in row `a_row' of `a_view' (the view tracks the character
			-- under the pointer), and its occurrence in `last_word_occurrence'; empty when none is.
		local
			l_item, l_character, l_from: INTEGER
			l_range: TUPLE [lo, hi: INTEGER]
			l_text: READABLE_STRING_32
		do
			create Result.make_empty
			last_word_occurrence := 0
			l_item := a_view.hover_item
			l_character := a_view.hover_character
			if l_item > 0 and l_character > 0 and then a_view.unit_block (l_item) = a_row then
				l_text := a_view.text_of (l_item)
				l_range := a_view.word_at (l_item, l_character)
				if l_range.hi > l_range.lo and l_range.hi <= l_text.count then
					Result := l_text.substring (l_range.lo + 1, l_range.hi).to_string_32
					last_word_occurrence := 1
					from l_from := 1 until l_from > l_range.lo loop
						l_from := whole_word_after (l_text, Result, l_from)
						if l_from > 0 and l_from <= l_range.lo then
							last_word_occurrence := last_word_occurrence + 1
							l_from := l_from + Result.count
						else
							l_from := l_range.lo + 1
						end
					end
				end
			end
		ensure
			counted: not Result.is_empty implies last_word_occurrence >= 1
		end

	is_word_character (a_char: CHARACTER_32): BOOLEAN
			-- Is `a_char' part of a word: a letter, digit, Hebrew point or Greek letter (not a space,
			-- punctuation, the Hebrew maqaf or sof pasuq)?
		do
			Result := a_char.is_alpha_numeric
				or else (a_char.natural_32_code > 127 and then not a_char.is_space
					and then a_char.natural_32_code /= 0x05BE and then a_char.natural_32_code /= 0x05C3
					and then not (a_char.natural_32_code >= 0x2000 and a_char.natural_32_code <= 0x206F))
		end

	whole_word_after (a_text: READABLE_STRING_32; a_word: STRING_32; a_from: INTEGER): INTEGER
			-- Where `a_word' next stands in `a_text' as a whole word, at or after `a_from'; 0 when not.
		local
			l_at: INTEGER
		do
			from
				l_at := a_text.substring_index (a_word, a_from)
			until
				l_at = 0 or Result > 0
			loop
				if (l_at = 1 or else not is_word_character (a_text.item (l_at - 1)))
					and then (l_at + a_word.count > a_text.count or else not is_word_character (a_text.item (l_at + a_word.count)))
				then
					Result := l_at
				else
					l_at := a_text.substring_index (a_word, l_at + 1)
				end
			end
		end

	numbering_note (a_version: BIB_READING_VERSION): STRING_32
			-- What the reader should know: a place's numbering may differ here, or the version's caveat.
		do
			if study_corpus.same_string ("WLC-MACULA") and not a_version.versification.same_string ("hebrew") then
				Result := {STRING_32} "Places follow the Hebrew Bible's numbering; in a few chapters this version numbers verses differently."
			else
				Result := a_version.caveat.twin
				if Result.count > 160 then
					Result := Result.substring (1, 160) + {STRING_32} "..."
				end
			end
		end

	numbering_name (a_version: BIB_READING_VERSION): STRING_32
			-- C13: which numbering the version uses.
		do
			if a_version.versification.same_string ("hebrew") then
				Result := {STRING_32} "Hebrew numbering"
			elseif a_version.versification.same_string ("lxx") then
				Result := {STRING_32} "Septuagint numbering"
			elseif a_version.versification.same_string ("vulgate") then
				Result := {STRING_32} "Vulgate numbering"
			else
				Result := {STRING_32} "English numbering"
			end
		end

feature {NONE} -- Two layouts (C7)

	is_study: BOOLEAN
			-- Is the Study layout on?

	center_holder: SW_COLUMN
			-- The dock's centre: the Bible text (Simple) or the Bible tabs (Study, T3).

	center_tabs: SW_TABS
	bible_page: SW_COLUMN
	reading_column: SW_COLUMN
			-- T3's tabs, its Bible page, and the Bible text pane both layouts show.

	results_holder: SW_COLUMN
	results_tabs: SW_TABS
	results_page: SW_COLUMN
	results_column: SW_COLUMN
			-- The results panel: P07 alone (Simple) or T6's tabs (Study).

	tools_holder: SW_ROW
	tools_strip: SW_TOOLBAR
			-- C10, in the toolbar in Study only.

	navigator_panel, notes_panel: INTEGER
			-- T1 and T2, west in Study, hidden in Simple.

	navigator_tree: SW_TREE [BIB_NAV_NODE]
	parallel_view: SW_PARALLEL_TEXT

	interlinear_view: SW_INTERLINEAR
	interlinear_note: SW_LABEL
			-- T3 Interlinear (P03): the chapter word by word, and what it is read from.

	interlinear_words: ARRAYED_LIST [BIB_INTERLINEAR_WORD]
			-- The words in `interlinear_view', in order (word k is cell k).

	interlinear_book, interlinear_chapter: INTEGER
			-- The chapter `interlinear_view' holds; 0 when none.

	is_interlinear_click: BOOLEAN
			-- Is a word clicked in the Interlinear moving the place read? Then the click's word stays
			-- selected, not the verse's first.

	parallel_codes: ARRAYED_LIST [STRING_8]
			-- The versions in T3 Parallel's columns, left to right.
		attribute
			create Result.make (0)
		end

	arrange (a_study: BOOLEAN)
			-- Put the panels where the layout wants them: Simple (the guide's Simple board) or Study
			-- (T1 Navigator and T2 Notes west, T3 Bible tabs centre, T4 Lexicon over T5 Commentary
			-- east, T6 results south, C10 in the toolbar). Kept for the next run.
		local
			l_saved: BOOLEAN
		do
			detach (center_holder, reading_column)
			detach (bible_page, reading_column)
			detach (center_holder, center_tabs)
			detach (results_holder, results_column)
			detach (results_page, results_column)
			detach (results_holder, results_tabs)
			if tools_holder.children.has (tools_strip) then
				tools_holder.remove (tools_strip)
			end
			is_study := a_study
			if a_study then
				bible_page.put (reading_column)
				center_holder.put (center_tabs)
				results_page.put (results_column)
				results_holder.put (results_tabs)
				tools_holder.put (tools_strip)
				dock.move_panel (lexicon_panel, dock.Zone_east)
				dock.move_panel (commentary_panel, dock.Zone_east)
				dock.move_panel (results_panel, dock.Zone_south)
				dock.show_panel (navigator_panel)
				dock.show_panel (notes_panel)
				dock.show_panel (results_panel)
				dock.set_fraction (dock.Zone_west, 0.18)
				dock.set_fraction (dock.Zone_east, 0.34)
				dock.set_fraction (dock.Zone_south, 0.30)
				center_tabs.select_tab (1)
				fill_parallel
			else
				center_holder.put (reading_column)
				results_holder.put (results_column)
				dock.move_panel (lexicon_panel, dock.Zone_south)
				dock.move_panel (commentary_panel, dock.Zone_east)
				dock.move_panel (results_panel, dock.Zone_west)
				dock.hide_panel (navigator_panel)
				dock.hide_panel (notes_panel)
				if choices.is_empty then
					dock.hide_panel (results_panel)
				else
					dock.show_panel (results_panel)
				end
				dock.set_fraction (dock.Zone_west, 0.22)
				dock.set_fraction (dock.Zone_east, 0.30)
				dock.set_fraction (dock.Zone_south, 0.42)
			end
			if mode_switch.selected_index /= (if a_study then 2 else 1 end) then
				mode_switch.select_segment (if a_study then 2 else 1 end)
			end
			window.clear_reference_marks
			if a_study then
				add_study_pills
			else
				add_pills
			end
			settings.set_study_layout (a_study)
			if not is_snapshot then
				l_saved := settings.save
			end
			keep_verse_in_view
			window.request_render
		ensure
			set: is_study = a_study
		end

	detach (a_holder: SW_COLUMN; a_widget: SW_WIDGET)
			-- Take `a_widget' out of `a_holder' when it is there.
		do
			if a_holder.children.has (a_widget) then
				a_holder.remove (a_widget)
			end
		ensure
			out: not a_holder.children.has (a_widget)
		end

	build_study_parts
			-- T3's tabs, T6's tabs and C10's tools, built once.
		local
			l_parallel_page, l_interlinear_page: SW_COLUMN
		do
			create l_parallel_page.make
			l_parallel_page.put (parallel_view.growing)
			create l_interlinear_page.make
			l_interlinear_page.put (interlinear_note)
			l_interlinear_page.put (interlinear_view.growing)
			l_interlinear_page.put (analysis_title)
			l_interlinear_page.put (analysis_grid)
				-- No pronunciation of the written word in the pack yet (lemma.pron is the headword's).
			interlinear_view.set_line_visible ({SW_INTERLINEAR_TOKEN}.Line_pronunciation, False)
			center_tabs.add_page ("Bible", bible_page)
			center_tabs.add_page ("Parallel", l_parallel_page)
			center_tabs.add_page ("Interlinear", l_interlinear_page)
			center_tabs.set_on_change (agent on_center_tab)
			parallel_view.add_column ("").do_nothing
			parallel_view.add_column ("").do_nothing
			parallel_view.add_column ("").do_nothing

			results_tabs.add_page ("Search Results", results_page)
			results_tabs.add_page ("Guides", create {SW_EMPTY_STATE}.make ("Guides come later", "A guide assembles passages, notes and word studies on one subject (P08)."))
			results_tabs.add_page ("Census and Checks", create {SW_EMPTY_STATE}.make ("Census comes later", "Counts across books and corpora with their controls (P09)."))
			results_tabs.add_page ("Author Library", create {SW_EMPTY_STATE}.make ("Author library comes later", "Your own documents and their status (P10)."))
			results_tabs.add_page ("Study Ledger v1.5", create {SW_EMPTY_STATE}.make ("Study ledger is version 1.5", "Planned for version 1.5."))

			tools_strip.add_tool ("Parallel", "Versions side by side (P02)", True, agent show_parallel)
			tools_strip.add_tool ("Interlinear", "Word by word in the original (P03). Ctrl+I", True, agent show_interlinear)
			tools_strip.add_tool ("Guide", "A guide on one subject (P08): comes later", False, Void)
			tools_strip.add_tool ("Word Study", "The word study (P05 Word Study): comes later", False, Void)
			tools_strip.add_tool ("Count", "Census and checks (P09): comes later", False, Void)
			tools_strip.add_tool ("Ledger v1.5", "The study ledger, version 1.5", False, Void)
		end

	navigator_pane: SW_COLUMN
			-- T1, P11 Navigator: the books, testament by testament, chapter by chapter.
		local
			l_roots: ARRAYED_LIST [BIB_NAV_NODE]
		do
			create l_roots.make (2)
			l_roots.extend (create {BIB_NAV_NODE}.make_testament ("Old Testament", 1, 39))
			l_roots.extend (create {BIB_NAV_NODE}.make_testament ("New Testament", 40, Last_book))
			navigator_tree.set_label (agent {BIB_NAV_NODE}.label)
			navigator_tree.set_children (agent nav_children)
			navigator_tree.set_roots (l_roots)
			navigator_tree.set_on_select (agent on_nav)
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (create {SW_LABEL}.make_ui ("Books"))
			Result.put (navigator_tree.growing)
		end

	notes_pane: SW_WIDGET
			-- T2, P06 Notes (GUI spec 5.6): its tabs, of which Verse notes is built (2026-10-27).
		local
			l_tabs: SW_TABS
			l_page: SW_COLUMN
			l_buttons: SW_ROW
		do
			create l_page.make
			l_page := l_page.with_gap (6.0)
			l_page.put (notes_heading)
			l_page.put (notes_list.growing)
			l_page.put (new_note_label)
			l_page.put (new_note_box)
			create l_buttons.make
			l_buttons.put (add_note_button)
			l_buttons.put (delete_note_button)
			l_buttons.put (restore_note_button)
			l_page.put (l_buttons)
			create l_tabs.make
			l_tabs.add_page ("Verse notes", l_page)
			l_tabs.add_page ("Journal", create {SW_EMPTY_STATE}.make ("Journal comes later", "Notebooks and topical notes (E04)."))
			l_tabs.add_page ("Tags", create {SW_EMPTY_STATE}.make ("Tags come later", "Your tags and their verses (E05)."))
			l_tabs.add_page ("Highlights", create {SW_EMPTY_STATE}.make ("Highlights come later", "Highlights by reason, not color (E01)."))
			l_tabs.add_page ("Prayer", create {SW_EMPTY_STATE}.make ("Prayer list comes later", "Requests with dates (E06)."))
			l_tabs.add_page ("Memory", create {SW_EMPTY_STATE}.make ("Memory cards come later", "Verses to learn, spaced (E07)."))
			Result := l_tabs.growing
		end

feature {NONE} -- Notes (T2, P06)

	user_store: BIB_USER_STORE
	note_store: BIB_DB_NOTE_STORE
			-- user.db, the reader's own data, and its notes.

	notes_list: SW_PARAGRAPH_LIST
	notes_heading, new_note_label: SW_LABEL
	new_note_box: SW_TEXT_BOX
	add_note_button, delete_note_button, restore_note_button: SW_BUTTON
			-- Verse notes: the chapter's notes, and a new note on the verse read.

	note_rows: ARRAYED_LIST [BIB_NOTE]
			-- The notes in `notes_list', in order (paragraph k is note k).

	last_deleted_note: INTEGER_64
			-- The note Delete removed last; Restore brings it back (0: none).

	fill_notes
			-- Verse notes follow the place read: the chapter's notes, each under its verse number, and
			-- the box for a new note on the verse read.
		local
			l_hub: BIB_HUB_ID
			i: INTEGER
		do
			notes_list.wipe_out
			note_rows.wipe_out
			if not user_store.is_open then
				if attached user_store.last_error as al_error then
					notes_heading.set_text ({STRING_32} "Notes are unavailable: " + al_error.message)
				else
					notes_heading.set_text ("Notes are unavailable.")
				end
			elseif reading_book > 0 and reading_chapter > 0 then
				create l_hub
				note_rows := note_store.notes_between (l_hub.hub_id (reading_book, reading_chapter, 1), l_hub.hub_id (reading_book, reading_chapter, l_hub.Max_part))
				from i := 1 until i > note_rows.count loop
					notes_list.add (note_rows.i_th (i).body)
					i := i + 1
				end
				if note_rows.is_empty then
					notes_heading.set_text ({STRING_32} "No notes on " + place_text (reading_book, reading_chapter, 0) + {STRING_32} " yet")
				else
					notes_heading.set_text ({STRING_32} "Notes on " + place_text (reading_book, reading_chapter, 0) + {STRING_32} " (double-click one to edit)")
				end
			end
			if reading_verse > 0 then
				new_note_label.set_text ({STRING_32} "A new note on " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} ":")
			else
				new_note_label.set_text ("Click a verse to write a note on it.")
			end
			add_note_button.set_enabled (user_store.is_open and reading_verse > 0)
			delete_note_button.set_enabled (False)
			restore_note_button.set_enabled (last_deleted_note > 0)
		end

	add_note
			-- The box's text becomes a note on the verse read.
		local
			l_note: BIB_NOTE
			l_body: STRING_32
		do
			l_body := new_note_box.text.twin
			l_body.left_adjust
			l_body.right_adjust
			if l_body.is_empty then
				window.toast ("Write the note in the box first.", 1)
			elseif user_store.is_open and reading_verse > 0 and note_store.is_writable then
				create l_note.make ((create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse), "", l_body)
				note_store.add_note (l_note)
				if attached note_store.last_error as al_error then
					window.toast (al_error.message, 1)
				else
					new_note_box.set_text ("")
					fill_notes
				end
			end
		end

	edit_note (a_index: INTEGER)
			-- A double-click opens the note for editing in place.
		do
			if a_index >= 1 and a_index <= note_rows.count then
				notes_list.begin_edit (a_index)
			end
		end

	on_note_edited (a_index: INTEGER; a_text: STRING_32)
			-- An edit stands: it becomes the note's next version (the old one is kept).
		do
			if a_index >= 1 and a_index <= note_rows.count and then note_store.is_writable then
				note_store.update_note (note_rows.i_th (a_index).id, a_text)
				if attached note_store.last_error as al_error then
					window.toast (al_error.message, 1)
				end
			end
		end

	on_note_selected (a_index: INTEGER)
			-- A selected note can be deleted.
		do
			delete_note_button.set_enabled (a_index >= 1 and a_index <= note_rows.count)
		end

	delete_note
			-- Soft-delete the selected note (Restore brings it back, with its history).
		local
			l_index: INTEGER
		do
			l_index := notes_list.selected_index
			if l_index >= 1 and l_index <= note_rows.count and then note_store.is_writable then
				note_store.remove_note (note_rows.i_th (l_index).id)
				if attached note_store.last_error as al_error then
					window.toast (al_error.message, 1)
				else
					last_deleted_note := note_rows.i_th (l_index).id
					fill_notes
					window.toast ("Note deleted. Restore brings it back.", 1)
				end
			end
		end

	restore_note
			-- Bring back the note Delete removed last.
		do
			if last_deleted_note > 0 and then note_store.is_writable and then note_store.is_deleted (last_deleted_note) then
				note_store.restore_note (last_deleted_note)
				if attached note_store.last_error as al_error then
					window.toast (al_error.message, 1)
				else
					last_deleted_note := 0
					fill_notes
				end
			end
		end

	draw_note_gutter (a_p: SW_PAINTER; a_index: INTEGER; a_x, a_y, a_width, a_height: REAL_64)
			-- A note's verse number beside it.
		local
			l_hub: BIB_HUB_ID
		do
			if a_index >= 1 and a_index <= note_rows.count then
				create l_hub
				if l_hub.is_valid_hub (note_rows.i_th (a_index).hub_id) then
					a_p.set_color (a_p.theme.ink_muted)
					a_p.font ({SW_PAINTER}.Role_ui, a_p.theme.size_label - 1.0, False)
					a_p.text (a_x + 2.0, a_y + a_p.theme.size_label + 4.0, l_hub.verse_of (note_rows.i_th (a_index).hub_id).out)
				end
			end
		end

	nav_children (a_node: BIB_NAV_NODE): ARRAYED_LIST [BIB_NAV_NODE]
			-- A testament's books, or a book's chapters (in the version read); a chapter has none. Built
			-- once per node and kept there, so the tree finds the same objects again.
		local
			i, l_last: INTEGER
		do
			if attached a_node.children as al_kept then
				Result := al_kept
			else
				Result := new_nav_children (a_node)
				a_node.set_children (Result)
			end
		ensure
			kept: a_node.children = Result
		end

	new_nav_children (a_node: BIB_NAV_NODE): ARRAYED_LIST [BIB_NAV_NODE]
			-- `nav_children', built.
		local
			i, l_last: INTEGER
		do
			create Result.make (0)
			if a_node.is_testament then
				from i := a_node.first_book until i > a_node.last_book loop
					if bible.books.has_book (i) then
						Result.extend (create {BIB_NAV_NODE}.make_book (bible.books.book (i).name, i))
					end
					i := i + 1
				end
			elseif a_node.is_book and then bible.text_reader.has_version (reading_version) then
				l_last := bible.text_reader.last_chapter (reading_version, a_node.book_id)
				if l_last = 0 then
					l_last := bible.text_reader.last_chapter ("KJV", a_node.book_id)
				end
				from i := 1 until i > l_last loop
					Result.extend (create {BIB_NAV_NODE}.make_chapter (a_node.book_id, i))
					i := i + 1
				end
			end
		end

	on_nav (a_node: BIB_NAV_NODE)
			-- A chapter chosen in T1: read it. A testament or book clicked opens or closes, not only
			-- on its small arrow (Larry: clicking John did not show its chapters).
		do
			if a_node.is_chapter then
				go_to (a_node.book_id, a_node.chapter, 0)
			elseif navigator_tree.is_expanded (a_node) then
				navigator_tree.collapse_node (a_node)
			else
				navigator_tree.expand_node (a_node)
			end
		end

	on_center_tab (a_index: INTEGER)
			-- T3: the Parallel and Interlinear tabs follow the place read.
		do
			if a_index = 2 then
				fill_parallel
			elseif a_index = Interlinear_tab then
				fill_interlinear
			end
		end

	Interlinear_tab: INTEGER = 3
			-- T3's Interlinear page.

	show_interlinear
			-- C10 Interlinear, Ctrl+I: the Interlinear tab (in Study; Simple has no tabs).
		do
			if not is_study then
				arrange (True)
			end
			center_tabs.select_tab (Interlinear_tab)
			fill_interlinear
		end

	fill_interlinear
			-- T3 Interlinear (P03): the chapter read, word by word in the original (the Hebrew Bible,
			-- right to left, or the Greek New Testament), with the verse read selected. The words are
			-- read once per chapter; a new verse in it only moves the selection.
		local
			l_lookup: BIB_LOOKUP
			l_corpus: STRING_8
			l_words: BIB_LIST_RESULT [BIB_INTERLINEAR_WORD]
			l_word: BIB_INTERLINEAR_WORD
			l_note: STRING_32
			i, k, l_previous_verse, l_select: INTEGER
		do
			if reading_book > 0 and then bible.is_open then
				if reading_book /= interlinear_book or reading_chapter /= interlinear_chapter then
					interlinear_view.wipe_out
					interlinear_words.wipe_out
					interlinear_book := reading_book
					interlinear_chapter := reading_chapter
					create l_lookup.make (bible)
					l_corpus := l_lookup.corpus_for_book (reading_book)
					if not bible.conc_pack.is_available then
						l_note := {STRING_32} "The interlinear needs the concordance pack (conc.db), which is not open."
					elseif not bible.conc_pack.has_corpus (l_corpus) then
						l_note := {STRING_32} "The concordance has no tagged text for this book."
					else
						l_words := bible.conc_pack.interlinear_chapter (reading_book, reading_chapter, l_corpus)
						interlinear_view.set_right_to_left (l_corpus.same_string ("WLC-MACULA"))
						from i := 1 until i > l_words.count loop
							l_word := l_words.item (i)
							interlinear_words.extend (l_word)
							if l_word.surface.is_empty then
								k := interlinear_view.add_token ({STRING_32} "[" + l_word.lemma_text + {STRING_32} "]")
							else
								k := interlinear_view.add_token (l_word.surface)
							end
							interlinear_view.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_transliteration, l_word.translit)
							interlinear_view.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_gloss, l_word.gloss)
							interlinear_view.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_lemma, l_word.lemma_text)
							interlinear_view.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_strongs, l_word.strongs)
							interlinear_view.set_token_line (k, {SW_INTERLINEAR_TOKEN}.Line_morphology, l_word.morphology)
							if l_word.verse /= l_previous_verse then
								interlinear_view.set_verse_label (k, l_word.verse.out)
								l_previous_verse := l_word.verse
							end
							i := i + 1
						end
						if attached l_words.error as al_error then
							l_note := al_error.message.to_string_32
								-- Not kept: the next visit reads again (scan 38).
							interlinear_book := 0
						elseif l_words.count = 0 then
							l_note := place_text (reading_book, reading_chapter, 0) + {STRING_32} " is not in the tagged text."
						else
							l_note := bible.conc_pack.corpus_name (l_corpus) + {STRING_32} ", word by word; English: STEPBible. Verses follow its own numbering."
						end
					end
					interlinear_note.set_text (l_note)
				end
				if not is_interlinear_click then
					from i := 1 until i > interlinear_words.count or l_select > 0 loop
						if interlinear_words.i_th (i).verse = reading_verse then
							l_select := i
						end
						i := i + 1
					end
					is_interlinear_click := True
					interlinear_view.select_token (l_select)
					is_interlinear_click := False
				end
				fill_verse_analysis
			end
		end

	analysis_title: SW_LABEL
	analysis_grid: SW_DATA_GRID [BIB_INTERLINEAR_WORD]
			-- C13 Verse analysis, under the Interlinear: the verse read, a row per word.

	analysis_rows: ARRAYED_LIST [BIB_INTERLINEAR_WORD]
			-- The rows of `analysis_grid'.

	analysis_uses: HASH_TABLE [INTEGER_64, INTEGER_64]
			-- How often each headword of the verse occurs in its testament's tagged text, by headword
			-- (the concordance's per-corpus counts, read when the verse changes).

	fill_verse_analysis
			-- C13: the words of the verse read in the Interlinear, with their headword's uses.
		local
			l_lookup: BIB_LOOKUP
			l_corpus: STRING_8
			i: INTEGER
		do
			create analysis_rows.make (24)
			analysis_uses.wipe_out
			if reading_verse > 0 then
				from i := 1 until i > interlinear_words.count loop
					if interlinear_words.i_th (i).verse = reading_verse then
						analysis_rows.extend (interlinear_words.i_th (i))
					end
					i := i + 1
				end
			end
			if not analysis_rows.is_empty and then bible.conc_pack.is_available then
				create l_lookup.make (bible)
				l_corpus := l_lookup.corpus_for_book (reading_book)
				if bible.conc_pack.has_corpus (l_corpus) then
					across analysis_rows as ic loop
						if ic.has_door and then not analysis_uses.has (ic.lemma_id)
							and then attached bible.conc_pack.place_total (ic.lemma_id, l_corpus) as al_total
						then
							analysis_uses.put (al_total.value, ic.lemma_id)
						end
					end
				end
			end
			if analysis_rows.is_empty then
				analysis_title.set_text ("Verse analysis: click a verse or a word.")
			else
				analysis_title.set_text ({STRING_32} "Verse analysis: " + place_text (reading_book, reading_chapter, reading_verse)
					+ {STRING_32} ", " + analysis_rows.count.out + {STRING_32} " words (Uses: how often the headword occurs in this testament)")
			end
			analysis_grid.set_rows (analysis_rows)
		end

	on_analysis_row (a_row: INTEGER)
			-- A row clicked: T4 follows its headword.
		do
			if a_row >= 1 and a_row <= analysis_rows.count and then analysis_rows.i_th (a_row).has_door then
				open_study (analysis_rows.i_th (a_row).lemma_id)
			end
		end

	analysis_position (a_word: BIB_INTERLINEAR_WORD): STRING_32
			-- The word's place in its verse.
		do
			Result := a_word.position.out
		end

	analysis_uses_text (a_word: BIB_INTERLINEAR_WORD): STRING_32
			-- How often the word's headword occurs; empty when it has none or the count is unknown.
		do
			create Result.make_empty
			if a_word.has_door and then analysis_uses.has (a_word.lemma_id) then
				Result := analysis_uses.item (a_word.lemma_id).out
			end
		end

	on_interlinear_word (a_token: INTEGER)
			-- A word clicked (or stepped to) in the Interlinear: its verse becomes the place read, and
			-- T4 follows its headword.
		local
			l_word: BIB_INTERLINEAR_WORD
		do
			if not is_interlinear_click and then a_token >= 1 and then a_token <= interlinear_words.count then
				l_word := interlinear_words.i_th (a_token)
				is_interlinear_click := True
				if l_word.verse /= reading_verse then
					go_to (reading_book, reading_chapter, l_word.verse)
					fill_verse_analysis
				end
				is_interlinear_click := False
				if l_word.has_door then
					open_study (l_word.lemma_id)
				end
			end
		end

	show_parallel
			-- C10 Parallel: the Parallel tab (in Study; Simple has no tabs).
		do
			if not is_study then
				arrange (True)
			end
			center_tabs.select_tab (2)
			fill_parallel
		end

	parallel_versions: ARRAYED_LIST [STRING_8]
			-- Three versions side by side: the one read, the other English one, and the original
			-- (the Hebrew Bible for the Old Testament, the Textus Receptus for the New).
		local
			l_other, l_original: STRING_8
		do
			create Result.make (3)
			Result.extend (reading_version)
			if reading_version.same_string ("KJV") then
				l_other := "BSB"
			else
				l_other := "KJV"
			end
			if reading_book <= 39 then
				l_original := "WLC"
			else
				l_original := "TR"
			end
			across <<l_other, l_original, "BSB", "YLT">> as ic loop
				if Result.count < 3 and then not Result.has (ic) and then bible.text_reader.has_version (ic) then
					Result.extend (ic)
				end
			end
		ensure
			at_most_three: Result.count <= 3
		end

	fill_parallel
			-- T3 Parallel: the chapter read, verse by verse, in `parallel_versions'.
		local
			l_codes: ARRAYED_LIST [STRING_8]
			l_chapters: ARRAYED_LIST [HASH_TABLE [STRING_32, INTEGER]]
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_text: HASH_TABLE [STRING_32, INTEGER]
			l_row, l_selected, i, c: INTEGER
			l_lookup: BIB_LOOKUP
			l_notes: ARRAYED_LIST [STRING_32]
			l_name, l_note: STRING_32
		do
			if reading_book > 0 and then bible.is_open then
				l_codes := parallel_versions
				parallel_codes := l_codes
				create l_chapters.make (l_codes.count)
				create l_lookup.make (bible)
				create l_notes.make (3)
				from c := 1 until c > 3 loop
					create l_text.make (40)
					if c <= l_codes.count then
						l_name := l_codes.i_th (c).to_string_32
						if attached bible.text_reader.version (l_codes.i_th (c)) as al_version then
							l_name := al_version.name
							parallel_view.set_column_title (c, al_version.name)
							if al_version.is_right_to_left then
								parallel_view.set_column_scale (c, Original_script_scale)
							else
								parallel_view.set_column_scale (c, 1.0)
							end
						end
						l_chapter := bible.text_reader.chapter (l_codes.i_th (c), reading_book, reading_chapter)
						from i := 1 until i > l_chapter.count loop
							l_text.force (l_chapter.item (i).display_text, l_chapter.item (i).verse)
							i := i + 1
						end
							-- A column with nothing says why, as the Bible tab does (scan 36).
						l_note := l_lookup.empty_chapter_text (l_chapter, place_text (reading_book, reading_chapter, 0))
						if not l_note.is_empty then
							l_notes.extend (l_name + {STRING_32} ": " + l_note)
						end
					else
						parallel_view.set_column_title (c, "")
					end
					l_chapters.extend (l_text)
					c := c + 1
				end
				parallel_view.wipe_out
				across reading_verses as ic loop
					l_row := parallel_view.add_row (ic.verse.out)
					from c := 1 until c > 3 loop
						if attached l_chapters.i_th (c).item (ic.verse) as al_cell then
							parallel_view.set_cell (l_row, c, al_cell)
								-- The selected verse is marked in every column, as in the Bible tab.
							if ic.verse = reading_verse then
								mark_selected_verse (parallel_view, l_row, c, al_cell)
							end
						end
						c := c + 1
					end
					if ic.verse = reading_verse then
						l_selected := l_row
					end
				end
				across l_notes as ic loop
					parallel_view.add_note (ic).do_nothing
				end
				if l_selected > 0 then
					parallel_view.scroll_to_row (l_selected)
				end
				if not l_codes.is_empty and then attached bible.text_reader.version (l_codes.last) as al_last
					and then not al_last.versification.same_string ("kjv")
				then
					parallel_view.add_note ({STRING_32} "Rows follow the first version's verse numbers; " + al_last.name + {STRING_32} " numbers some verses differently.").do_nothing
				end
			end
		end

	add_study_pills
			-- The Study board's codes: the chrome as on the Simple board, C10, and T1 to T6.
		do
			add_chrome_pills
			window.add_reference_mark (tools_strip, "C10", "Study tools strip: Parallel and Interlinear work; Guide, Word Study, Count and Ledger come later.", window.Corner_top_left)
			window.add_reference_mark (mode_switch, "C7", "Mode switch, on Study: only the docking changes. Ctrl+M.", window.Corner_top_left)
			window.add_reference_mark (navigator_tree, "T1", "P11 Navigator, west: books, chapter by chapter. Bookmarks come later.", window.Corner_top_left)
			window.add_reference_mark (notes_heading, "T2", "P06 Notes, west below T1: Verse notes on the chapter read. Add one on the verse read; double-click to edit (each edit keeps the old version); Delete and Restore. The other tabs come later.", window.Corner_top_left)
			window.add_reference_mark (center_tabs, "T3", "Centre tabs: the Bible text, Parallel (P02) and Interlinear (P03, Ctrl+I). More Bible tabs come later.", window.Corner_top_left)
			window.add_reference_mark (analysis_title, "C13", "Verse analysis: the verse read, a row per word with its lemma, Strong's number, morphology, gloss, and how often its headword occurs in this testament. Click a row and T4 follows it.", window.Corner_top_left)
			window.add_reference_mark (interlinear_note, "P03", "Interlinear: word by word in the original, right to left for Hebrew. A click makes the word's verse the place read and opens its headword in T4.", window.Corner_top_left)
			window.add_reference_mark (lexicon_heading, "T4", "P05 Lexicon, east: follows the clicked word.", window.Corner_top_left)
			window.add_reference_mark (commentary_title, "T5", "P04 Commentary, east: Commentaries (Larry's commentary packs, verse by verse, every claim labelled SOURCED or DEDUCED), Cross-refs with OpenBible votes.", window.Corner_top_left)
			window.add_reference_mark (results_tabs, "T6", "South results zone: Search Results; Guides, Census, Author Library and Ledger come later.", window.Corner_top_left)
		end

feature {NONE} -- Commentary (S2, P04)

	commentary_title: SW_LABEL
	commentary_tabs: SW_TABS
	cross_refs_grid: SW_DATA_GRID [BIB_READING_CROSS_REF]

	cross_refs: ARRAYED_LIST [BIB_READING_CROSS_REF]
			-- The selected verse's cross-references, most voted first.

	show_cross_refs
			-- S2 follows the verse: its cross-references, or what to do when no verse is selected.
		local
			l_result: BIB_LIST_RESULT [BIB_READING_CROSS_REF]
			i: INTEGER
		do
			create cross_refs.make (0)
			if reading_verse > 0 then
				commentary_title.set_text (place_text (reading_book, reading_chapter, reading_verse))
				l_result := bible.text_reader.cross_references (reading_book, reading_chapter, reading_verse)
				create cross_refs.make (l_result.count)
				from i := 1 until i > l_result.count loop
					cross_refs.extend (l_result.item (i))
					i := i + 1
				end
			else
				commentary_title.set_text (place_text (reading_book, reading_chapter, 0) + {STRING_32} ": click a verse for its cross-references")
			end
			cross_refs_grid.set_rows (cross_refs)
			show_commentary
		end

	commentary_view: SW_DOCUMENT_VIEW
			-- S2's Commentaries tab: the commentary packs' sections on the verse read (read-only).

	commentary_reader: MD_DOCUMENT_READER
			-- Markdown into the view's document model.

	show_commentary
			-- The Commentaries tab follows the verse: every commentary pack's sections covering it,
			-- narrowest first, each claim wearing its SOURCED or DEDUCED label.
		local
			l_text: BIB_COMMENTARY_TEXT
			l_page: STRING_32
			l_sections: BIB_LIST_RESULT [BIB_COMMENTARY_SECTION]
			l_list: ARRAYED_LIST [BIB_COMMENTARY_SECTION]
			i: INTEGER
		do
			create l_text
			create l_page.make_empty
			if not bible.is_open or else bible.commentary_packs.is_empty then
				l_page := {STRING_32} "**No commentary yet**%N%NA commentary pack in the packs folder shows here, verse by verse."
				across bible.pack_errors as ic loop
					l_page.append ({STRING_32} "%N%N*A pack was refused: " + ic.message + {STRING_32} "*")
				end
			elseif reading_verse = 0 then
				l_page := {STRING_32} "Click a verse for its commentary."
			else
				across bible.commentary_packs as ic loop
					if ic.is_available then
						l_sections := ic.sections_for_verse (reading_book, reading_chapter, reading_verse)
						if attached l_sections.error as al_error then
							l_page.append ({STRING_32} "*" + ic.title + {STRING_32} ": " + al_error.message + {STRING_32} "*%N%N")
						elseif l_sections.count > 0 then
							create l_list.make (l_sections.count)
							from i := 1 until i > l_sections.count loop
								l_list.extend (l_sections.item (i))
								i := i + 1
							end
							l_page.append (l_text.page (ic.title, l_list))
						end
					end
				end
				if l_page.is_empty then
					l_page := {STRING_32} "No commentary on " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} " yet."
				end
			end
			commentary_view.set_document (commentary_reader.read (l_page))
		end

	on_cross_ref (a_model: INTEGER)
			-- A cross-reference clicked: read it.
		do
			if a_model >= 1 and a_model <= cross_refs.count then
				go_to (cross_refs.i_th (a_model).to_book, cross_refs.i_th (a_model).to_chapter, cross_refs.i_th (a_model).verse_start)
			end
		end

feature {NONE} -- Dictionary and lexicon (S3, P05)

	lexicon_heading, lexicon_subtitle, lexicon_chip: SW_LABEL
	search_word_button, word_study_button: SW_BUTTON
	lexicon_tabs: SW_TABS
	renderings_title, entries_title, places_title: SW_LABEL
	renderings_grid: SW_DATA_GRID [BIB_ENGLISH_GLANCE_ROW]
	entries_list: SW_PARAGRAPH_LIST
	places_grid: SW_DATA_GRID [BIB_PLACE_ROW]

	renderings: ARRAYED_LIST [BIB_ENGLISH_GLANCE_ROW]
	places: ARRAYED_LIST [BIB_PLACE_ROW]
	study_lemma: INTEGER_64
	study_corpus: STRING_8
	places_total: INTEGER_64
	is_loading_places: BOOLEAN

	open_study (a_lemma_id: INTEGER_64)
			-- S3 follows the word: heading, renderings, lexicon entries, and every place.
		require
			id_positive: a_lemma_id > 0
		local
			l_glance: BIB_LIST_RESULT [BIB_ENGLISH_GLANCE_ROW]
			l_entries: BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
			l_view: BIB_WORD_VIEW
			l_gloss, l_sub: STRING_32
			i: INTEGER
		do
			is_loading_places := False
			if attached bible.conc_pack.word_entry (a_lemma_id) as al_entry then
				study_lemma := a_lemma_id
				study_corpus := study_corpus_for (a_lemma_id, bible.conc_pack.corpus_of (al_entry.provenance))
				lexicon_heading.set_text (al_entry.headword + {STRING_32} "   " + al_entry.translit)
				l_gloss := bible.conc_pack.short_gloss (a_lemma_id)
				create l_sub.make_empty
				if not al_entry.pron.is_empty then
					l_sub.append ({STRING_32} "(" + al_entry.pron + {STRING_32} ")")
				end
				if not l_gloss.is_empty then
					l_sub.append ({STRING_32} "  %"" + l_gloss + {STRING_32} "%"")
				end
				lexicon_subtitle.set_text (l_sub)
				if study_corpus.is_empty then
					lexicon_chip.set_text ("")
				else
					lexicon_chip.set_text (bible.conc_pack.corpus_short_name (study_corpus))
				end
				create renderings.make (12)
				l_glance := bible.conc_pack.english_glance (a_lemma_id, 4)
				from i := 1 until i > l_glance.count loop
					renderings.extend (l_glance.item (i))
					i := i + 1
				end
				renderings_grid.set_rows (renderings_for_version (renderings))
				entries_list.wipe_out
				l_entries := bible.conc_pack.lexicon_entries (a_lemma_id)
				from i := 1 until i > l_entries.count loop
					entries_list.add (entry_text (l_entries.item (i)))
					i := i + 1
				end
				if l_entries.count = 0 then
					entries_list.add ("No lexicon entry for this word in the concordance.")
				end
				create places.make ({BIB_CONC_PACK}.Max_page_size)
				places_total := 0
				if not study_corpus.is_empty then
					l_view := bible.word_lookup.view (a_lemma_id, study_corpus)
					if attached l_view.place_total as al_total and attached l_view.first_places as al_first then
						places_total := al_total.value
						from i := 1 until i > al_first.count loop
							places.extend (al_first.item (i))
							i := i + 1
						end
						renderings_title.set_text ({STRING_32} "How the Bibles render it (" + al_total.value.out + {STRING_32} " places in the " + bible.conc_pack.corpus_short_name (study_corpus) + {STRING_32} ")")
						is_loading_places := places.count < places_total and places.count = {BIB_CONC_PACK}.Max_page_size
						if is_loading_places and places_total <= All_at_once then
							from until not is_loading_places loop
								load_next_page
							end
						end
					elseif attached l_view.error as al_error then
						renderings_title.set_text (al_error.message)
					end
				end
				places_grid.set_rows (places)
				show_places_count
				lexicon_tabs.select_tab (1)
				dock.show_panel (lexicon_panel)
			end
		end

	study_corpus_for (a_lemma_id: INTEGER_64; a_most: STRING_8): STRING_8
			-- The corpus S3 studies a word in: the one the reader is reading (the Greek NT in John)
			-- when the word occurs there, else `a_most', where it occurs most.
		local
			l_reading: STRING_8
		do
			Result := a_most
			if reading_book > 0 then
				l_reading := (create {BIB_LOOKUP}.make (bible)).corpus_for_book (reading_book)
				if not l_reading.same_string (a_most) and then bible.conc_pack.has_corpus (l_reading)
					and then attached bible.conc_pack.place_total (a_lemma_id, l_reading) as al_total and then al_total.value > 0
				then
					Result := l_reading
				end
			end
		end

	renderings_for_version (a_rows: ARRAYED_LIST [BIB_ENGLISH_GLANCE_ROW]): ARRAYED_LIST [BIB_ENGLISH_GLANCE_ROW]
			-- `a_rows' with the reading version's own renderings first (C5: KJV picked, the KJV's
			-- renderings lead), the rest in their order.
		local
			l_corpus: STRING_8
		do
			create Result.make (a_rows.count)
			l_corpus := (create {BIB_LOOKUP}.make (bible)).english_corpus_for_version (reading_version)
			across a_rows as ic loop
				if not l_corpus.is_empty and then ic.bible.same_string (l_corpus) then
					Result.extend (ic)
				end
			end
			across a_rows as ic loop
				if l_corpus.is_empty or else not ic.bible.same_string (l_corpus) then
					Result.extend (ic)
				end
			end
		ensure
			same_rows: Result.count = a_rows.count
		end

	show_no_word
			-- S3/T4 before any word is chosen: say what to do, never a blank panel (Larry: T4 could not
			-- be seen until a search).
		do
			lexicon_heading.set_text ("No word chosen yet")
			lexicon_subtitle.set_text ("Click a word in the Bible text, or search for one.")
		end

	entry_text (a_entry: BIB_LIBRARY_ENTRY): STRING_32
			-- "AS1922  to love: the entry's own words".
		do
			Result := a_entry.resource_code.to_string_32 + {STRING_32} "   " + a_entry.title
			if not a_entry.body.is_empty and then not a_entry.body.same_string (a_entry.title) then
				Result.append ({STRING_32} ":  " + a_entry.body)
			end
		end

	show_every_place
			-- "Search this word": the Every place tab.
		do
			if study_lemma > 0 then
				lexicon_tabs.select_tab (2)
			end
		end

	on_place (a_model: INTEGER)
			-- A place clicked in Every place: read it in S1.
		do
			if a_model >= 1 and a_model <= places.count and then places.i_th (a_model).is_readable then
				go_to (places.i_th (a_model).book_id, places.i_th (a_model).chapter, places.i_th (a_model).verse)
			end
		end

	load_more_places
			-- On the window's tick: the next pages of a long every-place list.
		local
			k: INTEGER
		do
			if is_loading_places then
				from k := 1 until k > Pages_per_tick or not is_loading_places loop
					load_next_page
					k := k + 1
				end
				places_grid.set_rows (places)
				show_places_count
			end
		end

	load_next_page
			-- Append the page after the last place shown (keyset paging); stop at the end or on failure.
		require
			loading: is_loading_places
			has_places: not places.is_empty
		local
			l_page: BIB_LIST_RESULT [BIB_PLACE_ROW]
			i: INTEGER
		do
			l_page := bible.conc_pack.place_page_after (study_lemma, study_corpus, places.last.token_id, {BIB_CONC_PACK}.Max_page_size)
			if l_page.is_success then
				from i := 1 until i > l_page.count loop
					places.extend (l_page.item (i))
					i := i + 1
				end
				is_loading_places := l_page.count = {BIB_CONC_PACK}.Max_page_size and places.count < places_total
			else
				is_loading_places := False
			end
		end

	show_places_count
			-- "Every place  1,200 of 88,444, loading", and C14's bar.
		do
			if places_total > places.count then
				places_title.set_text ({STRING_32} "Every place   " + places.count.out + {STRING_32} " of " + places_total.out + {STRING_32} ", loading")
				progress.set_fraction ((places.count / places_total).min (1.0))
			else
				places_title.set_text ({STRING_32} "Every place   " + places.count.out)
				progress.set_fraction (0.0)
			end
		end

feature {NONE} -- Search results (P07)

	results_note: SW_LABEL
	results_grid: SW_DATA_GRID [BIB_LOOKUP_CHOICE]
	close_results_button: SW_BUTTON

	choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE]
			-- What the last search found, in the order P07 lists it.

	show_results
			-- Dock P07 west (Simple), or bring Search Results to the front of T6 (Study).
		do
			dock.show_panel (results_panel)
			if is_study then
				results_tabs.select_tab (1)
			end
			keep_verse_in_view
		end

	hide_results
			-- Collapse P07: an empty zone takes no room (C16). The Study layout keeps its T6 zone.
		do
			if not is_study then
				dock.hide_panel (results_panel)
				keep_verse_in_view
			end
		end

	keep_verse_in_view
			-- S1 changed width, so its rows reflow: bring the selected verse back into view once they
			-- are laid out again (seen in a scripted check: docking P07 pushed John 3:16 out of sight).
		local
			i: INTEGER
		do
			from i := 1 until i > reading_verses.count or i > reading_view.row_count loop
				if reading_verses.i_th (i).verse = reading_verse and reading_verse > 0 then
					reading_view.scroll_to_row (i)
				end
				i := i + 1
			end
		end

	on_choice (a_model: INTEGER)
			-- A result clicked: S3 follows its word.
		do
			if a_model >= 1 and a_model <= choices.count and then choices.i_th (a_model).opens_a_word then
				open_study (choices.i_th (a_model).lemma_id)
			end
		end

feature {NONE} -- Start and status (C1, C11-C15)

	show_start
			-- The opening state: what to type, or why nothing can be looked up.
		do
			if not bible.is_open then
				search_box.set_enabled (False)
				reference_box.set_enabled (False)
				if attached bible.last_error as al_error then
					results_note.set_text ({STRING_32} "simple_bible cannot open its content database: " + al_error.message)
				end
				show_results
			elseif not bible.conc_pack.is_available then
				search_box.set_enabled (False)
				if attached bible.conc_error as al_error then
					results_note.set_text ({STRING_32} "No concordance: " + al_error.message)
				else
					results_note.set_text ("No concordance pack was found beside the program.")
				end
				show_results
			end
			editions_label.set_text (status_text)
			back_button.set_enabled (False)
			forward_button.set_enabled (False)
		end

	window_title: STRING_32
			-- C1: the app, the chapter and version read, and the edition the pack names (FR-157).
		do
			Result := {STRING_32} "simple_bible"
			if reading_book > 0 then
				Result.append ({STRING_32} "   " + place_text (reading_book, reading_chapter, 0) + {STRING_32} " (" + reading_version.to_string_32 + {STRING_32} ")")
			end
			if bible.is_open and then bible.conc_pack.is_available then
				Result.append ({STRING_32} "   " + bible.conc_pack.edition_label)
			end
		end

	status_text: STRING_32
			-- C15: which data files are loaded.
		do
			if bible.is_open then
				Result := {STRING_32} "content.db " + bible.database_edition
				if bible.conc_pack.is_available then
					Result.append ({STRING_32} "  |  conc.db " + bible.conc_pack.edition_label)
				end
			else
				Result := {STRING_32} "No content database open."
			end
		end

	place_text (a_book, a_chapter, a_verse: INTEGER): STRING_32
			-- "John 3" or "John 3:16".
		do
			if bible.books.has_book (a_book) then
				Result := bible.books.book (a_book).name.twin
			else
				Result := {STRING_32} "Book " + a_book.out
			end
			Result.append ({STRING_32} " " + a_chapter.out)
			if a_verse > 0 then
				Result.append ({STRING_32} ":" + a_verse.out)
			end
		end

feature {NONE} -- Design pills

	add_chrome_pills
			-- The chrome both boards share (C1 to C6, C8, C9, C11 to C15), named once so the two
			-- layouts never tell two stories (scan 36: Simple's tips had gone stale beside Study's).
		do
			window.add_reference_mark (menu_bar, "C2", "Menu bar: the same in both layouts; every tool lives here (greyed: not built yet).", window.Corner_top_left)
			window.add_reference_mark (menu_bar, "C1", "Title bar (above): app, chapter and version, and the PERSONAL EDITION label.", window.Corner_top_right)
			window.add_reference_mark (back_button, "C3", "Back and Forward: history, Alt+Left and Alt+Right.", window.Corner_top_left)
			window.add_reference_mark (reference_box, "C4", "Reference box: 'John 3:16', 'Ps 23', 'Gen 1 1'. Anything else is searched. Ctrl+L.", window.Corner_top_left)
			window.add_reference_mark (version_select, "C5", "Version picker: every version content.db holds. The text changes; the place stays.", window.Corner_top_right)
			window.add_reference_mark (search_box, "C6", "Quick search: a word, verse or Strong's number; results open the results zone. Ctrl+F.", window.Corner_top_left)
			window.add_reference_mark (smaller_button, "C8", {STRING_32} "Text size: all the window's text, " + (settings.Min_text_scale * 100.0).rounded.out + {STRING_32} " to "
				+ (settings.Max_text_scale * 100.0).rounded.out + {STRING_32} " percent, kept for next time. Ctrl + and -.", window.Corner_top_left)
			window.add_reference_mark (dark_switch, "C9", "Dark / Light: your choice; until you switch, Windows decides.", window.Corner_top_right)
			window.add_reference_mark (link_label, "C12", "Link set: always A for now.", window.Corner_top_left)
			window.add_reference_mark (numbering_label, "C13", "Versification: which numbering the version uses.", window.Corner_top_left)
			window.add_reference_mark (progress, "C14", "Job progress: a long every-place list loading.", window.Corner_top_left)
			window.add_reference_mark (editions_label, "C15", "Database editions: which data files are loaded.", window.Corner_top_right)
			window.add_reference_mark (status_bar, "C11", "Status: the reference and version read.", window.Corner_top_left)
		end

	add_pills
			-- Each part of the window named with its code on the guide's Simple board (and P05/P07),
			-- so a screenshot with the pills on can say "C5" or "S3" and be understood. View menu or
			-- Ctrl+Shift+P shows them; each tip is the board's legend, cut short, plus what is here today.
		do
			add_chrome_pills
			window.add_reference_mark (mode_switch, "C7", "Simple | Study switch: layout only, never data. Ctrl+M.", window.Corner_top_left)
			window.add_reference_mark (dock, "C16", "Dock host: centre plus west, east, south; an empty zone collapses (P07 here).", window.Corner_top_right)
			window.add_reference_mark (reading_caption, "S1", "P01 Bible Text, centre: verse per line. Previous and Next step chapters.", window.Corner_top_left)
			window.add_reference_mark (reading_view, "S4", "Selected verse and word: click a word (English, Hebrew or Greek) and S3 follows it; S2 follows the verse.", window.Corner_top_right)
			window.add_reference_mark (commentary_title, "S2", "P04 Commentary, east: follows the verse. Commentaries from the commentary packs (every claim labelled SOURCED or DEDUCED); Cross-refs (OpenBible votes).", window.Corner_top_left)
			window.add_reference_mark (lexicon_heading, "S3", "P05 Lexicon, south: follows the word. Renderings first, then lexicon entries.", window.Corner_top_left)
			window.add_reference_mark (renderings_grid, "P05.4", "Range before ruling: every rendering with its count, before any lexicon's verdict.", window.Corner_top_left)
			window.add_reference_mark (entries_list, "P05.5", "Lexicon entries: each source in its own words (Abbott-Smith, BDB, LSJ, UBS, TBESH).", window.Corner_top_left)
			window.add_reference_mark (search_word_button, "P05.7", "Actions: Every place of this word; Word Study comes later.", window.Corner_top_left)
			window.add_reference_mark (results_note, "P07", "Search results, docked west only while there are results. Close collapses it.", window.Corner_top_left)
		end

	toggle_pills
			-- Show the design pills, or hide them.
		do
			window.set_reference_marks_shown (not window.reference_marks_shown)
		end

feature {NONE} -- Columns

	cross_ref_text (a_ref: BIB_READING_CROSS_REF): STRING_32
			-- "Romans 5:8" or "1 John 4:9-10".
		do
			Result := place_text (a_ref.to_book, a_ref.to_chapter, 0) + {STRING_32} ":" + a_ref.verses_text
		end

	votes_text (a_ref: BIB_READING_CROSS_REF): STRING_32
		do
			Result := a_ref.votes.out.to_string_32
		end

	version_name (a_row: BIB_ENGLISH_GLANCE_ROW): STRING_32
			-- The English Bible's name, never its code (FR-156).
		do
			Result := bible.conc_pack.corpus_short_name (a_row.bible)
		end

	count_text (a_row: BIB_ENGLISH_GLANCE_ROW): STRING_32
		do
			Result := a_row.count.out.to_string_32
		end

feature {NONE} -- Constants

	Key_p: INTEGER = 0x50
	Key_l: INTEGER = 0x4C
	Key_f: INTEGER = 0x46
	Key_m: INTEGER = 0x4D
	Key_i: INTEGER = 0x49
	Key_left: INTEGER = 0x25
	Key_right: INTEGER = 0x27
	Key_plus: INTEGER = 0xBB
	Key_minus: INTEGER = 0xBD
			-- Virtual keys for the accelerators.

	Last_book: INTEGER = 66
			-- Revelation, the last of the vault's book ids (FR-105).

	All_at_once: INTEGER_64 = 10000
			-- Up to this many places load before the word shows; longer lists stream on the tick.

	Pages_per_tick: INTEGER = 15
			-- Pages a tick loads (about 3,000 places, a few milliseconds each page).

end
