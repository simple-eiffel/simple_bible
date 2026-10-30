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
			create highlights_heading.make_ui ("")
			create highlight_reason_label.make_ui ("")
			create highlight_reason_box.make_single_line ("")
			create highlight_button.make ("Highlight", Void)
			create highlights_grid.make (100.0)
			create navigator_tabs.make
			create bookmarks_heading.make_ui ("")
			create bookmarks_grid.make (100.0)
			create history_grid.make (100.0)
			create history_heading.make_ui ("")
			create history_rows.make (0)
			create tag_label.make_ui ("")
			create journal_title_box.make_single_line ("")
			create prayer_title_box.make_single_line ("")
			create prayer_body_box.make ("")
			create prayer_answer_box.make_single_line ("")
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
			create reading_version.make_empty
			create commentary_title.make ("", {SW_PAINTER}.Role_ui, 13.0, True)
			create commentary_tabs.make
			create commentary_view.make (200.0)
			create commentary_reader.make
			create cross_refs_grid.make (60.0)
			create books_grid.make (60.0)
			create book_rows.make (0)
			create chapters_grid.make (60.0)
			create chapter_rows.make (0)
			create book_view.make (200.0)
			create in_books_grid.make (60.0)
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
				-- The item panels get agents on Current once both exist and every attribute is set (VEVI).
			create highlights_panel.make (user_store, {BIB_USER_STORE}.Kind_highlight, highlights_grid, "Highlight")
			create bookmarks_panel.make (user_store, {BIB_USER_STORE}.Kind_bookmark, bookmarks_grid, "Bookmark")
			create tagged_panel.make (user_store, {BIB_USER_STORE}.Kind_tag, tagged_grid, "Tag")
			create prayer_open_panel.make (user_store, {BIB_USER_STORE}.Kind_prayer, prayer_open_grid, "Prayer")
			create prayer_answered_panel.make (user_store, {BIB_USER_STORE}.Kind_prayer, prayer_answered_grid, "Prayer")
			create memory_panel.make (user_store, {BIB_USER_STORE}.Kind_memory_card, memory_grid, "Card")
			tagged_panel.set_actions (agent say, agent fill_tags, agent go_to_hub)
			highlights_panel.set_actions (agent say, agent reopen_reading, agent go_to_hub)
			bookmarks_panel.set_actions (agent say, agent fill_bookmarks, agent go_to_hub)
			prayer_open_panel.set_actions (agent say, agent fill_prayers, agent read_hub_if_any)
			prayer_answered_panel.set_actions (agent say, agent fill_prayers, agent read_hub_if_any)
			memory_panel.set_actions (agent say, agent fill_memory, agent go_to_hub)
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
				if bible.is_open and then (create {BIB_NOTE_BATCH}.make (bible)).is_pack_stale ((create {BIB_DATA_LOCATION}).notes_folder) then
						-- notes the installer brought (Larry's, for the alpha testers, 2026-10-30), or a pack
						-- an import could not put in place: built again once the window is painted
					pending_notes_rebuild_ticks := 2
					say ("Bringing the notes up to date...")
				end
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
			elseif snapshot_tab.same_string ({STRING_32} "notesrebuild") then
				rebuild_notes_pack
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
			elseif snapshot_tab.same_string ({STRING_32} "bookmarks") then
				bookmark_verse
				navigator_tabs.select_tab (Bookmarks_tab)
			elseif snapshot_tab.same_string ({STRING_32} "highlights") then
				highlight_reason_box.set_text ("A sample reason written by the snapshot run")
				add_highlight
					-- The next verse read, so the highlighted one shows its own wash, not the selection's.
				go_to (reading_book, reading_chapter, reading_verse + 1)
				if attached notes_tabs as al_tabs then
					al_tabs.select_tab (Highlights_tab)
				end
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
			search_word_button.set_on_click (agent show_every_place)
			results_grid.set_on_select (agent on_choice)
			verses_grid.set_on_select (agent on_verse_hit)
			close_results_button.set_on_click (agent hide_results)
			places_grid.set_on_select (agent on_place)
			window.set_on_tick (agent on_window_tick)
			focus_button.set_on_click (agent toggle_focus_reading)
			origin_button.set_on_click (agent back_to_commentary_verse)
			back_to_writings_button.set_on_click (agent back_to_writings)
			commentary_view.set_hover_card_builder (agent link_card (commentary_view, ?, ?))
			framework_view.set_hover_card_builder (agent link_card (framework_view, ?, ?))
			framework_view.set_on_link_click (agent on_commentary_link)
			framework_view.set_menu_extension (agent pane_menu (lexicon_panel, ?, ?, ?))
			frameworks_grid.set_on_select (agent on_framework_row)
			books_grid.set_on_select (agent on_book_row)
			chapters_grid.set_on_select (agent on_chapter_row)
			in_books_grid.set_on_select (agent on_in_books_row)
			writings_grid.set_on_select (agent on_writing_row)
			book_view.set_on_link_click (agent on_commentary_link)
			book_view.set_hover_card_builder (agent link_card (book_view, ?, ?))
			book_view.set_menu_extension (agent pane_menu (results_panel, ?, ?, ?))
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
			verses_grid.add_column (create {SW_GRID_COLUMN [BIB_READING_VERSE]}.make ("Verse", 110.0, agent hit_place))
			verses_grid.add_column ((create {SW_GRID_COLUMN [BIB_READING_VERSE]}.make ("Text", 400.0, agent {BIB_READING_VERSE}.display_text)).growing)
			cross_refs_grid.add_column ((create {SW_GRID_COLUMN [BIB_READING_CROSS_REF]}.make ("Reference", 180.0, agent cross_ref_text)).growing)
			highlights_grid.add_column (create {SW_GRID_COLUMN [BIB_HIGHLIGHT]}.make ("Verse", 120.0, agent item_place ({BIB_HIGHLIGHT} ?)))
			bookmarks_grid.add_column ((create {SW_GRID_COLUMN [BIB_BOOKMARK]}.make ("Verse", 140.0, agent item_place ({BIB_BOOKMARK} ?))).growing)
			history_grid.add_column ((create {SW_GRID_COLUMN [BIB_VISIT]}.make ("Place", 120.0, agent item_place ({BIB_VISIT} ?))).growing)
			history_grid.add_column (create {SW_GRID_COLUMN [BIB_VISIT]}.make ("When", 120.0, agent visit_when))
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
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Rendering", 150.0, agent {BIB_ENGLISH_GLANCE_ROW}.english))
			renderings_grid.add_column ((create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Version", 200.0, agent version_name)).growing)
			renderings_grid.add_column (create {SW_GRID_COLUMN [BIB_ENGLISH_GLANCE_ROW]}.make ("Count", 70.0, agent count_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Place", 150.0, agent {BIB_PLACE_ROW}.reference_text))
			places_grid.add_column (create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Word", 150.0, agent {BIB_PLACE_ROW}.surface))
			places_grid.add_column ((create {SW_GRID_COLUMN [BIB_PLACE_ROW]}.make ("Transliteration", 160.0, agent {BIB_PLACE_ROW}.translit)).growing)
			reading_view.add_column ("").do_nothing
			frameworks_grid.add_column ((create {SW_GRID_COLUMN [BIB_FRAMEWORK]}.make ("Framework", 120.0, agent {BIB_FRAMEWORK}.display_name)).growing)
			books_grid.add_column ((create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Book", 160.0, agent {BIB_AUTHOR_BOOK}.full_title)).growing)
			books_grid.add_column (create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Kind", 70.0, agent library_kind_name))
			books_grid.add_column (create {SW_GRID_COLUMN [BIB_AUTHOR_BOOK]}.make ("Status", 90.0, agent {BIB_AUTHOR_BOOK}.status))
			chapters_grid.add_column ((create {SW_GRID_COLUMN [TUPLE [chapter: INTEGER; title, kind: STRING_32]]}.make ("Chapter", 200.0, agent chapter_row_title)).growing)
			in_books_grid.add_column (create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Book", 120.0, agent {BIB_BOOK_BLOCK}.book_title))
			in_books_grid.add_column (create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Chapter", 140.0, agent {BIB_BOOK_BLOCK}.chapter_title))
			in_books_grid.add_column ((create {SW_GRID_COLUMN [BIB_BOOK_BLOCK]}.make ("Text", 300.0, agent block_snippet)).growing)
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
			window.register_accelerator (Key_left, False, True, False, agent move_in_history (-1))
			window.register_accelerator (Key_right, False, True, False, agent move_in_history (1))
			window.register_accelerator (Key_l, True, False, False, agent focus_reference)
			window.register_accelerator (Key_f, True, False, False, agent focus_search)
			window.register_accelerator (Key_plus, True, False, False, agent change_text_size (1))
			window.register_accelerator (Key_minus, True, False, False, agent change_text_size (-1))
			window.register_accelerator (Key_m, True, False, False, agent toggle_mode)
			window.register_accelerator (Key_i, True, False, False, agent show_interlinear)
			window.register_accelerator (Key_d, True, False, False, agent bookmark_verse)
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
			if is_commentary_held then
				Result.add_item ({STRING_32} "Back to " + place_text (held_book, held_chapter, held_verse), "", True, agent back_to_commentary_verse)
			end
			Result.add_separator
			Result.add_item ("Bookmark this verse", "Ctrl+D", reading_verse > 0, agent bookmark_verse)
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
			window.toast ({STRING_32} "simple_bible " + {BIB_RELEASE}.Program_version + {STRING_32} " (engine " + {BIB_RELEASE}.Engine_version + {STRING_32} ").  " + status_text + {STRING_32} "  |  " + ask_status, 1)
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

	mark_selected_verse (a_view: SW_PARALLEL_TEXT; a_row, a_column: INTEGER; a_text: READABLE_STRING_32; a_highlighted: BOOLEAN)
			-- Mark the selected verse's text `a_text' in cell `a_row', `a_column' of `a_view': the one
			-- mark the Bible and Parallel tabs both use (scan 36). Washed blue; outlined instead when
			-- the verse is `a_highlighted', so its amber wash still shows (scan 42).
		local
			l_mark: SW_MARK
		do
			if not a_text.is_empty then
				create l_mark.make ({SW_MARK}.Hue_blue)
				if a_highlighted then
					a_view.cell_marks (a_row, a_column).mark_range_with (0, a_text.count, "selected verse", l_mark).do_nothing
				else
					a_view.cell_marks (a_row, a_column).mark_range_with (0, a_text.count, "selected verse", l_mark.with_wash).do_nothing
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
			-- Edit > Copy verse: the selected verse with its reference (scan 56: `copy_hub_verse', the
			-- one verse copier).
		do
			if reading_verse > 0 then
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
			if not is_following_commentary then
					-- Anything but a commentary link: the commentary follows the Bible text again.
				release_commentary
			end
			from until history.count <= history_index loop
				history.finish
				history.remove
			end
			history.extend ([a_book, a_chapter, a_verse])
			history_index := history.count
			record_place (a_book, a_chapter, a_verse)
			open_reading (a_book, a_chapter, a_verse)
		end

	move_in_history (a_step: INTEGER)
			-- C3: Back (-1) or Forward (1).
		do
			if history_index + a_step >= 1 and history_index + a_step <= history.count then
				release_commentary
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
			l_reasons: HASH_TABLE [STRING_32, INTEGER]
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
				l_reasons := chapter_highlight_reasons (a_book, a_chapter)
				across reading_verses as ic loop
					l_row := reading_view.add_row (ic.verse.out)
					reading_view.set_cell (l_row, 1, ic.display_text)
					if attached l_reasons.item (ic.verse) as al_reason then
						mark_highlighted_verse (reading_view, l_row, 1, ic.display_text, al_reason)
					end
					if ic.verse = a_verse then
						l_selected_row := l_row
						mark_selected_verse (reading_view, l_row, 1, ic.display_text, l_reasons.has (ic.verse))
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
				next_button.set_enabled (a_chapter < bible.text_reader.last_chapter (reading_version, a_book) or a_book < {BIB_CANON}.Last_book)
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
					fill_highlights
					fill_bookmarks
					fill_tags
					fill_journal
					fill_history
					fill_prayers
					fill_memory
				end
				refresh_strip_marks
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
			results_tabs.add_page ("Author Library", books_page)
			results_tabs.add_page ("Writings", writings_page)
			results_tabs.add_page ("Study Ledger v1.5", create {SW_EMPTY_STATE}.make ("Study ledger is version 1.5", "Planned for version 1.5."))

			tools_strip.add_tool ("Parallel", "Versions side by side (P02)", True, agent show_parallel)
			tools_strip.add_tool ("Interlinear", "Word by word in the original (P03). Ctrl+I", True, agent show_interlinear)
			tools_strip.add_tool ("Guide", "A guide on one subject (P08): comes later", False, Void)
			tools_strip.add_tool ("Word Study", "The word study (P05 Word Study): comes later", False, Void)
			tools_strip.add_tool ("Count", "Census and checks (P09): comes later", False, Void)
			tools_strip.add_tool ("Ledger v1.5", "The study ledger, version 1.5", False, Void)
		end

	navigator_pane: SW_COLUMN
			-- T1, P11 Navigator: the books, testament by testament, chapter by chapter; and the
			-- bookmarks.
		local
			l_roots: ARRAYED_LIST [BIB_NAV_NODE]
			l_books, l_marks, l_history: SW_COLUMN
			l_buttons: SW_ROW
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
			l_marks.put (bookmarks_heading)
			l_marks.put (bookmarks_grid.growing)
			create l_buttons.make
			l_buttons.put (bookmarks_panel.remove_button)
			l_buttons.put (bookmarks_panel.restore_button)
			l_marks.put (l_buttons)
			navigator_tabs.add_page ("Books", l_books)
			navigator_tabs.add_page ("Bookmarks", l_marks)
			create l_history.make
			l_history := l_history.with_gap (6.0)
			l_history.put (history_heading)
			l_history.put (history_grid.growing)
			navigator_tabs.add_page ("History", l_history)
			create Result.make
			Result.put (navigator_tabs.growing)
		end

	navigator_tabs: SW_TABS
	bookmarks_heading: SW_LABEL
	bookmarks_grid: SW_DATA_GRID [BIB_BOOKMARK]
			-- T1's Books and Bookmarks tabs (2026-10-27).

	bookmarks_panel: BIB_ITEM_LIST_PANEL [BIB_BOOKMARK]
			-- The bookmarks list, newest first, with Remove and Restore.

	Bookmarks_tab: INTEGER = 2
			-- T1's Bookmarks page.

	fill_bookmarks
			-- Every bookmark, newest first (a click opens its verse).
		do
			if user_store.is_open then
				bookmarks_panel.set_rows (user_store.bookmarks)
			else
				bookmarks_panel.set_rows (create {ARRAYED_LIST [BIB_BOOKMARK]}.make (0))
			end
			if bookmarks_panel.rows.is_empty then
				bookmarks_heading.set_text ("No bookmarks yet: Ctrl+D bookmarks the verse read.")
			else
				bookmarks_heading.set_text ({STRING_32} "Your bookmarks (" + bookmarks_panel.rows.count.out + {STRING_32} "), newest first. Ctrl+D adds the verse read.")
			end
		end

	bookmark_verse
			-- Ctrl+D: the verse read is bookmarked.
		do
			if reading_verse = 0 then
				window.toast ("Click a verse to bookmark it.", 1)
			elseif user_store.is_open then
				user_store.add_bookmark (create {BIB_BOOKMARK}.make (reading_hub, place_text (reading_book, reading_chapter, reading_verse)))
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					fill_bookmarks
					window.toast ({STRING_32} "Bookmarked " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} ".", 1)
				end
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

	History_length: INTEGER = 50
			-- How many chapters History lists.

	history_heading: SW_LABEL
	history_grid: SW_DATA_GRID [BIB_VISIT]
			-- T1's History tab (2026-10-27): the chapters read, newest first, kept in user.db.

	history_rows: ARRAYED_LIST [BIB_VISIT]
			-- The rows of `history_grid'.

	last_recorded_hub: INTEGER_64
			-- The place History recorded last this run (0: none yet).

	record_place (a_book, a_chapter, a_verse: INTEGER)
			-- `go_to' adds the place to History when its chapter is not the one recorded last (a verse
			-- clicked in the same chapter is no new visit). Scan 46: Back and Forward no longer
			-- reorder History, and a failed write is told once, not retried silently at each open.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_not_negative: a_verse >= 0
		local
			l_hub: INTEGER_64
		do
			if user_store.is_open then
				l_hub := (create {BIB_HUB_ID}).hub_id (a_book, a_chapter, a_verse.max (1))
				if l_hub // {BIB_HUB_ID}.Chapter_unit /= last_recorded_hub // {BIB_HUB_ID}.Chapter_unit then
					last_recorded_hub := l_hub
					user_store.record_visit (create {BIB_VISIT}.make (l_hub, "reading"))
					if attached user_store.write_error as al_error then
						say ({STRING_32} "History was not saved: " + al_error.message)
					end
				end
			end
		end

	fill_history
			-- The chapters read, newest first; the chapter read stays selected.
		local
			i, l_index: INTEGER
			l_hub: BIB_HUB_ID
			l_place: INTEGER_64
		do
			if user_store.is_open then
				history_rows := user_store.recent_places (History_length)
			else
				create history_rows.make (0)
			end
			history_grid.set_rows (history_rows)
			create l_hub
			from i := 1 until i > history_rows.count or l_index > 0 loop
				l_place := history_rows.i_th (i).hub_id
				if l_hub.is_valid_hub (l_place) and then l_hub.book_of (l_place) = reading_book and then l_hub.chapter_of (l_place) = reading_chapter then
					l_index := i
				end
				i := i + 1
			end
			reselect (history_grid, l_index)
			if history_rows.is_empty then
				history_heading.set_text ("No history yet: the chapters you read are listed here.")
			else
				history_heading.set_text ({STRING_32} "The last " + History_length.out + {STRING_32} " chapters you read, newest first; click one to read it again.")
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
				say ("Write the note in the box first.")
			elseif user_store.is_open and reading_verse > 0 and note_store.is_writable then
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
			prayer_answered_button.set_enabled (not prayer_open_rows.is_empty)
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
			memory_add_button.set_enabled (user_store.is_open and reading_verse > 0)
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
			if reading_verse = 0 then
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
			a_verse_read: reading_book > 0 and reading_chapter > 0 and reading_verse > 0
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
			if reading_verse > 0 then
				tag_label.set_text ({STRING_32} "Tag " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} ":")
			else
				tag_label.set_text ("Click a verse to tag it.")
			end
			tag_button.set_enabled (user_store.is_open and reading_verse > 0)
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
			elseif user_store.is_open and reading_verse > 0 then
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
			if reading_verse > 0 then
				highlight_reason_label.set_text ({STRING_32} "Why highlight " + place_text (reading_book, reading_chapter, reading_verse) + {STRING_32} "?")
			else
				highlight_reason_label.set_text ("Click a verse to highlight it.")
			end
			highlight_button.set_enabled (user_store.is_open and reading_verse > 0)
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
			elseif user_store.is_open and reading_verse > 0 then
				user_store.add_highlight (create {BIB_HIGHLIGHT}.make (reading_hub, l_reason))
				if attached user_store.write_error as al_error then
					say (al_error.message)
				else
					highlight_reason_box.set_text ("")
					open_reading (reading_book, reading_chapter, reading_verse)
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
			-- Read the place read again (a highlight changed its washes).
		do
			if reading_book > 0 and reading_chapter > 0 then
				open_reading (reading_book, reading_chapter, reading_verse)
			end
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
			if reading_verse > 0 then
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
				arrange (True)
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
			l_row, l_selected, i, c: INTEGER
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
							if ic.verse = reading_verse then
								mark_selected_verse (parallel_view, l_row, c, al_cell, l_reasons.has (ic.verse))
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
			window.add_reference_mark (tools_strip, "C10", "Study tools strip: Parallel and Interlinear work; Guide, Word Study, Count and Ledger come later.", window.Corner_top_left)
			window.add_reference_mark (mode_switch, "C7", "Mode switch, on Study: only the docking changes. Ctrl+M.", window.Corner_top_left)
			window.add_reference_mark (navigator_tabs, "T1", "P11 Navigator, west: Books (chapter by chapter), Bookmarks (Ctrl+D bookmarks the verse read; click one to read it; Remove and Restore) and History (the last 50 chapters read, newest first, kept between runs; click one to read it again).", window.Corner_top_left)
			window.add_reference_mark (notes_heading, "T2", "P06 Notes, west below T1, in tab order: Verse notes on the chapter read (add on the verse read; double-click to edit, each edit keeps the old version; Delete and Restore); Journal, notes on a subject (New; Save keeps the earlier version; Delete and Restore); Tags (tag the verse read; click a tag for its verses, a verse to read it; Remove and Restore); Highlights (a reason, not a color; washed amber in the Bible and Parallel tabs; click one to read it; Remove and Restore); Prayer (a title and the request; Open and Answered, with how it was answered; Remove and Restore); Memory (learn the verse read; recall today's card, Show the verse, grade Again, Hard, Good or Easy; the next date follows SuperMemo 2).", window.Corner_top_left)
			window.add_reference_mark (center_tabs, "T3", "Centre tabs: the Bible text, Parallel (P02) and Interlinear (P03, Ctrl+I). More Bible tabs come later.", window.Corner_top_left)
			window.add_reference_mark (analysis_title, "P03.2", "Verse analysis: the verse read, a row per word with its lemma, Strong's number, morphology, gloss, and how often its headword occurs in this testament. Click a row and T4 follows it.", window.Corner_top_left)
			window.add_reference_mark (interlinear_note, "P03", "Interlinear: word by word in the original, right to left for Hebrew. A click makes the word's verse the place read and opens its headword in T4.", window.Corner_top_left)
			window.add_reference_mark (lexicon_heading, "T4", "P05 Lexicon, east: follows the clicked word. Its Frameworks tab (P05.8) explains each FRAMEWORK(TM) for the common reader; a framework named anywhere is a link: rest on it for a summary, click it to open it here.", window.Corner_top_left)
			window.add_reference_mark (commentary_title, "T5", "P04 Commentary, east: Commentaries (Larry's commentary packs, verse by verse, every claim labelled SOURCED or DEDUCED), Cross-refs with OpenBible votes.", window.Corner_top_left)
			window.add_reference_mark (results_tabs, "T6", "South results zone: Search Results (word choices, then the verses holding the words; click one to read it); Author Library (Larry's books); Writings (the search box with My writings as its scope); Guides, Census and Ledger come later.", window.Corner_top_left)
			window.add_reference_mark (writings_grid, "T6.5", "Writings: what the search box found in your commentary, frameworks and books (scope My writings; My writings (fuzzy) forgives a misspelt word). Click one to open it.", window.Corner_top_right)
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
			commentary_view.set_menu_extension (agent pane_menu (commentary_panel, ?, ?, ?))
			entries_list.set_menu_extension (agent pane_menu (lexicon_panel, ?, ?, ?))
			notes_list.set_menu_extension (agent notes_menu)
			cross_refs_grid.set_menu_extension (agent cross_ref_menu)
			results_grid.set_menu_extension (agent choice_menu)
			verses_grid.set_menu_extension (agent verse_hit_menu)
			places_grid.set_menu_extension (agent place_menu)
			renderings_grid.set_menu_extension (agent rendering_menu)
			history_grid.set_menu_extension (agent history_menu)
			journal_grid.set_menu_extension (agent journal_menu)
			tag_names_grid.set_menu_extension (agent tag_name_menu)
			bookmarks_panel.set_menu_items (agent listed_menu_items)
			highlights_panel.set_menu_items (agent listed_menu_items)
			tagged_panel.set_menu_items (agent listed_menu_items)
			prayer_open_panel.set_menu_items (agent listed_menu_items)
			prayer_answered_panel.set_menu_items (agent listed_menu_items)
			memory_panel.set_menu_items (agent listed_menu_items)
		end

	verse_menu (a_view: SW_PARALLEL_TEXT; a_menu: SW_MENU; a_px, a_py: REAL_64)
			-- A verse in the Bible or Parallel tab: copy it with its reference or the chapter; keep it
			-- (bookmark, highlight, note, tag, card, prayer); open it in the other tabs; Focus reading.
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
				a_menu.add_item ("Bookmark", "Ctrl+D", user_store.is_open, agent on_verse_do (l_verse, agent bookmark_verse))
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
				arrange (True)
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
			if reading_verse > 0 then
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
			if reading_verse > 0 then
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
				if reading_verse > 0 then
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
			dock.set_panel_marked (results_panel, not choices.is_empty or not verse_hits.is_empty)
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
	chapters_grid: SW_DATA_GRID [TUPLE [chapter: INTEGER; title, kind: STRING_32]]
	chapter_rows: ARRAYED_LIST [TUPLE [chapter: INTEGER; title, kind: STRING_32]]
	book_view: SW_DOCUMENT_VIEW
			-- T6's Author Library: the books, the chosen book's chapters, the chapter read.

	listed_book: STRING_32
			-- The book (or essay series) whose chapters are listed; empty for none.

	listed_kind: STRING_32
			-- Its pack's kind: "books" or "essays"; empty for none.

	in_books_grid: SW_DATA_GRID [BIB_BOOK_BLOCK]
	in_books_rows: ARRAYED_LIST [BIB_BOOK_BLOCK]
			-- T5's In the books: the paragraphs citing the commentary's verse.

	In_books_tab: INTEGER = 3
			-- T5's In the books page.

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
			-- The attached text packs, books then essays (2026-10-28): the Author Library's.
		do
			create Result.make (2)
			if bible.is_open then
				across bible.text_packs as ic loop
					if ic.is_available then
						Result.extend (ic)
					end
				end
			end
		end

	library_pack (a_kind: READABLE_STRING_GENERAL): detachable BIB_BOOK_PACK
			-- The attached pack of kind `a_kind' ("books", "essays"); Void when none is.
		do
			across library_packs as ic loop
				if Result = Void and then ic.schema.Pack_kind.same_string_general (a_kind) then
					Result := ic
				end
			end
		ensure
			of_kind: attached Result as r implies r.schema.Pack_kind.same_string_general (a_kind)
		end

	fill_books
			-- The books, then the essay series, or the page saying there is no pack yet.
		do
			create book_rows.make (0)
			across library_packs as ic loop
				if attached ic.books as al_result and then al_result.is_success then
					across 1 |..| al_result.count as al_i loop
						book_rows.extend (al_result.item (al_i))
					end
				end
			end
			if book_rows.is_empty then
				book_view.set_document (commentary_reader.read ({STRING_32} "**No books or essays pack yet**%N%NA books or essays pack in the packs folder brings Larry's writing here, chapter by chapter."))
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

	chapter_row_title (a_row: TUPLE [chapter: INTEGER; title, kind: STRING_32]): STRING_32
			-- A chapter's title as listed.
		do
			Result := a_row.title
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
			bring_into_view (results_panel, results_tabs, Author_library_tab)
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
				if a_block > 0 then
						-- one document block per book block, after the book's title
					window.request_render
					book_view.scroll_to (book_view.stacked_scroll_for ((a_block + 1).min (book_view.document.count)))
				end
			else
				book_view.set_document (commentary_reader.read ({STRING_32} "No " + a_book.to_string_32 + {STRING_32} " in the " + a_kind.to_string_32 + {STRING_32} " pack."))
			end
			window.request_render
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
			-- The prepared file `a_path' checked (its source beside it, when there, for the length check);
			-- refused with its report in the Author Library, or kept: its files written, the notes pack
			-- rebuilt, the engine reopened on it, the note shown.
		local
			l_importer: BIB_NOTE_IMPORTER
			l_file, l_source: SIMPLE_FILE
			l_text, l_folder, l_packs, l_new, l_pack: STRING_32
			l_error: detachable STRING_32
			l_ok: BOOLEAN
		do
			create l_file.make (a_path)
			if bible.is_open and then l_file.is_file then
				l_text := l_file.read_text_utf_8
				create l_importer.make (bible)
				l_importer.read (l_text, Void)
				if not l_importer.source.is_empty then
					create l_source.make (l_file.parent_path + {STRING_32} "\" + l_importer.source)
					if l_source.is_file then
						l_importer.read (l_text, l_source.read_text_utf_8)
					end
				end
				if not l_importer.is_accepted then
					show_import_report ({STRING_32} "Import refused", l_importer.problems, l_importer.warnings)
				else
					l_folder := (create {BIB_DATA_LOCATION}).notes_folder.to_string_32
					l_packs := (create {BIB_DATA_LOCATION}).pack_folder.to_string_32
					l_pack := l_packs + {STRING_32} "\" + {BIB_NOTE_SCHEMA}.Pack_file_name
					l_new := l_pack + {STRING_32} ".new"
					if (create {SIMPLE_FILE}.make (l_new)).is_file then
						l_ok := (create {SIMPLE_FILE}.make (l_new)).delete
					end
					l_error := l_importer.keep (l_folder, l_new, l_packs + {STRING_32} "\" + {BIB_FRAMEWORK_SCHEMA}.Pack_file_name)
					if attached l_error as al_error then
						show_import_report ({STRING_32} "The note could not be kept", create {ARRAYED_LIST [STRING_32]}.make_from_array (<<al_error>>), l_importer.warnings)
					elseif attached swapped_notes_pack (l_pack, l_new) as al_swap_error then
							-- scan 70: the note is kept as files; the next import builds the pack again
						(create {BIB_NOTE_BATCH}.make (bible)).set_pack_stale (l_folder, True)
						show_import_report ({STRING_32} "The new notes pack could not be put in place", create {ARRAYED_LIST [STRING_32]}.make_from_array (<<al_swap_error>>), l_importer.warnings)
					else
						(create {BIB_NOTE_BATCH}.make (bible)).set_pack_stale (l_folder, False)
						framework_names_cache := Void
						writing_names_cache := Void
						create listed_book.make_empty
						create listed_kind.make_empty
						fill_books
						show_book_place ({BIB_NOTE_SCHEMA}.Pack_kind, l_importer.id, 1, 0)
						say ({STRING_32} "Imported " + l_importer.title + {STRING_32} ": " + l_importer.built_blocks.out.to_string_32 + {STRING_32} " paragraphs, "
							+ l_importer.built_suggestions.out.to_string_32 + (if l_importer.built_suggestions = 1 then {STRING_32} " suggested passage." else {STRING_32} " suggested passages." end)
							+ (if l_importer.warnings.is_empty then {STRING_32} "" else {STRING_32} " Note: " + l_importer.warnings.first end))
					end
				end
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
			-- Every prepared file in `a_folder' checked; the new and changed kept, the notes pack built once
			-- and put in place, the engine reopened on it; what happened shown in the Author Library.
		local
			l_batch: BIB_NOTE_BATCH
			l_folder, l_packs, l_pack, l_new: STRING_32
			l_swap_error: detachable STRING_32
			l_ok: BOOLEAN
		do
			if bible.is_open then
				l_folder := (create {BIB_DATA_LOCATION}).notes_folder.to_string_32
				l_packs := (create {BIB_DATA_LOCATION}).pack_folder.to_string_32
				l_pack := l_packs + {STRING_32} "\" + {BIB_NOTE_SCHEMA}.Pack_file_name
				l_new := l_pack + {STRING_32} ".new"
				if (create {SIMPLE_FILE}.make (l_new)).is_file then
					l_ok := (create {SIMPLE_FILE}.make (l_new)).delete
				end
				create l_batch.make (bible)
				l_batch.run (a_folder, l_folder, l_new, l_packs + {STRING_32} "\" + {BIB_FRAMEWORK_SCHEMA}.Pack_file_name)
				if l_batch.is_built then
					l_swap_error := swapped_notes_pack (l_pack, l_new)
						-- scan 70: a pack not put in place is built again by the next import
					l_batch.set_pack_stale (l_folder, l_swap_error /= Void)
					if l_swap_error = Void then
						framework_names_cache := Void
						writing_names_cache := Void
						create listed_book.make_empty
						create listed_kind.make_empty
						fill_books
					end
				end
				show_folder_report (a_folder, l_batch, l_swap_error)
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

	rebuild_notes_pack
			-- The notes pack built again from every note in the notes folder and put in place, the stale
			-- mark cleared (2026-10-30: notes the installer brought; a pack an import could not put in
			-- place). A folder with no notes only loses the mark.
		local
			l_importer: BIB_NOTE_IMPORTER
			l_batch: BIB_NOTE_BATCH
			l_folder, l_packs, l_pack, l_new: STRING_32
			l_error: detachable STRING_32
			l_ok: BOOLEAN
		do
			if bible.is_open then
				l_folder := (create {BIB_DATA_LOCATION}).notes_folder.to_string_32
				l_packs := (create {BIB_DATA_LOCATION}).pack_folder.to_string_32
				l_pack := l_packs + {STRING_32} "\" + {BIB_NOTE_SCHEMA}.Pack_file_name
				l_new := l_pack + {STRING_32} ".new"
				create l_batch.make (bible)
				if not (create {SIMPLE_FILE}.make (l_folder)).is_directory or else (create {SIMPLE_FILE}.make (l_folder)).files_with_extension (".json").is_empty then
					l_batch.set_pack_stale (l_folder, False)
				else
					if (create {SIMPLE_FILE}.make (l_new)).is_file then
						l_ok := (create {SIMPLE_FILE}.make (l_new)).delete
					end
					create l_importer.make (bible)
					l_error := l_importer.build (l_folder, l_new, l_packs + {STRING_32} "\" + {BIB_FRAMEWORK_SCHEMA}.Pack_file_name)
					if l_error = Void then
						l_error := swapped_notes_pack (l_pack, l_new)
					end
					l_batch.set_pack_stale (l_folder, l_error /= Void)
					if attached l_error as al_error then
						say ({STRING_32} "The notes could not be brought up to date: " + al_error)
					else
						framework_names_cache := Void
						writing_names_cache := Void
						create listed_book.make_empty
						create listed_kind.make_empty
						fill_books
						say ({STRING_32} "The notes are up to date: " + l_importer.built_blocks.out.to_string_32 + {STRING_32} " paragraphs, "
							+ l_importer.built_suggestions.out.to_string_32 + {STRING_32} " suggested passages.")
					end
				end
			end
		end

	show_folder_report (a_folder: STRING_32; a_batch: BIB_NOTE_BATCH; a_swap_error: detachable STRING_32)
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
			elseif attached a_swap_error as al_swap then
				l_page.append ({STRING_32} "**The notes below are saved, but the new notes pack could not be put in place:** " + al_swap
					+ {STRING_32} " Once that is put right, import the folder again: the pack is built again from every note.%N%N")
			elseif a_batch.is_built and a_batch.kept.is_empty then
				l_page.append ({STRING_32} "The notes pack was built again from every note: an earlier one had not been put in place.%N%N")
			end
			if a_batch.file_count = 0 then
				l_page.append ({STRING_32} "No file in this folder ends in .prepared.md.%N%N")
			end
			if not a_batch.kept.is_empty then
				l_page.append ({STRING_32} "## Imported (" + a_batch.kept.count.out.to_string_32 + {STRING_32} ")%N%N")
				across a_batch.kept as ic loop
					l_page.append ({STRING_32} "- " + ic.title + {STRING_32} " (" + ic.file
						+ (if across a_batch.replaced as al_r some al_r.same_string (ic.file) end then {STRING_32} ", replacing its earlier version" else {STRING_32} "" end)
						+ {STRING_32} ")%N")
				end
				l_page.append ({STRING_32} "%NThe notes pack holds " + a_batch.built_blocks.out.to_string_32 + {STRING_32} " paragraphs and "
					+ a_batch.built_suggestions.out.to_string_32 + {STRING_32} " suggested passages.%N%N")
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

	swapped_notes_pack (a_pack, a_new: STRING_32): detachable STRING_32
			-- The new notes pack `a_new' put in `a_pack''s place, the engine closed for it and opened
			-- again; the old pack kept as ".old" until the new one is in place, and put back when it
			-- cannot be (scan 66: a failed delete or rename lost the pack and still said "Imported").
			-- Void when done, else what went wrong.
		local
			l_old: STRING_32
			l_had_old, l_ok: BOOLEAN
		do
			l_old := a_pack + {STRING_32} ".old"
			if (create {SIMPLE_FILE}.make (l_old)).is_file then
					-- scan 69: never deleted: it may be the only copy of an earlier notes pack
				Result := {STRING_32} "A notes pack kept from an earlier failed import is still at " + l_old
					+ {STRING_32} ": move it somewhere safe, then import again."
			else
				bible.close
				l_had_old := (create {SIMPLE_FILE}.make (a_pack)).is_file
				if l_had_old and then not (create {SIMPLE_FILE}.make (a_pack)).rename_to ({BIB_NOTE_SCHEMA}.Pack_file_name.to_string_32 + {STRING_32} ".old") then
					Result := {STRING_32} "The old notes pack could not be moved aside; it is unchanged."
				elseif not (create {SIMPLE_FILE}.make (a_new)).rename_to ({BIB_NOTE_SCHEMA}.Pack_file_name) then
					Result := {STRING_32} "The new notes pack could not be renamed into place"
					if l_had_old then
						if (create {SIMPLE_FILE}.make (l_old)).rename_to ({BIB_NOTE_SCHEMA}.Pack_file_name) then
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
					Result := {STRING_32} "Simple Bible could not open the new notes pack ("
						+ (if attached bible.last_error as al_e then al_e.message else {STRING_32} "no reason given" end) + {STRING_32} ")"
					l_ok := (create {SIMPLE_FILE}.make (a_pack)).delete
					if l_had_old then
						if (create {SIMPLE_FILE}.make (l_old)).rename_to ({BIB_NOTE_SCHEMA}.Pack_file_name) then
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
			-- Ticks left before the notes pack is built again (`rebuild_notes_pack'); 0: none waiting.

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
					arrange (True)
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
			-- forgiving a misspelt word.

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
					rebuild_notes_pack
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
				verses_heading.set_text ({STRING_32} "Verses in " + reading_version.to_string_32 + {STRING_32} ": 1 matches. Click it to read it." + l_note)
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
			-- Dock P07 west (Simple), or bring Search Results to the front of T6 (Study).
		do
			refresh_strip_marks
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
			window.add_reference_mark (commentary_title, "S2", "P04 Commentary, east: follows the verse. Commentaries from the commentary packs (every claim labelled SOURCED or DEDUCED); Cross-refs (OpenBible votes).", window.Corner_top_left)
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
