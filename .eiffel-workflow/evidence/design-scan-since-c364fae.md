# Design Scan (diff mode): simple_bible since c364fae (release 0.7.32, the ingest kit)
# Date: 2026-10-29
# Mode: read-only; nothing compiled, nothing run. Every finding cites lines that were read.
# Subjects: ingest/bib_ingest_kit.e, ingest/bib_note_importer.e, src/pack/bib_note_schema.e,
#   src/reading/bib_name_list.e, src/reading/bib_suggestion_line.e, src/pack/bib_text_pack_schema.e,
#   src/pack/bib_book_pack.e, src/pack/bib_book_block.e, build/bib_book_builder.e,
#   src/reading/bib_book_abbreviations.e, cli/bib_cli_commands.e, cli/bib_data_location.e,
#   gui_app/bib_gui_app.e (ingest kit clause, chapter_page, fill_in_books, Ask tick), both ecf files,
#   the spec .eiffel-workflow/research/21-INGEST-KIT.md, and testing/test_facade_open.e (the new test).
# Compared against: build/bib_markdown_blocks.e and the rest of src/.

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 5 (findings 1-5) |
| MEDIUM | 10 (findings 6-15) |
| LOW | 6 (findings 16-21) |
| **Total** | **21** |

## Findings

| # | Priority | Category | Where | Finding |
|---|----------|----------|-------|---------|
| 1 | HIGH | D1 | importer vs builder | A suggestion passes the importer as a LINE but the builder only reads it as a whole BLOCK |
| 2 | HIGH | D1 | BIB_BOOK_PACK.blocks_suggesting | Reasons come from a second query with different joins and filters; they can attach to the wrong block |
| 3 | HIGH | safety | bib_gui_app import_note | Close, delete, rename, reopen: failures ignored; engine or notes pack can be lost |
| 4 | HIGH | data loss | BIB_NOTE_IMPORTER.write_files | Old chapter files deleted before the new note is known good; a failed build leaves a poisoned manifest |
| 5 | HIGH | D1 | importer vs BIB_MARKDOWN_BLOCKS | Fence readers disagree (tilde fences, fence length) |
| 6 | MEDIUM | correctness | importer read_header / is_accepted | `sbn` not required; a header-only file is refused with no reason |
| 7 | MEDIUM | correctness | importer check_links | Links inside inline code are checked (false refusals) |
| 8 | MEDIUM | correctness | pack, builder, GUI | One block listed twice; suggestions on code blocks never shown on the page; suggestion after a heading goes to the wrong paragraph |
| 9 | MEDIUM | perf | importer check_body, import_note | The name list (every book loaded) is built on every read, twice per import |
| 10 | MEDIUM | A5 | importer, markdown blocks | Fence toggling written six times (abstraction half of finding 5) |
| 11 | MEDIUM | A5 / A6 | BIB_BOOK_BUILDER.write_book | Chapter loop is one long feature; suggestion handling changes numbering for books and essays too |
| 12 | MEDIUM | A6 | bib_gui_app ingest clause | The swap sequence and kit file naming live in the window class |
| 13 | MEDIUM | contracts | several | Missing postconditions where the code relies on an invariant |
| 14 | MEDIUM | tests | test_facade_open.e | One happy-path test; none of the failure paths the checks exist for |
| 15 | MEDIUM | spec drift | spec vs code | Checks the spec names that the code does not make; "fourth" kind |
| 16 | LOW | edge | importer id | Windows device names and unbounded length are valid ids |
| 17 | LOW | edge | importer `source` | Header `source` becomes a path read beside the file |
| 18 | LOW | edge | forms_of | Equal-length forms come out in hash order |
| 19 | LOW | edge | chapter_page | A reason is written into Markdown unescaped |
| 20 | LOW | edge | importer problems | Header problems always say line 1; numbers are of the unwrapped text |
| 21 | LOW | A5 | `trimmed`, `Format_version` | Small duplicates |

## Detailed Findings

