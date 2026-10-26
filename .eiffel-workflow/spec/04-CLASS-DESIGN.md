# CLASS DESIGN: simple_bible

*Step R04, 2026-10-06. Applies OOSC2 principles to the domain model (02) as changed by the verdicts in 03. Class names are final for the spec; the GUI spec's `SB_*` placeholders map one for one to `BIB_*` (A-009).*

*Fold 2026-10-26: the five gated verdicts (debates 01 to 05) and D-021 are folded into this file in one pass; the GUI is native simple_widgets (D-006, decided 2026-10-06) and every GUI gap work item GW is done (gui/02-GAP-PROGRAM.md, Phase 4 complete 2026-10-26). Every changed or added passage is marked "(fold 2026-10-26, debate NN)" or "(fold 2026-10-26, D-021)"; superseded text is quoted in the Fold log of `00-FOLD-2026-10-26.md`. Locked inputs: decisions are copied, never reopened. The live source classes (`src/data`, `src/user`, `src/plugin`, `src/bib_config.e`) are still the Release 1 skeletons; this file states the target.*

---

## 0. Naming and layering decisions

**Prefix.** `BIB_` for every class except the facade `SIMPLE_BIBLE` (fleet convention: `SIMPLE_<LIB>` is the entry class). `SB_` is rejected because Gobo's storable library defines `SB_*` classes (`gobo-26.06/gobo/library/storable/src/`), and simple_* libraries wrap Gobo. `BIB_` is used by no class in the fleet's root folder, Gobo or the ISE 25.02 libraries (searched 2026-10-06). **C:** zero C planned; if a C helper is ever needed, its prefix is `sbib_` (unused in every `.h`, `.c` and `.e` under the fleet's root folder), and any C that can wait is declared `blocking` (fleet laws).

**Layers and ECF targets** (one repository `simple_bible`, one ECF `simple_bible.ecf`, several targets; no ECF is written in this phase):

| Layer | Target | Root | Clusters | May depend on |
|-------|--------|------|----------|---------------|
| L-LIB engine library | `simple_bible` (library) | none | `src/` | simple_sql, simple_mml, simple_encoding, simple_regex, simple_json, simple_hash, simple_diff, simple_file, simple_toml, simple_logger, simple_datetime |
| L-BUILD build pipeline | `bible_build` (console exe, build machine only) | `BIB_BUILD_APP` | `src/`, `build/` | L-LIB + simple_xml, simple_csv, simple_onnx, simple_graph |
| L-CLI face | `bible` (`bible.exe`) | `BIB_CLI_APP` | `src/`, `cli/` | L-LIB + simple_cli, simple_console |
| L-GUI face | `simple_bible_app` | `BIB_GUI_APP` | `src/`, `gui/` | L-LIB + simple_widgets, simple_shaping, simple_cairo, simple_shell |
| Tests | `simple_bible_tests` | `TEST_APP` | `src/`, `build/`, `cli/`, `test/` (GUI tests offscreen in `test/gui/`) | + simple_testing |
| Private packs (fold 2026-10-26, debate 03; supersedes "Private plug-in: separate private repo and ECF (Larry's), Larry's root registering his plug-in") | no target in Release 1: Larry's export tool (Python allowed; D-020 scope is the shipped product only) writes versioned packs in the public pack schema | none | none | none (the public engine reads packs; it links no private code) |

**Dependency rules (enforced by tests that read the ECF and grep class texts):**
1. L-GUI and L-CLI classes never name a `SIMPLE_SQL_*` type and contain no SQL text (FR-124). They see only `SIMPLE_BIBLE`, engine result types and `BIB_JOB` descendants.
2. L-LIB never names an `SW_*`, `SHELL_*` or console type.
3. L-BUILD is the only layer that writes the build stages (`core.db`, `ai_data.db`, the rix stage) and `history.db`, and the only layer that **assembles `content.db`** from the stages; L-LIB opens `content.db` and every pack read-only; only `BIB_USER_STORE` writes (`user.db`). (fold 2026-10-26, debate 01; supersedes "L-BUILD is the only layer that writes `core.db`, `ai_data.db`, `rix.db` and `history.db`; L-LIB opens them read-only")
4. The public executable contains no private string (K2′: no string from the R-2 list in ASCII, UTF-16LE or UTF-32LE, positive control including a `{STRING_32}` private string) and no private code; there is no plug-in registry and no deferred lens class. (fold 2026-10-26, debate 03; supersedes "The public targets contain no effective descendant of `BIB_LENS` or `BIB_PRIVATE_SOURCE` (FR-NEW-010)")
5. The SQLite binding is `eiffel_sqlite_2025` 1.1.0 (SQLite 3.53.4, `blocking` externals; the patch landed 2026-10-08/09, debate 04 gate item 2) behind the one door `simple_sql`; the Release 1 DDL ceiling stays at 3.31.1 features (RQ-03 option 2). Every dependent is rebuilt with `-clean` after a binding change. (fold 2026-10-26, debate 04)
6. Every provenance check names its schema, packs included. (fold 2026-10-26, debate 01)

## 1. Class Inventory

Release column: R1 = Release 1 (1a/1b split per Q-01 noted where relevant), v1.5, v2, v3. "(d)" = deferred. Harvest column cites the 08-HARVEST-LEDGER row the class lands.

### 1.1 L-LIB: engine library (Release 1: 145 classes + shape family)

**Facade and configuration (2)**

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `SIMPLE_BIBLE` | Facade | Open the sources for one processor and hand out the engines (fold 2026-10-26, debate 05b: also `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup`) | (S-38 replaced) |
| `BIB_CONFIG` | Builder | Database paths (exe-relative, `%LOCALAPPDATA%`, `bible.toml`), options. Fold 2026-10-26: gains `conc_path` (debate 05b); the content path replaces the per-database paths (`ai_data_path`, `rix_path`; debate 01); the plug-in registry is dropped (debate 03); the notes folder becomes the export folder in 1a (debate 02) | S-11, C-01 data-dir logic |

**core: identity and keys (12)**

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `BIB_ENUMERATION` (d) | Base | Closed code set with label and validity | - |
| `BIB_BOOK` | Value | One canonical book (id, code, names) | S-09 |
| `BIB_BOOK_CATALOG` | Lookup | Resolve names/aliases to books; chapter counts per system | S-09 (book resolution), rix R12 alias table |
| `BIB_VERSIFICATION_SYSTEM` | Enumeration | kjv, mt, swete, rahlfs_ccat, vulgate | - |
| `BIB_REF` | Value | Book/chapter/verse/suffix in one system | S-09 |
| `BIB_REF_RANGE` | Value | Start and end references | - |
| `BIB_MAPPED_REF` | Value | Hub id + origin + rules applied (map-created only) | - |
| `BIB_KEY` (d) | Value base | A join/count key (never a display string) | - |
| `BIB_LEMMA_KEY` | Value | Lemma id | - |
| `BIB_STRONGS_KEY` | Value | Strong's number with optional sense suffix | S-09 word-level Strong's |
| `BIB_MORPH_CODE` | Value | Morphology code (OSHB/MACULA) | - |
| `BIB_WORD_ID` | Value | Immutable token id | - |

**provenance and results (12)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_LICENSE` | Value | License id, clauses (NC, SA), credit line, shippability |
| `BIB_PROVENANCE` | Value | Source, edition, license, grade, caveat, AI-made flag and method label |
| `BIB_GRADE` | Enumeration | P1-P4 |
| `BIB_VOICE` | Enumeration | trusted / hold-loosely / cite-exactly / author |
| `BIB_FACT [G]` | Data | One value bound to its provenance |
| `BIB_METHOD` | Data | Canonical query, corpus, versions, rules, counts, engine version, DB edition, SQLite version |
| `BIB_ENGINE_RESULT` (d) | Data base | Method + citations + success xor error |
| `BIB_LIST_RESULT [G]` | Data | Engine result holding an ordered list of items |
| `BIB_ERROR` | Data | Code, message, details |
| `BIB_VERDICT` | Enumeration | FITS, PARTIAL, FAILS, NO_DATA |
| `BIB_FINDING` | Data | Reference, verdict, grounds, near-miss, evidence |
| `BIB_BUCKETED_RESULT [G -> BIB_FINDING]` | Data | The four buckets together |

**data: sources (4)** (fold 2026-10-26, debate 01; was "(5)"; `BIB_AUTHOR_LIBRARY` is listed under author; `BIB_HISTORY_SOURCE` is v2)

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `BIB_DATA_SOURCE` (d) | Base | One database's identity, schema check, provenance access | - |
| one content source (fold 2026-10-26, debate 01; replaces `BIB_CORE_SOURCE` "`core.db` (required, read-only)" and `BIB_AI_DATA_SOURCE` "`ai_data.db` (optional, read-only)", which collapse; the verdict gives no class name) | Source | The one shipped read-only `content.db` (core, AI-made related passages, author library, folded indexes); optional public content is empty tables, so `has_ai_data` becomes a presence count | S-09 schema knowledge |
| `BIB_USER_STORE` | Store | `user.db` (read-write; one writer processor) | C-17 history |
| `BIB_SOURCE_SET` | Coordinator | One connection per processor; main = `content.db`; attaches packs read-only through `attach_read_only` (at most 10 pack slots; fold 2026-10-26, debate 01, debate 05a; was "attaches (at most 10)") | - |

**text (11)**

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `BIB_NORMALIZER` (d) | Strategy | Idempotent search-form normalization | - |
| `BIB_HEBREW_NORMALIZER` | Strategy | Consonantal, final forms folded, marks removed | - |
| `BIB_GREEK_NORMALIZER` | Strategy | NFD (LG-01), marks removed, lowercase, final sigma folded | - |
| `BIB_ENGLISH_NORMALIZER` | Strategy | Lowercase; optional stemming | - |
| `BIB_STEMMER` | Utility | Porter stemmer with exception table | C-18 (as-is) |
| `BIB_STOP_WORDS` | Utility | Stop-word list | C-19 (as-is) |
| `BIB_POINTING_REDUCER` | Utility | Hebrew full / vowels / consonants derived forms | - |
| `BIB_TRANSLITERATOR` | Utility | Transliteration and pronunciation (stress in capitals) | C-01 transliteration |
| `BIB_SCRIPT_CLASSIFIER` | Utility | Script runs (Hebrew, Greek, Latin) in text | - |
| `BIB_EDIT_DISTANCE` | Utility | Levenshtein for fuzzy book/term matching | S-30, X-06 |
| `BIB_NORMALIZER_SET` | Factory | The three normalizers, chosen by script/language; shared by build and query path | - |

**reference (4)**

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `BIB_REFERENCE_PARSER` | Engine | Text to valid/ambiguous/invalid references (FR-020) | S-09 reference parsing |
| `BIB_PARSE_RESULT` | Data | Exactly one of valid, ambiguous, invalid | - |
| `BIB_REFERENCE_DETECTOR` | Engine | Explicit references in free text (rix R12 + scripture_detect explicit) | scripture_detect.py, build_rix_db.py R12 |
| `BIB_QUOTATION_DETECTOR` | Engine | Unnamed quotations by n-gram shingles (min 6) with match length | scripture_detect.py |

**versification (3)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_VERSIFICATION_MAP` | Engine | The only creator of `BIB_MAPPED_REF`; pairing into any system |
| `BIB_MAPPING_RULE` | Data | One rule with provenance |
| `BIB_PAIRING` | Result | Target references + rules + note |

**hub (9)**

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `BIB_VERSE_HUB` | Engine | One verse in every version with words and cross-references (FR-021) | S-09 lookup |
| `BIB_VERSION_INFO` | Data | Version metadata, edition label, caveat, quality caveat | S-09 version resolution |
| `BIB_VERSE_TEXT` | Data | One verse in one version, or an omission; repair state | - |
| `BIB_OMISSION` | Enumeration+data | Edition-omitted, edition-absent, digital-loss, not-in-canon, quarantined | - |
| `BIB_WORD` | Data | Token with keys, morphology (code + English), gloss, transliteration, pronunciation | S-09 word-level Strong's |
| `BIB_VERSE_RESULT` | Result | The hub's answer | - |
| `BIB_CROSS_REFERENCE` | Data | Target, source, votes | S-09 cross-references |
| `BIB_MORPH_EXPANDER` | Utility | Morphology code to English (TEHMC/TEGMC data) | - |
| `BIB_REPAIR_STATE` | Enumeration | as-imported OCR / repaired / collated (Swete, A-001) | - |

**search (11)**

| Class | Role | Single Responsibility | Harvest |
|-------|------|----------------------|---------|
| `BIB_QUERY` | Data | Immutable clause tree + scope | S-28 |
| `BIB_QUERY_CLAUSE` | Data | One node (word, phrase, and/or/not, regex, lemma, strongs, morph) | - |
| `BIB_QUERY_PARSER` | Engine | Query text to clause tree or positioned error (VR-03..05) | - |
| `BIB_SEARCH_SCOPE` | Data | Versions, book range, collection | S-28 facets |
| `BIB_SEARCH_ENGINE` | Engine | FTS5 over the folded index (shipped `content=''`; stage external-content), regex (target text, display or folded, stated), key search; chunked by book (fold 2026-10-26, debate 01; was "FTS5 over normalized columns") | - |
| `BIB_SEARCH_RESULT` | Result | Pages of hits, per-book counts, method | S-29 |
| `BIB_HIT` | Data | Reference, version, display text, hit spans | - |
| `BIB_CONCORDANCE` | Engine | Counts and hits by core key (FR-023; untouched by debate 05b, fold plan conflict 1: its keys are core keys, never conc.db `lemma_id`) | - |
| `BIB_COUNT_TABLE` | Data | Per-book counts and corpus sizes; frequency per 1,000 words | - |
| `BIB_RANK_FUSION` | Utility | Reciprocal rank fusion | S-06, X-04 |
| `BIB_TOKEN_DIFF` | Utility | Word diff over normalized token keys (simple_diff underneath) | - |

**concordance (9)** (new cluster `src/concordance/`; fold 2026-10-26, debate 05b, pathway B "exactly as compiled", PREFERRED, gated 2026-10-26; D-021; sources: the compiled skeletons `debate/05 - Concordance placement and lookups (D-021)/spikes/skeletons/B/new/*.e` and `B/override/simple_bible.e`)

| Class | Role | Single Responsibility (public features, from the skeleton) |
|-------|------|----------------------|
| `BIB_CONC_PACK` | Pack reader | Owns **every** SQL statement against the attached concordance pack (alias `Pack_alias = "conc"`, whichever file it is: conc.db or conc_dist.db). Created with `make (a_sources: BIB_SOURCE_SET)`. Status: `is_available`, `has_corpus (a_code)`, `has_layer (a_layer)` ("lxx", "bsb", "dictionaries"; conc_dist.db may lack some). Access: `edition_label: STRING_32` (title bar and About; the engine never branches on it), `word_entry (a_lemma_id: INTEGER_64): detachable BIB_WORD_ENTRY`, `headwords_for_strongs (a_key: BIB_STRONGS_KEY): BIB_LIST_RESULT [BIB_WORD_ENTRY]` (through `lemma_xref` only), `place_total (a_lemma_id; a_corpus_code): BIB_FACT [INTEGER_64]`, `place_page (a_lemma_id; a_corpus_code; a_offset, a_limit): BIB_LIST_RESULT [BIB_PLACE_ROW]` (one page of the every-place list in token order). Constants `Pack_alias`, `Max_page_size = 200`. Its `sources` is exported only to `{BIB_ENGLISH_INDEX, BIB_VERSE_WORDS, BIB_WORD_LOOKUP}` |
| `BIB_WORD_LOOKUP` | Lookup | The word view: `view (a_lemma_id: INTEGER_64; a_corpus_code): BIB_WORD_VIEW` assembles the heading, the place total and the first page of places from the pack reader, in the approved section order. Created with `make (a_pack)`; `pack` exported (preconditions use it) |
| `BIB_ENGLISH_INDEX` | Lookup | The English lookup: `rows (a_english): BIB_LIST_RESULT [BIB_ENGLISH_ROW]` (an English word to the original words behind it, one row per original word and book, with counts) |
| `BIB_VERSE_WORDS` | Lookup | The verse lookup: `words (a_ref: BIB_REF; a_corpus_code): BIB_LIST_RESULT [BIB_VERSE_WORD]` (every word of the verse in order, each a door to its word view) |
| `BIB_WORD_ENTRY` | Value (`BIB_SOURCED`) | The heading of a word view: `lemma_id`, `language` (hbo, arc, grc), `headword`, `translit`, `pron`, `token_total`, `provenance` |
| `BIB_PLACE_ROW` | Value (`BIB_SOURCED`) | One row of the every-place list: `token_id`, `reference_text`, `surface`, `translit`, `provenance`; optional `meaning` (SDBH or SDGNT), `stem`, and `bsb`, `kjv`, `step` in context (Void when the pack lacks that layer); optional columns set by `set_context` |
| `BIB_ENGLISH_ROW` | Value (`BIB_SOURCED`) | One line of the English lookup: `english`, `lemma_id`, `headword`, `translit`, `book_id`, `count`, `provenance` |
| `BIB_VERSE_WORD` | Value (`BIB_SOURCED`) | One word of a verse: `position`, `surface`, `translit`, `lemma_id` (0 when none), `lemma_basis` (tagged, aligned, xref, none), `provenance`; `has_door` |
| `BIB_WORD_VIEW` | Result (`BIB_ENGINE_RESULT`; creation `make_success`, `make_failure`) | Heading (`entry`), `place_total`, the FIRST page of places (`first_places`), and the ten sections in the approved order: `section_count`, `section_name (i)`, `is_known_section`, `is_present`, `is_in_approved_order`; a section the pack cannot answer is reported absent, not faked; never holds a whole list |

**What the debate rejected or deferred (debate 05b section 5):**
- `BIB_CONCORDANCE` is **untouched** (it keeps core-database counts).
- **No deferred seam now.** A deferred source with core and pack as effectors is raised for one query family only if core.db is built and its `lemma` and `alignment` can answer a headword, place or English query in `lemma_id` terms, or a `lemma_xref` bridge is specified (overturn trigger 1); a second pack needing the same lookups needs a deferred source plus a composite or router (trigger 2). Abstractions wait for a real second implementor (Larry's gate, 2026-10-26).
- **`BIB_HEADWORD_KEY` is NOT adopted** (as skeletoned it inherits `BIB_KEY`, and the live `BIB_CONCORDANCE.count (a_key: BIB_KEY ...)` has no precondition, so it would accept a headword key that core.db cannot answer). Add it only if it does not conform to `BIB_KEY`, or if `count` gains a precondition rejecting it; compile first (queue 1).
- Merging the three lookup classes into `BIB_CONC_PACK` is a Phase 4 choice that needs a compile; the pathway is unchanged.
- Two counters, each stating its key kind and scope: `BIB_CONCORDANCE` (core keys) and `BIB_CONC_PACK.place_total` (`lemma_id`). Where FR-023's headword counts live: **in core, unchanged** (fold plan conflict 1; rekeying is overturn trigger 3).
- Melt-compiled skeletons do not predict runtime, final size or Phase 4 line counts (do not assume 5).

**Builder side (not engine classes):** the conc.db builder (Python, `Scholars/_Tools/`) may stay Python while it builds only the private pack (D-021, D-020 fork 03 item 6). It gains `token.translit` (precomputed; debate 05a fork 4, PREFERRED) and per-corpus counts plus the English-at-a-glance summary per headword (debate 05b addendum). conc_dist.db, which ships, needs an Eiffel builder and a port of the transliteration rules (`BIB_TRANSLITERATOR`) with a differential test against `conc_translit.py` over the 158,342 distinct written forms.

**census (5)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_CENSUS_DEFINITION` | Data (mutable until frozen) | The pre-registered question |
| `BIB_CONTROL_SET` | Engine+data | Deterministic frequency-matched controls |
| `BIB_CENSUS_ENGINE` | Engine | Run a frozen definition version into a run |
| `BIB_CENSUS_RUN` | Result | Four buckets, target vs controls, verdict, method |
| `BIB_CONTROL_COMPARISON` | Data | One control's count against the target |

**shape (8 + family)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_SHAPE` (d) | Strategy base | Definition fields + `classify` |
| `BIB_SHAPE_TIER` | Enumeration | T1, T2, T3 |
| `BIB_SHAPE_REGISTRY` | Registry | Slug to shape |
| `BIB_SHAPE_ENGINE` | Engine | Run a shape (build) and read its evidence (run time); refuses T3 as evidence |
| `BIB_SHAPE_RUN` | Result | Buckets of shape findings, raw candidates, method |
| `BIB_SHAPE_FINDING` | Data | Finding + tier + scale + tag-level evidence |
| `BIB_SHAPE_LINT` | Utility | Port of `shape_db.py lint` (100% FITS suspicious, definition-after-answer flags) |
| `BIB_SHAPE_CANDIDATE` | Value | A candidate reference with the tag-level evidence a shape needs |
| `BIB_SHAPE_<slug>` (family, up to 27) | Strategy | One ported shape each; count fixed at /eiffel.intent after the data-dependency check (A-014) |

**quotation (6)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_QUOTATION_INDEX` | Engine | Indexed NT quotations (UBS seed) by verse |
| `BIB_QUOTATION` | Data | NT, MT, LXX ranges; match kind |
| `BIB_ALIGNMENT` | Data | Precomputed token alignment with marks, method, review state |
| `BIB_AGREEMENT_CLASS` | Enumeration | MT-against-LXX, LXX-against-MT, both, neither, NO_DATA |
| `BIB_QUOTATION_COMPARER` | Engine | Compute the verdict from alignment rows |
| `BIB_QUOTATION_RESULT` | Result | Columns, marks, verdict, edition/OCR note |

**study (13)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_RANGE_VIEWER` | Engine | Renderings of a lemma with counts and examples (I-P09) |
| `BIB_RANGE_RESULT` | Result | Ordered renderings |
| `BIB_WORD_JOURNEY` | Engine | Witnesses in time order with method per row (I-P07) |
| `BIB_JOURNEY_RESULT` | Result | Journey rows |
| `BIB_DIVINE_NAME_MARKER` | Engine | Divine-name spans by key; surface-form for Swete (I-P08) |
| `BIB_GUIDE_ASSEMBLER` | Engine | Passage Guide, Word Study, They Chose, Word's Journey from engine results |
| `BIB_GUIDE` | Result | Ordered sections (no empty sections) |
| `BIB_GUIDE_SECTION` | Data | Section id, title, engine result |
| `BIB_RELATED_PASSAGES` | Engine | Related passages with reasons (core + AI-made rows, read from the one `content.db`; fold 2026-10-26, debate 01; was "core + ai_data") |
| `BIB_RELATED_PASSAGE` | Data | Target, reasons, AI-made label |
| `BIB_LIBRARY` | Engine | Commentary/lexicon/dictionary/devotional entries by verse, lemma, topic, date |
| `BIB_LIBRARY_ENTRY` | Data | Neutral rich-text body + provenance |
| `BIB_PROPER_NAMES` | Engine | TIPNR people and places with references and relations (CLI `people`) |

**user (15)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_USER_ITEM` (d) | Data base | Owner hub id, created/changed dates, id |
| `BIB_NOTE` | Data | Note body (neutral rich text) on a verse or topical |
| `BIB_HIGHLIGHT` | Data | Highlight reason (not a color) on a verse |
| `BIB_BOOKMARK` | Data | Bookmark |
| `BIB_TAG_ASSIGNMENT` | Data | User tag on a verse |
| `BIB_PRAYER_ITEM` | Data | Prayer request with dates and state |
| `BIB_MEMORY_CARD` | Data | Verse to memorize with schedule state |
| `BIB_VISIT` | Data | One history entry (Back/Forward) |
| `BIB_COLLECTION` | Data | Named search scope |
| `BIB_MEMORY_SCHEDULER` | Engine | Spaced-repetition next-due dates (deterministic) |
| `BIB_READING_PLAN` | Engine+data | Plan generation and progress |
| `BIB_NOTE_STORE` (d) | Store seam | Where notes live; panels and CLI see only this (03 A-021) |
| `BIB_DB_NOTE_STORE` | Store | Notes in user.db: **the Release 1a store** (system of record; append-only versions, soft delete, restore). Fold 2026-10-26, debate 02: gains an **export** feature set (one Markdown file per live note, `id` and `hub_id` front matter, id-based or sanitized file names, atomic write, folder created by the exporter, every failure reported) and an **import** feature set (a folder read back as new notes or new versions, never overwriting a row), beside it; the exit snapshot (B′) is added only if its test DS-B′ passes. The verdict names no class for the export and import features; the class home is fixed at Phase 4 |
| `BIB_MARKDOWN_NOTE_STORE` | Store | **The Release 1b candidate** (pathway A″, file-authoritative, UNTESTED, behind its gates; fold 2026-10-26, debate 02; was "Notes as Markdown files in a user folder, indexed into user.db for search and backlinks (13 S5; which store ships first is Q-11)"; Q-11 is answered by Larry's own fallback, "user.db first"). Its conflict path must set `last_error`, or the inherited `body_set` and `history_grown` postconditions fail; the colon trap in `add_note`'s "write `<folder>/<title>.md`" moves here with R9 |
| `BIB_USER_BACKUP` | Utility | Rotating local backup of user data on exit; restore (03 A-022); F-9 item (i) (online backup retries SQLITE_BUSY and LOCKED) has landed in simple_sql `5a17f97` (2026-10-08, with items a to d and f to i, per the debate 02 gate), so the class is no longer blocked by it; it is a skeleton only because Phase 4 has not written it (fold 2026-10-26, settlement S7; was the verdict's section 8.3 "stays a stub until F-9 (i)"); the backup retries BUSY and LOCKED (fold 2026-10-26, debate 02) |

**checks (8)**

| Class | Role |
|-------|------|
| `BIB_CHECK` (d) | One deterministic writing check |
| `BIB_CHECK_FINDING` | Position, rule id, message |
| `BIB_CHECK_RUNNER` | Runs a set of checks over a text |
| `BIB_CHECK_FIRST_USE_GLOSS` | Hebrew/Greek first use has transliteration, pronunciation, gloss |
| `BIB_CHECK_BARE_SCRIPT` | No bare script as the only label |
| `BIB_CHECK_CAPITAL_AFTER_COLON` | Capital after a colon when a sentence follows |
| `BIB_CHECK_CITATION_COMPLETE` | Citations complete |
| `BIB_CHECK_PROVENANCE_TAG` | Provenance tag present on claims |

**author (3)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_AUTHOR_LIBRARY` | Source + engine | The author library (the rix stage's output, shipped inside `content.db`; fold 2026-10-26, debate 01, Larry's gate item 3; was "`rix.db`"): search, documents citing a passage, reader. Its folded index is built the same way beside the untouched R15 tables |
| `BIB_AUTHOR_DOC` | Data | Document with status and voice |
| `BIB_DOC_STATUS` | Enumeration | framework, verdict, draft, unmarked, withdrawn, ungated |

**export (2)**

| Class | Role |
|-------|------|
| `BIB_EXPORTER` | Plain text, Markdown, CSV from engine results with attribution |
| `BIB_ATTRIBUTION` | Attribution lines and share-alike notices from a set of provenances |

**jobs (7)**

| Class | Role | Single Responsibility |
|-------|------|----------------------|
| `BIB_JOB [R -> BIB_ENGINE_RESULT]` (d) | Process | Chunked long work on its own processor |
| `BIB_SEARCH_JOB` | Process | Streams search pages |
| `BIB_CENSUS_JOB` | Process | Runs a census; stores the run in user.db |
| `BIB_GUIDE_JOB` | Process | Builds guide sections one at a time |
| `BIB_CANCEL_TOKEN` | Shared flag | Cancel request (own processor) |
| `BIB_JOB_MAILBOX` | Shared buffer | Progress, pages, completion, error as plain values (own processor) |
| `BIB_JOB_PAGE` | Data | One page of copied rows |

**plugin cluster, now pack cluster (2)** (fold 2026-10-26, debate 03, pathway B′ PREFERRED, adopted 2026-10-06; was "plugin (5)"; debate 03 section 8 says only that "the plugin folder" listing in spec 07 changes, so the folder name is left to spec 07)

| Class | Role | Harvest |
|-------|------|---------|
| ~~`BIB_PLUGIN` (d)~~ | **Dropped** ("Seam: name, version, sources, lenses") | S-16 |
| ~~`BIB_PLUGIN_REGISTRY`~~ | **Dropped** ("Registry of compiled-in plug-ins (empty in public build)") | S-19 |
| `BIB_PRIVATE_SOURCE` | Now an **effective, generic pack source** (was deferred, "Private database attached when present, with voice"): a generic private data pack found by the pack-folder scan, attached read-only, its voice column and `user_version` checked at attach (conc.db is not one: fold 2026-10-26, settlement S6) | S-10 (seam only) |
| ~~`BIB_LENS` (d)~~ | **Dropped** ("A reading applied to a passage"); lens logic runs once per vault export on Larry's machine and arrives as annotation rows in a pack | S-16 |
| `BIB_LENS_RESULT` | Lens output labeled by voice and **pack** name (`plugin_name` becomes the pack name; voice kept) | - |

The public engine must provide the **generic primitives** that read packs (debate 03 "Known costs"): by-verse range overlap, Boolean key search, edit-distance fuzzy match (`BIB_EDIT_DISTANCE`), and multi-source FTS with source labels. The verdict names no host classes for them; library queries (FR-116) and search (B01 to B05) must state that they cover attached packs (debate 03 section 2.3 gap). Voiced results are built through the public `make_success`. `BIB_CONC_PACK` (concordance cluster) is a separate, purpose-built pack reader; it does not pass the generic pack-schema check: conc.db is a concordance pack of its own kind, opened through `BIB_CONC_PACK`'s own check (an expected `user_version` plus the required tables; provenance per corpus and per meaning), and `BIB_CONC_PACK` has no inheritance relation to `BIB_PRIVATE_SOURCE` now (no deferred seam until a real second implementor; Larry, 2026-10-26). conc.db is found by `BIB_CONFIG.conc_path`; generic private packs by the pack-folder scan. Which class holds export, import and the generic pack features is open for Phase 4 (name proposed by the fold where a class is named; fixed in Phase 4) (fold 2026-10-26, settlements S6, G1, G2, G3).

**ai (4)**

| Class | Role |
|-------|------|
| `BIB_AI_ADAPTER` (d) | Explain an engine result (later releases) |
| `BIB_NULL_AI_ADAPTER` | Default; produces no AI text (Release 1) |
| `BIB_AI_TEXT` | Labeled wording; creatable only by the post-check |
| `BIB_AI_POST_CHECK` | FR-053 check and the only creator of `BIB_AI_TEXT` |

### 1.2 L-LIB later releases (18)

| Release | Classes |
|---------|---------|
| v1.5 (7) | `BIB_CLAIM`, `BIB_CLAIM_EXTRACTOR`, `BIB_CLAIM_CHECKER`, `BIB_CLAIM_VERDICT`, `BIB_COMPLETENESS_CHECK` (13 S1 omission check), `BIB_LEDGER_ENTRY`, `BIB_STUDY_LEDGER` |
| v2 (10) | `BIB_HISTORY_SOURCE`, `BIB_HISTORY_EVENT`, `BIB_EVENT_DATE`, `BIB_CERTAINTY_CLASS`, `BIB_DISPUTE`, `BIB_ASTRO_YEAR`, `BIB_TIMELINE`, `BIB_CAPABILITY_PROBE` (S-24), `BIB_QUERY_EMBEDDER`, `BIB_MODEL_BASE` (S-25 as-is) |
| v3 (1) | `BIB_LOCAL_CHAT_ADAPTER` (hidden llama-server via simple_process; loopback via simple_winhttp) |

### 1.3 L-BUILD: build pipeline (Release 1: 44; v2: 2)

| Class | Role | Harvest / reference |
|-------|------|--------------------|
| `BIB_BUILD_APP` | Root: `core`, `rix`, `precompute`, `verify`, `credits` subcommands | - |
| `BIB_BUILD_CONTEXT` | Build date (passed in), manifest, paths, rules version | shape_db.py BUILD_DATE pattern |
| `BIB_BUILD_MANIFEST` | Pinned sources | FR-010 |
| `BIB_PINNED_SOURCE` | One input: URL, commit, file hashes, license, ship/SA flags | 12 checklist |
| `BIB_LICENSE_GATE` | Ship decision, named errors | FR-004 |
| `BIB_BUILD_STEP` (d) | One deterministic stage | C-07 |
| `BIB_DISTRIBUTION_BUILDER` | Runs the steps; checks the build postconditions | - |
| `BIB_SCHEMA_STEP` | core.db DDL (3.31.1-compatible: CHECK, NOT NULL) | - |
| `BIB_BOOK_CATALOG_STEP` | Pinned canonical book table (FR-105) | - |
| `BIB_IMPORT_OSHB` | WLC + MapM + lemma/morph (OSIS XML) | D-09, SC-05 |
| `BIB_IMPORT_MORPHGNT` | SBLGNT + MorphGNT | D-10 |
| `BIB_IMPORT_MACULA_GREEK` | MACULA Greek (TSV) | - |
| `BIB_IMPORT_SWETE` | First1KGreek TEI | 12 |
| `BIB_IMPORT_PLAIN_TEXT_VERSION` | KJV, ASV, YLT, BSB, Tyndale, Vulgate, WH, Wycliffe (per declared format) | - |
| `BIB_IMPORT_STEPBIBLE` | TBESH/TBESG, TIPNR, TEHMC/TEGMC, TVTMS | SC-01, SC-02, SC-03, SC-06 |
| `BIB_IMPORT_STRONGS` | openscriptures Strong's (Moody material stripped) | - |
| `BIB_IMPORT_CROSS_REFERENCES` | OpenBible.info | SC-04, D-12 |
| `BIB_IMPORT_UBS_PARALLELS` | UBS Paratext Parallel Passages (quotation seed) | - |
| `BIB_IMPORT_LIBRARY_MODULE` | Library content packs (format per pack; R1b per Q-01) | - |
| `BIB_SWETE_REPAIR` | Repairs, Sollupulo collation, numbering-gap report, `source_repairs` | 12 |
| `BIB_DEFECT_RULE` | One defect-register item as a rule | - |
| `BIB_DEFECT_RULES_STEP` | Quarantine, caveats, gap flags, protections | Defect register |
| `BIB_NORMALIZE_STEP` | Folded text via the shared normalizers (removes M\* and Cf; stage keeps a stored folded column; fold 2026-10-26, debate 01; was "Normalized columns via the shared normalizers") | - |
| `BIB_VERSIFICATION_STEP` | `versification_map` from TVTMS + vault LXX Jer concordance + Swete entries | - |
| `BIB_FTS_STEP` | FTS5 over the folded text: in the stage, an external-content index over the stored folded column with `integrity-check` required to pass; the shipped index is declared `content=''` (fold 2026-10-26, debate 01; was "FTS5 tables over normalized columns") | - |
| `BIB_ASSEMBLY_STEP` (new; fold 2026-10-26, debate 01: "a new **assembly step** class in `bible_build`"; the verdict gives no class name, name proposed by the fold; fixed in Phase 4) | Writes the shipped `content.db` from the stages: DDL copied verbatim, rows copied, per-table identity with each stage checked both directions (`EXCEPT`, FTS5 shadow tables included, the verified stage index against the shipped contentless index), two builds byte-identical; optional public content shipped as empty tables | - |
| `BIB_TABLE_CHECKSUM` | Ordered per-table SHA-256 | - |
| `BIB_CREDITS_GENERATOR` | Credits file and About text from provenance | FR-003 |
| `BIB_DB_COMPARATOR` | Row-by-row differential compare of two databases | validate_rix_db.py |
| `BIB_COMPARE_SPEC` | Which tables, keys and tolerances to compare (e.g. mtime within 1e-6 s) | validate_rix_db.py FIELDS |
| `BIB_COMPARE_REPORT` | Mismatches, matched-by-key counts, identity verdict | validate_rix_db.py report |
| `BIB_RIX_DB_BUILDER` | rix.db builder (R1-R15) | build_rix_db.py |
| `BIB_RIX_RULES` | Status (R11 v2.1), verse refs (R12), doc id continuity (R13) | build_rix_db.py |
| `BIB_VAULT_WALKER` | Scope (R1) and traversal order (R2) | build_rix_db.py |
| `BIB_VAULT_DOCUMENT` | Parsed vault document (frontmatter, header, body) | S-12, S-27 |
| `BIB_PRECOMPUTE_JOB` (d) | A precompute stage (is a build step) | - |
| `BIB_LEMMA_FREQUENCY_PRECOMPUTE` | Lemma frequencies for controls | - |
| `BIB_GLOSS_TABLE_PRECOMPUTE` | Gloss + pronunciation tables, coverage report | SC-06 |
| `BIB_RELATED_PRECOMPUTE` | Related passages from votes, rare lemmas, neighbors | S-22, S-23 |
| `BIB_EMBEDDING_PRECOMPUTE` | bge-m3 vectors via simple_onnx | S-26 |
| `BIB_ALIGNMENT_PRECOMPUTE` | Quotation alignments (reviewed LXX spans) | - |
| `BIB_SHAPE_PRECOMPUTE` | Runs registered shapes into shape tables | shape_db.py build |
| `BIB_SPARSE_VECTOR` | Sparse TF-IDF vector | S-39 (wip branch, as-is) |
| `BIB_TFIDF_INDEX` | Rare-lemma weighting over verses | S-23 (wip branch) |
| `BIB_PASSAGE_GRAPH` | Cross-reference / shared-lemma graph | S-22 (wip branch) |
| v2: `BIB_HISTORY_BUILDER`, `BIB_HISTORY_GATE` | history.db export and the six ship gates | 11 §5.4, §6 |

### 1.4 L-CLI: CLI/REPL (7 + command family)

| Class | Role | Harvest |
|-------|------|---------|
| `BIB_CLI_APP` | Root: one-shot argv mode and REPL | C-01 |
| `BIB_REPL` | Read-eval-print loop | C-01 |
| `BIB_COMMAND` (d) | One allowlisted read-only command | - |
| `BIB_COMMAND_SET` | Closed set; refuses unknown commands | ledger R-5 |
| `BIB_COMMAND_PARSER` | Splits input into command + arguments | C-06 (as-is) |
| `BIB_TEXT_RENDERER` | Engine results to console text with provenance and method lines | - |
| `BIB_COMMAND_OUTCOME` | Executed / refused / failed, with the rendered text | - |
| `BIB_CMD_<name>` (family, 15) | verse, define, search, compare, etymology, xref, people, list, versions, census, shape, quote, journey, method, credits | C-01 commands |

### 1.5 L-GUI: native face (13 + panel and dialog families)

| Class | Role |
|-------|------|
| `BIB_GUI_APP` | Creates theme, window, engine client, user store; runs |
| `BIB_MAIN_WINDOW` | `SW_WINDOW`, menus, toolbar row, dock host, status bar, accelerators, `app_activity` |
| `BIB_PANEL` (d) | Header row, link chip, four states, `refresh`, `is_stale`, `link_set`, `link_role` (lead / follow / follow-only / independent, 03 A-026), `accessible_name` and `spoken_text` (03 A-027), `required_gaps` |
| `BIB_LINK_HUB` | Active reference per link set; subscriptions; panel sync |
| `BIB_ACTIVE_REFERENCE` | Immutable hub id, origin system, range end, word token |
| `BIB_LAYOUT_STORE` | Per-mode session snapshots and presets (via user store) |
| `BIB_STATE_MACHINE` | Table-driven machine for the JSON regions |
| `BIB_ENGINE_CLIENT` | The GUI's only door: lookup worker (separate `SIMPLE_BIBLE`) + job launch |
| `BIB_RESULT_ADAPTER [R -> BIB_ENGINE_RESULT]` (d) | Result to widget model; enforces provenance/label contracts |
| `BIB_PROVENANCE_CHIP` | `SW_CHIP` + tooltip + Show-method link for one provenance |
| `BIB_JOB_MONITOR` | Polls mailboxes on the heartbeat; sets cancel tokens |
| `BIB_JOB_HANDLE` | GUI-side record of one job: kind, its token and its mailbox |
| `BIB_WORD_CARD` | Word hover/pinned card |
| `BIB_P01_BIBLE_TEXT` ... `BIB_P11_NAVIGATOR` (family, 11 in v1; P12 v1.5; P13, P14 v2) | One panel each |
| `BIB_D01_GO_TO` ... `BIB_D10_AMBIGUOUS_REFERENCE` (family, 9 in v1: D01-D03, D05-D10; D04 v1.5) | One dialog each |

### 1.5a Candidate face: MCP over stdio (Q-12, not in Release 1 counts)

| Class | Role |
|-------|------|
| `BIB_MCP_APP` | Root of a `bible_mcp` target: MCP over stdio (no listening port), each tool call answered by the engine with provenance (13 S6) |
| `BIB_MCP_TOOL_SET` | Maps MCP tools onto `BIB_COMMAND_SET` (same allowlist as the CLI) |

Needs a fleet MCP protocol library (none exists in the fleet's root folder today: LG-06).

### 1.6 Counts by layer

| Layer | Release 1 named classes | Families (Release 1) | Deferred (named) | Later releases |
|-------|-------------------------|----------------------|------------------|----------------|
| L-LIB engine | 145 (before the fold) | shapes (up to 27) | 14 | 18 |
| L-BUILD | 44 (incl. 1 R1b) | - | 2 (`BIB_BUILD_STEP`, `BIB_PRECOMPUTE_JOB`) | 2 |
| L-CLI | 7 | 15 commands | 1 | - |
| L-GUI | 13 | 11 panels + 9 dialogs | 2 | 4 (P12-P14, D04) |
| **Total** | **209** | **up to 62** | **19** | **26** (incl. 2 for the MCP face, Q-12) |

**Fold delta (fold 2026-10-26; arithmetic only, the inventory rows above were not recounted):** L-LIB +9 concordance classes, -1 net for the source collapse (two sources become one), -3 for the dropped plug-in classes (`BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, `BIB_LENS`) = **+5 (150)**; deferred in L-LIB -3 (`BIB_PLUGIN`, `BIB_LENS` dropped, `BIB_PRIVATE_SOURCE` now effective) = **11**; L-BUILD +1 (assembly step) = **45**. Totals after the fold: **215** named classes, **16** deferred. Not counted: the export and import feature set (no class named by debate 02), the generic pack primitives (no host class named by debate 03); which class holds them is open for Phase 4, recorded as a Phase 4 design item, not a decision (fold 2026-10-26, settlement G3). `BIB_MARKDOWN_NOTE_STORE` stays in the L-LIB count but is the 1b candidate (debate 02).

Tests (not counted): `TEST_APP`, `LIB_TESTS` and one `TEST_*` class per cluster, all inheriting `TEST_SET_BASE` (fleet test convention); golden fixtures under `test/fixtures/`.

## 2. Facade Design: SIMPLE_BIBLE

**Purpose:** Single entry point for one processor's use of the engine.
**Responsibility:** Open the configured sources on the current processor, verify them, and hand out the engines; delegate everything else.

```eiffel
class SIMPLE_BIBLE

create
    make

feature -- Configuration
    config: BIB_CONFIG

feature -- Lifecycle (commands)
    open
        -- Open content.db (required) read-only as the main database and attach the packs found in the pack folder, read-only, on this processor.   (fold 2026-10-26, debate 01 and debate 03; was "Open core.db (required) and the optional sources present, read-only, on this processor.")
    close

feature -- Status
    is_open: BOOLEAN
    has_ai_data: BOOLEAN                         -- presence count over the empty-table model, not a file test (fold 2026-10-26, debate 01)
    has_author_library: BOOLEAN                  -- same: a presence count or manifest flag
    has_history: BOOLEAN                         -- v2
    last_error: detachable BIB_ERROR

feature -- Engines (queries; each requires is_open)
    books: BIB_BOOK_CATALOG
    parser: BIB_REFERENCE_PARSER
    versification: BIB_VERSIFICATION_MAP
    hub: BIB_VERSE_HUB
    search: BIB_SEARCH_ENGINE
    concordance: BIB_CONCORDANCE
    census: BIB_CENSUS_ENGINE
    shapes: BIB_SHAPE_ENGINE
    quotations: BIB_QUOTATION_COMPARER
    range_viewer: BIB_RANGE_VIEWER
    journey: BIB_WORD_JOURNEY
    divine_names: BIB_DIVINE_NAME_MARKER
    guides: BIB_GUIDE_ASSEMBLER
    related: BIB_RELATED_PASSAGES
    library: BIB_LIBRARY
    names: BIB_PROPER_NAMES
    author_library: BIB_AUTHOR_LIBRARY           -- requires has_author_library
    checks: BIB_CHECK_RUNNER
    exporter: BIB_EXPORTER
    conc_pack: BIB_CONC_PACK                      -- fold 2026-10-26, debate 05b (once per instance, requires is_open)
    word_lookup: BIB_WORD_LOOKUP                  -- fold 2026-10-26, debate 05b
    english_index: BIB_ENGLISH_INDEX              -- fold 2026-10-26, debate 05b
    verse_word_lookup: BIB_VERSE_WORDS            -- fold 2026-10-26, debate 05b
    -- (removed, fold 2026-10-26, debate 03: "plugins: BIB_PLUGIN_REGISTRY"; the facade's plug-in features are removed before release)

feature -- Convenience (queries delegating to engines)
    verse (a_text: READABLE_STRING_GENERAL): BIB_VERSE_RESULT
        -- Parse, map and look up; ambiguous or invalid text yields a result carrying the parse outcome.
    rerun (a_method: BIB_METHOD): BIB_ENGINE_RESULT
        -- Re-run a recorded method (FR-032).
    credits: STRING_32
        -- Credits text generated from source_provenance (FR-003).
```

**Hides:** `BIB_SOURCE_SET` (connections, attaches), SQL text, schema details, normalizers, the versification rule tables, chunking.

## 3. Engine Designs (representative)

### BIB_VERSIFICATION_MAP (the pairing gate)
```eiffel
class BIB_VERSIFICATION_MAP
feature -- Mapping
    mapped (a_ref: BIB_REF): detachable BIB_MAPPED_REF
        -- The canonical identity of `a_ref`, or Void when the map has no row for it.
    pair (a_mapped: BIB_MAPPED_REF; a_target: BIB_VERSIFICATION_SYSTEM): BIB_PAIRING
        -- What `a_mapped` is called in `a_target`, with the rules used.
feature -- Model
    rules_model: MML_SET [BIB_MAPPING_RULE]
end
```
`BIB_MAPPED_REF` declares `create {BIB_VERSIFICATION_MAP} make`, so no other class can create one; pairing features elsewhere accept only `BIB_MAPPED_REF` (I-003).

### BIB_CENSUS_ENGINE
```eiffel
class BIB_CENSUS_ENGINE
feature -- Execution
    run (a_definition: BIB_CENSUS_DEFINITION; a_token: separate BIB_CANCEL_TOKEN): BIB_CENSUS_RUN
        -- Freeze, run chunk by chunk, return all four buckets; cancelled runs return a result marked cancelled with no findings.
    proposed_controls (a_definition: BIB_CENSUS_DEFINITION): BIB_CONTROL_SET
end
```

### BIB_SHAPE_ENGINE
```eiffel
class BIB_SHAPE_ENGINE
feature -- Evidence (run time)
    evidence (a_shape: BIB_SHAPE): BIB_SHAPE_RUN
        -- All four buckets for `a_shape`; T3 is refused by precondition.
feature -- Execution (build time)
    run (a_shape: BIB_SHAPE; a_corpus: BIB_SEARCH_SCOPE): BIB_SHAPE_RUN
end
```

### BIB_QUOTATION_COMPARER
```eiffel
class BIB_QUOTATION_COMPARER
feature -- Comparison
    compare (a_nt: BIB_MAPPED_REF): BIB_QUOTATION_RESULT
        -- They Chose for the indexed quotation at `a_nt`; NO_DATA when not indexed or not aligned.
end
```

### BIB_SOURCE_SET (fold 2026-10-26, debate 01, debate 03, debate 05a)
```eiffel
class BIB_SOURCE_SET
feature -- Commands
    open_core (a_path: READABLE_STRING_GENERAL)
        -- Open `a_path' (the shipped content.db) read-only as the main database.
    attach (a_alias: STRING_8; a_path: READABLE_STRING_GENERAL)
        -- Attach `a_path' read-only as `a_alias' through SIMPLE_SQL_DATABASE.attach_read_only.
    detach (a_alias: STRING_8)
    close
feature -- Status
    is_attached_alias (a_alias: READABLE_STRING_8): BOOLEAN      -- BIB_CONC_PACK.is_available asks this of Pack_alias
feature -- Constants
    Max_attached: INTEGER = 10                                   -- pack slots only
end
```
- **One main** (`content.db`); `Max_attached` counts **pack slots only**; an attach policy is specified (debate 01 queue 4; an open pack count overflows the limit in any layout, risk R-F1-1; attach #11 reports SQLite's own message).
- **conc.db is a pack** (debate 05a fork 1, ESTABLISHED, confidence 0.90): `BIB_SOURCE_SET.attach` calls `SIMPLE_SQL_DATABASE.attach_read_only` under the alias `conc` (`BIB_CONC_PACK.Pack_alias`). The personal-edition marking follows D-021 and is carried by the pack, not tested by the engine. A write into the attached pack is refused by SQLite ("attempt to write a readonly database"). Overturn: a pack count above the 10-attachment limit, or an attached query more than 20% slower than direct on a future SQLite.
- **Superseded** (fold 2026-10-26): the skeleton's `ATTACH DATABASE 'file:...?mode=ro' AS <alias>` form (`bib_source_set.e`, `attach` body comment and the class note's "ai_data.db, rix.db and private sources are attached read-only"). Debates 01 and 03 dropped that form on the 3.31.1 finding (URI handling off, CANTOPEN), and `attach_read_only` (URI, `mode=ro`, works on read-only connections) landed in simple_sql (5a17f97, 2026-10-08); the attach uses `attach_read_only` (fold 2026-10-26, settlement S1). The class note's FT-02 paragraph ("not yet declared `blocking`... Not patched here") is also stale: the six `blocking` externals landed in eiffel_sqlite_2025 `11f69b9` (debate 04 gate).
- Settled: attach through `SIMPLE_SQL_DATABASE.attach_read_only`. Debates 01 and 03 (2026-10-06) had specified the query path (`query ("ATTACH ...")`, because `execute` has precondition `database_is_writable`) because URI filenames were off on SQLite 3.31.1; debate 05a executed `attach_read_only` on 3.53.4 and SQLite refused writes (fold 2026-10-26, settlement S1).

### BIB_CONFIG (fold 2026-10-26, debates 01 to 05)
| Feature | Change | Source |
|---|---|---|
| `conc_path` | **Added** (the concordance pack's file; "BIB_CONFIG gains `conc_path`"); the route for conc.db, whereas generic private packs are found by the pack-folder scan (fold 2026-10-26, settlement G1) | debate 05b |
| main database path | The per-path setters shrink to the **content path** (`set_ai_data_path` goes; `ai_data_path` and `rix_path` leave) | debate 01 section 8 |
| `plugin_registry`, `set_plugin_registry` | **Removed** (line 39 "drops the plug-in registry from `BIB_CONFIG`"; `make_from_separate` no longer creates a registry) | debate 03 section 8 |
| `ai_data_present`, `rix_present` | Become empty-table presence counts, not file tests | debate 01 section 8 |
| `note_folder`, `set_note_folder` | In 1a an export (and snapshot) folder, outside the vault by default; `set_note_store_folder` moves to 1b | debate 02 section 8.2, gate item 3 |
| pack folder | The folder in which generic private packs are found and attached by `open` (conc.db is not found by this scan: settlement G1); the config feature name is not given by any verdict (name proposed by the fold; fixed in Phase 4) (fold 2026-10-26, settlement G1) | debate 03 section 8 (spec 07 line 89) |

### Concordance cluster (fold 2026-10-26, debate 05b; shapes from the skeletons)
```eiffel
class BIB_CONC_PACK
create make (a_sources: BIB_SOURCE_SET)
feature -- Status
    is_available: BOOLEAN                          -- sources.is_attached_alias (Pack_alias)
    has_corpus (a_code: READABLE_STRING_8): BOOLEAN
    has_layer (a_layer: READABLE_STRING_8): BOOLEAN
feature -- Access
    edition_label: STRING_32
    word_entry (a_lemma_id: INTEGER_64): detachable BIB_WORD_ENTRY
    headwords_for_strongs (a_key: BIB_STRONGS_KEY): BIB_LIST_RESULT [BIB_WORD_ENTRY]
    place_total (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8): BIB_FACT [INTEGER_64]
    place_page (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8; a_offset, a_limit: INTEGER): BIB_LIST_RESULT [BIB_PLACE_ROW]
feature -- Constants
    Pack_alias: STRING_8 = "conc"
    Max_page_size: INTEGER = 200
end

class BIB_WORD_LOOKUP    view (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8): BIB_WORD_VIEW
class BIB_ENGLISH_INDEX  rows (a_english: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_ENGLISH_ROW]
class BIB_VERSE_WORDS    words (a_ref: BIB_REF; a_corpus_code: READABLE_STRING_8): BIB_LIST_RESULT [BIB_VERSE_WORD]
```
Paging rule (debate 05a "Do not assume" 1, 5): the every-place list is never loaded whole (first 200 rows: 25 to 28 ms; whole list up to 0.9 s lean for the Greek article); `ORDER BY` on an unindexed column is not lazy; a cursor left early holds SQLite's read lock, so close it. The shipped build is lean (timing trumps contracts); tests that time reads use `without_contracts`. The first-screen budget risk (NFR-001: the commonest words about 200 ms warm, up to 2.8 s with cold pages, debate 05b addendum) has two remedies named by the verdict: precompute per-corpus counts and the English-at-a-glance summary per headword in the conc.db builder (the orchestrator addendum adds this builder item; overturn: a measured first screen under 200 ms cold for lemma 8 without it), or fill sections asynchronously.

## 4. Data Class Design: results

### BIB_ENGINE_RESULT (deferred)
**Purpose:** The common shape of every answer. **Immutable:** YES.
```eiffel
deferred class BIB_ENGINE_RESULT
feature -- Access
    is_success: BOOLEAN
    error: detachable BIB_ERROR
    method: BIB_METHOD
    citation_count: INTEGER
    citation (i: INTEGER): BIB_PROVENANCE        -- 1 <= i <= citation_count
feature -- Model
    citations_model: MML_SEQUENCE [BIB_PROVENANCE]
invariant
    success_xor_error: is_success xor (error /= Void)
    citation_count_non_negative: citation_count >= 0
    success_is_cited: is_success implies citation_count > 0
end
```

### BIB_BUCKETED_RESULT [G -> BIB_FINDING]
```eiffel
class BIB_BUCKETED_RESULT [G -> BIB_FINDING]
feature -- Access
    count (a_verdict: BIB_VERDICT): INTEGER
    item (a_verdict: BIB_VERDICT; i: INTEGER): G     -- 1 <= i <= count (a_verdict)
    total: INTEGER
    definition_id: INTEGER_64
feature -- Model
    bucket_model (a_verdict: BIB_VERDICT): MML_SEQUENCE [G]
feature {NONE} -- Representation
    fits, partial, fails, no_data: ARRAYED_LIST [G]
invariant
    four_buckets_present: fits /= Void and partial /= Void and fails /= Void and no_data /= Void
    total_consistent: total = fits.count + partial.count + fails.count + no_data.count
    bound_to_definition: definition_id > 0
end
```
There is no feature that returns FITS alone as the whole answer: every bucketed answer is one object that holds all four, and clients reach a bucket only through that object (FR-026). The `count` of every bucket is always defined, including zero.

## 5. Inheritance Hierarchy

```
BIB_ENUMERATION (d)
  ├── BIB_VERSIFICATION_SYSTEM   ├── BIB_GRADE          ├── BIB_VOICE
  ├── BIB_VERDICT                ├── BIB_SHAPE_TIER     ├── BIB_AGREEMENT_CLASS
  ├── BIB_DOC_STATUS             ├── BIB_REPAIR_STATE   └── BIB_OMISSION (adds reason text)

BIB_KEY (d)
  ├── BIB_LEMMA_KEY   ├── BIB_STRONGS_KEY   ├── BIB_MORPH_CODE   └── BIB_WORD_ID

BIB_ENGINE_RESULT (d)
  ├── BIB_VERSE_RESULT      ├── BIB_PAIRING          ├── BIB_SEARCH_RESULT
  ├── BIB_CENSUS_RUN        ├── BIB_SHAPE_RUN        ├── BIB_QUOTATION_RESULT
  ├── BIB_RANGE_RESULT      ├── BIB_JOURNEY_RESULT   ├── BIB_GUIDE
  ├── BIB_WORD_VIEW (fold 2026-10-26, debate 05b)
  ├── BIB_LENS_RESULT       └── BIB_LIST_RESULT [G]   (cross-references, related passages,
                                                       library entries, author docs, names, check findings)

BIB_FINDING
  └── BIB_SHAPE_FINDING

BIB_DATA_SOURCE (d)
  ├── the content source (replaces BIB_CORE_SOURCE and BIB_AI_DATA_SOURCE; fold 2026-10-26, debate 01)   ├── BIB_AUTHOR_LIBRARY
  ├── BIB_USER_STORE    ├── BIB_HISTORY_SOURCE (v2)
  └── BIB_PRIVATE_SOURCE  ── effective, generic pack source (fold 2026-10-26, debate 03; was deferred, "effective classes only in Larry's private repo")

BIB_SOURCED (d)  (live class, src/provenance/bib_sourced.e; fold 2026-10-26, debate 05b)
  └── BIB_WORD_ENTRY, BIB_PLACE_ROW, BIB_ENGLISH_ROW, BIB_VERSE_WORD   (concordance values; `provenance` is an attribute of each)

BIB_NORMALIZER (d)
  ├── BIB_HEBREW_NORMALIZER   ├── BIB_GREEK_NORMALIZER   └── BIB_ENGLISH_NORMALIZER

BIB_SHAPE (d)         └── BIB_SHAPE_<slug> (family)
BIB_CHECK (d)         └── the five effective checks
BIB_USER_ITEM (d)     └── NOTE, HIGHLIGHT, BOOKMARK, TAG_ASSIGNMENT, PRAYER_ITEM, MEMORY_CARD, VISIT
BIB_NOTE_STORE (d)    ├── BIB_DB_NOTE_STORE (1a)   └── BIB_MARKDOWN_NOTE_STORE (1b candidate; fold 2026-10-26, debate 02)
BIB_JOB [R] (d)       ├── BIB_SEARCH_JOB [BIB_SEARCH_RESULT]   ├── BIB_CENSUS_JOB [BIB_CENSUS_RUN]
                      └── BIB_GUIDE_JOB [BIB_GUIDE]
BIB_AI_ADAPTER (d)    └── BIB_NULL_AI_ADAPTER   (v3: BIB_LOCAL_CHAT_ADAPTER)
(removed, fold 2026-10-26, debate 03: "BIB_PLUGIN (d), BIB_LENS (d)  ── effective classes only in Larry's private repo")
BIB_BUILD_STEP (d)    ├── every importer, repair, rule, normalize, versification, FTS, schema step
                      └── BIB_PRECOMPUTE_JOB (d) └── the six precompute stages
BIB_COMMAND (d)       └── BIB_CMD_<name> (family)
BIB_PANEL (d)         └── BIB_P01 ... BIB_P11 (family)
BIB_RESULT_ADAPTER [R] (d) └── one effective adapter per panel content kind (inside the panel family)
```

**Inheritance Justification:**

| Child | Parent | IS-A Valid? | Liskov OK? |
|-------|--------|-------------|------------|
| `BIB_DB_NOTE_STORE`, `BIB_MARKDOWN_NOTE_STORE` | `BIB_NOTE_STORE` | Each stores notes with history and verse keys | YES: same append-only and soft-delete contracts |
| `BIB_VERSE_RESULT` etc. | `BIB_ENGINE_RESULT` | Each is an engine answer with method and citations | YES: adds content, keeps `success_xor_error` |
| `BIB_LIST_RESULT [G]` | `BIB_ENGINE_RESULT` | A list answer is an answer | YES |
| `BIB_SHAPE_FINDING` | `BIB_FINDING` | A shape finding is a finding with tier and evidence | YES: strengthens invariant only (`tier_not_judgment_if_evidence`) |
| `BIB_WORD_VIEW` | `BIB_ENGINE_RESULT` | A word view is an engine answer with method and citations (fold 2026-10-26, debate 05b) | YES: its invariant `success_has_entry`, `success_has_total` and `order_kept` only add to `success_xor_error` |
| `BIB_WORD_ENTRY`, `BIB_PLACE_ROW`, `BIB_ENGLISH_ROW`, `BIB_VERSE_WORD` | `BIB_SOURCED` | Each is a value that carries its own provenance (fold 2026-10-26, debate 05b) | YES: each defines `provenance` as an attribute and keeps it set by its creation postcondition |
| the content source, `BIB_USER_STORE`, etc. (fold 2026-10-26, debate 01; was `BIB_CORE_SOURCE` etc.) | `BIB_DATA_SOURCE` | Each is a database with identity and schema check | YES: `BIB_USER_STORE` redefines `is_read_only` as False; clients of the parent never assume read-write |
| `BIB_HEBREW_NORMALIZER` etc. | `BIB_NORMALIZER` | Each normalizes one script | YES: idempotence postcondition inherited |
| `BIB_SHAPE_<slug>` | `BIB_SHAPE` | Each is a named pattern | YES: `classify` contract inherited (absent tags give NO_DATA) |
| check classes | `BIB_CHECK` | Each is a check | YES |
| user item kinds | `BIB_USER_ITEM` | Each is a record keyed to a hub id | YES |
| job kinds | `BIB_JOB [R]` | Each is chunked cancellable work | YES: `step` contract inherited |
| `BIB_NULL_AI_ADAPTER` | `BIB_AI_ADAPTER` | It is an adapter that never produces text | YES: `explain` returns Void (weaker result allowed by the parent's detachable result) |
| enumerations | `BIB_ENUMERATION` | Each is a closed code set | YES |
| build steps | `BIB_BUILD_STEP` | Each is a deterministic stage | YES |

## 6. Generic Classes

| Class | Type Parameter | Constraint | Purpose |
|-------|----------------|------------|---------|
| `BIB_FACT [G]` | G | `detachable ANY` (values are copied, never `separate`) | A value of any type with provenance |
| `BIB_LIST_RESULT [G]` | G | `ANY` | Ordered list answers of any item type |
| `BIB_BUCKETED_RESULT [G]` | G | `BIB_FINDING` | Census findings and shape findings share the four-bucket law |
| `BIB_JOB [R]` | R | `BIB_ENGINE_RESULT` | Each job produces one result type |
| `BIB_RESULT_ADAPTER [R]` | R | `BIB_ENGINE_RESULT` | GUI adapters typed by the result they lay out |

## 7. SCOOP processor map

| Processor | Objects | Notes |
|-----------|---------|-------|
| GUI (CLI: main) | `BIB_MAIN_WINDOW`, widgets, the one shaping kit, `BIB_LINK_HUB`, `BIB_STATE_MACHINE`, `BIB_JOB_MONITOR` | Never runs SQL; text shaping only here |
| Lookup worker | `separate SIMPLE_BIBLE` (own `BIB_SOURCE_SET`) | Bounded verse-and-word lookups only (< 50 ms p95): verse hub, word card, lexicon, cross-references; the concordance first screen has its own budget (NFR-019; RISK-038), not this one (fold 2026-10-26, settlement S5) |
| Job workers (at most two on 4 cores) | `separate BIB_SEARCH_JOB` / `BIB_CENSUS_JOB` / `BIB_GUIDE_JOB`, each with its own `SIMPLE_BIBLE` | Chunked by book; checks the token between chunks; writes the mailbox |
| One per job: token | `separate BIB_CANCEL_TOKEN` | Set by the GUI, read by the job; never blocked by the job's work |
| One per job: mailbox | `separate BIB_JOB_MAILBOX` | Written by the job, polled by the GUI; holds copied values only |
| User store | `separate BIB_USER_STORE` | The only read-write `user.db` connection; serialized writes |

(The CLI runs single-processor: `SIMPLE_BIBLE` and `BIB_USER_STORE` on the main processor; jobs run inline through `BIB_JOB.run_to_completion`.)

## 8. Class Diagram (core path)

```
┌───────────────────────────────────────────────┐
│ SIMPLE_BIBLE (Facade, one per processor)      │
├───────────────────────────────────────────────┤
│ + make (BIB_CONFIG) / open / close            │
│ + hub / search / concordance / census / ...   │
│ + verse (text): BIB_VERSE_RESULT              │
│ + rerun (BIB_METHOD): BIB_ENGINE_RESULT       │
├───────────────────────────────────────────────┤
│ - sources: BIB_SOURCE_SET                     │
└──────────────┬────────────────────────────────┘
               │ delegates to
               ▼
┌──────────────────────┐   creates   ┌───────────────────────┐
│ BIB_REFERENCE_PARSER │───────────▶ │ BIB_PARSE_RESULT      │
└──────────────────────┘             └──────────┬────────────┘
                                                │ valid BIB_REF
                                                ▼
┌──────────────────────────┐ only creator ┌──────────────────┐
│ BIB_VERSIFICATION_MAP    │────────────▶ │ BIB_MAPPED_REF   │
└──────────┬───────────────┘              └────────┬─────────┘
           │ pair                                  │ required by
           ▼                                       ▼
┌──────────────────┐                ┌──────────────────────────────┐
│ BIB_PAIRING      │◀───── uses ─── │ BIB_VERSE_HUB / QUOTATION /  │
└──────────────────┘                │ CENSUS / SHAPE / SEARCH      │
                                    └──────────────┬───────────────┘
                                                   │ produces
                                                   ▼
                                    ┌──────────────────────────────┐
                                    │ BIB_ENGINE_RESULT (d)        │
                                    │ + method: BIB_METHOD         │
                                    │ + citations: BIB_PROVENANCE* │
                                    │ + is_success xor error       │
                                    └──────────────┬───────────────┘
                                                   │ only input of
                                                   ▼
                     ┌───────────────────────┐  creates  ┌─────────────┐
                     │ BIB_AI_POST_CHECK     │──────────▶│ BIB_AI_TEXT │
                     └───────────────────────┘           └─────────────┘
```
