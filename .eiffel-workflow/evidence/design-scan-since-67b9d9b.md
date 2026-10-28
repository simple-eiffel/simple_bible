# Design Scan (diff mode): simple_bible, since 67b9d9b
# Date: 2026-10-28
# Subjects: src/pack/bib_text_pack_schema.e, bib_book_schema.e, bib_essay_schema.e, bib_essay_pack.e,
#   bib_book_pack.e, bib_book_block.e, bib_author_book.e; build/bib_book_builder.e, bib_markdown_blocks.e;
#   build_app/bib_build_app.e; src/reading/bib_link_target.e; src/simple_bible.e; gui_app/bib_gui_app.e
# Mode: read-only; nothing compiled, nothing changed except this file.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction (A/D/T) | 8 | 2 | 3 | 3 |
| MI / structure | 1 | 0 | 0 | 1 |
| Contracts / drift / edge cases | 4 | 0 | 2 | 2 |
| **Total** | **13** | **2** | **5** | **6** |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | A5 | SIMPLE_BIBLE, BIB_GUI_APP | Pack-list loop is now four copies in the facade plus two in the window (scan 12 grew) |
| 2 | HIGH | A5 | BIB_LINK_TARGET | Two near-identical link branches; every new text-pack kind is a third copy |
| 3 | MEDIUM | A1/T1 | BIB_GUI_APP, BIB_BUILD_APP, BIB_BOOK_BUILDER | "Is it an essay?" decided by string compare against BIB_ESSAY_SCHEMA, plus kind nouns spelled in three places |
| 4 | MEDIUM | A6 | BIB_ESSAY_PACK, BIB_BOOK_PACK, BIB_BOOK_BLOCK | The pack kind is a redefined function that allocates a schema per call and per block; an argument at creation removes the class |
| 5 | MEDIUM | D1 | BIB_GUI_APP | Merging two packs' results broke two orderings the single pack kept (narrowest passage first; the mentions cap) |
| 6 | MEDIUM | edge | BIB_MARKDOWN_BLOCKS.from_title | A "# " line inside a fence or inside the draft note above the title becomes the start; no title is silent |
| 7 | MEDIUM | contracts | BIB_BOOK_PACK, BIB_LINK_TARGET, BIB_TEXT_PACK_SCHEMA | Kind-aware contracts missing (pack kind versus schema, link place range, deferred postconditions) |
| 8 | LOW | A1 | BIB_BOOK_PACK, BIB_BOOK_BLOCK, BIB_AUTHOR_BOOK | Static BIB_BOOK_SCHEMA uses in kind-neutral code (instance created per row) |
| 9 | LOW | drift | several | Comments and messages that still say "books" |
| 10 | LOW | A5 | BIB_BUILD_APP | The essays-or-books decision is made twice; both flags together silently pick essays |
| 11 | LOW | M2 | BIB_BOOK_BUILDER | make_essays builds a books schema and overwrites it; a settable flag on the splitter |
| 12 | LOW | A1 | BIB_PRIVATE_PACK_READER, BIB_PRIVATE_SOURCE | Shared constants reached through BIB_BOOK_SCHEMA |
| 13 | LOW | tests | testing | No test for from_title's edge cases |

## Detailed Findings