### Finding 1: a suggestion is checked as a line, stored as a block (HIGH, D1)
**Classes:** ingest/bib_note_importer.e, build/bib_book_builder.e, build/bib_markdown_blocks.e
**Evidence:**
- ingest/bib_note_importer.e:296-297 and 340-354: the importer takes each LINE, trims it and calls `suggestions.parsed`; a line that is a whole suggestion passes.
- build/bib_book_builder.e (write_book, the new `attached suggestions.parsed (l_blocks.blocks.i_th (l_block).markdown)`): the builder parses a whole BLOCK's markdown.
- build/bib_markdown_blocks.e:107-138: only a blank line ends a paragraph; the comment at 138 says a following line is "a continuation of a paragraph".
- So "Some paragraph." followed directly (no blank line) by `{{suggest: Jude 9 | why}}` is ACCEPTED by the importer (the line stands alone) but the block's markdown is two lines, `parsed` returns Void (it needs the text to START with the opening and have exactly two `{`), the text is stored as paragraph text, the linker links "Jude 9" as a CITATION, and the reader sees the raw `{{suggest:` text. The spec's point (suggestions "never mixed with citations") fails silently. The same happens for a suggestion directly before a paragraph.
- The kit's example (ingest/bib_ingest_kit.e:110) has blank lines, but instruction 5 (line 94) says "on a line of its own right after that paragraph", which invites the adjacent form.
- The one test (testing/test_facade_open.e, Prepared_note) always has blank lines around the suggestion.
**Suggested Action:** make the importer check the unit the builder reads: either refuse a suggestion line without a blank line on both sides (a named problem) or normalize in `read` (insert blank lines around each standalone suggestion line before `split_chapters`, so the kept chapter files carry them). Put the rule in BIB_SUGGESTION_LINE so importer and builder share it. Add a test with adjacent lines.
**Effort:** 1 feature + 1 test

### Finding 2: reasons aligned with blocks by position across two queries (HIGH, D1)
**Classes:** src/pack/bib_book_pack.e
**Evidence:**
- bib_book_pack.e:144-161 (`blocks_suggesting`): the blocks come from `blocks_answer` over `blocks_sql` plus a JOIN on block_suggestion (inner joins to book, book_block and book_chapter, lines 237-243); the reasons come from a SECOND query (`SELECT s.reason ... JOIN book k ... ORDER BY k.ordinal, s.chapter, s.block, s.ordinal`) and are matched to blocks by index.
- The two row sets differ when: (a) a suggestion's block row does not exist (the builder's chapter-of-headings fallback `write_suggestion (..., l_number.max (1), ic)` writes block 1 for a chapter that wrote no block: an orphan the second query returns and the first drops); (b) `blocks_answer` skips rows failing its id and range checks (bib_book_pack.e:263-266, "passed over") while the reasons query does not; (c) a book_chapter row is missing. After one such row every later block gets the wrong reason. The loop condition `i > Result.count or i > l_reasons.count` hides a length mismatch rather than failing.
- Two suggestions on one block that both cover the verse return that block twice (one join row per suggestion), contrary to `blocks_citing`'s "each block once".
**Suggested Action:** select the reason in the SAME statement as the block columns and read both from one row (a `blocks_answer` variant taking a reason column). Add a postcondition: a successful result has a non-empty `suggestion_reason` on every block (the importer refuses empty reasons). Decide whether a block with several reasons shows once.
**Effort:** 1 feature; the second query goes away

### Finding 3: import_note's close / swap / reopen has no failure path (HIGH)
**Classes:** gui_app/bib_gui_app.e
**Evidence:** bib_gui_app.e:4439-4444 runs `bible.close`, then deletes the old notes.db if present, then `rename_to`, then `bible.open`. `l_ok` is assigned twice and never read.
- Delete fails (another handle, a scanner) -> the rename onto an existing file fails -> `bible.open` opens the OLD pack, and the message at 4452 still says "Imported ... N paragraphs" from the build that was discarded.
- Delete succeeds, rename fails -> no notes.db at all; the previous notes pack (search, links, every earlier note) is gone until another import; the message still says Imported.
- `bible.open` has `ensure open_or_error` (src/simple_bible.e:111): it may leave the engine CLOSED with `last_error` set, for instance when the pack folder now holds more than `Max_generic_packs` (9) packs (src/simple_bible.e:92 and 596) because notes.db is a new file there. The code goes on to `fill_books`, `show_book_place` and `say` on a closed engine, and the commentary, history and search panes are left closed with no explanation.
- A failed build leaves `notes.db.new` in the pack folder (never removed; it is not counted as a pack, only litter).
- The swap uses BIB_DATA_LOCATION.pack_folder (line 4428) on the assumption that the open engine attached from the same folder (set at line 39).
**Suggested Action:** a small swap helper (see finding 12): keep the old file as `notes.db.old`, rename, check every step, reopen, and on any failure restore `.old`, reopen and say what happened; check `bible.is_open` after `open` and stop the UI refresh when it is closed; remove the `.new` on build failure.
**Effort:** 1 new class, 1 feature rewritten

