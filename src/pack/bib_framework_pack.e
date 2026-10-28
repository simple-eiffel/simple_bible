note
	description: "[
		A frameworks pack, read (BIB_FRAMEWORK_SCHEMA): every framework in the tool's
		order (tier, then name), one framework whole (its sections, related
		frameworks and the commentary sections that use it), and the spellings that
		link to each, for BIB_FRAMEWORK_LINKER. The pack is attached read-only under
		`pack_alias' by BIB_PRIVATE_SOURCE, which checked its version, voice and
		provenance columns; this reader only asks it questions. T4's Frameworks tab
		and every framework hover card are built on it (2026-10-28).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FRAMEWORK_PACK

inherit
	BIB_PRIVATE_PACK_READER

create
	make

feature -- Access

	frameworks: BIB_LIST_RESULT [BIB_FRAMEWORK]
			-- Every framework, without its sections: cornerstone, master, recovery, then sub, each
			-- tier by name.
		require
			available: is_available
		local
			l_sql: STRING_8
			l_list: ARRAYED_LIST [BIB_FRAMEWORK]
			l_provenance: BIB_PROVENANCE
		do
			l_provenance := pack_provenance
			l_sql := "SELECT framework_id, name, mark, title, tier, status, hover FROM " + pack_alias + ".framework ORDER BY tier_rank, name"
			run_query (l_sql, {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				create l_list.make (al_rows.rows.count)
				across al_rows.rows as ic loop
					if attached framework_of_row (ic) as al_framework then
						l_list.extend (al_framework)
					end
				end
				create Result.make_success (method ("frameworks", l_sql, pack_alias, "all", l_list.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_list)
			else
				create Result.make_failure (method ("frameworks", l_sql, pack_alias, "all", 0), query_error)
			end
		ensure
			ordered_by_tier: Result.is_success implies across 2 |..| Result.count as al_i all
				(create {BIB_FRAMEWORK_SCHEMA}).tier_rank (Result.item (al_i - 1).tier) <= (create {BIB_FRAMEWORK_SCHEMA}).tier_rank (Result.item (al_i).tier) end
		end

	framework (a_id: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_FRAMEWORK]
			-- Framework `a_id' whole - its sections, related frameworks and commentary uses - or no
			-- item when the pack has none by that id.
		require
			available: is_available
		local
			l_sql: STRING_8
			l_list: ARRAYED_LIST [BIB_FRAMEWORK]
			l_ok: BOOLEAN
			l_provenance: BIB_PROVENANCE
		do
			l_provenance := pack_provenance
			l_sql := "SELECT framework_id, name, mark, title, tier, status, hover FROM " + pack_alias + ".framework WHERE framework_id = ?"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_id.to_string_32>>)
			if attached last_rows as al_rows then
				create l_list.make (1)
				l_ok := True
				across al_rows.rows as ic loop
					if attached framework_of_row (ic) as al_framework then
						l_ok := l_ok and fill (al_framework)
						l_list.extend (al_framework)
					end
				end
				if l_ok then
					create Result.make_success (method ("framework", l_sql, pack_alias, a_id, l_list.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_list)
				else
					create Result.make_failure (method ("framework", l_sql, pack_alias, a_id, 0), query_error)
				end
			else
				create Result.make_failure (method ("framework", l_sql, pack_alias, a_id, 0), query_error)
			end
		ensure
			at_most_one: Result.count <= 1
			that_one: Result.count = 1 implies Result.item (1).id.same_string_general (a_id)
		end

	aliases: BIB_LIST_RESULT [BIB_FRAMEWORK_SPELLING]
			-- Every spelling that links to a framework, the longest first (so "the JESUS Cornerstone"
			-- is tried before "JESUS"); `needs_mark': it links only followed by (TM).
		require
			available: is_available
		local
			l_sql: STRING_8
			l_list: ARRAYED_LIST [BIB_FRAMEWORK_SPELLING]
			l_provenance: BIB_PROVENANCE
		do
			l_provenance := pack_provenance
			l_sql := "SELECT alias, framework_id, needs_mark FROM " + pack_alias + ".framework_alias ORDER BY length(alias) DESC, alias"
			run_query (l_sql, {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				create l_list.make (al_rows.rows.count)
				across al_rows.rows as ic loop
					if not ic.string_value ("alias").is_empty and then (create {BIB_FRAMEWORK_SCHEMA}).is_framework_id (ic.string_value ("framework_id")) then
						l_list.extend (create {BIB_FRAMEWORK_SPELLING}.make (ic.string_value ("alias"), ic.string_value ("framework_id"), ic.integer_value ("needs_mark") /= 0, l_provenance))
					end
				end
				create Result.make_success (method ("aliases", l_sql, pack_alias, "all", l_list.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_list)
			else
				create Result.make_failure (method ("aliases", l_sql, pack_alias, "all", 0), query_error)
			end
		ensure
			longest_first: Result.is_success implies across 2 |..| Result.count as al_i all Result.item (al_i - 1).spelling.count >= Result.item (al_i).spelling.count end
		end

feature {NONE} -- Implementation

	framework_of_row (a_row: SIMPLE_SQL_ROW): detachable BIB_FRAMEWORK
			-- The framework a row names; Void when the row breaks BIB_FRAMEWORK's preconditions.
		local
			l_schema: BIB_FRAMEWORK_SCHEMA
		do
			create l_schema
			if l_schema.is_framework_id (a_row.string_value ("framework_id")) and then not a_row.string_value ("name").is_empty
				and then l_schema.is_status (a_row.string_value ("status"))
			then
				create Result.make (a_row.string_value ("framework_id"), a_row.string_value ("name"), a_row.integer_value ("mark") /= 0,
					a_row.string_value ("title"), a_row.string_value ("tier"), a_row.string_value ("status"), a_row.string_value ("hover"), pack_provenance)
			end
		end

	fill (a_framework: BIB_FRAMEWORK): BOOLEAN
			-- Read `a_framework''s sections, related frameworks and uses; False when a query failed
			-- (`query_error' says why).
		local
			l_id: STRING_32
		do
			Result := True
			l_id := a_framework.id
			run_query ("SELECT heading, body_markdown FROM " + pack_alias + ".framework_section WHERE framework_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_framework.sections.extend ([ic.string_value ("heading"), ic.string_value ("body_markdown")])
				end
			end
			run_query ("SELECT related_id FROM " + pack_alias + ".framework_related WHERE framework_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_framework.related.extend (ic.string_value ("related_id"))
				end
			end
			run_query ("SELECT section_id, heading, start_book, start_chapter, start_verse, end_chapter, end_verse FROM " + pack_alias + ".framework_use WHERE framework_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_framework.uses.extend ([ic.string_value ("section_id"), ic.string_value ("heading"), ic.integer_value ("start_book"),
						ic.integer_value ("start_chapter"), ic.integer_value ("start_verse"), ic.integer_value ("end_chapter"), ic.integer_value ("end_verse")])
				end
			end
		end

	query_failed_message: STRING_8 = "A frameworks query failed."
	not_open_message: STRING_8 = "The frameworks pack is not attached."

	pack_noun: STRING_32
		once
			Result := {STRING_32} "frameworks pack"
		end

end
