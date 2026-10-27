# Design Scan (diff mode): simple_bible since ff44a6b
# Date: 2026-10-27
# Mode: read-only; nothing compiled
# Subjects: gui_app/bib_gui_app.e, src/concordance/bib_conc_pack.e, src/concordance/bib_interlinear_word.e, src/concordance/bib_morphology_names.e
# Compared against: src/, cli/, gui_app/, build/, build_app/ (build/ and build_app/ hold nothing relevant to these findings)

## Summary

| Priority | Findings |
|----------|----------|
| HIGH | 2 |
| MEDIUM | 4 |
| LOW | 5 |
| **Total** | **11** |

## Findings

| # | Priority | Category | Classes | Opportunity |
|---|----------|----------|---------|-------------|
| 1 | HIGH | D1 | BIB_INTERLINEAR_WORD, BIB_LOOKUP, BIB_CONC_PACK | Three different "which morpheme opens the word" rules |
| 2 | HIGH | D1/A5 | BIB_CONC_PACK | interlinear_chapter copies verse_words and has drifted from it |
| 3 | MEDIUM | A5 | BIB_LOOKUP, BIB_CONC_PACK, BIB_INTERLINEAR_WORD | Group-tokens-by-position loop exists three times |
| 4 | MEDIUM | T1 | BIB_LOOKUP, BIB_GUI_APP | Corpus code "WLC-MACULA" spelled four times; right-to-left decided by string compare |
| 5 | MEDIUM | A5/T1 | BIB_GUI_APP | show_interlinear and show_parallel copy each other; tab indexes 1, 2 literal beside constant 3 |
| 6 | MEDIUM | D1 (suspected) | BIB_GUI_APP | Interlinear verse numbers come from the original-text pack but are used as the reading version's verse numbers |
| 7 | LOW | A4 | BIB_MORPHOLOGY_NAMES | Features without contracts; documentation names a second client that does not exist; exported publicly through the pack |
| 8 | LOW | A4 | BIB_INTERLINEAR_WORD, BIB_CONC_PACK | Thin contracts on add_morpheme, make, interlinear_chapter |
| 9 | LOW | pill | BIB_GUI_APP | P03 pill tip is incomplete (a click also moves the place read; words without a headword do not open T4) |
| 10 | LOW | A6/M4 | BIB_GUI_APP | fill_interlinear (68 lines) mixes fetch, cache and render; a failed chapter is cached as loaded |
| 11 | LOW | T1 | BIB_CONC_PACK | Glossing source named by two constants for one fact |

## Detailed Findings

### Finding 1: Three different rules for the morpheme that opens a word
**Priority:** HIGH (drift)
**Category:** D1
**Classes:** BIB_INTERLINEAR_WORD (src/concordance/bib_interlinear_word.e), BIB_LOOKUP (cli/bib_lookup.e), BIB_CONC_PACK (src/concordance/bib_conc_pack.e)
**Description:** A Hebrew word is several morphemes at one position (prefix plus word). Three places choose which morpheme's headword the word opens, and they do not agree:
- Interlinear click: the morpheme with the longest SURFACE (pointed, as written); the first one wins a tie. bib_interlinear_word.e:86-89 (`a_lemma_id > 0 and (lemma_id = 0 or a_surface.count > longest_surface)`). The class comment at bib_interlinear_word.e:9-10 says this is "as a clicked word finds it".
- Parallel click: the morpheme with the longest `token.search` form (folded: points and accents gone); the first one wins a tie. bib_conc_pack.e:330-333 (`headwords_behind_original_word`); documented at bib_conc_pack.e:299.
- Lookup window verse choices: the LAST morpheme that has a headword wins, with no length rule at all. cli/bib_lookup.e:267-269 (`if l_words.item (i).has_door then l_lemma := ...`).
The same word can therefore open different headwords from the Interlinear tab, the Parallel tab and the lookup window whenever the longest morpheme is not the last one carrying a lemma (a word whose suffix morpheme has its own headword is the likely case; not verified against pack data, which I did not query). Pointed length versus folded length can also change which morpheme is longest, so even the first two may differ.
**Winner (proposal):** the longest-token rule, since it is the documented rule in two of three places. Put it in one helper (for example a small BIB_WORD_DOOR holding `consider (a_length, a_lemma)` and `lemma_id`) that BIB_INTERLINEAR_WORD, headwords_behind_original_word and add_verse_words each own an instance of. Decide surface or search length once.
**Effort:** 3 call sites, 1 new helper class.

