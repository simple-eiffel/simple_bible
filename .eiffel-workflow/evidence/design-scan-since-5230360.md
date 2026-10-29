# Design Scan (diff mode): simple_bible, since 5230360
# Mode: read-only, nothing compiled or run. Every line number below was read in the working tree at HEAD.
# Subjects: ask/bib_ask_helper.e, ask/bib_ask_check.e, gui_app/bib_gui_app.e (search_scope, on_scope_change, parallel_versions, on_ask, run_ask_call), src/text/bib_word_characters.e (new), src/pack/bib_framework_names.e, src/reading/bib_reference_linker.e, testing/test_facade_open.e
# Compared against: all of src/, ask/, gui_app/, cli/, testing/ and SIMPLE_PIPED_PROCESS / SIMPLE_MONOTONIC_CLOCK (the sources the helper rides on)
# Previous scan: .eiffel-workflow/evidence/design-scan-since-51405b9.md (HIGH findings 1-6)

## Verdict on the previous HIGH findings

| # | Previous HIGH | Verdict | Evidence |
|---|---------------|---------|----------|
| 1 | parallel_versions repeated a version / exceeded three | RESOLVED | gui_app/bib_gui_app.e:3175-3205: `compare_objects` (3176), asked versions only (3177-3182), reading version and the fallback list only when `Result.is_empty` (3183). Postcondition `each_once` added (3205). Two side issues below (sticky asked list, no test). |
| 2 | A book scope passed the check, the window searched the whole Bible | RESOLVED in effect, with a new HIGH on its lifetime (finding 1 below) | gui_app/bib_gui_app.e:4455-4457 sets `asked_search_scope`; 620-632 `search_scope` returns it first. |
| 3 | A typed range "28-30" lost its numbers (false rule 4 refusal) | RESOLVED | ask/bib_ask_check.e:374-378 splits a hyphenated token into its digit runs (each at most 3 digits). New test testing/test_facade_open.e:762 ("explain Jude 1:5-7 please"). The spelled "twenty-one" case still falls to the old branch (381). |
| 4 | UI thread blocked up to 24 s, helper respawned on every request | PARTLY RESOLVED, downgraded to MEDIUM (finding 3) | Respawn fixed: `may_start` / `Retry_ms` 60 s (ask/bib_ask_helper.e:70-78, window 4360). Waits cut: `Wait_ms` 5 s (63), `Reply_ms` 3 s (66). Still synchronous on the UI thread. |
| 5 | Four `is_word_character` copies, two whole-word loops | RESOLVED for the window and Ask; one thin copy of the loop remains (finding 9) | src/text/bib_word_characters.e:21-51; ask/bib_ask_check.e:437-447, 470-474; gui_app/bib_gui_app.e:1539-1549. The linker (renamed `is_name_character`, src/reading/bib_reference_linker.e:402) and BIB_FRAMEWORK_NAMES (src/pack/bib_framework_names.e:104-109) are kept apart on purpose and their comments say why: accepted. |
| 6 | Reply id never compared; stderr merged into the protocol stream | RESOLVED | `set_merge_error_output (False)` at ask/bib_ask_helper.e:114; `reply_to` (208-232) takes the line whose "id" equals the request id and passes over the rest. Residuals in findings 4 and 8. |

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Correctness / lifetime (new code) | 5 | 1 | 4 | 0 |
| Contracts / tests | 2 | 0 | 1 | 1 |
| Drift and duplication | 3 | 0 | 0 | 3 |
| Claim versus code | 2 | 0 | 0 | 2 |
| **Total** | **12** | **1** | **5** | **6** |

## Findings

