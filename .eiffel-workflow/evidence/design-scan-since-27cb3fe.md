# Design Scan (diff mode): simple_bible
# Since: 27cb3fe (Task 1, merge 92aa65b)
# Subjects: src/data/bib_source_set.e, testing/test_source_set.e, testing/test_app.e (14 lines)
# Compared against: all of src/ and testing/, plus simple_sql (simple_sql/src/simple_sql_database.e) and eiffel_sqlite_2025 (sqlite_database.e)
# Mode: read-only, nothing compiled, nothing edited

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Error mapping / resources | 3 | 1 | 2 | 0 |
| Design / duplication | 3 | 0 | 1 | 2 |
| Contracts / CQS / SCOOP | 3 | 0 | 0 | 3 |
| Tests | 3 | 0 | 1 | 2 |
| **Total** | **12** | **1** | **4** | **7** |

Whole-library comparison: BIB_SOURCE_SET is the ONLY class in src/ that creates or holds a
SIMPLE_SQL_DATABASE (grep of src/ and testing/ finds no other `make_read_only`, no other
`last_error_message`, no other creation of SIMPLE_SQL_DATABASE). BIB_CONTENT_SOURCE.open_on
(src/data/bib_content_source.e:86-92), BIB_PRIVATE_SOURCE.open_on (src/pack/bib_private_source.e:70-75),
BIB_USER_STORE.open_on (src/user/bib_user_store.e:267-270) and BIB_CONC_PACK are still Phase 4 stubs,
so no duplicated body exists yet; the findings name where the second copy will appear.

## Findings

| # | Priority | Category | Where | Opportunity |
|---|----------|----------|-------|-------------|
| 1 | HIGH | error mapping | src/data/bib_source_set.e:113 | `make_read_only` raises on open failure; open_core has no rescue, so `open_or_error` is not honored on that path |
| 2 | MEDIUM | error mapping | src/data/bib_source_set.e:180-195 | `close` leaves `core_path` and `sqlite_version` stale |
| 3 | MEDIUM | error mapping | src/data/bib_source_set.e:143-151 | attach reports every failure as Source_unavailable and has no probe for a non-database pack |
| 4 | MEDIUM | design | src/data/bib_source_set.e:99-131 | open_core is hard-wired read-only; BIB_USER_STORE (a real second implementor) needs read-write |
| 5 | MEDIUM | tests | testing/test_source_set.e:32 | hard-coded "3.53.4"; several paths untested |
| 6 | LOW | duplication | src/data/bib_source_set.e:62-68 | `is_valid_alias` restates simple_sql `is_valid_schema_name` |
| 7 | LOW | duplication | src/data/bib_source_set.e:209-219 | `sqlite_message` is not in simple_sql; keep, it is the future shared mapper |
| 8 | LOW | contracts | src/data/bib_source_set.e:175-178 | detach postcondition lacks the count clause attach has |
| 9 | LOW | CQS/SCOOP | src/data/bib_source_set.e:197-200 | `database` exported to ANY; one-processor rule is prose only |
| 10 | LOW | contracts | src/data/bib_source_set.e:138,163 | preconditions build an MML map for a membership test |
| 11 | LOW | tests | testing/test_source_set.e:130-158 | make_database / delete_file private to one class; two more users are coming |
| 12 | LOW | tests | testing/test_source_set.e:50-51 etc. | cleanup runs only if every earlier assertion passed |

## Detailed Findings

### Finding 1: open_core can raise instead of reporting (HIGH)
**Classes:** BIB_SOURCE_SET (src/data/bib_source_set.e)
**Evidence:**
- src/data/bib_source_set.e:110 guards only "file does not exist" via RAW_FILE.exists; line 113
  `create l_db.make_read_only (a_path)` then runs with no `rescue` anywhere in open_core (99-131).
