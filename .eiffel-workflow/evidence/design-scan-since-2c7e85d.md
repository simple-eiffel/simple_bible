# Design Scan (diff mode): simple_bible since 2c7e85d

Scope: subjects are the nine files changed since 2c7e85d under src, cli, gui_app, build and build_app
(build/bib_content_builder.e, build_app/bib_build_app.e, gui_app/bib_gui_app.e,
src/concordance/bib_conc_pack.e, src/concordance/bib_root_places.e, src/search/bib_place_sets.e,
src/search/bib_verse_search.e, src/simple_bible.e, src/versification/bib_versification_map.e).
Each was compared against all of src/, cli/, gui_app/, build/ and build_app/. Read-only; nothing was compiled.
All paths are relative to the repository root.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Drift (D1) | 3 | 3 | 0 | 0 |
| Abstraction | 2 | 0 | 1 | 1 |
| Robustness / contracts | 4 | 0 | 2 | 2 |
| **Total** | **9** | **3** | **3** | **3** |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_CONTENT_BUILDER, BIB_BOOK_CATALOG, BIB_CANON | Tvtms_books is a second positional table of book codes, unchecked against book_catalog |
| 2 | HIGH | D1 | BIB_VERSE_SEARCH, BIB_VERSIFICATION_SYSTEM, BIB_CONTENT_BUILDER, gui_app | "kjv" / "hebrew" strings: a fifth to seventh copy, and the existing copies already disagree |
| 3 | HIGH | D1 | BIB_VERSIFICATION_MAP | english_place (new, table-driven) beside mapped / pair (rule-driven): two mapping interfaces that can disagree |
| 4 | MEDIUM | robustness | BIB_CONTENT_BUILDER | write_versification_map: documented "counted" rows are not counted; a missing or wrong file section is silent; INSERT OR IGNORE is silent |
| 5 | MEDIUM | robustness | BIB_VERSIFICATION_MAP | hebrew_moves once("OBJECT") caches a failed or early read forever and swallows the query error |
| 6 | MEDIUM | abstraction | BIB_VERSE_SEARCH, gui_app | has_moved_hebrew_roots and has_hebrew_roots are two flags the heading note treats as exclusive |
| 7 | LOW | robustness | BIB_PLACE_SETS | sorted_once: insertion sort with a contract that does not state the "nearly sorted" assumption |
| 8 | LOW | abstraction | BIB_ROOT_PLACES | places is now a computing function (a union per call), formerly an attribute |
| 9 | LOW | robustness | BIB_CONTENT_BUILDER | BEGIN left open when a row fails; provenance row 3 written even when zero rows follow |

## Detailed Findings

