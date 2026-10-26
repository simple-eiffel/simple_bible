# Phase 2 Review Register: the concordance slice (2026-10-26)

*`/eiffel.review --scope` (one scope per cycle), code-lite. Position paper: `../approach.md`. Status: **REGISTER WRITTEN, EXECUTION RECORD DONE, BUDGET PLAN AWAITING LARRY'S GO.***

## Scope

`simple_bible.ecf`, target `simple_bible`: `src/concordance/` (BIB_CONC_PACK, BIB_WORD_LOOKUP, BIB_ENGLISH_INDEX, BIB_VERSE_WORDS, BIB_WORD_ENTRY, BIB_PLACE_ROW, BIB_ENGLISH_ROW, BIB_VERSE_WORD, BIB_WORD_VIEW) plus BIB_SOURCE_SET, BIB_DATA_SOURCE, BIB_CONTENT_SOURCE, BIB_PRIVATE_SOURCE, BIB_CONFIG and SIMPLE_BIBLE: **15 classes**.

## Criteria (fixed before any finding)

| # | Criterion | Source |
|---|---|---|
| K1 | Three lookups and the word view's order | FR-150, FR-151, FR-152, research/14 section 3 |
| K2 | Headword keys only; Strong's only through `lemma_xref` | FR-153, conflict 1 |
| K3 | Candidates, transliteration on every original word, layout rules | FR-154, FR-155, FR-156 |
| K4 | Edition marking and swap by `conc_path` alone; no edition test in engine code | FR-157, FR-158, V-54, V-55 |
| K5 | Paged lists; first screen budget | FR-159, NFR-002, NFR-019 |
| K6 | conc.db a read-only pack; two pack kinds; slots | FR-160, FR-164, FR-166, DR-020 |
| K7 | Joins by keys, never display strings | FR-024, V-56 |
| K8 | Every fact carries provenance; fact closure is not vacuous | NFR-007, RQ-02, `BIB_SOURCED` |
| K9 | Determinism | NFR-006 |
| K10 | OOSC2, CQS, void safety, SCOOP (one connection per processor, DR-019), contracts on every public feature (NFR-015), layering (no SQL outside the engine) | fleet rules, spec 04 |

## Claims under test

| # | Claim (what the contracts and approach.md assert) |
|---|---|
| R-C1 | No lookup can run without the pack: every lookup feature requires `pack.is_available`. |
| R-C2 | The headword key is `lemma_id` (INTEGER_64); no lookup takes a Strong's number except `headwords_for_strongs`, which reads `lemma_xref`. |
| R-C3 | `place_page (a_lemma_id, a_corpus_code, a_offset, a_limit)` with `a_limit <= Max_page_size` meets K5 for every word at every depth. |
| R-C4 | Every value carries provenance set at creation, and `BIB_WORD_VIEW.fact_closure` checks real facts. |
| R-C5 | The edition swap needs no code: nothing in the slice names conc.db, conc_dist.db or an edition, except `edition_label` read from the pack. |
| R-C6 | `SIMPLE_BIBLE.open`'s contract states what is attached (content.db, the generic packs, the concordance pack) and fails visibly when a pack cannot attach. |
| R-C7 | Pack slots are bounded: generic packs plus the concordance pack never exceed `Max_attached`. |
| R-C8 | The value classes' contracts pin their fields (a swapped argument is caught). |

## S6 declaration

The contracts' author (this orchestrator, from the compiled 05b skeletons) leans toward the contracts as written. The execution record already contradicts R-C3 (spike R1). Scan 23's open items (concordance pack not checked at open; attach #11 versus FR-138; value postconditions that cannot catch swaps) bear on R-C6, R-C7 and R-C8.

## Budget plan (Budget rules 1-7)

| Step | Seat | Agent type / model | Cap |
|---|---|---|---|
| 3 | Execution record | main thread (done: `01 - Execution Record.md`) | — |
| 4 | RED (lenses RED-1 deflationary, RED-2 acceleration, RED-3 provenance, plus correctness and contract quality) | debate-seat / Sonnet 5.5 | 8 KB |
| 5 | BLUE defense | debate-seat / Sonnet | 6 KB |
| 6 | Adjudicator | debate-adjudicator / Opus 5.5 | 10 KB |

**Three agents. Estimate: 180,000-240,000 tokens** (debate 05b's five agents: 351,835; a review has no gather seat and a smaller scope), about 40% Opus. Session model: Opus 5.5. Tokens recorded per seat in `evidence/phase2-chain.txt`.
