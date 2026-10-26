# Design Scan (diff mode): simple_bible, since 34adf34
# Date: 2026-10-26
# Subjects (git diff --name-only 34adf34..HEAD, Eiffel sources): cli/bib_cli_commands.e, cli/bib_data_location.e (new), cli/bib_lookup.e (new), cli/bib_lookup_choice.e (new), cli_app/bib_cli_app.e, gui_app/bib_gui_app.e (new), gui_app/bib_lookup_box.e (new), src/concordance/bib_conc_pack.e, testing/ (not scored)
# Compared against: src/, cli/, cli_app/, gui_app/ (read-only scan; no source modified, nothing compiled)

## Summary

| Severity | Count |
|----------|-------|
| HIGH | 2 |
| MEDIUM | 4 |
| LOW | 3 |

## Findings

| # | Priority | Category | Opportunity |
|---|----------|----------|-------------|
| 1 | HIGH | D1 | BIB_LOOKUP never checks `error` on the engine answers; a failed query reads as "Nothing found" while the CLI copy reports the error |
| 2 | HIGH | A5/D1 | english, strongs, verse exist twice (BIB_CLI_COMMANDS and BIB_LOOKUP) and have diverged: corpus naming (FR-156), default verse corpus, empty-result handling |
| 3 | MEDIUM | A6/M4 | BIB_GUI_APP (406 lines) owns the every-place paging state machine; a helper object would also serve the CLI |
| 4 | MEDIUM | M1 | BIB_LIST_RESULT is not ITERABLE; the new code adds four more copy-into-list index loops |
| 5 | MEDIUM | A1/M2 | BIB_DATA_LOCATION (in cli/) does the discovery that BIB_CONFIG.make_default (src/) leaves as a stub |
| 6 | MEDIUM | A1 | BIB_LOOKUP.verse_parts is a private reference parser beside the (stub) BIB_REFERENCE_PARSER, and silently guesses the first candidate |
| 7 | LOW | T1 | GUI Max_page = 200 repeats BIB_CONC_PACK.Max_page_size; Last_old_testament_book and corpus codes are literals |
| 8 | LOW | A4 | corpus_of: linear reference scan; CLI message when it returns empty reads "no corpus ." |
| 9 | LOW | M2 | Window and CLI each build the same "label + count words" phrases (count_words, places text) |

## Detailed Findings

### Finding 1: BIB_LOOKUP drops engine errors (HIGH, D1)
**Classes:** cli/bib_lookup.e (subject), cli/bib_cli_commands.e (subject, the copy that is right)
**Evidence (read):**
- src/provenance/bib_list_result.e:92 invariant `failure_is_empty: not is_success implies count = 0`: a failed query answers with zero items plus `error`.
- cli/bib_cli_commands.e:78 (word: `attached l_view.error`), english (checks `l_rows.error`, then `l_rows.count = 0`), verse (`l_words.error`), strongs (`l_entries.error`): each reports the database problem.
- cli/bib_lookup.e:84-89 `add_strongs` (reads `headwords_for_strongs`, never `error`), 108-131 `add_verse` (never `l_words.error`), 150-156 `add_word` (never `l_entries.error` or `l_rows.error`); 176-177 then says `Nothing found for "..."`.
**Divergence:** one face (CLI) tells the reader the pack is broken; the window tells the reader the word does not exist. The CLI copy should win.
**Proposal:** in BIB_LOOKUP, after each engine call set `note_text` from `error.message` when `not is_success` and return no choices (the postcondition `reason_when_empty` already requires a reason). Best done with Finding 2 so the check exists once.
**Before/after test idea:** extend testing/test_cli_commands.e: open the engine on a pack with `lemma_xref` (or the English index table) dropped or renamed, call `BIB_LOOKUP.choices_for ("H1254")` and `("love")`. Before: `note_text` is "Strong's H1254: 0 headwords" or "Nothing found". After: `note_text` carries the database error message, matching what `BIB_CLI_COMMANDS.strongs` prints for the same pack.

