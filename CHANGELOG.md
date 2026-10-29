# Changelog

All notable changes to simple_bible are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added (2026-10-29: Ask, and the 0.7.31 plan; personal installer 0.7.31)

- **Ask** (C6.5, the toolbar): a request in plain words. Larry's ruling (D-016, 2026-10-29): only the Cactus Needle CPU engine ships, in a separate helper (`needle_helper.exe` with `libneedle.dll`, the fine-tuned model and the tool list, installed in an `ask` folder beside the program, with Cactus's Apache-2.0 license and our NOTICE). The program never loads its DLL: `BIB_ASK_HELPER` (the new `ask` cluster) checks the files, starts the helper at the first request, speaks JSON lines with it, sets Cactus's telemetry switches off, and turns Ask off with its reason on any failure or a reply past ten seconds. `BIB_ASK_CHECK` applies NEEDLE's rules before anything runs: the tool and its keys, a reference that reads, every number typed, versions (the reader's words win; ESV and the like refused; testaments), every word typed, a query mended and read, a scope that exists, the internet refused. A reference the box reads opens without asking. The checked calls run with the window's own actions (open, parallel, word study, words behind, cross-references, interlinear, commentary, search); anything refused goes to the search box as typed. Help > About shows Ask's state; each request is logged on this machine (`ask_log.txt`).
- **Back to results** in the Author Library after opening a Writings hit there.
- **Essays**: a heading straight under the title reads as the subtitle, in italics.
- **`bible names`**: every name of the books, essays and frameworks with the link it opens, for NEEDLE's tool data (1,547 names today).
- **The block splitter**: a hash ending a heading word kept ("C#"); comments inside code kept; an unclosed `<!--` keeps the text after it and the build warns. Tests 201.

### Added (2026-10-28: the names of Larry's books and essays link; personal installer 0.7.30)

- **The packs keep the names an essay goes by** (`chapter_alias`: "JESUS 06: Isaac's Word", "JESUS 06"), from the manifests' per-chapter `aliases`, checked unique across the pack and never a framework's spelling. `BIB_BOOK_PACK.name_links` gives every book's and chapter's name with the link it opens; `BIB_REFERENCE_LINKER.writing_names` links them by the frameworks' rule (as written, a word of its own, longest first). In the window every page the linker writes (the commentary, the frameworks, the books and essays) links them: 56 of the commentary's 300 Further reading items name a book or an essay.

### Changed (2026-10-28: design scan 62; packs rebuilt; personal installer 0.7.29)

- **One list of text-pack kinds**, `BIB_TEXT_PACKS` (books, then essays): `SIMPLE_BIBLE.text_packs` builds every kind's readers in one loop (`book_packs`, `essay_packs` filter it), `BIB_LINK_TARGET` reads every kind's links in one loop, and the window's library uses it. One reader, `BIB_BOOK_PACK.make_with_schema`, takes its schema at creation (`BIB_ESSAY_PACK` is gone, and no schema is made a row); the builder's `make_with_schema` likewise. The schema names its kind (`Kind_noun`, `Entries_noun`) where three places compared strings.
- An essay with no "# " title is refused by name (it kept what stood above; test fails on the old builder); a byte-order mark before a title is read past; `bible_build` refuses `--books` with `--essays`; a framework's page shows up to twelve mentions from each pack, so the essays show beside a book that names it often.
- Packs rebuilt from COMMENTARY's latest: books.db 14 books (batch 2: *The Bible You Think You Know* v3; drafts HA-SHEM 4-6, Epilogue, Bent, *The Hebrew Recovery Toolkit*), 287 chapters, 19,922 blocks; essays.db 46 series, 378 essays (JESUS 13-33 as drafts; CREDITED held); commentary.db 4,728 claims (1 John's labelled leans); frameworks.db the revised cards.

### Added (2026-10-28: Larry's essays; personal installer 0.7.28)

- **The essays pack** (`essays.db`, private): one manifest per series (`<id>.essay.json`, written by the COMMENTARY session; a series is a book, an essay a chapter), links `essay:<series>/<essay>#<block>`. Built by the books' builder and read by the books' reader: `BIB_TEXT_PACK_SCHEMA` holds the tables and link grammar, `BIB_BOOK_SCHEMA` and `BIB_ESSAY_SCHEMA` name the kind, file, title, link prefix and manifest extension; `BIB_ESSAY_PACK` is `BIB_BOOK_PACK` over the essays' schema; `bible_build --essays <folder> --out essays.db`. An essay begins at its title: a draft note above it, and an italic production line of wiki links right under it, are left out. First batch: 47 series, 363 essays, 34,308 blocks, 11,649 references.
- **In the window**: the Author Library lists the books, then the essay series (a Kind column); T5's tab, now **Books & essays**, lists both for the verse; a framework's page lists **Where the books and essays discuss it**; `essay:` links open and show a card; the writings search covers the essays. Snapshot option `essays`.
- commentary.db 14 books (1 John: 207 sections, 4,719 claims).