### Finding 1: Tvtms_books duplicates the book catalog by position
**Priority:** HIGH (D1)
**Classes:** BIB_CONTENT_BUILDER (build/bib_content_builder.e), BIB_BOOK_CATALOG (src/core/bib_book_catalog.e), BIB_CANON (src/core/bib_canon.e)
**Description:** Book numbers in the map come from the position of a TVTMS code in a hand-typed array.
The library already has two owners of "which number is which book": the book_catalog table
(built at build/bib_content_builder.e:134 from bible.db abbreviations and read by
src/core/bib_book_catalog.e:46-53) and BIB_CANON (src/core/bib_canon.e:18 for the limit, with the
ordering owned by the vault's bible_books ids). Tvtms_books is a third table, tied to the other two
only by the count contract at build/bib_content_builder.e:375
(`Result.count = {BIB_CANON}.Last_old_testament_book`). A swapped pair of codes, or a vault whose
bible_books order differs, still passes that contract and silently writes wrong book numbers
(for example "Sng" at position 22 versus a bible_books row 22). Past design scans 48 and 51
(noted in src/core/bib_canon.e and src/search/bib_place_sets.e) removed exactly this kind of second
owner.
**Evidence:**
- build/bib_content_builder.e:369-376: Tvtms_books array and count-only ensure
- build/bib_content_builder.e:134: book_catalog filled from bible.db, never compared with Tvtms_books
- build/bib_content_builder.e:347-351: position becomes l_id with no catalog lookup
**Suggested Action:** Name a mapping from the TVTMS code to the catalog name ("Sng" to "Song of Solomon") only as data, and have write_versification_map verify, for each of the 39 positions, that book_catalog's row at that book_id carries the same book; fail the build with last_error when one differs. Alternatively a postcondition-style check in the builder after write_book_catalog.
**Effort:** 1 check, no new class.

### Finding 2: "kjv" and "hebrew" versification strings are copied again, and the copies already disagree
**Priority:** HIGH (D1)
**Classes:** BIB_VERSE_SEARCH, BIB_VERSIFICATION_SYSTEM, BIB_CONTENT_BUILDER, BIB_COMMENTARY_BUILDER, BIB_GUI_APP
**Description:** The builder writes the strings 'hebrew', 'lxx', 'vulgate', 'kjv' into version_info
(build/bib_content_builder.e:208, final CASE). The new reads_english_numbers compares against a
literal "kjv" (src/search/bib_verse_search.e:123). The same literal appears in
gui_app/bib_gui_app.e:2741, build/bib_commentary_builder.e:225 (as a default) and "hebrew" in
gui_app/bib_gui_app.e:1355 and :1368. Worse, BIB_VERSIFICATION_SYSTEM.label uses a different
vocabulary for the same systems: "kjv", "mt", "swete", "rahlfs_ccat", "vulgate"
(src/core/bib_versification_system.e:70-80); "mt" there is "hebrew" in version_info, and "lxx" in
version_info has two labels in the class. So the string set has no single owner and two vocabularies
already diverged. The new map ("hebrew" system column, build/bib_content_builder.e:309;
src/versification/bib_versification_map.e:118) adds a third place that must say "hebrew".
**Evidence:**
- src/search/bib_verse_search.e:123 `same_string ("kjv")`
- src/core/bib_versification_system.e:70-80 labels "kjv", "mt", "swete", "rahlfs_ccat", "vulgate"
- build/bib_content_builder.e:208 CASE writes 'hebrew' / 'lxx' / 'vulgate' / 'kjv'
- gui_app/bib_gui_app.e:1355, 1368, 2741 literals
- src/versification/bib_versification_map.e:118 and build/bib_content_builder.e:309 literal 'hebrew'
**Suggested Action:** One owner of the version_info vocabulary (constants on BIB_VERSIFICATION_SYSTEM, for example Label_kjv, Label_hebrew), used by the builder SQL (concatenated, as BIB_CANON.Last_book already is at build/bib_content_builder.e:139), BIB_VERSE_SEARCH, the map and the GUI; and a query on BIB_READING_VERSION (uses_english_numbers) replacing the literal compare. Reconcile "mt" with "hebrew" at the same time.
**Effort:** about 8 literals, 1 query.

### Finding 3: english_place beside mapped / pair is a second mapping interface
**Priority:** HIGH (D1)
**Classes:** BIB_VERSIFICATION_MAP (src/versification/bib_versification_map.e)
**Description:** The class's specified interface is `mapped` (:66) and `pair` (:77), which "name their
rules" and return every target (class header, lines 5-6; postconditions :74-90). The new `english_place`
(:53-62) answers "where does this place land in English" from a separate table read (`hebrew_moves`,
:109-126) that discards the rule name and keeps only one target. Both read versification_map. The two
can disagree for the same verse: pair returns every target and a rule; english_place returns the first
row kept by INSERT OR IGNORE (Finding 4). `mapped` is still a Phase 4 stub comment (:71 "Phase 4: look up
versification_map"), so the real table now has one live reader that bypasses the specification.
**Evidence:**
- src/versification/bib_versification_map.e:53-62 english_place; :109-126 hebrew_moves
- src/versification/bib_versification_map.e:66-90 mapped and pair contracts (rules reported, every target)
- build/bib_content_builder.e:199 versification_map schema carries `rule`, which hebrew_moves never selects
**Suggested Action:** Make english_place a thin, named projection of pair/mapped (or of one shared loader of versification_map rows), or document it in the class header as the bulk, single-target, search-only path and state the relation in a contract (english_place (p) is the first target of pair for p). Do not let the two read the table separately.
**Effort:** 1 feature plus a shared row loader.

### Finding 4: write_versification_map failures and drops are not all reported
**Priority:** MEDIUM
**Classes:** BIB_CONTENT_BUILDER (build/bib_content_builder.e)
**Description:**
- The header (:276-280) says "A row the reader cannot place is left out and counted", but nothing is counted: tvtms_place returning Void (:306-308 condition) is skipped with no counter, and BIB_CONTENT_BUILDER has no attribute for it (only versification_rows_written, :53). The bible_build output (build_app/bib_build_app.e:83) prints only the surviving row count.
- A TVTMS file without "#DataStart(Expanded)" (a renamed section in a newer STEPBible release) yields zero rows and no error: l_in_expanded never becomes True (:295), `versification_rows_written` is 0, and the build still succeeds. The user passed --tvtms and gets a content.db without a map and a normal exit code 0.
- Insert failures are reported (note_failure, :311) and an unreadable file is reported (:289-290), but `l_lines.count < 3` is the only read check; a file of the wrong encoding passes.
- INSERT OR IGNORE (:309) keeps the FIRST TVTMS row for a Hebrew verse that has several rows (a divided verse listed once per part, or a verse named by both a Renumber and a Divided row). Which row comes first is the file's order, not a rule: the first English verse is a reasonable choice for DividedPrev/DividedNext, but the code neither says so nor counts the ignored rows. Several different Hebrew verses merging into one English verse is NOT a conflict: the primary key is the Hebrew side (:199), so each keeps its own row, and the search side removes the duplicate English place (sorted_once, src/search/bib_place_sets.e:50-53).
**Evidence:** build/bib_content_builder.e:276-280, 289-290, 295, 305-311, 317-321; build_app/bib_build_app.e:83.
**Suggested Action:** Count skipped (unplaceable) and ignored (duplicate Hebrew key) rows into two attributes, print them in bible_build, and set last_error when --tvtms was given and the expanded section was never found or produced zero rows. State the "first row wins" rule in the header comment and in the rule column's meaning.
**Effort:** 2 attributes, 1 check.

### Finding 5: hebrew_moves caches an empty or failed read for the life of the object
**Priority:** MEDIUM
**Classes:** BIB_VERSIFICATION_MAP, SIMPLE_BIBLE (src/simple_bible.e:295 once ("OBJECT") for versification)
**Description:** hebrew_moves is a once ("OBJECT") (src/versification/bib_versification_map.e:114). If
`sources.is_open` is False at the first call (:117) or run_query fails (:118-119), the empty table is
cached permanently; has_hebrew_map (:47-51) then reports False for that object and the search quietly
reverts to Hebrew numbers, with no error recorded (last_query_error from BIB_SQLITE_QUERYING is never
read here). Because SIMPLE_BIBLE.versification is itself a once per instance whose precondition is
`open`, a content.db REOPENED on the same SIMPLE_BIBLE object would keep the old table: the policy
"this never closes the Bible" (src/simple_bible.e near :270) makes this unlikely today, but the cache
has no invalidation hook. A missing table (older content.db) and a genuine query failure are
indistinguishable.
**Evidence:** src/versification/bib_versification_map.e:109-126; src/simple_bible.e:291-297.
**Suggested Action:** Distinguish "table absent" (empty, fine) from "query failed" (record the error and do not cache, or expose it so the search can set error_message); the same-object reopen can be left as a dated note.
**Effort:** 1 feature.

### Finding 6: two heading-note flags that the GUI treats as exclusive
**Priority:** MEDIUM
**Classes:** BIB_VERSE_SEARCH (src/search/bib_verse_search.e:54, 84-86, 190-200), BIB_GUI_APP (gui_app/bib_gui_app.e:3143-3147)
**Description:** has_moved_hebrew_roots and has_hebrew_roots can both be True in one query: a clause
against a version that reads English numbers moves its Hebrew side (:190-195) while a clause evaluated
for another version (for example a scope or a second clause) leaves the Hebrew side unmoved (:196-200).
The GUI's if/elseif (gui_app/bib_gui_app.e:3143-3147) then shows only the "moved" note and drops the
"stand in Hebrew verse numbers" warning. In practice find uses one version per call, so the collision
needs the version to change mid-evaluation; the exposure is small but the two flags and the elseif
encode a state machine in two places.
**Evidence:** src/search/bib_verse_search.e:190-200; gui_app/bib_gui_app.e:3143-3147.
**Suggested Action:** One query on BIB_VERSE_SEARCH, numbering_note (a STRING_32 or an enumerated state: none, hebrew, moved, both), owning the wording decision, so the GUI only displays it. This is the same direction as the earlier "value, not side effect" change that produced BIB_ROOT_PLACES.
**Effort:** 1 feature, 1 caller.

### Finding 7: sorted_once's insertion sort and its contract
**Priority:** LOW
**Classes:** BIB_PLACE_SETS (src/search/bib_place_sets.e:32-58)
**Description:** Cost: O(n) when the list is nearly sorted, O(n squared) for a badly ordered list. The
comment (:33-34) says the lists "are nearly sorted" but neither a precondition nor a note records the
bound. Its only caller (src/search/bib_verse_search.e:135) passes an ascending Hebrew list mapped
through a table that moves a verse back by at most one chapter (Malachi 3:19 to 4:1 and Joel 3:1 to
2:28 stay inside their book), so the worst-case displacement per element is small and a common root
(a few thousand places) costs little. Other costs: l_sorted := a_places.twin (:41) copies the list
that the second loop then copies again into Result (:53-58); the postcondition `is_ascending (Result)`
(:57) is O(n) per call and runs in finalized test code only. Any future caller with an arbitrary list
(a descending list is the worst case) gets quadratic behavior from a class named for set algebra.
**Evidence:** src/search/bib_place_sets.e:32-58; src/search/bib_verse_search.e:126-136.
**Suggested Action:** Either document the assumption as the contract ("nearly sorted: each place is at most K positions from its sorted slot") with a dated note, or use the ecosystem's sorter (simple_sorter) for the general case; merge the twin and the dedup into one pass.
**Effort:** 1 feature.

### Finding 8: BIB_ROOT_PLACES.places now allocates per call
**Priority:** LOW
**Classes:** BIB_ROOT_PLACES (src/concordance/bib_root_places.e:56-60)
**Description:** places was an attribute; it is now `union (hebrew_places, greek_places)`, a new
list per call, and has_hebrew / has_greek are computed too (:62-72). The only reader is one call at
src/search/bib_verse_search.e:197, so the cost is one merge per clause. No contract states that
`places` is ascending-once (it was implicit before); BIB_PLACE_SETS.union's postcondition gives it
for free but the class does not repeat it. Inheriting BIB_PLACE_SETS (:17-18) only for `union` pulls
in the whole set algebra, which is the intended side-by-side style, so no objection to that.
**Evidence:** src/concordance/bib_root_places.e:56-60, 17-18; src/search/bib_verse_search.e:190-197.
**Suggested Action:** Add `ascending_once: is_ascending (Result)` as a postcondition on places, or cache it at make; leave inheritance as is.
**Effort:** 1 contract.

### Finding 9: transaction left open on failure; provenance row without rows
**Priority:** LOW
**Classes:** BIB_CONTENT_BUILDER (build/bib_content_builder.e:292-317)
**Description:** When an INSERT fails, `run (a_db, "COMMIT")` at :317 is skipped by run's
`last_error = Void` guard (:411), so BEGIN (:293) is never closed. The temp file is discarded on
failure, so no corrupt output results, but it differs from write_verse_index's handling of the same
pair (BEGIN at :244, COMMIT at :265). Separately, provenance row 3 (:292) is written before the file
is parsed, so a TVTMS file that yields zero rows still leaves a "STEPBible TVTMS" source listed in
the content.db with no data behind it (see Finding 4).
**Evidence:** build/bib_content_builder.e:244/265 versus 293/317; 292.
**Suggested Action:** Insert the provenance row only when at least one row was written, or after the loop.
**Effort:** 1 reorder.

## Checked and found sound

- Many Hebrew verses to one English verse: the primary key is the Hebrew side (build/bib_content_builder.e:199), so INSERT OR IGNORE only drops a genuine duplicate Hebrew key; merged targets are removed by sorted_once (src/search/bib_place_sets.e:53-58). The first-row-wins question applies only to a Hebrew verse that TVTMS lists twice (Finding 4).
- tvtms_place guards the packed range with BIB_PLACE_PACKING.Max_part (build/bib_content_builder.e:361) rather than a literal, consistent with the earlier BIB_CANON cleanup.
- The single-lookup order in BIB_VERSE_SEARCH is correct: the Hebrew side moves before union with the Greek side (src/search/bib_verse_search.e:190-192), and union's ascending precondition is satisfied by sorted_once's postcondition.
- Contract costs: the new postcondition is_ascending (O(n)) on sorted_once is the only one in a search path; the builder's Tvtms_books ensure is a count compare on a once. No contract added in a hot loop.

## Recommended Order

1. Finding 2 (shared version vocabulary): small, touches the same files the next map work will, and the "mt" versus "hebrew" divergence is a latent defect.
2. Finding 1 (catalog check): one verification step in the builder protects every row of the map.
3. Finding 3 (one mapping interface): decide before more readers of versification_map are added.
4. Finding 4, then 5 (reporting of dropped rows and failed reads).
5. Findings 6 to 9 as cleanup.
