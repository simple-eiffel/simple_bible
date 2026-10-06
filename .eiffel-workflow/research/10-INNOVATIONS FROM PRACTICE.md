# INNOVATIONS FROM PRACTICE: simple_bible

*2026-10-06. Ideas drawn from how Larry and Claude actually work in the Scholars vault: research cycles, censuses, shape.db, and an exchange with a friend's AI-generated answer. They complement `05-INNOVATIONS.md` (written by the research agent). Novelty is unverified until `09-FEATURE-PARITY` confirms whether e-Sword or Logos already have equivalents.*

> **Novelty checked (2026-10-06, `09-FEATURE-PARITY`):** 11 of the 17 have no equivalent in e-Sword or Logos. 5 are new only as a layer on an existing Logos feature: the quotation verdict (I-P06), the word's journey (I-P07), the divine-name view (I-P08, buildable in Logos with Visual Filters), per-sentence fact links (I-P11), and near-misses always shown (I-P03). 1 is NOT new: **range before ruling (I-P09)**, because Logos's Bible Word Study already shows senses with counts.

**The thread through all of them:** Big Bible tools sell content and convenience. Our work kept needing something else: **checking claims against the text, honestly, with the counter-evidence shown.** In an age of AI-generated Bible answers, that is the gap.

---

## A. Claim checking: the flagship

