# Design Scan (diff mode): simple_bible since e184aae
# Subjects (git diff --name-only e184aae..HEAD -- src cli gui_app build build_app):
#   cli/bib_lookup.e, cli/bib_reference_linker.e, gui_app/bib_gui_app.e, src/core/bib_book_catalog.e
# Compared against: src/, cli/, gui_app/, build/, build_app/ (read-only; nothing compiled)

## Summary

| Priority | Count | Findings |
|----------|-------|----------|
| HIGH | 3 | 1, 2, 3 |
| MEDIUM | 4 | 4, 5, 6, 7 |
| LOW | 2 | 8, 9 |
| **Total** | **9** | MI and generics: none |

## Findings

| # | Priority | Cat | Subjects | Opportunity |
|---|----------|-----|----------|-------------|
| 1 | HIGH | D1 | BIB_REFERENCE_LINKER, BIB_LOOKUP | Number bounds differ: the linker bounds 1..176, the box has no upper bound and accepts verse 0 |
| 2 | HIGH | D1 | BIB_REFERENCE_LINKER, BIB_LOOKUP, BIB_BOOK_CATALOG | The box guesses a book by prefix and takes the first candidate; the linker needs an exact name; the catalog says "never guesses" |
| 3 | HIGH | D1 | BIB_REFERENCE_LINKER, BIB_LOOKUP | Accepted forms differ: three-word cap on book names, spaced dash, trailing period |
| 4 | MEDIUM | A1 | BIB_REFERENCE_LINKER, BIB_GUI_APP | "bible:B.C.V" is written in one class and parsed in another; defined twice, no shared feature |
| 5 | MEDIUM | A4 | linker, lookup, catalog, gui | Missing contracts and missing tests for the new reader features |
| 6 | MEDIUM | A1 | BIB_REFERENCE_LINKER, BIB_LOOKUP, BIB_REFERENCE_PARSER, BIB_REFERENCE_DETECTOR | Four reference readers; the two designed ones are stubs, so the interim ones keep diverging |
| 7 | MEDIUM | D1 | BIB_REFERENCE_LINKER | A name ending a sentence plus a number is linked ("Numbers. 5 people") |
| 8 | LOW | T1/misc | BIB_GUI_APP | Design pill tips C4, S2 and T5 are stale about the new behavior |
| 9 | LOW | misc | BIB_BOOK_CATALOG | is_single_chapter_book hard-codes five book ids |

## Detailed Findings

