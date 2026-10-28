# SPECIFICATION: simple_bible

*Step R07, 2026-10-06. Synthesis of 01-06. Eiffel class texts below are **specification text** for /eiffel.intent and /eiffel.contracts; no `.e` file, ECF or repository is created in this phase. Bodies marked `-- (Phase 4)` are left for implementation; contracts are the specification.*

*Fold 2026-10-26 (debates 01-05, D-021): the run-time database table, the SQLite row, the notes store, the plug-in seam, the concordance pack and the edition swap below follow the five gated verdicts. Each changed passage is marked "(fold 2026-10-26, debate NN)" or "(fold 2026-10-26, D-021)"; superseded text is quoted in the Fold log of `00-FOLD-2026-10-26.md`.*

---

## Overview

simple_bible is a free Windows Bible-study workbench in which a deterministic Eiffel engine over SQLite does all the counting, lookup, comparison and checking of the Hebrew, Greek and English text, and every fact carries its source and license. It is built as:

1. **An engine library** (`simple_bible`, 145 classes in Release 1 plus ported shapes) exposing `SIMPLE_BIBLE` and its engines. Every answer is a result object with a method record and citations; census and shape answers always carry FITS, PARTIAL, FAILS and NO_DATA together; cross-version pairing is possible only through the versification map; AI text can only be created from an engine answer and is always labeled.
2. **A build pipeline** (`bible_build`, 44 classes) that builds the core, AI-data and author-library **stages** from pinned upstream sources and the vault, then assembles the one shipped `content.db` from them, under a license gate, deterministically, with generated credits (fold 2026-10-26, debate 01; was "assembles `core.db`, `ai_data.db` and `rix.db` from pinned upstream sources and the vault"); it hosts the Eiffel ports of the vault's Python tools, each accepted by a differential test against golden outputs.
3. **Two faces** that depend only on engine abstractions: a native simple_widgets GUI (`simple_bible_app`; 13 classes plus 11 panels and 9 dialogs in v1) and a CLI/REPL (`bible.exe`; 7 classes plus 15 allowlisted commands, and three more for the concordance lookups: word view, English, verse words; fold 2026-10-26, debate 05b, FR-061). The engine library's class count above does not yet include the nine `src/concordance/` classes (fold 2026-10-26, debate 05b).
4. **A private data-pack seam (B′)**: no private code and no plug-in registry in the public engine; private material arrives as versioned, read-only packs in a published schema, attached through `attach_read_only` (fold 2026-10-26, settlement S1; was "through the query path") and read by generic public features; the lens logic runs once per vault export in Larry's own export tool (fold 2026-10-26, debate 03; was "A private plug-in seam (5 classes, 3 deferred) that Larry's separate repository implements at compile time"). The **concordance** (`src/concordance/`, nine classes) reads conc.db as one such read-only pack (fold 2026-10-26, debate 05 and D-021).

Release 1 runs no AI on the user's machine; it ships precomputed, labeled AI-made related passages (D-016). Release 1 scope split (1a engine-and-reader, 1b library content packs) is recommended and awaits Larry (Q-01). **Release order (fold 2026-10-26, D-021):** the personal concordance edition (the public engine plus the private conc.db pack) comes before public Release 1a; the target user of the public release (D-003) is unchanged.

## Prerequisites and gap register (must be tracked before the phases that need them)

| ID | Item | Owning library | Needed by | Status |
|----|------|----------------|-----------|--------|
| FT-01 | Upgrade the amalgamation to **3.53.4** (current as of 2026-10-07), unchanged flags; docs in both libraries (D-007) (fold 2026-10-26, debate 04; was "Upgrade the amalgamation from 3.31.1 to current; fix README drift (D-007)") | eiffel_sqlite_2025 | optional for Release 1 (spec designs to the 3.31.1 DDL ceiling, RQ-03 option 2) | **LANDED** (eiffel_sqlite_2025 1.1.0, SQLite 3.53.4; verified 2026-10-22 by a clean simple_bible build: 69 passed, 47 skipped, 0 failed) (fold 2026-10-26, debate 04; was "fleet task, not started") |
| FT-02 | Mark **six** externals (`step`, `prepare_v2`, `open_v2`, `close`, `close_v2`, `backup_step`) `blocking`; no hook guard (commit e80c57c made the five hook setters safe under `blocking` and lifted the guard) (fold 2026-10-26, debate 04, settlement S3; was "guard the five hook setters"; was "Mark `c_sqlite3_step`, `c_sqlite3_open_v2`, `c_sqlite3_close` `blocking` (fleet GC law)") | eiffel_sqlite_2025 | GUI phase P5 (hard; NFR-016), P2 (preferred); ships with FT-01; the FT-02-only build is the contingency; every dependent is rebuilt `-clean` afterward and its generated C checked for `EIF_ENTER_C` around `sqlite3_step` | **LANDED** with FT-01; no hook guard (`e80c57c` made the hooks safe under `blocking`) (fold 2026-10-26, debate 04, settlement S3; was "HELD for Larry's gate (patch in place vs fork)") |
| F-9 | simple_sql error integrity (items a-d, f-i) and eiffel_sqlite_2025 COMMIT flag (item e): `atomic` rolls back on a failed statement, errors are sticky inside a transaction, a failed COMMIT is reported, the migration runner fails on any failed statement, online backup retries SQLITE_BUSY/LOCKED | simple_sql; eiffel_sqlite_2025 | **before P2's `user` cluster tests**; the P-ATOMIC probes must pass on the fixed library before any user-store contract test counts (fold 2026-10-26, debate 02) | **LANDED** (simple_sql `5a17f97`; eiffel_sqlite_2025 `23db5d0`) (fold 2026-10-26, debate 02) |
| F-1, F-4, F-2, F-5, F-7, F-SN | simple_file: atomic write (temp, flush, `MoveFileExW` replace with write-through), ReadOnly-folder create, UTF-8 `read_text`, OS failures reported through `has_error`/`last_error`, file-safe names (F-SN, confirm against simple_file 1.1.0 `7f31278`); simple_yaml: front-matter split (F-7); simple_hash: STRING_32 paths (LG-09) | simple_file, simple_yaml, simple_hash | the export and import of the notes store (P2) | landing status not recorded in the verdict (F-SN: simple_file 1.1.0 lists stream-name handling; confirm it covers F-SN) (fold 2026-10-26, debate 02) |
| F-3b, F-11, F-1″, LG-10 | One-pass enumeration; streaming SHA-256; hold-then-rename save by handle with a full path; 100 ns timestamps | simple_file, simple_hash | Release 1b only (the file-authoritative notes candidate A″) | UNTESTED; gated by DS-3c first (fold 2026-10-26, debate 02) |
| LG-01 | Unicode NFD/NFC and general category incl. Mn/Mc/Me | simple_encoding | `BIB_GREEK_NORMALIZER`, Swete repair | to file |
| LG-03 | `STRING_32` variants of `string_value_or_void` / `_or_default` | simple_sql | engine coding rule (until then, banned accessors) | to file |
| LG-04 | GPU execution provider runtime (optional) | simple_onnx | build-time embeddings speed | optional |
| LG-05 | bge-m3 (XLM-R SentencePiece) tokenizer compatibility, if the check fails | simple_onnx | `BIB_EMBEDDING_PRECOMPUTE` | check first |
| LG-06 | MCP protocol library (JSON-RPC over stdio), new fleet library | new (`simple_mcp`) | the MCP face, only if Q-12 says yes | not started |
| GW-01..13, 24, 26 (every GW gap is done; Phase 4 complete 2026-10-26: gui/02-GAP-PROGRAM.md) (fold 2026-10-26, D-006) | v1 GUI gap items (fonts, RTL alignment, cantillation, shaped grids, dock, parallel text, interlinear, paragraph-list hit tests, hover card, grouped bars, status sections, query builder, rich text, function keys, cross-processor wake) | simple_shaping, simple_widgets, simple_shell | GUI panels (see 03 A-011 order) | filed in gui/spec_windows_design_notes §9 |
| GW-14..16, 21 | v1.5 GUI items | same | v1.5 | - |
| GW-17..20, 22, 23, 25 | v2 GUI items | same | v2 | - |

Every item is fixed in its owning library, followed by a downstream-dependents sweep and README/docs/CHANGELOG updates (C-018). None is worked around in simple_bible (C-013).

## Data model (run time)

