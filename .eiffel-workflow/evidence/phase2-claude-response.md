# Phase 2: Review Response (debate cycle)
# STATUS: COMPLETE
# Date: 2026-10-26
# Method: separate-seat cycle (RED code-lite, BLUE, adjudicator); condition C3 (C2 with the executed-evidence proposal)

Sources: review/00 - Review Register.md, review/01 - Execution Record.md (E1-E6), review/02 - RED.md, review/03 - BLUE Defense.md, review/04 - VERDICT.md. Adjudicator runs A1 and A2 are recorded in the verdict. Provenance level for every item below: P1-raw (read or run this cycle).

### ISSUE 1.1: Basis vocabulary rejects every real row
- **LOCATION**: BIB_VERSE_WORD.make `basis_known`, invariant `none_means_no_lemma`
- **SEVERITY**: HIGH
- **RULING**: NARROWED (BLUE's form)   (seat: RED-1; BLUE: narrow)
- **DESCRIPTION**: The precondition accepts only tagged, aligned, xref and none. The stored `token.lemma_basis` values are `computed:spacy-lemma` (3,114,729) and `tagged:CATSS`, `tagged:Grauman-WH`, `tagged:MACULA-Greek`, `tagged:MACULA-Hebrew`; no `none`, `aligned` or `xref` token exists, and `lemma_id` is never NULL or 0. Every real row would violate the precondition. RED proposed a prefix match inside the precondition; BLUE narrowed this, because it would leak storage spelling into a value class.
- **EVIDENCE**: Execution record E6 (spike R2, `review/spikes/R2-conc-data-shape/shape.py`) reproduces RED's counts exactly: lemma_basis values listed above, zero tokens with lemma_id NULL or 0 (P1-raw, second reading). BLUE's raw read of `bib_verse_word.e:29-30` and spec 02-DOMAIN-MODEL.md:294, 05-CONTRACT-DESIGN.md:764 shows the contract matches the written vocabulary, which lacks `computed`.
- **REQUIRED FIX**: VERSE_WORD keeps a domain vocabulary; add `computed`: `basis_known: across <<"tagged","computed","aligned","xref","none">> as b some a_lemma_basis.same_string (b) end`. BIB_CONC_PACK maps stored `<kind>:<source>` to the kind (text before the colon). (R2: only `tagged:*`, `computed:*` exist)

### ISSUE 1.2: Empty surface and transliteration are legal for real rows
- **LOCATION**: BIB_VERSE_WORD.make `translit_not_empty`; BIB_PLACE_ROW.make
- **SEVERITY**: HIGH
- **RULING**: SUSTAINED; BLUE's narrowing of *surface* to English OVERRULED by A1   (seat: RED-1; BLUE: concede)
- **DESCRIPTION**: FR-152 asks for words in every corpus, including English BSB and KJV tokens. English lemmas (language `eng`, 19,838) all have an empty `translit`, and 6,435 tokens have an empty `surface`. Also `token.translit` does not exist in today's file (FR-155 and FR-162 are unbuilt). Empty surfaces are Hebrew originals, not English (A1), so the surface precondition cannot be limited to English.
- **EVIDENCE**: Execution record E6 (spike R2): eng 19,838 of 19,838 lemmas with empty translit, grc 0 of 15,725, hbo 0 of 8,656, arc 0 of 715; 6,435 tokens with empty or NULL surface; no `token.translit` column (P1-raw). Adjudicator run A1 (conc.db opened with `mode=ro`): the 6,435 empty-surface tokens are all `hbo`, corpus 1 (WLC-MACULA), `tagged:MACULA-Hebrew`; token language always equals lemma language (P1-raw). BLUE's raw read of `bib_verse_word.e:27-28` confirms the stub demands a non-empty `translit` for every corpus.
- **REQUIRED FIX**: Empty surfaces are Hebrew originals, not English. VERSE_WORD and PLACE_ROW take `a_language` (pin `language_set`, as BIB_WORD_ENTRY does); drop `surface_not_empty`; replace `translit_not_empty` in require and invariant with `translit_when_written: (is_original (language) and not surface.is_empty) implies not translit.is_empty`, `is_original` = hbo, arc or grc. `word_entry` returns Void for a non-original lemma (its creator requires hbo/arc/grc)

### ISSUE 1.3: Value-class creators do not pin their arguments (R-C8)
- **LOCATION**: BIB_PLACE_ROW.make (`bib_place_row.e:23-33`), BIB_ENGLISH_ROW.make, BIB_VERSE_WORD.make
- **SEVERITY**: MEDIUM
- **RULING**: SUSTAINED   (seat: RED-1; BLUE: concede)
- **DESCRIPTION**: `surface` and `translit` (and `headword` and `translit`) have the same type and are both non-empty, and the postconditions do not pin them. PLACE_ROW pins only id, reference and provenance; ENGLISH_ROW omits headword and translit; VERSE_WORD omits surface and translit. Swapped arguments pass.
- **EVIDENCE**: Raw read of the three creators by RED and BLUE (P1-raw); the register's claim R-C8 is scored DISPROVEN in the verdict (three creators omit surface, translit and headword pins). The creators are Phase 4 stubs and were not run (E5).
- **REQUIRED FIX**: Add `surface_set`, `translit_set` (PLACE_ROW, VERSE_WORD), `headword_set`, `translit_set` (ENGLISH_ROW), each `x.same_string_general (a_x)`; PLACE_ROW.make `context_absent: meaning = Void and stem = Void and bsb = Void and kjv = Void and step = Void`; `set_context` adds `meaning_set`, `stem_set` in the existing `(a = Void) = (x = Void)` form

### ISSUE 1.5: Word view creators leave the places, method and error unpinned
- **LOCATION**: BIB_WORD_VIEW.make_success / make_failure (`bib_word_view.e:117-118` holds the existing invariants)
- **SEVERITY**: MEDIUM
- **RULING**: NARROWED   (seat: RED-1; BLUE: narrow)
- **DESCRIPTION**: The postcondition omits `first_places = a_first_places` and `method`; the invariant lacks a places clause; `make_failure` pins no `error`. RED also charged that a failed view has an empty `facts_model`, so `is_fact_closed` is vacuously true. The vacuity charge is OVERRULED: zero facts on failure is the true claim, now stated. The lemma-to-rows tie is dropped, because PLACE_ROW has no `lemma_id`.
- **EVIDENCE**: Raw read of the creators and invariant (P1-raw, RED and BLUE); the verdict's raw read that PLACE_ROW carries token ids, not lemma ids. Claim R-C4 is PREFERRED (0.65): `provenance_set` on every creator, `facts_model` real on success; creators are stubs, unrun (E5).
- **REQUIRED FIX**: `places_set: first_places = a_first_places`, `method_set`, invariant `success_has_places: is_success = (first_places /= Void)`; `make_failure`: `error_set`, `empty_model: facts_model.is_empty`

### ISSUE 1.6: Section order queries are undefined
- **LOCATION**: BIB_WORD_VIEW.is_in_approved_order, is_known_section, section_name (`bib_word_view.e:70-91`)
- **SEVERITY**: MEDIUM
- **RULING**: SUSTAINED, contract's names   (seat: RED-1; BLUE: concede)
- **DESCRIPTION**: All three are stubs with no postcondition; `order_kept` and `approved_order` assert an undefined query (K1). The order of `present_names` is never tied to the research/14 section 3 order. RED's constant used `septuagint` and `further`; the contract's own names are `greek_ot` and `going_further`, which prevail.
- **EVIDENCE**: Raw read of `bib_word_view.e:70-91` and line 71 for the contract's names (P1-raw, BLUE). The oracle gotcha that `has` uses object identity for strings governs the `definition` clause.
- **REQUIRED FIX**: `approved_order: ARRAY [STRING_8] once Result := <<"heading","how_often","english","dictionaries","centuries","callout","every_place","greek_ot","going_further","notes">> end`; `is_known_section` ensure `definition: Result = across approved_order as n some n.same_string (a_name) end` (never `has`: object identity, oracle gotcha); `is_in_approved_order` ensure: `present_names` is a subsequence of `approved_order`

### ISSUE 1.7: No ordering contract on lists
- **LOCATION**: BIB_CONC_PACK lookups, K9 (`place_page`, `words`)
- **SEVERITY**: MEDIUM
- **RULING**: NARROWED   (seat: RED-1; BLUE: narrow)
- **DESCRIPTION**: No contract orders any list (NFR-006). `rows` uses `same_string_general`; case and diacritic handling is unstated. BLUE conceded the ordering postcondition; the normalization of `a_english` belongs to debate 01 (D-009), so it is a header pointer, not a new rule in this slice. K2 and K7 remain unmapped (static checks, none cited).
- **EVIDENCE**: Raw read of the pack's lookups (P1-raw, RED and BLUE). The spike R1 query orders by `t.token_id` (E3), consistent with the ascending contract.
- **REQUIRED FIX**: `place_page` ensure `ascending: across 1 |..| (Result.count - 1) as i all Result.item (i).token_id < Result.item (i + 1).token_id end`; `words` the same over `position`; normalization of `a_english` is a header pointer to debate 01 (D-009), not a new rule here

### ISSUE 2.1: Offset paging cost grows with depth
- **LOCATION**: BIB_CONC_PACK.place_page (claim R-C3)
- **SEVERITY**: MEDIUM
- **RULING**: NARROWED   (seat: RED-2; BLUE: narrow)
- **DESCRIPTION**: Offset paging stays within NFR-002 (2 seconds) warm, so R-C3 as worded holds, but cost grows linearly with depth. RED proposed a keyset method; BLUE narrowed it: a virtual grid jump has no previous token id, so `place_page` must stay for the first page and jumps, `no_place_after` is undefined, and the offset-only `page_size_right` formula must not be copied to the keyset query. Cold deep-page timing was never measured.
- **EVIDENCE**: Execution record E3, spike R1 (`review/spikes/R1-offset-vs-keyset/paging.py`, lemma 9380, 88,444 places, best of three, 200-row pages): offset 26.6, 64.4 and 121.5 milliseconds versus keyset 30.4, 0.4 and 0.5 milliseconds at rows 0, 44,000 and 88,200, identical rows (P1-raw). The cold first-screen figure is 2.8 seconds (debate 05b addendum, carried in as E4).
- **REQUIRED FIX**: Add `place_page_after (a_lemma_id; a_corpus_code; a_after_token_id: INTEGER_64; a_limit)`: require as `place_page` plus `a_after_token_id >= 0`; ensure `bounded`, `ascending`, `after_respected: across 1 |..| Result.count as i all Result.item (i).token_id > a_after_token_id end`, `fact_closure`. Drop `full_unless_last` (`no_place_after` undefined); never copy `page_size_right` to it. `place_page` stays for the first page and jumps

### ISSUE 2.3: The pack exports its SQL source set to three classes
- **LOCATION**: BIB_CONC_PACK `sources` export (`bib_conc_pack.e:122`), layering K10
- **SEVERITY**: MEDIUM
- **RULING**: SUSTAINED   (seat: RED-2; BLUE: concede)
- **DESCRIPTION**: The pack has no `english_rows` or `verse_words` feature; `sources` is exported to BIB_ENGLISH_INDEX, BIB_VERSE_WORDS and BIB_WORD_LOOKUP, so their Phase 4 bodies can only run SQL themselves. That contradicts the class description ("One class owns every SQL statement") and TEST_PACK_PURITY, which now scans `src/concordance`.
- **EVIDENCE**: Raw read of `bib_conc_pack.e:122` and the class header at line 3 (P1-raw, BLUE); TEST_PACK_PURITY 4 run, all PASS, reading `src/pack` and `src/concordance` (execution record E2).
- **REQUIRED FIX**: `english_rows` and `verse_words` move onto BIB_CONC_PACK; `sources` becomes `{NONE}`

### ISSUE 2.4: Concordance pack can be silently missing; pack bound is not enforced
- **LOCATION**: SIMPLE_BIBLE.open (`simple_bible.e:69`), pack_count (line 115), BIB_SOURCE_SET.attach `under_limit` (`bib_source_set.e:111`)
- **SEVERITY**: HIGH
- **RULING**: SUSTAINED; BLUE's clamp OVERRULED   (seat: RED-2; BLUE: concede)
- **DESCRIPTION**: `packs_attached: attached_count >= pack_count` is satisfied by generic packs alone; nothing says `conc` is attached when `conc_path` is set, or that its failure surfaces. `pack_count`'s postcondition promises a bound a folder scan cannot guarantee. `attach` `under_limit` is a precondition, so attach number 11 is a caller bug, not the FR-138 reported error. BLUE proposed clamping the scan; the adjudicator ruled that a clamp makes the overflow clause vacuous.
- **EVIDENCE**: Raw reads of `simple_bible.e:69`, line 115 and `bib_source_set.e:111` (P1-raw, RED and BLUE). Claim R-C6 DISPROVEN (met by generic packs alone); R-C7 UNSUPPORTED (limit 10 is real per issue 3.2, the scan bound is promised, not enforced).
- **REQUIRED FIX**: `Max_generic_packs: INTEGER = 9` (`Max_attached - 1`, conc slot always reserved). `pack_count` = packs *found*, unclamped (a clamp makes the overflow clause vacuous); drop `within_slots`. `open` ensure `too_many_packs: pack_count > Max_generic_packs implies last_error /= Void` and `conc_attached_or_reported: is_open and not config.conc_path.is_empty implies (conc_pack.is_available or conc_error /= Void)`. `attach` keeps `under_limit` as a caller guard; `open` checks the count first, so FR-138's report comes from `open`

### ISSUE 2.5: Edition swap is structurally sound but untested
- **LOCATION**: BIB_CONC_PACK alias and `edition_label` (claim R-C5)
- **SEVERITY**: INFO
- **RULING**: SUSTAINED   (seat: RED-2; BLUE: concede)
- **DESCRIPTION**: The pack uses the literal alias `conc`; filenames appear only in comments; `edition_label` is read from the pack. This holds structurally, but `test_edition_swap_needs_no_code` is skipped.
- **EVIDENCE**: Raw grep (P1-raw): the static half holds. `test_edition_swap_needs_no_code` SKIP (skeletal) in the test run (execution record E2).
- **REQUIRED FIX**: None now; run `test_edition_swap_needs_no_code` on the Phase 5 fixture.

### ISSUE 3.1: Database errors are not mapped to last_error
- **LOCATION**: BIB_SOURCE_SET.attach; `attach_read_only` in simple_sql_database.e:609-632
- **SEVERITY**: LOW
- **RULING**: SUSTAINED, raised   (seat: RED-3; BLUE: concede)
- **DESCRIPTION**: `attach_read_only` exists, uses a read-only URI, requires `is_open`, a valid schema name and `not_yet_attached`, and sets `has_error` on a missing file. Nothing maps `has_error` to `last_error`. FR-138 wants SQLite's own message, so the verdict raised BLUE's weaker form to the stated fix. Severity raised from INFO (RED) to LOW.
- **EVIDENCE**: simple_sql_database.e:609-632, raw read (P1-raw, RED).
- **REQUIRED FIX**: FR-138 wants SQLite's own message. `attach` ensure `error_mapped: (attached database as al_db and then al_db.has_error) implies last_error /= Void`

### ISSUE 3.2: SQLite attach limit and ECF overrides
- **LOCATION**: eiffel_sqlite_2025 Clib/sqlite3.c:14869 (`#define SQLITE_MAX_ATTACHED 10`)
- **SEVERITY**: INFO
- **RULING**: SUSTAINED   (seat: RED-3; BLUE: concede)
- **DESCRIPTION**: The limit of 10 with the main database uncounted is correct (claim R-C7's limit half). RED left an ECF override unchecked; the adjudicator checked it.
- **EVIDENCE**: RED's raw read of sqlite3.c:14869 and the version at line 470 (3.53.4) (P1-raw). Adjudicator grep this cycle: no `SQLITE_MAX_ATTACHED` override in any eiffel_sqlite_2025 ECF, makefile or header (P1-raw).
- **REQUIRED FIX**: None now. The limit is 10; the overflow policy stays FR-138 queue item 4 (RISK-023).

### ISSUE 3.3: Pack validity check reads the wrong database
- **LOCATION**: SIMPLE_SQL_SCHEMA `user_version` (simple_sql_schema.e:310-321); BIB_CONC_PACK.is_available (`bib_conc_pack.e:29-35`)
- **SEVERITY**: HIGH
- **RULING**: SUSTAINED; BLUE's pack-owned query OVERRULED (fleet rule)   (seat: RED-3; BLUE: concede)
- **DESCRIPTION**: The helper runs `PRAGMA user_version` unqualified, so it reads the main database, not the attached pack. conc.db reports `user_version` 0 today (FR-165's builder stamp is unbuilt). BIB_CONC_PACK has no `Expected_user_version` or required-tables check, so `is_available` (alias attached) never enforces FR-164. BLUE proposed a pack-owned query; the fleet rule requires the fix in simple_sql.
- **EVIDENCE**: simple_sql_schema.e:310-321 (P1-raw, RED); spike R2 `user_version` 0 (execution record E6). Adjudicator run A2: main `:memory:` stamped 7, conc.db attached read-only as `conc`: `PRAGMA user_version` returns 7, `PRAGMA conc.user_version` returns 0 (P1-raw).
- **REQUIRED FIX**: Fix in simple_sql: `SIMPLE_SQL_SCHEMA.user_version_of (a_schema: READABLE_STRING_8): INTEGER`, require `database.is_valid_schema_name (a_schema)`, runs `PRAGMA <schema>.user_version`; before/after test (A2's setup: main 7, attached 0). BIB_CONC_PACK: `Expected_user_version`, a `check_pack` command run once at attach (version plus required tables) that sets the attribute `is_pack_valid`; `is_available` ensure `definition: Result = (sources.is_attached_alias (Pack_alias) and is_pack_valid)`. No SQL inside the precondition every lookup evaluates