### Changed (2026-10-28: design scan 61; personal installer 0.7.27)

- **The pack rule's exemption names the search tables only**: `writing_search` (FTS5, and it must carry `voice`), `writing_words` (its fts5vocab) and the search table's five shadow tables. Any other virtual table answers to the voice rule like a table, so a stray one is refused (test fails on the old rule, which exempted every virtual table and its shadows).
- **One clause walk for both searches**: `BIB_CLAUSE_WALKING [G]` walks the parser's tree (OR; AND with its NOTs taken away); `BIB_VERSE_SEARCH` combines places, `BIB_WRITINGS_SEARCH` writes an FTS5 expression. The two copies had drifted.
- The writings search says which pack's search failed (it read as nothing found) and which held more rows than it lists; fuzzy search sweeps a pack's words once, and `BIB_EDIT_DISTANCE` keeps three rows, not a table a word. `BIB_LINK_TARGET` reads `bible:` with `BIB_BIBLE_LINK`.

### Added (2026-10-28: searching Larry's writings, plain and fuzzy; personal installer 0.7.26)

- **Every private pack carries a search table** (research/20-WRITINGS-SEARCH.md): FTS5 `writing_search` (the address a reading pane follows, where it stands, the text, its voice; diacritics folded) and its vocabulary `writing_words`, filled by the builders: a book's every block, a framework's hover and sections, a commentary section's fields (not the quoted Bible text). The attach rule exempts virtual tables and FTS5's shadow tables.
- **`BIB_WRITINGS_SEARCH`** (`SIMPLE_BIBLE.writings_search`): the Bible search's grammar (words, "phrases", word*, AND, OR, NOT, parentheses) as one FTS5 expression per pack; **fuzzy** widens each plain word to the pack's own words within one edit (up to five letters) or two (`BIB_EDIT_DISTANCE`, transpositions counting one, which fills the old unimplemented stub); by pack kind and within an address ("book:beacon", "framework:prism"); one hit a place a reader can open, best first; a pack built before search is named, not failed. The contract NEEDLE asked for: search_writings(query, pack?, within?).
- **In the window**: the search box's scope list ends with **My writings** and **My writings (fuzzy)**; the hits fill T6's new **Writings** tab (pack, where, the words with the matches marked); a hit opens where it stands. **Command line**: `bible writings "<query>" [--fuzzy] [--pack KIND] [--within PREFIX] [--packs FOLDER]`, one hit a line.
- `BIB_BIBLE_LINK`: the "bible:" link grammar, out of the linker (which inherits it), so a builder writes passage addresses without a book catalog.
- Packs rebuilt with search: commentary 9.9 MB, frameworks 0.45 MB, books 10.5 MB. Snapshot option `writings`.

### Changed (2026-10-28: design scan 59, the seven HIGH findings; personal installer 0.7.25)

- **The reference reader's two faces ask for a book in one order** (exact name, then a standard short form, then, in the reference box only, a prefix): the box now reads "gn 1:1", "Mt 5:3", "1pet 1:3", and prose links the compact forms ("1Pet 1:3", "1John 1:9"), which the short-form table held but never reached. Test first: the old reader fails it.
- **One link reader**, `BIB_LINK_TARGET` (framework, book or Bible passage, read once): the window's click and hover card and the books builder's indexes ask it, so the essays' links will be one more branch.
- **One private-pack schema ancestor**, `BIB_PRIVATE_PACK_SCHEMA` (the kind, file, title, version, author, the `meta` and `source_provenance` tables, lowercase ids), inherited by the commentary, frameworks and books schemas; `BIB_PACK_WRITING` gains `begin_private_pack`, `put_private_provenance`, `sidecars_with` and `fail_unless`, which the builders had copied. The rebuilt packs are the same: identical tables, meta, provenance and counts.
- **Book links name at most chapter and block 9999** (`BIB_BOOK_SCHEMA.Max_part`), in the contracts and the builder, where the link postcondition could fail before.
- In the window: one hover-card builder (passage, framework, book) and one way a pane comes into view (`bring_into_view`: Study layout, another pane's maximizing put back, a folded zone opened); the Frameworks tab now switches to Study like the others.

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
