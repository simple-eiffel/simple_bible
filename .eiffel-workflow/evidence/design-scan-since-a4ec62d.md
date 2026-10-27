# Design Scan (diff mode): simple_bible since a4ec62d
# Date: 2026-10-27
# Subjects (git diff --name-only a4ec62d..HEAD -- src cli gui_app build build_app):
#   cli/bib_lookup.e, cli/bib_settings.e, gui_app/bib_gui_app.e (1,773 lines now, not 1,400),
#   gui_app/bib_nav_node.e (new), src/concordance/bib_conc_pack.e
# Each subject was compared against all of src/, cli/, gui_app/, build/, build_app/. Read-only; nothing compiled.

## Known (not re-reported)
BIB_LIST_RESULT is not ITERABLE (this is why gui_app/bib_gui_app.e repeats index loops, see Finding 5); BIB_DATA_LOCATION lives in cli/; BIB_REFERENCE_PARSER is a stub.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift / tokens | 9 | 3 | 4 | 2 |
| MI (panel classes and mixins) | 1 | 0 | 1 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **10** | **3** | **5** | **2** |

(The Abstraction row counts Findings 1-7, 9, 10; Finding 8 is the MI row. Priorities: HIGH 1-3; MEDIUM 4-8; LOW 9-10.)

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_CONC_PACK | Two Hebrew folds that disagree: `without_hebrew_points` vs `original_search_form` |
| 2 | HIGH | D1 / A5 | BIB_GUI_APP | `open_reading` and `fill_parallel` copy the same chapter-to-rows logic; only one handles an empty chapter or an error |
| 3 | HIGH | D1 | BIB_GUI_APP | Design pill tips in the two layouts have diverged; the Simple copy is stale |
| 4 | MEDIUM | A5 / T1 | BIB_LOOKUP, BIB_GUI_APP | The testament boundary and version-to-corpus rules live in three places, partly as bare literals |
| 5 | MEDIUM | A5 | BIB_GUI_APP | Seven copies of the "result list to ARRAYED_LIST" loop and a double KJV search in `fill_versions` |
| 6 | MEDIUM | A5 | BIB_CONC_PACK | `headwords_behind_word` and `headwords_behind_original_word` share a prologue and epilogue |
| 7 | MEDIUM | A5 | BIB_GUI_APP | The two pill routines repeat the same chrome marks |
| 8 | MEDIUM | MI / M4 | BIB_GUI_APP | Panel clusters that should leave the 1,773-line class |
| 9 | LOW | T1 | BIB_GUI_APP, BIB_SETTINGS | Hard-coded sizes, gaps, fractions and the 1.35 Hebrew scale |
| 10 | LOW | A4 | BIB_CONC_PACK, BIB_GUI_APP, BIB_NAV_NODE | Contracts missing on new shared behavior |

## Detailed Findings

### Finding 1: Two Hebrew folds that disagree (D1)
**Priority:** HIGH. **Category:** D1.
**Evidence:**
- src/concordance/bib_conc_pack.e:969-979 `without_hebrew_points`: removes only U+0591 to U+05C7 and keeps every other character (Latin, digits, punctuation, Hebrew punctuation such as U+05F3).
- src/concordance/bib_conc_pack.e:347-374 `original_search_form`: keeps only U+05D0 to U+05EA for Hebrew, and drops everything else that is not ASCII alphanumeric or Greek.
- Both claim to produce what the pack's search column holds ("as `lemma.search' holds it", line 970; "as the pack's `token.search' is", line 348). The word-click path (line 310, `l_key := original_search_form (a_word)`) and the text-search path (`headwords_for_text`, line 407, which matches `l.search`, line 420) therefore fold the same Hebrew word differently whenever it carries a character outside U+0591..U+05EA (for example U+05F3 or U+05F4, or presentation forms U+FB1D..U+FB4F, which BIB_SCRIPT_CLASSIFIER at src/text/bib_script_classifier.e:18 counts as Hebrew).
- The Greek table `greek_base` (src/concordance/bib_conc_pack.e:376-403) is a third copy of script-range knowledge next to src/text/bib_script_classifier.e:20 (0x0370-0x03FF, 0x1F00-0x1FFF).
**Winner:** one fold. `original_search_form` is the newer and is the one built to match `token.search`; make `without_hebrew_points` call it (or move both, and `greek_base`, into the planned BIB_GREEK_NORMALIZER). Add a shared contract: folding is idempotent.
**Effort:** 3 features move; 1 contract.

### Finding 2: `open_reading` and `fill_parallel` copy one logic and have drifted (D1, A5)
**Priority:** HIGH.
**Evidence:**
- gui_app/bib_gui_app.e:744-749 and 1260-1264: chapter fetched, then verses copied into a container.
- gui_app/bib_gui_app.e:763-764 and 1279-1280: the identical selected-verse mark (`create l_mark.make ({SW_MARK}.Hue_blue)` then `mark_range_with (0, ..., "selected verse", l_mark.with_wash)`).
- gui_app/bib_gui_app.e:608-612 and 1254-1258: the identical Hebrew-reads-larger rule (`is_right_to_left` then column scale 1.35, else 1.0).
- DRIFT: `open_reading` shows the engine error or "is not in this version" when the chapter is empty (lines 767-773). `fill_parallel` ignores `l_chapter.error` and an empty chapter entirely (line 1260 onward): an unreadable chapter shows blank cells in Parallel with no explanation. `open_reading` should win.
**Suggested action:** a deferred mixin (BIB_VERSE_ROWS, see Finding 8) holding `mark_selected_verse (view, row, column, text)`, `apply_script_scale (view, column, version)` and `chapter_texts (version, book, chapter)`; both views call it.
**Effort:** 3 features.

