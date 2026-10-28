# Frameworks pack: the sidecar the writing side prepares

*2026-10-28. Larry's request: every FRAMEWORK(TM) name anywhere in simple_bible carries a hover card that says what the framework is, and a click opens it in a Frameworks tool; the contents are rewritten so the common Christian reader can follow them. Decided with Larry the same day: the tool is a **Frameworks tab in the Dictionary and Lexicon pane (T4)**, so the commentary stays in view beside it; the **COMMENTARY session writes** the plain-reader text and Larry reviews it before it ships.*

## Pipeline

```
one sidecar per framework (JSON, below)  ->  bible_build --frameworks <folder> --out frameworks.db
frameworks.db (private pack, like commentary.db)  ->  simple_bible: links, hover cards, the T4 tab
```

The pack is private, like commentary.db: never published, shipped only in the personal installer.

## The sidecar: `<id>.framework.json`, one per framework

```json
{
  "id": "kacc",
  "name": "KACC",
  "mark": true,
  "title": "Kingdom Allegiance in Contested Cosmos",
  "aliases": ["KACC"],
  "tier": "master",
  "status": "draft",
  "hover": "One or two plain sentences, at most 280 characters: what this framework says, in words a reader with no training follows.",
  "sections": [
    {"heading": "What it is", "markdown": "..."},
    {"heading": "Why it matters", "markdown": "..."},
    {"heading": "The question it asks of a passage", "markdown": "..."},
    {"heading": "Key passages", "markdown": "Psalm 82; Ephesians 6:12; Daniel 10:13-21"},
    {"heading": "A common reading it corrects", "markdown": "..."}
  ],
  "related": ["prism", "lotf"],
  "source": "the framework's own file name, for provenance (no folder path)"
}
```

| Field | Rule |
|---|---|
| `id` | Lowercase ASCII letters and digits, unique; the link target is `framework:<id>` |
| `name` | The name as written in prose, without the mark ("KACC", "ZAKAR", "AQOV" may carry its accents in `aliases`) |
| `mark` | true when the name carries (TM) in prose; the link keeps the mark the text wrote |
| `title` | The full name |
| `aliases` | Every spelling that should become a link, case-sensitive ("KACC", "the JESUS Cornerstone", accented forms); the name itself is always one |
| `tier` | `cornerstone`, `master`, `recovery`, `sub` (a sub-framework) |
| `status` | `draft` until Larry approves it, then `reviewed`; the tool labels a draft as one |
| `hover` | Plain text (no Markdown), 280 characters at most; the card shows it under the title |
| `sections` | Markdown, in the order shown; Bible references written out ("Romans 8:38-39") become passage links with hover cards; another framework's name becomes its link |
| `related` | Ids of frameworks a reader should look at next |
| `source` | The source file's name, for the pack's provenance |

Writing rules for the plain-reader text: the commentary's production rules apply (the writing side holds them); no unexplained jargon; a Hebrew or Greek word gets its transliteration, pronunciation and plain meaning the first time, as in the commentary's terms.

## What the build adds

- **Where the commentary uses it**: computed by `bible_build` from commentary.db (every section whose text names the framework), so it never goes stale.
- Checks: unique ids and aliases, every `related` id exists, the hover length, at least the first three sections present; a failed check names the file and refuses the build.

## In the window

- A framework name in the commentary (and later in notes and cards) is a link: hover shows the title and `hover` text, with "Draft" when `status` is `draft`; a click opens T4's Frameworks tab at it (the commentary stays where it is).
- The Frameworks tab lists every framework by tier; choosing one shows its sections, related frameworks and the commentary sections that use it.
