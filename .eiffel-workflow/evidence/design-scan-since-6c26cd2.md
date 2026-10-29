# Design Scan (diff mode): simple_bible since 6c26cd2 (the fixes for scan 66's five HIGH findings)
# Date: 2026-10-29
# Mode: read-only; nothing compiled, nothing run. Every finding cites lines that were read.
# Subjects: src/text/bib_fence_tracker.e (new), build/bib_markdown_blocks.e, ingest/bib_note_importer.e,
#   src/pack/bib_book_pack.e, gui_app/bib_gui_app.e (import_note, swapped_notes_pack), testing/test_facade_open.e.
# Compared against: all of src/, build/, ingest/. Previous scan: .eiffel-workflow/evidence/design-scan-since-c364fae.md

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 1 (finding 1) |
| MEDIUM | 4 (findings 2-5) |
| LOW | 5 (findings 6-10) |
| **Total** | **10** |

## Verdicts on the previous HIGH findings

| Prev # | Verdict | Why |
|--------|---------|-----|
| 1 suggestion checked as a line, stored as a block | RESOLVED in design | split_chapters (ingest/bib_note_importer.e:463-468) puts blank lines around a standalone suggestion line, so the builder's block reader sees a block of its own. Finding 1 below damages the same text (indentation), a separate defect. A suggestion straight after a heading still attaches to the next paragraph (prev finding 8, unchanged). |
| 2 reasons paired with blocks by position | RESOLVED | src/pack/bib_book_pack.e:141-148 selects `s.reason AS reason` in the block query; blocks_answer reads it from the same row (bib_book_pack.e:253-255). The second query is gone. Residual: finding 4 (detection by substring) and finding 8. |
| 3 import_note close/swap/reopen without a failure path | MOSTLY RESOLVED | swapped_notes_pack (gui_app/bib_gui_app.e:4454-4483) keeps the old pack as ".old", checks the move aside and the rename, restores on a failed rename, and checks `bible.is_open`. Residual: finding 3 (a failed reopen has no rollback; the old pack is already deleted). |
| 4 write_files deletes before the build is known good | RESOLVED for the failure paths the code returns | keep (ingest/bib_note_importer.e:175-193) sets the earlier note aside, writes, builds, and on any returned error puts back; the build guard for a missing folder is at 207-211. Residual: finding 2 (an exception skips put_back; stale ".aside" files). |
| 5 fence readers disagree | RESOLVED for the call sites converted, but the fix introduced finding 1 | one rule in BIB_FENCE_TRACKER, used at build/bib_markdown_blocks.e:95, 369 and ingest/bib_note_importer.e:382, 457. `unwrapped` (importer :521-533) still has its own rule (finding 7). |

## Findings

| # | Priority | Category | Where | Finding |
|---|----------|----------|-------|---------|
| 1 | HIGH | D1 / defect | BIB_FENCE_TRACKER.feed | `to_string_32` returns the caller's own object for a STRING_32, so `feed` strips carriage returns and leading spaces from the caller's line; every caller then uses the damaged line |
| 2 | MEDIUM | safety | BIB_NOTE_IMPORTER.keep | No `rescue`; an exception between set_aside and put_back leaves the poisoned state again; a stale ".aside" next to a live file is handled by luck |
| 3 | MEDIUM | safety | bib_gui_app swapped_notes_pack | A failed reopen is reported but not rolled back, the old pack is already deleted, the window stays bound to a closed engine, and the report names the wrong step |
| 4 | MEDIUM | D1 / fragile | BIB_BOOK_PACK.blocks_suggesting, blocks_answer | The SQL is built by slicing `blocks_sql` at " FROM ", and the reason column is detected by `has_substring (" AS reason")` in the statement text |
| 5 | MEDIUM | tests | testing/test_facade_open.e | No test of the tracker, of indentation kept, of a reason aligned with its block, of swapped_notes_pack, or of a stale ".aside" |
| 6 | LOW | edge | swapped_notes_pack | Restore of the old pack ignores its own failure yet the message says "the old one is back"; a later message overwrites an earlier one |
| 7 | LOW | A5 | BIB_NOTE_IMPORTER.unwrapped | A seventh fence reader remains (start and end characters may differ; length ignored) |
| 8 | LOW | edge | blocks_suggesting | A block with two suggestions covering the verse is still listed twice (now each row carries its own reason) |
| 9 | LOW | edge | BIB_FENCE_TRACKER | Four-space-indented fence lines count as fences; a backtick fence whose info string holds a backtick opens a fence |
| 10 | LOW | edge | BIB_NOTE_IMPORTER.put_back | When no earlier note existed, the new note's empty folder is left behind |

## Detailed Findings