### Finding 3: Design pill tips drifted between layouts, Simple copy stale (D1)
**Priority:** HIGH.
**Evidence:**
- gui_app/bib_gui_app.e:1703 (Simple board) says "Study is the next step"; Study is built (lines 1006-1072) and its own tip at 1310 says "on Study".
- gui_app/bib_gui_app.e:1702 says C6 results "open P07"; the Study copy at 1308 says "go to T6" (correct for its layout, but the sentences are written independently).
- gui_app/bib_gui_app.e:1704 hard-codes "80 to 200 percent" while cli/bib_settings.e:146-147 owns Min_text_scale 0.8 and Max_text_scale 2.0: one number in two files.
- gui_app/bib_gui_app.e:1708 (S4) says "click a word (KJV, BSB)"; since commit 46396f4 a click in Hebrew and Greek also works (`follow_word`, lines 844-876).
**Winner:** the Study copy's wording (shorter, current). Fix with the Finding 7 extraction so each tip is written once.
**Effort:** 4 strings.

### Finding 4: Testament boundary and version rules in three places (A5, T1)
**Priority:** MEDIUM.
**Evidence:**
- cli/bib_lookup.e:338 `Last_old_testament_book: INTEGER = 39` (a private constant), used at lines 76 and 94.
- gui_app/bib_gui_app.e:1118 `make_testament ("Old Testament", 1, 39)`, 1119 and 1764 `Last_book = 66`, 1221 `reading_book <= 39`: bare copies of the boundary, none using BIB_LOOKUP's constant.
- gui_app/bib_gui_app.e:1216-1227 `parallel_versions` picks the original ("WLC" up to book 39, "TR" after) and is a second rule beside `BIB_LOOKUP.original_corpus_for_version` (cli/bib_lookup.e:72-79) and `corpus_for_book` (cli/bib_lookup.e:94-98); gui_app/bib_gui_app.e:947 compares `study_corpus` with the literal "WLC-MACULA" (the name `corpus_for_book` returns).
- cli/bib_cli_commands.e:159 already asks BIB_LOOKUP for the corpus; only the GUI bypasses it.
**Suggested action:** move `Last_old_testament_book`, `Last_book` and the corpus-name strings into BIB_BOOK_CATALOG (src/core/) or one small BIB_TESTAMENTS class; GUI and lookup read them. Contract: `is_old_testament (book)` iff `book <= Last_old_testament_book`.
**Effort:** 3 constants, 2 features.

### Finding 5: Index-loop copies (A5)
**Priority:** MEDIUM.
**Evidence:** the same `from i := 1 until i > R.count loop L.extend (R.item (i)); i := i + 1 end` appears at gui_app/bib_gui_app.e:746-749, 1261-1264, 1346-1349, 1413-1416, 1420-1423, 1433-1436 and 1553-1556 (seven copies; cause is BIB_LIST_RESULT not being ITERABLE, known). `fill_versions` (lines 684-695) runs the "choose KJV" search twice; the first loop (684-689) is made redundant by the second (690-695) whenever KJV exists.
**Suggested action:** add `BIB_LIST_RESULT.to_list: ARRAYED_LIST [G]` (postcondition: same count, same order) and replace the seven loops; collapse the two version loops into one.
**Effort:** 1 feature in src, 8 call sites.

### Finding 6: Prologue and epilogue copies in BIB_CONC_PACK (A5)
**Priority:** MEDIUM.
**Evidence:**
- src/concordance/bib_conc_pack.e:258-288 (`headwords_behind_word`) and 290-345 (`headwords_behind_original_word`): both build the scope text with the identical expression (lines 272 and 309), carry the identical four-clause require block, and create the failure the same way.
- The lemma lookup `SELECT Entry_columns ... WHERE l.lemma_id = ?` appears at line 235 (`word_entry`) and again at line 338.
- No behavior drift yet, but the new routine omits the `fact_closure` postcondition that `headwords_for_strongs` states (line 255); `headwords_behind_word` omits it as well (only `method_recorded`).
**Suggested action:** private `word_scope (a_ref, a_word, a_occurrence): STRING_32` and a shared "entries of one lemma" query.
**Effort:** 2 helpers.

### Finding 7: Pill routines repeat the chrome marks (A5)
**Priority:** MEDIUM.
**Evidence:** gui_app/bib_gui_app.e:1303-1312 and 1319-1323 repeat the marks of lines 1697-1705 and 1715-1719 (C1 to C15 on the same widgets, different strings). Twenty-odd `add_reference_mark` calls are a data table in disguise.
**Suggested action:** a deferred BIB_DESIGN_PILLS mixin (Finding 8) with the chrome marks written once and a layout-specific tip table.
**Effort:** 2 features.

