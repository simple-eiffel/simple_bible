# REFERENCES: simple_bible

*All URLs fetched or returned by live search on 2026-10-06 unless marked. "(search result)" means the URL came from a search result and its content was summarized by the search engine rather than fetched directly.*

## Documentation Consulted
- https://www.sqlite.org/fts5.html : FTS5 tokenizers; unicode61 default categories "L* N* Co" (Mn marks are separators); remove_diacritics applies to Latin script only; trigram, contentless and external-content tables; bm25, highlight, snippet.
- https://www.sqlite.org/changes.html : Built-in math 3.35.0; STRICT 3.37.0; `->>` 3.38.0; contentless-delete 3.43.0; latest release 3.53.4 (2026-07-24).
- https://sqlite.org/releaselog/3_34_0.html (search result): Trigram tokenizer added in 3.34.0 (2020-12-01).
- https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution : Evergreen vs Fixed; Windows 11 includes the runtime; vast majority of Windows 10 devices have it; detection via `pv` registry value; bootstrapper and standalone installer; ship WebView2Loader.dll.
- https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/evergreen-vs-fixed-version (search result): Evergreen runtime preinstalled on Windows 11.
- https://jrsoftware.org/isinfo.php : Inno Setup features and license posture.
- https://www.sblgnt.com/ : SBLGNT licensed under CC BY 4.0.
- https://huggingface.co/intfloat/multilingual-e5-small/raw/main/README.md : MIT; 384 dimensions; 512 tokens; 101 languages incl. Hebrew and Greek; "query: "/"passage: " prefixes.
- https://www.accordancefiles1.com/helpfiles/14-Win/win14/content/topics/01_welcome_help/new_v_14.htm : Accordance 14 new features (Dynamic Word Study, phrasing, user tools).
- https://en.wikipedia.org/wiki/Logos_Bible_Software : Logos subscription model (Oct 2024), platforms, AI features.
- https://www.logos.com/ : Study Assistant, Factbook, free app with limited features.
- https://www.eiffel.org/ : EiffelStudio community, SCOOP, EiffelWeb.
- https://annotation.github.io/text-fabric/tf/ (search result): Text-Fabric API docs.
- https://pypi.org/project/text-fabric/ (search result): text-fabric 13.1.0, 2026-01-15.

## Repositories Examined
- https://github.com/STEPBible/STEPBible-Data : TAHOT, TAGNT, TBESH/TBESG, TFLSJ, TIPNR, TVTMS, TEHMC/TEGMC, TTESV; CC BY 4.0 at repository level.
- https://github.com/Clear-Bible/macula-greek : Nestle 1904 + SBLGNT syntax trees, glosses, senses, referents; TEI/Nodes/Lowfat/TSV.
- https://github.com/Clear-Bible/macula-hebrew : WLC-based syntax trees, OSHB morphology, Cherith glosses CC BY 4.0; per-component license.
- https://github.com/openscriptures/morphhb : OSHB; lemma/morphology CC BY 4.0; WLC public domain; OSIS XML.
- https://github.com/morphgnt/sblgnt : MorphGNT v6.12; morphology/lemmatization CC-BY-SA; text per SBLGNT terms.
- https://github.com/ETCBC/bhsa : BHSA, CC BY-NC 4.0, Text-Fabric format, versions since 2011.
- https://github.com/ETCBC/text-fabric : Marked "Unsupported"; superseded by annotation/text-fabric.
- https://github.com/annotation/text-fabric (search result): Current Text-Fabric repository.
- https://github.com/asg017/sqlite-vec : Pre-v1 vector search extension; Apache-2.0/MIT; vec0 KNN; Windows supported.
- https://github.com/asg017/sqlite-vec/releases : v0.1.9 stable (2026-03-31); v0.1.10-alpha.4 (2026-05-18) with experimental DiskANN.
- https://github.com/ggml-org/llama.cpp : MIT; CPU SIMD paths; GGUF quantization; llama-server OpenAI-compatible API.
- https://github.com/sql-js/sql.js : MIT; in-memory SQLite in WebAssembly; whole DB loaded into memory.
- https://github.com/ubsicap/ubs-open-license : CC BY-SA 4.0; SDBH and SDGNT dictionaries; Paratext Parallel Passages incl. OT quotes in the NT; HOTTP.
- https://github.com/Copenhagen-Alliance/versification-specification : JSON versification mappings and sniffing rules.
- https://github.com/nida-institute/awesome-biblical-data : Catalog of open biblical datasets with licenses.
- https://github.com/Clear-Bible/speaker-quotations : Speaker quotations in English Bibles (not an NT-use-of-OT index).
- https://github.com/gobo-eiffel/gobo : Gobo libraries (regexp, XML, XPath, string, etc.), MIT; supports ISE Eiffel 25.12.
- https://github.com/eliranwong/LXX-Rahlfs-1935 (search result): Rahlfs derivative, CC BY-NC-SA 4.0; CCAT user declaration requirement.
- https://github.com/eliranwong/LXX-Swete-1930 (search result): Swete-based database with morphology work.
- https://github.com/nathans/lxx-swete (search result): Swete from First1KGreek; CC BY-SA 4.0 per the awesome-biblical-data catalog.
- https://github.com/OpenGreekAndLatin/septuagint-dev (search result): Machine-corrected Swete XML (EpiDoc).
- https://github.com/CenterBLC/LXX (search result): Rahlfs 1935 with CBLC features.
- https://github.com/byztxt/byzantine-majority-text (via awesome-biblical-data catalog): Robinson-Pierpont 2018, public domain.
- http://ccat.sas.upenn.edu/gopher/text/religion/biblical/lxxmorph/0-user-declaration.txt : CATSS user declaration (fetch failed: TLS certificate error; terms cited from search summary and the eliranwong README).

