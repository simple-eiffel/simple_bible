# 27: INCIPIT PACK SCHEMA, version 1 (incipit.db)

*Drafted 2026-11-11 from research 26 and the plan doc "INCIPIT and CHIASM: Plan for simple_bible". Larry's decisions that bind it: LXX basis and LXX numbering; the Hebrew only as an easy second look; LXX-only books shown by default, labeled; the file is `incipit.db`; "incipit" is one kind among the others; BSB is the English; no review buttons (Larry reviews as he goes).*

## Place in simple_bible

A private pack like `empires.db` and `timeline.db`: schema class `BIB_INCIPIT_SCHEMA` (heir of `BIB_PRIVATE_PACK_SCHEMA`), reader `BIB_INCIPIT_PACK` (heir of `BIB_PRIVATE_PACK_READER`), builder `BIB_INCIPIT_BUILDER` run by `bible_build --incipit`, attached read-only by `BIB_PRIVATE_SOURCE`. Common tables (`meta`, `source_provenance`, `writing_search`, `writing_words`) come from the ancestor; `writing_search` indexes the stories.

**License:** mixed, so `pack_license` is redefined: the UBS Parallel Passages rows are CC BY-SA 4.0 (share-alike: the link rows derived from them carry it); Hühn, Dittmar and the other 19th-century lists are public domain; the stories are Larry's own work, free to share. Each row names its source through `provenance_key`; Help > About lists them all.

## Tables (`pack_tables`)

