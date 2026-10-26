# Design Scan (diff mode): simple_bible since e06e6ed
# Subjects: Task 10 (bible_build.ecf, build/bib_content_builder.e, build_app/bib_build_app.e, testing/test_content_builder.e), Task 9 (simple_bible_app.ecf, cli/bib_cli_commands.e, cli_app/bib_cli_app.e, testing/test_cli_commands.e), simple_bible.ecf test target
# Method: read-only; nothing compiled or run. Every finding cites lines read in this scan.
# Compared against: all of src/, testing/source_scan.e, testing/test_layering.e, testing/conc_fixture.e, simple_file move_to, simple_cli/simple_console (greps only)

## Summary

| Priority | Count |
|----------|-------|
| HIGH | 4 |
| MEDIUM | 7 |
| LOW | 8 |
| Total | 19 |

## Verdicts on the questions asked

- RQ-01 layering: the engine ECF target is still clean (its own target lists only base, simple_mml, simple_sql, simple_file, simple_datetime; simple_bible.ecf:30-35). Including build/ and cli/ in `simple_bible_tests` does NOT add a forbidden library, and it actually pins build/ and cli/ to "no simple_cli" (that library is not in the test target, so a use would fail to compile). It DOES weaken the reverse guarantee (F1, F2).
- SQL in the builder: acceptable in the build pipeline (the engine only reads; the builder is the one writer), provided it stays out of src/. It should move behind a builder-side class once the second stage arrives (F9). No engine class is bypassed.
- EXCEPTIONS.die: ISE base; no simple_cli equivalent was found by grep, so acceptable in a root class only if resources are released first. They are not (F4).
- Builder failure paths: every SQL step is checked (one exception, F11), the temp file is removed on every failure before replace, verify() closes on both paths. Two real defects: F3 (replace) and F5 (gate too weak).

## Findings

| # | Priority | Where | Opportunity |
|---|----------|-------|-------------|
| F1 | HIGH | testing/test_layering.e:22-33, simple_bible.ecf:39-41 | Test target now compiles build/ and cli/, so an engine class referencing them passes the suite |
| F2 | HIGH | testing/source_scan.e:115-123, test_layering.e:96-107 | Layering scans never read build/ or cli/ (no purity check on the new clusters) |
| F3 | HIGH | build/bib_content_builder.e:185-192 | replace deletes the previous good content.db before the move; move failure loses it and leaks the temp file |
| F4 | HIGH | cli_app/bib_cli_app.e:307-331,354-358; build_app/bib_build_app.e:37,47 | die(1) skips l_bible.close; empty-string options violate preconditions instead of exiting 1 |
| F5 | MEDIUM | build/bib_content_builder.e:93-99,168-183 | Gate is the engine check only; zero books and broken foreign keys pass |
| F6 | MEDIUM | cli/bib_cli_commands.e:69-72 | Hidden coupling to the "conc:" source_key format (magic 6) |
| F7 | MEDIUM | cli/bib_cli_commands.e:133-149 | Bible-by-Bible aggregation lives in the face, not the engine |
| F8 | MEDIUM | cli_app/bib_cli_app.e:307-331 | Argument dispatch and exit codes untested (private in the root class) |
| F9 | MEDIUM | build/bib_content_builder.e:84-104,124-132 | DDL and SQL strings inline; schema knowledge in three places |
| F10 | MEDIUM | cli_app/bib_cli_app.e:296,319-325 | print of STRING_32 for Hebrew and Greek text (encoding unverified) |
| F11 | MEDIUM | build/bib_content_builder.e:94-96 | count query not error-checked |
| F12 | LOW | build/bib_content_builder.e:194-204 | delete ignores unlink result; unused l_ok; journal siblings not removed |
| F13 | LOW | build/bib_content_builder.e:105 | l_db.close result unchecked |
| F14 | LOW | cli_app/bib_cli_app.e:323 vs cli/bib_cli_commands.e:54 | Default corpus rule split between app and commands |
| F15 | LOW | cli_app/bib_cli_app.e:315 | Law of Demeter: a_commands.bible.conc_pack.is_available |
| F16 | LOW | cli/bib_cli_commands.e:81-83, 217-219, 182, 216 | Repeated headword/door line formatting |
| F17 | LOW | build/bib_content_builder.e:121 | Builder_name "bible_build 0.1.0" literal, not from BIB_RELEASE |
| F18 | LOW | testing/test_content_builder.e, test_cli_commands.e | Missing failure-path tests |
| F19 | LOW | bible_build.ecf:23-26 | Direct libraries also transitive (informational) |

## Detailed Findings

