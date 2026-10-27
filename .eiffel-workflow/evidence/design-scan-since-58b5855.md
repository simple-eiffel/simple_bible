# Design Scan (diff mode): simple_bible since 58b5855

Mode: read-only, nothing compiled. Subjects (changed since 58b5855, under src, cli, gui_app, build, build_app):
`src/concordance/bib_conc_pack.e`, `src/search/bib_search_scopes.e` (new), `src/search/bib_verse_search.e`, `src/simple_bible.e`.
Each subject was compared against src, cli, gui_app, build, build_app and testing.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 2 |
| MEDIUM | 3 |
| LOW | 2 |
| **Total** | **7** |

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_SEARCH_SCOPES, BIB_GUI_APP, BIB_LOOKUP, tests, builder | Book-range constants (39, 40, 66, 40-43, 45-57) now live in at least five places |
| 2 | HIGH | D1 / A5 | BIB_GUI_APP, BIB_SEARCH_SCOPES, tests | The whole-Bible scope is built ad hoc in the GUI and tests while a named factory now exists |
| 3 | MEDIUM | A1 | BIB_SEARCH_SCOPE, BIB_VERSE_SEARCH | The book-range test is written three times; the scope's own `contains` is not used |
| 4 | MEDIUM | contract cost | BIB_VERSE_SEARCH | The `in_scope` postcondition repeats the whole filter over every result |
| 5 | MEDIUM | placement | BIB_CONC_PACK, BIB_NORMALIZER_SET | The schwa fold sits in SQL, defeats the index, and is applied to the stored side only |
| 6 | LOW | A3 | BIB_SEARCH_SCOPES | Scope names are an if-chain of string literals |
| 7 | LOW | cleanup | BIB_SEARCH_SCOPES | `whole_bible` allocates per call; scope labels differ in style |

## Detailed Findings

