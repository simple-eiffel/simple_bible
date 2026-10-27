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

	make (a_sources: BIB_SOURCE_SET; a_edition: READABLE_STRING_GENERAL; a_normalizers: BIB_NORMALIZER_SET)
			-- A reader over content.db in `a_sources', whose build is `a_edition'; searches fold with
			-- `a_normalizers', as the build did.
		require
			edition_not_empty: not a_edition.is_empty
		do
			sources := a_sources
			edition := a_edition.to_string_32
			normalizers := a_normalizers
			create versions.make (24)
			create version_orders.make (24)
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

	has_cross_references: BOOLEAN
			-- Does content.db carry cross-references (an optional table in v2)?

	has_verse_index: BOOLEAN
			-- Does content.db carry `verse_fts', the verse search index (optional; bible_build 0.3.0)?

	verses_matching (a_version: READABLE_STRING_8; a_words: READABLE_STRING_GENERAL; a_limit: INTEGER): BIB_LIST_RESULT [BIB_READING_VERSE]
			-- The verses of `a_version' holding every word of `a_words' (a "quoted phrase" as written,
			-- a word ending in * as a prefix), in Bible order, at most `a_limit'. Words fold as the
			-- build folded the text (D-009), so unpointed Hebrew finds pointed and "beginning" finds
			-- "Beginning". Empty when nothing searchable is left or content.db has no index.
		require
			version_known: has_version (a_version)
			limit_positive: a_limit > 0
		local
			l_verses: ARRAYED_LIST [BIB_READING_VERSE]
			l_expression: STRING_32
			l_first: INTEGER_64
		do
			create l_verses.make (0)
			l_expression := search_expression (a_version, a_words)
			if attached version (a_version) as al_version then
				if not has_verse_index or l_expression.is_empty then
					create Result.make_success (method ("verses_matching", Search_sql, a_version, a_words, 0), {ARRAY [BIB_PROVENANCE]} <<al_version.provenance>>, l_verses)
				else
					l_first := keys.first_key (version_orders.item (a_version.to_string_8))
					run_query (Search_sql, {ARRAY [detachable ANY]} <<l_expression, l_first, keys.last_key (version_orders.item (a_version.to_string_8)), a_limit, al_version.code>>)
					if attached last_rows as al_rows then
						create l_verses.make (al_rows.rows.count)
						across al_rows.rows as ic loop
							l_verses.extend (create {BIB_READING_VERSE}.make (al_version.code, ic.integer_value ("book_id"), ic.integer_value ("chapter"), ic.integer_value ("verse"), ic.string_value ("text"), al_version.provenance))
						end
						create Result.make_success (method ("verses_matching", Search_sql, a_version, a_words, l_verses.count), {ARRAY [BIB_PROVENANCE]} <<al_version.provenance>>, l_verses)
					else
						create Result.make_failure (method ("verses_matching", Search_sql, a_version, a_words, 0), query_error)
					end
				end
			else
				check version_known: False then end
			end
		ensure
			one_version: across 1 |..| Result.count as i all Result.item (i).version_code.same_string (a_version) end
			at_most_the_limit: Result.count <= a_limit
			method_recorded: Result.method.engine_feature.same_string_general ("verses_matching")
		end

	matching_count (a_version: READABLE_STRING_8; a_words: READABLE_STRING_GENERAL): INTEGER
			-- How many verses of `a_version' `verses_matching' would find with no limit (0 on failure).
		require
			version_known: has_version (a_version)
		local
			l_expression: STRING_32
			l_first: INTEGER_64
		do
			l_expression := search_expression (a_version, a_words)
			if has_verse_index and not l_expression.is_empty then
				l_first := keys.first_key (version_orders.item (a_version.to_string_8))
				run_query (Count_sql, {ARRAY [detachable ANY]} <<l_expression, l_first, keys.last_key (version_orders.item (a_version.to_string_8))>>)
				if attached last_rows as al_rows then
					across al_rows.rows as ic loop
						Result := ic.integer_value ("n")
					end
				end
			end
		ensure
			not_negative: Result >= 0
		end

	search_expression (a_version: READABLE_STRING_8; a_words: READABLE_STRING_GENERAL): STRING_32
			-- The FTS5 expression for `a_words' in `a_version''s language: each word, or each "quoted
			-- phrase", one FTS5 string (so no word is read as an operator); a word ending in * a
			-- prefix. Empty when no letter or digit is left.
		require
			version_known: has_version (a_version)
		local
			l_form, l_term: STRING_32
			i: INTEGER
			l_in_quote, l_closing_star: BOOLEAN
		do
			create Result.make_empty
			if attached version (a_version) as al_version then
				l_form := normalizers.for_language (al_version.language).normalized (a_words)
				create l_term.make_empty
				from i := 1 until i > l_form.count + 1 loop
					if i > l_form.count or else l_form [i] = '"' or else (not l_in_quote and l_form [i] = ' ') then
						l_closing_star := l_in_quote and then i < l_form.count and then l_form [i] = '"' and then l_form [i + 1] = '*'
						if l_closing_star then
								-- "a phrase"* ends in a prefix (design scan 47: the star was dropped).
							l_term.append_character ('*')
						end
						append_term (Result, l_term)
						l_term.wipe_out
						if i <= l_form.count and then l_form [i] = '"' then
							l_in_quote := not l_in_quote
						end
						if l_closing_star then
							i := i + 1
						end
					else
						l_term.append_character (l_form [i])
					end
					i := i + 1
				end
			end
		end

	keys: BIB_VERSE_KEY
			-- `verse_fts''s keys (bible_build writes the same).
		once ("OBJECT")
			create Result
		end

	cross_references (a_book, a_chapter, a_verse: INTEGER): BIB_LIST_RESULT [BIB_READING_CROSS_REF]
			-- The cross-references from `a_book' `a_chapter':`a_verse', most voted first; empty when
			-- content.db carries none (P04's Cross-refs tab).
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_positive: a_verse > 0
		local
			l_refs: ARRAYED_LIST [BIB_READING_CROSS_REF]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_scope: STRING_32
		do
			l_scope := a_book.out + " " + a_chapter.out + ":" + a_verse.out
			create l_refs.make (0)
			create l_citations.make (1)
			if not has_cross_references or not attached cross_reference_provenance as al_provenance then
				create Result.make_success (method ("cross_references", Cross_references_sql, "", l_scope, 0), l_citations, l_refs)
			else
				run_query (Cross_references_sql, <<a_book, a_chapter, a_verse>>)
				if attached last_rows as al_rows then
					create l_refs.make (al_rows.rows.count)
					across al_rows.rows as ic loop
						if ic.integer_value ("to_book") > 0 and ic.integer_value ("to_chapter") > 0 and ic.integer_value ("to_verse_start") > 0 then
							l_refs.extend (create {BIB_READING_CROSS_REF}.make (ic.integer_value ("to_book"), ic.integer_value ("to_chapter"),
								ic.integer_value ("to_verse_start"), ic.integer_value ("to_verse_end"), ic.integer_value ("votes"), al_provenance))
						end
					end
					l_citations.extend (al_provenance)
					create Result.make_success (method ("cross_references", Cross_references_sql, "", l_scope, l_refs.count), l_citations, l_refs)
				else
					create Result.make_failure (method ("cross_references", Cross_references_sql, "", l_scope, 0), query_error)
				end
			end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("cross_references")
			empty_without_table: not has_cross_references implies Result.count = 0
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

	normalizers: BIB_NORMALIZER_SET
			-- The search folds, shared with the build.

	version_orders: HASH_TABLE [INTEGER, STRING_8]
			-- Each version's `sort_order', the first part of its `verse_key'.

	append_term (a_expression, a_term: STRING_32)
			-- Add `a_term' to `a_expression' as one FTS5 string ("term", or "term"* for a prefix),
			-- unless it holds no letter or digit.
		local
			l_text: STRING_32
			l_prefix: BOOLEAN
		do
			l_text := a_term.twin
			l_text.left_adjust
			l_text.right_adjust
			from until l_text.is_empty or else l_text [l_text.count] /= '*' loop
				l_prefix := True
				l_text.remove_tail (1)
			end
			if across l_text as ic some normalizers.unicode.is_letter_or_digit (ic) end then
				if not a_expression.is_empty then
					a_expression.append_character (' ')
				end
				a_expression.append_character ('"')
				a_expression.append (l_text)
				a_expression.append_character ('"')
				if l_prefix then
					a_expression.append_character ('*')
				end
			end
		end

	cross_reference_provenance: detachable BIB_PROVENANCE
			-- The cross-references' source row, read with the versions.

	load_versions
			-- Read `version_info' with each version's source, and whether cross-references are carried
			-- (the optional table's source row; a query error there just means it is absent).
		require
			open: sources.is_open
		local
			l_license: BIB_LICENSE
			l_provenance: BIB_PROVENANCE
		do
			versions.wipe_out
			run_query ("SELECT p.provenance_key, p.source_key, p.edition, p.license_id, p.non_commercial, p.share_alike, p.restricted, p.credit, p.caveat FROM main.source_provenance p WHERE p.provenance_key = (SELECT provenance_key FROM main.cross_reference LIMIT 1)", {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					create l_license.make (non_empty (ic.string_value ("license_id")), ic.integer_value ("non_commercial") /= 0,
						ic.integer_value ("share_alike") /= 0, ic.integer_value ("restricted") /= 0, ic.string_value ("credit"))
					create cross_reference_provenance.make (ic.integer_64_value ("provenance_key"), non_empty (ic.string_value ("source_key")), non_empty (ic.string_value ("edition")), l_license, ic.string_value ("caveat"))
					has_cross_references := True
				end
			end
			run_query ("SELECT rowid FROM main.verse_fts LIMIT 1", {ARRAY [detachable ANY]} <<>>)
			has_verse_index := last_rows /= Void
			run_query (Versions_sql, {ARRAY [detachable ANY]} <<>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					if not ic.string_value ("version_code").is_empty and not ic.string_value ("name").is_empty then
						create l_license.make (non_empty (ic.string_value ("license_id")), ic.integer_value ("non_commercial") /= 0,
							ic.integer_value ("share_alike") /= 0, ic.integer_value ("restricted") /= 0, ic.string_value ("credit"))
						create l_provenance.make (ic.integer_64_value ("provenance_key"), non_empty (ic.string_value ("source_key")),
							non_empty (ic.string_value ("edition")), l_license, ic.string_value ("caveat"))
						version_orders.force (ic.integer_value ("sort_order"), ic.string_value ("version_code").to_string_8)
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

	Versions_sql: STRING_8 = "SELECT v.version_code, v.sort_order, v.name, v.language, v.direction, v.versification, v.caveat, v.provenance_key, p.source_key, p.edition, p.license_id, p.non_commercial, p.share_alike, p.restricted, p.credit FROM main.version_info v JOIN main.source_provenance p ON p.provenance_key = v.provenance_key ORDER BY v.sort_order, v.version_code"

	Chapter_sql: STRING_8 = "SELECT verse, text FROM main.verse_text WHERE version_code = ? AND book_id = ? AND chapter = ? ORDER BY verse"

	Cross_references_sql: STRING_8 = "SELECT to_book, to_chapter, to_verse_start, to_verse_end, votes FROM main.cross_reference WHERE from_book = ? AND from_chapter = ? AND from_verse = ? ORDER BY votes DESC, to_book, to_chapter, to_verse_start LIMIT 200"

	Search_sql: STRING_8 = "SELECT t.book_id, t.chapter, t.verse, t.text FROM (SELECT rowid AS key FROM main.verse_fts WHERE verse_fts MATCH ? AND rowid BETWEEN ? AND ? ORDER BY rowid LIMIT ?) h JOIN main.verse_text t ON t.version_code = ? AND t.book_id = (h.key %% 1000000000) / 1000000 AND t.chapter = (h.key %% 1000000) / 1000 AND t.verse = h.key %% 1000 ORDER BY h.key"
			-- The hits and their text in one query (design scan 47: one query per hit before); the
			-- key arithmetic is BIB_PLACE_PACKING's units.

	Count_sql: STRING_8 = "SELECT count(*) AS n FROM main.verse_fts WHERE verse_fts MATCH ? AND rowid BETWEEN ? AND ?"

	Last_chapter_sql: STRING_8 = "SELECT coalesce(max(chapter), 0) AS last FROM main.verse_text WHERE version_code = ? AND book_id = ?"

invariant
	edition_not_empty: not edition.is_empty

end
