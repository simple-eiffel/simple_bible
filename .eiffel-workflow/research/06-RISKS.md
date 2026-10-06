# RISKS: simple_bible

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| RISK-001 | Compiled SQLite is 3.31.1, not the 3.51.1 the README claims; newer features unavailable; fleet upgrade could break dependents | HIGH (already true) | MED | D-007 fleet upgrade with full regression; spec assumes only 3.31.1 features until it lands |
| RISK-002 | FTS5 mishandles Hebrew marks and Greek accents (Mn = separator by default; diacritic removal is Latin-only) | HIGH (if unaddressed) | HIGH | D-009 normalized search columns; shared idempotent normalizer; test corpus of pointed and polytonic forms |
| RISK-003 | A shipped source turns out not to be redistributable (Rahlfs/CCAT, MorphGNT SA, MACULA Hebrew components, fonts) | MED | HIGH | License gate (FR-004); D-011 Swete default; provenance per row; written permission where needed |
| RISK-004 | Versification errors produce plausible wrong pairings | MED | HIGH | D-010 mapping as data; precondition requires mapped refs; regression suite from defect register B1 to B4 |
| RISK-005 | Data contamination reappears from upstream re-imports (class A defects) | MED | HIGH | Build rules carry the A1 fix; content-anchor checks (first/middle/last verse per chapter vs. a second witness) on every import |
| RISK-006 | Small models mangle Hebrew/Greek or invent facts | HIGH | MED | D-004; AI never a source; FR-053 post-check; labeled output; AI deferred from Release 1 |
| RISK-007 | Embedding model gives weak Hebrew/Greek retrieval | MED | MED | Lemma-based related passages do not depend on embeddings; survey must test Hebrew and Greek queries |
| RISK-008 | simple_scholar's `bible_htmx` and other harvested code no longer compile | MED | LOW | One-day spike first (design doc §8.1); harvest is copy-and-adapt, not link |
| RISK-009 | WebView2 Runtime missing or blocked on some Windows 10 machines | LOW | HIGH | Installer detects the `pv` registry value and runs the bundled Evergreen standalone installer silently |
| RISK-010 | Low-memory laptops (8 GB) thrash with the AI edition | MED | MED | Core edition default; AI edition warns below 16 GB; smallest models only on 8 GB |
| RISK-011 | Scope creep from Larry's research needs into the public tool | HIGH | MED | Private plug-in seam (D-014); public requirements list is the gate |
| RISK-012 | The PWA path (sql.js loads the whole DB into memory) is unusable at 400 to 700 MB | HIGH | LOW | PWA deferred; slim database if pursued |
| RISK-013 | Share-alike obligations missed on derived tables | MED | MED | Provenance records SA; derived-table license computed from inputs |
| RISK-014 | Single maintainer (Larry plus AI agents); bus factor | HIGH | MED | Spec Kit artifacts, README/docs per fleet rule, reproducible build scripts |
| RISK-015 | sqlite-vec API churn (pre-v1) if adopted early | MED | LOW | D-008 defers it; brute force suffices at verse scale |
| RISK-016 | Edition-omitted verses read as data errors (empty strings) | MED | LOW | FR-009 explicit omission markers |
| RISK-017 | Gloss column treated as meaning (defect E7: gloss disagrees with Strong's in one row) | MED | MED | Glosses labeled as orientation only; census and concordance never key on gloss |

## Technical Risks

### RISK-001: SQLite version drift in eiffel_sqlite_2025
**Description:** `Clib/sqlite3.h` defines `SQLITE_VERSION "3.31.1"`; the compiled `spec/msvc/win64/lib/sqlite_2025.lib` carries source id `2020-01-27 19:55:54 3bfa9cc9...`; README and CHANGELOG claim 3.51.1. Compile options in the library: FTS5, JSON1, RTREE, GEOPOLY, COLUMN_METADATA, OMIT_LOAD_EXTENSION.
**Likelihood:** HIGH (verified 2026-10-06).
**Impact:** MEDIUM. No trigram tokenizer (3.34.0), STRICT tables (3.37.0), `->>` (3.38.0), built-in math (3.35.0), contentless-delete (3.43.0); five years of fixes missing; extension loading impossible.
**Indicators:** `select sqlite_version()` returns 3.31.1; SQL using newer syntax fails at prepare time.
**Mitigation:** Replace the amalgamation with the current release (3.53.4 as of 2026-07-24), rebuild with the same flags, run fleet SQL tests; correct the README.
**Contingency:** Stay on 3.31.1 and design around it (all MUST requirements are achievable with FTS5 unicode61 plus normalized columns).

### RISK-002: Hebrew and Greek search correctness
**Description:** unicode61 default categories "L* N* Co" make combining marks separators; `remove_diacritics` covers Latin script only; MapM uses deliberate NBSP before paseq; `macula_hebrew.greek` writes chi as xi (E8).
**Likelihood:** HIGH if unaddressed.
**Impact:** HIGH. Silent near-zero results look like evidence of absence.
**Indicators:** Searches for pointed forms return fragments; Greek accented and unaccented queries disagree.
**Mitigation:** D-009; FR-024 key joins only; a search test corpus built from the defect register's traps.
**Contingency:** Custom FTS5 tokenizer in C (heavier; only if normalization proves insufficient).

### RISK-003: Licensing
**Description:** CCAT/CATSS Rahlfs requires a signed user declaration; derivatives are CC BY-NC-SA. MorphGNT's README says its morphology is CC BY-SA (the vault records CC BY 4.0). MACULA Hebrew mixes components with separate terms. Byz, SP, TgN and TgW editions are unrecorded. STEPBible's TTESV contains the ESV.
**Likelihood:** MEDIUM. **Impact:** HIGH (a takedown or a rebuild).
**Mitigation:** D-002 license gate; D-011 Swete default; read each LICENSE file at pin time and store its text hash in the manifest; exclude TTESV.
**Contingency:** Drop or replace the source; the pipeline makes rebuilding cheap.

### RISK-006: AI errors
**Description:** Small chat models make mistakes, especially in Hebrew and Greek (design doc §9).
**Mitigation:** AI never sees a question without an engine result; short contexts; post-check; labels; off by default on low memory.
**Contingency:** Remove the explain feature; nothing else depends on it.

## Ecosystem Risks
- **Fleet coupling:** simple_bible depends on simple_sql, simple_browser, simple_web, simple_htmx, simple_onnx, simple_process, simple_winhttp. Changes there ripple (fleet rule: check downstream dependents after a library change).
- **libcurl trap:** `simple_http` needs libcurl.dll, which ships only inside EiffelStudio; any shipped network code must use `simple_winhttp` (C-009).
- **ONNX Runtime 1.17.3** bundled in simple_onnx is not current; a newer embedding model may need a newer runtime.
- **simple_shaping** is pre-release; the native face must not be scheduled against it.
- **WebView2 Evergreen** updates under the app; feature-detect newer APIs.
- **Upstream data repos** change; pin by commit or release and hash.

## Resource Risks
- **Data engineering dominates:** the distribution build (import, normalize, map, verify, credit) is larger than the engine code. Schedule it as its own Spec Kit phase.
- **Larry's time** is the gate for D-011, D-016, D-019 and license correspondence (CATSS).
- **Build machine dependency:** precompute needs Larry's RTX machine; document so another machine can reproduce.
- **Testing on target hardware:** need a real 8 GB, 4-core, DDR4 Windows laptop (or VM with capped resources) for NFR checks; Larry's machine is an upper bound (DDR5-5600 dual channel).
