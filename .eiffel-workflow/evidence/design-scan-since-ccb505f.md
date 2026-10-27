# Design Scan (diff mode): simple_bible since ccb505f
# Date: 2026-10-27
# Subjects: gui_app/bib_gui_app.e, src/user/bib_user_store.e (the only src/cli/gui_app/build/build_app files changed)
# Compared against: src/, cli/, gui_app/, build/, build_app/ (read-only; nothing compiled)

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift | 4 | 2 | 2 | 0 |
| Behavior (growth, recording) | 3 | 0 | 2 | 1 |
| Tokens / contracts / pills | 2 | 0 | 0 | 2 |
| **Total** | **9** | **2** | **4** | **3** |

## Findings

| # | Priority | Category | Subject | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_GUI_APP.record_reading | A failed History write is never reported, and is retried silently on every later open_reading of the same chapter; every other writer says the error |
| 2 | HIGH | D1 / A5 | BIB_GUI_APP.fill_history | Reselect-by-guard pattern written a fourth time (journal, tags, panel, now History), each keyed differently |
| 3 | MEDIUM | growth | BIB_USER_STORE.record_visit / recent_places | One user_item row per chapter change, forever; no pruning; the History query scans every visit row on every chapter change |
| 4 | MEDIUM | behavior | BIB_GUI_APP.record_reading | Back and Forward record a visit, so stepping Back reorders History (the chapter just left jumps to the top) |
| 5 | MEDIUM | A1 / A5 | visit_place, bookmark_place, highlight_place, tag_place | Fourth identical `hub_place (x.hub_id)` wrapper |
| 6 | MEDIUM | behavior | BIB_GUI_APP.open_reading | fill_history runs in Simple mode (tab not shown) while every other tab fill is gated by is_study |
| 7 | LOW | A5 | BIB_GUI_APP.record_reading | Rebuilds the hub id by hand beside `reading_hub` (which has a verse > 0 precondition) |
| 8 | LOW | contract | BIB_USER_STORE.recent_places | one_per_chapter postcondition: cheap enough, but redundant with the SQL; no test of limit/growth/failure |
| 9 | LOW | T1 token | History_length / pill | The 50 limit lives in one constant but the pill tip and heading do not say "last 50" |

## Detailed Findings

### Finding 1: A failed visit write is silent and retried forever (HIGH, D1)
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e), BIB_USER_STORE (src/user/bib_user_store.e)
**Description:** `record_reading` calls `user_store.record_visit` and only tests `write_error = Void` to decide whether to advance `last_recorded_hub`; when the write fails it says nothing. Every other user-item writer in the same class reports `al_error.message` through `say`: `bookmark_verse`, `tag_verse`, `add_highlight`. On failure `last_recorded_hub` stays old, so every later `open_reading` (chapter change, but also `reopen_reading` after a highlight, and `on_version_change`) tries the INSERT again and fails again, silently. The reader sees an empty or stale History with no explanation (the heading only says "No history yet"). No unbounded growth results from failure, but the failure is invisible. The write that matters (bookmarks) wins here: report it, once per run is enough (a toast on every chapter would nag), e.g. say once and remember `history_failure_told`.
**Evidence:**
- gui_app/bib_gui_app.e:1531-1535: `user_store.record_visit (...)`; `if user_store.write_error = Void then last_recorded_hub := l_hub end`; `fill_history` (no else branch, no `say`)
- gui_app/bib_gui_app.e:1488-1489, 2075-2076, 2188-2189: the three sibling writers all `say (al_error.message)`
- src/user/bib_user_store.e:490-492: add_item sets `write_error` with "The item could not be saved."
**Suggested Action:** report the error (once per run), then decide whether to keep retrying. Effort: 1 feature.

### Finding 2: Reselect-by-guard written again, with a different key (HIGH, D1)
**Classes:** BIB_GUI_APP, BIB_ITEM_LIST_PANEL (gui_app/bib_item_list_panel.e)
**Description:** The panel's own header (lines 3-9) says scan 43 found "the same logic had been written for each list" and moved bookmarks and highlights into `BIB_ITEM_LIST_PANEL` (set_rows keeps the chosen item selected by id behind `is_refilling`). Scan 44 moved tags to select by name (bib_gui_app.e:2018-2043) and journal selects by id (1825-1845). `fill_history` is now another hand-written copy of the same loop: scan rows, find the index, `is_refilling_history := True`, `select_model_row`, `False` (lines 1553-1563). The copies have diverged in the key they reselect by:
  - panel (bookmarks, highlights, tagged): by `id` (item_id), clears `chosen_id` when gone (bib_item_list_panel.e:105-121)
  - journal: by `journal_entry_id` (1832-1840), clears it when gone
  - tags: by name (2030-2038), clears it when gone
  - history: by chapter of the place read (1553-1560), keeps NO remembered choice at all, so a click on a row followed by any refill (a chapter opened some other way) moves the selection to the chapter now read; also the selection is lost entirely (index 0) whenever the chapter read is past row 50.
  The history copy is a legitimate difference (selection follows the place read, not a click), but the scaffolding (`is_refilling_*` flag, guard in the handler `on_history_row` at 1573-1577, `select_model_row` wrapper, heading text choice) is the same four times. Candidate: a deferred mixin (side-by-side parent) that owns the `is_refilling` guard and `reselect (a_grid, a_index)`: `BIB_RESELECTING` with `select_without_event (a_grid: SW_DATA_GRID [G]; a_index: INTEGER)`, which BIB_ITEM_LIST_PANEL and BIB_GUI_APP both inherit. Alternatively let the panel take a "select by" agent (id, name, chapter) so History is a panel with Remove/Restore hidden (a panel option) and `on_row` still opens the verse.