### Finding 1: the pack-list loop, now six copies
**Priority:** HIGH (duplicate code; previous scan finding 12 grew)
**Classes:** SIMPLE_BIBLE (src/simple_bible.e), BIB_GUI_APP (gui_app/bib_gui_app.e)
**Evidence:**
- src/simple_bible.e:187-194 commentary_packs, :196-203 framework_packs, :224-231 essay_packs, :233-240 book_packs: each is `create Result.make (1)`, `across packs_of_kind (K) as ic loop Result.extend (create {X}.make (sources, ic.alias_name, ic.pack_title)) end`. Only K and X differ.
- src/simple_bible.e:205-222 writings_search then repeats the shape a fifth time: one `across ... Result.add_pack (ic, K)` per kind, the kind written twice (once to pick the packs, once to label them).
- gui_app/bib_gui_app.e:4048-4062 library_packs: two more `across ... if ic.is_available then Result.extend (ic)` loops, one per kind; :4065-4073 library_pack loops over that list again.
- BIB_BOOK_PACK and BIB_ESSAY_PACK are now the same reader; the two facade features differ only in the class created and the kind constant.
**Description:** each new text-pack kind costs another facade feature, another writings_search loop and another window loop. Once finding 4 is applied (the pack takes its schema as a creation argument), book_packs and essay_packs collapse to one `text_packs (a_schema)`; library_packs becomes `across <<book schema, essay schema>> ... bible.text_packs (it)` and writings_search labels each pack with `ic.schema.Pack_kind`, so the kind is written once. A deferred `BIB_TEXT_PACK_SCHEMA` list (a once `Kinds`, see finding 2) drives all of them.
**Suggested Action:** /eiffel.abstract (or a refactor branch): one schema registry, one `text_packs`.
**Effort:** 2 facade features removed, 2 window loops folded.

### Finding 2: BIB_LINK_TARGET's two near-identical branches
**Priority:** HIGH (duplicate code)
**Class:** src/reading/bib_link_target.e
**Evidence:**
- :37-42 `elseif attached (create {BIB_BOOK_SCHEMA}).link_place (text) as al_place then is_book := True; book_kind := {BIB_BOOK_SCHEMA}.Pack_kind; id := al_place.book; chapter := ...; block := ...`
- :43-48 the same six lines with BIB_ESSAY_SCHEMA. Only the schema differs.
- :6 and :9 the description still says "a new kind of link (essays next)" and lists only BIB_BOOK_SCHEMA's `link_place`.
**Description:** the grammar is already shared (BIB_TEXT_PACK_SCHEMA.link_place); the class only has to ask each text-pack schema in turn. A once registry `BIB_TEXT_PACK_SCHEMA`s (books, essays) turns the two branches into one loop and the next kind into one registry entry. The registry is the same list finding 1 needs.
**Suggested Action:** /eiffel.abstract targeting BIB_TEXT_PACK_SCHEMA (a `kinds` list, plus `schema_for_link (text)`).
**Effort:** 2 branches to 1 loop.

### Finding 3: "is it an essay?" by string compare; kind nouns in three places
**Priority:** MEDIUM
**Classes:** BIB_GUI_APP, BIB_BUILD_APP
**Evidence:**
- gui_app/bib_gui_app.e:4098 `a_book.pack_kind.same_string_general ({BIB_ESSAY_SCHEMA}.Pack_kind)` picks "Essays" or "Book" (library_kind_name).
- gui_app/bib_gui_app.e:432 the snapshot picks the first essay row by the same compare.
- build_app/bib_build_app.e:104 picks " series, " or " books, " by the same compare.
- gui_app/bib_gui_app.e:4181 builds "No <id> in the <kind> pack" from the raw kind word.
**Description:** the three places want a noun for the kind ("Book"/"Essays", "books"/"series"). A deferred `Kind_noun` / `Collection_noun` on BIB_TEXT_PACK_SCHEMA, effected by constants in the heirs (the pattern already used for Link_prefix), removes the compares; a third kind then needs no edit in the window or the build program.
**Suggested Action:** /eiffel.abstract: two deferred constants on BIB_TEXT_PACK_SCHEMA.
**Effort:** 2 deferred features, 3 call sites.

