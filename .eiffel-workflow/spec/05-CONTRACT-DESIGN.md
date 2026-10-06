# CONTRACT DESIGN: simple_bible

*Step R05, 2026-10-06. Contracts for the classes that carry the product's promises. Every public engine feature gets `require`/`ensure` (NFR-015); the contracts below are the ones the review phase must defend. MML models come from `simple_mml` (`MML_SEQUENCE`, `MML_SET`, `MML_MAP`; `|=|` model equality; `&` extended; `updated`; `removed`).*

**Fleet convention (C-019):** class invariants are O(1). Model clauses (anything that builds an MML value) appear only in postconditions as frame conditions, never in invariants (the 2026-09-11 commits "Class invariants are O(1): model clauses removed" in simple_scholar and simple_shaping).

**Void-safety note:** where a contract says a part is "present", the type is `attached`, so presence is a type guarantee; the invariant clause is kept as executable documentation of the requirement it encodes (FR-026, DR-001).

---

## MML Model Queries

| Class | Attribute | Type | Model Query | MML Type |
|-------|-----------|------|-------------|----------|
| `BIB_ENGINE_RESULT` | citations | `ARRAYED_LIST [BIB_PROVENANCE]` | `citations_model` | `MML_SEQUENCE [BIB_PROVENANCE]` |
| `BIB_LIST_RESULT [G]` | items | `ARRAYED_LIST [G]` | `items_model` | `MML_SEQUENCE [G]` |
| `BIB_BUCKETED_RESULT [G]` | fits, partial, fails, no_data | `ARRAYED_LIST [G]` x4 | `bucket_model (v)` | `MML_SEQUENCE [G]` |
| `BIB_SOURCE_SET` | attached databases | `HASH_TABLE [STRING_32, STRING_8]` (alias to path) | `attached_model` | `MML_MAP [STRING_8, STRING_32]` |
| `BIB_BOOK_CATALOG` | aliases | `HASH_TABLE [INTEGER, STRING_32]` | `aliases_model` | `MML_MAP [STRING_32, INTEGER]` |
| `BIB_VERSIFICATION_MAP` | rules | `ARRAYED_LIST [BIB_MAPPING_RULE]` | `rules_model` | `MML_SET [BIB_MAPPING_RULE]` |
| `BIB_PARSE_RESULT` | candidates | `ARRAYED_LIST [BIB_REF]` | `candidates_model` | `MML_SEQUENCE [BIB_REF]` |
| `BIB_QUERY` | clauses (pre-order) | `ARRAYED_LIST [BIB_QUERY_CLAUSE]` | `clauses_model` | `MML_SEQUENCE [BIB_QUERY_CLAUSE]` |
| `BIB_CENSUS_DEFINITION` | controls | `ARRAYED_LIST [BIB_KEY]` | `controls_model` | `MML_SEQUENCE [BIB_KEY]` |
| `BIB_SHAPE_REGISTRY` | shapes | `HASH_TABLE [BIB_SHAPE, STRING_32]` | `shapes_model` | `MML_MAP [STRING_32, BIB_SHAPE]` |
| `BIB_PLUGIN_REGISTRY` | plug-ins | `ARRAYED_LIST [BIB_PLUGIN]` | `plugins_model` | `MML_SEQUENCE [BIB_PLUGIN]` |
| `BIB_GUIDE` | sections | `ARRAYED_LIST [BIB_GUIDE_SECTION]` | `sections_model` | `MML_SEQUENCE [BIB_GUIDE_SECTION]` |
| `BIB_JOB_MAILBOX` | pages | `ARRAYED_LIST [BIB_JOB_PAGE]` | `pages_model` | `MML_SEQUENCE [BIB_JOB_PAGE]` |
| `BIB_COMMAND_SET` | commands | `HASH_TABLE [BIB_COMMAND, STRING_8]` | `commands_model` | `MML_MAP [STRING_8, BIB_COMMAND]` |
| `BIB_BUILD_MANIFEST` | sources | `HASH_TABLE [BIB_PINNED_SOURCE, STRING_8]` | `sources_model` | `MML_MAP [STRING_8, BIB_PINNED_SOURCE]` |
| `BIB_DISTRIBUTION_BUILDER` | steps | `ARRAYED_LIST [BIB_BUILD_STEP]` | `steps_model` | `MML_SEQUENCE [BIB_BUILD_STEP]` |
| `BIB_LINK_HUB` (GUI) | references per set | `HASH_TABLE [BIB_ACTIVE_REFERENCE, CHARACTER_8]` | `references_model` | `MML_MAP [CHARACTER_8, BIB_ACTIVE_REFERENCE]` |
| `BIB_LINK_HUB` (GUI) | subscriptions | `ARRAYED_LIST [BIB_PANEL]` | `subscribers_model` | `MML_SEQUENCE [BIB_PANEL]` |
| `BIB_USER_STORE` | (database-backed) | SQLite tables | counts per kind and hub id (`item_count (kind, hub_id)`) | integer frame conditions (a model of a database is not materialized) |

## Class Contracts

### SIMPLE_BIBLE (facade)

**Creation Contract:**
```eiffel
make (a_config: BIB_CONFIG)
    require
        config_valid: a_config.is_valid
    ensure
        config_set: config = a_config
        not_open: not is_open
        no_error: last_error = Void
```

**Command Contracts:**
```eiffel
open
    require
        not_open: not is_open
    ensure
        open_or_error: is_open xor (last_error /= Void)
        core_checked: is_open implies core_schema_valid
        optional_sources_reflect_files: is_open implies (has_ai_data = config.ai_data_present and has_author_library = config.rix_present)

close
    require
        open: is_open
    ensure
        closed: not is_open
```

