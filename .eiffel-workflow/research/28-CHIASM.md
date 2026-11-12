# 28: CHIASM (chiasm.db)

*Started 2026-11-11, Larry: "sooner" (CHIASM ahead of INCIPIT steps 3 and 6). Plan: the doc "INCIPIT and CHIASM: Plan for simple_bible", sections CHIASM (reader) and CHIASM (how found and graded). His decision there: load all of Bullinger and grade it by the chance test.*

## What the reader gets

- Marks: a margin bracket spanning the chiasm; letters A, B, C ... C', B', A' beside its parts; matching pairs share a color; the center highlighted. All / strong only / off.
- Hover card: extent, size (four-line ABBA to a whole book), who proposed it, how strong.
- Panel: the ladder (parts indented to the center and back, pairing words lit), the center and what it says, who saw it (rival structures side by side), measured strength, Larry's reading where his work treats it (labeled as in INCIPIT), nesting.
- Browse: by book, size, strength; a book-outline view.

## Sources

| Source | State | License |
|---|---|---|
| Bullinger, *The Companion Bible* (1909-1922), digital edition by C. T. Haywood (2005), archive.org `CompanionBible.Bullinger.1901-Haywood.2005` | OCR text of OT (7.3 MB) and NT + Appendixes (4.8 MB) downloading 2026-11-11 | item marked public domain (creativecommons publicdomain); the book is pre-1930 |
| Boys, *Tactica Sacra* (1824), *A Key to the Book of Psalms* (1825) | scans located (archive.org `tactica-sacra`, `akeytobookpsalm00boysgoog`) | public domain |
| Jebb, *Sacred Literature* (1820) | located (`sacredliterature00jebb`) | public domain |
| Forbes, *The Symmetrical Structure of Scripture* (1854) | located (`symmetricalstruc00forbiala`) | public domain |
| Larry's DNP studies | divine-name chiasms and chiastic blocks (vault Divine Name Pattern, 16 files mention chiasm) | the author's own work |

Seeding only: Lund 1942, Welch 1981 and his criteria, Blomberg 1989, Dorsey 1999.

## Grading (to build)

Each pair A/A', B/B' ... measured by shared headwords weighted by rarity (conc.db: WLC Hebrew, WH Greek, Rahlfs LXX), the INCIPIT way; the whole tested against chance by cutting the same passage into the same number of parts and pairing at random many times; the center checked for words or themes found nowhere else in the structure. Grades: strong / moderate / thematic only / disputed.

**Grader built (2026-11-11, session scratchpad `chiasm/tools/chiasm_grade.py`).** Pair score = rarity-weighted shared headwords over the geometric mean of the two members' rarity mass (0 to 1); whole = mean pair score; chance = 2,000 random perfect matchings of the same non-center members; p = share scoring at or above the real pairing; center_own = share of the center's rarity mass found in no other member. Grades: strong p < 0.01, moderate p < 0.05, thematic otherwise, too_small with 3 pairs or fewer (15 or fewer matchings: the test cannot reach p < 0.05 meaningfully). Old Testament words from WLC via the KJV-to-Hebrew map read backward; New Testament from WH.

First case, Bullinger's Genesis 6:9-9:29 (the generations of Noah, A-E E-A): **strong, p = 0.009**, whole 0.288; pairs A 0.176, B 0.348, C 0.275, D 0.193, E (entering and leaving the Ark) 0.447.

