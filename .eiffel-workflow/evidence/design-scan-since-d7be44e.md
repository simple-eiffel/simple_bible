# Design Scan (diff mode): simple_bible, since d7be44e
# Mode: read-only, no compile, no test run. Evidence is from reading the files at HEAD and the diff.
# Subjects: src/reading/bib_reference_linker.e, ingest/bib_source_reader.e (new), ingest/bib_kit_folder.e (new),
#           gui_app/bib_gui_app.e, testing/test_reading.e, testing/test_facade_open.e, testing/test_app.e

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Defects (logic) | 7 | 2 | 3 | 2 |
| Abstraction (A5/A6) | 2 | 0 | 1 | 1 |
| Tests | 1 | 0 | 1 | 0 |
| Cleanup | 1 | 0 | 0 | 1 |
| **Total** | **11** | **2** | **5** | **4** |

## Findings

| # | Priority | Category | Subject | Finding |
|---|----------|----------|---------|---------|
| 1 | HIGH | logic | BIB_KIT_FOLDER | Two sources with the same stem ("ch01.md", "ch01.txt") share one kit path; the second is reported "up to date" and never gets a kit |
| 2 | HIGH | logic | BIB_REFERENCE_LINKER | Any bare number before a book name ("In 1517 Romans 1:17 ...") suppresses the link |
| 3 | MEDIUM | logic | BIB_KIT_FOLDER | Up-to-date rule is mtime-only: a source restored with an older mtime, or Bible content that changed, leaves a stale kit "current" |
| 4 | MEDIUM | logic | BIB_KIT_FOLDER / test | `>=` on equal timestamps plus the test's immediate rewrite can miss a change (flaky test, silent skip) |
| 5 | MEDIUM | A5 | BIB_GUI_APP | Third copy of "build, swap, mark stale, reset caches, fill_books" |
| 6 | MEDIUM | logic | BIB_GUI_APP | rebuild_notes_pack with no `.json` notes clears the mark but leaves the old pack live |
| 7 | MEDIUM | tests | testing | No test for the cases above (same stem, number words, rebuild_notes_pack, tie timestamps) |
| 8 | LOW | logic | BIB_REFERENCE_LINKER | Capitalized heading "Vision of Isaiah 6" / "Life of Jonah 1" is not linked; only a plain space is read as the separator |
| 9 | LOW | logic | BIB_GUI_APP | A notes pack that always fails to build is retried synchronously at every start |
| 10 | LOW | A6 | BIB_GUI_APP | Three "pending + ticks" pairs (folder import, kit folder, notes rebuild) in one tick handler |
| 11 | LOW | cleanup | linker / kit folder | `l_first` is a pointless alias; `every_source_accounted` re-lists the folder; `sources` sorts case-sensitively |

## Detailed Findings

### Finding 1: Same-stem sources collide on one kit file (HIGH)
**Evidence:**
- ingest/bib_kit_folder.e:71-87 `kit_path_for` drops the extension and appends ".kit.md", so "ch01.md" and "ch01.txt" both map to "ch01.kit.md".
- ingest/bib_kit_folder.e:100-133 `run` handles sources in name order. "ch01.md" writes the kit; for "ch01.txt", `is_kit_current` (line 89-96) finds a kit that exists and is newer than "ch01.txt", so the source is added to `skipped` (shown as "up to date already").
**Concrete input:** a folder with `ch01.md` and `ch01.txt` (an export in both formats). Run "Make ingest kits for a folder": one kit, made from `ch01.md`; `ch01.txt` is reported up to date and is never made a kit. If `ch01.txt` is edited later it is newer than the kit, so it overwrites the kit made from `ch01.md` and lists it as "remade"; the next run remakes it from `ch01.md`'s side only if that is newer, so the two flip-flop.
**Why the postcondition does not help:** `every_source_accounted` (line 132) counts skipped as accounted.
**Suggested Action:** include the source's extension in the kit name when another source has the same stem, or refuse and list the pair under `failed` ("ch01.md and ch01.txt share a kit"). Decide with Larry; the kit name is also what the prepared file's name is derived from by hand, so a rename affects the workflow text in `make_kits` (bib_gui_app.e:4437).
**Effort:** 1 feature plus a test.

