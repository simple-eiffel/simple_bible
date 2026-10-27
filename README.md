# simple_bible

[Documentation](https://simple-eiffel.github.io/simple_bible/) •
[GitHub](https://github.com/simple-eiffel/simple_bible) •
[Issues](https://github.com/simple-eiffel/simple_bible/issues)

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Eiffel 25.02](https://img.shields.io/badge/Eiffel-25.02-purple.svg)
![DBC: Contracts](https://img.shields.io/badge/DBC-Contracts-green.svg)

A free Bible-study workbench for Windows: an Eiffel engine over SQLite that looks up, counts and compares the biblical text in Hebrew, Greek and English. **Every fact it shows carries its source and license.**

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

🚧 **A working personal edition; no public release yet.**

- ✅ Research (Eiffel Spec Kit pre-phase): scope, landscape, requirements, decisions, risks, plus a feature study of e-Sword and Logos, a user-voice study (294 user comments from 96 sources), a world-timeline design, and a Septuagint source plan
- ✅ GUI layout and operation spec: native [simple_widgets](https://github.com/simple-eiffel/simple_widgets), with a Simple (three-pane reader) mode and a Study (docked) mode
- ✅ Specification and intent (Phase 0 approved)
- ✅ **Phase 1, engine library contracts:** 150 classes (16 deferred) with full `require`/`ensure`/`invariant` and MML model queries; 0 errors, 0 warnings
- ✅ **Design-fork debates (`/eiffel.debate`), all five gated:** run-time database layout and search folding, the notes store, private material as data packs (no plug-in code), the SQLite upgrade (3.53.4), and the concordance (its database attached read-only as a pack; its classes in `src/concordance/`)
- ✅ **One specification fold (2026-10-26)** carried every verdict into the spec, and the engine skeletons follow it: the concordance cluster, one content database, data packs, note export and import; tests 73 pass, 52 skeletal (reported as skipped), 0 fail
- ✅ **Phase 2 contract review of the concordance slice** (separate-seat cycle, 13 findings ruled, all applied) and **Phase 3 task plan**, both approved
- ✅ **Phase 4, the concordance engine and command line** (the personal edition comes before the public Release 1a): `SIMPLE_BIBLE.open` checks content.db v1 and attaches the concordance pack read-only; the word view, English and verse lookups and Strong's lookup run on the real data; the word view's first screen takes about 42 ms on the lean build; tests 131 pass, 49 skeletal (reported as skipped), 0 fail
- ✅ **Build and application ECFs:** `bible_build.ecf` (`bible_build.exe` writes content.db v2: books, 21 versions, every verse, 344,799 cross-references) and `simple_bible_app.ecf` (`bible.exe`: `word`, `english`, `verse`, `strongs`; `bible_gui.exe`, the window)
- ✅ **The main window, the GUI guide's Simple layout** (`bible_gui.exe`, simple_widgets): the Bible text in the centre (any of 21 versions, chapter by chapter), the commentary panel east (cross-references with OpenBible votes), the dictionary and lexicon south (how the Bibles render a word, lexicon entries, every place), search results west while there are any; a reference box, a search box, Back and Forward, text size, light and dark. Click a verse and the panels follow it; click a word in the KJV or BSB text and the lexicon opens its Greek or Hebrew original. Design pills (View menu) label every part with its code from the GUI guide
- ✅ **A personal installer** (Inno Setup, per user) for the project lead's own machines; it carries the personal edition, so it is never published
- ✅ **The Study layout** (Simple | Study, Ctrl+M): the navigator (books by chapter) and notes west, Bible and Parallel tabs centre (three versions side by side), the lexicon over the commentary east, the results zone south; the window opens at most of the screen and remembers the layout and the text size
- ✅ **The study tools (2026-10-27):** the Interlinear tab (Hebrew and Greek word by word, with glosses, Strong's numbers and morphology) and its verse analysis; notes in `user.db` with every version kept, export and import; a Journal; highlights, bookmarks, tags and reading history; private data packs, including commentary packs whose claims are labelled SOURCED or DEDUCED; references in a commentary that open their verse; tests 167 pass, 49 skeletal, 0 fail
- ⏳ Prayer list, memory cards and reading plans (Release 1b), Bible tabs, dictionaries and full-text search, then the rest of the engine

## The idea

Most Bible software sells content and convenience. simple_bible is built to **check what people say about the Bible against the Bible itself**:

- **The engine owns every fact.** Counts, lookups and comparisons are deterministic code over SQLite. A fact cannot exist without a source, and every result cites the sources it used (enforced by contract: `BIB_SOURCED`, `fact_closure` postconditions).
- **Counts show their failures.** Every pattern or census result carries all four buckets (FITS, PARTIAL, FAILS and NO_DATA), and counts can run beside frequency-matched control words.
- **AI is optional and never a source of facts.** Release 1 runs no AI on the user's machine.
- **Trust rules:** no ads, store, accounts, telemetry or activation; no paywalls; your notes stay yours.
- **Runs on ordinary hardware:** CPU-only, 8 GB of RAM, no GPU required.

## Layout

```
simple_bible.ecf        engine library + tests target (simple_bible_tests)
src/                    BIB_* engine classes (contracts, Phase 1)
testing/                TEST_APP + test sets (simple_testing)
docs/                   documentation site
.eiffel-workflow/       research, GUI spec, specification, intent, evidence
```

Class prefix: `BIB_`. Entry class: `SIMPLE_BIBLE`. No C code.

## Building

```bash
cd simple_bible
ec.sh check -config simple_bible.ecf -target simple_bible_tests
ec.sh test  -config simple_bible.ecf -target simple_bible_tests
```

Read the build log, not just the summary line.

## Dependencies

base, [simple_mml](https://github.com/simple-eiffel/simple_mml), [simple_sql](https://github.com/simple-eiffel/simple_sql), [simple_datetime](https://github.com/simple-eiffel/simple_datetime); tests add testing and [simple_testing](https://github.com/simple-eiffel/simple_testing).

## License

MIT. Bible texts and datasets shipped later carry their own licenses, credited in a generated credits file.
