# Design Scan (diff mode): simple_bible since b71833c
# Date: 2026-10-28
# Mode: read-only; nothing compiled, nothing changed except this file
# Subjects (changed since b71833c): src/search/bib_writings_search.e, src/search/bib_writing_hit.e,
#   src/text/bib_edit_distance.e, src/reading/bib_bible_link.e, src/reading/bib_reference_linker.e,
#   src/pack/bib_private_pack_reader.e, src/pack/bib_private_pack_schema.e, src/pack/bib_private_source.e,
#   src/simple_bible.e, build/bib_pack_writing.e + the three builders, cli/bib_cli_commands.e,
#   cli_app/bib_cli_app.e, gui_app/bib_gui_app.e (feature clause "Searching Larry's writings")
# Spec: .eiffel-workflow/research/20-WRITINGS-SEARCH.md

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / duplication | 3 | 1 | 0 | 2 |
| Correctness / safety | 6 | 1 | 4 | 1 |
| Performance | 2 | 0 | 1 | 1 |
| Contracts / tests / drift | 5 | 0 | 2 | 3 |
| **Total** | **16** | **2** | **7** | **7** |

Checked and found sound (no finding): the pre-order walk handles AND with NOT children, OR containing
NOT, and nested parentheses correctly, because the parser (`BIB_QUERY_PARSER.check_negations`,
src/search/bib_query_parser.e:360-385) already refuses a NOT that is not beside a positive operand, so the
walk only ever sees a NOT as a direct child of an AND (bib_writings_search.e:173-175). Every leaf goes
through `quoted` (lines 201, 206, 210, 214, 252) with embedded `"` doubled (lines 262-268); the MATCH text
is a bound parameter and the `within` prefix goes through `substr(address, 1, ?) = ?` as two bound
parameters (bib_private_pack_reader.e, `searched`). I found no FTS5 injection path. Column filters
(`voice:x`), `NEAR`, `^`, and `-` are neutralised by the quoting.

## Findings

| # | Priority | Category | Classes | Opportunity | Effort |
|---|----------|----------|---------|-------------|--------|
| 1 | HIGH | safety | BIB_PRIVATE_SOURCE | The virtual/shadow exemption lets any table slip past the voice and provenance rule | 1 feature |
| 2 | HIGH | A5 duplicate body | BIB_WRITINGS_SEARCH, BIB_VERSE_SEARCH | Two copies of the pre-order clause walk; extract a deferred walker | 2 classes |
| 3 | MEDIUM | correctness | BIB_WRITINGS_SEARCH, BIB_PRIVATE_PACK_READER | 200-row cap is applied before the one-hit-per-address merge; truncation is silent | 2 features |
| 4 | MEDIUM | correctness | BIB_WRITINGS_SEARCH | A failed pack query reads as "0 found" | 1 feature |
| 5 | MEDIUM | performance | BIB_WRITINGS_SEARCH, BIB_EDIT_DISTANCE | Fuzzy sweep: up to three vocabulary passes, a full matrix allocated per word | 2 features |
| 6 | MEDIUM | semantics | BIB_WRITINGS_SEARCH | Fuzzy widening is applied under NOT, so a NOT removes near-miss words too | 1 feature |
| 7 | MEDIUM | tests | test_writings_search_finds_plain_and_fuzzy | No test for commentary packs, OR/NOT mixes, nesting, quoting, diacritics, or the exemption's negative case | tests |
| 8 | MEDIUM | drift | BIB_PACK_WRITING builders, BIB_WRITING_HIT | Spec says hits carry provenance; rows carry only a voice, hits get the pack's first provenance row | 1 feature |
| 9 | LOW | duplication | BIB_LINK_TARGET, BIB_BIBLE_LINK | The extraction is half done: BIB_LINK_TARGET still builds a whole linker to read a "bible:" target | 1 feature |
| 10 | LOW | CQS | BIB_WRITINGS_SEARCH | `expression` is a query that moves `index` and sets `error_message` | 1 feature |
| 11 | LOW | duplication | BIB_GUI_APP, BIB_CLI_COMMANDS | Two clients each restate "search, report error, name unsearched packs" | 2 features |
| 12 | LOW | perf/UI | BIB_GUI_APP | The fuzzy sweep and FTS query run on the UI thread, on every scope change | 1 feature |
| 13 | LOW | contract | BIB_PRIVATE_PACK_READER | `has_search` is re-queried by the `searched` precondition and by `words`; `words` hands out its mutable cache | 2 features |
| 14 | LOW | drift | spec vs BIB_EDIT_DISTANCE | Spec says limit 1 "up to five letters"; code gives 0 under three letters and the diacritic is a full edit | 1 feature |
| 15 | LOW | edge | BIB_WRITINGS_SEARCH | A lone `*` becomes `""*`; one commentary hit per passage hides sibling sections | 1 feature |
| 16 | LOW | tokens | BIB_GUI_APP | Scope index arithmetic is spelled three ways (`+2`, `+3`, `> Writings_scope_index`) | 1 feature |

