note
	description: "[
		The one shipped content.db, read-only: assembled at build time from the
		stages core (texts, morphology, versification map, cross-references,
		glosses, quotations, shapes, provenance), AI data (related passages, each
		row labeled `is_ai_made' with a method and a model id) and rix (the
		author library). Optional public content ships as empty tables, never as
		missing files, so presence is a row count. No vector table ships in
		Release 1 (Q-06). Built by bible_build; never written at run time.
		(2026-10-26 spec fold, debate 01 pathway B-S: replaces BIB_CORE_SOURCE
		and BIB_AI_DATA_SOURCE.)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONTENT_SOURCE

inherit
	BIB_DATA_SOURCE

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Describe content.db at `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			path := a_path.to_string_32
			create sqlite_version.make_empty
			create database_edition.make_empty
		ensure
			path_set: path.same_string_general (a_path)
			closed: not is_open
		end

feature -- Access

	alias_name: STRING_8
		do
			Result := "main"
		end

	expected_schema_version: INTEGER
		do
			Result := Content_schema_version
		end

	database_edition: STRING_32
			-- Build id of content.db (status bar; every BIB_METHOD).

	ai_row_count: INTEGER_64
			-- AI-made related-passage rows (0 when the AI stage shipped empty or the table is
			-- absent, research/18). Counted once by `open_on'.
		require
			open: is_open
		do
			Result := ai_rows
		ensure
			non_negative: Result >= 0
		end

	author_document_count: INTEGER_64
			-- Author-library documents (0 when the rix stage shipped empty or `docs' is absent).
			-- Counted once by `open_on'.
		require
			open: is_open
		do
			Result := author_documents
		ensure
			non_negative: Result >= 0
		end

feature -- Status

	has_vector_tables: BOOLEAN
			-- Does the file carry embedding vectors (a table whose name holds "vector")? Never in
			-- Release 1 (Q-06). Recorded by `open_on'.

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Open content.db as the main database of `a_set' and check it (research/18): version,
			-- required tables, provenance columns, build edition, no vectors. A refused file
			-- leaves `a_set' closed.
		local
			l_schema: SIMPLE_SQL_SCHEMA
		do
			last_error := Void
			has_required_tables := False
			a_set.open_core (path)
			if attached a_set.last_error as al_error then
				last_error := al_error
			elseif attached a_set.database as al_db then
				create l_schema.make (al_db)
				sqlite_version := a_set.sqlite_version.twin
				schema_version := l_schema.user_version
				if schema_version /= Content_schema_version then
					create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "content.db is version " + schema_version.out + "; this engine reads version " + Content_schema_version.out + ".", path)
				elseif attached first_missing_table (l_schema) as al_missing then
					create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "content.db has no table " + al_missing + ".", path)
				else
					has_required_tables := True
					tables_without_provenance_column := tables_lacking_provenance (l_schema)
					if tables_without_provenance_column > 0 then
						create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "content.db has " + tables_without_provenance_column.out + " content tables without a provenance_key column bound to source_provenance.", path)
					else
						read_build_facts (al_db, l_schema)
						if database_edition.is_empty then
							create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "content.db names no build (build_run).", path)
						elseif has_vector_tables then
							create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "content.db carries vector tables, which Release 1 does not read.", path)
						else
							is_open := True
						end
					end
				end
				if last_error /= Void then
					has_required_tables := False
					a_set.close
				end
			end
		ensure then
			edition_recorded: is_open implies not database_edition.is_empty
			no_vectors_in_release_1: is_open implies not has_vector_tables
		end

	close
			-- Mark closed; the source set's owner closes the connection.
		do
			is_open := False
		end

feature -- Constants

	Content_schema_version: INTEGER = 2

	Required_tables: ARRAY [STRING_8]
			-- content.db v1's tables (research/18); the pipeline adds to them as engines read more.
		once
			Result := <<"source_provenance", "build_run", "book_catalog", "version_info", "verse_text">>
		end

	Provenance_exempt: ARRAY [STRING_8]
			-- Tables that describe the file, not content (K7-A).
		once
			Result := <<"source_provenance", "build_run", "table_checksum">>
		end