### Finding 4: the schema is a function that allocates, and BIB_ESSAY_PACK exists only to redefine it
**Priority:** MEDIUM
**Classes:** src/pack/bib_essay_pack.e, src/pack/bib_book_pack.e, src/pack/bib_book_block.e
**Evidence:**
- bib_book_pack.e:192-196 `schema` is a plain function: `create {BIB_BOOK_SCHEMA} Result` on every call. It is called in :157 once per block row in blocks_answer, in :171 once per book row, and in :177, :182, :187.
- bib_essay_pack.e:25-28 redefines it with the same shape; the class has no other feature.
- bib_book_block.e:238 stores that fresh schema object in every block (a 34,000-block essays pack holds that many schema objects).
**Description:** the schema is an immutable value; the pack's kind is decided at creation. A `make_text (sources, alias, title, a_schema)` on BIB_BOOK_PACK with `schema` an attribute removes BIB_ESSAY_PACK, the per-row allocation and the redefine. If the two classes stay, make both `schema` features `once` (a once in an heir needs a redefine; the cost is the same as today).
**Suggested Action:** /eiffel.abstract or small refactor; then finding 1 collapses.
**Effort:** 1 creation procedure, 1 class removed.

### Finding 5: merged lists lost the order the single pack kept
**Priority:** MEDIUM (drift between old and new behavior)
**Class:** gui_app/bib_gui_app.e
**Evidence:**
- :4209-4222 fill_in_books appends `blocks_citing` of the books pack, then of the essays pack. BIB_BOOK_PACK.blocks_citing (src/pack/bib_book_pack.e:103-117) documents "the narrowest passage first" and orders by `p.width`; across the two packs the list is books-then-essays, so an essay paragraph that cites exactly the verse (width 0) lands below a book paragraph citing a whole chapter.
- :4469-4486 framework_page merges `blocks_naming` of both packs into `l_mentions`, then shows the first `Book_mentions_shown` (12, :4032). With 12 or more book mentions no essay mention is ever shown, and "... and N more" hides them. Before this change the cap applied to the books alone, and the list would not hide a second source.
**Description:** the order is documented in the change ("then of the essays") but the "narrowest first" promise is not kept across packs, and the cap starves the essays (the larger pack: 363 essays, against the books). Either interleave by `width` (needs the width on the block, or a merged query) or cap per pack.
**Suggested Action:** decide the order with Larry; a refactor branch.
**Effort:** 2 features.

### Finding 6: from_title edge cases
**Priority:** MEDIUM
**Class:** build/bib_markdown_blocks.e (from_title, :145-189; its caller :79-83)
**Evidence and cases read:**
- Title inside a code fence: from_title is a text search for "%N# " (:153-159), run before the line scanner knows about fences (the fence state `l_in_code` lives in split, :74-102). A "# comment" line in a fenced block above the real title, or in the draft note, becomes the start; the real title then comes out as a second level-1 heading, and the draft note's text is kept. The draft note is the exact thing the feature exists to drop.
- A "# " line inside the draft note itself (a note written as "# TODO") has the same effect.
- Other heading levels: handled correctly. "%N## " does not match "%N# " (second character is "#"), so a "## Subtitle" above the title is dropped with the note, as the comment says; a "#" with no space after is not a title.
- CRLF: handled. The title line keeps its "%R"; the skip loop (:167) steps over "%R", "%N" and " "; the production line's "%R" is pruned before the italic test (:176). Only a "%R" alone (old Mac line ends) is not a line break here, and split ('%N') treats it the same way.
- No title at all: returns the whole text including the draft note (:161-162, and the comment says so), and the builder neither warns nor fails (build/bib_book_builder.e:229-230 takes whatever blocks come out). An essay whose title is "#Title" or "Title" with a setext underline would silently keep its draft note.
- A leading space or a byte order mark before the first "# " fails the starts_with test (:153); it then needs a later "%N# ", so the title is missed.
- The production-line skip (:178-180) drops any first line after the title that is italic and holds "[[", so an essay whose first real sentence is a fully italic sentence with a wiki link loses it.
- Contract: `at_the_title` (:188) is the only postcondition on the start; there is none for "title absent keeps everything" or for the production line, and nothing checks that a skipped line was the production line.
**Description:** move the start decision into the line scanner (track fence state, find the first heading of level 1 outside a fence), or at least skip fenced regions in from_title; make the builder refuse (or warn on) an essay chapter with no "# " title through `fail_unless`.
**Suggested Action:** refactor branch plus a test (finding 13).
**Effort:** 1 feature, 1 check in the builder.

