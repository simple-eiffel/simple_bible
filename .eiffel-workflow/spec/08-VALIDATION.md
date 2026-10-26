# DESIGN VALIDATION: simple_bible

*Step R08, 2026-10-06. Validation of 01-07 against OOSC2, Eiffel practice, the fleet laws, and every requirement and risk. ✓ = satisfied in the design; ◐ = satisfied with a recorded condition; ✗ = not satisfied.*

*Fold 2026-10-26 (debates 01-05, D-006, D-021): rows changed by the five gated verdicts are marked; a new section, "Acceptance checks named by the verdicts", lists every check they name. Superseded text is quoted in the Fold log of `00-FOLD-2026-10-26.md`.*

---

## OOSC2 Compliance

| Principle | Status | Evidence |
|-----------|--------|----------|
| Single Responsibility | ✓ | 04 §1 gives one responsibility per class; engines (one question each) are separate from results (immutable data) and from sources (connections). The facade only opens and delegates. |
| Open/Closed | ✓ | New shapes, checks, normalizers, user-item kinds, build steps, importers, commands, panels and plug-ins are added as descendants of deferred bases (`BIB_SHAPE`, `BIB_CHECK`, `BIB_NORMALIZER`, `BIB_USER_ITEM`, `BIB_BUILD_STEP`, `BIB_COMMAND`, `BIB_PANEL`) without changing engine code (fold 2026-10-26, debate 03: `BIB_PLUGIN` and `BIB_LENS` are removed from the list). Library content packs and private packs plug in as data behind `BIB_LIBRARY` and the generic pack reader (03 A-010; debate 03). |
| Liskov Substitution | ✓ | 04 §5 justification table; descendants only strengthen invariants or weaken preconditions; `BIB_NULL_AI_ADAPTER` returns Void within the parent's `detachable` result; `BIB_USER_STORE.is_read_only = False` is a query clients never assume True for every source. |
| Interface Segregation | ✓ | The GUI sees `BIB_ENGINE_CLIENT` (lookups, jobs, user data) only; the CLI sees the facade and the command set; private packs are read by the generic pack reader (`BIB_PRIVATE_SOURCE`), with no plug-in or lens seam (fold 2026-10-26, debate 03; was "plug-ins see `BIB_PLUGIN`/`BIB_LENS`/`BIB_PRIVATE_SOURCE`"); the AI seam sees `BIB_ENGINE_RESULT` only. |
| Dependency Inversion | ✓ | Faces depend on engine abstractions and result types, never on simple_sql (layer rule tested by `test_layering`); private material is data in public-schema packs and the public library never depends on private code (fold 2026-10-26, debate 03; was "private code depends on deferred seams in the public library, never the reverse"); engines depend on `BIB_DATA_SOURCE` abstractions. |

## Eiffel Excellence

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Command-Query Separation | ✓ | 06 CQS table; one documented exception (`BIB_COMMAND_SET.execute` returns the outcome for the exit code); factories (`start_*`, `new_version`, `checked`) do not change Current. |
| Uniform Access | ✓ | Engine accessors are `once ("OBJECT")` queries indistinguishable from attributes; counts and statuses are queries (`total`, `citation_count`, `is_complete`). |
| Design by Contract | ✓ | 05 covers every promise-carrying class; 07 repeats them in class texts; the "engine owns every fact" rule maps to 14 concrete contracts (05 last table). NFR-015 (100% of engine public features) is a Phase 1 obligation. |
| Genericity | ✓ | `BIB_FACT [G]`, `BIB_LIST_RESULT [G]`, `BIB_BUCKETED_RESULT [G -> BIB_FINDING]`, `BIB_JOB [R -> BIB_ENGINE_RESULT]`, `BIB_RESULT_ADAPTER [R -> BIB_ENGINE_RESULT]`. |
| Inheritance | ✓ | IS-A only (04 §5); no implementation-only inheritance; enumerations share `BIB_ENUMERATION`. |
| Information Hiding | ✓ | Bucket lists, citation lists, rule tables and connections are `{NONE}`; `extend`/`seal` exported only to the engines that build results; `BIB_MAPPED_REF` and `BIB_AI_TEXT` creation exported only to their sole creators. |

## Practical Quality

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Void-safe | ✓ | Attached results; optional parts `detachable` with explicit `has_*`/`is_*` queries (`omission`, `alignment`, `error`, `grade`). |
| SCOOP-compatible | ◐ | Processor map 04 §7; one connection per processor; mailbox and token on their own processors (03 A-006); chunked jobs (A-005). **Condition:** FT-02 (six `blocking` sqlite externals; no hook guard, e80c57c lifted it: fold 2026-10-26, settlement S3) must land before the GUI phase for NFR-016 to hold under garbage collection; the GC-probe test proves it; every dependent is rebuilt `-clean` after FT-02 and its generated C checked for `EIF_ENTER_C` around `sqlite3_step`. FT-02 landed with FT-01 (eiffel_sqlite_2025 1.1.0, SQLite 3.53.4) (fold 2026-10-26, debate 04). |
| simple_* first | ✓ | 07 dependency table, every ECF confirmed present today; no ISE/Gobo direct dependency; gaps filed in owning libraries (LG-01, LG-03, LG-04/05, FT-01/02, GW-*). |
| MML postconditions | ✓ | 05 MML table (19 collection-bearing classes); frame conditions with `|=|` on every collection command; invariants O(1) per fleet convention (two clauses flagged for review: `BIB_GUIDE.no_empty_section`, `BIB_CONTROL_SET.deterministic`). |
| Testable | ✓ | Engine headless (FR-033); GUI offscreen (C-017); differential tests against golden fixtures (A-015); defect-register tests per item; layering, purity and determinism tests listed in 07 file structure. |
| Fleet laws | ✓ | Prefix `BIB_` and C prefix `sbib_` checked unique (A-009); zero C; blocking-externals law applied (A-005); fill-gaps rule (no fallback anywhere in the design); README/docs rule in the phase plan. |

