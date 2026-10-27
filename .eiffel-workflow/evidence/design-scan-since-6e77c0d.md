# Design Scan (diff mode): simple_bible since 6e77c0d
# Date: 2026-10-27
# Subjects (git diff --name-only 6e77c0d..HEAD): build/bib_content_builder.e, build_app/bib_build_app.e, gui_app/bib_gui_app.e, src/reading/bib_text_reader.e, src/reading/bib_verse_key.e (new), src/simple_bible.e, src/text/bib_english_normalizer.e, bib_greek_normalizer.e, bib_hebrew_normalizer.e, bib_normalizer.e, bib_simple_unicode.e (new)
# Compared against: all of src/, cli/, gui_app/, build/, build_app/
# Read-only. Nothing was compiled or run; every statement below is from reading the code at the cited lines.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 1 |
| MEDIUM | 7 |
| LOW | 5 |
| **Total** | **13** |

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | D1 drift | `BIB_CONC_PACK.original_search_form` is a second Hebrew and Greek fold, and it already disagrees with the new normalizers |
| 2 | MEDIUM | perf | `verse_at` runs one query per hit: 500 queries on the interface thread per search |
| 3 | MEDIUM | contract cost | Normalizer postconditions run each fold at least twice more, 362,607 times in a build |
| 4 | MEDIUM | A1/A5 | `BIB_VERSE_KEY` repeats `BIB_HUB_ID`'s unit constants and decoders |
| 5 | MEDIUM | robustness | A failed index write is safe, but a silently short index is not caught |
| 6 | MEDIUM | robustness | Source rows outside the key domain abort a contract build or vanish from results |
| 7 | MEDIUM | M2 | Category-letter tests are scattered over four places and train-wreck through `normalizers.english.unicode` |
| 8 | MEDIUM | D1-adjacent | `BIB_POINTING_REDUCER` is a stub third Hebrew route |
| 9 | MEDIUM | design pill / behavior | C6 promises verse search, but `on_search` is gated on the concordance pack; P07 tip is stale |
| 10 | LOW | A3 | Sigma and final-form loops are two extra passes that a per-character hook would remove |
| 11 | LOW | T1 | Variant-character ranges written twice in `BIB_NORMALIZER` |
| 12 | LOW | correctness (edge) | Hangul recomposition depends on the whole text's length |
| 13 | LOW | tests / hygiene | No hostile-input test for `search_expression`; misplaced comment in the builder |

Checked and clean (no finding): FTS5 expression injection; `hub_place` versus `hit_place` (one route); failed index write leaves no unusable content.db. Details at the end.

## Detailed Findings