```sql
-- The declared tests: every kind is a definition with what would make it fail (shape.db's rule).
CREATE TABLE link_kind(
  kind TEXT PRIMARY KEY CHECK (kind IN ('incipit','quotation','allusion','echo','word_link','motif')),
  label TEXT NOT NULL,               -- what the reader sees: "incipit", "quotation" ...
  definition_formal TEXT NOT NULL,   -- the test, in terms the measure can answer
  could_fail_if TEXT NOT NULL,
  mark_style TEXT NOT NULL CHECK (mark_style IN ('solid','dotted','faint')));

-- A whole source passage a link points into: Psalm 22 entire, not 22:1.
CREATE TABLE source_unit(
  unit_id INTEGER PRIMARY KEY,
  lxx_book TEXT NOT NULL, lxx_ch_from INTEGER NOT NULL, lxx_v_from INTEGER NOT NULL,
  lxx_ch_to INTEGER NOT NULL, lxx_v_to INTEGER NOT NULL,      -- LXX numbering (the key)
  hebrew_ref TEXT NOT NULL,          -- "Psalm 22" ('' for an LXX-only book)
  english_ref TEXT NOT NULL,         -- "Psalm 22" (BSB numbering)
  title TEXT NOT NULL,
  book_class TEXT NOT NULL CHECK (book_class IN ('hebrew_canon','lxx_only','outside')),
  provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key));

-- One link: an NT range drawing on an LXX range.
CREATE TABLE incipit_link(
  link_id INTEGER PRIMARY KEY,
  nt_book TEXT NOT NULL, nt_ch INTEGER NOT NULL, nt_v_from INTEGER NOT NULL, nt_v_to INTEGER NOT NULL,
  lxx_book TEXT NOT NULL, lxx_ch INTEGER NOT NULL, lxx_v_from INTEGER NOT NULL, lxx_v_to INTEGER NOT NULL,
  unit_id INTEGER NOT NULL REFERENCES source_unit(unit_id),
  kind TEXT NOT NULL REFERENCES link_kind(kind),
  volume REAL NOT NULL CHECK (volume >= 0),       -- the measure's score (0 when only a list names it)
  loudness TEXT NOT NULL CHECK (loudness IN ('loud','clear','quiet','theme')),  -- volume against the chance lines
  follows TEXT NOT NULL CHECK (follows IN ('lxx','hebrew','both','unknown')),
  run_id INTEGER REFERENCES measure_run(run_id),  -- NULL when no measure scored it
  provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key),
  CHECK (nt_v_from <= nt_v_to AND lxx_v_from <= lxx_v_to));
CREATE INDEX incipit_link_nt ON incipit_link(nt_book, nt_ch, nt_v_from);
CREATE INDEX incipit_link_lxx ON incipit_link(lxx_book, lxx_ch, lxx_v_from);

-- Who else heard it: one row per list (or shape, or Larry) that names the link.
CREATE TABLE link_witness(
  link_id INTEGER NOT NULL REFERENCES incipit_link(link_id),
  witness TEXT NOT NULL CHECK (witness IN ('ubs','huhn','dittmar','openbible','shape','larry','measure')),
  detail TEXT NOT NULL,              -- Hühn "**" / "*" / "", a shape slug, OpenBible votes ...
  provenance_key INTEGER NOT NULL REFERENCES source_provenance(provenance_key),
  PRIMARY KEY (link_id, witness, detail));

-- The evidence the panel lights: words shared by the two sides.
CREATE TABLE link_word(
  link_id INTEGER NOT NULL REFERENCES incipit_link(link_id),
  side TEXT NOT NULL CHECK (side IN ('nt','lxx')),
  seq INTEGER NOT NULL,              -- order within the side
  surface TEXT NOT NULL,             -- the form as printed in that edition
  headword TEXT NOT NULL,            -- the shared headword (conc.db's)
  PRIMARY KEY (link_id, side, seq));

-- The measure's features for each scored link (why the program thinks so).
CREATE TABLE link_feature(
  link_id INTEGER NOT NULL REFERENCES incipit_link(link_id),
  feature TEXT NOT NULL CHECK (feature IN ('align','lex','form','run','share','rare','dist')),
  value REAL NOT NULL,
  PRIMARY KEY (link_id, feature));

-- One run of the measure: its version, data and chance lines.
CREATE TABLE measure_run(
  run_id INTEGER PRIMARY KEY,
  measure_version TEXT NOT NULL,     -- "v0.3"
  run_on TEXT NOT NULL,              -- ISO date
  nt_edition TEXT NOT NULL, lxx_edition TEXT NOT NULL,
  candidates INTEGER NOT NULL,
  chance_95 REAL NOT NULL, chance_99 REAL NOT NULL, chance_999 REAL NOT NULL,
  method TEXT NOT NULL);

-- A New Testament scene that uses a source unit (Matthew 27:35-54 with Psalm 22).
CREATE TABLE scene(
  scene_id INTEGER PRIMARY KEY,
  unit_id INTEGER NOT NULL REFERENCES source_unit(unit_id),
  nt_book TEXT NOT NULL, nt_ch_from INTEGER NOT NULL, nt_v_from INTEGER NOT NULL,
  nt_ch_to INTEGER NOT NULL, nt_v_to INTEGER NOT NULL,
  title TEXT NOT NULL);

-- The written stories: source story, scene framing, forward story; each section labeled.
CREATE TABLE story(
  story_id INTEGER PRIMARY KEY,
  unit_id INTEGER NOT NULL REFERENCES source_unit(unit_id),
  scene_id INTEGER REFERENCES scene(scene_id),      -- NULL for source and forward stories
  story_kind TEXT NOT NULL CHECK (story_kind IN ('source','scene','forward')),
  title TEXT NOT NULL,
  vault_path TEXT NOT NULL,          -- vault-relative, e.g. "Incipit/Psalm 22/01 - Matthew 27.md"
  CHECK ((story_kind = 'scene') = (scene_id IS NOT NULL)));
CREATE TABLE story_section(
  story_id INTEGER NOT NULL REFERENCES story(story_id),
  seq INTEGER NOT NULL,
  heading TEXT NOT NULL,
  body TEXT NOT NULL,                -- markdown
  status TEXT NOT NULL CHECK (status IN ('larry_posted','larry_framework','larry_draft','larry_approved','claude_take')),
  sources TEXT NOT NULL,             -- vault-relative files the section draws on, one per line
  PRIMARY KEY (story_id, seq));
```

## Loudness from the chance lines

