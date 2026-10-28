# Design Scan (diff mode): simple_bible, since 42f3f67
# Date: 2026-10-28
# Subjects: src/pack/bib_private_pack_schema.e (new), src/reading/bib_link_target.e (new), build/bib_pack_writing.e, build/bib_book_builder.e, build/bib_framework_builder.e, build/bib_commentary_builder.e, src/pack/bib_book_schema.e, bib_framework_schema.e, bib_commentary_schema.e, bib_book_block.e, src/reading/bib_reference_linker.e, gui_app/bib_gui_app.e, testing/test_reading.e
# Compared against: all of src/, build/, gui_app/, testing/
# Mode: read-only; nothing compiled, nothing run. Findings are proposals. Whether the merge compiles and its tests pass is not claimed here.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Contracts / edge cases | 3 | 1 | 1 | 1 |
| Abstraction | 2 | 0 | 1 | 1 |
| Behavior change | 3 | 0 | 1 | 2 |
| Tests | 1 | 0 | 1 | 0 |
| **Total** | **9** | **1** | **4** | **4** |

## Verdict on the previous scan's seven HIGHs

| Prev # | Subject | Verdict | What remains |
|--------|---------|---------|--------------|
| 1 | Three hover-card copies | Resolved | Card width of book and framework cards moved 440 to 460 (finding 8) |
| 2 | Three "bring into view" copies | Resolved (one helper) | Two visible behavior changes (finding 7); other bare `show_panel` uses are not copies |
| 3 | Builders repeat BIB_PACK_WRITING | Resolved | The `build` skeleton of the two builders is still parallel (not re-reported) |
| 4 | Schema ids and tables twice | Resolved | `Link_prefix` stays per schema (correct: grammars differ). Invariant cost: finding 5 |
| 5 | `link_text` above 9999 | Partly | Writer side closed (builder, `link_text`, `BIB_BOOK_BLOCK.make`); the reader guard was not updated: finding 1 (HIGH) |
| 6 | Dead abbreviations, faces disagree | Resolved | Forgiving-face order change is sound on the cases read (finding 6); tests cover only 5 forms |
| 7 | Link dispatch twice, grammars twice | Resolved for dispatch; partly for grammars | One reader now (BIB_LINK_TARGET), but it still calls three parsers with different number rules (finding 4) |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | contract | BIB_BOOK_PACK, BIB_BOOK_BLOCK | Reader guard accepts block or chapter above 9999; the new precondition then fires |
| 2 | MEDIUM | tests | BIB_LINK_TARGET, BIB_PACK_WRITING, BIB_BOOK_SCHEMA, bring_into_view | No test touches the new classes or contracts |
| 3 | MEDIUM | behavior | BIB_BOOK_BUILDER.write_indexes via BIB_LINK_TARGET | A malformed "framework:" link is now dropped silently; it used to be indexed |
| 4 | MEDIUM | A1 | BIB_LINK_TARGET, BIB_REFERENCE_LINKER, BIB_BOOK_SCHEMA | Three parsers behind one reader still disagree on zero and size; prefix handling repeated |
| 5 | MEDIUM | contract cost | BIB_PRIVATE_PACK_SCHEMA | Invariant on constant-equals-constant, run on every schema call |
| 6 | LOW | behavior | BIB_REFERENCE_LINKER.book_named | Forgiving-face order checked; class note out of date |
| 7 | LOW | behavior | BIB_GUI_APP.bring_into_view | Drift resolved; two behavior changes worth Larry's yes; no contract on the panel |
| 8 | LOW | T1 | BIB_GUI_APP.card | One width for all cards (440 to 460) |
| 9 | LOW | dead code | BIB_BOOK_BUILDER.write_indexes | `a_linker` parameter now unused |

## Detailed Findings

### Finding 1: Reader guard does not match the new BIB_BOOK_BLOCK precondition
**Priority:** HIGH (contract gap, type safety). **Category:** contract.
**Evidence:**
- src/pack/bib_book_block.e:29 now requires `a_chapter <= {BIB_BOOK_SCHEMA}.Max_part and a_block <= ...Max_part`; the invariant (line 90) says the same.
- src/pack/bib_book_pack.e:150 `blocks_answer` guards each row with only `is_book_id (...) and chapter >= 1 and block >= 1`, then calls `BIB_BOOK_BLOCK.make` at 151.
- A books.db row with block or chapter 10000 or more (a pack from an older or other builder, or edited by hand) passes the guard and breaks the precondition. In a finalized build with contracts baked in that is a contract violation inside a query answer. The previous scan (finding 10) had noted that this guard repeats the preconditions by hand; the merge made the repeat wrong.
**Suggested Action:** add `chapter <= Max_part and block <= Max_part` to the guard at line 150 (rows dropped as the other bad rows are), or better give BIB_BOOK_SCHEMA an `is_place (chapter, block)` query that the guard, the precondition and the invariant all call. Add a reader test with a row at 10000.
**Effort:** 1 clause or 1 query.

