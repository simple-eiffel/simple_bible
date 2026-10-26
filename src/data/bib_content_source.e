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
			-- AI-made related-passage rows (0 when the AI stage shipped empty).
		require
			open: is_open
		do
			-- Phase 4: count of related-passage rows with `is_ai_made'.
		ensure
			non_negative: Result >= 0
		end

	author_document_count: INTEGER_64
			-- Author-library documents (0 when the rix stage shipped empty).
		require
			open: is_open
		do
			-- Phase 4: count of the author library's documents.
		ensure
			non_negative: Result >= 0
		end

feature -- Status

	has_vector_tables: BOOLEAN
			-- Does the file carry embedding vectors? (Never in Release 1.)
		do
			-- Phase 4
		end

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Open content.db as the main database of `a_set'.
		do
			-- Phase 4: a_set.open_core (path); read user_version and the edition; check
			-- the tables and their provenance columns.
		ensure then
			edition_recorded: is_open implies not database_edition.is_empty
			no_vectors_in_release_1: is_open implies not has_vector_tables
		end

	close
		do
			-- Phase 4
		end

feature -- Constants

	Content_schema_version: INTEGER = 1

end