**Query Contracts (pattern for every engine accessor):**
```eiffel
hub: BIB_VERSE_HUB
    require
        open: is_open
    ensure
        same_engine: Result = hub           -- once per instance (uniform access)

author_library: BIB_AUTHOR_LIBRARY
    require
        open: is_open
        available: has_author_library

verse (a_text: READABLE_STRING_GENERAL): BIB_VERSE_RESULT
    require
        open: is_open
        text_not_empty: not a_text.is_empty
    ensure
        parsed_outcome_carried: Result.parse_outcome /= Void
        ambiguous_never_guessed: Result.parse_outcome.is_ambiguous implies Result.version_count = 0
        method_recorded: Result.method.engine_feature.same_string ("verse")

rerun (a_method: BIB_METHOD): BIB_ENGINE_RESULT
    require
        open: is_open
        rerunnable: a_method.is_rerunnable
    ensure
        same_edition_same_counts: a_method.database_edition.same_string (database_edition) implies Result.method.counts_equal (a_method)
```

**Invariant:**
```eiffel
invariant
    error_only_when_closed: last_error /= Void implies not is_open
```

### BIB_CONFIG (builder)

```eiffel
set_core_path (a_path: READABLE_STRING_GENERAL): like Current
    require
        path_not_empty: not a_path.is_empty
    ensure
        set: core_path.same_string_general (a_path)
        others_unchanged: ai_data_path ~ old ai_data_path and rix_path ~ old rix_path and user_path ~ old user_path
        result_is_current: Result = Current

set_plugin_registry (a_registry: BIB_PLUGIN_REGISTRY): like Current
    ensure
        set: plugin_registry = a_registry
        result_is_current: Result = Current

is_valid: BOOLEAN
    ensure
        definition: Result = not core_path.is_empty
```

### BIB_SOURCE_SET (one connection per processor)

```eiffel
attach (a_alias: STRING_8; a_path: READABLE_STRING_GENERAL)
    require
        open: is_open
        alias_valid: is_valid_alias (a_alias)
        not_attached: not attached_model.domain [a_alias]
        under_limit: attached_count < Max_attached
    ensure
        attached_now: attached_model |=| old attached_model.updated (a_alias, a_path.to_string_32) or last_error /= Void
        count_grown: last_error = Void implies attached_count = old attached_count + 1

detach (a_alias: STRING_8)
    require
        attached: attached_model.domain [a_alias]
    ensure
        removed: attached_model |=| old attached_model.removed (a_alias)

invariant
    within_limit: attached_count <= Max_attached          -- Max_attached = 10 (SQLite; DR-020)
    count_non_negative: attached_count >= 0
```

### BIB_DATA_SOURCE (deferred)

```eiffel
open_on (a_set: BIB_SOURCE_SET)
    require
        set_open: a_set.is_open
        file_present: is_available
    ensure
        schema_checked: is_open implies schema_version = expected_schema_version
        tables_present: is_open implies has_required_tables
        version_recorded: is_open implies not sqlite_version.is_empty

is_read_only: BOOLEAN
    -- True for every source except BIB_USER_STORE.

invariant
    open_implies_schema: is_open implies schema_version = expected_schema_version
```

### BIB_NORMALIZER (deferred) and descendants

```eiffel
normalized (a_text: READABLE_STRING_GENERAL): STRING_32
    ensure
        idempotent: normalized (Result).same_string (Result)
        no_combining_marks: not has_combining_mark (Result)
        not_longer: Result.count <= a_text.count
        empty_preserved: a_text.is_empty implies Result.is_empty

-- BIB_HEBREW_NORMALIZER adds:
    ensure then
        consonants_only: across Result as c all is_hebrew_base_letter (c) or not is_hebrew_letter (c) end
        finals_folded: not Result.has ('ך') and not Result.has ('ם') and not Result.has ('ן') and not Result.has ('ף') and not Result.has ('ץ')

-- BIB_GREEK_NORMALIZER adds (depends on LG-01 NFD in simple_encoding):
    ensure then
        lowercase: Result.same_string (Result.as_lower)
        final_sigma_folded: not Result.has ('ς')
```

### BIB_REFERENCE_PARSER / BIB_PARSE_RESULT

```eiffel
parse (a_text: READABLE_STRING_GENERAL; a_default_system: BIB_VERSIFICATION_SYSTEM): BIB_PARSE_RESULT
    require
        text_not_empty: not a_text.is_empty
    ensure
        system_named: Result.is_valid implies Result.system /= Void
        never_guesses: Result.is_ambiguous implies Result.candidates_model.count >= 2
        error_located: Result.is_invalid implies (Result.error_position >= 1 and Result.error_position <= a_text.count + 1)

-- BIB_PARSE_RESULT
invariant
    exactly_one_state: (is_valid.to_integer + is_ambiguous.to_integer + is_invalid.to_integer) = 1
    valid_has_reference: is_valid implies reference /= Void
```

### BIB_VERSIFICATION_MAP / BIB_MAPPED_REF / BIB_PAIRING

```eiffel
mapped (a_ref: BIB_REF): detachable BIB_MAPPED_REF
    require
        book_known: books.has_book (a_ref.book_id)
    ensure
        identity_kept: attached Result implies Result.origin ~ a_ref
        rules_named: attached Result implies Result.rules_applied_count >= 0

pair (a_mapped: BIB_MAPPED_REF; a_target: BIB_VERSIFICATION_SYSTEM): BIB_PAIRING
    ensure
        same_hub: Result.hub_id = a_mapped.hub_id
        rules_reported: Result.target_count > 0 implies Result.note_text /= Void
        identity_when_same_system: a_target ~ a_mapped.origin.system implies (Result.target_count = 1 and Result.target (1) ~ a_mapped.origin)
        method_names_rules: Result.method.rules_count = Result.rules_count

-- BIB_MAPPED_REF
create {BIB_VERSIFICATION_MAP}
    make
invariant
    hub_id_positive: hub_id > 0
```
The selective creation clause is the contract that makes unmapped pairing impossible to write (I-003, DR-003).

