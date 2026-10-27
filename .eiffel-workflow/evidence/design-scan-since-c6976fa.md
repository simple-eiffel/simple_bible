# Design Scan (diff mode): simple_bible, since c6976fa

Change scanned: morphology search (B05). Read-only; nothing was compiled.

Subjects (changed since c6976fa, under src, cli, gui_app, build, build_app):
src/core/bib_morph_code.e, src/search/bib_query_parser.e, src/search/bib_verse_search.e,
src/concordance/bib_conc_pack.e, gui_app/bib_gui_app.e. Each was compared against src/, cli/,
gui_app/, build/ and build_app/. Limits of this scan: conc.db is not in the repository, so no
real morph column value was read; claims about stored codes are marked "unverified".

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Drift (D1) | 1 | 1 | 0 | 0 |
| Abstraction | 3 | 0 | 3 | 0 |
| Cleanup and tips | 3 | 0 | 0 | 3 |
| **Total** | **7** | **1** | **3** | **3** |

Findings are numbered 1 to 7; the table above groups them (1 drift; 2, 3, 4 abstraction/contract;
5, 6, 7 cleanup).

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_MORPH_CODE, BIB_QUERY_PARSER, BIB_CONC_PACK | scheme_of guesses the scheme from letter case and disagrees with the corpus it should come from |
| 2 | MEDIUM | A3/contracts | BIB_MORPH_CODE, BIB_CONC_PACK | The GLOB guard lives only in the parser; morph_places has no contract of its own |
| 3 | MEDIUM | A1/M2 | BIB_CONC_PACK, BIB_KEY | key_places is now a three-way type switch with a silent fall-through |
| 4 | MEDIUM | tests | BIB_CONC_PACK, BIB_VERSE_SEARCH | No test reaches the morph SQL path |
| 5 | LOW | A5 | BIB_QUERY_PARSER | A dummy instance is built only to call two predicates |
| 6 | LOW | tips | bib_gui_app | Tips and lookup_text comment omit what the single-capital rule does |
| 7 | LOW | contracts | BIB_CONC_PACK | places_where splices a condition string; trust is only in a comment |

## Detailed Findings

### Finding 1: scheme_of guesses the scheme, and guesses wrong for starred single capitals (D1)
**Priority:** HIGH
**Category:** D1 (drift between copies of one decision)
**Classes:** BIB_MORPH_CODE (src/core/bib_morph_code.e), BIB_QUERY_PARSER (src/search/bib_query_parser.e), BIB_CONC_PACK (src/concordance/bib_conc_pack.e)

**Description:** The decision "Hebrew or Greek" is now made in four places with four vocabularies:
1. `lemma_language` in the parser answers "hbo", "grc" or "any" from the script of the text
   (src/search/bib_query_parser.e:389-398, through BIB_SCRIPT_CLASSIFIER).
2. `key_places` re-tests the language literals "hbo", "arc", "grc" inline
   (src/concordance/bib_conc_pack.e:395, 397), although BIB_LANGUAGE_CODES.is_hebrew_script
   (src/core/bib_language_codes.e:18-21) already owns exactly that test.
3. `scheme_of` answers "oshb" or "robinson" from the letter case of the code
   (src/core/bib_morph_code.e:74-96).
4. `morph_places` maps the scheme string back to a corpus by one string compare
   (src/concordance/bib_conc_pack.e:421), and treats every scheme that is not "oshb" as Greek, so
   a code made with any other scheme (the class note at src/core/bib_morph_code.e:2 lists MACULA)
   silently searches the Greek corpus.

The corpus table already holds the answer: it has a `morph_scheme` column
(testing/conc_fixture.e:155), so the scheme of a corpus is data, and `scheme_of` re-derives from
letter case what the pack could read.

**Divergence (live defect):** the rule at src/core/bib_morph_code.e:89 sends "one letter and no
dash" to Hebrew. The starred form of a Greek part-of-speech letter has exactly one letter and no
dash: `morph:V*`, `morph:N*`, `morph:A*` (Robinson V-, N-, A- codes begin with those capitals
before the dash). `scheme_of ("V*")` counts one letter, finds no '-', and answers Oshb, so the
Greek reader who types `morph:V*` gets Hebrew verbs only, with no message. The same happens to a
Greek code typed in lowercase (`morph:v-aai-3s` holds a lowercase letter, so it is read as
Hebrew and finds nothing, because GLOB at src/concordance/bib_conc_pack.e:424 is case sensitive).
The tests lock in the rule rather than probing its edge: testing/test_search.e:43-44 asserts that
`morph:R` is Hebrew, and nothing tests `V*`.

