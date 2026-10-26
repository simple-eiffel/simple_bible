# Design Scan (diff mode): simple_bible, changes since 839b689
# Date: 2026-10-26
# Subjects (12 files changed in src, testing): src/concordance/{bib_conc_pack, bib_english_index, bib_english_row, bib_place_row, bib_verse_word, bib_verse_words, bib_word_view}.e, src/data/bib_source_set.e, src/provenance/bib_sourced.e, src/simple_bible.e, testing/test_app.e, testing/test_concordance.e
# Compared against: all of src/ (read-only; nothing compiled, nothing edited)
# Intent source: .eiffel-workflow/review/04 - VERDICT.md (Phase 2 rulings 1.1, 1.2, 1.6, 2.3, 2.4, 3.3)

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / duplication | 6 | 1 | 3 | 2 |
| Contracts / invariants | 4 | 1 | 1 | 2 |
| Naming / comments | 2 | 0 | 0 | 2 |
| **Total** | **12** | **2** | **4** | **6** |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | D1 / A1 | The language vocabulary has no home; `is_original` is the fifth copy of the Hebrew/Aramaic/Greek test and sits in the wrong class (BIB_SOURCED) |
| 2 | HIGH | contract gap | BIB_CONC_PACK `is_pack_valid` has no class invariant, and `is_available` can go stale after detach and re-attach |
| 3 | MEDIUM | A1 | `language_known` precondition copied into BIB_VERSE_WORD and BIB_PLACE_ROW, a third variant in BIB_WORD_ENTRY |
| 4 | MEDIUM | A1 / A6 | (language, surface, translit) written-form cluster and its `translit_when_written` rule duplicated in BIB_VERSE_WORD and BIB_PLACE_ROW |
| 5 | MEDIUM | invariant cost | `order_kept` invariant iterates instance data (`present_names`) |
| 6 | MEDIUM | A4 | BIB_WORD_VIEW: `is_known_section`, `approved_position`, `is_in_approved_order` restate and re-search each other |
| 7 | LOW | A4 | Facade classes BIB_ENGLISH_INDEX / BIB_VERSE_WORDS and BIB_CONC_PACK carry identical postconditions |
| 8 | LOW | comments | SQL-ownership claim repeated four times and overstated |
| 9 | LOW | naming | `is_attached` / `is_available` vs BIB_DATA_SOURCE.is_available and BIB_SOURCE_SET.is_attached_alias |
| 10 | LOW | encapsulation | `approved_order` is a public once ARRAY (mutable shared state) |
| 11 | LOW | T1 | `Max_generic_packs = 9` hard-codes `Max_attached - 1` and is policed by an invariant |
| 12 | LOW | contract | Tautological postconditions (`is_original`, `is_known_section`, `is_available`) |

(Counting note: the summary table groups by theme; the findings table is the authoritative list of 12.)

## Detailed Findings

### Finding 1: `is_original` is the wrong home, and there is no language home at all
**Priority:** HIGH (D1: duplicated logic across classes)
**Answer to the question asked:** No, BIB_SOURCED is not the right home, and no shared language constant set exists in the code base. The `grep "hbo"` shows only bare literals, never a constant or shared query.
**Evidence (the same three-code test, hand-copied):**
- src/provenance/bib_sourced.e:24-31 `is_original` (new in this diff; body line 28, postcondition line 30 repeats it)
- src/text/bib_transliterator.e:36-39 `is_supported_language`, the same Boolean as `is_original`
- src/text/bib_normalizer_set.e:36 (contract line 44) `hbo` or `arc` script test, `grc` test
- src/hub/bib_version_info.e:51 and :139 `hbo` or `arc` for `is_right_to_left`
- src/concordance/bib_word_entry.e:26 `language_known` (hbo, arc, grc)
- src/core/bib_lemma_key.e:19 comment names ("hbo", "grc"), same vocabulary
- src/text/bib_hebrew_normalizer.e:20 and src/text/bib_greek_normalizer.e:23 each return the literal from `language_code`
**Why BIB_SOURCED is wrong:**
- BIB_SOURCED is the provenance mixin (RQ-02, fact closure). 26 other classes inherit it (BIB_FACT, BIB_HIT, BIB_QUOTATION, BIB_ALIGNMENT and so on). All of them gain a public `is_original (a_language)` that means nothing to them. Only BIB_VERSE_WORD and BIB_PLACE_ROW use it (src/concordance/bib_verse_word.e:31,69; src/concordance/bib_place_row.e:30,78).
- Language is a domain vocabulary, not provenance. The provenance cluster is the lowest layer and should not learn what Hebrew is.
- It landed there because both consumers already inherited BIB_SOURCED, which is a convenience reason, not a design reason.
**Suggested fix (a real second implementor exists: five or more users, so this is not a speculative seam):** one small EFFECTIVE mixin, stateless, inherited side by side, for example `BIB_LANGUAGE_CODES` in src/core or src/text. It owns the constants (hbo, arc, grc, eng) and the queries `is_original`, `is_known_language` (original or English), `is_hebrew_script` (hbo or arc, replacing bib_normalizer_set.e:36 and bib_version_info.e:51). BIB_VERSE_WORD, BIB_PLACE_ROW, BIB_WORD_ENTRY, BIB_TRANSLITERATOR, BIB_NORMALIZER_SET and BIB_VERSION_INFO inherit it next to their existing parents. Remove `is_original` from BIB_SOURCED and delete `is_supported_language`.
**Effort:** 1 new class (about 3 features), 6 inheriting classes, 1 removal.

