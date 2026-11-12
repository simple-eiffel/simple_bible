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

feature -- Undo and Redo for Favorites (Larry, 2026-11-03)

	test_ctrl_z_undoes_an_added_favorite_and_ctrl_y_redoes_it
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_add_favorite (1, 16, "John 3:16", 0)
			assert_integers_equal ("kept", 1, app.harness_folder_item_count (0))
			assert_strings_equal ("Undo names it", "Add John 3:16", app.harness_undo_name)
			app.harness_key (0x5A, True, False)
			assert_integers_equal ("Ctrl+Z took it back", 0, app.harness_folder_item_count (0))
			assert_false ("and its star", app.harness_verse_starred (16))
			app.harness_key (0x59, True, False)
			assert_integers_equal ("Ctrl+Y put it back", 1, app.harness_folder_item_count (0))
			app.harness_key (0x5A, True, False)
			app.harness_key (0x5A, True, True)
			assert_integers_equal ("Ctrl+Shift+Z redoes too", 1, app.harness_folder_item_count (0))
		end

	test_ctrl_z_in_a_text_box_stays_the_boxs_own
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_add_favorite (1, 16, "John 3:16", 0)
			app.harness_give_focus_to_filter
			app.harness_key (0x5A, True, False)
			assert_integers_equal ("typing's Undo, not Favorites'", 1, app.harness_folder_item_count (0))
		end

	test_a_notices_undo_puts_a_move_back
		local
			app: BIB_GUI_APP
			t: SW_TREE [BIB_FAVORITE_NODE]
			l_folder: INTEGER_64
			k: INTEGER
		do
			app := new_window
				-- Study shows the Navigator and its Favorites tree; the window must not depend on what a
				-- data folder's settings.txt holds (port-coordination issue 58, 2026-11-11).
			app.harness_state.set_study (True)
			app.harness_go_to (43, 3, 16)
			app.harness_add_favorite (1, 16, "John 3:16", 0)
			l_folder := app.harness_new_folder ("Gospel")
			app.harness_show_favorites
			app.harness_render
			t := app.harness_favorites_tree
			k := row_of (t, "John 3:16")
			app.harness_dispatch (2, row_x (t), row_y (t, k))
			app.harness_dispatch (9, row_x (t), row_y (t, k) + 10)
			app.harness_dispatch (9, row_x (t), row_y (t, row_of (t, "Gospel")))
			app.harness_dispatch (10, row_x (t), row_y (t, row_of (t, "Gospel")))
			assert_integers_equal ("moved", 1, app.harness_folder_item_count (l_folder))
			app.harness_notice_undo
			assert_integers_equal ("the notice's Undo put it back", 1, app.harness_folder_item_count (0))
			assert_integers_equal ("out of Gospel", 0, app.harness_folder_item_count (l_folder))
		end

	test_a_drop_into_a_new_folder_undoes_as_one_change
		local
			app: BIB_GUI_APP
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [BIB_FAVORITE_NODE]
			l_folder: INTEGER_64
			cx: INTEGER
		do
			app := new_window
			l_folder := app.harness_new_folder ("Sermons")
			app.harness_show_framework (1)
			app.harness_show_favorites
			app.harness_render
			v := app.harness_document_view (1)
			t := app.harness_favorites_tree
			v.select_range (2, 0, 2, v.text_of (2).count.min (24))
			app.harness_pick_up (1)
			app.harness_dispatch (13, row_x (t), row_y (t, row_of (t, "Sermons")))
			cx := (t.new_folder_chip_left + 20.0).truncated_to_integer
			app.harness_dispatch (13, cx, row_y (t, row_of (t, "Sermons")))
			app.harness_dispatch (2, cx, row_y (t, row_of (t, "Sermons")))
			app.harness_close_sheet
			assert_integers_equal ("a folder made", 1, app.harness_folder_ids_in (l_folder).count)
			assert_true ("one change, to a new folder", app.harness_undo_name.has_substring ("to a new folder"))
			app.harness_key (0x5A, True, False)
			assert_integers_equal ("one Ctrl+Z: no folder", 0, app.harness_folder_ids_in (l_folder).count)
			assert_strings_equal ("and Sermons' own name is next", "Rename Untitled", app.harness_undo_name)
		end

	test_ctrl_z_puts_an_old_name_back
		local
			app: BIB_GUI_APP
			l_folder: INTEGER_64
		do
			app := new_window
			l_folder := app.harness_new_folder ("Sermons")
			assert_strings_equal ("named", "Sermons", app.harness_favorite_root_label (1))
			app.harness_key (0x5A, True, False)
			assert_strings_equal ("Ctrl+Z: the old name", "Untitled", app.harness_favorite_root_label (1))
			app.harness_key (0x5A, True, False)
			assert_integers_equal ("Ctrl+Z again: no folder", 0, app.harness_favorite_roots)
		end