feature {NONE} -- Implementation

	ai_rows: INTEGER_64
			-- `ai_row_count', counted at open.

	author_documents: INTEGER_64
			-- `author_document_count', counted at open.

	first_missing_table (a_schema: SIMPLE_SQL_SCHEMA): detachable STRING_8
			-- The first of `Required_tables' content.db lacks.
		do
			across Required_tables as ic until Result /= Void loop
				if not a_schema.table_exists (ic) then
					Result := ic
				end
			end
		end

	tables_lacking_provenance (a_schema: SIMPLE_SQL_SCHEMA): INTEGER
			-- Content tables without `provenance_key NOT NULL' bound to `source_provenance' (K7-A);
			-- FTS5 virtual tables, their shadow tables and `Provenance_exempt' do not count.
		local
			l_tables, l_virtual: ARRAYED_LIST [STRING_8]
		do
			l_tables := a_schema.tables
			create l_virtual.make (2)
			across l_tables as ic loop
				if attached a_schema.table_info (ic) as al_info and then attached al_info.sql as al_sql and then al_sql.as_upper.has_substring ("CREATE VIRTUAL TABLE") then
					l_virtual.extend (ic)
				end
			end
			across l_tables as ic loop
				if not is_exempt (ic, l_virtual) and then not declares_provenance (a_schema, ic) then
					Result := Result + 1
				end
			end
		ensure
			non_negative: Result >= 0
		end

	is_exempt (a_table: STRING_8; a_virtual: ARRAYED_LIST [STRING_8]): BOOLEAN
			-- Is `a_table' outside the provenance rule: a file table, an FTS5 table or one of its shadows?
		do
			Result := across Provenance_exempt as ic some a_table.same_string (ic) end
				or else across a_virtual as ic some a_table.same_string (ic)
					or else across <<"_data", "_idx", "_content", "_docsize", "_config">> as s some a_table.same_string (ic + s) end end
		end

	declares_provenance (a_schema: SIMPLE_SQL_SCHEMA; a_table: STRING_8): BOOLEAN
			-- Does `a_table' have `provenance_key NOT NULL' with a foreign key to `source_provenance'?
		do
			if attached a_schema.table_info (a_table) as al_info and then attached al_info.column ("provenance_key") as al_column and then al_column.is_not_null then
				Result := across al_info.foreign_keys as ic some
						ic.to_table.is_case_insensitive_equal ("source_provenance")
						and across ic.column_mappings as m some m.from_column.same_string ("provenance_key") end
					end
			end
		end

	read_build_facts (a_db: SIMPLE_SQL_DATABASE; a_schema: SIMPLE_SQL_SCHEMA)
			-- Read the edition (the latest build) and count the optional content, once.
		do
			create database_edition.make_empty
			across a_db.query ("SELECT build_id FROM build_run ORDER BY built_at DESC, build_id DESC LIMIT 1").rows as ic loop
				database_edition := ic.string_value ("build_id")
			end
			ai_rows := 0
			if a_schema.table_exists ("related_passage") then
				across a_db.query ("SELECT count(*) AS n FROM related_passage WHERE is_ai_made = 1").rows as ic loop
					ai_rows := ic.integer_64_value ("n").max (0)
				end
			end
			author_documents := 0
			if a_schema.table_exists ("docs") then
				across a_db.query ("SELECT count(*) AS n FROM docs").rows as ic loop
					author_documents := ic.integer_64_value ("n").max (0)
				end
			end
			has_vector_tables := across a_schema.tables as ic some ic.as_lower.has_substring ("vector") end
		end

invariant
	counts_non_negative: ai_rows >= 0 and author_documents >= 0

end