### Finding 2: The new code has no test of its own
**Priority:** MEDIUM. **Category:** tests.
**Evidence:** a search of testing/ for BIB_LINK_TARGET, bring_into_view, begin_private_pack, sidecars_with and link_text finds nothing. testing/test_reading.e:186-194 adds only the compact-form and box tests (1Pet, 1John, gn, Mt, 1pet).
- Untested: BIB_LINK_TARGET for each of framework, book, bible, none and the invalid-id case (bib_link_target.e:105-125); its invariant (163-167); `link_text` at 9999 and 10000 (bib_book_schema.e:73-90) and `is_count` at 0, 9999, 10000 (133-138); the builder's two `fail_unless` bounds (bib_book_builder.e:206, 213); `schema_statements` equal to the old commentary statements (bib_private_pack_schema.e:45-64).
- The abbreviation table has about 30 compact forms (bib_book_abbreviations.e:46-100); five are tested. "2Chr", "1Kgs", "3John" are not.
**Suggested Action:** one test class (test_link_target) with a row per kind and per boundary; one row per compact-form family.
**Effort:** about 15 asserts.

### Finding 3: A malformed framework link is now silently dropped from the index
**Priority:** MEDIUM. **Category:** behavior change.
**Evidence:** before the merge, `write_indexes` indexed any target that began with the framework prefix. Now (build/bib_book_builder.e:244-250) it asks `l_target.is_framework`, and BIB_LINK_TARGET.make (src/reading/bib_link_target.e:105-110) sets that only when `is_framework_id` holds. "framework:KACC" (capitals) or "framework:" (empty) becomes `is_none`; nothing is written or reported. A typo in a manifest used to reach the book_framework table and now is lost without a `last_error`. A "book:" link with a bad id has the same silence (it ends as is_none).
**Suggested Action:** decide with Larry: report an unknown framework link at build time, or accept the silence and say so in BIB_LINK_TARGET's header.

### Finding 4: One reader, still three differing parsers
**Priority:** MEDIUM. **Category:** A1.
**Evidence:**
- src/reading/bib_link_target.e:105-124 tries framework (own prefix test and `is_framework_id`), then BIB_BOOK_SCHEMA.link_place (bib_book_schema.e:92-131: counts 1 to 9999, no zero), then BIB_REFERENCE_LINKER.target_range (bib_reference_linker.e:138-170: `is_small_number`, zero allowed, at most 176).
- The framework branch strips its prefix by hand (line 106), the same shape as BIB_BOOK_SCHEMA.link_place (101-102). A fourth kind (essays) adds a fourth hand-written split.
- A "framework:" link with a bad id is `is_none` and does not fall through; a "book:" link with a bad shape does fall through (to target_range, which refuses it). Correct, but only because the prefixes differ.
**Description:** the dispatch duplication named last time is gone. What remains is the prefix split. A small deferred grammar ancestor (prefix, `body_of`) that each schema inherits side by side would let BIB_LINK_TARGET loop over grammars. Not urgent; propose when essays arrive.
**Effort:** 1 deferred class, 3 heirs.

