# Design Scan (diff mode): simple_bible, since fbf9d85

Subjects (changed under src, cli, gui_app, build, build_app since fbf9d85):

- gui_app/bib_gui_app.e
- src/concordance/bib_conc_pack.e
- src/core/bib_form_key.e (new)
- src/search/bib_query_clause.e
- src/search/bib_query_parser.e
- src/search/bib_verse_search.e

Each subject was compared against the whole of src/, cli/, gui_app/, build/ and build_app/. Read-only; nothing was compiled. All paths are relative to the repository root.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 4 |
| MEDIUM | 4 |
| LOW | 3 |
| **Total** | **11** |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_CONC_PACK | The morphology equals-or-GLOB condition is written twice (morph_places, lemma_places) |
| 2 | HIGH | D1 | BIB_QUERY_PARSER | Three readers of a root: the tokenizer's strongs:/lemma:/bare branches, form_root, and the grammar's Token_lemma branch |
| 3 | HIGH | D1 | BIB_GUI_APP, BIB_SEARCH_SCOPES | Scope names live in two lists, and a mismatch silently becomes "Whole Bible" |
| 4 | HIGH | A4 | BIB_FORM_KEY, BIB_CONC_PACK | A form's code is not checked where it is built, yet it reaches a GLOB pattern |
| 5 | MEDIUM | A1/M2 | BIB_CONC_PACK, BIB_FORM_KEY, BIB_CONCORDANCE | The type switch in key_places grew to four branches, with a second switch in root_places and four copies of "is a root" |
| 6 | MEDIUM | A5 | BIB_GUI_APP | search_scope rebuilds its scope on every call (twice per search, plus the parse) when the query already holds it |
| 7 | MEDIUM | A1 | BIB_QUERY_CLAUSE, BIB_VERSE_SEARCH, BIB_QUERY_PARSER, BIB_GUI_APP | "Which kinds are key clauses" is a hand-written list in five places; lookup_text adds a sixth rule |
| 8 | MEDIUM | A4 | BIB_CONC_PACK | The ascending-once postcondition (a full scan) now runs twice for every root and form search |
| 9 | LOW | D1 | BIB_QUERY_PARSER | The "@" branch is tested before the morph:, strongs: and lemma: branches |
| 10 | LOW | T1 | BIB_GUI_APP | Heading wording: "1 matches" and the order of the scope note |
| 11 | LOW | A2 | BIB_QUERY_CLAUSE | Form = 10 must stay the last kind for the invariant to hold |

## Detailed Findings

### Finding 1: the form condition is written twice (D1)
**Priority:** HIGH. **Category:** D1 (drift between copies).
**Classes:** BIB_CONC_PACK (src/concordance/bib_conc_pack.e).
**Description:** Both features decide "a code ending in * is a GLOB prefix, any other code is equality", then bind the code as a parameter. The two copies are in different shapes (one builds `l_condition` and passes it to both corpora; the other inlines three SQL strings), so a later fix to one (letter case, an escape, a new scheme) will not reach the other. This is the same logic that the previous scan (48/49) already consolidated for plain morphology. Today the copies agree; they will drift.
**Evidence:**
- src/concordance/bib_conc_pack.e:438-443 (morph_places): `if a_code.is_prefix then l_condition := "t.morph GLOB ?" else "t.morph = ?"`
- src/concordance/bib_conc_pack.e:1088-1093 (lemma_places): `al_form.is_prefix` then `"... AND t.morph GLOB ?"`, `elseif` then `"... AND t.morph = ?"`
**Suggested Action:** One feature, for example `morph_condition (a_code: BIB_MORPH_CODE): STRING_8`, owned by BIB_CONC_PACK (or by BIB_MORPH_CODE as the SQL-free "match mode"), used by morph_places and lemma_places. lemma_places then appends `" AND " + morph_condition (al_form)`. The behavior that should win is morph_places', whose precondition (line 434, `a_code.is_code_text (a_code.code)`) is the safer one; see Finding 4.
**Effort:** 1 feature extracted, 2 call sites.

