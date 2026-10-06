# spec_windows design notes: simple_bible GUI

*2026-10-06. Implementation notes for `spec_windows.json`. Read with `00-GUI-SPEC.md`.*

> **Widget vocabulary: simple_widgets 0.8.1 (`SW_*` classes)**, not simple_vision. This deliberately departs from the eiffel-gui-ux skill's "windows" platform (D-006: native simple_widgets with simple_shaping, simple_cairo and simple_shell; no WebView2). Every missing capability is a **gap work item** for the owning library (§9). None is papered over in application code.

**What was checked in the toolkit (2026-10-06):** README, CHANGELOG (0.8.0, 0.8.1) and the public features of the classes used (`D:\prod\simple_widgets\src`). Claims about capabilities below cite the class. Where a capability is absent, the note says so and points at its GW item.

---

## 1. Application structure (proposed for /eiffel.spec)

Class names are proposals; the `SB_` prefix is a placeholder until the naming pass.

| Class | Role |
|---|---|
| `SB_APPLICATION` | Creates the theme, the window, the engine client and the user store; runs the window |
| `SB_MAIN_WINDOW` | Owns `SW_WINDOW`, the menu bar, toolbar row, `SW_DOCK_HOST`, status bar; registers accelerators; holds `app_activity` |
| `SB_PANEL` (deferred) | Header row, link chip, the four panel states (empty, loading, error, content); `refresh (a_ref: SB_ACTIVE_REFERENCE)`, `is_stale`, `link_set` |
| `SB_P01_BIBLE_TEXT` ... `SB_P14_ATLAS` | One effective panel class per panel in the spec |
| `SB_LINK_HUB` | The active reference per link set; subscriptions; the `panel_sync` machine per panel |
| `SB_ACTIVE_REFERENCE` | `verse_id`, `origin_system`, `range_end`, `word_token`; immutable value |
| `SB_LAYOUT_STORE` | Session snapshot per mode; presets; named layouts (v2) |
| `SB_JOB` (deferred) and descendants | Long engine work on separate processors (§5) |
| `SB_ENGINE_CLIENT` | The only door to the engine from the GUI; returns result objects with provenance and method ids |
| `SB_PROVENANCE_CHIP` | Builds the `SW_CHIP` + tooltip + Show-method link for one fact |
| `SB_STATE_MACHINE` | Table-driven machine for the regions in the JSON (states, transitions, guards, entry/exit actions) |

**Rule carried from D-004:** no panel issues SQL, formats a number it did not receive, or assembles a guide section on its own. The engine returns a result object; the panel lays it out.

## 2. Per-class notes

### Foundations

| Class | Use in simple_bible | Notes |
|---|---|---|
| `SW_WINDOW` | Main window | `enable_shaped_text` at creation (Hebrew and Greek through simple_shaping). `set_menu_bar` gives the bar the Alt key. `register_accelerator` for every Ctrl/Ctrl+Shift/Alt shortcut (a modifier is required by contract). `show_sheet` for D02-D07 and D09, `show_popover` for the word card, D01 and D10, `show_drawer` for the timeline event drawer, `toast` for notices (kinds 1-4). `set_on_tick` is a fixed 250 ms heartbeat (GW-26). Tests use the offscreen surface (`write_frame`, `simulate_key_down`, `simulate_context_click`, `simulate_wheel`) and never call `run`. |
| `SW_THEME` | Light, dark, high contrast | `make_light`, `make_dark`; `set_surfaces`, `set_semantics`, `set_washes` under the contrast invariant; `set_text_scale` for the interface scale. The reading size is a separate application setting passed to the text widgets' pixel size. |
| `SW_PAINTER` | Only through widgets and gutter/row renderers | `draw_shaped_layout` for host-drawn shaped text in `SW_LIST` rows and paragraph gutters. No dashes, hatches or gradients today (GW-18). |
| `SW_SHAPING` | One kit per window, per SCOOP processor | Workers never measure text; only the GUI processor holds a kit. |
| `SW_EVENT` | Behind every `on_[event]` | Link-hub subscriptions use the same ordered, abortable roll. |

### Layout and chrome