### Finding 2: BIB_CONC_PACK validity flag has no invariant and can go stale
**Priority:** HIGH (missing contract, state that outlives its precondition)
**Evidence:**
- src/concordance/bib_conc_pack.e:39 `is_pack_valid` is a plain attribute; :43-50 `is_available = is_attached and is_pack_valid`.
- The rule `is_pack_valid implies is_attached` exists only as a postcondition of `check_pack` (line 83). The class has no `invariant` clause (verified by grep).
- `sources` is the shared BIB_SOURCE_SET. `detach` (src/data/bib_source_set.e:122-131) and `close` (:133-142) act on it without telling the pack reader. After detach, `is_attached` is False but `is_pack_valid` stays True; a later `attach` of a different file under alias "conc" makes `is_available` True with NO `check_pack` run. FR-164 (refuse a wrong `user_version`) is then bypassed. Test `test_pack_not_valid_until_checked` (testing/test_concordance.e) covers only the fresh state, not this sequence.
- Bodies are stubs today, so this is a contract-level defect now and a live one at Phase 4.
**Suggested fix:** record WHAT was validated, not just that something was: `validated_path: detachable STRING_32` set by `check_pack` (copy of the attached path), and define `is_available` as attached and the currently attached path for `Pack_alias` equal to `validated_path`. That survives detach and re-attach. Add the class invariant only if the pack becomes the sole owner of attach and detach of "conc". Add a test: detach, re-attach, `is_available` False until `check_pack`.
**Effort:** 1 attribute, 2 feature bodies, 1 test.

### Finding 3: `language_known` precondition copied three ways
**Priority:** MEDIUM (A1, same contract, different text)
**Evidence:**
- src/concordance/bib_verse_word.e:30 and src/concordance/bib_place_row.e:28: identical four-way `or` chain (eng, hbo, arc, grc).
- src/concordance/bib_word_entry.e:26: three-way chain (originals only). Headwords are never English, so the narrower rule is right, but it is a third hand-typed spelling.
- Adding a language (Latin appears in the src/hub/bib_version_info.e:72 comment) means editing at least six places.
**Suggested fix:** with the mixin from finding 1: `language_known: is_known_language (a_language)` in the first two, `language_original: is_original (a_language)` in BIB_WORD_ENTRY (which also makes its narrower intent visible). The attribute comments (bib_verse_word.e:50, bib_place_row.e:47) then point at the mixin.
**Effort:** 3 one-line changes after finding 1.

### Finding 4: Written-form cluster duplicated
**Priority:** MEDIUM (A1 plus A6, a real second implementor exists)
**Evidence:**
- src/concordance/bib_verse_word.e:30-31, 47-55, 69 and src/concordance/bib_place_row.e:28-30, 44-50, 78: both hold `language`, `surface`, `translit`; both state `translit_when_written` as a creation precondition and as a class invariant; both ensure `language_set`, `surface_set`, `translit_set` (this diff made them converge, which shows they are one concept).
- BIB_WORD_ENTRY (language, headword, translit) and BIB_ENGLISH_ROW (headword, translit) are cousins but with a different rule (translit required); do NOT force them in.
**Suggested fix:** deferred mixin `BIB_WRITTEN_FORM` (deferred `language`, `surface`, `translit`; invariant `translit_when_written`), inherited side by side with BIB_SOURCED and the language mixin by exactly the two rows. Two implementors today meets the fleet rule; if Larry wants a third first, record it and leave as is.
**Effort:** 1 class, 3 deferred features, 2 inheritors.

