# 21 - The ingest kit (0.7.32, draft for Larry's review)

2026-10-29. Larry: bring notes, book materials and papers into Simple Bible "without resorting to using expensive Claude or other AI" inside the program; refined the same day to one self-contained file: "a 'file-open' dialog that then includes the target source file directly in the output file with prompt instructions tailored for that ingest file along with the link/ref data from the existing Simple Bible and its present contents." He called it an ingest kit.

## The flow

1. **File > Make ingest kit...** Larry picks a source file (TXT or MD first; DOCX, ODT, EPUB and HTML as their readers arrive, PDF later). Simple Bible writes one file beside it: `<source name>.kit.md`.
2. Larry gives the kit to an AI in an ordinary chat. The kit carries its own instructions.
3. The AI returns one **prepared file** in the Simple Bible notes format (below). Larry saves it.
4. **File > Import prepared notes...** Simple Bible checks it strictly, refuses what fails (and says why, line by line), and adds what passes to the Notes pack: searchable, linked to the verses it discusses, shown under "Books & essays" on those verses, and listed in the next kit's reference data.

## The kit file (one Markdown file, readable by any AI chat)

```
# Simple Bible ingest kit
kit: 1    simple_bible: 0.7.32    made: 2026-10-29    source: Sermon notes on Romans 8.txt (14,203 characters)

## Instructions
(written for this source: its kind, its size, whether to divide it into chapters, what to keep verbatim)

## The prepared file you return
(the notes format, with a short worked example)

## What Simple Bible holds (link only to these)
### Bible books and how to write a reference
### Larry's books, essays, frameworks and earlier notes      <- `bible names`: name, then link
### Link forms: bible:, book:, essay:, framework:, note:

## The source
```text
... the source text, verbatim ...
```
```

The reference data is everything `bible names` lists today (1,547 names) plus the 66 books and their accepted short forms; a few hundred KB at most, well inside a chat's file limit.

## The prepared file (Simple Bible notes format, `sbn: 1`)

```
---
sbn: 1
id: romans8-sermon          (lowercase letters, digits, hyphens; unique)
title: Sermon notes on Romans 8
author: Larry Rix
date: 2026-10-12
source: Sermon notes on Romans 8.txt
status: draft | published | manuscript
---
# No Condemnation               (one "# " title per chapter; a short source is one chapter)

Paragraphs as Markdown. A reference is written plainly in a standard form ("Romans 8:1", "1 Cor 13:4-7");
Simple Bible links it itself.

A link to Larry's other writing uses a target from the kit's list: [the KACC lens](framework:kacc),
[JESUS 06](essay:jesus/6).

A passage the text alludes to but does not cite:
{{suggest: Galatians 5:1 | Paul's same "freedom from the law" argument}}
```

## The importer's checks (nothing passes that fails one)

- The header is complete; `id` is well formed and not already a different note.
- Every `[label](target)` link points at a target in the reference data or at a Bible passage that exists; anything else is refused by line.
- Every `{{suggest: ...}}` names a reference the box reads, in a book the content holds, with a reason.
- Plain references are linked by the window's own linker, exactly as in the books (so "written" links are never the AI's guesses).
- The source must be kept: the importer warns when the prepared text is much shorter than the source (a summary passed off as the notes).

## What is stored

A fourth text-pack kind, **notes** (BIB_TEXT_PACKS: `note:<id>/<chapter>#<block>`, `notes.db`), built by the books' builder from the imported files kept in the user's data folder (`notes\<id>\` plus a generated `<id>.note.json` manifest), so a rebuild never needs the AI again. Suggestions go in their own table (`block_suggestion`: the block, the passage, the reason): shown under the paragraph as "Suggested: Galatians 5:1 - reason", in the verse's "Books & essays" list marked "suggested", never mixed with citations.

## Questions for Larry

1. The kit's name and place: `<source>.kit.md` beside the source, or in a Kits folder?
2. Suggestions in the verse's list: shown with the citations (marked), or behind a "show suggested" switch?
3. A note re-imported with the same `id`: replace the old one (my default), or keep both?