## Detailed Findings

### Finding 1: The exemption rule lets a non-FTS table slip past the voice rule
**Priority:** HIGH
**Category:** safety (pack rule bypass)
**Classes:** src/pack/bib_private_source.e
**Description:** The rule "every table has NOT NULL `voice` and `provenance_key`" exists so no result can
go unlabelled. The new exemption does not exempt "the search table and its vocabulary"; it exempts
(a) every table whose `sql` starts with `CREATE VIRTUAL TABLE`, whatever its name or module (fts5, rtree,
a loadable module), and (b) every ordinary table named `<virtual name>` + `_data`, `_idx`, `_content`,
`_docsize` or `_config`. A pack can therefore carry `CREATE VIRTUAL TABLE essays USING fts5(...)` with no
voice column, or an ordinary table `writing_search_content` holding unlabelled rows, and attach cleanly.
The spec (section "What is searched") says the exemption covers "virtual tables and FTS5's five shadow
tables", which is the same width, so the code matches the spec and both are looser than the intent.
Nothing checks that `writing_search` itself has a `voice` column either, although `searched` selects it.
**Evidence:**
- src/pack/bib_private_source.e:97-103: `ic.string_value ("sql").as_upper.starts_with ("CREATE VIRTUAL TABLE")` sends any virtual table to `l_virtual`
- src/pack/bib_private_source.e:107-111: prunes `ic_virtual + ic_suffix` from `l_tables` by name only, without confirming the pruned name is an FTS5 shadow table
- src/pack/bib_private_source.e:185-190: `Shadow_suffixes` list
- src/pack/bib_private_pack_schema.e:48-54: the only virtual tables the schema makes are `writing_search` (fts5) and `writing_words` (fts5vocab)
**Suggested Action:** Narrow the exemption to the schema's own two names (`Search_table`, `Words_table`), require the `sql` to name `fts5` / `fts5vocab`, and prune shadow tables only of those names. Then require that `writing_search` has a `voice` column (a `table_info` check, UNINDEXED columns are visible there). Add the negative test (Finding 7).
**Effort:** 1 feature (`open_on`), 1 test