### BIB_VERSION_INFO

```eiffel
invariant
    code_not_empty: not code.is_empty
    septuagint_labeled_with_edition: is_septuagint implies (not edition.is_empty and display_label.has_substring (edition))
    never_bare_lxx: not display_label.same_string ("LXX")
    has_license: license /= Void
    rtl_for_hebrew: language.same_string ("hbo") implies is_right_to_left
```

### BIB_VERSE_TEXT

```eiffel
invariant
    text_xor_omission: (display_text /= Void) xor (omission /= Void)
    quarantine_is_omission: is_quarantined implies (attached omission as o and then o.is_quarantined)
    provenance_present: provenance /= Void
    swete_quality_known: version.is_swete implies repair_state.is_valid
```
`display_text` has no setter (DR-009).

### BIB_FACT [G], BIB_PROVENANCE, BIB_LICENSE

```eiffel
-- BIB_FACT [G]
make (a_value: G; a_provenance: BIB_PROVENANCE)
    ensure
        value_set: value ~ a_value
        provenance_set: provenance = a_provenance
invariant
    has_provenance: provenance /= Void

-- BIB_PROVENANCE
invariant
    source_named: not source_key.is_empty
    licensed: license /= Void
    ai_made_has_method: is_ai_made implies (not method_label.is_empty and not model_id.is_empty)
    graded_when_required: requires_grade implies grade /= Void

-- BIB_LICENSE
may_ship_in_free_tool: BOOLEAN
    ensure
        unknown_never_ships: is_unknown implies not Result
        nc_allowed_free: (is_non_commercial and not is_unknown and not is_restricted) implies Result   -- D-002
invariant
    id_not_empty: not identifier.is_empty
```

### BIB_METHOD

```eiffel
invariant
    query_recorded: not canonical_query.is_empty
    engine_named: not engine_feature.is_empty
    edition_recorded: not database_edition.is_empty
    sqlite_recorded: not sqlite_version.is_empty                 -- FR-NEW-008

counts_equal (other: BIB_METHOD): BOOLEAN
    ensure
        symmetric: Result = other.counts_equal (Current)
```

### BIB_ENGINE_RESULT (deferred)

```eiffel
citation (i: INTEGER): BIB_PROVENANCE
    require
        in_range: i >= 1 and i <= citation_count
    ensure
        model_agrees: Result = citations_model [i]

invariant
    success_xor_error: is_success xor (error /= Void)
    success_is_cited: is_success implies citation_count > 0      -- an answer always names the sources it consulted
    method_present: method /= Void
```

### BIB_BUCKETED_RESULT [G -> BIB_FINDING]

```eiffel
make (a_definition_id: INTEGER_64)
    require
        definition_bound: a_definition_id > 0
    ensure
        all_empty: total = 0
        open_for_filling: not is_sealed

extend (a_finding: G)
    require
        not_sealed: not is_sealed
        verdict_matches: a_finding.verdict /= Void
    ensure
        grown: count (a_finding.verdict) = old count (a_finding.verdict) + 1
        appended: bucket_model (a_finding.verdict) |=| old bucket_model (a_finding.verdict) & a_finding
        others_unchanged: across all_verdicts as v all v /~ a_finding.verdict implies bucket_model (v) |=| old bucket_model (v) end
        total_grown: total = old total + 1

seal
    require
        not_sealed: not is_sealed
    ensure
        sealed: is_sealed
        unchanged: total = old total

invariant
    four_buckets_present: fits /= Void and partial /= Void and fails /= Void and no_data /= Void
    total_consistent: total = fits.count + partial.count + fails.count + no_data.count
    bound_to_definition: definition_id > 0
```
`extend` and `seal` are exported only to the engines that build results (`{BIB_CENSUS_ENGINE, BIB_SHAPE_ENGINE, BIB_SHAPE_PRECOMPUTE}`); clients see a sealed, read-only object.

### BIB_CENSUS_DEFINITION (DR-006, FR-025)

```eiffel
set_question (a_text: READABLE_STRING_GENERAL)
    require
        not_frozen: not is_frozen
        text_not_empty: not a_text.is_empty
    ensure
        set: question.same_string_general (a_text)
        criteria_unchanged: criteria ~ old criteria
        controls_unchanged: controls_model |=| old controls_model

add_control (a_key: BIB_KEY)
    require
        not_frozen: not is_frozen
        not_target: not criteria.mentions_key (a_key)
    ensure
        appended: controls_model |=| old controls_model & a_key

freeze (a_run_id: INTEGER_64)
    require
        complete: is_complete
        not_frozen: not is_frozen
    ensure
        frozen: is_frozen
        first_run_recorded: first_run_id = a_run_id
        content_unchanged: question ~ old question and controls_model |=| old controls_model

new_version: like Current
    require
        frozen: is_frozen
    ensure
        next_version: Result.version = version + 1
        same_lineage: Result.lineage_id = lineage_id
        editable: not Result.is_frozen
        content_copied: Result.question ~ question and Result.controls_model |=| controls_model

is_complete: BOOLEAN
    ensure
        definition: Result = (not question.is_empty and not corpus_label.is_empty and criteria.clause_count > 0
                               and controls_count >= 1 and not holds_if.is_empty and not fails_if.is_empty)

invariant
    frozen_has_run: is_frozen implies first_run_id > 0
    version_positive: version >= 1
    seed_recorded: control_seed /= 0
```

