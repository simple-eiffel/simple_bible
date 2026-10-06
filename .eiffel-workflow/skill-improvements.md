# Skill improvements queued (not applied; Skill Version Lock)

*Found while running /eiffel.intent on simple_bible, 2026-10-06. For the skill owner to review after this workflow.*

## eiffel-intent (`C:\Users\LJR19\.claude\skills\eiffel-intent\SKILL.md`)

1. **Hard-coded model name.** Step 4 and the step 8 evidence template say "Claude Opus 4.6". Use a model-neutral line ("Review engine: Claude (self-review), model as run") so the evidence stays true when the model changes.
2. **No pending status for delegated runs.** The step 8 template has only `# Status: APPROVED`. When a subagent runs the phase, it must not approve on the user's behalf. Add `User approved: PENDING` and `# Status: AWAITING APPROVAL` as the documented state before step 7, with the flip to APPROVED done by whoever hears the user's approval.
3. **Binding prior answers.** Step 2 reads only 07, 01 and 03. Add: read 08-VALIDATION's open questions and any `09-*ANSWERS*` file, and treat those answers as binding (do not re-ask them).
4. **Multi-release intents.** The template has one Acceptance Criteria list. Add guidance for split releases (for example 1a and 1b): number criteria per release, mark conditional criteria, and give totals.
5. **Each criterion names its test.** Step 10 ("testability") would be stronger if the template asked each criterion to name the test class that proves it.
6. **Transitive ISE and Gobo.** The dependency policy lists "Only ISE allowed" but does not say whether ISE or Gobo reached through a simple_* wrapper (simple_xml over Gobo XML, simple_json over ISE json) is acceptable. State the rule (allowed through a wrapper; direct use limited to `base`) so audits are consistent.
7. **Audit depth.** Step 5 checks only that a simple_* library exists for a need. In this run, every library existed, but six had real capability gaps (8-bit paths, no mixed-content XML walk, fixed CSV quoting, whole-second mtime, no Unicode normalization, tokenizer parity). Add: "verify the specific features the spec relies on (signatures, string widths, streaming, Unicode), not only the library's presence."
8. **Gap numbering.** When a spec already numbers gaps (LG-01, LG-03 ...), new gaps should continue that series. Say so in step 5.
9. **Line endings.** Fleet repositories use CRLF on disk. Add a closing step: normalize the new .md and .txt files to the folder's line endings.
10. **Deferred items from the spec.** When the spec defers items to intent (here, seven innovation sparks), step 4 should require a placement and a reason for each, alongside the probing questions.

## eiffel-contracts (`C:\Users\LJR19\.claude\skills\eiffel-contracts\SKILL.md`), found 2026-10-06 (engine library)

1. **Stale build line.** Steps 6 and 6b say `ec.sh -batch -config ... -c_compile`; ec.sh blocks raw flags. Use `ec.sh check -config X.ecf -target T` then `ec.sh test -config X.ecf -target T`, both from the project folder.
2. **Never trust the ec.sh summary.** `run_ec` pipes ec.exe into `tee` and reads `$?` (tee's status), so ec.sh prints "passed" and exits 0 with syntax and type errors in the log. The skill should require grepping the log for `Error code`, `Syntax error` and `Warning:` (obsolete calls appear as "Error code: Obsolete Call" with a "Warning:" line, so `Warning code` alone misses them). Fleet fix filed as GAP-EC-01 in phase1-compile.txt.
3. **Void-safe stubs.** `do end` does not compile for a function with an attached result (VEVI). Document the stub form `check implemented_in_phase_4: False then end` (passes VEVI, fails loudly if called), and that creation procedures must still set every attached attribute.
4. **Reserved words.** `reference`, `attached`, `unique` and `frozen` cannot be feature names or assertion tags; a spec that names a feature `reference` needs a rename at Phase 1.
5. **SCOOP preconditions.** A precondition on a separate argument is a wait condition, not a check; ordering rules on mailbox-style classes belong in postconditions. Say so next to Step 6b.
6. **`old` and across.** `old` cannot mention an across-cursor local (VAOL(2)); an "others unchanged" frame over a family needs a helper model query (for example `other_buckets_model (v)`).
7. **Test layout.** The skill shows `test/` and `EQA_TEST_SET`; the fleet uses `testing/`, TEST_APP plus LIB_TESTS and TEST_SET_BASE, with skeletal tests reported as SKIP, never as PASS (simple_shaping precedent).
8. **all_classes.** A tests target rooted at TEST_APP type-checks only reachable classes; add `ec.sh check` of the library target (root all_classes) to the gate so unreached skeletons are checked too.
9. **Multi-ECF projects.** Add guidance for a phase that covers one ECF of several (RQ-01): the evidence names the ECF, and the AC mapping splits engine, build and face criteria.
10. **Line endings.** Git Bash `sed -i` rewrites CRLF files as LF; normalize after any sed edit and count bytes in Python.
