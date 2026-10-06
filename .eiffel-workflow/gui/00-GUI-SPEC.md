# 00 GUI SPEC: simple_bible (layout and operation)

*2026-10-06. Input specification for `/eiffel.gui-ux generate windows` (the skill's Step 1). Companion files in this folder: `spec_windows.json`, `spec_windows_design_notes.md`, `spec_windows_state_diagram.txt`, `README.md`.*

> **Widget vocabulary: simple_widgets 0.8.1 (`SW_*` classes).** This is a deliberate deviation from the eiffel-gui-ux skill, whose "windows" platform assumes simple_vision (the legacy Vision2 wrapper). simple_bible's face is native simple_widgets with simple_shaping, simple_cairo and simple_shell (D-006, decided by Larry 2026-10-06: "we FILL GAPS"; no WebView2). Where simple_widgets lacks a capability, this spec names a **gap work item (GW-nn)** for the owning library. It never specifies a workaround or a fallback. The gap list is in `spec_windows_design_notes.md` §9.

**Inputs read:** `research/09-FEATURE-PARITY - e-Sword and Logos.md` (feature IDs A01-H08 are used throughout), `10-INNOVATIONS FROM PRACTICE.md` (I-P01-I-P17), `11-HISTORY-TIMELINE.md`, `04-DECISIONS.md` (D-001-D-020), `03-REQUIREMENTS.md` (FR-/NFR- IDs), `12-SEPTUAGINT-SOURCE.md`, the design doc `Bible Study Workbench - Design (2026-10-06).md`, and simple_widgets' README, CHANGELOG and class headers (`D:\prod\simple_widgets\src`, 114 classes).

---

## 1. Purpose

simple_bible is a free Windows Bible-study workbench for someone who is not Larry: CPU only, 8-16 GB of RAM, no setup skills (D-003). It must let a reader **see, count, compare and check** the biblical text in Hebrew, Greek and English, with every number computed and every quotation pulled from the data (design doc §1). The engine owns every fact; the GUI only shows engine results and never invents, rounds away or hides one (D-004, C-004).

The GUI has two jobs that pull against each other:

1. **Be as easy as e-Sword.** Open the program, type a reference, read. Panes follow along. One click from a word to its dictionary entry.
2. **Reach as deep as Logos.** Guides, interlinear, morphology search, word studies, census with controls, quotation comparison, all from open data.

## 2. Design philosophy: one window, two layouts

### 2.1 The decision: a SIMPLE / STUDY mode switch over shared panels

simple_bible has **one main window with one set of panels** and **two layout presets**:

- **Simple** (the default on first run): the classic three-pane reader arrangement that e-Sword users know. Bible text in the center, commentary on the right, dictionary and lexicon below. Large type. Every pane follows the verse being read; there are no link-set controls on screen.
- **Study**: the Logos-style workbench. A navigator on the left, Bible tabs (text, parallel, interlinear) in the center, lexicon and commentary on the right, a results area below (search, guides, census, author library). Link-set chips appear on panel headers.

The switch is a segmented control on the toolbar (`SW_SEGMENTED` "Simple | Study") and `Ctrl+M`.

**Rules that keep the switch honest:**

1. **The mode changes layout, never data or ability.** The active reference, open tabs, selection, notes, search results and running jobs survive a switch untouched.
2. **Menus are identical in both modes.** Every tool is reachable from the menus in Simple mode. Hiding menu items by mode creates "where did it go?" confusion, the opposite of simplicity. What changes is the toolbar's density and which panels are docked by default.
3. **Progressive disclosure inside Simple.** Opening a study tool in Simple mode (Word Study from a word card, a census from the Search menu) docks that one panel and shows a single toast: "Opened Word Study. Switch to the Study layout?" with a **Switch** action. The user is never moved without asking.
4. **Each mode remembers its own arrangement.** Moving a panel in Study mode does not disturb Simple mode, and the reverse. Both are restored at the next start (session snapshot).

### 2.2 Why not progressive disclosure alone

Pure progressive disclosure (start bare, grow as tools are used) was considered and rejected as the only mechanism:

- **It accretes.** After a week the screen looks like Logos, and the casual reader has no one-click way back. A named Simple layout is that way back.
- **Large-print readers need a stable screen** (NFR-013: "large-print friendly (matches Larry's audience)"). Panels that appear and disappear on their own move the text the reader was following.
- **Two named presets are teachable.** "Click Simple to read; click Study to dig" fits on one line of a help page.

Progressive disclosure is kept *inside* Simple mode (rule 3), where it serves the reader who meets one deeper tool at a time.

### 2.3 What each side contributes

| From e-Sword (simplicity) | From Logos (depth) | Neither has (simple_bible adds) |
|---|---|---|
| Always-synchronized panes: change the verse and everything follows | Link sets: panels follow different references on purpose | A provenance badge on every fact; "Show method" behind every number (FR-032) |
| One-click word to dictionary (Strong's tooltips, A06) | Guides assembled per passage and per word (D09, C06, C07) | FITS / PARTIAL / FAILS / NO_DATA always shown together (I-P03, FR-026) |
| A reference box that takes "jn 3 16" | Morphology and lemma search with a builder (B03, B05) | Census with frequency-matched controls (I-P02) |
| Docked panels and saved views (A08, A09) | Interlinear and verse analysis (C04, C13) | "They chose": a computed quotation verdict (I-P06) |
| Dark mode, large type | Text comparison with word diff (A04) | AI-made data labeled as such, and no AI run on the user's machine in Release 1 (D-016) |

## 3. Main window layout

### 3.1 Chrome (both modes)

```
+------------------------------------------------------------------------------------------+
| File  Edit  View  Go  Search  Study  Tools  Window  Help                (SW_MENU_BAR)    |
+------------------------------------------------------------------------------------------+
| [<] [>]  [ John 3:16            v]  [ BSB           v]  [ Search the Bible...       ]  |
|  back fwd  reference box (SW_COMBO)   version (SW_SELECT)  quick search (SW_TEXT_BOX)    |
|                                   [Simple | Study]  (SW_SEGMENTED)   [A-][A+]  [Dark]    |
|  Study-mode extras (SW_TOOLBAR): Parallel  Interlinear  Guide  Word Study  Count  Ledger |
+------------------------------------------------------------------------------------------+
|                         SW_DOCK_HOST (zones: west, east, south; center)                 |
|                                                                                          |
+------------------------------------------------------------------------------------------+
| John 3:16 (BSB) | link A | KJV numbering | Searching... 42% [Cancel] | core.db 2026.10 |
|                                                         (SW_STATUS_BAR, sections GW-11) |
+------------------------------------------------------------------------------------------+
```

- **Menu bar** (`SW_MENU_BAR`, registered with `SW_WINDOW.set_menu_bar` so Alt+letter works): File, Edit, View, Go, Search, Study, Tools, Window, Help. Mnemonics through `&` labels (`SW_MNEMONIC`).
- **Toolbar row** (`SW_ROW` holding the controls below, then an `SW_TOOLBAR` strip of tools; `SW_TOOLBAR` hosts buttons and toggles only, so the input controls sit beside it in the row):
  - Back / Forward (`SW_BUTTON`, history, `Alt+Left` / `Alt+Right`).
  - **Reference box** (`SW_COMBO`): accepts "John 3:16", "jn 3 16", "Ps 23", "Gen 1:1-5; Heb 8:8". Dropdown holds recent references. Enter navigates. Invalid input marks the box invalid (`set_invalid`) with a message under it; ambiguous input opens a candidate popover (FR-020: "ambiguous input returns a choice, never a guess").
  - **Version picker** (`SW_SELECT`): versions grouped by language with separators (`add_separator_after`). Every LXX entry shows its edition: "LXX (Swete)", never bare "LXX" (12-SEPTUAGINT checklist).
  - **Quick search** (`SW_TEXT_BOX`, single line, clear button): Enter runs a basic search into the Search Results panel.
  - **Mode switch** (`SW_SEGMENTED`: Simple | Study).
  - Text size A- / A+ (`SW_BUTTON`, also `Ctrl+-` / `Ctrl+=`) and Dark/Light (`SW_SWITCH`).
  - **Study tools** (`SW_TOOLBAR`, shown in Study mode only): Parallel, Interlinear, Passage Guide, Word Study, Count (census), Ledger (v1.5). Toggle tools latch (`add_toggle`); tool hints show as tooltips.
- **Dock host** (`SW_DOCK_HOST`): a center document plus west, east and south zones. An empty zone collapses to nothing (the class's own law). Panels move between zones by drag (middle-click title bar, drop on a zone) or from Window > Move Panel.
- **Status bar** (`SW_STATUS_BAR`): current reference and version, the active link set, the versification note for the current pairing, job progress with Cancel, and database edition. `SW_STATUS_BAR` has a left and a right message only; sections with a progress bar and a clickable Cancel need **GW-11**.

### 3.2 Simple layout

```
+------------------------------------------------------------+------------------------+
| CENTER: P01 Bible Text (one tab, large print)               | EAST: P04 Commentary   |
|                                                              |   & Library            |
|  John 3                                                      |   (follows the verse)  |
|  16 For God so loved the world that He gave His one and     |                        |
|     only Son, that everyone who believes in Him shall not   |                        |
|     perish but have eternal life.                           |                        |
+------------------------------------------------------------+------------------------+
| SOUTH: P05 Dictionary & Lexicon (follows the clicked word)                          |
+-------------------------------------------------------------------------------------+
```

Default panels: P01 center, P04 east, P05 south. All in link set A, with no link chips shown. Search Results (P07) docks south beside P05 only while a search is open and closes with it.

### 3.3 Study layout

```
+-------------+------------------------------------------+------------------------+
| WEST        | CENTER: SW_TABS                           | EAST                   |
| P11         | [BSB John 3] [Parallel] [Interlinear] [+]  | P05 Dictionary &       |
| Navigator   |                                           |     Lexicon            |
|-------------|  P01 / P02 / P03 as center tabs            |------------------------|
| P06 Notes   |                                           | P04 Commentary &       |
|             |                                           |     Library            |
+-------------+------------------------------------------+------------------------+
| SOUTH (tabbed zone, GW-05): P07 Search Results | P08 Guides | P09 Census & Checks | |
|                             P10 Author Library | P12 Study Ledger (v1.5)            |
+----------------------------------------------------------------------------------+
```

`SW_DOCK_HOST` stacks a zone's panels in equal shares under title bars. Five panels in the south zone need **tabbed zones (GW-05)**; resizable zone edges, hiding and restoring a panel, and a layout snapshot for session restore are in the same work item.

### 3.4 Panels (14)

| ID | Panel | Simple | Study | Link set | Release |
|---|---|---|---|---|---|
| P01 | Bible Text | center | center tab | A (each tab may choose) | v1 |
| P02 | Parallel and Compare | (menu) | center tab | A | v1 |
| P03 | Original Language (interlinear, verse analysis) | (menu) | center tab | A | v1 |
| P04 | Commentary and Library | east | east | A | v1 |
| P05 | Dictionary and Lexicon | south | east | A (follows the selected word) | v1 |
| P06 | Notes | (menu) | west | A | v1 |
| P07 | Search Results | south while open | south tab | none (shows its query) | v1 |
| P08 | Guides | (menu) | south tab | A | v1 core; v2 full |
| P09 | Census and Checks | (menu) | south tab | none (shows its definition) | v1 census; v1.5 Claim Check |
| P10 | Author Library (rix.db) | (menu) | south tab | A (documents citing the passage) | v1 |
| P11 | Navigator (books, bookmarks, history, plans, collections) | (menu) | west | A | v1 |
| P12 | Study Ledger | (menu) | south tab | none | v1.5 |
| P13 | World Timeline | (menu) | center tab | A (narrated and composition time) | v2 |
| P14 | Atlas | (menu) | center tab | A | v2 |

"(menu)" means the panel is closed in that preset and opens from the View menu or a command, docking where the preset puts it.

## 4. Synchronization model

### 4.1 The active reference

One **active reference** exists per link set. It is an engine object, never a display string:

- `verse_id`: the canonical verse key (the engine's hub id after the versification map, D-010).
- `origin_system`: the versification the user typed or clicked in (KJV-English, MT, Swete, Rahlfs-CCAT in the private build).
- `range`: optional end verse for passages.
- `word_token`: optional; the selected original-language token (word id), set by clicking a word.

Every pane converts the active reference into its own version's numbering through the engine. When a rule applied, the pane's header and the status bar say which one: "LXX (Swete) Ps 22:1 = MT Ps 23:1 (title outside verse 1)"; "Swete Mal 4:1 = MT Mal 3:19". Pairing code never hard-codes an offset (D-010, FR-022).

### 4.2 Link sets (from Logos) with follow-along (from e-Sword)

- **Link sets A, B and C, and Off.** A panel belongs to one. Changing the reference in any panel of a set moves every panel of that set. **Off** pins a panel: it keeps its reference until relinked.
- **Simple mode: everything is in A and no chip is shown.** That is e-Sword's behavior: the panes follow the verse, with nothing to learn.
- **Study mode: a link chip** (`SW_CHIP`, "A", "B", "C", "Off") sits in each panel's header row; clicking it opens a small menu (A / B / C / Off). `Ctrl+L` cycles the focused panel's set.
- **Two Bible tabs, two sets:** a second Bible tab can be put in set B to read Romans while set A follows John 3.
- **Follow-along on scroll:** in a Bible pane, the first fully visible verse becomes the active reference after 120 ms of scroll stillness (settable). Hover never changes the reference; click does.
- **Word follow:** clicking a word sets `word_token` in the set; the Lexicon, Interlinear and Word Study follow the word. Clicking a verse number clears the word.

### 4.3 Who updates when

| Event | Visible panels in the set | Hidden panels in the set (other tab, collapsed) | Unlinked panels |
|---|---|---|---|
| Reference changed | Refresh now; the active Bible pane renders first (NFR-001) | Marked **stale**; refresh when shown | Unchanged |
| Word selected | Lexicon, Interlinear, Word Study refresh; others highlight the token | Stale | Unchanged |
| Version changed in a pane | That pane only | - | - |
| Search result clicked | Navigates its target set (A by default; the results header chip chooses) | Stale | Unchanged |

A refresh started for an older reference is cancelled when a newer one arrives (state machine §15, region C).

## 5. Panels in detail

Every panel shares a **header row** (`SW_ROW`): title (`SW_LABEL`), the subject (reference or word), the link chip (Study mode), a provenance/sources button where the panel shows facts, and a panel menu (`SW_BUTTON` opening an `SW_MENU`). Every panel defines the same four states:

- **Empty** (`SW_EMPTY_STATE`): says what would appear and offers one action.
- **Loading** (`SW_SKELETON`, the shape of the content): shown after 150 ms, so fast results never flash.
- **Error** (`SW_CARD` with a danger stripe): what failed in plain words, **Retry**, and **Details** (the engine's message). The panel's last good content stays visible beneath when there is one.
- **Content.**

### 5.1 P01 Bible Text (center)

**Widgets:** `SW_TABS` (one tab per open Bible; `add_lazy_page` so unopened tabs cost nothing); each tab holds a header row (version `SW_SELECT`, edition label `SW_LABEL` with an info tooltip, caveat `SW_CHIP` when the version has one, display toggles) and an `SW_PARAGRAPH_LIST` with one paragraph per verse (verse-per-line mode) or per pericope paragraph (paragraph mode).

**Content and display:**

- **Gutter** (`set_gutter_renderer`): verse number, note marker, bookmark marker, highlight stripe, cross-reference dot. For Hebrew text the gutter belongs on the right; a per-item direction and alignment are **GW-02**.
- **Highlights** (E01) are `SW_MARKED_TEXT` spans with reasons ("hl:yellow", "hl:green" ...) drawn through an `SW_MARK_LEGEND`; whole-verse highlights show in every version because they are keyed to the canonical verse id.
- **Divine-name view** (I-P08, v1): a View toggle that marks the divine names through the passage with a fixed legend: יְהוָה YHWH (the divine name, rendered "the LORD"), אֱלֹהִים *Elohim* (e-lo-HEEM, "God"), אֲדֹנָי *Adonai* (a-do-NAI, "Lord"), אֵל *El* ("God"), שַׁדַּי *Shaddai* (shad-DAI, "Almighty"); in Greek κύριος *kyrios* (KOO-ree-os, "Lord") and θεός *theos* (the-OS, "God"). The marks come from lemma tags in Hebrew and Greek and from Strong's tags in the KJV. A Hebrew/Greek toggle sets the MT beside the LXX (Swete) to show where the Greek keeps or loses the distinction. Swete has no open morphology (12-SEPTUAGINT), so its side uses normalized surface forms and says so ("surface-form match").
- **Strong's numbers inline** (KJV with Strong's): small raised numbers after tagged words. Raised small runs inside a paragraph are **GW-08**.
- **Supplied words** (KJV italics) as an italic mark; **small caps LORD** needs a run style (GW-08).
- **Hebrew pointing level** (Hebrew panes): Full (vowels and cantillation) / Vowels only / Consonants, `Ctrl+Shift+P` cycles. The engine supplies the reduced forms; stored display text is never edited (FR-008).
- **Edition labels and omissions:** "LXX (Swete)" with the tooltip "Codex Vaticanus as printed by H. B. Swete (Cambridge, 1887-1912). Digital text from OCR; it may contain errors. Report one: [link]." Two-text books are labeled by text ("Daniel (Old Greek)", "Daniel (Theodotion)"). An omitted verse is a muted placeholder that says why: "Matt 17:21: omitted in this edition (WH)" (FR-009), and for Swete either "absent from Swete's edition" or "missing from this digital text (OCR loss)". Ecclesiastes in the Swete slot follows Larry's pending call (Brenton 1851 rows labeled "Brenton 1851", or an explicit "not in this digital edition").

**Interactions:**

| Gesture | Result |
|---|---|
| Click a verse (or its number) | Selects it; sets the active reference of the tab's link set |
| Click a word | Selects the token; the word follows in the set (Lexicon, Interlinear) |
| Hover a word (400 ms) | Word hover card (§5.15) with lemma, Strong's, transliteration, pronunciation, gloss (A06). Per-word hit testing is **GW-08**; the hover card is **GW-09** |
| Double-click a word | Simple: pins the word card. Study: opens Word Study (P08) |
| Right-click | Context menu: Copy verse, Copy with format..., Highlight ▸, Add note, Bookmark, Tag..., Search this word, Word Study, Word's Journey, Passage Guide, Compare this verse, Quotation comparer (when the verse quotes or is quoted), Show method |
| `Ctrl+F` | Find bar inside the pane (B08) |
| Up / Down, Page Up / Page Down | Move verse selection, scroll |
| `Ctrl+PageUp` / `Ctrl+PageDown` | Previous / next chapter |

**States:** Empty "Type a reference above, or pick a book on the left." Loading skeleton lines. Error "This version could not be read" with Retry. A reference outside the version's canon (Tobit in the BSB) shows an empty state naming the versions that have it.

### 5.2 P02 Parallel and Compare (A02-A05)

**Modes** (`SW_SEGMENTED`): **Parallel** (versions side by side, scrolling together), **Compare all** (one verse in every shipped version, A03), **Harmony** (v2, A05).

- **Parallel** needs a verse-aligned, multi-column text view: rows are canonical verses, columns are versions, each cell is wrapped shaped text of its own direction, the row is as tall as its tallest cell, and there is one scroll. That widget is **GW-06 (`SW_PARALLEL_TEXT`)**. A thin note row appears where the versification map paired unequal numbers ("LXX 9 = MT 9-10").
- **Word diff** (A04, toggle): differing tokens between a base column and each other column are marked (wash) by an engine LCS diff; the legend says "differs from [base]".
- **Compare all**: an `SW_PARAGRAPH_LIST`, one paragraph per version, gutter showing the version label and caveat chip.
- **Column chooser:** `SW_BUTTON` opening a menu of versions with check marks; up to six columns.

**States:** Empty "Choose two or more versions." Error per column (one bad version does not blank the others).

### 5.3 P03 Original Language (C04, C12, C13)

- **Interlinear** (C04): stacked word cells that flow and wrap, right to left for Hebrew and left to right for Greek. Lines (each toggleable): surface word, transliteration, pronunciation, gloss, lemma, Strong's, morphology in English ("verb, aorist active indicative, 3rd singular"). That widget is **GW-07 (`SW_INTERLINEAR`)**. Example cell for Gen 1:1: בְּרֵאשִׁית / *bereshit* / be-re-SHEET / "in the beginning" / H7225 / "preposition + noun, feminine singular".
- **Source** (`SW_SELECT`): Hebrew OT (WLC, MapM), Greek NT (SBLGNT, WH), LXX (Swete). For Swete the morphology lines read NO_DATA with the note "No openly licensed morphology exists for Swete" (12-SEPTUAGINT).
- **Verse Analysis** (C13) under the interlinear: `SW_DATA_GRID` with # | Word | Transliteration | Lemma | Strong's | Morphology | Gloss | Uses in Bible (C12: lemma counts, rare words flagged). Each row carries a provenance chip. Hebrew cells in the grid need the shaped path in data widgets (**GW-04**).
- **Reverse interlinear** (C05), clause outline (C09), variants (C11) and sentence diagramming (C10) are later tabs (v2, v2, v2, v3).

### 5.4 P04 Commentary and Library (D01, D02, D05, related passages)

`SW_TABS`: **Commentaries** | **Cross-references** | **Devotional** | **Related** | **Books** (v2) | **Topics** (v2).

- **Commentaries** (D01): source `SW_SELECT` (Matthew Henry, Gill, Barnes, JFB, Clarke, Wesley); the comment for the active verse as rich text (**GW-13**). Scripture references inside the text are detected by the engine and underlined; hover shows the verse (A06), click navigates. **Expand references** (A07, Power Lookup) shows each cited verse inline beneath its reference.
- **Cross-references** (D02): `SW_DATA_GRID` (Reference | Text preview | Source | Votes): OpenBible.info with its vote counts and TSK, each row with a provenance chip.
- **Devotional** (D05): Spurgeon's *Morning and Evening*, Daily Light, by date (`SW_DATE_PICKER` to change the day).
- **Related** (G07 partial, D-016): precomputed related passages, each with **why it is listed** as chips: "cross-reference (OpenBible, 57 votes)", "shares a rare word", "**AI-made**: meaning neighbor". A banner at the top of the tab reads: "Some of these passages were found by an AI model (bge-m3) when this edition was built, not on your computer. Each one shows why it is listed." No model runs on the user's machine in Release 1.

### 5.5 P05 Dictionary and Lexicon (C01-C03, D03, I-P09)

`SW_TABS`: **Word** | **Compare** | **Bible Dictionaries**.

- **Word header:** the selected word in script, transliteration, pronunciation with the stressed syllable in capitals, and gloss on first use: ἐκκλησία *ekklēsia* (ek-klay-SEE-ah), "assembly". Strong's number and lemma with provenance chips.
- **Range before ruling first** (I-P09, FR-029): before any single lexicon entry, every attested rendering of the lemma with its count and an example verse, from the shipped glosses and tagged versions (`SW_DATA_GRID`: Rendering | Version | Count | Example). The data layer of senses (UBS SDBH/SDGNT) arrives in v2 (C08). 09 notes Logos already shows senses with counts; the difference here is the default order.
- **Lexicon entries** (C01, C02): Strong's, BDB (Hebrew), Thayer, Abbott-Smith, LSJ, as rich text (GW-13), each with its source and license.
- **Compare** (C03): two to four lexicon entries side by side (`SW_SPLITTER` pairs).
- **Bible Dictionaries** (D03): Easton, Smith, ISBE (1915), Hitchcock articles for the selected English word or topic (`SW_LIST` of matching articles, rich text body).
- Buttons: **Search this word** (lemma search), **Word Study** (P08), **Word's Journey** (P08), **Graph by book** (P07).

**Empty:** "Click a word in the Bible text to see it here."

### 5.6 P06 Notes (E01, E03-E07, E09)

`SW_TABS`: **Verse notes** | **Journal** | **Tags** | **Highlights** | **Prayer** | **Memory**.

- **Verse notes** (E03): notes on the current chapter in an `SW_PARAGRAPH_LIST` (one paragraph per note, edited in place), gutter showing the verse. The note editor needs headings, lists, verse links and images (**GW-13**). Spell check comes from `SW_TEXT_BOX` (Windows ISpellChecker via `SW_SPELLER`), so E09's spell check is present in v1; the thesaurus waits (v2).
- **Journal** (E04): `SW_TREE` of notebooks and topical notes, editor beside it (`SW_SPLITTER`).
- **Tags** (E05): `SW_LIST` of the user's tags with counts (`SW_BADGE`); selecting a tag lists its verses.
- **Highlights** (E01): `SW_MARK_LEGEND_VIEW` (one row per highlight color with a live swatch and the user's label); clicking a row lists the verses carrying it.
- **Prayer** (E06): `SW_LIST` with check boxes and dates.
- **Memory** (E07): due cards (`SW_CARD`) with Reveal and "Got it / Again" buttons; spaced repetition scheduled by the engine.

All writes go to `user.db` through the user-store processor (design notes §5).

### 5.7 P07 Search Results (B01-B05, B08, B10)

- **Query bar:** `SW_TEXT_BOX` with the query syntax: words, "exact phrases", `AND` / `OR` / `NOT`, `/regex/` (B02), `lemma:` and `strongs:H1254` (B03), `morph:V-AAI-3S` (B05). A **Builder...** button opens the Search Builder (D02). **Scope** (`SW_SELECT`): this version, all Bibles, the whole library (B04), current book, a collection (E11).
- **Summary strip:** hits, verses, books (`SW_STATISTIC` x3) and a **Show method** link (FR-032).
- **Results:** `SW_TABS` **List** | **Graph**.
  - **List:** `SW_DATA_GRID` (Reference | Text with the hit marked | Version | provenance), sortable, paged as results stream in. Double-click navigates the target link set. A KWIC (key word in context) toggle aligns hits in one column.
  - **Graph** (B10): `SW_BAR_CHART` of hits per book normalized per 1,000 words, and `SW_HEATMAP` of book x chapter.
- **Inline search** (B08) is the `Ctrl+F` find bar in each reading pane, not this panel.

**States:** Loading shows the first page as soon as it arrives (no blank wait). **Zero results** is an empty state that says what was searched and offers "Search all Bibles" or "Search by lemma instead". Invalid syntax marks the query box and names the problem at the character where it occurs.

### 5.8 P08 Guides (D09, C06, C07, I-P06, I-P07)

A guide is a page the **engine assembles**: every section is an engine result with its provenance, and the GUI only lays the sections out.

**Widgets:** guide kind `SW_SELECT` (Passage Guide, Word Study, They Chose, Word's Journey; Exegetical Guide and Topic Guide in v2); subject label; `SW_ACCORDION` (multi-open) of sections; each section body is built lazily and shows a skeleton until its result arrives; each section ends with its sources line and **Show method**.

**Sections without data are not listed.** A v1 guide never shows a "coming in v2" teaser; it lists what the shipped data can answer.

| Guide | v1 sections | Added in v2 |
|---|---|---|
| **Passage Guide** (D09) | Text in your versions; cross-references; commentary snippets; related passages (AI-made, labeled); quotations (this verse quotes or is quoted); rare words in the passage (C12); verse analysis (C13); your notes and highlights; author-library documents citing the passage, each with its status label | People and places (D08), atlas (D06), timeline (D07), topics (D10) |
| **Word Study** (C06) | Range before ruling (I-P09); counts and graph by book; lexicon entries; renderings in tagged versions (KJV with Strong's, BSB through the MACULA gloss mapping); Word's Journey summary; divine-name note when the lemma is one | Senses (C08), Septuagint-translation section, root family, clause participants |
| **They Chose** (I-P06, FR-030) | NT, LXX (Swete) and MT side by side, tokens marked by agreement, with the computed verdict line | Full NT-Use-of-OT browser over UBS Parallel Passages (D15): citation, quotation, allusion, echo |
| **Word's Journey** (I-P07) | Witnesses in time order: MT → LXX → NT → Vulgate → Wycliffe → Tyndale → KJV → BSB, each with its renderings and counts | Word-level alignment for untagged versions |
| **Exegetical Guide** (C07) | - | Per-word grammar, variants (C11), clause outline (C09) |

**They Chose, in detail.** Three `SW_PARALLEL_TEXT` columns (GW-06): NT | LXX (Swete) | MT (WLC). Tokens are marked by agreement class through an `SW_MARK_LEGEND` with text labels, never color alone: "agrees with LXX", "agrees with MT", "agrees with both", "neither". The verdict line is computed by the engine from the precomputed alignment tables (FR-042), for example: "Heb 8:8-12 agrees with the Septuagint (LXX Jer 38:31-34) against the Hebrew (MT Jer 31:31-34)" (FR-030's acceptance case). An edition note says the verdict was computed against Swete and may differ for Rahlfs (D-011). v1 covers the quotations in the seeded index; the full browser is v2 (09 places D15 in v2; 10 places I-P06 in v1; this split honors both).

**Word's Journey, in detail.** `SW_DATA_GRID` rows in chronological order: Witness | Date | Rendering(s) | Count | Method. The method column is a chip: **tagged** (lemma or Strong's tags), **verse co-occurrence** (in verses where the lemma occurs, how often each candidate rendering appears; labeled as such, not word alignment), or **NO_DATA**. Example: ἐκκλησία *ekklēsia* ("assembly") → "congregation" in Tyndale → "church" in the KJV (the example in 10-INNOVATIONS, I-P07). A small `SW_BAR_CHART` shows each witness's share of its top rendering.

### 5.9 P09 Census and Checks (I-P02, I-P03, FR-025-FR-028; Claim Check v1.5)

- **Definition card** (`SW_CARD`, read-only once run): Question, Corpus, Criteria, Controls, Holds if, Fails if, Definition version. A census definition is stored before the run and can only be versioned after it (FR-025).
- **Four-bucket strip:** four `SW_STATISTIC` tiles, **FITS**, **PARTIAL**, **FAILS**, **NO_DATA**, always shown together, in that order, with counts. The list below can be filtered to one bucket; **the strip cannot be filtered** (FR-026). NO_DATA is explained as "the tagging is silent here; this is not evidence of absence" (FR-027).
- **Controls chart** (I-P02): target against frequency-matched control words as grouped bars; this needs **GW-10** (grouped multi-series bars). A one-line verdict from the engine: "beats its controls" / "within the range of its controls".
- **Results grid:** `SW_DATA_GRID` (Bucket | Reference | Text | Why | Near miss) with the bucket as a labeled chip.
- **Shapes:** a list of named structural patterns (tiers T1 and T2; T3 rows are never returned as evidence, FR-028) that run into the same four buckets.
- **Claim Check results (v1.5, I-P01):** each extracted claim as a row with SUPPORTED / CONTRADICTED / PARTLY / CAN'T BE CHECKED and its evidence; the engine checks, AI never judges.
- Buttons: **Show method** (re-runs to the same number, FR-032), **Re-run as new version**, **Export report** (D06).

### 5.10 P10 Author Library (rix.db, D-019)

- **Search box** (`SW_TEXT_BOX`) over `docs_fts`; **status filter** chips; **"Citing this passage"** list that follows link set A through `verse_refs`.
- **Status travels with every document and is always visible** (D-019): an `SW_CHIP` with the word, never color alone.

| Status | Chip | Treatment |
|---|---|---|
| framework | FRAMEWORK (accent) | Normal |
| verdict | VERDICT (success) | Normal; the verdict's confidence shown where the document states one |
| draft | DRAFT (neutral) | Banner: "Draft: not a settled position" |
| unmarked | UNMARKED (muted) | Normal |
| withdrawn | WITHDRAWN (danger) | Banner on open: "Withdrawn by the author. Kept for the record; not authority." Listed after current documents; included in search only when "Include withdrawn" is on, and labeled in results |
| ungated | UNGATED (warning) | Banner: "Not reviewed (ungated). Read as a working note." |

- **Reader:** rich text view (GW-13) with title, author line ("Larry Rix, author library"), date, status banner (`SW_CARD` stripe) and the verses it cites (clickable).
- Nothing from rix.db ever appears inside an engine fact or a guide section without its status chip.

### 5.11 P11 Navigator (E02, E08, E11, D16)

`SW_TABS`: **Books** | **Bookmarks** | **History** | **Plans** | **Collections**.

- **Books:** `SW_TREE` of books → chapters, canon order of the current version (LXX order and additional books when an LXX version is active). A **Books Explorer** view (D16) is an `SW_DATA_GRID` of books with genre, author (from a small sourced table), chapters, verses and word counts.
- **Bookmarks / History** (E02): `SW_LIST`s; History is also the Back/Forward stack.
- **Plans** (E08): `SW_CALENDAR` with today's reading, `SW_PROGRESS` for the plan, plan editor in a sheet.
- **Collections** (E11): named subsets of the library used as search scopes.

### 5.12 P12 Study Ledger (v1.5, I-P12, I-P16)

`SW_DATA_GRID` log of every query, count and finding in the session (Time | Action | Query | Version | Result | Ruling). **Replay** re-runs an entry as it was; **Re-run on current data** shows what changed. **My ruling** records the user's own conclusion (I-P16: the human rules). Export to a file (D06).

### 5.13 P13 World Timeline (v2, 11-HISTORY-TIMELINE)

- **Lanes:** zoomable parallel lanes (time left to right, lanes top to bottom, grouped and collapsible: Bible world core on by default; Church; Asia; Africa; Americas before the US; Europe after Rome; themes). Lanes are data rows, not code. That widget is **GW-17 (`SW_LANE_TIMELINE`)**; `SW_TIMELINE` is a vertical event rail and `SW_GANTT` a day axis, neither of which carries lanes, BC years or certainty patterns.
- **Certainty classes A-G are drawn with patterns and labels, never color alone** (solid tick, solid bar, bar with scheme badge, gradient, soft band, dashed bar "per the text", hatched "tradition" band). Patterns need **GW-18** (painter dashes, hatches, gradients).
- **Disputes are drawn, not hidden:** a disputed event draws every position, stacked inside the dispute's envelope. Larry's lean, where shown, carries "Larry's lean", its confidence and wording, and is never pre-selected (11 §11 decision 3, pending).
- **Synchronism slice:** pick a year, range or verse; a vertical cursor lists every visible lane at that moment, each item with its own certainty pattern. From a verse: **Narrated time** and **Composition time** are separate choices.
- **Event drawer** (`SW_DRAWER`): title and summary, original date expression ("in the fifteenth year of Tiberius"), sources by grade (P1/P2/P3), who said what, verses (open in P01), disputes.
- Era labels BC/AD by default with a BCE/CE setting; no year zero is ever displayed.

### 5.14 P14 Atlas (v2, D06)

`SW_MAP` with markers for places in the passage; regional detail for the Levant and the Mediterranean, routes and place labels need **GW-19**.

### 5.15 Word hover card and pinned word card

A popover anchored at the word (`SW_WINDOW.show_popover` hosting an `SW_COLUMN`): script, transliteration, pronunciation, gloss, lemma, Strong's, morphology in English, uses in the Bible, provenance chip; buttons **Word Study**, **Search**, **Journey**, **Pin**. Hover opening (dwell, stays open while the pointer is over it, shaped text) is **GW-09**; click opening works with `show_popover` as it stands.

## 6. Dialogs and sheets

All are drawn (`SW_DIALOG` for alerts, `SW_WINDOW.show_sheet` for forms, `SW_FILE_DIALOG` for files). Escape cancels; Enter accepts when the form is valid.

| ID | Dialog | Opens from | Widgets | Validation | Release |
|---|---|---|---|---|---|
| D01 | **Go to Reference** | `Ctrl+G`, reference box | `SW_COMBO` with recent references; book / chapter / verse pickers (three `SW_LIST`s); versification indicator | Parser result: valid, ambiguous (candidate list), or invalid (message at the faulty part) | v1 |
| D02 | **Search Builder** | Search > Builder, `Ctrl+Shift+F` | Mode `SW_SEGMENTED` (Basic, Boolean, Lemma / Strong's, Morphology, Shape); `SW_QUERY_BUILDER` (nested groups, NOT, proximity: **GW-12**); scope; diacritic- and final-form-insensitive by default (D-009); live count preview; "Write the question first" (I-P13, v1.5) | Each clause complete; lemma and morphology codes resolve in the engine; regex compiles | v1 (pre-registration option v1.5) |
| D03 | **Census Builder** | Study > New Census, `Ctrl+Shift+K` | Question, corpus, criteria (query builder), controls (auto frequency-matched list, editable), Holds if, Fails if; Save; Run | All fields filled; at least one control; "Fails if" stated | v1 |
| D04 | **Claim Check** | Tools > Claim Check | Paste box (`SW_TEXT_BOX`, multiline); detected claims (`SW_DATA_GRID`, editable kind); Check | Text present; at least one claim | v1.5 |
| D05 | **Settings** | `Tools > Settings` (`Ctrl+Shift+O`) | `SW_TABS`: Appearance, Languages, Texts, Sync, Data, Privacy, Keyboard, About and Credits | Values in range; a theme change keeps WCAG contrast (`SW_THEME` invariant) | v1 |
| D06 | **Export / Copy** | `Ctrl+Shift+C`, `Ctrl+E` | What (verses, notes, results, census report, guide); format (plain text, Markdown, CSV); reference style; attribution (automatic); share-alike notice when Swete text is included; **verification flags** and "strip unchecked items" (I-P05, v1.5); preview; Copy / Save | Something selected; target writable | v1 (flags v1.5) |
| D07 | **Layouts** | Window > Layouts | Presets Simple and Study; Reset; Save current as... and the saved list (A09, v2) | Name unique | v1 presets; v2 named |
| D08 | **Database problem** | Startup | What is wrong; Retry; Locate...; Exit | - | v1 |
| D09 | **Show method** | Any number | Query, corpus, version, counts, provenance, Re-run | - | v1 |
| D10 | **Ambiguous reference** | Parser | Candidate `SW_LIST` ("Ju 1" → Judges 1 or Jude 1; "Ph 1" → Philippians 1 or Philemon 1) | One chosen | v1 |

## 7. Keyboard

| Keys | Action | Notes |
|---|---|---|
| `Ctrl+G` | Go to reference (focus the reference box) | |
| `Alt+Left` / `Alt+Right` | Back / forward | |
| `Ctrl+PageUp` / `Ctrl+PageDown` | Previous / next chapter | |
| `Ctrl+M` | Switch Simple / Study | |
| `Ctrl+L` | Cycle the focused panel's link set | Study mode |
| `Ctrl+F` | Find in this pane | |
| `Ctrl+Shift+F` | Search Builder | |
| `Ctrl+Shift+K` | New census | |
| `Ctrl+Shift+W` | Word Study for the selected word | |
| `Ctrl+Shift+G` | Passage Guide | |
| `Ctrl+Shift+J` | Word's Journey | |
| `Ctrl+Shift+Q` | They Chose (quotation comparer) | |
| `Ctrl+Shift+D` | Divine-name view on/off | |
| `Ctrl+Shift+P` | Hebrew pointing: full → vowels → consonants | |
| `Ctrl+I` | Interlinear tab | |
| `Ctrl+B` | Bookmark the verse | |
| `Ctrl+Shift+H` | Highlight with the last color | |
| `Ctrl+N` | New note on the verse | |
| `Ctrl+C` | Copy the selected verse with its reference | |
| `Ctrl+Shift+C` / `Ctrl+E` | Copy with format / Export | |
| `Ctrl+T` / `Ctrl+W` | New Bible tab / close tab | Closable tabs need GW-15 (v1.5); v1 closes from the tab menu |
| `Ctrl+=` / `Ctrl+-` / `Ctrl+0` | Text larger / smaller / reset | |
| `Ctrl+Shift+O` | Settings | |
| `F1`, `F3`, `F6`, `Ctrl+1`..`Ctrl+9` | Help, next match, next panel, Bible tab n | **GW-24:** simple_shell's key-down filter forwards stepping keys and Alt+letter/digit only, and the accelerator table requires a modifier, so function keys and Ctrl+digit do not reach the window today |
| `Esc` | Close popover, drawer, sheet; cancel the running job when the status bar has focus | |
| Alt+letter | Menu mnemonics | Works today (`set_menu_bar`) |

Every command is also on a menu, so no feature depends on a shortcut.

## 8. Search

| Kind | How it is asked | Engine | Release |
|---|---|---|---|
| Basic words and phrases | Quick search box; P07 query bar | FTS5 over normalized columns (D-009) | v1 |
| Boolean | `AND`, `OR`, `NOT`, parentheses; Builder | FTS5 | v1 |
| Regular expression | `/.../` | Engine REGEXP | v1 |
| Lemma / Strong's | `lemma:`, `strongs:`; "Search this word" | Concordance by key, never by display string (FR-023, FR-024) | v1 |
| Morphology | `morph:`; Builder's Morphology mode with code pickers | MACULA Greek, OSHB | v1 |
| Census with controls | Census Builder (D03) | Census engine: four buckets, controls, stored definition | v1 |
| Shape queries | P09 Shapes list | Shape engine (named shapes, T1/T2) | v1 (user-made shapes, I-P14, v2) |
| Meaning (smart) search | P07 "Meaning" mode | Run-time query embedding | v2 (D-016: Release 1.1/2) |
| Clause / syntax | Builder modes | MACULA trees | v2 / v3 |

**Normalization the user never has to think about:** Hebrew is searched consonantally with final forms folded and marks removed; Greek with marks removed, lowercased, final sigma folded (D-009). Display always comes from the exact text, never from the normalized copy.

## 9. Innovations placed per release

| ID | Innovation | Where | Release |
|---|---|---|---|
| I-P03 | FAILS always shown | P09 four-bucket strip; every census and shape result | v1 |
| I-P02 | Built-in frequency-matched controls | D03, P09 controls chart (GW-10) | v1 |
| I-P06 | Quotation comparer, "They chose" | P08 They Chose | v1 (indexed quotations); v2 full browser |
| I-P07 | A word's journey | P08 Word's Journey | v1 |
| I-P08 | Divine-name view | P01 / P02 overlay | v1 |
| I-P09 | Range before ruling | P05 Word tab; P08 Word Study | v1 (renderings); v2 (senses) |
| I-P01 | Claim Check | D04, P09 | v1.5 |
| I-P05 | Share-safe export | D06 flags, strip unchecked | v1.5 |
| I-P12 | Study ledger | P12 | v1.5 |
| I-P13 | Write the question down first | D02 option (census pre-registers already in v1, FR-025) | v1.5 |
| I-P16 | The human adjudicates | AI is never a source (all releases); "My ruling" in P12 (v1.5); "Argue the other side" (v2) | v1 / v1.5 / v2 |
| I-P10, I-P11, I-P14, I-P17, I-P04, I-P15 | Writing pane, grounded drafting, pattern builder, reply kit, leading-question warning, preflight | Notes editor, P09, D04 | v2 |

## 10. Provenance and AI labeling

- **Every fact carries a provenance chip** (`SW_CHIP`, mono): the source's short code (WLC, MACULA, SBLGNT, BSB, OB-XREF, TSK, SWETE ...). Its tooltip names source, edition, license and retrieval date, and the version caveat when there is one (FR-005). Clicking opens D09 Show method.
- **Every number has Show method** (FR-032).
- **AI-made data** (Release 1 ships precomputed related passages only, D-016) carries an **AI-made** chip with the method ("meaning neighbor, bge-m3, computed at build time") and never appears without it (NFR-014).
- **No AI runs on the user's machine in Release 1.** When the optional AI layer arrives (v2 or later; 09 places the AI rows in v3), its output is labeled "AI wording; the facts above are from the engine" and is post-checked (FR-052, FR-053).
- **Licenses with conditions are surfaced where they bind:** the Swete share-alike notice beside Copy and Export when Swete text is included (12-SEPTUAGINT A5); generated credits in Settings > About (FR-003).

## 11. Hebrew and Greek display rules

1. **Right to left, right-aligned.** Hebrew paragraphs, labels and cells read right to left (simple_shaping bidi) and align right with the verse gutter on the right. Alignment and per-item base direction are **GW-02**.
2. **Pointing and cantillation** are on by default and can be reduced (Full / Vowels / Consonants). Stacked marks, meteg and MapM's deliberate no-break space before paseq (FR-008) must render correctly; any defect found in the D-006 spike (Gen 1:1 WLC with cantillation, Gen 1:1 LXX Swete, John 1:1 WH, offscreen in `SW_LABEL` and `SW_TEXT_BOX`) is fixed in simple_shaping (**GW-03**).
3. **Fonts ship with the program.** The target user has no scholar fonts installed; simple_shaping's Hebrew fallback names SBL Hebrew and Ezra SIL. Loading bundled font files privately is **GW-01**. Font licenses are checked in the spec phase (D-006 implications).
4. **Never a bare "LXX".** "LXX (Swete)" in the public build, "LXX (Rahlfs, CCAT/CATSS)" in the private build, "Brenton 1851" for filler rows, with the OCR tooltip in §5.1.
5. **Transliteration and pronunciation on hover** for every Hebrew and Greek word (hover card); the transliteration scheme is a setting (academic or simple).
6. **First-use gloss convention:** wherever the GUI itself writes Hebrew or Greek into a heading or summary (guide titles, word headers, exports), the first occurrence on that page carries transliteration and an English gloss: בְּרִית *berit* (be-REET), "covenant". This is the engine's checks module applied to GUI-generated text (FR-031); exports run the same check.
7. **Bare script is never the only label of a control.** A toggle that shows Hebrew shows its English name beside it.

## 12. Theming

- `SW_THEME.make_light` and `make_dark`; the theme's own invariant computes contrast, so an unreadable combination is rejected where it is set. A **high-contrast** theme is built through `set_surfaces` / `set_semantics` under the same invariant; following the Windows high-contrast setting is GW-16 (v1.5).
- Highlights use `SW_MARK_PALETTE`, whose twelve hues are held by contract at wash under ink >= 4.5:1 and ink on surface >= 3:1 in both themes.
- **Meaning is never color alone:** buckets, statuses, agreement classes and certainty classes all carry words or badges (`SW_MARK_LEGEND.badge_of`, chips with text).
- **Two type scales:** the interface scale (`SW_THEME.set_text_scale`, 1.0-3.0) and the reading scale (Bible and library text, 14-40 px), so large-print readers can enlarge the text without enlarging the chrome, or both.

## 13. Accessibility

- **Full keyboard use** (NFR-013): Tab ring through every panel (`focus_next`), `F6` panel cycling (GW-24), arrow navigation in lists, trees and grids, Escape to close; every command on a menu.
- **Large print:** reading scale up to 40 px; controls never smaller than their font (`SW_PAINTER.min_control_height`); margins scale with text.
- **Visible focus** on every focusable widget.
- **Screen readers:** a drawn toolkit exposes nothing to UI Automation today. An accessibility bridge (names, roles, values, focus events) is **GW-14**, priority v1.5.
- **Reduced motion:** skeleton shimmer and toast motion off on request (GW-14 carries the theme flag).

## 14. Performance targets (CPU only, 8-16 GB, 4-core DDR4 laptop, SSD)

| Measure | Target | Source |
|---|---|---|
| Cold start to the first verse | 3 s or less (warm: 1.5 s) | proposed |
| Reference change to active Bible pane rendered | under 200 ms | NFR-001 |
| All visible linked panels refreshed | under 400 ms; hidden panels deferred | proposed |
| Hover card after dwell | under 100 ms | proposed |
| Scrolling a chapter | no dropped frames at 60 Hz; only the visible band painted | `SW_PARAGRAPH_LIST`, `SW_LIST` virtualization |
| Search: first page / whole canon | under 500 ms / under 2 s | NFR-002 |
| Census with controls | under 10 s, with progress and Cancel | NFR-002 |
| Guide: first section / all v1 sections | under 300 ms / under 2 s | proposed |
| Window resize | re-layout once at resize end | simple_widgets R10 |
| Working set, core edition | under 1 GB | NFR-003 |

Long work never runs on the GUI processor (SCOOP, design notes §5). `SW_WINDOW.on_tick` is a fixed 250 ms heartbeat, too coarse to stream a search's first page within 500 ms or to show a finished job promptly (short lookups are synchronous separate queries and do not wait on it); a cross-processor wake and a settable interval are **GW-26**.

## 15. App-level state machine (summary)

Three orthogonal regions (full definition in `spec_windows.json` and `spec_windows_state_diagram.txt`):

- **A. Lifecycle and activity:** `starting → checking_databases → (database_error | restoring_session) → ready`, and from `ready`: `navigating` (with `choosing_reference` for ambiguous input), `searching`, `building_guide`, `census_defining → census_running`, `claim_checking` (v1.5), `settings_open`, `exporting`, `error_recoverable`, and `exiting` (final). One job of each kind at a time; a new navigation cancels an older one.
- **B. Mode and layout:** `mode_simple ⇄ layout_applying ⇄ mode_study`, plus `layout_saving`. A failed snapshot falls back to the Simple preset and says so.
- **C. Panel sync (one instance per panel):** `panel_current`, `panel_stale`, `panel_refreshing`, `panel_unlinked`.

## 16. Release mapping

| Release | GUI scope |
|---|---|
| **v1 (Release 1, core only)** | Main window, menus, toolbar, status bar; Simple and Study presets; session restore; dark, light, high contrast; two text scales; P01-P11; D01-D03, D05-D10; divine-name view; They Chose (indexed quotations); Word's Journey; range before ruling (renderings); census with controls and the four buckets; named shapes; provenance chips and Show method everywhere; AI-made related passages with their label (D-016); author library with status labels (D-019); Swete labeling |
| **v1.5** | P12 Study Ledger; D04 Claim Check; share-safe export flags (I-P05); pre-registered questions for any search (I-P13); "My ruling"; accessibility bridge (GW-14); closable tabs (GW-15); image export of a pane (GW-21) |
| **v2** | P13 World Timeline; P14 Atlas; Exegetical Guide; full Word Study (senses, LXX section); reverse interlinear; variants; clause search and views; full NT-Use-of-OT browser; meaning search; Passage Guide's people, places, topics; Topic Guide; Bible Browser; visual filters; Gospel harmony; audio; printing; named layouts; localization; module manager; workflows; citation tool; sermon manager and markers; preaching mode; Visual Copy; I-P10/11/14/17/04/15; "Argue the other side" |
| **v3** | Syntax search; sentence diagramming; Theology Guide; Sermon Builder; the optional AI layer (G01-G06) |
| **Never (BLOCKED, 09 §6)** | Licensed translations, BDAG/HALOT, licensed commentaries, proprietary datasets, Mobile Ed, Counseling Guide |

Two choices here go beyond 09 and are flagged: E09 spell check is v1 because `SW_TEXT_BOX` already provides it (09 lists E09 without placing it in v1); and the guide frames ship in v1 with the sections v1 data can fill (09 lists D09 and C06 as v2), so the full guides remain v2 as 09 says. Five features that 09 does not place in any release list (D04, E14, F05, F06, H03) carry proposed releases in the README's traceability table, marked "proposed".
