# PARSED REQUIREMENTS: simple_bible

*Pre-phase specification, step R01 (/eiffel.spec), 2026-10-06. Inputs read in full: research 01-07, REFERENCES, 08-HARVEST-LEDGER, 09-FEATURE-PARITY, 10-INNOVATIONS FROM PRACTICE, 11-HISTORY-TIMELINE (+ `11-timeline-pilot.csv`), 12-SEPTUAGINT-SOURCE; gui/00-GUI-SPEC, spec_windows.json, spec_windows_design_notes, spec_windows_state_diagram, gui/README; the design doc `Rix/Upcoming Projects/Bible Study Workbench - Design (2026-10-06).md`; the Python reference tools named by D-020 (`_Tools/build_rix_db.py`, `_Tools/validate_rix_db.py`, `Rix/_Tools/shape_db.py`, `Rix/_Tools/scripture_detect.py`); the fleet-rule memory notes. `research/13-USER-VOICE.md` (294 user items, 96 sources) arrived complete during R03 and was read in full; it is treated as evidence, not as requirements, and its effect is recorded in 03 (A-021 to A-030, spark dispositions) as FR-NEW-012 to FR-NEW-021, traced in 08.*

*Where research documents disagree, the later decision wins. 04-DECISIONS is binding. Three research statements were overtaken on 2026-10-06 and are read in their corrected form here: the WebView2 face (replaced by native simple_widgets, D-006), "morphology work exists for Swete" (it does not, 12-SEPTUAGINT), and "rix.db: none ships" (all of it ships, D-019).*

*Fold note (fold 2026-10-26, debate 01 to 05 and D-021): the five gated verdicts and D-021 are folded in by the plan `00-FOLD-2026-10-26.md`. Each changed or added passage carries its source marker; superseded text is quoted in the Fold log of `00-FOLD-2026-10-26.md`. Release order (fold 2026-10-26, D-021): the personal concordance edition comes before the public Release 1a; the target user of the public release (D-003) is unchanged.*

---

## Problem Summary

An ordinary reader on an ordinary Windows laptop (CPU only, 8-16 GB RAM, no setup skills) has no free tool that lets them **see, count, compare and check** the biblical text in Hebrew, Greek and English with every number computed, every quotation pulled from data, every fact carrying its source and license, and any AI help clearly separated from the facts. Free readers (e-Sword, theWord) do not measure; corpus tools (Text-Fabric, SHEBANQ) are not one-click installs and often carry NC data; Logos puts AI in the answer path. A full research cycle (CL 58) showed that more than half of study work is mechanical and can be done by deterministic code over SQLite.

simple_bible answers this with a deterministic Eiffel engine over a freshly built, fully provenanced SQLite distribution database; a native simple_widgets face plus a CLI/REPL; AI only as build-time data (Release 1) or as optional, labeled phrasing (later); and a private plug-in seam for Larry's own research material.

## Scope

### In Scope (Release 1, "core only", D-016)
- **L0 data (fold 2026-10-26, debate 01):** reproducible distribution build from pinned upstream open sources (D-005) in separate **build stages**: the core stage (texts, morphology, versification map, cross-references, glosses, provenance, quarantine, caveats, a stored folded search column with an external-content FTS5 index), the AI-data stage (precomputed related passages made at build time, labeled AI-made) and the rix stage (Larry's author library, rebuilt fresh, every status labeled, D-019). One assembly step writes the shipped read-only `content.db` (core, AI-made related passages, author library, folded indexes; optional public content as empty tables). `user.db` (the reader's own data) stays separate; packs attach read-only (debate 03, debate 05). License gate; generated credits.
- **L1 engine:** reference parser; versification map applied before any pairing; verse hub; concordance (lemma, Strong's incl. split senses, morphology, surface); search (words, phrases, Boolean, regex, lemma/Strong's/morph); census engine (pre-registered, frequency-matched controls, FITS/PARTIAL/FAILS/NO_DATA together, method stored); shape engine (named T1/T2 shapes, near-misses, T3 never evidence); range before ruling (renderings); word's journey; divine-name marking; quotation comparer ("They Chose") over the seeded quotation index; guide assembly from engine results; related passages with reasons; library resources (public-domain commentaries, lexicons, dictionaries, devotionals) with provenance; writing checks; personal tools (notes, highlights, bookmarks, tags, history, prayer list, memory cards, reading plans, collections) keyed to canonical verse ids; export/copy with attribution and share-alike notices.
- **L2 precompute (build machine):** related passages (cross-reference votes, shared rare lemmas, embedding neighbors), quotation alignments, gloss and pronunciation tables with coverage report, lemma frequency tables for controls, shape instances.
- **L4 faces:** native `simple_widgets` GUI (Simple and Study layouts, panels P01-P11, dialogs D01-D03 and D05-D10) and a CLI/REPL (`bible.exe`) with a closed, read-only one-shot command set.
- **Private data packs (fold 2026-10-26, debate 03):** private material reaches the public program only as versioned data packs read by a generic public pack reader; the lens logic runs once, at export, on Larry's machine; the public build contains no plug-in code, no lens class and no rule interpreter.
- **Ports of the vault's Python tools to Eiffel** (D-020), each with a differential test.
- **Concordance, personal edition first (fold 2026-10-26, D-021):** three lookups over conc.db, a read-only pack attached to the public engine: by Hebrew/Aramaic/Greek word, by English word, and by verse reference (FR-150 to FR-152). The personal edition reads conc.db as is and is marked "PERSONAL EDITION - not for distribution"; the distribution edition (conc_dist.db only) comes later (FR-157, FR-163). It comes before the public Release 1a.
- Windows installer (Inno Setup), core edition.

