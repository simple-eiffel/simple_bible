# Intent v2: simple_bible

*Phase 0 (/eiffel.intent), steps 4 to 6, 2026-10-06. This file combines `intent.md` (step 3), the deep self-review (step 4: 12 probing questions plus the 7 deferred sparks of Q-16), the dependency audit (step 5) and the refinements found along the way. It governs wherever it differs from `intent.md`. Binding inputs: `spec/09-LARRY-ANSWERS (2026-10-06).md` (Q-01 to Q-16) and D-001 to D-020. Every recommendation below is Claude's; Larry may override any of them at approval. **Status: AWAITING LARRY'S APPROVAL.***

---

## 1. What

simple_bible is a free Windows Bible-study workbench. A deterministic Eiffel engine over SQLite does all the counting, lookup, comparison and checking of the Hebrew, Greek and English text, and every fact it returns carries its source and license. One repository holds four parts, each with its own ECF (refinement R-03; see RQ-01):

1. **Engine library** `simple_bible.ecf` (`SIMPLE_BIBLE` facade, `BIB_` classes, the user store, the plug-in seam and the AI seam). Every answer is a result object with a method record and citations. Census and shape answers always carry FITS, PARTIAL, FAILS and NO_DATA together. Cross-version pairing happens only through the versification map. AI text can be created only from an engine answer and is always labeled.
2. **Build pipeline** `bible_build.ecf`. It assembles `core.db`, `ai_data.db` and `rix.db` from pinned upstream sources and Larry's vault, under a license gate, deterministically, with generated credits. It hosts the Eiffel ports of the vault's Python tools, each accepted by a differential test against golden outputs (D-020).
3. **Faces** `simple_bible_app.ecf`: the native simple_widgets GUI (Simple and Study layouts) and the CLI/REPL `bible.exe` with a closed, read-only command set. Both depend only on engine abstractions.
4. **Private plug-in seam:** deferred interfaces and the registry only, in the public build. Larry's separate repository implements them at compile time.

Release 1 runs no AI on the user's machine. It ships precomputed related passages, each with its reason, and the AI-made ones are labeled (D-016; neighbors only, Q-06).

**Release split (Q-01, decided; boundaries refined in RQ-05 and RQ-11):**

