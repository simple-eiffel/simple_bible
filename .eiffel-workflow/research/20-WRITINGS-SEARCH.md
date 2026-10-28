# 20 - Searching Larry's writings (plain and fuzzy)

2026-10-28. Larry: "bible passage links for them and the tools to search, fuzzy search, and perhaps NEEDLE search." NEEDLE's reply: NEEDLE emits tool calls and does not search; build deterministic plain and fuzzy search first, one query grammar, a names table per pack, and the contract `search_writings(query, pack?, within?)`.

## What is searched

Every private pack (commentary, frameworks, books; essays when built) carries one FTS5 table, written by its builder:

```
writing_search(address UNINDEXED, place UNINDEXED, body, voice UNINDEXED)   tokenize = 'unicode61 remove_diacritics 2'
writing_words  = fts5vocab(writing_search, row)                   the pack's vocabulary, for fuzzy search
```

| Pack | One row per | address (a link the window follows) | place |
|------|-------------|-------------------------------------|-------|
| books | block | `book:<id>/<chapter>#<block>` | "Book title, Chapter title" |
| frameworks | section, and the hover | `framework:<id>` | "NAME: Section heading" |
| commentary | field (not the quoted Bible text) | `bible:<b>.<c>.<v>-<c>.<v>` (the section's passage) | the section's heading |

Only `body` is searched: `place` names where a hit stands but is not searched, or a book's title would find every paragraph of it (a heading is its own block, so a chapter's title is still found). Diacritics fold: "zakar" finds "zākar".

The pack rule (every table has NOT NULL `voice` and `provenance_key`) exempts virtual tables and FTS5's five shadow tables (`_data`, `_idx`, `_content`, `_docsize`, `_config`); the search table carries `voice` as a column so every hit is labelled.

## One grammar

The Bible search's grammar (BIB_QUERY_PARSER): words side by side mean AND; "exact phrases"; `word*` a prefix; AND, OR, NOT in capitals; parentheses. A Strong's number or lemma is searched as the word it is written. It becomes an FTS5 expression, every term quoted; NOT takes away from the AND it stands in (`(a AND b) NOT c`).

## Fuzzy

Fuzzy widens each plain word (not a phrase, not a prefix) to the pack's own words within an edit distance of 1 (words of up to five letters) or 2 (longer), transpositions counting one, closest first, at most 12: "remmeber" finds "remember", "sabath" "sabbath". Each pack widens from its own vocabulary.

## The contract

Engine: `BIB_WRITINGS_SEARCH.search (query, fuzzy, pack_kind, within)`: `pack_kind` empty for every pack, or "commentary", "frameworks", "books"; `within` empty, or an address prefix ("book:beacon", "framework:prism"). Hits: pack, address, place, snippet with the matched words marked, rank (bm25 per pack), voice and provenance. Packs are listed commentary, frameworks, books; within a pack, best first.

Window: T6's Writings tab: the query, Fuzzy, the hits; a hit opens its address (the passage with its commentary, the framework, the book at its paragraph). Command line: `bible writings "<query>" [--fuzzy] [--pack <kind>] [--within <prefix>]`, one hit a line, for NEEDLE's validator and for scripts.

## Later

Names tables (ids, titles, aliases per pack) for NEEDLE's tools-v5 data; essays.db joins as a fourth pack with `essay:<series>/<n>#<block>` addresses.
