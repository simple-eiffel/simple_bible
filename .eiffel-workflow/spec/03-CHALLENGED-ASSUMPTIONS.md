# CHALLENGED ASSUMPTIONS: simple_bible

*Step R03, 2026-10-06. Attack mindset. Each assumption was checked against files actually read today (research 01-12, the GUI spec set, the Python reference tools, and the fleet's source in `D:\prod`). Verdicts that changed the design are marked **CHANGES DESIGN**. `research/13-USER-VOICE.md` (294 user items from 96 sources, graded OPENED/SNIPPET, with `13-user-voice-items.csv`) arrived complete during this step and was read in full; its evidence is folded in as A-021 to A-030 and the spark dispositions below. User-voice items are treated as evidence (OPENED quotes weighed above SNIPPET summaries), not as requirements by themselves.*

---

## Assumptions Challenged

### A-001: Swete is good enough to be the default Septuagint
**Challenge:** The First1KGreek Swete is OCR that "nobody read through": its editors counted 74 errors or omissions in 56 Genesis verses; 11 chapter openings lost; merged verses; Ecclesiastes missing; 1,083 raw numbering gaps (12 §A3). A default text that silently differs from print undercuts the "engine owns every fact" promise, and the quotation comparer computes verdicts from it.
**Evidence for:** Only complete Swete with a clean license (CC BY-SA 4.0); public-domain print; the scans are public domain, so hand repairs add no license; Sollupulo (CC BY-SA 4.0) gives a hand-proofread collation partner for Genesis through 3 Kingdoms; Rahlfs is legally blocked (D-011).
**Evidence against:** The FR-030 acceptance case (Heb 8:8-12 against LXX Jer 38:31-34) lies **outside** Sollupulo's range (Genesis-3 Kingdoms). Jeremiah, Isaiah, Psalms and the Twelve, where most NT quotations land, are uncollated OCR. There is no open Swete morphology, so LXX-side lemma alignment is impossible.
**Verdict:** VALID as the default, with conditions. **CHANGES DESIGN.**
**Action:**
1. `BIB_VERSE_TEXT` carries a `repair_state` (as-imported OCR / repaired / collated) taken from `source_repairs` and the collation log; `BIB_VERSION_INFO` carries `text_quality_caveat` ("Digital text from OCR; it may contain errors").
2. `BIB_QUOTATION_RESULT` invariant `edition_note_present`; when any LXX token in the aligned span comes from an uncollated OCR row, the result adds the note "LXX leg from uncollated OCR text" and the verdict stays computed but flagged.
3. LXX-side alignment and divine-name marking use normalized surface forms and say so ("surface-form match"); NO_DATA for morphology lines.
4. The build's quotation-alignment step must hand-verify the LXX span of every seeded quotation against the archive.org scan before the alignment row ships (a `reviewed_by` column, FR-044 pattern). This is data work for the build phase, not code.
5. Ecclesiastes in the Swete slot stays Larry's call (Brenton 1851 labeled rows, or "not in this digital edition"); `BIB_OMISSION` already has both kinds.

### A-002: The target machine (CPU only, 8-16 GB) can run everything in Release 1
**Challenge:** NFR-002 asks for a census with controls in under 10 s. Frequency-matched controls multiply the work (target + N controls). Whole-canon regex search cannot use FTS5.
**Evidence for:** Release 1 runs no AI on the user's machine (D-016). The vault's normalized `plain` column gave a 250x speed-up with prefix search (D-009). Whole canon is about 31,000 verses; per-lemma counts are indexed lookups. Lemma frequency tables can be precomputed (control selection is then a table lookup).
**Evidence against:** Regex over all versions is a full scan of roughly 300,000 verse rows in Eiffel; each control count is a separate query.
**Verdict:** VALID.
**Action:** Precompute `lemma_frequency` at build time (`BIB_LEMMA_FREQUENCY_PRECOMPUTE`). Census runs the target and controls as one job on a worker processor, chunked by book. Regex runs only over the selected scope with a scope precondition (`scope_bounded_for_regex`: default scope is one version, never "all versions" without the user choosing it), and streams pages.

### A-003: Build-time embeddings run "on Larry's RTX" (D-016, D-017) with simple_onnx (D-020)
**Challenge:** `simple_onnx` bundles `onnxruntime-win-x64-1.17.3`, a CPU runtime. `ONNX_PROVIDER` names `CUDAExecutionProvider`, but the bundled runtime cannot use it. bge-m3 uses the XLM-R SentencePiece tokenizer; `ONNX_TOKENIZER` is a unigram tokenizer built for MarianMT vocab files; compatibility is unverified (research A-6).
**Evidence for:** bge-m3 is MIT; ~31,000 verse vectors is small; CPU inference of a 568M encoder over 31,000 short passages is hours, not days.
**Evidence against:** "RTX" implies a GPU runtime not present in the fleet.
**Verdict:** NEEDS_VALIDATION.
**Action:** The embedding precompute is specified as **CPU-correct first** (`BIB_EMBEDDING_PRECOMPUTE` uses whatever provider `simple_onnx` offers; result rows record provider and runtime version). A GPU runtime in simple_onnx is filed as **LG-04** (owning library: simple_onnx), optional. The tokenizer check is the first task of the precompute phase: bge-m3's tokenizer file loaded by `ONNX_TOKENIZER`, token ids compared with a golden list produced by the model's reference tokenizer for 100 verses in English, Hebrew and Greek; a mismatch is **LG-05** in simple_onnx. Release 1 does not depend on it: related passages from cross-references and rare lemmas ship regardless (RISK-007).

### A-004: The compiled SQLite is adequate (3.31.1)
**Challenge:** Header and library are 3.31.1 (`SQLITE_VERSION "3.31.1"`, re-read today; the last eiffel_sqlite_2025 commit, 2026-10-06, did not change it). D-007's upgrade is not done.
**Evidence for:** Everything Release 1 needs exists in 3.31.1: FTS5 with unicode61 and `remove_diacritics 2` (3.27), JSON1, window functions (3.25), UPSERT (3.24), generated columns (3.31.0), RTREE.
**Evidence against:** No trigram (substring search in transliterations), no STRICT tables, no `->>`, no built-in math, no contentless-delete; five years of fixes missing; `OMIT_LOAD_EXTENSION`.
**Verdict:** VALID constraint (C-010).
**Action:** Schema uses CHECK constraints and NOT NULL instead of STRICT; normalized columns plus prefix queries instead of trigram; transliteration substring search via LIKE on a normalized transliteration column within a bounded scope; all arithmetic (frequencies per 1,000 words, control statistics) in Eiffel. `BIB_DATA_SOURCE.open` checks `sqlite_version() >= "3.31.1"` and records the version in every method record so a later upgrade is visible.

### A-005: Running long queries on SCOOP worker processors keeps the GUI responsive
**Challenge:** The fleet GC law: a plain `external "C inline"` call that waits blocks every processor at its next allocation during a collection. `eiffel_sqlite_2025` `c_sqlite3_step` is declared `"C inline use <sqlite3.h>"` **without `blocking`** (re-read today, `internals/sqlite_externals.e:491`). The fleet audit lists it as **HELD for Larry's gate** (patch in place vs fleet-local fork). A census whose single `sqlite3_step` takes seconds on a worker freezes the GUI processor at its next allocation if a collection starts.
**Evidence for:** SCOOP isolates Eiffel execution; the GUI never waits on a worker by design.
**Evidence against:** The GC stall is below SCOOP; it was measured in simple_chat (211 s of freezes in 20 minutes).
**Verdict:** INVALID as stated. **CHANGES DESIGN.**
**Action:**
1. Prerequisite fleet task **FT-02**: mark `c_sqlite3_step`, `c_sqlite3_open_v2`, `c_sqlite3_close` `blocking` in eiffel_sqlite_2025 (Larry's gate on patch-in-place vs fork), bundled with the D-007 upgrade (FT-01) so the fleet regression runs once.
2. Independently of FT-02, the engine never issues a statement whose single step can run long: whole-canon work is **chunked by book** (66-87 chunks), each a bounded query; regex scans step row by row. Chunking is also the cancellation granularity (FR-123). `BIB_JOB` contract: `step` processes exactly one chunk.
3. NFR-016 added: no GUI-processor stall beyond one frame from engine work, including GC waits; a GC-probe test (the simple_chat `gc_probe` pattern) runs a census on a worker while the GUI processor allocates, and fails if any allocation waits longer than 16 ms.

### A-006: The GUI can poll a running job's queries for progress and pages (GUI design notes §5 rule 3)
**Challenge:** In SCOOP, a separate call from the GUI to `job.progress` is served only when the job's processor is free. If the job is inside a long `run`, the GUI's query waits for `run` to finish: exactly the stall the design meant to avoid. Likewise `request_cancel` on the busy job cannot be delivered until the job finishes, so cancel would never work.
**Evidence for:** None; it is a SCOOP semantics error in the design notes.
**Verdict:** INVALID. **CHANGES DESIGN.**
**Action:** Jobs report through a **`BIB_JOB_MAILBOX`** and are stopped through a **`BIB_CANCEL_TOKEN`**, each its own separate object on its own processor. The job writes pages and progress into the mailbox (short separate calls) and reads the token between chunks. The GUI polls the mailbox on the heartbeat (GW-26 later replaces polling with a wake), and sets the token. The job object itself is never queried by the GUI while it runs. Mailbox values are plain copied values (`STRING_32`, `INTEGER_64`, arrays), never references into the job's objects.

### A-007: Unicode tooling in the fleet can build the Hebrew and Greek normalizer
**Challenge:** D-009 needs NFD decomposition for polytonic Greek (precomposed U+1F00-U+1FFF and tonos letters) and the Mn general category. `simple_encoding.SIMPLE_CHARACTER_PROPERTIES` has "Unicode Categories (simplified)" with no Mn and no decomposition; no fleet library offers NFD/NFC (grep of `simple_encoding` and `simple_zstring` today: none). Detached breathings (U+1FBF, U+1FFE) in Swete must be attached (12 checklist) and NFC applied.
**Evidence for:** Hebrew marks occupy a known block (U+0591-U+05C7); a Hebrew normalizer needs no decomposition.
**Evidence against:** Greek folding without canonical decomposition data would be a hand-made table in simple_bible, against the fill-gaps rule.
**Verdict:** INVALID as assumed. **CHANGES DESIGN.**
**Action:** File **LG-01** against `simple_encoding`: Unicode canonical decomposition and composition (NFD/NFC) from UCD data, and general category including Mn/Mc/Me, with contracts (`nfd (nfd (s)) ~ nfd (s)`; `nfc (nfd (s)) ~ nfc (s)`). `BIB_GREEK_NORMALIZER` depends on it. The normalizer and the build's Swete repair (breathing attachment) share it.

### A-008: simple_sql returns Hebrew and Greek safely
**Challenge:** `SIMPLE_SQL_ROW.string_value` decodes UTF-8 to `STRING_32` (good), but `string_value_or_void` and `string_value_or_default` return `string_value (...).to_string_8`, which fails its precondition on any non-Latin-1 text.
**Verdict:** VALID with a trap. **CHANGES DESIGN** (coding rule).
**Action:** Engine rule: text columns are read only through `string_value` (STRING_32) or a NULL check plus `string_value`; the two narrowing accessors are banned in simple_bible (static check in tests). File **LG-03** against simple_sql: `string_32_value_or_void` / `_or_default` variants, and a note in its README.

### A-009: The fleet prefix `SB_` (the GUI spec's placeholder) is free
**Challenge:** Search of `D:\prod` today: Gobo's storable library (`gobo-26.06/gobo/library/storable/src/`) defines `SB_ATTRIBUTE`, `SB_CLASS`, `SB_BASIC_OBJECT` and others. simple_xml and simple_regex wrap Gobo; any universe that ever includes Gobo storable would clash.
**Evidence for (alternatives):** `BIB_` is used by no class in `D:\prod`, in Gobo, or in the ISE 25.02 libraries (searched today). `sbib_` appears in no header, C file or Eiffel file in `D:\prod`.
**Verdict:** INVALID (`SB_` rejected). **CHANGES DESIGN.**
**Action:** Class prefix **`BIB_`**; facade `SIMPLE_BIBLE` (fleet convention). Inline C prefix, if C is ever needed (for example the RISK-002 contingency of a custom FTS5 tokenizer), **`sbib_`**; the design plans zero C. GUI spec names `SB_*` map to `BIB_*` one for one.

### A-010: v1 scope is one list
**Challenge:** Research 01/07 define Release 1 as engine-centric (distribution build, verse hub, versification, concordance, census, shapes, checks, provenance, face, CLI, installer). The GUI spec's v1 adds library content (public-domain commentaries, BDB/Thayer/Abbott-Smith/LSJ lexicons, Bible dictionaries, devotionals), guide frames, Word's Journey, divine-name view, They Chose, reading plans, prayer list, memory cards and collections. The library content needs **importers not listed in 07's build list** (CrossWire SWORD module decoding, CCEL, Perseus lexica XML, OSHB HebrewLexicon, Thayer from Zenodo), each a license review, and needs GW-13 (rich text view), the largest GUI gap.
**Evidence for (GUI list):** 09 §9 places these rows (A01-A10, B01-B05, C01-C04, D01-D03, D05, E01-E11) in "v1: the COMFORTABLE core", the credible free alternative to e-Sword.
**Evidence against:** Two lists disagree on what "Release 1" ships; the content importers are a second data-engineering project.
**Verdict:** MODIFY (recommendation; scope is Larry's call). **CHANGES DESIGN** (structure, not scope).
**Action:** The class design treats library content as **data behind one abstraction** (`BIB_LIBRARY`, `BIB_LIBRARY_ENTRY`, importer steps per format) so the engine and faces are identical whether a content pack ships in Release 1 or later. Recommended split for /eiffel.intent: **Release 1a** = engine, core texts, reader, search, census/shapes, They Chose (seeded), Word's Journey, divine names, range of renderings, author library, notes/highlights/bookmarks/history; **Release 1b** = library content packs (commentaries, lexicons beyond Strong's, dictionaries, devotionals) plus prayer list, memory cards, reading plans. Open question Q-01 for Larry.

### A-011: The 26 GUI gap items can be scheduled alongside simple_bible
**Challenge:** Fifteen gap items gate v1 (GW-01..13, GW-24, GW-26) across simple_shaping, simple_widgets and simple_shell. Four are new widgets or major subsystems (GW-05 tabbed dock zones and snapshots, GW-06 `SW_PARALLEL_TEXT`, GW-07 `SW_INTERLINEAR`, GW-13 rich document view/editor). simple_widgets carried another session's uncommitted work today (memory note), so its owners must be coordinated. The fill-gaps rule forbids any fallback.
**Evidence for:** The engine is UI-independent (FR-033); the CLI face needs no gap item.
**Evidence against:** If the GUI is the Release 1 face, its gaps are on the critical path.
**Verdict:** VALID decision (D-006), HIGH schedule risk (RISK-018). **CHANGES DESIGN** (phase order and seams).
**Action:**
1. Phase order: build pipeline and engine (with CLI) first; they need no gap item. The D-006 spike (GW-01..03) runs in parallel because every Hebrew screen depends on it.
2. Panels are separate classes behind `BIB_PANEL`, each declaring the gap items it needs (`required_gaps` note); a panel is enabled in the build when its gaps close. This is staging, not a fallback: no panel substitutes another technology.
3. Gap dependency order for v1: GW-01/02/03 (shaping) then GW-04 (shaped grids/chips) and GW-08/09 (word hit-test, hover) for P01/P05; GW-05 (dock) for the Study layout; GW-06/07 for P02/P03; GW-13 for P04/P05 entries/P06/P10; GW-10/11/12/24/26 as their panels arrive.
4. Each gap item gets its own Spec Kit pass in its owning library and a downstream-dependents sweep (C-018).

### A-012: A plug-in can be "loaded only when present"
**Challenge:** Eiffel has no dynamic class loading; a DLL plug-in system is not available in the fleet. "Loaded when present" (FR-063) cannot mean runtime discovery of code.
**Evidence for:** Data can be discovered at run time (private databases attached when the files exist).
**Verdict:** MODIFY. **CHANGES DESIGN.**
**Action:** Code seam is **compile-time**: the public library defines deferred `BIB_PLUGIN`, `BIB_PRIVATE_SOURCE`, `BIB_LENS`; Larry's private repository has its own ECF that includes `simple_bible` and his plug-in cluster, and its own root class that registers the plug-in with `BIB_PLUGIN_REGISTRY` before the app starts. The public executable's registry is empty. **Data** is "when present": each private source's `is_available` checks its file and attaches it; absent files make the plug-in's panels show their absent state (GUI ER-02). The public build is checked by a test that the public target contains no effective `BIB_LENS` descendant and no string naming `scholars.db`, `transcripts.db` or `nakedbiblepodcast` (ledger R-2).

### A-013: rix.db book ids are independent of core.db
**Challenge:** `build_rix_db.py` R12 writes `verse_refs.book_id = bible.db bible_books.id`. A fresh `core.db` with its own book numbering would make the Eiffel port disagree with the Python reference on every row, and would break the author library's "citing this passage" join.
**Verdict:** INVALID as assumed. **CHANGES DESIGN.**
**Action:** FR-105: the canonical book table is a pinned seed (`book_catalog` rows equal to the vault's `bible_books` ids and names), imported as a build step with its own provenance row; `BIB_BOOK_CATALOG` is the single source for ids. The rix.db builder resolves aliases through the same catalog.

### A-014: Shape port acceptance "reproduces published counts" (FR-028)
**Challenge:** The published counts were computed by `shape_db.py` over the vault's `bible.db` (with its import history and its "version 22 = LXX contains the 27 NT books" trap), not over the fresh `core.db`. The two databases differ by design (D-005), so equal counts are not expected. Several shapes rest on MACULA Greek `role` (34% tagged) and Louw-Nida domains, which MACULA labels "MARBLE senses used with permission" from UBS (09 §10), a license nuance for a free redistribution.
**Verdict:** MODIFY. **CHANGES DESIGN** (acceptance and data dependency).
**Action:** FR-028 acceptance becomes a **differential test on the same input**: the Python reference run against a frozen `core.db` fixture versus the Eiffel shapes on that fixture (golden outputs checked in with SHA-256; D-020). Published vault counts become an informative comparison, not a gate. Each ported shape declares its data dependencies (`required_columns`); shapes needing Louw-Nida domains are gated on the license decision (prefer the UBS SDGNT release, CC BY-SA 4.0, per 09 §10). Shapes over private data stay in the plug-in.

### A-015: Differential tests need Python at test time (D-020)
**Challenge:** "Run both on the same input and compare" implies the test suite runs Python; D-020 says nothing in simple_bible requires Python.
**Verdict:** MODIFY.
**Action:** The reference implementation runs on Larry's machine to produce **golden outputs** (databases or TSV) committed as fixtures with SHA-256; simple_bible's tests compare the Eiffel output to the golden with `BIB_DB_COMPARATOR` (the Eiffel port of `validate_rix_db.py`, generalized). Regenerating goldens is a documented maintenance step, outside the product path.

### A-016: Frequency-matched controls are well defined
**Challenge:** "Frequency-matched" depends on the corpus, the frequency band width and a random draw; without a seed, re-runs differ (FR-032, NFR-006).
**Verdict:** VALID with a rule.
**Action:** `BIB_CONTROL_SET` selection is deterministic: band = target frequency +/- a stated percentage in the same corpus and part of speech; draw with the seed stored in the definition (shape 21's fixed-seed precedent); the chosen controls are stored with the run. Editing controls after a run creates a new definition version.

### A-017: The GUI design's "short lookups are synchronous separate queries under 50 ms" is safe
**Challenge:** A synchronous separate call blocks the GUI until the lookup worker answers; if that worker is busy (a prefetch, a slow first open), the GUI waits.
**Verdict:** VALID with a rule.
**Action:** The lookup worker runs only bounded lookups (verse hub, word card, lexicon entry, cross-references), never jobs; prefetch is a job on another processor. `SIMPLE_BIBLE` lookup features carry a documented complexity note and a test asserting p95 < 50 ms on the fixture database.

### A-018: The harvest ledger's WebView2 rows are still valid
**Challenge:** The ledger (written before Larry's D-006 decision) classifies the `bible_htmx` face (H-01..H-07, H-13, T-07) as HARVEST-REWRITE "the primary WebView2 face", and retirement criterion R-4 reads "Hebrew and Greek render correctly in the simple_bible WebView2 face".
**Verdict:** INVALID (overtaken by D-006). **CHANGES DESIGN** (traceability).
**Action:** In this spec those rows trace to nothing in the GUI; they become ARCHIVE-ONLY (prior art for panel content). R-4 should read "in the simple_bible native face". The ledger is authoritative, so the change is an open item for Larry (Q-05); the spec does not edit the ledger.

### A-019: Determinism of builds is automatic
**Challenge:** SQLite row order, floating-point formatting, wall-clock timestamps (`retrieved_at`, `run_at`), file-system walk order and hash-map iteration order can all change output between runs.
**Verdict:** VALID with rules (NFR-018).
**Action:** `BIB_BUILD_CONTEXT` carries the build date (passed in, never read from the clock); every export orders by key; walks follow `build_rix_db.py` R2 ordering; floats are written with a fixed format; per-table checksums (`BIB_TABLE_CHECKSUM`) hash ordered rows. Two builds compared in a test.

### A-020: Fonts can be bundled freely
**Challenge:** simple_shaping's Hebrew fallback names SBL Hebrew and Ezra SIL. Ezra SIL is SIL OFL. The SBL fonts' redistribution terms were not checked in any research file read today.
**Verdict:** NEEDS_VALIDATION.
**Action:** The font set is data with provenance (a `font` row per bundled file, license required by the license gate). Recommendation: SIL OFL fonts only (Ezra SIL; Gentium Plus or Noto Serif for polytonic Greek) unless the SBL terms are verified (Q-03). GW-01 loads them privately.

## Requirements Questioned

### FR-060: "WebView2 front end renders pointed Hebrew"
**Challenge:** Overtaken by D-006.
**Verdict:** MODIFY
**If MODIFY:** The native face renders pointed Hebrew and polytonic Greek with bundled fonts; the D-006 spike offscreen in `SW_LABEL` and `SW_TEXT_BOX` is the acceptance; defects are fixed in simple_shaping (GW-01..03).

### FR-062: Installer detects and installs WebView2
**Verdict:** MODIFY
**If MODIFY:** No WebView2 detection; the installer bundles OFL fonts; keeps `user.db` on uninstall; verified on a non-live identity (standing rule; ledger R-7).

### NFR-012: Loopback server, random port, session token
**Verdict:** REMOVE (withdrawn by D-006; there is no local server).

### FR-028: Shapes reproduce published counts
**Verdict:** MODIFY (A-014): differential test against the Python reference on the same `core.db` fixture.

### FR-030: Quotation comparer, Heb 8:8-12 classified "agrees with LXX"
**Verdict:** KEEP, with the edition note (A-001). The acceptance case is checked on a hand-verified LXX span.

### FR-040: Verse/pericope embeddings shipped
**Verdict:** MODIFY: Release 1 ships the **neighbors** (related passages, AI-made, labeled) computed from the vectors; the vectors themselves ship only when run-time meaning search arrives (v2), which keeps `ai_data.db` small for Release 1. Recommendation, Q-06.

### FR-063: Private plug-in loads rix/scholars/transcripts/primary_evidence
**Verdict:** MODIFY: rix.db ships publicly (D-019); the plug-in narrows to scholars.db, transcripts.db, primary_evidence.db and the lenses (A-012 mechanics).

### FR-044: Model-written chapter overviews
**Verdict:** KEEP as COULD; not in Release 1 (no reviewed overviews exist).

### FR-121 (from the ledger): CLI one-shot with closed command set
**Verdict:** KEEP. It is the only way simple_chat's `@tools-larry` participant survives simple_scholar's retirement (ledger R-6).

## Missing Requirements Identified

| ID | Missing Requirement | How Discovered |
|----|---------------------|----------------|
| FR-NEW-001 (= NFR-016) | No GUI-processor stall from engine work, including GC waits on C externals | A-005, fleet GC law, `sqlite_externals.e:491` |
| FR-NEW-002 | Job progress and pages via a separate mailbox; cancellation via a separate token | A-006 (SCOOP semantics) |
| FR-NEW-003 | Unicode NFD/NFC and Mn category in simple_encoding (LG-01) | A-007 |
| FR-NEW-004 | `repair_state` per Swete verse; OCR caveat on display and on quotation verdicts | A-001 |
| FR-NEW-005 | Stable canonical book ids equal to the vault's (FR-105) | A-013 |
| FR-NEW-006 | Golden-output fixtures with SHA-256 for every differential test | A-015 |
| FR-NEW-007 | Regex search requires a bounded scope (one version by default) | A-002 |
| FR-NEW-008 | Every method record carries the SQLite version and database edition | A-004 |
| FR-NEW-009 | Fonts are provenance-tracked data under the license gate | A-020 |
| FR-NEW-010 | Public-build purity test: no effective lens, no private DB names | A-012, ledger R-2 |
| FR-NEW-011 | Ban `string_value_or_void` / `_or_default` on text columns | A-008 |
| FR-NEW-012 | Omission check: for a pasted or AI-made list, the engine's exhaustive answer and what the list left out (v1.5) | 13 S1, T19 (Logos AI missed 1 Cor 1:14, 1:16) |
| FR-NEW-013 | Text-first guide mode: no commentary, author or lens sections | 13 S9, T21 |
| FR-NEW-014 | Panels expose accessible names and reading-order text; CLI complete for screen readers; memory practice down to one verse | 13 S14, T23 |
| FR-NEW-015 | Notes behind a store seam (database or user-owned Markdown folder) | 13 S5, T11 |
| FR-NEW-016 | User data append-only with history and soft delete; rotating local backup; restore | 13 T10 |
| FR-NEW-017 | Settings, layouts and notes survive every user.db migration (regression test) | 13 T05 |
| FR-NEW-018 | Any phrase copied from any shipped text finds its own verse; Strong's zero-padding insensitive | 13 T07 |
| FR-NEW-019 | Every displayed count states corpus, edition and unit; per-text verse count and seal shown | 13 S11, S2, T18 |
| FR-NEW-020 | Pane link role: lead / follow / follow-only / independent | 13 S12, T13 |
| FR-NEW-021 | Portable mode (one folder, no registry writes) | 13 T14, T02 |

## Design Constraints Validated

| Constraint | Valid? | Notes |
|------------|--------|-------|
| simple_* first | YES | Verified present in `D:\prod` today: simple_sql (+ eiffel_sqlite_2025), simple_mml, simple_encoding, simple_regex, simple_json, simple_hash, simple_diff, simple_file, simple_toml, simple_logger, simple_testing, simple_xml, simple_csv, simple_onnx, simple_graph, simple_cli, simple_console, simple_widgets, simple_shaping, simple_cairo, simple_shell, simple_process, simple_winhttp, simple_datetime. Gaps filed: LG-01 (simple_encoding), LG-03 (simple_sql), LG-04/05 (simple_onnx, optional), FT-01/02 (eiffel_sqlite_2025), GW-01..26 (GUI stack) |
| SCOOP-compatible | YES, with A-005/A-006 changes | One connection per processor; jobs chunked; mailbox and token on their own processors; results copied as plain values; text shaping only on the GUI processor |
| Void-safe | YES | Results use attached types; optional parts are `detachable` with explicit `has_*` queries |
| No Python in product (D-020) | YES | Python remains only to regenerate golden fixtures on Larry's machine (A-015) |
| Fill gaps, no fallback (D-006) | YES | Every gap named with its owning library; panels staged by gap closure, never substituted |
| Unique prefixes (fleet law) | YES | `BIB_` classes; `sbib_` C (none planned) (A-009) |
| Blocking externals (fleet law) | YES once FT-02 lands; engine chunking protects meanwhile | A-005 |
| SQLite 3.31.1 ceiling | YES | A-004 |
| Invariants O(1) (fleet convention) | YES | MML model clauses only in postconditions (R05) |
| No windows in tests | YES | GUI tests offscreen (`write_frame`, `simulate_*`) |

## User-voice evidence (research/13-USER-VOICE)

13's bottom line: the loudest pain is **betrayal of trust** (paywalling owned features, forced redesigns and settings resets, lost or scrambled notes, ads inside Scripture, AI forced into plain search, silently changed text, vendor death: the BibleWorks story), then **complexity**, then **AI accuracy/citations/completeness** (T19-T22 together: 44 items, 26 pages, the largest cluster). Most of the trust themes are answered by decisions already made (D-002 free, D-004 engine owns facts, D-016 no run-time AI, FR-064 no network/telemetry). The assumptions below are the ones the evidence actually moves.

### A-021: Notes belong in `user.db` (09 E03, GUI §8)
**Challenge:** T11 (12 items, 9 pages): users call Logos notes "terrible when compared to any modern notes app" and move them to Obsidian, then miss unified search. Spark S5 asks for notes as Markdown files the user owns. T02 (vendor death) says the same thing from the other side: data must outlive the program.
**Evidence for user.db:** atomic writes, one writer processor, simple backup, verse keys enforced by the schema.
**Evidence against:** lock-in by construction; Larry himself works in Obsidian.
**Verdict:** NEEDS_VALIDATION (13 Q3 is Larry's call). **CHANGES DESIGN** (seam only).
**Action:** Notes go behind a deferred `BIB_NOTE_STORE` with two effective stores: `BIB_DB_NOTE_STORE` (user.db, the default) and `BIB_MARKDOWN_NOTE_STORE` (a user-chosen folder of Markdown files, verse links in a stable syntax, indexed into user.db for search and backlinks; verse links found with `BIB_REFERENCE_DETECTOR`, the same rules that build rix.db). Panels and the CLI see only `BIB_NOTE_STORE`. Which store ships first is Q-11.

### A-022: User data is safe if writes succeed
**Challenge:** T10 (14 items): notes erased by an update (Bible Gateway), highlight citations scrambled (BLB), a prayer list that could not be opened (Logos). "Users forgive bugs; they do not forgive lost notes" (13 gotcha 3).
**Verdict:** INVALID as an assumption. **CHANGES DESIGN.**
**Action:** `BIB_USER_STORE` becomes append-only with history: an edit writes a new version, a delete is a soft delete, both recoverable (contracts in 05 addendum). New `BIB_USER_BACKUP`: rotating local backup of `user.db` (and the note folder index) on exit, restorable from Settings > Data. Highlights and notes are keyed to canonical hub ids (already FR-117), which is exactly what prevents the BLB "scrambled citations" failure when a text is updated.

### A-023: Updates may change settings and workflows
**Challenge:** T05 (11 items): "Every day, it resets to some strange translation"; "How do I recover a prior version"; e-Sword 15 dropping old module formats.
**Verdict:** INVALID. **CHANGES DESIGN** (contract + test).
**Action:** `BIB_USER_STORE.migrate` (schema upgrade of user.db) ensures every setting, layout snapshot and note survives (`settings_preserved` postcondition; regression test with a previous-version fixture). Updates are manual and offline-installable (installer phase). Keeping an old workflow selectable after a redesign is a release-policy rule for /eiffel.intent (13 Q8), not a class.

### A-024: Search "just works" once normalization exists
**Challenge:** T07 (11 items): text copied out of the passage itself finds nothing (Accordance, BLB); Xiphos returns nothing for Hebrew Strong's numbers below 1000 because of zero padding.
**Verdict:** VALID direction, two gaps. **CHANGES DESIGN** (contracts).
**Action:** (1) A golden test: any phrase copied from any shipped text finds its own verse, whatever the punctuation, curly quotes, diacritics, final forms or MapM NBSP; the normalizers therefore fold punctuation and quote variants as well as marks (05 addendum). (2) `BIB_STRONGS_KEY` parsing treats `H1`, `H0001` and `H00001` as one key. (3) Plain search is never routed through AI (already true: no AI path exists in the search engine).

### A-025: Counts are honest if a method record exists
**Challenge:** T18 (9 items): STEP's "Occurs in the Bible NN times" silently counts only the NT for Greek (STEP #93); text changed without notice (Olive Tree Amplified, missing KJV words); a KJV spelling read as a typo ("Jeremy the prophet").
**Verdict:** MODIFY. **CHANGES DESIGN** (rule + small features).
**Action:** (1) **Count-scope rule (S11):** every count the faces show carries corpus, edition and unit; `BIB_METHOD.scope_label` is required non-empty and adapters render it beside the number. (2) **Text seal (S2), user-facing:** `BIB_VERSION_INFO` exposes `verse_count` and `seal` (the build's per-table checksum for that text) so About/Versions can show "KJV 1769 · 31,102 verses · sealed"; a changed text in a later build appears in a generated changelog. Both reuse build data already specified (`BIB_TABLE_CHECKSUM`). (3) The archaic-word helper (S3) is deferred to /eiffel.intent as content work (a sourced gloss table from the vault's KJV vocabulary-shift notes), with the rule that the text's own spelling is never "corrected."

### A-026: Panels in one link set should all follow each other
**Challenge:** T13: the most repeated desktop request in r/LogosBibleSoftware is **follow-only** linking ("super frustrating for the passage you're studying to scroll away when you're scrolling to read the linked commentary"); S12.
**Verdict:** MODIFY. **CHANGES DESIGN** (GUI seam).
**Action:** Each panel has a `link_role`: lead, follow, follow-only, independent. A follow-only panel follows its set but its own scrolling never calls `BIB_LINK_HUB.set_reference` (contract in 05 addendum). Simple layout keeps e-Sword behavior (everything follows); the role chip appears in Study layout.

### A-027: Accessibility can wait for v1.5 (GUI spec: GW-14 at v1.5)
**Challenge:** T23 (11 items, 9 pages): blind users have searched "for literally years"; Logos and Olive Tree are "just not accessible"; a blind writer prefers Windows for long study; low-vision users need giant print and true-black themes. 09 has no accessibility row. Spark S14 ranks it among the five best.
**Evidence for v1.5:** GW-14 (UI Automation bridge) is a simple_shell + simple_widgets subsystem not yet started; a drawn toolkit exposes nothing today.
**Verdict:** NEEDS_VALIDATION (13 Q2: v1 requirement or v2 goal is Larry's call). **CHANGES DESIGN** (panels bridge-ready now).
**Action:** `BIB_PANEL` gets `accessible_name` and a reading-order text query (`spoken_text`) from v1, so the GW-14 bridge has something to expose the day it lands; the CLI already gives screen-reader users a complete text path (it prints transliteration for every Hebrew/Greek word). Copy-with-reference is `Ctrl+C` (GUI §7). Memory practice takes a "verses at a time" count down to one (`BIB_MEMORY_CARD.chunk_size`). Pulling GW-14 into v1 is Q-13.

### A-028: The performance budgets assume an SSD
**Challenge:** T04 (16 items): slowness that grows with the library and indexing that blocks work drive users away; 13 suggests budgets on an 8 GB, CPU-only, **non-SSD** machine (cold start < 3 s, verse jump < 100 ms, whole-Bible word search < 300 ms). NFR-001/017 say "SSD".
**Verdict:** NEEDS_VALIDATION (reference machine is Q-15).
**Action:** No run-time indexing exists in the design (FTS and all indexes are built at build time, I-006), and one bad resource cannot slow the rest (sources open lazily; a failing optional database degrades, ER-02). The numeric budgets and the reference machine (SSD or HDD) are fixed at /eiffel.intent; the engine's chunking and the lookup worker do not change either way.

### A-029: Trust rules are implied by "free tool"
**Challenge:** 13 gotchas 1-5, 12, 13: paywalling owned features, forced updates, commerce inside Scripture, AI forced into plain tasks, tracking, persona chatbots, AI text inserted silently into the user's writing.
**Verdict:** VALID, but they should be written down as rules, not left implicit. Recorded for ratification at /eiffel.intent (Q-14): no tiers, credits or withdrawable features; no ads, store, review prompts or account; donation link (if any) on About only; AI off by default, its own pane, never in plain search, never inserted unlabeled into the user's writing (extends `BIB_AI_TEXT` labeling to paste); no persona chatbots; no sermon generator; no telemetry; no activation or phone-home; open formats for all user data (SQLite + Markdown/CSV export). Every one of these is already true of the Release 1 design; none needs a class.

### A-030: Vendor survival is not a design concern for a free tool
**Challenge:** T02 (19 items) and the BibleWorks story: users kept BW10 running on an offline computer for years, fearing a Windows update with no vendor left; activation codes and closed formats made it worse.
**Verdict:** INVALID. Free tools die too (bus factor, RISK-014).
**Action:** Already in the design: no activation; reproducible build from pinned public sources; all user data in SQLite with documented schemas plus Markdown/CSV export; Spec Kit artifacts and README/docs. Added: a **portable mode** (`BIB_CONFIG.make_portable`: every path beside the executable, no registry writes) so the program runs from one folder or a USB drive (T14).

### Spark dispositions (13 §5, the five best)

| Spark | Disposition | Reason |
|-------|-------------|--------|
| **S1 Omission check** (what an AI answer or pasted list left out) | **Missing requirement FR-NEW-012, v1.5** with Claim Check; class `BIB_COMPLETENESS_CHECK` (claim cluster) | The engine side exists now (exhaustive search/census over keys); what is missing is knowing which exhaustive query a pasted list answers, which is the claim extractor's job (I-P01, v1.5). It is the natural "FAILS bucket" of a list: same law as FR-026 |
| **S6 Local engine server for users' own AIs (MCP + link scheme)** | **Deferred to /eiffel.intent (Q-12)**, with a design recommendation | It reaches the heart of D-004 (outside AIs would get facts from the engine), and the seam already exists: the CLI one-shot command set is exactly what simple_chat uses today. Recommended shape: a fourth face `bible_mcp` speaking MCP over **stdio** (no listening port, so D-006's withdrawal of the loopback server and NFR-011 stay intact), reusing `BIB_COMMAND_SET`, every result with provenance. The fleet has no MCP library (`D:\prod` has no `*mcp*` project today), so it would be a new fleet library (LG-06), not code inside simple_bible. Reasons to defer: protocol library does not exist; opt-in and security stance are Larry's; the `simplebible://` link scheme needs a Windows protocol registration decision |
| **S9 Text-first answer mode** | **Missing requirement FR-NEW-013, v1** (cheap) | Guides are already assembled only from engine results; "text first" is a guide option that excludes library (commentary), author-library and lens sections: `BIB_GUIDE_ASSEMBLER` gets `text_first: BOOLEAN` with a postcondition that no such section appears. No AI is involved in Release 1, so the mode is pure engine |
| **S10 Disagreement map** (positions from public-domain commentaries, no verdict) | **Deferred to /eiffel.intent / v2** | Grouping commentaries into "positions" is a judgment (a T3 act in shape.db terms); the engine cannot derive it deterministically. It needs curated, sourced position data reviewed by a person, and it should reuse the timeline's dispute model (11 §5.3: positions, holders, sources, envelope, no pre-selected lean). Barna's 60% supports it, but it is content work, not engine work |
| **S14 Accessible-first study** | **Missing requirement FR-NEW-014; release by Q-13** | See A-027: panels are bridge-ready in v1 (`accessible_name`, `spoken_text`); the UI Automation bridge itself (GW-14) lives in simple_shell + simple_widgets |

Other sparks: S2 text seal and S11 count-scope label adopted into v1 (A-025); S12 follow-only adopted (A-026); S5 notes as files designed as a seam (A-021); S3 archaic helper, S4 trust rings, S7 map that follows the text, S8 plain-English apparatus, S13 unlock-as-you-go and S15 exhaustive study export are deferred to /eiffel.intent (content or UX policy, no engine change; S4 would generalize `BIB_VOICE` from private material to every resource and is noted as the likely mechanism).

## Verdicts that changed the design (summary)

| ID | Change |
|----|--------|
| A-001 | Swete `repair_state` and OCR caveat; quotation verdicts carry an edition/OCR note; hand-verified LXX spans for seeded quotations |
| A-005 | FT-02 prerequisite (sqlite externals `blocking`); engine chunks long work by book; NFR-016 with a GC-probe test |
| A-006 | `BIB_JOB_MAILBOX` and `BIB_CANCEL_TOKEN` as separate objects; GUI never queries a running job |
| A-007 | LG-01 (NFD/NFC + Mn) in simple_encoding before the Greek normalizer |
| A-008 | Text read only as STRING_32; LG-03 in simple_sql |
| A-009 | Prefix `BIB_` (not `SB_`, which Gobo storable uses); C prefix `sbib_`, zero C planned |
| A-010 | Library content behind one abstraction; Release 1a/1b split recommended (Q-01) |
| A-011 | Engine + CLI first; panels staged by gap closure; gap order fixed |
| A-012 | Plug-in seam is compile-time (private ECF + registrar); data attached when present |
| A-013 | Pinned canonical book table equal to the vault's ids |
| A-014 / A-015 | Shapes and all ports accepted by differential tests on the same input, with golden fixtures |
| FR-040 | Ship neighbors in Release 1, vectors with v2 meaning search (Q-06) |
| A-021 | `BIB_NOTE_STORE` seam (database store; Markdown-folder store) |
| A-022 / A-023 | Append-only user data, soft delete, `BIB_USER_BACKUP`, migration preserves settings |
| A-024 / A-025 | Copied-phrase golden test; Strong's padding; count-scope labels; per-text seal |
| A-026 | Panel `link_role` with follow-only |
| A-027 | Panels bridge-ready for screen readers (`accessible_name`, `spoken_text`) |
| A-030 | Portable mode |
| Sparks | S1 omission check (v1.5, `BIB_COMPLETENESS_CHECK`); S9 text-first guides (v1); S6 MCP and S10 disagreement map deferred to /eiffel.intent with reasons |
