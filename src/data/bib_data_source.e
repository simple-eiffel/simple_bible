note
	description: "[
		One database's identity, schema check and provenance access. Every source
		except the user store is read-only. Opening checks the schema version,
		the required tables, and (RQ-02) that every shipped table declares its
		`provenance_key INTEGER NOT NULL REFERENCES source_provenance' column, so
		a row without a source cannot be read.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_DATA_SOURCE

feature -- Access

	alias_name: STRING_8
			-- Attach alias ("main" for core.db).
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	path: STRING_32
			-- File path.

	schema_version: INTEGER
			-- `PRAGMA user_version' read at open.

	expected_schema_version: INTEGER
			-- Schema version this engine reads.
		deferred
		ensure
			positive: Result > 0
		end

	sqlite_version: STRING_32
			-- SQLite version at open.

	last_error: detachable BIB_ERROR
			-- Why the last open failed.

	provenance (a_key: INTEGER_64): BIB_PROVENANCE
			-- The `source_provenance' row `a_key'.
		require
			open: is_open
			known: has_provenance (a_key)
		do
			check implemented_in_phase_4: False then end
		ensure
			key_kept: Result.key = a_key
		end

feature -- Status

	is_open: BOOLEAN
			-- Is the database open (or attached) on this processor?

	is_read_only: BOOLEAN
			-- True for every source except the user store.
		do
			Result := True
		end

	is_available: BOOLEAN
			-- Is the file present?
		do
			-- Phase 4: simple_file existence check.
		end

	has_required_tables: BOOLEAN
			-- Are the tables this engine reads present?
		do
			-- Phase 4: sqlite_master.
		end

	tables_without_provenance_column: INTEGER
			-- Shipped tables lacking `provenance_key NOT NULL REFERENCES source_provenance' (RQ-02).
		do
			-- Phase 4: PRAGMA table_info / foreign_key_list over the shipped tables.
		ensure
			non_negative: Result >= 0
		end

	is_provenance_schema_valid: BOOLEAN
			-- Does every shipped table declare its provenance column?
		do
			Result := tables_without_provenance_column = 0
		end

	has_provenance (a_key: INTEGER_64): BOOLEAN
			-- Is `a_key' a row of `source_provenance'?
		do
			-- Phase 4
		end

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Open (main) or attach (others) this source on `a_set'.
		require
			set_open: a_set.is_open or alias_name.same_string ("main")
			file_present: is_available
			not_open: not is_open
		deferred
		ensure
			open_or_error: is_open xor (last_error /= Void)
			schema_checked: is_open implies schema_version = expected_schema_version
			tables_present: is_open implies has_required_tables
			provenance_declared: is_open implies is_provenance_schema_valid
			version_recorded: is_open implies not sqlite_version.is_empty
		end

	close
			-- Close or detach.
		require
			open: is_open
		deferred
		ensure
			closed: not is_open
		end

invariant
	open_implies_schema: is_open implies schema_version = expected_schema_version
	error_only_when_closed: last_error /= Void implies not is_open

end