Source check: the Companion Bible OCR (Haywood digital edition) downloads only through PowerShell (curl stopped at archive.org's 302); OT 7,340,934 bytes, NT + Appendixes 4,772,279 bytes. Structures read as a header (range, page tag, TITLE, kind in parentheses) and lettered members "A | 6. 9. label" with OCR noise (| read as I, j, l; 11 as n or "1 1"). A helper is parsing them (`bullinger_structures.json`).

**Bullinger parsed (helper, 2026-11-11, `chiasm/tools/parse_structures.py`, `bullinger_structures.json`):** 2,593 structures (OT 1,773, NT 820), 1,244 mention Introversion, 13,374 members (1,088 repaired from OCR, 50 unresolved); 438 read as a mirror after repair. Hand spot check 135 of 142 parsed members OK (95%); 5 member lines dropped. Known problems: garbled member letters (A read as J, ft), dropped lines, chapterless headers in Psalms, note fragments in titles.

**Grading, version 1 on the parse:** only 150 graded, 138 "too small" (Bullinger's top levels are mostly 2-3 pairs), and Noah fell to thematic (p 0.13) because the parse kept OCR "6. 1 1" as 6:11 (overlapping C) where the text is 6:10. Lesson: one OCR digit decides a grade.

**Version 2 (`chiasm_grade2.py`):** overlap repair (a member that runs into the next while a gap stands before it moves into the gap), nested levels graded, and a shape test for any size (the same member lengths and pairing laid at 500 random places in the same book; p_shape). Result: 123 mirrors graded (6 overlaps repaired; 86 left out because their members still do not run in order): strong 12, moderate 11, thematic 95, untestable 2 (3 of the 123 are nested). Noah strong again (p_shape 0.006, p_pairing 0.009). Strong include 1 Chronicles 17-22 (the temple, CDEDC), 2 Chronicles 2:1-7:11, Matthew 26:47-27:10 (the betrayal, PQRTRQP), Matthew 5:17-7:12, Leviticus 16 (the Day of Atonement), 1 Kings 6, Jeremiah 21-35. False mirrors still pass the letter test: Psalms 137-144 "LMLMLML" is an alternation that happens to read the same both ways; "NN?NN" and "?????" are garbled letters.

**Coverage gap to close next:** 438 mirrors parsed, 123 graded. Causes: members out of order (86), letters lost to OCR, nested levels barely detected. Fixes: letters inferred from the mirror's position, alternations told from introversions by the printed kind, nested levels read from indentation.

**Second parse pass (helper, `run_v2.py`, `bullinger_structures_v2.json`):** order repair (289 members re-read so members run in order; Noah's B now 6:10), 580 letters inferred from position on introversion levels only, `pattern` per structure and per nested level (Psalms 137-144 now an alternation). Patterns: alternation 1,080, introversion 825, extended alternation 308, mixed 311, no members 69. Mirrors: 605 of 825 mirror_ok, 579 gradable. Unresolved members rose from 50 to 217 (no reading restores order: the parser refuses to guess). Depth from letter case and line order (archive.org did not serve the djvu XML for indentation). Spot check 139 of 171 members OK (81%; 89% leaving out one structure whose book was misread).

**Grading version 3 (`chiasm_grade3.py`) on the second pass:** 282 mirrors graded (179 left out: members still not in order): strong 18, moderate 35, thematic 222, untestable 7; depth 0: 11 strong, 19 moderate, 119 thematic; nested: 7 strong, 16 moderate, 103 thematic. Strong include Genesis 6:9-9:29 (p 0.006), Leviticus 23, 1 Chronicles 17-22, Matthew 5:17-7:12, Matthew 26:47-27:10, Acts 3:1-11, Acts 15:1-35, Luke 1:68-79 (the Benedictus), Leviticus 26:3-42, Jeremiah 21-35. Letters still muddled in some strong ones (Leviticus 23 "TUTWWWWTUT", Psalm 145 "NNONN"): hand check before the panel shows them. Psalm 22:1-6 (Bullinger, TUUT) thematic, p 0.91. Isaiah 6 has no Bullinger structure in the parse.

**Round 2 (2026-11-12, Larry: "more CHIASM and then finish INCIPIT"):**
- Third parse pass: the "out of order" mirrors were mostly Bullinger's verse splits ("17-" then "-17"), not misreads. v3 adds `verse_from`/`verse_to` (a shared verse to the earlier member). Grader v4 on them: 316 graded (21 strong, 36 moderate, 246 thematic, 8 untestable).
- Larry's own structures (helper gather from the vault, 53; kept SETTLED and DRAFT at high or medium confidence: 47; left out debate seats, others' voices, and Genesis 49 whose arms the helper had to guess): 40 inclusios, 5 introversions, 2 alternations. Grader v5 grades a frame (inclusio) by the shape test: 3 strong (Exodus 15, 2 Samuel 8, Psalm 8), 11 moderate, 25 thematic. Caution: a frame built on the divine name grades thematic though real (the measure counts rare words; YHWH is common); the Psalter bookend p = 1.0.
- Older lists (helper): Boys, Key to the Psalms (81 parsed) and Tactica Sacra (17; its Greek epistle tables lost to OCR), Jebb (5), Forbes (9); kept high and medium confidence: 70 (Boys 62, Forbes 6, Jebb 2). Jebb prints no letters and Forbes only for Philemon: letters assigned from the author's prose, marked inferred. Graded 1: their members are half-verse lines, below the grader's whole-verse grain; shown ungraded.
- Pack: schema gains pattern `inclusio` and the author voice; builder gives each source its own provenance row (Bullinger, grader, Larry, Boys, Jebb, Forbes) and Larry's rows the author's voice; the Chiasm tab a From column. Merged manifest 2,567 structures: 24 strong, 48 moderate, 271 thematic, 9 untestable, 2,215 not graded.
- Reading gutter: the member letter on its first verse, "|" down its later verses; View menu strong and moderate (default) / every mirror / off. A real bracket drawn beside the rows needs a simple_widgets feature (SW_PARALLEL_TEXT), left for a port-branch PR.

## chiasm.db, version 1 (draft)

A private pack in the INCIPIT pattern: BIB_CHIASM_SCHEMA (heir of BIB_PRIVATE_PACK_SCHEMA), BIB_CHIASM_BUILDER (`bible_build --chiasm <chiasm.structures.json>`), BIB_CHIASM_PACK, SIMPLE_BIBLE.chiasm_packs. Keyed in the English (KJV) numbering the reader shows, which is Bullinger's own: no LXX mapping. Every table carries NOT NULL `voice` and `provenance_key` (the pack rule). Bullinger rows: voice "hold loosely (datum only)" (read from a scan); grades and scores: the measure's.

```sql
CREATE TABLE structure(
  structure_id INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES structure(structure_id),   -- a nested level's parent; NULL at the top
  under_letter TEXT NOT NULL,                              -- the parent member's letter ('' at the top)
  book_id INTEGER NOT NULL CHECK (book_id BETWEEN 1 AND 66),
  ch_from INTEGER NOT NULL, v_from INTEGER NOT NULL, ch_to INTEGER NOT NULL, v_to INTEGER NOT NULL,
  title TEXT NOT NULL,
  kind_printed TEXT NOT NULL,                              -- as the source prints it
  pattern TEXT NOT NULL CHECK (pattern IN ('introversion','alternation','extended_alternation','mixed')),
  source TEXT NOT NULL CHECK (source IN ('bullinger','boys','jebb','forbes','larry','measure')),
  grade TEXT NOT NULL CHECK (grade IN ('strong','moderate','thematic','untestable','not_graded')),
  whole REAL, p_shape REAL, p_pairing REAL, center_own REAL,
  repaired INTEGER NOT NULL,                               -- members repaired from the scan
  voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key));
CREATE TABLE member(
  structure_id INTEGER NOT NULL REFERENCES structure(structure_id),
  seq INTEGER NOT NULL,
  letter TEXT NOT NULL, letter_inferred INTEGER NOT NULL,
  ch_from INTEGER NOT NULL, v_from INTEGER NOT NULL, ch_to INTEGER NOT NULL, v_to INTEGER NOT NULL,
  label TEXT NOT NULL,
  pair_seq INTEGER,                                        -- its partner's seq; NULL for the center or an alternation
  pair_score REAL,
  repair TEXT NOT NULL,                                    -- '', 'order', 'ocr'
  voice TEXT NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key),
  PRIMARY KEY (structure_id, seq));
CREATE INDEX structure_place ON structure(book_id, ch_from, v_from);
```

Reader queries: structures covering a verse (innermost first), a structure's members with pairs, a book's structures by strength.

## Steps

1. Parse Bullinger's structures from the OCR (letters, indents, references, the short label on each member).
2. Map each member's reference range to verses; validate against versification.
3. Grade (pairs, whole against chance, center).
4. chiasm.db schema (voice and provenance_key on every table: the pack rule), builder, reader, tests.
5. Reader: margin brackets and the ladder panel.
