# LARRY'S ANSWERS to the specification questions (Q-01 to Q-16)

*2026-10-06. Larry: "all as recommended." Each answer below is the recommendation from `08-VALIDATION.md`, now decided. These are binding inputs to `/eiffel.intent`.*

| # | Question (short) | DECIDED |
|---|---|---|
| Q-01 | Release 1 scope | **1a then 1b.** 1a covers the engine, core texts, reader, search, census and shapes, the They Chose seed, the word's journey, divine names, renderings, the author library, and notes, highlights, bookmarks and history. 1b covers commentaries, lexicons beyond Strong's, dictionaries, devotionals, prayer, memory and plans. The design is the same either way. |
| Q-02 | SQLite externals (FT-02) | **Patch eiffel_sqlite_2025 in place, together with the SQLite upgrade (FT-01)**, with one fleet regression run. |
| Q-03 | Fonts | **SIL OFL fonts only** (Ezra SIL; Gentium Plus or Noto for polytonic Greek), unless the SBL font terms are verified. |
| Q-04 | Ecclesiastes in the Swete slot | **Brenton 1851 rows, clearly labeled** as Brenton. |
| Q-05 | Harvest ledger update | **Yes.** H-01 to H-07, H-13 and T-07 become ARCHIVE-ONLY. Retirement criterion R-4 reads "native face" (D-006 overtook them). |
| Q-06 | Related passages in Release 1 | **Yes:** neighbors only. The vectors arrive with v2 meaning search, which keeps the download smaller. |
| Q-07 | Louw-Nida domains for T2 shapes | **UBS SDGNT (CC BY-SA 4.0).** |
| Q-08 | TUI face | **None.** |
| Q-09 | Withdrawn author documents | **Excluded from search by default**, with an "Include withdrawn" switch. Always labeled. |
| Q-10 | Primary first user | **The lay reader who outgrew e-Sword.** The Simple layout is the default. |
| Q-11 | Notes storage | **A Markdown folder (Obsidian-compatible) as the store, with user.db as its index**, if Release 1 can carry it. Otherwise user.db first. Both sit behind `BIB_NOTE_STORE`. |
| Q-12 | MCP face for users' own AIs | **v1.5, stdio only** (`bible_mcp`, opt-in; new fleet library LG-06). |
| Q-13 | Screen-reader access | **v1**, if the simple_shell and simple_widgets owners can schedule GW-14 (the UI Automation bridge). It is a real reason to choose the tool. |
| Q-14 | Trust rules (A-029) | **RATIFIED.** No tiers, ads, store, prompts, accounts, telemetry or activation. AI is off by default, never in plain search, and never pasted unlabeled. No persona chatbots or sermon generator. A donation link on the About page only. |
| Q-15 | Performance reference machine | **State both.** Gate on 8 GB CPU-only **with SSD**; report HDD numbers too. Targets: verse jump under 100 ms, whole-Bible search under 300 ms. |
| Q-16 | Deferred innovation sparks | **Decide each one at `/eiffel.intent`**: S10 disagreement map, S3 archaic-word helper, S4 trust rings, S7 map that follows the reading, S8 plain-English apparatus, S13 unlock-as-you-go, S15 exhaustive study export. |

## Also carried forward (ratified earlier on 2026-10-06)

- **D-006:** the face is native simple_widgets. No WebView2. Gaps get fixed in the libraries.
- **D-011:** Swete is the default. Rahlfs only after permission.
- **D-016:** Release 1 runs no AI on the user's machine. It ships precomputed related passages, labeled.
- **D-019:** rix.db ships in full, rebuilt to current, with status labels.
- **D-020:** no Python in the product. Python tools are reference implementations, and the Eiffel ports must pass differential tests.
