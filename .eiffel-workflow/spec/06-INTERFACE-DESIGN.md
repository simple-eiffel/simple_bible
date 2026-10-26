# INTERFACE DESIGN: simple_bible

*Step R06, 2026-10-06. The public API of the engine library, the seams the two faces and the private packs use (fold 2026-10-26, debate 03; was "the private plug-in"), the error-handling pattern and the command-query split. Features are named in Eiffel style (nouns for queries, verbs for commands); every engine feature returns a result object that carries its method and its sources.*

*Fold 2026-10-26 (debates 01-05, D-006, D-021): the configuration, status and seam sections below follow the five gated verdicts; a new "Faces" section states the native simple_widgets face, the concordance word view, paged lists, the PERSONAL EDITION marking and the CLI lookups. Superseded text is quoted in the Fold log of `00-FOLD-2026-10-26.md`.*

---

## Public API Summary

### Creation

| Feature | Purpose | Typical Use |
|---------|---------|-------------|
| `{BIB_CONFIG}.make_default` | Paths from the executable folder, `%LOCALAPPDATA%\simple_bible\` and `bible.toml` | `create cfg.make_default` |
| `{BIB_CONFIG}.make_from_file (path)` | Paths from a TOML file (the BibleREPL `bible.toml` precedent) | CLI `--config` |
| `{SIMPLE_BIBLE}.make (config)` | One engine instance for the current processor | `create bible.make (cfg)` |
| `{BIB_REF}.make (book_id, chapter, verse, system)` | A raw reference (usually produced by the parser) | tests, CLI |
| `{BIB_QUERY_PARSER}.parsed (text)` | A query clause tree | search box |
| `{BIB_CENSUS_DEFINITION}.make (question)` | A new, unfrozen definition | Census Builder |
| `{BIB_USER_STORE}.make (path)` | The read-write store (one writer processor) | GUI startup |

### Configuration (Builder Pattern on BIB_CONFIG)

| Feature | Returns | Purpose |
|---------|---------|---------|
| `set_content_path (p)` | like Current | `content.db` location, the one shipped content file (fold 2026-10-26, debate 01; replaces `set_core_path`, "`core.db` location"; name proposed by the fold; fixed in Phase 4) |
| `set_pack_folder (p)` | like Current | the folder scanned for generic private packs, attached read-only at `open`; conc.db is not found by this scan but by `set_conc_path` (fold 2026-10-26, debate 03, settlement G1; "finds packs by folder"; name proposed by the fold; fixed in Phase 4) |
| `set_conc_path (p)` | like Current | the concordance pack: conc.db (personal edition) or conc_dist.db (distribution edition); the edition swap is this one path, no code change (fold 2026-10-26, debate 05 and D-021; `BIB_CONFIG` gains `conc_path`) |
| `set_history_path (p)` | like Current | optional `history.db` (v2: folded into `content.db` or a separate file, decided when v2 is specified; fold 2026-10-26, debate 01) |
| `set_user_path (p)` | like Current | `user.db` |
| `set_default_version (code)` | like Current | the reader's default version (BSB unless changed) |
| `with_reading_options (o)` | like Current | fluent alias grouping display options (pointing level, transliteration scheme) |
| `set_note_store_folder (p)` | like Current | **moves to Release 1b**: notes as Markdown files in a user folder (`BIB_MARKDOWN_NOTE_STORE`, the gated A″ candidate; Q-11). Release 1a gets an export command instead (the export and exit-snapshot folder, outside the Obsidian vault by default, labeled a read-only copy; the user may point it into the vault) (fold 2026-10-26, debate 02) |
| `{BIB_CONFIG}.make_portable` | creation | every path beside the executable; no registry writes (13 T14) |

**Removed from `BIB_CONFIG` (fold 2026-10-26):** the AI-data and author-library path setters, because those stages ship inside `content.db` as tables, empty when absent (debate 01); the plug-in registry setter, because Release 1 has no plug-in facade features and uses the generic pack reader instead (debate 03). The old rows are quoted in the Fold log of `00-FOLD-2026-10-26.md`.

### Core Operations (queries on SIMPLE_BIBLE and its engines)

| Feature | Returns | Purpose | FR |
|---------|---------|---------|----|
| `parser.parse (text, system)` | `BIB_PARSE_RESULT` | valid / ambiguous / invalid | FR-020 |
| `versification.mapped (ref)` | `detachable BIB_MAPPED_REF` | canonical identity | FR-022 |
| `versification.pair (mapped, system)` | `BIB_PAIRING` | numbering in another system, with rules | FR-022 |
| `hub.verse (mapped, versions)` | `BIB_VERSE_RESULT` | one verse in many versions with words and cross-references | FR-021 |
| `hub.chapter (mapped, version)` | `BIB_LIST_RESULT [BIB_VERSE_TEXT]` | a chapter for reading | A01 |
| `hub.word (word_id)` | `BIB_WORD` (as a `BIB_FACT`) | word card | A06 |
| `hub.reduced_pointing (verse_text, level)` | `STRING_32` | Hebrew vowels-only or consonants (derived; stored text unchanged) | FR-113 |
| `verse (text)` | `BIB_VERSE_RESULT` | parse + map + hub in one call | UC-001 |
| `concordance.count (key, scope)` | `BIB_COUNT_TABLE` (in a result) | counts by book with corpus sizes | FR-023, FR-115 |
| `concordance.hits (key, scope)` | `BIB_SEARCH_JOB` | paged hits | FR-023 |
| `search.start_search (query)` | `BIB_SEARCH_JOB` | words, phrases, Boolean, regex, keys; the query is folded by the same Eiffel normalizer as the index; covers attached packs, each hit labeled with its source (fold 2026-10-26, debates 01 and 03) | B01-B05 |
| `search.diff (mapped, base_version, other_version)` | `BIB_LIST_RESULT [...]` spans | word diff | FR-114 |
| `census.proposed_controls (definition)` | `BIB_CONTROL_SET` | frequency-matched controls | FR-112 |
| `census.start_run (definition)` | `BIB_CENSUS_JOB` | four buckets, controls, method | FR-025-027 |
| `shapes.registry` | `BIB_SHAPE_REGISTRY` | named shapes | FR-028 |
| `shapes.evidence (shape)` | `BIB_SHAPE_RUN` | four buckets of a T1/T2 shape | FR-026, FR-028 |
| `quotations.compare (mapped_nt)` | `BIB_QUOTATION_RESULT` | They Chose | FR-030 |
| `quotations.index.quotations_at (mapped)` | `BIB_LIST_RESULT [BIB_QUOTATION]` | is this verse quoted / quoting? | GUI P01 menu |
| `range_viewer.range (lemma_key)` | `BIB_RANGE_RESULT` | renderings with counts and examples | FR-029 |
| `journey.journey (lemma_key)` | `BIB_JOURNEY_RESULT` | witnesses in time order | FR-108 |
| `divine_names.marks (mapped, version)` | `BIB_LIST_RESULT [...]` spans | divine-name spans with legend reasons | FR-109 |
| `guides.passage_guide (range)` / `word_study (key)` / `they_chose (mapped)` / `word_journey (key)` | `BIB_GUIDE_JOB` | engine-assembled guides | FR-110 |
| `related.related (mapped)` | `BIB_LIST_RESULT [BIB_RELATED_PASSAGE]` | related passages with reasons, AI-made labeled | FR-111 |
| `library.entries_for_verse (mapped, resource)` / `for_lemma (key, resource)` / `for_topic (text, resource)` / `for_date (date, resource)` | `BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]` | commentaries, lexicons, dictionaries, devotionals; **covers attached packs** (the library tables live in the pack schema); each entry carries a voice (fold 2026-10-26, debates 01 and 03) | FR-116 |
| `word_lookup.view (lemma_id, corpus_code)` | `BIB_WORD_VIEW` | the word view's data for one headword: heading, how often, English at a glance, dictionary candidates, through the centuries, every-place count, Septuagint section (personal edition; keyed by `lemma_id`, never Strong's) (fold 2026-10-26, debate 05 and D-021) | FR-061, D-021 |
| `conc_pack.place_page (lemma_id, corpus_code, offset, limit)` | `BIB_LIST_RESULT [BIB_PLACE_ROW]` | one page (limit at most 200) of the every-place list in token order; `conc_pack.place_total` gives the row count first (fold 2026-10-26, debate 05a/05b) | D-021 |
| `conc_pack.headwords_for_strongs (key)` | `BIB_LIST_RESULT [BIB_WORD_ENTRY]` | headword candidates behind a Strong's key, through `lemma_xref` only (fold 2026-10-26, debate 05b) | D-021 |
| `english_index.rows (english_word)` | `BIB_LIST_RESULT [BIB_ENGLISH_ROW]` | an English word to the original-language words behind it, Bible by Bible, with counts (fold 2026-10-26, debate 05b) | D-021 |
| `verse_word_lookup.words (ref, corpus_code)` | `BIB_LIST_RESULT [BIB_VERSE_WORD]` | every word in a verse, each a door to its word view (fold 2026-10-26, debate 05b) | D-021 |
| `names.person (name)` / `names.place (name)` | `BIB_LIST_RESULT [...]` | proper names with references | CLI `people` |
| `author_library.search (query, include_withdrawn)` / `citing (mapped)` / `document (doc_id)` | `BIB_LIST_RESULT [BIB_AUTHOR_DOC]` | author library with status | FR-120 |
| `checks.run (text)` | `BIB_LIST_RESULT [BIB_CHECK_FINDING]` | writing checks | FR-031 |
| `exporter.export (result, format)` | `STRING_32` | text with attribution and notices | FR-119 |
| `rerun (method)` | `BIB_ENGINE_RESULT` | Show method / re-run | FR-032 |
| `guides.passage_guide (range, text_first)` | `BIB_GUIDE_JOB` | text-first mode: no commentary, author or lens sections | FR-NEW-013 (13 S9) |
| `notes` (a `BIB_NOTE_STORE`) | store | notes with history, soft delete, restore, backlinks; Release 1a default `BIB_DB_NOTE_STORE` over `user.db`; export and import commands: one Markdown file per live note with `id` and `hub_id` front matter, file-safe names, atomic write, every failure reported; import as new notes or new versions, never overwriting a row (fold 2026-10-26, debate 02) | FR-NEW-015/016 |
| `{BIB_VERSION_INFO}.verse_count`, `seal` | INTEGER, STRING_8 | "KJV 1769 · 31,102 verses · sealed" | FR-NEW-019 (13 S2) |
| `{BIB_METHOD}.scope_label` | STRING_32 | "NT, SBLGNT, word tokens" beside every count | FR-NEW-019 (13 S11) |
| `credits` | `STRING_32` | generated credits | FR-003 |

### Commands (state changes)

| Feature | Purpose |
|---------|---------|
| `SIMPLE_BIBLE.open` / `close` | Open / close this processor's sources: `content.db` read-only, then the generic private packs found in the pack folder attached read-only through `attach_read_only`, and conc.db from `conc_path` (fold 2026-10-26, debates 01 and 03, settlements S1, G1; was "through the query path") |
| `BIB_CENSUS_DEFINITION.set_question`, `set_corpus`, `set_criteria`, `add_control`, `remove_control`, `set_holds_if`, `set_fails_if` | Edit an unfrozen definition |
| `BIB_CENSUS_DEFINITION.new_version` (query creating a copy) | Version a frozen definition |
| `BIB_USER_STORE.add_note`, `update_note`, `remove_note`, `add_highlight`, `remove_highlight`, `add_bookmark`, `tag_verse`, `untag_verse`, `add_prayer_item`, `set_prayer_answered`, `add_memory_card`, `record_review`, `record_visit`, `save_collection`, `save_layout_snapshot`, `set_setting`, `store_census_definition`, `store_census_run`, `record_plan_progress` | The reader's own data (one writer processor) |
| `BIB_JOB.run_to_completion (token, mailbox)` | Run a job on its processor |
| `BIB_CANCEL_TOKEN.request_cancel` | Ask a running job to stop |
| `BIB_USER_STORE` export and import of notes (plus the exit snapshot if DS-B′ passes) | Write the export folder atomically and report every failure; read a folder back as new notes or new versions (fold 2026-10-26, debate 02; replaces the row `BIB_PLUGIN_REGISTRY.register (plugin)`, `seal`, removed by debate 03) |

### Status Queries

| Feature | Returns | Purpose |
|---------|---------|---------|
| `SIMPLE_BIBLE.is_open` | BOOLEAN | sources open on this processor |
| `has_ai_data`, `has_author_library`, `has_history` | BOOLEAN | optional public content present: a presence count over empty-by-default tables of `content.db`, never a missing file (fold 2026-10-26, debate 01; was "optional databases present") |
| `conc_pack.is_available`, `has_corpus (code)`, `has_layer (layer)`, `edition_label` | BOOLEAN, BOOLEAN, BOOLEAN, `STRING_32` | is the concordance pack attached; which corpora and layers ("lxx", "bsb", "dictionaries") it carries; what the pack says it is, shown in the title bar and the About window. The engine never branches on `edition_label` (fold 2026-10-26, debate 05 and D-021) |
| `last_error` | `detachable BIB_ERROR` | why `open` failed |
| `database_edition` | STRING_32 | build id of `content.db` (status bar) (fold 2026-10-26, debate 01; was "build id of `core.db`") |
| `BIB_ENGINE_RESULT.is_success` / `error` | BOOLEAN / `detachable BIB_ERROR` | outcome |
| `BIB_JOB_MAILBOX.progress`, `page_count`, `page (n)`, `is_done`, `is_cancelled`, `is_failed`, `error_text` | - | what the GUI polls |
| `BIB_CENSUS_DEFINITION.is_complete`, `is_frozen`, `is_stored` | BOOLEAN | builder validation (VR-06, VR-07) |
| `BIB_VERSION_INFO.has_caveat`, `has_morphology`, `is_right_to_left`, `is_septuagint` | BOOLEAN | display decisions the face makes from data |

## Fluent API Example

```eiffel
local
    cfg: BIB_CONFIG
    bible: SIMPLE_BIBLE
    r: BIB_VERSE_RESULT
