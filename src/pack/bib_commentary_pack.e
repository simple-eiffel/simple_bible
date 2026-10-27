note
	description: "[
		A commentary pack, read (BIB_COMMENTARY_SCHEMA): the sections whose verses
		cover a verse, the narrowest first (Jude 5-7 before the introduction on
		the whole letter), each with its fields, tagged claims, terms, lists and
		restricted quotations. The pack is attached read-only under `pack_alias'
		by BIB_PRIVATE_SOURCE, which checked its version, voice and provenance
		columns; this reader only asks it questions. S2/T5's Commentaries tab is
		built on it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COMMENTARY_PACK

inherit
	BIB_SQLITE_QUERYING

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_alias: READABLE_STRING_8; a_title: READABLE_STRING_GENERAL)
			-- The commentary pack attached as `a_alias' on `a_sources', titled `a_title'.
		require
			alias_not_empty: not a_alias.is_empty
		do
			sources := a_sources
			pack_alias := a_alias.to_string_8
			title := a_title.to_string_32
		ensure
			alias_set: pack_alias.same_string (a_alias)
		end

feature -- Access

	pack_alias: STRING_8
	title: STRING_32
			-- The pack's `meta.title' ("Jude: A Commentary").

	is_available: BOOLEAN
			-- Is the pack attached?
		do
			Result := sources.is_open and then sources.is_attached_alias (pack_alias)
		end

	sections_for_verse (a_book, a_chapter, a_verse: INTEGER): BIB_LIST_RESULT [BIB_COMMENTARY_SECTION]
			-- The sections covering `a_book' `a_chapter':`a_verse' (English numbering), the narrowest
			-- first; empty when the pack says nothing on it.
		require
			available: is_available
			book_valid: a_book >= 1 and a_book <= {BIB_HUB_ID}.Max_part
			chapter_valid: a_chapter >= 1 and a_chapter <= {BIB_HUB_ID}.Max_part
			verse_valid: a_verse >= 1 and a_verse <= {BIB_HUB_ID}.Max_part
		local
			l_sql, l_scope: STRING_8
			l_sections: ARRAYED_LIST [BIB_COMMENTARY_SECTION]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_section: BIB_COMMENTARY_SECTION
			l_license: BIB_LICENSE
			l_provenance: BIB_PROVENANCE
			l_rows: ARRAYED_LIST [SIMPLE_SQL_ROW]
			l_failed: BOOLEAN
		do
			l_scope := a_book.out + " " + a_chapter.out + ":" + a_verse.out
			l_sql := sections_sql
			run_query (l_sql, {ARRAY [detachable ANY]} <<(create {BIB_HUB_ID}).hub_id (a_book, a_chapter, a_verse)>>)
			if attached last_rows as al_rows then
				create l_rows.make (al_rows.rows.count)
				across al_rows.rows as ic loop
					l_rows.extend (ic)
				end
				create l_sections.make (l_rows.count)
				create l_citations.make (2)
				across l_rows as ic loop
					create l_license.make (non_empty (ic.string_value ("license_id")), ic.integer_value ("non_commercial") /= 0,
						ic.integer_value ("share_alike") /= 0, ic.integer_value ("restricted") /= 0, ic.string_value ("credit"))
					create l_provenance.make (ic.integer_64_value ("provenance_key").max (1), non_empty (ic.string_value ("source_key")),
						non_empty (ic.string_value ("edition")), l_license, ic.string_value ("caveat"))
					if not across l_citations as ic_seen some ic_seen.key = l_provenance.key end then
						l_citations.extend (l_provenance)
					end
					if is_section_row (ic) then
						create l_section.make (ic.string_value ("section_id"), ic.string_value ("heading"), ic.integer_value ("start_book"),
							ic.integer_value ("start_chapter"), ic.integer_value ("start_verse"), ic.integer_value ("end_chapter"),
							ic.integer_value ("end_verse"), ic.string_value ("voice"), l_provenance)
						if fill_section (l_section) then
							l_sections.extend (l_section)
						else
							l_failed := True
						end
					end
				end
				if l_failed then
						-- Scan 39: a section half read is never shown as if whole.
					create Result.make_failure (method ("sections_for_verse", l_sql, pack_alias, l_scope, 0), query_error)
				elseif l_citations.is_empty then
					create Result.make_success (method ("sections_for_verse", l_sql, pack_alias, l_scope, 0), {ARRAY [BIB_PROVENANCE]} <<pack_provenance>>, l_sections)
				else
					create Result.make_success (method ("sections_for_verse", l_sql, pack_alias, l_scope, l_sections.count), l_citations, l_sections)
				end
			else
				create Result.make_failure (method ("sections_for_verse", l_sql, pack_alias, l_scope, 0), query_error)
			end
		ensure
			named: Result.method.engine_feature.same_string_general ("sections_for_verse")
			narrowest_first: across 1 |..| (Result.count - 1) as l_i all span (Result.item (l_i)) <= span (Result.item (l_i + 1)) end
		end

	span (a_section: BIB_COMMENTARY_SECTION): INTEGER_64
			-- How many hub ids `a_section' reaches across (0 for one verse).
		local
			l_hub: BIB_HUB_ID
		do
			create l_hub
			Result := l_hub.hub_id (a_section.book, a_section.end_chapter, a_section.end_verse) - l_hub.hub_id (a_section.book, a_section.start_chapter, a_section.start_verse)
		end

feature {NONE} -- Implementation

	sections_sql: STRING_8
			-- The sections over one hub id, with their provenance, narrowest first.
		do
			Result := "SELECT s.section_id, s.heading, s.start_book, s.start_chapter, s.start_verse, s.end_chapter, s.end_verse, s.voice, s.provenance_key, p.source_key, p.edition, p.license_id, p.non_commercial, p.share_alike, p.restricted, p.credit, p.caveat FROM "
				+ pack_alias + ".commentary_section s JOIN " + pack_alias + ".source_provenance p ON p.provenance_key = s.provenance_key WHERE ? BETWEEN s.start_hub AND s.end_hub ORDER BY s.end_hub - s.start_hub, s.ordinal"
		end

	is_section_row (a_row: SIMPLE_SQL_ROW): BOOLEAN
			-- Does `a_row' meet BIB_COMMENTARY_SECTION's preconditions?
		do
			Result := not a_row.string_value ("section_id").is_empty and a_row.integer_value ("start_book") > 0
				and a_row.integer_value ("start_chapter") > 0 and a_row.integer_value ("start_verse") > 0
				and (a_row.integer_value ("end_chapter") > a_row.integer_value ("start_chapter")
					or (a_row.integer_value ("end_chapter") = a_row.integer_value ("start_chapter") and a_row.integer_value ("end_verse") >= a_row.integer_value ("start_verse")))
				and not a_row.string_value ("voice").is_empty
		end

	fill_section (a_section: BIB_COMMENTARY_SECTION): BOOLEAN
			-- Read `a_section''s fields, claims, terms, lists and restricted quotations; False when
			-- a query failed (`query_error' says why).
		local
			l_id: STRING_32
			l_label: STRING_32
		do
			Result := True
			l_id := a_section.section_id
			run_query ("SELECT field_kind, body_markdown FROM " + pack_alias + ".commentary_field WHERE section_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_section.fields.extend ([ic.string_value ("field_kind").to_string_8, ic.string_value ("body_markdown")])
				end
			end
			run_query ("SELECT claim_id, label, claim_text, summary, source_ref FROM " + pack_alias + ".commentary_claim WHERE section_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					l_label := ic.string_value ("label")
					if not ic.string_value ("claim_id").is_empty and (l_label.same_string ({BIB_COMMENTARY_CLAIM}.Sourced) or l_label.same_string ({BIB_COMMENTARY_CLAIM}.Deduced)) then
						a_section.claims.extend (create {BIB_COMMENTARY_CLAIM}.make (ic.string_value ("claim_id"), l_label, ic.string_value ("claim_text"), ic.string_value ("summary"), ic.string_value ("source_ref")))
					end
				end
			end
			run_query ("SELECT script, translit, pron, english, language FROM " + pack_alias + ".commentary_term WHERE section_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_section.terms.extend ([ic.string_value ("script"), ic.string_value ("translit"), ic.string_value ("pron"), ic.string_value ("english"), ic.string_value ("language")])
				end
			end
			run_query ("SELECT list_kind, item_markdown FROM " + pack_alias + ".commentary_list WHERE section_id = ? ORDER BY list_kind, ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_section.lists.extend ([ic.string_value ("list_kind").to_string_8, ic.string_value ("item_markdown")])
				end
			end
			run_query ("SELECT source, ship_class, note, body_markdown FROM " + pack_alias + ".commentary_restricted_quote WHERE section_id = ? ORDER BY ordinal", {ARRAY [detachable ANY]} <<l_id>>)
			Result := Result and last_rows /= Void
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					a_section.restricted_quotes.extend ([ic.string_value ("source"), ic.string_value ("ship_class"), ic.string_value ("note"), ic.string_value ("body_markdown")])
				end
			end
		end

	pack_provenance: BIB_PROVENANCE
			-- The pack itself, cited when a verse has no section.
		do
			create Result.make (1, method_edition, method_edition, create {BIB_LICENSE}.make ({STRING_32} "private", True, False, True, {STRING_32} "Larry Rix"), {STRING_32} "")
		end

	non_empty (a_text: STRING_32): STRING_32
			-- `a_text', or "unknown" when it is empty.
		do
			if a_text.is_empty then
				Result := {STRING_32} "unknown"
			else
				Result := a_text
			end
		end

	sources: BIB_SOURCE_SET

	query_failed_message: STRING_8 = "A commentary query failed."
	not_open_message: STRING_8 = "The commentary pack is not attached."

	method_edition: STRING_32
		do
			Result := title
			if Result.is_empty then
				Result := {STRING_32} "commentary pack"
			end
		end

end
