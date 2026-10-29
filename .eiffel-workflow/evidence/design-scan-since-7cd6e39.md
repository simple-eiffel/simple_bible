# Design Scan (diff mode): simple_bible, since 7cd6e39
# Mode: read-only, nothing compiled or run. Every line number was read in the working tree at HEAD.
# Subjects: ask/bib_ask_helper.e (last_error, reply_to has_exited), gui_app/bib_gui_app.e (run_ask_call, asked_search_scope), testing/test_facade_open.e (Ask tests)
# Compared against: all of src/, ask/, gui_app/, cli/, testing/
# Previous scan: .eiffel-workflow/evidence/design-scan-since-5230360.md

## Verdict on the previous HIGH

Finding 1 of design-scan-since-5230360 (asked_search_scope outlives its request): RESOLVED.
- gui_app/bib_gui_app.e:4457 sets the scope; 4459 runs `on_search`; 4462 clears it. `on_search` is fully synchronous: every branch that reads the scope does so through `find_verses` (1056, 1062, 1076), which reads `search_scope` once at 5248 before any deferred work. So the one search sees the book and no later search can.
- The other clears stay: `on_ask` (4350) and `on_scope_change` (640). The postcondition `scope_not_kept` (4464-4465) is the tripwire.
- Residual (finding 1 below): the clear is not exception-safe. The version-change half of the old finding is moot now, since the scope no longer lives across a version change.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / contracts | 4 | 0 | 2 | 2 |
| MI | 0 | 0 | 0 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| **Total** | **4** | **0** | **2** | **2** |

## Findings

| # | Priority | Subject | Opportunity |
|---|----------|---------|-------------|
| 1 | MEDIUM | run_ask_call | scope_not_kept holds on every normal path but not on an exception path, and nothing tests it |
| 2 | MEDIUM | on_ask / BIB_ASK_HELPER | last_error is never shown or logged; the reader and the log see "rule 0: no tool fits" |
| 3 | LOW | reply_to | a helper that wrote its reply and then exited loses the reply |
| 4 | LOW | BIB_ASK_HELPER | contract gaps: last_error and calls not tied together by contract |

## Detailed Findings

### Finding 1: scope_not_kept is not exception-safe, and no test covers it (MEDIUM)
**Where:** gui_app/bib_gui_app.e:4404-4466.
Checked on every path of `run_ask_call`:
- Branches other than `search_text` (4416-4441) never touch the scope; it is Void on entry because `on_ask` clears it at 4350 and `run_ask_call` has one caller (4377). The postcondition holds, but only through that caller; there is no precondition saying so, and a different caller that left a scope set would break the postcondition.
- `search_text` with a named range (4447-4453): never sets the scope, cleared again at 4462. Holds.
- `search_text` with a book (4455-4457): set, `on_search`, cleared. Holds.
- If `on_search` raises (index missing, database error), 4462 is skipped and the postcondition is not reached: the scope stays set and the next typed search runs in that book while the list says "Whole Bible" - the old HIGH again, by the exception route.
- `scope_select.select_index (1)` (4446) can fire the scope-change handler (544), which runs a search with the old search box text before the asked scope is set; older behavior, only noted.
- testing/test_facade_open.e has no test that reaches `run_ask_call` or `asked_search_scope` (grep finds none), so the fix rests on the one postcondition.
**Suggested action:** pass the asked scope to the search as an argument instead of holding it in an attribute (nothing can then outlive anything), or set/search/clear inside one routine with a rescue that clears. Add `require scope_clear: asked_search_scope = Void`.
**Effort:** small.

### Finding 2: a per-request error is invisible (MEDIUM)
**Where:** ask/bib_ask_helper.e:63-67, 168-173; gui_app/bib_gui_app.e:4368-4374.
The helper now keeps running after an error reply and `calls` is empty (created at 161). The window then takes the `l_calls.is_empty` branch: `l_check.checked` is given an empty list and refuses with rule 0 "no tool fits" (ask/bib_ask_check.e:76-77), `log_ask` records "rule 0" with an empty call text, and `ask_fallback` searches the typed words. The behavior is correct (reader gets the plain search, Ask stays on) but the reason is lost: `last_error` is read only by the test (testing/test_facade_open.e:803). A 2100-character request is logged as "no tool fits".
**Suggested action:** in `on_ask`, when `al_helper.last_error` is not empty, `say` it and give it to `log_ask` instead of `l_check.refusal`.
**Effort:** 3 lines.

### Finding 3: reply_to gives up on an exited helper before reading its pipe (LOW)
**Where:** ask/bib_ask_helper.e:226 and 239-242.
The loop condition tests `a_process.has_exited` before the first `read_line`. `has_exited` is `is_started and not is_running` (simple_process, src/simple_piped_process.e:216-218). A helper that writes its reply and exits at once leaves the reply in the pipe unread, and the request reports "The Ask helper stopped." The normal helper stays alive, so this is an edge. The message is set only when `off_reason` is still empty by the `Result = Void` test, so it does not overwrite the stray-lines message (239-242 is an if/elseif).
**Suggested action:** on `has_exited`, do one last `read_line` with a minimal wait before declaring it dead.
**Effort:** 2 lines.

### Finding 4: contracts do not state what the new field means (LOW)
**Where:** ask/bib_ask_helper.e:63-67, 155-185, 354-355.
- `ask` has only `calls_only_while_ready` (183). Add `error_means_no_calls: not last_error.is_empty implies calls.is_empty` (true on every path: `calls` is created empty at 161 and only `read_calls`, in the non-error branch, fills it).
- The invariant (355) is still only `off_or_ready`. `last_error` is stale after `stop` until the next `ask`; harmless, since `ask` resets it at 161.

## Checked and found sound
- `last_error` initialization: attribute clause with `create Result.make_empty` (63-67) plus `create last_error.make_empty` at 161; the `as_string_32` assignment at 173 matches the STRING_32 type.
- An error reply does not set `off_reason`, so the `if not off_reason.is_empty` block (177-180) is skipped: the helper stays on and `failed_at` is not set, so `may_start` is not locked for 60 seconds. This resolves the previous scan's finding 2 for replies that carry the request id (an error reply without an id is still passed over as a stray, unchanged).
- `on_ask` after an error: `al_helper.is_ready` stays True (4371), so the branch is `l_calls.is_empty` and the fallback; it does not print "Ask is off".
- New tests (testing/test_facade_open.e:760-762, 801-805): Greek-word and whole-word checks, and a 2100-character request giving `last_error` non-empty, still ready, no calls. They assert the stated behavior; they do not exercise the window side.

## Recommended Order
1. Finding 2 (3 lines, makes the new field useful).
2. Finding 1 (exception safety, or drop the attribute by passing the scope to the search).
3. Findings 4 and 3 with the next touch of the helper.
