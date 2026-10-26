# Phase 2 Synopsis: concordance slice (2026-10-26)

**STATUS: AWAITING LARRY'S GATE**

Source of truth: `.eiffel-workflow/review/04 - VERDICT.md` (fresh adjudicator, General Research ROE v1.1, October 12, 2026). Ruled findings: `.eiffel-workflow/evidence/phase2-claude-response.md`. Thirteen findings were raised: SUSTAINED 9, NARROWED 4, OVERRULED 0. After ruling: HIGH 4, MEDIUM 6, LOW 1, INFO 2.

## Critical findings (HIGH: must fix before implementation)

| ID | Finding | Required fix (verdict text) |
|---|---|---|
| 1.1 | BIB_VERSE_WORD basis vocabulary rejects every real row (stored values are `computed:*` and `tagged:*`). Narrowed to BLUE's form. | VERSE_WORD keeps a domain vocabulary; add `computed`: `basis_known: across <<"tagged","computed","aligned","xref","none">> as b some a_lemma_basis.same_string (b) end`. BIB_CONC_PACK maps stored `<kind>:<source>` to the kind (text before the colon). (R2: only `tagged:*`, `computed:*` exist) |
| 1.2 | Empty surfaces and empty transliterations are legal for real rows: 6,435 Hebrew tokens have no surface (adjudicator run A1); English lemmas have no transliteration. BLUE's narrowing of surface to English overruled. | Empty surfaces are Hebrew originals, not English. VERSE_WORD and PLACE_ROW take `a_language` (pin `language_set`, as BIB_WORD_ENTRY does); drop `surface_not_empty`; replace `translit_not_empty` in require and invariant with `translit_when_written: (is_original (language) and not surface.is_empty) implies not translit.is_empty`, `is_original` = hbo, arc or grc. `word_entry` returns Void for a non-original lemma (its creator requires hbo/arc/grc) |
| 2.4 | `packs_attached` is met by generic packs alone, so a missing concordance pack is silent; the pack-count bound is promised, not enforced. BLUE's clamp overruled. | `Max_generic_packs: INTEGER = 9` (`Max_attached - 1`, conc slot always reserved). `pack_count` = packs *found*, unclamped (a clamp makes the overflow clause vacuous); drop `within_slots`. `open` ensure `too_many_packs: pack_count > Max_generic_packs implies last_error /= Void` and `conc_attached_or_reported: is_open and not config.conc_path.is_empty implies (conc_pack.is_available or conc_error /= Void)`. `attach` keeps `under_limit` as a caller guard; `open` checks the count first, so FR-138's report comes from `open` |
| 3.3 | The user-version helper reads the main database, not the attached pack (adjudicator run A2: main 7, attached 0), and `is_available` never checks FR-164. BLUE's pack-owned query overruled (fleet rule). | Fix in simple_sql: `SIMPLE_SQL_SCHEMA.user_version_of (a_schema: READABLE_STRING_8): INTEGER`, require `database.is_valid_schema_name (a_schema)`, runs `PRAGMA <schema>.user_version`; before/after test (A2's setup: main 7, attached 0). BIB_CONC_PACK: `Expected_user_version`, a `check_pack` command run once at attach (version plus required tables) that sets the attribute `is_pack_valid`; `is_available` ensure `definition: Result = (sources.is_attached_alias (Pack_alias) and is_pack_valid)`. No SQL inside the precondition every lookup evaluates |

## Important findings (MEDIUM: fix during implementation)

| ID | Ruling | Finding | Required fix (verdict text) |
|---|---|---|---|
| 1.3 | SUSTAINED | Value-class creators do not pin surface, transliteration or headword; swapped arguments pass (claim R-C8 disproven). | Add `surface_set`, `translit_set` (PLACE_ROW, VERSE_WORD), `headword_set`, `translit_set` (ENGLISH_ROW), each `x.same_string_general (a_x)`; PLACE_ROW.make `context_absent: meaning = Void and stem = Void and bsb = Void and kjv = Void and step = Void`; `set_context` adds `meaning_set`, `stem_set` in the existing `(a = Void) = (x = Void)` form |
| 1.5 | NARROWED | BIB_WORD_VIEW creators leave places, method and error unpinned. The vacuity charge is overruled: zero facts on failure is the true claim, now stated. | `places_set: first_places = a_first_places`, `method_set`, invariant `success_has_places: is_success = (first_places /= Void)`; `make_failure`: `error_set`, `empty_model: facts_model.is_empty` |
| 1.6 | SUSTAINED, contract's names | Section-order queries are undefined stubs. | `approved_order: ARRAY [STRING_8] once Result := <<"heading","how_often","english","dictionaries","centuries","callout","every_place","greek_ot","going_further","notes">> end`; `is_known_section` ensure `definition: Result = across approved_order as n some n.same_string (a_name) end` (never `has`: object identity, oracle gotcha); `is_in_approved_order` ensure: `present_names` is a subsequence of `approved_order` |
| 1.7 | NARROWED | No contract orders any list. | `place_page` ensure `ascending: across 1 \|..\| (Result.count - 1) as i all Result.item (i).token_id < Result.item (i + 1).token_id end`; `words` the same over `position`; normalization of `a_english` is a header pointer to debate 01 (D-009), not a new rule here |
| 2.1 | NARROWED | Offset paging cost grows with depth (spike R1: 26.6, 64.4, 121.5 milliseconds versus keyset 30.4, 0.4, 0.5). | Add `place_page_after (a_lemma_id; a_corpus_code; a_after_token_id: INTEGER_64; a_limit)`: require as `place_page` plus `a_after_token_id >= 0`; ensure `bounded`, `ascending`, `after_respected: across 1 \|..\| Result.count as i all Result.item (i).token_id > a_after_token_id end`, `fact_closure`. Drop `full_unless_last` (`no_place_after` undefined); never copy `page_size_right` to it. `place_page` stays for the first page and jumps |
| 2.3 | SUSTAINED | The pack exports `sources` to three classes, so their bodies must run SQL themselves, against the one-class-owns-SQL rule. | `english_rows` and `verse_words` move onto BIB_CONC_PACK; `sources` becomes `{NONE}` |