do
    cfg := (create {BIB_CONFIG}.make_default)
        .set_default_version ("BSB")
        .set_user_path (user_db_path)
    create bible.make (cfg)
    bible.open
    if bible.is_open then
        r := bible.verse ("jn 3 16")
        if r.is_success then
            render (r)                   -- every text and word arrives with its provenance
        elseif r.parse_outcome.is_ambiguous then
            offer_candidates (r.parse_outcome)
        else
            show_error (r.error)
        end
    else
        show_database_problem (bible.last_error)   -- D08
    end
end
```

**Census, pre-registered (UC-004):**
```eiffel
def := create {BIB_CENSUS_DEFINITION}.make ("Does X cluster in Paul beyond its frequency band?")
def.set_corpus (scope_pauline)
def.set_criteria (bible.parser_for_queries.parsed ("lemma:G1577"))
across bible.census.proposed_controls (def).keys as k loop def.add_control (k) end
def.set_holds_if ("target rate exceeds every control's rate")
def.set_fails_if ("target rate within the controls' range")
store.store_census_definition (def)                    -- written down before the run
job := bible.census.start_run (def)                    -- freezes on first run
```

## Error Handling Pattern

```eiffel
result := bible.hub.verse (mapped, versions)
if result.is_success then
    across result.texts as t loop
        if attached t.omission as o then
            show_omission (o)                -- "omitted in this edition (WH)", "missing from this digital text (OCR loss)"
        else
            show_text (t.display_text, t.provenance)
        end
    end
