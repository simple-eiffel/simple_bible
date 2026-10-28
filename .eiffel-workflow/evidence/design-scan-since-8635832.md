# Design Scan (diff mode): simple_bible, since 8635832
# Date: 2026-10-28
# Mode: read-only; nothing compiled, no source changed
# Subjects: src/pack/bib_framework_schema.e, bib_framework.e, bib_framework_spelling.e, bib_framework_pack.e, bib_framework_names.e;
#           build/bib_framework_builder.e; build_app/bib_build_app.e (--frameworks branch); cli/bib_reference_linker.e (framework branch);
#           src/simple_bible.e (framework_packs); gui_app/bib_gui_app.e ("Frameworks explained", link_card, snapshot_link_card)
# Compared against: all of src/, build/, cli/, gui_app/, build_app/

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A/D/T) | 12 | 4 | 4 | 4 |
| MI | 2 | 0 | 1 | 1 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **14** | **4** | **5** | **5** |

## Findings

| # | Priority | Category | Classes | Opportunity | Effort | Suggested Skill |
|---|----------|----------|---------|-------------|--------|-----------------|
| 1 | HIGH | A5 | BIB_FRAMEWORK_BUILDER, BIB_COMMENTARY_BUILDER | Shared deferred pack-builder ancestor plus a JSON-fields mixin: put_meta, text_of, check_db, the build skeleton | 4 features + skeleton | /eiffel.abstract, /eiffel.mi |
| 2 | HIGH | A5/A1 | BIB_FRAMEWORK_PACK, BIB_COMMENTARY_PACK | Shared deferred private-pack reader ancestor: make, pack_alias, title, is_available, pack_provenance, method_edition, non_empty, messages | 7 features | /eiffel.abstract |
| 3 | HIGH | D1 | BIB_FRAMEWORK_PACK (vs BIB_COMMENTARY_PACK, BIB_FRAMEWORK_BUILDER) | Framework reader invents its provenance; the stored row (with its caveat) is never read | 1 feature | refactor branch |
| 4 | HIGH | D1 | BIB_FRAMEWORK_BUILDER, BIB_FRAMEWORK_SCHEMA | Tier error text names four tiers, the schema has five | 1 line | refactor branch |
| 5 | MEDIUM | A1 | SIMPLE_BIBLE | framework_packs repeats commentary_packs | 2 features | refactor branch |
| 6 | MEDIUM | A5 | BIB_GUI_APP | framework_card repeats passage_card's card skeleton | 2 features | refactor branch |
| 7 | MEDIUM | A5/A6 | BIB_GUI_APP | Range label built twice (already drifted); no verse-range value object | 3 sites | /eiffel.abstract |
| 8 | MEDIUM | A5 (latent D1) | BIB_FRAMEWORK_BUILDER | The "name needs its mark" rule is written twice | 1 feature | refactor branch |
| 9 | MEDIUM | M4 | BIB_GUI_APP | Frameworks feature clause is a cohesive panel inside a 4765-line class | ~250 lines | /eiffel.mi |
| 10 | LOW | A6 | BIB_FRAMEWORK | Anonymous tuples for sections, uses, builder records | 3 classes | /eiffel.abstract |
| 11 | LOW | A5 | BIB_FRAMEWORK_PACK | `create {BIB_FRAMEWORK_SCHEMA}` inside loops and postconditions | 5 sites | refactor branch |
| 12 | LOW | A5 | BIB_FRAMEWORK_NAMES, BIB_FRAMEWORK_SPELLING | Spellings carried as class and as tuple | 1 constructor | refactor branch |
| 13 | LOW | M1 | BIB_LIST_RESULT | Not ITERABLE; callers copy by index | 1 feature | /eiffel.mi |
| 14 | LOW | T1/D1 | BIB_REFERENCE_LINKER, BIB_FRAMEWORK_NAMES, BIB_GUI_APP | Same-named is_word_character with different meaning; names cache never reset; displaced header comment; contract gaps | 4 spots | refactor branch |

## Detailed Findings