### Finding 2: Two copies of the pre-order clause walk
**Priority:** HIGH (A5, and a D1 drift risk)
**Category:** abstraction (duplicated body)
**Classes:** src/search/bib_writings_search.e, src/search/bib_verse_search.e
**Description:** `BIB_WRITINGS_SEARCH.expression` and `BIB_VERSE_SEARCH.evaluated` are the same walk:
a shared mutable cursor (`index` / `cursor`), an OR loop over `child_count`, an AND loop that peels off
NOT children into a negatives list before recursing, and a final "NOT outside AND" error. Only the leaf
action (verse places vs FTS5 text) and the combine step (union/intersection/difference vs `OR`/`AND`/`NOT`
text) differ. The copies have already diverged: the verse walk guards with `not has_failed` and tracks
`a_negated` for the Hebrew/Greek root flags; the writings walk has no failure guard and its
"NOT takes away..." branches (lines 181-182, 198-199) are unreachable because the parser refuses those
shapes (see summary). A third consumer (essays, named in the spec's "Later") would make a third copy.
**Evidence:**
- src/search/bib_writings_search.e:155-215: walk with `index`
- src/search/bib_verse_search.e:157-257: walk with `cursor`; OR loop 207-211, AND loop 212-237
- src/search/bib_verse_search.e:238-241 and src/search/bib_writings_search.e:198-199: the same unreachable NOT error
**Suggested Action:** `/eiffel.abstract` or a refactor branch: a deferred `BIB_CLAUSE_WALKER [G]` holding the cursor, the OR/AND/NOT peeling and the arity bookkeeping, with deferred `leaf (clause): G`, `union (a, b)`, `intersection (a, b)`, `difference (a, b)`, inherited side by side with each searcher's own parent (multiple inheritance, no single chain). Each searcher keeps only its leaf and combine features. The unreachable error branches become a single `check`.
**Effort:** 1 new deferred class, 2 classes slimmed (about 70 lines each)

### Finding 3: The 200-row cap comes before the one-hit-per-address merge
**Priority:** MEDIUM
**Category:** correctness
**Classes:** src/search/bib_writings_search.e, src/pack/bib_private_pack_reader.e
**Description:** `searched` returns at most `Max_hits_per_pack` rows (SQL `LIMIT ?`), then `search` drops repeat
addresses. A framework has a hover row plus one row per section, and a commentary passage has several
field rows, all under one address. A hit-rich address can therefore use many of the 200 rows, so fewer than
200 distinct places come back, and a place ranked 201st by row is lost even though it would be the 150th
by place. Nothing tells the reader that the cap was reached (the GUI says "N found").
**Evidence:**
- src/pack/bib_private_pack_reader.e (`searched`): `... ORDER BY rank LIMIT ?` bound to `a_limit`
- src/search/bib_writings_search.e:121-131: dedupe after the limit; line 79 `Max_hits_per_pack = 200`
**Suggested Action:** Merge in SQL (`GROUP BY address` with `min(bm25(...))`, or a window function on `address`) so the limit counts places; fetch limit+1 and expose `is_truncated` so CLI and GUI can say "first 200".
**Effort:** 2 features

### Finding 4: A failed pack query reads as "0 found"
**Priority:** MEDIUM
**Category:** correctness
**Classes:** src/search/bib_writings_search.e
**Description:** `if l_result.is_success then ... end` has no else. If the FTS5 expression is rejected (for
example the `""*` of Finding 15), or a pack lacks a column `searched` selects (Finding 1), the result is a
silent empty list. `BIB_LIST_RESULT` already carries the failure (`make_failure ... query_error` in
`searched`), so the information exists and is dropped. This is the same class of defect as the "design
scan 48" note in bib_verse_search.e:238 ("a failed root query read as 'no verse matches'").
**Evidence:**
- src/search/bib_writings_search.e:122-132 (no failure branch)
- src/pack/bib_private_pack_reader.e (`searched`): the `else create Result.make_failure (...)` branch
**Suggested Action:** On failure, add the pack's title and error to a `packs_failed` list (or set `error_message`), and have CLI and GUI print it beside `packs_without_search`.
**Effort:** 1 feature plus 2 call sites

### Finding 5: Fuzzy sweep cost
**Priority:** MEDIUM
**Category:** performance
**Classes:** src/search/bib_writings_search.e, src/text/bib_edit_distance.e
**Description:** `widened` runs `d` from 0 to `l_limit` and re-sweeps the whole vocabulary on each pass, calling
`distance` for every word each time (up to three passes for a word of six or more letters). The `d = 0`
pass can find nothing new (the word itself is already in `l_near`, line 231). Inside `distance`, every
call that survives the length-gap test allocates `l_n + 1` row arrays of `l_m + 1` integers plus an outer
array (lines 31-36), although the recurrence needs at most three rows. For a vocabulary of V words and a
query word that lies within the length window for about a third of them, one plain word costs roughly
3 x V/3 x (n + 2) allocations per pack, per query, and again for every plain word in the query. The
early-abandon test (line 56) saves arithmetic but not the allocation, since the matrix is built first.
**Evidence:**
- src/search/bib_writings_search.e:232-242 (the repeated sweep; line 234 `across a_pack.words`; line 235 `edits.distance`)
- src/text/bib_edit_distance.e:31-36 (full matrix), 41-60 (row-best abandon)
**Suggested Action:** One sweep: compute each word's distance once and file it in buckets `0..l_limit`, then take buckets in order up to `Max_widening`. In `distance`, keep three rolling rows (OSA needs rows i-2, i-1, i), allocated once per call, or reuse two scratch arrays held by the `BIB_EDIT_DISTANCE` object. Optionally skip words that share neither first nor last letter when `a_limit` is 1.
**Effort:** 2 features

### Finding 6: Fuzzy widening applies under NOT
**Priority:** MEDIUM
**Category:** semantics / drift from intent
**Classes:** src/search/bib_writings_search.e
**Description:** The recursion passes `a_fuzzy` unchanged into the NOT operand (line 175), so
`covenant NOT lamb` with fuzzy on excludes every place holding "lamb", "lambs", "land" (distance 1),
"limb" and so on. The spec says fuzzy widens "each plain word", which does not say whether a negated
word counts; a reader asking for fuzzy is asking to be forgiving about what they want, not about what they
want removed. `BIB_VERSE_SEARCH` has no fuzzy mode, so there is no precedent to copy.
**Evidence:**
- src/search/bib_writings_search.e:175 (`l_negatives.extend (expression (a_query, a_fuzzy, a_pack))`), 207-208 (widened)
**Suggested Action:** Decide with Larry; the likely answer is to pass `False` under a NOT (exact removal) and say so in the spec's "Fuzzy" section.
**Effort:** 1 line plus a spec sentence plus a test

### Finding 7: Test coverage does not reach the risky paths
**Priority:** MEDIUM
**Category:** tests
**Classes:** testing/test_facade_open.e (`test_writings_search_finds_plain_and_fuzzy`)
**Description:** The one test builds a frameworks pack and a books pack only (`pack_count` 2). Untested:
the commentary builder's `put_search_row` call and its `range_target_text` address (build/bib_commentary_builder.e, the new block after the field insert); an OR containing NOT (rejected by the parser, so
worth one assertion that the message reaches `error_message`); nested parentheses; an AND with two NOTs;
a phrase holding a double quote; a diacritic fold (the schema comment promises "zakar" finds "zākar",
src/pack/bib_private_pack_schema.e, `Search_statements` comment); `within` on a "book:" prefix; `packs_without_search` for an old pack; the exemption's negative case (Finding 1); the CLI `writings` command and the GUI path (only a snapshot hook exists, bib_gui_app.e snapshot branch "writings"). `BIB_EDIT_DISTANCE` has four point assertions and no property test (symmetry, triangle-ish bound, early-abandon agreeing with the full distance).
**Evidence:**
- testing/test_facade_open.e (added test, `l_search.pack_count` asserted 2; no commentary builder)
- src/text/bib_edit_distance.e:66-68 postconditions are the only property checks
**Suggested Action:** Add a commentary-pack case and a small table-driven expression test (query text to expected `last_expression`) so each walk shape is pinned without a database.
**Effort:** 1 to 3 tests