### I-P01 Claim Check (paste anything, get it checked)
**From:** an exchange about a friend's AI-generated answer (pasted in, checked line by line).
**What it does:** The user pastes an AI answer, a sermon note, or a social-media post. The tool:
1. pulls out verse references (the vault's `scripture_detect.py` already does this);
2. pulls out word claims ("X means Y"), number claims ("in every book," "systematically"), and quotation claims;
3. checks each one against the engine.

Each claim comes back marked SUPPORTED, CONTRADICTED, PARTLY, or CAN'T BE CHECKED, with the evidence attached.
**Why it matters:** It is the honest answer to a world full of AI Bible content. It never relies on AI to judge facts; the engine does the checking.

### I-P02 "Is it special, or just common?" (built-in controls)
**From:** the quad test (a friend's four words "in every book" scored the same as ordinary nouns of matching frequency).
**What it does:** Any "X appears everywhere / clusters here" claim automatically runs beside **frequency-matched control words**. The result shows whether the pattern beats chance.
**Why it matters:** It kills the commonest error in popular word studies. Nobody else does this by default (to confirm).

### I-P03 The FAILS bucket is always shown
**From:** shape.db (every query returns FITS, PARTIAL, FAILS and NO_DATA together; you can't ask for confirming cases only).
**What it does:** Every search for a pattern also lists where it *doesn't* hold, and where the data is silent.
**Why it matters:** It builds honest readers. "Show me where this breaks" is one click, not an afterthought.

### I-P04 Leading-question warning
**From:** A friend's prompt, which contained its own conclusion; the AI mirrored it back as a "finding."
**What it does:** When the user asks the optional AI layer a question that assumes its answer, the tool says so and offers a neutral rewording.

### I-P05 Share-safe export
**From:** the Dahse/Skinner line, which left our notes unverified, went through a friend's AI, and came back as "fact," reversed.
**What it does:** Export (to email, social posts, an essay) carries **verification flags with every claim**. Unchecked items are visibly marked, and an option strips them out.
**Why it matters:** It stops provenance laundering at the source.

## B. Seeing the text the way we work it

### I-P06 Quotation comparer: "They chose"
**From:** Rom 12:19 and 1 Cor 3:19 (agreeing with the Hebrew against the LXX) and Acts 15:17 (the reverse).
**What it does:** For every NT quotation of the OT, the NT, LXX and Hebrew sit side by side, color-coded by agreement, with a one-line computed verdict ("agrees with the Hebrew against the Septuagint").

### I-P07 A word's journey
**From:** the Tyndale/More fight and the KJV's Rule 3.
**What it does:** One Hebrew or Greek word followed through every version in the database, laid out in time order: LXX → NT → Vulgate → Wycliffe → Tyndale → KJV → BSB. It shows how each version rendered the word, with counts. Example: *ekklēsia* → "congregation" (Tyndale, 109/111) → "church" (KJV).
**Why it matters:** It makes translation history visible without anyone's commentary.

### I-P08 Divine-name view
**From:** the divine-name work (Gen 7:16: "God commanded … the LORD shut him in"). The generic version is not a framework.
**What it does:** It colors the divine names (YHWH, Elohim, Adonai, El, Shaddai …) through any passage, with a Hebrew/Greek toggle showing where the LXX keeps or loses the distinction.

### I-P09 Range before ruling
**From:** the vault's Rule 22.
**What it does:** A word's page opens on **every attested sense with counts and example verses** before any single "meaning" is shown. The reader sees the range first.

## C. Writing honestly about the text

### I-P10 Gloss-aware writing pane
**From:** Larry's writing conventions.
**What it does:** When you type a Hebrew or Greek word in a note, the tool offers the transliteration, the pronunciation (stress in caps) and an English gloss on first use. It flags bare script and checks that every quotation matches the database text.

### I-P11 Grounded drafting
**From:** "the engine owns every fact."
**What it does:** If the optional AI drafts a paragraph, every sentence carries a small badge linking it to the engine fact it rests on. Sentences with no support are shaded for the reader to check or delete.

## D. Doing study like a lab notebook

### I-P12 Study ledger (replayable research)
**From:** the vault's numbered cycle files, census scripts and verification ledgers.
**What it does:** Every query, count and finding in a study session is logged automatically. The session can be replayed, shared, and re-run when the data improves. It works like a lab notebook for Bible study.

### I-P13 Write the question down first
**From:** pre-registered tests ("holds if…" written before the run).
**What it does:** The user may state the claim and what would count as support **before** the count runs. The tool records both, then shows the result against the stated test. That makes hindsight cherry-picking visible.

### I-P14 Pattern builder (user-made shapes)
**From:** shape.db.
**What it does:** A form-based builder lets users define a structural pattern in the tags (lemma, morphology, nearness, book). Results come back with near-misses. Shapes are shareable files, so a study group can test the same pattern.

### I-P15 Preflight for a topic
**From:** `cycle_preflight.py`.
**What it does:** Before you write on a topic, it shows what your notes already hold and the verses you haven't looked at. In the private edition, it also shows withdrawn or superseded material you shouldn't cite.

## E. The partnership model

### I-P16 The human adjudicates, by design
**From:** how Larry and Claude work. The engine and AI gather, count and draft; adversarial checks attack; **the human rules.** The vault's own rule says the only party not running on model weights is the human reader.
**What it does:**
- AI output is always labeled as a draft.
- The engine is always the source.
- Conclusions are the user's, recorded in the study ledger as *their* ruling.
- An optional "argue the other side" button assembles counter-evidence from the engine only. This is the RED seat, with no AI judgment involved.

### I-P17 Reply kit
**From:** answering a friend: credit first, then check, then reply.
**What it does:** It combines Claim Check (I-P01) with a reply scaffold. It lists what the other person got right, what checks out, what doesn't, and the verified verses, each with its source. It's ready for a gracious, accurate answer.

---

## Suggested placement

- **v1 (fits the "comfortable core"):** I-P03 FAILS always shown; I-P06 quotation comparer; I-P07 word journey; I-P08 divine-name view; I-P09 range before ruling; I-P02 frequency controls.
- **v1.5:** I-P01 Claim Check (needs good claim extraction; the engine side is ready); I-P05 share-safe export; I-P12 study ledger; I-P13 pre-registered questions.
- **v2:** I-P10 writing pane; I-P11 grounded drafting (needs the optional AI layer); I-P14 pattern builder; I-P17 reply kit; I-P04 leading-question warning; I-P15 preflight.

**Positioning line:** *e-Sword gives you free books. Logos sells you a library. simple_bible checks what people say about the Bible against the Bible itself: free, honest, and with the counter-evidence shown.*
