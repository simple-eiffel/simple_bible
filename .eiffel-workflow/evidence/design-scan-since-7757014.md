# Design Scan (diff mode): simple_bible, since 7757014
# Date: 2026-10-30
# Subjects: src/reading/bib_reference_linker.e, ingest/bib_note_batch.e (new), ingest/bib_note_importer.e, gui_app/bib_gui_app.e, testing/test_reading.e, testing/test_facade_open.e
# Method: read-only; nothing compiled, nothing run; line numbers are from the working tree at HEAD

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Defects (logic, drift) | 6 | 1 | 3 | 2 |
| Abstraction (A5/A6) | 2 | 0 | 1 | 1 |
| Tests | 1 | 0 | 0 | 1 |
| **Total** | **9** | **1** | **4** | **4** |

## Findings

| # | Priority | Where | Finding |
|---|----------|-------|---------|
| 1 | HIGH | ingest/bib_note_batch.e:147-169, gui_app/bib_gui_app.e:4498 | Notes on disk but pack swap failed: re-import skips every file and builds nothing, so they never reach the pack |
| 2 | MEDIUM | ingest/bib_note_batch.e:150-153, ingest/bib_note_importer.e:289-304 | set_aside runs before the importer joins `l_written`; its rename failures are ignored, so rollback can lose the earlier note |
| 3 | MEDIUM | src/reading/bib_reference_linker.e:410-423 | A comma after a chapter-only reference reads a lone number as a CHAPTER ("Matthew 5, 6.") against the stated rule |
| 4 | MEDIUM | src/reading/bib_reference_linker.e:462-478 | `ends_a_reference` is stricter than the first reference: closing quote, `*`, `:` stop a list part; a ")" or text end lets a stray number link |
| 5 | MEDIUM | ingest/bib_note_batch.e:129-180, ingest/bib_note_importer.e:230-250 | Second copy of the set_aside / write / build / put_back / drop protocol and its rescue-retry |
| 6 | LOW | gui_app/bib_gui_app.e:4443-4448 vs 4500-4505, 4431-4436 vs 4489-4496 | Cache reset and `.new` cleanup copied between import_note and import_folder |
| 7 | LOW | gui_app/bib_gui_app.e:4482, 4469 | import_folder does nothing and says nothing when the engine is closed; a bare file name gives an empty folder |
| 8 | LOW | gui_app/bib_gui_app.e:4511-4558 | Report puts titles, file names, problems into markdown unescaped; "N imported" shown when the pack swap failed |
| 9 | LOW | testing/ | No test of rollback, the rescue path, the pack-swap failure, or list text ends |

## Detailed Findings

### Finding 1: Skipped forever after a failed pack swap (HIGH)
**Classes:** BIB_NOTE_BATCH, BIB_GUI_APP, BIB_NOTE_IMPORTER
**Description:** `BIB_NOTE_BATCH.run` drops the set-aside copies (ingest/bib_note_batch.e:177-179) as soon as the build into the `.new` pack succeeds. The batch has no knowledge of the live pack. The GUI then swaps the pack (gui_app/bib_gui_app.e:4498, `swapped_notes_pack`), which can fail: a stale `.old` pack (the message says "move it somewhere safe, then import again"), a locked pack file, a rename failure. When it fails, the notes and manifests are on disk, the live pack lacks them, and `import_folder` deletes `.new` at the next run (bib_gui_app.e:4491-4494). Importing again finds each file `is_already_kept` (ingest/bib_note_importer.e:166-187) true, puts it in `skipped`, leaves `l_written` empty, and the build at ingest/bib_note_batch.e:165 never runs. The report says "0 imported, N already imported", and the notes never reach the pack. The single-file path does not have this fault: `keep` (bib_note_importer.e:230-250) always writes and builds, so "import again" works there.
**Evidence:**
- ingest/bib_note_batch.e:147-149 skip on is_already_kept; :165 build only when `l_written` is not empty
- gui_app/bib_gui_app.e:4498-4507 swap result only reaches the report; nothing undoes or marks the kept notes
- gui_app/bib_gui_app.e:4547-4558 the report tells the user "import the folder again: what is in already is passed over"
**Concrete failing input:** Folder with `b.prepared.md` (new id `sermon9`); a `notes.db.old` is left in the pack folder from an earlier failed import. Run 1: files written, `.new` built, `swapped_notes_pack` returns the "kept from an earlier failed import is still at" message; the report shows "1 imported" plus the swap failure. The user moves the `.old` file away and imports the folder again: `sermon9` is `is_already_kept`, so it is skipped, nothing is built, and the live pack never gets `sermon9`. The only way out is to edit the prepared file so it counts as changed.
**Suggested Action:** a refactor branch, with Larry's word: (a) the GUI rolls the batch back (put back the notes) when the swap fails, or (b) the batch builds whenever the live pack lacks a skipped note, or (c) a "rebuild pack" button. Add a test with a stale `.old` pack.
**Effort:** 1 to 2 features plus 1 test

