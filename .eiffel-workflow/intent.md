# Intent: simple_bible

*Phase 0 (/eiffel.intent), step 3: initial intent, 2026-10-06. Pre-populated from `spec/07-SPECIFICATION.md`, `spec/01-PARSED-REQUIREMENTS.md`, `spec/03-CHALLENGED-ASSUMPTIONS.md`, `spec/08-VALIDATION.md`, and Larry's binding answers in `spec/09-LARRY-ANSWERS (2026-10-06).md` (Q-01 to Q-16, "all as recommended"). Context: `research/04-DECISIONS.md` (D-001 to D-020), `research/13-USER-VOICE.md`, `research/10-INNOVATIONS FROM PRACTICE.md`, `gui/00-GUI-SPEC.md`. The reviewed and refined version is `intent-v2.md`; where the two differ, intent-v2 governs.*

---

## What

simple_bible is a free Windows Bible-study workbench. A deterministic Eiffel engine over SQLite does all the counting, lookup, comparison and checking of the Hebrew, Greek and English text, and every fact it returns carries its source and license. It is built as four parts in one repository:

1. **An engine library** (`SIMPLE_BIBLE` facade, `BIB_` classes). Every answer is a result object with a method record and citations. Census and shape answers always carry FITS, PARTIAL, FAILS and NO_DATA together. Cross-version pairing happens only through the versification map. AI text can be created only from an engine answer and is always labeled.
2. **A build pipeline** (`bible_build`). It assembles `core.db`, `ai_data.db` and `rix.db` from pinned upstream sources and Larry's vault, under a license gate, deterministically, with generated credits. It hosts the Eiffel ports of the vault's Python tools, each accepted by a differential test against golden outputs (D-020).
3. **Two faces** that depend only on engine abstractions: a native simple_widgets GUI (Simple and Study layouts) and a CLI/REPL (`bible.exe`) with a closed, read-only command set.
4. **A private plug-in seam** (deferred interfaces only in the public build). Larry's separate repository implements it at compile time.

Release 1 runs no AI on the user's machine. It ships precomputed related passages, labeled as AI-made where they are (D-016; neighbors only, Q-06).

**Release split (Q-01, decided):**

