# PARSED REQUIREMENTS: simple_bible

*Pre-phase specification, step R01 (/eiffel.spec), 2026-10-06. Inputs read in full: research 01-07, REFERENCES, 08-HARVEST-LEDGER, 09-FEATURE-PARITY, 10-INNOVATIONS FROM PRACTICE, 11-HISTORY-TIMELINE (+ `11-timeline-pilot.csv`), 12-SEPTUAGINT-SOURCE; gui/00-GUI-SPEC, spec_windows.json, spec_windows_design_notes, spec_windows_state_diagram, gui/README; the design doc `Rix/Upcoming Projects/Bible Study Workbench - Design (2026-10-06).md`; the Python reference tools named by D-020 (`_Tools/build_rix_db.py`, `_Tools/validate_rix_db.py`, `Rix/_Tools/shape_db.py`, `Rix/_Tools/scripture_detect.py`); the fleet-rule memory notes. `research/13-USER-VOICE.md` (294 user items, 96 sources) arrived complete during R03 and was read in full; it is treated as evidence, not as requirements, and its effect is recorded in 03 (A-021 to A-030, spark dispositions) as FR-NEW-012 to FR-NEW-021, traced in 08.*

*Where research documents disagree, the later decision wins. 04-DECISIONS is binding. Three research statements were overtaken on 2026-10-06 and are read in their corrected form here: the WebView2 face (replaced by native simple_widgets, D-006), "morphology work exists for Swete" (it does not, 12-SEPTUAGINT), and "rix.db: none ships" (all of it ships, D-019).*

---

## Problem Summary

An ordinary reader on an ordinary Windows laptop (CPU only, 8-16 GB RAM, no setup skills) has no free tool that lets them **see, count, compare and check** the biblical text in Hebrew, Greek and English with every number computed, every quotation pulled from data, every fact carrying its source and license, and any AI help clearly separated from the facts. Free readers (e-Sword, theWord) do not measure; corpus tools (Text-Fabric, SHEBANQ) are not one-click installs and often carry NC data; Logos puts AI in the answer path. A full research cycle (CL 58) showed that more than half of study work is mechanical and can be done by deterministic code over SQLite.

simple_bible answers this with a deterministic Eiffel engine over a freshly built, fully provenanced SQLite distribution database; a native simple_widgets face plus a CLI/REPL; AI only as build-time data (Release 1) or as optional, labeled phrasing (later); and a private plug-in seam for Larry's own research material.

## Scope

