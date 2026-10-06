# SPECIFICATION: simple_bible

*Step R07, 2026-10-06. Synthesis of 01-06. Eiffel class texts below are **specification text** for /eiffel.intent and /eiffel.contracts; no `.e` file, ECF or repository is created in this phase. Bodies marked `-- (Phase 4)` are left for implementation; contracts are the specification.*

---

## Overview

simple_bible is a free Windows Bible-study workbench in which a deterministic Eiffel engine over SQLite does all the counting, lookup, comparison and checking of the Hebrew, Greek and English text, and every fact carries its source and license. It is built as:

1. **An engine library** (`simple_bible`, 145 classes in Release 1 plus ported shapes) exposing `SIMPLE_BIBLE` and its engines. Every answer is a result object with a method record and citations; census and shape answers always carry FITS, PARTIAL, FAILS and NO_DATA together; cross-version pairing is possible only through the versification map; AI text can only be created from an engine answer and is always labeled.
2. **A build pipeline** (`bible_build`, 44 classes) that assembles `core.db`, `ai_data.db` and `rix.db` from pinned upstream sources and the vault, under a license gate, deterministically, with generated credits; it hosts the Eiffel ports of the vault's Python tools, each accepted by a differential test against golden outputs.
3. **Two faces** that depend only on engine abstractions: a native simple_widgets GUI (`simple_bible_app`; 13 classes plus 11 panels and 9 dialogs in v1) and a CLI/REPL (`bible.exe`; 7 classes plus 15 allowlisted commands).
4. **A private plug-in seam** (5 classes, 3 deferred) that Larry's separate repository implements at compile time.

Release 1 runs no AI on the user's machine; it ships precomputed, labeled AI-made related passages (D-016). Release 1 scope split (1a engine-and-reader, 1b library content packs) is recommended and awaits Larry (Q-01).

## Prerequisites and gap register (must be tracked before the phases that need them)

| ID | Item | Owning library | Needed by | Status |
|----|------|----------------|-----------|--------|
| FT-01 | Upgrade the amalgamation from 3.31.1 to current; fix README drift (D-007) | eiffel_sqlite_2025 | optional for Release 1 (spec designs to 3.31.1) | fleet task, not started |
| FT-02 | Mark `c_sqlite3_step`, `c_sqlite3_open_v2`, `c_sqlite3_close` `blocking` (fleet GC law) | eiffel_sqlite_2025 | GUI phase (NFR-016); do with FT-01 | HELD for Larry's gate (patch in place vs fork) |
| LG-01 | Unicode NFD/NFC and general category incl. Mn/Mc/Me | simple_encoding | `BIB_GREEK_NORMALIZER`, Swete repair | to file |
| LG-03 | `STRING_32` variants of `string_value_or_void` / `_or_default` | simple_sql | engine coding rule (until then, banned accessors) | to file |
| LG-04 | GPU execution provider runtime (optional) | simple_onnx | build-time embeddings speed | optional |
| LG-05 | bge-m3 (XLM-R SentencePiece) tokenizer compatibility, if the check fails | simple_onnx | `BIB_EMBEDDING_PRECOMPUTE` | check first |
| LG-06 | MCP protocol library (JSON-RPC over stdio), new fleet library | new (`simple_mcp`) | the MCP face, only if Q-12 says yes | not started |
| GW-01..13, 24, 26 | v1 GUI gap items (fonts, RTL alignment, cantillation, shaped grids, dock, parallel text, interlinear, paragraph-list hit tests, hover card, grouped bars, status sections, query builder, rich text, function keys, cross-processor wake) | simple_shaping, simple_widgets, simple_shell | GUI panels (see 03 A-011 order) | filed in gui/spec_windows_design_notes §9 |
| GW-14..16, 21 | v1.5 GUI items | same | v1.5 | - |
| GW-17..20, 22, 23, 25 | v2 GUI items | same | v2 | - |

Every item is fixed in its owning library, followed by a downstream-dependents sweep and README/docs/CHANGELOG updates (C-018). None is worked around in simple_bible (C-013).

## Data model (run time)

| Database | Mode | Holder | Contents (Release 1) |
|----------|------|--------|----------------------|
| `core.db` | read-only | every engine processor | `book_catalog` (vault ids, FR-105), `versification_system`, `versification_map`, `version`, `verse` (display text, `verse_suffix`, omission kind, repair state, provenance key), `verse_norm` + FTS5 (`unicode61 remove_diacritics 2`) over normalized text, `word` (keys, morph code, gloss, transliteration, pronunciation), `lemma`, `strongs` (split senses), `morph_code` (English expansion), `cross_reference` (votes), `quotation`, `alignment`, `lemma_frequency`, `shape`, `shape_instance`, `shape_evidence`, `shape_run`, `proper_name*` (TIPNR), `library_resource`, `library_entry` (R1b per Q-01), `source_provenance`, `source_repairs`, `quarantine`, `caveat`, `import_gap`, `build_run`, `table_checksum` |
| `ai_data.db` | read-only, optional | engine processors | `related_passage` (target, reason kind, votes, `is_ai_made`, method, model id) ; vectors in v2 (Q-06) |
| `rix.db` | read-only, optional | engine processors | exactly the R15 schema of `build_rix_db.py` (`docs`, `verse_refs`, `docs_fts`) |
| `user.db` | read-write | user-store processor only | notes, highlights, bookmarks, tags, history, prayer, memory cards, plan progress, collections, layout snapshots, settings, census definitions and runs, (v1.5) ledger |
| `history.db` | read-only, v2 | engine processors | 11 §5.3 schema, `v_shippable` export only |

All DDL uses only SQLite 3.31.1 features: `CHECK` and `NOT NULL` instead of `STRICT`; no `->>`; no math functions; generated columns allowed.

## Class Specifications

### SIMPLE_BIBLE (Facade)