### Out of Scope
- Judgment-grade local AI (debate, adjudication) on 8-16 GB CPU machines (design doc §5).
- Any run-time AI in Release 1 (D-016): no model downloaded or run on the user's machine.
- Selling, paid tiers, accounts, telemetry (D-002, FR-064).
- Shipping copyrighted material without a license: `scholars.db`, `transcripts.db`, book texts, NBP corpus, DDD (D-002; ledger §4).
- WebView2 in any role (D-006 as decided: no fallback; NFR-012 withdrawn).
- Editing primary texts at run time; corrections go into the build with a recorded reason.
- Rahlfs (CCAT) in the public build until written permission (D-011). (fold 2026-10-26, D-021: the personal edition's private concordance pack carries the CATSS Rahlfs LXX as a research-only layer; it is never published.)
- macOS/Linux native builds.

### Deferred (designed for, not built in Release 1)
- v1.5: Claim Check (I-P01), Study Ledger (I-P12), share-safe export flags (I-P05), pre-registered questions for any search (I-P13), "My ruling" (I-P16), accessibility bridge (GW-14).
- v2: World timeline over `history.db` (11-HISTORY-TIMELINE), atlas, meaning search (run-time query embedding), Exegetical Guide, senses (UBS SDBH/SDGNT; public release only, the personal edition already shows the SDBH/SDGNT meanings conc.db holds, fold 2026-10-26, D-021, conflict 2), reverse interlinear, variants, clause views, full NT-Use-of-OT browser, user-made shapes (I-P14), Hebrew syntax layer (D-012).
- v3: optional local chat model behind a labeled "explain" button (FR-052/053), syntax search, sermon tools.
- The zero-install PWA (ledger L-2; 213 MB private-content DB must leave any served folder first).

## Functional Requirements

Requirement IDs FR-001 to FR-065 are carried from `research/03-REQUIREMENTS.md`. IDs FR-100 and up are derived here from the supplementary research (08-12), the GUI spec and the decisions; their source is named. Priority follows research; "R" = release.

### L0: Data and distribution build

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-001 | Reproducible build assembles `core.db` from pinned upstream sources, never by copying the vault's `bible.db` | MUST | research/03, D-005 | Two builds from the same manifest yield identical per-table checksums |
| FR-002 | Every shipped row carries a provenance key to a `source_provenance` row | MUST | research/03 | Rows without provenance = 0 |
| FR-003 | Credits file and About page generated, never hand-edited: the engine's sources from `source_provenance`, and each attached pack's own `notice` table (About lists both; fold 2026-10-26, settlement S4) | MUST | research/03; research/14 §1; D-021 | Shipped credits byte-equal to regenerated credits; each pack's listed notices equal its `notice` table |
| FR-004 | License gate: build fails on a shipped source with license UNKNOWN; NC and SA clauses recorded | MUST | research/03, D-002 | Named build error for `UNKNOWN` + `ship = true` |
| FR-005 | Each version carries a caveat shown wherever it is displayed | MUST | research/03 | Caveat present in verse hub and census reports |
| FR-006 | Proven-wrong rows go to quarantine with reason and date; nothing deleted; quarantined refs answer NO_DATA | MUST | research/03 | Defect A1 (LXX Jer tails) reproduces as quarantined |
| FR-007 | Every defect-register class carried: A fixed, B documented, C flagged as import gaps, D protected, E caveated | MUST | research/03 | One test per register item |
| FR-008 | Display text keeps exact Unicode (MapM NBSP before paseq); search uses a folded index built from one Eiffel normalizer, display text is never read from the index (fold 2026-10-26, debate 01; supersedes "a separate normalized column"; see FR-133) | MUST | research/03, D-009, debate 01 | Byte-equality test; NBSP phrase found through the folded index (fold 2026-10-26, debate 01) |
| FR-009 | Edition-omitted verses stored as explicit omission markers | SHOULD | research/03 | Matt 17:21 in WH reads "omitted in this edition" |
| FR-010 | Pinned-source manifest (URL, commit/release, SHA-256, license text hash) verified before import | MUST | research/03, 12 | Build refuses a hash mismatch |
| FR-100 | Swete LXX imported from First1KGreek TEI pinned at `eb81494`, `grc1`/`grc2` selection rules, apparatus and margins dropped, repairs logged in `source_repairs`, numbering-gap report classified, Gen-3 Kgdms collated against Sollupulo | MUST | 12 (D-011) | 12's build checklist passes; build fails if any verse begins with a Roman numeral without a repair row |
| FR-101 | Lettered verses, verse 0 titles, prologues and Odes `iva`/`ivb` representable (`verse_suffix`) | MUST | 12 §A7 | 3 Kgdms 2:35a and Esther prologue round-trip |
| FR-102 | Share-alike tables (Swete, MorphGNT, UBS, Wycliffe) kept in their own tables with `share_alike = true`; no extra terms | MUST | 12 §A5, D-002 | Provenance query lists every SA table |
| FR-103 | `rix.db` rebuilt from the current vault by an Eiffel port of `build_rix_db.py` rules v2.1 (R1-R15) | MUST | D-019, D-020 | Differential compare against the Python reference output = 100% (validator port); the comparator's object is the rix stage file, not the assembled `content.db` (fold 2026-10-26, debate 01) |
| FR-104 | Every Python reference tool in the product path has an Eiffel port that passes a row-by-row differential test; the test suite itself needs no Python (golden outputs) | MUST | D-020 | One differential test per port: rix.db builder, distribution builder steps, reference detector, versification map, census, shapes, quotation comparer, precompute jobs |
| FR-105 | Canonical book ids are stable and equal to the vault's `bible_books.id` (rix.db `verse_refs.book_id` contract, R12) | MUST | build_rix_db.py R12 | rix.db built against core.db's catalog equals the Python reference |
| FR-106 | Build-time precompute (related passages, alignments, gloss/pronunciation tables, lemma frequencies, shape instances) carries model id, version and date in provenance; AI-made rows flagged | SHOULD | D-016, D-017, FR-040/041 | Every AI-made row (the AI-data stage, shipped in `content.db`) has `is_ai_made` and a method label (fold 2026-10-26, debate 01; was "Every `ai_data.db` row") |
| FR-107 | TIPNR prose descriptions (written by Claude 3) are labeled AI text or omitted; Strong's 1980 Moody material stripped | MUST | 09 §10 | No unlabeled TIPNR description ships |

### L1: Deterministic engine

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-020 | Reference parser: names, abbreviations, ranges, lists; names the versification system assumed; ambiguous input returns a choice, never a guess | MUST | research/03 | 300+ case suite; "Ju 1" and "Ph 1" return candidates |
| FR-021 | Verse hub: every shipped version, words with lemma, Strong's, morphology expanded to English, gloss, pronunciation, cross-references | MUST | research/03 | Gen 1:1; Ps 23:1 (LXX 22:1); Mal 4:1 (Heb 3:19; Swete leg Mal 4:1 = Rahlfs 3:19); Jer 31:31 (LXX 38:31); Heb 8:8 |
| FR-022 | Versification map (TVTMS + vault LXX Jeremiah concordance + Swete entries) applied before any pairing | MUST | research/03, D-010, 12 §A7 | Malachi, Psalms (9/10, 118/119, titles), Jeremiah, Lev 5/6, Deut 23, Num 16/17 (Swete), Joel 2-4 |
| FR-023 | Concordance by lemma, Strong's (split senses 6743/6743a), morphology, surface; Hebrew final-form-safe; Greek diacritic-safe. (fold 2026-10-26, D-021, conflict 1: this row stays as is for Release 1a; the headword rule, keys are `lemma_id` and never Strong's, governs only the concordance pack's lookups, FR-153; rekeying this row is overturn trigger 3 of debate 05 and needs a new debate) | MUST | research/03 | Strong's count = lemma count for unsplit lemmas |
| FR-024 | Joins by keys only, never by display strings (defect E8) | MUST | research/03 | Static check over engine SQL |
| FR-025 | Census definition stored before the run; immutable after a run; edits create a new version | MUST | research/03 | Editing a run definition is a contract violation |
| FR-026 | Census and shape results always carry FITS, PARTIAL, FAILS and NO_DATA together, with near-misses; no "fits only" API | MUST | research/03 | No public feature returns a single bucket alone |
| FR-027 | NO_DATA kept distinct from FAILS | MUST | research/03 | Heb 11:3 / Eph 4:12 regression |
| FR-028 | Shape engine: named shapes, tiers T1/T2/T3; T3 never returned as evidence | MUST | research/03 | Eiffel shapes equal the Python reference run on the same core.db (modified in R03) |
| FR-029 | Range viewer: every attested rendering/gloss with supporting verses before any ruling | SHOULD (v1 per GUI) | research/03, I-P09 | 50-lemma sample: every distinct gloss shown |
| FR-030 | Quotation comparer: NT, LXX, MT side by side with computed agreement class | SHOULD (v1 seeded index) | research/03, I-P06 | Heb 8:8-12 vs LXX Jer 38:31-34 vs MT Jer 31:31-34 |
| FR-031 | Checks: gloss + pronunciation on first use; no bare script; capital after a colon; citation complete; provenance tag | SHOULD | research/03 | Positive and negative fixture per check |
| FR-032 | Every number has a method record that re-runs to the same number | MUST | research/03 | Show-method re-run equality test |
| FR-033 | Engine usable without any UI | MUST | research/03 | All engine tests run headless with no window |
| FR-108 | Word's Journey: one lemma through witnesses in time order (MT, LXX, NT, Vulgate, Wycliffe, Tyndale, KJV, BSB) with method per row (tagged, verse co-occurrence, NO_DATA) | SHOULD (v1) | I-P07, GUI §5.8 | ekklesia: Tyndale "congregation", KJV "church" |
| FR-109 | Divine-name marking by lemma/Strong's keys; Swete side by normalized surface form, labeled "surface-form match" | SHOULD (v1) | I-P08, GUI §5.1 | Gen 7:16 marks Elohim and YHWH |
| FR-110 | Guides (Passage Guide, Word Study, They Chose, Word's Journey) assembled only from engine results; a section with no data is not listed | SHOULD (v1 frames) | GUI §5.8 | No guide section lacks provenance |
| FR-111 | Related passages per verse with the reason for each (cross-reference with votes, shared rare word, AI-made meaning neighbor) | SHOULD (v1) | FR-041, D-016 | Every AI-made row carries the AI-made label and method |
| FR-112 | Frequency-matched control words selected deterministically (seed stored in the definition) and compared with the target | MUST (v1) | I-P02 | Re-run selects identical controls |
| FR-113 | Hebrew pointing reduction (full / vowels / consonants) supplied by the engine; stored text never edited | SHOULD | GUI §5.1, FR-008 | Reduced forms derived, display row unchanged |
| FR-114 | Word diff between versions (LCS over normalized tokens) | SHOULD | A04 | Differing tokens reported as spans |
| FR-115 | Hits per book normalized per 1,000 words (graph data) computed by the engine | SHOULD | B10 | GUI renders numbers it received |
| FR-116 | Library resources (public-domain commentaries, lexicons, dictionaries, devotionals) queried by verse, lemma, topic or date, each entry with provenance | SHOULD (v1 per GUI) | 09 §9, GUI P04/P05 | Entry without provenance cannot be built |
| FR-117 | Personal data (notes, highlights, bookmarks, tags, history, prayer, memory cards, plan progress, collections, layout snapshots, settings) stored in `user.db` keyed to canonical verse ids | MUST (v1) | GUI §8, D-015 | A highlight shows in every version of the verse |
| FR-118 | Spaced-repetition scheduling for memory cards and reading-plan generation are engine features | SHOULD | E07, E08 | Deterministic schedule given dates |
| FR-119 | Export/copy with automatic attribution; share-alike notice when SA text (Swete) is included | MUST (v1) | GUI D06, 12 §A5 | Export of a Swete verse carries the notice |
| FR-120 | Author library: search `docs_fts`, documents citing a passage via `verse_refs`, status always attached; withdrawn excluded unless asked, always labeled | MUST (v1) | D-019, GUI P10 | No author document reaches a face without its status |
| FR-121 | CLI one-shot mode with a closed, specified, read-only command set covering at least the ledger R-5 core subset (verse refs, define, search, compare, etymology, xref, people, list, versions) | MUST | 08 R-5/R-6 | simple_chat's tool participant retargets and passes |
| FR-122 | Never a bare "LXX": every Septuagint label carries its edition; two-text books labeled by text | MUST | 12 checklist | Label invariant on version info |
| FR-123 | Long work (search, census, guides, precompute) cancellable; partial results discarded, never shown as findings | MUST | GUI ER-10 | Cancelled job yields no result object |
| FR-124 | The GUI depends on engine abstractions only: no SQL, no number formatting it did not receive, no guide assembly | MUST | GUI design notes §1, D-004 | No GUI class depends on simple_sql |
| FR-125 | Private packs with a `NOT NULL` voice column, read by the public generic pack reader; private results labeled by voice (trusted / hold-loosely / cite-exactly) (fold 2026-10-26, debate 03; supersedes "Private plug-in seam: deferred source and lens interfaces") | SHOULD | D-014, I-008, debate 03 | Public build contains no lens class and no private strings (see FR-146) |
| FR-126 | Claim Check (v1.5): extract references, word/number/quotation claims deterministically; engine checks; SUPPORTED / CONTRADICTED / PARTLY / CAN'T BE CHECKED | COULD (v1.5) | I-P01 | AI never judges |
| FR-127 | Study Ledger (v1.5): every query, count and finding logged; replay; re-run on current data; user ruling | COULD (v1.5) | I-P12, I-P16 | Replay reproduces |
| FR-128 | Timeline (v2) over `history.db`: events with original date expressions, certainty classes A-G, disputes as all positions, P4-only events never ship, synchronism slices, narrated vs composition time | COULD (v2) | 11 | Ship gates 1-6 enforced by the builder |

### L2: Precomputed intelligence

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-040 | Verse/pericope vectors computed on the build machine, stored in SQLite with model id and prefix convention | SHOULD (data in R1; run-time use v2) | research/03 | Vector table with provenance |
| FR-041 | Related-passage lists per verse with the signal that produced each | SHOULD | research/03 | Reason present per item |
| FR-042 | Quotation alignment tables computed once | SHOULD | research/03 | Covers every seeded quotation |
| FR-043 | Gloss and pronunciation tables for every lemma; coverage report lists gaps | MUST | research/03 | Lemmas with no gloss listed, not hidden |
| FR-044 | Model-written text reviewed by a person and labeled | COULD | research/03 | Unreviewed rows never ship |

### L3: Optional run-time AI (not in Release 1)

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-050 | Application runs with every AI component absent | MUST | research/03, debate 01 | Full suite passes with no model files; with optional public content empty, the author library shows its absent state, not an error (fold 2026-10-26, debate 01, K9-A) |
| FR-051 | CPU query embedding for semantic search | SHOULD (v2) | research/03 | Under 1 s on 4-core DDR4 |
| FR-052 | "Explain" rewrites an engine result only | COULD (v3) | research/03 | Prompt = engine output + fixed instruction |
| FR-053 | AI output never introduces a number, reference or Hebrew/Greek string absent from the engine result | MUST when FR-052 exists | research/03 | Post-check withholds or marks |
| FR-054 | Bring-your-own-key, off by default, via simple_winhttp | COULD (v3) | research/03 | Disabled without a key |

### L4: Faces and packaging

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-060 | Face renders pointed Hebrew (RTL, niqqud, cantillation) and polytonic Greek with bundled fonts | MUST | research/03 as modified by D-006 | D-006 spike offscreen in SW_LABEL / SW_TEXT_BOX; defects fixed in simple_shaping (GW-01..03) |
| FR-061 | CLI/REPL `bible.exe` exposes verse, concordance and census commands; in the personal edition also the word-view, English and verse-word commands, through the facade names `conc_pack`, `word_lookup`, `english_index` and `verse_word_lookup` (fold 2026-10-26, debate 05) | MUST | research/03, debate 05 | CLI tests |
| FR-062 | Inno Setup installer, core edition (AI edition later); bundles fonts; no WebView2 detection | MUST (core) | research/03 as modified by D-006 | Silent install/uninstall on a non-live identity; `user.db` kept on uninstall |
| FR-063 | Private packs (scholars, transcripts and primary_evidence material, lens annotations, `machine_generated.db`, the concordance pack) attach only when present, as versioned packs through the generic public pack reader; there is no plug-in (rix.db ships, D-019) (fold 2026-10-26, debate 03; supersedes "Private plug-in attaches scholars/transcripts/primary_evidence only when present") | SHOULD | research/03, D-019, debate 03 | Public build has no private data |
| FR-064 | No telemetry, no account, no network unless the user turns on BYOK or an update check | MUST | research/03 | Zero outbound connections by default |
| FR-065 | Never opens console windows or extra visible windows when spawning helpers | MUST | research/03 | Hidden spawns only |

### Fold additions: requirements the five verdicts and D-021 call for (fold 2026-10-26)

*Every row is a locked input copied from a gated verdict (its section 8, with its section 5 and the gate in section 10) or from D-021; none reopens a decision. The full path and status word of each verdict are in "Decisions Already Made". Priority follows the verdict. IDs FR-130 and up are new.*

#### Data layout and search (debate 01)

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-130 | One assembly step writes the shipped read-only `content.db` from the separate build stages (core, AI data, rix): DDL copied verbatim, rows copied, per-table identity with each stage checked (`EXCEPT` in both directions, FTS5 shadow tables included) (fold 2026-10-26, debate 01) | MUST | debate 01 §5.1, §8 (new AC) | The assembled `content.db` equals each stage per table, shadow tables included; two builds from one manifest are byte-identical |
| FR-131 | Optional public content ships as empty tables, never as missing files; presence is a count or a manifest flag (`has_ai_data` becomes a presence count); `user.db` stays separate on the user-store processor only (fold 2026-10-26, debate 01) | MUST | debate 01 §5.1 items 3-4, §8 | With optional public content empty, the full suite passes with no model files and the author library shows its absent state (K9-A); no guard path for a missing file exists |
| FR-132 | Provenance measure K7-A: every content table the build defines in a shipped file (FTS5 shadow tables excepted) declares `provenance_key ... NOT NULL REFERENCES source_provenance`, with `source_provenance` in the same file; every provenance check names its schema (fold 2026-10-26, debate 01) | MUST | debate 01 §1.3, §8 (restates AC-1a-04) | `PRAGMA <schema>.foreign_key_check`, named per schema, returns no rows for every shipped file and every pack; how the R15 tables are covered is UNTESTED (queue item 10) |
| FR-133 | Search normalization TN-R: one Eiffel normalizer folds every searchable text the build produces (remove general categories M\* and Cf, map Hebrew finals and Greek final sigma, case-fold); FTS5 indexes the folded text with `unicode61 remove_diacritics 2`; the user's query passes through the same normalizer (fold 2026-10-26, debate 01; supersedes "separate normalized columns" of D-009) | MUST | debate 01 §5.2, §8 | AC-1a-20 is found through the folded index; AC-1a-23 adds "no format character (Cf)" (K3-A); the same pattern builds the author library's folded index beside the untouched R15 tables |
| FR-134 | Storage form R-N4v: the stage keeps a stored folded column and an external-content FTS5 index over it, `integrity-check` run and required to pass, residue census over the column; the shipped file carries the same index declared `content=''` with shadow rows copied from the verified stage; no stored folded column ships unless overturn trigger OT-N1 fires (fold 2026-10-26, debate 01) | MUST | debate 01 §5.2 items 3-4 | The stage index passes `integrity-check`; the shipped index's four shadow tables equal it (`EXCEPT` both directions, 0 rows) |
| FR-135 | Pack fold rule: the pack format declares its fold-rule version; a pack's folded index is built by the published Eiffel pack builder or passes the published fold-parity fixture; a pack that fails the fixture is attached and labeled "not diacritic-safe", not refused (Larry's gate, item 4) (fold 2026-10-26, debate 01) | MUST | debate 01 §5.2 item 6, §8, §10 | Parity fixture mismatches = 0 for a pack not built by the Eiffel pack builder, or the pack carries the label |
| FR-136 | Search path contract SB-1: `verse_id` contiguous per version; a version-range table; every search and display-fetch path filters by FTS rowid range, never by a join on `verse.version_id`; `hub_id` is never the FTS rowid (fold 2026-10-26, debate 01) | MUST | debate 01 §8 (carried from the seats) | One-version search with a rowid range runs about 1 ms p95, warm, on the development machine (deploy only that statement) |
| FR-137 | Cross-version, book-subset and prefix search shapes are in the Release 1a suite as reported numbers, not gated targets (Larry's gate, item 5) (fold 2026-10-26, debate 01) | SHOULD | debate 01 §9 item 5, §10 | Suite reports the three shapes; no gate on them |
| FR-138 | Packs attach read-only; `BIB_SOURCE_SET` has one main (`content.db`) and `Max_attached` counts pack slots only; an attach policy for an open pack count is specified; attach #11 reports SQLite's own message, not "Unknown error"; the `file:...?mode=ro` form of the skeleton is dropped; the attach goes through `SIMPLE_SQL_DATABASE.attach_read_only` (simple_sql 5a17f97, 2026-10-08), which debates 01 and 03 could not use on SQLite 3.31.1 (URI filenames off) and debate 05a executed on 3.53.4 (write refused) (fold 2026-10-26, debate 01, debate 03; settlement S1) | MUST | debate 01 §8, debate 03 §8, debate 05a fork 1 | A write into an attached pack is refused; attach policy under SCOOP specified (queue item 4) |

#### Notes store (debate 02)

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-139 | `user.db` is the system of record for notes, written only by the user-store processor through `BIB_DB_NOTE_STORE` behind `BIB_NOTE_STORE`: append-only versions, soft delete, restore; all note writes go through the one processor that owns the store's state (fold 2026-10-26, debate 02) | MUST (1a) | debate 02 §5 item 1, §8 | `BIB_DB_NOTE_STORE` is the 1a default (no "conditional on the RQ-06 gate") |
| FR-140 | Export on demand writes one Markdown file per live note with `id` and `hub_id` front matter, under an id-based or sanitized file name (never a raw title), through an atomic write, into a folder the exporter creates, and reports every failure; import reads a folder back as new notes or new versions, never overwriting a row; export needs simple_yaml in 1a (fold 2026-10-26, debate 02) | MUST (1a) | debate 02 §5 item 2, §8 | `files_written + failures = live notes`; titles with `: ? / \ * " < > \|`, trailing dots and reserved names: 10,000 of 10,000 listed as `.md`, 0 in alternate streams (DS-EXP) |
| FR-141 | At each clean exit, write the notes changed in that session as Markdown files the program never reads back (B′); default folder outside the reader's notes vault, labeled as a read-only copy, the user may point it into the vault (Larry's gate, items 2-3) (fold 2026-10-26, debate 02) | SHOULD, only if DS-B′ passes | debate 02 §9 items 2-3, §10 | 0 bytes lost in the snapshot folder under kill and outside edit (DS-B′); a start-time backup after an unclean exit is recommended for test (DS-B-S8), not adopted untested |
| FR-142 | simple_sql error integrity (F-9) is a prerequisite of the user store: `atomic` and the migration runner roll back and report on any failed statement; P-ATOMIC passes on the fixed library before any user-store contract test counts (fold 2026-10-26, debate 02) | MUST | debate 02 §5 item 3, §8.1 (new 1a AC), OT-1 | `spikes/ADJ-p-atomic` re-run unchanged: 0 partial commits, every failure reported, M1 returns False with the SQLite message kept (landed in simple_sql `5a17f97` and eiffel_sqlite_2025 `23db5d0`, gate 2026-10-22) |
| FR-143 | File-authoritative note store `BIB_MARKDOWN_NOTE_STORE` (A″) is a Release 1b candidate, UNTESTED, gated by DS-3c first (one GUI test on a scratch vault, at a time Larry chooses), then DS-10, DS-2″, DS-1/DS-8, DS-R1, DS-R2 and the A″-only library fixes; AC-1a-43 moves to 1b (fold 2026-10-26, debate 02) | COULD (1b, gated) | debate 02 §5 item 5, §8.1 | OT-3 of debate 02: every gate passes by the end of P2 |

#### Private packs (debate 03)

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-144 | The public engine runs no private code and no rule interpreter: it finds generic private packs by folder (conc.db by `conc_path`, FR-166), attaches each read-only, and builds voiced results through the public `make_success`; a pack carries rows with a `NOT NULL` voice column and `provenance_key`, keyed to passages through reference rows (versification declared), in the published schema with `user_version` checked at open; the pack format is public and documented, third parties may build packs; the plug-in facade features are removed before release (fold 2026-10-26, debate 03) | SHOULD | debate 03 §5, §8, §10 items 2 and 5 | Every generic private data pack opens only at the expected `user_version`; a pack with a `NULL` voice is refused at attach (conc.db is checked by `BIB_CONC_PACK`'s own check, FR-164: fold 2026-10-26, settlement S6) |
| FR-145 | User queries over private corpora run through generic public features: by-verse range overlap, Boolean key search, edit-distance fuzzy match, multi-source FTS with source labels; the library queries (FR-116) and search (B01-B05) state that they cover attached packs; cross-chapter reference ranges are handled in the rewrite of the harvested S-10 queries (fold 2026-10-26, debate 03) | SHOULD (1b for the library queries) | debate 03 §5 item 4, §8, §3.2 ADJ-2 | Eiffel re-run on SQLite 3.31.1 of the facet, by-reference and fuzzy tests: mismatches = 0 (OT-7) |
| FR-146 | Public-build purity (K2′, restates AC-1a-57): the finalized public executable contains no string from the R-2 list in ASCII, UTF-16LE or UTF-32LE; the positive control includes a `{STRING_32}` private string; the clause "no effective `BIB_LENS` descendant" is dropped (fold 2026-10-26, debate 03) | MUST | debate 03 §1.6, §8 | `test_plugin_purity` re-specified to K2′ passes |
| FR-147 | An unlabeled private result in a fixture run = 0, with the pack voice column checked at attach (K4); lens annotations over Larry's public notes and `machine_generated.db` are private packs (Larry's gate, items 3-4) (fold 2026-10-26, debate 03) | MUST | debate 03 §8, §10 | Fixture run shows 0 unlabeled private results |

#### SQLite binding (debate 04)

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-148 | The binding is `eiffel_sqlite_2025` on SQLite 3.53.4 with unchanged compile flags and `blocking` on six externals (`step`, `prepare_v2`, `open_v2`, `close`, `close_v2`, `backup_step`); every dependent is rebuilt with `-clean` and its generated C is checked for `EIF_ENTER_C` around the library's `sqlite3_step`; `sqlite_version` is recorded per method (fold 2026-10-26, debate 04) | MUST | debate 04 §5.2, §5.4, §8, §10 | Verified 2026-10-22: simple_bible clean build against eiffel_sqlite_2025 1.1.0: 69 passed, 47 skipped (skeletal), 0 failed |

#### Concordance, personal edition (D-021, debate 05, research/14)

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-150 | Word lookup by Hebrew, Aramaic or Greek word shows a word view in this order: heading (transliteration, then Hebrew or Greek, then pronunciation); how often, in plain words; English at a glance (BSB, KJV and STEP renderings with counts); what the dictionaries say, each source in its own words side by side as candidates; through the centuries; one short callout at most; EVERY PLACE (reference, whole word with transliteration, meaning or stem, BSB in context, KJV, STEP); the Greek Old Testament; going further; notes. Phrase entries are included (fold 2026-10-26, D-021) | MUST (personal edition) | D-021, research/14 §3, debate 05b §5 (`BIB_WORD_LOOKUP`, `BIB_WORD_VIEW`) | Word view for the pilot's 15 words and one phrase matches the order above; every query is at most 125 ms lean, attached (debate 05b F5-C4a) |
| FR-151 | English lookup: an English word leads to the Hebrew and Greek words behind it, Bible by Bible, with counts (the pilot's English index) (fold 2026-10-26, D-021) | MUST (personal edition) | D-021, research/14 §3, debate 05b §5 (`BIB_ENGLISH_INDEX`) | English lookup of 'lord' about 90 ms lean, attached (debate 05a) |
| FR-152 | Verse-reference lookup: the words of a verse in every corpus the pack holds (fold 2026-10-26, D-021) | MUST (personal edition) | D-021, debate 05b §5 (`BIB_VERSE_WORDS`) | Verse in every corpus 0.1 ms lean, attached (debate 05a) |
| FR-153 | Headword rule: the concordance pack's lookups key on the conc.db `lemma_id` (an `INTEGER_64`), never on Strong's; Strong's lives only in `lemma_xref`; core's FR-023 stays as it is for Release 1a (fold 2026-10-26, D-021, conflict 1) | MUST (personal edition) | D-021 (research/14 §1), debate 05b §5 | Static check: no Strong's number in a `BIB_CONC_PACK` signature or key |
| FR-154 | Meanings and renderings are shown as "candidates", never "best"; the personal edition shows the SDBH and SDGNT meanings conc.db holds, a meaning for every place, resolved to the token (fold 2026-10-26, D-021, conflict 2) | MUST (personal edition) | D-021 (research/14 §1, §2), conflict 2 | No label "best" in any shipped string of the word view |
| FR-155 | Every original-language word shows a transliteration (SBL style); dictionary forms also show a pronunciation (capitals mark stress, for example KHEH-sed; YHWH is YAH-weh); each place's whole-word transliteration is read from a precomputed `token.translit` column (fold 2026-10-26, D-021, debate 05a fork 4) | MUST (personal edition) | D-021 (research/14 §1), debate 05a fork 4 | No Hebrew or Greek word in the word view lacks a transliteration |
| FR-156 | Layout and helps rules: Hebrew lines up left in tables (a left-to-right mark before Hebrew cells) and headings start with the transliteration; at most one callout per entry, asides go in numbered notes; readers never see corpus codes and "linked" counts appear only when something is missing; first opening is "painfully obvious" (usefulness model: Strong's Concordance), finer uses taught in the help; American English throughout; Larry's name is never printed; his framework ideas appear only in an unnamed "Going further" section with no trademark names (fold 2026-10-26, D-021) | MUST (personal edition) | D-021 (research/14 §1) | Review of the pilot layout against each rule |
| FR-157 | Edition marking: the personal edition is marked "PERSONAL EDITION - not for distribution" in the title bar and the About window, and is never published (fold 2026-10-26, D-021) | MUST | D-021 | Title bar and About window carry the exact marking in the personal edition |
| FR-158 | Edition swap: the personal edition reads conc.db and the distribution edition reads conc_dist.db only; the two differ by which pack is attached, and no edition test appears in engine code (fold 2026-10-26, D-021, debate 05b trigger 4) | MUST | D-021, debate 05b §5 (trigger 4, K3) | Edition-swap check: the same engine build opens either pack; Phase 4 grep for edition literals finds none |
| FR-159 | Every-place lists are paged (page of at most 200 rows, `Max_page_size = 200`) and shown in a virtual grid; a list is never loaded whole for any word; a cursor left early is closed (fold 2026-10-26, debate 05) | MUST (personal edition) | debate 05a ("Do not assume" 1, 4; "For the spec fold"), research/14 §2 | First page of 200 places in 25-28 ms lean; the largest list (the Greek article in the LXX, 88,444 rows) is paged, whole list up to 0.9 s lean |
| FR-160 | conc.db stays its own file and attaches read-only as a pack (`BIB_SOURCE_SET.attach` through `SIMPLE_SQL_DATABASE.attach_read_only`); a write into the pack is refused; the shipped build is lean (timing trumps contracts), tests that time reads use `without_contracts` (fold 2026-10-26, debate 05a fork 1) | MUST (personal edition) | debate 05a fork 1 | Attached queries are not more than 20% slower than direct on a future SQLite (overturn trigger) |
| FR-161 | Two counters, each stating its key kind and scope: `BIB_CONCORDANCE` counts core keys, `BIB_CONC_PACK.place_total` counts `lemma_id` (fold 2026-10-26, debate 05b) | MUST | debate 05b §8 | Each counter's contract names its key kind and scope |
| FR-162 | conc.db builder items: a `token.translit` column (precomputed transliteration, 158,342 distinct written forms in 1.2 s, 7.6 MB); per-corpus counts and the English-at-a-glance summary per headword (a few tens of thousands of rows); the builder may stay Python while it builds only the private pack (fold 2026-10-26, debate 05a fork 4, debate 05b addendum, D-021) | MUST (personal edition) | debate 05a fork 4, debate 05b addendum, D-021 | Differential test for conc_dist.db's Eiffel builder against conc_translit.py, form by form, over the 158,342 forms |
| FR-163 | Distribution edition (later): reads conc_dist.db only; credits generated from the pack's own `notice` table and listed in Help, About beside the engine's `source_provenance` credits (FR-003; fold 2026-10-26, settlement S4); the distribution data is CC BY-SA 4.0 as a whole; blockers (Swete lemmas, Berean's confirmation of the BSB per-word tables, permission letters) are Larry's (fold 2026-10-26, D-021) | SHOULD (later) | D-021, research/14 §1, §6 | Credits byte-equal to regenerated credits from the `notice` table |
| FR-164 | Two pack kinds, two checks: conc.db is a concordance pack, opened by `BIB_CONC_PACK` through its own check (the expected `user_version` plus the required tables), with provenance per corpus (`corpus.license`, `ship_class`) and per meaning (`meaning_source`); the pack-schema check of FR-144 (`user_version`, a `NOT NULL` voice column, `provenance_key`) governs generic private data packs (`BIB_PRIVATE_SOURCE`) only (fold 2026-10-26, settlement S6) | MUST (personal edition) | debate 05b §5 (K6); debate 03 §5; D-021 | A conc.db with the expected `user_version` and the required tables opens without a voice or `provenance_key` column; a generic private pack without them is refused |
| FR-165 | The conc.db builder sets `PRAGMA user_version` (conc.db has 0 today) (fold 2026-10-26, settlement S6) | MUST (personal edition) | settlement S6; research/14 §2 | A rebuilt conc.db reports the expected `user_version`; `BIB_CONC_PACK` refuses a pack that reports another |
| FR-166 | Two routes to a pack: conc.db is found by `BIB_CONFIG.conc_path`; generic private packs are found by the pack-folder scan. `BIB_CONC_PACK` has no inheritance relation to `BIB_PRIVATE_SOURCE` now (no deferred seam until a real second implementor; Larry, 2026-10-26). Which class holds export, import and the generic pack features is a Phase 4 design item, not a decision (fold 2026-10-26, settlements G1, G2, G3) | MUST (personal edition) | debate 05b §5; debate 03 §8; settlements G1-G3 | The pack-folder scan does not attach conc.db; `conc_path` does |

## Non-Functional Requirements

| ID | Requirement | Category | Measure | Target |
|----|-------------|----------|---------|--------|
| NFR-001 | Verse hub latency | PERFORMANCE | reference to rendered active pane | < 200 ms on 4-core / 8 GB / SSD |
| NFR-002 | Whole-canon concordance / census with controls | PERFORMANCE | wall time | < 2 s typical; < 10 s census with controls |
| NFR-003 | Memory, core edition | RESOURCE | working set | < 1 GB |
| NFR-004 | Memory, AI edition | RESOURCE | working set | < 4 GB with a 1-4B Q4 model (later releases) |
| NFR-005 | Disk | RESOURCE | installed size | core 2-4 GB |
| NFR-006 | Determinism | CORRECTNESS | same query, same DB | identical output |
| NFR-007 | Provenance completeness | CORRECTNESS | rows without provenance | 0 |
| NFR-008 | License compliance | LEGAL | shipped UNKNOWN licenses | 0 |
| NFR-009 | No GPU | PORTABILITY | GPU required at any tier | none |
| NFR-010 | Windows support | PORTABILITY | OS | Windows 10 22H2, Windows 11, x64 |
| NFR-011 | Privacy | SECURITY | outbound connections by default | 0 |
| NFR-012 | ~~Local server binding~~ | — | — | **Withdrawn by D-006** (no local web server) |
| NFR-013 | Accessibility | USABILITY | font scaling, keyboard, dark mode | large-print friendly; full keyboard use; screen reader in v1.5 (GW-14) |
| NFR-014 | AI labeling | TRUST | unlabeled AI-produced text | 0 |
| NFR-015 | Contract coverage | QUALITY | engine public features with require/ensure | 100% |
| NFR-016 | GUI responsiveness | PERFORMANCE | longest GUI-processor stall | no stall beyond one frame from engine work, including garbage-collection waits on C externals (fleet GC law) |
| NFR-017 | Cold start | PERFORMANCE | launch to first verse | 3 s or less (warm 1.5 s) (GUI §14, proposed); store start-up work (reconcile, first-build indexing) counts inside the 3 s, the stricter reading that debate 02 scored (section 1.3); the note store's share measured 38-43 ms at 100,000 notes on the development machine (fold 2026-10-26, debate 02) |
| NFR-018 | Build reproducibility | CORRECTNESS | per-table checksums across two builds | identical; no wall-clock values in rows (build date passed in) |
| NFR-019 | Word view first screen (personal edition): heading, how often, English at a glance, first page of 200 places, back to back | PERFORMANCE | lean F_code, conc.db attached read-only | 200 ms (the register's K5 target) warm; measured Greek article 205 / 398 / 197 ms over three rounds, Hebrew "and" (lemma 8, 50,272 places) 2,773 ms cold then 277 and 140 ms; the cold first read of a very common word may reach 2.8 s against NFR-002's 2 s typical, so the builder precomputes per-corpus counts and the English-at-a-glance summary per headword (FR-162); overturn of that item: a measured first screen under 200 ms cold for lemma 8 without it (fold 2026-10-26, debate 05, orchestrator addendum) |

## Constraints (simple_* First)

| ID | Constraint | Type |
|----|------------|------|
| C-001 | SCOOP-compatible | TECHNICAL |
| C-002 | Prefer simple_* over ISE/Gobo; ISE base/time and Gobo only through simple_* wrappers | ECOSYSTEM |
| C-003 | Void-safe ("all") | TECHNICAL |
| C-004 | Engine owns every fact; AI never a source of facts (D-004) | ARCHITECTURE |
| C-005 | Free tool; nothing sold (D-002) | LICENSING |
| C-006 | Unknown license = restricted; copyrighted without license stays private (D-002) | LICENSING |
| C-007 | CPU only, 8-16 GB, Windows (D-003) | HARDWARE |
| C-008 | Clean project; simple_scholar retired only after the harvest ledger closes (D-001) | PROCESS |
| C-009 | Shipped network code uses simple_winhttp, never libcurl-based simple_http | ECOSYSTEM |
| C-010 | Release 1 DDL uses SQLite 3.31.1 features only (RQ-03 option 2); the binding is SQLite 3.53.4 with `blocking` externals (eiffel_sqlite_2025 1.1.0, landed and verified 2026-10-22); FT-02 alone on 3.31.1 was the contingency (fold 2026-10-26, debate 04; supersedes "SQLite feature ceiling is 3.31.1 until the D-007 fleet upgrade lands (header still reads 3.31.1 on 2026-10-06)") | TECHNICAL |
| C-011 | Eiffel Spec Kit for every build phase | PROCESS |
| C-012 | American English in UI and documentation; CRLF in the repo | STYLE |
| C-013 | Fill gaps in the owning simple_* library; never plan a fallback to outside technology (D-006, standing rule) | ECOSYSTEM |
| C-014 | No Python in the shipped app or the distribution build (D-020); the scope is the shipped product only: Larry's private export tool and the conc.db builder (while it builds only the private pack) may stay Python (fold 2026-10-26, debate 03 gate item 6, D-021) | PROCESS |
| C-015 | Class prefix unique in the fleet (chosen in R04: `BIB_`); any inline C helper prefix unique in the fleet (`sbib_`); zero C preferred | ECOSYSTEM (fleet law) |
| C-016 | Any C external that can wait must be `external "C blocking ..."` (fleet GC law) | TECHNICAL (fleet law) |
| C-017 | No visible windows in tests or builds; GUI tests run offscreen | PROCESS |
| C-018 | Pushing a changed library requires README + `/docs` + CHANGELOG updates and a downstream-dependents sweep | PROCESS |
| C-019 | Class invariants O(1); MML model clauses live in postconditions (fleet convention, commits of 2026-09-11 in simple_scholar and simple_shaping) | TECHNICAL |
| C-020 | After a change to `eiffel_sqlite_2025`, every dependent is rebuilt with `-clean` and its generated C is checked for `EIF_ENTER_C` around `sqlite3_step`; an incremental rebuild keeps unmarked externals with exit 0 (fold 2026-10-26, debate 04) | TECHNICAL (fleet rule) |
| C-021 | Every `PRAGMA foreign_key_check` names its schema, packs included; a bare check passes a cross-file reference on 3.31.1 (fold 2026-10-26, debate 01) | TECHNICAL |
| C-022 | A deferred class waits for a real second implementor: no deferred seam until overturn trigger 1 or 2 of debate 05b fires ("push abstractions up" reads as triggered by real duplication, Larry's gate 2026-10-26) (fold 2026-10-26, debate 05) | DESIGN |

## Decisions Already Made

| ID | Decision | Rationale | From |
|----|----------|-----------|------|
| D-001 | Clean `simple_bible`; simple_scholar retired after harvest | Public-facing design; no one person's frameworks | research/04 (Larry) |
| D-002 | Free tool; attribution always; NC may ship; unknown = restricted; copyrighted-without-license private | Larry's rule | research/04 (Larry) |
| D-003 | Target user: not Larry; CPU only; 8-16 GB; Windows; no setup skills | Design doc §1, §5 | research/04 (Larry) |
| D-004 | Engine owns every fact; AI optional; heavy AI precomputed | "Pulled from bible.db, never recalled" as architecture | research/04 (Larry) |
| D-005 | Distribution DB built fresh from upstream with provenance | Provenance and license certainty | research/04 |
| D-006 | Native simple_widgets face (with simple_shaping, simple_cairo, simple_shell); NO WebView2; gaps fixed in the owning libraries; every GW gap is done (Phase 4 complete 2026-10-26, `gui/02-GAP-PROGRAM.md`) (fold 2026-10-26, D-006) | "We FILL GAPS" | research/04 (Larry); gui/00-GUI-SPEC.md, gui/02-GAP-PROGRAM.md |
| D-007 | Upgrade the fleet SQLite: landed as 3.53.4 with six `blocking` externals (see DB-04); the Release 1 DDL ceiling stays 3.31.1 features (fold 2026-10-26, debate 04; supersedes "design to 3.31.1 until it lands") | Fleet consistency | research/04; debate 04 verdict |
| D-008 | Vectors: precomputed neighbors + brute-force scan (SIMPLE_SQL_VECTOR_STORE); sqlite-vec deferred | Scale is small | research/04 |
| D-009 | Build-time folding by one shared idempotent Eiffel normalizer, indexed with FTS5 `unicode61 remove_diacritics 2`; the stage keeps the stored folded column, the shipped file carries the verified index under `content=''`; the `bible_search.db` "proven" citation is retired (fold 2026-10-26, debate 01; supersedes "Separate normalized search columns") | Unicode61 limits | research/04; debate 01 verdict (see DB-01N) |
| D-010 | Versification as data; every pairing goes through the map; results name the rule | Silent mispairing in half the books | research/04 |
| D-011 | Swete ships by default; Rahlfs private until written permission | Unknown is restricted | research/04 (Larry) |
| D-012 | No Hebrew syntax layer in MVP; public Release 1a keeps this as decided, the personal edition shows the SDBH/SDGNT meanings conc.db holds, and the distribution edition may carry them (CC BY-SA, research/14 §6) once conc_dist.db exists (fold 2026-10-26, D-021, conflict 2) | License review pending | research/04 |
| D-013 | Run-time AI mechanics (ONNX query embedding; llama-server spawned hidden); NULL AI adapter default | Model survey | research/04 |
| D-014 | Private material arrives only as versioned data packs; the lens logic runs at export; no plug-in seam in Release 1 (fold 2026-10-26, debate 03; supersedes "Private plug-in seam: deferred source and lens interfaces; private repo implements") | D-002 | research/04; debate 03 verdict (see DB-03) |
| D-015 | Run-time: one read-only `content.db` assembled from the build stages core, AI data and rix (optional public content as empty tables), `user.db` (RW), and packs attached read-only; `history.db` (v2) is folded in or separate, decided when v2 is specced; D-014's attach count is superseded by the slot table in debate 01 §3.1 (fold 2026-10-26, debate 01; supersedes "core (RO), ai_data (RO, optional), user (RW); plus rix.db (RO, D-019) and history.db (RO, v2)") | Updates never touch user work | research/04, 11; debate 01 verdict (see DB-01L) |
| D-016 | Release 1 core-only: no run-time AI, but AI-made build-time data (related passages) ships labeled | Smallest, proves the promise | research/04 (Larry) |
| D-017 | Precompute on the build machine; outputs carry model id, version and date | Weak user hardware | research/04 |
| D-018 | Inno Setup, two editions; `user.db` kept on uninstall (WebView2 detection removed by D-006) | Precedent | research/04 |
| D-019 | All of rix.db ships, rebuilt to current by a reproducible builder; status travels with every document; the author library ships inside the content file, built by its own stage (fold 2026-10-26, debate 01 gate item 3; replaces "a separate database beside the core") | "No reason to hold back" | research/04 (Larry) |
| D-020 | No Python in the product; Python tools are reference implementations; Eiffel ports pass differential tests; the scope is the shipped product only, so the private export tool and the conc.db builder (private pack only) may stay Python, while conc_dist.db needs an Eiffel builder with a differential test (fold 2026-10-26, debate 03 gate item 6, D-021) | Pure Eiffel product | research/04 (Larry) |
| D-021 | The concordance comes into simple_bible (conc.db accessed through simple_bible, not a separate simple_conc); three lookups (by Hebrew/Aramaic/Greek word, by English word, by verse reference); PERSONAL edition first (reads conc.db as is, marked "PERSONAL EDITION - not for distribution", never published); DISTRIBUTION edition later (conc_dist.db only, credits from its own `notice` table, listed beside the `source_provenance` credits: fold 2026-10-26, settlement S4); Larry's concordance rules (headword `lemma_id` never Strong's, "candidates" never "best", a transliteration for every original-language word, Hebrew lines up left, at most one callout, never print Larry's name) (fold 2026-10-26, D-021) | Larry, 2026-10-22: "we were going to put this in simple_bible"; "take the recommends; personal edition first". Fits D-014 (conc.db is a private DATA pack, no private code), D-020 (builder may stay Python for the private pack) and D-011 (Rahlfs only in the personal edition) | `research/04-DECISIONS.md` D-021 (LARRY, DECIDED 2026-10-22); `research/14-CONCORDANCE (conc.db) - HANDOFF (2026-10-22).md` §1, §3, §6. Status: DECIDED, reversible |
| DB-01L | Runtime database layout, pathway B-S: build stages stay separate (core, AI data, rix); one assembly step writes the shipped `content.db` (per-table identity with each stage, two builds byte-identical); optional public content ships as empty tables; `user.db` separate; packs attach read-only (fold 2026-10-26, debate 01) | The split bought nothing a requirement measures; absent-as-empty removes guard paths; 2-3 more pack slots under an open pack count. Gate 2026-10-22 ("take the recommends; personal edition first"): adopted with OT-L1 to OT-L6; D-019 wording changed (item 3) | `debate/01 - Runtime database layout and search normalization (D-015 + D-009)/04 - VERDICT.md` §5.1, §10. **PREFERRED**, confidence 0.65, rootedness 0.80 (not ESTABLISHED) |
| DB-01N | Search normalization, pathway TN-R with storage form R-N4v: one Eiffel normalizer folds at build time; FTS5 `unicode61 remove_diacritics 2`; the query is folded by the same normalizer; stage keeps stored column plus external-content index (integrity-checked), the shipped file carries the index under `content=''` bridged by table identity (fold 2026-10-26, debate 01) | Built-in tokenizers fail K4 on 3.31.1; query-only folding collapses recall; a custom tokenizer fails K11; the contentless index gives identical hits, is 34% smaller, and is verifiable through the stage. Gate items 4-5: a pack that fails the parity fixture is attached and labeled, cross-version and prefix shapes are reported not gated | same path, `04 - VERDICT.md` §5.2, §10. **PREFERRED**, TN-R 0.75 / 0.85, R-N4v 0.70 / 0.85 (not ESTABLISHED) |
| DB-02 | Notes store, pathway B for Release 1a: `user.db` is the authoritative note store behind `BIB_NOTE_STORE` (`BIB_DB_NOTE_STORE`); Markdown export and import on demand; B′ plain-text copy at clean exit if DS-B′ passes; A″ file-authoritative store is the gated Release 1b candidate (fold 2026-10-26, debate 02) | Q-11's own fallback ("Otherwise user.db first") applies; every file-authoritative design lost content in an executed test that B passed (0 lost of 33,552 verified entries in 600 kills). Gate 2026-10-22: adopted; F-9 landed | `debate/02 - Notes store (RQ-06)/04 - VERDICT.md` §5, §10. **PREFERRED**, confidence 0.70, rootedness 0.80 (not ESTABLISHED) |
| DB-03 | Private plug-in seam, pathway B′: private material reaches the public program only as versioned data packs; the lens logic runs once, at export, on Larry's machine; the public engine runs no private code and no rule interpreter; plug-in facade features removed before release (reverses RQ-11's "keep the seam in 1a"); lens annotations and `machine_generated.db` are private packs; the pack format is public and documented; the private export tool may stay Python (fold 2026-10-26, debate 03) | Option A needs a clean private rebuild per public release (691 s today) and composes to a silently dark plug-in; every private item checked either computes once from the export or is a generic query. Gate 2026-10-06 ("take the recommends"): adopted | `debate/03 - Private plug-in seam (D-014)/04 - VERDICT.md` §5, §10. **PREFERRED**, confidence 0.75, rootedness 0.80 (not ESTABLISHED) |
| DB-04 | SQLite library, pathway A″ as adjudicated: patch `eiffel_sqlite_2025` in place: SQLite 3.53.4 with unchanged compile flags, `blocking` on six externals, no hook guard (the hooks were made safe under `blocking` and the guard lifted, e80c57c, 2026-10-08; debate 04 section 10 wins over its sections 5 and 8), truthful docs in both libraries, every dependent rebuilt `-clean`; Release 1 DDL stays at the 3.31.1 ceiling (fold 2026-10-26, debate 04; settlement S3; was "a guard on the five Eiffel-callback setters") | One door (`simple_sql.ecf`); proven on copies first; the hook hazard closed by construction. Gate 2026-10-22: adopted; landed (eiffel_sqlite_2025 `11f69b9`, `23db5d0`, `e80c57c`; simple_sql `a26b79a`, `5a17f97`); verified 2026-10-22 | `debate/04 - SQLite library - patch in place or fork (Q-02)/04 - VERDICT.md` §5, §10. **PREFERRED**, confidence 0.82, rootedness 0.88 (not ESTABLISHED) |
| DB-05a-1 | conc.db stays its own file and attaches read-only as a pack (`BIB_SOURCE_SET.attach` to `SIMPLE_SQL_DATABASE.attach_read_only`), not folded into content.db and not a build stage (fold 2026-10-26, debate 05) | Attaching costs nothing measurable (write refused; attached versus direct within noise); folding 1.23 GB of research-only layers into shipped content.db would break D-021 and debate 03's B′. Gate 2026-10-26 ("1 and your recommends") | `debate/05 - Concordance placement and lookups (D-021)/04a - SETTLED BY SPIKE - pack and transliteration.md` fork 1, §10. **ESTABLISHED**, confidence 0.90, rootedness 0.90 |
| DB-05a-4 | Transliteration is precomputed in the conc.db builder as a `token.translit` column, not a form table and not ported into the engine (fold 2026-10-26, debate 05) | 158,342 distinct written forms transliterate in 1.2 s with 0 failures; the column is 7.6 MB (0.6% of conc.db). Overturn: a view that transliterates text not in conc.db. Gate 2026-10-26 | same file, fork 4, §10. **PREFERRED**, confidence 0.80, rootedness 0.85 |
| DB-05b | Engine classes for the concordance, pathway B as skeletoned and compiled: a new `src/concordance/` cluster (`BIB_CONC_PACK`, `BIB_WORD_LOOKUP`, `BIB_ENGLISH_INDEX`, `BIB_VERSE_WORDS`, and the value classes `BIB_WORD_ENTRY`, `BIB_PLACE_ROW`, `BIB_ENGLISH_ROW`, `BIB_VERSE_WORD`, `BIB_WORD_VIEW`) beside an untouched `BIB_CONCORDANCE`; the facade gains `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup`; `BIB_CONFIG` gains `conc_path`; no deferred seam now (fold 2026-10-26, debate 05) | Best on K10 (one existing file touched); all pack SQL in one class; no seam without a second implementor. Gate 2026-10-26 ("1 and your recommends"): abstractions wait for a real second implementor | `debate/05 - Concordance placement and lookups (D-021)/04b - VERDICT.md` §5, §10 and the orchestrator addendum. **PREFERRED**, confidence 0.70, rootedness 0.80 (A not shown to fail) |
| CF-1 | Conflict 1: core's FR-023 (counts by lemma, Strong's, morphology, surface in core.db; AC-1a-22) stays as is for Release 1a; Larry's headword rule (keys are conc.db `lemma_id`, never Strong's; Strong's only through `lemma_xref`) governs the concordance pack's lookups (`src/concordance/`) only (fold 2026-10-26, D-021) | Rekeying FR-023 is overturn trigger 3 of debate 05b and needs a new debate | `00-FOLD-2026-10-26.md` conflict 1; `debate/05 - .../04b - VERDICT.md` §5 trigger 3, §8. Status: settled by the fold plan |
| CF-2 | Conflict 2: D-012 (no Hebrew semantic layer in MVP) holds for the public Release 1a; the personal edition shows the SDBH/SDGNT meanings that conc.db holds (D-021 is later than D-012); the distribution edition may carry them (CC BY-SA, research/14 §6) once conc_dist.db exists (fold 2026-10-26, D-021) | D-021 is later than D-012 | `00-FOLD-2026-10-26.md` conflict 2; `research/14-CONCORDANCE (conc.db) - HANDOFF (2026-10-22).md` §2, §6. Status: settled by the fold plan |
| CF-3 | Conflict 3: release order (D-021): the personal concordance edition comes before the public Release 1a; the target user of the public release (D-003) is unchanged (fold 2026-10-26, D-021) | Larry's "personal edition first" | `00-FOLD-2026-10-26.md` conflict 3; `research/04-DECISIONS.md` D-021. Status: settled by the fold plan |

## Innovations to Implement

| ID | Innovation | Design Impact |
|----|------------|---------------|
| I-001 | Engine owns every fact (AI as phrasing only) | `BIB_AI_TEXT` creatable only by the post-checker from an engine result; `BIB_AI_ADAPTER.explain` takes `BIB_ENGINE_RESULT`, never a string |
| I-002 | Pre-registered census, four buckets | `BIB_CENSUS_DEFINITION` frozen on first run; `BIB_BUCKETED_RESULT` cannot exist without all four buckets |
| I-003 | Versification-safe pairing as a precondition | `BIB_MAPPED_REF` creatable only by `BIB_VERSIFICATION_MAP`; pairing features take `BIB_MAPPED_REF` |
| I-004 | Provenance per row, generated credits, license gate | `BIB_FACT [G]` requires a provenance; builder postconditions `all_rows_have_provenance`, `no_unknown_license_shipped` |
| I-005 | Defects as data | Quarantine, caveat, omission and import-gap kinds are types (`BIB_OMISSION`), never empty strings |
| I-006 | Do the AI at build time | Separate build target; the AI-data stage is optional (its tables ship empty when absent, fold 2026-10-26, debate 01; was "`ai_data.db` optional"); AI-made rows carry a label invariant |
| I-007 | Quotation comparer with computed agreement class | `BIB_QUOTATION_COMPARER` computes from precomputed alignment rows; NO_DATA where alignment is absent |
| I-008 | Public core, private packs | No plug-in classes: `BIB_PRIVATE_SOURCE` becomes an effective, generic pack source; `NOT NULL` voice column on every private hit; `BIB_LENS_RESULT` keeps its voice (fold 2026-10-26, debate 03; supersedes "Public core, private plug-in ... Deferred `BIB_PLUGIN`, `BIB_PRIVATE_SOURCE`, `BIB_LENS`") |
| I-P02 | Frequency-matched controls by default | `BIB_CONTROL_SET` with stored seed |
| I-P03 | FAILS always shown | Same as I-002 |
| I-P06/07/08/09 | They Chose; Word's Journey; Divine-name view; Range before ruling | Study cluster engines, each returning provenance-bearing results |
| I-P01/05/12/13/16 | Claim Check; share-safe export; ledger; pre-registration; human ruling (v1.5) | Interfaces designed now, built in v1.5 |

## Risks to Address in Design

| ID | Risk | Mitigation Strategy |
|----|------|---------------------|
| RISK-001 | The binding is now SQLite 3.53.4 (landed); Release 1 DDL stays at the 3.31.1 ceiling (fold 2026-10-26, debate 04; was "Compiled SQLite 3.31.1") | Design to the 3.31.1 ceiling (CHECK not STRICT; folded index not trigram; no `->>`; math in Eiffel); FT-02 alone on 3.31.1 was the contingency |
| RISK-002 | FTS5 mishandles Hebrew marks and Greek accents | `BIB_NORMALIZER` family, idempotence postcondition, folded index (stage stored column plus verified index, FR-133, FR-134; fold 2026-10-26, debate 01; was "normalized columns"), trap corpus tests |
| RISK-003 | A shipped source not redistributable | `BIB_LICENSE_GATE`; Swete default; per-row provenance |
| RISK-004 | Plausible wrong pairings | `BIB_MAPPED_REF` precondition; regression suite incl. Swete legs |
| RISK-005 | Upstream contamination reappears | Content-anchor checks per import; quarantine rules as build steps |
| RISK-006 | Small models invent facts | No run-time AI in R1; `BIB_AI_POST_CHECK` for later |
| RISK-007 | Weak Hebrew/Greek embeddings | Related passages also from cross-references and rare lemmas; reasons shown |
| RISK-008 | Harvested code no longer compiles | Harvest is copy-and-adapt; ledger rows tracked |
| RISK-009 | ~~WebView2 missing~~ | Withdrawn by D-006; replaced by: fonts missing on target machine (GW-01, bundled fonts) |
| RISK-010 | 8 GB laptops thrash with AI | No run-time AI in R1; `BIB_CAPABILITY_PROBE` later |
| RISK-011 | Scope creep from Larry's research | Plug-in seam; public requirement list as gate |
| RISK-013 | Share-alike obligations missed | SA flag per table; export notice |
| RISK-014 | Single maintainer | Spec Kit artifacts; reproducible builds; README/docs rule |
| RISK-016 | Omitted verses read as errors | `BIB_OMISSION` kinds |
| RISK-017 | Gloss treated as meaning | Glosses labeled orientation; census/concordance never key on gloss |
| RISK-018 (new) | 15 v1 GUI gap items in other libraries (GW-01..13, 24, 26) gate the GUI | Engine and CLI phases independent of the GUI; panel order by gap dependency (R03). Every GW gap is done (Phase 4 complete 2026-10-26, `gui/02-GAP-PROGRAM.md`): the gating risk is closed (fold 2026-10-26, D-006) |
| RISK-019 (new) | GC stall: `eiffel_sqlite_2025` `c_sqlite3_step` not marked `blocking` (fleet audit) | Adopted and landed (fold 2026-10-26, debate 04; was "HELD for Larry's gate"): six externals marked `blocking`, every dependent rebuilt `-clean`; engine still chunks long queries so no single step is long (R03) |
| RISK-020 (new) | Swete is uncorrected OCR (74 errors in 56 Genesis verses) | Repair log; OCR caveat on every Swete display and on quotation verdicts (R03) |
| RISK-021 (new, 13) | Lost or scrambled user notes destroy trust faster than any bug (13 T10, gotcha 3) | Append-only user data with history, soft delete, rotating backup, hub-id keys (R03 A-022) |
| RISK-022 (new, 13) | Trust betrayals (settings reset, forced redesign, silent text change) | Migration preserves settings; per-text seal and changelog; trust rules ratified at intent (R03 A-023, A-025, A-029) |
| RISK-023 (fold, debate 01) | An open pack count overflows the attach limit (10) in any layout; attach #11 fails | Attach policy under SCOOP (attach on demand or a slot cap per engine connection), queue item 4; debate 03 OT-6 |
| RISK-024 (fold, debate 01) | Pack folds made outside the Eiffel normalizer drift from it | Published fold-parity fixture; failing packs are attached and labeled "not diacritic-safe" (FR-135) |
| RISK-025 (fold, debate 01) | Full-corpus assembly cost and the stage-to-ship identity are unmeasured | Queue item 2; overturn triggers OT-L1 and OT-N2 |
| RISK-026 (fold, debate 01) | Every timing comes from the development machine; the 8 GB reference machine is unmeasured | Queue item 1; OT-L2 |
| RISK-027 (fold, debate 02) | The user's notes are lost to any silent partial commit until simple_sql error integrity (F-9) lands | F-9 landed (simple_sql `5a17f97`, eiffel_sqlite_2025 `23db5d0`); P-ATOMIC re-run before user-store tests (FR-142) |
| RISK-028 (fold, debate 02) | During 1a, outside edits to an export are never read back unless imported (stranded edits) | Default export folder outside the reader's notes vault, labeled a read-only copy (FR-141) |
| RISK-029 (fold, debate 02) | A″'s refused-save behavior in real editors is unknown (DS-3c) | A″ stays a gated 1b candidate (FR-143) |
| RISK-030 (fold, debate 02) | Seats and tools that inherit the session's current folder write into the vault root | A rename-by-handle primitive takes a full path and rejects a bare name (F-1″) |
| RISK-031 (fold, debate 03) | Private corpus queries depend on 1b features (FR-116 library queries, search) covering packs | FR-145 states the coverage; schedule item |
| RISK-032 (fold, debate 03) | Pack-schema churn: the pack `user_version` bumps in more than 2 of the first 4 public releases | OT-4 of debate 03 reopens K9 |
| RISK-033 (fold, debate 03) | Export cost of the verbatim graph analytics on the real exported graph is unmeasured | OT-5 of debate 03 (more than 30 minutes per export reopens S-02's placement) |
| RISK-034 (fold, debate 04) | A dependent rebuilt incrementally after the patch silently keeps unmarked externals | C-020: `-clean` rebuild plus generated-C check |
| RISK-035 (fold, debate 04) | A future client needs an Eiffel hook before the gap item lands | Overtaken: the hooks were made safe under `blocking` and the guard lifted (eiffel_sqlite_2025 `e80c57c`, gate 2026-10-22) |
| RISK-036 (fold, debate 04) | FT-01 fails the dependents campaign and only FT-02 ships | Closed: the combined patch landed and was verified 2026-10-22 |
| RISK-037 (fold, debate 04) | Multi-processor connection churn stalls the GUI beyond 16 ms under every pathway | simple_bible keeps long-lived connections; AC-1a-48 at P5 |
| RISK-038 (fold, debate 05) | Frequent words miss the 200 ms first-screen budget of the word view (about 260 ms of measured queries in sequence for the Greek article; cold first read up to 2.8 s) | Precompute per-corpus counts and the English-at-a-glance summary per headword in the conc builder (FR-162), or fill sections asynchronously; NFR-019 |

## Use Cases

### UC-001: Read one verse in every version
**Actor:** Reader (Simple layout) or CLI user
**Precondition:** `core.db` present and schema-valid
**Main Flow:**
1. User types "jn 3 16" in the reference box.
2. Engine parses to exactly one reference (or returns candidates; the user picks one).
3. Engine maps it to the canonical hub id and pairs it into each shipped version through the versification map.
4. Engine returns every version's text (or an omission marker), caveats, edition labels, words with lemma/Strong's/morphology/gloss/pronunciation, cross-references, each with provenance.
5. Face lays out the result; every pairing that used a rule names it.
**Postcondition:** Active reference of link set A = parsed hub id; history extended by one.

### UC-002: Word to lexicon, range before ruling
**Actor:** Reader
**Precondition:** A verse with tagged words is displayed
**Main Flow:**
1. User clicks a Hebrew or Greek word (the face sends the word id, never the display string).
2. Engine returns the word header (script, transliteration, pronunciation, gloss), then the range of renderings with counts and example verses, then lexicon entries, each with provenance.
**Postcondition:** Word token set in the link set; panels following the word refresh.

### UC-003: Concordance by key
**Actor:** Student
**Main Flow:**
1. User asks `strongs:H6743` or clicks "Search this word".
2. Engine resolves the key (split senses 6743/6743a reported separately), counts hits per book with corpus sizes, and pages hits.
**Postcondition:** Result carries a method record; re-running returns identical counts.

### UC-004: Pre-registered census with controls
**Actor:** Careful researcher
**Main Flow:**
1. User writes question, corpus, criteria, holds-if and fails-if; the engine proposes frequency-matched controls (deterministic seed); user saves.
2. Definition is stored; on Run it freezes.
3. A census job runs off the GUI processor in chunks, reporting progress; cancel discards partial results.
4. Result: FITS, PARTIAL, FAILS, NO_DATA together, near-misses, target vs controls verdict, method.
**Postcondition:** Definition frozen; further edits create version n+1.

### UC-005: Shape evidence
**Actor:** Researcher
**Main Flow:** User opens a named T1/T2 shape; engine returns its four buckets with grounds and evidence; a T3 shape is refused as evidence.

### UC-006: They Chose (quotation comparer)
**Actor:** Reader
**Main Flow:**
1. User opens a verse that is an indexed NT quotation (Heb 8:8).
2. Engine pairs NT, LXX (Swete) and MT through the map, reads the precomputed alignment, and computes the agreement class.
3. Result shows columns, token marks, the verdict, and an edition/OCR note.
**Postcondition:** Verdict reproducible; NO_DATA where the alignment is absent.

### UC-007: Build the distribution database
**Actor:** Larry (build machine)
**Main Flow:**
1. `bible_build core --manifest M --date D` verifies every pinned source hash and license.
2. License gate refuses UNKNOWN shipped sources.
3. Importers, repairs, defect rules, normalization, versification, FTS and checksums run as steps in separate stages; the assembly step then writes `content.db` and checks it against each stage (FR-130) (fold 2026-10-26, debate 01).
4. Credits generated from provenance.
**Postcondition:** Every row has provenance; checksums recorded; a second build is identical.

### UC-008: Rebuild rix.db and prove the port
**Actor:** Larry
**Main Flow:** `bible_build rix --vault V --previous OLD --out NEW`; the Eiffel comparator compares NEW with the Python reference output row by row.
**Postcondition:** 100% match or a named list of mismatches.

### UC-009: Author library beside the text
**Actor:** Reader
**Main Flow:** With John 3:16 active, the Author Library lists documents citing it, each with its status chip; withdrawn documents only when asked, always labeled.

### UC-010: CLI one-shot for another tool
**Actor:** simple_chat's tool participant
**Main Flow:** `bible.exe /verse John 3:16` (closed command set) prints the result with provenance and exits; an unknown command is refused.

### UC-011: Export with attribution
**Actor:** Reader
**Main Flow:** User copies Swete Ps 22:1 with format; the export carries the attribution and the CC BY-SA notice.

### UC-012: Larry runs the public executable with private packs present (fold 2026-10-26, debate 03; was "Private build lights up Larry's plug-in")
**Actor:** Larry
**Main Flow:** Larry runs the public executable; it finds his private packs in the pack folder and attaches each read-only when present; lens annotations computed at his export arrive labeled by voice.
**Postcondition:** The public executable contains no plug-in, lens or private-name string, and no private code runs in it.

### UC-013 (v1.5): Claim Check
**Actor:** Reader
**Main Flow:** User pastes text; engine extracts references and claims deterministically; each is checked against the engine and marked SUPPORTED / CONTRADICTED / PARTLY / CAN'T BE CHECKED with evidence.

### UC-014 (v2): Synchronism slice
**Actor:** Reader
**Main Flow:** From Luke 3:1 the user asks for narrated time; the engine returns every visible lane's items at that range, each with certainty class and sources; disputes show all positions.

### UC-015: Concordance lookups, personal edition (fold 2026-10-26, D-021)
**Actor:** Larry (personal edition); later any reader of the distribution edition
**Precondition:** conc.db (personal) or conc_dist.db (distribution) is attached read-only as a pack; the title bar carries "PERSONAL EDITION - not for distribution" in the personal edition
**Main Flow:**
1. By word: the user enters or clicks a Hebrew, Aramaic or Greek word; the engine resolves its headword (`lemma_id`) and returns the word view in the order of FR-150; the every-place list opens at its first page of 200 and pages on demand.
2. By English word: the user enters an English word; the engine lists the original-language words behind it, Bible by Bible, with counts; choosing one opens its word view.
3. By verse reference: the user enters a reference; the engine lists the words of that verse in every corpus the pack holds; choosing a word opens its word view.
**Postcondition:** Every original-language word shown carries its transliteration; meanings appear as candidates; no list was loaded whole.
