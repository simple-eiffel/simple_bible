# DESIGN VALIDATION: simple_bible

*Step R08, 2026-10-06. Validation of 01-07 against OOSC2, Eiffel practice, the fleet laws, and every requirement and risk. ✓ = satisfied in the design; ◐ = satisfied with a recorded condition; ✗ = not satisfied.*

---

## OOSC2 Compliance

| Principle | Status | Evidence |
|-----------|--------|----------|
| Single Responsibility | ✓ | 04 §1 gives one responsibility per class; engines (one question each) are separate from results (immutable data) and from sources (connections). The facade only opens and delegates. |
| Open/Closed | ✓ | New shapes, checks, normalizers, user-item kinds, build steps, importers, commands, panels and plug-ins are added as descendants of deferred bases (`BIB_SHAPE`, `BIB_CHECK`, `BIB_NORMALIZER`, `BIB_USER_ITEM`, `BIB_BUILD_STEP`, `BIB_COMMAND`, `BIB_PANEL`, `BIB_PLUGIN`, `BIB_LENS`) without changing engine code. Library content packs plug in as data behind `BIB_LIBRARY` (03 A-010). |
| Liskov Substitution | ✓ | 04 §5 justification table; descendants only strengthen invariants or weaken preconditions; `BIB_NULL_AI_ADAPTER` returns Void within the parent's `detachable` result; `BIB_USER_STORE.is_read_only = False` is a query clients never assume True for every source. |
| Interface Segregation | ✓ | The GUI sees `BIB_ENGINE_CLIENT` (lookups, jobs, user data) only; the CLI sees the facade and the command set; plug-ins see `BIB_PLUGIN`/`BIB_LENS`/`BIB_PRIVATE_SOURCE`; the AI seam sees `BIB_ENGINE_RESULT` only. |
| Dependency Inversion | ✓ | Faces depend on engine abstractions and result types, never on simple_sql (layer rule tested by `test_layering`); private code depends on deferred seams in the public library, never the reverse; engines depend on `BIB_DATA_SOURCE` abstractions. |

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
| SCOOP-compatible | ◐ | Processor map 04 §7; one connection per processor; mailbox and token on their own processors (03 A-006); chunked jobs (A-005). **Condition:** FT-02 (`blocking` sqlite externals) must land before the GUI phase for NFR-016 to hold under garbage collection; the GC-probe test proves it. |
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
| FR-008 | `BIB_VERSE_TEXT.display_text` (no setter); `BIB_NORMALIZE_STEP`; separate `verse_norm` | ✓ |
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
| FR-023 | `BIB_CONCORDANCE`, `BIB_STRONGS_KEY` (sense suffix), normalizers | ✓ |
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
| FR-125 | `BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, `BIB_PRIVATE_SOURCE`, `BIB_LENS`, `BIB_LENS_RESULT` (`voice_attached`); `test_plugin_purity` | ✓ |
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
| FR-NEW-010 | `test_plugin_purity` | ✓ |
| FR-NEW-011 | `test_layering` banned accessors; LG-03 | ✓ |
| FR-NEW-012 | `BIB_COMPLETENESS_CHECK` (v1.5, with Claim Check) | ◐ (deferred by release) |
| FR-NEW-013 | `BIB_GUIDE_ASSEMBLER` `text_first` postcondition | ✓ |
| FR-NEW-014 | `BIB_PANEL.accessible_name`, `spoken_text`; CLI transliteration; `BIB_MEMORY_CARD.chunk_size`; GW-14 bridge | ◐ (release of GW-14: Q-13) |
| FR-NEW-015 | `BIB_NOTE_STORE`, `BIB_DB_NOTE_STORE`, `BIB_MARKDOWN_NOTE_STORE` | ◐ (which store first: Q-11) |
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
| FR-060 (modified) | GUI on simple_widgets/simple_shaping; D-006 spike P0; GW-01..03 | ◐ (gated on GW items) |
| FR-061 | L-CLI | ✓ |
| FR-062 (modified) | `installer/simple_bible.iss` (P6), OFL fonts, no WebView2 | ✓ |
| FR-063 (modified) | Plug-in seam; rix.db public (D-019) | ✓ |
| FR-064 | No network code in R1 (simple_winhttp only in v3, off by default) | ✓ |
| FR-065 | No helper processes in R1; v3 spawns hidden via simple_process | ✓ |

### Non-functional

| Requirement | Addressed By | Status |
|-------------|--------------|--------|
| NFR-001 | Lookup worker (bounded lookups, p95 < 50 ms test), normalized/indexed tables, chapter as the load unit | ✓ |
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

## Risk Mitigations Implemented

| Risk | Mitigation in Design |
|------|---------------------|
| RISK-001 SQLite 3.31.1 | DDL and SQL limited to 3.31.1 features; SQLite version recorded in every method; FT-01 separate |
| RISK-002 FTS5 and marks | Normalizer family with idempotence; LG-01; normalized columns; trap-corpus tests |
| RISK-003 Licensing | License gate; Swete default; Rahlfs `ship = false`; fonts under the gate (A-020) |
| RISK-004 Wrong pairings | `BIB_MAPPED_REF` selective creation; regression suite with Swete legs |
| RISK-005 Re-contamination | Content-anchor checks in importers; quarantine rules as build steps |
| RISK-006 AI invents facts | No run-time AI in R1; `BIB_AI_TEXT` only via post-check |
| RISK-007 Weak embeddings | Related passages also from votes and rare lemmas, each with its reason |
| RISK-008 Harvested code broken | Copy-and-adapt per ledger row; harvest column in 04 |
| RISK-010 8 GB thrash | No model in R1; capability probe in v2 |
| RISK-011 Scope creep | Plug-in seam; public purity test |
| RISK-013 Share-alike | SA flags, separate tables, export notice |
| RISK-014 Bus factor | Spec Kit artifacts; reproducible build; README/docs rule |
| RISK-016 Omissions read as errors | `BIB_OMISSION` kinds with reason text |
| RISK-017 Gloss as meaning | Glosses are orientation fields; counts never key on gloss |
| RISK-018 GUI gap schedule | Engine + CLI first; panels staged by gap closure (A-011) |
| RISK-019 GC stall on sqlite | FT-02 + chunking + GC-probe test (A-005) |
| RISK-020 Swete OCR | `BIB_REPAIR_STATE`, quality caveat, OCR note on verdicts, hand-verified spans (A-001) |
| RISK-021 Lost or scrambled notes (13 T10) | Append-only history, soft delete, `BIB_USER_BACKUP`, hub-id keys (A-022) |
| RISK-022 Trust betrayals (13 T05, T18) | Migration preserves settings; per-text seal; count-scope labels; trust rules for ratification (A-023, A-025, A-029) |

## Open Issues (questions for Larry)

| ID | Question | Recommendation |
|----|----------|----------------|
| Q-01 | Release 1 scope: one list (GUI v1, including library content packs) or 1a (engine, core texts, reader, search, census/shapes, They Chose seed, journey, divine names, renderings, author library, notes/highlights/bookmarks/history) then 1b (commentaries, lexicons beyond Strong's, dictionaries, devotionals, prayer, memory, plans)? | 1a then 1b; the design is identical either way |
| Q-02 | FT-02: patch eiffel_sqlite_2025's externals in place, or a fleet-local fork? Do it together with the D-007 upgrade (FT-01)? | Patch in place with FT-01, one fleet regression |
| Q-03 | Fonts: ship SIL OFL fonts only (Ezra SIL; Gentium Plus or Noto for polytonic Greek), or verify and ship the SBL fonts? | OFL only unless SBL terms are verified |
| Q-04 | Ecclesiastes in the Swete slot: Brenton 1851 rows labeled, or "not in this digital edition"? (from 12) | Brenton, labeled |
| Q-05 | Update the harvest ledger: H-01..H-07, H-13, T-07 become ARCHIVE-ONLY; retirement criterion R-4 reads "native face" (D-006 overtook them) | Yes |
| Q-06 | Release 1 ships related-passage neighbors only, with the vectors arriving with v2 meaning search | Yes (smaller download) |
| Q-07 | T2 shapes that use Louw-Nida domains: take the domains from UBS SDGNT (CC BY-SA 4.0) or gate those shapes until the MARBLE permission question is settled? | UBS SDGNT |
| Q-08 | TUI face (ledger L-3): the design has none; confirm | None |
| Q-09 | Withdrawn author documents excluded from search by default with an "Include withdrawn" switch, always labeled (GUI open point 3) | Confirm |
| Q-10 | Primary first user (13 Q1): the lay reader who outgrew e-Sword, or the pastor who left BibleWorks? It sets the default screen and the Release 1a/1b order | Lay reader (13: trust themes come mostly from lay readers; the Simple layout is the default) |
| Q-11 | Notes: user.db (default) or Markdown files in a user folder (Obsidian-compatible) first? The design supports both behind `BIB_NOTE_STORE` (13 Q3) | Markdown folder as the store, user.db as its index, if Release 1 can carry it; otherwise user.db first |
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
2. FT-02 before the GUI phase (P5); the engine's chunking protects the CLI meanwhile.
3. The bge-m3 tokenizer check before the embedding precompute (P3).
4. Q-01, Q-07, Q-11 and Q-13 answered before /eiffel.tasks fixes the Release 1 task list.