```eiffel
note
    description: "Facade: one processor's access to the simple_bible engine. Open the sources, then use the engines; every answer carries its method and sources."
    author: "Larry Rix"

class
    SIMPLE_BIBLE

create
    make

feature {NONE} -- Initialization

    make (a_config: BIB_CONFIG)
            -- Create an unopened engine for `a_config`.
        require
            config_valid: a_config.is_valid
        do
            config := a_config
            create sources.make
        ensure
            config_set: config = a_config
            not_open: not is_open
            no_error: last_error = Void
        end

feature -- Configuration

    config: BIB_CONFIG

feature -- Lifecycle

    open
            -- Open core.db (required) and the optional databases present, read-only, on this processor.
        require
            not_open: not is_open
        do
            -- (Phase 4) sources.open_core (config.core_path); check schema; attach optional sources;
            -- let each registered plug-in attach its private sources (A-012).
        ensure
            open_or_error: is_open xor (last_error /= Void)
            core_checked: is_open implies core_schema_valid
        end

    close
            -- Close every connection held by this processor.
        require
            open: is_open
        do
            -- (Phase 4)
        ensure
            closed: not is_open
        end

feature -- Status

    is_open: BOOLEAN
            -- Are the sources open on this processor?
        do
            Result := sources.is_open
        end

    core_schema_valid: BOOLEAN
            -- Did core.db pass its schema-version and required-table check?

    has_ai_data: BOOLEAN
    has_author_library: BOOLEAN
    has_history: BOOLEAN
            -- Optional databases present and open (history: v2).

    database_edition: STRING_32
            -- Build id of core.db.

    last_error: detachable BIB_ERROR
            -- Why `open` failed.

feature -- Engines

    books: BIB_BOOK_CATALOG
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    parser: BIB_REFERENCE_PARSER
        require open: is_open
        once ("OBJECT") create Result.make (books) end

    versification: BIB_VERSIFICATION_MAP
        require open: is_open
        once ("OBJECT") create Result.make (sources, books) end

    hub: BIB_VERSE_HUB
        require open: is_open
        once ("OBJECT") create Result.make (sources, versification) end

    search: BIB_SEARCH_ENGINE
        require open: is_open
        once ("OBJECT") create Result.make (sources, normalizers) end

    concordance: BIB_CONCORDANCE
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    census: BIB_CENSUS_ENGINE
        require open: is_open
        once ("OBJECT") create Result.make (sources, concordance) end

    shapes: BIB_SHAPE_ENGINE
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    quotations: BIB_QUOTATION_COMPARER
        require open: is_open
        once ("OBJECT") create Result.make (sources, versification) end

    range_viewer: BIB_RANGE_VIEWER
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    journey: BIB_WORD_JOURNEY
        require open: is_open
        once ("OBJECT") create Result.make (sources, versification) end

    divine_names: BIB_DIVINE_NAME_MARKER
        require open: is_open
        once ("OBJECT") create Result.make (sources, normalizers) end

    guides: BIB_GUIDE_ASSEMBLER
        require open: is_open
        once ("OBJECT") create Result.make (Current) end

    related: BIB_RELATED_PASSAGES
        require open: is_open
        once ("OBJECT") create Result.make (sources, has_ai_data) end

    library: BIB_LIBRARY
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    names: BIB_PROPER_NAMES
        require open: is_open
        once ("OBJECT") create Result.make (sources) end

    author_library: BIB_AUTHOR_LIBRARY
        require
            open: is_open
            available: has_author_library
        once ("OBJECT") create Result.make (sources) end

    checks: BIB_CHECK_RUNNER
        once ("OBJECT") create Result.make_default end

    exporter: BIB_EXPORTER
        once ("OBJECT") create Result.make end

    plugins: BIB_PLUGIN_REGISTRY
        do Result := config.plugin_registry end

feature -- Convenience

    verse (a_text: READABLE_STRING_GENERAL): BIB_VERSE_RESULT
            -- Parse `a_text`, map it, and look it up in the default versions.
        require
            open: is_open
            text_not_empty: not a_text.is_empty
        do
            -- (Phase 4)
        ensure
            parse_outcome_carried: Result.parse_outcome /= Void
            ambiguous_never_guessed: Result.parse_outcome.is_ambiguous implies Result.version_count = 0
        end

    rerun (a_method: BIB_METHOD): BIB_ENGINE_RESULT
            -- Re-run a recorded method (Show method, FR-032).
        require
            open: is_open
            rerunnable: a_method.is_rerunnable
        do
            -- (Phase 4) dispatch on a_method.engine_feature
        ensure
            same_edition_same_counts: a_method.database_edition.same_string (database_edition)
                implies Result.method.counts_equal (a_method)
        end

    credits: STRING_32
            -- Credits generated from source_provenance (FR-003).
        require
            open: is_open
        do
            -- (Phase 4)
        end

feature {NONE} -- Implementation

    sources: BIB_SOURCE_SET
            -- This processor's single connection and its attachments.

    normalizers: BIB_NORMALIZER_SET
            -- Hebrew, Greek, English normalizers (shared with the build).

invariant
    error_only_when_closed: last_error /= Void implies not is_open

end
```

### BIB_ENUMERATION and BIB_VERDICT

```eiffel
note
    description: "A closed set of codes with labels."
deferred class
    BIB_ENUMERATION

feature -- Access

    code: INTEGER
    label: STRING_32 deferred end

feature -- Status

    is_valid_code (a_code: INTEGER): BOOLEAN deferred end

invariant
    valid: is_valid_code (code)
end

note
    description: "FITS, PARTIAL, FAILS, NO_DATA. NO_DATA means the tagging is silent; it is not evidence of absence."
class
    BIB_VERDICT

inherit
    BIB_ENUMERATION

create
    make_fits, make_partial, make_fails, make_no_data

feature {NONE} -- Initialization
    make_fits do code := Fits ensure is_fits end
    make_partial do code := Partial ensure is_partial end
    make_fails do code := Fails ensure is_fails end
    make_no_data do code := No_data ensure is_no_data end

feature -- Status
    is_fits: BOOLEAN do Result := code = Fits end
    is_partial: BOOLEAN do Result := code = Partial end
    is_fails: BOOLEAN do Result := code = Fails end
    is_no_data: BOOLEAN do Result := code = No_data end
    is_valid_code (a_code: INTEGER): BOOLEAN do Result := a_code >= Fits and a_code <= No_data end

feature -- Access
    label: STRING_32
        do
            inspect code
            when Fits then Result := "FITS"
            when Partial then Result := "PARTIAL"
            when Fails then Result := "FAILS"
            else Result := "NO_DATA"
            end
        end

feature -- Constants
    Fits: INTEGER = 1
    Partial: INTEGER = 2
    Fails: INTEGER = 3
    No_data: INTEGER = 4
            -- The reporting order: always FITS, PARTIAL, FAILS, NO_DATA.
end
```

### BIB_LICENSE and BIB_PROVENANCE

```eiffel
note
    description: "License of a source: identifier, clauses, credit line. Unknown licenses never ship (D-002)."
class
    BIB_LICENSE

create
    make

feature {NONE} -- Initialization
    make (a_identifier: READABLE_STRING_GENERAL; a_non_commercial, a_share_alike, a_restricted: BOOLEAN; a_credit: READABLE_STRING_GENERAL)
        require
            identifier_not_empty: not a_identifier.is_empty
        do
            identifier := a_identifier.to_string_32
            is_non_commercial := a_non_commercial
            is_share_alike := a_share_alike
            is_restricted := a_restricted
            credit_line := a_credit.to_string_32
        ensure
            identifier_set: identifier.same_string_general (a_identifier)
        end

feature -- Access
    identifier: STRING_32
    credit_line: STRING_32

feature -- Status
    is_unknown: BOOLEAN do Result := identifier.same_string ("UNKNOWN") end
    is_non_commercial: BOOLEAN
    is_share_alike: BOOLEAN
    is_restricted: BOOLEAN
            -- Copyrighted without a license to share, or held under terms the tool cannot meet (e.g. CCAT clause 3).

    may_ship_in_free_tool: BOOLEAN
            -- D-002: attribution always; NC allowed (free tool); unknown and restricted never.
        do
            Result := not is_unknown and not is_restricted
        ensure
            unknown_never_ships: is_unknown implies not Result
            restricted_never_ships: is_restricted implies not Result
        end

invariant
    id_not_empty: not identifier.is_empty
end

note
    description: "Where a fact came from: source, edition, license, grade, caveat; AI-made build-time data is flagged with its method."
class
    BIB_PROVENANCE

create
    make, make_ai_made

feature {NONE} -- Initialization
    make (a_source_key: READABLE_STRING_GENERAL; a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE)
        require
            key_not_empty: not a_source_key.is_empty
        do
            source_key := a_source_key.to_string_32
            edition := a_edition.to_string_32
            license := a_license
            create caveat.make_empty
            create method_label.make_empty
            create model_id.make_empty
        ensure
            not_ai: not is_ai_made
        end

    make_ai_made (a_source_key, a_edition: READABLE_STRING_GENERAL; a_license: BIB_LICENSE; a_method, a_model: READABLE_STRING_GENERAL)
        require
            key_not_empty: not a_source_key.is_empty
            method_named: not a_method.is_empty
            model_named: not a_model.is_empty
        do
            make (a_source_key, a_edition, a_license)
            is_ai_made := True
            method_label := a_method.to_string_32
            model_id := a_model.to_string_32
        ensure
            ai: is_ai_made
        end

feature -- Access
    source_key: STRING_32            -- e.g. "WLC", "SBLGNT", "SWETE", "OB-XREF"
    edition: STRING_32
    license: BIB_LICENSE
    caveat: STRING_32                -- version caveat (FR-005), may be empty
    grade: detachable BIB_GRADE      -- P1-P4 where the source class requires it (timeline, private)
    is_ai_made: BOOLEAN
    method_label: STRING_32          -- "meaning neighbor, bge-m3, computed at build time"
    model_id: STRING_32

feature -- Status
    requires_grade: BOOLEAN
        -- Timeline and private sources must be graded.

invariant
    source_named: not source_key.is_empty
    ai_made_has_method: is_ai_made implies (not method_label.is_empty and not model_id.is_empty)
    graded_when_required: requires_grade implies grade /= Void
end
```

### BIB_FACT [G]

