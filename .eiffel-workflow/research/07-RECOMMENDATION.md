# RECOMMENDATION: simple_bible

## Executive Summary
Build `simple_bible` as a clean Eiffel project: a deterministic engine over a freshly built, fully provenanced SQLite distribution database, presented through a WebView2 face and a CLI, with AI optional and confined to phrasing engine results. No free or commercial tool surveyed combines pre-registered counting with controls, versification-safe pairing, per-row provenance and an AI that is never a source of facts; the open datasets needed (OSHB, SBLGNT, MACULA, STEPBible-Data, OpenBible cross-references, UBS parallel passages, Swete) exist under licenses compatible with a free tool. Release 1 should be core-only.

## Recommendation
**Action:** BUILD (clean project per D-001; adopt open datasets; harvest simple_scholar per `08-HARVEST-LEDGER.md`)
**Confidence:** HIGH for the core engine and data build; MEDIUM for the optional AI layer (model survey pending, small-model quality in Hebrew/Greek unproven).

## Rationale
- **The gap is real.** Free apps (e-Sword, theWord, Bible Analyzer, Xiphos, STEP) read and search well but do not measure; corpus tools (Text-Fabric/BHSA, SHEBANQ, Bible Online Learner, Parabible) measure but are not one-click Windows installs and carry NC or restrictive data; Logos puts AI in the answer path.
- **The data exists and is mostly open.** SBLGNT is now CC BY 4.0; OSHB morphology CC BY 4.0; STEPBible-Data (including TVTMS versification) CC BY 4.0; MACULA Greek CC BY 4.0; OpenBible cross-references CC BY; UBS parallel passages (with OT quotes in the NT) CC BY-SA 4.0; Swete is public domain (digitization CC BY-SA 4.0).
- **The engine is cheap to run.** The core tier needs no AI and runs on 2 to 4 cores and 8 GB (design doc §5).
- **The ecosystem covers most needs.** simple_sql (FTS5, JSON1, vector store), simple_browser + simple_web + simple_htmx (WebView2 face), simple_onnx (embeddings), simple_rixqwen pattern (llama-server), simple_winhttp (shippable networking), simple_cli, simple_testing.
- **Two ecosystem corrections matter:** the compiled SQLite is 3.31.1, not 3.51.1 (D-007); simple_shaping now exists in pre-release, so the native Hebrew path is "pending release", not "impossible".

## Proposed Approach

### Phase 0: Spike (one day)
- Build simple_scholar's `bible_htmx` (or a minimal simple_bible equivalent) against current libraries with a tiny test database; confirm pointed Hebrew and polytonic Greek render in WebView2 and a verse lookup works end to end.
- Record the result in `08-HARVEST-LEDGER.md`.

### Phase 1 (MVP, Release 1: core-only)
- Distribution build pipeline: pinned manifest, imports (OSHB/WLC, MapM, SBLGNT + MorphGNT, MACULA Greek, Westcott-Hort, KJV, ASV, YLT, BSB, Tyndale, Clementine Vulgate, OpenBible cross-references, STEPBible TVTMS/TBESH/TBESG/TIPNR, Swete LXX), `source_provenance`, license gate, normalized search columns, versification map, quarantine and caveats, generated credits.
- Engine: reference parser, verse hub, versification map, concordance, census engine (pre-registered, controls, four buckets, method view), shape engine (shapes that need only shipped data), checks.
- Front ends: WebView2 face; `bible.exe` CLI.
- Installer: Inno Setup core edition with WebView2 detection.

### Phase 2 (Full)
- Precomputed L2 data: related passages, gloss/pronunciation completion, quotation alignments; quotation comparer UI.
- Semantic search: shipped verse/pericope vectors; CPU query embedding via simple_onnx.
- Optional "explain" button (small local model via llama-server), labeled, post-checked.
- Core + AI installer edition.
- Private plug-in for Larry (rix/scholars/transcripts/primary_evidence, framework lenses).

### Phase 3 (Later)
- Hebrew syntax/semantic layer (MACULA Hebrew, BHSA or SDBH, after license review).
- Native simple_widgets face once simple_shaping is released.
- Slim-database PWA; bring-your-own-key online model.