### Finding 4: write_files deletes before it knows the new note is good (HIGH, data loss)
**Classes:** ingest/bib_note_importer.e, gui_app/bib_gui_app.e
**Evidence:**
- bib_note_importer.e:153-156: when `<notes>/<id>/` exists, every `.md` in it is deleted first; the new chapters are written afterwards (161-167). A write failing midway (disk full, locked file) leaves the earlier version of the note half deleted and returns False, and the old manifest (written only at line 175) still names files that are gone. Same-id replacement is a decided feature (spec "Decided" 3), and no copy of the earlier version is kept.
- bib_gui_app.e:4431-4434: `write_files` runs BEFORE `build`. If `build` fails (a bad manifest, a count over Max_part), the new files and manifest stay in the folder, and `BIB_NOTE_IMPORTER.build` rebuilds from EVERY manifest there (lines 190-197): every later import of any note then fails the same way, until the user finds the folder by hand.
- The deletion is confined to `<notes>/<id>/` and `id` is validated lowercase letters and digits (line 263), so other files in the notes folder are not at risk from the id; the risk is the replaced note itself.
**Suggested Action:** write the new chapters into a staging folder and the manifest as a `.new` file, swap (old to `.old`, new into place) only after the build into `notes.db.new` succeeded, and restore the old note when the build fails. Make `write_files` plus `build` one `keep` operation.
**Effort:** 2 features

