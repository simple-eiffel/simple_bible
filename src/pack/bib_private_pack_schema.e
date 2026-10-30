note
	description: "[
		What every private pack's schema says alike (design scan 59): its kind, file and
		title, the version BIB_PRIVATE_SOURCE reads, the author, the `meta' and
		`source_provenance' tables made first and the version set last, and the
		lowercase ids its links name, and the search tables every private pack
		carries (research/20: `Search_table', FTS5, and `Words_table', its
		vocabulary for fuzzy search). The commentary, frameworks and books schemas
		inherit it; each adds its own tables (`pack_tables') and link grammar.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PRIVATE_PACK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8
			-- `meta.pack_kind' of the pack.
		deferred
		end

	Pack_file_name: STRING_8
			-- The pack's file in the packs folder.
		deferred
		end

	Pack_title: STRING_8
			-- The pack's title, as the window names it.
		deferred
		end

	Schema_version: INTEGER = 1
			-- The pack's `user_version': BIB_PRIVATE_SOURCE's `Pack_schema_version'.

	Pack_author: STRING_8 = "Larry Rix"
			-- The `meta' author of every private pack.

	pack_license: BIB_LICENSE
			-- The license of the pack's own text (2026-10-30, Larry: "I can share my own material.
			-- It's mine."): his own work, free to share. A kind built on another author's
			-- copyrighted work redefines it.
		do
			create Result.make (Author_license, False, False, False, Pack_author)
		end

	Author_license: STRING_8 = "the author's own work, free to share"
			-- `pack_license''s identifier for Larry's own writing.

	Search_table: STRING_8 = "writing_search"
			-- The pack's full-text table: one row per place a reader can open (research/20).

	Words_table: STRING_8 = "writing_words"
			-- `Search_table''s vocabulary, for fuzzy search.

	Search_statements: ARRAY [STRING_8]
			-- The search tables, made after the pack's own: the address a pane follows, where it
			-- stands, the text, its voice; diacritics folded ("zakar" finds "z%/257/kar").
		once
			Result := <<"CREATE VIRTUAL TABLE writing_search USING fts5(address UNINDEXED, place UNINDEXED, body, voice UNINDEXED, tokenize = 'unicode61 remove_diacritics 2')",
				"CREATE VIRTUAL TABLE writing_words USING fts5vocab(writing_search, row)">>
		end

	is_lowercase_id (a_id: READABLE_STRING_GENERAL): BOOLEAN
			-- Lowercase ASCII letters and digits, at least one: an id a link names.
		do
			Result := not a_id.is_empty and then across a_id.to_string_32 as al_c all (al_c >= 'a' and al_c <= 'z') or (al_c >= '0' and al_c <= '9') end
		end

	schema_statements: ARRAY [STRING_8]
			-- The statements making a new pack: `meta' and `source_provenance', the pack's own
			-- tables, the search tables, then its version.
		local
			i: INTEGER
		do
			create Result.make_filled ("", 1, pack_tables.count + Search_statements.count + 3)
			Result [1] := "CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)"
			Result [2] := "CREATE TABLE source_provenance(provenance_key INTEGER PRIMARY KEY, source_key TEXT NOT NULL, edition TEXT NOT NULL, license_id TEXT NOT NULL, non_commercial INTEGER NOT NULL, share_alike INTEGER NOT NULL, restricted INTEGER NOT NULL, credit TEXT NOT NULL, caveat TEXT NOT NULL)"
			i := 3
			across pack_tables as ic loop
				Result [i] := ic
				i := i + 1
			end
			across Search_statements as ic loop
				Result [i] := ic
				i := i + 1
			end
			Result [i] := "PRAGMA user_version = " + Schema_version.out
		ensure
			common_first: Result [1].starts_with ("CREATE TABLE meta(") and Result [2].starts_with ("CREATE TABLE source_provenance(")
			version_last: Result [Result.upper].starts_with ("PRAGMA user_version = ")
			every_table: Result.count = pack_tables.count + Search_statements.count + 3
		end

	pack_tables: ARRAY [STRING_8]
			-- The pack's own tables and indexes, in the order they are made.
		deferred
		end

end