### In Scope (Release 1, "core only", D-016)
- **L0 data:** reproducible distribution build from pinned upstream open sources (D-005): `core.db` (texts, morphology, versification map, cross-references, glosses, provenance, quarantine, caveats, normalized search columns, FTS5), `ai_data.db` (precomputed related passages made at build time, labeled AI-made), `rix.db` (Larry's author library, rebuilt fresh, every status labeled, D-019), `user.db` (the reader's own data). License gate; generated credits.
- **L1 engine:** reference parser; versification map applied before any pairing; verse hub; concordance (lemma, Strong's incl. split senses, morphology, surface); search (words, phrases, Boolean, regex, lemma/Strong's/morph); census engine (pre-registered, frequency-matched controls, FITS/PARTIAL/FAILS/NO_DATA together, method stored); shape engine (named T1/T2 shapes, near-misses, T3 never evidence); range before ruling (renderings); word's journey; divine-name marking; quotation comparer ("They Chose") over the seeded quotation index; guide assembly from engine results; related passages with reasons; library resources (public-domain commentaries, lexicons, dictionaries, devotionals) with provenance; writing checks; personal tools (notes, highlights, bookmarks, tags, history, prayer list, memory cards, reading plans, collections) keyed to canonical verse ids; export/copy with attribution and share-alike notices.
- **L2 precompute (build machine):** related passages (cross-reference votes, shared rare lemmas, embedding neighbors), quotation alignments, gloss and pronunciation tables with coverage report, lemma frequency tables for controls, shape instances.
- **L4 faces:** native `simple_widgets` GUI (Simple and Study layouts, panels P01-P11, dialogs D01-D03 and D05-D10) and a CLI/REPL (`bible.exe`) with a closed, read-only one-shot command set.
- **Private plug-in seam** (deferred interfaces only in the public build; Larry's implementation lives in a separate private repository).
- **Ports of the vault's Python tools to Eiffel** (D-020), each with a differential test.
- Windows installer (Inno Setup), core edition.

### Out of Scope
- Judgment-grade local AI (debate, adjudication) on 8-16 GB CPU machines (design doc §5).
- Any run-time AI in Release 1 (D-016): no model downloaded or run on the user's machine.
- Selling, paid tiers, accounts, telemetry (D-002, FR-064).
- Shipping copyrighted material without a license: `scholars.db`, `transcripts.db`, book texts, NBP corpus, DDD (D-002; ledger §4).
- WebView2 in any role (D-006 as decided: no fallback; NFR-012 withdrawn).
- Editing primary texts at run time; corrections go into the build with a recorded reason.
- Rahlfs (CCAT) in the public build until written permission (D-011).
- macOS/Linux native builds.

### Deferred (designed for, not built in Release 1)
- v1.5: Claim Check (I-P01), Study Ledger (I-P12), share-safe export flags (I-P05), pre-registered questions for any search (I-P13), "My ruling" (I-P16), accessibility bridge (GW-14).
- v2: World timeline over `history.db` (11-HISTORY-TIMELINE), atlas, meaning search (run-time query embedding), Exegetical Guide, senses (UBS SDBH/SDGNT), reverse interlinear, variants, clause views, full NT-Use-of-OT browser, user-made shapes (I-P14), Hebrew syntax layer (D-012).
- v3: optional local chat model behind a labeled "explain" button (FR-052/053), syntax search, sermon tools.
- The zero-install PWA (ledger L-2; 213 MB private-content DB must leave any served folder first).

## Functional Requirements

Requirement IDs FR-001 to FR-065 are carried from `research/03-REQUIREMENTS.md`. IDs FR-100 and up are derived here from the supplementary research (08-12), the GUI spec and the decisions; their source is named. Priority follows research; "R" = release.

### L0: Data and distribution build

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-001 | Reproducible build assembles `core.db` from pinned upstream sources, never by copying the vault's `bible.db` | MUST | research/03, D-005 | Two builds from the same manifest yield identical per-table checksums |
| FR-002 | Every shipped row carries a provenance key to a `source_provenance` row | MUST | research/03 | Rows without provenance = 0 |
| FR-003 | Credits file and About page generated from `source_provenance`, never hand-edited | MUST | research/03 | Shipped credits byte-equal to regenerated credits |
| FR-004 | License gate: build fails on a shipped source with license UNKNOWN; NC and SA clauses recorded | MUST | research/03, D-002 | Named build error for `UNKNOWN` + `ship = true` |
| FR-005 | Each version carries a caveat shown wherever it is displayed | MUST | research/03 | Caveat present in verse hub and census reports |
| FR-006 | Proven-wrong rows go to quarantine with reason and date; nothing deleted; quarantined refs answer NO_DATA | MUST | research/03 | Defect A1 (LXX Jer tails) reproduces as quarantined |
| FR-007 | Every defect-register class carried: A fixed, B documented, C flagged as import gaps, D protected, E caveated | MUST | research/03 | One test per register item |
| FR-008 | Display text keeps exact Unicode (MapM NBSP before paseq); search uses a separate normalized column | MUST | research/03, D-009 | Byte-equality test; NBSP phrase found via normalized column |
| FR-009 | Edition-omitted verses stored as explicit omission markers | SHOULD | research/03 | Matt 17:21 in WH reads "omitted in this edition" |
| FR-010 | Pinned-source manifest (URL, commit/release, SHA-256, license text hash) verified before import | MUST | research/03, 12 | Build refuses a hash mismatch |
| FR-100 | Swete LXX imported from First1KGreek TEI pinned at `eb81494`, `grc1`/`grc2` selection rules, apparatus and margins dropped, repairs logged in `source_repairs`, numbering-gap report classified, Gen-3 Kgdms collated against Sollupulo | MUST | 12 (D-011) | 12's build checklist passes; build fails if any verse begins with a Roman numeral without a repair row |
| FR-101 | Lettered verses, verse 0 titles, prologues and Odes `iva`/`ivb` representable (`verse_suffix`) | MUST | 12 §A7 | 3 Kgdms 2:35a and Esther prologue round-trip |
| FR-102 | Share-alike tables (Swete, MorphGNT, UBS, Wycliffe) kept in their own tables with `share_alike = true`; no extra terms | MUST | 12 §A5, D-002 | Provenance query lists every SA table |
| FR-103 | `rix.db` rebuilt from the current vault by an Eiffel port of `build_rix_db.py` rules v2.1 (R1-R15) | MUST | D-019, D-020 | Differential compare against the Python reference output = 100% (validator port) |
| FR-104 | Every Python reference tool in the product path has an Eiffel port that passes a row-by-row differential test; the test suite itself needs no Python (golden outputs) | MUST | D-020 | One differential test per port: rix.db builder, distribution builder steps, reference detector, versification map, census, shapes, quotation comparer, precompute jobs |
| FR-105 | Canonical book ids are stable and equal to the vault's `bible_books.id` (rix.db `verse_refs.book_id` contract, R12) | MUST | build_rix_db.py R12 | rix.db built against core.db's catalog equals the Python reference |
| FR-106 | Build-time precompute (related passages, alignments, gloss/pronunciation tables, lemma frequencies, shape instances) carries model id, version and date in provenance; AI-made rows flagged | SHOULD | D-016, D-017, FR-040/041 | Every `ai_data.db` row has `is_ai_made` and a method label |
| FR-107 | TIPNR prose descriptions (written by Claude 3) are labeled AI text or omitted; Strong's 1980 Moody material stripped | MUST | 09 §10 | No unlabeled TIPNR description ships |

### L1: Deterministic engine

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-020 | Reference parser: names, abbreviations, ranges, lists; names the versification system assumed; ambiguous input returns a choice, never a guess | MUST | research/03 | 300+ case suite; "Ju 1" and "Ph 1" return candidates |
| FR-021 | Verse hub: every shipped version, words with lemma, Strong's, morphology expanded to English, gloss, pronunciation, cross-references | MUST | research/03 | Gen 1:1; Ps 23:1 (LXX 22:1); Mal 4:1 (Heb 3:19; Swete leg Mal 4:1 = Rahlfs 3:19); Jer 31:31 (LXX 38:31); Heb 8:8 |
| FR-022 | Versification map (TVTMS + vault LXX Jeremiah concordance + Swete entries) applied before any pairing | MUST | research/03, D-010, 12 §A7 | Malachi, Psalms (9/10, 118/119, titles), Jeremiah, Lev 5/6, Deut 23, Num 16/17 (Swete), Joel 2-4 |
| FR-023 | Concordance by lemma, Strong's (split senses 6743/6743a), morphology, surface; Hebrew final-form-safe; Greek diacritic-safe | MUST | research/03 | Strong's count = lemma count for unsplit lemmas |
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
| FR-125 | Private plug-in seam: deferred source and lens interfaces; private results labeled by voice (trusted / hold-loosely / cite-exactly) | SHOULD | D-014, I-008 | Public build contains no lens class and no private DB names |
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
| FR-050 | Application runs with every AI component absent | MUST | research/03 | Full suite passes with no model files |
| FR-051 | CPU query embedding for semantic search | SHOULD (v2) | research/03 | Under 1 s on 4-core DDR4 |
| FR-052 | "Explain" rewrites an engine result only | COULD (v3) | research/03 | Prompt = engine output + fixed instruction |
| FR-053 | AI output never introduces a number, reference or Hebrew/Greek string absent from the engine result | MUST when FR-052 exists | research/03 | Post-check withholds or marks |
| FR-054 | Bring-your-own-key, off by default, via simple_winhttp | COULD (v3) | research/03 | Disabled without a key |

### L4: Faces and packaging

| ID | Requirement | Priority | Source | Acceptance |
|----|-------------|----------|--------|------------|
| FR-060 | Face renders pointed Hebrew (RTL, niqqud, cantillation) and polytonic Greek with bundled fonts | MUST | research/03 as modified by D-006 | D-006 spike offscreen in SW_LABEL / SW_TEXT_BOX; defects fixed in simple_shaping (GW-01..03) |
| FR-061 | CLI/REPL `bible.exe` exposes verse, concordance and census commands | MUST | research/03 | CLI tests |
| FR-062 | Inno Setup installer, core edition (AI edition later); bundles fonts; no WebView2 detection | MUST (core) | research/03 as modified by D-006 | Silent install/uninstall on a non-live identity; `user.db` kept on uninstall |
| FR-063 | Private plug-in attaches scholars/transcripts/primary_evidence only when present (rix.db now ships, D-019) | SHOULD | research/03, D-019 | Public build has no private data |
| FR-064 | No telemetry, no account, no network unless the user turns on BYOK or an update check | MUST | research/03 | Zero outbound connections by default |
| FR-065 | Never opens console windows or extra visible windows when spawning helpers | MUST | research/03 | Hidden spawns only |

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
| NFR-017 | Cold start | PERFORMANCE | launch to first verse | 3 s or less (warm 1.5 s) (GUI §14, proposed) |
| NFR-018 | Build reproducibility | CORRECTNESS | per-table checksums across two builds | identical; no wall-clock values in rows (build date passed in) |

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
| C-010 | SQLite feature ceiling is 3.31.1 until the D-007 fleet upgrade lands (header still reads 3.31.1 on 2026-10-06) | TECHNICAL |
| C-011 | Eiffel Spec Kit for every build phase | PROCESS |
| C-012 | American English in UI and documentation; CRLF in the repo | STYLE |
| C-013 | Fill gaps in the owning simple_* library; never plan a fallback to outside technology (D-006, standing rule) | ECOSYSTEM |
| C-014 | No Python in the shipped app or the distribution build (D-020) | PROCESS |
| C-015 | Class prefix unique in the fleet (chosen in R04: `BIB_`); any inline C helper prefix unique in the fleet (`sbib_`); zero C preferred | ECOSYSTEM (fleet law) |
| C-016 | Any C external that can wait must be `external "C blocking ..."` (fleet GC law) | TECHNICAL (fleet law) |
| C-017 | No visible windows in tests or builds; GUI tests run offscreen | PROCESS |
| C-018 | Pushing a changed library requires README + `/docs` + CHANGELOG updates and a downstream-dependents sweep | PROCESS |
| C-019 | Class invariants O(1); MML model clauses live in postconditions (fleet convention, commits of 2026-09-11 in simple_scholar and simple_shaping) | TECHNICAL |

## Decisions Already Made

| ID | Decision | Rationale | From |
|----|----------|-----------|------|
| D-001 | Clean `simple_bible`; simple_scholar retired after harvest | Public-facing design; no one person's frameworks | research/04 (Larry) |
| D-002 | Free tool; attribution always; NC may ship; unknown = restricted; copyrighted-without-license private | Larry's rule | research/04 (Larry) |
| D-003 | Target user: not Larry; CPU only; 8-16 GB; Windows; no setup skills | Design doc §1, §5 | research/04 (Larry) |
| D-004 | Engine owns every fact; AI optional; heavy AI precomputed | "Pulled from bible.db, never recalled" as architecture | research/04 (Larry) |
| D-005 | Distribution DB built fresh from upstream with provenance | Provenance and license certainty | research/04 |
| D-006 | Native simple_widgets face (with simple_shaping, simple_cairo, simple_shell); NO WebView2; gaps fixed in the owning libraries | "We FILL GAPS" | research/04 (Larry) |
| D-007 | Upgrade the fleet SQLite; design to 3.31.1 until it lands | Fleet consistency | research/04 |
| D-008 | Vectors: precomputed neighbors + brute-force scan (SIMPLE_SQL_VECTOR_STORE); sqlite-vec deferred | Scale is small | research/04 |
| D-009 | Separate normalized search columns; one shared idempotent normalizer for build and query | Unicode61 limits | research/04 |
| D-010 | Versification as data; every pairing goes through the map; results name the rule | Silent mispairing in half the books | research/04 |
| D-011 | Swete ships by default; Rahlfs private until written permission | Unknown is restricted | research/04 (Larry) |
| D-012 | No Hebrew syntax layer in MVP | License review pending | research/04 |
| D-013 | Run-time AI mechanics (ONNX query embedding; llama-server spawned hidden); NULL AI adapter default | Model survey | research/04 |
| D-014 | Private plug-in seam: deferred source and lens interfaces; private repo implements | D-002 | research/04 |
| D-015 | Run-time DBs: core (RO), ai_data (RO, optional), user (RW); plus rix.db (RO, D-019) and history.db (RO, v2) | Updates never touch user work | research/04, 11 |
| D-016 | Release 1 core-only: no run-time AI, but AI-made build-time data (related passages) ships labeled | Smallest, proves the promise | research/04 (Larry) |
| D-017 | Precompute on the build machine; outputs carry model id, version and date | Weak user hardware | research/04 |
| D-018 | Inno Setup, two editions; `user.db` kept on uninstall (WebView2 detection removed by D-006) | Precedent | research/04 |
| D-019 | All of rix.db ships, rebuilt to current by a reproducible builder; status travels with every document | "No reason to hold back" | research/04 (Larry) |
| D-020 | No Python in the product; Python tools are reference implementations; Eiffel ports pass differential tests | Pure Eiffel product | research/04 (Larry) |

## Innovations to Implement

| ID | Innovation | Design Impact |
|----|------------|---------------|
| I-001 | Engine owns every fact (AI as phrasing only) | `BIB_AI_TEXT` creatable only by the post-checker from an engine result; `BIB_AI_ADAPTER.explain` takes `BIB_ENGINE_RESULT`, never a string |
| I-002 | Pre-registered census, four buckets | `BIB_CENSUS_DEFINITION` frozen on first run; `BIB_BUCKETED_RESULT` cannot exist without all four buckets |
| I-003 | Versification-safe pairing as a precondition | `BIB_MAPPED_REF` creatable only by `BIB_VERSIFICATION_MAP`; pairing features take `BIB_MAPPED_REF` |
| I-004 | Provenance per row, generated credits, license gate | `BIB_FACT [G]` requires a provenance; builder postconditions `all_rows_have_provenance`, `no_unknown_license_shipped` |
| I-005 | Defects as data | Quarantine, caveat, omission and import-gap kinds are types (`BIB_OMISSION`), never empty strings |
| I-006 | Do the AI at build time | Separate build target; `ai_data.db` optional; AI-made rows carry a label invariant |
| I-007 | Quotation comparer with computed agreement class | `BIB_QUOTATION_COMPARER` computes from precomputed alignment rows; NO_DATA where alignment is absent |
| I-008 | Public core, private plug-in | Deferred `BIB_PLUGIN`, `BIB_PRIVATE_SOURCE`, `BIB_LENS`; voice label on every private hit |
| I-P02 | Frequency-matched controls by default | `BIB_CONTROL_SET` with stored seed |
| I-P03 | FAILS always shown | Same as I-002 |
| I-P06/07/08/09 | They Chose; Word's Journey; Divine-name view; Range before ruling | Study cluster engines, each returning provenance-bearing results |
| I-P01/05/12/13/16 | Claim Check; share-safe export; ledger; pre-registration; human ruling (v1.5) | Interfaces designed now, built in v1.5 |

## Risks to Address in Design

| ID | Risk | Mitigation Strategy |
|----|------|---------------------|
| RISK-001 | Compiled SQLite 3.31.1 | Design to 3.31.1 (CHECK not STRICT; normalized columns not trigram; no `->>`; math in Eiffel); D-007 as a fleet task |
| RISK-002 | FTS5 mishandles Hebrew marks and Greek accents | `BIB_NORMALIZER` family, idempotence postcondition, normalized columns, trap corpus tests |
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
| RISK-018 (new) | 15 v1 GUI gap items in other libraries (GW-01..13, 24, 26) gate the GUI | Engine and CLI phases independent of the GUI; panel order by gap dependency (R03) |
| RISK-019 (new) | GC stall: `eiffel_sqlite_2025` `c_sqlite3_step` not marked `blocking` (fleet audit, HELD for Larry's gate) | Prerequisite fleet task; engine chunks long queries so no single step is long (R03) |
| RISK-020 (new) | Swete is uncorrected OCR (74 errors in 56 Genesis verses) | Repair log; OCR caveat on every Swete display and on quotation verdicts (R03) |
| RISK-021 (new, 13) | Lost or scrambled user notes destroy trust faster than any bug (13 T10, gotcha 3) | Append-only user data with history, soft delete, rotating backup, hub-id keys (R03 A-022) |
| RISK-022 (new, 13) | Trust betrayals (settings reset, forced redesign, silent text change) | Migration preserves settings; per-text seal and changelog; trust rules ratified at intent (R03 A-023, A-025, A-029) |

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
3. Importers, repairs, defect rules, normalization, versification, FTS and checksums run as steps.
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

### UC-012: Private build lights up Larry's plug-in
**Actor:** Larry
**Main Flow:** Larry's private executable registers his plug-in at startup; it attaches scholars/transcripts/primary_evidence when present; lens results arrive labeled by voice.
**Postcondition:** The public executable contains none of these classes.

### UC-013 (v1.5): Claim Check
**Actor:** Reader
**Main Flow:** User pastes text; engine extracts references and claims deterministically; each is checked against the engine and marked SUPPORTED / CONTRADICTED / PARTLY / CAN'T BE CHECKED with evidence.

### UC-014 (v2): Synchronism slice
**Actor:** Reader
**Main Flow:** From Luke 3:1 the user asks for narrated time; the engine returns every visible lane's items at that range, each with certainty class and sources; disputes show all positions.
