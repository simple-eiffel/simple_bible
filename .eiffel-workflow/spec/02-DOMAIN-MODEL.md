# DOMAIN MODEL: simple_bible

*Step R02, 2026-10-06. Concepts are taken from the research and the Python reference tools, not invented. Class names use the `BIB_` prefix chosen in R04 (justification there). Where a concept is release-gated, the release is named.*

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
**Definition:** The only things the engine joins or counts on (FR-024). A Strong's key may carry a sense suffix (H6743a). A display string is never a key (defect E8).
**Will become:** `BIB_KEY` (deferred) with `BIB_LEMMA_KEY`, `BIB_STRONGS_KEY`, `BIB_MORPH_CODE`, `BIB_WORD_ID`.

### Concept: Normalized Form
**Definition:** The search form of a text, built by one shared normalizer at build time and at query time (D-009): Hebrew consonantal with final forms folded and marks removed; Greek decomposed, marks removed, lowercased, final sigma folded; English lowercased. Display never comes from it.
**Behaviors:** `normalize (normalize (s)) = normalize (s)`.
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
**Definition:** A SQLite database the engine reads: `core.db` (required), `ai_data.db`, `rix.db`, `history.db` (optional), `user.db` (read-write), and private databases through the plug-in. Each has an identity (schema version, required tables) and is opened by one processor only.
**Will become:** `BIB_DATA_SOURCE` (deferred), `BIB_CORE_SOURCE`, `BIB_AI_DATA_SOURCE`, `BIB_AUTHOR_LIBRARY`, `BIB_HISTORY_SOURCE`, `BIB_USER_STORE`, `BIB_SOURCE_SET`, `BIB_CONFIG`.

### Concept: User Item
**Definition:** The reader's own record keyed to a canonical hub id: note, highlight (a reason, not a color), bookmark, tag assignment, prayer item, memory card; also plan progress, collections, layout snapshots, settings.
**Will become:** `BIB_USER_ITEM` (deferred) and its kinds; `BIB_MEMORY_SCHEDULER`, `BIB_READING_PLAN`.

### Concept: Note Store and Backup (from research/13, T10/T11)
**Definition:** Where the reader's notes live: the user database, or a folder of Markdown files the reader owns (Obsidian-compatible), indexed for search and verse backlinks. User data is append-only: an edit is a new version, a delete is soft and recoverable; a rotating local backup is taken on exit.
**Will become:** `BIB_NOTE_STORE` (deferred), `BIB_DB_NOTE_STORE`, `BIB_MARKDOWN_NOTE_STORE`, `BIB_USER_BACKUP`.

### Concept: Job
**Definition:** Long engine work (search, census, guide, precompute) running on its own SCOOP processor in chunks, reporting progress and pages through a mailbox, stoppable through a cancel token. A cancelled job produces no findings.
**Will become:** `BIB_JOB` (deferred), `BIB_SEARCH_JOB`, `BIB_CENSUS_JOB`, `BIB_GUIDE_JOB`, `BIB_CANCEL_TOKEN`, `BIB_JOB_MAILBOX`, `BIB_JOB_PAGE`.

### Concept: Plug-in, Private Source, Lens
**Definition:** The private seam: a plug-in registers private sources (attached databases labeled by voice) and lenses (readings applied to a passage, labeled by voice and plug-in) without the public build containing any of them.
**Will become:** `BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, `BIB_PRIVATE_SOURCE`, `BIB_LENS`, `BIB_LENS_RESULT`.

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
BIB_SOURCE_SET ---- has-many ----> BIB_DATA_SOURCE (attached; at most 10 per connection)
BIB_CORE_SOURCE, BIB_AI_DATA_SOURCE, BIB_AUTHOR_LIBRARY, BIB_HISTORY_SOURCE, BIB_USER_STORE ---- is-a ----> BIB_DATA_SOURCE
BIB_PRIVATE_SOURCE ---- is-a ----> BIB_DATA_SOURCE          (deferred; private repo implements)
BIB_PLUGIN ---- has-many ----> BIB_PRIVATE_SOURCE, BIB_LENS
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
| DR-008 | Joins and counts by keys only | Concordance/search features take `BIB_KEY` descendants; static SQL check in tests |
| DR-009 | Display text never edited; normalized text never displayed | `BIB_VERSE_TEXT.display_text` has no setter; normalized forms live only in the search path |
| DR-010 | Normalization is idempotent | `BIB_NORMALIZER.normalized` postcondition `idempotent` |
| DR-011 | Never a bare "LXX" | `BIB_VERSION_INFO` invariant `septuagint_labeled_with_edition` |
| DR-012 | AI-made data always labeled; AI never a source | `BIB_RELATED_PASSAGE` invariant `ai_made_has_label`; `BIB_AI_TEXT` creatable only by `BIB_AI_POST_CHECK` from an engine result with at least one citation |
| DR-013 | Author documents always carry status | `BIB_AUTHOR_DOC` invariant `status_valid`; withdrawn excluded from search unless requested (`search` precondition-free flag, postcondition `withdrawn_only_if_requested`) |
| DR-014 | Partial job results are never findings | `BIB_JOB.result` require `is_done and not is_cancelled` |
| DR-015 | Every number re-runs to itself | `BIB_METHOD` carries the canonical query; `SIMPLE_BIBLE.rerun (method)` ensures equal counts on an unchanged database |
| DR-016 | Builds are deterministic | No clock reads in builders: build date is a `BIB_BUILD_CONTEXT` argument; every export `ORDER BY` a key; per-table checksums compared |
| DR-017 | Quarantined refs answer NO_DATA, never foreign text | `BIB_VERSE_TEXT` omission kind `quarantined`; verse hub postcondition |
| DR-018 | Private material labeled by voice; public build contains no lens | `BIB_LENS_RESULT` invariant `voice_attached`; build check that the public target has no effective `BIB_LENS` |
| DR-019 | One SQLite connection per SCOOP processor; never passed between processors | `BIB_SOURCE_SET` created on and used by one processor; results copied as plain values |
| DR-020 | At most 10 attached databases per connection (SQLite limit observed in the vault) | `BIB_SOURCE_SET.attach` require `attached_count < Max_attached` |
| DR-021 | A P4-only timeline event never ships (v2) | `BIB_HISTORY_GATE` P4-only gate; build fails |
| DR-022 | No year zero ever displayed (v2) | `BIB_ASTRO_YEAR.display` postcondition |
| DR-023 | Edition-dependent verdicts name the edition | `BIB_QUOTATION_RESULT` invariant `edition_note_present` (Swete; OCR note) |
| DR-024 | User data is never lost by an edit, delete or upgrade | `BIB_NOTE_STORE` history and soft-delete postconditions; `BIB_USER_STORE.migrate` `settings_preserved` |
| DR-025 | Every count names its corpus, edition and unit | `BIB_METHOD` invariant `scope_stated` |
| DR-026 | A follow-only or independent panel never moves its link set | `BIB_PANEL.scrolled_to` postcondition |

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
