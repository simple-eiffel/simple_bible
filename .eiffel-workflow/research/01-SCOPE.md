# SCOPE: simple_bible

*Pre-phase research, /eiffel.research, 2026-10-06. Step 0 input: `Rix/Upcoming Projects/Bible Study Workbench - Design (2026-10-06).md` (the design doc). Companion file in this folder: `08-HARVEST-LEDGER.md` (written separately; it records what simple_bible takes from `D:\prod\simple_scholar` before that project is retired).*

## Step 0: The Idea

| Field | Content |
|-------|---------|
| IDEA | A free, installable Bible-study workbench for Windows in which a deterministic engine over SQLite does all the counting, lookup, comparison and checking of the Hebrew, Greek and English text, and AI is an optional, labeled layer that never supplies a fact. |
| CONTEXT | A step-by-step teardown of a full research cycle (CL 58, 2026-10-06) found that more than half the work by volume is mechanical: lookups, concordance, censuses with controls, pattern queries, quotation comparison, style checks. Those parts can be done by code and SQLite with no AI and no miscounting. |
| INITIAL THOUGHTS | Five layers (L0 data, L1 engine, L2 precomputed intelligence, L3 optional run-time AI, L4 front ends). "Do the AI at build time, not at run time." WebView2 face as primary UI because it renders Hebrew correctly. |
| CONSTRAINTS | Free tool (nothing sold). Target user is not Larry: CPU only, 8 to 16 GB RAM, no or weak integrated GPU, Windows, no setup skills. Private and copyrighted data never ships. Engine owns every fact. |

## Problem Statement

In one sentence: **An ordinary reader on an ordinary Windows laptop has no free tool that lets them see, count, compare and check the biblical text in Hebrew, Greek and English with every number computed and every quotation pulled from data, where any AI help is clearly separated from the facts.**

What's wrong today:
- Free desktop tools (e-Sword, theWord, Bible Analyzer, Xiphos) are strong readers and searchers, but none of them treats a count as a reproducible, pre-registered measurement with control groups and near-misses, and none computes "agrees with the Hebrew against the Septuagint" for an NT quotation.
- Scholarly corpus tools (Text-Fabric/BHSA, SHEBANQ, Bible Online Learner, Parabible) are powerful but are Python notebooks or web services, not a one-click Windows install, and several carry non-commercial or restrictive data licenses.
- Commercial suites (Logos, Accordance) are capable but paid, and Logos now leads with AI answers (Smart Search, Study Assistant), which is the opposite of "the engine owns every fact."
- General-purpose AI chat models miscount, misquote and invent citations, especially in Hebrew and Greek.

Who experiences this: Lay students of Scripture, Bible-study leaders, pastors without a Logos budget, seminary students, and Larry's own readers who want to check his work.

Impact of not solving: Readers either trust a chatbot's numbers, pay for a commercial suite, or never check. Larry's vault discipline ("pulled from bible.db, never recalled") stays locked on one machine.

## Target Users

| User Type | Needs | Pain Level |
|-----------|-------|------------|
| Lay reader / Bible-study leader (primary, not Larry) | One verse in many versions; word lookup with gloss and pronunciation; "where else does this word occur"; plain-English explanations; zero setup | HIGH |
| Student of Hebrew/Greek | Lemma and morphology concordance; LXX vs MT comparison; versification-safe pairing; range of attested senses | HIGH |
| Careful researcher / essay writer | Pre-registered censuses with controls; FITS / PARTIAL / FAILS / NO_DATA reporting; quotation comparer; reproducible method stored beside results; citation and style checks | HIGH |
| Larry (private build) | All of the above plus `rix.db`, `scholars.db`, `transcripts.db`, `primary_evidence.db`, framework lenses, loaded through a private plug-in | MEDIUM (he already has the vault tooling) |
| Zero-install visitor | Read and search in a browser without an installer | LOW |

## Success Criteria

| Level | Criterion | Measure |
|-------|-----------|---------|
| MVP | Installs and runs on the target machine | Clean install on Windows 10/11, 4 cores, 8 GB RAM, no GPU; first window in under 5 s on SSD; no admin-only steps beyond the installer |
| MVP | Verse hub | Any reference returns every shipped version, Hebrew/Greek words with lemma, morphology, gloss and pronunciation, in under 200 ms |
| MVP | Versification-safe pairing | Hebrew/English/LXX offsets (Malachi 3/4, Psalms, Jeremiah LXX order, Lev 5/6, Deut 23, and the rest of TVTMS) are applied before any cross-version pairing; regression suite of known offsets passes 100% |
| MVP | Concordance | By lemma, Strong's number (including split senses such as 6743/6743a) and morphology; final-form-safe Hebrew; diacritic-safe Greek; whole-canon query under 1 s |
| MVP | Census engine | A question stored before the run, with controls; results reported as FITS / PARTIAL / FAILS / NO_DATA together; method and counts stored beside the result; re-run gives identical output |
| MVP | Provenance and credits | Every shipped row traceable to a `source_provenance` row; the credits file is generated from that table, never hand-edited |
| MVP | Works with AI absent | Every MVP feature passes its tests with no model files present |
| Full | Quotation comparer | For each indexed NT quotation, MT/LXX/NT aligned and labeled "agrees with MT against LXX", "agrees with LXX against MT", "agrees with both", or "agrees with neither" |
| Full | Semantic search | Query embedded on CPU in under 1 s; nearest passages returned from precomputed vectors with sources shown |
| Full | Optional explain button | Small local model rewrites an engine result in plain English; output labeled as AI; context capped (about 1,500 tokens) so the first word appears in under 15 s on a DDR4 laptop |
| Full | Private plug-in | Larry's build loads rix/scholars/transcripts/primary_evidence and the framework lenses only when present; the public build contains none of their code paths' data |