### Finding 8: Clusters that should leave gui_app/bib_gui_app.e (MI / M4)
**Priority:** MEDIUM. The class is 1,773 lines with one shared state of about 130 attributes across 13 feature groups. Proposed deferred mixins, inherited side by side; the app keeps `make`, `wire_events`, `arrange`, `go_to`, `open_reading` and the history. In order of benefit:
1. BIB_WORD_CLICK (lines 878-942, 65 lines): `clicked_word`, `last_word_occurrence`, `is_word_character`, `whole_word_after`. Pure text logic over SW_PARALLEL_TEXT, no dependence on the app, and the occurrence-count loop (899-907) is the riskiest code in the class and has no test. Conflicts: none.
2. BIB_LEXICON_PANEL (lines 1364-1573, about 210 lines, 13 widgets and 6 state attributes): `open_study`, `study_corpus_for`, `renderings_for_version`, `entry_text`, and the places streaming (`load_more_places`, `load_next_page`, `show_places_count`). It carries an unstated invariant (`is_loading_places` implies `places.count < places_total`). Needs `bible` and `reading_version` as deferred queries and `progress` passed in.
3. BIB_NAVIGATOR_PANEL (lines 1112-1188 with BIB_NAV_NODE): `navigator_pane`, `nav_children`, `new_nav_children`, `on_nav`; calls a deferred `go_to`.
4. BIB_PARALLEL_PANEL (lines 1198-1298): `parallel_versions`, `fill_parallel`, `show_parallel`, `on_center_tab`, `parallel_codes`; shares BIB_VERSE_ROWS from Finding 2.
5. BIB_DESIGN_PILLS (lines 1300-1324 and 1690-1726), Finding 7.
6. BIB_MENUS (lines 377-504): nine menu features that only read state.
Minor in the same class: `window_width`, `window_height`, `window_x`, `window_y` (lines 143-171) create SW_SCREEN six times and call `window_width` twice from `window_x`; one `window_frame` query is shorter. `nav_children` declares unused locals `i, l_last` (line 1140).
**Effort:** six extractions of 60 to 210 lines each; start with 1 and 2.

### Finding 9: Token drift (T1)
**Priority:** LOW (no role has two different values today, but the values are bare and one was already changed in this range).
**Evidence:**
- gui_app/bib_gui_app.e:70, 75, 84, 86, 88, 91: grid minimum heights, changed in this range from 200/120/100/120/140 to 120/60/60/60/60 (comment at lines 51-52 says they are minimums). One named value would have made that one edit.
- Stack and row gaps 6.0, 8.0, 10.0 at lines 228, 272, 279, 295, 309, 318, 322, 329, 341, 352, 356, 1125: belong in SW_THEME (gap, padding) and must scale with `text_scale`.
- Hebrew column scale 1.35 at lines 609 and 1255 (same role, same value, two copies).
- Dock fractions 0.18/0.34/0.30 (lines 1035-1037) and 0.22/0.30/0.42 (1053-1055).
- Status bar widths 70/170/140/460 (lines 250-253); column widths 150/200/70/180/160 (lines 364-373).
- Window fallbacks 1440 and 920, minimums 800 and 600 (lines 148-158), share 0.92 (line 173).
- Text size step 0.1 (line 593) sits beside, not with, Min_text_scale and Max_text_scale (cli/bib_settings.e:146-147).
- cli/bib_settings.e:118-128 `scale_text` hand-rolls two-decimal text and gui_app/bib_gui_app.e:602 hand-rolls percent text from the same value; a `percent_text` on BIB_SETTINGS would own both.

### Finding 10: Missing contracts on new shared behavior (A4)
**Priority:** LOW.
- src/concordance/bib_conc_pack.e:347 `original_search_form`: no postcondition (only Hebrew letters, lowercase Greek, lowercase ASCII alphanumerics; idempotent).
- src/concordance/bib_conc_pack.e:376 `greek_base`: no postcondition (`Result = 0 or (Result >= 0x03B1 and Result <= 0x03C9)`).
- src/concordance/bib_conc_pack.e:290: only `method_recorded`; siblings state `fact_closure` (lines 255, 426, 475).
- gui_app/bib_gui_app.e:844 `follow_word`: silently does nothing when `reading_verse` is 0 (line 854) instead of a precondition; line 1152 `new_nav_children` has no ensure (every child is a book or chapter node).
- gui_app/bib_nav_node.e:97-98: invariant `one_kind` is present, but nothing states `is_testament implies last_book >= first_book` (make_testament requires it at line 25 only).

## Recommended Order
1. Finding 1 (live defect risk: Hebrew word click and text search fold differently).
2. Finding 2 (blank Parallel on an unreadable chapter).
3. Finding 3 (stale tips), done inside Finding 7.
4. Findings 4 and 5 (shared constants and `to_list`; shrinks the GUI before any panel moves).
5. Finding 8 items 1 and 2, then the rest; Finding 6, then Findings 9 and 10 as cleanup.