### Finding 2: Set-aside before registration, rename failures ignored (MEDIUM)
**Classes:** BIB_NOTE_BATCH, BIB_NOTE_IMPORTER
**Description:** In `run`, `l_importer.set_aside` (ingest/bib_note_batch.e:151) is called before `l_written.extend (l_importer)` (:152). An exception inside `set_aside` after some chapter files were renamed leaves that importer out of `l_written`, so the rescue branch (:107-115) never puts its files back. Separately, `set_aside` ignores every `rename_to` result (ingest/bib_note_importer.e:296-303, `l_ok` is never read). If a rename fails (a file held open, a leftover `.aside` file from a crashed earlier run), the old chapter file stays under its own name, `write_files` overwrites it, and on a later failure `put_back` (:307-327) deletes every `.md` and finds no `.aside` to restore: the earlier note's text is gone. The code predates the diff (it was `{NONE}` and used only by `keep`), but the batch now runs it over many notes per click.
**Concrete input:** `sermon9` kept with `01.md`; a crash earlier left `01.md.aside`; File > Import prepared folder with a changed `b.prepared.md` followed by a file that fails to write: the rename of `01.md` fails, the new `01.md` overwrites it, rollback deletes it, and the earlier text is gone. (Whether `rename_to` over an existing target fails depends on SIMPLE_FILE; not verified.)
**Suggested Action:** swap lines 151/152; make `set_aside` report failure and treat it as `last_error` before writing.
**Effort:** 2 features

### Finding 3: Comma after a chapter-only reference reads a chapter (MEDIUM)
**Class:** BIB_REFERENCE_LINKER
**Description:** The header note (src/reading/bib_reference_linker.e:20-23) says a lone number after "," that follows a verse is a verse. In `continuation_at` the verse branch needs `a_after_verse` (line 410); for a chapter-only reference (`end_verse = 0`, call at line 201) a comma falls through to `numbers_at` (line 423), which reads the lone number as a CHAPTER. If it then ends right (`,` `)` `;` text end, closing period) it links.
**Concrete input:** "Compare Matthew 5, 6." links `6` as Matthew 6; "(Psalm 23, 4)" links 4 as Psalm 4; "Genesis 1, 2." links Genesis 2. "in Matthew 5, 6 times" is safe (space then a letter fails `ends_a_reference`). It may be intended ("Psalm 23, 24" as chapters), but the header and tests do not say so.
**Suggested Action:** decide the rule with Larry: chapters after a comma only with a colon or a range, or document it; add a test either way.
**Effort:** 1 condition plus tests

### Finding 4: End-of-part rule is asymmetric (MEDIUM)
**Class:** BIB_REFERENCE_LINKER (`ends_a_reference`, lines 462-478)
**Description:** The first reference of a list needs no end check (`reference_at`, lines 220-262) but later parts do. Characters outside `; , ) newline carriage-return .` and " (" make the part stay unlinked: a double quote, apostrophe, `*`, `_`, `]`, `:`, `?`, `!`, an em dash. So "**Genesis 1:26; 3:5**" links the first part but leaves 3:5 plain (half-linked list). In the other direction a bare ")" or text end accepts a stray number: "(see Genesis 1:26, 12)" links 12 as verse 12.
**Evidence:** src/reading/bib_reference_linker.e:462-478; tests at testing/test_reading.e:187-200 cover only the space-then-letter case.
**Suggested Action:** treat emphasis marks and closing quotes as ends; add tests. Loops are safe: each pass of the loop at lines 200-209 moves `i` past `l_more.last` (contract `after_start`, lines 413-414).
**Effort:** 1 feature plus tests

