# Design Scan (diff mode): simple_bible since 8ba11bb
# Date: 2026-10-28
# Subjects: gui_app/bib_gui_app.e (feature clause "Right-click menus and panes", lines 3181-3650), gui_app/bib_item_list_panel.e (set_menu_items, offer_menu, remove_id)
# Compared against: gui_app/, src/, cli/
# Read-only scan: no source modified, nothing compiled.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction | 7 | 3 | 3 | 1 |
| MI | 1 | 0 | 0 | 1 |
| Generics | 1 | 0 | 0 | 1 |
| **Total** | **9** | **3** | **3** | **3** |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | A5/D1 | copy_verse and copy_hub_verse repeat one clipboard format with drifted behavior; copy_verse bypasses copy_to_clipboard |
| 2 | HIGH | A5 | place_hub re-implements BIB_HUB_ID's range rule outside BIB_HUB_ID |
| 3 | HIGH | D1/contract gap | delete_journal_row acts on the previous selection when its index is out of range; sibling delete_note_at is correct |
| 4 | MEDIUM | A5 | Four *_menu routines repeat one shape (verse row + pane_menu); most menu routines ignore a_px/a_py |
| 5 | MEDIUM | A5/contract gap | The row-index guard is written about 10 times; index commands guard silently instead of stating a precondition |
| 6 | MEDIUM | A5/A6 | Hub decode (create BIB_HUB_ID, is_valid_hub, book_of/chapter_of/verse_of) repeated at about 6 sites |
| 7 | LOW | A5 | start_answer / start_prayer share a select-then-start sequence; start_answer speaks even when the id is missing |
| 8 | LOW | M2 | One agent, listed_menu_items, serves six panels and type-tests for BIB_PRAYER |
| 9 | LOW | G2 | BIB_ITEM_LIST_PANEL.menu_items is PROCEDURE [SW_MENU, BIB_LISTED], not [SW_MENU, G] |

## Detailed Findings

### Finding 1: Clipboard verse formatting written twice, and the copies have drifted
**Priority:** HIGH  **Category:** A5 / D1
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e)
**Evidence:**
- gui_app/bib_gui_app.e:1143-1155 copy_verse: loops reading_verses, builds `ic.display_text + " (" + place_text (...) + " " + reading_version + ")"`, calls `(create {SW_CLIPBOARD}).set_text (l_text)` directly (line 1151), reports with `window.toast ("Verse copied.", 2)`.
- gui_app/bib_gui_app.e:3424-3433 copy_hub_verse: builds the same `text + " (" + hub_place + " " + reading_version + ")"`, calls copy_to_clipboard, reports with `say (...)`.
- gui_app/bib_gui_app.e:3262-3265 copy_to_clipboard is the new single clipboard routine, yet copy_verse (1151) does not use it. grep SW_CLIPBOARD over gui_app, src, cli finds exactly these two call sites.
- gui_app/bib_gui_app.e:3247-3260 copy_chapter writes a third clipboard string in its own format (reference and version, then numbered verses).
**Drift:**
- Feedback channel: copy_verse says "Verse copied." through window.toast; copy_hub_verse says the same words through say. The Edit menu (line 814) and the right-click menu (line 3210 verse_menu) copy the same verse with different feedback.
- copy_verse silently does nothing when the verse read is not in reading_verses; copy_hub_verse says "X is not in <version>".
- Winner: copy_hub_verse's behavior (says why on failure). The verse read is already `reading_hub` (line 2537, requires reading_verse > 0), so copy_verse can become `if reading_verse > 0 then copy_hub_verse (reading_hub) end`.
**Suggested Action:** route copy_verse through copy_hub_verse; one `cited (a_text, a_hub): STRING_32` formatter; one `place_with_version` for the " (" + place + " " + version + ")" text, which also appears at 1285, 3430 and 4160.
**Effort:** 1 feature rewritten, 1 extracted.