- **Release 1a:** the engine; the build pipeline; the core texts; the reader; search; census and shapes; They Chose over the seeded quotation index; the word's journey; divine names; the range of renderings; the author library (rix.db); notes, highlights, bookmarks, tags and history; the CLI; the native GUI; the installer.
- **Release 1b:** library content packs (public-domain commentaries, lexicons beyond Strong's, dictionaries, devotionals), plus the prayer list, memory cards and reading plans. The design is the same either way: library content is data behind `BIB_LIBRARY`.

## Why

An ordinary reader on an ordinary Windows laptop (CPU only, 8 to 16 GB, no setup skills) has no free tool that lets them **see, count, compare and check** the biblical text, with every number computed, every quotation pulled from data, every fact sourced and licensed, and any AI help kept apart from the facts. Free readers (e-Sword, theWord) do not measure. Corpus tools (Text-Fabric, SHEBANQ) are not one-click installs and often carry non-commercial (NC) data. Logos puts AI in the answer path.

The user-voice research (`research/13`, 294 items from 96 sources) shows that the loudest pain is not missing features but **betrayal of trust**: paywalled features, forced redesigns, lost notes, ads inside Scripture, AI pushed into plain search, and text changed without notice. Complexity comes second, then AI accuracy and completeness. A free, offline tool with no account, no store and no AI in the answer path, where the engine owns every fact, answers most of this by design (D-002, D-004, D-016; trust rules ratified, Q-14).

**Positioning:** *e-Sword gives you free books. Logos sells you a library. simple_bible checks what people say about the Bible against the Bible itself: free, honest, and with the counter-evidence shown.*

## Users

1. **Primary first user (Q-10): the lay reader who outgrew e-Sword.** The Simple layout is the default on first run: the Bible text in the center, commentary and related passages to the east, dictionary and lexicon to the south, every pane following the verse. The program uses large print, has no account, never shows ads, and never changes the text silently. This reader needs plain search that always finds a copied phrase, original-language help that does not need a seminary education (transliteration, pronunciation, gloss), notes they own, and honest counts.
2. **The student:** concordance by lemma, Strong's and morphology; the range of renderings before any ruling; the word's journey; census with frequency-matched controls; Show method behind every number.
3. **The pastor:** They Chose (NT against the LXX against the MT), the author library beside the text, guides assembled only from engine results, and export with attribution. No sermon generator (Q-14).
4. **The language learner:** pointing reduction (full, vowels, consonants), the interlinear, word cards with transliteration and pronunciation, and divine-name marking.
5. **Larry (build machine):** runs `bible_build` to produce the distribution databases and proves each Python port by a differential test.
6. **Other tools:** simple_chat's tool participant through the CLI one-shot command set (ledger R-5/R-6); users' own AIs through an MCP face in v1.5 (Q-12).

## Acceptance Criteria

Each criterion names the test that proves it. **1a** criteria gate Release 1a; **1b** criteria gate Release 1b. "Reference machine" means 8 GB RAM, CPU only, SSD (Q-15).

### Release 1a: build and data

- [ ] **AC-1a-01** Two `bible_build core` runs from the same manifest and the same passed-in build date produce identical per-table checksums (`test_build_determinism`).
- [ ] **AC-1a-02** The build refuses, with a named error and a non-zero exit, any pinned source whose SHA-256 or license-text hash does not match the manifest (`test_license_gate`).
- [ ] **AC-1a-03** A source with license UNKNOWN or restricted and `ship = true` fails the build, and the message names its key; the Rahlfs entry is `ship = false` (`test_license_gate`).
- [ ] **AC-1a-04** In `core.db` and `ai_data.db`, zero rows lack a provenance key (`test_build_determinism`).
- [ ] **AC-1a-05** The shipped credits are byte-equal to credits regenerated from `source_provenance` (FR-003).
- [ ] **AC-1a-06** Swete: No verse begins with a Roman numeral without a `source_repairs` row; every numbering gap is classified; no apparatus or marginal note text ships; every Swete verse has a repair state; the Ecclesiastes slot holds Brenton 1851 rows labeled "Brenton 1851" (Q-04) (`test_defect_register`, Swete checklist).
- [ ] **AC-1a-07** One passing test per defect-register item (A1, B1-B4, C, D, E1-E11); LXX Jeremiah tails (A1) answer NO_DATA as quarantined (`test_defect_register`).
- [ ] **AC-1a-08** `book_catalog` ids equal the vault's `bible_books` ids (FR-105).
- [ ] **AC-1a-09** Only SIL OFL fonts ship, each with its license file and a provenance row (Q-03).
- [ ] **AC-1a-10** The Eiffel rix.db builder's output equals the Python reference golden on the same vault snapshot, with zero mismatches in `BIB_DB_COMPARATOR`'s report (`test_rix_differential`).
- [ ] **AC-1a-11** Every `ai_data.db` row carries `is_ai_made`, a method label and a model id; no vector table ships (Q-06).
- [ ] **AC-1a-12** Every D-020 port (rix.db builder, reference detector, versification step, census, shapes, quotation comparer, precompute jobs) passes a differential test against a SHA-256-pinned golden fixture, and the whole suite passes with no Python installed.

### Release 1a: engine

- [ ] **AC-1a-13** The reference parser passes its 300+ case suite; "Ju 1" and "Ph 1" return at least two candidates and no version text (`test_reference_parser`).
- [ ] **AC-1a-14** The versification regression set passes, and each pairing names its rule: Ps 23:1 / LXX 22:1; Mal 4:1 / MT 3:19 (with the Swete leg); Jer 31:31 / LXX 38:31; Lev 5/6; Deut 23; Num 16/17 (Swete); Joel 2-4; Ps 9/10 and 118/119; psalm titles (`test_versification`).
- [ ] **AC-1a-15** Only `BIB_VERSIFICATION_MAP` can create a `BIB_MAPPED_REF` (`test_layering`).
- [ ] **AC-1a-16** The verse hub returns each shipped version's text or a typed omission, never an empty string: Matt 17:21 in WH reads "omitted in this edition"; Tobit in the BSB is "not in this canon" (`test_verse_hub`).
- [ ] **AC-1a-17** Display text is byte-equal to the source (MapM's no-break space before paseq preserved), and the same phrase is found through the normalized column (`test_normalizers`).
- [ ] **AC-1a-18** Copied-phrase test: For 200 verses per shipped version, drawn with a fixed seed, searching the verse's own display text returns that verse (`test_search`).
- [ ] **AC-1a-19** `H1`, `H0001` and `H00001` are one key; split senses (6743/6743a) are reported separately; for unsplit lemmas the Strong's count equals the lemma count (`test_search`).
- [ ] **AC-1a-20** The Hebrew, Greek and English normalizers are idempotent and leave no combining mark on the trap corpus (`test_normalizers`).
- [ ] **AC-1a-21** A census definition freezes at its first run; editing it afterwards violates a precondition; `new_version` increments the version; re-running the same definition on the same edition gives identical counts and controls (`test_census`).
- [ ] **AC-1a-22** Every census and shape result carries all four buckets, and no public feature returns one bucket alone; the Heb 11:3 / Eph 4:12 regression keeps NO_DATA apart from FAILS; a T3 shape is refused as evidence (`test_census`, `test_shapes`).
- [ ] **AC-1a-23** They Chose: Heb 8:8-12 against LXX (Swete) Jer 38:31-34 against MT Jer 31:31-34 yields a computed agreement class with an edition note naming Swete and the OCR note, on a hand-verified LXX span; an unaligned quotation yields NO_DATA (`test_quotation`).
- [ ] **AC-1a-24** The word's journey for *ekklēsia* shows Tyndale "congregation" and KJV "church" with counts and a method on every row (`test_study`).
- [ ] **AC-1a-25** Gen 7:16 marks Elohim and YHWH; Swete-side marks carry the label "surface-form match" (`test_study`).
- [ ] **AC-1a-26** The range of renderings shows every distinct gloss with counts for a fixed 50-lemma sample (`test_study`).
- [ ] **AC-1a-27** Every count carries a non-empty scope label (corpus, edition, unit), and every method record re-runs to identical counts (`test_search`, `test_census`).
- [ ] **AC-1a-28** Every related passage has at least one reason; every AI-made item carries the AI-made label, method and model id (`test_study`).
- [ ] **AC-1a-29** No author document reaches a face without its status; withdrawn documents are excluded from search by default and returned, with their banner, when "Include withdrawn" is on (Q-09) (`test_author_library`).
- [ ] **AC-1a-30** No version label equals a bare "LXX" (`test_verse_hub`).
- [ ] **AC-1a-31** Every engine test runs headless (FR-033).
- [ ] **AC-1a-32** A cancelled job yields no result object, and its mailbox holds zero pages (`test_jobs_scoop`).

### Release 1a: user data

- [ ] **AC-1a-33** Notes, highlights, bookmarks, tags and history are keyed to canonical hub ids: A highlight made on John 3:16 in the BSB shows on John 3:16 in every version (`test_user_store`).
- [ ] **AC-1a-34** User data is append-only: An edit writes a new version, a delete is soft, and both can be restored; a rotating backup is written on exit and restores from Settings (`test_user_store`).
- [ ] **AC-1a-35** A previous-schema `user.db` fixture migrates with every setting, layout and note preserved (`test_user_store`).
- [ ] **AC-1a-36** Notes go through `BIB_NOTE_STORE`. If Release 1 carries it (Q-11), the Markdown-folder store is the default, with `user.db` as its index (`test_user_store`).

### Release 1a: faces

- [ ] **AC-1a-37** The CLI exposes a closed command set covering at least the ledger R-5 subset; an unknown command is refused with a non-zero exit; simple_chat's tool participant, retargeted to `bible.exe`, passes its tests (`test_cli_commands`).
- [ ] **AC-1a-38** D-006 spike: Gen 1:1 WLC with cantillation, Gen 1:1 Swete and John 1:1 WH render offscreen in `SW_LABEL` and `SW_TEXT_BOX` and match reference images (GW-01 to GW-03 closed).
- [ ] **AC-1a-39** The Simple layout is the default on first run; switching modes preserves the active reference, notes, search results and running jobs (`test_state_machines`).
- [ ] **AC-1a-40** No GUI or CLI class depends on simple_sql, and no banned accessor appears (`test_layering`).
- [ ] **AC-1a-41** GC probe: While a census runs on a worker, no allocation on the GUI processor waits longer than 16 ms (`test_gc_probe`; needs FT-02).
- [ ] **AC-1a-42** Every displayed fact has a provenance chip, and every number has Show method (`test_panels_offscreen`).
- [ ] **AC-1a-43** Every panel exposes `accessible_name` and `spoken_text`; every command is reachable from a menu and from the keyboard. Screen-reader access (GW-14) is part of 1a if its owners can schedule it (Q-13).
- [ ] **AC-1a-44** Copying or exporting Swete text carries the attribution and the CC BY-SA notice; AI-made items keep their label in every export (`test_study`).

### Release 1a: trust, packaging, performance

- [ ] **AC-1a-45** The app and the CLI make zero outbound network connections in a default run (FR-064).
- [ ] **AC-1a-46** There are no tiers, ads, store, review prompts, accounts, telemetry or activation; a donation link appears only on the About page (Q-14).
- [ ] **AC-1a-47** The null AI adapter is bound; no AI path is reachable from search; AI-made text is never exported or pasted without its label (Q-14).
- [ ] **AC-1a-48** The installer installs and uninstalls silently on a non-live identity, keeps `user.db` and the note folder on uninstall, and contains no WebView2.
- [ ] **AC-1a-49** On the reference machine: verse jump under 100 ms and whole-Bible search under 300 ms (Q-15), cold start in 3 s or less, census with controls under 10 s. The same suite runs on an HDD machine and its numbers are reported, not gated.
- [ ] **AC-1a-50** The public executable contains no effective `BIB_LENS` descendant and no string naming `scholars.db`, `transcripts.db` or `nakedbiblepodcast` (`test_plugin_purity`).

### Release 1b

- [ ] **AC-1b-01** Each library content pack (public-domain commentaries, lexicons beyond Strong's, dictionaries, devotionals) passes the license gate, and every entry has provenance; an entry without provenance cannot be built.
- [ ] **AC-1b-02** Library queries by verse, lemma, topic and date return entries with provenance, and the Commentary and Lexicon panels render them.
- [ ] **AC-1b-03** Prayer items, memory cards and reading plans are stored append-only in `user.db`; the memory schedule and plan generation are deterministic for given dates; memory practice works down to one verse.
- [ ] **AC-1b-04** Text-first guide mode contains no commentary, author-library or lens section while commentary packs are installed.
- [ ] **AC-1b-05** A Release 1a `user.db` fixture migrates to 1b with all user data preserved.
- [ ] **AC-1b-06** The 1a performance suite passes with every 1b pack installed.

## Out of Scope

- Any run-time AI in Release 1 (D-016): no model downloaded or run on the user's machine. Judgment-grade AI never ships.
- Selling, paid tiers, credits, accounts, telemetry, activation, ads, a store or review prompts (D-002, Q-14).
- Persona chatbots and a sermon generator (Q-14).
- Shipping copyrighted material without a license: `scholars.db`, `transcripts.db`, book texts, the NBP corpus (D-002).
- Rahlfs (CCAT) in the public build until written permission arrives (D-011).
- WebView2 in any role, and any fallback to outside technology (D-006).
- A TUI face (Q-08).
- Editing primary texts at run time. Corrections go into the build with a recorded reason.
- macOS and Linux native builds.
- Python anywhere in the product or the distribution build (D-020).
- Meaning vectors in Release 1 (v2 meaning search, Q-06).
- v1.5: Claim Check, the Study Ledger, share-safe export flags, pre-registered questions for any search, "My ruling", the MCP face (Q-12).
- v2: world timeline (`history.db`), atlas, meaning search, Exegetical Guide, senses, reverse interlinear, variants, clause views, the full NT-Use-of-OT browser, user-made shapes, the Hebrew syntax layer (D-012).
- v3: the optional local chat model behind a labeled "explain" button, syntax search.

## Dependencies (REQUIRED - simple_* First Policy)

**Rule:** simple_* libraries before ISE and Gobo. simple_bible itself uses ISE `base` directly and nothing else from ISE or Gobo. Gobo and ISE libraries reach it only through simple_* wrappers (C-002).

| Need | Library | Justification | Layer / release |
|------|---------|---------------|-----------------|
| SQLite access, FTS5, read-only open, online backup, migrations | simple_sql | All database work | engine, 1a |
| SQLite engine | eiffel_sqlite_2025 (through simple_sql) | 3.31.1 today; FT-01 upgrade and FT-02 `blocking` externals, patched in place (Q-02) | engine, 1a |
| Model queries in postconditions | simple_mml | MML frame conditions (C-019) | engine, 1a |
| UTF-8/32; Unicode normalization | simple_encoding | NFD/NFC and Mn after LG-01 | engine and build, 1a |
| Regex search, reference patterns, rix rules | simple_regex | Search, detectors, rix.db port | engine and build, 1a |
| Method records, payloads, fixtures | simple_json | Serialized method records | engine, 1a |
| SHA-256 | simple_hash | Manifest, checksums, fixtures | build, 1a |
| LCS word diff | simple_diff | `BIB_TOKEN_DIFF` | engine, 1a |
| Paths, data-folder discovery, vault walk | simple_file | Portable mode, vault walker | engine and build, 1a |
| Configuration | simple_toml | `bible.toml` | engine, 1a |
| Diagnostics | simple_logger | Logs | all, 1a |
| Dates (user records, memory scheduling) | simple_datetime | Never in builder rows | engine, 1a/1b |
| OSIS and TEI imports | simple_xml | OSHB, Swete (First1KGreek TEI) | build, 1a |
| TSV imports | simple_csv | STEPBible, MACULA, OpenBible | build, 1a |
| Build-time embeddings | simple_onnx | bge-m3 neighbors, build machine only | build, 1a |
| Passage graph | simple_graph | Related-passage precompute | build, 1a |
| Arguments | simple_cli | `bible.exe`, `bible_build` | CLI and build, 1a |
| REPL | simple_console | REPL | CLI, 1a |
| Native face | simple_widgets, simple_shaping, simple_cairo, simple_shell | D-006 | GUI, 1a |
| Tests | simple_testing | `TEST_SET_BASE` | tests, 1a |
| Hidden process spawn | simple_process | llama-server | v3 only |
| Loopback and BYOK calls | simple_winhttp | Never libcurl (C-009) | v3 only |
| MCP over stdio | new fleet library (LG-06) | `bible_mcp` face | v1.5 |

**Only ISE used directly:** `base`. `testing` reaches the suite only through simple_testing.

## MML Decision (REQUIRED)

**Decision:** YES-Required.
**Rationale:** The specification already uses MML models on every collection-bearing class: 19 classes in the 05 MML table, including `BIB_BUCKETED_RESULT`, `BIB_CENSUS_DEFINITION`, `BIB_JOB_MAILBOX`, `BIB_SOURCE_SET`, `BIB_PLUGIN_REGISTRY` and `BIB_DISTRIBUTION_BUILDER`. Frame conditions (`|=|`) carry the core promises: Buckets never lose a finding, frozen definitions never change, cancelled jobs discard pages. By fleet convention (C-019), model clauses live in postconditions and invariants stay O(1).