### Finding 8: Hits carry the pack's provenance, not the row's
**Priority:** MEDIUM
**Category:** drift (spec vs code)
**Classes:** src/pack/bib_private_pack_reader.e, build/bib_pack_writing.e, src/search/bib_writing_hit.e
**Description:** The spec's contract lists "voice and provenance" per hit. The search table has columns
`address, place, body, voice` and no provenance key (bib_private_pack_schema.e, `Search_statements`); every hit is
built with `pack_provenance`, the pack's first `source_provenance` row (bib_private_pack_reader.e,
`searched`: `l_provenance := pack_provenance`). A commentary field is written with its own `a_key`
(build/bib_commentary_builder.e, `commentary_field` insert), so a field from a second source in the same
pack would show the first source's licence. This matches how `sections_for_verse` already labels
(bib_commentary_pack.e:73), so it is a pre-existing convention, but search is the first place a hit
is shown out of its section's context.
**Evidence:**
- build/bib_pack_writing.e `put_search_row` signature: address, place, body, voice (no key)
- src/pack/bib_private_pack_reader.e `searched`: one `l_provenance` for every row
**Suggested Action:** Either add an UNINDEXED `provenance_key` column to the search table and join `source_provenance`, or say in the spec that search hits carry pack-level provenance.
**Effort:** 3 builders plus the reader, or one spec sentence