`loudness` is set from the measure run's chance lines (the loudest score a fake verse of random NT words reaches; chance_control.py 2026-11-11: median 27.5, 95th 33.3, 99th 37.3, 99.9th 42.2): `loud` above the 99.9th percentile, `clear` above the 99th, `quiet` above the median, `theme` below it or unscored (a link a scholar's list names but the words do not carry). The first draft put `quiet` at the 95th; that labeled Matthew 27:43 <- Psalm 21:9 (volume 32.3, the verse's top candidate, real shared words) a theme, so the line moved to the median. The reader's "loud only" filter shows `loud` and `clear`. Refinement owed: a chance line matched to the verse's length.

A link only the measure found (no list names it) is kept only when it is its NT verse's loudest candidate and above the 99th line: "from my mother's womb" otherwise tied five unrelated verses to Psalm 21:11.

Manifest v1 (`make_links_manifest.py`, 2026-11-11): 4,219 links; incipit 9, quotation 524, allusion 3,686; loud 789, clear 680, quiet 161, theme 2,589.

## The split: vault tools prepare, bible_build checks and writes

As with timeline.db (vault seed JSON -> `bible_build --timeline`) and the conc.db and shape.db builders: the measure and the list parsers are vault tools (research scripts now in the session scratchpad `incipit/tools/`, to move to vault `Rix/_Tools/incipit/`). They write one manifest, `incipit.links.json` (kinds, source units, the measure run, links with witnesses, words and features), and one manifest per source unit for the stories (`Incipit/<unit>/_manifest.json` naming its markdown files). `bible_build --incipit` (Eiffel, BIB_INCIPIT_BUILDER) reads them, checks every row against the schema's lists and the versification, refuses a broken manifest by name, and writes incipit.db. No Python ships in the product.

## What the builder reads

1. UBS `ParallelPassages.xml` (OT-to-NT groups), mapped to LXX numbering by conc.db `unit_map` (MT->LXX).
2. Hühn 1899 parsed rows (clean subset first: paren form, validated), `**`/`*` -> quotation, unmarked -> allusion or motif by volume.
3. The measure's scored candidates above the 99th-percentile chance line that no list names, kind by the declared tests, witness `measure`.
4. shape.db Enoch shapes as `motif` links with witness `shape` (1 Enoch is `outside`, keyed by its own numbering).
5. The vault `Incipit/` folder: one manifest per source unit (the books and essays packs' pattern), its markdown files cut into `story_section` rows by their status labels.

## Built (2026-11-11, branch feature/incipit-pack, local, not committed)

- `src/pack/bib_incipit_schema.e`, `build/bib_incipit_builder.e`, `src/pack/bib_incipit_pack.e` (`links_from`, `links_into`, `link_count`), `SIMPLE_BIBLE.incipit_packs`, `bible_build --incipit`; `testing/test_incipit.e` (5 tests). Suite: 228 passed, 48 skeletal, 0 failed (F_code).
- Every table carries NOT NULL `voice` and `provenance_key` (BIB_PRIVATE_SOURCE's pack rule; the first build without them was refused at open). UBS rows `trusted`; Hühn and measured rows `hold loosely (datum only)`; kinds `author`.
- Real pack written to the session scratchpad only (not installed): 4,219 links, 735 units, 4,295 witnesses, 16,639 features, in 1.1 seconds with bible_build_lean.
- Known data gaps seen in the Psalm 22 read-back: Matthew 27:46 carries only the UBS witness (Hühn's "*2746" line misread by the OCR as "*92746"); Matthew 19:12 <- Psalm 21:11 ("from the mother's womb") is a stock phrase the top-candidate rule still lets through.

## Audit of every link (2026-11-12, 0.7.66)

Larry caught "Deuteronomy 31:30 -> Acts 11:22, allusion, clear, measured" (shared: the stock phrase "into the ears", 35 LXX verses): "please check ALL of these. that is a pretty misleading error that I cannot allow to be published." `audit_links.py` checked all 4,219: UBS words agree 497 (+1: Mark 15:28, absent from WH); Hühn with shared rare words 830; Hühn with no shared word but a neighboring NT verse sharing words 367 (likely misread verse numbers); Hühn with no shared word anywhere 1,424 (an allusion by idea, or a misread); measured-only stock phrase 244, names only 40, distinctive 816. A strict bar on the measured-only (loud, a shared run of 2+ words in 5 or fewer LXX verses: 273) still read about half coincidences in a 12-row sample ("rolled the stone", "ninety-nine", "oil and wine"). Rule adopted (memory: verified-links-only): the pack keeps only UBS and word-confirmed Hühn rows (1,328 links in 352 units: incipit 9, quotation 496, allusion 823); the 1,100 program-found and 1,791 unverifiable Hühn rows went to vault review lists (`Incipit/_Review/Candidates - found by the program.md`, `Candidates - Huehn 1899 unverified.md`) with KJV text; rows Larry approves return as his. Casualty to note: Luke 23:35 <- LXX Psalm 21:8-9 (the LXX-only "watching / sneered / let him save" find) is now a review row.

## Open technical points (settled by a spike, not by Larry)

- Kind assignment rules (definition_formal text for each kind) are drafted from the measure's features and tested on UBS and Hühn before they are fixed.
- `link_word` surfaces come from conc.db's editions (WH, Rahlfs); the reader shows BSB English and the Greek of the version on screen, so the panel lights words by headword, not by position.
- Whether a public build may ship rows scored on Rahlfs lemmas (Larry's earlier question 3 in research 26 remains open; the personal edition first).