| Class | Use | Notes |
|---|---|---|
| `SW_DOCK_HOST`, `SW_DOCK_ZONE` | Main dock | West, east and south zones plus a center; empty zones collapse; `add_panel`, `move_panel`, `on_layout_change`. Zone fractions are fixed at creation (0.22 / 0.24 / 0.30) with no setter, a zone stacks its panels in equal shares, and there is no remove/hide or snapshot. All of that is GW-05. Title bars draw through the toy path (GW-04). |
| `SW_TABS` | Center Bible tabs; tabs inside panels | `add_lazy_page` so unopened pages cost nothing; `on_change` drives `panel_shown` (stale panels refresh). No close button or reorder (GW-15). |
| `SW_SPLITTER` | Interlinear over analysis; compare panes | Contract-clamped ratio. |
| `SW_COLUMN`, `SW_ROW`, `SW_CARD`, `SW_GROUP`, `SW_SCROLL_AREA` | Everything | One border from the window (`content_border`); boxes default to zero padding; explicit values win. |
| `SW_MENU_BAR`, `SW_MENU` | Menus and context menus | Both on the shaped path since 0.7.2; `&` mnemonics; menus are built fresh at every open, so enabled state is computed at open (no stale menus). |
| `SW_TOOLBAR` | Study tools | Tools, toggles (queried by label), gaps; hints show as tooltips. It hosts only tool buttons, so the reference box, version picker and search box sit beside it in an `SW_ROW`. |
| `SW_STATUS_BAR` | Status | Left and right texts only. Sections with a progress bar and a Cancel are GW-11. |
| `SW_SEGMENTED` | Mode switch, panel modes | Exactly one selected; `on_change`. |
| `SW_ACCORDION` | Guide sections | Multi-open (`set_exclusive (False)`). |
| `SW_DRAWER` | Timeline event drawer (v2) | Rides `show_drawer`. |

### Text

| Class | Use | Notes |
|---|---|---|
| `SW_PARAGRAPH_LIST` | Bible text, notes, compare-all | Variable-height shaped paragraphs; only the visible band painted; host-drawn gutter (`set_gutter_renderer`) and bands; selection set with anchor; one paragraph editable in place; marks per item through a legend. Missing: point to (item, character offset), a hover-dwell event, a scroll event for follow-along, raised small runs and small caps (GW-08), per-item direction and right alignment (GW-02). |
| `SW_TEXT_BOX` | Query boxes, editors, paste box | Shaped editing since 0.8.0 (bidi caret, cluster hit-testing); Windows spell check; marks; undo/redo; `set_invalid` for validation. |
| `SW_LABEL` | Headers, word header, edition labels | Shaped for `ui` and `body` roles since 0.8.1. **A `mono` label stays on the toy path by design**, so Hebrew or Greek must never go in a mono label (provenance codes and counts are ASCII and fine there). |
| `SW_SHAPED_TEXT`, `SW_TEXT_GEOMETRY`, `SW_CLUSTER_MATH` | Internal to the widgets above | GW-04 reuses `SW_SHAPED_TEXT` the way `SW_LABEL` did in 0.8.1. |
| `SW_MARKED_TEXT`, `SW_MARK_SPAN`, `SW_MARK`, `SW_MARK_LEGEND`, `SW_MARK_PALETTE`, `SW_MARK_PAINTER`, `SW_MARK_LEGEND_VIEW` | Highlights, find hits, divine names, diff, agreement classes | Spans carry REASONS, the legend carries LOOKS, so a reason re-themes everywhere at the next paint. Spans follow edits (`text_inserted`, `text_removed`). Line-per-span codec for `user.db`. The palette is held at 4.5:1 / 3:1 by contract. Badges (`badge_of`) give the non-color cue. |
| `SW_COMBO`, `SW_SELECT` | Reference box; version and source pickers | `SW_COMBO` is a text box plus an option menu; `SW_SELECT` has separators and per-option enabling. Option text draws on the toy path (GW-04) for `SW_SELECT`; version names are Latin, so this only matters for lemma pickers. |

### Data and charts

