# Design Scan (diff mode): simple_bible since 8180bd4
# Subjects: gui_app/bib_gui_app.e, src/user/bib_memory_card.e, src/user/bib_memory_schedule.e, src/user/bib_prayer.e, src/user/bib_user_store.e
# Compared against: src/, cli/, gui_app/, build/, build_app/ (read-only; nothing compiled)

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A and D1 and T1) | 9 | 3 | 5 | 1 |
| MI | 0 (folded into Finding 3 and 4) | 0 | 0 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **9** | **3** | **5** | **1** |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_USER_STORE, BIB_DB_NOTE_STORE | Soft delete now written four times, and the copies disagree |
| 2 | HIGH | D1 | BIB_USER_STORE | Four spellings of "live", the prayer and card ones differ from Live_item_filter |
| 3 | HIGH | D1 / A5 | BIB_GUI_APP, BIB_ITEM_LIST_PANEL | Prayer and Memory repeat the Remove/Restore panel and reintroduce its fixed bugs (memory has no Restore at all) |
| 4 | MEDIUM | A1 / M2 | BIB_PRAYER, BIB_MEMORY_CARD, BIB_USER_ITEM | The two new records re-declare what BIB_USER_ITEM already owns |
| 5 | MEDIUM | A5 | BIB_USER_STORE | upgrade_from_1 and create_schema repeat the same transaction block; migration edge cases |
| 6 | MEDIUM | D1 | BIB_USER_STORE | record_review transaction: unchecked begin, row count read from the wrong statement |
| 7 | MEDIUM | D1 / T1 | BIB_USER_STORE, BIB_MEMORY_CARD, BIB_GUI_APP | Three producers of "now" in two granularities; dates compared as text |
| 8 | MEDIUM | T1 | BIB_GUI_APP, BIB_MEMORY_SCHEDULE | Grade numbers 1, 3, 4, 5 are literals in the GUI |
| 9 | LOW | contract cost | BIB_USER_STORE | Contract costs: duplicate existence query, redundant row filters |

## Detailed Findings

### Finding 1: Soft delete written four times, and the copies disagree
**Priority:** HIGH (D1)
**Classes:** BIB_USER_STORE (src/user/bib_user_store.e), BIB_DB_NOTE_STORE (src/user/bib_db_note_store.e)
**Description:** There were two copies of "flip the deleted flag" before this change (user items, notes). The new code adds two more. They have already diverged. The behavior of `set_item_deleted` (the oldest, scan 42 hardened) should win.
**Evidence:**
- src/user/bib_user_store.e:712-728 `set_item_deleted`: writes `changed_at`, checks `has_error`, checks `changes_count /= 1` (Not_found).
- src/user/bib_user_store.e:356-374 `set_prayer_deleted`: no change time (the prayer table has no changed_at, line 799); otherwise a line-for-line copy of 716-727, including the `l_flag` conversion at 362-367.
- src/user/bib_user_store.e:494-512 `set_memory_card_deleted`: the same, a third copy (no change time; table at line 800).
- src/user/bib_db_note_store.e:528-540 `set_deleted`: a fourth shape (transaction plus `finish`), and it does not check `changes_count`, so a missing note id is a silent success.
- Guards differ: `restore_item` requires `deleted: is_deleted (a_id)` (line 312) and ensures `restored` (316); `remove_item` ensures `soft_deleted` (305). `set_prayer_deleted` and `set_memory_card_deleted` have only `open` and `stored` preconditions and no postcondition (lines 356-362, 494-500).
- `set_prayer_answered` guards with `AND deleted = 0` (line 348) but `set_prayer_deleted` does not, so Remove of an already removed prayer reports success again.
- Consequence of the missing change time: a removed prayer or card carries no record of when it was removed, unlike every user item and note (AC-1a-40 says deletes are soft and restorable; the audit trail is only partial for the new tables).
**Suggested Action:** one private `soft_delete (a_table, a_key_column, a_id, a_deleted)` in BIB_USER_STORE (or a deferred ancestor shared with BIB_DB_NOTE_STORE through `store`), taking the table and key column, writing `changed_at` everywhere (add the column to prayer and memory_card in schema 2 before it ships), and keeping the Not_found check. Then `remove_item`, `set_prayer_deleted`, `set_memory_card_deleted`, and the note `set_deleted` become one-line callers.
**Effort:** 1 helper, 4 callers.

