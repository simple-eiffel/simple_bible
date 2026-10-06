note
	description: "[
		core.db: texts, morphology, versification map, cross-references,
		glosses, quotations, shapes, provenance (required, read-only). Built by
		bible_build; never written at run time.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CORE_SOURCE

inherit
	BIB_DATA_SOURCE

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Describe core.db at `a_path'.
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
			Result := Core_schema_version
		end

	database_edition: STRING_32
			-- Build id of core.db (status bar; every BIB_METHOD).

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Open core.db as the main database of `a_set'.
		do
			-- Phase 4: a_set.open_core (path); read user_version, edition; check tables and provenance columns.
		ensure then
			edition_recorded: is_open implies not database_edition.is_empty
		end

	close
		do
			-- Phase 4
		end

feature -- Constants

	Core_schema_version: INTEGER = 1

end
