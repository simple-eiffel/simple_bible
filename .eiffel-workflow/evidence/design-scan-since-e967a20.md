# Design Scan (diff mode): simple_bible since e967a20
# Subjects: gui_app/bib_gui_app.e (the only file changed in src, cli, gui_app, build, build_app)
# Compared against: src/, cli/, gui_app/, build/, build_app/
# Mode: read-only; nothing compiled

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A5/A1/A6) | 3 | 1 | 2 | 0 |
| Drift (D1) | 1 | 1 | 0 | 0 |
| Tokens/tips (T1/T2) | 2 | 0 | 1 | 1 |
| MI/other | 1 | 0 | 0 | 1 |
| **Total** | **7** | **2** | **4** | **2** (see note on counting below) |

Counting: HIGH 2, MEDIUM 4, LOW 2 (8 rows below; finding 5 is split into 5a MEDIUM and 5b LOW).

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | A5 | Remove/Restore/row-click exists three times (notes, highlights, bookmarks): extract a deferred "removable list panel" mixin |
| 2 | HIGH | D1 | Shared stale-selection defect in all three copies after Remove (one fix would fix all; as separate copies it must be fixed three times) |
| 3 | MEDIUM | A1/A5 | `on_bookmark_row` and `on_highlight_row` are line-for-line identical (hub decode then go_to); hub-to-place wrappers duplicated |
| 4 | MEDIUM | A5 | The reverse copy, building a hub id from the verse read, appears three times |
| 5a | MEDIUM | T1 | Pill T1 is anchored on `navigator_tree`, which now lives only in the Books tab |
| 5b | LOW | T2 | Pill T1 text and Go menu enablement vs Simple layout (see detail) |
| 6 | LOW | M4 | `bib_gui_app.e` is a 2,700-line monolith; the mixin in finding 1 is also the first slice |
| 7 | MEDIUM | other | Bookmark add allows unlimited duplicates of one verse (contract permits, UI does not warn) |

## Detailed Findings

