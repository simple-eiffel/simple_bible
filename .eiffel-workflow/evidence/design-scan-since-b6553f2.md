# Design Scan (diff mode): simple_bible since b6553f2
# Mode: read-only, nothing compiled. Subjects (git diff --name-only b6553f2..HEAD -- src cli gui_app build build_app):
#   gui_app/bib_gui_app.e, src/concordance/bib_conc_pack.e, src/reading/bib_text_reader.e,
#   src/search/bib_query.e, src/search/bib_query_node.e, src/search/bib_query_parser.e,
#   src/search/bib_verse_search.e, src/simple_bible.e
# Each subject was compared against src/, cli/, gui_app/, build/, build_app/ (testing/ read only to see who calls what).
# All paths are under D:\prod\simple_bible. Line numbers are the files as they stand at HEAD.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Drift / duplication (D1, A5) | 3 | 3 | 0 | 0 |
| Grammar and contracts | 4 | 0 | 4 | 0 |
| Design (CQS, lookup overlap, failure reporting) | 3 | 0 | 2 | 1 |
| Cosmetic / pills / UX | 5 | 0 | 0 | 5 |
| **Total** | **15** | **3** | **6** | **6** |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1/A5 | BIB_VERSE_SEARCH, BIB_CONC_PACK | `union` and `merged_places` are the same sorted merge, written twice (plus a third ascending check) |
| 2 | HIGH | D1 | BIB_CONC_PACK, BIB_TEXT_READER, BIB_PLACE_PACKING | Place arithmetic (1000000 / 1000) written as SQL text in three places; BIB_CONC_PACK does not inherit the packing at all |
| 3 | HIGH | D1 | BIB_TEXT_READER, gui_app | Two search paths: `verses_matching`/`matching_count` (old) beside `verse_places_matching`/`verses_at_places` (new) |
| 4 | MEDIUM | grammar | BIB_QUERY_PARSER, BIB_VERSE_SEARCH | `a NOT (NOT b)` passes the parser and fails in the evaluator with an unpositioned message |
| 5 | MEDIUM | grammar | BIB_QUERY_PARSER, BIB_VERSE_SEARCH | A word with no searchable letter (a lone `*`, `-`, `"..."`) silently empties every AND it sits in |
| 6 | MEDIUM | grammar | BIB_QUERY_PARSER, BIB_QUERY_NODE, BIB_VERSE_SEARCH | No nesting or length bound: parser, `check_negations`, `flatten_into`, `evaluated` all recurse by nesting depth |
| 7 | MEDIUM | CQS | BIB_CONC_PACK | `key_places` is a query that sets `last_places_were_hebrew` / `last_places_were_greek` |
| 8 | MEDIUM | contract cost | BIB_VERSE_SEARCH, BIB_CONC_PACK | O(n) `is_ascending` in invariant and in pre/postconditions of every set operation |
| 9 | MEDIUM | overlap | BIB_LOOKUP, BIB_QUERY_PARSER, gui_app | The lookup box and the parser both decide what `G5485` means, by different surrounding rules |
| 10 | LOW | failure reporting | BIB_CONC_PACK, BIB_VERSE_SEARCH | Root-word query failure reads as "no verse matches"; word path reports failure |
| 11 | LOW | pill | gui_app | C6 and P07.2 tips omit that AND/OR/NOT must be capitals and that NOT cannot stand alone |
| 12 | LOW | message | BIB_QUERY_PARSER | `()` is reported as "')' has no '(' before it" |
| 13 | LOW | UX | BIB_TEXT_READER, gui_app | Omitted-verse rows are counted and shown blank |
| 14 | LOW | perf | BIB_TEXT_READER | `verses_at_places` WHERE clause is arithmetic, not index-friendly |
| 15 | LOW | cleanup | BIB_VERSE_SEARCH, gui_app | AND intersects the first operand with itself; `l_found.is_success` false is silent |

## Detailed Findings

