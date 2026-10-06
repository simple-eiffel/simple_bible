# LANDSCAPE: simple_bible

*Every URL below was fetched or returned by a live search on 2026-10-06. Where a page did not state a fact, this file says so rather than filling it in.*

The landscape splits into four groups: (A) free Bible-study applications, (B) open scholarly corpora and data platforms, (C) commercial references used only for feature comparison, and (D) enabling technology. Then the Eiffel ecosystem check.

---

## A. Free Bible-Study Applications

### A1. STEP Bible (Tyndale House, Cambridge)
| Aspect | Assessment |
|--------|------------|
| Type | APPLICATION (web + offline desktop) |
| Platform | Web; desktop for Windows, macOS, Linux |
| URL | https://www.stepbible.org/ ; downloads https://www.stepbible.org/downloads.jsp |
| Maturity | MATURE (desktop download version 26_1_2 listed) |
| License | Software license not stated on the download page; data is in STEPBible-Data (see B1) |

**Strengths:** Original-language tools, interlinear, cross-references, people/places directories, offline desktop edition, 50 interface languages.
**Weaknesses:** Ships ESV and NIV (licensed texts), so it is not a model for an all-open distribution; no pre-registered census or control-group counting; no quotation-agreement computation.
**Relevance:** 60%. It is the closest free peer in purpose, and its open dataset (B1) is a primary source for us.

### A2. The SWORD Project (CrossWire) with Xiphos and BibleTime
| Aspect | Assessment |
|--------|------------|
| Type | LIBRARY (SWORD engine) + APPLICATIONS (front ends) |
| Platform | C++ engine; Xiphos on Linux/UNIX/Windows (GTK); BibleTime; Ezra Bible App |
| URL | https://www.crosswire.org/sword/index.jsp ; https://xiphos.org/ |
| Maturity | MATURE (Xiphos 4.5.0, 2026-08-31; BibleTime 3.2.0, February 2026; Ezra 1.20, June 2026) |
| License | GPL 2.0 (SWORD tools); Xiphos open source |

**Strengths:** Hundreds of modules in about 100 languages; the module format is a de facto exchange standard; the Tyndale and Wycliffe texts in the vault came from CrossWire modules.
**Weaknesses:** GPL engine (incompatible with simple_* MIT style if linked); module-oriented reading, not measurement; module licenses vary per module.
**Relevance:** 40%. A source of module texts and a reference for the module/plug-in pattern, not a dependency.

### A3. e-Sword (Rick Meyers)
| Aspect | Assessment |
|--------|------------|
| Type | APPLICATION |
| Platform | Windows, Mac, Android, iPad, iPhone |
| URL | https://www.e-sword.net/ |
| Maturity | MATURE |
| License | Free, proprietary (not open source) |

**Strengths:** Free, popular, parallel Bibles, Strong's search, tooltips, built-in study-notes editor.
**Weaknesses:** Closed; English-reader oriented; no reproducible counting.
**Relevance:** 30%. Sets the user-expectation baseline for a free Windows Bible tool.

### A4. theWord
| Aspect | Assessment |
|--------|------------|
| Type | APPLICATION |
| Platform | Windows (theWord 7), portable USB edition, separate mobile app |
| URL | https://www.theword.net/ |
| Maturity | MATURE |
| License | Free ("no catches, no ads, no nags, no registration"); proprietary |

**Strengths:** Fast, customizable, morphological search, large add-on module library, portable install.
**Weaknesses:** Closed; no measurement discipline.
**Relevance:** 30%. Its "no registration, not even your e-mail" stance matches our free-tool posture.

### A5. Bible Analyzer
| Aspect | Assessment |
|--------|------------|
| Type | APPLICATION |
| Platform | Windows 7 to 11, macOS 10.8 to 15.1, Linux/Ubuntu 24.04 |
| URL | https://www.bibleanalyzer.com/ |
| Maturity | MATURE (maintained since 2005) |
| License | Free core, paid premium modules; proprietary |

**Strengths:** The closest free tool to "analysis": statistics, word lists, proximity/regex search, hit charts across chapters, LexiScope morphology.
**Weaknesses:** Statistics are descriptive (counts and charts), not pre-registered questions with controls; closed.
**Relevance:** 45%. Its hit charts and word lists are features our census engine should match and exceed.

