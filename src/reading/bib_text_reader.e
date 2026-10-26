note
	description: "[
		Bible text for reading (FR-130's first content stage): the versions
		content.db holds and a chapter of any of them, each in its own
		numbering. No pairing across versions yet: that is the versification
		hub's work (BIB_VERSE_HUB, BIB_VERSIFICATION_MAP), which builds on the
		same `verse_text` table later (fold 2026-10-26, Larry: "Reading slice
		now", the way D-021 put the concordance first).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_TEXT_READER

inherit
	BIB_SQLITE_QUERYING
		redefine
			method_versions
		end

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_edition: READABLE_STRING_GENERAL)
			-- A reader over content.db in `a_sources', whose build is `a_edition'.
		require
			edition_not_empty: not a_edition.is_empty
		do
			sources := a_sources
			edition := a_edition.to_string_32
			create versions.make (24)
			if a_sources.is_open then
				load_versions
			end
		ensure
			sources_set: sources = a_sources
		end

feature -- Access

	versions: ARRAYED_LIST [BIB_READING_VERSION]
			-- Every version content.db holds, in its own order.

	version (a_code: READABLE_STRING_8): detachable BIB_READING_VERSION
			-- The version coded `a_code'; Void when there is none.
		do
			across versions as ic until Result /= Void loop
				if ic.code.same_string (a_code) then
					Result := ic
				end
			end
		ensure
			same_code: attached Result implies Result.code.same_string (a_code)
		end

	has_version (a_code: READABLE_STRING_8): BOOLEAN
			-- Does content.db hold version `a_code'?
		do
			Result := version (a_code) /= Void
		end

feature -- Reading

	chapter (a_version: READABLE_STRING_8; a_book, a_chapter: INTEGER): BIB_LIST_RESULT [BIB_READING_VERSE]
			-- Chapter `a_chapter' of book `a_book' in `a_version', verse by verse; empty when the
			-- version lacks it, a failure with SQLite's words when the query fails.
		require
			version_known: has_version (a_version)
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
		local
			l_verses: ARRAYED_LIST [BIB_READING_VERSE]
		do
			run_query (Chapter_sql, <<a_version.to_string_8, a_book, a_chapter>>)
			if attached last_rows as al_rows and attached version (a_version) as al_version then
				create l_verses.make (al_rows.rows.count)
				across al_rows.rows as ic loop
					if ic.integer_value ("verse") > 0 then
						l_verses.extend (create {BIB_READING_VERSE}.make (a_version, a_book, a_chapter, ic.integer_value ("verse"), ic.string_value ("text"), al_version.provenance))
					end
				end
				create Result.make_success (method ("chapter", Chapter_sql, a_version, a_book.out + " " + a_chapter.out, l_verses.count),
					{ARRAY [BIB_PROVENANCE]} <<al_version.provenance>>, l_verses)
			else
				create Result.make_failure (method ("chapter", Chapter_sql, a_version, a_book.out + " " + a_chapter.out, 0), query_error)
			end
		ensure
			one_version: across 1 |..| Result.count as i all Result.item (i).version_code.same_string (a_version) end
			one_chapter: across 1 |..| Result.count as i all Result.item (i).book_id = a_book and Result.item (i).chapter = a_chapter end
			method_recorded: Result.method.engine_feature.same_string_general ("chapter")
		end

	last_chapter (a_version: READABLE_STRING_8; a_book: INTEGER): INTEGER
			-- The last chapter of book `a_book' in `a_version'; 0 when the version lacks the book.
		require
			version_known: has_version (a_version)
			book_positive: a_book > 0
		do
			run_query (Last_chapter_sql, <<a_version.to_string_8, a_book>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result := ic.integer_value ("last")
				end
			end
		ensure
			not_negative: Result >= 0
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
	edition: STRING_32

	load_versions
			-- Read `version_info' with each version's source.
		require
			open: sources.is_open
		local
			l_license: BIB_LICENSE
			l_provenance: BIB_PROVENANCE
		do
			versions.wipe_out
			run_query (Versions_sql, {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					if not ic.string_value ("version_code").is_empty and not ic.string_value ("name").is_empty then
						create l_license.make (non_empty (ic.string_value ("license_id")), ic.integer_value ("non_commercial") /= 0,
							ic.integer_value ("share_alike") /= 0, ic.integer_value ("restricted") /= 0, ic.string_value ("credit"))
						create l_provenance.make (ic.integer_64_value ("provenance_key"), non_empty (ic.string_value ("source_key")),
							non_empty (ic.string_value ("edition")), l_license, ic.string_value ("caveat"))
						versions.extend (create {BIB_READING_VERSION}.make (ic.string_value ("version_code").to_string_8, ic.string_value ("name"),
							ic.string_value ("language").to_string_8, ic.string_value ("direction").to_string_8,
							ic.string_value ("versification").to_string_8, ic.string_value ("caveat"), l_provenance))
					end
				end
			end
		end

	non_empty (a_text: STRING_32): STRING_32
			-- `a_text', or "unknown" when it is empty.
		do
			if a_text.is_empty then
				Result := {STRING_32} "unknown"
			else
				Result := a_text
			end
		ensure
			not_empty: not Result.is_empty
		end

	query_failed_message: STRING_8 = "A Bible text query failed."
	not_open_message: STRING_8 = "content.db is not open."
			-- The reader's words around SQLite's own (BIB_SQLITE_QUERYING).

	method_edition: STRING_32
			-- content.db's build, for the method records.
		do
			Result := edition
		end

	method_versions (a_version: READABLE_STRING_8): ARRAYED_LIST [STRING_32]
			-- A reading query names the one version it read.
		do
			create Result.make (1)
			Result.extend (a_version.to_string_32)
		end

feature {NONE} -- SQL

	Versions_sql: STRING_8 = "SELECT v.version_code, v.name, v.language, v.direction, v.versification, v.caveat, v.provenance_key, p.source_key, p.edition, p.license_id, p.non_commercial, p.share_alike, p.restricted, p.credit FROM main.version_info v JOIN main.source_provenance p ON p.provenance_key = v.provenance_key ORDER BY v.sort_order, v.version_code"

	Chapter_sql: STRING_8 = "SELECT verse, text FROM main.verse_text WHERE version_code = ? AND book_id = ? AND chapter = ? ORDER BY verse"

	Last_chapter_sql: STRING_8 = "SELECT coalesce(max(chapter), 0) AS last FROM main.verse_text WHERE version_code = ? AND book_id = ?"

invariant
	edition_not_empty: not edition.is_empty

end