### Finding 1: Framework builder is a second copy of the commentary builder's plumbing
**Priority:** HIGH  **Category:** A5 (duplicated bodies)
**Classes:** build/bib_framework_builder.e, build/bib_commentary_builder.e (build/bib_content_builder.e also inherits BIB_SQLITE_REPORTING, line 18, and declares its own last_error, line 78)
**Description:** Three features are character-for-character copies and the build skeleton is the same 35 lines.
**Evidence:**
- put_meta: build/bib_framework_builder.e:322-329 = build/bib_commentary_builder.e:323-330.
- text_of: build/bib_framework_builder.e:331-339 = build/bib_commentary_builder.e:332-340.
- check_db: build/bib_framework_builder.e:357-363 = build/bib_commentary_builder.e:357-363.
- `last_error: detachable STRING_32` declared in both (framework:46, commentary:47) and again in bib_content_builder.e:78.
- Skeleton (delete old file, make database, run Schema_statements checking each, begin_transaction, put_meta for pack_kind/title/author/builder, commit with check_db, rollback if still in transaction, close): build/bib_framework_builder.e:106-141 vs build/bib_commentary_builder.e:104-137. Differences: the provenance insert and the per-record write.
- sidecars_in has the same shape (is_directory, files_with_extension, or a single file): build/bib_framework_builder.e:61-76 vs build/bib_commentary_builder.e:59-81 (extension and one-level descent differ).
- Dead store: `l_ok := l_file.delete` is assigned and never read, in both (framework:108, commentary:106).
- `strings_of` (framework:341-355) is a JSON reader of the same family as text_of; the commentary builder reads its lists by hand in write_list (commentary:287-301).
**Suggested Action (multiple inheritance, side by side):**
- BIB_JSON_FIELDS: effective mixin with text_of, strings_of, non_empty (usable by BIB_CONTENT_BUILDER too).
- BIB_PACK_WRITING: deferred (`schema_statements`, `pack_kind`, `pack_title`, `builder_name`, `write_records (a_db)`); effective last_error, put_meta, check_db, and a template `write_pack (a_path)` owning delete / create / schema / begin / meta / commit / rollback / close.
Both builders become `inherit BIB_PACK_WRITING, BIB_JSON_FIELDS`. A third pack (the prayer and memory packs are planned) would otherwise be a fifth copy.
**Effort:** 4 features + 1 template; about 90 lines removed.

### Finding 2: Framework pack reader is a second copy of the commentary pack reader
**Priority:** HIGH  **Category:** A5/A1
**Classes:** src/pack/bib_framework_pack.e, src/pack/bib_commentary_pack.e. The deferred-ancestor pattern is already established: BIB_SQLITE_QUERYING (src/data/bib_sqlite_querying.e:15-115) serves the concordance, text and versification readers.
**Evidence (identical or near-identical):**
- make: src/pack/bib_framework_pack.e:26-36 = src/pack/bib_commentary_pack.e:26-36.
- pack_alias, title, is_available: framework:40-48 = commentary:40-48.
- `sources: BIB_SOURCE_SET`: framework:191 = commentary:206.
- query_failed_message / not_open_message: framework:193-194, commentary:208-209 (only the noun differs).
- method_edition (title, or a default noun when empty): framework:196-202 = commentary:211-217.
- pack_provenance: framework:185-189 = commentary:190-194 (same license literal `make ("private", True, False, True, "Larry Rix")`).
- non_empty: commentary:196-204; also src/reading/bib_text_reader.e:374 and build/bib_commentary_builder.e:342 (different signature).
- The "one query per child table, AND the success flag, walk the rows" idiom: src/pack/bib_framework_pack.e:153-183 (3 queries) and src/pack/bib_commentary_pack.e:141-188 (5 queries): eight repetitions of `Result := Result and last_rows /= Void` followed by `if attached last_rows as al_rows then across al_rows.rows`.
**Suggested Action:** deferred BIB_PRIVATE_PACK_READER inheriting BIB_SQLITE_QUERYING: deferred `pack_noun`; effective make, pack_alias, title, is_available, sources, the two messages built from pack_noun, method_edition, pack_provenance (see Finding 3), non_empty; plus a helper `each_row (a_sql, a_id, a_action): BOOLEAN` running one child query and answering whether it succeeded. Contract: `is_available` ensure `Result implies sources.is_open`.
**Effort:** 7 features + 1 helper; about 70 lines removed.

