# Design Scan (diff mode): simple_bible, since c8b43dd
# Date: 2026-10-28
# Subjects: src/pack/bib_book_schema.e, bib_author_book.e, bib_book_block.e, bib_book_pack.e; build/bib_book_builder.e, bib_markdown_blocks.e; build_app/bib_build_app.e (--books); src/reading/bib_book_abbreviations.e, bib_reference_linker.e; src/simple_bible.e (book_packs); gui_app/bib_gui_app.e (books clause, link_card, on_commentary_link)
# Compared against: all of src/, build/, build_app/, gui_app/
# Mode: read-only; nothing compiled, no source changed. Findings are proposals.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A1/A5/A6/D1) | 12 | 6 | 4 | 2 |
| MI | 1 | 0 | 1 | 0 |
| Generics | 1 | 0 | 0 | 1 |
| Contracts / edge cases | 3 | 1 | 1 | 1 |
| **Total** | **17** | **7** | **6** | **4** |

(One finding is listed once under its main category; the table counts it there.)

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | A5 | BIB_GUI_APP (book_card, framework_card, passage_card) | One hover-card builder |
| 2 | HIGH | D1 | BIB_GUI_APP (show_book_place, show_framework, start_in_notes) | Three "bring a pane into view" copies have drifted |
| 3 | HIGH | A5 | BIB_BOOK_BUILDER, BIB_FRAMEWORK_BUILDER, BIB_COMMENTARY_BUILDER, BIB_PACK_WRITING | Move sidecars_in, fail_unless, provenance row, meta rows up |
| 4 | HIGH | A1 | BIB_BOOK_SCHEMA, BIB_FRAMEWORK_SCHEMA | is_book_id and is_framework_id are the same body; id and link rules want one ancestor |
| 5 | HIGH | contract | BIB_BOOK_SCHEMA, BIB_BOOK_BLOCK, BIB_BOOK_BUILDER | link_text postcondition fails above 9999; nothing bounds chapter or block |
| 6 | HIGH | D1 | BIB_REFERENCE_LINKER, BIB_BOOK_ABBREVIATIONS | Compact abbreviations are dead; the forgiving face ignores the table |
| 7 | HIGH | A5 | BIB_GUI_APP (link_card, on_commentary_link) plus two link parsers | Three-way link dispatch written twice; "book:" and "bible:" parsed by two near-identical readers |
| 8 | MEDIUM | edge cases | BIB_MARKDOWN_BLOCKS | Parsing edge cases and no contract on kind or level |
| 9 | MEDIUM | A5 | BIB_GUI_APP (fill_books, fill_frameworks, fill_in_books, book_pack, framework_pack) | One rows-from-result helper; one pack accessor |
| 10 | MEDIUM | A1 | BIB_BOOK_PACK, BIB_FRAMEWORK_PACK, BIB_COMMENTARY_PACK | Shared answer tail and the three pack-noun routines |
| 11 | MEDIUM | coupling | BIB_GUI_APP (chapter_page, show_book_place) | "Block n is page block n+1" holds by comment only |
| 12 | MEDIUM | A1 | SIMPLE_BIBLE (commentary_packs, framework_packs, book_packs) | Three copies of one loop |
| 13 | MEDIUM | MI | BIB_BOOK_BUILDER | Frameworks-pack reading belongs with BIB_PACK_WRITING heirs, not inline |
| 14 | LOW | T1 | BIB_GUI_APP | Magic tab indexes (In_books_tab, Author_library_tab, Frameworks_tab) |
| 15 | LOW | edge | BIB_BOOK_BLOCK.snippet | Leading list marker handling |
| 16 | LOW | A4 | BIB_BOOK_ABBREVIATIONS | Table has no contract tying it to the catalog; capitalised short forms near ordinary words |
| 17 | LOW | G | BIB_BOOK_BUILDER | records tuple is a 14-field anonymous TUPLE; a class would carry contracts |

## Detailed Findings

