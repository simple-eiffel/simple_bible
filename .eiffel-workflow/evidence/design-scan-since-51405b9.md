# Design Scan (diff mode): simple_bible, since 51405b9 (release 0.7.31)
# Mode: read-only, nothing compiled or run. Every line number below was read.
# Subjects: ask/bib_ask_helper.e, ask/bib_ask_call.e, ask/bib_ask_check.e, gui_app/bib_gui_app.e (Ask feature clause, parallel_versions, Back to results, chapter_page/is_subtitle), cli/bib_cli_commands.e (names, name_line), cli/bib_data_location.e (ask_log_path), build/bib_markdown_blocks.e, build/bib_book_builder.e, simple_bible.ecf, simple_bible_app.ecf
# Compared against: all of src/, cli/, build/, gui_app/ and the SIMPLE_PIPED_PROCESS source the helper rides on

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Correctness / robustness (new code) | 17 | 4 | 7 | 6 |
| Drift and duplication (D1/A5) | 5 | 2 | 1 | 2 |
| Contracts / comment drift | 5 | 0 | 1 | 4 |
| **Total** | **27** | **6** | **9** | **12** |

(High findings 1-6 below; the table groups them by kind.)

## Findings

| # | Priority | Kind | Where | Finding |
|---|----------|------|-------|---------|
| 1 | HIGH | contract/defect | gui_app/bib_gui_app.e:3162-3195 | parallel_versions adds reading_version unconditionally: duplicate column, and a 4th code breaks its own postcondition |
| 2 | HIGH | D1 drift | ask/bib_ask_check.e:240-244 vs gui_app/bib_gui_app.e:4429-4435 | A book scope passes the check but the window silently searches the whole Bible |
| 3 | HIGH | false refusal | ask/bib_ask_check.e:452-470 (words_of), 371-388 | A typed range "28-30" loses both numbers, so rule 4 refuses it |
| 4 | HIGH | UI blocking | gui_app/bib_gui_app.e:4344-4350; ask/bib_ask_helper.e:63,107,144,171 | Up to about 24 seconds frozen on the UI thread, and a failed helper is re-spawned on every request |
| 5 | HIGH | D1 drift | ask/bib_ask_check.e:431-476; gui_app/bib_gui_app.e:1535-1562; src/pack/bib_framework_names.e:104; src/reading/bib_reference_linker.e:402 | Four is_word_character definitions (three behaviours) and two whole-word searches |
| 6 | HIGH | protocol | ask/bib_ask_helper.e:142-160; simple_piped_process.e:81 | Reply id never compared, and stderr is merged into the protocol stream by default |
| 7 | MEDIUM | validator | ask/bib_ask_check.e:264-266, 280-282, 297 | mended_query replaces substrings inside other words; "without" and "or" rewrite real phrases |
| 8 | MEDIUM | validator | ask/bib_ask_check.e:164-190 | Version repair: keyword-table order beats the reader's own code, indexes misalign, "Hebrew" forces WLC onto New Testament parallels |
| 9 | MEDIUM | validator | ask/bib_ask_check.e:559, 64 | Rule 11 refuses "good news", "spider's web", "weather" anywhere in the text |
| 10 | MEDIUM | validator | ask/bib_ask_check.e:358-391, 562-569 | Number words stop at ninety: no hundreds ("Psalm 119"), no ordinals |
| 11 | MEDIUM | robustness | ask/bib_ask_helper.e:146-148, 159-160 | One error reply or one stray line turns Ask off for the session |
| 12 | MEDIUM | defect | gui_app/bib_gui_app.e:4414-4417 | word_study and words_behind only run a plain text search |
| 13 | MEDIUM | robustness | build/bib_markdown_blocks.e:353-381 | Fence tracking: any fence line closes any fence; a comment spanning a fence |
| 14 | MEDIUM | lifecycle | gui_app/bib_gui_app.e (no stop call) | ask_helper.stop is never called by the window |
| 15 | MEDIUM | duplication | ask/bib_ask_check.e:324-332 vs cli/bib_lookup.e:173-185 | Reference reading bypasses the one entry point |
| 16 | LOW | robustness | ask/bib_ask_check.e:341-355 | to_integer on an unbounded digit run (precondition) |
| 17 | LOW | validator | ask/bib_ask_check.e:358-391 | Number check is a set, not positional |
| 18 | LOW | validator | ask/bib_ask_check.e:259-262 | Only one quoted run, straight quotes only |
| 19 | LOW | robustness | gui_app/bib_gui_app.e:4471-4482 | log_ask: tabs and carriage returns in the request, unbounded growth, ignored failure |
| 20 | LOW | contracts | ask/bib_ask_helper.e:289-290 | No invariant ties is_ready to process |
| 21 | LOW | comment drift | ask/bib_ask_check.e:24-29, 3-8; gui_app/bib_gui_app.e:4323-4325 | Header lists fewer mendings and outside words than the code has |
| 22 | LOW | comment drift | testing/test_facade_open.e:758 | Assertion text says "web of lies", input is "Jude 5 commentary" |
| 23 | LOW | duplication | ask/bib_ask_check.e:562-583 vs src/core/bib_book_catalog.e:210 | Third table of number words (ordinals) |
| 24 | LOW | robustness | gui_app/bib_gui_app.e:4247-4258 | Subtitle wrapped in * * breaks when its text has * or _ |
| 25 | LOW | robustness | gui_app/bib_gui_app.e:4399-4434 | Many calls run in a row, no cap; last wins |
| 26 | LOW | security | ask/bib_ask_helper.e:102 | Helper exe taken from SIMPLE_BIBLE_ASK or a folder beside the program, no integrity check |
| 27 | LOW | efficiency | gui_app/bib_gui_app.e:4429-4435 | BIB_SCOPE_NAMES created three times per loop pass; ask_status builds a helper per call |

