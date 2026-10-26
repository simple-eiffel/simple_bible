# BLUE: defense of the concordance contracts (2026-10-26)

Lens: defend what is written, concede what the record shows. **P1-raw** = read this cycle. BLUE could not locate conc.db (searched the project folder, the Bible data folder and the vault roots; the filesystem walks timed out), so RED's data counts carry no BLUE weight either way (GR-12); where the spec independently agrees I say so.

## RED-1

| ID | Verdict | Reasoning and fix |
|---|---|---|
| 1.1 | NARROW | `bib_verse_word.e:29-30` matches the domain vocabulary in spec 02-DOMAIN-MODEL.md:294 and 05-CONTRACT-DESIGN.md:764 (tagged, aligned, xref, none) (P1-raw). RED's stored values (`computed:*`, `tagged:*`) are unverified by BLUE. If they hold, the vocabulary lacks `computed`. **Fix:** add `computed` to `basis_known`; the pack reader maps stored strings (prefix before the colon) to the vocabulary. RED's prefix-in-the-precondition would leak storage spelling into a value class. `none_means_no_lemma` stays (it is the invariant already, line 61). |
| 1.2 | CONCEDE | FR-152 says "every corpus"; the stub demands a non-empty `translit` for all of them (`bib_verse_word.e:27-28`). Spec FR-155/FR-162 confirm `token.translit` is unbuilt (P1-raw). **Fix:** RED's: translit and surface required only for original-language words (pass language or a `a_is_original` flag); allow empty for English. Same for `BIB_PLACE_ROW.make`. |
| 1.3 | CONCEDE | `bib_place_row.e:23-33` pins id and provenance only (P1-raw). **Fix:** RED's `surface_set`, `translit_set`, `headword_set`. `context_absent` is sound (`make` comment says optional columns come from `set_context`). |
| 1.5 | NARROW | Invariant already has `success_has_entry` and `success_has_total` (`bib_word_view.e:117-118`), but no places invariant: concede. **Fix:** `places_set`, `method_set`, `error_set`, `success_has_places`, and `empty_model` on failure. Contest only the vacuity charge: a failed view shows no facts, so closure over zero facts is the correct claim, and the `empty_model` postcondition makes that explicit. The `a_entry.lemma_id`-to-rows tie is dropped: place rows carry token ids, not lemma ids, so it cannot be stated. |
| 1.6 | CONCEDE | `is_known_section` and `is_in_approved_order` have no postcondition (`bib_word_view.e:70-91`); `order_kept` rests on an undefined query (K1). **Fix:** RED's `Approved_order` constant and subsequence definition, but use the contract's own names (`greek_ot`, `going_further`, line 71), not RED's `septuagint`/`further`, or the two diverge. |
| 1.7 | NARROW | Concede the `ascending` postcondition on `place_page` (cheap, K9). The normalization of `a_english` is a debate 01 (D-009) search-normalization matter, so the fix is a pointer in the header comment, not a new rule in this slice. K2 and K7 unmapped: concede; add static-check citations in the next register. |

## RED-2

| ID | Verdict | Reasoning and fix |
|---|---|---|
| 2.1 | NARROW | R-C3 as worded holds: K5 and NFR-002 pass (OFFSET at most 121.5 ms at row 88,200; 01 - Execution Record, spike output.txt, P1-raw). Accept `place_page_after` as additive. **Break risk in RED's fix:** a virtual grid needs random access by row index (thumb jump, scroll to row N); keyset needs the previous token id, which a jump does not have. `place_page` (offset) must stay for jumps, and the offset-only `page_size_right` formula must not be copied to the keyset query. `no_place_after` is undefined; define it or drop `full_unless_last`. |
| 2.3 | CONCEDE | `sources` is exported to three classes (`bib_conc_pack.e:122`); their bodies can only run SQL, against "one class owns every SQL statement" (line 3). **Fix:** RED's `english_rows` and `verse_words` on the pack; `sources` becomes `{NONE}`. |
| 2.4 | CONCEDE | `simple_bible.e:69` is satisfied by generic packs alone; `pack_count` (line 115) promises a bound a folder scan cannot guarantee; `attach` `under_limit` (`bib_source_set.e:111`) is a precondition, while FR-138 needs a reported error (P1-raw). **Fix:** RED's `conc_attached`, `Max_generic_packs`, and `overflow_reported`; drop the `within_slots` postcondition, replace it by the scan's own clamp: `Result <= Max_generic_packs`. |
| 2.5 | CONCEDE (INFO) | Holds structurally, untested; Phase 5 runs `test_edition_swap_needs_no_code`. |

## RED-3

| ID | Verdict | Reasoning and fix |
|---|---|---|
| 3.1 | CONCEDE | Nothing maps `has_error` to `last_error`. **Fix:** `attach` ensure: `database.has_error implies last_error /= Void`. |
| 3.2 | CONCEDE (INFO) | Limit 10, main uncounted: agreed. ECF override stays unchecked (UNTESTED). |
| 3.3 | CONCEDE | `simple_sql_schema.e:310-322` runs `PRAGMA user_version` unqualified (P1-raw), so it reads main. FR-165 independently says conc.db reports 0 today. `is_available` is alias-only (`bib_conc_pack.e:29-35`). **Fix:** RED's `Expected_user_version`, `is_pack_valid` using `PRAGMA conc.user_version` (via a pack-owned query, not the helper), and `is_available` = attached and valid. Note FR-164 forbids a pack that reports another version, so personal-edition use waits on FR-165 or a documented bypass. |

## Claims

| Claim | BLUE final position |
|---|---|
| R-C1 | Holds narrowly; strengthened by 3.3 |
| R-C2 | Holds (RED agrees) |
| R-C3 | Holds as worded; keyset added as an additive method, offset kept for jumps |
| R-C4 | Holds on success; failure case made explicit by `empty_model` |
| R-C5 | Holds structurally; UNTESTED |
| R-C6 | Conceded as written; restored by `conc_attached` |
| R-C7 | Limit true; reserve and reported overflow conceded, fixed by 2.4 |
| R-C8 | Conceded; restored by the pins in 1.3 |

Totals: 9 CONCEDE (1.2, 1.3, 1.6, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3; 2.5 and 3.2 are INFO), 4 NARROW (1.1, 1.5, 1.7, 2.1), 0 CONTEST.

**Do-not-assume:** RED's conc.db value counts (BLUE did not obtain the file); that `computed` needs no vocabulary entry; that keyset can replace offset for random-access grids.
