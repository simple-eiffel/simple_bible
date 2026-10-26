note
	description: "[
		One SQLite connection per processor (DR-019) with its attached packs (at
		most 10 pack slots, DR-020). Never passed between processors: each SCOOP
		processor that runs engine code owns its own SIMPLE_BIBLE and therefore
		its own source set. The shipped content.db is the main database; packs
		(generic private packs from the pack folder, and the concordance pack
		from `conc_path') attach read-only through
		SIMPLE_SQL_DATABASE.attach_read_only, and SQLite refuses any write into
		them (2026-10-26 spec fold: debates 01 and 03, settlement S1, debate 05a).

		Fleet dependency FT-02 has landed: eiffel_sqlite_2025 1.1.0 (SQLite
		3.53.4) declares its long externals `blocking', so a long query on a
		worker no longer stalls the other processors' collections (debate 04).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SOURCE_SET

inherit
	BIB_SQLITE_REPORTING

create
	make

feature {NONE} -- Initialization

	make
			-- Create a closed source set.
		do
			create attached_paths.make (Max_attached)
			create attach_serials.make (Max_attached)
			create core_path.make_empty
			create sqlite_version.make_empty
		ensure
			not_open: not is_open
			none_attached: attached_count = 0
			no_error: last_error = Void
		end

feature -- Status

	is_open: BOOLEAN
			-- Is content.db open on this processor?

	core_path: STRING_32
			-- Path of the main database (content.db).

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

	attached_path (a_alias: READABLE_STRING_8): detachable STRING_32
			-- Path attached as `a_alias', or Void when none (no SQL: the alias table).
		do
			Result := attached_paths.item (a_alias.to_string_8)
		ensure
			void_when_absent: (Result = Void) = not is_attached_alias (a_alias)
		end

	attachment_serial (a_alias: READABLE_STRING_8): INTEGER_64
			-- Which attach put the current database under `a_alias': unique for this source set's
			-- life and never reused, even when the same path is attached again; 0 when none.
			-- A reader that checked a pack compares this, so a rebuilt file is checked again
			-- (design scan 27). No SQL.
		do
			Result := attach_serials.item (a_alias.to_string_8)
		ensure
			zero_when_absent: (Result = 0) = not is_attached_alias (a_alias)
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
			-- Open `a_path' (the shipped content.db) read-only as the main database.
		require
			not_open: not is_open
			path_not_empty: not a_path.is_empty
		local
			l_db: SIMPLE_SQL_DATABASE
			l_result: SIMPLE_SQL_RESULT
		do
				-- No foreign-key pragma: main is read-only, so nothing here can write a row.
			last_error := Void
			if not (create {RAW_FILE}.make_with_name (a_path)).exists then
				create last_error.make_with_details ({BIB_ERROR}.Source_unavailable, "The content database was not found.", a_path)
			elseif attached read_only_connection (a_path) as al_db then
				l_db := al_db
					-- Reading sqlite_master makes a file that is not a database fail here, at open.
				l_result := l_db.query ("SELECT sqlite_version() AS v, (SELECT count(*) FROM sqlite_master) AS n")
				if not l_db.has_error and then not l_result.rows.is_empty and then attached l_result.rows.first as al_row then
					sqlite_version := al_row.string_value ("v")
					core_path := a_path.to_string_32
					database := l_db
					is_open := True
				else
					create last_error.make_with_details ({BIB_ERROR}.Database_problem, "The content database cannot be read.", sqlite_message (l_db, a_path))
					l_db.close
				end
			else
				create last_error.make_with_details ({BIB_ERROR}.Database_problem, "SQLite could not open the content database.", a_path)
			end
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
			last_error := Void
			if attached database as al_db then
				al_db.attach_read_only (a_path, a_alias)
				if al_db.has_error then
						-- SQLite's own words (FR-138, ruling 3.1), never "Unknown error".
					create last_error.make_with_details ({BIB_ERROR}.Source_unavailable, "A pack could not be attached as " + a_alias + ".", sqlite_message (al_db, a_path))
				else
					attached_paths.force (a_path.to_string_32, a_alias.twin)
					last_attach_serial := last_attach_serial + 1
					attach_serials.force (last_attach_serial, a_alias.twin)
				end
			end
		ensure
			attached_now: last_error = Void implies attached_model |=| old attached_model.updated (a_alias, a_path.to_string_32)
			count_grown: last_error = Void implies attached_count = old attached_count + 1
			unchanged_on_error: last_error /= Void implies attached_model |=| old attached_model
			error_mapped: (attached database as al_db and then al_db.has_error) implies last_error /= Void
		end

	detach (a_alias: STRING_8)
			-- Detach the database attached as `a_alias'.
		require
			open: is_open
			is_attached: attached_model.domain [a_alias]
		do
			last_error := Void
			if attached database as al_db then
				al_db.detach (a_alias)
				if al_db.has_error then
						-- SQLite refuses while a statement on the pack is still open (FR-159: close cursors).
					create last_error.make_with_details ({BIB_ERROR}.Database_problem, "A pack could not be detached: " + a_alias + ".", sqlite_message (al_db, a_alias))
				else
					attached_paths.remove (a_alias)
					attach_serials.remove (a_alias)
				end
			end
		ensure
			removed: last_error = Void implies attached_model |=| old attached_model.removed (a_alias)
			kept_on_error: last_error /= Void implies attached_model |=| old attached_model
		end

	close
			-- Close the connection and every attachment.
		require
			open: is_open
		do
			if attached database as al_db then
				al_db.close
			end
			database := Void
			attached_paths.wipe_out
			attach_serials.wipe_out
			is_open := False
			create core_path.make_empty
			create sqlite_version.make_empty
		ensure
			closed: not is_open
			none_attached: attached_count = 0
			no_connection: database = Void
			path_cleared: core_path.is_empty
			version_cleared: sqlite_version.is_empty
		end

feature -- Connection (engine-internal; faces never see a source set)

	database: detachable SIMPLE_SQL_DATABASE
			-- The one connection of this processor.

feature -- Constants

	Max_attached: INTEGER = 10
			-- SQLite attach limit (DR-020; attach #11 fails): pack slots only.

feature {NONE} -- Implementation

	read_only_connection (a_path: READABLE_STRING_GENERAL): detachable SIMPLE_SQL_DATABASE
			-- A read-only connection to `a_path', or Void when SQLite cannot open it (a folder,
			-- a file it may not read). simple_sql's `make_read_only' raises on an open failure,
			-- and an open that fails is an answer here, never control flow (design scan 26).
		require
			path_not_empty: not a_path.is_empty
			file_exists: (create {RAW_FILE}.make_with_name (a_path)).exists
		local
			l_failed: BOOLEAN
		do
			if not l_failed then
				create Result.make_read_only (a_path)
			end
		rescue
			l_failed := True
			retry
		end

feature {NONE} -- Representation

	attached_paths: HASH_TABLE [STRING_32, STRING_8]
			-- Path by alias.

	attach_serials: HASH_TABLE [INTEGER_64, STRING_8]
			-- `attachment_serial' by alias.

	last_attach_serial: INTEGER_64
			-- The serial of the latest successful attach; never reset, not even by `close'.

invariant
	within_limit: attached_count >= 0 and attached_count <= Max_attached
	serials_match_aliases: attach_serials.count = attached_paths.count
	nothing_attached_when_closed: not is_open implies attached_count = 0
	connection_when_open: is_open implies database /= Void

end