else
    handle_error (result.error)              -- code, message, details; panel error state (ER-04)
end
```

Rules:
1. **Engine features never raise for expected conditions.** Missing data is a result (`BIB_OMISSION`, NO_DATA bucket, `agreement.is_no_data`); a failed query is `is_success = False` with a `BIB_ERROR`. Contract violations are bugs, never control flow.
2. **The parser never guesses.** Ambiguity is a valid outcome with candidates.
3. **Opening is the only operation that leaves the facade unusable**; `last_error` explains it (GUI D08 "Database problem").
4. **Optional content is empty, never fails** (GUI ER-02): `has_ai_data = False` (the related-passage table is empty) makes `related` return cross-reference and rare-word reasons only, labeled as such; an absent concordance pack makes `conc_pack.is_available` False and the concordance faces show their absent state (fold 2026-10-26, debates 01 and 05; was "Optional databases degrade, never fail").
5. **Jobs end in exactly one of done, cancelled, failed** (mailbox invariant); cancelled jobs carry no findings.

## Face seams

### GUI seam (L-GUI depends on these only)

| GUI class | Uses | Never uses |
|-----------|------|------------|
| `BIB_ENGINE_CLIENT` | `separate SIMPLE_BIBLE` (lookup worker); `separate BIB_*_JOB` + `separate BIB_CANCEL_TOKEN` + `separate BIB_JOB_MAILBOX` (job workers); `separate BIB_USER_STORE` | `SIMPLE_SQL_*`, SQL text |
| `BIB_RESULT_ADAPTER [R]` descendants | engine result types (copied values) | any engine class with behavior |
| Panels | `BIB_ENGINE_CLIENT`, adapters, `BIB_LINK_HUB` | engines directly |

**BIB_ENGINE_CLIENT (the GUI's only door):**
```eiffel
class BIB_ENGINE_CLIENT
feature -- Short verse-and-word lookups (synchronous separate calls; < 50 ms p95; this is not the concordance first screen, whose budget is NFR-019 with the builder precomputations as its mitigation, RISK-038) (fold 2026-10-26, settlement S5)
    verse (a_ref: BIB_ACTIVE_REFERENCE; a_versions: ARRAY [STRING_8]): BIB_VERSE_RESULT
    word (a_word_id: INTEGER_64): BIB_FACT [BIB_WORD]
    lexicon (a_key: BIB_KEY): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
    cross_references (a_ref: BIB_ACTIVE_REFERENCE): BIB_LIST_RESULT [BIB_CROSS_REFERENCE]
    parse (a_text: STRING_32): BIB_PARSE_RESULT