### F1 (HIGH): the engine can now depend on build/ or cli/ without a test failing
**Evidence:**
- simple_bible.ecf:39-41: the `simple_bible_tests` target (extends `simple_bible`) adds clusters `build` and `cli` beside `tests`.
- testing/test_layering.e:22-33 reads simple_bible.ecf as ONE string and checks only that no forbidden library name appears. It does not separate the library target from the test target and does not forbid a `build` or `cli` cluster in the library target.
- Before this change a src/ class naming BIB_CLI_COMMANDS or BIB_CONTENT_BUILDER would fail the test build (unknown type). Now the test target compiles those clusters, so the suite passes; the break shows only when bible_build.ecf or simple_bible_app.ecf is built (they use the library target alone).
- Mitigated: because simple_cli is absent from the test target, build/ and cli/ cannot use SIMPLE_CLI. That half is a real new guarantee.

**Suggested fix (testing only):** add to TEST_LAYERING (a) a test that no src/ file contains `BIB_CLI_`, `BIB_BUILD_`, `BIB_CONTENT_BUILDER`; (b) make the ECF test slice the text of `<target name="simple_bible">` up to its `</target>` and assert there is no `name="build"` or `name="cli"` cluster in it (the test target may have them).

### F2 (HIGH): purity scans do not cover the new clusters
**Evidence:** testing/source_scan.e:115-123: `Clusters` is "src" plus folders under src/. build/, cli/, build_app/, cli_app/ are never read, so `test_no_face_types_in_engine` (test_layering.e:96-107) and the banned-accessor test (test_layering.e:35-47) say nothing about them. cli/ is meant to be console-free text (cli/bib_cli_commands.e:5: "No argument parsing and no printing here") but nothing enforces it.

**Suggested fix:** a second scan list `Face_clusters = <<"cli", "build">>` and tests: cli/ and build/ contain no `print (`, `io.`, `SIMPLE_CLI`, `SIMPLE_CONSOLE`, `SW_`; cli/ contains no `SIMPLE_SQL_` (the face asks the engine, never the database). Keep the existing engine scans unchanged.

### F3 (HIGH): replace can destroy the last good content.db and leaks the temp file
**Evidence:** build/bib_content_builder.e:185-192: `delete (a_out)` first (failure ignored, see F12), then `move_to`. simple_file's move_to is `RAW_FILE.rename_file` (simple_file/src/simple_file.e:683-705), which does not overwrite, so the pre-delete is needed, but the order is unsafe. If the move fails (locked target, antivirus, cross-volume), the previous content.db is already gone, `last_error` is set, and `build` (lines 109-113) does NOT delete the temp, because the `else` branch only runs when `last_error` was set BEFORE replace. The postcondition `built_or_reported` (line 116) holds while the user has lost their file.

**Suggested fix:** replace = (1) if a_out exists, rename it to `a_out + ".old"`; (2) move temp to a_out; (3) on failure rename `.old` back and delete temp; on success delete `.old`. Or use the atomic replace-existing path simple_file documents (simple_file.e:8, 1410) if it exposes a move form. Always delete the temp when replace fails. Add a test: hold a_out open and check the old bytes survive and no `.tmp` remains.

### F4 (HIGH): exit-code paths skip cleanup; some bad input raises instead of exiting 1
**Evidence:**
- cli_app/bib_cli_app.e:354-358 `fail` is `(create {EXCEPTIONS}).die (1)`. `run` (line 307) is called while l_bible is open (line 298); every `fail` inside run (lines 316-317, 327-328) exits before `l_bible.close` (line 299). Process exit releases the handle, but engine close is skipped on every usage error.
- build_app/bib_build_app.e:244-248 passes `--bible ""` and `--out ""` straight to `build`, whose preconditions (bib_content_builder.e:70-71) reject empty paths: a contract violation (exception trace) instead of a usage message and exit 1. `--build-id ""` likewise hits `set_build_id` precondition `id_not_empty` (line 50).
- cli_app/bib_cli_app.e:320-321: `bible english ""` has a_args.count = 2, `joined` returns "", and `english` precondition `word_not_empty` (bib_cli_commands.e:116) is violated.
- Usage and errors go to stdout (`print`), not standard error (cli_app lines 275-277; build_app line 241).

**Suggested fix:** make `make` record an `exit_code` attribute and return, closing the bible in every branch, then call die once at the end of `make` (single exit point; die stays, since no simple_* wrapper was found; document the ISE use). Validate non-empty option values and the joined english word before calling contracted routines. Write failures to standard error or state why stdout is intended.

### F5 (MEDIUM): the gate passes a content.db with no books or bad references
**Evidence:** build/bib_content_builder.e:168-183 `verify` runs only BIB_CONTENT_SOURCE.open_on (version, required tables, provenance_key columns, build_run row; src/data/bib_content_source.e:86-118). `books_written` (line 95) may be 0 (empty `bible_books`) and the build still succeeds and replaces a good file. Foreign-key validity of `book_catalog.provenance_key` is declared (line 130) but never checked.