### BIB_CONTROL_SET (FR-112, A-016)

```eiffel
make_frequency_matched (a_target: BIB_KEY; a_corpus: BIB_SEARCH_SCOPE; a_band_percent: INTEGER; a_size: INTEGER; a_seed: INTEGER_64; a_frequencies: BIB_COUNT_TABLE)
    require
        band_sane: a_band_percent > 0 and a_band_percent <= 50
        size_positive: a_size >= 1
        seed_given: a_seed /= 0
    ensure
        deterministic: same_selection_as (create {BIB_CONTROL_SET}.make_frequency_matched (a_target, a_corpus, a_band_percent, a_size, a_seed, a_frequencies))
        target_excluded: not keys_model.has (a_target)
        within_band: across keys_model as k all a_frequencies.within_band (k, a_target, a_band_percent) end
        at_most_size: count <= a_size
```
(The `deterministic` clause is a test oracle; implementations may keep it as a debug-only assertion if its cost is too high, which /eiffel.review must decide.)

### BIB_CENSUS_ENGINE

```eiffel
run (a_definition: BIB_CENSUS_DEFINITION; a_token: separate BIB_CANCEL_TOKEN): BIB_CENSUS_RUN
    require
        complete: a_definition.is_complete
        stored: a_definition.is_stored                    -- written down before the run
    ensure
        definition_frozen: a_definition.is_frozen
        bound: Result.definition_id = a_definition.id and Result.definition_version = a_definition.version
        four_buckets: Result.buckets.total >= 0           -- the object exists with all four
        cancelled_means_no_findings: Result.was_cancelled implies Result.buckets.total = 0
        controls_compared: not Result.was_cancelled implies Result.control_count = a_definition.controls_count
        method_recorded: Result.method.engine_feature.same_string ("census")
```

### BIB_CENSUS_RUN

```eiffel
invariant
    buckets_present: buckets /= Void
    bound: buckets.definition_id = definition_id
    cancelled_empty: was_cancelled implies buckets.total = 0
    verdict_only_when_complete: control_verdict /= Void implies not was_cancelled
```

### BIB_SHAPE / BIB_SHAPE_ENGINE (DR-005, DR-007)

```eiffel
-- BIB_SHAPE (deferred)
classify (a_candidate: BIB_SHAPE_CANDIDATE): BIB_SHAPE_FINDING
    require
        candidate_in_corpus: corpus.contains (a_candidate.reference)
    deferred
    ensure
        absent_tag_is_no_data: not a_candidate.has_required_tags (required_columns) implies Result.verdict.is_no_data
        tier_carried: Result.tier ~ tier
        grounds_given: not Result.grounds.is_empty

invariant
    defined_before_run: not definition_formal.is_empty and not definition_prose.is_empty and not could_fail_if.is_empty
    seeded: not seeded_by.is_empty
    slug_valid: not slug.is_empty

-- BIB_SHAPE_ENGINE
evidence (a_shape: BIB_SHAPE): BIB_SHAPE_RUN
    require
        not_judgment: not a_shape.tier.is_judgment                 -- T3 never scores a claim
        registered: shapes.has_slug (a_shape.slug)
    ensure
        all_buckets: Result.buckets.is_sealed
        tier_carried: Result.tier ~ a_shape.tier
```
(`BIB_SHAPE_CANDIDATE` is a small value class internal to the shape cluster: reference plus the tag-level evidence the shape needs; it is listed in the shape cluster of 04.)

### BIB_QUOTATION_COMPARER / BIB_QUOTATION_RESULT (FR-030, A-001)

```eiffel
compare (a_nt: BIB_MAPPED_REF): BIB_QUOTATION_RESULT
    ensure
        not_indexed_no_data: not index.has_quotation (a_nt) implies Result.agreement.is_no_data
        no_alignment_no_data: (index.has_quotation (a_nt) and not index.is_aligned (a_nt)) implies Result.agreement.is_no_data
        edition_named: not Result.edition_note.is_empty
        ocr_flagged: Result.lxx_from_uncollated_ocr implies Result.edition_note.has_substring ("OCR")

-- BIB_QUOTATION_RESULT
invariant
    edition_note_present: not edition_note.is_empty
    verdict_matches_marks: not agreement.is_no_data implies alignment /= Void
```

### BIB_RELATED_PASSAGE (DR-012)

```eiffel
invariant
    has_reason: reason_count >= 1
    ai_made_has_label: is_ai_made implies (not ai_label.is_empty and provenance.is_ai_made)
    ai_flag_matches_provenance: is_ai_made = provenance.is_ai_made
```

### BIB_AUTHOR_LIBRARY / BIB_AUTHOR_DOC (DR-013, D-019)

```eiffel
-- BIB_AUTHOR_LIBRARY
search (a_query: BIB_QUERY; a_include_withdrawn: BOOLEAN): BIB_LIST_RESULT [BIB_AUTHOR_DOC]
    ensure
        withdrawn_only_if_requested: not a_include_withdrawn implies across Result.items_model as d all not d.status.is_withdrawn end
        statuses_attached: across Result.items_model as d all d.status /= Void end
        current_first: Result.is_ordered_current_before_withdrawn

citing (a_mapped: BIB_MAPPED_REF): BIB_LIST_RESULT [BIB_AUTHOR_DOC]
    ensure
        cites_verse: across Result.items_model as d all d.cites (a_mapped.hub_id) end

-- BIB_AUTHOR_DOC
invariant
    status_valid: status /= Void and then status.is_valid
    voice_author: voice.is_author
    title_present: not title.is_empty
```

### BIB_AI_ADAPTER, BIB_AI_POST_CHECK, BIB_AI_TEXT (I-001, DR-012, FR-053)