feature -- Concordance (fold 2026-10-26, debate 05 and D-021; the GUI reaches the pack only through this door)
    word_view (a_lemma_id: INTEGER_64; a_corpus_code: STRING_8): BIB_WORD_VIEW
    place_total (a_lemma_id: INTEGER_64; a_corpus_code: STRING_8): BIB_FACT [INTEGER_64]
    place_page (a_lemma_id: INTEGER_64; a_corpus_code: STRING_8; a_offset, a_limit: INTEGER): BIB_LIST_RESULT [BIB_PLACE_ROW]
    english_rows (a_english: STRING_32): BIB_LIST_RESULT [BIB_ENGLISH_ROW]
    verse_words (a_ref: BIB_REF; a_corpus_code: STRING_8): BIB_LIST_RESULT [BIB_VERSE_WORD]
feature -- Jobs (return a handle; results arrive through the mailbox)
    start_search (a_query: BIB_QUERY): BIB_JOB_HANDLE
    start_census (a_definition_id: INTEGER_64): BIB_JOB_HANDLE
    start_guide (a_kind: INTEGER; a_subject: BIB_ACTIVE_REFERENCE): BIB_JOB_HANDLE
    cancel (a_handle: BIB_JOB_HANDLE)
feature -- User data (separate user store)
    add_note (...), add_highlight (...), ...
