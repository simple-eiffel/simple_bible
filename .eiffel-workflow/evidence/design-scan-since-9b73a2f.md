# Design Scan (diff mode): simple_bible, since 9b73a2f
# Date: 2026-10-26
# Mode: read-only; nothing compiled, nothing edited, no tests run. Every finding is from reading the code.
# Subjects: Task 6 (bib_word_lookup.e, bib_word_view.e, BIB_CONC_PACK.lookup_method) and Task 7a
#   (bib_content_source.e, bib_data_source.e, bib_source_set.e, simple_bible.e, research/18,
#   testing/test_facade_open.e, CONC_FIXTURE.build_content), each compared against all of src/.
# Diff: 13 files, 766 insertions, 57 deletions (git diff 9b73a2f..HEAD).

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift / contracts | 17 | 4 | 7 | 6 |
| MI | 1 (inside #4) | 0 | 0 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **17** | **4** | **7** | **6** |

## Findings

| # | Pri | Cat | Where | Finding |
|---|-----|-----|-------|---------|
| 1 | HIGH | D1/contract | src/simple_bible.e:471-487, 165-175 | `is_conc_file` compares path spellings; a relative/absolute or `..` mismatch counts conc.db as a generic pack and `open` refuses |
| 2 | HIGH | contract | src/simple_bible.e:90-95, 113-114 | `pack_count` re-scans the folder up to 5 times per `open`; postconditions re-scan too and can fail on a folder change; `packs_attached` is masked by the conc slot |
| 3 | HIGH | A5 | src/concordance/bib_word_lookup.e:102-109, src/concordance/bib_conc_pack.e:633-641 | `cite` is a byte-for-byte copy (body and contract) in two classes |
| 4 | HIGH | A5/A6/M2 | src/data/bib_content_source.e:162-170, src/concordance/bib_conc_pack.e:444-452 | `first_missing_table` and the "version + required tables" check duplicated; a third copy is due in Task 7b |
| 5 | MEDIUM | D1 | src/simple_bible.e:76-77, 99-103, 146-156; src/study/bib_related_passages.e:19-22 | Optional-content facts stored twice (attributes and functions); they diverge after `close`; `related` captures `has_ai_data` once |
| 6 | MEDIUM | contract | src/simple_bible.e:101-104; src/author/bib_author_library.e:23-31 | `author_source` is created but never opened; `author_library` hands out a closed source |
| 7 | MEDIUM | A1/A4 | src/concordance/bib_word_lookup.e:79-86 | The word view's method record carries pseudo-queries, not SQL; the pack's convention (NFR-006) is broken |
| 8 | MEDIUM | cost | src/data/bib_content_source.e:172-211 | Provenance check runs `table_info` (about four statements) twice per table; FTS5 detection by substring |
| 9 | MEDIUM | contract | src/data/bib_content_source.e:213-232 | Optional-table queries ignore SQLite errors; a malformed optional table reads as "absent" |
| 10 | MEDIUM | contract | src/data/bib_content_source.e:86-90, src/data/bib_data_source.e:93-99 | `open_on` precondition (`a_set.is_open or main`) contradicts `open_core`'s `not_open` |
| 11 | MEDIUM | tests | testing/test_facade_open.e | No test for close + reopen, failed open then good open, more than 9 packs, vector tables, FTS5, path spellings |
| 12 | LOW | state | src/data/bib_content_source.e:86-126 | `open_on` resets only `last_error` and `has_required_tables`; other recorded facts go stale on a retry |
| 13 | LOW | state | src/simple_bible.e:63-131 | `close` and a failed `open` leave `database_edition`, `has_ai_data`, `has_author_library`, `author_source`, `conc_error` stale |
| 14 | LOW | T1 | src/concordance/bib_word_lookup.e:79 | `200` typed into `View_query` beside `pack.Max_page_size` |
| 15 | LOW | G | src/data/bib_content_source.e:142-152, src/concordance/bib_conc_pack.e:427-431, src/concordance/bib_word_view.e:143-147 | Public `once` arrays are shared and mutable; plain `once` under SCOOP is unverified |
| 16 | LOW | D1 | src/data/bib_source_set.e:125 vs src/data/bib_data_source.e:69 | `open_core` tests `exists` (file or folder); everything else tests `is_file` |
| 17 | LOW | fleet | testing/conc_fixture.e:54,107; testing/test_concordance.e:252; testing/test_source_set.e:70,87,126; testing/source_scan.e:18,37,52,120 | ISE file and directory classes remain in testing; src/ is clean |

Doc drift (folded into the table above as part of #12, listed in the details): research/18 omits the vector step.

## Detailed findings

### 1. HIGH. `is_conc_file` compares spellings, not files
src/simple_bible.e:471-487. It builds `pack_folder + "\" + name`, flips `/` to `\`, and compares case-insensitively with `conc_path`.
It fails when:
- the folder is relative and `conc_path` absolute (or the reverse);
- either holds `.\` or `..`;
- either holds a doubled separator (`C:\p\\`: the `ends_with` test passes, so nothing collapses it);
- a UNC prefix differs.
`pack_count` (165-175) then counts conc.db as a generic pack. Until Task 7b, `open` refuses with "Generic private packs are not read yet" (line 93-96). That breaks Larry's 2026-10-26 policy that conc.db never fails `open`. After 7b it will try to attach conc.db twice (alias collision) or eat a pack slot.
The only test, `test_pack_folder_scan_skips_the_concordance` (testing/test_facade_open.e:125-137), builds both paths from the same `Folder` constant, so identical spelling is the only case tested.
Suggested fix: compare normalized absolute paths. `SIMPLE_PATH.absolute` then `.normalize` exist (simple_file/src/simple_path.e:293, 331); compute the conc path once per scan, not per file. Or compare file names, and check the folder against `parent` of `conc_path` the same way. Add tests with `conc_path` absolute and `pack_folder` relative, and with `..`.

### 2. HIGH. `pack_count` is a filesystem scan used as a constant
- src/simple_bible.e:90, 91, 93, 95: up to 4 scans in the refusal branches. Each is a full directory listing, and `files_with_extension` lowercases each name twice.
- Postconditions 113 and 114 scan again.
- If the folder changes between the decision (line 90) and the postcondition (line 114), `too_many_packs` fails. In an F_code test build, contracts are baked in, so an outside file write becomes a contract crash. The message text (line 91) can also disagree with the decision.
- `packs_attached` (113): `sources.attached_count` includes the conc slot. Three packs found and two attached plus conc still passes. The `or last_error /= Void` branch is vacuous: the invariant (503) already says `is_open` implies `last_error = Void`. With `pack_count > 0` refused today, the postcondition checks nothing; it will mask a short attach once 7b lands.
Suggested fix: count once into a local `l_packs`; keep it as a recorded fact (`packs_found_at_open: INTEGER`, set by `open`); phrase the postconditions on that fact. `packs_attached` becomes `sources.attached_count - (1 if conc_pack.is_attached) >= packs_found_at_open`. Keep `pack_count` as the public scan.

### 3. HIGH. Duplicate `cite`
src/concordance/bib_word_lookup.e:102-109 and src/concordance/bib_conc_pack.e:633-641: same name, same signature, same body, same postcondition. It is used 3 times in BIB_WORD_LOOKUP (lines 50, 51, 53) and 4 times in BIB_CONC_PACK (204, 213, 324, 331). `BIB_ENGINE_RESULT.set_success` (src/provenance/bib_engine_result.e:25-31) and `BIB_GUIDE` (src/study/bib_guide.e:36-42) also copy a citation list into a result by hand.
Two defects ride along:
- `ic = a_provenance` compares by reference. `first_provenance` (conc_pack.e:546-554) builds a new object on every call, so its fallback is never de-duplicated.
- Neither class can reach the other's copy; the copy was made because `cite` is `{NONE}`.
Second implementor: real (two live copies, plus the hand-copied loops).
Suggested fix, in order of preference:
1. Make `BIB_ENGINE_RESULT.set_success` drop duplicate citations (by `same_key` / identity). It already owns `citations`, and every answer goes through it. Then delete both `cite`s and the `cite` calls become plain `extend`s.
2. If a pre-collection helper is wanted, a stateless mixin inherited beside the real parent, as BIB_SQLITE_REPORTING already is (see its note: "the second copy had appeared"): `BIB_CITING` with one `cite`, inherited by BIB_CONC_PACK and BIB_WORD_LOOKUP side by side.

### 4. HIGH. `first_missing_table` and the schema walk, twice, a third coming
src/data/bib_content_source.e:162-170 and src/concordance/bib_conc_pack.e:444-452: the same `across Required_tables ... until Result /= Void` loop; only `table_exists (ic)` versus `table_exists_in (Pack_alias, ic)` differs (`table_exists_in ("main", ic)` would serve both). Both also hold a `Required_tables` once array (content_source.e:142, conc_pack.e:427) and both check `user_version` first.
The provenance walk (content_source.e:172-211, tables → `table_info` → NOT NULL column → foreign key) is the same walk the Task 7b stub names for private packs: src/pack/bib_private_source.e:62-67 ("PRAGMA table_info over the pack's tables", voice column NOT NULL). That makes a real second implementor of `tables_lacking_column`, not a hypothetical one.
Suggested fix (do it with 7b, not before): one stateless mixin `BIB_SCHEMA_PROBE`, inherited side by side with BIB_DATA_SOURCE and BIB_CONC_PACK (as BIB_CONC_PACK already inherits BIB_SQLITE_REPORTING), with `first_missing_table (schema, alias, required)` and `tables_lacking_column (db, alias, column, referenced_table, exempt)`. The two `Required_tables` stay where they are, as data.

### 5. MEDIUM. Optional-content facts stored twice and they diverge
`has_ai_data` / `has_author_library` (attributes, simple_bible.e:76-77, 99-103) and `content_has_ai_rows` / `content_has_author_rows` (functions, 146-156) state the same fact. The postcondition `optional_content_reflects_presence` (112) exists only to police the duplication. After `close` (119-131) the attributes stay True while the functions answer False.
Live consequence: `related` (line 332-337) is `once ("OBJECT")` and captures `has_ai_data` when first called (BIB_RELATED_PASSAGES.make, src/study/bib_related_passages.e:19-22). Open, use `related`, close, rebuild content.db, reopen: `related` keeps the old flag.
Suggested fix: keep one source. Make `has_ai_data` and `has_author_library` functions over `content`, or reset them in `close`; and give `related` the facade (or a query) instead of a captured BOOLEAN.

### 6. MEDIUM. `author_source` is built but never opened
simple_bible.e:101-104 creates `BIB_AUTHOR_LIBRARY.make (config.core_path)`. `make` only records the path (bib_author_library.e:23-31); nothing calls `open_on`; `author_library` (353-363) requires `open: is_open` (the facade) and returns a source with `is_open = False`, whose own queries require `is_open`. It also names alias "rix" and a separate `Rix_schema_version`, while research/18 and the 7a doc place the author library inside content.db (`docs` table). The invariant `author_library_when_flagged` only checks non-Void.
Suggested fix: decide the shape before 7b: either a view over `main` (no alias, no second version) opened by the facade, or add `ensure Result.is_open` to `author_library` and open it in `open`.

### 7. MEDIUM. Word-view method record holds no SQL
bib_word_lookup.e:79 `View_query` = "word_entry (lemma); place_total (lemma, corpus); place_page (lemma, corpus, 0, 200)". Every other pack answer records its real SQL in `method` (conc_pack.e:196, 237, 259, 312, 365; `place_result` 581-614), which is what Show method (FR-032) and `rerun` rely on. The view is the one answer whose method cannot be re-run from its text. `lookup_method` (conc_pack.e:406-416) is also a one-line wrapper over `method`, exported to a single class.
Suggested fix: build the view's `method` from the three sub-answers' methods (their SQL), or move the assembly into BIB_CONC_PACK as `word_view_parts` so `method` stays private and `lookup_method` and `cite` both go. If BIB_CONC_PACK (722 lines) should not grow, widen `method` itself to `{BIB_CONC_PACK, BIB_WORD_LOOKUP}` and drop the wrapper.

### 8. MEDIUM. Provenance check cost and FTS5 detection
content_source.e:172-211: `tables_lacking_provenance` calls `a_schema.table_info (ic)` for every table in the virtual-detection pass and again in `declares_provenance`. In simple_sql, `table_info` runs a `sqlite_master` query plus columns, indexes and foreign keys per call (simple_sql/src/simple_sql_schema.e:149-190, 404-475), so a 40-table file costs several hundred statements at open. Virtual-table detection is `sql.as_upper.has_substring ("CREATE VIRTUAL TABLE")`, which misses `CREATE  VIRTUAL TABLE` (two spaces) or a newline between the words.
The shadow-suffix list `_data _idx _content _docsize _config` is correct for FTS5 (checked against the FTS5 shadow-table set). It misses FTS4 (`_segments`, `_segdir`, `_stat`) and R-tree (`_node`, `_rowid`, `_parent`); research/18 only promises FTS5. `table_info` on a virtual table works while the module is loaded; if the linked SQLite lacks FTS5 it errors and leaves `has_error` set on the shared connection; unverified here.
Suggested fix: one statement using the pragma table functions, e.g. `PRAGMA table_list` (SQLite 3.37+, the library is 3.53.4) whose `type` column reads `virtual` and `shadow`, plus `pragma_table_info` / `pragma_foreign_key_list` joined per table, replaces the suffix list and the per-table walk. `Provenance_exempt` compares with `same_string` (case-sensitive) while SQLite names are case-insensitive; compare with `is_case_insensitive_equal`.

### 9. MEDIUM. Unchecked queries in `read_build_facts`
content_source.e:213-232. The `build_run`, `related_passage` and `docs` queries never test `a_db.has_error`. A `related_passage` table without `is_ai_made` yields 0 rows, reported as "no AI data"; a `build_run` without `built_at` yields an empty edition, reported as "names no build" instead of SQLite's own words (the fleet rule used elsewhere: FR-138, `sqlite_message`).
Suggested fix: after each query, `if a_db.has_error then` refuse with `Schema_mismatch` / `Database_problem` and `sqlite_message`, as `check_pack` does through `note_failure` (conc_pack.e:475-483).

### 10. MEDIUM. `open_on` precondition against `open_core`
bib_data_source.e:96 says `a_set.is_open or alias_name = "main"`. For content (main) the call then reaches `BIB_SOURCE_SET.open_core`, whose precondition is `not_open` (bib_source_set.e:117). Calling `content.open_on (open_set)` therefore fails inside `open_core`, blaming the callee. The deferred contract cannot say it, because attached sources need the set open.
Suggested fix: `set_state: (alias_name.same_string ("main")) = not a_set.is_open` in BIB_DATA_SOURCE.open_on (for main the set must be closed; for packs it must be open).

### 11. MEDIUM. Test gaps (the cases Larry named)
testing/test_facade_open.e has 10 tests (lines 20-156) with 8 `close` calls but no reopen. Missing:
- close then open again on the same facade, with conc_pack, word_lookup and a lookup in between (my read of the code says it works: `conc_pack` holds the shared `sources`, `is_available` compares `attachment_serial` against `validated_serial`, and `last_attach_serial` is never reset by `close`, bib_source_set.e:260; but nothing runs it);
- a refused open followed by a good open on the same object;
- 10 packs found (`Max_generic_packs`, the FR-138 branch at simple_bible.e:90-92);
- a `vector` table, `provenance_key` nullable or without a foreign key, an FTS5 table with shadows, an empty `build_run`;
- `conc_path` and `pack_folder` spelled differently (finding 1).
`CONC_FIXTURE.build_content` (conc_fixture.e:71-96) only builds the all-good file and the "no provenance column" file.

### 12. LOW. `open_on` leaves stale facts on a retry
bib_content_source.e:86-126 resets `last_error` and `has_required_tables`. `schema_version`, `sqlite_version`, `tables_without_provenance_column`, `has_vector_tables`, `database_edition`, `ai_rows`, `author_documents` keep earlier values when a later `open_on` is refused early (the precondition `not_open` allows a retry on the same object). SIMPLE_BIBLE always makes a fresh BIB_CONTENT_SOURCE, so this is reachable only by direct use. Fix: one `reset_facts` at the top.
research/18 drift: the "check (in this order)" table has six steps and no vector step, though the code refuses vectors after the `build_run` check (content_source.e:115) and the same document says so below. Add step 7.

### 13. LOW. Facade state after `close` and a failed `open`
simple_bible.e:63-131. `close` resets `core_schema_valid` only. `database_edition`, `has_ai_data`, `has_author_library`, `author_source`, `conc_error` stay. A failed `open` resets all but `database_edition`. The invariant holds; the facts are just not zeroed. Suggest a single `forget_open_state` called by `open` and `close`.
Also: `open_concordance` ignores `sources.last_error` after `sources.detach` (line 446). A refused detach leaves the conc slot used while `conc_error` is set.
Also: `open` nests five levels (lines 79-108) and repeats "create last_error ... close_after_refusal" three times; a `refuse (a_error)` helper would flatten it.

### 14. LOW. Literal 200
bib_word_lookup.e:79 repeats the page size as text; `pack.Max_page_size` (conc_pack.e:422) owns it and line 41 already uses it. Build `View_query` from the constant, or drop it (finding 7).

### 15. LOW. Shared mutable `once` arrays
`Required_tables` (content_source.e:142), `Provenance_exempt` (148), conc_pack.e:427 and `approved_order` (word_view.e:143) are public plain `once` functions returning an `ARRAY`. Any client can `put` into them, and under SCOOP a plain `once` is process-wide. The facade uses `once ("OBJECT")` for per-instance state. I did not verify how the compiler treats these under the SCOOP setting. Make the arrays `{NONE}`, or use the literal at the use site.

### 16. LOW. `exists` versus `is_file`
bib_source_set.e:125 and the contract at 240 use `exists` (true for a folder); `is_available` (bib_data_source.e:69), `open_concordance` (simple_bible.e:436) and the new tests use `is_file`. A folder named `content.db` reaches `read_only_connection` and fails with a Database_problem instead of "not found". Use `is_file` in both places.

### 17. LOW. Fleet rule: ISE file classes
src/ is clean: grep of RAW_FILE, PLAIN_TEXT_FILE, DIRECTORY, FILE_NAME, PATH in src/ finds nothing (the only file calls are `SIMPLE_FILE`, simple_bible.e:163, 436; bib_data_source.e:69; bib_source_set.e:125, 240). Remaining in testing/: testing/conc_fixture.e:54 (`RAW_FILE` in a postcondition) and 107 (`delete_file`), while the same class uses `SIMPLE_FILE` at line 95; testing/test_concordance.e:252 (`PLAIN_TEXT_FILE`); testing/test_source_set.e:70, 87, 126; testing/source_scan.e:18, 37, 52, 120 (`DIRECTORY`, `RAW_FILE`, `PLAIN_TEXT_FILE`). `SIMPLE_FILE` has `delete`, `read_text`, `write_text`, `lines`, `files`, `directories`. Note: simple_file's own body uses RAW_FILE and DIRECTORY; that is the library's job.

## Checked and found sound (no finding)
- `SIMPLE_BIBLE.open` postconditions on every path (read): invalid config, content missing, `open_on` refused (open_on closes the set), too many packs and pack refusal (`close_after_refusal` closes sources and content), success. `open_or_error`, `core_checked`, `optional_content_reflects_presence` and `conc_attached_or_reported` hold on each; `implies` is semi-strict so `conc_pack` is not touched when closed. `packs_attached` and `too_many_packs` are the weak/racy ones (finding 2).
- `BIB_CONTENT_SOURCE.open_on` postconditions: the refusal branch (line 122-125) clears `has_required_tables` and closes the set, so `open_or_error`, `tables_present` and `provenance_declared` hold.
- Close then open: `conc_pack`, `word_lookup` and the other `once ("OBJECT")` engines hold the same `sources` object, which `close` empties and `open` refills. `BIB_CONC_PACK.is_available` is False after close because `attachment_serial` is 0, and `open_concordance` calls `check_pack` again after a new attach (new serial). Stale `pack_error` can survive when `conc_path` is empty on the second open (cosmetic).
- Resource release on refusal: no connection or attachment is left open on any refusal path (the author source opens nothing).
- Invariants added (`counts_non_negative`, `provenance_count_non_negative`) are O(1). Pre-existing: `attached_count` (bib_source_set.e:52-58) builds an MML model in its postcondition and is called by the invariant `within_limit` (264), O(10) per check.
- CQS: `pack_count`, `is_conc_file`, `lookup_method`, `first_missing_table` are pure queries. BIB_WORD_LOOKUP.view is a query that mutates `last_rows` inside the pack (pre-existing pattern).
- SCOOP: no separate objects added; `make_from_separate` copies config; `content` is local to the facade.
- FTS5 shadow suffix list correct for FTS5; `table_info` on a virtual table works with the module loaded (finding 8 caveat).
- BIB_WORD_VIEW bodies satisfy their contracts as read (`present_names` is {NONE}; `is_in_approved_order` handles 0 and 1 present sections). `section_count` reports implemented sections (3 of 10), not sections "the pack can answer for"; a pack with dictionaries still returns `is_present ("dictionaries")` False. The class note says absence means "absent from the pack"; worth a one-line comment or an `is_implemented` split when the next section lands.

## Recommended order
1. Finding 1 (path comparison) with its test: a real way for `open` to refuse that Larry's policy forbids.
2. Finding 2 (count once, record it): removes a contract that can fail from the outside, and fixes the vacuous `packs_attached` before 7b relies on it.
3. Finding 5 and 6 (one source of truth for optional content; decide the author library's shape) before 7b adds more state.
4. Findings 3, 4, 7 together as one small refactor branch (citation dedupe in `set_success`; `BIB_SCHEMA_PROBE`; the word view's method), best done with 7b, when the third implementor exists.
5. Finding 9, 10, 11, then the LOWs.
Nothing is extracted without Larry's word.

## Status (2026-10-26, refactor/scan-29)

Fixed: HIGH 1 (is_conc_file compares canonical paths through SIMPLE_PATH.resolve; test with a relative folder and an absolute or dotted conc_path failed before), HIGH 2 (packs_found counted once per open; postconditions read it), HIGH 3 (BIB_CITATIONS mixin; the fallback provenance is made once per check). Deferred to Task 7b: HIGH 4 (BIB_SCHEMA_PROBE with BIB_PRIVATE_SOURCE as the third implementor). MEDIUMs and LOWs open; testing still uses ISE file classes (finding 17).