### Finding 2: three readers of a root in the parser (D1)
**Priority:** HIGH. **Category:** D1.
**Classes:** BIB_QUERY_PARSER (src/search/bib_query_parser.e).
**Description:** form_root re-implements what the tokenizer's strongs: and lemma: branches and the bare-number branch already do: strip the prefix, upper-case the first letter, test `is_strongs_text`, require a non-empty lemma, pick `lemma_language`. A form is therefore read by form_root, while a root alone is read by the tokenizer, and the key object for a lemma is built in two places. Divergences already present:
- A bad strongs: gives the specific message "strongs: needs a number such as H1254 or G5485." (line 193); a bad root before @ gives a different, generic message (line 172).
- Lemma keys are built at line 344 (grammar, from the token) and at line 418 (form_root), each calling `lemma_language`; a change to how a lemma is keyed must be made twice.
- The prefix "morph:" is stripped in the tokenizer (178-179, `substring (7, ...)`) and again in form_code_text (428-431).
- form_root runs twice for every form token: once in the tokenizer to validate (171, result discarded) and again in the grammar (346). The grammar's `if attached ... as al_root` at 346 has no else branch, so a Void root would silently produce no leaf.
**Evidence:**
- src/search/bib_query_parser.e:185-194 (strongs: branch), 195-200 (lemma: branch), 202-203 (bare number)
- src/search/bib_query_parser.e:403-422 (form_root: duplicates the same prefix, case and validity rules)
- src/search/bib_query_parser.e:342-347 (two key constructions)
- src/search/bib_query_parser.e:425-433 (form_code_text duplicates the morph: strip of 178-179)
**Suggested Action:** One `root_key (a_text): detachable BIB_KEY` (prefix handling, case, validity, language) used by the Token_strongs, Token_lemma and Token_form constructions; the tokenizer branches then only choose which token kind to emit. Keep the stricter error messages of the existing branches.
**Effort:** about 3 features merged into 1.

### Finding 3: scope names in two lists (D1)
**Priority:** HIGH. **Category:** D1.
**Classes:** BIB_GUI_APP (gui_app/bib_gui_app.e), BIB_SEARCH_SCOPES (src/search/bib_search_scopes.e).
**Description:** Scope_names is a hand-typed list of the display names, whose comment says they are "the names BIB_SEARCH_SCOPES reads". BIB_SEARCH_SCOPES keeps the same names as string literals in scope_named, again as the labels it creates, and in whole_bible. Nothing ties the two. If one is renamed or reordered:
- scope_named returns Void and search_scope (lines 466-471) silently falls back to the whole Bible, so the user picks "Gospels" and searches everything;
- the heading guard at line 3146 tests only `selected_index > 1` and takes its label from search_scope, so it would print "Searched in Whole Bible only" for a non-whole choice, which contradicts the control.
The same silent fallback happens for "This book" when `reading_book = 0` (line 464).
The positions are magic numbers as well: `Scope_this_book = 6` (458), `select_index (1)` (109), `select_index (3)` in the snapshot (324), `> 1` (466, 3146). Adding a scope means editing both classes and the numbers.
**Evidence:**
- gui_app/bib_gui_app.e:452-456 (Scope_names), 458 (Scope_this_book), 460-472 (search_scope), 3146 (heading test)
- src/search/bib_search_scopes.e:40-50 (the same names, lowercased match, plus the labels "Old Testament", "New Testament", "Gospels", "Paul's letters"), 56-62 (whole_bible, "Whole Bible")
**Suggested Action:** BIB_SEARCH_SCOPES owns the ordered list of choice names (a once feature) and `scope_for_choice (a_index: INTEGER; a_book: INTEGER; a_version): BIB_SEARCH_SCOPE` with a contract that the result is never Void; the GUI fills scope_select from that list and keeps only the "This book" slot (and the Whole Bible slot) as named constants exported by it. A postcondition or an invariant check that every listed name resolves through scope_named closes the drift.
**Effort:** 2 features move; 1 list removed from the GUI.

### Finding 4: a form's code is unchecked where it is built (contract gap)
**Priority:** HIGH. **Category:** A4.
**Classes:** BIB_FORM_KEY (src/core/bib_form_key.e), BIB_CONC_PACK.
**Description:** morph_places requires `a_code.is_code_text (a_code.code)` (src/concordance/bib_conc_pack.e:434) because the code is used in a GLOB pattern (the in-code comment says only letters, digits, dashes and a final * are safe). BIB_FORM_KEY.make takes the same kind of code with no such precondition (src/core/bib_form_key.e:23-34) and the invariant (49-50) only checks the root. lemma_places then binds `al_form.code` into GLOB (bib_conc_pack.e:1089) with no check of its own. Only the parser guards it (bib_query_parser.e:173), so any other caller that builds a BIB_FORM_KEY (a test, the command line, a future client) can send `[a-z]*` or `?` as a pattern. The code is bound, so it is not an SQL injection, but it is a wrong-result path that the plain morph route rules out by contract. The scheme is also unchecked: morph_places relies on `Every_scheme`; form keys accept any scheme.
**Evidence:**
- src/core/bib_form_key.e:23-34 (make, precondition checks only the root), 49-50 (invariant)
- src/concordance/bib_conc_pack.e:434 versus 1081-1093 (no precondition on a_form in lemma_places)
**Suggested Action:** Add `code_text: a_code.is_code_text (a_code.code)` to BIB_FORM_KEY.make and to the invariant; add `form_code_text: attached a_form as al_form implies al_form.is_code_text (al_form.code)` to lemma_places and root_places.
**Effort:** 3 contract clauses.