### Finding 1: union and merged_places are one sorted merge, written twice
**Priority:** HIGH (D1/A5, same body in two classes)
**Classes:** src/search/bib_verse_search.e, src/concordance/bib_conc_pack.e
**Description:** Both are a two-pointer merge of two ascending INTEGER_64 lists, dropping duplicates. The loop bodies are character for character the same apart from names. They have already drifted in contracts: `union` has `require ascending` and `ensure ascending` (bib_verse_search.e:181-204 region), `merged_places` has neither. A fix to one (for example, an equal-element case) will not reach the other. A third copy of the same law is the ascending-once postcondition of `key_places` (bib_conc_pack.e:396), which restates `BIB_VERSE_SEARCH.is_ascending` (bib_verse_search.e:105-115). BIB_VERSE_SEARCH also owns `intersection` (206-228) and `difference` (230-252): the whole set algebra over sorted place lists lives half in one class and half in another.
**Evidence:**
- BIB_VERSE_SEARCH.union: src/search/bib_verse_search.e:181-204 (loop 189-200)
- BIB_CONC_PACK.merged_places: src/concordance/bib_conc_pack.e:982-1001 (loop 987-999), called at bib_conc_pack.e:394
- BIB_VERSE_SEARCH.is_ascending: bib_verse_search.e:105-115; same law as bib_conc_pack.e:396
**Suggested Action:** A small effective class BIB_PLACE_LIST_ALGEBRA (name is a proposal) holding `is_ascending`, `union`, `intersection`, `difference`, with contracts, inherited side by side by BIB_VERSE_SEARCH and BIB_CONC_PACK (BIB_CONC_PACK already has many role parents, bib_conc_pack.e:17-37). Delete `merged_places`. The winner on contracts is `union` (it states ascending in and out). Alternative: one BIB_PLACE_SET value class that owns a sorted list and offers `or`/`and`/`minus`, which also removes the repeated `ARRAYED_LIST [INTEGER_64]` signature seen in `key_places`, `lemma_places`, `verse_places_matching`.
**Effort:** 4 features to move, 1 to delete.

### Finding 2: place arithmetic written in SQL beside BIB_PLACE_PACKING
**Priority:** HIGH (D1: the packing was already deduplicated once, design scan 47, and has now been re-split)
**Classes:** src/concordance/bib_conc_pack.e, src/reading/bib_text_reader.e, src/user/bib_place_packing.e, src/reading/bib_verse_key.e
**Description:** BIB_PLACE_PACKING owns `Book_unit` = 1_000_000, `Chapter_unit` = 1_000, `Place_span`, `Max_part` (bib_place_packing.e:46-49). Its header says the units "were written twice" and are now shared. Three SQL strings repeat the numbers as literals:
- bib_conc_pack.e:963: `wb.book_id * 1000000 + CAST(u.div1 AS INTEGER) * 1000 + CAST(u.div2 AS INTEGER)` and the `BETWEEN 1 AND 999` bounds (these are `Max_part`)
- bib_text_reader.e:214: `book_id * 1000000 + chapter * 1000 + verse IN (...)`
- bib_text_reader.e:467 (older `Search_sql`): `h.key %% 1000000000`, `/ 1000000`, `%% 1000000`, `/ 1000`, `%% 1000`
BIB_CONC_PACK does not inherit BIB_PLACE_PACKING at all (the inherit list is bib_conc_pack.e:17-37); its comment at line 358 says "packed by BIB_PLACE_PACKING" but only the number layout is shared, by convention. If the units ever change (a verse number of 1000 or more, as `Max_part` documents is not allowed today), the pack and the reader would silently disagree and BIB_VERSE_SEARCH would intersect places packed two ways. The reader's own comment at 468-469 says "the key arithmetic is BIB_PLACE_PACKING's units" but nothing enforces it.
**Suggested Action:** Give BIB_PLACE_PACKING one deferred-free helper, `place_sql (a_book, a_chapter, a_verse: READABLE_STRING_8): STRING_8`, that builds `a * Book_unit + b * Chapter_unit + c` from the constants, and `Max_part` bounds as `max_part_sql`. BIB_CONC_PACK inherits BIB_PLACE_PACKING side by side with its other parents; build `lemma_places` SQL and the reader's SQL from these. Add one test that decodes a pack place with `book_part`/`chapter_part`/`verse_part` against a known Strong's hit.
**Effort:** 3 SQL strings, 1 inherit clause, 2 helper features.

