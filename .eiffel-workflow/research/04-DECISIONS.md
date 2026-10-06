# DECISIONS: simple_bible

*D-001 to D-004 were made by Larry on 2026-10-06 and are recorded, not reopened. D-005 onward are research recommendations for /eiffel.spec; those marked PENDING LARRY need his call.*

## Decision Log

### D-001: Clean new project; simple_scholar retired after harvest (LARRY, DECIDED)
**Question:** Revive `D:\prod\simple_scholar` in place, or start a clean `simple_bible`?
**Options:**
1. Revive simple_scholar: keeps working code; but it carries Larry-specific lenses (`SCHOLAR_FRAME_WALTON/RILLERA/DNP/PODCAST/ANCIENT`, `KACC_VALIDATOR`), a February `data/bible.db` fork (161 MB, pre-split, no MACULA, no Westcott-Hort), web-search workers, and six months of dormancy with unverified compilation.
2. Clean simple_bible: a public-facing design from the first line, with simple_scholar's proven parts harvested deliberately.

**Decision:** Option 2. `simple_bible` is a clean new project. `D:\prod\simple_scholar` is retired, and archived only after simple_bible has harvested everything it needs.
**Rationale:** The target user is not Larry; the generic tool should not carry one person's frameworks (design doc §4).
**Implications:** Harvest is tracked item by item in `08-HARVEST-LEDGER.md` (same folder, written by a separate agent). Archive of simple_scholar is gated on that ledger being closed. Candidate harvest items noted in this research: multi-front-end layout (`bible_repl`, `bible_tui`, `bible_htmx`), `RANK_FUSION`, `SCHOLAR_SEARCH`/`SCHOLAR_INDEX`, `SCHOLAR_ONNX_ENGINE`/`SCHOLAR_BERT_EMBEDDER`, `SPARSE_VECTOR`, the `pwa/` and `installer/bible_repl.iss`; the ledger is authoritative.
**Reversible:** NO (by decision), though harvested code can always be consulted until archival.

### D-002: Licensing posture for a free tool (LARRY, DECIDED)
**Question:** What may ship?
**Decision:**
- It is a FREE tool; nothing is sold.
- Attribution for everything, always.
- Non-commercial-licensed texts MAY ship, with attribution, because the tool is free.
- Unknown licenses are RESTRICTED until identified.
- Copyrighted material without a license (`scholars.db`, `transcripts.db`, book texts) stays private.
- Larry's own `rix.db` and framework lenses live in a private plug-in.

