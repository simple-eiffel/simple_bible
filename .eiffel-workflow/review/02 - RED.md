# RED: Phase 2 contract review, concordance slice (2026-10-26)

Lens: contract-completeness first, then seams, then provenance. Bodies are Phase 4 stubs, so no lookup was run. **P1-raw** = read or run this cycle (read-only Python on the vault conc.db, `mode=ro`, SQLite 3.50.4, 2026-10-26). S6: I attacked before reading conc.db.

## RED-1 Contract completeness

| ID | Where | Sev | Finding and evidence | Fix |
|---|---|---|---|---|
| 1.1 | BIB_VERSE_WORD.make `basis_known`, invariant `none_means_no_lemma` | HIGH | conc.db `token.lemma_basis` holds `computed:spacy-lemma` (3,114,729), `tagged:CATSS`, `tagged:Grauman-WH`, `tagged:MACULA-Greek`, `tagged:MACULA-Hebrew`; no `none`, `aligned` or `xref` token exists, and `lemma_id` is never NULL or 0 (P1-raw run). Every real row would violate the precondition. | Take the basis kind as a prefix: `a_lemma_basis.starts_with ("tagged") or ... "computed"`; derive `none` from `lemma_id = 0`, and let the pack reader map. |
| 1.2 | BIB_VERSE_WORD.make `translit_not_empty`; BIB_PLACE_ROW.make | HIGH | FR-152 asks for words "in every corpus", including English BSB/KJV tokens. Their lemmas (language `eng`, 19,838 lemmas) have empty `translit`: all 3,114,729 joined English tokens, and 6,435 tokens have an empty `surface` (P1-raw). Also `token.translit` does not exist in today's file (0 columns, P1-raw): FR-155 and FR-162 are unbuilt. | Make translit a precondition only for `hbo`, `arc`, `grc` (pass the language); allow empty for English; `a_surface` non-empty only when the source has one. |
| 1.3 | R-C8: BIB_PLACE_ROW.make, BIB_ENGLISH_ROW.make, BIB_VERSE_WORD.make | MEDIUM | `surface` and `translit` (and `headword` and `translit`) are the same type and both non-empty, and the postconditions do not pin them: PLACE_ROW pins id, reference, provenance only; ENGLISH_ROW omits headword, translit; VERSE_WORD omits surface, translit. Swapped arguments pass. | Add `surface_set: surface.same_string_general (a_surface)`, `translit_set: ...`, `headword_set: ...` to each. In PLACE_ROW add `context_absent: meaning = Void and stem = Void and bsb = Void and kjv = Void and step = Void`. |
| 1.5 | BIB_WORD_VIEW.make_success / make_failure | MEDIUM | Postcondition omits `first_places = a_first_places`, `method`, and that the citations are kept; no precondition ties `a_entry.lemma_id` to the rows; invariant lacks `success_has_places`; `make_failure` pins no `error`. A failed view has an empty `facts_model`, so `is_fact_closed` is vacuously true (RQ-02 closure is non-vacuous only on success). | Add `places_set: first_places = a_first_places`, `method_set: method = a_method` (`error = a_error` for failure); invariant `is_success = (first_places /= Void)`; make_failure `empty_model: facts_model.is_empty`. |
| 1.6 | BIB_WORD_VIEW.is_in_approved_order, is_known_section, section_name | MEDIUM | All three are stubs with no postcondition; `order_kept` and `approved_order` assert an undefined query (K1). `present_names` order is never tied to the research/14 section 3 order. | Define `Approved_order: ARRAY [STRING_8]` (heading, how_often, english, dictionaries, centuries, callout, every_place, septuagint, further, notes) and `is_in_approved_order` as `present_names` being a subsequence of it, with `definition:` in the ensure. |
| 1.7 | BIB_CONC_PACK lookups, K9 | MEDIUM | No contract orders any list (NFR-006). `rows` uses `same_string_general`: case and diacritic handling unstated. | `place_page`: `ascending: across 1 |..| (Result.count - 1) as i all Result.item (i).token_id < Result.item (i + 1).token_id end`; define the normalization of `a_english`. |

## RED-2 Design and seams