- simple_sql `make_read_only` (simple_sql/src/simple_sql_database.e:64-77) has no rescue; it calls
  `internal_db.make_open_read`, whose `open_internal` ends in `sqlite_raise_on_failure (l_result)`
  (eiffel_sqlite_2025/sqlite_database.e:922-925, the else branch after sqlite3_open_v2 fails). An
  unreadable or unopenable path (permission denied, locked, a directory that passes `exists`) therefore
  raises an Eiffel exception out of open_core. (That a directory passes RAW_FILE.exists was not run.)
- Consequences: the postcondition `open_or_error` (127) is not honored on that path, the caller gets an
  exception where BIB_ERROR is meant to be "results, never control flow" (src/provenance/bib_error.e:2);
  `last_error` was set to Void at line 109 and stays Void while `is_open` is False, which breaks the
  contract of BIB_DATA_SOURCE.open_on (src/data/bib_data_source.e:108, 126) once it calls open_core.
- No test reaches it: test_open_core_not_a_database_reports (testing/test_source_set.e:66-80) uses a text
  file, which SQLite opens fine and rejects only at the query.
**Suggested fix:** add a `rescue` to open_core using the fleet pattern (local `l_failed: BOOLEAN`; in
rescue set `l_failed := True`, build the Database_problem BIB_ERROR from the exception description,
then `retry`; the `do` body skips the open when `l_failed`). Add tests that open a directory path and
a locked or permission-denied file, asserting `last_error /= Void` and `not is_open`.
**Effort:** 1 feature, 2 tests.

### Finding 2: close leaves stale state (MEDIUM)
**Evidence:** close (src/data/bib_source_set.e:180-195) resets `database`, `attached_paths` and
`is_open`, but not `core_path` (45), `sqlite_version` (56) or `last_error` (59). After close,
`core_path` still names the old file and `sqlite_version` is non-empty while the invariant (226-229)
is silent. A failed second open_core after a close (precondition `not_open` allows it) leaves the old
path and version, so `path_recorded` and `version_recorded` (128-129) are only vacuously true.
**Suggested fix:** reset core_path and sqlite_version in close and in the failure branches of
open_core; add postconditions `no_path: core_path.is_empty`, `no_version: sqlite_version.is_empty`
and an invariant `closed_has_no_path: not is_open implies core_path.is_empty`. Add a close-then-reopen
test (no current test reopens).
**Effort:** 1 feature, 1 invariant clause.

### Finding 3: attach error mapping is coarse and one path is unprobed (MEDIUM)
**Evidence:**
- attach (143-151) maps every simple_sql failure to `Source_unavailable`; open_core maps a failed
  query to `Database_problem` (122). A pack that exists but is corrupt or locked reports "could not be
  attached" with SQLite words but the wrong code; callers branching on `code` cannot tell missing from
  corrupt.
- open_core deliberately reads sqlite_master so "file is not a database" surfaces at open (comment at
  line 114). attach has no such probe. Whether ATTACH rejects a text file or a zero-byte file was not
  exercised; if it accepts one, the failure shows up at the first query on `alias.table`, outside
  `last_error`. Only the missing-file case is tested (testing/test_source_set.e:82-97).
- `error_mapped` (156) is `has_error implies last_error /= Void`, true by construction of the `if` at
  line 145; it does not state the code.
**Suggested fix:** after a successful attach, probe `SELECT count(*) FROM <alias>.sqlite_master`; on
failure detach and report Database_problem with SQLite message. Check RAW_FILE.exists first for the
Source_unavailable code, as open_core does. Strengthen the postcondition to name both codes. Add
tests for a text-file pack and a zero-byte pack.
**Effort:** 1 feature, 2 tests.