```eiffel
note
    description: "One value the engine asserts, bound to its provenance. A fact cannot exist without provenance."
class
    BIB_FACT [G]

create
    make

feature {NONE} -- Initialization
    make (a_value: G; a_provenance: BIB_PROVENANCE)
        do
            value := a_value
            provenance := a_provenance
        ensure
            value_set: value ~ a_value
            provenance_set: provenance = a_provenance
        end

feature -- Access
    value: G
    provenance: BIB_PROVENANCE

invariant
    has_provenance: provenance /= Void
end
```

### BIB_METHOD

```eiffel
note
    description: "How a number or list was produced. Re-running it on the same database yields the same output (FR-032)."
class
    BIB_METHOD

create
    make

feature -- Access
    engine_feature: STRING_32       -- "verse", "census", "shape", "search", "concordance" ...
    canonical_query: STRING_32      -- clause tree / parameters in canonical text form
    corpus_label: STRING_32
    versions: ARRAY [STRING_32]
    rules_count: INTEGER            -- versification rules applied
    rule_notes: ARRAY [STRING_32]
    counts: ARRAY [INTEGER_64]
    engine_version: STRING_32
    database_edition: STRING_32
    sqlite_version: STRING_32       -- FR-NEW-008

feature -- Status
    is_rerunnable: BOOLEAN
        do Result := not canonical_query.is_empty end

    counts_equal (other: BIB_METHOD): BOOLEAN
        do -- (Phase 4) element-wise equality of counts
        ensure
            symmetric: Result = other.counts_equal (Current)
        end

invariant
    query_recorded: not canonical_query.is_empty
    engine_named: not engine_feature.is_empty
    edition_recorded: not database_edition.is_empty
    sqlite_recorded: not sqlite_version.is_empty
end
```

### BIB_ENGINE_RESULT (deferred)

```eiffel
note
    description: "Every engine answer: method, citations (the sources consulted), success xor error."
deferred class
    BIB_ENGINE_RESULT

feature -- Access
    is_success: BOOLEAN
    error: detachable BIB_ERROR
    method: BIB_METHOD

    citation_count: INTEGER
        do Result := citations.count end

    citation (i: INTEGER): BIB_PROVENANCE
        require
            in_range: i >= 1 and i <= citation_count
        do
            Result := citations [i]
        ensure
            model_agrees: Result = citations_model [i]
        end

feature -- Model
    citations_model: MML_SEQUENCE [BIB_PROVENANCE]
        do
            create Result
            across citations as ic loop Result := Result & ic.item end
        end

feature {NONE} -- Representation
    citations: ARRAYED_LIST [BIB_PROVENANCE]

invariant
    success_xor_error: is_success xor (error /= Void)
    success_is_cited: is_success implies citation_count > 0
    method_present: method /= Void
end
```

### BIB_BUCKETED_RESULT [G -> BIB_FINDING]

```eiffel
note
    description: "FITS, PARTIAL, FAILS and NO_DATA together. A result with fewer than four buckets cannot exist (FR-026)."
class
    BIB_BUCKETED_RESULT [G -> BIB_FINDING]

create
    make

feature {NONE} -- Initialization
    make (a_definition_id: INTEGER_64)
        require
            definition_bound: a_definition_id > 0
        do
            definition_id := a_definition_id
            create fits.make (0); create partial.make (0); create fails.make (0); create no_data.make (0)
        ensure
            all_empty: total = 0
            open_for_filling: not is_sealed
        end

feature -- Access
    definition_id: INTEGER_64

    count (a_verdict: BIB_VERDICT): INTEGER
        do Result := list_for (a_verdict).count end

    item (a_verdict: BIB_VERDICT; i: INTEGER): G
        require
            in_range: i >= 1 and i <= count (a_verdict)
        do Result := list_for (a_verdict) [i] end

    total: INTEGER
        do Result := fits.count + partial.count + fails.count + no_data.count end

    near_miss_count: INTEGER
        -- Findings flagged as near-misses, across buckets.

feature -- Status
    is_sealed: BOOLEAN

feature -- Model
    bucket_model (a_verdict: BIB_VERDICT): MML_SEQUENCE [G]
        do
            create Result
            across list_for (a_verdict) as ic loop Result := Result & ic.item end
        end

feature {BIB_CENSUS_ENGINE, BIB_SHAPE_ENGINE, BIB_SHAPE_PRECOMPUTE} -- Filling
    extend (a_finding: G)
        require
            not_sealed: not is_sealed
        do
            list_for (a_finding.verdict).extend (a_finding)
        ensure
            appended: bucket_model (a_finding.verdict) |=| (old bucket_model (a_finding.verdict) & a_finding)
            total_grown: total = old total + 1
        end

    seal
        require
            not_sealed: not is_sealed
        do
            is_sealed := True
        ensure
            sealed: is_sealed
        end

feature {NONE} -- Representation
    fits, partial, fails, no_data: ARRAYED_LIST [G]

    list_for (a_verdict: BIB_VERDICT): ARRAYED_LIST [G]
        do
            if a_verdict.is_fits then Result := fits
            elseif a_verdict.is_partial then Result := partial
            elseif a_verdict.is_fails then Result := fails
            else Result := no_data
            end
        end

invariant
    four_buckets_present: fits /= Void and partial /= Void and fails /= Void and no_data /= Void
    bound_to_definition: definition_id > 0
end
```

### BIB_REF, BIB_MAPPED_REF and BIB_VERSIFICATION_MAP

```eiffel
note
    description: "A parsed reference in one versification system; not comparable across versions until mapped."
class
    BIB_REF

create
    make, make_with_suffix

feature -- Access
    book_id: INTEGER        -- canonical id (vault bible_books.id, FR-105)
    chapter: INTEGER        -- 0 allowed for prologue chapters (Swete Esther)
    verse: INTEGER          -- 0 allowed for unnumbered titles
    suffix: STRING_8        -- "" or "a".."z" for lettered verses (3 Kgdms 2:35a)
    system: BIB_VERSIFICATION_SYSTEM

invariant
    book_positive: book_id > 0
    chapter_non_negative: chapter >= 0
    verse_non_negative: verse >= 0
    suffix_letters: across suffix as c all c.item.is_lower end
end

note
    description: "A reference that has passed the versification map: hub id, origin, rules applied. Only the map can create one (I-003)."
class
    BIB_MAPPED_REF

create {BIB_VERSIFICATION_MAP}
    make

feature {NONE} -- Initialization
    make (a_hub_id: INTEGER_64; a_origin: BIB_REF; a_rules: ARRAY [BIB_MAPPING_RULE])
        require
            hub_positive: a_hub_id > 0
        do
            hub_id := a_hub_id
            origin := a_origin
            rules := a_rules
        end

feature -- Access
    hub_id: INTEGER_64
    origin: BIB_REF
    rules_applied_count: INTEGER do Result := rules.count end

feature {NONE} -- Representation
    rules: ARRAY [BIB_MAPPING_RULE]

invariant
    hub_id_positive: hub_id > 0
end

note
    description: "Versification as data (D-010): TVTMS + the vault's verified LXX Jeremiah concordance + Swete entries. The only creator of BIB_MAPPED_REF."
class
    BIB_VERSIFICATION_MAP

create
    make

feature -- Mapping
    mapped (a_ref: BIB_REF): detachable BIB_MAPPED_REF
            -- Canonical identity of `a_ref`, or Void when no row maps it.
        require
            book_known: books.has_book (a_ref.book_id)
        do
            -- (Phase 4) look up versification_map; apply rule; create {BIB_MAPPED_REF}.make (...)
        ensure
            identity_kept: attached Result implies Result.origin ~ a_ref
        end

    pair (a_mapped: BIB_MAPPED_REF; a_target: BIB_VERSIFICATION_SYSTEM): BIB_PAIRING
            -- What `a_mapped` is called in `a_target`, with the rules used.
        do
            -- (Phase 4)
        ensure
            same_hub: Result.hub_id = a_mapped.hub_id
            identity_when_same_system: a_target ~ a_mapped.origin.system
                implies (Result.target_count = 1 and then Result.target (1) ~ a_mapped.origin)
            method_names_rules: Result.method.rules_count = Result.rules_count
        end

feature -- Model
    rules_model: MML_SET [BIB_MAPPING_RULE]

feature {NONE} -- Implementation
    books: BIB_BOOK_CATALOG
end
```