### Finding 3: Drift - the framework reader invents the provenance the builder wrote
**Priority:** HIGH (D1)  **Category:** D1
**Classes:** src/pack/bib_framework_pack.e, build/bib_framework_builder.e, src/pack/bib_commentary_pack.e
**Description:** The builder writes a real source_provenance row (build/bib_framework_builder.e:122-124: source "frameworks sidecars", edition Pack_title, license 'private', restricted 1, credit 'Larry Rix', caveat "Plain-reader rewrites; a draft until Larry approves it.") and every table row carries provenance_key (src/pack/bib_framework_schema.e:93-97). BIB_FRAMEWORK_PACK never reads it: pack_provenance (src/pack/bib_framework_pack.e:185-189) fabricates key 1, uses the title as source key and edition, and passes an empty caveat. The commentary pack JOINs source_provenance and builds each BIB_PROVENANCE from the stored row (src/pack/bib_commentary_pack.e:79-82, 127-128). The caveat is lost and a license or credit change in the pack would never reach an answer, in a project whose rule is that a private result is never unlabeled (src/pack/bib_private_source.e:3-10).
**Copy whose behavior should win:** the commentary pack's (read the stored row).
**Suggested Action:** read source_provenance in `frameworks`, `framework`, `aliases` (JOIN on provenance_key as commentary_pack.e:127-128), or once and cache; best as `read_provenance` in the Finding 2 ancestor. Add a test: a framework answer's caveat is not empty.
**Effort:** 1 feature + ancestor helper.

### Finding 4: Drift - tier error text names four tiers, schema has five
**Priority:** HIGH (D1: divergence is a live defect, though small)  **Category:** D1
**Evidence:** build/bib_framework_builder.e:188: "its tier is not cornerstone, master, recovery or sub". src/pack/bib_framework_schema.e:50: `Tiers = <<"cornerstone", "bedrock", "master", "recovery", "sub">>`. A sidecar with a wrong tier is told a list that omits a valid one.
**Suggested Action:** build the message from `schema.Tiers`; likewise the status text at line 189 from Draft/Reviewed.
**Effort:** 2 lines.

### Finding 5: framework_packs is a second copy of commentary_packs
**Priority:** MEDIUM  **Category:** A1
**Evidence:** src/simple_bible.e:173-182 (commentary_packs) and 184-193 (framework_packs): same loop and same `ic.is_open and then ic.pack_kind.same_string (...Pack_kind)` filter; only the created class differs (small drift: `make (private_packs.count)` vs `make (1)`). The window re-asks every use: gui_app/bib_gui_app.e:3937-3938 calls `bible.framework_packs` twice per `framework_pack`, each call rebuilding pack objects.
**Suggested Action:** after Finding 2, one `packs_of_kind (a_kind)` over the ancestor type, or cache both lists in attach_private_packs (they cannot change between opens).
**Effort:** 2 features.

### Finding 6: framework_card repeats passage_card's card skeleton
**Priority:** MEDIUM  **Category:** A5
**Evidence:** gui_app/bib_gui_app.e:3797-3860 (passage_card) and 4072-4099 (framework_card) both create a title SW_LABEL (`Role_ui, 13.0, True`), a body SW_LABEL (`make_body`, `with_wrap`), an SW_COLUMN `with_gap (6.0)`, put the labels, and `create Result.make (l_column, <width>)`. Differences: width 460.0 vs 440.0, and the framework card adds a muted hint. The literals 13.0, 6.0, 460.0, 440.0 are card tokens (T1).
**Suggested Action:** `text_card (a_title, a_body, a_hint, a_width): SW_HOVER_CARD` with Card_gap, Card_title_size, Card_width constants; both cards call it.
**Effort:** 2 features.

