# Design Scan (diff mode): simple_bible since 8dc45f2
# Subjects: gui_app/bib_gui_app.e (the only file changed in src, cli, gui_app, build, build_app: 178 lines added, 2 removed)
# Compared against: src/, cli/, gui_app/ (build and build_app hold no related code)
# Commits: d6771bd (Highlights in the window), 29267f2 (merge)
# Read-only scan; nothing was compiled.

Note on scope: BIB_USER_STORE (src/user/bib_user_store.e) did not change in this range; it
holds the highlight, bookmark and tag code written earlier and is read here as the counterpart
that the new window code calls, so findings on it are reported where the new code depends on it.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A, D) | 6 | 3 | 2 | 1 |
| MI | 1 | 0 | 1 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| Contracts / pills | 3 | 1 | 1 | 1 |
| **Total** | **10** | **4** | **4** | **2** |

(Finding 1 is both a contract gap and drift, counted once under HIGH.)

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | contract gap | Write failure in add_highlight, remove_item, restore_item violates its own postcondition instead of being reported |
| 2 | HIGH | D1 | Notes Delete/Restore and highlight Remove/Restore are two different rules for one behavior |
| 3 | HIGH | D1 | Two soft-delete rules in the stores (note store: transaction, no kind guard; item store: bare update with kind guard, silent no-op) |
| 4 | HIGH | D1 | Highlight wash is inline in open_reading and missing from the Parallel tab; the blue selection wash covers it |
| 5 | MEDIUM | A1, MI | The one-step "last removed, Restore" state and its button rules should be one mixin |
| 6 | MEDIUM | A5 | time_of and the row-to-item loop are copied in the two stores |
| 7 | MEDIUM | D1 | Three ways to turn a hub id into text or a place; chapter and "every verse" ranges built inline three times |
| 8 | MEDIUM | contract gap | BIB_HIGHLIGHT (and BIB_NOTE) accept hub ids that BIB_HUB_ID calls invalid, so the window re-guards in four places |
| 9 | LOW | contract gap | Two error attributes for one idea (write_error, last_item_error); the new one is not exported |
| 10 | LOW | pill | T2 tip omits Highlights' Remove and Restore buttons and the row click; T3 tip omits the amber wash |

## Detailed Findings

### Finding 1: Failed item writes break the postconditions (HIGH, contract gap)
**Classes:** BIB_USER_STORE (src/user/bib_user_store.e), called from BIB_GUI_APP
**Description:** add_item and set_item_deleted report a failed write in `last_item_error`
(lines 429-436, 445-452). But the public commands' postconditions test `last_error`, which the
class's own comments say is "only for a failed open" (lines 394, 419). After a write failure on
an open store `last_error` is Void, so the guard `last_error = Void implies ...` is true and the
consequent is false: `stored` (194), `count_grown` (195), the bookmark and tag copies (207, 208,
219, 220) and `soft_deleted` / `restored` (242, 253) all fail. In a contract-baked finalized
build that is an exception where a reported error should be; in a contract-free build the failure
is silent, because `last_item_error` is a `feature {NONE}` attribute (418) and the window cannot
read it. The same holds for a silent no-op: `set_item_deleted` filters on `kind` (449) and never
checks that a row changed.
**Evidence:**
- src/user/bib_user_store.e:194-195: `last_error = Void implies a_highlight.is_stored` and the count rule
- src/user/bib_user_store.e:418, 434: `last_item_error` set, never exported
- gui_app/bib_gui_app.e:1613-1615 (add_highlight), 1632-1636 (remove_highlight), 1639-1646 (restore_highlight): none reads any error
- Compare the notes code, which tests `note_store.last_error` and toasts it: gui_app/bib_gui_app.e:1458-1460, 1500-1501, 1515-1516
**Suggested Action:** Make the postconditions say `last_item_error = Void implies ...`, export `last_item_error` (or fold it into one `write_error`, see finding 9), and have the window toast it as the notes code does.
**Effort:** 5 contract lines, 1 export, 3 window commands.

### Finding 2: Two rules for delete and restore in the window (HIGH, D1)
**Classes:** BIB_GUI_APP
**Description:** The notes pair and the highlights pair do the same job and have diverged. The
notes code is the careful copy; the highlights code is the one that should change (the notes
rule should win).
| Step | Notes (delete_note, restore_note) | Highlights (remove_highlight, restore_highlight) |
|------|-----------------------------------|--------------------------------------------------|
| Remember the id | after a successful remove (1503) | BEFORE the remove (1633), so a failed remove leaves Restore enabled for an item that is still live |
| Writable guard | note_store.is_writable (1498, 1513) | user_store.is_open only (1632, 1640) |
| Error shown | toast of the error (1500-1501, 1515-1516) | none |
| Forget the id on restore | only on success (1518) | unconditionally (1642), so a failed restore loses the undo |
| User feedback | "Note deleted. Restore brings it back." (1505) | none |
| Selection source | notes_list.selected_index (1497) | highlights_grid.selected_object (1631), set_rows may clear it (see below) |
**Evidence:** gui_app/bib_gui_app.e:1492-1522 against 1631-1646. In addition on_highlight_row
(1620-1630) calls go_to, which calls open_reading and fill_highlights (983), whose set_rows (1566)
and `remove_highlight_button.set_enabled (False)` (1578) run before line 1631's re-enable (1632); if
set_rows drops the grid selection the enabled Remove button finds `selected_object` Void and does
nothing (not verified: SW_DATA_GRID lives outside this library).
**Suggested Action:** See finding 5 (shared mixin carries the winning rule).
**Effort:** 2 commands per kind.

