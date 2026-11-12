# 26: THE OLD TESTAMENT IN THE NEW (incipit.db)

*Started 2026-11-11. Larry's charge, in his words:*

1. Find free sources for the quotations, allusions, and echoes.
2. Figure a way to measure "volume" or "loudness" derivatively and apply it.
3. Do this research ourselves, even if we use copyrighted or restricted sources as seeding for understanding how scholars think.
4. The goal is an `incipit.db` that links the Old Testament to the New, with the LXX as the basis, since first-century readers used the LXX for precisely this reason (and more).

Status: research only. No code, no spec change, no debate cycle yet.

---

## 0. The plan for the reader (given to Larry 2026-11-11)

Promise: when an NT writer uses the OT, the reader sees it, hears the whole passage behind it, and sees how it frames the story; reading the OT, the reader sees where the NT takes it up.

1. **Marks while reading** (both directions): solid quotation, dotted allusion, faint echo; margin dot; show all / loud only / off; filter by kind.
2. **Hover card:** source (with LXX number), kind, loudness, witnesses.
3. **Incipit panel on click:** source story in beats with borrowed words lit; every use in this scene; how it frames the story (labeled Larry / Claude's take); the evidence (NT Greek beside LXX Greek, shared words highlighted, Hebrew where easy); other NT uses; links into Larry's essays, frameworks, commentary. Reading the OT: the forward story.
4. **Browse and search:** Incipit list sortable by OT book, NT book, kind, loudness; queries such as every NT use of Isaiah 53, every source behind Hebrews, every use of Wisdom or 1 Enoch.
5. **Map:** arcs OT book to NT book, thickness by use; click to the links.
6. **Labels everywhere:** measured / named by scholars / Larry approved / Claude's take.

Build steps: A links (incipit.db v1: UBS + Hühn + measured, LXX keys, declared kind definitions, bible_build); B reading (marks, card, panel, both directions; Psalm 22 first); C finding (list, search scope, map); D stories at scale (vault batches, most-used sources first, Larry reviews); E widening (Hebrew second look, 1 Enoch via the Enoch shapes, Dittmar). Open: Approve / Change buttons in the panel, or review in the vault?

## 1. Goal

One database of links from an Old Testament passage (keyed in LXX numbering) to a New Testament passage, each link carrying:

- its **kind**: incipit (opening words that name the whole passage), quotation, allusion, echo, or word link (gezerah shavah: two passages joined by a shared key word);
- its **volume**: a measured loudness, derived from the text and calibrated against the scholars' own lists (section 4);
- its **witnesses**: which independent lists name it, so a reader sees who else heard it;
- the **source passage's extent**: the whole unit the fragment points to (Psalm 22 entire, with its turn at 22:21b/22b), so the reader can open the whole and not just the verse.

**The reader's view (Larry, 2026-11-11, considering):** "one can read and visually 'see' where known or possible 'incipit' links are being used and how they frame the story. For example, one might read Matthew putting Psalm 22:1 in the mouth of Jesus, and simple_bible tells you the story of Psalm 22 in plain simple terms." Proposed shape:

- marks in the reading text, weight by volume (solid quotation, dotted allusion, faint echo), a margin dot per verse; hover card with source, kind, volume, witnesses;
- click opens an Incipit panel: (1) the source passage's story in plain terms, in beats, matched words lit; (2) every use of it in this NT scene (Matthew 27:35, 39, 43, 46 for Psalm 22); (3) how it frames the story; (4) other NT uses (Hebrews 2:12);
- incipit.db tables: links (NT range, OT range in LXX numbering, kind, volume, text followed), witnesses, source passages (whole unit plus story beats), framings (text, status: draft / reviewed by Larry / measured);
- links and volumes are measured; stories and framings are written content, drafted in the vault, reviewed by Larry, built by bible_build, labeled apart from measured facts. UBS alone points to about 250 source passages.

**Both directions, and the stories are AI work in Larry's rails (Larry, 2026-11-11):** "not only will the INCIPIT tool give you the link, but we will need some AI work by you to tell the story in keeping with my frameworks/dossiers/controversy-labs/essays/sermons/et al — the story of the incipit link in its NT context. The other side will be OT links when reading the OT."

- Reading the NT: the source passage's story, and how this NT scene uses it (one framing per NT scene cluster, such as Matthew 27:35-46 with Psalm 22).
- Reading the OT: where the NT takes this passage up, and what it becomes there (one forward story per source passage, such as Psalm 22 in Matthew, Mark, John and Hebrews).
- Same link rows both ways; three kinds of written content: source story, NT scene framing, OT forward story.
- Drafts are grounded in his corpus (vault Scholars/Rix: Frameworks, Dossiers, Controversy Lab, Substack Essays, SermonCentral, Commentaries, Books, DNP), follow the essay Production Manual's rails (Hebrew, LXX, ANE and first-century witnesses; Reformers only as foil; never audit his words), cite where they draw from (link targets into his packs), report any difference from his earlier work as information, and carry a status (draft / reviewed by Larry). A grep on 2026-11-11 found Psalm 22 in 20 vault areas (Data 30 files, Controversy Lab 23, DNP 22, Substack Essays 11, Frameworks 7, Dossiers 4, SermonCentral 3, Commentaries 3, among others).

What exists today in simple_bible: spec skeletons only. FR-030 "They Chose" (`src/quotation/`) compares one quotation's wording against the LXX and the MT. `BIB_QUOTATION_DETECTOR` (`src/reference/`) finds unnamed quotations by word runs of 6 or more. `BIB_CROSS_REFERENCE` (`src/hub/`) holds OpenBible links. None covers allusions, echoes, recurrence, word links, or volume.

## 2. Sources

### 2a. Free to ship

| Source | What it gives | License | Checked |
|---|---|---|---|
| **UBS Paratext Parallel Passages** (`ubsicap/ubs-open-license`, `parallel passages/ParallelPassages.xml`, 336,250 bytes) | 2,193 parallel passages, of which **249 join the OT to the NT (421 OT-to-NT verse pairs)**. Each word carries a mark: 0 no match, 1 partial, 2 full (3-8 repeat 0-2 with line breaks). For OT verses quoted in the NT the marks apply to the **LXX words**, per its README. Quotations only: Psalm 22 has 3 rows (22:2 to Matthew 27:46 and Mark 15:34; 22:19 to John 19:24; 22:23 to Hebrews 2:12), no Mark 15:29 or Matthew 27:43. Psalm numbers are Hebrew. | CC BY-SA 4.0 (© 2023 United Bible Societies) | Downloaded and counted 2026-11-11 |
| **Hühn, *Die messianischen Weissagungen*, volume 2 (1899/1900), "nebst Erörterung der alttestamentlichen Citate und Reminiszenzen im Neuen Testamente"** (archive.org `diemessianischen02hhne`, OCR text 718,558 bytes) | Arranged by NT book and verse. **Includes reminiscences (allusions)** and apocryphal parallels. Mark 15 reads: 15:24 (Ps 22:19), 15:29f (Ps 22:8; compare Ps 109:25, Job 16:4, Lam 2:15, Wisdom 2:13-17), *15:34 (Ps 22:2). An asterisk appears to mark direct quotation (to confirm from the preface). | Public domain | OCR text downloaded; parsing needs care: verse numbers lose their spacing ("2735" = 27:35) and some digits read as letters ("ı" for 1) |
| **Dittmar, *Vetus Testamentum in Novo* (1899-1903)** (archive.org `vetustestamentum00ditt`, OCR 1,112,187 bytes) | The fullest old list: OT parallels of the NT with the Hebrew, the LXX and the NT wording printed side by side, including apocrypha and pseudepigrapha. | Public domain | OCR of the Greek/Hebrew columns is poor; the reference lines are the usable part. Needs a vision-OCR pass or hand review |
| **Toy, *Quotations in the New Testament* (1884)** (archive.org `quotationsinnewt00toycuoft`) | Each quotation discussed against the Hebrew and the LXX. | Public domain | Scan located |
| **Turpie, *The Old Testament in the New* (1868)** (archive.org `OldTestamentInTheNew`) | Quotations classed by agreement with the Hebrew and the LXX. | Public domain | Scan located |
| **Swete, *An Introduction to the Old Testament in Greek* (1900)** (archive.org `introductiontool00swet`, also EPUB) | Part III, chapter 2: quotations from the LXX in the NT, with tables. The same Swete whose LXX text we ship. | Public domain | Scan located |
| **OpenBible.info cross references** | Already in content.db: 344,799 rows with votes. Broad, crowd-voted, no kind. Good as one witness and a candidate generator; not a classification. | CC BY | In content.db |
| **Treasury of Scripture Knowledge** (19th century) | About 500,000 references, no kinds. A witness only. | Public domain | Not yet located in a clean digital form |

### 2b. Seeding only (study how scholars decide; do not ship)

- **Luke Plant, Bible Quotation Database** (`spookylukey/bible-quotation-database`; SQLite, CSV, JSON). Direct quotations only, built from bible-researcher.com and kalvesmaki.com. **No license in the repository** (GitHub API, 2026-11-11), so it is seed only.
- UBS GNT index (about 340 quotations, over 2,000 allusions), Nestle-Aland margins and *Loci citati vel allegati*, Beale and Carson, *Commentary on the New Testament Use of the Old Testament* (2007), Hays, *Echoes of Scripture in the Letters of Paul* (1989) and *in the Gospels* (2016), Archer and Chirichigno (1983). Copyrighted. Use them to learn the categories and to check our results, never as rows.

## 3. The text we measure against

- **LXX with lemmas:** only Rahlfs (CATSS) has lemmas. In conc.db it is corpus LXX-RAHLFS, 623,693 tokens, marked research only (D-011). conc.db also holds token-level `translation:MT->LXX` links and a Hebrew-to-LXX verse map (`unit_map`, 52,378 rows). Swete (what we ship) has **no open lemmas** (research 12).
- **NT with lemmas:** in conc.db (MorphGNT/STEP corpora; to confirm by name).
- **Consequence:** the personal edition can measure on Rahlfs now. A public `incipit.db` holds only references and scores, never Rahlfs text, but it is derived from research-only data; whether that may ship is Larry's call (open question Q3).

## 4. Measuring volume, derived rather than set by hand

Hays named seven tests (availability, volume, recurrence, thematic coherence, historical plausibility, history of interpretation, satisfaction). Three can be counted: volume (its wording part), recurrence, and history of interpretation (the witnesses). Availability and historical plausibility are partly data and act as filters (the source existed and in which form, LXX or Hebrew; its date). Thematic coherence and satisfaction are judgments and stay labeled as such. Hays meant recurrence within one writer's work; widening it to the nearby context and to other NT books (feature 5) is our extension, not his.

**Features for a candidate pair (LXX span, NT span):**

1. **Shared words, weighted by rarity.** Sum over shared lemmas of inverse frequency (from `lemma_corpus_count` over LXX plus NT). Ten shared common words are quiet; two rare shared words are loud.
2. **Exact form over lemma.** A shared surface form scores above a shared lemma in another form.
3. **Order and contiguity.** Longest common ordered run of lemmas; the longest unbroken run.
4. **Distinctiveness.** How many *other* LXX passages share the same rare set. If only Psalm 22 has it, the link points there; if fifty passages do, it is common speech.
5. **Recurrence.** Other links from the same NT context (a few verses either side) into the same OT chapter, and other NT books using the same OT passage. This is what makes the Passion narrative's Psalm 22 cluster loud as a whole.
6. **Markers.** An introductory formula (γέγραπται, ἵνα πληρωθῇ, λέγει ἡ γραφή) marks quotation.
7. **Witnesses.** How many independent lists name the pair (UBS, Hühn, Dittmar, OpenBible votes, Treasury). History of interpretation, counted.

**Derived, not hand-weighted:** fit the weights to the scholars' own judgments.

- Positives: UBS pairs (quotation), Hühn reminiscences (allusion), Dittmar parallels.
- Negatives: random pairs drawn from the candidate pool.
- Fit a simple model (logistic regression first; nothing that hides its weights), so volume = a calibrated score from 0 to 1, and each link can show *why* (which features carried it).
- Hold out one list (Dittmar) to test: does the measure find what Dittmar found without being taught it, and what does it find that no list has?

**Applying it:** candidates come from an inverted index of rare lemmas (each NT verse against only the LXX verses that share a rare lemma), not all 8,000 by 23,000 verse pairs. Score each candidate, keep those over a threshold, mark the kind from the features (marker plus long run = quotation; rare shared set without marker = allusion; low volume with recurrence = echo; one rare shared key word between two OT texts used together = word link).

## 5. The LXX basis: information for Larry

The LXX basis matches the scholarly picture for most NT quotations, and the UBS data itself marks the LXX words. Some quotations follow the Hebrew or another Greek revision, not the LXX as we have it:

- Matthew 2:15 "Out of Egypt I called **my son**" follows the Hebrew of Hosea 11:1; the LXX reads "his children."
- John 19:37 "They shall look on him whom they **pierced**" follows the Hebrew of Zechariah 12:10, not the LXX.
- 1 Corinthians 3:19 (Job 5:13) and Romans 11:35 (Job 41:3/11) are not LXX wording.

If links are measured on LXX words alone, these score low or vanish. Proposal: key every link in LXX numbering as asked, but measure through **both** the LXX and the Hebrew (via conc.db's MT-to-LXX links), and record which text the NT wording follows. That is also what FR-030 "They Chose" already wants, so the two tools share the work.

### 5a. First evidence (step 1, run 2026-11-11)

`ubs_seed.py` (session scratchpad `incipit/tools/`) turned the UBS file into 422 OT-to-NT rows. Most quoted: Psalms 100, Isaiah 77, Deuteronomy 64, Exodus 58, Genesis 37. NT match share (full = 1, partial = 0.5, over the NT verse's words) runs from 0.067 to 1.0, median 0.485.

- **Hosea 11:1 to Matthew 2:15 scores 0.174** (61st lowest of 422), because UBS marks the LXX words and Matthew follows the Hebrew. Section 5's warning shows up in the seed itself.
- **Psalm 22:19 to John 19:24 scores 0.324** even though all 12 OT words match fully: the NT verse carries 25 words of narrative around the quotation. Volume must be measured on the matched span, not the whole NT verse.
- Content.db's `versification_map` holds only Hebrew-to-English rows (1,974); the Hebrew-to-LXX map lives in conc.db (`unit_map`) or STEPBible's TVTMS. The LXX key waits on that.

### 5b. Larry's answers and what they mean (2026-11-11)

- **Text basis:** "just the LXX I think. The Hebrew might be too much. But where the Hebrew works easily, then okay." So: measure on the LXX; use the Hebrew only as a cheap second look where the LXX scores low but a scholar list names the link (Matthew 2:15), through conc.db's existing MT-to-LXX links. No full Hebrew pipeline.
- **Rahlfs:** Larry asked whether we need it. Not necessarily. Facts found: content.db's `LXX` is Rahlfs, 30,902 rows of which 7,928 are the NT (the known trap), so 22,974 OT verses, **canonical books only (no book_id above 66: no apocrypha)**. Swete is not imported anywhere yet. Plan: measure on Swete word forms (accents and case folded, a light stem match) and test it once against Rahlfs lemmas on the 422 UBS pairs in the personal copy; if the two rank the pairs alike, Rahlfs drops out. Risks: Swete Psalms and Isaiah (the most quoted books) are unproofread OCR; the UBS word marks were made on another LXX text, so their counts are usable but their positions may not line up with Swete's words.
- **Apocrypha:** Larry asked whether the NT uses them. See the reply of 2026-11-11 (section 6, Q4 evidence): no formal quotation of the LXX's extra books, real allusions (Wisdom 2 at Matthew 27:43, Wisdom 7:26 at Hebrews 1:3, 2 Maccabees 7 at Hebrews 11:35), and one named quotation of 1 Enoch (Jude 14-15), which is not in the LXX or Swete. An LXX basis brings the LXX's extra books in naturally.

### 5c. Volume spike, first runs (2026-11-11)

Larry, 2026-11-11: frameworks may be named; where his corpus is silent, write my best guess at his view marked as my take until he approves; no alpha testing ("just do it"); Psalm 22 pilot approved in vault `Scholars/Rix/Incipit/`.

Data: conc.db (vault `Rix/Data/data/conc.db`) holds WH1881 NT and Rahlfs LXX with **shared Greek lemma ids**, and the LXX includes the 16 extra books (Wisdom, Sirach, Maccabees, Psalms of Solomon...). Odes are dropped as sources (they repeat Exodus 15, Deuteronomy 32, Luke 1-2). `unit_map` (MT->LXX, 22,933 rows) maps every UBS OT verse to LXX numbering (499 NT-verse/LXX-verse labels, 0 unmapped; Jeremiah 31:31 -> LXX 38:31).

Scripts (session scratchpad `incipit/tools/`): `volume_spike.py` (features + candidates), `ubs_to_lxx.py`, `fit_volume.py` (logistic fit, five folds by NT verse), `check_passion.py`.

Passion test (Matthew 27, Mark 15, Luke 23, John 19; 16 expected sources):

| Version | Change | Ranked first | In top 5 |
|---|---|---|---|
| v0 | rare shared lemmas, run, distinctiveness | 4 of 16 | 8 |
| v0.1 | verse-length correction (long Esther additions won by chance) | 7 of 16 | 11 |
| v0.2 | Smith-Waterman local alignment (the quoted stretch, not the whole verse) | 8 of 16 | 11 |
| v0.3 | reconcile lemma lists: CATSS files μου/μοι/με as headwords, the NT files them under ἐγώ (131 LXX lemmas remapped by surface-form majority) | **9 of 16** | **13** |

(Counted by `check_passion.py` against one expected verse each; Matthew 27:46 -> Psalm 21:2 first only from v0.3.)

Misses explained: John 19:37 follows the Hebrew of Zechariah 12:10 (the Hebrew second look); John 19:28 "I thirst" shares a theme, not words (needs the neighboring-verse window: 19:29 vinegar -> Psalm 68:22); Mark 15:34 rank 5 (narrative words around the cry). Found on the way: Wisdom 2:18 near the top for Matthew 27:43, Lamentations 2:15 above Psalm 21:8 for the head-shaking (Hühn lists both), Psalm 33:21 beside Exodus 12:46 for John 19:36.

**Whole NT (2026-11-11):** 5,977,545 candidate pairs (v0.3, Odes dropped, 130 lemmas reconciled); 447 of 498 UBS labels among candidates (89.8%). Five folds by NT verse, 347 held-out verses: hand weights rank 1 286 (82.4%), top 5 326 (93.9%); fitted logistic weights 283 (81.6%) and 324 (93.4%); fitted weights (standardized log features) align 2.112, run 0.887, dist 0.881, share 0.513, form 0.506, lex 0.397, rare -0.110. The hand weights hold; the local alignment carries the measure. Plan doc with the CHIASM tool added (Larry, 2026-11-11): claude.ai Doc "INCIPIT and CHIASM: Plan for simple_bible".

**Hühn test (2026-11-11, never used in the fit):** Hühn parsed by a helper (`tools/huhn_parse.py`; 8,869 rows; preface: `**` = quotation with formula, `*` = without, unmarked = reminiscence; spot checks 24/25 and 23/25 on the clean paren-form subset). `eval_huhn.py` on the clean primary paren rows: quotations UBS also lists 60, 57 among candidates, 45 in top 5; quotations UBS lacks 35, 7 found, 5 top 5; reminiscences UBS lacks 2,586, 823 found (32%), 110 top 5 (4%). Sample of misses: mostly motif/theme allusions (Revelation's sevenfold plagues <- Leviticus 26; Acts 12:24 <- Isaiah 55:11), some OCR misreads (Luke 1:76 parsed as 17:6). Conclusion: word volume measures quotations and verbal allusions; motif allusions come from the lists, shown as "shares a theme, few words", and need a second signal (meaning domains or a labeled judgment). The 35 quotations Hühn has and UBS lacks need a hand look (Hebrew-following, parse errors, or real misses).

**Chance control (2026-11-11, `chance_control.py`):** 2,000 fake NT verses (real lengths, random NT tokens) scored against the whole LXX with v0.3; loudest candidate per fake verse: median 27.5, 95th 33.3, 99th 37.3, 99.9th 42.2. Real pairs above: 7,686 / 3,370 / 1,423 of 5,977,545; UBS pairs above: 349 / 327 / 293 of 447. Of 1,124 pairs above 42.2 not in UBS, a hand read of 15: about half real allusions (Rev 17:12 <- Dan 7:24; Rev 18:23 <- Jer 7:34; Rev 17:4 <- LXX Jer 28:7 = MT 51:7; Jas 5:7 <- Hos 6:3; Acts 20:37 <- Gen 45:14; Luke 13:19 <- LXX Ps 103:12), stock phrases ("right and left", "fragrant aroma", "with all your heart"), noise; 281 of the 1,124 share NT verse and OT book with a Hühn row. Romans 3:14 <- LXX Psalm 13:3 (the LXX psalm carries the Romans 3:13-18 catena; the Hebrew does not). Needed: a stock-phrase filter (phrases common across many LXX passages score low on distinctiveness already; strengthen it).

**Plan doc answers (Larry, 2026-11-11, typed into the doc):** no review buttons ("I will review as I go"); BSB is the English default; LXX-only books (Wisdom, Sirach, Maccabees) shown by default, labeled; Bullinger loaded whole and graded by the chance test; the file keeps the name incipit.db, "incipit" one kind among quotation, allusion, echo.

### 5d. Relation to shape.db (Larry asked, 2026-11-11)

shape.db (vault `Rix/Data/data/shape.db`; 87 shapes, 11,068 instances) tests a declared pattern INSIDE a text (FITS / PARTIAL / FAILS / NODATA). incipit.db links a PAIR of texts with a kind and a volume. Overlaps found:

- Shape 22 (kept Semitic word glossed on the spot) FITS at Matthew 27:46 and Mark 15:34; shape 24 (bilingual apposition) PARTIAL there.
- Shapes 54-87 are 34 Enoch motif shapes (1,440 instances, 258 FITS, with controls), already linking 1 Enoch to the NT (Son of Man on the throne of glory: Matthew 19:28, 25:31, 1 Enoch 62:5; Jude 1:14 PARTIAL on "holy myriads", FITS on the control "Enoch named as speaking"). incipit takes these as motif-level links with shape.db as witness; this covers the 1 Enoch source the LXX basis cannot measure.
- Shape 25 and shape 31 already define citation markers (γέγραπται, ἐρρέθη, λέγει ἡ γραφή, κατὰ τὰς γραφάς); incipit's marker feature uses those definitions, not a copy.

Borrowed discipline ("A shape tests a DEFINITION, not an idea"): each link kind gets a declared formal definition with a could-fail-if; every run reports all verdicts; the volume threshold is set against a permutation control (shuffled NT verses), as shape 18 does.

Code: simple_bible `src/shape/` (BIB_SHAPE_ENGINE, _RUN, _FINDING, _TIER, _REGISTRY, _LINT). incipit is the real second implementor of "declared definition, run, findings with tiers"; recommendation: incipit.db stays its own file (pairs, not instances) but shares definitions, verdict/tier vocabulary and run bookkeeping through one ancestor.

### 5e. The Hebrew second look, built (2026-11-12, 0.7.70)

`hebrew_look.py` (scratchpad tools). For a link's LXX verse it finds the Hebrew verse(s) (`unit_map` MT->LXX) and reads them through the LXX translators' own habits: each Hebrew lemma -> the Greek lemmas `link` (translation:MT->LXX, 369,468 token pairs) gives it at 15% or more of its alignments, at most 3. The decision rests only on **departures in this verse**, from the verse's own token alignment:
- a word counts for the **Hebrew** when the NT has a usual rendering of a Hebrew word the LXX rendered unusually here (or left out);
- a word counts for the **LXX** when the NT has an LXX word that is not a usual rendering of the Hebrew word it stands for here, or stands for none (an LXX plus).
Content words only (noun, verb, adjective, idf >= 2.5). Decisive: two words of idf >= 4.5, or one of idf >= 8.0. Verdict hebrew / lxx when one side decides and the other has nothing; both when the shared words decide and neither side has a departure; else unknown. Run on quotations and incipits named by UBS or Hühn only (which text a passage follows is a quotation's question).

How it got there: run 1 counted function words ("I", "into") and missed Matthew 2:15, Hebrews 10:5 and Matthew 27:46 (4 of 7); content words only, 7 of 7. Run 2 on every scholar-named link: 118 "hebrew", mostly one common verb ("eat") whose headword differs between the LXX (CATSS) and NT taggings: the departure test cut it to 51; the rarity rule and quotations only to 12. The 7 agreed cases (Matthew 2:15, John 19:37, Matthew 8:17 Hebrew; Hebrews 10:5, Acts 15:17, Matthew 21:16 LXX; Matthew 27:46 both) were used to tune, so they are not an independent test; the 12 Hebrew verdicts are all cases scholarship names (John 12:15, 13:18, 19:37; Matthew 2:15, 5:21, 5:27 (the Hebrew order of the commandments), 8:17, 26:31, 27:10; Mark 14:27; Revelation 1:7; Romans 11:35). A 14-row sample of the LXX verdicts read right but for 1 Timothy 5:18, where the Hebrew says the same ("both" would be fairer). Result over 505 quotations: hebrew 12, lxx 176, both 159, unknown 158. Shown as the Incipit list's Follows column and in Side by side's note.

## 6. Open questions for Larry

- **Q1.** Name: an incipit is strictly the opening words. Most links are mid-passage (Mark 15:24 to Psalm 22:18). Keep `incipit.db` as the name for the idea (the fragment points to the whole), with "incipit" as one *kind* among the others?
- **Q2.** Measure through both LXX and Hebrew as in section 5, with LXX numbering as the key?
- **Q3.** May an `incipit.db` scored on Rahlfs lemmas ship publicly (references and scores only), or stays it personal until Swete has lemmas?
- **Q4.** Include apocrypha and pseudepigrapha as sources (Hühn and Dittmar both do: Wisdom 2 at Mark 15:29, 1 Enoch at Jude 14)?

## 7. Next steps (proposed)

1. Parse UBS into seed rows (Hebrew psalm numbers mapped to LXX).
2. Parse Hühn's reference lines (OCR repair, spot-checked by hand); then Dittmar's.
3. Spike the volume measure on one corpus slice (the Passion narratives against the Psalms), report precision against UBS and Hühn.
4. Then a debate cycle on where it lives in simple_bible (extend FR-030 versus its own tool versus a pack), per the goal-first, plural rule.