### Finding 2: A bare number before a book name hides a real reference (HIGH)
**Evidence:**
- src/reading/bib_reference_linker.e:415-417: when the word before the book name is a natural number, `Result` is true unless that number is itself part of a longer token (letter, digit, ".", ":" before it). Nothing checks that the number could be an edition or work number ("4 Ezra"); any number counts.
- Linker line 196 then discards the match.
**Concrete input:** "In 1517 Romans 1:17 changed Luther." leaves "Romans 1:17" unlinked ("1517 " is a natural-number word standing alone). The same for "the 12 Luke 10:1 disciples", "chapter 3 John 3:16" (though "3 John" is read from its number first), "note 3 Romans 8:1", "Figure 2 Isaiah 40". The test at testing/test_reading.e:201 ("as 4 Isaiah 1:1 has it") only covers the intended case; no test covers a year or count.
**Suggested Action:** restrict the number rule to the numbers that make a work with the following name (the apocrypha set: 1-4 before Ezra, Esdras, Enoch, Baruch, Maccabees and the like) or to a number of one or two digits not following "chapter", "note", "verse", "figure". Keep "III.6 Romans 7" and "1 John" as they are.
**Effort:** 1 feature, 3 test lines.

### Finding 3: Up-to-date rule is mtime only (MEDIUM)
**Evidence:** ingest/bib_kit_folder.e:89-96 `is_kit_current` is `kit exists and kit mtime >= source mtime`.
- A source copied or unzipped with a preserved older mtime over an existing newer kit is skipped although its text changed (restore from backup, archive extraction).
- A kit lists what Simple Bible holds (BIB_INGEST_KIT.make takes the Bible, bib_kit_folder.e:106, line 194 of the pre-split listing); when the content changes (new version, new pack) every kit stays "current" with a stale list.
**Concrete input:** extract `ch02.txt` (edited, mtime from last week) over a folder whose `ch02.kit.md` was written yesterday: skipped, the kit is for the old text.
**Suggested Action:** keep a hash of the source text (and a content version) in the kit's first line, and compare that; mtime stays only as the cheap pre-check. Or document the rule in the menu help line.
**Effort:** 1 feature.

### Finding 4: Tie timestamps and the test that depends on them (MEDIUM)
**Evidence:** `>=` at ingest/bib_kit_folder.e:95; testing/test_facade_open.e (test_kits_for_a_folder) rewrites `ch02.txt` right after the second `run`, then expects a remake. File times on Windows can share a tick when the writes are a few milliseconds apart, so the kit (older write) and the source can compare equal, and `>=` calls the kit current.
**Concrete input:** the test on a fast machine: first run writes `ch02.kit.md`; second run only reads; the rewrite of `ch02.txt` can land on the same timestamp as the kit, so `remade.count = 1` fails (flaky), and in real use a source saved within one tick after a kit is silently skipped.
**Suggested Action:** make the test set the source's mtime later explicitly, or sleep past the clock resolution; consider `>` for source-newer-or-equal being remade (cost: a rare extra kit).
**Effort:** 1 line in the rule, 1 in the test.

### Finding 5: Third copy of the notes-pack tail (MEDIUM, A5)
**Classes:** BIB_GUI_APP
**Evidence:**
- gui_app/bib_gui_app.e:4594-4635 `rebuild_notes_pack`: pack path building, delete of `.new`, build, `swapped_notes_pack`, `set_pack_stale`, then `framework_names_cache := Void`, `writing_names_cache := Void`, `listed_book`/`listed_kind` reset, `fill_books`.
- gui_app/bib_gui_app.e:4548-4580 `import_folder`: the same sequence (about 14 lines).
- gui_app/bib_gui_app.e:4497-4518 (`import_prepared_notes`): the same path building and the same cache reset.
**Description:** one feature (for example `put_notes_pack_in_place (a_build: FUNCTION...)` or two: `notes_pack_paths` and `refresh_after_notes_pack`) would own the paths, the stale mark and the cache reset, so a future change (say a new cache) cannot be made in two of three places. The risk of drift is real: the three differ already in what they say and when they mark.
**Suggested Action:** refactor branch, proposal only. A deferred ancestor with the notes-pack protocol (paths, swap, refresh) inherited side by side with the existing GUI mixins fits better than a helper alone.
**Effort:** 2 features.

### Finding 6: Rebuild with no notes keeps the old pack (MEDIUM)
**Evidence:** gui_app/bib_gui_app.e:4594-4606: when the notes folder is missing or has no `.json` file, only `set_pack_stale (l_folder, False)` runs (the comment at 4596-4598 says so). The live pack is not removed or rebuilt empty.
**Concrete input:** the user deletes all their notes' `.note.json` files (or the installer ships the stale marker with an empty folder after an upgrade that removed notes): the pack built from the deleted notes stays active and their paragraphs keep showing, and the mark that would have fixed it is gone.
**Suggested Action:** when the folder has no notes and a pack exists, build an empty pack or remove it; or leave the mark and say so.
**Effort:** 1 branch.