### Finding 2: Two implementations of the same four lookups (HIGH, A5 plus D1)
**Classes:** cli/bib_lookup.e, cli/bib_cli_commands.e
**Evidence (read):**
- English aggregation (sum counts per headword and Bible, keep first-seen order through a keys list): cli/bib_lookup.e:157-175 and cli/bib_cli_commands.e (english, the `create l_totals` ... `across l_keys` block). Identical algorithm.
- Divergence 1, Bible naming: bib_lookup.e:161 and 172-173 name the Bible by `bible.conc_pack.corpus_name (...)` (added in this range, FR-156 "never the code"); the CLI key is `l_rows.item (i).bible.to_string_32 + "  " + translit + " - " + headword`, the raw code. The new corpus_name (src/concordance/bib_conc_pack.e:108) was adopted by one copy only.
- Divergence 2, verse corpus: bib_lookup.e:102-106 chooses WLC-MACULA or NT-MACULA from the book (book <= 39); cli_app/bib_cli_app.e:95 passes `"WLC-MACULA"` as the default for every verse, so `verse 43 3 16` returns "No words for that verse in WLC-MACULA" unless `--corpus` is given.
- Divergence 3, word view: GUI open_study (gui_app/bib_gui_app.e:267-317) and BIB_CLI_COMMANDS.word each resolve the corpus through `corpus_of`, call `word_lookup.view`, and read entry, total and first places; one prints 20 rows, the other pages.
- The same loop `from i := 1 until i > l_x.count loop ... i := i + 1` appears 11 times in src, cli and gui_app.
**Proposal:** BIB_LOOKUP is already the face-neutral model (its description says "so the window and the tests share it"). Make the CLI a formatter over it: move the verse-to-corpus rule (one feature, `corpus_for_book`) and the English aggregation into BIB_LOOKUP (or a deferred ancestor BIB_LOOKUP_KIND inherited side by side by BIB_LOOKUP and BIB_CLI_COMMANDS if both need the plain-text rendering), and have `BIB_CLI_COMMANDS.english/verse/strongs` print `choices` (label, detail). Keep `bib_cli_app` passing `--corpus` only as an override.
**Before/after test idea:** a test that, for the same pack, asserts the CLI `english` output lines contain the corpus name (not the code) and that `verse 43 3 16` with no corpus lists John 3:16 words. Before: the first line shows `ENG-...` code style text and the verse test reports "No words". After: both pass and BIB_LOOKUP and the CLI share one aggregation.
**Effort:** about 3 features moved, 4 CLI features reduced to formatting.

### Finding 3: Paging state machine inside the window (MEDIUM, A6 plus M4)
**Evidence (read):** gui_app/bib_gui_app.e is 406 lines and mixes layout (120-166), design pills (168-203), lookup (205-256), word study and paging (258-363), columns and constants. Attributes `places`, `places_total`, `is_loading_places`, `study_lemma`, `study_corpus` and features `load_next_page` (334-353), `load_more_places` (319-332), the loop at 305-309 are one cohesive cluster that only needs the pack, a lemma and a corpus.
**Proposal:** a helper class (for example BIB_PLACE_STREAM, in cli/ beside BIB_LOOKUP so it is face-neutral): `make (pack, lemma, corpus)`, `load_next_page`, `rows`, `total`, `is_complete`. The window holds one and calls it from the tick. It becomes testable without a window, and the CLI `word` could use the same first-page call.

### Finding 4: BIB_LIST_RESULT is not ITERABLE (MEDIUM, M1)
**Evidence (read):** src/provenance/bib_list_result.e:46-62 offers `count` and `item (i)` but inherits only BIB_ENGINE_RESULT; no `new_cursor`. New copy-into-list loops: gui_app/bib_gui_app.e:288-291 and 299-302; cli/bib_lookup.e:85-88 and 151-154; plus the CLI loops in bib_cli_commands.e. The class already builds from an `ITERABLE [G]` (line 26) and keeps an ARRAYED_LIST `items` (line 87).
**Proposal:** add `ITERABLE [G]` and `new_cursor: ITERATION_CURSOR [G]` (delegating to `items.new_cursor`), so the new code can write `across l_glance as ic loop renderings.extend (ic) end` and the rows grids can take `set_rows` from the result directly. Contract: `new_cursor` ensures count agrees. This file is unchanged since the range start; it is flagged because the subjects repeat the loop.

