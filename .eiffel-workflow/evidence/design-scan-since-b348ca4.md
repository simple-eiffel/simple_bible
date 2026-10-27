# Design Scan (diff mode): simple_bible since b348ca4
# Subjects: gui_app/bib_gui_app.e (only changed file under src, cli, gui_app, build, build_app)
# Compared against: src/, cli/, gui_app/, build/, build_app/
# Mode: read-only; nothing compiled

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Drift (D1) | 4 | 4 | 0 | 0 |
| Abstraction (A5/A6) | 1 | 0 | 1 | 0 |
| Token / tips (T2) | 2 | 0 | 1 | 1 |
| **Total** | **7** | **4** | **2** | **1** |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | D1 | Restore on Verse notes cannot show a restored journal entry, and a journal Delete leaves Restore disabled |
| 2 | HIGH | D1 | One `last_deleted_note` slot shared by two tabs: the second Delete silently forgets the first |
| 3 | HIGH | D1 | Two Save rules (add_note vs save_journal_entry) have diverged: trimming, empty body, feedback channel |
| 4 | HIGH | D1 | Two Delete rules have diverged: selection source, refresh of the other tab, feedback channel |
| 5 | MEDIUM | A5 | "Reselect by id with a guard flag" is written three times (one helper or mixin wanted) |
| 6 | MEDIUM | T2 | The T2 design pill misdescribes Journal Delete and the tab order |
| 7 | LOW | D1/UX | Editing the title of a selected journal entry is silently discarded on Save |

## Detailed Findings

### Finding 1: Restore on Verse notes does not bring a journal entry back into view
**Priority:** HIGH  **Category:** D1
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e), BIB_DB_NOTE_STORE (src/user/bib_db_note_store.e)
**Description:** `delete_journal_entry` promises the user "Restore on Verse notes brings it back". The store does restore it (`restore_note`, bib_gui_app.e:1643), but nothing shows it, and the button may be disabled.
**Evidence:**
- bib_gui_app.e:1791-1793: the journal Delete sets `last_deleted_note`, calls `new_journal_entry`, says "Restore on Verse notes brings it back."
- bib_gui_app.e:1535-1571: `fill_notes` is the only place that sets `restore_note_button.set_enabled (last_deleted_note > 0)` (line 1570). `delete_journal_entry` calls `fill_journal` (through `new_journal_entry`, 1742) but never `fill_notes`, so if the Restore button was disabled before (no earlier verse-note Delete), it stays disabled after a journal Delete. The promised message is then false until some other action calls `fill_notes` (a place change, 1046).
- bib_gui_app.e:1552: `fill_notes` lists `note_store.notes_between (hub first verse, hub last verse)`. A journal entry is topical (hub 0: `make_topical`, bib_note.e:31-41; `notes_for (0)` branch at bib_db_note_store.e:72-89), so it is outside every chapter range and `fill_notes` can never show it.
- bib_gui_app.e:1639-1651: `restore_note` ends with `fill_notes` only; it never calls `fill_journal`. After a successful Restore of a journal entry, the Journal grid (1710) stays stale and the entry is invisible until the next place change (1050) or a Save (1766, 1778).
**Behavior that should win:** the journal intent (Delete then Restore returns the entry, visible). 
**Suggested Action:** one shared Restore routine that refreshes both lists (and the button state), or a Restore button on the Journal tab. Needs Larry's word.
**Effort:** 2 features

### Finding 2: One undo slot for two stores of notes
**Priority:** HIGH  **Category:** D1
**Evidence:**
- bib_gui_app.e:1532: `last_deleted_note: INTEGER_64`, documented as "The note Delete removed last" (verse notes only in intent).
- bib_gui_app.e:1632 (verse Delete) and 1791 (journal Delete) both overwrite it. Delete a verse note, then delete a journal entry: Restore now brings back only the journal entry and the verse note can no longer be restored from the UI. The reverse order has the same loss.
- Contrast the panel pattern: BIB_ITEM_LIST_PANEL owns its own `last_removed` (bib_item_list_panel.e:62-63) per list, so Highlights, Bookmarks, and Tags never share an undo slot.
**Behavior that should win:** the panel's one-slot-per-list. 
**Suggested Action:** a second slot (`last_deleted_journal`) with its own Restore on the Journal tab, or move both lists to one panel class that owns its slot.
**Effort:** 1 attribute plus 1 button

### Finding 3: Two Save rules for the same note store
**Priority:** HIGH  **Category:** D1
**Classes:** BIB_GUI_APP: `add_note`/`on_note_edited` vs `save_journal_entry`
**Evidence (divergences):**
- Trimming: `add_note` trims both ends of the body (bib_gui_app.e:1580-1581); `save_journal_entry` trims only the title (1753-1754) and keeps the body untrimmed (1755).
- Empty body: `add_note` refuses an empty body with a toast (1582-1583); `save_journal_entry` accepts an empty body for a new entry (1768-1779) and also for an existing one (1759-1760 updates to empty).
- Open guard: `add_note` requires `user_store.is_open` (1584); `save_journal_entry` checks `note_store.is_writable` only (1756). (If `is_writable` implies open this is harmless, but the two guards are not the same text.)
- Feedback channel: `add_note`/`on_note_edited`/`delete_note` use `window.toast` (1583, 1588, 1610, 1630, 1634); every journal routine uses `say` (1757, 1763, 1765, 1769, 1774, 1777, 1789, 1793).
- Version rule: `on_note_edited` calls `update_note` unconditionally (1608); `save_journal_entry` skips it when the body is unchanged (1759) but still says "Saved; the earlier version is kept." (1765), which is untrue when nothing was versioned.
**Behavior that should win:** the Verse notes rules for trim and empty body (they were first and tested); the journal rule for skipping an unchanged version. 
**Suggested Action:** one `BIB_NOTE_EDITING` helper (or deferred ancestor) owning "save body of note id", used by both tabs.
**Effort:** 3 features

