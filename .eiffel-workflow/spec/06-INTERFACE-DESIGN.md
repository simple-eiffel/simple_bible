# INTERFACE DESIGN: simple_bible

*Step R06, 2026-10-06. The public API of the engine library, the seams the two faces and the private plug-in use, the error-handling pattern and the command-query split. Features are named in Eiffel style (nouns for queries, verbs for commands); every engine feature returns a result object that carries its method and its sources.*

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
| `set_core_path (p)` | like Current | `core.db` location |
| `set_ai_data_path (p)` | like Current | optional `ai_data.db` |
| `set_rix_path (p)` | like Current | optional `rix.db` (author library) |
| `set_history_path (p)` | like Current | optional `history.db` (v2) |
| `set_user_path (p)` | like Current | `user.db` |
| `set_default_version (code)` | like Current | the reader's default version (BSB unless changed) |
| `set_plugin_registry (r)` | like Current | private build only |
| `with_reading_options (o)` | like Current | fluent alias grouping display options (pointing level, transliteration scheme) |
| `set_note_store_folder (p)` | like Current | notes as Markdown files in a user folder (`BIB_MARKDOWN_NOTE_STORE`; Q-11) |
| `{BIB_CONFIG}.make_portable` | creation | every path beside the executable; no registry writes (13 T14) |

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
| `search.start_search (query)` | `BIB_SEARCH_JOB` | words, phrases, Boolean, regex, keys | B01-B05 |
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
| `library.entries_for_verse (mapped, resource)` / `for_lemma (key, resource)` / `for_topic (text, resource)` / `for_date (date, resource)` | `BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]` | commentaries, lexicons, dictionaries, devotionals | FR-116 |
| `names.person (name)` / `names.place (name)` | `BIB_LIST_RESULT [...]` | proper names with references | CLI `people` |
| `author_library.search (query, include_withdrawn)` / `citing (mapped)` / `document (doc_id)` | `BIB_LIST_RESULT [BIB_AUTHOR_DOC]` | author library with status | FR-120 |
| `checks.run (text)` | `BIB_LIST_RESULT [BIB_CHECK_FINDING]` | writing checks | FR-031 |
| `exporter.export (result, format)` | `STRING_32` | text with attribution and notices | FR-119 |
| `rerun (method)` | `BIB_ENGINE_RESULT` | Show method / re-run | FR-032 |
| `guides.passage_guide (range, text_first)` | `BIB_GUIDE_JOB` | text-first mode: no commentary, author or lens sections | FR-NEW-013 (13 S9) |
| `notes` (a `BIB_NOTE_STORE`) | store | notes with history, soft delete, restore, backlinks | FR-NEW-015/016 |
| `{BIB_VERSION_INFO}.verse_count`, `seal` | INTEGER, STRING_8 | "KJV 1769 · 31,102 verses · sealed" | FR-NEW-019 (13 S2) |
| `{BIB_METHOD}.scope_label` | STRING_32 | "NT, SBLGNT, word tokens" beside every count | FR-NEW-019 (13 S11) |
| `credits` | `STRING_32` | generated credits | FR-003 |

### Commands (state changes)

| Feature | Purpose |
|---------|---------|
| `SIMPLE_BIBLE.open` / `close` | Open / close this processor's sources |
| `BIB_CENSUS_DEFINITION.set_question`, `set_corpus`, `set_criteria`, `add_control`, `remove_control`, `set_holds_if`, `set_fails_if` | Edit an unfrozen definition |
| `BIB_CENSUS_DEFINITION.new_version` (query creating a copy) | Version a frozen definition |
| `BIB_USER_STORE.add_note`, `update_note`, `remove_note`, `add_highlight`, `remove_highlight`, `add_bookmark`, `tag_verse`, `untag_verse`, `add_prayer_item`, `set_prayer_answered`, `add_memory_card`, `record_review`, `record_visit`, `save_collection`, `save_layout_snapshot`, `set_setting`, `store_census_definition`, `store_census_run`, `record_plan_progress` | The reader's own data (one writer processor) |
| `BIB_JOB.run_to_completion (token, mailbox)` | Run a job on its processor |
| `BIB_CANCEL_TOKEN.request_cancel` | Ask a running job to stop |
| `BIB_PLUGIN_REGISTRY.register (plugin)`, `seal` | Private build startup only |

### Status Queries

| Feature | Returns | Purpose |
|---------|---------|---------|
| `SIMPLE_BIBLE.is_open` | BOOLEAN | sources open on this processor |
| `has_ai_data`, `has_author_library`, `has_history` | BOOLEAN | optional databases present |
| `last_error` | `detachable BIB_ERROR` | why `open` failed |
| `database_edition` | STRING_32 | build id of `core.db` (status bar) |
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
4. **Optional databases degrade, never fail** (GUI ER-02): `has_ai_data = False` makes `related` return cross-reference and rare-word reasons only, labeled as such.
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
feature -- Short lookups (synchronous separate calls; < 50 ms p95)
    verse (a_ref: BIB_ACTIVE_REFERENCE; a_versions: ARRAY [STRING_8]): BIB_VERSE_RESULT
    word (a_word_id: INTEGER_64): BIB_FACT [BIB_WORD]
    lexicon (a_key: BIB_KEY): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
    cross_references (a_ref: BIB_ACTIVE_REFERENCE): BIB_LIST_RESULT [BIB_CROSS_REFERENCE]
    parse (a_text: STRING_32): BIB_PARSE_RESULT
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

### Private plug-in seam

```eiffel
deferred class BIB_PLUGIN
feature -- Identity
    name: STRING_8 deferred end
    version: STRING_8 deferred end
feature -- Contributions
    sources: ITERABLE [BIB_PRIVATE_SOURCE] deferred end      -- attached when present
    lenses: ITERABLE [BIB_LENS] deferred end
    commands: ITERABLE [BIB_COMMAND] deferred end            -- private CLI commands (ledger C-03 subset)
feature -- Lifecycle
    on_open (a_bible: SIMPLE_BIBLE) deferred end              -- attach its sources through the source set
end

deferred class BIB_LENS
feature
    name: STRING_8 deferred end
    voice: BIB_VOICE deferred end
    applies_to (a_ref: BIB_MAPPED_REF): BOOLEAN deferred end
    read (a_ref: BIB_MAPPED_REF; a_bible: SIMPLE_BIBLE): BIB_LENS_RESULT
        require applies: applies_to (a_ref)
        deferred
        ensure labeled: Result.voice ~ voice and Result.plugin_name.same_string (plugin_name)
        end
end
```
Larry's private repository implements these (`SCHOLAR_FRAME_*` successors, KACC classes per ledger L-4, scholars/transcripts/primary_evidence sources). Its root registers the plug-in before `SIMPLE_BIBLE.open`. GUI panels for private content register through the same plug-in (`panels` contribution added on the GUI side when P-numbers are assigned to them).

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