### Finding 1: Hover-card builders are three copies of one skeleton
**Priority:** HIGH. **Category:** A5.
**Classes:** BIB_GUI_APP.
**Evidence:**
- gui_app/bib_gui_app.e:4137-4162 `book_card`: heading label with wrap (bold UI role 13.0), body label with wrap, muted hint label, SW_COLUMN with gap 6.0, `create Result.make (l_column, 440.0)`.
- gui_app/bib_gui_app.e:4332-4359 `framework_card`: the same 16 lines; only the strings (heading, body, hint text) and the "Draft" suffix differ.
- gui_app/bib_gui_app.e:3842-3898 `passage_card`: the title/body/column tail (l_title, l_body, with_wrap, with_gap (6.0), put, put, make (l_column, 460.0)) is the same again, minus the hint, with width 460.0 rather than 440.0.
**Description:** a helper `card (a_heading, a_body, a_hint: READABLE_STRING_GENERAL; a_width: REAL_64): SW_HOVER_CARD` (hint empty: no hint line) would leave each *_card with only its data lookup. A fourth card (essays, announced as next) would otherwise be a fourth copy. The helper may live in a deferred BIB_HOVER_CARDS mixin the window inherits side by side with its other roles. The two widths 440.0 and 460.0 are also a T1 token pair (Card_width) for the same role.
**Suggested Action:** /eiffel.abstract targeting book_card, framework_card, passage_card. **Effort:** 1 helper, 3 callers.

### Finding 2: "Bring the pane into view" has drifted across three copies
**Priority:** HIGH (drift, D1). **Category:** D1.
**Evidence:**
- gui_app/bib_gui_app.e:4047-4064 `show_book_place` starts with `if not is_study then arrange (True) end`, then restores a maximized pane only when `dock.maximized_panel /= 0 and /= results_panel` (4089-4093), shows the panel, expands its zone, selects the tab.
- gui_app/bib_gui_app.e:4241-4266 `show_framework`: the same restore/show/expand/select steps (4260-4265) but NO `arrange (True)` call. From the Simple layout it can show a panel that is not laid out the way Study lays it out.
- gui_app/bib_gui_app.e:3326-3340 `start_in_notes`: has `arrange (True)`, but calls `dock.restore_maximized` unconditionally (it also un-maximizes the target pane).
**Description:** three variants of one routine. Name the divergence: the Study-layout guard (two of three have it) and conditional versus unconditional restore. The behavior that should win is `show_book_place`'s (guard plus restore only another pane). Proposed `bring_into_view (a_panel: INTEGER; a_tabs: SW_TABS; a_tab: INTEGER)`.
**Suggested Action:** refactor branch; confirm with Larry whether Simple layout should show Frameworks at all without switching to Study. **Effort:** 1 helper, 3 callers.

### Finding 3: The two (three) builders repeat what BIB_PACK_WRITING was made to hold
**Priority:** HIGH. **Category:** A5/A1.
**Evidence:**
- build/bib_book_builder.e:54-68 `sidecars_in` equals build/bib_framework_builder.e:58-73 and build/bib_commentary_builder.e:56 except for the extension (".book.json" / ".framework.json") and list capacity.
- build/bib_book_builder.e:206-212 `fail_unless` equals build/bib_framework_builder.e:211-217 line for line.
- build/bib_book_builder.e:99-107 and build/bib_framework_builder.e:101-110: the same sequence `fresh_pack`, four `put_meta` (pack_kind, title, author "Larry Rix", builder), then `INSERT INTO source_provenance VALUES (1, ?, ?, 'private', 1, 0, 1, 'Larry Rix', ?)` plus `check_db`. Only the builder name and two strings differ.
- build/bib_pack_writing.e:2-10 states its purpose: "what BIB_COMMENTARY_BUILDER and BIB_FRAMEWORK_BUILDER had line for line"; the books builder (written after it) re-copied the leftovers.
- build/bib_book_builder.e:70-119 and bib_framework_builder.e:77-123 share the same `build` skeleton: reset counters, read inputs, fresh_pack, metas, provenance, write, finish_pack.
**Suggested Action:** move `fail_unless`, `sidecars_in (folder, extension)` and `begin_private_pack (db, kind, title, builder_name, source_key, caveat)` into BIB_PACK_WRITING (a deferred `sidecar_extension` for the first). **Effort:** 3 features, 3 heirs lose about 60 lines.