### Finding 4: open_core cannot serve the user store (MEDIUM)
**Evidence:** open_core (99-131) always calls make_read_only; its comment (108) says "No foreign-key
pragma: main is read-only". BIB_USER_STORE.open_on is documented "Open user.db read-write as the main
database of the user-store processor's own set" (src/user/bib_user_store.e:267-270). That is a real
second implementor with different needs (create if missing, read-write, foreign keys), and the class
note (src/data/bib_source_set.e:2-4) already says every engine processor owns a set.
**Suggested fix:** do not copy open_core into BIB_USER_STORE (that would be the second copy of the
version probe, error mapping and SQLite-message code). Factor the probe-and-adopt tail of open_core
(114-124) into a `{NONE}` routine and add `open_user (a_path)` beside open_core. A deferred ancestor is
not warranted: one class with two openers is enough. Decide with Larry before the BIB_USER_STORE task.
**Effort:** 2 features.

### Finding 5: tests fix the engine version and leave paths untested (MEDIUM)
**Evidence:** testing/test_source_set.e:32 asserts "3.53.4"; the next SQLite bump (the class note at
src/data/bib_source_set.e:12-14 already records one) fails a test that is about opening. Untested
paths of the subject: open on a directory or unreadable file (Finding 1), close then reopen
(Finding 2), attach of a non-database (Finding 3), the DR-020 limit (attach #10 succeeds, #11 is
blocked by the precondition at line 139), `is_valid_alias` (62-68) with "main", "temp", empty, upper
case, a leading digit, and `attached_path` of an unknown alias.
**Suggested fix:** assert `sqlite_version.starts_with ("3.")` and equality with a second
`SELECT sqlite_version()` on the same connection; add the listed tests.
**Effort:** 1 edit, about 6 tests.

### Finding 6: is_valid_alias restates simple_sql's rule (LOW)
**Evidence:** src/data/bib_source_set.e:62-68 versus simple_sql `is_valid_schema_name`
(simple_sql/src/simple_sql_database.e:665-678: alpha or underscore start, alphanumeric or underscore,
not main or temp, case-insensitive). BIB's rule is stricter (lowercase only, lowercase first letter),
so it implies simple_sql's precondition today, but nothing checks that they stay aligned.
**Suggested fix:** keep the stricter rule (BIB's alias table is case-sensitive, SQLite's is not) and
add one test asserting `is_valid_alias (x) implies db.is_valid_schema_name (x)` over a table of names.
**Effort:** 1 test.

### Finding 7: sqlite_message is not duplicated in simple_sql (LOW, informational)
**Evidence:** simple_sql offers `last_error_message: detachable STRING_32`
(simple_sql_database.e:95-106) and `last_error_code` (113-123) but no helper with a fallback. Other
fleet libraries read last_error_message directly (simple_kb/src/kb_database.e,
simple_oracle/src/simple_oracle.e). BIB_SOURCE_SET.sqlite_message (209-219) is the only
message-with-fallback mapper in simple_bible; three call sites use it (122, 147, 170). The detach call
passes the alias as the fallback (170), so with no SQLite message the details hold only the alias.
**Suggested fix:** none now. When the pack sources or the user store need the same mapping
(Finding 4), keep the BIB_ERROR construction in one `{NONE}` helper inside BIB_SOURCE_SET rather than
copying it. Moving a `last_error_message_or (a_default)` into simple_sql is a fleet decision.
**Effort:** 0 now.

### Finding 8: detach contract is thinner than attach (LOW)
**Evidence:** attach ensures count_grown (154) and error_mapped (156); detach (175-178) ensures only
`removed` and `kept_on_error`. Missing: `count_shrunk: last_error = Void implies attached_count = old
attached_count - 1`. simple_sql detach clears the previous error itself (simple_sql_database.e:644),
so no stale-error hazard.
**Suggested fix:** add the clause.
**Effort:** 1 contract edit.

