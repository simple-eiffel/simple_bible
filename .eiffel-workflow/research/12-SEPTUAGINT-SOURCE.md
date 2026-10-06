# SEPTUAGINT SOURCE: simple_bible

*Prepared 2026-10-06 for decision D-011 (Larry, decided 2026-10-06): Swete ships by default; Rahlfs stays in the private build until its rights holders give written permission. Every URL below was fetched or returned by a live search on 2026-10-06 unless marked otherwise. Repository facts (licenses, file lists, commit dates, issue texts) came from the GitHub API on that date. Nothing has been sent to anyone; the letters in section C are drafts for Larry.*

*Samples saved (one book each, Ruth) in `research/_samples/`:*

| File | Source | SHA-256 |
|---|---|---|
| `tlg0527.tlg010.1st1K-grc1.xml` | First1KGreek TEI (Swete Ruth) | `c69973e18bf87ba98e7fdef8ea0456a0d478b99b0291033da726f8acb648a484` |
| `nathans_10.Ruth.txt` | nathans/lxx-swete token file | `74c76b5c6ce7e4743454012fb0d3d34b46422a3e763dca1ef072677c1f808ff2` |
| `Sollupulo_8.Ruth_Swete1909.txt` | Sollupulo/Swete-1909-LXX proofread verse file | `2840164becf4da4a56c9d11db9e8b594c23df8353d371d7a7d296a39778572d7` |

---

## Summary

- **Ship:** the First1KGreek TEI files for Swete (Open Greek and Latin, University of Leipzig), `data/tlg0527`, pinned at commit `eb81494731fd632f582c4b94634127bdbd596b43` (2025-01-24, the last commit to touch the Septuagint folder). License: **CC BY-SA 4.0** (stated in the repo and in every TEI header). Swete's printed edition is public domain.
- **Coverage gaps:** Ecclesiastes is missing entirely (the folder holds only metadata); about a dozen chapter openings were lost in OCR; a number of verses were merged into their neighbors. Judges has a single text, which is Codex Vaticanus (B) despite a metadata label saying "Alexandrinus". Tobit has only the B/A text. Daniel, Susanna, and Bel have both the Old Greek and Theodotion texts.
- **Quality:** These files are OCR output that nobody read through. The project's own editor counted **74 errors or omissions in 56 verses of Genesis** (2022). The build must carry a visible "digital text from OCR" caveat and run the checks listed in the build checklist.
- **No open morphology exists for Swete.** The eliranwong repository has no morphology, and its own license and provenance are unresolved. Release 1 should ship Swete as text only (surface-form search with normalized copies). Lemmas are a later, separate decision.
- **Rahlfs rights are split three ways.** The Deutsche Bibelgesellschaft (German Bible Society, Stuttgart) holds the print edition. The digital text was keyed by the TLG (UC Irvine). CCAT/CATSS at Penn did the morphology and runs the distribution. CCAT's named contact, Professor Robert A. Kraft, died on 2023-09-15. No successor is named anywhere I could find, so the Penn letter goes to the Department of Religious Studies.

---

## A. Swete acquisition plan

### A1. Every machine-readable Swete source found