### Finding 3: two search paths in BIB_TEXT_READER
**Priority:** HIGH (D1: old path kept beside the new one)
**Classes:** src/reading/bib_text_reader.e, gui_app/bib_gui_app.e, testing/test_content_builder.e
**Description:** `verses_matching` (bib_text_reader.e:106-145) and `matching_count` (147-166) are the older single-path search; `verse_places_matching` (168-192) and `verses_at_places` (194-250) are the new one. The GUI no longer calls the old pair: a grep of src, cli, gui_app, build, build_app finds `verses_matching` and `matching_count` only at their definitions. The only callers left are testing/test_content_builder.e:78-88. So the tests exercise the path production does not use, and the path production uses (the Boolean path) is checked, in the files I read, only through test_search.e entries that do not name `verse_places_matching`, `verses_at_places` or `key_places`.
The two paths share `search_expression` (so the FTS expression agrees) but differ in what they do with a place the version lacks:
- old: inner join to `verse_text` (Search_sql, line 467) drops a hit whose `verse_text` row is absent
- new: `verses_at_places` turns an absent text into an "omitted verse" with empty text (bib_text_reader.e around 226-232) and the count (`verse_search.places.count`, gui_app/bib_gui_app.e:3023) still includes it
So a single word search can show N rows and a count of N with the old path, and N+k with blank rows on the new one.
**Evidence:**
- bib_text_reader.e:106 `verses_matching`, :147 `matching_count`, :168 `verse_places_matching`, :194 `verses_at_places`
- gui_app/bib_gui_app.e:3010-3024 uses only `bible.verse_search`
- testing/test_content_builder.e:78-88 uses only the old pair
**Suggested Action:** Choose one. Recommended: keep the new pair as the single path, re-point test_content_builder.e at `verse_search` (one word, a phrase, a prefix, the limit, the count), delete `verses_matching`/`matching_count`/`Search_sql`/`Count_sql` (also removes the `%%` arithmetic of Finding 2). Or, if the old pair is a public API of the library, make it a thin wrapper: `verses_matching` = `verses_at_places` over the first `a_limit` of `verse_places_matching`, `matching_count` = its `.count`. Either way there is then one path and the two cannot disagree.
**Effort:** 2 features to delete or wrap, 1 test file to re-point.

### Finding 4: nested NOT passes the parser, fails in the evaluator
**Priority:** MEDIUM
**Classes:** src/search/bib_query_parser.e, src/search/bib_verse_search.e
**Description:** The parser rejects `NOT NOT x` (bib_query_parser.e:260-261) and a NOT that stands alone or in an OR branch or in an AND made only of NOTs (`check_negations`, 286-304). But `check_negations` passes `a_stands_alone = (a_node.kind = Or_clause)` to the children of every non-AND node (line 301), including a NOT node. For `grace NOT (NOT law)` the tree is AND[grace, NOT[NOT[law]]]: the outer NOT is an AND child (allowed), its child NOT is checked with `a_stands_alone` = False and passes. In the evaluator the AND branch consumes the outer NOT clause and calls `evaluated` on the inner NOT clause (bib_verse_search.e:153-173, specifically 157-159), which reaches the `else` branch that sets the error "NOT needs something to take away from." (174-176). The user gets a message with no position, from the search rather than from the parser, for input the parser said was valid. The comment at bib_verse_search.e:175 ("the parser refuses it") is false for this input.
**Suggested Action:** In `check_negations`, treat a NOT's child as stand-alone-forbidden when it is itself a NOT (`a_stands_alone` = True for the child of a NOT), so the error is positioned at 1 like its siblings. Or make `evaluated` handle a bare NOT as complement-of-nothing and say so. Parser fix is one line (bib_query_parser.e:301). Add a test for `a NOT (NOT b)`.
**Effort:** 1 feature.

### Finding 5: a word with no searchable character silently empties the query
**Priority:** MEDIUM
**Classes:** src/search/bib_query_parser.e, src/reading/bib_text_reader.e, src/search/bib_verse_search.e
**Description:** The tokenizer accepts any run of non-space, non-paren, non-quote characters as a Word (bib_query_parser.e:129-165), so `*`, `-`, `'` or `,` are Word tokens; `"..."` is a Phrase (the empty-phrase test at line 121 only rejects spaces and quotes). `search_expression` returns empty "when no letter or digit is left" (bib_text_reader.e, doc at the head of `search_expression`), and `verse_places_matching` then returns an empty list, not Void (bib_text_reader.e:168-192, `l_expression.is_empty` leaves the initial `create Result.make (0)`). In an AND this makes the whole query empty without a message: `grace AND -` names no verse. For `grace NOT *` nothing is removed. A lone `*` gives "No verse in KJV matches", which reads as a real answer. Nothing crashes: `make_text` only requires non-empty text and these tokens are non-empty.
**Suggested Action:** In `read_tokens`, after the Word/Phrase is cut, fail with a positioned message ("This has no letter or number to search") when the text has no letter or digit (`is_alpha`/`is_digit` over the characters, apart from the `*` and quotes). Cheaper alternative: `BIB_VERSE_SEARCH` sets `error_message` when `verse_places_matching` returns an empty list because the expression was empty (the reader would need to say so; it is the CQS-free way to add `is_searchable (a_version, a_words)`).
**Effort:** 1 check in the tokenizer.