feature -- Carrying a selection to Favorites (research/24 stage D3, 2026-11-03)

	test_a_framework_selection_dragged_onto_a_folder_is_kept_there
			-- Larry: drag a selection into Favorites. Pressed on the selection and moved, it lifts;
			-- released on a folder, it is kept there; the framework is not changed.
		local
			app: BIB_GUI_APP
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [BIB_FAVORITE_NODE]
			l_folder: INTEGER_64
			b: TUPLE [x, y, width, height: REAL_64]
			px, py: INTEGER
		do
			app := new_window
			l_folder := app.harness_new_folder ("Sermons")
			app.harness_show_framework (1)
			app.harness_show_favorites
			app.harness_render
			v := app.harness_document_view (1)
			t := app.harness_favorites_tree
			assert_true ("the framework and the tree both shown", v.width > 0 and t.width > 0 and t.height > 0)
			v.select_range (2, 0, 2, v.text_of (2).count.min (24))
			b := v.text_boxes (2, 3, 4).first
			px := (b.x + b.width / 2.0).truncated_to_integer
			py := (b.y + b.height / 2.0).truncated_to_integer
			app.harness_dispatch (2, px, py)
			app.harness_dispatch (9, px + 30, py)
			assert_true ("lifted", app.harness_is_picking)
			assert_true ("its card names it", not app.harness_pick_card.is_empty)
			app.harness_dispatch (9, row_x (t), row_y (t, row_of (t, "Sermons")))
			app.harness_dispatch (10, row_x (t), row_y (t, row_of (t, "Sermons")))
			assert_false ("dropped", app.harness_is_picking)
			assert_integers_equal ("kept in Sermons", 1, app.harness_folder_item_count (l_folder))
			assert_integers_equal ("not at the top level", 0, app.harness_folder_item_count (0))
			assert_true ("the framework's selection stands", v.has_selection)
		end

	test_pick_up_a_verse_quotation_and_click_a_folder
			-- The verse menu's Pick up: the words follow the pointer with no button held; a click on a
			-- folder keeps them there.
		local
			app: BIB_GUI_APP
			v: SW_PARALLEL_TEXT
			t: SW_TREE [BIB_FAVORITE_NODE]
			l_folder: INTEGER_64
			u: INTEGER
		do
			app := new_window
				-- Study shows the Navigator and its Favorites tree; the window must not depend on what a
				-- data folder's settings.txt holds (port-coordination issue 58, 2026-11-11).
			app.harness_state.set_study (True)
			l_folder := app.harness_new_folder ("Verses")
			app.harness_go_to (43, 3, 16)
			app.harness_show_favorites
			app.harness_render
			v := app.harness_bible_view
			t := app.harness_favorites_tree
			from u := 1 until u > v.unit_count or else v.unit_block (u) = 16 loop
				u := u + 1
			end
			assert_true ("verse 16 laid out", u <= v.unit_count)
			v.select_range (u, 4, u, 26)
			app.harness_pick_up (4)
			assert_true ("picked up", app.harness_is_picking)
			app.harness_dispatch (13, row_x (t), row_y (t, row_of (t, "Verses")))
			app.harness_dispatch (10, row_x (t), row_y (t, row_of (t, "Verses")))
			assert_true ("a stray release does not drop it", app.harness_is_picking)
			app.harness_dispatch (2, row_x (t), row_y (t, row_of (t, "Verses")))
			assert_false ("the click drops it", app.harness_is_picking)
			assert_integers_equal ("kept in Verses", 1, app.harness_folder_item_count (l_folder))
			assert_true ("verse 16 starred", app.harness_verse_starred (16))
		end

	test_a_favorite_dragged_onto_a_folder_moves_into_it
		local
			app: BIB_GUI_APP
			t: SW_TREE [BIB_FAVORITE_NODE]
			l_folder: INTEGER_64
			k: INTEGER
		do
			app := new_window
				-- Study shows the Navigator and its Favorites tree; the window must not depend on what a
				-- data folder's settings.txt holds (port-coordination issue 58, 2026-11-11).
			app.harness_state.set_study (True)
			app.harness_go_to (43, 3, 16)
			app.harness_add_favorite (1, 16, "John 3:16", 0)
			l_folder := app.harness_new_folder ("Gospel")
			app.harness_show_favorites
			app.harness_render
			t := app.harness_favorites_tree
			assert_integers_equal ("one at the top level", 1, app.harness_folder_item_count (0))
			k := row_of (t, "John 3:16")
			assert_true ("the favorite shown", k > 0)
			app.harness_dispatch (2, row_x (t), row_y (t, k))
			app.harness_dispatch (9, row_x (t), row_y (t, k) + 10)
			assert_true ("the line lifts", app.harness_is_picking)
			app.harness_dispatch (9, row_x (t), row_y (t, row_of (t, "Gospel")))
			app.harness_dispatch (10, row_x (t), row_y (t, row_of (t, "Gospel")))
			assert_integers_equal ("moved into Gospel", 1, app.harness_folder_item_count (l_folder))
			assert_integers_equal ("none left at the top level", 0, app.harness_folder_item_count (0))
		end

	test_a_folders_new_folder_button_keeps_it_in_an_untitled_folder
			-- One drop, not two: an "Untitled" folder made inside the folder, the quotation kept in
			-- it, its name open for editing.
		local
			app: BIB_GUI_APP
			v: SW_DOCUMENT_VIEW
			t: SW_TREE [BIB_FAVORITE_NODE]
			l_folder: INTEGER_64
			l_made: ARRAYED_LIST [INTEGER_64]
			cx: INTEGER
		do
			app := new_window
			l_folder := app.harness_new_folder ("Sermons")
			app.harness_show_framework (1)
			app.harness_show_favorites
			app.harness_render
			v := app.harness_document_view (1)
			t := app.harness_favorites_tree
			v.select_range (2, 0, 2, v.text_of (2).count.min (24))
			app.harness_pick_up (1)
			app.harness_dispatch (13, row_x (t), row_y (t, row_of (t, "Sermons")))
			cx := (t.new_folder_chip_left + 20.0).truncated_to_integer
			app.harness_dispatch (13, cx, row_y (t, row_of (t, "Sermons")))
			assert_true ("on the New folder button", t.is_on_new_folder_row)
			app.harness_dispatch (2, cx, row_y (t, row_of (t, "Sermons")))
			l_made := app.harness_folder_ids_in (l_folder)
			assert_integers_equal ("a folder made inside Sermons", 1, l_made.count)
			assert_integers_equal ("the quotation in it", 1, app.harness_folder_item_count (l_made.first))
			assert_true ("its name open for editing", app.harness_sheet_open)
		end