| # | Priority | Kind | Where | Finding |
|---|----------|------|-------|---------|
| 1 | HIGH | D1 / lifetime | gui_app/bib_gui_app.e:620-632, 640, 1133-1144, 4306-4308, 4350, 4446, 4457 | `asked_search_scope` outlives the Ask request: a later search from the box, or after a version change, silently runs in the asked book while the scope list says "Whole Bible" |
| 2 | MEDIUM | robustness (made worse) | ask/bib_ask_helper.e:163-164, 175-178 | One error reply now locks Ask out for 60 seconds and kills a healthy helper |
| 3 | MEDIUM | UI blocking (residual of old 4) | ask/bib_ask_helper.e:122, 183-195, 217-218; gui_app/bib_gui_app.e:4360-4366 | Still on the UI thread: up to 5 s + 2 s at start, 3 s + 2 s per failed ask |
| 4 | MEDIUM | robustness | ask/bib_ask_helper.e:160-162, 215-228 | A dead helper is not detected: `is_ready` stays True, and `reply_to` has no pause when `read_line` returns at once |
| 5 | MEDIUM | lifetime | gui_app/bib_gui_app.e:3177-3182, 4349, 4425 | `asked_parallel_versions` stays set until the next Ask request, so every later Parallel opening uses the asked columns |
| 6 | MEDIUM | tests | testing/test_facade_open.e (diff, lines 760-769) | The new tests cover only BIB_ASK_CHECK; the helper loop, may_start, parallel_versions, asked_search_scope and BIB_WORD_CHARACTERS have none |
| 7 | LOW | protocol | ask/bib_ask_helper.e:122-132 | `start` reads one line only: a stray non-JSON line before "ready" gives a false "did not say it was ready" |
| 8 | LOW | message | gui_app/bib_gui_app.e:4385-4388 | The window says why Ask is off, but not that it will retry in 60 seconds |
| 9 | LOW | drift / MI | gui_app/bib_gui_app.e:1539-1566; ask/bib_ask_check.e:437-447, 470-474 | Wrappers and one `once` per client around BIB_WORD_CHARACTERS; `whole_word_after` is still a second copy of the loop |
| 10 | LOW | contracts | ask/bib_ask_helper.e:74-78, 208-232, 342-343 | No contracts on `may_start` / `reply_to`; no invariant tying `is_ready` to `process` |
| 11 | LOW | claim vs code | ask/bib_ask_check.e:264-273 | "mended_query whole words" is true only for `joined_by`; the quoted run and "any form of" still match inside words |
| 12 | LOW | validator | ask/bib_ask_check.e:554-560 | Rule 11 phrases: "the web" refuses "the web of the spider"; "news today" matches inside "good news today" |

## Detailed Findings