### Finding 2: interlinear_chapter copies verse_words and has drifted from it
**Priority:** HIGH (drift plus duplicated body)
**Category:** D1 / A5
**Classes:** BIB_CONC_PACK
**Description:** Same skeleton (query, per-row validity check, `l_bad` message, schema-mismatch failure, success wrap, query-error failure), different rules:
- Row validity. verse_words rejects a bad position, a position that goes backwards, a language that is not a concordance language, an incomplete transliteration, an unknown lemma basis, and a basis/lemma mismatch (bib_conc_pack.e:92-96). interlinear_chapter rejects only verse < 1, position < 1 and lemma < 0 (bib_conc_pack.e:147). It never checks the language, so BIB_INTERLINEAR_WORD.make (bib_interlinear_word.e:27) takes any string although the class says "hbo", "arc" or "grc" (bib_interlinear_word.e:55). It never checks that positions do not decrease within a verse (verse_words does, through `l_previous`); it relies on the SQL ORDER BY and on a postcondition that runs only in contract builds.
- Negative lemma. verse_words clamps it with `.max (0)` (bib_conc_pack.e:86); interlinear_chapter rejects the whole chapter (bib_conc_pack.e:147). One bad token blanks a whole chapter in the Interlinear but only makes a word door-less in verse_words.
- Scope text. `verse_scope` exists (bib_conc_pack.e:1107-1110, "book N, chapter M, verse V") but the chapter scope is built inline (bib_conc_pack.e:698, "book N chapter M", no comma): the same idea written a second way.
- Failure and success construction repeat: `method ("interlinear_chapter", Interlinear_sql, ...)` three times (bib_conc_pack.e:726, 733, 736) as `method ("verse_words", l_sql, ...)` three times (bib_conc_pack.e:662, 664, 667).
- Query shape. The joins token, unit, work_book with `recension = ''` appear in three SQL strings: inline in verse_words (bib_conc_pack.e:76), Verse_original_tokens_sql (bib_conc_pack.e:983) and Interlinear_sql (bib_conc_pack.e:1163). Only verse_words keeps its SQL inline.
**Suggested Action:** one shared row-sanity check used by both; a `chapter_scope` beside `verse_scope`; one policy for a negative lemma (verse_words should win: a bad lemma costs the door, not the chapter, unless the pack rules say otherwise); optionally one shared SQL fragment for the token-unit-work_book scope.
**Effort:** 1 helper query, 1 scope feature, 1 policy decision.

### Finding 3: Group-tokens-by-position loop exists three times
**Priority:** MEDIUM
**Category:** A5
**Classes:** BIB_LOOKUP (cli/bib_lookup.e:256-271), BIB_CONC_PACK headwords_behind_original_word (bib_conc_pack.e:323-335), BIB_CONC_PACK interlinear_chapter (bib_conc_pack.e:150-156, accumulating in BIB_INTERLINEAR_WORD.add_morpheme, bib_interlinear_word.e:81-96)
**Description:** Each walks rows ordered by position and merges consecutive rows with an equal position into one word: surface appended (lookup, interlinear), transliteration joined with a hyphen (cli/bib_lookup.e:263-266 and bib_interlinear_word.e:91 are the same rule written twice), door chosen (Finding 1). BIB_INTERLINEAR_WORD is already the merged word; add_verse_words could build the same type from the rows, and headwords_behind_original_word could consume it instead of a tuple list. `l_word` and `l_current` in interlinear_chapter (bib_conc_pack.e:131) are two names for one cursor.
**Suggested Action:** a shared "word of merged morphemes" type or ancestor, with the door helper of Finding 1 inside it.
**Effort:** 3 loops.