## Detailed Findings

### Finding 1: parallel_versions can repeat a version and exceed three (HIGH)
**Where:** gui_app/bib_gui_app.e:3162-3195.
Lines 3170-3176 add up to three asked versions (`Result.count < 3 and not Result.has`), then line 3177 does `Result.extend (reading_version)` with no guard. Two failures:
- Asked versions that include the version being read (the common case: reading KJV, request "John 3:16 in the KJV and the BSB") give `[KJV, BSB, KJV]`: the same column twice.
- Three asked versions give four codes, which breaks the routine's own `at_most_three` postcondition (line 3193) in any build with contracts (test builds are finalized with `-keep`). fill_parallel then silently drops the fourth (it loops c = 1..3).
The old behaviour (reading version first, then the others, each guarded by `Result.count < 3` and `has`) was correct; the new code moved the unguarded extend below the asked loop.
**Suggested action:** guard the extend the same way as the others (`not Result.has` and count < 3), or put reading_version first only when nothing was asked. Add a test with asked = [reading version, X] and asked = three codes.

### Finding 2: scope accepted by the check is not the scope the window runs (HIGH, D1)
**Where:** ask/bib_ask_check.e:240-244 versus gui_app/bib_gui_app.e:4429-4435.
The check accepts any scope that `bible.search_scopes.scope_named` resolves, which is a named range OR a single book ("Romans", "1 John"; src/search/bib_search_scopes.e:32-52). run_ask_call resolves only `BIB_SCOPE_NAMES.range_named` (4429); for a book name it finds no range, leaves `scope_select` at index 1, and searches the whole Bible. The reader asked "grace in Romans" and gets every book, with no message. Three scope lookups now exist (check, window, BIB_SEARCH_SCOPES); the check and the window have drifted, and the window's is the one that loses information.
**Suggested action:** one resolver the window and the check share (BIB_SEARCH_SCOPES.scope_named, then map its book range to a scope_select index or give scope_select a "book" entry); until then refuse (rule 9) a scope the window cannot place, so the failure is loud and falls back to the search box as typed.