**Evidence:**
- src/core/bib_morph_code.e:74-96 (scheme_of), line 89 (the one-capital rule).
- src/concordance/bib_conc_pack.e:395, 397, 421 (inline language literals and scheme compare).
- src/core/bib_language_codes.e:18-21 (is_hebrew_script, already exists).
- src/search/bib_query_parser.e:389-398 (a third script-detection helper).
- testing/test_search.e:43-44 (the single capital is asserted Hebrew, `V*` is not tested).
- testing/conc_fixture.e:155 (corpus.morph_scheme column exists).

**Suggested Action:** Let the key be honest about ambiguity: when the text cannot be told apart by
shape alone (one capital, with or without the star; any all-lowercase or mixed text outside the
Hebrew shapes), search BOTH corpora and union the places, setting has_hebrew and has_greek from
what was found (BIB_ROOT_PLACES.make already takes both flags). Then `scheme_of` shrinks to
"oshb", "robinson" or "either", and the pack picks corpora by the corpus's own morph_scheme
rather than by a string compare. Route the language literals at src/concordance/bib_conc_pack.e:395
and 397 through BIB_LANGUAGE_CODES while that block is open.
**Effort:** 2 features changed (scheme_of, morph_places), 1 inline test removed from the pack.

### Finding 2: the GLOB guard lives only in the parser
**Priority:** MEDIUM
**Category:** A4 (missing contract on shared behavior)
**Classes:** BIB_MORPH_CODE, BIB_CONC_PACK

**Description:** Reachability of GLOB metacharacters through the parser is closed: `is_code_text`
admits only ASCII letters, digits and dashes (src/core/bib_morph_code.e:68, the `< 128` test), at
least one letter (line 70), and one optional final star (lines 60-63), so `[`, `?`, `]` and an
inner `*` are refused (testing/test_search.e:67 tests `morph:V[A]*`). Non-ASCII and empty codes
are refused (empty by `l_last >= 1` at line 64, and by the `code_not_empty` precondition at
src/core/bib_morph_code.e:22). So via the query box GLOB is safe.

The guard is not in the type, though. `BIB_MORPH_CODE.make` requires only a non-empty code
(src/core/bib_morph_code.e:20-22), `key_places` has no precondition on a morph key, and
`morph_places` (src/concordance/bib_conc_pack.e:414-435) trusts a comment: "The parser lets only
letters, digits and dashes before the star" (line 423). Any other caller (a CLI command, a test, a
future import) that builds `BIB_MORPH_CODE.make ("oshb", "*")` matches every token of the corpus,
and `make ("oshb", "[a-z]*")` reaches GLOB as a pattern. Note also that `is_prefix` tests the
last character (src/core/bib_morph_code.e:42-46) while the matching rule "star only at the end"
is stated in a different class.

**Evidence:**
- src/core/bib_morph_code.e:18-30 (make: no is_code_text precondition).
- src/core/bib_morph_code.e:56-72 (is_code_text), line 68 (ASCII test).
- src/concordance/bib_conc_pack.e:414-430 (morph_places, GLOB at line 424, comment at line 423).
- src/search/bib_query_parser.e:170 (the only caller that checks).

**Suggested Action:** Give `morph_places` a precondition and BIB_MORPH_CODE a class-level rule so
the guarantee travels with the object: `make` requires a code that satisfies the code-text rule
(move `is_code_text` to a once-free class feature or a small deferred helper both classes see), and
`morph_places` requires `a_code.code` to pass it. The cost is one linear scan of a short string,
once per parsed clause; it is not on a hot path.
**Effort:** 2 contracts, 1 relocated predicate.

