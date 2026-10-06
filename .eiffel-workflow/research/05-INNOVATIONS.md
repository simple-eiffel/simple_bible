# INNOVATIONS: simple_bible

## What Makes This Different

### I-001: The engine owns every fact (AI as phrasing only)
**Problem Solved:** AI Bible tools miscount, misquote and invent citations; the market leader (Logos Study Assistant, Smart Search) puts AI in the answer path.
**Approach:** Every number, verse and quotation comes from a deterministic engine result object. The optional AI adapter accepts only that object and returns labeled wording; a post-check rejects any digit, reference or Hebrew/Greek string the input did not contain (FR-053).
**Novelty:** No surveyed tool (free or commercial) enforces this as a contract; it is the vault's "pulled from bible.db, never recalled" rule compiled into the type system.
**Design Impact:** `ENGINE_RESULT` is the only input type of `AI_ADAPTER.explain`; NULL adapter is the default; the whole product passes its tests with no models present.

### I-002: Pre-registered census with controls, reported in four buckets
**Problem Solved:** Concordance counts invite cherry-picking and silent mistakes; "a correct top-line number sitting on broken reasoning" was caught in shape.db only because the schema refused to return FITS alone.
**Approach:** A census (question, corpus, criteria, controls, "could fail if") is written and frozen before it runs; results always come back as FITS / PARTIAL / FAILS / NO_DATA with near-misses; NO_DATA (absence in tagging) is never collapsed into FAILS (absence in text); the method is stored beside every result.
**Novelty:** Bible Analyzer offers statistics and hit charts; Text-Fabric allows arbitrary queries; none treats a count as a pre-registered experiment with controls. This brings research-methods discipline to a lay tool.
**Design Impact:** Census definitions are immutable after first run (versioned instead); class invariants tie result buckets to the definition id.

### I-003: Versification-safe pairing as a precondition
**Problem Solved:** Hebrew, Greek and English numbering differ (Malachi 3/4, LXX Psalms, LXX Jeremiah chapter order, Lev 5/6); naive pairing is silently wrong in about half the shared books.
**Approach:** Every cross-version operation takes a mapped reference produced by the versification map (TVTMS plus the vault's verified LXX concordance); the pairing feature's precondition requires a mapped reference, so unmapped pairing cannot be written.
**Novelty:** Commercial suites handle this internally; free tools mostly do not. Making it a contract precondition is new.
**Design Impact:** `MAPPED_REF` type distinct from `RAW_REF`; mapping rule carried into every result's method view.

### I-004: Provenance per row, credits generated, license gate in the build
**Problem Solved:** Free Bible software rarely states which edition and license each text came from; the vault discovered it could not name the edition of most of its own versions (defect E5).
**Approach:** `source_provenance` is a foreign key on every shipped row; credits and the About page are generated from it; the build fails on UNKNOWN licenses; NC and SA clauses are carried as data.
**Novelty:** Turns attribution from a documentation chore into a build invariant.
**Design Impact:** Build pipeline classes with contracts (`all_rows_have_provenance`, `no_unknown_license_shipped`).

### I-005: Defects as data: quarantine, caveats and protected non-defects
**Problem Solved:** Datasets silently carry contamination (LXX Jeremiah tails), reference-space traps, import gaps and "fixes" that would damage correct data (MapM NBSP, LXX Dan 3's 97 verses).
**Approach:** Carry the vault's defect register classes into the product: a quarantine table (nothing deleted), per-version caveats shown at the point of use, import-gap flags so a nil is reported as NO_DATA, and a protected list of non-defects with regression tests.
**Novelty:** Most tools present data as clean; this one shows the reader where it is not.
**Design Impact:** Each register item becomes a test; caveats are part of the verse hub's output contract.

### I-006: "Do the AI at build time"
**Problem Solved:** Basic laptops cannot run judgment-grade models, and prompt reading on CPU is slow (143 tokens/s measured at 4 threads on a fast machine).
**Approach:** Embeddings, related passages, quotation alignments and gloss tables are computed once on a strong machine and shipped as data; at run time the user's machine only looks them up, and optionally embeds a short query.
**Novelty:** Logos runs AI as a cloud service; free tools have none. Shipping precomputed intelligence offline is an unusual middle path.
**Design Impact:** Separate read-only `ai_data.db`; build scripts are first-class deliverables with provenance.

### I-007: Quotation comparer with computed agreement class
**Problem Solved:** Whether an NT quotation follows the LXX or the MT is usually asserted from memory or commentary.
**Approach:** For each indexed quotation (seeded from UBS Paratext Parallel Passages, CC BY-SA 4.0), align NT, LXX and MT through the versification map and lemma keys, and compute "agrees with MT against LXX", the reverse, both, or neither, with the aligned words shown.
**Novelty:** Not found in any free tool surveyed.
**Design Impact:** Alignment computed at build time (L2); the run-time feature only displays and explains.

### I-008: Public core, private plug-in
**Problem Solved:** One person's frameworks and copyrighted research must not ship, yet Larry wants the same tool.
**Approach:** Deferred source and lens interfaces in the public build; Larry's private library implements them and attaches private databases labeled by voice (trusted, hold-loosely, cite-exactly).
**Novelty:** Similar in spirit to SWORD modules, but with trust class carried into every result.
**Design Impact:** No lens classes in the public executable; voice label on every private hit.

## Differentiation from Existing Solutions

| Aspect | Existing | Our Approach | Benefit |
|--------|----------|--------------|---------|
| Source of facts | AI answers with citations (Logos); human memory (most) | Deterministic engine only; AI phrases engine output | No invented numbers or verses |
| Counting | Hit counts and charts (Bible Analyzer); free queries (Text-Fabric) | Pre-registered census with controls and four buckets | Reproducible, honest measurements |
| Versification | Implicit or ignored in free tools | Mapping as data and as a precondition | No silent mispairing |
| Data trust | Presented as clean | Quarantine, caveats, NO_DATA, protected non-defects | Reader sees the limits |
| Licensing | Mixed, often unstated | Provenance per row, generated credits, license gate | Free distribution without legal guesswork |
| Hardware | Cloud AI or none | Precomputed intelligence; optional CPU models | Useful on an 8 GB laptop with no GPU |
| Hebrew/Greek search | Tokenizers that split on marks or ignore accents | Normalized search columns beside exact display text | Accurate search without editing the text |
| Personal research | Separate tools | Private plug-in with voice labels | One tool for Larry and the public, cleanly separated |
