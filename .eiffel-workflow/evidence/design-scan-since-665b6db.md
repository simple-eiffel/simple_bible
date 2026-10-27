# Design Scan (diff mode): simple_bible since 665b6db
# Date: 2026-10-27
# Subjects (14 files): src/user/{bib_hub_id,bib_user_store,bib_db_note_store}.e, src/pack/{bib_private_source,bib_commentary_schema,bib_commentary_pack,bib_commentary_section,bib_commentary_claim}.e, src/simple_bible.e, build/bib_commentary_builder.e, build_app/bib_build_app.e, cli/{bib_commentary_text,bib_data_location}.e, gui_app/bib_gui_app.e
# Compared against: src/, cli/, gui_app/, build/, build_app/
# Read-only scan. Nothing compiled. Findings are proposals; nothing is extracted without Larry's word.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / drift (A, D1) | 15 | 4 | 6 | 5 |
| MI (M4 and mixin proposals) | 1 | 0 | 1 | 0 |
| Contracts / invariants / defects | 3 | 0 | 2 | 1 |
| GUI pills and cleanup | 3 | 0 | 0 | 3 |
| **Total** | **22** | **4** | **9** | **9** |

Checked and found clean (no finding):
- Schema versus pack rules: every non-meta, non-source_provenance table that BIB_COMMENTARY_SCHEMA creates carries NOT NULL voice and NOT NULL provenance_key: commentary_book (schema:205), commentary_section (206), commentary_field (208), commentary_claim (209), commentary_term (210), commentary_list (211), commentary_restricted_quote (212). BIB_PRIVATE_SOURCE.open_on (private_source.e:311-337, 342-345) checks exactly those two columns on exactly those tables. No drift.
- BIB_DATA_SOURCE invariant error_only_when_closed (bib_data_source.e:119): BIB_PRIVATE_SOURCE.open_on sets last_error only on paths where is_open stays False (private_source.e:306-307, 338-345, 354-359); BIB_USER_STORE.open sets it only before is_open becomes True (bib_user_store.e:319-340); set_setting deliberately uses write_error. No breach today; see finding 18 for an export that could cause one.
- Front-matter parsing: front_matter (bib_db_note_store.e:407-436) and body_after_front_matter (438-455) agree on terminated, unterminated, empty and absent front matter (line breaks are normalized before both, lines 258-259 and 359). No divergence; see finding 19.
- Hub-id arithmetic: no other class computes book*1000000+chapter*1000+verse (grep of src, cli, build, gui_app).

## Findings

