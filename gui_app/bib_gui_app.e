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
			create lookup_box.make_lookup
			create look_button.make_primary ("Look up", Void)
			create centre_title.make_ui ("ORIGINAL LANGUAGE")
			create centre_note.make_ui ("")
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
			window.set_root (layout)
			lookup_box.set_on_enter (agent look_up)
			look_button.set_on_click (agent look_up)
			results_grid.set_on_select (agent on_choice)
			window.set_on_tick (agent load_more_places)
			show_start
			window.run
			if bible.is_open then
				bible.close
			end
		end

feature {NONE} -- Window

	window: SW_WINDOW
	lookup_box: BIB_LOOKUP_BOX
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
		end

	layout: SW_COLUMN
			-- The guide's Simple layout: toolbar, centre over south, status bar.
		local
			l_toolbar: SW_ROW
			l_centre, l_heading_block, l_places: SW_COLUMN
			l_study: SW_SPLITTER
			l_main: SW_SPLITTER
		do
			create l_toolbar.make
			l_toolbar := l_toolbar.with_gap (8.0)
			l_toolbar.put (lookup_box.growing)
			l_toolbar.put (look_button)

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
			create l_main.make (l_centre, l_study)
			l_main := l_main.with_horizontal
			l_main.set_ratio (0.42)

			create Result.make
			Result := Result.with_padding (12.0).with_gap (10.0)
			Result.put (l_toolbar)
			Result.put (l_main.growing)
			Result.put (status_label.as_muted)
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
				if choices.count >= 1 and then choices.first.opens_a_word and then (choices.count = 1 or not l_lookup.is_verse_text (lookup_box.text)) then
					open_study (choices.first.lemma_id)
				end
			end
		end

	on_choice (a_model: INTEGER)
			-- The reader chose a row in the centre: open its word.
		do
			if a_model >= 1 and a_model <= choices.count and then choices.i_th (a_model).opens_a_word then
				open_study (choices.i_th (a_model).lemma_id)
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

	Max_page: INTEGER = 200
			-- Places per page ({BIB_CONC_PACK}.Max_page_size).

	All_at_once: INTEGER_64 = 10000
			-- Up to this many places load before the word shows; longer lists stream on the tick.

	Pages_per_tick: INTEGER = 15
			-- Pages a tick loads (about 3,000 places, a few milliseconds each page).

end