### Finding 9: The "bible:" extraction is half done
**Priority:** LOW
**Category:** duplication / M2
**Classes:** src/reading/bib_link_target.e, src/reading/bib_bible_link.e, src/reading/bib_reference_linker.e
**Description:** `BIB_BIBLE_LINK` was extracted precisely because it "needs no book catalog"
(bib_bible_link.e:5-6). `BIB_LINK_TARGET` still does `(create {BIB_REFERENCE_LINKER}.make (a_books)).target_range (text)`,
building a full linker (with its catalog) to call one inherited query. It should use
`(create {BIB_BIBLE_LINK}).target_range (text)` and keep its own `has_book` test. The reading of "book:" and "framework:" links lives in their schemas, so "bible:" is now the only grammar read through an unrelated heavy class. Also, the linker now inherits the whole grammar but only `Max_number` is used by its own code (bib_reference_linker.e:333-362); that is correct use of inheritance and needs no change.
**Evidence:**
- src/reading/bib_link_target.e:42
- src/reading/bib_bible_link.e:47-93
**Suggested Action:** Swap the creation expression; no behavior change.
**Effort:** 1 line

### Finding 10: `expression` is a query with side effects
**Priority:** LOW
**Category:** CQS
**Classes:** src/search/bib_writings_search.e
**Description:** `expression` returns a value and also advances `index` and may call `fail`, which writes
`error_message`/`error_position`. `search` must set `index := 1` before each pack (line 117) and read
`error_message` afterwards (line 120); forgetting either is silent. Also nothing asserts that the walk
consumed exactly the clause list (`index = clause_count + 1` afterwards). Folding this into Finding 2's walker
object (a fresh walker per pack, `is_complete` as a postcondition) removes both.
**Evidence:** src/search/bib_writings_search.e:117-120, 145-217, 274-281
**Effort:** absorbed by Finding 2

### Finding 11: CLI and GUI each restate the search report
**Priority:** LOW
**Category:** A5 (small)
**Classes:** cli/bib_cli_commands.e, gui_app/bib_gui_app.e
**Description:** Both clients do: no packs, then `search`, then error text with position, then a loop over
`packs_without_search`, then a count. The wording differs slightly ("built before search existed; rebuild it" vs "was built before search and is not searched"). When Finding 4 adds `packs_failed`, both must change in step.
**Evidence:** cli/bib_cli_commands.e (`writings`, new feature near line 225); gui_app/bib_gui_app.e (`search_writings`, "Searching Larry's writings" clause)
**Suggested Action:** A `report` or `notes` query on BIB_WRITINGS_SEARCH returning the lines both print.
**Effort:** 1 feature

### Finding 12: Search runs on the UI thread
**Priority:** LOW
**Category:** performance
**Classes:** gui_app/bib_gui_app.e
**Description:** `on_search`, `on_scope_change` and `search_writings` call `search` directly. With fuzzy on, Finding 5's cost lands on the window thread, and `on_scope_change` re-runs it each time the scope select changes. Also, changing scope while the box is empty still calls `search_writings`, which clears the grid and `bring_into_view`s the Writings tab.
**Evidence:** gui_app/bib_gui_app.e, `on_scope_change` (is_writings_scope branch), `search_writings` ends with `bring_into_view (results_panel, results_tabs, Writings_tab)`
**Suggested Action:** Fix Finding 5 first and measure; use the SCOOP worker pattern from the prompter panel only if it is still slow. Guard `on_scope_change` with the same non-empty test the Bible branch has.
**Effort:** 1 line to start

