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
- ✅ **Phase 1, engine library contracts:** 150 classes (16 deferred) with full `require`/`ensure`/`invariant` and MML model queries; 0 errors, 0 warnings; tests 69 pass, 47 skeletal (reported as skipped), 0 fail
- ⏳ Design-fork debates (`/eiffel.debate`), then Phase 2 contract review as a separate-seat debate cycle
- ⏳ Build-pipeline and application ECFs

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
/d/prod/ec.sh check -config simple_bible.ecf -target simple_bible_tests
/d/prod/ec.sh test  -config simple_bible.ecf -target simple_bible_tests
```

Read the build log, not just the summary line.

## Dependencies

base, [simple_mml](https://github.com/simple-eiffel/simple_mml), [simple_sql](https://github.com/simple-eiffel/simple_sql), [simple_datetime](https://github.com/simple-eiffel/simple_datetime); tests add testing and [simple_testing](https://github.com/simple-eiffel/simple_testing).

## License

MIT. Bible texts and datasets shipped later carry their own licenses, credited in a generated credits file.
