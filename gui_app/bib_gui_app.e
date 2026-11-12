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

create {BIB_WINDOW_HARNESS_CLIENT}
	make_harness

feature {NONE} -- Initialization

	make
			-- Open the engine, build the window, run it (or take a snapshot), close the engine.
		do
			build
			if is_snapshot then
				take_snapshot
			else
				if bible.is_open and then ((create {BIB_NOTE_BATCH}.make (bible)).is_pack_stale ((create {BIB_DATA_LOCATION}).notes_folder)
					or (create {BIB_NOTE_BATCH}.make (bible)).is_pack_stale ((create {BIB_DATA_LOCATION}).guides_folder))
				then
						-- notes the installer brought (Larry's, for the alpha testers, 2026-10-30), or a pack
						-- an import could not put in place: built again once the window is painted
					pending_notes_rebuild_ticks := 2
					say ("Bringing the notes up to date...")
				end
				window.run
			end
			shut_down
		end

	make_harness
			-- The whole window built offscreen for the GUI tests (research/23): the data LOCALAPPDATA
			-- names, a user.db of its own emptied first (as a snapshot's), no settings saved, no event
			-- loop. The tests drive it through the harness features, then call `shut_down'.
		do
			is_harness := True
			build
		end

	build
			-- Open the engine and build the window, at Genesis 1:1, the layout and look joined.
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
			if is_offscreen then
					-- A snapshot or the harness never touches the reader's notes: its own user.db,
					-- emptied first.
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
			create highlights_heading.make_ui ("")
			create highlight_reason_label.make_ui ("")
				-- the reason and the answer wrap as they are typed (Larry, 2026-11-01: a long reason ran
				-- out of sight in one line), and the lists' long text reads in full under them
			create highlight_reason_box.make_wrapping_line ("")
			create highlight_detail.make_body ("")
			create prayer_answer_detail.make_body ("")
			create highlight_button.make ("Highlight", Void)
			create highlights_grid.make (100.0)
			create navigator_tabs.make
			create favorites_heading.make_ui ("")
			create favorites_tree.make (100.0)
			create favorites_filter_box.make_single_line ("")
			favorites_filter_box.set_tooltip ("Filter: the favorites and folders whose names hold these words.")
			create favorites_new_folder_button.make ("", Void)
			favorites_new_folder_button.set_glyph ({SW_PAINTER}.Glyph_folder)
			favorites_new_folder_button.set_tooltip ("New folder: inside the folder chosen (or the chosen favorite's), named at once.")
			create favorites_rename_button.make ("", Void)
			favorites_rename_button.set_glyph ({SW_PAINTER}.Glyph_pencil)
			favorites_rename_button.set_tooltip ("Rename the chosen folder or favorite.")
			create favorites_remove_button.make ("", Void)
			favorites_remove_button.set_glyph ({SW_PAINTER}.Glyph_trash)
			favorites_remove_button.set_tooltip ("Remove the chosen folder (and everything in it) or favorite. Restore brings it back.")
			create favorites_restore_button.make ("", Void)
			favorites_restore_button.set_glyph ({SW_PAINTER}.Glyph_refresh)
			favorites_restore_button.set_tooltip ("Restore what Remove took away last.")
			create favorites_state.make
			create favorite_nodes.make (32)
				-- the meme tool (research/25): meme.db beside user.db; its list sorts on a header click and
				-- keeps the favorite memes first (Larry, 2026-11-01)
			create meme_store.make ((create {BIB_DATA_LOCATION}).meme_path)
			create meme_rows.make (0)
			create memes_grid.make (100.0)
			create meme_search_box.make_single_line ("")
			meme_search_box.set_tooltip ("Search the memes: their titles, words, lines, sets and passages.")
			create meme_scope.make
			meme_scope.add_segment ("All")
			meme_scope.add_segment ("Verse read")
			meme_scope.add_segment ("Chapter read")
			create meme_heading.make_ui ("")
			create meme_view.make (300.0)
			create meme_cut_select.make
			create meme_copy_picture_button.make ("Copy picture", Void)
			meme_copy_picture_button.set_tooltip ("Copy picture: the meme's picture (in the cut chosen) on the clipboard, to paste elsewhere.")
			create meme_copy_text_button.make ("Copy description", Void)
			meme_copy_text_button.set_tooltip ("Copy description: the meme's words on the clipboard, to paste with it.")
			create meme_favorite_button.make ("", Void)
			meme_favorite_button.set_glyph ({SW_PAINTER}.Glyph_star)
			create meme_edit_button.make ("Edit...", Void)
			meme_edit_button.set_tooltip ("Edit: change the meme's title, its words (type over them, or paste new ones) and its passages.")
			create meme_add_button.make ("Add meme...", Void)
			meme_add_button.set_tooltip ("Add meme: a picture, its words and its passages, kept in meme.db.")
			create history_grid.make (100.0)
			create history_heading.make_ui ("")
			create history_rows.make (0)
			create session_visits.make (40)
			create history_scope.make
			history_scope.add_segment ("This session")
			history_scope.add_segment ("Kept")
			create history_keep_box.make (Default_history_limit, Min_history_limit, Max_history_limit, Void)
			history_keep_box.set_step (10)
			history_keep_box.set_tooltip ("How many verses the Kept list shows (10 to 1,000). Every visit stays in user.db; this only lists fewer or more.")
			create tag_label.make_ui ("")
			create journal_title_box.make_single_line ("")
			create prayer_title_box.make_single_line ("")
			create prayer_body_box.make ("")
			create prayer_answer_box.make_wrapping_line ("")
			create prayer_add_button.make ("Add", Void)
			create prayer_answered_button.make ("Answered", Void)
			create prayer_open_heading.make_ui ("")
			create prayer_answered_heading.make_ui ("")
			create prayer_open_grid.make (60.0)
			create prayer_answered_grid.make (60.0)
			create prayer_open_rows.make (0)
			create prayer_answered_rows.make (0)
			create memory_add_button.make ("Learn the verse read", Void)
			create memory_heading.make_ui ("")
			create memory_place_label.make_ui ("")
			create memory_text_label.make_ui ("")
			memory_text_label := memory_text_label.with_wrap
			create memory_show_button.make ("Show the verse", Void)
			create memory_again_button.make ("Again", Void)
			create memory_hard_button.make ("Hard", Void)
			create memory_good_button.make ("Good", Void)
			create memory_easy_button.make ("Easy", Void)
			create memory_grid.make (60.0)
			create memory_rows.make (0)
			create memory_due.make (0)
			create journal_body_box.make ("")
			create journal_new_button.make ("New", Void)
			create journal_save_button.make ("Save", Void)
			create journal_delete_button.make ("Delete", Void)
			create journal_restore_button.make ("Restore", Void)
			create journal_heading.make_ui ("")
			create journal_grid.make (60.0)
			create journal_rows.make (0)
			create tag_box.make_single_line ("")
			create tag_button.make ("Tag", Void)
			create tag_names_grid.make (80.0)
			create tag_name_rows.make (0)
			create tagged_heading.make_ui ("")
			create tagged_grid.make (80.0)
			create chosen_tag.make_empty
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
			create go_button.make ({STRING_32} "%/128269/", Void)
			go_button.set_tooltip ("Go: open the reference typed in the box (C4), or search for it when it names no place. Enter does the same.")
			create search_button.make ({STRING_32} "%/128269/", Void)
			search_button.set_tooltip ("Search: every verse the box names (C6) - words, %"phrases%", word*, AND, OR, NOT, Strong's numbers - in the scope beside it. Enter does the same.")
			create version_select.make
			create scope_select.make
			scope_select.add_option ({BIB_SCOPE_NAMES}.Whole_bible_name)
			across (create {BIB_SCOPE_NAMES}).names as ic loop
				scope_select.add_option (ic)
			end
			scope_select.add_option (Scope_this_book_name)
			scope_select.add_option (Scope_writings_name)
			scope_select.add_option (Scope_writings_fuzzy_name)
			scope_select.select_index (1)
			create search_box.make_lookup
			create ask_box.make_lookup
			create ask_button.make ("Ask", Void)
			ask_button.set_tooltip ("Ask: read the request in the box (Enter does the same).")
			ask_box.set_tooltip ("Ask in plain words: %"commentary on Titus 2:12%", %"Psalm 23 in Hebrew%", %"verses with light or darkness%". Enter.")
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
			create focus_button.make ("Focus", Void)
			create back_to_writings_button.make ("Back to results", Void)
			back_to_writings_button.set_tooltip ("Back to the Writings list, at the hit you opened.")
			create library_bar.make
			create origin_button.make ("Back", Void)
			origin_button.set_tooltip ("Back to the verse the commentary is on; the commentary follows the Bible text again.")
			create reading_bar.make
			focus_button.set_tooltip ("Fold the sides so the Bible text has the window (Ctrl+Shift+F); again to bring them back.")
			create reading_view.make (120.0)
			create reading_verses.make (0)
			create reading.make
			create commentary_title.make ("", {SW_PAINTER}.Role_ui, 13.0, True)
			create commentary_tabs.make
			create commentary_view.make (200.0)
			create commentary_reader.make
			create cross_refs_grid.make (60.0)
			create incipit_grid.make (60.0)
			create incipit_verse_button.make ("This verse", Void)
			create incipit_all_nt_button.make ("All, by New Testament", Void)
			create incipit_all_ot_button.make ("All, by Old Testament", Void)
			create chiasm_verse_button.make ("This verse", Void)
			create chiasm_all_button.make ("All structures", Void)
			create chiasm_graded_button.make ("Strong and moderate", Void)
			create chiasm_note.make_ui ("")
			chiasm_note := chiasm_note.with_wrap
			create chiasm_structures_grid.make (110.0)
			create chiasm_structure_rows.make (0)
			create chiasm_ladder_grid.make (60.0)
			create chiasm_member_rows.make (0)
			create incipit_rows.make (0)
			create incipit_note.make_ui ("")
			incipit_note := incipit_note.with_wrap
			create books_grid.make (60.0)
			create book_rows.make (0)
			create chapters_grid.make (60.0)
			create chapter_rows.make (0)
			create book_view.make (200.0)
			create in_books_grid.make (60.0)
			create study_guides_grid.make (60.0)
			create study_guides_rows.make (0)
			create guide_labels.make (16)
			create library_holder.make
			library_holder := library_holder.with_padding (0.0)
			create guides_holder.make
			guides_holder := guides_holder.with_padding (0.0)
			create writings_grid.make (60.0)
			create writing_rows.make (0)
			create writings_note.make_ui ("Choose My writings in the search scope, then search: your commentary, frameworks and books.")
			writings_note := writings_note.with_wrap
			create in_books_rows.make (0)
			create listed_book.make_empty
			create listed_kind.make_empty
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
			create frameworks_grid.make (60.0)
			create framework_rows.make (0)
			create framework_view.make (200.0)
			create places_title.make_ui ("Every place")
			create places_grid.make (60.0)
			create results_note.make_ui ("")
			results_note := results_note.with_wrap
			create results_grid.make (60.0)
			create verses_heading.make_ui ("")
			create verses_grid.make (80.0)
			create verse_hits.make (0)
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
			create center_holder.make
				-- fitting: the Timeline asks for every row (it scrolls itself) and ran under the south
				-- zone at its full height (seen 2026-10-31, hidden in 0.7.41 by the order zones paint in)
			center_holder := center_holder.fitting
			create center_tabs.make
			create bible_page.make
			create parallel_view.make (200.0)
			create pair_view.make (200.0)
			create pair_stack.make (200.0)
			create pair_side_places.make (16)
			create pair_stack_places.make (16)
			build_pair_page
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
				-- The item panels get agents on Current once both exist and every attribute is set (VEVI).
			create highlights_panel.make (user_store, {BIB_USER_STORE}.Kind_highlight, highlights_grid, "Highlight")
			create tagged_panel.make (user_store, {BIB_USER_STORE}.Kind_tag, tagged_grid, "Tag")
			create prayer_open_panel.make (user_store, {BIB_USER_STORE}.Kind_prayer, prayer_open_grid, "Prayer")
			create prayer_answered_panel.make (user_store, {BIB_USER_STORE}.Kind_prayer, prayer_answered_grid, "Prayer")
			create memory_panel.make (user_store, {BIB_USER_STORE}.Kind_memory_card, memory_grid, "Card")
			tagged_panel.set_actions (agent say, agent fill_tags, agent go_to_hub)
			highlights_panel.set_actions (agent say, agent reopen_reading, agent go_to_hub)
			prayer_open_panel.set_actions (agent say, agent fill_prayers, agent read_hub_if_any)
			prayer_answered_panel.set_actions (agent say, agent fill_prayers, agent read_hub_if_any)
			memory_panel.set_actions (agent say, agent fill_memory, agent go_to_hub)
				-- state by agents (research/23 phase 5): Answered follows the open list's choice, and
				-- the strip's dots follow the facts they show
			prayer_open_panel.on_choice (agent (a_id: INTEGER_64) do prayer_answered_button.set_enabled (a_id > 0) end)
				-- the chosen highlight's reason and answered prayer's answer, in full (2026-11-01)
			highlights_panel.on_choice (agent show_highlight_detail)
			prayer_answered_panel.on_choice (agent show_answer_detail)
			notes_listed.subscribe (agent refresh_strip_marks)
			commentary_found.subscribe (agent refresh_strip_marks)
			word_opened.subscribe (agent refresh_strip_marks)
			build_columns
			fill_versions
			mode_switch.add_segment ("Simple")
			mode_switch.add_segment ("Study")
			window.set_root (layout)
			add_menus
			add_accelerators
			wire_events
			show_start
				-- the layout and the look as one state (research/23 phase 2): each view joins, and
				-- joining applies the present; the window's own theme changes (following Windows)
				-- reach the state too
			layout_state.set_dark (window.theme.is_dark)
			layout_state.on_layout (agent arrange)
			layout_state.on_workspace (agent apply_river_workspace)
			layout_state.on_text_scale (agent apply_text_scale)
			layout_state.on_theme (agent apply_theme)
			window.set_on_theme_changed (agent (a_theme: SW_THEME) do layout_state.set_dark (a_theme.is_dark) end)
			results_state.on_change (agent apply_results)
				-- the place read as one state (research/23 phase 3): the version, the chapter, the verse
				-- and the history buttons each join it
			reading.on_version (agent show_version)
			reading.on_chapter (agent show_chapter)
			reading.on_verse (agent show_verse)
			reading.on_history (agent show_trail_buttons)
			show_verse_tools
				-- History (research/24 stage B): every verse touched joins this session's list and
				-- user.db; the Kept list shows as many as the reader chose
			history_keep_box.set_value (history_limit)
			history_keep_box.set_on_change (agent set_history_limit)
			history_scope.set_on_change (agent (a_index: INTEGER) do fill_history end)
			reading.on_verse (agent note_visit)
				-- Favorites (research/24 stage C): one state; the tree and every star join it
			favorites_tree.set_label (agent {BIB_FAVORITE_NODE}.label)
			favorites_tree.set_children (agent favorite_children)
			favorites_tree.set_icon (agent favorite_icon)
			favorites_tree.set_on_select (agent on_favorite)
				-- research/24 stage D3: a selection carried to Favorites (dragged, picked up or
				-- middle-clicked); the tree takes it, and its own lines move by a drag
			favorites_tree.set_folder_test (agent {BIB_FAVORITE_NODE}.is_folder)
			favorites_tree.set_drop_handler (agent favorite_drop_welcome, agent drop_into_favorites)
			favorites_tree.set_row_offer (agent favorite_row_offer)
			framework_view.set_selection_offer (agent document_selection_offer (framework_view))
			book_view.set_selection_offer (agent document_selection_offer (book_view))
			commentary_view.set_selection_offer (agent document_selection_offer (commentary_view))
			reading_view.set_selection_offer (agent verse_selection_offer (reading_view))
			parallel_view.set_selection_offer (agent verse_selection_offer (parallel_view))
			favorites_new_folder_button.set_on_click (agent new_favorite_folder)
			favorites_rename_button.set_on_click (agent rename_chosen_favorite)
			favorites_remove_button.set_on_click (agent remove_chosen_favorite)
			favorites_restore_button.set_on_click (agent restore_favorite)
			favorites_new_folder_button.set_enabled (user_store.is_open)
			favorite_choice_changed.subscribe (agent show_favorite_buttons)
			show_favorite_buttons
			favorites_filter_box.set_on_change (agent fill_favorites)
			navigator_tree.set_icon (agent nav_icon)
			if user_store.has_setting (Favorites_sort_key) and then user_store.setting (Favorites_sort_key).is_integer
				and then user_store.setting (Favorites_sort_key).to_integer >= {BIB_FAVORITE_SET}.By_name
				and then user_store.setting (Favorites_sort_key).to_integer <= {BIB_FAVORITE_SET}.By_created_oldest
			then
				favorites_state.set_sort_order (user_store.setting (Favorites_sort_key).to_integer)
			end
			favorites_state.on_change (agent fill_favorites)
			favorites_state.on_change (agent show_stars)
			favorites_state.on_change (agent mark_quotations)
			reload_favorites
				-- the meme tool: the favorite memes pinned first, the list following the place read when
				-- its scope is the verse or the chapter, the buttons following the chosen meme
			memes_grid.set_pinned (agent meme_starred)
			memes_grid.sort_by (2, False)
			memes_grid.set_hover_card (agent meme_card)
			memes_grid.set_on_select (agent on_meme_row)
			meme_search_box.set_on_change (agent fill_memes)
			meme_scope.set_on_change (agent (a_index: INTEGER) do fill_memes end)
			meme_cut_select.set_on_change (agent show_meme)
			meme_copy_picture_button.set_on_click (agent copy_meme_picture)
			meme_copy_text_button.set_on_click (agent copy_meme_description)
			meme_favorite_button.set_on_click (agent toggle_meme_favorite)
			meme_add_button.set_on_click (agent add_meme_sheet)
			meme_edit_button.set_on_click (agent edit_meme_sheet)
			meme_view.set_on_link_click (agent on_commentary_link)
			meme_choice_changed.subscribe (agent show_meme_buttons)
			show_meme_buttons
			open_memes
			show_meme
			favorites_state.changed.subscribe (agent fill_memes)
			favorites_state.changed.subscribe (agent show_meme_buttons)
			reading.verse_changed.subscribe (agent (a_dummy: detachable ANY) do if meme_scope.selected_index > 1 then fill_memes end end (Void))
				-- Genesis 1:1 selected, so the commentary has its cross-references from the start (Larry:
				-- T5 was empty until a verse was clicked).
			if bible.is_open and then not reading_version.is_empty and then bible.books.has_book (1) then
				go_to (1, 1, 1)
			end
			show_no_word
				-- Typing goes straight into the reference box (keys typed before a click were lost once).
			window.give_focus (reference_box)
		end

feature {NONE} -- Quotations and documents in Favorites (research/24 stage D, 2026-11-01)

	shown_book_document: detachable SIMPLE_DOCUMENT
			-- The document `show_book_place' put in `book_view' (a report or a placeholder since is
			-- another object, and names nothing a favorite can keep).

	shown_book_kind: STRING_32
		attribute
			create Result.make_empty
		end

	shown_book_id: STRING_32
		attribute
			create Result.make_empty
		end

	shown_book_chapter: INTEGER
			-- What `shown_book_document' is: the pack kind, the book and the chapter.

	shown_framework_document: detachable SIMPLE_DOCUMENT
			-- The document `show_framework' put in `framework_view'.

	shown_framework_id: STRING_32
		attribute
			create Result.make_empty
		end

	shown_commentary_document: detachable SIMPLE_DOCUMENT
			-- The document `show_commentary' put in `commentary_view' when it held a verse's commentary.

	shown_commentary_hub: INTEGER_64
			-- That verse.

	Commentary_prefix: STRING_32 = "commentary:"
			-- A favorite's target for a verse's commentary: "commentary:<hub id>".

	document_target (a_view: SW_DOCUMENT_VIEW): detachable STRING_32
			-- The link of the document `a_view' shows, when a favorite can name it.
		do
			if a_view = book_view and then shown_book_document = book_view.document
				and then attached (create {BIB_TEXT_PACKS}).schema_of_kind (shown_book_kind) as al_schema
				and then al_schema.is_book_id (shown_book_id) and then shown_book_chapter >= 0 and then shown_book_chapter <= al_schema.Max_part
			then
				Result := al_schema.link_text (shown_book_id, shown_book_chapter, 0)
			elseif a_view = framework_view and then shown_framework_document = framework_view.document and then not shown_framework_id.is_empty then
				Result := {BIB_FRAMEWORK_SCHEMA}.Link_prefix + shown_framework_id
			elseif a_view = commentary_view and then shown_commentary_document = commentary_view.document and then shown_commentary_hub > 0 then
				Result := Commentary_prefix + shown_commentary_hub.out
			end
		end

	quote_target (a_view: SW_DOCUMENT_VIEW; a_unit: INTEGER): detachable STRING_32
			-- The link to unit `a_unit' of the document `a_view' shows: a book's block, else the document.
		local
			l_block: INTEGER
		do
			Result := document_target (a_view)
			if a_view = book_view and then Result /= Void and then a_unit >= 1 and then a_unit <= a_view.unit_count
				and then attached (create {BIB_TEXT_PACKS}).schema_of_kind (shown_book_kind) as al_schema
			then
					-- one document block per book block, after the book's title (`show_book_place')
				l_block := a_view.unit_block (a_unit) - 1
				if l_block >= 1 and l_block <= al_schema.Max_part and shown_book_chapter >= 1 then
					Result := al_schema.link_text (shown_book_id, shown_book_chapter, l_block)
				end
			end
		end

	document_title (a_view: SW_DOCUMENT_VIEW): STRING_32
			-- What the document `a_view' shows is called: "Zakar, 4. Remembering", a framework's name,
			-- "Commentary on John 3:16".
		do
			create Result.make_empty
			if a_view = book_view then
				across book_rows as ic loop
					if ic.id.same_string (shown_book_id) and ic.pack_kind.same_string_general (shown_book_kind) then
						Result := ic.full_title.twin
					end
				end
				across chapter_rows as ic loop
					if ic.chapter = shown_book_chapter and shown_book_chapter > 0 then
						Result.append ({STRING_32} ", " + ic.title)
					end
				end
				if Result.is_empty then
					Result := shown_book_id.twin
				end
			elseif a_view = framework_view then
				across framework_rows as ic loop
					if ic.id.same_string (shown_framework_id) then
						Result := ic.display_name.twin
					end
				end
				if Result.is_empty then
					Result := shown_framework_id.twin
				end
			elseif shown_commentary_hub > 0 then
				Result := {STRING_32} "Commentary on " + hub_place (shown_commentary_hub)
			end
		end

	document_menu (a_view: SW_DOCUMENT_VIEW; a_panel: INTEGER; a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A document's own items (Larry: the selection kept as a quotation; the document itself
			-- kept), then the pane's.
		do
			if document_target (a_view) /= Void then
				a_menu.add_item ("Add to Favorites as a quotation...", "", user_store.is_open and a_view.has_selection, agent add_quotation_of (a_view))
				a_menu.add_item ("Pick up the quotation", "", user_store.is_open and a_view.has_selection, agent pick_up_quotation (a_view))
				a_menu.add_item ({STRING_32} "Add " + document_title (a_view) + {STRING_32} " to Favorites...", "", user_store.is_open, agent add_document_of (a_view))
				a_menu.add_separator
			end
			pane_menu (a_panel, a_menu, a_px, a_py)
		end

	quotation_of (a_view: SW_DOCUMENT_VIEW): detachable BIB_FAVORITE
			-- `a_view''s selection as a quotation favorite, not yet kept; Void with no selection.
		local
			l_lo_item, l_lo_offset, l_hi_item, l_hi_offset: INTEGER
			l_quote: STRING_32
			l_hub: INTEGER_64
		do
			if a_view.has_selection then
				if a_view.anchor_item < a_view.caret_item or (a_view.anchor_item = a_view.caret_item and a_view.anchor_offset <= a_view.caret_offset) then
					l_lo_item := a_view.anchor_item
					l_lo_offset := a_view.anchor_offset
					l_hi_item := a_view.caret_item
					l_hi_offset := a_view.caret_offset
				else
					l_lo_item := a_view.caret_item
					l_lo_offset := a_view.caret_offset
					l_hi_item := a_view.anchor_item
					l_hi_offset := a_view.anchor_offset
				end
				l_quote := a_view.selected_text
				l_quote.left_adjust
				l_quote.right_adjust
				if a_view = commentary_view then
					l_hub := shown_commentary_hub
				end
				if not l_quote.is_empty and then attached quote_target (a_view, l_lo_item) as al_target then
					create Result.make_quotation (al_target, a_view.selected_text, l_hub, l_hub, "",
						l_lo_item * {BIB_FAVORITE}.Anchor_scale + l_lo_offset, l_hi_item * {BIB_FAVORITE}.Anchor_scale + l_hi_offset,
						quotation_name (l_quote, document_title (a_view)))
				end
			end
		end

	add_quotation_of (a_view: SW_DOCUMENT_VIEW)
			-- Right-click, "Add to Favorites as a quotation": the selection kept, named and foldered in
			-- a sheet.
		do
			if attached quotation_of (a_view) as al_quote then
				open_favorite_sheet (al_quote, "Add to Favorites as a quotation")
			end
		end

	pick_up_quotation (a_view: SW_DOCUMENT_VIEW)
			-- Right-click, "Pick up the quotation": the selection follows the pointer (no button held)
			-- until a click on a Favorites folder keeps it there (research/24 stage D3).
		do
			if attached document_selection_offer (a_view) as al_offer then
				window.start_pick (al_offer.pebble, al_offer.card, window.last_pointer_x, window.last_pointer_y)
			end
		end

	pick_up_verse_quotation (a_view: SW_PARALLEL_TEXT)
			-- The verse menu's "Pick up the quotation".
		do
			if attached verse_selection_offer (a_view) as al_offer then
				window.start_pick (al_offer.pebble, al_offer.card, window.last_pointer_x, window.last_pointer_y)
			end
		end

	document_selection_offer (a_view: SW_DOCUMENT_VIEW): detachable TUPLE [pebble: ANY; card: STRING_32]
			-- A document's selection as a quotation not yet kept, and its name for the card beside
			-- the pointer; Void when nothing can be kept.
		do
			if user_store.is_open and then document_target (a_view) /= Void and then attached quotation_of (a_view) as al_quote then
				Result := [al_quote, al_quote.label]
			end
		end

	verse_selection_offer (a_view: SW_PARALLEL_TEXT): detachable TUPLE [pebble: ANY; card: STRING_32]
			-- The selected part of a verse as a quotation not yet kept.
		do
			if user_store.is_open and then attached verse_quotation_of (a_view) as al_quote then
				Result := [al_quote, al_quote.label]
			end
		end

	favorite_row_offer (a_node: BIB_FAVORITE_NODE): detachable TUPLE [pebble: ANY; card: STRING_32]
			-- A line of the Favorites tree, carried to another folder.
		do
			if user_store.is_open then
				Result := [a_node, a_node.label]
			end
		end

	favorite_drop_welcome (a_pebble: ANY; a_folder: detachable BIB_FAVORITE_NODE): BOOLEAN
			-- A favorite not yet kept, or a line of the tree, into folder `a_folder' (Void: the top
			-- level); a folder never into itself or below itself.
		do
			if user_store.is_open then
				if attached {BIB_FAVORITE} a_pebble as al_new then
					Result := not al_new.is_stored
				elseif attached {BIB_FAVORITE_NODE} a_pebble as al_line then
					if attached al_line.folder as al_moved and then attached a_folder as al_into
						and then attached al_into.folder as al_into_folder
					then
						Result := not favorites_state.is_inside (al_into_folder.id, al_moved.id)
					else
						Result := True
					end
				end
			end
		end

	drop_into_favorites (a_pebble: ANY; a_folder: detachable BIB_FAVORITE_NODE; a_new_folder: BOOLEAN)
			-- Carried into Favorites: a quotation kept, a line moved, in folder `a_folder' (Void: the
			-- top level); on a New folder target, in an "Untitled" folder made there, its name opened
			-- for editing at once (one drop, not two). The source is never changed.
		local
			l_target: INTEGER_64
			l_made: detachable BIB_FAVORITE_FOLDER
			l_node: BIB_FAVORITE_NODE
			l_failed: BOOLEAN
			l_steps: INTEGER
			l_told: detachable STRING_32
			l_named: STRING_32
		do
			create l_named.make_empty
			if user_store.is_open then
				if attached a_folder as al_node and then attached al_node.folder as al_into then
					l_target := al_into.id
				end
				l_steps := favorites_history.position
				if a_new_folder then
					create l_made.make (l_target, "Untitled")
					user_store.add_favorite_folder (l_made)
					if attached user_store.write_error as al_error then
						say (al_error.message)
						l_failed := True
					else
						favorites_history.record ("New folder", agent set_folder_removed (l_made, True), agent set_folder_removed (l_made, False))
						l_target := l_made.id
					end
				end
				if not l_failed then
					if attached {BIB_FAVORITE} a_pebble as al_new then
						is_quiet_keep := True
						keep_favorite (al_new, al_new.label, l_target)
						is_quiet_keep := False
						l_told := {STRING_32} "Added " + al_new.label + {STRING_32} " to "
						l_named := {STRING_32} "Add " + al_new.label
					elseif attached {BIB_FAVORITE_NODE} a_pebble as al_line then
						move_favorite_node (al_line, l_target)
						l_told := {STRING_32} "Moved " + al_line.label + {STRING_32} " to "
						l_named := {STRING_32} "Move " + al_line.label
					end
					if favorites_history.position - l_steps >= 2 then
						favorites_history.join_last (favorites_history.position - l_steps, l_named + {STRING_32} " to a new folder")
					end
					if favorites_history.position > l_steps and then attached l_told as al_told then
						if attached l_made then
							notice_with_undo (al_told + {STRING_32} "a new folder.")
						else
							notice_with_undo (al_told + favorites_place (l_target) + {STRING_32} ".")
						end
					end
					reload_favorites
					if l_target /= 0 and then attached favorites_state.folder (l_target) as al_landed then
						open_favorite_path (al_landed)
					end
					if attached l_made as al_made then
						l_node := folder_node (al_made)
						choose_favorite (l_node)
						open_rename_sheet (l_node)
					end
				end
			end
		end

	undo_favorites
			-- Ctrl+Z, Edit > Undo: the last change to Favorites put back.
		local
			l_name: STRING_32
		do
			if favorites_history.can_undo then
				l_name := favorites_history.undo_name
				favorites_history.undo
				window.toast ({STRING_32} "Undone: " + l_name + {STRING_32} ".", 1)
			end
		end

	redo_favorites
			-- Ctrl+Y (or Ctrl+Shift+Z), Edit > Redo: the change undone last done again.
		local
			l_name: STRING_32
		do
			if favorites_history.can_redo then
				l_name := favorites_history.redo_name
				favorites_history.redo
				window.toast ({STRING_32} "Redone: " + l_name + {STRING_32} ".", 1)
			end
		end

	notice_with_undo (a_text: READABLE_STRING_GENERAL)
			-- A notice of the change just recorded, with an Undo for it.
		do
			window.toast_with_action (a_text, 1, "Undo", agent undo_if_unchanged (favorites_history.changes))
		end

	undo_if_unchanged (a_changes: INTEGER)
			-- A notice's Undo: the change it told of, if nothing changed in Favorites since.
		do
			if favorites_history.changes = a_changes and then favorites_history.can_undo then
				undo_favorites
			else
				window.toast ("Favorites changed after that notice. Ctrl+Z undoes the latest change.", 3)
			end
		end

	set_item_removed (a_item: BIB_FAVORITE; a_removed: BOOLEAN)
			-- A step: a favorite hidden (removed softly) or shown again.
		do
			if user_store.is_open then
				user_store.set_favorite_removed (a_item, a_removed)
				after_favorite_step
			end
		end

	set_folder_removed (a_folder: BIB_FAVORITE_FOLDER; a_removed: BOOLEAN)
			-- A step: a folder hidden with everything in it, or shown again.
		do
			if user_store.is_open then
				user_store.set_favorite_folder_removed (a_folder, a_removed)
				after_favorite_step
			end
		end

	move_item_to (a_item: BIB_FAVORITE; a_folder_id: INTEGER_64)
			-- A step: a favorite into folder `a_folder_id' (0: the top level).
		do
			if user_store.is_open then
				user_store.move_favorite (a_item, a_folder_id)
				after_favorite_step
			end
		end

	move_folder_to (a_folder: BIB_FAVORITE_FOLDER; a_parent_id: INTEGER_64)
			-- A step: a folder into folder `a_parent_id' (0: the top level).
		do
			if user_store.is_open then
				user_store.move_favorite_folder (a_folder, a_parent_id)
				after_favorite_step
			end
		end

	rename_item (a_item: BIB_FAVORITE; a_name: STRING_32)
			-- A step: a favorite's name.
		do
			if user_store.is_open then
				user_store.rename_favorite (a_item, a_name)
				after_favorite_step
			end
		end

	rename_folder (a_folder: BIB_FAVORITE_FOLDER; a_name: STRING_32)
			-- A step: a folder's name.
		do
			if user_store.is_open then
				user_store.rename_favorite_folder (a_folder, a_name)
				after_favorite_step
			end
		end

	after_favorite_step
			-- A step written: say a failure, show the tree as it is now.
		do
			if attached user_store.write_error as al_error then
				say (al_error.message)
			end
			reload_favorites
		end

	open_favorite_path (a_folder: BIB_FAVORITE_FOLDER)
			-- `a_folder' and every folder above it open in the tree, so the line that landed shows.
		local
			l_id: INTEGER_64
			n: INTEGER
		do
			from
				l_id := a_folder.id
			until
				l_id = 0 or n > 64
			loop
				if attached favorites_state.folder (l_id) as al_folder then
					favorites_tree.expand_node (folder_node (al_folder))
					l_id := al_folder.parent_id
				else
					l_id := 0
				end
				n := n + 1
			end
		end

	favorites_place (a_folder_id: INTEGER_64): STRING_32
			-- "Favorites" for the top level, else the folder's path.
		do
			if a_folder_id = 0 then
				Result := {STRING_32} "Favorites"
			else
				Result := favorites_state.folder_path (a_folder_id)
			end
		end

	add_document_of (a_view: SW_DOCUMENT_VIEW)
			-- Right-click, "Add ... to Favorites": the whole document kept.
		do
			if attached document_target (a_view) as al_target then
				open_favorite_sheet (create {BIB_FAVORITE}.make_document (al_target, document_title (a_view)), "Add to Favorites")
			end
		end

	quotation_name (a_quote, a_source: READABLE_STRING_GENERAL): STRING_32
			-- A quotation's first name: its opening words in quotation marks, then its source.
		local
			l_words: STRING_32
		do
			l_words := a_quote.to_string_32
			l_words.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			l_words.replace_substring_all ({STRING_32} "%T", {STRING_32} " ")
			if l_words.count > 48 then
				l_words := l_words.substring (1, 47) + {STRING_32} "%/8230/"
			end
			Result := {STRING_32} "%/8220/" + l_words + {STRING_32} "%/8221/ (" + a_source.to_string_32 + {STRING_32} ")"
		end

	open_favorite_sheet (a_favorite: BIB_FAVORITE; a_title: READABLE_STRING_GENERAL)
			-- A sheet to name `a_favorite' (not yet kept) and choose its folder (the last used).
		local
			l_column: SW_COLUMN
			l_row: SW_ROW
			l_name: SW_TEXT_BOX
			l_folder: SW_SELECT
			l_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER]
			l_add, l_cancel: SW_BUTTON
			i: INTEGER
		do
			create l_name.make_single_line (a_favorite.label)
			create l_folder.make
			l_folder.add_option ("Top level")
			l_folder.select_index (1)
			l_folders := favorites_state.shown_folders_by_path
			from i := 1 until i > l_folders.count loop
				l_folder.add_option (favorites_state.folder_path (l_folders.i_th (i).id))
				if l_folders.i_th (i).id = last_favorite_folder then
					l_folder.select_index (i + 1)
				end
				i := i + 1
			end
			create l_add.make ("Add", agent confirm_favorite_sheet (a_favorite, l_name, l_folder, l_folders))
			create l_cancel.make ("Cancel", agent window.close_sheet)
			create l_column.make
			l_column := l_column.with_padding (16.0).with_gap (10.0)
			l_column.put (create {SW_LABEL}.make_ui (a_title))
			if a_favorite.is_quotation then
				l_column.put (create {SW_LABEL}.make_ui (quotation_name (a_favorite.quote, "")))
			end
			create l_row.make
			l_row.put (create {SW_LABEL}.make_ui ("Name"))
			l_row.put (l_name.growing)
			l_column.put (l_row)
			create l_row.make
			l_row.put (create {SW_LABEL}.make_ui ("Folder"))
			l_row.put (l_folder)
			l_column.put (l_row)
			create l_row.make
			l_row.put (l_add)
			l_row.put (l_cancel)
			l_column.put (l_row)
			window.show_sheet (l_column, 460.0)
			window.give_focus (l_name)
		end

	confirm_favorite_sheet (a_favorite: BIB_FAVORITE; a_name: SW_TEXT_BOX; a_folder: SW_SELECT; a_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER])
			-- Add pressed.
		local
			l_folder_id: INTEGER_64
		do
			if a_folder.selected_index >= 2 and a_folder.selected_index - 1 <= a_folders.count then
				l_folder_id := a_folders.i_th (a_folder.selected_index - 1).id
			end
			window.close_sheet
			keep_favorite (a_favorite, a_name.text, l_folder_id)
		end

	keep_favorite (a_favorite: BIB_FAVORITE; a_name: READABLE_STRING_GENERAL; a_folder_id: INTEGER_64)
			-- `a_favorite' kept in folder `a_folder_id' (0: the top level), named `a_name' when that is
			-- not blank.
		require
			not_kept: not a_favorite.is_stored
			folder_non_negative: a_folder_id >= 0
		local
			l_name: STRING_32
		do
			if user_store.is_open then
				user_store.put_favorite_in (a_favorite, a_folder_id)
				user_store.add_favorite (a_favorite)
				l_name := a_name.to_string_32
				l_name.left_adjust
				l_name.right_adjust
				if user_store.write_error = Void and then not l_name.is_empty and then not l_name.same_string (a_favorite.label) then
					user_store.rename_favorite (a_favorite, l_name)
				end
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					last_favorite_folder := a_folder_id
					reload_favorites
					favorites_history.record ({STRING_32} "Add " + a_favorite.label,
						agent set_item_removed (a_favorite, True), agent set_item_removed (a_favorite, False))
					if not is_quiet_keep then
						notice_with_undo ({STRING_32} "Added " + a_favorite.label + {STRING_32} " to " + favorites_place (a_folder_id) + {STRING_32} ".")
					end
				end
			end
		end

	open_favorite_source (a_item: BIB_FAVORITE)
			-- A document or a quotation chosen: its document opened; a quotation's words selected there
			-- and brought into view.
		local
			l_view: detachable SW_DOCUMENT_VIEW
			l_hub: STRING_32
			l_target: BIB_LINK_TARGET
		do
			if a_item.is_verse_quotation then
				open_verse_quotation (a_item)
			elseif a_item.target.starts_with (Meme_prefix) then
				show_meme_of_favorite (a_item.target)
			elseif a_item.target.starts_with (Commentary_prefix) then
				l_hub := a_item.target.substring (Commentary_prefix.count + 1, a_item.target.count)
				if l_hub.is_integer_64 then
					go_to_hub (l_hub.to_integer_64)
					bring_into_view (commentary_panel, commentary_tabs, 1)
					l_view := commentary_view
				end
			else
				create l_target.make (a_item.target, bible.books)
				on_commentary_link (a_item.target)
				if l_target.is_framework then
					l_view := framework_view
				elseif l_target.is_book then
					l_view := book_view
				end
			end
			if a_item.is_quotation and then attached l_view as al_view then
				window.request_render
				if attached quotation_range (al_view, a_item) as al_range then
					al_view.select_range (al_range.from_item, al_range.from_offset, al_range.to_item, al_range.to_offset)
					al_view.scroll_to (al_view.stacked_scroll_for (al_view.unit_block (al_range.from_item)))
					window.request_render
				else
					say ("The quoted words are not in it any more: the document has changed.")
				end
			end
		end

	quotation_range (a_view: SW_DOCUMENT_VIEW; a_item: BIB_FAVORITE): detachable TUPLE [from_item, from_offset, to_item, to_offset: INTEGER]
			-- Where `a_item''s words stand in `a_view' now: at its anchors when the text there is the
			-- quote, else where its opening words are found (to the end of that text when the quote
			-- runs on); Void when they are nowhere. `a_view' laid out.
		require
			a_quotation: a_item.is_quotation
		local
			fi, fo, ti, t_o, u, p, l_cut: INTEGER
			l_head: STRING_32
		do
			fi := a_item.anchor_item (a_item.anchor_from)
			fo := a_item.anchor_offset (a_item.anchor_from)
			ti := a_item.anchor_item (a_item.anchor_to)
			t_o := a_item.anchor_offset (a_item.anchor_to)
			if fi >= 1 and ti >= fi and ti <= a_view.unit_count and then fo <= a_view.text_of (fi).count and then t_o <= a_view.text_of (ti).count
				and then (fi < ti or fo <= t_o) and then range_text (a_view, fi, fo, ti, t_o).same_string (a_item.quote)
			then
				Result := [fi, fo, ti, t_o]
			else
				l_head := a_item.quote.twin
				l_cut := l_head.index_of ('%N', 1)
				if l_head.index_of ('%T', 1) > 0 and (l_cut = 0 or l_head.index_of ('%T', 1) < l_cut) then
					l_cut := l_head.index_of ('%T', 1)
				end
				if l_cut > 1 then
					l_head := l_head.substring (1, l_cut - 1)
				end
				if not l_head.is_empty then
					from u := 1 until u > a_view.unit_count or Result /= Void loop
						p := a_view.text_of (u).to_string_32.substring_index (l_head, 1)
						if p > 0 then
							if l_head.count = a_item.quote.count then
								Result := [u, p - 1, u, p - 1 + l_head.count]
							else
								Result := [u, p - 1, u, a_view.text_of (u).count]
							end
						end
						u := u + 1
					end
				end
			end
		end

	range_text (a_view: SW_DOCUMENT_VIEW; fi, fo, ti, t_o: INTEGER): STRING_32
			-- The text from offset `fo' of unit `fi' to offset `t_o' of unit `ti', units joined as a
			-- selection's text is (`item_separator').
		require
			ordered: 1 <= fi and fi <= ti and ti <= a_view.unit_count
		local
			k, l_lo, l_hi: INTEGER
		do
			create Result.make (64)
			from k := fi until k > ti loop
				if k = fi then
					l_lo := fo.min (a_view.text_of (k).count)
				else
					l_lo := 0
				end
				if k = ti then
					l_hi := t_o.min (a_view.text_of (k).count)
				else
					l_hi := a_view.text_of (k).count
				end
				if l_lo < l_hi then
					Result.append (a_view.text_of (k).substring (l_lo + 1, l_hi))
				end
				if k < ti then
					Result.append (a_view.item_separator (k))
				end
				k := k + 1
			end
		end

	mark_quotations
			-- Each document view marks what the favorites hold of the document it shows: every quoted
			-- part, and the title of a favorite document (Larry: marked inside the document itself).
			-- `favorites_state' tells, and each view when it shows a document.
		do
			mark_view (book_view)
			mark_view (framework_view)
			mark_view (commentary_view)
			mark_bible_quotations
		end

	mark_view (a_view: SW_DOCUMENT_VIEW)
			-- `a_view''s standing ranges: its document's quoted parts and, for a favorite document, its title.
		do
			a_view.clear_standing_ranges
			if attached document_target (a_view) as al_target then
				window.request_render
				across favorites_state.items as ic loop
					if favorites_state.is_folder_shown (ic.folder_id) then
						if ic.is_quotation and then is_in_document (ic.target, al_target) then
							if attached quotation_range (a_view, ic) as al_range then
								a_view.add_standing_range (al_range.from_item, al_range.from_offset, al_range.to_item, al_range.to_offset)
							end
						elseif ic.is_document and then ic.target.same_string (al_target) and then a_view.unit_count >= 1 then
							a_view.add_standing_range (1, 0, 1, a_view.text_of (1).count)
						end
					end
				end
			end
		end

	is_in_document (a_target, a_document: READABLE_STRING_32): BOOLEAN
			-- Does link `a_target' name document `a_document' or a block of it ("book:zakar/4#12" in
			-- "book:zakar/4")?
		do
			Result := a_target.same_string (a_document) or else a_target.starts_with (a_document + {STRING_32} "#")
		end

	has_kept_link (a_link: READABLE_STRING_32): BOOLEAN
			-- Does a shown document or quotation favorite name `a_link' or something inside it?
		do
			Result := across favorites_state.items as ic some
				(ic.is_document or ic.is_quotation) and then favorites_state.is_folder_shown (ic.folder_id)
				and then (ic.target.same_string (a_link) or ic.target.starts_with (a_link + {STRING_32} "/") or ic.target.starts_with (a_link + {STRING_32} "#"))
			end
		end

	book_starred (a_book: BIB_AUTHOR_BOOK): BOOLEAN
			-- The Author Library's books: is it, or something in it, among the favorites?
		do
			if attached (create {BIB_TEXT_PACKS}).schema_of_kind (a_book.pack_kind) as al_schema and then al_schema.is_book_id (a_book.id) then
				Result := has_kept_link (al_schema.link_text (a_book.id, 0, 0))
			end
		end

	chapter_starred (a_row: TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]): BOOLEAN
			-- The chapters of the book listed: is the chapter, or something in it, among the favorites?
		do
			if attached (create {BIB_TEXT_PACKS}).schema_of_kind (listed_kind) as al_schema and then al_schema.is_book_id (listed_book)
				and then a_row.chapter >= 1 and then a_row.chapter <= al_schema.Max_part
			then
				Result := has_kept_link (al_schema.link_text (listed_book, a_row.chapter, 0))
			end
		end

	framework_starred (a_framework: BIB_FRAMEWORK): BOOLEAN
			-- The frameworks: is it, or a part of it, among the favorites?
		do
			Result := has_kept_link ({BIB_FRAMEWORK_SCHEMA}.Link_prefix + a_framework.id)
		end

feature {NONE} -- Quotations of verses (research/24 stage D2, 2026-11-01)

	Bible_prefix: STRING_32 = "bible:"
			-- A verse quotation's target: "bible:<book>.<chapter>.<verse>" (BIB_LINK_TARGET's form).

	view_unit (a_view: SW_PARALLEL_TEXT; a_row, a_column: INTEGER): INTEGER
			-- The unit of cell `a_row', `a_column' of `a_view' (0: none laid out).
		local
			u: INTEGER
		do
			from u := 1 until u > a_view.unit_count or Result > 0 loop
				if a_view.unit_block (u) = a_row and a_view.unit_column (u) = a_column then
					Result := u
				end
				u := u + 1
			end
		end

	view_version (a_view: SW_PARALLEL_TEXT; a_column: INTEGER): STRING_8
			-- The version column `a_column' of `a_view' shows.
		do
			if a_view = parallel_view and then a_column >= 1 and then a_column <= parallel_codes.count then
				Result := parallel_codes.i_th (a_column)
			else
				Result := reading_version
			end
		end

	verse_quotation_of (a_view: SW_PARALLEL_TEXT): detachable BIB_FAVORITE
			-- The selected part of a verse in the Bible text or Parallel as a quotation favorite (Larry:
			-- an optional way to keep a passage, where the whole verse is not wanted), not yet kept.
		local
			l_lo, l_lo_offset, l_hi, l_hi_offset, l_row, l_end_row: INTEGER
			l_quote: STRING_32
			l_hub: BIB_HUB_ID
			l_version: STRING_8
		do
			if a_view.has_selection and reading.has_place then
				if a_view.anchor_item < a_view.caret_item or (a_view.anchor_item = a_view.caret_item and a_view.anchor_offset <= a_view.caret_offset) then
					l_lo := a_view.anchor_item
					l_lo_offset := a_view.anchor_offset
					l_hi := a_view.caret_item
					l_hi_offset := a_view.caret_offset
				else
					l_lo := a_view.caret_item
					l_lo_offset := a_view.caret_offset
					l_hi := a_view.anchor_item
					l_hi_offset := a_view.anchor_offset
				end
				l_row := a_view.unit_block (l_lo)
				l_end_row := a_view.unit_block (l_hi).max (l_row)
				l_quote := a_view.selected_text
				l_quote.left_adjust
				l_quote.right_adjust
				if not l_quote.is_empty and then l_row >= 1 and then l_end_row <= reading_verses.count then
					create l_hub
					l_version := view_version (a_view, a_view.unit_column (l_lo))
					create Result.make_quotation (Bible_prefix + reading_book.out + "." + reading_chapter.out + "." + reading_verses.i_th (l_row).verse.out,
						a_view.selected_text,
						l_hub.hub_id (reading_book, reading_chapter, reading_verses.i_th (l_row).verse),
						l_hub.hub_id (reading_book, reading_chapter, reading_verses.i_th (l_end_row).verse),
						l_version,
						l_lo * {BIB_FAVORITE}.Anchor_scale + l_lo_offset, l_hi * {BIB_FAVORITE}.Anchor_scale + l_hi_offset,
						quotation_name (l_quote, place_text (reading_book, reading_chapter, reading_verses.i_th (l_row).verse) + {STRING_32} ", " + l_version.to_string_32))
				end
			end
		end

	add_verse_quotation_of (a_view: SW_PARALLEL_TEXT)
			-- The verse menu's "Add to Favorites as a quotation": the selected words kept.
		do
			if attached verse_quotation_of (a_view) as al_quote then
				open_favorite_sheet (al_quote, "Add to Favorites as a quotation")
			end
		end

	open_verse_quotation (a_item: BIB_FAVORITE)
			-- A verse quotation chosen: the verse read in the version it was taken from, its words
			-- selected in the Bible text.
		require
			a_verse_quotation: a_item.is_verse_quotation
		local
			i, l_row, u: INTEGER
		do
			from i := 1 until i > bible.text_reader.versions.count loop
				if bible.text_reader.versions.i_th (i).code.same_string (a_item.version) and then not reading_version.same_string (a_item.version) then
					version_select.select_index (i)
				end
				i := i + 1
			end
			go_to_hub (a_item.hub_id)
			window.request_render
			l_row := verse_row
			u := view_unit (reading_view, l_row, 1)
			if u > 0 and then attached quote_in_unit (reading_view, u, a_item.quote) as al_part then
				reading_view.select_range (u, al_part.lo, u, al_part.hi)
				window.request_render
			end
		end

	quote_in_unit (a_view: SW_DOC_UNITS; a_unit: INTEGER; a_quote: READABLE_STRING_32): detachable TUPLE [lo, hi: INTEGER]
			-- Where `a_quote''s opening words stand in unit `a_unit' (to the unit's end when the quote
			-- runs on into the next verse); Void when they are not there.
		local
			l_head: STRING_32
			p, l_cut: INTEGER
		do
			l_head := a_quote.to_string_32
			l_cut := l_head.index_of ('%T', 1)
			if l_head.index_of ('%N', 1) > 0 and (l_cut = 0 or l_head.index_of ('%N', 1) < l_cut) then
				l_cut := l_head.index_of ('%N', 1)
			end
			if l_cut > 1 then
				l_head := l_head.substring (1, l_cut - 1)
			end
			if not l_head.is_empty then
				p := a_view.text_of (a_unit).to_string_32.substring_index (l_head, 1)
				if p > 0 then
					if l_head.count = a_quote.count then
						Result := [p - 1, p - 1 + l_head.count]
					else
						Result := [p - 1, a_view.text_of (a_unit).count]
					end
				end
			end
		end

	mark_bible_quotations
			-- The Bible text, and Parallel in Study, mark the quoted words of the chapter's verses in the
			-- column of the version each was taken from (`favorites_state' tells, and `show_chapter').
		do
			mark_verse_quotes (reading_view)
			if is_study then
				mark_verse_quotes (parallel_view)
			end
		end

	mark_verse_quotes (a_view: SW_PARALLEL_TEXT)
			-- `a_view''s standing ranges: each shown verse quotation of the chapter read, in its
			-- version's column.
		local
			l_hub: BIB_HUB_ID
			c, i, u: INTEGER
		do
			a_view.clear_standing_ranges
			if reading.has_place then
				window.request_render
				create l_hub
				across favorites_state.items as ic loop
					if ic.is_verse_quotation and then favorites_state.is_folder_shown (ic.folder_id)
						and then l_hub.book_of (ic.hub_id) = reading_book and then l_hub.chapter_of (ic.hub_id) = reading_chapter
					then
						from c := 1 until c > a_view.column_count loop
							if view_version (a_view, c).same_string (ic.version) then
								from i := 1 until i > reading_verses.count loop
									if reading_verses.i_th (i).verse = l_hub.verse_of (ic.hub_id) then
										u := view_unit (a_view, i, c)
										if u > 0 and then attached quote_in_unit (a_view, u, ic.quote) as al_part then
											a_view.add_standing_range (u, al_part.lo, u, al_part.hi)
										end
									end
									i := i + 1
								end
							end
							c := c + 1
						end
					end
				end
			end
		end

feature {NONE} -- The meme tool (research/25, 2026-11-01)

	meme_store: BIB_MEME_STORE
			-- Larry's memes (meme.db beside user.db).

	meme_rows: ARRAYED_LIST [BIB_MEME]
			-- The memes the list shows; the grid sorts them (a header click) and pins the favorites first.

	memes_grid: SW_DATA_GRID [BIB_MEME]
	meme_search_box: SW_TEXT_BOX
	meme_cut_select: SW_SELECT
	meme_scope: SW_SEGMENTED
	meme_heading: SW_LABEL
	meme_view: SW_DOCUMENT_VIEW
	meme_copy_picture_button, meme_copy_text_button, meme_edit_button, meme_favorite_button, meme_add_button: SW_BUTTON
			-- T6's Memes tab.

	meme_card_picture: detachable CAIRO_SURFACE
			-- The one picture in memory: the hovered meme's, decoded for its card and destroyed when the
			-- next card is made (Larry, 2026-11-01: load lazily, only when hovered, never them all).

	chosen_meme: detachable BIB_MEME
			-- The meme the list has chosen.

	meme_choice_changed: SW_EVENT [TUPLE]
			-- Told when the chosen meme changes; the meme's buttons join it (state by agents).
		attribute
			create Result.make
		end

	Memes_tab: INTEGER = 7
			-- T6's Memes page.

	Memes_folder_name: STRING_32 = "Memes"
			-- The Favorites folder a starred meme goes into.

	Meme_prefix: STRING_32 = "meme:"
			-- A meme favorite's target: "meme:<slug>".

	open_memes
			-- meme.db opened, its memes listed (no file: the tab says so).
		do
			if not meme_store.is_open then
				meme_store.open
			end
			fill_memes
		end

	memes_page: SW_COLUMN
			-- One row of search, scope and count; under it the list (a header click sorts; a picture icon
			-- shows the picture when hovered) beside the chosen meme's buttons and words. The south zone
			-- is short, so nothing stands over the list but that one row.
		local
			l_top, l_body, l_buttons: SW_ROW
			l_right: SW_COLUMN
		do
			create l_top.make
			l_top.put (meme_search_box.growing)
			l_top.put (meme_scope)
			l_top.put (meme_heading)
			create l_buttons.make
			l_buttons.put (meme_copy_picture_button)
			l_buttons.put (meme_copy_text_button)
			l_buttons.put (meme_edit_button)
			l_buttons.put (meme_favorite_button)
			l_buttons.put (meme_cut_select)
			l_buttons.put (meme_add_button)
			create l_right.make
			l_right := l_right.with_gap (6.0).fitting
			l_right.put (l_buttons)
			l_right.put (meme_view.growing)
			create l_body.make
			l_body.set_cross_axis ({SW_ROW}.Cross_stretch)
			l_body.put (memes_grid.growing)
			l_body.put (l_right.growing)
			create Result.make
			Result := Result.with_gap (6.0).fitting
			Result.put (l_top)
			Result.put (l_body.growing)
		end

	is_meme_favorite (a_meme: BIB_MEME): BOOLEAN
			-- Is `a_meme' among the favorites (in any shown folder)?
		do
			Result := across favorites_state.items as ic some
				ic.is_document and then ic.target.same_string (Meme_prefix + a_meme.slug) and then favorites_state.is_folder_shown (ic.folder_id)
			end
		end

	meme_matches (a_meme: BIB_MEME; a_words: STRING_32): BOOLEAN
			-- Do `a_words' (lowercase) appear in its title, words, lines, set or passages?
		do
			Result := a_words.is_empty
				or else a_meme.title.as_lower.has_substring (a_words) or else a_meme.description.as_lower.has_substring (a_words)
				or else a_meme.punch.as_lower.has_substring (a_words) or else a_meme.hook.as_lower.has_substring (a_words)
				or else a_meme.trigger_line.as_lower.has_substring (a_words) or else a_meme.meme_set.as_lower.has_substring (a_words)
				or else a_meme.references_text.as_lower.has_substring (a_words)
		end

	fill_memes
			-- The list: every meme the scope takes (all, the verse read, the chapter read) that the search
			-- words match; the grid keeps them in the order chosen with the favorites first.
		local
			l_words: STRING_32
			l_pool: ARRAYED_LIST [BIB_MEME]
			l_place: STRING_32
		do
			l_words := meme_search_box.text.as_lower
			l_words.left_adjust
			l_words.right_adjust
			create l_place.make_empty
			if not meme_store.is_open then
				create l_pool.make (0)
			elseif meme_scope.selected_index = 2 and reading.has_verse then
				l_pool := meme_store.memes_for_verse ((create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse))
				l_place := place_text (reading_book, reading_chapter, reading_verse)
			elseif meme_scope.selected_index >= 2 and reading.has_place then
				l_pool := meme_store.memes_for_chapter (reading_book, reading_chapter)
				l_place := place_text (reading_book, reading_chapter, 0)
			else
				l_pool := meme_store.memes
			end
			create meme_rows.make (l_pool.count)
			across l_pool as ic loop
				if meme_matches (ic, l_words) then
					meme_rows.extend (ic)
				end
			end
			memes_grid.set_rows (meme_rows)
			if attached chosen_meme as al_meme and then not meme_rows.has (al_meme) then
				choose_meme (Void)
			end
			if attached meme_store.last_error as al_error then
				meme_heading.set_text (al_error)
			elseif not meme_store.is_open then
				meme_heading.set_text ("No memes yet: meme.db is not in the data folder. Add meme starts one.")
			elseif l_place.is_empty then
				meme_heading.set_text (meme_rows.count.out.to_string_32 + {STRING_32} " of " + meme_store.memes.count.out + {STRING_32} " memes; the favorites first.")
			else
				meme_heading.set_text (meme_rows.count.out.to_string_32 + {STRING_32} " memes name " + l_place + {STRING_32} "; the favorites first.")
			end
		end

	meme_card (a_meme: BIB_MEME; a_column: INTEGER): detachable SW_HOVER_CARD
			-- Over the picture icon (the first column): the meme's picture in a card, read from meme.db
			-- now and decoded; the picture before it destroyed. Nowhere else: no card.
		local
			l_image: SW_IMAGE
		do
			if a_column = 1 and then attached meme_store.picture (a_meme, {BIB_MEME_SCHEMA}.Feed_variant) as al_png then
				if attached meme_card_picture as al_old then
					al_old.destroy
					meme_card_picture := Void
				end
				meme_card_picture := create {CAIRO_SURFACE}.make_from_png_data (al_png)
				if attached meme_card_picture as al_picture and then al_picture.is_valid then
					create l_image.make_from_surface (al_picture)
					create Result.make (l_image, Meme_card_width)
				end
			end
		end

	Meme_card_width: REAL_64 = 380.0
			-- How wide a meme's picture card opens.

	meme_picture_glyph (a_meme: BIB_MEME): INTEGER
			-- The list's first column: a picture to hover.
		do
			Result := {SW_PAINTER}.Glyph_picture
		end

	meme_no_text (a_meme: BIB_MEME): STRING_32
		do
			create Result.make_empty
		end

	meme_words (a_meme: BIB_MEME): STRING_32
			-- The start of its words, one line, for the Words column.
		do
			Result := a_meme.description.twin
			Result.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			if Result.count > 140 then
				Result := Result.substring (1, 139) + {STRING_32} "%/8230/"
			end
		end

	meme_title (a_meme: BIB_MEME): STRING_32
		do
			Result := a_meme.title
		end

	meme_set_name (a_meme: BIB_MEME): STRING_32
		do
			Result := a_meme.meme_set
		end

	meme_passages_text (a_meme: BIB_MEME): STRING_32
		do
			Result := a_meme.references_text
		end

	on_meme_row (a_row: INTEGER)
			-- Meme `a_row' of the list chosen.
		do
			if a_row >= 1 and a_row <= meme_rows.count then
				choose_meme (meme_rows.i_th (a_row))
			end
		end

	choose_meme (a_meme: detachable BIB_MEME)
			-- The one door to `chosen_meme': its picture and words shown, its cuts offered;
			-- `meme_choice_changed' is told.
		local
			i: INTEGER
		do
			if a_meme /= chosen_meme then
				chosen_meme := a_meme
				meme_cut_select.clear_options
				if attached a_meme as al_meme then
					across al_meme.variants as ic loop
						meme_cut_select.add_option (cut_name (ic.cut))
					end
					if not al_meme.variants.is_empty then
						meme_cut_select.select_index (1)
					end
					from i := 1 until i > meme_rows.count loop
						if meme_rows.i_th (i) = al_meme then
							reselect (memes_grid, i)
						end
						i := i + 1
					end
				end
				show_meme
				meme_choice_changed.call (Void)
			end
		end

	cut_name (a_cut: READABLE_STRING_GENERAL): STRING_32
			-- How a picture's cut reads in the select.
		do
			if a_cut.same_string ("feed") then
				Result := {STRING_32} "Feed picture"
			elseif a_cut.same_string ("typographic") then
				Result := {STRING_32} "Typographic card"
			elseif a_cut.same_string ("square") then
				Result := {STRING_32} "Square"
			elseif a_cut.same_string ("wide") then
				Result := {STRING_32} "Wide (16:9)"
			else
				Result := a_cut.to_string_32
			end
		end

	chosen_cut: STRING_8
			-- The cut the select names for the chosen meme (its feed picture when none).
		do
			Result := {BIB_MEME_SCHEMA}.Feed_variant
			if attached chosen_meme as al_meme and then meme_cut_select.selected_index >= 1 and then meme_cut_select.selected_index <= al_meme.variants.count then
				Result := al_meme.variants.i_th (meme_cut_select.selected_index).cut
			end
		end

	show_meme
			-- The chosen meme's words: title, description, punch, passages (each a link to its place),
			-- credit. Its picture shows only when its icon is hovered (`meme_card').
		local
			l_page: STRING_32
			l_first: BOOLEAN
		do
			if attached chosen_meme as al_meme then
				create l_page.make (al_meme.description.count + 200)
				l_page.append ({STRING_32} "## " + al_meme.title + {STRING_32} "%N%N")
				l_page.append (al_meme.description)
				l_page.append ({STRING_32} "%N%N")
				if not al_meme.punch.is_empty then
					l_page.append ({STRING_32} "**" + al_meme.punch + {STRING_32} "**%N%N")
				end
				if not al_meme.passages.is_empty then
					l_page.append ({STRING_32} "Passages: ")
					l_first := True
					across al_meme.passages as ic loop
						if not l_first then
							l_page.append ({STRING_32} " %/183/ ")
						end
						l_first := False
						l_page.append (passage_link (ic.hub_from, ic.hub_to, ic.wording))
					end
					l_page.append ({STRING_32} "%N%N")
				end
				l_page.append ({STRING_32} "*" + al_meme.credit)
				if not al_meme.license.is_empty then
					l_page.append ({STRING_32} "; " + al_meme.license)
				end
				l_page.append ({STRING_32} "*")
				meme_view.set_document (commentary_reader.read (l_page))
			else
				meme_view.set_document (commentary_reader.read ("Choose a meme: its words and its passages show here. Hover its picture icon to see it. Copy picture and Copy description put either on the clipboard."))
			end
			window.request_render
		end

	passage_link (a_from, a_to: INTEGER_64; a_wording: READABLE_STRING_GENERAL): STRING_32
			-- "[John 3:16](bible:43.3.16)": a passage the reader can click.
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			Result := {STRING_32} "[" + a_wording.to_string_32 + {STRING_32} "]("
				+ (create {BIB_BIBLE_LINK}).range_target_text (l_hub.book_of (a_from), l_hub.chapter_of (a_from), l_hub.verse_of (a_from), l_hub.chapter_of (a_to), l_hub.verse_of (a_to))
				+ {STRING_32} ")"
		end

	show_meme_buttons
			-- Copy and Favorite need a chosen meme; Add meme, meme.db (`meme_choice_changed' tells).
		do
			meme_copy_picture_button.set_enabled (chosen_meme /= Void)
			meme_copy_text_button.set_enabled (chosen_meme /= Void)
			meme_edit_button.set_enabled (chosen_meme /= Void and meme_store.is_open)
			meme_favorite_button.set_enabled (chosen_meme /= Void and user_store.is_open)
			if attached chosen_meme as al_meme and then is_meme_favorite (al_meme) then
				meme_favorite_button.set_tooltip ("A favorite: it stays at the top of the list. Press to take it out of Favorites.")
			else
				meme_favorite_button.set_tooltip ("Favorite: keep this meme at the top of the list (it goes into the Memes folder of Favorites).")
			end
		end

	copy_meme_picture
			-- Copy picture: the chosen meme's picture, in the cut chosen, on the clipboard (Larry: to paste
			-- it elsewhere).
		local
			l_surface: CAIRO_SURFACE
			l_clipboard: SW_CLIPBOARD
		do
			if attached chosen_meme as al_meme and then attached meme_store.picture (al_meme, chosen_cut) as al_png then
				create l_surface.make_from_png_data (al_png)
				if l_surface.is_valid then
					l_surface.flush.do_nothing
					create l_clipboard
					l_clipboard.set_image (l_surface.data, l_surface.width, l_surface.height, l_surface.stride)
					window.toast ({STRING_32} "Copied the picture of " + al_meme.title + {STRING_32} ".", 1)
				else
					say ("That picture does not decode.")
				end
				l_surface.destroy
			end
		end

	edit_meme_sheet
			-- Edit...: the chosen meme's title, its words (type over them, or paste new ones) and its
			-- passages, saved to meme.db (Larry, 2026-11-01).
		local
			l_column: SW_COLUMN
			l_row: SW_ROW
			l_title, l_words, l_passages: SW_TEXT_BOX
			l_save, l_cancel: SW_BUTTON
		do
			if attached chosen_meme as al_meme then
				create l_title.make_single_line (al_meme.title)
				create l_words.make (al_meme.description)
				l_words := l_words.with_min_size (0.0, 220.0)
				create l_passages.make_wrapping_line (passages_line (al_meme))
				create l_save.make ("Save", agent confirm_edit_meme (al_meme, l_title, l_words, l_passages))
				l_save.set_tooltip ("Save the title, the words and the passages to meme.db.")
				create l_cancel.make ("Cancel", agent window.close_sheet)
				create l_column.make
				l_column := l_column.with_padding (16.0).with_gap (8.0)
				l_column.put (create {SW_LABEL}.make_ui ({STRING_32} "Edit the meme: " + al_meme.title))
				l_column.put (create {SW_LABEL}.make_ui ("Title"))
				l_column.put (l_title)
				l_column.put (create {SW_LABEL}.make_ui ("Its words: type over them, or select all (Ctrl+A) and paste new ones"))
				l_column.put (l_words)
				l_column.put (create {SW_LABEL}.make_ui ("Passages, separated by semicolons (John 3:16; Romans 8:1-4; Psalm 23)"))
				l_column.put (l_passages)
				create l_row.make
				l_row.put (l_save)
				l_row.put (l_cancel)
				l_column.put (l_row)
				window.show_sheet (l_column, 680.0)
				window.give_focus (l_words)
			end
		end

	passages_line (a_meme: BIB_MEME): STRING_32
			-- Its passages as an editable line: "John 3:16; Romans 8:1".
		do
			create Result.make (40)
			across a_meme.passages as ic loop
				if not Result.is_empty then
					Result.append ({STRING_32} "; ")
				end
				Result.append (ic.wording)
			end
		end

	confirm_edit_meme (a_meme: BIB_MEME; a_title, a_words, a_passages: SW_TEXT_BOX)
			-- Save pressed: kept, or told what is wrong (the sheet stays open to fix it).
		do
			if save_meme_edit (a_meme, a_title.text, a_words.text, a_passages.text) then
				window.close_sheet
			end
		end

	save_meme_edit (a_meme: BIB_MEME; a_title, a_words, a_passages: READABLE_STRING_GENERAL): BOOLEAN
			-- `a_meme' retitled, its words and passages replaced; True when saved. A blank title, or a
			-- passage that does not read, is told and nothing is changed.
		local
			l_title, l_slug: STRING_32
			l_read: TUPLE [read: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]]; unread: ARRAYED_LIST [STRING_32]]
		do
			l_title := a_title.to_string_32
			l_title.left_adjust
			l_title.right_adjust
			l_read := (create {BIB_PASSAGE_TEXT}.make (bible.books)).ranges (a_passages)
			if l_title.is_empty then
				say ("Give the meme a title.")
			elseif not l_read.unread.is_empty then
				say ({STRING_32} "This does not read as a passage: " + l_read.unread.first)
			elseif meme_store.is_open then
				l_slug := a_meme.slug
				meme_store.edit_meme (a_meme, l_title, a_words, l_read.read)
				if attached meme_store.write_error as al_error then
					say (al_error)
				else
					Result := True
					fill_memes
					choose_meme (meme_store.meme_by_slug (l_slug))
					show_meme
					window.toast ({STRING_32} "Saved " + l_title + {STRING_32} ".", 1)
				end
			end
		end

	copy_meme_description
			-- Copy description: the chosen meme's words on the clipboard.
		do
			if attached chosen_meme as al_meme then
				(create {SW_CLIPBOARD}).set_text (al_meme.description)
				window.toast ({STRING_32} "Copied the words of " + al_meme.title + {STRING_32} ".", 1)
			end
		end

	toggle_meme_favorite
			-- Favorite: the chosen meme into the Memes folder of Favorites (made when missing), or out of
			-- Favorites; the favorites stay at the top of the list (Larry, 2026-11-01).
		local
			l_folder_id: INTEGER_64
			l_folder: BIB_FAVORITE_FOLDER
			l_removed: BOOLEAN
		do
			if attached chosen_meme as al_meme and user_store.is_open then
				across favorites_state.items as ic loop
					if ic.is_document and then ic.target.same_string (Meme_prefix + al_meme.slug) then
						user_store.set_favorite_removed (ic, True)
						l_removed := True
					end
				end
				if not l_removed then
					across favorites_state.folders as ic loop
						if ic.parent_id = 0 and ic.name.same_string (Memes_folder_name) then
							l_folder_id := ic.id
						end
					end
					if l_folder_id = 0 then
						create l_folder.make (0, Memes_folder_name)
						user_store.add_favorite_folder (l_folder)
						l_folder_id := l_folder.id
					end
					keep_favorite (create {BIB_FAVORITE}.make_document (Meme_prefix + al_meme.slug, al_meme.title), "", l_folder_id)
				else
					reload_favorites
				end
				if attached user_store.write_error as al_error then
					say (al_error.message)
				end
			end
		end

	show_meme_of_favorite (a_target: READABLE_STRING_32)
			-- A meme favorite chosen in Favorites: the Memes tab, its meme chosen.
		local
			l_slug: STRING_32
		do
			l_slug := a_target.substring (Meme_prefix.count + 1, a_target.count)
			bring_into_view (results_panel, results_tabs, Memes_tab)
			open_memes
			if meme_scope.selected_index /= 1 then
				meme_scope.select_segment (1)
			end
			meme_search_box.set_text ("")
			fill_memes
			choose_meme (meme_store.meme_by_slug (l_slug))
		end

	add_meme_sheet
			-- Add meme: a title, its words, its passages and its picture (a PNG), kept in meme.db (Larry:
			-- "I will add as I go").
		local
			l_column: SW_COLUMN
			l_row: SW_ROW
			l_title, l_words, l_passages, l_file: SW_TEXT_BOX
			l_pick, l_add, l_cancel: SW_BUTTON
		do
			create l_title.make_single_line ("")
			create l_words.make ("")
			l_words := l_words.with_min_size (0.0, 120.0)
			create l_passages.make_wrapping_line ("")
			create l_file.make_single_line ("")
			create l_pick.make ("Choose...", agent pick_meme_png (l_file))
			create l_add.make ("Add", agent confirm_add_meme (l_title, l_words, l_passages, l_file))
			create l_cancel.make ("Cancel", agent window.close_sheet)
			create l_column.make
			l_column := l_column.with_padding (16.0).with_gap (8.0)
			l_column.put (create {SW_LABEL}.make_ui ("Add a meme"))
			l_column.put (create {SW_LABEL}.make_ui ("Title"))
			l_column.put (l_title)
			l_column.put (create {SW_LABEL}.make_ui ("Its words (what to paste with it)"))
			l_column.put (l_words)
			l_column.put (create {SW_LABEL}.make_ui ("Passages, separated by semicolons (John 3:16; Romans 8:1)"))
			l_column.put (l_passages)
			l_column.put (create {SW_LABEL}.make_ui ("Picture (a PNG file)"))
			create l_row.make
			l_row.put (l_file.growing)
			l_row.put (l_pick)
			l_column.put (l_row)
			create l_row.make
			l_row.put (l_add)
			l_row.put (l_cancel)
			l_column.put (l_row)
			last_meme_sheet := l_column
			window.show_sheet (l_column, 560.0)
			window.give_focus (l_title)
		end

	pick_meme_png (a_file: SW_TEXT_BOX)
			-- Choose...: a PNG file for the Add meme sheet (the sheet comes back with it).
		local
			l_dialog: SW_FILE_DIALOG
		do
			window.close_sheet
			create l_dialog.make_open (documents_folder)
			l_dialog.set_extension_filter ("*.png")
			l_dialog.set_on_accept (agent (a_path: STRING_32; a_box: SW_TEXT_BOX) do a_box.set_text (a_path); window.close_sheet; reopen_meme_sheet end (?, a_file))
			l_dialog.set_on_cancel (agent do window.close_sheet; reopen_meme_sheet end)
			window.show_sheet (l_dialog, 680.0)
		end

	reopen_meme_sheet
			-- The Add meme sheet back after the file dialog (its boxes keep what was typed).
		do
			if attached last_meme_sheet as al_sheet then
				window.show_sheet (al_sheet, 560.0)
			end
		end

	last_meme_sheet: detachable SW_COLUMN
			-- The Add meme sheet last shown.

	confirm_add_meme (a_title, a_words, a_passages, a_file: SW_TEXT_BOX)
			-- Add pressed: the picture read and checked, the passages read; kept, or told what is wrong.
		local
			l_title: STRING_32
			l_read: TUPLE [read: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]]; unread: ARRAYED_LIST [STRING_32]]
			l_file: RAW_FILE
			l_png: MANAGED_POINTER
		do
			l_title := a_title.text.twin
			l_title.left_adjust
			l_title.right_adjust
			l_read := (create {BIB_PASSAGE_TEXT}.make (bible.books)).ranges (a_passages.text)
			if l_title.is_empty then
				say ("Give the meme a title.")
			elseif not l_read.unread.is_empty then
				say ({STRING_32} "This does not read as a passage: " + l_read.unread.first)
			elseif a_file.text.is_empty or else not (create {SIMPLE_FILE}.make (a_file.text)).is_file then
				say ("Choose the meme's picture (a PNG file).")
			else
				create l_file.make_open_read (a_file.text)
				create l_png.make (l_file.count.max (1))
				l_file.read_to_managed_pointer (l_png, 0, l_file.count)
				l_file.close
				if not meme_store.schema.is_png (l_png) then
					say ("That file is not a PNG picture.")
				else
					keep_meme (l_title, a_words.text, l_png, l_read.read)
				end
			end
		end

	keep_meme (a_title, a_words: READABLE_STRING_GENERAL; a_png: MANAGED_POINTER;
			a_passages: ARRAYED_LIST [TUPLE [hub_from, hub_to: INTEGER_64; wording: STRING_32]])
			-- A new meme kept in meme.db (made from the schema when there is none yet), listed and chosen.
		require
			a_png_picture: meme_store.schema.is_png (a_png)
		do
			if not meme_store.is_open then
				start_meme_file
			end
			if meme_store.is_open then
				meme_store.add_meme (a_title, a_words, a_png, a_passages)
				if attached meme_store.write_error as al_error then
					say (al_error)
				else
					window.close_sheet
					fill_memes
					choose_meme (meme_store.memes.last)
					window.toast ({STRING_32} "Added the meme " + a_title.to_string_32 + {STRING_32} ".", 1)
				end
			end
		end

	start_meme_file
			-- A first meme.db, empty, from the schema (no memes were installed).
		local
			l_db: SIMPLE_SQL_DATABASE
		do
			if not (create {SIMPLE_FILE}.make (meme_store.path)).exists then
				create l_db.make (meme_store.path)
				across meme_store.schema.schema_statements as ic loop
					l_db.execute (ic)
				end
				l_db.execute_with_args ("INSERT INTO meta VALUES ('pack_kind', ?), ('title', ?), ('author', ?), ('builder', 'Simple Bible')",
					<<meme_store.schema.Pack_kind, meme_store.schema.Pack_title, meme_store.schema.Pack_author>>)
				l_db.close
			end
			meme_store.open
		end

	copy_folder_references (a_folder: BIB_FAVORITE_FOLDER)
			-- A folder's right-click "Copy references": every passage and verse quotation in it and its
			-- folders, in the tree's order, one a line, on the clipboard (Larry, 2026-11-01).
		local
			l_lines: STRING_32
		do
			create l_lines.make (256)
			append_folder_references (a_folder.id, l_lines)
			if l_lines.is_empty then
				say ({STRING_32} "No passages in " + a_folder.name + {STRING_32} ".")
			else
				(create {SW_CLIPBOARD}).set_text (l_lines)
				window.toast ({STRING_32} "Copied the references in " + a_folder.name + {STRING_32} ".", 1)
			end
		end

	append_folder_references (a_folder_id: INTEGER_64; a_lines: STRING_32)
			-- The references of folder `a_folder_id''s favorites, then of its folders, appended to `a_lines'.
		do
			across favorites_state.child_items (a_folder_id) as ic loop
				if ic.is_passage or ic.is_verse_quotation then
					if not a_lines.is_empty then
						a_lines.append ({STRING_32} "%N")
					end
					a_lines.append (passage_text (ic.hub_id, ic.end_hub_id, ic.is_whole_chapter))
				end
			end
			across favorites_state.child_folders (a_folder_id) as ic loop
				append_folder_references (ic.id, a_lines)
			end
		end

	passage_text (a_from, a_to: INTEGER_64; a_whole_chapter: BOOLEAN): STRING_32
			-- "John 3:16", "Romans 8:28-30", "John 3:16-4:2", or "John 3" for a whole chapter.
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			if a_whole_chapter then
				Result := place_text (l_hub.book_of (a_from), l_hub.chapter_of (a_from), 0)
			else
				Result := place_text (l_hub.book_of (a_from), l_hub.chapter_of (a_from), l_hub.verse_of (a_from))
				if a_to > a_from then
					if l_hub.chapter_of (a_to) = l_hub.chapter_of (a_from) then
						Result.append ({STRING_32} "-" + l_hub.verse_of (a_to).out)
					else
						Result.append ({STRING_32} "-" + l_hub.chapter_of (a_to).out + {STRING_32} ":" + l_hub.verse_of (a_to).out)
					end
				end
			end
		end

	meme_starred (a_meme: BIB_MEME): BOOLEAN
			-- The memes list: a favorite meme wears the star.
		do
			Result := is_meme_favorite (a_meme)
		end

feature {BIB_WINDOW_HARNESS_CLIENT} -- The window harness (research/23, 2026-10-31: GUI risks shown failing before their fixes)

	is_harness: BOOLEAN
			-- Was the window built by `make_harness'?

	is_offscreen: BOOLEAN
			-- A snapshot or the harness: no settings saved, a user.db of its own.
		do
			Result := is_snapshot or is_harness
		end

	shut_down
			-- Close the reader's stores and the engine.
		do
			if user_store.is_open then
				user_store.close
			end
			if bible.is_open then
				bible.close
			end
		end

	harness_state: BIB_LAYOUT_STATE
			-- The layout and the look, to drive as the reader would.
		do
			Result := layout_state
		end

	harness_selection: BIB_TIME_PLACE_SELECTION
			-- The Timeline and the Atlas's shared selection.
		do
			Result := selection
		end

	harness_render
			-- One frame, as after any input.
		do
			window.request_render
		end

	harness_go_to (a_book, a_chapter, a_verse: INTEGER)
			-- Read that place, as the reference box would.
		do
			go_to (a_book, a_chapter, a_verse)
		end

	harness_toggle_focus
			-- Ctrl+Shift+F.
		do
			toggle_focus_reading
		end

	harness_show_timeline
			-- The Timeline tab and its Atlas.
		do
			show_timeline
		end

	harness_select_tab (a_index: INTEGER)
			-- A center tab, as a click on it would.
		do
			center_tabs.select_tab (a_index)
		end

	harness_pair_open: BOOLEAN
			-- Is the Side by side window open?
		do
			Result := attached pair_float as al_float and then al_float.is_open
		end

	harness_close_pair
			-- Close the Side by side window, as its close box would.
		do
			close_pair
		end

	harness_toggle_pair_layout
			-- The window's layout switch, as a click on it would.
		do
			toggle_pair_layout
		end

	harness_pair_over_under: BOOLEAN
			-- Does the window show the passages over and under?
		do
			Result := pair_over_under
		end

	harness_stack_rows: INTEGER
			-- Rows in the over-and-under view, its notes included.
		do
			Result := pair_stack.row_count
		end

	harness_stack_has_text (a_row: INTEGER): BOOLEAN
			-- Does the over-and-under view's row `a_row' hold text?
		require
			valid_row: a_row >= 1 and a_row <= harness_stack_rows
		do
			Result := pair_stack.cell_marks (a_row, 1).text_count > 0
		end

	harness_show_incipit
			-- The Incipit tab, listing the verse read's links.
		do
			commentary_tabs.select_tab (Incipit_tab)
			set_incipit_mode (Incipit_mode_verse)
		end

	harness_incipit_count: INTEGER
			-- Rows the Incipit tab lists.
		do
			Result := incipit_rows.count
		end

	harness_show_pair (a_index: INTEGER)
			-- Side by side for Incipit row `a_index', as its right-click item would.
		require
			valid: a_index >= 1 and a_index <= harness_incipit_count
		do
			show_pair (incipit_rows.i_th (a_index))
		end

	harness_pair_rows: INTEGER
			-- Rows in Side by side, its note included.
		do
			Result := pair_view.row_count
		end

	harness_pair_has_text (a_row, a_column: INTEGER): BOOLEAN
			-- Does Side by side's cell `a_row', `a_column' hold text?
		require
			valid_row: a_row >= 1 and a_row <= harness_pair_rows
			valid_column: a_column = 1 or a_column = 2
		do
			Result := pair_view.cell_marks (a_row, a_column).text_count > 0
		end

	harness_east_fraction: REAL_64
			-- The east zone's width as a share of the window.
		do
			Result := dock.fraction (dock.Zone_east)
		end

	harness_set_east_fraction (a_fraction: REAL_64)
			-- The reader dragging the east zone's edge.
		do
			dock.set_fraction (dock.Zone_east, a_fraction)
		end

	harness_notes_heading: STRING_32
			-- What the Notes pane's heading says.
		do
			Result := notes_heading.text
		end

	harness_smaller_enabled: BOOLEAN
			-- Is the smaller-text button enabled?
		do
			Result := smaller_button.is_enabled
		end

	harness_larger_enabled: BOOLEAN
		do
			Result := larger_button.is_enabled
		end

	harness_focus_label: STRING_32
			-- What the Focus button says.
		do
			Result := focus_button.label
		end

	harness_dark_switch_on: BOOLEAN
		do
			Result := dark_switch.is_on
		end

	harness_window_dark: BOOLEAN
		do
			Result := window.theme.is_dark
		end

	harness_search (a_text: READABLE_STRING_GENERAL)
			-- Type `a_text' in the search box and press Enter.
		do
			search_box.set_text (a_text)
			on_search
		end

	harness_close_results
			-- A press on the results panel's Close button.
		do
			if attached close_results_button.on_click as al_click then
				al_click.call (Void)
			end
		end

	harness_results_visible: BOOLEAN
			-- Is the Search Results panel shown?
		do
			Result := dock.is_panel_visible (results_panel)
		end

	harness_results_marked: BOOLEAN
			-- Has the Search Results panel its dot (results to show)?
		do
			Result := dock.is_panel_marked (results_panel)
		end

	harness_results_count: INTEGER
			-- Choices and verses the results panel lists.
		do
			Result := choices.count + verse_hits.count
		end

	harness_window_menu_enabled (a_label: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the Window menu's item `a_label' enabled, as the menu would open now?
		do
			across window_menu.items as ic loop
				if ic.label.same_string_general (a_label) then
					Result := ic.enabled
				end
			end
		end

	harness_verses_heading: STRING_32
			-- What the verses list's heading says.
		do
			Result := verses_heading.text
		end

	harness_add_note (a_text: READABLE_STRING_GENERAL)
			-- Write `a_text' in the new-note box and press Add note.
		do
			new_note_box.set_text (a_text)
			add_note
		end

	harness_delete_note (a_index: INTEGER)
			-- Delete note `a_index' of the list.
		do
			delete_note_at (a_index)
		end

	harness_notes_marked: BOOLEAN
			-- Has the Notes panel its dot (the chapter has notes)?
		do
			Result := dock.is_panel_marked (notes_panel)
		end

	harness_add_prayer (a_title, a_body: READABLE_STRING_GENERAL)
			-- Write a prayer's title and request and press Add.
		do
			prayer_title_box.set_text (a_title)
			prayer_body_box.set_text (a_body)
			add_prayer
		end

	harness_choose_open_prayer (a_row: INTEGER)
			-- Click open prayer `a_row'.
		do
			prayer_open_grid.select_model_row (a_row)
		end

	harness_answered_enabled: BOOLEAN
			-- Is the Answered button enabled?
		do
			Result := prayer_answered_button.is_enabled
		end

	harness_click_verse (a_row: INTEGER)
			-- Click row `a_row' of the Bible tab (away from any word).
		do
			on_verse_click (a_row, 1)
		end

	harness_bible_cell (a_row: INTEGER): ANY
			-- The text object of row `a_row' in the Bible tab (a rebuilt chapter makes new ones).
		do
			Result := reading_view.cell (a_row, 1)
		end

	harness_parallel_cell (a_row: INTEGER): ANY
			-- The text object of row `a_row', first column, in Parallel.
		do
			Result := parallel_view.cell (a_row, 1)
		end

	harness_highlight_rows: ANY
			-- The list the Highlights tab shows (read again, it is a new list).
		do
			Result := highlights_panel.rows
		end

	harness_verse_selected (a_row: INTEGER): BOOLEAN
			-- Does row `a_row' of the Bible tab carry the selected-verse mark?
		do
			Result := across reading_view.cell_marks (a_row, 1).reasons as ic some ic.same_string ("selected verse") end
		end

	harness_parallel_verse_selected (a_row: INTEGER): BOOLEAN
			-- Does row `a_row' of Parallel, first column, carry the selected-verse mark?
		do
			Result := across parallel_view.cell_marks (a_row, 1).reasons as ic some ic.same_string ("selected verse") end
		end

	harness_step_history (a_step: INTEGER)
			-- Back (-1) or Forward (1).
		do
			move_in_history (a_step)
		end

	harness_back_enabled: BOOLEAN
		do
			Result := back_button.is_enabled
		end

	harness_forward_enabled: BOOLEAN
		do
			Result := forward_button.is_enabled
		end

	harness_previous_enabled: BOOLEAN
		do
			Result := previous_button.is_enabled
		end

	harness_next_enabled: BOOLEAN
		do
			Result := next_button.is_enabled
		end

	harness_go_menu_enabled (a_label: READABLE_STRING_GENERAL): BOOLEAN
			-- Is the Go menu's item `a_label' enabled, as the menu would open now?
		do
			across go_menu.items as ic loop
				if ic.label.same_string_general (a_label) then
					Result := ic.enabled
				end
			end
		end

	harness_is_at (a_book, a_chapter, a_verse: INTEGER): BOOLEAN
			-- Is that the place read?
		do
			Result := reading_book = a_book and reading_chapter = a_chapter and reading_verse = a_verse
		end

	harness_history_scope (a_index: INTEGER)
			-- This session (1) or Kept (2).
		do
			history_scope.select_segment (a_index)
		end

	harness_history_count: INTEGER
			-- Rows the History tab lists.
		do
			Result := history_rows.count
		end

	harness_history_is (a_row, a_book, a_chapter, a_verse: INTEGER): BOOLEAN
			-- Is row `a_row' of the History tab that verse?
		do
			Result := a_row >= 1 and a_row <= history_rows.count and then history_rows.i_th (a_row).hub_id = (create {BIB_HUB_ID}).hub_id (a_book, a_chapter, a_verse)
		end

	harness_set_history_limit (a_limit: INTEGER)
			-- Set the Kept list's length.
		do
			set_history_limit (a_limit)
		end

	harness_history_keep_value: INTEGER
			-- What the Kept list's length box shows.
		do
			Result := history_keep_box.value
		end

	harness_add_favorite (a_kind, a_end_verse: INTEGER; a_name: READABLE_STRING_GENERAL; a_folder_id: INTEGER_64)
			-- Add the place read as the Add sheet would: verse (1), verses through `a_end_verse' (2),
			-- whole chapter (3).
		do
			add_favorite (a_kind, a_end_verse, a_name, a_folder_id)
		end

	harness_new_folder (a_name: READABLE_STRING_GENERAL): INTEGER_64
			-- New folder, then its name typed in the sheet that opens; its id.
		do
			new_favorite_folder
			window.close_sheet
			if attached favorites_tree.selected_node as al_node and then attached al_node.folder as al_folder then
				rename_favorite_node (al_node, a_name)
				Result := al_folder.id
			end
		end

	harness_dispatch (a_type, a_x, a_y: INTEGER)
			-- A pointer or key event, as the native queue delivers it (press 2, release 10, drag 9,
			-- move 13, heartbeat 7, middle-click 17, key 3).
		do
			window.dispatch (a_type, a_x, a_y)
		end

	harness_favorites_tree: SW_TREE [BIB_FAVORITE_NODE]
		do
			Result := favorites_tree
		end

	harness_show_favorites
			-- The Navigator's Favorites tab.
		do
			navigator_tabs.select_tab (Favorites_tab)
			window.request_render
		end

	harness_sheet_open: BOOLEAN
			-- Is a sheet up (the rename sheet a new folder opens)?
		do
			Result := window.has_sheet
		end

	harness_undo_name: STRING_32
			-- What Undo would put back; empty for nothing.
		do
			create Result.make_empty
			if favorites_history.can_undo then
				Result := favorites_history.undo_name
			end
		end

	harness_key (a_vk: INTEGER; a_ctrl, a_shift: BOOLEAN)
			-- A key with its modifiers, as the keyboard would send it.
		do
			window.simulate_key_down (a_vk, a_ctrl, False, a_shift)
		end

	harness_notice_undo
			-- A click on the newest notice's Undo.
		do
			window.request_render
			if not window.toast_action_spots.is_empty and then attached window.toast_action_spots.first.toast.act as al_act then
				al_act.call
			end
		end

	harness_close_sheet
			-- The open sheet closed, as its Cancel would.
		do
			window.close_sheet
		end

	harness_give_focus_to_filter
			-- The keyboard to the Favorites filter box (a text box).
		do
			window.give_focus (favorites_filter_box)
		end

	harness_is_picking: BOOLEAN
		do
			Result := window.is_picking
		end

	harness_pick_card: STRING_32
		do
			Result := window.pick_card
		end

	harness_pick_up (a_which: INTEGER)
			-- "Pick up the quotation" from a menu: 1 to 3 that document view, 4 the Bible text.
		do
			if a_which = 4 then
				pick_up_verse_quotation (reading_view)
			else
				pick_up_quotation (harness_document_view (a_which))
			end
		end

	harness_folder_item_count (a_folder_id: INTEGER_64): INTEGER
			-- Favorites kept directly in folder `a_folder_id' (0: the top level).
		do
			Result := favorites_state.child_items (a_folder_id).count
		end

	harness_folder_ids_in (a_folder_id: INTEGER_64): ARRAYED_LIST [INTEGER_64]
			-- The folders directly in folder `a_folder_id'.
		do
			create Result.make (4)
			across favorites_state.child_folders (a_folder_id) as ic loop
				Result.extend (ic.id)
			end
		end

	harness_favorite_roots: INTEGER
			-- Lines at the top of the Favorites tree.
		do
			Result := favorites_tree.roots.count
		end

	harness_favorite_root_label (a_index: INTEGER): STRING_32
			-- Line `a_index' at the top of the tree.
		do
			Result := favorites_tree.roots.i_th (a_index).label
		end

	harness_choose_favorite_root (a_index: INTEGER)
			-- Click line `a_index' at the top of the tree.
		do
			choose_favorite (favorites_tree.roots.i_th (a_index))
		end

	harness_remove_chosen_favorite
		do
			remove_chosen_favorite
		end

	harness_restore_favorite
		do
			restore_favorite
		end

	harness_filter_favorites (a_words: READABLE_STRING_GENERAL)
			-- Type `a_words' in the filter box.
		do
			favorites_filter_box.set_text (a_words)
			fill_favorites
		end

	harness_verse_starred (a_row: INTEGER): BOOLEAN
			-- Does row `a_row' of the Bible tab wear the star?
		do
			Result := reading_view.is_row_starred (a_row)
		end

	harness_chapter_starred (a_book, a_chapter: INTEGER): BOOLEAN
			-- Is that chapter among the favorites (its star in the Books tree)?
		do
			Result := favorites_state.is_chapter_starred (a_book, a_chapter)
		end

	harness_show_first_book (a_chapter: INTEGER)
			-- The Author Library's first book at chapter `a_chapter'.
		do
			if not book_rows.is_empty then
				show_book_place (book_rows.first.pack_kind, book_rows.first.id, a_chapter, 0)
			end
		end

	harness_book_count: INTEGER
		do
			Result := book_rows.count
		end

	harness_books_grid: SW_DATA_GRID [BIB_AUTHOR_BOOK]
			-- The Author Library's books (or series).
		do
			Result := books_grid
		end

	harness_chapters_grid: SW_DATA_GRID [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]
			-- The chosen book's chapters (a series' essays).
		do
			Result := chapters_grid
		end

	harness_show_book (a_kind, a_book: READABLE_STRING_GENERAL)
			-- Book (or series) `a_book' of the `a_kind' pack listed, its first chapter read.
		do
			show_book_place (a_kind, a_book, 1, 0)
		end

	harness_favorite_target (a_index: INTEGER): STRING_32
			-- The target of the favorite at line `a_index' at the top of the tree.
		do
			create Result.make_empty
			if attached favorites_tree.roots.i_th (a_index).item as al_item then
				Result := al_item.target
			end
		end

	harness_favorites_heading: STRING_32
		do
			Result := favorites_heading.text
		end

	harness_quote_verse_selection (a_folder_id: INTEGER_64)
			-- The verse menu's "Add to Favorites as a quotation" on the Bible text's selection, the
			-- sheet accepted as it opens.
		do
			if attached verse_quotation_of (reading_view) as al_quote then
				keep_favorite (al_quote, "", a_folder_id)
			end
		end

	harness_bible_view: SW_PARALLEL_TEXT
			-- The Bible tab.
		do
			Result := reading_view
		end

	harness_meme_card (a_slug: READABLE_STRING_GENERAL): detachable SW_HOVER_CARD
			-- The card hovering that meme's picture icon would open.
		do
			if attached meme_store.meme_by_slug (a_slug) as al_meme then
				Result := meme_card (al_meme, 1)
			end
		end

	harness_card_picture: detachable CAIRO_SURFACE
			-- The one picture in memory.
		do
			Result := meme_card_picture
		end

	harness_edit_meme (a_slug, a_title, a_words, a_passages: READABLE_STRING_GENERAL): BOOLEAN
			-- Edit...'s sheet filled in and saved.
		do
			if attached meme_store.meme_by_slug (a_slug) as al_meme then
				Result := save_meme_edit (al_meme, a_title, a_words, a_passages)
			end
		end

	harness_meme_words (a_slug: READABLE_STRING_GENERAL): STRING_32
			-- That meme's words as kept.
		do
			create Result.make_empty
			if attached meme_store.meme_by_slug (a_slug) as al_meme then
				Result := al_meme.description
			end
		end

	harness_meme_passages (a_slug: READABLE_STRING_GENERAL): STRING_32
			-- That meme's passages as Edit shows them.
		do
			create Result.make_empty
			if attached meme_store.meme_by_slug (a_slug) as al_meme then
				Result := passages_line (al_meme)
			end
		end

	harness_meme_title (a_slug: READABLE_STRING_GENERAL): STRING_32
		do
			create Result.make_empty
			if attached meme_store.meme_by_slug (a_slug) as al_meme then
				Result := al_meme.title
			end
		end

	harness_pill_tip (a_code: READABLE_STRING_GENERAL): STRING_32
			-- The tip of the design pill `a_code' on the board shown, or empty.
		do
			create Result.make_empty
			across window.reference_marks as ic loop
				if ic.code.same_string_general (a_code) then
					Result := ic.tip
				end
			end
		end

	harness_meme_count: INTEGER
			-- Memes the list shows.
		do
			Result := meme_rows.count
		end

	harness_meme_scope (a_index: INTEGER)
			-- All (1), Verse read (2), Chapter read (3).
		do
			meme_scope.select_segment (a_index)
		end

	harness_search_memes (a_words: READABLE_STRING_GENERAL)
		do
			meme_search_box.set_text (a_words)
			fill_memes
		end

	harness_choose_meme (a_slug: READABLE_STRING_GENERAL)
		do
			choose_meme (meme_store.meme_by_slug (a_slug))
		end

	harness_meme_shown_first: STRING_32
			-- The slug of the meme the list shows first.
		do
			create Result.make_empty
			if not memes_grid.view.is_empty then
				Result := memes_grid.rows.i_th (memes_grid.view.first).slug
			end
		end

	harness_lists_meme (a_slug: READABLE_STRING_GENERAL): BOOLEAN
		do
			Result := across meme_rows as ic some ic.slug.same_string_general (a_slug) end
		end

	harness_toggle_meme_favorite
		do
			toggle_meme_favorite
		end

	harness_copy_meme_picture
		do
			copy_meme_picture
		end

	harness_copy_meme_description
		do
			copy_meme_description
		end

	harness_copy_folder_references (a_folder_id: INTEGER_64)
		do
			if attached favorites_state.folder (a_folder_id) as al_folder then
				copy_folder_references (al_folder)
			end
		end

	harness_framework_count: INTEGER
		do
			Result := framework_rows.count
		end

	harness_show_framework (a_index: INTEGER)
			-- Framework `a_index' of the list in T4.
		do
			show_framework (framework_rows.i_th (a_index).id)
		end

	harness_document_view (a_which: INTEGER): SW_DOCUMENT_VIEW
			-- 1 the framework view, 2 the book view, 3 the commentary view.
		do
			inspect a_which
			when 1 then
				Result := framework_view
			when 2 then
				Result := book_view
			else
				Result := commentary_view
			end
		end

	harness_quote_selection (a_which: INTEGER; a_folder_id: INTEGER_64)
			-- "Add to Favorites as a quotation" on that view's selection, the sheet accepted as it opens.
		do
			if attached quotation_of (harness_document_view (a_which)) as al_quote then
				keep_favorite (al_quote, "", a_folder_id)
			end
		end

	harness_keep_document (a_which: INTEGER)
			-- "Add ... to Favorites" on that view's document, the sheet accepted as it opens.
		do
			if attached document_target (harness_document_view (a_which)) as al_target then
				keep_favorite (create {BIB_FAVORITE}.make_document (al_target, document_title (harness_document_view (a_which))), "", 0)
			end
		end

	harness_open_favorite_root (a_index: INTEGER)
			-- Click line `a_index' at the top of the Favorites tree (a quotation opens its source).
		do
			choose_favorite (Void)
			choose_favorite (favorites_tree.roots.i_th (a_index))
		end

	harness_favorite_root_icon (a_index: INTEGER): INTEGER
		do
			Result := favorite_icon (favorites_tree.roots.i_th (a_index))
		end

	harness_framework_starred (a_index: INTEGER): BOOLEAN
			-- Does framework `a_index' of the list wear the star?
		do
			Result := framework_starred (framework_rows.i_th (a_index))
		end

	harness_add_highlight (a_reason: READABLE_STRING_GENERAL)
			-- Write `a_reason' in the reason box and press Highlight.
		do
			highlight_reason_box.set_text (a_reason)
			add_highlight
		end

	harness_choose_highlight (a_row: INTEGER)
			-- Click highlight `a_row' of the list.
		do
			highlights_grid.select_model_row (a_row)
		end

	harness_highlight_detail: STRING_32
			-- What the line under the highlights says.
		do
			Result := highlight_detail.text
		end

	harness_select_notes_tab (a_index: INTEGER)
			-- Tab `a_index' of the Notes pane (4: Highlights).
		do
			if attached notes_tabs as al_tabs then
				al_tabs.select_tab (a_index)
			end
		end

	harness_highlight_box_height (a_text: READABLE_STRING_GENERAL): REAL_64
			-- The highlight reason box's height, holding `a_text', in the Study layout's Highlights tab.
		do
			highlight_reason_box.set_text (a_text)
			window.request_render
			Result := highlight_reason_box.height
		end

	harness_theme_swapped_by_windows (a_dark: BOOLEAN)
			-- What following Windows does when its setting flips: the window wears the theme and
			-- tells `on_theme_changed'.
		do
			if a_dark then
				window.follow_system_theme (light_theme, dark_theme)
				window.set_theme (dark_theme)
			else
				window.set_theme (light_theme)
			end
			if attached window.on_theme_changed as al_told then
				al_told.call ([window.theme])
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
			if snapshot_tab.starts_with ({STRING_32} "simple") then
					-- the Simple layout, its pills shown or not, for the User Manual (2026-11-01)
				layout_state.set_study (False)
				window.set_reference_marks_shown (snapshot_tab.same_string ({STRING_32} "simplepills"))
			elseif not is_study then
				layout_state.set_study (True)
			end
			if snapshot_tab.same_string ({STRING_32} "pills") then
					-- the design pills shown, for the User Manual (2026-11-01)
				window.set_reference_marks_shown (True)
			elseif snapshot_tab.same_string ({STRING_32} "interlinear") then
				show_interlinear
			elseif snapshot_tab.same_string ({STRING_32} "timeline") then
				show_timeline
			elseif snapshot_tab.same_string ({STRING_32} "measure") then
					-- the measuring tool: Jerusalem, Jericho, Bethlehem joined into a shape
				show_atlas
				atlas_view.set_view (128.0, 35.32, 31.79)
				atlas_view.start_measuring
				atlas_view.place_point (35.2345, 31.7767)
				atlas_view.place_point (35.4440, 31.8710)
				atlas_view.place_point (35.2003, 31.7054)
				atlas_view.close_shape
			elseif snapshot_tab.same_string ({STRING_32} "atlas") then
					-- Sennacherib's campaign, 701 BC: Jerusalem and Lachish marked, Assyria on the map
				show_timeline
				if item_of_event ("sennacherib") > 0 then
					selection.select_event ("sennacherib", timeline_view.items.i_th (item_of_event ("sennacherib")).year_from)
				end
			elseif snapshot_tab.same_string ({STRING_32} "parallel") then
				show_parallel
			elseif snapshot_tab.same_string ({STRING_32} "commentary") then
				commentary_tabs.select_tab (1)
			elseif snapshot_tab.same_string ({STRING_32} "incipit") then
				commentary_tabs.select_tab (Incipit_tab)
			elseif snapshot_tab.same_string ({STRING_32} "chiasm") then
				commentary_tabs.select_tab (Chiasm_tab)
			elseif snapshot_tab.same_string ({STRING_32} "incipitall") then
				commentary_tabs.select_tab (Incipit_tab)
				set_incipit_mode (Incipit_mode_new)
			elseif snapshot_tab.same_string ({STRING_32} "incipitpair") then
				commentary_tabs.select_tab (Incipit_tab)
				if not incipit_rows.is_empty then
					show_pair (incipit_rows.first)
					if attached pair_float as al_float then
						al_float.export_frame_png (snapshot_path + {STRING_32} ".pair.png").do_nothing
					end
				end
			elseif snapshot_tab.same_string ({STRING_32} "chiasmall") then
				commentary_tabs.select_tab (Chiasm_tab)
				set_chiasm_mode (Chiasm_mode_graded)
			elseif snapshot_tab.same_string ({STRING_32} "notes") then
				new_note_box.set_text ("A sample note written by the snapshot run.")
				add_note
			elseif snapshot_tab.same_string ({STRING_32} "journal") then
				journal_title_box.set_text ("Covenant")
				journal_body_box.set_text ("A sample journal entry written by the snapshot run.")
				save_journal_entry
				if attached notes_tabs as al_tabs then
					al_tabs.select_tab (Journal_tab)
				end
			elseif snapshot_tab.same_string ({STRING_32} "tags") then
				tag_box.set_text ("Watchers")
				tag_verse
				if attached notes_tabs as al_tabs then
					al_tabs.select_tab (Tags_tab)
				end
			elseif snapshot_tab.same_string ({STRING_32} "search") then
				search_box.set_text ("%"full of grace%"")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "searchword") then
				search_box.set_text ("grace")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "boolean") then
				search_box.set_text ("G5485 AND G1515 NOT G2962")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "morph") then
				search_box.set_text ("G3056 AND morph:N-NSM")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "scope") then
				scope_select.select_index (3)
				search_box.set_text ("grace")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "kitwrite") and then attached (create {SIMPLE_ENV}).get ("SIMPLE_BIBLE_SNAPSHOT_FILE") as al_file then
				write_ingest_kit (al_file.to_string_32)
			elseif snapshot_tab.same_string ({STRING_32} "importnote") and then attached (create {SIMPLE_ENV}).get ("SIMPLE_BIBLE_SNAPSHOT_FILE") as al_file then
				import_note (al_file.to_string_32)
				commentary_tabs.select_tab (In_books_tab)
			elseif snapshot_tab.same_string ({STRING_32} "importfolder") and then attached (create {SIMPLE_ENV}).get ("SIMPLE_BIBLE_SNAPSHOT_FILE") as al_folder then
				import_folder (al_folder.to_string_32)
			elseif snapshot_tab.same_string ({STRING_32} "kitfolder") and then attached (create {SIMPLE_ENV}).get ("SIMPLE_BIBLE_SNAPSHOT_FILE") as al_folder then
				make_kits (al_folder.to_string_32)
			elseif snapshot_tab.same_string ({STRING_32} "about") then
				show_about
				keep_snapshot_report ((create {BIB_ABOUT_PAGE}.make (bible, status_text + {STRING_32} "; " + ask_status)).text)
			elseif snapshot_tab.same_string ({STRING_32} "scholarguides") then
				bring_into_view (results_panel, results_tabs, Scholar_guides_tab)
				if not book_rows.is_empty then
					on_book_row (1)
				end
			elseif snapshot_tab.same_string ({STRING_32} "studyguides") then
				commentary_tabs.select_tab (Study_guides_tab)
			elseif snapshot_tab.same_string ({STRING_32} "notesrebuild") then
				rebuild_stale_packs
				bring_into_view (results_panel, results_tabs, Author_library_tab)
			elseif snapshot_tab.same_string ({STRING_32} "ask") then
				ask_box.set_text ("commentary on Galatians 2:16")
				on_ask
			elseif snapshot_tab.same_string ({STRING_32} "writingsback") then
				scope_select.select_index (Writings_scope_index)
				search_box.set_text ("covenant memory")
				on_search
				across 1 |..| writing_rows.count as al_i loop
					if writing_row_opened = 0 and then writing_rows.i_th (al_i).pack_kind.same_string ({BIB_BOOK_SCHEMA}.Pack_kind) then
						on_writing_row (al_i)
					end
				end
			elseif snapshot_tab.same_string ({STRING_32} "writings") then
				scope_select.select_index (Writings_scope_index)
				search_box.set_text ("covenant memory")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "form") then
				search_box.set_text ("G3056@N-NSM")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "prayer") then
				prayer_title_box.set_text ("Strength for Daniel")
				prayer_body_box.set_text ("A sample prayer written by the snapshot run.")
				add_prayer
				prayer_title_box.set_text ("Wisdom for the elders")
				add_prayer
				prayer_open_grid.select_model_row (prayer_open_rows.count)
				prayer_answer_box.set_text ("Agreed together on Sunday")
				mark_prayer_answered
				prayer_tabs.select_tab (2)
				if attached notes_tabs as al_tabs then
					al_tabs.select_tab (Prayer_tab)
				end
			elseif snapshot_tab.same_string ({STRING_32} "memory") then
				add_memory_card
				show_memory_verse
				if attached notes_tabs as al_tabs then
					al_tabs.select_tab (Memory_tab)
				end
			elseif snapshot_tab.same_string ({STRING_32} "versification") then
				search_box.set_text ("H7307 AND H8210")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "spelling") then
				search_box.set_text ("lemma:ruach")
				on_search
			elseif snapshot_tab.same_string ({STRING_32} "hold") then
				on_commentary_link ({STRING_32} "bible:48.2.16")
			elseif snapshot_tab.same_string ({STRING_32} "refcard") then
				snapshot_reference_card
			elseif snapshot_tab.same_string ({STRING_32} "frameworks") then
				if not framework_rows.is_empty then
					show_framework (framework_rows.first.id)
				else
					show_framework ({STRING_32} "kacc")
				end
			elseif snapshot_tab.same_string ({STRING_32} "fwcard") then
				snapshot_framework_card
			elseif snapshot_tab.same_string ({STRING_32} "memes") then
				bring_into_view (results_panel, results_tabs, Memes_tab)
				dock.maximize_panel (results_panel)
				fill_memes
				choose_meme (meme_store.meme_by_slug ("john-3-16"))
			elseif snapshot_tab.same_string ({STRING_32} "editmeme") then
				bring_into_view (results_panel, results_tabs, Memes_tab)
				fill_memes
				choose_meme (meme_store.meme_by_slug ("john-3-16"))
				edit_meme_sheet
			elseif snapshot_tab.same_string ({STRING_32} "versequote") then
				snapshot_verse_quotation
			elseif snapshot_tab.same_string ({STRING_32} "quotation") or snapshot_tab.same_string ({STRING_32} "quotemenu") then
				snapshot_quotation (snapshot_tab.same_string ({STRING_32} "quotemenu"))
			elseif snapshot_tab.same_string ({STRING_32} "books") then
				if not book_rows.is_empty then
					show_book_place (book_rows.first.pack_kind, book_rows.first.id, 2, 0)
				end
			elseif snapshot_tab.same_string ({STRING_32} "essays") then
				across book_rows as ic loop
					if ic.pack_kind.same_string ({BIB_ESSAY_SCHEMA}.Pack_kind) and listed_kind.is_empty then
						show_book_place (ic.pack_kind, ic.id, 1, 0)
					end
				end
			elseif snapshot_tab.same_string ({STRING_32} "inbooks") then
				commentary_tabs.select_tab (In_books_tab)
			elseif snapshot_tab.same_string ({STRING_32} "focus") then
				toggle_focus_reading
			elseif snapshot_tab.same_string ({STRING_32} "maximize") then
				dock.maximize_panel (commentary_panel)
			elseif snapshot_tab.same_string ({STRING_32} "fold") then
				dock.collapse_zone (dock.Zone_west)
				dock.collapse_zone (dock.Zone_east)
			elseif snapshot_tab.same_string ({STRING_32} "versemenu") then
				snapshot_right_click_verse
			elseif snapshot_tab.same_string ({STRING_32} "barmenu") then
				window.request_render
				window.simulate_context_click ((dock.zone_widget (dock.Zone_east).x + 40.0).truncated_to_integer,
					(dock.zone_widget (dock.Zone_east).y + dock.zone_widget (dock.Zone_east).panel_slot_h + 6.0).truncated_to_integer)
			elseif snapshot_tab.same_string ({STRING_32} "gridmenu") then
				commentary_tabs.select_tab (2)
				window.request_render
				window.simulate_context_click ((cross_refs_grid.x + 40.0).truncated_to_integer,
					(cross_refs_grid.y + cross_refs_grid.Header_h + cross_refs_grid.Row_h * 1.5).truncated_to_integer)
			elseif snapshot_tab.same_string ({STRING_32} "history") then
				go_to (43, 3, 16)
				go_to (65, 1, 6)
				navigator_tabs.select_tab (History_tab)
			elseif snapshot_tab.same_string ({STRING_32} "historykept") then
				go_to (43, 3, 16)
				go_to (65, 1, 6)
				navigator_tabs.select_tab (History_tab)
				history_scope.select_segment (2)
			elseif snapshot_tab.same_string ({STRING_32} "bookmarks") or snapshot_tab.same_string ({STRING_32} "favorites") then
				snapshot_favorites
				navigator_tabs.select_tab (Favorites_tab)
			elseif snapshot_tab.same_string ({STRING_32} "addfavorite") then
				add_to_favorites
			elseif snapshot_tab.same_string ({STRING_32} "highlights") then
				highlight_reason_box.set_text ("A sample reason written by the snapshot run, long enough to wrap in the list's reading line below.")
				add_highlight
					-- The next verse read, so the highlighted one shows its own wash, not the selection's.
				go_to (reading_book, reading_chapter, reading_verse + 1)
				if attached notes_tabs as al_tabs then
					al_tabs.select_tab (Highlights_tab)
				end
					-- a long reason typed, wrapping in the box; the kept one chosen, read in full below
				highlight_reason_box.set_text ("A second reason being typed, long enough that it wraps onto another line of the box.")
				highlights_grid.select_model_row (1)
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
			go_button.set_on_click (agent on_reference)
			search_button.set_on_click (agent on_search)
			search_box.set_on_enter (agent on_search)
			ask_box.set_on_enter (agent on_ask)
			ask_button.set_on_click (agent on_ask)
			version_select.set_on_change (agent on_version_change)
			scope_select.set_on_change (agent on_scope_change)
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
			commentary_view.set_on_link_click (agent on_commentary_link)
			notes_list.set_gutter_renderer (agent draw_note_gutter)
			notes_list.set_on_activate (agent edit_note)
			notes_list.set_on_edit_commit (agent on_note_edited)
			notes_list.set_on_select (agent on_note_selected)
			add_note_button.set_on_click (agent add_note)
			tag_button.set_on_click (agent tag_verse)
			journal_new_button.set_on_click (agent new_journal_entry)
			prayer_add_button.set_on_click (agent add_prayer)
			prayer_answered_button.set_on_click (agent mark_prayer_answered)
			memory_add_button.set_on_click (agent add_memory_card)
			memory_show_button.set_on_click (agent show_memory_verse)
			memory_again_button.set_on_click (agent grade_memory_card ({BIB_MEMORY_SCHEDULE}.Grade_again))
			memory_hard_button.set_on_click (agent grade_memory_card ({BIB_MEMORY_SCHEDULE}.Grade_hard))
			memory_good_button.set_on_click (agent grade_memory_card ({BIB_MEMORY_SCHEDULE}.Grade_good))
			memory_easy_button.set_on_click (agent grade_memory_card ({BIB_MEMORY_SCHEDULE}.Grade_easy))
			journal_save_button.set_on_click (agent save_journal_entry)
			journal_delete_button.set_on_click (agent delete_journal_entry)
			journal_restore_button.set_on_click (agent restore_journal_entry)
			journal_grid.set_on_select (agent on_journal_row)
			tag_names_grid.set_on_select (agent on_tag_name)
			delete_note_button.set_on_click (agent delete_note)
			restore_note_button.set_on_click (agent restore_note)
			highlight_button.set_on_click (agent add_highlight)
			cross_refs_grid.set_on_select (agent on_cross_ref)
			incipit_grid.set_on_select (agent on_incipit_row)
			incipit_verse_button.set_on_click (agent set_incipit_mode (Incipit_mode_verse))
			pair_layout_button.set_on_click (agent toggle_pair_layout)
			incipit_all_nt_button.set_on_click (agent set_incipit_mode (Incipit_mode_new))
			incipit_all_ot_button.set_on_click (agent set_incipit_mode (Incipit_mode_old))
			chiasm_verse_button.set_on_click (agent set_chiasm_mode (Chiasm_mode_verse))
			chiasm_all_button.set_on_click (agent set_chiasm_mode (Chiasm_mode_all))
			chiasm_graded_button.set_on_click (agent set_chiasm_mode (Chiasm_mode_graded))
			chiasm_structures_grid.set_on_select (agent on_chiasm_structure_row)
			chiasm_ladder_grid.set_on_select (agent on_chiasm_member_row)
			search_word_button.set_on_click (agent show_every_place)
			results_grid.set_on_select (agent on_choice)
			verses_grid.set_on_select (agent on_verse_hit)
			close_results_button.set_on_click (agent close_results)
			places_grid.set_on_select (agent on_place)
			window.set_on_tick (agent on_window_tick)
			focus_button.set_on_click (agent toggle_focus_reading)
			origin_button.set_on_click (agent back_to_commentary_verse)
			back_to_writings_button.set_on_click (agent back_to_writings)
			commentary_view.set_hover_card_builder (agent link_card (commentary_view, ?, ?))
			framework_view.set_hover_card_builder (agent link_card (framework_view, ?, ?))
			framework_view.set_on_link_click (agent on_commentary_link)
			framework_view.set_menu_extension (agent document_menu (framework_view, lexicon_panel, ?, ?, ?))
			frameworks_grid.set_on_select (agent on_framework_row)
			books_grid.set_on_select (agent on_book_row)
			chapters_grid.set_on_select (agent on_chapter_row)
			in_books_grid.set_on_select (agent on_in_books_row)
			study_guides_grid.set_on_select (agent on_study_guides_row)
			writings_grid.set_on_select (agent on_writing_row)
			book_view.set_on_link_click (agent on_commentary_link)
			book_view.set_hover_card_builder (agent link_card (book_view, ?, ?))
			book_view.set_menu_extension (agent document_menu (book_view, results_panel, ?, ?, ?))
			wire_menus
		end

feature {NONE} -- Window

	window: SW_WINDOW
	light_theme, dark_theme: SW_THEME
	menu_bar: SW_MENU_BAR
	back_button, forward_button: SW_BUTTON
	reference_box, search_box: BIB_LOOKUP_BOX
	version_select: SW_SELECT

	scope_select: SW_SELECT
			-- C6.1: where the verse search looks (2026-10-27): the whole Bible, a testament, the
			-- Gospels, Paul's letters, or the book being read.

	Scope_this_book_name: STRING_32 = "This book"
			-- `scope_select''s last choice: the book being read.

	search_scope: BIB_SEARCH_SCOPE
			-- The scope `scope_select' names for the version read: the whole Bible, a name of
			-- BIB_SCOPE_NAMES (the list shows them in their order), or the book being read; while an
			-- Ask search names a book ("grace in Romans"), that book (scan 63).
		do
			if attached asked_search_scope as al_asked then
				Result := al_asked
			elseif scope_select.selected_index = (create {BIB_SCOPE_NAMES}).names.count + 2 and reading_book > 0 and then attached bible.search_scopes.scope_named (bible.books.book (reading_book).name, reading_version) as al_book then
				Result := al_book
			elseif scope_select.selected_index >= 2 and scope_select.selected_index <= (create {BIB_SCOPE_NAMES}).names.count + 1 and then attached bible.search_scopes.scope_named ((create {BIB_SCOPE_NAMES}).names.i_th (scope_select.selected_index - 1), reading_version) as al_named then
				Result := al_named
			else
				Result := bible.search_scopes.whole_bible (reading_version)
			end
		end

	on_scope_change
			-- C6.1 changed: search again in the new scope when there is a search (My writings: the
			-- writings, research/20).
		do
			asked_search_scope := Void
			if is_writings_scope then
				search_writings
			elseif bible.is_open and then not search_box.text.is_empty then
				find_verses (search_box.text)
			end
		end
	mode_switch: SW_SEGMENTED
	smaller_button, larger_button: SW_BUTTON
	dark_switch: SW_SWITCH
	dock: SW_DOCK_HOST
	results_panel, commentary_panel, lexicon_panel: INTEGER

	atlas_panel: INTEGER
			-- The Atlas's dock panel (Plan 22 phase 3).
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
			l_toolbar.put (go_button)
			l_toolbar.put (version_select)
			l_toolbar.put (search_box.growing)
			l_toolbar.put (search_button)
			l_toolbar.put (scope_select)
			l_toolbar.put (ask_box.growing)
			l_toolbar.put (ask_button)
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
				-- the Atlas, docked beside the Timeline tab (Plan 22 phase 3, spike S9)
			atlas_panel := dock.add_panel ("ATLAS", atlas_pane, dock.Zone_east)
			dock.set_maximizable (atlas_panel, True)
				-- Panes worth reading larger (Larry, 2026-10-28): a maximize button on their bars. The
				-- Navigator gains nothing from the room; the Bible text has Focus reading instead.
			dock.set_maximizable (commentary_panel, True)
			dock.set_maximizable (lexicon_panel, True)
			dock.set_maximizable (notes_panel, True)
			dock.set_maximizable (results_panel, True)
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
			l_bar := reading_bar.with_gap (10.0)
			l_bar.put (reading_caption.as_muted)
			l_bar.put (reading_title)
			l_bar.put (version_chip.as_muted.growing)
			l_bar.put (previous_button)
			l_bar.put (next_button)
			l_bar.put (focus_button)
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
			commentary_tabs.add_page ("Books & essays", in_books_grid)
			commentary_tabs.add_page ("Study guides", study_guides_grid)
			commentary_tabs.add_page ("Incipit", incipit_page)
			commentary_tabs.add_page ("Chiasm", chiasm_page)
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
			lexicon_tabs.add_page ("Frameworks", frameworks_page)
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
			Result.put (verses_heading)
			Result.put (verses_grid.growing)
		end

	build_columns
			-- The grids' columns and the reading view's one column.
		do
			results_grid.add_column (create {SW_GRID_COLUMN [BIB_LOOKUP_CHOICE]}.make ("Word", 150.0, agent {BIB_LOOKUP_CHOICE}.label))
			results_grid.add_column ((create {SW_GRID_COLUMN [BIB_LOOKUP_CHOICE]}.make ("Details", 200.0, agent {BIB_LOOKUP_CHOICE}.detail)).growing)
			verses_grid.add_column ((create {SW_GRID_COLUMN [BIB_READING_VERSE]}.make ("Verse", 110.0, agent hit_place)).with_star (agent hit_starred))
			verses_grid.add_column ((create {SW_GRID_COLUMN [BIB_READING_VERSE]}.make ("Text", 400.0, agent {BIB_READING_VERSE}.display_text)).growing)
			cross_refs_grid.add_column ((create {SW_GRID_COLUMN [BIB_READING_CROSS_REF]}.make ("Reference", 180.0, agent cross_ref_text)).growing.with_star (agent cross_ref_starred))
			highlights_grid.add_column (create {SW_GRID_COLUMN [BIB_HIGHLIGHT]}.make ("Verse", 120.0, agent item_place ({BIB_HIGHLIGHT} ?)))
			history_grid.add_column ((create {SW_GRID_COLUMN [BIB_VISIT]}.make ("Place", 120.0, agent item_place ({BIB_VISIT} ?))).growing.with_star (agent visit_starred))
			history_grid.add_column (create {SW_GRID_COLUMN [BIB_VISIT]}.make ("When", 120.0, agent visit_when))
			memes_grid.add_column ((create {SW_GRID_COLUMN [BIB_MEME]}.make ("", 40.0, agent meme_no_text)).with_glyph (agent meme_picture_glyph))
			memes_grid.add_column ((create {SW_GRID_COLUMN [BIB_MEME]}.make ("Meme", 190.0, agent meme_title)).with_star (agent meme_starred))
			memes_grid.add_column ((create {SW_GRID_COLUMN [BIB_MEME]}.make ("Words", 220.0, agent meme_words)).growing)
			memes_grid.add_column (create {SW_GRID_COLUMN [BIB_MEME]}.make ("Passages", 150.0, agent meme_passages_text))
			memes_grid.add_column (create {SW_GRID_COLUMN [BIB_MEME]}.make ("Set", 110.0, agent meme_set_name))
			history_grid.set_on_select (agent on_history_row)
			tag_names_grid.add_column ((create {SW_GRID_COLUMN [TUPLE [tag: STRING_32; verses: INTEGER]]}.make ("Tag", 160.0, agent tag_name_text)).growing)
			tag_names_grid.add_column (create {SW_GRID_COLUMN [TUPLE [tag: STRING_32; verses: INTEGER]]}.make ("Verses", 70.0, agent tag_verses_text))
			tagged_grid.add_column ((create {SW_GRID_COLUMN [BIB_TAG_ASSIGNMENT]}.make ("Verse", 140.0, agent item_place ({BIB_TAG_ASSIGNMENT} ?))).growing)
			journal_grid.add_column ((create {SW_GRID_COLUMN [BIB_NOTE]}.make ("Entry", 200.0, agent {BIB_NOTE}.title)).growing)
			prayer_open_grid.add_column ((create {SW_GRID_COLUMN [BIB_PRAYER]}.make ("Prayer", 180.0, agent {BIB_PRAYER}.title)).growing)
			prayer_open_grid.add_column (create {SW_GRID_COLUMN [BIB_PRAYER]}.make ("Since", 90.0, agent prayer_since))
			prayer_answered_grid.add_column ((create {SW_GRID_COLUMN [BIB_PRAYER]}.make ("Prayer", 140.0, agent {BIB_PRAYER}.title)).growing)
			prayer_answered_grid.add_column (create {SW_GRID_COLUMN [BIB_PRAYER]}.make ("Answered", 90.0, agent prayer_answered_day))
			prayer_answered_grid.add_column ((create {SW_GRID_COLUMN [BIB_PRAYER]}.make ("How", 160.0, agent {BIB_PRAYER}.answer)).growing)
			memory_grid.add_column ((create {SW_GRID_COLUMN [BIB_MEMORY_CARD]}.make ("Verse", 140.0, agent memory_card_place)).growing)
			memory_grid.add_column (create {SW_GRID_COLUMN [BIB_MEMORY_CARD]}.make ("Next", 100.0, agent memory_card_due))
			highlights_grid.add_column ((create {SW_GRID_COLUMN [BIB_HIGHLIGHT]}.make ("Reason", 160.0, agent {BIB_HIGHLIGHT}.reason)).growing)
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("#", 40.0, agent analysis_position))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Word", 130.0, agent {BIB_INTERLINEAR_WORD}.surface))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Transliteration", 130.0, agent {BIB_INTERLINEAR_WORD}.translit))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Gloss", 150.0, agent {BIB_INTERLINEAR_WORD}.gloss))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Lemma", 130.0, agent {BIB_INTERLINEAR_WORD}.lemma_text))
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Strong's", 120.0, agent {BIB_INTERLINEAR_WORD}.strongs))
			analysis_grid.add_column ((create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Morphology", 260.0, agent {BIB_INTERLINEAR_WORD}.morphology)).growing)
			analysis_grid.add_column (create {SW_GRID_COLUMN [BIB_INTERLINEAR_WORD]}.make ("Uses", 70.0, agent analysis_uses_text))
			cross_refs_grid.add_column (create {SW_GRID_COLUMN [BIB_READING_CROSS_REF]}.make ("Votes", 70.0, agent votes_text))
			incipit_grid.add_column ((create {SW_GRID_COLUMN [like incipit_row_type]}.make ("Place", 220.0, agent incipit_place)).growing)
			incipit_grid.add_column (create {SW_GRID_COLUMN [like incipit_row_type]}.make ("Kind", 90.0, agent incipit_kind))
			incipit_grid.add_column (create {SW_GRID_COLUMN [like incipit_row_type]}.make ("Loudness", 80.0, agent incipit_loudness))
			incipit_grid.add_column (create {SW_GRID_COLUMN [like incipit_row_type]}.make ("Heard by", 170.0, agent incipit_heard_by))
			chiasm_structures_grid.add_column ((create {SW_GRID_COLUMN [like chiasm_structure_row_type]}.make ("Structure", 220.0, agent chiasm_structure_title)).growing)
			chiasm_structures_grid.add_column (create {SW_GRID_COLUMN [like chiasm_structure_row_type]}.make ("Verses", 150.0, agent chiasm_structure_range))
			chiasm_structures_grid.add_column (create {SW_GRID_COLUMN [like chiasm_structure_row_type]}.make ("Pattern", 140.0, agent chiasm_structure_pattern))
			chiasm_structures_grid.add_column (create {SW_GRID_COLUMN [like chiasm_structure_row_type]}.make ("Grade", 130.0, agent chiasm_structure_grade))
			chiasm_structures_grid.add_column (create {SW_GRID_COLUMN [like chiasm_structure_row_type]}.make ("From", 110.0, agent chiasm_structure_source))
			chiasm_ladder_grid.add_column (create {SW_GRID_COLUMN [like chiasm_member_row_type]}.make ("Member", 110.0, agent chiasm_member_letter))
			chiasm_ladder_grid.add_column (create {SW_GRID_COLUMN [like chiasm_member_row_type]}.make ("Verses", 90.0, agent chiasm_member_verses))
			chiasm_ladder_grid.add_column ((create {SW_GRID_COLUMN [like chiasm_member_row_type]}.make ("What it holds", 220.0, agent chiasm_member_label)).growing)
			chiasm_ladder_grid.add_column (create {SW_GRID_COLUMN [like chiasm_member_row_type]}.make ("Pair", 110.0, agent chiasm_member_pair))
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Rendering", 150.0, agent {BIB_ENGLISH_GLANCE_ROW}.english))
			renderings_grid.add_column ((create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Version", 200.0, agent version_name)).growing)
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Count", 70.0, agent count_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Place", 150.0, agent {BIB_PLACE_ROW}.reference_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Word", 150.0, agent {BIB_PLACE_ROW}.surface))
			places_grid.add_column ((create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Transliteration", 160.0, agent {BIB_PLACE_ROW}.translit)).growing)
			reading_view.add_column ("").do_nothing
			frameworks_grid.add_column ((create {SW_GRID_COLUMN [BIB_FRAMEWORK]}.make ("Framework", 120.0, agent {BIB_FRAMEWORK}.display_name)).growing.with_star (agent framework_starred))
			books_grid.add_column ((create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Book", 160.0, agent {BIB_AUTHOR_BOOK}.full_title)).growing.with_star (agent book_starred))
			books_grid.add_column (create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Kind", 70.0, agent library_kind_name))
				-- 0.7.61: "3 of 8 published" while a series is part posted; the latest day one was (Larry, 2026-11-03)
			books_grid.add_column (create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Status", 120.0, agent {BIB_AUTHOR_BOOK}.status_text))
			books_grid.add_column (create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Latest", 84.0, agent {BIB_AUTHOR_BOOK}.last_published))
			chapters_grid.add_column ((create {SW_GRID_COLUMN [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]}.make ("Chapter", 200.0, agent chapter_row_title)).growing.with_star (agent chapter_starred))
				-- 0.7.61: each essay's day or "draft"; its header orders the list oldest first, then
				-- newest first, then as written again
			chapters_grid.add_column (create {SW_GRID_COLUMN [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]}.make ("Published", 84.0, agent chapter_row_published))
			in_books_grid.add_column (create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Book", 120.0, agent {BIB_BOOK_BLOCK}.book_title))
			in_books_grid.add_column (create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Chapter", 140.0, agent {BIB_BOOK_BLOCK}.chapter_title))
			in_books_grid.add_column ((create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Text", 300.0, agent block_snippet)).growing)
			study_guides_grid.add_column (create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Guide", 290.0, agent guide_label))
			study_guides_grid.add_column ((create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Text", 300.0, agent block_snippet)).growing)
			writings_grid.add_column (create {SW_GRID_COLUMN [BIB_WRITING_HIT]}.make ("In", 110.0, agent writing_pack_name))
			writings_grid.add_column (create {SW_GRID_COLUMN [BIB_WRITING_HIT]}.make ("Where", 240.0, agent {BIB_WRITING_HIT}.place))
			writings_grid.add_column ((create {SW_GRID_COLUMN [BIB_WRITING_HIT]}.make ("Text", 400.0, agent writing_text)).growing)
			frameworks_grid.add_column (create {SW_GRID_COLUMN [BIB_FRAMEWORK]}.make ("Tier", 90.0, agent {BIB_FRAMEWORK}.tier))
			frameworks_grid.add_column (create {SW_GRID_COLUMN [BIB_FRAMEWORK]}.make ("Status", 80.0, agent {BIB_FRAMEWORK}.status))
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
				-- Undo and Redo for Favorites; inside a text box the keys stay the box's own
			window.register_accelerator_yielding (Key_z, True, False, False, agent undo_favorites)
			window.register_accelerator_yielding (Key_y, True, False, False, agent redo_favorites)
			window.register_accelerator_yielding (Key_z, True, False, True, agent redo_favorites)
			window.register_accelerator (Key_left, False, True, False, agent move_in_history (-1))
			window.register_accelerator (Key_right, False, True, False, agent move_in_history (1))
			window.register_accelerator (Key_l, True, False, False, agent focus_reference)
			window.register_accelerator (Key_f, True, False, False, agent focus_search)
			window.register_accelerator (Key_plus, True, False, False, agent change_text_size (1))
			window.register_accelerator (Key_minus, True, False, False, agent change_text_size (-1))
			window.register_accelerator (Key_m, True, False, False, agent toggle_mode)
			window.register_accelerator (Key_i, True, False, False, agent show_interlinear)
			window.register_accelerator (Key_d, True, False, False, agent add_to_favorites)
			window.register_accelerator (Key_f, True, False, True, agent toggle_focus_reading)
		end

	file_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Make ingest kit...", "", True, agent make_ingest_kit)
			Result.add_item ("Make ingest kits for a folder...", "", True, agent make_ingest_kits_for_folder)
			Result.add_item ("Import prepared notes...", "", True, agent import_prepared_notes)
			Result.add_item ("Import prepared folder...", "", True, agent import_prepared_folder)
			Result.add_separator
			Result.add_item ("Export...", "", False, Void)
			Result.add_item ("Print...", "", False, Void)
			Result.add_separator
			Result.add_item ("Exit", "Alt+F4", True, agent window.close)
		end

	edit_menu: SW_MENU
		do
			create Result.make
			if favorites_history.can_undo then
				Result.add_item ({STRING_32} "Undo " + favorites_history.undo_name, "Ctrl+Z", True, agent undo_favorites)
			else
				Result.add_item ("Undo", "Ctrl+Z", False, Void)
			end
			if favorites_history.can_redo then
				Result.add_item ({STRING_32} "Redo " + favorites_history.redo_name, "Ctrl+Y", True, agent redo_favorites)
			else
				Result.add_item ("Redo", "Ctrl+Y", False, Void)
			end
			Result.add_separator
			Result.add_item ("Copy verse", "", reading.has_verse, agent copy_verse)
			Result.add_item ("Find in chapter...", "", False, Void)
		end

	view_menu: SW_MENU
		do
			create Result.make
			Result.add_item ("Simple layout", "Ctrl+M", is_study, agent layout_state.set_study (False))
			Result.add_item ("Study layout", "Ctrl+M", not is_study, agent layout_state.set_study (True))
			Result.add_separator
			Result.add_item ("Larger text", "Ctrl++", layout_state.can_grow_text, agent change_text_size (1))
			Result.add_item ("Smaller text", "Ctrl+-", layout_state.can_shrink_text, agent change_text_size (-1))
			Result.add_separator
			Result.add_item (focus_label, "Ctrl+Shift+F", True, agent toggle_focus_reading)
			if dock.maximized_panel = commentary_panel then
				Result.add_item ("Commentary back to its place", "", True, agent dock.restore_maximized)
			else
				Result.add_item ("Commentary in a larger view", "", dock.is_panel_visible (commentary_panel), agent dock.maximize_panel (commentary_panel))
			end
			if window.theme.is_dark then
				Result.add_item ("Light theme", "", True, agent set_dark (False))
			else
				Result.add_item ("Dark theme", "", True, agent set_dark (True))
			end
			Result.add_separator
			if chiasm_letters_mode /= Chiasm_letters_graded then
				Result.add_item ("Chiasm letters: strong and moderate mirrors", "", True, agent set_chiasm_letters_mode (Chiasm_letters_graded))
			end
			if chiasm_letters_mode /= Chiasm_letters_all then
				Result.add_item ("Chiasm letters: every mirror", "", True, agent set_chiasm_letters_mode (Chiasm_letters_all))
			end
			if chiasm_letters_mode /= Chiasm_letters_off then
				Result.add_item ("Chiasm letters: off", "", True, agent set_chiasm_letters_mode (Chiasm_letters_off))
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
			Result.add_item ("Back", "Alt+Left", reading.can_go_back, agent move_in_history (-1))
			Result.add_item ("Forward", "Alt+Right", reading.can_go_forward, agent move_in_history (1))
			Result.add_separator
			Result.add_item ("Previous chapter", "", has_previous_chapter, agent step_chapter (-1))
			Result.add_item ("Next chapter", "", has_next_chapter, agent step_chapter (1))
			Result.add_item ("Go to reference", "Ctrl+L", True, agent focus_reference)
			if is_commentary_held then
				Result.add_item ({STRING_32} "Back to " + place_text (held_book, held_chapter, held_verse), "", True, agent back_to_commentary_verse)
			end
			Result.add_separator
			Result.add_item ("Add to Favorites...", "Ctrl+D", reading.has_place and user_store.is_open, agent add_to_favorites)
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
			Result.add_item ("Search results", "", results_state.has_results, agent reopen_results)
			Result.add_item ("Commentary", "", True, agent dock.show_panel (commentary_panel))
			Result.add_item ("Dictionary and lexicon", "", True, agent dock.show_panel (lexicon_panel))
			Result.add_item ("Atlas", "", True, agent show_atlas)
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
			-- Help > About (2026-10-30, Larry): a modal window with the version, what Simple Bible is, and
			-- credit to everyone owed it (BIB_ABOUT_PAGE): the data's sources as the data records them,
			-- the compiler, the libraries, the tools and the art; Close shuts it.
		local
			l_column: SW_COLUMN
			l_view: SW_DOCUMENT_VIEW
			l_close: SW_BUTTON
		do
				-- the text follows the sheet (2026-10-30, Larry): it grows into whatever height the
				-- sheet has, dragged or not, and asks for more than any screen so the sheet opens as
				-- tall as the window allows and follows it; the column takes back what does not fit
			create l_view.make (4000.0)
			l_view := l_view.with_min_size (0.0, 160.0).growing
			l_view.set_document (commentary_reader.read ((create {BIB_ABOUT_PAGE}.make (bible, status_text + {STRING_32} "; " + ask_status)).text))
			create l_close.make ("Close", agent window.close_sheet)
			l_close.set_tooltip ("Close the About window")
			create l_column.make
			l_column := l_column.with_padding (16.0).fitting
			l_column.put (l_view)
			l_column.put (l_close)
			window.show_sheet (l_column, 820.0)
		end

feature {NONE} -- Toolbar (C3-C9)

	reading: BIB_READING_STATE
			-- The place read and the trail Back and Forward walk (research/23 phase 3): the version,
			-- the chapter, the verse and the history buttons each join it.

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
			-- C6: a word, verse or Strong's number; several choices open P07, one word opens S3. With
			-- My writings as the scope, Larry's writings are searched instead (research/20).
		local
			l_lookup: BIB_LOOKUP
		do
			if is_writings_scope then
				search_writings
			elseif bible.is_open and then not search_box.text.is_empty and then not bible.conc_pack.is_available then
					-- Design scan 47: the verses need no concordance, only content.db's index.
				create choices.make (0)
				results_grid.set_rows (choices)
				results_note.set_text ("No concordance attached: the verses are searched, the dictionary words are not.")
				find_verses (search_box.text)
				show_results
			elseif bible.is_open and then bible.conc_pack.is_available and then not search_box.text.is_empty and then not attached lookup_text (search_box.text) then
					-- Design scan 48: a search of several parts is the parser's; the lookup box read it
					-- whole and said "nothing found".
				create choices.make (0)
				results_grid.set_rows (choices)
				results_note.set_text ("No dictionary word to show for this search: the verses it names are listed below.")
				find_verses (search_box.text)
				show_results
			elseif bible.is_open and then bible.conc_pack.is_available and then not search_box.text.is_empty and then attached lookup_text (search_box.text) as al_lookup_text then
				create l_lookup.make (bible)
				choices := l_lookup.choices_for (al_lookup_text)
				results_grid.set_rows (choices)
				results_note.set_text (l_lookup.note_text)
				if attached l_lookup.last_verse as al_verse and then not reading_version.is_empty then
					go_to (al_verse.book, al_verse.chapter, al_verse.verse)
					clear_verse_hits
				else
					find_verses (search_box.text)
					if choices.is_empty and not verse_hits.is_empty then
							-- The lookup's "nothing found" is about headwords; the verses below say otherwise.
						results_note.set_text ("No dictionary headword matches; the verses the search names are listed below.")
					end
				end
				if choices.count = 1 and then choices.first.opens_a_word then
					open_study (choices.first.lemma_id)
					if verse_hits.is_empty then
						hide_results
					else
						show_results
					end
				else
					show_results
					if choices.count >= 1 and then choices.first.opens_a_word and then l_lookup.last_verse = Void then
						open_study (choices.first.lemma_id)
					end
				end
			end
		end

	lookup_text (a_text: READABLE_STRING_GENERAL): detachable STRING_32
			-- What the lookup box should read for `a_text': the text itself when it is plain words (a
			-- word, a verse such as John 3:16, an English phrase), a Strong's number for strongs:,
			-- the headword for lemma:; Void for a grammar code (morph:) and when the search has
			-- several parts (OR, NOT, parentheses, quotes, or keys among words), which only the verse
			-- search reads.
		local
			l_query: BIB_QUERY
			l_plain: BOOLEAN
			i: INTEGER
		do
			l_query := bible.query_parser.parsed (a_text, bible.search_scopes.whole_bible ("KJV"))
			if not l_query.is_valid then
				Result := a_text.to_string_32
			elseif l_query.clause_count = 1 and then (l_query.clause (1).kind = {BIB_QUERY_CLAUSE}.Morph or l_query.clause (1).kind = {BIB_QUERY_CLAUSE}.Form) then
					-- A grammar code names no headword: the verse search alone.
				Result := Void
			elseif l_query.clause_count = 1 and then l_query.clause (1).is_key_clause then
				if attached l_query.clause (1).key as al_key and then attached {BIB_LEMMA_KEY} al_key as al_lemma then
					Result := al_lemma.lemma
				else
					Result := l_query.clause (1).text
				end
			else
				l_plain := not a_text.has ('(') and not a_text.has ('"')
				from i := 1 until i > l_query.clause_count or not l_plain loop
					l_plain := l_query.clause (i).kind = {BIB_QUERY_CLAUSE}.Word or l_query.clause (i).kind = {BIB_QUERY_CLAUSE}.And_clause
					i := i + 1
				end
				if l_plain then
					Result := a_text.to_string_32
				end
			end
		end

	on_version_change
			-- C5: read the same place in the version picked.
		do
			if version_select.selected_index >= 1 and version_select.selected_index <= bible.text_reader.versions.count then
				reading.set_version (bible.text_reader.versions.i_th (version_select.selected_index).code)
			end
		end

	on_mode (a_index: INTEGER)
			-- C7: Simple (1) or Study (2); layout only, never data.
		do
			layout_state.set_study (a_index = 2)
		end

	toggle_mode
			-- Ctrl+M.
		do
			layout_state.toggle_study
		end

	change_text_size (a_step: INTEGER)
			-- C8: all the window's text larger (1) or smaller (-1), menus too, kept for the next run
			-- (Larry, 2026-10-26: not the Bible text alone). The state tells `apply_text_scale'.
		do
			layout_state.step_text_scale (a_step)
			window.toast ({STRING_32} "Text size " + (layout_state.text_scale * 100.0).rounded.out + {STRING_32} "%%", 1)
		end

	apply_text_scale (a_scale: REAL_64)
			-- The text size everywhere it shows: both themes, the two size buttons, the saved setting
			-- (told by the layout state, and on joining, so the buttons are right from the start:
			-- risk 2).
		local
			l_saved: BOOLEAN
		do
			light_theme.set_text_scale (a_scale)
			dark_theme.set_text_scale (a_scale)
			smaller_button.set_enabled (layout_state.can_shrink_text)
			larger_button.set_enabled (layout_state.can_grow_text)
			if settings.text_scale /= a_scale then
				settings.set_text_scale (a_scale)
				if not is_offscreen then
					l_saved := settings.save
				end
			end
			window.request_render
		end

	mark_selected_verse (a_view: SW_PARALLEL_TEXT; a_row, a_column: INTEGER)
			-- Mark cell `a_row', `a_column' of `a_view' as the selected verse's: the one mark the Bible
			-- and Parallel tabs both use (scan 36). Washed blue; outlined instead when the cell carries
			-- another mark (a highlight), so its amber wash still shows (scan 42).
		require
			valid_row: a_row >= 1 and a_row <= a_view.row_count
			verse_row: not a_view.is_note_row (a_row)
			valid_column: a_column >= 1 and a_column <= a_view.column_count
		local
			l_marks: SW_MARKED_TEXT
			l_mark: SW_MARK
		do
			l_marks := a_view.cell_marks (a_row, a_column)
			l_marks.remove_reason (Selected_verse_reason)
			if l_marks.text_count > 0 then
				create l_mark.make ({SW_MARK}.Hue_blue)
				if l_marks.count > 0 then
					l_marks.mark_range_with (0, l_marks.text_count, Selected_verse_reason, l_mark).do_nothing
				else
					l_marks.mark_range_with (0, l_marks.text_count, Selected_verse_reason, l_mark.with_wash).do_nothing
				end
			end
		end

	mark_highlighted_verse (a_view: SW_PARALLEL_TEXT; a_row, a_column: INTEGER; a_text: READABLE_STRING_32; a_reasons: READABLE_STRING_32)
			-- Wash a highlighted verse amber, its reasons as the mark's label: the one highlight mark the
			-- Bible and Parallel tabs both use (scan 42).
		do
			if not a_text.is_empty then
				a_view.cell_marks (a_row, a_column).mark_range_with (0, a_text.count, a_reasons, (create {SW_MARK}.make ({SW_MARK}.Hue_amber)).with_wash).do_nothing
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
			-- The reader's choice of the dark theme, or the light one; the state tells `apply_theme'.
		do
			layout_state.set_dark (a_dark)
		end

	apply_theme (a_dark: BOOLEAN)
			-- The window and the switch wearing what the state says (told on joining, on the reader's
			-- choice, and when following Windows swapped the theme: then the window already wears it,
			-- so it is not set again and keeps following; the switch follows too: risk 11).
		do
			if window.theme.is_dark /= a_dark then
				if a_dark then
					window.set_theme (dark_theme)
				else
					window.set_theme (light_theme)
				end
			end
			if dark_switch.is_on /= a_dark then
				dark_switch.set_on (a_dark)
			end
			window.request_render
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
			-- Edit > Copy verse: the selected verse with its reference (scan 56: `copy_hub_verse', the
			-- one verse copier).
		do
			if reading.has_verse then
				copy_hub_verse (reading_hub)
			end
		end

feature {NONE} -- Reading (S1, P01)

	reading_caption, reading_title, version_chip, reading_note: SW_LABEL
	previous_button, next_button, focus_button, origin_button: SW_BUTTON

	reading_bar: SW_ROW
			-- S1's header row; `origin_button' stands at its end while the commentary is held.
	reading_view: SW_PARALLEL_TEXT

	reading_verses: ARRAYED_LIST [BIB_READING_VERSE]
			-- The chapter shown, verse by verse.

	reading_version: STRING_8
			-- The version S1 reads (C5's choice); empty when content.db holds none.
		do
			Result := reading.version
		end

	reading_book: INTEGER
			-- The book shown (0: none yet).
		do
			Result := reading.book
		end

	reading_chapter: INTEGER
			-- The chapter shown.
		do
			Result := reading.chapter
		end

	reading_verse: INTEGER
			-- Its selected verse (0: none).
		do
			Result := reading.verse
		end

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
					reading.set_version (bible.text_reader.versions.i_th (l_chosen).code)
				end
			end
		end

	go_to (a_book, a_chapter, a_verse: INTEGER)
			-- Read `a_book' `a_chapter' (verse `a_verse' selected, 0: none) and remember it for Back.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_not_negative: a_verse >= 0
		local
			l_released: BOOLEAN
		do
			if bible.text_reader.has_version (reading_version) then
				if not is_following_commentary and is_commentary_held then
						-- Anything but a commentary link: the commentary follows the Bible text again.
					release_commentary
					l_released := True
				end
				reading.go_to (a_book, a_chapter, a_verse)
				if l_released then
					show_cross_refs
				end
			end
		end

	move_in_history (a_step: INTEGER)
			-- C3: Back (-1) or Forward (1).
		do
			if (a_step = -1 and reading.can_go_back) or (a_step = 1 and reading.can_go_forward) then
				release_commentary
				reading.step_history (a_step)
			end
		end

	has_previous_chapter: BOOLEAN
			-- Is there a chapter before the one read (across books)?
		do
			Result := reading.has_place and then (reading.chapter > 1 or reading.book > 1)
		end

	has_next_chapter: BOOLEAN
			-- Is there a chapter after the one read (across books)?
		do
			Result := reading.has_place and then (reading.chapter < bible.text_reader.last_chapter (reading.version, reading.book) or reading.book < {BIB_CANON}.Last_book)
		end

	show_version (a_code: STRING_8)
			-- What names the version read follows it (`reading' tells): C5's chip, the numbering notes,
			-- the size of the script, and the Lexicon's renderings.
		do
			if attached bible.text_reader.version (a_code) as al_version then
				version_chip.set_text (al_version.name)
				reading_note.set_text (numbering_note (al_version))
				numbering_label.set_text (numbering_name (al_version))
			end
			apply_reading_scale
			if study_lemma > 0 then
				renderings_grid.set_rows (renderings_for_version (renderings))
			end
		end

	show_chapter
			-- S1 shows the chapter read, verse by verse, and in Study Parallel, Interlinear, the notes
			-- and History follow it (`reading' tells when the chapter's text is another). The selected
			-- verse is `show_verse''s, told next.
		require
			a_place: reading.has_place
		local
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_row, i: INTEGER
			l_lookup: BIB_LOOKUP
			l_reasons: HASH_TABLE [STRING_32, INTEGER]
			l_letters: HASH_TABLE [STRING_32, INTEGER]
		do
			l_chapter := bible.text_reader.chapter (reading_version, reading_book, reading_chapter)
			create reading_verses.make (l_chapter.count)
			from i := 1 until i > l_chapter.count loop
				reading_verses.extend (l_chapter.item (i))
				i := i + 1
			end
			reading_title.set_text (place_text (reading_book, reading_chapter, 0))
			reading_view.wipe_out
			reading_marked_row := 0
			l_reasons := chapter_highlight_reasons (reading_book, reading_chapter)
			l_letters := chiasm_letters (reading_book, reading_chapter)
			across reading_verses as ic loop
				if attached l_letters.item (ic.verse) as al_letter then
					l_row := reading_view.add_row (ic.verse.out.to_string_32 + {STRING_32} " " + al_letter)
				else
					l_row := reading_view.add_row (ic.verse.out)
				end
				reading_view.set_cell (l_row, 1, ic.display_text)
				if attached l_reasons.item (ic.verse) as al_reason then
					mark_highlighted_verse (reading_view, l_row, 1, ic.display_text, al_reason)
				end
			end
			if l_chapter.count = 0 then
				create l_lookup.make (bible)
				reading_view.add_note (l_lookup.empty_chapter_text (l_chapter, place_text (reading_book, reading_chapter, 0))).do_nothing
			end
			star_rows (reading_view)
			mark_verse_quotes (reading_view)
			previous_button.set_enabled (has_previous_chapter)
			next_button.set_enabled (has_next_chapter)
			window.set_title (window_title)
			if is_study then
				fill_parallel
				if center_tabs.selected_index = Interlinear_tab then
					fill_interlinear
				end
				fill_notes
			end
		end

	show_verse
			-- The verse read is marked in S1 (and in Study, Parallel and Interlinear) and brought into
			-- view; S2's cross-references, C4, the status bar and the verse's tools follow it (`reading'
			-- tells: a click on another verse of the chapter changes only these).
		require
			a_place: reading.has_place
		do
			reading_marked_row := moved_verse_mark (reading_view, reading_marked_row)
			if reading_marked_row > 0 then
				reading_view.scroll_to_row (reading_marked_row)
			end
			show_cross_refs
				-- C4 shows the place S1 reads, however S1 got there (Larry, 2026-10-26: a verse
				-- or cross-reference click left it showing what was typed last).
			reference_box.set_text (place_text (reading_book, reading_chapter, reading_verse))
			status_bar.set_left (place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} " (" + reading_version.to_string_32 + {STRING_32} ")")
			show_verse_tools
			if is_study then
				mark_parallel_verse
				if center_tabs.selected_index = Interlinear_tab then
					fill_interlinear
				end
			end
		end

	show_trail_buttons
			-- Back and Forward (C3) follow the trail (`reading' tells).
		do
			back_button.set_enabled (reading.can_go_back)
			forward_button.set_enabled (reading.can_go_forward)
		end

	show_verse_tools
			-- The tools that act on the verse read name it, or ask for one: a new note, a highlight, a
			-- tag, a memory card.
		local
			l_place: STRING_32
			l_can: BOOLEAN
		do
			l_can := user_store.is_open and reading.has_verse
			if reading.has_verse then
				l_place := place_text (reading_book, reading_chapter, reading_verse)
				new_note_label.set_text ({STRING_32} "A new note on " + l_place + {STRING_32} ":")
				highlight_reason_label.set_text ({STRING_32} "Why highlight " + l_place + {STRING_32} "?")
				tag_label.set_text ({STRING_32} "Tag " + l_place + {STRING_32} ":")
			else
				new_note_label.set_text ("Click a verse to write a note on it.")
				highlight_reason_label.set_text ("Click a verse to highlight it.")
				tag_label.set_text ("Click a verse to tag it.")
			end
			add_note_button.set_enabled (l_can)
			highlight_button.set_enabled (l_can)
			tag_button.set_enabled (l_can)
			memory_add_button.set_enabled (l_can)
		end

	mark_parallel_verse
			-- Parallel's selected-verse mark moves to the verse read, brought into view.
		do
			parallel_marked_row := moved_verse_mark (parallel_view, parallel_marked_row)
			if parallel_marked_row > 0 then
				parallel_view.scroll_to_row (parallel_marked_row)
			end
		end

	moved_verse_mark (a_view: SW_PARALLEL_TEXT; a_old_row: INTEGER): INTEGER
			-- Move `a_view''s selected-verse mark from row `a_old_row' (0: none) to the verse read's row,
			-- in every column; that row (0: no verse, or none in `a_view').
		local
			c: INTEGER
		do
			if a_old_row >= 1 and a_old_row <= a_view.row_count and then not a_view.is_note_row (a_old_row) then
				from c := 1 until c > a_view.column_count loop
					a_view.cell_marks (a_old_row, c).remove_reason (Selected_verse_reason)
					c := c + 1
				end
			end
			Result := verse_row
			if Result > a_view.row_count or else (Result > 0 and then a_view.is_note_row (Result)) then
				Result := 0
			end
			if Result > 0 then
				from c := 1 until c > a_view.column_count loop
					mark_selected_verse (a_view, Result, c)
					c := c + 1
				end
			end
		ensure
			in_the_view: Result >= 0 and Result <= a_view.row_count
		end

	verse_row: INTEGER
			-- The row of the verse read in the chapter's views, which list `reading_verses' in order
			-- (0: no verse, or not in the chapter).
		local
			i: INTEGER
		do
			if reading.has_verse then
				from i := 1 until i > reading_verses.count or Result > 0 loop
					if reading_verses.i_th (i).verse = reading_verse then
						Result := i
					end
					i := i + 1
				end
			end
		end

	reading_marked_row, parallel_marked_row: INTEGER
			-- The rows the selected-verse mark stands on in S1 and in Parallel (0: none).

	Selected_verse_reason: STRING_32 = "selected verse"
			-- The selected-verse mark's reason, the handle that moves it.

	fill_study_panes
			-- Every Study pane for the place read: Parallel (and Interlinear when it shows), notes,
			-- highlights, tags, journal, history, prayers, memory, and the strip marks.
		do
			fill_parallel
			if center_tabs.selected_index = Interlinear_tab then
				fill_interlinear
			end
			fill_notes
			fill_highlights
			fill_tags
			fill_journal
			fill_history
			fill_prayers
			fill_memory
			show_verse_tools
			refresh_strip_marks
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
				elseif l_chapter > bible.text_reader.last_chapter (reading_version, l_book) and l_book < {BIB_CANON}.Last_book then
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
			if bible.conc_pack.is_available and then bible.books.has_book (reading_book) and then reading.has_verse then
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
					clear_verse_hits
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
			-- Is `a_char' part of a word (BIB_WORD_CHARACTERS: one rule for the window and Ask)?
		do
			Result := word_characters.is_word_character (a_char)
		end

	word_characters: BIB_WORD_CHARACTERS
			-- What a word is made of.
		once
			create Result
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
			if study_corpus.same_string ("WLC-MACULA") and not a_version.numbers_like_hebrew then
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
			if a_version.numbers_like_hebrew then
				Result := {STRING_32} "Hebrew numbering"
			elseif a_version.numbers_like_septuagint then
				Result := {STRING_32} "Septuagint numbering"
			elseif a_version.numbers_like_vulgate then
				Result := {STRING_32} "Vulgate numbering"
			else
				Result := {STRING_32} "English numbering"
			end
		end

feature {NONE} -- Two layouts (C7)

	is_study: BOOLEAN
			-- The Study layout? (One copy: the layout state.)
		do
			Result := layout_state.is_study
		end

	layout_state: BIB_LAYOUT_STATE
			-- The layout and the look, one copy of each fact (research/23 phase 2).
		attribute
			create Result.make (settings.is_study_layout, settings.text_scale, False)
		end
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

	interlinear_corpus: STRING_8
			-- The tagged text that chapter was read from; the verse analysis counts in it (scan 40:
			-- the corpus was worked out again in each place).
		attribute
			create Result.make_empty
		end

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
				-- A new layout starts with every side open and no pane maximized.
			dock.restore_maximized
			dock.set_all_collapsed (False)
			detach (center_holder, reading_column)
			detach (bible_page, reading_column)
			detach (center_holder, center_tabs)
			detach (results_holder, results_column)
			detach (results_page, results_column)
			detach (results_holder, results_tabs)
			if tools_holder.children.has (tools_strip) then
				tools_holder.remove (tools_strip)
			end
			if a_study then
				bible_page.put (reading_column)
				center_holder.put (center_tabs)
				results_page.put (results_column)
				results_holder.put (results_tabs)
				tools_holder.put (tools_strip)
				dock_panel_into (lexicon_panel, dock.Zone_east)
				dock_panel_into (commentary_panel, dock.Zone_east)
				dock_panel_into (results_panel, dock.Zone_south)
				dock.show_panel (navigator_panel)
				dock.show_panel (notes_panel)
				dock.show_panel (results_panel)
				dock.hide_panel (atlas_panel)
				river_applied := False
				dock.set_fraction (dock.Zone_west, 0.18)
				dock.set_fraction (dock.Zone_east, 0.34)
				dock.set_fraction (dock.Zone_south, 0.30)
				center_tabs.select_tab (1)
					-- every Study pane filled for the place read (risk 1: switching from Simple left
					-- notes, journal, memory and the rest empty, their buttons as made)
				fill_study_panes
			else
				center_holder.put (reading_column)
				results_holder.put (results_column)
				dock_panel_into (lexicon_panel, dock.Zone_south)
				dock_panel_into (commentary_panel, dock.Zone_east)
				dock_panel_into (results_panel, dock.Zone_west)
				dock.hide_panel (navigator_panel)
				dock.hide_panel (notes_panel)
				dock.hide_panel (atlas_panel)
				river_applied := False
				if results_state.is_wanted then
					dock.show_panel (results_panel)
				else
					dock.hide_panel (results_panel)
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
			if not is_offscreen then
				l_saved := settings.save
			end
			show_focus_label
			keep_verse_in_view
			window.request_render
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
			l_library: SW_SPLITTER
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
			center_tabs.add_page ("Timeline", timeline_pane)
			center_tabs.set_on_change (agent on_center_tab)
			pair_view.add_column ("Old Testament").do_nothing
			pair_view.add_column ("New Testament").do_nothing
			pair_stack.add_column ("Old Testament, then New Testament").do_nothing
			parallel_view.add_column ("").do_nothing
			parallel_view.add_column ("").do_nothing
			parallel_view.add_column ("").do_nothing

			results_tabs.add_page ("Search Results", results_page)
			results_tabs.add_page ("Guides", create {SW_EMPTY_STATE}.make ("Guides come later", "A guide assembles passages, notes and word studies on one subject (P08)."))
			results_tabs.add_page ("Census and Checks", create {SW_EMPTY_STATE}.make ("Census comes later", "Counts across books and corpora with their controls (P09)."))
				-- one reader for the Author Library and the Scholar Guides, shelved in the tab chosen (2026-10-30)
			l_library := books_page.growing
			library_page := l_library
			library_holder.put (l_library)
			results_tabs.add_page ("Author Library", library_holder)
			results_tabs.add_page ("Writings", writings_page)
			results_tabs.add_page ("Scholar Guides", guides_holder)
			results_tabs.add_page ("Memes", memes_page)
			results_tabs.set_on_change (agent on_results_tab)
			results_tabs.add_page ("Study Ledger v1.5", create {SW_EMPTY_STATE}.make ("Study ledger is version 1.5", "Planned for version 1.5."))

			tools_strip.add_tool ("Parallel", "Versions side by side (P02)", True, agent show_parallel)
			tools_strip.add_tool ("Interlinear", "Word by word in the original (P03). Ctrl+I", True, agent show_interlinear)
			tools_strip.add_tool ("Timeline", "The River of Time: when it happened, and who says so", True, agent show_timeline)
			tools_strip.add_tool ("Atlas", "The Atlas: where it happened, empires by year, places and their doubt", True, agent show_atlas)
			tools_strip.add_tool ("Guide", "A guide on one subject (P08): comes later", False, Void)
			tools_strip.add_tool ("Word Study", "The word study (P05 Word Study): comes later", False, Void)
			tools_strip.add_tool ("Count", "Census and checks (P09): comes later", False, Void)
			tools_strip.add_tool ("Ledger v1.5", "The study ledger, version 1.5", False, Void)
		end

	navigator_pane: SW_COLUMN
			-- T1, P11 Navigator: the books, testament by testament, chapter by chapter; the
			-- favorites; and the history.
		local
			l_roots: ARRAYED_LIST [BIB_NAV_NODE]
			l_books, l_marks, l_history: SW_COLUMN
			l_buttons, l_keep: SW_ROW
		do
			create l_roots.make (2)
			l_roots.extend (create {BIB_NAV_NODE}.make_testament ("Old Testament", {BIB_CANON}.First_book, {BIB_CANON}.Last_old_testament_book))
			l_roots.extend (create {BIB_NAV_NODE}.make_testament ("New Testament", {BIB_CANON}.First_new_testament_book, {BIB_CANON}.Last_book))
			navigator_tree.set_label (agent {BIB_NAV_NODE}.label)
			navigator_tree.set_children (agent nav_children)
			navigator_tree.set_roots (l_roots)
			navigator_tree.set_on_select (agent on_nav)
			create l_books.make
			l_books := l_books.with_gap (6.0)
			l_books.put (navigator_tree.growing)
			create l_marks.make
			l_marks := l_marks.with_gap (6.0)
				-- the filter box on a row of its own, the four buttons and the count under it: one row
				-- for all of them ran past a Navigator's width (seen in the 0.7.52 snapshot)
			l_marks.put (favorites_filter_box)
			create l_buttons.make
			l_buttons.put (favorites_new_folder_button)
			l_buttons.put (favorites_rename_button)
			l_buttons.put (favorites_remove_button)
			l_buttons.put (favorites_restore_button)
			l_buttons.put (favorites_heading)
			l_marks.put (l_buttons)
			l_marks.put (favorites_tree.growing)
			navigator_tabs.add_page ("Books", l_books)
			navigator_tabs.add_page ("Favorites", l_marks)
			create l_history.make
				-- the Kept list's length beside the switch: a row of its own did not fit a short Navigator
			l_history := l_history.with_gap (6.0)
			create l_keep.make
			l_keep.put (history_scope)
			l_keep.put (history_keep_box)
			l_history.put (l_keep)
			l_history.put (history_heading)
			l_history.put (history_grid.growing)
			navigator_tabs.add_page ("History", l_history)
			create Result.make
			Result.put (navigator_tabs.growing)
		end

	navigator_tabs: SW_TABS

	favorites_history: BIB_UNDO_HISTORY
			-- Undo and Redo for Favorites (Larry, 2026-11-03): Ctrl+Z, Ctrl+Y, the Edit menu and a
			-- notice's Undo.
		attribute
			create Result.make (100)
		end

	is_quiet_keep: BOOLEAN
			-- Is `keep_favorite' keeping as one part of a larger change (no notice of its own)?
	favorites_heading: SW_LABEL
	favorites_tree: SW_TREE [BIB_FAVORITE_NODE]
	favorites_filter_box: SW_TEXT_BOX
	favorites_new_folder_button, favorites_rename_button, favorites_remove_button, favorites_restore_button: SW_BUTTON
			-- T1's Favorites page (research/24 stage C, 2026-11-01; it took the Bookmarks page's place:
			-- Larry, bookmarks are favorites).

	favorites_state: BIB_FAVORITE_SET
			-- The folders and favorites user.db holds, their order and their stars.

	favorite_nodes: HASH_TABLE [BIB_FAVORITE_NODE, INTEGER_64]
			-- One tree line per row (by `{BIB_FAVORITE_NODE}.key'), so a reload keeps open folders open.

	last_removed_favorite: detachable BIB_FAVORITE_NODE
			-- What Remove took away last; Restore brings it back (`set_last_removed_favorite').

	favorite_choice_changed: SW_EVENT [TUPLE]
			-- Told whenever the chosen line or the line Restore would bring back changes; Rename,
			-- Remove and Restore join it (Larry's rule: GUI state by agents, research/23).
		attribute
			create Result.make
		end

	choose_favorite (a_node: detachable BIB_FAVORITE_NODE)
			-- The one door to the tree's chosen line from the window (a click comes through
			-- `on_favorite'); `favorite_choice_changed' is told once, on a real change (a line chosen is
			-- told by `on_favorite', which the tree calls).
		do
			if a_node /= favorites_tree.selected_node then
				favorites_tree.select_node (a_node)
				if a_node = Void then
					favorite_choice_changed.call (Void)
				end
			end
		ensure
			chosen: favorites_tree.selected_node = a_node
		end

	set_last_removed_favorite (a_node: detachable BIB_FAVORITE_NODE)
			-- The one door to `last_removed_favorite'; `favorite_choice_changed' is told.
		do
			last_removed_favorite := a_node
			favorite_choice_changed.call (Void)
		ensure
			set: last_removed_favorite = a_node
		end

	last_favorite_folder: INTEGER_64
			-- The folder the Add sheet offers first: the one used last (0: the top level).

	Favorites_tab: INTEGER = 2
			-- T1's Favorites page.

	Favorites_sort_key: STRING_8 = "favorites_sort"
			-- The user.db setting that keeps the tree's order.

	reload_favorites
			-- What user.db lists, into `favorites_state', which tells the tree and the stars.
		do
			if user_store.is_open then
				favorites_state.load (user_store.favorite_folders, user_store.favorites)
			end
		end

	folder_node (a_folder: BIB_FAVORITE_FOLDER): BIB_FAVORITE_NODE
			-- The tree line of `a_folder', made once.
		do
			if attached favorite_nodes.item (- a_folder.id) as al_node and then al_node.is_folder then
				al_node.refresh_folder (a_folder)
				Result := al_node
			else
				create Result.make_folder (a_folder)
				favorite_nodes.force (Result, - a_folder.id)
			end
		end

	item_node (a_item: BIB_FAVORITE): BIB_FAVORITE_NODE
			-- The tree line of `a_item', made once.
		do
			if attached favorite_nodes.item (a_item.id) as al_node and then not al_node.is_folder then
				al_node.refresh_item (a_item)
				Result := al_node
			else
				create Result.make_item (a_item)
				favorite_nodes.force (Result, a_item.id)
			end
		end

	nodes_in (a_folder_id: INTEGER_64): ARRAYED_LIST [BIB_FAVORITE_NODE]
			-- Folder `a_folder_id''s lines (0: the top level): its folders first, then its favorites.
		do
			create Result.make (8)
			across favorites_state.child_folders (a_folder_id) as ic loop
				Result.extend (folder_node (ic))
			end
			across favorites_state.child_items (a_folder_id) as ic loop
				Result.extend (item_node (ic))
			end
		end

	favorite_children (a_node: BIB_FAVORITE_NODE): ARRAYED_LIST [BIB_FAVORITE_NODE]
			-- A folder's lines; a favorite has none.
		do
			if attached a_node.folder as al_folder then
				Result := nodes_in (al_folder.id)
			else
				create Result.make (0)
			end
		end

	favorite_icon (a_node: BIB_FAVORITE_NODE): INTEGER
			-- A folder's glyph, or a favorite's gold star.
		do
			if a_node.is_folder then
				Result := {SW_PAINTER}.Glyph_folder
			elseif attached a_node.item as al_item and then al_item.is_document then
				Result := {SW_PAINTER}.Glyph_document
			elseif attached a_node.item as al_item and then al_item.is_quotation then
				Result := {SW_PAINTER}.Glyph_quote
			else
				Result := {SW_PAINTER}.Glyph_star
			end
		end

	fill_favorites
			-- The tree: the top level's folders and favorites, or, with words in the filter box, every
			-- shown folder and favorite whose name holds them; the heading counts them (`favorites_state'
			-- tells, and the filter box).
		local
			l_roots: ARRAYED_LIST [BIB_FAVORITE_NODE]
			l_words: STRING_32
		do
			l_words := favorites_filter_box.text.as_lower
			l_words.left_adjust
			l_words.right_adjust
			if l_words.is_empty then
				l_roots := nodes_in (0)
			else
				create l_roots.make (8)
				across favorites_state.folders as ic loop
					if favorites_state.is_folder_shown (ic.id) and then ic.name.as_lower.has_substring (l_words) then
						l_roots.extend (folder_node (ic))
					end
				end
				across favorites_state.items as ic loop
					if favorites_state.is_folder_shown (ic.folder_id) and then ic.label.as_lower.has_substring (l_words) then
						l_roots.extend (item_node (ic))
					end
				end
			end
			favorites_tree.set_roots (l_roots)
			if attached favorites_tree.selected_node as al_node and then not is_node_shown (al_node) then
				choose_favorite (Void)
			end
			if not user_store.is_open then
				favorites_heading.set_text ("Favorites are not kept: user.db is not open.")
			elseif favorites_state.shown_item_count = 0 and favorites_state.shown_folder_count = 0 then
				favorites_heading.set_text ("None yet: Ctrl+D adds one.")
			elseif not l_words.is_empty then
				favorites_heading.set_text (l_roots.count.out.to_string_32 + {STRING_32} " found")
			else
				favorites_heading.set_text (favorites_count_text (favorites_state.shown_item_count, favorites_state.shown_folder_count))
			end
		end

	favorites_count_text (a_favorites, a_folders: INTEGER): STRING_32
			-- "1 favorite", "3 favorites", "3 in 2 folders", "1 in 1 folder" (short: it shares a row
			-- with four buttons).
		do
			if a_folders = 0 then
				if a_favorites = 1 then
					Result := {STRING_32} "1 favorite"
				else
					Result := a_favorites.out.to_string_32 + {STRING_32} " favorites"
				end
			elseif a_folders = 1 then
				Result := a_favorites.out.to_string_32 + {STRING_32} " in 1 folder"
			else
				Result := a_favorites.out.to_string_32 + {STRING_32} " in " + a_folders.out + {STRING_32} " folders"
			end
		end

	is_node_shown (a_node: BIB_FAVORITE_NODE): BOOLEAN
			-- Is `a_node''s row still listed and in a shown folder?
		do
			if attached a_node.folder as al_folder then
				Result := favorites_state.folder (al_folder.id) /= Void and then favorites_state.is_folder_shown (al_folder.id)
			elseif attached a_node.item as al_item then
				Result := favorites_state.item (al_item.id) /= Void and then favorites_state.is_folder_shown (al_item.folder_id)
			end
		end

	show_favorite_buttons
			-- Rename and Remove need a chosen line; Restore, something removed (`favorite_choice_changed'
			-- tells).
		do
			favorites_rename_button.set_enabled (favorites_tree.selected_node /= Void)
			favorites_remove_button.set_enabled (favorites_tree.selected_node /= Void)
			favorites_restore_button.set_enabled (last_removed_favorite /= Void)
		end

	on_favorite (a_node: BIB_FAVORITE_NODE)
			-- A favorite chosen: read its passage, in the version read (its own version is a menu item
			-- away). A folder chosen: the place New folder, Rename and Remove act on.
		do
			favorite_choice_changed.call (Void)
			if attached a_node.item as al_item then
				if al_item.is_passage then
					go_to_hub (al_item.hub_id)
				else
					open_favorite_source (al_item)
				end
			end
		end

	chosen_folder_id: INTEGER_64
			-- The folder chosen, or the chosen favorite's (0: the top level).
		do
			if attached favorites_tree.selected_node as al_node then
				if attached al_node.folder as al_folder then
					Result := al_folder.id
				elseif attached al_node.item as al_item then
					Result := al_item.folder_id
				end
			end
		end

	open_favorite_in_its_version (a_item: BIB_FAVORITE)
			-- Read `a_item' in the version it was saved in.
		local
			i: INTEGER
		do
			from i := 1 until i > bible.text_reader.versions.count loop
				if bible.text_reader.versions.i_th (i).code.same_string (a_item.version) then
					version_select.select_index (i)
				end
				i := i + 1
			end
			go_to_hub (a_item.hub_id)
		end

	favorites_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A line of the tree: open, rename, move, remove; then New folder and the tree's order.
		local
			o: INTEGER
			l_mark: STRING_32
		do
			if attached favorites_tree.context_node as al_node then
				if attached al_node.item as al_item then
					if al_item.is_passage then
						a_menu.add_item ("Open", "", True, agent go_to_hub (al_item.hub_id))
					else
						a_menu.add_item ("Open", "", True, agent open_favorite_source (al_item))
					end
					if not al_item.version.is_empty and then not al_item.version.same_string (reading_version)
						and then attached bible.text_reader.version (al_item.version) as al_version
					then
						a_menu.add_item ({STRING_32} "Open in " + al_version.name, "", True, agent open_favorite_in_its_version (al_item))
					end
				end
				if attached al_node.folder as al_folder then
					a_menu.add_item ("Copy references", "", True, agent copy_folder_references (al_folder))
				end
				a_menu.add_item ("Rename...", "", True, agent open_rename_sheet (al_node))
				a_menu.add_item ("Move to...", "", True, agent open_move_sheet (al_node))
				a_menu.add_item ("Remove", "", True, agent remove_favorite_node (al_node))
				a_menu.add_separator
			end
			a_menu.add_item ("New folder", "", user_store.is_open, agent new_favorite_folder)
			a_menu.add_separator
			from o := {BIB_FAVORITE_SET}.By_name until o > {BIB_FAVORITE_SET}.By_created_oldest loop
				if o = favorites_state.sort_order then
					l_mark := {STRING_32} "Sorted by "
				else
					l_mark := {STRING_32} "Sort by "
				end
				a_menu.add_item (l_mark + favorites_state.order_name (o), "", o /= favorites_state.sort_order, agent set_favorites_sort (o))
				o := o + 1
			end
		end

	set_favorites_sort (a_order: INTEGER)
			-- The tree lists by `a_order' from now on, kept in user.db.
		require
			known: a_order >= {BIB_FAVORITE_SET}.By_name and a_order <= {BIB_FAVORITE_SET}.By_created_oldest
		do
			user_store.set_setting (Favorites_sort_key, a_order.out)
			favorites_state.set_sort_order (a_order)
		end

	add_to_favorites
			-- Ctrl+D: the Add to Favorites sheet for the place read: its verse, its verses through
			-- another, or its whole chapter; a name; a folder (the last one used); the version read.
		local
			l_column: SW_COLUMN
			l_row: SW_ROW
			l_kind: SW_SEGMENTED
			l_end: SW_NUMBER_BOX
			l_name: SW_TEXT_BOX
			l_folder: SW_SELECT
			l_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER]
			l_add, l_cancel: SW_BUTTON
			l_first, l_last, i: INTEGER
		do
			if not user_store.is_open then
				say ("Favorites are kept in user.db, which is not open.")
			elseif not reading.has_place then
				say ("Open a chapter first.")
			else
				l_first := reading_verse.max (1)
				l_last := l_first
				if not reading_verses.is_empty then
					l_last := reading_verses.last.verse.max (l_first)
				end
				create l_kind.make
				l_kind.add_segment ("This verse")
				l_kind.add_segment ("Verses")
				l_kind.add_segment ("Whole chapter")
				if not reading.has_verse then
					l_kind.select_segment (3)
				end
				create l_end.make ((l_first + 1).min (l_last), l_first, l_last, Void)
				l_end.set_enabled (l_kind.selected_index = 2)
				create l_name.make_single_line (favorite_default_name (l_kind.selected_index, l_end.value))
				create l_folder.make
				l_folder.add_option ("Top level")
				l_folders := favorites_state.shown_folders_by_path
				l_folder.select_index (1)
				from i := 1 until i > l_folders.count loop
					l_folder.add_option (favorites_state.folder_path (l_folders.i_th (i).id))
					if l_folders.i_th (i).id = last_favorite_folder then
						l_folder.select_index (i + 1)
					end
					i := i + 1
				end
				l_kind.set_on_change (agent favorite_kind_changed (?, l_end, l_name))
				l_end.set_on_change (agent favorite_end_changed (?, l_kind, l_name))
				create l_add.make ("Add", agent confirm_add_favorite (l_kind, l_end, l_name, l_folder, l_folders))
				l_add.set_tooltip ("Keep it in Favorites (Enter)")
				create l_cancel.make ("Cancel", agent window.close_sheet)
				create l_column.make
				l_column := l_column.with_padding (16.0).with_gap (10.0)
				l_column.put (create {SW_LABEL}.make_ui ("Add to Favorites"))
				l_column.put (l_kind)
				create l_row.make
				l_row.put (create {SW_LABEL}.make_ui ("Through verse"))
				l_row.put (l_end)
				l_column.put (l_row)
				create l_row.make
				l_row.put (create {SW_LABEL}.make_ui ("Name"))
				l_row.put (l_name.growing)
				l_column.put (l_row)
				create l_row.make
				l_row.put (create {SW_LABEL}.make_ui ("Folder"))
				l_row.put (l_folder)
				l_column.put (l_row)
				if attached bible.text_reader.version (reading_version) as al_version then
					l_column.put (create {SW_LABEL}.make_ui ({STRING_32} "Saved in " + al_version.name))
				end
				create l_row.make
				l_row.put (l_add)
				l_row.put (l_cancel)
				l_column.put (l_row)
				window.show_sheet (l_column, 460.0)
				window.give_focus (l_name)
			end
		end

	favorite_kind_changed (a_kind: INTEGER; a_end: SW_NUMBER_BOX; a_name: SW_TEXT_BOX)
			-- The Add sheet's choice changed: the name follows, and Through verse matters only for Verses.
		do
			a_name.set_text (favorite_default_name (a_kind, a_end.value))
			a_end.set_enabled (a_kind = 2)
		end

	favorite_end_changed (a_end: INTEGER; a_kind: SW_SEGMENTED; a_name: SW_TEXT_BOX)
			-- Through verse changed: Verses chosen, the name follows.
		do
			if a_kind.selected_index /= 2 then
				a_kind.select_segment (2)
			end
			a_name.set_text (favorite_default_name (2, a_end))
		end

	confirm_add_favorite (a_kind: SW_SEGMENTED; a_end: SW_NUMBER_BOX; a_name: SW_TEXT_BOX; a_folder: SW_SELECT; a_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER])
			-- Add pressed.
		local
			l_folder_id: INTEGER_64
		do
			if a_folder.selected_index >= 2 and a_folder.selected_index - 1 <= a_folders.count then
				l_folder_id := a_folders.i_th (a_folder.selected_index - 1).id
			end
			window.close_sheet
			add_favorite (a_kind.selected_index, a_end.value, a_name.text, l_folder_id)
		end

	favorite_default_name (a_kind, a_end_verse: INTEGER): STRING_32
			-- "John 3:16", "John 3:16-18" or "John 3" for the place read.
		do
			inspect a_kind
			when 1 then
				Result := place_text (reading_book, reading_chapter, reading_verse.max (1))
			when 2 then
				Result := place_text (reading_book, reading_chapter, reading_verse.max (1))
				if a_end_verse > reading_verse.max (1) then
					Result.append ({STRING_32} "-" + a_end_verse.out)
				end
			else
				Result := place_text (reading_book, reading_chapter, 0)
			end
		end

	add_favorite (a_kind, a_end_verse: INTEGER; a_name: READABLE_STRING_GENERAL; a_folder_id: INTEGER_64)
			-- Keep the place read in folder `a_folder_id' (0: the top level): its verse (`a_kind' 1), its
			-- verses through `a_end_verse' (2) or its whole chapter (3), named `a_name' (its place when
			-- empty), with the version read.
		require
			a_place: reading.has_place
			known_kind: a_kind >= 1 and a_kind <= 3
			folder_non_negative: a_folder_id >= 0
		local
			l_hub: BIB_HUB_ID
			l_from, l_to: INTEGER_64
			l_name: STRING_32
			l_favorite: BIB_FAVORITE
		do
			if user_store.is_open then
				create l_hub
				inspect a_kind
				when 1 then
					l_from := l_hub.hub_id (reading_book, reading_chapter, reading_verse.max (1))
					l_to := l_from
				when 2 then
					l_from := l_hub.hub_id (reading_book, reading_chapter, reading_verse.max (1))
					l_to := l_hub.hub_id (reading_book, reading_chapter, a_end_verse.max (reading_verse.max (1)))
				else
					l_from := l_hub.hub_id (reading_book, reading_chapter, 1)
					l_to := l_hub.hub_id (reading_book, reading_chapter, l_hub.Max_part)
				end
				l_name := a_name.to_string_32
				l_name.left_adjust
				l_name.right_adjust
				if l_name.is_empty then
					l_name := favorite_default_name (a_kind, a_end_verse)
				end
				create l_favorite.make_passage (l_from, l_to, reading_version, l_name)
				user_store.put_favorite_in (l_favorite, a_folder_id)
				user_store.add_favorite (l_favorite)
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					last_favorite_folder := a_folder_id
					reload_favorites
					favorites_history.record ({STRING_32} "Add " + l_name,
						agent set_item_removed (l_favorite, True), agent set_item_removed (l_favorite, False))
					notice_with_undo ({STRING_32} "Added " + l_name + {STRING_32} " to " + favorites_place (a_folder_id) + {STRING_32} ".")
				end
			end
		end

	new_favorite_folder
			-- An "Untitled" folder in the folder chosen (or the chosen favorite's, or the top level),
			-- chosen and named at once, as a notes app does.
		local
			l_folder: BIB_FAVORITE_FOLDER
			l_parent: INTEGER_64
			l_node: BIB_FAVORITE_NODE
		do
			if user_store.is_open then
				l_parent := chosen_folder_id
				create l_folder.make (l_parent, "Untitled")
				user_store.add_favorite_folder (l_folder)
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					favorites_history.record ("New folder", agent set_folder_removed (l_folder, True), agent set_folder_removed (l_folder, False))
					reload_favorites
					if l_parent /= 0 and then attached favorites_state.folder (l_parent) as al_parent then
						favorites_tree.expand_node (folder_node (al_parent))
					end
					l_node := folder_node (l_folder)
					choose_favorite (l_node)
					open_rename_sheet (l_node)
				end
			end
		end

	rename_chosen_favorite
			-- The pencil: rename the chosen line.
		do
			if attached favorites_tree.selected_node as al_node then
				open_rename_sheet (al_node)
			end
		end

	open_rename_sheet (a_node: BIB_FAVORITE_NODE)
			-- A sheet with the line's name, selected, to type over.
		local
			l_column: SW_COLUMN
			l_row: SW_ROW
			l_name: SW_TEXT_BOX
			l_ok, l_cancel: SW_BUTTON
		do
			if attached a_node.folder as al_folder then
				create l_name.make_single_line (al_folder.name)
			elseif attached a_node.item as al_item then
				create l_name.make_single_line (al_item.label)
			else
				create l_name.make_single_line ("")
			end
			create l_ok.make ("Rename", agent confirm_rename (a_node, l_name))
			create l_cancel.make ("Cancel", agent window.close_sheet)
			create l_column.make
			l_column := l_column.with_padding (16.0).with_gap (10.0)
			if a_node.is_folder then
				l_column.put (create {SW_LABEL}.make_ui ("Folder name"))
			else
				l_column.put (create {SW_LABEL}.make_ui ("Favorite name"))
			end
			l_column.put (l_name)
			create l_row.make
			l_row.put (l_ok)
			l_row.put (l_cancel)
			l_column.put (l_row)
			window.show_sheet (l_column, 420.0)
			window.give_focus (l_name)
		end

	confirm_rename (a_node: BIB_FAVORITE_NODE; a_box: SW_TEXT_BOX)
			-- Rename pressed.
		do
			window.close_sheet
			rename_favorite_node (a_node, a_box.text)
		end

	rename_favorite_node (a_node: BIB_FAVORITE_NODE; a_name: READABLE_STRING_GENERAL)
			-- `a_node''s row named `a_name' (nothing when it is blank).
		local
			l_name, l_old: STRING_32
		do
			l_name := a_name.to_string_32
			l_name.left_adjust
			l_name.right_adjust
			if not l_name.is_empty and user_store.is_open then
				if attached a_node.folder as al_folder then
					l_old := al_folder.name.twin
					user_store.rename_favorite_folder (al_folder, l_name)
					if user_store.write_error = Void and then not l_old.same_string (l_name) then
						favorites_history.record ({STRING_32} "Rename " + l_old,
							agent rename_folder (al_folder, l_old), agent rename_folder (al_folder, l_name))
					end
				elseif attached a_node.item as al_item then
					l_old := al_item.label.twin
					user_store.rename_favorite (al_item, l_name)
					if user_store.write_error = Void and then not l_old.same_string (l_name) then
						favorites_history.record ({STRING_32} "Rename " + l_old,
							agent rename_item (al_item, l_old), agent rename_item (al_item, l_name))
					end
				end
				if attached user_store.write_error as al_error then
					say (al_error.message)
				end
				reload_favorites
			end
		end

	open_move_sheet (a_node: BIB_FAVORITE_NODE)
			-- A sheet to choose the folder `a_node' goes to (a folder never into itself or below itself).
		local
			l_column: SW_COLUMN
			l_row: SW_ROW
			l_folder: SW_SELECT
			l_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER]
			l_ok, l_cancel: SW_BUTTON
		do
			create l_folders.make (8)
			across favorites_state.shown_folders_by_path as ic loop
				if not (attached a_node.folder as al_moving and then favorites_state.is_inside (ic.id, al_moving.id)) then
					l_folders.extend (ic)
				end
			end
			create l_folder.make
			l_folder.add_option ("Top level")
			across l_folders as ic loop
				l_folder.add_option (favorites_state.folder_path (ic.id))
			end
			l_folder.select_index (1)
			create l_ok.make ("Move", agent confirm_move (a_node, l_folder, l_folders))
			create l_cancel.make ("Cancel", agent window.close_sheet)
			create l_column.make
			l_column := l_column.with_padding (16.0).with_gap (10.0)
			l_column.put (create {SW_LABEL}.make_ui ({STRING_32} "Move " + a_node.label + {STRING_32} " to"))
			l_column.put (l_folder)
			create l_row.make
			l_row.put (l_ok)
			l_row.put (l_cancel)
			l_column.put (l_row)
			window.show_sheet (l_column, 420.0)
		end

	confirm_move (a_node: BIB_FAVORITE_NODE; a_folder: SW_SELECT; a_folders: ARRAYED_LIST [BIB_FAVORITE_FOLDER])
			-- Move pressed.
		local
			l_target: INTEGER_64
		do
			if a_folder.selected_index >= 2 and a_folder.selected_index - 1 <= a_folders.count then
				l_target := a_folders.i_th (a_folder.selected_index - 1).id
			end
			window.close_sheet
			move_favorite_node (a_node, l_target)
		end

	move_favorite_node (a_node: BIB_FAVORITE_NODE; a_target: INTEGER_64)
			-- `a_node''s row into folder `a_target' (0: the top level); a folder never into itself or
			-- below itself.
		local
			l_from: INTEGER_64
		do
			if user_store.is_open then
				if attached a_node.folder as al_folder then
					l_from := al_folder.parent_id
					if (not favorites_state.is_inside (a_target, al_folder.id) or a_target = 0) and a_target /= l_from then
						user_store.move_favorite_folder (al_folder, a_target)
						if user_store.write_error = Void then
							favorites_history.record ({STRING_32} "Move " + a_node.label,
								agent move_folder_to (al_folder, l_from), agent move_folder_to (al_folder, a_target))
						end
					end
				elseif attached a_node.item as al_item then
					l_from := al_item.folder_id
					if a_target /= l_from then
						user_store.move_favorite (al_item, a_target)
						if user_store.write_error = Void then
							favorites_history.record ({STRING_32} "Move " + a_node.label,
								agent move_item_to (al_item, l_from), agent move_item_to (al_item, a_target))
						end
					end
				end
				if attached user_store.write_error as al_error then
					say (al_error.message)
				end
				reload_favorites
			end
		end

	remove_chosen_favorite
			-- The bin: remove the chosen line.
		do
			if attached favorites_tree.selected_node as al_node then
				remove_favorite_node (al_node)
			end
		end

	remove_favorite_node (a_node: BIB_FAVORITE_NODE)
			-- `a_node''s row removed softly (a folder hides everything in it); Restore brings it back.
		do
			if user_store.is_open then
				if attached a_node.folder as al_folder then
					user_store.set_favorite_folder_removed (al_folder, True)
				elseif attached a_node.item as al_item then
					user_store.set_favorite_removed (al_item, True)
				end
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					set_last_removed_favorite (a_node)
					if favorites_tree.selected_node = a_node then
						choose_favorite (Void)
					end
					reload_favorites
					if attached a_node.folder as al_gone then
						favorites_history.record ({STRING_32} "Remove " + a_node.label,
							agent set_folder_removed (al_gone, False), agent set_folder_removed (al_gone, True))
					elseif attached a_node.item as al_gone_item then
						favorites_history.record ({STRING_32} "Remove " + a_node.label,
							agent set_item_removed (al_gone_item, False), agent set_item_removed (al_gone_item, True))
					end
					notice_with_undo ({STRING_32} "Removed " + a_node.label + {STRING_32} ".")
				end
			end
		end

	restore_favorite
			-- Restore: what Remove took away last.
		do
			if attached last_removed_favorite as al_node and user_store.is_open then
				if attached al_node.folder as al_folder then
					user_store.set_favorite_folder_removed (al_folder, False)
				elseif attached al_node.item as al_item then
					user_store.set_favorite_removed (al_item, False)
				end
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					if attached al_node.folder as al_back then
						favorites_history.record ({STRING_32} "Restore " + al_node.label,
							agent set_folder_removed (al_back, True), agent set_folder_removed (al_back, False))
					elseif attached al_node.item as al_back_item then
						favorites_history.record ({STRING_32} "Restore " + al_node.label,
							agent set_item_removed (al_back_item, True), agent set_item_removed (al_back_item, False))
					end
					set_last_removed_favorite (Void)
					reload_favorites
				end
			end
		end

	show_stars
			-- The chapter's verse rows (and Parallel's) follow the favorites (`favorites_state' tells);
			-- the grids, History and the Books tree ask as they draw.
		do
			if reading.has_place then
				star_rows (reading_view)
				if is_study then
					star_rows (parallel_view)
				end
			end
			window.request_render
		end

	star_rows (a_view: SW_PARALLEL_TEXT)
			-- Each verse row of `a_view' (which lists `reading_verses') starred when a verse or range
			-- among the favorites takes it in.
		local
			l_hub: BIB_HUB_ID
			i: INTEGER
		do
			create l_hub
			from i := 1 until i > reading_verses.count or i > a_view.row_count loop
				if not a_view.is_note_row (i) then
					a_view.set_row_starred (i, favorites_state.is_verse_starred (l_hub.hub_id (reading_book, reading_chapter, reading_verses.i_th (i).verse)))
				end
				i := i + 1
			end
		end

	visit_starred (a_visit: BIB_VISIT): BOOLEAN
			-- History: is the verse among the favorites?
		do
			Result := favorites_state.is_verse_starred (a_visit.hub_id)
		end

	hit_starred (a_verse: BIB_READING_VERSE): BOOLEAN
			-- Search results: is the verse among the favorites?
		do
			Result := favorites_state.is_verse_starred ((create {BIB_HUB_ID}).hub_id (a_verse.book_id, a_verse.chapter, a_verse.verse))
		end

	cross_ref_starred (a_ref: BIB_READING_CROSS_REF): BOOLEAN
			-- Cross-references: is a verse of the target among the favorites?
		local
			l_hub: BIB_HUB_ID
			v: INTEGER
		do
			create l_hub
			from v := a_ref.verse_start until Result or v > a_ref.verse_end.max (a_ref.verse_start) loop
				Result := favorites_state.is_verse_starred (l_hub.hub_id (a_ref.to_book, a_ref.to_chapter, v))
				v := v + 1
			end
		end

	nav_icon (a_node: BIB_NAV_NODE): INTEGER
			-- The Books tree: a chapter among the favorites wears the star.
		do
			if a_node.is_chapter and then favorites_state.is_chapter_starred (a_node.book_id, a_node.chapter) then
				Result := {SW_PAINTER}.Glyph_star
			end
		end

	snapshot_favorites
			-- For a snapshot: two folders, one inside the other, a verse, a range and a whole chapter,
			-- the folders open.
		local
			l_grace, l_faith: BIB_FAVORITE_FOLDER
		do
			if user_store.is_open then
				create l_grace.make (0, "Grace")
				user_store.add_favorite_folder (l_grace)
				create l_faith.make (l_grace.id, "Faith")
				user_store.add_favorite_folder (l_faith)
				add_favorite (1, 0, "", l_faith.id)
				add_favorite (2, reading_verse + 2, "", l_grace.id)
				add_favorite (3, 0, "", 0)
				favorites_tree.expand_node (folder_node (l_grace))
				favorites_tree.expand_node (folder_node (l_faith))
			end
		end

	item_place (a_item: BIB_USER_ITEM): STRING_32
			-- "Jude 1:6": the place of a verse-keyed item in any list (scan 46: one for the four kinds).
		do
			Result := hub_place (a_item.hub_id)
		end

	is_reselecting: BOOLEAN
			-- Is `reselect' choosing a row after a refill (no click for a select handler to answer)?

	reselect (a_grid: SW_DATA_GRID [ANY]; a_row: INTEGER)
			-- Select row `a_row' of `a_grid' (0: none) after a refill. Scan 46: one guard for every
			-- list the window refills (Tags, Journal, History each had their own).
		require
			in_range: a_row >= 0 and a_row <= a_grid.rows.count
		do
			is_reselecting := True
			a_grid.select_model_row (a_row)
			is_reselecting := False
		ensure
			guard_down: not is_reselecting
		end

	History_tab: INTEGER = 3
			-- T1's History page.

	Default_history_limit: INTEGER = 200
			-- The Kept list's length unless the reader sets another (Larry, 2026-11-01).

	Min_history_limit: INTEGER = 10
	Max_history_limit: INTEGER = 1000
			-- The lengths the reader may choose (the longest is the store's `Max_recent_places').

	History_limit_key: STRING_8 = "history_limit"
			-- The user.db setting that keeps the reader's choice.

	history_limit: INTEGER
			-- How many verses the Kept list shows.
		do
			Result := Default_history_limit
			if user_store.has_setting (History_limit_key) and then user_store.setting (History_limit_key).is_integer then
				Result := user_store.setting (History_limit_key).to_integer.max (Min_history_limit).min (Max_history_limit)
			end
		ensure
			in_range: Result >= Min_history_limit and Result <= Max_history_limit
		end

	set_history_limit (a_limit: INTEGER)
			-- The Kept list shows `a_limit' verses (kept to the lengths allowed), from now on.
		do
			user_store.set_setting (History_limit_key, a_limit.max (Min_history_limit).min (Max_history_limit).out)
			history_keep_box.set_value (history_limit)
			fill_history
		ensure
			kept_in_range: history_limit = a_limit.max (Min_history_limit).min (Max_history_limit)
		end

	history_heading: SW_LABEL
	history_grid: SW_DATA_GRID [BIB_VISIT]

	history_rows: ARRAYED_LIST [BIB_VISIT]
			-- The rows of `history_grid'.

	history_scope: SW_SEGMENTED
			-- This session's verses, or the kept ones.

	history_keep_box: SW_NUMBER_BOX
			-- How many verses the Kept list shows.

	session_visits: ARRAYED_LIST [BIB_VISIT]
			-- Every verse touched since the window opened, newest first, each once.

	last_recorded_hub: INTEGER_64
			-- The place `note_visit' recorded last.

	is_history_write_failed: BOOLEAN
			-- Did a visit fail to save? Told once, then not tried again this run (scan 46).

	is_session_history: BOOLEAN
			-- Does the History tab list this session's verses (else the kept ones)?
		do
			Result := history_scope.selected_index = 1
		end

	note_visit
			-- The verse read (the chapter, when no verse is) joins this session's list and user.db
			-- (`reading' tells; Larry, 2026-11-01: every verse touched, not one visit per chapter).
		local
			l_hub: INTEGER_64
			l_visit: BIB_VISIT
			i: INTEGER
		do
			l_hub := (create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse.max (1))
			if l_hub /= last_recorded_hub then
				last_recorded_hub := l_hub
				create l_visit.make (l_hub, "reading")
				if user_store.is_open and not is_history_write_failed then
					user_store.record_visit (l_visit)
					if attached user_store.write_error as al_error then
						is_history_write_failed := True
						say ({STRING_32} "History was not saved: " + al_error.message)
					end
				end
				from i := session_visits.count until i < 1 loop
					if session_visits.i_th (i).hub_id = l_hub then
						session_visits.go_i_th (i)
						session_visits.remove
					end
					i := i - 1
				end
				session_visits.put_front (l_visit)
				fill_history
			end
		ensure
			newest_first: reading.has_place implies session_visits.first.hub_id = (create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse.max (1))
		end

	fill_history
			-- This session's verses or the kept ones, newest first; the verse read stays selected.
		local
			i, l_index: INTEGER
			l_hub: INTEGER_64
		do
			if is_session_history then
				create history_rows.make_from_array (session_visits.to_array)
			elseif user_store.is_open then
				history_rows := user_store.recent_visits (history_limit)
			else
				create history_rows.make (0)
			end
			history_grid.set_rows (history_rows)
			if reading.has_place then
				l_hub := (create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse.max (1))
			end
			from i := 1 until i > history_rows.count or l_index > 0 loop
				if history_rows.i_th (i).hub_id = l_hub then
					l_index := i
				end
				i := i + 1
			end
			reselect (history_grid, l_index)
			history_keep_box.set_enabled (not is_session_history and user_store.is_open)
			if is_session_history then
				if history_rows.is_empty then
					history_heading.set_text ("Nothing read yet in this session.")
				else
					history_heading.set_text (history_rows.count.out.to_string_32 + {STRING_32} " verses this session, newest first.")
				end
			elseif not user_store.is_open then
				history_heading.set_text ("History is not kept: user.db is not open.")
			elseif history_rows.is_empty then
				history_heading.set_text ("No history yet: the verses you read are kept here.")
			else
				history_heading.set_text ({STRING_32} "Kept: the last " + history_rows.count.out + {STRING_32} " verses read.")
			end
		end

	on_history_row (a_row: INTEGER)
			-- A chapter clicked: read it again, at the verse it was opened at.
		do
			if not is_reselecting and then a_row >= 1 and then a_row <= history_rows.count then
				go_to_hub (history_rows.i_th (a_row).hub_id)
			end
		end

	visit_when (a_visit: BIB_VISIT): STRING_32
			-- "5 minutes ago".
		do
			if attached a_visit.created_at as al_at then
				Result := al_at.time_ago.to_string_32
			else
				create Result.make_empty
			end
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
			l_tabs.add_page ("Journal", journal_page)
			l_tabs.add_page ("Tags", tags_page)
			l_tabs.add_page ("Highlights", highlights_page)
			l_tabs.add_page ("Prayer", prayer_page)
			l_tabs.add_page ("Memory", memory_page)
			notes_tabs := l_tabs
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

	notes_tabs: detachable SW_TABS
			-- P06's tabs, once built.

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
			delete_note_button.set_enabled (False)
			restore_note_button.set_enabled (last_deleted_note > 0)
			notes_listed.call (Void)
		end

	notes_listed: SW_EVENT [TUPLE]
			-- Told whenever the chapter's notes are listed again (research/23 phase 5: the Notes dot
			-- was set only when a chapter was read, so a first note or a last deletion left it wrong,
			-- risk 6).
		attribute
			create Result.make
		end

	commentary_found: SW_EVENT [TUPLE]
			-- Told whenever the commentary for the verse is looked up (`has_commentary' settled).
		attribute
			create Result.make
		end

	word_opened: SW_EVENT [TUPLE]
			-- Told whenever a word opens in the lexicon (`study_lemma' set).
		attribute
			create Result.make
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
				say ("Write the note in the box first.")
			elseif user_store.is_open and reading.has_verse and note_store.is_writable then
				create l_note.make (reading_hub, "", l_body)
				note_store.add_note (l_note)
				if attached note_store.last_error as al_error then
					say (al_error.message)
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
					say (al_error.message)
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
		do
			delete_note_at (notes_list.selected_index)
		end

	delete_note_at (a_index: INTEGER)
			-- Soft-delete note `a_index' of the list (the Delete button's, and a right-click's).
		local
			l_index: INTEGER
		do
			l_index := a_index
			if l_index >= 1 and l_index <= note_rows.count and then note_store.is_writable then
				note_store.remove_note (note_rows.i_th (l_index).id)
				if attached note_store.last_error as al_error then
					say (al_error.message)
				else
					last_deleted_note := note_rows.i_th (l_index).id
					fill_notes
					say ("Note deleted. Restore brings it back.")
				end
			end
		end

	restore_note
			-- Bring back the note Delete removed last.
		do
			if last_deleted_note > 0 and then note_store.is_writable and then note_store.is_deleted (last_deleted_note) then
				note_store.restore_note (last_deleted_note)
				if attached note_store.last_error as al_error then
					say (al_error.message)
				else
					last_deleted_note := 0
					fill_notes
				end
			end
		end

	highlights_heading, highlight_reason_label: SW_LABEL
	highlight_reason_box: SW_TEXT_BOX
	highlight_button: SW_BUTTON
	highlights_grid: SW_DATA_GRID [BIB_HIGHLIGHT]
			-- T2's Highlights tab (E01): every highlight, and a reason for the verse read.

	highlights_panel: BIB_ITEM_LIST_PANEL [BIB_HIGHLIGHT]
			-- The highlights list, in Bible order, with Remove and Restore.

	Journal_tab: INTEGER = 2
			-- P06's Journal page.

	journal_title_box: SW_TEXT_BOX
	journal_body_box: SW_TEXT_BOX
	journal_new_button, journal_save_button, journal_delete_button, journal_restore_button: SW_BUTTON
	journal_heading: SW_LABEL
	journal_grid: SW_DATA_GRID [BIB_NOTE]
			-- T2's Journal tab (E04): topical notes, on a subject rather than a verse.

	journal_rows: ARRAYED_LIST [BIB_NOTE]
			-- The rows of `journal_grid', oldest first.

	journal_entry_id: INTEGER_64
			-- The entry in the boxes (0: a new one).

	journal_shown_title: STRING_32
			-- The title the entry in the boxes was loaded with.
		attribute
			create Result.make_empty
		end

	last_deleted_entry: INTEGER_64
			-- The journal entry Delete removed last; the Journal's Restore brings it back (0: none). Its
			-- own slot: scan 45 found the Journal and Verse notes sharing one, each Delete losing the
			-- other's, and Verse notes never showing a journal entry it restored.

	Prayer_tab: INTEGER = 5
	Memory_tab: INTEGER = 6
			-- P06's Prayer and Memory pages.

	prayer_title_box, prayer_answer_box: SW_TEXT_BOX
	prayer_body_box: SW_TEXT_BOX
	prayer_add_button, prayer_answered_button: SW_BUTTON
	prayer_open_heading, prayer_answered_heading: SW_LABEL
	prayer_open_grid, prayer_answered_grid: SW_DATA_GRID [BIB_PRAYER]
			-- T2's Prayer tab (E06): requests, open and answered.

	prayer_open_rows, prayer_answered_rows: ARRAYED_LIST [BIB_PRAYER]
			-- The rows of the two grids.

	prayer_open_panel, prayer_answered_panel: BIB_ITEM_LIST_PANEL [BIB_PRAYER]
			-- The two lists with their Remove and Restore (design scan 54: hand-made copies brought back
			-- the stale selection scan 43 fixed).

	read_hub_if_any (a_hub: INTEGER_64)
			-- Read verse `a_hub' when a prayer rests on one (0: none).
		do
			if a_hub > 0 then
				go_to_hub (a_hub)
			end
		end

	prayer_page: SW_COLUMN
			-- A title and the request, Add; the open prayers; the answered ones with how.
		local
			l_row: SW_ROW
			l_open, l_answered: SW_COLUMN
		do
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (prayer_title_box)
			Result.put (prayer_body_box)
			Result.put (prayer_add_button)
				-- The open and the answered prayers on their own tabs: one under the other, the narrow
				-- Notes pane hid the answered list (seen by snapshot, 2026-10-27).
			create l_open.make
			l_open := l_open.with_gap (6.0)
			l_open.put (prayer_open_heading)
			l_open.put (prayer_open_grid.growing)
			create l_row.make
			l_row.put (prayer_answer_box.growing)
			l_row.put (prayer_answered_button)
			l_open.put (l_row)
			create l_row.make
			l_row.put (prayer_open_panel.remove_button)
			l_row.put (prayer_open_panel.restore_button)
			l_open.put (l_row)
			create l_answered.make
			l_answered := l_answered.with_gap (6.0)
			l_answered.put (prayer_answered_heading)
			l_answered.put (prayer_answered_grid.growing)
			l_answered.put (prayer_answer_detail)
			create l_row.make
			l_row.put (prayer_answered_panel.remove_button)
			l_row.put (prayer_answered_panel.restore_button)
			l_answered.put (l_row)
			create prayer_tabs.make
			prayer_tabs.add_page ("Open", l_open)
			prayer_tabs.add_page ("Answered", l_answered)
			Result.put (prayer_tabs.growing)
		end

	prayer_tabs: SW_TABS
			-- Open and Answered (made with `prayer_page').
		attribute
			create Result.make
		end

	fill_prayers
			-- Both lists from user.db.
		do
			if user_store.is_open then
				prayer_open_rows := user_store.prayers (False)
				prayer_answered_rows := user_store.prayers (True)
			else
				create prayer_open_rows.make (0)
				create prayer_answered_rows.make (0)
			end
			prayer_open_panel.set_rows (prayer_open_rows)
			prayer_answered_panel.set_rows (prayer_answered_rows)
			if prayer_open_rows.is_empty then
				prayer_open_heading.set_text ("Open: none. Write a title and the request, then Add.")
			else
				prayer_open_heading.set_text ({STRING_32} "Open (" + prayer_open_rows.count.out + {STRING_32} "), newest first. Click one, write how it was answered below, then Answered.")
			end
			if prayer_answered_rows.is_empty then
				prayer_answered_heading.set_text ("Answered: none yet.")
			else
				prayer_answered_heading.set_text ({STRING_32} "Answered (" + prayer_answered_rows.count.out + {STRING_32} "), latest first:")
			end
			prayer_add_button.set_enabled (user_store.is_open)
		end

	add_prayer
			-- The title and request become an open prayer.
		local
			l_title, l_body: STRING_32
			l_prayer: BIB_PRAYER
		do
			l_title := prayer_title_box.text.twin
			l_title.left_adjust
			l_title.right_adjust
			l_body := prayer_body_box.text.twin
			l_body.left_adjust
			l_body.right_adjust
			if l_title.is_empty then
				say ("Give the prayer a title first.")
			elseif user_store.is_open then
				if prayer_hub > 0 and then l_title.same_string (prayer_hub_title) then
						-- begun from a verse's menu, and still titled by it
					create l_prayer.make (l_title, l_body, prayer_hub)
				else
					create l_prayer.make (l_title, l_body, 0)
				end
				prayer_hub := 0
				user_store.add_prayer_item (l_prayer)
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					prayer_title_box.set_text ("")
					prayer_body_box.set_text ("")
					fill_prayers
					say ("Prayer kept.")
				end
			end
		end

	mark_prayer_answered
			-- The chosen open prayer answered today, as the answer box tells.
		do
			if prayer_open_panel.chosen_id = 0 then
				say ("Click an open prayer first.")
			elseif user_store.is_open then
				user_store.set_prayer_answered (prayer_open_panel.chosen_id, prayer_answer_box.text)
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					prayer_answer_box.set_text ("")
					fill_prayers
					say ("Marked answered.")
				end
			end
		end

	prayer_since (a_prayer: BIB_PRAYER): STRING_32
			-- The day it was written.
		do
			Result := a_prayer.created_on.head (10)
		end

	prayer_answered_day (a_prayer: BIB_PRAYER): STRING_32
			-- The day it was answered.
		do
			Result := a_prayer.answered_on.head (10)
		end

	memory_add_button, memory_show_button, memory_again_button, memory_hard_button, memory_good_button, memory_easy_button: SW_BUTTON
	memory_heading, memory_place_label, memory_text_label: SW_LABEL
	memory_grid: SW_DATA_GRID [BIB_MEMORY_CARD]
			-- T2's Memory tab (E07): verses to learn, spaced (BIB_MEMORY_SCHEDULE).

	memory_rows: ARRAYED_LIST [BIB_MEMORY_CARD]
			-- Every card, soonest first.

	memory_due: ARRAYED_LIST [BIB_MEMORY_CARD]
			-- The cards due today; the first is the one under review.

	memory_panel: BIB_ITEM_LIST_PANEL [BIB_MEMORY_CARD]
			-- Every card, with Remove and Restore (design scan 54: Memory had no Restore).

	today_text: STRING_8
			-- Today, as an ISO date.
		do
			Result := (create {SIMPLE_DATE}.make_now).to_iso8601
		end

	memory_page: SW_COLUMN
			-- Learn the verse read; today's card to recall and grade; every card with its next date.
		local
			l_row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (memory_add_button)
			Result.put (memory_heading)
			Result.put (memory_place_label)
			Result.put (memory_text_label)
			create l_row.make
			l_row.put (memory_show_button)
			l_row.put (memory_again_button)
			l_row.put (memory_hard_button)
			l_row.put (memory_good_button)
			l_row.put (memory_easy_button)
			Result.put (l_row)
			Result.put (memory_grid.growing)
			create l_row.make
			l_row.put (memory_panel.remove_button)
			l_row.put (memory_panel.restore_button)
			Result.put (l_row)
		end

	fill_memory
			-- The cards from user.db; the first due one up for review, its text hidden.
		do
			if user_store.is_open then
				memory_rows := user_store.memory_cards ("")
				memory_due := user_store.memory_cards (today_text)
			else
				create memory_rows.make (0)
				create memory_due.make (0)
			end
			memory_panel.set_rows (memory_rows)
			if memory_rows.count = 1 then
				memory_heading.set_text ({STRING_32} "1 card; " + memory_due.count.out + {STRING_32} " due today.")
			else
				memory_heading.set_text (memory_rows.count.out.to_string_32 + {STRING_32} " cards; " + memory_due.count.out + {STRING_32} " due today.")
			end
			memory_text_label.set_text ("")
			if memory_due.is_empty then
				memory_place_label.set_text ("Nothing to review today.")
			else
				memory_place_label.set_text ({STRING_32} "Recall " + hub_place (memory_due.first.hub_id) + {STRING_32} ", then Show the verse and grade yourself.")
			end
			memory_show_button.set_enabled (not memory_due.is_empty)
			memory_again_button.set_enabled (False)
			memory_hard_button.set_enabled (False)
			memory_good_button.set_enabled (False)
			memory_easy_button.set_enabled (False)
		end

	add_memory_card
			-- The verse read becomes a card, due today.
		local
			l_card: BIB_MEMORY_CARD
		do
			if not reading.has_verse then
				say ("Click a verse to learn it.")
			elseif user_store.is_open then
				if user_store.has_memory_card (reading_hub) then
					say (place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} " is already a card.")
				else
					create l_card.make (reading_hub, today_text)
					user_store.add_memory_card (l_card)
					if attached user_store.write_error as al_error then
						say (al_error.message)
					else
						fill_memory
						say (place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} " is a card, due today.")
					end
				end
			end
		end

	show_memory_verse
			-- The text of the card under review, in the version read; grading opens.
		do
			if not memory_due.is_empty and not reading_version.is_empty and then bible.text_reader.has_version (reading_version) then
				if attached verse_text_at_hub (memory_due.first.hub_id) as al_text then
					memory_text_label.set_text (al_text)
				end
				memory_again_button.set_enabled (True)
				memory_hard_button.set_enabled (True)
				memory_good_button.set_enabled (True)
				memory_easy_button.set_enabled (True)
			end
		end

	grade_memory_card (a_grade: INTEGER)
			-- The card under review graded `a_grade' (Again 1, Hard 3, Good 4, Easy 5); the next one up.
		require
			grade_valid: (create {BIB_MEMORY_SCHEDULE}).is_valid_grade (a_grade)
		do
			if not memory_due.is_empty and user_store.is_open then
				user_store.record_review (memory_due.first, a_grade, create {SIMPLE_DATE}.make_from_string (today_text))
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					say ({STRING_32} "Next review: " + memory_due.first.due_on + {STRING_32} ".")
					fill_memory
				end
			end
		end

	memory_card_place (a_card: BIB_MEMORY_CARD): STRING_32
			-- "John 3:16".
		do
			Result := hub_place (a_card.hub_id)
		end

	memory_card_due (a_card: BIB_MEMORY_CARD): STRING_32
			-- Its next date, or "today".
		do
			if a_card.is_due (today_text) then
				Result := {STRING_32} "today"
			else
				Result := a_card.due_on
			end
		end

	journal_page: SW_COLUMN
			-- The Journal tab: a title, a body, New, Save and Delete, then every entry.
		local
			l_row: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (journal_title_box)
			Result.put (journal_body_box)
				-- The buttons on their own line: beside the title the narrow panel cut Delete off.
			create l_row.make
			l_row.put (journal_new_button)
			l_row.put (journal_save_button)
			l_row.put (journal_delete_button)
			l_row.put (journal_restore_button)
			Result.put (l_row)
			Result.put (journal_heading)
			Result.put (journal_grid.growing)
		end

	fill_journal
			-- Every journal entry; the one in the boxes stays selected.
		local
			i, l_index: INTEGER
		do
			if user_store.is_open then
				journal_rows := note_store.notes_for (0)
			else
				create journal_rows.make (0)
			end
			journal_grid.set_rows (journal_rows)
			from i := 1 until i > journal_rows.count or l_index > 0 loop
				if journal_rows.i_th (i).id = journal_entry_id then
					l_index := i
				end
				i := i + 1
			end
			if l_index = 0 then
				journal_entry_id := 0
			end
			reselect (journal_grid, l_index)
			if journal_rows.is_empty then
				journal_heading.set_text ("No journal entries yet: write a title and a body, then Save.")
			else
				if journal_rows.count = 1 then
					journal_heading.set_text ("Your journal (1 entry; click it to edit it):")
				else
					journal_heading.set_text ({STRING_32} "Your journal (" + journal_rows.count.out + {STRING_32} " entries; click one to edit it):")
				end
			end
			journal_save_button.set_enabled (user_store.is_open)
			journal_delete_button.set_enabled (journal_entry_id > 0)
			journal_restore_button.set_enabled (last_deleted_entry > 0)
		end

	new_journal_entry
			-- Empty boxes for a new entry.
		do
			journal_entry_id := 0
			journal_title_box.set_text ("")
			journal_body_box.set_text ("")
			create journal_shown_title.make_empty
			fill_journal
		end

	save_journal_entry
			-- A new entry is added; an entry being edited gets the body as its next version (the old
			-- one kept).
		local
			l_title, l_body: STRING_32
			l_note: BIB_NOTE
		do
			l_title := journal_title_box.text.twin
			l_title.left_adjust
			l_title.right_adjust
			l_body := journal_body_box.text.twin
			l_body.left_adjust
			l_body.right_adjust
			if not note_store.is_writable then
				say ("The journal cannot be written now.")
			elseif l_body.is_empty then
					-- As Verse notes: a note has words (scan 45).
				say ("Write the entry first.")
			elseif journal_entry_id > 0 then
				if note_store.current_body (journal_entry_id).same_string (l_body) then
					if l_title.same_string (journal_shown_title) then
						say ("Nothing changed.")
					else
						say ("Titles stay as first written; nothing else changed.")
					end
				else
					note_store.update_note (journal_entry_id, l_body)
					if attached note_store.last_error as al_error then
						say (al_error.message)
					elseif l_title.same_string (journal_shown_title) then
						say ("Saved; the earlier version is kept.")
						fill_journal
					else
							-- Scan 45: a changed title was dropped while "Saved" was said.
						say ("Saved; the earlier version is kept. Titles stay as first written.")
						fill_journal
					end
				end
			elseif l_title.is_empty then
				say ("Give the entry a title first.")
			else
				create l_note.make_topical (l_title, l_body)
				note_store.add_note (l_note)
				if attached note_store.last_error as al_error then
					say (al_error.message)
				else
					journal_entry_id := l_note.id
					journal_shown_title := l_title.twin
					say ("Saved.")
					fill_journal
				end
			end
		end

	delete_journal_entry
			-- Soft-delete the entry in the boxes (its history kept).
		do
			if journal_entry_id > 0 and then note_store.is_writable then
				note_store.remove_note (journal_entry_id)
				if attached note_store.last_error as al_error then
					say (al_error.message)
				else
					last_deleted_entry := journal_entry_id
					new_journal_entry
					say ("Entry deleted. Restore brings it back.")
				end
			end
		end

	restore_journal_entry
			-- Bring back the journal entry Delete removed last.
		do
			if last_deleted_entry > 0 and then note_store.is_writable and then note_store.is_deleted (last_deleted_entry) then
				note_store.restore_note (last_deleted_entry)
				if attached note_store.last_error as al_error then
					say (al_error.message)
				else
					journal_entry_id := last_deleted_entry
					last_deleted_entry := 0
					fill_journal
				end
			end
		end

	on_journal_row (a_row: INTEGER)
			-- An entry clicked: into the boxes for editing.
		do
			if not is_reselecting and then a_row >= 1 and then a_row <= journal_rows.count then
				journal_entry_id := journal_rows.i_th (a_row).id
				journal_title_box.set_text (journal_rows.i_th (a_row).title)
				journal_shown_title := journal_rows.i_th (a_row).title.twin
				journal_body_box.set_text (journal_rows.i_th (a_row).body)
				journal_delete_button.set_enabled (True)
			end
		end

	Tags_tab: INTEGER = 3
			-- P06's Tags page.

	tag_label, tagged_heading: SW_LABEL
	tag_box: SW_TEXT_BOX
	tag_button: SW_BUTTON
	tag_names_grid: SW_DATA_GRID [TUPLE [tag: STRING_32; verses: INTEGER]]
	tagged_grid: SW_DATA_GRID [BIB_TAG_ASSIGNMENT]
			-- T2's Tags tab (E05): a tag for the verse read, every tag with its count, and the verses
			-- of the tag chosen.

	tag_name_rows: ARRAYED_LIST [TUPLE [tag: STRING_32; verses: INTEGER]]
			-- The rows of `tag_names_grid'.

	chosen_tag: STRING_32
			-- The tag whose verses `tagged_panel' lists; empty for none.

	reading_hub: INTEGER_64
			-- The verse read as a hub id (scan 44: the expression was written at each use).
		require
			a_verse_read: reading.has_verse
		do
			Result := (create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse)
		end

	tagged_panel: BIB_ITEM_LIST_PANEL [BIB_TAG_ASSIGNMENT]
			-- The chosen tag's verses, with Remove and Restore.

	tags_page: SW_COLUMN
			-- The Tags tab.
		local
			l_row, l_buttons: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (tag_label)
			create l_row.make
			l_row.put (tag_box.growing)
			l_row.put (tag_button)
			Result.put (l_row)
			Result.put (tag_names_grid.growing)
				-- The chosen tag's heading and its Remove and Restore share a line: the panel is short.
			create l_buttons.make
			l_buttons.put (tagged_heading.growing)
			l_buttons.put (tagged_panel.remove_button)
			l_buttons.put (tagged_panel.restore_button)
			Result.put (l_buttons)
			Result.put (tagged_grid.growing)
		end

	fill_tags
			-- The Tags tab follows the place read: every tag and its count, the chosen tag's verses, and
			-- the box for tagging the verse read.
		local
			i, l_index: INTEGER
		do
			if user_store.is_open then
				tag_name_rows := user_store.tag_counts
			else
				create tag_name_rows.make (0)
			end
			tag_names_grid.set_rows (tag_name_rows)
				-- The chosen tag stays selected by name, not by row (scan 44: tag names sort, so a new
				-- tag moved the old choice to another row).
			from i := 1 until i > tag_name_rows.count or l_index > 0 loop
				if tag_name_rows.i_th (i).tag.same_string (chosen_tag) then
					l_index := i
				end
				i := i + 1
			end
			if l_index = 0 then
				chosen_tag := {STRING_32} ""
			end
			reselect (tag_names_grid, l_index)
			if chosen_tag.is_empty or not user_store.is_open then
				tagged_panel.set_rows (create {ARRAYED_LIST [BIB_TAG_ASSIGNMENT]}.make (0))
				if tag_name_rows.is_empty then
					tagged_heading.set_text ("No tags yet: tag the verse read, then click a tag for its verses.")
				else
					tagged_heading.set_text ("Click a tag for its verses.")
				end
			else
				tagged_panel.set_rows (user_store.assignments_tagged (chosen_tag))
				tagged_heading.set_text ({STRING_32} "Verses tagged " + chosen_tag + {STRING_32} ":")
			end
		end

	tag_verse
			-- The verse read gets the tag in the box.
		local
			l_tag: STRING_32
		do
			l_tag := tag_box.text.twin
			l_tag.left_adjust
			l_tag.right_adjust
			if l_tag.is_empty then
				say ("Name the tag first.")
			elseif user_store.is_open and reading.has_verse then
				user_store.tag_verse (create {BIB_TAG_ASSIGNMENT}.make (reading_hub, l_tag))
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					tag_box.set_text ("")
					chosen_tag := l_tag
					fill_tags
				end
			end
		end

	on_tag_name (a_row: INTEGER)
			-- A tag clicked: its verses listed.
		do
			if not is_reselecting and then a_row >= 1 and then a_row <= tag_name_rows.count then
				chosen_tag := tag_name_rows.i_th (a_row).tag.twin
				fill_tags
			end
		end

	tag_name_text (a_row: TUPLE [tag: STRING_32; verses: INTEGER]): STRING_32
		do
			Result := a_row.tag
		end

	tag_verses_text (a_row: TUPLE [tag: STRING_32; verses: INTEGER]): STRING_32
		do
			Result := a_row.verses.out
		end

	Highlights_tab: INTEGER = 4
			-- P06's Highlights page.

	highlight_detail, prayer_answer_detail: SW_LABEL
			-- The chosen highlight's reason and the chosen answered prayer's answer, in full and wrapped
			-- (Larry, 2026-11-01: the lists cut long text off at the column's edge).

	show_highlight_detail (a_id: INTEGER_64)
			-- The highlight `a_id' (0: none chosen) read in full (`highlights_panel' tells).
		do
			highlight_detail.set_text ("Click a highlight to read its reason in full.")
			across highlights_panel.rows as ic loop
				if ic.id = a_id then
					highlight_detail.set_text (item_place (ic) + {STRING_32} ": " + ic.reason)
				end
			end
		end

	show_answer_detail (a_id: INTEGER_64)
			-- The answered prayer `a_id' (0: none chosen) and its answer in full (`prayer_answered_panel'
			-- tells).
		do
			prayer_answer_detail.set_text ("Click an answered prayer to read its answer in full.")
			across prayer_answered_panel.rows as ic loop
				if ic.id = a_id then
					if ic.answer.is_empty then
						prayer_answer_detail.set_text (ic.title + {STRING_32} ": no answer written.")
					else
						prayer_answer_detail.set_text (ic.title + {STRING_32} ": " + ic.answer)
					end
				end
			end
		end

	highlights_page: SW_COLUMN
			-- The Highlights tab: a reason and Highlight for the verse read, then every highlight.
		local
			l_buttons: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (highlight_reason_label)
			Result.put (highlight_reason_box)
			create l_buttons.make
			l_buttons.put (highlight_button)
			l_buttons.put (highlights_panel.remove_button)
			l_buttons.put (highlights_panel.restore_button)
			Result.put (l_buttons)
			Result.put (highlights_heading)
			Result.put (highlights_grid.growing)
			Result.put (highlight_detail)
		end

	fill_highlights
			-- The Highlights tab follows the place read: every highlight (a click opens its verse), and
			-- the reason box for the verse read.
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			if user_store.is_open then
				highlights_panel.set_rows (user_store.highlights_between (l_hub.hub_id (1, 1, 1), l_hub.hub_id (l_hub.Max_part, l_hub.Max_part, l_hub.Max_part)))
			else
				highlights_panel.set_rows (create {ARRAYED_LIST [BIB_HIGHLIGHT]}.make (0))
			end
			if highlights_panel.rows.is_empty then
				highlights_heading.set_text ("No highlights yet: a highlight is a reason, not a color.")
			else
				highlights_heading.set_text ({STRING_32} "Your highlights (" + highlights_panel.rows.count.out + {STRING_32} "), in Bible order:")
			end
		end

	chapter_highlight_reasons (a_book, a_chapter: INTEGER): HASH_TABLE [STRING_32, INTEGER]
			-- The reasons each highlighted verse of the chapter carries, joined, by verse number.
		local
			l_hub: BIB_HUB_ID
			l_verse: INTEGER
		do
			create Result.make (8)
			create l_hub
			if user_store.is_open and then l_hub.is_place (a_book, a_chapter, 1) then
				across user_store.highlights_between (l_hub.hub_id (a_book, a_chapter, 1), l_hub.hub_id (a_book, a_chapter, l_hub.Max_part)) as ic loop
					l_verse := l_hub.verse_of (ic.hub_id)
					if attached Result.item (l_verse) as al_reasons then
						al_reasons.append ({STRING_32} "; " + ic.reason)
					else
						Result.put (ic.reason.twin, l_verse)
					end
				end
			end
		end

	add_highlight
			-- The verse read is highlighted for the reason in the box.
		local
			l_reason: STRING_32
		do
			l_reason := highlight_reason_box.text.twin
			l_reason.left_adjust
			l_reason.right_adjust
			if l_reason.is_empty then
				window.toast ("Say why first: a highlight is a reason.", 1)
			elseif user_store.is_open and reading.has_verse then
				user_store.add_highlight (create {BIB_HIGHLIGHT}.make (reading_hub, l_reason))
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					highlight_reason_box.set_text ("")
					reopen_reading
				end
			end
		end

	say (a_text: READABLE_STRING_GENERAL)
			-- A short message at the window's edge.
		do
			window.toast (a_text, 1)
		end

	go_to_hub (a_hub: INTEGER_64)
			-- Read the verse `a_hub' names (nothing when it names none).
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			if l_hub.is_valid_hub (a_hub) then
				go_to (l_hub.book_of (a_hub), l_hub.chapter_of (a_hub), l_hub.verse_of (a_hub))
			end
		end

	reopen_reading
			-- A highlight changed: the chapter's washes and the Highlights list.
		do
			reading.redraw
			fill_highlights
		end

	hub_place (a_hub: INTEGER_64): STRING_32
			-- The verse `a_hub' names, "Jude 1:6" (its number when it names none): the one way every
			-- list turns a verse identity into words.
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			if l_hub.is_valid_hub (a_hub) then
				Result := place_text (l_hub.book_of (a_hub), l_hub.chapter_of (a_hub), l_hub.verse_of (a_hub))
			else
				Result := a_hub.out
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
			elseif a_index = Timeline_tab then
				fill_timeline
				show_atlas
			end
			if a_index /= Timeline_tab then
				layout_state.set_river_workspace (False)
			end
		end

	Timeline_tab: INTEGER = 4

	timeline_view: SW_LANE_TIMELINE
			-- The River of Time (Plan 22 phase 1, 2026-10-30): the lens on, filled when first shown.
		attribute
			create Result.make
			Result.set_lens (True)
		end

	timeline_filled: BOOLEAN
			-- Has `timeline_view' been filled from the timeline packs?

	timeline_pane: SW_COLUMN
			-- T8 and the river: the years in view as two boxes and a Set button over the Timeline
			-- (Larry, 2026-10-31: "a pair of text boxes with a Set button that allows the user to
			-- dictate what years from-and-to are in view").
		local
			l_bar: SW_ROW
		do
			create l_bar.make
			l_bar := l_bar.with_gap (6.0)
			l_bar.put (create {SW_LABEL}.make_ui ("From"))
			l_bar.put (years_from_box.with_min_size (130.0, 0.0))
			l_bar.put (create {SW_LABEL}.make_ui ("to"))
			l_bar.put (years_to_box.with_min_size (130.0, 0.0))
			l_bar.put (years_set_button)
			l_bar.put (create {SW_SPACER}.make_weighted (1.0))
			create Result.make
			Result := Result.fitting.with_gap (6.0)
			Result.put (l_bar)
			Result.put (timeline_view.growing)
				-- the boxes follow the years in view, pushed by the river (state by agents)
			timeline_view.view_changed.subscribe (agent show_years_in_view)
		end

	years_from_box: BIB_LOOKUP_BOX
		attribute
			create Result.make_lookup
			Result.set_tooltip ("The first year in view. Type one (1446 BC, AD 70, 200,000 BC) and press Set or Enter.")
			Result.set_on_enter (agent set_years_in_view)
		end

	years_to_box: BIB_LOOKUP_BOX
		attribute
			create Result.make_lookup
			Result.set_tooltip ("The last year in view. Type one (586 BC, AD 135) and press Set or Enter.")
			Result.set_on_enter (agent set_years_in_view)
		end

	years_set_button: SW_BUTTON
		attribute
			create Result.make ("Set", agent set_years_in_view)
			Result.set_tooltip ("Show the years typed in the two boxes. The bar under the river walks time; Home and End reach the first and last years of the data.")
		end

	show_years_in_view (a_from, a_to: REAL_64)
			-- The boxes show the years now in view, unless the reader is typing in one.
		do
			if not years_from_box.is_focused and not years_to_box.is_focused then
				years_from_box.set_text (timeline_view.era.label (a_from.ceiling))
				years_to_box.set_text (timeline_view.era.label ((a_to.floor - 1).max (a_from.ceiling)))
			end
		end

	set_years_in_view
			-- The years typed in the two boxes, in view; a reason said when they cannot be read.
		local
			e: SW_ERA_YEARS
			l_from, l_to: INTEGER
		do
			e := timeline_view.era
			if not e.is_year_text (years_from_box.text) or not e.is_year_text (years_to_box.text) then
				say ("Type two years, like 1446 BC and AD 70.")
			else
				l_from := e.year_of_text (years_from_box.text)
				l_to := e.year_of_text (years_to_box.text)
				if l_from >= l_to then
					say ("The first year must come before the second.")
				else
					fill_timeline
					timeline_view.show_years (l_from, l_to + 1)
					window.give_focus (timeline_view)
					window.request_render
				end
			end
		end

	show_timeline
			-- The Timeline tab (in Study; Simple has no tabs).
		do
			if not is_study then
				layout_state.set_study (True)
			end
			center_tabs.select_tab (Timeline_tab)
			fill_timeline
			show_atlas
		end

	fill_timeline
			-- The River of Time from the attached timeline packs: a lane for each of theirs, an item
			-- for each settled event, and for a disputed one a dispute with one position per claim
			-- (its holder named, the lean marked); each claim's basis drawn as its certainty class.
		local
			l_lane_of: HASH_TABLE [INTEGER, STRING_32]
			l_dispute, l_lane: INTEGER
			it: SW_TIMELINE_ITEM
			l_lo, l_hi: INTEGER
		do
			if not timeline_filled and then bible.is_open then
				timeline_filled := True
				create l_lane_of.make (8)
				across bible.timeline_packs as ic_pack loop
					if ic_pack.is_available then
						across ic_pack.lanes as ic_lane loop
							if not l_lane_of.has (ic_lane.id) then
								l_lane_of.put (timeline_view.add_lane (ic_lane.title, ic_lane.group), ic_lane.id)
							end
						end
						across ic_pack.events as ic_event loop
							l_lane := l_lane_of.item (ic_event.lane)
							if l_lane > 0 then
								if ic_event.is_disputed then
									l_dispute := timeline_view.add_dispute (ic_event.title, river_year (ic_event.earliest), river_year (ic_event.latest))
									across ic_event.claims as ic_claim loop
										it := timeline_view.add_position (l_dispute, l_lane, ic_event.title + {STRING_32} ": " + ic_claim.label,
											river_year (ic_claim.earliest), river_year (ic_claim.latest), claim_class (ic_event, ic_claim))
										item_events.put (ic_event.id, it.id)
										if ic_claim.is_lean then
											it.set_lean ("shown first")
										end
									end
								else
									l_lo := river_year (ic_event.claims.first.earliest)
									l_hi := river_year (ic_event.claims.first.latest)
									it := timeline_view.add_item (l_lane, ic_event.title, l_lo, l_hi, claim_class (ic_event, ic_event.claims.first))
									item_events.put (ic_event.id, it.id)
									it.set_importance (ic_event.importance)
									if not ic_event.claims.first.chronology.is_empty then
										it.set_badge (ic_event.claims.first.chronology)
									end
								end
								event_titles.put (ic_event.title, ic_event.id)
							end
						end
						across ic_pack.event_places as ic_ep loop
							if not places_of_event.has (ic_ep.event_id) then
								places_of_event.put (create {ARRAYED_LIST [STRING_32]}.make (1), ic_ep.event_id)
							end
							if attached places_of_event.item (ic_ep.event_id) as al_list then
								al_list.extend (ic_ep.place_id)
							end
							if not events_at_place.has (ic_ep.place_id) then
								events_at_place.put (create {ARRAYED_LIST [STRING_32]}.make (1), ic_ep.place_id)
							end
							if attached events_at_place.item (ic_ep.place_id) as al_list then
								al_list.extend (ic_ep.event_id)
							end
						end
					end
				end
				timeline_view.set_on_select (agent on_timeline_item)
				timeline_view.set_on_cursor (agent on_timeline_cursor)
					-- the river follows the shared selection from now on, told the present on joining
				selection.on_year (agent timeline_follow_year)
				selection.on_place (agent timeline_follow_place)
				if timeline_view.items.is_empty then
					timeline_view.add_lane ("No timeline pack yet: bible_build --timeline writes one", "River of Time").do_nothing
				else
						-- open on the biblical world, 3500 BC to AD 135; prehistory is one zoom out
					timeline_view.set_view (-3499.0, 140.0)
				end
			end
		end

feature {NONE} -- The Atlas and the shared selection (Plan 22 phase 3, 2026-10-31)

	item_events: HASH_TABLE [STRING_32, INTEGER]
			-- Each timeline item's event id, by the item's id.
		attribute
			create Result.make (256)
		end

	event_titles: HASH_TABLE [STRING_32, STRING_32]
			-- Each event's title, by its id.
		attribute
			create Result.make (256)
		end

	places_of_event: HASH_TABLE [ARRAYED_LIST [STRING_32], STRING_32]
			-- The places each event happened at.
		attribute
			create Result.make (128)
		end

	events_at_place: HASH_TABLE [ARRAYED_LIST [STRING_32], STRING_32]
			-- The events at each place.
		attribute
			create Result.make (128)
		end

	item_of_event (a_event: READABLE_STRING_GENERAL): INTEGER
			-- The id of the first timeline item showing `a_event'; 0 for none.
		do
			across item_events as ic until Result > 0 loop
				if ic.same_string_general (a_event) then
					Result := @ic.key
				end
			end
		end

	selection: BIB_TIME_PLACE_SELECTION
			-- What the Timeline and the Atlas share; each follows it, neither knows the other. Each
			-- view joins when it is filled, and joining tells it the present (research/23).
		attribute
			create Result.make
		end

	atlas_view: SW_ATLAS
			-- The Atlas, filled when first shown; its measurement pushes each change to
			-- `refresh_measure_buttons' (Larry, 2026-10-31: state machines through agents).
		attribute
			create Result.make
			Result.on_measure_change (agent refresh_measure_buttons)
		end

	atlas_pane: SW_COLUMN
			-- T7: the measuring tool's buttons over the Atlas (Larry, 2026-10-31: "something to
			-- start and something to end", and to delete the whole path).
		local
			l_bar: SW_ROW
		do
			create l_bar.make
			l_bar := l_bar.with_gap (6.0)
			l_bar.put (measure_start_button)
			l_bar.put (measure_undo_button)
			l_bar.put (measure_end_button)
			l_bar.put (measure_close_button)
			l_bar.put (measure_delete_button)
			create Result.make
			Result := Result.fitting.with_gap (6.0)
			Result.put (l_bar)
			Result.put (atlas_view.growing)
			refresh_measure_buttons
		end

	refresh_measure_buttons
			-- Each measuring button enabled by the tool's state, told by the Atlas on every change
			-- (0.7.43's conditions were asked by a walk of the widget tree that never reached a
			-- docked panel, so only Start, made enabled, ever worked).
		do
			measure_start_button.set_enabled (not atlas_view.is_measuring)
			measure_undo_button.set_enabled (atlas_view.is_measuring and not atlas_view.measure_points.is_empty)
			measure_end_button.set_enabled (atlas_view.is_measuring and atlas_view.measure_points.count >= 2)
			measure_close_button.set_enabled (atlas_view.can_close)
			measure_delete_button.set_enabled (atlas_view.measure_state /= atlas_view.Measure_idle)
		end

	measure_start_button: SW_BUTTON
		attribute
			create Result.make ("Start measuring", agent start_measuring)
			Result.set_tooltip ("Start measuring: then click the map to place points, one after another. A drag still moves the map.")
		end

	measure_undo_button: SW_BUTTON
		attribute
			create Result.make ("Undo point", agent undo_measure_point)
			Result.set_tooltip ("Take back the last point placed.")
		end

	measure_end_button: SW_BUTTON
		attribute
			create Result.make ("End", agent end_measuring)
			Result.set_tooltip ("End: keep the path and its distance on the map; clicks move the map again. (A double-click on the map does the same.)")
		end

	measure_close_button: SW_BUTTON
		attribute
			create Result.make ("Close shape", agent close_measure_shape)
			Result.set_tooltip ("Close shape: join the last point to the first for the perimeter and the area. (A click on the first point does the same.)")
		end

	measure_delete_button: SW_BUTTON
		attribute
			create Result.make ("Delete", agent delete_measure)
			Result.set_tooltip ("Delete the whole path or shape and its readout.")
		end

	start_measuring
		do
			atlas_view.start_measuring
			window.request_render
		end

	undo_measure_point
		do
			if atlas_view.is_measuring and not atlas_view.measure_points.is_empty then
				atlas_view.undo_point
			end
			window.request_render
		end

	end_measuring
		do
			if atlas_view.is_measuring then
				atlas_view.end_measuring
			end
			window.request_render
		end

	close_measure_shape
		do
			if atlas_view.can_close then
				atlas_view.close_shape
			end
			window.request_render
		end

	delete_measure
		do
			atlas_view.delete_measure
			window.request_render
		end

	atlas_filled: BOOLEAN
			-- Has `atlas_view' been filled from the packs?

	is_river_workspace: BOOLEAN
			-- Is the east zone given to the Atlas beside the Timeline tab? (The layout state.)
		do
			Result := layout_state.is_river_workspace
		end

	river_applied: BOOLEAN
			-- Does the dock show the river workspace now?

	reading_east_fraction, river_east_fraction: REAL_64
			-- The east zone's width the reader last had in each workspace (risk 13: a drag was lost
			-- on every change).

	apply_river_workspace (a_on: BOOLEAN)
			-- The dock showing the river workspace or not, as the layout state says.
		do
			if a_on /= river_applied then
				if a_on then
					enter_river_workspace
				else
					leave_river_workspace
				end
			end
		ensure
			applied: river_applied = a_on
		end

	show_atlas
			-- The Atlas beside the Timeline tab: the river workspace (in Study; Simple has no tabs).
			-- Until the Atlas follows the reader (A10), it lives with the Timeline.
		do
			if not is_study then
				layout_state.set_study (True)
			end
			if center_tabs.selected_index /= Timeline_tab then
				center_tabs.select_tab (Timeline_tab)
			end
			fill_timeline
			layout_state.set_river_workspace (True)
			fill_atlas
			window.request_render
		end

	enter_river_workspace
			-- The east zone given to the Atlas alone (42 percent at first, spike S9; then as wide as
			-- the reader last left it): the lexicon and the commentary step aside.
		require
			study: is_study
		do
			reading_east_fraction := dock.fraction (dock.Zone_east)
			dock.hide_panel (lexicon_panel)
			dock.hide_panel (commentary_panel)
			dock.show_panel (atlas_panel)
			dock.set_fraction (dock.Zone_east, (if river_east_fraction > 0.0 then river_east_fraction else 0.42 end))
			river_applied := True
		ensure
			entered: river_applied
		end

	leave_river_workspace
			-- The lexicon and the commentary back in the east zone as wide as the reader had it, the
			-- Atlas put away.
		do
			river_east_fraction := dock.fraction (dock.Zone_east)
			dock.hide_panel (atlas_panel)
			dock.show_panel (lexicon_panel)
			dock.show_panel (commentary_panel)
			dock.set_fraction (dock.Zone_east, (if reading_east_fraction > 0.0 then reading_east_fraction else 0.34 end))
			river_applied := False
		ensure
			left: not river_applied
		end

	Atlas_zoom_scale: REAL_64 = 6.0
			-- A place's min_zoom counts from the Near East view (1 = that view); the Atlas counts
			-- from the whole world, where the Near East view is zoom 6.

	fill_atlas
			-- The empires from the empires packs and the places from the timeline packs, each place
			-- with every candidate location; the needle at the timeline's cursor, else 1000 BC.
		local
			l_site: INTEGER
		do
			if not atlas_filled and then bible.is_open then
				atlas_filled := True
				across bible.empires_packs as ic_pack loop
					if ic_pack.is_available then
						across ic_pack.areas as ic_area loop
							atlas_view.add_area (ic_area.name, ic_area.ring, ic_area.year_from, ic_area.year_to, hue_of (ic_area.name),
								(if ic_area.wikipedia.is_empty then {STRING_32} "" else {STRING_32} "Wikipedia: " + ic_area.wikipedia end)).do_nothing
						end
					end
				end
				across bible.timeline_packs as ic_pack loop
					if ic_pack.is_available then
						across ic_pack.places as ic_place loop
							l_site := atlas_view.add_site (ic_place.id, ic_place.name, (ic_place.min_zoom * Atlas_zoom_scale).min (atlas_view.Max_zoom),
								atlas_view.Always_from, atlas_view.Always_to, site_line (ic_place.id))
							across ic_place.claims as ic_claim loop
								atlas_view.add_candidate (l_site, ic_claim.lon, ic_claim.lat, ic_claim.radius_m, ic_claim.held_by, ic_claim.is_lean)
							end
						end
					end
				end
				atlas_view.set_on_site_select (agent on_atlas_site)
				atlas_view.set_view (Atlas_zoom_scale, 38.0, 32.0)
					-- a needle first (the river's cursor, else 1000 BC), then the Atlas joins the
					-- selection and is told the year AND the event chosen (risk 15: it learned the
					-- year only, so an event chosen before the Atlas was filled had no marks)
				if not selection.has_year then
					selection.set_year (if timeline_view.has_cursor then timeline_view.cursor_year else -999 end)
				end
				selection.on_year (agent atlas_follow_year)
				selection.on_event (agent atlas_follow_event)
			end
		end

	site_line (a_place: STRING_32): STRING_32
			-- A place's card line: its events, the first three named.
		local
			k: INTEGER
		do
			create Result.make_empty
			if attached events_at_place.item (a_place) as al_events then
				Result.append_integer (al_events.count)
				Result.append (if al_events.count = 1 then {STRING_32} " event: " else {STRING_32} " events: " end)
				across al_events as ic until k = 3 loop
					k := k + 1
					if k > 1 then
						Result.append ({STRING_32} "; ")
					end
					if attached event_titles.item (ic) as al_title then
						Result.append (al_title)
					else
						Result.append (ic)
					end
				end
				if al_events.count > 3 then
					Result.append ({STRING_32} "; ...")
				end
			end
		end

	hue_of (a_name: STRING_32): INTEGER
			-- A polity's hue, the same every time for the same name.
		local
			l_sum: NATURAL_32
		do
			across a_name as c loop
				l_sum := l_sum * 31 + c.natural_32_code
			end
			Result := (l_sum \\ atlas_view.Hue_count.to_natural_32).to_integer_32 + 1
		ensure
			known: Result >= 1 and Result <= atlas_view.Hue_count
		end

	on_timeline_item (a_item: SW_TIMELINE_ITEM)
			-- An event chosen on the river: the selection learns it.
		do
			if attached item_events.item (a_item.id) as al_event then
				selection.select_event (al_event, a_item.year_from)
			end
		end

	on_timeline_cursor (a_year: INTEGER)
		do
			selection.set_year (a_year)
		end

	on_atlas_site (a_site: INTEGER)
			-- A place chosen on the Atlas: the selection learns it.
		do
			selection.select_place (atlas_view.sites.i_th (a_site).key)
		end

	atlas_follow_year (a_year: INTEGER)
			-- The Atlas at the needle's year, named in its title.
		do
			if atlas_filled then
				atlas_view.set_year (a_year)
				atlas_view.with_title ({STRING_32} "The world in " + atlas_view.era.label (a_year)).do_nothing
				window.request_render
			end
		end

	timeline_follow_year (a_year: INTEGER)
			-- The river's cursor at the needle, brought into view.
		local
			l_span: REAL_64
		do
			if timeline_filled and then (not timeline_view.has_cursor or else timeline_view.cursor_year /= a_year) then
				timeline_view.set_cursor (a_year)
				if a_year < timeline_view.view_from or a_year > timeline_view.view_to then
					l_span := timeline_view.view_to - timeline_view.view_from
					timeline_view.set_view (a_year - l_span / 2.0, a_year + l_span / 2.0)
				end
				window.request_render
			end
		end

	atlas_follow_event (a_event: STRING_32)
			-- The event's places marked on the Atlas and brought into view.
		local
			l_marks: ARRAYED_LIST [INTEGER]
		do
			if atlas_filled then
				create l_marks.make (2)
				if attached places_of_event.item (a_event) as al_places then
					across al_places as ic loop
						if atlas_view.site_index (ic) > 0 then
							l_marks.extend (atlas_view.site_index (ic))
						end
					end
				end
				atlas_view.set_marked (l_marks)
				if not l_marks.is_empty then
					atlas_view.fit_marked (40.0)
				end
				window.request_render
			end
		end

	timeline_follow_place (a_place: STRING_32)
			-- The needle at the earliest event at the place.
		local
			l_year: INTEGER
			l_any: BOOLEAN
		do
			if attached events_at_place.item (a_place) as al_events then
				across al_events as ic loop
					if item_of_event (ic) > 0 and then (not l_any or else timeline_view.items.i_th (item_of_event (ic)).year_from < l_year) then
						l_year := timeline_view.items.i_th (item_of_event (ic)).year_from
						l_any := True
					end
				end
				if l_any then
					selection.set_year (l_year)
				end
			end
		end

	river_year (a_year: INTEGER): INTEGER
			-- `a_year' inside what the lens can show (an open end stands at its edge).
		do
			Result := a_year.max ({SW_LANE_TIMELINE}.Lens_deepest.truncated_to_integer + 1).min (timeline_view.lens_anchor.truncated_to_integer - 1)
		end

	claim_class (a_event: BIB_TIMELINE_EVENT; a_claim: BIB_CLAIM): INTEGER
			-- How a claim draws: a period as a soft band, tradition hatched, the text's own reckoning
			-- dashed ("per the text"), a named chronology with its badge, an approximate or coarse date
			-- graded, a dated day as a tick, otherwise a solid bar.
		do
			if a_event.kind.same_string ({STRING_32} "period") then
				Result := {SW_TIMELINE_ITEM}.Class_e
			elseif a_claim.basis.same_string ({STRING_32} "tradition") then
				Result := {SW_TIMELINE_ITEM}.Class_g
			elseif a_claim.basis.same_string ({STRING_32} "text") then
				Result := {SW_TIMELINE_ITEM}.Class_f
			elseif not a_claim.chronology.is_empty then
				Result := {SW_TIMELINE_ITEM}.Class_c
			elseif a_claim.edtf.is_approximate or a_claim.edtf.precision > 0 then
				Result := {SW_TIMELINE_ITEM}.Class_d
			elseif a_claim.edtf.has_day and a_claim.earliest = a_claim.latest then
				Result := {SW_TIMELINE_ITEM}.Class_a
			else
				Result := {SW_TIMELINE_ITEM}.Class_b
			end
		end

	Interlinear_tab: INTEGER = 3
			-- T3's Interlinear page.

	show_interlinear
			-- C10 Interlinear, Ctrl+I: the Interlinear tab (in Study; Simple has no tabs).
		do
			if not is_study then
				layout_state.set_study (True)
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
					interlinear_corpus := l_corpus
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
			-- P03.2: the words of the verse read in the Interlinear, with their headword's uses in the
			-- tagged text the Interlinear was read from (`Unknown_uses' when the count cannot be read).
		local
			i: INTEGER
		do
			create analysis_rows.make (24)
			analysis_uses.wipe_out
			if reading.has_verse then
				from i := 1 until i > interlinear_words.count loop
					if interlinear_words.i_th (i).verse = reading_verse then
						analysis_rows.extend (interlinear_words.i_th (i))
					end
					i := i + 1
				end
			end
			if not analysis_rows.is_empty and then bible.conc_pack.is_available and then bible.conc_pack.has_corpus (interlinear_corpus) then
				across analysis_rows as ic loop
					if ic.has_door and then not analysis_uses.has (ic.lemma_id) then
						if attached bible.conc_pack.place_total (ic.lemma_id, interlinear_corpus) as al_total then
							analysis_uses.put (al_total.value, ic.lemma_id)
						else
							analysis_uses.put (Unknown_uses, ic.lemma_id)
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
				if analysis_uses.item (a_word.lemma_id) = Unknown_uses then
						-- Said, never a blank that reads as "none" (scan 40).
					Result := {STRING_32} "unknown"
				else
					Result := analysis_uses.item (a_word.lemma_id).out
				end
			end
		end

	Unknown_uses: INTEGER_64 = -1
			-- `analysis_uses' for a headword whose count could not be read.

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
						-- go_to reaches fill_interlinear, which fills the verse analysis (scan 40: it was filled twice).
					go_to (reading_book, reading_chapter, l_word.verse)
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
				layout_state.set_study (True)
			end
			center_tabs.select_tab (2)
			fill_parallel
		end

	parallel_versions: ARRAYED_LIST [STRING_8]
			-- Three versions side by side: those an Ask request named (0.7.31), else the one read, the
			-- other English one, and the original (the Hebrew Bible for the Old Testament, the Textus
			-- Receptus for the New).
		local
			l_other, l_original: STRING_8
		do
			create Result.make (3)
			Result.compare_objects
			if attached asked_parallel_versions as al_asked then
					-- scan 63: the versions asked for are the columns, the one read not added before them
				across al_asked as ic loop
					if Result.count < 3 and then not Result.has (ic) and then bible.text_reader.has_version (ic) then
						Result.extend (ic)
					end
				end
			end
			if Result.is_empty then
				Result.extend (reading_version)
				if reading_version.same_string ("KJV") then
					l_other := "BSB"
				else
					l_other := "KJV"
				end
				if reading_book <= {BIB_CANON}.Last_old_testament_book then
					l_original := "WLC"
				else
					l_original := "TR"
				end
				across <<l_other, l_original, "BSB", "YLT">> as ic loop
					if Result.count < 3 and then not Result.has (ic) and then bible.text_reader.has_version (ic) then
						Result.extend (ic)
					end
				end
			end
		ensure
			at_most_three: Result.count <= 3
			each_once: across Result as al_v all Result.occurrences (al_v) = 1 end
		end

	fill_parallel
			-- T3 Parallel: the chapter read, verse by verse, in `parallel_versions'.
		local
			l_codes: ARRAYED_LIST [STRING_8]
			l_chapters: ARRAYED_LIST [HASH_TABLE [STRING_32, INTEGER]]
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_text: HASH_TABLE [STRING_32, INTEGER]
			l_row, i, c: INTEGER
			l_lookup: BIB_LOOKUP
			l_notes: ARRAYED_LIST [STRING_32]
			l_name, l_note: STRING_32
			l_reasons: HASH_TABLE [STRING_32, INTEGER]
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
				l_reasons := chapter_highlight_reasons (reading_book, reading_chapter)
				across reading_verses as ic loop
					l_row := parallel_view.add_row (ic.verse.out)
					from c := 1 until c > 3 loop
						if attached l_chapters.i_th (c).item (ic.verse) as al_cell then
							parallel_view.set_cell (l_row, c, al_cell)
								-- A highlight and the selected verse are marked in every column, as in the
								-- Bible tab (scan 42: highlights showed in the Bible tab only).
							if attached l_reasons.item (ic.verse) as al_reason then
								mark_highlighted_verse (parallel_view, l_row, c, al_cell, al_reason)
							end
						end
						c := c + 1
					end
				end
				across l_notes as ic loop
					parallel_view.add_note (ic).do_nothing
				end
				parallel_marked_row := 0
				mark_parallel_verse
				star_rows (parallel_view)
				mark_verse_quotes (parallel_view)
				if not l_codes.is_empty and then attached bible.text_reader.version (l_codes.last) as al_last
					and then not al_last.numbers_like_english
				then
					parallel_view.add_note ({STRING_32} "Rows follow the first version's verse numbers; " + al_last.name + {STRING_32} " numbers some verses differently.").do_nothing
				end
			end
		end

	add_study_pills
			-- The Study board's codes: the chrome as on the Simple board, C10, and T1 to T6.
		do
			add_chrome_pills
			window.add_reference_mark (tools_strip, "C10", "Study tools strip: Parallel, Interlinear, Timeline and Atlas work; Guide, Word Study, Count and Ledger come later.", window.Corner_top_left)
			window.add_reference_mark (mode_switch, "C7", "Mode switch, on Study: only the docking changes. Ctrl+M.", window.Corner_top_left)
			window.add_reference_mark (navigator_tabs, "T1", "P11 Navigator, west: Books (chapter by chapter; a favorite chapter wears the star), Favorites (folders of your own; Ctrl+D adds the verse read; New folder, Rename, Remove, Restore; right-click to move or sort) and History (this session's verses, or the kept ones; the box sets how many).", window.Corner_top_left)
			window.add_reference_mark (favorites_filter_box, "T1.1", "Favorites tools: the filter box (favorites and folders whose names hold its words), New folder (named at once), Rename, Remove (a folder hides everything in it) and Restore.", window.Corner_top_left)
			window.add_reference_mark (favorites_tree, "T1.2", "Favorites tree: folders first, then favorites (each named with the version it was saved in), in one order for the whole tree; click a favorite to read it; right-click to open it in its version, rename, move, remove, make a folder or sort.", window.Corner_top_left)
			window.add_reference_mark (history_scope, "T1.3", "History: This session (every verse touched since the window opened) or Kept (between sessions); the number box sets how many verses the Kept list shows (10 to 1,000; every visit stays stored).", window.Corner_top_left)
			window.add_reference_mark (history_grid, "T1.4", "History list: newest first, the verse read selected, a favorite starred; click one to read it again.", window.Corner_top_left)
			window.add_reference_mark (notes_heading, "T2", "P06 Notes, west below T1, in tab order: Verse notes on the chapter read (add on the verse read; double-click to edit, each edit keeps the old version; Delete and Restore); Journal, notes on a subject (New; Save keeps the earlier version; Delete and Restore); Tags (tag the verse read; click a tag for its verses, a verse to read it; Remove and Restore); Highlights (a reason, not a color; washed amber in the Bible and Parallel tabs; click one to read it; Remove and Restore); Prayer (a title and the request; Open and Answered, with how it was answered; Remove and Restore); Memory (learn the verse read; recall today's card, Show the verse, grade Again, Hard, Good or Easy; the next date follows SuperMemo 2).", window.Corner_top_left)
			window.add_reference_mark (highlight_detail, "T2.1", "Highlight read in full: the chosen highlight's reason, wrapped (the list cuts long reasons off).", window.Corner_top_left)
			window.add_reference_mark (prayer_answer_detail, "T2.2", "Answer read in full: the chosen answered prayer's answer, wrapped.", window.Corner_top_left)
			window.add_reference_mark (center_tabs, "T3", "Centre tabs: the Bible text, Parallel (P02), Interlinear (P03, Ctrl+I) and the Timeline (the River of Time).", window.Corner_top_left)
			window.add_reference_mark (years_from_box, "T8", "The years in view: From and to boxes and Set (or Enter) over the Timeline; the bar under the river walks time and names the first and last years of the data; Home and End reach them.", window.Corner_top_left)
			window.add_reference_mark (atlas_view, "T7", "The Atlas (Plan 22): empires by year from Cliopatria, places with their doubt (several candidates are dashed rings, each naming who holds it); choosing an event on the Timeline marks its places, choosing a place moves the Timeline; the scale in miles, kilometers and nautical miles; Start measuring, click points, End or Close shape for the area, Delete; an empire's card and a click on it give its area. Window > Atlas.", window.Corner_top_left)
			window.add_reference_mark (analysis_title, "P03.2", "Verse analysis: the verse read, a row per word with its lemma, Strong's number, morphology, gloss, and how often its headword occurs in this testament. Click a row and T4 follows it.", window.Corner_top_left)
			window.add_reference_mark (interlinear_note, "P03", "Interlinear: word by word in the original, right to left for Hebrew. A click makes the word's verse the place read and opens its headword in T4.", window.Corner_top_left)
			window.add_reference_mark (lexicon_heading, "T4", "P05 Lexicon, east: follows the clicked word. Its Frameworks tab (P05.8) explains each FRAMEWORK(TM) for the common reader; a framework named anywhere is a link: rest on it for a summary, click it to open it here.", window.Corner_top_left)
			window.add_reference_mark (commentary_title, "T5", "P04 Commentary, east: Commentaries (Larry's commentary packs, verse by verse, every claim labelled SOURCED or DEDUCED), Cross-refs with OpenBible votes, Incipit (where the New Testament draws on the Old, LXX-keyed, loudest first)." , window.Corner_top_left)
			window.add_reference_mark (results_tabs, "T6", "South results zone: Search Results (word choices, then the verses holding the words; click one to read it); Author Library (Larry's books); Writings (the search box with My writings as its scope); Guides, Census and Ledger come later.", window.Corner_top_left)
			window.add_reference_mark (writings_grid, "T6.5", "Writings: what the search box found in your commentary, frameworks and books (scope My writings; My writings (fuzzy) forgives a misspelled word). Click one to open it.", window.Corner_top_right)
			window.add_reference_mark (memes_grid, "T6.6", "Memes list: all, or those naming the verse or chapter read; search box above; click a heading to sort (title, words, passages, set); your favorite memes stay at the top (the star); hover the picture icon to see the meme.", window.Corner_top_left)
			window.add_reference_mark (meme_view, "T6.7", "The chosen meme: Copy picture and Copy description put either on the clipboard; Edit changes its title, words and passages; the star makes it a favorite; its passages open the Bible text; Add meme keeps a new one.", window.Corner_top_left)
		end

feature {NONE} -- Right-click menus and panes (Larry, 2026-10-28)

	wire_menus
			-- Each control's own right-click items, standing above the widget's Copy items.
		do
			reading_view.set_menu_extension (agent verse_menu (reading_view, ?, ?, ?))
			parallel_view.set_menu_extension (agent verse_menu (parallel_view, ?, ?, ?))
			interlinear_view.set_menu_extension (agent interlinear_menu)
			analysis_grid.set_menu_extension (agent analysis_menu)
			navigator_tree.set_menu_extension (agent navigator_menu)
			commentary_view.set_menu_extension (agent document_menu (commentary_view, commentary_panel, ?, ?, ?))
			entries_list.set_menu_extension (agent pane_menu (lexicon_panel, ?, ?, ?))
			notes_list.set_menu_extension (agent notes_menu)
			cross_refs_grid.set_menu_extension (agent cross_ref_menu)
			incipit_grid.set_menu_extension (agent incipit_menu)
			pair_view.set_menu_extension (agent pair_menu (pair_view, pair_side_places, ?, ?, ?))
			pair_stack.set_menu_extension (agent pair_menu (pair_stack, pair_stack_places, ?, ?, ?))
			results_grid.set_menu_extension (agent choice_menu)
			verses_grid.set_menu_extension (agent verse_hit_menu)
			places_grid.set_menu_extension (agent place_menu)
			renderings_grid.set_menu_extension (agent rendering_menu)
			history_grid.set_menu_extension (agent history_menu)
			journal_grid.set_menu_extension (agent journal_menu)
			tag_names_grid.set_menu_extension (agent tag_name_menu)
			favorites_tree.set_menu_extension (agent favorites_menu)
			highlights_panel.set_menu_items (agent listed_menu_items)
			tagged_panel.set_menu_items (agent listed_menu_items)
			prayer_open_panel.set_menu_items (agent listed_menu_items)
			prayer_answered_panel.set_menu_items (agent listed_menu_items)
			memory_panel.set_menu_items (agent listed_menu_items)
		end

	verse_menu (a_view: SW_PARALLEL_TEXT; a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A verse in the Bible or Parallel tab: copy it with its reference or the chapter; keep it
			-- (favorite, highlight, note, tag, card, prayer); open it in the other tabs; Focus reading.
			-- Each item reads the verse first, as a click would.
		local
			l_row, l_verse: INTEGER
		do
			l_row := a_view.cell_at (a_px, a_py).row
			if l_row >= 1 and l_row <= reading_verses.count then
				l_verse := reading_verses.i_th (l_row).verse
				a_menu.add_item ({STRING_32} "Copy " + place_text (reading_book, reading_chapter, l_verse) + {STRING_32} " with its reference",
					"", True, agent on_verse_do (l_verse, agent copy_verse))
				a_menu.add_item ({STRING_32} "Copy " + place_text (reading_book, reading_chapter, 0), "", True, agent copy_chapter)
				a_menu.add_separator
				a_menu.add_item ("Add to Favorites...", "Ctrl+D", user_store.is_open, agent on_verse_do (l_verse, agent add_to_favorites))
				a_menu.add_item ("Add to Favorites as a quotation...", "", user_store.is_open and a_view.has_selection, agent add_verse_quotation_of (a_view))
				a_menu.add_item ("Pick up the quotation", "", user_store.is_open and a_view.has_selection, agent pick_up_verse_quotation (a_view))
				a_menu.add_item ("Highlight...", "", user_store.is_open, agent on_verse_do (l_verse, agent start_in_notes (Highlights_tab, highlight_reason_box)))
				a_menu.add_item ("Add a note...", "", user_store.is_open, agent on_verse_do (l_verse, agent start_in_notes (Verse_notes_tab, new_note_box)))
				a_menu.add_item ("Tag...", "", user_store.is_open, agent on_verse_do (l_verse, agent start_in_notes (Tags_tab, tag_box)))
				a_menu.add_item ("Learn it by heart", "", user_store.is_open, agent on_verse_do (l_verse, agent add_memory_card))
				a_menu.add_item ("Pray about it...", "", user_store.is_open, agent on_verse_do (l_verse, agent start_prayer))
				a_menu.add_separator
				a_menu.add_item ("Open in Parallel", "", True, agent on_verse_do (l_verse, agent show_parallel))
				a_menu.add_item ("Open in Interlinear", "Ctrl+I", True, agent on_verse_do (l_verse, agent show_interlinear))
				a_menu.add_separator
			end
			a_menu.add_item (focus_label, "Ctrl+Shift+F", True, agent toggle_focus_reading)
		end

	on_verse_do (a_verse: INTEGER; a_action: PROCEDURE)
			-- Read verse `a_verse' of the chapter (unless it is the verse read), then `a_action'.
		do
			if a_verse /= reading_verse and reading_book > 0 and reading_chapter > 0 and a_verse >= 0 then
				go_to (reading_book, reading_chapter, a_verse)
			end
			a_action.call
		end

	copy_chapter
			-- The chapter read onto the clipboard: its reference and version, then each verse numbered.
		local
			l_text: STRING_32
		do
			if reading_book > 0 and reading_chapter > 0 then
				l_text := place_text (reading_book, reading_chapter, 0) + {STRING_32} " (" + reading_version.to_string_32 + {STRING_32} ")"
				across reading_verses as ic loop
					l_text.append ({STRING_32} "%N" + ic.verse.out.to_string_32 + {STRING_32} " " + ic.display_text)
				end
				copy_to_clipboard (l_text)
				say ("Chapter copied.")
			end
		end

	copy_to_clipboard (a_text: READABLE_STRING_GENERAL)
			-- `a_text' onto the system clipboard.
		do
			(create {SW_CLIPBOARD}).set_text (a_text)
		end

	start_in_notes (a_tab: INTEGER; a_box: SW_TEXT_BOX)
			-- Open the Notes pane at tab `a_tab' with the typing in `a_box': where a highlight's reason,
			-- a note, a tag or a prayer is written (Study; the pane folds open if it was folded).
		do
			bring_into_view (notes_panel, notes_tabs, a_tab)
			window.give_focus (a_box)
		end

	bring_into_view (a_panel: INTEGER; a_tabs: detachable SW_TABS; a_tab: INTEGER)
			-- Pane `a_panel' shown at tab `a_tab' of `a_tabs' (Void: none): the Study layout, another
			-- pane's maximizing put back, a folded zone opened (scan 59: three copies had drifted).
		do
			if not is_study then
				layout_state.set_study (True)
			end
			if dock.maximized_panel /= 0 and dock.maximized_panel /= a_panel then
				dock.restore_maximized
			end
			dock.show_panel (a_panel)
			dock.expand_zone (dock.panels.i_th (a_panel).zone)
			if attached a_tabs as al_tabs then
				al_tabs.select_tab (a_tab)
			end
			window.request_render
		end

	start_prayer
			-- A prayer resting on the verse read: titled by it, the request to be written.
		do
			if reading.has_verse then
				prayer_hub := reading_hub
				prayer_hub_title := place_text (reading_book, reading_chapter, reading_verse)
				prayer_title_box.set_text (prayer_hub_title)
				prayer_tabs.select_tab (1)
				start_in_notes (Prayer_tab, prayer_body_box)
			end
		end

	prayer_hub: INTEGER_64
			-- The verse a prayer begun from a verse's menu rests on (0: none).

	prayer_hub_title: STRING_32
			-- The title it was begun with; a prayer retitled rests on no verse.
		attribute
			create Result.make_empty
		end

	interlinear_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A word in the Interlinear: its headword's items; Focus reading.
		local
			l_token: INTEGER
		do
			l_token := interlinear_view.context_token
			if l_token >= 1 and l_token <= interlinear_words.count then
				word_items (a_menu, interlinear_words.i_th (l_token))
				if not a_menu.items.is_empty then
					a_menu.add_separator
				end
			end
			a_menu.add_item (focus_label, "Ctrl+Shift+F", True, agent toggle_focus_reading)
		end

	analysis_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A row of the verse analysis: its headword's items.
		do
			if attached analysis_grid.context_object as al_word then
				word_items (a_menu, al_word)
			end
		end

	word_items (a_menu: SW_MENU; a_word: BIB_INTERLINEAR_WORD)
			-- An original word: open its headword in T4, its every place, search for its Strong's
			-- number, copy that number.
		do
			if a_word.has_door then
				a_menu.add_item ({STRING_32} "Open " + a_word.surface + {STRING_32} " in the lexicon", "", True, agent open_study (a_word.lemma_id))
				a_menu.add_item ({STRING_32} "Every place of " + a_word.lemma_text, "", True, agent show_word_places (a_word.lemma_id))
			end
			if not a_word.strongs.is_empty then
				a_menu.add_item ({STRING_32} "Search the Bible for " + a_word.strongs, "", True, agent search_for (a_word.strongs))
				a_menu.add_item ({STRING_32} "Copy " + a_word.strongs, "", True, agent copy_to_clipboard (a_word.strongs))
			end
		end

	show_word_places (a_lemma_id: INTEGER_64)
			-- Headword `a_lemma_id' in T4, at its Every place tab.
		do
			open_study (a_lemma_id)
			show_every_place
		end

	search_for (a_text: READABLE_STRING_GENERAL)
			-- Search the Bible for `a_text', as typed in the search box.
		do
			search_box.set_text (a_text)
			on_search
		end

	navigator_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A book or chapter in the Navigator: read it.
		do
			if attached navigator_tree.context_node as al_node then
				if al_node.is_chapter and al_node.book_id > 0 and al_node.chapter > 0 then
					a_menu.add_item ({STRING_32} "Read " + place_text (al_node.book_id, al_node.chapter, 0), "", True, agent go_to (al_node.book_id, al_node.chapter, 0))
				elseif al_node.is_book and al_node.book_id > 0 then
					a_menu.add_item ({STRING_32} "Read " + place_text (al_node.book_id, 1, 0), "", True, agent go_to (al_node.book_id, 1, 0))
				end
			end
		end

	pane_menu (a_panel: INTEGER; a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- Read pane `a_panel' in a larger view, or put it back.
		do
			if dock.maximized_panel = a_panel then
				a_menu.add_item ("Back to its place", "", True, agent dock.restore_maximized)
			elseif dock.is_panel_visible (a_panel) and then dock.is_maximizable (a_panel) then
				a_menu.add_item ("Read in a larger view", "", True, agent dock.maximize_panel (a_panel))
			end
		end

	notes_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A verse note: go to its verse, edit, delete; a new note on the verse read; a larger view.
		local
			l_index: INTEGER
		do
			l_index := notes_list.context_item
			if l_index >= 1 and l_index <= note_rows.count then
				a_menu.add_item ({STRING_32} "Go to " + hub_place (note_rows.i_th (l_index).hub_id), "", True, agent go_to_hub (note_rows.i_th (l_index).hub_id))
				a_menu.add_item ("Edit", "", note_store.is_writable, agent edit_note (l_index))
				a_menu.add_item ("Delete", "", note_store.is_writable, agent delete_note_at (l_index))
				a_menu.add_separator
			end
			if reading.has_verse then
				a_menu.add_item ({STRING_32} "A new note on " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} "...",
					"", user_store.is_open, agent start_in_notes (Verse_notes_tab, new_note_box))
			end
			pane_menu (notes_panel, a_menu, a_px, a_py)
		end

	verse_items (a_menu: SW_MENU; a_hub: INTEGER_64)
			-- Verse `a_hub' (nothing when it names none): go to it, copy it with its text in the version
			-- read, copy its reference.
		local
			l_place: STRING_32
		do
			if (create {BIB_HUB_ID}).is_valid_hub (a_hub) then
				l_place := hub_place (a_hub)
				a_menu.add_item ({STRING_32} "Go to " + l_place, "", True, agent go_to_hub (a_hub))
				a_menu.add_item ({STRING_32} "Copy " + l_place + {STRING_32} " with its text", "", True, agent copy_hub_verse (a_hub))
				a_menu.add_item ("Copy the reference", "", True, agent copy_to_clipboard (l_place))
			end
		end

	copy_hub_verse (a_hub: INTEGER_64)
			-- Verse `a_hub' in the version read, with its reference, onto the clipboard.
		do
			if attached verse_text_at_hub (a_hub) as al_text then
				copy_to_clipboard (al_text + {STRING_32} " (" + hub_place (a_hub) + {STRING_32} " " + reading_version.to_string_32 + {STRING_32} ")")
				say ("Verse copied.")
			else
				say (hub_place (a_hub) + {STRING_32} " is not in " + reading_version.to_string_32 + {STRING_32} ".")
			end
		end

	verse_text_at_hub (a_hub: INTEGER_64): detachable STRING_32
			-- Verse `a_hub''s text in the version read; Void when that version lacks it.
		local
			l_hub: BIB_HUB_ID
			l_keys: BIB_VERSE_KEY
			l_found: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_places: ARRAYED_LIST [INTEGER_64]
		do
			create l_hub
			if l_hub.is_valid_hub (a_hub) and not reading_version.is_empty and then bible.text_reader.has_version (reading_version) then
				create l_keys
				create l_places.make (1)
				l_places.extend (l_keys.packed_place (l_hub.book_of (a_hub), l_hub.chapter_of (a_hub), l_hub.verse_of (a_hub)))
				l_found := bible.text_reader.verses_at_places (reading_version, l_places)
				if l_found.is_success and then l_found.count = 1 then
					Result := l_found.item (1).display_text
				end
			end
		end

	cross_ref_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A cross-reference: its verse's items.
		do
			if attached cross_refs_grid.context_object as al_ref then
				verse_items (a_menu, (create {BIB_HUB_ID}).hub_of_place (al_ref.to_book, al_ref.to_chapter, al_ref.verse_start))
			end
			pane_menu (commentary_panel, a_menu, a_px, a_py)
		end

	choice_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A dictionary word in the results: open it, its every place; a larger view.
		do
			if attached results_grid.context_object as al_choice and then al_choice.opens_a_word then
				a_menu.add_item ({STRING_32} "Open " + al_choice.label + {STRING_32} " in the lexicon", "", True, agent open_study (al_choice.lemma_id))
				a_menu.add_item ({STRING_32} "Every place of " + al_choice.label, "", True, agent show_word_places (al_choice.lemma_id))
			end
			pane_menu (results_panel, a_menu, a_px, a_py)
		end

	verse_hit_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A verse the search found: its items; a larger view.
		do
			if attached verses_grid.context_object as al_hit then
				verse_items (a_menu, (create {BIB_HUB_ID}).hub_of_place (al_hit.book_id, al_hit.chapter, al_hit.verse))
			end
			pane_menu (results_panel, a_menu, a_px, a_py)
		end

	place_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A place of the word: its verse's items.
		do
			if attached places_grid.context_object as al_place and then al_place.is_readable then
				verse_items (a_menu, (create {BIB_HUB_ID}).hub_of_place (al_place.book_id, al_place.chapter, al_place.verse))
			end
			pane_menu (lexicon_panel, a_menu, a_px, a_py)
		end

	rendering_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- An English rendering: search the Bible for it.
		do
			if attached renderings_grid.context_object as al_row then
				a_menu.add_item ({STRING_32} "Search the Bible for %"" + al_row.english + {STRING_32} "%"", "", True, agent search_for ({STRING_32} "%"" + al_row.english + {STRING_32} "%""))
			end
			pane_menu (lexicon_panel, a_menu, a_px, a_py)
		end

	history_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A chapter read before: its verse's items.
		do
			if attached history_grid.context_object as al_visit then
				verse_items (a_menu, al_visit.hub_id)
			end
		end

	journal_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A journal entry: open it, delete it; a new entry.
		local
			l_model: INTEGER
		do
			l_model := journal_grid.context_model
			if l_model >= 1 and l_model <= journal_rows.count then
				a_menu.add_item ("Open the entry", "", True, agent open_journal_row (l_model))
				a_menu.add_item ("Delete the entry", "", note_store.is_writable, agent delete_journal_row (l_model))
				a_menu.add_separator
			end
			a_menu.add_item ("A new entry", "", True, agent new_journal_entry)
			pane_menu (notes_panel, a_menu, a_px, a_py)
		end

	open_journal_row (a_model: INTEGER)
			-- Entry `a_model' into the boxes, as a click on it.
		require
			row_listed: a_model >= 1 and a_model <= journal_rows.count
		do
			journal_grid.select_model_row (a_model)
			on_journal_row (a_model)
		ensure
			opened: journal_entry_id = journal_rows.i_th (a_model).id
		end

	delete_journal_row (a_model: INTEGER)
			-- Soft-delete entry `a_model' (Restore brings it back); scan 56: the row itself, never the
			-- entry open before.
		require
			row_listed: a_model >= 1 and a_model <= journal_rows.count
		do
			open_journal_row (a_model)
			delete_journal_entry
		end

	tag_name_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A tag: list its verses; tag the verse read with it.
		local
			l_model: INTEGER
			l_tag: STRING_32
		do
			l_model := tag_names_grid.context_model
			if l_model >= 1 and l_model <= tag_name_rows.count then
				l_tag := tag_name_rows.i_th (l_model).tag.twin
				a_menu.add_item ("Show its verses", "", True, agent show_tag_row (l_model))
				if reading.has_verse then
					a_menu.add_item ({STRING_32} "Tag " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} " with it",
						"", user_store.is_open, agent tag_read_verse_with (l_tag))
				end
			end
		end

	show_tag_row (a_model: INTEGER)
			-- Tag `a_model''s verses listed, as a click on it.
		do
			if a_model >= 1 and a_model <= tag_name_rows.count then
				tag_names_grid.select_model_row (a_model)
				on_tag_name (a_model)
			end
		end

	tag_read_verse_with (a_tag: READABLE_STRING_GENERAL)
			-- The verse read gets tag `a_tag'.
		do
			tag_box.set_text (a_tag)
			tag_verse
		end

	listed_menu_items (a_menu: SW_MENU; a_item: BIB_LISTED)
			-- A bookmark, highlight, tagged verse, prayer or card: its verse's items; an open prayer
			-- can be marked answered.
		do
			verse_items (a_menu, a_item.hub_id)
			if attached {BIB_PRAYER} a_item as al_prayer and then not al_prayer.is_answered then
				a_menu.add_item ("Mark answered...", "", user_store.is_open, agent start_answer (al_prayer.id))
			end
		end

	start_answer (a_id: INTEGER_64)
			-- Open prayer `a_id' chosen, and the typing in the box for how it was answered.
		local
			i: INTEGER
		do
			from i := 1 until i > prayer_open_rows.count loop
				if prayer_open_rows.i_th (i).id = a_id then
					prayer_open_grid.select_model_row (i)
				end
				i := i + 1
			end
			prayer_tabs.select_tab (1)
			start_in_notes (Prayer_tab, prayer_answer_box)
			say ("Write how it was answered, then press Answered.")
		end

	Verse_notes_tab: INTEGER = 1
			-- P06's Verse notes page.

	focus_label: STRING_32
			-- What the Focus reading item says now.
		do
			if dock.is_focused_on_center then
				Result := "Leave focus reading"
			else
				Result := "Focus reading"
			end
		end

	show_focus_label
			-- The Focus button says what a press will do (risk 18: it said "Focus" always).
		do
			if dock.is_focused_on_center then
				focus_button.set_label ("Sides back")
			else
				focus_button.set_label ("Focus")
			end
		end

	toggle_focus_reading
			-- Fold every side so the Bible text has the window, or bring the sides back (Larry,
			-- 2026-10-28). A folded side still names its panes, with a dot where one has something for
			-- the verse read (`refresh_strip_marks').
		do
			dock.restore_maximized
			if dock.is_focused_on_center then
				dock.set_all_collapsed (False)
			else
				dock.set_all_collapsed (True)
				say ("Focus reading. Ctrl+Shift+F brings the panes back.")
			end
			show_focus_label
			keep_verse_in_view
			window.request_render
		end

	has_commentary: BOOLEAN
			-- Did the last `show_commentary' find a section on the verse read?

	refresh_strip_marks
			-- The dots on folded sides: Commentary when a pack covers the verse read, Notes when the
			-- chapter has notes, the Lexicon when a word is open, Search results when there are some.
		do
			dock.set_panel_marked (commentary_panel, has_commentary)
			dock.set_panel_marked (notes_panel, not note_rows.is_empty)
			dock.set_panel_marked (lexicon_panel, study_lemma > 0)
			dock.set_panel_marked (results_panel, results_state.is_wanted)
		end

	snapshot_verse_quotation
			-- For a snapshot: words of the verse read kept as a quotation (its verse starred, the words
			-- washed), Favorites open.
		local
			u: INTEGER
		do
			window.request_render
			u := view_unit (reading_view, verse_row, 1)
			if u > 0 then
				reading_view.select_range (u, 0, u, reading_view.text_of (u).count.min (31))
				if attached verse_quotation_of (reading_view) as al_quote then
					keep_favorite (al_quote, "", 0)
				end
				reading_view.clear_selection
				navigator_tabs.select_tab (Favorites_tab)
			end
		end

	snapshot_quotation (a_menu: BOOLEAN)
			-- For a snapshot: the first framework with a quotation kept from its third text (marked) and
			-- Favorites open; with `a_menu', a selection in its second text right-clicked instead.
		local
			u: INTEGER
		do
			if not framework_rows.is_empty then
				show_framework (framework_rows.first.id)
				window.request_render
				if framework_view.unit_count >= 3 then
					if a_menu then
						u := 2
						framework_view.select_range (u, 0, u, framework_view.text_of (u).count.min (40))
						window.simulate_context_click ((framework_view.unit_origin_x (u) + 30.0).truncated_to_integer, (framework_view.unit_origin_y (u) + 6.0).truncated_to_integer)
					else
						framework_view.select_range (3, 0, 3, framework_view.text_of (3).count.min (60))
						if attached quotation_of (framework_view) as al_quote then
							keep_favorite (al_quote, "", 0)
						end
						framework_view.clear_selection
						navigator_tabs.select_tab (Favorites_tab)
					end
				end
			end
		end

	snapshot_right_click_verse
			-- For a snapshot: a right-click on the verse read, so the picture shows its menu.
		local
			u, l_row: INTEGER
		do
			window.request_render
			from l_row := 1 until l_row > reading_verses.count or else reading_verses.i_th (l_row).verse = reading_verse loop
				l_row := l_row + 1
			end
			from u := 1 until u > reading_view.unit_count or else (reading_view.unit_block (u) = l_row and reading_view.unit_column (u) = 1) loop
				u := u + 1
			end
			if u <= reading_view.unit_count then
				window.simulate_context_click ((reading_view.unit_origin_x (u) + 60.0).truncated_to_integer, (reading_view.unit_origin_y (u) + 6.0).truncated_to_integer)
			end
		end

feature {NONE} -- Commentary held, and its references previewed (Larry, 2026-10-28)

	is_commentary_held: BOOLEAN
			-- Is T5 kept on `held_book' `held_chapter':`held_verse' while T3 shows a passage a
			-- commentary link opened? (The invariant `hold_is_a_place'.)

	held_book, held_chapter, held_verse: INTEGER
			-- The verse the commentary is kept on.

	is_following_commentary: BOOLEAN
			-- Is a commentary link being followed (`go_to' keeps the hold)?

	shown_book, shown_chapter, shown_verse: INTEGER
			-- The place T5 was last drawn for.

	commentary_book: INTEGER
			-- The book T5 is on: the held verse's, else the one read.
		do
			if is_commentary_held then
				Result := held_book
			else
				Result := reading_book
			end
		end

	commentary_chapter: INTEGER
		do
			if is_commentary_held then
				Result := held_chapter
			else
				Result := reading_chapter
			end
		end

	commentary_verse: INTEGER
		do
			if is_commentary_held then
				Result := held_verse
			else
				Result := reading_verse
			end
		end

	held_note: STRING_32
			-- After T5's heading while it is held: what T3 shows meanwhile.
		do
			if is_commentary_held then
				Result := {STRING_32} "   (kept while you read " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} ")"
			else
				create Result.make_empty
			end
		end

	release_commentary
			-- T5 follows the Bible text again.
		do
			if is_commentary_held then
				is_commentary_held := False
				show_origin_button
			end
		ensure
			released: not is_commentary_held
		end

	back_to_commentary_verse
			-- T3 back to the verse T5 is kept on, selected; T5 follows again.
		local
			l_book, l_chapter, l_verse: INTEGER
		do
			if is_commentary_held then
				l_book := held_book
				l_chapter := held_chapter
				l_verse := held_verse
				release_commentary
				go_to (l_book, l_chapter, l_verse)
			end
		ensure
			released: not is_commentary_held
		end

	show_origin_button
			-- "Back to Galatians 2:20" at the end of S1's header while T5 is held; gone otherwise.
		do
			if is_commentary_held then
				origin_button.set_label ({STRING_32} "Back to " + place_text (held_book, held_chapter, held_verse))
				if not reading_bar.children.has (origin_button) then
					reading_bar.put (origin_button)
				end
			elseif reading_bar.children.has (origin_button) then
				reading_bar.remove (origin_button)
			end
			window.request_render
		ensure
			shown_while_held: reading_bar.children.has (origin_button) = is_commentary_held
		end

	link_card (a_view: SW_DOCUMENT_VIEW; a_item, a_character: INTEGER): detachable SW_HOVER_CARD
			-- A link in `a_view' rested on: a Bible reference's passage in the version read, a
			-- framework's title and plain summary, or a book's title (2026-10-28; read once,
			-- BIB_LINK_TARGET: scan 59).
		local
			l_target: BIB_LINK_TARGET
		do
			if a_view.is_valid_item (a_item) and then attached a_view.link_target_at (a_item, a_character) as al_text then
				create l_target.make (al_text, bible.books)
				if l_target.is_framework then
					Result := framework_card (l_target.id)
				elseif l_target.is_book then
					Result := book_card (l_target.book_kind, l_target.id, l_target.chapter)
				elseif l_target.is_bible then
					Result := passage_card (l_target.book, l_target.chapter, l_target.verse, l_target.end_chapter, l_target.end_verse)
				end
			end
		end

	range_label (a_book, a_chapter, a_verse, a_end_chapter, a_end_verse: INTEGER): STRING_32
			-- "Galatians 2:15-21", "Exodus 5:1-6:2", "Matthew 5-7" (verse 0: whole chapters), or one
			-- place: the one way a passage is named (scan 58: two copies had drifted).
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
		do
			Result := place_text (a_book, a_chapter, a_verse)
			if a_end_chapter /= a_chapter then
				Result.append ({STRING_32} "-" + a_end_chapter.out.to_string_32)
				if a_end_verse > 0 then
					Result.append ({STRING_32} ":" + a_end_verse.out.to_string_32)
				end
			elseif a_end_verse /= a_verse then
				Result.append ({STRING_32} "-" + a_end_verse.out.to_string_32)
			end
		end

	Card_verses: INTEGER = 8
			-- The most verses a reference card shows before "...".

	passage_card (a_book, a_chapter, a_verse, a_end_chapter, a_end_verse: INTEGER): SW_HOVER_CARD
			-- The passage `a_book' `a_chapter':`a_verse' to `a_end_chapter':`a_end_verse' (verse 0: from
			-- or to a chapter's end) in the version read, each verse numbered, at most `Card_verses'.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
		local
			l_text: STRING_32
			l_verses: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_chapter, i, l_count, l_verse: INTEGER
			l_more: BOOLEAN
		do
			create l_text.make (600)
			if bible.text_reader.has_version (reading_version) then
				from l_chapter := a_chapter until l_chapter > a_end_chapter or l_more loop
					l_verses := bible.text_reader.chapter (reading_version, a_book, l_chapter)
					from i := 1 until i > l_verses.count or l_more loop
						l_verse := l_verses.item (i).verse
						if (l_chapter > a_chapter or a_verse = 0 or l_verse >= a_verse)
							and (l_chapter < a_end_chapter or a_end_verse = 0 or l_verse <= a_end_verse)
						then
							if l_count = Card_verses then
								l_more := True
							else
								if not l_text.is_empty then
									l_text.append_character (' ')
								end
								if a_end_chapter > a_chapter then
									l_text.append (l_chapter.out.to_string_32 + {STRING_32} ":")
								end
								l_text.append (l_verse.out.to_string_32 + {STRING_32} " " + l_verses.item (i).display_text)
								l_count := l_count + 1
							end
						end
						i := i + 1
					end
					l_chapter := l_chapter + 1
				end
			end
			if l_more then
				l_text.append ({STRING_32} " ...")
			end
			if l_text.is_empty then
				l_text := {STRING_32} "Not in this version."
			end
			Result := card (range_label (a_book, a_chapter, a_verse, a_end_chapter, a_end_verse) + {STRING_32} " (" + reading_version.to_string_32 + {STRING_32} ")",
				l_text, "")
		end

	Card_width: REAL_64 = 460.0
			-- A hover card's width.

	card (a_heading, a_body, a_hint: READABLE_STRING_GENERAL): SW_HOVER_CARD
			-- A hover card: `a_heading' bold, `a_body' below, and `a_hint' muted under it when there is
			-- one (scan 59: the passage, framework and book cards were three copies).
		local
			l_column: SW_COLUMN
			l_title, l_body, l_hint: SW_LABEL
		do
			create l_title.make (a_heading, {SW_PAINTER}.Role_ui, 13.0, True)
			l_title := l_title.with_wrap
			create l_body.make_body (a_body)
			l_body := l_body.with_wrap
			create l_column.make
			l_column := l_column.with_gap (6.0)
			l_column.put (l_title)
			l_column.put (l_body)
			if not a_hint.is_empty then
				create l_hint.make_ui (a_hint)
				l_column.put (l_hint.as_muted)
			end
			create Result.make (l_column, Card_width)
		end

	snapshot_reference_card
			-- For a snapshot: the card of the first passage linked in the commentary (the first range
			-- when there is one), as a rest on it would open it.
		do
			snapshot_link_card ({STRING_32} "bible:")
		end

	snapshot_link_card (a_prefix: READABLE_STRING_GENERAL)
			-- For a snapshot: the commentary scrolled to its first link whose target starts with
			-- `a_prefix' (for a passage, the first range when there is one), and that link's card up,
			-- as a rest on it would open it.
		local
			u, c, l_unit, l_char, l_range_unit, l_range_char: INTEGER
			g: SW_TEXT_GEOMETRY
		do
			window.request_render
			from u := 1 until u > commentary_view.unit_count or l_range_unit > 0 loop
				g := commentary_view.unit_geometry (u)
				from c := 1 until c > g.count or l_range_unit > 0 loop
					if attached commentary_view.link_target_at (u, c) as al_target and then al_target.starts_with (a_prefix.to_string_32) then
						if l_unit = 0 then
							l_unit := u
							l_char := c
						end
						if al_target.has ('-') then
							l_range_unit := u
							l_range_char := c
						end
					end
					c := c + 1
				end
				u := u + 1
			end
			if l_range_unit > 0 then
				l_unit := l_range_unit
				l_char := l_range_char
			end
			if l_unit > 0 then
				commentary_view.scroll_to (commentary_view.stacked_scroll_for (commentary_view.unit_block (l_unit)))
				window.request_render
				g := commentary_view.unit_geometry (l_unit)
				if attached commentary_view.hover_card_at (commentary_view.unit_origin_x (l_unit) + g.x_of (l_char) + 2.0,
					commentary_view.unit_origin_y (l_unit) + g.top_of_line (g.line_of (l_char)) + 3.0) as al_card
				then
					window.show_hover_card (al_card)
				end
			end
		end

feature {NONE} -- Larry's books (T6 Author Library, T5 In the books; Larry, 2026-10-28)

	books_grid: SW_DATA_GRID [BIB_AUTHOR_BOOK]
	book_rows: ARRAYED_LIST [BIB_AUTHOR_BOOK]
	chapters_grid: SW_DATA_GRID [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]
	chapter_rows: ARRAYED_LIST [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]
	book_view: SW_DOCUMENT_VIEW
			-- T6's Author Library: the books, the chosen book's chapters, the chapter read.

	listed_book: STRING_32
			-- The book (or essay series) whose chapters are listed; empty for none.

	listed_kind: STRING_32
			-- Its pack's kind: "books" or "essays"; empty for none.

	in_books_grid: SW_DATA_GRID [BIB_BOOK_BLOCK]
	in_books_rows: ARRAYED_LIST [BIB_BOOK_BLOCK]
			-- T5's In the books: the paragraphs citing the commentary's verse.

	study_guides_grid: SW_DATA_GRID [BIB_BOOK_BLOCK]
	study_guides_rows: ARRAYED_LIST [BIB_BOOK_BLOCK]
			-- T5's Study guides: the scholar guides' paragraphs citing the verse, apart (2026-10-30).

	guide_labels: HASH_TABLE [STRING_32, STRING_32]
			-- Each guide's label by its id, as `guide_label' made it.

	guide_label (a_block: BIB_BOOK_BLOCK): STRING_32
			-- "Heiser, The Unseen Realm: Chapter 11": the guide's work and section.
		do
			if attached guide_labels.item (a_block.book) as al_label then
				Result := al_label
			else
				Result := a_block.book_title
				across guide_packs as ic loop
					if attached ic.book (a_block.book) as al_result and then al_result.is_success and then al_result.count = 1 and then not al_result.item (1).edition.is_empty then
						Result := al_result.item (1).edition + (if al_result.item (1).subtitle.is_empty then {STRING_32} "" else {STRING_32} ": " + al_result.item (1).subtitle end)
					end
				end
				guide_labels.put (Result, a_block.book)
			end
		end

	on_study_guides_row (a_model: INTEGER)
			-- A guide's paragraph citing the verse chosen: read it where it stands, on the guides' shelf.
		do
			if a_model >= 1 and then a_model <= study_guides_rows.count then
				show_book_place (study_guides_rows.i_th (a_model).pack_kind, study_guides_rows.i_th (a_model).book, study_guides_rows.i_th (a_model).chapter, study_guides_rows.i_th (a_model).block)
			end
		end

	In_books_tab: INTEGER = 3
			-- T5's In the books page.

	Study_guides_tab: INTEGER = 4
			-- T5's Study guides page (2026-10-30).

	Incipit_tab: INTEGER = 5
			-- S2's Incipit page: the Old Testament in the New (research 26, 2026-11-11).

	Author_library_tab: INTEGER = 4
			-- T6's Author Library page.

	Book_mentions_shown: INTEGER = 12
			-- The most book paragraphs a framework's page lists.

	books_page: SW_SPLITTER
			-- The books over their chapters, beside the chapter read (under `library_bar').
		local
			l_lists: SW_SPLITTER
			l_reader: SW_COLUMN
		do
			create l_lists.make (books_grid, chapters_grid)
			l_lists.set_horizontal (True)
			l_lists.set_ratio (0.4)
			create l_reader.make
			l_reader := l_reader.with_gap (4.0)
			l_reader.put (library_bar)
			l_reader.put (book_view.growing)
			create Result.make (l_lists, l_reader)
			Result.set_ratio (0.28)
			fill_books
		end

	library_packs: ARRAYED_LIST [BIB_BOOK_PACK]
			-- The attached packs of Larry's writings, books then essays then notes (2026-10-28): the Author
			-- Library's; never the scholar guides, kept apart (2026-10-30).
		do
			create Result.make (2)
			if bible.is_open then
				across bible.text_packs as ic loop
					if ic.is_available and not ic.schema.Is_kept_apart then
						Result.extend (ic)
					end
				end
			end
		end

	guide_packs: ARRAYED_LIST [BIB_BOOK_PACK]
			-- The attached scholar guides packs: the Scholar Guides tab's (2026-10-30).
		do
			create Result.make (1)
			if bible.is_open then
				across bible.text_packs as ic loop
					if ic.is_available and ic.schema.Is_kept_apart then
						Result.extend (ic)
					end
				end
			end
		end

	shelf_packs: ARRAYED_LIST [BIB_BOOK_PACK]
			-- The packs the shared reader lists: the guides on the Scholar Guides shelf, else the library.
		do
			Result := if is_guides_shelf then guide_packs else library_packs end
		end

	is_guides_shelf: BOOLEAN
			-- Is the reader shelved in the Scholar Guides tab, listing the guides (`show_shelf')?

	library_page: detachable SW_SPLITTER
			-- The reader both the Author Library and the Scholar Guides tab show, one at a time; set once
			-- the results tabs are built.

	library_holder, guides_holder: SW_COLUMN
			-- The two tabs' places for `library_page'.

	Scholar_guides_tab: INTEGER = 6
			-- T6's Scholar Guides page.

	on_results_tab (a_index: INTEGER)
			-- A results tab chosen: the reader moved to the Author Library or the Scholar Guides with it.
		do
			if a_index = Scholar_guides_tab then
				show_shelf (True)
			elseif a_index = Author_library_tab then
				show_shelf (False)
			end
		end

	show_shelf (a_guides: BOOLEAN)
			-- The reader shelved with the scholar guides (`a_guides') or the library: moved to that tab and
			-- its list filled with that shelf's packs.
		do
			if a_guides /= is_guides_shelf then
				if attached library_page as al_page then
					if a_guides then
						detach (library_holder, al_page)
						guides_holder.put (al_page)
					else
						detach (guides_holder, al_page)
						library_holder.put (al_page)
					end
				end
				is_guides_shelf := a_guides
				create listed_book.make_empty
				create listed_kind.make_empty
				create chapter_rows.make (0)
				chapters_grid.set_rows (chapter_rows)
				fill_books
			end
		ensure
			shelved: is_guides_shelf = a_guides
		end

	library_pack (a_kind: READABLE_STRING_GENERAL): detachable BIB_BOOK_PACK
			-- The attached pack of kind `a_kind' ("books", "essays", "guides"); Void when none is.
		do
			across library_packs as ic loop
				if Result = Void and then ic.schema.Pack_kind.same_string_general (a_kind) then
					Result := ic
				end
			end
			across guide_packs as ic loop
				if Result = Void and then ic.schema.Pack_kind.same_string_general (a_kind) then
					Result := ic
				end
			end
		ensure
			of_kind: attached Result as r implies r.schema.Pack_kind.same_string_general (a_kind)
		end

	fill_books
			-- The shelf's packs (the books, then the essay series, then the notes; or the scholar guides),
			-- or the page saying there is none yet.
		do
			create book_rows.make (0)
			across shelf_packs as ic loop
				if attached ic.books as al_result and then al_result.is_success then
					across 1 |..| al_result.count as al_i loop
						book_rows.extend (al_result.item (al_i))
					end
				end
			end
			if book_rows.is_empty and is_guides_shelf then
				book_view.set_document (commentary_reader.read ({STRING_32} "**No scholar guides yet**%N%NImport a folder of prepared guides (File > Import prepared folder): each file whose header says %"kind: guide%" comes here, kept apart from your writings."))
			elseif book_rows.is_empty then
				book_view.set_document (commentary_reader.read ({STRING_32} "**No books or essays pack yet**%N%NA books or essays pack in the packs folder brings Larry's writing here, chapter by chapter."))
			elseif is_guides_shelf then
				book_view.set_document (commentary_reader.read ({STRING_32} "Choose a guide, then a chapter. These are study guides to other scholars' books: private research, kept apart from your writings."))
			else
				book_view.set_document (commentary_reader.read ({STRING_32} "Choose a book or an essay series, then a chapter or an essay. A Bible reference in the text shows its passage; a framework's name, its summary."))
			end
			books_grid.set_rows (book_rows)
		end

	library_kind_name (a_book: BIB_AUTHOR_BOOK): STRING_32
			-- "Book" or "Essays": its pack's kind as the library names it.
		do
			if attached (create {BIB_TEXT_PACKS}).schema_of_kind (a_book.pack_kind) as al_schema then
				Result := al_schema.Kind_noun
			else
				Result := a_book.pack_kind
			end
		end

	on_book_row (a_model: INTEGER)
			-- A book chosen: its chapters listed and its first one read.
		do
			if not is_reselecting and then a_model >= 1 and then a_model <= book_rows.count then
				show_book_place (book_rows.i_th (a_model).pack_kind, book_rows.i_th (a_model).id, 1, 0)
			end
		end

	on_chapter_row (a_model: INTEGER)
			-- A chapter chosen: read it.
		do
			if not is_reselecting and then a_model >= 1 and then a_model <= chapter_rows.count and then not listed_book.is_empty then
				show_book_place (listed_kind, listed_book, chapter_rows.i_th (a_model).chapter, 0)
			end
		end

	on_in_books_row (a_model: INTEGER)
			-- A paragraph citing the verse chosen: read it where it stands.
		do
			if a_model >= 1 and then a_model <= in_books_rows.count then
				show_book_place (in_books_rows.i_th (a_model).pack_kind, in_books_rows.i_th (a_model).book, in_books_rows.i_th (a_model).chapter, in_books_rows.i_th (a_model).block)
			end
		end

	chapter_row_title (a_row: TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]): STRING_32
			-- A chapter's title as listed.
		do
			Result := a_row.title
		end

	chapter_row_published (a_row: TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]): STRING_32
			-- The day a chapter (an essay) was published, "2026-06-14"; else its status when it is not
			-- published ("draft"); else nothing (a book's chapters, an essay posted on a day not known).
		do
			if not a_row.published_on.is_empty then
				Result := a_row.published_on
			elseif not a_row.status.same_string ("published") then
				Result := a_row.status
			else
				create Result.make_empty
			end
		end

	block_snippet (a_block: BIB_BOOK_BLOCK): STRING_32
			-- A paragraph's first words, for a list; "Suggested (why): ..." when the verse was only
			-- suggested for it.
		do
			if a_block.suggestion_reason.is_empty then
				Result := a_block.snippet (140)
			else
				Result := {STRING_32} "Suggested (" + a_block.suggestion_reason + {STRING_32} "): " + a_block.snippet (120)
			end
		end

	show_book_place (a_kind, a_book: READABLE_STRING_GENERAL; a_chapter, a_block: INTEGER)
			-- Book (or essay series) `a_book' of the `a_kind' pack in T6's Author Library: its chapters
			-- listed, chapter `a_chapter' (0: the first) read and, with `a_block' > 0, scrolled to that
			-- paragraph; the pane brought into view.
		require
			not_negative: a_chapter >= 0 and a_block >= 0
		local
			l_chapter, i: INTEGER
		do
				-- a scholar guide opens on the Scholar Guides shelf, anything else in the Author Library
			show_shelf (attached (create {BIB_TEXT_PACKS}).schema_of_kind (a_kind) as al_schema and then al_schema.Is_kept_apart)
			bring_into_view (results_panel, results_tabs, if is_guides_shelf then Scholar_guides_tab else Author_library_tab end)
			l_chapter := a_chapter.max (1)
			if attached library_pack (a_kind) as al_pack and then attached al_pack.book (a_book) as al_result and then al_result.is_success and then al_result.count = 1 then
				if not listed_book.same_string_general (a_book) or not listed_kind.same_string_general (a_kind) then
					listed_book := a_book.to_string_32
					listed_kind := a_kind.to_string_32
					create chapter_rows.make (al_result.item (1).chapters.count)
					chapter_rows.append (al_result.item (1).chapters)
					chapters_grid.set_rows (chapter_rows)
				end
				from i := 1 until i > book_rows.count loop
					if book_rows.i_th (i).id.same_string_general (a_book) and book_rows.i_th (i).pack_kind.same_string_general (a_kind) then
						reselect (books_grid, i)
					end
					i := i + 1
				end
				from i := 1 until i > chapter_rows.count loop
					if chapter_rows.i_th (i).chapter = l_chapter then
						reselect (chapters_grid, i)
					end
					i := i + 1
				end
				book_view.set_document (commentary_reader.read (chapter_page (al_pack, al_result.item (1), l_chapter)))
				shown_book_document := book_view.document
				shown_book_kind := a_kind.to_string_32
				shown_book_id := a_book.to_string_32
				shown_book_chapter := l_chapter
				if a_block > 0 then
						-- one document block per book block, after the book's title
					window.request_render
					book_view.scroll_to (book_view.stacked_scroll_for ((a_block + 1).min (book_view.document.count)))
				end
			else
				book_view.set_document (commentary_reader.read ({STRING_32} "No " + a_book.to_string_32 + {STRING_32} " in the " + a_kind.to_string_32 + {STRING_32} " pack."))
			end
			window.request_render
			mark_view (book_view)
		end

	chapter_page (a_pack: BIB_BOOK_PACK; a_book: BIB_AUTHOR_BOOK; a_chapter: INTEGER): STRING_32
			-- Chapter `a_chapter' of `a_book' as a page: the book's title, then every block in order,
			-- each its own paragraph (so block n is the page's block n + 1) and a heading at its own
			-- level (the chapter's first heading is its title), references and framework names linked.
			-- In an essay, a heading straight under the title is its subtitle, set in italics, not a
			-- section (0.7.31; COMMENTARY's builder notes).
		local
			l_linker: BIB_REFERENCE_LINKER
			l_suggestions: ARRAYED_LIST [TUPLE [block: INTEGER; passage, reason: STRING_32]]
		do
			l_linker := page_linker
			create Result.make (20000)
			Result.append ({STRING_32} "*" + a_book.full_title + {STRING_32} "*%N%N")
			l_suggestions := a_pack.chapter_suggestions (a_book.id, a_chapter)
			if attached a_pack.chapter_blocks (a_book.id, a_chapter) as al_blocks and then al_blocks.is_success then
				across 1 |..| al_blocks.count as al_i loop
					if a_pack.schema.Starts_at_title and then is_subtitle (al_blocks, al_i) then
						Result.append ({STRING_32} "*" + l_linker.linked (al_blocks.item (al_i).markdown) + {STRING_32} "*%N%N")
					elseif al_blocks.item (al_i).kind.same_string_general ("heading") then
						Result.append (create {STRING_32}.make_filled ('#', al_blocks.item (al_i).level.max (1).min (6)))
						Result.append ({STRING_32} " " + l_linker.linked (al_blocks.item (al_i).markdown) + {STRING_32} "%N%N")
					elseif al_blocks.item (al_i).kind.same_string_general ("code") then
						Result.append (al_blocks.item (al_i).markdown + {STRING_32} "%N%N")
					else
						Result.append (l_linker.linked (al_blocks.item (al_i).markdown))
							-- 0.7.32: a passage the text only alludes to, after its paragraph, never as a citation
						across l_suggestions as ic loop
							if ic.block = al_blocks.item (al_i).block then
								Result.append ({STRING_32} " *(Suggested: " + l_linker.linked (ic.passage) + (if ic.reason.is_empty then {STRING_32} "" else {STRING_32} " - " + ic.reason end) + {STRING_32} ")*")
							end
						end
						Result.append ({STRING_32} "%N%N")
					end
				end
			end
		end

	is_subtitle (a_blocks: BIB_LIST_RESULT [BIB_BOOK_BLOCK]; a_index: INTEGER): BOOLEAN
			-- Is block `a_index' a heading below level 1 standing straight under a level-1 title?
		require
			in_range: a_index >= 1 and a_index <= a_blocks.count
		do
			Result := a_index = 2 and then a_blocks.item (1).kind.same_string_general ("heading") and then a_blocks.item (1).level = 1
				and then a_blocks.item (2).kind.same_string_general ("heading") and then a_blocks.item (2).level >= 2
		end

	fill_in_books
			-- T5's Books & essays: the paragraphs of the books, then of the essays, citing the
			-- commentary's verse, the narrowest passage first within each.
		do
			create in_books_rows.make (0)
			if commentary_verse > 0 and then (create {BIB_HUB_ID}).is_place (commentary_book, commentary_chapter, commentary_verse) then
				across library_packs as ic loop
					if attached ic.blocks_citing (commentary_book, commentary_chapter, commentary_verse) as al_result and then al_result.is_success then
						across 1 |..| al_result.count as al_i loop
							in_books_rows.extend (al_result.item (al_i))
						end
					end
				end
					-- then the paragraphs the verse was only suggested for, marked so (0.7.32)
				across library_packs as ic loop
					if attached ic.blocks_suggesting (commentary_book, commentary_chapter, commentary_verse) as al_result and then al_result.is_success then
						across 1 |..| al_result.count as al_i loop
							in_books_rows.extend (al_result.item (al_i))
						end
					end
				end
			end
			in_books_grid.set_rows (in_books_rows)
				-- the scholar guides apart: their own list (2026-10-30)
			create study_guides_rows.make (0)
			if commentary_verse > 0 and then (create {BIB_HUB_ID}).is_place (commentary_book, commentary_chapter, commentary_verse) then
				across guide_packs as ic loop
					if attached ic.blocks_citing (commentary_book, commentary_chapter, commentary_verse) as al_result and then al_result.is_success then
						across 1 |..| al_result.count as al_i loop
							study_guides_rows.extend (al_result.item (al_i))
						end
					end
				end
				across guide_packs as ic loop
					if attached ic.blocks_suggesting (commentary_book, commentary_chapter, commentary_verse) as al_result and then al_result.is_success then
						across 1 |..| al_result.count as al_i loop
							study_guides_rows.extend (al_result.item (al_i))
						end
					end
				end
			end
			study_guides_grid.set_rows (study_guides_rows)
		end

	book_card (a_kind, a_book: READABLE_STRING_GENERAL; a_chapter: INTEGER): detachable SW_HOVER_CARD
			-- A book or essay link rested on: the book's (series') title, chapter `a_chapter''s (0:
			-- none), its description; Void when the `a_kind' pack has no such book.
		local
			l_heading: STRING_32
		do
			if attached library_pack (a_kind) as al_pack and then attached al_pack.book (a_book) as al_result and then al_result.is_success and then al_result.count = 1 then
				l_heading := al_result.item (1).full_title
				if a_chapter > 0 and then not al_result.item (1).chapter_title (a_chapter).is_empty then
					l_heading.append ({STRING_32} ": " + al_result.item (1).chapter_title (a_chapter))
				end
				Result := card (l_heading, al_result.item (1).description, "Click to read it in the Author Library.")
			end
		end

feature {NONE} -- The ingest kit (0.7.32, research/21)

	make_ingest_kit
			-- File > Make ingest kit: choose a source (TXT or MD); its kit is written beside it.
		local
			l_dialog: SW_FILE_DIALOG
		do
			create l_dialog.make_open (documents_folder)
			l_dialog.set_extension_filter ((create {BIB_SOURCE_READER}).dialog_filter)
			l_dialog.set_on_accept (agent (a_path: STRING_32) do window.close_sheet; write_ingest_kit (a_path) end)
			l_dialog.set_on_cancel (agent window.close_sheet)
			window.show_sheet (l_dialog, 680.0)
		end

	write_ingest_kit (a_source: STRING_32)
			-- The kit for the source file `a_source', written beside it as <name>.kit.md.
		local
			l_reader: BIB_SOURCE_READER
			l_kit_path: STRING_32
			l_ok: BOOLEAN
		do
			create l_reader
			if not bible.is_open then
				say ("No Bible content is open, so a kit cannot list what Simple Bible holds.")
			elseif not attached l_reader.text_of (a_source) as al_text then
				say (if attached l_reader.last_error as al_why then al_why else {STRING_32} "The file could not be read." end)
			else
					-- one reader and one naming rule for one kit and a folder's (2026-10-30)
				l_kit_path := (create {BIB_KIT_FOLDER}.make (bible)).kit_path_for (a_source)
				l_ok := (create {SIMPLE_FILE}.make (l_kit_path)).write_text_utf_8 ((create {BIB_INGEST_KIT}.make (bible)).kit_text ((create {SIMPLE_FILE}.make (a_source)).file_name, al_text))
				if l_ok then
					copy_to_clipboard (l_kit_path)
					say ({STRING_32} "Ingest kit written: " + l_kit_path + {STRING_32} " (its path is on the clipboard). Give it to an AI chat; import what it returns with File > Import prepared notes.")
				else
					say ({STRING_32} "The kit could not be written at " + l_kit_path)
				end
			end
		end

	make_ingest_kits_for_folder
			-- File > Make ingest kits for a folder (2026-10-30, Larry): pick any source; every source in
			-- its folder without an up-to-date kit gets one (BIB_KIT_FOLDER). "Making" is painted first.
		local
			l_dialog: SW_FILE_DIALOG
		do
			create l_dialog.make_open (documents_folder)
			l_dialog.set_extension_filter ((create {BIB_SOURCE_READER}).dialog_filter)
			l_dialog.set_on_accept (agent (a_path: STRING_32)
				do
					window.close_sheet
					pending_kit_folder := (create {SIMPLE_FILE}.make (a_path)).parent_path
					pending_kit_folder_ticks := 2
					say ({STRING_32} "Making ingest kits for every file in its folder...")
					window.request_render
				end)
			l_dialog.set_on_cancel (agent window.close_sheet)
			window.show_sheet (l_dialog, 680.0)
		end

	make_kits (a_folder: STRING_32)
			-- A kit beside every source in `a_folder' that needs one; what happened shown in the Author
			-- Library, the folder's path on the clipboard.
		local
			l_kits: BIB_KIT_FOLDER
			l_page, l_summary: STRING_32
		do
			if not bible.is_open then
				say ("No Bible content is open, so a kit cannot list what Simple Bible holds.")
			else
				create l_kits.make (bible)
				l_kits.run (a_folder)
				l_summary := (l_kits.written.count + l_kits.remade.count).out.to_string_32 + {STRING_32} " kits made, "
					+ l_kits.skipped.count.out.to_string_32 + {STRING_32} " up to date already, " + l_kits.failed.count.out.to_string_32 + {STRING_32} " failed"
				create l_page.make (4000)
				l_page.append ({STRING_32} "# Ingest kits%N%N`" + a_folder + {STRING_32} "`%N%N" + l_summary + {STRING_32} ".%N%N")
				if l_kits.sources (a_folder).is_empty then
					l_page.append ({STRING_32} "No file in this folder is a source a kit is made from (" + l_kits.reader.dialog_filter + {STRING_32} ").%N%N")
				end
				if not l_kits.written.is_empty or not l_kits.remade.is_empty then
					l_page.append ({STRING_32} "## Made (" + (l_kits.written.count + l_kits.remade.count).out.to_string_32 + {STRING_32} ")%N%N")
					across l_kits.written as ic loop
						l_page.append ({STRING_32} "- " + ic + {STRING_32} "%N")
					end
					across l_kits.remade as ic loop
						l_page.append ({STRING_32} "- " + ic + {STRING_32} " (again: its source had changed)%N")
					end
					l_page.append ({STRING_32} "%NGive each kit to an AI chat; save what it returns as <name>.prepared.md, then File > Import prepared folder.%N%N")
				end
				if not l_kits.failed.is_empty then
					l_page.append ({STRING_32} "## Failed (" + l_kits.failed.count.out.to_string_32 + {STRING_32} ")%N%N")
					across l_kits.failed as ic loop
						l_page.append ({STRING_32} "- " + ic.file + {STRING_32} ": " + ic.why + {STRING_32} "%N")
					end
					l_page.append ({STRING_32} "%N")
				end
				if not l_kits.skipped.is_empty then
					l_page.append ({STRING_32} "## Up to date already (" + l_kits.skipped.count.out.to_string_32 + {STRING_32} ")%N%N")
					across l_kits.skipped as ic loop
						l_page.append ({STRING_32} "- " + ic + {STRING_32} "%N")
					end
				end
				copy_to_clipboard (a_folder)
				bring_into_view (results_panel, results_tabs, Author_library_tab)
				book_view.set_document (commentary_reader.read (l_page))
				keep_snapshot_report (l_page)
				say ({STRING_32} "Ingest kits: " + l_summary + {STRING_32} ". The folder's path is on the clipboard.")
			end
		end

	import_prepared_notes
			-- File > Import prepared notes: choose the file an AI returned; checked, then kept as a note.
		local
			l_dialog: SW_FILE_DIALOG
		do
			create l_dialog.make_open (documents_folder)
			l_dialog.set_extension_filter ("*.md;*.txt")
			l_dialog.set_on_accept (agent (a_path: STRING_32) do window.close_sheet; import_note (a_path) end)
			l_dialog.set_on_cancel (agent window.close_sheet)
			window.show_sheet (l_dialog, 680.0)
		end

	import_note (a_path: STRING_32)
			-- The prepared file `a_path' checked (its source beside it, when there, for the length check)
			-- and kept through the folder import's one path (BIB_NOTE_BATCH.run_files, 2026-10-30): a note
			-- or a scholar guide, each in its own place; refused with its report, or kept and shown.
		local
			l_batch: BIB_NOTE_BATCH
			l_file: SIMPLE_FILE
			l_errors: ARRAYED_LIST [STRING_32]
		do
			create l_file.make (a_path)
			if bible.is_open and then l_file.is_file then
				create l_batch.make (bible)
				l_batch.run_files (l_file.parent_path, create {ARRAYED_LIST [STRING_32]}.make_from_array (<<l_file.file_name>>), ingest_places)
				if not l_batch.refused.is_empty then
					show_import_report ({STRING_32} "Import refused", l_batch.refused.first.problems, l_batch.warnings)
				elseif attached l_batch.last_error as al_error then
					show_import_report ({STRING_32} "The file could not be kept", create {ARRAYED_LIST [STRING_32]}.make_from_array (<<al_error>>), l_batch.warnings)
				else
					l_errors := packs_put_in_place (l_batch)
					if not l_errors.is_empty then
						show_import_report ({STRING_32} "A new pack could not be put in place", l_errors, l_batch.warnings)
					elseif not l_batch.kept.is_empty then
						show_book_place (l_batch.kept.first.kind, l_batch.kept.first.id, 1, 0)
						say ({STRING_32} "Imported " + l_batch.kept.first.title + {STRING_32} ": " + l_batch.built_blocks.out.to_string_32 + {STRING_32} " paragraphs, "
							+ l_batch.built_suggestions.out.to_string_32 + (if l_batch.built_suggestions = 1 then {STRING_32} " suggested passage." else {STRING_32} " suggested passages." end)
							+ (if l_batch.retired.is_empty then {STRING_32} "" else {STRING_32} " It replaces the note of the same id." end)
							+ (if l_batch.warnings.is_empty then {STRING_32} "" else {STRING_32} " Note: " + l_batch.warnings.first end))
					else
						say ({STRING_32} "Already imported, unchanged: " + l_file.file_name)
					end
				end
			end
		end

	ingest_places: BIB_INGEST_PLACES
			-- Where imports keep notes and scholar guides, the packs built as ".new" files (any left from
			-- before removed) and put in place after (`packs_put_in_place').
		local
			l_location: BIB_DATA_LOCATION
		do
			create l_location
			create Result.make (l_location.notes_folder, new_pack_path ({BIB_NOTE_SCHEMA}.Pack_file_name),
				l_location.guides_folder, new_pack_path ({BIB_GUIDE_SCHEMA}.Pack_file_name),
				l_location.pack_folder.to_string_32 + {STRING_32} "\" + {BIB_FRAMEWORK_SCHEMA}.Pack_file_name)
		end

	live_pack_path (a_file_name: READABLE_STRING_GENERAL): STRING_32
			-- The pack `a_file_name' in the packs folder.
		do
			Result := (create {BIB_DATA_LOCATION}).pack_folder.to_string_32 + {STRING_32} "\" + a_file_name.to_string_32
		end

	new_pack_path (a_file_name: READABLE_STRING_GENERAL): STRING_32
			-- Where a pack `a_file_name' is built before it is put in place; one left from before removed.
		local
			l_ok: BOOLEAN
		do
			Result := live_pack_path (a_file_name) + {STRING_32} ".new"
			if (create {SIMPLE_FILE}.make (Result)).is_file then
				l_ok := (create {SIMPLE_FILE}.make (Result)).delete
			end
		end

	packs_put_in_place (a_batch: BIB_NOTE_BATCH): ARRAYED_LIST [STRING_32]
			-- The packs `a_batch' built put in place, guides first, and the notes pack taken away when its
			-- last note retired; what could not be done, empty when all was.
		do
			create Result.make (0)
			if a_batch.guides_built and then attached pack_put_in_place (live_pack_path ({BIB_GUIDE_SCHEMA}.Pack_file_name), live_pack_path ({BIB_GUIDE_SCHEMA}.Pack_file_name) + {STRING_32} ".new", (create {BIB_DATA_LOCATION}).guides_folder) as al_error then
				Result.extend (al_error)
			end
			if a_batch.notes_built then
				if attached pack_put_in_place (live_pack_path ({BIB_NOTE_SCHEMA}.Pack_file_name), live_pack_path ({BIB_NOTE_SCHEMA}.Pack_file_name) + {STRING_32} ".new", (create {BIB_DATA_LOCATION}).notes_folder) as al_error then
					Result.extend (al_error)
				end
			elseif a_batch.notes_now_empty and then attached pack_removed (live_pack_path ({BIB_NOTE_SCHEMA}.Pack_file_name), (create {BIB_DATA_LOCATION}).notes_folder) as al_error then
				Result.extend (al_error)
			end
		end

	import_prepared_folder
			-- File > Import prepared folder (2026-10-30, Larry): pick any prepared file; every *.prepared.md
			-- in its folder is checked and kept (BIB_NOTE_BATCH), a note in already, unchanged, passed over.
			-- "Importing" is painted first; the work runs on the next window tick.
		local
			l_dialog: SW_FILE_DIALOG
		do
			create l_dialog.make_open (documents_folder)
			l_dialog.set_extension_filter ("*.prepared.md")
			l_dialog.set_on_accept (agent (a_path: STRING_32)
				do
					window.close_sheet
					pending_folder := (create {SIMPLE_FILE}.make (a_path)).parent_path
					pending_folder_ticks := 2
					say ({STRING_32} "Importing every prepared file in its folder: this can take a moment...")
					window.request_render
				end)
			l_dialog.set_on_cancel (agent window.close_sheet)
			window.show_sheet (l_dialog, 680.0)
		end

	import_folder (a_folder: STRING_32)
			-- Every prepared file in `a_folder' checked; notes and scholar guides kept apart, each pack built
			-- once and put in place, the engine reopened on them; what happened shown in a report.
		local
			l_batch: BIB_NOTE_BATCH
		do
			if bible.is_open then
				create l_batch.make (bible)
				l_batch.run (a_folder, ingest_places)
				show_folder_report (a_folder, l_batch, packs_put_in_place (l_batch))
			end
		end

	keep_snapshot_report (a_page: STRING_32)
			-- In a snapshot, the whole report page `a_page' beside the picture as <picture>.md (2026-10-30:
			-- a folder's dry run reports more than one window shows).
		local
			l_ok: BOOLEAN
		do
			if is_snapshot then
				l_ok := (create {SIMPLE_FILE}.make (snapshot_path + {STRING_32} ".md")).write_text_utf_8 (a_page)
			end
		end

	rebuild_stale_packs
			-- The notes pack and the guides pack, each whose folder is marked stale, built again from every
			-- file there and put in place, the mark cleared (2026-10-30: files the installer brought; a pack
			-- an import could not put in place). A folder with no files takes its pack away.
		do
			rebuild_pack (create {BIB_NOTE_SCHEMA}, (create {BIB_DATA_LOCATION}).notes_folder)
			rebuild_pack (create {BIB_GUIDE_SCHEMA}, (create {BIB_DATA_LOCATION}).guides_folder)
		end

	rebuild_pack (a_schema: BIB_TEXT_PACK_SCHEMA; a_folder: READABLE_STRING_GENERAL)
			-- The `a_schema' pack built again from `a_folder' when it is marked stale (`rebuild_stale_packs').
		local
			l_importer: BIB_NOTE_IMPORTER
			l_batch: BIB_NOTE_BATCH
			l_folder: STRING_32
			l_error: detachable STRING_32
		do
			create l_folder.make_from_string_general (a_folder)
			if bible.is_open then
				create l_batch.make (bible)
				if l_batch.is_pack_stale (l_folder) then
					if not (create {SIMPLE_FILE}.make (l_folder)).is_directory or else (create {SIMPLE_FILE}.make (l_folder)).files_with_extension (".json").is_empty then
						l_error := pack_removed (live_pack_path (a_schema.Pack_file_name), l_folder)
					else
						create l_importer.make (bible)
						l_error := l_importer.build_with (a_schema, l_folder, new_pack_path (a_schema.Pack_file_name), live_pack_path ({BIB_FRAMEWORK_SCHEMA}.Pack_file_name))
						if l_error = Void then
							l_error := pack_put_in_place (live_pack_path (a_schema.Pack_file_name), live_pack_path (a_schema.Pack_file_name) + {STRING_32} ".new", l_folder)
						else
							l_batch.set_pack_stale (l_folder, True)
						end
					end
					if attached l_error as al_error then
						say ({STRING_32} "The " + a_schema.Entries_noun + {STRING_32} " could not be brought up to date: " + al_error)
					else
						say ({STRING_32} "The " + a_schema.Entries_noun + {STRING_32} " are up to date.")
					end
				end
			end
		end

	show_folder_report (a_folder: STRING_32; a_batch: BIB_NOTE_BATCH; a_swap_errors: LIST [STRING_32])
			-- What a folder import did, in the Author Library's reader.
		local
			l_page, l_summary: STRING_32
		do
			l_summary := a_batch.kept.count.out.to_string_32 + {STRING_32} " imported, " + a_batch.skipped.count.out.to_string_32
				+ {STRING_32} " already imported, " + a_batch.refused.count.out.to_string_32 + {STRING_32} " refused"
			create l_page.make (4000)
			l_page.append ({STRING_32} "# Folder import%N%N`" + a_folder + {STRING_32} "`%N%N" + l_summary + {STRING_32} " (of "
				+ a_batch.file_count.out.to_string_32 + {STRING_32} " prepared files).%N%N")
			if attached a_batch.last_error as al_error then
				l_page.append ({STRING_32} "**Nothing was imported:** " + al_error + {STRING_32} "%N%N")
			elseif not a_swap_errors.is_empty then
				l_page.append ({STRING_32} "**The files below are saved, but a new pack could not be put in place:**%N%N")
				across a_swap_errors as ic loop
					l_page.append ({STRING_32} "- " + ic + {STRING_32} "%N")
				end
				l_page.append ({STRING_32} "%NOnce that is put right, import the folder again: the pack is built again from every file.%N%N")
			elseif a_batch.is_built and a_batch.kept.is_empty then
				l_page.append ({STRING_32} "A pack was built again from every file: an earlier one had not been put in place.%N%N")
			end
			if a_batch.file_count = 0 then
				l_page.append ({STRING_32} "No file in this folder ends in .prepared.md.%N%N")
			end
			if not a_batch.kept.is_empty then
				l_page.append ({STRING_32} "## Imported (" + a_batch.kept.count.out.to_string_32 + {STRING_32} ")%N%N")
				across a_batch.kept as ic loop
					l_page.append ({STRING_32} "- " + ic.title + {STRING_32} " (" + ic.file
						+ (if ic.kind.same_string ({BIB_GUIDE_SCHEMA}.Pack_kind) then {STRING_32} ", a scholar guide" else {STRING_32} "" end)
						+ (if across a_batch.replaced as al_r some al_r.same_string (ic.file) end then {STRING_32} ", replacing its earlier version" else {STRING_32} "" end)
						+ {STRING_32} ")%N")
				end
				l_page.append ({STRING_32} "%NThe packs built hold " + a_batch.built_blocks.out.to_string_32 + {STRING_32} " paragraphs and "
					+ a_batch.built_suggestions.out.to_string_32 + {STRING_32} " suggested passages.%N%N")
			end
			if not a_batch.retired.is_empty then
				l_page.append ({STRING_32} "## Moved from Notes to Scholar Guides (" + a_batch.retired.count.out.to_string_32 + {STRING_32} ")%N%NThese notes are guides now, kept apart from your writings: ")
				across a_batch.retired as ic loop
					l_page.append (ic + (if ic.is_equal (a_batch.retired.last) then {STRING_32} ".%N%N" else {STRING_32} ", " end))
				end
			end
			if not a_batch.refused.is_empty then
				l_page.append ({STRING_32} "## Refused (" + a_batch.refused.count.out.to_string_32 + {STRING_32} ")%N%N")
				across a_batch.refused as ic loop
					l_page.append ({STRING_32} "- **" + ic.file + {STRING_32} "**%N")
					across ic.problems as al_p loop
						l_page.append ({STRING_32} "    - " + al_p + {STRING_32} "%N")
					end
				end
				l_page.append ({STRING_32} "%NCorrect these files (or ask the AI to), then import the folder again: what is in already is passed over.%N%N")
			end
			if not a_batch.skipped.is_empty then
				l_page.append ({STRING_32} "## Already imported, passed over (" + a_batch.skipped.count.out.to_string_32 + {STRING_32} ")%N%N")
				across a_batch.skipped as ic loop
					l_page.append ({STRING_32} "- " + ic + {STRING_32} "%N")
				end
			end
			bring_into_view (results_panel, results_tabs, Author_library_tab)
			book_view.set_document (commentary_reader.read (l_page))
			say ({STRING_32} "Folder import: " + l_summary + {STRING_32} ".")
			keep_snapshot_report (l_page)
		end

	pack_put_in_place (a_pack, a_new, a_folder: READABLE_STRING_GENERAL): detachable STRING_32
			-- The built pack `a_new' put in `a_pack''s place (`swapped_pack'); the folder `a_folder' its files
			-- live in marked stale when it could not be (scan 70: the next import or start builds it again),
			-- else the mark cleared and the lists the packs feed filled afresh (`packs_changed'). Void when in
			-- place, else why not. (Scan 71: once, for a note, a folder and a rebuild; 2026-10-30: any pack.)
		do
			Result := swapped_pack (a_pack.to_string_32, a_new.to_string_32)
			(create {BIB_NOTE_BATCH}.make (bible)).set_pack_stale (a_folder, Result /= Void)
			if Result = Void then
				packs_changed
			end
		end

	pack_removed (a_pack, a_folder: READABLE_STRING_GENERAL): detachable STRING_32
			-- The pack `a_pack' taken away (its folder `a_folder' holds no files now: the last note became a
			-- guide), the engine closed for it and opened again; put back when the engine will not open
			-- without it. Void when done or there was none, else why not.
		local
			l_pack, l_old: STRING_32
			l_ok: BOOLEAN
		do
			create l_pack.make_from_string_general (a_pack)
			l_old := l_pack + {STRING_32} ".old"
			if (create {SIMPLE_FILE}.make (l_pack)).is_file then
				if (create {SIMPLE_FILE}.make (l_old)).is_file then
					Result := {STRING_32} "A pack kept from an earlier failed import is still at " + l_old + {STRING_32} ": move it somewhere safe, then import again."
				else
					bible.close
					if not (create {SIMPLE_FILE}.make (l_pack)).rename_to ((create {SIMPLE_FILE}.make (l_pack)).file_name + {STRING_32} ".old") then
						Result := {STRING_32} "The emptied pack " + l_pack + {STRING_32} " could not be taken away; it is unchanged."
					end
					bible.open
					if Result = Void and not bible.is_open then
						bible.close
						l_ok := (create {SIMPLE_FILE}.make (l_old)).rename_to ((create {SIMPLE_FILE}.make (l_pack)).file_name)
						bible.open
						Result := {STRING_32} "Simple Bible would not open without " + l_pack + {STRING_32} "; it is back."
					elseif Result = Void then
						l_ok := (create {SIMPLE_FILE}.make (l_old)).delete
					end
				end
			end
			(create {BIB_NOTE_BATCH}.make (bible)).set_pack_stale (a_folder, Result /= Void)
			if Result = Void then
				packs_changed
			end
		end

	packs_changed
			-- The lists the text packs feed filled afresh, after a pack was put in place or taken away.
		do
			framework_names_cache := Void
			writing_names_cache := Void
			create guide_labels.make (16)
			create listed_book.make_empty
			create listed_kind.make_empty
			fill_books
		end

	swapped_pack (a_pack, a_new: STRING_32): detachable STRING_32
			-- The new pack `a_new' put in `a_pack''s place, the engine closed for it and opened again; the
			-- old pack kept as ".old" until the new one is in place, and put back when it cannot be (scan
			-- 66: a failed delete or rename lost the pack and still said "Imported"). Void when done, else
			-- what went wrong. (2026-10-30: any pack, notes or guides.)
		local
			l_old, l_name: STRING_32
			l_had_old, l_ok: BOOLEAN
		do
			l_old := a_pack + {STRING_32} ".old"
			l_name := (create {SIMPLE_FILE}.make (a_pack)).file_name
			if (create {SIMPLE_FILE}.make (l_old)).is_file then
					-- scan 69: never deleted: it may be the only copy of an earlier pack
				Result := {STRING_32} "A pack kept from an earlier failed import is still at " + l_old
					+ {STRING_32} ": move it somewhere safe, then import again."
			else
				bible.close
				l_had_old := (create {SIMPLE_FILE}.make (a_pack)).is_file
				if l_had_old and then not (create {SIMPLE_FILE}.make (a_pack)).rename_to (l_name + {STRING_32} ".old") then
					Result := {STRING_32} "The old pack " + l_name + {STRING_32} " could not be moved aside; it is unchanged."
				elseif not (create {SIMPLE_FILE}.make (a_new)).rename_to (l_name) then
					Result := {STRING_32} "The new pack " + l_name + {STRING_32} " could not be renamed into place"
					if l_had_old then
						if (create {SIMPLE_FILE}.make (l_old)).rename_to (l_name) then
							Result.append ({STRING_32} "; the old one is back.")
						else
							Result.append ({STRING_32} "; the old one is kept as " + l_old + {STRING_32} ".")
						end
					else
						Result.append_character ('.')
					end
				end
				bible.open
				if Result = Void and not bible.is_open then
						-- scan 67: the new pack would not open: the old one goes back and opens again
					Result := {STRING_32} "Simple Bible could not open the new pack " + l_name + {STRING_32} " ("
						+ (if attached bible.last_error as al_e then al_e.message else {STRING_32} "no reason given" end) + {STRING_32} ")"
					l_ok := (create {SIMPLE_FILE}.make (a_pack)).delete
					if l_had_old then
						if (create {SIMPLE_FILE}.make (l_old)).rename_to (l_name) then
							Result.append ({STRING_32} "; the old one is back.")
						else
							Result.append ({STRING_32} "; the old one is kept as " + l_old + {STRING_32} ".")
						end
					else
						Result.append_character ('.')
					end
					bible.open
				elseif Result = Void and l_had_old then
						-- scan 68: the old pack goes only once the new one is in place and open
					l_ok := (create {SIMPLE_FILE}.make (l_old)).delete
				end
				if not bible.is_open then
						-- scan 69: what was said about the old pack stays said
					Result := (if attached Result as al_said then al_said + {STRING_32} " " else {STRING_32} "" end)
						+ {STRING_32} "Simple Bible could not open its data again: " + (if attached bible.last_error as al_e then al_e.message else {STRING_32} "no reason given" end)
				end
			end
		end

	show_import_report (a_heading: STRING_32; a_problems, a_warnings: LIST [STRING_32])
			-- The import's report in the Author Library's reader.
		local
			l_page: STRING_32
		do
			create l_page.make (2000)
			l_page.append ({STRING_32} "# " + a_heading + {STRING_32} "%N%N")
			across a_problems as ic loop
				l_page.append ({STRING_32} "- " + ic + {STRING_32} "%N")
			end
			if not a_warnings.is_empty then
				l_page.append ({STRING_32} "%N## Warnings%N%N")
				across a_warnings as ic loop
					l_page.append ({STRING_32} "- " + ic + {STRING_32} "%N")
				end
			end
			l_page.append ({STRING_32} "%NCorrect the prepared file (or ask the AI to), then import it again.%N")
			bring_into_view (results_panel, results_tabs, Author_library_tab)
			book_view.set_document (commentary_reader.read (l_page))
			say (a_heading)
		end

	documents_folder: STRING_32
			-- Where the file dialogs open: the reader's Documents folder, else the current one.
		do
			if attached (create {SIMPLE_ENV}).item ("USERPROFILE") as al_home then
				Result := al_home.to_string_32 + {STRING_32} "\Documents"
			else
				Result := {STRING_32} "."
			end
		end

feature {NONE} -- Ask (C6.5, 0.7.31: plain words through the Cactus Needle helper)

	ask_box: BIB_LOOKUP_BOX
			-- C6.5: a request in plain words.

	ask_button: SW_BUTTON
			-- Reads the request in `ask_box' (Larry, 2026-10-29).

	go_button, search_button: SW_BUTTON
			-- Beside C4 and C6, a magnifying glass each, doing what Enter does (Larry, 2026-10-29).

	pending_ask: detachable STRING_32
			-- A request waiting for the helper to start, so "Starting Ask" is painted first.

	pending_ask_ticks: INTEGER
			-- Ticks left before `pending_ask' runs.

	pending_folder: detachable STRING_32
			-- A folder of prepared files waiting to be imported, so "Importing" is painted first.

	pending_folder_ticks: INTEGER
			-- Ticks left before `pending_folder' is imported.

	pending_kit_folder: detachable STRING_32
			-- A folder of sources waiting for kits, so "Making" is painted first.

	pending_kit_folder_ticks: INTEGER
			-- Ticks left before `pending_kit_folder''s kits are made.

	pending_notes_rebuild_ticks: INTEGER
			-- Ticks left before stale packs are built again (`rebuild_stale_packs'); 0: none waiting.

	needs_helper_start: BOOLEAN
			-- Will the next request start the helper (about half a second)?
		do
			if attached ask_helper as al_helper then
				Result := not al_helper.is_ready and then al_helper.may_start
			else
				Result := True
			end
		end

	ask_helper: detachable BIB_ASK_HELPER
			-- The helper, started at the first request that needs it.

	asked_parallel_versions: detachable ARRAYED_LIST [STRING_8]
			-- The versions the last Ask request put side by side; Void after another request.

	asked_search_scope: detachable BIB_SEARCH_SCOPE
			-- A scope an Ask search named that the scope list does not offer (one book), while that
			-- one search runs; Void otherwise (scan 64: it outlived the search).

	ask_folder: STRING_32
			-- Where the helper's files are: SIMPLE_BIBLE_ASK when set, else the "ask" folder beside the
			-- program (where the installer puts them).
		do
			if attached (create {SIMPLE_ENV}).get ("SIMPLE_BIBLE_ASK") as al_folder and then not al_folder.is_empty then
				Result := al_folder.to_string_32
			else
				Result := (create {SIMPLE_ENV}).executable_folder.to_string_32 + {STRING_32} "\ask"
			end
		end

	ask_status: STRING_32
			-- "Ask: on (libneedle)", "Ask: off - <why>", or "Ask: starts at the first request".
		do
			if attached ask_helper as al_helper and then al_helper.is_ready then
				Result := {STRING_32} "Ask: on (" + al_helper.engine + {STRING_32} ")"
			elseif attached ask_helper as al_helper then
				Result := {STRING_32} "Ask: off - " + al_helper.off_reason
			elseif attached (create {BIB_ASK_HELPER}.make (ask_folder)).missing_file as al_missing then
				Result := {STRING_32} "Ask: off - its file " + al_missing + {STRING_32} " is missing"
			else
				Result := {STRING_32} "Ask: starts at the first request"
			end
		end

	on_ask
			-- C6.5: the request in `ask_box'. Not Ask's (the internet, the news): said. A reference the
			-- box reads: opened at once (NEEDLE's rule 1). Else the helper proposes tools, BIB_ASK_CHECK
			-- checks them against what was typed, and the window runs them; a refused or failed answer
			-- goes to the search box as typed.
		local
			l_text: STRING_32
			l_check: BIB_ASK_CHECK
		do
			create l_text.make_from_string_general (ask_box.text)
			l_text.left_adjust
			l_text.right_adjust
			asked_parallel_versions := Void
			asked_search_scope := Void
			if bible.is_open and then not l_text.is_empty then
				create l_check.make (bible)
				if l_check.is_outside (l_text) then
					say ("Ask looks things up in Simple Bible only: not the internet, the news or the weather.")
					log_ask (l_text, "", "rule 11: not Ask's")
				elseif attached (create {BIB_LOOKUP}.make (bible)).place_named (l_text) as al_place then
					go_to (al_place.book, al_place.chapter, al_place.verse)
					log_ask (l_text, "", "rule 1: read as a reference")
				elseif needs_helper_start then
					pending_ask := l_text
					pending_ask_ticks := 2
					say ("Starting Ask: the first request takes a moment...")
					window.request_render
				else
					answer_ask (l_text)
				end
			end
		end

	answer_ask (a_text: STRING_32)
			-- The request `a_text' through the helper (started here when it is not running): its calls
			-- checked and run, or the search box when Ask cannot answer it safely.
		local
			l_text: STRING_32
			l_check: BIB_ASK_CHECK
			l_calls: ARRAYED_LIST [BIB_ASK_CALL]
			l_helper: BIB_ASK_HELPER
		do
			l_text := a_text
			if bible.is_open then
				create l_check.make (bible)
				if not l_text.is_empty then
					if attached ask_helper as al_running and then not al_running.is_ready and then al_running.may_start then
						al_running.start
					elseif ask_helper = Void then
						create l_helper.make (ask_folder)
						ask_helper := l_helper
						l_helper.start
					end
					if attached ask_helper as al_helper and then al_helper.is_ready then
						al_helper.ask (l_text)
						if al_helper.is_ready then
							l_calls := l_check.checked (l_text, al_helper.calls)
							if l_calls.is_empty and then not al_helper.last_error.is_empty then
									-- the helper refused the request itself: its reason, not "no tool fits" (scan 65)
								log_ask (l_text, "", {STRING_32} "helper: " + al_helper.last_error)
								ask_fallback (l_text)
							elseif l_calls.is_empty then
								log_ask (l_text, calls_text (al_helper.calls), l_check.refusal)
								ask_fallback (l_text)
							else
								log_ask (l_text, calls_text (l_calls), "run")
								across l_calls as ic loop
									run_ask_call (ic)
								end
							end
						else
							say ({STRING_32} "Ask is off: " + al_helper.off_reason)
							log_ask (l_text, "", al_helper.off_reason)
							ask_fallback (l_text)
						end
					elseif attached ask_helper as al_off then
						say ({STRING_32} "Ask is off: " + al_off.off_reason)
						log_ask (l_text, "", al_off.off_reason)
						ask_fallback (l_text)
					end
				end
			end
		end

	ask_fallback (a_text: READABLE_STRING_GENERAL)
			-- What Ask could not answer safely, searched as typed (the Bible's search, not the writings').
		do
			if is_writings_scope then
				scope_select.select_index (1)
			end
			search_box.set_text (a_text)
			on_search
		end

	run_ask_call (a_call: BIB_ASK_CALL)
			-- One checked call, run with the window's own actions.
		local
			l_place: detachable TUPLE [book, chapter, verse: INTEGER]
			l_versions: ARRAYED_LIST [STRING_8]
			l_scope: STRING_32
			i: INTEGER
		do
			if a_call.has ("reference") then
				l_place := (create {BIB_LOOKUP}.make (bible)).place_named (a_call.text ("reference"))
			end
			if a_call.has ("version") and then bible.text_reader.has_version (a_call.text ("version").to_string_8) then
				use_version (a_call.text ("version").to_string_8)
			end
			if a_call.name.same_string ("open_passage") and attached l_place as al_place then
				go_to (al_place.book, al_place.chapter, al_place.verse)
			elseif a_call.name.same_string ("show_parallel") and attached l_place as al_place then
				create l_versions.make (3)
				across a_call.texts ("versions") as ic loop
					l_versions.extend (ic.to_string_8)
				end
				asked_parallel_versions := l_versions
				go_to (al_place.book, al_place.chapter, al_place.verse)
				if not is_study then
					layout_state.set_study (True)
				end
				center_tabs.select_tab (2)
				fill_parallel
			elseif a_call.name.same_string ("word_study") then
				ask_fallback (a_call.text ("word"))
			elseif a_call.name.same_string ("words_behind") then
				ask_fallback (a_call.text ("english"))
			elseif a_call.name.same_string ("cross_references") and attached l_place as al_place then
				go_to (al_place.book, al_place.chapter, al_place.verse)
				bring_into_view (commentary_panel, commentary_tabs, 2)
			elseif a_call.name.same_string ("interlinear") and attached l_place as al_place then
				go_to (al_place.book, al_place.chapter, al_place.verse)
				show_interlinear
			elseif a_call.name.same_string ("commentary") and attached l_place as al_place then
				go_to (al_place.book, al_place.chapter, al_place.verse)
				bring_into_view (commentary_panel, commentary_tabs, 1)
			elseif a_call.name.same_string ("search_text") then
				scope_select.select_index (1)
				if not a_call.text ("scope").is_empty and then attached (create {BIB_SCOPE_NAMES}).range_named (a_call.text ("scope")) as al_range then
					l_scope := al_range.name
					from i := 1 until i > (create {BIB_SCOPE_NAMES}).names.count loop
						if (create {BIB_SCOPE_NAMES}).names.i_th (i).same_string (l_scope) then
							scope_select.select_index (i + 1)
						end
						i := i + 1
					end
				elseif not a_call.text ("scope").is_empty then
						-- a book (BIB_ASK_CHECK let it pass as a scope): searched there (scan 63)
					asked_search_scope := bible.search_scopes.scope_named (a_call.text ("scope"), reading_version)
				end
				search_box.set_text (a_call.text ("query"))
				on_search
					-- scan 64: the asked book was this search's only; a later search reads the list again
				asked_search_scope := Void
			end
		ensure
			scope_not_kept: asked_search_scope = Void
		end

	use_version (a_code: STRING_8)
			-- Read in version `a_code' (the version box follows).
		local
			i: INTEGER
		do
			from i := 1 until i > bible.text_reader.versions.count loop
				if bible.text_reader.versions.i_th (i).code.same_string (a_code) then
					version_select.select_index (i)
				end
				i := i + 1
			end
			if not reading_version.same_string (a_code) then
				on_version_change
			end
		end

	calls_text (a_calls: LIST [BIB_ASK_CALL]): STRING_32
			-- The calls, for the log.
		do
			create Result.make (80)
			across a_calls as ic loop
				if not Result.is_empty then
					Result.append ({STRING_32} "; ")
				end
				Result.append (ic.description)
			end
		end

	log_ask (a_text, a_calls, a_outcome: READABLE_STRING_GENERAL)
			-- One line in the Ask log (on this machine only): when, the request, the calls, the outcome.
		local
			l_ok: BOOLEAN
			l_line: STRING_32
		do
			l_line := (create {SIMPLE_DATE_TIME}.make_now).to_iso8601.to_string_32 + {STRING_32} "%T" + a_text.to_string_32 + {STRING_32} "%T"
				+ a_calls.to_string_32 + {STRING_32} "%T" + a_outcome.to_string_32
			l_line.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			l_ok := (create {SIMPLE_FILE}.make ((create {BIB_DATA_LOCATION}).ask_log_path)).append_line (l_line)
		end

feature {NONE} -- Searching Larry's writings (T6 Writings; research/20, 2026-10-28)

	Scope_writings_name: STRING_32 = "My writings"
	Scope_writings_fuzzy_name: STRING_32 = "My writings (fuzzy)"
			-- `scope_select''s last two choices: Larry's commentary, frameworks and books, the second
			-- forgiving a misspelled word.

	Writings_scope_index: INTEGER
			-- `scope_select''s index of `Scope_writings_name'; the fuzzy choice follows it.
		do
			Result := (create {BIB_SCOPE_NAMES}).names.count + 3
		end

	is_writings_scope: BOOLEAN
			-- Does the search box search Larry's writings?
		do
			Result := scope_select.selected_index >= Writings_scope_index
		end

	Writings_tab: INTEGER = 5
			-- T6's Writings page.

	writings_grid: SW_DATA_GRID [BIB_WRITING_HIT]
	writing_rows: ARRAYED_LIST [BIB_WRITING_HIT]
	writings_note: SW_LABEL
			-- T6's Writings: what the search found in the writings, and how many.

	writings_page: SW_COLUMN
			-- The note over the hits.
		do
			create Result.make
			Result := Result.with_gap (6.0)
			Result.put (writings_note)
			Result.put (writings_grid.growing)
		end

	search_writings
			-- The search box's query over Larry's writings, the hits in T6's Writings, the pane brought
			-- into view; "(fuzzy)" widens a plain word to the writings' words an edit or two from it.
		local
			l_search: BIB_WRITINGS_SEARCH
			l_note: STRING_32
		do
			create writing_rows.make (0)
			writing_row_opened := 0
			show_back_to_writings
			if bible.is_open and then not search_box.text.is_empty then
				l_search := bible.writings_search
				if l_search.pack_count = 0 then
					writings_note.set_text ("No commentary, frameworks or books pack yet: nothing of yours to search.")
				else
					l_search.search (search_box.text, scope_select.selected_index > Writings_scope_index, "", "")
					if not l_search.error_message.is_empty then
						writings_note.set_text ({STRING_32} "The search does not read: " + l_search.error_message)
					else
						writing_rows.append (l_search.hits)
						l_note := l_search.hits.count.out.to_string_32 + {STRING_32} " found in your writings for " + search_box.text.to_string_32
						if l_search.hits.count = 1 then
							l_note.replace_substring_all ({STRING_32} " found", {STRING_32} " place found")
						end
						across l_search.packs_without_search as ic loop
							l_note.append ({STRING_32} "; " + ic + {STRING_32} " was built before search and is not searched")
						end
						across l_search.packs_failed as ic loop
							l_note.append ({STRING_32} "; the search of " + ic + {STRING_32} " failed")
						end
						across l_search.packs_cut_short as ic loop
							l_note.append ({STRING_32} "; " + ic + {STRING_32} " holds more, only the best are listed")
						end
						writings_note.set_text (l_note + {STRING_32} ".")
					end
				end
			end
			writings_grid.set_rows (writing_rows)
			bring_into_view (results_panel, results_tabs, Writings_tab)
		end

	on_writing_row (a_model: INTEGER)
			-- A hit chosen: open it where it stands (a passage with its commentary, a framework, a
			-- book's or essay's paragraph: then the library offers "Back to results", 0.7.31).
		do
			if not is_reselecting and then a_model >= 1 and then a_model <= writing_rows.count then
				if (create {BIB_LINK_TARGET}.make (writing_rows.i_th (a_model).address, bible.books)).is_book then
					writing_row_opened := a_model
				end
				on_commentary_link (writing_rows.i_th (a_model).address)
				show_back_to_writings
			end
		end

	library_bar: SW_ROW
	back_to_writings_button: SW_BUTTON
			-- Above the library's reader: "Back to results" while a Writings hit is open there.

	writing_row_opened: INTEGER
			-- The Writings row whose book or essay the library shows; 0 for none.

	show_back_to_writings
			-- "Back to results" above the library's reader while a Writings hit is open there.
		do
			if writing_row_opened > 0 then
				if not library_bar.children.has (back_to_writings_button) then
					library_bar.put (back_to_writings_button)
				end
			elseif library_bar.children.has (back_to_writings_button) then
				library_bar.remove (back_to_writings_button)
			end
			window.request_render
		ensure
			shown_while_open: library_bar.children.has (back_to_writings_button) = (writing_row_opened > 0)
		end

	back_to_writings
			-- The Writings list again, the hit that was opened selected.
		do
			results_tabs.select_tab (Writings_tab)
			if writing_row_opened >= 1 and writing_row_opened <= writing_rows.count then
				reselect (writings_grid, writing_row_opened)
			end
			writing_row_opened := 0
			show_back_to_writings
		ensure
			closed: writing_row_opened = 0
		end

	writing_pack_name (a_hit: BIB_WRITING_HIT): STRING_32
			-- "Commentary", "Frameworks", "Books".
		do
			Result := a_hit.pack_kind.twin
			if not Result.is_empty then
				Result.put (Result [1].as_upper, 1)
			end
		end

	writing_text (a_hit: BIB_WRITING_HIT): STRING_32
			-- The hit's words on one line, its emphasis marks gone, the matched words still marked.
		do
			Result := a_hit.snippet.twin
			Result.replace_substring_all ({STRING_32} "%N", {STRING_32} " ")
			Result.prune_all ('*')
			Result.prune_all ('`')
		end

feature {NONE} -- Frameworks explained (P05.8, Larry, 2026-10-28)

	frameworks_grid: SW_DATA_GRID [BIB_FRAMEWORK]
	framework_rows: ARRAYED_LIST [BIB_FRAMEWORK]
	framework_view: SW_DOCUMENT_VIEW
			-- T4's Frameworks tab: every framework by tier, and the one chosen, explained.

	Frameworks_tab: INTEGER = 3
			-- T4's Frameworks page.

	frameworks_page: SW_SPLITTER
			-- The list beside the framework read.
		local
			l_list: SW_COLUMN
		do
			create l_list.make
			l_list.put (frameworks_grid.growing)
			create Result.make (l_list, framework_view)
			Result.set_ratio (0.32)
			fill_frameworks
		end

	framework_pack: detachable BIB_FRAMEWORK_PACK
			-- The frameworks pack, when one is attached.
		do
			if bible.is_open and then not bible.framework_packs.is_empty and then bible.framework_packs.first.is_available then
				Result := bible.framework_packs.first
			end
		end

	page_linker: BIB_REFERENCE_LINKER
			-- Links a page's references and, when the packs are attached, its framework names and the
			-- names of Larry's books and essays ("JESUS 06: Isaac's Word", 2026-10-28).
		do
			create Result.make (bible.books)
			if attached framework_names as al_names then
				Result.set_framework_names (al_names)
			end
			Result.set_writing_names (writing_names)
		end

	writing_names: BIB_FRAMEWORK_NAMES
			-- The names the books and essays go by, each with its link, read once.
		local
			l_names: ARRAYED_LIST [TUPLE [spelling, id: STRING_32; needs_mark: BOOLEAN]]
		do
			if attached writing_names_cache as al_cache then
				Result := al_cache
			else
				create l_names.make (256)
				across library_packs as ic loop
					l_names.append (ic.name_links)
				end
				create Result.make (l_names)
				writing_names_cache := Result
			end
		end

	writing_names_cache: detachable BIB_FRAMEWORK_NAMES
			-- `writing_names' once read.

	framework_names: detachable BIB_FRAMEWORK_NAMES
			-- The pack's spellings, read once.
		do
			if attached framework_names_cache as al_cache then
				Result := al_cache
			elseif attached framework_pack as al_pack and then attached al_pack.aliases as al_spellings and then al_spellings.is_success then
				create Result.make_from_spellings (al_spellings)
				framework_names_cache := Result
			end
		end

	framework_names_cache: detachable BIB_FRAMEWORK_NAMES
			-- `framework_names' once read.

	fill_frameworks
			-- The list: every framework of the pack, or the page saying there is no pack yet.
		do
			create framework_rows.make (0)
			if attached framework_pack as al_pack and then attached al_pack.frameworks as al_result and then al_result.is_success then
				create framework_rows.make (al_result.count)
				across 1 |..| al_result.count as al_i loop
					framework_rows.extend (al_result.item (al_i))
				end
				framework_view.set_document (commentary_reader.read ({STRING_32} "Choose a framework on the left, or click a framework's name wherever it appears."))
			else
				framework_view.set_document (commentary_reader.read ({STRING_32} "**No frameworks pack yet**%N%NA frameworks pack in the packs folder explains each FRAMEWORK, for the common reader, here."))
			end
			frameworks_grid.set_rows (framework_rows)
		end

	on_framework_row (a_model: INTEGER)
			-- A framework chosen in the list: read it.
		do
			if not is_reselecting and then a_model >= 1 and then a_model <= framework_rows.count then
				show_framework (framework_rows.i_th (a_model).id)
			end
		end

	show_framework (a_id: READABLE_STRING_GENERAL)
			-- Framework `a_id' in T4's Frameworks tab, the commentary left as it is: T4 brought into
			-- view.
		local
			i: INTEGER
		do
			bring_into_view (lexicon_panel, lexicon_tabs, Frameworks_tab)
			if attached framework_pack as al_pack and then attached al_pack.framework (a_id) as al_result
				and then al_result.is_success and then al_result.count = 1
			then
				framework_view.set_document (commentary_reader.read (framework_page (al_result.item (1))))
				shown_framework_document := framework_view.document
				shown_framework_id := a_id.to_string_32
				from i := 1 until i > framework_rows.count loop
					if framework_rows.i_th (i).id.same_string_general (a_id) then
						reselect (frameworks_grid, i)
					end
					i := i + 1
				end
			else
				framework_view.set_document (commentary_reader.read ({STRING_32} "No framework " + a_id.to_string_32 + {STRING_32} " in the frameworks pack yet."))
			end
			window.request_render
			mark_view (framework_view)
		end

	framework_page (a_framework: BIB_FRAMEWORK): STRING_32
			-- `a_framework' as a page: its name and title, a draft's label, its summary, its sections
			-- (their references and other frameworks' names linked; the heading never links to
			-- itself), the frameworks related to it, where the books and essays discuss it and where
			-- the commentary uses it.
		local
			l_range: STRING_32
			l_linker: BIB_REFERENCE_LINKER
			l_mentions: ARRAYED_LIST [BIB_BOOK_BLOCK]
			l_more: INTEGER
		do
			l_linker := page_linker
			create Result.make (2000)
			Result.append ({STRING_32} "# " + a_framework.display_name + {STRING_32} "%N%N*" + a_framework.title + {STRING_32} "*%N%N")
			if a_framework.is_draft then
				Result.append ({STRING_32} "**Draft:** written for Larry's review; not yet approved.%N%N")
			end
			Result.append ({STRING_32} "> " + a_framework.hover + {STRING_32} "%N%N")
			across a_framework.sections as ic loop
				Result.append ({STRING_32} "## " + ic.heading + {STRING_32} "%N%N" + l_linker.linked (ic.markdown) + {STRING_32} "%N%N")
			end
			if not a_framework.related.is_empty then
				Result.append ({STRING_32} "## Related frameworks%N%N")
				across a_framework.related as ic loop
					Result.append ({STRING_32} "- [" + framework_display_name (ic) + {STRING_32} "](" + {BIB_FRAMEWORK_SCHEMA}.Link_prefix + ic + {STRING_32} ")%N")
				end
				Result.append ({STRING_32} "%N")
			end
				-- At most `Book_mentions_shown' from each pack, so the essays show beside a book that
				-- names it often (scan 62).
			create l_mentions.make (0)
			across library_packs as ic loop
				if attached ic.blocks_naming (a_framework.id) as al_blocks and then al_blocks.is_success then
					across 1 |..| al_blocks.count as al_i loop
						if al_i <= Book_mentions_shown then
							l_mentions.extend (al_blocks.item (al_i))
						else
							l_more := l_more + 1
						end
					end
				end
			end
			if not l_mentions.is_empty then
				Result.append ({STRING_32} "## Where the books and essays discuss it%N%N")
				across l_mentions as ic loop
					Result.append ({STRING_32} "- [" + ic.book_title + {STRING_32} ", " + ic.chapter_title + {STRING_32} "](" + ic.link + {STRING_32} "): " + ic.snippet (90) + {STRING_32} "%N")
				end
				if l_more > 0 then
					Result.append ({STRING_32} "- ... and " + l_more.out.to_string_32 + {STRING_32} " more%N")
				end
				Result.append ({STRING_32} "%N")
			end
			if not a_framework.uses.is_empty then
				Result.append ({STRING_32} "## Where the commentary uses it%N%N")
				across a_framework.uses as ic loop
					l_range := range_label (ic.book, ic.chapter, ic.verse, ic.end_chapter, ic.end_verse)
					Result.append ({STRING_32} "- [" + l_range + {STRING_32} "]("
						+ (create {BIB_REFERENCE_LINKER}.make (bible.books)).range_target_text (ic.book, ic.chapter, ic.verse, ic.end_chapter, ic.end_verse)
						+ {STRING_32} "): " + ic.heading + {STRING_32} "%N")
				end
			end
		end

	framework_display_name (a_id: READABLE_STRING_GENERAL): STRING_32
			-- The listed framework `a_id''s name with its mark; the id when it is not listed.
		local
			i: INTEGER
		do
			Result := a_id.to_string_32
			from i := 1 until i > framework_rows.count loop
				if framework_rows.i_th (i).id.same_string_general (a_id) then
					Result := framework_rows.i_th (i).display_name
				end
				i := i + 1
			end
		end

	framework_card (a_id: READABLE_STRING_GENERAL): detachable SW_HOVER_CARD
			-- Framework `a_id''s name, title and plain summary, "Draft" while it is one; Void when the
			-- pack has no such framework.
		local
			l_heading: STRING_32
		do
			if attached framework_pack as al_pack and then attached al_pack.framework (a_id) as al_result
				and then al_result.is_success and then al_result.count = 1
			then
				l_heading := al_result.item (1).display_name + {STRING_32} ": " + al_result.item (1).title
				if al_result.item (1).is_draft then
					l_heading.append ({STRING_32} " (Draft)")
				end
				Result := card (l_heading, al_result.item (1).hover, "Click to read it in the Frameworks tab.")
			end
		end

	snapshot_framework_card
			-- For a snapshot: the card of the first framework linked in the commentary.
		do
			snapshot_link_card ({BIB_FRAMEWORK_SCHEMA}.Link_prefix)
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
			if commentary_verse > 0 then
				commentary_title.set_text (place_text (commentary_book, commentary_chapter, commentary_verse) + held_note)
			else
				commentary_title.set_text (place_text (commentary_book, commentary_chapter, 0) + {STRING_32} ": click a verse for its cross-references")
			end
			if commentary_book /= shown_book or commentary_chapter /= shown_chapter or commentary_verse /= shown_verse then
					-- Redrawn only when its verse changes, so a held commentary keeps its scroll.
				shown_book := commentary_book
				shown_chapter := commentary_chapter
				shown_verse := commentary_verse
				create cross_refs.make (0)
				if commentary_verse > 0 then
					l_result := bible.text_reader.cross_references (commentary_book, commentary_chapter, commentary_verse)
					create cross_refs.make (l_result.count)
					from i := 1 until i > l_result.count loop
						cross_refs.extend (l_result.item (i))
						i := i + 1
					end
				end
				cross_refs_grid.set_rows (cross_refs)
				fill_in_books
				fill_incipit
				fill_chiasm
				show_commentary
			end
		end

	commentary_view: SW_DOCUMENT_VIEW
			-- S2's Commentaries tab: the commentary packs' sections on the verse read (read-only).

	commentary_reader: MD_DOCUMENT_READER
			-- Markdown into the view's document model.

	on_commentary_link (a_target: STRING_32)
			-- (Also the Frameworks tab's links. A "framework:<id>" link opens that framework in T4's
			-- Frameworks tab, the commentary staying in view: Larry, 2026-10-28.)
			-- A link in the commentary clicked: "bible:<book>.<chapter>.<verse>" opens that place
			-- (verse 0: the chapter); a "book:" link, Larry's book there; another link is left alone.
			-- The target is read once (BIB_LINK_TARGET, scan 59).
		local
			l_target: BIB_LINK_TARGET
		do
			create l_target.make (a_target, bible.books)
			if l_target.is_framework then
				show_framework (l_target.id)
			elseif l_target.is_book then
				show_book_place (l_target.book_kind, l_target.id, l_target.chapter, l_target.block)
			elseif l_target.is_bible then
					-- Larry, 2026-10-28: the passage opens in T3 and the commentary stays where it was,
					-- until Back or a verse clicked in T3.
				if not is_commentary_held and reading_book > 0 and reading_chapter > 0 then
					held_book := reading_book
					held_chapter := reading_chapter
					held_verse := reading_verse
					is_commentary_held := True
				end
				is_following_commentary := True
				go_to (l_target.book, l_target.chapter, l_target.verse)
				is_following_commentary := False
				show_origin_button
			end
		end

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
			has_commentary := False
			if not bible.is_open or else bible.commentary_packs.is_empty then
				l_page := {STRING_32} "**No commentary yet**%N%NA commentary pack in the packs folder shows here, verse by verse."
				across bible.pack_errors as ic loop
					l_page.append ({STRING_32} "%N%N*A pack was refused: " + ic.message + {STRING_32} "*")
				end
			elseif commentary_verse = 0 then
				l_page := {STRING_32} "Click a verse for its commentary."
			else
				across bible.commentary_packs as ic loop
					if ic.is_available then
						l_sections := ic.sections_for_verse (commentary_book, commentary_chapter, commentary_verse)
						if attached l_sections.error as al_error then
							l_page.append ({STRING_32} "*" + ic.title + {STRING_32} ": " + al_error.message + {STRING_32} "*%N%N")
						elseif l_sections.count > 0 then
							create l_list.make (l_sections.count)
							from i := 1 until i > l_sections.count loop
								l_list.extend (l_sections.item (i))
								i := i + 1
							end
							l_page.append (page_linker.linked (l_text.page (ic.title, l_list)))
						end
					end
				end
				has_commentary := not l_page.is_empty
				if l_page.is_empty then
					l_page := {STRING_32} "No commentary on " + place_text (commentary_book, commentary_chapter, commentary_verse) + {STRING_32} " yet."
				end
			end
			commentary_view.set_document (commentary_reader.read (l_page))
			if commentary_verse > 0 and has_commentary then
				shown_commentary_document := commentary_view.document
				shown_commentary_hub := (create {BIB_HUB_ID}).hub_id (commentary_book, commentary_chapter, commentary_verse)
			else
				shown_commentary_document := Void
				shown_commentary_hub := 0
			end
			mark_view (commentary_view)
			commentary_found.call (Void)
		end

	on_cross_ref (a_model: INTEGER)
			-- A cross-reference clicked: read it.
		do
			if a_model >= 1 and a_model <= cross_refs.count then
				go_to (cross_refs.i_th (a_model).to_book, cross_refs.i_th (a_model).to_chapter, cross_refs.i_th (a_model).verse_start)
			end
		end

feature {NONE} -- Incipit (S2, research 26: the Old Testament in the New)

	incipit_grid: SW_DATA_GRID [like incipit_row_type]
			-- The links of the verse read, loudest first.

	incipit_rows: ARRAYED_LIST [like incipit_row_type]

	incipit_note: SW_LABEL
			-- What the grid shows, or what to do.

	incipit_row_type: TUPLE [place, kind, loudness, heard_by: STRING_32; book, chapter, verse: INTEGER;
			nt_place, ot_place: STRING_32; nt_book, nt_ch, nt_v, ot_book, ot_ch, ot_v: INTEGER]
			-- One row: the place shown, its kind, loudness and witnesses; where a click goes (`book' 0 when the
			-- reader cannot go there); and both ends of the link (`ot_book' 0 for a book only the LXX has).
		do
			Result := [{STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", 0, 0, 0, {STRING_32} "", {STRING_32} "", 0, 0, 0, 0, 0, 0]
		end

	incipit_row (a_link: like {BIB_INCIPIT_PACK}.link_type; a_place: STRING_32; a_to_old: BOOLEAN): like incipit_row_type
			-- A row showing `a_place' and carrying both ends of `a_link'; a click reads the Old Testament end
			-- when `a_to_old' and the reader has it, else the New Testament end.
		local
			l_nt: INTEGER
		do
			l_nt := book_number_of (a_link.nt_book)
			Result := [a_place, kind_text (a_link.kind), a_link.loudness, heard_by_text (a_link.witnesses), l_nt, a_link.nt_ch, a_link.nt_v,
				place_text (l_nt, a_link.nt_ch, a_link.nt_v), source_place_text (a_link), l_nt, a_link.nt_ch, a_link.nt_v,
				a_link.en_book_id, a_link.en_ch, a_link.en_v]
			if a_to_old and a_link.en_book_id > 0 then
				Result.book := a_link.en_book_id
				Result.chapter := a_link.en_ch
				Result.verse := a_link.en_v
			end
		end

	incipit_schema: BIB_INCIPIT_SCHEMA
		once
			create Result
		end

	First_new_testament_book: INTEGER = 40
			-- Matthew's book number.

	incipit_page: SW_COLUMN
			-- The Incipit tab: what to list, a note, the grid.
		local
			l_buttons: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (6.0)
			create l_buttons.make
			l_buttons.put (incipit_verse_button)
			l_buttons.put (incipit_all_nt_button)
			l_buttons.put (incipit_all_ot_button)
			Result.put (l_buttons)
			Result.put (incipit_note.as_muted)
			Result.put (incipit_grid.growing)
		end

	incipit_verse_button, incipit_all_nt_button, incipit_all_ot_button: SW_BUTTON
			-- What the Incipit tab lists.

	incipit_mode: INTEGER
			-- `Incipit_mode_verse' (the links of the verse read, the default), or every link in
			-- New Testament or Old Testament order (Larry, 2026-11-12: "I want the ability to see all
			-- of both in a list ... where I can click them and have the bible text go to that entry").

	Incipit_mode_verse: INTEGER = 0
	Incipit_mode_new: INTEGER = 1
	Incipit_mode_old: INTEGER = 2

	set_incipit_mode (a_mode: INTEGER)
			-- List `a_mode''s links. A whole list stays while the reader reads; This verse follows again.
		require
			a_mode: a_mode >= Incipit_mode_verse and a_mode <= Incipit_mode_old
		do
			incipit_mode := a_mode
			if a_mode = Incipit_mode_verse then
				fill_incipit_verse
			else
				fill_all_incipit (a_mode = Incipit_mode_old)
			end
		ensure
			set: incipit_mode = a_mode
		end

	fill_incipit
			-- The Incipit tab when the verse changes: the verse's links, unless a whole list is shown.
		do
			if incipit_mode = Incipit_mode_verse then
				fill_incipit_verse
			end
		end

	fill_all_incipit (a_by_old_testament: BOOLEAN)
			-- Every link, in New Testament order ("Matthew 27:46 <- Psalms 22:1 (LXX 21:2)") or Old
			-- Testament order ("Psalms 22:1 (LXX 21:2) -> Matthew 27:46"); a click reads the first place.
		local
			l_packs: ARRAYED_LIST [BIB_INCIPIT_PACK]
			l_nt: STRING_32
			l_book: INTEGER
		do
			create incipit_rows.make (4096)
			l_packs := bible.incipit_packs
			if l_packs.is_empty or else not l_packs.first.is_available then
				incipit_note.set_text ({STRING_32} "No incipit pack is installed. It brings the places where the New Testament draws on the Old.")
			else
				across l_packs.first.all_links (a_by_old_testament) as ic loop
					l_book := book_number_of (ic.nt_book)
					l_nt := place_text (l_book, ic.nt_ch, ic.nt_v)
					if a_by_old_testament then
						incipit_rows.extend (incipit_row (ic, source_place_text (ic) + {STRING_32} " %/8594/ " + l_nt, True))
					else
						incipit_rows.extend (incipit_row (ic, l_nt + {STRING_32} " %/8592/ " + source_place_text (ic), False))
					end
				end
				incipit_note.set_text ({STRING_32} "All " + incipit_rows.count.out.to_string_32 + (if a_by_old_testament then {STRING_32} " links, in Old Testament order" else {STRING_32} " links, in New Testament order" end)
					+ {STRING_32} ". Click one to read it; the list stays until This verse.")
			end
			incipit_grid.set_rows (incipit_rows)
		end

	fill_incipit_verse
			-- The Incipit tab follows the verse: a New Testament verse's links into the Old Testament
			-- (keyed in the LXX), or the New Testament places that take up an Old Testament verse.
		local
			l_packs: ARRAYED_LIST [BIB_INCIPIT_PACK]
			l_place: STRING_32
		do
			create incipit_rows.make (4)
			l_packs := bible.incipit_packs
			if l_packs.is_empty or else not l_packs.first.is_available then
				incipit_note.set_text ({STRING_32} "No incipit pack is installed. It brings the places where the New Testament draws on the Old.")
			elseif commentary_verse = 0 then
				incipit_note.set_text ({STRING_32} "Click a verse: a New Testament verse shows the Old Testament it draws on; an Old Testament verse shows where the New takes it up.")
			else
				l_place := place_text (commentary_book, commentary_chapter, commentary_verse)
				if commentary_book >= First_new_testament_book and commentary_book <= incipit_schema.Book_codes.count then
					across l_packs.first.links_from (incipit_schema.Book_codes [commentary_book], commentary_chapter, commentary_verse) as ic loop
						incipit_rows.extend (incipit_row (ic, source_place_text (ic), True))
					end
					if incipit_rows.is_empty then
						incipit_note.set_text (l_place + {STRING_32} ": no link into the Old Testament is known.")
					else
						incipit_note.set_text (l_place + {STRING_32} " draws on the Old Testament (LXX) in " + count_words (incipit_rows.count)
							+ {STRING_32} ", loudest first. Loud and clear stand above chance; a theme is named by a scholar's list but shares few words.")
					end
				elseif commentary_book >= 1 then
					across l_packs.first.links_into_english (commentary_book, commentary_chapter, commentary_verse) as ic loop
						incipit_rows.extend (incipit_row (ic, place_text (book_number_of (ic.nt_book), ic.nt_ch, ic.nt_v), False))
					end
					if incipit_rows.is_empty then
						incipit_note.set_text (l_place + {STRING_32} ": no New Testament use of this verse is known.")
					else
						incipit_note.set_text ({STRING_32} "The New Testament takes up " + l_place + {STRING_32} " in " + count_words (incipit_rows.count)
							+ {STRING_32} ", loudest first. Loud and clear stand above chance; a theme is named by a scholar's list but shares few words.")
					end
				end
			end
			incipit_grid.set_rows (incipit_rows)
		end

	on_incipit_row (a_model: INTEGER)
			-- An Incipit row clicked: read its place, when the reader has it.
		do
			if a_model >= 1 and a_model <= incipit_rows.count and then incipit_rows.i_th (a_model).book > 0 then
				go_to (incipit_rows.i_th (a_model).book, incipit_rows.i_th (a_model).chapter, incipit_rows.i_th (a_model).verse)
			end
		end

	incipit_menu (a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- An Incipit row: read either end, or both side by side (Larry, 2026-11-12: "how can I get to the
			-- NT ref, and can I see them side by side?").
		do
			if attached incipit_grid.context_object as al_row then
				a_menu.add_item ({STRING_32} "Read " + al_row.nt_place, "", al_row.nt_book > 0, agent go_to (al_row.nt_book.max (1), al_row.nt_ch.max (1), al_row.nt_v.max (0)))
				a_menu.add_item ({STRING_32} "Read " + al_row.ot_place, "", al_row.ot_book > 0, agent go_to (al_row.ot_book.max (1), al_row.ot_ch.max (1), al_row.ot_v.max (0)))
				a_menu.add_item ({STRING_32} "Side by side", "", True, agent show_pair (al_row))
			end
			pane_menu (commentary_panel, a_menu, a_px, a_py)
		end

	pair_view: SW_PARALLEL_TEXT
			-- Side by side: an Incipit link's Old Testament passage (left) beside its New Testament one (right).

	pair_stack: SW_PARALLEL_TEXT
			-- Over and under: the Old Testament passage above the New Testament one.

	pair_page: SW_COLUMN
			-- The Side by side window's content: its bar, then `pair_view' or `pair_stack'.

	pair_layout_button: SW_BUTTON
			-- Switches the window between side by side and over and under; says what it will do.

	pair_side_places, pair_stack_places: HASH_TABLE [TUPLE [book, chapter, verse: INTEGER], INTEGER]
			-- The verse in each cell of `pair_view' and `pair_stack', keyed by row * 10 + column.

	pair_over_under: BOOLEAN
			-- Does the window show the passages over and under (else side by side)?

	pair_link: detachable like incipit_row_type
			-- The link the window shows (Void: none chosen yet).

	pair_float: detachable SW_FLOATING_WINDOW
			-- The Side by side window, while open (Larry, 2026-11-12: "a popover window that allows me to
			-- see the two verses or the passages side by side"; then: a switch to over and under, and a
			-- window he can size by its corners, move, and maximize).

	Pair_context: INTEGER = 3
			-- Verses shown before and after each linked verse.

	build_pair_page
			-- The window's content, built once: the layout switch, then the side-by-side view.
		local
			l_bar: SW_ROW
		do
			create pair_page.make
			pair_page := pair_page.with_gap (6.0)
			create pair_layout_button.make ("Over and under", Void)
			pair_layout_button.set_tooltip ("Over and under: the Old Testament passage above the New. Click again for side by side.")
			create l_bar.make
			l_bar.put (pair_layout_button)
			pair_page.put (l_bar)
			pair_page.put (pair_view.growing)
		end

	show_pair (a_row: like incipit_row_type)
			-- Open the Side by side window on `a_row''s two ends, in place of any open one: a window of
			-- its own, sized by its edges and corners, moved by its title bar, with a maximize box.
		local
			l_float: SW_FLOATING_WINDOW
		do
			close_pair
			pair_link := a_row
			fill_pair
			l_float := window.float_document (pair_page, {STRING_32} "Side by side: " + a_row.ot_place + {STRING_32} " and " + a_row.nt_place, 160, 120, 1100, 600)
			if l_float.is_open then
				l_float.set_on_close_request (agent close_pair)
				pair_float := l_float
			end
		ensure
			chosen: pair_link = a_row
		end

	close_pair
			-- Close the Side by side window, if open.
		do
			if attached pair_float as al_float and then window.floating_windows.has (al_float) then
				window.unfloat (al_float)
			end
			pair_float := Void
		ensure
			closed: pair_float = Void
		end

	toggle_pair_layout
			-- The layout switch: side by side to over and under, or back.
		do
			set_pair_over_under (not pair_over_under)
		ensure
			switched: pair_over_under = not old pair_over_under
		end

	set_pair_over_under (a_over_under: BOOLEAN)
			-- Show the passages over and under when `a_over_under', else side by side.
		do
			pair_over_under := a_over_under
			if pair_page.children.has (pair_view) then
				pair_page.remove (pair_view)
			end
			if pair_page.children.has (pair_stack) then
				pair_page.remove (pair_stack)
			end
			if a_over_under then
				pair_page.put (pair_stack.growing)
				pair_layout_button.set_label ("Side by side")
				pair_layout_button.set_tooltip ("Side by side: the Old Testament passage on the left, the New on the right. Click again for over and under.")
			else
				pair_page.put (pair_view.growing)
				pair_layout_button.set_label ("Over and under")
				pair_layout_button.set_tooltip ("Over and under: the Old Testament passage above the New. Click again for side by side.")
			end
			window.request_render
		ensure
			set: pair_over_under = a_over_under
			one_view: pair_page.children.has (pair_stack) = a_over_under and pair_page.children.has (pair_view) = not a_over_under
		end

	fill_pair
			-- Both layouts of the link chosen, in the version read, `Pair_context' verses around each end,
			-- the two linked verses marked: side by side on one row; over and under, each under its place.
		local
			l_ot, l_nt: HASH_TABLE [STRING_32, INTEGER]
			k, l_row: INTEGER
			l_name, l_note: STRING_32
		do
			pair_view.wipe_out
			pair_stack.wipe_out
			pair_side_places.wipe_out
			pair_stack_places.wipe_out
			if attached pair_link as al_link then
				l_name := reading_version.to_string_32
				if attached bible.text_reader.version (reading_version) as al_version then
					l_name := al_version.name
				end
				l_note := al_link.kind + {STRING_32} ", " + al_link.loudness + {STRING_32} "; heard by " + al_link.heard_by
					+ {STRING_32} ". " + l_name + {STRING_32} ". Right-click a verse to read it in its chapter."
				l_ot := chapter_texts (al_link.ot_book, al_link.ot_ch)
				l_nt := chapter_texts (al_link.nt_book, al_link.nt_ch)
					-- Side by side
				pair_view.set_column_title (1, al_link.ot_place)
				pair_view.set_column_title (2, al_link.nt_place)
				pair_view.add_note (l_note).do_nothing
				from k := - Pair_context until k > Pair_context loop
					l_row := pair_view.add_row ("")
					put_pair_verse (pair_view, pair_side_places, l_row, 1, al_link.ot_book, al_link.ot_ch, al_link.ot_v, k, l_ot)
					put_pair_verse (pair_view, pair_side_places, l_row, 2, al_link.nt_book, al_link.nt_ch, al_link.nt_v, k, l_nt)
					k := k + 1
				end
					-- Over and under
				pair_stack.set_column_title (1, al_link.ot_place + {STRING_32} ", then " + al_link.nt_place)
				pair_stack.add_note (l_note).do_nothing
				pair_stack.add_note (al_link.ot_place).do_nothing
				from k := - Pair_context until k > Pair_context loop
					l_row := pair_stack.add_row ("")
					put_pair_verse (pair_stack, pair_stack_places, l_row, 1, al_link.ot_book, al_link.ot_ch, al_link.ot_v, k, l_ot)
					k := k + 1
				end
				pair_stack.add_note (al_link.nt_place).do_nothing
				from k := - Pair_context until k > Pair_context loop
					l_row := pair_stack.add_row ("")
					put_pair_verse (pair_stack, pair_stack_places, l_row, 1, al_link.nt_book, al_link.nt_ch, al_link.nt_v, k, l_nt)
					k := k + 1
				end
			else
				pair_view.set_column_title (1, "Old Testament")
				pair_view.set_column_title (2, "New Testament")
				pair_view.add_note ({STRING_32} "Right-click a link in the Incipit tab and choose Side by side.").do_nothing
				pair_stack.set_column_title (1, "Old Testament, then New Testament")
				pair_stack.add_note ({STRING_32} "Right-click a link in the Incipit tab and choose Side by side.").do_nothing
			end
		end

	put_pair_verse (a_view: SW_PARALLEL_TEXT; a_places: like pair_side_places; a_row, a_column, a_book, a_chapter, a_verse, a_offset: INTEGER;
			a_texts: HASH_TABLE [STRING_32, INTEGER])
			-- Put verse `a_verse' + `a_offset' of `a_texts' in `a_view''s cell `a_row', `a_column' and remember
			-- its place; the linked verse (`a_offset' 0) marked; a book only the LXX has says so.
		require
			valid_row: a_row >= 1 and a_row <= a_view.row_count
			verse_row: not a_view.is_note_row (a_row)
			valid_column: a_column >= 1 and a_column <= a_view.column_count
		local
			l_verse: INTEGER
		do
			l_verse := a_verse + a_offset
			if attached a_texts.item (l_verse) as al_text then
				a_view.set_cell (a_row, a_column, verse_label (a_chapter, l_verse) + al_text)
				a_places.force ([a_book, a_chapter, l_verse], a_row * 10 + a_column)
				if a_offset = 0 then
					mark_selected_verse (a_view, a_row, a_column)
				end
			elseif a_offset = 0 and a_book = 0 then
				a_view.set_cell (a_row, a_column, {STRING_32} "A book only the LXX has; this Bible does not carry it.")
			end
		end

	verse_label (a_chapter, a_verse: INTEGER): STRING_32
			-- "27:46  ", leading a verse's text in the Side by side window.
		do
			Result := a_chapter.out.to_string_32
			Result.append_character (':')
			Result.append (a_verse.out.to_string_32)
			Result.append ({STRING_32} "  ")
		end

	chapter_texts (a_book, a_chapter: INTEGER): HASH_TABLE [STRING_32, INTEGER]
			-- `a_book' `a_chapter''s verses in the version read, by verse number (empty for book 0).
		local
			l_chapter: BIB_LIST_RESULT [BIB_READING_VERSE]
			i: INTEGER
		do
			create Result.make (40)
			if a_book > 0 and a_chapter > 0 and bible.is_open then
				l_chapter := bible.text_reader.chapter (reading_version, a_book, a_chapter)
				from i := 1 until i > l_chapter.count loop
					Result.force (l_chapter.item (i).display_text, l_chapter.item (i).verse)
					i := i + 1
				end
			end
		end

	pair_menu (a_view: SW_PARALLEL_TEXT; a_places: like pair_side_places; a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- The Side by side window: read the verse under the pointer, in its own chapter.
		local
			l_cell: TUPLE [row, column: INTEGER]
		do
			l_cell := a_view.cell_at (a_px, a_py)
			if attached a_places.item (l_cell.row * 10 + l_cell.column) as al_place then
				a_menu.add_item ({STRING_32} "Read " + place_text (al_place.book, al_place.chapter, al_place.verse), "", True,
					agent go_to (al_place.book, al_place.chapter, al_place.verse))
			end
		end

	source_place_text (a_link: like {BIB_INCIPIT_PACK}.link_type): STRING_32
			-- "Psalm 22:1 (LXX 21:2)"; a book only the LXX has, by its LXX place: "Wisdom 2:18 (LXX only)".
		do
			if a_link.en_book_id > 0 then
				Result := place_text (a_link.en_book_id, a_link.en_ch, a_link.en_v) + {STRING_32} " (LXX " + a_link.lxx_ch.out.to_string_32
					+ {STRING_32} ":" + a_link.lxx_v.out.to_string_32 + {STRING_32} ")"
			else
				Result := a_link.unit_title + {STRING_32} ":" + a_link.lxx_v.out.to_string_32 + {STRING_32} " (LXX only)"
			end
		end

	kind_text (a_kind: STRING_32): STRING_32
			-- "word link" for "word_link".
		do
			Result := a_kind.twin
			Result.replace_substring_all ({STRING_32} "_", {STRING_32} " ")
		end

	heard_by_text (a_witnesses: STRING_32): STRING_32
			-- "UBS, H%/252/hn (quoted)" for "ubs huhn*".
		local
			l_word: STRING_32
		do
			create Result.make (32)
			across a_witnesses.split (' ') as ic loop
				if ic.same_string ({STRING_32} "ubs") then
					l_word := {STRING_32} "UBS"
				elseif ic.same_string ({STRING_32} "huhn**") then
					l_word := {STRING_32} "H%/252/hn (quoted, formula)"
				elseif ic.same_string ({STRING_32} "huhn*") then
					l_word := {STRING_32} "H%/252/hn (quoted)"
				elseif ic.same_string ({STRING_32} "huhn") then
					l_word := {STRING_32} "H%/252/hn"
				elseif ic.same_string ({STRING_32} "measure") then
					l_word := {STRING_32} "measured"
				else
					l_word := ic
				end
				if not l_word.is_empty then
					if not Result.is_empty then
						Result.append ({STRING_32} ", ")
					end
					Result.append (l_word)
				end
			end
		end

	book_number_of (a_code: STRING_32): INTEGER
			-- The book number of code `a_code' ("MAT" = 40), 0 when unknown.
		do
			across incipit_schema.Book_codes as ic until Result > 0 loop
				if ic.same_string_general (a_code) then
					Result := @ic.cursor_index
				end
			end
		ensure
			a_book_or_none: Result >= 0 and Result <= 66
		end

feature {NONE} -- Chiasm (S2, research 28: structures and chiasms)

	chiasm_note: SW_LABEL
			-- What the tab shows, or what to do.

	chiasm_structures_grid: SW_DATA_GRID [like chiasm_structure_row_type]
			-- The structures covering the verse read, innermost first.

	chiasm_structure_rows: ARRAYED_LIST [like chiasm_structure_row_type]

	chiasm_ladder_grid: SW_DATA_GRID [like chiasm_member_row_type]
			-- The chosen structure's members, indented toward its center.

	chiasm_member_rows: ARRAYED_LIST [like chiasm_member_row_type]

	chiasm_structure_row_type: TUPLE [title, range, pattern, grade, source: STRING_32; structure_id, book, ch, v: INTEGER]
		do
			Result := [{STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", 0, 0, 0, 0]
		end

	chiasm_member_row_type: TUPLE [letter, verses, label, pair: STRING_32; ch, v: INTEGER]
		do
			Result := [{STRING_32} "", {STRING_32} "", {STRING_32} "", {STRING_32} "", 0, 0]
		end

	Chiasm_tab: INTEGER = 6
			-- S2's Chiasm page (research 28, 2026-11-11).

	chiasm_page: SW_COLUMN
			-- The Chiasm tab: what to list, a note, the structures, the ladder of the one chosen.
		local
			l_buttons: SW_ROW
		do
			create Result.make
			Result := Result.with_gap (6.0)
			create l_buttons.make
			l_buttons.put (chiasm_verse_button)
			l_buttons.put (chiasm_all_button)
			l_buttons.put (chiasm_graded_button)
			Result.put (l_buttons)
			Result.put (chiasm_note.as_muted)
			Result.put (chiasm_structures_grid)
			Result.put (chiasm_ladder_grid.growing)
		end

	chiasm_verse_button, chiasm_all_button, chiasm_graded_button: SW_BUTTON
			-- What the Chiasm tab lists.

	chiasm_mode: INTEGER
			-- `Chiasm_mode_verse' (the structures around the verse read, the default), every
			-- structure, or the strong and moderate ones, each with its full range (Larry, 2026-11-12).

	Chiasm_mode_verse: INTEGER = 0
	Chiasm_mode_all: INTEGER = 1
	Chiasm_mode_graded: INTEGER = 2

	set_chiasm_mode (a_mode: INTEGER)
			-- List `a_mode''s structures. A whole list stays while the reader reads; This verse follows again.
		require
			a_mode: a_mode >= Chiasm_mode_verse and a_mode <= Chiasm_mode_graded
		do
			chiasm_mode := a_mode
			if a_mode = Chiasm_mode_verse then
				fill_chiasm_verse
			else
				fill_all_chiasm (a_mode = Chiasm_mode_graded)
			end
		ensure
			set: chiasm_mode = a_mode
		end

	fill_chiasm
			-- The Chiasm tab when the verse changes: the structures around it, unless a whole list is shown.
		do
			if chiasm_mode = Chiasm_mode_verse then
				fill_chiasm_verse
			end
		end

	fill_all_chiasm (a_graded_only: BOOLEAN)
			-- Every structure (or the strong and moderate ones) in book order with its full range; a
			-- click reads where it begins and shows its ladder.
		local
			l_packs: ARRAYED_LIST [BIB_CHIASM_PACK]
		do
			create chiasm_structure_rows.make (1024)
			create chiasm_member_rows.make (8)
			l_packs := bible.chiasm_packs
			if l_packs.is_empty or else not l_packs.first.is_available then
				chiasm_note.set_text ({STRING_32} "No chiasm pack is installed. It brings Bullinger's structures, each graded against chance.")
			else
				across l_packs.first.all_structures (a_graded_only) as ic loop
					chiasm_structure_rows.extend ([ic.title, place_text (ic.book_id, ic.ch_from, ic.v_from) + {STRING_32} "-" + verses_text (ic.ch_to, ic.v_to, ic.ch_to, ic.v_to),
						pattern_text (ic.pattern), grade_text (ic.grade, ic.p_shape), source_text (ic.source, ic.kind_printed), ic.structure_id, ic.book_id, ic.ch_from, ic.v_from])
				end
				chiasm_note.set_text ({STRING_32} "All " + chiasm_structure_rows.count.out.to_string_32
					+ (if a_graded_only then {STRING_32} " strong and moderate structures" else {STRING_32} " structures" end)
					+ {STRING_32} ", in book order. Click one to read it and see its ladder; the list stays until This verse.")
			end
			chiasm_structures_grid.set_rows (chiasm_structure_rows)
			chiasm_ladder_grid.set_rows (chiasm_member_rows)
		end

	fill_chiasm_verse
			-- The Chiasm tab follows the verse: the structures covering it, innermost first, and the
			-- ladder of the innermost.
		local
			l_packs: ARRAYED_LIST [BIB_CHIASM_PACK]
		do
			create chiasm_structure_rows.make (4)
			create chiasm_member_rows.make (8)
			l_packs := bible.chiasm_packs
			if l_packs.is_empty or else not l_packs.first.is_available then
				chiasm_note.set_text ({STRING_32} "No chiasm pack is installed. It brings Bullinger's structures, each graded against chance.")
			elseif commentary_verse = 0 or commentary_book < 1 or commentary_book > 66 then
				chiasm_note.set_text ({STRING_32} "Click a verse to see the structures it stands in.")
			else
				across l_packs.first.structures_at (commentary_book, commentary_chapter, commentary_verse) as ic loop
					chiasm_structure_rows.extend ([ic.title, verses_text (ic.ch_from, ic.v_from, ic.ch_to, ic.v_to),
						pattern_text (ic.pattern), grade_text (ic.grade, ic.p_shape), source_text (ic.source, ic.kind_printed), ic.structure_id, commentary_book, ic.ch_from, ic.v_from])
				end
				if chiasm_structure_rows.is_empty then
					chiasm_note.set_text (place_text (commentary_book, commentary_chapter, commentary_verse) + {STRING_32} ": no structure is known here.")
				else
					chiasm_note.set_text (place_text (commentary_book, commentary_chapter, commentary_verse) + {STRING_32} " stands in " + chiasm_count_words (chiasm_structure_rows.count)
						+ {STRING_32} ", innermost first. Strong and moderate pair by shared words above chance; thematic pairs by idea.")
					show_chiasm_ladder (1)
				end
			end
			chiasm_structures_grid.set_rows (chiasm_structure_rows)
			chiasm_ladder_grid.set_rows (chiasm_member_rows)
		end

	show_chiasm_ladder (a_row: INTEGER)
			-- The ladder of structure row `a_row': members indented toward the center; the member
			-- holding the verse read marked.
		local
			l_members: ARRAYED_LIST [like {BIB_CHIASM_PACK}.member_type]
			l_depth, n: INTEGER
			l_letter, l_pair: STRING_32
			l_holds: BOOLEAN
		do
			create chiasm_member_rows.make (8)
			if a_row >= 1 and a_row <= chiasm_structure_rows.count and then not bible.chiasm_packs.is_empty then
				l_members := bible.chiasm_packs.first.members_of (chiasm_structure_rows.i_th (a_row).structure_id)
				n := l_members.count
				across l_members as ic loop
					if ic.pair_seq > 0 then
						l_depth := (@ic.cursor_index - 1).min (n - @ic.cursor_index)
					else
						l_depth := 0
					end
					l_holds := ic.ch_from * 1000 + ic.v_from <= commentary_chapter * 1000 + commentary_verse
						and commentary_chapter * 1000 + commentary_verse <= ic.ch_to * 1000 + ic.v_to
					create l_letter.make_filled (' ', 3 * l_depth)
					if l_holds then
						l_letter.prepend ({STRING_32} "%/9654/ ")
					end
					l_letter.append (ic.letter)
					if ic.letter_inferred then
						l_letter.append ({STRING_32} "*")
					end
					if ic.pair_seq > 0 then
						l_pair := {STRING_32} "with " + ic.pair_seq.out.to_string_32 + {STRING_32} ": " + score_text (ic.pair_score)
					else
						create l_pair.make_empty
					end
					chiasm_member_rows.extend ([l_letter, verses_text (ic.ch_from, ic.v_from, ic.ch_to, ic.v_to), ic.label, l_pair, ic.ch_from, ic.v_from])
				end
			end
			chiasm_ladder_grid.set_rows (chiasm_member_rows)
		end

	on_chiasm_structure_row (a_model: INTEGER)
			-- A structure chosen: show its ladder; from a whole list, read where it begins first.
		do
			if chiasm_mode /= Chiasm_mode_verse and a_model >= 1 and a_model <= chiasm_structure_rows.count then
				go_to (chiasm_structure_rows.i_th (a_model).book, chiasm_structure_rows.i_th (a_model).ch, chiasm_structure_rows.i_th (a_model).v)
			end
			show_chiasm_ladder (a_model)
		end

	on_chiasm_member_row (a_model: INTEGER)
			-- A member clicked: read where it begins.
		do
			if a_model >= 1 and a_model <= chiasm_member_rows.count and then commentary_book >= 1 then
				go_to (commentary_book, chiasm_member_rows.i_th (a_model).ch, chiasm_member_rows.i_th (a_model).v)
			end
		end

	verses_text (a_ch_from, a_v_from, a_ch_to, a_v_to: INTEGER): STRING_32
			-- "6:9-9:29", "6:14-22" or "8:20".
		do
			Result := a_ch_from.out.to_string_32 + {STRING_32} ":" + a_v_from.out.to_string_32
			if a_ch_to /= a_ch_from then
				Result.append ({STRING_32} "-" + a_ch_to.out.to_string_32 + {STRING_32} ":" + a_v_to.out.to_string_32)
			elseif a_v_to /= a_v_from then
				Result.append ({STRING_32} "-" + a_v_to.out.to_string_32)
			end
		end

	pattern_text (a_pattern: STRING_32): STRING_32
			-- "introversion (a mirror)", "alternation", ...
		do
			if a_pattern.same_string ({STRING_32} "introversion") then
				Result := {STRING_32} "introversion (mirror)"
			elseif a_pattern.same_string ({STRING_32} "inclusio") then
				Result := {STRING_32} "inclusio (frame)"
			elseif a_pattern.same_string ({STRING_32} "extended_alternation") then
				Result := {STRING_32} "extended alternation"
			else
				Result := a_pattern.twin
			end
		end

	grade_text (a_grade: STRING_32; a_p: REAL_64): STRING_32
			-- "strong (p 0.006)", "thematic", "not graded".
		do
			if a_grade.same_string ({STRING_32} "strong") or a_grade.same_string ({STRING_32} "moderate") or a_grade.same_string ({STRING_32} "thematic") then
				Result := a_grade.twin
				if a_p > 0 then
					Result.append ({STRING_32} " (p " + score_text (a_p) + {STRING_32} ")")
				end
			elseif a_grade.same_string ({STRING_32} "untestable") then
				Result := {STRING_32} "untestable"
			else
				Result := {STRING_32} "not graded"
			end
		end

	score_text (a_value: REAL_64): STRING_32
			-- `a_value' to three places: "0.447".
		local
			l_n: INTEGER
		do
			l_n := (a_value * 1000).rounded
			Result := (l_n // 1000).out.to_string_32 + {STRING_32} "." + (l_n \\ 1000 + 1000).out.to_string_32.substring (2, 4)
		end

	chiasm_count_words (a_count: INTEGER): STRING_32
			-- "1 structure", "3 structures".
		do
			Result := a_count.out.to_string_32 + (if a_count = 1 then {STRING_32} " structure" else {STRING_32} " structures" end)
		end

	chiasm_structure_title (a_row: like chiasm_structure_row_type): STRING_32
		do
			Result := a_row.title
		end

	chiasm_structure_range (a_row: like chiasm_structure_row_type): STRING_32
		do
			Result := a_row.range
		end

	chiasm_structure_pattern (a_row: like chiasm_structure_row_type): STRING_32
		do
			Result := a_row.pattern
		end

	chiasm_structure_source (a_row: like chiasm_structure_row_type): STRING_32
		do
			Result := a_row.source
		end

	source_text (a_source, a_kind: STRING_32): STRING_32
			-- "Bullinger", "Boys", "Larry (settled)" ...: a Larry structure carries its status in `a_kind'.
		do
			if a_source.same_string ({STRING_32} "larry") then
				Result := a_kind.twin
			elseif a_source.is_empty then
				Result := {STRING_32} "Bullinger"
			else
				Result := a_source.as_upper.substring (1, 1) + a_source.substring (2, a_source.count)
			end
		end

	chiasm_structure_grade (a_row: like chiasm_structure_row_type): STRING_32
		do
			Result := a_row.grade
		end

	chiasm_member_letter (a_row: like chiasm_member_row_type): STRING_32
		do
			Result := a_row.letter
		end

	chiasm_member_verses (a_row: like chiasm_member_row_type): STRING_32
		do
			Result := a_row.verses
		end

	chiasm_member_label (a_row: like chiasm_member_row_type): STRING_32
		do
			Result := a_row.label
		end

	chiasm_member_pair (a_row: like chiasm_member_row_type): STRING_32
		do
			Result := a_row.pair
		end

	chiasm_letters_mode: INTEGER
			-- Which mirrors put their letters in the reading gutter: `Chiasm_letters_graded' (the
			-- default: strong and moderate, where shared words carry the mirror), `Chiasm_letters_all'
			-- or `Chiasm_letters_off'. Not kept between runs yet.

	Chiasm_letters_graded: INTEGER = 0
	Chiasm_letters_all: INTEGER = 1
	Chiasm_letters_off: INTEGER = 2

	set_chiasm_letters_mode (a_mode: INTEGER)
			-- Show the chiasm letters for `a_mode''s mirrors, and redraw the chapter.
		require
			a_mode: a_mode >= Chiasm_letters_graded and a_mode <= Chiasm_letters_off
		do
			chiasm_letters_mode := a_mode
			if reading.has_place then
				show_chapter
			end
		ensure
			set: chiasm_letters_mode = a_mode
		end

	chiasm_letters (a_book, a_chapter: INTEGER): HASH_TABLE [STRING_32, INTEGER]
			-- For each verse of the chapter read that stands in a mirror (an introversion) the mode
			-- shows, the letter of its member in the innermost such mirror: the gutter reads "6 A".
		local
			l_members: HASH_TABLE [ARRAYED_LIST [like {BIB_CHIASM_PACK}.member_type], INTEGER]
			l_place: INTEGER
			l_found: BOOLEAN
		do
			create Result.make (32)
			if chiasm_letters_mode /= Chiasm_letters_off and a_book >= 1 and a_book <= 66 and then not bible.chiasm_packs.is_empty
				and then attached bible.chiasm_packs.first as al_pack and then al_pack.is_available
			then
				create l_members.make (8)
				across reading_verses as ic_v loop
					l_place := a_chapter * 1000 + ic_v.verse
					l_found := False
					across al_pack.structures_at (a_book, a_chapter, ic_v.verse) as ic_s until l_found loop
						if (ic_s.pattern.same_string ({STRING_32} "introversion") or ic_s.pattern.same_string ({STRING_32} "inclusio")) and then (chiasm_letters_mode = Chiasm_letters_all
							or ic_s.grade.same_string ({STRING_32} "strong") or ic_s.grade.same_string ({STRING_32} "moderate"))
						then
							if not l_members.has (ic_s.structure_id) then
								l_members.put (al_pack.members_of (ic_s.structure_id), ic_s.structure_id)
							end
							if attached l_members.item (ic_s.structure_id) as al_list then
								across al_list as ic_m until l_found loop
									if ic_m.ch_from * 1000 + ic_m.v_from <= l_place and l_place <= ic_m.ch_to * 1000 + ic_m.v_to then
										if ic_m.ch_from = a_chapter and ic_m.v_from = ic_v.verse then
											Result.put (ic_m.letter, ic_v.verse)
										else
												-- a member's later verses: a line down the gutter, a bracket's stem
											Result.put ({STRING_32} "|", ic_v.verse)
										end
										l_found := True
									end
								end
							end
						end
					end
				end
			end
		end

	dock_panel_into (a_panel, a_zone: INTEGER)
			-- Put `a_panel' in `a_zone' unless it is there already. SW_DOCK_HOST.move_panel promises
			-- the panel then ends its zone (simple_widgets 1r-b, c430fea), but leaves a panel already
			-- in the zone where it stands, so asking twice broke that promise (the GUI suite's first
			-- test, 2026-11-11). Skipping the second ask keeps the layout the lean build gave.
		do
			if not dock.all_panels_in (a_zone).has (a_panel) then
				dock.move_panel (a_panel, a_zone)
			end
		ensure
			in_the_zone: dock.all_panels_in (a_zone).has (a_panel)
		end

	incipit_place (a_row: like incipit_row_type): STRING_32
		do
			Result := a_row.place
		end

	incipit_kind (a_row: like incipit_row_type): STRING_32
		do
			Result := a_row.kind
		end

	incipit_loudness (a_row: like incipit_row_type): STRING_32
		do
			Result := a_row.loudness
		end

	incipit_heard_by (a_row: like incipit_row_type): STRING_32
		do
			Result := a_row.heard_by
		end

	count_words (a_count: INTEGER): STRING_32
			-- "1 place", "3 places".
		do
			Result := a_count.out.to_string_32 + (if a_count = 1 then {STRING_32} " place" else {STRING_32} " places" end)
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
				word_opened.call (Void)
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
			refresh_strip_marks
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

	on_window_tick
			-- The window's heartbeat: a long every-place list's next pages; an Ask request waiting for
			-- its helper to start, once "Starting Ask" has been painted (0.7.32); a folder of prepared
			-- files, once "Importing" has been painted (2026-10-30).
		do
			load_more_places
			if attached pending_ask as al_text then
				pending_ask_ticks := pending_ask_ticks - 1
				if pending_ask_ticks <= 0 then
					pending_ask := Void
					answer_ask (al_text)
				end
			end
			if attached pending_folder as al_folder then
				pending_folder_ticks := pending_folder_ticks - 1
				if pending_folder_ticks <= 0 then
					pending_folder := Void
					import_folder (al_folder)
				end
			end
			if attached pending_kit_folder as al_folder then
				pending_kit_folder_ticks := pending_kit_folder_ticks - 1
				if pending_kit_folder_ticks <= 0 then
					pending_kit_folder := Void
					make_kits (al_folder)
				end
			end
			if pending_notes_rebuild_ticks > 0 then
				pending_notes_rebuild_ticks := pending_notes_rebuild_ticks - 1
				if pending_notes_rebuild_ticks = 0 then
					rebuild_stale_packs
				end
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

	verses_heading: SW_LABEL
	verses_grid: SW_DATA_GRID [BIB_READING_VERSE]
			-- P07's verses (2026-10-27): every verse of the version read that holds the words.

	verse_hits: ARRAYED_LIST [BIB_READING_VERSE]
			-- The rows of `verses_grid', in Bible order.

	Verse_hit_limit: INTEGER = 500
			-- The most verses P07 lists (the heading gives the full count).

	find_verses (a_words: READABLE_STRING_GENERAL)
			-- The verses of the version read that `a_words' names (words, "phrases", word*, AND, OR,
			-- NOT, parentheses, strongs:H1254 or G5485, lemma:), listed under the word choices with
			-- their count (B02, B03).
		local
			l_found: BIB_LIST_RESULT [BIB_READING_VERSE]
			l_query: BIB_QUERY
			l_scope: BIB_SEARCH_SCOPE
			l_total: INTEGER
		do
			create verse_hits.make (0)
			if reading_version.is_empty or else not bible.text_reader.has_version (reading_version) then
				verses_heading.set_text ("")
			else
					-- The scope once per search (design scan 52: it was built for the parse and again for the
					-- heading).
				l_scope := search_scope
				l_query := bible.query_parser.parsed (a_words, l_scope)
				if not l_query.is_valid then
					verses_heading.set_text ({STRING_32} "The search cannot be read at character " + l_query.error_position.out + {STRING_32} ": " + l_query.error_message)
				elseif l_query.has_text_clause and not bible.text_reader.has_verse_index then
					verses_heading.set_text ("This content.db has no verse index: rebuild it with bible_build 0.3.0 to search the text.")
				else
					bible.verse_search.find (l_query, reading_version)
					if bible.verse_search.has_failed then
						verses_heading.set_text (bible.verse_search.error_message)
					else
						l_found := bible.verse_search.verses (reading_version, 1, Verse_hit_limit)
						if l_found.is_success then
							across 1 |..| l_found.count as i loop
								verse_hits.extend (l_found.item (i))
							end
							l_total := bible.verse_search.places.count
							show_verse_count (l_total, l_scope)
						else
								-- Design scan 48: a count was shown over no rows.
							verses_heading.set_text ("The verses were found but could not be read.")
						end
					end
				end
			end
			verses_grid.set_rows (verse_hits)
		end

	show_verse_count (a_total: INTEGER; a_scope: BIB_SEARCH_SCOPE)
			-- The heading over `verses_grid' for `a_total' verses found in `a_scope'.
		local
			l_note: STRING_32
		do
			create l_note.make_empty
			if bible.verse_search.has_moved_hebrew_roots and a_total > 0 then
				l_note := {STRING_32} " Hebrew roots are shown at their English verse numbers (versification by STEPBible.org TVTMS, CC BY)."
			end
				-- Design scan 53: both notes can apply; neither hides the other.
			if bible.verse_search.has_hebrew_roots and a_total > 0 then
				l_note.append ({STRING_32} " Hebrew roots stand in Hebrew verse numbers; a few English Bibles number those verses one off.")
			end
			if bible.verse_search.has_greek_roots and a_total > 0 then
					-- The Colossians 1:2 lesson: the KJV reads "Lord" where the critical text has none.
				l_note.append ({STRING_32} " Greek roots are read in the Greek New Testament of the concordance (a critical text), whose wording can differ from the Textus Receptus behind the KJV.")
			end
			if not a_scope.label.same_string ({BIB_SCOPE_NAMES}.Whole_bible_name) then
				l_note.prepend ({STRING_32} " Searched in " + a_scope.label + {STRING_32} " only.")
			end
			if a_total = 0 then
				verses_heading.set_text ({STRING_32} "No verse in " + reading_version.to_string_32 + {STRING_32} " matches." + l_note)
			elseif a_total > verse_hits.count then
				verses_heading.set_text ({STRING_32} "Verses in " + reading_version.to_string_32 + {STRING_32} ": " + a_total.out + {STRING_32} " match; the first " + verse_hits.count.out + {STRING_32} " in Bible order. Click one to read it." + l_note)
			elseif a_total = 1 then
				verses_heading.set_text ({STRING_32} "Verses in " + reading_version.to_string_32 + {STRING_32} ": 1 verse matches. Click it to read it." + l_note)
			else
				verses_heading.set_text ({STRING_32} "Verses in " + reading_version.to_string_32 + {STRING_32} ": " + a_total.out + {STRING_32} " match, in Bible order. Click one to read it." + l_note)
			end
		end

	clear_verse_hits
			-- No verses listed (a reference or a clicked word filled P07).
		do
			create verse_hits.make (0)
			verses_grid.set_rows (verse_hits)
			verses_heading.set_text ("")
		end

	on_verse_hit (a_row: INTEGER)
			-- A verse clicked: read it.
		do
			if a_row >= 1 and a_row <= verse_hits.count then
				go_to (verse_hits.i_th (a_row).book_id, verse_hits.i_th (a_row).chapter, verse_hits.i_th (a_row).verse)
			end
		end

	hit_place (a_verse: BIB_READING_VERSE): STRING_32
			-- "John 1:14".
		do
			Result := place_text (a_verse.book_id, a_verse.chapter, a_verse.verse)
		end

	show_results
			-- New results listed: the state learns them (and shows the panel, `apply_results'); in
			-- Study, Search Results to the front of T6.
		do
			results_state.set_found (choices.count, verse_hits.count)
			if is_study then
				results_tabs.select_tab (1)
			end
		end

	hide_results
			-- Nothing to list in P07 for this search (a word opened in the lexicon instead).
		do
			results_state.set_found (choices.count, verse_hits.count)
			results_state.close
		end

	close_results
			-- The Close button. Simple: the panel put away (the results stay, for Window > Search
			-- results). Study: the results emptied, since the T6 zone also holds the Author Library
			-- and the guides (risk 5: Close did nothing there).
		do
			if is_study then
				create choices.make (0)
				results_grid.set_rows (choices)
				results_note.set_text ("")
				clear_verse_hits
				results_state.clear
			else
				results_state.close
			end
		end

	reopen_results
			-- Window > Search results.
		do
			results_state.reopen
			if is_study then
				results_tabs.select_tab (1)
			end
		end

	results_state: BIB_RESULTS_STATE
			-- What the results panel lists and whether the reader closed it (research/23 phase 4).
		attribute
			create Result.make
		end

	apply_results
			-- The panel and its dot as the results state says: in Simple shown while the results are
			-- wanted (P07 docks west, an empty zone takes no room, C16); in Study the T6 zone stays.
			-- The dot: results the reader has not closed (risk 6: it stayed after Close).
		do
			dock.set_panel_marked (results_panel, results_state.is_wanted)
			if not is_study then
				if results_state.is_wanted then
					dock.show_panel (results_panel)
				else
					dock.hide_panel (results_panel)
				end
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
				if reading_verses.i_th (i).verse = reading_verse and reading.has_verse then
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
		end

	window_title: STRING_32
			-- C1: the app, the chapter and version read, and the edition the pack names (FR-157).
		do
			Result := {STRING_32} "simple_bible " + {BIB_RELEASE}.Program_version
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
			window.add_reference_mark (scope_select, "C6.1", "Search scope: the whole Bible, the Old or New Testament, the Gospels, Paul's letters, or the book being read. Changing it searches again.", window.Corner_top_right)
			window.add_reference_mark (version_select, "C5", "Version picker: every version content.db holds. The text changes; the place stays.", window.Corner_top_right)
			window.add_reference_mark (ask_box, "C6.5", "Ask: a request in plain words, read by the Cactus Needle helper on this machine (no internet). Its answer is checked against what you typed, then run here: a passage, its commentary, a word study, a search. Anything it cannot answer safely goes to the search box.", window.Corner_top_left)
			window.add_reference_mark (search_box, "C6", "Quick search: a word, verse or Strong's number, and every verse it names: words, %"phrases%", word*, AND, OR and NOT in capitals, parentheses, strongs:H1254 or G5485, lemma:charis, morph:V-AAI-3S or morph:Vq*, and a root in a form on one word: G3056@N-NSM. Results open the results zone. Ctrl+F.", window.Corner_top_left)
			window.add_reference_mark (smaller_button, "C8", {STRING_32} "Text size: all the window's text, " + (settings.Min_text_scale * 100.0).rounded.out + {STRING_32} " to "
				+ (settings.Max_text_scale * 100.0).rounded.out + {STRING_32} " percent, kept for next time. Ctrl + and -.", window.Corner_top_left)
			window.add_reference_mark (dark_switch, "C9", "Dark / Light: your choice; until you switch, Windows decides.", window.Corner_top_right)
			window.add_reference_mark (link_label, "C12", "Link set: always A for now.", window.Corner_top_left)
			window.add_reference_mark (numbering_label, "C13", "Versification: which numbering the version uses.", window.Corner_top_left)
			window.add_reference_mark (progress, "C14", "Job progress: a long every-place list loading.", window.Corner_top_left)
			window.add_reference_mark (editions_label, "C15", "Database editions: which data files are loaded.", window.Corner_top_right)
			window.add_reference_mark (status_bar, "C11", "Status: the reference and version read.", window.Corner_top_left)
			window.add_reference_mark (focus_button, "S1.1", "Focus reading: fold every side so the Bible text has the window; again (or Ctrl+Shift+F) brings them back. A folded side is a strip naming its panes, a dot where one has something for the verse read; click a name to open it.", window.Corner_top_right)
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
			window.add_reference_mark (commentary_title, "S2", "P04 Commentary, east: follows the verse. Commentaries from the commentary packs (every claim labelled SOURCED or DEDUCED); Cross-refs (OpenBible votes); Incipit (the Old Testament in the New, both ways); Chiasm (Bullinger's structures around the verse, graded against chance).", window.Corner_top_left)
			window.add_reference_mark (lexicon_heading, "S3", "P05 Lexicon, south: follows the word. Renderings first, then lexicon entries.", window.Corner_top_left)
			window.add_reference_mark (renderings_grid, "P05.4", "Range before ruling: every rendering with its count, before any lexicon's verdict.", window.Corner_top_left)
			window.add_reference_mark (entries_list, "P05.5", "Lexicon entries: each source in its own words (Abbott-Smith, BDB, LSJ, UBS, TBESH).", window.Corner_top_left)
			window.add_reference_mark (search_word_button, "P05.7", "Actions: Every place of this word; Word Study comes later.", window.Corner_top_left)
			window.add_reference_mark (verses_heading, "P07.2", "Verses of the version read that the search names, in Bible order with their count; click one to read it. Words, %"phrases%", word*, AND, OR and NOT in capitals (NOT takes away from what stands beside it), parentheses, root words (strongs:H1254 or G5485, lemma:charis) and grammar (morph:V-AAI-3S Greek, morph:Vqp3ms Hebrew, written as the corpora write them, letter case included; morph:V* for every code it begins, Greek and Hebrew alike). AND joins verses, not words: G3056 AND morph:N-NSM finds verses holding both; G3056@N-NSM finds the word itself in that form.", window.Corner_top_left)
			window.add_reference_mark (results_note, "P07", "Search results: the dictionary words matching the search, then (P07.2) the verses holding it. Docked west only while there are results (Simple); Close collapses it.", window.Corner_top_left)
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

	Key_y: INTEGER = 0x59

	Key_z: INTEGER = 0x5A
	Key_l: INTEGER = 0x4C
	Key_f: INTEGER = 0x46
			-- Ctrl+F search, Ctrl+Shift+F Focus reading.
	Key_m: INTEGER = 0x4D
	Key_i: INTEGER = 0x49
	Key_d: INTEGER = 0x44
	Key_left: INTEGER = 0x25
	Key_right: INTEGER = 0x27
	Key_plus: INTEGER = 0xBB
	Key_minus: INTEGER = 0xBD
			-- Virtual keys for the accelerators.

	All_at_once: INTEGER_64 = 10000
			-- Up to this many places load before the word shows; longer lists stream on the tick.

	Pages_per_tick: INTEGER = 15
			-- Pages a tick loads (about 3,000 places, a few milliseconds each page).


invariant
	hold_is_a_place: is_commentary_held implies (held_book > 0 and held_chapter > 0 and held_verse >= 0)

end