end
```
(`BIB_JOB_HANDLE` is the GUI-side record of one job: kind, its cancel token and its mailbox; listed in 04 section 1.5.)

All results crossing from a worker to the GUI processor are copied (deep import of plain values) when the separate call returns; the GUI never keeps a reference into a worker's objects (GUI notes §5 rule 4).

### Native face and the concordance views (fold 2026-10-26, D-006, D-021, debate 05)

**The faces are native `simple_widgets`** (with simple_shaping, simple_cairo and simple_shell), decided by Larry 2026-10-06 (D-006): no WebView2, no fallback, no local web server (NFR-012 withdrawn). Every gap found is filed and fixed in the owning library; every GW gap is done (Phase 4 complete 2026-10-26; `gui/00-GUI-SPEC.md`, `gui/02-GAP-PROGRAM.md`). The CLI/REPL face stays for power users. The widget vocabulary and panel layout are those of `gui/00-GUI-SPEC.md`; this section adds only what the concordance decisions require.

**Word view, in the pilot's approved order** (research/14 section 3; Larry approved it over five pilot rounds; reference design: `Pilot 5.7 - Words and a Phrase in Both Concordances`):

| # | Section | Content |
|---|---------|---------|
| 1 | Heading | Transliteration, Hebrew or Greek, pronunciation |
| 2 | How often | In plain words, with Hebrew stems or Greek editions |
| 3 | English at a glance | What the BSB, KJV and STEP use for the word, with counts |
| 4 | What the dictionaries say | Each source in its own words, side by side, as candidates |
| 5 | Through the centuries | Counts per writing and per 10,000 words; for Greek, LSJ meanings by five periods |
| 6 | One short callout | At most one |
| 7 | **Every place** (the core) | Reference, whole word with transliteration, meaning (SDBH or SDGNT) or stem, BSB in context, KJV, STEP |
| 8 | The Greek Old Testament | For Greek words, the Septuagint places with Brenton's English; for Hebrew words, the Greek column in the table |
| 9 | Going further | From `see_also`, in an unnamed section (no framework names, no trademark names) |
| 10 | Notes | Numbered; asides go here, not into callouts |

**English lookup:** the pilot's English index: an English word to the Hebrew and Greek words behind it, Bible by Bible, with counts. **Verse lookup:** a reference to every word in the verse, each a door to its word view. **Phrase entries** ("Son of Man": head word plus second word, at most an article between) are part of the pilot's reference design.

**Rules carried from Larry's concordance rules (research/14 section 1; personal edition):**

| Rule | Interface consequence |
|------|-----------------------|
| Keyed by headword, never by Strong's | Every concordance control carries a `lemma_id`; Strong's reaches a headword only through `headwords_for_strongs` |
| "Candidates," never "best" | Labels for meanings and renderings say "candidates"; no control or column says "best" |
| Readers never see corpus codes | Corpus codes stay in the engine; "linked" counts appear only when something is missing |
| Usefulness model is Strong's Concordance | How to use the view is painfully obvious on first opening; finer uses are taught in the help |
| Hebrew lines up left in tables | An LRM precedes Hebrew cells; headings start with the transliteration |
| Every original-language word shows a transliteration | SBL style; dictionary forms also show a pronunciation (CAPS stress, for example KHEH-sed; YHWH = YAH-weh) |
| Helps without clutter | At most one callout per entry; asides in numbered notes |
| Never print Larry's name | His framework ideas appear in an unnamed "Going further" section |
| American English | All labels, prose and identifiers |

**Paged lists (virtual grid).** The every-place list and the English list are paged through the large virtual grid with shaped Hebrew cells, never loaded whole (the Greek article has 88,444 places in the LXX; the Hebrew "and" has 50,272). Page size is at most 200 rows; `place_total` is read first. Measured (lean, warm): first page of 200 places 25-28 ms; the whole 88,444-row list 572-874 ms. A cursor abandoned early is closed. The list is token-ordered; a sort on an unindexed column is never requested of the pack for a whole list.

**First-screen timing (debate 05b, queue 2 executed; NFR-001 stays at risk).** Heading, how often, English at a glance and the first page of 200 places, back to back: rare and ordinary words are instant (a word with 246 places: 2-3 ms); the commonest words sit near 200 ms warm (Greek article, NT: 197-398 ms) and up to 2,773 ms the first time their pages are read from disk (Hebrew "and"). The remedy is a builder item (per-corpus counts and the English-at-a-glance summary precomputed per headword; see 07), or filling sections as they arrive.

**The PERSONAL EDITION marking.** When the attached pack is conc.db, the title bar and the About window carry **"PERSONAL EDITION - not for distribution"**. The face shows what the pack says it is (`conc_pack.edition_label`); no engine class tests the edition (debate 05b, overturn trigger 4). Layers the pack lacks (`has_layer`: "lxx", "bsb", "dictionaries") simply do not appear: the distribution pack conc_dist.db may carry fewer.

**Credits (distribution edition).** Every "free to use with credit" source appears in Help, About. About lists both, generated: the engine's sources from `source_provenance` (FR-003, the existing generated `credits`) and each attached pack's own `notice` table (planned for conc_dist.db), so nothing is typed by hand and neither list can go stale (fold 2026-10-26, settlement S4; was "how the two are presented together in About is not settled by the sources").

**Absent state.** With no concordance pack attached (`conc_pack.is_available` False, the public build), the concordance views are absent or show their absent state; nothing fails (rule 4 above).

### CLI seam

`BIB_CLI_APP` creates one `SIMPLE_BIBLE` and one `BIB_USER_STORE` on the main processor; commands call engine features and render with `BIB_TEXT_RENDERER`. Jobs run inline (`run_to_completion` with a local token and mailbox). One-shot mode: `bible.exe /<command> <args>` executes exactly one allowlisted command and exits with code 0 (executed), 2 (refused: not in the allowlist), 1 (failed). Console Hebrew is printed as text; the renderer adds transliteration for every Hebrew or Greek word (consoles cannot shape RTL reliably; research D-006 option 3).

**Allowlisted commands (closed set, read-only):**

| Command | Engine call | Ledger R-5 |
|---------|-------------|------------|
| `<reference>` / `/verse` | `verse` | verse references |
| `/define` | `library.for_lemma` (Strong's + lexicons) | define |
| `/search` | `search.start_search` | search |
| `/compare` | `hub.verse` over all versions | compare |
| `/etymology` | Strong's derivation entry | etymology |
| `/xref` | cross-references | xref |
| `/people` | `names` | people |
| `/list` | books / chapters | list |
| `/versions` | version infos with caveats and licenses | versions |
| `/census` | run a stored definition by id | (new) |
| `/shape` | shape evidence by slug | (new) |
| `/quote` | They Chose | (new) |
| `/journey` | Word's Journey | (new) |
| `/method` | re-run a method id | (new) |
| `/credits` | credits | (new) |
| the word-view command (name fixed in Phase 4; takes a headword or an original-language word) | `word_lookup.view`, `conc_pack.place_page` | FR-061, D-021 (fold 2026-10-26, debate 05b section 8) |
| the English command (name fixed in Phase 4) | `english_index.rows` | FR-061, D-021 (fold 2026-10-26, debate 05b section 8) |
| the verse-word command (name fixed in Phase 4) | `verse_word_lookup.words` | FR-061, D-021 (fold 2026-10-26, debate 05b section 8) |

**Concordance commands (fold 2026-10-26, debate 05b section 8 and D-021, FR-061):** the CLI gains the three lookups of the personal edition (by original-language word, by English word, by verse reference) through the facade names `word_lookup`, `english_index` and `verse_word_lookup`. They are read-only, so they join the closed allowlist. Lists are paged at 200 rows, the console prints transliteration for every Hebrew or Greek word, and every command is refused with a stated reason when `conc_pack.is_available` is False.

### Private pack seam (B′; fold 2026-10-26, debate 03; replaces "Private plug-in seam")

There is **no private code seam** in Release 1: no `BIB_PLUGIN`, no `BIB_PLUGIN_REGISTRY`, no deferred `BIB_LENS`, no `commands` or `panels` contributions, no rule interpreter. Private material arrives as versioned **data packs** in a public, documented schema (a free tool; the schema holds nothing private; third parties may build packs), found by folder and attached read-only through `SIMPLE_SQL_DATABASE.attach_read_only` on the read-only main (fold 2026-10-26, settlement S1; was `query ("ATTACH ...")`). conc.db is a concordance pack of its own kind, found by `conc_path` rather than the folder scan (fold 2026-10-26, settlements S6, G1).

| Part of the generic private data pack schema (conc.db is a concordance pack with its own check; fold 2026-10-26, settlement S6) | Specification |
|-------------------------|---------------|
| DDL and version | The published DDL; `user_version` checked at open (a mismatch is a named open failure, as for every source) |
| Voice | A `NOT NULL` voice column on every row that can reach a result; checked at attach; an unlabeled private result in a fixture run = 0 |
| Provenance | `provenance_key` with `source_provenance` in the pack's own file; the foreign-key check names the pack's schema |
| Reference rows | Rows keyed to passages through reference rows, each pack declaring its versification |
| Library tables | `library_resource` and `library_entry` live in the pack schema (debate 01) |
| Fold rule | The pack declares its fold-rule version; its folded index comes from the Eiffel pack builder or passes the published fold-parity fixture; otherwise it is attached and labeled "not diacritic-safe" (debate 01, gate item 4) |
| Reader | One generic public reader. `BIB_PRIVATE_SOURCE` is an effective, generic pack source; `BIB_LENS_RESULT` keeps its voice, with `plugin_name` becoming the pack name; results are built through the public `make_success`, which requires `BIB_VOICE`; `BIB_LIBRARY_ENTRY.make` gains `a_voice: BIB_VOICE` |
| Generic features | By-verse range overlap, Boolean key search, edit-distance fuzzy match, and multi-source FTS with source labels, so user queries over private corpora (S-10, C-03) need no private code. `library.*` queries (FR-116) and `search.start_search` (B01-B05) state that they cover attached packs |

Larry's lens logic (the `SCHOLAR_FRAME_*` successors, KACC classes per ledger L-4) runs once per vault export in his own tool, which may stay Python (D-020 scope is the shipped product), and writes the packs. Lens annotations and `machine_generated.db` ship only as private packs. The concordance pack (conc.db, personal edition) is such a pack. Overturn triggers OT-1 to OT-7 of debate 03 govern; the first is the C-03 presentation spike.

### Outside-AI seam (candidate, Q-12; research/13 S6)

The CLI's closed command set is already an engine door for other programs (simple_chat uses it). A candidate fourth face, `bible_mcp`, would speak MCP over **stdio** (no listening port, so NFR-011 and D-006's withdrawal of the loopback server stay intact), map each MCP tool to an allowlisted `BIB_COMMAND`, and return every result with its provenance and method, so a user's own AI gets facts from the engine instead of from memory. It needs a fleet MCP protocol library (LG-06) and Larry's opt-in and security stance; it is not in Release 1.

### AI seam (later releases)

```eiffel
deferred class BIB_AI_ADAPTER
feature
    explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
        require engine_answer: a_result.is_success; cited: a_result.citation_count > 0
        deferred
        end