### Finding 7: Range label built twice (already drifted); no verse-range value
**Priority:** MEDIUM  **Category:** A5/A6
**Evidence:**
- passage_card builds "Book c:v-c:v" at gui_app/bib_gui_app.e:3843-3853; framework_page builds the same label at 4044-4050. Drift: passage_card appends ":end_verse" only when `a_end_verse > 0` (3846-3848); framework_page always appends it (4047).
- `create {BIB_REFERENCE_LINKER}.make (bible.books)` is made afresh at 3786, 4052 and 4162, and a fourth time in page_linker (3942-3949), each to call a converter (target_range, range_target_text, target_place).
- A five-integer range (book, chapter, verse, end_chapter, end_verse) travels as separate arguments or anonymous tuples: passage_card (3797), range_target_text (cli/bib_reference_linker.e), BIB_COMMENTARY_SECTION, BIB_FRAMEWORK.uses (src/pack/bib_framework.e:79), the linker's reference_at result (cli/bib_reference_linker.e:69).
**Suggested Action:** value class BIB_VERSE_RANGE (book, start and end chapter and verse; invariant end >= start; `is_whole_chapter`), held by BIB_COMMENTARY_SECTION and the framework use; one `range_label` and one window-level linker feature. Fix the end_verse = 0 label first.
**Effort:** 1 class + 3 call sites.

### Finding 8: "Needs its mark" is written in two places
**Priority:** MEDIUM (latent D1)  **Category:** A5
**Evidence:** build/bib_framework_builder.e:255 stores needs_mark as `i = 1 and a_record.mark`; build/bib_framework_builder.e:291 builds the linker's spellings with `ic.mark and then ic_alias.same_string (ic.name)`. If one changes, the stored aliases and the commentary-use scan disagree, and uses are silently missed.
**Suggested Action:** one feature `spelling_needs_mark (a_record, a_spelling)`, or have write_uses read back the table it just wrote so the stored aliases are the single source.
**Effort:** 1 feature.

### Finding 9: Frameworks feature clause is a panel inside a monolith
**Priority:** MEDIUM  **Category:** M4
**Evidence:** gui_app/bib_gui_app.e is 4765 lines. The clause at 3912-4104 owns eleven features and four attributes (frameworks_grid, framework_rows, framework_view, framework_names_cache) and reaches the rest only through bible, commentary_reader, dock, lexicon_tabs, place_text and reselect. Construction is scattered over lines 172-174, 539-543, 721, 791-793.
**Suggested Action:** a BIB_FRAMEWORKS_VIEW class (or a deferred pane ancestor holding the grid/view/page triple, which the commentary tab also repeats) with a few agents supplied by the window. Do after Findings 6 and 7.
**Effort:** about 250 lines move.