### Finding 4: Schema ids and link grammars are written twice
**Priority:** HIGH (identical bodies). **Category:** A1.
**Evidence:**
- src/pack/bib_book_schema.e:66-70 `is_book_id` and src/pack/bib_framework_schema.e:90-94 `is_framework_id`: identical bodies (`not empty and then across ... all (a..z) or (0..9)`).
- Both schemas also repeat: `Pack_kind`, `Pack_file_name`, `Pack_title`, `Schema_version`, `Link_prefix` (book_schema.e:30-44, framework_schema.e:28-36), and the `meta`/`source_provenance` CREATE TABLE statements (book_schema.e:123-126, framework_schema.e:103-104, byte for byte).
- BIB_COMMENTARY_SCHEMA (not read in full) is expected to hold the same constants.
**Description:** a deferred BIB_PRIVATE_PACK_SCHEMA (Pack_kind, Pack_file_name, Pack_title, Schema_version, common_statements, is_lowercase_id) inherited by all three schemas; each keeps its own tables and link grammar. Contract gain: `Schema_version = 1` ties to BIB_PRIVATE_SOURCE.Pack_schema_version once, rather than each schema's comment saying so.
**Suggested Action:** /eiffel.abstract. **Effort:** 6 features.

### Finding 5: link_text and BIB_BOOK_BLOCK contracts allow what link_place refuses
**Priority:** HIGH (contract gap). **Category:** contract.
**Evidence:**
- src/pack/bib_book_schema.e:77-91 `link_text` requires only `a_chapter >= 0 and a_block >= 0`; its postcondition `read_back` parses the result with `link_place`.
- src/pack/bib_book_schema.e:142-146 `is_count` accepts only 1 to 4 digits (at most 9999).
- A chapter or block number of 10000 or more satisfies the precondition and breaks the postcondition. BIB_BOOK_BLOCK.make (src/pack/bib_book_block.e:26-28) requires only `>= 1`, and BIB_BOOK_BLOCK.link (60-63) calls link_text, so a long chapter fails at the link, not at the build.
- build/bib_book_builder.e:232-246 writes any number of chapters and blocks with no bound.
**Description:** add `Max_part: INTEGER = 9999` to BIB_BOOK_SCHEMA; require `a_chapter <= Max_part and a_block <= Max_part` in link_text and BIB_BOOK_BLOCK.make; make the builder refuse a chapter list or block count above it with a named `last_error`. (Blocks restart at 1 per chapter, so 9999 is generous; the point is that the contract says so.)
**Suggested Action:** contract fix, no abstraction. **Effort:** 1 constant, 3 clauses.

### Finding 6: Abbreviation table has dead entries; the two faces of the linker disagree
**Priority:** HIGH (drift). **Category:** D1.
**Evidence:**
- src/reading/bib_reference_linker.e:411-420 `starts_like_a_name` accepts a leading capital, or digit + space + capital ("1 John"). Compact forms fail it: "1Sam", "1Kgs", "2Chr", "1Cor", "1John" and the like (src/reading/bib_book_abbreviations.e:46-52, 83-84, 89-101: about 30 entries) have a digit then a letter, so `book_named` never reaches the table for them in prose mode (linker lines 315-320). The reference_at word splitter also reads "1Sam" as one word, so no other path finds them either.
- The forgiving face (linker lines ~310-313) uses only `books.candidates_for_name` (prefix and case), never BIB_BOOK_ABBREVIATIONS. So "Gn 1:1", "Qoh 3:1", "Phlm 5", "Ezk 1:1", "Dt 6:4", "Jn 3:16" link in prose but do not read in the reference box, against the class note's claim "ONE READER FOR BOTH FACES" (linker header). "Phil" is also ambiguous in the forgiving face (Philippians or Philemon: first candidate wins) while the table says Philippians.
**Description:** the faces should share one `book_named` fallback order (exact, table, then, if forgiving, prefix). Either allow digit-letter starts in `starts_like_a_name` or drop the dead entries. Add a test per compact form; the tests added in testing/test_reading.e (8 lines) are not shown to cover them.
**Suggested Action:** fix in the linker; tests first. **Effort:** 2 features.

