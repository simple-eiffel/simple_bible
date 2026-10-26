note
	description: "[
		One query on the open connection, told the engine's way: the rows, or
		SQLite's own words as a BIB_ERROR, and the method record each answer
		carries (NFR-006). Shared by the readers of content.db and the
		concordance pack (design scan 33: BIB_TEXT_READER had copied
		BIB_CONC_PACK's helpers line for line). Inherit it beside the class's
		real parent; the heir names its connection, its two messages and the
		edition its method records cite.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_SQLITE_QUERYING

inherit
	BIB_SQLITE_REPORTING

feature {NONE} -- The heir's part

	sources: BIB_SOURCE_SET
			-- The connection queries run on.
		deferred
		end

	query_failed_message: STRING_8
			-- What a failed query says before SQLite's own words ("A concordance query failed.").
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	not_open_message: STRING_8
			-- What a query says when there is no connection.
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	method_edition: STRING_32
			-- The edition the method records cite.
		deferred
		ensure
			not_empty: not Result.is_empty
		end

	method_versions (a_corpus_code: READABLE_STRING_8): ARRAYED_LIST [STRING_32]
			-- The versions a method record names for `a_corpus_code'; none unless the heir says.
		do
			create Result.make (0)
		end

feature {NONE} -- Querying

	last_rows: detachable SIMPLE_SQL_RESULT
			-- Rows of the latest `run_query'; Void when it failed.

	last_query_error: detachable BIB_ERROR
			-- Why the latest `run_query' failed.

	run_query (a_sql: STRING_8; a_args: ARRAY [detachable ANY])
			-- Run `a_sql' with `a_args' on the connection: the rows go to `last_rows', a refusal to
			-- `last_query_error' with SQLite's own words.
		require
			sql_not_empty: not a_sql.is_empty
		do
			last_rows := Void
			last_query_error := Void
			if attached sources.database as al_db then
				last_rows := al_db.query_with_args (a_sql, a_args)
				if al_db.has_error then
					last_rows := Void
					create last_query_error.make_with_details ({BIB_ERROR}.Database_problem, query_failed_message, sqlite_message (al_db, a_sql))
				end
			else
				create last_query_error.make ({BIB_ERROR}.Source_unavailable, not_open_message)
			end
		ensure
			rows_xor_error: (last_rows /= Void) xor (last_query_error /= Void)
		end

	query_error: BIB_ERROR
			-- `last_query_error', or a general one when there is none.
		do
			if attached last_query_error as al_error then
				Result := al_error
			else
				create Result.make ({BIB_ERROR}.Database_problem, query_failed_message)
			end
		end

	method (a_feature, a_sql: STRING_8; a_corpus_code: READABLE_STRING_8; a_scope: READABLE_STRING_GENERAL; a_count: INTEGER_64): BIB_METHOD
			-- The method record of one query (NFR-006): its SQL, scope, versions and count.
		require
			scope_not_empty: not a_scope.is_empty
		do
			create Result.make (a_feature, a_sql, a_corpus_code, a_scope, method_versions (a_corpus_code), create {ARRAYED_LIST [STRING_32]}.make (0),
				{ARRAY [INTEGER_64]} <<a_count>>, {BIB_RELEASE}.Engine_version, method_edition, sqlite_version_or_unknown)
		ensure
			named: Result.engine_feature.same_string_general (a_feature)
		end

	sqlite_version_or_unknown: STRING_32
			-- SQLite's version for the method record.
		do
			if sources.sqlite_version.is_empty then
				Result := {STRING_32} "unknown"
			else
				Result := sources.sqlite_version
			end
		ensure
			not_empty: not Result.is_empty
		end

end
