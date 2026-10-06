# HISTORY TIMELINE: simple_bible

*2026-10-06. Research and design for a world history timeline with the Bible world at its center. Larry asked for it "based on the Roman and Israel histories" in the vault, then widened it twice the same day: The data "can be gathered from the internet in any number of directions, including more YouTube videos," and "we might include history of church, Asia, North American pre-US, and so on." Effort is not a constraint. Licensing and accuracy are. Companion file: `11-timeline-pilot.csv` (the pilot rows). Nothing in the vault was modified.*

**The thread through the design:** A timeline is a pile of date claims, and date claims are exactly what popular history gets wrong. So the timeline is built the way the rest of simple_bible is built. The engine owns every fact. Every fact carries its sources and their grades. Disputes are shown as competing ranges, never quietly resolved. Claims that fail are kept and shown as failed. A video, a wiki page or an AI never puts a date on the screen by itself.

---

## 0. Findings first

1. **Larry's two histories are the backbone, and they are better than anything else in the inputs.** *A History of Rome: From the Kings to the Fall of Constantinople* (2026-10-01) carries an Appendix C of New Testament-period anchors, each with its manuscript, coin or inscription basis and its competing dates (Herod 4 BC vs 1 BC; Quirinius; Pilate; AD 30 vs 33; Gallio; Masada 73 vs 74; Bar Kokhba). *A History of Israel in Its Ancient Near Eastern World* (2026-10-02) carries an Appendix C from c. 10,000 BC to 63 BC in the same format, plus a "Contested Chronologies" section (Exodus; high vs low Iron Age chronology; 587 vs 586; Ezra–Nehemiah; Thera; AD 30 vs 33). Both were built from these same transcripts and checked claim by claim. Both have source registers (Appendix B) that already rate every transcript. The pilot leaned on them, then re-checked against primary texts and fetched scholarship.
2. **The transcripts are leads, and mostly duplicates.** The 45 Israel files are 36 distinct productions by a 4-gram overlap test (Appendix B counts 37). The 15 Rome files are 13 (Mary Beard's *Empire Without Limit* uploaded three times; 4-gram Jaccard 0.75–0.81). Quality runs from a careful podcast (Fall of Civilizations) and a BBC series to one fabricated "Kramer admits the truth" video and a re-cut of *The Exodus Decoded*. Section 3 rates every file.
3. **`primary_evidence.db` is uneven as an anchor.** Its `docs` table holds real public-domain text (Josephus's *Antiquities* in Whiston, Philo in Yonge, the KJV Apocrypha including 1 Maccabees, Knudtzon's Amarna edition). Its `ane_texts` rows for inscriptions (Merneptah, Kurkh, Taylor Prism, the Babylonian Chronicles, Cyrus Cylinder) are one-line *summaries*, not translations, with generic museum home-page URLs. Two of those summaries are wrong on dates (Section 4.3). The "Josephus - Complete Works" document is *Antiquities* only: no *Jewish War*, *Life* or *Against Apion*.
4. **Several transcript claims are wrong, and a few apparent errors are really disputes.** "Herod's Temple begun in 23 BC" follows Josephus's *Jewish War* (15th year) against his own *Antiquities* (18th year, 20/19 BC); that is a dispute, not a blunder. "The kingdom divided in 928 BC" follows Cogan's chronology against Thiele's 931/930; also a dispute. But "Nehemiah appointed governor in 458 BC" (that is Ezra's date), "the Romans attacked the Temple in AD 67" (it was 66, under Florus), "a thirty-month siege in 597 BC" (the long siege and the burning were 588–587/586), and "12,000 Jewish captives built the Colosseum" (no ancient source) are errors. Section 8.
5. **The ship rule holds up in practice.** The pilot has 61 rows (21 Israel and ancient Near East, 30 Rome, 10 synchronisms from the new lanes): **31 VERIFIED, 18 DISPUTED, 8 P3-ONLY, 4 UNVERIFIED.** Every Israel and Rome row is anchored in P1, P2 or Larry's P3, except the patriarchs, which have no date to anchor. Three synchronisms could only be confirmed on Wikipedia within the session's budget; under the rule they stay UNVERIFIED and do not ship. That is the rule working.

---

## 1. What the timeline is for

Three questions drive it:

1. **"When was this, and how sure are we?"** One event, its date or range, the evidence, and the competing dates.
2. **"What else was happening then?"** The synchronism view: Pick a year, a range or a verse, and see every lane at that moment. Rome when Paul wrote Romans. Han China when Jesus was a boy. Kush when Philip met the Ethiopian official.
3. **"Is what I just heard true?"** A date claim from a sermon, a video or an AI answer, checked against the engine (Section 9, I-P01).

**What it inherits from the design doc and `10-INNOVATIONS FROM PRACTICE.md`:**
- The engine owns every fact. AI is used at build time, or as labeled drafting, never as a source.
- Copyrighted material without a license never ships. Transcript text never ships; dates and events are facts and are restated in our own words.
- Every fact carries provenance.
- Disputes and FAILS are always shown.
- Export is share-safe: Flags travel with every claim.

---

## 2. Source channels

The two `_YouTube` folders are a **seed corpus, not the boundary**. Leads may come from anywhere. **The verification rule is the same for every channel:** an event ships only when it is anchored in P1 or P2, or in Larry's verified writing (P3), never on a video, wiki or dataset claim alone. Every source that asserted the event is recorded, so agreement and disagreement across sources stay visible.

### 2.1 Provenance grades

| Grade | Meaning | Can anchor a shipped event? |
|---|---|---|
| **P1** | Primary witness: an ancient text, inscription, papyrus, coin or archive, in an identified edition or translation (e.g., Josephus *Ant.* 18.89 in Whiston; the Babylonian Chronicle BM 21946; Suetonius *Claudius* 25.4) | Yes |
| **P2** | Scholarship of record: peer-reviewed work, academic handbooks, museum and university object pages, encyclopedias of record (Britannica), named scholars' positions with a fetched URL | Yes |
| **P3** | Larry's verified writing: the two histories' appendices and ledgers, Controversy Lab verdicts. Ships under D-019 (rix.db ships). P3 anchors only where it itself names its P1/P2 basis; a P3 line resting on recall does not anchor | Yes, with its basis carried |
| **P4** | Lead: YouTube transcripts, Wikipedia, Wikidata, Theographic and other secondary datasets, AI extraction output | **Never alone** |

A **build-time gate** enforces it: An event row whose supporting assertions are all P4 cannot reach the shippable database (Section 5.4). AI recall is not a grade at all; it can propose a lead, never support one.

### 2.2 The channels

Licenses below were checked 2026-10-06 against pages actually fetched (URLs in the References list at the end). "Facts" means extracted dates, names and coordinates; "text" means copied prose. This is a reading of the license wording, not legal advice.

