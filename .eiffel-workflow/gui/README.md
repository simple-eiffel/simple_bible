# simple_bible GUI specification

*2026-10-06. Layout and operation spec for simple_bible's native face, produced with the `/eiffel.gui-ux generate windows` workflow.*

> **Widget vocabulary: simple_widgets 0.8.1 (`SW_*` classes).** The eiffel-gui-ux skill's "windows" platform assumes simple_vision (the legacy Vision2 wrapper); this spec deliberately uses simple_widgets instead, per D-006 (native simple_widgets, no WebView2, "we FILL GAPS"). Missing capabilities are gap work items for the owning library, never workarounds.

## Files

| File | What it is |
|---|---|
| `00-GUI-SPEC.md` | The human-readable specification (skill Step 1): philosophy (Simple and Study layouts), main window, panels P01-P14, sync model, dialogs D01-D10, keyboard, search, innovations, provenance, Hebrew and Greek rules, theming, accessibility, performance, state machine summary, release mapping |
| `spec_windows.json` | The JSON spec: `app`, `theme`, `windows` (widget tree), `panels`, `popovers`, `dialogs`, `sync_model`, `keyboard`, `events`, `validation`, `error_handling`, `contracts`, `state_machines` (six machines), `releases`, `gap_work_items`, and the root `states` / `transitions` / `screens` / `traceability` that simple_spec_viz reads |
| `spec_windows_design_notes.md` | Notes per `SW_` class, engine data flow, the link hub, SCOOP threading, performance, headless testing, persistence, and **§9 simple_widgets gap work items** (GW-01 to GW-26) |
| `spec_windows_state_diagram.txt` | ASCII diagrams of the three app regions and the three dialog machines |
| `output/` | simple_spec_viz output: `state_machine.svg`, `SCR-01.svg` ... `SCR-25.svg` (screen mockups), `traceability.md` |

**Counts:** 14 panels, 10 dialogs, 1 popover, 25 mockup screens. Root machine: 24 states, 62 transitions in 3 orthogonal regions. All six machines: 36 states, 78 transitions. Widget tree: 283 `SW_*` nodes of 45 types (40 shipped classes, 5 proposed by gap items: `SW_PARALLEL_TEXT`, `SW_INTERLINEAR`, `SW_RICH_TEXT_VIEW`, `SW_RICH_TEXT_EDITOR`, `SW_LANE_TIMELINE`); 156 positioned widgets in the mockups. Gap work items: 26 (15 for v1).

## Regenerating the visualization

Run headless, with output captured (it writes files only and opens no window):

```bash
cd /d/prod/simple_spec_viz/bin
./simple_spec_viz.exe visualize "D:\prod\simple_bible\.eiffel-workflow\gui\spec_windows.json" \
    -o "D:\prod\simple_bible\.eiffel-workflow\gui\output" > viz.log 2>&1
```

**Schema notes for whoever edits the JSON:**