### Finding 2: Four spellings of "live"
**Priority:** HIGH (D1)
**Classes:** BIB_USER_STORE
**Description:** Scan 44 collapsed six spellings into `Live_item_filter` (line 689-691). Schema 2 adds three new ones that do not use it and do not agree with each other. A row can be counted by one query and not listed by another, which is the exact scan 44 defect.
**Evidence:**
- src/user/bib_user_store.e:689 `Live_item_filter`: `deleted = 0 AND hub_id > 0 AND label <> ''`.
- src/user/bib_user_store.e:386 and 388 `prayers`: `deleted = 0 AND answered_at <> '' AND title <> ''` (and the open variant); then line 391 filters `hub_id >= 0` again in Eiffel, though the column default is 0 (line 799) so that test is always true for valid rows. Note the item rule says `hub_id > 0` but a prayer may have hub 0 (BIB_PRAYER invariant at line 161), so the shared constant could not be reused as is.
- src/user/bib_user_store.e:430 `has_memory_card`: `hub_id = ? AND deleted = 0` only.
- src/user/bib_user_store.e:442 and 444 `memory_cards`: `deleted = 0 AND hub_id > 0` in SQL, then `due_on` not empty and `ease_percent >= Least_ease` in Eiffel. A card with a bad ease (below 130) is counted by `has_memory_card` (so Add says "already a card") but never listed or reviewable. That is a live divergence.
**Suggested Action:** one constant per table beside `Live_item_filter` (`Live_prayer_filter`, `Live_card_filter`), used by every query on that table, including `has_memory_card`; add a CHECK constraint (ease_percent >= 130, due_on <> '', title <> '') in schema 2 so the Eiffel row filters can go. Then `has_memory_card` and `memory_cards` cannot disagree.
**Effort:** 2 constants, 4 queries.

### Finding 3: The Remove/Restore panel is not reused, and its fixed bugs come back
**Priority:** HIGH (D1 and A5)
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e), BIB_ITEM_LIST_PANEL (gui_app/bib_item_list_panel.e)
**Description:** The panel's header says (lines 3-9) that scan 43 found the same logic written per list and every copy keeping a stale selected row after Remove. Prayer and Memory write it again, inline in the 3800-line application class, and show the same defects.
**Evidence:**
- Prayer copy: gui_app/bib_gui_app.e:2025-2029 (`chosen_prayer`, `last_removed_prayer`), 2145-2173 (`remove_prayer`, `restore_prayer`), 2175-2192 (`on_open_prayer`, `on_answered_prayer`). Memory copy: 2341-2354 `remove_memory_card`, 2356-2364 `on_memory_row`, `chosen_card`.
- Panel versions: gui_app/bib_item_list_panel.e:117-130 `remove`, 134-144 `restore`, 88-109 `set_rows`.
- Drift 1: the panel's `restore` checks `store.is_deleted (last_removed)` first (line 135); `restore_prayer` (bib_gui_app.e:2161-2172) does not.
- Drift 2: the panel's `set_rows` keeps the selection by id and clears it when the item is gone (lines 99-108); `fill_prayers` (2072-2098) and `fill_memory` (2249-2278) call `grid.set_rows` only, so the grid keeps a selected row number that now points at the next item (the scan 43 defect) while `chosen_prayer` is reset to 0 at 2154 and `chosen_card` at 2349. Clicking the highlighted row then does nothing.
- Drift 3: Memory has no Restore at all. `set_memory_card_deleted (..., False)` has no caller in the GUI (only line 2345 calls it, with True), and there is no memory restore button (buttons at lines 88-98). A removed card is invisible and unrecoverable from the interface, against the "removed things stay restorable" rule.
- Drift 4: prayer Remove and Restore are enabled by two different paths (2094-2095 and 2180-2184, 2191), the panel does it in one place (`set_rows`, lines 105-106).
- The panel is bound to `G -> BIB_USER_ITEM` and to `Kind_*` through `store.remove_item` (lines 28-30, 121, 138), so BIB_PRAYER and BIB_MEMORY_CARD cannot use it as it stands.
**Suggested Action:** two steps. (a) Finding 4 (give the two records the BIB_USER_ITEM role). (b) Make the panel's three store calls into agents or a small deferred `BIB_REMOVABLE_SOURCE` (remove, restore, is_deleted by id) that BIB_USER_STORE's three kinds each supply, so one panel serves bookmarks, highlights, tags, prayers and cards. A deferred mixin side by side with the existing parents, not a deeper chain. Until then, Memory needs a Restore button today.
**Effort:** about 6 features moved out of bib_gui_app.e, 1 deferred class.