### Finding 9: raw connection exported to every client (LOW)
**Evidence:** `database` (197-200) is exported to ANY. A client can call `database.close`,
`database.detach` or `database.attach_read_only` behind the set, after which `attached_paths` and
`is_open` disagree with SQLite and the invariant `connection_when_open` (229) cannot see it. The tests
use it (testing/test_source_set.e:37, 111); engines will need it. SCOOP: "one connection per
processor" (class note, lines 2-4) is prose only; passing the set to another processor makes it
`separate` and `database` returns a non-separate reference, so the compiler guards it indirectly.
Not a defect today.
**Suggested fix:** restrict to the engine classes and TEST_SOURCE_SET when the engines start calling it.
**Effort:** 1 export clause.

### Finding 10: precondition cost (LOW)
**Evidence:** attach precondition `not_attached` (138) and detach `is_attached` (163) build a fresh
MML_MAP (88-95) for a membership test that `is_attached_alias` (70-76) answers directly. At most 10
entries and contract builds only, so cosmetic (timing-trumps-contracts rule).
**Suggested fix:** use `is_attached_alias` in the preconditions; keep the model in postconditions.
**Effort:** 2 lines.

### Finding 11: test fixture will be copied (LOW)
**Evidence:** `make_database` (137-147) and `delete_file` (149-158) are `{NONE}` features of
TEST_SOURCE_SET. A grep of testing/ for `make_database|delete_file|RAW_FILE` finds only this class and
testing/source_scan.e (reads source text, line 37, different purpose), so no copy exists yet. Real
second users are coming: TEST_CONCORDANCE (testing/test_concordance.e:66 mentions attach) and
TEST_USER_STORE. Fleet rule: extract when the second implementor is real, so do nothing now; then move
both routines into a small mixin `TEST_DATABASE_FILES` inherited side by side with TEST_SET_BASE
(TEST_FIXTURES, testing/test_fixtures.e, is pure in-memory value builders and is not the right home).
**Effort:** 2 features, at the time of the second user.

### Finding 12: cleanup is not guaranteed (LOW)
**Evidence:** every test deletes its files as the last statements (lines 50-51, 79, 96, 126-127). If an
assertion fails first, files remain; make_database deletes first (142) so reruns recover, but a left-over
connection could keep a file locked on Windows. File names are relative (132-135), so they land in
the runner working directory, not testing/.
**Suggested fix:** when the fixture moves (Finding 11) add a shared cleanup routine and put the files
under a temp directory.
**Effort:** part of Finding 11.

## Checked and found sound

- CQS: `is_open`, `attached_count`, `attached_path`, `is_attached_alias`, `is_valid_alias`,
  `attached_model`, `sqlite_message` have no side effects; commands set `last_error` as the library
  convention; `model_agrees` (53, 75) ties the cached table to the model.
- attach and detach failure paths do not touch `attached_paths` (149, 172 run on success only);
  `unchanged_on_error` and `kept_on_error` (155, 177) state it; tests at 91-93 and 115-121 exercise it.
- open_core failure branch closes `l_db` (123) and leaves `is_open` False; the missing-file branch
  creates no connection.
- Invariant `nothing_attached_when_closed` (228) matches close (189).

## Recommended Order

1. Finding 1 (raise on open, no rescue): live defect against the stated contract, with tests.
2. Findings 2 and 3 with their tests (stale state; attach probe and code split).
3. Finding 4 before BIB_USER_STORE.open_on is written.
4. Findings 5, 8, 6, 10 as one small cleanup.
5. Findings 7, 9, 11, 12: no action until a second implementor or client appears.

## Status (2026-10-26, refactor/scan-26)

Fixed: HIGH 1 (open_core reports an open SQLite refuses: read_only_connection rescues make_read_only; test_open_core_folder_reports failed before), MEDIUM 2 (close clears core_path and sqlite_version; test_close_forgets_the_connection failed before). Open: MEDIUM 3 (a non-database pack is caught at Task 3 by check_pack, which reads user_version), MEDIUM 4 (read-write open for BIB_USER_STORE: extract when that second user is built), MEDIUM 5 (the 3.53.4 pin is deliberate, debate 04), and the LOWs.