### Finding 5: Invariant of a constant on a small, hot class
**Priority:** MEDIUM. **Category:** contract placement.
**Evidence:** src/pack/bib_private_pack_schema.e:71-72: `the_version_read: Schema_version = {BIB_PRIVATE_SOURCE}.Pack_schema_version`. Both sides are constants (src/pack/bib_private_source.e:173), so the clause cannot change after the first run. It is checked on entry and exit of every exported feature of all three schemas: `is_book_id` (called per row at bib_book_pack.e:150 and 165, per alias at bib_framework_pack.e:107, in BIB_BOOK_BLOCK.make's precondition, each time on a fresh `create {BIB_BOOK_SCHEMA}`), `is_count`, `link_place`. The class also now depends on the reader class BIB_PRIVATE_SOURCE. It is a sound law, but a law about two constants belongs in one test, not an invariant paid on each call (house rule: timing trumps contracts).
**Suggested Action:** move the equality to a test (or to a `schema_statements` postcondition, which runs once per build); keep the invariant empty.
Redeclaration rules checked and fine: deferred `Pack_kind`, `Pack_file_name`, `Pack_title` are effected by constant attributes in each heir (no `redefine` needed for a deferred feature); `pack_tables` by a `once` function; `Schema_version` is effective in the ancestor and removed from the commentary schema; the rename of `is_lowercase_id` in two heirs does not clash (no class inherits two schemas).

### Finding 6: The forgiving face's new order, checked
**Priority:** LOW. **Category:** behavior.
**Evidence:** src/reading/bib_reference_linker.e:307-333 `book_named`: exact name, then the table (the forgiving face asks with the first letter capitalized, `capitalized` at 337-352), then, forgiving only, the first prefix candidate. Compared with the old forgiving path (prefix only):
- Every table form that is also a prefix of one book gives the same book (table read at bib_book_abbreviations.e:38-103). "Phil" is Philippians in the table and was the first candidate before, so no change.
- New reach: forms that are not prefixes ("Jn", "Mt", "Mk", "Dt", "Gn", "Qoh", "Ezk", "Phlm", "1Cor", "1 Jn") now read in a box, as the class note promised.
- A table entry that disagrees with the old first prefix candidate: none found.
- Wording: the class header (bib_reference_linker.e:20-26) still says a box "forgives a prefix or lowercase" and "prose needs the exact name"; prose also takes the short forms and the box takes them too. Update the note.
- `starts_like_a_name` (about 446-461) now accepts digit then capital with no space; "3D" begins a name too, but `book_named` returns 0 for it, so no false link. The new `abbreviations` once function is stateless, fine under SCOOP.

### Finding 7: bring_into_view resolved the drift; two behavior changes and no contract
**Priority:** LOW. **Category:** D1 follow-up.
**Evidence:** gui_app/bib_gui_app.e:3335-3350.
- `show_framework` (about 4251) now calls `arrange (True)` when not in Study; before it did not. The Frameworks link from the Simple layout now switches to Study. The previous scan asked Larry to confirm this; it should be told to him.
- `start_in_notes` (3326-3331) used to restore any maximized pane unconditionally; now it restores only another pane's maximizing, so a maximized Notes pane stays maximized.
- `bring_into_view` has no precondition: `dock.panels.i_th (a_panel)` (line 3345) is checked only by the library. Add `valid_panel: a_panel >= 1 and a_panel <= dock.panels.count`.
- `window.request_render` is now called inside the helper (3349) and again by `show_book_place` and `show_framework`: harmless, redundant.
- Other `dock.show_panel` sites (4573, 4818) are single calls, not copies of the bundle.

### Finding 8: One card width
**Priority:** LOW. **Category:** T1.
**Evidence:** `Card_width = 460.0` (gui_app/bib_gui_app.e:3902) used by `card` (3908-3926). Book and framework cards were 440.0. One role, one token: good. A 20 pixel widening of two cards is visible; confirm in a snapshot.

### Finding 9: Unused parameter after the link target move
**Priority:** LOW. **Category:** dead code.
**Evidence:** build/bib_book_builder.e:226 `write_indexes (..., a_linker: BIB_REFERENCE_LINKER)` and its call at 219 still pass the linker; the body now reads links through `create l_target.make (ic, catalog)` and never uses `a_linker`. BIB_LINK_TARGET.make builds a fresh BIB_REFERENCE_LINKER per target (src/reading/bib_link_target.e:116): cheap, but one per link in every block of every book. Drop the parameter, or give BIB_LINK_TARGET a creation taking the linker.

## Checked and found sound
- src/pack/bib_private_pack_schema.e:45-64 `schema_statements` postconditions hold for the commentary pack's old statement order (meta, provenance, tables, version).
- build/bib_pack_writing.e: `fail_unless` carries "first failure stands" as a postcondition (306-308); `begin_private_pack` and `put_private_provenance` guard on `last_error` as `put_meta` does; `sidecars_with` requires a non-empty extension. The three builders lost about 60 lines. Commentary now writes `voice_status` after author and builder (meta row order differs; rows are keyed by `key`).
- src/reading/bib_link_target.e: the creation clause `create make` exports `make` to clients although it sits in `feature {NONE}`, so the window and the builder can create it. Invariant clauses `one_kind_at_most`, `named_by_id`, `bible_placed`, `bible_has_a_chapter` hold on all paths in `make` (a framework with an invalid id leaves everything False and `id` empty; a book leaves `book` 0; the bible branch needs `has_book (book)` so `book > 0`).
- BIB_BOOK_SCHEMA `link_text`, `link_place`, `is_count` agree on 1 to `Max_part` (bib_book_schema.e:73-138); `Max_part` is an integer constant, so no once or constant redeclaration issue.
- `on_commentary_link` (gui 4399-4430) is now one if/elseif chain on one target; the old double reading and separate trailing `if` are gone. It reads through `target_range` where it read `target_place`; `target_place` is a projection of `target_range` (bib_reference_linker.e:130-136), and the old extra check `verse >= 0` is always true.

## Recommended Order
1. Finding 1 (reader guard): a live contract hole created by this merge; add a test row.
2. Finding 2 (tests for link target, bounds, schema statements).
3. Finding 3 (decide on the silent drop of malformed framework links).
4. Finding 5 (move the version-equality law to a test).
5. Findings 4, 6, 7, 8, 9 as convenient; confirm findings 7 and 8's visible changes with Larry.
