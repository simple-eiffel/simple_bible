# Design Scan (diff mode): simple_bible since 138c2f1
# Date: 2026-10-27
# Subjects: gui_app/bib_gui_app.e (only file changed in src, cli, gui_app, build, build_app)
# Compared against: src/, cli/, gui_app/, build/, build_app/
# Read-only scan. Nothing compiled, nothing modified except this report.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 3 |
| MEDIUM | 3 |
| LOW | 3 |
| **Total** | **9** |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | D1 | Board code C13 is claimed by two different parts (Verse analysis and Versification) |
| 2 | HIGH | D1 | fill_verse_analysis runs twice per word click in Study (go_to chain plus explicit call) |
| 3 | HIGH | D1/A5 | The corpus for a book is chosen in four separate GUI places, each building its own BIB_LOOKUP; the analysis re-derives what fill_interlinear already holds |
| 4 | MEDIUM | A5 | Two verse-selection loops over interlinear_words with the same predicate |
| 5 | MEDIUM | A4 | New features in the C13 group have no contracts |
| 6 | MEDIUM | D1 | "Uses" silently blank when the count cannot be read; the lexicon panel reports the error |
| 7 | LOW | A5 | Numeric-to-text column helpers repeated (analysis_position, votes_text, count_text) |
| 8 | LOW | D1 | Pill text says "testament" but the Hebrew Bible corpus is not named that way in the title or the lexicon chip |
| 9 | LOW | A1 | Five-fold `create l_lookup.make (bible)` in the GUI class for a stateless helper |

## Detailed Findings

### Finding 1: Board code C13 is used twice
**Priority:** HIGH (D1, tip drift)
**Evidence:**
- gui_app/bib_gui_app.e:1866: `add_reference_mark (analysis_title, "C13", "Verse analysis: ...")`
- gui_app/bib_gui_app.e:2302: `add_reference_mark (numbering_label, "C13", "Versification: which numbering the version uses.")`
- gui_app/bib_gui_app.e:1651 and 1661 (comments) and 1124 (comment on the versification label) also both say "C13".
**Description:** The design pills are meant to be the shared vocabulary for GUI talk ("tell him what to test by pill"). Two different parts now answer to C13, so "C13 is wrong" is ambiguous. The new analysis part should take a free code from the guide boards, or the guide boards should be reconciled first. The Study marks (1858 to 1867) and the common marks (2296 to 2315) are separate routines, so in the Study layout both pills appear.
**Suggested Action:** Pick the code per the GUI guide board; rename the pill and the three comments for whichever part is wrong.
**Effort:** 1 pill string plus 3 comments.

### Finding 2: fill_verse_analysis runs twice on a word click
**Priority:** HIGH (D1: two paths to the same refresh, one redundant and costly)
**Evidence:**
- gui_app/bib_gui_app.e:1731 to 1733: on_interlinear_word calls `go_to (...)` then `fill_verse_analysis`.
- gui_app/bib_gui_app.e:952 to 954: go_to, in Study with the Interlinear tab selected, calls `fill_interlinear`, which ends with `fill_verse_analysis` at 1645.
- gui_app/bib_gui_app.e:1634 to 1644: the selection block is skipped under `is_interlinear_click`, but line 1645 is outside that block, so the analysis is rebuilt anyway.
**Description:** On a click in the Interlinear the analysis is rebuilt twice, each time re-creating BIB_LOOKUP, re-querying `place_total` per distinct headword (a SQLite query per lemma, bible.conc_pack.place_total at 1683), and resetting the grid rows. The explicit call at 1733 is also the only refresh path when the Interlinear tab is not the selected tab; the two paths should be one: either go_to always refreshes the analysis when the Interlinear tab is shown (then delete 1733), or fill_verse_analysis is called only from one place.
**Suggested Action:** Keep the call in fill_interlinear (1645) and remove 1733, after confirming go_to reaches fill_interlinear in every layout that shows the grid.
**Effort:** 1 line.

### Finding 3: The corpus for a book is derived in four GUI places
**Priority:** HIGH (D1: a second way of choosing the corpus for a book)
**Evidence:**
- gui_app/bib_gui_app.e:1595 (fill_interlinear): `corpus_for_book (reading_book)`
- gui_app/bib_gui_app.e:1679 (fill_verse_analysis): the same call again, with its own `create l_lookup.make (bible)` at 1678
- gui_app/bib_gui_app.e:2059 (study_corpus_for): the same call a third time
- gui_app/bib_gui_app.e:1795 (fill_parallel): `original_corpus_for_version`, a different rule for the Parallel original column
- cli/bib_lookup.e:112 to 125: the single rule (`corpus_for_book`, "one rule for every face, design scan 32"). It is called correctly, so there is no divergent copy of the rule itself today.
**Description:** All calls reach the one rule, so no live divergence in values. The drift risk is structural: the Uses count (1683) and the Lexicon places count (2026, via study_corpus_for at 2059 to 2063, then bible.word_lookup.view at 2026, then cli: src/concordance/bib_word_lookup.e:44 `place_total`) both end in `place_total` with a corpus. They agree today only because every word in the verse occurs in the reading corpus, so study_corpus_for always returns the reading corpus for it (2060 to 2063, `value > 0`). If study_corpus_for ever changes (for example to prefer the most common corpus, or LXX), the Uses column and the Lexicon header "N places in the X" will disagree with no test noticing. The analysis also recomputes a corpus that fill_interlinear just chose for the very same words; the corpus of `interlinear_words` is a fact of that list and could be stored beside `interlinear_book` and `interlinear_chapter` (1173).
**Suggested Action:** Add `interlinear_corpus: STRING_8` set at 1595 and reused at 1679; give both counts one shared query (a feature on BIB_WORD_LOOKUP such as `places_in (lemma, corpus)` that the Lexicon and the grid both call), with a contract that the two agree.
**Effort:** 1 attribute, 1 shared feature.