### Finding 6: no nesting depth or length bound
**Priority:** MEDIUM
**Classes:** src/search/bib_query_parser.e, src/search/bib_query_node.e, src/search/bib_verse_search.e
**Description:** The grammar recurses once per parenthesis (parsed_or, parsed_and, parsed_unary, parsed_primary, four frames per level, bib_query_parser.e:173-274); `check_negations` (286-304), `flatten_into` (bib_query_node.e:61-74), and `evaluated` (bib_verse_search.e:122-179) recurse by tree depth too. The search box has no length limit I could find in the files read, and `parsed` has only the precondition "not empty" (bib_query_parser.e:38). A pasted query of many thousand `(` is a stack overflow in a finalized application, which closes the program with no message (see the shared-list crash note in memory). Width is also unbounded: each Word clause is one FTS query (bib_verse_search.e:134-139), so a pasted paragraph of 500 words is 500 queries and 500 set intersections before the first row shows.
**Suggested Action:** Count depth in the parser (`depth` attribute; `fail (position, "Too many parentheses")` above, say, 32) and cap clause count (for example 64: `fail (..., "Too many terms")`) before building the tree. Add both limits to the `parsed` postcondition doc. Test with 10000 parentheses.
**Effort:** 2 checks and 2 constants.

### Finding 7: key_places is a query with side effects (CQS)
**Priority:** MEDIUM
**Classes:** src/concordance/bib_conc_pack.e, src/search/bib_verse_search.e
**Description:** `key_places` returns the place list and also assigns `last_places_were_hebrew` and `last_places_were_greek` (bib_conc_pack.e:357-396, assignments at 372-373, 389, 391-392). The caller reads the attributes right after (bib_verse_search.e:145-146 in the file: `has_hebrew_roots := has_hebrew_roots or pack.last_places_were_hebrew`). Every other `last_` flag in the pack's neighbors is set by a command. Calling `key_places` twice (for instance from a test, or from a future caller that only wants the list) changes state a previous caller depends on; the postcondition does not say so (bib_conc_pack.e:395-397). The same shape is in BIB_VERSE_SEARCH: `find` is a command (good), `has_hebrew_roots` / `has_greek_roots` are reset in it.
**Suggested Action:** Return a value: a small class BIB_ROOT_PLACES with `places`, `has_hebrew`, `has_greek` (created by `key_places`), or make `find_key_places (a_key)` a command and `last_key_places` / the two flags queries. The value class also gives Finding 1's list algebra a natural home. Run /eiffel.audit-cqs on BIB_CONC_PACK.
**Effort:** 1 feature changed, 1 small class, 1 caller.

### Finding 8: contract cost of the ascending check
**Priority:** MEDIUM (project rule: hot paths keep only cheap critical contracts)
**Classes:** src/search/bib_verse_search.e, src/concordance/bib_conc_pack.e
**Description:** `is_ascending` scans the whole list. It runs:
- in the class invariant `places_ascending` (bib_verse_search.e:254-255), which is checked on every call of an exported feature: `find`, `verses`, `has_failed`, `has_hebrew_roots`, `has_greek_roots`, `places`, `error_message`. The GUI makes about eight such calls per search (gui_app/bib_gui_app.e:3016-3024 plus `show_verse_count` 3037-3042), each scanning every place (a common word is about 30 thousand verses)
- in `union`, `intersection`, `difference`: preconditions on both operands and a postcondition on the result (3 scans each, bib_verse_search.e:181-252), once per operator node per query
- in `find`'s postcondition (line 76) and in `key_places`' postcondition (bib_conc_pack.e:396)
Finalized test builds keep these in; F_code lean builds drop them, so the cost shows up as slow tests, not slow release builds.
**Suggested Action:** Keep the cheap, order-1 clauses (`empty_on_failure`, `no_larger`), move the full scan to a single `check` inside `find` guarded by `without_contracts`-style test helper, or test it once in testing/ (a property test over random lists), and drop it from the invariant. If Finding 1 is done, put the scan into the shared ancestor once.
**Effort:** 5 contract clauses.

