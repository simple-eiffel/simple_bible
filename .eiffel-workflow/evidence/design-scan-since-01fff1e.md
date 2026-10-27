# Design Scan (diff mode): simple_bible, since 01fff1e
# Subjects: gui_app/bib_gui_app.e (the only file changed in src, cli, gui_app, build, build_app since 01fff1e; commits 159501d and c99c842)
# Compared against: src/, cli/, gui_app/, build/, build_app/
# Note: src/user/bib_user_store.e carries the tag engine (commit 27692fb) but is NOT in the diff range; it was read as the comparison base, so findings that involve it are reported through their GUI counterpart.
# Read-only: nothing compiled, no other file modified.

## Summary

| Priority | Count |
|----------|-------|
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 3 |
| **Total** | **8** |

## Findings

| # | Priority | Category | Where | Opportunity |
|---|----------|----------|-------|-------------|
| 1 | HIGH | D1 | gui_app/bib_gui_app.e:1683-1712 vs gui_app/bib_item_list_panel.e (set_rows) | Tag-name grid keeps a stale row number after refill; the scan-43 bug returns in a fourth copy of "list with a chosen item" |
| 2 | HIGH | D1 | src/user/bib_user_store.e:65, 92, 110, 123, 136, 146 | The "live item" filter is spelled six ways; contracts compare counts across the spellings |
| 3 | MEDIUM | A5 | src/user/bib_user_store.e:90-98, 108-114, 493-506 | Three copies of the item row reader (select four columns, create, mark_stored, extend) |
| 4 | MEDIUM | A5 | gui_app/bib_gui_app.e:1442-1455, 1720-1740, 1833-1852 | "Type a label, press a button, write an item" written three times, plus the three fill features |
| 5 | MEDIUM | A5/A6 | gui_app/bib_gui_app.e:1448, 1731, 1844 (and 1564) | The reading position to hub identity expression is repeated four times |
| 6 | LOW | A1 | gui_app/bib_gui_app.e:1458-1462, 1761-1765, 1854-1858 | Three identical `place` wrappers all calling hub_place |
| 7 | LOW | T2 | gui_app/bib_gui_app.e:2291 | Design-pill tip: missing comma, and "Lists: click to read" is wrong for the tag-name list |
| 8 | LOW | D1 check | gui_app/bib_gui_app.e:1722-1727 vs 1838-1842 vs 1444-1453 | Empty-label and error handling compared: no behavioral drift, only wording and success feedback differ |

## Detailed Findings

### Finding 1: Tag-name grid does not keep its choice on refill (D1, HIGH)
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e), BIB_ITEM_LIST_PANEL (gui_app/bib_item_list_panel.e), SW_DATA_GRID (simple_widgets/src/sw_data_grid.e, read only for this check)
**Description:** The class header of BIB_ITEM_LIST_PANEL records scan 43: "every copy kept a row number selected after Remove - pointing at the next item, its click doing nothing. The choice follows the item now, not its row." The panel's `set_rows` finds the chosen item by id and calls `grid.select_model_row (l_index)` (bib_item_list_panel.e, set_rows). The new tag-name grid is a hand-written copy without that fix: `fill_tags` (bib_gui_app.e:1683-1712) calls `tag_names_grid.set_rows (tag_name_rows)` at line 1691, then only recomputes `chosen_tag` by name (1692-1697) and never selects the matching row. SW_DATA_GRID.set_rows only clamps the old number (sw_data_grid.e:159-160: `if selected_model > rows.count then selected_model := 0`). The tags are ordered `label COLLATE NOCASE` (bib_user_store.e:123), so tagging a verse with a new tag that sorts before the chosen one shifts every row: the highlighted row is then a different tag from `chosen_tag`, and the verses list below shows the other tag.
**Evidence:**
- bib_gui_app.e:1691 set_rows with no select call after it; 1742-1748 `on_tag_name` is the only place the choice is made.
- bib_gui_app.e:1737 `chosen_tag := l_tag` then `fill_tags`: after tagging, the grid does not highlight the tag just chosen.
- bib_item_list_panel.e set_rows: the id search and `select_model_row`, with `is_refilling` guarding the select action.
**Winning behavior:** the panel's (the choice follows the item). I did not run the window to observe the wrong highlight; the finding rests on reading both code paths.
**Suggested Action:** after `set_rows` in `fill_tags`, find the index of `chosen_tag` in `tag_name_rows` and select it with a guard against re-entry (`on_tag_name` calls `fill_tags`, so an unguarded select loops). Better, see finding 4: let one class own "list, chosen item, refill".
**Effort:** 1 feature changed (fill_tags) plus a guard attribute.