## Requirements Traceability

### L0 data and build

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| FR-001 | `BIB_DISTRIBUTION_BUILDER`, `BIB_BUILD_CONTEXT` (date passed in), `BIB_TABLE_CHECKSUM`; `test_build_determinism` | ✓ |
| FR-002 | `BIB_BUILD_STEP.execute` postcondition `provenance_for_rows`; builder `all_rows_have_provenance` | ✓ |
| FR-003 | `BIB_CREDITS_GENERATOR`; builder `credits_generated`; `SIMPLE_BIBLE.credits` | ✓ |
| FR-004 | `BIB_LICENSE_GATE.ship_allowed`, `check_manifest` (named refusal) | ✓ |
| FR-005 | `BIB_VERSION_INFO.caveat`, `BIB_PROVENANCE.caveat`; adapters show it | ✓ |
| FR-006 | `BIB_DEFECT_RULES_STEP` (quarantine table); `BIB_OMISSION.Quarantined`; `BIB_VERSE_TEXT.is_quarantined` | ✓ |
| FR-007 | `BIB_DEFECT_RULE` per register item; `test_defect_register` | ✓ |
| FR-008 | `BIB_VERSE_TEXT.display_text` (no setter); `BIB_NORMALIZE_STEP`; folded text lives in the stage's stored column and the shipped contentless index, never in a display column (fold 2026-10-26, debate 01; was "separate `verse_norm`") | ✓ |
| FR-009 | `BIB_OMISSION.Edition_omitted` | ✓ |
| FR-010 | `BIB_BUILD_MANIFEST`, `BIB_PINNED_SOURCE` (hashes, license-text hash); builder precondition | ✓ |
| FR-100 | `BIB_IMPORT_SWETE`, `BIB_SWETE_REPAIR` (12 checklist as postconditions) | ✓ |
| FR-101 | `BIB_REF.suffix`, verse 0, chapter 0 (prologue) | ✓ |
| FR-102 | `BIB_LICENSE.is_share_alike`; SA tables separate; `BIB_ATTRIBUTION.share_alike_notice` | ✓ |
| FR-103 | `BIB_RIX_DB_BUILDER`, `BIB_RIX_RULES`, `BIB_VAULT_WALKER`, `BIB_VAULT_DOCUMENT`; `test_rix_differential` | ✓ |
| FR-104 | `BIB_DB_COMPARATOR` + golden fixtures; one differential test per port | ✓ |
| FR-105 | `BIB_BOOK_CATALOG_STEP`, `BIB_BOOK_CATALOG` (vault ids) | ✓ |
| FR-106 | `BIB_PROVENANCE.make_ai_made` (method, model id); precompute stages | ✓ |
| FR-107 | `BIB_IMPORT_STEPBIBLE` (TIPNR descriptions AI-labeled or omitted), `BIB_IMPORT_STRONGS` (Moody material stripped) | ✓ |

