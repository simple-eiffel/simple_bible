# Phase 2 Verdict: concordance slice (2026-10-26)

*Fresh adjudicator (Opus 5.5). Read: register, execution record, spikes, RED, BLUE, approach.md; raw reads of cited source and spec. Pipeline log: adjudicator runs A1 and A2 (read-only Python, SQLite 3.50.4, scratchpad, output below); `find spikes -name EIFGENs` and the *.exe/*.obj/*.lib/*.dll search both empty, nothing deleted; no Eiffel compiled.*

**A1** (conc.db, `mode=ro`): the 6,435 empty-surface tokens are all `hbo`, corpus 1 (WLC-MACULA), `tagged:MACULA-Hebrew`; token language always equals lemma language (eng 3,114,729 `computed`; grc 899,160, hbo 468,362, arc 7,549 `tagged`).
**A2**: main `:memory:` stamped 7, conc.db attached read-only as `conc`: `PRAGMA user_version` -> 7, `PRAGMA conc.user_version` -> 0.

## 0. Declarations

| Item | Value |
|---|---|
| ROE | General Research ROE **v1.1, October 12, 2026**, read in full this cycle |
| Condition grade | **C3** without the proposal (RED and BLUE in separate contexts, one model family); **C2** with the *(proposal)* that executed evidence (E1-E6, A1-A2) counts as external confrontation; C1 only after Larry's gate |
| Declared interest | None in the subject. Same model family as the contracts' author (S6 in the register); seats shared weights |

## 1. Rulings

| RED | Ruling | Sev | Required fix |
|---|---|---|---|
| 1.1 | NARROWED (BLUE's form) | HIGH | VERSE_WORD keeps a domain vocabulary; add `computed`: `basis_known: across <<"tagged","computed","aligned","xref","none">> as b some a_lemma_basis.same_string (b) end`. BIB_CONC_PACK maps stored `<kind>:<source>` to the kind (text before the colon). (R2: only `tagged:*`, `computed:*` exist) |
| 1.2 | SUSTAINED; BLUE's narrowing of *surface* to English OVERRULED by A1 | HIGH | Empty surfaces are Hebrew originals, not English. VERSE_WORD and PLACE_ROW take `a_language` (pin `language_set`, as BIB_WORD_ENTRY does); drop `surface_not_empty`; replace `translit_not_empty` in require and invariant with `translit_when_written: (is_original (language) and not surface.is_empty) implies not translit.is_empty`, `is_original` = hbo, arc or grc. `word_entry` returns Void for a non-original lemma (its creator requires hbo/arc/grc) |
| 1.3 | SUSTAINED | MEDIUM | Add `surface_set`, `translit_set` (PLACE_ROW, VERSE_WORD), `headword_set`, `translit_set` (ENGLISH_ROW), each `x.same_string_general (a_x)`; PLACE_ROW.make `context_absent: meaning = Void and stem = Void and bsb = Void and kjv = Void and step = Void`; `set_context` adds `meaning_set`, `stem_set` in the existing `(a = Void) = (x = Void)` form |
| 1.5 | NARROWED | MEDIUM | `places_set: first_places = a_first_places`, `method_set`, invariant `success_has_places: is_success = (first_places /= Void)`; `make_failure`: `error_set`, `empty_model: facts_model.is_empty`. Vacuity charge OVERRULED: zero facts on failure is the true claim, now stated. Lemma-to-rows tie dropped (PLACE_ROW has no `lemma_id`, raw read) |
| 1.6 | SUSTAINED, contract's names | MEDIUM | `approved_order: ARRAY [STRING_8] once Result := <<"heading","how_often","english","dictionaries","centuries","callout","every_place","greek_ot","going_further","notes">> end`; `is_known_section` ensure `definition: Result = across approved_order as n some n.same_string (a_name) end` (never `has`: object identity, oracle gotcha); `is_in_approved_order` ensure: `present_names` is a subsequence of `approved_order` |
| 1.7 | NARROWED | MEDIUM | `place_page` ensure `ascending: across 1 \|..\| (Result.count - 1) as i all Result.item (i).token_id < Result.item (i + 1).token_id end`; `words` the same over `position`; normalization of `a_english` is a header pointer to debate 01 (D-009), not a new rule here |
| 2.1 | NARROWED | MEDIUM | Add `place_page_after (a_lemma_id; a_corpus_code; a_after_token_id: INTEGER_64; a_limit)`: require as `place_page` plus `a_after_token_id >= 0`; ensure `bounded`, `ascending`, `after_respected: across 1 \|..\| Result.count as i all Result.item (i).token_id > a_after_token_id end`, `fact_closure`. Drop `full_unless_last` (`no_place_after` undefined); never copy `page_size_right` to it. `place_page` stays for the first page and jumps |
| 2.3 | SUSTAINED | MEDIUM | `english_rows` and `verse_words` move onto BIB_CONC_PACK; `sources` becomes `{NONE}` |
| 2.4 | SUSTAINED; BLUE's clamp OVERRULED | HIGH | `Max_generic_packs: INTEGER = 9` (`Max_attached - 1`, conc slot always reserved). `pack_count` = packs *found*, unclamped (a clamp makes the overflow clause vacuous); drop `within_slots`. `open` ensure `too_many_packs: pack_count > Max_generic_packs implies last_error /= Void` and `conc_attached_or_reported: is_open and not config.conc_path.is_empty implies (conc_pack.is_available or conc_error /= Void)`. `attach` keeps `under_limit` as a caller guard; `open` checks the count first, so FR-138's report comes from `open` |
| 2.5 | SUSTAINED | INFO | None now; run `test_edition_swap_needs_no_code` on the Phase 5 fixture. |
| 3.1 | SUSTAINED, raised | LOW | FR-138 wants SQLite's own message. `attach` ensure `error_mapped: (attached database as al_db and then al_db.has_error) implies last_error /= Void` |
| 3.2 | SUSTAINED | INFO | No `SQLITE_MAX_ATTACHED` override in any eiffel_sqlite_2025 ECF, makefile or header (grep, this cycle); the limit is 10 |
| 3.3 | SUSTAINED; BLUE's pack-owned query OVERRULED (fleet rule) | HIGH | Fix in simple_sql: `SIMPLE_SQL_SCHEMA.user_version_of (a_schema: READABLE_STRING_8): INTEGER`, require `database.is_valid_schema_name (a_schema)`, runs `PRAGMA <schema>.user_version`; before/after test (A2's setup: main 7, attached 0). BIB_CONC_PACK: `Expected_user_version`, a `check_pack` command run once at attach (version plus required tables) that sets the attribute `is_pack_valid`; `is_available` ensure `definition: Result = (sources.is_attached_alias (Pack_alias) and is_pack_valid)`. No SQL inside the precondition every lookup evaluates |

## 2. Scored claims

| Claim | Confidence | Rootedness | Status | Basis |
|---|---|---|---|---|
| R-C1 | 0.85 | 0.75 | ESTABLISHED (as worded) | Every lookup requires it (raw); `test_pack_absent_until_attached` PASS; means "alias attached" until 3.3 |
| R-C2 | 0.85 | 0.85 | ESTABLISHED | Raw grep: Strong's only in `headwords_for_strongs`; the FR-153 static check is not yet built |
| R-C3 | 0.65 | 0.70 | PREFERRED | R1: worst list, deepest page 121.5 ms warm, identical rows; cold depth unmeasured; cost linear in depth |
| R-C4 | 0.65 | 0.70 | PREFERRED | `provenance_set` on every creator (raw); `facts_model` real on success; creators are stubs, unrun |
| R-C5 | 0.70 | 0.75 | PREFERRED | Static half holds (raw grep); swap test skipped |
| R-C6 | 0.05 | 0.30 | DISPROVEN | `packs_attached` is met by generic packs alone (simple_bible.e:69) |
| R-C7 | 0.35 | 0.55 | UNSUPPORTED | Limit 10 is real (3.2); the scan bound is promised, not enforced; overflow is a precondition failure |
| R-C8 | 0.05 | 0.35 | DISPROVEN | Three creators omit surface, translit, headword pins (raw) |

## 3. Deployment lines

| May rely on | Must not rely on |
|---|---|
| Offset paging meets NFR-002 warm at every depth of the largest list (R1) | Offset paging for sequential scroll of deep lists; use `place_page_after` |
| `lemma_id` as the only headword key | Any value contract as written before the 1.1, 1.2, 1.3 fixes: real rows break them |
| conc.db shape per R2 and A1 (as of 2026-10-26) | `is_available` meaning "valid pack" before the 3.3 fix |
| SQLite attach limit 10, main uncounted | `PRAGMA user_version` through simple_sql's helper on an attached pack |

## 4. Do not assume

| Statement | Reason |
|---|---|
| Original-language words always have a surface | A1: 6,435 Hebrew tokens are empty |
| conc.db opens under FR-164 today | `user_version` is 0 (R2, A2); FR-165's builder stamp must land first; no bypass constant (it would be an edition test) |
| `token.translit` exists | R2: no such column (FR-162 unbuilt) |
| Keyset can replace offset | A grid jump has no previous token id (BLUE) |
| Cold deep-page timing | Never measured; NFR-019's cold figure is first-screen only |
| Fact closure is exercised | All creators are Phase 4 stubs (E5) |

## 5. Escalations

None. Every fix is a contract edit, an additive feature, a simple_sql variant or a builder stamp: cheap to reverse. The overflow policy stays FR-138 queue item 4 (RISK-023); the contract above only forbids silence.

## 6. Overall assessment: PASS WITH CONDITIONS

| # | Condition (before Phase 4 bodies) | Deciding test or rule; overturn trigger |
|---|---|---|
| 1 | Apply the 13 rulings' fixes; `ec.sh check` and `ec.sh test` at 0 errors, 0 warnings | Phase 4 compile log; overturn: none |
| 2 | simple_sql `user_version_of` with its before/after test, pushed first; clients rebuilt `-clean` | simple_sql test fails on main-vs-attached; overturn: none (fleet rule) |
| 3 | conc builder stamps `user_version` (FR-165) before Phase 5 integration | A rebuilt conc.db reports `Expected_user_version` |
| 4 | Phase 5 fixture runs the five skipped concordance tests, the edition swap, and value creators over A1's empty-surface rows | Any precondition violation on real rows reopens 1.1 or 1.2 |
| 5 | Timing test (`without_contracts`): deepest offset page of lemma 9380 (LXX), cold | Under 125 ms cold: `place_page_after` may be dropped |

Counts: SUSTAINED 9, NARROWED 4, OVERRULED 0 (seat positions overruled inside rulings: BLUE on 1.2 surface, 2.4 clamp, 3.3 helper; RED on 1.5 vacuity). HIGH after ruling: 4 (1.1, 1.2, 2.4, 3.3).

## 7. Open items for Larry

| # | Item |
|---|---|
| 1 | *(proposal)* executed evidence counts as external confrontation: grade C2 with it, C3 without |
| 2 | Policy default ruled here, yours to overturn: a missing or refused conc.db leaves the Bible open with the concordance unavailable and the reason reported (`conc_error`), following FR-164's "refuses a pack"; the alternative is that `open` fails |
| 3 | Adopt this verdict and its five conditions |
