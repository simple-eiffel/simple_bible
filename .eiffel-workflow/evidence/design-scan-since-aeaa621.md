# Design Scan (diff mode): simple_bible, since aeaa621
# Date: 2026-10-26
# Subjects: 11 Eiffel files under src/, cli/, gui_app/, build/, build_app/ (testing/ files not scanned for findings)
# Compared against: every Eiffel source in the repository

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A, T) | 3 | 1 | 1 | 1 |
| MI (M) | 2 | 0 | 2 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **5** | **1** | **3** | **1** |

No drift (D1) was found: the two copies in finding 1 are equivalent in behavior.

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | A1/A5 | BIB_TEXT_READER, BIB_CONC_PACK | Extract a shared query-running mixin beside BIB_SQLITE_REPORTING |
| 2 | MEDIUM | M1 | BIB_LIST_RESULT, BIB_GUI_APP | Not ITERABLE; the GUI copies its items by hand four times |
| 3 | MEDIUM | T1 | BIB_GUI_APP, BIB_LOOKUP, BIB_CONC_PACK | Book count 66 and page size 200 restated in the GUI |
| 4 | MEDIUM | M4 | BIB_GUI_APP | 620-line class with two disjoint state clusters |
| 5 | LOW | A5 | BIB_GUI_APP | fill_versions picks the King James Version with a convoluted double test |

## Detailed Findings