### Finding 4: The two new records re-declare what BIB_USER_ITEM owns
**Priority:** MEDIUM (A1, M2)
**Classes:** BIB_PRAYER (src/user/bib_prayer.e), BIB_MEMORY_CARD (src/user/bib_memory_card.e), BIB_USER_ITEM (src/user/bib_user_item.e)
**Description:** BIB_USER_ITEM already owns `id` with its zero-until-stored contract (lines 16-17), `hub_id` (19-20), `is_stored` (34-37), `is_deleted` (41), `mark_stored`, `mark_deleted`, `mark_restored` (47-81) and the invariants `id_non_negative`, `hub_non_negative`, `only_stored_deleted`. The new classes declare each again with weaker contracts.
**Evidence:**
- src/user/bib_prayer.e:111 `id`, 117 `hub_id`, 120 `created_on` (text; BIB_USER_ITEM has `created_at: detachable SIMPLE_DATE_TIME`), 129 `is_deleted` (an attribute that is never set: queries filter deleted rows out, so it is always False), 139-147 `mark_stored` (a different signature, takes text, not SIMPLE_DATE_TIME).
- src/user/bib_memory_card.e:199 `id`, 202 `hub_id`, 218-223 `mark_stored`; no `is_deleted` at all, and no `is_stored` (the store tests `a_card.id = 0`, user_store.e:325 and 410, where items use `not a_item.is_stored`, lines 253 and 266).
- Time is two types: `created_on: STRING_32` here, `created_at: SIMPLE_DATE_TIME` there; the GUI cuts text with `head (10)` (bib_gui_app.e:2195-2200) where items use `time_of`.
- `kind` is deferred in BIB_USER_ITEM (line 24-27) and is_valid_kind (user_store.e:242-245) bounds on Kind_note..Kind_visit, so prayer and card kinds are absent there; that is why Finding 3 cannot reuse the panel.
**Suggested Action:** inherit BIB_USER_ITEM in both (add Kind_prayer = 6 and Kind_memory_card = 7, widen `is_valid_kind`, or keep them out of `Kind_*` and extract a shallower deferred BIB_STORED_RECORD with id, is_stored, is_deleted, hub_id, created_at that BIB_USER_ITEM and these two inherit side by side). Keep the card's `due_on` and the prayer's `answered_on` as their own features.
**Effort:** 5 features per class.