| # | Priority | Cat | Classes | Opportunity |
|---|----------|-----|---------|-------------|
| 1 | HIGH | D1 | BIB_DB_NOTE_STORE (export vs import) | A topical note's title survives export but is dropped on import |
| 2 | HIGH | D1/A5 | BIB_USER_STORE, BIB_DB_NOTE_STORE, BIB_COMMENTARY_BUILDER, BIB_CONTENT_BUILDER, BIB_SQLITE_REPORTING | Five SQLite error-to-message copies disagree with sqlite_message on an empty message |
| 3 | HIGH | D1 | BIB_COMMENTARY_PACK, BIB_COMMENTARY_BUILDER, BIB_COMMENTARY_SCHEMA | A claim the schema and builder accept (empty id) is silently dropped by the reader |
| 4 | HIGH | A5 | BIB_USER_STORE, BIB_PRIVATE_SOURCE | count_of and first_integer are the same body; first_text is its twin |
| 5 | MEDIUM | A5 | BIB_DB_NOTE_STORE, SIMPLE_BIBLE, BIB_COMMENTARY_BUILDER, BIB_GUI_APP | Four path joiners, two spellings of the rule |
| 6 | MEDIUM | A5/contract | BIB_HUB_ID, BIB_COMMENTARY_BUILDER, BIB_COMMENTARY_PACK, BIB_COMMENTARY_SECTION | "Part is 1 to 999" written five times; section make has no upper bound, so a crafted pack breaks hub_id's precondition |
| 7 | MEDIUM | defect | BIB_USER_STORE | create_schema is not one transaction; a half-made user.db can never open again |
| 8 | MEDIUM | defect | BIB_COMMENTARY_PACK | fill_section ignores every query failure |
| 9 | MEDIUM | D1 | BIB_COMMENTARY_SCHEMA, BIB_PRIVATE_SOURCE, BIB_COMMENTARY_BUILDER | Pack rules in prose and in code disagree (meta status); schema version "1" written three times; kind never checked |
| 10 | MEDIUM | contract | BIB_NOTE, BIB_NOTE_STORE, BIB_DB_NOTE_STORE import | Hub validity checked in the importer and the gutter, not in the note; a non-numeric hub_id becomes a topical note |
| 11 | MEDIUM | M4 | BIB_DB_NOTE_STORE | 624 lines; a front-matter parser and a file-name rule live inside the store |
| 12 | MEDIUM | D1 | BIB_COMMENTARY_TEXT | Claim tags are labelled in fields but not in lists, terms or quotations |
| 13 | MEDIUM | D1 | BIB_COMMENTARY_TEXT, SIMPLE_BIBLE, BIB_COMMENTARY_BUILDER | Voice fixed to "author" in three places while rows and meta carry their own |
| 14 | LOW | A5 | schema, builder, text, pack | Field and list kind names written as literals in several classes |
| 15 | LOW | D1 | BIB_COMMENTARY_PACK, BIB_COMMENTARY_BUILDER | Pack-level license text differs between the two copies |
| 16 | LOW | contract | BIB_PRIVATE_SOURCE | open_on never checks has_error on its own queries |
| 17 | LOW | contract | BIB_COMMENTARY_SECTION | end_book stored but dropped; invariant states less than make requires |
| 18 | LOW | invariant | BIB_USER_STORE | note_failure sets last_error and is exported though nobody outside calls it |
| 19 | LOW | A5 | BIB_DB_NOTE_STORE | Two front-matter scanners for one delimiter rule |
| 20 | LOW | pill | bib_gui_app.e T2 | Tip says "Delete and Restore"; Restore only reaches the last note deleted this run |
| 21 | LOW | pill | bib_gui_app.e | New note controls have no design pill; commentary_title text stale on the Commentaries tab |
| 22 | LOW | cleanup | bib_gui_app.e | take_snapshot ends with dead assignments |

## Detailed Findings

### Finding 1: Topical note title lost on import (D1, HIGH)
Export writes the title for every note that has one; import reads it only for verse notes.
- src/user/bib_db_note_store.e:385-387: note_file_text writes `title: "..."` whenever the row's title is not empty, topical notes included.
- src/user/bib_db_note_store.e:282-287: import builds a verse note with key_text (l_keys, "title") (line 283) but a topical note from the FILE STEM (l_stem := ic.twin, remove_tail (3), make_topical (l_stem, l_body)), ignoring any title key.
- Effect: export a topical note titled "Prayer of Jabez" as note-9.md, lose user.db, import: the note is titled "note-9". Only unknown ids reach this path (a known id updates the body at 266-277).
- Winning copy: the exported title key; fall back to the stem only when the key is empty.
Suggested action: one title_of (a_keys, a_stem) used by both branches. Effort: 1 feature.

