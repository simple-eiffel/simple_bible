# Design Scan (diff mode): simple_bible since 0255b48
# Date: 2026-10-28
# Subjects: cli/bib_reference_linker.e, gui_app/bib_gui_app.e (Commentary held clause and its callers)
# Compared against: gui_app/, src/, cli/
# Mode: read-only; nothing compiled; proposals only

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Abstraction / duplication | 7 | 1 | 4 | 2 |
| MI / helper object | 1 | 0 | 1 | 0 |
| Contracts | 3 | 2 | 0 | 1 |
| **Total** | **11** | **3** | **5** | **3** |

## Findings

| # | Priority | Category | Subject | Opportunity | Effort |
|---|----------|----------|---------|-------------|--------|
| 1 | HIGH | contracts | hold state in gui_app/bib_gui_app.e | No invariant ties is_commentary_held to held_* and the origin button | 1 invariant + 1 postcondition |
| 2 | HIGH | A5 | numbers_at in cli/bib_reference_linker.e | Digit-reading loop written four times | 1 helper feature |
| 3 | HIGH | contracts + D1 | target_range / target_place and its two callers | No postcondition on what a link target may name; callers guard differently; hover loop unbounded | 1 postcondition + 1 shared guard |
| 4 | MEDIUM | A6 / G4 | linker, passage_card, snapshot_reference_card, history | Five positional INTEGERs for a passage; a BIB_PASSAGE value would own range text, place text, parsing | 1 class |
| 5 | MEDIUM | M4 / A6 | BIB_GUI_APP | The hold (state, 3 queries, release/back/button) is a cohesive helper hiding in a 4400-line class | 1 helper class |
| 6 | MEDIUM | A5 | commentary_book/chapter/verse | One shape written three times (and again as held_*, shown_*, reading_*) | folds into 4 or 5 |
| 7 | MEDIUM | contracts | show_cross_refs skip-when-unchanged | Cannot hide a refresh today; nothing keeps it that way | 1 reset feature |
| 8 | MEDIUM | A5 | passage_card, copy_chapter, open_reading | "n text" verse formatting and chapter-to-list copy repeated; card re-queries a chapter the app holds | 1 helper + 1 generic feature |
| 9 | LOW | A5 | three `create {BIB_REFERENCE_LINKER}.make` | A linker built per hover, per click, per page | 1 attribute |
| 10 | LOW | A5 | snapshot_reference_card | Re-implements link scanning with a "bible:" literal and has ('-') | reuse target_range |
| 11 | LOW | contracts | is_following_commentary flag | Not exception safe; set and cleared by hand around go_to | 1 wrapper |

## Detailed Findings

### Finding 1: Hold state has no invariant (HIGH, contracts)
**Evidence:**
- gui_app/bib_gui_app.e:3666-3670: is_commentary_held, held_book, held_chapter, held_verse are four independent attributes. The class has no invariant clause at all (grep for a line starting "invariant" in gui_app/bib_gui_app.e finds none).
- The only thing that makes the hold a valid place is the entry test at gui_app/bib_gui_app.e:3934 (reading_book > 0 and reading_chapter > 0), inside on_commentary_link. Nothing states it as a law. Consumers trust it: commentary_book/chapter/verse (3679-3705) return held_* unchecked; back_to_commentary_verse (3728-3739) passes them to go_to, whose precondition (1213-1215) requires book > 0 and chapter > 0.
- release_commentary (3717-3726) leaves held_* at their old values; its postcondition says only `not is_commentary_held`.
- show_origin_button has the postcondition tying the button to the flag (3757), but release_commentary and on_commentary_link must remember to call it; the button state is not an invariant.
**Proposal:** invariant `is_commentary_held implies (held_book > 0 and held_chapter > 0 and held_verse >= 0)`; if finding 5 is taken, the invariant lives in the helper where it is cheap to check. Strengthen release_commentary with the button postcondition.
**Note:** no file in testing/ names is_commentary_held or passage_card (grep), so the hold is exercised only through the GUI snapshot path.

