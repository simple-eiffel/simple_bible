# Implementation Tasks: simple_bible, the concordance slice (personal edition)

*Phase 3, 2026-10-26. Inputs: `approach.md`, `synopsis.md` and `review/04 - VERDICT.md` (Phase 2, approved by Larry 2026-10-26), the contracts in `src/concordance/`, `src/data/bib_source_set.e`, `src/simple_bible.e`, `src/bib_config.e`. Scope: the personal edition of the concordance (D-021), engine and command line. The face (simple_widgets virtual grid) is a later plan; the rest of the engine (150 classes) gets its own review cycles first.*

**Rules for every task:** one Eiffel compile at a time, `ec.sh` modes only; each task ends at 0 errors and 0 warnings with the full test run pasted; every defect fixed gets a test that fails on the old code; timing is judged on the lean build inside `without_contracts`; no SQL outside `BIB_CONC_PACK` and `BIB_SOURCE_SET`; simple_* only (a gap goes into the simple_* library, with a before/after test there).

## Task 0: conc.db builder items (vault tooling, Python, private)

**Where:** the vault's `_Tools` (Python is allowed while it builds only the private pack: FR-162). Not in this repository.
**Schema note:** written in this repository as `research/17-CONC-PACK-SCHEMA-v1.md` (Task 2, 2026-10-26); the builder follows it.
**Items:** FR-165 `PRAGMA user_version = 1` (the pack's `Expected_user_version`); FR-162 `token.translit` (precomputed whole-word transliteration); per-corpus counts per headword and the English-at-a-glance summary per headword (two small tables); a one-page schema note (`conc pack v1`: tables, columns, keys) that Task 2's fixture copies.

### Acceptance Criteria
- [x] conc.db reports `user_version` 1 (read with `PRAGMA user_version` on the file itself)
- [x] `token.translit` exists and is non-empty for every original-language token that has a surface (A1: the 6,435 empty Hebrew surfaces stay empty)
- [x] The counts table sums to `lemma.n_tokens` per headword; the summary table has a row for every headword with English links
- [x] Done 2026-10-26 by the vault step `_Tools/build_conc_pack_v1.py` (last in the rebuild order; idempotent; undo steps in its docstring), tried on a copy first: 158,341 forms transliterated (the Greek numeral stigma by a fallback), 0 headwords whose counts differ, 40 seconds on the real file; the 17 deuterocanonical works have no bible.db book yet, so the verse lookup answers none for them

### Implementation Notes
Full rebuild order (research/14 section 4): build_conc_db, build_conc_english, conc_translit, build_conc_meaning, build_conc_seealso, build_conc_periods; the new items go at the end. Until this lands, the engine refuses the real conc.db (verdict condition 3; no bypass constant).

### Dependencies
None. Blocks Task 8 and any test against the real file.

---

## Task 1: BIB_SOURCE_SET opens and attaches for real

**Files:** `src/data/bib_source_set.e`
**Features:** `open_core`, `attach`, `detach`, `close`, `attached_count`, `attached_model`, `is_attached_alias`, `sqlite_version`

### Acceptance Criteria
- [x] `open_core` opens content.db with simple_sql `make_read_only`; `attach` uses `SIMPLE_SQL_DATABASE.attach_read_only` (FR-160)
- [x] A failing attach (a missing file, a file that is not a database) puts SQLite's own message in `last_error` (FR-138, ruling 3.1 `error_mapped`). Attach #11 never reaches SQLite: `attach` requires `attached_count < Max_attached`, and `open` reports too many packs (ruling 2.4, Task 7)
- [x] `detach` refused by SQLite (a statement still open on the pack) keeps the alias and reports it
- [x] A write into an attached pack is refused (test with a throwaway pack file)
- [x] Postconditions hold under the test run; compiles clean

### Implementation Notes
`Max_attached` = 10 (ruling 3.2: no override in eiffel_sqlite_2025). One connection per SCOOP processor (DR-019).

### Dependencies
None.

---

## Task 2: a synthetic conc pack fixture, built by the tests

**Files:** `testing/conc_fixture.e` (new), used by TEST_CONCORDANCE
**Features:** `build (a_path)`: writes a small conc-shaped database with simple_sql and stamps `user_version` 1

### Acceptance Criteria
- [x] Holds the shapes the verdict names: a Hebrew token with an empty surface (A1), an English token with basis `computed:spacy-lemma`, Greek and Hebrew tokens with basis `tagged:<source>`, a `lemma_xref` Strong's row, two corpora with `license` and `ship_class`, a lemma with more than 200 places (paging)
- [x] Generated at test time into a temporary file and deleted after; **no conc.db data is committed** (the personal data never enters the public repository)
- [x] A variant with `user_version` 0 and one missing a required table (refusal tests)

### Implementation Notes
Table and column names copy Task 0's schema note; where Task 0 is not done yet, copy today's conc.db schema (spike R2's column lists) plus the two planned tables, and reconcile when Task 0 lands.

### Dependencies
Task 0's schema note (soft).

---

## Task 3: BIB_CONC_PACK checks the pack once, at attach

**Files:** `src/concordance/bib_conc_pack.e`
**Features:** `check_pack`, `is_attached`, `is_available`, `has_corpus`, `has_layer`, `edition_label`

### Acceptance Criteria
- [x] `check_pack` reads `SIMPLE_SQL_SCHEMA.user_version_of (Pack_alias)` and `table_exists_in (Pack_alias, ...)` (simple_sql 09cb860) and sets `is_pack_valid` (FR-164, ruling 3.3)
- [x] The fixture opens; the `user_version` 0 variant and the missing-table variant are refused with a reason
- [x] `is_available` runs no SQL (it reads the cached `is_pack_valid`)
- [x] `edition_label` comes from the pack, never from engine code (FR-158)

### Dependencies
Tasks 1 and 2.

---

## Task 4: the value creators

**Files:** `src/concordance/bib_word_entry.e`, `bib_place_row.e`, `bib_english_row.e`, `bib_verse_word.e`
**Features:** `make` on each, `set_context` (BIB_PLACE_ROW), `has_door` (BIB_VERSE_WORD)

### Acceptance Criteria
- [x] Every field pinned by the postconditions (rulings 1.2, 1.3) holds on fixture rows
- [x] `test_verse_word_takes_real_hebrew_rows` and `test_verse_word_takes_english_computed_rows` move from skeletal to run, and pass
- [x] Provenance from `corpus.license` / `ship_class` on every value (NFR-007), built by the pack in Task 5 (`meaning_source` comes with the meanings, Task 6)

### Dependencies
Task 2.

---

## Task 5: the pack's queries

**Files:** `src/concordance/bib_conc_pack.e`
**Features:** `word_entry`, `headwords_for_strongs`, `place_total`, `place_page`, `place_page_after`, `english_rows`, `verse_words`

### Acceptance Criteria
- [x] Parameterized SQL only; joins by `lemma_id`, `token_id`, `unit_id`, never display strings (FR-024, V-56)
- [ ] Strong's appears only in `headwords_for_strongs` through `lemma_xref` (FR-153): the query is done and tested; the static test that greps the pack's signatures is still to write
- [x] `verse_words` maps stored `<kind>:<source>` to the kind (ruling 1.1)
- [x] `place_page` and `place_page_after` return the same rows as spike R1 for the same window (keyset after the first page)
- [x] No list is ever loaded whole (FR-159): every place query is a page of at most 200 rows, so no cursor is held open between calls
- [x] `place_total` reads the precomputed counts (Task 0) when present

### Implementation Notes
Port the SQL from `conc_pilot.py` (reference only, D-020). Each query gets a fixture test.

### Dependencies
Tasks 3 and 4.

---

## Task 6: the three lookups and the word view

*Open from Task 5: place rows carry no context yet (meaning, stem, BSB/KJV/STEP), and `verse_words` reads the default recension only. The word view checks that the first page fits the total before `make_success` (`total_covers_page`) and fails with Schema_mismatch otherwise (design scan 28).*

**Files:** `src/concordance/bib_word_lookup.e`, `bib_english_index.e`, `bib_verse_words.e`, `bib_word_view.e`
**Features:** `view`, `rows`, `words`; BIB_WORD_VIEW `section_count`, `section_name`, `is_present`, `facts_model`

### Acceptance Criteria
- [x] Sections come in `approved_order` (research/14 section 3; ruling 1.6)
- [x] Four of the five skeletal concordance tests run against the fixture and pass; the edition swap needs `SIMPLE_BIBLE.open` and moves to Task 7 (verdict condition 4)
- [x] `facts_model` holds the entry, the total and every row of the first page (fact closure on real facts)
- [ ] No label "best" (the engine has no word-view strings yet; checked again with the face) in any word-view string (FR-154)

### Dependencies
Task 5.

---

## Task 7: SIMPLE_BIBLE opens the concordance

*7b deferred (2026-10-26): debate 03 settled that private material arrives as versioned packs "in the published schema", but that schema (voice column, tables, provenance rows) has not been designed; it is a public format third parties may build, so it gets its own design note when the first pack is exported. Until then a generic pack in the folder makes `open` refuse with a named reason; an empty or unset pack folder is the personal edition's case.*

*Found 2026-10-26 while starting it: `open`'s contract also needs two subsystems nobody has built. (1) The content.db check: `core_schema_valid` must hold when open, but content.db's pipeline is unbuilt and the spec does not yet say where its edition lives (`build_run` columns). (2) Generic private packs: `packs_attached` needs the pack-folder scan and BIB_PRIVATE_SOURCE's attach and voice check. Decision (orchestrator): split. **7a**: a content check against a declared minimal content.db v1 (version stamp, the tables the concordance needs, `source_provenance`, a `build_run` row giving the edition), written down as research/18 before code, plus the concordance half of `open`. **7b**: generic packs through BIB_PRIVATE_SOURCE (an empty or unset pack folder counts as zero). **Task 10 (new)**: a small content.db v1 builder (Eiffel) so the personal edition has a real main database before the GUI.*

**Files:** `src/simple_bible.e`, `src/bib_config.e`
**Features:** `open` (concordance part), `pack_count`, `conc_error`, `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup`

### Acceptance Criteria
- [x] `conc_path` attaches the pack; the pack-folder scan never attaches conc.db (FR-166)
- [x] A missing or refused conc.db leaves the Bible open, `conc_pack.is_available` False and the reason in `conc_error` (Larry's policy, 2026-10-26)
- [x] More than `Max_generic_packs` generic packs fail `open` with a reported reason (ruling 2.4); until 7b any generic pack fails `open` with a named reason
- [x] 7a done 2026-10-26: content.db v1 check (research/18), the concordance half of `open`, the edition swap test (FR-158) runs
- [ ] 7b: generic packs through BIB_PRIVATE_SOURCE

### Dependencies
Tasks 3 and 6.

---

## Task 8: timing on the real conc.db (lean)

**Files:** `testing/test_conc_timing.e` (new; skips when the personal conc.db is absent)

### Acceptance Criteria
- [x] Word view first screen within 200 ms warm (lean: 41-44 ms Greek article, 3 ms Hebrew "and") for the commonest words (NFR-019), measured inside `without_contracts` on the lean build
- [x] Verdict condition 5 (lean: 132-146 ms, over 125, so `place_page_after` stays; keyset 3.0 ms): deepest offset page of lemma 9380 (LXX), cold. Under 125 ms: `place_page_after` may be dropped; otherwise it stays
- [x] Results pasted with the machine and build mode: `evidence/phase4-task8-timing.txt`

### Dependencies
Tasks 0 and 7.

---

## Task 10: a content.db v1 builder (Eiffel; new 2026-10-26)

**Files:** a build target (simple_* only)
**What:** writes a content.db that passes research/18's v1 check from bible.db (book catalog with the vault ids, FR-105), `source_provenance`, and a `build_run` row; grows with the content pipeline (FR-130) later.

### Acceptance Criteria
- [x] The built file passes BIB_CONTENT_SOURCE's check; two builds from one input are byte-identical (FR-130's direction; `--built-at` fixes the time)
- [x] Built 2026-10-26 from the vault's bible.db: 66 books, build `content-v1-2026-10-26`, written to `%LOCALAPPDATA%\simple_bible\content.db`; the personal edition opens with it and the real conc.db

### Dependencies
Task 7a.

---

## Task 9: command-line exposure

**Files:** the CLI application (FR-061). No application ECF exists yet (only `simple_bible` and `simple_bible_tests`), so this task starts with a `bible_cli` target, simple_* only (simple_cli or the code base's existing CLI library; check before choosing)
**Features:** word-view, English and verse-word commands through `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup`

### Acceptance Criteria
- [ ] CLI tests for each command against the fixture
- [ ] The personal edition marking (FR-157) on the command line's banner

### Dependencies
Task 7.