### Finding 7: contract gaps in the kind-aware code
**Priority:** MEDIUM
**Classes and evidence:**
- BIB_TEXT_PACK_SCHEMA deferred features carry no postcondition except Link_prefix (:38-43): Manifest_extension (:45-48) should end the way a manifest does (starts with "."), Builder_command (:50-53) and Starts_at_title (:55-58) none. "One deferred feature = one responsibility, postconditions mandatory."
- BIB_BOOK_PACK: nothing ties the reader's schema to the pack it reads. `make` (inherited, src/pack/bib_private_pack_reader.e:21-31) only checks the alias; a BIB_BOOK_PACK made over an essays alias reads fine but labels its blocks "book:" (BIB_BOOK_BLOCK.link, bib_book_block.e:71-74). The facade picks the class by kind (src/simple_bible.e:217,228), but the invariant lives only there.
- BIB_BOOK_PACK has no postcondition on `schema` (192-196) such as "the Pack_kind is a text pack kind".
- BIB_LINK_TARGET: the invariant (:103-107) covers `book_kind` presence but not the place a book link names; the schema's `link_place` ensure (bib_text_pack_schema.e:144-145) says chapter and block are in 0..Max_part and block > 0 implies chapter > 0, and the target loses that. Missing: `is_book implies chapter >= 0 and block >= 0 and (block > 0 implies chapter > 0)`, and `is_book implies book_kind is a known pack kind`.
- gui_app/bib_gui_app.e: library_pack (:4065-4073) has no postcondition `attached Result implies Result.schema.Pack_kind.same_string_general (a_kind)`; show_book_place (:4141) and book_card (:4225) have no `kind_given: not a_kind.is_empty`.
**Suggested Action:** add the contracts (cheap ones; none in a hot path).
**Effort:** about 8 clauses.