### Finding 4: Corpus codes as literals; right-to-left decided by string compare
**Priority:** MEDIUM
**Category:** T1
**Classes:** BIB_LOOKUP, BIB_GUI_APP
**Description:** "WLC-MACULA" is written at cli/bib_lookup.e:73 and 113 and gui_app/bib_gui_app.e:969 and 1281; "NT-MACULA" at cli/bib_lookup.e:75 and 115. The new use, bib_gui_app.e:1281, sets right-to-left from the corpus code string, while the Parallel tab asks the version (`al_version.is_right_to_left`, bib_gui_app.e:1406). Two ways to answer "is this text right to left" will disagree once a corpus is added (BIB_LOOKUP already knows "LXX-RAHLFS", cli/bib_lookup.e:77, Greek, left to right). `corpus_for_book` (cli/bib_lookup.e:106-119) is the rule the new code uses; `original_corpus_for_version` repeats its literals.
**Suggested Action:** constants (Hebrew corpus, Greek corpus) in BIB_LOOKUP, or better a query on BIB_CONC_PACK (is a corpus right to left) from the corpus language, which the GUI calls.
**Effort:** 4 literals in the Hebrew case, 1 query.

### Finding 5: show_interlinear and show_parallel copy each other; tab indexes partly literal
**Priority:** MEDIUM
**Category:** A5 / T1
**Classes:** BIB_GUI_APP
**Description:** show_interlinear (bib_gui_app.e:1245-1253) and show_parallel (bib_gui_app.e:1344-1352) are the same body (leave Simple mode through `arrange (True)`, select a tab, fill it); only the index and the fill feature differ. on_center_tab (bib_gui_app.e:1232-1240) is a third copy of the index-to-fill mapping, and bib_gui_app.e:806-811 a fourth (the Interlinear branch tests the selected tab, the Parallel branch at line 807 fills regardless). Indexes: Interlinear has the constant `Interlinear_tab` (line 1242), Parallel uses the literal 2 (lines 1235 and 1350) and Bible the literal 1 (line 1074); the add_page order at bib_gui_app.e:1132-1134 is the only statement of the order, so reordering a tab breaks three literals silently.
**Suggested Action:** `Bible_tab`, `Parallel_tab`, `Interlinear_tab` constants side by side; one `show_center_tab (a_index)` that arranges, selects and calls one `fill_center_tab (a_index)`, which on_center_tab and lines 806-811 also call.
**Effort:** 2 features collapsed, 3 constants.

### Finding 6: Original-text verse numbers used as the reading version's verse numbers
**Priority:** MEDIUM (suspected drift; go_to's versification handling not verified)
**Category:** D1
**Classes:** BIB_GUI_APP
**Description:** fill_interlinear selects the cell whose `verse = reading_verse` (bib_gui_app.e:1313) and on_interlinear_word calls `go_to (reading_book, reading_chapter, l_word.verse)` (bib_gui_app.e:1335), where `verse` is the pack's own numbering. The note admits it, "Verses follow its own numbering" (bib_gui_app.e:1306). In a Psalm with a numbered title the Hebrew numbering is offset from the KJV, so the selection, and the navigation, land on a neighbouring verse. The same mismatch is already handled for the lexicon (bib_gui_app.e:969 compares the corpus with the version's versification); the Interlinear path does not use it.
**Suggested Action:** map through the versification as line 969 does, or limit click-to-verse to books where numbering agrees, and say so in the note.
**Effort:** 2 call sites.

### Finding 7: BIB_MORPHOLOGY_NAMES: thin contracts, a documented client that does not exist, public exposure
**Priority:** LOW
**Category:** A4
**Classes:** BIB_MORPHOLOGY_NAMES
**Description:** `morphology_text` (bib_morphology_names.e:21-38) has no postcondition (it could state no leading, trailing or doubled ", "). The class comment says it serves "the Interlinear tab and the Verse Analysis" (lines 3-4), but the only client is BIB_CONC_PACK (bib_conc_pack.e:32, 718); no Verse Analysis class uses it. BIB_CONC_PACK inherits it with no export clause (bib_conc_pack.e:32), whereas BIB_LANGUAGE_CODES is hidden with `{NONE} all` (bib_conc_pack.e:20-23), so `morphology_text`, `feature_name` and the `Part_of_speech_names` table are now public API of the pack. `feature_name` drops any value that merely starts with "unknown" (line 56).
**Suggested Action:** hide it in the pack (or export the one feature wanted), add a postcondition, correct the comment.
**Effort:** 3 features.