### Finding 5: Migration: repeated transaction block and edge cases
**Priority:** MEDIUM (A5 plus data-loss review)
**Classes:** BIB_USER_STORE
**Description:** Data loss review result: the main path is safe (backup first, then one transaction, everything additive). The edges below are not data loss today but can refuse to open, or mislead.
**Evidence:**
- Duplicate block: src/user/bib_user_store.e:774-791 (`upgrade_from_1`) and 814-838 (`create_schema`) are the same begin, loop over statements, set last_error, commit, check commit error, rollback if still open. Schema 3 would make a third copy. A shared `run_in_transaction (statements, message)` removes about 25 lines.
- Failed VACUUM INTO: the failure is caught (770) and `open` closes the connection and leaves version 1 as it was (629, 642). Good. But a partial backup file may stay behind and nothing deletes it; the next open picks the "-2" name (765-768), so failed attempts accumulate files beside user.db. The check is `is_file` only (770), not a size greater than zero or a test open.
- Name collision: handled by the loop (765-768), but the test-and-use is not atomic and the loop has no upper bound. Two copies of the program opening a version-1 file at once: both back up (distinct names), both `CREATE TABLE` (the second fails with "table already exists", line 777), the second reports "user.db could not be upgraded; it is as it was" (778) and refuses to open although the file is now schema 2 and fine. The version is not re-read after the failure, and the transaction is not `BEGIN IMMEDIATE`. Medium: refuses to open, no data lost.
- `begin_transaction` result is not checked at 774 (nor in create_schema at 814).
- `last_backup_path` (187-191) is set at 773 before the upgrade has succeeded and is never reset in `open` (610-611), so a store reopened after a failed upgrade, or a version-2 file, can report a stale path. The path should be set only after commit, and cleared at the start of `open`.
- `migrate` (572-590) repeats the version-1 test and calls `upgrade_from_1` again, so a second backup is made when a caller migrates a store that `open` already upgraded only if schema_version were 1; it is guarded (579), so no defect, only a second entry point to keep in step.
**Suggested Action:** extract the transaction runner; set `last_backup_path` after commit; clear it in `open`; on a failed upgrade re-read `PRAGMA user_version` and accept 2; delete a failed partial backup.
**Effort:** 1 helper, 3 small edits.

### Finding 6: record_review transaction
**Priority:** MEDIUM (D1 against the Scan 42 pattern in `set_item_deleted`)
**Classes:** BIB_USER_STORE
**Description:** Rollback paths are correct (error rolls back at 482, a missing card rolls back at 485, commit only on success at 487, and the card object is changed only after commit at 488, so a failure leaves memory and disk agreeing). The weaknesses are in how success is read.
**Evidence:**
- src/user/bib_user_store.e:473 `begin_transaction` is not checked.
- Line 476 tests `changes_count = 1` after the UPDATE, but line 483 tests `changes_count` again after the INSERT ran, so what the success branch really verifies is the INSERT's count. If the UPDATE hit zero rows the INSERT is skipped and the count is still 0 (correct), but the logic is fragile and reads as if it checked the UPDATE twice. Keep the update count in a local, as `set_item_deleted` reads it once.
- The `ensure` (491) checks only `repetitions`; due date, interval and ease are the other three results and are untested. It also calls `next_repetitions` on `old a_card.repetitions` but the `old` of an object attribute is evaluated as a value, fine; the check is weak, not wrong.
- There is no precondition that the card is live; a removed card can still be reviewed (the UPDATE has `deleted = 0`, so the result is Not_found, an error message "No such card" for a card that exists).
- The UPDATE has no guard that the stored state still matches `a_card` (no optimistic check), so a stale card object overwrites newer state. Low risk with one writer.
**Suggested Action:** local `l_updated`, check begin, strengthen the postcondition with `due_on`, `interval_days`, `ease_percent`; fold the transaction pattern into the helper of Finding 5.
**Effort:** 1 feature.

