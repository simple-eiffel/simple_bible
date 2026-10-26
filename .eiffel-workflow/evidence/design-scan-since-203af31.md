# Design Scan (diff mode): simple_bible, changes since 203af31
# Date: 2026-10-26
# Subjects: src/concordance/bib_conc_pack.e (Task 5 queries and helpers), bib_word_entry.e, bib_place_row.e, bib_english_row.e, bib_verse_word.e (Task 4), src/bib_release.e, src/core/bib_strongs_key.e, testing/test_concordance.e, testing/conc_fixture.e, .eiffel-workflow/research/17-CONC-PACK-SCHEMA-v1.md
# Excluded: attach serials, BIB_SQLITE_REPORTING (scan 27)
# Compared against: all of src/ (consumers BIB_WORD_VIEW, BIB_WORD_LOOKUP, BIB_ENGLISH_INDEX, BIB_VERSE_WORDS, BIB_ENGINE_RESULT, BIB_LIST_RESULT, BIB_LANGUAGE_CODES)
# READ-ONLY: nothing compiled, nothing edited. Findings are proposals.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / duplication / drift | 5 | 3 | 1 | 1 |
| Contracts / correctness (SQL, postconditions, invariants) | 7 | 1 | 5 | 1 |
| Docs / tests agreement | 2 | 0 | 1 | 1 |
| **Total** | **14** | **4** | **7** | **3** |

## Direct answers to the questions asked