| Channel | Grade | License / terms | Facts | Text | How it is ingested | Reliability notes |
|---|---|---|---|---|---|---|
| **YouTube transcripts** (seed folders; future harvests) | P4 | YouTube ToS: personal, non-commercial viewing; no downloading or redistribution "except as expressly authorized" | Lead only | **Never ships** | Already harvested to `_YouTube/<folder>/` by `simple_ocr_capture` v1.15 (point at a channel, get every transcript, YAML front matter); ingested into `transcripts.db` (handling rule `spoken-word-captioned-datum-only`, sha256 per body, ¶ locators). The build reads claims with their ¶ locator | Auto-captions mangle names and numbers ("Saon II," "Around35 CE," "Akmosistella"). Popular channels repeat legends. Rate each production (Section 3) |
| **Larry's histories** (`Rix/History/`) | P3 | Larry's own composition; ships per D-019 | Yes | Yes (his choice) | Parse Appendix C tables (Israel and Rome) and the nine judged ledgers into candidate events with their stated basis | Best single source in the inputs; built from the transcripts but checked against named scholarship. Some items marked [OPEN] or † (Wikipedia-resting) in Israel Appendix E; those carry that flag |
| **Controversy Lab verdicts** | P3 | Larry's | Yes | Yes | Hand-entered as dispute rulings with confidence (Section 4.4) | Rulings are "a lean, never consensus" where so stated |
| **`primary_evidence.db`** (`docs`) | P1 | Public-domain texts: Whiston's Josephus (Gutenberg #2848), Yonge's Philo, KJV Apocrypha, Knudtzon 1915 Amarna | Yes | Quotable (PD); strip Gutenberg branding if redistributing | FTS5 lookup with locators; a verification step records book.chapter.section and a sha256 of the passage | Whiston is paraphrastic; Knudtzon is German + Akkadian with OCR-degraded diacritics. "Complete Works" is *Antiquities* only. The Philo file came from a PDF of a later publisher's edition; Yonge's text is PD but any publisher apparatus is not |
| **`primary_evidence.db`** (`ane_texts`) | **P4 as stored** | Mixed | Pointer only | No | Used only to know a witness exists and which verses it touches (`ane_text_bible_links`, 1,420 rows) | Summaries, not translations; generic URLs; two date errors found (Section 4.3) |
| **bible.db / distribution core.db** | P1 (for what the text says) | Per version (BSB CC0, KJV PD, etc.) | Yes | Per version | Verse links resolved through the versification map (`MAPPED_REF`, D-010) | A verse is P1 for what the text *says* ("in the fifteenth year of Tiberius"), not for the modern date it implies; the conversion is a separate, sourced step |
| **Wikidata** | P4 (structured backbone) | **CC0** for all structured data | Yes, no attribution needed | n/a | Periodic SPARQL snapshot per lane: items with point in time (P585), start (P580), end (P582), with precision, calendar model and earliest/latest qualifiers. Supplies stable IDs (QIDs) for people, places, events, polities | Crowd-edited and uneven. Dates carry precision (9 = year, 10 = month, 11 = day), a calendar model (proleptic Julian before 1583), astronomical BCE numbering (1 BCE = year 0), and earliest (P1319) / latest (P1326) qualifiers. Best as an ID spine and a lead generator; never an anchor |
| **Wikipedia** | P4 | CC BY-SA 4.0 (text); facts and ideas are not covered by copyright | Yes, as leads | Only under BY-SA (we do not copy) | Pointer to its cited sources, which are then fetched and graded | Variable; use the footnotes, not the prose |
| **Pleiades** (ancient places) | P2 for places | CC BY | Yes | Yes, with credit | Dump import: IDs, names, coordinates, time periods, location precision | Scholarly gazetteer (ISAW/NYU). The site's own wording does not give a CC BY version number |
| **OpenBible.info Bible Geocoding** | P2-lite for biblical place identifications | CC BY 4.0 (some OpenStreetMap-derived data is ODbL 1.0) | Yes | Yes | GitHub dataset: each biblical place with candidate modern sites and confidence | The author says "there are almost certainly errors"; identifications are probabilistic and say so. Keep its confidence score visible |
| **STEPBible-Data (TIPNR)** | P2 for names and references | CC BY 4.0 | Yes | Yes | Person and place names with every verse reference; disambiguates people who share a name | Names and references, not a chronology |
| **Theographic Bible Metadata** | P4 | CC BY-SA 4.0 (share-alike) | Lead only | SA applies | Optional cross-check of people/place/event linkage | Its Old Testament dates follow Floyd Nolen Jones's young-earth, Ussher-type chronology. Never import its dates; CL #19 forbids a year-count before Abraham |
| **Perseus / Scaife** | P1 (texts) | CC BY-SA 4.0 for the GitHub texts; Tufts says statuses vary | Yes | SA; check each | Locator verification for Greek and Latin authors | Check each translation's own status |
| **LacusCurtius** (Thayer) | P1 | Public domain **only** where the URL has exactly one asterisk; no asterisk = © Thayer; two = someone else's copyright | Yes | One-asterisk pages only | Locator verification (Tacitus, Suetonius, Dio, Strabo) | Careful transcriptions; the notes are his |
| **Project Gutenberg** | P1 | US public domain; the PG license and trademark apply unless branding is removed | Yes | Yes, branding stripped | Local copies with sha256 | Whiston (1737) is paraphrastic; check load-bearing readings |
| **CCEL** (Schaff, ANF/NPNF) | P1 for church history | "Personal, educational, or non-profit purposes"; republication needs permission; some front matter copyrighted | Yes | Non-profit use; check each book | Church-lane locators (Eusebius, councils) | 19th-century translations |
| **Livius.org** | P2-lite | All rights reserved, with reuse allowed if you "do not make profit" | Yes | Avoid copying | Verification lookups only | One careful curator (Jona Lendering) |
| **PeriodO** | P2 for named periods | Says "public domain"; CC0 not confirmed | Yes | n/a | Period definitions (e.g., "Iron Age IIA") with the authority that defines each boundary | Periods are defined per authority; keep the authority |
| **World Historical Gazetteer** | P4/P2 by dataset | Aggregate CC BY 4.0; contributed datasets keep their own terms (CHGIS and Native Land Digital have "specialized terms") | Per record | Per record | Non-Mediterranean places | Check each record's source license |
| **Seshat** | P2 (polity-level) | CC BY-NC-SA on the website and README; a CC0 file in one repo conflicts | NC: free tool qualifies, but SA would bind | Avoid | Polity date ranges as leads | Expert-coded; polity-level, not event-level. Resolve the license conflict before any import |
| **ctext.org** (Chinese texts) | P1 host | Forbids scraping; API by subscription | Lookup by hand only | No | Manual locator checks | Do not automate |
| **Native Land Digital** | Context only | Terms not opened; says its maps "are not official sources" | Not for dates | No | Link out only, if at all | Self-described non-authoritative |
| **Region-specific P1 translations** (e.g., John E. Hill's *Hou Hanshu* "Western Regions" translation; Ashoka's edicts; Strabo via LacusCurtius) | P1 | Per page (Hill's translation is "freely available," no license stated: lookups only) | Yes | Only with a clear license | Locator verification | Translator named on every source row |

**Not yet verified (open work):** a CC0 statement for PeriodO; the Pleiades license version; the CBDB (China Biographical Database) license; any Mesoamerican correlation dataset; open sources for Africa (Kush, Aksum) and South Asia beyond single translations; Native Land's terms; the Seshat license conflict.

### 2.3 Gathering is open-ended

New channels plug in as **lead producers**. Each produces `lead_claim` rows (Section 5.1) with a channel, a locator and a grade of P4 unless it is itself P1 or P2. Adding a channel never changes the ship rule. More YouTube channels (harvested by `simple_ocr_capture`), Wikidata snapshots, a new open dataset, or a scholar's article all enter the same funnel.

---

## 3. Source ratings: the seed transcripts

Larry's registers (Israel Appendix B; Rome Appendix B) already rate every file in prose. The table below compresses them, adds the duplicate measurements made today (4-gram word overlap), and corrects a few register details. "Lead value" means usefulness for *dated* events in this timeline.

### 3.1 History-Israel (45 files → 36 distinct productions)

| # | File | Kind | Channel / presenter | Duplicate status | Lead value |
|---|---|---|---|---|---|
| 1–2 | 13. The Assyrians - Empire of Iron; (2) | Documentary series (podcast) | Fall of Civilizations (Paul Cooper) | Same video ID. The un-numbered file holds the clean manual text **plus** an appended auto-caption copy (4-gram containment 1.00); use "(2)" | Medium-high: Assyrian side of Israel and Judah; quotes royal inscriptions; flattens the Samaria and 701 debates |
| 3–4 | 17. Carthage - Empire of the Phoenicians; (2) | Documentary series | Fall of Civilizations | Different uploads; original is auto-captioned with garbled names, "(2)" is manual | Low: Phoenicia, Tyre, the tophet debate |
| 5–6 | 18. Egypt - Fall of the Pharaohs; (2) | Documentary series | Fall of Civilizations | Different uploads (Jaccard 0.74); **original is manual**, "(2)" auto | Medium: dynastic sequence; Shoshenq; Kushite 25th Dynasty |
| 7–8 | 20. Persia - An Empire in Ashes; (2) | Documentary series | Fall of Civilizations | Different uploads; **"(2)" is manual**, original auto | Medium: Cyrus, the Cylinder; but conflates 597 with the 588–586 siege |
| 9–10 | 8. The Sumerians - Fall of the First Cities; (2) | Documentary series | Fall of Civilizations | Same video ID; use "(2)" | Low: before the patriarchs; middle chronology |
| 11 | 1st Century Israel Judaea … | TV-style documentary | ArchieCastle (auto) | — | Medium: sects, the revolt; dates the Temple attack to 67 (wrong) |
| 12, 41, 45 | 2+ Hours Of Facts …; The Time of Jesus … Parable; What Life Was Like … | TV documentary compilation | Odyssey; Parable; Timeline (History Hit network); Aaron Kislenko with Shimon Gibson and others | **One program, three uploads** (Jaccard 0.68–0.76, containment 0.82–0.87) | Low: daily life, few dates |
| 13 | 8,000-Year-Old Underwater Settlement … | Misfiled (British archaeology) | Odyssey | — | None |
| 14 | AI Just Decoded the Dead Sea Scrolls … | Clickbait | The Ultimate Discovery | — | Low: conflates the 2021 Cave of Horror find with a separate AI dating study; "35 CE" caption garble for 135 |
| 15 | Ancient Israel and Assyria … (Part I) | Narrated lecture | History with Cy | — | **High** for 885–841 BC; cites Kurkh, Black Obelisk, Tel Dan; flags the Tel Dan vs 2 Kings 9 problem itself |
| 16 | Before I Die, Please Listen — … Kramer Admits the Truth | **Fabricated** clickbait (AI-style) | Secret World Files | — | **None.** Invents "unpublished notes" and a thesis Kramer never held (he died in 1990) |
| 17 | Bible Secrets Revealed … (S1, E2) | TV episode | HISTORY; Cargill, Mullins and others | — | Medium: Temple Mount; skeptical on the Exodus |
| 18 | What Was Left Out of the Bible … (S1, E3) | TV episode | HISTORY | — | Low: canon history |
| 19 | Exodus Evidence: Ahmose Stela, Avaris Seals and Santorini Ash | **Re-cut of *The Exodus Decoded* (2006)** under a new title | Absolute Egypt | — | Low; a foil. Thesis (Exodus = Hyksos expulsion) rejected by Bietak, whose excavation it leans on |
| 20 | History of Ancient Israel Full DOCUMENTARY | Single documentary | Para Bellum | Distinct from #21 (containment 0.20) | **High**: clean dated sequence 1207–63 BC, with errors (Section 8) |
| 21 | History of Ancient Israel. From Arrival to Canaan … | Short documentary | Para Bellum | Separate script | Low |
| 22 | Jericho - The First City on Earth | Documentary | History Time | — | Medium: Neolithic Jericho (Kenyon's figures) |
| 23 | Jerusalem History Documentary (1350 BCE - PRESENT) | Documentary | Past Uncovered | — | High: Jerusalem's whole span |
| 24, 25, 27 | Jewish History - Evidence Of Ancient Israel (History Documentary); … - Full Documentary; Kingdom Of David & Solomon … Part 1 | Documentary | History Channel; Wisdom Land; World Documentary Channel | **One program, three uploads**; "Kingdom of David" is a half-length cut (containment 0.76–0.87) | High: Merneptah, settlement survey, high vs low chronology |
| 26 | Judea Under Roman Rule | Narrated lecture | Para Bellum | — | **High**: 63 BC–AD 73 with dates |
| 28 | Lost Worlds: Lost City of the Bible Discovered | TV episode | HISTORY | — | Low: Hattusa; overstates Hattusili's command at Kadesh |
| 29 | Sacred Jerusalem … | Travel/devotional documentary | Hidden Compass | — | Low |
| 30 | Sifting The Evidence … Dr. Chris Sinkinson | Lecture, scholar-led (apologetics) | Vision Video | — | Medium: site-by-site; 732 and 701 BC |
| 31 | The Buried Biblical Mysteries Of The Holy Land … | TV compilation | Odyssey | — | Medium: Herod, Masada, Qumran; misdates the Sicarii seizure of Masada to 73 |
| 32 | The Concise History of Ancient Canaan … (c. 7000–539 BC) | Narrated lecture | History with Cy | — | **High**: dense Bronze and Iron Age chronology |
| 33 | The ENTIRE History of Ancient Israel to Fall Asleep … | Sleep narration (AI voice) | The Sleepless Story of Historian | — | Low: garbled names; narrative presented as history |
| 34 | The ENTIRE History of Israel (Documentary) | Narrated listicle | The Entire History | — | Medium: many dates, some off ("second temple's construction began in 516") |
| 35 | The ENTIRE History of the Jews (Documentary) | Narrated listicle | The Entire History | — | Medium-high: the most hedged of the "Entire" set |
| 36 | The Entire History Of The Hittites | Documentary | History Time (script by Gordon Dockery) | — | Low: nearly every Hittite name garbled |
| 37 | The Entire History of the Persian Achaemenid Empire | Documentary | History Time | — | Low-medium |
| 38 | The Great Revolt & The Siege of Masada | Documentary | History Time | — | **High** for AD 66–73; states 73 only |
| 39 | The Incredible History of the Jewish Temple | Documentary | Bible Passages | — | Medium: "23 BC" (a real minority date, Section 8); "1446 BC" Exodus stated flatly |
| 40 | The Kingdoms of Israel and Judah: What the Archaeology Actually Shows | Long narration (AI style) | Ancestors Civilization | — | Medium: hedged, few dates |
| 42 | The Real History of Biblical Israel — Complete Documentary … | Narration with confessional framing | Deep Bible Insights | — | Medium: many dates (uses 928 BC for the division, Cogan's chronology) |
| 43 | We Found the Temple Mount Beams … (Not Clickbait) | Travel vlog | Sergio & Rhoda in Israel; Dr. David Gurevich | — | Low: careful on the beams, sensational on a "6,000-year-old civilization" |
| 44 | Who were the Philistines | Narrated lecture | Epimetheus | — | Medium: best-grounded on the Philistines (Stager, Maeir, the 2019 Ashkelon DNA study) |

### 3.2 History-Rome (15 files → 13 distinct productions)

| # | File | Kind | Channel / presenter | Duplicate status | Lead value |
|---|---|---|---|---|---|
| 1 | Athens, Alexandria, And Rome … | Docudrama compilation (c. 2000, German) | Timeline (History Hit) | — | Low: city life; almost no Jewish or Christian content |
| 2 | Complete History Of The Roman Republic | Single documentary | Odyssey | — | Medium: 753 BC to Actium; Actium placed in "the Gulf of Corinth" (wrong) |
| 3 | Europe in the Wake of the Fall of Rome … Dark Ages | TV special | HISTORY | — | Low for this period: 410 onward; omits 476 |
| 4 | How Rome Forged an Epic Empire (Engineering an Empire) | TV episode (2005) | HISTORY; named experts | — | Medium: building chronology; several errors (Section 8) |
| 5, 10, 13 | … Roman Empire In 4 Hours (Empire Without Limit); … Explained In 4 Hours; The Thousand Year History … | **BBC *Ultimate Rome: Empire Without Limit* (2016), Mary Beard** | Odyssey; Parable; All Out History | **One series, three uploads** (4-gram Jaccard 0.75–0.81) | **High**: the most scholarly of the set; cite once |
| 6 | The Complete History of Rome, Summarized | Comedic educational compilation | Overly Sarcastic Productions | — | High as a dated spine; does source criticism; repeats some legends |
| 7 | The ENTIRE History of Rome Explained (753 BC – 1453 AD) | Background-listen narration | Uncharted Mysteries | — | Medium-low: dates mostly sound; legend told as fact |
| 8 | The First Barbarian War E1 | TV episode (2008) | THE History Channel | — | Low: Cimbri and Marius |
| 9 | The Genius of Ancient Rome's Architecture | Dubbed French documentary | SLICE History | — | Low |
| 11 | The Most Disastrous Emperors In Roman History | **Mislabeled**: a single-presenter documentary on Augustus to Augustine (Larry's register infers Richard Miles, *Ancient Worlds* ep. 6, unverified) | Odyssey | — | Medium: Ara Pacis, Nicaea; contains no list of emperors |
| 12 | The Roman Empire - Episode 1 … | 1990s TV re-upload | AgeOfAntiquity | — | Low: dated views of early Rome |
| 14 | The Untold Story Of Emperor Vespasian | Single documentary | Odyssey | — | **High** for AD 66–79; Jotapata "40 days" (Josephus: 47) |
| 15 | Who Were The Greatest Caesars … Romans with Tony Robinson | Four stitched episodes (Caesar ×2, Caligula, Nero) | Odyssey | — | Medium-high: Suetonius tested against coins and archaeology |

**Kind breakdown, both folders (49 distinct productions):**

| Kind | Israel | Rome | Total |
|---|---|---|---|
| Documentary series (Fall of Civilizations ×5; Beard; Robinson's stitched episodes) | 5 | 2 | 7 |
| Single documentaries and TV episodes | 15 | 9 | 24 |
| Narrated lectures (History with Cy ×2, Para Bellum's *Judea*, Sinkinson, Epimetheus) | 5 | 0 | 5 |
| Narrations, listicles, AI-voice | 5 | 1 | 6 |
| Comedic educational (Overly Sarcastic Productions) | 0 | 1 | 1 |
| Clickbait or fabricated (Kramer; AI and the Dead Sea Scrolls) | 2 | 0 | 2 |
| Pseudo-documentary re-cut (*The Exodus Decoded*) | 1 | 0 | 1 |
| Travel or devotional vlog | 2 | 0 | 2 |
| Misfiled (not Bible world) | 1 | 0 | 1 |

**Lead value:** high 10 (Israel 7, Rome 3), medium-high 3, medium 15, low-medium 2, low 17, none 2.

---

## 4. Larry's history work and the primary witnesses

### 4.1 Larry's histories (P3 backbone)

- **Israel:** `Rix/History/A History of Israel in Its Ancient Near Eastern World.md` (assembled, about 141,800 words), built in `_Israel Build/`: nine extracts, nine judged ledgers (about 800 judged entries from about 3,900 raw claims), research dossiers R1–R18 with fetched URLs, a framework inventory, and drafts with Appendices A (competing claims), B (source register), C (chronological anchors), D (vault touchpoints), E (open research).
- **Rome:** `Rix/History/A History of Rome - From the Kings to the Fall of Constantinople.md`, with Appendices A–D. Its Appendix C is the New Testament-period anchor table; Israel's Appendix C cross-references it for 4 BC–AD 135 rather than duplicating it.
- **How the timeline uses them:** Appendix C rows become candidate events with their basis copied into source rows. The "Contested Chronologies" sections become dispute rows. Appendix A's "Competing claims" boxes become transcript flags (what the videos say, our verdict). Items Israel Appendix E marks [OPEN] or † (resting mainly on Wikipedia) enter as candidates needing P2, not as anchors.

**Frame rules stated in Larry's work, which the timeline honors:**
- **One shared ancient Near Eastern world (Larry, 2026-10-02).** Israel is not "borrowing" from its neighbors. All the peoples share one world; YHWH gives Israel the true, well-founded version; the nations' versions run on the logic of their patron gods (Deut 32:8–9). In the timeline, lanes are parallel peers; cross-lane links are typed *contemporary with*, *interacts with*, *rules over*, *wars with*, *names* (an inscription names a person), never *derived from*. Scholarly dependence theses (e.g., a Hittite vs Neo-Assyrian model for the covenant form) appear only as named positions inside a dispute.
- **Calibrated honesty on archaeology:** minimalist and maximalist readings both stated (Build Plan guardrails). Every Israel dispute row carries both.
- **The circularity clause:** the ancient Near Eastern frame weighs evidence; it never supplies a conclusion the text is then said to prove. In the timeline, a synchronism shown beside a verse never claims to *confirm* the verse unless the source does.
- **Later sources are marked as later.** Each source row carries its own date of composition, so the UI can show "this witness wrote 150 years after the event."
- **No framework names in the shipped interface.** Rulings appear as "Larry's lean," with the cycle linked in his edition, never as ™ labels in body text.

### 4.2 `primary_evidence.db`: what can anchor events

| Holding | What it anchors | Status |
|---|---|---|
| Josephus, *Antiquities* (Whiston 1737, Gutenberg #2848; 549,253 words) | Pompey's capture of Jerusalem (14.66: "the third month, on the day of the fast … when Caius Antonius and Marcus Tullius Cicero were consuls" = 63 BC); Herod's Temple begun "in the eighteenth year of his reign" (15.380); the lunar eclipse before Herod's death (17.167); the census under Quirinius with Coponius (18.1–2); Pilate "tarried ten years in Judea" (18.89); James "the brother of Jesus, who was called Christ" stoned between Festus and Albinus (20.200); the war began "in the twelfth year of the reign of Nero" (20.257) | **Verified today** (passages read) |
| Josephus, *Jewish War*, *Life*, *Against Apion* | Temple burned 10 Lous AD 70 (*War* 6.250); Masada (7.401) | **Not in the database** (the "Complete Works" doc is *Antiquities* only). The `ane_texts` rows for *War* I–VII are summaries |
| KJV Apocrypha (1 and 2 Maccabees etc.) | The desecration on 15 Chislev, 145 Seleucid era (1 Macc 1:54) and the rededication on 25 Chislev, 148 SE (4:52) | Verified today |
| Philo, Yonge (complete, incl. *Embassy to Gaius*) | Caligula's statue order and Petronius (Legatio 188ff.) | Verified present |
| Amarna letters, Knudtzon 1915 vol. 1 (Akkadian + German) | Abdi-Heba of Jerusalem's letters (EA 285–290) in the Amarna age, c. 1350s–1330s BC | Present; OCR-degraded diacritics |
| 1 Enoch, Targums, Plato, Apostolic Fathers (provenance stub only) | Composition-date events for texts, not political events | — |
| `ane_texts` (416 summaries: oracc 155, eBL 102, perseus 79, pseudepigrapha 72, angelology 8) | **Pointers only.** Tells the build that a witness exists (Merneptah, Kurkh, Black Obelisk, Taylor Prism, Siloam, Lachish, the Babylonian and Nabopolassar Chronicles, Cyrus Cylinder, Tel Dan, Mesha) and which verses it touches (`ane_text_bible_links`, 1,420 rows) | Each needs a real edition or museum record before it anchors anything |
| `dss_manuscripts` (173) with date ranges | Manuscript-date events (a "Texts and manuscripts" lane) | Dates are as recorded; verify per scroll |

### 4.3 Defects found in the vault data (for the defect register; nothing edited)

1. **`ane_texts` "Babylonian Chronicle (Nebuchadnezzar)"** says Jerusalem was captured in "Arahsamnu 597 BCE." The chronicle (BM 21946) gives **2 Adar** of Nebuchadnezzar's 7th year (16 March 597 BC); Kislev is when the army set out.
2. **`ane_texts` "Josephus, Jewish War VI"** says the Temple burned "on the 9th of Av." Josephus gives the **tenth of Lous** (Av); the ninth is the later rabbinic commemoration. The timeline must show both and say whose each is.
3. **`docs` "Josephus - Complete Works (Whiston)"** is *Antiquities of the Jews* only.
4. **`ane_texts` period labels** are inconsistent (e.g., Enuma Elish tablets labeled "Old Babylonian (c. 1100 BCE)").
5. **`ane_texts` inscription rows** are summaries with generic museum home-page URLs; they cannot be cited as text.
6. **`bible.db` `bible_versions.license`** reads "MIT" for every version (KJV, WLC, LXX, TgO …), contradicting the caveat column and the design doc's §7. The distribution build must not copy this column.

### 4.4 Vault rulings the timeline must honor

| Ruling | What the timeline shows |
|---|---|
| **CL #18, crucifixion dating** (VERDICT): Friday sustained **0.93**; 14 Nisan **0.80**; **AD 33 over AD 30 at 0.60, "a genuine lean, not a settled result"**; the "blood moon" eclipse clincher retired (0.20); Jaubert Tuesday supper 0.30; Wednesday crucifixion rejected | Dispute D-CRUCIFIXION with two positions (7 April AD 30; 3 April AD 33), both drawn; Larry's lean marked on AD 33 at 0.60 with the words "a lean, not consensus." The Wednesday chronology appears in the FAILS bucket with its refutation. Helen Bond's outer bound AD 29–34 drawn as the envelope |
| **CL #19, genealogies and the age of the earth**: Genealogies license "sequence + rough antiquity" and **forbid a precise year-count**; Gen 5 ages schematic (0.88); the age of the earth left open | **No event before Abraham gets an absolute year.** Gen 1–11 appears as an undated narrative sequence beside the axis, not on it. Ussher-type dates never ship as dates |
| **CL #17, Job**: Mosaic authorship untenable; composition late 6th–mid 5th century BC (the folktale core older); Job contemporary with Israel in Egypt NOT SUSTAINED (0.25); a short (about 215-year) sojourn a defensible option (0.50) | Job's composition goes on the "Texts" lane as a range; no "Job lived in year X" event; the sojourn length is a dispute (430 years in Egypt per Exod 12:40 MT vs 430 including Canaan per LXX/SP and Gal 3:17) |
| **Israel history, Contested Chronologies** | Disputes: Exodus (c. 1446 / c. 1270–1260 / non-historical or minimal kernel); high vs low Iron Age chronology; 587 vs 586; Ezra–Nehemiah order; Thera |
| **Rome history, Appendix C** | Disputes: Herod's death 4 BC vs 1 BC; Luke 2:2 vs Quirinius AD 6; Claudius's expulsion 49 vs 41; Masada 73 vs 74; Peter and Paul's deaths c. 64–67 |

---

## 5. The data model (SQLite)

### 5.1 Where it lives

A new read-only **`history.db`** beside `core.db` (D-015), so the timeline can be rebuilt and updated without touching the texts. It joins to `core.db` only through mapped verse references. A build-only **`history_build.db`** on Larry's machine holds leads, candidates, review state and everything that does not ship. (Proposed decision D-0xx below.)

### 5.2 Dates, calendars and eras

- **One internal axis:** astronomical year numbers (1 BC = 0, 2 BC = −1), the same convention Wikidata uses, so sorting and arithmetic are trivial. Display converts to BC/AD or BCE/CE (a user setting) and never shows a year zero.
- **Day-precision dates** also store a Julian Day Number, proleptic Julian before 15 October 1582 and Gregorian after (the Americas' colonial era needs both; British dates switch in 1752).
- **The original expression is always kept**, word for word as the source dates it, with the conversion shown: "2 Adar, year 7 of Nebuchadnezzar → 16 March 597 BC"; "15 Chislev, 145 Seleucid era → December 167 BC"; "consuls Antonius and Cicero → 63 BC"; "9th *yongyuan* year of Emperor He → AD 97"; "7.16.6.16.18 (Long Count) → 1 September 32 BC, GMT correlation 584,283."
- **Calendar and era systems** are rows in a table with their conversion method and its uncertainty: regnal years (accession-year vs non-accession-year reckoning, which is what drives 587 vs 586), the Seleucid era (Macedonian and Babylonian epochs differ by six months), Olympiads, *ab urbe condita* (Varronian), consular years, the Hebrew calendar, Chinese reign eras, the Maya Long Count (correlation constant as a parameter), the Hijri calendar, and calibrated radiocarbon.
- **Chronology schemes** (Mesopotamian middle vs short; Egyptian high, middle and low; Thiele vs Cogan vs Galil for Israel's kings; the Varronian vs Polybian date for early Rome) are rows too. A date can be tagged with the scheme it belongs to, and the UI can switch schemes. Switching never edits data; it selects which rows are drawn.

**Certainty classes** (what kind of evidence fixes the date), shown with a pattern and a label, never color alone:

| Class | Example | Drawn as |
|---|---|---|
| **A. Fixed to the day by independent records** | 16 March 597 BC (Babylonian Chronicle); 15 March 44 BC | Solid tick |
| **B. Fixed to the year by inscription, coin, regnal count or synchronism** | Qarqar 853 BC; Gallio AD 51–52 | Solid bar |
| **C. Range from a chronology scheme** | Division of the kingdom 931/930 or 928 BC | Bar with scheme badge |
| **D. Scientific range** (radiocarbon, dendro, ice core) | Thera; Teotihuacan's Sun Pyramid | Gradient bar with stated confidence (68% / 95%) |
| **E. Archaeological period** | Hopewell, c. AD 1–400 (NPS); Iron Age I | Soft band, period name, defining authority |
| **F. Literary or narrative-internal** | 1 Kings 6:1's 480 years; Josephus's numbers | Dashed bar, "per the text" |
| **G. Tradition** (church, oral, later chronicle) | Thomas in India in AD 52; Rome founded 753 BC | Hatched band labeled "tradition," **never drawn as a point** |

### 5.3 Schema

```sql
-- Lanes are data: open-ended, grouped, user-toggleable.
CREATE TABLE lane (
  lane_id        INTEGER PRIMARY KEY,
  slug           TEXT NOT NULL UNIQUE,          -- 'israel-judah', 'rome', 'han-china'
  name           TEXT NOT NULL,
  parent_lane_id INTEGER REFERENCES lane,       -- 'church-patristic' under 'church'
  region_group   TEXT NOT NULL,                 -- 'Bible world core','Asia','Africa','Americas','Europe'
  theme_group    TEXT,                          -- 'Political','Church','Texts and manuscripts','Discovery'
  sort_key       INTEGER NOT NULL,
  default_on     INTEGER NOT NULL DEFAULT 0,
  pattern_token  TEXT NOT NULL,                 -- CSS token; color plus a pattern, never color alone
  scope_note     TEXT NOT NULL                  -- what belongs here, in our words
);

CREATE TABLE calendar_system (
  calendar_id INTEGER PRIMARY KEY, slug TEXT UNIQUE NOT NULL,   -- 'julian','gregorian','seleucid-mac','long-count'
  name TEXT NOT NULL, conversion_method TEXT NOT NULL, uncertainty_note TEXT
);
CREATE TABLE chronology_scheme (
  scheme_id INTEGER PRIMARY KEY, slug TEXT UNIQUE NOT NULL,     -- 'thiele','cogan','meso-middle','egypt-low'
  name TEXT NOT NULL, region_group TEXT, authority_source_id INTEGER REFERENCES source, note TEXT
);

CREATE TABLE event (
  event_id        INTEGER PRIMARY KEY,
  slug            TEXT NOT NULL UNIQUE,
  title           TEXT NOT NULL,                -- our words
  summary         TEXT NOT NULL,                -- our words; n-gram-checked against the transcripts (5.4)
  kind            TEXT NOT NULL CHECK (kind IN ('point','span','reign','period','composition','discovery','undated-sequence')),
  certainty_class TEXT NOT NULL CHECK (certainty_class IN ('A','B','C','D','E','F','G')),
  status          TEXT NOT NULL CHECK (status IN ('verified','disputed','unverified','fails','withdrawn')),
  dispute_id      INTEGER REFERENCES dispute,   -- set when this row is one position in a dispute
  position_label  TEXT,                         -- 'AD 33 (Hoehner, Finegan, Humphreys)'
  scheme_id       INTEGER REFERENCES chronology_scheme,
  wikidata_qid    TEXT,                         -- ID spine only, never a date source
  summary_drafted_by TEXT NOT NULL CHECK (summary_drafted_by IN ('human','ai-reviewed')),
  reviewed_by     TEXT, reviewed_at TEXT,
  build_run_id    INTEGER
);

CREATE TABLE event_date (
  event_id      INTEGER NOT NULL REFERENCES event,
  role          TEXT NOT NULL CHECK (role IN ('point','start','end')),
  y_earliest    INTEGER NOT NULL,               -- astronomical year
  y_latest      INTEGER NOT NULL,
  y_best        INTEGER,                        -- NULL when no best year is defensible
  month INTEGER, day INTEGER, jdn INTEGER,      -- only when the source fixes them
  precision     TEXT NOT NULL CHECK (precision IN ('day','month','season','year','decade','century','millennium')),
  calendar_id   INTEGER NOT NULL REFERENCES calendar_system,
  original_expression TEXT NOT NULL,            -- '2 Adar, year 7 of Nebuchadnezzar'
  conversion_note TEXT,                         -- 'Babylonian Chronicle; Wiseman 1956'
  ci_percent    INTEGER,                        -- radiocarbon only (68 or 95)
  CHECK (y_earliest <= y_latest),
  PRIMARY KEY (event_id, role)
);

CREATE TABLE event_lane (event_id INTEGER REFERENCES event, lane_id INTEGER REFERENCES lane,
  is_primary INTEGER NOT NULL DEFAULT 0, PRIMARY KEY (event_id, lane_id));

CREATE TABLE event_link (                        -- cross-lane relations; never 'derived-from'
  from_event INTEGER REFERENCES event, to_event INTEGER REFERENCES event,
  relation TEXT NOT NULL CHECK (relation IN ('contemporary-with','interacts-with','rules-over','wars-with',
            'names','precedes','follows','part-of','commemorated-by')),
  source_id INTEGER REFERENCES source, PRIMARY KEY (from_event, to_event, relation));

-- Disputes: each position is its own event row, so each can be drawn, sourced and exported alone.
CREATE TABLE dispute (
  dispute_id   INTEGER PRIMARY KEY, slug TEXT UNIQUE NOT NULL,   -- 'exodus-date','kings-chronology','crucifixion-year'
  question     TEXT NOT NULL,
  state        TEXT NOT NULL CHECK (state IN ('open','leaning','settled-majority')),
  envelope_earliest INTEGER, envelope_latest INTEGER,             -- outer bound all positions sit inside
  lean_event_id INTEGER REFERENCES event,                          -- Larry's lean, if any
  lean_confidence REAL, lean_wording TEXT,                         -- 0.60, 'a lean, never consensus'
  lean_source_id INTEGER REFERENCES source                         -- the Controversy Lab verdict
);
CREATE TABLE dispute_holder (                    -- who holds each position
  event_id INTEGER REFERENCES event, holder TEXT NOT NULL, source_id INTEGER REFERENCES source);

-- People and places
CREATE TABLE person (person_id INTEGER PRIMARY KEY, name TEXT NOT NULL, wikidata_qid TEXT,
  tipnr_id TEXT, note TEXT);
CREATE TABLE event_person (event_id INTEGER REFERENCES event, person_id INTEGER REFERENCES person,
  role TEXT NOT NULL);                            -- 'ruler','commander','author','named-in-inscription'
CREATE TABLE place (place_id INTEGER PRIMARY KEY, name TEXT NOT NULL,
  pleiades_id TEXT, openbible_id TEXT, wikidata_qid TEXT, tipnr_id TEXT,
  lat REAL, lon REAL, location_confidence TEXT,  -- carried from OpenBible/Pleiades, never upgraded
  coord_source_id INTEGER REFERENCES source);
CREATE TABLE event_place (event_id INTEGER REFERENCES event, place_id INTEGER REFERENCES place, role TEXT);

-- Verses (joined to core.db through the versification map; MAPPED_REF, D-010)
CREATE TABLE event_verse (
  event_id INTEGER REFERENCES event, book_id INTEGER NOT NULL, chapter INTEGER NOT NULL,
  verse_start INTEGER NOT NULL, verse_end INTEGER NOT NULL,
  link_kind TEXT NOT NULL CHECK (link_kind IN ('narrates','dates','mentions','set-during','written-during')),
  versification TEXT NOT NULL DEFAULT 'eng');

-- Sources and every assertion any source made about an event
CREATE TABLE source (
  source_id INTEGER PRIMARY KEY,
  grade     TEXT NOT NULL CHECK (grade IN ('P1','P2','P3','P4')),
  channel   TEXT NOT NULL,                       -- 'youtube','wikidata','wikipedia','primary_evidence.db','web','rix-history','controversy-lab'
  citation  TEXT NOT NULL,                       -- 'Josephus, Ant. 18.89 (Whiston)'
  locator   TEXT,                                -- section, page, ¶ number, QID
  url       TEXT, retrieved_at TEXT, sha256 TEXT,
  composed  TEXT,                                -- when the witness itself was written ('c. AD 93')
  license   TEXT NOT NULL,
  text_shippable INTEGER NOT NULL DEFAULT 0,     -- 0 for every transcript, always
  credit_line TEXT                               -- feeds the generated credits file
);
CREATE TABLE assertion (
  assertion_id INTEGER PRIMARY KEY,
  event_id  INTEGER NOT NULL REFERENCES event,
  source_id INTEGER NOT NULL REFERENCES source,
  says      TEXT NOT NULL,                       -- our paraphrase of what the source asserts, incl. its date
  stance    TEXT NOT NULL CHECK (stance IN ('agrees','disagrees','partial','silent','overstates')),
  checked_by TEXT NOT NULL, checked_at TEXT NOT NULL
);

-- What popular sources get wrong: kept, shown, and corrected (the FAILS bucket)
CREATE TABLE claim_flag (
  flag_id INTEGER PRIMARY KEY, source_id INTEGER NOT NULL REFERENCES source, event_id INTEGER REFERENCES event,
  kind TEXT NOT NULL CHECK (kind IN ('wrong-date','conflation','legend-as-fact','overclaim','fabricated',
                                     'caption-garble','minority-as-fact','outdated')),
  claim_paraphrase TEXT NOT NULL,                -- our words; never transcript text
  correction TEXT NOT NULL, evidence_source_id INTEGER NOT NULL REFERENCES source);

CREATE TABLE build_run (build_run_id INTEGER PRIMARY KEY, started_at TEXT, finished_at TEXT,
  corpus_manifest_sha256 TEXT, extractor TEXT, extractor_prompt_sha256 TEXT, notes TEXT);
```

### 5.4 The ship rule, as code

```sql
-- An event is shippable only if a P1, P2 or P3 source agrees with it, and every disputed
-- position is separately anchored. P4-only events never ship.
CREATE VIEW v_shippable AS
SELECT e.* FROM event e
WHERE e.status IN ('verified','disputed','fails')
  AND e.reviewed_by IS NOT NULL
  AND EXISTS (SELECT 1 FROM assertion a JOIN source s USING (source_id)
              WHERE a.event_id = e.event_id AND s.grade IN ('P1','P2','P3')
                AND a.stance IN ('agrees','partial'));
```

`fails` rows ship *as refuted claims* (the FAILS bucket), and their refutation must itself be P1/P2/P3. Build gates (deterministic, run before export; any failure stops the export):
1. **P4-only gate:** zero shipped events lack a P1/P2/P3 agreeing assertion.
2. **Own-words gate:** no `summary`, `says` or `claim_paraphrase` shares a run of 8 or more words with any transcript in the corpus manifest (checked against `transcripts.db` chunk FTS).
3. **Dispute gate:** every event with a `dispute_id` has at least one P1/P2/P3 holder; every dispute has at least two positions.
4. **Date sanity:** `y_earliest <= y_latest`; no year zero in any displayed string; every date has an `original_expression`.
5. **License gate:** every source row has a license; transcript sources have `text_shippable = 0`.
6. **Credits:** generated from `source.credit_line`, never hand-edited (design doc §7).

---

## 6. The build pipeline

Runs on Larry's build machine. AI is used here and only here, and every AI output is a lead or a labeled draft.

1. **Corpus manifest.** List every input with its sha256: transcripts on disk (and new harvests by `simple_ocr_capture`), `transcripts.db`, `primary_evidence.db` docs, Larry's history files, Wikidata snapshot, Pleiades and OpenBible dumps, the list of fetched P2 URLs. The manifest hash goes into `build_run`.
2. **Lead extraction (AI, P4).** A model reads transcripts in chunks and emits only structured rows: event, date *as stated*, place, people, the ¶ locator. No prose is copied; the extractor prompt forbids quotation beyond a short identifying phrase, and the own-words gate catches leaks. Structured channels (Wikidata, Larry's Appendix C tables) are parsed deterministically. Output: `lead_claim` rows in `history_build.db`. *Lesson from the Israel build:* Haiku-class extraction dropped material (the Carthage tophet section); spot-check the most important batches against the transcripts.
3. **Clustering.** Leads that describe the same event merge into a candidate event (same Wikidata QID, or same place and overlapping date window and similar title). Every lead stays attached as an `assertion` with stance not yet set.
4. **Anchoring (deterministic first, then human).** For each candidate, search the local P1 texts by FTS (Josephus, Philo, the Apocrypha, Amarna, the Bible) and record a locator and passage hash; match Larry's Appendix C and ledgers (P3); then fetch P2 pages and record URL, date and hash. **A source counts only if it was actually opened** (the vault's standing rule after Haiku packs invented citations three times). Model recall never counts.
5. **Disagreement detection.** If assertions disagree beyond the event's precision (e.g., 73 vs 74 at year precision), the engine opens a dispute and splits the positions into separate event rows, each needing its own anchor. A transcript that states one side of a live dispute as fact gets a `minority-as-fact` or `overclaim` flag, not a "wrong" flag.
6. **Writing.** Titles and summaries in our own words. A person writes them, or an AI drafts them and a person reviews (`summary_drafted_by = 'ai-reviewed'`). American English; any Hebrew or Greek with transliteration and gloss on first use (writing conventions).
7. **Review.** Larry or a delegate marks each event reviewed. Disputes with a vault ruling get the lean recorded from the verdict file, with its confidence and wording.
8. **Gates and export.** Run the six gates; export `v_shippable` and its joins to `history.db`; generate credits. Unverified candidates stay in `history_build.db` and appear only in Larry's private edition, marked UNVERIFIED.

**Re-runs are cheap.** New leads re-enter at step 2; verified events gain or lose supporting assertions; a new P1/P2 source can promote an unverified candidate. Each release records which build run produced it.

**Implementation note (D-020, no Python in the product):** steps 1, 3, 4 (deterministic part), 5 and 8 are engine code and must be Eiffel in the product path. The extraction step may run any model on the build machine; its output is data.

---

## 7. Lanes for a world timeline

Lanes are rows, not code. They group by **region** and by **theme**, nest (Church → Patristic), and switch on and off. The Bible world sits in the middle by default; the other groups are one click away.

| Group | Lanes (initial) | Notes |
|---|---|---|
| **Bible world core** (on by default) | Israel and Judah; Second Temple Judaism; Egypt; Mesopotamia (Sumer, Akkad, Babylon); Assyria; Hittites and Anatolia; Canaan, Phoenicia, Philistia, Aram; Persia; Greece and the Hellenistic kingdoms; Rome; Church | The "Church" lane starts in the 30s AD |
| **Church history** | Apostolic (c. 30–100); Patristic (2nd–5th c.); Councils (Nicaea 325 → Chalcedon 451 → …); Church of the East and Oriental Orthodox; Medieval West; Medieval East (Byzantine); Reformation; Modern | Council dates are firm; martyrdom and authorship dates often tradition (class G) |
| **Asia** | China (Shang → Zhou → Qin → Han, Xin interregnum, …); India and South Asia (Maurya, Kushan, …); Central Asia and the Silk Road; later Japan, Korea, Southeast Asia | Chinese dates are usually annalistic and exact by reign era; Indian dates often ranges |
| **Africa** | Egypt (shared with core); Kush and Nubia (Napata, Meroë); Aksum and the Ethiopian church; Carthage and North Africa; later West and East African kingdoms | Kushite rulers appear in the Bible (Tirhakah, 2 Kgs 19:9; the Kandake, Acts 8:27) |
| **Americas before the United States** | Mesoamerica (Olmec-region, Maya, Teotihuacan, Zapotec, Mexica); Andes; Indigenous North America (Adena, Hopewell, Mississippian, Ancestral Puebloan, and many others); European contact and the colonial era | Most dates are archaeological ranges (class D/E); Long Count dates depend on a correlation constant; see 7.1 |
| **Europe after Rome** | Byzantium (also Rome's continuation); Franks and the Carolingians; the Islamic world (caliphates, al-Andalus); medieval kingdoms; later | The Islamic world deserves its own group as coverage grows |
| **Themes** | Texts and manuscripts (composition of books, the Septuagint, Dead Sea Scrolls, codices); Discovery (when an inscription or site was found: Tel Dan Stele 1993–94) | **Event time and discovery time are different axes**; the Discovery theme lives on modern dates |

### 7.1 Indigenous histories: respectful and accurate

- **Name people as the sources name them, and say whose name it is.** "Hopewell" is an archaeologists' label from Mordecai Hopewell's farm in Ohio; the National Park Service describes Hopewell as "a broad network of economic, political, and spiritual beliefs and practices among different Native American groups," not as a people's own name. "Teotihuacan" is a later Nahua name; the builders' own name is unknown. "Olmec" is likewise a modern label. The UI shows the label, a note on its origin, and the people's own name where known.
- **Oral-tradition dates are never drawn as points.** They are class G bands, labeled "tradition," with the community's own account cited as the community gives it. The same rule applies to church traditions (Thomas in India in AD 52) and to Rome's founding (753 BC).
- **Archaeological dates show their method.** Radiocarbon ranges carry their confidence and calibration; period bands carry the authority that defines them (PeriodO).
- **Contact-era events cite both sides where both exist**, and the lane describes Indigenous nations as political communities, not as scenery for European arrival.
- **Sources with specialized terms** (Native Land Digital; tribal or nation-held archives) are linked or asked, never scraped.
- **Review by people with standing.** Before an Americas lane ships beyond a pilot, its scope notes should be read by scholars of those histories, and where possible by members of the nations described. This is a release gate for that lane, not a courtesy.

---

## 8. Transcript claims found wrong or sensational

Paraphrased; the transcripts' own wording does not ship. "Dispute" means the video took one side of a real disagreement and stated it as fact.

| Video | Claim (paraphrased) | Finding | Evidence |
|---|---|---|---|
| History of Ancient Israel Full DOCUMENTARY (Para Bellum) | Nehemiah was appointed governor in 458 BC | **Wrong.** 458 BC is Ezra's traditional date (Ezra 7:7, Artaxerxes's 7th year); Nehemiah's is 445 BC (Neh 2:1, the 20th year) | Israel Appendix C; Ezra 7:7; Neh 2:1 |
| same | In 153 BC a civil war broke out between Demetrius II and Alexander Balas | **Wrong rival.** Balas's challenge (153/152–150 BC) was against **Demetrius I** Soter; Demetrius II came later (147–145) | Livius (pilot H21) |
| 20. Persia - An Empire in Ashes (FoC) | Nebuchadnezzar besieged Jerusalem in 597 BC; after a thirty-month siege it fell and the Temple burned | **Conflation.** 597 was a short siege ending in surrender on 2 Adar (no burning); the long siege and the burning were 588–587/586 | Babylonian Chronicle; 2 Kgs 24:12; 25:1–9 |
| 1st Century Israel Judaea … (ArchieCastle) | The Roman governor attacked the Temple in AD 67 | **Wrong year.** Florus took Temple funds in AD 66, which helped spark the revolt; Vespasian arrived in 67 | Josephus, *Ant.* 20.257 (war began in Nero's 12th year, AD 66); Rome Appendix C |
| The Buried Biblical Mysteries … (Odyssey) | The Sicarii took Masada from the Romans in AD 73 | **Wrong.** They seized it in AD 66; 73 (or 74) is its fall | Rome Appendix C |
| The Great Revolt & The Siege of Masada (History Time) | Hadrian rebuilt Jerusalem at the beginning of the second century | **Imprecise.** Aelia Capitolina was founded c. AD 130 | Rome Appendix C (coins in the refuge caves) |
| The Great Revolt; Judea Under Roman Rule | Masada fell in AD 73 (stated flatly) | **Dispute stated as fact.** Many historians now prefer 74 (Eck; Cotton) | Rome Appendix C; pilot R22 |
| The Incredible History of the Jewish Temple | Herod's Temple construction began in 23 BC | **Minority as fact, not an error.** It matches *Jewish War* 1.401 (15th year); *Antiquities* 15.380 says the 18th year (20/19 BC), which most scholars follow | *Ant.* 15.380 read today |
| The Real History of Biblical Israel | The kingdom divided in 928 BC | **Dispute stated as fact.** 928 follows Cogan's chronology; Thiele has 931/930 | Pilot H10 |
| The ENTIRE History of Israel | The second temple's construction *began* in 516 BC | **Wrong.** It was *completed* in 516/515 (Ezra 6:15); work resumed in 520 (Haggai) | Ezra 6:15 |
| Lost Worlds: Lost City of the Bible | Prince Hattusili was appointed commander in chief of the Hittite army against Ramesses in 1274 BC | **Overstated.** King Muwatalli II led the army at Kadesh; Hattusili commanded under him | Pilot H05 |
| Exodus Evidence (*The Exodus Decoded* re-cut) | The Exodus "code has been cracked": the Exodus is the Hyksos expulsion; Santorini pumice at Avaris "proves" the ash cloud | **Overclaim.** Rejected by Bietak; pumice was a traded material; Thera's date is itself disputed | Israel Appendix B; pilot H03 |
| same | The excavator "has been forced to cover up his dig every single year" | **Sensational framing.** The film itself gives conservation as the reason; backfilling is ordinary practice | Israel Appendix B |
| The ENTIRE History of the Jews | "The Assyrian general Sennacherib" besieged Jerusalem in 701 BC | **Wrong title.** Sennacherib was king of Assyria | Pilot H15 |
| Before I Die, Please Listen — … Kramer | Kramer's "unpublished notes" reveal writing as mind control | **Fabricated.** Nothing in Kramer's work supports it | Israel Appendix B |
| AI Just Decoded the Dead Sea Scrolls … | AI "decoded" the scrolls and proved heavy revisions; the Bar Kokhba revolt fell "around 35 CE" | **Conflation and overclaim** (a 2021 cave find and a separate AI handwriting-dating study); "35" is a caption garble for 135 | Israel Appendix B |
| The Incredible History of the Jewish Temple | The Dome of the Rock was "constructed in 685" | **Imprecise** (begun in the 680s, completed 691/692 by the usual reading of its dated inscription) | Not checked against a P2 page today; to verify |
| How Rome Forged an Epic Empire (Engineering an Empire) | 12,000 Jewish captives built the Colosseum, financed by selling Temple relics | **No ancient source for 12,000.** Josephus gives 97,000 captives in all (*War* 6.420); the reconstructed dedication says the building was paid for from war spoils (*ex manubiis*), not by selling relics | Rome Appendix B; pilot R24 |
| same | Nero died in "69 A.D." | **Wrong.** June AD 68 | Rome Appendix B |
| The Untold Story Of Emperor Vespasian | Jotapata held out 40 days; the triumph was in October 70 | **Wrong on both.** 47 days (*War* 3.316); the joint triumph was June 71 | Rome Appendix B / C |
| Complete History Of The Roman Republic (Odyssey) | Actium was fought in the Gulf of Corinth; war was declared on Antony and Cleopatra | **Wrong.** The Ambracian Gulf; war was declared on Cleopatra | Rome Appendix B |
| Who Were The Greatest Caesars … (Robinson) | "Fiddling while Rome burns" (as the legend's frame) | **Legend, and the film says so.** Tacitus has Nero at Antium when the fire began and reports only a *rumor* that he sang of Troy | Tacitus, *Annals* 15.39 |

---

## 9. The interface (WebView2 face)

**The main view: zoomable parallel lanes.** Time runs left to right; lanes stack top to bottom, grouped and collapsible. Zoom is *semantic*: at millennium scale, periods and reigns; at century scale, major events; at decade or year scale, everything. Each event shows its certainty pattern (Section 5.2) and a provenance badge (P1, P2, P3; a P4 badge never appears in the public edition because P4-only events never ship).

**Disputes are drawn, not hidden.** A disputed event is drawn as all its positions, stacked and bracketed, inside the dispute's envelope. If Larry has ruled, his lean carries a marker with its confidence and wording ("AD 33 over AD 30: 0.60, a lean, not consensus"). Nothing is pre-selected for the reader.

**Click an event → the event panel:**
- the title and summary (our words), with dates in BC/AD or BCE/CE and the **original expression** ("in the fifteenth year of Tiberius");
- **Sources**, grouped by grade, each with its locator, date of composition ("written about AD 93, 160 years later"), license and link;
- **Who said what:** every assertion, including the videos, with agree / disagree / partial; flagged claims in a "What popular sources say" box (paraphrased, with the correction);
- **Verses:** linked passages, opening in the verse hub;
- **People and places,** with a small map (Pleiades and OpenBible coordinates, their confidence shown);
- **Disputes,** with each position's holders.

**"What was happening when this verse was written?"** From any verse, the hub's Timeline tab offers two times, kept separate because they are different:
- **Narrated time:** when the events the verse describes happened (Luke 3:1 → AD 28/29 on the usual count).
- **Composition time:** when the book was written, itself usually a range and often disputed (Romans c. AD 57; Hebrews c. 60s–80s).

Either one opens the **synchronism slice**: every visible lane at that moment. Who ruled in Rome, Parthia, Han China, Kush and Aksum; which events overlap; what the church lane shows. The slice lists each item with its certainty pattern, so a firm Roman date never lends its firmness to a soft Hopewell range beside it.

**Sync with the verse hub.** Selecting an event highlights its verses in the hub; opening a verse in the hub can pin its narrated and composition times on the timeline. Both views share one selection.

**Other views:** a rulers table ("who reigned where in AD 50"), generated from reign events; a dispute index; a FAILS index (claims the timeline refutes); and a "Discovery" toggle that overlays when key witnesses were found.

### How it carries the innovations (`10-INNOVATIONS FROM PRACTICE.md`)

| Innovation | In the timeline |
|---|---|
| **I-P01 Claim Check** | Paste "Herod's Temple was begun in 23 BC" → DISPUTED: *War* 1.401 (15th year) vs *Antiquities* 15.380 (18th year, 20/19 BC), with the majority view. Paste "Masada fell in 73" → DISPUTED, 73 vs 74. Paste "the kingdom split in 931" → one position of two |
| **I-P03 FAILS always shown** | Refuted claims (the Wednesday crucifixion; the Exodus = Hyksos-expulsion thesis; "12,000 captives") stay in a FAILS bucket, linked to the events they misdate |
| **I-P05 Share-safe export** | An exported slice (image, text, or CSV) carries each item's status and grade badges and its dispute positions; any UNVERIFIED item (private edition only) is visibly marked, and an option strips it |
| **I-P09 Range before ruling** | Every disputed date opens on all positions and the envelope before any lean |
| **I-P12 Study ledger** | Timeline queries ("everything AD 40–60, Rome + Church + Han") are logged and replayable |
| **I-P16 The human adjudicates** | The engine shows positions; Larry's leans are labeled as his; the reader can record their own ruling in `user.db` |

---

## 10. The pilot

**Scope:** 61 candidate events, more than the planned 40 because effort was not the constraint: 21 Israel and ancient Near East events (patriarchs to the Maccabees), 30 Rome events (753 BC–AD 476, weighted to the New Testament era; the Judea–Rome overlap events sit on both lanes), and 10 cross-lane synchronisms from the new lanes. The full rows (dates, lanes, verses, lead files, sources, URLs) are in `11-timeline-pilot.csv`.

**Status key.** VERIFIED: a P1 or P2 source was opened today and agrees. DISPUTED: competing positions, each with its holders and sources. P3-ONLY: anchored in Larry's verified writing (shippable under the rule) but no P1 or P2 page could be opened today (most often Britannica or museum pages refusing the fetch). UNVERIFIED: only P4 (Wikipedia, transcripts) or, for H01, no date exists to verify. Wikipedia pages were opened only as pointers and never counted.

| Group | Rows | VERIFIED | DISPUTED | P3-ONLY | UNVERIFIED |
|---|---|---|---|---|---|
| Israel/ANE | 21 | 11 | 7 | 2 | 1 |
| Rome | 30 | 17 | 7 | 6 | 0 |
| Synchronism | 10 | 3 | 4 | 0 | 3 |
| **Total** | **61** | **31** | **18** | **8** | **4** |

### 10.1 Israel and the ancient Near East

| ID | Event | Date | Lanes | Verses | Status | Checked against | Flags |
|---|---|---|---|---|---|---|---|
| H01 | Patriarchal narratives (Abraham to Jacob) | No absolute date (narrative sequence only) | israel-judah | Gen 11:31; Gen 12:4; Exod 12:40; 1Kgs 6:1 | **UNVERIFIED** | P1 (text only) | - |
| H02 | Hyksos rule at Avaris; expelled by Ahmose I | c. 1650-1550 BC; expulsion c. 1550-1540 BC | egypt; canaan-phoenicia | - | **P3-ONLY** | P3 | yes |
| H03 | Thera (Santorini) eruption | DISPUTED: c. 1600s BC (radiocarbon) vs c. 1550-1500 BC (archaeological); 2025 study: before Ahmose I | greece-aegean; egypt | - | **DISPUTED** | P2; P3 | yes |
| H04 | Amarna letters, incl. Abdi-Heba of Jerusalem | c. 1353-1336 BC (Akhenaten's reign and its neighbors) | egypt; canaan-phoenicia | - | **VERIFIED** | P1; P3 | - |
| H05 | Battle of Kadesh (Ramesses II vs Muwatalli II) | 1274 BC (low chronology; Ramesses II year 5) | egypt; hittites | - | **P3-ONLY** | P3 | yes |
| H06 | Merneptah Stele names "Israel" | c. 1208 BC (Merneptah year 5) | egypt; israel-judah | - | **VERIFIED** | P2; P3 | - |
| H07 | The Exodus | DISPUTED: c. 1446 BC / c. 1270-1260 BC / no mass exodus / small kernel | israel-judah; egypt | Exod 1:11; Exod 12:40; 1Kgs 6:1 | **DISPUTED** | P2; P3 | yes |
| H08 | Late Bronze Age collapse | c. 1200-1150 BC | egypt; hittites; canaan-phoenicia; greece-aegean | Amos 9:7 | **VERIFIED** | P2; P3 | - |
| H09 | Reign of David; Jerusalem under Israelite control | c. 1010-970 BC (biblical reckoning); scale and Iron Age dating disputed | israel-judah | 2Sam 5:4 | **DISPUTED** | P3 | yes |
| H10 | The kingdom divides (Rehoboam and Jeroboam) | DISPUTED by scheme: 931/930 BC (Thiele) / 928 BC (Cogan table) / 932 BC (Themelios revision) | israel-judah | 1Kgs 12:20 | **DISPUTED** | P2; P3 | yes |
| H11 | Shoshenq I (Shishak) campaigns in the Levant | c. 925 BC (Rehoboam's fifth year) | egypt; israel-judah | 1Kgs 14:25 | **VERIFIED** | P1; P2 | - |
| H12 | Battle of Qarqar; "Ahab the Israelite" | 853 BC | assyria; israel-judah; aram | 1Kgs 16:29 | **VERIFIED** | P1; P3 | - |
| H13 | Jehu pays tribute to Shalmaneser III (Black Obelisk) | 841 BC | assyria; israel-judah | 2Kgs 9:24; 2Kgs 10:32 | **VERIFIED** | P2; P3 | - |
| H14 | Fall of Samaria; end of the northern kingdom | DISPUTED: 722 BC (Shalmaneser V) / 723 BC / 720 BC (Sargon II's claim) | assyria; israel-judah | 2Kgs 17:6; 2Kgs 18:10 | **DISPUTED** | P1; P2; P3 | - |
| H15 | Sennacherib's campaign against Judah | 701 BC | assyria; israel-judah; kush | 2Kgs 18:13; 2Kgs 19:9 | **VERIFIED** | P2; P3 | yes |
| H16 | Jerusalem surrenders; first deportation (Jehoiachin) | 2 Adar, Nebuchadnezzar year 7 = February/March 597 BC (16 March in Israel App C) | babylon; israel-judah | 2Kgs 24:12; Jer 52:28 | **VERIFIED** | P1; P2; P3 | yes |
| H17 | Jerusalem and the First Temple destroyed | DISPUTED: 587 BC vs 586 BC (Nebuchadnezzar year 19) | babylon; israel-judah | 2Kgs 25:8; Jer 52:12 | **DISPUTED** | P1; P2; P3 | - |
| H18 | Babylon falls to Cyrus | 16 Tashritu = c. 12 October 539 BC; Cyrus enters 3 Arahsamnu (c. 29 October) | persia; babylon | Dan 5:30; Ezra 1:1 | **VERIFIED** | P1; P2 | - |
| H19 | Second Temple completed | 3 Adar, Darius I year 6 = early 515 BC (516/515) | persia; israel-judah | Ezra 6:15 | **VERIFIED** | P1; P3 | yes |
| H20 | Missions of Ezra and Nehemiah | DISPUTED: Ezra 458 & Nehemiah 445 / Nehemiah 445 & Ezra 398 / Ezra c. 428 | persia; israel-judah | Ezra 7:7; Ezra 7:8; Neh 2:1 | **DISPUTED** | P1; P2; P3 | yes |
| H21 | Antiochus IV desecrates the Temple; Maccabees rededicate it | 15 Chislev 145 SE (December 167 BC); rededication 25 Chislev 148 SE (December 164 BC) | hellenistic; israel-judah; second-temple | Dan 11:31 | **VERIFIED** | P1; P3 | yes |

### 10.2 Rome (753 BC-AD 476; Judea overlap rows sit on both lanes)

| ID | Event | Date | Lanes | Verses | Status | Checked against | Flags |
|---|---|---|---|---|---|---|---|
| R01 | Traditional founding of Rome | 21 April 753 BC (Varro's reckoning; tradition) | rome | - | **P3-ONLY** | P3 | - |
| R02 | Gauls sack Rome | DISPUTED: 390 BC (Varronian) vs 387/386 BC (Polybius) | rome | - | **DISPUTED** | P3 | yes |
| R03 | Carthage destroyed | 146 BC | rome; carthage | - | **VERIFIED** | P2; P3 | yes |
| R04 | Pompey takes Jerusalem | 63 BC | rome; israel-judah; second-temple | - | **VERIFIED** | P1; P3 | - |
| R05 | Julius Caesar assassinated | 15 March 44 BC | rome | - | **VERIFIED** | P1; P3 | - |
| R06 | Battle of Actium | 2 September 31 BC | rome; egypt | - | **VERIFIED** | P1; P3 | yes |
| R07 | Octavian receives the name Augustus | 16 January 27 BC | rome | Luke 2:1 | **VERIFIED** | P1; P3 | - |
| R08 | Herod begins rebuilding the Temple | DISPUTED: 20/19 BC (Herod's 18th year) vs 23/22 BC (15th year) | second-temple; rome | John 2:20 | **DISPUTED** | P1; P2 | yes |
| R09 | Death of Herod the Great | DISPUTED: spring 4 BC (consensus) vs 1 BC (minority) | rome; second-temple | Matt 2:1; Matt 2:19 | **DISPUTED** | P1; P3 | - |
| R10 | Judea annexed; census under Quirinius | AD 6/7 | rome; second-temple | Acts 5:37; Luke 2:2 | **VERIFIED** | P1; P3 | - |
| R11 | Augustus dies; Tiberius succeeds | 19 August AD 14 | rome | Luke 3:1 | **VERIFIED** | P1; P3 | - |
| R12 | Pontius Pilate, prefect of Judea | AD 26-36/37 | rome; second-temple | Luke 3:1; Luke 13:1 | **VERIFIED** | P1; P3 | - |
| R13 | Crucifixion of Jesus | DISPUTED: Friday 7 April AD 30 vs Friday 3 April AD 33 (envelope AD 29-34) | rome; second-temple; church | John 19:31; Mark 15:42; Luke 3:23 | **DISPUTED** | P3 | - |
| R14 | Caligula orders his statue set up in the Temple | late 39 or 40 to January 41; Caligula killed 24 January AD 41 | rome; second-temple | - | **VERIFIED** | P1; P3 | yes |
| R15 | Death of Agrippa I at Caesarea | AD 44 | rome; second-temple; church | Acts 12:21; Acts 12:23 | **VERIFIED** | P1; P3 | - |
| R16 | Claudius acts against the Jews of Rome | DISPUTED: AD 49 (expulsion) vs AD 41 (assembly ban); undated in Suetonius | rome; church | Acts 18:2 | **DISPUTED** | P1; P3 | - |
| R17 | Gallio proconsul of Achaia; Paul before him at Corinth | AD 51-52 | rome; church | Acts 18:12 | **VERIFIED** | P2; P3 | - |
| R18 | Great Fire of Rome; Nero blames the Christians | from the night of 18/19 July AD 64 | rome; church | - | **VERIFIED** | P1; P3 | yes |
| R19 | The Jewish War begins | spring/summer AD 66 (Nero's twelfth year) | rome; second-temple | Luke 21:20 | **VERIFIED** | P1; P3 | yes |
| R20 | Year of the Four Emperors | Nero dies 9 June 68; Vespasian acclaimed 1 July 69 (Alexandria) | rome | - | **VERIFIED** | P1; P3 | yes |
| R21 | Second Temple burned | 10 Lous (Av), AD 70 (August) | rome; second-temple; church | Luke 21:20; Matt 24:2 | **VERIFIED** | P1; P2 | yes |
| R22 | Masada falls | DISPUTED: spring AD 73 vs spring AD 74 (15 Xanthicus) | rome; second-temple | - | **DISPUTED** | P1; P2; P3 | yes |
| R23 | Vesuvius buries Pompeii and Herculaneum | DISPUTED: 24 August AD 79 vs 24 October AD 79 | rome | - | **DISPUTED** | P2; P3 | - |
| R24 | The Colosseum (Flavian Amphitheater) built | begun c. AD 70-72; dedicated AD 80 | rome; second-temple | - | **P3-ONLY** | P3 | yes |
| R25 | Pliny's letter to Trajan on the Christians | c. AD 111-112 (Bithynia-Pontus) | rome; church | - | **P3-ONLY** | P3 | - |
| R26 | Bar Kokhba revolt | AD 132 to late 135 or early 136 | rome; second-temple; church | - | **VERIFIED** | P1; P3 | yes |
| R27 | Constantine wins at the Milvian Bridge; the 313 letter on toleration | 28 October 312; 313 | rome; church | - | **P3-ONLY** | P3 | yes |
| R28 | Council of Nicaea | opened May or June 325 (20 May and 19 June both transmitted); closed c. 25 August | rome; church | - | **P3-ONLY** | P3 | - |
| R29 | Alaric's Goths sack Rome | 24 August 410 | rome; europe-after-rome | - | **P3-ONLY** | P3 | yes |
| R30 | Odoacer deposes Romulus Augustulus | 4 September 476 | rome; europe-after-rome | - | **VERIFIED** | P2; P3 | yes |

### 10.3 Cross-lane synchronisms (new lanes)

| ID | Event | Date | Lanes | Verses | Status | Checked against | Flags |
|---|---|---|---|---|---|---|---|
| S01 | Wang Mang's Xin dynasty interrupts the Han (China) | AD 9-23 | china | Luke 2:42 | **UNVERIFIED** | P4 only | - |
| S02 | Gan Ying sent toward Da Qin (the Roman world) | AD 97 | china; silk-road; rome | - | **VERIFIED** | P1 | - |
| S03 | Envoys "from Andun, king of Da Qin," reach the Han court | AD 166 | china; rome | - | **DISPUTED** | P1 | - |
| S04 | Ashoka's Rock Edict XIII names five Greek kings (India) | c. 260-250 BC (conventional) | india; hellenistic | - | **DISPUTED** | P1 | - |
| S05 | Kush and Rome at war; the Kandake's envoys at Samos | c. 25-21 BC | kush; rome; egypt | Acts 8:27 | **VERIFIED** | P1; P1 | - |
| S06 | Ezana of Aksum turns to Christianity (Ethiopia) | DISPUTED: mid-330s to 340s (coins, inscriptions) vs tradition c. 324-330 | aksum; church | - | **DISPUTED** | P2 | - |
| S07 | Earliest Long Count dates (Mesoamerica) | 36 BC (Chiapa de Corzo Stela 2, uncertain); 32 BC (Tres Zapotes Stela C) | mesoamerica | - | **UNVERIFIED** | P4 only | - |
| S08 | Teotihuacan's Pyramid of the Sun built (Mesoamerica) | DISPUTED: 1st century AD vs c. AD 170-310 | mesoamerica | - | **DISPUTED** | P2 | - |
| S09 | Hopewell earthworks (Indigenous North America) | c. AD 1-400 (archaeological period) | indigenous-north-america | - | **VERIFIED** | P2 | - |
| S10 | Tradition: the apostle Thomas in India; Roman trade with Muziris | Tradition: Thomas lands AD 52 (class G); trade: 1st-2nd centuries AD | india; church | - | **UNVERIFIED** | P4 only | - |

### 10.4 What the pilot showed

1. **The rule sorts cleanly.** Of 61 rows: 31 VERIFIED, 18 DISPUTED, 8 P3-ONLY, 4 UNVERIFIED. Every Israel and Rome row is anchored in P1, P2 or P3 except H01 (the patriarchs), which has no date to anchor and is drawn off-axis by design (CL #19). The three UNVERIFIED synchronisms (Xin dynasty, earliest Long Count dates, Thomas in India) rested only on Wikipedia within this session's budget, so they stay out of the shipped build until a P1 or P2 page is opened.
2. **Disputes are the norm, not the exception.** 18 of 61 rows carry competing positions, and in four of them the "error" in a video turned out to be one side of a real dispute (Herod's Temple 23 vs 20/19 BC; the division 928 vs 931/930; Masada 73 vs 74; Vesuvius August vs October). The flag kinds `minority-as-fact` and `overclaim` are needed beside `wrong-date`.
3. **Some disputes live inside one source.** Josephus gives Herod's 15th year in *War* and his 18th in *Antiquities*; Kings says the 7th of Av and Jeremiah the 10th for the Temple's burning. The model must let one author be a holder on both sides.
4. **The local primary texts carried a lot.** Nine rows were anchored in `primary_evidence.db` and `bible.db` without the web (Pompey, Herod's eclipse, Quirinius, Pilate, Agrippa I, the war's start, 1 Maccabees, Ezra 6:15, Amarna). Adding Josephus's *Jewish War* (Gutenberg #2850, public domain) would cover most of the rest of the first century.
5. **The web is a weak P2 channel for fetch-based verification.** Britannica, British Museum object pages, Perseus and several Livius pages refused or truncated the fetch. Eight rows ended P3-ONLY for that reason alone. The build should hold a curated shelf of P2 works (with page references) rather than depend on live fetches.
6. **Larry's histories are reliable enough to be the default anchor, and they were right where the web disagreed with the videos.** Where today's P1/P2 checks touched an Appendix C claim, none contradicted it; some added a position (Themelios's 723 for Samaria; 932 for the division). One nuance: Appendix C gives 16 March 597 BC as a day; the chronicle gives 2 Adar, and the Julian day is a modern conversion. The timeline should show both.
7. **Synchronisms work and are the payoff.** Gan Ying (AD 97, P1 *Hou Hanshu*) beside Nerva and 1 Clement; Strabo's "Candace" envoys at Samos (c. 21 BC) beside Acts 8:27's Kandake title; Hopewell (AD 1–400, NPS) as a soft band under the whole New Testament era; Teotihuacan's pyramid as a two-position dispute. Each keeps its own certainty pattern, so a firm Roman date does not lend firmness to a soft range beside it.

---

## 11. Decisions for Larry

1. **D-0xx: `history.db` as a separate read-only database** beside `core.db` (recommended), or tables inside `core.db`.
2. **Era labels:** default display BC/AD (the vault's and both histories' convention) with a BCE/CE setting. Recommended: BC/AD default.
3. **Larry's leans in the public edition:** show Controversy Lab leans (with confidence and wording) as "Larry's lean"? Recommended: yes, since rix.db ships (D-019), always labeled and never pre-selected.
4. **Unverified layer:** keep UNVERIFIED candidates entirely out of the public build (recommended), or ship them hidden behind a "research leads" switch with a P4 badge. The rule as written says never ship; this keeps it.
5. **Americas and other non-core lanes:** ship as "preview" lanes after the scope-note review in 7.1, or hold until reviewed.
6. **Theographic and Seshat:** use as leads only (recommended); never import their dates.

---

## References (pages fetched 2026-10-06)

Licenses and channels: Wikidata licensing https://www.wikidata.org/wiki/Wikidata:Licensing · Wikidata dates https://www.wikidata.org/wiki/Help:Dates · Wikipedia copyrights https://en.wikipedia.org/wiki/Wikipedia:Copyrights · Pleiades https://pleiades.stoa.org/ · OpenBible geocoding https://www.openbible.info/geo/ and https://github.com/openbibleinfo/Bible-Geocoding-Data · STEPBible-Data https://github.com/STEPBible/STEPBible-Data · Theographic https://github.com/robertrouse/theographic-bible-metadata (chronology bibliography in docs/data-source-bibliography.md) · Livius https://www.livius.org/about/ · Perseus https://github.com/PerseusDL/canonical-greekLit · LacusCurtius copyright https://penelope.uchicago.edu/Thayer/E/HELP/Copyright/home.html · Project Gutenberg license https://www.gutenberg.org/policy/license.html · CCEL https://www.ccel.org/about/copyright.html · PeriodO https://perio.do/en/ · World Historical Gazetteer https://whgazetteer.org/licenses/ · Seshat https://github.com/datasets/seshat · ctext https://ctext.org/faq · Native Land https://native-land.ca/about/ · YouTube Terms https://www.youtube.com/t/terms

Vault inputs (read, not modified): `Rix/Upcoming Projects/Bible Study Workbench - Design (2026-10-06).md`; `Rix/History/` (both histories, `_Israel Build/` plan, handoff, Appendices B and C); `Rix/Controversy Lab/18 …/07 - VERDICT.md`, `19 …/06 - VERDICT.md`, `17 …/06 - VERDICT.md`; `Rix/Data/data/primary_evidence.db`, `bible.db`; `Rix/Data/_transcripts.db README.md`; `D:\prod\simple_ocr_capture\CHANGELOG.md` (v1.15 channel harvest).
