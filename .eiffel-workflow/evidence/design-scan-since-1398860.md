# Design scan since 1398860 (to 0538abb), simple_bible, 2026-10-26
Read-only; nothing compiled. Stub bodies not reported. Paths are relative to the simple_bible project folder.

## HIGH
**H1. SOURCE_SCAN.Clusters not updated; purity and layering tests skip the new code.**
testing/source_scan.e:115-119 lists "src/plugin" (deleted), omits "src/pack" and "src/concordance".
- Scenario: "scholars.db" or an SW_ type added in src/pack/ passes every static test (test_pack_purity.e:43-53, test_layering.e:84). A BIB_PRIVATE_SOURCE descendant in src/pack/ passes test_private_source_is_one_generic_class (line 32-41).
- No purity test asserts `source_files.count > 0` (test_layering.e:34 does, once): a wrong `root` passes vacuously.
- test_no_plugin_classes (line 28) tests file PATHS only, not contents.
Fix: swap the cluster names, add the count assertion, scan code_of for BIB_PLUGIN/BIB_LENS.

**H2. BIB_WORD_VIEW.facts_model is always empty, so `fact_closure` is vacuous.**
bib_word_view.e:353-356 (`create Result`, real code). BIB_WORD_LOOKUP.view `fact_closure` (bib_word_lookup.e:166) always holds: a view whose entry provenance is not cited still "closes". Add to make_success: `facts_model.has (a_entry)` plus every first-page row.

## MEDIUM
**M1. No contract promises or checks the concordance pack at open.** simple_bible.e:65-71: `packs_attached` is `attached_count >= pack_count` (true when nothing attaches) and ignores conc_path. BIB_CONC_PACK has no open/check feature (bib_conc_pack.e:27-35), though spec S6 says it checks user_version and required tables itself. Scenario: conc.db with wrong user_version attaches; `is_available` True. Add `conc_path set and is_open implies conc_pack.is_available or last_error /= Void` plus a schema-valid query.

**M2. Slot arithmetic.** simple_bible.e:114 `pack_count <= Max_attached`; conc takes a slot, so 10 generic packs plus conc is attach #11. Bound is Max_attached - 1 when conc_path is set.

**M3. Alias collision.** BIB_PRIVATE_SOURCE.make (src/pack/bib_private_source.e:136, invariant 197) forbids only "main". A folder pack named "conc" makes BIB_CONC_PACK.is_available True over a generic pack. "temp" and uppercase pass make but fail attach's `alias_valid` (bib_source_set.e:261, 308). Require a valid alias and not "conc".

**M4. Attach #11 cannot report SQLite's message.** bib_source_set.e:310 `under_limit` turns #11 into a precondition violation; FR-138/DR-020 require a reported error. Spec 05:152 has the same contradiction. Drop the precondition or the criterion.

**M5. BIB_AUTHOR_LIBRARY is still a file-based "rix" source.** bib_author_library.e:23 (`make (a_path)`), :37 (alias "rix"), :107. The fold puts it inside content.db; inherited `open_on` still demands `file_present` and its own user_version. Make it a view over the content source.

**M6. Export (bib_db_note_store.e:100-118).** No name-uniqueness clause: "A:B" and "A?B" both sanitize to "A_B.md", replace-existing overwrites, `accounted_for` still holds. `atomic`, `front_matter_keys`, `every_failure_reported` (111, 114, 115) are answered by the writer itself (counters and flags): cannot fail. `notes_unchanged` compares a version count only; spec says every row and version.

**M7. Import (lines 120-133, 170).** `never_overwrites: versions_rewritten = 0` is an attribute never assigned: vacuous (spec 05:1050 states per-row body equality). `imported_count = new_notes + new_versions` while line 171 defines imported_count as "read": re-importing an unchanged export reads N, adds 0, violates it. No `is_writable` precondition though import writes.

**M8. is_file_safe_name (lines 193-239).** Correct: the nine reserved characters, codes < 32, trailing dot or space (this also rejects ".", "..", "..."), CON/PRN/AUX/NUL/COM1-9/LPT1-9 in any case with any extension, empty. Gaps:
1. COM0 and LPT0 absent (reserved in the current Microsoft list).
2. Superscript COM¹ COM² COM³, LPT¹ LPT² LPT³ absent.
3. Stem not right-trimmed: "NUL .md", "CON .txt" pass (line 221 leaves "NUL ").
4. No 255 limit (the spec never mentions one): a long sanitized title fails at the file system. Cap at 255 UTF-16 units or fall back to the id name.
5. CONIN$ and CONOUT$ not covered.
6. Postcondition (line 226) constrains only the empty name. Test (test_user_store.e:57-68) tries 2 of 9 reserved characters and no AUX, NUL, LPT1, COM9, COM0, "CON .md", long name.
Placement: BIB_MARKDOWN_NOTE_STORE (bib_markdown_note_store.e:150 writes `<title>.md`; spec 04:245 moves the colon trap there) is a real second user. Move the rule to a helper BIB_FILE_NAME_RULE.

## LOW
- L1. Postconditions cannot detect swapped arguments: WORD_ENTRY.make never ensures translit or pron (bib_word_entry.e:22-39; a_pron unused in contract), PLACE_ROW (bib_place_row.e:90) omits surface/translit, ENGLISH_ROW (bib_english_row.e:160) omits headword/translit, VERSE_WORD omits surface/translit. Invariants lack surface_not_empty and ENGLISH_ROW's lemma/book/english checks.
- L2. BIB_VERSE_WORD accepts negative lemma_id with basis "tagged" (bib_verse_word.e:211, 242); has_door False. Add `a_lemma_id >= 0`.
- L3. BIB_ENGLISH_INDEX `every_row_for_word` (bib_english_index.e:207) is case-sensitive: a folded lookup ("Love" finds "love") violates it. Result unbounded, unlike place_page's 200 cap.
- L6. BIB_CONFIG: make_from_separate ensure checks only core_path (bib_config.e:72), not conc_path or pack_folder; setter frames uneven; `set_core_path` vs spec 06:27 `set_content_path` (spec self-contradicts; code follows 05).
- L7. simple_bible.ecf line 3 still says "private plug-in seam". BIB_DATA_SOURCE `provenance_declared` (bib_data_source.e:78-89) must exempt contentless FTS and shadow tables on content.db.

## Duplication (proposals only)
- D1 (3 implementors): WORD_LOOKUP, ENGLISH_INDEX, VERSE_WORDS repeat `make (a_pack)`, `pack`, `pack_set`, `pack.is_available` precondition: deferred BIB_CONC_CLIENT, inherited side by side.
- D2 (4 implementors): WORD_ENTRY, ENGLISH_ROW, VERSE_WORD, PLACE_ROW share `translit` plus its invariant and (three) `lemma_id`: deferred BIB_ORIGINAL_WORD mixin beside BIB_SOURCED.
- D3: file-name rule, M8. BIB_CONC_PACK need not inherit BIB_PRIVATE_SOURCE (G2).