### Finding 2: The "live item" filter is spelled six ways (D1, HIGH)
**Classes:** BIB_USER_STORE (src/user/bib_user_store.e)
**Description:** Six readers over `user_item` each restate which rows count as live, and the spellings differ:
- `item_count` (line 65): `kind = ? AND hub_id = ? AND deleted = 0`. No `hub_id > 0`, no `label <> ''`.
- `highlights_between` (92): `deleted = 0 AND hub_id > 0 AND label <> ''`.
- `bookmarks` (110): `deleted = 0 AND hub_id > 0`. No `label <> ''`.
- `tag_counts` (123): `deleted = 0 AND label <> '' AND hub_id > 0`.
- `assignments_tagged` (136) and `tags_for` (146): same filter, and then `tag_rows` (src/user/bib_user_store.e:497-503) filters AGAIN in Eiffel (`hub_id > 0 and not label.is_empty`), which `highlights_between` and `bookmarks` do not.
The postconditions tie the spellings together: `highlights_for` ensures `Result.count = item_count (Kind_highlight, ...)` (line 79) and `tags_for` ensures `Result.count = item_count (Kind_tag, ...)` (line 149). They hold only while no row has an empty label or hub_id 0. The table has no CHECK constraint (create_schema: `label TEXT NOT NULL`, `hub_id INTEGER NOT NULL`), so a restored or imported backup with such a row makes the contract fail in a test build while the lean build silently shows fewer items than `item_count` reports.
**Suggested Action:** one SQL fragment constant (for example `Live_item_where`) used by `item_count` and every reader, and one decision on whether an empty label hides a bookmark (today it does not). Pairs with finding 3.
**Effort:** 6 SQL strings, 1 constant.

### Finding 3: Three copies of the item row reader (A5, MEDIUM)
**Classes:** BIB_USER_STORE
**Evidence:**
- src/user/bib_user_store.e:90-98 `highlights_between`: query, `create l_highlight.make (hub_id, label)`, `mark_stored (item_id, time_of (created_at))`, `extend`.
- src/user/bib_user_store.e:108-114 `bookmarks`: same shape with BIB_BOOKMARK.
- src/user/bib_user_store.e:493-506 `tag_rows`: same shape with BIB_TAG_ASSIGNMENT, and the only one factored into a reusable feature.
**Description:** All three select the same four columns (`item_id, hub_id, label, created_at`) and finish with the same two calls. Only the creation call differs. A generic `items_of (a_sql, a_arguments, a_make: FUNCTION [INTEGER_64, STRING_32, G]): ARRAYED_LIST [G]` with `G -> BIB_USER_ITEM`, or a deferred `new_item (a_hub_id, a_label)` in a small reader helper, removes two copies and keeps `tag_rows`' callers unchanged. A future kind (E04 Journal, E06 Prayer) would otherwise be a fourth copy.
**Effort:** 3 features become one plus three one-line callers.

### Finding 4: "Type a label, press a button, write an item" times three (A5, MEDIUM)
**Classes:** BIB_GUI_APP, BIB_ITEM_LIST_PANEL
**Evidence:**
- gui_app/bib_gui_app.e:1833-1852 `add_highlight`: trim the box (1837-1839), empty check with a toast (1840-1841), `store.is_open and reading_verse > 0` (1843), store call (1844), `write_error` message or clear box and refresh (1845-1850).
- gui_app/bib_gui_app.e:1720-1740 `tag_verse`: the same sequence, with `say` for messages and `fill_tags` as the refresh.
- gui_app/bib_gui_app.e:1442-1455 `bookmark_verse`: the same guard and `write_error` branch; the label is the place text, so there is no box.
- The three refresh features repeat a second pattern: `fill_highlights` (1795-1824), `fill_bookmarks` (1427-1440), `fill_tags` (1683-1712) each do "store open? set_rows else set empty list; heading text from `rows.is_empty`; verse label from `reading_verse > 0`; enable the button from `is_open and reading_verse > 0`".
**Description:** BIB_ITEM_LIST_PANEL already owns the right half of the pattern (Remove, Restore, chosen item, error telling) after scan 43 removed that copy. The left half (add) and the heading/enabling are the next candidates. Following the "deferred mixins side by side" rule: a small deferred ancestor (for example BIB_ITEM_ADDING with deferred `new_item (a_hub_id: INTEGER_64; a_label: STRING_32): G` and `store_item (a_item: G)`) that the panel inherits next to its current role, owning `label_box`, `add_button`, the trim and empty message, the write-error branch and the clear-and-refresh. BIB_GUI_APP would pass the reading position in (`set_target (a_hub_id)`, `a_hub_id = 0` meaning none), and the panel would own the `button.set_enabled` rule too. A sibling is the alternative if bookmark (no box) should not carry a box; a deferred hook `label_for_add` returning the box text or the place text covers both.
**Effort:** about 6 features move (`add_*`, three `fill_*` tails, enabling), three call sites shrink to one line each.
**Suggested Action:** /eiffel.abstract, on Larry's word.

### Finding 5: Reading position to hub identity, four times (A5/A6, MEDIUM)
**Classes:** BIB_GUI_APP
**Evidence:** `(create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse)` at gui_app/bib_gui_app.e:1448 (bookmark), 1564 (note), 1731 (tag), 1844 (highlight).
**Description:** One query `reading_hub: INTEGER_64` (0 when `reading_verse = 0`) would remove the repeated creation and give finding 4's panel its single input. Side benefit: `reading_verse > 0` stops being re-tested in `fill_*`, `add_*` and the enabling rules.
**Effort:** 1 query, 4 call sites.

