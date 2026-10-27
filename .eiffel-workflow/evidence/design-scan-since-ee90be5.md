# Design Scan (diff mode): simple_bible, since ee90be5

Subjects (changed under src, cli, gui_app, build, build_app): `cli/bib_reference_linker.e` only.
Compared against all of src/, cli/, gui_app/, build/, build_app/. Read-only; nothing compiled.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift | 1 | 1 | 0 | 0 |
| Contracts / tests / false readings | 4 | 0 | 3 | 1 |
| Export / hygiene | 2 | 0 | 0 | 2 |
| **Total** | **7** | **1** | **3** | **3** |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | D1 | Book-name knowledge now lives in two places: ordinals in the linker, aliases in the catalog |
| 2 | MEDIUM | false reading | "John verse 9" silently reads as chapter 9 in a multi-chapter book |
| 3 | MEDIUM | tests | No test pins the strict reader, the pronoun case, or any negative spoken form |
| 4 | MEDIUM | contract | `not_longer` is the only contract and cannot catch any false reading |
| 5 | LOW | false reading | The colon-to-space rewrite runs on every forgiving input, not only spoken ones |
| 6 | LOW | export | `spoken_form`, `Ordinal_words`, `Spelled_parts` are public (feature -- Access) |
| 7 | LOW | docs | Class note still says the readers differ "only" in how a book is named |

## Detailed Findings

### Finding 1: Spoken book numbers are text rewriting in the linker, not catalog aliases
**Priority:** HIGH (D1, drift)
**Category:** D1
**Classes:** `cli/bib_reference_linker.e`, `src/core/bib_book_catalog.e`
**Description:** The catalog is the one authority for "what name denotes which book": `load` registers each book's name and code, lowercased, as aliases (`src/core/bib_book_catalog.e:52-53`), and `candidates_for_name` resolves exact alias, then prefix (`src/core/bib_book_catalog.e:83-116`). The new code teaches name variants ("first", "II", "1st") in a second place, as a string rewrite ahead of the catalog (`cli/bib_reference_linker.e:62-96`, tables at 98-110), called only from `place_in` (131-132). The two have already diverged: `books.candidates_for_name ("First Peter")` returns empty, while `place_in ("First Peter 4:8")` in forgiving mode finds book 60. Any other caller of the catalog (the tests at `testing/test_facade_open.e:297-301` show it is a public API) gets no spoken forms. The linker's own `book_named` (line 275 onward) is the only reader that sees them.
**Why it is not simply a catalog change:** strict prose mode calls `books.book_named_exactly` (`src/core/bib_book_catalog.e:129`), which reads the same alias table. Plain aliases like "i peter" would make prose "I Peter 1:1" and a sentence starting "I John 3" link, which the new header comment (`cli/bib_reference_linker.e:62-67`) says must not happen.
**Suggested Action:** Give the catalog the ordinal variants as a separate, flagged alias set, for example a second table `spoken_aliases` consulted only by `candidates_for_name` (forgiving) and never by `book_named_exactly` (strict). Generate each variant from the book's leading number (1, 2, 3) using one deferred or shared "number word" table that the catalog owns, so a future book such as "1 Maccabees" or "1 Esdras" is covered with no linker change. Then `spoken_form` shrinks to the "chapter" and "verse" rewrite, which is a reference-grammar concern and belongs in the linker. Proposal only; nothing extracted without Larry's word.
**Effort:** 2 tables and 1 helper move; about 3 features.

### Finding 2: "verse" with a multi-chapter book reads as a chapter
**Priority:** MEDIUM
**Category:** false reading
**Evidence:** `cli/bib_reference_linker.e:80-90` turns " verse " into ":" and then, when the text before the first colon has no space, replaces the colon with a space (line 91-93). For "John verse 9" the result is "John 9", which `numbers_at` reads as chapter 9 of John (a chapter, verse 0) because John is not a single-chapter book. The only test of the colon rule uses Jude (`testing/test_reading.e:200`). The comment at line 90 states the intent for one-chapter books only; the code does not check for one.
**Suggested Action:** Apply the colon rule only when `books.is_single_chapter_book` holds for the named book; otherwise return Void for a "Book verse N" form. The check needs the book id, so this is another reason for Finding 1 (resolve the book first, then rewrite).

### Finding 3: Test gaps
**Priority:** MEDIUM
**Category:** tests
**Evidence:** The one new test (`testing/test_reading.e:183-201`) goes through `BIB_LOOKUP.place_named`, so it only exercises the forgiving reader, and only positive cases. Nothing asserts:
- strict mode is untouched: no test calls `BIB_REFERENCE_LINKER.linked` with "First Peter 4:8", "I John 3:16" or "Chapter 5" (the nearest strict tests are at `testing/test_reading.e:216-218`, which predate the change);
- a pronoun or sentence start, for example "I 5" or "I Isaiah", stays Void;
- "Isaiah 5", "Iii 1", "Second" alone, "First" alone, "First 5" stay as before;
- "Matthew verse" or "John chapter" with a missing number is Void, not a crash;
- `spoken_form` directly, including `Result.count <= a_text.count`.
The fixture catalog holds only six books (`testing/conc_fixture.e:91`: Genesis, Exodus, Matthew, 1 Peter, 2 Peter, Jude), so Isaiah, 1 John and 1 Samuel cannot be asserted at all without extending it. A regression that made strict mode call `spoken_form` would pass every current test.
**Suggested Action:** Add the strict-mode and negative cases above, and widen the fixture with Isaiah, 1 John and 1 Samuel.