### Finding 1: Two Greek and two Hebrew folds; the old one is already wrong
**Priority:** HIGH (D1, drift: a live defect)
**Category:** D1 / A1
**Classes:** src/concordance/bib_conc_pack.e, src/text/bib_greek_normalizer.e, src/text/bib_hebrew_normalizer.e, src/text/bib_normalizer.e
**Description:** `original_search_form` (conc_pack.e:357-387, with the precomposed table `greek_base`, 388-417) is the typed-word fold for headword lookup. Its own comment (lines 358-361) says the normalizers "do this through NFD once LG-01 lands; this precomposed table serves the click until then". LG-01 landed (src/simple_bible.e:585-588, `normalizers` now over BIB_SIMPLE_UNICODE), so there are now two folds for the same words. One search box feeds both: `on_search` sends the same text to `choices_for` (headwords, uses `original_search_form`) at gui_app/bib_gui_app.e:786 and to `find_verses` (verses, uses the normalizers) at line 794.
**Divergences that exist in the code today:**
- Hebrew final forms: conc_pack.e:368-369 keeps ך ם ן ף ץ as written; BIB_HEBREW_NORMALIZER folds them to the base letter (hebrew_normalizer.e:270-271).
- Greek capital iota and upsilon with dialytika, U+03AA and U+03AB: the capital branch (conc_pack.e:370) stops at U+03A9, the next branch (line 376) sends them to `greek_base`, which has no case for them (lines 392-415 return 0 at line 416), so the letter is DROPPED. The normalizers lowercase it to iota or upsilon (bib_normalizer.e:177 `simple_lower` after NFD). A typed capital Ϊ or Ϋ loses a letter in the headword search.
- Any letter outside Hebrew, Greek and ASCII is dropped (conc_pack.e:380 keeps only `c < 128` alphanumerics), while `folded` keeps it (bib_normalizer.e:165-179). Punctuation is dropped by one route and kept by the other.
- Maqaf: dropped by `original_search_form`, turned into a space by the Hebrew normalizer (hebrew_normalizer.e:267-269). `headwords_behind_original_word` compares a joined group of tokens to this key (conc_pack.e:342-346), so the two routes disagree on multi-word groups.
- `greek_base` (388-417) is a hand-typed list of precomposed ranges; NFD does the same for every character with no list.
**Which copy should win:** BIB_NORMALIZER_SET.for_language ("hbo" / "grc") should win: it is NFD-based, covers all of Unicode 15.1, and is the one the verse index is built and queried with (D-009: the same class builds and queries). One caveat that needs a check against the data, not the code: `lemma.search` and `token.search` come from the concordance pack, built outside this repository. If that column keeps Hebrew final forms, the Hebrew normalizer's fold is the one that must change for lookups, or lookups must fold the column's way; the pack's actual values decide, so compare before replacing.
**Callers to switch:** src/concordance/bib_conc_pack.e:320, 433; cli/bib_lookup.e:255 (only the letter count).
**Suggested Action:** Replace the body of `original_search_form` with `normalizers.for_language (...)` once the language is known (Greek letters versus Hebrew letters by script, which BIB_SCRIPT_CLASSIFIER already decides, script_classifier.e:18-20), delete `greek_base`, update the stale comment. Add a test pairing the two for Ϊ, Ϋ, final forms and maqaf.
**Effort:** 2 features removed, 3 call sites