- **Release 1a:** the engine; the build pipeline; the core texts (OSHB/WLC with MapM, SBLGNT with MorphGNT, MACULA Greek, Westcott-Hort, KJV (1769 Blayney), ASV, YLT, BSB, Tyndale, Clementine Vulgate, Wycliffe, Swete LXX with Brenton 1851 Ecclesiastes); Strong's and glosses (STEPBible); cross-references; the reader; search; census with controls; T1 and T2 shapes; They Chose over the seeded quotation index; the word's journey; divine names; the range of renderings; related passages; the author library (rix.db); notes, highlights, bookmarks, tags and history; the CLI; the native GUI; the installer; portable mode.
- **Release 1b:** library content packs (public-domain commentaries, lexicons beyond Strong's, dictionaries, devotionals) and rich-text rendering of library entries (GW-13); the prayer list, memory cards, reading plans and collections; the writing checks (FR-031); the archaic-word helper (S3).

## 2. Why

An ordinary reader on an ordinary Windows laptop (CPU only, 8 to 16 GB, no setup skills) has no free tool that lets them **see, count, compare and check** the biblical text, with every number computed, every quotation pulled from data, every fact sourced and licensed, and any AI help kept apart from the facts. Free readers (e-Sword, theWord) do not measure. Corpus tools are not one-click installs and often carry non-commercial (NC) data. Logos puts AI in the answer path.

The user-voice research (`research/13`, 294 items from 96 sources) shows that the loudest pain is **betrayal of trust**: paywalled features, forced redesigns, lost notes, ads inside Scripture, AI pushed into plain search, and text changed without notice. Complexity comes second, then AI accuracy and completeness. A free, offline tool with no account, no store and no AI in the answer path, where the engine owns every fact, answers most of this by design (D-002, D-004, D-016; trust rules ratified, Q-14).

*e-Sword gives you free books. Logos sells you a library. simple_bible checks what people say about the Bible against the Bible itself: free, honest, and with the counter-evidence shown.*

## 3. Users

1. **Primary first user (Q-10): the lay reader who outgrew e-Sword.** The Simple layout is the default on first run, with large print, every pane following the verse, no account and no ads, and text that never changes silently. This reader needs plain search that always finds a copied phrase, original-language help that does not need a seminary education (transliteration, pronunciation, gloss), notes they own, and honest counts.
2. **The student:** concordance by lemma, Strong's and morphology; the range of renderings before any ruling; the word's journey; census with frequency-matched controls; Show method behind every number.
3. **The pastor:** They Chose (NT against the LXX against the MT), the author library beside the text, guides assembled only from engine results, and export with attribution. No sermon generator (Q-14).
4. **The language learner:** pointing reduction, the interlinear, word cards with transliteration and pronunciation, and divine-name marking.
5. **Larry (build machine):** runs `bible_build` and proves each Python port by a differential test.
6. **Other tools:** simple_chat's tool participant through `bible.exe` (ledger R-5/R-6); users' own AIs through `bible_mcp` in v1.5 (Q-12).

## 4. Acceptance Criteria

Each criterion names the test that proves it. **Reference machine** = 8 GB RAM, CPU only, SSD (Q-15). Criteria marked **[conditional]** depend on a decision recorded in section 6. Totals: **Release 1a: 57** criteria (4 of them conditional); **Release 1b: 10**.

### 4.1 Release 1a: build and data

- [ ] **AC-1a-01** Two `bible_build core` runs from the same manifest and the same passed-in build date produce identical per-table checksums (`test_build_determinism`).
- [ ] **AC-1a-02** The build refuses, with a named error and a non-zero exit, any pinned source whose SHA-256 or license-text hash does not match the manifest (`test_license_gate`).
- [ ] **AC-1a-03** A source with license UNKNOWN or restricted and `ship = true` fails the build, and the message names its key; the Rahlfs entry is `ship = false` (`test_license_gate`).
- [ ] **AC-1a-04** Every shipped table declares its provenance column `NOT NULL REFERENCES source_provenance`, and after the build `PRAGMA foreign_key_check` returns no rows for `core.db` or `ai_data.db` (`test_build_determinism`; RQ-02).
- [ ] **AC-1a-05** The shipped credits are byte-equal to credits regenerated from `source_provenance` (FR-003).
- [ ] **AC-1a-06** Swete: No verse begins with a Roman numeral without a `source_repairs` row; every numbering gap is classified; no apparatus or marginal-note text ships; every Swete verse has a repair state; the Ecclesiastes slot holds Brenton 1851 rows labeled "Brenton 1851" (Q-04) (`test_defect_register`).
- [ ] **AC-1a-07** One passing test per defect-register item (A1, B1-B4, C, D, E1-E11); LXX Jeremiah tails (A1) answer NO_DATA as quarantined (`test_defect_register`).
- [ ] **AC-1a-08** `book_catalog` ids equal the vault's `bible_books` ids (FR-105).
- [ ] **AC-1a-09** Only SIL OFL fonts ship (Ezra SIL; Gentium Plus or Noto for polytonic Greek), each with its license file and a provenance row under the license gate (Q-03).
- [ ] **AC-1a-10** The Eiffel rix.db builder's output equals the Python reference golden on the same vault snapshot: zero mismatched rows and columns in `BIB_DB_COMPARATOR`'s report, `mtime` included (`test_rix_differential`; needs LG-10).
- [ ] **AC-1a-11** Every `ai_data.db` row carries `is_ai_made`, a method label and a model id; no vector table ships (Q-06).
- [ ] **AC-1a-12** Every D-020 port (rix.db builder, reference detector, versification step, census, shapes, quotation comparer, precompute jobs) passes a differential test against a SHA-256-pinned golden fixture, and the whole suite passes on a machine with no Python installed.
- [ ] **AC-1a-13** The build obtains each pinned source through `bible_build fetch` (simple_winhttp, build tool only), verifies it, and caches it; a second build with a warm cache makes no network request (RQ-07).
- [ ] **AC-1a-14** rix.db ships only the documents that pass the publication-scope list Larry approved; the exclusion rule is a builder rule with its own differential fixture (RQ-08) **[conditional on Larry's answer to RQ-08]**.

### 4.2 Release 1a: engine

- [ ] **AC-1a-15** The reference parser passes its 300+ case suite; "Ju 1" and "Ph 1" return at least two candidates and no version text (`test_reference_parser`).
- [ ] **AC-1a-16** The versification regression set passes, and each pairing names its rule: Ps 23:1 / LXX 22:1; Mal 4:1 / MT 3:19 (with the Swete leg); Jer 31:31 / LXX 38:31; Lev 5/6; Deut 23; Num 16/17 (Swete); Joel 2-4; Ps 9/10 and 118/119; psalm titles (`test_versification`).
- [ ] **AC-1a-17** One-to-many and many-to-one mappings: A pairing returns every target with its rule, and every count is taken per canonical hub id, so no verse is counted twice when one version splits or merges it (`test_versification`, `test_census`; RQ-12).
- [ ] **AC-1a-18** Only `BIB_VERSIFICATION_MAP` can create a `BIB_MAPPED_REF` (`test_layering`).
- [ ] **AC-1a-19** The verse hub returns each shipped version's text or a typed omission, never an empty string: Matt 17:21 in WH reads "omitted in this edition"; Tobit in the BSB is "not in this canon" (`test_verse_hub`).
- [ ] **AC-1a-20** Display text is byte-equal to the source (MapM's no-break space before paseq preserved), and the same phrase is found through the normalized column (`test_normalizers`).
- [ ] **AC-1a-21** Copied-phrase test: For 200 verses per shipped version, drawn with a fixed seed, searching the verse's own display text, including curly quotes, final forms and accents, returns that verse (`test_search`).
- [ ] **AC-1a-22** `H1`, `H0001` and `H00001` are one key; split senses (6743/6743a) are reported separately; for unsplit lemmas the Strong's count equals the lemma count (`test_search`).
- [ ] **AC-1a-23** The Hebrew, Greek and English normalizers are idempotent and leave no combining mark on the trap corpus (`test_normalizers`; needs LG-01).
- [ ] **AC-1a-24** A census definition freezes at its first run; editing it afterwards violates a precondition; `new_version` increments the version; re-running the same definition on the same edition gives identical counts and controls (`test_census`).
- [ ] **AC-1a-25** Every census and shape result carries all four buckets, and no public feature returns one bucket alone; the Heb 11:3 / Eph 4:12 regression keeps NO_DATA apart from FAILS; a T3 shape is refused as evidence (`test_census`, `test_shapes`).
- [ ] **AC-1a-26** Every shape that ships declares its required columns, and each one's Eiffel output equals the Python reference golden on the frozen `core.db` fixture; shapes using Louw-Nida domains take them from UBS SDGNT (Q-07) (`test_shape_differential`).
- [ ] **AC-1a-27** They Chose: Heb 8:8-12 against LXX (Swete) Jer 38:31-34 against MT Jer 31:31-34 yields a computed agreement class with an edition note naming Swete and the OCR note, on a hand-verified LXX span; an unaligned quotation yields NO_DATA (`test_quotation`).
- [ ] **AC-1a-28** The word's journey for *ekklēsia* shows Tyndale "congregation" and KJV "church" with counts and a method on every row (`test_study`).
- [ ] **AC-1a-29** Gen 7:16 marks Elohim and YHWH; Swete-side marks carry the label "surface-form match" (`test_study`).
- [ ] **AC-1a-30** The range of renderings shows every distinct gloss with counts for a fixed 50-lemma sample (`test_study`).
- [ ] **AC-1a-31** Every count carries a non-empty scope label (corpus, edition, unit); every method record re-runs to identical counts; every version reports its verse count and seal (`test_search`, `test_census`, `test_verse_hub`; refinement R-01).
- [ ] **AC-1a-32** Fact closure: For every engine result in the suite, the provenance of every value it carries is among its citations (`test_study` plus a closure check in every engine test; RQ-02).
- [ ] **AC-1a-33** Every related passage has at least one reason; every AI-made item carries the AI-made label, method and model id; AI-made neighbors ship only if the bge-m3 tokenizer golden test passes (RQ-04) (`test_study`).
- [ ] **AC-1a-34** No author document reaches a face without its status; withdrawn documents are excluded from search by default and returned, with their banner, when "Include withdrawn" is on (Q-09) (`test_author_library`).
- [ ] **AC-1a-35** No version label equals a bare "LXX"; the KJV is labeled "KJV (1769 Blayney)" (`test_verse_hub`; RQ-10).
- [ ] **AC-1a-36** Every engine test runs headless, and `simple_bible.ecf` has no dependency on simple_widgets, simple_shaping, simple_cairo, simple_shell, simple_onnx, simple_xml, simple_csv or simple_graph (FR-033; RQ-01).
- [ ] **AC-1a-37** A cancelled job yields no result object, and its mailbox holds zero pages (`test_jobs_scoop`).
- [ ] **AC-1a-38** Text-first guide mode contains no commentary, author-library or lens section (S9, FR-NEW-013) (`test_study`).

### 4.3 Release 1a: user data

- [ ] **AC-1a-39** Notes, highlights, bookmarks, tags and history are keyed to canonical hub ids: A highlight made on John 3:16 in the BSB shows on John 3:16 in every version (`test_user_store`).
- [ ] **AC-1a-40** User data is append-only: An edit writes a new version, a delete is soft, and both can be restored; a rotating backup (simple_sql online backup) is written on exit and restores from Settings (`test_user_store`).
- [ ] **AC-1a-41** A previous-schema `user.db` fixture migrates with every setting, layout and note preserved (`test_user_store`).
- [ ] **AC-1a-42** Notes go through `BIB_NOTE_STORE`. The Markdown-folder store is the default, with `user.db` as its index; verse links are plain references found by `BIB_REFERENCE_DETECTOR`, so the files read naturally in Obsidian or any editor (RQ-06) **[conditional: the RQ-06 gate]**.
- [ ] **AC-1a-43** Markdown store edge cases: An external edit is picked up at the next start or window focus; a file changed outside the program since its last read is never overwritten (the program writes a conflict copy); a renamed or deleted file leaves no dangling index row; a second instance opens read-only (`test_user_store`; RQ-06) **[conditional, with AC-1a-42]**.

### 4.4 Release 1a: faces

- [ ] **AC-1a-44** The CLI exposes a closed command set covering at least the ledger R-5 subset; an unknown command is refused with a non-zero exit; simple_chat's tool participant, retargeted to `bible.exe`, passes its tests (`test_cli_commands`).
- [ ] **AC-1a-45** D-006 spike: Gen 1:1 WLC with cantillation, Gen 1:1 Swete and John 1:1 WH render offscreen in `SW_LABEL` and `SW_TEXT_BOX` and match reference images (GW-01 to GW-03 closed).
- [ ] **AC-1a-46** The Simple layout is the default on first run; switching modes preserves the active reference, notes, search results and running jobs; a follow-only panel's own scrolling never moves its link set (`test_state_machines`).
- [ ] **AC-1a-47** No GUI or CLI class depends on simple_sql, and no banned accessor (`string_value_or_void`, `string_value_or_default`) appears in simple_bible (`test_layering`).
- [ ] **AC-1a-48** GC probe: While a census runs on a worker, no allocation on the GUI processor waits longer than 16 ms (`test_gc_probe`; needs FT-02).
- [ ] **AC-1a-49** Every displayed fact has a provenance chip, and every number has Show method (`test_panels_offscreen`).
- [ ] **AC-1a-50** Every panel exposes `accessible_name` and `spoken_text`; every command is reachable from a menu and from the keyboard (F6 cycles panels). Screen-reader access through GW-14 passes an NVDA script over the Simple layout **[conditional on GW-14 being scheduled, Q-13]**.
- [ ] **AC-1a-51** Copying or exporting Swete text carries the attribution and the CC BY-SA notice; AI-made items keep their label in every export (`test_study`).

### 4.5 Release 1a: trust, packaging, performance

- [ ] **AC-1a-52** `simple_bible_app.ecf` links no network-capable library, and a default run makes zero outbound connections (FR-064).
- [ ] **AC-1a-53** A UI-string audit finds no tiers, ads, store, review prompts, account, telemetry or activation text, and the donation link only on the About page; no update check exists in 1a (Q-14; RQ-10).
- [ ] **AC-1a-54** The null AI adapter is bound; no AI path is reachable from search; AI-made text is never exported or pasted without its label (Q-14).
- [ ] **AC-1a-55** The installer installs and uninstalls silently on a non-live identity, keeps `user.db` and the note folder on uninstall, and contains no WebView2; portable mode runs from one folder with no registry writes (FR-NEW-021).
- [ ] **AC-1a-56** On the reference machine: verse jump (reference entered to active Bible pane rendered) under 100 ms at p95; whole-Bible word search (one version, full hit count) under 300 ms at p95 (Q-15; these supersede NFR-001 and NFR-002 for those two measures); cold start in 3 s or less; census with controls under 10 s. The same suite runs on an 8 GB HDD machine and its numbers are reported, not gated.
- [ ] **AC-1a-57** The public executable contains no effective `BIB_LENS` descendant and no string naming `scholars.db`, `transcripts.db` or `nakedbiblepodcast` (`test_plugin_purity`).

### 4.6 Release 1b

- [ ] **AC-1b-01** Each library content pack (public-domain commentaries, lexicons beyond Strong's, dictionaries, devotionals) passes the license gate, and every entry has provenance; an entry without provenance cannot be built.
- [ ] **AC-1b-02** Library queries by verse, lemma, topic and date return entries with provenance, and the Commentary and Lexicon panels render them as rich text (GW-13 closed).
- [ ] **AC-1b-03** Prayer items, memory cards and reading plans are stored append-only in `user.db`; the memory schedule and plan generation are deterministic for given dates; memory practice works down to one verse.
- [ ] **AC-1b-04** Collections filter library resources and searches; a collection never changes a count's corpus without the scope label saying so.
- [ ] **AC-1b-05** Text-first guide mode contains no commentary, author-library or lens section while commentary packs are installed.
- [ ] **AC-1b-06** Writing checks (first-use gloss, bare script, capital after a colon, complete citation, provenance tag) each pass one positive and one negative fixture, applied to notes and exports (FR-031; RQ-11).
- [ ] **AC-1b-07** Archaic-word helper (S3): Every KJV archaic word or old name form in the sourced gloss table shows a hover gloss labeled as the text's own spelling; the display text is never altered (byte-equality test).
- [ ] **AC-1b-08** A Release 1a `user.db` fixture and note folder migrate to 1b with all user data preserved.
- [ ] **AC-1b-09** Export of a guide includes full public-domain commentary sections, not snippets, with attribution per section.
- [ ] **AC-1b-10** The 1a performance suite passes with every 1b pack installed.

## 5. Out of Scope

- Any run-time AI in Release 1 (D-016). Judgment-grade AI never ships.
- Selling, paid tiers, credits, accounts, telemetry, activation, ads, a store or review prompts (D-002, Q-14).
- Persona chatbots and a sermon generator (Q-14). See refinement R-07 for the GUI spec's v3 "Sermon Builder".
- Shipping copyrighted material without a license: `scholars.db`, `transcripts.db`, book texts, the NBP corpus (D-002).
- Rahlfs (CCAT) in the public build until written permission arrives (D-011).
- WebView2 in any role, and any fallback to outside technology (D-006).
- A TUI face (Q-08).
- Editing primary texts at run time.
- macOS and Linux native builds; Wine is not tested in Release 1 (RQ-10).
- Python anywhere in the product or the distribution build (D-020).
- Meaning vectors in Release 1 (Q-06).
- An update check, automatic or opt-in, in Release 1 (RQ-10).
- v1.5: Claim Check, omission check, the Study Ledger, share-safe export flags, pre-registered questions for any search, "My ruling", the MCP face (Q-12), trust rings (S4), exhaustive study export (S15).
- v2: world timeline, atlas and the map that follows the reading (S7), meaning search, Exegetical Guide, senses, reverse interlinear, variants and the plain-English apparatus (S8), the disagreement map (S10), clause views, the full NT-Use-of-OT browser, user-made shapes, the Hebrew syntax layer, read-aloud.
- v3: the optional local chat model behind a labeled "explain" button, the AI post-check implementation, syntax search.
- Dropped: S13 "unlock as you go".

## 6. Deep Intent Review (Claude Opus self-review)

Twelve probing questions across the ten attack angles, followed by the seven deferred sparks (Q-16). Each has why it matters, alternatives and a recommended answer. **Recommendations are not decisions until Larry approves.**

### RQ-01 (scope creep: library versus application) Where do the build tool, the user store and the faces live?

**Why it matters:** 07 puts five targets in one `simple_bible.ecf`. If the engine library's ECF names the build dependencies (simple_onnx with ONNX Runtime, simple_xml with Gobo XML, simple_csv, simple_graph), every consumer (CLI, GUI, the future `bible_mcp`, Larry's private build) links them, and nothing stops engine code from calling build code. The personal tools (notes, prayer, memory scheduling, reading plans) are application concerns that sit in the library.

**Alternatives:**
1. Keep one ECF with five targets, and police clusters with `test_layering` only.
2. Three ECFs in one repository: `simple_bible.ecf` (engine library: core through ai, plus `user` and `plugin`), `bible_build.ecf` (build library and tool; depends on the engine), `simple_bible_app.ecf` (GUI and CLI; depends on the engine).
3. Separate repositories for build and app.

**Recommended:** Option 2. The user store stays in the engine library, in its own `user` cluster, because the CLI, the GUI and the v1.5 MCP face all need it; no engine cluster may depend on `user`. Tests get their own target in each ECF. AC-1a-36 checks the library's dependency list.

### RQ-02 (contract gaps) How is "the engine owns every fact" stated so a test can prove it?

**Why it matters:** The 15 enforcement points in 05 prove that a result has *some* citation (`success_is_cited: citation_count > 0`), not that every value it carries came from a cited source. `BIB_FACT`'s `has_provenance: provenance /= Void` is already guaranteed by void safety, so it proves nothing. `rows_without_provenance (a_db) = 0` is a query whose correctness depends on its SQL. A reviewer could pass every one of these contracts with a fact that has no source.

**Alternatives:**
1. Keep the contracts as written.
2. Make every value a result exposes a `BIB_FACT`, add `facts_model` to each result, and add a closure postcondition on each engine feature: Every fact's provenance is among `citations_model`. Per C-019 this is a postcondition, never an invariant, because it is O(n).
3. Option 2, plus structural enforcement in the schema: `provenance_key INTEGER NOT NULL REFERENCES source_provenance` on every shipped table, foreign keys on during the build, and `PRAGMA foreign_key_check` empty as the builder postcondition.

**Recommended:** Option 3 (AC-1a-04, AC-1a-32). Also, **refinement R-01**: 07's class texts for `BIB_METHOD` and `BIB_VERSION_INFO` lag behind 05's addendum (no `scope_label` / `scope_stated`; no `verse_count` / `seal`). /eiffel.contracts must treat 05's addendum as authoritative for those two classes.

### RQ-03 (dependency risk) What is the SQLite ceiling for Release 1 after FT-01, and when must FT-01 and FT-02 land?

**Why it matters:** Verified today: `eiffel_sqlite_2025/Clib/sqlite3.h` reads 3.31.1, its README claims 3.51.1, and no external in `internals/` is marked `blocking` (`c_sqlite3_step` at `sqlite_externals.e:491` is plain `"C inline use <sqlite3.h>"`). Q-02 decided to patch in place with the upgrade. If the upgrade lands mid-build, the schema could start relying on STRICT or trigram, and the 1a databases would then fail to open on the old engine during development.

**Alternatives:**
1. Raise the ceiling to the upgraded version as soon as FT-01 lands.
2. Keep the 3.31.1 feature ceiling for all Release 1 DDL and SQL even after FT-01; adopt newer features in v2.
3. Fork a simple_bible-only SQLite (rejected by Q-02).

**Recommended:** Option 2. Schedule FT-01 and FT-02 as the first fleet task, before phase P2 (engine), so every engine test runs on the final SQLite and the GC probe (AC-1a-48) is meaningful. FT-02 is a hard gate for P5 (GUI). The README drift is fixed in the same pass, followed by the fleet regression run and the downstream-dependents sweep (C-018).

### RQ-04 (dependency risk) Can the fleet supply the Unicode work and the bge-m3 tokenizer that 1a's related passages need?

**Why it matters:** Verified today: `simple_encoding` has codecs and "simplified" character properties, with no NFD, NFC, NFKC or Mn category (LG-01 is still open), and `simple_zstring` has none either. `simple_onnx`'s `ONNX_TOKENIZER` is a pure-Eiffel SentencePiece unigram tokenizer that reads an "id TAB piece TAB score" vocabulary file. bge-m3 ships an XLM-R SentencePiece model whose normalizer applies NFKC-style compatibility folding; without it, token ids will differ from the reference on accented Greek and on compatibility characters. The rix.db port also needs Python's single-code-point uppercase (`simple_upper` in `build_rix_db.py` R2) for walk order.

**Alternatives:**
1. LG-01 as filed (NFD, NFC, Mn only).
2. Widen LG-01 to full UCD normalization (NFD, NFC, NFKD, NFKC), general category (including Mn, Mc, Me) and simple case mapping, with Python-parity tests, and make LG-05 (tokenizer parity) depend on it.
3. Ship 1a with no AI-made neighbors at all.

**Recommended:** Option 2. Add a release rule: AI-made neighbors ship in 1a only if the 100-verse tokenizer golden test (English, Hebrew, Greek) passes. Otherwise 1a ships the non-AI reasons (cross-reference votes, shared rare lemmas), and the neighbors follow in 1b. This is staging, not a fallback.

### RQ-05 (dependency risk) simple_shaping is pre-release and 15 GUI gap items gate v1. What is the minimum 1a GUI?

**Why it matters:** simple_shaping reads "0.1.0 pre-release, Phase 4 in progress"; no private font-file loading was found in it (GW-01). simple_widgets has `SW_DOCK_HOST`, `SW_MARKED_TEXT`, `SW_PARAGRAPH_LIST`, `SW_DATA_GRID`, `SW_CHART`, `SW_TABS`, `SW_CHIP`, `SW_SEGMENTED`, `SW_STATUS_BAR` and `SW_COMBO`, but no parallel text (GW-06), interlinear (GW-07), rich-text view (GW-13) or hover card (GW-09), and no accessibility bridge (GW-14). If all 15 v1 items must close before 1a ships, the GUI owns the critical path.

**Alternatives:**
1. All of P01 to P11 with every v1 gap closed.
2. Panels enabled as their gaps close (A-011 staging), with no minimum.
3. A named 1a minimum: P01 Bible Text, P02 Parallel, P03 Original Language, P05 Dictionary and Lexicon (Strong's and the range of renderings), P06 Notes, P07 Search, P08 Guides (They Chose, Word's Journey), P09 Census and Checks, P10 Author Library, P11 Navigator, and P04 showing cross-references and related passages only. Notes and author documents show as wrapped Markdown source text in 1a, so GW-13 (rich text) moves to 1b, where the library packs need it.

**Recommended:** Option 3. That puts GW-01 to GW-12, GW-24 and GW-26 on the 1a path, and GW-13 on 1b. Plain Markdown is legible and is exactly what an Obsidian user expects to see, and no other technology stands in. It is Larry's call whether wrapped Markdown is acceptable for the lay reader in 1a.

### RQ-06 (edge cases; integration seam) Can Release 1 carry the Markdown note store (Q-11), and what are its rules?

**Why it matters:** "Lost or scrambled notes" is the trust failure users do not forgive (13 gotcha 3). A folder that Obsidian, OneDrive and simple_bible all touch has edge cases a database never sees: external edits while the program is open, OneDrive conflict copies, renames, two instances, and an index that drifts from the files.

**Alternatives:**
1. `user.db` store first; the Markdown store in 1b.
2. The Markdown store with a live file watcher.
3. The Markdown store with reconcile at start and on window focus (an mtime and SHA-256 scan), "the file wins" with the index rebuilt from the files, a conflict copy instead of any overwrite of a file changed since its last read, a single-instance lock, and verse links as plain references ("John 3:16") found by `BIB_REFERENCE_DETECTOR`, so no proprietary syntax is needed.

**Recommended:** Option 3 in 1a, gated: If the AC-1a-43 contract tests pass by the end of phase P2, the Markdown store ships as the default; otherwise `user.db` ships first and the Markdown store follows in 1b (Q-11's own condition). Highlights, bookmarks, tags and history stay in `user.db` either way. Front matter, if any, is read with simple_yaml in the note store only. The rix.db port must keep the Python line-regex behavior and must not use a YAML parser, so that the differential test stays exact.

### RQ-07 (integration seams) How does the build get its sources, and where do the databases and the MCP face connect?

**Why it matters:** FR-010 verifies pinned hashes but says nothing about how the files arrive. simple_http is excluded (libcurl, C-009), and the app must stay network-free (FR-064). rix.db depends on Larry's private vault path, so no one else can rebuild it. `history.db` is v2. The MCP face (v1.5) should not force a second command surface.

**Alternatives:**
1. Larry downloads sources by hand; the manifest only verifies them.
2. `bible_build fetch` through simple_winhttp (build tool only), with a hash-verified cache folder.
3. Git submodules for the upstream repositories.

**Recommended:** Option 2 (AC-1a-13). Network code links only into `bible_build.ecf`, never into the app (AC-1a-52). rix.db is its own build stage with a vault-snapshot hash in the manifest, and `core.db` never depends on it. `history.db` gets no code in 1a beyond `has_history = False`. `BIB_COMMAND_SET` is the single command surface that the CLI and the v1.5 `bible_mcp` both adapt, so the MCP face stays a thin adapter over the same closed set.

### RQ-08 (what is missing) Should every document in rix.db ship publicly as built today?

**Why it matters:** D-019 ships all of rix.db. The builder's R1 scope is everything under `Rix/`, `_About/`, `_Indexes/` and `_db/` except `Rix/Data/` and `Rix/Bibles/`. That includes `Rix/FB Analyses/`, `Rix/Chats/`, `Rix/Dossiers/` and `Rix/Upcoming Projects/`, which analyze or name private individuals (Facebook commenters, local congregation members) and hold working AI chats. A public installer would distribute those pages. This is a privacy and reputation question, not a technical one.

**Alternatives:**
1. Ship everything (D-019 as worded).
2. Ship everything except a publication-scope exclusion list Larry approves (for example, documents that center on private individuals, and raw chats), with the list applied as a builder rule and covered by its own differential fixture.
3. Ship only published essays and frameworks.

**Recommended:** Option 2 (AC-1a-14). D-019's spirit ("no reason to hold back") is kept for Larry's own work; the exclusion list covers only material about other people. It is Larry's decision; the spec does not reopen D-019 without him.

### RQ-09 (naming) Are the names right for the fleet and for Eiffel style?

**Why it matters:** `BIB_` was verified unique (not `SB_`, which Gobo's storable library uses). But 07 names panel classes by number (`BIB_P01_BIBLE_TEXT`, `BIB_D01_GO_TO`), which says nothing about what a class does and breaks when panels are renumbered. The CLI executable `bible.exe` is generic. The product's display name is still open.

**Alternatives:**
1. Keep the numbered class names.
2. Name classes by role (`BIB_BIBLE_TEXT_PANEL`, `BIB_PARALLEL_PANEL`, `BIB_GO_TO_DIALOG`, and so on) and keep the P/D numbers in each class's note clause for traceability to the GUI spec.
3. Option 2, and rename `bible.exe`.

**Recommended:** Option 2. Keep `bible.exe` for continuity with simple_chat's retarget (ledger R-6), and keep `bible_build` and `bible_mcp`. The display name stays "simple_bible" until Larry names the product.

### RQ-10 (what is missing) Which user-voice questions did Q-01 to Q-16 leave open?

**Why it matters:** 13's questions 8 (update policy), 9 (canon scope), 10 (platforms and portable mode) and 12 (KJV label) are not answered by Q-01 to Q-16, and each one shows up as a user-visible behavior in 1a.

**Alternatives:** Answer each now; leave them to /eiffel.tasks; or leave them to the installer phase.

**Recommended (answer now):**
- **Updates:** manual and offline-installable only, with no update check in 1a (AC-1a-53); every text change appears in the generated text changelog against the seal (S2); old workflows stay selectable for one major version after any redesign.
- **Canon:** the deuterocanon is first-class wherever a shipped text contains it (Swete, Clementine Vulgate, Wycliffe); texts without it show "not in this canon", never an empty pane.
- **Platforms:** Windows 10 22H2 and 11, x64. Portable mode is in 1a (FR-NEW-021, cheap). Wine is not tested and not promised.
- **KJV label:** "KJV (1769 Blayney)" everywhere (AC-1a-35); old spellings are never corrected (see S3).

### RQ-11 (what is premature) What in 1a can wait without breaking a seam?

**Why it matters:** 1a is large: 145 library classes plus build, CLI and GUI. Some designed classes serve later releases.

**Alternatives:** Build everything in 07 for 1a; defer by release with the seams kept; or cut features from 1a.

**Recommended:** Defer by release, keeping the seams:
- The **AI seam:** build the deferred `BIB_AI_ADAPTER`, `BIB_NULL_AI_ADAPTER` and `BIB_AI_TEXT` with its selective creation export in 1a; leave `BIB_AI_POST_CHECK`'s implementation (digit, reference and script detectors) to v3 with the first real adapter. Its contract stays specified now.
- The **writing checks** (FR-031, `BIB_CHECK` family): 1b, where the notes editor and exports use them; the GUI's own first-use gloss rule (GUI §11.6) uses the same check, so the GUI headings check moves with it.
- **Collections:** 1b, with the library packs they filter.
- **Shapes:** 1a ships the T1 and T2 shapes whose required columns exist in `core.db`, including the Louw-Nida ones once the SDGNT import lands (Q-07); the rest wait.
- The **plug-in seam:** keep in 1a (interfaces, registry, purity test). It is cheap, and adding it later would change `SIMPLE_BIBLE.open`.

### RQ-12 (edge cases; testability) How are split and merged verses counted, and is every acceptance criterion deterministic?

**Why it matters:** `BIB_PAIRING` may return more than one target (`target_count`). A census that counts displayed verses would count a split verse twice, and a merged verse once for two hub ids. Separately, several criteria rest on timing (AC-1a-48, AC-1a-56) or on external tools (NVDA), which are not deterministic in the usual sense.

**Alternatives:**
1. Count per displayed target.
2. Count per canonical hub id, with every target listed and its rule shown.
3. Refuse to count in books with one-to-many maps.

**Recommended:** Option 2 (AC-1a-17), with fixtures from Num 16/17, Joel 2-3, Mal 3/4 and the psalm titles. For testability: Timing criteria are measured as p95 over 200 fixed-seed runs on the named reference machine, with that machine's specification recorded in the evidence; the GC probe uses the simple_chat `gc_probe` pattern with a fixed allocation load; the NVDA criterion is a scripted pass recorded per release. Everything else is a pure function of the fixture databases.

### 6.1 Deferred innovation sparks (Q-16): recommendation per spark

| Spark | Recommendation | Reason |
|---|---|---|
| **S10 Disagreement map** | **v2**, after the 1b commentary packs, built on the timeline's dispute model | Grouping commentaries into "positions" is a judgment the engine cannot make deterministically. It needs curated position rows (holder, source, date, the textual data each appeals to) reviewed by a person and shipped as data, with no verdict column in the schema. It needs the 1b commentaries first and reuses the v2 dispute model (11 §5.3). |
| **S3 Archaic-word and name helper** | **1b** | It is content work: a sourced gloss table (Jeremy = Jeremiah, Esaias = Isaiah, archaic words) built from the vault's KJV vocabulary-shift notes, with a provenance row per entry. It needs the hover card (GW-09) and serves the primary lay reader directly. The rule is fixed now: the text's own spelling is never corrected (AC-1b-07). |
| **S4 Trust rings** | **v1.5** | It generalizes `BIB_VOICE` from Larry's private material to every resource. It means little until the 1b library exists, and it must only group and order results, never change a count or hide a FAILS row (a rule to write into its contract). |
| **S7 Map that follows the reading** | **v2**, with P14 Atlas | It needs map rendering, offline geodata (OpenBible geocoding and TIPNR, licensed per 09 D06) and a tile or vector base map whose license is not yet checked. It is a GUI subsystem with no 1a seam to protect. |
| **S8 Plain-English apparatus** | **v2**, with variants (C11) | Its plain sentences must come from templates over structured apparatus data (SBLGNT apparatus, TR/WH differences), never from AI. 1a already shows the part that exists: WH omission markers ("omitted in this edition", FR-009). |
| **S13 Unlock as you go** | **Drop** | GUI spec §2.2 rejected pure progressive disclosure for good reasons (it accretes; large-print readers need a stable screen; menus must not hide items). The Simple/Study switch plus §2.1 rule 3 (dock one tool and offer the Study layout) already meets the need. |
| **S15 Exhaustive study export** | **v1.5**, with the Study Ledger | A "study" is a ledger session (I-P12, v1.5). 1a's exporter already exports full passages with attribution, and 1b adds full commentary sections (AC-1b-09). The ledger then exports a whole study as one document. |

## 7. Dependency audit (simple_* first)

Checked in `D:\prod` on 2026-10-06 by reading each ECF's library list and the relevant README or source. **Direct ISE use by simple_bible: `base` only.** Gobo and ISE libraries reach simple_bible only transitively through simple_* wrappers, which C-002 allows: Gobo xml, kernel and structure (simple_xml); Gobo regexp, kernel, string, structure and utility (simple_regex); ISE json contrib, ISE logging and Gobo regexp (simple_json); ISE time (simple_datetime); ISE logging (simple_logger); ISE net (simple_winhttp). Every library's ECF also names ISE `testing` for its own tests.

| Library | Present | What was verified | Verdict |
|---|---|---|---|
| simple_sql | yes | `make_read_only`, FTS5 classes, `SIMPLE_SQL_ONLINE_BACKUP` (fits `BIB_USER_BACKUP`), migration runner, vector store. `string_value_or_void` and `string_value_or_default` return STRING_8 (`simple_sql_row.e:262, 329`) | OK; LG-03 confirmed |
| eiffel_sqlite_2025 | yes | Header 3.31.1; README claims 3.51.1; no `blocking` external anywhere in `internals/`; last commit 2026-10-06, working tree clean | FT-01, FT-02 (Q-02) |
| simple_mml | yes | MML_SEQUENCE, MML_SET, MML_MAP, MML_BAG | OK |
| simple_encoding | yes | Codecs plus simplified character properties; no NFD, NFC, NFKC or Mn | Gap: LG-01, widened (RQ-04) |
| simple_regex | yes | 1.0.1; wraps Gobo regexp; code-point positions on STRING_32; `case_insensitive`, `multiline`, `dotall` options | OK, with a parity risk: LG-08 (verify first) |
| simple_json | yes | Wrapper over ISE json contrib | OK |
| simple_hash | yes | `sha256`, `sha256_file`; file paths are `STRING` (8-bit). 64 of 4,918 vault Markdown paths contain characters outside Latin-1 (em dashes) | Gap: LG-09 (minor) |
| simple_diff | yes | Myers diff (LCS) | OK |
| simple_file | yes | STRING_32 listings (`list_files`, `list_directories`); no recursive walk (`BIB_VAULT_WALKER` recurses itself); `modified_timestamp: INTEGER`, whole seconds, from `RAW_FILE.date`. rix.db stores `mtime real` from Python's `os.stat().st_mtime` (sub-second) | Gap: LG-10 (blocks AC-1a-10) |
| simple_toml, simple_logger, simple_graph, simple_cli, simple_console | yes | Present; weighted graph in simple_graph | OK |
| simple_datetime | yes | Wraps ISE time; ISO 8601 output | OK |
| simple_xml | yes | DOM over Gobo XML; `parse` and `parse_file` convert to STRING_8; `SIMPLE_XML_ELEMENT.text` joins only direct text children, so there is no ordered walk of mixed content. Swete's TEI keeps the apparatus inline as `<note type="footnote">` and `<note type="marginal">` with `<pb>` and `<lb>` milestones inside verse text; OSHB's OSIS interleaves `<w>`, `<seg>` and `<note>` | Gap: LG-07 (blocks the Swete and OSHB importers) |
| simple_csv | yes | RFC 4180 parsing; `quote_char` fixed to `"` with no setter; STRING_8 fields; `from_file` loads the whole file into memory | Gap: LG-11 (STEPBible and MACULA TSVs carry literal quote characters in data) |
| simple_onnx | yes | Links `lib/onnxruntime/lib/onnxruntime.lib` (CPU runtime); `ONNX_TOKENIZER` is SentencePiece unigram from an "id TAB piece TAB score" file | LG-05 (verify first), depends on widened LG-01; LG-04 optional |
| simple_widgets | yes | Wave 3 Unreleased; last commit 2026-10-06; clean working tree at check time. Has the controls listed in RQ-05; lacks parallel text, interlinear, rich text, hover card and an accessibility bridge (`sw_widget.e` mentions only a "future accessibility bridge") | GW items as filed |
| simple_shaping | yes | 0.1.0 pre-release, Phase 4; Hebrew fallback list names Ezra SIL, Noto Sans Hebrew, David; no private font-file loading found | GW-01 to GW-03 as filed |
| simple_cairo, simple_shell | yes | Present; no UI Automation code in simple_shell | GW-14 as filed |
| simple_testing | yes | `TEST_SET_BASE` | OK |
| simple_process | yes | Externals declared `C blocking inline` | OK (v3) |
| simple_winhttp | yes | Present (ISE net transitively) | OK; used by `bible_build fetch` only (RQ-07) |
| simple_yaml | yes | "Full YAML 1.2 parser" | Added for note front matter only (RQ-06) |
| simple_markdown | yes | Markdown to HTML (CommonMark plus GFM); no AST or event API | Not needed in 1a; LG-12 if GW-13 renders Markdown natively in 1b |
| simple_http | yes | libcurl | Not used (C-009) |
| simple_mcp | **no** | No `*mcp*` project in `D:\prod` | LG-06, v1.5 |
| simple_speech | yes | Speech-to-text, not text-to-speech | Not relevant; read-aloud (v2) would need a new library |
| Inno Setup | external tool | Build-time packaging, not a library | OK (ledger I-01) |

### 7.1 Gaps Identified (each fixed in its owning library, then a downstream-dependents sweep and README/docs/CHANGELOG updates, C-018)

| Gap | Current workaround | Proposed simple_* fix | Needed by |
|-----|-------------------|-------------------|-----------|
| SQLite 3.31.1; README drift; no `blocking` externals | None (fleet law violated today) | eiffel_sqlite_2025 FT-01 + FT-02, patched in place, one fleet regression run (Q-02) | before P2 (preferred), P5 (hard) |
| No Unicode normalization or general category; no Python-parity case mapping | None | **LG-01 widened:** simple_encoding NFD, NFC, NFKD, NFKC from UCD data; general category including Mn, Mc, Me; simple case mapping; contracts `nfd (nfd (s)) ~ nfd (s)`, `nfc (nfd (s)) ~ nfc (s)` | P1 normalize step; LG-05 |
| Narrowing text accessors | Banned in simple_bible (static test) | **LG-03:** simple_sql STRING_32 `_or_void` / `_or_default` variants | P2 |
| bge-m3 tokenizer parity unverified | None | **LG-05:** simple_onnx loads the XLM-R SentencePiece model with its normalizer; golden ids for 100 verses | P3 precompute |
| GPU runtime (optional) | CPU runtime | **LG-04:** simple_onnx GPU execution provider | optional |
| No MCP library | None | **LG-06:** new `simple_mcp` (JSON-RPC over stdio) | v1.5 |
| No ordered mixed-content XML walk; 8-bit parse | None | **LG-07:** simple_xml ordered child-node cursor (text, element, milestone in document order), STRING_32 text accessors, Unicode file paths | P1 Swete and OSHB importers |
| Regex Unicode semantics versus Python `re` unverified (`\b`, `\w`, case-insensitive matching on non-ASCII text) | None | **LG-08 (verify first):** a parity fixture from `build_rix_db.py`'s patterns over the vault snapshot; if it fails, Unicode-aware classes in simple_regex | P3 rix.db port |
| 8-bit file paths in hashing | ASCII-named sources only | **LG-09:** simple_hash `sha256_file` and siblings take `READABLE_STRING_GENERAL` paths | P3 (note store, rix fixtures) |
| Whole-second, 32-bit mtime | None | **LG-10:** simple_file `modified_time_precise: REAL_64` (or INTEGER_64 in 100 ns units) from the Windows file time | P3 rix.db differential |
| TSV with literal quotes; whole-file loading | None | **LG-11:** simple_csv quoting-off mode (`set_quote_char` with a "none" option) and a streaming row reader | P1 STEPBible, MACULA, OpenBible importers |
| Markdown has no AST | Wrapped Markdown source in 1a (RQ-05) | **LG-12:** simple_markdown parse tree or event API for native rendering | 1b, only if GW-13 renders Markdown |
| GUI gaps | Panels staged by gap closure | GW-01 to GW-12, GW-24, GW-26 (1a); GW-13 (1b); GW-14 (1a if scheduled, Q-13) in simple_shaping, simple_widgets and simple_shell | P0 spike, P5 |

## 8. Refinements discovered during review

| ID | Refinement | Effect |
|----|-----------|--------|
| R-01 | 07's class texts for `BIB_METHOD` and `BIB_VERSION_INFO` lack 05's addendum features (`scope_label` / `scope_stated`; `verse_count` / `seal`) | /eiffel.contracts treats 05's addendum as authoritative for both classes |
| R-02 | Fact closure plus schema-level provenance (RQ-02) | New postconditions; AC-1a-04, AC-1a-32 |
| R-03 | Three ECFs in one repository (RQ-01) | 07's file structure changes at /eiffel.contracts; AC-1a-36 |
| R-04 | LG-01 widened; LG-07 to LG-12 new (section 7.1) | Fleet tasks to file |
| R-05 | Q-15's targets (verse jump < 100 ms, whole-Bible search < 300 ms) supersede NFR-001 (200 ms) and the GUI spec's search targets for those two measures, defined as in AC-1a-56 | NFR table updated at /eiffel.contracts |
| R-06 | rix.db publication-scope review (RQ-08) | AC-1a-14, conditional |
| R-07 | The GUI spec's v3 "Sermon Builder" conflicts with the ratified "no sermon generator" rule (Q-14) | Recommend dropping it from the v3 list, or limiting it to an outline organizer over the user's own notes, with no generated text; Larry's call |
| R-08 | GUI spec §13 places the screen-reader bridge in v1.5; Q-13 moved it to v1 if schedulable | The GUI spec follows Q-13 |
| R-09 | GW-13 moves from 1a to 1b (RQ-05); collections and writing checks move to 1b (RQ-11) | Release lists in section 1 |
| R-10 | The rix.db port must not use a YAML parser for front matter (parity with Python's line regex) | Coding rule for P3 |

## 9. MML Decision (REQUIRED)

**Decision:** YES-Required.
**Rationale:** The specification uses MML models on every collection-bearing class (19 classes in the 05 MML table, including `BIB_BUCKETED_RESULT`, `BIB_CENSUS_DEFINITION`, `BIB_JOB_MAILBOX`, `BIB_SOURCE_SET`, `BIB_PLUGIN_REGISTRY` and `BIB_DISTRIBUTION_BUILDER`). Frame conditions (`|=|`) carry the core promises: Buckets never lose a finding, frozen definitions never change, cancelled jobs discard pages. RQ-02 adds `facts_model` to every result. By fleet convention (C-019), model clauses live in postconditions and invariants stay O(1).

## 10. Dependencies (final list)

| Need | Library | ECF | Release |
|------|---------|-----|---------|
| SQLite, FTS5, read-only open, online backup, migrations | simple_sql (+ eiffel_sqlite_2025) | engine | 1a |
| Model queries | simple_mml | engine | 1a |
| Unicode | simple_encoding (after LG-01) | engine, build | 1a |
| Regex | simple_regex | engine, build | 1a |
| JSON | simple_json | engine | 1a |
| LCS diff | simple_diff | engine | 1a |
| Paths, portable mode | simple_file (after LG-10 for the build) | engine, build | 1a |
| Configuration | simple_toml | engine | 1a |
| Logging | simple_logger | all | 1a |
| Dates | simple_datetime | engine | 1a |
| Note front matter | simple_yaml | engine (`user` cluster) | 1a |
| SHA-256 | simple_hash (after LG-09) | build, engine (`user` cluster) | 1a |
| OSIS and TEI | simple_xml (after LG-07) | build | 1a |
| TSV | simple_csv (after LG-11) | build | 1a |
| Build-time embeddings | simple_onnx (LG-05) | build | 1a |
| Passage graph | simple_graph | build | 1a |
| Source fetch | simple_winhttp | build | 1a |
| Arguments | simple_cli | app, build | 1a |
| REPL | simple_console | app | 1a |
| Native face | simple_widgets, simple_shaping, simple_cairo, simple_shell | app | 1a |
| Tests | simple_testing | all test targets | 1a |
| Hidden spawn | simple_process | app | v3 |
| MCP | simple_mcp (LG-06, new) | `bible_mcp` | v1.5 |

## 11. Approval

**Intent document refined. Approve to proceed to Phase 1 (Contracts)?**

Larry may approve as is or override any recommendation. The open items that need his word are RQ-05 (wrapped Markdown in 1a), RQ-06 (the Markdown store gate), RQ-08 (the rix.db publication scope), R-07 (Sermon Builder) and the seven spark placements in section 6.1. Phase 1 (/eiffel.contracts) does not start until he approves.

## APPROVAL (Larry, 2026-10-06)

Larry: "approve as recommended, then run /eiffel.contracts." Every review question RQ-01..RQ-12 takes its **recommended** answer, the per-spark placements stand as recommended, and these two calls are settled:

- **RQ-08 (rix.db publication scope): Option 2.** Larry's own work ships in full (D-019 stands). A **publication-scope exclusion list** covers only material centered on private individuals (e.g., Facebook commenters, local congregation members) and raw AI chats. It is applied as a builder rule with its own differential fixture (AC-1a-14). **The list itself needs Larry's approval before the first public build.** Contracts model it as a rule object fed by an approved list. No list content is assumed.
- **R-07 (Sermon Builder):** Keep it only as an **outline organizer over the user's own notes, with no generated text**, consistent with the ratified "no sermon generator" trust rule (Q-14). Recorded as a v3 GUI item under that constraint.

Status: **APPROVED**. Next: `/eiffel.contracts`.
