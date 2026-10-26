# 17. The concordance pack, schema v1 (2026-10-26)

*What the engine expects of conc.db (and later conc_dist.db). Written for Phase 4, Task 0 (the builder, in the vault's `_Tools`) and Task 2 (the test fixture, `testing/conc_fixture.e`). The tables below are conc.db's own definitions as built 2026-10-21, read from the file; v1 adds three things.*

## What v1 adds to today's conc.db

| Item | Definition | Why |
|---|---|---|
| `PRAGMA user_version = 1` | set by the builder after the last step | FR-165; `BIB_CONC_PACK.Expected_user_version`; the engine refuses any other value (FR-164, verdict condition 3) |
| `token.translit` | `TEXT`: whole-word transliteration of `surface` | FR-155, FR-162; empty when the surface is empty (6,435 Hebrew tokens) and for English |
| `lemma_corpus_count` | `(lemma_id INTEGER, corpus_id INTEGER, n INTEGER, PRIMARY KEY(lemma_id, corpus_id))` | FR-162: "how often", per corpus, without counting tokens at view time (NFR-019) |
| `work_book` | `(work_id INTEGER PRIMARY KEY, book_id INTEGER NOT NULL)`; `book_id` is the engine's book id (bible.db `bible_books.id`, FR-105) | conc.db's work ids are not the engine's book ids (Matthew is work 56 in conc.db, book 40 in bible.db); the builder matches them once, so the engine joins by key, never by book name (FR-024) |
| `meta` row `edition_label` | for conc.db: `PERSONAL EDITION - not for distribution` (FR-157) | The title bar and About read the edition from the pack, so no engine code tests the edition (FR-158) |
| `lemma_english` | `(lemma_id INTEGER, corpus_id INTEGER, english TEXT, n INTEGER, PRIMARY KEY(lemma_id, corpus_id, english))`; `corpus_id` is the English Bible; one row per original headword, English Bible and English word | FR-162: English at a glance without walking `link` at view time |

## Tables the engine reads (required for v1)

`corpus`, `work`, `work_book`, `unit`, `lemma`, `token`, `link`, `lemma_xref`, `meaning_source`, `lex_sense`, `lemma_corpus_count`, `lemma_english`, `meta` (with `edition_label`). `BIB_CONC_PACK.check_pack` refuses a pack missing any of them.

## Facts the engine relies on (read from conc.db, 2026-10-26)

| Fact | Evidence |
|---|---|
| `token.lemma_basis` is `<kind>:<source>`; kinds seen: `tagged`, `computed` | review spike R2 |
| `token.language` is `hbo`, `arc`, `grc` or `eng`; `corpus.language` may be `hbo+arc` | read 2026-10-26 |
| English lemmas have no `translit` | review spike R2 |
| `link` runs from the original token to the English token; kinds `translation:ENG-BSB`, `translation:ENG-KJV`, `translation:ENG-STEP`, `translation:ENG-BRENTON`, `translation:MT->LXX`, `quotation:ODE` | read 2026-10-26 |
| `lemma_xref.scheme` values: `strongs`, `OSHB`, `louw-nida` | read 2026-10-26 |
| Provenance: `corpus.license`, `corpus.ship_class`; `meaning_source.license`, `meaning_source.ship_class` | read 2026-10-26 |

## Not in v1

`see_also`, `period_count` / `period_text`, `lsj_cite`, `eng_sense`, `unit_map` and the others stay in the file and are read by later word-view sections (centuries, going further); v1's check does not require them.