### BIB_PARSE_RESULT

```eiffel
note
    description: "Outcome of parsing reference text: exactly one of valid, ambiguous (with candidates) or invalid (with a position). Never a guess."
class
    BIB_PARSE_RESULT

create
    make_valid, make_ambiguous, make_invalid

feature -- Status
    is_valid, is_ambiguous, is_invalid: BOOLEAN

feature -- Access
    reference: detachable BIB_REF
    range_end: detachable BIB_REF
    system: detachable BIB_VERSIFICATION_SYSTEM     -- the system the parser assumed (named, FR-020)
    error_position: INTEGER
    error_message: STRING_32
    candidate_count: INTEGER
    candidate (i: INTEGER): BIB_REF
        require in_range: i >= 1 and i <= candidate_count
        do -- (Phase 4)
        end

feature -- Model
    candidates_model: MML_SEQUENCE [BIB_REF]

invariant
    exactly_one_state: (is_valid.to_integer + is_ambiguous.to_integer + is_invalid.to_integer) = 1
    valid_has_reference: is_valid implies (reference /= Void and system /= Void)
    ambiguous_has_choices: is_ambiguous implies candidate_count >= 2
    invalid_located: is_invalid implies error_position >= 1
end
```

### BIB_VERSION_INFO, BIB_VERSE_TEXT, BIB_OMISSION

```eiffel
note
    description: "Metadata of one shipped version; never a bare 'LXX' (FR-122)."
class
    BIB_VERSION_INFO

feature -- Access
    code: STRING_8                  -- "BSB", "WLC", "SWETE", "WH" ...
    display_label: STRING_32        -- "LXX (Swete)", "Judges (Swete; Codex B)"
    edition: STRING_32
    language: STRING_8             -- "hbo", "grc", "eng", "lat"
    system: BIB_VERSIFICATION_SYSTEM
    caveat: STRING_32               -- FR-005
    text_quality_caveat: STRING_32  -- Swete: "Digital text from OCR; it may contain errors."
    license: BIB_LICENSE
    provenance: BIB_PROVENANCE

feature -- Status
    is_septuagint: BOOLEAN
    is_swete: BOOLEAN
    is_right_to_left: BOOLEAN
    has_morphology: BOOLEAN         -- False for Swete (no open morphology)
    has_caveat: BOOLEAN do Result := not caveat.is_empty end
    has_book (a_book_id: INTEGER): BOOLEAN

invariant
    code_not_empty: not code.is_empty
    septuagint_labeled_with_edition: is_septuagint implies (not edition.is_empty and display_label.has_substring (edition))
    never_bare_lxx: not display_label.same_string ("LXX")
    swete_is_septuagint: is_swete implies is_septuagint
    swete_quality_caveat: is_swete implies not text_quality_caveat.is_empty
    rtl_for_hebrew: language.same_string ("hbo") implies is_right_to_left
end

note
    description: "Why a verse has no text in a version. Never an empty string (FR-009, I-005)."
class
    BIB_OMISSION

inherit
    BIB_ENUMERATION

create
    make

feature -- Constants
    Edition_omitted: INTEGER = 1      -- "omitted in this edition (WH)"
    Edition_absent: INTEGER = 2       -- "absent from Swete's edition" (Codex B gap)
    Digital_text_loss: INTEGER = 3    -- "missing from this digital text (OCR loss)"
    Not_in_canon: INTEGER = 4         -- Tobit in the BSB
    Quarantined: INTEGER = 5          -- defect-register class A

feature -- Access
    reason_text: STRING_32            -- shown in place of the verse
    is_quarantined: BOOLEAN do Result := code = Quarantined end
    is_valid_code (a_code: INTEGER): BOOLEAN do Result := a_code >= Edition_omitted and a_code <= Quarantined end
    label: STRING_32 do Result := reason_text end

invariant
    reason_given: not reason_text.is_empty
end

note
    description: "One verse in one version: exact display text (never edited) or an omission, with provenance and repair state."
class
    BIB_VERSE_TEXT

feature -- Access
    reference: BIB_REF
    version: BIB_VERSION_INFO
    display_text: detachable STRING_32       -- exact Unicode; MapM NBSP preserved (FR-008)
    omission: detachable BIB_OMISSION
    provenance: BIB_PROVENANCE
    repair_state: BIB_REPAIR_STATE           -- as-imported / repaired / collated (Swete; A-001)
    is_quarantined: BOOLEAN do Result := attached omission as o and then o.is_quarantined end

invariant
    text_xor_omission: (display_text /= Void) xor (omission /= Void)
    provenance_present: provenance /= Void
end
```

### BIB_NORMALIZER (deferred)

```eiffel
note
    description: "Search-form normalization shared by the build and the query path (D-009). Display never comes from it."
deferred class
    BIB_NORMALIZER

feature -- Normalization
    normalized (a_text: READABLE_STRING_GENERAL): STRING_32
        deferred
        ensure
            idempotent: normalized (Result).same_string (Result)
            no_combining_marks: not has_combining_mark (Result)
            not_longer: Result.count <= a_text.count
            empty_preserved: a_text.is_empty implies Result.is_empty
        end

feature -- Status
    has_combining_mark (a_text: READABLE_STRING_32): BOOLEAN
            -- Does `a_text` contain a nonspacing/enclosing/spacing combining mark (Mn/Me/Mc)? (via LG-01)
        deferred
        end
end
```

### BIB_CENSUS_DEFINITION

```eiffel
note
    description: "A question written down before counting (FR-025, I-002). Editable until the first run; then frozen and only versioned."
class
    BIB_CENSUS_DEFINITION

create
    make

feature {NONE} -- Initialization
    make (a_question: READABLE_STRING_GENERAL)
        require
            question_not_empty: not a_question.is_empty
        do
            question := a_question.to_string_32
            version := 1
            -- (Phase 4) lineage_id, empty criteria, corpus, controls, holds_if, fails_if; control_seed from a fixed generator stored here
        ensure
            first_version: version = 1
            editable: not is_frozen
        end

feature -- Access
    id: INTEGER_64                  -- 0 until stored
    lineage_id: INTEGER_64
    version: INTEGER
    question: STRING_32
    corpus_label: STRING_32
    corpus: BIB_SEARCH_SCOPE
    criteria: BIB_QUERY
    holds_if: STRING_32
    fails_if: STRING_32
    control_seed: INTEGER_64
    controls_count: INTEGER
    first_run_id: INTEGER_64

feature -- Status
    is_frozen: BOOLEAN
    is_stored: BOOLEAN do Result := id > 0 end
    is_complete: BOOLEAN
        do
            Result := not question.is_empty and not corpus_label.is_empty and criteria.clause_count > 0
                and controls_count >= 1 and not holds_if.is_empty and not fails_if.is_empty
        end

feature -- Model
    controls_model: MML_SEQUENCE [BIB_KEY]

feature -- Element change (only before the first run)
    set_question (a_text: READABLE_STRING_GENERAL)
        require
            not_frozen: not is_frozen
            text_not_empty: not a_text.is_empty
        do
            question := a_text.to_string_32
        ensure
            set: question.same_string_general (a_text)
            controls_unchanged: controls_model |=| old controls_model
        end

    add_control (a_key: BIB_KEY)
        require
            not_frozen: not is_frozen
            not_target: not criteria.mentions_key (a_key)
        do
            -- (Phase 4)
        ensure
            appended: controls_model |=| (old controls_model & a_key)
        end

    -- set_corpus, set_criteria, remove_control, set_holds_if, set_fails_if: same pattern (require not_frozen; frame on the others)

feature {BIB_CENSUS_ENGINE, BIB_CENSUS_JOB} -- Freezing
    freeze (a_run_id: INTEGER_64)
        require
            complete: is_complete
            not_frozen: not is_frozen
            run_id_positive: a_run_id > 0
        do
            is_frozen := True
            first_run_id := a_run_id
        ensure
            frozen: is_frozen
            first_run_recorded: first_run_id = a_run_id
            controls_unchanged: controls_model |=| old controls_model
        end

feature -- Versioning
    new_version: like Current
        require
            frozen: is_frozen
        do
            -- (Phase 4) deep copy content; version + 1; same lineage; not frozen; id = 0
        ensure
            next_version: Result.version = version + 1
            same_lineage: Result.lineage_id = lineage_id
            editable: not Result.is_frozen
            content_copied: Result.question.same_string (question) and Result.controls_model |=| controls_model
        end

invariant
    frozen_has_run: is_frozen implies first_run_id > 0
    version_positive: version >= 1
    seed_recorded: control_seed /= 0
end
```