### Finding 5: the type switch in key_places grew again (MEDIUM)
**Priority:** MEDIUM. **Category:** A1 / M2 (missing role parent).
**Classes:** BIB_CONC_PACK, BIB_FORM_KEY, BIB_STRONGS_KEY, BIB_LEMMA_KEY, BIB_CONCORDANCE.
**Description:** key_places is now a four-branch `attached {TYPE}` chain (morph, form, strongs-or-lemma, else-failure), and the extracted root_places contains a second chain on the same two types. The test "this key is a Strong's number or a lemma" is written four times: as a precondition and an invariant in BIB_FORM_KEY, as a branch condition in key_places, and as a precondition of root_places. src/search/bib_concordance.e:35 holds a similar type test. Each new key kind adds a branch to key_places and to bib_verse_search.e:152. The `else` failure branch (line 383-385) is how an unsupported key is caught at run time instead of by the type system.
**Evidence:**
- src/concordance/bib_conc_pack.e:377-386 (key_places chain), 394 (root_places precondition), 403-406 (second chain)
- src/core/bib_form_key.e:26, 50 (two more copies of the root test)
- src/search/bib_concordance.e:35
**Suggested Action:** A deferred role parent, for example BIB_ROOT_KEY (inherited by BIB_STRONGS_KEY and BIB_LEMMA_KEY alongside BIB_KEY, side by side), declaring what root_places needs (the headword lookup and the language filter). BIB_FORM_KEY.root becomes typed `BIB_ROOT_KEY`, which removes its precondition and invariant and the root_places precondition. key_places then dispatches on three kinds (morph, form, root) with the failure branch only for unknown kinds, or each key answers `places_in (pack)` and the switch disappears.
**Effort:** 1 new deferred class, 2 descendants, 4 type tests removed.

