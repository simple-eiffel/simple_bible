# Books pack: Larry's books in simple_bible

*2026-10-28. Larry's request: "get my books into simple_bible so that we have a books tool that the users are able to access my books, but also to be able to link my books to the various things like the scripture passages, the commentaries, the frameworks, and other things that are linkable." The COMMENTARY session inventories the books and prepares one manifest per book; this session builds the pack, the links and the tool. Same pattern as the commentary pack (one private pack, built from sidecars) and the frameworks pack (research/18).*

## What "digitized" means here

The books already exist as Markdown manuscripts, chapter by chapter (the PDFs are print outputs), so nothing is scanned. The builder reads the Markdown and keeps it as **blocks**: each heading, paragraph, block quote and list item, in order, inside its chapter. The block is the unit everything links to: a verse, a framework, a commentary section can point at one paragraph of one chapter.

Address of a block: `book:<book_id>/<chapter>#<block>`, for example `book:zakar/4#12` (chapter ordinals and block ordinals from 1). `book:zakar/4` is the chapter, `book:zakar` the book.

## Pipeline

```
<book_id>.book.json (one manifest per book, COMMENTARY)  +  the chapter Markdown files it names
        -> bible_build --books <folder of manifests> --uses-frameworks frameworks.db --out books.db
books.db (private pack, like commentary.db)  ->  simple_bible: the Books tool, links, hover cards, indexes
```

## The manifest: `<book_id>.book.json`

```json
{
  "id": "zakar",
  "title": "ZAKAR",
  "subtitle": "...",
  "author": "Larry Rix",
  "status": "published",
  "edition": "KDP 2026, 6x9",
  "year": 2026,
  "aliases": ["ZAKAR (the book)"],
  "description": "Two or three plain sentences: what the book is about, for the Books tool's list and its hover card.",
  "root": "the book's folder, relative to the manifest folder",
  "chapters": [
    {"title": "Front matter", "file": "00 - Front Matter.md", "kind": "front"},
    {"title": "Chapter 1: ...", "file": "Ch01 - ....md", "kind": "chapter"},
    {"title": "Notes", "file": "99 - Notes.md", "kind": "back"}
  ],
  "skip_headings": ["Draft notes", "TODO"],
  "source": "which manuscript version this is, in words (\"v3, the KDP text\")"
}
```

| Field | Rule |
|---|---|
| `id` | lowercase ASCII letters and digits, unique; the link target is `book:<id>` |
| `status` | `published`, `manuscript` (finished, unpublished) or `draft` |
| `aliases` | spellings that link to the book in commentary or notes; never a framework's name alone (ZAKAR the framework and ZAKAR the book are told apart by the alias) |
| `chapters` | in reading order; `kind` front, chapter or back; `file` relative to `root` |
| `skip_headings` | sections the builder leaves out (working notes inside a chapter file) |

The Markdown files stay where they are; the manifest only names them. Wiki-style links (`[[...]]`) become plain text; embedded images are left out (a caption stays); YAML front matter is dropped.

## What the build adds

- **Blocks**: every heading, paragraph, quote and list item of every chapter, in order, with its Markdown.
- **Scripture index**: every Bible reference in a block (the commentary's own reader, BIB_REFERENCE_LINKER, ranges included) as a passage row: book, chapter, block, start and end verse. A verse then finds every paragraph of every book that cites it.
- **Framework index**: every framework name in a block (BIB_FRAMEWORK_NAMES, the linker's own rule) as a row.
- Checks: unique ids and aliases, every chapter file present and readable, at least one chapter; a failure names the manifest and the file.

## In the window

- **The Books tool: the bottom zone's "Author Library" tab** (T6, a placeholder until now): the books on the left, the chosen book's chapters, and the chapter read as formatted text; references in it are passage links with hover cards, framework names framework links. T6 maximizes for long reading.
- **"In the books"**: a tab beside Commentaries and Cross-refs (T5) listing the paragraphs of the books that cite the verse read, each with its book, chapter and the first words; a click opens it in the Books tool at that paragraph.
- **Frameworks**: each framework's page adds "Where the books discuss it".
- **The commentary** may write explicit links, `[ZAKAR, chapter 4](book:zakar/4)`; they open the Books tool, and rest on one for the book's title, chapter and description.
