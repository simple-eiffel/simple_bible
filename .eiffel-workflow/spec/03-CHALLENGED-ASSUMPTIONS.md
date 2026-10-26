# CHALLENGED ASSUMPTIONS: simple_bible

*Step R03, 2026-10-06. Attack mindset. Each assumption was checked against files actually read today (research 01-12, the GUI spec set, the Python reference tools, and the fleet's source in the fleet's root folder). Verdicts that changed the design are marked **CHANGES DESIGN**. `research/13-USER-VOICE.md` (294 user items from 96 sources, graded OPENED/SNIPPET, with `13-user-voice-items.csv`) arrived complete during this step and was read in full; its evidence is folded in as A-021 to A-030 and the spark dispositions below. User-voice items are treated as evidence (OPENED quotes weighed above SNIPPET summaries), not as requirements by themselves.*

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
**Evidence for:** Release 1 runs no AI on the user's machine (D-016). The vault's normalized `plain` column gave a 250x speed-up with prefix search (D-009). [SETTLED (fold 2026-10-26, debate 01): this "250x" citation is retired as a proof: `bible_search.db` uses `remove_diacritics` 1, its builder is not on disk, and "250x" has no record.] Whole canon is about 31,000 verses; per-lemma counts are indexed lookups. Lemma frequency tables can be precomputed (control selection is then a table lookup).
**Evidence against:** Regex over all versions is a full scan of roughly 300,000 verse rows in Eiffel; each control count is a separate query.
**Verdict:** VALID.
**Action:** Precompute `lemma_frequency` at build time (`BIB_LEMMA_FREQUENCY_PRECOMPUTE`). Census runs the target and controls as one job on a worker processor, chunked by book. Regex runs only over the selected scope with a scope precondition (`scope_bounded_for_regex`: default scope is one version, never "all versions" without the user choosing it), and streams pages. SETTLED (fold 2026-10-26, debate 01): the regex contract states its target text (display or folded); a folded-text scan costs about 2x without a stored column (lower bound, development machine), and a regex consumer of folded text that misses its p95 budget while a stored column meets it is the trigger OT-N1; which text regex reads is unspecified in the record and stays a spec gap.

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
**Action:** Schema uses CHECK constraints and NOT NULL instead of STRICT; folded index plus prefix queries instead of trigram (a `prefix=` index only if prefix search is gated at 10x) (fold 2026-10-26, debate 01; was "normalized columns plus prefix queries instead of trigram"); transliteration substring search via LIKE on a normalized transliteration column within a bounded scope; all arithmetic (frequencies per 1,000 words, control statistics) in Eiffel. `BIB_DATA_SOURCE.open` checks `sqlite_version() >= "3.31.1"` and records the version in every method record so a later upgrade is visible.
**SETTLED (fold 2026-10-26, debate 04, PREFERRED 0.82 / 0.88):** the binding was upgraded to SQLite 3.53.4 (eiffel_sqlite_2025 1.1.0, verified 2026-10-22); the Release 1 DDL ceiling stays 3.31.1 features (RQ-03 option 2, K9). The "library claims 3.51.1" reading was false: header, object and runtime all reported 3.31.1 until the upgrade.