1. **`'translation:ENG-%%'`**: correct. In an Eiffel manifest string `%%` is one literal percent, so SQLite receives `k.kind LIKE 'translation:ENG-%'`. Confirmed by the same escape in `testing/test_concordance.e:101` (`LIKE 'computed:%%'`) which the fixture test passes against a real count. (The method record stores the Eiffel-decoded SQL, so the recorded text is also right.) The pattern itself has other problems, see M3.
2. **run_query inside the `across` loop (`headwords_for_strongs`, `src/concordance/bib_conc_pack.e:195`)**: not a defect today. `al_rows` (line 192) is a local binding to the SIMPLE_SQL_RESULT object; `run_query` assigns a NEW result to `last_rows` (simple_sql `query_sql_with`, simple_sql/src/simple_sql_database.e:362-384, returns a fresh eagerly-loaded result with its own `ARRAYED_LIST rows`), so the list being iterated is never replaced or mutated. It is safe by accident of the local binding, not by design. See H3 for the real cost (hidden queries, CQS).
3. **Is there a real second/third implementor of the row validation?** Yes, a fourth. See H1.
4. **Postconditions true on every path?** No. `place_page.page_size_right` and the `place_total` it calls fail on healthy-but-disagreeing data. See H2. `fact_closure` holds on every failure path (failure results carry an empty `facts_model`, and the `l_citations.is_empty` fallbacks keep `make_success`'s `cited` precondition true).
5. **Does research/17 + fixture agree with Task 5's SQL?** Columns all exist in the fixture (`token.search/translit/lemma_basis`, `work.name`, `unit.recension/div1/div2`, `work_book`). The research doc is silent on several things the SQL depends on. See M4.

## Findings

| # | Priority | Category | Subjects | Opportunity | Effort |
|---|----------|----------|----------|-------------|--------|
| 1 | HIGH | A5/M2 | bib_conc_pack.e, 4 value classes, bib_language_codes.e | Row validation written 4x (+ restated in requires AND invariants); answer-assembly template 3x | 3 mixin features + 1 template |
| 2 | HIGH | contracts | bib_conc_pack.e `place_total`, `place_page`; bib_word_view.e | A failed or missing count becomes a "fact" of 0 and breaks consumer/own contracts | 1 feature + 2 contracts |
| 3 | HIGH | CQS / D1 | bib_conc_pack.e `lemma_provenance`, `entry_from_row`, `word_entry`, `headwords_for_strongs` | Query-with-side-effect, N+1 SQL not in the method record | 1 SQL change, 3 bodies |
| 4 | HIGH | D1 | bib_conc_pack.e (word_entry / headwords / english_rows / place_result / verse_words) | Copies diverged: drop vs fail-whole vs Void; different checks per copy | policy + shared check |
| 5 | MEDIUM | contracts | bib_conc_pack.e provenance fallbacks, read_pack_facts | Silent substitution of the first corpus's license/caveat | 3 sites |
| 6 | MEDIUM | SQL | `verse_words` | versification ignored, no tiebreak, silent empty success | 1 query |
| 7 | MEDIUM | SQL | `english_rows` | LIKE not tied to the token's corpus; count(*) counts links; silent INNER JOIN drops | 1 query |
| 8 | MEDIUM | docs/SQL | research/17, fixture | Doc omits columns/format/indexes the SQL relies on | doc + fixture |
| 9 | MEDIUM | contracts | `place_page` postcondition, BIB_LIST_RESULT | SQL inside a postcondition; O(n^2) to O(n^3) clauses | 2 contracts |
| 10 | MEDIUM | invariants | 4 value classes | Invariants weaker than the creators' preconditions | 4 classes, ~10 clauses |
| 11 | MEDIUM | method record | `method`, all queries | rule_notes always empty; scope omits limit | helper + 6 call sites |
| 12 | LOW | A1/T1 | bib_conc_pack.e | "conc." spelled 7 times beside `Pack_alias`; lemma column list repeated; hard-coded ENG-BSB / LXX- in `has_layer` | cleanup |
| 13 | LOW | A1 | bib_english_index.e, bib_verse_words.e | Facades restate the pack's postconditions verbatim | merge contract |
| 14 | LOW | tests | testing/test_concordance.e, conc_fixture.e | Failure paths and the shapes the SQL guards against are untested | fixture variants |

## Detailed Findings

### Finding 1: Row validation written four times (and again in each creator)
**Priority:** HIGH. **Category:** A5 / M2 (duplicated cross-cutting rule), A1 (vocabulary).
**Evidence:**
- `src/concordance/bib_conc_pack.e:545` (`entry_from_row`): `l_id > 0 and is_original (l_language) and headword /= "" and translit /= ""` = BIB_WORD_ENTRY.make requires (`src/concordance/bib_word_entry.e:27-30`).
- `src/concordance/bib_conc_pack.e:301` (`english_rows`): translit non-empty, book_id > 0, lemma_id > 0 = BIB_ENGLISH_ROW.make requires (`src/concordance/bib_english_row.e:26-29`).
- `src/concordance/bib_conc_pack.e:572` (`place_result`): `token_id <= 0`, `is_concordance_language`, `(is_original and surface /= "") and translit = ""` = BIB_PLACE_ROW.make requires (`src/concordance/bib_place_row.e:29-32`) and invariant (`:101`).
- `src/concordance/bib_conc_pack.e:363-366` (`verse_words`): position, language, the same translit rule, `is_known_basis`, none/lemma coupling = BIB_VERSE_WORD.make requires (`src/concordance/bib_verse_word.e:31-35`) and invariant (`:76-78`).
- The expression `(is_original (L) and not surface.is_empty) implies not translit.is_empty` is written eight times: bib_place_row.e:32, :101; bib_verse_word.e:33, :77; bib_conc_pack.e:364, :572 (in negated form), plus the two creators' ensures.
- The basis vocabulary `<<"tagged", "computed", "aligned", "xref", "none">>` is written twice: `src/concordance/bib_verse_word.e:34` and `src/concordance/bib_conc_pack.e:620` (`is_known_basis`).
- The "loop rows `until l_bad /= Void`, make a Schema_mismatch failure or a success with citations, `method (...)` called 2-4 times" template is written three times: `english_rows` (296-319), `place_result` (566-585), `verse_words` (350-380); `headwords_for_strongs` (192-207) is a fourth variant.
**Description:** Each reader re-states its value class's creation rule so a bad row fails the answer instead of crashing the creator. That is the right behavior, but the rule now lives in two places per class and 8 places in all; a change to one (for example allowing English `translit`) will leave the others drifting.
**Suggested Action (multiple inheritance, side by side; Larry's rule):**
- Add to the stateless `src/core/bib_language_codes.e` (already inherited by all four value classes AND by the pack): `is_translit_complete (a_language: READABLE_STRING_8; a_surface, a_translit: READABLE_STRING_GENERAL): BOOLEAN` with the rule once. Use it in the creators' `require`, the invariants and the pack.
- New stateless deferred-free mixin `BIB_LEMMA_BASIS` (parent of BIB_VERSE_WORD and BIB_CONC_PACK, side by side with BIB_LANGUAGE_CODES): `is_known_basis (kind)`, `basis_kind (stored)`, and the none/lemma coupling `is_basis_consistent (kind, lemma_id)`. Moves `basis_kind` (607-615) and `is_known_basis` (617-621) out of the pack.
- Give each value class a pure `is_creatable (...)` query (or put the pack-side checks in the mixins above) so the pack asks the class "can you be built from this" and the class's `make` precondition is `is_creatable (...)`. One definition per class.
- Extract the assembly template into a helper held by the pack (`BIB_PACK_ANSWERS`): rows -> items via an agent returning `detachable G` plus a problem text, then success or `Schema_mismatch` failure. Removes ~60 lines from the pack.
**Effort:** 1 feature in BIB_LANGUAGE_CODES, 1 new 3-feature mixin, 4 `is_creatable`, 1 helper.

### Finding 2: `place_total` turns a failure or a missing count into a fact of 0
**Priority:** HIGH. **Category:** contracts / type-safety gap.
**Evidence:**
- `src/concordance/bib_conc_pack.e:219-227`: `l_total` starts at 0; a failed query (`last_rows = Void`) or a missing `lemma_corpus_count` row both fall through to `create Result.make (0, ...)`. The answer is a `BIB_FACT [INTEGER_64]` with provenance and no way to say "unknown". `BIB_FACT` has no failure channel (`src/provenance/bib_fact.e`).
- Consumer: `src/concordance/bib_word_view.e:30` requires `total_covers_page: a_first_places.count <= a_place_total.value`. A total of 0 beside a successful non-empty first page is a precondition violation (a crash, not an answer) the first time Task 6 (`BIB_WORD_LOOKUP.view`, `src/concordance/bib_word_lookup.e:34`, still a stub) composes them, whenever the builder's `lemma_corpus_count` is missing or stale for a lemma that has tokens, or the query fails.
- Own contract: `src/concordance/bib_conc_pack.e:250` `page_size_right: Result.is_success implies Result.count = (place_total (...).value - a_offset).max (0).min (a_limit)`. Same hole: it recomputes from the count table, not from the rows it just read, so data where the two sources disagree makes a correct page fail its postcondition. The fixture agrees today (`testing/conc_fixture.e:142` vs 251 tokens) and the test at `testing/test_concordance.e:105` checks that agreement, but conc.db data can drift (FR-162's counts are a copy of what the tokens say).
**Suggested Fix:** make the absence explicit. Either `place_total: detachable BIB_FACT [INTEGER_64]` (Void when the query failed or no count row exists, with the reason in a `last_*` -free way, see H3) or return a small `BIB_VALUE_RESULT` carrying a method and an error like BIB_LIST_RESULT. The word view then fails with `Schema_mismatch` when `page.count > total`, instead of crashing. Rewrite `page_size_right` as `Result.is_success implies Result.count <= a_limit` plus `(count < a_limit) implies (a_offset + count = total)` only when the total fact is present; or drop it from the postcondition and make the builder's count/token agreement a builder test (Task 0).
**Effort:** 1 feature, 2 contracts, 1 consumer precondition.

### Finding 3: `lemma_provenance` is a query that runs SQL; the headword answer hides N extra queries
**Priority:** HIGH. **Category:** CQS (Phase 4.5), D1 with the method record.
**Evidence:**
- `src/concordance/bib_conc_pack.e:526-534` `lemma_provenance` is a function that calls `run_query`, overwriting `last_rows` and `last_query_error` (`:663-667`). `entry_from_row` (`:536-550`) calls it, so a function named "entry from row" executes SQL. Every `word_entry` is two queries; `headwords_for_strongs` is 1 + N (one `lemma_provenance` per headword inside the `across`, `:195-200`).
- Loop safety: iteration is on the local `al_rows` (see answer 2 above), so the loop is correct today. The hazard: any future edit that reads `last_rows` after the loop (or iterates `last_rows` directly) sees the provenance query's result; and when the last provenance query FAILS, `last_rows` is Void and `last_query_error` is set while the answer being built is a success, so the `rows_xor_error` ensure (`:687`) of `run_query` holds only per call, not across the answer. A failed provenance query is swallowed (falls to `first_provenance`, line 529).
- NFR-006 (`method`): `headwords_for_strongs` records only `l_sql` (`:204`), but the provenance each entry carries depends on N hidden statements (`ORDER BY n DESC, corpus_id LIMIT 1`, `:530`). The method record cannot re-run the answer. `word_entry` records no method at all.
- SCOOP: no defect while one processor owns one SIMPLE_BIBLE (`src/data/bib_source_set.e` class note). The hidden `last_rows`/`last_query_error` register would be unsafe if a pack reader were ever shared; a query function that mutates the object also makes it unusable from a separate-call postcondition without a lock.
**Suggested Fix:** fold the provenance into the headword SQL and make `entry_from_row` pure:
`(SELECT c.corpus_id FROM conc.lemma_corpus_count c WHERE c.lemma_id = l.lemma_id ORDER BY c.n DESC, c.corpus_id LIMIT 1) AS top_corpus`. `entry_from_row` then reads `top_corpus` and calls `provenance_of_id`; `lemma_provenance` is deleted. Make `run_query` a function returning a result record (rows or error) instead of setting two attributes, so no helper can clobber another's state.
**Effort:** 1 SQL change in two queries, 3 bodies, 1 helper signature.

### Finding 4: Drift between the copies of "what do I do with a bad row"
**Priority:** HIGH (D1). **Category:** D1.
**Evidence (same class, same job, diverged):**
- `headwords_for_strongs` (`:196`): a row `entry_from_row` rejects is SILENTLY DROPPED; the method's count (`:204`) is `l_entries.count`, so the record hides the loss.
- `word_entry` (`:174-176`): the same rejection returns Void, indistinguishable from "unknown id" (doc at `:167` lumps them) and from a query failure.
- `english_rows` (`:301-302`), `place_result` (`:572-573`), `verse_words` (`:363-367`): the same kind of rejection FAILS THE WHOLE ANSWER with `Schema_mismatch`.
- Checks that exist in one copy and not the others: `verse_words` enforces strictly ascending positions (`:363`); `place_result` has no ordering check (SQL orders by `token_id`, unique, so it holds by construction); `english_rows` never checks `is_original` of the headword's language (it does not even select `l.language`) though BIB_WORD_ENTRY's creator requires it, so a rendering-to-English-lemma link would put a non-original headword behind a row `word_entry` would refuse; `place_result` accepts any reference text (see L: `reference_text` is `work + " " + div1 + ":" + div2`, never empty, so `reference_not_empty` at bib_place_row.e:31 is vacuous for NULL columns).
- Error text: the failure message names a token or lemma in three copies but not the SQL scope; the three messages are built differently (`:302`, `:367`, `:573`).
**Which copy wins:** fail-whole with a named row (`english_rows` / `place_result` / `verse_words`). A pack that violates its own schema must say so rather than shrink an answer. Apply to `headwords_for_strongs` (fail, or at minimum record the dropped count in the method's `rule_notes`) and give `word_entry` a failure channel (same design as Finding 2).
**Suggested Action:** resolve together with Finding 1 (one `is_creatable`-style check per class; one `Schema_mismatch` constructor with the row id and the feature name).
**Effort:** 5 call sites.

### Finding 5: Provenance silently falls back to the first corpus's license
**Priority:** MEDIUM. **Category:** contracts (NFR-007).
**Evidence:**
- `src/concordance/bib_conc_pack.e:506-514` `provenance_of_id`: an unlisted corpus id yields `first_provenance`; `:516-524` can even fabricate a provenance with license "unknown". `english_rows` (`:304`) takes the corpus id from data (`e.corpus_id`), so a link to an English token in an unlisted corpus is shown under the first corpus's license and caveat (in conc.db that is the Hebrew corpus: CC BY 4.0 for a row whose real class is a restricted Bible).
- `read_pack_facts` (`:428-435`) fills `corpus_ids`/`corpus_codes` for EVERY corpus row but fills `corpus_provenances` only when `corpus_id > 0` and `code /= ""`; `check_pack` (`:137-145`) then accepts the pack. A corpus with id 0 or an empty code is listed by `has_corpus` yet has no provenance, and `place_page` on it (`provenance_of (a_corpus_code)`, `:565`) quietly cites the first corpus.
**Suggested Fix:** `check_pack` refuses a corpus with id <= 0, empty code or duplicate code (Schema_mismatch). `provenance_of_id` gets a precondition `known: corpus_provenances.has (a_id)`; `english_rows` fails the answer on an unlisted `bible_id` (as for any bad row). Then `first_provenance` is needed only for the empty-citation fallbacks (`:202`, `:313`), and the "no corpus listed" branch (`:522`) is unreachable and can go.
**Effort:** 3 sites.

### Finding 6: `verse_words` ignores versification, has no tiebreak, and returns empty success for what it cannot answer
**Priority:** MEDIUM. **Category:** SQL correctness, NFR-006.
**Evidence:** `src/concordance/bib_conc_pack.e:347`.
- `a_ref` carries a versification system, but `u.div1 = ? AND u.div2 = ?` compares the reference's chapter/verse text directly. `corpus.versification` (`testing/conc_fixture.e:111`) is never read. For Psalms and other numbering differences (MT vs LXX vs KJV) a KJV ref returns the wrong verse's words as a success. The class note admits only the recension gap.
- `ORDER BY t.pos` has no tiebreak (NFR-006). `unit` is unique on `(corpus_id, work_id, recension, div1, div2, div3)` (`testing/conc_fixture.e:114`), and the query does not constrain `div3`; two units of one verse differing in `div3` repeat positions, and the strict-ascending check at `:363` then fails the whole verse with "breaks the pack's rules". Order by `t.pos, t.token_id` (or `u.div3, t.pos`) and decide what `div3` means.
- A book with no `work_book` row, or an LXX book kept only in recensions (`u.recension = ''`), answers `Result.is_success` with `count = 0`: a false fact "the verse has no words". The comment at `:332-333` records the recension gap but the contract cannot see it.
**Suggested Fix:** read `corpus.versification` once in `check_pack` (it is a corpus fact, like the code), compare with `a_ref`'s system, and map through BIB_MAPPED_REF/BIB_VERSIFICATION_MAP or refuse; add the tiebreak; return a failure with a named reason (or a flagged empty answer in `rule_notes`) when the book has no `work_book` row.
**Effort:** 1 query, 1 check_pack read, 1 contract.

### Finding 7: `english_rows` SQL: LIKE not tied to the token's corpus, links counted not tokens, silent INNER JOIN
**Priority:** MEDIUM. **Category:** SQL correctness.
**Evidence:** `src/concordance/bib_conc_pack.e:294`.
- `k.kind LIKE 'translation:ENG-%'` accepts ANY English translation link onto token `e`, regardless of `e.corpus_id`. A `translation:ENG-KJV` link onto a BSB token (a builder error) would be grouped under the BSB. `LIKE` is also case-insensitive for ASCII and cannot use an index. Tie the kind to the token's corpus: `JOIN conc.corpus ec ON ec.corpus_id = e.corpus_id AND ec.language = 'eng' AND k.kind = 'translation:' || ec.code`. That also drops the hard-coded `ENG-` family and any `LIKE` escape worry.
- `count(*) AS n` counts link rows. If two original tokens of the same lemma in one book align to one English token (or one token carries links of the same kind from several originals) the count exceeds the number of English places. The test comment (`testing/test_concordance.e:44`, skeleton) promises counts "that sum to the word's places". Decide the unit and use `count(DISTINCT e.token_id)` or `count(DISTINCT k.from_token)` accordingly, and state it in the method's rule notes.
- `JOIN conc.work_book wb` is an INNER join: originals in works without a `work_book` row vanish from the answer with no trace.
- `GROUP BY` returns `l.headword, l.translit` as bare columns; deterministic only because they depend on `o.lemma_id`. `ORDER BY e.corpus_id, n DESC, o.lemma_id, wb.book_id` is total (good, NFR-006).
- `a_english.to_string_32.as_lower`: ASCII/Unicode lowercase by Eiffel's tables vs `token.search` as the builder wrote it. The doc does not say how `token.search` is normalized (see Finding 8).
**Effort:** 1 query.

### Finding 8: research/17 and the fixture do not state what the SQL depends on
**Priority:** MEDIUM. **Category:** docs / agreement.
**Evidence:** `.eiffel-workflow/research/17-CONC-PACK-SCHEMA-v1.md` (whole file): no mention of `token.search`, `work.name`, `unit.recension`, `unit.div1/div2/div3`, `corpus.versification`, or any index. Columns the Task 5 SQL reads that the doc never names: `token.search` (`bib_conc_pack.e:294`), `work.name` (`:552`), `unit.recension`, `div1`, `div2` (`:347`, `:552`), `lemma.pron`/`n_tokens` (`:173`).
- `lemma_xref.value` format: `headwords_for_strongs` compares `x.value = a_key.text` (`:190`), and `BIB_STRONGS_KEY` canonical text is UNPADDED (`H1254`, `src/core/bib_strongs_key.e:92-99`). If conc.db stores padded values (`H0001`) the query finds nothing for a padded key and the unpadded one only by luck. The doc's fact table lists only the `scheme` values. The fixture uses unpadded values (`testing/conc_fixture.e:139`), so the test cannot notice a mismatch with the real file.
- Indexes: the fixture creates none and the doc names none. The queries need, for the cost claims of ruling 2.1 and NFR-019: `token(lemma_id, corpus_id, token_id)` (place_page, place_page_after keyset), `token(search)` and `link(to_token)` (english_rows; the `link` primary key `(from_token, to_token, kind)` does not serve `to_token`), `unit(work_id, div1, div2)` (verse_words), `lemma_xref(scheme, value)`. A missing index returns correct rows on the fixture and a full scan on conc.db.
- `token.search` for English is lowercase in the fixture (`:136`); the doc should say whether that is a builder guarantee.
**Suggested Fix:** add a "Columns the engine reads and what they hold" table to research/17 (search normalization, work.name is the display name, recension default '', div1/div2 are TEXT chapter/verse, xref value format, versification), and a "Required indexes" list that `check_pack` can verify with `sqlite_master`. Make the fixture create the same indexes.
**Effort:** doc + fixture + one `check_pack` clause.

### Finding 9: SQL inside a postcondition; O(n^2) clauses
**Priority:** MEDIUM (Larry's rule "timing trumps contracts", memory 2026-10-25). **Category:** contracts.
**Evidence:**
- `src/concordance/bib_conc_pack.e:250`: `page_size_right` calls `place_total` and so runs a SQL statement (and replaces `last_rows`) inside every `place_page` postcondition check. Finalized `-keep` test builds run it on every page.
- `ascending` (`:249`, `:274`, `src/concordance/bib_verse_words.e:76`) calls `Result.item (l_i)` twice per step; `BIB_LIST_RESULT.item`'s own ensure `model_agrees` (`src/provenance/bib_list_result.e:64`) rebuilds `items_model` with MML `&` per call (O(n^2) each), so a 200-row page costs on the order of 400 model rebuilds. `is_fact_closed` (`src/provenance/bib_engine_result.e:90-106`) builds `facts_model` the same way.
**Suggested Fix:** keep only the cheap clauses (`bounded`, `method_recorded`) on the hot path; move `ascending` and `page_size_right` into the tests (`without_contracts` budget per simple_testing 1.1.0); drop the SQL from the postcondition (see Finding 2).

### Finding 10: Value-class invariants weaker than their creators' preconditions
**Priority:** MEDIUM. **Category:** "Invariants Enforce Laws".
**Evidence (O(1) candidates):**
- `src/concordance/bib_english_row.e:62-64` invariant has `count_positive`, `translit_not_empty` only; `make` also requires `english_not_empty`, `bible_not_empty`, `id_positive`, `book_positive` (`:24-27`). Add all four.
- `src/concordance/bib_place_row.e:99-101`: add `language_known: is_concordance_language (language)`, `reference_not_empty: not reference_text.is_empty`.
- `src/concordance/bib_verse_word.e:75-78`: add `language_known`, `basis_known` (the vocabulary from Finding 1), and use the shared `is_translit_complete`.
- `src/concordance/bib_word_entry.e:60-64`: add `language_original: is_original (language)` (the creator requires `is_original`, `:28`).
- `BIB_CONC_PACK` has no invariant. O(1) candidates: `valid_has_serial: is_pack_valid implies validated_serial > 0`; `invalid_has_no_serial: not is_pack_valid implies validated_serial = 0`; `valid_has_no_error: is_pack_valid implies pack_error = Void`; `valid_names_edition: is_pack_valid implies not edition_label_cache.is_empty`; `valid_has_corpus: is_pack_valid implies not corpus_codes.is_empty`; `tables_agree: corpus_codes.count = corpus_ids.count and corpus_ids.count = corpus_code_of.count`; `register_exclusive: not (last_rows /= Void and last_query_error /= Void)` (initial state both Void is allowed, unlike `run_query`'s xor).
**Effort:** about 14 clauses in 5 classes. (Not candidates: anything touching `is_available`, which calls the source set; `is_fact_closed` is O(n) by design, C-019.)

### Finding 11: The method record omits the rules that shaped the answer
**Priority:** MEDIUM. **Category:** NFR-006.
**Evidence:** `src/concordance/bib_conc_pack.e:638` passes empty `versions` and empty `rule_notes` for every query. Rules that change the answer and are recorded nowhere: lowercase folding of the English word (`:295`; the scope at `:310-318` records the word as typed), `recension = ''` only (`:347`), counts from `lemma_corpus_count` not tokens (`:222`), the dropped entries (Finding 4), the provenance corpus choice (Finding 3). `place_page`'s scope line (`:245`) omits `a_limit`, so the record cannot re-run the page; `place_page_after` (`:270`) also omits it.
**Suggested Fix:** give `method` a `a_rule_notes: ITERABLE [READABLE_STRING_GENERAL]` argument (BIB_METHOD already has the slot, `src/provenance/bib_method.e:22`) and pass one sentence per rule; add the limit to the scope.
**Effort:** 1 helper signature, 6 call sites.

### Finding 12: Spelling drift inside the pack class
**Priority:** LOW. **Category:** T1 / A1.
**Evidence:**
- `conc.` is typed literally in seven SQL strings (`:173`, `:190`, `:223`, `:294`, `:347`, `:530`, `:552`) while `check_pack`/`read_pack_facts` build names from `Pack_alias` (`:428-439`). Changing the alias constant would silently break seven queries.
- The lemma column list `lemma_id, language, headword, translit, pron, n_tokens` is repeated in `:173` and `:190` (with and without the `l.` prefix) and read by `entry_from_row` (`:543-546`); one `Lemma_columns` constant avoids drift.
- `has_layer` (`:89-93`) states "never from an edition name (FR-158)" but tests the literal `"ENG-BSB"` and the `"LXX-"` prefix. Corpus codes are not edition labels, so this is defensible; the comment overstates it. Either read a `corpus.layer` column or reword the comment.
- `src/bib_release.e:15` `Engine_version: STRING = "0.1.0"`: no second copy of the version exists in `src/` (checked), so there is no drift today; `simple_bible.ecf` carries no version, so keeping the constant in step with releases is a manual step.

### Finding 13: The facades restate the pack's contracts
**Priority:** LOW. **Category:** A1.
**Evidence:** `src/concordance/bib_english_index.e:30-34` and `src/concordance/bib_verse_words.e:72-77` repeat the pack's ensure clauses (`method_recorded`, `every_row_for_word`, `positions_valid`, `ascending`, `fact_closure`) word for word over a one-line delegation (`Result := pack.english_rows (...)`). `BIB_WORD_LOOKUP` (`src/concordance/bib_word_lookup.e`) is still a stub. With Finding 9 applied, keep one copy (the pack's) and let the facades' postconditions state only what they add; or drop the facades if Task 6 gives them no further job.

### Finding 14: Test and fixture gaps
**Priority:** LOW. **Category:** tests.
**Evidence:** `testing/test_concordance.e:285-411`, `testing/conc_fixture.e:126-145`.
- No test reaches any failure path: a row that breaks BIB_PLACE_ROW's, BIB_VERSE_WORD's or BIB_ENGLISH_ROW's rules (`l_bad`, `Schema_mismatch`); a query SQLite refuses (`last_query_error`); a missing `lemma_corpus_count` row; a count that disagrees with the tokens (Finding 2).
- Shapes the SQL guards against are absent from the fixture: a second recension, a `div3`, two English Bibles (only `ENG-BSB`; the LIKE is exercised with one kind), a link kind `MT->LXX` that must NOT match, two links to one English token, a padded Strong's value, a lemma with a NULL translit, an unlisted corpus id, a NULL `work.name`, a Psalm-style versification mismatch.
- `place_page`'s `page_size_right` and `ascending` are only ever checked by their own postconditions (finalized, `-keep`); the test asserts counts 200/51 and keyset equality (`:355-367`), which is good.
- Skeleton tests still empty: `test_word_view_in_pilot_order`, `test_english_lookup_counts_per_bible`, `test_verse_lookup_every_corpus`, `test_word_view_lists_every_fact`, `test_edition_swap_needs_no_code` (Task 6 and later).
**Suggested Fix:** add two fixture variants through `build_variant`-style switches (a "broken rows" pack and a "drift" pack) and one test each per `l_bad` path.

## BIB_STRONGS_KEY (bodies reviewed, `src/core/bib_strongs_key.e`)
No defect found. Walked the cases against `is_strongs_text` (`:55-67`): "H1", "H0001", "H00001" accepted, "H000001" and "H123456" refused (digit run limit 5), "G0"/"H00" refused (`digits_value > 0`), "Ha"/"H" refused, "H1ab" and "H1A" refused, "H6743a" accepted with suffix kept. `digits_value`'s precondition `a_last <= 6` is protected by short-circuit order (`:63-65`, `and then`), which is worth a comment because reordering would make the precondition fail. `make_from_text`'s ensure `padding_insensitive` (`:32`) compares a value to the same call that produced it (vacuous); a stronger clause is `text.same_string_general (canonical_form (testament, number, sense_suffix))` (already `:34`) plus an explicit example in a test. The private ASCII helpers (`:132-142`) are justified because `CHARACTER_32.is_lower` is Unicode-aware; no other copy exists in `src/`. Open question is data, not code (Finding 8): the stored `lemma_xref.value` format.

## Not found (checked, clean)
- LIKE `%%` escaping (answer 1).
- Iteration over `last_rows` inside `across` (answer 2).
- `corpus_provenance` license flags (`:480`) and `edition_label` aliasing (`:161` uses `.twin`).
- `fact_closure` on failure and on the empty-citation fallbacks.
- Ordering determinism: `headwords_for_strongs` (`n_tokens DESC, lemma_id`), `place_page`/`place_page_after` (`token_id`, unique), `english_rows` (total order), `lemma_provenance` (`n DESC, corpus_id`). Only `verse_words` lacks a tiebreak (Finding 6).
- Joins are by key throughout (FR-024): `work_book` by `work_id`, no book-name joins.
- Unverified, worth one check when Task 6 lands: whether `READABLE_STRING_GENERAL.to_string_32` on a `STRING_32` copies or returns Current in the value creators (`bib_word_entry.e:35-37`, etc.); aliasing a row's strings into long-lived values would matter only if SIMPLE_SQL_ROW reuses buffers (not seen).

## Recommended Order
1. Finding 2 (place_total) before Task 6 builds BIB_WORD_LOOKUP on it; it decides the failure-channel shape that Findings 3 and 4 reuse.
2. Findings 3 and 4 together (pure `entry_from_row`, one bad-row policy), then Finding 1 (the shared checks and template) so the new policy is written once.
3. Finding 5 (provenance substitution), then Findings 6 and 7 (the SQL).
4. Finding 8 (doc and indexes) before conc.db is built into pack v1, since the builder is the other side of this contract.
5. Findings 9, 10, 11, then the LOW items.

## Status (2026-10-26, refactor/scan-28)

Fixed: HIGH 1 (is_translit_complete in BIB_LANGUAGE_CODES and the BIB_LEMMA_BASIS mixin: one rule, one vocabulary; the answer-assembly helper is not extracted, the three copies differ in their row types), HIGH 2 (place_total is Void when unreadable; page_size_right dropped as a data property; test failed before), HIGH 3 (top corpus folded into the headword SQL; entry_from_row pure; lemma_provenance gone), HIGH 4 (headwords_for_strongs and english_rows fail whole on a bad row; english_rows checks the headword language; test failed before). Open for Task 6: the word view must check total_covers_page before make_success and fail with Schema_mismatch. Open for Task 0 / research/17: columns, lemma_xref.value format, required indexes (MEDIUM 8). Other MEDIUMs and LOWs open.
