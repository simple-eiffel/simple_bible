# Design Scan (diff mode): simple_bible, since c534f30
# Scope: git diff c534f30..HEAD -- src testing simple_bible.ecf (12 files)
# Read-only: nothing compiled, no source edited. Evidence is source reading only.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Behavior and test design | 6 | 1 | 5 | 0 |
| Abstraction / drift / cleanup | 7 | 0 | 0 | 7 |
| **Total** | **13** | **1** | **5** | **7** |

## Findings

| # | Pri | Where | Finding |
|---|-----|-------|---------|
| 1 | HIGH | testing/conc_fixture.e:170, testing/test_concordance.e:489-491 | Fixture puts the Hebrew prefix AFTER its word; the token_id tie-break is not actually tested |
| 2 | MEDIUM | src/concordance/bib_verse_word.e:56-59,67 | Gap: nothing groups morphemes into a word; a face cannot tell which tokens form one word |
| 3 | MEDIUM | src/simple_bible.e:477-499 | SIMPLE_PATH.resolve is lexical only; the "same file" claim is weaker than the comment says |
| 4 | MEDIUM | testing/test_conc_timing.e:42-71 | "First" in tests 2 and 3 is not first in process; the 125 ms deep-page rule is never asserted |
| 5 | MEDIUM | testing/test_conc_timing.e:49-53,66-72,80-82 | A failed budget skips close and remove_test_files; leaves the fixture and the pack open |
| 6 | MEDIUM | src/concordance/bib_conc_pack.e:386 | `l_position < l_previous` can never be true after ORDER BY t.pos; dead check |
| 7 | LOW | src/concordance/bib_verse_words.e:33-37 vs bib_conc_pack.e:404-408 | Postconditions copied verbatim between facade and engine |
| 8 | LOW | src/simple_bible.e:172-176,484-490 | is_conc_file recomputes canonical (conc_path) and stats conc_path per directory entry |
| 9 | LOW | src/simple_bible.e:160-166,253 | packs_found vs pack_count: two names, stale between opens, public |
| 10 | LOW | src/data/bib_source_set.e:247-250 | Retry terminates, but swallows every exception class |
| 11 | LOW | testing/conc_fixture.e:56,109; source_scan.e; test_concordance.e:274; test_source_set.e | ISE file classes remain (none new in this diff) |
| 12 | LOW | testing/test_conc_timing.e:60,63 | Hard-coded lemma ids 9380 and 8 tie the test to one build of the personal pack |
| 13 | LOW | src/provenance/bib_citations.e | Mixin is sound (two real implementors); notes only |

## Detailed Findings

### 1. HIGH. Fixture orders the morphemes the wrong way round, so the tie-break is untested
Category: D1 (a test that drifts from the real data it claims to model).
- testing/conc_fixture.e:170 inserts token 1 `BRA` (pos 1) and token 5 `B` (pos 1, the prefix, a "tagged" preposition, lemma 5). The header note (conc_fixture.e:9-11) says Genesis 1:1 begins with two tokens at position 1: a prefix, then its word.
- With `ORDER BY t.pos, t.token_id` (bib_conc_pack.e:370) the fixture returns BRA (id 1) then B (id 5): the word first, the prefix after. The assertions at testing/test_concordance.e:489-491 only check `item(1).position = 1 and item(2).position = 1` and that `item(3)` is the empty-surface token. They pass in either order of the two tied tokens, and they would pass if `, t.token_id` were deleted (SQLite tends to return rowid order for ties anyway).
- Consequence: the one rule that is new (a tie broken by token_id) has no test that fails when it is wrong, and the fixture contradicts the premise that token_id follows reading order (prefix first). Nothing in the repository shows how the real conc.db numbers a prefix against its word.
Suggested fix: give the prefix a LOWER token_id than its word in the fixture (or a deliberately inverted insert order, to prove token_id and not insertion order decides), and assert `item(1).lemma_id = 5` (prefix first) and `item(2).lemma_id = 1`. Add one runnable-only probe against the real pack (TEST_CONC_TIMING or a sibling) that Genesis 1:1's first token is the prefix.