### A-005: Running long queries on SCOOP worker processors keeps the GUI responsive
**Challenge:** The fleet GC law: a plain `external "C inline"` call that waits blocks every processor at its next allocation during a collection. `eiffel_sqlite_2025` `c_sqlite3_step` is declared `"C inline use <sqlite3.h>"` **without `blocking`** (re-read today, `internals/sqlite_externals.e:491`). The fleet audit listed it as HELD for Larry's gate (patch in place vs fleet-local fork); SETTLED (fold 2026-10-26, debate 04): patch in place, adopted and landed. A census whose single `sqlite3_step` takes seconds on a worker freezes the GUI processor at its next allocation if a collection starts.
**Evidence for:** SCOOP isolates Eiffel execution; the GUI never waits on a worker by design.
**Evidence against:** The GC stall is below SCOOP; it was measured in simple_chat (211 s of freezes in 20 minutes). SETTLED (fold 2026-10-26, debate 04): that 211 s was a WinHTTP long poll, so it is a magnitude for WinHTTP, not for SQLite; the SQLite magnitude is the whole step, 3.2-5.2 s per long step in the F4 probes.
**Verdict:** INVALID as stated. **CHANGES DESIGN.**
**Action:**
1. Prerequisite fleet task **FT-02** (fold 2026-10-26, debate 04; was "mark `c_sqlite3_step`, `c_sqlite3_open_v2`, `c_sqlite3_close` `blocking` in eiffel_sqlite_2025 (Larry's gate on patch-in-place vs fork), bundled with the D-007 upgrade (FT-01) so the fleet regression runs once"): mark six externals (`step`, `prepare_v2`, `open_v2`, `close`, `close_v2`, `backup_step`) `blocking` in eiffel_sqlite_2025 with FT-01 (3.53.4, unchanged flags); one clean campaign on copies before the commit; every dependent rebuilt `-clean` with a generated-C check (`EIF_ENTER_C` around the library's `sqlite3_step`); FT-02 alone on 3.31.1 was the contingency. Landed and verified 2026-10-22.
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
**SETTLED (fold 2026-10-26, debate 01):** the folding rule removes general categories M\* and Cf (K3-A: a zero-width joiner, general category Cf, splits words exactly as a combining grapheme joiner does), maps Hebrew finals and Greek final sigma, and case-folds; an NFD-based fold is the only one that unifies oxia (U+1F79) and tonos (U+03CC). The Eiffel normalizers (F1-C5b) are UNTESTED until LG-01 lands and the corpus-scale residue census passes.

### A-008: simple_sql returns Hebrew and Greek safely
**Challenge:** `SIMPLE_SQL_ROW.string_value` decodes UTF-8 to `STRING_32` (good), but `string_value_or_void` and `string_value_or_default` return `string_value (...).to_string_8`, which fails its precondition on any non-Latin-1 text.
**Verdict:** VALID with a trap. **CHANGES DESIGN** (coding rule).
**Action:** Engine rule: text columns are read only through `string_value` (STRING_32) or a NULL check plus `string_value`; the two narrowing accessors are banned in simple_bible (static check in tests). File **LG-03** against simple_sql: `string_32_value_or_void` / `_or_default` variants, and a note in its README.

### A-009: The fleet prefix `SB_` (the GUI spec's placeholder) is free
**Challenge:** Search of the fleet's root folder today: Gobo's storable library (`gobo-26.06/gobo/library/storable/src/`) defines `SB_ATTRIBUTE`, `SB_CLASS`, `SB_BASIC_OBJECT` and others. simple_xml and simple_regex wrap Gobo; any universe that ever includes Gobo storable would clash.
**Evidence for (alternatives):** `BIB_` is used by no class in the fleet's root folder, in Gobo, or in the ISE 25.02 libraries (searched today). `sbib_` appears in no header, C file or Eiffel file in the fleet's root folder.
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
**Challenge:** Eiffel has no dynamic class loading; a DLL plug-in system is not available in the fleet. "Loaded when present" (FR-063) cannot mean runtime discovery of code. SETTLED (fold 2026-10-26, debate 03, PREFERRED 0.75 / 0.80), premise restated: code in an Eiffel DLL can be loaded through a C ABI (executed: a finalized SCOOP host loaded an Eiffel DLL and ran it); classes cannot cross (documents read, not spiked). The earlier wording that "a DLL plug-in system is not available" is withdrawn as a premise; the claim "A-012's premise is disproven" is also withdrawn (only the C-ABI code reading fell).
**Evidence for:** Data can be discovered at run time (private databases attached when the files exist).
**Verdict:** MODIFY. **CHANGES DESIGN.**
**Action (fold 2026-10-26, debate 03; supersedes the compile-time plug-in seam quoted in the Fold log of `00-FOLD-2026-10-26.md`):** no private code seam in Release 1. Private material arrives as versioned data packs; the lens logic runs once, at export, on Larry's machine; the public engine runs no private code and no rule interpreter. The public engine finds generic private packs by folder and attaches each read-only (`user_version` checked at open; conc.db is a concordance pack with its own check, found by `conc_path`: fold 2026-10-26, settlements S6, G1); absent packs make their panels show their absent state (GUI ER-02). The plug-in facade features are removed before release; `BIB_PRIVATE_SOURCE` becomes an effective, generic pack source. The public build is checked by test K2′: no string from the R-2 list in ASCII, UTF-16LE or UTF-32LE, with a positive control that includes a `{STRING_32}` private string (ledger R-2).

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
**Action:** The lookup worker runs only bounded lookups (verse hub, word card, lexicon entry, cross-references), never jobs; prefetch is a job on another processor. `SIMPLE_BIBLE` lookup features carry a documented complexity note and a test asserting p95 < 50 ms on the fixture database. The 50 ms figure is the verse-and-word lookup budget only; the concordance first screen (about 200 ms warm, up to 2.8 s cold) is NFR-019 with the builder precomputations as its mitigation (RISK-038) (fold 2026-10-26, settlement S5).

### A-018: The harvest ledger's WebView2 rows are still valid (historical quote: the WebView2 face is superseded by D-006, native simple_widgets; fold 2026-10-26, D-006)
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

### FR-060: "WebView2 front end renders pointed Hebrew" (historical quote, superseded by D-006: native simple_widgets face; fold 2026-10-26, D-006)
**Challenge:** Overtaken by D-006.
**Verdict:** MODIFY
**If MODIFY:** The native face renders pointed Hebrew and polytonic Greek with bundled fonts; the D-006 spike offscreen in `SW_LABEL` and `SW_TEXT_BOX` is the acceptance; defects are fixed in simple_shaping (GW-01..03).

### FR-062: Installer detects and installs WebView2 (historical quote, superseded by D-006: no WebView2 detection; fold 2026-10-26, D-006)
**Verdict:** MODIFY
**If MODIFY:** No WebView2 detection; the installer bundles OFL fonts; keeps `user.db` on uninstall; verified on a non-live identity (standing rule; ledger R-7).

### NFR-012: Loopback server, random port, session token
**Verdict:** REMOVE (withdrawn by D-006; there is no local server).

### FR-028: Shapes reproduce published counts
**Verdict:** MODIFY (A-014): differential test against the Python reference on the same `core.db` fixture.

### FR-030: Quotation comparer, Heb 8:8-12 classified "agrees with LXX"
**Verdict:** KEEP, with the edition note (A-001). The acceptance case is checked on a hand-verified LXX span.

### FR-040: Verse/pericope embeddings shipped
**Verdict:** MODIFY: Release 1 ships the **neighbors** (related passages, AI-made, labeled) computed from the vectors; the vectors themselves ship only when run-time meaning search arrives (v2), which keeps the AI-data stage small for Release 1 (fold 2026-10-26, debate 01: `ai_data.db` is a build stage, not a shipped file; was "`ai_data.db` small"). Recommendation, Q-06.

### FR-063: Private plug-in loads rix/scholars/transcripts/primary_evidence
**Verdict:** MODIFY: rix.db ships publicly (D-019); private material (scholars, transcripts and primary_evidence content, lens annotations, `machine_generated.db`, the concordance pack) arrives as versioned private packs read by the generic public pack reader, with no plug-in (A-012 as settled) (fold 2026-10-26, debate 03; supersedes "the plug-in narrows to scholars.db, transcripts.db, primary_evidence.db and the lenses (A-012 mechanics)").

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
| FR-NEW-010 | Public-build purity test K2′: no string from the R-2 list in ASCII, UTF-16LE or UTF-32LE, positive control including a `{STRING_32}` private string; the clause "no effective lens" is dropped, there being no lens class (fold 2026-10-26, debate 03; was "no effective lens, no private DB names") | A-012, ledger R-2 |
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
| simple_* first | YES | Verified present in the fleet's root folder today: simple_sql (+ eiffel_sqlite_2025), simple_mml, simple_encoding, simple_regex, simple_json, simple_hash, simple_diff, simple_file, simple_toml, simple_logger, simple_testing, simple_xml, simple_csv, simple_onnx, simple_graph, simple_cli, simple_console, simple_widgets, simple_shaping, simple_cairo, simple_shell, simple_process, simple_winhttp, simple_datetime. Gaps filed: LG-01 (simple_encoding), LG-03 (simple_sql), LG-04/05 (simple_onnx, optional), FT-01/02 (eiffel_sqlite_2025), GW-01..26 (GUI stack) |
| SCOOP-compatible | YES, with A-005/A-006 changes | One connection per processor; jobs chunked; mailbox and token on their own processors; results copied as plain values; text shaping only on the GUI processor |
| Void-safe | YES | Results use attached types; optional parts are `detachable` with explicit `has_*` queries |
| No Python in product (D-020) | YES | Python remains only to regenerate golden fixtures on Larry's machine (A-015) |
| Fill gaps, no fallback (D-006) | YES | Every gap named with its owning library; panels staged by gap closure, never substituted |
| Unique prefixes (fleet law) | YES | `BIB_` classes; `sbib_` C (none planned) (A-009) |
| Blocking externals (fleet law) | YES: FT-02 landed (six externals `blocking`, every dependent rebuilt `-clean`, verified 2026-10-22); engine chunking still bounds each step (fold 2026-10-26, debate 04; was "YES once FT-02 lands") | A-005 |
| SQLite 3.31.1 ceiling | YES | A-004 |
| Invariants O(1) (fleet convention) | YES | MML model clauses only in postconditions (R05) |
| No windows in tests | YES | GUI tests offscreen (`write_frame`, `simulate_*`) |

## User-voice evidence (research/13-USER-VOICE)

13's bottom line: the loudest pain is **betrayal of trust** (paywalling owned features, forced redesigns and settings resets, lost or scrambled notes, ads inside Scripture, AI forced into plain search, silently changed text, vendor death: the BibleWorks story), then **complexity**, then **AI accuracy/citations/completeness** (T19-T22 together: 44 items, 26 pages, the largest cluster). Most of the trust themes are answered by decisions already made (D-002 free, D-004 engine owns facts, D-016 no run-time AI, FR-064 no network/telemetry). The assumptions below are the ones the evidence actually moves.

### A-021: Notes belong in `user.db` (09 E03, GUI §8)
**Challenge:** T11 (12 items, 9 pages): users call Logos notes "terrible when compared to any modern notes app" and move them to Obsidian, then miss unified search. Spark S5 asks for notes as Markdown files the user owns. T02 (vendor death) says the same thing from the other side: data must outlive the program.
**Evidence for user.db:** atomic writes, one writer processor, simple backup, verse keys enforced by the schema.
**Evidence against:** lock-in by construction; Larry himself works in Obsidian.
**Verdict:** NEEDS_VALIDATION (13 Q3 is Larry's call). **CHANGES DESIGN** (seam only). **SETTLED (fold 2026-10-26, debate 02, PREFERRED 0.70 / 0.80):** `user.db` first, under Q-11's own fallback.
**Action:** Notes go behind a deferred `BIB_NOTE_STORE` with two effective stores: `BIB_DB_NOTE_STORE` (user.db, the default) and `BIB_MARKDOWN_NOTE_STORE` (a user-chosen folder of Markdown files, verse links in a stable syntax, indexed into user.db for search and backlinks; verse links found with `BIB_REFERENCE_DETECTOR`, the same rules that build rix.db). Panels and the CLI see only `BIB_NOTE_STORE`. (fold 2026-10-26, debate 02; supersedes "Which store ships first is Q-11."): `BIB_DB_NOTE_STORE` is the Release 1a default and `BIB_MARKDOWN_NOTE_STORE` becomes the Release 1b candidate (file-authoritative A″, UNTESTED, gated); Release 1a adds an export and import feature set beside `BIB_DB_NOTE_STORE` (and the exit snapshot B′ if DS-B′ passes). Q-11 is answered by its own fallback ("Otherwise user.db first"). FR-NEW-015's row is unchanged in substance.

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
| **S6 Local engine server for users' own AIs (MCP + link scheme)** | **Deferred to /eiffel.intent (Q-12)**, with a design recommendation | It reaches the heart of D-004 (outside AIs would get facts from the engine), and the seam already exists: the CLI one-shot command set is exactly what simple_chat uses today. Recommended shape: a fourth face `bible_mcp` speaking MCP over **stdio** (no listening port, so D-006's withdrawal of the loopback server and NFR-011 stay intact), reusing `BIB_COMMAND_SET`, every result with provenance. The fleet has no MCP library (the fleet's root folder has no `*mcp*` project today), so it would be a new fleet library (LG-06), not code inside simple_bible. Reasons to defer: protocol library does not exist; opt-in and security stance are Larry's; the `simplebible://` link scheme needs a Windows protocol registration decision |
| **S9 Text-first answer mode** | **Missing requirement FR-NEW-013, v1** (cheap) | Guides are already assembled only from engine results; "text first" is a guide option that excludes library (commentary), author-library and lens sections: `BIB_GUIDE_ASSEMBLER` gets `text_first: BOOLEAN` with a postcondition that no such section appears. No AI is involved in Release 1, so the mode is pure engine |
| **S10 Disagreement map** (positions from public-domain commentaries, no verdict) | **Deferred to /eiffel.intent / v2** | Grouping commentaries into "positions" is a judgment (a T3 act in shape.db terms); the engine cannot derive it deterministically. It needs curated, sourced position data reviewed by a person, and it should reuse the timeline's dispute model (11 §5.3: positions, holders, sources, envelope, no pre-selected lean). Barna's 60% supports it, but it is content work, not engine work |
| **S14 Accessible-first study** | **Missing requirement FR-NEW-014; release by Q-13** | See A-027: panels are bridge-ready in v1 (`accessible_name`, `spoken_text`); the UI Automation bridge itself (GW-14) lives in simple_shell + simple_widgets |

Other sparks: S2 text seal and S11 count-scope label adopted into v1 (A-025); S12 follow-only adopted (A-026); S5 notes as files designed as a seam (A-021); S3 archaic helper, S4 trust rings, S7 map that follows the text, S8 plain-English apparatus, S13 unlock-as-you-go and S15 exhaustive study export are deferred to /eiffel.intent (content or UX policy, no engine change; S4 would generalize `BIB_VOICE` from private material to every resource and is noted as the likely mechanism).

## Settled by the gated verdicts: every "Do not assume" entry (fold 2026-10-26)

*Each entry below is a locked input copied from section 6 of a gated verdict (debate 05a: its "Do not assume" list); none reopens a decision. Every row has the status SETTLED (the verdict names the reason; the evidence is in the verdict). "3.31.1?" marks a finding specific to the SQLite 3.31.1 build; no scoring run of debate 01 touched 3.53.4. Where an entry was already held above as a challenged assumption, it is marked settled there and only pointed to here. Verdict paths are under `.eiffel-workflow/`.*

### Debate 01: runtime database layout and search normalization (fold 2026-10-26, debate 01)

*Verdict: `debate/01 - Runtime database layout and search normalization (D-015 + D-009)/04 - VERDICT.md` §6; B-S and TN-R / R-N4v both PREFERRED; Larry's gate 2026-10-22: adopted.*

| # | Do not assume (status SETTLED) | Settled as | 3.31.1? | Ref |
|---|---|---|---|---|
| 1 | "AC-1a-10 requires the shipped file to be R15-exact" | Its object is the builder's output (`intent-v2.md:55`); the phrase came from spec 07 via the register | No | 01 §6.1 |
| 2 | "`validate_rix_db.py` checks page size and encoding" | Its docstring says so; the code only prints them and never reads `user_version` | No | 01 §6.2 |
| 3 | "Every shipped table can carry a provenance column" | R15 tables ship without one, and FTS5 shadow tables have fixed DDL; the measure is K7-A | No | 01 §6.3 |
| 4 | "A bare `PRAGMA foreign_key_check` verifies one file's provenance" | On 3.31.1 it resolved a parent in an attached file and passed; always name the schema, packs included (3.53.4 reports the violation, so debate 01's finding holds; debate 04, ADJ-f1-recheck) | Yes | 01 §6.4 |
| 5 | "A cross-file foreign key cannot be declared" | It can, with a bare parent name; it cannot name or resolve to another schema | No | 01 §6.5 |
| 6 | "FTS5 `integrity-check` verifies a contentless index on 3.31.1" | Code 11 on a sound contentless index, the same code as real corruption | Yes | 01 §6.6 |
| 7 | "A contentless index cannot be verified on 3.31.1" | It can: integrity-check the external-content stage, then prove identity of the four shadow tables | No | 01 §6.7 |
| 8 | "A folded word search finds Hebrew words with clitic prefixes" | Whole tokens only (392 article-prefixed rows missed for the elohim key); prefixes need lemma search or a declared second form with a named consumer | No | 01 §6.8 |
| 9 | "On pointed Hebrew, the default tokenizer's hit count is a recall baseline" | It cuts words into letter fragments and matches inside and across words | No | 01 §6.9 |
| 10 | "Two Greek spellings that look identical are one token" | Oxia (U+1F79) and tonos (U+03CC) differ to unicode61; only an NFD-based fold unifies them | No | 01 §6.10 |
| 11 | "Rowid-range timings include the range lookup and a cold cache" | Warm, with the lookup outside the timer | No | 01 §6.11 |
| 12 | "An OR of rowid ranges is a range filter" | The planner drops it; use one range query per range (seen on 3.31.1 and 3.50.4) | Seen on both | 01 §6.12 |
| 13 | "K5 passes, so search is fast at scale" | K5 times the one scale-free shape; breakdowns, subsets and prefixes grow with the corpus | No | 01 §6.13 |
| 14 | "FT-01 fixes search speed" | The 3.50.4 join form is FTS-first and reached p50 209 ms, worst 6.9 s at 10x (lead only) | Lead only | 01 §6.14 |
| 15 | "The join-form slowness is how SQLite behaves" | It is the 3.31.1 planner; 3.50.4 plans it differently (lead) | Yes | 01 §6.15 |
| 16 | "`WHERE rix.docs_fts MATCH` works" | An error on 3.31.1 and on 3.53.4; use the bare table name or an alias (fold 2026-10-26, settlement S2; was "An error on 3.31.1") | No: also 3.53.4 (debate 04, ADJ-f1-recheck; fold 2026-10-26, settlement S2; was "Yes") | 01 §6.16 |
| 17 | "Trigram or a v2 tokenizer is available" | Not in 3.31.1 (trigram create failed; API v1 only) | Yes | 01 §6.17 |
| 18 | "`ATTACH 'file:...?mode=ro'` attaches read-only" | Failed with CANTOPEN on the 3.31.1 build (URI off). Settled: use `SIMPLE_SQL_DATABASE.attach_read_only` (simple_sql 5a17f97, 2026-10-08; executed by debate 05a on 3.53.4, write refused) (fold 2026-10-26, settlement S1; was "read-only is inherited from a read-only main, attach through `query (\"ATTACH ...\")`") | Build flag | 01 §6.18 |
| 19 | "`SIMPLE_SQL_FTS5.table_exists` sees attached tables" | Main only | No (library) | 01 §6.19 |
| 20 | "B needs no ATTACH" | Debate 03 puts pack attachment in the public 1a engine | No | 01 §6.20 |
| 21 | "The attach budget holds through v2" | Not with an open pack count; any layout overflows at 11 packs without an attach policy | Limit is a compile default | 01 §6.21 |
| 22 | "Normalization is uniform across packs" | Only where the Eiffel normalizer folded the pack, or its parity fixture passed | No | 01 §6.22 |
| 23 | "Removing M\* and Cf by general category is proven at corpus scale" | Only a six-character prune ran on the corpus; the category rule ran on the trap corpus and on rix.db, in Python | No | 01 §6.23 |
| 24 | "Query-time expansion cannot do folded phrases" | Only the Cartesian form ran, and nothing above its own cutoff | No | 01 §6.24 |
| 25 | "The 6-10 s term-map build is the cold-start cost" | Contracts on, load undisclosed, 67% spread between identical runs | No | 01 §6.25 |
| 26 | "The 1.07 s vs 0.53 s scan figures are the real normalizer's cost" | A proxy fold without NFD on the development machine: a lower bound | No | 01 §6.26 |
| 27 | "D-009's `bible_search.db` proves stored normalization" | Retired as a proof (recorded at A-002 above) | No | 01 §6.27 |
| 28 | "The dev machine is faster than the reference machine" | Unproven: Q-15 defines the reference machine by RAM, CPU-only and SSD | No | 01 §6.28 |
| 29 | "Any 3.31.1-specific line above holds on 3.53.4" | No run touched 3.53.4; re-run before relying on it | n/a | 01 §6.29 |

### Debate 02: notes store (fold 2026-10-26, debate 02)

*Verdict: `debate/02 - Notes store (RQ-06)/04 - VERDICT.md` §6; pathway B PREFERRED; Larry's gate 2026-10-22: adopted.*

| # | Do not assume (status SETTLED) | Settled as | Ref |
|---|---|---|---|
| 1 | "simple_sql `atomic` rolls back when a statement fails" | DISPROVEN (ADJ-p-atomic: A1 and A2 committed 2 of 2 with `has_error` False); fixed by F-9 (landed) | 02 §6.1 |
| 2 | "A migration whose `migrate` returned True applied cleanly" | DISPROVEN (M1 stamped `user_version=1` on a migration whose middle statement failed) | 02 §6.2 |
| 3 | "`has_error` after several statements reflects all of them" | DISPROVEN (A3: last statement only) | 02 §6.3 |
| 4 | "`execute_with_args` reports failures" or "uses bind variables" | DISPROVEN (literal substitution, no failure reporting) | 02 §6.4 |
| 5 | "SQLite lost 0 of 33,572 confirmed commits" | Cite "0 lost of 33,552 verified ledger entries in 600 process kills"; never as power-loss evidence (DELETE+FULL is not necessarily durable across a power loss) | 02 §6.5 |
| 6 | "`simple_file.write_text` is crash-safe" | DISPROVEN (112 of 200 and 28 of 100 emptied); cite the existence of the window, never a rate | 02 §6.6 |
| 7 | "`simple_file.read_text` decodes UTF-8" | DISPROVEN (41 characters for 25), although its header says "(UTF-8 default)" | 02 §6.7 |
| 8 | "`write_text` fails silently in a ReadOnly-attribute folder" | False as worded: it returns False and sets `last_error`; the defects are that it refuses what Windows allows and that callers ignored the Boolean | 02 §6.8 |
| 9 | "`ReplaceFileW` with a backup name is atomic or closes the race" | DISPROVEN (15 lost, 0 caught, some with success returned); its internal step order is inferred | 02 §6.9 |
| 10 | "Hold-then-rename is safe with real editors" | UNTESTED (0 of 32,659 lost against a retrying synthetic writer; it refused 24,527 saves) | 02 §6.10 |
| 11 | "A race-safe save keeps every note readable at every moment" | DISPROVEN for every race-safe primitive on the record (name absent in 12 of 200 and 10 of 200 kills until recovery) | 02 §6.11 |
| 12 | "SHA-256 detected 20 of 20 edits" as a detection rate | A tautology counted twice | 02 §6.12 |
| 13 | "A full-hash reconcile takes about 2.7 s at 10,000 notes" | A sum of passes on 1,254-byte notes; at the vault's median size it took 14.2-14.6 s | 02 §6.13 |
| 14 | "`simple_file.files` can drive a reconcile at scale" | 3.9-7.7 s for the listing alone at 100,000 entries | 02 §6.14 |
| 15 | "simple_hash is fine for any file a vault holds" | 9-13 MB/s and a working set about 4x the file (350 MB file: 2,140 MB) | 02 §6.15 |
| 16 | "A note titled with a verse reference is a visible file" | DISPROVEN (`John 3:16.md` became `John 3`, 0 bytes, body in a hidden stream); names are file-safe (F-SN) | 02 §6.16 |
| 17 | "A conflict copy is a new note" | It carries the original's front-matter id; a duplicate-id state follows | 02 §6.17 |
| 18 | "The single-instance lock protects against a second device" | Session namespace only | 02 §6.18 |
| 19 | "OneDrive is safe for plain file IO" | One device, one client (26.173.0906.0008) only; the race file was not yet cloud-managed during the trials | 02 §6.19 |
| 20 | "B's store share of cold start is 11-19 ms in 15 of 16 runs" | It was 11-35 ms with an empty lookup; cite 38-43 ms at 100,000 notes, development machine, not the reference machine | 02 §6.20 |
| 21 | "B′ meets K7" or "a start-time backup closes B's S8 residue" | Both UNTESTED | 02 §6.21 |
| 22 | "Any pathway survives power loss or an OS crash" | UNTESTED for all | 02 §6.22 |

### Debate 03: private plug-in seam (fold 2026-10-26, debate 03)

*Verdict: `debate/03 - Private plug-in seam (D-014)/04 - VERDICT.md` §6; pathway B′ PREFERRED; Larry's gate 2026-10-06: adopted.*

| # | Do not assume (status SETTLED) | Settled as | Ref |
|---|---|---|---|
| 1 | "`GAP_DETECTOR` runs on demand in simple_scholar" | `graph` is never assigned; no face calls `gaps` (grep by four seats) | 03 §6.1 |
| 2 | "B′'s precompute costs about 41 s" (without "two lenses plus a networkx analogue") | The verbatim Eiffel code took 163 s at 3,200 synthetic nodes; the real-graph export cost is unmeasured (OT-5) | 03 §6.2 |
| 3 | "B needs a public rule interpreter" | True of B as filed only | 03 §6.3 |
| 4 | "Only pathway A enforces voice presence at compile time" | DISPROVEN: public `make_success` requires `BIB_VOICE` | 03 §6.4 |
| 5 | "A-012's premise is disproven" / "Eiffel lens classes can be loaded at run time" | Only the C-ABI code reading fell (settled at A-012 above) | 03 §6.5 |
| 6 | "A clean private rebuild takes 358 s" | No log holds it; the measured figures are 412 s (toy) and 691 s (real skeleton) | 03 §6.6 |
| 7 | "An incremental private rebuild picks up public changes" | `log_07` ran stale code | 03 §6.7 |
| 8 | "An ECF override applies to a class in a library reached through another library" | ES 25.02: silently ignored, exit 0 | 03 §6.8 |
| 9 | "An ASCII binary scan proves no private string ships" | `{STRING_32}` manifests are stored as UTF-32LE; scan three encodings (K2′) | 03 §6.9 |
| 10 | "All pathways meet K7" (without "at today's private set") | Headroom is 2-3, and a new private database appeared on 2026-10-06 | 03 §6.10 |
| 11 | "`ATTACH 'file:...?mode=ro'` attaches read-only" | URI handling was off on SQLite 3.31.1; it created a writable alternate stream. Settled: use `SIMPLE_SQL_DATABASE.attach_read_only` (simple_sql 5a17f97, 2026-10-08; debate 05a executed it on 3.53.4) (fold 2026-10-26, settlement S1) | 03 §6.11 |
| 12 | "`execute ("ATTACH ...")` works on a read-only connection" | Precondition `database_is_writable`; on a read-only connection use `SIMPLE_SQL_DATABASE.attach_read_only` (fold 2026-10-26, settlement S1; was "use `query`") | 03 §6.12 |
| 13 | "The harvested S-10 SQL handles cross-chapter ranges" | It does not; fix it in the rewrite whatever the pathway | 03 §6.13 |
| 14 | "BLUE's facet spike shows order equality" | The order was borrowed by construction; set equality was tested | 03 §6.14 |
| 15 | "Python-harness results hold on the fleet's SQLite 3.31.1" | Not run there (OT-7) | 03 §6.15 |
| 16 | "B′'s K9 = 0 depends on the export not linking `simple_bible`" | Packs are versioned data checked at open (ADJ-1); a public release forces export work only when it bumps the pack schema version | 03 §6.16 |
| 17 | "simple_process can serve a stdio protocol" or "decodes UTF-8" | No stdin write; Hebrew 0 of 1000 as shipped | 03 §6.17 |
| 18 | "On-demand private analysis parallelizes across SCOOP workers" | 16 workers ran slower than serial; the cause is a lead, not a finding | 03 §6.18 |
| 19 | "Private corpus queries light up in 1a" | They ride on FR-116 (1b) and on search covering packs, which is not yet specified | 03 §6.19 |

### Debate 04: SQLite library, patch in place or fork (fold 2026-10-26, debate 04)

*Verdict: `debate/04 - SQLite library - patch in place or fork (Q-02)/04 - VERDICT.md` §6; A″ as adjudicated PREFERRED; Larry's gate 2026-10-22: adopted, landed.*

| # | Do not assume (status SETTLED) | Settled as | Ref |
|---|---|---|---|
| 1 | "The library links SQLite 3.51.1" | False: header, object and runtime all reported 3.31.1 before the upgrade (recorded at A-004 above) | 04 §6.1 |
| 2 | "Marking `step` is safe with an Eiffel hook installed" | Segfaults with two hook types and a silent insert failure; the hooks were later made safe (`e80c57c`, gate 2026-10-22), and there is no guard (fold 2026-10-26, settlement S3) | 04 §6.2 |
| 3 | "The hook guard's precondition protects every build" | A lean build drops it; only the body check refuses there. Moot: the guard was lifted (`e80c57c`); no guard remains (fold 2026-10-26, settlement S3) | 04 §6.3 |
| 4 | "`EIFFEL_CALL` in `esqlite.c` fixes the hooks" | Compiles to nothing without `EIF_THREADS` | 04 §6.4 |
| 5 | "`/DEIF_THREADS` is harmless to add" | Inert for the stock `esqlite.c`; with re-entry code every non-concurrent link fails | 04 §6.5 |
| 6 | "The re-entry fix is finished" | Crash removed for two hooks; 11-28 ms for a per-row callback; non-concurrent link unsolved; no runtime reviewer | 04 §6.6 |
| 7 | "simple_sql's busy timeout is an Eiffel callback" | It is SQLite's C `sqliteDefaultBusyCallback` | 04 §6.7 |
| 8 | "A dependent rebuilt without `-clean` carries the markers" | It keeps the bare call with exit 0 (C-020) | 04 §6.8 |
| 9 | "A linked-version test proves FT-02 reached a dependent" | The object is current; the stale part is the generated C | 04 §6.9 |
| 10 | "FP_DIGITS = 15 restores 3.31.1 output" | Not for `json_object` or `quote()` | 04 §6.10 |
| 11 | "Every REAL renders differently on 3.53.4" | Only values whose 15-digit text does not round-trip (`0.1` stays `0.1`; `0.1+0.2` changes) | 04 §6.11 |
| 12 | "No REAL is ever stored as text in the fleet" | Not checked: a REAL bound into a TEXT-affinity column is converted by SQLite on storage, and SQL built from fragments escapes a grep | 04 §6.12 |
| 13 | "Only reporting changed in `PRAGMA compile_options`" | Five vendor defaults changed in effect (K1′ corrected) | 04 §6.13 |
| 14 | "FT-01 and FT-02 must ship together" | No technical dependency | 04 §6.14 |
| 15 | "FT-01 gives simple_bible 1a a feature it uses" | No feature (K9; RQ-03 option 2) | 04 §6.15 |
| 16 | "3.53.4 is faster than 3.31.1" | The only datum compared runs on a shared machine | 04 §6.16 |
| 17 | "K2 (b) holds under multi-processor connection churn" | 65-582 ms marked | 04 §6.17 |
| 18 | "A-005's 211 s was a SQLite stall" | It was a WinHTTP long poll (recorded at A-005 above) | 04 §6.18 |
| 19 | "A fork could coexist with the old library in one executable" | 275 duplicate symbols (`.obj`) or silent substitution (`.lib`) | 04 §6.19 |
| 20 | "A bare `PRAGMA foreign_key_check` checks only `main`" (debate 01) | On 3.31.1 it resolves a parent in an attached file and passes; on 3.53.4 it reports the violation; name the schema on both | 04 §6.20 |
| 21 | "`WHERE schema.fts MATCH` works on 3.53.4" | It errors on 3.53.4 as on 3.31.1; debate 01's entry is not 3.31.1-specific, and the workaround stands on every version (fold 2026-10-26, settlement S2) | 04 §6.21 |
| 22 | "The attach limit rose with the upgrade" | `SQLITE_MAX_ATTACHED 10` on both; attach #11 fails on both | 04 §6.22 |
| 23 | Counts from the ripgrep-based Grep tool over the fleet's root folder | It undercounted; use GNU `grep` | 04 §6.23 |
| 24 | "The library's own test target tests anything" | It roots at `ANY.default_create` | 04 §6.24 |

### Debate 05a: concordance pack placement and transliteration (fold 2026-10-26, debate 05)

*Verdict: `debate/05 - Concordance placement and lookups (D-021)/04a - SETTLED BY SPIKE - pack and transliteration.md`, "Do not assume"; fork 1 ESTABLISHED, fork 4 PREFERRED; Larry's gate 2026-10-26: approved.*

| # | Do not assume (status SETTLED) | Settled as | Ref |
|---|---|---|---|
| 1 | That an every-place list can be loaded whole for any word | Page it (first 200 rows: 25-28 ms; whole list up to 0.9 s lean for the Greek article) | 05a DNA 1 |
| 2 | That a contract build's timings say anything about the shipped build | 20x on large reads; the shipped build is lean and timing tests use `without_contracts` | 05a DNA 2 |
| 3 | That `perform` can ATTACH on a read-only connection | It fails in contract builds; use `attach_read_only` | 05a DNA 3 |
| 4 | That a cursor left early releases SQLite's read lock | Close it (simple_sql class note, scan 22) | 05a DNA 4 |
| 5 | That `ORDER BY` on an unindexed column is lazy | SQLite sorts every row before the first step | 05a DNA 5 |

### Debate 05b: engine classes for the concordance (fold 2026-10-26, debate 05)

*Verdict: `debate/05 - Concordance placement and lookups (D-021)/04b - VERDICT.md` §6; pathway B PREFERRED (0.70 / 0.80); Larry's gate 2026-10-26: approved.*

| # | Do not assume (status SETTLED) | Settled as | Ref |
|---|---|---|---|
| 1 | That core.db cannot answer headword or English queries | The source examined was bible.db; spec/07:39 plans `lemma` and `alignment` for core.db (UNTESTED; overturn trigger 1) | 05b §6.1 |
| 2 | That core's lemma keys are the pack's `lemma_id` | Live `BIB_LEMMA_KEY` is lemma text (language plus MACULA/OSHB lemma text) | 05b §6.2 |
| 3 | That the word view's first screen meets 200 ms for frequent words | About 260 ms of measured queries run one after another (Greek article); see NFR-019 in 01 | 05b §6.3 |
| 4 | That `BIB_HEADWORD_KEY` can inherit `BIB_KEY` safely while `count` has no precondition | It would accept a headword key core.db cannot answer; not adopted now; add only if it does not conform to `BIB_KEY`, or if `count` gains a rejecting precondition; compile first | 05b §6.4 |
| 5 | That melt-compiled skeletons predict runtime, final size or Phase 4 line counts | They do not | 05b §6.5 |
| 6 | That a deferred class with one implementor is "pushing abstractions up" | The record shows no duplication to push (see C-022 in 01) | 05b §6.6 |
| 7 | That B's "one existing file" excludes `BIB_CONFIG` | `conc_path` is shared by all pathways | 05b §6.7 |

## Verdicts that changed the design (summary)

| ID | Change |
|----|--------|
| A-001 | Swete `repair_state` and OCR caveat; quotation verdicts carry an edition/OCR note; hand-verified LXX spans for seeded quotations |
| A-005 | FT-02 prerequisite (six sqlite externals `blocking`, landed; fold 2026-10-26, debate 04); engine chunks long work by book; NFR-016 with a GC-probe test |
| A-006 | `BIB_JOB_MAILBOX` and `BIB_CANCEL_TOKEN` as separate objects; GUI never queries a running job |
| A-007 | LG-01 (NFD/NFC + Mn) in simple_encoding before the Greek normalizer |
| A-008 | Text read only as STRING_32; LG-03 in simple_sql |
| A-009 | Prefix `BIB_` (not `SB_`, which Gobo storable uses); C prefix `sbib_`, zero C planned |
| A-010 | Library content behind one abstraction; Release 1a/1b split recommended (Q-01) |
| A-011 | Engine + CLI first; panels staged by gap closure; gap order fixed |
| A-012 | No private code seam in Release 1: private material arrives as versioned data packs, lens logic runs at export (fold 2026-10-26, debate 03; was "Plug-in seam is compile-time (private ECF + registrar); data attached when present") |
| A-013 | Pinned canonical book table equal to the vault's ids |
| A-014 / A-015 | Shapes and all ports accepted by differential tests on the same input, with golden fixtures |
| FR-040 | Ship neighbors in Release 1, vectors with v2 meaning search (Q-06) |
| A-021 | `BIB_NOTE_STORE` seam; `BIB_DB_NOTE_STORE` is the 1a default, `BIB_MARKDOWN_NOTE_STORE` the gated 1b candidate (fold 2026-10-26, debate 02) |
| A-022 / A-023 | Append-only user data, soft delete, `BIB_USER_BACKUP`, migration preserves settings |
| A-024 / A-025 | Copied-phrase golden test; Strong's padding; count-scope labels; per-text seal |
| A-026 | Panel `link_role` with follow-only |
| A-027 | Panels bridge-ready for screen readers (`accessible_name`, `spoken_text`) |
| A-030 | Portable mode |
| Sparks | S1 omission check (v1.5, `BIB_COMPLETENESS_CHECK`); S9 text-first guides (v1); S6 MCP and S10 disagreement map deferred to /eiffel.intent with reasons |
| A-002 / A-004 / A-007 (settled by debate 01 and 04) | Folded index replaces "normalized columns"; the 250x citation is retired; the binding is 3.53.4 with a 3.31.1 DDL ceiling; the folding rule removes M\* and Cf (fold 2026-10-26, debate 01, debate 04) |
| All six "Do not assume" lists | 106 entries recorded as SETTLED in the section above (debate 01: 29, debate 02: 22, debate 03: 19, debate 04: 24, debate 05a: 5, debate 05b: 7) (fold 2026-10-26, debates 01 to 05) |