### BIB_SHAPE (deferred) and BIB_SHAPE_ENGINE

```eiffel
note
    description: "A named structural pattern (shape.db). Definitions are written before the run; T3 shapes may frame a question, never score one."
deferred class
    BIB_SHAPE

feature -- Definition (all fixed before any run)
    slug: STRING_32 deferred end
    name: STRING_32 deferred end
    tier: BIB_SHAPE_TIER deferred end
    definition_formal: STRING_32 deferred end
    definition_prose: STRING_32 deferred end
    could_fail_if: STRING_32 deferred end
    seeded_by: STRING_32 deferred end           -- self / larry / vault:<file> / scholar:<name> / foil:<position>
    required_columns: ARRAY [STRING_8] deferred end
    corpus: BIB_SEARCH_SCOPE deferred end

feature -- Classification
    classify (a_candidate: BIB_SHAPE_CANDIDATE): BIB_SHAPE_FINDING
        require
            in_corpus: corpus.contains (a_candidate.reference)
        deferred
        ensure
            absent_tag_is_no_data: not a_candidate.has_required_tags (required_columns) implies Result.verdict.is_no_data
            tier_carried: Result.tier ~ tier
            grounds_given: not Result.grounds.is_empty
        end
end

note
    description: "Runs shapes (build) and returns their evidence (run time). Refuses T3 as evidence (ROE Rule 21 S3)."
class
    BIB_SHAPE_ENGINE

create
    make

feature -- Access
    registry: BIB_SHAPE_REGISTRY

feature -- Evidence
    evidence (a_shape: BIB_SHAPE): BIB_SHAPE_RUN
        require
            not_judgment: not a_shape.tier.is_judgment
            registered: registry.has_slug (a_shape.slug)
        do
            -- (Phase 4) read shape_instance by verdict, all four, ordered by reference
        ensure
            sealed: Result.buckets.is_sealed
            tier_carried: Result.tier ~ a_shape.tier
            method_recorded: Result.method.engine_feature.same_string ("shape")
        end
end
```

### BIB_QUOTATION_RESULT

```eiffel
note
    description: "They Chose: NT, LXX (Swete) and MT side by side with the computed agreement class and an edition note."
class
    BIB_QUOTATION_RESULT

inherit
    BIB_ENGINE_RESULT

feature -- Access
    quotation: detachable BIB_QUOTATION
    alignment: detachable BIB_ALIGNMENT
    agreement: BIB_AGREEMENT_CLASS
    verdict_line: STRING_32          -- "Heb 8:8-12 agrees with the Septuagint (LXX Jer 38:31-34) against the Hebrew (MT Jer 31:31-34)"
    edition_note: STRING_32          -- "Computed against Swete; may differ for Rahlfs." (+ OCR note)
    lxx_from_uncollated_ocr: BOOLEAN

invariant
    edition_note_present: not edition_note.is_empty
    verdict_needs_alignment: not agreement.is_no_data implies alignment /= Void
    ocr_flagged: lxx_from_uncollated_ocr implies edition_note.has_substring ("OCR")
end
```

### BIB_RELATED_PASSAGE and BIB_AUTHOR_DOC

```eiffel
note
    description: "A related passage with the reason it is listed; AI-made neighbors are always labeled (D-016, NFR-014)."
class
    BIB_RELATED_PASSAGE

feature -- Access
    target: BIB_REF
    reason_count: INTEGER
    reason (i: INTEGER): STRING_32       -- "cross-reference (OpenBible, 57 votes)", "shares a rare word", "AI-made: meaning neighbor"
        require in_range: i >= 1 and i <= reason_count
        do -- (Phase 4)
        end
    is_ai_made: BOOLEAN
    ai_label: STRING_32
    provenance: BIB_PROVENANCE

invariant
    has_reason: reason_count >= 1
    ai_made_has_label: is_ai_made implies not ai_label.is_empty
    ai_flag_matches_provenance: is_ai_made = provenance.is_ai_made
end

note
    description: "A document in Larry's author library (rix.db). Status travels with it everywhere (D-019)."
class
    BIB_AUTHOR_DOC

feature -- Access
    doc_id: INTEGER_64
    title: STRING_32
    relpath: STRING_32
    collection: STRING_32
    status: BIB_DOC_STATUS              -- framework / verdict / draft / unmarked / withdrawn / ungated
    voice: BIB_VOICE                    -- author
    banner_text: STRING_32              -- "Withdrawn by the author. Kept for the record; not authority." etc.
    provenance: BIB_PROVENANCE

feature -- Status
    cites (a_hub_id: INTEGER_64): BOOLEAN

invariant
    status_valid: status.is_valid_code (status.code)
    voice_author: voice.is_author
    title_present: not title.is_empty
    banner_for_flagged: (status.is_withdrawn or status.is_ungated or status.is_draft) implies not banner_text.is_empty
end
```

### BIB_AI_ADAPTER, BIB_AI_POST_CHECK, BIB_AI_TEXT

```eiffel
note
    description: "Optional AI phrasing of one engine answer. Release 1 binds the null adapter. Input is an engine result, never free text (I-001)."
deferred class
    BIB_AI_ADAPTER

feature -- Explanation
    explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
        require
            engine_answer: a_result.is_success
            cited: a_result.citation_count > 0
        deferred
        ensure
            rests_on_input: attached Result implies Result.basis = a_result
            labeled: attached Result implies Result.is_labeled
        end
end

class
    BIB_NULL_AI_ADAPTER

inherit
    BIB_AI_ADAPTER

feature -- Explanation
    explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
        do
            -- Release 1: no model runs on the user's machine (D-016).
        ensure then
            never_produces: Result = Void
        end
end

note
    description: "The FR-053 post-check and the only creator of BIB_AI_TEXT."
class
    BIB_AI_POST_CHECK

feature -- Factory
    checked (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL): BIB_AI_TEXT
        require
            basis_success: a_basis.is_success
            basis_cited: a_basis.citation_count > 0
            model_named: not a_model_id.is_empty
        do
            create Result.make (a_wording, a_basis, a_model_id,
                has_unsupported_digit (a_wording, a_basis)
                or has_unsupported_reference (a_wording, a_basis)
                or has_unsupported_script (a_wording, a_basis))
        ensure
            basis_kept: Result.basis = a_basis
            withheld_if_new_facts: (has_unsupported_digit (a_wording, a_basis) or has_unsupported_reference (a_wording, a_basis)
                or has_unsupported_script (a_wording, a_basis)) implies Result.is_withheld
        end

feature -- Checks
    has_unsupported_digit (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
    has_unsupported_reference (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
    has_unsupported_script (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT): BOOLEAN
            -- Any digit run, reference pattern (via BIB_REFERENCE_DETECTOR) or Hebrew/Greek run (via BIB_SCRIPT_CLASSIFIER)
            -- in `a_wording` that the rendered basis does not contain.
end

note
    description: "Model wording about one engine answer: labeled, post-checked, never a fact source."
class
    BIB_AI_TEXT

create {BIB_AI_POST_CHECK}
    make

feature {NONE} -- Initialization
    make (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL; a_withheld: BOOLEAN)
        do
            basis := a_basis
            model_id := a_model_id.to_string_32
            is_withheld := a_withheld
            if a_withheld then create displayable_text.make_empty else displayable_text := a_wording.to_string_32 end
            label := Ai_label
        end

feature -- Access
    basis: BIB_ENGINE_RESULT
    displayable_text: STRING_32
    model_id: STRING_32
    label: STRING_32
    is_withheld: BOOLEAN
    is_labeled: BOOLEAN do Result := label.same_string (Ai_label) end

feature -- Constants
    Ai_label: STRING_32 = "AI wording; the facts above are from the engine"

invariant
    label_present: is_labeled
    cites_engine: basis.is_success and basis.citation_count > 0
    model_named: not model_id.is_empty
    withheld_text_hidden: is_withheld implies displayable_text.is_empty
end
```