## Scope Boundaries

### In Scope (MUST)
- L0: A distribution database built reproducibly from openly licensed sources (not a copy of the vault's `bible.db`), with a provenance table, version caveats, a quarantine table, versification map and FTS indexes.
- L1: Deterministic engine: verse hub, versification map, concordance, census engine, shape engine, range viewer, checks.
- L4: WebView2 front end (Hebrew and Greek render correctly) and a CLI/REPL for power users.
- Generated credits file; license gate (unknown license = restricted).
- Windows installer (core edition, no AI).

### In Scope (SHOULD)
- Quotation comparer (NT to LXX to MT), driven by a precomputed alignment table.
- L2 precomputed data: verse/pericope embeddings, related-passage lists, gloss and pronunciation tables.
- L3: CPU query embedding for semantic search.
- Private plug-in seam for Larry's data and lenses.
- "Core + AI" installer edition.

### Out of Scope
- Judgment-grade local AI (debate, adjudication): not realistic on 8 to 16 GB CPU machines (design doc §5).
- Selling anything, paid tiers, accounts, telemetry: it is a free tool.
- Shipping copyrighted material without a license (scholars.db, transcripts.db, book texts).
- macOS/Linux native builds: WebView2 is Windows-only; the PWA covers other platforms.
- A native (non-WebView2) Hebrew text surface in the MVP: depends on `simple_shaping`, which is pre-release.
- Editing primary texts: the engine reads and reports; corrections go into the build pipeline with a recorded reason.

### Deferred to Future
- Optional chat model ("explain" button): after the core release (pending Larry's decision on core-only first release).
- Bring-your-own-key online model: off by default, later.
- Reranker: only if semantic search quality needs it.
- PWA with a slimmed database: sql.js loads the whole database into memory, so the 400 to 700 MB core database is too large for it.
- Native simple_widgets face: when `simple_shaping` reaches release.
- Hebrew syntax layer (BHSA is CC BY-NC; MACULA Hebrew terms to confirm): after license review.

## Constraints

| Type | Constraint |
|------|------------|
| Hardware | CPU only; 8 GB RAM floor for the core tier, 16 GB for comfortable local chat; no GPU required at any tier (design doc §5) |
| Platform | Windows 10/11 x64; WebView2 Runtime (preinstalled on Windows 11 and on the vast majority of Windows 10 devices, per Microsoft) |
| Licensing | Free distribution; NC material may ship with attribution (D-002); unknown license = restricted; copyrighted-without-license stays private |
| Facts | Engine owns every fact; AI never supplies a number, verse or quotation |
| Ecosystem | Eiffel, simple_* first, SCOOP-compatible, void-safe, Design by Contract |
| Data | The vault's `_bible.db Defect Register.md` classes A to E (contamination, reference space, missing data, non-defects, quality) must be carried into the distribution build as fixes or caveats |
| Process | Eiffel Spec Kit phases for every phase of the build |
| Disk | Core install about 2 to 4 GB including the database; AI edition adds model files |

## Assumptions to Validate

| ID | Assumption | Risk if False |
|----|------------|---------------|
| A-1 | The compiled SQLite in `eiffel_sqlite_2025` supports what the engine needs | **Already partly false:** the compiled library is SQLite 3.31.1 (source id 2020-01-27), not the 3.51.1 its README states; no trigram tokenizer (3.34.0+), no STRICT tables (3.37.0+), no `->>` (3.38.0+), no contentless-delete (3.43.0+), load_extension omitted. See RISK-001. |
| A-2 | FTS5 unicode61 can index pointed Hebrew and polytonic Greek usefully | Default token categories are "L* N* Co", so combining marks (Mn: Hebrew niqqud and cantillation, combining Greek accents) act as separators, and diacritic removal applies to Latin script only. A normalized search column is required. |
| A-3 | All MUST-ship sources are licensed for free redistribution | Rahlfs (CCAT user declaration), Byzantine edition, SP, TgN, TgW are unresolved; MorphGNT morphology is CC BY-SA per its repo while the vault credits list CC BY 4.0 |
| A-4 | A multilingual embedding model of about 600M parameters or less gives useful Hebrew and Greek retrieval | Semantic search would be English-only; mitigated by lemma-based related passages |
| A-5 | The simple_scholar WebView2 face (`bible_htmx`) still compiles and renders Hebrew | Spike fails; front end must be rebuilt (cost, not blocker) |
| A-6 | `simple_onnx` (ONNX Runtime 1.17.3) plus its SentencePiece tokenizer can run the chosen embedding model | Need a tokenizer port or a llama.cpp embedding path |
| A-7 | A small (1 to 4B) 4-bit chat model on CPU is fast enough for a short "explain" | Feature stays deferred; core is unaffected |
| A-8 | An open NT-quotation dataset exists for the quotation comparer | UBS Paratext Parallel Passages (CC BY-SA 4.0) lists OT quotes in the NT; needs fetching and evaluation |

## Research Questions
- Which existing free tools already do pre-registered counting, controls and near-miss reporting? (Landscape answer: none found.)
- Which open datasets provide versification mapping (TVTMS, Copenhagen Alliance) and NT-quotation indexes (UBS Parallel Passages)?
- What is the exact license position of each candidate source for a free, attributed redistribution?
- Can the SQLite build be upgraded and extended (sqlite-vec statically compiled) without breaking the simple_* fleet?
- Which embedding and chat models fit the CPU tiers? (Pending: `Rix/Data/_Small Model Survey (2026-10-06).md`, not yet written when this research ran.)
- What from simple_scholar is worth harvesting? (See `08-HARVEST-LEDGER.md`.)
