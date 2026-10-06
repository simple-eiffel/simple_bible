# 08 — HARVEST LEDGER: simple_scholar → simple_bible

**Date:** 2026-10-06
**For:** Larry Rix
**Status:** OPEN. simple_scholar may be retired and archived only when every box in §6 is ticked.
**Decision this serves:** D-001 (04-DECISIONS.md). Start a clean `simple_bible`; retire, then archive, `D:\prod\simple_scholar` once simple_bible has everything it needs from it. This ledger turns "has everything it needs" into a checkable list.
**Inputs read:** `Rix/Upcoming Projects/Bible Study Workbench - Design (2026-10-06).md` (§3, §4, §7); `Rix/Data/_Text Credits (paste-ready).md`; 04-DECISIONS.md D-001, D-005, D-008, D-014 to D-020 in this folder; the simple_scholar tree, ECF and git history; the installed BibleREPL footprint; `D:\prod\bible_pwa`.
**Method:** Read-only. Nothing in simple_scholar was modified, built or run. No windows were opened. Databases were opened with SQLite `mode=ro`. EIFGENs contents were skipped.

**Classes used (each item gets exactly one):**

| Class | Meaning |
|---|---|
| **HARVEST-AS-IS** | Move to simple_bible with minimal change |
| **HARVEST-REWRITE** | The idea or behavior is needed; the code is rewritten (reason given) |
| **PRIVATE-PLUGIN** | Larry's frameworks, or access to scholars.db / transcripts.db / primary_evidence.db / podcast material. Goes to the private plug-in (D-014), never the shipped core |
| **ARCHIVE-ONLY** | Kept in the archive for history or as prior art; not needed by simple_bible |
| **DROP** | Obsolete, generated, or superseded; nothing to keep |

**The "Landed" column** is the checklist. Tick it with the simple_bible (or plug-in) commit hash when the item lands and its tests pass. ARCHIVE-ONLY and DROP rows have no box; they are satisfied by the archive procedure (§8).

---

## 0. Summary

| Class | Rows |
|---|---:|
| HARVEST-AS-IS | 9 |
| HARVEST-REWRITE | 56 |
| PRIVATE-PLUGIN | 27 |
| ARCHIVE-ONLY | 104 |
| DROP | 28 |
| **Total** | **224** |

