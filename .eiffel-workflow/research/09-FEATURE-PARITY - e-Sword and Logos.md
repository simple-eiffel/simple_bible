# 09 FEATURE PARITY: e-Sword and Logos vs. simple_bible

*2026-10-06. Research for `simple_bible`. Question: How many e-Sword and Logos features can simple_bible bring in comfortably, so that someone might choose simple_bible for free? Every product claim cites a URL in the References section. Data licenses were checked at the source on 2026-10-06. Fit is judged by whether simple_bible CAN do the feature (data, licensing, CPU), not by how heavy the work is (Larry's direction, 2026-10-06). Effort is information only.*

---

## 1. Bottom line

- **e-Sword parity: 42 of 45 features (93%)** reachable (COMFORTABLE + FEASIBLE + FEASIBLE-HEAVY). The 3 BLOCKED e-Sword features are all licensed content (modern translations, modern commentaries, dramatized audio), not tools.
- **Logos parity: 66 of 72 features (92%)** reachable. The 6 BLOCKED Logos features are licensed content and services: BDAG/HALOT, modern translations and commentaries, Lexham/Logos proprietary datasets, Mobile Ed courses, and the Counseling Guide.
- **COMFORTABLE alone:** e-Sword 27 of 45 (60%); Logos 22 of 72 (31%). e-Sword is mostly a reader with personal tools, which the planned engine already covers; Logos's weight sits in guides, original-language tools and AI, which are FEASIBLE or FEASIBLE-HEAVY with open data.
- **The tools are reachable; much of the content is not.** Where Logos wins, it usually wins on licensed books, not on software. A free tool can match the software and must substitute public-domain and openly licensed content for the rest.
- **Why choose simple_bible over free e-Sword:** e-Sword reads and searches. It has no morphology or syntax search, interlinear, clause tools, sense lexicon, textual variants or Septuagint-vs-Hebrew comparison in the sources reviewed. simple_bible adds the Logos-class original-language layer from open data, plus things neither product has: counts with controls, FITS/PARTIAL/FAILS/NO_DATA with near-misses, quotation agreement verdicts, and provenance on every fact.

## 2. Products as of 2026-10-06

### e-Sword (Rick Meyers)

- **Current version:** Windows 15.2.0, updated 08-14-2026 [E2]. Version 15.0 (July 2026) redesigned the interface, added Super Search, the Views selector, whole-verse highlighting and verse tagging, and made user files compatible across platforms [E3][E4].
- **Platforms:** Windows; e-Sword X (Mac); e-Sword HD (iPad); e-Sword LT (iPhone); Android [E1]. The official pages reviewed do not state mobile prices.
- **Price model:** The program is free ("It is absolutely free!") and funded by donations from "less than 1%" of users [E1][E12]. The basic install includes the KJV, KJV with Strong's numbers, Strong's dictionaries, Smith's Bible Dictionary, F. B. Meyer's *Through the Bible Day by Day*, the Treasury of Scripture Knowledge and Spurgeon's *Morning & Evening* [E2]. Free add-ons come through the Download menu; premium modules need a product key [E5]. Paid modern translations and commentaries are typically $10-30 each (NIV bundle $24.99) [E14][E18][E19]. The ESV is free to users because the developer pays the license [E17].
- **Module ecosystem:** Free and public-domain books (classic commentaries, dictionaries, TSK), licensed premium modules (NKJV, NASB, NIV, Believer's Bible Commentary, Vine's) [E2][E18], and a third-party module community [E15][E16].

### Logos Bible Software (Faithlife)

- **Model:** Subscription platform since October 2024, updated about every six weeks; Windows, macOS, iOS, iPadOS, Android and web [L3]. Current releases are numbered by month (v52 July 2026, v53 August 2026) [L32][L33].
- **Plans:** Free (25+ resources, simple tools) [L6]; Premium $9.99/mo or $99.99/yr; Pro $14.99/mo or $149.99/yr; Max $19.99/mo or $199.99/yr (verified July 31, 2026) [L7]. Original-language tools rise by tier: Premium works through English only; Pro adds intermediate morphology tools; Max adds advanced grammar, syntax, Latin and Syriac [L8]. Sources disagree on which plan carries some features [L2][L5]; this study records the tier only where a source states it.
- **Library packages are separate from the subscription.** Package pages fetched 2026-10-06 showed the 2026 Bronze Library at $89.99 and the 2026 Gold Library at $849.99; the price shown depends on what the account already owns [L49][L22][L51]. BDAG and HALOT are sold separately [L46][L47][L48].
- **AI today:** Study Assistant (chat Q&A over your library, with follow-ups; Explain and Ask on a selection), Smart Search, Search Results Synopsis with footnotes, Summarize, Questions to Ask, Sermon Assistant, Auto-translation, Insights sidebar [L1][L2][L4][L32][L33][L38]. AI use draws on monthly credits that do not roll over [L4][L50]. Logos says its AI draws from the user's library, and that users can restrict it to a Collection to keep within their tradition [L3][L4].

## 3. Fit classes

| Class | Meaning |
|---|---|
| **COMFORTABLE** | The data and engine pieces exist (in bible.db, shape.db or the design) or are straightforward. |
| **FEASIBLE** | Real work, or needs openly licensed substitute data that has been located and checked. |
| **FEASIBLE-HEAVY** | Large build, or slow on a CPU, but nothing in data, licensing or hardware forbids it. Still in scope. |
| **BLOCKED** | Depends on copyrighted content or a service a free tool cannot ship. The content is named. |

Columns: **e-Sword / Logos** show whether the product has the feature in the sources reviewed (blank = not found, which is not proof of absence). **Effort** S/M/L is information only. **CPU** = runs on a CPU-only 8-16 GB machine.

## 4. Feature table

### A. Reading, layout and platform

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| A01 | Bible reader with many versions | Read any shipped text quickly, offline | Y | Y (Free) | **COMFORTABLE** | BSB (CC0), KJV, ASV, YLT, WLC, SBLGNT, WH, Vulgate, Tyndale and the rest of design §7 | S | Y | [E1], [E2], [L6] |
| A02 | Parallel Bible (versions side by side, scrolling together) | Read two or more versions in step | Y | Y | **COMFORTABLE** | Verse hub + versification map (TVTMS, CC BY 4.0) so verses pair correctly | S | Y | [E1], [E9], [L28] |
| A03 | Compare mode (one verse in every version) | See all renderings of a verse at once | Y | Y | **COMFORTABLE** | Verse hub; already in `bible_repl` | S | Y | [E1], [E6], [L28] |
| A04 | Word-level difference highlighting between versions (Text Comparison) | Spot exactly where two versions differ | - | Y | **COMFORTABLE** | Token diff (longest common subsequence) over the shipped texts | S | Y | [L29] |
| A05 | Gospel harmony | Read parallel Gospel accounts together | Y | - | **FEASIBLE** | UBS Paratext Parallel Passages (CC BY-SA 4.0) for the pairings; Eusebian canons (ancient, public domain) as a second scheme | M | Y | [E13], [E9], [D4] |
| A06 | Tooltips for Strong's numbers and Scripture references | Hover to see a definition or a verse without leaving the page | Y | - | **COMFORTABLE** | word_strongs + Strong's dictionaries; verse hub | S | Y | [E1], [E6] |
| A07 | Power Lookup (expand every reference on the visible page) | Read cited verses in place while reading a book | - | Y | **COMFORTABLE** | Reference detector (vault `scripture_detect.py` logic) + verse hub | S | Y | [L37] |
| A08 | Docked study panels (cross-references, tagged verses, history) | Keep the study aids beside the text | Y (v15) | - | **COMFORTABLE** | WebView2 panes over the engine | S | Y | [E3] |
| A09 | Saved layouts (Views selector) | Switch between workspaces in one click | Y (v15) | - | **FEASIBLE** | Layout presets stored in the user database | S | Y | [E3] |
| A10 | Dark mode and themes | Comfortable reading at night | Y (v12) | - | **COMFORTABLE** | CSS themes in the WebView2 face | S | Y | [E4] |
| A11 | Localized interface | Use the program in another language | Y | - | **FEASIBLE** | String tables; Hebrew/Greek data are language-neutral | M | Y | [E13], [E7] |
| A12 | Audio Bible | Listen to Scripture | Y (v13, dramatized) | Y (reading-plan audio) | **FEASIBLE** | LibriVox KJV complete (public domain); BSB narration reported CC0 by a third party (verify with berean.bible before shipping); licensed dramatized audio is row H07 | M | Y | [E4], [E5], [L33], [D16], [D17] |
| A13 | Printing (WYSIWYG) | Print a passage, notes or a study sheet as shown | Y | - | **FEASIBLE** | WebView2 print and print-to-PDF | S | Y | [E1] |
| A14 | Mobile apps | Study on a phone or tablet | Y (Android, iPhone, iPad, Mac) | Y (iOS, Android) | **FEASIBLE-HEAVY** | `D:\prod\bible_pwa` (SQLite in the browser via sql.js) as the starting point; a large download on phones | L | Y | [E1], [E9], [E10], [E11], [L3] |
| A15 | Web app (no install) | Use it on any computer | - | Y (app.logos.com) | **FEASIBLE** | The same PWA, hosted as static files; no server-side logic needed | M | Y | [L3], [L36] |
| A16 | Sync of notes, highlights and plans across devices | Pick up on another device where you left off | Y (v14/v15 shared user files) | Y (cloud sync) | **FEASIBLE-HEAVY** | No server: a portable user database in a folder the user already syncs (OneDrive, Dropbox), merged by row timestamps | L | Y | [E3], [E4], [L36] |

### B. Search

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| B01 | Word and phrase search with Boolean options | Find every verse with these words | Y | Y | **COMFORTABLE** | SQLite FTS5 (planned in design §8) | S | Y | [E6], [E7], [L9] |
| B02 | Regular-expression search | Find spelling patterns and partial words | Y (Android) | - | **COMFORTABLE** | REGEXP function registered in the engine | S | Y | [E7] |
| B03 | Strong's number / lemma search | Find every place an original word is used, without typing Greek or Hebrew | Y (v15) | Y | **COMFORTABLE** | word_strongs, MACULA lemma columns; final-form-safe Hebrew, diacritic-safe Greek (design L1) | S | Y | [E3], [E11], [L15] |
| B04 | Library-wide search (Super Search / All Search) | One query across Bibles, commentaries and books | Y (v15) | Y | **COMFORTABLE** | FTS5 over every shipped book table | S | Y | [E3], [L9] |
| B05 | Morphological search | Find, for example, every aorist passive of a verb | - | Y (Pro, Max) | **COMFORTABLE** | MACULA Greek morphology (CC BY 4.0) and OSHB morphology (CC BY 4.0), already in bible.db | M | Y | [L9], [L12], [L5], [D1], [D2] |
| B06 | Syntax search (query the syntax trees) | Find grammatical constructions, not just words | - | Y (Max) | **FEASIBLE-HEAVY** | MACULA Greek and Hebrew syntax trees (CC BY 4.0); needs a tree-query engine and a form-based query builder | L | Y | [L11], [L5], [D1], [D2] |
| B07 | Clause search (who does what to whom) | Find a word acting as subject, object, and so on | - | Y | **FEASIBLE** | MACULA semantic roles, frames and participant referents (CC BY 4.0) | M | Y | [L10], [D1], [D2] |
| B08 | Inline search (search inside the open book) | Search the text you are reading without leaving it | - | Y | **COMFORTABLE** | FTS5 scoped to one resource | S | Y | [L19] |
| B09 | Smart Search (natural-language and meaning-based search) | Ask in plain words; find passages that match the idea even without the word | - | Y | **FEASIBLE** | bge-m3 (MIT) vectors precomputed at build time; query embedded on the CPU (design L2/L3) | M | Y | [L1], [L2], [L7] |
| B10 | Graph of search results by book | See where a word clusters | - | Y | **COMFORTABLE** | Engine counts per book, normalized per 1,000 words | S | Y | [L40] |
| B11 | Search by Factbook topic, person or place; map search | Search by entity rather than by spelling | - | Y | **FEASIBLE** | STEPBible TIPNR (CC BY 4.0), Theographic (CC BY-SA 4.0), Nave's (public domain) | M | Y | [L9], [D3], [D11], [D10] |
| B12 | Visual filters (color the text by lemma or morphology rule) | See a grammatical pattern light up in the text | - | Y | **FEASIBLE** | Morphology query rendered as an overlay in the WebView2 face | M | Y | [L30] |

### C. Original-language tools

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| C01 | Strong's Hebrew and Greek dictionaries | Quick definitions keyed to the KJV | Y (included) | - | **COMFORTABLE** | openscriptures/strongs XML (rights field: public domain; strip the 1980 Moody copyright line, which covers added material) | S | Y | [E2], [D8] |
| C02 | Fuller lexicons (BDB, Thayer, Abbott-Smith, LSJ) | Real lexicon entries, not just Strong's glosses | Y (Lexicon view; downloads) | Y (library) | **COMFORTABLE** | OSHB HebrewLexicon (BDB; files CC BY 4.0, BDB text public domain); STEPBible TBESH/TBESG/TFLSJ (CC BY 4.0); Thayer (CC0 on Zenodo); Abbott-Smith (CrossWire, public domain); Perseus lexica (CC BY-SA 4.0) | M | Y | [E6], [L15], [D7], [D3], [D12], [D9], [D5] |
| C03 | Lexicon compare | See several lexicons' entries for one word together | Y (Android) | - | **COMFORTABLE** | Join the C02 lexicons on the Strong's/lemma key | S | Y | [E7] |
| C04 | Interlinear (original text with gloss and parsing lines) | Follow the Hebrew or Greek word by word | - | Y | **COMFORTABLE** | MACULA glosses (Cherith CC BY 4.0; Berean Interlinear glosses, public domain since 2023-04-30) + morphology | S | Y | [L16], [D1], [D2] |
| C05 | Reverse interlinear (English with the original under it) | Start from English and see the word underneath | - | Y | **FEASIBLE** | Berean Interlinear word order (public domain) linked through MACULA's BSB gloss mapping; alignment table built once at build time | M | Y | [L16], [L17], [D1], [D16] |
| C06 | Bible Word Study guide | One page on a word: counts, translations, Septuagint equivalents, senses, root, uses | - | Y (full original-language sections Max) | **FEASIBLE** | Concordance counts; translation counts from the alignment; Septuagint equivalents (MACULA Hebrew); senses (UBS SDBH/SDGNT, CC BY-SA 4.0); clause participants (MACULA) | M | Y | [L15], [L5], [D2], [D4] |
| C07 | Exegetical Guide | One page on a passage's Greek or Hebrew: words, grammar, variants, clause structure | - | Y (Max) | **FEASIBLE** | Morphology, public-domain lexicons (C02), SBLGNT apparatus, UBS HOTTP notes, MACULA clause structure; the BDAG/HALOT parts are row H04 | M | Y | [L14], [L5], [D6], [D4] |
| C08 | Bible Sense Lexicon (word senses across lemmas) | See which words share a meaning, and which meaning a word has here | - | Y | **FEASIBLE** | UBS Dictionary of Biblical Hebrew and of the Greek NT (from SDBH/SDGNT, CC BY-SA 4.0); MACULA sense tags | M | Y | [L20], [D4], [D1], [D2] |
| C09 | Clause visualizations and clausal outlines | See the sentence's structure as an indented outline | - | Y (Lexham datasets) | **FEASIBLE** | MACULA lowfat trees (clause nesting), Greek and Hebrew | M | Y | [L14], [L25], [D1], [D2] |
| C10 | Sentence diagramming tool | Draw your own diagram of a verse | - | Y | **FEASIBLE-HEAVY** | A drawing editor in WebView2; can be seeded from the MACULA tree | L | Y | [L26] |
| C11 | Textual variants | See where manuscripts and printed editions differ | - | Y (Exegetical Guide) | **FEASIBLE** | SBLGNT apparatus (CC BY 4.0, `data/sblgntapp`); STEPBible TAGNT edition markers (CC BY 4.0); WH vs TR differences computed; UBS HOTTP for the Old Testament (CC BY-SA 4.0) | M | Y | [L14], [D6], [D3], [D4] |
| C12 | Lemma in Passage (the passage's words with their whole-Bible counts) | Spot which words in this passage are rare | - | Y (Max) | **COMFORTABLE** | Concordance filtered by passage | S | Y | [L15], [L5] |
| C13 | Verse Analysis Tool | (Listed by a secondary source; not described in the official pages reviewed. Most likely a word-by-word analysis of one verse.) | Y | - | **COMFORTABLE** | Word-by-word Strong's and morphology breakdown from word_strongs/MACULA | S | Y | [E13] |

### D. Reference library and guides

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| D01 | Public-domain commentaries (Matthew Henry, Gill, Barnes, JFB, Clarke, Wesley) | Classic verse-by-verse comment | Y | Y (library) | **COMFORTABLE** | CrossWire SWORD modules marked Public Domain (MHC, Barnes, JFB, Clarke, Wesley); Gill from CCEL or sacred-texts (CCEL terms: free for non-profit use) | M | Y | [E14], [L22], [D13], [D14] |
| D02 | Cross-references (Treasury of Scripture Knowledge) | Follow a verse to related verses | Y (TSK included) | - | **COMFORTABLE** | OpenBible.info cross-references (about 340,000, CC BY; already in bible.db); TSK (CrossWire, public domain) | S | Y | [E2], [D15], [D13] |
| D03 | Bible dictionaries (Smith, Easton, ISBE 1915, Hitchcock) | Background on people, places and terms | Y (Smith's included) | - | **COMFORTABLE** | CrossWire modules marked Public Domain | S | Y | [E2], [E14], [D13] |
| D04 | Reference library (Josephus, early church writers and other books) | Primary sources beside the Bible | Y (Reference Library) | Y (library) | **FEASIBLE** | Josephus/Whiston (CrossWire, public domain); ANF/NPNF (CCEL; free for non-profit use, CCEL's own introductions excluded) | M | Y | [E1], [L22], [D13], [D14] |
| D05 | Devotionals | A daily reading | Y (Spurgeon's Morning & Evening included) | - | **COMFORTABLE** | Spurgeon's Morning & Evening (public domain by date); Daily Light (CrossWire, public domain) | S | Y | [E2], [D13] |
| D06 | Maps and atlas | See where events happened | Y (Map/Graphic Viewer; location maps) | Y (Atlas) | **FEASIBLE** | OpenBible Bible Geocoding Data (CC BY 4.0); UBS MARBLE Bible Routes (CC BY-SA 4.0); Natural Earth base map (public domain), drawn offline | M | Y | [E13], [E10], [E8], [L21], [D10], [D4], [D18] |
| D07 | Timeline | See how people and events fit in history | - | Y | **FEASIBLE** | Theographic Bible Metadata periods and events (CC BY-SA 4.0); dates shown with their source, since many are contested | M | Y | [L23], [D11] |
| D08 | Factbook (pages on people, places, events, topics) | One page per biblical entity | - | Y | **FEASIBLE** | STEPBible TIPNR (CC BY 4.0; its prose descriptions were written by Claude 3, so label them as AI text or omit them); Theographic; Easton/Smith/ISBE | M | Y | [L24], [D3], [D11], [D13] |
| D09 | Passage Guide | Everything about a passage on one page | - | Y | **FEASIBLE** | Assembles D01-D08, cross-references and parallels per passage | M | Y | [L13] |
| D10 | Topic Guide | Verses and articles on a topic | - | Y | **FEASIBLE** | Nave's Topical Bible and Torrey's Topical Textbook (CrossWire, public domain) | M | Y | [L18], [D13] |
| D11 | Theology Guide | Reports on doctrines with passages and systematic theologies | - | Y | **FEASIBLE-HEAVY** | Public-domain systematic theologies (for example Gill's Body of Divinity on CCEL) plus a topic map that must be built by hand | L | Y | [L13], [D14] |
| D12 | Counseling Guide | Passages and resources for counseling topics | - | Y | **BLOCKED** | Depends on licensed counseling books and Logos's own topic data; Nave's gives passages only | - | - | [L41] |
| D13 | Sermon Starter Guide | Ideas, outlines and illustrations to begin a sermon | - | Y | **FEASIBLE-HEAVY** | Nave's topics plus public-domain sermons and illustration books (sources to be located and licensed per item) | L | Y | [L41] |
| D14 | Sermon illustrations | Stories and quotations for teaching | Y | - | **FEASIBLE-HEAVY** | Public-domain illustration collections (to be located and checked per item) | M | Y | [E13] |
| D15 | NT Use of the OT interactive (citation, quotation, allusion, echo) | See how the New Testament uses the Old | - | Y | **FEASIBLE** | UBS Paratext Parallel Passages (CC BY-SA 4.0), which includes OT quotations in the NT with exact and partial word matches | M | Y | [L1], [L42], [D4] |
| D16 | Bible Books Explorer (compare books by genre, author, length) | Overview of the canon | - | Y | **COMFORTABLE** | Computed from the text; genre and author fields from a small hand table with sources | S | Y | [L1] |
| D17 | Bible Browser (filter passages by people, places, topics, senses) | Discover passages by combining filters | - | Y | **FEASIBLE** | TIPNR, Nave's, SDBH/SDGNT domains joined on verse ids | M | Y | [L1], [D3], [D4] |
| D18 | Media tool and Visual Copy (verse slides and images) | Make a slide of a verse for teaching | - | Y | **FEASIBLE** | Render to image in WebView2; images from UBS MARBLE (each image keeps its own Creative Commons credit) | M | Y | [L27], [D4] |
| D19 | Popular Quotations | Quotes from teachers to drop into notes or sermons | - | Y (Pro) | **FEASIBLE-HEAVY** | Curate public-domain quotations with exact source; Logos's own collection cannot ship | L | Y | [L1], [L2] |

### E. Personal study tools

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| E01 | Highlighting (including whole-verse highlights shown in every translation) | Mark what matters and see it everywhere | Y (v15) | Y | **COMFORTABLE** | User database keyed to canonical verse ids through the versification map | S | Y | [E3], [E6], [L36] |
| E02 | Bookmarks and history | Return to where you were | Y | - | **COMFORTABLE** | User database | S | Y | [E6], [E7] |
| E03 | Study notes on verses, with a rich editor (images) | Keep your own comments beside the text | Y | Y | **COMFORTABLE** | User database + WebView2 editor | M | Y | [E1], [E9], [L36] |
| E04 | Topical notes, journal and notebooks | Notes not tied to a verse | Y | Y | **COMFORTABLE** | User database | S | Y | [E13], [L39] |
| E05 | Verse tagging with your own categories | Group verses by theme and filter by tag | Y (v15) | - | **COMFORTABLE** | User database | S | Y | [E3], [E6] |
| E06 | Prayer list | Keep prayer requests | Y | - | **COMFORTABLE** | User database | S | Y | [E13] |
| E07 | Scripture memory | Memorize verses with review scheduling | Y | - | **COMFORTABLE** | Spaced-repetition scheduler over user-picked verses | S | Y | [E13], [E7] |
| E08 | Reading plans (custom plans, progress, editing) | Read through the Bible or a book on a schedule | Y | Y | **COMFORTABLE** | Plan generator + progress table (phone reminders depend on A14) | S | Y | [E13], [E10], [L32], [L33], [L34] |
| E09 | Editor spell check and thesaurus | Write clean notes | Y | - | **FEASIBLE** | WebView2's built-in spell checking; an openly licensed thesaurus list (to be chosen and its license checked) | S | Y | [E13] |
| E10 | Copy verses in chosen formats | Paste Scripture into a document correctly formatted | Y | Y | **COMFORTABLE** | Verse hub + format templates; vault `scripture_block.py` logic | S | Y | [E6], [L31] |
| E11 | Collections (named subsets of the library) | Search or ask within books you trust | - | Y | **COMFORTABLE** | Saved filter over resource ids | S | Y | [L4] |
| E12 | Workflows (guided study steps saved to a notebook) | Be walked through a study method | - | Y | **FEASIBLE** | Step definitions as data; answers saved to the user database | M | Y | [L39] |
| E13 | Citation and bibliography tool | Cite sources correctly | - | Y | **FEASIBLE** | Generated from the provenance table (design §7) | S | Y | [L2] |
| E14 | Print-library catalog (scan your paper books) | Know what you own on paper | - | Y (Pro) | **FEASIBLE** | ISBN entry or scan; optional online lookup (Open Library) | M | Y | [L1], [L7] |

### F. Teaching and preaching

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| F01 | Sermon Builder (manuscript, slides, handouts together) | Write and present a sermon in one place | - | Y (Pro) | **FEASIBLE-HEAVY** | Editor + slide renderer in WebView2; passage blocks from the verse hub | L | Y | [L35], [L7] |
| F02 | Sermon Manager (calendar planning and archive) | Plan a year of preaching | - | Y (Pro) | **FEASIBLE** | Calendar view over the user database | M | Y | [L35], [L7] |
| F03 | Preaching Mode (notes, timer, slide control) | Preach from the screen | - | Y (Pro) | **FEASIBLE** | Presenter view in WebView2 | M | Y | [L35], [L7] |
| F04 | Sermon and Bible-study markers on passages | See which of your talks used this passage | - | Y | **FEASIBLE** | Reverse index of passages in the user's own documents | S | Y | [L1], [L7] |
| F05 | Bible Study Builder (discussion questions; partly AI) | Prepare a group study | - | Y (Premium) | **FEASIBLE-HEAVY** | Template-based builder; optional AI questions (row G03) | M | Y | [L1], [L2] |
| F06 | SermonAudio integration / audio sermons | Hear sermons on the passage | Y | - | **FEASIBLE** | Link out to SermonAudio by passage (needs internet) | S | Y | [E13], [E9] |
| F07 | Video courses (Mobile Ed) | Seminary-style teaching inside the program | - | Y (8 per quarter with a subscription) | **BLOCKED** | Licensed video courses; nothing equivalent can ship | - | - | [L43], [L44] |

### G. AI features

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| G01 | Study Assistant (chat over your library; Explain and Ask on a selection) | Ask questions and get answers drawn from your books | - | Y (all plans; limited uses without a subscription) | **FEASIBLE-HEAVY** | Engine first: The engine gathers verses and public-domain passages; a small CPU model (Gemma 4 E2B or Qwen3.5-4B, Apache-2.0) only phrases them, with sources shown; optional bring-your-own-key. Slower and weaker than Logos's cloud models | L | Y (slow) | [L1], [L4], [L32], [L33] |
| G02 | Summarize (books and chapters) | Decide what is worth reading | - | Y | **FEASIBLE-HEAVY** | Summaries of shipped public-domain books written at build time by a large model, reviewed by a person, labeled (design L2) | L | Y | [L1], [L2] |
| G03 | Questions to Ask | Suggested questions to explore a topic | - | Y (Premium) | **FEASIBLE-HEAVY** | Small model given engine output only, or a curated question bank | M | Y | [L1], [L2] |
| G04 | Search Results Synopsis (AI digest of results) | A fast answer with footnotes | - | Y | **FEASIBLE-HEAVY** | Small model phrases engine results; contexts kept short because prompt reading is the slow part on a CPU (design §5) | M | Y (slow) | [L1], [L4] |
| G05 | Sermon Assistant (outlines, illustrations, applications) | Draft ideas for a sermon | - | Y (Pro) | **FEASIBLE-HEAVY** | Bring-your-own-key for quality; small local model as a labeled draft only. Judgment work, per design §2 | M | Partial | [L35], [L4], [L2] |
| G06 | Auto-translation of books | Read resources in your own language | - | Y (Max) | **FEASIBLE-HEAVY** | OPUS-MT models (Apache-2.0 per model card) on the CPU, or bring-your-own-key | L | Y (slow) | [L1], [L2], [D19] |
| G07 | Insights sidebar and Lens bar (related passages, commentary snippets, viewpoints) | Related material appears while you read | - | Y (Pro) | **FEASIBLE** | Precomputed related-passage lists (cross-references, shared rare lemmas, embedding neighbors) + public-domain commentary snippets | M | Y | [L2], [L38] |

### H. Content ecosystem

| # | Feature | What the user gets | e-Sword | Logos | simple_bible fit | Data or method that would power it | Effort | CPU | Refs |
|---|---|---|---|---|---|---|---|---|---|
| H01 | Module download manager / store | Add resources from inside the program | Y | Y | **FEASIBLE** | Signed catalog of openly licensed add-on packs; each pack carries its provenance rows | M | Y | [E2], [E5], [L45] |
| H02 | Third-party and user-made modules | Use resources the community has prepared | Y (third-party module sites) | - | **FEASIBLE** | Import a user's own public-domain SWORD/e-Sword modules locally (never redistributed); license read from the module where present | M | Y | [E15], [E16] |
| H03 | Legacy STEP-format book viewer | Read older electronic books | Y | - | **FEASIBLE-HEAVY** | Reader for an old format; low value | M | Y | [E13] |
| H04 | BDAG and HALOT | The standard scholarly Greek and Hebrew lexicons | - | Y (paid add-ons) | **BLOCKED** | Copyrighted (Univ. of Chicago Press; Brill). Substitutes: BDB, Thayer, Abbott-Smith, LSJ, SDBH/SDGNT (row C02, C08) | - | - | [L46], [L47], [L48] |
| H05 | Modern copyrighted translations (ESV, NIV, NASB, NKJV, CSB, NLT) | Read the versions most churches use | Y (ESV free under license; others $10-30) | Y (library) | **BLOCKED** | Publisher licenses. Open substitutes: BSB (CC0), WEB/ASV/KJV (public domain) | - | - | [E17], [E18], [E14], [E19] |
| H06 | Modern licensed commentaries, study Bibles and dictionaries (for example Believer's Bible Commentary, Vine's; New Cambridge Bible Commentary) | Current scholarship | Y (premium) | Y (packages) | **BLOCKED** | Copyrighted; nothing equivalent can ship. Public-domain commentaries are row D01 | - | - | [E2], [L49] |
| H07 | Licensed dramatized audio (ESV, NRSV, CEV) | High-production audio | Y (v13) | - | **BLOCKED** | Licensed recordings; public-domain audio is row A12 | - | - | [E4] |
| H08 | Logos/Lexham proprietary datasets (Lexham Discourse GNT, Factbook content, Logos topic data) | Curated scholarly data layers | - | Y | **BLOCKED** | Copyrighted; open substitutes are MACULA, STEPBible, Theographic, UBS (rows C08, C09, D07, D08) | - | - | [L25], [L24] |

## 5. Counts and parity

| Fit class | e-Sword | Logos | All rows |
|---|---|---|---|
| COMFORTABLE | 27 | 22 | 36 |
| FEASIBLE | 11 | 29 | 36 |
| FEASIBLE-HEAVY | 4 | 15 | 17 |
| BLOCKED | 3 | 6 | 7 |
| **Total features** | **45** | **72** | **96** |
| **Parity (C + F + FH)** | **42/45 = 93%** | **66/72 = 92%** | |
| COMFORTABLE only | 60% | 31% | |
| COMFORTABLE + FEASIBLE (excluding heavy) | 84% | 71% | |

**Caveats on the numbers.** Row granularity is a judgment call: Logos has many more named tools than e-Sword, and e-Sword's list includes small conveniences. Features found in only one product's sources are counted for that product only. The parity score measures tools and the user benefit they deliver with open data; it does not claim the open content equals the licensed content (Thayer is not BDAG).

## 6. The BLOCKED list and its causes

| Cause | Rows | What is lost | Best open substitute |
|---|---|---|---|
| Copyrighted modern translations | H05 | ESV, NIV, NASB, NKJV, CSB, NLT | BSB (CC0), plus KJV, ASV, YLT, WEB-class public-domain texts |
| Licensed scholarly lexicons | H04 | BDAG, HALOT | BDB, Thayer, Abbott-Smith, LSJ (Perseus, CC BY-SA), UBS SDBH/SDGNT senses (CC BY-SA) |
| Licensed modern commentaries, study Bibles, dictionaries | H06 | Current scholarship | Public-domain commentaries (Henry, Gill, Barnes, JFB, Clarke) |
| Proprietary datasets | H08 | Lexham Discourse GNT, Factbook content, Logos topic data | MACULA, STEPBible, Theographic, UBS open data |
| Licensed media and courses | F07, H07 | Mobile Ed video courses; dramatized audio | LibriVox KJV audio; none for courses |
| Content-dependent guide | D12 | Counseling Guide | Nave's passages only (not equivalent) |

No tool feature is BLOCKED by CPU limits. The AI rows are FEASIBLE-HEAVY because a small CPU model is slower and weaker than Logos's cloud models, not because they are impossible.

## 7. Where simple_bible would exceed both

Only items the design (`Bible Study Workbench - Design (2026-10-06).md`) actually supports are claimed.

| Capability | Design basis | e-Sword | Logos |
|---|---|---|---|
| Pre-registered census with control groups, reported FITS / PARTIAL / FAILS / NO_DATA, method stored beside the result | Census engine (L1) | None found | Counts and graphs of search results without controls [L40] |
| Shape engine: named structural patterns, re-runnable, near-misses always returned | Shape engine, shape.db (27 shapes) | None found | Syntax search returns matches; no near-miss or FAILS bucket found [L11] |
| Quotation comparer with a computed verdict ("agrees with the Hebrew against the Septuagint" and the reverse) | Quotation comparer (L1), alignment tables precomputed (L2) | None found | NT Use of OT shows NT, Greek OT and Hebrew side by side and classifies citation/quotation/allusion/echo; no computed agreement verdict found [L1][L42] |
| Provenance tag on every fact; credits generated from a provenance table | §7, build step 2 | None found | None found |
| The engine owns every fact; AI only phrases engine output | §2 governing principle, L3 | No AI | AI answers drawn from the library with footnotes [L1][L4]; the model is in the answer path |
| Offline, CPU-only AI with precomputed intelligence; no credits or account | L2/L3, §5 | No AI | Cloud AI on monthly credits [L4][L50] |
| Writing checks: gloss and pronunciation on first use, no bare script, citation complete | Checks module (L1) | None found | None found |
| Versification map applied before any pairing, visible to the user | Versification map (L1) | None found | Not documented in sources reviewed (Logos may handle it internally) |

### 7a. Check of `10-INNOVATIONS FROM PRACTICE.md` (17 ideas) against e-Sword and Logos

"None found" means not found in the official pages, support articles and reviews listed in References; it is not proof of absence.

| Idea | e-Sword equivalent? | Logos equivalent? | Verdict |
|---|---|---|---|
| I-P01 Claim Check (paste text, check each claim) | None found (no AI or claim tools) [E1][E3] | None found. Study Assistant answers questions from the library [L1][L32]; it does not check a pasted text claim by claim | **Novel** as far as the sources show |
| I-P02 Built-in frequency-matched controls | None found | Search-result graphs by book, no controls [L40] | **Novel** (Logos has the counts, not the controls) |
| I-P03 FAILS bucket always shown | None found | None found; searches return hits [L9][L11] | **Novel** |
| I-P04 Leading-question warning | No AI | None found. Logos's guardrail is restricting AI to a Collection [L4] | **Novel** |
| I-P05 Share-safe export with verification flags | Copy Verses in formats [E6]; no verification flags | Copy Bible Verses, Visual Copy, Citation tool [L31][L27][L5]; citations, not verification status | **Novel** (export exists; flags do not) |
| I-P06 Quotation comparer, "they chose" verdict | None found | **Partial:** NT Use of OT interactive shows NT, Greek and Hebrew OT side by side and classes the use [L1][L42]; no computed agreement verdict found | **Novel in the verdict**; the side-by-side view is not new |
| I-P07 A word's journey through versions in time order | Partial: Strong's dictionary lists KJV renderings [E2] | **Partial:** Bible Word Study has Translation and Septuagint Translation sections [L15]; not a chronological multi-version trace | **Novel in form**; ingredients exist in Logos |
| I-P08 Divine-name view | None found | **Possible by hand:** Visual Filters can color any lemma [L30]; no preset or LXX toggle found | **Convenience, not capability**: Logos users can build it |
| I-P09 Range before ruling (all senses with counts first) | None found | **Equivalent in substance:** Bible Word Study Senses section with counts; Bible Sense Lexicon [L15][L20] | **Not novel**; the difference is ordering and the default view |
| I-P10 Gloss-aware writing pane | Editor with spell check and thesaurus [E13] | Sermon Builder inserts passage blocks [L35]; no gloss or pronunciation checks found | **Novel** |
| I-P11 Grounded drafting (per-sentence fact badges) | No AI | **Partial:** Synopsis and Smart Search answers carry footnotes to library sources [L1][L4]; unsupported sentences are not flagged | **Novel in the per-sentence engine link** |
| I-P12 Study ledger (replayable research) | History list [E3] | **Partial:** Workflows save responses to a notebook [L39]; no replayable query log found | **Novel** |
| I-P13 Write the question down first (pre-registration) | None found | None found | **Novel** |
| I-P14 Pattern builder (user-made shapes) | None found | **Partial:** Syntax Search and Morph Search let users build structural queries [L11][L12]; no near-misses or FITS/FAILS classes found | **Novel in the near-miss and verdict layer**; the query builder is not new |
| I-P15 Preflight for a topic | None found | **Partial:** Sermon and Bible Study markers show your past sermons on a passage [L1] | **Mostly novel** (withdrawn-material warning has no equivalent) |
| I-P16 Human adjudicates; "argue the other side" from engine evidence | None found | **Partial:** Lens bar offers perspective options [L5]; library and AI driven, not engine counter-evidence | **Novel** |
| I-P17 Reply kit | None found | None found | **Novel** |

**Summary of the check:** 11 of 17 ideas have no equivalent in either product in the sources reviewed (I-P01-05, I-P10, I-P12, I-P13, I-P15 mostly, I-P16, I-P17). Five are novel only in a layer added to an existing Logos capability (I-P06 verdict, I-P07 form, I-P11 per-sentence link, I-P14 near-misses; and I-P08 is a preset Logos users can build). One is not novel (I-P09: Logos's Bible Word Study already shows senses with counts). The positioning line in file 10 should not claim the range view or the divine-name view as unique.

## 8. Positioning

### Why choose simple_bible over e-Sword (which is already free)

- **e-Sword is a reader with a library.** Its strengths are fast reading, parallel and compare views, Strong's tooltips, a good editor and a large free and paid module catalog [E1][E3]. In the sources reviewed it has no morphological or syntax search, no interlinear or reverse interlinear, no clause tools, no sense lexicon, no textual-variant view and no Septuagint-vs-Hebrew comparison.
- **simple_bible keeps the reader comforts** (COMFORTABLE rows A01-A10, E01-E10) and adds the original-language layer that otherwise means paying for Logos Pro or Max: morphology search, interlinear, Bible Word Study, Exegetical Guide, sense lexicon, clause views and variants, all from open data (MACULA, STEPBible, UBS, SBLGNT).
- **Then it does what neither does:** counts with controls, pattern queries that show where they fail, quotation agreement verdicts, and a source on every fact.
- **What e-Sword keeps:** licensed modern translations (the free ESV, paid NIV/NASB/NKJV), a 25-year module catalog and mobile apps. Someone who mainly reads the ESV and Matthew Henry is well served by e-Sword already.

### Which Logos users could be served free

- **Served well:** Lay students, small-group leaders and pastors on the Premium/Pro tiers who want word studies, morphology, interlinear, cross-references, maps, a timeline, reading plans and notes; students who want Greek/Hebrew tools without the $199.99/yr Max tier [L7][L8]; anyone who wants offline study without AI credits or an account; anyone who wants to check claims against the text.
- **Served partly:** Preachers. Sermon Builder, Manager and Preaching Mode are FEASIBLE but are a separate product's worth of work, and the AI Sermon Assistant would be slower or need the user's own key.
- **Not served:** Anyone whose work depends on BDAG, HALOT, licensed commentaries (Word, NICNT, Hermeneia-class series), modern study Bibles, Lexham discourse data, Mobile Ed courses, or the ESV/NIV/NASB text. Seminary students and academics who must cite BDAG/HALOT will still need Logos, Accordance or the print volumes. simple_bible can sit beside Logos for them, as the counting and checking tool.

**One-line positioning (revised from file 10):** *e-Sword gives you free books. Logos sells you a library and an AI that reads it. simple_bible gives you the original-language tools for free and checks what people say about the Bible against the text itself, with the counter-evidence shown.*

## 9. Recommended feature sets

### v1: The COMFORTABLE core (a credible free alternative)

1. **Reader:** many versions; parallel, compare and word-diff views; tooltips; Power Lookup; docked panels; dark mode (A01-A04, A06-A08, A10).
2. **Search:** words and phrases with Boolean and regex; Strong's/lemma; whole-library; inline; morphology search; graph by book (B01-B05, B08, B10).
3. **Original language:** Strong's plus BDB/Thayer/Abbott-Smith/LSJ; lexicon compare; interlinear; lemma in passage; verse analysis (C01-C04, C12, C13).
4. **Library:** public-domain commentaries, TSK and OpenBible cross-references, dictionaries, devotionals, Bible Books Explorer (D01-D03, D05, D16).
5. **Personal tools:** highlights, bookmarks, notes, journal, tags, prayer list, scripture memory, reading plans, copy verses, collections (E01-E08, E10, E11).
6. **The differentiators already in the engine:** census with controls and the four buckets; shape engine with near-misses; provenance on every fact; versification map.

### v2: FEASIBLE additions (in priority order)

1. Quotation comparer + NT Use of OT view from UBS Parallel Passages (D15), with the agreement verdict.
2. Bible Word Study, Exegetical Guide, Bible Sense Lexicon, reverse interlinear, textual variants, clause search and clause views (C05-C09, C11, B07).
3. Smart Search with precomputed bge-m3 vectors (B09); Insights sidebar from precomputed related passages (G07).
4. Passage Guide, Topic Guide, Factbook, Atlas, Timeline, Bible Browser, visual filters (D06-D10, D17, B11, B12).
5. Gospel harmony, audio (LibriVox KJV), printing, layouts, localization, module manager, import of the user's own modules, web app (A05, A09, A11-A13, A15, H01, H02).
6. Workflows, citation tool, sermon markers, Sermon Manager, Preaching Mode, Visual Copy (E12, E13, F02-F04, D18).

### v3 and later: FEASIBLE-HEAVY

Syntax search (B06); sentence diagramming (C10); Theology Guide (D11); Sermon Builder (F01); mobile apps and folder-based sync (A14, A16); the optional AI layer (G01-G06), always engine-first and labeled; curated quotations and illustrations (D13, D14, D19).

## 10. License notes found during this study

- **UBS open-license resources are CC BY-SA 4.0** [D4]: the Hebrew and Greek dictionaries (sense lexicon), Bible Routes (atlas), Parallel Passages (quotation index and harmony) and HOTTP (OT variants). Share-alike applies to derived tables; record it in provenance.
- **MACULA's sense data is "used with permission" from UBS** inside a CC BY 4.0 package [D1][D2]. Since UBS now publishes SDBH/SDGNT under CC BY-SA 4.0 [D4], prefer the UBS release for the sense layer to avoid relying on a permission granted to Clear.
- **STEPBible-Data's README now states CC BY 4.0 for the whole repository** [D3]. The vault's credits file still gates it as NC because of TTESV; TTESV ties tags to the ESV, so leave it out regardless. TIPNR's prose descriptions were written by Claude 3 [D3]: Label them as AI text or omit, per the engine-owns-facts rule.
- **Perseus lexica (LSJ) are CC BY-SA 4.0** and ask that modifications be offered back to Perseus [D5].
- **The Strong's XML says "Public Domain" but also carries a 1980 Moody Bible Institute copyright line** [D8]; check what that line covers and strip that material.
- **CCEL texts are free for non-profit use; CCEL's introductions are copyrighted** [D14]. A free tool fits the non-profit terms; prefer CrossWire or Internet Archive sources where they exist.
- **The CrossWire LXX module is "free non-commercial distribution"** [D13], which matches the vault's Rahlfs caution (design §7, decision 4).
- **BSB audio** is reported CC0 by a third party [D17], but berean.bible's licensing page names only the texts [D16]. Verify before shipping; LibriVox KJV is a safe fallback.

## References

All accessed 2026-10-06. support.logos.com blocks automated fetching; claims from those pages rest on search-result text from the URLs listed.

### e-Sword

- **[E1]** e-Sword home page (free; features; platforms). https://www.e-sword.net/
- **[E2]** e-Sword downloads (v15.2.0, updated 08-14-2026; included resources; Berean Bible Study Library offer). https://www.e-sword.net/downloads.html
- **[E3]** e-Sword 15 changes (UI redesign, Strong's search, docked panels, Super Search, Views, ribbon, whole-verse highlighting, verse tagging, cross-platform user files). https://www.e-sword.net/changes.html
- **[E4]** e-Sword history (v12 dark mode 2019; v13 audio Bibles 2021; v14 shared notes 2024; v15 July 2026). https://www.e-sword.net/history.html
- **[E5]** e-Sword FAQ (premium modules need a product key; Download menu; audio needs legacy Windows Media Player). https://www.e-sword.net/faq.html
- **[E6]** e-Sword tutorial (Windows). https://www.e-sword.net/tutorial.html
- **[E7]** e-Sword for Android tutorial (regular expressions, scripture memory, maps, Lexicon Compare, localization). https://www.e-sword.net/android/tutorial.htm
- **[E8]** e-Sword X (Mac) help. https://www.e-sword.net/mac/help.htm
- **[E9]** e-Sword X (Mac) page. https://www.e-sword.net/mac/
- **[E10]** e-Sword HD (iPad) page (location maps, reading plans). https://www.e-sword.net/ipad/
- **[E11]** e-Sword for Android page. https://www.e-sword.net/android/
- **[E12]** e-Sword support page (funded by donations). https://www.e-sword.net/support.html
- **[E13]** Christian Archive, e-Sword feature list (secondary). https://christianarchive.org/software/e-sword-bible-study-software
- **[E14]** Learn of Christ, e-Sword review 2026 (secondary; premium modules $10-30; some claims conflict with official pages and are not used). https://learnofchrist.com/resources/e-sword
- **[E15]** Third-party e-Sword module index (example). https://home.hiwaay.net/~wgann/e-Sword%20Modules/e-Sword%20index.htm
- **[E16]** BibleSupport forum, e-Sword module requests (example of the third-party ecosystem). http://www.biblesupport.com/topic/11020-nasb-2020/
- **[E17]** Reformed Baptist Blog, ESV free in e-Sword; commenter notes the developer pays license fees. https://reformedbaptistblog.com/2016/11/28/excellent-esv-resources-for-e-sword/
- **[E18]** eStudySource, NIV 2011 bundle for e-Sword, $24.99. https://estudysource.com/product/B0024/niv-2011-bundle-niv-and-nirv-for-e-sword
- **[E19]** Lockman Foundation store, NASB for e-Sword. https://shop.lockman.org/collections/e-sword-bibles/nasb

### Logos

- **[L1]** Logos features page (Study Assistant, Smart Search, Synopsis, Summarize, Factbook, NT Use of OT, Bible Books Explorer, Bible Browser, Sermon Builder/Manager, Bible Study Builder, markers, Preaching Mode, Popular Quotations, Auto-translation, Questions to Ask, Print Library Catalog). https://www.logos.com/features
- **[L2]** The Next Era of Logos (features by plan: Free, Premium, Pro, Max). https://www.logos.com/future-of-logos
- **[L3]** Wikipedia, Logos Bible Software (subscription since Oct 2024; platforms; AI features). https://en.wikipedia.org/wiki/Logos_Bible_Software
- **[L4]** Logos support, How Logos uses AI (search snippet; page blocks automated fetch). https://support.logos.com/hc/en-us/articles/35181728416397-How-Logos-uses-AI
- **[L5]** Bible Buying Guide, Logos subscriptions in detail (per-tier lists incl. Exegetical Guide and Bible Word Study at Max; Lens bar, Insights, Citation tool). https://biblebuyingguide.com/logos-subscriptions-a-detailed-look-at-the-new-logos/
- **[L6]** Logos free plan (25+ resources; desktop, web, mobile). https://www.logos.com/basic
- **[L7]** Scribe, Logos pricing 2026 (Premium $9.99/mo or $99.99/yr; Pro $14.99/$149.99; Max $19.99/$199.99; verified July 31, 2026). https://scribe-bible.app/blog/logos-bible-software-pricing
- **[L8]** Nick Stapleton, Logos buyer's guide 2026 (original-language tools by tier). https://www.nickstapleton.me/logos-buyers-guide/
- **[L9]** Logos support, How do I search in Logos (search types). https://support.logos.com/hc/en-us/articles/360039621591-How-Do-I-Search-in-Logos
- **[L10]** Logos support, Clause Search. https://support.logos.com/hc/en-us/articles/360017524912-Clause-Search
- **[L11]** Logos support, Greek Syntax Search. https://support.logos.com/hc/en-us/articles/360017808131-Greek-Syntax-Search
- **[L12]** Logos community wiki, Morphological Search. https://community.logos.com/wiki/logos-user-wiki/to-sort/table-of-contents/morphological-search/
- **[L13]** Logos support, Using Guides (Passage Guide, Exegetical Guide, Bible Word Study, Topic, Theology). https://support.logos.com/hc/en-us/articles/360017893592-Using-Guides
- **[L14]** Logos support, Study a Passage with the Exegetical Guide. https://support.logos.com/hc/en-us/articles/360016462852-Study-a-Passage-with-the-Exegetical-Guide
- **[L15]** Logos support, Bible Word Study Guide (sections include Translation, Septuagint Translation, Root, Senses, Clause Participants, Lemma in Passage). https://support.logos.com/hc/en-us/articles/360016688811-Studying-Words-Using-the-Bible-Word-Study-Guide
- **[L16]** Logos support, Interlinears. https://support.logos.com/hc/en-us/articles/360016304852-Deepen-your-Understanding-of-Biblical-Languages-with-Interlinears
- **[L17]** Logos community, Reverse-Interlinear/Interlinear Bibles. https://community.logos.com/kb/articles/2305-reverse-interlinear-interlinear-bibles
- **[L18]** Logos support, Topic Guide. https://support.logos.com/hc/en-us/articles/360016688791-Topic-Guide
- **[L19]** Logos community wiki, New Search help (Inline Search). https://community.logos.com/wiki/logos-user-wiki/search-help/new-search-help/
- **[L20]** Logos support, Bible Sense Lexicon. https://support.logos.com/hc/en-us/articles/360016188011-Bible-Sense-Lexicon
- **[L21]** Logos support, Atlas. https://support.logos.com/hc/en-us/articles/360015929072-Atlas
- **[L22]** Logos 2026 Gold Library product page ($849.99 on 2026-10-06; commentary series listed). https://www.logos.com/product/228268/logos-10-gold
- **[L23]** Logos support, Advanced Timeline. https://support.logos.com/hc/en-us/articles/360015929052-Advanced-Timeline
- **[L24]** Logos support, What can I do with the Factbook (20,000+ pages). https://support.logos.com/hc/en-us/articles/360016146691-What-can-I-do-with-the-Factbook
- **[L25]** Logos product, Lexham Discourse Greek New Testament Datasets. https://www.logos.com/product/131520/lexham-discourse-greek-new-testament-datasets
- **[L26]** Logos, Sentence Diagramming feature. https://www.logos.com/features/sentence-diagramming
- **[L27]** Logos, Media Tool and Visual Copy. https://www.logos.com/features/media-tool-visual-copy
- **[L28]** Logos support, Three Tools to Compare Bible Translations. https://support.logos.com/hc/en-us/articles/360054863171-Three-Tools-to-Compare-Bible-Translations
- **[L29]** Logos support, Compare Translations with Text Comparison. https://support.logos.com/hc/en-us/articles/360015518292-How-do-I-compare-Bible-translations
- **[L30]** Logos support, Create a Visual Filter. https://support.logos.com/hc/en-us/articles/360016747431-Create-a-Visual-Filter
- **[L31]** Logos support, Copy Bible Verses. https://support.logos.com/hc/en-us/articles/360015518272-Copy-Bible-Verses-from-Logos
- **[L32]** Logos, What's New July 2026 (v52: Reading Plan Manager; Study Assistant uses an open resource as anchor; limited uses for non-subscribers). https://www.logos.com/grow/release-july-2026/
- **[L33]** Logos, What's New August 2026 (v53: Explain and Ask open Study Assistant; reading-plan editing; reading-plan audio). https://www.logos.com/grow/release-august-2026/
- **[L34]** Logos support, Reading Plans. https://support.logos.com/hc/en-us/articles/360016525132-Reading-Plans
- **[L35]** Logos support, Sermon Builder; Sermon Manager; Preaching Mode; Logos Tools for Great Sermons. https://support.logos.com/hc/en-us/articles/360016747391-Writing-Sermons-Using-Sermon-Builder ; https://support.logos.com/hc/en-us/articles/360046242132-Sermon-Manager ; https://support.logos.com/hc/en-us/articles/360046239932-Deliver-a-Sermon-with-Preaching-Mode ; https://support.logos.com/hc/en-us/articles/20993014297101-Logos-Tools-for-Great-Sermons
- **[L36]** Logos support, Logos Mobile Notes (notes and highlights sync across desktop, mobile, app.logos.com). https://support.logos.com/hc/en-us/articles/360026434012-Logos-Mobile-Notes
- **[L37]** Logos community wiki, Tools table of contents (Power Lookup, Passage Analysis). https://community.logos.com/wiki/logos-user-wiki/to-sort/table-of-contents/tools/
- **[L38]** Kevin Purcell, Logos Insights sidebar with AI for Pro users. https://www.kevinpurcell.org/new-logos-insights-sidebar-with-ai-for-logos-pro-users/
- **[L39]** Logos support, Workflow Editor; guided study options. https://support.logos.com/hc/en-us/articles/360018252991-Workflow-Editor ; https://support.logos.com/hc/en-us/articles/360018035692-What-guided-study-options-does-Logos-offer
- **[L40]** Logos community wiki, Graph Bible Search Results. https://community.logos.com/wiki/logos-user-wiki/bible-word-study/graph-bible-search-results/
- **[L41]** Logos community wiki, Guides (Sermon Starter, Counseling and others). https://community.logos.com/wiki/logos-user-wiki/to-sort/table-of-contents/guides/
- **[L42]** Abram K-J, Logos 7 review (NT Use of the OT: citation, quotation, allusion, echo; Greek and Hebrew display). https://abramkj.com/2016/08/22/logos-7-review-screenshots-video/
- **[L43]** Logos subscription perks (8 Mobile Ed courses per quarter; monthly free book; 5% off). https://www.logos.com/perks
- **[L44]** Logos Mobile Ed. https://www.logos.com/mobile-ed
- **[L45]** Logos base packages. https://www.logos.com/basepackages
- **[L46]** Logos, BDAG product page. https://www.logos.com/product/3878/a-greek-english-lexicon-of-the-new-testament-and-other-early-christian-literature-3rd-ed
- **[L47]** Logos, HALOT product page. https://www.logos.com/product/5226/hebrew-and-aramaic-lexicon-of-the-old-testament-halot
- **[L48]** Logos, BDAG/HALOT bundle. https://www.logos.com/product/5228/bdag-halot-bundle
- **[L49]** Logos 2026 Bronze Library product page ($89.99 shown on 2026-10-06 against a $939.80 collection value; price shown depends on what the account owns). https://logos.com/product/165447/logos-8-bronze
- **[L50]** AI credits (credits renew monthly). https://support.logos.com/hc/en-us/articles/23563051328269-How-do-AI-credits-work
- **[L51]** Bible Study With Randy, Logos 2026 libraries (tracks; cost varies with what you own). https://www.biblestudywithrandy.com/2026/01/logos-2026-libraries/

### Open data and licenses

- **[D1]** MACULA Greek LICENSE (CC BY 4.0; Berean Interlinear glosses public domain since 2023-04-30; Cherith glosses CC BY 4.0; MARBLE senses used with permission). https://github.com/Clear-Bible/macula-greek/blob/main/LICENSE.md
- **[D2]** MACULA Hebrew LICENSE (CC BY 4.0; WLC; Groves syntax CC BY 4.0; OSHB CC BY 4.0; SDBH senses used with permission; LXX equivalents). https://github.com/Clear-Bible/macula-hebrew/blob/main/LICENSE.md
- **[D3]** STEPBible-Data README (CC BY 4.0; TAHOT, TAGNT, TBESH, TBESG, TFLSJ, TIPNR, TVTMS, TEHMC, TEGMC, TTESV). https://github.com/STEPBible/STEPBible-Data
- **[D4]** UBS open-license resources (CC BY-SA 4.0: Dictionary of Biblical Hebrew, Dictionary of the Greek NT, MARBLE images and Bible Routes, Paratext Parallel Passages incl. OT quotes in the NT, HOTTP). https://github.com/ubsicap/ubs-open-license
- **[D5]** Perseus lexica repository (CC BY-SA 4.0). https://github.com/PerseusDL/lexica
- **[D6]** SBLGNT repository (CC BY 4.0; data/sblgntapp apparatus). https://github.com/LogosBible/SBLGNT
- **[D7]** Open Scriptures HebrewLexicon (CC BY 4.0; BDB and Strong's text public domain). https://github.com/openscriptures/HebrewLexicon
- **[D8]** Open Scriptures Strong's dictionaries (XML rights field: Public Domain). https://github.com/openscriptures/strongs
- **[D9]** Thayer's Greek-English Lexicon on Zenodo (CC0). https://zenodo.org/records/2338577
- **[D10]** OpenBible.info Bible Geocoding Data (CC BY 4.0). https://github.com/openbibleinfo/Bible-Geocoding-Data
- **[D11]** Theographic Bible Metadata (CC BY-SA 4.0). https://github.com/robertrouse/theographic-bible-metadata
- **[D12]** CrossWire module AbbottSmith (Public Domain). https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=AbbottSmith
- **[D13]** CrossWire module pages, Distribution License = Public Domain for TSK, Nave, Torrey, Easton, Smith, ISBE, Hitchcock, MHC, Barnes, JFB, Clarke, Wesley, Josephus, Daily, Dodson, StrongsGreek, StrongsHebrew; Robinson = CC BY-SA 4.0; LXX and RWP = free non-commercial; NETfree = copyrighted. https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=TSK (substitute the module name)
- **[D14]** CCEL copyright policy (public-domain texts free for personal, educational or non-profit use; CCEL introductions copyrighted). https://www.ccel.org/about/copyright.html ; John Gill at CCEL: https://ccel.org/ccel/gill
- **[D15]** OpenBible.info cross-references (about 340,000; CC BY). https://www.openbible.info/labs/cross-references/
- **[D16]** Berean Bible terms and licensing (BSB and Majority Bible text public domain/CC0 since 2023-04-30). https://berean.bible/terms.htm ; https://berean.bible/licensing.htm
- **[D17]** LibriVox, Bible (KJV) Complete (public domain recording). https://librivox.org/bible-complete-king-james-version/ ; BSB audio reported CC0 (third party, verify): https://thehistoricfaith.com/audio-bible/bsb
- **[D18]** Natural Earth terms of use (public domain). https://www.naturalearthdata.com/about/terms-of-use/
- **[D19]** Helsinki-NLP OPUS-MT model card (Apache-2.0). https://huggingface.co/Helsinki-NLP/opus-mt-en-es