### Finding 2: numbers_at reads digits four times (HIGH, A5)
**Evidence:** cli/bib_reference_linker.e:290-293, 297-300, 306-309, 313-316. Each is `from until i > a_text.count or else not a_text [i].is_digit loop X := X * 10 + a_text [i].code - ('0').code; i := i + 1 end`, differing only in the target variable. The ":" followed by a digit test (294, 310) is also the same shape twice. The other digit loop in the project (src/core/bib_strongs_key.e:127) is a different grammar and not a copy.
**Proposal:** one private feature returning the value and the next index (a small TUPLE or a BIB_NUMBER_READER with `value` and `position`), plus `colon_number_follows (a_text, a_index)`. numbers_at drops from about 75 lines to about 40. It also gives one place to fix a latent issue: a very long digit run overflows INTEGER silently before the Max_number test at 342 (for example "Gen 99999999999").
**Effort:** 1 helper, 4 call sites.

### Finding 3: target_range has no postcondition; callers re-guard differently; hover loop unbounded (HIGH, contracts + D1)
**Evidence:**
- cli/bib_reference_linker.e:126-160 target_range: parts are read with is_integer, which accepts a sign, so "bible:1.-2.3" and "bible:1.1.1-999999999.1" both parse. There is no ensure clause, while its sibling place_in carries one (line 95: chapter and verse within Max_number) and numbers_at has one (354: ends after it starts). target_place (118-124) inherits the gap.
- The two GUI callers guard it differently (drift):
  - on_commentary_link, gui_app/bib_gui_app.e:3929-3930: has_book, chapter > 0, verse >= 0.
  - commentary_card, gui_app/bib_gui_app.e:3763-3765: has_book, chapter >= 1 only; the verse and the end are unchecked.
- passage_card then loops `from l_chapter := a_chapter until l_chapter > a_end_chapter or l_more` (gui_app/bib_gui_app.e:3790). A chapter the version lacks yields zero verses, so l_more never becomes True. A commentary pack (third-party markdown) holding a hand-written "bible:1.1.1-999999999.1" link would make a hover issue up to that many chapter queries on the UI thread. Links made by `linked` are bounded by Max_number, so only pack text reaches this.
**Proposal:** give target_range the same bounds as numbers_at as a postcondition (chapter and verse in 0..Max_number, end not before start); move the shared guard (has_book and chapter >= 1) into one feature such as `commentary_range_at (target)` used by both on_commentary_link and commentary_card; bound passage_card at the book last chapter. The stricter guard (on_commentary_link) should win.
**Effort:** 1 postcondition, 1 shared guard feature.

### Finding 4: a passage travels as five positional INTEGERs (MEDIUM, A6 / G4)
**Evidence:** range_target_text (cli/bib_reference_linker.e:106) takes five; reference_at and numbers_at return a six-INTEGER tuple (219, 281); target_range returns a five-INTEGER tuple (126); passage_card takes five (gui_app/bib_gui_app.e:3774); calls at gui_app/bib_gui_app.e:3767 and cli/bib_reference_linker.e:207 pass them by position, so a swap compiles. The range is spelled twice: range_target_text builds the link form (112) and passage_card builds the display form (gui_app/bib_gui_app.e:3821-3829).
**Proposal:** a BIB_PASSAGE value class (book, chapter, verse, end_chapter, end_verse; invariant end not before start; is_range, target_text, display_text, make_from_target). place_text (gui_app/bib_gui_app.e:4420) would serve ranges through it. It also absorbs the history triple (history.extend at 1222).

### Finding 5: the hold is a helper object inside a large class (MEDIUM, M4 / A6)
**Evidence:** gui_app/bib_gui_app.e:3664-3877 holds is_commentary_held, held_*, is_following_commentary, shown_*, commentary_book/chapter/verse, held_note, release_commentary, back_to_commentary_verse, show_origin_button. Its collaborators are reading_book/chapter/verse (read), go_to, and origin_button/reading_bar (widgets).
**Proposal:** BIB_COMMENTARY_HOLD (state, hold, release, place_for (reading place), the invariant of finding 1) owned by BIB_GUI_APP; widget work (show_origin_button) stays in the app. If another view wants the same hold, a deferred mixin inherited side by side is the multiple-inheritance form; for one owner a plain helper is enough.