### Finding 8: Thin contracts on the interlinear classes
**Priority:** LOW
**Category:** A4
**Classes:** BIB_INTERLINEAR_WORD, BIB_CONC_PACK
**Description:** `make` has no precondition on `a_language` (Finding 2) and no postcondition that it is stored (bib_interlinear_word.e:43-48). `add_morpheme` (bib_interlinear_word.e:97-100) ensures the count only; it could also state that the surface grew by `a_surface.count` and, when `a_lemma_id > 0` and the word had no door, that the door is taken. The invariant (bib_interlinear_word.e:118-121) lacks `morpheme_count >= 0` and `has_door implies morpheme_count >= 1`. interlinear_chapter's postcondition (bib_conc_pack.e:179-185) states order only; unlike verse_words (bib_conc_pack.e:112) it has no positions-valid clause and does not state that every word has at least one morpheme.
**Effort:** 4 clauses.

### Finding 9: Design pill P03 is incomplete
**Priority:** LOW
**Category:** pill accuracy
**Classes:** BIB_GUI_APP
**Description:** The tip reads "Interlinear: word by word in the original, right to left for Hebrew; click a word and T4 follows it." (bib_gui_app.e:1468). What a click does (bib_gui_app.e:1325-1341): the word's VERSE becomes the place read (`go_to`, line 1335), and T4 follows only if the word has a headword (`has_door`, line 1338). A word without one moves the place and leaves T4 alone, so "T4 follows it" is wrong for those words and the place change is not mentioned. The pill hangs on `interlinear_note`, which is created empty (line 108) and so has no text width until the tab first fills (not measured). The other new tips match the code: C10 (line 1463), T3 (line 1467, P03 and Ctrl+I; accelerator at line 409, menu item at line 473) and the tools-strip tip (line 1147).
**Suggested tip:** "Interlinear: word by word in the original, right to left for Hebrew; a click moves the place read to the word's verse and, when the word has a headword, opens it in T4."
**Effort:** 1 string.

### Finding 10: fill_interlinear mixes fetch, cache and render; a failed read is cached
**Priority:** LOW
**Category:** A6 / M4
**Classes:** BIB_GUI_APP
**Description:** The feature (bib_gui_app.e:1255-1323) picks the corpus, writes four different notes (pack closed, no corpus, error, empty), renders every token and line, and selects a word. The cache key (`interlinear_book`, `interlinear_chapter`, lines 1271-1272) is set BEFORE the read, so a failed read, or a pack not yet open (note at line 1276), is not retried until the reader changes chapter. fill_parallel (line 1381) has the same shape, so the tab fillers want one pattern. A small render-one-word feature would keep the five `set_token_line` calls (lines 1290-1294) in one place.
**Effort:** split into 3 features; move the key assignment after success.

### Finding 11: Gloss source named by two constants for one fact
**Priority:** LOW
**Category:** T1
**Classes:** BIB_CONC_PACK
**Description:** `Gloss_link_kind` = "translation:ENG-STEP" (bib_conc_pack.e:1166) and `Gloss_corpus` = "ENG-STEP" (line 1169) state one source twice; english_rows hard-codes the family as `'translation:ENG-%%'` inside its SQL (line 580). The corpus code and link kind literals asked about are therefore already constants, which is right; derive one from the other so they cannot diverge. The GUI note names the source in text ("English: STEPBible", bib_gui_app.e:1306) although the call already returns the citation (bib_conc_pack.e:169-173).
**Effort:** 2 constants, 1 string.

## Recommended Order

1. Finding 1 (live defect: one word may open different headwords on different faces) together with Finding 3 (the helper that fixes it).
2. Finding 2 (shared row validation and one policy for a bad lemma) before another corpus or tab reuses the copy.
3. Finding 6 (check go_to with a Psalm, then fix).
4. Findings 5 and 4 (constants and one show-tab feature) before the next centre tab is added.
5. Findings 9, 7, 8, 10, 11 as cleanup; Finding 9 is one string and can go with the next GUI edit.