### Finding 2: SQLite error text, five copies, two behaviors (D1/A5, HIGH)
BIB_SQLITE_REPORTING.sqlite_message (src/data/bib_sqlite_reporting.e:134-144) returns SQLite's words, or the fallback when the message is void OR EMPTY. The copies only test void and then join with a space:
- src/user/bib_user_store.e:222-226 (set_setting).
- src/user/bib_user_store.e:390-401 (note_failure).
- src/user/bib_db_note_store.e:554-562 (error_text).
- build/bib_commentary_builder.e:351-361 (check_db).
- build/bib_content_builder.e:195-200 (older copy of the same pattern).
Already shared: src/concordance/bib_conc_pack.e:200,909 and src/data/bib_source_set.e:137,164,189 use sqlite_message.
Divergence: an empty last_error_message yields "The note could not be saved. " (trailing space, no cause) in the copies, versus the fallback text in the shared one. FR-138 (never "Unknown error") is met in the shared one only.
Suggested action (MI): add one effective feature to BIB_SQLITE_REPORTING, failure_text (a_db, a_what): STRING_32 (what plus SQLite's own words, empty-safe), and inherit BIB_SQLITE_REPORTING side by side with BIB_DATA_SOURCE in BIB_USER_STORE, with BIB_NOTE_STORE in BIB_DB_NOTE_STORE, and into both builders. Effort: 1 feature, 5 call sites. Suggested skill: /eiffel.mi.

### Finding 3: Claims the reader drops but the writer accepts (D1, HIGH)
- build/bib_commentary_builder.e:252-254 inserts a claim with text_of (al_claim, "id"), the empty string when the sidecar has no id. Schema (src/pack/bib_commentary_schema.e:209) has claim_id TEXT NOT NULL with no non-empty CHECK, so SQLite accepts it, and claim_count counts it (builder:256).
- src/pack/bib_commentary_pack.e:151 skips any claim whose id is empty (BIB_COMMENTARY_CLAIM.make also requires one, claim.e:327). The claim vanishes from the window with no error.
- Same shape for sections, three copies of "is this a valid section" with different strictness: builder:210-211 (parts 1..999, end >= start by hub id), bib_commentary_pack.e:124-132 is_section_row (chapter and verse order only, no 999 bound), bib_commentary_section.e:233-238 make precondition (no 999 bound). A row is_section_row rejects is dropped silently.
Winning copy: the strictest (builder). Put CHECK (claim_id <> '') and range checks in the schema so the builder fails loudly; keep the reader guards but make them report (finding 8).

### Finding 4: First-column readers copied (A5, HIGH)
- src/user/bib_user_store.e:373-379 count_of and src/pack/bib_private_source.e:396-402 first_integer have identical bodies (first column of first row as integer, 0 when none).
- src/user/bib_user_store.e:381-388 first_text is the text twin.
- src/pack/bib_private_source.e:404-414 meta_value is a third "first value" reader.
- BIB_DB_NOTE_STORE reaches through the user store for them at lines 45, 52, 58, 66, 119, 326, 498 (exported to {BIB_NOTE_STORE} at bib_user_store.e:371).
Suggested action (MI): put first_integer (a_result) and first_text (a_result) in BIB_SQLITE_REPORTING (stateless, already inherited side by side elsewhere), and delete the three bodies. BIB_SQLITE_QUERYING (src/data/bib_sqlite_querying.e) does not offer them (only run_query, query_error, method, sqlite_version_or_unknown) and is the wrong home: it needs an heir `sources` connection that BIB_USER_STORE and BIB_PRIVATE_SOURCE lack. Effort: 2 features moved, 3 deleted.

### Finding 5: Path joiners (A5, MEDIUM)
- src/user/bib_db_note_store.e:501-509 joined_path: appends a backslash unless the folder already ends in backslash or slash.
- src/simple_bible.e:243-251 pack_path: the same logic on config.pack_folder.
- build/bib_commentary_builder.e:67 and :71: always appends a backslash, so a folder given with a trailing slash yields a doubled separator (harmless on Windows, but a third spelling).
- gui_app/bib_gui_app.e:96-97: al_temp + "\simple_bible_snapshot_user.db", a fourth, same trailing-slash assumption.
Suggested action: one joined_path in a deferred mixin BIB_PATH_JOINING (or in BIB_DATA_LOCATION, cli/, which already owns paths) inherited by the four. Check the eiffel-paths skill first. Effort: 1 feature, 4 callers.

### Finding 6: "Part is 1 to 999" five times; section lacks the bound (A5 + missing contract, MEDIUM)
- src/user/bib_hub_id.e:42-44 (hub_id precondition, three inline copies) and :76-81 is_valid_hub.
- build/bib_commentary_builder.e:345-349 is_part.
- src/pack/bib_commentary_pack.e:55-57 (sections_for_verse precondition, three more inline copies).
- Missing: BIB_COMMENTARY_SECTION.make (section.e:233-238) and BIB_COMMENTARY_PACK.is_section_row (pack.e:124-132) never bound chapter or verse by Max_part.
- Consequence: a pack row with end_verse = 1000 (pack rules at attach do not look at rows) passes is_section_row, then span (pack.e:106-113) calls hub_id with a verse above Max_part, breaking its precondition. In a test build (contracts baked in) that is a crash from data, not a refusal.
Suggested action: add is_part (a_number) to BIB_HUB_ID; use it in its own preconditions, the builder, the pack and the section's make and invariant. Effort: 1 feature, 4 users.

### Finding 7: user.db schema creation is not atomic (defect, MEDIUM)
- src/user/bib_user_store.e:407-415: create_schema runs each statement alone (until last_error /= Void); PRAGMA user_version = 1 is the LAST statement of Schema_statements.
- :313-318: open creates the schema only when user_version is 0.
- If a statement fails or the program dies midway, tables exist but user_version stays 0; the next open runs CREATE TABLE note again and fails with "already exists", so user.db can never open again (the panel then says "Notes are unavailable", gui_app.e:268-273).
Suggested action: wrap create_schema in begin_transaction and commit (SQLite DDL is transactional), as BIB_COMMENTARY_BUILDER already does for rows (builder:111-132).

### Finding 8: fill_section swallows query failures (defect, MEDIUM)
- src/pack/bib_commentary_pack.e:141-173: five run_query calls, each followed by "if attached last_rows"; last_query_error is never read. A failed field, claim, term, list or quotation query yields a section that looks complete but misses that part, with no message. sections_for_verse reports only the first (sections) query error (line 99).
- BIB_SQLITE_QUERYING.run_query (querying.e:63-82) already provides the error; fill_section only needs to propagate it. FR-138: SQLite's own words, never silence.
Suggested action: have fill_section record the first error and let sections_for_verse make a failure result.

### Finding 9: Pack rules in three places disagree (D1, MEDIUM)
- Prose: bib_commentary_schema.e:156-158 says the meta table holds pack_kind, title, status. The builder writes pack_kind, title, voice_status, author, builder (builder:112-116) and no status (status lives on commentary_book and source_provenance.edition). Doc or builder is wrong.
- Code: BIB_PRIVATE_SOURCE checks only that a meta table exists (private_source.e:315). A pack with an empty or wrong pack_kind still opens: meta_value returns empty (lines 347, 404-414) and commentary_packs (simple_bible.e:187-195) just never lists it. pack_voice_column_present is also True for a pack with no tables other than the two meta ones (line 316 sets True before the loop).
- Version "1" in three places: BIB_COMMENTARY_SCHEMA.Schema_version (schema.e:184), the literal "PRAGMA user_version = 1" (schema.e:213), BIB_PRIVATE_SOURCE.Pack_schema_version (private_source.e:387). The schema's own comment says they must match; nothing makes them.
Suggested action: build the PRAGMA string from Schema_version; tie it to Pack_schema_version with an assertion; decide whether meta.status exists and align doc and builder; check pack_kind is non-empty at attach.

### Finding 10: Hub validity not owned by the note (contract, MEDIUM)
- src/user/bib_note.e:23-24 make requires only a_hub_id > 0; src/user/bib_note_store.e:62 add_note requires hub_id > 0 or is_topical. Neither uses BIB_HUB_ID.is_valid_hub.
- The rule is enforced ad hoc: importer bib_db_note_store.e:264, GUI gutter gui_app.e:1476. add_note with hub 5 stores a note no chapter query (notes_between, fill_notes) can show.
- Import edge: key_number returns 0 for a non-number, and the guard at line 264 is "l_hub /= 0 and not valid", so "hub_id: abc" is not skipped; it silently becomes a topical note (lines 284-287).
Suggested action: valid_hub: is_valid_hub (a_hub_id) in BIB_NOTE.make; the importer skips a present-but-unparsable hub_id.

### Finding 11: BIB_DB_NOTE_STORE is three classes (M4/M2, MEDIUM)
624 lines. Beside note persistence it holds a front-matter reader and writer (front_matter, body_after_front_matter, unquoted, quoted, key_number, key_text, note_file_text; lines 380-495) and the Windows file-name rule (is_file_safe_name, Reserved_characters, Reserved_names; lines 570-624). Both are pure and reusable (a later pack exporter would want the file-name rule).
Suggested action (MI, Larry's preferred shape): mixins BIB_FRONT_MATTER and BIB_FILE_NAMING inherited side by side by BIB_DB_NOTE_STORE (and BIB_PATH_JOINING from finding 5). The class header itself calls the final home of export and import "a Phase 4 design item (G3)".

### Finding 12: Claim labels skipped outside fields (D1, MEDIUM)
The banner promise (cli/bib_commentary_text.e:8-12, "EVERY CLAIM WEARS ITS LABEL") is kept by labelled only for the five fields (append_field, lines 91-100). Lists (append_list, lines 102-117: ic.markdown appended raw at line 114), terms (46-50) and restricted quotations (57) bypass it. A tag such as [D11.9] in a framework or further-reading item reads as bare text, never as DEDUCED. The postcondition no_bare_tag (line 80) covers only the text passed in.
Suggested action: route list items and quotation bodies through labelled.

### Finding 13: Voice fixed to "author" three times (D1, MEDIUM)
- src/simple_bible.e:226: every pack is made with make_author, whatever its rows say.
- cli/bib_commentary_text.e:27: the banner prints "Larry Rix, author voice (provisional)" for every pack.
- build/bib_commentary_builder.e:215-218 honors a sidecar voice per section but writes meta voice_status PROVISIONAL always (line 114); the reader returns each row's own voice (pack.e:88).
A section whose sidecar names another voice is labelled author by the pack and the banner, and a later non-provisional status is never read. Winning copy: the row's voice and meta voice_status.

### Finding 14: Kind names as literals (A5, LOW)
"teaser", "text", "common_reading", "commentary", "variants" appear in schema.e:190 (Field_kinds) and again in bib_commentary_text.e:38-42; "framework", "question", "further_reading" in schema.e:196, text.e:53-55 and builder:237-239 (where JSON names are plural and kinds singular, a second mapping). Use Field_kinds and List_kinds plus one name map.

### Finding 15: License text drift (D1, LOW)
bib_commentary_pack.e:179 (pack_provenance) uses license id "private" with flags True/False/True; builder:159 writes "private (the author's own)" with 1, 0, 1; the restricted row is "research only" (builder:165). Same flags, different ids.

### Finding 16: Unchecked queries in open_on (contract, LOW)
private_source.e:309, 311, 321 run al_db.query without testing has_error; a failing PRAGMA reads as version 0 and the refusal names the wrong cause ("The pack's version is 0"). The table name is concatenated unquoted into PRAGMA table_info (line 321). BIB_SQLITE_REPORTING.sqlite_message fits here (finding 2).

### Finding 17: Section keeps one book (contract, LOW)
Schema stores start_book and end_book (schema.e:206); the builder writes the same value to both (builder:220); the reader selects only start_book (pack.e:120) and span uses book for both ends (pack.e:112). The class invariant (section.e:300-302) is weaker than make (237-238: an ordered range is not an invariant).

### Finding 18: note_failure exported (invariant, LOW)
bib_user_store.e:390-401 sits in feature {BIB_NOTE_STORE} and assigns last_error. Called while the store is open it would break error_only_when_closed (bib_data_source.e:119). Its only caller is create_schema (line 413). Make it {NONE}, or retire it for finding 2's shared feature.

### Finding 19: Two scanners for one rule (A5, LOW)
front_matter splits lines; body_after_front_matter searches for a line break, three dashes, a line break. They agree today (verified above); one parse returning keys and body would keep it that way.

### Finding 20: T2 pill (LOW)
gui_app.e, T2 tip in the add_reference_mark for notes_heading: "Delete and Restore". restore_note works only for last_deleted_note (gui_app.e:256, 364-367), which is lost on exit; an older deleted note cannot be restored in the window. Say "Restore brings back the note deleted last."

### Finding 21: No pills on the new controls (LOW)
add_note_button, delete_note_button, restore_note_button, new_note_box and notes_list have no add_reference_mark; only notes_heading (T2) does. Per the pill rule every window part gets a board-code pill. The T5 and S2 tips match the code (claims are labelled; Cross-refs live), but both anchor on commentary_title, whose text still reads "click a verse for its cross-references" even when Commentaries is the open tab.

### Finding 22: take_snapshot dead code (LOW)
gui_app.e, take_snapshot (diff lines 115-151): after a failed write_frame, l_written is set by the .txt write and then forced to False, so the program always exits 1 and the text-file write result is unused. Intent is fine; the assignment chain is noise.

## Recommended Order
1. Finding 1 (live round-trip defect) and Finding 3 (silent claim loss): small and user-visible.
2. Finding 7 (user.db can become unopenable) and Finding 8 (silent partial sections).
3. Findings 2 and 4 together: one change to BIB_SQLITE_REPORTING (failure_text, first_integer, first_text) removes about eight copies.
4. Finding 6 (BIB_HUB_ID.is_part) with Finding 10 (note hub contract), then Finding 5 (path joiner).
5. Findings 9, 12, 13 (rule and label drift), then 11 (mixins out of the note store).
6. Low items as convenient.