### Finding 3: key_places is growing into a type switch
**Priority:** MEDIUM
**Category:** A1/M2 (a decision that each key kind should answer for itself)
**Classes:** BIB_CONC_PACK, BIB_KEY, BIB_STRONGS_KEY, BIB_LEMMA_KEY, BIB_MORPH_CODE

**Description:** `key_places` now chooses its behavior by dynamic type: `attached {BIB_MORPH_CODE}`
at src/concordance/bib_conc_pack.e:381, then `attached {BIB_STRONGS_KEY}` at line 387 and
`attached {BIB_LEMMA_KEY}` at line 389. Three kinds is where a switch starts to be a smell, and
two more are named already (word id in the BIB_KEY note at src/core/bib_key.e:2; MACULA in
src/core/bib_morph_code.e:2). The chain has no final `else`: a key of a fourth kind falls through
with `l_entries` Void and `l_language` "any", and `key_places` answers success with an empty place
list (lines 384-405), which BIB_VERSE_SEARCH reads as "no verse matches"
(src/search/bib_verse_search.e:133-146), the exact failure mode design scan 48 named at line 139
of that file. The same chain-of-kinds appears a second time in the GUI
(`attached {BIB_LEMMA_KEY}` at gui_app/bib_gui_app.e:854) and a third as the kind `inspect` in
BIB_VERSE_SEARCH.

**Description of the proposal:** the Eiffel shape is for each key to answer "which corpus
conditions do you stand for", for example a deferred feature on BIB_KEY (or a small deferred mixin
beside it, for example BIB_ROOT_KEY inherited by the Strong's and lemma keys) that returns the
condition and argument, leaving the pack with one place query (`places_where`, line 1009) that it
already has. Layering matters here (testing/test_layering.e exists), so the key may answer plain
data (condition text, argument, language), not a pack call.

**Evidence:**
- src/concordance/bib_conc_pack.e:381-405 (the chain, no else).
- src/search/bib_verse_search.e:133-146 (success-empty read as no match).
- gui_app/bib_gui_app.e:854 (a second type test on keys).
- src/core/bib_key.e:21-26 (the one deferred feature a key has: kind_label).

**Suggested Action:** /eiffel.abstract targeting BIB_KEY with a deferred or mixin query feature;
at minimum add an `else` that returns make_failed so an unknown kind is loud.
**Effort:** 1 deferred feature, 3 effective, 1 branch removed from the pack.

### Finding 4: nothing tests the morph SQL path
**Priority:** MEDIUM
**Category:** tests (A4 adjacent)
**Classes:** BIB_CONC_PACK, BIB_VERSE_SEARCH

**Description:** The tests for B05 reach the parser only. A search of testing/ for `scheme_of`,
`morph_places`, `Oshb`, `is_code_text` and `BIB_MORPH_CODE` finds only testing/test_search.e:40-46.
`morph_places` (GLOB and equality branches), `places_where` with an argument, and the Morph arm of
BIB_VERSE_SEARCH (src/search/bib_verse_search.e:133) are not exercised, and the refactor also moved
`lemma_places` onto `places_where` (src/concordance/bib_conc_pack.e:1005). The snapshot option
`morph` (gui_app/bib_gui_app.e, the new elseif near line 315) is a picture, not an assertion.

**Evidence:** testing/test_search.e:39-46 and 66-67 (parser only); src/concordance/bib_conc_pack.e:414-435,
1009-1035 (untested SQL).

**Suggested Action:** one fixture test per branch (exact code, starred code, Hebrew corpus, Greek
corpus, a code that matches nothing, and the failure of Finding 1 for `V*`).
**Effort:** about 5 test features.

### Finding 5: a dummy instance carries two static predicates
**Priority:** LOW
**Category:** A6 (helper-object candidate)
**Classes:** BIB_QUERY_PARSER, BIB_MORPH_CODE

**Description:** The parser builds `BIB_MORPH_CODE.make (Robinson, "V")` only to ask
`is_code_text` and `scheme_of` (src/search/bib_query_parser.e:33 and 93-94, 170, 336). The same
pattern already exists for `strongs_check`
(src/search/bib_query_parser.e:32). Both predicates depend on no state of the instance, so a
contract (Finding 2) cannot call them without another dummy either.

**Suggested Action:** make them once-free class features usable by creation precondition, or move
them to a small shared parent both keys inherit.
**Effort:** 2 features moved.

