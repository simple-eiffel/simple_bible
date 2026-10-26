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

🚧 **Design and contracts. Not usable yet.**

- ✅ Research (Eiffel Spec Kit pre-phase): scope, landscape, requirements, decisions, risks, plus a feature study of e-Sword and Logos, a user-voice study (294 user comments from 96 sources), a world-timeline design, and a Septuagint source plan
- ✅ GUI layout and operation spec: native [simple_widgets](https://github.com/simple-eiffel/simple_widgets), with a Simple (three-pane reader) mode and a Study (docked) mode
- ✅ Specification and intent (Phase 0 approved)
- ✅ **Phase 1, engine library contracts:** 150 classes (16 deferred) with full `require`/`ensure`/`invariant` and MML model queries; 0 errors, 0 warnings
- ✅ **Design-fork debates (`/eiffel.debate`), all five gated:** run-time database layout and search folding, the notes store, private material as data packs (no plug-in code), the SQLite upgrade (3.53.4), and the concordance (its database attached read-only as a pack; its classes in `src/concordance/`)
- ✅ **One specification fold (2026-10-26)** carried every verdict into the spec, and the engine skeletons follow it: the concordance cluster, one content database, data packs, note export and import; tests 73 pass, 52 skeletal (reported as skipped), 0 fail
- ✅ **Phase 2 contract review of the concordance slice** (separate-seat cycle, 13 findings ruled, all applied) and **Phase 3 task plan**, both approved
- ✅ **Phase 4, the concordance engine and command line** (the personal edition comes before the public Release 1a): `SIMPLE_BIBLE.open` checks content.db v1 and attaches the concordance pack read-only; the word view, English and verse lookups and Strong's lookup run on the real data; the word view's first screen takes about 42 ms on the lean build; tests 131 pass, 49 skeletal (reported as skipped), 0 fail
- ✅ **Build and application ECFs:** `bible_build.ecf` (`bible_build.exe` writes content.db v1) and `simple_bible_app.ecf` (`bible.exe`: `word`, `english`, `verse`, `strongs`)
- ✅ **The first window** (`bible_gui.exe`, simple_widgets): the GUI guide's Simple layout with one lookup box (a Hebrew, Greek or English word, a verse, a Strong's number), the words found, and the word study (heading, how the Bibles render it, every place, streaming in); light and dark follow Windows
- ✅ **A personal installer** (Inno Setup, per user) for the project lead's own machines; it carries the personal edition, so it is never published
- ⏳ More of the window (Study layout, Bible text and commentary once the content pipeline carries them), then the rest of the engine

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