### BIB_JOB [R], BIB_CANCEL_TOKEN, BIB_JOB_MAILBOX

```eiffel
note
    description: "Chunked long work on its own SCOOP processor. Reports through a separate mailbox and stops through a separate token (A-006); one chunk = one book or one guide section (A-005)."
deferred class
    BIB_JOB [R -> BIB_ENGINE_RESULT]

feature -- Status
    is_started, is_done, is_cancelled, has_result: BOOLEAN
    chunks_done, chunk_total: INTEGER

feature -- Execution
    run_to_completion (a_token: separate BIB_CANCEL_TOKEN; a_mailbox: separate BIB_JOB_MAILBOX)
        require
            not_started: not is_started
        do
            is_started := True
            from until is_done loop
                if cancel_requested (a_token) then
                    is_cancelled := True; is_done := True
                    close_cancelled (a_mailbox)
                else
                    step
                    report (a_mailbox)
                end
            end
            if not is_cancelled then close_finished (a_mailbox) end
        ensure
            finished: is_done
            cancel_observed: is_cancelled implies not has_result
        end

    step
            -- Process exactly one bounded chunk.
        require
            started: is_started
            not_finished: not is_done
        deferred
        ensure
            progressed: chunks_done = old chunks_done + 1 or is_done
        end

feature -- Result
    result_value: R
        require
            done: is_done
            not_cancelled: not is_cancelled
            succeeded: has_result
        deferred
        end

feature {NONE} -- Mailbox and token access (short separate calls)
    cancel_requested (a_token: separate BIB_CANCEL_TOKEN): BOOLEAN
        do Result := a_token.is_cancel_requested end
    report (a_mailbox: separate BIB_JOB_MAILBOX) deferred end
    close_cancelled (a_mailbox: separate BIB_JOB_MAILBOX) do a_mailbox.close_cancelled end
    close_finished (a_mailbox: separate BIB_JOB_MAILBOX) deferred end

invariant
    progress_bounded: chunks_done >= 0 and chunks_done <= chunk_total
    cancelled_has_no_result: is_cancelled implies not has_result
end

note
    description: "A cancel request shared between the GUI and one job; lives on its own processor so the GUI never waits on the job."
class
    BIB_CANCEL_TOKEN

create
    make

feature {NONE} -- Initialization
    make do ensure not is_cancel_requested end

feature -- Status
    is_cancel_requested: BOOLEAN

feature -- Command
    request_cancel
        do is_cancel_requested := True ensure requested: is_cancel_requested end
            -- Monotone: no reset feature exists.
end

note
    description: "Progress, pages and the final outcome of one job, as copied plain values; written by the job, polled by the GUI."
class
    BIB_JOB_MAILBOX

create
    make

feature -- Status
    progress: REAL_64
    page_count: INTEGER
    is_closed, is_done, is_cancelled, is_failed: BOOLEAN
    error_text: STRING_32

feature -- Access
    page (n: INTEGER): BIB_JOB_PAGE
        require in_range: n >= 1 and n <= page_count
        do -- (Phase 4)
        end

feature -- Model
    pages_model: MML_SEQUENCE [BIB_JOB_PAGE]

feature -- Commands (called by the job)
    post_page (a_page: BIB_JOB_PAGE)
        require
            open: not is_closed
            next_in_order: a_page.number = page_count + 1
        do -- (Phase 4) store a copy
        ensure
            appended: pages_model |=| (old pages_model & a_page)
            progress_unchanged: progress = old progress
        end

    set_progress (a_fraction: REAL_64)
        require
            in_range: a_fraction >= 0.0 and a_fraction <= 1.0
            monotone: a_fraction >= progress
        do progress := a_fraction
        ensure set: progress = a_fraction
        end

    close_done, close_cancelled
    close_failed (a_error: STRING_32)
        -- Each ensures: is_closed; exactly one outcome; close_cancelled drops pages (page_count = 0).

invariant
    progress_bounded: progress >= 0.0 and progress <= 1.0
    outcome_exclusive: is_closed implies (is_done.to_integer + is_cancelled.to_integer + is_failed.to_integer) = 1
    cancelled_discards: is_cancelled implies page_count = 0
end
```

### BIB_SOURCE_SET

```eiffel
note
    description: "One SQLite connection per processor (DR-019) with its attached databases (at most 10, DR-020). Never passed between processors."
class
    BIB_SOURCE_SET

create
    make

feature -- Status
    is_open: BOOLEAN
    attached_count: INTEGER
    sqlite_version: STRING_32
    last_error: detachable BIB_ERROR

feature -- Model
    attached_model: MML_MAP [STRING_8, STRING_32]

feature -- Commands
    open_core (a_path: READABLE_STRING_GENERAL)
        require not_open: not is_open
        do -- (Phase 4) SIMPLE_SQL_DATABASE.make_read_only; record sqlite_version
        ensure open_or_error: is_open xor (last_error /= Void)
        end

    attach (a_alias: STRING_8; a_path: READABLE_STRING_GENERAL)
        require
            open: is_open
            alias_valid: is_valid_alias (a_alias)
            not_attached: not attached_model.domain [a_alias]
            under_limit: attached_count < Max_attached
        do -- (Phase 4) ATTACH DATABASE ... AS <alias> (read-only URI)
        ensure
            attached_now: last_error = Void implies attached_model |=| old attached_model.updated (a_alias, a_path.to_string_32)
            count_grown: last_error = Void implies attached_count = old attached_count + 1
        end

feature -- Constants
    Max_attached: INTEGER = 10

invariant
    within_limit: attached_count >= 0 and attached_count <= Max_attached
end
```

### BIB_LICENSE_GATE, BIB_BUILD_STEP and BIB_DISTRIBUTION_BUILDER (L-BUILD)

```eiffel
note
    description: "The build's refusal to ship unknown or restricted sources (FR-004); records NC and SA clauses."
class
    BIB_LICENSE_GATE

feature -- Decision
    ship_allowed (a_source: BIB_PINNED_SOURCE): BOOLEAN
        do
            Result := a_source.ship and a_source.license.may_ship_in_free_tool
        ensure
            unknown_refused: a_source.license.is_unknown implies not Result
            restricted_refused: a_source.license.is_restricted implies not Result
            flag_respected: not a_source.ship implies not Result
        end

    check_manifest (a_manifest: BIB_BUILD_MANIFEST)
        do -- (Phase 4)
        ensure
            refusal_named: has_refusal implies across refused_keys as k all refusal_message.has_substring (k.item) end
        end

feature -- Status
    has_refusal: BOOLEAN
    refused_keys: ARRAYED_LIST [STRING_8]
    refusal_message: STRING_32
end

note
    description: "One deterministic stage of a build: no clock reads, ordered output, progress and a named error."
deferred class
    BIB_BUILD_STEP

feature -- Access
    name: STRING_8 deferred end
    last_error: detachable BIB_ERROR
    rows_written: INTEGER_64

feature -- Execution
    execute (a_context: BIB_BUILD_CONTEXT; a_db: SIMPLE_SQL_DATABASE)
        require
            context_ready: a_context.is_ready
            writable: not a_db.is_read_only
        deferred
        ensure
            provenance_for_rows: last_error = Void implies rows_without_provenance (a_db) = 0
        end

feature -- Status
    rows_without_provenance (a_db: SIMPLE_SQL_DATABASE): INTEGER_64
        deferred end
end

note
    description: "Assembles core.db from pinned sources (D-005): verify, gate, import, repair, defect rules, normalize, map, FTS, checksum, credits."
class
    BIB_DISTRIBUTION_BUILDER

feature -- Execution
    build (a_context: BIB_BUILD_CONTEXT)
        require
            manifest_hashes_verified: a_context.manifest.all_hashes_verified
            gate_passed: not a_context.license_gate.has_refusal
            steps_registered: steps_model.count > 0
        do -- (Phase 4) run each step in order inside a transaction per step; stop at the first error
        ensure
            all_rows_have_provenance: succeeded implies rows_without_provenance = 0
            no_unknown_license_shipped: succeeded implies shipped_unknown_license_count = 0
            checksums_recorded: succeeded implies checksum_count = table_count
            credits_generated: succeeded implies credits_match_provenance
            steps_unchanged: steps_model |=| old steps_model
        end

feature -- Status
    succeeded: BOOLEAN
    rows_without_provenance, shipped_unknown_license_count: INTEGER_64
    checksum_count, table_count: INTEGER
    credits_match_provenance: BOOLEAN

feature -- Model
    steps_model: MML_SEQUENCE [BIB_BUILD_STEP]
end
```

