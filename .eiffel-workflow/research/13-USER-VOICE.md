# 13 USER VOICE: what Bible-software users complain about, wish for and quit over

*2026-10-06. Research for `simple_bible` (free, native Windows, CPU-only, the engine owns every fact, AI optional). Input to `/eiffel.intent`. Question from Larry: "scour the internet for user-comments, complaints, ideas and so on for eSword, Logos, or just about any other bible software you can find." Every quote below was copied from the source text and checked by script against a saved copy of that text. Items graded SNIPPET carry no quote. The raw list is `13-user-voice-items.csv` (294 items).*

---

## 1. Bottom line

- **The loudest pain is not missing features. It is betrayal of trust:** paying again for what you own, features removed or paywalled after purchase, ads and store links inside Scripture, forced redesigns, data lost on update, and AI pushed into plain search. A free, offline, no-store, no-account tool answers most of this by design. That is simple_bible's strongest position, and users state it in their own words.
- **Complexity is the second wall.** Logos is "the greatest library in the world that won't let you in" (App Store, 2026-09-11). Accordance users ask why tagged searches still need "code-like syntax." The free tools users praise (Literal Word, theWord, SwordSearcher, BibleWorks) are praised for being fast and plain.
- **AI draws a split verdict.** Users like AI for *finding* things in their library. They distrust it for *interpreting*, and they object when it is forced on them, burns credits, omits items or quotes without a citation. Barna (2026-08-25): 94% of pastors worry about AI misinterpreting Scripture, and 60% want AI to show all major interpretations without choosing one. That fits "the engine owns every fact" exactly.
- **Gaps nobody fills well:** screen-reader access, honest counts that state their scope, text that never changes silently, notes that live in the user's own files (many users fall back to Obsidian), and an exhaustive answer ("every verse where...") instead of three or four AI-picked sources.

## 2. Method and sources

**Corpus:** 294 items from 96 distinct source pages; 270 OPENED, 24 SNIPPET. Each item is one user's complaint, wish or idea. A few app-store items group several reviewers who said the same thing, and they are named in the item.