- simple_spec_viz reads only the root `name`, `version`, `states` (`id`, `name`, `description`, `is_initial`, `is_final`, `screen`, `entry_actions`, `exit_actions`), `transitions` (`id`, `event`, `from`, `to`, `label`, `requirements`), `screens` (`id`, `name`, `description`, `widgets` with `type`, `id`, `label`, `x`, `y`, `width`, `height`; `requirements`) and `traceability` (`requirements_to_states`, `states_to_screens`). Everything else follows the reference examples (`D:\prod\reference_docs\gui\examples\`) and is ignored by the tool.
- State `name`s must be unique (the GraphViz builder refuses duplicates). State ids start `S-`, transition ids `T-` (the traceability report sorts by those prefixes).
- **Mockup labels must avoid `|`, `<`, `>`, `{`, `}`, `"` and `\`.** The mockup generator builds GraphViz record labels, and the first run (2026-10-06) failed on SCR-13 with `Error: bad label format {P11 Navigator|Books \\| Bookmarks ...}`. The labels were changed to use `/` and `-`; the second run produced all 25 screens.
- Mockup rows group widgets by `y` in 20-pixel bands.
- Keep the file ASCII (Hebrew and Greek appear in transliteration); the loader converts strings to 8-bit.
- Line endings: the JSON uses LF like the reference examples; the `.md` and `.txt` files use CRLF (the simple_bible repo convention).

**Last run (2026-10-06):** exit 0; "States: 24, Transitions: 62, Screens: 25"; state diagram OK; 25 screens; traceability report OK. In `traceability.md` the States → Screens table's Requirements column shows "-" for every state even though the Requirements → States table is filled; that is the tool's rendering, not missing data.

## Feature traceability: e-Sword and Logos to simple_bible

Feature IDs, names and fit classes come from `research/09-FEATURE-PARITY - e-Sword and Logos.md` (e-Sword / Logos columns: Y = present in the sources 09 reviewed). Releases follow 09 §9, 10's placement and 04's decisions; the two places this spec goes beyond 09 are marked ★ and explained in `00-GUI-SPEC.md` §16.

### A. Reading, layout and platform

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| A01 | Bible reader, many versions | Y | Y | P01 Bible Text | v1 |
| A02 | Parallel Bible | Y | Y | P02 Parallel (`SW_PARALLEL_TEXT`, GW-06) | v1 |
| A03 | Compare mode (one verse, every version) | Y | Y | P02 Compare all | v1 |
| A04 | Word-level difference highlighting | - | Y | P02 Show differences | v1 |
| A05 | Gospel harmony | Y | - | P02 Harmony | v2 |
| A06 | Tooltips for Strong's and references | Y | - | Word hover card (GW-08, GW-09); P04 reference hover | v1 |
| A07 | Power Lookup | - | Y | P04 Expand references | v1 |
| A08 | Docked study panels | Y | - | Main window `SW_DOCK_HOST` (GW-05) | v1 |
| A09 | Saved layouts | Y | - | D07 Layouts: presets and session restore v1; named layouts v2 | v1 / v2 |
| A10 | Dark mode and themes | Y | - | Toolbar switch; D05 Appearance | v1 |
| A11 | Localized interface | Y | - | D05 Languages (interface language) | v2 |
| A12 | Audio Bible | Y | Y | P01 media bar (GW-25) | v2 |
| A13 | Printing | Y | - | File > Print (GW-20) | v2 |
| A14 | Mobile apps | Y | Y | Outside this face (bible_pwa) | v3 |
| A15 | Web app | - | Y | Outside this face (PWA) | v2 |
| A16 | Sync across devices | Y | Y | D05 Data (portable user.db folder) | v3 |

### B. Search

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| B01 | Word and phrase search, Boolean | Y | Y | Quick search; P07; D02 Basic/Boolean | v1 |
| B02 | Regular-expression search | Y | - | P07 `/regex/`; D02 | v1 |
| B03 | Strong's / lemma search | Y | Y | P07 `lemma:`/`strongs:`; word card Search; D02 | v1 |
| B04 | Library-wide search | Y | Y | P07 scope "Whole library" | v1 |
| B05 | Morphological search | - | Y | P07 `morph:`; D02 Morphology (GW-12) | v1 |
| B06 | Syntax search | - | Y | D02 Syntax mode | v3 |
| B07 | Clause search | - | Y | D02 Clause mode | v2 |
| B08 | Inline search | - | Y | `Ctrl+F` find bar in P01 and reading panes | v1 |
| B09 | Smart (meaning) search | - | Y | P07 Meaning mode | v2 (D-016: Release 1.1/2) |
| B10 | Graph of results by book | - | Y | P07 Graph tab (`SW_BAR_CHART`, `SW_HEATMAP`) | v1 |
| B11 | Entity and map search | - | Y | D02 Entity mode; P14 | v2 |
| B12 | Visual filters | - | Y | P01 overlays (divine-name preset is v1) | v2 |

### C. Original-language tools

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| C01 | Strong's dictionaries | Y | - | P05 Word tab; word card | v1 |
| C02 | Fuller lexicons (BDB, Thayer, Abbott-Smith, LSJ) | Y | Y | P05 lexicon tabs (GW-13) | v1 |
| C03 | Lexicon compare | Y | - | P05 Compare | v1 |
| C04 | Interlinear | - | Y | P03 (`SW_INTERLINEAR`, GW-07) | v1 |
| C05 | Reverse interlinear | - | Y | P03 Reverse mode | v2 |
| C06 | Bible Word Study | - | Y | P08 Word Study: core sections ★ v1, full v2 | v1 ★ / v2 |
| C07 | Exegetical Guide | - | Y | P08 Exegetical Guide | v2 |
| C08 | Bible Sense Lexicon | - | Y | P05 Senses; P08 Word Study | v2 |
| C09 | Clause visualizations | - | Y | P03 Clause outline (GW-23) | v2 |
| C10 | Sentence diagramming | - | Y | P03 Diagram | v3 |
| C11 | Textual variants | - | Y | P03 Variants; P08 Exegetical | v2 |
| C12 | Lemma in Passage | - | Y | P03 "Uses in Bible" column; P08 rare words | v1 |
| C13 | Verse Analysis | Y | - | P03 Verse Analysis grid | v1 |

### D. Reference library and guides

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| D01 | Public-domain commentaries | Y | Y | P04 Commentaries | v1 |
| D02 | Cross-references (TSK, OpenBible) | Y | - | P04 Cross-references | v1 |
| D03 | Bible dictionaries | Y | - | P05 Bible Dictionaries | v1 |
| D04 | Reference library (Josephus, fathers) | Y | Y | P04 Books | v2 (proposed; not placed in 09's lists) |
| D05 | Devotionals | Y | - | P04 Devotional | v1 |
| D06 | Maps and atlas | Y | Y | P14 Atlas (GW-19) | v2 |
| D07 | Timeline | - | Y | P13 World Timeline (GW-17, GW-18) | v2 |
| D08 | Factbook | - | Y | P08 Passage Guide people and places; Factbook guide | v2 |
| D09 | Passage Guide | - | Y | P08 Passage Guide: core sections ★ v1, full v2 | v1 ★ / v2 |
| D10 | Topic Guide | - | Y | P08 Topic Guide; P04 Topics | v2 |
| D11 | Theology Guide | - | Y | P08 | v3 |
| D12 | Counseling Guide | - | Y | BLOCKED (licensed content) | none |
| D13 | Sermon Starter Guide | - | Y | P08 | v3 |
| D14 | Sermon illustrations | Y | - | P04 | v3 |
| D15 | NT Use of the OT | - | Y | P08 They Chose (indexed quotations v1); full browser v2 | v1 / v2 |
| D16 | Bible Books Explorer | - | Y | P11 Books > Explorer | v1 |
| D17 | Bible Browser | - | Y | P07 Browser mode | v2 |
| D18 | Media tool and Visual Copy | - | Y | D06 image export (GW-21 v1.5) | v2 |
| D19 | Popular Quotations | - | Y | P04 | v3 |

### E. Personal study tools

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| E01 | Highlighting (whole-verse, all versions) | Y | Y | P01 marks; P06 Highlights | v1 |
| E02 | Bookmarks and history | Y | - | P11 Bookmarks, History; Back/Forward | v1 |
| E03 | Study notes, rich editor | Y | Y | P06 Verse notes (GW-13) | v1 |
| E04 | Topical notes, journal | Y | Y | P06 Journal | v1 |
| E05 | Verse tagging | Y | - | P06 Tags | v1 |
| E06 | Prayer list | Y | - | P06 Prayer | v1 |
| E07 | Scripture memory | Y | - | P06 Memory | v1 |
| E08 | Reading plans | Y | Y | P11 Plans | v1 |
| E09 | Spell check and thesaurus | Y | - | Note editors: spell check ★ v1 (`SW_TEXT_BOX`); thesaurus v2 | v1 ★ / v2 |
| E10 | Copy verses in formats | Y | Y | D06 Export / Copy; `Ctrl+C` | v1 |
| E11 | Collections | - | Y | P11 Collections; P07 scope | v1 |
| E12 | Workflows | - | Y | P08 Workflows | v2 |
| E13 | Citation tool | - | Y | D06 Cite | v2 |
| E14 | Print-library catalog | - | Y | Not placed in 09's lists; proposed v3 | v3 (proposed) |

### F. Teaching and preaching

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| F01 | Sermon Builder | - | Y | Separate tool | v3 |
| F02 | Sermon Manager | - | Y | Separate panel | v2 |
| F03 | Preaching Mode | - | Y | Separate window mode | v2 |
| F04 | Sermon and study markers on passages | - | Y | P01 gutter markers | v2 |
| F05 | Bible Study Builder | - | Y | Not placed in 09's lists; proposed v3 | v3 (proposed) |
| F06 | SermonAudio link-out | Y | - | P04 link-out (user-initiated network) | v2 (proposed) |
| F07 | Video courses (Mobile Ed) | - | Y | BLOCKED | none |

### G. AI features

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| G01 | Study Assistant | - | Y | P08 Ask (engine-first, labeled) | v3 |
| G02 | Summarize | - | Y | P04 (build-time summaries, reviewed, labeled) | v3 |
| G03 | Questions to Ask | - | Y | P08 | v3 |
| G04 | Search Results Synopsis | - | Y | P07 | v3 |
| G05 | Sermon Assistant | - | Y | Separate tool | v3 |
| G06 | Auto-translation | - | Y | P04 | v3 |
| G07 | Insights sidebar (related passages) | - | Y | P04 Related: precomputed, AI-made rows labeled (D-016) v1; full sidebar v2 | v1 / v2 |

### H. Content ecosystem

| # | Feature | e-Sword | Logos | simple_bible panel or dialog | Release |
|---|---|---|---|---|---|
| H01 | Module download manager | Y | Y | D05 Data > Library manager | v2 |
| H02 | User and third-party modules | Y | - | D05 Data > Import | v2 |
| H03 | Legacy STEP-format viewer | Y | - | Not placed | none planned |
| H04 | BDAG and HALOT | - | Y | BLOCKED (substitutes in P05) | none |
| H05 | Modern copyrighted translations | Y | Y | BLOCKED (BSB, KJV, ASV, YLT shipped) | none |
| H06 | Licensed commentaries and study Bibles | Y | Y | BLOCKED (P04 public-domain set) | none |
| H07 | Licensed dramatized audio | Y | - | BLOCKED | none |
| H08 | Logos/Lexham proprietary datasets | - | Y | BLOCKED (MACULA, STEPBible, UBS open data) | none |

### Innovations (10-INNOVATIONS FROM PRACTICE)

| ID | Innovation | Panel or dialog | Release |
|---|---|---|---|
| I-P01 | Claim Check | D04; results in P09 | v1.5 |
| I-P02 | Frequency-matched controls | D03; P09 controls chart (GW-10) | v1 |
| I-P03 | FAILS always shown | P09 four-bucket strip | v1 |
| I-P04 | Leading-question warning | AI layer | v2 |
| I-P05 | Share-safe export | D06 verification flags | v1.5 |
| I-P06 | Quotation comparer, "They chose" | P08 They Chose | v1 |
| I-P07 | A word's journey | P08 Word's Journey | v1 |
| I-P08 | Divine-name view | P01 / P02 overlay | v1 |
| I-P09 | Range before ruling | P05 Word tab; P08 Word Study | v1 |
| I-P10 | Gloss-aware writing pane | P06 editors | v2 |
| I-P11 | Grounded drafting | AI layer | v2 |
| I-P12 | Study ledger | P12 | v1.5 |
| I-P13 | Write the question down first | D02 option (census pre-registers in v1) | v1.5 |
| I-P14 | Pattern builder | P09 Shapes > New | v2 |
| I-P15 | Preflight for a topic | P06 / P10 | v2 |
| I-P16 | The human adjudicates | AI never a source (all); P12 My ruling (v1.5); Argue the other side (v2) | v1 / v1.5 / v2 |
| I-P17 | Reply kit | D04 | v2 |

## Where to go next

1. Run the D-006 spike offscreen (Gen 1:1 WLC with cantillation, Gen 1:1 LXX Swete, John 1:1 WH in `SW_LABEL` and `SW_TEXT_BOX`), and file its defects as GW-01 to GW-03.
2. Open the v1 gap items (design notes §9) against simple_widgets, simple_shaping and simple_shell.
3. Feed `00-GUI-SPEC.md` into `/eiffel.spec` and `/eiffel.intent` for the GUI layer.