### Finding 3: a typed range loses its numbers, so rule 4 falsely refuses (HIGH)
**Where:** ask/bib_ask_check.e:452-470 (`words_of`) feeding 358-391 (`numbers_in`).
`words_of` keeps a hyphen inside a word whenever the word so far is non-empty (line 460). For "Romans 8:28-30" the tokens are "8", "28-30". `numbers_in` takes a token as a number only if `is_natural` (line 371) or if it is hyphenated spelled words (375-378); "28-30" is neither (number_word("28") is Void), so 28 and 30 never enter `l_typed`. The model's reference "Romans 8:28-30" has numbers 8, 28, 30 (reference_numbers), and rule 4 refuses "the number 28 was not typed". The window's rule 1 opens a bare reference before asking, so the damage is limited to a range inside a sentence ("explain Romans 8:28-30 in the Greek"), which is exactly the request Ask exists for. testing/test_facade_open.e:739 tests "five through seven" but never "5-7".
**Suggested action:** in numbers_in split a token on '-' and take each digit run (and keep the spelled-words case); or let words_of keep the hyphen only between letters. Add the test.

### Finding 4: the UI thread waits on the helper (HIGH)
**Where:** gui_app/bib_gui_app.e:4344-4350 (on_ask is called from the box's enter handler, line 542); ask/bib_ask_helper.e:63 (Wait_ms = 10000), 107 (ready wait), 144 (reply wait), 170-171 (close_input then wait_for_exit 2000).
Everything is synchronous. Worst case for one request: 10 s waiting for the ready line + 2 s stop + (nothing more, since not ready) = 12 s; or a ready helper that never replies: 10 s + 2 s. A helper that is merely slow (cold model load of needle_bible.cact on first use, antivirus scan of libneedle.dll) is declared dead at 10 s. And because a non-ready helper is replaced (4344-4347: `if not (attached ask_helper ... is_ready)` creates a new one and starts it), every later request pays the start cost again: a persistently slow machine freezes the window about 12 s per request, with no spinner and no cancel.
The project has a SCOOP worker pattern for exactly this (Measure, publish jobs in simple_prompter; memory note on button progress bars): long work is a rule row plus a worker, not the UI thread.
**Suggested action:** run start and ask on a worker with a "Thinking..." state; keep the 10 s cap but start the helper at window open (or after the first idle second) rather than at the first request; after a failed start, do not respawn until the reader asks again explicitly, or back off.

### Finding 5: word-boundary helpers have drifted (HIGH, D1/A5)
**Copies:**
- ask/bib_ask_check.e:472-476 `is_word_character`: `is_alpha or is_digit`.
- gui_app/bib_gui_app.e:1535-1543: `is_alpha_numeric` plus any code above 127 that is not a space, the Hebrew maqaf/sof pasuq, or general punctuation (written specifically so Greek letters and Hebrew points count as word characters).
- src/pack/bib_framework_names.e:104-108: `is_alpha or is_digit`.
- src/reading/bib_reference_linker.e:402-406: `is_alpha or is_digit or '.'`.
Whole-word search: `whole_word_after` (gui_app/bib_gui_app.e:1545-1562) and `has_word` (ask/bib_ask_check.e:431-450) are the same loop (substring_index, check neighbours, retry from i+1); BIB_FRAMEWORK_NAMES.match_at (62-80) is a third variant.
**Divergence that matters:** the GUI version was fixed to treat non-ASCII letters as word characters; the check's version, if CHARACTER_32.is_alpha is ASCII-only for Hebrew points and some scripts (to verify), would accept "logo" inside a Greek or accented token (rule 8 false pass) or fail a boundary next to a point. The check is the one that gates what the model may run on the reader's words, so it should have the strictest definition, not the weakest.
**Suggested action:** one deferred ancestor or helper (for example BIB_WORD_BOUNDARIES with is_word_character and whole_word_at/whole_word_after) inherited side by side by BIB_ASK_CHECK, BIB_GUI_APP (or its word-click feature clause), BIB_FRAMEWORK_NAMES; the linker keeps its period override via a redefine. Effort: 2 features, 5 classes.

### Finding 6: the helper protocol trusts the next line (HIGH)
**Where:** ask/bib_ask_helper.e:127-163; ask/bib_ask_helper.e:139 (request id written), 145-156 (reply taken); simple_piped_process.e:81 (`merge_error_output := True` in `make`).
1. The request carries `"id"` (line 139) but the reply's id is never read or compared. The reply is simply "the next line". Any extra line the helper (or libneedle) prints between replies, once, shifts every later answer by one: request N+1 is answered with request N's calls. The validator still checks calls against the typed words (rules 3-9), which blunts the damage, but a call valid for both texts runs, and the reader sees the wrong passage.
2. SIMPLE_PIPED_PROCESS merges stderr into stdout by default and the helper never calls `set_merge_error_output (False)`. A native library's warning or load message on stderr arrives as a line on the protocol stream: at start it is taken as the "ready" line (108-117), fails to parse as an object, and Ask is off with the message "did not say it was ready within 10 seconds" even though the helper answered at once.
3. Line 154-156: an unparsable line (not an object) gets the same message, "did not answer within N seconds", which is false and misleads diagnosis.
Positive checks: partial lines are handled by the library (read_line waits for LF; simple_piped_process.e:462-495); a late reply is followed by `stop` (killed after 2 s), so no stale reply survives a timeout; json_string (259-287) escapes quote, backslash, %N %R %T and every code below 32, and any other character is valid raw in UTF-8 JSON, so I found no injection gap in the request side.
**Suggested action:** set_merge_error_output (False) before start (and drain or ignore stderr); read lines in a loop until an object with the matching `id` arrives or the deadline passes, skipping non-JSON lines; say "answered, but not in a form I can read" for garbage.

### Finding 7: mended_query rewrites inside words and real phrases (MEDIUM)
**Where:** ask/bib_ask_check.e:264-266, 280-282, 297.
- Quoted run (264-265): `Result.replace_substring_all (l_quoted, """ + l_quoted + """)` is a substring replace, not a whole-word one. Quoted "love" over the query `beloved love` becomes `be"love"d "love"`. The guard `has_substring (quoted)` is case-sensitive, so a lower-cased model query is not mended at all (no refusal, but the reader's phrase is lost).
- `joined_by` (285-301) uses `replace_substring_all (A + " " + B, ...)` the same way (inside longer tokens), and its test is `a_lower.has_substring (a + " or " + b)` with no word boundary.
- " without " becomes NOT (line 282): "faith without works" is a verse's own words (James 2:20, 26). A reader who types it unquoted gets `faith NOT works`, a silent change of meaning that still passes every rule. " or " has the same problem for phrases ("do or die" is not Biblical, "life or death" is).
- "any form of lovely" matches query word "love" because `has_substring ("any form of love")` has no boundary (271), so love* is searched.
- `Result := a_query.to_string_32` (256): for a STRING_32 argument `to_string_32` may return Current, so the replace calls mutate the call's stored text before `set_text`; harmless today, fragile.
**Suggested action:** replace only whole words (the helper from Finding 5), compare case-insensitively, mend " without " only when "not" or "excluding" also appears, or only when the reader did not quote.

### Finding 8: version repair order and reach (MEDIUM)
**Where:** ask/bib_ask_check.e:160-190, 406-429.
- `a_call.set_text ("version", l_named.first)` (166) overrides a valid model code with the first keyword-table hit, whatever the reader meant. "John 3:16 in the KJV, compared with the Greek": "KJV" is not a keyword (the table has "king james"), `l_named` is [WH], and open_passage is changed from KJV to WH.
- `l_named` is in keyword-table order ("septuagint", ..., "latin", ..., "hebrew", "greek"), not the reader's order. The list repair at 174-176 maps the model's i-th invalid code to the i-th named version; "Greek and Latin" gives [Vul, LXX], so an invalid pair [Greek, Latin] is repaired reversed.
- Line 181-185 appends every named version to the list; "Hebrew" always names WLC, so "the Hebrew background of Matthew 5:3 compared in KJV and BSB" (show_parallel, New Testament book) gets WLC appended and rule 7 refuses it ("WLC holds the Old Testament only"). The reader named the Hebrew idea, not the Hebrew text.
- `Missing_versions` (539-544) refuses the whole answer for ESV/NIV/etc. only when a call carries a reference (check_versions is under the reference branch, 113-123), so the behaviour differs by tool.
**Suggested action:** also scan for the catalog's own codes (KJV, BSB, ASV, YLT) typed as codes before applying keywords; keep the reader's order (index of each hit in the text); append named versions only for show_parallel when the model's list is shorter than the number named; skip WLC for a New Testament book.

### Finding 9: rule 11 refuses ordinary Bible words (MEDIUM)
**Where:** ask/bib_ask_check.e:556-560 and 61-65.
`Outside_words` = internet, web, google, online, news, weather, tested with has_word over the whole request. "good news" (the meaning of gospel, a staple of this audience), "spider's web" (Job 8:14, Isaiah 59:5) and "weather" (Matthew 16:2-3) refuse the request with a toast saying Ask only looks things up in Simple Bible; the window also does this check before anything else (gui_app/bib_gui_app.e:4338). "online" and "web" appear in real study requests ("online resources" is outside, but "web" alone is not).
**Suggested action:** match phrases ("on the web", "the internet", "search online", "the news", "the weather", "google it") rather than single words, or refuse only when the request has no scripture reference or study word beside it.

### Finding 10: numbers_in covers one to ninety only (MEDIUM)
**Where:** ask/bib_ask_check.e:358-391, 562-583.
No "hundred": "Psalm one nineteen" works only as digits; "one hundred nineteen" gives 1, 19 (or 1 and 19 via nineteen), not 119, so Psalm 119 and 150 are refused when spoken in words. No ordinals: "the second chapter of Genesis", "verse sixteenth" read as nothing. "twenty one" yields 21 and also 20 and 1 (permissive superset by design, but it lets a call with verse 1 or 20 pass).
**Suggested action:** hundreds and a small ordinal table; if ordinals are added, reuse the catalog's table (Finding 23).

### Finding 11: one bad reply turns Ask off for the session (MEDIUM)
**Where:** ask/bib_ask_helper.e:146-148, 154-160.
An `{"error":...}` reply to a single request (for example "query too long") sets off_reason, which stops and kills the helper; the next request restarts it (window line 4344), so each such error costs a model reload and, with Finding 4, up to 12 s of frozen UI. The contract text (header lines 10-14) says "off, never broken", but a per-request error is not a broken helper.
**Suggested action:** an error for one request returns empty calls and keeps the helper; only a missing/late/unreadable reply stops it.

### Finding 12: word_study and words_behind run a plain search (MEDIUM)
**Where:** gui_app/bib_gui_app.e:4414-4417.
`word_study` calls `ask_fallback (a_call.text ("word"))` and `words_behind` calls `ask_fallback (a_call.text ("english"))`: both put the word in the search box and run the Bible text search. The checker validates these arguments as typed (rule 8) and logs "run", so the log says the tool ran. If the scope box is on writings, ask_fallback also switches it to the Bible (4326-4328). The word study feature exists (word_study_button, line 186; clicked_word 1481-1483 calls headwords_behind_word), but Ask does not reach it.
**Suggested action:** call the same routines the buttons call, or log "fallback: search" instead of "run" so tuning data is honest.

### Finding 13: fence tracking in without_comments (MEDIUM)
**Where:** build/bib_markdown_blocks.e:353-381 (new).
- Any line starting with ``` or ~~~ both opens and closes (`l_is_fence`, 367-368, 371-374), regardless of marker type, length or info string: a "```text" line inside a ~~~ fence ends it, and the text after it loses its comment protection (the reverse of the original bug, but it silently deletes comments written inside code).
- An HTML comment that contains a fence line (`<!-- ... ``` ... -->`, for instance a commented-out snippet) toggles `l_in_fence` from inside the comment: the part before the fence is passed to comments_removed with an unclosed marker (warning, marker dropped, comment text kept), the rest is treated as code.
- The warning (build/bib_book_builder.e:273-275) says "the text after it is kept" - true - but names only the file, not the line.
**Suggested action:** close a fence only on the same marker character with at least the opening run length and no info string; remove comments before fences only when the opener stands outside any open fence (scan comment and fence state in one pass).

### Finding 14: the window never stops the helper (MEDIUM)
**Where:** gui_app/bib_gui_app.e: the only references to `ask_helper` are at 4289-4367; no close/exit handler calls `ask_helper.stop`.
The helper is started with `set_ends_with_owner (True)` (ask/bib_ask_helper.e:101), so Windows ends it when the program ends; that is the only thing preventing a leaked process. During the session it stays resident (model in memory) with no idle stop, and a crash of the helper between requests leaves `is_ready` True (no liveness check, `is_running` is available at simple_piped_process.e:208), so the next request writes to a dead pipe, waits 10 s, and loses that request.
**Suggested action:** call stop from the window's close handler; check `is_running` before `write_line`; optionally stop after N idle minutes.

### Finding 15: reference reading bypasses the single entry point (MEDIUM)
**Where:** ask/bib_ask_check.e:324-332 (`place_of`, creates BIB_REFERENCE_LINKER.make_forgiving directly) versus cli/bib_lookup.e:173-185 (`place_named`, whose comment says the box and the links read numbers by one rule after scan 41 found drift).
Today they agree (same linker); the check adds `bible.books.has_book`. The window's run_ask_call uses place_named (gui_app/bib_gui_app.e:4388-4390). Two ways in will drift again.
**Suggested action:** place_of delegates to `(create {BIB_LOOKUP}.make (bible)).place_named`.

### Finding 16: to_integer on a digit run (LOW)
**Where:** ask/bib_ask_check.e:349, also 372 (guarded by count <= 3, fine).
`l_text.substring (i, j - 1).to_integer` has the precondition `is_integer`, which an 11-digit run in a model-proposed reference violates (exception in a build with contracts, wrap-around without). Only reachable if the linker accepts the reference first (place_of is called before check_numbers, so a huge verse likely fails there), hence LOW.

### Finding 17: numbers are a set, not a position (LOW)
**Where:** ask/bib_ask_check.e:145-148.
Any typed number satisfies any reference number. "3 John 16" with the model proposing "John 3:16" passes (3 and 16 both typed). Rule 4 is a guard against invention, not a proof of the reading; the comment at 3-8 is accurate about that, noted for completeness. The book-number skip (reference_numbers 348) is correct for "1 Peter 1:18" but is not mirrored for a reader who typed "first Peter": "first" counts as no number, so verse 1 of "1 Peter 1:1" is refused only by chance of digits.

### Finding 18: one quoted run, straight quotes only (LOW)
**Where:** ask/bib_ask_check.e:259-268. Only the first pair of " is considered; curly quotes (typed in a word processor and pasted) are ignored; an unmatched quote is skipped silently.

### Finding 19: log_ask (LOW)
**Where:** gui_app/bib_gui_app.e:4471-4482.
Only %N is replaced (4480); a tab or carriage return in the request breaks the tab-separated columns. The log (cli/bib_data_location.e:61-67) grows without limit and holds the reader's typed text (kept local, as the comment says; worth a line in the privacy notes). `l_ok` is assigned and never read, so a failed append is invisible.

### Finding 20: invariant and contract gaps in BIB_ASK_HELPER (LOW)
**Where:** ask/bib_ask_helper.e:289-290.
Only `is_ready implies off_reason.is_empty` is stated. Missing: `is_ready implies process /= Void` (ask silently does nothing when process is Void, line 142), `calls.is_empty` while not ready is only an ensure of ask (162) not an invariant, `Wait_ms > 0`. `ask` does not ensure that `off_reason` is non-empty when calls are empty because of a failure. In `ask` the invariant is not at risk during the off_reason assignment (the call to `stop` is unqualified, so the invariant is not checked in between), but a future qualified caller would see the broken state.
BIB_ASK_CALL: `text` and `texts` (349-367) return the stored objects, not copies; `description` (369-394) decides where to put ", " by looking at the last character being "(" or "[", which drops the comma after a value ending in "(" and has no stable order (hash table). Log only.

### Finding 21: comment drift in the check and the window (LOW)
- ask/bib_ask_check.e:24-26 lists rule 10's mendings as quoted run, "any form of X", "A or B", "A but not B", "the Greek word X"; the code also mends "starting with X", "X with any ending", "the Hebrew word X", and " without " (271-282).
- Rule 11 text (27-28) names the internet, the web, the news, the weather; the table (559) also has "google" and "online".
- Header 3-8 says rule 1 is the window's "before it asks"; on_ask (gui_app/bib_gui_app.e:4338-4342) runs rule 11 first, then rule 1, then asks.
- ask/bib_ask_helper.e:128-129 says "a late or unreadable reply turns Ask off"; an error reply does too (146-148).

### Finding 22: test message drift (LOW)
testing/test_facade_open.e:758: the assertion message says "a request about web of lies is about the web" but the input is "Jude 5 commentary", and it asserts false. Message and input do not match; the test is fine, the text misleads.

### Finding 23: a third table of number words (LOW)
ask/bib_ask_check.e:562-583 (Number_words, Number_values) and src/core/bib_book_catalog.e:210 (ordinals "first"..."third" to digits for book names) are separate tables for the same job: reading a spelled number. Natural home: one BIB_SPOKEN_NUMBERS (cardinals, ordinals, hundreds) used by both.

### Finding 24: subtitle in italics (LOW)
gui_app/bib_gui_app.e:4228-4229: the subtitle is wrapped in `*...*` around `linked (markdown)`; a subtitle with `*`, `_` or a link whose text has emphasis breaks the italic run. is_subtitle (4243-4249) is correct for its own cases (block 2, level >= 2, under a level-1 title) and its precondition holds.

### Finding 25: many calls, no cap (LOW)
gui_app/bib_gui_app.e:4357-4361 runs every checked call in order; each search_text calls on_search, each open_passage moves the reader. Nothing limits the count (read_calls in the helper takes the whole array, ask/bib_ask_helper.e:229-255); the last call wins the screen. A cap of about three, or only the first navigating call, would keep it predictable.

### Finding 26: where the helper comes from (LOW)
ask/bib_ask_helper.e:102 starts needle_helper.exe from `folder`, which is SIMPLE_BIBLE_ASK or the "ask" folder beside the program (gui_app/bib_gui_app.e:4299-4303). No hash or signature check; protection is the install folder's permissions. Acceptable for a local desktop program; worth a sentence in the install notes.

### Finding 27: small efficiency items (LOW)
gui_app/bib_gui_app.e:4429-4435 creates `BIB_SCOPE_NAMES` three times per loop pass and the loop has no exit after a match (4444-4455 use_version likewise continues after a match). `ask_status` (4306-4318) builds a helper object (four file checks) every time it is called (toast text, line 1010).

## Items checked and found sound
- json_string (ask/bib_ask_helper.e:259-287): complete JSON escaping; no injection path through the query.
- stop and start (165-186, 84-125): the process is closed on every path I read, killed when it ignores end of input within 2 s, `ready_or_said` postcondition holds, and `is_ready` is only True after a readable ready line. The `off_or_ready` invariant holds at every routine exit.
- Rule 3 and the one-chapter exception (ask/bib_ask_check.e:144-148): "Jude 5" and "Jude verse 9" pass, "Jude 1:5-7" with "verses five through seven" passes (test at testing/test_facade_open.e:739).
- reference_numbers' book-number skip (334-356) handles "1 Peter 1:18", "2 Timothy 3:16-17".
- heading_text (build/bib_markdown_blocks.e:277-295): "Learning C#" kept, "## Title ##" closed, all-hash heading yields empty text (CommonMark-like).
- comments_removed's unclosed-comment handling (398-405): keeps the text, sets the flag, test at testing/test_facade_open.e:711-713.
- names/name_line (cli/bib_cli_commands.e:265-321): tab and newline in names are replaced with spaces, so the tab-separated output is safe; a carriage return in a title or a link text is not replaced (negligible).
- ecf changes: simple_process and simple_json are added to the window target, and the ask cluster to the tests and window targets; the CLI and build targets do not reference the ask classes (checked with grep), so no missing cluster.

## Recommended Order
1. Finding 1 (parallel_versions): a two-line guard, and the duplicate column is visible to any reader who names the version they are reading.
2. Finding 2 (scope drift): silent wrong results; refuse or map, then share one resolver.
3. Finding 3 (ranges in words_of): the most common false refusal; one test and one loop.
4. Finding 6 (id check, stderr merge, garbage message): small, makes the protocol trustworthy before more models are added.
5. Finding 4 (worker for start/ask; no respawn storm): the largest change, schedule with the window's other long jobs.
6. Finding 5 with 23 and 15 (one word-boundary helper, one spoken-number table, one reference entry): an abstraction pass by deferred ancestors inherited side by side, per Larry's rule; do it before the next Ask rule is added.
7. Findings 7-11 (validator precision and the one-error-kills-Ask rule): tune from the Ask log once readers have used it.
8. Findings 12-14, then the LOW items as cleanup.
