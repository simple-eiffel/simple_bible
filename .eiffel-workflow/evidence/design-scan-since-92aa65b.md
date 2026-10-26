# Design Scan (diff mode): simple_bible since 92aa65b
# Date: 2026-10-26
# Subjects: src/concordance/bib_conc_pack.e, src/data/bib_source_set.e, testing/conc_fixture.e (new), testing/test_concordance.e, testing/test_source_set.e, testing/test_app.e, .eiffel-workflow/research/17-CONC-PACK-SCHEMA-v1.md
# Read-only: nothing compiled, no source edited. Compared against all of src/ and testing/.
# Not verified: the fixture's CREATE statements against the real conc.db (the file is not in the repository; the fixture header says "read 2026-10-26").

## Summary

| Category | Findings | High | Medium | Low |
|---|---|---|---|---|
| Abstraction / duplication | 3 | 1 | 1 | 1 |
| Cache coherence / contracts | 8 | 1 | 4 | 3 |
| Fixture vs spec | 4 | 0 | 2 | 2 |
| **Total** | **15** | **2** | **7** | **6** |

## Findings

| # | Pri | Where | Finding |
|---|---|---|---|
| 1 | HIGH | src/concordance/bib_conc_pack.e:50-61, 94-131 | `is_available` compares only the path; a same-path re-attach keeps the stale cache |
| 2 | HIGH | src/concordance/bib_conc_pack.e:311-319 vs src/data/bib_source_set.e:233-242 | `database_message` is a second copy of `sqlite_message` (D1: contracts already diverged) |
| 3 | MED | src/concordance/bib_conc_pack.e:289-298 | `read_pack_facts` ignores query errors; a pack can be accepted with empty facts |
| 4 | MED | src/concordance/bib_conc_pack.e:94-131, 262-266 | `check_pack` checks tables only; research/17 lists no columns, so "agree on every column" cannot be shown |
| 5 | MED | testing/conc_fixture.e:133-134 vs tasks.md Task 5 | fixture rows leave `token.after/stem/sense/morph/pos_tag` NULL; no KJV/STEP corpora; one work |
| 6 | MED | testing/test_source_set.e:170-188 vs testing/conc_fixture.e:57-79 | `delete_file` and `make_database`/`build_main` duplicated |
| 7 | MED | src/concordance/bib_conc_pack.e (whole class) | no class invariant; the new state has cheap O(1) laws |
| 8 | MED | testing/test_concordance.e:130-153 | no test for absent layers (the reason `has_layer` exists) or for a same-path re-attach |
| 9 | LOW | src/concordance/bib_conc_pack.e:72-87 | layer names and corpus codes are string literals in `has_layer` |
| 10 | LOW | src/concordance/bib_conc_pack.e:262-266 | `Required_tables` is a public once ARRAY (mutable shared state) |
| 11 | LOW | src/data/bib_source_set.e:215-232 | rescue catches every exception; comment says "never control flow"; failure detail lost |
| 12 | LOW | src/concordance/bib_conc_pack.e:109-126 | dead `else` of `attached sources.database` would break `reason_when_refused` |
| 13 | LOW | testing/conc_fixture.e:31-55 | `build_variant` accepts an unknown `a_omitted_table` |
| 14 | LOW | src/data/bib_source_set.e:113, 32-33, 193-194 | redundant local; state reset duplicated between `make` and `close` |
| 15 | LOW | src/concordance/bib_conc_pack.e:292-296, testing/conc_fixture.e:141 | SQL by concatenation: safe today; one place should own the prefix |

## Detailed findings