### Finding 2: place_hub duplicates BIB_HUB_ID's validity rule
**Priority:** HIGH  **Category:** A5
**Classes:** BIB_GUI_APP, BIB_HUB_ID (src/user/bib_hub_id.e)
**Evidence:**
- gui_app/bib_gui_app.e:3411-3422 place_hub: `create l_hub`, then `a_book >= 1 and a_book <= l_hub.Max_part and a_chapter ... and a_verse ...` before `l_hub.hub_id`.
- src/user/bib_hub_id.e:14-19 hub_id's precondition states the same three range clauses; the rule exists in BIB_HUB_ID only as a precondition, so a client that wants to test it must copy it.
- gui_app/bib_gui_app.e:2708 repeats a partial copy (`a_book >= 1 and a_book <= Max_part and a_chapter >= 1 and a_chapter <= Max_part`).
**Suggested Action:** add to BIB_HUB_ID `is_place (a_book, a_chapter, a_verse): BOOLEAN` (hub_id's precondition then uses it) and `hub_of_place (a_book, a_chapter, a_verse): INTEGER_64` (0 when not a place) with `ensure Result = 0 or is_valid_hub (Result)`. Delete place_hub from the application class; fix line 2708. If Max_part ever changes, one class moves.
**Effort:** 2 features in BIB_HUB_ID, 1 removed from BIB_GUI_APP, 2 call sites.

### Finding 3: delete_journal_row can delete the wrong entry; delete_note_at is the right shape
**Priority:** HIGH  **Category:** D1 / contract gap
**Classes:** BIB_GUI_APP
**Evidence:**
- gui_app/bib_gui_app.e:3533 delete_journal_row (a_model) calls open_journal_row (3524-3531), then delete_journal_entry. open_journal_row guards `a_model >= 1 and a_model <= journal_rows.count` silently (line 3527); with a bad index it selects nothing.
- gui_app/bib_gui_app.e:2478-2491 delete_journal_entry deletes `journal_entry_id`, the entry currently in the boxes. With a stale or bad `a_model` the PREVIOUS selection is deleted.
- Contrast gui_app/bib_gui_app.e:1987-1993 delete_note_at (a_index): it works on the item at that index itself, the shape the verse-note menu already uses.
- Neither delete_journal_row nor open_journal_row has a `require`; the only protection is journal_menu (3509-3521) checking the same range at line 3515 when the menu is built. A menu built before the list refreshes holds the old index.
**Suggested Action:** add `require valid_row: a_model >= 1 and a_model <= journal_rows.count` to open_journal_row, delete_journal_row, show_tag_row (3557) and a found-check to start_answer (3583); make delete_journal_row delete by the row's id as delete_note_at does, not through the selection side effect.
**Effort:** 4 routines.

### Finding 4: The menu routines repeat one shape
**Priority:** MEDIUM  **Category:** A5 (one generic routine or a table of agents)
**Classes:** BIB_GUI_APP
**Evidence:**
- Shape "if attached grid.context_object as al_row then verse_items (a_menu, place_hub (...)) end; pane_menu (panel, a_menu, a_px, a_py)": cross_ref_menu (3455), verse_hit_menu (3474), place_menu (3483); history_menu (3501) is the same without the pane item. Only the row-to-hub conversion and the panel differ.
- Of the 16 `*_menu` agents wired in wire_menus (3183-3207), only verse_menu (3210) uses a_px/a_py (cell_at); the rest take them to satisfy the agent signature and pass them to pane_menu.
- The widget side differs by accessor name: context_object (cross_ref_menu, analysis_menu, choice_menu ...), context_item (notes_menu 3378), context_model (journal_menu 3509, tag_name_menu 3540), context_token (interlinear_menu 3305), context_node (navigator_menu 3356).
**Suggested Action:** one `verse_row_menu (a_menu, a_hub, a_panel)` (a_panel = 0 for none) doing verse_items then pane_menu; each wired agent becomes a one-line converter. Larger: a deferred SW_CONTEXT_ROW mixin in simple_widgets giving the five accessors one name (inherited side by side with the existing mixins); that is outside this project, for Larry's word.
**Effort:** 4 routines collapsed here; mixin is a separate item.

### Finding 5: The row-index guard is repeated; index commands guard silently
**Priority:** MEDIUM  **Category:** A5 / contract gap
**Classes:** BIB_GUI_APP, BIB_ITEM_LIST_PANEL
**Evidence:** `x >= 1 and x <= list.count` at gui_app/bib_gui_app.e:3218 (verse_menu), 3311 (interlinear_menu), 3384 (notes_menu), 3515 (journal_menu), 3527 (open_journal_row), 3547 (tag_name_menu), 3560 (show_tag_row), and, older, 1959, 1967, 1993, 2785, 3754, 3918, 4124; gui_app/bib_item_list_panel.e:121 (on_row). All are silent `if` tests, none a precondition.
- gui_app/bib_item_list_panel.e:136-152 remove_id has no `require` (the body tests `a_id > 0 and store.is_open`); set_menu_items (78-86) has only a trivial postcondition and does not require that the grid supports menus.
**Suggested Action:** one query `is_row (a_index: INTEGER; a_count: INTEGER): BOOLEAN` (or a shared deferred ancestor for panels) used in `require` of the index commands and in the menu builders; silent guards stay only where a widget event can arrive out of range.
**Effort:** about 10 sites.

### Finding 6: Hub decode repeated
**Priority:** MEDIUM  **Category:** A5 / A6
**Classes:** BIB_GUI_APP, BIB_HUB_ID, BIB_VERSE_KEY
**Evidence:** `create l_hub` followed by is_valid_hub and book_of/chapter_of/verse_of at gui_app/bib_gui_app.e:1814, 2747-2754 (go_to_hub), 2766-2775 (hub_place), 2783-2790, and the new verse_text_at_hub (3435-3453). verse_text_at_hub decodes the hub with book_of/chapter_of/verse_of and then re-packs with `l_keys.packed_place` (3448), a round trip; BIB_HUB_ID and BIB_VERSE_KEY both inherit BIB_PLACE_PACKING (src/user/bib_place_packing.e), so the packed place is already what the hub is.
- verse_text_at_hub is also used by show_memory_verse (2317); it needs only bible.text_reader and reading_version, not the application.
**Suggested Action:** a once-attribute `hub_ids: BIB_HUB_ID` (stateless; `create l_hub` is repeated at every call), `BIB_HUB_ID.place_key (a_hub)`, and consider moving verse_text_at_hub to the text reader as `verse_at_hub (version, hub)`.
**Effort:** about 6 sites; mechanical.

### Finding 7: Select-then-start sequences
**Priority:** LOW  **Category:** A5
**Classes:** BIB_GUI_APP
**Evidence:** start_answer (3583-3597) loops for the prayer, selects it, and says "Write how it was answered" even when the loop finds nothing. start_prayer (3284-3295) and start_answer both do `prayer_tabs.select_tab (1)` then `start_in_notes (Prayer_tab, box)`. `dock.restore_maximized` appears at 1547, 3275 and 3617 with pane_menu (3368) choosing between it and maximize.
**Suggested Action:** `start_in_prayers (a_box)` for the two callers; start_answer silent when the id is not found.
**Effort:** 2 routines.

### Finding 8: One menu agent serves six panels with a type test
**Priority:** LOW  **Category:** M2
**Evidence:** wire_menus (3183-3207) wires listed_menu_items for bookmarks, highlights, tagged, open prayers, answered prayers and memory; listed_menu_items (3573-3581) type-tests `attached {BIB_PRAYER} a_item`. The prayer-only item belongs to the prayer panels, not inside the shared routine. (The test is also true for answered prayers' `is_answered` guard.)
**Suggested Action:** wire a `prayer_menu_items` agent for prayer_open_panel; leave the rest on listed_menu_items.
**Effort:** 1 feature.

### Finding 9: Panel menu callback is not typed by G
**Priority:** LOW  **Category:** G2
**Evidence:** gui_app/bib_item_list_panel.e:17 `BIB_ITEM_LIST_PANEL [G -> BIB_LISTED]` but lines 78 and 189 use `PROCEDURE [SW_MENU, BIB_LISTED]`. Probably deliberate (agents are not contravariant, so a host routine taking BIB_LISTED cannot be given as [SW_MENU, G]); the host needs only hub_id and id. No change unless a host wants G-specific items; then Finding 8's fix would need the typed form.
**Effort:** none now.

## Recommended Order

1. Finding 3 (live risk: wrong entry deleted), small and self-contained.
2. Finding 1 (drift in the clipboard code, fixes the toast/say difference).
3. Finding 2, then Finding 6 (BIB_HUB_ID gains is_place / hub_of_place / place_key; both land in one class).
4. Finding 5, then Finding 4 (row-guard preconditions, then collapse the verse-row menus).
5. Findings 7, 8, 9 only when the area is touched again.

## Not found
- No other clipboard helper in gui_app/, src/ or cli/; no other copy of the BIB_HUB_ID range check in src/ or cli/ (BIB_HUB_ID is used in src/ by pack, reading and user classes only through its own queries).
- Finding 4's widget-side mixin lives in simple_widgets, outside this scan's scope.