## Key Features
1. **Verse hub:** one verse in every shipped version with morphology, gloss, pronunciation, cross-references and caveats.
2. **Versification-safe pairing:** mapping as data and as a precondition.
3. **Concordance:** lemma, Strong's, morphology; Hebrew final-form-safe, Greek diacritic-safe; key joins only.
4. **Census engine:** pre-registered questions, controls, FITS / PARTIAL / FAILS / NO_DATA together, method stored.
5. **Shape engine:** named structural patterns with tiers and near-misses.
6. **Quotation comparer:** NT vs LXX vs MT with computed agreement class.
7. **Provenance and credits:** per-row provenance, generated credits, license gate.
8. **Optional AI:** semantic search and plain-English phrasing, never a source of facts.

## Success Criteria
- Clean install and first launch on a 4-core, 8 GB, no-GPU Windows 10 machine; no outbound network by default.
- Verse hub under 200 ms; whole-canon concordance under 2 s; census with controls under 10 s.
- 100% of defect-register regression tests pass (A1, B1 to B4, C, D, E1 to E11 as applicable to shipped data).
- 0 rows without provenance; 0 shipped sources with UNKNOWN license; credits file byte-equal to its generated form.
- All engine features pass with no AI models present.

## Dependencies
| Library | Purpose | simple_* Preferred |
|---------|---------|-------------------|
| simple_sql + eiffel_sqlite_2025 | All data access, FTS5, JSON1, vector store | YES |
| simple_browser | WebView2 host | YES |
| simple_web | Loopback HTTP server for the face | YES |
| simple_htmx / simple_alpine / simple_template | Page building | YES |
| simple_json | Config, data exchange | YES |
| simple_cli / simple_console | CLI/REPL | YES |
| simple_zstring / simple_encoding / simple_regex | Unicode text, normalization, reference parsing | YES |
| simple_file / simple_config / simple_env / simple_logger | Infrastructure | YES |
| simple_hash | Manifest and file integrity | YES |
| simple_csv / simple_xml | Build-time imports (TSV, OSIS, TEI) | YES |
| simple_testing | Tests | YES |
| simple_onnx | Query embeddings (Phase 2) | YES |
| simple_process | Hidden llama-server spawn (Phase 2) | YES |
| simple_winhttp | Any shipped network call (BYOK, update check) | YES |
| simple_ai_client | Build-time precompute; BYOK provider | YES |
| ONNX Runtime (bundled in simple_onnx) | Embedding inference | NO (external, MIT) |
| llama.cpp `llama-server.exe` | Optional chat | NO (external, MIT) |
| WebView2 Runtime + WebView2Loader.dll | UI runtime | NO (Microsoft) |
| Inno Setup | Installer | NO (free) |

## Next Steps
1. Run `/eiffel.spec D:\prod\simple_bible` to transform this research into a specification.
2. Then `/eiffel.intent D:\prod\simple_bible` to capture refined intent.
3. Continue with the Eiffel Spec Kit workflow (contracts, review, tasks, implement, verify, harden, ship), one Spec Kit pass per build phase.
4. In parallel (fleet task): upgrade `eiffel_sqlite_2025` to the current SQLite and correct its README (D-007).
5. Before Phase 1 imports: finish `08-HARVEST-LEDGER.md` and the one-day spike.

## Open Questions (for Larry)
1. **Septuagint:** secure written CATSS terms for Rahlfs, or ship Swete (public domain text, CC BY-SA digitization) by default with Rahlfs as an optional download? (Recommended: Swete default; seek Rahlfs permission.) (D-011)
2. **rix.db:** does any of it ship (for example, a curated pack of published essays), or none? (Recommended: none in Release 1.) (D-019)
3. **First release core-only?** (Recommended: yes.) (D-016)
4. **Go-ahead for the one-day spike** (design doc decision 5).
5. **SQLite upgrade:** approve the fleet-wide upgrade of `eiffel_sqlite_2025` from the compiled 3.31.1 to current, with a full fleet regression? (D-007)
6. **Hebrew syntax layer:** with NC permitted in a free tool, is BHSA (CC BY-NC 4.0) acceptable for a later release, or prefer MACULA Hebrew / UBS SDBH? (D-012)
7. **Model slots:** confirm the embedding and chat selections once `Rix/Data/_Small Model Survey (2026-10-06).md` is written (pending at the time of this research). (D-013)
8. **MorphGNT license wording:** the vault's credits list CC BY 4.0, MorphGNT's README says CC-BY-SA; adopt the README's wording in provenance?
9. **Byzantine text:** identify the edition (RP2018 from byztxt is public domain) or leave Byz out of Release 1?
10. **Fonts:** which Hebrew/Greek fonts to bundle (license check in spec phase)?
11. **Name and branding:** is "simple_bible" the public product name, or an internal name with a reader-facing title?