### Finding 1: the tracker damages the line it is fed (HIGH, D1 / defect)
**Classes:** src/text/bib_fence_tracker.e, build/bib_markdown_blocks.e, ingest/bib_note_importer.e
**Evidence:**
- src/text/bib_fence_tracker.e:36-38: `l_line := a_line.to_string_32` then `l_line.prune_all ('%R')` and `l_line.left_adjust`. In EiffelStudio's READABLE_STRING_GENERAL, `as_string_32, to_string_32` is "if attached {STRING_32} Current as l_result then Result := l_result": a STRING_32 argument comes back as the SAME object, not a copy. So the caller's string is modified. (The same aliasing is at ingest/bib_note_importer.e:99-100, `a_prepared.to_string_32` then `replace_substring_all`, which edits the caller's text; harmless there only by luck.)
- build/bib_markdown_blocks.e:92-95: `l_line := ic.twin` ... `fences.feed (l_line)`; then at 99 `current_lines.extend (l_line)` inside a code block. The line was left-adjusted by `feed`, so the indentation of every line in a code block is lost (the code branch keeps `l_line`, not the trimmed copy). Sample code in a book, essay or note loses its structure.
- build/bib_markdown_blocks.e:369-373 (`without_comments`): `l_fences.feed (l_lines.i_th (i))` then `l_piece := l_lines.i_th (i).twin`: the piece is the already-stripped line, so the text returned to `split` has NO leading whitespace on any line and no carriage returns, in code blocks and outside them. Nested list indentation and the "indented continuation of an item" signal (comment near bib_markdown_blocks.e:134) are gone before `split` sees them.
- ingest/bib_note_importer.e:382 (`check_body`): `feed (l_line)` where `l_line` is an element of `a_lines`; `read` passes the SAME list `l_lines` to `split_chapters` (lines 108 and 111), so the chapter text written to the note's `.md` files is already left-adjusted by `check_body`. Then 457-458: `feed (a_lines.i_th (i))` and `a_lines.i_th (i).starts_with ({STRING_32} "# ")` run on the stripped line, so an INDENTED "# ..." line inside a list or quote (outside a fence) now starts a new chapter; before the merge it did not.
- The previous HIGH 5 fix therefore changes behavior for books, essays and notes alike (the splitter is shared), and the damage is silent. The new tests (testing/test_facade_open.e:912-918) use unindented text, so they cannot see this.
**Suggested Action:** in `feed`, make the copy explicit: `create l_line.make_from_string (a_line.to_string_32)` (or `a_line.to_string_32.twin`) before the two edits. Add a test: a code block with a four-space indented line must come out of `split` and out of `read` (chapter text) with its indentation intact, and `without_comments` must return its input unchanged when there are no comments. Rebuild the books, essays and notes packs afterward: any pack built from the merged code lost code indentation.
**Effort:** 1 line + 2 tests + a pack rebuild

### Finding 2: keep has no rescue and trusts rename semantics (MEDIUM, safety)
**Classes:** ingest/bib_note_importer.e
**Evidence:**
- keep (175-193) restores only when `write_files` or `build` RETURNS a message. An exception raised inside either (the comment at 208-210 says SQLite "raised, past the restore of an earlier note" and only the missing-folder case was guarded) skips `put_back` and `drop_set_aside`. The earlier note stays as `.aside` files with no manifest, the new files and manifest stay in place: the previous HIGH 4 state again (every later build reads the new manifest; a bad one fails every import).
- set_aside (230-246) ignores each rename result (`l_ok` is never read). If a ".aside" file from an earlier interrupted run already exists beside a live file, the rename may fail, depending on SIMPLE_FILE move_to overwrite semantics (not verified here). Then the live `.md` is overwritten by write_files, and a failed build ends in put_back deleting the new files and restoring the OLDER aside: a version two imports old, silently.
- An earlier note whose files are already `.aside` with no live files: set_aside does nothing, write_files writes the new note, a failed build restores the aside (correct), a good build drops it (correct). That edge is fine. The failing edge is live AND aside both present.
- Shrinking replacement (five chapters to three): set_aside moves all five, drop_set_aside deletes the two extra asides, put_back deletes the three new files and restores five. Correct.
**Suggested Action:** wrap keep's body in a `rescue` that runs put_back once; make set_aside remove a leftover `.aside` first or refuse with a message; read `l_ok`.
**Effort:** 1 rescue clause + 1 loop edit

### Finding 3: a failed reopen has no rollback (MEDIUM, safety)
**Classes:** gui_app/bib_gui_app.e
**Evidence:**
- swapped_notes_pack 4454-4483: the success path deletes `.old` (4476-4477) BEFORE `bible.open` (4479). When `bible.open` leaves the engine closed (for example the pack folder now holds more than Max_generic_packs packs, src/simple_bible.e:92, 596), the code only sets `Result` (4480-4482). The old pack is gone; no attempt to reopen with it.
- import_note 4437-4439 then shows a report headed "The new notes pack could not be put in place", which is wrong: the pack WAS put in place; the engine could not open it. The branch skips fill_books and show_book_place, but the window's other panes remain bound to a closed engine.
- `Result` set at 4480 overwrites a more specific earlier message (the rename failure texts).
**Suggested Action:** reopen BEFORE deleting `.old`; on a failed reopen move the new pack aside, restore `.old`, reopen again, and say so; decide what the window does while the engine is closed.
**Effort:** 1 feature reordered

### Finding 4: reason column detected by substring (MEDIUM, D1 / fragile)
**Classes:** src/pack/bib_book_pack.e
**Evidence:**
- bib_book_pack.e:141-146: the statement is `"SELECT ... s.reason AS reason FROM " + blocks_sql.substring (blocks_sql.substring_index (" FROM ", 1) + 6, blocks_sql.count) + ...`. It depends on `blocks_sql` (225-231) having its first " FROM " right after the column list. A later change to the shared select (a subselect, a column containing " FROM ") builds a broken statement silently.
- bib_book_pack.e:253-255: blocks_answer calls `a_sql.has_substring (" AS reason")` for EVERY row. Any statement that happens to contain that text turns the feature on; the intent (this answer carries reasons) is not in the signature.
- blocks_citing (126-129) and blocks_naming (179) extend `blocks_sql` by appending after it; a `blocks_sql` variant taking extra select columns would serve all three.
**Suggested Action:** `blocks_sql_with (a_columns)` and a `with_reason: BOOLEAN` parameter on blocks_answer; add the postcondition "every block of a successful blocks_suggesting result has a non-empty suggestion_reason" (the importer refuses empty reasons).
**Effort:** 2 features

### Finding 5: tests (MEDIUM)
**Evidence:** testing/test_facade_open.e:912-918 and 943-948 add four assertions. Not tested: BIB_FENCE_TRACKER on its own (open, close, a four-backtick fence holding three backticks, a tilde fence, a closing line with trailing text, two fences back to back); indentation kept through `split` and `read` (finding 1); two suggestions on two blocks and the reason beside each block (previous HIGH 2); swapped_notes_pack (needs the helper moved out of the window, prev finding 12); a leftover ".aside" (finding 2). The put-back test passes `no_such_folder\notes.db`, which covers only the one guard added for it.
**Suggested Action:** a tracker test class first (pure, fast), then the integration tests.

### Finding 6: restore ignores its own failure (LOW)
swapped_notes_pack 4469-4471: the rename of `.old` back to the notes pack is assigned to `l_ok` and never read; if it fails, the pack is gone and the message still says "the old one is back".

### Finding 7: a seventh fence reader remains (LOW, A5)
ingest/bib_note_importer.e:521-533 (`unwrapped`) accepts a first line starting with three backticks or tildes and a last line ending with either (mixed characters allowed, no length). The tracker could answer "does the whole text stand inside one fence" by feeding the lines.

### Finding 8: block listed twice for two suggestions (LOW)
bib_book_pack.e:141-146 joins block_suggestion with one row per suggestion, so a block with two suggestions covering the verse returns twice; each row now carries its own reason (correct pairing), but there is no statement of the rule like blocks_citing's "each block once".

### Finding 9: tracker edge cases (LOW)
src/text/bib_fence_tracker.e:38 left-adjusts all whitespace, so a line indented four spaces or more is read as a fence. Lines 39-44 do not apply the CommonMark rule that a backtick fence's info string holds no backtick, so "```code``` more" opens a fence that swallows the rest of the text (the importer then skips every later check). Both existed before the merge; the tracker makes them one place to fix.

### Finding 10: empty note folder after put_back (LOW)
ingest/bib_note_importer.e:248-269: with no earlier note, put_back deletes the new `.md` files and manifest but leaves the folder write_files created. Harmless litter.

## BIB_FENCE_TRACKER closing-line semantics, caller by caller

The tracker keeps `is_inside` True THROUGH the closing line (cleared at the start of the next `feed`, src/text/bib_fence_tracker.e:45-48) and `was_fence_line` True on both the opening and the closing line.
- bib_markdown_blocks.split (95-109): uses `was_fence_line` to close (98-100) and to open (104); both fence lines stay in the code block. The skip-section test `fences.is_inside or else not (heading...)` (102) is right for both fence lines. Correct.
- bib_markdown_blocks.without_comments (369-381): the closing line is appended raw because `is_inside` is still True; `l_outside` is emptied at the opening line only. Correct apart from finding 1. A fence line inside a multi-line HTML comment still opens a fence (unchanged).
- importer check_body (382-383): opening and closing lines are skipped from the link and suggestion checks, as before. Correct.
- importer split_chapters (457-468): the `# ` test and the suggestion lift use `not is_inside`, so fence lines never start a chapter. Correct apart from finding 1.

The "AS reason" detection: finding 4. set_aside / put_back / drop_set_aside edge cases: findings 2 and 10. swapped_notes_pack when the engine fails to reopen: finding 3.

## Recommended Order

1. Finding 1 first: a one-line fix with a wide blast radius (every pack built from the merged code), with its test (finding 5) and a pack rebuild.
2. Finding 3, then finding 2 (small data-safety reorderings).
3. Finding 4 (one parameter), then the LOW items as convenient.