### Finding 5: Data discovery lives in the wrong cluster (MEDIUM, A1 plus M2)
**Evidence (read):** cli/bib_data_location.e:18-71 implements the search order (beside program, then SIMPLE_BIBLE_CONC, then %LOCALAPPDATA%\simple_bible); src/bib_config.e:34-40 `make_default` says "Paths from the executable folder, %LOCALAPPDATA%\simple_bible\ and bible.toml" and its body is `init_empty` plus a Phase 4 comment; both faces now call `make_with_core` plus `set_conc_path` by hand (gui_app/bib_gui_app.e:34-37). testing/test_conc_timing.e:129 reads SIMPLE_BIBLE_CONC a third way.
**Proposal:** move BIB_DATA_LOCATION into src/ and let `BIB_CONFIG.make_default` call it, so the engine owns discovery and each face just says `create l_config.make_default`. Needs Larry's word because it changes the library API surface.

### Finding 6: A private reference parser (MEDIUM, A1)
**Evidence (read):** cli/bib_lookup.e:194-214 `verse_parts` splits "book chapter:verse" itself and uses `l_candidates.first` (line 210); src/reference/bib_reference_parser.e:33-46 `parse` carries the contract `never_guesses: Result.is_ambiguous implies candidates >= 2` (FR-020; "Ju 1" is ambiguous) but its body is a Phase 4 stub (`check implemented_in_phase_4: False`). So the new code guesses where the spec says never to.
**Proposal:** when BIB_REFERENCE_PARSER is implemented, route `is_verse_text`/`verse_parts` through it, and show the ambiguity in `note_text` ("Ju 1 could be Judges or Jude") instead of taking the first. Until then, at least reject text whose `candidates_for_name` has more than one candidate.

### Finding 7: Literals that a shared token should own (LOW, T1)
- gui_app/bib_gui_app.e:397 `Max_page: INTEGER = 200` with the comment "({BIB_CONC_PACK}.Max_page_size)"; the pack's own constant is at src/concordance/bib_conc_pack.e:514 and BIB_WORD_LOOKUP already uses `pack.Max_page_size` (src/concordance/bib_word_lookup.e:45). Use the pack's constant so the two cannot drift.
- cli/bib_lookup.e:185 `Last_old_testament_book = 39` and the corpus codes at 103, 105 and cli_app/bib_cli_app.e:95: one place (the pack or BIB_BOOK_CATALOG) should answer "which corpus holds this book".

### Finding 8: corpus_of (LOW, A4)
src/concordance/bib_conc_pack.e:123-138 scans `corpus_provenances` comparing references (`ic = a_provenance`), while `corpus_names` and `corpus_code_of` are hash tables; fine at 8 corpora. When it returns empty, cli/bib_cli_commands.e:72-73 prints "The concordance has no corpus ." with an empty name; say "The concordance cannot tell which corpus holds headword N."

### Finding 9: Phrase builders (LOW, M2)
cli/bib_lookup.e:216-223 `count_words`, gui_app/bib_gui_app.e:303, 356-362 and cli/bib_cli_commands.e:84, 96-98 each assemble "N places / N more" text by hand. A small shared phrase helper would give one plural rule. Cosmetic.

## Recommended Order
1. Findings 1 and 2 together (live defect plus drift; fix the error handling while unifying the four lookups).
2. Finding 4 (small, removes the loop copies from what Finding 2 touches).
3. Finding 3, then 5 and 6 on Larry's word.
4. Findings 7 to 9 as cleanup in the same pass as 2.