### Finding 10: Anonymous tuples where classes belong
**Priority:** LOW  **Category:** A6
**Evidence:** src/pack/bib_framework.e:73-79 (sections and uses as tuples); build/bib_framework_builder.e:148-150 (a 12-field `records` tuple, its type repeated at 158, 242, 280). The siblings BIB_COMMENTARY_SECTION and BIB_COMMENTARY_CLAIM are classes with invariants; a tuple holds none, so "a section has a heading and a body" is checked only in the builder (line 192).
**Suggested Action:** BIB_FRAMEWORK_SECTION, BIB_FRAMEWORK_USE (using Finding 7's range), BIB_FRAMEWORK_SIDECAR.
**Effort:** 3 small classes.

### Finding 11: Schema object created in loops and postconditions
**Priority:** LOW  **Category:** A5 (timing)
**Evidence:** `create {BIB_FRAMEWORK_SCHEMA}` at src/pack/bib_framework_pack.e:74 (twice per iteration of a postcondition), 125 (per alias row), 142 (per framework row); src/pack/bib_framework.e:26, 28; src/pack/bib_framework_spelling.e:26. The class has no state (src/pack/bib_framework_schema.e:26-99).
**Suggested Action:** a once `schema` in the pack (or a tier_rank on BIB_FRAMEWORK); hoist in the postcondition.
**Effort:** 5 sites.

### Finding 12: Spellings carried two ways
**Priority:** LOW  **Category:** A5
**Evidence:** BIB_FRAMEWORK_NAMES.make takes tuples (src/pack/bib_framework_names.e:26-36); make_from_spellings takes BIB_LIST_RESULT [BIB_FRAMEWORK_SPELLING] and copies each into a tuple (38-49). The builder builds tuples (build/bib_framework_builder.e:288-293); the pack builds BIB_FRAMEWORK_SPELLING objects (src/pack/bib_framework_pack.e:126). BIB_FRAMEWORK_SPELLING.provenance is never read by BIB_FRAMEWORK_NAMES.
**Suggested Action:** one element type and one constructor over ITERABLE [BIB_FRAMEWORK_SPELLING].
**Effort:** 1 constructor, 2 callers.

### Finding 13: BIB_LIST_RESULT is not ITERABLE
**Priority:** LOW  **Category:** M1
**Evidence:** src/provenance/bib_list_result.e takes ITERABLE inputs (line 23) but offers only item (i) and count (57); no new_cursor. Callers copy by index: gui_app/bib_gui_app.e:3970-3973; src/pack/bib_framework_pack.e:73-74 and 134 (postconditions); src/pack/bib_commentary_pack.e:110.
**Suggested Action:** inherit ITERABLE [G] with new_cursor over `items`.
**Effort:** 1 feature.

### Finding 14: Small drift, tokens and contract gaps
**Priority:** LOW  **Category:** T1/D1
**Evidence:**
- `is_word_character` is defined twice with different meaning: src/pack/bib_framework_names.e:104-108 (letter or digit) and cli/bib_reference_linker.e:420-424 (letter, digit or period). linked asks the linker's at line 238, then match_at its own at bib_framework_names.e:68. Correct today; the shared name invites a wrong merge. Rename the linker's `is_book_character`.
- `framework_names_cache` (gui_app/bib_gui_app.e:3954-3962) is assigned and never cleared, while `framework_pack` (3934-3941) is recomputed each call; after a re-attach the spellings come from the old pack.
- gui_app/bib_gui_app.e:4151-4156: the "(Also the Frameworks tab's links...)" lines sit before the original description of on_commentary_link, so it reads out of order; a framework: target also falls through to target_place (4162) after show_framework rather than taking an else (harmless today because that parse returns Void for the prefix).
- Contract gaps: read_sidecar, write_framework, write_uses (build/bib_framework_builder.e:152, 242, 275) have no require or ensure (for example write_uses could ensure `last_error = Void implies use_count >= old use_count`); link_card and framework_card (gui_app/bib_gui_app.e:3779, 4072) state nothing about their result.
**Effort:** 4 small edits.

## Checked, no separate finding
- build_app/bib_build_app.e --frameworks branch (49-72): a third arm of the same if-chain repeating the "print failed, set l_failed" idiom (58-62, 85-89, 105-109); sidecars_in is called twice per arm (53 and 57; commentary 77 and 81), rescanning the folder. Fold into Finding 1.
- cli/bib_reference_linker.e framework branch (234-243): scan order is right and the postcondition nothing_lost (265) covers it.
- src/pack/bib_framework_schema.e: `Pack_file_name` (31) and `Schema_version` (36) are referenced nowhere except as parallel copies of BIB_COMMENTARY_SCHEMA's (33, 38); Schema_statements repeats `PRAGMA user_version = 1` as a literal (98). Moves with Finding 1 (the shared ancestor owns the version pragma).

## Recommended Order

1. Findings 4 and 3 first (live defects, small, no restructuring).
2. Finding 2 (reader ancestor), which carries the Finding 3 fix and enables Finding 5.
3. Finding 1 (builder ancestors, side-by-side MI) before any third pack is built.
4. Findings 7, 6, then 9 (window: range value, card helper, then the panel).
5. Findings 8, 5 and 10-14 as cleanup in any order.
