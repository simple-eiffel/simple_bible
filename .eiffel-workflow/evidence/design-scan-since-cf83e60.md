# Design Scan (diff mode): simple_bible since cf83e60
# Date: 2026-10-26
# Subjects (git diff --name-only cf83e60..HEAD): gui_app/bib_gui_app.e (1,181 lines at HEAD), cli/bib_lookup.e,
#   src/concordance/bib_conc_pack.e (953 lines at HEAD), src/reading/bib_text_reader.e,
#   src/reading/bib_reading_cross_ref.e (new), build/bib_content_builder.e, build_app/bib_build_app.e
#   (testing/ and installer/ files also changed; not subjects)
# Compared against: all of src/, cli/, gui_app/, build/
# Line numbers are the committed HEAD (8c32b6d). The working tree has uncommitted edits by another session
# (bib_gui_app.e is now 1,262 lines, bib_lookup.e adds english_corpus_for_version); they were not scanned.
# Read-only scan: no source file was modified, nothing was compiled.

## Summary

| Severity | Findings |
|----------|----------|
| HIGH | 2 |
| MEDIUM | 5 |
| LOW | 3 |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | M4 / A6 (+ command-query separation) | BIB_GUI_APP | Split into panel classes now; the pane builders are not safe to call twice |
| 2 | HIGH | D1 / A5 | BIB_LOOKUP, BIB_REFERENCE_PARSER | Three reference-text parsers, already drifted (trailing space) |
| 3 | MEDIUM | A1 | BIB_READING_CROSS_REF, BIB_CROSS_REFERENCE | Two classes for one concept |
| 4 | MEDIUM | M4 / A1 | BIB_CONC_PACK, BIB_LIBRARY | lexicon_entries implements what BIB_LIBRARY.entries_for_lemma only promises; the pack is 953 lines |
| 5 | MEDIUM | A5 | BIB_GUI_APP, BIB_LIST_RESULT | List-copy loop written six times; add one query to BIB_LIST_RESULT |
| 6 | MEDIUM | A5 / D1 | BIB_CONC_PACK | Two SQL strings rank the same sources differently; unordered tie in Gloss_sql |
| 7 | MEDIUM | A5 | BIB_GUI_APP, BIB_LOOKUP, BIB_BOOK_CATALOG | Place text, neighbor-chapter logic and last book id belong in the engine |
| 8 | LOW | A5 | BIB_TEXT_READER | Row-to-provenance block written twice in load_versions |
| 9 | LOW | A5 | BIB_GUI_APP | fill_versions loops twice |
| 10 | LOW | T1 | BIB_GUI_APP | Literal gaps, font sizes and fractions repeated |

## Detailed Findings

### Finding 1 (HIGH): split bib_gui_app.e into panel classes now
**Judgment: yes, split now.** The Study layout is a second arrangement of the same four panels, which is a real second user, and the file already shows the symptoms that make a second user unsafe.

**Evidence (bib_gui_app.e, read in full):**
- About 90 features and 60 attributes in one class (M4). The `make` block at lines 48-97 creates about 50 widgets and values by hand.
- The four clusters are visible in the feature clauses: Reading S1/P01 (lines 593-783), Commentary S2/P04 (785-821), Lexicon S3/P05 (823-1002), Results P07 (1004-1031). Menus (319-446), toolbar (448-591), start and status (1033-1096) and pills (1098-1134) are the application's own.
- **The pane builders are queries that do work.** `reading_pane` (208), `commentary_pane` (227), `lexicon_pane` (242), `results_pane` (288) and `layout` (165) are functions without `once`. `commentary_pane` calls `commentary_tabs.add_page` three times (230-234) and `select_tab` (235); `lexicon_pane` calls `lexicon_tabs.add_page` four times (275-280) and `word_study_button.set_enabled (False)` (257); `layout` calls `dock.add_panel` three times (185-187), `dock.hide_panel` (191), `status_bar.add_widget` four times (194-197) and `add_pills` (205). Calling any of them a second time, which is exactly what a second arrangement does, would duplicate tab pages and dock panels. This is a command-query-separation fault today that nothing triggers only because each is called once.
- Order dependence: `create dock.make (reading_pane)` (line 99) runs before `build_columns` (line 100), so the centre column is built before the columns of the grids it holds exist.
- Cross-panel state is shared through plain attributes: `study_corpus` is read by `numbering_note` in the Reading cluster (761) but written by `open_study` in the Lexicon cluster (854); `progress` (status bar, line 160) is written by the Lexicon loader (997, 1000); `choices` is written by search (485) and verse click (750) and read by the Window menu (424) and `on_choice` (1028). These couplings need to become named events.
- The GUI has no tests; nothing in testing/ names BIB_GUI_APP, because nothing in it can be built without the whole window.