### 2. MEDIUM. Gap (to note, not fix): no way to group morphemes into a word
- BIB_VERSE_WORD (bib_verse_word.e:56-59) carries `position` only; the morphemes of one word are the tokens that share it. `has_door` (bib_verse_word.e:67) is `lemma_id > 0`, per morpheme. So the prefix and its word each open their own word view, and an empty-surface token (6,435 in the pack) is a door with nothing written on it.
- A face needs per verse: (a) the morphemes of one word together, in order (derivable by grouping on `position`); (b) the word's written form (a join of surfaces); (c) which morpheme is the head the reader expects the word view of, versus prefix or suffix. (c) is not derivable: there is no `morpheme_index`, `is_prefix`, `is_head` or token kind.
- Naming: BIB_VERSE_WORD is now a morpheme, and `BIB_VERSE_WORDS.words` (bib_verse_words.e:25) returns morphemes.
Suggested direction (decide when the face is specified): add `morpheme_index` (1-based within the position) plus a grouped query, or a small value class BIB_VERSE_WORD_GROUP with `surface`, `morphemes`, `head`. Today every consumer must regroup on `position` itself.

### 3. MEDIUM. SIMPLE_PATH.resolve: nonexistent paths, folder entries, and what "same file" means now
- Behavior for a path that does not exist: `resolve` is `internal_path.canonical_path.name` (simple_file/src/simple_path.e:287-291). Its comment says "requires file to exist", but ISE's PATH.canonical_path (elks/kernel/path.e:586-632) is purely lexical: `absolute_path` against the current directory, then "." and ".." collapsed. It never touches the file system, so a missing file resolves without error. One edge: when `absolute_path.root` is Void it reaches `check False end`, a contract violation in a contract-on build; not reachable for drive-letter or UNC spellings, possible for a rooted-without-drive or drive-relative spelling.
- The `is_file` guard at simple_bible.e:484 is therefore not needed for `resolve` to behave. What it does: a conc_path that names no file never equals a folder entry. That is correct, but it costs a stat per entry (finding 8).
- Is the folder entry always existing? Yes. `pack_count` iterates `files_with_extension (".db")` (simple_bible.e:172-176), a directory listing, so each `a_name` is an existing basename at scan time (a race aside). The entry path is built as pack_folder plus a_name (simple_bible.e:481-485).
- What it does NOT resolve: symbolic links, junctions, 8.3 short names, subst drives, mapped drive versus UNC spellings of one share. A conc.db reached through a junction is again counted as a generic pack and `open` refuses. The comment "the same file, however each path is spelled" (simple_bible.e:478) over-claims; it means lexically the same path.
Suggested fix: reword the comment; correct the stale "requires file to exist" comment in simple_path.e:288; if link robustness is wanted, compare file identity (volume serial plus file index) in simple_file rather than strings. Add a test where conc_path does not exist and the folder holds conc.db (expect pack_count 1, no exception).

### 4. MEDIUM. Timing test: "first" is not first, and the 125 ms rule is never asserted
- testing/test_conc_timing.e:67 ("deepest offset page, first") runs after test_word_view_first_screen in the same process on the same LXX Greek article (lines 49-52), so the operating system already holds the pack; test 3 runs after both. The docstring (lines 60-61) says under 125 milliseconds first-in-process decides whether `place_page_after` may be dropped, yet the budget at line 67 is 2000: the decision criterion is printed, never held. The keyset-versus-offset comparison (line 71) is by eye only.
- `report` (lines 148-162) does measure only the work: the clock is read just before and just after `without_contracts (a_work)`; printing and asserts are outside. It includes agent dispatch plus `.is_success`, negligible. Opening and fixture building happen earlier in `opened_bible`. Correct.
- The warm budgets of 200 ms (lines 51, 54) are asserted in every build and machine state, while the class note says to judge numbers from the lean build. In the fat build or under load the suite reports FAIL for a number it says not to trust.
Suggested fix: assert the 125 ms figure with its own budget argument; label "first" as "first in this test" or run the deep-page test first; make budgets report-only unless the build is lean, or scalable through an environment variable.