### Finding 5: fence readers disagree (HIGH, D1)
**Classes:** ingest/bib_note_importer.e, build/bib_markdown_blocks.e
**Evidence:**
- Importer: check_body (292), split_chapters (369) and unwrapped (435) treat any line starting with three backticks OR three tildes as a fence TOGGLE, whatever the fence's length or character.
- build/bib_markdown_blocks.e:96 and 102: block splitting recognizes ONLY backtick fences. (The comment stripper at 368 knows both.)
- Effect 1: inside a tilde fence the importer skips the link and suggestion checks, but the builder sees ordinary paragraphs there; a disallowed `[x](nowhere)` or a `{{suggest: ...}}` line inside a tilde fence passes the importer and is then linked or stored as a suggestion by the builder. A construct the builder ignores disables the importer's checks.
- Effect 2: a four-backtick block holding a three-backtick line (the kit's own example does this, ingest/bib_ingest_kit.e:109-111) is closed early by the importer; the lines after are then checked as body (false refusals) and a `# ` line in the sample splits the chapters.
- Effect 3: `unwrapped` accepts a start of one fence character and an end of the other and strips both.
**Suggested Action:** one fence reader following CommonMark (the closer is the same character and at least as long as the opener), used by the importer and by BIB_MARKDOWN_BLOCKS (both loops and the comment stripper), so the importer's view and the builder's cannot differ. Tests for a tilde fence and a nested longer fence.
**Effort:** 1 new class, six call sites

### Finding 6: header completeness (MEDIUM)
**Evidence:** bib_note_importer.e:239-242 checks `sbn` only IF the line is present; a header with no `sbn` passes, while the kit says "(always)" (ingest/bib_ingest_kit.e:105). Lines 261-267: an elseif chain, so only ONE of "id" and "title" is reported per read. `is_accepted` (66-70) is False for a header-only file (no chapters) while `problems` is EMPTY, so the GUI's refusal page (bib_gui_app.e:4421) lists nothing. `read`'s postcondition (126-128) covers `is_accepted implies chapters` but not `not is_accepted implies not problems.is_empty`.
**Suggested Action:** require `sbn`; add a problem "no text after the header" when no chapter results; add the postcondition.
**Effort:** 3 small edits

### Finding 7: links in inline code (MEDIUM)
**Evidence:** bib_note_importer.e:304-322 scans every `](` outside a fence, so a link written inside an inline code span is checked as a real link and refused (a source about Markdown, or an AI showing its own markup). Indented code blocks are not recognised.
**Suggested Action:** blank out inline code spans before scanning; BIB_MARKDOWN_BLOCKS's comment stripper has the same need, so share it.
**Effort:** 1 feature

### Finding 8: duplicate rows and invisible suggestions (MEDIUM)
**Evidence:**
- bib_gui_app.e:4302-4318 (`fill_in_books`): a block that cites the verse AND carries a suggestion for it appears twice (citing list, then suggesting list); the second row says "Suggested (...)" about text that cites the verse.
- build/bib_book_builder.e (new loop): `l_last_text` is set for any kind that is not "heading", including "code"; bib_gui_app.e:4262-4284 (`chapter_page`) prints suggestions only in the final `else` branch, so one attached to a code block (the 4269 branch) or to the headings-only fallback is never shown on the page, while the verse list shows it.
- A suggestion straight after a heading and before the first paragraph is attached to the NEXT paragraph (the "pending" list), while the spec and kit say "right after that paragraph".
**Suggested Action:** attach to paragraphs and items only; show on the page for every kind but heading; drop the citing block from the suggested list.
**Effort:** 3 small edits

### Finding 9: the name list on every read (MEDIUM, performance)
**Evidence:** bib_note_importer.e:288 builds the list once per `read` (two BIB_NAME_LIST objects created, `names` called once). `names` (src/reading/bib_name_list.e:236-274) calls `ic.book (id)` for EVERY book of every pack (a query and a chapter list each; the spec counts 1,547 names). `import_note` reads twice when a source file sits beside the prepared file (bib_gui_app.e:4411-4416), so the list is built twice per import; the kit builds it again (ingest/bib_ingest_kit.e:58).
**Suggested Action:** build the link set once per importer and let `read` take the source text in one call so `import_note` does not call it twice.
**Effort:** 1 feature + GUI call

### Finding 10: fence toggling written six times (MEDIUM, A5)
Importer lines 292, 369, 435 and build/bib_markdown_blocks.e lines 96, 102, 368 each decide "is this line a fence" in their own words. Extract as in finding 5; this is the abstraction half.

### Finding 11: write_book's chapter loop (MEDIUM, A5 / A6)
**Evidence:** build/bib_book_builder.e `write_book`: the loop body (from `l_number := 0`) is about 40 lines with `l_blocks.blocks.i_th (l_block)` written eight times, suggestion bookkeeping (`l_last_text`, `l_pending`) beside block insertion, search row and index writes, and a tail loop for pending suggestions. It runs for books and essays as well as notes, so a literal suggestion line in a book or essay now changes their block numbering (the line is removed from the numbering for every schema), which no spec asks for.
**Suggested Action:** extract `write_block` and a helper object holding `last_text` and `pending`; make suggestion handling conditional on a schema flag true only for notes.
**Effort:** 2 features, 1 flag

### Finding 12: the window class holds the swap and the file naming (MEDIUM, A6)
**Evidence:** bib_gui_app.e:4350-4380 (`write_ingest_kit`), 4402-4460 (`import_note`, about 60 lines mixing reading, source lookup, writing, building, swapping and refreshing the window), 4382-4395 (`kit_path_for`). A `.txt` and an `.md` of the same stem both write `<stem>.kit.md`, the second silently overwriting the first (no check that the kit file exists). A source that is not valid UTF-8 is read with `read_text_utf_8` and no check of `has_error`. All of this is testable without a window.
**Suggested Action:** move it into BIB_INGEST_KIT and a keeper class (read, keep, build, swap; returns a result with a message); the window shows what it returns; test both in the facade tests.
**Effort:** 1 class; the window shrinks by about 80 lines

### Finding 13: contract gaps (MEDIUM)
- BIB_BOOK_PACK.blocks_suggesting (bib_book_pack.e:133-163): no alignment postcondition (finding 2); `chapter_suggestions` (166-182) none on block numbers.
- BIB_NOTE_IMPORTER.read: no `not is_accepted implies not problems.is_empty` (finding 6); `write_files` and `build` have no postconditions (for example `Result = Void implies built_blocks > 0`).
- BIB_NAME_LIST.make (bib_name_list.e:226) has no `require` that the Bible is open though `names` walks the open packs; the kit and importer each state it on their own `make`.
- BIB_BOOK_BLOCK.set_suggestion_reason is public and mutates a shared result; nothing records that only the pack should call it.
- BIB_INGEST_KIT.kit_text's `holds_the_source` (kit line 68) searches a result of hundreds of KB; it runs once per kit so it is acceptable, but `Result.count > a_source_text.count` is the cheap form.

### Finding 14: test coverage (MEDIUM)
**Evidence:** testing/test_app.e:435 adds ONE test, `test_ingest_kit_writes_and_notes_import`. It covers the happy path, one link refusal, a mid-line suggestion, an unreadable reference, a capital id, a wrapped file and the replace warning. Not covered: adjacent suggestion lines (1), tilde and nested fences (5), missing `sbn`, header-only file, unclosed header, bad status (6), a link in inline code (7), a failed build (4), the swap (3), two suggestions on one block or chapter (2), a headings-only chapter, a suggestion before the first paragraph (8), a book or essay holding a literal suggestion line (11), and replacing an existing note with fewer chapters.
**Suggested Action:** each fix above arrives with its test, written first.

### Finding 15: spec drift (MEDIUM)
- Spec "importer's checks": "id ... not already a different note". The code only warns when the id is already a note (importer 118-124) and cannot tell "a different note"; two sources given the same id replace each other, and the GUI shows only `warnings.first` (bib_gui_app.e:4455).
- Spec "the header is complete": the code requires only `id` and `title` (and `sbn` when present); author, date, source, status are optional (finding 6).
- Spec "a link ... points at a target in the reference data or at a Bible passage": the importer also accepts `mailto:` and any Bible form `BIB_LINK_TARGET.is_bible` reads (importer 329-335); the kit tells the AI not to make Bible links (kit line 93).
- The spec says "a fourth text-pack kind"; BIB_TEXT_PACKS has three (the test asserts 3).
- Two entry points decide "does this text read as a reference": the importer uses `place_in` (importer 420), the builder uses `reference_at (..., 1)` (write_suggestion); they can differ on text such as a trailing "and 29". The builder then drops the suggestion with a warning only for the not-read case; a read reference with `l_start <= 0` or a reversed range is dropped silently (no warning, not counted).
- Spec flow lists `bible:` among the kit's link forms; the kit lists book, essay, framework and note only (kit 135-137).

### Finding 16: ids (LOW)
src/pack/bib_private_pack_schema.e:55-59 `is_lowercase_id` allows `con`, `nul`, `aux`, `prn`, `com1`, which are Windows device names, so a note folder or manifest of that name fails or misbehaves; no length cap, so a long id plus the folder can pass the path limit. Add a reserved list and a limit in BIB_NOTE_SCHEMA.

### Finding 17: header `source` (LOW)
bib_gui_app.e:4411-4413 joins the prepared file's folder and `l_importer.source` and reads it if it is a file. `source` is the AI's text, so `..\..\anything` reads a file elsewhere (only its length is used and nothing is shown). Harmless, unintended; use the file-name part only.

### Finding 18: forms_of (LOW)
src/reading/bib_book_abbreviations.e:32-66: among equal-length forms the order follows hash-table order, so a kit's text differs between runs; the hand-written sort is fine at this size. The kit loop's `66` (kit line 124) is a literal.

### Finding 19: reason unescaped (LOW)
bib_gui_app.e:4278 puts `ic.reason` raw inside an italic span; a reason with an asterisk, underscore or closing parenthesis breaks the markup. Nothing caps the reason's length although the kit asks for "a few words".

### Finding 20: line numbers (LOW)
bib_note_importer.e:227 and 262-271: header problems say line 1 or the last line; numbers refer to the text AFTER the unwrap and BOM removal (100-104), so for a fence-wrapped file they are off by one from what the user sees.

### Finding 21: small duplicates (LOW)
`trimmed` is written in BIB_NOTE_IMPORTER (462-467) and BIB_SUGGESTION_LINE (356-361). `Format_version` is a STRING_32 "1" in the importer (276) and an INTEGER 1 in the kit (kit line 38): the file the kit asks for and the file the importer checks are tied together by two literals.

## Checked and fine
- BIB_NAME_LIST is shared by the kit, the importer and the CLI; the CLI's own `name_line` copy was removed (cli/bib_cli_commands.e diff), and the importer's allowed links use the same link strings the kit lists, so those two cannot drift.
- Whole-file fence wrapping works for the usual case (importer 427-442) and is tested.
- The deletion in `write_files` is confined to `<notes>/<id>/` for a validated id; the user's source files and other files in the notes folder are not touched.
- `suggestion_ordinal` is unique across the pack, so the block_suggestion primary key cannot collide; queries guard older packs with `has_table`.
- ecf changes: the `ingest` and `build` clusters and `simple_sql` in the window target match what the new classes use.
- Ask tick: `pending_ask` is cleared before `answer_ask` runs (bib_gui_app.e:5417), so a failure inside cannot re-run it.

## Recommended Order
1. Findings 1 and 5 (suggestion line vs block; fence rules): accepted files can yield a different result than the importer promised. One shared fence reader, one shared suggestion rule, tests first.
2. Finding 2 (reason alignment): a wrong reason shown on a verse is a silent wrong answer; one query.
3. Findings 4 then 3: make keep, build and swap one safe sequence with a restore; this also resolves finding 12.
4. Findings 6, 7, 8 and 15: bring the importer's rules to the spec, adding the tests of finding 14 as each lands.
5. Findings 9, 10, 11, 13: duplication and contract clean-up, in the branch that touches those lines.
6. Findings 16-21 whenever convenient.
