# 15 — Reference and query parsers from formal grammars (Gobo spike): pointer (2026-10-23)

**From:** the GOBO session, 2026-10-21. Relayed to the BIBLE session 2026-10-23 at Larry's prompt ("See the GOBO session for some gobo tools it sussed out that will help in locating bible and other verse references").
**Status:** research input. Nothing in simple_bible's spec, contracts or code has changed. The spike lives outside this repository.

## What it is (and is not)

- **A PARSER, not a detector.** Given a candidate string ("Rom 8:28, 30") it returns a reference, refuses it, or returns every reading when ambiguous. It does **not** find references in running prose. For D-020's "scripture reference detector" it supplies the back half (validate and normalize a candidate), not the front half (spot candidates in text). Recall on real prose was not measured.
- **Tools:** Gobo 26.10 `gelex` (lexer generator) and `geyacc` (parser generator), build-time only; they write plain Eiffel classes from `.l`/`.y` grammars.
- **Runtime:** the generated classes inherit Gobo's `YY_COMPRESSED_SCANNER_SKELETON` and `YY_PARSER_SKELETON` (Gobo kernel, lexical and parse skeleton libraries).
- **Adapters** keep simple_bible's frozen `BIB_REFERENCE_PARSER` / `BIB_QUERY_PARSER` signatures and postconditions and return `BIB_PARSE_RESULT` / `BIB_QUERY`. A stand-in book table replaces `BIB_BOOK_CATALOG` for now.

## What the GOBO session reports as run

- Both grammars: 0 conflicts in geyacc (exactly one reading per input).
- 23/23 tests from a clean build, 0 warnings, SCOOP, full void safety.
- Differential against the old parser (simple_scholar's `SCHOLAR_BIBLE.parse_reference`) over 11,185 inputs: 22 existing test inputs, 7,163 generated (every book × spelling × form, plus malformed variants), 4,000 sampled read-only from 80,943 reference-like strings in 5,661 vault notes. 0 crashes; 5,424 agree, 3,078 refused by both; every other row has a named cause. (BIBLE session check, 2026-10-23: `corpus/differential.tsv` holds 11,185 rows plus a header.)
- **Old-parser defects it found** (counts in the 4,000-string vault sample): en dash unread ("Isa 50:8–9", 266); dot after the book unread ("Lev.6:25", 76); lists silently return the WRONG verses ("Acts 23:11, 27:23-24" → Acts 23:23-24, 5, plus 18 read halfway); shared prefixes guessed ("Jud 1" → Judges); "1 Kgs" / "1 Jn" unread (9); nonsense accepted ("Gen 40:00").

## Open questions it raises for simple_bible

1. **Dependency: RULED (b), Larry, 2026-10-23 ("(b) it is").** The ~15 `YY_*` runtime classes the generated parsers inherit are vendored into a small simple_* library (working name simple_grammar), MIT with Gobo credit kept in the class notes, README and LICENSE. simple_bible depends on that library, never on Gobo's skeleton libraries directly. gelex/geyacc stay build-time tools only. Rejected: (a) an exception for the two skeleton libraries; (c) hand-porting the generated tables. The library is built when the parsers are merged (Phase 4, see item 6), not before.
2. **FR-020 lists:** `BIB_PARSE_RESULT` cannot hold the lists FR-020 promises; the adapter refuses at the comma.
3. **Naming the versification system:** undefined. The spike proposes a trailing "(KJV)" / "(Swete)", with "(LXX)" returning both numberings.
4. **Over-acceptance:** two-letter prefixes accept prose ("So 33", "Ep. 112"); the detector (front half) must not feed those through.
5. **Query rules VR-03..05** are cited but do not exist, so the spike's query rules are provisional.
6. **Timing:** merging is Phase-4 work ahead of the Phase-2 gate, and needs `BIB_BOOK_CATALOG` data (fork 01) and a chapter-count check.

## Where it lives

- Report: `$SIMPLE_EIFFEL\_gobo-work\06 - simple_bible grammar parsers.md`
- Spike: `$SIMPLE_EIFFEL\_gobo-work\06-grammar-spike\` (grammar, src, src/generated, oracle, testing, corpus, tools, `regenerate.sh`, `docs/GELEX_GEYACC_PATTERN.md`)
- Fleet how-to copy (uncommitted): `$SIMPLE_EIFFEL\reference_docs\language\gelex_geyacc_pattern.md`

**Fold into:** the one spec fold (with the four verdicts and the concordance), as input to FR-020, the reference grammar, and D-020's detector port.