| Class | Use | Notes |
|---|---|---|
| `SW_DATA_GRID` | Results, verse analysis, range grid, cross-references, census, journey, ledger | Typed rows (`SW_GRID_COLUMN` value agents), click-to-sort, resize, host filter predicate, virtualized, selection follows the row object. Read-only (fine: grids here are views). Cells draw on the toy path, so Hebrew and Greek cells need GW-04. |
| `SW_LIST` | Related passages, article lists, tags, candidates | Row renderer agent receives the painter, so rows can draw shaped layouts through `draw_shaped_layout` today. |
| `SW_TREE`, `SW_TREE_TABLE` | Book tree, journal notebooks | Lazy children; toy-path labels (GW-04 for any non-Latin label). |
| `SW_STATISTIC` | Hits, the four buckets | Big value, muted label, optional delta. |
| `SW_CHIP`, `SW_BADGE` | Provenance, statuses, link sets, counts | Chips are mono pills with semantic kinds; statuses always carry their word. |
| `SW_BAR_CHART`, `SW_SCALE`, `SW_HEATMAP` | Graph by book, book x chapter | One series only today; target-versus-controls needs grouped bars (GW-10). |
| `SW_QUERY_BUILDER` | Search and census criteria | Its `query_text` emits SQL-shaped text "on demand"; simple_bible never executes it. The engine reads the clause model (`clauses`) and builds its own parameterized query. Nested groups, NOT, proximity and typed value pickers are GW-12. |
| `SW_CALENDAR`, `SW_DATE_PICKER`, `SW_PROGRESS` | Plans, devotional date, job progress | |
| `SW_EMPTY_STATE`, `SW_SKELETON` | Every panel's empty and loading states | The skeleton shimmer drifts on the heartbeat; a reduce-motion flag is in GW-14. |
| `SW_DIALOG`, `SW_FILE_DIALOG` | D08 and alerts; Locate and Save | Drawn (R7); `SW_FILE_DIALOG` uses base PATH/DIRECTORY only. |
| `SW_MAP` | Atlas (v2) | Natural Earth 110m coastlines; too coarse for the Levant (GW-19). |
| `SW_CANVAS` | Not used to cover any gap | The escape valve is reserved for genuinely app-specific drawing. Anything a GW item names is built in the library. |
| `SW_CLIPBOARD`, `SW_SPELLER`, `SW_KEYS`, `SW_MNEMONIC` | Copy, spell check, modifiers, menu letters | |

## 3. Data flow from the engine

```
user gesture
   |
   v
SB_MAIN_WINDOW / panel  --(event)-->  SB_STATE_MACHINE (app_activity)
   |                                         |
   | short lookup (verse, word, hover)       | long work (search, census, guide)
   v                                         v
SB_ENGINE_CLIENT.query  (separate call,   SB_JOB on a worker processor
  blocks < 50 ms)                            | pages / sections / progress
   |                                         v
   v                                    polled on the heartbeat (GW-26 to wake)
ENGINE RESULT (values + provenance keys + method id)
   |
   v
panel adapter: result -> widget model (rows, paragraphs, marks, chips)
   |
   v
SW_* widgets paint (GUI processor only)
```

- **Result objects carry their own provenance keys and a method id.** The adapter turns each provenance key into an `SB_PROVENANCE_CHIP` and each method id into a Show-method link. An adapter that receives a fact without a provenance key raises a contract violation (`fact_has_provenance`), which is NFR-007 enforced at the face.
- **AI-made rows** come from `ai_data.db` with `is_ai_made = true` and their method; the adapter must attach the AI-made chip (`ai_label_present`).
- **rix.db rows** come with `status`; the adapter must attach the status chip (`status_label_present`).
- **Display strings never become keys.** Clicks return word ids, verse ids and lemma ids to the engine (FR-024).

## 4. The link hub

- `SB_LINK_HUB` holds one `SB_ACTIVE_REFERENCE` per set (A, B, C). `set_reference (a_set, a_ref, a_origin_panel)` stores it and calls each subscribed panel's `reference_changed`.
- Each panel runs the `panel_sync` machine: visible and linked → `panel_refreshing`; hidden → `panel_stale` (refresh on `panel_shown`, from `SW_TABS.on_change` or a dock reflow); unlinked → unchanged. A newer reference cancels the panel's running job (cancel token) before starting the next.
- **Ordering:** the active Bible pane refreshes first (NFR-001), then the other visible panels in dock order.
- **Follow-along:** the Bible pane reports its first fully visible verse after 120 ms of scroll stillness. `SW_PARAGRAPH_LIST` has no scroll event today (GW-08); `first_visible` exists as a query.
- **Versification:** the hub stores the canonical `verse_id`; each panel asks the engine for its own version's verse and the rule applied, and shows the rule in its header and the status bar.

