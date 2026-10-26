# Phase 2 Execution Record: the concordance slice (2026-10-26)

*Step 3, main thread. Harness: Windows 11 Pro 10.0.26300, EiffelStudio 25.02.9.8732, `ec.sh` modes only, F_code, assertions on; SQLite 3.53.4 in the engine (eiffel_sqlite_2025), Python's SQLite 3.50.4 for the paging spike. Logs read, not the summary line.*

## E1. Compile, every target, assertions on

| Command (from the project folder) | Result (read from the log) |
|---|---|
| `ec.sh check -config simple_bible.ecf -target simple_bible` | 0 errors, 0 warnings, `System Recompiled.`, target found |
| `ec.sh test -config simple_bible.ecf -target simple_bible_tests` | 0 errors, 0 warnings, F_code built |

## E2. Test run

`./EIFGENs/simple_bible_tests/F_code/simple_bible.exe`:
```
Results: 73 passed, 52 skipped (skeletal), 0 failed
ALL RUN TESTS PASSED (52 skeletal, Phase 5)
```
No contract violation tripped. In scope: TEST_CONCORDANCE `test_pack_absent_until_attached` PASS (R-C1's precondition chain holds with nothing attached), `test_pack_rules` PASS (alias `conc`, page size 200); `test_word_view_in_pilot_order`, `test_english_lookup_counts_per_bible`, `test_verse_lookup_every_corpus`, `test_word_view_lists_every_fact`, `test_edition_swap_needs_no_code` SKIP (skeletal: the value classes' creators are Phase 4 stubs). TEST_PACK_PURITY 4 run, all PASS, now reading `src/pack` and `src/concordance` (scan 23).

## E3. Spike R1: offset paging versus keyset paging (claim R-C3)

`review/spikes/R1-offset-vs-keyset/paging.py`, read-only against conc.db (1,226,866,688 bytes), the Greek article in the LXX (lemma 9380, 88,444 places), best of three runs, 200-row pages. Could have failed: OFFSET pages as fast as keyset at every depth, or the two returning different rows.
```
sqlite 3.50.4 | places: 88444
page at row      0: OFFSET    26.6 ms | keyset   30.4 ms | same rows: True
page at row  44000: OFFSET    64.4 ms | keyset    0.4 ms | same rows: True
page at row  88200: OFFSET   121.5 ms | keyset    0.5 ms | same rows: True
```
Reading: identical rows; OFFSET cost grows with depth (SQLite steps past every skipped row), keyset (`AND t.token_id > last ORDER BY t.token_id LIMIT 200`) stays under 1 ms past the first page. R-C3 as written (`a_offset`) holds within NFR-002's 2 s for this word, but scrolling a virtual grid to the end costs roughly 250 times more per page than keyset; for a 50,000-place Hebrew word in a cold cache the gap grows (first touch was 2.8 s in 05b's addendum). The cost sits inside SQLite before any Eiffel row exists, so Python's SQLite measures it fairly; the engine adds its row building on top (lean: about 0.004 ms per row).

## E4. Earlier executed evidence in scope (read raw, carried in)

| Item | Source |
|---|---|
| Attach read-only on a read-only connection; SQLite refuses writes | debate 05a, S1 run4 |
| Attached queries as fast as direct | debate 05a, S1 run4 |
| First screen: commonest words about 200 ms warm, 2.8 s cold | debate 05b addendum, S1 run5 |
| simple_sql lazy cursor: 88,444 rows in 370 ms lean (was 20,690 ms) | simple_sql 5c987a1, run4 |
| Static scan reads every source folder (scan 23) | `test_scan_sees_every_source_folder` |

## E6. Spike R2: conc.db's data shape against the value contracts (added after BLUE, main thread)

BLUE could not locate conc.db, so RED's data counts had no second reading. `review/spikes/R2-conc-data-shape/shape.py`, read-only, same conc.db (vault `Rix/Data/data/conc.db`, 1,226,866,688 bytes). Could have failed: a `none`, `aligned` or `xref` basis present, English lemmas with transliterations, or a `token.translit` column.
```
sqlite 3.50.4 | user_version: 0
token columns: ['token_id', 'corpus_id', 'unit_id', 'pos', 'surface', 'after', 'search', 'language', 'lemma_id', 'lemma_basis', 'pos_tag', 'morph', 'stem', 'form', 'person', 'gender', 'number', 'gstate', 'tense', 'voice', 'mood', 'gcase', 'degree', 'src_id', 'sense', 'before']
lemma_basis values:
  'computed:spacy-lemma'      3114729
  'tagged:CATSS'               623693
  'tagged:MACULA-Hebrew'       475911
  'tagged:MACULA-Greek'        137779
  'tagged:Grauman-WH'          137688
tokens with lemma_id NULL or 0: 0
tokens with empty or NULL surface: 6435
lemmas by language, empty translit / all:
  eng       19838 /    19838
  grc           0 /    15725
  hbo           0 /     8656
  arc           0 /      715
```
Reading: RED-1.1 and RED-1.2's counts reproduce exactly (P1-raw, second reading). `lemma_basis` is `<kind>:<source>`, never a bare word; no `token.translit` column yet (FR-162 unbuilt); `user_version` 0 (FR-165 unbuilt).

## E5. Not runnable yet (no weight until run)

The lookups' bodies and the value creators are Phase 4 stubs; a conc.db fixture arrives with Phase 5. Fact closure (R-C4) and field pinning (R-C8) can only be judged from the contract text.
