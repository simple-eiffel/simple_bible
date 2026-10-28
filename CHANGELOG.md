# Changelog

All notable changes to simple_bible are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added (2026-10-28: Larry's books; personal installer 0.7.24)

- **The books pack** (`books.db`, private): Larry's books from one manifest per book, which the COMMENTARY session writes (it chooses the canonical manuscript and chapter order; research/19-BOOKS-PACK.md). `bible_build --books <folder> --out books.db [--content content.db] [--frameworks-pack frameworks.db]` reads the Markdown chapters itself and splits them into BLOCKS (`BIB_MARKDOWN_BLOCKS`: heading, paragraph, quote, list item, code; front matter, comments, images, rules, typesetting placeholders, draft status lines and skipped sections left out; wiki links and footnote markers read plainly), each addressed `book:<id>/<chapter>#<block>`. Every block is linked by the window's own linker and the `bible:` and `framework:` targets it wrote become the block's passage and framework indexes. `BIB_BOOK_SCHEMA`, `BIB_BOOK_PACK` (books, one book, a chapter's blocks, the blocks citing a verse narrowest first, the blocks naming a framework), `BIB_AUTHOR_BOOK`, `BIB_BOOK_BLOCK`, `BIB_BOOK_BUILDER`; `SIMPLE_BIBLE.book_packs`. First batch: 7 books, 151 chapters, 7,092 blocks, 2,519 references.
- **In the window**: T6's **Author Library** tab (the books, their chapters, the chapter read, references and framework names linked); T5's **In the books** tab (the paragraphs citing the verse); each framework's page lists **Where the books discuss it**; `book:` links open the library with a hover card (title, chapter, description).
- **The reference reader knows the standard abbreviations** (`BIB_BOOK_ABBREVIATIONS`: 1 Cor, 1 Kgs, Psalm, Heb, Isa, Matt, 1 Jn ...) when content.db's catalog has no exact name: the books' indexed references rose from 2,095 to 2,519, and the commentary links "Heb 13:8" now. `BIB_REFERENCE_LINKER` moved from the command line's cluster to the engine (`src/reading`), so the builder uses the same reader as the window.
- commentary.db 13 books (James: 195 sections, 4,400 claims). Snapshot options `books`, `inbooks`.

### Added (2026-10-28: Frameworks explained; personal installer 0.7.22)

- **The frameworks pack** (`frameworks.db`, private like commentary.db): Larry's FRAMEWORKS(TM) rewritten for the common Christian reader by the COMMENTARY session (research/18-FRAMEWORKS-PACK-SIDECAR.md), drafts until Larry approves them. `BIB_FRAMEWORK_SCHEMA`, `BIB_FRAMEWORK_PACK` (by tier, one whole, the spellings), `BIB_FRAMEWORK`, `BIB_FRAMEWORK_SPELLING`; `SIMPLE_BIBLE.framework_packs`. `bible_build --frameworks <folder> --out frameworks.db --uses commentary.db` checks every sidecar (ids, spellings unique, tier, status, hover at most 280 characters, the first three sections) and works out where the commentary uses each framework from its "Frameworks at work" lists; a related framework not written yet is a warning. Tiers: cornerstone, bedrock, master, recovery, sub.
- **A framework named anywhere in the commentary is a link** (`BIB_FRAMEWORK_NAMES`, one rule for the builder and the linker; `BIB_REFERENCE_LINKER.set_framework_names`): a framework prose marks (TM) links by its name only with the mark, so essay titles and capitalized words stay prose; a mark may follow a word inside a spelling ("the JESUS(TM) Cornerstone"). Hover shows its title and plain summary ("Draft" while it is one); a click opens it in T4's new **Frameworks** tab (P05.8): every framework by tier beside the one read, its sections with their references and other frameworks linked, the frameworks related to it, and where the commentary uses it. The commentary stays in view; a maximized pane or a folded side makes way.
- The commentary pack now holds 12 books (Colossians, Ephesians, Hebrews: 182 sections, 4,149 claims); frameworks.db 19 frameworks, 740 commentary uses. Snapshot options `frameworks`, `fwcard`. Personal installer 0.7.23.

### Fixed (design scan 58)

