note
	description: "[
		One SQLite connection per processor (DR-019) with its attached databases
		(at most 10, DR-020). Never passed between processors: each SCOOP
		processor that runs engine code owns its own SIMPLE_BIBLE and therefore
		its own source set. core.db is the main database; ai_data.db, rix.db and
		private sources are attached read-only.

		Fleet dependency FT-02: eiffel_sqlite_2025's `c_sqlite3_step',
		`c_sqlite3_open_v2' and `c_sqlite3_close' are not yet declared
		`blocking'; until they are, a long query on a worker stalls every other
		processor at its next allocation during a collection. Not patched here.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SOURCE_SET

create
	make

feature {NONE} -- Initialization

	make
			-- Create a closed source set.
		do
			create attached_paths.make (Max_attached)
			create core_path.make_empty
			create sqlite_version.make_empty
		ensure
			not_open: not is_open
			none_attached: attached_count = 0
			no_error: last_error = Void
		end

feature -- Status

	is_open: BOOLEAN
			-- Is core.db open on this processor?

	core_path: STRING_32
			-- Path of the main database (core.db).

	attached_count: INTEGER
			-- Number of attached databases.
		do
			Result := attached_paths.count
		ensure
			model_agrees: Result = attached_model.count
		end

	sqlite_version: STRING_32
			-- Version reported by the SQLite library at open (FR-NEW-008).

	last_error: detachable BIB_ERROR
			-- Why the last command failed.

	is_valid_alias (a_alias: READABLE_STRING_8): BOOLEAN
			-- Is `a_alias' a lowercase identifier other than "main" and "temp"?
		do
			Result := not a_alias.is_empty and then a_alias [1].is_lower
				and then across a_alias as c all c.is_lower or c.is_digit or c = '_' end
				and then not a_alias.same_string ("main") and then not a_alias.same_string ("temp")
		end

	is_attached_alias (a_alias: READABLE_STRING_8): BOOLEAN
			-- Is a database attached as `a_alias'?
		do
			Result := attached_paths.has (a_alias.to_string_8)
		ensure
			model_agrees: Result = attached_model.domain [a_alias.to_string_8]
		end

feature -- Model

	attached_model: MML_MAP [STRING_8, STRING_32]
			-- Alias to path of every attached database.
		do
			create Result
			across attached_paths as p loop
				Result := Result.updated (@p.key, p)
			end
		end

feature -- Commands

	open_core (a_path: READABLE_STRING_GENERAL)
			-- Open `a_path' (core.db) read-only as the main database.
		require
			not_open: not is_open
			path_not_empty: not a_path.is_empty
		do
			-- Phase 4: SIMPLE_SQL_DATABASE.make_read_only; record sqlite_version; foreign keys on.
		ensure
			open_or_error: is_open xor (last_error /= Void)
			path_recorded: is_open implies core_path.same_string_general (a_path)
			version_recorded: is_open implies not sqlite_version.is_empty
			none_attached: attached_count = 0
		end

	attach (a_alias: STRING_8; a_path: READABLE_STRING_GENERAL)
			-- Attach `a_path' read-only as `a_alias'.
		require
			open: is_open
			alias_valid: is_valid_alias (a_alias)
			not_attached: not attached_model.domain [a_alias]
			under_limit: attached_count < Max_attached
			path_not_empty: not a_path.is_empty
		do
			-- Phase 4: ATTACH DATABASE 'file:...?mode=ro' AS <alias>.
		ensure
			attached_now: last_error = Void implies attached_model |=| old attached_model.updated (a_alias, a_path.to_string_32)
			count_grown: last_error = Void implies attached_count = old attached_count + 1
			unchanged_on_error: last_error /= Void implies attached_model |=| old attached_model
		end

	detach (a_alias: STRING_8)
			-- Detach the database attached as `a_alias'.
		require
			open: is_open
			is_attached: attached_model.domain [a_alias]
		do
			-- Phase 4: DETACH DATABASE.
		ensure
			removed: attached_model |=| old attached_model.removed (a_alias)
		end

	close
			-- Close the connection and every attachment.
		require
			open: is_open
		do
			-- Phase 4
		ensure
			closed: not is_open
			none_attached: attached_count = 0
		end

feature -- Connection (engine-internal; faces never see a source set)

	database: detachable SIMPLE_SQL_DATABASE
			-- The one connection of this processor.

feature -- Constants

	Max_attached: INTEGER = 10
			-- SQLite attach limit (DR-020; attach #11 fails).

feature {NONE} -- Representation

	attached_paths: HASH_TABLE [STRING_32, STRING_8]
			-- Path by alias.

invariant
	within_limit: attached_count >= 0 and attached_count <= Max_attached
	nothing_attached_when_closed: not is_open implies attached_count = 0
	connection_when_open: is_open implies database /= Void

end