### Finding 9: the lookup box and the parser both decide what a Strong's number is
**Priority:** MEDIUM
**Classes:** cli/bib_lookup.e, src/search/bib_query_parser.e, src/core/bib_strongs_key.e, gui_app/bib_gui_app.e
**Description:** Both ask the same predicate, `BIB_STRONGS_KEY.is_strongs_text` (bib_strongs_key.e:55-67), so the bare forms `G5485`, `H1254a` agree: the parser makes a Token_strongs (bib_query_parser.e:161-162) and the lookup calls `add_strongs` (bib_lookup.e:146-147). Differences that matter:
- The lookup trims the whole box text (bib_lookup.e:140-141) and tests the whole text; the parser tests each token. `G5485 AND G1515` is a Boolean query to the parser but a headword search for the text "G5485 AND G1515" to the lookup (bib_lookup.e:148-150 `add_word`).
- `strongs:g5485` is upper-cased by the parser (bib_query_parser.e:145-148); the lookup sees the whole word `strongs:g5485` and searches headwords for it. `lemma:charis` the same.
- on_search runs both for every search (gui_app/bib_gui_app.e:791-806): the lookup first, then `find_verses`. For a Boolean query the headword list is therefore empty or wrong while the verse list is right, and the note "No dictionary headword matches; the verses the search names are listed below." (line 807) is shown. That is correct but only by accident of the empty-choices test.
- `choices_for` builds `create l_key.make_from_text ("H1")` just to call the predicate (bib_lookup.e:143); the parser does the same with `strongs_check` (bib_query_parser.e:29, 84). The predicate is a query that does not need an instance.
**Suggested Action:** Make `is_strongs_text` a class-level (once or `{BIB_STRONGS_KEY}` static) query, give BIB_LOOKUP a one-line `parsed_keys` that asks BIB_QUERY_PARSER for the parse and, when the query is valid and has operators or keyword prefixes, skips the headword search (the verses are the answer). That makes the parser the single place that says what the text means; the lookup keeps verse-reference and headword rules only.
**Effort:** 1 feature in BIB_LOOKUP, 1 static query.

### Finding 10: root-word failures read as "no match"
**Priority:** LOW
**Classes:** src/concordance/bib_conc_pack.e, src/search/bib_verse_search.e
**Description:** `lemma_places` returns an empty list "when there is no lemma, no such corpus, or the query fails" (bib_conc_pack.e:953-956, 957-979), and `key_places` takes a Void `headwords_for_*` result the same way (373-384). The word path reports a failed query (`Void` from `verse_places_matching` becomes "The verse index could not be searched.", bib_verse_search.e:136-138); the root path never sets `error_message` on failure, only when no concordance is attached. A broken conc.db (or a missing `NT-MACULA` corpus: `has_corpus` False) therefore shows "No verse in KJV matches", not a fault.
**Suggested Action:** Give `key_places` the same detachable result (Void on failure) or a failure flag, and set `error_message` in BIB_VERSE_SEARCH; say "The concordance has no corpus NT-MACULA" for the missing corpus.
**Effort:** 2 features.

### Finding 11: design-pill tips
**Priority:** LOW
**Classes:** gui_app/bib_gui_app.e
**Description:** C6 (line 3197) and P07.2 (line 3223) list AND, OR, NOT, parentheses, `strongs:H1254 or G5485`, `lemma:charis`. They are accurate about what works, but they leave out two things the parser enforces: the operators must be capitals (bib_query_parser.e:134-139; lowercase `and` is searched as a word) and NOT cannot stand alone (parser header lines 6-9, `check_negations` 286-304). The tip in C4 (line 3194, "Anything else is searched") is still right. P07.2's old wording ("every search word") is gone, which is correct. Nothing wrong; nothing misleading about the new syntax beyond the omissions. The Hebrew-verse-number and critical-text notes live only in the heading text (`show_verse_count`, 3027-3054), not in a pill.
**Suggested Action:** Add "capitals: AND OR NOT" and "NOT takes away: grace NOT law" to the C6 tip.
**Effort:** 1 string.

