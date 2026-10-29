# Design Scan (diff mode): simple_bible since a26e0bb (scan 68)
# Date: 2026-10-29
# Mode: read-only; nothing compiled, nothing run. Every finding cites lines that were read.
# Subjects: src/reading/bib_reference_linker.e (place_in), gui_app/bib_gui_app.e (swapped_notes_pack),
#   testing/test_reading.e (new test lines). The diff also adds the previous scan's report (not code).
# Compared against: the three place_in callers (ask/bib_ask_check.e, ingest/bib_note_importer.e, cli/bib_lookup.e)
#   and the whole of src/reading/.
# Previous scan: .eiffel-workflow/evidence/design-scan-since-ab2e46e.md

## Verdicts on the previous scan

- Previous HIGH (finding 1, place_in editing the caller's string): RESOLVED.
  src/reading/bib_reference_linker.e:106 now reads `create l_text.make_from_string_general (a_text)`; the
  trims at 107-108 and `remove_tail` at 110 work on the copy. Later rebinds (112-120) only touch the local.
  The one other `to_string_32` in the file (line 140, in `linked`) is read-only: `Result` is built
  separately, so it is safe. The three callers (ask/bib_ask_check.e:328, ingest/bib_note_importer.e:527,
  cli/bib_lookup.e:181) pass their strings in and now get them back intact. The new test
  (testing/test_reading.e:186-189) passes a STRING_32 "  Jude 9. " and compares it afterward; on the old
  code the trims would have changed it, so the test would have failed before the fix.
- Previous MEDIUM (rollback order, finding 3): RESOLVED in both parts.
  (a) The `.old` delete after a failed restore: gui_app/bib_gui_app.e:4495 is now
  `elseif Result = Void and l_had_old`, so it runs only when no failure was recorded; after a failed
  rename-in plus failed restore, `.old` survives.
  (b) The message is built after the step it describes, from the rename result (4472-4478 and 4487-4493):
  "the old one is back." only when the rename returned True, else "the old one is kept as <path>.".
  The dead `if bible.is_open then bible.close end` (previous finding 7) is gone.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 0 |
| MEDIUM | 1 (finding 1) |
| LOW | 3 (findings 2-4) |
| **Total** | **4** |

## Findings

| # | Priority | Category | Where | Finding |
|---|----------|----------|-------|---------|
| 1 | MEDIUM | safety | swapped_notes_pack, closing check | The truthful "kept as .old" message is overwritten by the final "could not open its data again" when the engine cannot open, which is the likely state after a failed restore |
| 2 | LOW | safety | swapped_notes_pack, start | The next import deletes a stale `.old` first, the copy the new message told the user was kept |
| 3 | LOW | safety | swapped_notes_pack, rollback arm | The delete of the new pack (`l_ok`, 4486) is still unread; when it fails the report says the new pack could not open, but the new pack may be live after the reopen |
| 4 | LOW | tests | testing/test_reading.e, swapped_notes_pack | The place_in test covers the direct call only; the swap arms and the Ask-call stored value are still untested |

## Detailed Findings

### Finding 1: the new truthful message is mostly overwritten (MEDIUM, safety)
**Evidence:**
- gui_app/bib_gui_app.e:4469-4478: when the new pack cannot be renamed into place and the restore of `.old`
  also fails, `Result` becomes "... renamed into place; the old one is kept as <path>.".
- In that state no pack sits at the live name (the old one was moved aside at 4469, the new one did not
  move), so `bible.open` (4480) is likely to fail. Then 4497-4499 runs `Result := "Simple Bible could not
  open its data again: ..."`, an assignment, not an append. The location of the old pack is lost, which is
  the very thing this diff set out to report.
- The same overwrite hits the rollback arm: 4487-4491 records "kept as <path>", 4494 reopens, and if that
  fails 4497-4499 replaces the text.
**Suggested Action:** at 4498 append to `Result` when it is already set (keep the first message, add the
open failure after it), instead of replacing it.
**Effort:** 1 statement

### Finding 2: the promised ".old" is deleted by the next import (LOW, safety)
**Evidence:** gui_app/bib_gui_app.e:4465-4467 deletes any existing `.old` before doing anything. After a
double failure (finding 1) the live pack is absent and `.old` is the only copy; the next import starts by
deleting it, though the message promised it was kept. The line is old; the new message creates the promise.
**Suggested Action:** skip that delete when the live pack is absent and `.old` exists (it is the pack), or
rename `.old` back at that point.
**Effort:** 1 condition

### Finding 3: the delete of the new pack is unread in the rollback (LOW, safety)
**Evidence:** gui_app/bib_gui_app.e:4486 `l_ok := ...delete` is never read. If it fails, the rename of
`.old` onto the same name at 4488 fails too, the message says "kept as <path>" (true), and `bible.open` at
4494 may then open the new pack while the message says it could not open. Narrow (needs a failed open that
holds the file, then a failed delete); the message about `.old` stays accurate, only the claim about the new
pack can be stale.
**Effort:** read `l_ok`, say "the new pack could not be removed"

### Finding 4: test scope (LOW, tests)
**Evidence:** testing/test_reading.e:186-189 checks a direct STRING_32 argument only. Not covered: the Ask
check path (ask/bib_ask_check.e:325-331 passes `a_call.text (...)`, a stored alias), and any arm of
swapped_notes_pack (a GUI method; unchanged from the previous scan's finding 4). Not introduced by this
diff; the new test is a correct, failing-before regression test for the fix it accompanies.

## Checked and clean (no issue from this diff)

- `Result.append` / `append_character` on the detachable `Result` (4473-4477, 4488-4492, 4494): `Result`
  was just assigned an attached STRING_32 on every path that reaches them.
- No new copy-then-edit repetition beyond the idiom already noted; no drift between place_in and its
  siblings (BIB_FENCE_TRACKER, BIB_SUGGESTION_LINE, BIB_NAME_LIST copy the same way).

## Recommended Order

1. Finding 1 (one statement; makes the new message survive).
2. Finding 2 (completes the "old one is kept" promise).
3. Findings 3 and 4 when the swap is next touched.
