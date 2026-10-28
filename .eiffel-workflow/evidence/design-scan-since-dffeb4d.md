# Design Scan (diff mode): simple_bible, since dffeb4d
# Date: 2026-10-28
# Mode: read-only, no compile. Subjects: classes changed dffeb4d..HEAD
# Subjects: src/pack/bib_text_packs.e (new), src/pack/bib_book_pack.e, src/pack/bib_text_pack_schema.e,
#   src/pack/bib_book_schema.e, src/pack/bib_essay_schema.e, src/reading/bib_link_target.e,
#   src/simple_bible.e, build/bib_book_builder.e, build/bib_markdown_blocks.e,
#   build_app/bib_build_app.e, gui_app/bib_gui_app.e, testing/test_facade_open.e
#   (src/pack/bib_essay_pack.e deleted)

## Verdict on the two previous HIGH findings

| Previous HIGH | Verdict | Evidence |
|---|---|---|
| 1. Pack-list loops (one loop per kind in facade, window, search) | RESOLVED | `src/simple_bible.e:213-256`: `writings_search` has one `across text_packs` loop (lines 216-218); `text_packs` loops `BIB_TEXT_PACKS.schemas` (224-230); `book_packs` and `essay_packs` are one-line filters over `text_packs_of_kind` (246-256). `gui_app/bib_gui_app.e:4048-4059` `library_packs` is one loop over `bible.text_packs`; the T5 loop (4211) and the framework page loop (4470) iterate `library_packs`. No other `book_packs`/`essay_packs` caller remains in src, build, build_app or gui_app (grep). |
| 2. Link-target branches (one `elseif` per kind in BIB_LINK_TARGET) | RESOLVED | `src/reading/bib_link_target.e:37-47`: one `across (create {BIB_TEXT_PACKS}).schemas as ic until is_book loop` calling `ic.link_place`, taking `book_kind := ic.Pack_kind`; the Bible-link branch runs after it only when `not is_book` (48-57). A third kind needs no edit here. Prefix order matters (see Finding 2). |

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction | 5 | 0 | 2 | 3 |
| MI | 0 | 0 | 0 | 0 |
| Generics | 0 | 0 | 0 | 0 |
| Test gaps / drift | 3 | 0 | 1 | 2 |
| **Total** | **8** | **0** | **3** | **5** |

No new HIGH. No drift (D1) found between copies the merge touched.

## Findings

| # | Priority | Category | Classes | Opportunity | Effort |
|---|----------|----------|---------|-------------|--------|
| 1 | MEDIUM | contract gap | BIB_TEXT_PACKS | `schemas` list is not checked for distinct kinds/prefixes, and is a shared mutable once list | 1 postcondition |
| 2 | MEDIUM | A4 | BIB_TEXT_PACKS, BIB_LINK_TARGET | First-match semantics (`until is_book`, `schema_of_kind`) rely on unique, non-overlapping prefixes nothing enforces | same fix as 1 |
| 3 | MEDIUM | test gap | test_facade_open | Merge's fixes with no test: BOM, `--books` + `--essays` refusal, `schema_of_kind`/`Kind_noun`, `text_packs_of_kind` | 3 tests |
| 4 | LOW | A1 / drift | BIB_BOOK_PACK, BIB_AUTHOR_BOOK, BIB_BOOK_BLOCK | Still names BIB_BOOK_SCHEMA (not its own `schema`) for id and Max_part rules | 5 sites |
| 5 | LOW | naming | BIB_BOOK_PACK | The one reader of every text pack keeps the name "book pack" (and BIB_BOOK_SCHEMA constants such as `Search_table`) | rename, optional |
| 6 | LOW | A1 | bib_build_app | CLI still picks the builder by `--essays` string, not by the schemas' own `Builder_command`/kind list | 2 sites |
| 7 | LOW | placement | BIB_MARKDOWN_BLOCKS | `without_mark` sits under "An essay's start" but now applies to books too; postcondition is weak | 1 feature |
| 8 | LOW | A1 | bib_gui_app | Snapshot tab `"essays"` still compares against `BIB_ESSAY_SCHEMA.Pack_kind` | 1 site |

## Detailed Findings