### Finding 4: Two Delete rules
**Priority:** HIGH  **Category:** D1
**Evidence:**
- Verse Delete takes the grid selection and range-checks it (bib_gui_app.e:1626-1627), reads the id before refresh (1632), then refreshes with `fill_notes` (1633) and toasts (1634).
- Journal Delete reads `journal_entry_id` (1786), refreshes via `new_journal_entry` which also wipes the edit boxes (1739-1742), and speaks with `say` (1793). Neither calls the other tab's refresh (see Finding 1).
- Verse Delete order: `last_deleted_note := note_rows.i_th (l_index).id` happens AFTER `remove_note` and `fill_notes` has not yet replaced `note_rows` (1632-1633), fine; but the journal copy depends on `journal_entry_id` before `new_journal_entry` zeroes it (1791-1792). Both are correct today, but each relies on statement order the other does not share.
**Behavior that should win:** one rule: remove, record the undo slot, refresh BOTH lists and the Restore button, one feedback channel.
**Suggested Action:** same shared routine as Finding 3.
**Effort:** 1 feature

### Finding 5: Reselect by id with a guard flag, written three times
**Priority:** MEDIUM  **Category:** A5 / A6
**Classes:** BIB_ITEM_LIST_PANEL (gui_app/bib_item_list_panel.e), BIB_GUI_APP
**Evidence:**
- bib_item_list_panel.e:84-100 (`set_rows`) with flag at 152 and its use at 111.
- bib_gui_app.e:1862-1887 (`fill_tags`), flag at 1826, use at 1932. Keyed by tag name, not id.
- bib_gui_app.e:1700-1722 (`fill_journal`), flag at 1678, use at 1801. Keyed by id.
- The shared shape: `grid.set_rows`, linear search for the kept key, clear the key when missing, `flag := True`, `select_model_row`, `flag := False`. Two copies are keyed by `.id` and so are identical in logic.
- Note on count: three copies exist in the code (the panel counts once even though it serves Highlights, Bookmarks, and Tags-verses).
**Suggested Action:** a small deferred mixin `BIB_RESELECTING` (inherited side by side), holding the guard flag and a `reselect (grid, rows, key_matches)` helper; the panel, fill_tags, and fill_journal each inherit it. The journal list could instead become a BIB_ITEM_LIST_PANEL [BIB_NOTE] if the panel's `open` action (hub id to read, bib_item_list_panel.e:111-114) is optional, since a topical note has hub 0; that would also give Journal its own Remove and Restore (fixes Findings 2 and 4 at once).
**Effort:** 1 mixin, 3 call sites

### Finding 6: T2 design pill is wrong or lumpy
**Priority:** MEDIUM  **Category:** T2
**Evidence:** bib_gui_app.e:2478.
- The tab order in the pane is Verse notes, Journal, Tags, Highlights (1503-1507), but the sentence lists Verse notes, Tags, Highlights and puts Journal last, after "Remove and Restore on the Tags and Highlights lists".
- It says Journal Delete exists but not that the only Restore is on Verse notes (and, per Finding 1, that Restore does not show it). The Delete message itself (1793) sends the user to a button on another tab; the pill hides that.
- The Verse notes clause "(... Delete and Restore) Tags (" is missing a separator before "Tags".
**Suggested Action:** reorder the pill to follow the tabs, add the separator, and state where Restore lives for Journal (or fix Finding 1 first and then describe the result).
**Effort:** 1 string

### Finding 7: Title edits on a selected entry are discarded
**Priority:** LOW  **Category:** D1/UX
**Evidence:** `on_journal_row` puts the title into `journal_title_box` (1803) so it looks editable; `save_journal_entry` for an existing entry only calls `update_note (journal_entry_id, l_body)` (1759-1760) and never reads `l_title` on that branch (the title is read at 1752-1754 and used only at 1768-1771). The user can change the title, press Save, see "Saved; the earlier version is kept." (1765), and the old title returns on refill. Notes have no title-update command in the store (bib_note_store.e:77, `update_note` takes a body only). Either make the title box read-only while an entry is selected, or add a title version.

## Not findings (checked)
- `Journal_tab = 2` (bib_gui_app.e:1662) matches the page order (1505); `Tags_tab = 3` (1809) and `Highlights_tab = 4` (1954) were renumbered consistently.
- Snapshot option `journal` (286-291) mirrors the `notes` option (283-285) and is sound.

## Recommended Order
1. Findings 1 and 2 together (live defects; one Restore story for both tabs).
2. Findings 3 and 4 (one shared save/delete helper, one feedback channel).
3. Finding 5 (the reselect mixin; consider the panel route for the journal, which would absorb 2 and 4).
4. Findings 6 and 7 (text and small UX).

Nothing was extracted or modified. Proposals only, pending Larry's word.