### Finding 6: search_scope rebuilds on every call (MEDIUM)
**Priority:** MEDIUM. **Category:** A5.
**Classes:** BIB_GUI_APP.
**Description:** search_scope is a function with no cache. For a fixed choice it calls scope_named, which lowercases and trims the name, and for "This book" looks the book up through `candidates_for_name` (src/search/bib_search_scopes.e:35-51). It is called in find_verses (line 3106, to parse) and again in show_verse_count (line 3147, only for the heading label), so a scoped search builds the scope twice, and the book scope runs `candidates_for_name` twice. The parsed query already holds the scope the search used (BIB_QUERY.scope, read by bib_verse_search.e:79 and 86), so the heading can print the exact scope that was searched instead of recomputing it. Recomputing also opens a window for the heading to name a different scope than the one searched if the choice changed in between (the current code is single-threaded, so this is a risk, not a live defect).
**Evidence:**
- gui_app/bib_gui_app.e:460-472 (search_scope), 3106 (first call), 3147 (second call)
- src/search/bib_verse_search.e:79, 86 (the query's own scope is what the search uses)
**Suggested Action:** Compute the scope once in find_verses and pass `l_query.scope` (or its label) to show_verse_count.
**Effort:** 1 call site, 1 parameter.

### Finding 7: key-kind lists repeated by hand (MEDIUM)
**Priority:** MEDIUM. **Category:** A1.
**Classes:** BIB_QUERY_CLAUSE, BIB_VERSE_SEARCH, BIB_QUERY_PARSER, BIB_GUI_APP.
**Description:** Adding Form meant editing the same set of kinds in five places: the precondition of make_key (src/search/bib_query_clause.e:30), is_key_clause (65), the invariant range (88), the `when` list in BIB_VERSE_SEARCH (src/search/bib_verse_search.e:152), and the term-count test in the parser (src/search/bib_query_parser.e:223; six `or`s). BIB_QUERY_CLAUSE.is_key_clause already exists as the single source of truth but the first, fourth and fifth lists do not use it. In BIB_GUI_APP.lookup_text the rule "a grammar code names no headword" is again a kind list (gui_app/bib_gui_app.e:901) and the plain-words rule is another (910-913). The lookup_text rule for Form is also a choice worth confirming: a form on a Strong's root (G3056@N-NSM) does name a headword, yet it returns Void (no dictionary entry shown), where a bare G3056 returns the number (lines 905-908). If that is intended, name it in a query on the clause (for example `names_headword`) so the rule is not rediscovered at each use.
**Evidence:**
- src/search/bib_query_clause.e:30, 65, 88
- src/search/bib_verse_search.e:152
- src/search/bib_query_parser.e:223
- gui_app/bib_gui_app.e:901-913
**Suggested Action:** Use `is_key_clause` in the make_key precondition and in the parser's count; add `is_grammar_clause` (Morph or Form) and `names_headword` on BIB_QUERY_CLAUSE and call them from lookup_text.
**Effort:** 2 new queries, 4 call sites.

### Finding 8: ascending-once postcondition runs twice (MEDIUM)
**Priority:** MEDIUM. **Category:** A4 (hot-path contract).
**Classes:** BIB_CONC_PACK.
**Description:** `ensure ascending_once: is_ascending (Result.places)` is a full scan of the packed places. Before this change root searches paid it once, in key_places. Now key_places (src/concordance/bib_conc_pack.e:387-389) calls root_places (425-427), which has the same postcondition, so every Strong's, lemma and form search scans its result twice in a contract-checked build, and every verse number set can be tens of thousands of places long. Under the ecosystem rule that timing trumps contracts, a hot-path scan should be kept once, or guarded by the testing helper that runs it outside timed code.
**Evidence:**
- src/concordance/bib_conc_pack.e:387-389, 425-427, 431 (morph_places has its own copy)
**Suggested Action:** Keep the postcondition on the public key_places only, or on each of the three producers and not on the dispatcher.
**Effort:** 1 clause.

### Finding 9: "@" is claimed before the keyword prefixes (LOW)
**Priority:** LOW. **Category:** D1.
**Classes:** BIB_QUERY_PARSER.
**Description:** The `l_word.has ('@')` branch (line 169) comes before the morph:, strongs: and lemma: branches (178-200). Any word containing @ is now a form or an error: a lemma containing @, or an e-mail style word that was previously searchable as a word, now fails with "Before @ write a root". Whether the old behavior was searchable depends on `is_searchable` and was not exercised here, so confirm before treating it as a regression.
**Evidence:** src/search/bib_query_parser.e:169-177, 178-200, 204
**Suggested Action:** Decide whether a quoted phrase is the way to search a word containing @ and say so in the error text (line 172), or test the prefixes first.
**Effort:** 1 reorder or 1 message.

### Finding 10: heading wording (LOW)
**Priority:** LOW. **Category:** T1 (text).
**Classes:** BIB_GUI_APP.
**Description:** The scope sentence is prepended to the other notes (line 3147), so with a Hebrew root the heading reads "... Click one to read it. Searched in Gospels only. Hebrew roots stand in ..."; this is readable, but the zero-result heading now appends the note after "matches." (3150), which is useful and consistent. Pre-existing and still present: the single-verse heading says "1 matches" (3153). The new "No dictionary word to show for this search: the verses it names are listed below." (line 851) replaces "A search of several parts" and now also covers a grammar-only or form-only search, where the old wording was wrong; the new wording is accurate for both. No drift here beyond the pre-existing "1 matches" grammar.
**Evidence:** gui_app/bib_gui_app.e:851, 3146-3154
**Suggested Action:** "1 verse matches."
**Effort:** 1 string.

### Finding 11: Form must stay the last kind (LOW)
**Priority:** LOW. **Category:** A2.
**Classes:** BIB_QUERY_CLAUSE.
**Description:** The invariant `kind >= Word and kind <= Form` (line 88) accepts every integer between the two, so the next kind appended after Form breaks the invariant until the author notices. The range also admits values that are not kinds. Using an explicit `is_valid_kind` query that lists the kinds, or a `Last_kind` constant next to the others, keeps this in one place.
**Evidence:** src/search/bib_query_clause.e:81-88
**Suggested Action:** Add `Last_kind = Form` and use it in the invariant.
**Effort:** 1 constant.

## Recommended Order

1. Finding 4 (contracts; smallest change, closes a wrong-result path).
2. Finding 1 (one condition, protects Finding 4's fix).
3. Finding 2 (one root reader, then the Finding 9 decision falls out of it).
4. Finding 3 (one list of scope names).
5. Finding 5 (role parent BIB_ROOT_KEY; also removes the type tests of Findings 4 and 5), then Finding 7.
6. Findings 6 and 8 (cheap), then the LOW items.

Findings are proposals: nothing is extracted without Larry's word.