**Proposed boundaries (deferred ancestor and helpers, side by side where a class needs two roles):**
1. `BIB_PANEL` (deferred, gui_app/): `widget: SW_WIDGET` created ONCE in the creation procedure (never a function with side effects) and a caption. Each panel holds its widgets and announces through agents; none knows the window.
2. `BIB_READING_PANEL` (S1/P01): reading_caption, reading_title, version_chip, reading_note, previous and next buttons, reading_view, reading_verses, reading_version, reading_scale; features `show_chapter (book, chapter, verse)`, `apply_scale`, `numbering_note`, `selected_verse`; announces `on_verse_chosen` and `on_step`. Lines 593-783 move here, apart from `go_to` and history.
3. `BIB_COMMENTARY_PANEL` (S2/P04): commentary_title, commentary_tabs, cross_refs_grid, cross_refs; `follow (book, chapter, verse)`; announces `on_place_chosen (book, chapter, verse)`. Lines 785-821.
4. `BIB_LEXICON_PANEL` (S3/P05): heading, subtitle, chip, buttons, tabs, renderings, entries, places; `follow_word (lemma_id, reading_book)` (today's `open_study`) and `tick`; announces `on_place_chosen` (the same agent type as Commentary, so a layout wires both to one handler) and reports load progress through an agent instead of writing `progress` itself.
5. `BIB_PLACE_STREAM` (helper object held by the Lexicon panel, no widgets): places, places_total, is_loading_places, `load_next_page`, `load_more` (lines 833-838 and 956-990). It is the part with real logic (keyset paging, the 10,000 threshold, 15 pages a tick) and becomes testable headless against the fixture pack.
6. `BIB_RESULTS_PANEL` (P07): results_note, results_grid, close button, choices; `show_choices (choices, note)`; announces `on_word_chosen (lemma_id)` and `on_close`. Lines 1004-1031.
7. `BIB_HISTORY` (helper, no widgets): the Back and Forward list and index (450-453, 636-659). Pure, and the Study layout shares one history with Simple.
8. `BIB_SIMPLE_LAYOUT` (and later `BIB_STUDY_LAYOUT`): owns only the dock arrangement (lines 165-206: fractions, zones, which panels, status sections). `BIB_GUI_APP` keeps window, menus, toolbar, accelerators, start and status text, pills and the mediation (`go_to` and the wiring of panel agents). Target size for BIB_GUI_APP: about 450 lines.
- Pills (1098-1128) name widgets inside panels: each panel offers its pill targets so the application can still add them.
- Do finding 7 first so panels do not each need the application to format a place.

**Before/after test:**
- Before: no test builds the lexicon or commentary part without the full window; building `lexicon_pane` twice duplicates its four tab pages, provable only by hand today.
- After: (a) with the fixture engine, create `BIB_LEXICON_PANEL`, call `follow_word` for a known lemma, assert the entries list is non-empty and the stream's `places_total > 0`; (b) create `BIB_COMMENTARY_PANEL`, call `follow (1, 1, 1)`, assert the cross-reference row count equals `text_reader.cross_references (1, 1, 1).count`; (c) place the same panel objects into two dock arrangements and assert the tab page count is unchanged after the second; (d) `BIB_HISTORY`: go to three places, back twice, go to a new place, assert forward is empty.
**Suggested Action:** refactor branch, panel by panel (Results first because it is smallest, then Commentary, Reading, Lexicon with the stream), the window launched by hand after each. `/eiffel.abstract` for `BIB_PANEL`.

### Finding 2 (HIGH): three reference-text parsers, already drifted
**Evidence:**
- `BIB_LOOKUP.verse_parts` (cli/bib_lookup.e:306-326): splits "<book> <chapter>:<verse>" at the LAST space and the last colon, no trimming, verse must be above 0. Used by `is_verse_text` (143-146) and `add_verse` (191).
- `BIB_LOOKUP.place_named` (cli/bib_lookup.e:108-141, new): trims, splits on spaces, accepts "Book c:v", "Book c v" and "Book c" (verse 0), then calls `resolved` (343-357), which repeats the tail of `verse_parts`: integer checks, `bible.books.candidates_for_name`, take the first candidate. `joined_words` (328-341) is its helper.
- `BIB_REFERENCE_PARSER.parse` (src/reference/bib_reference_parser.e:33-45) is the specified home for this (FR-020: ambiguity candidates, error position) and its body is `check implemented_in_phase_4: False then end`.
- **Drift (D1):** `place_named` trims; `verse_parts` does not. For the text "John 3:16 " (trailing space) `verse_parts` finds the last space at the end, so `l_colon > l_space + 1` is false and it returns Void, while `place_named` returns book 43, chapter 3, verse 16. A verse typed with a stray trailing space in the SEARCH box (C6, which uses `is_verse_text`) is treated as a word search, while the same text in the reference box (C4) goes to the verse. The copy whose behavior should win is `place_named` (trimmed, three forms). Both also take `candidates.first` for ambiguous names ("Ju 1", "Ph 1"), where the specification says to return every candidate and never guess.
- Tests: testing/test_cli_commands.e:97-101 cover `place_named` only; none covers `is_verse_text` with surrounding spaces.

**Proposal:** implement `BIB_REFERENCE_PARSER.parse` for real, using `place_named`'s tokenizer as its body (keeping the postcondition `never_guesses`), then make `place_named`, `verse_parts` and `is_verse_text` thin callers (`is_verse_text` is "valid and verse above 0"). Delete `resolved` and `joined_words` from BIB_LOOKUP. The parser lives in src/reference/, where the engine, the command line and the window can all reach it; today the window reaches reading logic through the cli/ cluster.
**Before/after test:** before, `is_verse_text ("John 3:16 ")` is False while `place_named ("John 3:16 ")` succeeds; after, both agree. Add: `parse ("Ju 1")` is ambiguous with two or more candidates.
**Effort:** one parser body, three callers reduced, two helper features removed.

### Finding 3 (MEDIUM): BIB_READING_CROSS_REF and BIB_CROSS_REFERENCE are one concept
**Evidence:** src/reading/bib_reading_cross_ref.e (new; target as four integers, votes, provenance, `is_range`, `verses_text`) against src/hub/bib_cross_reference.e (target as BIB_REF plus hub ids, votes, provenance). The new class's own header says it is the plain-number form and that the specification class adds hub ids "when the map exists (fold 2026-10-26)". Both inherit BIB_SOURCED and carry `votes`.
**Proposal:** do not fold yet (the hub ids do not exist on this path). When the versification map lands, make the two classes descendants of one deferred `BIB_CROSS_LINK` (votes, provenance, target book, chapter and verse queries) inherited SIDE BY SIDE with BIB_SOURCED, so the grid column agents (`cross_ref_text`, `votes_text`, bib_gui_app.e:1138-1147) work on either. Put the intent and date in the class note.

### Finding 4 (MEDIUM): lexicon_entries is the first real lemma-library query, and it sits in a 953-line class
**Evidence:** `BIB_CONC_PACK.lexicon_entries` (src/concordance/bib_conc_pack.e:520-559) returns `BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]` for a lemma. `BIB_LIBRARY.entries_for_lemma` (src/study/bib_library.e:34-41) has the same result type and a stub body (`check implemented_in_phase_4: False`). Nothing else in src/ reads `lex_sense` (grep). BIB_CONC_PACK is the largest class by far (953 lines; the next is cli/bib_lookup.e at 367) and gained `meaning_provenance` and `edition_text` (909-934) and two SQL constants (937-939) in this change (M4).
**Proposal:** move the dictionary queries (`lexicon_entries`, `short_gloss`, `meaning_provenance`, `edition_text`, the two SQL strings, `has_meanings`) into a `BIB_CONC_LEXICON` helper held by the pack, and let `BIB_LIBRARY.entries_for_lemma` call it, so the specified feature and the working one are one. `entries_for_lemma` takes a BIB_KEY and a resource code; the helper filters by `source`.
**Also:** `lexicon_entries` requires only `is_available`, not `has_meanings` (the status query exists at line 623, set at 653). Without `lex_sense` it reports a query failure, which the window shows as "No lexicon entry" (bib_gui_app.e:883-885). A precondition, or an empty success when `not has_meanings`, would say so honestly.

### Finding 5 (MEDIUM): the same copy-the-list loop six times
**Evidence (bib_gui_app.e):** `from i := 1 until i > X.count loop list.extend (X.item (i)) ...` at lines 679-682 (reading_verses), 804-808 (cross_refs), 872-875 (renderings), 879-882 (entries), 892-895 (places) and 982-985 (places page). BIB_LIST_RESULT exposes `count` and `item` but not its list (src/provenance/bib_list_result.e:51-65; `items` is in the NONE clause at line 89), so every client copies it by hand. 16 `from i := 1 until i > ...count loop` loops exist across src/, cli/ and gui_app/.
**Proposal:** add `to_list: ARRAYED_LIST [G]` (a twin) to BIB_LIST_RESULT with postcondition `Result.count = count`, and `append_to (a_list)` for the paging case. The panels in finding 1 then never write the loop.
**Before/after test:** `result.to_list.count = result.count`, and changing the returned list does not change the result.

### Finding 6 (MEDIUM): two SQL strings rank the same sources differently
**Evidence:** src/concordance/bib_conc_pack.e:937 (`Lexicon_sql`) orders AS1922, BDB1906, LSJ, ML1889, SDGNT, SDBH, TBESH, else 9, then `s.source`, `s.seq`. Line 939 (`Gloss_sql`) lists a different set (STEP, AS1922, BDB1906, SDGNT, SDBH, TBESH: no LSJ, no ML1889) and ranks STEP 1, AS1922 2, BDB1906 3, everything else 4, then `seq` only. Two glosses at rank 4 (for example SDGNT and TBESH, both sequence 1) have no defined order and `LIMIT 1` takes whichever SQLite returns first. The window heading's gloss may then differ from the first entry listed beneath it.
**Proposal:** one `Source_rank_sql` fragment (or a `rank` column in `meaning_source`) used by both queries, and `source` added to the gloss tiebreak. Decide on purpose whether LSJ and ML1889 glosses may head a word (they are skipped today).
**Before/after test:** a lemma with glosses from SDGNT and TBESH: assert `short_gloss` equals the gloss of the first `lexicon_entries` item that has one.

### Finding 7 (MEDIUM): place text, neighbor chapters and the last book id belong in the engine
**Evidence:** `place_text` (bib_gui_app.e:1084-1096) formats "Book c:v"; cli/bib_lookup.e:218 formats the same by hand (`name + " " + chapter + ":" + verse`); `cross_ref_text` (bib_gui_app.e:1141) formats it again. `step_chapter` (720-739) and the previous and next enabling (710-711) compute the neighbor chapter across book ends in the window, with `Last_book: INTEGER = 66` (1172) hard-coded, while the catalog knows its books and `last_chapter` lives in BIB_TEXT_READER (src/reading/bib_text_reader.e:138). cli/bib_lookup.e:297 has a second constant, `Last_old_testament_book = 39`.
**Proposal:** `BIB_BOOK_CATALOG.place_text (book, chapter, verse): STRING_32` (verse 0 means the chapter) and `BIB_TEXT_READER.chapter_after (version, book, chapter, step): detachable TUPLE [book, chapter]` (Void at the ends). The Study layout then gets Previous and Next for free, and the bound is no longer a literal.
**Before/after test:** `chapter_after (KJV, 1, 50, 1)` is Exodus 1; `chapter_after (KJV, 66, 22, 1)` is Void.

### Finding 8 (LOW): provenance row built twice in load_versions
**Evidence:** src/reading/bib_text_reader.e:175-178 and 185-189 both build a BIB_LICENSE and a BIB_PROVENANCE from a `source_provenance` row with the same column reads. A third style exists in bib_conc_pack.e:699 and 920.
**Proposal:** one `provenance_from_row (a_row)` feature in BIB_SQLITE_QUERYING (or a small deferred mixin) used by both readers.

### Finding 9 (LOW): fill_versions loops twice
**Evidence:** bib_gui_app.e:617-622 picks the first version and lets any KJV match replace it; 623-628 runs the same KJV test again. The first loop alone does the whole job. Keep one loop when the reading panel takes this over.

### Finding 10 (LOW): literal gaps and sizes
**Evidence:** `with_gap (6.0)` at bib_gui_app.e:221, 237, 260, 264, 271, 283, 298; `with_gap (8.0)` at 172 and 294; `with_gap (10.0)` at 214 and 251; font sizes 13.0, 14.0 and 20.0 (59, 68, 72); split ratio 0.52 (268); dock fractions 0.22, 0.30, 0.42 (188-190).
**Proposal:** theme-owned spacing tokens belong to SW_THEME; until they exist, name them once in the layout class from finding 1.

## New engine features checked for duplication

| Feature | Result |
|---------|--------|
| BIB_TEXT_READER.cross_references (src/reading/bib_text_reader.e:100) | No second copy of the query; its provenance block is finding 8; its result class overlaps BIB_CROSS_REFERENCE (finding 3). |
| BIB_CONC_PACK.lexicon_entries (src/concordance/bib_conc_pack.e:520) | Overlaps the stub BIB_LIBRARY.entries_for_lemma (finding 4); SQL ranking drifts from short_gloss (finding 6). |
| BIB_CONC_PACK.short_gloss (:561) | Only user of Gloss_sql; see finding 6. |
| BIB_CONC_PACK.corpus_short_name (:123-141) | No existing equivalent. cli/bib_cli_commands.e:131 and :170 still print the long `corpus_name` while the lookup and window print the short one; that looks intentional for the command line, so not raised. |
| BIB_LOOKUP.place_named (cli/bib_lookup.e:108) | Duplicates `verse_parts`; `resolved` repeats its tail (finding 2). |
| BIB_CONTENT_BUILDER cross-reference insert (build/bib_content_builder.e:108-110) | No duplicate; the long SQL strings follow the existing `run (l_db, "...")` style. |

## Recommended Order
1. Finding 2: smallest change, fixes a live drift, and the Study layout's reference box needs the same parser.
2. Findings 5 and 7: tiny engine additions that every panel in finding 1 will use.
3. Finding 1: panel split, Results then Commentary then Reading then Lexicon with the place stream; the Study layout is then a second layout class, not a copy.
4. Findings 4 and 6 together (they touch the same two queries).
5. Findings 3, 8, 9 and 10 when nearby code is touched.