### Finding 1: BIB_TEXT_PACKS.schemas is an unchecked, shared, mutable once list
**Priority:** MEDIUM
**Classes:** src/pack/bib_text_packs.e
**Evidence:**
- `bib_text_packs.e:16-24`: `schemas: ARRAYED_LIST [...]` is a `once` function; its only postcondition is `some_kind: not Result.is_empty`. Every caller (`simple_bible.e:224`, `bib_link_target.e:38`, `bib_text_packs.e:29`) gets the SAME list object, so any caller that does `.extend` or `.wipe_out` changes every other reader's view (the contract cannot catch it: the postcondition holds at first evaluation only).
- A new `BIB_TEXT_PACKS` object is created at every use (`create {BIB_TEXT_PACKS}` at `bib_link_target.e:38`, `simple_bible.e:224`, `bib_gui_app.e:4094`) only to reach the once; the class has no state.
- Nothing states that kinds are distinct: two schemas sharing a `Pack_kind` or a `Link_prefix` would pass every current contract.
**Suggested Action:** give `schemas` the postcondition `distinct_kinds` (no two share `Pack_kind`; no `Link_prefix` is a prefix of another), and expose the list as read-only (return a copy or `ITERABLE`/`LINEAR`) or document it as frozen. Optional, per the project's SCOOP stance: a `once ("PROCESS")` is safe only if the list is immutable.
**Effort:** 1 postcondition, 1 return type.

### Finding 2: First-match lookups depend on unenforced uniqueness
**Priority:** MEDIUM
**Classes:** src/pack/bib_text_packs.e, src/reading/bib_link_target.e
**Evidence:**
- `bib_link_target.e:38-47` stops at the first schema whose `link_place` is attached; `bib_text_packs.e:26-36` returns the first schema of a kind (it also scans to the end, without `until`).
- Today `"book:"` and `"essay:"` (`bib_book_schema.e:27`, `bib_essay_schema.e:30`) never collide, so this is correct. The old hand-written branches had the same hidden assumption; the loop made it a library-wide one.
**Suggested Action:** same postcondition as Finding 1 closes both.

### Finding 3: The merge's fixes are mostly untested
**Priority:** MEDIUM
**Classes:** testing/test_facade_open.e
**Evidence:**
- The only new test (`test_facade_open.e:675-682`) covers the missing-title refusal. Grep of `testing/` finds no use of `BIB_TEXT_PACKS`, `text_packs`, `schema_of_kind`, `Kind_noun`, or a byte-order mark (code 65279).
- Not covered: `without_mark` (`build/bib_markdown_blocks.e:145-154`), the `--books` with `--essays` refusal (`build_app/bib_build_app.e:79-83`), `library_kind_name` through `Kind_noun` (`gui_app/bib_gui_app.e:4092-4101`), `text_packs_of_kind` and `text_packs` ordering (books before essays), the framework page's per-pack cap of 12 with the "... and N more" line (`bib_gui_app.e:4467-4488`).
- Existing tests reach the new loops indirectly (`book_packs`/`essay_packs` at `test_facade_open.e:477, 656-657`; `BIB_LINK_TARGET` essay link at 668-669), so the loop paths are exercised, but the BOM and cap behavior are not.
**Suggested Action:** add a BOM-prefixed chapter test (title found, blocks start at the heading), a `schema_of_kind` / `Kind_noun` test, and a cap test with 13 mentions in one pack.

### Finding 4: BIB_BOOK_PACK and the value classes still name BIB_BOOK_SCHEMA for shared rules
**Priority:** LOW
**Classes:** src/pack/bib_book_pack.e, src/pack/bib_author_book.e, src/pack/bib_book_block.e, src/pack/bib_private_pack_reader.e
**Evidence:**
- `bib_book_pack.e:166-167, 183`: `(create {BIB_BOOK_SCHEMA}).is_book_id` and `{BIB_BOOK_SCHEMA}.Max_part` inside a reader whose `schema` attribute (line 206) is the right owner. Both constants are inherited unchanged by the essay schema, so behavior is equal today; the code would silently apply the books' rules if a kind ever overrode them.
- `bib_author_book.e:25`, `bib_book_block.e:28, 30, 101` do the same in preconditions/invariant; `bib_private_pack_reader.e:57` and `bib_private_source.e:105-121` reach `Search_table`/`Words_table` through BIB_BOOK_SCHEMA (these are pack-wide constants of BIB_PRIVATE_PACK_SCHEMA; naming the ancestor would be accurate).
**Suggested Action:** use `schema.*` in the reader; name the true declaring ancestor for shared constants. Cosmetic until a third kind differs.

### Finding 5: One reader for every text pack still called BIB_BOOK_PACK
**Priority:** LOW
**Classes:** src/pack/bib_book_pack.e:15-17
**Description:** A comment at line 17 explains it; the type is the return type of `text_packs`, `essay_packs`, `library_packs`, `library_pack` and so reads as books-only in clients. A rename (BIB_TEXT_PACK) is a repository-wide edit; only on Larry's word.