### 1. HIGH - Stale cache can answer after a re-attach (cache coherence)
**Evidence:** `is_available` (src/concordance/bib_conc_pack.e:50-61) is true when `is_pack_valid` and the path now attached as "conc" `same_string` the `validated_path` recorded at line 125. The facts (`corpus_codes`, `has_meanings`, `edition_label_cache`, lines 270-277) are filled only inside `check_pack`.
**Answer to the question asked:** with a DIFFERENT path the guard works (`test_reattached_pack_needs_a_new_check`, testing/test_concordance.e:211-231, covers exactly that). With the SAME path it does not. A `detach` then `attach` of a file that was rebuilt or replaced in place (the conc.db to conc_dist.db swap by an update), or `sources.close` followed by `open_core` and `attach` of the same path (which Task 7's reopen will do), leaves `is_available` True, and `has_corpus`, `has_layer` and `edition_label` answer from the old file. The FR-164 gate exists to check each attachment once; this lets an unchecked attachment through. `is_available` is the precondition of every page query, so the stale answer reaches Task 5's SQL.
**Suggested fix:** give BIB_SOURCE_SET an O(1) attach serial (`attach_serial: INTEGER`, incremented in `attach` on success and in `close`; postcondition `attach_serial = old attach_serial + 1`). `check_pack` records it in `validated_serial`; `is_available` compares serial AND path. Add the same-path test (detach, rebuild the file, attach, assert not available until checked). No SQL; stays O(1).
**Effort:** 1 attribute and 2 contracts in BIB_SOURCE_SET, 1 attribute and 2 lines in BIB_CONC_PACK, 1 test.

### 2. HIGH - `database_message` is the second implementor of `sqlite_message` (duplicate body, drifted contract)
**Evidence:**
- src/data/bib_source_set.e:233-242 `sqlite_message (a_db; a_fallback: READABLE_STRING_GENERAL): STRING_32`: `if attached a_db.last_error_message as al_message and then not al_message.is_empty then Result := al_message.twin else Result := a_fallback.to_string_32`, with `ensure not_empty`.
- src/concordance/bib_conc_pack.e:311-319 `database_message (a_db): STRING_32`: the same body; the fallback is `pack_path` instead of a parameter; NO postcondition (D1: the copy dropped `not_empty`).
**Answer:** yes, this is now a real second implementor (two classes, identical logic, one parameter apart), so the fleet rule is met. Task 5 will need a third (query failures in `place_page` and the others), so waiting costs more.
**Suggested fix (multiple inheritance, side by side):** an effective helper ancestor `BIB_SQLITE_REPORTING` in src/data/ holding `sqlite_message (a_db, a_fallback)` with its contract, inherited by BIB_SOURCE_SET and BIB_CONC_PACK (`feature {NONE}`). `database_message (a_db)` is then deleted and callers pass `pack_path`. Alternative: a creation procedure on BIB_ERROR taking the database. Ask simple_sql for a `last_error_text_or (fallback)` only if a third library wants it (fleet rule: fill gaps in simple_*).
**Effort:** 1 feature moved, 1 deleted, 2 inherit clauses.

### 3. MEDIUM - `read_pack_facts` never checks for a failed query
**Evidence:** src/concordance/bib_conc_pack.e:289-298 runs three queries and never tests `a_db.has_error`. A failed `SELECT code FROM conc.corpus` leaves `corpus_codes` empty; `has_meanings` false on error looks like "no dictionaries"; only an empty edition label is caught (lines 121-122), by accident. The pack is then accepted with `has_corpus` false for every corpus.
**Suggested fix:** after the three queries test `a_db.has_error` and set `pack_error` (Database_problem, `database_message`) instead of accepting; add the postcondition `is_pack_valid implies not corpus_codes.is_empty`.

### 4. MEDIUM - Tables are checked, columns are not; research/17 lists no columns the engine reads
**Evidence:** research/17 "Tables the engine reads" names 12 tables. They agree exactly with `Required_tables` (src/concordance/bib_conc_pack.e:262-266) and with `schema` in testing/conc_fixture.e:106-122 (12 CREATEs, same names). The v1 additions it lists (user_version, token.translit, lemma_corpus_count, lemma_english, meta edition_label) are all in the fixture. But the document gives no column list for the existing tables ("conc.db's own definitions ... read from the file" is a claim, not a list), so the only written column definitions are the fixture's SQL. `check_pack` uses `table_exists_in` only, so a pack whose `token` lacks `translit`, or whose `lemma_corpus_count` lacks `n`, is accepted.
**Suggested fix:** add a "Columns the engine reads" table to research/17 (table, column, read by feature); make `Required_tables` a map from table to columns and check with simple_sql's `SIMPLE_SQL_TABLE_INFO` (a collaborator of SIMPLE_SQL_SCHEMA). Generate the fixture against the same list. Do it before Task 5 so the SQL, the check and the fixture agree.

### 5. MEDIUM - Fixture rows omit token columns Task 5 will read
**Evidence:** the `token` CREATE (testing/conc_fixture.e:114) has `after, search, pos_tag, morph, stem, sense, translit`, so the columns exist, but both token INSERTs (lines 133-134) set only `token_id, corpus_id, unit_id, pos, surface, language, lemma_id, lemma_basis, translit`. Left NULL: `after`, `search`, `pos_tag`, `morph`, `stem`, `sense`. BIB_PLACE_ROW (src/concordance/bib_place_row.e:55-58) has `meaning`, `stem`, `bsb`, `kjv`, `step`; tasks.md Task 5 ports the `place_page` and `verse_words` SQL, so `stem` and `sense` (the place row's meaning and stem) and `after` (verse text spacing) will be read. With NULLs a Task 5 test passes whatever the SQL does with those columns, or crashes on a NULL string.
Also: `corpus` holds WLC-MACULA, LXX-RAHLFS, ENG-BSB only (line 128), with one `link` row (line 135) and one `work` (Genesis), so the `kjv` and `step` columns of the place row and the one-row-per-book grouping of `english_rows` cannot be tested. `lemma_english` has no book column (research/17), so BIB_ENGLISH_ROW's `book_id` must come from `link` and `unit`.
**Suggested fix:** before Task 5, give token 1 `stem`, `sense`, `morph`, `pos_tag`; give English tokens `after`; add ENG-KJV and ENG-STEP corpora with one link each; add a second work (EXO) with one English link. Update the file header's token-column note.

### 6. MEDIUM - Duplicated test helpers
**Evidence:** `delete_file`: testing/test_source_set.e:182-190 and testing/conc_fixture.e:70-79, identical bodies. `make_database (a_name)` (test_source_set.e:170-180: `CREATE TABLE t (id INTEGER PRIMARY KEY)` plus one insert) and `CONC_FIXTURE.build_main` (conc_fixture.e:57-68: the same table, no insert) are the same stand-in. testing/test_concordance.e already calls the fixture's `delete_file` (lines 110-112, 282-285), so the fixture's public `delete_file` is a shared file utility sitting in a "Building" group of a fixture.
**Suggested fix:** a small effective class `TEST_FILES` (testing/) with `delete_file` and `build_stand_in (path, with_row)`, inherited side by side by TEST_SOURCE_SET, TEST_CONCORDANCE and CONC_FIXTURE; delete both copies. Three users, so the fleet rule is met.

### 7. MEDIUM - BIB_CONC_PACK has no invariant; the new state has O(1) laws
**Evidence:** no `invariant` clause in src/concordance/bib_conc_pack.e (grep). New state: `pack_error`, `corpus_codes`, `has_meanings`, `edition_label_cache`, `validated_path`.
**Suggested fix (all O(1), no SQL, no list walks):** `valid_has_path: is_pack_valid implies validated_path /= Void`; `valid_has_no_error: is_pack_valid implies pack_error = Void`; `label_when_valid: is_pack_valid implies not edition_label_cache.is_empty`; `refused_has_empty_label: not is_pack_valid implies edition_label_cache.is_empty` (the clearing is at lines 107-108). Do NOT put a corpus walk in it. For BIB_SOURCE_SET: `closed_state_clear: not is_open implies core_path.is_empty` (covers the two new postconditions, src/data/bib_source_set.e:199-200, for every command). `make` (bib_conc_pack.e:27-30) should also ensure `pack_error = Void`.

### 8. MEDIUM - Test gaps for what the new code exists to do
**Evidence:** `test_pack_accepts_the_fixture` (testing/test_concordance.e:130-153) asserts every layer present. No pack lacks `lex_sense` rows or an LXX corpus, so `has_layer ("dictionaries")` false and `has_layer ("lxx")` false (the conc_dist.db case) are untested. `test_pack_refuses_a_file_that_is_not_a_database` (about lines 177-202) accepts either outcome (refused at attach, or at the check), so neither branch is pinned. There is no same-path re-attach test (finding 1), and no test that a second `check_pack` clears the first one's cache.
**Suggested fix:** add `build_variant` options (no LXX corpus, no `lex_sense` rows), a test for each, and pin the not-a-database test to the outcome actually observed.

### 9. LOW - Magic strings in `has_layer`
**Evidence:** src/concordance/bib_conc_pack.e:78-83 ("lxx", "bsb", "dictionaries", "LXX-", "ENG-BSB"); the postcondition (line 86) repeats the three layer names. No other class in src/ uses them (grep), so no drift yet; Task 5 will name corpora.
**Suggested fix:** constants `Layer_lxx`, `Layer_bsb`, `Layer_dictionaries`, `Corpus_bsb`, `Lxx_prefix` in the Constants group, and an `is_known_layer` query. Note the asymmetry: lxx is a prefix match, bsb an exact code.

### 10. LOW - `Required_tables` is a public mutable once
**Evidence:** src/concordance/bib_conc_pack.e:262-266, `ARRAY [STRING_8]` once, exported to ANY; a client could `put` into it and change every pack check. **Fix:** move to `feature {NONE}`, or return a fresh ARRAY from a function.

### 11. LOW - `read_only_connection` rescue is broader than its comment
**Evidence:** src/data/bib_source_set.e:215-232. `rescue ... retry` catches every exception, including a precondition or assertion violation inside `make_read_only`, and turns it into Void; the comment (lines 216-219) calls an open failure "an answer, never control flow" while the code is rescue/retry. The caller's message (line 125, "SQLite could not open the content database.", path only) loses SQLite's words, against the FR-138 rule used elsewhere in this class.
**Suggested fix:** read `{EXCEPTION_MANAGER}.last_exception` in the rescue, keep its description for the BIB_ERROR details, and reword the comment. Ask simple_sql (fleet rule: fill gaps there) for a non-raising open (`make_read_only` plus `has_error`) so this rescue can go. In `test_open_core_folder_reports` (testing/test_source_set.e:82-99) the folder is deleted only after the assertions; if one fails it leaks into the next run.

### 12. LOW - Dead branch would violate the postcondition
**Evidence:** if `sources.database` were Void (src/concordance/bib_conc_pack.e:109), `check_pack` leaves `is_pack_valid` False and `pack_error` Void, violating its own `reason_when_refused`. Unreachable today (`is_attached` implies open implies a database, by BIB_SOURCE_SET's invariant, src/data/bib_source_set.e:126-129), but the compiler cannot see it. **Fix:** `check attached sources.database as al_db then ... end`, or give the `else` an error.

### 13. LOW - `build_variant` accepts a typo
**Evidence:** testing/conc_fixture.e:31-55; `a_omitted_table` is compared with `same_string`, so an unknown name builds the full pack and a refusal test then fails far from the cause. **Fix:** `require omitted_known: a_omitted_table.is_empty or else across schema as ic some ic.table.same_string (a_omitted_table) end` and `version_non_negative`.

### 14. LOW - Small cleanups in BIB_SOURCE_SET
**Evidence:** `l_db := al_db` (src/data/bib_source_set.e:113) is redundant (use `al_db`, drop the local); `create core_path.make_empty` and `create sqlite_version.make_empty` appear in `make` (lines 32-33) and `close` (lines 193-194): a `{NONE}` `clear_open_state` would hold both.

### 15. LOW - SQL by concatenation: safe today; one place should own the prefix
**Evidence (the question asked):** src/concordance/bib_conc_pack.e:292, 295, 296 concatenate `Pack_alias` (the constant "conc", line 255) into SQL. Identifiers cannot be bound, and "conc" satisfies `is_valid_alias`, so this is safe. `check_pack` passes table names from the constant `Required_tables` to `table_exists_in`, which binds the name (`query_with_args`, simple_sql_schema.e:129). No caller-supplied text reaches SQL in these classes. The one spliced literal is the fixture's `Edition_label` (testing/conc_fixture.e:141), a constant without a quote.
**Task 5 note:** the acceptance criterion "parameterized SQL only" must mean values bound, identifiers from constants. Keep every `conc.` prefix in one feature (`pack_table (a_name)` or a `Pack_prefix` constant) so an alias change cannot miss a statement, and precondition any identifier parameter with `database.is_valid_schema_name`. For the fixture, bind the label (`execute_with_args`) or reject an apostrophe in a precondition.

## Checked and found fine
- **CQS:** `check_pack` is a command; `pack_error`, `has_corpus`, `has_layer`, `edition_label`, `first_missing_table`, `pack_path`, `database_message` are queries without side effects; `read_pack_facts` mutates but is a `{NONE}` procedure. `edition_label` returns a `twin`, so callers cannot alias the cache.
- **Contracts on new public features:** `has_corpus` and `has_layer` require `is_available`; `has_layer` has a real postcondition (`unknown_layer_absent`); `check_pack` ensures `reason_when_refused` and `no_reason_when_accepted`. `pack_error` is a plain attribute with no contract; its law belongs in the invariant (finding 7).
- **BIB_SOURCE_SET.close** clears `core_path` and `sqlite_version`, with matching postconditions and a test (`test_close_forgets_the_connection`). `has_error` in simple_sql reflects the latest operation, so an earlier error cannot make `check_pack` refuse a good pack.
- **Tables:** research/17's table list, `Required_tables` and the fixture `schema` agree (12 names). The shapes the review named are present: empty-surface Hebrew token (testing/conc_fixture.e:133, token 2), English `computed:spacy-lemma` (token 3), Strong's rows (line 136), license and ship_class (line 128), 251 article places against `Max_page_size` 200 (checked at testing/test_concordance.e:104).
- **Fixture columns:** every column of the CREATE statements is carried, none dropped from the schema (finding 5 concerns row values, not columns). Faithfulness to the real conc.db could not be verified (file not in the repository).

## Recommended order
1. Finding 1 (stale cache) with its test (finding 8, same-path case), before Task 5 relies on `is_available`.
2. Finding 2 together with finding 3, so the shared reporting feature serves the Task 5 query errors from the start.
3. Findings 4 and 5 (column list in research/17, fixture rows) as one step ahead of Task 5.
4. Findings 6, 7, 8.
5. LOW items with the next edit of each file.

## Status (2026-10-26, refactor/scan-27)

Fixed: HIGH 1 (BIB_SOURCE_SET.attachment_serial; the pack compares the serial it checked, so a same-path rebuild is checked again; test failed before), HIGH 2 (BIB_SQLITE_REPORTING mixin; both copies gone), MEDIUM read_pack_facts errors (a refused query refuses the pack; test failed before), MEDIUM duplicated test helpers (TEST_SOURCE_SET uses CONC_FIXTURE). Open for Task 5: fixture columns after, stem, sense and a KJV or STEP corpus; tests for packs without LXX or lex_sense; a class invariant for BIB_CONC_PACK; research/17 columns.
