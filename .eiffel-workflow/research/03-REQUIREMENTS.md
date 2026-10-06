# REQUIREMENTS: simple_bible

*Derived from the design doc (§§1 to 8), the vault's `_bible.db Defect Register.md`, `_Text Credits (paste-ready).md`, Larry's four decisions (04-DECISIONS D-001 to D-004), and the landscape (02). Model-specific targets wait on `Rix/Data/_Small Model Survey (2026-10-06).md` (pending).*

## Functional Requirements

### L0: Data and distribution build

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | A reproducible build script assembles the distribution database from upstream open sources (not by copying the vault's `bible.db`) | MUST | Running the build twice from the same pinned sources yields byte-identical table contents (checksummed per table) |
| FR-002 | Every shipped row carries a provenance key to a `source_provenance` row (source, edition, URL, retrieval date, license, clauses beyond attribution) | MUST | A query for rows with no provenance returns 0 |
| FR-003 | The credits file (and the in-app About page) is generated from `source_provenance`, never hand-edited | MUST | Credits regenerate from the table; a diff test fails if the shipped file differs from the generated one |
| FR-004 | A license gate refuses to include any source whose license is UNKNOWN; NC and SA clauses are recorded and surfaced | MUST | Build fails with a named error if a source row has license `UNKNOWN` and `ship = true` |
| FR-005 | Each version carries a `caveat` text shown wherever that version is displayed (the vault's `bible_versions.caveat` practice) | MUST | Every version with a known issue displays its caveat in the verse hub and in census reports |
| FR-006 | Rows proven wrong go to a quarantine table with reason and date; nothing is deleted | MUST | Defect register A1 (LXX Jer 1:20-37, 6:31-34, 16:22-27) reproduces as quarantined; queries for those refs return NO_DATA, not foreign text |
| FR-007 | The build applies or records every defect-register class: A (contamination) fixed; B (reference space) documented; C (missing data) flagged as import gaps; D (non-defects) protected from "repair"; E (quality) caveated | MUST | A test per register item (A1, B1 to B4, C table, D list, E1 to E11) passes |
| FR-008 | Display text keeps exact Unicode (including MapM's 2,488 deliberate NBSP before paseq); a separate normalized column carries search forms | MUST | MapM row byte-equality test against source; search for a MapM phrase with an ordinary space succeeds through the normalized column |
| FR-009 | Edition-omitted verses (WH and ASV critical-text omissions) are stored as explicit "omitted by this edition" markers, not empty strings | SHOULD | Matt 17:21 in WH shows "omitted in this edition", not a blank |
| FR-010 | A pinned-source manifest (URL, commit or release, SHA-256) is kept with the build | MUST | Manifest present; build verifies hashes before import |

### L1: Deterministic engine

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-020 | Reference parser accepts common English book names and abbreviations, ranges and lists, and names the versification system it assumed | MUST | Parser test suite (at least 300 cases) passes; ambiguous input returns a choice, never a guess |
| FR-021 | Verse hub: one verse in every shipped version, with Hebrew/Greek words, lemma, Strong's, morphology (expanded to English), gloss and pronunciation, and cross-references | MUST | Gen 1:1, Ps 23:1 (LXX 22:1), Mal 4:1 (Heb 3:19), Jer 31:31 (LXX 38:31), Heb 8:8 all return correctly aligned rows |
| FR-022 | Versification map (TVTMS-based, plus the vault's verified LXX Jeremiah concordance) is applied before any cross-version pairing | MUST | Pairing test covers Malachi, Psalms (LXX 9 = MT 9+10; LXX 118 = MT 119), Jeremiah (LXX 38 = MT 31 and the rest of B2), Lev 5:21/6:2, Deut 23 |
| FR-023 | Concordance by lemma, Strong's (including split senses such as 6743 / 6743a), morphology, and surface form; Hebrew final-form-safe; Greek diacritic-safe | MUST | Counting by Strong's equals counting by lemma for unsplit lemmas; final-form and diacritic variants return the same hits |
| FR-024 | Joins are by keys (Strong's, lemma id, word id), never by display strings (defect E8: χ written as ξ in `macula_hebrew.greek`) | MUST | No engine query uses a display string as a join key (static check over SQL) |
| FR-025 | Census engine: a census definition (question, corpus, criteria, controls, expected failure condition) is stored before the run and cannot be edited after a run, only versioned | MUST | Attempt to edit a run census raises a contract violation; a new version gets a new id |
| FR-026 | Every census and shape query returns FITS, PARTIAL, FAILS and NO_DATA together, with near-misses; there is no API to request FITS alone | MUST | The public query features have no "fits only" form; results always carry all four buckets |
| FR-027 | NO_DATA is kept distinct from FAILS (an absence in tagging is not an absence in the text) | MUST | Heb 11:3 / Eph 4:12 regression from shape.db v1 reports NO_DATA where tagging is missing |
| FR-028 | Shape engine: named structural patterns with tiers T1 (mechanical), T2 (taxonomy-assisted) and T3 (judgment); T3 rows never returned as evidence | MUST | Port of shape.db's 27 shapes (those depending only on shipped data) reproduces published counts |
| FR-029 | Range viewer: every attested sense/gloss of a lemma with supporting verses, laid out before any ruling | SHOULD | For a sample of 50 lemmas, every distinct gloss in the data appears with at least one verse |
| FR-030 | Quotation comparer: for each indexed NT quotation, show NT, LXX and MT side by side and compute agreement class | SHOULD | Heb 8:8-12 vs LXX Jer 38:31-34 vs MT Jer 31:31-34 is classified "agrees with LXX"; index seeded from UBS Parallel Passages |
| FR-031 | Checks: gloss and pronunciation on first use; no bare script; capital after a colon; citation complete; provenance tag present | SHOULD | Each check has positive and negative fixtures |
| FR-032 | Every number shown is traceable: a "show method" view lists the query, corpus, version and counts | MUST | Each result screen has a method view; the method re-runs to the same number |
| FR-033 | Engine API is usable without any UI (library classes plus CLI) | MUST | All engine features covered by tests that never start WebView2 |

### L2: Precomputed intelligence (build time)

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-040 | Verse and pericope embedding vectors are computed on the build machine and shipped in SQLite | SHOULD | Vector table present; model id, version and prefix convention recorded in provenance |
| FR-041 | Related-passage lists per verse from cross-references (with votes), shared rare lemmas and embedding neighbors, each with its reason | SHOULD | Each related item names which signal produced it |
| FR-042 | Quotation alignment tables NT to LXX to MT computed once | SHOULD | Table covers every quotation in the seeded index |
| FR-043 | Gloss and pronunciation tables for every Hebrew and Greek lemma | MUST | Coverage report: lemmas with no gloss listed, not hidden (defect C: 34.2% Hebrew `word_strongs.gloss` NULL in the vault) |
| FR-044 | Any model-written text (chapter overviews) is reviewed by a person and labeled "AI-drafted, reviewed by ..." | COULD | Label present on every such row; unreviewed rows never ship |

### L3: Optional run-time AI

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-050 | The application runs with every AI component absent | MUST | Full test suite passes with no model files installed |
| FR-051 | Query embedding on CPU for semantic search | SHOULD | Query embedded in under 1 s on a 4-core DDR4 laptop |
| FR-052 | "Explain" button: a small local model rewrites an engine result in plain English, given only that result | COULD | Prompt contains only engine output plus a fixed instruction; output labeled "AI wording; facts above are from the engine" |
| FR-053 | AI output never introduces a number, verse reference or quotation absent from the engine result | MUST (when FR-052 exists) | Post-check flags any digit, reference pattern or Hebrew/Greek string not present in the input; flagged output is withheld or marked |
| FR-054 | Bring-your-own-key online model, off by default | COULD | Disabled unless the user enters a key; network calls via simple_winhttp |

### L4: Front ends and packaging

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-060 | WebView2 front end renders pointed Hebrew (right to left, niqqud, cantillation) and polytonic Greek correctly with bundled fonts | MUST | Visual check of Gen 1:1 MapM, Ps 119:1 WLC, John 1:1 SBLGNT against a reference rendering |
| FR-061 | CLI/REPL (`bible.exe`) exposes verse, concordance and census commands | MUST | CLI tests in CI |
| FR-062 | Installer (Inno Setup) in two editions: core (no AI) and core + AI | MUST (core) / SHOULD (AI) | Silent install and uninstall on a clean Windows 10 VM; detects WebView2 and installs it if missing |
| FR-063 | Private plug-in loads `rix.db`, `scholars.db`, `transcripts.db`, `primary_evidence.db` and the framework lenses only when present | SHOULD | Public build contains no private data and no lens classes; Larry's build lights them up |
| FR-064 | No telemetry, no account, no network access unless the user turns on BYOK or an update check | MUST | Network monitor during test session shows zero outbound connections in default configuration |
| FR-065 | Never opens console windows or extra visible windows when spawning helpers | MUST | llama-server and any helper processes spawn hidden |

## Non-Functional Requirements

| ID | Requirement | Category | Measure | Target |
|----|-------------|----------|---------|--------|
| NFR-001 | Verse hub latency | PERFORMANCE | Time from reference to rendered page | under 200 ms on 4-core / 8 GB / SSD |
| NFR-002 | Whole-canon concordance or census | PERFORMANCE | Wall time | under 2 s typical; under 10 s for a census with controls |
| NFR-003 | Memory, core edition | RESOURCE | Working set | under 1 GB resident |
| NFR-004 | Memory, AI edition with chat model loaded | RESOURCE | Working set | under 4 GB for a 1 to 4B Q4 model (8 GB machines run smallest models only) |
| NFR-005 | Disk | RESOURCE | Installed size | core 2 to 4 GB; AI edition adds model files |
| NFR-006 | Determinism | CORRECTNESS | Same query, same database | identical output, byte for byte |
| NFR-007 | Provenance completeness | CORRECTNESS | Rows without provenance | 0 |
| NFR-008 | License compliance | LEGAL | Shipped sources with UNKNOWN license | 0 |
| NFR-009 | No GPU | PORTABILITY | GPU required at any tier | none |
| NFR-010 | Windows support | PORTABILITY | OS | Windows 10 22H2 and Windows 11, x64 |
| NFR-011 | Privacy | SECURITY | Outbound connections by default | 0 |
| NFR-012 | Local server binding | SECURITY | Listening interfaces | 127.0.0.1 only, random port, per-session token |
| NFR-013 | Accessibility | USABILITY | Font scaling, keyboard navigation, dark mode | large-print friendly (matches Larry's audience); full keyboard use |
| NFR-014 | AI labeling | TRUST | AI-produced text unlabeled | 0 instances |
| NFR-015 | Contract coverage | QUALITY | Public features with require/ensure | 100% of engine public features |

## Constraints

| ID | Constraint | Type | Immutable? |
|----|------------|------|------------|
| C-001 | Must be SCOOP-compatible | TECHNICAL | YES |
| C-002 | Must prefer simple_* over ISE | ECOSYSTEM | YES |
| C-003 | Void-safe ("all") | TECHNICAL | YES |
| C-004 | Engine owns every fact; AI never a source of facts | ARCHITECTURE | YES (D-004) |
| C-005 | Free tool; nothing sold | LICENSING | YES (D-002) |
| C-006 | Unknown license = restricted; copyrighted-without-license stays private | LICENSING | YES (D-002) |
| C-007 | Target hardware: CPU only, 8 to 16 GB, Windows | HARDWARE | YES (D-003) |
| C-008 | Clean new project; simple_scholar retired and archived only after harvest | PROCESS | YES (D-001) |
| C-009 | Networked code in the shipped app uses simple_winhttp, not libcurl-based simple_http | ECOSYSTEM | YES (libcurl.dll is not redistributable with a finalized binary per simple_winhttp README) |
| C-010 | SQLite build must be current enough for the features chosen (see D-007) | TECHNICAL | NO (upgrade path) |
| C-011 | Eiffel Spec Kit for every build phase (intent, contracts, review, implement, verify, harden, ship) | PROCESS | YES |
| C-012 | American English in all UI and documentation | STYLE | YES |