### Finding 1: Remove/Restore panel logic three times (A5)
**Priority:** HIGH
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e)
**Description:** Each of notes, highlights, bookmarks owns the same cluster: a rows list, a "last removed id" integer (0 means none), a Remove button and a Restore button, a "select row, enable Remove" handler, a remove routine that records the id only after a successful write, and a restore routine guarded by `is_deleted`. Three copies, with three naming schemes (`last_deleted_note` versus `last_removed_highlight` and `last_removed_bookmark`).
**Evidence:**
- Bookmarks: state 1407-1411; `fill_bookmarks` 1416-1432; `on_bookmark_row` 1450-1464; `remove_bookmark` 1466-1479; `restore_bookmark` 1481-1493.
- Highlights: state 1671-1679; `fill_highlights` 1702-1728; `on_highlight_row` 1771-1785; `remove_highlight` 1787-1801; `restore_highlight` 1803-1815.
- Notes: state 1545-1549; `on_note_selected` 1631-1635; `delete_note` 1637-1653; `restore_note` 1655-1667.
- `remove_bookmark` (1469-1478) and `remove_highlight` (1790-1799) differ only by kind constant (`Kind_bookmark` versus `Kind_highlight`), the grid they read, the refresh call (`fill_bookmarks` versus `open_reading`) and the toast text. `restore_bookmark` (1484-1492) and `restore_highlight` (1806-1814) differ in the same four ways.
- Wiring is also tripled: 352-359 (click and select agents).
**Suggested Action:** Deferred mixin, inherited side by side by BIB_GUI_APP (Larry's rule), for example BIB_REMOVABLE_LIST_PANEL with these deferred decisions: `removable_kind: INTEGER`, `removable_store_open: BOOLEAN`, `selected_removable_id: INTEGER_64` (0 when none), `refresh_after_change`, `removed_toast_text`; and these effective features: `last_removed_id`, `remove_selected`, `restore_last`, `note_removed`, with the postconditions "last_removed_id > 0 implies the store reports it deleted" and "write_error /= Void implies last_removed_id unchanged". Because the GUI app needs three instances, either three small helper objects held in the mixin (A6: each instance carries its own `last_removed_id` and buttons) or a generic `BIB_REMOVABLE_PANEL [G -> BIB_USER_ITEM]` helper owned by the mixin. Notes use `note_store` rather than `user_store` and select by index, so notes fit only after the two deferred decisions `store_is_writable` and `selected_removable_id` are added; they can be migrated last.
**Effort:** about 6 features extracted, 3 copies collapsed (net minus roughly 90 lines)

### Finding 2: Drift among the three copies (D1, always HIGH)
**Priority:** HIGH
**Category:** D1
**Classes:** BIB_GUI_APP
**Description:** The copies agree on the important rules (record the removed id only after a successful write: 1474, 1796 with its "scan 42" comment at 1795, 1648; guard Restore with `is_deleted`: 1484, 1806, 1658; toast on Remove, none on Restore). Behavioral divergences found:
1. Refresh after Restore/Remove: highlights call `open_reading` (1797, 1812) because the reading view paints washes; bookmarks and notes call their own `fill_*` (1475, 1490, 1649, 1664). This difference is legitimate, not a defect; a mixin must keep it as a deferred `refresh_after_change`.
2. Guard: notes use `note_store.is_writable` (1643, 1658); highlights and bookmarks use `user_store.is_open` (1469, 1484, 1790, 1806). Likely equivalent today, but the two predicates can diverge.
3. Selection source: notes use `notes_list.selected_index` (1642); the other two use `grid.selected_object` (1469, 1790).
4. Naming: `last_deleted_note` (1548) versus `last_removed_*` (1410, 1678).
**Live defect shared by all three grid copies (needs the fix once the code is shared):** `SW_DATA_GRID.set_rows` keeps the selected row number when it is still within range (simple_widgets/src/sw_data_grid.e:151-160, `selected_model` only reset when greater than the count) and `select_model_row` calls the select action only when the row number CHANGES (sw_data_grid.e:249-256). After Remove, `fill_bookmarks` (1430) and `fill_highlights` (1726) disable Remove but the same row number stays selected and now points at the NEXT item. Clicking that row again does not fire `on_bookmark_row` (1450) or `on_highlight_row` (1771), so it neither opens the verse nor re-enables Remove until a different row is clicked first. This was reasoned from the grid source, not run; confirm in the GUI before treating it as proven. Which copy should win: none has the fix; the shared panel should clear the grid selection when it refreshes (needs a grid feature such as `select_model_row (0)`, which the grid's precondition 0 allows at sw_data_grid.e:244-246).
**Suggested Action:** Fix once inside the mixin from finding 1 rather than three times.
**Effort:** 1 feature (plus the mixin)

### Finding 3: Row-click decode and place wrappers duplicated (A1/A5)
**Priority:** MEDIUM
**Classes:** BIB_GUI_APP; BIB_HIGHLIGHT and BIB_BOOKMARK (src/user/*.e, both inherit BIB_USER_ITEM)
**Evidence:**
- `on_bookmark_row` 1456-1463 and `on_highlight_row` 1777-1784 are the same body: create `BIB_HUB_ID`, read `hub_id`, `is_valid_hub`, `go_to (book_of, chapter_of, verse_of)`, enable Remove.
- `bookmark_place` 1495-1499 and `highlight_place` 1817-1821 are the same one-line wrapper of `hub_place` (1823-1835).
- `draw_note_gutter` 1840-1849 decodes a hub id a third time (valid check at 1844, `verse_of` at 1847); it needs only the verse number, so it is a smaller copy.
**Suggested Action:** (a) A single `go_to_hub (a_hub: INTEGER_64)` (validity check inside) used by both row handlers and by any note-row click later. (b) One `item_place (a_item: BIB_USER_ITEM): STRING_32` agent target for both grid columns (539-540), since `hub_id` is declared in the shared parent BIB_USER_ITEM (verify the feature is on the parent: both classes call `hub_id` and both inherit it). The place-name logic itself is already in one place (`hub_place`, 1823), so there is no remaining copy of hub-to-text besides the wrappers and the gutter's verse-number decode.
**Effort:** 2 features

### Finding 4: Hub id built from the verse read, three times (A5)
**Priority:** MEDIUM
**Evidence:** `(create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse)` at 1440 (bookmark), 1601 (note) and 1761 (highlight). Each is preceded by its own `reading_verse > 0` guard (1437, 1600, 1760) and each has its own toast for the guard.
**Suggested Action:** `reading_hub: INTEGER_64` (precondition `reading_verse > 0`, postcondition `is_valid_hub (Result)`) in the same mixin or in BIB_GUI_APP next to `place_text` (2649).
**Effort:** 1 feature

### Finding 5a: Pill T1 anchored on a widget inside one tab (T1 token/tip)
**Priority:** MEDIUM
**Evidence:** line 2228 anchors T1 on `navigator_tree`; after the change the tree is the `Books` page only (1386, 1395) and `Bookmarks` is a second page (1396, 1401). With the Bookmarks tab selected the anchor widget is hidden; whether the pill follows a hidden anchor is not verified. The tip text itself is accurate (Books, Bookmarks, Ctrl+D, click, Remove and Restore all exist). Consider anchoring on `navigator_tabs` (declared 1401), which is visible on both tabs.
**Suggested Action:** change the anchor to `navigator_tabs`; re-check the snapshot with "bookmarks" (line 269-271).

### Finding 5b: Other tips and accelerator (LOW)
**Evidence:**
- Ctrl+D: registered once (589, `Key_d` 2740) among accelerators 580-589 (Ctrl+Shift+P, Alt+Left, Alt+Right, Ctrl+L, Ctrl+F, Ctrl+plus, Ctrl+minus, Ctrl+M, Ctrl+I). No conflict inside the app. Not checked: whether the focused text boxes (SW_TEXT_BOX, notes box) swallow Ctrl+D before the window accelerator sees it.
- The tip for T2 (2229) is unchanged by this diff; no tip was found that names a control the diff removed.
- `bookmark_verse` is wired to Ctrl+D in both layouts (589) but `fill_bookmarks` is only called from the study branch of `open_reading` (1008-1014) and the list is only shown in the navigator pane; in the Simple layout the toast "Bookmarked ..." (1445) appears with no visible list. Verify the Simple layout shows no Bookmarks tab; if so the Go item (639) is still correct but the feedback is a toast only.

### Finding 6: Monolithic class (M4)
**Priority:** LOW
**Evidence:** bib_gui_app.e runs past line 2740 (`Key_d` constant at 2740) and holds notes, highlights, bookmarks, interlinear, commentary, lexicon and pills. Finding 1's mixin is the cheapest first slice.

### Finding 7: Duplicate bookmarks allowed
**Priority:** MEDIUM (behavior, not duplication)
**Evidence:** `bookmark_verse` 1434-1448 adds without checking an existing live bookmark of the same hub id; `add_bookmark` contract (src/user/bib_user_store.e:200-209) says the count grows by exactly one, so repeated Ctrl+D stacks identical rows. Also the bookmark stores a text label (1440, `place_text` at the time) that the grid never shows; the Verse column recomputes from the hub id (1495-1499). The stored label can drift from what the list shows if the version or book names change.
**Suggested Action:** decide with Larry whether Ctrl+D toggles or warns; either way keep it in the shared panel.

## Recommended Order

1. Finding 2 live defect: confirm in the GUI, then fix (once, ideally inside Finding 1's mixin).
2. Finding 3 and 4: two tiny helpers (`go_to_hub`, `item_place`, `reading_hub`), no new class needed, immediate duplication drop.
3. Finding 1: the mixin, migrating bookmarks and highlights first, notes last (store and selection differ).
4. Finding 5a: one-word anchor change, with a snapshot check.
5. Finding 7 after Larry's decision.

Nothing is extracted without Larry's word.