**Suggested fix:** after the count, fail with "bible.db lists no books" when 0; run `PRAGMA foreign_key_check` and `PRAGMA integrity_check` before close and report any row.

### F6 (MEDIUM): hidden coupling to the provenance key format
**Evidence:** cli/bib_cli_commands.e:69-72 strips "conc:" from `provenance.source_key` with `substring (6, ...)`. The prefix is created in src/concordance/bib_conc_pack.e:516 (`{STRING_32} "conc:" + a_code`). Further: when a headword's corpus is not listed, `provenance_of_id` falls back to `first_provenance` (bib_conc_pack.e:540-560), whose key may be the bare `"conc"` (no colon), so the command line would answer `no corpus conc`.

**Suggested fix:** add to BIB_CONC_PACK a query `top_corpus_code (a_lemma_id: INTEGER_64): STRING_8` (postcondition: empty or `has_corpus (Result)`), tested in the pack suite; the command uses it. If the key must stay parseable, define `Provenance_prefix` beside the code that builds it. Remove the magic 6.

### F7 (MEDIUM): per-Bible aggregation belongs in the engine
**Evidence:** cli/bib_cli_commands.e:133-149 sums BIB_ENGLISH_ROW counts per Bible and headword in a HASH_TABLE keyed on a display string (line 137). BIB_ENGLISH_INDEX.rows (src/concordance/bib_english_index.e) returns the per-book rows (FR-151). A GUI face would repeat the fold, and keying on a formatted string couples logic to layout.

**Suggested fix:** add `BIB_ENGLISH_INDEX.totals (a_word)` returning rows summed by (bible, lemma_id), postcondition: summed counts equal the sum over `rows`. The CLI only formats. A query on an existing class, not a new abstraction.

### F8 (MEDIUM): dispatch and exit codes untested
**Evidence:** cli_app/bib_cli_app.e:307-331 holds all argument validation (word: 2 args and positive integer_64; verse: 4 positive integers; english joins the rest; strongs: 2). testing/test_cli_commands.e covers only the text routines. `run` is `{NONE}` in the root class.

**Suggested fix:** move dispatch into cli/ (for example `BIB_CLI_COMMANDS.dispatch (a_args, a_corpus): STRING_32` with `last_exit_code`), leaving BIB_CLI_APP to parse options and print. Test: unknown command, `word abc`, `word 0`, `verse 1 1`, `verse 1 -1 1`, `english` with no word, with and without the pack.

### F9 (MEDIUM): SQL and schema knowledge inline in the pipeline class
**Evidence:** build/bib_content_builder.e:91-92, 101, 104 are SQL strings inside `build`; lines 124-132 are the DDL as a public `Schema` constant. Grep finds CREATE TABLE source_provenance/build_run only here and in testing/conc_fixture.e, and the required-table list is in src/data/bib_content_source.e:151: three copies of the content.db v1 shape that can drift.

**Layering rule:** "no SQL outside the engine" is met in spirit (the engine side is read-only; the builder is the pipeline). Not a defect today. When the second stage (FR-130 core, AI-data, author-library) lands, put DDL and the step runner (`run`, `note_failure`) behind one builder-side class (for example BIB_CONTENT_WRITER with `create_schema`, `insert_provenance`, `finish`). Do not extract an ancestor before a second implementor exists. Make `Schema` `{NONE}` unless the fixture should share it, in which case expose it from the builder instead of copying.

### F10 (MEDIUM): console text encoding for Hebrew and Greek
**Evidence:** cli_app/bib_cli_app.e:296, 319-325 call `print` on STRING_32 holding Hebrew/Greek headwords and transliterations (cli/bib_cli_commands.e:81-83, 92-96). ISE `print` of non-Latin-1 STRING_32 on a Windows console is unreliable; tests compare in-memory strings, so it is untested.

**Suggested fix:** an output helper in BIB_CLI_APP that encodes to UTF-8 (`{UTF_CONVERTER}`) and sets the console code page, then verify by running the exe on a Hebrew word (not done: read-only scan). cli_app is a face, so using simple_console there is allowed; the ban is on the engine.

### F11 (MEDIUM): count query not checked
**Evidence:** build/bib_content_builder.e:94-96: the `query` is followed by no `note_failure`; on error `books_written` stays 0 and the next step (`detach`, line 97) clears the error flag, so the failure is lost. The comment at line 147 says every step is checked.

**Suggested fix:** `note_failure (l_db, "The book count could not be read")` straight after the query.