### Finding 7: Test gaps (MEDIUM)
**Evidence:** testing/test_reading.e:201-210 (linker cases) and testing/test_facade_open.e (test_kits_for_a_folder) cover the author's cases. Missing: same-stem pair (Finding 1), year or count before a book (Finding 2), `Letter of Jeremiah`, "Additions to Esther", text that starts with the book ("4 Ezra" at index 1 is guarded by `a_start > 2`, line 414, untested), `rebuild_notes_pack` (startup and "notesrebuild" snapshot only), and the tie timestamp. No test calls `BIB_SOURCE_READER.text_of` on a missing file or a `.kit.md`.

### Finding 8: Capitalized headings with the title words (LOW)
**Evidence:** src/reading/bib_reference_linker.e:427 compares `l_before` with `Other_title_words` using `same_string`, case sensitive, entries at lines 446-452 include "Vision", "Life", "Rest", "Questions".
**Concrete input:** a heading "Vision of Isaiah 6" or a sentence start "Life of Jonah 1 shows ..." is not linked; mid-sentence "the vision of Isaiah 6" is (lowercase). Probably acceptable, and the list is a closed set, but "Vision" and "Life" are ordinary English words that open sentences. Consider dropping "Life", "Vision" and "Rest" unless the Reversing Hermon guide needs them, or require the title word to be followed by a capital after "of".
Also: only a plain space (line 414) is read before the book name, so "4\nIsaiah" after a hard wrap is linked while "4 Isaiah" is not; and a non-breaking space differs. LOW.

### Finding 9: Failing pack rebuild retries at every start (LOW)
**Evidence:** bib_gui_app.e:277-281 queues the rebuild when the mark exists; 4615 sets the mark again when `l_error /= Void`. The rebuild runs on the window thread (4594ff), so a bad note file means a pause and the same message at every start. Consider a bounded retry or naming the failing note in the message.

### Finding 10: Pending-with-ticks pattern repeated (LOW, A6)
**Evidence:** bib_gui_app.e:4802-4812 (declarations) and 5726-5746 (tick handler): `pending_folder`/`pending_folder_ticks`, `pending_kit_folder`/`pending_kit_folder_ticks`, `pending_notes_rebuild_ticks` each hand-written; the kit one decrements only while the folder is attached, the rebuild one uses a bare counter. A small "after the next paint, do this" helper (agent plus ticks) held by the app would replace all three; a second rapid pick of a folder silently replaces the first (4392-4400). Not urgent.

### Finding 11: Small cleanup (LOW)
- src/reading/bib_reference_linker.e:412, 421, 425: `l_first := a_start` is an alias; use `a_start`.
- src/reading/bib_reference_linker.e:446: `Other_title_words` is a once array a client could mutate; harmless.
- ingest/bib_kit_folder.e:132 postcondition re-lists the folder (a second directory read in contract builds); it would fail if a file appears during the run. Cheap to keep, but record the count at the start instead.
- ingest/bib_kit_folder.e:60-65 `sources` sorts with a case-sensitive order (SORTED_TWO_WAY_LIST of STRING_32) though documented as "name order".
- ingest/bib_kit_folder.e:71-87 `kit_path_for` knows only the backslash; a path with "/" and a dot in a folder name would misplace the extension. Callers today pass dialog paths.
- ingest/bib_source_reader.e:55-71 `text_of` is correct against `read_text_utf_8` (it gives an empty string, never Void, on a read failure, so a failed read is reported as an empty kit, not as `failed`): `SIMPLE_FILE.read_text_utf_8` sets `last_error` but this routine does not look at it. That makes an unreadable (locked, permission) source produce a kit of an empty text. Worth checking: it is the nearest to a real defect here, MEDIUM if a locked file reproduces it.

## Checked and fine
- Index bounds in `is_in_another_title` (linker 402-431): precondition a_start in text; guarded by `a_start > 2`; `a_text [l_end]` read only when `l_end = 0` is excluded (first branch) or `l_end > 1` (second); `word_ending_at` with `a_last = 0` returns empty (loop exits at once), and with a non-alphanumeric char returns empty. "III.6 Romans 7", "the Old Testament to Luke 14:26" ("to" needs "Additions"), "the Letter of Jude 3" (only "Jeremiah" follows Letter/Epistle) link as the tests expect.
- every_source_accounted holds by construction (one branch per iteration) while the folder does not change during the run.
- write_ingest_kit (bib_gui_app.e:4365ff) checks `bible.is_open` before building BIB_KIT_FOLDER, whose `make` requires it. The old GUI-only `kit_path_for` has no other caller left (grep of the repository).
- Behavior change to note: File > Make ingest kit now refuses a file that is not .txt/.md (and a .kit.md / .prepared.md) with a message; before, any picked file was read.