### Finding 2: One query per hit
**Priority:** MEDIUM
**Category:** perf (design)
**Classes:** src/reading/bib_text_reader.e, gui_app/bib_gui_app.e
**Description:** `verses_matching` first reads up to `a_limit` keys (reader.e:127-132), then calls `verse_at` for each key (lines 133-137), and `verse_at` runs `Verse_sql` once per hit (lines 284, 402). The GUI asks for `Verse_hit_limit` = 500 (`Verse_hit_limit`, gui_app.e:2984), so one search is 1 key query, 1 count query (`matching_count`, reader.e:152-170) and up to 500 text queries, all on the interface thread inside `find_verses` (gui_app.e:2987-3019, called from `on_search` line 794). A common word freezes the window for the length of 500 statement executions.
**Design options:** (a) read the text in the key query: join `verse_text` on the decoded key, or store the key in `verse_text` as a column so one `SELECT ... WHERE key IN (...)` or a single join returns text; (b) one query per run of keys ordered by book, chapter, verse; (c) keep `verse_fts` as is but fetch `verse_text` with `WHERE (book_id, chapter, verse) IN (VALUES ...)` in batches of 200 (SQLite's 999 or 32,766 variable limits apply). Option (a) is the smallest change.
**Also:** hits whose text row is missing are skipped silently (reader.e:134), so the list can be shorter than `matching_count`; see Finding 6.
**Effort:** 1 feature changed (`verse_at` becomes a batch)

### Finding 3: Normalizer contracts cost several folds per call
**Priority:** MEDIUM
**Category:** contract strength vs cost
**Classes:** src/text/bib_normalizer.e, src/text/bib_unicode_service.e, src/text/bib_*_normalizer.e
**Description:** The memory rule says hot paths keep only cheap critical contracts. `normalized` runs once per verse text in `write_verse_index` (build/bib_content_builder.e:218), 362,607 times in a build, and once per search term. In any build that keeps contracts (test, fat), each call also evaluates:
- `idempotent: normalized (Result).same_string (Result)` (bib_normalizer.e:116): a complete second fold (NFD, category lookup per character, simple_lower), so every call costs at least twice.
- `no_combining_marks` (117) and `punctuation_folded` (120): two linear scans, each with one general-category lookup per character (`has_combining_mark` -> bib_unicode_service.e:72-76) and a range test per character (bib_normalizer.e:134).
- `folded` repeats the same two scans in its own postcondition (bib_normalizer.e:185-186) and the language classes add a third scan: Greek `lowercase` (greek_normalizer.e:230) and `final_sigma_folded` (231), Hebrew `consonants_only` and `finals_folded` (hebrew_normalizer.e:277-278), English `lowercase` (english_normalizer.e:334).
- Below that, `BIB_UNICODE_SERVICE.nfd` has `idempotent: nfd (Result).same_string (Result)` (bib_unicode_service.e:26) which makes every NFD in `folded` (bib_normalizer.e:165) two NFDs, and each of those pays the postcondition of SIMPLE_UNICODE.nfd (see the simple_encoding scan, Finding 3: two ordering scans). `nfc` carries `idempotent` and `through_nfd` (lines 33-34): three more full compositions per call, on the Hangul-only path.
- `is_combining_mark` has the same tautology on both sides of the adapter (bib_unicode_service.e:57; simple_encoding's simple_unicode.e:49).
**Suggested Action:** Keep the cheap ones in the build path (`not_longer`, `empty_preserved`, one of the scans). Move `idempotent` and the all-characters scans into the normalizer test class (testing/test_normalizers.e) where they run over a corpus once, and run timing tests under `without_contracts`. Leave `idempotent` on `nfd` / `nfc` in the deferred service only as a test property.
**Effort:** about 12 assertions moved

### Finding 4: BIB_VERSE_KEY copies BIB_HUB_ID's arithmetic
**Priority:** MEDIUM (same arithmetic with a deliberately different domain; no result diverges over the shared domain today, hence not HIGH)
**Category:** A1 / A5 / M2
**Classes:** src/reading/bib_verse_key.e, src/user/bib_hub_id.e
**Description:** Both classes pack book, chapter and verse as `book * 1,000,000 + chapter * 1,000 + verse` and unpack them with the same operations.
**Evidence:**
- Constants: bib_verse_key.e:403-405 `Version_unit`, `Book_unit` = 1_000_000, `Chapter_unit` = 1_000; bib_hub_id.e:65-67 `Book_unit` = 1_000_000, `Chapter_unit` = 1_000.
- Decoders: `book_of`, `chapter_of`, `verse_of` at bib_verse_key.e:386-399 versus bib_hub_id.e:35-53 (the same values, written differently: `(a_key \\ Book_unit) // Chapter_unit` versus `(a_hub // Chapter_unit) \\ Chapter_unit`).
- Domain drift already present: the key accepts book 0..99 and chapter and verse 0..999 (verse_key.e:360); the hub id requires 1..999 for all three (hub_id.e:23-25, 59-60). The key's class note (lines 338-346) says "Not a hub id", which is right about meaning, but it does not require a second copy of the packing.
**Suggested Action:** A deferred or effective ancestor `BIB_VERSE_PACKING` (constants, `book_of`, `chapter_of`, `verse_of` over `a_key \\ Version_unit`) that both classes inherit side by side (multiple inheritance); `hub_id` and `verse_key` keep only their own preconditions. The key's `a_order * Version_unit` stays in BIB_VERSE_KEY.
**Effort:** 5 features

### Finding 5: A failed index write is safe; a short index is not noticed
**Priority:** MEDIUM
**Category:** robustness
**Classes:** build/bib_content_builder.e, src/data/bib_content_source.e
**Description (the question asked):** If an insert fails, no unusable content.db is left behind. The build writes `<out>.tmp` (builder.e:100-102); `write_verse_index` records the first error in `last_error` (`note_failure`, 245-246, 275-278); `build` then deletes the temp file instead of replacing the output (lines 141-148), and the previous content.db stays untouched (`replace` is only reached when `last_error = Void`, line 146). The `COMMIT` at line 228 is skipped on failure (it goes through `run`, which does nothing after an error, 266-272), so the connection closes with the transaction open; SQLite rolls back, and the file is discarded anyway, so this is harmless.
**What is not covered:**
- The two SELECTs that feed the index are not checked for errors: `a_db.query ("SELECT version_code, language, sort_order FROM version_info ...")` (builder.e:209-211) and `query_with_args ("SELECT book_id, chapter, verse, text FROM verse_text ...")` (216). A failing query returns no rows, nothing is inserted, no error is recorded, and the build succeeds with a short or empty index.
- Nothing compares `verses_indexed` (232) with `verses_written` (128). Only the one-line report at build_app/bib_build_app.e:81 prints both; no code fails on a mismatch.
- `verify` (builder.e:151-166) opens the file with the engine's check, but the reader treats `verse_fts` as optional (`has_verse_index`, reader.e:103-104, 342-343), so a missing or empty index passes the check, and the interface then says "This content.db has no verse index" (gui_app.e:2998).
- `Index_batch` = 400 gives 800 bound variables per INSERT (builder.e:215, 238-258); fine for SQLite 3.32 and later (limit 32,766) but over the older 999 limit if the batch is ever raised to 500.
**Suggested Action:** After `write_verse_index`, set `last_error` when `verses_indexed /= verses_written`; check `has_error` after each of the two queries; make `verify` require `verse_fts` for a v3 build.
**Effort:** 3 checks

### Finding 6: Source rows outside the key domain
**Priority:** MEDIUM
**Category:** robustness / contract as input validation
**Classes:** build/bib_content_builder.e, src/reading/bib_verse_key.e, src/reading/bib_text_reader.e
**Description:** `verse_text` is filled from `src.bible_verses` with no range filter (builder.e:117), while the cross-reference insert next to it filters `BETWEEN 1 AND 66` and `> 0` (builder.e:116), which suggests the source holds out-of-range rows. `write_verse_index` then calls `verse_key` for every row (line 217), whose precondition (verse_key.e:359-360) rejects book 100 or more, chapter 1000 or more, verse 1000 or more. In a build with assertions, a bad source row aborts with a contract violation instead of a reported build error (a precondition is the caller's duty; the data is external input). In a lean build, the key silently overlaps a neighbor's range.
At search time, `verse_at` ignores any hit with book, chapter or verse 0 (reader.e:285). Verse 0 is legal in the key (precondition allows 0) and exists in some versifications (Psalm titles), so such verses are indexed, counted by `matching_count`, and never listed.
**Suggested Action:** Validate each source row in the builder and record a build error (or skip with a count in `last_error`); make the key and `verse_at` agree on whether 0 is valid (allow verse 0 in `verse_at`, or reject it in `verse_key`).
**Effort:** 2 features

### Finding 7: "Is this a letter or number" asked four ways
**Priority:** MEDIUM
**Category:** M2 (duplicated cross-cutting concern) / law of Demeter
**Classes:** src/text/bib_normalizer.e, src/text/bib_unicode_service.e, src/reading/bib_text_reader.e, src/text/bib_simple_unicode.e
**Evidence:**
- src/reading/bib_text_reader.e:307: `normalizers.english.unicode.general_category (ic) [1] = 'L' or normalizers.english.unicode.general_category (ic) [1] = 'N'`: reaches through the set, the English normalizer and its service, and looks the category up twice per character. (The code reaches through a facade the way the oracle gotcha "Reaching Through Facade" warns about.)
- src/text/bib_normalizer.e:142-143 `is_dropped` tests `[1] = 'M'` or `"Cf"` by string comparison.
- src/text/bib_unicode_service.e:57 `is_combining_mark` tests `[1] = 'M'`; bib_normalizer.e:128 and :72-76 route through it.
- simple_encoding already has the named queries: `is_combining_mark`, `is_format_character`, `is_letter` (simple_unicode.e:44-62), and BIB_SIMPLE_UNICODE (bib_simple_unicode.e:52-55) forwards only the first.
**Suggested Action:** Add `is_letter`, `is_number` (or `is_letter_or_number`), `is_format_character` to BIB_UNICODE_SERVICE and forward them in BIB_SIMPLE_UNICODE; give BIB_NORMALIZER a query `has_searchable_character (a_text)`, and have the reader call that. `append_term` then drops the train wreck.
**Effort:** 3 features added, 2 call sites

### Finding 8: BIB_POINTING_REDUCER is an unimplemented third Hebrew route
**Priority:** MEDIUM
**Category:** D1-adjacent / stub
**Classes:** src/text/bib_pointing_reducer.e, src/hub/bib_verse_hub.e
**Evidence:** `reduced` is `check implemented_in_phase_4: False then end` (pointing_reducer.e:20) and returns nothing; BIB_VERSE_HUB calls it at bib_verse_hub.e:110. Its `Level_consonants` (a level that removes cantillation and vowel points, lines 24-25) is what the Hebrew normalizer now does through NFD (hebrew_normalizer.e:264). The point and accent ranges are typed again as literals (pointing_reducer.e:38, 47-48) when `general_category` gives "Mn" for all of them. Not new in this diff, but the new normalizers make the stub a third copy of the same job.
**Suggested Action:** Implement `Level_consonants` by delegating to the Hebrew normalizer; implement `Level_vowels` as NFD, drop `is_cantillation` marks (U+0591..U+05AF), recompose; keep the two status queries as the contract vocabulary.
**Effort:** 1 feature body

### Finding 9: Design pills: C6 promises more than `on_search` does; P07 is stale
**Priority:** MEDIUM
**Category:** wrong design-pill tip / behavior
**Classes:** gui_app/bib_gui_app.e
**Evidence:**
- C6 (gui_app.e:3161) says the quick search finds "every verse of the version read holding the words". `on_search` begins `if bible.is_open and then bible.conc_pack.is_available and then not search_box.text.is_empty` (line 785). Verse search needs only content.db (`has_verse_index`, reader.e:103), but when the concordance pack is unavailable the whole search, including the verse list, silently does nothing. Either the tip or the guard is wrong.
- P07 (line 3187) still reads "Search results, docked west only while there are results. Close collapses it." The same panel now carries the verses heading and grid (lines 579-580, 2975-2976) that neither T6 nor P07 names as parts; `verses_heading` and `verses_grid` have no pill of their own. T6 (line 2655) was updated.
- Behavior the tip does not say: a Strong's number or a typed reference is also sent to `find_verses` (line 794 for a non-reference input), so "H1254" produces the heading "No verse in KJV holds every word." (line 3007).
- After `on_version_change` (line 816) the old hits stay under a heading naming the previous version. The heading is honest, so LOW on its own, but the C5 tip ("The text changes; the place stays") says nothing of it.
**Suggested Action:** Split the guard (concordance for headwords, `bible.text_reader.has_verse_index` for verses); update P07; add a pill for the verses part or extend P07's text; either re-run `find_verses` on version change or clear it.
**Effort:** 1 guard, 2 tips

### Finding 10: Two post-fold loops that one hook would remove
**Priority:** LOW
**Category:** A3 (template method)
**Classes:** BIB_GREEK_NORMALIZER, BIB_HEBREW_NORMALIZER, BIB_NORMALIZER
**Evidence:** `folded` already walks every character once (bib_normalizer.e:165-179). Greek then walks `Result` again to map final sigma (greek_normalizer.e:221-228) and Hebrew walks it again for finals and maqaf (hebrew_normalizer.e:265-275). A deferred-with-default `fold_character (a_char): CHARACTER_32` in BIB_NORMALIZER, called at line 177, would let each language state its one-character mapping and remove both loops and the extra pass over every verse in the build. Deliberate Eiffel pattern: effective default in the ancestor, redefined in two descendants.
**Effort:** 1 hook, 2 loops removed

### Finding 11: Variant ranges written twice
**Priority:** LOW
**Category:** T1
**Evidence:** bib_normalizer.e:152 (`is_variant_character`: U+00A0, U+2010..U+2015, U+2018..U+201F) and bib_normalizer.e:168-174 (`folded`: the same boundaries split into four branches). They agree now; the postcondition at line 186 is what would catch a drift, at the cost in Finding 3. One table (`variant_fold (a_code): NATURAL_32`, 0 when none) used by both removes the hazard.

### Finding 12: Hangul recomposition depends on the whole text
**Priority:** LOW
**Category:** edge-case correctness
**Evidence:** bib_normalizer.e:181-183 recomposes when `Result.count > a_text.count`, a length comparison against the input. A text with Hangul plus dropped marks can stay decomposed while the same Hangul alone is recomposed, so one word has two search forms depending on its neighbors. `idempotent` still holds. No effect on Hebrew, Greek or English; noted because the class comment claims one fold for every language.

### Finding 13: Tests and hygiene
**Priority:** LOW
**Category:** tests / comments
**Evidence:**
- testing/test_content_builder.e:78-86 covers words, a phrase, case, prefix, two words, one version, pointed Hebrew. There is no test of hostile input to `search_expression` (a lone `"`, `*`, `AND`, `NEAR(`, `-`, only punctuation) or of verse 0.
- build/bib_content_builder.e:46-51: `verses_indexed` was inserted between `verses_written` and its comment, so `verses_written` now has no comment and `verses_indexed` has two lines, the second describing `verses_written`.
- BIB_SIMPLE_UNICODE (bib_simple_unicode.e:30-64) repeats the contracts of the deferred service through inheritance, which is correct; its adapter doubles every contract of SIMPLE_UNICODE (see Finding 3).

## Checked and clean

**FTS5 expression injection: no syntax error and no operator can come from user text.**
- `search_expression` (reader.e:174-201) splits the folded text at spaces outside quotes and at every `"` (line 187), so no term contains a double quote. The normalizer also maps all curly double quotes to `"` first (bib_normalizer.e:174-175), so typographic quotes cannot slip through.
- `append_term` (293-320) wraps each term as one FTS5 string (`"` + term + `"`, line 311-313), which makes AND, OR, NOT, NEAR, `-`, `^`, `:` column filters and `(` literal text inside the string. The only operator emitted is the trailing `*`, added after stripping the user's own trailing stars (lines 301-305).
- A term is emitted only when a character has category L or N (line 307), so an empty phrase is never sent.
- The finished expression is a bound parameter (`MATCH ?`, reader.e:398, 127), never concatenated into SQL; a failed query returns `make_failure` (line 140), not an exception.
- Small behavior gaps (not safety): a star after a closing quote ("in the beginning"*) is parsed as a separate term of only `*` and dropped, so a prefix on a phrase is silently lost; a star typed inside quotes applies to the phrase as a prefix.

**hub_place versus hit_place: one route, no drift.** `hub_place` (gui_app.e:2243-2253), `item_place` (1524-1527) and `hit_place` (3038-3041) all end in `place_text` (3136-3148). `hit_place` exists only because the grid agent takes a BIB_READING_VERSE; it is a one-line adapter, not a second route to the text.

**verse_key versus BIB_HUB_ID:** see Finding 4 (same arithmetic, separate meaning).

## Recommended Order
1. Finding 1: a live defect in lookups (dropped Ϊ and Ϋ, final forms, maqaf) and the stale comment that predicted it.
2. Finding 2: the freeze users will see first on a common word.
3. Finding 5 and Finding 6: the index write must fail loudly before the next build is shipped.
4. Finding 9: cheap, user-visible, and the tips are the documentation.
5. Finding 3: moves cost out of the 362,607-call path.
6. Findings 4, 7, 8 as structural work with Larry's word (multiple-inheritance ancestor for the packing; service queries; reducer).
7. Findings 10 to 13 as convenience.