- One private-pack reader and one writer: `BIB_PRIVATE_PACK_READER` (the alias, title, availability, a provenance row read, the pack's own provenance) under `BIB_COMMENTARY_PACK` and `BIB_FRAMEWORK_PACK`, and `BIB_PACK_WRITING` (a fresh pack in one transaction, meta rows, SQLite's words, sidecar strings) under both builders, which had copied each other's plumbing; a pack file that cannot be deleted is now said, not ignored. The frameworks reader cites the pack's own provenance row as the builder wrote it (it invented one). The tier message names the schema's own tiers. `SIMPLE_BIBLE.packs_of_kind`; one `range_label` in the window (two copies had drifted); one rule for a name that needs its mark. Before: `test_framework_pack_builds_attaches_and_answers` FAILED on the old reader ("cited from the pack's own provenance"); after: 195 passed, 0 failed.

### Added (2026-10-28: the commentary's references previewed and followed; personal installer 0.7.21)

- **A reference's passage on hover**: resting on a Bible reference in the commentary opens a card with its text in the version read, each verse numbered, up to 8 verses ("Galatians 2:15-21 (KJV)"). `BIB_REFERENCE_LINKER` now writes where a range ends into its link (`bible:48.2.15-2.21`; one place keeps `bible:48.2.15`), read by `target_range`; `target_place` still reads the first verse of either form.
- **Following a reference keeps the commentary**: a click on one opens the passage in the Bible text while the commentary stays on its verse, its heading saying what is read meanwhile; "Back to Galatians 2:20" in the reading bar (and the Go menu) returns, and any other way of moving (a verse clicked, the reference box, Back and Forward) lets the commentary follow again. The commentary is redrawn only when its verse changes, so a long one keeps its scroll.
- Snapshot options `hold` and `refcard`. The personal concordance carries two covering indexes (first English lookup cold 5.3 s -> 0.9 s; built by the vault's builder).
- **The version in the caption and Help > About** ("simple_bible 0.7.21"): `BIB_RELEASE.Program_version`, the same as `bible_gui.rc`'s new version block (Windows shows it in the file's properties; the installer reads it from the built exe); `test_program_version_is_the_resource_version` holds the two equal.

### Fixed (design scan 57)

- The commentary hold is a place by invariant (`hold_is_a_place`). The reference reader reads digits through one `number_at`, held at 177 so a long run never overflows; `target_range` answers Void for a target no reference writes (book 0, a sign, a part past 176, a passage running backward), with a postcondition, so a hover can never walk thousands of chapters. Before: `test_references_become_links` FAILED ("a passage past any book is none"); after: 193 passed, 0 failed.

### Added (2026-10-28: right-click menus, Focus reading, larger panes; personal installer 0.7.19)