### Finding 1: Chapter and verse bounds differ between the two readers
**Priority:** HIGH (D1, drift)
**Evidence:**
- cli/bib_reference_linker.e:169 requires 1 <= chapter <= Max_number and 1 <= verse <= Max_number for the colon form; :173 and :176 bound the lone number; Max_number is 176 at :200-201.
- cli/bib_lookup.e:425-438 (`resolved`) only requires chapter > 0 and verse >= 0, no upper bound. `place_named` (:173-212) goes through it.
- Divergences: "John 3:0" is not linked (linker :169 needs verse >= 1) but the box accepts it as the whole chapter (verse 0, `resolved` :431). "Jude 999" is not linked, but the box returns place 65.1.999 and `go_to` (gui_app/bib_gui_app.e:870-884) opens a verse that does not exist. "Genesis 170" is linked (170 <= 176) although Genesis has 50 chapters.
- 176 is Psalm 119's verse count but is used as a chapter bound too; the real limit is `BIB_BOOK_CATALOG.chapter_count` (src/core/bib_book_catalog.e:119-127), which is still a stub body ("Phase 4").
**Which should win:** neither bound is right; both readers should share one "is this a plausible place" test (book known, chapter 1..chapter_count, verse 1..verse count) once `chapter_count` is real. Until then, one shared constant and one shared rule for verse 0.
**Suggested Action:** one shared place-checking feature (see finding 4's shared ancestor).

### Finding 2: The box resolves a book by prefix and picks the first candidate; the linker is exact
**Priority:** HIGH (D1)
**Evidence:**
- cli/bib_lookup.e:433-435: `candidates_for_name (a_book)` then `l_candidates.first`, with no check that the list has one entry.
- src/core/bib_book_catalog.e:84-113: `candidates_for_name` is an exact alias, else a PREFIX match over all aliases; the class note (:2-5) says "Never guesses: an ambiguous abbreviation ("Ju", "Ph") yields every candidate". `place_named` guesses: "Ju 5" opens the lowest-id candidate.
- cli/bib_reference_linker.e:128 uses `book_named_exactly` (bib_book_catalog.e:129-138), exact only, by design (header note :11-16).
- The new one-chapter rule at bib_lookup.e:205 then tests `al_place.book` of that guessed first candidate, so "Ju 9" depends on which book sorts first.
**Which should win:** the catalog's own rule (ambiguity yields every candidate; src/reference/bib_reference_parser.e:2-5 says the same, AC-1a-15). `resolved` should return Void (or a choice list) when `candidates_for_name` has more than one entry.

### Finding 3: Accepted written forms differ
**Priority:** HIGH (D1)
Checked form by form:

| Form | Linker | place_named | Same place? |
|------|--------|-------------|-------------|
| Range with hyphen or en dash ("Psalm 23:1-3", "1-3" with U+2013) | yes, linker :162 | yes, bib_lookup.e:221 | Yes, both open the first verse |
| Range "Gen 1:1-2:3" | yes, :164 | yes, before_range :222 | Yes |
| One-chapter book, lone number ("Jude 9", "Jude 5-7") | verse, :172-175 | verse, :205-207 | Yes (shared `is_single_chapter_book`) |
| "1 John 4:8", "Song of Songs 2:1" | up to three words, :107-120 | any word count, `joined_words` :410 | Yes for these two |
| Book name of four or more words (for example "Song of the Three Young Men" or "Bel and the Dragon", if catalog names them so) | NOT found: the word list is capped at 3 (:109) | found | No |
| Spaced dash "John 3:16 - 18" | links only "John 3:16" (the dash needs a digit right after, :162) | Void: words become [John, 3:16, -, 18] and `resolved` gets the book "John 3:16 -" (:200-204) | No |
| Trailing period after the reference ("John 3:16.") | link excludes the period | Void: "16." is not an integer (:199) | No (box rejects what a reader copied) |
| Trailing period after an abbreviation ("Gen. 1:1") | yes, :123-125 | yes through `candidates_for_name` :98-100 | Yes |
| Lowercase ("john 3:16") | no, by design (`starts_like_a_name` :181-192) | yes | Intentional |
| Space-only ("Gen 1 1") | no (prose safety) | yes (test_cli_commands.e:99) | Intentional |

**Evidence lines:** linker :109, :123-125, :162; lookup :187-208; lookup :410-423.
**Which should win:** the box's tolerance on name length and the linker's strictness on prose are both intended; the word-count cap and the spaced dash are accidents. Lift the cap to the longest catalog name (compute it from the catalog) and decide once about the spaced dash and the trailing period.

### Finding 4: The "bible:B.C.V" target format is defined twice
**Priority:** MEDIUM (A1, shared definition)
**Evidence:**
- Written: cli/bib_reference_linker.e:84-85 (`"](bible:" + book + "." + chapter + "." + verse + ")"`), documented in the header :4-6.
- Parsed: gui_app/bib_gui_app.e:1930-1935 (`starts_with "bible:"`, `substring (7, ...)` with the prefix length written as a bare 7, `split ('.')`, three `is_integer` tests, a book and number check).
- No shared constant for the scheme, no shared "target of a place" or "place of a target" feature, and no test that the writer's output is accepted by the reader. The reader accepts verse 0 and any chapter > 0; the writer emits verse 0 only for a whole chapter; the two only agree because they were written the same day.
**Suggested Action:** one small class (or deferred mixin the linker and the window inherit side by side) owning `target_of (book, chapter, verse): STRING_32` and `place_of (target): detachable TUPLE [book, chapter, verse]`, with the postcondition that `place_of (target_of (b, c, v))` returns (b, c, v). The window then calls it instead of splitting text itself.
**Effort:** 2 features, 1 class.

### Finding 5: Missing contracts and missing tests on the new features
**Priority:** MEDIUM (A4)
**Evidence:**
- cli/bib_reference_linker.e:97-138 `reference_at`: only `after_start` is guaranteed (:137). Nothing says the book is known (`books.has_book`), chapter >= 1, verse >= 0, or that a one-chapter book gives chapter 1.
- :142-179 `numbers_at`: no precondition (`a_text [a_start].is_digit`, `books.has_book (a_book)`), no postcondition.
- :43-95 `linked`: `nothing_lost` (:94) is the only guarantee; it does not say that removing the link syntax gives back the input, and it would pass for a result that is longer for the wrong reason.
- cli/bib_lookup.e:211 `place_named` ensure lacks "a one-chapter book implies chapter = 1"; :227-229 `before_range` ensure is only `no_longer`; `resolved` (:425-438) has no ensure at all.
- src/core/bib_book_catalog.e:129-138 `book_named_exactly`: no tie to `candidates_for_name` (for example `Result > 0 implies candidates_for_name (a_name).has (Result)`); :142-147 `is_single_chapter_book` has no `Result implies has_book (a_book_id)`.
- gui_app/bib_gui_app.e:1924-1938 `on_commentary_link`: nothing states what a non-matching target does (it is silently ignored).
- Tests: testing/test_reading.e:151-170 (linker) and :172-185 (box) cover Genesis 1:1, a hyphen range, Matthew 5, Jude 9, prose, existing links. Not covered: en dash, "1 John", "Song of Songs", "Gen." with a period, number bounds, verse 0, spaced dash, a name ending a sentence, and the linker-to-window round trip.

### Finding 6: Four reference readers; the two designed ones are stubs
**Priority:** MEDIUM (A1)
**Evidence:**
- src/reference/bib_reference_parser.e:33-46 (`parse`) and src/reference/bib_reference_detector.e:38-50 (`detected`) have rich contracts and bodies of `check implemented_in_phase_4: False then end`.
- The linker's header (cli/bib_reference_linker.e:15-16) says it is "an interim reader until the reference grammar (research/15) is vendored"; BIB_LOOKUP.place_named is a second hand-written reader (its own note, :174-177).
- Result: two interim readers with different rules (findings 1 to 3) while the designed ones would give ambiguity, systems and distinct references. Each new fix to one reader widens the drift.
**Suggested Action:** do not extract yet; when the grammar is vendored, make the linker and the box thin callers of `BIB_REFERENCE_PARSER`. Until then, put the shared rules (bounds, single-chapter, ambiguity) in the catalog so both interim readers call one place.

### Finding 7: A name ending a sentence, followed by a number, becomes a reference
**Priority:** MEDIUM (D1: the linker's prose rule is weaker than its own header)
**Evidence:**
- cli/bib_reference_linker.e:109-120 builds words with `is_word_character`, which includes '.' (:194-198), then :123-125 strips one trailing period from the name and :131 only requires one space and a digit.
- "... the book of Numbers. 5 people came" is read as the name "Numbers." followed by "5" and linked as Numbers 5; "... in Genesis. 1 Corinthians 13 says" links "Genesis. 1". The header (:15) promises "Prose is never touched by a guess".
**Which should win:** the header. Accept a trailing period only when the number follows it directly with a colon form, or only when the abbreviation is in the catalog's code list (not a full name).

### Finding 8: Design pill tips are stale about the new behavior
**Priority:** LOW
**Evidence:**
- gui_app/bib_gui_app.e:2331 (C4): lists 'John 3:16', 'Ps 23', 'Gen 1 1' but not a range ("John 3:16-18") or a lone verse in a one-chapter book ("Jude 9"); the handler comment at :666 says the same.
- :2347 (S2) and :1883 (T5): describe the commentary text but not that Bible references in a commentary are links that open that place in S1; this is the most visible new behavior of the change.
- No tip is false; each is incomplete. Larry's rule (pills carry "what is here today") makes this a defect for his screenshot tests.

### Finding 9: Hard-coded book ids
**Priority:** LOW
**Evidence:** src/core/bib_book_catalog.e:146 lists 31, 57, 63, 64, 65 (verified against the id scheme at bib_lookup.e:390-391: Genesis 1 to Malachi 39, Matthew 40 to Revelation 66). Correct today; it would be safer as `chapter_count (id, system) = 1` once that feature is real (finding 1), or as named constants.

## Recommended Order

1. Findings 1 and 2 (live defects; "Jude 999" and "Ju 5" open the wrong place today).
2. Finding 4 (one definition of the target format; small).
3. Finding 3 and 7 (agree the name rules once; add tests listed in 5).
4. Finding 5 (contracts and round-trip test).
5. Finding 6 (waits for the vendored grammar), then 8 and 9.