### Finding 6: bible_build still selects the builder by flag text
**Priority:** LOW
**Classes:** build_app/bib_build_app.e
**Evidence:** lines 28-33 (`manifests_named`) and 93-97 (`make_essays` vs `make`) compare the literal flags `"essays"`/`"books"`; the flag text duplicates `Builder_command` (`bib_essay_schema.e:35`, `bib_book_schema.e:32`). The refusal added at 79-83 and the Entries_noun message (110) are good; the remaining branch is CLI-level and acceptable until a third kind.

### Finding 7: without_mark placement and contract
**Priority:** LOW
**Classes:** build/bib_markdown_blocks.e:145-154
**Evidence:** declared under "An essay's start" yet applied on both branches of `split` (lines 80, 82), so books also lose a leading BOM (a behavior change, harmless and arguably correct). Postcondition `at_most_one_less` does not say the mark is removed only when present; `Result = a_text` aliases the argument when no mark is found (callers only read it, so safe).
**Suggested Action:** move to the "Splitting" implementation group; strengthen ensure: `Result.count = a_text.count or Result.count = a_text.count - 1`.

### Finding 8: snapshot tab compare
**Priority:** LOW
**Classes:** gui_app/bib_gui_app.e:426-434
**Evidence:** `"books"` and `"essays"` tab names and `{BIB_ESSAY_SCHEMA}.Pack_kind` remain hard-wired in the snapshot harness (a test/diagnostic path, not product behavior). Could loop `BIB_TEXT_PACKS.schemas` like the rest.

## Checks requested, answered

- **Void safety of `make_with_schema` setting `schema` before the inherited `make`** (`bib_book_pack.e:27-37`): sound. `schema` is a plain attached attribute (line 206) with no default; `make_with_schema` is the class's only creation procedure (line 23) and assigns it before calling `make`, so it is attached at the end of the creation procedure. The inherited `make` (`bib_private_pack_reader.e:22-33`) touches only `sources`, `pack_alias`, `title`; it calls no feature that reads `schema` (`pack_noun`, `not_open_message`, `query_failed_message` are only called later from queries). `make` is not itself a creation procedure here, so no client can create a pack without a schema. The class has no invariant naming `schema`. (Static reasoning only; not compiled, per instructions.) Residual: `a_schema` is not required to be a member of `BIB_TEXT_PACKS.schemas`, so a pack of an unregistered schema would be invisible to `text_packs` and `BIB_LINK_TARGET` (folded into Finding 1).
- **Same pattern in BIB_BOOK_BUILDER** (`build/bib_book_builder.e:34-63`): `make` and `make_essays` now delegate to `make_with_schema`, which sets `catalog`, `schema`, `records`, `framework_spellings` and ensures `schema_set`. This removes the old double-assignment of `schema` (create then overwrite), which was the former void-safety/ordering hazard. Note `make_essays` lacks the `schema_set` postcondition that `make_with_schema` has (it ensures `catalog_set` only; the essays check it had before was dropped). Minor.
- **Title check** (`bib_book_builder.e:238-239`): guarded (`not is_empty and then first.kind ... and then level = 1`), only active for `Starts_at_title` schemas, and its message ends in the internal jargon "(scan 62: ...)" in a user-visible build error. Cosmetic.
- **Remaining hard-wired book/essay string compares:** library_kind_name, build report noun, and the facade loops are now schema-driven. What remains: `bib_gui_app.e:426-432` (Finding 8), `bib_build_app.e:28-33, 93` (Finding 6), `simple_bible.e:249, 255` (the two named convenience filters, intended), and prose comments. No `same_string ... "essays"` compare remains in `src/`.
- **Drift:** none found. `writings_search` (kinds in `add_pack`) now reads `ic.schema.Pack_kind`, same value as the former constants.
- **Cost note (no finding):** `text_packs` rebuilds every pack object on each call and `book_packs`/`essay_packs`/`library_pack` each call it (`simple_bible.e:222-256`, `bib_gui_app.e:4061-4070`, used per hover card at 4149, 4228). `packs_of_kind` is an in-memory filter (`simple_bible.e:173-183`) and `make` only stores three fields, so this is cheap; not worth caching.

## Recommended Order

1. Findings 1 and 2 together: one `distinct_kinds` postcondition on `BIB_TEXT_PACKS.schemas`, plus return the list read-only. Smallest change, protects the "a new kind is one more schema" promise.
2. Finding 3: add the BOM, `schema_of_kind`/`Kind_noun` and mention-cap tests before the next item starts.
3. Findings 4-8: cosmetic; fold into the next edit of each file.