| Database | Mode | Holder | Contents (Release 1) |
|----------|------|--------|----------------------|
| `content.db` **(the one shipped content file; fold 2026-10-26, debate 01, B-S)**, assembled from the core, AI-data and rix build stages (rows below) | read-only | every engine processor | **Core stage part:** `book_catalog` (vault ids, FR-105), `versification_system`, `versification_map`, `version`, `verse` (display text, `verse_suffix`, omission kind, repair state, provenance key; `verse_id` contiguous per version, with a version-range table), `verse_fts`: an FTS5 index (`unicode61 remove_diacritics 2`) over text folded at build time by one Eiffel normalizer, declared `content=''` in the shipped file, its four shadow tables copied from the verified stage and identical to it (fold 2026-10-26, debate 01, TN-R and R-N4v; was "`verse_norm` + FTS5 (`unicode61 remove_diacritics 2`) over normalized text"; no stored `verse_norm` column ships unless overturn trigger OT-N1 fires), `word` (keys, morph code, gloss, transliteration, pronunciation), `lemma`, `strongs` (split senses), `morph_code` (English expansion), `cross_reference` (votes), `quotation`, `alignment`, `lemma_frequency`, `shape`, `shape_instance`, `shape_evidence`, `shape_run`, `proper_name*` (TIPNR), `source_provenance` (one table, same file), `source_repairs`, `quarantine`, `caveat`, `import_gap`, `build_run`, `table_checksum` (the changelog and seal work from per-table checksums, since the file hash changes whenever the author library is rebuilt). `library_resource` and `library_entry` (R1b per Q-01) move into the pack schema (fold 2026-10-26, debates 01 and 03). **AI-data stage part:** `related_passage` (target, reason kind, votes, `is_ai_made`, method, model id); vectors in v2 (Q-06). **Author-library stage part:** `docs`, `verse_refs`, `docs_fts` (R15) plus its folded index built beside the untouched R15 tables. **Optional public content ships as empty tables, never as missing files;** presence is a count or a manifest flag (fold 2026-10-26, debate 01) |
| `core.db`, `ai_data.db`, `rix.db` | **build stages only; not shipped as separate files** (fold 2026-10-26, debate 01; was three read-only run-time databases: `core.db` required, `ai_data.db` "read-only, optional" with `related_passage`, and `rix.db` "read-only, optional", "exactly the R15 schema of `build_rix_db.py`") | the build | The rix stage file is the object of AC-1a-10 (the builder's output equals the Python golden, `mtime` included); "exactly the R15 schema" applies to that stage file, not to `content.db`. Each stage keeps its own provenance and stored folded column; the assembly step copies DDL verbatim and rows, checks per-table identity with each stage in both directions (FTS5 shadow tables included), and checks that two builds from one manifest are byte-identical (fold 2026-10-26, debate 01) |
| Packs (generic private data packs: `*.db` in the pack folder, found by the folder scan; conc.db is a second kind, found by `conc_path`: fold 2026-10-26, settlements S6, G1) | read-only, optional, **attached read-only through `SIMPLE_SQL_DATABASE.attach_read_only`** on the read-only main (fold 2026-10-26, settlement S1; was "through the query path (never a `file:` URI)") | engine processors | A generic private data pack declares its `user_version` (checked at open), a `NOT NULL` voice column, `provenance_key` and `source_provenance` in its own file (conc.db is checked by `BIB_CONC_PACK`'s own check instead: expected `user_version` plus required tables, provenance per corpus and per meaning; fold 2026-10-26, settlement S6), and reference rows with their versification declared. The pack format is public and documented; third parties may build packs; Larry's lens annotations and `machine_generated.db` ship only as private packs (fold 2026-10-26, debate 03). A pack whose folded index fails the published fold-parity fixture is attached and labeled "not diacritic-safe", not refused (fold 2026-10-26, debate 01, gate item 4). The concordance pack **conc.db** (1.23 GB, personal edition) is described under "Concordance pack and edition swap" below (fold 2026-10-26, debate 05 and D-021) |
| `user.db` | read-write | user-store processor only | notes (system of record, append-only versions, soft delete, restore; fold 2026-10-26, debate 02), highlights, bookmarks, tags, history, prayer, memory cards, plan progress, collections, layout snapshots, settings, census definitions and runs, (v1.5) ledger |
| `history.db` | read-only, v2 | engine processors | 11 §5.3 schema, `v_shippable` export only; v2: folded into `content.db` or a separate file, decided when v2 is specified (fold 2026-10-26, debate 01) |

All DDL uses only the SQLite 3.31.1 feature ceiling: `CHECK` and `NOT NULL` instead of `STRICT`; no `->>`; no math functions; generated columns allowed. The run-time engine is SQLite **3.53.4** (eiffel_sqlite_2025 1.1.0) with the six `blocking` externals; the Release 1 DDL ceiling stays at 3.31.1 features (RQ-03 option 2) (fold 2026-10-26, debate 04).

### Attach policy and per-schema checks (fold 2026-10-26, debates 01, 03, 04)

| Rule | Statement | Source |
|------|-----------|--------|
| One main | The engine's main connection opens `content.db` read-only; `user.db` is never on an engine connection | debate 01, verdict 5.1 item 4 |
| Attach through `attach_read_only` | Packs attach with `SIMPLE_SQL_DATABASE.attach_read_only` (URI, `mode=ro`, simple_sql 5a17f97, 2026-10-08; executed on 3.53.4 by debate 05a: write refused); never `ATTACH 'file:...?mode=ro'` through `perform`/`execute` (the skeleton's form at `bib_source_set.e:111-112` is dropped). Superseded: "`query ("ATTACH ...")` on the read-only main" (debates 01 and 03, written when SQLite 3.31.1 had URI filenames off) (fold 2026-10-26, settlement S1) | debates 01, 03, 05a |
| Slots | `Max_attached` (10 on both 3.31.1 and 3.53.4; attach #11 fails) counts **pack slots only**; an attach policy (attach on demand, or a slot cap per engine connection) is specified and tested under SCOOP; attach number 11 reports SQLite's own message, not "Unknown error" | debate 01 queue 4; debate 03 OT-6 |
| Named schema | Every provenance check names its schema: `PRAGMA <schema>.foreign_key_check` for `content.db` and every pack. A bare `foreign_key_check` is never used (3.31.1 false pass; 3.53.4 reports the violation) | debates 01, 04 |
| Rowid range | `verse_id` is contiguous per version; every search and display-fetch path filters by an FTS rowid range, never by a join on `verse.version_id`; `hub_id` is never the FTS rowid | debate 01, SB-1 |
| Provenance measure | K7-A: every content table `content.db` defines (FTS5 shadow tables excepted) declares `provenance_key ... NOT NULL REFERENCES source_provenance` with `source_provenance` in the same file | debate 01, K7-A |

### Build stages, assembly and folded search (fold 2026-10-26, debate 01)

| Item | Specification | Status word |
|------|---------------|-------------|
| Layout | B-S: stages separate; one assembly step writes `content.db` (DDL verbatim, rows copied, per-table `EXCEPT` identity in both directions with each stage, FTS5 shadow tables included, two-build byte identity); optional public content as empty tables; `user.db` separate; packs attach read-only | PREFERRED, 0.65 / 0.80 (debate 01, Larry's gate 2026-10-22: adopted) |
| Assembly step | A new class in `bible_build` carries the `per_table_identity` and `deterministic` postconditions; `BIB_AI_DATA_SOURCE` and `BIB_CORE_SOURCE` collapse into one content source; `has_ai_data` becomes a presence count | debate 01, section 8 |
| Normalizer | One Eiffel normalizer (`BIB_*_NORMALIZER` over LG-01) folds every searchable text the build makes: remove general categories M\* and Cf, map Hebrew finals and Greek final sigma, case-fold; the user's query passes through the same normalizer. Display text is never read from the index | PREFERRED, 0.75 / 0.85 (TN-R) |
| Storage form | Stage: a stored folded column and an external-content FTS5 index, `integrity-check` required to pass, residue census over the column. Shipped: the same index declared `content=''`, shadow rows copied from the stage; no stored folded column ships unless OT-N1 fires. The author library's folded index is built the same way beside the untouched R15 tables | PREFERRED over a shipped stored column, 0.70 / 0.85 (R-N4v) |
| Pack folds | A pack's folded index comes from the Eiffel pack builder or passes the published fold-parity fixture; the pack format declares its fold-rule version | debate 01, 5.2 item 6 and section 8 |
| Prefix search | A `prefix=` index only if prefix search is gated at 10x | debate 01, section 8 (03 line 40) |
| Highlight | No `highlight()` or `snippet()` on the folded index (no Release 1a consumer) | debate 01, known costs |
| User anchors | User items anchor to `hub_id`, not to the FTS rowid, so per-version rowid renumbering touches no anchor | debate 01, section 7 note |

### Notes store (fold 2026-10-26, debate 02)

| Item | Specification | Status word |
|------|---------------|-------------|
| Release 1a store | Pathway B: `user.db` is the system of record for notes, written only by the user-store processor through `BIB_DB_NOTE_STORE` behind `BIB_NOTE_STORE` (append-only versions, soft delete, restore; the seam stays). All note writes go through the one processor that owns the store's state | PREFERRED, 0.70 / 0.80 (Larry's gate 2026-10-22: adopted; Q-11's own fallback "otherwise user.db first") |
| Export | On demand, one Markdown file per live note with `id` and `hub_id` front matter, an id-based or sanitized file name (never a raw title), an atomic write, into a folder the exporter creates; every failure is reported (`files_written + failures = live notes`). Default folder outside the reader's notes vault, labeled a read-only copy; the user may point it into the vault | debate 02, 5 item 2 and gate item 3 |
| Import | Reads a folder back as new notes or new versions; never overwrites a row | debate 02, 5 item 2 |
| Exit snapshot (B′) | An automatic plain-text copy of changed notes at each clean exit, **if DS-B′ passes**; a rotating backup at start after an unclean exit is recommended for test (DS-B-S8), not adopted untested | debate 02, 5 item 4 and gate item 2 |
| Prerequisite | F-9 (above): P-ATOMIC passes on the fixed library before any user-store contract test counts (overturn trigger OT-1); the user-store contracts forbid any store routine reporting success after a failed statement | debate 02, 5 item 3 |
| 1b candidate | A″ (file-authoritative Markdown folder) is gated and UNTESTED, behind DS-3c (one GUI test on a scratch vault, allowed once, at a time Larry chooses), then DS-10, DS-2″, DS-1/DS-8, DS-R1, DS-R2 and the A″-only fixes. `BIB_MARKDOWN_NOTE_STORE` is the 1b candidate, not a 1a class | debate 02, 5 item 5 and gate item 4 |
| Libraries | simple_yaml is needed in 1a for export (`to_yaml`) and import (parse) | debate 02, 8.1 |

### Private packs, plug-in seam B′ (fold 2026-10-26, debate 03)

| Item | Specification | Status word |
|------|---------------|-------------|
| Seam | B′: the lens logic (five frame lenses, graph analytics, KACC scoring once it exists) runs once per vault export on Larry's machine and writes rows with a `NOT NULL` voice column and `provenance_key`, keyed to passages through reference rows; private databases are re-emitted into versioned packs in the published schema (`user_version` checked at open; generic private data packs only, conc.db has its own check: fold 2026-10-26, settlement S6) | PREFERRED, 0.75 / 0.80 (Larry's gate 2026-10-06: adopted) |
| Public engine | Runs no private code and no rule interpreter; finds generic private packs by folder (conc.db by `conc_path`: fold 2026-10-26, settlement G1), attaches each through `SIMPLE_SQL_DATABASE.attach_read_only` on a read-only main (fold 2026-10-26, settlement S1; was `query ("ATTACH ...")`), builds voiced results through the public `make_success`. User queries over private corpora run through generic public features (by-verse range overlap, Boolean key search, edit-distance fuzzy match, multi-source FTS with source labels), and those searches and FR-116 library queries cover attached packs | debate 03, 5 items 3-4; 8 |
| Removed | `BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, the deferred `BIB_LENS`, `set_plugin_registry`, the `plugins` accessor and the plug-in folder; `BIB_PRIVATE_SOURCE` becomes an effective generic pack source; `BIB_LENS_RESULT` keeps its voice, `plugin_name` becoming the pack name | debate 03, section 8 |
| Purity test | `test_plugin_purity` is re-specified (K2′, AC-1a-57): the public executable contains no string from the private list in ASCII, UTF-16LE or UTF-32LE, and the positive control includes a `{STRING_32}` private string | debate 03, section 8 |
| Export tool | The private export tool may stay Python (D-020 scope is the shipped product only) | debate 03, gate item 6 |

### Concordance pack and edition swap (fold 2026-10-26, debate 05 and D-021)

| Item | Specification | Status word |
|------|---------------|-------------|
| Placement | conc.db stays its own file and attaches read-only as a pack: `BIB_SOURCE_SET.attach` calls `SIMPLE_SQL_DATABASE.attach_read_only` (alias `conc`, URI `mode=ro`, works on a read-only connection). It is never folded into `content.db`: folding 1.23 GB of research-only layers into the shipped file would break D-021 (personal edition = public engine plus a private pack) and debate 03's B′. Measured: a write into the attached pack is refused by SQLite ("attempt to write a readonly database"); attached queries cost the same as direct (first page of 200 places 28.2 versus 25.0 ms) | ESTABLISHED, 0.90 / 0.90 (05a fork 1; gated 2026-10-26) |
| Pack count | The pack uses one of the 10 attach slots (`Max_attached`); overturn: a pack count above 10, or an attached query more than 20 percent slower than direct on a future SQLite | 05a |
| Classes | `src/concordance/` beside an untouched `BIB_CONCORDANCE`: `BIB_CONC_PACK` (every pack SQL statement, `Pack_alias = "conc"`, `Max_page_size = 200`, `lemma_id: INTEGER_64` signatures), `BIB_WORD_LOOKUP`, `BIB_ENGLISH_INDEX`, `BIB_VERSE_WORDS`, and the value classes `BIB_WORD_ENTRY`, `BIB_PLACE_ROW`, `BIB_ENGLISH_ROW`, `BIB_VERSE_WORD`, `BIB_WORD_VIEW`, as compiled in `debate/05.../spikes/skeletons/B/`. `SIMPLE_BIBLE` gains `conc_pack`, `word_lookup`, `english_index` and `verse_word_lookup`; `BIB_CONFIG` gains `conc_path`. No deferred seam now | PREFERRED, 0.70 / 0.80 (05b; gated 2026-10-26) |
| Headword rule | The concordance pack's lookups are keyed by `lemma_id`, never by Strong's; Strong's only through `lemma_xref` (`headwords_for_strongs`). `BIB_CONCORDANCE` and FR-023 (counts by lemma, Strong's, morphology, surface; AC-1a-22) stay as they are for Release 1a; rekeying FR-023 is 05b overturn trigger 3 and needs a new debate (fold conflict 1) | fold plan, conflict 1 |
| Two counters | `BIB_CONCORDANCE.count` (core keys) and `BIB_CONC_PACK.place_total` (`lemma_id`), each stating its key kind and scope | 05b, section 8 |
| Paging | Every-place and English lists are paged, never loaded whole: first 200 places 25-28 ms; the whole list for the Greek article in the LXX (88,444 rows) 572-874 ms lean, 9.6-10.6 s in a contract build, so the shipped build is lean and tests that time reads run `without_contracts`. A cursor left early is closed (it holds SQLite's read lock). `ORDER BY` on an unindexed column is not lazy | 05a, do-not-assume 1, 2, 4, 5 |
| Pack builder: transliteration | `token.translit` is precomputed in the conc.db builder (158,342 distinct written forms covering 1,375,071 tokens, 1.2 s with the pilot's rules, 0 failures, 7.6 MB, 0.6 percent of conc.db). Not a form table (saves 3.5 MB but adds a join to every every-place row) and not a port of the rules into the engine for the personal edition. Overturn: a view that transliterates text not in conc.db (needs `BIB_TRANSLITERATOR` rules in Eiffel) | PREFERRED, 0.80 / 0.85 (05a fork 4) |
| Pack builder: first-screen aggregates | Precompute, per headword, the per-corpus counts and the English-at-a-glance summary (a few tens of thousands of rows) so the first screen reads rows instead of aggregating hundreds of thousands. Measured first screen (lean F_code, back to back, three rounds): Greek article NT 205 / 398 / 197 ms; Hebrew "and" (50,272 places) 2,773 / 277 / 140 ms; a word with 246 places 3 / 2 / 2 ms. Overturn: a measured first screen under 200 ms cold for lemma 8 without it | orchestrator addendum to 05b |
| Pack builder: schema version | The conc.db builder sets `PRAGMA user_version` (conc.db has 0 today), so `BIB_CONC_PACK` can check its expected version at open together with the required tables (fold 2026-10-26, settlement S6). conc.db is a concordance pack of its own kind: it is not checked by debate 03's generic pack-schema check (`user_version`, a `NOT NULL` voice column, `provenance_key`), which governs generic private data packs (`BIB_PRIVATE_SOURCE`); its provenance is per corpus (`corpus.license`, `ship_class`) and per meaning (`meaning_source`), as 05b's K6 measures (fold 2026-10-26, settlement S6). `BIB_CONC_PACK` has no inheritance relation to `BIB_PRIVATE_SOURCE` now (fold 2026-10-26, settlement G2). conc.db is found by `BIB_CONFIG.conc_path`, generic private packs by the pack-folder scan (fold 2026-10-26, settlement G1) | 05b; debate 03; D-021 |
| Builder language | The conc.db builder (Python, the research vault's tools folder) may stay Python while it builds only the private pack. The distribution pack `conc_dist.db` needs an Eiffel builder with a differential test against `conc_translit.py`, form by form, over the 158,342 forms | D-021, D-020 fork 03 item 6, 05a |
| Editions | **Personal edition**: reads conc.db as is (research-only layers included: the CATSS Rahlfs LXX; the BSB per-word tables awaiting Berean's answer); marked "PERSONAL EDITION - not for distribution" in the title bar and the About window; never published. **Distribution edition**: reads conc_dist.db only (not yet built; blockers in research/14 section 6); credits generated from the pack's own `notice` table, listed in About beside the engine's `source_provenance` credits (FR-003; nothing typed by hand; fold 2026-10-26, settlement S4) | D-021 |
| Edition swap | The edition is a pack path: the same `BIB_CONC_PACK` reads conc.db or conc_dist.db by changing `conc_path`; no code change. `BIB_CONC_PACK.edition_label` is what the pack says it is (title bar and About); the engine never branches on it, and no edition test appears in engine code (05b overturn trigger 4: remove it). `has_layer` ("lxx", "bsb", "dictionaries") tells the face which sections exist, since conc_dist.db may lack some | 05a, 05b |
| Meanings | The personal edition shows the SDBH and SDGNT meanings conc.db holds (D-021, later than D-012). Public Release 1a keeps D-012 (no Hebrew semantic layer in the MVP); the distribution edition may carry them (CC BY-SA) when conc_dist.db exists (fold conflict 2) | fold plan, conflict 2 |
| Core build | Whether core.db's specified `lemma` and `alignment` tables can answer a headword query in `lemma_id` terms is UNTESTED; when core.db is built, read its schema once (05b queue 3, overturn trigger 1) | 05b |

## Class Specifications

### SIMPLE_BIBLE (Facade)

```eiffel
note
    description: "Facade: one processor's access to the simple_bible engine. Open the sources, then use the engines; every answer carries its method and sources."
    author: "Larry Rix"

class
    SIMPLE_BIBLE

create
    make

feature {NONE} -- Initialization

    make (a_config: BIB_CONFIG)
            -- Create an unopened engine for `a_config`.
        require
            config_valid: a_config.is_valid
        do
            config := a_config
            create sources.make
        ensure
            config_set: config = a_config
            not_open: not is_open
            no_error: last_error = Void
        end

feature -- Configuration

    config: BIB_CONFIG

feature -- Lifecycle

    open
            -- Open content.db (required) read-only, then attach the packs found in the pack folder, on this processor.
            -- (fold 2026-10-26, debates 01 and 03; was "Open core.db (required) and the optional databases present")
        require
            not_open: not is_open
        do
            -- (Phase 4) sources.open_core (config.content_path); check schema; attach each pack found in
            -- the pack folder on the read-only main through attach_read_only (fold 2026-10-26, settlement S1), checking
            -- user_version, the voice column and provenance per named schema (generic private data packs; conc.db is attached
            -- from config.conc_path and opened through BIB_CONC_PACK's own check: fold 2026-10-26, settlements S6, G1); no plug-in registry.
            -- (fold 2026-10-26, debates 01 and 03; was "attach optional sources; let each registered
            -- plug-in attach its private sources (A-012)")
        ensure
            open_or_error: is_open xor (last_error /= Void)
            core_checked: is_open implies core_schema_valid
        end

    close
            -- Close every connection held by this processor.
        require
            open: is_open
        do
            -- (Phase 4)
        ensure
            closed: not is_open
        end

feature -- Status

    is_open: BOOLEAN
            -- Are the sources open on this processor?
        do
            Result := sources.is_open
        end

    core_schema_valid: BOOLEAN
            -- Did content.db pass its schema-version and required-table check? (fold 2026-10-26, debate 01; was "core.db")

    has_ai_data: BOOLEAN
    has_author_library: BOOLEAN
    has_history: BOOLEAN
            -- Optional public content present: a count over the empty-by-default tables of content.db
            -- (never a missing file; history: v2). (fold 2026-10-26, debate 01; was "Optional databases present and open")

    -- (fold 2026-10-26, debate 05) Whether the concordance pack is attached is `conc_pack.is_available`.

    database_edition: STRING_32
            -- Build id of content.db.

    last_error: detachable BIB_ERROR
            -- Why `open` failed.

feature -- Engines

    books: BIB_BOOK_CATALOG
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    parser: BIB_REFERENCE_PARSER
        require open: is_open
        once ("OBJECT") create Result.make (books) end

    versification: BIB_VERSIFICATION_MAP
        require open: is_open
        once ("OBJECT") create Result.make (sources, books) end

    hub: BIB_VERSE_HUB
        require open: is_open
        once ("OBJECT") create Result.make (sources, versification) end

    search: BIB_SEARCH_ENGINE
        require open: is_open
        once ("OBJECT") create Result.make (sources, normalizers) end

    concordance: BIB_CONCORDANCE
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    census: BIB_CENSUS_ENGINE
        require open: is_open
        once ("OBJECT") create Result.make (sources, concordance) end

    shapes: BIB_SHAPE_ENGINE
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    quotations: BIB_QUOTATION_COMPARER
        require open: is_open
        once ("OBJECT") create Result.make (sources, versification) end

    range_viewer: BIB_RANGE_VIEWER
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    journey: BIB_WORD_JOURNEY
        require open: is_open
        once ("OBJECT") create Result.make (sources, versification) end

    divine_names: BIB_DIVINE_NAME_MARKER
        require open: is_open
        once ("OBJECT") create Result.make (sources, normalizers) end

    guides: BIB_GUIDE_ASSEMBLER
        require open: is_open
        once ("OBJECT") create Result.make (Current) end

    related: BIB_RELATED_PASSAGES
        require open: is_open
        once ("OBJECT") create Result.make (sources, has_ai_data) end

    library: BIB_LIBRARY
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    names: BIB_PROPER_NAMES
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    author_library: BIB_AUTHOR_LIBRARY
        require
            open: is_open
            available: has_author_library
        once ("OBJECT") create Result.make (sources) end

    checks: BIB_CHECK_RUNNER
        once ("OBJECT") create Result.make_default end

    exporter: BIB_EXPORTER
        once ("OBJECT") create Result.make end

    -- (fold 2026-10-26, debate 03) The `plugins: BIB_PLUGIN_REGISTRY` accessor is removed; private
    -- material arrives as packs read through generic public features.

    conc_pack: BIB_CONC_PACK
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    word_lookup: BIB_WORD_LOOKUP
        require open: is_open
        once ("OBJECT") create Result.make (conc_pack) end

    english_index: BIB_ENGLISH_INDEX
        require open: is_open
        once ("OBJECT") create Result.make (conc_pack) end

    verse_word_lookup: BIB_VERSE_WORDS
        require open: is_open
        once ("OBJECT") create Result.make (conc_pack) end
            -- conc_pack, word_lookup, english_index and verse_word_lookup: the concordance
            -- (fold 2026-10-26, debate 05; debate/05.../spikes/skeletons/B/override/simple_bible.e)

feature -- Convenience

    verse (a_text: READABLE_STRING_GENERAL): BIB_VERSE_RESULT
            -- Parse `a_text`, map it, and look it up in the default versions.
        require
            open: is_open
            text_not_empty: not a_text.is_empty
        do
            -- (Phase 4)
        ensure
            parse_outcome_carried: Result.parse_outcome /= Void
            ambiguous_never_guessed: Result.parse_outcome.is_ambiguous implies Result.version_count = 0
        end

    rerun (a_method: BIB_METHOD): BIB_ENGINE_RESULT
            -- Re-run a recorded method (Show method, FR-032).
        require
            open: is_open
            rerunnable: a_method.is_rerunnable
        do
            -- (Phase 4) dispatch on a_method.engine_feature
        ensure
            same_edition_same_counts: a_method.database_edition.same_string (database_edition)
                implies Result.method.counts_equal (a_method)
        end

    credits: STRING_32
            -- Credits generated from source_provenance (FR-003).
        require
            open: is_open
        do
            -- (Phase 4)
        end

feature {NONE} -- Implementation

    sources: BIB_SOURCE_SET
            -- This processor's single connection and its attachments.

    normalizers: BIB_NORMALIZER_SET
            -- Hebrew, Greek, English normalizers (shared with the build).

invariant
    error_only_when_closed: last_error /= Void implies not is_open

end
```

### BIB_ENUMERATION and BIB_VERDICT

```eiffel
note
    description: "A closed set of codes with labels."
deferred class
    BIB_ENUMERATION

feature -- Access

    code: INTEGER
    label: STRING_32 deferred end

feature -- Status

    is_valid_code (a_code: INTEGER): BOOLEAN deferred end

invariant
    valid: is_valid_code (code)
end

note
    description: "FITS, PARTIAL, FAILS, NO_DATA. NO_DATA means the tagging is silent; it is not evidence of absence."
class
    BIB_VERDICT

inherit
    BIB_ENUMERATION

create
    make_fits, make_partial, make_fails, make_no_data

feature {NONE} -- Initialization
    make_fits do code := Fits ensure is_fits end
    make_partial do code := Partial ensure is_partial end
    make_fails do code := Fails ensure is_fails end
    make_no_data do code := No_data ensure is_no_data end

feature -- Status
    is_fits: BOOLEAN do Result := code = Fits end
    is_partial: BOOLEAN do Result := code = Partial end
    is_fails: BOOLEAN do Result := code = Fails end
    is_no_data: BOOLEAN do Result := code = No_data end
    is_valid_code (a_code: INTEGER): BOOLEAN do Result := a_code >= Fits and a_code <= No_data end

feature -- Access
    label: STRING_32
        do
            inspect code
            when Fits then Result := "FITS"
            when Partial then Result := "PARTIAL"
            when Fails then Result := "FAILS"
            else Result := "NO_DATA"
            end
        end

feature -- Constants
    Fits: INTEGER = 1
    Partial: INTEGER = 2
    Fails: INTEGER = 3
    No_data: INTEGER = 4
            -- The reporting order: always FITS, PARTIAL, FAILS, NO_DATA.
end
```

### BIB_LICENSE and BIB_PROVENANCE

```eiffel
note
    description: "License of a source: identifier, clauses, credit line. Unknown licenses never ship (D-002)."
class
    BIB_LICENSE

create
    make

feature {NONE} -- Initialization
    make (a_identifier: READABLE_STRING_GENERAL; a_non_commercial, a_share_alike, a_restricted: BOOLEAN; a_credit: READABLE_STRING_GENERAL)
        require
            identifier_not_empty: not a_identifier.is_empty
        do
            identifier := a_identifier.to_string_32
            is_non_commercial := a_non_commercial
            is_share_alike := a_share_alike
            is_restricted := a_restricted
            credit_line := a_credit.to_string_32
        ensure
            identifier_set: identifier.same_string_general (a_identifier)
        end

feature -- Access
    identifier: STRING_32
    credit_line: STRING_32

feature -- Status
    is_unknown: BOOLEAN do Result := identifier.same_string ("UNKNOWN") end
    is_non_commercial: BOOLEAN
    is_share_alike: BOOLEAN
    is_restricted: BOOLEAN
            -- Copyrighted without a license to share, or held under terms the tool cannot meet (e.g. CCAT clause 3).

    may_ship_in_free_tool: BOOLEAN
            -- D-002: attribution always; NC allowed (free tool); unknown and restricted never.
        do
            Result := not is_unknown and not is_restricted
        ensure
            unknown_never_ships: is_unknown implies not Result
            restricted_never_ships: is_restricted implies not Result
        end

invariant
    id_not_empty: not identifier.is_empty
end

note
    description: "Where a fact came from: source, edition, license, grade, caveat; AI-made build-time data is flagged with its method."
class
    BIB_PROVENANCE

create
    make, make_ai_made

feature {NONE} -- Initialization
    make (a_source_key: READABLE_STRING_GENERAL; a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE)
        require
            key_not_empty: not a_source_key.is_empty
        do
            source_key := a_source_key.to_string_32
            edition := a_edition.to_string_32
            license := a_license
            create caveat.make_empty
            create method_label.make_empty
            create model_id.make_empty
        ensure
            not_ai: not is_ai_made
        end

    make_ai_made (a_source_key, a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE; a_method, a_model: READABLE_STRING_GENERAL)
        require
            key_not_empty: not a_source_key.is_empty
            method_named: not a_method.is_empty
            model_named: not a_model.is_empty
        do
            make (a_source_key, a_edition, a_license)
            is_ai_made := True
            method_label := a_method.to_string_32
            model_id := a_model.to_string_32
        ensure
            ai: is_ai_made
        end

feature -- Access
    source_key: STRING_32            -- e.g. "WLC", "SBLGNT", "SWETE", "OB-XREF"
    edition: STRING_32
    license: BIB_LICENSE
    caveat: STRING_32                -- version caveat (FR-005), may be empty
    grade: detachable BIB_GRADE      -- P1-P4 where the source class requires it (timeline, private)
    is_ai_made: BOOLEAN
    method_label: STRING_32          -- "meaning neighbor, bge-m3, computed at build time"
    model_id: STRING_32

feature -- Status
    requires_grade: BOOLEAN
        -- Timeline and private sources must be graded.

invariant
    source_named: not source_key.is_empty
    ai_made_has_method: is_ai_made implies (not method_label.is_empty and not model_id.is_empty)
    graded_when_required: requires_grade implies grade /= Void
end
```

### BIB_FACT [G]

```eiffel
note
    description: "One value the engine asserts, bound to its provenance. A fact cannot exist without provenance."
class
    BIB_FACT [G]

create
    make

feature {NONE} -- Initialization
    make (a_value: G; a_provenance: BIB_PROVENANCE)
        do
            value := a_value
            provenance := a_provenance
        ensure
            value_set: value ~ a_value
            provenance_set: provenance = a_provenance
        end

feature -- Access
    value: G
    provenance: BIB_PROVENANCE

invariant
    has_provenance: provenance /= Void
end
```

### BIB_METHOD

```eiffel
note
    description: "How a number or list was produced. Re-running it on the same database yields the same output (FR-032)."
class
    BIB_METHOD

create
    make

feature -- Access
    engine_feature: STRING_32       -- "verse", "census", "shape", "search", "concordance" ...
    canonical_query: STRING_32      -- clause tree / parameters in canonical text form
    corpus_label: STRING_32
    versions: ARRAY [STRING_32]
    rules_count: INTEGER            -- versification rules applied
    rule_notes: ARRAY [STRING_32]
    counts: ARRAY [INTEGER_64]
    engine_version: STRING_32
    database_edition: STRING_32
    sqlite_version: STRING_32       -- FR-NEW-008

feature -- Status
    is_rerunnable: BOOLEAN
        do Result := not canonical_query.is_empty end

    counts_equal (other: BIB_METHOD): BOOLEAN
        do -- (Phase 4) element-wise equality of counts
        ensure
            symmetric: Result = other.counts_equal (Current)
        end

invariant
    query_recorded: not canonical_query.is_empty
    engine_named: not engine_feature.is_empty
    edition_recorded: not database_edition.is_empty
    sqlite_recorded: not sqlite_version.is_empty
end
```

### BIB_ENGINE_RESULT (deferred)

```eiffel
note
    description: "Every engine answer: method, citations (the sources consulted), success xor error."
deferred class
    BIB_ENGINE_RESULT

feature -- Access
    is_success: BOOLEAN
    error: detachable BIB_ERROR
    method: BIB_METHOD

    citation_count: INTEGER
        do Result := citations.count end

    citation (i: INTEGER): BIB_PROVENANCE
        require
            in_range: i >= 1 and i <= citation_count
        do
            Result := citations [i]
        ensure
            model_agrees: Result = citations_model [i]
        end

feature -- Model
    citations_model: MML_SEQUENCE [BIB_PROVENANCE]
        do
            create Result
            across citations as ic loop Result := Result & ic.item end
        end

feature {NONE} -- Representation
    citations: ARRAYED_LIST [BIB_PROVENANCE]

invariant
    success_xor_error: is_success xor (error /= Void)
    success_is_cited: is_success implies citation_count > 0
    method_present: method /= Void
end
```

### BIB_BUCKETED_RESULT [G -> BIB_FINDING]

```eiffel
note
    description: "FITS, PARTIAL, FAILS and NO_DATA together. A result with fewer than four buckets cannot exist (FR-026)."
class
    BIB_BUCKETED_RESULT [G -> BIB_FINDING]

create
    make

feature {NONE} -- Initialization
    make (a_definition_id: INTEGER_64)
        require
            definition_bound: a_definition_id > 0
        do
            definition_id := a_definition_id
            create fits.make (0); create partial.make (0); create fails.make (0); create no_data.make (0)
        ensure
            all_empty: total = 0
            open_for_filling: not is_sealed
        end

feature -- Access
    definition_id: INTEGER_64

    count (a_verdict: BIB_VERDICT): INTEGER
        do Result := list_for (a_verdict).count end

    item (a_verdict: BIB_VERDICT; i: INTEGER): G
        require
            in_range: i >= 1 and i <= count (a_verdict)
        do Result := list_for (a_verdict) [i] end

    total: INTEGER
        do Result := fits.count + partial.count + fails.count + no_data.count end

    near_miss_count: INTEGER
        -- Findings flagged as near-misses, across buckets.

feature -- Status
    is_sealed: BOOLEAN

feature -- Model
    bucket_model (a_verdict: BIB_VERDICT): MML_SEQUENCE [G]
        do
            create Result
            across list_for (a_verdict) as ic loop Result := Result & ic.item end
        end

feature {BIB_CENSUS_ENGINE, BIB_SHAPE_ENGINE, BIB_SHAPE_PRECOMPUTE} -- Filling
    extend (a_finding: G)
        require
            not_sealed: not is_sealed
        do
            list_for (a_finding.verdict).extend (a_finding)
        ensure
            appended: bucket_model (a_finding.verdict) |=| (old bucket_model (a_finding.verdict) & a_finding)
            total_grown: total = old total + 1
        end

    seal
        require
            not_sealed: not is_sealed
        do
            is_sealed := True
        ensure
            sealed: is_sealed
        end

feature {NONE} -- Representation
    fits, partial, fails, no_data: ARRAYED_LIST [G]

    list_for (a_verdict: BIB_VERDICT): ARRAYED_LIST [G]
        do
            if a_verdict.is_fits then Result := fits
            elseif a_verdict.is_partial then Result := partial
            elseif a_verdict.is_fails then Result := fails
            else Result := no_data
            end
        end

invariant
    four_buckets_present: fits /= Void and partial /= Void and fails /= Void and no_data /= Void
    bound_to_definition: definition_id > 0
end
```

### BIB_REF, BIB_MAPPED_REF and BIB_VERSIFICATION_MAP

```eiffel
note
    description: "A parsed reference in one versification system; not comparable across versions until mapped."
class
    BIB_REF

create
    make, make_with_suffix

feature -- Access
    book_id: INTEGER        -- canonical id (vault bible_books.id, FR-105)
    chapter: INTEGER        -- 0 allowed for prologue chapters (Swete Esther)
    verse: INTEGER          -- 0 allowed for unnumbered titles
    suffix: STRING_8        -- "" or "a".."z" for lettered verses (3 Kgdms 2:35a)
    system: BIB_VERSIFICATION_SYSTEM

invariant
    book_positive: book_id > 0
    chapter_non_negative: chapter >= 0
    verse_non_negative: verse >= 0
    suffix_letters: across suffix as c all c.item.is_lower end
end

note
    description: "A reference that has passed the versification map: hub id, origin, rules applied. Only the map can create one (I-003)."
class
    BIB_MAPPED_REF

create {BIB_VERSIFICATION_MAP}
    make

feature {NONE} -- Initialization
    make (a_hub_id: INTEGER_64; a_origin: BIB_REF; a_rules: ARRAY [BIB_MAPPING_RULE])
        require
            hub_positive: a_hub_id > 0
        do
            hub_id := a_hub_id
            origin := a_origin
            rules := a_rules
        end

feature -- Access
    hub_id: INTEGER_64
    origin: BIB_REF
    rules_applied_count: INTEGER do Result := rules.count end

feature {NONE} -- Representation
    rules: ARRAY [BIB_MAPPING_RULE]

invariant
    hub_id_positive: hub_id > 0
end

note
    description: "Versification as data (D-010): TVTMS + the vault's verified LXX Jeremiah concordance + Swete entries. The only creator of BIB_MAPPED_REF."
class
    BIB_VERSIFICATION_MAP

create
    make

feature -- Mapping
    mapped (a_ref: BIB_REF): detachable BIB_MAPPED_REF
            -- Canonical identity of `a_ref`, or Void when no row maps it.
        require
            book_known: books.has_book (a_ref.book_id)
        do
            -- (Phase 4) look up versification_map; apply rule; create {BIB_MAPPED_REF}.make (...)
        ensure
            identity_kept: attached Result implies Result.origin ~ a_ref
        end

    pair (a_mapped: BIB_MAPPED_REF; a_target: BIB_VERSIFICATION_SYSTEM): BIB_PAIRING
            -- What `a_mapped` is called in `a_target`, with the rules used.
        do
            -- (Phase 4)
        ensure
            same_hub: Result.hub_id = a_mapped.hub_id
            identity_when_same_system: a_target ~ a_mapped.origin.system
                implies (Result.target_count = 1 and then Result.target (1) ~ a_mapped.origin)
            method_names_rules: Result.method.rules_count = Result.rules_count
        end

feature -- Model
    rules_model: MML_SET [BIB_MAPPING_RULE]

feature {NONE} -- Implementation
    books: BIB_BOOK_CATALOG
end
```

### BIB_PARSE_RESULT

```eiffel
note
    description: "Outcome of parsing reference text: exactly one of valid, ambiguous (with candidates) or invalid (with a position). Never a guess."
class
    BIB_PARSE_RESULT

create
    make_valid, make_ambiguous, make_invalid

feature -- Status
    is_valid, is_ambiguous, is_invalid: BOOLEAN

feature -- Access
    reference: detachable BIB_REF
    range_end: detachable BIB_REF
    system: detachable BIB_VERSIFICATION_SYSTEM     -- the system the parser assumed (named, FR-020)
    error_position: INTEGER
    error_message: STRING_32
    candidate_count: INTEGER
    candidate (i: INTEGER): BIB_REF
        require in_range: i >= 1 and i <= candidate_count
        do -- (Phase 4)
        end

feature -- Model
    candidates_model: MML_SEQUENCE [BIB_REF]

invariant
    exactly_one_state: (is_valid.to_integer + is_ambiguous.to_integer + is_invalid.to_integer) = 1
    valid_has_reference: is_valid implies (reference /= Void and system /= Void)
    ambiguous_has_choices: is_ambiguous implies candidate_count >= 2
    invalid_located: is_invalid implies error_position >= 1
end
```

### BIB_VERSION_INFO, BIB_VERSE_TEXT, BIB_OMISSION

```eiffel
note
    description: "Metadata of one shipped version; never a bare 'LXX' (FR-122)."
class
    BIB_VERSION_INFO

feature -- Access
    code: STRING_8                  -- "BSB", "WLC", "SWETE", "WH" ...
    display_label: STRING_32        -- "LXX (Swete)", "Judges (Swete; Codex B)"
    edition: STRING_32
    language: STRING_8             -- "hbo", "grc", "eng", "lat"
    system: BIB_VERSIFICATION_SYSTEM
    caveat: STRING_32               -- FR-005
    text_quality_caveat: STRING_32  -- Swete: "Digital text from OCR; it may contain errors."
    license: BIB_LICENSE
    provenance: BIB_PROVENANCE

feature -- Status
    is_septuagint: BOOLEAN
    is_swete: BOOLEAN
    is_right_to_left: BOOLEAN
    has_morphology: BOOLEAN         -- False for Swete (no open morphology)
    has_caveat: BOOLEAN do Result := not caveat.is_empty end
    has_book (a_book_id: INTEGER): BOOLEAN

invariant
    code_not_empty: not code.is_empty
    septuagint_labeled_with_edition: is_septuagint implies (not edition.is_empty and display_label.has_substring (edition))
    never_bare_lxx: not display_label.same_string ("LXX")
    swete_is_septuagint: is_swete implies is_septuagint
    swete_quality_caveat: is_swete implies not text_quality_caveat.is_empty
    rtl_for_hebrew: language.same_string ("hbo") implies is_right_to_left
end

note
    description: "Why a verse has no text in a version. Never an empty string (FR-009, I-005)."
class
    BIB_OMISSION

inherit
    BIB_ENUMERATION

create
    make

feature -- Constants
    Edition_omitted: INTEGER = 1      -- "omitted in this edition (WH)"
    Edition_absent: INTEGER = 2       -- "absent from Swete's edition" (Codex B gap)
    Digital_text_loss: INTEGER = 3    -- "missing from this digital text (OCR loss)"
    Not_in_canon: INTEGER = 4         -- Tobit in the BSB
    Quarantined: INTEGER = 5          -- defect-register class A

feature -- Access
    reason_text: STRING_32            -- shown in place of the verse
    is_quarantined: BOOLEAN do Result := code = Quarantined end
    is_valid_code (a_code: INTEGER): BOOLEAN do Result := a_code >= Edition_omitted and a_code <= Quarantined end
    label: STRING_32 do Result := reason_text end

invariant
    reason_given: not reason_text.is_empty
end

note
    description: "One verse in one version: exact display text (never edited) or an omission, with provenance and repair state."
class
    BIB_VERSE_TEXT

feature -- Access
    reference: BIB_REF
    version: BIB_VERSION_INFO
    display_text: detachable STRING_32       -- exact Unicode; MapM NBSP preserved (FR-008)
    omission: detachable BIB_OMISSION
    provenance: BIB_PROVENANCE
    repair_state: BIB_REPAIR_STATE           -- as-imported / repaired / collated (Swete; A-001)
    is_quarantined: BOOLEAN do Result := attached omission as o and then o.is_quarantined end

invariant
    text_xor_omission: (display_text /= Void) xor (omission /= Void)
    provenance_present: provenance /= Void
end
```

### BIB_NORMALIZER (deferred)

```eiffel
note
    description: "Search-form normalization shared by the build and the query path (D-009). Display never comes from it."
deferred class
    BIB_NORMALIZER

feature -- Normalization
    normalized (a_text: READABLE_STRING_GENERAL): STRING_32
        deferred
        ensure
            idempotent: normalized (Result).same_string (Result)
            no_combining_marks: not has_combining_mark (Result)
            not_longer: Result.count <= a_text.count
            empty_preserved: a_text.is_empty implies Result.is_empty
        end

feature -- Status
    has_combining_mark (a_text: READABLE_STRING_32): BOOLEAN
            -- Does `a_text` contain a nonspacing/enclosing/spacing combining mark (Mn/Me/Mc)? (via LG-01)
        deferred
        end
end
```

### BIB_CENSUS_DEFINITION

```eiffel
note
    description: "A question written down before counting (FR-025, I-002). Editable until the first run; then frozen and only versioned."
class
    BIB_CENSUS_DEFINITION

create
    make

feature {NONE} -- Initialization
    make (a_question: READABLE_STRING_GENERAL)
        require
            question_not_empty: not a_question.is_empty
        do
            question := a_question.to_string_32
            version := 1
            -- (Phase 4) lineage_id, empty criteria, corpus, controls, holds_if, fails_if; control_seed from a fixed generator stored here
        ensure
            first_version: version = 1
            editable: not is_frozen
        end

feature -- Access
    id: INTEGER_64                  -- 0 until stored
    lineage_id: INTEGER_64
    version: INTEGER
    question: STRING_32
    corpus_label: STRING_32
    corpus: BIB_SEARCH_SCOPE
    criteria: BIB_QUERY
    holds_if: STRING_32
    fails_if: STRING_32
    control_seed: INTEGER_64
    controls_count: INTEGER
    first_run_id: INTEGER_64

feature -- Status
    is_frozen: BOOLEAN
    is_stored: BOOLEAN do Result := id > 0 end
    is_complete: BOOLEAN
        do
            Result := not question.is_empty and not corpus_label.is_empty and criteria.clause_count > 0
                and controls_count >= 1 and not holds_if.is_empty and not fails_if.is_empty
        end

feature -- Model
    controls_model: MML_SEQUENCE [BIB_KEY]

feature -- Element change (only before the first run)
    set_question (a_text: READABLE_STRING_GENERAL)
        require
            not_frozen: not is_frozen
            text_not_empty: not a_text.is_empty
        do
            question := a_text.to_string_32
        ensure
            set: question.same_string_general (a_text)
            controls_unchanged: controls_model |=| old controls_model
        end

    add_control (a_key: BIB_KEY)
        require
            not_frozen: not is_frozen
            not_target: not criteria.mentions_key (a_key)
        do
            -- (Phase 4)
        ensure
            appended: controls_model |=| (old controls_model & a_key)
        end

    -- set_corpus, set_criteria, remove_control, set_holds_if, set_fails_if: same pattern (require not_frozen; frame on the others)

feature {BIB_CENSUS_ENGINE, BIB_CENSUS_JOB} -- Freezing
    freeze (a_run_id: INTEGER_64)
        require
            complete: is_complete
            not_frozen: not is_frozen
            run_id_positive: a_run_id > 0
        do
            is_frozen := True
            first_run_id := a_run_id
        ensure
            frozen: is_frozen
            first_run_recorded: first_run_id = a_run_id
            controls_unchanged: controls_model |=| old controls_model
        end

feature -- Versioning
    new_version: like Current
        require
            frozen: is_frozen
        do
            -- (Phase 4) deep copy content; version + 1; same lineage; not frozen; id = 0
        ensure
            next_version: Result.version = version + 1
            same_lineage: Result.lineage_id = lineage_id
            editable: not Result.is_frozen
            content_copied: Result.question.same_string (question) and Result.controls_model |=| controls_model
        end

invariant
    frozen_has_run: is_frozen implies first_run_id > 0
    version_positive: version >= 1
    seed_recorded: control_seed /= 0
end
```

### BIB_SHAPE (deferred) and BIB_SHAPE_ENGINE

```eiffel
note
    description: "A named structural pattern (shape.db). Definitions are written before the run; T3 shapes may frame a question, never score one."
deferred class
    BIB_SHAPE

feature -- Definition (all fixed before any run)
    slug: STRING_32 deferred end
    name: STRING_32 deferred end
    tier: BIB_SHAPE_TIER deferred end
    definition_formal: STRING_32 deferred end
    definition_prose: STRING_32 deferred end
    could_fail_if: STRING_32 deferred end
    seeded_by: STRING_32 deferred end           -- self / larry / vault:<file> / scholar:<name> / foil:<position>
    required_columns: ARRAY [STRING_8] deferred end
    corpus: BIB_SEARCH_SCOPE deferred end

feature -- Classification
    classify (a_candidate: BIB_SHAPE_CANDIDATE): BIB_SHAPE_FINDING
        require
            in_corpus: corpus.contains (a_candidate.reference)
        deferred
        ensure
            absent_tag_is_no_data: not a_candidate.has_required_tags (required_columns) implies Result.verdict.is_no_data
            tier_carried: Result.tier ~ tier
            grounds_given: not Result.grounds.is_empty
        end
end

note
    description: "Runs shapes (build) and returns their evidence (run time). Refuses T3 as evidence (ROE Rule 21 S3)."
class
    BIB_SHAPE_ENGINE

create
    make

feature -- Access
    registry: BIB_SHAPE_REGISTRY

feature -- Evidence
    evidence (a_shape: BIB_SHAPE): BIB_SHAPE_RUN
        require
            not_judgment: not a_shape.tier.is_judgment
            registered: registry.has_slug (a_shape.slug)
        do
            -- (Phase 4) read shape_instance by verdict, all four, ordered by reference
        ensure
            sealed: Result.buckets.is_sealed
            tier_carried: Result.tier ~ a_shape.tier
            method_recorded: Result.method.engine_feature.same_string ("shape")
        end
end
```

### BIB_QUOTATION_RESULT

```eiffel
note
    description: "They Chose: NT, LXX (Swete) and MT side by side with the computed agreement class and an edition note."
class
    BIB_QUOTATION_RESULT

inherit
    BIB_ENGINE_RESULT

feature -- Access
    quotation: detachable BIB_QUOTATION
    alignment: detachable BIB_ALIGNMENT
    agreement: BIB_AGREEMENT_CLASS
    verdict_line: STRING_32          -- "Heb 8:8-12 agrees with the Septuagint (LXX Jer 38:31-34) against the Hebrew (MT Jer 31:31-34)"
    edition_note: STRING_32          -- "Computed against Swete; may differ for Rahlfs." (+ OCR note)
    lxx_from_uncollated_ocr: BOOLEAN

invariant
    edition_note_present: not edition_note.is_empty
    verdict_needs_alignment: not agreement.is_no_data implies alignment /= Void
    ocr_flagged: lxx_from_uncollated_ocr implies edition_note.has_substring ("OCR")
end
```

### BIB_RELATED_PASSAGE and BIB_AUTHOR_DOC

```eiffel
note
    description: "A related passage with the reason it is listed; AI-made neighbors are always labeled (D-016, NFR-014)."
class
    BIB_RELATED_PASSAGE

feature -- Access
    target: BIB_REF
    reason_count: INTEGER
    reason (i: INTEGER): STRING_32       -- "cross-reference (OpenBible, 57 votes)", "shares a rare word", "AI-made: meaning neighbor"
        require in_range: i >= 1 and i <= reason_count
        do -- (Phase 4)
        end
    is_ai_made: BOOLEAN
    ai_label: STRING_32
    provenance: BIB_PROVENANCE

invariant
    has_reason: reason_count >= 1
    ai_made_has_label: is_ai_made implies not ai_label.is_empty
    ai_flag_matches_provenance: is_ai_made = provenance.is_ai_made
end

note
    description: "A document in Larry's author library (the rix stage, shipped inside content.db; fold 2026-10-26, debate 01). Status travels with it everywhere (D-019)."
class
    BIB_AUTHOR_DOC

feature -- Access
    doc_id: INTEGER_64
    title: STRING_32
    relpath: STRING_32
    collection: STRING_32
    status: BIB_DOC_STATUS              -- framework / verdict / draft / unmarked / withdrawn / ungated
    voice: BIB_VOICE                    -- author
    banner_text: STRING_32              -- "Withdrawn by the author. Kept for the record; not authority." etc.
    provenance: BIB_PROVENANCE

feature -- Status
    cites (a_hub_id: INTEGER_64): BOOLEAN

invariant
    status_valid: status.is_valid_code (status.code)
    voice_author: voice.is_author
    title_present: not title.is_empty
    banner_for_flagged: (status.is_withdrawn or status.is_ungated or status.is_draft) implies not banner_text.is_empty
end
```

### BIB_AI_ADAPTER, BIB_AI_POST_CHECK, BIB_AI_TEXT

```eiffel
note
    description: "Optional AI phrasing of one engine answer. Release 1 binds the null adapter. Input is an engine result, never free text (I-001)."
deferred class
    BIB_AI_ADAPTER

feature -- Explanation
    explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
        require
            engine_answer: a_result.is_success
            cited: a_result.citation_count > 0
        deferred
        ensure
            rests_on_input: attached Result implies Result.basis = a_result
            labeled: attached Result implies Result.is_labeled
        end
end

class
    BIB_NULL_AI_ADAPTER

inherit
    BIB_AI_ADAPTER

feature -- Explanation
    explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
        do
            -- Release 1: no model runs on the user's machine (D-016).
        ensure then
            never_produces: Result = Void
        end
end

note
    description: "The FR-053 post-check and the only creator of BIB_AI_TEXT."
class
    BIB_AI_POST_CHECK

feature -- Factory
    checked (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL): BIB_AI_TEXT
        require
            basis_success: a_basis.is_success
            basis_cited: a_basis.citation_count > 0
            model_named: not a_model_id.is_empty
        do
            create Result.make (a_wording, a_basis, a_model_id,
                has_unsupported_digit (a_wording, a_basis)
                or has_unsupported_reference (a_wording, a_basis)
                or has_unsupported_script (a_wording, a_basis))
        ensure
            basis_kept: Result.basis = a_basis
            withheld_if_new_facts: (has_unsupported_digit (a_wording, a_basis) or has_unsupported_reference (a_wording, a_basis)
                or has_unsupported_script (a_wording, a_basis)) implies Result.is_withheld
        end

feature -- Checks
    has_unsupported_digit (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
    has_unsupported_reference (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
    has_unsupported_script (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
            -- Any digit run, reference pattern (via BIB_REFERENCE_DETECTOR) or Hebrew/Greek run (via BIB_SCRIPT_CLASSIFIER)
            -- in `a_wording` that the rendered basis does not contain.
end

note
    description: "Model wording about one engine answer: labeled, post-checked, never a fact source."
class
    BIB_AI_TEXT

create {BIB_AI_POST_CHECK}
    make

feature {NONE} -- Initialization
    make (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL; a_withheld: BOOLEAN)
        do
            basis := a_basis
            model_id := a_model_id.to_string_32
            is_withheld := a_withheld
            if a_withheld then create displayable_text.make_empty else displayable_text := a_wording.to_string_32 end
            label := Ai_label
        end

feature -- Access
    basis: BIB_ENGINE_RESULT
    displayable_text: STRING_32
    model_id: STRING_32
    label: STRING_32
    is_withheld: BOOLEAN
    is_labeled: BOOLEAN do Result := label.same_string (Ai_label) end

feature -- Constants
    Ai_label: STRING_32 = "AI wording; the facts above are from the engine"

invariant
    label_present: is_labeled
    cites_engine: basis.is_success and basis.citation_count > 0
    model_named: not model_id.is_empty
    withheld_text_hidden: is_withheld implies displayable_text.is_empty
end
```

### BIB_JOB [R], BIB_CANCEL_TOKEN, BIB_JOB_MAILBOX

```eiffel
note
    description: "Chunked long work on its own SCOOP processor. Reports through a separate mailbox and stops through a separate token (A-006); one chunk = one book or one guide section (A-005)."
deferred class
    BIB_JOB [R -> BIB_ENGINE_RESULT]

feature -- Status
    is_started, is_done, is_cancelled, has_result: BOOLEAN
    chunks_done, chunk_total: INTEGER

feature -- Execution
    run_to_completion (a_token: separate BIB_CANCEL_TOKEN; a_mailbox: separate BIB_JOB_MAILBOX)
        require
            not_started: not is_started
        do
            is_started := True
            from until is_done loop
                if cancel_requested (a_token) then
                    is_cancelled := True; is_done := True
                    close_cancelled (a_mailbox)
                else
                    step
                    report (a_mailbox)
                end
            end
            if not is_cancelled then close_finished (a_mailbox) end
        ensure
            finished: is_done
            cancel_observed: is_cancelled implies not has_result
        end

    step
            -- Process exactly one bounded chunk.
        require
            started: is_started
            not_finished: not is_done
        deferred
        ensure
            progressed: chunks_done = old chunks_done + 1 or is_done
        end

feature -- Result
    result_value: R
        require
            done: is_done
            not_cancelled: not is_cancelled
            succeeded: has_result
        deferred
        end

feature {NONE} -- Mailbox and token access (short separate calls)
    cancel_requested (a_token: separate BIB_CANCEL_TOKEN): BOOLEAN
        do Result := a_token.is_cancel_requested end
    report (a_mailbox: separate BIB_JOB_MAILBOX) deferred end
    close_cancelled (a_mailbox: separate BIB_JOB_MAILBOX) do a_mailbox.close_cancelled end
    close_finished (a_mailbox: separate BIB_JOB_MAILBOX) deferred end

invariant
    progress_bounded: chunks_done >= 0 and chunks_done <= chunk_total
    cancelled_has_no_result: is_cancelled implies not has_result
end

note
    description: "A cancel request shared between the GUI and one job; lives on its own processor so the GUI never waits on the job."
class
    BIB_CANCEL_TOKEN

create
    make

feature {NONE} -- Initialization
    make do ensure not is_cancel_requested end

feature -- Status
    is_cancel_requested: BOOLEAN

feature -- Command
    request_cancel
        do is_cancel_requested := True ensure requested: is_cancel_requested end
            -- Monotone: no reset feature exists.
end

note
    description: "Progress, pages and the final outcome of one job, as copied plain values; written by the job, polled by the GUI."
class
    BIB_JOB_MAILBOX

create
    make

feature -- Status
    progress: REAL_64
    page_count: INTEGER
    is_closed, is_done, is_cancelled, is_failed: BOOLEAN
    error_text: STRING_32

feature -- Access
    page (n: INTEGER): BIB_JOB_PAGE
        require in_range: n >= 1 and n <= page_count
        do -- (Phase 4)
        end

feature -- Model
    pages_model: MML_SEQUENCE [BIB_JOB_PAGE]

feature -- Commands (called by the job)
    post_page (a_page: BIB_JOB_PAGE)
        require
            open: not is_closed
            next_in_order: a_page.number = page_count + 1
        do -- (Phase 4) store a copy
        ensure
            appended: pages_model |=| (old pages_model & a_page)
            progress_unchanged: progress = old progress
        end

    set_progress (a_fraction: REAL_64)
        require
            in_range: a_fraction >= 0.0 and a_fraction <= 1.0
            monotone: a_fraction >= progress
        do progress := a_fraction
        ensure set: progress = a_fraction
        end

    close_done, close_cancelled
    close_failed (a_error: STRING_32)
        -- Each ensures: is_closed; exactly one outcome; close_cancelled drops pages (page_count = 0).

invariant
    progress_bounded: progress >= 0.0 and progress <= 1.0
    outcome_exclusive: is_closed implies (is_done.to_integer + is_cancelled.to_integer + is_failed.to_integer) = 1
    cancelled_discards: is_cancelled implies page_count = 0
end
```

### BIB_SOURCE_SET

```eiffel
note
    description: "One SQLite connection per processor (DR-019): one read-only main (content.db) with its attached packs (at most 10 pack slots, DR-020), each attached read-only through `attach_read_only` (fold 2026-10-26, settlement S1; was "through the query path"). Never passed between processors. (fold 2026-10-26, debates 01, 03, 05a; was 'with its attached databases (at most 10, DR-020)')"
class
    BIB_SOURCE_SET

create
    make

feature -- Status
    is_open: BOOLEAN
    attached_count: INTEGER
    sqlite_version: STRING_32
    last_error: detachable BIB_ERROR

feature -- Model
    attached_model: MML_MAP [STRING_8, STRING_32]

feature -- Commands
    open_core (a_path: READABLE_STRING_GENERAL)
        require not_open: not is_open
        do -- (Phase 4) SIMPLE_SQL_DATABASE.make_read_only on content.db; record sqlite_version
           -- (fold 2026-10-26, debate 01: `open_core` opens the one content main; was core.db)
        ensure open_or_error: is_open xor (last_error /= Void)
        end

    attach (a_alias: STRING_8; a_path: READABLE_STRING_GENERAL)
        require
            open: is_open
            alias_valid: is_valid_alias (a_alias)
            not_attached: not attached_model.domain [a_alias]
            under_limit: attached_count < Max_attached
        do -- (Phase 4) SIMPLE_SQL_DATABASE.attach_read_only (a_path, a_alias) on the read-only main
           -- (fold 2026-10-26, debates 01, 03, 05a; was "ATTACH DATABASE ... AS <alias> (read-only URI)":
           -- the `file:...?mode=ro` form through perform/execute is dropped; the pack's user_version, voice
           -- column and provenance are checked per named schema; attach number 11 reports SQLite's own message)
        ensure
            attached_now: last_error = Void implies attached_model |=| old attached_model.updated (a_alias, a_path.to_string_32)
            count_grown: last_error = Void implies attached_count = old attached_count + 1
        end

feature -- Constants
    Max_attached: INTEGER = 10
            -- Counts pack slots only (the main is content.db; user.db is not on engine connections);
            -- an attach policy (attach on demand, or a slot cap) is specified (fold 2026-10-26, debate 01).

feature -- Status (concordance)
    is_attached_alias (a_alias: STRING_8): BOOLEAN
            -- Is a pack attached under `a_alias'? (used by BIB_CONC_PACK.is_available; fold 2026-10-26, debate 05)

invariant
    within_limit: attached_count >= 0 and attached_count <= Max_attached
end
```

### BIB_LICENSE_GATE, BIB_BUILD_STEP and BIB_DISTRIBUTION_BUILDER (L-BUILD)

```eiffel
note
    description: "The build's refusal to ship unknown or restricted sources (FR-004); records NC and SA clauses."
class
    BIB_LICENSE_GATE

feature -- Decision
    ship_allowed (a_source: BIB_PINNED_SOURCE): BOOLEAN
        do
            Result := a_source.ship and a_source.license.may_ship_in_free_tool
        ensure
            unknown_refused: a_source.license.is_unknown implies not Result
            restricted_refused: a_source.license.is_restricted implies not Result
            flag_respected: not a_source.ship implies not Result
        end

    check_manifest (a_manifest: BIB_BUILD_MANIFEST)
        do -- (Phase 4)
        ensure
            refusal_named: has_refusal implies across refused_keys as k all refusal_message.has_substring (k.item) end
        end

feature -- Status
    has_refusal: BOOLEAN
    refused_keys: ARRAYED_LIST [STRING_8]
    refusal_message: STRING_32
end

note
    description: "One deterministic stage of a build: no clock reads, ordered output, progress and a named error."
deferred class
    BIB_BUILD_STEP

feature -- Access
    name: STRING_8 deferred end
    last_error: detachable BIB_ERROR
    rows_written: INTEGER_64

feature -- Execution
    execute (a_context: BIB_BUILD_CONTEXT; a_db: SIMPLE_SQL_DATABASE)
        require
            context_ready: a_context.is_ready
            writable: not a_db.is_read_only
        deferred
        ensure
            provenance_for_rows: last_error = Void implies rows_without_provenance (a_db) = 0
        end

feature -- Status
    rows_without_provenance (a_db: SIMPLE_SQL_DATABASE): INTEGER_64
        deferred end
end

note
    description: "Builds the core stage from pinned sources (D-005): verify, gate, import, repair, defect rules, normalize, map, FTS, checksum, credits; a separate assembly step then writes content.db from the stages (fold 2026-10-26, debate 01; was \"Assembles core.db from pinned sources\")."
class
    BIB_DISTRIBUTION_BUILDER

feature -- Execution
    build (a_context: BIB_BUILD_CONTEXT)
        require
            manifest_hashes_verified: a_context.manifest.all_hashes_verified
            gate_passed: not a_context.license_gate.has_refusal
            steps_registered: steps_model.count > 0
        do -- (Phase 4) run each step in order inside a transaction per step; stop at the first error
        ensure
            all_rows_have_provenance: succeeded implies rows_without_provenance = 0
            no_unknown_license_shipped: succeeded implies shipped_unknown_license_count = 0
            checksums_recorded: succeeded implies checksum_count = table_count
            credits_generated: succeeded implies credits_match_provenance
            steps_unchanged: steps_model |=| old steps_model
        end

feature -- Status
    succeeded: BOOLEAN
    rows_without_provenance, shipped_unknown_license_count: INTEGER_64
    checksum_count, table_count: INTEGER
    credits_match_provenance: BOOLEAN

feature -- Model
    steps_model: MML_SEQUENCE [BIB_BUILD_STEP]
end
```

### BIB_PLUGIN_REGISTRY (removed; fold 2026-10-26, debate 03)

`BIB_PLUGIN_REGISTRY` (compiled-in private plug-ins, A-012; `plugin_count`, `is_sealed`, `has_plugin`, `plugins_model`, `register`, `seal`) is **removed**: the public engine has no private code seam in Release 1. Private material arrives as versioned data packs read by generic public features (B′, section "Private packs, plug-in seam B′" above). `BIB_PRIVATE_SOURCE` becomes an effective generic pack source; `BIB_LENS_RESULT` keeps `voice_attached` with `plugin_name` becoming the pack name; `BIB_LIBRARY_ENTRY.make` gains `a_voice: BIB_VOICE`. (Old class text deleted; quoted in the Fold log of `00-FOLD-2026-10-26.md`.)

### BIB_SOURCE_SET after the fold

See the class text of `BIB_SOURCE_SET`: one main (`content.db`), `Max_attached` counts pack slots only, packs attach through `attach_read_only` (fold 2026-10-26, debates 01, 03, 05a). The concordance classes are specified in "Concordance pack and edition swap" and in 04 and 05 (fold 2026-10-26, debate 05).

## Remaining classes (interface by reference)

The remaining Release 1 classes follow the contracts in 05 and the interfaces in 06; their one-line responsibilities are in 04 §1. Notable obligations carried into /eiffel.contracts:

- `BIB_HEBREW_NORMALIZER`, `BIB_GREEK_NORMALIZER`, `BIB_ENGLISH_NORMALIZER`: `ensure then` clauses of 05; Greek waits on LG-01.
- `BIB_REFERENCE_DETECTOR`: function-for-function port of `build_rix_db.py` R12 (alias table, colon and period forms, de-duplication) plus `scripture_detect.py`'s explicit detector; golden fixtures from both scripts.
- `BIB_QUOTATION_DETECTOR`: shingle matcher (MIN_N 6, MAX_N 14) reporting match length; never treated as evidence until read.
- `BIB_RIX_DB_BUILDER`, `BIB_RIX_RULES`, `BIB_VAULT_WALKER`, `BIB_VAULT_DOCUMENT`: rules R1-R15 v2.1 exactly; accepted by `BIB_DB_COMPARATOR` at 100% against `build_rix_db.py`'s output on the same vault snapshot (`--max-mtime`).
- `BIB_SWETE_REPAIR`: the 12-SEPTUAGINT build checklist as postconditions (`no_verse_starts_with_roman_numeral_without_repair`, `every_gap_classified`, `apparatus_dropped`).
- `BIB_CENSUS_ENGINE`, `BIB_CONTROL_SET`, `BIB_CENSUS_RUN`, `BIB_SEARCH_ENGINE`, `BIB_QUOTATION_COMPARER`, `BIB_AUTHOR_LIBRARY`, `BIB_EXPORTER`, `BIB_GUIDE`, `BIB_COMMAND_SET`, `BIB_LINK_HUB`, `BIB_RESULT_ADAPTER`: 05's contracts verbatim.

## Dependencies

All libraries below were confirmed present in the fleet's root folder on 2026-10-06 (ECF file named). Versions are the `package.json` / CHANGELOG values seen today where present.

| Library | ECF | Purpose | Layer | Version seen |
|---------|-----|---------|-------|--------------|
| simple_sql | `simple_sql/simple_sql.ecf` | All SQLite access, FTS5, read-only open, vector store (v2) | LIB | 0.1.0 (package.json) |
| eiffel_sqlite_2025 | `eiffel_sqlite_2025/sqlite_2025.ecf` (through simple_sql) | SQLite 3.53.4 binding (1.1.0, FT-01 landed; 3.31.1 before it); six `blocking` externals (FT-02); no hook guard (`e80c57c` made Eiffel callbacks safe under `blocking`; fold 2026-10-26, settlement S3; was "Eiffel callbacks refused by a guard"); the Release 1 DDL ceiling stays 3.31.1 (fold 2026-10-26, debate 04; was "SQLite 3.31.1 binding; FT-01/FT-02") | LIB | 1.1.0 (SQLite 3.53.4) |
| simple_mml | `simple_mml/simple_mml.ecf` | Model queries in postconditions | LIB | - |
| simple_encoding | `simple_encoding/simple_encoding.ecf` | UTF-8/32; NFD/NFC + Mn after LG-01 | LIB | - |
| simple_regex | `simple_regex/simple_regex.ecf` | Regex search, reference patterns, checks | LIB | 1.0.1 |
| simple_json | `simple_json/simple_json.ecf` | Method records, user-store payloads, golden fixtures | LIB | 0.2.0 |
| simple_hash | `simple_hash/simple_hash.ecf` | SHA-256 (manifest, checksums, fixtures) | LIB, BUILD | 0.1.0 |
| simple_diff | `simple_diff/simple_diff.ecf` | LCS diff under `BIB_TOKEN_DIFF` (token keys mapped to ASCII lines) | LIB | - |
| simple_file | `simple_file/simple_file.ecf` | Paths, data-folder discovery; atomic export write, file-safe names (F-1, F-4, F-2, F-5, F-SN; fold 2026-10-26, debate 02) | LIB | 0.1.0 (1.1.0 lists stream-name handling) |
| simple_yaml | `simple_yaml/simple_yaml.ecf` | Notes export front matter (`to_yaml`) and import (parse), Release 1a (fold 2026-10-26, debate 02) | LIB | - |
| simple_toml | `simple_toml/simple_toml.ecf` | `bible.toml` configuration | LIB | 0.1.2 |
| simple_logger | `simple_logger/simple_logger.ecf` | Diagnostics | LIB | 0.1.0 |
| simple_datetime | `simple_datetime/simple_datetime.ecf` | User-record dates, memory scheduling (never in builders' rows) | LIB | 0.1.1 |
| simple_xml | `simple_xml/simple_xml.ecf` | OSIS (OSHB) and TEI (Swete) imports | BUILD | 0.1.0 |
| simple_csv | `simple_csv/simple_csv.ecf` | TSV imports (STEPBible, MACULA, OpenBible) | BUILD | 0.1.0 |
| simple_onnx | `simple_onnx/simple_onnx.ecf` | bge-m3 embeddings at build time (ONNX Runtime 1.17.3, CPU) | BUILD (v2: LIB) | - |
| simple_graph | `simple_graph/simple_graph.ecf` | Passage graph for related-passage precompute | BUILD | 0.1.0 |
| simple_cli | `simple_cli/simple_cli.ecf` | `bible.exe` and `bible_build` arguments | CLI, BUILD | 0.1.0 |
| simple_console | `simple_console/simple_console.ecf` | REPL | CLI | 1.2.0 |
| simple_widgets | `simple_widgets/simple_widgets.ecf` | Native face | GUI | 0.8.1 (README) |
| simple_shaping | `simple_shaping/simple_shaping.ecf` | Shaped Hebrew/Greek, bidi | GUI | 0.1.0 pre-release |
| simple_cairo | `simple_cairo/simple_cairo.ecf` | Canvas | GUI | 1.3.0 + Unreleased |
| simple_shell | `simple_shell/simple_shell.ecf` | Window, pump, keys | GUI | 1.12.0 |
| simple_testing | `simple_testing/simple_testing.ecf` | `TEST_SET_BASE` suites | Tests | 0.1.0 |
| simple_process | `simple_process/simple_process.ecf` | Hidden llama-server spawn (externals marked `blocking`, PR #1) | v3 | 1.0.1 |
| simple_winhttp | `simple_winhttp/simple_winhttp.ecf` | Loopback and BYOK calls (`c_send` marked `blocking`) | v3 | 0.1.1 |

**Not used:** simple_http (libcurl not redistributable, C-009), simple_browser/simple_web/simple_htmx/simple_alpine (WebView2 path withdrawn by D-006), Vision2/simple_vision, any Python.

**C code:** none planned. Reserved prefix `sbib_`.

## File Structure

```
simple_bible\
├── simple_bible.ecf                  (targets: simple_bible, bible_build, bible, simple_bible_app, simple_bible_tests)
├── README.md, CHANGELOG.md, docs\index.html   (C-018)
├── src\                              (L-LIB)
│   ├── simple_bible.e  bib_config.e
│   ├── core\        bib_enumeration.e bib_book.e bib_book_catalog.e bib_versification_system.e bib_ref.e
│   │                bib_ref_range.e bib_mapped_ref.e bib_key.e bib_lemma_key.e bib_strongs_key.e bib_morph_code.e bib_word_id.e
│   ├── provenance\  bib_license.e bib_provenance.e bib_grade.e bib_voice.e bib_fact.e bib_method.e
│   │                bib_engine_result.e bib_list_result.e bib_error.e bib_verdict.e bib_finding.e bib_bucketed_result.e
│   ├── data\        bib_data_source.e bib_content_source.e bib_user_store.e bib_source_set.e
│   │                (fold 2026-10-26, debate 01: bib_core_source.e and bib_ai_data_source.e collapse into one content source)
│   ├── concordance\ bib_conc_pack.e bib_word_lookup.e bib_english_index.e bib_verse_words.e bib_word_entry.e
│   │                bib_place_row.e bib_english_row.e bib_verse_word.e bib_word_view.e
│   │                (fold 2026-10-26, debate 05b: as compiled in debate/05.../spikes/skeletons/B/new/)
│   ├── text\        bib_normalizer.e bib_hebrew_normalizer.e bib_greek_normalizer.e bib_english_normalizer.e
│   │                bib_stemmer.e bib_stop_words.e bib_pointing_reducer.e bib_transliterator.e bib_script_classifier.e
│   │                bib_edit_distance.e bib_normalizer_set.e
│   ├── reference\   bib_reference_parser.e bib_parse_result.e bib_reference_detector.e bib_quotation_detector.e
│   ├── versification\ bib_versification_map.e bib_mapping_rule.e bib_pairing.e
│   ├── hub\         bib_verse_hub.e bib_version_info.e bib_verse_text.e bib_omission.e bib_word.e
│   │                bib_verse_result.e bib_cross_reference.e bib_morph_expander.e bib_repair_state.e
│   ├── search\      bib_query.e bib_query_clause.e bib_query_parser.e bib_search_scope.e bib_search_engine.e
│   │                bib_search_result.e bib_hit.e bib_concordance.e bib_count_table.e bib_rank_fusion.e bib_token_diff.e
│   ├── census\      bib_census_definition.e bib_control_set.e bib_census_engine.e bib_census_run.e bib_control_comparison.e
│   ├── shape\       bib_shape.e bib_shape_tier.e bib_shape_registry.e bib_shape_engine.e bib_shape_run.e
│   │                bib_shape_finding.e bib_shape_lint.e bib_shape_candidate.e  shapes\bib_shape_<slug>.e
│   ├── quotation\   bib_quotation_index.e bib_quotation.e bib_alignment.e bib_agreement_class.e
│   │                bib_quotation_comparer.e bib_quotation_result.e
│   ├── study\       bib_range_viewer.e bib_range_result.e bib_word_journey.e bib_journey_result.e bib_divine_name_marker.e
│   │                bib_guide_assembler.e bib_guide.e bib_guide_section.e bib_related_passages.e bib_related_passage.e
│   │                bib_library.e bib_library_entry.e bib_proper_names.e
│   ├── user\        bib_user_item.e bib_note.e bib_highlight.e bib_bookmark.e bib_tag_assignment.e bib_prayer_item.e
│   │                bib_memory_card.e bib_visit.e bib_collection.e bib_memory_scheduler.e bib_reading_plan.e
│   │                bib_note_store.e bib_db_note_store.e bib_markdown_note_store.e bib_user_backup.e
│   ├── checks\      bib_check.e bib_check_finding.e bib_check_runner.e bib_check_first_use_gloss.e bib_check_bare_script.e
│   │                bib_check_capital_after_colon.e bib_check_citation_complete.e bib_check_provenance_tag.e
│   ├── author\      bib_author_library.e bib_author_doc.e bib_doc_status.e
│   ├── export\      bib_exporter.e bib_attribution.e
│   ├── jobs\        bib_job.e bib_search_job.e bib_census_job.e bib_guide_job.e bib_cancel_token.e bib_job_mailbox.e bib_job_page.e
│   ├── pack\        bib_private_source.e bib_lens_result.e
│   │                (fold 2026-10-26, debate 03: the plugin\ cluster is dropped: bib_plugin.e, bib_plugin_registry.e, bib_lens.e removed;
│   │                bib_private_source.e becomes an effective generic pack source; the verdict removes the plug-in folder but names no replacement: `pack\` and `bib_content_source.e` (which stands for "one content source") are names proposed by the fold; fixed in Phase 4)
│   └── ai\          bib_ai_adapter.e bib_null_ai_adapter.e bib_ai_text.e bib_ai_post_check.e
├── build\                            (L-BUILD; 44 classes; root bib_build_app.e)
│   ├── pipeline\    bib_build_app.e bib_build_context.e bib_build_manifest.e bib_pinned_source.e bib_license_gate.e
│   │                bib_build_step.e bib_distribution_builder.e bib_schema_step.e bib_book_catalog_step.e
│   ├── import\      bib_import_oshb.e bib_import_morphgnt.e bib_import_macula_greek.e bib_import_swete.e
│   │                bib_import_plain_text_version.e bib_import_stepbible.e bib_import_strongs.e
│   │                bib_import_cross_references.e bib_import_ubs_parallels.e bib_import_library_module.e
│   ├── rules\       bib_swete_repair.e bib_defect_rule.e bib_defect_rules_step.e bib_normalize_step.e
│   │                bib_versification_step.e bib_fts_step.e bib_table_checksum.e bib_credits_generator.e
│   ├── verify\      bib_db_comparator.e bib_compare_spec.e bib_compare_report.e
│   ├── rix\         bib_rix_db_builder.e bib_rix_rules.e bib_vault_walker.e bib_vault_document.e
│   └── precompute\  bib_precompute_job.e bib_lemma_frequency_precompute.e bib_gloss_table_precompute.e
│                    bib_related_precompute.e bib_embedding_precompute.e bib_alignment_precompute.e
│                    bib_shape_precompute.e bib_sparse_vector.e bib_tfidf_index.e bib_passage_graph.e
├── cli\                              (L-CLI) bib_cli_app.e bib_repl.e bib_command.e bib_command_set.e
│                                      bib_command_parser.e bib_text_renderer.e bib_command_outcome.e  commands\bib_cmd_<name>.e
├── gui\                              (L-GUI) bib_gui_app.e bib_main_window.e bib_panel.e bib_link_hub.e bib_active_reference.e
│                                      bib_layout_store.e bib_state_machine.e bib_engine_client.e bib_result_adapter.e
│                                      bib_provenance_chip.e bib_job_monitor.e bib_job_handle.e bib_word_card.e
│                                      panels\bib_p01_bible_text.e .. bib_p11_navigator.e  dialogs\bib_d01_go_to.e .. bib_d10_ambiguous_reference.e
├── fonts\                            (OFL fonts with license files; provenance rows; GW-01)
├── installer\simple_bible.iss        (from ledger I-01; core edition)
└── test\
    ├── test_app.e  lib_tests.e       (fleet test convention; TEST_SET_BASE)
    ├── test_reference_parser.e  test_versification.e  test_verse_hub.e  test_normalizers.e  test_search.e
    ├── test_census.e  test_shapes.e  test_quotation.e  test_study.e  test_author_library.e  test_user_store.e
    ├── test_jobs_scoop.e  test_gc_probe.e (NFR-016)  test_ai_seam.e  test_pack_purity.e (FR-NEW-010; was test_plugin_purity, re-specified to K2′: no private string in ASCII, UTF-16LE or UTF-32LE; fold 2026-10-26, debate 03; `test_pack_purity` name proposed by the fold; fixed in Phase 4)  test_concordance.e (fold 2026-10-26, debate 05: spikes S1 attach-and-word-view and S2 translit-cost rerun as tests; first-screen measurement; name proposed by the fold; fixed in Phase 4)
    ├── test_layering.e (no SQL in gui/ or cli/; banned accessors; static join check FR-024)
    ├── test_build_determinism.e  test_license_gate.e  test_defect_register.e (A1, B1-B4, C, D, E1-E11)
    ├── test_rix_differential.e  test_shape_differential.e  test_detector_differential.e (D-020 ports)
    ├── test_cli_commands.e  gui\test_panels_offscreen.e  gui\test_state_machines.e
    └── fixtures\  (small content.db fixture assembled from small stage fixtures; golden outputs with SHA-256; vault snapshot for the rix stage; never private data; fold 2026-10-26, debate 01)
```

## Phase plan (one Spec Kit pass per phase, C-011)

| Phase | Scope | Depends on |
|-------|-------|-----------|
| P0 spike | D-006 spike offscreen (Gen 1:1 WLC with cantillation, Gen 1:1 LXX Swete, John 1:1 WH in `SW_LABEL`/`SW_TEXT_BOX`); file GW-01..03 defects | simple_widgets owners |
| P1 build core | L-BUILD: manifest, gate, catalog, importers for core texts, Swete repair, defect rules, normalize (LG-01), versification, FTS (stage index verified, shipped index contentless), checksums, credits, and the assembly step that writes `content.db` from the stages (fold 2026-10-26, debate 01) | LG-01 |
| P2 engine | L-LIB: core, provenance, data, concordance, text, reference, versification, hub, search, census, shapes, quotation, study, author, export, checks, user (with note export and import), jobs, pack seam, ai seam (fold 2026-10-26, debates 02, 03, 05; was "..., user, jobs, plugin, ai seam") | P1 fixture DB; **F-9 and the P-ATOMIC probes passing before the `user` cluster's tests count** (debate 02) |
| P3 ports | rix stage builder, detectors, shapes, precompute; differential tests vs golden outputs; for the distribution edition only, the conc_dist.db Eiffel builder with its `BIB_TRANSLITERATOR` differential test against `conc_translit.py` (fold 2026-10-26, D-021) | P1, P2 |
| P4 CLI | L-CLI; simple_chat retarget (ledger R-6) | P2 |
| P5 GUI | L-GUI panels in gap order (03 A-011); native simple_widgets, every GW gap done (fold 2026-10-26, D-006); the concordance word view, English lookup and verse lookup (personal edition first, D-021) | P0, GW items, FT-02 (landed), every dependent rebuilt `-clean` after FT-02 (fold 2026-10-26, debate 04) |
| P6 installer | core edition (public: no conc pack; the personal edition is the same executable plus the private pack and is never installed publicly), OFL fonts, non-live identity verification (fold 2026-10-26, D-021) | P4, P5 |