**Evidence:**
- gui_app/bib_gui_app.e:1516, 1561-1563, 1574 (history guard)
- gui_app/bib_gui_app.e:1799, 1842-1844, 1956 (journal guard)
- gui_app/bib_gui_app.e:1982, 2041-2043, 2088 (tags guard)
- gui_app/bib_item_list_panel.e: `is_refilling` set around `grid.select_model_row` in `set_rows`, tested in `on_row`
**Suggested Action:** /eiffel.abstract or /eiffel.mi: shared guard mixin; Effort: 3 features (flag, wrapper, handler guard).

### Finding 3: History grows without bound and each chapter change scans all visits (MEDIUM)
**Classes:** BIB_USER_STORE
**Description:** `record_visit` is a plain `add_item` INSERT into `user_item` (bib_user_store.e:277-285, 489-490). Nothing deletes or prunes `Kind_visit` rows (grep of src for prune/purge/DELETE FROM finds nothing; `remove_item` only soft-deletes and no UI offers it for visits). One row is added per chapter change, plus one per run (last_recorded_hub starts at 0 each run, so the first chapter of every run is recorded even when it equals the previous run's last chapter). Over years this is tens of thousands of rows. `recent_places` then runs `SELECT max(item_id) ... WHERE kind = ? ... GROUP BY hub_id / 1000` (line 126); the index `ix_user_item_hub (kind, hub_id, deleted)` (line 577) narrows to kind = visit but still visits every visit row to group them, and the GUI calls it on EVERY chapter change via `fill_history` (bib_gui_app.e:1548). Cost is O(visits) per chapter change; small now, rising linearly. It also inflates user.db and any backup (BIB_USER_BACKUP) that copies it. Options: keep only the newest row per chapter (UPDATE the existing visit row's changed_at, or delete older rows of the same chapter in the same write), or prune to the newest N (say 500) after insert.
**Evidence:**
- src/user/bib_user_store.e:126 (query), 277-285 (record_visit), 489-490 (INSERT), 577 (index)
- gui_app/bib_gui_app.e:1531, 1548
**Effort:** 1 to 2 features.

### Finding 4: Back and Forward record visits (MEDIUM)
**Classes:** BIB_GUI_APP
**Description:** `move_in_history` (bib_gui_app.e:985-991) calls `open_reading` directly, which calls `record_reading` (1052). Stepping Back from chapter B to chapter A therefore records A as the newest visit, and History reorders under the reader's hands (A jumps above B) even though no new place was read. It also adds a row per Back or Forward press (compounds Finding 3). Larry's wording in the doc comment ("a verse clicked in the same chapter is no new visit") suggests Back/Forward should not count either. Fix: a flag `is_stepping_history` set in `move_in_history`, or record in `go_to` (bib_gui_app.e:971-983, the only path for a new place) rather than in `open_reading`. Recording from `go_to` also removes the need for the `last_recorded_hub` guard against `reopen_reading` (2220-2225), `on_version_change` (797) and the highlight refresh (2192), which all call `open_reading` for the SAME place.
**Evidence:**
- gui_app/bib_gui_app.e:971-983 (go_to), 985-991 (move_in_history), 1052 (record_reading call), 797, 2192, 2224 (other open_reading callers)
**Effort:** move one call; remove one guard.

### Finding 5: Fourth `hub_place` wrapper (MEDIUM, A1/A5)
**Classes:** BIB_GUI_APP
**Description:** `visit_place` (1579-1583) is the fourth feature whose whole body is `Result := hub_place (x.hub_id)`, beside `bookmark_place` (1497-1501), `tag_place` (2104-2108), `highlight_place` (2197-2201). Each takes a different type but all four types are BIB_USER_ITEM (BIB_VISIT inherits it, bib_visit.e:10-11; panel is generic over `G -> BIB_USER_ITEM`, bib_item_list_panel.e:17). One `item_place (a_item: BIB_USER_ITEM): STRING_32` would serve every grid column (the agents are typed per SW_GRID_COLUMN [G], so a G-generic agent works where the argument type conforms, or a `place_text_of` on the panel). Same for `visit_when` against any "created_at" column if bookmarks ever show age.
**Evidence:** gui_app/bib_gui_app.e:578, 579, 585 (column wiring), 1497, 1579, 2104, 2197 (the wrappers)
**Effort:** 4 features collapse to 1.