## 5. Threading (SCOOP)

**Processors:**

| Processor | Holds | Work |
|---|---|---|
| GUI | `SW_WINDOW`, painter, the one shaping kit, all widgets, `SB_LINK_HUB`, the state machines | Layout and paint; short synchronous queries |
| Lookup worker (`separate SB_ENGINE_WORKER`) | Its own read-only SQLite connection to `core.db` (+ attached `rix.db`, `ai_data.db`) | Verse hub, word card, lexicon, cross-references: answers in under 50 ms |
| Job worker(s) (`separate SB_JOB`) | Their own read-only connections | Search, census, guide sections, claim check. One per running job kind; on a 4-core machine, at most two at once |
| User store (`separate SB_USER_STORE`) | The only read-write connection to `user.db` | Notes, highlights, layout snapshots, ledger; writes serialized |

**Rules:**

1. **One SQLite connection per processor.** A connection is never passed between processors.
2. **Short lookups are synchronous separate queries.** The GUI waits for an answer that takes under 50 ms; anything that can take longer is a job.
3. **Jobs report through queries the GUI polls:** `progress`, `has_page (n)`, `page (n)`, `is_done`, `error_text`. The GUI polls on the heartbeat; with GW-26 the worker wakes the pump instead, so a first page shows as soon as it exists.
4. **Results are copied into the GUI processor** as plain values (STRING_32, INTEGER_64, arrays of them) when read. The GUI never keeps references into a worker's objects.
5. **Cancellation:** `request_cancel` sets a flag the job checks between chunks (every 1,000 verses or each section). A cancelled job's partial results are discarded, never shown as findings (ER-10).
6. **No text measuring off the GUI processor.** `SW_SHAPING` is one per processor; workers return text, the GUI shapes it.
7. **Writes are optimistic.** A note shows as saved at once; a failed write raises ER-03 with the text still in the editor.

## 6. Performance notes

- **Startup:** open `core.db` read-only, check `PRAGMA user_version` and table presence only; the full integrity check is Settings > Data > Verify. Paint the startup skeleton in the last layout's shape so the screen does not jump.
- **Lazy everything:** `SW_TABS.add_lazy_page` for tabs; panels in collapsed zones are stale, not refreshed; guide sections are requested as their accordion opens, except the first two.
- **Virtualization:** `SW_PARAGRAPH_LIST` paints only the visible band and caches layouts by item revision; `SW_LIST` and `SW_DATA_GRID` draw only visible rows. A chapter is the unit of loading; neighboring chapters are prefetched on the lookup worker.
- **Shaping cache:** layouts are cached by text and pixel size; changing the reading size is a new key by construction. Re-layout happens at resize end (simple_widgets R10).
- **Search streaming:** pages of 500 rows; the grid appends; the graph is computed by the engine from counts, not from the rows.
- **Memory (NFR-003, under 1 GB):** the GUI holds the visible chapter, its neighbors, and result pages on screen; older pages are dropped and re-read on scroll.

## 7. Testing without a desktop

- **Never open a visible window in tests or builds** (standing rule). Every GUI test builds `SW_WINDOW` offscreen, drives it with `simulate_key_down`, `simulate_context_click` and `simulate_wheel`, and reads pixels or `write_frame` PNGs.
- **The D-006 spike first:** render Gen 1:1 WLC (pointed, with cantillation), Gen 1:1 LXX (Swete) and John 1:1 WH in `SW_LABEL` and `SW_TEXT_BOX` offscreen, compare against a reference rendering, and file every defect against simple_shaping (GW-01, GW-02, GW-03).
- **State machines are tested as tables:** every transition in the JSON has a test that fires its event from its source state with the guard true and false.
- **Contract tests for the face:** `fact_has_provenance`, `ai_label_present`, `status_label_present`, `four_buckets_present`, `no_bare_lxx_label`.

