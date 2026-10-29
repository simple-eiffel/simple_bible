# Design Scan (diff mode): simple_bible since ab2e46e (the aliasing fix, scan 67)
# Date: 2026-10-29
# Mode: read-only; nothing compiled, nothing run. Every finding cites lines that were read.
# Subjects: src/text/bib_fence_tracker.e, src/reading/bib_suggestion_line.e, src/reading/bib_name_list.e,
#   ingest/bib_note_importer.e (read, keep), ask/bib_ask_check.e (mended_query), gui_app/bib_gui_app.e
#   (on_ask, swapped_notes_pack), testing/test_facade_open.e.
# Compared against: all of ingest/, ask/, src/reading/, src/text/, build/ (grep of every to_string_32 / to_string_8 / mutator).
# Previous scan: .eiffel-workflow/evidence/design-scan-since-6c26cd2.md

## Verdict on the previous HIGH

Finding 1 of design-scan-since-6c26cd2 (the fence reader editing the caller's line): RESOLVED.
- src/text/bib_fence_tracker.e:36-38 now reads `create l_line.make_from_string_general (a_line)` before
  `prune_all` / `left_adjust` (39-40); the caller's line is no longer touched.
- The same copy is in src/reading/bib_suggestion_line.e:24, src/reading/bib_name_list.e:92,
  ingest/bib_note_importer.e:99, ask/bib_ask_check.e:257 (mended_query) and gui_app/bib_gui_app.e:4601 (on_ask).
- The call sites that were damaged (build/bib_markdown_blocks.e:95 `fences.feed (l_line)`, :369-373
  `without_comments`, ingest/bib_note_importer.e:382 and :457-458) now pass the intact line on. Behavior
  restored: indentation in code blocks, nested lists, "indented # is not a chapter".
- Residual: the same DEFECT CLASS is still present in one place the fix did not reach (finding 1 below).
- Packs built from the merged code between 6c26cd2 and ab2e46e lost indentation (the previous scan said
  rebuild); nothing in the diff rebuilds them.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 1 (finding 1) |
| MEDIUM | 3 (findings 2-4) |
| LOW | 4 (findings 5-8) |
| **Total** | **8** |

## Findings

| # | Priority | Category | Where | Finding |
|---|----------|----------|-------|---------|
| 1 | HIGH | D1 / defect | BIB_REFERENCE_LINKER.place_in | `a_text.to_string_32` then `left_adjust`, `right_adjust`, `remove_tail`: edits the caller's string; the Ask check hands it the call's own stored text |
| 2 | MEDIUM | safety | BIB_NOTE_IMPORTER.keep rescue | The retry swallows the cause (fixed message); a second failure inside the retry propagates with no further restore; set_aside still ignores rename results |
| 3 | MEDIUM | safety | swapped_notes_pack rollback | The restore ignores its own results; "the old one is back" is said whether or not it is; the `.old` delete now also runs after a failed restore, deleting the only copy of the old pack |
| 4 | MEDIUM | tests | testing/test_facade_open.e | The diff adds indentation tests only; no test of the rescue/retry, of the rollback, or of place_in leaving its argument alone |
| 5 | LOW | A1 | the "copy then edit" idiom | Five classes each repeat `create l_x.make_from_string_general (a)` + trim; a `trimmed` helper exists in the importer only |
| 6 | LOW | edge | BIB_ASK_CALL.make/set_text, BIB_LINK_TARGET.make, BIB_READING_VERSE.make | Store `to_string_32` of the argument: the stored text IS the caller's string (an alias, not edited today) |
| 7 | LOW | dead code | swapped_notes_pack | `if bible.is_open then bible.close end` inside the branch that just tested `not bible.is_open` |
| 8 | LOW | edge | swapped_notes_pack | After a failed swap the new note's files stay in the notes folder (set-aside copy already dropped) while the live pack is the old one |

## Detailed Findings

### Finding 1: place_in edits its argument (HIGH, D1 / defect)
**Classes:** src/reading/bib_reference_linker.e, ask/bib_ask_check.e, ingest/bib_note_importer.e, cli/bib_lookup.e
**Evidence:**
- src/reading/bib_reference_linker.e:99-111: `place_in (a_text: READABLE_STRING_GENERAL)`; `l_text := a_text.to_string_32` (106) returns the caller's own object when `a_text` is a STRING_32 (the aliasing the fix documents at src/text/bib_fence_tracker.e:34-35); then `l_text.left_adjust` (107), `l_text.right_adjust` (108) and `l_text.remove_tail (1)` (110) edit it in place. The later reassignments (112-120) only rebind the local after the damage is done.
- ask/bib_ask_check.e:325-331 `place_of (a_reference)`; its callers pass `a_call.text (...)`. BIB_ASK_CALL stores values by alias (ask/bib_ask_call.e:111 `texts_by_key.force (a_value.to_string_32, ...)`) and returns the stored object (:60-61). So the Ask check trims, and removes a closing period from, the reference stored in the helper's call. Anything reading the call afterward sees "John 3:16" where the helper said "John 3:16.". The comment at bib_reference_linker.e:99-101 says "with one closing period allowed"; the allowance is paid for by editing the caller.
- ingest/bib_note_importer.e:524-531 `place_of` and cli/bib_lookup.e:181 pass their own strings straight in; a STRING_32 argument is edited the same way.
- This is the previous HIGH (a reader that trims what it was handed) in the one reader the fix did not convert; it is older and shared by the Ask check, the importer and the CLI.
**Suggested Action:** `create l_text.make_from_string_general (a_text)` at line 106. Add a test (testing/test_reading.e near :189): `place_in` on a STRING_32 holding "  Gen 1 1. " leaves it equal to "  Gen 1 1. "; and the same through BIB_ASK_CALL, checking the stored value.
**Effort:** 1 line + 2 tests

### Finding 2: keep's rescue and retry semantics (MEDIUM, safety)
**Classes:** ingest/bib_note_importer.e
**Evidence:**
- ingest/bib_note_importer.e:178-208 (diff hunk): `l_failed` starts False; any exception in the else branch (set_aside, write_files, build, put_back, drop_set_aside) enters the rescue, sets `l_failed`, and `retry` runs the body again, which now takes the first branch: fixed message plus `put_back`. Locals keep their value across `retry`, so the flag works. This part is correct, and it fixes the previous scan's finding 2 (exception skipping put_back).
- Cause dropped: the rescue never reads the exception, so a contract violation, a locked file and out-of-memory all read "Keeping the note failed unexpectedly". A programming error in `build` is reported to the user exactly like a transient file problem.
- A second exception inside the retry (put_back raising) is not retried (`l_failed` is True), leaves the rescue and propagates to the GUI callback (gui_app/bib_gui_app.e:4426): an uncaught exception in the import path, with the earlier note's ".aside" files possibly still beside the new ones, the state the rescue was written to prevent.
- Exception after a good build (for example `drop_set_aside` raising): the retry runs `put_back`, which deletes the new note's files and restores the earlier ones; the non-Void result makes import_note skip the pack swap (4426-4428), so files and live pack agree on the earlier note and the user is told so. Acceptable. A stale `.new` pack is removed by import_note at 4421-4423.
- set_aside (ingest/bib_note_importer.e:230-246) still ignores every rename result (`l_ok` never read), unchanged from the previous scan.
**Suggested Action:** put the exception description into the returned message; report "the earlier note may be incomplete" when put_back itself raises instead of letting it propagate.
**Effort:** 1 feature

### Finding 3: the rollback order in swapped_notes_pack (MEDIUM, safety)
**Classes:** gui_app/bib_gui_app.e
**Evidence:**
- gui_app/bib_gui_app.e:4461-4496 (post-merge). Order now: close; delete a stale ".old"; move `a_pack` to ".old"; rename `a_new` into place (restore ".old" when that fails); `bible.open`; then, when `Result = Void and not bible.is_open`, delete `a_pack`, rename ".old" back, `bible.open`; else when an old pack existed, delete ".old". Reopening BEFORE the ".old" delete is what the previous scan's finding 3 asked for; that part is resolved.
- New regression: the `elseif l_had_old then delete .old` is now the else of `if Result = Void and not bible.is_open`, so it also runs when `Result` was set by the earlier failure branches. Case: the new pack could not be renamed into place and the restore of ".old" ALSO failed (`l_ok` False, 4474); control reaches the delete and removes ".old", the only copy of the old pack. Before the diff this delete sat in the success arm of the first chain and was not reached after a failed rename.
- The rollback branch builds "the old one is back" (4480) BEFORE the delete, rename and reopen it describes, and neither `l_ok` (4486, 4488) is read. If the delete of the new pack fails (a failed `bible.open` may still hold the file; SQLite on Windows keeps handles) the rename of ".old" onto the same name also fails, `bible.open` reopens the new pack (it may now succeed), and the report still says the old pack is back while the new one is live. The final check (4494-4496) catches only a closed engine, not an engine open on the wrong pack.
**Suggested Action:** delete ".old" only when the new pack opened; compose the message AFTER the restore from the `l_ok` results.
**Effort:** 1 feature reordered

### Finding 4: tests do not exercise the new paths (MEDIUM, tests)
**Evidence:**
- testing/test_facade_open.e:715-717 and 922-924 (diff hunks): two indentation assertions through `split` and `read`; they fail on the pre-fix tracker, good.
- Nothing covers: keep after an injected exception (the retry branch), swapped_notes_pack (either arm), place_in leaving its argument alone, mended_query leaving `a_query`, BIB_NAME_LIST.add leaving its name. The aliasing fix now spans six classes with two tests.
**Suggested Action:** one "does not edit its argument" test per reader: pass a STRING_32 with leading and trailing spaces, compare after. A small helper in the test set would carry all of them.
**Effort:** 5 tests

### Finding 5: the copy-then-edit idiom is repeated (LOW, A1)
**Evidence:** `make_from_string_general` followed by left_adjust / right_adjust in src/text/bib_fence_tracker.e:36-40, src/reading/bib_suggestion_line.e:24-26, src/reading/bib_name_list.e:92-96, gui_app/bib_gui_app.e:4601-4603; `trimmed` exists only in ingest/bib_note_importer.e (used at 465, 480). A once `trimmed (a_text): STRING_32` (a copy by construction) in a shared ancestor would make the safe form the short form.
**Effort:** 1 helper, 5 call sites

### Finding 6: stored arguments are aliases (LOW, edge)
**Evidence:** ask/bib_ask_call.e:26 `name := a_name.to_string_32`, :111 `texts_by_key.force (a_value.to_string_32, ...)`; src/reading/bib_link_target.e:29 `text := a_target.to_string_32`; src/reading/bib_reading_verse.e:35 `text := a_text.to_string_32`. Nothing in the scanned clusters mutates these after storing today, but each ties the stored value to the caller's string; finding 1 shows the cost when one reader later trims it.

### Finding 7: dead close in the rollback (LOW, dead code)
**Evidence:** gui_app/bib_gui_app.e:4482-4484 `if bible.is_open then bible.close end` sits inside the branch whose condition (4477) includes `not bible.is_open`; the guard is always False.

### Finding 8: a failed swap leaves the new note's files behind (LOW, edge)
**Evidence:** keep has already run `drop_set_aside` when `swapped_notes_pack` is called (gui_app/bib_gui_app.e:4429). When the swap fails and the old pack is back, the notes folder holds the new note and no copy of the earlier one while the live pack still holds the earlier one; the next build rebuilds from the folder. The report says the pack could not be put in place, not that the note's files were kept.

## Sweep: remaining `to_string_32` / `to_string_8` followed by a mutation

Searched ingest/, ask/, src/reading/, src/text/, build/ for every `to_string_32`, `as_string_32`, `to_string_8` and every in-place mutator (left_adjust, right_adjust, prune_all, replace_substring_all, remove_head/tail, append, to_lower/upper, wipe_out).
- Still wrong: src/reading/bib_reference_linker.e:106-110 (finding 1) only.
- Fixed by this diff and verified: bib_fence_tracker.e:36-40, bib_suggestion_line.e:24-26, bib_name_list.e:92-96, bib_note_importer.e:99-102, bib_ask_check.e:257, bib_gui_app.e:4601.
- Checked and safe (copy or no mutation): ask/bib_ask_check.e:229-233 (`.twin`), :343 (read only); src/reading/bib_bible_link.e:55 (rebinds, no mutation); src/reading/bib_reference_linker.e:139 (`l_text` read only, Result built separately); src/reading/bib_book_abbreviations.e:148 (`.twin`); src/reading/bib_text_reader.e:312-318 (`.twin`); ingest/bib_note_importer.e:227 (rebound, not edited); build/bib_markdown_blocks.e:84-86 (`without_mark` and `without_front_matter` return the argument itself, but `split` and `without_comments` only read it; `ic.twin` at 92 copies each line); ask/bib_ask_check.e:288-298 `joined_by` edits `a_query` on purpose (it is mended_query's own working copy).
- build/bib_markdown_blocks.e:339 `without_front_matter` returns the caller's text as `Result := a_text`: safe today; an in-place edit of its result would reach the caller.

## Recommended Order

1. Finding 1 (one line; same class as the previous HIGH; the Ask check, the importer and the CLI all reach it).
2. Finding 3 (the ".old" delete after a failed restore is a regression this diff introduced).
3. Findings 4 and 5 (tests for "does not edit its argument", then a shared trim helper).
4. Finding 2, then the LOWs.