### Finding 7: Link dispatch written twice, link grammars parsed twice
**Priority:** HIGH. **Category:** A5/A3.
**Evidence:**
- gui_app/bib_gui_app.e:3804-3820 `link_card`: `framework:` prefix, else `link_place` (book), else `target_range` (bible).
- gui_app/bib_gui_app.e:4413-4440 `on_commentary_link`: the same three-way split, with `framework:` and `book:` as an if/elseif and the `bible:` branch as a separate trailing `if` (not an elseif, so a future overlap would run two branches).
- src/pack/bib_book_schema.e:101-140 `link_place` and src/reading/bib_reference_linker.e (`target_range`, `is_small_number`) both split a prefix, cut at '/', '#' or '-', check digit-only parts and bound them (is_count max 4 digits nonzero; is_small_number max 3 digits and at most 176, zero allowed). Two parsers of one family with different rules for zero and size.
- `framework:` prefix removal appears as `al_target.substring (Link_prefix.count + 1, al_target.count)` at gui lines 3810 and 4420, in builder lines 273-276 and elsewhere.
**Description:** a BIB_LINK_TARGET value object (kind: framework, book, bible, other; plus the parsed fields) built by one `parsed (a_target)` and consumed by both GUI routines with `inspect`, would make the next link kind (essays) one addition rather than two edits plus a parser. The builder's index reading in write_indexes (book_builder.e:261-280) would use it too.
**Suggested Action:** /eiffel.abstract. **Effort:** 1 class, 3 call sites.

### Finding 8: BIB_MARKDOWN_BLOCKS edge cases and missing contracts
**Priority:** MEDIUM. **Category:** contract / edge cases.
**Evidence (build/bib_markdown_blocks.e):**
- 65: `without_comments (without_front_matter (...))` runs over the whole chapter, fences included. A code block containing an HTML comment loses it silently; an unterminated "<!--" (267-282, lines 274-277) deletes the rest of the chapter with no error.
- 247-264 `without_front_matter`: a chapter that begins with a horizontal rule ("---" line) and has another "%N---" anywhere later is read as front matter, dropping all text between them.
- 78-84: in a skipped section the code-fence state is not tracked; a line inside a fenced block that looks like "# x" ends the skip. Opening "~~~" fences are not recognised; "```code```" on one line opens and never closes (swallows the rest of the chapter into one code block, flushed at 120).
- 196-207 `heading_text`: strips every trailing '#', so "# Learning C#" becomes "Learning C" (CommonMark closes only on a space before the hashes).
- 99-102, 116-117: list items keep `l_trimmed`, so nesting depth is lost; a non-indented line after an item is absorbed into the item although the comment says "when indented". Setext headings ("Title" over "====") become a paragraph with a line of "=" in it.
- 47: `blocks` is a public mutable ARRAYED_LIST of anonymous tuples; no postcondition ties `kind` to BIB_BOOK_SCHEMA.Block_kinds or `level` to 1-6 for headings and 0 otherwise (the block table has no CHECK on kind: schema line "book_block"); the one ensure is `no_empty_block`.
- 366: `lists_attached: blocks /= Void` etc. is vacuous in void-safe code.
**Suggested Action:** add ensures (kinds known, level range, headings have level >= 1), clean comments outside fences only, report an unterminated comment through the builder's `last_error`. **Effort:** about 6 small fixes.