| Source | How it was read | Grade | Items |
|---|---|---|---|
| Apple App Store reviews: Logos, Verbum, Olive Tree, Accordance, e-Sword LT, Blue Letter Bible, Bible Gateway, Bible Hub, YouVersion, Literal Word, Bible Chat (AI) | Apple's public customer-review RSS feed (US): 8,451 unique reviews downloaded, 1,490 rated 1-3 stars. Low-rated reviews and wish-reviews were read in date order. | OPENED | 109 |
| Reddit r/LogosBibleSoftware, r/Reformed, r/AcademicBiblical, r/Bible | reddit.com blocks this machine (login wall; JSON blocked). Posts and comment trees were read through the Arctic Shift archive API, which stores Reddit's own post text. URLs are the Reddit permalinks. | OPENED (archive copy) | 76 |
| Puritan Board (Reformed forum) | Threads fetched directly: Logos subscription (2024), "Just not a fan of Logo software" (2023), BibleWorks closing (2018), theWord (2009) | OPENED | 32 |
| Hacker News | Algolia API: "I made a new kind of Bible app" (2021), "Bible translated using LLMs" (2026) | OPENED | 10 |
| GitHub issues: AndBible, Xiphos, STEPBible | `gh api` | OPENED | 11 |
| SwordSearcher forum, AppleVis forum, blogs and reviews (Knowable Word, From the Couch, Reading Acts, Matt Dabbs, Christ Over All, firstthreequarters, Marisa D'Amore), Barna, Christian Post, Slate | Fetched directly | OPENED | 32 |
| Logos community forums, Accordance forums, BibleSupport (e-Sword) topic pages, Tom's Hardware, CodeWeavers, Trustpilot | Blocked (403 or 404 to this machine) or seen only through a summarizer. Search-result text only. | SNIPPET | 24 |

**Blocked or not mined:** community.logos.com (403), forums.accordancebible.com (403), BibleSupport topic pages (404 without login; forum indexes load), newtestamentredux.com (403), Trustpilot (403 direct; the summarizer's quotes could not be checked, so those items are SNIPPET), reddit.com direct (login wall; archive used instead). Google Play reviews were not mined (no public feed). The session's web-search budget (200 calls, shared across the session) ran out during this work. The rest of the work used direct fetches, the Apple feed, the Reddit archive, HN and GitHub.

**Bias warnings.**
- **Logos dominates (139 of 294 items),** because it has the most active public discussion and a subreddit full of feature-request threads. Treat Logos-specific counts as "what a power user hits," not as "most common in the market."
- **App-store reviewers skew toward lay readers on phones.** simple_bible is a desktop program, but the trust themes (ads, paywalls, data loss, forced redesigns) carry over unchanged.
- **Complaints outnumber praise by design.** Praise was recorded where it shows what users value (speed, simplicity, one-time price, offline).
- **User type** comes from self-description or context. "Lay reader" is the default when nothing says otherwise.

**Counts by product family:** Logos 139 · e-Sword (incl. LT) 24 · Accordance 18 · Olive Tree 14 · BibleWorks 11 · Blue Letter Bible 10 · Bible Gateway 8 · AI apps and general AI (Bible Chat, Text With Jesus, LLM-translation, Barna) 15 · Verbum 6 · STEPBible 5 · AndBible 5 · Bible Hub 4 · Literal Word 4 · Xiphos 4 · theWord 4 · YouVersion 4 · SwordSearcher 3 · others and general 15 (Gramcord, Spark Bible, BibleTime, Text-Fabric, multi-product threads).

**Counts by user type:** lay reader 166 · pastor 90 · scholar 23 · student 13 · other 2.

**Corroborating keyword scan** (1,490 App Store reviews rated 1-3 stars; regex hits, noisy, one review can hit several): ads/upsell 482 (391 of them Bible Gateway) · price/subscription 321 · performance/crash 311 · search 175 · "since the update"/redesign 164 · audio 152 · translation availability 150 · sync/lost data 94 · original-language 66 · login/account 63 · complexity 59 · readability/accessibility 55 · offline 32 · AI 30 · doctrine/bias 21.

## 3. Theme table

Ranked by distinct source pages. Items = distinct user voices. AI themes T19-T22 together hold **44 items from 26 pages**, which makes AI the single largest cluster when combined.

| # | Theme | Items | Source pages | Products | User types | simple_bible response (short) |
|---|---|---|---|---|---|---|
| T19 | AI accuracy, citations, completeness | 19 | 16 | Logos, AI apps, Olive Tree, Bible Hub | lay, pastor, scholar | Engine owns facts; exhaustive lists; every quote cited |
| T01 | Price, subscriptions, paywalls | 22 | 15 | Logos, Bible Chat, BibleWorks, Verbum, SwordSearcher | all | Free, no tiers, no credits: a rule |
| T06 | Complexity, learning curve, discoverability | 27 | 15 | Logos, Accordance, e-Sword, Olive Tree, theWord, AndBible, STEP | all | Plain-first UI, progressive disclosure, built-in help |
| T04 | Performance, bloat, indexing | 16 | 14 | Logos, e-Sword, Accordance, Xiphos | lay, pastor, student | Startup and search budgets as tested requirements |
| T02 | Buying again, lock-in, ownership, vendor risk | 19 | 12 | Logos, e-Sword, BibleWorks, Gramcord, Accordance | lay, pastor, scholar | No activation; open formats; survivable if abandoned |
| T14 | Platforms, offline, portability | 12 | 11 | Logos, e-Sword, Olive Tree, theWord, Literal Word | lay, pastor | Fully offline; portable mode; Wine-tested |
| T13 | Workspace and reading ergonomics | 13 | 11 | Logos, Olive Tree, Accordance, e-Sword, BLB | lay, pastor | Linked panes with follow-only; saved layouts; following map |
| T03 | Ads, upsell, nagging, billing tricks | 18 | 11 | Bible Gateway, Bible Hub, Logos, Olive Tree, BLB, Bible Chat | lay | No ads, store, prompts or account: a rule |
| T07 | Search that fails or needs syntax | 11 | 9 | Accordance, BLB, Bible Gateway, Logos, Xiphos, YouVersion | all | Pasted text always finds its verse; guided forms |
| T23 | Accessibility and readability | 11 | 9 | Logos, Bible Gateway, BLB, e-Sword, SwordSearcher | lay, pastor | Screen-reader and keyboard first; low-vision themes |
| T11 | Notes and the personal-data model | 12 | 9 | Logos, e-Sword, BLB, AndBible, Verbum, Olive Tree | lay, pastor | Notes as user-owned files; verse backlinks |
| T26 | Free, simple tools are enough | 11 | 8 | STEP, BibleWorks, Literal Word, Logos | all | Position: the fast, plain, free tool |
| T08 | Original-language tools and workflow | 8 | 8 | Logos, Accordance, theWord, Literal Word, Bible Hub | all | One-click word panel; lemma, not bare number |
| T10 | Sync, accounts, backup, data loss | 14 | 8 | Accordance, Bible Gateway, BLB, Logos, Olive Tree, e-Sword, AndBible | lay, pastor | No account; append-only user data; backups |
| T18 | Text integrity, versification, honest counts | 9 | 8 | STEP, Verbum, Olive Tree, Bible Gateway, e-Sword | lay, scholar | Count-scope labels; text checksums; archaic glosses |
| T12 | Export, sharing, interoperability | 9 | 8 | Logos, e-Sword, AndBible, Accordance, Bible Chat | all | Everything exports; Markdown/CSV; local link scheme |
| T17 | Translations, licensing, canon | 7 | 7 | e-Sword, Xiphos, Verbum, Spark | lay, student | Open texts only; deuterocanon/LXX available |
| T15 | Privacy and tracking | 7 | 7 | YouVersion, Bible Hub, e-Sword, Logos | lay | No telemetry; no network unless asked |
| T22 | AI and the integrity of study and preaching | 6 | 6 | Logos, Text With Jesus | all | No "write my sermon"; AI output labeled draft |
| T21 | AI doctrine bias and who interprets | 9 | 6 | Logos, Text With Jesus, Barna | lay, pastor | Text-first answers; show disagreement, never settle it |
| T05 | Updates that break or force redesigns | 11 | 5 | Logos, e-Sword, Verbum | lay, pastor | No forced redesigns; settings never reset |
| T20 | AI forced, opt-out, credits | 10 | 4 | Logos | all | AI off by default; plain search never routed through AI |
| T16 | Modules and content installation | 4 | 4 | e-Sword, Accordance | lay, scholar | Ships complete; no module hunting |
| T24 | Audio and read-aloud | 4 | 4 | Logos, BLB, Olive Tree, SwordSearcher | lay | TTS with verse highlight and resume |
| T09 | Hebrew/Greek display and fonts | 3 | 3 | STEP, BibleTime, Logos | scholar | Shaping tests on real Hebrew |
| T25 | Church and teaching use | 2 | 2 | e-Sword, Bible Gateway | lay | Service mode |

## 4. Theme detail

Each theme gives the evidence, then **what simple_bible should do**. "Rule" means a design rule for intent. "Req" means a testable requirement. "Not our problem" gives the reason.

### T01 Price, subscriptions and paywalls (22 items, 15 pages)

- "I have never known a subscription-based scheme that did not cost more in the long run." (Puritan Board, 2024-08-02, OPENED) https://puritanboard.com/threads/logos-is-switching-to-subscription-based-features.114291/
- "Now, I'm forced to pay a monthly subscription fee just to use the Word Study /Lexicon while in the Bible!" (Logos App Store, Acvine, 2026-06-27, OPENED) https://apps.apple.com/us/app/logos-bible/id336400266
- "now they charge a subscription for basic features like word search and cross-reference" (Logos App Store, TeamEllis_, 2026-04-03, OPENED)
- "Reserving criticism to see how they can help the global church where even USD9.99 monthly is a huge sum to ministers living on a paper-thin stipend." (r/LogosBibleSoftware, 2024-10-23, OPENED) https://www.reddit.com/r/LogosBibleSoftware/comments/1ga9p6p/logos_move_to_subscriptionthoughts/
- "I'm morally opposed to money-gating Bible study to this extreme degree." (same thread, 2024-10-24, OPENED)
- AI-app version of the same anger: "Now you have to pay anytime you want to look up a verse." (Bible Chat App Store, 2026-10-03, OPENED) https://apps.apple.com/us/app/bible-chat-daily-devotional/id6448849666

**simple_bible:** **Rule:** No tiers, credits, trials or features that can ever be withdrawn. Anything shipped stays shipped. **Req:** The program works fully with no account and no network. This is the main positioning line, and users already speak it ("money-gating Bible study").

### T02 Buying again, lock-in, ownership and vendor risk (19 items, 12 pages)

- "Had I known prior to purchase that each version doesn't sync to the other versions I would not have chosen this software." (e-Sword LT App Store, 2025-03-19, OPENED) https://apps.apple.com/us/app/e-sword-lt-bible-study-to-go/id634158738
- "The books you own in logos are available to you, yes, *but only in Logos*." (r/Reformed, 2025-05-01, OPENED) https://www.reddit.com/r/Reformed/comments/1kc3k16/bible_software/
- "having spent a large amount of money on the library there's no way to get the books out of Logos" (r/LogosBibleSoftware, 2026-02-09, OPENED) https://www.reddit.com/r/LogosBibleSoftware/comments/1qzvutt/logos_is_frustrating_because/
- After BibleWorks closed: "Set up old computer, not connected to internet, install BW (whatever version). Use it strictly for BW." (Puritan Board, 2018-06-01, OPENED) https://puritanboard.com/threads/bibleworks-is-closing.95708/
- "I lost my code for Bibleworks in a number of moves, & BW wanted to charge me for a new code after all the money I had spent" (same thread, 2018-06-02, OPENED)
- "they should consider making the resources open source after this final round of 'going out of business' sales" (same thread, OPENED)
- "If I wasn't so heavily invested in Accordance software I'd like switch to another company." (Accordance App Store, 2026-06-03, OPENED) https://apps.apple.com/us/app/accordance-bible-software/id411970514

**Why users mourned BibleWorks (2018):** It was the original-language workhorse, it was fast on ordinary hardware, and users describe it as the plain, fast tool beside Logos. Users kept running BW10 for years ("backed up in three places and it still works," 2023). Their fear was that a Windows update would one day break it with no vendor left to fix it.

**simple_bible:** **Rule:** No activation, license keys or phone-home. **Rule:** All data (texts, user notes, highlights) lives in open, documented formats (SQLite plus Markdown/CSV export), so the program survives its author. **Req:** A "portable install" that runs from one folder. **Intent note:** publish the build and the data so someone else could carry it on. This is the BibleWorks lesson.

### T03 Ads, upsell, nagging and billing tricks (18 items, 11 pages)

- "At least 50% of the time you click on anything to try to get a passage, you get a very long ad." (Bible Gateway App Store, 2026-09-16, OPENED) https://apps.apple.com/us/app/bible-gateway/id506512797. The app averages 3.65 stars.
- An ad mimicked an iCloud sign-in: "I had one ad that came up and it had a pop-up that made it look like my iPhone was asking me to sign into iCloud." (2026-08-03, OPENED)
- Paid Logos user: "As much money as I've spent on this software, I am riddled with ads and they just made it so that you can't turn them off." (2026-09-29, OPENED)
- Logos v53 mobile put the store where the library was: "now it is direct access to the store" (2026-09-09, OPENED)
- "When this is paired with "these materials will help you study the Word of God" ethos of Logos, it borders the line of predatory." (r/LogosBibleSoftware, 2026-02-09, OPENED)
- Review nagging drives one-star reviews: "Please stop asking me to leave a review every single time I open the app." (Blue Letter Bible, 2026-09-27, OPENED) https://apps.apple.com/us/app/blue-letter-bible/id365547505
- Trial and billing traps (Logos $112 and $200 charges after cancelling; Bible Chat weekly billing with no in-app cancel).

**simple_bible:** **Rule:** No ads, store, upsell, review prompts, streak monetization, email capture or cart. **Rule:** No donation prompt inside reading or study views. If Larry wants a donation link, it lives on the About page only. This is cheap to promise and users visibly reward it.

### T04 Performance, bloat and indexing (16 items, 14 pages; 8 SNIPPET)

- "Now you have to watch videos just to figure out how to use it or it may be indexing for the next 3 weeks." (Puritan Board, 2023-06-05, OPENED) https://puritanboard.com/threads/just-not-a-fan-of-logo-software.111372/
- "for everything else I use Olive Tree simply because it takes forever for Logos to load on my computer" (r/Reformed, 2025-05-02, OPENED)
- Logos slow on a 16 GB i7 laptop. The advice given was an SSD, finished indexing or 32 GB of RAM (r/LogosBibleSoftware, 2024-08-09, OPENED).
- "I really appreciate how new Accordance works well on old computers and old Accordance works well on new computers." (r/AcademicBiblical, 2020-11-18, OPENED)
- e-Sword: startup slows to minutes as modules pile up. One bad module slowed everything, and long-time users rolled back to v8 (BibleSupport, SNIPPET).
- Mobile link animation "takes 3.2 seconds to open in a new tab" (r/LogosBibleSoftware, 2025-12-02, OPENED).

**simple_bible:** **Req:** Measured budgets, tested on an 8 GB, CPU-only, non-SSD reference machine. Suggested starting values: cold start under 3 s, verse jump under 100 ms, whole-Bible word search under 300 ms. **Rule:** No background indexing at run time; indexes are built at build time (fits I-006). **Rule:** No animations on navigation. **Req:** One broken or slow resource must not slow the rest. Load lazily, quarantine on error (fits I-005).

### T05 Updates that break things or force redesigns (11 items, 5 pages)

- "Not happy with the idea that you make changes without giving us the option to keep the old format." (Logos App Store, 2026-08-29, OPENED)
- "How do I recover a prior version of logos?" (2026-09-12, OPENED)
- "at every update they change the process/method to complete an action and it takes a readjustment time to learn the new process" (2026-07-21, OPENED)
- "Every day, it resets to some strange translation I've never heard of called lexham." (2026-09-09, OPENED)
- Reading plans rebuilt on time estimates: "It now creates reading plans based on arbitrary time factors instead of the old version like chapters." (2026-06-09, OPENED)
- e-Sword LT removed the daily-verse widget, cross references and sermons in updates. e-Sword 15 dropped older RTF-format modules, and users thought their library was gone (App Store OPENED; BibleSupport SNIPPET).

**simple_bible:** **Rule:** No silent behavior changes. A changed workflow ships with the old one still selectable for at least one major version. **Req:** User settings (default text, layout) never reset across updates; this gets a regression test. **Rule:** Updates are manual and offline-installable, never forced.

### T06 Complexity, learning curve and discoverability (27 items, 15 pages)

- "Logos Bible Software is like the greatest library in the world that won't let you in." (Logos App Store, 2026-09-11, OPENED)
- "In the time it would take me to learn how to access all the bells and whistles of the program I could master Greek and Hebrew" (same review)
- "Logos has become much too complicated for the average user. I guess it has just passed me up." (decades-long user, 2026-09-24, OPENED)
- Wish: "the most stripped down basic interface possible, and then allow you to add existing features and functionality that you actually understand and use" (r/LogosBibleSoftware, 2025-11-30, OPENED) https://www.reddit.com/r/LogosBibleSoftware/comments/1paiiz9/dream_with_me_if_you_could_add_or_drastically/
- "it already takes 100 hours of lessons to be considered a pro at it" (Puritan Board, 2024-08-02, OPENED)
- AndBible first run: "they have 1800 documents to choose from, they select them one by one, then download, and finally they can start. I think this is unnecessarily hard." (GitHub #1231, 2021-07-03, OPENED) https://github.com/AndBible/and-bible/issues/1231
- e-Sword LT memory verses: "There is NO ADD icon anywhere in the Bible section. I think I am being tested." (2024-09-24, OPENED). Five other reviewers could not find the same feature.
- theWord (2009): powerful, but "e-Sword and WordSearch have a much less cluttered default set-up."

**simple_bible:** **Rule:** Plain first. The opening screen is a reader with a reference box. Power tools open from the word or verse the user is looking at (right-click or a hotkey), not from a menu wall. **Req:** Progressive disclosure, so advanced panels stay hidden until first used. **Req:** Ships with a complete default library; zero choices before first reading. **Req:** Every feature reachable from a searchable command palette that shows its keyboard shortcut. **Req:** Short built-in help, not hour-long webinars.

### T07 Search that fails or needs syntax (11 items, 9 pages)

- "I can see a word in the GNT, type it exactly in the search box, and Accordance will fail to find it anywhere (including the passage where I first saw it)." (2026-09-20, OPENED)
- "I can actually cut and paste keyword or words out of that passage and attempt to search it, and it will still come up with no matches" (Blue Letter Bible, 2026-08-01, OPENED)
- "it still requires users to type in awkward code-like syntax—something most people aren't trained to do" (Accordance, 2025-10-07, OPENED)
- "Guided searches so I don't need to use complicated syntax." (r/LogosBibleSoftware, 2023-10-05, OPENED)
- Xiphos: Hebrew Strong's numbers below 1000 return nothing because of a zero-padding mismatch (GitHub #1201, 2025-02-19, OPENED). Desktop search misses verb conjugations that the phone app finds (#782, OPENED).
- Logos: "all the search features have been hidden inside of AI-assisted search features" (2026-04-17, OPENED)

**simple_bible:** **Req (golden test):** Any phrase copied from any shipped text finds its own verse, whatever the punctuation, curly quotes, diacritics or Hebrew final forms (the design's normalized search columns, L1). **Req:** Strong's queries accept H1, H0001 and H00001. **Req:** Morphology and lemma searches come from a form builder that shows the generated query and lets the user edit it. **Rule:** Plain precise search is never routed through AI.

### T08 Original-language tools and workflow (8 items, 8 pages)

- "Logos' workflow is tedious for language work." (Puritan Board, 2023-06-06, OPENED). Users still miss BibleWorks for the same reason.
- "It was much better when you could see all the information with one click." (Logos word panel, r/LogosBibleSoftware, 2025-12-03, OPENED)
- theWord praised for showing "the Hebrew or Greek Lemma rather than as a stupid number" (Puritan Board, 2009-08-14, OPENED)
- Bible Hub: "when I find the definitions, I cannot continue in a chapter to study it; but rather I have to exit back out and search again" (2025-12-02, OPENED)
- Literal Word: the dictionary splits one Hebrew word (H8314, "seraphim" and "flying serpent") into unrelated entries (2026-05-29, OPENED)
- "It shouldn't be that you have to go to seminary or grad school to be able to know how to read a critical apparatus of BHS or NA28" (r/LogosBibleSoftware, 2026-06-04, OPENED)

**simple_bible:** **Req:** One click on a word shows lemma, gloss, parsing, Strong's, count and lexicon entries in one panel, beside the text, without leaving the chapter. **Req:** Lemma-keyed lexicon joins, so one Hebrew word never shows as unrelated entries. **Spark S8:** an apparatus in plain English (below).

### T09 Hebrew/Greek display and fonts (3 items; 2 SNIPPET)

STEPBible: chapters cut off when Hebrew shows both accents and transliteration (GitHub #103, OPENED). BibleTime: vowel points misplaced with every font tried (SNIPPET). Logos forum: vowel pointing not aligned (SNIPPET).

**simple_bible:** **Req:** Rendering tests on pointed and cantillated WLC text in WebView2 with the chosen fonts (vault memory: SBL/Ezra-class fonts; keep the LRM marks). Low volume here, but a failure would be fatal for credibility with scholars.

### T10 Sync, accounts, backup and data loss (14 items, 8 pages)

- "when I updated it, it erased every single one of my notes for every book" (Bible Gateway, 2026-08-24, OPENED)
- "most all of my highlighted verses have the texts and the verse cites scrambled--rendering them useless" (Blue Letter Bible, monthly donor, 2025-08-23, OPENED)
- "Ditches Dropbox for "Accordance sync" with 50 MB limit on total data size. My notes are much larger." (2025-10-15, OPENED)
- "I have lost all of my highlighted verses on the desktop app and the desktop app is not syncing with Accordance." (2025-11-03, OPENED)
- Logos prayer list: could not edit, then could not open (2026-09-28, OPENED)
- AndBible: notes restore on a new phone, but reading-plan progress does not (GitHub #55, OPENED)
- Accordance account creation fails with no troubleshooting path (three reviewers, 2025, OPENED)

**simple_bible:** **Rule:** No account. **Req:** User data is append-only with history: An edit writes a new version, and a delete is a soft delete. **Req:** Automatic local backup on exit, rotating, restorable in-app. **Req:** Highlights and notes keyed to canonical verse ids through the versification map, so a text update cannot scramble them (the BLB failure). Sync goes through a folder the user already syncs (09 A16).

### T11 Notes and the personal-data model (12 items, 9 pages)

- "notes is terrible when compared to any modern notes app. hard to find, hard to discover, hard to retrieve, hard to organize." (r/LogosBibleSoftware, 2025-12-31, OPENED) https://www.reddit.com/r/LogosBibleSoftware/comments/1pzvlx5/im_lost_with_notes/
- That thread's consensus is to keep notes in Obsidian with a plugin that links back to Logos. What users then miss: "The search is what I miss most with my current system of keeping the notes in Obsidian."
- Still valued: "The great thing…the only great thing is that you see your notes as a tag inside your Bible."
- e-Sword user who teaches classes: "connect notes with verses in a way that is much more like a physical experience. When I open my Bible, I can see the notes I have written." (2025-09-27, OPENED)
- BLB: wants to see, at any verse, which bookmark folders and notes reference it (2026-08-23, OPENED). Verbum: "Still can't list resources which cite a particular verse or scripture passage one is studying." (2022-10-11, OPENED)
- A place to note a book's quality or bias: "I want a spot to be able say stuff like "This was great, bad, etc" (2025-12-02, OPENED)

**simple_bible:** **Spark S4/S5 below.** **Req:** Margin view, with notes visible beside their verses in every translation. **Req:** Verse backlinks listing every note, tag, highlight and shipped resource that cites this verse. Larry works in Obsidian, so this theme matters doubly.

### T12 Export, sharing and interoperability (9 items, 8 pages)

- "Export notes with citations in CSV and TXT format! For sure!" (r/LogosBibleSoftware, 2024-09-07, OPENED)
- "I desperately want to be able to export research/workflow reports with a way to control what goes in." (same thread, OPENED)
- "Give us an MCP server (which would open up lots of AI possibilities and workflows)." (2026-02-10, OPENED)
- Olive Tree "won't let you copy search results in totality to Word, you have to do it one result by one" (2025-10-08, OPENED)
- Bible Chat "restrict you from copying or sharing the text from the devotional" (2026-10-03, OPENED)
- Module import between ecosystems: AndBible users want e-Sword/MySword/MyBible import (GitHub #1473). A theWord switcher faced 1,534 e-Sword modules to convert one by one (2009).

**simple_bible:** **Rule:** Everything the user can see, the user can export: search results, word studies, notes, highlights, study ledgers. Formats: Markdown, CSV and plain text, with references and provenance. **Spark S6:** local MCP server and link scheme. **Req (FEASIBLE):** Import the user's own e-Sword/MySword SQLite modules locally (09 H02).

### T13 Workspace and reading ergonomics (13 items, 11 pages)

- Most repeated desktop request in r/LogosBibleSoftware, raised by one user in three threads and seconded by others: follow-only linking. "it's super frustrating for the passage you're studying to scroll away when you're scrolling to read the linked commentary" (2025-11-30, OPENED)
- Olive Tree praised because Bible and commentary "both will scroll as you go" (r/Reformed, 2024-03-19, OPENED)
- SwordSearcher convert from e-Sword: "in e-sword under the Naves tab (for example), you can see all the references, but you must either click on them one by one or hover over them one by one" (2019-10-02, OPENED). The loved fix is one click that loads all verses.
- Saved layouts called a "Killer feature" (2020, OPENED). Accordance mobile users want tabs or workspaces.
- Dynamic map: "I wish I could just have a map showing in a separate window that dynamically follows the scriptural text and shows where things are happening" (2026-06-04, OPENED). The user says forum requests for it met "crickets."
- Distraction: YouVersion pop-ups interrupt reading plans; BLB "does have a distraction risk to it"; HN: "Moving graphics are very distracting when one wants to read text."

**simple_bible:** **Req:** Every pane has a link mode: lead, follow, follow-only (scrolling it does not move the leader) or independent. **Req:** Expand all references in a list or article with one click (extends 09 A07). **Spark S7:** map that follows the text. **Rule:** No moving elements in reading views.

### T14 Platforms, offline and portability (12 items, 11 pages)

- Linux is a recurring request. Users run Logos through Wine scripts, Docker or dual-boot (r/LogosBibleSoftware 2023-2026, several users, OPENED). theWord "works perfectly under WINE" (2009).
- Olive Tree's "Windows install" has not been updated "for a good decade" (2025-09-21, OPENED). Olive Tree desktop called "pretty clunky" (2024).
- theWord praised for running "from ANY computer" off a flash drive (2009, OPENED).
- Literal Word users want a synced PC companion (2025-2026, OPENED).
- Logos desktop valued because "everything is there without any distractions, i.e. internet" (2025-10-04, OPENED).
- Logos Android: a paid Bible not usable offline (Trustpilot, SNIPPET).

**simple_bible:** **Rule:** Fully offline, always. **Req:** Portable mode (one folder, runs from a USB drive, no registry writes). **Decision for intent:** Test under Wine as "best effort"? It is a cheap win for the Linux users who ask in every thread. Mobile is out of scope for v1 (09 A14).

### T15 Privacy and tracking (7 items)

- "I'd rather pay for something I can use offline or anonymously." (HN, 2021-06-22, OPENED) https://news.ycombinator.com/item?id=27593230
- "I'd far rather read offline with something that doesn't track my reading/information/etc." (HN, 2021-06-22, OPENED)
- Bible Hub app "contacted 87 domains" in 24 hours, per an Apple privacy report (2026-05-22, OPENED)
- e-Sword LT: no way to deny it network access (2024, OPENED). YouVersion: data-collection journalism (Slate 2013, OPENED).

**simple_bible:** **Rule:** No telemetry, no analytics, no network calls except user-initiated downloads and an optional bring-your-own-key AI call. The About page states this, and a build test asserts no network code in the core.

### T16 Modules and content installation (4 items; 2 SNIPPET)

e-Sword modules freeze during download (SNIPPET). Accordance has stuck content updates (vendor support article, SNIPPET) and a paid NKJV module that never appeared (OPENED). e-Sword LT: Getting a wanted version means a separate website account and download (OPENED).

**simple_bible:** **Rule:** The core ships complete. Optional packs are signed, versioned and atomic: install fully or not at all (09 H01).

### T17 Translations, licensing and canon (7 items)

- e-Sword LT: "I'm on a fixed income and can't afford that" ($14.99 NKJV, 2022, OPENED)
- Xiphos/SWORD lost the ESV: "Crossway revoked permission to distribute (for strategic reasons)." (r/Reformed, 2020-09-07, OPENED)
- Developer: "Getting access to translations has been a challenge due to licensing costs." (HN, 2021, OPENED)
- Catholic users: deuterocanonical books missing from plans and texts (Verbum 2019; e-Sword KJV-A missing Susanna, Bel and the Prayer of Manasseh, 2024; HN 2021; all OPENED)
- e-Sword's free library is "older stuff which has often been superseded by modern research" (r/AcademicBiblical, 2020, OPENED)

**simple_bible:** **Not our problem:** modern licensed translations (09 H05, BLOCKED). The ESV revocation shows that licensed text is a liability even when granted. **Rule:** Ship only texts whose license cannot be withdrawn (CC0/CC BY/PD), and say so as a feature. **Req:** Deuterocanon and LXX are available as first-class texts (the vault's LXX work already supports this), and reading plans can include them. **Gap to name honestly:** "superseded" content. Answer it with the open modern data layers (MACULA, UBS, STEP), not with 19th-century commentaries alone.

### T18 Text integrity, versification and honest counts (9 items, 8 pages)

- STEPBible: ""Occurs in the Bible NN times" should refer to only NT for Greek because it doesn't count OT Greek" (GitHub #93, 2021-04-27, OPENED) https://github.com/STEPBible/step/issues/93
- Olive Tree: "There are some words that are missing from the original KJV bible." No explanation came from the company (2026-08-16, OPENED). "You changed my Amplified version without my consent or knowledge." (2026-07-23, OPENED)
- Bible Gateway: chapters missing (Exodus 3, Matthew 6) (2026, OPENED)
- Verbum: Sirach 24:24-26 does not match the user's printed Bible, a versification difference the user read as an error (2022, OPENED)
- e-Sword LT: "Who is Jeremy the prophet? That's what I mean by spellchecking the texts." (2023-05-13, OPENED). This is the KJV's own spelling at Matt 2:17 and 27:9, read as a typo.
- HN, on AI translation: "Which set of NT Greek manuscripts is it using? Textus Teceptus? Byzantine? Critical Text?" (2026, OPENED). Others value NET-style translator notes.

**simple_bible:** This theme is where simple_bible's existing design (I-002 census, I-004 provenance, I-005 defects as data, versification map) is strongest. **Req:** Every count names its corpus and edition ("Greek NT, SBLGNT: 7 times"). **Spark S2** (text checksums and changelog) and **Spark S3** (archaic-word helper) below.

### T19 AI accuracy, citations and completeness (19 items, 16 pages)

- Logos AI listed the people baptized in the NT and "did miss a few like Paul baptizing Crispus and Gaius (1 Cor 1:14) and Stephanus's household (1 Cor 1:16)" until prompted again (Matt Dabbs, 2025-11-17, OPENED) https://mattdabbs.com/2025/11/17/logos-has-a-new-ai-bible-study-feature-study-assistant-heres-my-take/
- "Since the Study Assistant used a direct quotation, it needed a note, even though it was the most recent source." The professor found the source by manual search (Reading Acts, 2025-11-06, OPENED) https://readingacts.com/2025/11/06/first-look-logos-46-and-study-assistant/
- "I want the best, and I want to be the one who identifies what the best is." (same; the assistant uses only 3-4 sources per answer)
- "There have been times where I've caught it misquoting and then admiring that quotes don't exist after I confront." (r/LogosBibleSoftware, 2026-02-10, OPENED)
- HN on an LLM Bible translation: "there are hallucinations and issues seems like a deal-killer for a religious text." (2026-01-22, OPENED)
- What users do like: "the search results come clearly footnoted with sources in my library, so I can click on any source to verify the AI is not hallucinating on me" (Knowable Word, 2025-11-21, OPENED). Also "The library is only as good as the ability to retrieve the information we need." (r/LogosBibleSoftware, 2025-12-17, OPENED)
- Bible Hub devotions that read as AI-written: "hopefully find one that is written by humans" (2026-06-29, OPENED)

**simple_bible:** This confirms I-001 and I-P01/I-P11. **Req:** AI never produces a list of verses; the engine does, and the list is exhaustive with its count. **Spark S1 (omission check)** below. **Req:** Any quotation in AI wording must match an engine string, or it is struck (FR-053 already covers digits and references; extend it to quotations).

### T20 AI forced on users, opt-out and credits (10 items, 4 pages, all Logos)

- "I'm frankly concerned with the extent to which Logos has incorporated AI into the software, without granting users a setting to opt out of it." (Knowable Word, 2025-11-21, OPENED)
- "AI is automatically enabled whether I want it or not." (App Store, 2026-08-26, OPENED)
- "I don't want the AI features and yet every time I do an inline search it automatically performs it and then tells me I have a limited amount of free searches left." (2026-05-27, OPENED)
- "I recently used 100% of my ai quota and then I could not even use factbook or some other resources." (r/LogosBibleSoftware, 2025-12-11, OPENED)
- "I never saw any indication that we only get 3 free questions until I'd already asked 2" (2026-08-15, OPENED)
- Accordance user: "And no, this does not at all mean that AI should be incorporated into the app like Logos has done. Just make the app easier to use" (2026-06-27, OPENED)

**simple_bible:** **Rule:** AI is off by default and visibly separate (its own pane and button). No non-AI feature depends on it. With the NULL adapter the whole product passes its tests (already in I-001). **Rule:** No quotas; local AI has none, and bring-your-own-key spends the user's own key, which the program says plainly.

### T21 AI doctrine bias and who interprets (9 items, 6 pages)

- Barna (n=442 pastors, n=1,514 adults, surveyed Nov-Dec 2025, published 2026-08-25, OPENED): 94% of pastors, 83% of practicing Christians and 74% of US adults are concerned about AI misinterpreting Scripture. 60% of pastors want AI to present all major interpretations without indicating which is correct. 32% want it to cite scholarly disagreement by source. Practicing Christians are 2.5 times as likely as pastors to want the "right" answer. "What pastors want is simple: Let AI show you the disagreement, but don't let it settle it for you." https://www.barna.com/research/ai-scripture-interpretation/
- "there is currently no way to ask the SA to analyze and synthesize the biblical text itself as the primary source, rather than defaulting to how commentators frame the passage" (r/LogosBibleSoftware, 2026-01-05, OPENED) https://www.reddit.com/r/LogosBibleSoftware/comments/1q4c91c/the_study_assistant_is_new_and_i_want_to_request/
- "I have wrestled with the ai and had it admit that it keeps importing traditions that I have asked it to exclude." (same)
- "I want to be able to weight things by circles of trustworthiness." (r/LogosBibleSoftware, 2025-12-03, OPENED)
- "AI was used to summarize the Bible text itself ... This immediately raised a red flag for me." (2024-10-28, OPENED)
- Persona bots: "Text with Jesus" "would not even offer an unqualified "yes" when I asked whether Jesus was really God." (Christian Post, OPENED)

**simple_bible:** **Spark S9 (text-first answers)** and **Spark S10 (disagreement map)** below. **Rule:** No persona chatbots (no "talk to Jesus or Paul"), and no AI summary that stands in place of the text.

### T22 AI and the integrity of study and preaching (6 items)

- "if I find the AI-generated exegesis and outline useful, it is because I haven't understood the text." (pastor Ezra Dunn, Christ Over All, OPENED) https://christoverall.com/article/concise/encore-a-brave-new-world-of-preaching-logos-ai-sermon-assistant-and-the-ethics-of-sermon-prep/
- "with a single click, you can then insert those "suggestions" right into your notes or manuscript, presenting them as your own work" (Knowable Word, OPENED)
- "When you are writing an essay that asks you to read the Bible and reflect on it, I think AI is disruptive." (professor Phillip Long, OPENED)
- "allows us to be functionally ignorant of God's word without feeling like we are functionally ignorant" (Christian Post, OPENED)
- Earlier, pre-AI version of the worry: "Studying and cherry picking specific things that you are looking for can cause one to lose focus on the bible as a whole." (r/Bible, 2014, OPENED). "I don't want it to study for me." (r/LogosBibleSoftware, 2024, OPENED)

**simple_bible:** **Rule:** No sermon or outline generator. AI text never inserts silently into the user's writing; it pastes with a visible "AI draft" label that stays until the user edits it (extends I-P11/I-P16). This is a values stance Larry can state publicly.

### T23 Accessibility and readability (11 items, 9 pages)

- "You would not believe how aggravating and difficult that simple thing is to do with a screen reader in the Bible Apps and on the websites." This is about copying a verse with its reference. The blind user has searched "for literally years"; Logos and Olive Tree are "just not accessible" (AppleVis, 2026-04-22, OPENED) https://www.applevis.com/forum/windows/accessible-bible-windows-nvda-add
- Blind pastor: "I am trying to find accessible Bible study software for sermon preparation." (SwordSearcher forum, 2026-05-18, OPENED)
- "I'm totally blind and not able to select a different Bible versions I'd like to use." (Bible Gateway, 2026-09-22, OPENED)
- "Logos, please make your programs accessible for all people, including print impaired." (2026-08-12, OPENED)
- Blind writer: "For a long study, I prefer Windows." (Marisa D'Amore, OPENED)
- Low vision: MS user relies on "large and then giant print" (BLB, 2026); no dark mode on the interlinear page; true-black dark mode and custom contrast wanted (Logos, 2025); color e-ink reader user with bad eyesight (2026).
- Memory: early dementia, so wants one verse at a time instead of five (e-Sword LT, 2022, OPENED).

**simple_bible:** Feature parity (09) has no accessibility row. Users show it is a real, underserved gap, and "native Windows" is exactly where blind users say they prefer to study. **Req:** Every function is keyboard-reachable. Every control carries an accessible name. The reading view is real text in reading order (WebView2 ARIA). Tested with NVDA (free) on each release. **Req:** One hotkey copies the verse with its reference. **Req:** Large-print, true-black and low-contrast themes, plus font-size steps up to "giant." Ties to vault practice (Larry's large-print study guides). **Req:** Memory practice lets the user choose how many verses at a time, down to one.

### T24 Audio and read-aloud (4 items)

"I wish it highlighted the verse being read or had some sort of marker that showed the verse being read." (Logos, 2026-08-23, OPENED). BLB audio does not resume where the user left off (2026, OPENED). Olive Tree paid audio jumped chapters (2026, OPENED). SwordSearcher users pipe books into an external TTS and want "a button to play/pause/stop for the reading of books and commentaries" (2019, OPENED).

**simple_bible:** **Req (FEASIBLE):** Windows TTS read-aloud of any text or book, with the current verse highlighted, resume position and pause/stop. CPU-only, offline, and it also serves blind users.

### T25 Church and teaching use (2 items)

e-Sword LT screen sleeps during the sermon (2025, OPENED). Bible Gateway ads make use "in church or at a study almost impossible" (2026, OPENED).

**simple_bible:** A small "service mode" (big text, keep awake, nothing pops up) is cheap on a laptop. Low priority for a desktop v1.

### T26 Free, simple tools are enough (11 items)

- "Use stepbible.com and parabible.com. They are free." (r/Reformed, 2025, OPENED). "There are free tools that do 90% of what I am interested in." (r/AcademicBiblical, 2020, OPENED)
- "Most things are available outside logos for free. I didn't know this until I paid >$900 for all sorts of stuff I found I don't use." (2025-12-17, OPENED)
- Literal Word: "the best, uncomplicated app for Bible study" and "It really lets you focus on the Bible itself." (2025, OPENED)
- BibleWorks: "For in-depth study I use Logos, but for quick reference I use Bibleworks." (2023, OPENED)
- STEPBible for students: "students can take their understanding of the tool home and use it straight away without a major financial investment" (2018, OPENED). The same writer: "But it is not sufficiently developed to act as the main Bible study tool for me".

**simple_bible:** This is the market slot: "BibleWorks-fast, Literal-Word-plain, free like STEP, deeper than e-Sword." The STEP quote marks the bar a free tool must clear to become someone's *main* tool.

## 5. NEW INNOVATION SPARKS

Checked against `10-INNOVATIONS FROM PRACTICE.md` (I-P01 to I-P17), `05-INNOVATIONS.md` (I-001 to I-008) and `09-FEATURE-PARITY` (A01-H08). Each spark is new or adds a layer those files do not have; the overlap is named.

| # | Spark | From (users) | What it does | Overlap / why new |
|---|---|---|---|---|
| **S1** | **Omission check** | Logos AI missed 1 Cor 1:14, 1:16 (Dabbs); "3-4 sources" (Long) | When any AI answer or pasted text lists verses, people or places, the engine runs the exhaustive query and shows what the list *left out* ("2 more baptisms the answer did not mention"). | I-P01 checks claims made; S1 checks what was **not** said. Not in 09/10. |
| **S2** | **Text seal and changelog** | Olive Tree changed the Amplified text silently and dropped KJV words; Bible Gateway missing chapters | Each shipped text shows verse counts and a checksum per book ("KJV 1769 · 31,102 verses · sealed"). Any update to a text produces a visible diff list. The user can pin a text version. | I-004/I-005 are build-side. S2 is user-facing proof that the text did not change. Not in 09/10. |
| **S3** | **Archaic-word and name helper** | "Who is Jeremy the prophet?" read as a typo | Hover glosses for KJV archaic words and old name forms (Jeremy = Jeremiah; Esaias = Isaiah), flagged as the text's own spelling, never "corrected." Draws on the vault's KJV vocabulary-shift work. | Not in 09/10. Distinct from I-P07 (word journey across versions). |
| **S4** | **Trust rings** | "weight things by circles of trustworthiness"; AI pulls "perspectives I do not value"; a wish for a note on a book's bias | The user files each resource into rings (Trusted / Consult / Hold loosely) and can attach a note to a *book* ("Arminian; dated; strong on Greek"). Search results, guides and the AI layer group and rank by ring, and the ring shows on every hit. | I-008 voice labels exist only for Larry's private plug-in, and 09 E11 Collections are plain filters. S4 gives every user labeled trust on every result. |
| **S5** | **Notes as files (Obsidian-compatible)** | Logos notes "atrocious"; users move to Obsidian and lose unified search | Notes are Markdown files in a folder the user picks, with verse links in a stable syntax. simple_bible indexes them, shows them in the margin and backlinks, and searches them together with the Bible. Obsidian, VS Code or any editor can open the same files. | 09 E03/E04 store notes in the user database. S5 makes the user's files the store, which removes lock-in by construction. Not in 09/10. |
| **S6** | **Local engine server (MCP + link scheme)** | "Give us an MCP server"; Obsidian-Logos plugin users; "paste into VSCode" | An opt-in local MCP server exposes the engine (verse, search, census, word study) with provenance on every result. A `simplebible://` link scheme jumps from any document to a verse or saved query. The user's own AI (Claude, ChatGPT and others) then gets facts from the engine instead of from memory. | I-001 keeps AI inside. S6 lets *outside* AIs obey "the engine owns every fact." Not in 09/10. |
| **S7** | **Map that follows the reading** | "a map ... that dynamically follows the scriptural text"; asked on forums with no answer | As the reader scrolls, places named in the visible verses light up on an offline map, with travel lines (Jacob → Haran → Bethel). Built from OpenBible geocoding, TIPNR and MARBLE routes, already licensed in 09 D06. | 09 D06 is a static atlas. Following the text is new. |
| **S8** | **Apparatus in plain English, with disputed-text markers** | "you have to go to seminary ... to read a critical apparatus"; Accordance user wants strikethrough for the long ending of Mark | A toggle marks disputed passages in any text (brackets or dimmed) and explains each variant in one plain sentence: "Missing from the oldest Greek manuscripts (Sinaiticus, Vaticanus); present in the KJV's Greek text." Every claim cites the SBLGNT apparatus or the TR/WH difference. | 09 C11 shows variants for scholars. S8 is the lay translation layer plus in-text markers. |
| **S9** | **Text-first answer mode** | "analyze ... the biblical text itself as the primary source, rather than defaulting to how commentators frame the passage" | A question goes to the engine only: concordance hits, cross-references, immediate context and clause roles, with no commentary in the answer path. If AI is on, it may only phrase that bundle. Commentary is a separate, labeled second step. | I-001 governs facts. S9 is a user-selectable *mode* that also keeps commentary out. Not in 09/10. |
| **S10** | **Disagreement map** | Barna: 60% of pastors want all interpretations shown without a verdict; 32% want disagreement cited | For a passage, line up what the shipped public-domain commentaries and creeds say, grouped by position, each with its source and date, and no verdict. The engine supplies the textual data each position appeals to. | I-P16 "argue the other side" assembles counter-evidence. S10 maps *named positions with sources*. Not in 09 (Logos Lens bar is library-driven). |
| **S11** | **Count-scope label on every number** | STEP #93: "Occurs in the Bible NN times" but OT Greek not counted | Every count in the UI says corpus, edition and unit ("NT, SBLGNT, word tokens: 7"), and a click shows the query. | A light everyday form of I-002 (pre-registered census). Make it a **Rule**, not a feature. |
| **S12** | **Pane link modes, including follow-only** | Most repeated desktop wish in r/LogosBibleSoftware | Lead / follow / follow-only / independent per pane. | Small, but loved and absent on Logos desktop. Not in 09. |
| **S13** | **Plain-first shell with "unlock as you go"** | "the most stripped down basic interface possible, and then allow you to add ... features" | First run is a reader. A tool's panel appears in the menus after first use, or when the user turns it on in a "Tools I use" list. | Not in 09/10. A design rule for intent. |
| **S14** | **Accessible-first study** | Blind users searched "for years"; Logos and Olive Tree inaccessible; blind writer prefers Windows | Screen-reader-complete keyboard study, including the original-language panel read aloud in order (lemma, gloss, parsing). Copy-with-reference hotkey. NVDA test pass per release. | 09 has no accessibility row. This could be a real reason to choose simple_bible. |
| **S15** | **Exhaustive export of a study** | "export research/workflow reports with a way to control what goes in ... I want the whole reading" | A study (ledger I-P12) exports as one readable document with full passages and full public-domain commentary sections, not links or snippets, for print, e-ink or another AI. | Extends I-P05 (share-safe export) and I-P12. The "full text, not snippets" detail is new. |

**The five best (impact × fit with "engine owns every fact"):** S1 Omission check · S6 Local engine server (MCP) · S9 Text-first answer mode · S10 Disagreement map · S14 Accessible-first study. Close behind: S5 Notes as files and S2 Text seal.

## 6. GOTCHAS TO AVOID (what made users quit or stop trusting)

1. **Taking back or paywalling what users already had.** Logos word lookup, cross references and Word Study moved behind a subscription; e-Sword LT removed its widget and cross references. This is the most bitter complaint in the corpus.
2. **Forced redesigns with no way back, and settings that reset.** "How do I recover a prior version", a default translation that resets daily, reading plans rebuilt overnight.
3. **Losing or scrambling user data.** Bible Gateway erased notes on update, BLB scrambled highlight citations, Accordance cut sync to 50 MB, Logos lost a prayer list. Users forgive bugs; they do not forgive lost notes.
4. **Commerce inside Scripture.** Ads, a store in the navigation bar, review nags, cart emails, trial-billing traps. Bible Gateway's app has fallen to 3.65 stars largely on ads. One ad imitated an iCloud login.
5. **AI pushed into plain tasks.** AI on by default, plain search hidden inside AI search, credits burned by an ordinary search, and non-AI features failing when the AI quota runs out.
6. **AI that quotes without citing, picks 3-4 sources or leaves items out,** and a vendor that will not say which model it uses.
7. **Silent text changes or missing text.** Changed Amplified, missing KJV words, missing chapters, versification surprises.
8. **Dependence on the vendor's survival.** BibleWorks, Gramcord and theWord-era formats show it: activation codes, closed module formats, and old modules dropped in a new version (e-Sword 15 RTF modules).
9. **Slowness that grows with the library,** and indexing that blocks work.
10. **Hard onboarding.** 1,800 modules to choose from, features that cannot be found (e-Sword LT memory verses), training sold separately.
11. **Inaccessibility.** Blind users name Logos and Olive Tree as unusable.
12. **Tracking.** 87 domains contacted; no way to stop network access.
13. **Persona chatbots and AI-written devotions.** "Text with Jesus" draws the strongest Christian backlash in the AI material, and users notice AI-sounding devotions.

## 7. Questions this raises for /eiffel.intent (for Larry)

1. **Primary user.** The trust themes come mostly from lay readers. The depth themes come from pastors and students. Who is v1's first user, the lay reader who outgrew e-Sword or the pastor who left BibleWorks? The answer sets the default screen.
2. **Accessibility in v1?** Screen-reader-complete keyboard study (S14) is underserved and fits native Windows. Is it a v1 requirement or a v2 goal?
3. **Notes storage.** Markdown files in a user folder (S5, Obsidian-compatible, no lock-in) or the SQLite user database (09 E03)? Or files as the store and the database as an index?
4. **Local MCP server (S6).** Should simple_bible expose its engine to outside AIs in v1? It is the cleanest way to make "the engine owns every fact" reach Claude/ChatGPT users. It needs a security stance: local-only and opt-in.
5. **AI default.** Confirm AI is off by default, lives in its own pane, never runs inside plain search, and never inserts text into the user's writing unlabeled.
6. **Interpretation stance.** Will simple_bible ever show *positions* (S10 Disagreement map, built from public-domain commentaries), or stay strictly with text facts? Barna says pastors want the disagreement shown and not settled.
7. **No commerce, ever?** Confirm: no store, ads, prompts or account. Is a donation link acceptable on the About page only?
8. **Update policy.** Manual, offline-installable updates? Old workflows kept selectable for one major version after any redesign? Text versions pinnable (S2)?
9. **Canon scope.** Ship the deuterocanon and LXX as first-class texts in v1? Catholic and Orthodox users ask for it, and the vault already has the LXX work.
10. **Platforms.** Windows only, but test under Wine as "best effort" for the Linux users who ask in every thread? Portable (USB) mode in v1?
11. **Performance budgets.** Adopt numeric budgets (cold start, verse jump, whole-Bible search) on a stated reference machine as acceptance tests?
12. **Archaic-text helper (S3).** Which KJV edition label does the program show (vault note: bible.db's KJV is the 1769 Blayney text), and should old name forms be glossed on hover?

---

## References (source pages cited above)

App Store pages (reviews read through `https://itunes.apple.com/us/rss/customerreviews/...`): Logos https://apps.apple.com/us/app/logos-bible/id336400266 · Verbum https://apps.apple.com/us/app/verbum-catholic-bible-study/id571019685 · Olive Tree https://apps.apple.com/us/app/bible-app-read-study-daily/id332615624 · Accordance https://apps.apple.com/us/app/accordance-bible-software/id411970514 · e-Sword LT https://apps.apple.com/us/app/e-sword-lt-bible-study-to-go/id634158738 · Blue Letter Bible https://apps.apple.com/us/app/blue-letter-bible/id365547505 · Bible Gateway https://apps.apple.com/us/app/bible-gateway/id506512797 · Bible Hub https://apps.apple.com/us/app/bible-hub/id1090228108 · YouVersion https://apps.apple.com/us/app/bible/id282935706 · Literal Word https://apps.apple.com/us/app/literal-word-bible-lexicon/id1439010388 · Bible Chat https://apps.apple.com/us/app/bible-chat-daily-devotional/id6448849666

Forums, Reddit, HN, GitHub and articles: Every URL is in `13-user-voice-items.csv`, one per item. Reddit thread IDs used: 1paiiz9, 1fb41o7, 170ofzk, 1qzvutt, 1pccc5j, 1ga9p6p, 1pzvlx5, 1q4c91c, 1gdpcqi, 1polsi1, 1nmjdu9, 1vlc0ol, 1tw0bxa, 1dtd8fv, 1qpqmki, 1ennrq2, 1ny3q2h, 1jkptn8, 1qjclez, 1fh9qk4 (r/LogosBibleSoftware); 1kc3k16, 1bi0b2t, inxleq, k859sj, iyz5yx (r/Reformed); jvib93 (r/AcademicBiblical); 2ljcrx (r/Bible).
