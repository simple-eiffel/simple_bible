# Design Scan (diff mode): simple_bible, since ea4d9c8
# Date: 2026-10-30
# Subjects: the Scholar Guides feature (14 files changed; the source diffs read in full)
# Mode: read-only, nothing compiled, nothing run

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Defects (rollback / partial failure / drift) | 6 | 2 | 4 | 0 |
| Abstraction / MI (duplication, helper objects) | 4 | 0 | 4 | 0 |
| Cleanup (tokens, naming, dead path) | 4 | 0 | 0 | 4 |
| **Total** | **14** | **2** | **8** | **4** |

HIGH = a live defect or drift with a concrete failing input (the skill's rule).

## Findings

| # | Priority | Where | Opportunity |
|---|----------|-------|-------------|
| 1 | HIGH | ingest/bib_note_batch.e rescue path | A failure that raises after a pack was built leaves `guides_built` and `retired` set; the postcondition then fails inside the rescue |
| 2 | HIGH | ingest/bib_note_batch.e, gui_app/bib_gui_app.e | No stale mark exists between "files kept" and "pack swapped": an interrupted import makes a guide permanently "already imported" with no pack |
| 3 | MEDIUM | ingest/bib_note_batch.e restore_note, drop_retired | Rename and delete results are discarded, so "all put back" can be untrue and silent |
| 4 | MEDIUM | gui_app/bib_gui_app.e packs_put_in_place | Retired note is deleted before either swap; guides swap first, so a notes-swap failure lists the id twice |
| 5 | MEDIUM | ingest/bib_note_importer.e work_chapter | Written to the manifest, read by nothing; guides list in file-name order |
| 6 | MEDIUM | ingest/bib_note_batch.e run_files | A note imported with the id of a kept guide is not handled (the reverse case is) |
| 7 | MEDIUM | ingest/bib_note_batch.e run_files | The `folder_for` pair repeated 9 times; places should answer by kind |
| 8 | MEDIUM | batch, importer, window | Note and guide schema once-objects duplicated; BIB_TEXT_PACKS already is the registry |
| 9 | MEDIUM | gui_app/bib_gui_app.e swapped_pack, pack_removed | Two copies of the close / rename-aside / reopen / restore protocol inside a 6000-line window class, untested |
| 10 | MEDIUM | four Is_kept_apart filters | The same "writings packs" and "guide packs" filter written in four places; the facade should own it |
| 11 | LOW | ingest/bib_note_batch.e | `Stale_marker` still named for notes, now used for guides |
| 12 | LOW | gui_app/bib_gui_app.e | `Study_guides_tab` and `Author_library_tab` are both 4 (different tab sets); bare tab integers |
| 13 | LOW | ingest/bib_note_importer.e | `is_guide` by object identity of a once; `keep` now only reached by tests |
| 14 | LOW | ingest/bib_note_importer.e work_label | Surname taken as the last word of the author |

(Finding 10 is counted under Abstraction / MI; Findings 7-10 are the four there.)

## Detailed Findings

### Finding 1: the rescue path leaves the run state half-reset (HIGH)
**Category:** D1 (the normal failure path and the rescue path diverged)
**Evidence:**
- `ingest/bib_note_batch.e` lines 160-174 (the `if l_failed` branch): sets `last_error`, puts back `l_written`, calls `restore_retired`, wipes `kept` and `replaced`. It does NOT wipe `retired` and does NOT clear `notes_built`, `guides_built`, `notes_now_empty`.
- The ordinary failure branch (lines 265-278) clears all of them: `retired.wipe_out`, `notes_built := False`, `guides_built := False`, `notes_now_empty := False`. The ordinary branch should win.
- Postcondition, line 287: `last_error /= Void implies (kept.is_empty and not is_built)`; `is_built` is `notes_built or guides_built or notes_now_empty`.
- The rescue (lines 290-295) retries once; the second pass takes the `l_failed` branch, so a postcondition failure there is an unhandled exception to the caller.
**Concrete input:** one folder with a guide `a.prepared.md` (kind: guide) and a note `b.prepared.md`, where the notes build raises rather than returning an error (the importer comment near `bib_note_importer.e` line 364 records that SQLite raised on a bad pack path in scan 66). Line 258 has already set `guides_built := True`; the notes build at line 262 raises; the rescue sets `last_error` and restores files, but `guides_built` stays True, so `nothing_kept_on_failure` fails and the exception escapes into `import_folder` or `import_note` in the window (no report shown). `retired` also still lists the note, so `show_folder_report` would print "Moved from Notes to Scholar Guides" for a run that moved nothing.
**Suggested Action:** one private `undo_run (a_places)` (put back written, restore retired, wipe every list and flag) called from both branches. Effort: 1 feature, 2 call sites.

### Finding 2: no stale mark between "kept" and "swapped" (HIGH)
**Category:** D1 / partial failure
**Evidence:**
- `ingest/bib_note_batch.e` lines 280-283: on success the set-aside copies are dropped and `drop_retired` DELETES the retired note's chapter files and manifest (lines 382-399).
- The stale mark is written only by the window, after a swap fails: `gui_app/bib_gui_app.e` `pack_put_in_place` (line 4861) and `pack_removed` (line 4874) call `set_pack_stale (..., Result /= Void)`. Nothing writes it between `run_files` returning and the swap.
- `is_already_kept` (used at batch line 216) passes a kept, unchanged file over, so a second import does not rebuild.
**Concrete input:** import a folder holding one new guide `unseenrealm11` (taking the id of an existing note) and end the process (task manager, power loss, a crash inside `swapped_pack`) after `run_files` returns and before `guides.db.new` is renamed into place. The guide files are in the guides folder, the note's files are deleted, `guides.db` does not exist, no stale marker exists. Importing again reports "Already imported, unchanged" (`import_note`, around line 4655) and builds nothing; the Scholar Guides tab stays empty until the file is edited. Window start-up rebuilds only on a stale mark (`bib_gui_app.e` lines 281-289).
**Suggested Action:** call `set_pack_stale (folder, True)` inside `run_files` right after the files are kept and before returning, for each folder whose pack is built; the window clears it only after a successful swap. That also lets `rebuild_stale_packs` repair the interrupted case. Effort: a few lines in the batch.

### Finding 3: restore and drop ignore their own failures (MEDIUM)
**Evidence:** `ingest/bib_note_batch.e` `restore_note`, lines 365-380: each `rename_to` result goes into `l_ok` and is never read; `drop_retired`, lines 382-399, likewise.
**Concrete input:** the guide build fails (disk full) while a note's chapter file is open in an editor, so a rename is refused. `last_error` is set and the doc comment promises every retired note restored, yet the manifest may stay `.note.json.retired`; the note drops out of every later build and, at the next notes rebuild, out of the pack, with no message.
**Suggested Action:** `restore_note` returns BOOLEAN; failures go into `warnings` (or `last_error`) so the window names the note left retired.

### Finding 4: the retired note is deleted before either swap; swap order (MEDIUM)
**Evidence:** batch line 283 (`drop_retired`) runs before `packs_put_in_place` (`bib_gui_app.e` line 4695), which swaps guides first, then notes.
**Concrete input:** a guide takes id `sermon8`; the guides swap succeeds and the notes swap fails (for example a stray `notes.db.old`, the rule in `swapped_pack`, line 4920). The live guides pack and the live notes pack both hold `sermon8`, and the note's files are already gone; only a rebuild of the notes folder repairs it. The stale mark on the notes folder makes the next start repair it (so this is MEDIUM, not HIGH), but until then both lists show it. Say so in the doc comment, or swap notes first.

### Finding 5: `work_chapter` written, never read (MEDIUM)
**Category:** D1
**Evidence:** `ingest/bib_note_importer.e` line 288 writes `"work_chapter"` into the manifest; no reader exists anywhere in the repository (grep). `src/pack/bib_book_pack.e` line 51 orders books by `ordinal`, which `build/bib_book_builder.e` assigns in manifest load order (lines 241-249).
**Concrete input:** guides `unseenrealm1` through `unseenrealm11`. They load in file-name order 1, 10, 11, 2, 3, ..., so the Scholar Guides list shows Chapter 10 before Chapter 2, although the header carried `work_chapter` for exactly this reading order (importer description, line 24).
**Suggested Action:** the builder (or a schema hook such as `manifest_order`) sorts manifests by `work_chapter` then id when it assigns `ordinal`.

### Finding 6: a note arriving with a guide's id (MEDIUM)
**Evidence:** `run_files` lines 244-253 retire a NOTE when a GUIDE takes its id; nothing checks the reverse. The skip test at line 216 looks only at the incoming file's own folder.
**Concrete input:** keep guide `sermon8`, then import an old `sermon8.prepared.md` that has no `kind: guide`. A note `sermon8` is kept beside the guide; both packs list `sermon8` (links `note:sermon8/..` and `guide:sermon8/..`). Refuse it in `run_files` with "its id is a scholar guide already".

### Finding 7: the `folder_for (notes, guides)` pair at every site (MEDIUM)
**Category:** A5
**Evidence:** `ingest/bib_note_batch.e` lines 168, 216, 219, 220, 223, 226, 237, 270, 281 each call `folder_for (a_places.notes_folder, a_places.guides_folder)`; the importer's `folder_for` is an `if is_guide` over two arguments. `packs_put_in_place` (`bib_gui_app.e` line 4695) spells out guides then notes by hand.
**Description:** BIB_INGEST_PLACES holds five loose fields; the kind-to-folder choice is spread over the importer, the batch and the window. A third kind means editing about ten sites.
**Suggested Action:** BIB_INGEST_PLACES gets `folder_of (a_schema)` and `pack_of (a_schema)`; `run_files` keeps one local target per file; the batch exposes the kinds it built and the window loops over them. Effort: 2 features plus call-site edits.

### Finding 8: schema once-objects duplicated (MEDIUM)
**Category:** A1
**Evidence:** `Note_schema` and `Guide_schema` onces in `ingest/bib_note_batch.e` lines 316-324 and `ingest/bib_note_importer.e` lines 145-154; the window writes `create {BIB_NOTE_SCHEMA}` and `create {BIB_GUIDE_SCHEMA}` in `rebuild_stale_packs`. `BIB_TEXT_PACKS.schema_of_kind` (`src/pack/bib_text_packs.e` line 32) already is the registry, and the window already uses it (line 4371).
**Description:** `is_guide` (importer line 89) compares object identity with the importer's own once, which holds only while every reader shares that object.
**Suggested Action:** one BIB_TEXT_PACKS query per kind shared by all three; `is_guide` becomes `schema.Is_kept_apart`.

### Finding 9: the swap protocol copied inside the window class (MEDIUM)
**Category:** A5 / A6 (helper object)
**Evidence:** `gui_app/bib_gui_app.e` `swapped_pack` (line 4920) and `pack_removed` (line 4874) both check a leftover `.old`, `bible.close`, rename aside, `bible.open`, test `is_open`, restore on failure, delete `.old`. Only the "new pack renamed in" step differs. No test covers either: `test_guides_kept_apart` stops at the batch.
**Suggested Action:** extract BIB_PACK_SWAP (pack path, new path, bible; `put_in_place`, `remove`, `last_error`), held by the window and testable without a screen.

### Finding 10: the Is_kept_apart filter written four times (MEDIUM)
**Category:** M2 / A5
**Evidence:** `src/simple_bible.e` lines 216-221 (writings), `src/reading/bib_name_list.e` line 38 (names), `gui_app/bib_gui_app.e` `library_packs` (line 4188, `not ... Is_kept_apart`) and `guide_packs` (line 4202, `... Is_kept_apart`).
**Suggested Action:** `SIMPLE_BIBLE.writings_text_packs` and `SIMPLE_BIBLE.guide_packs` (or two BIB_TEXT_PACKS queries); the window, the name list and the writings search read those.

### Finding 11: the stale marker is still a notes marker (LOW)
`ingest/bib_note_batch.e` line 139 `Stale_marker = "notes-pack-stale.txt"` is written into the guides folder too; the text inside now says "pack" (lines 130-137) but the file name and the placement of `is_pack_stale` in BIB_NOTE_BATCH read as notes-only. Use a neutral name (still reading the old one for folders already marked) and move it to BIB_INGEST_PLACES.

### Finding 12: token drift in tab indexes (LOW)
**Category:** T1. `bib_gui_app.e` lines 4158-4164: `Study_guides_tab = 4` (commentary tabs) and `Author_library_tab = 4` (results tabs); `Scholar_guides_tab = 6` (line 4231) and `Writings_tab = 5` (line 5306) are bare integers tied to `add_page` order (around line 1813-1824). Inserting a page shifts them silently (`sw_tabs.e` line 80 notes that an earlier tab shifts the selection without firing `on_change`). Name constants per tab set, or look an index up by page title.

### Finding 13: identity test for `is_guide`; a path only tests reach (LOW)
`bib_note_importer.e` line 89 (see Finding 8). `keep` (line 308) is no longer called by the window (`import_note` now runs `run_files`); only tests call it (`testing/test_facade_open.e` lines 926, 952, 990), so its build path is a second copy of the batch's.

### Finding 14: surname by last word (LOW)
`bib_note_importer.e` `work_label`: `last_index_of (' ', ...)` gives "Jr." for "Martin Luther King Jr." and "III" for "Ben Witherington III". The first case (Heiser) is fine; a `work_author_short` header field would be exact.

## Checks that came out clean
- Retirement rollback order: `put_back` of written files, then `restore_retired` (including a note caught mid-retire through `retiring`); `retire_note` undoes its own partial renames (lines 328-349).
- `.retired` files are invisible to the builder (`has_files` and the builder read `.json`; the renamed manifest ends `.retired`).
- Duplicate ids inside one run are refused before any write (batch lines 205-208), so a guide and a note of one id cannot both be written in one run.
- Scholar Guides tab and the shared reader: `select_tab` fires `on_change` only when the index changes (`sw_tabs.e` lines 286-296); `show_book_place` shelves first, so the second `show_shelf` is a no-op; import reports shown at the Author Library index move the shelf back through `on_results_tab`. Consistent. The reader is built once (`build_study_parts`), so the holders never double-parent it.
- Guides stay out of the Writings search, kit names, In the books and the Author Library (`simple_bible.e` 216-221; `bib_name_list.e` 38; `library_packs`).
- Test gap: nothing drives a failing guide build, a failed retire, the rescue, `swapped_pack` or `pack_removed`, or a note arriving with a guide's id. `test_guides_kept_apart` covers three happy runs plus reads and kit names.

## Recommended Order
1. Finding 1 (one `undo_run`): cheap, removes an exception path.
2. Finding 2 (mark stale before the swap): a few lines, closes the permanent-skip hole.
3. Findings 3 and 4 (report restore failures; order or document the swap).
4. Finding 5 (chapter order), then Findings 7 and 8 together, since they touch the same lines of `run_files`.
5. Finding 9 (BIB_PACK_SWAP) with the tests it makes possible, and Finding 10.
6. Findings 6 and 11-14 as they come.
