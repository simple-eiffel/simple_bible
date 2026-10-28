note
	description: "[
		A generic private data pack (2026-10-26 spec fold, debate 03 pathway B'):
		a versioned SQLite file in the public pack schema, found by the pack-folder
		scan and attached read-only through SIMPLE_SQL_DATABASE.attach_read_only.
		At attach its `user_version' and its NOT NULL voice column are checked, so
		a private result is never unlabeled. No private code: the public engine
		reads every pack with the same generic primitives. conc.db is not one: it
		is a concordance pack, opened by BIB_CONC_PACK's own check (settlement S6).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PRIVATE_SOURCE

inherit
	BIB_DATA_SOURCE

	BIB_SQLITE_REPORTING

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL; a_alias: READABLE_STRING_8; a_voice: BIB_VOICE)
			-- Describe the pack at `a_path', attached as `a_alias', its results labeled `a_voice'.
		require
			path_not_empty: not a_path.is_empty
			alias_not_empty: not a_alias.is_empty
			not_main: not a_alias.same_string ("main")
			not_concordance: not a_alias.same_string ({BIB_CONC_PACK}.Pack_alias)
		do
			path := a_path.to_string_32
			alias_text := a_alias.to_string_8
			voice := a_voice
			create sqlite_version.make_empty
			create pack_kind.make_empty
			create pack_title.make_empty
		ensure
			path_set: path.same_string_general (a_path)
			alias_set: alias_name.same_string (a_alias)
			voice_set: voice = a_voice
			closed: not is_open
		end

feature -- Access

	alias_name: STRING_8
		do
			Result := alias_text
		end

	voice: BIB_VOICE
			-- How results from this pack are labeled.

	pack_kind: STRING_8
			-- `meta.pack_kind' as read at attach ("commentary"); empty before.

	pack_title: STRING_32
			-- `meta.title' as read at attach; empty when the pack names none.

	expected_schema_version: INTEGER
		do
			Result := Pack_schema_version
		end

feature -- Status

	pack_voice_column_present: BOOLEAN
			-- Does every pack table (but `meta' and `source_provenance') carry its NOT NULL voice
			-- column? Recorded by `open_on'.

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Attach this pack to `a_set', read-only, and check the pack rules (2026-10-27, Task 7b's
			-- first customer, the commentary pack): `user_version' `Pack_schema_version'; `meta' and
			-- `source_provenance' present; every other table carries NOT NULL `voice' and
			-- `provenance_key'. A pack that breaks a rule is detached again and `last_error' says which.
		local
			l_tables: ARRAYED_LIST [STRING_8]
			l_name, l_sql: STRING_8
			l_voiced, l_sourced, l_searchable, l_search_voiced: BOOLEAN
		do
			last_error := Void
			has_required_tables := False
			pack_voice_column_present := False
			tables_without_provenance_column := 0
			a_set.attach (alias_name, path)
			if attached a_set.last_error as al_error then
				last_error := al_error
			elseif attached a_set.database as al_db then
				schema_version := first_integer (al_db.query ("PRAGMA " + alias_name + ".user_version"))
				create l_tables.make (8)
					-- The search table (FTS5), its vocabulary (fts5vocab) and FTS5's shadow tables of the
					-- search table hold no row a result shows by itself: the rule is not theirs
					-- (research/20). Scan 61: only those, by name and module; any other virtual table
					-- answers to the rule like a table, and the search table must carry `voice'.
				across al_db.query ("SELECT name, sql FROM " + alias_name + ".sqlite_master WHERE type = 'table'").rows as ic loop
					l_name := ic.string_value ("name").to_string_8
					l_sql := ic.string_value ("sql").to_string_8.as_lower
					if l_name.same_string ({BIB_BOOK_SCHEMA}.Search_table) and then l_sql.starts_with ("create virtual table") and then l_sql.has_substring ("using fts5(") then
						l_searchable := True
						across al_db.query ("PRAGMA " + alias_name + ".table_info(" + l_name + ")").rows as ic_column loop
							if ic_column.string_value ("name").same_string ("voice") then
								l_search_voiced := True
							end
						end
					elseif not (l_name.same_string ({BIB_BOOK_SCHEMA}.Words_table) and then l_sql.starts_with ("create virtual table")
						and then l_sql.has_substring ("using fts5vocab(" + {BIB_BOOK_SCHEMA}.Search_table + ","))
					then
						l_tables.extend (l_name)
					end
				end
				l_tables.compare_objects
				if l_searchable then
					across Shadow_suffixes as ic_suffix loop
						l_tables.prune_all ({BIB_BOOK_SCHEMA}.Search_table + ic_suffix)
					end
				end
				has_required_tables := l_tables.has ("meta") and l_tables.has ("source_provenance")
				pack_voice_column_present := True
				across l_tables as ic loop
					if not ic.same_string ("meta") and not ic.same_string ("source_provenance") then
						l_voiced := False
						l_sourced := False
						across al_db.query ("PRAGMA " + alias_name + ".table_info(" + ic + ")").rows as ic_column loop
							if ic_column.integer_value ("notnull") = 1 then
								if ic_column.string_value ("name").same_string ("voice") then
									l_voiced := True
								elseif ic_column.string_value ("name").same_string ("provenance_key") then
									l_sourced := True
								end
							end
						end
						if not l_voiced then
							pack_voice_column_present := False
						end
						if not l_sourced then
							tables_without_provenance_column := tables_without_provenance_column + 1
						end
					end
				end
				if l_searchable and not l_search_voiced then
					pack_voice_column_present := False
				end
				if schema_version /= expected_schema_version then
					create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "The pack's version is " + schema_version.out + "; this program reads version " + expected_schema_version.out + ".", path)
				elseif not has_required_tables then
					create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "The pack has no meta or source_provenance table.", path)
				elseif not pack_voice_column_present then
					create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "A table of the pack has no NOT NULL voice column: its results could not be labelled.", path)
				elseif tables_without_provenance_column > 0 then
					create last_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "A table of the pack has no NOT NULL provenance_key.", path)
				else
					pack_kind := meta_value (al_db, "pack_kind").to_string_8
					pack_title := meta_value (al_db, "title")
					sqlite_version := a_set.sqlite_version.twin
					if sqlite_version.is_empty then
						sqlite_version := {STRING_32} "unknown"
					end
					attached_set := a_set
					is_open := True
				end
				if last_error /= Void then
					a_set.detach (alias_name)
				end
			end
		ensure then
			voice_column_checked: is_open implies pack_voice_column_present
			user_version_checked: is_open implies schema_version = expected_schema_version
		end

	close
			-- Detach the pack.
		do
			if attached attached_set as al_set and then al_set.is_open and then al_set.is_attached_alias (alias_name) then
				al_set.detach (alias_name)
			end
			attached_set := Void
			is_open := False
		end

	forget
			-- The connection was closed under this pack (the whole source set closed): it is no
			-- longer open.
		do
			attached_set := Void
			is_open := False
		ensure
			closed: not is_open
		end

feature -- Constants

	Shadow_suffixes: ARRAY [STRING_8]
			-- The tables FTS5 keeps for a virtual table, after its name.
		once
			Result := <<"_data", "_idx", "_content", "_docsize", "_config">>
		end

	Pack_schema_version: INTEGER = 1

feature {NONE} -- Implementation

	alias_text: STRING_8

	attached_set: detachable BIB_SOURCE_SET
			-- Where the pack is attached while open.

	meta_value (a_db: SIMPLE_SQL_DATABASE; a_key: STRING_8): STRING_32
			-- `meta' row `a_key' of the pack; empty when absent.
		local
			l_result: SIMPLE_SQL_RESULT
		do
			create Result.make_empty
			l_result := a_db.query_with_args ("SELECT value FROM " + alias_name + ".meta WHERE key = ?", <<a_key>>)
			if not l_result.rows.is_empty then
				Result := l_result.rows.first.string_value ("value")
			end
		end

invariant
	not_main: not alias_text.same_string ("main")
	not_concordance: not alias_text.same_string ({BIB_CONC_PACK}.Pack_alias)

end