**Biggest harvest items:** the generic two-fifths of `SCHOLAR_BIBLE` (verse lookup, reference parsing, book resolution, word-level Strong's, cross-references, proper names, edit distance; about 1,150 of its 3,890 lines); the core of `BIBLE_REPL` (the REPL loop, config and data-directory logic, lexicon, transliteration, cross-reference and name commands, one-shot mode; about 2,100 of its 5,698 lines); the `bible_htmx` WebView2 face (7 of 12 classes plus the untracked `bin/style.css`); the Inno Setup script; and seven Python importers that become reference implementations for Eiffel ports under D-020.

**Private plug-in:** the five frame lenses, the three KACC classes, `GAP_DETECTOR`, the corpus three-fifths of `SCHOLAR_BIBLE` and the matching REPL commands, five HTMX tabs, five TUI tabs, two tests, the cuneiform font, and the seeder for Larry's 134 sourced ANE glosses.

**At risk before archiving (§2):** two commits that exist only on the branch `wip/uncommitted-2026-09-02`; about 15 untracked-but-unique files (including the HTMX stylesheet, which is source code that git ignores); and the only built copy of the February "enriched" database, which holds tables the vault never received.

---

## 1. Corrections to the record

Facts from memory (verified 2026-08-28) and from the design doc, re-checked today. Where they differ, this ledger uses today's reading.

1. **`S05-VERDICTS.md` is not in simple_scholar.** It is `D:\prod\simple_widgets\specs\S05-VERDICTS.md`. simple_scholar has no `specs/` folder; its specification lives in `.eiffel-workflow/spec/` (9 files).
2. **Several "core" classes are stubs.** Their bodies are comments ("-- Implementation: ..."), and their tests pass vacuously. `RANK_FUSION` returns an empty list. `KACC_VALIDATOR` returns a neutral result. `SCHOLAR_BERT_EMBEDDER` returns a zero vector. `SCHOLAR_EMBEDDER`, `SCHOLAR_INFERENCE_TIER`, `SEARCH_AGGREGATOR` and the three web-search workers are stubs. The design doc's "keep the search, ranking and fusion classes" and "the ONNX/embedding plumbing" therefore keep ideas, not working code.
3. **There is no working embedding code.** `SCHOLAR_ONNX_ENGINE` is a working ONNX engine, but for Opus-MT machine translation (Hebrew/Greek → English), not embeddings. Ollama appears only in `BIBLE_REPL` (translation fallback and the `/research` agent), through `SIMPLE_AI_QUICK`.
4. **`bible_gui` is not a stub.** The 207-line figure was the root class only. The `gui/` cluster is 14 classes and 5,432 lines of Vision2. It is archived because Vision2 cannot shape right-to-left text, not because it is empty.
5. **Eiffel totals:** 106 classes, 32,659 lines (src 39 / 10,669; cli 16 / 7,440; gui 14 / 5,432; htmx 12 / 3,965; tui 9 / 3,278; test 16 / 1,875). Tests: 84 test features in 15 test classes (Phase 6 evidence 2026-02-20: "84 passed, 0 failed").
6. **There are three different February bible.db files, not one.** See §3.8. The richest (213 MB) is not in the repository at all.
7. **The repository copy `data/bible.db` labels all 15 versions' license as "MIT".** That is wrong for every one of them, and the file carries Naked Bible Podcast transcripts (copyrighted). It must never ship.
8. **Provenance flag for the vault, found during this inventory.** `primary_evidence.db`'s `dss_manuscripts` / `dss_bible_links` / `dss_entity_links` were imported from bible_pwa on 2026-08-14. They were produced by `scripts/import_dss.py` ("via Claude API ... using Claude Sonnet") and `scripts/import_dss_local.py` ("No API calls - all data generated from Claude's knowledge"). They are machine-generated, not sourced. The 2026-08-14 consolidation note flagged only `ane_text_bible_links` as machine-assigned. The DSS rows belong under the same flag (P4 until sourced).
9. **The installed BibleREPL is v1.7.0** (Feb 15) in `C:\Program Files\BibleREPL\`, on the user PATH. The PATH also carries a stale entry for `%LOCALAPPDATA%\Programs\BibleREPL`, which does not exist.
10. **The GitHub repository `simple-eiffel/simple_scholar` is PRIVATE**, has no releases, and is not archived.

---

## 2. Git state and at-risk work (preserve before archiving)

**Branches:**

| Ref | Commit | State |
|---|---|---|
| `wip/uncommitted-2026-09-02` (**HEAD**) | `2f939b2` 2026-09-11 "Class invariants are O(1): model clauses removed" | Pushed to origin. **Two commits ahead of master.** |
| `master` = `origin/master` | `17f8e14` 2026-02-20 "Fix TUI detail view segfaults and add Phase 6 adversarial tests" | Last feature commit |
| `refs/original/refs/heads/master` | `636e090` | Local-only `git filter-branch` backup of the pre-rewrite history. `git diff 636e090 17f8e14` is empty (tip trees identical). |

No tags. No stashes. Working tree clean. 316 tracked files. Loose objects 84.5 MiB, no packs.

**Log (`--oneline -15`, all of it):**

```
2f939b2 Class invariants are O(1): model clauses removed
7916fad WIP found uncommitted on 2026-09-02: export_to_obsidian.py (dated 2026-03-06); preserved on a branch
17f8e14 Fix TUI detail view segfaults and add Phase 6 adversarial tests
930af0c v2.0.0: Add Bible TUI, HTMX web app, PWA, and source scripts
7f02901 v1.9.0: Bible GUI, expanded REPL, guide update
6e777e0 Fill all 71 pseudepigrapha scaffolds + add 8 angelology texts
abf6211 Initial commit: simple_scholar with complete Traced dataset (16 episodes)
```

**Branch-only work (on `wip/...`, not on master):**

| Commit | Content | Harvest note |
|---|---|---|
| `7916fad` | `scripts/export_to_obsidian.py` (307 lines; dated 2026-03-06) | ARCHIVE-ONLY (row SC-27) |
| `2f939b2` | `src/sparse_vector.e`, `src/scholar_index.e`, `src/scholar_graph.e`: MML model clauses removed from invariants (O(1) invariants) | **Harvest these three from the wip branch, not from master.** |

**Untracked but unique (ignored by `.gitignore`, so a git-only archive loses them):**

| Path | Size | What | Class |
|---|---:|---|---|
| `bin/style.css` | 8 KB | **The HTMX face's stylesheet.** Source code, but `bin/` is ignored. `BIBLE_HTMX_APP` loads it at run time. | HARVEST-AS-IS (row H-13) |
| `plans/data-enrichment-plan.txt` | 21 KB | The February enrichment plan (Steps 1A–3) | ARCHIVE-ONLY |
| `scripts/*.json` (9 files) and `scripts/_*_candidates.txt`, `_candidates_dump.txt` | 14.2 MB | Intermediate dumps and candidate lists from the enrichment runs | ARCHIVE-ONLY |
| `scripts/sources/dionysius_works.pdf`, `fbe.txt`, `fbe.txt.gz`, `pseudepigrapha_charles.txt`, `texts/download_grimoires.py` | see §3.9 | Downloaded source texts and one untracked downloader | ARCHIVE-ONLY |
| `nakedbiblepodcast.db` | 38.6 MB | Podcast corpus DB (already migrated into scholars.db) | ARCHIVE-ONLY |
| `%LOCALAPPDATA%\BibleREPL\data\bible.db` (= `D:\prod\bible_pwa\bible.db`, byte-identical) | 213 MB | **The only built copy of the February enrichment** (§3.8 row D-03) | ARCHIVE-ONLY |

---

## 3. The ledger

### 3.1 ECF targets (`simple_scholar.ecf`, 7 targets)

Library dependencies of the base target: base, time, simple_ai_client, simple_datetime, simple_decimal, simple_encoding, simple_file, simple_graph, simple_http, simple_json, simple_linalg, simple_math, simple_mml, simple_onnx, simple_process, simple_regex, simple_sorter, simple_sql, simple_statistics, simple_toml, simple_web. SCOOP, full void safety. EIFGENs exist for all seven targets (contents not inspected).

| ID | Target | Root | Adds | Class | Landed |
|---|---|---|---|---|---|
| T-01 | `simple_scholar` (library) | all classes in `src/` | the 21 libraries above | HARVEST-REWRITE: becomes the `simple_bible` library target; prune unused libraries (simple_linalg, simple_statistics, simple_decimal, simple_http unless web search is kept) | [ ] |
| T-02 | `scholar_cli` | `SCHOLAR_CLI` | `cli/` | ARCHIVE-ONLY: vault-analysis REPL, superseded by the vault's four-database builders | — |
| T-03 | `simple_scholar_tests` | `TEST_APP` | simple_testing, testing, `cli/`, `test/` | HARVEST-REWRITE: becomes `simple_bible_tests` | [ ] |
| T-04 | `bible_repl` → `bible.exe` | `BIBLE_REPL` | `cli/` | HARVEST-REWRITE: becomes the simple_bible CLI (D-006 "CLI second") | [ ] |
| T-05 | `bible_gui` | `BIBLE_GUI` | simple_logger, simple_vision, vision2, `gui/` | ARCHIVE-ONLY: Vision2 cannot shape Hebrew (simple_shaping is pre-release) | — |
| T-06 | `bible_tui` | `BIBLE_TUI` | simple_logger, simple_tui, `tui/` | HARVEST-REWRITE: only if Larry keeps a TUI face (decision L-3) | [ ] |
| T-07 | `bible_htmx` | `BIBLE_HTMX_APP` | thread, simple_alpine, simple_browser, simple_htmx, simple_logger, `htmx/` | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |

### 3.2 `src/` — 39 classes (10,669 lines)

"Stub" means the feature bodies are comments. Library types used are shown in braces.

| ID | Class | Lines | Purpose | Depends on | Class | Landed |
|---|---|---:|---|---|---|---|
| S-01 | `DDG_SEARCH_WORKER` | 45 | DuckDuckGo worker. **Stub.** | SEARCH_WORKER | ARCHIVE-ONLY | — |
| S-02 | `GAP_DETECTOR` | 190 | Link prediction + co-occurrence + community bridging over the vault graph | {simple_math, simple_sorter}, SCHOLAR_GRAPH | PRIVATE-PLUGIN: a research aid over Larry's notes graph | [ ] |
| S-03 | `KACC_PILLAR_FINGERPRINT` | 108 | One KACC pillar's vocabulary fingerprint | {SIMPLE_VECTOR} | PRIVATE-PLUGIN | [ ] |
| S-04 | `KACC_VALIDATION_RESULT` | 123 | Four-pillar validation result | — | PRIVATE-PLUGIN | [ ] |
| S-05 | `KACC_VALIDATOR` | 80 | Four-pillar validator. **Stub** (returns neutral). | {SIMPLE_VECTOR}, S-03, S-04 | PRIVATE-PLUGIN (D-019 ships rix.db with frameworks; whether KACC scoring also ships is decision L-4) | [ ] |
| S-06 | `RANK_FUSION` | 59 | Reciprocal Rank Fusion. **Stub** (returns empty). | — | HARVEST-REWRITE: RRF is needed to merge FTS5, cross-reference and precomputed-neighbor rankings; about 20 lines to write | [ ] |
| S-07 | `SCHOLAR_ANALYZER` | 422 | TextRank summaries, bigrams, TF-IDF similarity, scholar comparison over vault documents | {simple_math, simple_sorter} | ARCHIVE-ONLY: prior art if rix.db "related documents" is wanted | — |
| S-08 | `SCHOLAR_BERT_EMBEDDER` | 53 | bert.cpp MiniLM wrapper. **Stub** (zero vector). | SCHOLAR_MODEL_BASE, {SIMPLE_VECTOR} | DROP: replaced by bge-m3 via simple_onnx (D-008, D-017) | — |
| S-09 | `SCHOLAR_BIBLE` (core sections) | ~1,150 | Schema, ingestion, query, lookup, reference parsing, book resolution, word-level Strong's, raw verse query, formatting, version resolution, book-id remap, cross-references (l. 2461), proper names (l. 2491), edit distance (l. 2776) | {simple_sql} | HARVEST-REWRITE: written against the February monolith and scrollmapper per-version .db files; must target `core.db` (D-015) with the versification map applied before pairing | [ ] |
| S-10 | `SCHOLAR_BIBLE` (corpus sections) | ~2,740 | Scholarly corpus/NBP (l. 1042), DDD + classification (l. 1519, 1872), ANE texts (l. 2569), Dead Sea Scrolls (l. 2644), cuneiform (l. 2819), prehistory (l. 3027), Traced (l. 3376), research corpus (l. 3707) | {simple_sql} | PRIVATE-PLUGIN: reads tables that now live in scholars.db (renamed `nbp_*`, `ddd_*`) and primary_evidence.db; queries must be rewritten for the split | [ ] |
| S-11 | `SCHOLAR_CONFIG` | 145 | Builder-style configuration (vault path, DB path, tier) | — | HARVEST-REWRITE: becomes core/ai/user DB paths + plug-in path | [ ] |
| S-12 | `SCHOLAR_DOCUMENT` | 216 | Parsed Obsidian document (title, tags, wikilinks, headers) | — | HARVEST-REWRITE: the document model for the Eiffel rix.db builder (D-019, D-020) | [ ] |
| S-13 | `SCHOLAR_EMBEDDER` | 114 | Tier router for embeddings. **Stub.** | {simple_math, SIMPLE_VECTOR} | DROP: D-008 / D-013 design this fresh | — |
| S-14 | `SCHOLAR_ENTITY` | 58 | Regex-extracted named entity | — | ARCHIVE-ONLY | — |
| S-15 | `SCHOLAR_FRAME_ANCIENT` | 196 | Ancient-sources lens | SCHOLAR_FRAME_BASE | PRIVATE-PLUGIN | [ ] |
| S-16 | `SCHOLAR_FRAME_BASE` | 228 | Deferred lens base | {simple_sql} | HARVEST-REWRITE: becomes the D-014 deferred "lens" seam; the public build ships the deferred class and no effective lens | [ ] |
| S-17 | `SCHOLAR_FRAME_DNP` | 157 | Divine-name-pattern lens | S-16 | PRIVATE-PLUGIN | [ ] |
| S-18 | `SCHOLAR_FRAME_PODCAST` | 184 | Naked Bible Podcast lens | S-16 | PRIVATE-PLUGIN | [ ] |
| S-19 | `SCHOLAR_FRAME_REGISTRY` | 102 | Lens registry and dispatch | S-16 | HARVEST-REWRITE: becomes the plug-in registry (D-014) | [ ] |
| S-20 | `SCHOLAR_FRAME_RILLERA` | 150 | Rillera sacrificial-system lens | S-16 | PRIVATE-PLUGIN | [ ] |
| S-21 | `SCHOLAR_FRAME_WALTON` | 151 | Walton Genesis 1 lens | S-16 | PRIVATE-PLUGIN | [ ] |
| S-22 | `SCHOLAR_GRAPH` | 635 | Knowledge graph, PageRank, communities, shortest path. **Take the wip-branch version.** | {simple_math, simple_sorter}, simple_graph | HARVEST-REWRITE: built over vault wikilinks; re-aim it at the cross-reference / shared-lemma graph for related-passage precompute (L2) | [ ] |
| S-23 | `SCHOLAR_INDEX` | 248 | TF-IDF matrix and vocabulary. **Take the wip-branch version.** | {simple_math}, S-39 | HARVEST-REWRITE: Re-aim at rare-lemma weighting over verses | [ ] |
| S-24 | `SCHOLAR_INFERENCE_TIER` | 71 | Probe for embedded runtime / Ollama. **Stub.** | — | HARVEST-REWRITE: the capability probe that keeps AI off on low-memory machines (design §2, §5) | [ ] |
| S-25 | `SCHOLAR_MODEL_BASE` | 58 | Deferred model load/unload lifecycle | — | HARVEST-AS-IS | [ ] |
| S-26 | `SCHOLAR_ONNX_ENGINE` | 414 | Working ONNX Runtime engine for Opus-MT translation | {simple_onnx}, S-25 | HARVEST-REWRITE: Keep the session and tokenizer plumbing for bge-m3 (build-time, then query-time); drop the translation use (D-004) | [ ] |
| S-27 | `SCHOLAR_PARSER` | 592 | Obsidian markdown parser (title, tags, wikilinks, headers, code-block stripping) | S-12 | HARVEST-REWRITE: the parser for the Eiffel rix.db builder port, checked by differential test against the Python builder (D-020) | [ ] |
| S-28 | `SCHOLAR_QUERY` | 115 | Query with facet filters | — | HARVEST-REWRITE: Facets become version / testament / book / voice | [ ] |
| S-29 | `SCHOLAR_RESULT` | 112 | Ranked result set | {simple_sorter} | HARVEST-REWRITE: Results must carry provenance (source DB, voice label) | [ ] |
| S-30 | `SCHOLAR_SEARCH` | 155 | Query processing; Levenshtein | — | HARVEST-REWRITE: Fuzzy book/term matching survives; assembly over the old store does not | [ ] |
| S-31 | `SCHOLAR_STORE` | 416 | SQLite persistence for the vault corpus | {simple_sql, SIMPLE_VECTOR} | ARCHIVE-ONLY: superseded by the docs / verse_refs / docs_fts schema | — |
| S-32 | `SEARCH_AGGREGATOR` | 87 | SCOOP scatter-gather web search. **Stub.** | S-33, S-34, S-35 | ARCHIVE-ONLY (decision L-5) | — |
| S-33 | `SEARCH_RESULT_BUFFER` | 86 | SCOOP shared result buffer | — | ARCHIVE-ONLY (L-5) | — |
| S-34 | `SEARCH_TIMEOUT_MONITOR` | 45 | SCOOP timeout watchdog | — | ARCHIVE-ONLY (L-5) | — |
| S-35 | `SEARCH_WORKER` | 34 | Deferred web-search worker | — | ARCHIVE-ONLY (L-5) | — |
| S-36 | `SEARXNG_SEARCH_WORKER` | 57 | SearXNG worker. **Stub.** | S-35 | ARCHIVE-ONLY (L-5) | — |
| S-37 | `SERPER_SEARCH_WORKER` | 58 | Serper worker. **Stub.** | S-35 | ARCHIVE-ONLY (L-5) | — |
| S-38 | `SIMPLE_SCHOLAR` | 602 | Facade over the vault-corpus pipeline (partly stubbed) | most of src | ARCHIVE-ONLY: simple_bible gets its own facade | — |
| S-39 | `SPARSE_VECTOR` | 161 | Sparse TF-IDF vector. **Take the wip-branch version.** | {simple_math} | HARVEST-AS-IS | [ ] |
| S-40 | `WEB_PROVENANCE` | 52 | Provenance record for web results | — | ARCHIVE-ONLY: simple_bible's provenance is a per-source table row (D-005) | — |

### 3.3 `cli/` — 16 classes (7,440 lines)

| ID | Class / section | Lines | Purpose | Depends on | Class | Landed |
|---|---|---:|---|---|---|---|
| C-01 | `BIBLE_REPL` core | ~2,100 | Init; first-run copy of bible.db to `%LOCALAPPDATA%`; `bible.toml` config; exe-relative paths; auto-load; REPL loop; one-shot argv mode (joins argv, dispatches on `/cmd`); commands; lexicon; helpers; transliteration (l. 2116–2537); cross-reference and name commands (l. 3699–3866); state; version | S-09, {simple_sql, simple_toml, SIMPLE_PATH, simple_encoding, simple_datetime, simple_decimal, simple_process} | HARVEST-REWRITE: The command set must become a closed, specified, read-only set for one-shot use (simple_chat ISSUE 38); data-dir logic must know core/ai/user DBs | [ ] |
| C-02 | `BIBLE_REPL` AI translation | ~675 | `--trx`: Opus-MT ONNX translation, Ollama `llama3` fallback (l. 1441–2115) | S-26, {SIMPLE_AI_QUICK} | DROP: Machine translation shown as a gloss breaks D-004 ("the engine owns every fact"); replaced by precomputed gloss tables (L2) | — |
| C-03 | `BIBLE_REPL` scholarly, DDD, DSS/ANE, cuneiform, prehistory, Traced commands | ~2,560 | l. 2538–3698, 3867–4741, 5105–5629 | S-10 | PRIVATE-PLUGIN | [ ] |
| C-04 | `BIBLE_REPL` research agent | ~360 | `/research`: Ollama RAG over all corpora (l. 4742–5104) | {SIMPLE_AI_QUICK}, S-10 | ARCHIVE-ONLY: prior art for D-013; the L3 "explain" button is designed fresh with engine-only context | — |
| C-05 | `SCHOLAR_CLI` | 371 | Vault-analysis REPL | S-38 | ARCHIVE-ONLY | — |
| C-06 | `SCHOLAR_COMMAND_PARSER` | 79 | Splits REPL input into command + arguments | — | HARVEST-AS-IS | [ ] |
| C-07 | `SCHOLAR_PIPELINE_BASE` | 128 | Deferred pipeline step (progress, errors, tear-down) | — | HARVEST-REWRITE: base for the Eiffel distribution-DB builder steps (D-005, D-020) | [ ] |
| C-08 | `SCHOLAR_PIPELINE_EMBED` | 36 | Step 5: embeddings (calls stub S-13) | C-07 | ARCHIVE-ONLY | — |
| C-09 | `SCHOLAR_PIPELINE_EXTRACT` | 38 | Step 6: entities | C-07 | ARCHIVE-ONLY | — |
| C-10 | `SCHOLAR_PIPELINE_FRAMES` | 158 | Applies lenses to documents | C-07, S-19 | PRIVATE-PLUGIN | [ ] |
| C-11 | `SCHOLAR_PIPELINE_GRAPH` | 326 | Step 4: graph, PageRank, communities | C-07, S-22 | ARCHIVE-ONLY | — |
| C-12 | `SCHOLAR_PIPELINE_INDEX` | 37 | Step 3: TF-IDF, FTS5 | C-07 | ARCHIVE-ONLY | — |
| C-13 | `SCHOLAR_PIPELINE_INGEST` | 138 | Step 8: NBP ingestion | C-07 | ARCHIVE-ONLY: NBP already in scholars.db | — |
| C-14 | `SCHOLAR_PIPELINE_KACC` | 38 | Step 7: KACC scores | C-07, S-05 | PRIVATE-PLUGIN | [ ] |
| C-15 | `SCHOLAR_PIPELINE_PARSE` | 66 | Step 1: parse vault | C-07, S-27 | ARCHIVE-ONLY | — |
| C-16 | `SCHOLAR_PIPELINE_TOKENIZE` | 37 | Step 2: tokenize | C-07 | ARCHIVE-ONLY | — |
| C-17 | `SCHOLAR_SESSION` | 96 | Query history and cross-session memory | — | HARVEST-REWRITE: History moves into `user.db` (D-015) | [ ] |
| C-18 | `SCHOLAR_STEMMER` | 116 | Porter stemmer with a theological exception table | — | HARVEST-AS-IS: English search normalization (D-009) | [ ] |
| C-19 | `SCHOLAR_STOP_WORDS` | 78 | Stop-word list | — | HARVEST-AS-IS | [ ] |

### 3.4 `htmx/` — 12 classes (3,965 lines), plus the stylesheet

| ID | Class | Lines | Purpose | Depends on | Class | Landed |
|---|---|---:|---|---|---|---|
| H-01 | `BIBLE_HTMX_APP` | 554 | Root: web server + WebView2 window; DB and CSS discovery (env var `BIBLE_DB`, relative paths) | {simple_browser, simple_web, simple_file, simple_sql}, all HTMX_* | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-02 | `HTMX_PAGE` | 489 | Full page shell | — | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-03 | `HTMX_SHARED` | 434 | Shared rendering helpers, book table | {simple_logger, simple_sql, simple_web} | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-04 | `HTMX_BIBLE` | 279 | Bible tab | H-03, S-09 | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-05 | `HTMX_LEXICON` | 171 | Lexicon tab | H-03, S-09 | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-06 | `HTMX_SEARCH` | 285 | Cross-corpus FTS5 search tab | H-03 | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-07 | `SERVER_THREAD` | 38 | Background thread for the HTTP server | thread | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |
| H-08 | `HTMX_ANE` | 379 | ANE tab | S-10 | PRIVATE-PLUGIN | [ ] |
| H-09 | `HTMX_DDD` | 354 | DDD tab | S-10 | PRIVATE-PLUGIN | [ ] |
| H-10 | `HTMX_PREHISTORY` | 251 | Prehistory tab | S-10 | PRIVATE-PLUGIN | [ ] |
| H-11 | `HTMX_SCHOLARLY` | 507 | NBP narrative-search tab | S-10 | PRIVATE-PLUGIN | [ ] |
| H-12 | `HTMX_TRACED` | 224 | Traced (Jeanson Y-DNA) tab | S-10 | PRIVATE-PLUGIN | [ ] |
| H-13 | `bin/style.css` | 8 KB | **The HTMX stylesheet. Untracked** (bin/ is git-ignored) | — | ARCHIVE-ONLY (Q-05, 2026-10-06: D-006 chose the native simple_widgets face; no WebView2) | — |

### 3.5 `tui/` — 9 classes (3,278 lines)

| ID | Class | Lines | Purpose | Class | Landed |
|---|---|---:|---|---|---|
| U-01 | `BIBLE_TUI` | 311 | TUI root; opens `data/bible.db` | HARVEST-REWRITE (if L-3 keeps a TUI) | [ ] |
| U-02 | `TUI_BIBLE_TAB` | 262 | Version/book/chapter + verse list | HARVEST-REWRITE (L-3) | [ ] |
| U-03 | `TUI_LEXICON_TAB` | 219 | Strong's search | HARVEST-REWRITE (L-3) | [ ] |
| U-04 | `TUI_SEARCH_TAB` | 304 | Cross-corpus FTS5 search | HARVEST-REWRITE (L-3) | [ ] |
| U-05 | `TUI_ANE_TAB` | 422 | ANE browser | PRIVATE-PLUGIN | [ ] |
| U-06 | `TUI_DDD_TAB` | 476 | DDD browser | PRIVATE-PLUGIN | [ ] |
| U-07 | `TUI_PREHISTORY_TAB` | 436 | Prehistory browser | PRIVATE-PLUGIN | [ ] |
| U-08 | `TUI_SCHOLARLY_TAB` | 459 | NBP assertion search | PRIVATE-PLUGIN | [ ] |
| U-09 | `TUI_TRACED_TAB` | 389 | Traced browser | PRIVATE-PLUGIN | [ ] |

All depend on simple_tui, simple_logger and S-09/S-10.

### 3.6 `gui/` — 14 classes (5,432 lines), all ARCHIVE-ONLY

Vision2 (simple_vision) cannot shape right-to-left text; text surfaces belong in the WebView2 face (S05-VERDICTS §6, design §3 L4). Kept as history; revisit only when simple_shaping matures.

| ID | Class | Lines | Class |
|---|---|---:|---|
| G-01 | `BIBLE_GUI` | 207 | ARCHIVE-ONLY |
| G-02 | `BIBLE_GUI_STATE` | 347 | ARCHIVE-ONLY |
| G-03 | `BIBLE_GUI_WINDOW` | 700 | ARCHIVE-ONLY |
| G-04 | `ANE_VIEW` | 319 | ARCHIVE-ONLY |
| G-05 | `BIBLE_READING_VIEW` | 485 | ARCHIVE-ONLY |
| G-06 | `DDD_VIEW` | 646 | ARCHIVE-ONLY |
| G-07 | `LEXICON_VIEW` | 263 | ARCHIVE-ONLY |
| G-08 | `PREHISTORY_VIEW` | 336 | ARCHIVE-ONLY |
| G-09 | `RESEARCH_VIEW` | 423 | ARCHIVE-ONLY |
| G-10 | `SCHOLARLY_VIEW` | 682 | ARCHIVE-ONLY |
| G-11 | `TRACED_VIEW` | 347 | ARCHIVE-ONLY |
| G-12 | `DETAIL_PANEL` | 388 | ARCHIVE-ONLY |
| G-13 | `SEARCH_BAR` | 141 | ARCHIVE-ONLY |
| G-14 | `VERSE_DISPLAY` | 148 | ARCHIVE-ONLY |

### 3.7 `test/` — 16 classes, 84 tests (1,875 lines), plus fixtures

| ID | Class | Tests | Covers | Class | Landed |
|---|---|---:|---|---|---|
| X-01 | `TEST_APP` | runner | Registers all suites | HARVEST-REWRITE | [ ] |
| X-02 | `TEST_BIBLE` | 17 | Schema creation, book-id resolution (names, abbreviations, numbered books, case), reference parsing | HARVEST-REWRITE: Re-point at core.db fixtures | [ ] |
| X-03 | `TEST_BIBLE_TUI_HARDEN` | 18 | Phase 6 adversarial: availability checks on empty/partial DBs, book-id boundaries, version list | HARVEST-REWRITE: Keep the empty/partial-DB pattern; private-table cases move to plug-in tests | [ ] |
| X-04 | `TEST_RANK_FUSION` | 2 | RRF construction (vacuous against the stub) | HARVEST-REWRITE: Write real RRF assertions | [ ] |
| X-05 | `TEST_INDEX` | 7 | Sparse vector, cosine, TF-IDF | HARVEST-REWRITE (with S-23) | [ ] |
| X-06 | `TEST_SEARCH` | 3 | Levenshtein | HARVEST-AS-IS | [ ] |
| X-07 | `TEST_GRAPH` | 6 | Graph build, neighbors, PageRank, shortest path | HARVEST-REWRITE (with S-22) | [ ] |
| X-08 | `TEST_PARSER` | 8 | Title, tags, wikilinks, headers, code-block stripping | HARVEST-REWRITE (with S-27, rix.db builder) | [ ] |
| X-09 | `TEST_KACC` | 3 | KACC result construction | PRIVATE-PLUGIN | [ ] |
| X-10 | `TEST_FRAME_DNP` | 6 | Registry, DNP / Walton / Rillera applicability | PRIVATE-PLUGIN | [ ] |
| X-11 | `TEST_ANALYZER` | 1 | Analyzer creation | ARCHIVE-ONLY | — |
| X-12 | `TEST_ANALYZER_FULL` | 4 | TextRank, bigrams, similarity | ARCHIVE-ONLY | — |
| X-13 | `TEST_SCHOLAR` | 4 | Facade configuration | ARCHIVE-ONLY | — |
| X-14 | `TEST_PIPELINE_GRAPH` | 1 | Graph pipeline tables | ARCHIVE-ONLY | — |
| X-15 | `TEST_EMBEDDER` | 2 | Tier defaults (stub) | ARCHIVE-ONLY | — |
| X-16 | `TEST_WEB_SEARCH` | 2 | Aggregator/fusion construction (stubs) | ARCHIVE-ONLY | — |
| X-17 | `test/fixtures/vault/` (10 .md, 7.4 KB) | — | Synthetic notes under Heiser/, Walton/, Wright/, Rix/ | HARVEST-REWRITE: neutral fixture names for parser and rix.db-builder tests | [ ] |

### 3.8 Data files

License column per `Rix/Data/_Text Credits (paste-ready).md` and design §7. "Restricted" = gated under Larry's NC/unknown ruling of 2026-09-04.

| ID | Path | Size | What | License status | Class | Landed |
|---|---|---:|---|---|---|---|
| D-01 | `data/bible.db` | 161 MB | February fork (Feb 11): 15 versions / 263,347 verses, word_strongs, strongs 14,298, peshitta_words, ane_glosses 134, **NBP corpus (corpus_units with full transcript text, assertions 13,393)**, research_corpus (2 rows) | Mixed. Versions span PD / CC0 / CC BY / CC BY-NC (TgO) / unknown (SP, Byz, TgN, TgW). `bible_versions.license` says "MIT" for all (wrong). NBP content copyrighted. | DROP: superseded by the vault and by the D-005 distribution build | — |
| D-02 | `bin/data/bible.db` (+ `-shm`, `-wal`) | 161 MB | Byte-identical copy of D-01 | as D-01 | DROP | — |
| D-03 | `%LOCALAPPDATA%\BibleREPL\data\bible.db` = `D:\prod\bible_pwa\bible.db` | 213 MB | The enriched February DB (Feb 17). Holds data the vault never received: `proper_names` 4,248 / `proper_name_refs` 31,062 / `proper_name_relations` 11,754 (STEPBible TIPNR); `strongs` 19,671 with `gloss`/`morphology`/`meaning` columns (5,373 extended entries, STEPBible TBESH/TBESG); `ane_glosses` 2,670 (2,536 with no source); `entity_verses` 8,799; `entity_strongs` 377; `traced_*` (533/192/50); `prehistory_*` (45/17/7); `enrichment_log` 974 (AI-written descriptions, e.g. "claude-opus-local") | Same mix as D-01, plus DDD (Brill, copyrighted), AI-generated DSS and enrichment rows | ARCHIVE-ONLY: Keep one copy in the archive. Its shippable content (TIPNR, TBESH/TBESG) is rebuilt from upstream (SC-01, SC-02, SC-03), not copied | — |
| D-04 | `C:\Program Files\BibleREPL\data\bible.db` | 208 MB | Older installed variant (Feb 14); a subset of D-03 | as D-03 | DROP (goes with uninstall, R-8) | — |
| D-05 | `nakedbiblepodcast.db` | 38.6 MB | episodes 479, assertions 13,393, entities 140, source_references 11,074 | Copyrighted (Heiser / NBP). Already in scholars.db `nbp_*` (copy-verified 2026-08-14) | ARCHIVE-ONLY (never publish) | — |
| D-06 | `data/transcripts/` | 213 MB, 471 PDF | NBP transcript PDFs | Copyrighted | ARCHIVE-ONLY (text already in scholars.db `nbp_units`) | — |
| D-07 | `data/transcripts_text/` | 24.7 MB, 471 TXT | Extracted transcript text | Copyrighted | ARCHIVE-ONLY | — |
| D-08 | `data/sources/STEPBible-Data/` | 484 MB | Git clone `043ffd0` (2026-01-03), github.com/STEPBible/STEPBible-Data | CC BY 4.0; **TTESV parts CC BY-NC → Restricted** | HARVEST-REWRITE: Record as a pinned source in the D-005 build manifest and re-clone; do not copy | [ ] |
| D-09 | `data/sources/morphhb/` | 115 MB | Git clone `3d15126` (2024-08-27), github.com/openscriptures/morphhb (WLC + MapM) | CC BY 4.0 | HARVEST-REWRITE: pinned source | [ ] |
| D-10 | `data/sources/sblgnt/` | 11 MB | Git clone `aaed91e` (2024-01-21), github.com/morphgnt/sblgnt | CC BY 4.0 (per Text Credits, via MorphGNT) | HARVEST-REWRITE: pinned source | [ ] |
| D-11 | `data/sources/peshitta-tools/` | 19 MB | Git clone `982089f` (2020-04-19), github.com/fhardison/peshitta-tools (SEDRA) | Terms to check (design §7) | HARVEST-REWRITE: pinned source, license check first | [ ] |
| D-12 | `data/sources/cross_references.txt` + `cross-references.zip` | 8.0 + 1.9 MB | OpenBible.info cross-references, header dated 2026-02-09 | CC BY | HARVEST-REWRITE: pinned download (vault bible.db already holds 344,799 rows) | [ ] |
| D-13 | `bin/data/models/opus-mt-mul-en/` | 1.29 GB, 13 files | Helsinki-NLP Opus-MT ONNX export | CC BY 4.0 (upstream) | DROP: The translation use is dropped (C-02); re-downloadable | — |
| D-14 | `bin/data/output/` | 7 files, 16 KB | REPL output captures (2026-02-13) | — | DROP | — |
| D-15 | `bin/fonts/NotoSansCuneiform-Regular.ttf` + OFL.txt | 824 KB | Cuneiform font, installed by the old installer | SIL OFL 1.1 | PRIVATE-PLUGIN: Only the ANE views need it | [ ] |
| D-16 | `installer/versions_placeholder.txt` | 99 B | "Place additional .db files here" | — | DROP | — |

### 3.9 Scripts — 61 in `scripts/`, 9 in `scripts/sources/`, 1 at the root

**D-020 applies:** No Python in simple_bible. A script marked HARVEST-REWRITE is harvested as a *reference implementation*. Its Eiffel port lands in the distribution-DB builder and must pass a row-by-row differential test against it.

**Shippable-data importers (reference implementations):**

| ID | Script | Size | Purpose | Class | Landed |
|---|---|---:|---|---|---|
| SC-01 | `import_stepbible_lexicons.py` | 8 KB | Extend `strongs` with TBESH/TBESG gloss, morphology, meaning; adds extended entries | HARVEST-REWRITE | [ ] |
| SC-02 | `import_stepbible_names.py` | 17 KB | TIPNR → proper_names / refs / relations | HARVEST-REWRITE | [ ] |
| SC-03 | `enrich_proper_name_relations.py` | 15 KB | Parents/siblings/partners/offspring from TIPNR headers | HARVEST-REWRITE | [ ] |
| SC-04 | `import_cross_references.py` | 10 KB | OpenBible.info cross-references | HARVEST-REWRITE | [ ] |
| SC-05 | `ingest_word_strongs.py` | 11 KB | Word-level Strong's from morphhb XML + STEPBible TAGNT | HARVEST-REWRITE (compare with the vault's MACULA path before porting) | [ ] |
| SC-06 | `update_glosses.py` | 7 KB | word_strongs.gloss from STEPBible TAHOT/TAGNT | HARVEST-REWRITE | [ ] |
| SC-07 | `ingest_peshitta_glosses.py` | 6 KB | Peshitta words from SEDRA list | HARVEST-REWRITE (license check D-11) | [ ] |
| SC-08 | `merge_strongs.py` | 2 KB | Merge strongs from an external strongs-sqlite3.db | DROP: one-off merge | — |
| SC-09 | `build_gloss_bridge.py` | 10 KB | Greek–Syriac positional gloss bridge | ARCHIVE-ONLY: "unfinished, not to be cited" (Text Credits) | — |
| SC-10 | `verify_bridge.py` | 2 KB | Checks SC-09 | ARCHIVE-ONLY | — |
| SC-11 | `check_overlap.py` | 1 KB | Ad-hoc overlap check | DROP | — |

**ANE, Dead Sea Scrolls, pseudepigrapha (output already in primary_evidence.db):**

| ID | Script | Size | Purpose | Class |
|---|---|---:|---|---|
| SC-12 | `create_ane_schema.py` | 4 KB | ANE table schema | ARCHIVE-ONLY |
| SC-13 | `import_ane_texts.py` | 12 KB | ANE texts with embedded data | ARCHIVE-ONLY |
| SC-14 | `_ane_data_oracc.py` | 94 KB | ORACC/Akkadian data | ARCHIVE-ONLY |
| SC-15 | `_ane_data_perseus.py` | 48 KB | Josephus + Philo data | ARCHIVE-ONLY |
| SC-16 | `_ane_data_pseudepigrapha.py` | 51 KB | Pseudepigrapha data | ARCHIVE-ONLY |
| SC-17 | `_ane_data_angelology.py` | 12 KB | Angelology/demonology data | ARCHIVE-ONLY |
| SC-18 | `import_ebl.py` | 19 KB | eBL API import | ARCHIVE-ONLY |
| SC-19 | `enrich_ane_corpora.py` | 75 KB | Bible/entity links across ANE corpora (Claude API) | ARCHIVE-ONLY (machine-assigned links) |
| SC-20 | `enrich_ane_corpora_pass2.py` | 22 KB | Fix-up pass (Claude API) | ARCHIVE-ONLY |
| SC-21 | `import_dss.py` | 26 KB | DSS records **generated by Claude Sonnet** | ARCHIVE-ONLY (provenance evidence for §1 item 8) |
| SC-22 | `import_dss_local.py` | 97 KB | DSS records **"generated from Claude's knowledge"** | ARCHIVE-ONLY (same) |
| SC-23 | `download_pseudepigrapha.py` | 26 KB | Download pseudepigrapha | ARCHIVE-ONLY |
| SC-24 | `download_pseudepigrapha_fix.py` | 20 KB | Gap fixes | ARCHIVE-ONLY |
| SC-25 | `download_pseudepigrapha_remaining.py` | 13 KB | Remaining texts | ARCHIVE-ONLY |
| SC-26 | `load_pseudepigrapha_content.py` | 6 KB | Load text into DB | ARCHIVE-ONLY |
| SC-28 | `load_angelology_content.py` | 5 KB | Load angelology text | ARCHIVE-ONLY |

**DDD (Dictionary of Deities and Demons; Brill, copyrighted; output in scholars.db):**

| ID | Script | Size | Purpose | Class |
|---|---|---:|---|---|
| SC-29 | `extract_ddd.py` | 21 KB | Extract DDD entries from the PDF | ARCHIVE-ONLY |
| SC-30 | `refine_ddd.py` | 17 KB | Pass 2 refinement | ARCHIVE-ONLY |
| SC-31 | `clean_ddd_text.py` | 15 KB | Artifact cleanup | ARCHIVE-ONLY |
| SC-32 | `classify_ddd_entities.py` | 87 KB | DDD classification system | ARCHIVE-ONLY |
| SC-33 | `enrich_ddd_claude.py` | 8 KB | Enrichment via Claude API | ARCHIVE-ONLY |
| SC-34 | `enrich_ddd_local.py` | 30 KB | Enrichment with embedded generated data | ARCHIVE-ONLY |
| SC-35 | `enrich_ddd_cleanup.py` | 16 KB | OCR cleanup + summary regeneration | ARCHIVE-ONLY |
| SC-36 | `link_ddd_strongs.py` | 11 KB | Step 1A | ARCHIVE-ONLY |
| SC-37 | `link_ddd_assertions.py` | 6 KB | Step 1B | ARCHIVE-ONLY |

**Entities, ANE glosses, enrichment (interpretive or machine-generated):**

| ID | Script | Size | Purpose | Class |
|---|---|---:|---|---|
| SC-38 | `seed_ane_glosses.py` | 17 KB | The original 134 ANE glosses (Larry's, sourced) | PRIVATE-PLUGIN: Interpretive data must not sit in core.db; it belongs with Larry's layer (decision L-6). Landed: [ ] |
| SC-39 | `expand_ane_glosses.py` | 8 KB | 134 → 2,000+ via Claude API | ARCHIVE-ONLY (unsourced output) |
| SC-40 | `expand_ane_glosses_local.py` | 3 KB | Same, from curated files | ARCHIVE-ONLY |
| SC-41 | `_ane_glosses_curated.py` | 36 KB | Curated glosses part 1 | ARCHIVE-ONLY |
| SC-42 | `_ane_glosses_curated2.py` | 108 KB | Part 2 | ARCHIVE-ONLY |
| SC-43 | `_ane_glosses_curated3.py` | 75 KB | Part 3 | ARCHIVE-ONLY |
| SC-44 | `enrich_entities_claude.py` | 7 KB | Entity descriptions via Claude API | ARCHIVE-ONLY |
| SC-45 | `enrich_entities_local.py` | 58 KB | Same, embedded data | ARCHIVE-ONLY |
| SC-46 | `eliminate_isolates.py` | 10 KB | Step 1F auto-linking | ARCHIVE-ONLY |

**Podcast, research, prehistory, Traced (private corpora):**

| ID | Script | Size | Purpose | Class |
|---|---|---:|---|---|
| SC-47 | `scrape_nakedbible.py` (repo root) | 10 KB | WordPress API scrape of NBP | ARCHIVE-ONLY |
| SC-48 | `download_transcripts.py` | 4 KB | NBP transcript PDFs | ARCHIVE-ONLY |
| SC-49 | `extract_transcript_text.py` | 7 KB | PDF → text | ARCHIVE-ONLY |
| SC-50 | `build_scholar_corpus.py` | 37 KB | Structured NBP corpus | ARCHIVE-ONLY |
| SC-51 | `merge_corpus_to_bible.py` | 24 KB | NBP → bible.db | ARCHIVE-ONLY |
| SC-52 | `ingest_research.py` | 12 KB | research_corpus + FTS5 | ARCHIVE-ONLY |
| SC-53 | `ingest_prehistory.py` | 29 KB | Prehistory assertions | ARCHIVE-ONLY (tables not in the vault; decision L-7) |
| SC-54 | `ingest_sumerian_assertions.py` | 75 KB | "Sumerian Memory" fact-checked assertions | ARCHIVE-ONLY (L-7) |
| SC-55 | `ingest_traced.py` | 371 KB | Traced assertions, data embedded in the script | ARCHIVE-ONLY (L-7) |

**One-off patchers and exporters:**

| ID | Script | Size | Purpose | Class |
|---|---|---:|---|---|
| SC-27 | `export_to_obsidian.py` (wip branch only) | 10 KB | bible.db → Obsidian markdown | ARCHIVE-ONLY (preserved by the branch merge, §8 step 2) |
| SC-56 | `patch_repl.py` | 30 KB | Patch bible_repl.e (cuneiform commands) | DROP |
| SC-57 | `patch_localappdata.py` | 8 KB | Patch bible_repl.e (LOCALAPPDATA) | DROP |
| SC-58 | `patch_rescue.py` | 3 KB | Patch rescue clause | DROP |
| SC-59 | `update_bible_repl.py` | 14 KB | Patch for prehistory columns | DROP |
| SC-60 | `update_scholar_bible.py` | 7 KB | Patch scholar_bible.e | DROP |
| SC-61 | `fix_scholar_bible.py` | 1 KB | Revert a patch | DROP |
| SC-62 | `update_guide.py` | 8 KB | Patch the user guide | DROP |

**`scripts/sources/` (9 tracked downloaders; 79 tracked + 1 untracked texts):**

| ID | Item | Size | Class |
|---|---|---:|---|
| SC-63 | 9 downloaders/cleaners (`download_texts.py`, `download_v3.py`, `download_final.py`, `download_pseudepigrapha.py`, `download_remaining.py`, `extract_eusebius.py`, `extract_eusebius2.py`, `cleanup_texts.py`, `final_cleanup.py`) | 117 KB | ARCHIVE-ONLY |
| SC-64 | `texts/` — 79 tracked plain-text files (1 Enoch sections, Jubilees, 2–3 Baruch, 4–6 Ezra, Testaments, Dionysius, Goetia, Key of Solomon, etc.) | 4.7 MB | ARCHIVE-ONLY (public-domain translations; output in primary_evidence.db) |
| SC-65 | Untracked: `dionysius_works.pdf`, `fbe.txt`, `fbe.txt.gz`, `pseudepigrapha_charles.txt`, `texts/download_grimoires.py` | ~6.6 MB | ARCHIVE-ONLY (copy into the keep-set, §8 step 4) |

**Untracked data dumps in `scripts/`:**

| ID | Item | Size | Class |
|---|---|---:|---|
| SC-66 | `strongs_candidates.json`, `ddd_dump.json`, `all_entities.json`, `entities_dump.json`, `entity_context.json`, `ane_gloss_examples.json`, `ebl_texts.json`, `ebl_sample_chapter.json` | 13.4 MB | ARCHIVE-ONLY |
| SC-67 | `bible_books.json` | 4 KB | ARCHIVE-ONLY (book metadata now comes from core.db) |
| SC-68 | `_candidates_dump.txt`, `_g_candidates.txt`, `_h_candidates.txt` | 562 KB | ARCHIVE-ONLY |
| SC-69 | `scripts/__pycache__/` | 577 KB | DROP |

### 3.10 Documentation, plans, workflow evidence

| ID | Item | Size | What | Class | Landed |
|---|---|---:|---|---|---|
| W-01 | `docs/BIBLE_REPL_USER_GUIDE.md` | 49 KB | User guide for bible.exe (all commands, install, config) | HARVEST-REWRITE: basis for the simple_bible CLI guide; private commands move to the plug-in's guide | [ ] |
| W-02 | `bin/docs/BIBLE_REPL_USER_GUIDE.pdf` | 458 KB | PDF render of W-01 | DROP | — |
| W-03 | `plans/data-enrichment-plan.txt` | 21 KB | February enrichment plan (untracked) | ARCHIVE-ONLY | — |
| W-04 | `.eiffel-workflow/intent.md`, `intent-v2.md` | 30 KB | Vault-analysis intent (three-tier AI, KACC) | ARCHIVE-ONLY | — |
| W-05 | `.eiffel-workflow/research/` (8 files) | 152 KB | February research 01–07 + REFERENCES | ARCHIVE-ONLY (consult 02-LANDSCAPE and 04-DECISIONS as prior art) | — |
| W-06 | `.eiffel-workflow/spec/` (9 files) | 262 KB | Spec 01–09 incl. 09-PREPROCESSING-PIPELINE | ARCHIVE-ONLY | — |
| W-07 | `.eiffel-workflow/approach.md`, `synopsis.md`, `tasks.md`, `prompts/` | ~40 KB | Phase 2–3 artifacts | ARCHIVE-ONLY | — |
| W-08 | `.eiffel-workflow/evidence/` (16 files) | 80 KB | Phase 0–6 evidence, design scan, MML | ARCHIVE-ONLY | — |

### 3.11 Installer, PWA, distribution, binaries

| ID | Item | Size | What | Class | Landed |
|---|---|---:|---|---|---|
| I-01 | `installer/bible_repl.iss` | 16 KB | Inno Setup: normal vs portable install, `bible.toml` written and preserved across upgrades, `%LOCALAPPDATA%` data dir, user-PATH add, ONNX component, font install | HARVEST-REWRITE: base for D-018 (two editions, WebView2 bootstrap, `user.db` kept on uninstall) | [ ] |
| I-02 | `dist/BibleREPL-Setup.exe` | 550 MB | Built installer. Bundles D-01-era bible.db with NBP content. Never published (repo private, no releases) | DROP: rebuildable from the archive tag; must not be distributed | — |
| I-03 | `pwa/` (5 files, 39 KB) | 39 KB | Early sql.js PWA | DROP: superseded by the later `D:\prod\bible_pwa` (all five files differ; app.js 26 KB → 49 KB) | — |
| I-04 | `bin/bible_tui.exe`, `bin/bible_tui_dbc.exe` | 3.8 + 16.1 MB | Built TUI | DROP | — |
| I-05 | `bin/onnxruntime.dll`, `WebView2Loader.dll`, `webview.dll`, `cairo.dll` | 13.6 MB | Runtime DLLs | DROP: supplied by simple_onnx / simple_browser at build | — |
| I-06 | `bin/*.log` (`task_manager.log` 29 MB, `tui_demo.log`, `bible_tui.log`), `bin/exception_trace.log` | 29.4 MB | Logs | DROP | — |

### 3.12 Root files

| ID | Item | Size | Class | Landed |
|---|---|---:|---|---|
| R-01 | `simple_scholar.ecf` | 5 KB | HARVEST-REWRITE (see §3.1) | [ ] |
| R-02 | `simple_scholar.rc` | 120 B | HARVEST-AS-IS (generic Windows resource string) | [ ] |
| R-03 | `.gitignore` | 1 KB | HARVEST-REWRITE: Keep the data/model/dist rules; stop ignoring hand-written assets such as the stylesheet | [ ] |
| R-04 | `compile_check*.log` (3), `compile_release*.log` (5) | 26 KB | DROP | — |
| R-05 | `exception_trace.log`, `ls_out.txt` | 2 KB | DROP | — |
| R-06 | `EIFGENs/` (7 target folders) | 1.6 GB | DROP (build output) | — |

### 3.13 Footprint outside the repository

| ID | Item | What | Class |
|---|---|---|---|
| O-01 | `C:\Program Files\BibleREPL\` | Installed bible.exe v1.7.0 (Feb 15), onnxruntime.dll, guide, fonts, models, D-04, uninstaller | DROP after R-6 and R-8 |
| O-02 | `%LOCALAPPDATA%\BibleREPL\` | `bible.toml` (v1.7.0, normal install), `data\bible.db` (D-03), `output\`, `versions\` | ARCHIVE-ONLY (D-03 copied into the keep-set before uninstall) |
| O-03 | `C:\Users\LJR19\OneDrive\Documents\BibleREPL\` | 144 REPL output captures (Feb 13 – Sep 1) | ARCHIVE-ONLY (Larry's call whether to keep in place) |
| O-04 | User PATH entries `C:\Program Files\BibleREPL` and stale `%LOCALAPPDATA%\Programs\BibleREPL` | | DROP (uninstall removes the first; remove the second by hand) |
| O-05 | `D:\prod\bible_pwa\` | Later PWA (Feb 17): app.js, index.html, sw.js, local sql-wasm, `serve.py`, **213 MB bible.db (D-03) including NBP, DDD and AI-generated rows**. **Not under git.** | Decision L-2 (§9). Not counted in §0 |

---

## 4. License summary for what simple_bible takes

Everything credited, always. What simple_bible's core.db may take from this harvest, by the Text Credits:

- **Ships with attribution:** OpenBible.info cross-references (CC BY); morphhb WLC + MapM (CC BY 4.0); SBLGNT via MorphGNT (CC BY 4.0); STEPBible TIPNR, TBESH/TBESG, TAHOT/TAGNT (CC BY 4.0).
- **Verify first:** peshitta-tools / SEDRA data.
- **Restricted (NC or unknown):** STEPBible TTESV (CC BY-NC); and, in the old DBs only, TgO (CC BY-NC), SP, Byz, TgN, TgW (unknown). None of these come through this harvest; the D-005 build decides them.
- **Never ships:** NBP transcripts and corpus; DDD (Brill); AI-generated DSS, entity, enrichment and expanded-gloss rows; Larry's interpretive `ane_glosses` (Larry's layer, L-6).

---

## 5. Counting rule

§0 counts every row with an ID in §3.1–§3.12 (224 rows; 92 of them carry a Landed box). §3.13 (outside the repository) is listed for the retirement checklist but not counted. `SCHOLAR_BIBLE` and `BIBLE_REPL` are split by section into two and four rows because their sections fall into different classes.

---

## 6. Retirement criteria (all must be true before simple_scholar is retired)

**Harvest landed:**

- [ ] **R-1** Every HARVEST-AS-IS and HARVEST-REWRITE row in §3 has its Landed box ticked with a simple_bible commit hash, and the simple_bible test suite passes (including the rewritten X-01 to X-08 and X-17).
- [ ] **R-2** Every PRIVATE-PLUGIN row has landed in the private plug-in repository (D-014), or Larry has marked it "deferred, consult the archive." A grep of the public simple_bible tree finds no `SCHOLAR_FRAME_WALTON|RILLERA|DNP|PODCAST|ANCIENT`, no `KACC_`, and no reference to `scholars.db`, `transcripts.db` or `nakedbiblepodcast`.
- [ ] **R-3** The Eiffel ports of SC-01 to SC-07 pass their differential tests against the Python reference implementations (D-020), and core.db carries everything the February DB offered that may ship: verses (via D-005), Strong's with the TBESH/TBESG extended entries and columns, word-level Strong's and glosses, OpenBible cross-references, TIPNR proper names with relations, Peshitta words (if D-11 clears).
- [ ] **R-4** Hebrew and Greek render correctly in the simple_bible native face (simple_widgets + simple_shaping; D-006, Q-05). Superseded wording: "WebView2 face".

**Replacements in place:**

- [ ] **R-5** A simple_bible CLI one-shot mode exists with a **closed, specified, read-only command set** (simple_chat ISSUE 38: "an allowlisted set of slash commands", not a shape). It covers the core subset of the 18 commands simple_chat allows today: verse references, `define`, `search`, `compare`, `etymology`, `xref`, `people`, `list`, `versions`. The private subset (`entity`, `episode`, `scholar`, `assertions`, `ddd`, `overlap`, `ane`, `dss`, `pseudepigrapha`) is served by Larry's plug-in build or retired by Larry's decision. `web` follows L-5.
- [ ] **R-6** simple_chat is retargeted and its tests pass: `src/participants/bible_tool_participant.e` (executable, `Allowed_commands`, `closed: Result.count = 18`, `Tool_description`, class note), `src/participants/tool_participant.e` comments at l. 243 and 680, `testing/participants_assault.e`, and the fixtures `testing/config_scratch/full.toml` and `testing/config_load_assault.e` (`engine = "bible_repl.exe"`). Larry's downstream-dependents rule applies.
- [ ] **R-7** The simple_bible installer (D-018) builds, installs and uninstalls cleanly **on a non-live identity** (standing rule: Never verify installers on the live identity). It supersedes `installer/bible_repl.iss`.
- [ ] **R-8** The installed BibleREPL v1.7.0 is uninstalled **only after** D-03 is in the keep-set (§8 step 4). Both PATH entries are gone. Larry has decided where the 144 outputs in `OneDrive\Documents\BibleREPL` live.
- [ ] **R-9** The PWA decision (L-2) is made and carried out. Either bible_pwa is rebuilt on core.db and put under git, or it is retired. In both cases the 213 MB private-content bible.db leaves any served folder, and `bible_pwa/serve.py` (l. 24–25, which tells the user to symlink `D:\prod\simple_scholar\bin\data\bible.db`) is updated or retired.

**Record kept:**

- [ ] **R-10** Branch-only work preserved: master fast-forwarded to `2f939b2` and pushed (§8 step 2).
- [ ] **R-11** The untracked keep-set (§2 table, SC-65, SC-66, SC-67, SC-68, W-03, D-03, D-05) is copied to the archive location with a manifest of paths, sizes and SHA-256 hashes.
- [ ] **R-12** The vault provenance flag in §1 item 8 is filed in `_bible.db Provenance.md` or the primary_evidence README (DSS tables = machine-generated, P4), along with the 2,536 unsourced `ane_glosses` rows in D-03.
- [ ] **R-13** Documentation references updated or deliberately left as history (§7, "docs" rows).
- [ ] **R-14** Larry signs off on this ledger.

---

## 7. Downstream dependents

Search: every file under `D:\prod` except `simple_scholar\`, `EIFGENs\`, `.git\`, `node_modules\`, `__pycache__\`, binaries, databases, logs and files over 8 MB, for `simple_scholar | bible.exe | bible_repl | BibleREPL | scholar_cli | bible_htmx | bible_tui` (case-insensitive). Also searched: the vault's `_Tools\` (no hits).

**Code that runs (must change before retirement):**

| Project | File | Reference | Action |
|---|---|---|---|
| simple_chat | `src/participants/bible_tool_participant.e` | `@tools-larry` runs **bible.exe** one-shot; 18-command allowlist verified against `bible_repl.e` `process_command` | Retarget (R-6) |
| simple_chat | `src/participants/tool_participant.e` | l. 243 (`/` admitted as bible.exe's prefix), l. 680 (bible.exe reads its DBs beside itself) | Update comments/law (R-6) |
| simple_chat | `testing/participants_assault.e` | bible.exe, simple_scholar | Update tests (R-6) |
| simple_chat | `testing/config_load_assault.e` l. 111, 143; `testing/config_scratch/full.toml` l. 37 | `engine = "bible_repl.exe"` | Update fixtures (R-6) |
| bible_pwa | `serve.py` l. 24–25 | Symlink instructions to `simple_scholar\bin\data\bible.db` | R-9 |

**Documentation and evidence (history; update only where they direct future work):**

| Project | Files |
|---|---|
| simple_chat | `.eiffel-workflow/CHRONICLE.md`, `intent.md`, `intent-v2.md`, `research/01,02,04,06,07,REFERENCES`, `spec/01-PARSED-REQUIREMENTS.md`, `spec/09-ADDENDUM-PARTICIPANTS.md`, `evidence/phase2b-part-participants.md`, `evidence/downstream-sweep-2026-09-02-high.txt` |
| simple_bible | `.eiffel-workflow/research/01–04, 06, 07, REFERENCES` (this project's own research; expected) |
| simple_shaping | `.eiffel-workflow/research/02-LANDSCAPE.md`, `REFERENCES.md` (cites simple_scholar's Hebrew problem) |
| simple_graphify | `docs/cookbook.html` l. 49 (uses `SIMPLE_SCHOLAR` as an example class name; update the example when the class is gone) |
| graphify-out | `GRAPH_REPORT.md`, `graph.dot`, `graph.html`, `graph.json` (generated graph of D:\prod; regenerate after archive) |
| whisper_cpp_build | `build_cuda/CMakeFiles/CMakeConfigureLog.yaml` (PATH echo containing `BibleREPL`; harmless, clears when PATH is fixed) |

**No ECF in D:\prod references `simple_scholar.ecf`.** No other library depends on simple_scholar as a library. Its only run-time consumer is simple_chat, through bible.exe.

**Outside D:\prod:** the installed `C:\Program Files\BibleREPL\bible.exe` is on the user PATH, so any script or person typing `bible` reaches it (O-01, O-04).

---

## 8. Archive procedure (proposal for Larry; not executed)

1. **Freeze.** Confirm the working tree is clean (it is today) and nothing is running from `D:\prod\simple_scholar\bin`.
2. **Bring master up to date.** `wip/uncommitted-2026-09-02` is a straight descendant of master, so this is a fast-forward:
   `git -C D:/prod/simple_scholar checkout master`
   `git -C D:/prod/simple_scholar merge --ff-only wip/uncommitted-2026-09-02`
   `git -C D:/prod/simple_scholar push origin master`
   Keep the wip branch until step 6, then delete it locally and on origin. The `refs/original` backup can be dropped (`git update-ref -d refs/original/refs/heads/master`); its tip tree equals master's.
3. **README notice.** Add `README.md` (the repo has none today): "RETIRED 2026-xx-xx. Superseded by `simple_bible` (D:\prod\simple_bible). Harvest record: `simple_bible/.eiffel-workflow/research/08-HARVEST-LEDGER.md`. This repository is kept read-only for history. Do not install BibleREPL from this source; its database contains copyrighted material." Commit, then tag `archive/2026-xx-xx` (annotated) and push the tag.
4. **Keep-set for untracked files.** Copy the items listed in R-11 to `D:\_archive\simple_scholar\` with a `MANIFEST.tsv` (path, bytes, SHA-256). D: is not in OneDrive backup, so make a second copy. Options for Larry: (a) a zipped keep-set as a release asset on the private, archived GitHub repo (private storage, not distribution); (b) an external drive. The keep-set is about 270 MB before compression (D-03 213 MB, D-05 39 MB, the rest small). Data that is re-fetchable upstream (D-08 to D-13) and NBP transcripts already in scholars.db (D-06, D-07) are not copied unless Larry wants them.
5. **Archive on GitHub.** `gh repo archive simple-eiffel/simple_scholar` (read-only). Keep it **private**: The scripts embed generated and scraped data, and the git history describes copyrighted sources.
6. **Retire locally.** After R-1 to R-13 are ticked and Larry signs R-14, move `D:\prod\simple_scholar` out of `D:\prod` (for example to `D:\_archive\simple_scholar\repo\`), so fleet sweeps and graphify stop seeing it. Leave a breadcrumb `D:\prod\simple_scholar_MOVED.md` naming the new location, the tag and this ledger (the vault's breadcrumb convention).
7. **Uninstall BibleREPL** (R-8), then remove the stale PATH entry by hand.
8. **Record.** Update memory `project_simple_scholar_revival.md` → RETIRED, with the tag, archive path and keep-set manifest location.

---

## 9. Decisions for Larry

- **L-1** Approve the classifications in §3, especially the DROP of C-02 (AI translation) and the ARCHIVE-ONLY of the GUI.
- **L-2** `D:\prod\bible_pwa`: Rebuild on core.db and put it under git, or retire it? The design (§3 L4) keeps a zero-install PWA. Today it is unversioned and serves a database with NBP, DDD and AI-generated rows.
- **L-3** Keep a TUI face in simple_bible? Design §4 keeps the multi-front-end layout; D-006 names only WebView2 and the CLI. U-01 to U-04 and T-06 depend on this.
- **L-4** D-019 ships rix.db with the frameworks. Should KACC scoring (S-03 to S-05, C-14, X-09) also ship, or stay private? This ledger keeps it private, per design §4.
- **L-5** Web search (S-01, S-32 to S-37, S-40; the `web` command): Drop, or lift into a fleet library (for example `simple_web_search`) rather than simple_bible? All of it is stubbed today.
- **L-6** The 134 sourced ANE glosses (SC-38) sit in the vault's bible.db today, which conflicts with bible.db's "nobody's opinions" rule. Move them into Larry's layer (rix.db or the plug-in) for simple_bible?
- **L-7** Prehistory and Traced data (SC-53 to SC-55; tables only in D-03): Migrate into scholars.db before archiving, or leave them in the archive only?