## Minor findings (LOW and INFO)

| ID | Severity | Ruling | Finding | Required fix (verdict text) |
|---|---|---|---|---|
| 3.1 | LOW | SUSTAINED, raised | Database errors are not mapped to `last_error`; FR-138 wants SQLite's own message. | `attach` ensure `error_mapped: (attached database as al_db and then al_db.has_error) implies last_error /= Void` |
| 2.5 | INFO | SUSTAINED | Edition swap holds structurally but its test is skipped. | None now; run `test_edition_swap_needs_no_code` on the Phase 5 fixture. |
| 3.2 | INFO | SUSTAINED | SQLite attach limit is 10 with main uncounted; no `SQLITE_MAX_ATTACHED` override in any eiffel_sqlite_2025 ECF, makefile or header (adjudicator grep). | No change; the limit is 10. |

## Recommended actions before Phase 3 (the verdict's five conditions, in order)

| # | Condition | Deciding test or rule; overturn trigger |
|---|---|---|
| 1 | Apply the 13 rulings' fixes; `ec.sh check` and `ec.sh test` at 0 errors, 0 warnings | Phase 4 compile log; overturn: none |
| 2 | simple_sql `user_version_of` with its before/after test, pushed first; clients rebuilt `-clean` | simple_sql test fails on main-vs-attached; overturn: none (fleet rule) |
| 3 | conc builder stamps `user_version` (FR-165) before Phase 5 integration | A rebuilt conc.db reports `Expected_user_version` |
| 4 | Phase 5 fixture runs the five skipped concordance tests, the edition swap, and value creators over A1's empty-surface rows | Any precondition violation on real rows reopens 1.1 or 1.2 |
| 5 | Timing test (`without_contracts`): deepest offset page of lemma 9380 (LXX), cold | Under 125 milliseconds cold: `place_page_after` may be dropped |

## Overall assessment

**PASS WITH CONDITIONS.** Condition grade C3 without the proposal (RED and BLUE in separate contexts, one model family); C2 with the proposal that executed evidence (E1-E6, A1-A2) counts as external confrontation; C1 only after Larry's gate. Claims scored: R-C1, R-C2 established; R-C3, R-C4, R-C5 preferred; R-C6 and R-C8 disproven; R-C7 unsupported.

## Escalations

None. Every fix is a contract edit, an additive feature, a simple_sql variant or a builder stamp: cheap to reverse. The overflow policy stays FR-138 queue item 4 (RISK-023); the contract only forbids silence.

## Do not assume

| Statement | Reason |
|---|---|
| Original-language words always have a surface | A1: 6,435 Hebrew tokens are empty |
| conc.db opens under FR-164 today | `user_version` is 0 (R2, A2); FR-165's builder stamp must land first; no bypass constant (it would be an edition test) |
| `token.translit` exists | R2: no such column (FR-162 unbuilt) |
| Keyset can replace offset | A grid jump has no previous token id (BLUE) |
| Cold deep-page timing | Never measured; NFR-019's cold figure is first-screen only |
| Fact closure is exercised | All creators are Phase 4 stubs (E5) |

## Open items for Larry

| # | Item |
|---|---|
| 1 | *(proposal)* executed evidence counts as external confrontation: grade C2 with it, C3 without |
| 2 | Policy default ruled here, yours to overturn: a missing or refused conc.db leaves the Bible open with the concordance unavailable and the reason reported (`conc_error`), following FR-164's "refuses a pack"; the alternative is that `open` fails |
| 3 | Adopt this verdict and its five conditions |
