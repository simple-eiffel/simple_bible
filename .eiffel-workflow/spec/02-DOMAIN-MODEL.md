# DOMAIN MODEL: simple_bible

*Step R02, 2026-10-06. Concepts are taken from the research and the Python reference tools, not invented. Class names use the `BIB_` prefix chosen in R04 (justification there). Where a concept is release-gated, the release is named.*

*Fold 2026-10-26: the five gated verdicts (debates 01 to 05) and D-021 are folded into this file in one pass. Every changed or added passage is marked "(fold 2026-10-26, debate NN)" or "(fold 2026-10-26, D-021)". Locked inputs: the decisions are copied, never reopened. Log: the Fold log of `00-FOLD-2026-10-26.md`.*

---

## Domain Concepts

### A. Identity and reference

### Concept: Book
**Definition:** A canonical book of the Bible or of the Septuagint/deuterocanon, with a stable id.
**Attributes:** canonical id (equal to the vault's `bible_books.id`, FR-105), OSIS-style code, English name, accepted aliases and abbreviations (the rix.db R12 alias table plus the REPL's book resolution), testament/corpus, chapter count per versification system.
**Behaviors:** answers whether a name or alias denotes it; answers its chapter count in a system.
**Related to:** Reference, Versification System, Book Catalog.
**Will become:** `BIB_BOOK` (value), `BIB_BOOK_CATALOG` (lookup).

### Concept: Versification System
**Definition:** A numbering tradition: English/KJV, Hebrew MT, Swete LXX, Rahlfs-CCAT (private build), Vulgate. A reference only means something inside a system.
**Attributes:** code, name.
**Behaviors:** none beyond identity.
**Related to:** Reference, Mapping Rule.
**Will become:** `BIB_VERSIFICATION_SYSTEM`.

### Concept: Reference (raw)
**Definition:** What a user typed or a document wrote, parsed: book, chapter, verse, optional verse suffix (lettered verses such as 3 Kgdms 2:35a; verse 0 for unnumbered titles), in one stated system. Not yet comparable across versions.
**Attributes:** book, chapter, verse, suffix, system; optional range end.
**Behaviors:** ordering within a system; formatting.
**Related to:** Parse Result, Mapped Reference.
**Will become:** `BIB_REF`, `BIB_REF_RANGE`.

### Concept: Parse Result
**Definition:** The outcome of parsing reference text: exactly one of valid, ambiguous (a candidate list) or invalid (an error position and message). The parser never guesses (FR-020).
**Will become:** `BIB_PARSE_RESULT`.