feature -- The design pills tell the truth (Larry, 2026-11-03)

	test_the_study_pills_tell_the_truth
			-- C10 named only Parallel and Interlinear as working, though Timeline
			-- and Atlas work too; T6.5 said "misspelt" (US English: "misspelled").
		local
			app: BIB_GUI_APP
			l_tip: STRING_32
		do
			app := new_window
			app.harness_state.set_study (True)
			l_tip := app.harness_pill_tip ("C10")
			assert_true ("C10 names Timeline", l_tip.has_substring ({STRING_32} "Timeline"))
			assert_true ("C10 names Atlas", l_tip.has_substring ({STRING_32} "Atlas"))
			l_tip := app.harness_pill_tip ("T6.5")
			assert_true ("T6.5 found", not l_tip.is_empty)
			assert_true ("T6.5 in US English", l_tip.has_substring ({STRING_32} "misspelled"))
			assert_false ("T6.5 not British", l_tip.has_substring ({STRING_32} "misspelt"))
		end

feature -- The meme tool (research/25, 2026-11-01)

	test_memes_answer_the_verse_read
			-- Larry: the tool responds to the passage read.
			-- The count comes from the data: memes keep being added.
		local
			app: BIB_GUI_APP
			l_all: INTEGER
		do
			app := new_window
			l_all := app.harness_meme_count
			assert_true ("meme.db in the test data", l_all > 0)
			app.harness_go_to (43, 3, 16)
			app.harness_meme_scope (2)
			assert_true ("John 3:16's meme listed", app.harness_lists_meme ("john-3-16"))
			assert_true ("only the verse's memes", app.harness_meme_count < l_all)
			app.harness_meme_scope (1)
			assert_integers_equal ("all again", l_all, app.harness_meme_count)
		end

	test_the_meme_search_finds_titles_and_words
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_search_memes ("kosmos")
			assert_true ("found by its words", app.harness_lists_meme ("john-3-16"))
			app.harness_search_memes ("stadium sign")
			assert_integers_equal ("found by its title", 1, app.harness_meme_count)
		end

	test_a_favorite_meme_stays_at_the_top
			-- Larry: favorite memes live at the top of the list, under any order.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			assert_false ("not first to begin with", app.harness_meme_shown_first.same_string ("in-christ"))
			app.harness_choose_meme ("in-christ")
			app.harness_toggle_meme_favorite
			assert_true ("first now: " + app.harness_meme_shown_first.to_string_8, app.harness_meme_shown_first.same_string ("in-christ"))
			assert_true ("kept in a Memes folder", app.harness_favorite_roots = 1 and then app.harness_favorite_root_label (1).same_string ("Memes"))
			app.harness_toggle_meme_favorite
			assert_false ("not first once taken out", app.harness_meme_shown_first.same_string ("in-christ"))
		end

	test_copy_a_memes_words_and_picture
			-- Larry: copy the picture to the clipboard, and the description separately. The reader's
			-- clipboard text is put back afterwards.
		local
			app: BIB_GUI_APP
			l_clip: SW_CLIPBOARD
			l_saved: STRING_32
		do
			create l_clip
			l_saved := l_clip.text.twin
			app := new_window
			app.harness_choose_meme ("john-3-16")
			app.harness_copy_meme_description
			assert_true ("the words on the clipboard", l_clip.text.has_substring ("kosmos"))
			app.harness_copy_meme_picture
			assert_true ("a picture on the clipboard", l_clip.has_image)
			assert_integers_equal ("the meme's width", 1080, l_clip.image_width)
			l_clip.set_text (l_saved)
		end

	test_a_memes_picture_loads_only_when_hovered
			-- Larry: load a picture only when its icon is hovered, never them all; one in memory.
		local
			app: BIB_GUI_APP
			l_first: detachable CAIRO_SURFACE
		do
			app := new_window
			assert_true ("no picture loaded at the start", app.harness_card_picture = Void)
			assert_true ("a card for John 3:16", attached app.harness_meme_card ("john-3-16"))
			l_first := app.harness_card_picture
			assert_true ("its picture decoded", attached l_first as al_first and then al_first.width = 1080)
			assert_true ("a card for another", attached app.harness_meme_card ("in-christ"))
			assert_true ("the first picture let go", attached l_first as al_first and then not al_first.is_valid)
		end

	test_a_memes_words_and_passages_are_edited
			-- Larry: edit the description (type or paste) and the passages as he finds them. The test data
			-- is put back as it was.
		local
			app: BIB_GUI_APP
			l_title, l_words, l_passages: STRING_32
		do
			app := new_window
			l_title := app.harness_meme_title ("john-3-16")
			l_words := app.harness_meme_words ("john-3-16")
			l_passages := app.harness_meme_passages ("john-3-16")
			assert_true ("saved", app.harness_edit_meme ("john-3-16", "The stadium sign", "Pasted in whole: new words.", "John 3:16; 1 John 4:9-10"))
			assert_true ("its new words", app.harness_meme_words ("john-3-16").same_string ("Pasted in whole: new words."))
			assert_true ("its passages as typed: " + app.harness_meme_passages ("john-3-16").to_string_8, app.harness_meme_passages ("john-3-16").same_string ("John 3:16; 1 John 4:9-10"))
			app.harness_go_to (62, 4, 10)
			app.harness_meme_scope (2)
			assert_true ("1 John 4:10 names it now", app.harness_lists_meme ("john-3-16"))
			assert_false ("a passage that does not read changes nothing", app.harness_edit_meme ("john-3-16", "x", "y", "Hezekiah 4:1"))
			assert_true ("still as saved", app.harness_meme_words ("john-3-16").same_string ("Pasted in whole: new words."))
			assert_true ("put back", app.harness_edit_meme ("john-3-16", l_title, l_words, l_passages))
			assert_true ("as it was", app.harness_meme_words ("john-3-16").same_string (l_words) and app.harness_meme_passages ("john-3-16").same_string (l_passages))
		end

	test_a_folder_copies_its_references
			-- Larry: right-click a Favorites folder to copy its references.
		local
			app: BIB_GUI_APP
			l_clip: SW_CLIPBOARD
			l_saved: STRING_32
			l_grace: INTEGER_64
		do
			create l_clip
			l_saved := l_clip.text.twin
			app := new_window
			app.harness_go_to (43, 3, 16)
			l_grace := app.harness_new_folder ("Grace")
			app.harness_add_favorite (1, 0, "", l_grace)
			app.harness_go_to (45, 8, 28)
			app.harness_add_favorite (2, 30, "", l_grace)
			app.harness_copy_folder_references (l_grace)
			assert_true ("both references, one a line: " + l_clip.text.to_string_8, l_clip.text.has_substring ("John 3:16") and l_clip.text.has_substring ("Romans 8:28-30") and l_clip.text.has ('%N'))
			l_clip.set_text (l_saved)
		end