end
```
Release 1 binds `BIB_NULL_AI_ADAPTER`. The input type is an engine result, never a string, so a free-text question can never reach a model without an engine answer (I-001).

## Command-Query Separation

| Feature | Type | Modifies State? | Returns Value? |
|---------|------|-----------------|----------------|
| `BIB_CONFIG.set_*` | Command (builder) | YES (config) | like Current (for chaining) |
| `SIMPLE_BIBLE.open` / `close` | Command | YES | NO |
| every engine accessor (`hub`, `search`, ...) | Query (once per instance) | NO observable | YES |
| `parse`, `mapped`, `pair`, `verse`, `count`, `compare`, `range`, `journey`, `marks`, `related`, `entries_*`, `citing`, `run` (checks), `export`, `credits` | Query | NO | YES |
| `rerun (method)` | Query | NO | YES |
| `search.start_search`, `census.start_run`, `concordance.hits`, `guides.*` | Query (factory) | NO: returns a new, unstarted job object | YES |
| `census.start_run` freezing the definition | Command side effect at **run**, not at `start_run` | the freeze happens in `BIB_CENSUS_JOB.run_to_completion` | - |
| `BIB_JOB.run_to_completion`, `step` | Command | YES | NO |
| `BIB_CANCEL_TOKEN.request_cancel` | Command | YES | NO |
| `BIB_JOB_MAILBOX.post_page`, `set_progress`, `close_*` | Command | YES | NO |
| `BIB_CENSUS_DEFINITION.set_*`, `add_control`, `freeze` | Command | YES | NO |
| `BIB_CENSUS_DEFINITION.new_version` | Query (factory) | NO (on Current) | YES (a new object) |
| `BIB_USER_STORE.add_*`, `remove_*`, `record_*`, `store_*`, `set_setting` | Command | YES | NO (ids readable afterwards; `last_error`) |
| `BIB_AI_POST_CHECK.checked` | Query (factory) | NO | YES (a new labeled object) |
| `BIB_DISTRIBUTION_BUILDER.build` | Command | YES (writes the database) | NO (status queries afterwards) |
| `BIB_DB_COMPARATOR.compare` | Query | NO (both files opened read-only) | YES (report) |
| `BIB_COMMAND_SET.execute` | Command (exception to CQS, documented) | prints output | YES (`BIB_COMMAND_OUTCOME` for the exit code) |

**CQS exceptions (documented):** `BIB_COMMAND_SET.execute` returns its outcome because the CLI's exit code depends on it; nothing else returns a value from a command. Factories that return new objects (`start_*`, `new_version`, `checked`) do not change Current.

## Versioning and compatibility

- **Schema versions:** each data source declares `expected_schema_version` (`PRAGMA user_version`); a mismatch is an open failure with a named error, never a silent read (GUI ER-01).
- **Method records** carry engine version, database edition and SQLite version, so a re-run after an upgrade states why a number changed.
- **Downstream consumers:** simple_chat's `@tools-larry` participant (via the CLI one-shot allowlist) is the only known consumer (ledger §7); its retargeting is part of the CLI phase (ledger R-6).
