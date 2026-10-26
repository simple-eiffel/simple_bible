# 18. content.db, minimal schema v1 (2026-10-26)

*What `BIB_CONTENT_SOURCE` checks before `SIMPLE_BIBLE.open` succeeds, and what Task 10's builder writes. Written for Phase 4, Task 7a. The full content.db (spec 07, "Databases": the core, AI-data and author-library stages, FR-130) grows from this; each table the pipeline adds joins the required list when an engine reads it. v1 is what the personal edition of the concordance needs from its main database.*

## The check (in this order)

| Step | Rule | Refusal |
|---|---|---|
| 1 | The file exists and is a file | `Source_unavailable`, the path |
| 2 | SQLite opens it read-only and reads `sqlite_master` | `Database_problem`, SQLite's own words |
| 3 | `PRAGMA user_version` = 1 (`Content_schema_version`) | `Schema_mismatch`, both versions |
| 4 | Every required table is present | `Schema_mismatch`, the first missing table |
| 5 | Every content table declares `provenance_key` `NOT NULL` with a foreign key to `source_provenance` (K7-A, RQ-02) | `Schema_mismatch`, the count of tables without it |
| 6 | `build_run` has a row; the latest `build_id` is the edition (every `BIB_METHOD.database_edition`) | `Schema_mismatch` |

A refused content.db leaves the engine closed (`SIMPLE_BIBLE.last_error`); content.db is required. The concordance pack is separate: a missing or refused conc.db leaves the Bible open (Larry, 2026-10-26).

## Required tables (v1)

| Table | Columns (v1) | Notes |
|---|---|---|
| `source_provenance` | `provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL` | One row per source; the fields of `BIB_PROVENANCE` and `BIB_LICENSE` (FR-003 credits come from here) |
| `build_run` | `build_id TEXT PRIMARY KEY, built_at TEXT NOT NULL, builder TEXT NOT NULL` | The build that wrote the file; `built_at` is ISO 8601, so the latest sorts last |
| `book_catalog` | `book_id INTEGER PRIMARY KEY, code TEXT NOT NULL, name TEXT NOT NULL, is_deuterocanonical INTEGER NOT NULL, provenance_key INTEGER NOT NULL REFERENCES source_provenance` | `book_id` is the vault's `bible_books.id` (FR-105), the key conc.db's `work_book` maps to (research/17) |

## Tables exempt from the provenance-column rule

`source_provenance` and `build_run` (they describe the file, not content), `table_checksum` when present, and FTS5 virtual tables with their shadow tables (spec 07, K7-A).

## Optional content (read when present, never required in v1)

`related_passage` (AI-made rows: `is_ai_made`), the author library's `docs`. Optional public content ships as empty tables in the full file; in v1 an absent table counts as zero rows. A table whose name contains `vector` is refused in Release 1 (`has_vector_tables`; vectors are v2, Q-06).
