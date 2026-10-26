# Changelog

All notable changes to simple_bible are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed (2026-10-26: the spec fold rolled into the skeletons)

- **The concordance comes in** (D-021, debate 05b pathway B): `src/concordance/` with `BIB_CONC_PACK`, `BIB_WORD_LOOKUP`, `BIB_ENGLISH_INDEX`, `BIB_VERSE_WORDS` and five value classes; `SIMPLE_BIBLE` gains `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup`; `BIB_CONFIG` gains `conc_path` (the edition swap is this one path).
- **One content database** (debate 01 pathway B-S): `BIB_CONTENT_SOURCE` replaces `BIB_CORE_SOURCE` and `BIB_AI_DATA_SOURCE`; optional content ships as empty tables. `BIB_CONFIG` loses `ai_data_path`, `rix_path` and their setters.
- **Data packs, no plug-ins** (debate 03 pathway B′): `BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, `BIB_LENS` and `BIB_LENS_RESULT` are gone; `BIB_PRIVATE_SOURCE` is the effective generic pack source in `src/pack/` (voice and `user_version` checked at attach); `BIB_CONFIG` gains `pack_folder`. Packs attach through `SIMPLE_SQL_DATABASE.attach_read_only`.
- **Notes** (debate 02 pathway B): `BIB_DB_NOTE_STORE` is the Release 1a store, with `export_notes` and `import_notes` under the verdict's contracts and a working `is_file_safe_name`; `BIB_MARKDOWN_NOTE_STORE` is the 1b candidate.
- Tests: `TEST_PACK_PURITY` (was `TEST_PLUGIN_PURITY`), `TEST_CONCORDANCE`, file-name tests.

### Fixed

- **Design scan 23** (`.eiffel-workflow/evidence/design-scan-since-1398860.md`: 2 HIGH, 8 MEDIUM, 5 LOW). HIGH: the purity and layering tests never read `src/pack` or `src/concordance`, because `SOURCE_SCAN` kept a fixed folder list that still named `src/plugin`; it now lists `src`'s folders when it runs (`test_scan_sees_every_source_folder` failed before). HIGH: `BIB_WORD_VIEW.facts_model` was always empty, so `fact_closure` could not fail; it now lists the entry, the place total and the first page (testable only once Phase 4 can build the values: skeletal `test_word_view_lists_every_fact`). MEDIUM fixed: `is_file_safe_name` refuses COM0/LPT0, the superscript-digit forms, CONIN$/CONOUT$ and "NUL .md" (`test_file_safe_name_scan23_gaps` failed before); export names must be distinct; import requires a writable store and accounts for unchanged notes; a generic pack cannot take the alias `conc`; the concordance pack counts against the attach slots. Open (Phase 4, in the report): checking the concordance pack at open, attach #11 versus FR-138, the author library still described as its own file. 73 pass, 52 skeletal, 0 fail.

- **Tests run from any folder.** `SOURCE_SCAN` read the engine ECF and sources relative to the working folder, so the layering and purity tests failed when the suite ran from elsewhere (found by a design-debate spike). Paths now resolve against `SOURCE_SCAN.root`: the working folder when it holds `simple_bible.ecf`, otherwise `$SIMPLE_EIFFEL/simple_bible`. Verified from both locations: 69 pass, 47 skeletal, 0 fail, 0 warnings.

## [0.1.0] - 2026-10-06 — design and engine contracts

### Added

- **Research** (`.eiffel-workflow/research/`): scope, landscape (53 sources), requirements, decisions D-001 to D-020, innovations, risks and recommendation; plus a harvest ledger for retiring simple_scholar, a feature-parity study of e-Sword and Logos, innovations drawn from practice, a world-timeline design with a 61-event pilot, a Septuagint source plan (Swete by default), and a user-voice study (294 items, 96 sources).
- **GUI spec** (`.eiffel-workflow/gui/`): layout and operation on native simple_widgets. A Simple mode (three-pane reader) and a Study mode (docked panels, link sets). 14 panels, 10 dialogs, 25 SVG mockups, the state machine, and 26 simple_widgets gap work items.
- **Specification** (`.eiffel-workflow/spec/`, 8 steps) and the approved **intent** (`intent-v2.md`, 57 Release 1a and 10 Release 1b acceptance criteria).
- **Engine library contracts** (Phase 1): 150 `BIB_*` classes, 16 deferred, with full contracts, MML model queries on all 53 collection attributes and 32 `|=|` frame conditions. "The engine owns every fact" is enforced through `BIB_SOURCED`, `fact_closure` postconditions on 27 features, mandatory provenance keys, four-bucket census and shape results, and restricted creation of mapped references and AI text.
- **Tests**: 21 test classes, 116 tests (69 pass, 47 skeletal reported as SKIP, 0 fail), plus a SCOOP consumer test. Compile gate: 0 errors, 0 warnings.

### Known gaps (to fill in fleet libraries)

- SQLite in eiffel_sqlite_2025 is 3.31.1, and its externals are not marked `blocking`.
- No Unicode normalization in the fleet yet (simple_encoding). Search normalization waits on it.
- simple_hash takes only 8-bit paths.
