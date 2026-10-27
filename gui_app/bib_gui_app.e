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
			create bible.make (l_config)
			bible.open
			create settings.make
			settings.load
			create light_theme.make_light
			create dark_theme.make_dark
				-- The text size the reader chose last time, for all the window's text (C8).
			light_theme.set_text_scale (settings.text_scale)
			dark_theme.set_text_scale (settings.text_scale)
			create window.make ("simple_bible", 40, 30, 1440, 920, light_theme)
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
			create reading_view.make (200.0)
			create reading_verses.make (0)
			create reading_version.make_empty
			create commentary_title.make ("", {SW_PAINTER}.Role_ui, 13.0, True)
			create commentary_tabs.make
			create cross_refs_grid.make (120.0)
			create cross_refs.make (0)
			create lexicon_heading.make ("", {SW_PAINTER}.Role_ui, 20.0, True)
			create lexicon_subtitle.make_ui ("")
			create lexicon_chip.make_ui ("")
			create search_word_button.make ("Search this word", Void)
			create word_study_button.make ("Word Study", Void)
			create lexicon_tabs.make
			create renderings_title.make_ui ("How the Bibles render it")
			create renderings_grid.make (100.0)
			create entries_title.make_ui ("Lexicon entries")
			create entries_list.make (120.0)
			create places_title.make_ui ("Every place")
			create places_grid.make (140.0)
			create results_note.make_ui ("")
			results_note := results_note.with_wrap
			create results_grid.make (120.0)
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
			create dock.make (reading_pane)
			build_columns
			fill_versions
			mode_switch.add_segment ("Simple")
			mode_switch.add_segment ("Study")
			window.set_root (layout)
			add_menus
			add_accelerators
			wire_events
			show_start
			if bible.is_open and then not reading_version.is_empty and then bible.books.has_book (1) then
				go_to (1, 1, 0)
			end
			dark_switch.set_on (window.theme.is_dark)
				-- Typing goes straight into the reference box (keys typed before a click were lost once).
			window.give_focus (reference_box)
			window.run
			if bible.is_open then
				bible.close
			end
		end

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

			results_panel := dock.add_panel ("SEARCH RESULTS", results_pane, dock.Zone_west)
			commentary_panel := dock.add_panel ("COMMENTARY", commentary_pane, dock.Zone_east)
			lexicon_panel := dock.add_panel ("DICTIONARY AND LEXICON", lexicon_pane, dock.Zone_south)
			dock.set_fraction (dock.Zone_west, 0.22)
			dock.set_fraction (dock.Zone_east, 0.30)
			dock.set_fraction (dock.Zone_south, 0.42)
			dock.hide_panel (results_panel)

			status_bar.set_left ("")
			status_bar.add_widget (link_label, 70.0, False).do_nothing
			status_bar.add_widget (numbering_label, 170.0, False).do_nothing
			status_bar.add_widget (progress, 140.0, False).do_nothing
			status_bar.add_widget (editions_label, 460.0, True).do_nothing

			create Result.make
			Result := Result.with_padding (10.0).with_gap (8.0)
			Result.put (menu_bar)
			Result.put (l_toolbar)
			Result.put (dock.growing)
			Result.put (status_bar)
			add_pills
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
			commentary_tabs.add_page ("Commentaries", create {SW_EMPTY_STATE}.make ("No commentary yet",
				"content.db carries no commentaries yet; Matthew Henry and the others come with the content pipeline."))
			commentary_tabs.add_page ("Cross-refs", cross_refs_grid)
			commentary_tabs.add_page ("Related", create {SW_EMPTY_STATE}.make ("Related passages come later",
				"AI-made related passages are planned for a later release, always marked as AI-made."))
			commentary_tabs.select_tab (2)
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
			Result.add_item ("Simple layout", "Ctrl+M", True, Void)
			Result.add_item ("Study layout (next step)", "Ctrl+M", False, Void)
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
			Result.add_item ("Parallel", "", False, Void)
			Result.add_item ("Interlinear", "", False, Void)
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
			-- C7: the Study layout is the next step; until it is built, the switch says so and stays.
		do
			if a_index = 2 then
				window.toast ("The Study layout is the next step; Simple stays for now.", 1)
				mode_switch.select_segment (1)
			end
		end

	toggle_mode
			-- Ctrl+M.
		do
			on_mode (2)
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

	apply_reading_scale
			-- Hebrew and Aramaic read a little larger than the window's text.
		do
			if attached bible.text_reader.version (reading_version) as al_version and then al_version.is_right_to_left then
				reading_view.set_column_scale (1, 1.35)
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
			-- Ctrl+L.
		do
			window.give_focus (reference_box)
		end

	focus_search
			-- Ctrl+F.
		do
			window.give_focus (search_box)
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
			l_mark: SW_MARK
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
						create l_mark.make ({SW_MARK}.Hue_blue)
						reading_view.cell_marks (l_row, 1).mark_range_with (0, ic.display_text.count, "selected verse", l_mark.with_wash).do_nothing
					end
				end
				if l_chapter.count = 0 then
					if attached l_chapter.error as al_error then
						reading_view.add_note (al_error.message).do_nothing
					else
						reading_view.add_note (place_text (a_book, a_chapter, 0) + {STRING_32} " is not in this version.").do_nothing
					end
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
			-- S4: the verse clicked is selected and S2 follows it. A word clicked in a version with
			-- per-word links (KJV, BSB) opens its original in S3 (GW-08); otherwise the verse's
			-- original words fill P07.
		local
			l_lookup: BIB_LOOKUP
			l_word: STRING_32
			l_occurrence: INTEGER
			l_corpus: STRING_8
			l_found: BIB_LIST_RESULT [BIB_WORD_ENTRY]
			l_entries: ARRAYED_LIST [BIB_WORD_ENTRY]
			i: INTEGER
		do
			if a_row >= 1 and a_row <= reading_verses.count then
				l_word := clicked_word (a_row)
				l_occurrence := last_word_occurrence
				go_to (reading_book, reading_chapter, reading_verses.i_th (a_row).verse)
				if bible.conc_pack.is_available and then bible.books.has_book (reading_book) then
					create l_lookup.make (bible)
					l_corpus := l_lookup.english_corpus_for_version (reading_version)
					create l_entries.make (0)
					if not l_word.is_empty and not l_corpus.is_empty then
						l_found := bible.conc_pack.headwords_behind_word (l_corpus,
							create {BIB_REF}.make (reading_book, reading_chapter, reading_verse, create {BIB_VERSIFICATION_SYSTEM}.make_kjv), l_word, l_occurrence)
						from i := 1 until i > l_found.count loop
							l_entries.extend (l_found.item (i))
							i := i + 1
						end
					end
					if l_entries.count >= 1 then
						open_study (l_entries.first.lemma_id)
						hide_results
					else
						choices := l_lookup.verse_choices (reading_book, reading_chapter, reading_verse)
						results_grid.set_rows (choices)
						results_note.set_text (l_lookup.note_text)
						show_results
					end
				end
			end
		end

	last_word_occurrence: INTEGER
			-- Which occurrence of its word in the verse the last `clicked_word' was (1 for the first).

	clicked_word (a_row: INTEGER): STRING_32
			-- The word under the pointer in row `a_row' of S1 (the view tracks the character under
			-- the pointer), and its occurrence in `last_word_occurrence'; empty when none is.
		local
			l_item, l_character, l_from: INTEGER
			l_range: TUPLE [lo, hi: INTEGER]
			l_text: READABLE_STRING_32
		do
			create Result.make_empty
			last_word_occurrence := 0
			l_item := reading_view.hover_item
			l_character := reading_view.hover_character
			if l_item > 0 and l_character > 0 and then reading_view.unit_block (l_item) = a_row then
				l_text := reading_view.text_of (l_item)
				l_range := reading_view.word_at (l_item, l_character)
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
				if (l_at = 1 or else not a_text.item (l_at - 1).is_alpha_numeric)
					and then (l_at + a_word.count > a_text.count or else not a_text.item (l_at + a_word.count).is_alpha_numeric)
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
			-- Dock P07 west.
		do
			dock.show_panel (results_panel)
			keep_verse_in_view
		end

	hide_results
			-- Collapse P07: an empty zone takes no room (C16).
		do
			dock.hide_panel (results_panel)
			keep_verse_in_view
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

	add_pills
			-- Each part of the window named with its code on the guide's Simple board (and P05/P07),
			-- so a screenshot with the pills on can say "C5" or "S3" and be understood. View menu or
			-- Ctrl+Shift+P shows them; each tip is the board's legend, cut short, plus what is here today.
		do
			window.add_reference_mark (menu_bar, "C2", "Menu bar: the same in both layouts; every tool lives here (greyed: not built yet).", window.Corner_top_left)
			window.add_reference_mark (menu_bar, "C1", "Title bar (above): app, chapter and version, and the PERSONAL EDITION label.", window.Corner_top_right)
			window.add_reference_mark (back_button, "C3", "Back and Forward: history, Alt+Left and Alt+Right.", window.Corner_top_left)
			window.add_reference_mark (reference_box, "C4", "Reference box: 'John 3:16', 'Ps 23', 'Gen 1 1'. Anything else is searched. Ctrl+L.", window.Corner_top_left)
			window.add_reference_mark (version_select, "C5", "Version picker: every version content.db holds. S1 changes; the place stays.", window.Corner_top_right)
			window.add_reference_mark (search_box, "C6", "Quick search: a word, verse or Strong's number; results open P07. Ctrl+F.", window.Corner_top_left)
			window.add_reference_mark (mode_switch, "C7", "Simple | Study switch: layout only, never data. Study is the next step. Ctrl+M.", window.Corner_top_left)
			window.add_reference_mark (smaller_button, "C8", "Text size: all the window's text, 80 to 200 percent, kept for next time. Ctrl + and -.", window.Corner_top_left)
			window.add_reference_mark (dark_switch, "C9", "Dark / Light: your choice; until you switch, Windows decides.", window.Corner_top_right)
			window.add_reference_mark (dock, "C16", "Dock host: centre plus west, east, south; an empty zone collapses (P07 here).", window.Corner_top_right)
			window.add_reference_mark (reading_caption, "S1", "P01 Bible Text, centre: verse per line. Previous and Next step chapters.", window.Corner_top_left)
			window.add_reference_mark (reading_view, "S4", "Selected verse and word: click a word (KJV, BSB) and S3 follows it; S2 follows the verse.", window.Corner_top_right)
			window.add_reference_mark (commentary_title, "S2", "P04 Commentary, east: follows the verse. Cross-refs live (OpenBible votes).", window.Corner_top_left)
			window.add_reference_mark (lexicon_heading, "S3", "P05 Lexicon, south: follows the word. Renderings first, then lexicon entries.", window.Corner_top_left)
			window.add_reference_mark (renderings_grid, "P05.4", "Range before ruling: every rendering with its count, before any lexicon's verdict.", window.Corner_top_left)
			window.add_reference_mark (entries_list, "P05.5", "Lexicon entries: each source in its own words (Abbott-Smith, BDB, LSJ, UBS, TBESH).", window.Corner_top_left)
			window.add_reference_mark (search_word_button, "P05.7", "Actions: Every place of this word; Word Study comes later.", window.Corner_top_left)
			window.add_reference_mark (results_note, "P07", "Search results, docked west only while there are results. Close collapses it.", window.Corner_top_left)
			window.add_reference_mark (link_label, "C12", "Link set: always A in Simple.", window.Corner_top_left)
			window.add_reference_mark (numbering_label, "C13", "Versification: which numbering the version uses.", window.Corner_top_left)
			window.add_reference_mark (progress, "C14", "Job progress: a long every-place list loading.", window.Corner_top_left)
			window.add_reference_mark (editions_label, "C15", "Database editions: which data files are loaded.", window.Corner_top_right)
			window.add_reference_mark (status_bar, "C11", "Status: the reference and version read.", window.Corner_top_left)
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