### Finding 12: `()` message
**Priority:** LOW
**Classes:** src/search/bib_query_parser.e
**Description:** For `()` the tokenizer yields open, close; `parsed_primary` for the open token calls `parsed_or`, whose first operand hits the Token_close case and fails with "This ')' has no '(' before it." (bib_query_parser.e:256-257), pointing at the close. Empty parentheses deserve "These parentheses are empty." Same for `grace AND ()`.
**Suggested Action:** In the Token_open branch check `tokens.i_th (index).kind = Token_close` before `parsed_or`.
**Effort:** 1 branch.

### Finding 13: omitted-verse rows
**Priority:** LOW
**Classes:** src/reading/bib_text_reader.e, gui_app/bib_gui_app.e
**Description:** A place the version lacks is returned as a verse with empty text (bib_text_reader.e:226-232 region of `verses_at_places`). That happens by design when a Greek or Hebrew root place has no verse in the version read (versification differences, which the heading warns about, gui_app/bib_gui_app.e:3029-3033). The count (3023) and the grid include those rows. The heading says "N match" while some rows are blank.
**Suggested Action:** Count only non-empty rows for the heading, or mark such rows ("(not in KJV)") in the grid. See Finding 3 for the old path's different behavior.
**Effort:** 1 feature.

### Finding 14: non-index-friendly WHERE in verses_at_places
**Priority:** LOW
**Classes:** src/reading/bib_text_reader.e
**Description:** `book_id * 1000000 + chapter * 1000 + verse IN (?, ...)` (bib_text_reader.e:214) cannot use an index on (version_code, book_id, chapter, verse); SQLite filters every row of the version (about 31 thousand) for each page of at most 500 places (`Max_places_per_read`, line 252 region). Safe from injection: every place is a bound parameter. If Finding 2 adds a `place_sql` helper, an indexed alternative is a row-value `IN` list over (book_id, chapter, verse).
**Effort:** 1 SQL string.

### Finding 15: small cleanups
**Priority:** LOW
**Classes:** src/search/bib_verse_search.e, gui_app/bib_gui_app.e
**Description:** (a) The AND branch seeds `Result := l_positives.first` and then intersects with every positive including the first (bib_verse_search.e:166-169), one wasted scan. (b) If `l_found.is_success` is False, `find_verses` leaves `verse_hits` empty but still shows the count (gui_app/bib_gui_app.e:3020-3024): count N, no rows, no message. (c) `has_hebrew_roots` is set even when the Hebrew clause is under a NOT (bib_verse_search.e:145-146), so the Hebrew-numbering note can show for a query whose result holds no Hebrew place; harmless but imprecise.
**Effort:** 3 one-line edits.

## Checks asked for, answered

- Grammar holes. Empty word after AND/OR, `NOT` last, `strongs:` empty, `lemma:` empty, unbalanced or reversed parentheses, `NOT NOT`: all fail with a positioned message and none reaches a precondition (`make_text` needs non-empty text, satisfied by every token; `make_operator` arity is guaranteed by `combined`). Open holes are Findings 4, 5, 6, 12. A lone `*` does not crash; it names nothing (Finding 5).
- SQL injection. `lemma_places` concatenates only `lemma_id` values rendered with `INTEGER_64.out` (bib_conc_pack.e:964-970); the corpus id is a bound parameter. `verses_at_places` binds every place. FTS text is bound (`Places_sql`, bib_text_reader.e:470). Injection-safe as written; the integer-only property is a convention, not a type, so it is worth one comment or a contract (`across a_lemmas as ic all ic > 0`).
- CQS: Finding 7. Contract cost: Finding 8.
- Two sorted merges: Finding 1. Two search paths: Finding 3. Packing arithmetic: Finding 2. Lookup versus parser on `G5485`: Finding 9.
- Pills: Finding 11.

## Recommended Order

1. Finding 3 (choose one search path), because Findings 2, 13 and 14 simplify once the old SQL is gone.
2. Finding 1 together with Finding 7 and Finding 8: one place-list class (effective, inherited side by side) with the set algebra, a value result for the root places, and the ascending scan kept once.
3. Finding 2 (one place-arithmetic source for the SQL text).
4. Findings 4, 5, 6 (parser: one-line fixes plus two bounds, each with a test).
5. Finding 9, then 10; the LOW findings last.
