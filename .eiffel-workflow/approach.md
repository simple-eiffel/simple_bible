# Approach: the concordance slice (Phase 2 review input, 2026-10-26)

*BLUE's position paper for the Phase 2 review of the concordance slice: specific enough to be attacked. Scope: `src/concordance/` (9 classes) and the classes it stands on (`BIB_SOURCE_SET`, `BIB_DATA_SOURCE`, `BIB_CONTENT_SOURCE`, `BIB_PRIVATE_SOURCE`, `BIB_CONFIG`, `SIMPLE_BIBLE`). The rest of the engine (150 classes) is reviewed in later cycles, one scope per cycle.*

## Architecture

| Class | Role |
|---|---|
| `SIMPLE_BIBLE` | Facade per SCOOP processor. `open` opens content.db, attaches the generic packs from the pack folder and the concordance pack from `config.conc_path`; hands out `conc_pack`, `word_lookup`, `english_index`, `verse_word_lookup` (once per instance, `require is_open`). |
| `BIB_CONFIG` | Builder: `core_path` (content.db), `conc_path` (conc.db or conc_dist.db: the edition swap is this one path), `pack_folder`, `user_path`. |
| `BIB_SOURCE_SET` | One SQLite connection per processor. `open_core` opens content.db read-only as main; `attach` calls `SIMPLE_SQL_DATABASE.attach_read_only` (at most 10 pack slots). |
| `BIB_CONC_PACK` | Owns every SQL statement against the conc.db schema (FR-024: joins by `lemma_id`, `token_id`, `unit_id`, never display strings). `is_available` = the alias `conc` is attached. Queries: `word_entry`, `headwords_for_strongs` (via `lemma_xref` only), `place_total`, `place_page`, English rows, verse words. `Pack_alias = "conc"`, `Max_page_size = 200`. |
| `BIB_WORD_LOOKUP` | The word view (research/14 section 3 order): heading, how often, English at a glance, dictionaries, centuries, callout, every place (paged), Greek OT, going further, notes. |
| `BIB_ENGLISH_INDEX` | An English word to the original words behind it, Bible by Bible, with counts. |
| `BIB_VERSE_WORDS` | A reference to every word of the verse in every corpus, each a door to its word view. |
| `BIB_WORD_ENTRY`, `BIB_PLACE_ROW`, `BIB_ENGLISH_ROW`, `BIB_VERSE_WORD` | Values; each `BIB_SOURCED` (provenance from `corpus.license` / `ship_class` and `meaning_source`). |
| `BIB_WORD_VIEW` | The assembled view; `facts_model` lists entry, total and first page (fact closure). |

## Data flow (a word view)

1. Face asks `word_lookup.view (lemma_id, corpus)` on the lookup worker (its own `SIMPLE_BIBLE`, its own connection).
2. `BIB_WORD_LOOKUP` asks `BIB_CONC_PACK` for the entry, the per-corpus totals, the English summary and the first page of places.
3. `BIB_CONC_PACK` runs parameterized SQL on `conc.*` through simple_sql (`run_query` for small results; the lazy `query_cursor` for long lists, fixed 2026-10-26: 88,444 rows in 370 ms lean).
4. Rows become values with provenance; the view is returned with its method and citations; `fact_closure` holds.

## Schema read (conc.db, read-only, as built 2026-10-21)

`lemma` (lemma_id, language, key, headword, translit, pron, n_tokens), `token` (token_id, corpus_id, unit_id, pos, surface, lemma_id, morphology, sense), `unit` (corpus, work, div1-3), `link` (English to original, MT to LXX), `lemma_xref` (Strong's and others), `lex_sense`/`meaning_source`, `period_count`, `see_also`, `corpus` (license, `ship_class`). Builder additions decided (FR-162, FR-165): `token.translit`, per-corpus counts and the English summary per headword, `PRAGMA user_version`.

## Implementation order (Phase 4)

1. `BIB_SOURCE_SET` real open and attach (simple_sql `make_read_only`, `attach_read_only`).
2. `BIB_CONC_PACK` queries, ported from the pilot's SQL (`conc_pilot.py`, reference only; D-020), each with a test against a small conc.db fixture.
3. The three lookups; CLI exposure (FR-061); the face (simple_widgets virtual grid) after.

## Key design decisions (locked inputs)

Debate 05a (pack, read-only, translit precomputed), 05b (pathway B, no deferred seam until a second implementor), settlements S1, S6, G1-G3 (spec 00-FOLD).

## Risks

| Risk | Evidence | Plan |
|---|---|---|
| First screen of the commonest words: about 200 ms warm, 2.8 s cold | 05b addendum, S1 run5 | Builder precomputes per-corpus counts and the English summary (FR-162) |
| Deep pages under OFFSET paging | review spike R1: 121.5 ms at row 88,200 vs 0.5 ms keyset | Under test in this review (claim R-C3) |
| `token.translit` not yet in conc.db | 05a | Builder change in the vault tooling (Python allowed for the private pack) |
| conc.db `user_version` is 0 | settlement S6 | Builder sets it (FR-165) |