### Finding 6: commentary_book/chapter/verse repeat one shape (MEDIUM, A5)
**Evidence:** gui_app/bib_gui_app.e:3679-3705, three queries each `if is_commentary_held then held_X else reading_X end`. The same triple appears as held_*, reading_* and shown_* (3670, 3676) and is compared member by member at 3899. With finding 4 or 5 the three become one `commentary_place`, and the comparison at 3899 becomes a single inequality.

### Finding 7: show_cross_refs skip-when-unchanged (MEDIUM, contracts)
**Evidence:** gui_app/bib_gui_app.e:3899-3915 redraws only when the commentary place differs from shown_*; shown_* are assigned only there (3901-3903) and never reset.
**Can it hide a needed refresh?** Not today. Callers checked: show_cross_refs is called only from open_reading (1294); open_reading is called from go_to (1227), move_in_history (1236), on_version_change (1040), the highlight add (2750) and reopen_reading (2776). Cross-references and commentary depend on the place alone, not on version or highlights, so skipping is right. The heading is set before the guard (3894-3898), so the held note stays current when only the reading place changes. The risk is future: anything that changes commentary content for an unchanged place (a pack reloaded or refused, the bible reopened) would show stale text, because nothing resets shown_*.
**Proposal:** an `invalidate_commentary` that zeroes shown_book, called by any pack or database change; or a comment contract stating the dependency. The name also misleads: show_cross_refs redraws the commentary too (3914); `follow_commentary_place` says so.

### Finding 8: verse formatting and chapter-to-list copy repeated (MEDIUM, A5)
**Evidence:** passage_card does not repeat verse_text_at_hub (gui_app/bib_gui_app.e:3436 fetches one verse by packed place; passage_card walks a range of chapters), so no merge is advised there. The duplication is elsewhere:
- Numbered verse text "n text": gui_app/bib_gui_app.e:3806 (passage_card) and 3269 (copy_chapter). copy_chapter uses reading_verses, while passage_card re-queries bible.text_reader.chapter (3791) even when the range lies in the chapter already held in reading_verses.
- The loop copying a BIB_LIST_RESULT into an ARRAYED_LIST: gui_app/bib_gui_app.e:1259, 3128, 3908, 3975, 4048, 4055 (six copies; none new in this diff, but show_cross_refs and show_commentary are subjects). A generic `to_list` on BIB_LIST_RESULT [G] removes them.
**Proposal:** `numbered_verse (a_verse, a_text)` helper; `to_list` on BIB_LIST_RESULT.

### Finding 9: linker built at every use (LOW)
gui_app/bib_gui_app.e:3764 (every hover), 3929, 3979 each `create {BIB_REFERENCE_LINKER}.make (bible.books)`; cli/bib_lookup.e:181 builds the forgiving variant. One attribute created after the books load serves the three.

### Finding 10: snapshot_reference_card scans links by hand (LOW)
gui_app/bib_gui_app.e:3851 uses the literal "bible:" (the linker owns Target_prefix, cli/bib_reference_linker.e:162) and has ('-') (3856) to detect a range; target_range plus an end-differs test says the same. It is a test hook inside production code; keep it small.

### Finding 11: is_following_commentary is set and cleared by hand (LOW)
gui_app/bib_gui_app.e:3940-3942: if go_to raised, the flag would stay True and every later go_to would keep the hold. go_to preconditions are met by the guard at 3930, so this is theoretical; a wrapper feature or rescue makes it structural.

## Checked, not findings
- back_to_commentary_verse (3728-3739) copies held_* into locals before release_commentary: needed because go_to must receive the verse; correct.
- target_text and range_target_text postconditions (103, 115) read back only the first place; the end of the range is not proven (a read-back through target_range would). testing/test_reading.e:167-172 covers one range and one single place.
- go_to and move_in_history releasing the hold (gui_app/bib_gui_app.e:1216-1218, 1234) match the rule "anything but a commentary link releases".

## Recommended Order
1. Finding 3 (bounds on target_range, one shared guard): closes the only reachable runaway loop; small.
2. Finding 1 (invariant): prerequisite for any hold refactor.
3. Finding 2 (digit helper): behavior-neutral and covered by linker tests.
4. Findings 4, 6, 5 together (BIB_PASSAGE and the hold helper), then 7 and 8.