```eiffel
-- BIB_AI_ADAPTER (deferred)
explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
    require
        engine_answer: a_result.is_success
        cited: a_result.citation_count > 0
    deferred
    ensure
        rests_on_input: attached Result implies Result.basis = a_result
        labeled: attached Result implies Result.is_labeled

-- BIB_NULL_AI_ADAPTER
explain (a_result: BIB_ENGINE_RESULT): detachable BIB_AI_TEXT
    ensure then
        never_produces: Result = Void

-- BIB_AI_POST_CHECK (the only creator of BIB_AI_TEXT)
checked (a_wording: READABLE_STRING_GENERAL; a_basis: BIB_ENGINE_RESULT; a_model_id: READABLE_STRING_GENERAL): BIB_AI_TEXT
    require
        basis_success: a_basis.is_success
        basis_cited: a_basis.citation_count > 0
        model_named: not a_model_id.is_empty
    ensure
        withheld_if_new_facts: has_unsupported_digit (a_wording, a_basis) or has_unsupported_reference (a_wording, a_basis)
                               or has_unsupported_script (a_wording, a_basis) implies Result.is_withheld
        basis_kept: Result.basis = a_basis

-- BIB_AI_TEXT
create {BIB_AI_POST_CHECK}
    make
invariant
    label_present: is_labeled and label.same_string (Ai_label)       -- "AI wording; the facts above are from the engine"
    cites_engine: basis.is_success and basis.citation_count > 0
    model_named: not model_id.is_empty
    withheld_text_hidden: is_withheld implies displayable_text.is_empty
```

### BIB_JOB [R], BIB_CANCEL_TOKEN, BIB_JOB_MAILBOX (A-005, A-006, DR-014)