### Finding 6: tips and comments omit the single-capital rule
**Priority:** LOW
**Category:** tips
**Classes:** bib_gui_app

**Description:** Checked against the parser: the C6 tip's examples (`morph:V-AAI-3S`, `morph:Vq*`,
gui_app/bib_gui_app.e:3245) and the P07.2 tip (line 3271) are accurate for what the parser accepts
(Greek `V-AAI-3S`, Hebrew `Vqp3ms`, star for a prefix), and the sentence "AND joins verses, not
words" matches the intersection of places in src/search/bib_verse_search.e:164-175. What they do
not say: codes are case sensitive (GLOB, src/concordance/bib_conc_pack.e:424, and equality at
line 426), and a starred single capital reads as Hebrew (Finding 1). The `lookup_text` header
comment (gui_app/bib_gui_app.e:838-841) was not updated: it lists strongs: and lemma: but not
that a morph: search returns Void (line 849-851).

**Suggested Action:** after Finding 1 is decided, add "capitals as written" to the P07.2 tip and
update the lookup_text header.
**Effort:** 2 strings, 1 comment.

### Finding 7: places_where trusts its condition
**Priority:** LOW
**Category:** A4
**Classes:** BIB_CONC_PACK

**Description:** `places_where` appends `a_condition` straight into the SQL
(src/concordance/bib_conc_pack.e:1023). Today both callers pass literals or integer lists (lines
424, 426, 1005), and the argument is bound as a parameter (the `<<corpus_id, al_argument>>` array),
so there is no injection path. But the safety is a comment ("SQL over the token `t'"), not a
contract, and the feature is the one place any later "key kind" will pass text into.

**Suggested Action:** a precondition that the condition holds no quote or semicolon, or constants
for the two conditions so only named conditions can be passed.
**Effort:** 1 precondition.

## Checked and found sound

- GLOB metacharacters: only a final star can reach GLOB from the query box (Finding 2 evidence).
- Non-ASCII input: refused at src/core/bib_morph_code.e:68. Empty input: refused at line 64.
  Pieces between dashes may be empty ("V--A", "-V"): accepted by is_code_text, harmless (match
  nothing), not worth a rule.
- Contract cost: `scheme_of`'s precondition (is_code_text) and `key_places`' `ascending_once`
  postcondition (src/concordance/bib_conc_pack.e:436, unchanged) are linear and run once per
  clause or per search, not per token. Contracts are not costly on a hot path. Unverified: whether
  `t.morph GLOB` can use an index (the conc.db schema is outside this repository); a starred
  single capital such as `V*` over the Hebrew corpus will return a very large place list, which
  a timing test (testing/test_conc_timing.e has none for morph) would measure.
- Duplication with BIB_MORPHOLOGY_NAMES (src/concordance/bib_morphology_names.e:21) and the
  interlinear's `morphology_text` (src/concordance/bib_conc_pack.e:773): none. They spell
  pos_tag, stem, tense and the other split columns out in English; the new code matches the raw
  `morph` column. The two are different columns, so no copy exists. The only overlap is the
  Hebrew-or-Greek decision, in Finding 1.
- Unverified: bib_key.e:19 gives the canonical Hebrew example "OSHB:HNcmsa", with a leading H,
  while the tips and tests teach `Vqp3ms` without it, and the Hebrew corpus constant is
  "WLC-MACULA" (src/concordance/bib_conc_pack.e:440), a MACULA corpus, not OSHB. Whether the
  stored `morph` values begin with the language letter, or are MACULA-shaped, was not checked
  against real data; if they do, every Hebrew `morph:` search finds nothing. Worth one query
  against conc.db before the feature is announced.

## Recommended Order

1. Finding 1 (live defect: `morph:V*` reads Hebrew; lowercase Greek finds nothing), together with
   the unverified question of the stored Hebrew code shape.
2. Finding 4 (tests that would have caught Finding 1 and the stored-shape question).
3. Finding 2 (contracts on make and morph_places).
4. Finding 3 (key answers its own condition; add the `else` now).
5. Findings 5, 6, 7 (cleanup, with Finding 6 after Finding 1 is decided).