### 5. MEDIUM. Timing test leaves resources open after a failed assertion
- Each test ends with `l_bible.close` and `remove_test_files` (lines 52-53, 71-72, 81-82). `report` asserts inside (lines 160-161) and an assertion failure raises, so close and delete are skipped. Task 8 fixed this very problem elsewhere with `close_leftovers` (test_concordance.e:614-632, test_facade_open.e:230-241); the new class has no such guard. The next run meets a locked `timing_test_content.db`, and a connection to the real personal pack stays open for the rest of the process.
Suggested fix: reuse the close_leftovers pattern (a once list of opened bibles closed at the start of each test and in `opened_bible`), or have `report` record failures and assert after cleanup.

### 6. MEDIUM. The relaxed ordering rule is dead behind the ORDER BY
- src/concordance/bib_conc_pack.e:386 `l_position < l_previous` runs on rows already sorted `ORDER BY t.pos, t.token_id` (line 370); `l_previous` is only the previous row's pos (line 395). It cannot be true. The old `<=` at least rejected duplicates; the new clause rejects nothing, and the postcondition `in_word_order` (line 407) is always true. Not wrong, but it reads as an integrity check and is not one.
- Real data and ties: `ORDER BY t.pos, t.token_id` is right only if token_id numbers a word's morphemes in reading order (prefix first, then the word). That is an unverified property of the personal pack (finding 1). A real integrity check would be a gap check (`l_position > l_previous + 1`), if the pack guarantees dense positions; that rule is not stated anywhere.
Suggested fix: drop the clause and keep the postcondition as documentation, or replace it with a gap check once the pack rule is known. Also `l_previous` is INTEGER_64 while `l_position` is INTEGER (lines 367-368); use one type.

### 7. LOW. Postconditions copied between BIB_VERSE_WORDS and BIB_CONC_PACK
- bib_verse_words.e:33-37 repeats the four postconditions of bib_conc_pack.e:404-408; `words` is a one-line delegate. This diff had to edit both (they stayed in step). Drift risk (A4).
- Fleet rule: no deferred ancestor, since there is no second implementor of "verse lookup". A query on the result (for example `is_in_word_order` on BIB_LIST_RESULT [BIB_VERSE_WORD]) would remove the copy without an abstraction. Proposal only.

### 8. LOW. is_conc_file repeats work per entry
- simple_bible.e:484-490: for each ".db" entry, an `is_file` stat on conc_path and two `canonical` calls, one of which (`canonical (config.conc_path)`) never changes within a scan.
Suggested fix: compute the conc canonical path once per `pack_count` (a local passed to a predicate `is_conc_entry (a_name, a_conc_canonical)`), keep the `is_file` guard once outside the loop. No invariant is involved.

### 9. LOW. packs_found beside pack_count
- simple_bible.e:160-166 and 253-269: `packs_found` is a public attribute reset in `open` (line 79) while `pack_count` still rescans on each call. Before the first open `packs_found` is 0 while `pack_count` may be 3; after `close` it keeps the old value.
Suggested fix: make `packs_found` `feature {NONE}` (name it `packs_at_open`) unless a client needs it, and reset it in `close`.

### 10. LOW. Retry audit (grep `retry` in src and testing)
Hits: src/data/bib_source_set.e:249, testing/test_app.e:436, testing/test_concordance.e:36. No retry that can hang a lean build.
- testing/test_concordance.e:33-38 (contracts probe): retries only when `l_raised` is False and `last_exception` is a PRECONDITION_VIOLATION. In a lean build no exception occurs, the assert fails, the rescue sees a non-precondition exception, does not retry, and the failure leaves. Correct, as its comment says. (Locals keep their values across a retry, so `l_tried` and `l_raised` persist.)
- testing/test_app.e:422-437 (`run_test`): sets `l_retried := True` before `retry`, so the second pass skips the body; terminates. It retries for any exception, but it is the runner and only counts the failure; acceptable. The new reason print attaches `last_exception` and `description` before use.
- src/data/bib_source_set.e:247-250: `l_failed := True` then `retry`; same terminating shape (not new in this diff). It also swallows a violated precondition or a void call inside `make_read_only` and answers Void. Suggested fix: retry only for the expected open failure, or ask simple_sql for a non-raising open (fleet gap).