### Finding 4: Two verse-selection loops over interlinear_words
**Priority:** MEDIUM (A5)
**Evidence:**
- gui_app/bib_gui_app.e:1635 to 1640: finds the first index whose `.verse = reading_verse`
- gui_app/bib_gui_app.e:1670 to 1675: collects all words whose `.verse = reading_verse`
- The same "row for the verse read" idea appears at 818 (copy_verse), 927, 1833, 1839 and 2206 (keep_verse_in_view) over other lists.
**Description:** One feature `verse_words: ARRAYED_LIST [BIB_INTERLINEAR_WORD]` (the words of the verse read) would serve both: the selection index is the position in `interlinear_words` of `verse_words.first`, and the analysis rows are the list itself. Better still, push it onto a small deferred mixin shared with the reading and parallel views (the "row of the verse read" lookup repeated at 818, 1833 and 2206), inherited side by side per the multiple-inheritance rule.
**Suggested Action:** Extract `verse_words (a_verse)`; fill_interlinear and fill_verse_analysis both call it.
**Effort:** 2 loops become 1 feature.

### Finding 5: No contracts on the new C13 features
**Priority:** MEDIUM (A4)
**Evidence:**
- gui_app/bib_gui_app.e:1660 fill_verse_analysis: no require or ensure (nothing says `analysis_rows` all have `verse = reading_verse`, or that `analysis_uses` keys are lemma ids of rows).
- gui_app/bib_gui_app.e:1699 on_analysis_row: the guard is an inline `if`; no contract; also the clicked row does not move the Interlinear selection, unlike on_interlinear_word.
- gui_app/bib_gui_app.e:1707 analysis_position and 1713 analysis_uses_text: no postcondition (for example `Result.is_empty implies not a_word.has_door or not counted`).
- gui_app/bib_gui_app.e:2086 to 2088 shows the file does use `ensure` elsewhere (renderings_for_version), so this is an omission, not the house style.
**Suggested Action:** Add `ensure rows_are_the_verse: across analysis_rows as ic all ic.verse = reading_verse end` and `uses_only_for_rows`; add `require row_in_range` to a split-out handler.
**Effort:** 4 features.

### Finding 6: Uses is blank on a failed count, the Lexicon says why
**Priority:** MEDIUM (D1: two handlings of the same failure)
**Evidence:**
- gui_app/bib_gui_app.e:1682 to 1686: when `place_total` is Void (count unreadable), nothing is stored; the cell is blank (1717 to 1719).
- gui_app/bib_gui_app.e:2040 to 2041: the Lexicon panel shows `al_error.message` for the same kind of failure.
- src/concordance/bib_conc_pack.e:498 to 502: `place_total` returns Void when the count cannot be read, "never a made-up 0 (design scan 28)". The analysis blank is indistinguishable from "word has no door".
**Suggested Action:** On a Void total, append a short note to the analysis title or show "?" in the cell, so unreadable counts are not silent.
**Effort:** 1 branch.

### Finding 7: Column text helpers
**Priority:** LOW (A5)
**Evidence:** gui_app/bib_gui_app.e:1707 (analysis_position), 2340 (votes_text), 2351 (count_text) are each an integer turned into STRING_32 via `.out`; votes_text and count_text use `.out.to_string_32`, analysis_position assigns `.out` directly (1710) and analysis_uses_text uses `.out` (1718) without `to_string_32`. Same job, two spellings.
**Suggested Action:** One `integer_text (a_value: INTEGER_64): STRING_32` helper, and agents wrap it where a column needs a field.
**Effort:** 4 features.

### Finding 8: Pill and title wording
**Priority:** LOW (D1)
**Evidence:** gui_app/bib_gui_app.e:1694 and 1866 say "how often the headword occurs in this testament" while the corpus is WLC-MACULA or NT-MACULA (cli/bib_lookup.e:118 to 122) and the Lexicon header names it with `corpus_short_name` (2033). The wording matches the code for the Old and New Testament; the other tips checked (C10 at 1861, T3 at 1865, P03 at 1867) match the code (P03: click selects the verse and opens the headword, 1731 to 1737; C10 and T3 name Interlinear, Ctrl+I, 1295 and 1567). Only the C13 code clash in Finding 1 is a true mismatch.
**Suggested Action:** Optional: use `corpus_short_name (l_corpus)` in the title so it names the corpus as the Lexicon does.
**Effort:** 1 line.

### Finding 9: Repeated `create l_lookup.make (bible)`
**Priority:** LOW (A1/M2)
**Evidence:** gui_app/bib_gui_app.e:238, 671, 687, 932, 1021, 1594, 1678, 1795, 2059, 2075 each create a BIB_LOOKUP for one call. The new code adds one (1678).
**Suggested Action:** A once-created `lookup` attribute on the GUI class (or `bible.lookup`) replaces ten creations.
**Effort:** 1 attribute, 10 call sites.

## Recommended Order

1. Finding 1: the pill code clash is a user-visible defect and a one-line fix.
2. Finding 2: removes a duplicated refresh and a query storm on every word click.
3. Finding 3: stops the Uses and Lexicon counts drifting; the shared count feature is the durable fix.
4. Findings 5 and 6: contracts and honest failure display on the new features.
5. Findings 4, 7, 9, 8: cleanup when next in the file.