### Finding 3: Two soft-delete rules in the stores (HIGH, D1)
**Classes:** BIB_DB_NOTE_STORE, BIB_USER_STORE
**Description:** Both set a `deleted` flag and `changed_at`, with different safeguards.
- Note store set_deleted (src/user/bib_db_note_store.e:528-542): begin_transaction, update, `finish` (commit or rollback), error in `last_error`.
- Item store set_item_deleted (src/user/bib_user_store.e:440-453): no transaction, update filtered by `kind`, error in `last_item_error`, no check that a row matched.
- Two `is_deleted` queries: bib_db_note_store.e:118-123 (guarded by `store.is_open`) and bib_user_store.e:164-170 (guarded by `database`, any kind of item).
- The two restore preconditions differ: restore_item requires `is_deleted (a_id)` (bib_user_store.e:249); restore_note has none (bib_db_note_store.e:173).
The behavior to keep: the note store's (atomic, reported through one error attribute); the
item store should gain "a row changed" and the same error seam.
**Suggested Action:** One soft-delete helper (table name, key column, id, flag) in BIB_SQLITE_REPORTING or a new deferred ancestor both stores inherit side by side; one `is_deleted`.
**Effort:** 2 features per store.

### Finding 4: Highlight wash is a copy, not the shared mark, and is incomplete (HIGH, D1)
**Classes:** BIB_GUI_APP
**Description:** `mark_selected_verse` (776-786) is the "one mark the Bible and Parallel tabs
both use" (scan 36). The amber wash was written inline inside open_reading (952-954), so:
1. The Parallel tab (2024) has no highlight wash at all; the tab's verses lose the reader's highlights.
2. In the reading view the amber range (953) and the blue selection range (957) cover the same
cell range; the code's own comment (266) shows the selection wash replaces the amber, so the
verse a reader just clicked, which is exactly the one just highlighted, shows blue, not amber.
3. A highlight made on a verse is shown only after the verse is no longer selected.
**Evidence:** gui_app/bib_gui_app.e:776-786, 952-954, 957, 2024, 266.
**Suggested Action:** A `mark_highlighted_verse` beside `mark_selected_verse`, called by both views, with the selection wash chosen to compose with (or sit under) the amber wash.
**Effort:** 1 feature, 2 call sites.

### Finding 5: One mixin for "remove, remember, restore" (MEDIUM, A1/A6, MI)
**Classes:** BIB_GUI_APP (notes 1403-1441, 1492-1522; highlights 1530-1531, 1578-1579, 1632-1646)
**Description:** `last_deleted_note` and `last_removed_highlight` are the same state with
the same button rule (`restore_x_button.set_enabled (last_x > 0)`, lines 1441 and 1579), and
Journal, Tags, Prayer and Memory (E04 to E07, line 1376-1380) will each add a third to sixth
copy. Proposal: a small deferred class BIB_GUI_UNDO (or a helper object BIB_LAST_REMOVED with
`remember (id)`, `forget`, `can_restore`) that BIB_GUI_APP inherits side by side with its other
roles, together with a deferred `show_error (BIB_ERROR)` seam (the toast) so the careful notes
rule from finding 2 lives once. A step further: BIB_GUI_APP is 2580 lines (M4), and the notes and
highlights panels are separate roles (BIB_GUI_NOTES_PANEL, BIB_GUI_HIGHLIGHTS_PANEL) that would
leave the monolith.
**Suggested Action:** /eiffel.abstract then /eiffel.mi after Larry's word.
**Effort:** 2 state attributes and 4 commands now; more with each later tab.

### Finding 6: time_of and the row-to-item loop copied (MEDIUM, A5)
**Classes:** BIB_USER_STORE, BIB_DB_NOTE_STORE
**Evidence:**
- src/user/bib_user_store.e:455-459 and src/user/bib_db_note_store.e:562-566: identical body `create Result.make_from_iso8601 (a_text.to_string_8)`.
- bib_user_store.e:91-97 (highlights_between) and 109-114 (bookmarks): the same select, build, `mark_stored`, `extend` loop, differing in class and order; tags will be a third copy.
- `now_text` is already exported to BIB_NOTE_STORE (bib_user_store.e:409); `time_of` is not.
**Suggested Action:** Export `time_of` next to `now_text` (or move both to BIB_SQLITE_REPORTING) and delete the note store's copy; one `stored_item (a_row, a_item)` helper for the loop.
**Effort:** 1 feature moved, 1 helper.