---

## B. Open Scholarly Corpora and Data Platforms

### B1. STEPBible-Data
| Aspect | Assessment |
|--------|------------|
| Type | DATASET |
| URL | https://github.com/STEPBible/STEPBible-Data |
| Maturity | MATURE (1,201 commits; ongoing) |
| License | CC BY 4.0 per the repository ("Include any part of STEPBible-Data in any software or publications without requesting permission"; credit "STEP Bible") |

**Contents:** TAHOT (tagged Hebrew OT), TAGNT (Greek NT, NA27/28 and TR and others), TBESH/TBESG (extended-Strong's lexicons), TFLSJ (LSJ for Bible words), TIPNR (proper names), **TVTMS (versification traditions across Hebrew, Latin, Greek and English, with rules per section)**, TEHMC/TEGMC (morphology codes), TTESV (tagged ESV).
**Note:** The vault's `_Text Credits` records TTESV as NC-restricted. The ESV text is Crossway's, so TTESV is excluded from the shipped build regardless of the repository-level statement.
**Relevance:** 90%. TVTMS is the strongest candidate for the versification map; TBESH/TBESG/TIPNR give glosses, lexicon entries and names.

### B2. Clear Bible MACULA Greek and MACULA Hebrew
| Aspect | Assessment |
|--------|------------|
| Type | DATASET |
| URL | https://github.com/Clear-Bible/macula-greek ; https://github.com/Clear-Bible/macula-hebrew |
| Maturity | MATURE (macula-greek 706 commits, active) |
| License | Per-component LICENSE.md. Hebrew: WLC public domain; morphology from OSHB; "Cherith Glosses" CC BY 4.0; syntax trees by Clear Bible and the Groves Center |

**Contents:** Syntax trees, morphology, glosses, word senses (UBS MARBLE), semantic roles, participant referents (`subjref`, `referent`). Greek covers Nestle 1904 and SBLGNT; formats TEI, Nodes, Lowfat, TSV.
**Weaknesses:** The vault's defect register E8 (the `greek` column in `macula_hebrew` writes chi as xi) and E11 (MACULA's Judges Greek differs from Rahlfs' row text) must be carried as caveats. MACULA Hebrew's full license must be read before shipping.
**Relevance:** 85%. The only open source of referent resolution and syntax for the NT.

### B3. OpenScriptures morphhb (OSHB)
| Aspect | Assessment |
|--------|------------|
| Type | DATASET |
| URL | https://github.com/openscriptures/morphhb |
| Maturity | MATURE (319 commits) |
| License | Lemma and morphology CC BY 4.0; WLC text public domain |

**Format:** OSIS XML, each word with lemma (augmented Strong's), morphology and an immutable id; JSON conversions available.
**Relevance:** 95%. The Hebrew backbone (WLC plus morphology).

### B4. MorphGNT SBLGNT and the SBLGNT itself
| Aspect | Assessment |
|--------|------------|
| Type | DATASET |
| URL | https://github.com/morphgnt/sblgnt ; https://www.sblgnt.com/ |
| Maturity | MATURE (MorphGNT v6.12, DOI 10.5281/zenodo.376200) |
| License | **SBLGNT text: now CC BY 4.0** ("licensed freely under the Creative Commons Attribution 4.0 International Public License", sblgnt.com). **MorphGNT morphology and lemmatization: "CC-BY-SA"** per the MorphGNT README, which still cites the older SBLGNT EULA for the text |

**Discrepancy to resolve:** The vault's credits list "SBLGNT via MorphGNT, CC BY 4.0". The morphology layer is share-alike per its own README. Share-alike is compatible with a free tool but must be recorded and honored for derived tables.
**Relevance:** 90%. Greek NT backbone.

### B5. ETCBC BHSA, Text-Fabric and SHEBANQ
| Aspect | Assessment |
|--------|------------|
| Type | DATASET + PYTHON TOOLKIT + WEB SERVICE |
| URL | https://github.com/ETCBC/bhsa ; https://github.com/annotation/text-fabric ; https://pypi.org/project/text-fabric/ ; https://shebanq.ancient-data.org/ |
| Maturity | MATURE (BHSA versions since 2011; text-fabric 13.1.0, 2026-01-15; the old ETCBC/text-fabric repo is marked "Unsupported" and work moved to annotation/text-fabric) |
| License | **BHSA: CC BY-NC 4.0** ("do not use the data for commercial applications without consent"); Text-Fabric: MIT |

**Strengths:** The richest open Hebrew linguistic database (clause, phrase, syntax features); corpus-as-annotated-graph model.
**Weaknesses:** Python and notebooks, not an installable app; NC license.
**Note under D-002:** Because simple_bible is free, BHSA's NC clause does not by itself bar shipping it with attribution. This is the best available answer to the vault's known weakness ("the OT side is weak: no syntax tree and no semantic-domain layer", shape.db notes). See D-012.
**Relevance:** 70%. Model for the data design; candidate Hebrew syntax layer.

### B6. Bible Online Learner
| Aspect | Assessment |
|--------|------------|
| Type | WEB SERVICE (open source) |
| URL | https://learner.bible/ |
| Maturity | MATURE |
| License | Free to use; source on GitHub |

**Strengths:** Corpus-driven language teaching using ETCBC4 and Nestle 1904; exercises drawn from the database; links to SHEBANQ.
**Relevance:** 25%. Shows that corpus data can drive lay-friendly pedagogy; not a dependency.

### B7. Parabible
| Aspect | Assessment |
|--------|------------|
| Type | WEB SERVICE |
| URL | https://parabible.com/ |
| Maturity | GROWING |
| License | Free to use; license and data sources not stated on the page |

**Strengths:** Parallel BHS/LXX/NET display, clause and word-feature search, syntax search.
**Relevance:** 35%. Its parallel Hebrew/Greek/English view is the UX target for our verse hub.

### B8. OpenBible.info cross-references
| Aspect | Assessment |
|--------|------------|
| Type | DATASET |
| URL | https://www.openbible.info/labs/cross-references/ |
| Maturity | MATURE |
| License | Creative Commons Attribution |

**Contents:** About 340,000 cross-references with community votes (the vault holds 344,799 rows; votes range -87 to 1274 per the defect register, Class D).
**Relevance:** 85%. Seeds the related-passage lists (L2).

### B9. UBS open-license resources (Paratext Parallel Passages, SDBH/SDGNT dictionaries)
| Aspect | Assessment |
|--------|------------|
| Type | DATASET |
| URL | https://github.com/ubsicap/ubs-open-license |
| Maturity | MATURE |
| License | CC BY-SA 4.0 for all resources |

**Contents:** UBS Dictionary of Biblical Hebrew (from SDBH) and of the Greek NT (from SDGNT) in XML/JSON; **Paratext Parallel Passages database, which includes OT quotes in the NT, marked exact and partial match**; HOTTP textual notes; MARBLE images and routes.
**Relevance:** 85%. The best open seed for the quotation comparer's index, and an open semantic-domain lexicon for the range viewer.

### B10. Versification specifications
| Aspect | Assessment |
|--------|------------|
| Type | SPECIFICATION + DATA |
| URL | https://github.com/Copenhagen-Alliance/versification-specification |
| Maturity | GROWING |
| License | LICENSE.md in repo (type not shown on the page; the awesome-biblical-data catalog lists Apache-2.0 for code) |

**Contents:** JSON versification mappings (based on Paratext VRS) and rule-based versification "sniffing", from a working group of UBS, Tyndale House, YouVersion, GBI and SIL. LXX coverage not stated.
**Relevance:** 60%. Complements STEPBible TVTMS; LXX-specific offsets (Psalms, Jeremiah chapter order) will still need the vault's verified concordance.

### B11. Septuagint texts
| Source | URL | License position |
|--------|-----|------------------|
| CCAT / CATSS morphological Rahlfs | http://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/ (user declaration file `0-user-declaration.txt`; the fetch failed on a TLS certificate error, so its wording is cited secondhand) | Restrictive: users must send a signed user declaration before download; derivatives such as https://github.com/eliranwong/LXX-Rahlfs-1935 are CC BY-NC-SA 4.0. The vault's register records "Copyrighted; free non-commercial distribution". |
| Swete (First1KGreek / OGL) | https://github.com/nathans/lxx-swete ; https://github.com/OpenGreekAndLatin/septuagint-dev ; https://github.com/eliranwong/LXX-Swete-1930 | Swete's edition is public domain; the First1KGreek digitization is CC BY-SA 4.0. ~~Morphology tagging work exists in the eliranwong repo.~~ *Corrected 2026-10-06 (12-SEPTUAGINT-SOURCE.md):* no openly licensed Swete morphology exists. The eliranwong repo has none, and the license of its Greek text is unanswered. The recommended base is First1KGreek TEI (`data/tlg0527`, CC BY-SA 4.0), which needs repair passes (Ecclesiastes missing; 11 lost chapter openings; merged verses; ~74 errors in 56 sampled Genesis verses). |

**Relevance:** 95%. The LXX choice is open question Q-1 for Larry.

### B12. Catalog: awesome-biblical-data (Nida Institute)
URL: https://github.com/nida-institute/awesome-biblical-data. A curated, machine-readable catalog (resources.json) of open biblical datasets. It lists Abbott-Smith (PD), Dodson Greek Lexicon (PD), Strong's (openscriptures/strongs, PD), BDB (BibleAquifer, CC0), Byzantine RP2018 (byztxt, PD) and the items above. **Relevance:** 70%, as the acquisition checklist for the distribution build.

---

## C. Commercial References (feature comparison only)

### C1. Logos (Faithlife)
| Aspect | Assessment |
|--------|------------|
| URL | https://www.logos.com/ ; https://en.wikipedia.org/wiki/Logos_Bible_Software |
| Model | Subscription since October 2024 (Premium, Pro, Max), updates about every six weeks; free app with limited features |
| Platforms | Windows, macOS, iOS, iPadOS, Android, web |
| AI | Smart Search (natural-language library query), Study Assistant ("cited answers from an AI Bible tool drawn from books you trust"), AI Summarize, Sermon Builder |

**Lesson:** The market leader puts AI in the answer path, with citations. simple_bible inverts this: the engine answers, and AI may only phrase an engine result.

### C2. Accordance 14
| Aspect | Assessment |
|--------|------------|
| URL | https://www.accordancebible.com/accordance-14/ (403 to the fetcher); feature list fetched from https://www.accordancefiles1.com/helpfiles/14-Win/win14/content/topics/01_welcome_help/new_v_14.htm |
| Platforms | Windows, macOS, iOS, iPadOS, Android |
| Features | Dynamic Word Study (word info, text comparisons, graphs, lexicons), phrasing for discourse structure, user tools, Ketiv/Qere handling |

**Lesson:** Dynamic Word Study is the commercial benchmark for our range viewer ("every attested sense with supporting verses, laid out before any ruling").

---

## D. Enabling Technology

### D1. SQLite FTS5
URL: https://www.sqlite.org/fts5.html. Tokenizers: unicode61 (default), ascii, porter, trigram. **Two findings that shape the design:**
1. unicode61's default token categories are **"L* N* Co"**, so **nonspacing marks (Mn) are separators**. Pointed Hebrew (niqqud, cantillation) and decomposed Greek accents would be split mid-word unless the `categories` option adds Mn or the indexed column is pre-normalized.
2. `remove_diacritics` acts on **Latin script only** ("diacritics are removed from all Latin script characters"). Greek accents and breathings are not removed.
**Consequence:** Index a normalized `plain` column (consonantal Hebrew with final forms folded; Greek lowercased with accents and breathings stripped), the approach the vault's `bible_search.db` already proved (250x speed-up, prefix search working, per memory note). Also: trigram tokenizer since 3.34.0 (https://sqlite.org/releaselog/3_34_0.html); contentless-delete since 3.43.0; STRICT tables since 3.37.0; `->>` since 3.38.0; built-in math since 3.35.0 (https://www.sqlite.org/changes.html). Latest SQLite: 3.53.4 (2026-07-24).

### D2. sqlite-vec
| Aspect | Assessment |
|--------|------------|
| URL | https://github.com/asg017/sqlite-vec ; releases https://github.com/asg017/sqlite-vec/releases |
| Status | Pre-v1 ("expect breaking changes"); latest stable v0.1.9 (2026-03-31); v0.1.10-alpha.4 (2026-05-18) adds experimental DiskANN |
| License | Apache-2.0 / MIT dual |

Pure C, no dependencies, Windows supported; float32, int8 and binary vectors in `vec0` virtual tables with KNN by `MATCH`. **It cannot be loaded into our current SQLite build**, which is compiled with `SQLITE_OMIT_LOAD_EXTENSION`; it would have to be compiled into the amalgamation. For about 31,000 verses x 384 dimensions (about 47 MB as float32) a brute-force scan is fast enough, and simple_sql already has `SIMPLE_SQL_VECTOR_STORE`. See D-008.

### D3. llama.cpp / GGUF
| Aspect | Assessment |
|--------|------------|
| URL | https://github.com/ggml-org/llama.cpp |
| License | MIT |
| Notes | Plain C/C++; AVX/AVX2/AVX512/AMX on x86; 1.5 to 8-bit quantization; Vulkan and other backends; `llama-server` with an OpenAI-compatible API; prebuilt binaries |

Already in use: `simple_rixqwen` spawns `llama-server.exe` hidden on 127.0.0.1 and talks to `/v1/chat/completions`. Design doc §5 measured 20.5 tokens/s generation and 143 tokens/s prompt reading with a 3B Q4 model on 4 CPU threads (this machine is an upper bound).

### D4. ONNX Runtime and embedding models
- `simple_onnx` wraps the ONNX Runtime C API (bundled `onnxruntime-win-x64-1.17.3`) and includes `ONNX_TOKENIZER`, a pure-Eiffel SentencePiece unigram tokenizer (vocabulary file format id/piece/score; built for MarianMT).
- Candidate: **intfloat/multilingual-e5-small**, https://huggingface.co/intfloat/multilingual-e5-small : MIT, 384 dimensions, 512-token max, 101 languages including Hebrew (he) and Greek (el), requires "query: " / "passage: " prefixes. Its tokenizer is the XLM-R SentencePiece model, so the existing unigram tokenizer is a plausible fit (to verify, A-6).
- Model selection belongs to `Rix/Data/_Small Model Survey (2026-10-06).md` (**pending**; not present when this research ran).

### D5. Microsoft Edge WebView2 Runtime
URL: https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution. Evergreen Runtime is part of Windows 11; "the vast majority of Windows 10 devices have the WebView2 Runtime installed already." Recommended: detect via the `pv` registry value or `GetAvailableCoreWebView2BrowserVersionString`, then run the about 2 MB bootstrapper (online) or the standalone installer (offline) with `/silent /install`. `WebView2Loader.dll` must ship with the app or be statically linked. Fixed Version adds over 250 MB.

### D6. sql.js (for the PWA)
URL: https://github.com/sql-js/sql.js. MIT. SQLite compiled to WebAssembly; **the whole database lives in memory**; FTS5 not confirmed in the default build. A 400 to 700 MB core database is not a PWA candidate; the PWA needs its own slim build.

### D7. Inno Setup
URL: https://jrsoftware.org/isinfo.php. Free; supports Windows 11/10, x64 and Arm64, LZMA2, right-to-left languages in the wizard, silent install, Pascal scripting. "Commercial users are requested to purchase a commercial license", which does not apply to a free tool. Already used for RixQwen and the BibleREPL installer (`simple_scholar/installer/bible_repl.iss`).

---

## Eiffel Ecosystem Check

*Verified by listing `D:\prod` and reading each README on 2026-10-06.*

### ISE Libraries
- **EiffelBase / WEL**: always used; WEL for Win32 calls where simple_* has no wrapper.
- **ISE sqlite library**: superseded by `eiffel_sqlite_2025` (see the finding below).
- **EiffelWeb**: underlies `simple_web`; not used directly.
- **ISE i18n**: wrapped by `simple_i18n` if the UI is localized later.
- **Vision2**: not used (simple_scholar's `bible_gui` target was a Vision2 stub).

### simple_* Libraries
| Library | Status (README) | Use in simple_bible |
|---------|-----------------|---------------------|
| simple_sql | Production; FTS5 (BM25, Boolean, highlight), JSON1, BLOB, migrations, `SIMPLE_SQL_VECTOR` / `SIMPLE_SQL_VECTOR_STORE` (KNN, cosine) | **Core.** All data access |
| eiffel_sqlite_2025 | README says SQLite 3.51.1; **compiled library is 3.31.1** (see finding) | Core, after upgrade |
| simple_browser | Development; WebView2 backend; ships `webview.dll`, `WebView2Loader.dll` | **Primary UI** host |
| simple_htmx | Fluent HTML/HTMX builder | Primary UI pages |
| simple_web | Production; SCOOP-clean HTTP server | Local server behind the WebView2 face |
| simple_alpine | Fluent Alpine.js attribute builder extending simple_htmx | Optional UI interactivity |
| simple_template | Mustache templates with auto-escaping | UI pages, credits file |
| simple_json | Production v1.0.0, JSON Schema | Config, data import, API to UI |
| simple_onnx | Production v1.0.0; ONNX Runtime 1.17.3; SentencePiece tokenizer | L3 query embedding |
| simple_rixqwen | llama-server spawn and chat pattern | L3 optional chat (pattern or dependency) |
| simple_ai_client | Ollama, Claude API, Claude Code CLI, OpenAI providers; embeddings | L3 bring-your-own-key; build-time precompute |
| simple_winhttp | WinHTTP client; "libcurl.dll ships only inside an EiffelStudio installation" so `simple_http` cannot run on a customer machine | Any network call in the shipped app (BYOK, update check) |
| simple_http | Production; libcurl-based | Build machine only |
| simple_process | Production v1.0.1; SCOOP-safe process execution | Spawning llama-server; build scripts |
| simple_cli | Production; flags, subcommands, help | `bible.exe` CLI |
| simple_console / simple_tui | Production / Phase 2 | REPL and optional TUI |
| simple_regex | Wraps Gobo PCRE | Reference parsing, checks |
| simple_zstring / simple_encoding | Production; Unicode strings, UTF-8 | Hebrew/Greek text handling, normalization |
| simple_file / simple_config / simple_env / simple_logger | Production | Paths, settings, diagnostics |
| simple_csv / simple_xml | Production | Build-time import (TSV, OSIS XML) |
| simple_hash | SHA-256 | Database and model-file integrity checks |
| simple_shaping | **0.1.0 pre-release, Phase 4 in progress**: DirectWrite bidi, itemization, glyph shaping and font fallback are real | Future native Hebrew surface (not MVP) |
| simple_widgets | Drawn Win32 toolkit | Future native face, after simple_shaping |
| simple_testing | Production v1.0.0 | Test suites |
| simple_graph / simple_linalg / simple_ml | Production | Related-passage graph; vector math if needed |
| simple_markdown / simple_pdf | Production | Export of results (later) |
| simple_kb | FTS5 knowledge base app | Reference implementation of an FTS5 app in the fleet |
| simple_langchain | Design only, no implementation | Not used |
| simple_setup | Deprecated (superseded by simple_pkg) | Not used |

### Gobo Libraries
- Gobo (https://github.com/gobo-eiffel/gobo, MIT; supports ISE Eiffel 25.12 and Gobo compiler 26.09.03; `D:\prod\gobo-26.06` present): Regexp (via simple_regex), XML/XPath (via simple_xml, for OSIS and TEI imports), Kernel/Structure/String utilities. No direct Gobo dependency is planned beyond what simple_* wraps.

### Key Findings From the Ecosystem Check
1. **The SQLite actually compiled is 3.31.1.** `eiffel_sqlite_2025/Clib/sqlite3.h` and the compiled `spec/msvc/win64/lib/sqlite_2025.lib` both carry source id `2020-01-27 19:55:54 3bfa9cc9...` (3.31.1). The README and CHANGELOG claim 3.51.1. Compile options embedded in the library: FTS5, JSON1, RTREE, GEOPOLY, COLUMN_METADATA, OMIT_LOAD_EXTENSION. The math-functions flag has no effect below 3.35.0. This is a fleet-level drift, not a simple_bible defect, but simple_bible depends on it.
2. **The "no text-shaping library exists" premise is out of date.** `simple_shaping` exists at 0.1.0 pre-release with real DirectWrite bidi and shaping. The MVP still uses WebView2; the native path is now "pending release", not "blocked on nonexistence".
3. **`simple_http` cannot be the network client in a shipped app** (libcurl dependency); `simple_winhttp` exists for exactly this.
4. **simple_scholar** (`D:\prod\simple_scholar`) has seven targets including `bible_htmx` (WebView2) and `bible_repl`, ships a February `data/bible.db` (161 MB, pre-split, no MACULA, no Westcott-Hort), and carries Larry-specific lenses (`SCHOLAR_FRAME_*`, `KACC_VALIDATOR`). Harvest decisions: `08-HARVEST-LEDGER.md`.

### Gap Analysis
Not available in Eiffel (or anywhere free): a deterministic Bible-study engine with pre-registered censuses, controls, near-miss reporting and versification-safe cross-version pairing. Not available in the Eiffel fleet: a vector index inside SQLite (only brute-force `SIMPLE_SQL_VECTOR_STORE`), a WordPiece/BPE tokenizer beyond SentencePiece unigram, a current SQLite build.

---

## Comparison Matrix

| Feature | STEP | e-Sword / theWord | Bible Analyzer | Text-Fabric / BHSA | Logos | Accordance | Our Need |
|---------|------|-------------------|----------------|--------------------|-------|------------|----------|
| Free | ✓ | ✓ | ✓ (core) | ✓ (NC data) | ✗ | ✗ | MUST |
| Windows install, no setup skills | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | MUST |
| Works offline | ✓ | ✓ | ✓ | ✓ | partial | ✓ | MUST |
| Hebrew/Greek morphology concordance | ✓ | modules | ✓ | ✓ | ✓ | ✓ | MUST |
| Versification-safe MT/LXX/English pairing | partial (TVTMS) | ✗ | ✗ | ✗ | ✓ | ✓ | MUST |
| Pre-registered census with controls | ✗ | ✗ | ✗ | by hand | ✗ | ✗ | MUST |
| FITS/PARTIAL/FAILS/NO_DATA together | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | MUST |
| Provenance per row + generated credits | ✗ | ✗ | ✗ | partial | ✗ | ✗ | MUST |
| NT quotation agreement MT vs LXX | ✗ | ✗ | ✗ | ✗ | partial | partial | SHOULD |
| Semantic search | ✗ | ✗ | ✗ | ✗ | ✓ (AI) | ✗ | SHOULD |
| AI never a source of fact | n/a | n/a | n/a | n/a | ✗ (AI answers) | n/a | MUST |
| Open data, all shipped texts openly licensed | ✗ (ESV/NIV) | mixed | mixed | ✗ (NC) | ✗ | ✗ | MUST |

## Patterns Identified

| Pattern | Seen In | Adopt? |
|---------|---------|--------|
| Module/plug-in resources loaded when present | SWORD, e-Sword, theWord | YES (private plug-in for Larry's data) |
| Normalized search column beside the display text | vault `bible_search.db`, Text-Fabric | YES |
| Versification rules as data, not code | STEPBible TVTMS, Copenhagen Alliance | YES |
| Corpus as annotated graph (nodes, features, edges) | Text-Fabric | PARTIAL (relational tables, graph only where needed) |
| Hit chart across books/chapters | Bible Analyzer | YES (census results view) |
| Dynamic word study pane | Accordance 14 | YES (range viewer) |
| AI answer with citations | Logos Study Assistant | NO (AI may only phrase engine output) |
| Precompute heavy work, ship as data | design doc L2 | YES |
| Quarantine table instead of deletion | vault defect register | YES |

## Build vs Buy vs Adapt

| Option | Effort | Risk | Fit |
|--------|--------|------|-----|
| Build simple_bible clean, harvesting simple_scholar | HIGH | MED | 90% |
| Adopt an existing app (STEP desktop, Xiphos) | LOW | HIGH (cannot add census discipline; GPL or closed; licensed texts) | 30% |
| Adapt simple_scholar in place | MED | HIGH (Larry-specific lenses, stale DB fork, six months dormant, unverified compile) | 55% |

**Initial Recommendation:** BUILD (clean project, decided by Larry, D-001), adopting open datasets wholesale and harvesting simple_scholar's proven classes per `08-HARVEST-LEDGER.md`.