```eiffel
-- BIB_JOB [R -> BIB_ENGINE_RESULT] (deferred)
step
    require
        started: is_started
        not_finished: not is_done
    deferred
    ensure
        progressed: chunks_done = old chunks_done + 1 or is_done
        bounded: last_chunk_bounded                 -- one chunk = one book (or one guide section)

run_to_completion (a_token: separate BIB_CANCEL_TOKEN; a_mailbox: separate BIB_JOB_MAILBOX)
    require
        not_started: not is_started
    ensure
        finished: is_done
        cancel_observed: is_cancelled implies not has_result
        reported: is_done implies mailbox_closed (a_mailbox)

result_value: R
    require
        done: is_done
        not_cancelled: not is_cancelled                 -- partial results are never findings
        succeeded: has_result

invariant
    progress_bounded: chunks_done >= 0 and chunks_done <= chunk_total
    cancelled_has_no_result: is_cancelled implies not has_result

-- BIB_CANCEL_TOKEN
request_cancel
    ensure
        requested: is_cancel_requested
invariant
    -- monotone: once requested it stays requested (no reset feature exists)

-- BIB_JOB_MAILBOX
post_page (a_page: BIB_JOB_PAGE)
    require
        open: not is_closed
        next_in_order: a_page.number = page_count + 1
    ensure
        appended: pages_model |=| old pages_model & a_page
        progress_unchanged: progress = old progress

set_progress (a_fraction: REAL_64)
    require
        in_range: a_fraction >= 0.0 and a_fraction <= 1.0
        monotone: a_fraction >= progress
    ensure
        set: progress = a_fraction

close_done / close_cancelled / close_failed (a_error: BIB_ERROR)
    ensure
        closed: is_closed
        outcome_exclusive: (is_done.to_integer + is_cancelled.to_integer + is_failed.to_integer) = 1
        cancelled_discards: is_cancelled implies page_count = 0       -- pages dropped on cancel (ER-10)

invariant
    pages_numbered: page_count >= 0
    progress_bounded: progress >= 0.0 and progress <= 1.0
```
`BIB_JOB_PAGE` holds only `STRING_32`, `INTEGER_64` and arrays of them (values copied into the mailbox's processor), so the GUI never holds a reference into a worker's objects.

### BIB_SEARCH_ENGINE (A-002)

```eiffel
start_search (a_query: BIB_QUERY): BIB_SEARCH_JOB
    require
        query_valid: a_query.is_valid
        scope_bounded_for_regex: a_query.has_regex implies a_query.scope.version_count = 1 or a_query.scope.is_user_confirmed_wide
        keys_resolve: across a_query.key_clauses as c all keys_resolve (c) end
    ensure
        not_started: not Result.is_started
        chunked_by_book: Result.chunk_total = a_query.scope.book_count
```

### BIB_USER_STORE (database-backed frames)

```eiffel
add_note (a_note: BIB_NOTE)
    require
        open: is_open
        not_stored: a_note.id = 0
        keyed: a_note.hub_id > 0 or a_note.is_topical
    ensure
        stored: a_note.id > 0 or last_error /= Void
        count_grown: last_error = Void implies item_count (Kind_note, a_note.hub_id) = old item_count (Kind_note, a_note.hub_id) + 1
        others_unchanged: last_error = Void implies item_count (Kind_highlight, a_note.hub_id) = old item_count (Kind_highlight, a_note.hub_id)

store_census_run (a_run: BIB_CENSUS_RUN)
    require
        complete_run: not a_run.was_cancelled
    ensure
        retrievable: last_error = Void implies census_run (a_run.id) ~ a_run

invariant
    only_writer: is_read_only = False
```

### BIB_LICENSE_GATE and BIB_DISTRIBUTION_BUILDER (DR-002, DR-016, FR-001..004)

```eiffel
-- BIB_LICENSE_GATE
ship_allowed (a_source: BIB_PINNED_SOURCE): BOOLEAN
    ensure
        unknown_refused: a_source.license.is_unknown implies not Result
        restricted_refused: a_source.license.is_restricted implies not Result
        flag_respected: not a_source.ship implies not Result

check_manifest (a_manifest: BIB_BUILD_MANIFEST)
    ensure
        refusal_named: has_refusal = across a_manifest.sources_model.domain as k some
                            a_manifest.sources_model [k].ship and not ship_allowed (a_manifest.sources_model [k]) end
        refusal_message_names_source: has_refusal implies across refused_keys as k all refusal_message.has_substring (k) end

-- BIB_DISTRIBUTION_BUILDER
build (a_context: BIB_BUILD_CONTEXT)
    require
        manifest_hashes_verified: a_context.manifest.all_hashes_verified
        gate_passed: not a_context.license_gate.has_refusal
        steps_registered: steps_model.count > 0
    ensure
        all_rows_have_provenance: succeeded implies rows_without_provenance = 0
        no_unknown_license_shipped: succeeded implies shipped_unknown_license_count = 0
        checksums_recorded: succeeded implies checksum_count = table_count
        credits_generated: succeeded implies credits_match_provenance
        steps_unchanged: steps_model |=| old steps_model

-- BIB_BUILD_CONTEXT
invariant
    date_fixed: not build_date.is_empty          -- passed in; builders never read the clock (DR-016)
    rules_version_known: rules_version >= 1
```

### BIB_TABLE_CHECKSUM, BIB_DB_COMPARATOR (FR-104, A-015)

```eiffel
-- BIB_TABLE_CHECKSUM
checksum (a_db: SIMPLE_SQL_DATABASE; a_table: STRING_8; a_key_columns: ARRAY [STRING_8]): STRING_8
    require
        table_exists: a_db.has_table (a_table)
        ordered_by_key: a_key_columns.count >= 1
    ensure
        sha256_hex: Result.count = 64
        deterministic: Result.same_string (checksum (a_db, a_table, a_key_columns))

-- BIB_DB_COMPARATOR
compare (a_reference, a_candidate: READABLE_STRING_GENERAL; a_spec: BIB_COMPARE_SPEC): BIB_COMPARE_REPORT
    require
        files_exist: file_exists (a_reference) and file_exists (a_candidate)
    ensure
        read_only: databases_unchanged (a_reference, a_candidate)
        strict_meaning: Result.is_identical = (Result.mismatch_count = 0)
```
(`BIB_COMPARE_SPEC` and `BIB_COMPARE_REPORT` are the comparator's parameter and report classes, listed in 04 §1.3.)

### BIB_RIX_RULES (port of build_rix_db.py rules v2.1)

```eiffel
derived_status (a_doc: BIB_VAULT_DOCUMENT): BIB_DOC_STATUS
    ensure
        explicit_marker_wins: a_doc.has_explicit_withdrawn_marker implies Result.is_withdrawn
        verdict_by_name: (not a_doc.has_explicit_marker and a_doc.file_name_has ("verdict")) implies Result.is_verdict
        framework_by_path: (Result.is_framework) implies a_doc.relpath.starts_with ("Rix/Frameworks/")
        valid: Result.is_valid

verse_refs (a_content: READABLE_STRING_32): BIB_LIST_RESULT [BIB_REF]
    ensure
        deduplicated: Result.items_model.count = distinct_count (Result.items_model)
        first_verse_only_for_ranges: across Result.items_model as r all r.range_end = Void end
        period_form_checked: across Result.items_model as r all r.from_period_form implies (r.chapter >= 1 and r.chapter <= books.chapter_count (r.book_id) and r.verse >= 1) end
```

### BIB_EXPORTER / BIB_ATTRIBUTION (FR-119)

```eiffel
export (a_result: BIB_ENGINE_RESULT; a_format: INTEGER): STRING_32
    require
        success: a_result.is_success
        format_valid: is_valid_format (a_format)
    ensure
        attributed: Result.has_substring (attribution.lines_for (a_result.citations_model))
        share_alike_notice: across a_result.citations_model as p some p.license.is_share_alike end
                            implies Result.has_substring (attribution.share_alike_notice)
        ai_labeled: across a_result.citations_model as p some p.is_ai_made end implies Result.has_substring (Ai_made_label)
```

### BIB_GUIDE (FR-110)

```eiffel
invariant
    no_empty_section: across sections as s all s.result.is_success and s.result.citation_count > 0 end   -- O(n) over a handful of sections: allowed as a documented exception, or moved to `add_section`'s precondition at review
    kind_valid: is_valid_kind (kind)

add_section (a_section: BIB_GUIDE_SECTION)
    require
        has_data: a_section.result.is_success and a_section.result.citation_count > 0
        unique: not has_section (a_section.id)
    ensure
        appended: sections_model |=| old sections_model & a_section
```
Review note: to honor C-019, the `no_empty_section` clause should live only as `add_section`'s precondition (the only way in), which makes the invariant redundant. Recorded for /eiffel.review.

### BIB_COMMAND_SET (FR-121, ledger R-5)

```eiffel
execute (a_line: READABLE_STRING_GENERAL): BIB_COMMAND_OUTCOME
    ensure
        unknown_refused: not commands_model.domain [command_name (a_line)] implies Result.is_refused
        read_only: user_store_unchanged

invariant
    closed: command_count = Allowed_count           -- the allowlist is fixed at compile time
```

### BIB_PLUGIN_REGISTRY (A-012, FR-125)

```eiffel
register (a_plugin: BIB_PLUGIN)
    require
        not_registered: not has_plugin (a_plugin.name)
        before_open: not is_sealed
    ensure
        appended: plugins_model |=| old plugins_model & a_plugin

seal
    ensure
        sealed: is_sealed

invariant
    -- public build: no registration call exists in the public root; a purity test asserts plugin_count = 0
    count_non_negative: plugin_count >= 0
```

### BIB_LENS_RESULT (DR-018)

```eiffel
invariant
    voice_attached: voice /= Void
    plugin_named: not plugin_name.is_empty
```

### BIB_LINK_HUB (GUI)

```eiffel
set_reference (a_set: CHARACTER_8; a_ref: BIB_ACTIVE_REFERENCE; a_origin: detachable BIB_PANEL)
    require
        valid_set: a_set = 'A' or a_set = 'B' or a_set = 'C'
    ensure
        stored: references_model [a_set] = a_ref
        other_sets_unchanged: references_model.removed (a_set) |=| old references_model.removed (a_set)
        subscribers_unchanged: subscribers_model |=| old subscribers_model
        set_members_notified: across subscribers_model as p all p.link_set = a_set implies (p.is_refreshing or p.is_stale or p = a_origin) end

invariant
    one_reference_per_set: reference_count <= 3
```

### BIB_RESULT_ADAPTER [R] (GUI, FR-124)

```eiffel
adapt (a_result: R)
    require
        engine_answer: a_result /= Void
        fact_has_provenance: a_result.is_success implies a_result.citation_count > 0
    deferred
    ensure
        chips_built: a_result.is_success implies chip_count >= 1
        ai_label_present: across a_result.citations_model as p some p.is_ai_made end implies has_ai_made_chip
        status_label_present: a_result.has_author_documents implies has_status_chips
        no_bare_lxx: not shows_label ("LXX")
```

### BIB_ASTRO_YEAR (v2, DR-022)

```eiffel
display (a_era_style: INTEGER): STRING_32
    ensure
        no_year_zero: not Result.same_string ("0 BC") and not Result.same_string ("0 AD") and not Result.same_string ("0")
        bc_for_non_positive: value <= 0 implies Result.has_substring (bc_label (a_era_style))
        one_bc_is_zero: value = 0 implies Result.starts_with ("1 ")
```

## Contract Completeness Checklist

| Contract area | What changed? | How (old)? | What did NOT change (frame)? |
|---------------|---------------|-----------|------------------------------|
| `BIB_CONFIG.set_*` | the one path | `old` values of the others | other paths (`others_unchanged`) |
| `BIB_SOURCE_SET.attach/detach` | `attached_model` | `old attached_model.updated/removed` | (whole model equality is the frame) |
| `BIB_BUCKETED_RESULT.extend` | one bucket | `old bucket_model (v) & f` | the three other buckets |
| `BIB_CENSUS_DEFINITION.set_*` / `add_control` / `freeze` | one field / controls / frozen flag | `old controls_model & k` | criteria, controls, question as applicable |
| `BIB_CENSUS_DEFINITION.new_version` | new object | `version + 1` | content copied |
| `BIB_JOB.step` | chunks done | `old chunks_done + 1` | bounded chunk |
| `BIB_JOB_MAILBOX.post_page` | pages | `old pages_model & page` | progress |
| `BIB_USER_STORE.add_note` | note count for the hub id | `old item_count + 1` | other kinds' counts |
| `BIB_DISTRIBUTION_BUILDER.build` | the database | per-table checksums | `steps_model` |
| `BIB_PLUGIN_REGISTRY.register` | plug-ins | `old plugins_model & p` | (model equality) |
| `BIB_LINK_HUB.set_reference` | one set's reference | model `removed (a_set)` | other sets, subscribers |
| `BIB_GUIDE.add_section` | sections | `old sections_model & s` | (model equality) |

- [x] **What changed?** Stated for every command above.
- [x] **How did it change?** `old` expressions or MML `&`/`updated`/`removed`.
- [x] **What did NOT change?** MML `|=|` frame conditions on every collection-bearing command; integer frames where the collection is a database.

## The "engine owns every fact" rule, as contracts (summary)

| # | Enforcement | Where |
|---|-------------|-------|
| 1 | A fact cannot be constructed without provenance | `BIB_FACT.make` signature; invariant `has_provenance` |
| 2 | An answer always names the sources it consulted | `BIB_ENGINE_RESULT` invariant `success_is_cited` |
| 3 | Every answer has a method that re-runs to itself | `BIB_ENGINE_RESULT` invariant `method_present`; `SIMPLE_BIBLE.rerun` postcondition |
| 4 | All four buckets always present; no single-bucket API | `BIB_BUCKETED_RESULT` invariants; `extend`/`seal` exported only to engines |
| 5 | NO_DATA never collapses into FAILS | `BIB_SHAPE.classify` postcondition `absent_tag_is_no_data` |
| 6 | T3 never evidence | `BIB_SHAPE_ENGINE.evidence` precondition `not_judgment` |
| 7 | No pairing without the map | `BIB_MAPPED_REF` creation exported only to `BIB_VERSIFICATION_MAP` |
| 8 | AI text cannot exist without an engine answer, and is always labeled | `BIB_AI_TEXT` creation exported only to `BIB_AI_POST_CHECK`; invariants `label_present`, `cites_engine`; `BIB_AI_ADAPTER.explain` takes `BIB_ENGINE_RESULT`, never a string |
| 9 | AI-made data always labeled | `BIB_RELATED_PASSAGE` and `BIB_PROVENANCE` invariants; GUI `ai_label_present`; exporter `ai_labeled` |
| 10 | Author status always present | `BIB_AUTHOR_DOC` invariant; adapter `status_label_present` |
| 11 | Never a bare "LXX" | `BIB_VERSION_INFO` invariants; adapter `no_bare_lxx` |
| 12 | Partial results never findings | `BIB_JOB.result_value` precondition; mailbox `cancelled_discards` |
| 13 | No unknown license ships; every row has provenance | `BIB_LICENSE_GATE`, `BIB_DISTRIBUTION_BUILDER.build` postconditions |
| 14 | The GUI shows only what the engine returned | `BIB_RESULT_ADAPTER.adapt` precondition `fact_has_provenance`; layer rule (no SQL in GUI) |
| 15 | Every count states its scope | `BIB_METHOD` invariant `scope_stated`; adapters render `scope_label` beside the number (13 S11) |

## Addendum: contracts from the user-voice evidence (03 A-021 to A-027, research/13)

### BIB_NOTE_STORE (deferred) and descendants (A-021, A-022)

```eiffel
add_note (a_note: BIB_NOTE)
    require
        not_stored: a_note.id = 0
        keyed: a_note.hub_id > 0 or a_note.is_topical
    deferred
    ensure
        stored: last_error = Void implies a_note.id > 0
        count_grown: last_error = Void implies note_count (a_note.hub_id) = old note_count (a_note.hub_id) + 1

update_note (a_note: BIB_NOTE)
    require
        stored: a_note.id > 0
        not_deleted: not is_deleted (a_note.id)
    deferred
    ensure
        history_grown: last_error = Void implies version_count (a_note.id) = old version_count (a_note.id) + 1
        previous_kept: last_error = Void implies version_body (a_note.id, old version_count (a_note.id)) ~ old current_body (a_note.id)

remove_note (a_id: INTEGER_64)
    require
        stored: a_id > 0
    deferred
    ensure
        soft_deleted: last_error = Void implies is_deleted (a_id)
        recoverable: last_error = Void implies version_count (a_id) = old version_count (a_id)

restore_note (a_id: INTEGER_64)
    require
        deleted: is_deleted (a_id)
    deferred
    ensure
        restored: last_error = Void implies not is_deleted (a_id)

-- BIB_MARKDOWN_NOTE_STORE adds:
invariant
    folder_chosen: not folder.is_empty
    -- index rows in user.db mirror the files; verse links resolved by BIB_REFERENCE_DETECTOR
```

### BIB_USER_STORE additions (A-022, A-023)

```eiffel
migrate (a_from_version, a_to_version: INTEGER)
    require
        forward: a_to_version > a_from_version
    ensure
        settings_preserved: last_error = Void implies settings_model |=| old settings_model
        layouts_preserved: last_error = Void implies layout_count = old layout_count
        notes_preserved: last_error = Void implies total_note_versions = old total_note_versions
        schema_upgraded: last_error = Void implies schema_version = a_to_version

remove_highlight (a_id: INTEGER_64)
    ensure
        soft_deleted: last_error = Void implies is_deleted (a_id)        -- every user item kind: soft delete

-- BIB_USER_BACKUP
backup_on_exit (a_store: BIB_USER_STORE)
    ensure
        rotated: backup_count <= Max_backups
        newest_first: last_error = Void implies newest_backup_time >= old newest_backup_time
restore (a_backup_index: INTEGER)
    require
        exists: a_backup_index >= 1 and a_backup_index <= backup_count
    ensure
        current_kept_as_backup: last_error = Void implies backup_count >= old backup_count
```
(`settings_model: MML_MAP [STRING_8, STRING_32]` is the one materialized model in the user store: settings are few.)

### Normalizers and keys (A-024)

```eiffel
-- BIB_NORMALIZER, every descendant
    ensure then
        punctuation_folded: not has_punctuation_or_quote_variant (Result)        -- straight/curly quotes, dashes, NBSP fold to the same form

-- BIB_STRONGS_KEY
make_from_text (a_text: READABLE_STRING_GENERAL)
    require
        well_formed: is_strongs_text (a_text)                                  -- "H1", "H0001", "H00001", "G3056", "H6743a"
    ensure
        padding_insensitive: number = numeric_value_without_padding (a_text)
        sense_kept: sense_suffix.same_string (suffix_of (a_text))
```
Golden test (FR-NEW-018): for every shipped version, phrases sampled from its display text are searched through the normalizer and must return their own verse.

### Count scope and text seal (A-025)

```eiffel
-- BIB_METHOD
scope_label: STRING_32                 -- "NT, SBLGNT, word tokens"
invariant
    scope_stated: not scope_label.is_empty

-- BIB_VERSION_INFO
verse_count: INTEGER
seal: STRING_8                         -- the build's per-text checksum (BIB_TABLE_CHECKSUM)
invariant
    sealed: seal.count = 64
    counted: verse_count > 0
```

### BIB_GUIDE_ASSEMBLER: text-first mode (13 S9)

```eiffel
passage_guide (a_range: BIB_REF_RANGE; a_text_first: BOOLEAN): BIB_GUIDE_JOB
    ensure
        text_first_excludes_commentary: a_text_first implies Result.excluded_section_kinds.has (Section_library)
            and Result.excluded_section_kinds.has (Section_author) and Result.excluded_section_kinds.has (Section_lens)
```

### BIB_PANEL and BIB_LINK_HUB (A-026, A-027)

```eiffel
-- BIB_PANEL
link_role: INTEGER                     -- Role_lead, Role_follow, Role_follow_only, Role_independent
accessible_name: STRING_32 deferred end
spoken_text: STRING_32 deferred end    -- the panel's content in reading order, for the GW-14 bridge
invariant
    role_valid: link_role >= Role_lead and link_role <= Role_independent
    named: not accessible_name.is_empty

scrolled_to (a_ref: BIB_ACTIVE_REFERENCE)
    ensure
        follow_only_never_leads: link_role = Role_follow_only implies hub.references_model |=| old hub.references_model
        independent_never_leads: link_role = Role_independent implies hub.references_model |=| old hub.references_model
```