### Finding 9: Grid fill routines and pack accessors repeat
**Priority:** MEDIUM. **Category:** A5.
**Evidence:**
- gui_app/bib_gui_app.e:3995-4008 `fill_books`, 4121-4134 `fill_in_books`, 4217-4230 `fill_frameworks`: each is "create rows (0); if pack attached and result success then create rows (count); across 1 |..| count extend; else set a document; set_rows". The copy loop `across 1 |..| al_result.count as al_i loop rows.extend (al_result.item (al_i)) end` is at 4004-4006, 4129-4131 and 4224-4226 (and the same idiom for cross_refs at 4392-4400).
- 3987-3993 `book_pack` and 4186-4192 `framework_pack`: same shape (open and nonempty and first available); commentary uses a third spelling at 696 and 4456-4464.
**Description:** `rows_of [G] (a_result: BIB_LIST_RESULT [G]): ARRAYED_LIST [G]` (a feature of BIB_LIST_RESULT, `to_arrayed_list`, is better still since the result already holds the list) and a generic `available_pack [P -> BIB_PRIVATE_PACK_READER] (a_packs: LIST [P]): detachable P`. The three on_*_row handlers (4012-4017, 4020-4025, 4234-4239) share the same bounds-check guard.
**Suggested Action:** /eiffel.generify for the pack accessor. **Effort:** 2 helpers.

### Finding 10: Pack readers share an answer tail and three boilerplate routines
**Priority:** MEDIUM. **Category:** A5.
**Evidence:**
- src/pack/bib_book_pack.e:171-177, bib_framework_pack.e:167-173, bib_commentary_pack.e:162-168: `query_failed_message`, `not_open_message` and `pack_noun` are three renderings of one noun ("books", "frameworks", "commentary"). The base BIB_PRIVATE_PACK_READER (lines 51, 68) already asks for pack_noun.
- bib_book_pack.e:34-49 `books` and bib_framework_pack.e:36-53 `frameworks` (and `aliases`, 91-117): run_query, if attached last_rows, build list, make_success or make_failure; only the row-to-object step differs. `blocks_answer` (book_pack.e:139-160) was extracted for blocks only.
- book_pack.e:150: the guard `is_book_id (...) and chapter >= 1 and block >= 1` repeats the BIB_BOOK_BLOCK preconditions by hand; `book_of_row` (162-169) does the same for BIB_AUTHOR_BOOK. Rows that fail are dropped silently, so the success count can be below what is in the file with no trace.
**Description:** derive the two messages from `pack_noun` in the base; give the base `listed (a_feature, a_sql, a_args, a_scope, a_make: FUNCTION [SIMPLE_SQL_ROW, detachable G])` as a generic template.
**Effort:** 2 features up, about 30 lines removed.

### Finding 11: "Block n is page block n+1" holds by comment only
**Priority:** MEDIUM. **Category:** coupling (no contract).
**Evidence:** gui_app/bib_gui_app.e:4083 `book_view.scroll_to (book_view.stacked_scroll_for ((a_block + 1).min (book_view.document.count)))` assumes each book block becomes exactly one document block after the title (comment 4078 and 4101-4103 for `chapter_page`). `chapter_page` (4098-4119) writes every block followed by a blank line, and kind "item" blocks as "- a" then "- b" separated by blank lines. A Markdown reader may join blank-line-separated items into one list (one document block), which would shift every later block's index; consecutive code or quote blocks have the same risk. I did not read MD_DOCUMENT_READER, so this is unverified, not a confirmed defect. `.min (document.count)` hides an overshoot instead of surfacing it.
**Suggested Action:** a test that reads a chapter containing items and compares `document.count` with block count plus one; or have the reader report the block index of each source block. **Effort:** 1 test.

### Finding 12: SIMPLE_BIBLE builds each pack list the same way
**Priority:** MEDIUM. **Category:** A5.
**Evidence:** src/simple_bible.e:187-194 `commentary_packs`, 196-203 `framework_packs`, 205-212 `book_packs`: each is `create Result.make (1); across packs_of_kind (Kind) as ic loop Result.extend (create {X}.make (sources, ic.alias_name, ic.pack_title))`. A generic factory, or a deferred class constructor taking the source (all three have the same make signature), would let a fourth pack be one line.
**Effort:** 1 feature.