## Applications and Services Surveyed
- https://www.stepbible.org/ ; https://www.stepbible.org/downloads.jsp : STEP Bible online and offline desktop (26_1_2).
- https://www.crosswire.org/sword/index.jsp : SWORD Project, GPL 2.0; BibleTime 3.2.0; Ezra 1.20.
- https://xiphos.org/ : Xiphos 4.5.0 (2026-08-31), SWORD-based, Windows/Linux.
- https://www.e-sword.net/ : e-Sword, free, proprietary.
- https://www.theword.net/ : theWord 7, free, proprietary.
- https://www.bibleanalyzer.com/ : Bible Analyzer, free core, statistics, hit charts.
- https://learner.bible/ : Bible Online Learner (ETCBC4 + Nestle 1904), free, open source.
- https://shebanq.ancient-data.org/ (search result): SHEBANQ Hebrew query site.
- https://parabible.com/ : Parabible parallel BHS/LXX/NET with syntax search.
- https://www.openbible.info/labs/cross-references/ : About 340,000 cross-references, CC BY.
- https://www.accordancebible.com/accordance-14/ : Accordance 14 (403 to the fetcher; features taken from the help file above).

## Local Sources (Eiffel ecosystem and vault)
- `D:\prod\simple_sql\README.md` : FTS5, JSON1, BLOB, vector store, migrations.
- `D:\prod\eiffel_sqlite_2025\README.md`, `COMPILE_FLAGS.md`, `Clib\sqlite3.h`, `spec\msvc\win64\lib\sqlite_2025.lib` : README claims 3.51.1; header and compiled library are 3.31.1 (source id 2020-01-27); OMIT_LOAD_EXTENSION.
- `D:\prod\simple_browser\README.md` : WebView2 backend, development status.
- `D:\prod\simple_onnx\README.md`, `src\onnx_tokenizer.e`, `lib\onnxruntime\` : ONNX Runtime 1.17.3; SentencePiece unigram tokenizer.
- `D:\prod\simple_shaping\README.md` : 0.1.0 pre-release, Phase 4, DirectWrite bidi and shaping real.
- `D:\prod\simple_winhttp\README.md` : Why libcurl-based simple_http cannot ship.
- `D:\prod\simple_rixqwen\README.md` : Hidden llama-server spawn, OpenAI-compatible chat.
- `D:\prod\simple_ai_client\README.md`, `simple_web`, `simple_htmx`, `simple_alpine`, `simple_cli`, `simple_json`, `simple_process`, `simple_testing`, and others listed in 02-LANDSCAPE.
- `D:\prod\simple_scholar\` : seven ECF targets; `data\bible.db` (161 MB, 2026-02-14); `src\` lens and validator classes; previous research in `.eiffel-workflow\research\`.
- Vault: `Rix/Upcoming Projects/Bible Study Workbench - Design (2026-10-06).md` (Step 0 input).
- Vault: `Rix/Data/_Text Credits (paste-ready).md` (licensing).
- Vault: `Rix/Data/_bible.db Defect Register.md` (data caveats, classes A to E).
- Vault: `Rix/Data/_Small Model Survey (2026-10-06).md` : **pending** (not present when this research ran).
- `D:\prod\simple_bible\.eiffel-workflow\research\08-HARVEST-LEDGER.md` : harvest ledger (written separately).

## Articles/Papers
- https://etcbc.nl/uncategorized/integrating-bhsa-data-with-wider-biblical-resources-on-desktop-and-mobile-platforms/ (search result): ETCBC on integrating BHSA into desktop and mobile resources.
- https://en.wikipedia.org/wiki/Alfred_Rahlfs%27_edition_of_the_Septuagint (search result): Background on Rahlfs.

## Discussions/Forums
- https://sqlite.org/forum/forumpost/c230760fdf?t=h (search result): SQLite forum thread on trigram indexes.