### Finding 6: fill_history is not gated by is_study (MEDIUM)
**Classes:** BIB_GUI_APP
**Description:** In `open_reading`, `fill_parallel`, `fill_notes`, `fill_highlights`, `fill_bookmarks` and `fill_tags` run only `if is_study` (lines 1054-1063, per the diff context at 1054-1062). `record_reading` (1052) sits above that branch and itself calls `fill_history`, so in Simple mode (T1 is hidden, "Simple has no tabs", line 1270) the history query and the grid `set_rows` run on every chapter change for a widget nobody sees. Recording in Simple mode is correct (the reading happened), refilling is waste; and when the reader switches to Study, `arrange (True)` must refill (bookmarks and tags are refilled by the study branch; History is refilled only because it was refilled all along). Move `fill_history` into the is_study branch beside `fill_bookmarks`, and call `record_reading` without the fill. Note `arrange` (1318-1369) would then need to call `fill_history` once on entering Study, as the sibling fills already must.
**Evidence:** gui_app/bib_gui_app.e:1052, 1054-1063, 1522-1537
**Effort:** 2 lines.

### Finding 7: Hub id rebuilt by hand beside reading_hub (LOW, A5)
**Classes:** BIB_GUI_APP
**Description:** `reading_hub` (1985-1991) exists because "the expression was written at each use" (scan 44) but requires `reading_verse > 0`. `record_reading` (1527) writes `(create {BIB_HUB_ID}).hub_id (reading_book, reading_chapter, reading_verse.max (1))` again, because a chapter opened with verse 0 has no verse. A `reading_chapter_hub` (verse 1 or the verse read) beside `reading_hub` would own both. Also `fill_history` creates its own BIB_HUB_ID (1544).
**Evidence:** gui_app/bib_gui_app.e:1527, 1544, 1985-1991.

### Finding 8: one_per_chapter postcondition (LOW)
**Classes:** BIB_USER_STORE
**Description:** The postcondition (line 133) is a nested across over Result: at most 50 rows (History_length, bib_gui_app.e:1506) gives at most 2,500 INTEGER_64 divisions and comparisons per call, about microseconds; it is cheap enough, per the memory rule (hot paths keep only cheap critical contracts), and `recent_places` is only called on chapter change. However it is redundant with the SQL (GROUP BY hub_id / 1000), and the limit is the caller's: another caller passing 100000 would make it quadratic (1e10). Keep it, but cap it (`a_limit <= 1000` in the precondition, or check `Result.count <= 200 implies ...`). Also the unit test (testing/test_user_store.e, test_recent_places_one_per_chapter) covers order, one-per-chapter and limit only; nothing tests a failed write, a deleted visit (Live_item_filter), or the same chapter at two verses beyond the first, which is the case the query chooses by max(item_id).
**Evidence:** src/user/bib_user_store.e:117-134; testing/test_user_store.e (new test, 3 visits, 2 chapters).

### Finding 9: Pill tip and heading do not state the limit (LOW)
**Classes:** BIB_GUI_APP
**Description:** The T1 pill (2633) says "History (the chapters read, newest first, kept between runs; click one to read it again)": true, and "newest first" is right (`ORDER BY item_id DESC`, line 126). It omits that only the last 50 chapters are listed (History_length, 1506), and `history_heading` (1566-1568) does not say so either. Not wrong; add "the last 50" so a reader who reads 51 chapters is not surprised. The snapshot option `history` (303-306) is not in any usage text found by grep of gui_app (check the command-line help if one exists).
**Evidence:** gui_app/bib_gui_app.e:303-306, 1506, 1566-1568, 2633.

## Checked and found sound
- Snapshot runs: `user_store` is the snapshot's own emptied user.db (bib_gui_app.e:45-52, fresh_snapshot_user_file), so recording in `take_snapshot` (go_to at 271-276, 304-305) never touches the reader's real History. The snapshot history option works by design.
- Simple mode: recording runs there (reading happened), see Finding 6 only for the redundant fill.
- Same-chapter re-opens (verse click, version change, highlight refresh, reopen_reading) do NOT record: guarded by chapter compare (1528).
- `on_history_row` guarded by `is_refilling_history` (1574): the reselect inside `fill_history` does not re-enter `go_to_hub`, so no recording loop.
- SQL grouping: `hub_id / 1000` groups book+chapter correctly as Chapter_unit = 1_000 (bib_hub_id.e:66) and hub = book * Book_unit + chapter * 1000 + verse (line 27).
- Deleted/blank rows excluded by Live_item_filter (475).

## Recommended Order
1. Finding 1 (silent failure) and Finding 4 (Back/Forward reorders; one fix in `go_to` also drops the guard)
2. Finding 3 (growth), before user.db files in the field grow
3. Finding 2 and 5 (drift and wrappers) together, in one extraction of the reselect guard and `item_place`
4. Findings 6 to 9 as cleanup