### Finding 13: The books builder reads the frameworks pack inline
**Priority:** MEDIUM. **Category:** M2.
**Evidence:** build/bib_book_builder.e:130-148 `read_framework_spellings` opens the frameworks pack as raw SQL (`SELECT alias, framework_id, needs_mark FROM framework_alias`), duplicating what BIB_FRAMEWORK_PACK.aliases (src/pack/bib_framework_pack.e:91-117) reads, minus its id checks and ordering. The builder already depends on the reader classes (BIB_FRAMEWORK_NAMES, BIB_FRAMEWORK_SCHEMA).
**Suggested Action:** build the spellings with BIB_FRAMEWORK_NAMES.make_from_spellings from the pack reader, or route both through BIB_PACK_WRITING. **Effort:** 1 feature.

### Finding 14: Magic tab indexes
**Priority:** LOW. **Category:** T1.
**Evidence:** gui_app/bib_gui_app.e:4198-4202 (`In_books_tab = 3`, `Author_library_tab = 4`), 4172 (`Frameworks_tab = 3`); the order is set by add_page at 690-693, 740-745 and 1704-1708. Reordering a page breaks `select_tab` silently. Select by the page object, or build the constants from one place.

### Finding 15: snippet and list markers
**Priority:** LOW. **Category:** edge.
**Evidence:** src/pack/bib_book_block.e:71-77 `snippet` prunes '*' before testing for a leading mark, so "* item" becomes " item" (mark gone, space left) while "+ x" and "1. x" are never stripped. Only "- " and "> " are removed. Test with each of the five marker styles BIB_MARKDOWN_BLOCKS keeps (is_item at 232-245).

### Finding 16: Abbreviation table and ordinary words
**Priority:** LOW. **Category:** A4.
**Evidence:** src/reading/bib_book_abbreviations.e:22-30 `book_of` only ensures 0 to 66; nothing checks the table against the catalog. Class note (lines 10-11) claims no form is an ordinary capitalised word followed by a number; "Dan 5 minutes", "Jon 3", "Phil 4", "Col. 3" (an abbreviation of Colonel) would link. Strict mode runs at build time on Larry's text, so a review pass over the built pack's passage index is the cheap check.

### Finding 17: The manifest record is a 14-field anonymous tuple
**Priority:** LOW. **Category:** G4.
**Evidence:** build/bib_book_builder.e:123-125 `records`; fields read by name across read_manifest (150-204) and write_book (216-248), plus nested chapter tuples. A BIB_BOOK_MANIFEST class would carry the checks now spread through `read_manifest` (179-195) as invariants, and BIB_AUTHOR_BOOK (src/pack/bib_author_book.e) and the manifest share nine fields with their mapping. The framework builder has the same shape (127-128), so the class would serve both.

## Checked and found sound
- src/pack/bib_book_schema.e:101-140 `link_place`: "book:x#12" without a chapter, "book:x/4#", "book:x/4/5", empty parts and zero parts are all refused by the `l_ok` chain; the postcondition `sane` covers the result.
- build/bib_book_builder.e:285-300 `link_targets` ends cleanly on an unterminated "](".
- src/pack/bib_book_pack.e:78-85: a missing book answers success with no item; a chapter-query failure answers failure.
- The linker move from cli/ to src/reading/ changed 4 lines (rename, no copy left in cli/).
- Cursor-style locals, attachment names and contract placement follow the project's naming standards in the files read.

## Recommended Order
1. Finding 5 (contract bound): smallest change, closes a postcondition hole before a long book hits it.
2. Finding 6 (dead abbreviations, face drift): a live defect; tests first.
3. Finding 2 (pane drift): a live behavioral divergence.
4. Findings 3 and 4 (builders and schemas up into shared ancestors, side by side with MI): removes the most duplicated lines and makes the next pack (essays) cheaper.
5. Findings 1, 7, 9 (GUI helpers and link target class), then 10, 12, 13.
6. Finding 8 (markdown edge cases) before the next book is built; 11 with a test; the LOW items as convenient.
