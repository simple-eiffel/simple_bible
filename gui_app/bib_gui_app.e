note
	description: "[
		bible_gui: the simple_bible window (first GUI, 2026-10-26). It follows the
		GUI guide's Simple layout ("simple_bible GUI Mockups", light and dark): the
		title bar carries the pack's edition label, the toolbar a lookup box, the
		centre the original-language words (a verse word by word, or what a lookup
		found), and the south the word study, in the place the guide gives the
		Dictionary and Lexicon panel: the heading, how the Bibles render it, and
		every place. Bible text and commentary come with the content pipeline.

		Lookups run on the window's thread for now (3 to 190 milliseconds on the
		real data). The every-place list streams in on the window's tick, a few
		pages at a time, so 88,444 rows never freeze it.
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
			l_light, l_dark: SW_THEME
		do
			create l_location
			create l_config.make_with_core (l_location.content_path)
			l_config := l_config.set_conc_path (l_location.conc_path)
			create bible.make (l_config)
			bible.open
			create l_light.make_light
			create l_dark.make_dark
			create window.make (window_title, 60, 40, 1320, 880, l_light)
			window.follow_system_theme (l_light, l_dark)
			window.enable_shaped_text
				-- Every attached attribute before any agent on Current (VEVI). Grid heights are minimums: a
				-- column never shrinks a child below its preferred height, so a tall grid overflowed its pane
				-- (Larry's first screenshot, 2026-10-26); small minimums grow to fill.
			create menu_bar.make
			create lookup_box.make_lookup
			create look_button.make_primary ("Look up", Void)
			create version_select.make
			create reading_title.make ("", {SW_PAINTER}.Role_ui, 15.0, True)
			create reading_note.make_ui ("")
			reading_note := reading_note.with_wrap
			create previous_button.make ("< Previous", Void)
			create next_button.make ("Next >", Void)
			create reading_view.make (200.0)
			create reading_verses.make (0)
			create reading_version.make_empty
			create centre_title.make_ui ("ORIGINAL LANGUAGE")
			create centre_note.make_ui ("")
			centre_note := centre_note.with_wrap
			create results_grid.make (120.0)
			create study_title.make_ui ("WORD STUDY")
			create heading_label.make ("", {SW_PAINTER}.Role_ui, 24.0, True)
			create pron_label.make_ui ("")
			create often_label.make_ui ("")
			create renderings_title.make_ui ("HOW THE BIBLES RENDER IT")
			create renderings_grid.make (100.0)
			create places_title.make_ui ("EVERY PLACE")
			create places_grid.make (160.0)
			create status_label.make_ui ("")
			create choices.make (0)
			create renderings.make (0)
			create places.make (0)
			create study_corpus.make_empty
			build_columns
			fill_versions
			window.set_root (layout)
			menu_bar.add_menu ("&View", agent view_menu)
			window.set_menu_bar (menu_bar)
			window.register_accelerator (Key_p, True, False, True, agent toggle_pills)
			lookup_box.set_on_enter (agent look_up)
			look_button.set_on_click (agent look_up)
			results_grid.set_on_select (agent on_choice)
			places_grid.set_on_select (agent on_place)
			version_select.set_on_change (agent on_version_change)
			previous_button.set_on_click (agent step_chapter (-1))
			next_button.set_on_click (agent step_chapter (1))
			reading_view.set_on_cell_click (agent on_verse_click)
			window.set_on_tick (agent load_more_places)
			show_start
			if bible.is_open and then not reading_version.is_empty and then bible.books.has_book (1) then
				open_reading (1, 1, 0)
			end
				-- Typing goes straight into the lookup box: at first nothing held the keyboard, so
				-- keys typed before a click were lost (seen in a scripted screenshot, 2026-10-26).
			window.give_focus (lookup_box)
			window.run
			if bible.is_open then
				bible.close
			end
		end

feature {NONE} -- Window

	window: SW_WINDOW
	menu_bar: SW_MENU_BAR
	lookup_box: BIB_LOOKUP_BOX
	version_select: SW_SELECT
	reading_title, reading_note: SW_LABEL
	previous_button, next_button: SW_BUTTON
	reading_view: SW_PARALLEL_TEXT
	look_button: SW_BUTTON
	centre_title, centre_note: SW_LABEL
	results_grid: SW_DATA_GRID [BIB_LOOKUP_CHOICE]
	study_title, heading_label, pron_label, often_label: SW_LABEL
	renderings_title, places_title, status_label: SW_LABEL
	renderings_grid: SW_DATA_GRID [BIB_ENGLISH_GLANCE_ROW]
	places_grid: SW_DATA_GRID [BIB_PLACE_ROW]

	window_title: STRING_32
			-- "simple_bible", and the edition the pack names (FR-157: the program never decides it).
		do
			Result := {STRING_32} "simple_bible"
			if bible.is_open and then bible.conc_pack.is_available then
				Result.append ({STRING_32} "   " + bible.conc_pack.edition_label)
			end
		end

	build_columns
			-- The three grids' columns.
		do
			results_grid.add_column (create {SW_GRID_COLUMN [BIB_LOOKUP_CHOICE]}.make ("Word", 220.0, agent {BIB_LOOKUP_CHOICE}.label))
			results_grid.add_column ((create {SW_GRID_COLUMN [BIB_LOOKUP_CHOICE]}.make ("Details", 360.0, agent {BIB_LOOKUP_CHOICE}.detail)).growing)
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Rendering", 160.0, agent {BIB_ENGLISH_GLANCE_ROW}.english))
			renderings_grid.add_column ((create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Version", 220.0, agent version_name)).growing)
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Count", 70.0, agent count_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Place", 150.0, agent {BIB_PLACE_ROW}.reference_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Word", 150.0, agent {BIB_PLACE_ROW}.surface))
			places_grid.add_column ((create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Transliteration", 160.0, agent {BIB_PLACE_ROW}.translit)).growing)
			reading_view.add_column ("").do_nothing
		end

	layout: SW_COLUMN
			-- The guide's Simple layout: toolbar; the lookup's results west of the Bible text (S1);
			-- the word study south (S3); status bar.
		local
			l_toolbar, l_reading_bar: SW_ROW
			l_centre, l_reading, l_heading_block, l_places: SW_COLUMN
			l_top, l_study: SW_SPLITTER
			l_main: SW_SPLITTER
		do
			create l_toolbar.make
			l_toolbar := l_toolbar.with_gap (8.0)
			l_toolbar.put (lookup_box.growing)
			l_toolbar.put (look_button)
			l_toolbar.put (version_select)

			create l_reading_bar.make
			l_reading_bar := l_reading_bar.with_gap (8.0)
			l_reading_bar.put (reading_title.growing)
			l_reading_bar.put (previous_button)
			l_reading_bar.put (next_button)
			create l_reading.make
			l_reading := l_reading.with_gap (6.0)
			l_reading.put (l_reading_bar)
			l_reading.put (reading_note.as_muted)
			l_reading.put (reading_view.growing)

			create l_centre.make
			l_centre := l_centre.with_gap (6.0)
			l_centre.put (centre_title.as_muted)
			l_centre.put (centre_note)
			l_centre.put (results_grid.growing)

			create l_heading_block.make
			l_heading_block := l_heading_block.with_gap (6.0)
			l_heading_block.put (study_title.as_muted)
			l_heading_block.put (heading_label)
			l_heading_block.put (pron_label.as_muted)
			l_heading_block.put (often_label)
			l_heading_block.put (renderings_title.as_muted)
			l_heading_block.put (renderings_grid.growing)

			create l_places.make
			l_places := l_places.with_gap (6.0)
			l_places.put (places_title.as_muted)
			l_places.put (places_grid.growing)

			create l_study.make (l_heading_block, l_places)
			l_study.set_ratio (0.45)
			create l_top.make (l_centre, l_reading)
			l_top.set_ratio (0.36)
			create l_main.make (l_top, l_study)
			l_main := l_main.with_horizontal
			l_main.set_ratio (0.5)

			create Result.make
			Result := Result.with_padding (12.0).with_gap (10.0)
			Result.put (menu_bar)
			Result.put (l_toolbar)
			Result.put (l_main.growing)
			Result.put (status_label.as_muted)
			add_pills (l_centre, l_reading, l_study)
		end

feature {NONE} -- Design pills

	add_pills (a_centre, a_reading, a_study: SW_WIDGET)
			-- Name each part of the window with its code on the GUI guide's boards (Simple layout and
			-- P05), so a screenshot with the pills on can say "P05.4" and be understood. View menu or
			-- Ctrl+Shift+P shows them; each pill's tip is the board's legend, cut short, plus what this
			-- window does there today.
		do
			window.add_reference_mark (menu_bar, "C2", "Menu bar: the same in both layouts; every tool lives here. Alt+letter works.", window.Corner_top_left)
			window.add_reference_mark (menu_bar, "C1", "Title bar (above): app and the PERSONAL EDITION label (D-021).", window.Corner_top_right)
			window.add_reference_mark (lookup_box, "C4", "Reference box: takes 'jn 3 16', 'Ps 23'. Here it also takes a word or a Strong's number.", window.Corner_top_left)
			window.add_reference_mark (look_button, "C6", "Quick search: Enter or Look up runs the box.", window.Corner_top_left)
			window.add_reference_mark (version_select, "C5", "Version picker: every version content.db holds. S1 changes; the chapter stays.", window.Corner_top_right)
			window.add_reference_mark (a_centre, "P07", "Search results (the guide's P07), docked west: what the lookup found. Click a row to study it.", window.Corner_top_left)
			window.add_reference_mark (a_reading, "S1", "P01 Bible Text, center: a chapter in the chosen version. Previous and Next step chapters.", window.Corner_top_left)
			window.add_reference_mark (reading_view, "S4", "Selected verse: click a verse and its words fill P07. A place clicked in P05.8 opens here.", window.Corner_top_right)
			window.add_reference_mark (a_study, "S3", "P05 Lexicon, south: follows the clicked word.", window.Corner_top_right)
			window.add_reference_mark (heading_label, "P05.1", "Word header: script, transliteration, pronunciation, how often.", window.Corner_top_left)
			window.add_reference_mark (renderings_grid, "P05.4", "Range before ruling: every rendering with its count, before any lexicon's verdict.", window.Corner_top_left)
			window.add_reference_mark (places_grid, "P05.8", "Meanings at every place: the spec puts this in v2; conc.db already has every place.", window.Corner_top_left)
			window.add_reference_mark (status_label, "C15", "Status: database edition: which data files are loaded.", window.Corner_top_left)
		end

	view_menu: SW_MENU
			-- The View menu: the design pills, on or off.
		do
			create Result.make
			if window.reference_marks_shown then
				Result.add_item ("Hide design pills", "Ctrl+Shift+P", True, agent toggle_pills)
			else
				Result.add_item ("Show design pills", "Ctrl+Shift+P", True, agent toggle_pills)
			end
		end

	toggle_pills
			-- Show the design pills, or hide them.
		do
			window.set_reference_marks_shown (not window.reference_marks_shown)
		end

feature {NONE} -- Lookup

	bible: SIMPLE_BIBLE
			-- The engine, opened before the window so its title can name the edition.

	choices: ARRAYED_LIST [BIB_LOOKUP_CHOICE]
			-- What the last lookup found, in the order the centre lists it.

	show_start
			-- The opening state: what to type, or why nothing can be looked up.
		do
			if not bible.is_open then
				look_button.set_enabled (False)
				if attached bible.last_error as al_error then
					centre_note.set_text ({STRING_32} "simple_bible cannot open its content database: " + al_error.message)
				end
			elseif not bible.conc_pack.is_available then
				look_button.set_enabled (False)
				if attached bible.conc_error as al_error then
					centre_note.set_text ({STRING_32} "No concordance: " + al_error.message)
				else
					centre_note.set_text ("No concordance pack was found beside the program.")
				end
			else
				centre_note.set_text ("Type a Hebrew, Greek or English word (bara, logos, love), a verse (Gen 1:1, John 3:16) or a Strong's number (H1254), then press Enter.")
			end
			status_label.set_text (status_text)
		end

	look_up
			-- Run what the lookup box holds, list the choices, and open the word when there is one.
		local
			l_lookup: BIB_LOOKUP
		do
			if bible.is_open and then bible.conc_pack.is_available then
				create l_lookup.make (bible)
				choices := l_lookup.choices_for (lookup_box.text)
				results_grid.set_rows (choices)
				centre_note.set_text (l_lookup.note_text)
				if attached l_lookup.last_verse as al_verse and then not reading_version.is_empty then
					open_reading (al_verse.book, al_verse.chapter, al_verse.verse)
				end
				if choices.count >= 1 and then choices.first.opens_a_word and then (choices.count = 1 or not l_lookup.is_verse_text (lookup_box.text)) then
					open_study (choices.first.lemma_id)
				end
			end
		end

	on_place (a_model: INTEGER)
			-- The reader chose a place in P05.8: open it in the reading pane.
		do
			if a_model >= 1 and a_model <= places.count and then places.i_th (a_model).is_readable then
				open_reading (places.i_th (a_model).book_id, places.i_th (a_model).chapter, places.i_th (a_model).verse)
			end
		end

	on_choice (a_model: INTEGER)
			-- The reader chose a row in the centre: open its word.
		do
			if a_model >= 1 and a_model <= choices.count and then choices.i_th (a_model).opens_a_word then
				open_study (choices.i_th (a_model).lemma_id)
			end
		end

feature {NONE} -- Reading (S1)

	reading_verses: ARRAYED_LIST [BIB_READING_VERSE]
			-- The chapter shown, verse by verse.

	reading_version: STRING_8
			-- The version S1 reads (the picker's choice); empty when content.db holds none.

	reading_book, reading_chapter, reading_verse: INTEGER
			-- The chapter shown and its selected verse (0: none).

	fill_versions
			-- The picker lists every version content.db holds; the King James Version first chosen.
		local
			i, l_chosen: INTEGER
		do
			if bible.is_open then
				across bible.text_reader.versions as ic loop
					version_select.add_option (ic.name)
				end
				from i := 1 until i > bible.text_reader.versions.count loop
					if l_chosen = 0 or else bible.text_reader.versions.i_th (i).code.same_string ("KJV") then
						if l_chosen = 0 or else not bible.text_reader.versions.i_th (l_chosen).code.same_string ("KJV") then
							l_chosen := i
						end
					end
					i := i + 1
				end
				if l_chosen > 0 then
					version_select.select_index (l_chosen)
					reading_version := bible.text_reader.versions.i_th (l_chosen).code
				end
			end
		end

	on_version_change
			-- The reader picked a version: read the same chapter in it.
		do
			if version_select.selected_index >= 1 and version_select.selected_index <= bible.text_reader.versions.count then
				reading_version := bible.text_reader.versions.i_th (version_select.selected_index).code
				if reading_book > 0 then
					open_reading (reading_book, reading_chapter, reading_verse)
				end
			end
		end

	open_reading (a_book, a_chapter, a_verse: INTEGER)
			-- Show chapter `a_chapter' of book `a_book' in S1, verse `a_verse' marked (0: none).
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_not_negative: a_verse >= 0
		local
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_row, l_selected_row, i: INTEGER
			l_mark: SW_MARK
			l_book_name: STRING_32
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
				if bible.books.has_book (a_book) then
					l_book_name := bible.books.book (a_book).name
				else
					l_book_name := {STRING_32} "Book " + a_book.out
				end
				if attached bible.text_reader.version (reading_version) as al_version then
					reading_title.set_text (l_book_name + {STRING_32} " " + a_chapter.out + {STRING_32} "    " + al_version.name)
						-- Align_start already sets a right-to-left cell flush right; Hebrew reads larger.
					if al_version.is_right_to_left then
						reading_view.set_column_scale (1, 1.35)
					else
						reading_view.set_column_scale (1, 1.0)
					end
					reading_note.set_text (numbering_note (al_version))
				end
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
						reading_view.add_note (l_book_name + {STRING_32} " " + a_chapter.out + {STRING_32} " is not in this version.").do_nothing
					end
				end
				if l_selected_row > 0 then
					reading_view.scroll_to_row (l_selected_row)
				end
				previous_button.set_enabled (a_chapter > 1 or a_book > 1)
				next_button.set_enabled (a_chapter < bible.text_reader.last_chapter (reading_version, a_book) or a_book < Last_book)
			end
		end

	numbering_note (a_version: BIB_READING_VERSION): STRING_32
			-- Why a place's number may differ here: the study's corpus numbers verses one way, this
			-- version another (no versification map yet: fold 2026-10-26).
		do
			if study_corpus.same_string ("WLC-MACULA") and not a_version.versification.same_string ("hebrew") then
				Result := {STRING_32} "Places follow the Hebrew Bible's numbering; in a few chapters this version numbers verses differently."
			else
				Result := a_version.caveat.twin
				if Result.count > 140 then
					Result := Result.substring (1, 140) + {STRING_32} "..."
				end
			end
		end

	step_chapter (a_step: INTEGER)
			-- The chapter before (`a_step' = -1) or after (1), across books at their ends.
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
					open_reading (l_book, l_chapter, 0)
				end
			end
		end

	on_verse_click (a_row, a_column: INTEGER)
			-- The reader clicked a verse: mark it, and list its words in P07.
		local
			l_lookup: BIB_LOOKUP
		do
			if a_row >= 1 and a_row <= reading_verses.count then
				open_reading (reading_book, reading_chapter, reading_verses.i_th (a_row).verse)
				if bible.conc_pack.is_available and then bible.books.has_book (reading_book) then
					create l_lookup.make (bible)
					choices := l_lookup.verse_choices (reading_book, reading_chapter, reading_verse)
					results_grid.set_rows (choices)
					centre_note.set_text (l_lookup.note_text)
				end
			end
		end

feature {NONE} -- Word study

	renderings: ARRAYED_LIST [BIB_ENGLISH_GLANCE_ROW]
	places: ARRAYED_LIST [BIB_PLACE_ROW]
	study_lemma: INTEGER_64
	study_corpus: STRING_8
	places_total: INTEGER_64
	is_loading_places: BOOLEAN

	open_study (a_lemma_id: INTEGER_64)
			-- Show headword `a_lemma_id' in the south: heading, how often, renderings, the first page of places.
		require
			id_positive: a_lemma_id > 0
		local
			l_glance: BIB_LIST_RESULT [BIB_ENGLISH_GLANCE_ROW]
			l_view: BIB_WORD_VIEW
			i: INTEGER
		do
			is_loading_places := False
			if attached bible.conc_pack.word_entry (a_lemma_id) as al_entry then
				study_lemma := a_lemma_id
				study_corpus := bible.conc_pack.corpus_of (al_entry.provenance)
				heading_label.set_text (al_entry.translit + {STRING_32} "    " + al_entry.headword)
				if al_entry.pron.is_empty then
					pron_label.set_text ("")
				else
					pron_label.set_text ({STRING_32} "Pronounced " + al_entry.pron)
				end
				create renderings.make (12)
				l_glance := bible.conc_pack.english_glance (a_lemma_id, 4)
				from i := 1 until i > l_glance.count loop
					renderings.extend (l_glance.item (i))
					i := i + 1
				end
				renderings_grid.set_rows (renderings)
				create places.make (Max_page)
				places_total := 0
				if not study_corpus.is_empty then
					l_view := bible.word_lookup.view (a_lemma_id, study_corpus)
					if attached l_view.place_total as al_total and attached l_view.first_places as al_first then
						places_total := al_total.value
						from i := 1 until i > al_first.count loop
							places.extend (al_first.item (i))
							i := i + 1
						end
						often_label.set_text (al_total.value.out.to_string_32 + {STRING_32} " places in the " + bible.conc_pack.corpus_name (study_corpus))
						is_loading_places := places.count < places_total and places.count = Max_page
						if is_loading_places and places_total <= All_at_once then
							from until not is_loading_places loop
								load_next_page
							end
						end
					elseif attached l_view.error as al_error then
						often_label.set_text (al_error.message)
					end
				end
				places_grid.set_rows (places)
				show_places_count
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
			l_page := bible.conc_pack.place_page_after (study_lemma, study_corpus, places.last.token_id, Max_page)
			if l_page.is_success then
				from i := 1 until i > l_page.count loop
					places.extend (l_page.item (i))
					i := i + 1
				end
				is_loading_places := l_page.count = Max_page and places.count < places_total
			else
				is_loading_places := False
			end
		end

	show_places_count
			-- "EVERY PLACE  1,200 of 88,444".
		do
			if places_total > places.count then
				places_title.set_text ({STRING_32} "EVERY PLACE   " + places.count.out + {STRING_32} " of " + places_total.out + {STRING_32} ", loading")
			else
				places_title.set_text ({STRING_32} "EVERY PLACE   " + places.count.out)
			end
		end

feature {NONE} -- Columns

	version_name (a_row: BIB_ENGLISH_GLANCE_ROW): STRING_32
			-- The English Bible's name, never its code (FR-156).
		do
			Result := bible.conc_pack.corpus_name (a_row.bible)
		end

	count_text (a_row: BIB_ENGLISH_GLANCE_ROW): STRING_32
			-- How often, as text.
		do
			Result := a_row.count.out.to_string_32
		end

	status_text: STRING_32
			-- The status bar: what is open (the guide's database editions).
		do
			if bible.is_open then
				Result := {STRING_32} "content.db " + bible.database_edition
				if bible.conc_pack.is_available then
					Result.append ({STRING_32} "   |   concordance: " + bible.conc_pack.edition_label)
				end
			else
				Result := {STRING_32} "No content database open."
			end
		end

feature {NONE} -- Constants

	Key_p: INTEGER = 0x50
			-- The virtual key for P (Ctrl+Shift+P: the design pills).

	Last_book: INTEGER = 66
			-- Revelation, the last of the vault's book ids (FR-105).

	Max_page: INTEGER = 200
			-- Places per page ({BIB_CONC_PACK}.Max_page_size).

	All_at_once: INTEGER_64 = 10000
			-- Up to this many places load before the word shows; longer lists stream on the tick.

	Pages_per_tick: INTEGER = 15
			-- Pages a tick loads (about 3,000 places, a few milliseconds each page).

end