### F12 (LOW): delete ignores failure, dead local, journal files
build/bib_content_builder.e:194-204: `l_ok` is assigned, never read; `unlink` failure is silent (feeds F3). A failed build may leave `-journal`/`-wal`/`-shm` siblings of `.tmp` (line 112 deletes only `l_temp`). Fix: make `delete` return BOOLEAN, fail the build when a stale temp (line 82) cannot be removed, and remove the siblings.

### F13 (LOW): close not checked
build/bib_content_builder.e:105 `l_db.close`: add `note_failure` after it for a clearer message than the later verify failure.

### F14 (LOW): default corpus split
`word` resolves an empty corpus itself (cli/bib_cli_commands.e:67-73), while `verse` gets the literal `"WLC-MACULA"` from the app (cli_app/bib_cli_app.e:323). A GUI would repeat the literal. One constant on BIB_CLI_COMMANDS, and let `verse` accept empty.

### F15 (LOW): Law of Demeter in the app
cli_app/bib_cli_app.e:315 `a_commands.bible.conc_pack.is_available`; the same expression is in four preconditions (bib_cli_commands.e:57,115,158,196). Add `is_available` to BIB_CLI_COMMANDS.

### F16 (LOW): repeated formatting
`translit - headword` at bib_cli_commands.e:81-83 and 217-219; `[word N]` at 182 and 216. Private helpers `heading_text` and `door_text`; local, no ancestor.

### F17 (LOW): builder version literal
build/bib_content_builder.e:121 `"bible_build 0.1.0"` also serves as the app version (build_app/bib_build_app.e:233) while the CLI uses `{BIB_RELEASE}.Engine_version` (cli_app/bib_cli_app.e:268). The value is written into the build row, so changing it changes the bytes the byte-identical test compares; comment that and move it to BIB_RELEASE.

### F18 (LOW): test gaps
testing/test_content_builder.e covers success, byte-identical rebuild, missing bible.db, missing table (temp removed). Not covered: engine-check failure (verify, lines 177-179), move failure (F3), empty `bible_books` (F5), an existing a_out replaced by a good build, a stale `.tmp` at start. testing/test_cli_commands.e: no `banner` without a pack or with a pack error, no `word` on a headword whose corpus is unlisted (F6). `finish` is not reached when an assertion fails, so fixture files can be left behind.

### F19 (LOW, informational): ECF library lists
bible_build.ecf:23-26 lists simple_sql, simple_file, simple_datetime that the builder itself uses (SIMPLE_SQL_DATABASE, SIMPLE_FILE, SIMPLE_DATE_TIME), so keeping them is correct. UUID uniqueness of the three ECFs was not checked (run `claude_tools uuid scan` if wanted).

## Checked and found fine
- Contracts on public features: `build`, `set_build_id`, `word`, `english`, `verse`, `strongs`, `banner` all have require/ensure; `not_empty` postconditions hold (every branch appends text).
- CQS: `build` is a command with queries `last_error`, `books_written`; `build_time` is a pure query.
- Invariants: neither class has one, so none is non-O(1); `books_written >= 0` could be added.
- SCOOP: no separate objects introduced; ECFs declare scoop and full void safety. `Schema` is an immutable once array.
- Strings: STRING_32 for stored text, STRING_8 for SQL and codes; conversions use non-obsolete `to_string_32` / `to_string_8`. Narrowing at cli/bib_cli_commands.e:213 (`l_key.text.to_string_8`) is safe because the key was validated as ASCII.
- verify() closes: on failure `open_on` leaves the set closed (bib_content_source.e:89, 122-124); on success set and source are closed (lines 180-181) before the move, so the file is not locked.
- Fleet rule (abstraction only with a real second implementor): no new deferred class is proposed. F6 and F7 are queries on existing classes; F9 waits for a second stage; F15/F16 are local helpers.

## Recommended Order
1. F3 (data loss) with its test (F18)
2. F4 (cleanup, validation) together with F8 (move dispatch into cli/)
3. F1 and F2 (layering tests; cheap, test-only)
4. F5, F11 (gate strength)
5. F6 (pack query), then F7
6. F10 (verify output encoding by running the exe)
7. F9 when the second pipeline stage begins; LOW items as convenient

## Status (2026-10-26, refactor/scan-31)

Fixed: F3 (the builder sets the previous content.db aside and restores it if the move fails; the temporary file never stays; test failed before), F4 (both programs validate their arguments, close the engine on every path and exit once; checked by running them: empty --bible, english "", a missing conc.db all exit 1 with a message), F1 (the ECF guard reads only the engine target; src never names a build or face class), F2 (cli/ is checked for SQL and GUI or console libraries). Open: F5 (the content gate accepts zero books, no foreign-key check), F6 (BIB_CLI_COMMANDS reads the corpus code out of a provenance key: a pack query would remove the coupling), F7-F11 and the LOWs.