### Finding 1: Second implementor of the query-running helpers
**Priority:** HIGH. **Category:** A1 / A5.
**Classes:** src/reading/bib_text_reader.e, src/concordance/bib_conc_pack.e.
**Evidence (all read):**
- bib_text_reader.e:152-177 (`last_rows`, `last_query_error`, `run_query`) versus bib_conc_pack.e:840-865. The bodies match line for line: clear both, test `attached sources.database`, call `query_with_args`, test `has_error`, build `make_with_details (Database_problem, ..., sqlite_message (al_db, a_sql))`, else `make (Source_unavailable, ...)`. Only two message strings differ ("A Bible text query failed." and "content.db is not open." versus "A concordance query failed." and "The concordance pack is not open.").
- bib_text_reader.e:179-187 `query_error` versus bib_conc_pack.e:867-875: identical apart from one message string.
- bib_text_reader.e:200-208 `sqlite_version_or_unknown` versus bib_conc_pack.e:830-838: identical.
- bib_text_reader.e:189-198 `method` versus bib_conc_pack.e:810-818: the same BIB_METHOD creation; they differ in the two list arguments (reader passes the version as the sixth argument, pack passes two empty lists) and in the edition source (`edition` versus `edition_or_pack`).
- Both classes already inherit BIB_SQLITE_REPORTING (src/data/bib_sqlite_reporting.e:13-27), whose header says it was extracted when "the second copy had appeared" (design scan 27). Its one feature, `sqlite_message`, is what both `run_query` bodies call. That mixin was extracted one layer too low: the layer above it is now duplicated by the same two classes. Both also declare `sources: BIB_SOURCE_SET` privately (bib_text_reader.e:112, bib_conc_pack.e:887).
**Judgment:** the evidence supports a shared deferred mixin now, since a second implementor exists. The only divergence is message text and the edition label, both natural deferred features.
**Proposal:** new deferred class BIB_SQLITE_QUERYING (src/data/) inheriting BIB_SQLITE_REPORTING, which BIB_TEXT_READER and BIB_CONC_PACK inherit side by side with their other parents (BIB_CONC_PACK already has four, so this is the established style). It owns effective `last_rows`, `last_query_error`, `run_query`, `query_error`, `sqlite_version_or_unknown`, and a `method_record (feature, sql, scope_code, scope, versions, count)` builder. It declares deferred `sources: BIB_SOURCE_SET`, `query_failed_text`, `source_closed_text`, and `method_edition: STRING_32`. Keep the postcondition `(last_rows = Void) = (last_query_error /= Void)` (bib_text_reader.e:176; equivalent to the pack's xor postcondition). Each class keeps a thin `method` wrapper so its callers do not change. Effort: 5 features moved, about 60 lines removed. Nothing is extracted without Larry's word (then `/eiffel.abstract` or a refactor branch).
**Before/after test idea:** Before: close the source set, then call `text_reader.chapter` and `conc_pack.word_entry`; assert each failure has `Source_unavailable` and its own message text; with a missing table assert the message is SQLite's own words. Record the strings. After the extraction the same test passes unchanged. Add one test on a tiny descendant of the mixin pinning the shared contract (rows or reason, never both or neither) and the "unknown" SQLite version fallback.

### Finding 2: BIB_LIST_RESULT cannot be iterated, so callers copy it
**Priority:** MEDIUM. **Category:** M1 / A5.
**Evidence:** src/provenance/bib_list_result.e:49-64 exposes only `count` and `item (i)`; `items` is `feature {NONE}` (line 89) and there is no `new_cursor`. gui_app/bib_gui_app.e copies items into a fresh ARRAYED_LIST with an index loop at 374-378 (`reading_verses`), 500-503 (`renderings`), 511-514 and 557-560 (`places`): four copies of one four-line loop, all new or changed since aeaa621.
**Proposal:** BIB_LIST_RESULT inherits ITERABLE [G] with `new_cursor` over `items`, or adds `to_arrayed_list` returning a twin. The GUI then reads `reading_verses := l_chapter.to_arrayed_list`. Effort: 1 feature, 4 call sites.

### Finding 3: Book count and page size restated
**Priority:** MEDIUM. **Category:** T1.
**Evidence:** bib_gui_app.e:609 `Last_book: INTEGER = 66` (FR-105); cli/bib_lookup.e:262 `Last_old_testament_book: INTEGER = 39` (same FR-105 comment); src/search/bib_count_table.e:20-21 literal 66. bib_gui_app.e:612 `Max_page: INTEGER = 200` whose own comment points at `{BIB_CONC_PACK}.Max_page_size`, the real token at bib_conc_pack.e:514. If the pack's cap changes, the GUI's copy breaks the precondition at bib_conc_pack.e:372 (`limit_bounded`).
**Proposal:** the GUI reads `bible.conc_pack.Max_page_size`, and the book catalog answers a `last_book_id` query instead of private copies. Effort: 2 constants.

### Finding 4: bib_gui_app.e clusters
**Priority:** MEDIUM. **Category:** M4.
**Evidence (read, 621 lines):** feature groups are Window and layout (104-205), Design pills (207-245), Lookup (247-309), Reading S1 (311-468: `reading_verses`, `reading_version`, `reading_book/chapter/verse`, `fill_versions`, `open_reading`, `step_chapter`, `on_verse_click`) and Word study (470-575: `renderings`, `places`, `study_*`, `is_loading_places`, paging). Reading and Word study own disjoint state and meet only through `open_reading` (called at 93, 287, 299, 449) and `open_study` (290, 307). `open_reading` alone is about 60 lines touching six widgets.
**Proposal:** two helper classes held by the app: a reading-pane presenter (state at 313-320 plus the five reading features) and a word-study presenter (472-477 plus `open_study`, `load_more_places`, `load_next_page`, `show_places_count`), each given its widgets at creation. Do it when the next gap item grows either cluster; today the class is long but coherent. Effort: about 10 features.

### Finding 5: fill_versions selection
**Priority:** LOW. **Category:** A5.
**Evidence:** bib_gui_app.e:331-338 uses an index loop with a nested double condition to choose "KJV", else the first. `bible.text_reader.has_version ("KJV")` (bib_text_reader.e:57) already answers it. Cosmetic.

## Recommended Order
1. Finding 1: the next gap item touching either class would add a third copy; the mixin is small and has precedent in this repository.
2. Finding 2: removes four copies and eases Finding 4.
3. Findings 3 and 5: small cleanups.
4. Finding 4: defer until the GUI grows again.