| ID | Where | Sev | Finding | Fix |
|---|---|---|---|---|
| 2.1 | place_page (R-C3) | MEDIUM | Spike R1 (P1-raw, 01 - Execution Record E3, paging.py read by me): OFFSET 26.6, 64.4, 121.5 ms versus keyset 30.4, 0.4, 0.5 ms at rows 0, 44,000, 88,200, identical rows. K5 (first screen) and NFR-002 (2 s) still hold, so R-C3's compliance holds; "at every depth" costs grow linearly. | Add `place_page_after (a_lemma_id; a_corpus_code; a_after_token_id: INTEGER_64; a_limit: INTEGER)`: require `available`, `id_positive`, `corpus_known`, `a_after_token_id >= 0`, `limit_bounded`; ensure `bounded`, `ascending`, `after_respected: Result.count > 0 implies Result.item (1).token_id > a_after_token_id`, `full_unless_last: Result.is_success and Result.count < a_limit implies no_place_after (Result.item (Result.count).token_id)`. Keep `place_page` with a_offset = 0 for the first page and thumb jumps; the sequential grid scroll uses keyset. |
| 2.3 | BIB_CONC_PACK `sources` export vs layering (K10) | MEDIUM | Pack has no `english_rows` or `verse_words` feature; `sources` is exported to BIB_ENGLISH_INDEX, BIB_VERSE_WORDS and BIB_WORD_LOOKUP, so their Phase 4 bodies can only run SQL themselves. That contradicts the class description ("One class owns every SQL statement") and TEST_PACK_PURITY, which now scans src/concordance. | Add `english_rows` and `verse_words` to BIB_CONC_PACK, take the three-class export off `sources`, keep `sources` `{NONE}`. |
| 2.4 | R-C6/R-C7: SIMPLE_BIBLE.open, pack_count, BIB_SOURCE_SET.attach | HIGH | `packs_attached: attached_count >= pack_count` is satisfied by generic packs alone; nothing says `conc` is attached when `conc_path` is set, or that its failure surfaces. `pack_count`'s postcondition `Result + conc <= Max_attached` promises a bound a folder scan cannot guarantee. `attach` `under_limit` is a precondition: attach #11 is a caller bug, not the FR-138 reported error. | `open` ensure: `conc_attached: is_open and not config.conc_path.is_empty implies sources.is_attached_alias ({BIB_CONC_PACK}.Pack_alias)` and `overflow_reported: pack_count > Max_generic_packs implies last_error /= Void`. Add `Max_generic_packs = Max_attached - 1`. |
| 2.5 | R-C5 | INFO | Pack uses literal alias `conc`; filenames appear only in comments; `edition_label` read from the pack. Holds structurally, but the test (`test_edition_swap_needs_no_code`) is skipped, so untested. | None; run it in Phase 5 on a fixture. |

**K traceability.** Mapped: K1 (1.6, stub), K3 (1.2), K4 (2.5), K5, K6 (2.4), K8, K10 (2.3). **Unmapped:** K2, K7 (static checks only, none cited), K9 (1.7).

## RED-3 Provenance and dependencies

| ID | Claim | Sev | Check | Result |
|---|---|---|---|---|
| 3.1 | `attach_read_only` | INFO | simple_sql_database.e:609-632 (P1-raw) | Exists; read-only URI; requires `is_open`, valid schema name, `not_yet_attached`; `has_error` flag on a missing file. BIB_SOURCE_SET.attach says `last_error = Void implies ...` but nothing maps `has_error` to `last_error`: state it. |
| 3.2 | 10-slot limit (R-C7) | INFO | eiffel_sqlite_2025 Clib/sqlite3.c:14869 `#define SQLITE_MAX_ATTACHED 10`; line 470 version 3.53.4 (P1-raw) | Main uncounted is right; ECF override unchecked. |
| 3.3 | user_version check (FR-164/165) | HIGH | simple_sql_schema.e:310-321: `user_version` runs `PRAGMA user_version` unqualified (P1-raw). conc.db reports `user_version 0` (P1-raw run). | The helper reads the main database, not the attached pack. Use `PRAGMA conc.user_version`; BIB_CONC_PACK has no `Expected_user_version` or required-tables feature, so `is_available` (alias attached) never checks FR-164. Add `Expected_user_version`, `is_pack_valid`, and `is_available`'s definition `attached and is_pack_valid`. Until FR-165, the pack refuses itself. |

## Claims

| Claim | Position | Line |
|---|---|---|
| R-C1 | holds, narrowly | `is_available` is alias-only (3.3). |
| R-C2 | holds | `lemma_id` INTEGER_64 throughout; Strong's only in `headwords_for_strongs`. |
| R-C3 | contested | Compliant on time (spike), not efficient at depth; replace per 2.1. |
| R-C4 | contested | `is_fact_closed` is real but vacuous on failure (1.5). |
| R-C5 | holds (untested) | 2.5. |
| R-C6 | disproven | `open` does not state conc is attached (2.4). |
| R-C7 | contested | Limit true (3.2); no reserve, no reported overflow (2.4). |
| R-C8 | disproven | Three value classes do not pin surface, translit, headword (1.3). |