- **Right-click menus** on every control one can do something with (simple_widgets 0.46.1 gives each its Copy items; the window adds its own above them): a verse in the Bible or Parallel tab (copy it with its reference or the chapter; bookmark, highlight, note, tag, learn it by heart, pray about it; open it in Parallel or Interlinear; Focus reading); a word in the Interlinear or the verse analysis (open it in the lexicon, every place, search for its Strong's number, copy it); a book or chapter in the Navigator (read it); a row of bookmarks, history, highlights, tagged verses, prayers, cards, cross-references, places or found verses (go to it, copy it with its text, copy the reference; Remove and Restore where the list has them; Mark answered for an open prayer); journal entries, tags, renderings and verse notes their own. `BIB_ITEM_LIST_PANEL.set_menu_items`.
- **Focus reading** (View, Ctrl+Shift+F, the Focus button in the reading bar, S1.1): every side folds to a strip naming its panes, so the Bible text has the window; a dot marks a pane with something for the verse read (Larry's commentary covering it, notes on the chapter, a word open, search results); a click on a name opens that side at that pane.
- **Larger panes**: Commentary, Dictionary and Lexicon, Notes and Search results maximize from their title bars (the button, a double click, the bar's menu or the pane's own menu) and come back the same way; every side's title bar folds it.
- A prayer begun from a verse's menu rests on that verse. Snapshot options `focus`, `maximize`, `fold`, `versemenu`, `barmenu`, `gridmenu`.

### Fixed (design scan 56)

- One verse copier: Edit > Copy verse goes through `copy_hub_verse`, as the menus do. One range rule for a place: `BIB_HUB_ID.is_place` and `hub_of_place` (the window had its own copy; `hub_id`'s precondition is now `is_place`), tested in `test_hub_id_is_english_numbering`. `open_journal_row` and `delete_journal_row` require a listed row and ensure the entry opened is that row's, so a right-click's Delete can never remove the entry open before.

### Added (2026-10-27: the study tools; personal installer 0.6.0 to 0.7.6)

- **Interlinear tab** (P03, Ctrl+I): the chapter word by word in Hebrew or Greek, with transliteration, gloss, Strong's number and morphology spelled out (`BIB_CONC_PACK.interlinear_chapter`, `BIB_INTERLINEAR_WORD`, `BIB_MORPHOLOGY_NAMES`); the **verse analysis** grid below it (P03.2) gives each word's count in the corpus.
- **Notes** (T2): `user.db` in the user's local application data (`BIB_USER_STORE`, schema 1); `BIB_DB_NOTE_STORE` keeps every version of a note, soft-deletes and restores, and exports and imports Markdown. Panels: **Verse notes** on the chapter read and a **Journal** of notes on a subject.
- **Highlights** (a reason, not a color; verses washed amber in the Bible and Parallel tabs), **Bookmarks** (Navigator, Ctrl+D), **Tags** (every tag with its count, the verses of a tag) and **History** (the last 50 chapters read, kept between runs). One list panel, `BIB_ITEM_LIST_PANEL`, gives highlights, bookmarks and tagged verses Remove and Restore.
- **Generic data packs** (Task 7b): `BIB_PRIVATE_SOURCE` attaches packs from the pack folder after checking their rules (user_version, meta, provenance, voice); a bad pack is refused and the Bible stays open.
- **Commentary packs**: `BIB_COMMENTARY_SCHEMA`, `BIB_COMMENTARY_PACK` (the sections for a verse, narrowest first) and `bible_build --commentary`, which builds one `commentary.db` for every book from section sidecars. The **Commentaries** tab labels every claim SOURCED or DEDUCED inline. Commentary packs are private data and are not distributed.
- **References become links**: `BIB_REFERENCE_LINKER` turns "Jude 9" or "2 Peter 2:4-5" in a commentary into a link that opens the verse; the reference box reads the same forms (ranges open their first verse; one-chapter books take a verse number).
- **Verse search**: `bible_build` 0.3.0 writes `verse_fts`, a contentless full-text index over every verse's search form (`BIB_VERSE_KEY`: one key range per version); `BIB_TEXT_READER.verses_matching` finds every word, a "quoted phrase" or a `word*` prefix in Bible order. The Hebrew, Greek and English normalizers now fold for real over simple_encoding's `SIMPLE_UNICODE` (LG-01), so unpointed Hebrew finds pointed text and accentless Greek finds accented text. The results zone lists the verses under the word choices.
- **Boolean and root-word search** (B02, B03): `BIB_QUERY_PARSER` reads words, "phrases", `word*`, AND, OR, NOT, parentheses, `strongs:H1254` or a bare `G5485`, and `lemma:` (a Hebrew or Greek headword or its plain letters), and names the place of any error; `BIB_VERSE_SEARCH` evaluates the query as sets of verses, words from the verse index and roots from the concordance by key (Hebrew roots in WLC-MACULA, Greek in NT-MACULA). The results say when Hebrew verse numbers or the critical Greek text are in play.
- **Morphology search** (B05): `morph:V-AAI-3S` (Greek, Robinson codes, the Greek New Testament) or `morph:Vqp3ms` (Hebrew, OSHB codes, the Hebrew Bible), with a final `*` for every code it begins; it combines with words and roots by verse.
- `bible_gui --snapshot <png> <place> [tab]`: a picture of the whole window without a screen, from its own scratch `user.db`.

### Fixed (design scans 36 to 46)

- Each feature was followed by a read-only design scan (reports in `.eiffel-workflow/evidence/`); every HIGH finding was fixed with a test that failed before. Among them: one Greek and Hebrew fold for every lookup; one door rule for every face of a word; one SQLite reporting mixin; one reference reader for the box and the links; one live-item rule for every user-item query (an unlabelled row was counted but not listed); a list keeps its choice when it is refilled; the Journal and Verse notes no longer share one Restore; a failed History write is told. Tests: 167 pass, 49 skeletal (reported as skipped), 0 fail.

### Changed (2026-10-26: the spec fold rolled into the skeletons)

- **The concordance comes in** (D-021, debate 05b pathway B): `src/concordance/` with `BIB_CONC_PACK`, `BIB_WORD_LOOKUP`, `BIB_ENGLISH_INDEX`, `BIB_VERSE_WORDS` and five value classes; `SIMPLE_BIBLE` gains `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup`; `BIB_CONFIG` gains `conc_path` (the edition swap is this one path).
- **One content database** (debate 01 pathway B-S): `BIB_CONTENT_SOURCE` replaces `BIB_CORE_SOURCE` and `BIB_AI_DATA_SOURCE`; optional content ships as empty tables. `BIB_CONFIG` loses `ai_data_path`, `rix_path` and their setters.
- **Data packs, no plug-ins** (debate 03 pathway B′): `BIB_PLUGIN`, `BIB_PLUGIN_REGISTRY`, `BIB_LENS` and `BIB_LENS_RESULT` are gone; `BIB_PRIVATE_SOURCE` is the effective generic pack source in `src/pack/` (voice and `user_version` checked at attach); `BIB_CONFIG` gains `pack_folder`. Packs attach through `SIMPLE_SQL_DATABASE.attach_read_only`.
- **Notes** (debate 02 pathway B): `BIB_DB_NOTE_STORE` is the Release 1a store, with `export_notes` and `import_notes` under the verdict's contracts and a working `is_file_safe_name`; `BIB_MARKDOWN_NOTE_STORE` is the 1b candidate.
- Tests: `TEST_PACK_PURITY` (was `TEST_PLUGIN_PURITY`), `TEST_CONCORDANCE`, file-name tests.

### Fixed

- **Design scan 23** (`.eiffel-workflow/evidence/design-scan-since-1398860.md`: 2 HIGH, 8 MEDIUM, 5 LOW). HIGH: the purity and layering tests never read `src/pack` or `src/concordance`, because `SOURCE_SCAN` kept a fixed folder list that still named `src/plugin`; it now lists `src`'s folders when it runs (`test_scan_sees_every_source_folder` failed before). HIGH: `BIB_WORD_VIEW.facts_model` was always empty, so `fact_closure` could not fail; it now lists the entry, the place total and the first page (testable only once Phase 4 can build the values: skeletal `test_word_view_lists_every_fact`). MEDIUM fixed: `is_file_safe_name` refuses COM0/LPT0, the superscript-digit forms, CONIN$/CONOUT$ and "NUL .md" (`test_file_safe_name_scan23_gaps` failed before); export names must be distinct; import requires a writable store and accounts for unchanged notes; a generic pack cannot take the alias `conc`; the concordance pack counts against the attach slots. Open (Phase 4, in the report): checking the concordance pack at open, attach #11 versus FR-138, the author library still described as its own file. 73 pass, 52 skeletal, 0 fail.

- **Tests run from any folder.** `SOURCE_SCAN` read the engine ECF and sources relative to the working folder, so the layering and purity tests failed when the suite ran from elsewhere (found by a design-debate spike). Paths now resolve against `SOURCE_SCAN.root`: the working folder when it holds `simple_bible.ecf`, otherwise `$SIMPLE_EIFFEL/simple_bible`. Verified from both locations: 69 pass, 47 skeletal, 0 fail, 0 warnings.

## [0.1.0] - 2026-10-06 — design and engine contracts

### Added

- **Research** (`.eiffel-workflow/research/`): scope, landscape (53 sources), requirements, decisions D-001 to D-020, innovations, risks and recommendation; plus a harvest ledger for retiring simple_scholar, a feature-parity study of e-Sword and Logos, innovations drawn from practice, a world-timeline design with a 61-event pilot, a Septuagint source plan (Swete by default), and a user-voice study (294 items, 96 sources).
- **GUI spec** (`.eiffel-workflow/gui/`): layout and operation on native simple_widgets. A Simple mode (three-pane reader) and a Study mode (docked panels, link sets). 14 panels, 10 dialogs, 25 SVG mockups, the state machine, and 26 simple_widgets gap work items.
- **Specification** (`.eiffel-workflow/spec/`, 8 steps) and the approved **intent** (`intent-v2.md`, 57 Release 1a and 10 Release 1b acceptance criteria).
- **Engine library contracts** (Phase 1): 150 `BIB_*` classes, 16 deferred, with full contracts, MML model queries on all 53 collection attributes and 32 `|=|` frame conditions. "The engine owns every fact" is enforced through `BIB_SOURCED`, `fact_closure` postconditions on 27 features, mandatory provenance keys, four-bucket census and shape results, and restricted creation of mapped references and AI text.
- **Tests**: 21 test classes, 116 tests (69 pass, 47 skeletal reported as SKIP, 0 fail), plus a SCOOP consumer test. Compile gate: 0 errors, 0 warnings.

### Known gaps (to fill in fleet libraries)

- SQLite in eiffel_sqlite_2025 is 3.31.1, and its externals are not marked `blocking`.
- No Unicode normalization in the fleet yet (simple_encoding). Search normalization waits on it.
- simple_hash takes only 8-bit paths.