### Finding 5: `order_kept` is not an O(1) invariant
**Priority:** MEDIUM
**Evidence:** src/concordance/bib_word_view.e:158 `order_kept: is_success implies is_in_approved_order`. The Phase 4 definition (contract at :112-121) walks `present_names` (:152) and calls `approved_position` (a linear scan of ten strings) twice per element.
**Verdict on the ten-element question:** it counts against the fleet rule, and "it is only ten" is not a reason to let it through. The rule is about iterating over the object's data. Ten is the bound of `approved_order` (a constant), but the loop runs over `present_names` (instance data) and each step scans that constant, so one check costs up to about 10 x 2 x 10 string compares (roughly 200). Invariants run on entry and exit of every exported feature, so a client looping `section_name (i)` for 1 to 10 pays about 20 evaluations (about 4,000 compares). That is small and bounded (the word view is not a hot path), hence MEDIUM, not HIGH. The stronger argument is that the invariant is redundant: `present_names` is `feature {NONE}` and has no mutator, so order is fixed at creation. A creation-time guarantee belongs in the `ensure` of `make_success` (run once), not in an invariant that re-proves it on every call.
**Suggested fix:** move to `make_success` ensure (`sections_in_order: is_in_approved_order`); keep only O(1) clauses in the invariant. If an in-class guarantee is still wanted, store a Boolean at creation and invariant that.
**Effort:** 1 clause moved.

### Finding 6: BIB_WORD_VIEW restates and re-searches itself
**Priority:** MEDIUM (A4 plus duplicated search)
**Evidence (src/concordance/bib_word_view.e):**
- :75-83 `is_known_section`: body is `across approved_order as n some n.same_string (a_name) end`; postcondition `definition` is the same text, so it proves nothing.
- :85-103 `approved_position`: a hand-written loop doing the same search again; its postcondition `zero_when_unknown` (:100) is defined through `is_known_section`. Two implementations of one search, each used to check the other, so a shared misunderstanding passes both.
- :112-121 `is_in_approved_order` ensure is `Result implies (...)`, one direction only; `Result = False` is never constrained, so a Phase 4 body that always returns False satisfies it. The `subsequence` text is O(n) in a postcondition (acceptable there) but is a second copy of the order rule that the Phase 4 body will also contain.
**Suggested fix:** make ONE search authoritative. `approved_position` keeps the loop (or call `compare_objects` once on the once-array and use `index_of`; today the array uses identity comparison, hence the oracle-gotcha comment at :77). `is_known_section` becomes `Result := approved_position (a_name) > 0`. Add a helper `is_ordered (a_names: ITERABLE [STRING_8]): BOOLEAN` and make `is_in_approved_order` ensure `definition: Result = is_ordered (present_names)` (an equality, so both directions are checked).
**Effort:** 2 bodies, 1 helper, 2 postconditions.

### Finding 7: Contracts duplicated between facade and pack
**Priority:** LOW (A4)
**Evidence:**
- src/concordance/bib_english_index.e:30-36 and src/concordance/bib_conc_pack.e `english_rows` (about :171-182): same `method_recorded`, `every_row_for_word`, `fact_closure`.
- src/concordance/bib_verse_words.e:30-36 and bib_conc_pack.e `verse_words` (about :185-202): same `method_recorded`, `positions_valid`, `fact_closure`, and `ascending` (added to both in this diff).
- The facades are now one-line forwarders; `is_fact_closed` runs twice per call in DBC builds.
**Suggested fix:** pick one side. Keep the full contract on the pack (it owns the data) and on the facade keep only what the facade adds, or the reverse; do not edit them in pairs.
**Effort:** 2 postcondition blocks.

### Finding 8: SQL-ownership comment repeated and overstated
**Priority:** LOW
**Evidence:** src/concordance/bib_conc_pack.e:3-4 ("One class owns every SQL statement against the attached concordance pack"), :7-8 (new: `sources` is private, so no other class can run SQL, ruling 2.3), :172 "(the SQL of BIB_ENGLISH_INDEX)", :186 "(the SQL of BIB_VERSE_WORDS)".
- The claim holds only by convention. At least six other classes hold a BIB_SOURCE_SET (src/census/bib_census_engine.e:81, src/core/bib_book_catalog.e:106, src/hub/bib_morph_expander.e:40, src/hub/bib_verse_hub.e:128, src/jobs/bib_search_job.e:65, src/simple_bible.e), and `database` is exported from BIB_SOURCE_SET (src/data/bib_source_set.e:146, "engine-internal"). Making `sources` private in one class does not stop another from querying alias "conc".
- Lines 3-4 and 7-8 say one thing twice; :172 and :186 read as if the facades own SQL they only forward.
**Suggested fix:** state it once in the class note as a rule enforced by review ("only this class names alias `conc`"), and delete the two parentheticals. For real enforcement narrow BIB_SOURCE_SET.database to a selective export; that is a separate decision for Larry.
**Effort:** 3 comment edits.