### Finding 1: the asked book scope outlives the request (HIGH, D1)
**Where:** gui_app/bib_gui_app.e.
`asked_search_scope` is set in `run_ask_call` (4457) after `scope_select.select_index (1)` (4446), so the list shows "Whole Bible" while `search_scope` (620-632) returns the asked book first (625-626). It is cleared in only two places: `on_ask` (4350) and `on_scope_change` (640, the list's change handler, 544). Nothing else clears it:
- The reader runs Ask "grace in Romans", sees the results, then types another word into the search box and presses Search. `on_search` goes to `find_verses`, which calls `search_scope` (5244 area), so the new search runs in Romans only, with the list saying "Whole Bible". This is the same defect class as old finding 2 (the scope shown and the scope run disagree), arriving one step later.
- `on_version_change` (1133-1144) does not clear it. The scope was built with `reading_version` at ask time (4457: `scope_named (..., reading_version)`), and a BIB_SEARCH_SCOPE carries its version list, so after the reader switches version the list-built scopes are rebuilt for the new version (629) but the asked one still names the old one.
**Suggested action:** clear `asked_search_scope` at the end of the run (after `on_search`, so only that one search uses it) and have `search_scope` consult it only during that call; or add the book to `scope_select` for the duration (a visible "Romans" entry) so the list tells the truth. Either way clear it in `on_version_change`. Add `asked_search_scope := Void` in `ask_fallback` as well (4395-4403 area) so a refused request never inherits it (it is cleared at 4350 today, so this is only for the shape of the code).
**Effort:** 3 lines.

### Finding 2: one error reply turns Ask off for a minute (MEDIUM, worse than before)
**Where:** ask/bib_ask_helper.e:163-164 and 175-178.
An `{"error":...}` reply to one request sets `off_reason`; the `if not off_reason.is_empty` block then stops the helper and sets `failed_at` (177). Before the merge the next request restarted it at once (a cost, but Ask came back); now `may_start` (74-78) refuses for `Retry_ms` = 60 s, so the next dozen requests all fall back to the plain search with "Ask is off: The Ask helper answered with an error: ...". A per-request error (query too long, say) is not a broken helper. An error reply without "id" is worse: `reply_to` passes it over as a stray, so the request waits the full 3 s and says "did not answer" (the helper's reply format is not in this repository, so whether its errors carry an id is unverified).
**Suggested action:** an error reply returns empty calls, keeps the helper, and does not set `failed_at`; only a missing or unreadable reply (timeout, 20 strays) stops it. In `reply_to`, accept an object with an "error" key and no id as the answer to the pending request.

### Finding 3: the wait is shorter, not gone (MEDIUM, residual of old finding 4)
**Where:** ask/bib_ask_helper.e:122 (`read_line (Wait_ms)`), 183-195 (`stop`: `close_input`, `wait_for_exit (2000)`, `kill`), 217-218; gui_app/bib_gui_app.e:4360-4366.
Worst cases on the UI thread now: a first request with a helper that never says "ready" = 5 s + 2 s (stop) = 7 s; a ready helper that never replies = 3 s + 2 s = 5 s, then silence for 60 s. The retry back-off removes the repeated freezes (old finding 4's second half), and the 3-second reply budget matches the measured 0.04-0.1 s replies. Not done: a worker or the "start at window open" suggestion, so the first request of a session still pays the model load on the UI thread. The 3 s `Reply_ms` also treats a cold or busy machine as a dead helper and disables Ask for a minute (finding 2's consequence).
**Suggested action:** start the helper at window open or first idle second; keep the waits; or move `ask` onto the existing SCOOP worker pattern.

### Finding 4: a crashed helper is not noticed (MEDIUM)
**Where:** ask/bib_ask_helper.e:160-162, 215-228.
`is_ready` stays True after the helper process dies between requests (no `is_running` check before `write_line`, as old finding 14 noted). The new `reply_to` loop then has two problems on that path: `read_line` returns Void at once when the pipe has ended (simple_piped_process.e:462-488: `last_line := Void` first, then `c_await`; whether `c_await` returns immediately on a closed pipe was not verified), the `l_stray` counter only counts lines that arrived (219-226), and there is no pause, so the loop can spin on the UI thread until `Reply_ms` (3 s) runs out before the "did not answer" message. The request is lost either way.
**Suggested action:** `if not al_process.is_running then off_reason := "The Ask helper ended."` before writing (is_running is in SIMPLE_PIPED_PROCESS); in `reply_to`, leave the loop when `read_line` gives Void and `is_running` is False.

### Finding 5: the asked parallel columns are sticky (MEDIUM)
**Where:** gui_app/bib_gui_app.e:3177-3182 (`parallel_versions`), 4349 (cleared only at the next Ask), 4425 (set), 3158-3168 (`show_parallel` and `fill_parallel` both use it).
Before the merge the reading version was always one column; now, when asked versions exist, they are the only columns. After "John 3:16 in the BSB and the YLT" the reader changes version, or opens Parallel from the menu or the right-click item (3359), and still gets BSB and YLT, not the version being read, until another Ask request runs. A single asked code gives a one-column parallel.
**Suggested action:** clear `asked_parallel_versions` after `fill_parallel` returns in `run_ask_call`, or when `go_to`/`on_version_change` runs for a reason other than Ask; and require at least two versions (or put the reading version first when only one is asked).

### Finding 6: the new fixes have almost no tests (MEDIUM)
**Where:** testing/test_facade_open.e, the added lines 760-769: seven assertions, all through BIB_ASK_CHECK (hyphen range, "good news", weather, "or", "without"). A grep of testing/ for BIB_WORD_CHARACTERS, may_start, reply_to, asked_search_scope, parallel_versions finds nothing.
Of the six previous HIGH fixes, tests exist for #3 and (through the check) #5; none for #1, #2, #4, #6. The window features need a window, but BIB_WORD_CHARACTERS (pure), `may_start`/`reply_to` (a stub helper script that prints a stray line, a wrong id, then the right id; one that sleeps past `Reply_ms`) and `parallel_versions` (a pure function of two lists once the reading state is passed in) can be tested headless. The tests added also show the earlier assertion text drift is fixed (old finding 22): the "web of lies" message at line 758 still reads "web of lies" for the input "Jude 5 commentary" (LOW, unchanged).

### Finding 7: `start` is less tolerant than `reply_to` (LOW)
**Where:** ask/bib_ask_helper.e:122-132.
`reply_to` skips strays; `start` takes exactly one line. If the helper (or libneedle) prints one non-JSON banner line on stdout before the ready object, Ask is off with "did not say it was ready within 5 seconds" although it answered at once. stderr is no longer merged (114), so this needs a stdout banner. **Suggested action:** loop in `start` until an object with "ready" or "error" arrives, sharing the loop with `reply_to` (one `next_object (a_process, a_wait_ms, a_matches)` feature).

### Finding 8: the retry window is silent (LOW)
**Where:** gui_app/bib_gui_app.e:4360-4388.
Checked as asked: when the helper exists, is not ready and `may_start` is False, neither start branch runs, `ask_helper.is_ready` is False, and the `elseif attached ask_helper as al_off` branch (4385) says "Ask is off: <off_reason>" and falls back to the box search. When `may_start` is True and the retry fails, `start` sets a fresh `off_reason` first (106-108), so the reason shown is the new one. So the window does still say why. Not said: that the next try is in up to 60 seconds. `ask_status` (4320-4332) shows the same reason. **Suggested action:** append "(tries again in about a minute)" when `may_start` is False.

### Finding 9: wrappers and a second loop around the new class (LOW, A5/M2)
**Where:** gui_app/bib_gui_app.e:1539-1549 (`is_word_character` wrapper, `word_characters` once) and 1551-1566 (`whole_word_after`: the same substring_index / neighbour test / retry loop as `has_whole_word`, but case-sensitive and returning a position); ask/bib_ask_check.e:437-447 (`has_word`, `word_characters` once), 470-474 (`is_word_character` wrapper).
Both clients delegate through a one-line wrapper plus their own `once`. The rule is now shared; the loop is not (`whole_word_after` needs the position and a start index).
**Suggested action (Larry's MI preference):** make BIB_WORD_CHARACTERS an effective ancestor that BIB_ASK_CHECK and the window's reading clause inherit side by side, so `is_word_character` and `has_whole_word` are inherited and the wrappers and `once` objects go; add `whole_word_index (text, word, from): INTEGER` (case-sensitive) and let `has_whole_word` and `whole_word_after` both use it. Effort: 2 features, 2 classes.

### Finding 10: contract gaps (LOW)
**Where:** ask/bib_ask_helper.e.
- `may_start` (74-78) and `reply_to` (208-232) have no postcondition. Useful ones: `reply_to`: `Result /= Void implies Result.item ("id") ... = a_id`; `may_start`: `is_ready implies not may_start`-style statements are not true (may_start is about retry, not state), so state it as `failed_at = 0 implies Result`.
- `stop` (183-204) has no postcondition that `off_reason` is non-empty afterward.
- The invariant (342-343) still says nothing about `is_ready implies process /= Void` (old LOW 20) and `failed_at >= 0`.
- src/text/bib_word_characters.e:30-51: `has_whole_word` has only `empty_never`; add `found_implies_substring: Result implies a_text.to_string_32.as_lower.has_substring (a_word.to_string_32.as_lower)`.

### Finding 11: the merge note says more than the code does (LOW)
**Where:** ask/bib_ask_check.e:264-273.
`joined_by` is whole-word now (296: `has_word`). The quoted-run mending still uses `has_substring` and `replace_substring_all` (265-266), and the "any form of / starting with / with any ending" tests still use `has_substring` (272-273, so "any form of lovely" matches the query word "love"). Old finding 7's first and third bullets stand. The `replace_substring_all` inside `joined_by` (298) also still replaces inside longer tokens. Not worse, but not fixed as the merge description reads.

### Finding 12: rule 11 phrases (LOW)
**Where:** ask/bib_ask_check.e:554-560.
"the web" refuses "the web of the spider" (Job 8:14 style requests); "news today" matches inside "good news today" (the new test covers only "good news in 1 Peter"). "online" and "internet" are still single words. Phrases are an improvement over the single words; tighten by requiring the phrase to stand without "good" before "news" (or test "the good news" first).

## Checked and found sound

- reply_to loop (ask/bib_ask_helper.e:208-232): the stray limit counts only lines that arrived (`l_stray > 20`, 217/225); the remaining wait is `Reply_ms - elapsed` with `.max (1)` (218), so a silent helper ends the loop at about 3 s and a read_line that returns early is retried with the remainder; `last_line` is reset to Void by `read_line` itself (simple_piped_process.e:473), so a stale line is never counted twice; a late reply after a timeout cannot shift later answers because the helper is stopped (175-176). `al_id.as_integer = a_id` compares INTEGER_64 with INTEGER, valid.
- Time arithmetic: `SIMPLE_MONOTONIC_CLOCK.elapsed_milliseconds` takes and returns INTEGER_64 (simple_datetime/src/simple_monotonic_clock.e:66-71 and the usage at 12-13 of its header), so `may_start` (77) compares INTEGER_64 with `Retry_ms` (INTEGER_64) correctly; `failed_at := clock.nanoseconds.max (1)` keeps 0 for "never".
- `start` / `stop` / `failed_at` pairing: `start` sets `failed_at` on every failed path (138-140) after `stop`; `ask` sets it after any `off_reason` (175-178); `start`'s postcondition `ready_or_said` holds on all four paths (missing file, not started, ready false, ready true).
- `on_ask` branching (gui_app/bib_gui_app.e:4360-4366): helper Void creates and starts; helper present, not ready and `may_start` starts again (precondition `not is_ready` holds); otherwise falls through to the "Ask is off" branch. No path starts a running helper.
- `parallel_versions` (3175-3205): asked codes are filtered by `has_version`; if none survive the old default list applies, so the reading version is not lost when the model proposes only unknown codes.

## Recommended Order

1. Finding 1 (asked book scope outlives the request): the only HIGH; a silent wrong-scope search, three-line fix.
2. Finding 2 (error reply locks Ask for 60 s): the back-off made a per-request error costly.
3. Findings 5 and 4: sticky parallel columns; dead-helper detection.
4. Finding 6: tests for BIB_WORD_CHARACTERS, parallel_versions and a stub-helper run of `reply_to` / `may_start`, before the next item builds on them.
5. Finding 3 (worker or start-at-open) when the UI-thread wait is next touched.
6. Findings 7-12 as one cleanup pass (shared `next_object`, MI parent for the word rule, contracts, whole-word mending of the quoted run, phrase tweaks).
