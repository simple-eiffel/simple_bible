# Design Scan (diff mode): simple_bible since 3990d13
# Date: 2026-10-30
# Subjects: ingest/bib_markup_text.e (new), ingest/bib_source_reader.e, simple_bible.ecf, simple_bible_app.ecf, testing/test_sources.e (new), testing/test_app.e, testing/test_facade_open.e, fixtures; sibling: simple_pdf src/core/simple_pdf_reader.e (a745e0b..HEAD)
# Mode: read-only; nothing compiled or run. Every finding below comes from reading the cited lines, not from running the code.

## Summary

| Category | Findings | High | Medium | Low |
|----------|----------|------|--------|-----|
| Defects (D / robustness) | 17 | 3 | 8 | 6 |
| Abstraction notes | 2 | 0 | 0 | 2 |
| MI / Generics | 0 | 0 | 0 | 0 |
| **Total** | **19** | **3** | **8** | **8** |

Of the 19 findings, 17 are defects or robustness gaps (numbered 1 to 17) and 2 are abstraction notes. The two
ecf changes are clean: both files add only simple_archive and simple_pdf, in the same style as their neighbours.

## Findings

| # | Priority | File | Issue |
|---|----------|------|-------|
| 1 | HIGH | ingest/bib_markup_text.e:383-409 | An empty heading or empty list item keeps its mark, and the next paragraph is written as a heading or item (Word, LibreOffice, HTML) |
| 2 | HIGH | ingest/bib_source_reader.e:225-284 | Heading rule splits sentences of PDFs whose lines are shorter than 60 characters |
| 3 | HIGH | ingest/bib_source_reader.e:253 | A heading line is glued onto the end of the paragraph before it when no blank line precedes the heading |
| 4 | MEDIUM | ingest/bib_source_reader.e:182-186 | EPUB hrefs with "../" are not normalized, so the pages vanish |
| 5 | MEDIUM | ingest/bib_source_reader.e:337-347, 215-216 | Result of the local copy ignored; simple_pdf precondition then fails |
| 6 | MEDIUM | ingest/bib_source_reader.e:123-126, 215 and simple_pdf_reader.e:171 | A non-ASCII program, user, or TEMP folder breaks PDF reading |
| 7 | MEDIUM | ingest/bib_markup_text.e:281, 330 | Skip regions never close when the end tag is omitted (head, script) |
| 8 | MEDIUM | ingest/bib_markup_text.e:411-429, 93-100 | A stray "<" or unbalanced quote makes the scanner drop the rest of the file |
| 9 | MEDIUM | ingest/bib_markup_text.e:494-516 | Named entities limited to 18; the rest are written out literally |
| 10 | MEDIUM | ingest/bib_source_reader.e:141, 85 | HTML and text are read as UTF-8 only; cp1252 files and a BOM go wrong |
| 11 | MEDIUM | ingest/bib_source_reader.e:257-260 | Line-end hyphen joined away from genuine compounds |
| 12 | LOW | ingest/bib_markup_text.e:83-88 | CDATA text is entity-decoded |
| 13 | LOW | ingest/bib_markup_text.e:152-174 | attribute_of needs "name=" with no spaces and a quoted value |
| 14 | LOW | ingest/bib_markup_text.e:121-150 | tags_named does not skip comments or CDATA |
| 15 | LOW | ingest/bib_source_reader.e:184-197 | Missing EPUB pages are dropped silently; the zip is reopened per page |
| 16 | LOW | ingest/bib_source_reader.e:343, 359 | Fixed temp name, delete result ignored (a user's document may stay in TEMP) |
| 17 | LOW | ingest/bib_markup_text.e:460, ingest/bib_source_reader.e:311-312 | Duplicate hex-digit parsing; to_character_8 on arbitrary characters |

## Detailed Findings

### Finding 1 (HIGH): empty heading or item mark leaks into the next paragraph
**Evidence:**
- `end_block` (ingest/bib_markup_text.e:396-407) resets `heading` and `is_item` only inside `if not l_text.is_empty`. When the block is empty (line 408 just wipes it), the marks survive. Line 386 documents this as intended for "<li><p>...", but it is applied to headings as well.
- Word: `read_docx_tag` sets `heading` at `w:pstyle` (line 311-318), and `w:p` close calls `end_block` (line 307-308). `w:numpr` sets `is_item` (line 319-320).
- LibreOffice: `text:h` open sets `heading` (line 332-339). `text:list-item` open sets `is_item` even for a self-closed `<text:list-item/>` (line 342-345; `a_empty` is not tested).
- HTML: `</h1>` (line 283-287) ends the block but does not clear `heading`. Only `</li>` clears `is_item` (line 290).

**Concrete inputs that go wrong:**
- Word: `<w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr></w:p><w:p><w:r><w:t>Body text.</w:t></w:r></w:p>` produces `# Body text.` An empty Heading 1 paragraph is common in real Word files (a blank styled line, or a paragraph holding only a picture or page break).
- EPUB page: `<h2><img src="title.png"/></h2><p>It was a dark night.</p>` produces `## It was a dark night.` Image-only chapter titles are common.
- LibreOffice: `<text:h text:outline-level="1"></text:h><text:p>Body</text:p>` produces `# Body`.
- Tests: none of the three markup tests has an empty heading or item (testing/test_sources.e:20-51).

**Suggested Action:** clear `heading` and `is_item` when a block ends (a close tag, or a new paragraph or heading start) even if empty. Keep the carried mark only for `li` followed by an inner block tag. Add a test per kind.
**Effort:** about 3 features (`end_block` plus two `read_*_tag` branches) and 3 tests.

### Finding 2 (HIGH): heading rule splits a sentence in a narrow-line PDF
**Evidence:** `prose_from_pdf` line 253 calls `is_heading_line (l_last) and then l_line [1].is_upper`. `is_heading_line` (273-284) is true for any line under `Heading_width` (60, line 286) that does not end in a closing mark. It uses no information about the other lines in the block.
**Concrete input:** PDF lines of about 45 characters, for example a two-column layout, a hymnal, slides, or a narrow-margin sermon:
```
...and then he said that
Jesus would come again to
```
The first line is under 60 characters with no closing mark and the next begins with a capital ("Jesus", "God", "Lord", "I"). The paragraph is cut in mid-sentence and the rest begins a new paragraph. In scripture-heavy prose a capital after a wrapped line is very common.
The fixture (testing/fixtures/sermon_sample.pdf, made by wkhtmltopdf) has full-width lines, so test_pdf_reads_as_prose (testing/test_sources.e:82-102) cannot show this.
**Suggested Action:** measure the typical line width of the block or document (for example the median or maximum line length), and call a line a heading only when it is clearly shorter than that. Also require the heading line to have started a paragraph or follow a blank line. Add a fixture or a string-level test of `prose_from_pdf` with 45-character lines.
**Effort:** 1 feature changed (`is_heading_line` gains a width argument), 1 test. `prose_from_pdf` is a string-in, string-out feature, so it can be tested without pdftotext.

### Finding 3 (HIGH): a heading is attached to the previous paragraph
**Evidence:** a heading line is recognized only when the line after it arrives (line 253 tests `l_last`). A heading line itself is processed first, through the branch at lines 261-263: if `l_paragraph` is not empty, the heading is appended to the paragraph before it with a space. Only then does the following capital line flush the paragraph, heading included. The description (lines 229-230) says pdftotext writes no blank line after a heading. If it writes none before one either (the case when a heading sits directly after a wrapped paragraph's last line), the heading ends the previous paragraph.
**Concrete input:**
```
...in the beginning God created.
Second part
Now the Lord said
```
Result: `...in the beginning God created. Second part` and then `Now the Lord said`. The test passes only because the fixture has a blank line before "Second part" (line 94 asserts `%N%NSecond part%N%N`).
**Suggested Action:** before appending a line, look ahead: if the line is short and the next non-empty line starts with a capital, flush the paragraph first. Two lines of look-ahead replace the `l_last` bookkeeping. Verify with a no-blank-line test.
**Effort:** 1 feature (`prose_from_pdf`); fix together with Finding 2.

### Finding 4 (MEDIUM): EPUB hrefs are not resolved
**Evidence:** ingest/bib_source_reader.e:182 builds the base folder from the package path, and line 186 joins `l_base + url_decoded (al_href)` with no normalization. A package at `OEBPS/Content/content.opf` that lists `../Text/ch1.xhtml` becomes `OEBPS/Content/../Text/ch1.xhtml`, which is not an entry name. `archive_entry` fails; line 191-192 drops the page without a word. Every page can vanish, giving "No text in ...". A `#fragment` in an href has the same effect.
**Suggested Action:** resolve "." and ".." segments and cut at "#" in a small `resolved_href` feature. The tests (testing/test_sources.e:64-67) use only `OEBPS/ch2.xhtml` style names.
**Effort:** 1 feature, 1 test.

### Finding 5 (MEDIUM): failed local copy leads to a precondition failure
**Evidence:** `local_path` (ingest/bib_source_reader.e:343) assigns `l_ok := ...copy_to (l_copy)` and never reads it, then sets `local_copy := l_copy` and returns the path. If the copy fails (full disk, temp folder not writable), `pdf_text` calls `extract_text_flowing (local_path (a_path))` (line 216) whose precondition `file_exists` (simple_pdf_reader.e, new feature) is violated. A contract violation stops the window in a build with contracts (the same kind of crash the test comment at testing/test_sources.e:98-99 describes). With contracts off, the failure message is a misleading "pdftotext failed".
**Suggested Action:** make `local_path` report failure (empty result with `last_error` set) and have the three callers check it; do not store `local_copy` after a failed copy.
**Effort:** 1 feature plus 3 call sites.

### Finding 6 (MEDIUM): non-ASCII tool, TEMP, or user folder
**Evidence:**
- `pdf_tool` (lines 119-128) can sit under the per-user install folder, which includes the user name. `pdf_text` passes it through `string_32_to_utf_8_string_8` (line 215), but the process is started from an 8-bit command line (simple_pdf_reader.e `execute_pdftotext`, lines 388-397). A non-ASCII user name probably fails.
- `extract_text_flowing` writes its temp file in `get_temp_directory` (simple_pdf_reader.e:171), unlike the reader's own `temp_folder` (lines 364-372), which falls back to a plain ASCII folder.
- The failure surfaces as "The PDF could not be read: pdftotext failed: ...", with no hint about the cause.
- Not run; flagged from the code reading only.
**Suggested Action:** apply the `temp_folder` fallback inside simple_pdf, or copy the PDF and run the tool from an ASCII folder. At minimum name the non-ASCII path in the message. The user-name case is only a risk if the app is installed per-user; confirm against the installer before ranking higher.
**Effort:** small, 1-2 features (one in the sibling library).

### Finding 7 (MEDIUM): skip regions without an end tag
**Evidence:** `skipping` (ingest/bib_markup_text.e:234, 261-264) ends only at the matching close tag. HTML allows a head element with no `</head>`, and a script or template that is never closed (lines 281-282). Odt notes behave the same (330-331).
**Concrete input:** `<html><head><title>T</title><body><p>Real text</p></body></html>` (head not closed) leaves the whole page skipped, so the file reports "No text". The same happens to an unclosed `<script>`.
**Nested regions:** `<svg>` inside `<svg>` (or template in template) ends the skip at the first `</svg>` and leaks the rest. There is no depth counter (a LOW concern on its own).
**Suggested Action:** for `head`, also end the skip at `<body`; keep a depth count for same-name nesting.
**Effort:** 1 feature.

### Finding 8 (MEDIUM): a stray "<" or unbalanced quote loses the rest of the file
**Evidence:** `tag_end` (411-429) tracks quotes from the "<". With no closing ">" it returns 0, and `text_of` then sets `i := l_markup.count + 1` (95-97): everything after is dropped without any message. In HTML text with an unescaped "<" ("if a < b and it's ...") `tag_end` also swallows the text up to the next ">" or to the end.
No loop risk was found: every branch of `text_of` strictly increases `i` (lines 82, 92, 97, 99, 108), `tags_named` ends on `j = 0`, and `attribute_of` advances `i` through `substring_index (l_name, i + 1)`. `is_at` and the index bounds are safe (`i + 4` and `i + 9` are at most `count + 1` once `is_at` has passed).
**Suggested Action:** when a tag has no end, treat the "<" as text and continue; for HTML, a "<" followed by a non-letter, "/", "!" or "?" is text.
**Effort:** 1 feature.

### Finding 9 (MEDIUM): few named entities
**Evidence:** `Named_entities` (494-516) holds 18 names. `&eacute;`, `&shy;`, `&ensp;`, `&emsp;`, `&laquo;`, `&raquo;`, `&bull;`, `&deg;`, `&times;`, `&Aacute;` and the rest of HTML's list come out literally ("Caf&eacute;" stays so). Hebrew and Greek texts use numeric references, which work.
**Suggested Action:** extend the table or move it to a shared table; at least the Latin-1 set.
**Effort:** data only.

### Finding 10 (MEDIUM): UTF-8 only for HTML and text
**Evidence:** `plain_text` (ingest/bib_source_reader.e:138-147) reads with `read_text_utf_8` only. An HTML file saved by Word or an older editor as Windows-1252 shows the replacement or garbled characters for every accented letter. A byte-order mark at the start of a UTF-8 file stays in the text as U+FEFF (not whitespace, so `end_block`'s adjust does not remove it) and reaches the kit's first line. The meta charset is never read. I did not check what `read_text_utf_8` does with invalid bytes.
**Suggested Action:** drop a leading U+FEFF; read `<meta charset>` or fall back to cp1252 on invalid UTF-8.
**Effort:** 1-2 features.

### Finding 11 (MEDIUM): line-end hyphen joined away from genuine compounds
**Evidence:** lines 257-260: any paragraph ending in "-" followed by a lowercase line is joined with no space. "well-" / "known" becomes "wellknown", "Jesus-" / "like" becomes "Jesuslike". It cannot tell a typeset break from a compound. A proper-noun compound has the same trouble ("Judeo-" / "christian" becomes "Judeochristian"), and a numeric range such as "5-" / "7" is not joined (digits are not lower case), which is right.
**Suggested Action:** accept, document it, or join only when the joined word is likely a dictionary word. Searchability is the stake, so ranking is MEDIUM rather than LOW.
**Effort:** policy decision.

### Findings 12 to 17 (LOW)
- **12. CDATA decoded** (ingest/bib_markup_text.e:83-88): `add_text` always calls `decoded` (line 365), so a literal "&amp;" inside CDATA becomes "&". Pass a flag.
- **13. attribute_of** (152-174): `href = "x"` (spaces around "=") and unquoted HTML values are not found. For the XML files it is used on this is acceptable; document it.
- **14. tags_named** (121-150): comments, CDATA and processing instructions are not skipped, so an `<item .../>` inside a comment in an OPF is counted. Rare.
- **15. EPUB** (184-197): each page costs a full zip open and validation in `archive_entry` (lines 158-160); a large book repeats it per chapter. Missing pages are dropped silently; a partial book reports success (the `last_error` the failed page set is cleared at line 109).
- **16. temp copy** (343, 359): the name is fixed (`simple_bible_source.<ext>`), so two program instances or workers collide. `drop_local_copy` ignores the delete result, so a failed delete leaves the user's document in TEMP. Deletion runs on every normal path of `text_of` (line 101), but not if an exception ends the routine first. `copy_to` overwrites (simple_file `copy_to` opens the destination for write), so a stale copy is not read.
- **17. small duplicates:** the hexadecimal digit lookup appears in `hex_value` (ingest/bib_markup_text.e:460) and `url_decoded` (ingest/bib_source_reader.e:311-312). Both call `to_character_8` on an arbitrary CHARACTER_32, which I could not confirm is contract-safe above code 255.

### Abstraction notes (LOW, A1/A5)
- **A-1:** `temp_folder` (ingest/bib_source_reader.e:364-372) repeats a TEMP lookup that gui_app/bib_gui_app.e:327 also does (`snapshot_user_path`), and the temp-then-ASCII fallback is needed by simple_pdf as well (Finding 6). A shared "ASCII-safe temp folder" helper in simple_env would serve all three. Effort: 1 feature.
- **A-2:** `hex_value` / `url_decoded` hex parsing (Finding 17) could be one helper if more decoders arrive. Effort: 1 feature. No MI or generics opportunity was found; BIB_MARKUP_TEXT and BIB_SOURCE_READER have no inherit clauses, and no other class in ingest/ or src/ repeats the markup scanner or the entity table.

## Contract and path checks asked for

- **text_of postconditions (bib_source_reader.e:111-113):** checked each branch. Missing file, wrong kind, plain text, HTML, Word, LibreOffice, EPUB (no container, no package, no readable opf) and PDF (no tool, reader error) either return Result with `last_error` void or Void with `last_error` set. Lines 102-110 set both for the empty and the Void-without-reason cases. Nothing violates `read_or_why` or `text_when_read` on a path I could trace. Residual risk: Findings 5 and 6, where the contract of simple_pdf fires before this routine's own ensure.
- **Temp-copy cleanup:** `drop_local_copy` runs once, after all branches (line 101). OK on every normal path; not on exceptions (Finding 16).
- **Failure messages:** specific and useful for no file, wrong kind, not an archive, entry missing, no package, no pdftotext, and scanned PDF (OCR hint). Weak for Findings 4, 5, 6 and for partial EPUBs.
- **Sibling simple_pdf (a745e0b..HEAD):** `extract_text_flowing` closes and deletes its temp file, returns an empty string on empty output (the fix applied to the other three extractors too), and guarantees no form feeds through `-nopgbrk`. The postcondition `no_page_breaks` holds if the option is honoured. Remaining notes: the failure message is "pdftotext failed: " plus the output (good); no timeout on the child process (a very large PDF blocks the caller; LOW); the same precondition risk as Finding 5.
- **Tests (testing/test_sources.e, test_app.e, test_facade_open.e):** cover the happy paths and the not-an-archive case; the PDF test runs only where `SIMPLE_BIBLE_PDF` is set (test_app.e run_sources_tests skips it as skeletal otherwise). Missing: empty headings and items (Finding 1), a PDF with short lines or no blank line before a heading (Findings 2 and 3), `../` EPUB hrefs (Finding 4), an unclosed head or script (Finding 7), an unescaped "<" (Finding 8). The test_facade_open changes (five sources, a fake .docx failing by name) are consistent with the reader's behavior.

## Recommended Order

1. Finding 1 (all three markup kinds produce wrong headings and bullets on common real files).
2. Findings 2 and 3 together (one routine, `prose_from_pdf`; test it at string level, no pdftotext needed).
3. Finding 4 (silent loss of EPUB pages).
4. Findings 5 and 6 (crash and install-path risks; confirm the per-user install path first).
5. Findings 7 and 8 (scanner robustness), then 9 to 11 as policy items, then the LOW items.