## 8. Persistence (user.db)

| Table | Contents |
|---|---|
| `layout_snapshot` | mode, zone membership and order, zone fractions, tab order, link sets (needs GW-05's snapshot API to read the dock) |
| `settings` | key / value |
| `highlight`, `note`, `tag`, `bookmark`, `history`, `prayer`, `memory_card`, `plan_progress`, `collection` | Keyed to canonical verse ids |
| `census_definition`, `census_run` | Immutable after a run; versions (FR-025) |
| `ledger_entry` (v1.5) | Query, version, result id, ruling |

## 9. simple_widgets gap work items

Each item is filed against its owning library, fixed there, and followed by a downstream-dependents check across the fleet (D-006). Priority is the simple_bible release that needs it.

| ID | Capability needed | Library | Why simple_bible needs it | Priority |
|---|---|---|---|---|
| GW-01 | Load bundled font files privately (a per-process font collection from the app folder) | simple_shaping | The target user has no scholar fonts; simple_shaping's Hebrew fallback list names SBL Hebrew and Ezra SIL, which a stock Windows machine lacks | v1 |
| GW-02 | Paragraph base direction and alignment in `layout_for`; per-item direction and right alignment in `SW_LABEL`, `SW_TEXT_BOX`, `SW_PARAGRAPH_LIST`; gutter on the reading-start side | simple_shaping + simple_widgets | Hebrew verses must read right to left AND sit flush right with the verse number on the right; today the bidi is resolved but paragraphs are laid out from the left | v1 |
| GW-03 | Verified Hebrew cantillation and niqqud stacking (mark-to-mark), meteg, MapM's no-break space before paseq, polytonic Greek (combining and precomposed) | simple_shaping | Pointed WLC with cantillation is the default Hebrew display; any defect in the D-006 spike is fixed here | v1 |
| GW-04 | Shaped path in every remaining text-drawing widget: `SW_DATA_GRID` cells and headers, `SW_TREE`, `SW_TREE_TABLE`, `SW_TABS`, `SW_CHIP`, `SW_SELECT`, `SW_DIALOG`, `SW_STATUS_BAR`, `SW_DOCK_ZONE` title bars, `SW_TIMELINE`, charts, `SW_DIAGRAM`, `SW_MAP`, and the window tooltip | simple_widgets | Lemmas, Hebrew and Greek words appear in result grids, verse analysis, chips and dialogs; these widgets call the toy `text` path today (only `SW_LABEL`, `SW_TEXT_BOX`, `SW_PARAGRAPH_LIST`, menus and the chat thread are shaped) | v1 |
| GW-05 | `SW_DOCK_HOST`: tabbed zones, draggable zone edges with a fraction setter, hide/show/remove a panel, layout snapshot and restore | simple_widgets | The Study layout puts four or five panels in the south zone (equal-share stacking makes them unusable); Simple/Study presets and session restore need to read and set the dock | v1 |
| GW-06 | New `SW_PARALLEL_TEXT`: rows of aligned cells (one per canonical verse), columns per version with their own direction and font, row height = tallest cell, one scroll, marks per cell, sticky column headers, cell hit test | simple_widgets | Parallel Bible (A02), word diff (A04) and They Chose (I-P06) | v1 |
| GW-07 | New `SW_INTERLINEAR`: a wrapping flow of stacked word cells (surface, transliteration, pronunciation, gloss, lemma, Strong's, morphology), right to left or left to right, toggleable lines, token hit test and selection, keyboard navigation | simple_widgets | Interlinear (C04) | v1 |
| GW-08 | `SW_PARAGRAPH_LIST`: point to (item, character offset) hit test, hover-dwell and scroll events, raised small runs (inline Strong's numbers) and small caps (LORD) | simple_widgets | Word click and hover (A06), follow-along on scroll, KJV with Strong's display | v1 |
| GW-09 | Hover card: a dwell-opened popover hosting a widget tree at a point, shaped, staying open while hovered, opened for a sub-region a widget names | simple_widgets | Strong's and reference tooltips (A06, A07); the current tooltip is one line of toy text per whole widget | v1 |
| GW-10 | `SW_BAR_CHART` grouped multi-series bars | simple_widgets | Census target against control words (I-P02); its README already names grouped bars as a future | v1 |
| GW-11 | `SW_STATUS_BAR` sections holding text or a small widget (progress, button), with click agents | simple_widgets | Job progress with Cancel, link set, versification note, database edition | v1 |
| GW-12 | `SW_QUERY_BUILDER`: nested groups, NOT, proximity operators, typed value pickers (lemma, morphology code), clause-tree output | simple_widgets | Boolean, morphology and census criteria (B01, B05, D03); the engine must never execute builder-made SQL text | v1 |
| GW-13 | Rich document view and editor: headings, lists, block quotes, inline styles, links (verse links clickable), tables (view); images in v1.5 | simple_widgets | Commentaries, lexicon entries, dictionary articles and author-library documents are formatted text; notes need a rich editor (E03) | v1 |
| GW-24 | Function keys F1-F12 (allowed without a modifier), Ctrl+digit and Ctrl+punctuation reach the accelerator table | simple_shell + simple_widgets | F1, F3, F6 and Ctrl+1..9 shortcuts; simple_shell's key-down filter forwards stepping keys and Alt+letter/digit only | v1 |
| GW-26 | Cross-processor wake (a worker posts a message that wakes the pump) and a settable heartbeat | simple_widgets + simple_shell | `on_tick` is a fixed 250 ms heartbeat; search streaming and job completion should show at once | v1 |
| GW-14 | UI Automation bridge (names, roles, values, focus events) and a reduce-motion flag | simple_shell + simple_widgets | Screen-reader users get nothing from a drawn toolkit today | v1.5 |
| GW-15 | `SW_TABS`: closable tabs, drag reorder, overflow menu | simple_widgets | Many Bible tabs (`Ctrl+W`) | v1.5 |
| GW-16 | Follow the Windows high-contrast setting | simple_shell + simple_widgets | Accessibility | v1.5 |
| GW-21 | Render one widget region to PNG | simple_widgets | Share-safe export images of a pane (I-P05), Visual Copy later (D18) | v1.5 |
| GW-17 | New `SW_LANE_TIMELINE`: horizontal zoomable time axis on astronomical years (BC/AD display, no year zero), grouped collapsible lanes, points/bars/bands, stacked dispute envelopes, semantic zoom, synchronism cursor, hit test | simple_widgets | World timeline (D07, 11-HISTORY-TIMELINE); `SW_TIMELINE` is a vertical rail and `SW_GANTT` a day axis | v2 |
| GW-18 | `SW_PAINTER`: dashed and dotted strokes, hatch and pattern fills, linear gradients | simple_widgets | Certainty classes drawn by pattern, never color alone | v2 |
| GW-19 | `SW_MAP`: regional geometry (Levant and Mediterranean at higher resolution), routes, labels at zoom, layers | simple_widgets | Atlas (D06) | v2 |
| GW-20 | Print preview, print and print to PDF | simple_widgets + simple_cairo + simple_shell | Printing (A13) | v2 |
| GW-22 | Floating panels in a second window | simple_widgets + simple_shell | Second-monitor study layouts | v2 |
| GW-23 | `SW_DIAGRAM`: deterministic layered (left-to-right) layout | simple_widgets | Clause outlines (C09); the force layout is not reproducible | v2 |
| GW-25 | Audio playback codecs behind `SW_MEDIA_TRANSPORT` (MP3 for LibriVox) | simple_widgets + audio stack | Audio Bible (A12); playback codecs are future-gated in the toolkit README | v2 |

**v1 needs fifteen items** (GW-01 to GW-13, GW-24, GW-26). The first three are the D-006 spike's subject and come first, because every Hebrew screen depends on them.

## 10. Open points for Larry

1. **Ecclesiastes in the Swete slot:** Brenton 1851 rows labeled, or an explicit "not in this digital edition" (12-SEPTUAGINT A4, pending).
2. **"Larry's lean" in the public timeline** (11 §11 decision 3, pending; v2).
3. **Withdrawn rix.db documents in search:** this spec excludes them by default with an "Include withdrawn" switch, and always labels them. Confirm.
4. **E09 spell check in v1** and **guide frames in v1** go beyond 09's v1 list (00-GUI-SPEC §16). Confirm.