### Finding 4: The `not_longer` postcondition cannot catch a false reading
**Priority:** MEDIUM
**Category:** contract
**Evidence:** `cli/bib_reference_linker.e:94-96` ensures only `Result.count <= a_text.count`. It does hold today (every replacement is the same length or shorter: "i" to "1" is equal at lines 98-104, " verse " to ":" is shorter, the colon to space swap is equal at line 92), and it is cheap. But it says nothing about what matters: that a text with no spoken part comes back equal (`a_text.same_string (Result)` when nothing matched), that strict readers never see a change, or that the result is idempotent (`spoken_form (spoken_form (x)) = spoken_form (x)`). The routine is public (Finding 6) and has no precondition. Under the project's rule that hot paths keep only cheap critical contracts, an idempotence ensure is the one worth adding if timing allows; otherwise prove the same facts in tests (Finding 3).
**Suggested Action:** Add `plain_text_unchanged` for text that contains no digit-leading ordinal word and none of the spelled parts, or cover it in tests.

### Finding 5: Colon rewrite is not limited to spoken forms
**Priority:** LOW
**Category:** false reading
**Evidence:** `cli/bib_reference_linker.e:91-93` runs on every forgiving input that has a colon with no space before it, whether or not "verse" was spelled. "Jude:9" or "Gen:1:1" now parse where they were Void before. This is lenient rather than harmful, but it is an undocumented widening of the box (the header comment names only ordinals, "chapter" and "verse"). Put the rewrite inside the branch that replaced " verse " (a local flag), or document it.

### Finding 6: Helpers are exported
**Priority:** LOW
**Category:** export
**Evidence:** `spoken_form` (62), `Ordinal_words` (98) and `Spelled_parts` (106) sit in `feature -- Access`, which is exported to all clients. They are implementation of `place_in`. The class already has a `feature {NONE} -- Implementation` section (line 268 area) for such helpers. If Finding 1 is accepted, the tables move to the catalog anyway; until then export them to {NONE}, or to {BIB_REFERENCE_LINKER, TEST_READING} if the tests call `spoken_form` directly.

### Finding 7: Class note is stale
**Priority:** LOW
**Category:** docs
**Evidence:** The class note at `cli/bib_reference_linker.e:19-24` says the two readers read numbers by one rule and "differ only in naming a book". The forgiving reader now also rewrites spoken ordinals and spelled-out "chapter" and "verse" before reading. Update the sentence so the next reader does not assume the forgiving path is a pure catalog difference.

## Questions asked in the brief

- **Drift with the catalog alias table:** yes, see Finding 1 (already diverged for `candidates_for_name`). Ordinals should become flagged catalog aliases, not linker text rewriting, because the catalog owns book names; the strict reader must keep not seeing them.
- **False readings:**
  - "I" as a pronoun: only a leading "i " is rewritten (`cli/bib_reference_linker.e:74-76` requires the word plus a space and text after it), so "I 5" becomes "1 5", which names no book and stays Void. A sentence is only affected in the forgiving box, never in prose linking, because `linked` calls `reference_at` directly and `spoken_form` is reached only from `place_in` (131-132).
  - "Isaiah": "isaiah 5" does not start with "i ", so it is untouched. Safe, but untested (Finding 3).
  - "Iii": only "iii " with a trailing space matches; the list order (iii, ii, i, lines 100-102) correctly tries the longest first.
  - "first" inside a name: only a prefix match at position 1 counts, so a name like "Thessalonians" or a text such as "Matthew first 5" is untouched. No canonical book name contains "first", "second", "third", "chapter" or "verse", so no book name is damaged today (verified against the six-book fixture only; the real catalog was not opened because this scan is read-only on the code).
  - " chapter " and " verse " are replaced anywhere in the text, not only after the book (lines 80-89); a future book or alias containing the word between spaces would be damaged.
- **`not_longer`:** holds; see Finding 4 for why it is weak.
- **Strict mode untouched:** yes. `spoken_form` is called once, guarded by `is_forgiving` (`cli/bib_reference_linker.e:131-133`); `linked`, `reference_at`, `book_named` strict branch (line 280-282) and `starts_like_a_name` are unchanged in the diff. But no test proves it (Finding 3).
- **Tests that would catch a regression:** `test_reference_box_reads_spoken_forms` catches the forgiving positives only; strict and negative cases are missing.

## Recommended Order

1. Finding 3 (tests): cheap, and it protects every later change, including Finding 1.
2. Finding 1 (move ordinal variants to flagged catalog aliases) together with Finding 2 (resolve the book first, then decide chapter or verse).
3. Findings 4 to 7 as part of the same change.