### Finding 13: `has_search` and `words` contracts
**Priority:** LOW
**Category:** contract
**Classes:** src/pack/bib_private_pack_reader.e
**Description:** `searched` requires `has_search` (an extra `sqlite_master` query on every call in contract-baked builds); `search` also calls `has_search` before `searched`, and `words` calls it again. Cache the answer like `words_read` and `pack_provenance_read`. `words` returns the cached list itself, so a caller that mutates it corrupts every later fuzzy search (the one caller, `widened`, only reads it). Neither cache is cleared if the pack is re-attached after a rebuild.
**Evidence:** src/pack/bib_private_pack_reader.e (`has_search`, `searched` precondition, `words`, `words_read`)
**Effort:** 2 features

### Finding 14: Spec and code differ on the fuzzy limit, and diacritics cost an edit
**Priority:** LOW
**Category:** drift
**Classes:** src/text/bib_edit_distance.e, src/search/bib_writings_search.e
**Description:** Spec: "an edit distance of 1 (words of up to five letters) or 2 (longer)". Code: no widening under three letters, 1 for three to five, 2 from six (bib_edit_distance.e:71-82; the comment says so). That is sensible but unwritten in the spec. Separately, `widened` lowercases the query word (line 227) but does not fold diacritics, while the vocabulary is folded by `unicode61 remove_diacritics 2`; "zākar" is distance 1 from "zakar" and so uses up the allowance, and Larry's transliterated vocabulary (ā, ū, ḥ) is the common case.
**Evidence:** src/search/bib_writings_search.e:227-228; src/text/bib_edit_distance.e:71-82; spec section "Fuzzy"
**Suggested Action:** Write the under-three rule into the spec; fold the query word the way the tokenizer does (or take the first token FTS returns for it) before measuring.
**Effort:** 1 feature plus a spec sentence

### Finding 15: Edge cases in expression building and dedupe
**Priority:** LOW
**Category:** edge
**Classes:** src/search/bib_writings_search.e
**Description:** (a) A word clause of just `*` gives `quoted ("")` plus `*`, i.e. `""*` (lines 204-206), which FTS5 may reject, and per Finding 4 that would read as 0 found. (b) One hit per address collapses two sections of one commentary pack that cover the same passage (the address is the passage, spec table), though the reader can open only the first; the other is reachable only through the pane's own commentary list. This is the spec's stated rule, but worth stating in the hit count's wording.
**Evidence:** src/search/bib_writings_search.e:204-206, 123-129
**Effort:** 1 guard

### Finding 16: Scope index arithmetic
**Priority:** LOW
**Category:** T1 (token drift)
**Classes:** gui_app/bib_gui_app.e
**Description:** `search_scope` finds "this book" at `names.count + 2` (line 598); `Writings_scope_index` is `names.count + 3` (line ~4206); the fuzzy choice is `selected_index > Writings_scope_index` (line 4243); `is_writings_scope` uses `>=` (line ~4210). They are consistent today, but adding another scope choice means editing four places.
**Evidence:** gui_app/bib_gui_app.e:598, 4206, 4210, 4243
**Suggested Action:** Named features `This_book_scope_index`, `Writings_scope_index`, `Writings_fuzzy_scope_index`.
**Effort:** 3 small features

## Recommended Order

1. Finding 1: a pack-rule hole, one feature, and the fix is a narrowing.
2. Finding 4 then Finding 3: stop silent zero-hit and silent truncation before more consumers (essays) join.
3. Finding 5 and Finding 6: both touch `widened`; do them together, with Finding 6 decided by Larry first.
4. Finding 2 (with 10): extract the clause walker before a third copy appears; do it on a refactor branch with Finding 7's table-driven expression test in place first, so the refactor is gated.
5. Finding 7, 8, 9, 13 to 16: tests, spec sentences and one-line cleanups.