### Finding 7: Hub id to text and hub ranges, several ways (MEDIUM, D1)
**Classes:** BIB_GUI_APP, BIB_HUB_ID
**Description:**
- Turning a hub id into reader text: highlight_place (1655-1666) guards `is_valid_hub` and `bible.books.has_book`, then calls place_text (2474-2486), which tests `has_book` again; an invalid id shows the raw number (1664). The notes gutter draws only `verse_of` (1675-1678) and a note's hub is never shown as a place; cross_ref_text (2536) is a third path. on_highlight_row (1620-1630) decodes the hub into book, chapter and verse a second time before go_to.
- Ranges: the chapter range `hub_id (b, c, 1)` to `hub_id (b, c, Max_part)` is written inline at 1423 (notes) and 1591 (highlights); the "every verse" range is written once at 1562 as `hub_id (1,1,1)` to `hub_id (Max_part,Max_part,Max_part)`, and notes_between has no all-verses call at all (its precondition at bib_db_note_store.e:95 is `0 < a_first_hub`, highlights_between's at bib_user_store.e:87 has none of it, only `ordered`).
- `create l_hub` appears in seven window features (1410, 1558, 1585, 1622, 1658, 1671, plus two inline at 1456 and 1613).
**Suggested Action:** Put `chapter_first`, `chapter_last`, `first_verse` and `last_verse` queries, and a `place_of (hub)` decode returning book, chapter, verse, on BIB_HUB_ID; one `hub_place_text` in the window used by highlight_place, the notes gutter and future Tags; the guard about `bible.books.has_book` goes inside place_text, not around it.
**Effort:** 4 queries, 1 helper.

### Finding 8: BIB_HIGHLIGHT trusts any positive hub id (MEDIUM, contract gap)
**Classes:** BIB_HIGHLIGHT (src/user/bib_highlight.e), BIB_USER_ITEM, BIB_NOTE
**Description:** make requires only `hub_positive` and the invariant repeats it, while
BIB_HUB_ID.is_valid_hub (src/user/bib_hub_id.e:48-53) demands book, chapter and verse each 1 to 999.
A hub like 43003000 (verse 0) is storable and falls inside the full-range query
(window 1562), so the window defends in four places: fill_highlights' query, highlight_place
(1661), on_highlight_row (1626) and draw_note_gutter (1675). The contract should state the
rule once: `hub_valid: (create {BIB_HUB_ID}).is_valid_hub (a_hub_id)` for highlights (topical notes,
hub 0, keep their exception).
**Effort:** 1 precondition and 1 invariant clause per class.

### Finding 9: Two error attributes for one concept (LOW)
**Classes:** BIB_USER_STORE
**Evidence:** `write_error` (bib_user_store.e:394, set at 263-268 for settings) and `last_item_error` (418, 429-451, hidden) both mean "why the last write failed"; the note store uses a third, `last_error` on BIB_NOTE_STORE (bib_note_store.e:16).
**Suggested Action:** One exported `write_error` set by settings and items alike; part of finding 1.

### Finding 10: Design pill tips (LOW)
**Evidence:**
- gui_app/bib_gui_app.e:2054 (T2): the tip names Highlights ("a reason, not a color; washed in the text") but not that the tab has Highlight, Remove and Restore buttons, that a row click opens its verse, or that Remove needs a selected row; the notes half still says "Delete and Restore". Accurate but incomplete; the pill sits on `notes_heading` (Verse notes tab) only, so a reader on the Highlights tab has no pill for its own controls.
- Same file, 2053 (T1): "Bookmarks come later" is still correct (the store has `bookmarks`, bib_user_store.e:102, but the window has no bookmark control).
- Same file, the T3 tip (the centre-tabs pill, near 2055) says nothing about the amber wash, and, per finding 4, the Parallel tab does not show it.
- Wrong claim candidate: "washed in the text" is true of the Bible tab only.
**Suggested Action:** Name the Highlights controls in the tip (or give the tab its own pill) and say "washed in the Bible tab" until finding 4 is fixed.

## Other small notes
- Snapshot uses a magic tab index `select_tab (4)` (bib_gui_app.e:269) for Highlights; the notes snapshot never needs one. A named constant beside the tab list (1375-1380) avoids a silent break when tabs are reordered.
- add_highlight (1605-1618) silently does nothing when the store is closed or no verse is read (the `elseif` has no else), while add_note at least toasts for an empty body; the button is disabled in those states (1580), so it is only reachable from the snapshot path.
- highlights_for's postcondition `counted` (bib_user_store.e:79) compares with `item_count`, which does not filter `label <> ''` or `hub_id > 0` as highlights_between does (92); the two agree only while BIB_HIGHLIGHT keeps its invariant.

## Recommended Order
1. Finding 1 (postconditions and error seam): a live defect on the first failed write.
2. Finding 8 and finding 7: one rule for hub validity and hub text, which findings 2 and 4 rest on.
3. Finding 3 then finding 2 and 5 (stores first, then the window mixin) so Journal, Tags, Prayer and Memory inherit one rule.
4. Finding 4 (wash helper, Parallel tab).
5. Findings 6, 9, 10.