| # | Source | License (verified where stated) | Format | Coverage | Lemmas / morphology | Status and notes |
|---|---|---|---|---|---|---|
| 1 | **First1KGreek (OGL), `data/tlg0527`**: https://github.com/OpenGreekAndLatin/First1KGreek/tree/master/data/tlg0527 | **CC BY-SA 4.0**: repo license (GitHub API `CC-BY-SA-4.0`), plus `<licence target="https://creativecommons.org/licenses/by-sa/4.0/">` in each TEI header (confirmed in the Ruth sample) | TEI EpiDoc XML, one file per work; `chapter`/`verse` textparts; Swete's apparatus kept as `<note type="footnote">`, marginal manuscript sigla as `<note type="marginal">`, page breaks `<pb>`, line breaks `<lb>` | 55 Swete works (57 Greek files, minus Hart's Sirach `tlg034…grc1` and Ottley's Isaiah `tlg048…grc2`); about 29,177 verse units in my count | None | **Recommended base.** Last Septuagint commit 2025-01-24 (`eb81494`); repo HEAD `03776b3` (2026-09-30). 144 open issues repo-wide; the Septuagint ones are summarized in A3 |
| 2 | **nathans/lxx-swete**: https://github.com/nathans/lxx-swete | Data CC BY-SA 4.0 (README); code MIT (`COPYING-Code`) | Plain text, one token per line, prefixed `book.chapter.verse` (sample confirmed) | Same as #1, but **file 30 (Ecclesiastes) absent** (open issue, 2026-07-29) and no 07/09/22 | None (README promises "annotations"; none present) | Derived from #1, rebased 2025-12 to the 2025-01-23 upstream. Drops apparatus, structure, and lettered verse labels. Inherits every OCR error (sample: Ruth 1:2 still reads `Μααλὼν καὶ ών`). Useful only as a cross-check |
| 3 | **eliranwong/LXX-Swete-1930**: https://github.com/eliranwong/LXX-Swete-1930 | Repo license **GPL-3.0**; **the license of the Greek text itself is unresolved.** README: text "supplied by Pasquale Amicarelli, previously compiled… as a BibleWorks module." Issues #2 (2022), #4 (2026-08), and #5 (2026-09) ask about the license and get no answer | CSV word lists (`00-Swete_versification.csv`, `01-…with_punctuations.csv`, `02-…without_punctuations.csv`, `03-…SBL_transliterations.csv`) | Whole Swete, including 1 Enoch, but issue #3 reports **1 Enoch 33–88 and 90–96 blank** | **None published.** README lists "tagging morphology (by James Tauber)" as a plan; issue #1 (2020, "where could I find this?") was never answered | **Do not use.** No commits since 2017; provenance is a BibleWorks module of unknown terms. Correction to `02-LANDSCAPE.md` B11 and `REFERENCES.md`, which said "morphology work exists" |
| 4 | **OpenGreekAndLatin/septuagint-dev**: https://github.com/OpenGreekAndLatin/septuagint-dev | **No license stated** | Three volume-level XML files plus `raw_ocr/` | All three volumes (1891, 1901, 1930 printings) | None | Last push 2015-11-16; an earlier, superseded stage of #1. Do not use |
| 5 | **sleeptillseven/LXX-Swete** (Christoph Jasinski): https://github.com/sleeptillseven/LXX-Swete | **Conflicting:** README says CC BY-SA 4.0, but `license.md` contains the **CC BY-NC-SA 4.0** text | Text files from #1, corrected against manuscripts | Progress "17/59"; `texts/DONE` holds Ruth, Esther, Psalms, the Twelve, Susanna (Th), Daniel (OG), Bel (OG) | None | Last push 2020-10-11. Treat as UNKNOWN (D-002) until the conflict is resolved. Corrections "against manuscripts" may depart from Swete's print |
| 6 | **Sollupulo/Swete-1909-LXX**: https://github.com/Sollupulo/Swete-1909-LXX | `LICENSE.txt` is the full **CC BY-SA 4.0** text (GitHub shows NOASSERTION only because it cannot parse the file) | One verse per line, `8.Ruth.1.1 <text>` (sample confirmed) | **Genesis through 3 Kingdoms only** (11 books), proofread by hand "character for character" against the PDFs; apparatus not reproduced | None | Created 2025-11, last push 2026-02-28. Sample shows real repairs: Ruth 1:2 restores `Κελαιών` and `Μωὰβ`, which #1 lost. **Best collation partner for Genesis through 3 Kingdoms** |
| 7 | **Mallioch/swete-lxx**: https://github.com/Mallioch/swete-lxx | Code MIT; README says "The Swete LXX text is in the public domain" (the digitization's own terms are not stated) | Text | A few Minor Prophets and both Daniels only | None | Last push 2017. Not useful |
| 8 | **brainheart/septuagint-contabulate**: https://github.com/brainheart/septuagint-contabulate | Data CC BY-SA 4.0 (`DATA-LICENSE.md`); code MIT | Derived JSON | #1 plus Brenton's Greek for the gaps | None | Not a source to ship, but its `SOURCES.md` is a useful independent audit of #1 (see A3). One error: It repeats the metadata label "Judges is Codex A only," which section A2 shows is wrong |
| 9 | **CrossWire SWORD** | No Swete module found. The only Septuagint module is `LXX` ("Septuagint, Morphologically Tagged Rahlfs'"), built from CCAT, license "Copyrighted; Free non-commercial distribution" (https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=LXX, module v3.2, 2025-03-15) | | | | Not a Swete source |
| 10 | **Commercial: Logos/Verbum "Lexham Greek-English Interlinear Septuagint: H. B. Swete Edition"** (https://www.logos.com/product/28564/the-lexham-greek-english-interlinear-septuagint-hb-swete-edition) | Proprietary | | | Has morphology | Not redistributable; listed only for completeness |
| 11 | **Gap filler (not Swete): Brenton's Greek text, eBible.org `grcbrent`** (https://ebible.org/Scriptures/details.php?id=grcbrent) | Marked **public domain** on eBible.org | USFM, USFX, VPL, and others | Full Septuagint (Brenton 1851, Sixtine/Vaticanus-based) | None | Possible filler for Swete's Ecclesiastes gap, **only with a per-row edition label** ("Brenton 1851, not Swete") |
| 12 | Other aggregators: cbop-dev/biblical-lexeme-explorer (AGPL code, CC BY-SA data) and OpenScriptorium (ISC) | | | | | Neither is a source. cbop-dev calls eliranwong's text "Public Domain" (not what that repo says), and OpenScriptorium lists "Rahlfs Septuagint (1935): Public domain" with morphology "from CATSS." **Do not copy either claim**; see section B |

Public-domain scans of the print volumes (cited by #1, #3, and #6): Vol. I https://archive.org/details/oldtestamentingr01swetuoft (cited in the TEI headers); also https://archive.org/details/theoldtestamenti00unknuoft, https://archive.org/details/oldtestamenting02swet, and https://archive.org/details/oldtestgreek00unknuoft.

### A2. Coverage of the recommended source (#1), checked file by file

Titles below are the TEI `<head>` or CTS titles. Greek names carry a transliteration and English the first time they appear.

- **Present (55 works):** Genesis through Deuteronomy; Joshua (one text); Judges (one text); Ruth; 1–4 Kingdoms (Βασιλειῶν, *Basileiōn*, "Reigns/Kingdoms" = 1–2 Samuel and 1–2 Kings); 1–2 Chronicles (Παραλειπομένων, *Paraleipomenōn*, "things left out"); 1 Esdras; 2 Esdras (= Ezra plus Nehemiah, 23 chapters); Esther with its additions; Judith; Tobit (B/A text); 1–4 Maccabees; Psalms (**151 chapters, so Psalm 151 is included**); Odes (14 odes, with Ode 4 split as `iva`/`ivb`); Proverbs; Song of Songs; Job; Wisdom; Sirach (`tlg034…grc2` is Swete; `grc1` is Hart's 1909 Codex 248 edition, **exclude it**); Psalms of Solomon; the Twelve; Isaiah (`tlg048…grc1` is Swete; `grc2` is Ottley's Codex A edition, **exclude it**); Jeremiah (52 chapters in Greek order); Baruch; Lamentations; Epistle of Jeremiah (**no chapter level**, verses only); Ezekiel; Susanna, Daniel, and Bel, each in **both** the Old Greek (`translatio Graeca`) and Theodotion.
- **Missing:**
  - **Ecclesiastes** (`tlg030`): only `__cts__.xml`, no text. Open issue #1973 (2018). An outside contributor offered a corrected file in 2022 (#2579), but it was never attached or merged.
  - **TLG numbers 007, 009, and 022** do not exist in this corpus. In the TLG canon these slots hold Rahlfs's second texts (Joshua A, Judges A, Tobit S). Swete prints Judges and Joshua as single texts, so nothing is lost there.
  - **Tobit's Sinaiticus (ℵ) text.** The B/A text is present and its apparatus cites ℵ readings. Whether Swete Vol. II also prints the ℵ text in full could not be confirmed from the digital files. **Check the Vol. II scan before claiming either way.**
  - **1 Enoch.** Not in `tlg0527` (eliranwong's copy has it, with the blanks noted above).
- **Judges is the B text, not A.** The CTS title says "Judices (Cod. Alexandrinus)," but the apparatus in chapter 1 reads `διὰ τοῦ κυρίου] ἐν κ(υρί)ῳ A` and `τοὺς Χαναναίους] τὸν Χαναναῖον A`. In other words, it records A as the *variant* against the printed text. That fits Swete's practice: B where it exists, other uncials in the apparatus. Label it "Judges (Swete; Codex B)."
- **Swete's base manuscripts, from the marginal sigla in the TEI:** Genesis margins show A, D, and E (B begins only at Gen 46:28). The Psalms in B's lacuna (around LXX Ps 105–137) carry ℵ/A/R/T sigla, with apparatus readings set *against* ℵ. 1 Maccabees margins show ℵ, A, and V (B has no Maccabees). Each of these fits Swete's method: print B, and where B is missing print the next uncial (A or ℵ).

### A3. Known quality issues in #1 (open, unresolved)

The OGL editors themselves said the following in issue #2579 (https://github.com/OpenGreekAndLatin/First1KGreek/issues/2579, 2022):

- "Unfortunately no read-throughs of most texts were done, so many of these data capture issues will not be spotted or resolved."
- "An hour's worth of reading Genesis produced 74 errors/omissions over 56 verses."
- "The project leads wanted to revisit replacing this edition of the LXX with better OCR data capture and versification." No replacement has appeared; the last Septuagint commits (2024-12 to 2025-01) were metadata and URN updates, plus one Latin-to-Greek letter fix (#2779).

I re-checked the reported problems against the current files on 2026-10-06:

| Problem | Example (current file) | Verified |
|---|---|---|
| **Chapter opening replaced by the Roman-numeral chapter head** | Exod 20:1 = `XX`; Num 17:1 = `XVII`; Num 19:1 = `XIX`; 3 Kgdms 16:1 = `XVI`; Deut 32:1 = `XXXII καὶ ἀκουέτω ἡ γῆ…` (Πρόσεχε, οὐρανέ, *Prosekhe, ourane*, "Give ear, O heaven" is lost); also Gen 50:1, Exod 7:1, Josh 6:1, 1 Kgdms 2:1, 1 Kgdms 6:1 | **11 verses** begin with a Roman numeral (3 Kgdms 14:1 is a genuine B absence; the rest are losses) |
| **Final verse merged into the one before it** | Num 30:16 absorbs 30:17 and drops its first word (`δικαιώματα` instead of `ταῦτα τὰ δικαιώματα`, *tauta ta dikaiōmata*, "these are the ordinances"); Gen 16:16 absorbed into 16:15; Gen 15:19 absorbed into 15:18 | Yes |
| **Words lost at line ends** | Ruth 1:2 reads `Μααλὼν καὶ ών` for `Μααλὼν καὶ Κελαιών` (*Maalōn kai Kelaiōn*, "Mahlon and Chilion"), and `εἰς ἀγρὸν` is missing `Μωάβ` (*Mōab*) | Yes (Sollupulo has both) |
| **Misread letters** | `Εὐφμάτου` for `Εὐφράτου` (*Euphratou*, "of the Euphrates"), Gen 15:18; `* κοὶ` in Ruth 2:23 | Yes |
| **Detached breathing marks** | `᾿Ιούδα` written with U+1FBF (spacing psili) before the capital instead of `Ἰούδα`; 31 cases in Ruth alone | Yes |
| **Latin letters mixed into Greek words** | 1,435 mixed-script tokens across the corpus (most in the apparatus); Isaiah's head is `ΗΕΑΙΑΣ` (Latin `E` for `Σ`) | Yes, by script |
| **OCR'd verse numbers** | 2 Chr 4 numbers verse 20 as `220` | Yes |
| **Placeholder codes for Hebrew-letter sigla** | `U+05D0` (א, the siglum for Sinaiticus) appears as literal text in the apparatus and margins | Yes |
| **Apparatus noise** | Footnotes are uncorrected OCR (`κݲςݲ`, `B?vil`) | Yes. Do not ship the apparatus |

**Numbering audit (my script, all 55 works):** 1,083 missing integers inside verse sequences. This is a rough signal, not an error count. Some gaps are genuine Codex B features (1 Kgdms 17:12–31; 1 Chr 1:11–16; 3 Kgdms 14:1–20), some come from OCR'd numbers like `220`, and some are real merges. The worst files are 2 Chronicles (296), Odes (236, mostly the `iva`/`ivb` labels), 1 Esdras (76), 1 Chronicles (70), and Sirach, Psalms, and Jeremiah (around 50 each). The build should produce this report per book and have a person classify each gap once, the same treatment the vault gave Class C gaps.

### A4. Choosing the shipped base

**Ship #1 (First1KGreek TEI), pinned, with build-time repairs. Do not ship #2, #3, #4, or #5.**

Reasons: It is the only complete Swete with a clean, stated license. TEI keeps Swete's structure, including lettered verses (3 Kgdms 2:35a–o, 12:24a–z), unnumbered psalm titles, and prologues. Every derivative (#2, #5, #6, #8) traces back to it, so fixes can be shared.

**Repair path, in order of payoff:**

1. Fix the eleven chapter-opening losses and the known merges by hand from the archive.org scans. The scans are public domain, so hand-keyed text adds no license. Record each repair in a `source_repairs` table.
2. Collate Genesis through 3 Kingdoms against **Sollupulo (#6, CC BY-SA 4.0)**. It is compatible with #1's license, so the combined table stays CC BY-SA 4.0 with both credited.
3. Ecclesiastes: Either leave it absent with an explicit "not in this digital edition" message, or fill it from Brenton's Greek (#11, public domain) with every row labeled "Brenton 1851." **Larry's call.** I recommend the labeled Brenton filler, because a missing book in a default text looks like a bug.
4. Report the repairs upstream to OGL (their declaration-free version of CCAT's "report errors" courtesy).

### A5. Share-alike and attribution

- **What CC BY-SA 4.0 requires** (https://creativecommons.org/licenses/by-sa/4.0/): credit the creator; keep the license notice and a link to it; say whether you changed the material; offer adapted material under the same license; add no further restrictions (no extra terms and no technical locks that limit what users may do with that table).
- **What it reaches in simple_bible:** the Swete text table, its normalized search copies, any token, index, or n-gram table computed from it, and any later Swete lemma layer. These are "Adapted Material" and must be offered under CC BY-SA 4.0. The rest of `core.db` (other texts with other licenses) and the Eiffel program are not adapted from Swete, so they keep their own licenses, but the database must make clear which tables carry which license. Keep Swete in its own tables with `source_provenance` rows (FR-002).
- **Attribution line to ship** (credits file and About page, generated from `source_provenance` per FR-003):

> Septuagint (Swete): *The Old Testament in Greek according to the Septuagint*, edited by Henry Barclay Swete (Cambridge University Press, 1887–1912), public domain. Digital text: First1KGreek, Open Greek and Latin Project, University of Leipzig (https://github.com/OpenGreekAndLatin/First1KGreek, `data/tlg0527`, commit `eb81494`), licensed CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/). Changes by simple_bible: converted from TEI to verse rows; apparatus and marginal notes removed; OCR repairs listed in the `source_repairs` table; normalized search copies added. These Septuagint tables are offered under CC BY-SA 4.0.

  If Sollupulo or Brenton rows are used, add: "Corrections for Genesis–3 Kingdoms from Swete-1909-LXX by Sollupulo (https://github.com/Sollupulo/Swete-1909-LXX), CC BY-SA 4.0." and "Ecclesiastes: Brenton's Greek text (London: Bagster, 1851), public domain, via eBible.org (`grcbrent`); not Swete."
- The TEI headers credit Digital Divide Data ("Corrected and encoded the text") and the Leipzig team (Crane, Berti, Munson, Clérice, and others). A "University of Leipzig / Open Greek and Latin" credit is a reasonable way to name them; listing the individual names in the credits file is better.

### A6. Swete and Rahlfs: the differences that matter to the tool

| Matter | Swete (default) | Rahlfs (private build; optional download later) |
|---|---|---|
| Kind of text | **Diplomatic:** prints one manuscript, Codex Vaticanus (B), and fills its gaps from A or ℵ, with a small apparatus of the main uncials | **Eclectic:** a reconstructed text built mainly from B, ℵ (S), and A ("Vaticanus as the leading manuscript", https://en.wikipedia.org/wiki/Alfred_Rahlfs%27_edition_of_the_Septuagint) |
| Editions | Cambridge, 1887–1912 (Vol. I 4th ed. 1909, Vol. II 3rd ed. 1907, Vol. III 4th ed. 1912, reprinted 1925/1930) | Stuttgart: Württembergische Bibelanstalt, 1935. Revised by Hanhart, © 2006 Deutsche Bibelgesellschaft; the revision changes diacritics plus two words of the main text (Isa 5:17, 53:2), per the same Wikipedia page |
| The CCAT digital text | Not applicable | Keyed by the TLG, then adapted by CATSS "towards conformity with the individual Göttingen editions that have appeared since 1935" (CCAT `0-readme.txt`). So **"CCAT Rahlfs" is not a pure 1935 Rahlfs.** Label it "Rahlfs (CCAT/CATSS digital text)" |
| Judges | One text (B), A readings in the apparatus | **Two texts, A and B** (CCAT files `09.JudgesB`, `10.JudgesA`). Defect E11 applies |
| Joshua | One text | Parts printed twice (CCAT `07.JoshB` 638K, `08.JoshA` 46K) |
| Tobit | B/A text (ℵ text: not digitized; see A2) | Two texts, BA and S (`22.TobitBA`, `23.TobitS`) |
| Daniel, Susanna, Bel | Old Greek and Theodotion | Old Greek and Theodotion (same structure) |
| Esther additions | Addition A as a `prologue` chapter, the rest as lettered verses (`1a`, `1b`…; some OCR-garbled labels such as `1a1`) | Lettered verses inside chapters. The vault's rows are integers only (`verse INTEGER`), so letters were flattened there |
| Psalm titles | Short titles are **unnumbered** (Ps 22, i.e., MT 23: title outside verse 1); long titles are verse 1 (Ps 3) | The vault's Rahlfs row LXX Ps 22:1 = `Ψαλμὸς τῷ Δαυιδ. Κύριος ποιμαίνει με…`, with the title **inside** verse 1 |

### A7. What the versification map (D-010) must handle for Swete

These differences were measured in the Swete TEI and compared against the vault's Rahlfs rows (`Rix/Data/data/bible.db`, version `LXX`, read-only, 2026-10-06):

| Book | Swete | Vault Rahlfs rows | Map need |
|---|---|---|---|
| **Numbers 16–17** | 16:1–50, 17:1–13 (English-style) | 16:1–35, 17:1–28 (Hebrew-style) | Swete 16:36–50 = Rahlfs 17:1–15; Swete 17:n = Rahlfs 17:n+15 |
| **Malachi** | 4 chapters (4:1–6) | 3 chapters (3:19–24) | Swete 4:1–6 = Rahlfs 3:19–24. **FR-021's "Mal 4:1" test case needs a Swete leg** |
| **Joel** | 3 chapters (20 / 32 / 21 verses) | 4 chapters (20 / 27 / 5 / 21) | Swete 2:28–32 = Rahlfs 3:1–5; Swete 3:1–21 = Rahlfs 4:1–21 |
| **Proverbs** | 29 chapters in the Greek order; ch. 24 holds 81 numbered units | 31 chapters | **Verse-level alignment, not offsets** |
| **Psalms** | Greek numbering (LXX 9 = MT 9+10; LXX 22 = MT 23; LXX 118 = MT 119); Psalm 151 | Greek numbering | Shared Greek↔MT table, plus a per-psalm rule for whether the title is verse 0 or part of verse 1 |
| **Jeremiah** | Greek chapter order, 52 chapters (Jer 38 has 40 verses, matching LXX 38 = MT 31) | Greek order | Reuse the vault's verified concordance (defect B2); **re-verify it against Swete** before trusting it, because it was built on Rahlfs |
| **Exodus 35–40** | Greek order (36/37/38/39/40 = 40/21/27/23/32 units) | Same tradition | Verse-level TVTMS rules |
| **3 Kingdoms** | Lettered pluses 2:35a–o, 2:46a–l, 12:24a–z; 14:1–20 absent (B) | Same pluses (flattened in the vault) | Needs a `verse_suffix` column; the vault's integer schema cannot hold these |
| **Esther** | `prologue` chapter plus lettered verses | Lettered | Map Addition A (Swete prologue) to Rahlfs 1:1a–s and so on |
| **Judges / Joshua / Tobit** | One text each | Two texts | Map Swete Judges to Rahlfs JudgesB first (same manuscript), JudgesA second |
| **Daniel 3** | Theodotion 98 units, OG 100 units | 97 verses | Verse-level check (Prayer of Azariah numbering) |
| **Sirach 30–36** | Ch. 30 ends with a `13b` label | Not checked | The Greek manuscripts transpose 30:25–33:13a and 33:13b–36:16a. **Verify** which order each edition prints before mapping |
| **Odes** | 14 odes, Ode 4 split `iva`/`ivb`; Prayer of Manasseh is Ode 12 (both editions) | Same | Odes are numbered by their source books' verses |
| **2 Esdras** | Ezra + Nehemiah as 23 chapters | Same | Already common to LXX mappings |
| **Import gaps vs. real absences** | Chapter-opening losses and merges (A3); Ecclesiastes | Defect register Class C | A flag that separates "missing from this digital text" from "absent from the edition" (1 Kgdms 17–18 short text, 3 Kgdms 14:1–20) |

---

## B. Rahlfs rights: who holds what

### B1. The print edition

- **1935:** *Septuaginta*, ed. Alfred Rahlfs (Stuttgart: Württembergische Bibelanstalt, 1935). Source: CCAT `0-readme.txt` (http://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/0-readme.txt): "LXX = Septuaginta, ed. A. Rahlfs (Stuttgart: Württembergische Bibelanstalt, 1935; repr. in 9th ed., 1971)." The Württembergische Bibelanstalt is a predecessor of today's Deutsche Bibelgesellschaft (DBG), so the DBG is the successor publisher. *Wikipedia says the 1935 edition was "published by the Deutsche Bibelgesellschaft"; that name is anachronistic for 1935.*
- **2006:** *Septuaginta*, ed. Alfred Rahlfs, second revised edition by Robert Hanhart, **"© 2006 Deutsche Bibelgesellschaft, Stuttgart"**. That exact credit line is on the DBG's German licensing page (https://www.die-bibel.de/ueber-uns/lizenzen, fetched 2026-10-06).
- **The DBG's stated position** (https://www.die-bibel.de/en/rights, fetched 2026-10-06): "As our publications are protected by copyright you need a written permission from us to use them, except for some specific cases." The exceptions are single verses in social media and excerpts in free publications of ACK-member churches. Neither covers a whole text in software.
- **Is the 1935 text still protected?** Unsettled, and I give no legal opinion. Rahlfs died in 1935. German law gives critical scholarly editions 25 years (long past). If the text instead counts as an authored work, protection ran 70 years after his death, to the end of 2005, and that could have revived a U.S. term running to the end of 2030. Third-party sites call "Rahlfs 1935" public domain (OpenScriptorium, for one), but **that claim is not a basis for shipping.** The practical route is to ask the DBG, which letter 2 does.

### B2. The CCAT/CATSS digital text (University of Pennsylvania)

- **Location:** http://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/. The directory lists `0-user-declaration.txt`, `0-readme.txt`, `0-betacode.txt`, `*Morph-Coding`, `*ReadMe.Analysis`, and 64 `.mlxx` files (Beta Code, morphologically tagged). Dates run from 1994 to 2019 (Ruth was updated 2019-10-21). **Plain HTTP works; HTTPS has the TLS certificate error reported earlier.**
- **The user declaration, verbatim key clauses** (`0-user-declaration.txt`, "USER AGREEMENT / DECLARATION (version 050215)", fetched 2026-10-06):

> "In accepting materials distributed by or through CCAT, the recipient agrees to observe the following "fair use" provisions:
> (1) Not to use or make available these materials for commercial purposes without first obtaining the written consent of the owners/encoders;
> (2) To observe any special restrictions that may govern the use of particular texts or bodies of material as stipulated in the aforementioned documentation;
> (3) To control access to these materials and require any other party to whom the recipient supplies any portion of this material to observe these conditions and to register a signed USER AGREEMENT form with CCAT;
> (4) When making formal public reference to the materials, to acknowledge appropriately the holder of the copyright to any published text that has been encoded as well as to the encoder and the source from which the machine-readable form has been obtained, to the extent that these details are supplied in the aforementioned documentation. Unless otherwise noted, CCAT is the legal owner of the software and documentation being distributed.
> (5) To report promptly to CCAT any errors discovered in these machine-readable materials or problems with the software."

  The `0-readme.txt` repeats the rule: "If copies are made and given to other persons for NON-COMMERCIAL use, those persons are also required to register with CCAT by completing the standard "User Declaration"… This is for legal and collaborative purposes only; no fees are involved."

- **Why this blocks bundling.** Clause (3) makes the *distributor* responsible for getting every recipient to register a signed form. A public installer cannot do that. This is the clause to ask about. The non-commercial clause (1) is not the obstacle for a free tool.
- **Who did what** (from `0-readme.txt`):
  - "CATSS LXX = The computer form prepared by the TLG (Thesaurus Linguae Graecae) Project directed by T. Brunner at the University of California, Irvine, with further verification and adaptation (in process) by CATSS…"
  - "LXXM = The morphologically analyzed text of CATSS LXX prepared by CATSS under the direction of R. Kraft (Philadelphia team)."
  - Kraft, as quoted in the eliranwong/LXX-Rahlfs-1935 README: "much of the CCAT material is also derivative (from TLG, e.g.) and with various permissions (from UBS, e.g.), which deserve to be acknowledged."
  - So there are three possible holders: the **DBG** (the Rahlfs text), the **TLG** (the keyed text), and **CCAT/Penn** (the morphology, the adaptation, and the distribution terms).
- **Contacts named in the declaration:** "227 Logan Hall, Philadelphia PA 19104-6304; Tel 215 898 5827; Email kraft at ccat.sas.upenn.edu."
  - **Professor Robert A. Kraft died on 2023-09-15** (Penn Almanac, https://almanac.upenn.edu/articles/robert-kraft-religious-studies; Philadelphia Inquirer, https://www.inquirer.com/obituaries/robert-kraft-obituary-religious-studies-philadelphia-pennsylvania-computer-20231004.html). The obituary names no successor for CCAT or CATSS, and **no current CCAT steward could be verified.**
- **Current verifiable channel: Penn Department of Religious Studies** (https://rels.sas.upenn.edu/people/staff, fetched 2026-10-06):
  - Address: 201 Cohen Hall, 249 S. 36th Street, Philadelphia, PA 19104-6304.
  - Administrative Coordinator: Maeve Malone, [contact kept privately], [phone kept privately].
  - Department Chair: Justin McDaniel ([contact kept privately], from https://rels.sas.upenn.edu/people). *The page footer names him as chair, but the body text of https://rels.sas.upenn.edu/welcome still names Jamal J. Elias, so that page is stale.*
  - Letter 1 goes to Maeve Malone and asks her to route it.

### B3. The morphology (CATSS LXXM)

Held by CCAT/Penn under the same declaration. **It matters only if simple_bible ever ships Rahlfs lemmas and parsing.** For the optional Rahlfs download it would be worth asking for. Letter 1 asks for it as a separate, optional item so that a "no" on the morphology does not sink the text request. The CrossWire `LXX` module, built from CCAT and labeled "Copyrighted; Free non-commercial distribution," suggests CCAT has allowed free software to use the text. Whatever terms CrossWire has are its own, though, and do not carry over to simple_bible.

### B4. The TLG (keyed the base text)

- Thesaurus Linguae Graecae, University of California, Irvine. Project Director: Maria Pantelia. Email: **[contact kept privately]**. Both appear on https://stephanus.tlg.uci.edu/contact.php, fetched 2026-10-06.
- A short courtesy letter (letter 3) asks whether the TLG claims any rights in the CATSS LXX. Whether it is needed depends on what Penn says; sending it at the same time saves a round trip.

### B5. The Deutsche Bibelgesellschaft: current contact channels (checked 2026-10-06)

| Page | What it says |
|---|---|
| https://www.die-bibel.de/en/rights (English) | Complete texts: "please outline your project briefly by writing and turn to us." Questions: **Ilona Raiser**, Permissions and Royalties Manager, +49 711 7181-244, **[contact kept privately]**. Form for verses, chapters, or books: https://www.die-bibel.de/en/permission-enquiry-form |
| https://www.die-bibel.de/ueber-uns/lizenzen (German) | For the complete text of an edition, write to "Deutsche Bibelgesellschaft, z.Hd. Frau **Béatrice Gerhard**, Balinger Str. 31A, 70567 Stuttgart, E-Mail: **[contact kept privately]**, Tel.: 0711/7181-244." The same page uses **[contact kept privately]** as a general license inbox |
| https://www.die-bibel.de/ueber-uns/ansprechpartner (German) | "Rechte und Lizenzen" (Rights and Licenses): **Dr. Florian Voss**, Leiter Lizenzen (head of licensing), +49 711 7181-202, **[contact kept privately]**; Béatrice Gerhard, Abdruckanfragen und Honorare (reprint requests and fees), +49 711 7181-244, [contact kept privately] |

The English and German pages name different people for the same extension (-244), so one of them is out of date. **Send to [contact kept privately] with copies to [contact kept privately] and [contact kept privately].** This is a request for a complete edition, so the web form (meant for verses, chapters, or books) is the wrong channel. Postal address: Deutsche Bibelgesellschaft, Balinger Straße 31 A, 70567 Stuttgart, Germany.

---

## C. Permission letters

Three permission-request drafts (University of Pennsylvania CCAT/CATSS, Deutsche Bibelgesellschaft, TLG) exist and are kept privately until they are sent. Contact routes: the rights pages cited in section B and in Sources.

## What the build must do (checklist)

**Source and license gate**
- [ ] Pin First1KGreek at `eb81494731fd632f582c4b94634127bdbd596b43`. Store the SHA-256 of each TEI file and the license URI in `source_provenance` (FR-002, FR-004).
- [ ] Use `grc1` for every work except Sirach (use `grc2`) and Isaiah (use `grc1`; exclude `grc2`, which is Ottley). Exclude Hart's Sirach (`tlg034…grc1`) and all `eng`/`mul` files.
- [ ] Mark the Swete tables as `license = CC BY-SA 4.0` with `share_alike = true`, and keep them in their own tables.
- [ ] Rahlfs (CCAT) rows stay `ship = false` until written permission is filed (D-011).

**Parsing and repair**
- [ ] Drop `<note type="footnote">` (OCR'd apparatus) and `<note type="marginal">`. Keep `<head>` only as metadata.
- [ ] Rejoin words hyphenated across lines.
- [ ] Attach detached breathings (U+1FBF and U+1FFE before a capital) to the following letter.
- [ ] Map Latin look-alike capitals to Greek and remove `U+05D0`-style placeholders. Apply NFC.
- [ ] Keep lettered verses (`35a`, `24z`), unnumbered titles and prologues (verse 0), the Esther `prologue`, Odes `iva`/`ivb`, and the Epistle of Jeremiah's verse-only structure. This needs a `verse_suffix` column.
- [ ] Fail the build if any verse begins with a Roman numeral (currently 11), unless a `source_repairs` row covers it. Repair those verses from the archive.org scans.
- [ ] Produce the numbering-gap report per book (currently 1,083 raw gaps). Every gap must be classified once as `genuine-B`, `ocr-number`, or `merge`, and merges must be repaired or flagged.
- [ ] Collate Genesis through 3 Kingdoms against Sollupulo (CC BY-SA 4.0) and log every difference.
- [ ] Ecclesiastes: either absent with an explicit message, or Brenton rows with `edition = 'Brenton 1851'` (Larry's call).

**Attribution and share-alike notice**
- [ ] Generate the attribution line in A5 into the credits file and the About page from `source_provenance` (FR-003).
- [ ] Add the share-alike notice next to the export and copy functions: "Swete Septuagint text: CC BY-SA 4.0. If you share this text or anything made from it, credit the sources above and share it under the same license."
- [ ] No extra terms or technical locks on the Swete tables.

**Edition labeling in the UI**
- [ ] Never show a bare "LXX". Use "LXX (Swete)" for the default and "LXX (Rahlfs, CCAT/CATSS)" in the private build. Brenton filler rows say "Brenton 1851".
- [ ] On the Swete label, add a tooltip: "Codex Vaticanus as printed by H. B. Swete (Cambridge, 1887–1912). Digital text from OCR; it may contain errors. Report one: [link]."
- [ ] Label two-text books by text: "Daniel (Old Greek)" and "Daniel (Theodotion)"; "Judges (Swete; Codex B)" next to "Judges A" and "Judges B" when Rahlfs is present.
- [ ] When a verse is missing, say whether the edition lacks it or the digital text lost it.

**Versification map entries (D-010 / FR-022)**
- [ ] Add a `swete` system next to `rahlfs_ccat`, `mt`, and `kjv`.
- [ ] Entries for: Numbers 16–17, Malachi 3/4, Joel 2–4, Proverbs (verse-level), Psalms (Greek↔MT plus the per-psalm title rule), Jeremiah (the vault concordance, re-verified on Swete), Exodus 35–40, 3 Kingdoms lettered pluses, Esther additions, Judges/Joshua/Tobit single↔double texts, Daniel 3, Sirach 30–36 (verify the order first), Odes, and 2 Esdras.
- [ ] Extend the FR-021/FR-022 regression tests with Swete legs: Mal 4:1 (Swete) = Mal 3:19 (Rahlfs, Hebrew); LXX Ps 22:1 with and without the title; LXX Jer 38:31 = MT Jer 31:31 = Heb 8:8; Num 16:36 (Swete) = Num 17:1 (Rahlfs).

---

## Sources (fetched or returned 2026-10-06)

- First1KGreek: https://github.com/OpenGreekAndLatin/First1KGreek (tlg0527 folder, `__cts__.xml` files, TEI headers); issues #2579, #2577, #2576, #2578, #1973, #2779, #2810, #2835
- nathans/lxx-swete: https://github.com/nathans/lxx-swete (README, `utils/convert-swete.py`, issues)
- eliranwong/LXX-Swete-1930: https://github.com/eliranwong/LXX-Swete-1930 (README, file tree, issues #1–#5)
- OpenGreekAndLatin/septuagint-dev: https://github.com/OpenGreekAndLatin/septuagint-dev
- sleeptillseven/LXX-Swete: https://github.com/sleeptillseven/LXX-Swete (README, `license.md`, `texts/DONE`)
- Sollupulo/Swete-1909-LXX: https://github.com/Sollupulo/Swete-1909-LXX (README, `LICENSE.txt`, Ruth file)
- Mallioch/swete-lxx: https://github.com/Mallioch/swete-lxx
- brainheart/septuagint-contabulate: https://github.com/brainheart/septuagint-contabulate (`SOURCES.md`, `DATA-LICENSE.md`)
- cbop-dev/biblical-lexeme-explorer: https://github.com/cbop-dev/biblical-lexeme-explorer
- OpenScriptorium: https://github.com/OpenScriptorium/OpenScriptorium
- openscriptures/GreekResources: https://github.com/openscriptures/GreekResources
- eliranwong/LXX-Rahlfs-1935: https://github.com/eliranwong/LXX-Rahlfs-1935
- eBible.org Brenton Greek: https://ebible.org/Scriptures/details.php?id=grcbrent
- CrossWire LXX module: https://www.crosswire.org/sword/modules/ModInfo.jsp?modName=LXX
- CCAT directory and files: http://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/ (`0-user-declaration.txt`, `0-readme.txt`, `*ReadMe.Analysis`, `*web-version.html`)
- Penn Almanac obituary: https://almanac.upenn.edu/articles/robert-kraft-religious-studies ; Inquirer: https://www.inquirer.com/obituaries/robert-kraft-obituary-religious-studies-philadelphia-pennsylvania-computer-20231004.html
- Penn Religious Studies: https://rels.sas.upenn.edu/people/staff ; https://rels.sas.upenn.edu/people ; https://rels.sas.upenn.edu/welcome
- TLG: https://stephanus.tlg.uci.edu/contact.php
- Deutsche Bibelgesellschaft: https://www.die-bibel.de/en/rights ; https://www.die-bibel.de/ueber-uns/lizenzen ; https://www.die-bibel.de/ueber-uns/ansprechpartner ; https://www.die-bibel.de/en/permission-enquiry-form
- Rahlfs background: https://en.wikipedia.org/wiki/Alfred_Rahlfs%27_edition_of_the_Septuagint
- CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/
- Vault: `Rix/Data/_bible.db Defect Register.md` (A1, B1, B2, E5, E11, Class C), `Rix/Data/_bible.db Provenance.md`, `Rix/Data/_Text Credits (paste-ready).md`, and `Rix/Data/data/bible.db` (read-only queries of version `LXX`)
