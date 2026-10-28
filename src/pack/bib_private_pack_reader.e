note
	description: "[
		A private pack's reader (design scan 58): what BIB_COMMENTARY_PACK and
		BIB_FRAMEWORK_PACK had line for line - the connection and the alias the
		pack is attached under, its title, whether it is attached, a provenance
		row read into a BIB_PROVENANCE, and the pack's own provenance as its
		builder wrote it (the frameworks reader had invented one). The heir names
		its noun and its two messages, and asks its own questions.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_PRIVATE_PACK_READER

inherit
	BIB_SQLITE_QUERYING

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_alias: READABLE_STRING_8; a_title: READABLE_STRING_GENERAL)
			-- The pack attached as `a_alias' on `a_sources', titled `a_title'.
		require
			alias_not_empty: not a_alias.is_empty
		do
			sources := a_sources
			pack_alias := a_alias.to_string_8
			title := a_title.to_string_32
		ensure
			alias_set: pack_alias.same_string (a_alias)
			title_set: title.same_string_general (a_title)
		end

feature -- Access

	pack_alias: STRING_8
			-- The alias the pack is attached under.

	title: STRING_32
			-- The pack's `meta.title'.

	is_available: BOOLEAN
			-- Is the pack attached?
		do
			Result := sources.is_open and then sources.is_attached_alias (pack_alias)
		end

feature {NONE} -- The heir's part

	pack_noun: STRING_32
			-- What the pack is called when it names no title ("commentary pack").
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature {NONE} -- Provenance

	sources: BIB_SOURCE_SET
			-- The connection the pack is attached on.

	method_edition: STRING_32
			-- The pack's title, else its noun.
		do
			Result := title
			if Result.is_empty then
				Result := pack_noun
			end
		end

	provenance_of_row (a_row: SIMPLE_SQL_ROW): BIB_PROVENANCE
			-- The provenance a row carrying `source_provenance''s columns names (a missing source,
			-- edition or license read as "unknown").
		local
			l_license: BIB_LICENSE
		do
			create l_license.make (non_empty (a_row.string_value ("license_id")), a_row.integer_value ("non_commercial") /= 0,
				a_row.integer_value ("share_alike") /= 0, a_row.integer_value ("restricted") /= 0, a_row.string_value ("credit"))
			create Result.make (a_row.integer_64_value ("provenance_key").max (1), non_empty (a_row.string_value ("source_key")),
				non_empty (a_row.string_value ("edition")), l_license, a_row.string_value ("caveat"))
		end

	pack_provenance: BIB_PROVENANCE
			-- The pack's own provenance: its first `source_provenance' row as the builder wrote it,
			-- read once; a private one in the pack's name only when that row cannot be read.
		do
			if attached pack_provenance_read as al_read then
				Result := al_read
			else
				run_query ("SELECT provenance_key, source_key, edition, license_id, non_commercial, share_alike, restricted, credit, caveat FROM "
					+ pack_alias + ".source_provenance ORDER BY provenance_key LIMIT 1", {ARRAY [detachable ANY]} <<>>)
				if attached last_rows as al_rows and then not al_rows.rows.is_empty then
					Result := provenance_of_row (al_rows.rows.first)
				else
					create Result.make (1, method_edition, method_edition,
						create {BIB_LICENSE}.make ({STRING_32} "private", True, False, True, {STRING_32} "Larry Rix"), {STRING_32} "")
				end
				pack_provenance_read := Result
			end
		end

	pack_provenance_read: detachable BIB_PROVENANCE
			-- `pack_provenance' once read.

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

end