**Rationale:** Larry's rule (design doc §7; `_Text Credits` standing restriction). The 2026-09-04 NC gate was about sold books and paid tiers; a free tool is outside it.
**Implications:** The build needs a license gate (FR-004). Share-alike sources (Wycliffe CC BY-SA 4.0; MorphGNT morphology CC BY-SA per its README; UBS resources CC BY-SA 4.0; First1KGreek Swete CC BY-SA 4.0) require that derived tables be offered under the same license; record this in provenance. BHSA (CC BY-NC 4.0) becomes shippable in principle (see D-012). If simple_bible is ever sold or given a paid tier, every NC source must be re-gated.
**Reversible:** YES (Larry's policy), but a change toward commercial use forces a rebuild without NC sources.

### D-003: Target user and hardware (LARRY, DECIDED)
**Decision:** Someone other than Larry; CPU only; 8 to 16 GB RAM; no or weak integrated GPU; Windows; no setup skills.
**Rationale:** Design doc §1 and the measured hardware tiers in §5 (a weak integrated GPU was slower than the CPU on both prompt reading and generation).
**Implications:** No GPU code paths; AI optional; heavy work precomputed (D-004); installer must handle WebView2; memory budget NFR-003/004.
**Reversible:** NO for the public build.

### D-004: Engine owns every fact; AI optional; heavy AI precomputed (LARRY, DECIDED)
**Decision:** The deterministic engine is the only source of numbers, verses and quotations. AI is optional and never a source of facts. Heavy AI work is done at build time on a strong machine and shipped as data.
**Rationale:** The vault's rule "pulled from bible.db, never recalled", turned into architecture (design doc §2).
**Implications:** FR-050 (runs with no AI), FR-053 (AI output post-check), NFR-014 (labeling). Contracts on the AI adapter: its input is an engine result object, not free text.
**Reversible:** NO.

### D-005: Distribution database built fresh from upstream, not copied from the vault
**Question:** Ship a cleaned copy of the vault's `bible.db`, or build anew?
**Options:**
1. Copy and strip the vault DB: fast; but it carries unresolved editions (defect E5: TR, Byz, Peshitta, SP, TgN, TgW unidentified), private-adjacent tables (`ane_glosses` compiled from Walton, Heiser and others), and import history.
2. Reproducible build from pinned upstream sources: slower first time; every row has provenance; credits generate; editions known.

**Decision:** Option 2.
**Rationale:** Provenance and license certainty are product requirements (FR-001 to FR-004), and E5 cannot be fixed by inspection.
**Implications:** Build pipeline is a deliverable. The vault's verified fixes (LXX Jeremiah concordance, quarantine list, Class C restorations) become build rules and regression tests. `ane_glosses` does not ship.
**Reversible:** YES.

### D-006: Front-end stack (LARRY, DECIDED 2026-10-06: native simple_widgets; WebView2 dropped)
**Options:**
1. WebView2 via `simple_browser`, served by `simple_web` on 127.0.0.1 with `simple_htmx`/`simple_alpine` pages: renders Hebrew correctly today.
2. Native `simple_widgets` + `simple_shaping`: native feel; simple_shaping is 0.1.0 pre-release (Phase 4).
3. TUI only: cannot render pointed Hebrew reliably in consoles.

**Decision:** Option 1 primary; CLI/REPL (`simple_cli`, `simple_console`) for power users; native face deferred until simple_shaping is released.
**Rationale:** Only path that renders RTL pointed Hebrew today (design doc §3 L4).
**Implications:** Bundle Hebrew/Greek fonts (e.g., SBL fonts or Noto, licenses to verify in spec) and load them via CSS; local server bound to loopback with a session token (NFR-012). Note the design doc's premise "the shaping library does not exist" is out of date: simple_shaping now exists in pre-release.
**Reversible:** YES (engine is UI-independent, FR-033).
**REOPENED 2026-10-06 (new evidence, PENDING LARRY):** The premise "only WebView2 renders RTL pointed Hebrew today" no longer holds. `simple_widgets` 0.8.1 (last commit 2026-10-06; 114 classes; 327 contract tests) draws SHAPED text through `simple_shaping`: `SW_LABEL` and `SW_TEXT_BOX` render Hebrew right to left, with a bidi caret and cluster hit-testing (0.8.0 / 0.8.1 CHANGELOG). It also ships the controls simple_bible needs: data grid, tree table, paragraph list with highlights (`SW_MARKED_TEXT` spans with reasons), charts, docking, theming with WCAG invariants, and a headless test door. **Recommendation: Option 2 (native simple_widgets) as the primary face**, because it is pure Eiffel end to end (in the spirit of D-020), has no local web server or session-token attack surface (removes NFR-012), and is one toolkit across the fleet. Keep Option 1 (WebView2) as a fallback only if a shaping gap shows up in testing: pointed Hebrew with cantillation, Greek polytonic, or mixed-direction lines. **First spike task:** render Gen 1:1 WLC (pointed, with cantillation), Gen 1:1 LXX and John 1:1 WH in SW_LABEL and SW_TEXT_BOX, offscreen, and compare against a reference rendering. See memory `reference_gui_stack_simple_widgets`.
**DECISION (Larry, 2026-10-06):** "we FILL GAPS, we don't resort to WebView2 because we live in fear of gaps in simple_widgets." **simple_bible's face is native `simple_widgets` (with simple_shaping, simple_cairo and simple_shell). There is NO WebView2 fallback.** Any gap found in testing (cantillation shaping, polytonic Greek, mixed-direction lines, a missing control) is filed and FIXED IN THE OWNING LIBRARY, followed by a downstream-dependents check. The CLI/REPL face stays for power users. The earlier "Option 1 primary" and its NFR-012 local-server requirement are withdrawn. The first spike is unchanged: render Gen 1:1 WLC (pointed, with cantillation), Gen 1:1 LXX (Swete) and John 1:1 WH in SW_LABEL and SW_TEXT_BOX offscreen, and turn every defect into a library fix.

### D-007: Upgrade the SQLite build before relying on newer features
**Question:** `eiffel_sqlite_2025` compiles SQLite **3.31.1** (source id 2020-01-27), although its README says 3.51.1. Upgrade or design around it?
**Options:**
1. Design around 3.31.1: FTS5, JSON1 and RTREE work; no trigram tokenizer (3.34.0), no STRICT tables (3.37.0), no `->>` (3.38.0), no built-in math (3.35.0), no contentless-delete (3.43.0); old bug fixes missing.
2. Replace the amalgamation with the current release (3.53.4, 2026-07-24), rebuild with the same flags, run the whole simple_* fleet's SQL test suites.
3. Fork a simple_bible-only SQLite build: avoids fleet risk but splits the ecosystem.

**Decision:** Option 2, as a separate fleet task before simple_bible's engine phase; simple_bible's spec must not assume features above 3.31.1 until it lands.
**Rationale:** Trigram (substring search in transliterations and English), STRICT tables (data integrity in the distribution DB) and current fixes are worth having; one SQLite for the fleet matches the fleet rules.
**Implications:** Fleet-wide regression run (simple_sql and dependents). README drift in eiffel_sqlite_2025 must be corrected either way.
**Reversible:** YES.

### D-008: Vector search: precomputed neighbors plus brute-force scan; sqlite-vec deferred
**Options:**
1. sqlite-vec compiled into the amalgamation: fast KNN in SQL; pre-v1 ("expect breaking changes"), latest stable v0.1.9 (2026-03-31); our build omits extension loading, so it must be statically compiled.
2. `SIMPLE_SQL_VECTOR_STORE` (simple_sql, brute force in Eiffel) over about 31,000 verse vectors (384 dims, about 47 MB float32) plus precomputed related-passage lists.
3. ONNX-side ANN index: adds a dependency for little gain at this scale.

**Decision:** Option 2 for MVP and Full; revisit Option 1 when sqlite-vec reaches 1.0 or when pericope/notes vectors push the count past about 500,000.
**Rationale:** At this scale a linear scan is well under a second on CPU, and most "related passage" lookups are precomputed (L2).
**Implications:** Store vectors as BLOBs with model id and dimension; consider int8 quantization to cut size by 4x.
**Reversible:** YES.

### D-009: Search normalization: separate normalized columns, not tokenizer tricks alone
**Question:** How do FTS5 and Hebrew/Greek coexist?
**Finding:** unicode61's default categories ("L* N* Co") treat Mn combining marks as separators; `remove_diacritics` acts on Latin script only.
**Decision:** Each text row stores (a) the exact display text and (b) normalized search forms built at build time: Hebrew consonantal with final forms folded and marks removed; Greek NFD, marks removed, lowercased, final sigma folded; English lowercased. FTS5 indexes the normalized columns with unicode61 `remove_diacritics 2`; display never comes from the normalized column.
**Rationale:** Proven in the vault's `bible_search.db` (normalized `plain` column, 250x faster, prefix search working). Protects MapM's deliberate NBSP (FR-008).
**Implications:** Query input goes through the same normalizer (one shared class, contract: `normalize (normalize (s)) = normalize (s)`).
**Reversible:** YES.

### D-010: Versification as data
**Decision:** Build a `versification_map` table from STEPBible TVTMS (CC BY 4.0), cross-checked against the Copenhagen Alliance mappings, plus the vault's verified LXX Jeremiah chapter concordance. Every cross-version pairing goes through it; no pairing code hard-codes offsets.
**Rationale:** Shape.db notes that 19 of 39 shared books differ in verse count between WLC and LXX; any unmapped pairing is silently wrong.
**Implications:** Regression suite of known offsets (FR-022). Pairing results state which mapping rule applied.
**Reversible:** YES.

### D-011: Septuagint text (LARRY, DECIDED 2026-10-06: Option 3)
**Options:**
1. Rahlfs via CCAT/CATSS: the text the vault uses (verified word-for-word at Gen 1:1, Isa 53:5, Ps 22:1). Requires a signed CATSS user declaration before download; the vault records "copyrighted; free non-commercial distribution"; derivatives are CC BY-NC-SA. Redistribution inside an installer may need explicit permission.
2. Swete (1909 to 1930): edition public domain; the First1KGreek/OGL digitization is CC BY-SA 4.0; ~~morphology work exists (eliranwong/LXX-Swete-1930)~~ no openly licensed Swete morphology exists (corrected 2026-10-06; see 12-SEPTUAGINT-SOURCE.md).
3. Both: Swete ships by default; Rahlfs is a separate optional download once CATSS terms are confirmed in writing.

**Recommendation:** Option 3, with Swete as the default in the first public release; ask CATSS for written permission covering a free installer.

**Decision (Larry, 2026-10-06):** "do the recommend." Swete ships by default; a written permission request goes to the Rahlfs digital-text rights holders (CATSS) and, if needed, the print-edition rights holder. Rahlfs stays in the private/vault build and becomes an optional download only after written permission. Acquisition and letter drafts: `12-SEPTUAGINT-SOURCE.md`.
**Rationale:** "Unknown is restricted" (D-002), and the CATSS declaration is more than an NC clause. Swete removes the question for the first release.
**Implications:** The quotation comparer and versification map must be edition-aware (Swete and Rahlfs differ in places, e.g., Rahlfs' double Judges text, defect E11).
**Reversible:** YES.

### D-012: Hebrew syntax and semantic layer (DEFERRED, needs license review)
**Options:** BHSA (CC BY-NC 4.0, shippable in a free tool under D-002); MACULA Hebrew (syntax trees by Clear Bible and the Groves Center; full license to read); UBS SDBH dictionary (CC BY-SA 4.0) for semantic domains; none in MVP.
**Decision:** None in MVP. Evaluate MACULA Hebrew first (already in the vault, keyed like MACULA Greek), then BHSA.
**Rationale:** Addresses shape.db's known weakness ("the OT side is weak") without blocking the core.
**Reversible:** YES.

### D-013: Run-time AI mechanics (model choice PENDING the survey)
**Decision:**
- Query embedding: ONNX Runtime via `simple_onnx` (bundled 1.17.3), with its SentencePiece unigram tokenizer if the chosen model uses one (multilingual-e5-small does, via XLM-R); otherwise llama.cpp embeddings.
- Chat ("explain"): `llama-server.exe` spawned hidden on 127.0.0.1, the `simple_rixqwen` pattern; contexts capped around 1,500 tokens because prompt reading is the slow part on CPU (design doc §5).
- Model slots and selections: from `Rix/Data/_Small Model Survey (2026-10-06).md` (pending; not present when this research ran). Requirements on any selection: redistribution allowed in a free installer; Hebrew and Greek coverage for the embedding model; CPU 4-bit GGUF for chat.

**Implications:** An `AI_ADAPTER` deferred class with contracts that its input is an engine result and its output is labeled; a NULL adapter is the default.
**Reversible:** YES.

### D-014: Private plug-in seam
**Decision:** The public build defines deferred "source" and "lens" interfaces; Larry's private library (separate ECF, separate repo, never in the installer) implements them and ATTACHes `rix.db`, `scholars.db`, `transcripts.db`, `primary_evidence.db` when present. The public executable contains no lens classes.
**Rationale:** D-002; simple_scholar's lenses move here per D-001.
**Implications:** SQLite attach limit is 10 (the vault tested attach #11 failing); the core DB plus user DB plus up to five private DBs fits. Private handling rules (`trusted`, `hold-loosely-datum-only`, `evidence-cite-exactly`) carried as metadata so private results are labeled by voice.
**Reversible:** YES.

### D-015: Three databases at run time: core, AI-data, user
**Decision:** `core.db` (texts, morphology, versification, cross-references, glosses; read-only), `ai_data.db` (vectors and precomputed neighbors; optional; read-only), `user.db` (census definitions, runs, notes, settings; read-write).
**Rationale:** Updates replace read-only files without touching user work; the core edition simply lacks `ai_data.db`.
**Reversible:** YES.

### D-016: First public release is core-only (LARRY, DECIDED 2026-10-06: YES, with AI-made data)
**Decision (recommended):** Release 1 ships L0, L1, the WebView2 face, the CLI and the generated credits. Precomputed related passages (L2, non-AI parts) may ship; embeddings and chat wait for Release 2.
**Rationale:** Smallest download, no model-license questions, proves the engine-owns-facts promise first.
**Reversible:** YES.
**Decision (Larry, 2026-10-06):** "yes, unless you've got something simple we can build out of the box for really useful features." **Refinement adopted:** Release 1 runs no AI on the user's machine, but it MAY ship AI-made DATA computed once at build time: precomputed cross-lingual related passages for every verse (bge-m3 embeddings on Larry's RTX, MIT license), stored as plain rows and shown with a label saying how they were made. No model is downloaded or run by the user. User-typed semantic search (needs run-time query embedding) and the optional chat model move to Release 1.1/2.

### D-017: Precompute on Larry's build machine (RTX), ship as data
**Decision:** Embeddings, neighbors, quotation alignments and gloss/pronunciation tables are computed by build scripts on Larry's machine; outputs carry model id, version and date in provenance.
**Reversible:** YES.

### D-018: Installer
**Decision:** Inno Setup, two editions (core; core + AI). The installer checks the WebView2 `pv` registry value and runs the bundled Evergreen standalone installer (offline-safe) silently if missing. `WebView2Loader.dll` ships with the app. Uninstall leaves `user.db` unless the user opts to remove it.
**Rationale:** Microsoft's distribution guidance; RixQwen and BibleREPL precedent.
**Reversible:** YES.

### D-019: Rix.db in the public build (LARRY, DECIDED 2026-10-06: SHIP ALL, REBUILT TO CURRENT)
**Options:** none of rix.db ships; a curated set of published essays ships as an optional pack; all of it ships.
**Decision (Larry, 2026-10-06):** "rix.db: ship everything and update it to the latest. there is no reason to hold back." All of rix.db ships, rebuilt from the current vault by a reproducible builder (no hand copy).
**Implications:** (1) The build gets a reproducible rix.db builder with the existing schema (docs, verse_refs, docs_fts), run fresh for each release. (2) Status travels with every document (framework / verdict / draft / unmarked / withdrawn / ungated) and the UI shows it, so withdrawn or ungated material is visibly labeled, never presented as authority. (3) rix.db ships as Larry's author library, a separate database beside the core (D-015), with the frameworks included. (4) The private plug-in seam (D-014) narrows to material that is not Larry's own (scholars.db, transcripts.db).
**Reversible:** YES.

### D-020: No Python in the final product (LARRY, DECIDED 2026-10-06)
**Question:** The vault's working tools (rix.db builder, census scripts, shape_db.py, scripture_detect.py, versification fixes) are Python. Does simple_bible depend on them?
**Decision (Larry, 2026-10-06):** "perhaps we can convert the python to Eiffel so we don't need python in the final product." Adopted: simple_bible ships and builds with no Python dependency.
**Method:** Each Python tool is treated as the REFERENCE IMPLEMENTATION (an executable spec). Its Eiffel port must pass a differential test: run both on the same input and compare output row by row (the rix.db validator, `_Tools/validate_rix_db.py`, is the first such harness). The Python retires from the product path only when the Eiffel port matches. Build-time embeddings use simple_onnx (bge-m3 via ONNX) rather than Python.
**Scope:** the shipped app AND the distribution build pipeline. Python may remain in Larry's private research workflow in the vault, but nothing in simple_bible requires it.
**Implications:** Port list (initial): rix.db builder; distribution-DB builder; scripture reference detector; versification map; census engine (pre-registered counts with controls); shape engine (shape_db.py, shapes 1-27); quotation comparer; precompute jobs (embeddings via simple_onnx, related passages). Each gets a differential test in the test suite.
**Reversible:** YES.