feature -- Text that wraps (Larry, 2026-11-01: a long highlight reason ran off the box's edge)

	test_a_long_highlight_reason_wraps_in_its_box
			-- The reason box was one line: typing on, the words ran out of sight. It wraps now, and
			-- grows a line at a time.
		local
			app: BIB_GUI_APP
			l_short, l_long: REAL_64
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_go_to (42, 24, 33)
			app.harness_select_notes_tab (4)
			l_short := app.harness_highlight_box_height ("Why")
			l_long := app.harness_highlight_box_height ("The %"two%" are not a part of the eleven. There are other disciples and %"those with them%" in the room, which matters for who saw the risen Lord that night.")
			assert_true ("a long reason makes the box taller: " + l_short.out + " then " + l_long.out, l_long > l_short + 4.0)
		end

	test_a_chosen_highlight_reads_in_full
			-- The list cuts a long reason off at the column's edge; chosen, it reads in full, wrapped,
			-- under the list.
		local
			app: BIB_GUI_APP
			l_reason: STRING_32
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_go_to (42, 24, 33)
			l_reason := {STRING_32} "The %"two%" are not a part of the eleven. There are other disciples and %"those with them%" in the room."
			app.harness_add_highlight (l_reason)
			app.harness_choose_highlight (1)
			assert_true ("the whole reason: " + app.harness_highlight_detail.to_string_8, app.harness_highlight_detail.has_substring (l_reason))
		end

feature -- Quotations and documents (research/24 stage D, 2026-11-01)

	test_a_framework_quotation_is_marked_and_found_again
			-- Larry: a selected part of a framework kept as a quotation; marked inside the framework;
			-- chosen in Favorites, the framework opens with the words selected.
		local
			app: BIB_GUI_APP
			v: SW_DOCUMENT_VIEW
			l_quote: STRING_32
		do
			app := new_window
			assert_true ("the test data has frameworks", app.harness_framework_count >= 2)
			app.harness_show_framework (1)
			app.harness_render
			v := app.harness_document_view (1)
			assert_true ("laid out", v.unit_count >= 2)
			v.select_range (2, 0, 2, v.text_of (2).count.min (24))
			l_quote := v.selected_text
			assert_false ("something selected", l_quote.is_empty)
			app.harness_quote_selection (1, 0)
			assert_integers_equal ("kept", 1, app.harness_favorite_roots)
			assert_integers_equal ("a quotation's mark in the tree", {SW_PAINTER}.Glyph_quote, app.harness_favorite_root_icon (1))
			assert_integers_equal ("marked in the framework", 1, v.standing_ranges.count)
			app.harness_show_framework (2)
			assert_integers_equal ("not in another", 0, v.standing_ranges.count)
			app.harness_open_favorite_root (1)
			assert_true ("chosen: its framework back, the words selected", v.selected_text.same_string (l_quote))
			assert_integers_equal ("and marked", 1, v.standing_ranges.count)
		end

	test_the_library_shows_status_and_days
			-- 0.7.61: the series list's Status column reads "N of M published" while a series is part
			-- posted, with a Latest day beside it; the essays list has a Published column whose header
			-- orders it oldest first, then newest first, then as written.
		local
			app: BIB_GUI_APP
			g: SW_DATA_GRID [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]
		do
			app := new_window
			assert_true ("the test data has books", app.harness_book_count >= 1)
			assert_strings_equal ("a Status column", "Status", app.harness_books_grid.columns.i_th (3).title)
			assert_strings_equal ("a Latest column", "Latest", app.harness_books_grid.columns.i_th (4).title)
			app.harness_show_first_book (1)
			g := app.harness_chapters_grid
			assert_strings_equal ("a Published column", "Published", g.columns.i_th (2).title)
			g.sort_by (2, False)
			assert_integers_equal ("ordered by day", 2, g.sort_column)
			g.sort_by (2, True)
			assert_true ("newest first", g.is_descending)
			g.sort_by (0, False)
			assert_integers_equal ("as written again", 0, g.sort_column)
		end

	test_a_book_quotation_names_its_block
			-- A quotation from a book chapter is kept with a link to its block ("book:x/2#n"), and
			-- chosen in Favorites it opens the chapter with the words selected.
		local
			app: BIB_GUI_APP
			v: SW_DOCUMENT_VIEW
			l_quote: STRING_32
		do
			app := new_window
			assert_true ("the test data has books", app.harness_book_count >= 1)
			app.harness_show_first_book (2)
			app.harness_render
			v := app.harness_document_view (2)
			assert_true ("laid out", v.unit_count >= 3)
			v.select_range (3, 0, 3, v.text_of (3).count.min (30))
			l_quote := v.selected_text
			app.harness_quote_selection (2, 0)
			assert_integers_equal ("kept", 1, app.harness_favorite_roots)
			assert_true ("its link names the block: " + app.harness_favorite_target (1).to_string_8, app.harness_favorite_target (1).has ('#'))
			assert_true ("one favorite, no folders", app.harness_favorites_heading.same_string ("1 favorite"))
			v.clear_selection
			app.harness_open_favorite_root (1)
			assert_true ("found again, selected", v.selected_text.same_string (l_quote))
		end

	test_a_verse_quotation_stars_marks_and_opens
			-- Larry: part of a verse kept as a quotation (an optional way to keep a passage): its verse
			-- starred, its words marked in the Bible text, and chosen in Favorites the verse is read
			-- in its version with the words selected.
		local
			app: BIB_GUI_APP
			v: SW_PARALLEL_TEXT
			u: INTEGER
			l_quote: STRING_32
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_render
			v := app.harness_bible_view
			from u := 1 until u > v.unit_count or else v.unit_block (u) = 16 loop
				u := u + 1
			end
			assert_true ("verse 16 laid out", u <= v.unit_count)
			v.select_range (u, 4, u, 26)
			l_quote := v.selected_text
			app.harness_quote_verse_selection (0)
			assert_integers_equal ("kept", 1, app.harness_favorite_roots)
			assert_integers_equal ("a quotation's mark in the tree", {SW_PAINTER}.Glyph_quote, app.harness_favorite_root_icon (1))
			assert_true ("verse 16 starred", app.harness_verse_starred (16))
			assert_integers_equal ("its words marked", 1, v.standing_ranges.count)
			app.harness_go_to (1, 1, 1)
			assert_integers_equal ("not in Genesis", 0, v.standing_ranges.count)
			app.harness_open_favorite_root (1)
			assert_true ("back at John 3:16", app.harness_is_at (43, 3, 16))
			assert_true ("the words selected", v.selected_text.same_string (l_quote))
			assert_integers_equal ("and marked", 1, v.standing_ranges.count)
		end

	test_a_favorite_document_marks_its_title_and_its_row
		local
			app: BIB_GUI_APP
			v: SW_DOCUMENT_VIEW
		do
			app := new_window
			assert_true ("the test data has frameworks", app.harness_framework_count >= 1)
			app.harness_show_framework (1)
			app.harness_render
			v := app.harness_document_view (1)
			app.harness_keep_document (1)
			assert_integers_equal ("kept", 1, app.harness_favorite_roots)
			assert_integers_equal ("a document's page in the tree", {SW_PAINTER}.Glyph_document, app.harness_favorite_root_icon (1))
			assert_integers_equal ("its title marked", 1, v.standing_ranges.count)
			assert_true ("its row in the list starred", app.harness_framework_starred (1))
		end

feature -- Favorites (research/24 stage C, 2026-11-01)

	test_a_favorite_verse_wears_the_star
			-- Larry: a favorite verse is marked with the gold star; its version is kept.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_add_favorite (1, 0, "", 0)
			assert_integers_equal ("one line at the top", 1, app.harness_favorite_roots)
			assert_true ("named with its version: " + app.harness_favorite_root_label (1).to_string_8, app.harness_favorite_root_label (1).same_string ("John 3:16 (KJV)"))
			assert_true ("verse 16 starred", app.harness_verse_starred (16))
			assert_false ("verse 17 not", app.harness_verse_starred (17))
		end

	test_a_range_in_a_new_folder
			-- Folders of the reader's own; a range stars each of its verses.
		local
			app: BIB_GUI_APP
			l_grace: INTEGER_64
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			l_grace := app.harness_new_folder ("Grace")
			assert_true ("a folder made", l_grace > 0)
			assert_true ("named Grace", app.harness_favorite_roots = 1 and then app.harness_favorite_root_label (1).same_string ("Grace"))
			app.harness_add_favorite (2, 18, "", l_grace)
			assert_integers_equal ("the range is inside the folder", 1, app.harness_favorite_roots)
			assert_true ("verses 16 to 18 starred", app.harness_verse_starred (16) and app.harness_verse_starred (17) and app.harness_verse_starred (18))
			assert_false ("verse 19 not", app.harness_verse_starred (19))
		end

	test_a_removed_folder_hides_its_stars_until_restored
		local
			app: BIB_GUI_APP
			l_grace: INTEGER_64
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			l_grace := app.harness_new_folder ("Grace")
			app.harness_add_favorite (1, 0, "", l_grace)
			app.harness_choose_favorite_root (1)
			app.harness_remove_chosen_favorite
			assert_integers_equal ("the folder gone", 0, app.harness_favorite_roots)
			assert_false ("and its verse's star", app.harness_verse_starred (16))
			app.harness_restore_favorite
			assert_integers_equal ("restored", 1, app.harness_favorite_roots)
			assert_true ("the star back", app.harness_verse_starred (16))
		end

	test_a_whole_chapter_stars_the_chapter_not_its_verses
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_add_favorite (3, 0, "", 0)
			assert_true ("John 3 starred", app.harness_chapter_starred (43, 3))
			assert_false ("its verses are not", app.harness_verse_starred (16))
			assert_true ("named for the chapter", app.harness_favorite_root_label (1).has_substring ("John 3"))
		end

	test_the_filter_finds_favorites_in_folders
		local
			app: BIB_GUI_APP
			l_grace: INTEGER_64
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			l_grace := app.harness_new_folder ("Grace")
			app.harness_add_favorite (1, 0, "For God so loved", l_grace)
			app.harness_go_to (1, 1, 1)
			app.harness_add_favorite (1, 0, "", 0)
			app.harness_filter_favorites ("loved")
			assert_integers_equal ("one found", 1, app.harness_favorite_roots)
			assert_true ("from inside its folder", app.harness_favorite_root_label (1).has_substring ("For God so loved"))
			app.harness_filter_favorites ("")
			assert_integers_equal ("the tree again: the folder and Genesis 1:1", 2, app.harness_favorite_roots)
		end

feature -- History (research/24 stage B, 2026-11-01)

	test_this_session_lists_every_verse_touched
			-- Larry: a History that lists every verse touched this session.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_click_verse (17)
			app.harness_click_verse (18)
			app.harness_go_to (1, 1, 1)
			app.harness_history_scope (1)
			assert_integers_equal ("four verses, each once", 4, app.harness_history_count)
			assert_true ("Genesis 1:1 newest (read at the start too, listed once)", app.harness_history_is (1, 1, 1, 1))
			assert_true ("then John 3:18", app.harness_history_is (2, 43, 3, 18))
			assert_true ("John 3:16 oldest", app.harness_history_is (4, 43, 3, 16))
		end

	test_kept_history_lists_each_verse_once
			-- The kept history lists verses, not chapters, each at its newest visit.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (43, 3, 16)
			app.harness_click_verse (17)
			app.harness_click_verse (16)
			app.harness_history_scope (2)
			assert_integers_equal ("three verses (Genesis 1:1 from the start)", 3, app.harness_history_count)
			assert_true ("John 3:16 newest", app.harness_history_is (1, 43, 3, 16))
			assert_true ("John 3:17 next", app.harness_history_is (2, 43, 3, 17))
		end

	test_kept_history_follows_its_limit
			-- Larry: kept up to a number the reader can change (200 at first).
		local
			app: BIB_GUI_APP
			i: INTEGER
		do
			app := new_window
			assert_integers_equal ("200 at first", 200, app.harness_history_keep_value)
			app.harness_set_history_limit (10)
			app.harness_go_to (43, 3, 1)
			from i := 2 until i > 15 loop
				app.harness_click_verse (i)
				i := i + 1
			end
			app.harness_history_scope (2)
			assert_integers_equal ("ten listed", 10, app.harness_history_count)
			assert_true ("John 3:15 newest", app.harness_history_is (1, 43, 3, 15))
			app.harness_set_history_limit (5000)
			assert_integers_equal ("kept to the longest allowed", 1000, app.harness_history_keep_value)
		end

feature -- Phase 3: the reading place (research/23; written 2026-11-01 and run on 0.7.49 first)

	test_a_verse_click_keeps_the_chapter
			-- Risk 17: a click on another verse of the chapter read rebuilt the chapter, Parallel and
			-- every Study pane, though only the selected verse changed.
		local
			app: BIB_GUI_APP
			l_bible, l_parallel, l_highlights: ANY
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_go_to (43, 3, 16)
			l_bible := app.harness_bible_cell (1)
			l_parallel := app.harness_parallel_cell (1)
			l_highlights := app.harness_highlight_rows
			app.harness_click_verse (17)
			assert_true ("the Bible tab's rows kept", l_bible = app.harness_bible_cell (1))
			assert_true ("Parallel's rows kept", l_parallel = app.harness_parallel_cell (1))
			assert_true ("the highlights list not read again", l_highlights = app.harness_highlight_rows)
			assert_false ("verse 16 no longer selected", app.harness_verse_selected (16))
			assert_true ("verse 17 selected", app.harness_verse_selected (17))
			assert_false ("Parallel: verse 16 no longer selected", app.harness_parallel_verse_selected (16))
			assert_true ("Parallel: verse 17 selected", app.harness_parallel_verse_selected (17))
		end

	test_a_click_on_the_verse_read_adds_no_step
			-- A second click on the verse already read added the same place to the trail again, so
			-- Back stood still once.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (1, 1, 1)
			app.harness_go_to (43, 3, 16)
			app.harness_click_verse (16)
			app.harness_step_history (-1)
			assert_true ("one Back returns to Genesis 1:1", app.harness_is_at (1, 1, 1))
		end

	test_back_and_forward_follow_the_trail
			-- Back and Forward, on the toolbar and in the Go menu, follow the trail.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (1, 1, 1)
			app.harness_go_to (43, 3, 16)
			assert_true ("Back on", app.harness_back_enabled and app.harness_go_menu_enabled ("Back"))
			assert_false ("Forward off", app.harness_forward_enabled or app.harness_go_menu_enabled ("Forward"))
			app.harness_step_history (-1)
			assert_true ("at Genesis 1:1", app.harness_is_at (1, 1, 1))
			assert_true ("Forward on", app.harness_forward_enabled and app.harness_go_menu_enabled ("Forward"))
			app.harness_step_history (1)
			assert_true ("at John 3:16", app.harness_is_at (43, 3, 16))
			assert_false ("Forward off at the end", app.harness_forward_enabled or app.harness_go_menu_enabled ("Forward"))
		end

	test_previous_and_next_stop_at_the_ends
			-- Risk 3: the Go menu's Previous and Next chapter asked the toolbar buttons; both ask the
			-- reading place now.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_go_to (1, 1, 1)
			assert_false ("Genesis 1: no previous chapter", app.harness_previous_enabled or app.harness_go_menu_enabled ("Previous chapter"))
			assert_true ("Genesis 1: a next chapter", app.harness_next_enabled and app.harness_go_menu_enabled ("Next chapter"))
			app.harness_go_to (66, 22, 21)
			assert_false ("Revelation 22: no next chapter", app.harness_next_enabled or app.harness_go_menu_enabled ("Next chapter"))
			assert_true ("Revelation 22: a previous chapter", app.harness_previous_enabled and app.harness_go_menu_enabled ("Previous chapter"))
		end

feature -- Phase 5: notes, collections, strip marks (each test seen failing on 0.7.48 first)

	test_notes_dot_follows_adding_and_deleting
			-- Risk 6: the Notes dot was set only when a chapter was read, so adding the chapter's
			-- first note (or deleting its last) left it wrong.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_go_to (43, 3, 16)
			assert_false ("no notes, no dot", app.harness_notes_marked)
			app.harness_add_note ("Born from above.")
			assert_true ("the first note: a dot", app.harness_notes_marked)
			app.harness_delete_note (1)
			assert_false ("the last note deleted: no dot", app.harness_notes_marked)
		end

	test_one_verse_reads_as_one
			-- The verses heading said "1 matches" (seen in the 0.7.48 search snapshot).
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_search ("%"full of grace%"")
			assert_true ("one verse: " + app.harness_verses_heading.to_string_8, app.harness_verses_heading.has_substring ("1 verse matches"))
		end

	test_answered_waits_for_a_chosen_prayer
			-- Risk 8: Answered was enabled whenever there was an open prayer, and a press with none
			-- chosen only said "Click an open prayer first".
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_add_prayer ("For wisdom", "James 1:5")
			assert_false ("an open prayer, none chosen: Answered off", app.harness_answered_enabled)
			app.harness_choose_open_prayer (1)
			assert_true ("one chosen: Answered on", app.harness_answered_enabled)
		end

feature -- Phase 4: search results (each test seen failing on 0.7.47 first)

	test_verse_search_listed_in_the_window_menu
			-- Risk 4: a search that finds only verses showed the panel, but Window > Search results
			-- was greyed (it asked for dictionary choices only).
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (False)
			app.harness_search ("%"born again%"")
			assert_true ("verses found", app.harness_results_count > 0)
			assert_true ("the panel shown", app.harness_results_visible)
			assert_true ("and Window > Search results enabled", app.harness_window_menu_enabled ("Search results"))
			app.shut_down
		end

	test_closed_results_stay_closed_across_layouts
			-- Risk 4: results the reader closed came back on the next switch to Simple.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (False)
			app.harness_search ("love")
			assert_true ("shown", app.harness_results_visible)
			app.harness_close_results
			assert_false ("closed", app.harness_results_visible)
			app.harness_state.set_study (True)
			app.harness_state.set_study (False)
			assert_false ("still closed after Study and back", app.harness_results_visible)
			app.shut_down
		end

	test_close_in_study_clears_the_results
			-- Risk 5: Close did nothing in Study (the zone stays: it holds the Author Library and the
			-- guides too), so the results now empty.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_search ("love")
			assert_true ("results", app.harness_results_count > 0)
			app.harness_close_results
			assert_integers_equal ("Close in Study empties them", 0, app.harness_results_count)
			app.shut_down
		end

	test_results_dot_follows_closing
			-- Risk 6: the results dot stayed after the results were closed.
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (False)
			app.harness_search ("love")
			assert_true ("the dot with results", app.harness_results_marked)
			app.harness_close_results
			assert_false ("no dot once closed", app.harness_results_marked)
			app.shut_down
		end

feature -- Phase 2

	test_entering_study_fills_the_study_panes
		local
			app: BIB_GUI_APP
		do
			app := new_window
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
			app := new_window
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
			app := new_window
			l_dark := not app.harness_window_dark
			app.harness_theme_swapped_by_windows (l_dark)
			assert_true ("the window wears it", app.harness_window_dark = l_dark)
			assert_true ("and the switch shows it", app.harness_dark_switch_on = l_dark)
			app.shut_down
		end

	test_an_incipit_link_shows_side_by_side
			-- Larry, 2026-11-12: "how can I get to the NT ref, and can I see them side by side?"
		local
			app: BIB_GUI_APP
		do
			app := new_window
			app.harness_state.set_study (True)
			app.harness_go_to (40, 27, 46)
			app.harness_show_incipit
			assert ("Matthew 27:46 draws on the Old Testament", app.harness_incipit_count > 0)
			app.harness_show_pair (1)
			assert ("the Side by side window opens", app.harness_pair_open)
			assert_integers_equal ("a note, then three verses either side of the pair", 8, app.harness_pair_rows)
			assert ("the Old Testament verse, on the pair's row", app.harness_pair_has_text (5, 1))
			assert ("Matthew 27:46, on the same row", app.harness_pair_has_text (5, 2))
			app.harness_toggle_pair_layout
			assert ("the switch shows over and under", app.harness_pair_over_under)
			assert_integers_equal ("a note, the Old Testament place and its seven verses, the New's and its seven", 17, app.harness_stack_rows)
			assert ("the Old Testament verse, under its place", app.harness_stack_has_text (6))
			assert ("Matthew 27:46, under its place", app.harness_stack_has_text (14))
			app.harness_toggle_pair_layout
			assert ("the switch shows side by side again", not app.harness_pair_over_under)
			app.harness_show_pair (1)
			assert ("a second Side by side replaces the first", app.harness_pair_open)
			app.harness_close_pair
			assert ("closed", not app.harness_pair_open)
			app.shut_down
		end

	test_each_workspace_keeps_its_east_width
		local
			app: BIB_GUI_APP
			l_reading: REAL_64
		do
			app := new_window
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
			app := new_window
			app.harness_state.set_study (True)
			assert_strings_equal ("before: Focus", "Focus", app.harness_focus_label)
			app.harness_toggle_focus
			assert_strings_equal ("focused: Sides back", "Sides back", app.harness_focus_label)
			app.harness_toggle_focus
			assert_strings_equal ("and back", "Focus", app.harness_focus_label)
			app.shut_down
		end

feature {NONE} -- The window

	new_window: BIB_GUI_APP
			-- A fresh window; the last one shut down first (a failed assertion skips a test's own
			-- `shut_down', and its open user.db then refused the next window: "Permission denied").
		do
			if attached last_window as al_last then
				al_last.shut_down
			end
			create Result.make_harness
			last_window := Result
		end

	last_window: detachable BIB_GUI_APP
			-- The window the last test built.

feature {NONE} -- Carrying helpers

	row_of (a_tree: SW_TREE [BIB_FAVORITE_NODE]; a_label: READABLE_STRING_GENERAL): INTEGER
			-- The visible row showing `a_label'; 0 = none.
		local
			i: INTEGER
		do
			from i := 1 until i > a_tree.visible.count or Result > 0 loop
				if a_tree.label_of (a_tree.visible.i_th (i).node).starts_with_general (a_label) then
					Result := i
				end
				i := i + 1
			end
		end

	row_x (a_tree: SW_TREE [BIB_FAVORITE_NODE]): INTEGER
			-- Over a row's label, past any arrow.
		do
			Result := (a_tree.x + 60.0).truncated_to_integer
		end

	row_y (a_tree: SW_TREE [BIB_FAVORITE_NODE]; a_row: INTEGER): INTEGER
			-- The middle of row `a_row' (scrolled).
		do
			Result := (a_tree.y + (a_row - 0.5) * a_tree.Row_h - a_tree.scroll_y).truncated_to_integer
		end

end