### Finding 9: `is_attached` / `is_available` naming
**Priority:** LOW
**Evidence:** src/concordance/bib_conc_pack.e:32 `is_attached`, :43 `is_available`; src/data/bib_data_source.e:66 `is_available` means "file present"; src/data/bib_source_set.e:70 `is_attached_alias`.
- The split is justified: `check_pack` requires attached-but-not-yet-validated (line 74), so there is a real second consumer. Keep it.
- But `is_available` now means two different things in the library, and `is_attached` reads like the Eiffel `attached` keyword.
**Suggested fix:** keep `is_available` (twelve preconditions use it); rename `is_attached` to `is_alias_attached`, or add a comment pointing at BIB_SOURCE_SET.is_attached_alias.
**Effort:** 1 rename, 2 references.

### Finding 10: `approved_order` is mutable shared state
**Priority:** LOW
**Evidence:** src/concordance/bib_word_view.e:125-129 `approved_order: ARRAY [STRING_8]` in `feature -- Constants` (exported), a `once` returning a mutable array of mutable strings. Any client can call `put` and change the order for every view, and `is_known_section` changes with it. The ten names also appear a third time in the comment at :76, and `is_present` hard-codes "heading" and "every_place".
**Suggested fix:** move to `feature {NONE}` (the public face is `is_known_section` and `approved_position`), or return a copy; drop the comment copy of the list.
**Effort:** 1 export change.

### Finding 11: `Max_generic_packs` hard-codes a derived number
**Priority:** LOW (T1)
**Evidence:** src/simple_bible.e:364-368 `Max_generic_packs: INTEGER = 9`, policed by invariant :387 `conc_slot_reserved: Max_generic_packs = sources.Max_attached - 1`; src/data/bib_source_set.e:151 `Max_attached = 10`. The number is stored twice and a runtime invariant guards the copy.
**Suggested fix:** own the reserved slot where the limit lives: a `Max_generic_attached` in BIB_SOURCE_SET defined as `Max_attached - 1`; BIB_SIMPLE_BIBLE reads it; drop the invariant.
**Effort:** 1 feature, 1 invariant removed.

### Finding 12: Tautological postconditions
**Priority:** LOW (A4 hygiene)
**Evidence:** src/provenance/bib_sourced.e:29-31 (`definition` repeats the body); src/concordance/bib_word_view.e:79-81; src/concordance/bib_conc_pack.e:34-38 (`is_attached`) and :46-50 (`is_available`). Each equals its own body, so it can never fail and costs a second evaluation in DBC builds (timing-trumps-contracts).
**Suggested fix:** keep a postcondition only where it states something the body does not.
**Effort:** delete or rewrite 4 clauses.

## Checked and found fine (no finding)
- `is_attached` / `is_available` split itself: justified (second consumer is `check_pack`).
- BIB_PLACE_ROW `context_absent` and BIB_ENGLISH_ROW `headword_set` / `translit_set`: contract strengthening, no duplication.
- BIB_SOURCE_SET `error_mapped` on `attach`: sole copy.
- BIB_SIMPLE_BIBLE `conc_error` and its policy note: one statement; `conc_attached_or_reported` is consistent with it.
- New tests: `test_pack_not_valid_until_checked` is a real test; the two verse-word tests are skeletal and flagged as such by `run_skeletal`.
- Not verified (no compile allowed): `1 |..| (count - 1)` with count 0 in `is_in_approved_order` and BIB_VERSE_WORDS `ascending` (an interval whose upper bound is below lower minus one). The same pattern already exists in older postconditions (for example `place_page_after`), so it is not new, but a Phase 5 run with an empty list should confirm it.

## Recommended Order
1. Finding 2 (live defect shape; small).
2. Findings 1 then 3 (one mixin removes five copies and fixes the wrong home).
3. Findings 6 then 5 (same class; one authoritative search, then relocate the invariant).
4. Finding 4 (second implementor exists; Larry decides).
5. Findings 7-12 as cleanup in the next pass over these files.

## Status (2026-10-26, refactor/scan-25)

Fixed: HIGH 1 (BIB_LANGUAGE_CODES mixin; six users; is_original out of BIB_SOURCED), HIGH 2 (validated_path; is_available holds only while the checked file is still attached; skeletal test for Task 3, since attach is a Phase 4 stub), MEDIUM order_kept (moved to make_success: fleet rule, invariants O(1)). Open for Phase 4: the other MEDIUMs (word view search duplication and the one-directional subsequence ensure; the written-form cluster, which waits for a real need) and the LOWs.