### Finding 5: The set-aside transaction exists twice (MEDIUM, A6 helper-object candidate)
**Classes:** BIB_NOTE_IMPORTER.keep (ingest/bib_note_importer.e:230-250), BIB_NOTE_BATCH.run (ingest/bib_note_batch.e:98-190)
**Description:** Both run set_aside, write_files, build, then put_back on failure or drop_set_aside on success, both with an `l_failed` rescue/retry that puts the files back. The batch is a one-to-many generalisation, and they already differ: `keep` calls set_aside inside the `else`, so an exception there is covered by put_back; the batch calls it before registering (Finding 2). A third caller would be a third copy. The source-beside-it reading also exists twice (ingest/bib_note_batch.e:133-140 and `import_note` in gui_app/bib_gui_app.e), differing in where the `source` check sits.
**Suggested Action:** a small transaction helper (holds a list of importers; begin, commit, roll_back) that `keep` uses with one importer and the batch with many, so the rescue branch lives once. A refactor branch, with Larry's word.
**Effort:** 3 features

### Finding 6: Copied GUI blocks (LOW, A5)
**Class:** BIB_GUI_APP
**Description:** After a good swap, `import_note` (gui_app/bib_gui_app.e:4443-4448) and `import_folder` (:4500-4505) both clear `framework_names_cache`, `writing_names_cache`, `listed_book`, `listed_kind` and call `fill_books`. The `.new` cleanup and path building (:4431-4436, :4489-4496) is repeated too. One feature would own both; a cache added later is likely to reach one copy only.
**Effort:** 2 features

### Finding 7: Silent no-ops (LOW)
**Description:** `import_folder` is wrapped in `if bible.is_open` (gui_app/bib_gui_app.e:4482) with no else: a closed engine gives no message. `import_prepared_folder` takes `parent_path` of the picked file (:4469): a path with no folder part gives an empty folder, `prepared_files` returns an empty list (ingest/bib_note_batch.e:76), and the report says "No file in this folder ends in .prepared.md", which is misleading.
**Effort:** 2 lines

### Finding 8: Report text (LOW)
**Description:** `show_folder_report` (gui_app/bib_gui_app.e:4511-4558) places the folder path inside backticks and titles, file names and problem text raw into markdown; a title with a backtick or "[x](y)" changes the layout, and a title holding a Bible reference is linked by the reader. When the pack swap fails, the line "N imported" (:4512) is still printed beside the failure note.
**Effort:** 1 feature

### Finding 9: Test gaps (LOW)
**Description:** `test_a_prepared_folder_imports_once` (testing/test_facade_open.e:963-1013) covers skip, replace, refuse, duplicate id and a second run. Not covered: a write or build failure rolling back (`nothing_kept_on_failure`, ingest/bib_note_batch.e:183), the rescue/retry branch, an empty or missing folder, a pack swap failure (Finding 1). Linker tests (testing/test_reading.e:187-200) do not cover: a list at the very end of text ("Genesis 1:26; 3", "Genesis 1:26;", "Genesis 1:26, "), a page note at text end ("Genesis 1:26 (p."), a part followed by a closing quote or `*`, a chapter-only reference followed by a comma, or "Matthew 5:3; 2 Peter 1:3".

## Checked and found sound (no finding)

- Index bounds in `continuation_at`, `after_page_note`, `ends_a_reference`: every `a_text [k]` sits behind a `k <= count` guard (lines 401-425, 441-458, 465-476). Hand-traced "Genesis 1:26; 3" (text ends after the digit; `ends_a_reference` gets `count + 1` and returns True) and "Genesis 1:26;" (stops at the guard at line 404). The `(p.` and `(pp.` prefix tests are guarded by `a_start + 4` and `a_start + 5` against the count.
- Loop advance: the loop at lines 200-209 moves `i` to `l_more.last + 1`; `continuation_at` guarantees `first > a_start` and `last >= first` (lines 413-414), and the verse branch sets `last = l_after - 1 >= first`.
- Verse numbers above `Max_number` are refused on the lone-verse branch (line 419) and in `numbers_at` (lines 375-381), so "Genesis 1:1, 2023." does not link.
- "Romans 8:28, 30 people" and "John 3:16, 1 John 4:8" stay unlinked as the tests say; "; 2 Peter" and ", 2 Kings" fail `ends_a_reference` the same way (space then a letter).
- Batch: ids are lowercase (`is_book_id`), so case-insensitive file systems cannot hide a duplicate; `every_file_accounted` holds in the success path because each file goes to exactly one of kept, skipped, refused unless `last_error` is set; the rescue branch guards a Void `l_written` (line 109) and relies on locals surviving `retry`.

## Recommended Order

1. Finding 1 (live defect: the dialog's own advice, "import again", does nothing).
2. Finding 2 (data-loss path in the rollback that the Finding 1 fix will touch too).
3. Finding 5 (together with 2: one transaction helper).
4. Findings 3 and 4 (decide the list rules with Larry, then pin them with tests, Finding 9).
5. Findings 6 to 8 (cleanup).