### Finding 7: Time stamps, and dates compared as text
**Priority:** MEDIUM (D1 and T1)
**Classes:** BIB_USER_STORE, BIB_MEMORY_CARD, BIB_GUI_APP
**Description:** Three producers of "now" in two granularities, with no one shared source.
**Evidence:**
- `now_text` (src/user/bib_user_store.e:680-684, full date and time) writes `created_at` and `answered_at` (331, 348, 415).
- `today_text` (gui_app/bib_gui_app.e:2221-2225, a SIMPLE_DATE, date only) is used for card creation (2291), list filter (2254) and the "today" label (2375).
- `record_review` takes `a_today: SIMPLE_DATE` (455) and the GUI passes a fresh `create {SIMPLE_DATE}.make_now` (2331), a separate clock read from `today_text` (2224). Across midnight a card listed as due by one day's `today_text` is scheduled from the next day's date.
- Text comparison: `due_on <= a_today.to_string_32` (src/user/bib_memory_card.e:213), SQL `due_on <= ?` and `ORDER BY due_on` (user_store.e:442) and index `ix_memory_due (deleted, due_on)` (800). This is only correct while every writer produces `YYYY-MM-DD`. `due_on` is written from `to_iso8601` of a SIMPLE_DATE (472) and from the card (415); the contract `due_given` (card.e:187) only requires non-empty, not the format. A single value with a time or zone suffix would sort after its own date and be wrongly not due. The prayer list uses `head (10)` to cut full times (bib_gui_app.e:2197, 2205) so the code already knows the two shapes differ.
**Suggested Action:** one clock feature (a `today_text` in the store, `now_text` beside it, and a testable `a_today` supplied by the caller for `add_memory_card` too); an `is_iso_date` check in the card's precondition and invariant; keep the `head (10)` cut in one place (a feature on the record).
**Effort:** 2 features, 2 contract lines.

### Finding 8: Grade numbers as magic numbers
**Priority:** MEDIUM (T1)
**Classes:** BIB_GUI_APP, BIB_MEMORY_SCHEDULE
**Description:** The mapping of button to grade (Again 1, Hard 3, Good 4, Easy 5) lives only in the GUI and a comment; the schedule owns `Passing_grade` (line 70) but not the others.
**Evidence:**
- gui_app/bib_gui_app.e:481-484 `agent grade_memory_card (1)`, `(3)`, `(4)`, `(5)`; comment at 2326.
- The same pair 0 and 5 (the grade range) is spelled as literals in src/user/bib_memory_schedule.e:22, 36, 59 and src/user/bib_user_store.e:461, gui_app/bib_gui_app.e:2328, with no `Least_grade` and `Most_grade`.
- Hard = 3 equals `Passing_grade`, so changing the pass mark silently changes what the Hard button means.
**Suggested Action:** add `Grade_again`, `Grade_hard`, `Grade_good`, `Grade_easy`, `Least_grade`, `Most_grade` and an `is_valid_grade (a_grade)` query to BIB_MEMORY_SCHEDULE; use them in the four agents and in all five preconditions. Does not scale; no theme token needed.
**Effort:** 6 constants, 1 query, 9 call sites.

### Finding 9: Contract costs
**Priority:** LOW
**Classes:** BIB_USER_STORE, BIB_GUI_APP
**Evidence:**
- `add_memory_card` has `one_card_a_verse: not has_memory_card (a_card.hub_id)` (src/user/bib_user_store.e:411), a count query, and the GUI already calls `has_memory_card` just before (gui_app/bib_gui_app.e:2288): two queries per Add in the contract-baked F_code build. Not a hot path; leave, but note it for the timing budget.
- `memory_cards` ensure `all_due` (452) walks the result once; cheap. `record_review` ensure (491) builds a BIB_MEMORY_SCHEDULE object per call; cheap. BIB_PRAYER and BIB_MEMORY_CARD invariants (prayer.e:159-161, card.e:238-242) are constant time.
- Redundant row filters in Eiffel that the SQL could carry (Finding 2) cost a second pass over every row on each tab refresh (`fill_memory` runs two `memory_cards` queries per refresh, bib_gui_app.e:2253-2254, one of which could be the other filtered in memory).
**Suggested Action:** none required now.

## Recommended Order

1. Finding 3 (memory has no Restore: a user-visible gap today), then Finding 4, which unblocks the shared panel.
2. Finding 1 and Finding 2 together: one soft-delete helper and the live filters; add `changed_at` and the CHECK constraints to schema 2 while it is still unreleased.
3. Finding 6 and Finding 5 together: one transaction runner for migration, create_schema and record_review.
4. Finding 7 and Finding 8: one clock, a format check, and named grades.
5. Finding 9: only if timing tests complain.