### 11. LOW. ISE file classes in testing versus the fleet rule (simple_* over ISE)
None are introduced by this diff (the diff adds only SIMPLE_FILE and SIMPLE_ENV uses). Remaining uses:
- testing/conc_fixture.e:56 (RAW_FILE exists), :109-114 (`delete_file`: RAW_FILE exists, delete)
- testing/source_scan.e:18 (DIRECTORY), :37 (RAW_FILE), :52 (PLAIN_TEXT_FILE), :120 (DIRECTORY)
- testing/test_concordance.e:274-277 (PLAIN_TEXT_FILE create plus put_string)
- testing/test_source_set.e:70 (PLAIN_TEXT_FILE), :87 (DIRECTORY), :126 (RAW_FILE exists)
SIMPLE_FILE already offers `exists`, `delete` (simple_file.e:737), `write_text` (500), `read_all` and `content`, `create_directory`, `files_with_extension` (854), and tests already use it (test_facade_open.e, test_conc_timing.e). Cheapest first: `CONC_FIXTURE.delete_file`, used by every suite. No new fleet gap is needed.

### 12. LOW. Magic lemma ids
test_conc_timing.e:60, 63 (`9380`, `8`) are ids in the author's current conc.db build; a rebuild renumbers them and the test times a different word (or fails on is_success). Suggested fix: look the lemma up by Strong's value (`lemma_xref`, G3588) at test start and fail with a message naming the pack when missing.

### 13. LOW. BIB_CITATIONS mixin and fallback_provenance (design scan 29 fixes): sound
- src/provenance/bib_citations.e:16-24. Two real implementors (BIB_CONC_PACK at bib_conc_pack.e:30, BIB_WORD_LOOKUP at bib_word_lookup.e:14), so the second-implementor rule is met; stateless, no invariant; inherited side by side. grep for `across .. some ic = ` finds no remaining copy in src.
- `fallback_provenance` (bib_conc_pack.e:130,552-566,568): cleared in `check_pack`, made once, so `cite` by reference de-duplicates it. It now uses `edition_or_pack` rather than `edition_label_cache` (which could be empty at that point); an improvement. It is a stale cache only if `corpus_codes` changes without `check_pack`; nothing does.
- Class invariants: none added in this diff. BIB_VERSE_WORD's `translit_when_written` (bib_verse_word.e:99) scans the surface, so it is O(length), not O(1); unchanged, words are short.

## Recommended Order
1. Finding 1 (fixture and test so the tie-break can fail), then decide finding 2 when the face is specified.
2. Findings 4 and 5 (timing test honesty and cleanup) before anyone trusts Task 8's numbers.
3. Finding 3 comments and the nonexistent-conc_path test; finding 6 dead check.
4. Findings 7-13 as cleanup, starting with `CONC_FIXTURE.delete_file` (finding 11).

## Status (2026-10-26, refactor/scan-30)

Fixed: HIGH 1 (the fixture now numbers the prefix before its word, as conc.db does: real Genesis 1:1 is token 1 the prefix, token 2 its word, both at position 1; the test asserts prefix-first order. SQLite gives no guaranteed order among ties, so no test can be built that is certain to fail with the token_id tie-break removed; the real-data read is the evidence for the rule). MEDIUM 5 (the timing test closes an engine a failed budget left open). MEDIUM 6 answered by the same read. Open: MEDIUM 2 (a face groups morphemes by position: a GUI-plan item), MEDIUM 3 (resolve is lexical; junctions and 8.3 names not resolved), MEDIUM 4 (timing labels), the LOWs.
