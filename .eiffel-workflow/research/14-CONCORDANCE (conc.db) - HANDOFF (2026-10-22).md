# 14 — Concordance (conc.db): Handoff into simple_bible (2026-10-22)

**From:** the CONC session (vault `Obsidian Vault\Scholars`), which built conc.db and its printed-concordance pilot, 2026-10-18 to 2026-10-22.
**To:** whichever session picks up simple_bible next.
**Status:** research input. Nothing in simple_bible's spec, contracts or code has been changed. This file has not been committed.

## 1. What Larry decided

- **2026-10-22, the printed concordance is shelved.** "These are HUGE (as books or as PDFs), which makes the idea impractical. The only way it now works will be conc.db accessed through" an app. Every book was held under 600 pages, and the full concordance still came to 14 books, about 6,750 pages.
- **2026-10-22, the app is simple_bible.** At first he said a new simple_conc, then corrected it: "we were going to put this in simple_bible."
- **2026-10-22, three lookups:** by Hebrew/Aramaic/Greek word, by English word, and by verse reference.
- **2026-10-22, personal edition "first and primarily."** The distribution edition comes later (§6).
- **Standing rules from the concordance work** (all Larry's, 2026-10-18 to 10-21):
  - Keyed by HEADWORD (our own `lemma_id`), **never by Strong's.** Strong's lives only in `lemma_xref`.
  - **"Candidates," never "best,"** for meanings and renderings.
  - **"Use local if we have it, but do not ship if license agreements are not solid."** There are TWO EDITIONS:
    - PERSONAL is built from conc.db and marked "PERSONAL EDITION - not for distribution" in the title bar and the About window.
    - DISTRIBUTION is built from conc_dist.db only.
  - **Credits rule:** every "free to use with credit" source appears in Help → About. Credits are generated from one `notice` table (planned for conc_dist.db), so they can never go stale.
  - **Usefulness model = Strong's Concordance:** how to use it at a high level must be "painfully obvious" on first opening, and the finer uses are taught in the help. Readers never see corpus codes. "Linked" counts appear only when something is missing.
  - **Hebrew lines up LEFT in tables** (an LRM before Hebrew cells), and headings start with the transliteration.
  - **Every original-language word shows a transliteration** (SBL style); dictionary forms also show a pronunciation (CAPS stress, e.g. KHEH-sed). YHWH = YAH-weh.
  - **Helps:** "the more common-man helps the better, but without … clutter": at most one callout per entry; asides go in numbered notes.
  - **Never print Larry's name.** His framework ideas appear in an unnamed "Going further" section, with no ™ names.
  - **American English** in all prose, code comments, identifiers and labels. Quotations of sources stay as printed.

## 2. The data: conc.db

- **Path:** `C:\Users\LJR19\OneDrive\Documents\Obsidian Vault\Scholars\Rix\Data\data\conc.db`.
  - **1.23 GB.** It was built 2026-10-21 by Python's SQLite 3.50.4.
  - Page size 4096, UTF-8, `user_version` 0, journal mode DELETE.
  - No STRICT tables, no generated columns, no FTS. It should open under the fleet's SQLite 3.31.1, but that is UNTESTED (§7).
- **README:** `Rix/Data/_conc.db README.md`. **Plan:** `Rix/Data/_conc.db Plan - Original-Language and English Concordances.md` (status board, licensing matrix, change log). **Read `SELECT * FROM audit` first** (111 checks).
- **Shape:** corpus → work → unit (div1/div2/div3 = chapter/verse/sub, plus `recension`) → token.
  - Each token has `lemma_id`, `lemma_basis` (tagged/aligned/xref/none), morphology columns, `sense`, and `before`/`after` (punctuation and joiners).
- **Corpora** (`corpus.ship_class` carries the license):

| Code | Text | Tokens | Ships? |
|---|---|---|---|
| WLC-MACULA | Hebrew Bible (WLC, MACULA Hebrew tagging) | 475,911 | yes (CC BY 4.0) |
| NT-MACULA | Greek NT (Nestle 1904, MACULA Greek) | 137,779 | yes (CC BY 4.0) |
| WH1881 | Westcott-Hort 1881 (Grauman) | 137,688 | yes (CC BY-SA 3.0 US) |
| LXX-RAHLFS | Septuagint, Rahlfs (CATSS) | 623,693 | **NO, research only** |
| ENG-BSB | BSB per-word tables | 726,109 | text PD; **the tables need Berean's OK** |
| ENG-KJV | KJV 1769 with Strong's tags | 789,989 | yes (UK note) |
| ENG-STEP | STEPBible per-word glosses | 852,713 | yes (CC BY 4.0) |
| ENG-BRENTON | Brenton's LXX English (1844/1851) | 745,918 | text yes; its links to the LXX are research-only |

- **Main tables** (row counts): `token` 4,489,800; `link` 2,532,519 (English↔original word links and MT→LXX links, by `kind`); `unit` 191,557; `unit_map` 52,378 (Hebrew↔LXX verse map); `lemma` 44,934 (headword, search key, pos, `n_tokens`, `translit`, `pron`); `lemma_spelling`, `lemma_xref` (Strong's/OSHB/Louw-Nida).
- **Meanings:**
  - `lex_sense` 123,926 rows from:
    - SDBH and SDGNT (UBS open license, CC BY-SA: a meaning for EVERY place, resolved to the token in `lex_sense_ref`, 462,787);
    - BDB 1906;
    - Abbott-Smith 1922;
    - LSJ (dated);
    - STEPBible glosses;
    - TBESH.
  - `meaning_source` lists all 14 sources.
- **Older English meanings:** `eng_shift`, `eng_sense` (Webster 1828, Wright 1884, …).
- **Use over time:** `period_text` (24 writings, Homer → Hippolytus; Hebrew Bible; Dead Sea Scrolls), `period_count`, `period_form`, `lsj_cite`.
- **Going further:** `see_also` (72 rows: readings, shape.db patterns, ideas.db items).
- **Indexes:** 17, on lemma(search/headword), token(lemma_id / unit_id,pos / search / corpus_id), unit(corpus,work,div1,div2), link(to_token) plus its primary key (from_token,to_token,kind), and the meaning tables.
- **The largest lists:** ὁ has 88,444 places in the LXX, and וְ has 50,272 in the Hebrew Bible. Any every-place view needs paging or a virtual grid. The print plan's "small-words appendix" is moot in an app: show every place on demand.

## 3. What a word looks like (the pilot = the reference design)

Larry approved this layout over five pilot rounds. A single word is small, which is why an app works where print did not. Read these for the look and the order:
- `Rix/Data/conc pilot/Pilot 5.7 - Words and a Phrase in Both Concordances (PERSONAL EDITION).pdf` (176 pp; 15 words and one phrase).
- `Rix/Data/conc pilot/Pilot 5.7 - Words and a Phrase in Both Concordances.md` (the same, as Markdown).

**Word view, in order:**
1. **Heading:** transliteration · Hebrew/Greek · pronunciation.
2. **How often,** in plain words (with Hebrew stems or Greek editions).
3. **English at a glance:** what the BSB, KJV and STEP use for the word, with counts.
4. **What the dictionaries say:** each source in its own words, side by side as candidates.
5. **Through the centuries:** counts per writing and per 10,000 words; for Greek, LSJ meanings by five periods.
6. **One short callout,** at most.
7. **EVERY PLACE** (the core): reference | whole word + transliteration | meaning (SDBH/SDGNT) or stem | BSB in context | KJV | STEP.
8. **The Greek Old Testament:** for Greek words, the Septuagint places with Brenton's English; for Hebrew words, the Greek column in the table.
9. **Going further** (from `see_also`).
10. **Notes.**

**English lookup:** the pilot's "English index" (an English word → the Hebrew/Greek words behind it, Bible by Bible, with counts).
**Phrase entries** exist too ("Son of Man": head word + second word, with at most an article between them; split phrases are found by rule).

**Browse lists, already built:** `Rix/Data/conc pilot/Planned Headwords/` holds one TSV per language (9,341 Hebrew/Aramaic; 5,396 NT; 14,175 LXX; 12,965 English), with headword, transliteration, pronunciation, part of speech, STEP gloss, usual English and count. They come from `_Tools/conc_headword_plan.py`.

## 4. Reference implementations (Python, in `Scholars/_Tools/`)

Under simple_bible's **D-020 (no Python in the final product),** these are reference implementations only:

| File | What it does |
|---|---|
| `build_conc_db.py` | builds conc.db (~10 min; builds to a temp file, keeps `.prev`); calls `conc_links.py` |
| `build_conc_english.py` (+ `conc_brenton.py`, `conc_englemma.py`, `conc_odes.py`) | English corpora, word links, English headwords |
| `conc_translit.py` | transliteration + pronunciation (fills `lemma.translit/pron`) |
| `build_conc_meaning.py` | meanings tables |
| `build_conc_seealso.py` | `see_also` |
| `build_conc_periods.py` (+ `stanza_classical.py`, `fetch_perseus_classical.py`) | counts by writing |
| `conc_entry.py` | one word's entry at the command line |
| `conc_pilot.py` | **the entry layout: every query the word view needs** (1,356 lines) |
| `conc_pdf.py` | Markdown → PDF (WeasyPrint 70.0); could serve "print this word" |

Full rebuild order: build_conc_db → build_conc_english → conc_translit → build_conc_meaning → build_conc_seealso → build_conc_periods.

**One porting trap:** the pilot transliterates each *place's* word at render time (`TR.translit`; the whole-word column). Only headwords have a stored `translit`. **Suggested:** add a `token.translit` column at build time, so the Eiffel engine never has to port the transliteration rules. That is a technical fork for this session to settle.

## 5. How it fits simple_bible (to work out, not yet decided)

- simple_bible's own design already has Hebrew/Greek/English lookups, an engine that owns every fact, sources and licenses on every fact, and D-011 (Swete ships; Rahlfs only with permission). conc.db is built on the same rules: the license per corpus, the LXX research-only.
- **The personal edition fits fork 03's gated answer (B′, private DATA PACKS, no private code).** conc.db, with its research-only layers (CATSS LXX, unconfirmed BSB tables), would be Larry's private pack. A shippable conc_dist.db would be a public pack.
  - simple_bible's target user is someone *other* than Larry, but he wants the personal edition "first and primarily". Check with him whether that changes simple_bible's release order (a policy question, so it is his gate).
- **The forks to settle** (technical, so they are settled by debate and spikes, not by asking Larry):
  1. Does conc.db stay its own file (attached or opened beside simple_bible's databases), or get folded into simple_bible's schema?
  2. Which engine classes (BIB_ prefix) carry the word view, the English lookup and the reference lookup?
  3. Do they reuse the simple_bible spec's lookup classes, or add new ones?
  4. Does `token.translit` get precomputed?
  - Following simple_bible's process, run them as an `/eiffel.debate` (Pre-Phase 1.5, budget seats). Then fold the results into the spec in one pass, and back up and roll forward through the Spec Kit.
- Read first: `Rix/Upcoming Projects/simple_bible - Session Handoff (2026-10-07).md`, then `research/04-DECISIONS.md`, `spec/07-SPECIFICATION.md` and `gui/00-GUI-SPEC.md`.

## 6. The distribution edition (later)

- conc_dist.db has not been built. Blockers, from the plan's licensing matrix:
  - the LXX → Swete (First1KGreek, CC BY-SA) needs its own lemmas, as in D-011;
  - the BSB per-word tables need Berean's confirmation;
  - the permission letters are Larry's to send (`Rix/Data/_conc.db Permission Letters (drafts).md`).
- Share-alike sources (WH/Grauman, UBS SDBH/SDGNT) ship; the distributed data would be CC BY-SA 4.0 as a whole.

## 7. Fleet facts that bear on this (from simple_bible's own debates; check that they are still current)

- **eiffel_sqlite_2025 was SQLite 3.31.1 (2026-10-07).** The upgrade to 3.53.4 plus `blocking` externals was verdict F4 A″, awaiting Larry. With a 1.23 GB file and 4.5M tokens, an unmarked `sqlite3_step` will freeze the GUI under SCOOP (fleet law), so check whether the patch has landed.
- On 3.31.1, `ATTACH 'file:…?mode=ro'` silently opened a WRITABLE database (URI filenames off). simple_sql cannot ATTACH on a read-only connection, and the 11th ATTACH fails. All of this matters if conc.db is attached as a pack.
- **The GUI is simple_widgets** (shaped Hebrew RTL in SW_TEXT_BOX/SW_LABEL). The 26 simple_widgets gap items are in `gui/spec_windows_design_notes.md`; a large virtual grid with shaped Hebrew cells is the one this view needs most. Test headless, with no windows on Larry's desktop.

## 8. Open items carried over from the concordance work

1. NT ἐμπίπρημι (2 uses) and LXX ἐμπρήθω are one verb under two headwords. Merging them is Larry's call.
2. The later writings' Stanza cache (Philo, Josephus, the fathers) has no accents, so τις, εἰς and the like go uncounted there. Re-tagging would also fill the missing half of Theophilus and Irenaeus.
3. The fathers' check by voting (86/100) predates the 30%-share vote rule; re-check it.
4. More English Bibles (ASV, YLT, Tyndale, Wycliffe; computed links), and the KJV small-word tags.
5. The classical hand check: about 92% over five rounds (90/100 in the last). The last two rules have not been re-measured.

## 9. Where the record lives

- Vault memory: `project_conc_db.md` (the session's running record).
- The plan's change log (§8) and status board (§5 H shelved; §5 I now points here).