### Finding 8: static BIB_BOOK_SCHEMA uses in kind-neutral code
**Priority:** LOW (the user's brief: is_book_id and Max_part are fine as constants; the cost here is the instance)
**Evidence:**
- src/pack/bib_book_pack.e:152 and :169: `(create {BIB_BOOK_SCHEMA}).is_book_id (...)` creates a schema object per row; the reader already has `schema` (:192). The condition is the same for both kinds (inherited from BIB_PRIVATE_PACK_SCHEMA through the rename in BIB_TEXT_PACK_SCHEMA), so behavior is not wrong, but the class now reads as books-only.
- src/pack/bib_book_block.e:28, :30, :101 and src/pack/bib_author_book.e:25: preconditions and invariant say BIB_BOOK_SCHEMA where BIB_TEXT_PACK_SCHEMA is the owner (Max_part and is_book_id are declared there).
- No link-grammar or pack-kind assumption was found hard-wired to books outside src/reading/bib_link_target.e (finding 2): the remaining kind decisions are the string compares in finding 3 and the "books" words in finding 9.
**Suggested Action:** name {BIB_TEXT_PACK_SCHEMA}.Max_part, and use `schema.is_book_id`.
**Effort:** 6 places.

### Finding 9: comments and messages that drifted
**Priority:** LOW
**Evidence:**
- src/reading/bib_link_target.e:6 "(essays next)"; :9 lists only BIB_BOOK_SCHEMA's `link_place`; CHANGELOG.md:30 says the same as history.
- src/pack/bib_text_pack_schema.e:107-109 link_place says 'a "book:" target'; :89 link_text lists only "book:" examples; :156 pack_tables says "The books pack's own tables" (shared by both).
- src/pack/bib_private_pack_schema.e:2-9 says "The commentary, frameworks and books schemas inherit it".
- src/pack/bib_book_pack.e:3 "A books pack", :17 a comment after the class name; the class also reads essays.
- src/pack/bib_author_book.e:3 "One of Larry's books"; :4 and :348-358 describe books only.
- build/bib_book_builder.e:2-19 header describes books only; :188 "already names another book", :213 "The book ... could not be written" printed for an essay series.
- build/bib_markdown_blocks.e:2-18 header does not mention start_at_title, which has its own comment at :53-55.
- build_app/bib_build_app.e:67-68 help text "With --books:" for --content and --frameworks-pack, which --essays also uses.
- gui_app/bib_gui_app.e:4285 message "No commentary, frameworks or books pack yet" (the essays pack now counts); :4586 comment 'a "book:" link'; :4327 and src/search/bib_writing_hit.e:44 / bib_writings_search.e:51 kind lists omit "essays".
**Effort:** comments only.

### Finding 10: the books-or-essays decision is made twice
**Priority:** LOW
**Class:** build_app/bib_build_app.e
**Evidence:** manifests_named (:25-33) tests `value_of ("essays")` first; make (:88) tests `value_of ("essays")` again to pick make_essays. With both --books and --essays given, essays silently wins with no message.
**Suggested Action:** one decision returning the builder (or a schema); an error when both are given.
**Effort:** 1 feature.

### Finding 11: make_essays builds the books schema and replaces it
**Priority:** LOW
**Class:** build/bib_book_builder.e
**Evidence:** :36-45 make_essays calls `make` (which does `create {BIB_BOOK_SCHEMA} schema`, :51) and then overwrites it (:41). The splitter is then told by a setter (:220-222, BIB_MARKDOWN_BLOCKS.start_at_title, :59-65) whose flag stays set once called.
**Description:** a `make_with_schema (a_catalog, a_schema)` that `make` and `make_essays` call; `Starts_at_title` passed to the splitter at creation. Pairs with finding 4.
**Effort:** 1 creation procedure.

### Finding 12: shared constants reached through BIB_BOOK_SCHEMA
**Priority:** LOW
**Evidence:** src/pack/bib_private_pack_reader.e:57 and src/pack/bib_private_source.e:105-121 use `{BIB_BOOK_SCHEMA}.Search_table` and `.Words_table`; both are declared in BIB_PRIVATE_PACK_SCHEMA and apply to every pack kind. (Files unchanged since 67b9d9b; listed because the new heir makes the misleading name worse.)
**Effort:** 4 references.

### Finding 13: no test for from_title edges
**Priority:** LOW
**Evidence:** the one test (testing/test_facade_open.e:624-676 with Essay_text at :694-698) covers a draft note, a title, a production line and a "%N" line end. Not covered: CRLF, a "# " line in a fence or the note, no title, a leading BOM or space, an italic first sentence that is not a production line.

## Checked and found sound
- BIB_TEXT_PACK_SCHEMA.link_text / link_place keep the read_back ensure for both prefixes; `essay:` and `book:` cannot be confused because the prefixes share no start, so the branch order in BIB_LINK_TARGET is safe.
- BIB_AUTHOR_BOOK.pack_kind and BIB_BOOK_BLOCK.pack_kind give the window the kind without a second query; show_book_place's row selection compares kind as well as id (gui_app/bib_gui_app.e:4161), so a book and a series with the same id do not select each other.
- Table names stay `book_*` in the essays pack (src/pack/bib_text_pack_schema.e:159-166): deliberate (one reader), noted only so the next reader is not surprised.

## Recommended Order

1. Findings 4, 11, then 1 (pack takes its schema; builder takes its schema; one `text_packs`): removes a class and two loops, and finding 1's copies follow.
2. Finding 2 with a small schema registry (the same list drives findings 1 and 2).
3. Finding 6 (from_title in the fence-aware scanner) with finding 13's tests, before the next essay batch is built: the first batch is 363 essays.
4. Finding 5 (decide the cross-pack order with Larry).
5. Finding 3, 7, then the comment sweep (8, 9, 10, 12).