### L1 engine

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| FR-020 | `BIB_REFERENCE_PARSER`, `BIB_PARSE_RESULT` (`exactly_one_state`, `ambiguous_has_choices`) | ✓ |
| FR-021 | `BIB_VERSE_HUB`, `BIB_VERSE_RESULT`, `BIB_WORD`, `BIB_MORPH_EXPANDER`, `BIB_CROSS_REFERENCE` | ✓ |
| FR-022 | `BIB_VERSIFICATION_MAP`, `BIB_MAPPED_REF` (selective creation), `BIB_VERSIFICATION_STEP` (TVTMS + LXX Jer + Swete entries) | ✓ |
| FR-023 | `BIB_CONCORDANCE`, `BIB_STRONGS_KEY` (sense suffix), normalizers; unchanged for Release 1a: the headword rule (keys are `lemma_id`, never Strong's) governs the concordance pack's lookups only, and rekeying FR-023 would be 05b overturn trigger 3 and a new debate (fold 2026-10-26, debate 05, conflict 1) | ✓ |
| FR-024 | `BIB_KEY` family as the only join/count inputs; `test_layering` static SQL check | ✓ |
| FR-025 | `BIB_CENSUS_DEFINITION` (`not_frozen` preconditions, `freeze`, `new_version`) | ✓ |
| FR-026 | `BIB_BUCKETED_RESULT` (no single-bucket API; `extend`/`seal` engine-only) | ✓ |
| FR-027 | `BIB_VERDICT.No_data`; `BIB_SHAPE.classify` `absent_tag_is_no_data` | ✓ |
| FR-028 | `BIB_SHAPE` family, `BIB_SHAPE_ENGINE.evidence` (`not_judgment`), `BIB_SHAPE_PRECOMPUTE`; acceptance modified to differential (03 A-014) | ◐ (shape count and Louw-Nida licensing open: Q-07) |
| FR-029 | `BIB_RANGE_VIEWER`, `BIB_RANGE_RESULT` | ✓ |
| FR-030 | `BIB_QUOTATION_COMPARER`, `BIB_QUOTATION_RESULT` (`edition_note_present`, `ocr_flagged`), `BIB_ALIGNMENT_PRECOMPUTE` | ◐ (hand-verified LXX spans needed for the acceptance case; 03 A-001) |
| FR-031 | `BIB_CHECK` family, `BIB_CHECK_RUNNER` | ✓ |
| FR-032 | `BIB_METHOD`, `SIMPLE_BIBLE.rerun` | ✓ |
| FR-033 | L-LIB has no UI dependency; headless tests | ✓ |
| FR-108 | `BIB_WORD_JOURNEY`, `BIB_JOURNEY_RESULT` (method per row) | ✓ |
| FR-109 | `BIB_DIVINE_NAME_MARKER` (keys; Swete surface-form labeled) | ✓ |
| FR-110 | `BIB_GUIDE_ASSEMBLER`, `BIB_GUIDE.add_section` (`has_data`) | ✓ |
| FR-111 | `BIB_RELATED_PASSAGES`, `BIB_RELATED_PASSAGE` (`ai_made_has_label`) | ✓ |
| FR-112 | `BIB_CONTROL_SET` (seed, band, determinism) | ✓ |
| FR-113 | `BIB_POINTING_REDUCER`, `hub.reduced_pointing` | ✓ |
| FR-114 | `BIB_TOKEN_DIFF` | ✓ |
| FR-115 | `BIB_COUNT_TABLE` (per 1,000 words in Eiffel) | ✓ |
| FR-116 | `BIB_LIBRARY`, `BIB_LIBRARY_ENTRY`, `BIB_IMPORT_LIBRARY_MODULE` | ◐ (scope placement: Q-01) |
| FR-117 | `BIB_USER_STORE`, `BIB_USER_ITEM` kinds keyed to hub ids | ✓ |
| FR-118 | `BIB_MEMORY_SCHEDULER`, `BIB_READING_PLAN` | ✓ |
| FR-119 | `BIB_EXPORTER`, `BIB_ATTRIBUTION` (`share_alike_notice`, `ai_labeled`) | ✓ |
| FR-120 | `BIB_AUTHOR_LIBRARY` (`withdrawn_only_if_requested`), `BIB_AUTHOR_DOC` (`status_valid`, `banner_for_flagged`) | ✓ |
| FR-121 | `BIB_COMMAND_SET` (`closed`), `BIB_CMD_*` family, exit codes | ✓ |
| FR-122 | `BIB_VERSION_INFO` (`never_bare_lxx`, `septuagint_labeled_with_edition`); adapter `no_bare_lxx` | ✓ |
| FR-123 | `BIB_JOB`, `BIB_CANCEL_TOKEN`, `BIB_JOB_MAILBOX` (`cancelled_discards`) | ✓ |
| FR-124 | Layer rules (04 §0); `BIB_ENGINE_CLIENT`; `BIB_RESULT_ADAPTER` | ✓ |
| FR-125 | Private packs with a `NOT NULL` voice column, read by the public generic pack reader: `BIB_PRIVATE_SOURCE`, `BIB_LENS_RESULT` (`voice_attached`); `test_pack_purity` (K2′; name proposed by the fold; fixed in Phase 4) (fold 2026-10-26, debate 03; was "`BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, `BIB_PRIVATE_SOURCE`, `BIB_LENS`, `BIB_LENS_RESULT` (`voice_attached`); `test_plugin_purity`") | ✓ |
| FR-126 | v1.5 classes `BIB_CLAIM*` (04 §1.2) | ◐ (deferred by release) |
| FR-127 | v1.5 `BIB_STUDY_LEDGER`, `BIB_LEDGER_ENTRY` | ◐ (deferred by release) |
| FR-128 | v2 timeline classes; `BIB_HISTORY_BUILDER`, `BIB_HISTORY_GATE` | ◐ (deferred by release) |

### From R03 (fleet findings and research/13 user voice)

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| FR-NEW-001 (NFR-016) | Chunked jobs; FT-02; `test_gc_probe` | ◐ (FT-02) |
| FR-NEW-002 | `BIB_JOB_MAILBOX`, `BIB_CANCEL_TOKEN` | ✓ |
| FR-NEW-003 | LG-01 in simple_encoding; `BIB_GREEK_NORMALIZER` | ◐ (LG-01) |
| FR-NEW-004 | `BIB_REPAIR_STATE`, `BIB_VERSION_INFO.text_quality_caveat`, `BIB_QUOTATION_RESULT.ocr_flagged` | ✓ |
| FR-NEW-005 | `BIB_BOOK_CATALOG_STEP` | ✓ |
| FR-NEW-006 | Golden fixtures + `BIB_DB_COMPARATOR` | ✓ |
| FR-NEW-007 | `BIB_SEARCH_ENGINE.start_search` `scope_bounded_for_regex` | ✓ |
| FR-NEW-008 | `BIB_METHOD.sqlite_version` | ✓ |
| FR-NEW-009 | Font rows under the license gate | ✓ |
| FR-NEW-010 | `test_pack_purity` (name proposed by the fold; fixed in Phase 4): no private string in ASCII, UTF-16LE or UTF-32LE, positive control includes a `{STRING_32}` private string (fold 2026-10-26, debate 03; was `test_plugin_purity`) | ✓ |
| FR-NEW-011 | `test_layering` banned accessors; LG-03 | ✓ |
| FR-NEW-012 | `BIB_COMPLETENESS_CHECK` (v1.5, with Claim Check) | ◐ (deferred by release) |
| FR-NEW-013 | `BIB_GUIDE_ASSEMBLER` `text_first` postcondition | ✓ |
| FR-NEW-014 | `BIB_PANEL.accessible_name`, `spoken_text`; CLI transliteration; `BIB_MEMORY_CARD.chunk_size`; GW-14 bridge | ◐ (release of GW-14: Q-13) |
| FR-NEW-015 | `BIB_NOTE_STORE`, `BIB_DB_NOTE_STORE` (Release 1a default); `BIB_MARKDOWN_NOTE_STORE` is the gated 1b candidate (fold 2026-10-26, debate 02) | ◐ (answered by Q-11's own fallback, debate 02; K2 and K3 contract tests count only after F-9 and P-ATOMIC pass) |
| FR-NEW-016 | Note-store history and soft-delete contracts; `BIB_USER_BACKUP` | ✓ |
| FR-NEW-017 | `BIB_USER_STORE.migrate` `settings_preserved`; previous-version fixture test | ✓ |
| FR-NEW-018 | Normalizer `punctuation_folded`; `BIB_STRONGS_KEY.make_from_text` `padding_insensitive`; copied-phrase golden test | ✓ |
| FR-NEW-019 | `BIB_METHOD.scope_label` invariant; `BIB_VERSION_INFO.verse_count`, `seal` | ✓ |
| FR-NEW-020 | `BIB_PANEL.link_role`; `scrolled_to` postconditions | ✓ |
| FR-NEW-021 | `BIB_CONFIG.make_portable` | ✓ |

### L2, L3, L4

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| FR-040 | `BIB_EMBEDDING_PRECOMPUTE` (simple_onnx); vectors ship with v2 (Q-06) | ◐ (tokenizer check, 03 A-003) |
| FR-041 | `BIB_RELATED_PRECOMPUTE` (votes, rare lemmas via `BIB_TFIDF_INDEX`, neighbors) | ✓ |
| FR-042 | `BIB_ALIGNMENT_PRECOMPUTE` | ✓ |
| FR-043 | `BIB_GLOSS_TABLE_PRECOMPUTE` (coverage report lists gaps) | ✓ |
| FR-044 | review fields on AI-drafted rows (pattern of `summary_drafted_by`); none in R1 | ✓ |
| FR-050 | `BIB_NULL_AI_ADAPTER` default; no model in R1 | ✓ |
| FR-051 | v2 `BIB_QUERY_EMBEDDER` | ◐ (deferred by release) |
| FR-052 | v3 `BIB_LOCAL_CHAT_ADAPTER` behind `BIB_AI_ADAPTER` | ◐ (deferred by release) |
| FR-053 | `BIB_AI_POST_CHECK` (only creator of `BIB_AI_TEXT`) | ✓ (designed now) |
| FR-054 | v3, via simple_winhttp | ◐ (deferred by release) |
| FR-060 (modified) | GUI on simple_widgets/simple_shaping; D-006 spike P0; GW-01..03; no WebView2 (D-006); the concordance faces (word view in the pilot's order, paged virtual grid, PERSONAL EDITION marking; 06) (fold 2026-10-26, D-006 and D-021) | ◐ (every GW gap is done, Phase 4 complete 2026-10-26; the P0 spike and offscreen panel tests remain) |
| FR-061 | L-CLI, plus the three concordance lookups (word view, English, verse words) through `word_lookup`, `english_index` and `verse_word_lookup` (fold 2026-10-26, debate 05b section 8) | ✓ |
| FR-062 (modified) | `installer/simple_bible.iss` (P6), OFL fonts, no WebView2 | ✓ |
| FR-063 (modified) | Private data packs read by the generic pack reader (no plug-in seam); the author library ships inside `content.db`, built by its own stage (D-019, debates 01 and 03) (fold 2026-10-26) | ✓ |
| FR-064 | No network code in R1 (simple_winhttp only in v3, off by default) | ✓ |
| FR-065 | No helper processes in R1; v3 spawns hidden via simple_process | ✓ |

### Non-functional

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| NFR-001 | Lookup worker (bounded verse-and-word lookups, p95 < 50 ms test; the concordance first screen is NFR-019, a different budget: fold 2026-10-26, settlement S5), folded index and rowid-range filters, chapter as the load unit | ✓ (fold 2026-10-26, debate 01: index wording) |
| NFR-001 (concordance first screen) | **At risk** (fold 2026-10-26, debate 05b): the commonest words sit near 200 ms warm and up to 2,773 ms cold; check V-52 below measures it | ◐ |
| NFR-002 | Precomputed lemma frequencies; chunked jobs; bounded regex scope | ✓ |
| NFR-003 | Visible chapter + neighbors in the GUI; pages dropped when off screen (GUI notes §6) | ✓ |
| NFR-004 | v2+ only | ◐ |
| NFR-005 | Release 1 ships neighbors, not vectors (Q-06) | ✓ |
| NFR-006 | Ordered queries; `BIB_METHOD.counts_equal`; deterministic controls | ✓ |
| NFR-007 | Builder postcondition; `BIB_FACT` | ✓ |
| NFR-008 | `BIB_LICENSE_GATE` | ✓ |
| NFR-009 | No GPU path; LG-04 optional for the build machine only | ✓ |
| NFR-010 | Windows 10 22H2 / 11 x64 (simple_shell) | ✓ |
| NFR-011 | No network in R1 | ✓ |
| NFR-012 | Withdrawn (D-006) | n/a |
| NFR-013 | Two type scales, keyboard (GW-24), dark/high contrast; screen reader GW-14 (v1.5) | ◐ |
| NFR-014 | AI-made labels (provenance, related passage, adapter, exporter invariants) | ✓ |
| NFR-015 | Phase 1 obligation; 05 sets the pattern | ◐ (verified at /eiffel.contracts) |
| NFR-016 | Chunking + FT-02 + GC-probe test | ◐ (FT-02) |
| NFR-017 | Startup checks `user_version` and table presence only (GUI notes §6) | ✓ |
| NFR-018 | `BIB_BUILD_CONTEXT`, `BIB_TABLE_CHECKSUM` | ✓ |

**Totals:** 90 functional requirements traced (FR-001..010, FR-020..033, FR-040..044, FR-050..054, FR-060..065, FR-100..128, and FR-NEW-001..021 from R03), 18 non-functional. ✓ 74 FR + 13 NFR; ◐ 16 FR + 4 NFR (each with a named condition or a release deferral); NFR-012 n/a (withdrawn); ✗ 0.

## Acceptance checks named by the verdicts (fold 2026-10-26)

*Every row below is a check the gated verdicts name. None has run in this specification phase; each runs as a test (finalized F_code, contracts on, except the timing checks, which run `without_contracts`) or as a measurement on the reference machine. Pass criteria are the verdicts' own.*

### Layout and search (debate 01)

| ID | Check | Pass criterion | Source |
|----|-------|----------------|--------|
| V-01 | Assembly at the full Release 1a corpus (rerun of the RED1 assembly spike as a test), including stage-verify and transplant of every FTS index | Per-table identity with each stage (`EXCEPT` both directions, FTS5 shadow tables included): 0 differing rows; two builds from one manifest byte-identical; assembly plus identity check no longer than the slowest single stage build | debate 01, OT-L1, OT-N2, queue 2 |
| V-02 | Stage index `integrity-check` and shipped-index identity (rerun of ADJ-contentless-verify) | Stage `verse_fts` passes `integrity-check`; the four shadow tables of the shipped contentless index equal the stage's; the negative control (one stage row changed behind the index) fails | debate 01, section 2.1, OT-N2 |
| V-03 | K7-A per-schema provenance check | `PRAGMA <schema>.foreign_key_check`, named per schema, returns no rows for `content.db` and every pack; a bare check is never used; R15 coverage (a `provenance_key` or a same-file sidecar on the shipped R15 copy, stage identity on the R15 columns, author-library open still passes) | debate 01, K7-A, queue 10, OT-L5 |
| V-04 | K9-A empty-content run | With optional public content empty, the core edition passes the full suite with no model files and the author library shows its absent state, not an error | debate 01, K9-A |
| V-05 | AC-1a-10 object | `BIB_DB_COMPARATOR` reports zero mismatched rows and columns, `mtime` included, on the **rix stage file** against the Python golden | debate 01, section 1.4 |
| V-06 | LG-01 normalizer census | No general category M\* or Cf residue and no idempotence failure in any Release 1a version (K3-A); ZWJ and CGJ cases included | debate 01, OT-N4, queue 5 |
| V-07 | Folded search against an independent reference | For 20 lemmas, folded-search recall of the unprefixed surface forms is not below the raw index's whole-word recall | debate 01, OT-N6, queue 7 |
| V-08 | Rowid-range contract (SB-1) | `verse_id` contiguous per version; every search and display-fetch path filters by FTS rowid range; no join on `verse.version_id`; `hub_id` never the FTS rowid; one-version search p95 under 300 ms (warm, dev machine: about 1 ms measured) | debate 01, section 8, F1-C2b-R |
| V-09 | Reference-machine run (8 GB, CPU only, SATA SSD) | AC-1a-56: 3 s cold start, 100 ms first verse jump, with the lookup inside the timer and no prior warm-up, on `content.db` plus one pack | debate 01, OT-L2, queue 1 |
| V-10 | Pack fold parity | Mismatches between a non-Eiffel pack fold and the Eiffel normalizer on the published parity fixture: 0, or the pack is attached and labeled "not diacritic-safe" | debate 01, OT-N5, queue 6, gate item 4 |
| V-11 | Search shapes (reported, not gated, in 1a) | Cross-version breakdown, book-subset and prefix search times are reported in the 1a suite, not gated | debate 01, gate item 5 |
| V-12 | Attach policy under SCOOP | With every real pack present, no query fails at attach number 11; attach number 11 reports SQLite's own message, not "Unknown error"; cost per attach and detach per query recorded | debate 01, queue 4; debate 03, OT-6 and new acceptance criterion (iii) |
| V-13 | 3.53.4 re-run of the 3.31.1-specific findings | Contentless `integrity-check`, bare `foreign_key_check`, join-form plan, rowid range, `schema.fts MATCH`, attach limit rerun on 3.53.4 (debate 04's ADJ-f1-recheck already shows: bare check reports the violation; `schema.fts MATCH` errors on both; contentless `integrity-check` returns OK at fixture scale; attach limit 10 on both) | debate 01, queue 11, OT-L6; debate 04, section 8 |

### Notes store (debate 02)

| ID | Check | Pass criterion | Source |
|----|-------|----------------|--------|
| V-20 | P-ATOMIC after F-9 | The ADJ-p-atomic probes (A1, A2, A3, M1) on the fixed simple_sql: any partial commit or unreported failure is 0; no user-store contract test counts as passed before this | debate 02, OT-1, 5 item 3 |
| V-21 | Kill harness on the new engine | The 600-kill harness rerun on SQLite 3.53.4: verified loss 0 | debate 02, OT-7 |
| V-22 | Export contract | Every failure is reported; `files_written + failures = live notes`; file names are id-based or sanitized, never a raw title; atomic write; folder created by the exporter; import never overwrites a row | debate 02, 5 item 2, section 8.2 |
| V-23 | Exit snapshot and start backup (DS-B′, DS-B-S8) | Pass required before adoption: after an unclean exit, a start, then `user.db` deleted and restored from backup, note bytes lost outside the crash-to-next-start window: 0 | debate 02, OT-2, gate item 2 |
| V-24 | Notes cold-start share | Store share of cold start on the reference machine, cold cache, at 10,000 and 100,000 notes: not above 1 s (38-43 ms measured at 100,000 notes, dev machine); NFR-017 states whether store start-up work is inside the 3 s | debate 02, OT-6, 8.2 |
| V-25 | A″ gates (Release 1b only) | DS-3c (0 editor edits lost with Obsidian as the outside writer, every refused save retried or reported; one GUI test on a scratch vault, a time Larry chooses), DS-10, DS-2″, DS-1/DS-8 on the reference machine, DS-R1, DS-R2, and F-1″, F-3b, F-11 shipped | debate 02, OT-3, gate item 5 |

### Private packs (debate 03)

| ID | Check | Pass criterion | Source |
|----|-------|----------------|--------|
| V-30 | B′ end to end in Eiffel on SQLite | Export writes rows for one lens; the engine attaches read-only, joins a mapped passage and builds voiced results; any mismatch against the code port's annotations, any result without a voice, or any write that succeeds on the attachment: 0 | debate 03, OT-2 |
| V-31 | Purity test (AC-1a-57, K2′) | The public executable contains no string from the private list in ASCII, UTF-16LE or UTF-32LE; the positive control includes a `{STRING_32}` private string | debate 03, section 8 |
| V-32 | Unlabeled private result | 0 in a fixture run; the pack voice column is checked at attach for generic private data packs (conc.db is checked by `BIB_CONC_PACK`'s own check: expected `user_version` plus required tables; fold 2026-10-26, settlement S6) | debate 03, K4, new acceptance criterion (i) |
| V-33 | Attach form | Packs attach through `SIMPLE_SQL_DATABASE.attach_read_only` on a read-only main, never through `ATTACH 'file:...'` by `perform` or `execute` (fold 2026-10-26, settlement S1; was "through `query` (or `attach_read_only`)") | debate 03, new acceptance criterion (ii); debate 05a |
| V-34 | C-03 presentation spike | Mismatches against generic list and detail output: 0 for every observable field of a private REPL command's output | debate 03, OT-1 |
| V-35 | Pack-schema churn and export cost | Pack `user_version` bumps in no more than 2 of the first 4 public releases; the graph analytics on the real exported graph take no more than 30 minutes per export on the reference machine | debate 03, OT-4, OT-5 |

### SQLite library (debate 04)

| ID | Check | Pass criterion | Source |
|----|-------|----------------|--------|
| V-40 | Clean campaign on copies (S-F4-4) | Every SQLite-reaching target of the 20 projects plus treebiz_core, each from clean EIFGENs, 0 new failures against its `_old` baseline | debate 04, 5.4 step 1, OT-1 |
| V-41 | `blocking` reaches every dependent | The generated C of each rebuilt target wraps the library's `sqlite3_step` in `EIF_ENTER_C`; a version test cannot see this failure; every dependent rebuilt `-clean` | debate 04, 5.3 |
| V-42 | GC-probe test and GUI allocation wait | `test_gc_probe` passes (NFR-016); AC-1a-48 at P5 measures a GUI-processor allocation wait not above 16 ms during a census | debate 04, OT-7 |

### Concordance (debate 05, D-021)

| ID | Check | Pass criterion | Source |
|----|-------|----------------|--------|
| V-50 | Spike S1 rerun: attach and write refusal | `attach_read_only` on a read-only connection succeeds; a write into the attached pack, sent through the query path, is refused ("attempt to write a readonly database"); attached queries are not more than 20 percent slower than direct | debate 05a, fork 1 |
| V-51 | Spike S2 rerun: transliteration | `token.translit` equals the pilot's rules over all 158,342 distinct written forms, 0 failures; for conc_dist.db's Eiffel builder, a form-by-form differential test against `conc_translit.py` | debate 05a, fork 4 |
| V-52 | First-screen measurement | The whole word view's first screen (heading, how often, English at a glance, first page of 200 places), back to back, lean F_code, conc.db attached read-only, three rounds: rare and ordinary words instant; the commonest words (Greek article NT lemma 9380; Hebrew "and" lemma 8, 50,272 places) near the 200 ms target warm. Baseline: 205 / 398 / 197 ms and 2,773 / 277 / 140 ms. The builder item (per-headword precomputed counts and English summary) is overturned only by a measured cold first screen under 200 ms for lemma 8 without it | debate 05b, queue 2 and addendum |
| V-53 | Paged lists | No list is loaded whole: first page of 200 places in about 25-28 ms (lean); a cursor left early is closed; timing tests run `without_contracts` (contracts cost 20 times on large reads) | debate 05a, do-not-assume 1, 2, 4 |
| V-54 | Edition-swap check | The same executable and the same `BIB_CONC_PACK` run against conc.db and against conc_dist.db changing only `conc_path`; no code change; layers the distribution pack lacks (`has_layer`) do not appear and nothing fails; the title bar and About window show `edition_label` ("PERSONAL EDITION - not for distribution" for conc.db) | D-021; debate 05a, 05b |
| V-55 | No edition test in engine code | Phase 4 grep over `src/` finds no edition literal and no branch on `edition_label` (05b overturn trigger 4) | debate 05b, queue 4 |
| V-56 | No display-string joins | FR-024 static join check over `BIB_CONC_PACK`: every concordance join and count is keyed by `lemma_id` (or `lemma_xref` for Strong's), never by a display string, never by Strong's directly | debate 05b, queue 4; research/14 section 1 |
| V-57 | Melt compile of the skeletons | `ec.sh check` on skeleton B (plus `BIB_HEADWORD_KEY`, non-conforming or with a rejecting precondition on `BIB_CONCORDANCE.count`, only if adopted) | debate 05b, queue 1 |
| V-58 | core.db schema read | When core.db is built, read its `lemma` and `alignment` columns once: can they answer a headword, place or English query in `lemma_id` terms (05b overturn trigger 1)? | debate 05b, queue 3 |

### Verification queues carried (not run; no weight until run)

| Queue | Items | Source |
|-------|-------|--------|
| Debate 01 | 1 reference machine, 2 full-corpus assembly, 3 R-N5, 4 attach policy under SCOOP, 5 LG-01 normalizer at corpus scale, 6 pack-boundary fold parity, 7 independent recall, 8 folded-scan consumer if specified (BR-3 with the real normalizer and simple_regex), 9 normalizer throughput at 3M rows, 10 K7-A R15 coverage, 11 3.53.4 re-run | debate 01, section 7 |
| Debate 02 | DS-B′, DS-B-S8, DS-3c and the A″ gates; P-ATOMIC after F-9 | debate 02, sections 5 and 7 |
| Debate 03 | OT-1 to OT-7 triggers above | debate 03, section 5 |
| Debate 04 | S-F4-4 campaign; ship-plan steps 5-8 | debate 04, section 5.4 |
| Debate 05b | 1 skeleton compile, 2 first-screen spike (executed 2026-10-26), 3 core.db schema, 4 edition-literal grep and FR-024 join check | debate 05b, section 7 |

## Risk Mitigations Implemented

| Risk | Mitigation in Design |
|------|---------------------|
| RISK-001 SQLite 3.31.1 | DDL and SQL limited to 3.31.1 features (the Release 1 ceiling stays 3.31.1 on the 3.53.4 engine, RQ-03 option 2); SQLite version recorded in every method; FT-01 with FT-02, the FT-02-only build is the contingency (fold 2026-10-26, debate 04; was "FT-01 separate") |
| RISK-002 FTS5 and marks | Normalizer family with idempotence and no format character (Cf); LG-01; build-time folded index, stage-verified, contentless when shipped; trap-corpus tests (fold 2026-10-26, debate 01; was "normalized columns") |
| RISK-003 Licensing | License gate; Swete default; Rahlfs `ship = false`; fonts under the gate (A-020) |
| RISK-004 Wrong pairings | `BIB_MAPPED_REF` selective creation; regression suite with Swete legs |
| RISK-005 Re-contamination | Content-anchor checks in importers; quarantine rules as build steps |
| RISK-006 AI invents facts | No run-time AI in R1; `BIB_AI_TEXT` only via post-check |
| RISK-007 Weak embeddings | Related passages also from votes and rare lemmas, each with its reason |
| RISK-008 Harvested code broken | Copy-and-adapt per ledger row; harvest column in 04 |
| RISK-010 8 GB thrash | No model in R1; capability probe in v2 |
| RISK-011 Scope creep | Private packs as data (B′); public purity test (K2′) (fold 2026-10-26, debate 03; was "Plug-in seam; public purity test") |
| RISK-013 Share-alike | SA flags, separate tables, export notice |
| RISK-014 Bus factor | Spec Kit artifacts; reproducible build; README/docs rule |
| RISK-016 Omissions read as errors | `BIB_OMISSION` kinds with reason text |
| RISK-017 Gloss as meaning | Glosses are orientation fields; counts never key on gloss |
| RISK-018 GUI gap schedule | Engine + CLI first; panels staged by gap closure (A-011) |
| RISK-019 GC stall on sqlite | FT-02 (adopted: six externals, no hook guard (fold 2026-10-26, settlement S3); clean rebuild of every dependent) + chunking + GC-probe test (A-005) (fold 2026-10-26, debate 04) |
| RISK-020 Swete OCR | `BIB_REPAIR_STATE`, quality caveat, OCR note on verdicts, hand-verified spans (A-001) |
| RISK-021 Lost or scrambled notes (13 T10) | Append-only history, soft delete, `BIB_USER_BACKUP`, hub-id keys (A-022) |
| RISK-022 Trust betrayals (13 T05, T18) | Migration preserves settings; per-text seal; count-scope labels; trust rules for ratification (A-023, A-025, A-029) |

## Open Issues (questions for Larry)

| ID | Question | Recommendation |
|----|----------|----------------|
| Q-01 | Release 1 scope: one list (GUI v1, including library content packs) or 1a (engine, core texts, reader, search, census/shapes, They Chose seed, journey, divine names, renderings, author library, notes/highlights/bookmarks/history) then 1b (commentaries, lexicons beyond Strong's, dictionaries, devotionals, prayer, memory, plans)? | 1a then 1b; the design is identical either way |
| Q-02 | FT-02: patch eiffel_sqlite_2025's externals in place, or a fleet-local fork? Do it together with the D-007 upgrade (FT-01)? | Patch in place with FT-01, one fleet regression. **Answered (fold 2026-10-26, debate 04): A″ adopted, PREFERRED 0.82 / 0.88; one clean campaign on copies before the commit, every dependent rebuilt `-clean` after it; landed in eiffel_sqlite_2025 1.1.0** |
| Q-03 | Fonts: ship SIL OFL fonts only (Ezra SIL; Gentium Plus or Noto for polytonic Greek), or verify and ship the SBL fonts? | OFL only unless SBL terms are verified |
| Q-04 | Ecclesiastes in the Swete slot: Brenton 1851 rows labeled, or "not in this digital edition"? (from 12) | Brenton, labeled |
| Q-05 | Update the harvest ledger: H-01..H-07, H-13, T-07 become ARCHIVE-ONLY; retirement criterion R-4 reads "native face" (D-006 overtook them) | Yes |
| Q-06 | Release 1 ships related-passage neighbors only, with the vectors arriving with v2 meaning search | Yes (smaller download) |
| Q-07 | T2 shapes that use Louw-Nida domains: take the domains from UBS SDGNT (CC BY-SA 4.0) or gate those shapes until the MARBLE permission question is settled? | UBS SDGNT |
| Q-08 | TUI face (ledger L-3): the design has none; confirm | None |
| Q-09 | Withdrawn author documents excluded from search by default with an "Include withdrawn" switch, always labeled (GUI open point 3) | Confirm |
| Q-10 | Primary first user (13 Q1): the lay reader who outgrew e-Sword, or the pastor who left BibleWorks? It sets the default screen and the Release 1a/1b order | Lay reader (13: trust themes come mostly from lay readers; the Simple layout is the default) |
| Q-11 | Notes: user.db (default) or Markdown files in a user folder (Obsidian-compatible) first? The design supports both behind `BIB_NOTE_STORE` (13 Q3) | Markdown folder as the store, user.db as its index, if Release 1 can carry it; otherwise user.db first. **Answered by fallback (fold 2026-10-26, debate 02): Release 1a cannot carry it, so user.db first (pathway B, PREFERRED 0.70 / 0.80); A″ stays the gated 1b candidate** |
| Q-12 | MCP face for users' own AIs (13 S6): build `bible_mcp` (stdio, opt-in, new fleet library LG-06), and when? | v1.5, stdio only |
| Q-13 | Screen-reader access (13 S14, T23): pull GW-14 (UI Automation bridge) into v1? Panels are bridge-ready either way | v1 if the simple_shell/simple_widgets owners can schedule it; it is a real reason to choose the tool |
| Q-14 | Ratify the trust rules (03 A-029): no tiers/ads/store/prompts/account/telemetry/activation; AI off by default, never in plain search, never pasted unlabeled; no persona chatbots or sermon generator; donation link on About only | Ratify |
| Q-15 | Performance reference machine: 8 GB CPU-only with SSD (research) or without (13 T04 suggests non-SSD, verse jump < 100 ms, whole-Bible search < 300 ms)? | State both; gate on the SSD numbers, report the HDD numbers |
| Q-16 | Deferred sparks for /eiffel.intent: S10 disagreement map (curated position data reusing the timeline's dispute model), S3 archaic-word helper, S4 trust rings (generalize `BIB_VOICE` to every resource), S7 map that follows the reading, S8 plain-English apparatus, S13 unlock-as-you-go, S15 exhaustive study export | Decide per spark at intent |

**Carried, not reopened:** MorphGNT license wording (adopt CC BY-SA per its README), Byzantine text edition, product name, Rahlfs permission letters (12 §C), "Larry's lean" in the public timeline (v2).

## Ready for Implementation

- [x] All requirements traced (90 FR incl. 21 from R03, 18 NFR; none untraced)
- [x] All risks mitigated in design (19 risks; three fleet risks and two user-voice risks found during R01-R03 included)
- [x] All principles satisfied (OOSC2 ✓; SCOOP ◐ with FT-02 as a named prerequisite)
- [x] Design is complete for /eiffel.intent: classes, contracts, interfaces, seams, dependencies, file structure and phase plan are specified; open questions are scope and policy choices, not design gaps

**VERDICT:** READY (for /eiffel.intent), with conditions that gate later phases, not this one:
1. LG-01 before the build phase's normalize step (P1).
2. FT-02 before the GUI phase (P5); the engine's chunking protects the CLI meanwhile. FT-02 has landed (fold 2026-10-26, debate 04); F-9 and the P-ATOMIC probes before the `user` cluster's tests (debate 02).
3. The bge-m3 tokenizer check before the embedding precompute (P3).
4. Q-01, Q-07, Q-11 and Q-13 answered before /eiffel.tasks fixes the Release 1 task list.