### Finding 6: Three identical `place` wrappers (A1, LOW)
**Classes:** BIB_GUI_APP
**Evidence:** `bookmark_place` (gui_app/bib_gui_app.e:1458-1462), `tag_place` (1761-1765), `highlight_place` (1854-1858) each have the comment `"Jude 1:6"` and the body `Result := hub_place (a_x.hub_id)`.
**Description:** All three item types inherit BIB_USER_ITEM (which declares `hub_id`; src/user/bib_tag_assignment.e shows `inherit BIB_USER_ITEM`). One `item_place (a_item: BIB_USER_ITEM)` would serve every list. Caution: an agent over a BIB_USER_ITEM argument is `FUNCTION [TUPLE [BIB_USER_ITEM], STRING_32]`; whether SW_GRID_COLUMN [BIB_TAG_ASSIGNMENT] accepts it needs a compile to know, so the safer form is to let the panel build its own "Verse" column (it already knows `G -> BIB_USER_ITEM` and the grid), which also removes `bookmark_place`, `tag_place` and `highlight_place` from BIB_GUI_APP. Not verified by compiling (read-only scan).
**Effort:** 3 features removed, one added in the panel.

### Finding 7: Design-pill tip T2 (LOW)
**Evidence:** gui_app/bib_gui_app.e:2291: `... Delete and Restore) Tags (tag the verse read; click a tag for its verses), and Highlights ...`
**Description:** (a) A comma is missing after "Restore)", so "Tags (...)" reads as part of the Verse notes parenthesis. (b) "Lists: click to read; Remove and Restore." is wrong for two of the lists it covers: Verse notes use Delete and Restore (the same sentence says so), and clicking a row in the tag-name list does not read a verse (`on_tag_name`, 1742-1748, only changes `chosen_tag`); only the verses of the chosen tag do (the panel's `on_row`). (c) The highlights part lost "click one to read it" and the "Bible and Parallel tabs" washes survive, which is correct. The tag page's own mechanics (type a tag, press Tag; the first list is the tag names with counts) are accurate in the tip.
**Suggested wording for the tag part:** "Tags (tag the verse read; click a tag for its verses, click a verse to read it; Remove and Restore)".

### Finding 8: D1 check of the three item kinds (LOW, no drift found)
**Evidence compared:**
- Empty label: `tag_verse` (1722-1727) and `add_highlight` (1838-1842) trim with `left_adjust` and `right_adjust`, then refuse an empty text; wording differs ("Name the tag first." vs "Say why first: a highlight is a reason."), which fits the two meanings. `bookmark_verse` has no box; its label is the place text.
- Write error: all three test `user_store.write_error` and speak `al_error.message` (`say` at 1734, `window.toast` at 1447 and 1847; `say` is `window.toast (a_text, 1)` at gui_app/bib_gui_app.e:1860-1864, so the effect is identical). The panel's Remove and Restore use the same error object (bib_item_list_panel.e remove, restore).
- Success feedback differs: the bookmark toasts "Bookmarked ..." (1449-1453); highlight and tag give none beyond the list refresh. Also with no verse read, `bookmark_verse` toasts (1444) while the other two do nothing, but their buttons are disabled in that case (`fill_tags` 1711, `fill_highlights` 1823), so only the keyboard shortcut Ctrl+D needs the message. This is intended, not drift.
- Behavior drift that IS real is in findings 1 and 2.
- Not drift but worth knowing: nothing stops the same tag on the same verse twice (store `tag_verse` has only `count_grown`, bib_user_store.e:247-256); `tag_counts` groups by exact label (123) while ordering by NOCASE, so "Angels" and "angels" are two tags that sort adjacent. A proposal for Larry, not a defect proven by the code.

## Checked and clean
- BIB_ITEM_LIST_PANEL reuse: `tagged_panel` is built exactly like the other two (bib_gui_app.e:163-166), so Remove and Restore for tags add no new copy. Generic constraint `G -> BIB_USER_ITEM` fits BIB_TAG_ASSIGNMENT (src/user/bib_tag_assignment.e).
- `tag_name_text` and `tag_verses_text` (1752-1759) are tiny column getters on an anonymous TUPLE type; a named row class (for example BIB_TAG_COUNT) would remove the long `TUPLE [tag: STRING_32; verses: INTEGER]` spelled at 1658, 1664, 1665, 1742-1759 and in the store (bib_user_store.e:117). LOW, folded into nothing above; mention to Larry only if tags get a third consumer.

## Recommended Order
1. Finding 1 - a live selection defect in new code, one small fix.
2. Finding 2 - contracts that can fail on an imported row; one constant fixes six strings.
3. Findings 5, 4, 6 together - one reading_hub query, then the panel owns add, fill tail and the Verse column (before Journal E04 and Prayer E06 become copies four and five).
4. Finding 3 - the generic row reader, best done with finding 2 in one refactor branch.
5. Finding 7 - a one-line tip fix, can ride with any of the above.