### BIB_PLUGIN_REGISTRY

```eiffel
note
    description: "Compiled-in private plug-ins (A-012). Empty in the public build; Larry's private root registers his before SIMPLE_BIBLE.open."
class
    BIB_PLUGIN_REGISTRY

create
    make

feature -- Status
    plugin_count: INTEGER
    is_sealed: BOOLEAN
    has_plugin (a_name: STRING_8): BOOLEAN

feature -- Model
    plugins_model: MML_SEQUENCE [BIB_PLUGIN]

feature -- Commands
    register (a_plugin: BIB_PLUGIN)
        require
            not_sealed: not is_sealed
            not_registered: not has_plugin (a_plugin.name)
        do -- (Phase 4)
        ensure
            appended: plugins_model |=| (old plugins_model & a_plugin)
        end

    seal
        do is_sealed := True ensure sealed: is_sealed end

invariant
    count_non_negative: plugin_count >= 0
end
```

## Remaining classes (interface by reference)

The remaining Release 1 classes follow the contracts in 05 and the interfaces in 06; their one-line responsibilities are in 04 §1. Notable obligations carried into /eiffel.contracts:

- `BIB_HEBREW_NORMALIZER`, `BIB_GREEK_NORMALIZER`, `BIB_ENGLISH_NORMALIZER`: `ensure then` clauses of 05; Greek waits on LG-01.
- `BIB_REFERENCE_DETECTOR`: function-for-function port of `build_rix_db.py` R12 (alias table, colon and period forms, de-duplication) plus `scripture_detect.py`'s explicit detector; golden fixtures from both scripts.
- `BIB_QUOTATION_DETECTOR`: shingle matcher (MIN_N 6, MAX_N 14) reporting match length; never treated as evidence until read.
- `BIB_RIX_DB_BUILDER`, `BIB_RIX_RULES`, `BIB_VAULT_WALKER`, `BIB_VAULT_DOCUMENT`: rules R1-R15 v2.1 exactly; accepted by `BIB_DB_COMPARATOR` at 100% against `build_rix_db.py`'s output on the same vault snapshot (`--max-mtime`).
- `BIB_SWETE_REPAIR`: the 12-SEPTUAGINT build checklist as postconditions (`no_verse_starts_with_roman_numeral_without_repair`, `every_gap_classified`, `apparatus_dropped`).
- `BIB_CENSUS_ENGINE`, `BIB_CONTROL_SET`, `BIB_CENSUS_RUN`, `BIB_SEARCH_ENGINE`, `BIB_QUOTATION_COMPARER`, `BIB_AUTHOR_LIBRARY`, `BIB_EXPORTER`, `BIB_GUIDE`, `BIB_COMMAND_SET`, `BIB_LINK_HUB`, `BIB_RESULT_ADAPTER`: 05's contracts verbatim.

## Dependencies

All libraries below were confirmed present in `D:\prod` on 2026-10-06 (ECF file named). Versions are the `package.json` / CHANGELOG values seen today where present.