### Finding 1: Book-range constants have several owners (D1)
**Priority:** HIGH (drift is always HIGH). No value has diverged yet; the copies are one edit away from diverging.
**Evidence:**
- `src/search/bib_search_scopes.e:66-67`: `Last_old_testament_book = 39`, `Last_book = 66` (new).
- `src/search/bib_search_scopes.e:48` and `:50`: literals 40, 43 (Gospels) and 45, 57 (Paul's letters). These two ranges exist only here.
- `gui_app/bib_gui_app.e:3320`: its own `Last_book = 66`, with a comment citing the vault's book ids (FR-105).
- `gui_app/bib_gui_app.e:1510-1511`: the navigator builds "Old Testament" as literal `1, 39` and "New Testament" as literal `40, Last_book`. It mixes a literal 39 with a constant 66, and never uses the new `Last_old_testament_book`.
- `gui_app/bib_gui_app.e:2600`: `reading_book <= 39` picks WLC versus TR, a third spelling of the testament boundary.
- `cli/bib_lookup.e:346-347`: its own `Last_old_testament_book = 39`, used at `:82` and `:118`, with a comment citing FR-105.
- `build/bib_content_builder.e:121`: SQL `BETWEEN 1 AND 66` twice.
- `src/search/bib_count_table.e:20-21`: `make (66)` for per-book tables.
- Tests: `testing/test_search.e:172` (`40, 66`), `:180` (`1, 66`), `testing/test_content_builder.e:257` (`1, 66`).
- Related: `gui_app/bib_nav_node.e:62-63` carries `first_book, last_book` for a testament node, which is the same concept as a scope's range.

**Description:** Two constants, Old Testament end and canon end, are declared in three classes (`BIB_SEARCH_SCOPES`, `BIB_GUI_APP`, `BIB_LOOKUP`) and inlined as literals in at least four more places. The new class is the third declaration, and the GUI still ignores it. A deuterocanonical or versification change would have to find every one.
**Suggested Action:** A deferred or constants ancestor (for example `BIB_CANON_BOOKS`, holding `Last_old_testament_book`, `First_new_testament_book`, `Last_book`, and the Gospel and Pauline ranges) that BIB_SEARCH_SCOPES, BIB_GUI_APP and BIB_LOOKUP inherit side by side. `BIB_BOOK_CATALOG` (`src/core/bib_book_catalog.e`) is the other candidate owner: the content builder's `bible_books` table already has a `testament` column (`testing/test_content_builder.e:346`), so the boundary could be data rather than a constant. Needs Larry's word before anything moves.
**Effort:** 2 constants, 3 declarations, about 8 literal sites.

### Finding 2: The whole-Bible scope is built ad hoc beside a factory (D1 / A5)
**Priority:** HIGH
**Evidence:**
- `src/search/bib_search_scopes.e:56-62`: `whole_bible (a_version)` builds `make ("the whole Bible", <<a_version>>, 1, Last_book, "verses")`.
- `gui_app/bib_gui_app.e:848` and `:3056`: `create {BIB_SEARCH_SCOPE}.make ("verses", ..., 1, Last_book, "verses")`. Same range, same unit, a different label ("verses" versus "the whole Bible"), and the GUI's own `Last_book`.
- `testing/test_search.e:180` and `testing/test_content_builder.e:257`: the same shape with a literal 66.
- `testing/test_search.e:172`: an NT scope built by hand (`40, 66`) while `scope_named ("NT", ...)` now exists; `testing/test_content_builder.e:163-167` exercises `scope_named` but through `found_scoped`, separate from the hand-built scope at `:257`.
- `src/simple_bible.e:337-343`: `search_scopes` is the new facade entry the GUI could call as `bible.search_scopes.whole_bible (reading_version)`.

**Description:** The two GUI sites already diverge in label from the factory; scope labels reach census and shape output, so a label drift is visible to users. The GUI also cannot offer OT, NT, Gospels or Paul's letters, though the facade now supplies them (`scope_named`).
**Suggested Action:** Route the GUI and tests through `search_scopes.whole_bible` and `scope_named`; the GUI keeps its default behavior. `whole_bible`'s label wins as the single spelling.
**Effort:** 4 call sites in gui_app and testing.

### Finding 3: The book-range test is written three times; `contains` is bypassed (A1)
**Priority:** MEDIUM
**Evidence:**
- `src/search/bib_search_scope.e:62-66`: `contains (a_ref: BIB_REF)` tests `book_id >= first_book and <= last_book`.
- `src/search/bib_verse_search.e:123`: `within_scope` repeats the test on `keys.book_part (ic)`.
- `src/search/bib_verse_search.e:86`: the postcondition repeats it again.
- A grep of src, cli, gui_app and testing found no caller of `BIB_SEARCH_SCOPE.contains`, so the feature that owns the rule is unused while the rule is copied.

**Description:** The scope owns the rule but speaks only in `BIB_REF`, while verse search holds packed places, so each caller re-wrote it. Add `contains_book (a_book: INTEGER): BOOLEAN` to `BIB_SEARCH_SCOPE` (with `contains` defined through it) and call it from `within_scope` and the contract. Then a future range change (for example a non-contiguous scope such as the Gospels plus Acts) edits one feature.
**Suggested Action:** Add `contains_book`; use it at the three sites.
**Effort:** 1 new feature, 2 call sites.

### Finding 4: Contract cost of `in_scope`
**Priority:** MEDIUM
**Evidence:** `src/search/bib_verse_search.e:86` re-walks `places` and calls `keys.book_part` (a once object, line 118-122) twice per element after `within_scope` (`:124-134`) has already filtered by the same test. A search such as "the" in the whole Bible returns tens of thousands of places. Test executables run finalized with contracts on (`ec.sh test`), so every search in the suite pays a second full pass. The existing `ascending_once: is_ascending (places)` at `:85` is already a full pass too, so this is a third.
**Description:** `in_scope` is correct and valuable as a check on `within_scope`, but it is an O(n) tautology of the loop above it. Per the timing note in project memory ("hot paths keep only cheap critical contracts"), either move the check to a postcondition on `within_scope` itself guarded by the cheap case, or keep it and make `within_scope` return `a_places` unchanged when the scope covers the whole canon (`first_book = 1 and last_book = Last_book`, the case at both GUI call sites, which today copies the whole list for nothing).
**Suggested Action:** Short-circuit the whole-canon case; wrap the heavy clause for `without_contracts` timing tests. Measure before deciding.
**Effort:** 1 feature.

### Finding 5: Schwa fold placement in `headwords_for_text`
**Priority:** MEDIUM
**Evidence:**
- `src/concordance/bib_conc_pack.e:475`: `... OR replace(l.translit_ascii, ?, 'e') = ?` with the parameter `{STRING_32} "%/601/"` (schwa) at `:478`.
- `src/concordance/bib_conc_pack.e:445-449`: `original_search_form` delegates to `folds.pack_token_form`, which folds the query side only (`src/text/bib_normalizer_set.e:38-55`).
- The fold applies to the stored column, not the query, so the pack data keeps the schwa and every row is rewritten at query time.

**Description:** Because the schwa is in the stored `translit_ascii`, the query-side fold in `pack_token_form` cannot fix it; that part of the question has a clear answer: the query form is not the right home. The better homes are (a) the pack builder, so the column is written with e (the pack is built outside this repository's `build/`, so this needs the pack's maintainer), or (b) a second stored column such as `translit_plain`. As written, `replace()` over the column prevents using any index on `translit_ascii` for the fifth term; the OR already forces a scan, but the scan now computes a function per row. `Max_text_matches` bounds the output, not the work. It also hard-codes one schwa where `pack_token_form` documents a single shared fold, so a future second character would add a third SQL expression. Note the reverse direction: a reader who types the schwa itself still matches through the third term, so no regression.
**Suggested Action:** Prefer fixing the pack data; if the SQL stays, name the code point as a constant next to `Max_text_matches` instead of an inline `%/601/`.
**Effort:** 1 feature.

### Finding 6: Scope names as an if-chain
**Priority:** LOW
**Evidence:** `src/search/bib_search_scopes.e:43-53`: five branches each comparing with `same_string` against inline literals, with synonyms ("pauline letters", "paul") inline at `:49`.
**Description:** A table (name, first, last, label) would make adding "Pentateuch" or "Torah" a one-line change and let tests iterate the table. It would also hold the Gospel and Pauline ranges (Finding 1) in one place.
**Effort:** 1 feature.

### Finding 7: Minor cleanup in the new class
**Priority:** LOW
**Evidence:** `src/search/bib_search_scopes.e:56-62` allocates a new scope per call; labels mix "Old Testament" (`:44`) with "the Gospels" (`:48`), "the whole Bible" (`:61`) and a bare book name (`:52`), which reads oddly in headings. `src/search/bib_search_scopes.e:30` has `books` exported without a comment and the `Last_book` comment (`:68`) sits under both constants.
**Effort:** trivial.

## Recommended Order

1. Finding 1 (one owner for the canon boundary), because Findings 2, 3 and 6 all lean on it.
2. Finding 2 (GUI and tests through the factory), small and removes label drift.
3. Finding 3 (`contains_book`), then Finding 4 once measured.
4. Finding 5 when the pack data can be changed.
5. Findings 6 and 7 as time allows.

Nothing above is extracted without Larry's word.