### Concept: Mapped Reference
**Definition:** A reference that has passed through the versification map: it carries the canonical hub id (the verse's identity independent of numbering), the system it came from, and the rule (if any) that was applied. Only mapped references can be paired across versions (I-003).
**Attributes:** hub id, origin reference, rules applied.
**Behaviors:** none (value).
**Related to:** Versification Map, Pairing.
**Will become:** `BIB_MAPPED_REF` (creatable only by the map).

### Concept: Mapping Rule
**Definition:** One row of the versification map: a source range in one system equals a target range in another (offset, split, merge, verse-level alignment, title-as-verse-0 rule), with its provenance (TVTMS, the vault's verified LXX Jeremiah concordance, the Swete entries of 12 §A7).
**Will become:** `BIB_MAPPING_RULE`.

### Concept: Pairing
**Definition:** The result of asking "what is this mapped verse called in system S?": zero, one or several target references and the rules used, plus a human-readable note ("Swete Mal 4:1 = MT Mal 3:19").
**Will become:** `BIB_PAIRING`.

### B. Texts, words and keys

### Concept: Version (edition)
**Definition:** One shipped text: BSB, KJV 1769, ASV, YLT, Tyndale, Clementine Vulgate, Wycliffe, WLC, MapM, SBLGNT, Westcott-Hort, LXX (Swete), and so on.
**Attributes:** code, display label (always with edition for the Septuagint, FR-122), language, script direction, versification system, caveat, license, provenance, has-morphology, canon coverage, text form (diplomatic/eclectic).
**Behaviors:** says whether a book is in its canon.
**Will become:** `BIB_VERSION_INFO`.

### Concept: Verse Text
**Definition:** One verse in one version: exact display text (never edited), or an omission; plus its provenance and repair/quarantine status.
**Will become:** `BIB_VERSE_TEXT`.

### Concept: Omission
**Definition:** Why a verse has no text in a version: omitted by the edition (WH Matt 17:21), absent from the edition (Swete 3 Kgdms 14:1-20, Codex B), lost from the digital text (OCR), not in the version's canon (Tobit in the BSB), quarantined (defect A1). Never an empty string (FR-009, I-005).
**Will become:** `BIB_OMISSION`.

### Concept: Word (token)
**Definition:** One original-language token in a tagged text.
**Attributes:** word id, surface form (exact), normalized form, lemma key, Strong's key (with split sense), morphology code and its English expansion, gloss (orientation only, RISK-017), transliteration, pronunciation, provenance.
**Will become:** `BIB_WORD`.

### Concept: Key (lemma, Strong's, morphology, word id)
**Definition:** The only things the engine joins or counts on (FR-024). A Strong's key may carry a sense suffix (H6743a). A display string is never a key (defect E8). **Fold 2026-10-26, D-021 and debate 05b:** two key spaces exist side by side. Core's keys (`BIB_LEMMA_KEY` is lemma text; Strong's; morphology; word id) key `core.db`/`content.db` and `BIB_CONCORDANCE` (FR-023 stays as is, fold plan conflict 1). The concordance pack's **headword** is keyed by conc.db `lemma_id` (a 64-bit integer), and Strong's reaches it only through `lemma_xref`.
**Will become:** `BIB_KEY` (deferred) with `BIB_LEMMA_KEY`, `BIB_STRONGS_KEY`, `BIB_MORPH_CODE`, `BIB_WORD_ID`.

### Concept: Normalized Form
**Definition:** The search form of a text, built by one shared normalizer at build time and at query time (D-009): Hebrew consonantal with final forms folded and marks removed; Greek decomposed, marks removed, lowercased, final sigma folded; English lowercased. Display never comes from it.
**Behaviors:** `normalize (normalize (s)) = normalize (s)`.
**Fold 2026-10-26, debate 01 (normalization TN-R with storage form R-N4v, PREFERRED, adopted 2026-10-22; verdict section 5.2):** One Eiffel normalizer folds every searchable text simple_bible builds: it removes general categories **M\*** and **Cf**, maps Hebrew finals and the Greek final sigma, and case-folds; the user's query passes through the same normalizer. FTS5 indexes the folded text with `unicode61 remove_diacritics 2`; display text is never read from the index. In the build **stage**, a stored folded column carries an external-content FTS5 index whose `integrity-check` is required to pass. In the shipped `content.db`, the same index is declared `content=''` with its shadow rows copied from the verified stage and identity-checked; no stored folded column ships unless overturn trigger OT-N1 fires. Folded word search finds whole tokens only (a Hebrew word with a clitic prefix needs lemma search). A pack's fold-rule version is declared (see Data Pack).
**Will become:** `BIB_NORMALIZER` (deferred), `BIB_HEBREW_NORMALIZER`, `BIB_GREEK_NORMALIZER`, `BIB_ENGLISH_NORMALIZER`.

### Concept: Cross-reference
**Definition:** A link from a verse to another verse from OpenBible.info (with community votes) or TSK.
**Will become:** `BIB_CROSS_REFERENCE`.

### C. Provenance, facts and results

### Concept: License
**Definition:** The terms a source ships under: identifier (PD, CC0, CC BY 4.0, CC BY-SA 4.0, CC BY-NC 4.0, UNKNOWN ...), clauses beyond attribution (NC, SA), credit line, license-text hash.
**Behaviors:** is it UNKNOWN; may it ship in a free tool (D-002); is it share-alike.
**Will become:** `BIB_LICENSE`.

### Concept: Provenance
**Definition:** Where a fact came from: source key, edition, URL, retrieval date or commit, license, caveat, grade (P1-P4 for timeline and private material), and whether it was AI-made at build time (with model id and method).
**Will become:** `BIB_PROVENANCE`, `BIB_GRADE`.

### Concept: Voice
**Definition:** The trust class of author or private material (`trusted`, `hold-loosely-datum-only`, `evidence-cite-exactly`, D-014) under which a private or author result must be labeled.
**Will become:** `BIB_VOICE`.

### Concept: Fact
**Definition:** One value the engine asserts, bound to its provenance. A fact cannot exist without provenance.
**Will become:** `BIB_FACT [G]`.

### Concept: Method
**Definition:** How a number or a list was produced: query (clause tree in canonical text form), corpus, versions, mapping rules applied, counts, engine version, database edition. Re-running the method yields the same output (FR-032).
**Will become:** `BIB_METHOD`.

### Concept: Engine Result
**Definition:** Any object the engine returns as an answer: it carries a method and its citations (the provenances it rests on), and either content or a structured error.
**Will become:** `BIB_ENGINE_RESULT` (deferred), `BIB_ERROR`.

### D. Measurement

### Concept: Verdict (bucket)
**Definition:** One of FITS, PARTIAL, FAILS, NO_DATA. NO_DATA means the tagging is silent; it is not evidence of absence (FR-027).
**Will become:** `BIB_VERDICT`.

### Concept: Finding
**Definition:** One verse (or word position) classified under a verdict, with grounds, near-miss flag and the tag-level evidence that triggered it (`shape_evidence`).
**Will become:** `BIB_FINDING`, `BIB_SHAPE_FINDING`.

### Concept: Bucketed Result
**Definition:** The four buckets together; a result with fewer than four does not exist (FR-026, I-P03).
**Will become:** `BIB_BUCKETED_RESULT [G -> BIB_FINDING]`.

### Concept: Census Definition
**Definition:** A question written down before counting: question, corpus, criteria (a query clause tree), controls, holds-if, fails-if, version number, control seed. Frozen on first run; edits create a new version (FR-025).
**Will become:** `BIB_CENSUS_DEFINITION`.

### Concept: Control Set
**Definition:** Frequency-matched control words chosen deterministically from lemma frequencies (I-P02); the target must beat its controls for "beats its controls".
**Will become:** `BIB_CONTROL_SET`, `BIB_CONTROL_COMPARISON`.

### Concept: Census Run
**Definition:** The immutable record of running one definition version: the four buckets, target and control counts, the control verdict, the method.
**Will become:** `BIB_CENSUS_RUN`.

### Concept: Shape
**Definition:** A named structural pattern (shape.db): slug, tier, formal and prose definitions, could-fail-if, seeded-by, all written before the run. T1 mechanical, T2 taxonomy-assisted, T3 judgment (never evidence).
**Behaviors:** classify a candidate into a verdict with grounds and evidence.
**Will become:** `BIB_SHAPE` (deferred), `BIB_SHAPE_TIER`, ported effective shapes `BIB_SHAPE_<slug>`, `BIB_SHAPE_REGISTRY`, `BIB_SHAPE_RUN`, `BIB_SHAPE_LINT`.

### E. Comparison and study

### Concept: Quotation
**Definition:** An indexed NT use of the OT (seeded from UBS Paratext Parallel Passages): NT range, MT range, LXX range (Swete, via the map), match kind (exact/partial).
**Will become:** `BIB_QUOTATION`, `BIB_QUOTATION_INDEX`.

### Concept: Alignment
**Definition:** Precomputed token correspondences NT-LXX-MT for one quotation, with per-token agreement marks, method and review state (FR-042).
**Will become:** `BIB_ALIGNMENT`.

### Concept: Agreement Class
**Definition:** "agrees with MT against LXX", "agrees with LXX against MT", "agrees with both", "agrees with neither", or NO_DATA.
**Will become:** `BIB_AGREEMENT_CLASS`.

### Concept: Range of Renderings
**Definition:** Every attested rendering/gloss of a lemma with counts and an example verse, shown before any single "meaning" (I-P09).
**Will become:** `BIB_RANGE_VIEWER`, `BIB_RANGE_RESULT`.

### Concept: Word's Journey
**Definition:** One lemma traced through witnesses in time order with renderings, counts and the method of each row (tagged, verse co-occurrence, NO_DATA) (I-P07).
**Will become:** `BIB_WORD_JOURNEY`, `BIB_JOURNEY_RESULT`.

### Concept: Related Passage
**Definition:** A passage listed as related to a verse, with the signal that produced it: cross-reference with votes, shared rare word, or an AI-made meaning neighbor computed at build time (labeled).
**Will become:** `BIB_RELATED_PASSAGES`, `BIB_RELATED_PASSAGE`.

### Concept: Guide and Section
**Definition:** A page assembled by the engine for a passage or a word; each section is an engine result with provenance; a section without data is omitted.
**Will become:** `BIB_GUIDE_ASSEMBLER`, `BIB_GUIDE`, `BIB_GUIDE_SECTION`.

### Concept: Library Entry
**Definition:** A public-domain commentary comment, lexicon entry, dictionary article or devotional reading keyed by verse, lemma, topic or date, as structured rich text (neutral markup) with provenance.
**Fold 2026-10-26, debate 01 (changed whatever the pathway):** the tables `library_resource` and `library_entry` move into the **pack schema** (see Data Pack); `BIB_LIBRARY_ENTRY.make` gains a voice (debate 03 section 8).
**Will become:** `BIB_LIBRARY`, `BIB_LIBRARY_ENTRY`.

### Concept: Author Document and Status
**Definition:** A document in Larry's author library (`rix.db` `docs`), with a status (framework, verdict, draft, unmarked, withdrawn, ungated) derived by rules v2.1 and verse references (`verse_refs`). Status travels with the document everywhere (D-019).
**Will become:** `BIB_AUTHOR_LIBRARY`, `BIB_AUTHOR_DOC`, `BIB_DOC_STATUS`.

### Concept: Check
**Definition:** A deterministic writing check over text (first-use gloss and pronunciation, bare script, capital after a colon, citation complete, provenance tag) producing findings with positions.
**Will become:** `BIB_CHECK` (deferred), five effective checks, `BIB_CHECK_FINDING`, `BIB_CHECK_RUNNER`.

### Concept: Claim (v1.5)
**Definition:** A checkable assertion extracted from pasted text: a reference, a word claim ("X means Y"), a number claim ("in every book"), a quotation claim; checked by the engine only.
**Will become:** `BIB_CLAIM`, `BIB_CLAIM_EXTRACTOR`, `BIB_CLAIM_CHECKER`, `BIB_CLAIM_VERDICT`.

### F. Search

### Concept: Query
**Definition:** A clause tree: words, phrases, AND/OR/NOT, regex, `lemma:`, `strongs:`, `morph:` clauses, with a scope (versions, book range, collection). The GUI's query builder produces a clause tree; the engine builds its own parameterized SQL and never executes builder-made SQL text (GW-12).
**Will become:** `BIB_QUERY`, `BIB_QUERY_CLAUSE`, `BIB_QUERY_PARSER`, `BIB_SEARCH_SCOPE`.

### Concept: Hit and Count Table
**Definition:** A hit is one verse/version match with character spans in the display text; a count table holds per-book hits and corpus sizes so frequencies per 1,000 words are computed by the engine.
**Will become:** `BIB_HIT`, `BIB_SEARCH_RESULT`, `BIB_COUNT_TABLE`, `BIB_CONCORDANCE`, `BIB_SEARCH_ENGINE`.

### G. Data sources and processes

### Concept: Data Source
**Definition (fold 2026-10-26, debate 01; supersedes "A SQLite database the engine reads: `core.db` (required), `ai_data.db`, `rix.db`, `history.db` (optional), `user.db` (read-write), and private databases through the plug-in"):** The run-time layout is **B-S** (PREFERRED, adopted by Larry 2026-10-22; verdict `debate/01 - Runtime database layout and search normalization (D-015 + D-009)/04 - VERDICT.md`, section 5.1). `core.db`, `ai_data.db` and the rix builder's output (`rix.db`) are **build stages**, not run-time files. One shipped, read-only **`content.db`** is **assembled** from the stages (DDL copied verbatim, rows copied, per-table identity with each stage checked in both directions with FTS5 shadow tables included, two builds from one manifest byte-identical). It carries core, the AI-made related passages, the author library (built by its own stage, Larry's gate item 3) and the folded indexes. Optional public content ships as **empty tables**, never as missing files; presence is a count or a manifest flag. `user.db` stays separate and read-write on the user-store processor only. `history.db` (v2) is folded in or kept separate, decided when v2 is specified. **Packs** (Release 1b libraries, third-party packs, Larry's private packs, and conc.db) attach read-only through `SIMPLE_SQL_DATABASE.attach_read_only` on the read-only main connection (see "Data Pack" below; fold 2026-10-26, settlement S1; was "through the query path"). Generic private packs are found by the pack-folder scan, conc.db by `conc_path` (fold 2026-10-26, settlement G1). Each source has an identity (schema version, required tables) and is opened by one processor only.
**Will become:** `BIB_DATA_SOURCE` (deferred), one content source (replaces `BIB_CORE_SOURCE` and `BIB_AI_DATA_SOURCE`, which collapse; debate 01 section 8, no class name given), `BIB_AUTHOR_LIBRARY`, `BIB_HISTORY_SOURCE`, `BIB_USER_STORE`, `BIB_SOURCE_SET`, `BIB_CONFIG`, and in `bible_build` an assembly step that writes `content.db` from the stages (fold 2026-10-26, debate 01).

### Concept: User Item
**Definition:** The reader's own record keyed to a canonical hub id: note, highlight (a reason, not a color), bookmark, tag assignment, prayer item, memory card; also plan progress, collections, layout snapshots, settings.
**Will become:** `BIB_USER_ITEM` (deferred) and its kinds; `BIB_MEMORY_SCHEDULER`, `BIB_READING_PLAN`.

### Concept: Note Store and Backup (from research/13, T10/T11)
**Definition (fold 2026-10-26, debate 02; supersedes "the user database, or a folder of Markdown files the reader owns (Obsidian-compatible), indexed for search and verse backlinks"):** For Release 1a, `user.db` is the **system of record** for notes (pathway B, PREFERRED, adopted 2026-10-22; verdict `debate/02 - Notes store (RQ-06)/04 - VERDICT.md`, section 5). It is written only by the user-store processor, through `BIB_DB_NOTE_STORE` behind the `BIB_NOTE_STORE` seam. User data is append-only: an edit is a new version, a delete is soft and recoverable (restore). A rotating local backup is taken on exit. The Markdown folder is no longer the store; it is an **export**:
- **Export** (on demand) writes one Markdown file per live note, with `id` and `hub_id` front matter, under an id-based or sanitized file name (never a raw title), by atomic write, into a folder the exporter creates, and reports every failure. **Import** reads a folder back as new notes or new versions, never overwriting a row.
- The default export folder is outside the Obsidian vault, labeled a read-only copy; the reader may point it into the vault (Larry's gate item 3).
- The **exit snapshot** (a plain-text copy of changed notes at each clean exit, B′) is adopted only if its test DS-B′ passes (Larry's gate item 2). A start-time rotating backup after an unclean exit is recommended for test, not adopted untested.
- A **file-authoritative Markdown store** (A″) is the **Release 1b candidate**, UNTESTED, behind its gates (DS-3c first); Q-11's preference for a Markdown store is carried to that gate, not dropped.
- Outside edits to an export are never read back unless imported (risk R-F2-2).
**Will become:** `BIB_NOTE_STORE` (deferred), `BIB_DB_NOTE_STORE` (1a default) with an export and import feature set, `BIB_MARKDOWN_NOTE_STORE` (the 1b candidate), `BIB_USER_BACKUP` (not blocked by F-9 item (i), which has landed in simple_sql 5a17f97, 2026-10-08) (fold 2026-10-26, debate 02, settlement S7; was "a stub until F-9 item i lands").

### Concept: Job
**Definition:** Long engine work (search, census, guide, precompute) running on its own SCOOP processor in chunks, reporting progress and pages through a mailbox, stoppable through a cancel token. A cancelled job produces no findings.
**Will become:** `BIB_JOB` (deferred), `BIB_SEARCH_JOB`, `BIB_CENSUS_JOB`, `BIB_GUIDE_JOB`, `BIB_CANCEL_TOKEN`, `BIB_JOB_MAILBOX`, `BIB_JOB_PAGE`.

### Concept: Pack, Private Pack, Lens Annotation
**Definition (fold 2026-10-26, debate 03; supersedes the concept "Plug-in, Private Source, Lens": "a plug-in registers private sources ... and lenses ... without the public build containing any of them"):** There is **no private code seam in Release 1** (pathway B′, PREFERRED, adopted 2026-10-06; verdict `debate/03 - Private plug-in seam (D-014)/04 - VERDICT.md`, section 5). Private material arrives as versioned **data packs** in the published schema. A **private pack** is a pack whose material is Larry's own (scholars, transcripts, primary evidence, lens annotations, `machine_generated.db`, and the concordance database conc.db); it is not public in 1a. A **lens annotation** is a row written by the lens logic (the five frame lenses, graph analytics, and KACC scoring once it exists), which runs **once per vault export** on Larry's machine. It carries a `NOT NULL` voice column and a `provenance_key`, keyed to passages through reference rows (with their versification declared). The public engine runs no private code and no rule interpreter: it finds packs by folder, attaches each read-only, and builds voiced results through the public `make_success`. Lens results are snapshots, current as of the last export.
**Will become:** `BIB_PRIVATE_SOURCE` (an effective, generic pack source), `BIB_LENS_RESULT` (keeps its voice; `plugin_name` becomes the pack name). Dropped: `BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, the deferred `BIB_LENS` (fold 2026-10-26, debate 03).

### Concept: Data Pack (fold 2026-10-26, debate 03 and debate 01)
**Definition:** A read-only SQLite file in the **public, documented pack schema** (a free tool; the schema holds nothing private; third parties may build packs; Larry's gate item 5). This is the schema of the **generic private data pack** (`BIB_PRIVATE_SOURCE`): it declares `user_version` (checked at open) and a fold-rule version; every row names its provenance (`provenance_key`); a private pack also carries a voice column. There are **two pack kinds**: the concordance pack conc.db is not checked by this schema check; `BIB_CONC_PACK` opens it through its own check (an expected `user_version` plus the required tables), and its provenance is per corpus (`corpus.license`, `ship_class`) and per meaning (`meaning_source`) (fold 2026-10-26, settlement S6). `BIB_CONC_PACK` does not inherit from `BIB_PRIVATE_SOURCE` now: no deferred seam until a real second implementor exists (fold 2026-10-26, settlement G2). conc.db is found by `BIB_CONFIG.conc_path`; generic private packs are found by the pack-folder scan (fold 2026-10-26, settlement G1). A pack's folded search index must come from the Eiffel normalizer (the published pack builder) or pass the published fold-parity fixture; a third-party pack that fails the fixture is **attached and labeled "not diacritic-safe"**, not refused (debate 01 gate item 4). `library_resource` and `library_entry` (Library Entry, above) live in the pack schema. Packs attach read-only on a read-only main connection. The attach goes through simple_sql's `SIMPLE_SQL_DATABASE.attach_read_only` (simple_sql 5a17f97, 2026-10-08). Debates 01 and 03 (2026-10-06) had said "through the query path, never through a `file:` URI" because URI filenames were off on SQLite 3.31.1; debate 05a executed `attach_read_only` on 3.53.4 and SQLite refused writes (fold 2026-10-26, settlement S1). Which class holds export, import and the generic pack features is open for Phase 4 (fold 2026-10-26, settlement G3). Each provenance check names its schema, packs included. At most 10 packs per connection (SQLite limit; attach #11 fails and must report SQLite's own message). Pack results are reachable by the generic public features (by-verse range overlap, Boolean key search, edit-distance fuzzy match, multi-source FTS with source labels).
**Will become:** `BIB_SOURCE_SET` (attaches), `BIB_PRIVATE_SOURCE`, and for the concordance `BIB_CONC_PACK` (below).

### Concept: AI Text (later releases)
**Definition:** Wording produced by a model from one engine result, labeled as AI, post-checked so it introduces no digit, reference or Hebrew/Greek string the engine result did not contain.
**Will become:** `BIB_AI_ADAPTER` (deferred), `BIB_NULL_AI_ADAPTER`, `BIB_AI_TEXT`, `BIB_AI_POST_CHECK`, `BIB_CAPABILITY_PROBE`.

### H. The build

### Concept: Pinned Source and Manifest
**Definition:** One upstream input (URL, commit or release, per-file SHA-256, license and license-text hash, ship flag, share-alike flag) and the manifest of all of them.
**Will become:** `BIB_PINNED_SOURCE`, `BIB_BUILD_MANIFEST`.

### Concept: License Gate
**Definition:** The build's refusal to ship UNKNOWN-license sources and its record of NC/SA clauses.
**Will become:** `BIB_LICENSE_GATE`.

### Concept: Build Step, Build Context
**Definition:** One deterministic stage of the distribution build (import, repair, defect rules, normalization, versification, FTS, checksums, credits) with progress and errors; the context carries the build date passed in (no clock reads), the manifest and the output paths.
**Will become:** `BIB_BUILD_STEP` (deferred), `BIB_BUILD_CONTEXT`, `BIB_DISTRIBUTION_BUILDER`, importer steps, `BIB_SWETE_REPAIR`, `BIB_DEFECT_RULE`, `BIB_CREDITS_GENERATOR`, `BIB_TABLE_CHECKSUM`.

### Concept: Repair, Quarantine, Defect Rule
**Definition:** A recorded change to imported data (`source_repairs`), a row moved aside with reason and date (`quarantine`), and a rule carrying one defect-register item into the build (fix, caveat, gap flag, protection).
**Will become:** `BIB_DEFECT_RULE`, rows written by `BIB_DEFECT_RULES_STEP` and `BIB_SWETE_REPAIR`.

### Concept: Differential Test
**Definition:** Row-by-row comparison of two SQLite databases (the Python reference output against the Eiffel port), the Eiffel port of `validate_rix_db.py` generalized to any table set.
**Will become:** `BIB_DB_COMPARATOR`.

### I. Timeline (v2)

### Concept: Event, Event Date, Certainty Class, Dispute, Astronomical Year
**Definition:** A historical event with dates as ranges in astronomical years (no year zero ever displayed), the original date expression kept word for word, a certainty class A-G, a status (verified, disputed, unverified, fails, withdrawn), assertions by graded sources, and disputes drawn as all positions inside an envelope with an optional labeled lean (11 §5).
**Will become:** `BIB_HISTORY_SOURCE`, `BIB_HISTORY_EVENT`, `BIB_EVENT_DATE`, `BIB_CERTAINTY_CLASS`, `BIB_DISPUTE`, `BIB_ASTRO_YEAR`, `BIB_TIMELINE`; build side `BIB_HISTORY_BUILDER`, `BIB_HISTORY_GATE`.

### J. Faces

### Concept: Active Reference and Link Set (GUI)
**Definition:** One active reference per link set (A, B, C; Off pins a panel): hub id, origin system, optional range end, optional word token. Panels in a set follow it (GUI §4). Each panel also has a link role: lead, follow, follow-only (follows, but its own scrolling never moves the set: the most repeated desktop wish in research/13 T13) or independent.
**Will become:** `BIB_ACTIVE_REFERENCE`, `BIB_LINK_HUB`.

### Concept: Command (CLI)
**Definition:** One allowlisted REPL/one-shot command (closed set, read-only).
**Will become:** `BIB_COMMAND`, `BIB_COMMAND_SET`, `BIB_COMMAND_PARSER`.

### K. Concordance (fold 2026-10-26, D-021 and debate 05)

*Source: D-021 (`research/04-DECISIONS.md`), research/14 sections 1 to 3 and 6, debate 05a (ESTABLISHED fork 1, PREFERRED fork 4) and debate 05b (pathway B, PREFERRED; all gated 2026-10-26). The concordance is read from conc.db, a 1.23 GB research database that is NOT core.db. Release order (D-021): the personal concordance edition comes before the public Release 1a; the target user of the public release (D-003) is unchanged. Larry's rules (research/14 section 1) are domain rules DR-027 to DR-029 below.*

### Concept: Headword (fold 2026-10-26, D-021, debate 05b)
**Definition:** The unit a concordance entry is about: one row of conc.db `lemma` (44,934 rows), identified by its own `lemma_id` (a positive 64-bit integer), never by a Strong's number. Strong's numbers live only in `lemma_xref` (Strong's, OSHB, Louw-Nida), reached through `BIB_CONC_PACK.headwords_for_strongs`, which returns candidates, never "the best". A headword has a language (`hbo` Hebrew, `arc` Aramaic, `grc` Greek), the written headword, a transliteration (SBL style), a pronunciation (stress in capitals, for example KHEH-sed), and a token total (`n_tokens`).
**Is not:** the core `BIB_LEMMA_KEY`. The live `BIB_LEMMA_KEY` is lemma text; the pack's `lemma_id` is a different key space (debate 05b "Do not assume" 2). Core's FR-023 counts stay keyed in core (conflict 1 of the fold plan; rekeying FR-023 is 05b overturn trigger 3 and needs a new debate).
**Will become:** `BIB_WORD_ENTRY` (value; `lemma_id: INTEGER_64`).

### Concept: Place (fold 2026-10-26, debate 05b)
**Definition:** One occurrence of a headword in one corpus: one conc.db `token` (4,489,800 rows). It carries the reference text, the whole written word, its transliteration (precomputed in the builder as `token.translit`, debate 05a fork 4), the meaning for this place (SDBH or SDGNT) or the Hebrew stem, and the English in context from the BSB, KJV and STEP layers (Void when the pack lacks that layer). Its license travels in its provenance (`corpus.ship_class`). The every-place list is in token order and is **paged** (first page of 200 rows; the whole list of the Greek article in the Septuagint is 88,444 rows, the Hebrew "and" 50,272).
**Will become:** `BIB_PLACE_ROW` (value).

### Concept: English Row (fold 2026-10-26, debate 05b)
**Definition:** One line of the English lookup: an English word, one original-language word behind it (a candidate, never "the best"), the book it occurs in, and a count. The lookup runs from an English word to the Hebrew or Greek words behind it, Bible by Bible, with counts (the pilot's "English index"; 12,965 planned English headwords).
**Will become:** `BIB_ENGLISH_ROW` (value).

### Concept: Verse Word (fold 2026-10-26, debate 05b)
**Definition:** One word of a verse in the verse lookup: its position, the written form, its transliteration, and the headword it is a door to (none when the lemma basis is "none"). `lemma_basis` records how the headword was reached: `tagged`, `aligned`, `xref` or `none`. Every word with a headword opens its word view.
**Will become:** `BIB_VERSE_WORD` (value), listed by `BIB_VERSE_WORDS`.

### Concept: Word View (fold 2026-10-26, D-021, debate 05b, research/14 section 3)
**Definition:** The concordance entry for one headword. It holds the heading (a word entry), the total of places, the first page of the every-place list, and ten sections in the approved order: 1 heading (transliteration, Hebrew or Greek, pronunciation), 2 how often (in plain words, with Hebrew stems or Greek editions), 3 English at a glance (what the BSB, KJV and STEP use, with counts), 4 what the dictionaries say (each source as a candidate, side by side), 5 through the centuries (counts per writing and per 10,000 words; for Greek, LSJ meanings by five periods), 6 one short callout (at most one), 7 every place, 8 the Greek Old Testament (Septuagint places with Brenton's English for Greek words; the Greek column for Hebrew words), 9 going further (`see_also`), 10 notes. A section the pack cannot answer (for example the Septuagint in conc_dist.db) is reported absent, never faked. The view never holds a whole every-place list; later pages come from the place-page query. Phrase entries exist in the reference design ("Son of Man": head word, an optional article, second word).
**Will become:** `BIB_WORD_VIEW` (result), assembled by `BIB_WORD_LOOKUP`.

### Concept: Concordance Pack (fold 2026-10-26, D-021, debate 05a fork 1, debate 05b)
**Definition:** conc.db (personal edition) or conc_dist.db (distribution edition), attached read-only to the engine's read-only connection under the alias `conc`; it stays its own file (ESTABLISHED against folding it into content.db: attaching costs nothing measurable, folding 1.23 GB of research-only layers would break D-021 and debate 03's B′). One reader class owns every SQL statement against it. Shape: corpus, work, unit (chapter, verse, sub, recension), token; `link` (English to original word links and Masoretic to Septuagint links), `lemma`, `lemma_spelling`, `lemma_xref`, `lex_sense` and `lex_sense_ref`, `period_text` and its counts, `see_also`. Corpora and their license class (`corpus.ship_class`): Hebrew Bible WLC-MACULA, Greek NT NT-MACULA, WH1881, LXX-RAHLFS (research only; never ships), ENG-BSB (text public domain; the per-word tables need Berean's permission), ENG-KJV, ENG-STEP, ENG-BRENTON (text ships; its links to the Septuagint are research only). The pack lists which corpora and layers it carries (the Septuagint, the BSB layer, the dictionaries); the engine asks, and never branches on which edition it is.
**Counters:** two, each stating its key kind and scope: `BIB_CONCORDANCE` (core keys) and `BIB_CONC_PACK.place_total` (`lemma_id`) (debate 05b section 8).
**Will become:** `BIB_CONC_PACK`, with the lookups `BIB_WORD_LOOKUP`, `BIB_ENGLISH_INDEX`, `BIB_VERSE_WORDS`.

### Concept: Edition (personal and distribution) (fold 2026-10-26, D-021)
**Definition:** Two editions of the same public engine plus a concordance pack.
| Edition | Reads | Marking | Meanings | Status |
|---|---|---|---|---|
| **Personal** | conc.db as is, including its research-only layers (CATSS Rahlfs LXX; BSB per-word tables) | "PERSONAL EDITION - not for distribution" in the title bar and the About window; never published | Shows the SDBH and SDGNT meanings that conc.db holds (D-021, later than D-012; fold plan conflict 2) | Comes first, before public Release 1a |
| **Distribution** | conc_dist.db only (not yet built; blockers in research/14 section 6: Swete lemmas as in D-011, Berean's confirmation, permission letters) | Credits from the pack's own `notice` table in Help, About, listed beside the engine's `source_provenance` credits, both generated (fold 2026-10-26, settlement S4) | May carry SDBH and SDGNT meanings (CC BY-SA 4.0 as a whole) when conc_dist.db exists | Later; needs an Eiffel builder with a differential test against the Python builder |
The public Release 1a keeps D-012 (no Hebrew semantic layer in the MVP) as decided. The engine never tests which edition it is running (05b overturn trigger 4: an edition test in engine code breaks K3 in any pathway and is removed); the edition is what the attached pack says it is (`BIB_CONC_PACK.edition_label`).

## Concept Relationships

```
BIB_BOOK_CATALOG ---- has-many ----> BIB_BOOK
BIB_REF ---- has-a ----> BIB_BOOK, BIB_VERSIFICATION_SYSTEM
BIB_VERSIFICATION_MAP ---- creates ----> BIB_MAPPED_REF            (only creator)
BIB_VERSIFICATION_MAP ---- has-many ----> BIB_MAPPING_RULE
BIB_MAPPED_REF ---- paired-by ----> BIB_PAIRING (target BIB_REF list + rules)
BIB_VERSE_RESULT ---- is-a ----> BIB_ENGINE_RESULT
BIB_VERSE_RESULT ---- has-many ----> BIB_VERSE_TEXT ---- has-a ----> BIB_VERSION_INFO
BIB_VERSE_TEXT ---- may-have ----> BIB_OMISSION
BIB_VERSE_TEXT ---- has-many ----> BIB_WORD ---- has ----> BIB_LEMMA_KEY, BIB_STRONGS_KEY, BIB_MORPH_CODE
BIB_FACT [G] ---- has-a ----> BIB_PROVENANCE ---- has-a ----> BIB_LICENSE, BIB_GRADE
BIB_ENGINE_RESULT ---- has-a ----> BIB_METHOD; has-many ----> BIB_PROVENANCE (citations)
BIB_CENSUS_DEFINITION ---- has-a ----> BIB_QUERY (criteria), BIB_CONTROL_SET
BIB_CENSUS_RUN ---- is-a ----> BIB_ENGINE_RESULT; has-a ----> BIB_BUCKETED_RESULT [BIB_FINDING]
BIB_SHAPE_RUN ---- is-a ----> BIB_ENGINE_RESULT; has-a ----> BIB_BUCKETED_RESULT [BIB_SHAPE_FINDING]
BIB_SHAPE_FINDING ---- is-a ----> BIB_FINDING
BIB_SHAPE_<slug> ---- is-a ----> BIB_SHAPE
BIB_QUOTATION ---- has-a ----> BIB_ALIGNMENT; compared-by ----> BIB_QUOTATION_COMPARER
BIB_QUOTATION_RESULT ---- has-a ----> BIB_AGREEMENT_CLASS
BIB_GUIDE ---- has-many ----> BIB_GUIDE_SECTION ---- has-a ----> BIB_ENGINE_RESULT
BIB_AUTHOR_DOC ---- has-a ----> BIB_DOC_STATUS, BIB_VOICE
BIB_SOURCE_SET ---- has-many ----> packs (attached read-only; at most 10 pack slots per connection; main = content.db)   (fold 2026-10-26, debate 01; supersedes "has-many BIB_DATA_SOURCE (attached; at most 10 per connection)")
the content source (replaces BIB_CORE_SOURCE and BIB_AI_DATA_SOURCE), BIB_AUTHOR_LIBRARY, BIB_HISTORY_SOURCE, BIB_USER_STORE ---- is-a ----> BIB_DATA_SOURCE   (fold 2026-10-26, debate 01)
BIB_PRIVATE_SOURCE ---- is-a ----> BIB_DATA_SOURCE          (effective, generic pack source; fold 2026-10-26, debate 03; supersedes "deferred; private repo implements")
(removed, fold 2026-10-26, debate 03: "BIB_PLUGIN ---- has-many ----> BIB_PRIVATE_SOURCE, BIB_LENS")
SIMPLE_BIBLE ---- owns ----> BIB_CONC_PACK, BIB_WORD_LOOKUP, BIB_ENGLISH_INDEX, BIB_VERSE_WORDS   (fold 2026-10-26, debate 05b)
BIB_CONC_PACK ---- reads (alias "conc") ----> BIB_SOURCE_SET        (one reader owns every pack SQL statement)
BIB_WORD_LOOKUP, BIB_ENGLISH_INDEX, BIB_VERSE_WORDS ---- use ----> BIB_CONC_PACK
BIB_WORD_LOOKUP ---- creates ----> BIB_WORD_VIEW ---- has-a ----> BIB_WORD_ENTRY, place total (BIB_FACT), first page (BIB_LIST_RESULT [BIB_PLACE_ROW])
BIB_ENGLISH_INDEX ---- returns ----> BIB_LIST_RESULT [BIB_ENGLISH_ROW];  BIB_VERSE_WORDS ---- returns ----> BIB_LIST_RESULT [BIB_VERSE_WORD]
BIB_WORD_ENTRY, BIB_PLACE_ROW, BIB_ENGLISH_ROW, BIB_VERSE_WORD ---- is-a ----> BIB_SOURCED (carry provenance);  BIB_WORD_VIEW ---- is-a ----> BIB_ENGINE_RESULT
BIB_VERSE_WORD ---- door-to ----> BIB_WORD_VIEW (by lemma_id)
BIB_JOB ---- uses ----> BIB_CANCEL_TOKEN (separate), BIB_JOB_MAILBOX (separate)
BIB_SEARCH_JOB, BIB_CENSUS_JOB, BIB_GUIDE_JOB ---- is-a ----> BIB_JOB
BIB_AI_POST_CHECK ---- creates ----> BIB_AI_TEXT                (only creator)
BIB_AI_TEXT ---- rests-on ----> BIB_ENGINE_RESULT
BIB_DISTRIBUTION_BUILDER ---- runs ----> BIB_BUILD_STEP (importers, repairs, rules, normalize, versification, FTS, checksums, credits)
BIB_BUILD_STEP ---- reads ----> BIB_BUILD_CONTEXT ---- has-a ----> BIB_BUILD_MANIFEST ---- has-many ----> BIB_PINNED_SOURCE
BIB_LICENSE_GATE ---- judges ----> BIB_PINNED_SOURCE
SIMPLE_BIBLE (facade) ---- owns ----> BIB_SOURCE_SET and every engine
BIB_ENGINE_CLIENT (GUI) ---- uses ----> separate SIMPLE_BIBLE (lookup worker), BIB_JOB (job workers)
BIB_PANEL ---- subscribes-to ----> BIB_LINK_HUB ---- holds ----> BIB_ACTIVE_REFERENCE (per link set)
```

## Domain Rules

| Rule | Description | Enforcement |
|------|-------------|-------------|
| DR-001 | Every fact carries provenance | `BIB_FACT` creation requires an attached provenance; `BIB_ENGINE_RESULT` invariant `has_method`; build postcondition `all_rows_have_provenance` |
| DR-002 | No shipped source has license UNKNOWN | `BIB_LICENSE_GATE.ship_allowed` postcondition; `BIB_DISTRIBUTION_BUILDER.build` postcondition `no_unknown_license_shipped` |
| DR-003 | Cross-version pairing only through the versification map | `BIB_PAIRING` and `pair` take `BIB_MAPPED_REF`; `BIB_MAPPED_REF` creation exported only to `BIB_VERSIFICATION_MAP` |
| DR-004 | Census and shape results carry all four buckets | `BIB_BUCKETED_RESULT` invariant `four_buckets_present` (all attached; void-safety); no feature returns one bucket as a result list without the others |
| DR-005 | NO_DATA is not FAILS | `BIB_VERDICT` distinct values; shapes and census classify absent tags as NO_DATA (postcondition `absent_tag_is_no_data` on classify) |
| DR-006 | A census definition is frozen after its first run | `set_*` require `not is_frozen`; `run` ensures `definition.is_frozen`; `new_version` creates version + 1 unfrozen |
| DR-007 | T3 shapes never returned as evidence | `BIB_SHAPE_ENGINE.evidence` require `not a_shape.tier.is_judgment` |
| DR-008 | Joins and counts by keys only | Concordance/search features take `BIB_KEY` descendants; static SQL check in tests. Fold 2026-10-26, debate 05b: the pack reader's features take `lemma_id: INTEGER_64`; `BIB_HEADWORD_KEY` is **not adopted** (as skeletoned it would inherit `BIB_KEY`, and `BIB_CONCORDANCE.count` has no precondition rejecting it); no display-string joins in `BIB_CONC_PACK` (FR-024 static check, queue 4) |
| DR-009 | Display text never edited; normalized text never displayed | `BIB_VERSE_TEXT.display_text` has no setter; normalized forms live only in the search path |
| DR-010 | Normalization is idempotent | `BIB_NORMALIZER.normalized` postcondition `idempotent` |
| DR-011 | Never a bare "LXX" | `BIB_VERSION_INFO` invariant `septuagint_labeled_with_edition` |
| DR-012 | AI-made data always labeled; AI never a source | `BIB_RELATED_PASSAGE` invariant `ai_made_has_label`; `BIB_AI_TEXT` creatable only by `BIB_AI_POST_CHECK` from an engine result with at least one citation |
| DR-013 | Author documents always carry status | `BIB_AUTHOR_DOC` invariant `status_valid`; withdrawn excluded from search unless requested (`search` precondition-free flag, postcondition `withdrawn_only_if_requested`) |
| DR-014 | Partial job results are never findings | `BIB_JOB.result` require `is_done and not is_cancelled` |
| DR-015 | Every number re-runs to itself | `BIB_METHOD` carries the canonical query; `SIMPLE_BIBLE.rerun (method)` ensures equal counts on an unchanged database |
| DR-016 | Builds are deterministic | No clock reads in builders: build date is a `BIB_BUILD_CONTEXT` argument; every export `ORDER BY` a key; per-table checksums compared |
| DR-017 | Quarantined refs answer NO_DATA, never foreign text | `BIB_VERSE_TEXT` omission kind `quarantined`; verse hub postcondition |
| DR-018 | Private material labeled by voice; public build contains no private code (fold 2026-10-26, debate 03; supersedes "public build contains no lens", enforced by "build check that the public target has no effective `BIB_LENS`") | `BIB_LENS_RESULT` invariant `voice_attached` (kept); K2′ replaces the lens-descendant build check: the finalized public executable contains no string from the R-2 list in ASCII, UTF-16LE or UTF-32LE, with a positive control that includes a `{STRING_32}` private string; the pack voice column is checked at attach (an unlabeled private result in a fixture run = 0, K4) |
| DR-019 | One SQLite connection per SCOOP processor; never passed between processors | `BIB_SOURCE_SET` created on and used by one processor; results copied as plain values |
| DR-020 | At most 10 attached **packs** per connection; the main database (`content.db`) is not counted (SQLite limit; attach #11 fails and must report SQLite's own message, not "Unknown error"; fold 2026-10-26, debate 01 and debate 03; supersedes "At most 10 attached databases per connection") | `BIB_SOURCE_SET.attach` require `attached_count < Max_attached` (`Max_attached` counts pack slots only; an attach policy is specified, debate 01 queue 4) |
| DR-021 | A P4-only timeline event never ships (v2) | `BIB_HISTORY_GATE` P4-only gate; build fails |
| DR-022 | No year zero ever displayed (v2) | `BIB_ASTRO_YEAR.display` postcondition |
| DR-023 | Edition-dependent verdicts name the edition | `BIB_QUOTATION_RESULT` invariant `edition_note_present` (Swete; OCR note) |
| DR-024 | User data is never lost by an edit, delete or upgrade (fold 2026-10-26, debate 02: `user.db` is the system of record in 1a; simple_sql error integrity F-9 and its probe P-ATOMIC must pass before any user-store contract test counts) | `BIB_NOTE_STORE` history and soft-delete postconditions; `BIB_USER_STORE.migrate` `settings_preserved` |
| DR-025 | Every count names its corpus, edition and unit | `BIB_METHOD` invariant `scope_stated` |
| DR-026 | A follow-only or independent panel never moves its link set | `BIB_PANEL.scrolled_to` postcondition |
| DR-027 (fold 2026-10-26, D-021, debate 05b) | Concordance entries are keyed by headword (`lemma_id`), never by Strong's; Strong's reaches a headword only through `lemma_xref` and yields candidates, never "the best" | `BIB_CONC_PACK` signatures take `lemma_id: INTEGER_64`; `headwords_for_strongs` returns a list; FR-024 static check over `BIB_CONC_PACK` (queue 4); core's FR-023 is unchanged (fold plan conflict 1) |
| DR-028 (fold 2026-10-26, D-021, debate 05b) | The engine never branches on which edition it runs; what the pack is shows only in `edition_label` and in the absence of layers it does not carry | `BIB_CONC_PACK.has_layer`, `has_corpus`, `edition_label`; Phase 4 grep for edition literals in engine code (queue 4; overturn trigger 4) |
| DR-029 (fold 2026-10-26, D-021, debate 05a and 05b) | Every original-language word shows a transliteration; every every-place list is paged and never loaded whole (Larry's rules, research/14 section 1) | `translit_not_empty` invariants on `BIB_WORD_ENTRY`, `BIB_PLACE_ROW`, `BIB_ENGLISH_ROW`, `BIB_VERSE_WORD`; `place_page` precondition `limit_bounded` (`Max_page_size = 200`); `token.translit` precomputed in the conc.db builder |
| DR-030 (fold 2026-10-26, debate 01) | `content.db` equals each build stage per table (FTS5 shadow tables included), and two builds from one manifest are byte-identical; optional public content is empty tables, never missing files | The assembly step's postconditions `per_table_identity` and `deterministic` (see 05) |
| DR-031 (fold 2026-10-26, debate 01) | Search and display fetch filter by FTS rowid range, never by a join on `verse.version_id`; `verse_id` is contiguous per version; `hub_id` is never the FTS rowid (SB-1) | Version-range table; contract in 05 |
| DR-032 (fold 2026-10-26, debate 02) | No store routine reports success after a failed statement; every export failure is reported | `BIB_DB_NOTE_STORE` contracts and the export postcondition `files_written + failures = live notes` (see 05) |

## Glossary

| Term | Definition |
|------|------------|
| Hub id | The canonical identity of a verse independent of numbering, produced by the versification map |
| MT | The Masoretic Text (Hebrew), here WLC and MapM |
| LXX (Swete) | The Septuagint as printed by H. B. Swete (Cambridge, 1887-1912), Codex Vaticanus based; digital text from First1KGreek OCR, CC BY-SA 4.0 |
| Rahlfs (CCAT/CATSS) | The Rahlfs Septuagint digital text from CCAT; private build only until permission (D-011) |
| TVTMS | STEPBible's versification traditions dataset (CC BY 4.0) |
| Census | A pre-registered count with controls, reported in four buckets |
| Shape | A named structural pattern with tier and near-misses (shape.db) |
| FITS / PARTIAL / FAILS / NO_DATA | The four verdict buckets; NO_DATA = the tagging is silent |
| Near-miss | A candidate that almost fits; always reported |
| Control words | Frequency-matched words counted beside the target to test whether a pattern beats chance |
| Provenance | Source, edition, license, grade and caveat of a fact |
| Grade P1-P4 | Primary witness / scholarship of record / Larry's verified writing / lead only (11 §2.1) |
| Voice | The trust class of private or author material |
| AI-made | Data computed by a model at build time, labeled with method; never a fact source |
| Range before ruling | All attested renderings with counts before any single meaning |
| They Chose | The quotation comparer's computed verdict on NT agreement with LXX or MT |
| Link set | A group of panels that follow one active reference (A, B, C, Off) |
| Gap work item (GW-nn) | A missing capability filed against and fixed in the owning simple_* library |
| Library gap (LG-nn) | A non-GUI library gap found in this spec (R03) |
| Differential test | Row-by-row comparison of a Python reference output and the Eiffel port's output |
| Build stage (fold 2026-10-26, debate 01) | `core.db`, `ai_data.db` or the rix builder's output: a file the build writes and `content.db` is assembled from; not a run-time file |
| `content.db` (fold 2026-10-26, debate 01) | The one shipped, read-only run-time database assembled from the build stages |
| Pack / private pack (fold 2026-10-26, debate 03) | A versioned, read-only data file in the public pack schema, attached beside `content.db`; a private pack holds Larry's own material |
| Headword (fold 2026-10-26, D-021) | A concordance entry's subject, identified by conc.db `lemma_id`, never by Strong's |
| Place (fold 2026-10-26, D-021) | One occurrence of a headword in a corpus (one conc.db token) |
| Word view (fold 2026-10-26, D-021) | The concordance entry for one headword, in ten sections in the approved order |
| Personal edition / distribution edition (fold 2026-10-26, D-021) | The engine plus conc.db (marked "PERSONAL EDITION - not for distribution") or conc_dist.db (later) |