| Library | ECF | Purpose | Layer | Version seen |
|---------|-----|---------|-------|--------------|
| simple_sql | `simple_sql/simple_sql.ecf` | All SQLite access, FTS5, read-only open, vector store (v2) | LIB | 0.1.0 (package.json) |
| eiffel_sqlite_2025 | `eiffel_sqlite_2025/sqlite_2025.ecf` (through simple_sql) | SQLite 3.31.1 binding; FT-01/FT-02 | LIB | header 3.31.1 |
| simple_mml | `simple_mml/simple_mml.ecf` | Model queries in postconditions | LIB | - |
| simple_encoding | `simple_encoding/simple_encoding.ecf` | UTF-8/32; NFD/NFC + Mn after LG-01 | LIB | - |
| simple_regex | `simple_regex/simple_regex.ecf` | Regex search, reference patterns, checks | LIB | 1.0.1 |
| simple_json | `simple_json/simple_json.ecf` | Method records, user-store payloads, golden fixtures | LIB | 0.2.0 |
| simple_hash | `simple_hash/simple_hash.ecf` | SHA-256 (manifest, checksums, fixtures) | LIB, BUILD | 0.1.0 |
| simple_diff | `simple_diff/simple_diff.ecf` | LCS diff under `BIB_TOKEN_DIFF` (token keys mapped to ASCII lines) | LIB | - |
| simple_file | `simple_file/simple_file.ecf` | Paths, data-folder discovery | LIB | 0.1.0 |
| simple_toml | `simple_toml/simple_toml.ecf` | `bible.toml` configuration | LIB | 0.1.2 |
| simple_logger | `simple_logger/simple_logger.ecf` | Diagnostics | LIB | 0.1.0 |
| simple_datetime | `simple_datetime/simple_datetime.ecf` | User-record dates, memory scheduling (never in builders' rows) | LIB | 0.1.1 |
| simple_xml | `simple_xml/simple_xml.ecf` | OSIS (OSHB) and TEI (Swete) imports | BUILD | 0.1.0 |
| simple_csv | `simple_csv/simple_csv.ecf` | TSV imports (STEPBible, MACULA, OpenBible) | BUILD | 0.1.0 |
| simple_onnx | `simple_onnx/simple_onnx.ecf` | bge-m3 embeddings at build time (ONNX Runtime 1.17.3, CPU) | BUILD (v2: LIB) | - |
| simple_graph | `simple_graph/simple_graph.ecf` | Passage graph for related-passage precompute | BUILD | 0.1.0 |
| simple_cli | `simple_cli/simple_cli.ecf` | `bible.exe` and `bible_build` arguments | CLI, BUILD | 0.1.0 |
| simple_console | `simple_console/simple_console.ecf` | REPL | CLI | 1.2.0 |
| simple_widgets | `simple_widgets/simple_widgets.ecf` | Native face | GUI | 0.8.1 (README) |
| simple_shaping | `simple_shaping/simple_shaping.ecf` | Shaped Hebrew/Greek, bidi | GUI | 0.1.0 pre-release |
| simple_cairo | `simple_cairo/simple_cairo.ecf` | Canvas | GUI | 1.3.0 + Unreleased |
| simple_shell | `simple_shell/simple_shell.ecf` | Window, pump, keys | GUI | 1.12.0 |
| simple_testing | `simple_testing/simple_testing.ecf` | `TEST_SET_BASE` suites | Tests | 0.1.0 |
| simple_process | `simple_process/simple_process.ecf` | Hidden llama-server spawn (externals marked `blocking`, PR #1) | v3 | 1.0.1 |
| simple_winhttp | `simple_winhttp/simple_winhttp.ecf` | Loopback and BYOK calls (`c_send` marked `blocking`) | v3 | 0.1.1 |

**Not used:** simple_http (libcurl not redistributable, C-009), simple_browser/simple_web/simple_htmx/simple_alpine (WebView2 path withdrawn by D-006), Vision2/simple_vision, any Python.

**C code:** none planned. Reserved prefix `sbib_`.

## File Structure

```
D:\prod\simple_bible\
├── simple_bible.ecf                  (targets: simple_bible, bible_build, bible, simple_bible_app, simple_bible_tests)
├── README.md, CHANGELOG.md, docs\index.html   (C-018)
├── src\                              (L-LIB)
│   ├── simple_bible.e  bib_config.e
│   ├── core\        bib_enumeration.e bib_book.e bib_book_catalog.e bib_versification_system.e bib_ref.e
│   │                bib_ref_range.e bib_mapped_ref.e bib_key.e bib_lemma_key.e bib_strongs_key.e bib_morph_code.e bib_word_id.e
│   ├── provenance\  bib_license.e bib_provenance.e bib_grade.e bib_voice.e bib_fact.e bib_method.e
│   │                bib_engine_result.e bib_list_result.e bib_error.e bib_verdict.e bib_finding.e bib_bucketed_result.e
│   ├── data\        bib_data_source.e bib_core_source.e bib_ai_data_source.e bib_user_store.e bib_source_set.e
│   ├── text\        bib_normalizer.e bib_hebrew_normalizer.e bib_greek_normalizer.e bib_english_normalizer.e
│   │                bib_stemmer.e bib_stop_words.e bib_pointing_reducer.e bib_transliterator.e bib_script_classifier.e
│   │                bib_edit_distance.e bib_normalizer_set.e
│   ├── reference\   bib_reference_parser.e bib_parse_result.e bib_reference_detector.e bib_quotation_detector.e
│   ├── versification\ bib_versification_map.e bib_mapping_rule.e bib_pairing.e
│   ├── hub\         bib_verse_hub.e bib_version_info.e bib_verse_text.e bib_omission.e bib_word.e
│   │                bib_verse_result.e bib_cross_reference.e bib_morph_expander.e bib_repair_state.e
│   ├── search\      bib_query.e bib_query_clause.e bib_query_parser.e bib_search_scope.e bib_search_engine.e
│   │                bib_search_result.e bib_hit.e bib_concordance.e bib_count_table.e bib_rank_fusion.e bib_token_diff.e
│   ├── census\      bib_census_definition.e bib_control_set.e bib_census_engine.e bib_census_run.e bib_control_comparison.e
│   ├── shape\       bib_shape.e bib_shape_tier.e bib_shape_registry.e bib_shape_engine.e bib_shape_run.e
│   │                bib_shape_finding.e bib_shape_lint.e bib_shape_candidate.e  shapes\bib_shape_<slug>.e
│   ├── quotation\   bib_quotation_index.e bib_quotation.e bib_alignment.e bib_agreement_class.e
│   │                bib_quotation_comparer.e bib_quotation_result.e
│   ├── study\       bib_range_viewer.e bib_range_result.e bib_word_journey.e bib_journey_result.e bib_divine_name_marker.e
│   │                bib_guide_assembler.e bib_guide.e bib_guide_section.e bib_related_passages.e bib_related_passage.e
│   │                bib_library.e bib_library_entry.e bib_proper_names.e
│   ├── user\        bib_user_item.e bib_note.e bib_highlight.e bib_bookmark.e bib_tag_assignment.e bib_prayer_item.e
│   │                bib_memory_card.e bib_visit.e bib_collection.e bib_memory_scheduler.e bib_reading_plan.e
│   │                bib_note_store.e bib_db_note_store.e bib_markdown_note_store.e bib_user_backup.e
│   ├── checks\      bib_check.e bib_check_finding.e bib_check_runner.e bib_check_first_use_gloss.e bib_check_bare_script.e
│   │                bib_check_capital_after_colon.e bib_check_citation_complete.e bib_check_provenance_tag.e
│   ├── author\      bib_author_library.e bib_author_doc.e bib_doc_status.e
│   ├── export\      bib_exporter.e bib_attribution.e
│   ├── jobs\        bib_job.e bib_search_job.e bib_census_job.e bib_guide_job.e bib_cancel_token.e bib_job_mailbox.e bib_job_page.e
│   ├── plugin\      bib_plugin.e bib_plugin_registry.e bib_private_source.e bib_lens.e bib_lens_result.e
│   └── ai\          bib_ai_adapter.e bib_null_ai_adapter.e bib_ai_text.e bib_ai_post_check.e
├── build\                            (L-BUILD; 44 classes; root bib_build_app.e)
│   ├── pipeline\    bib_build_app.e bib_build_context.e bib_build_manifest.e bib_pinned_source.e bib_license_gate.e
│   │                bib_build_step.e bib_distribution_builder.e bib_schema_step.e bib_book_catalog_step.e
│   ├── import\      bib_import_oshb.e bib_import_morphgnt.e bib_import_macula_greek.e bib_import_swete.e
│   │                bib_import_plain_text_version.e bib_import_stepbible.e bib_import_strongs.e
│   │                bib_import_cross_references.e bib_import_ubs_parallels.e bib_import_library_module.e
│   ├── rules\       bib_swete_repair.e bib_defect_rule.e bib_defect_rules_step.e bib_normalize_step.e
│   │                bib_versification_step.e bib_fts_step.e bib_table_checksum.e bib_credits_generator.e
│   ├── verify\      bib_db_comparator.e bib_compare_spec.e bib_compare_report.e
│   ├── rix\         bib_rix_db_builder.e bib_rix_rules.e bib_vault_walker.e bib_vault_document.e
│   └── precompute\  bib_precompute_job.e bib_lemma_frequency_precompute.e bib_gloss_table_precompute.e
│                    bib_related_precompute.e bib_embedding_precompute.e bib_alignment_precompute.e
│                    bib_shape_precompute.e bib_sparse_vector.e bib_tfidf_index.e bib_passage_graph.e
├── cli\                              (L-CLI) bib_cli_app.e bib_repl.e bib_command.e bib_command_set.e
│                                      bib_command_parser.e bib_text_renderer.e bib_command_outcome.e  commands\bib_cmd_<name>.e
├── gui\                              (L-GUI) bib_gui_app.e bib_main_window.e bib_panel.e bib_link_hub.e bib_active_reference.e
│                                      bib_layout_store.e bib_state_machine.e bib_engine_client.e bib_result_adapter.e
│                                      bib_provenance_chip.e bib_job_monitor.e bib_job_handle.e bib_word_card.e
│                                      panels\bib_p01_bible_text.e .. bib_p11_navigator.e  dialogs\bib_d01_go_to.e .. bib_d10_ambiguous_reference.e
├── fonts\                            (OFL fonts with license files; provenance rows; GW-01)
├── installer\simple_bible.iss        (from ledger I-01; core edition)
└── test\
    ├── test_app.e  lib_tests.e       (fleet test convention; TEST_SET_BASE)
    ├── test_reference_parser.e  test_versification.e  test_verse_hub.e  test_normalizers.e  test_search.e
    ├── test_census.e  test_shapes.e  test_quotation.e  test_study.e  test_author_library.e  test_user_store.e
    ├── test_jobs_scoop.e  test_gc_probe.e (NFR-016)  test_ai_seam.e  test_plugin_purity.e (FR-NEW-010)
    ├── test_layering.e (no SQL in gui/ or cli/; banned accessors; static join check FR-024)
    ├── test_build_determinism.e  test_license_gate.e  test_defect_register.e (A1, B1-B4, C, D, E1-E11)
    ├── test_rix_differential.e  test_shape_differential.e  test_detector_differential.e (D-020 ports)
    ├── test_cli_commands.e  gui\test_panels_offscreen.e  gui\test_state_machines.e
    └── fixtures\  (small core.db fixture; golden outputs with SHA-256; vault snapshot for rix.db; never private data)
```

## Phase plan (one Spec Kit pass per phase, C-011)

| Phase | Scope | Depends on |
|-------|-------|-----------|
| P0 spike | D-006 spike offscreen (Gen 1:1 WLC with cantillation, Gen 1:1 LXX Swete, John 1:1 WH in `SW_LABEL`/`SW_TEXT_BOX`); file GW-01..03 defects | simple_widgets owners |
| P1 build core | L-BUILD: manifest, gate, catalog, importers for core texts, Swete repair, defect rules, normalize (LG-01), versification, FTS, checksums, credits | LG-01 |
| P2 engine | L-LIB: core, provenance, data, text, reference, versification, hub, search, census, shapes, quotation, study, author, export, checks, user, jobs, plugin, ai seam | P1 fixture DB |
| P3 ports | rix.db builder, detectors, shapes, precompute; differential tests vs golden outputs | P1, P2 |
| P4 CLI | L-CLI; simple_chat retarget (ledger R-6) | P2 |
| P5 GUI | L-GUI panels in gap order (03 A-011) | P0, GW items, FT-02 |
| P6 installer | core edition, OFL fonts, non-live identity verification | P4, P5 |
