note
	description: "[
		The concordance pack reader (debate 05b). One class owns every SQL statement against the
		attached concordance pack (alias "conc"), whichever file it is (conc.db or
		conc_dist.db). BIB_CONCORDANCE is untouched and keeps core-database counts.
		Headwords are keyed by lemma_id (INTEGER_64), never by Strong's. The English
		and verse lookups reach the pack through `english_rows' and `verse_words'
		here: `sources' is private, so no other class can run SQL (ruling 2.3).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CONC_PACK

inherit
	BIB_SQLITE_QUERYING

	BIB_LANGUAGE_CODES
		export
			{NONE} all
		end

	BIB_LEMMA_BASIS
		export
			{NONE} all
		end

	BIB_CITATIONS

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
			create corpus_codes.make (0)
			create corpus_ids.make (8)
			create corpus_code_of.make (8)
			create corpus_provenances.make (8)
			create corpus_names.make (8)
			create edition_label_cache.make_empty
		ensure
			sources_set: sources = a_sources
			not_validated: not is_pack_valid
		end

feature -- Status

	is_attached: BOOLEAN
			-- Is a database attached as `Pack_alias'? (Attached, not yet known to be a valid pack.)
		do
			Result := sources.is_attached_alias (Pack_alias)
		ensure
			definition: Result = sources.is_attached_alias (Pack_alias)
		end

	is_pack_valid: BOOLEAN
			-- Did `check_pack' accept the attached pack (FR-164: `user_version' and required tables)?

	validated_serial: INTEGER_64
			-- The `attachment_serial' of the pack `check_pack' accepted; 0 when none. The source
			-- set is shared, so the pack can be detached and another file, or the same path
			-- rebuilt, attached under `Pack_alias' behind this reader's back; that pack is not
			-- available until it is checked (design scans 25 and 27).

	is_available: BOOLEAN
			-- Is the pack `check_pack' accepted still the one attached as `Pack_alias'?
			-- No SQL here: every lookup evaluates this, so the check runs once, in
			-- `check_pack' (ruling 3.3).
		do
			Result := is_pack_valid and then validated_serial > 0
				and then sources.attachment_serial (Pack_alias) = validated_serial
		ensure
			needs_attachment: Result implies is_attached
			needs_check: Result implies is_pack_valid
		end

	has_corpus (a_code: READABLE_STRING_8): BOOLEAN
			-- Does the pack list corpus `a_code'? No SQL: the codes are read once, by `check_pack'
			-- (this is a precondition of every page query).
		require
			available: is_available
		do
			Result := across corpus_codes as ic some ic.same_string (a_code) end
		end

	has_layer (a_layer: READABLE_STRING_8): BOOLEAN
			-- Does the pack carry layer `a_layer' ("lxx", "bsb", "dictionaries")? conc_dist.db may not.
			-- Read from the pack's own corpus list and meanings, never from an edition name (FR-158).
		require
			available: is_available
		do
			if a_layer.same_string ("lxx") then
				Result := across corpus_codes as ic some ic.starts_with ("LXX-") end
			elseif a_layer.same_string ("bsb") then
				Result := has_corpus ("ENG-BSB")
			elseif a_layer.same_string ("dictionaries") then
				Result := has_meanings
			end
		ensure
			unknown_layer_absent: not (a_layer.same_string ("lxx") or a_layer.same_string ("bsb") or a_layer.same_string ("dictionaries")) implies not Result
		end

	corpus_name (a_code: READABLE_STRING_8): STRING_32
			-- The name a reader sees for corpus `a_code' (FR-156: never the code), or the code when
			-- the pack names none.
		require
			available: is_available
		do
			if attached corpus_names.item (a_code.to_string_8) as al_name and then not al_name.is_empty then
				Result := al_name
			else
				Result := a_code.to_string_32
			end
		ensure
			not_empty: not a_code.is_empty implies not Result.is_empty
		end

	corpus_short_name (a_code: READABLE_STRING_8): STRING_32
			-- `corpus_name' cut before its first qualifier (" (", " - ", " with ", ", "): "Septuagint"
			-- for "Septuagint, Rahlfs 1935 (CATSS ...)", the label a column or chip has room for.
		require
			available: is_available
		local
			l_cut: INTEGER
		do
			Result := corpus_name (a_code).twin
			across <<{STRING_32} " (", {STRING_32} " - ", {STRING_32} " with ", {STRING_32} ", ">> as ic loop
				l_cut := Result.substring_index (ic, 1)
				if l_cut > 1 then
					Result := Result.substring (1, l_cut - 1)
				end
			end
		ensure
			not_empty: not a_code.is_empty implies not Result.is_empty
			never_longer: Result.count <= corpus_name (a_code).count
		end

	corpus_of (a_provenance: BIB_PROVENANCE): STRING_8
			-- The code of the corpus whose provenance `a_provenance' is; empty when it is none of the
			-- pack's corpora. A headword's provenance names the corpus where it occurs most, so this
			-- is where its word view opens (design scan 31, F6: no reading of provenance keys).
		require
			available: is_available
		do
			create Result.make_empty
			across corpus_provenances as ic until not Result.is_empty loop
				if ic = a_provenance and then attached corpus_code_of.item (@ic.key) as al_code then
					Result := al_code
				end
			end
		ensure
			known_or_empty: not Result.is_empty implies has_corpus (Result)
		end

	pack_error: detachable BIB_ERROR
			-- Why `check_pack' refused the attached pack; Void when it accepted it or has not run.

feature -- Commands

	check_pack
			-- Validate the pack attached as `Pack_alias' once, at attach, and record
			-- the answer in `is_pack_valid' (FR-164).
		require
			pack_attached: is_attached
		local
			l_schema: SIMPLE_SQL_SCHEMA
			l_version: INTEGER
		do
			is_pack_valid := False
			validated_serial := 0
			pack_error := Void
			corpus_codes.wipe_out
			corpus_ids.wipe_out
			corpus_code_of.wipe_out
			corpus_provenances.wipe_out
			corpus_names.wipe_out
			has_meanings := False
			create edition_label_cache.make_empty
			fallback_provenance := Void
			if attached sources.database as al_db then
				create l_schema.make (al_db)
					-- PRAGMA conc.user_version, never the unqualified pragma, which reads main (ruling 3.3).
				l_version := l_schema.user_version_of (Pack_alias)
				if al_db.has_error then
					create pack_error.make_with_details ({BIB_ERROR}.Database_problem, "The concordance pack cannot be read.", sqlite_message (al_db, pack_path))
				elseif l_version /= Expected_user_version then
					create pack_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "The concordance pack is version " + l_version.out + "; this engine reads version " + Expected_user_version.out + ".", pack_path)
				elseif attached first_missing_table (l_schema) as al_missing then
					create pack_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "The concordance pack has no table " + al_missing + ".", pack_path)
				else
					read_pack_facts (al_db)
					if pack_error /= Void then
							-- `read_pack_facts' reported a query SQLite refused.
					elseif corpus_codes.is_empty then
						create pack_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "The concordance pack lists no corpus.", pack_path)
					elseif edition_label_cache.is_empty then
						create pack_error.make_with_details ({BIB_ERROR}.Schema_mismatch, "The concordance pack does not name its edition (meta edition_label).", pack_path)
					else
						is_pack_valid := True
						validated_serial := sources.attachment_serial (Pack_alias)
					end
				end
			end
		ensure
			valid_only_when_attached: is_pack_valid implies is_attached
			serial_recorded: is_pack_valid implies validated_serial = sources.attachment_serial (Pack_alias)
			reason_when_refused: not is_pack_valid implies pack_error /= Void
			no_reason_when_accepted: is_pack_valid implies pack_error = Void
		end

feature -- Access

	edition_label: STRING_32
			-- What the pack says it is (title bar / About); the engine never branches on it.
		require
			available: is_available
		do
			Result := edition_label_cache.twin
		ensure
			not_empty: not Result.is_empty
		end

	word_entry (a_lemma_id: INTEGER_64): detachable BIB_WORD_ENTRY
			-- Heading of `a_lemma_id'; Void when unknown, and for an English lemma, which is a
			-- rendering, not a headword (ruling 1.2). A query SQLite refuses also answers Void.
		require
			available: is_available
			id_positive: a_lemma_id > 0
		do
			run_query ("SELECT " + Entry_columns + " FROM conc.lemma l WHERE l.lemma_id = ?", {ARRAY [detachable ANY]} <<a_lemma_id>>)
			if attached last_rows as al_rows and then not al_rows.rows.is_empty and then attached al_rows.rows.first as al_row then
				Result := entry_from_row (al_row)
			end
		ensure
			same_headword: attached Result as r implies r.lemma_id = a_lemma_id
		end

	headwords_for_strongs (a_key: BIB_STRONGS_KEY): BIB_LIST_RESULT [BIB_WORD_ENTRY]
			-- Headword candidates behind `a_key' through lemma_xref only (FR-153), commonest first.
		require
			available: is_available
		local
			l_sql: STRING_8
		do
			l_sql := "SELECT " + Entry_columns + " FROM conc.lemma_xref x JOIN conc.lemma l ON l.lemma_id = x.lemma_id WHERE x.scheme = 'strongs' AND x.value = ? ORDER BY l.n_tokens DESC, l.lemma_id"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_key.text>>)
			Result := entries_result ("headwords_for_strongs", l_sql, a_key.text)
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("headwords_for_strongs")
			fact_closure: Result.is_fact_closed
		end

	headwords_behind_word (a_corpus_code: READABLE_STRING_8; a_ref: BIB_REF; a_word: READABLE_STRING_GENERAL; a_occurrence: INTEGER): BIB_LIST_RESULT [BIB_WORD_ENTRY]
			-- The original-language headwords behind the `a_occurrence'th `a_word' of verse `a_ref' in
			-- English corpus `a_corpus_code', through its per-word translation links: the word a reader
			-- clicked in the Bible text (S4, GW-08). Empty when that word carries no link.
		require
			available: is_available
			corpus_known: has_corpus (a_corpus_code)
			word_not_empty: not a_word.is_empty
			occurrence_positive: a_occurrence >= 1
		local
			l_token: INTEGER_64
			l_seen: INTEGER
			l_scope: STRING_32
		do
			l_scope := verse_scope (a_ref).to_string_32 + {STRING_32} ", word " + a_word.to_string_32 + {STRING_32} " #" + a_occurrence.out
			run_query (Verse_word_tokens_sql, {ARRAY [detachable ANY]} <<corpus_id (a_corpus_code), a_ref.book_id, a_ref.chapter.out, a_ref.verse.out, a_word.to_string_32>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic until l_token > 0 loop
					l_seen := l_seen + 1
					if l_seen = a_occurrence then
						l_token := ic.integer_64_value ("token_id")
					end
				end
				run_query (Linked_headwords_sql, {ARRAY [detachable ANY]} <<l_token, "translation:" + a_corpus_code.to_string_8>>)
				Result := entries_result ("headwords_behind_word", Linked_headwords_sql, l_scope)
			else
				create Result.make_failure (method ("headwords_behind_word", Verse_word_tokens_sql, a_corpus_code, l_scope, 0), query_error)
			end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("headwords_behind_word")
		end

	headwords_for_text (a_text: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_WORD_ENTRY]
			-- Headwords written or transliterated as `a_text', commonest first: Hebrew matched
			-- without its points (as `lemma.search'), Greek as written or without accents, and
			-- plain letters without diacritics (`lemma.translit_ascii', pack v2: "bara",
			-- "shamayim"). What a reader types into the lookup box.
		require
			available: is_available
			text_not_empty: not a_text.is_empty
		local
			l_sql: STRING_8
			l_plain: STRING_32
		do
			l_plain := without_hebrew_points (a_text.to_string_32).as_lower
			l_sql := "SELECT " + Entry_columns + " FROM conc.lemma l WHERE l.language IN ('hbo', 'arc', 'grc') AND (l.search = ? OR l.headword = ? OR l.translit_ascii = ?) ORDER BY l.n_tokens DESC, l.lemma_id LIMIT " + Max_text_matches.out
			run_query (l_sql, {ARRAY [detachable ANY]} <<l_plain, a_text.to_string_32, l_plain>>)
			Result := entries_result ("headwords_for_text", l_sql, a_text)
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("headwords_for_text")
			bounded: Result.count <= Max_text_matches
			fact_closure: Result.is_fact_closed
		end

	english_glance (a_lemma_id: INTEGER_64; a_per_bible: INTEGER): BIB_LIST_RESULT [BIB_ENGLISH_GLANCE_ROW]
			-- English at a glance: for each English Bible, its commonest renderings of `a_lemma_id'
			-- (the builder's summary, FR-162), at most `a_per_bible' each. The little words a word
			-- alignment also links to a verb ("be", "they", "and") are held back: the real data
			-- links them to bara, for one, as often as "creator".
		require
			available: is_available
			id_positive: a_lemma_id > 0
			per_bible_positive: a_per_bible >= 1
		local
			l_sql: STRING_8
			l_rows: ARRAYED_LIST [BIB_ENGLISH_GLANCE_ROW]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_bible: INTEGER_64
			l_taken: INTEGER
			l_provenance: BIB_PROVENANCE
		do
			l_sql := "SELECT corpus_id, english, n FROM conc.lemma_english WHERE lemma_id = ? ORDER BY corpus_id, n DESC, english"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_lemma_id>>)
			if attached last_rows as al_rows then
				create l_rows.make (8)
				create l_citations.make (3)
				across al_rows.rows as ic loop
					if ic.integer_64_value ("corpus_id") /= l_bible then
						l_bible := ic.integer_64_value ("corpus_id")
						l_taken := 0
					end
					if l_taken < a_per_bible and ic.integer_64_value ("n") > 0 and then not ic.string_value ("english").is_empty
						and then not is_function_word (ic.string_value ("english"))
					then
						l_provenance := provenance_of_id (l_bible)
						l_rows.extend (create {BIB_ENGLISH_GLANCE_ROW}.make (corpus_code_of_id (l_bible), ic.string_value ("english"), ic.integer_64_value ("n"), l_provenance))
						cite (l_citations, l_provenance)
						l_taken := l_taken + 1
					end
				end
				if l_citations.is_empty then
					cite (l_citations, first_provenance)
				end
				create Result.make_success (method ("english_glance", l_sql, "", "lemma " + a_lemma_id.out, l_rows.count), l_citations, l_rows)
			else
				create Result.make_failure (method ("english_glance", l_sql, "", "lemma " + a_lemma_id.out, 0), query_error)
			end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("english_glance")
			no_function_words: Result.is_success implies across 1 |..| Result.count as l_i all not is_function_word (Result.item (l_i).english) end
			fact_closure: Result.is_fact_closed
		end

	is_function_word (a_english: READABLE_STRING_GENERAL): BOOLEAN
			-- Is `a_english' one of the little words English at a glance holds back?
		do
			Result := across Function_words as ic some a_english.to_string_32.as_lower.same_string_general (ic) end
		end

	place_total (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8): detachable BIB_FACT [INTEGER_64]
			-- Places of `a_lemma_id' in corpus `a_corpus_code', from the builder's per-corpus count
			-- (FR-162): 0 when the pack has no count row (the word is not in that corpus); Void when
			-- the count cannot be read, never a made-up 0 (design scan 28).
		require
			available: is_available
			id_positive: a_lemma_id > 0
			corpus_known: has_corpus (a_corpus_code)
		local
			l_total: INTEGER_64
		do
				-- The builder's per-corpus count (FR-162): no token is counted at view time (NFR-019).
			run_query ("SELECT n FROM conc.lemma_corpus_count WHERE lemma_id = ? AND corpus_id = ?", {ARRAY [detachable ANY]} <<a_lemma_id, corpus_id (a_corpus_code)>>)
			if attached last_rows as al_rows then
				if not al_rows.rows.is_empty and then attached al_rows.rows.first as al_row then
					l_total := al_row.integer_64_value ("n").max (0)
				end
				create Result.make (l_total, provenance_of (a_corpus_code))
			end
		ensure
			non_negative: attached Result as r implies r.value >= 0
		end

	place_page (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8; a_offset, a_limit: INTEGER): BIB_LIST_RESULT [BIB_PLACE_ROW]
			-- One page of the every-place list in token order.
		require
			available: is_available
			id_positive: a_lemma_id > 0
			corpus_known: has_corpus (a_corpus_code)
			offset_non_negative: a_offset >= 0
			limit_bounded: a_limit >= 1 and a_limit <= Max_page_size
		local
			l_sql: STRING_8
		do
			l_sql := Place_select + " WHERE t.lemma_id = ? AND t.corpus_id = ? ORDER BY t.token_id LIMIT ? OFFSET ?"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_lemma_id, corpus_id (a_corpus_code), a_limit, a_offset>>)
			Result := place_result ("place_page", l_sql, a_corpus_code, "lemma " + a_lemma_id.out + ", rows from " + (a_offset + 1).out)
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("place_page")
			bounded: Result.count <= a_limit
			ascending: across 1 |..| (Result.count - 1) as l_i all Result.item (l_i).token_id < Result.item (l_i + 1).token_id end
				-- No postcondition ties the page to `place_total': that count is the builder's, a fact
				-- about the pack's data, and a pack whose counts disagree must not stop the engine
				-- (design scan 28). The fixture tests check it; Task 0's acceptance checks the builder.
			fact_closure: Result.is_fact_closed
		end

	place_page_after (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8; a_after_token_id: INTEGER_64; a_limit: INTEGER): BIB_LIST_RESULT [BIB_PLACE_ROW]
			-- The next page of the every-place list: rows whose token id follows `a_after_token_id'
			-- (keyset paging for sequential scroll; cost does not grow with depth, ruling 2.1).
			-- `place_page' stays for the first page and for jumps (a grid jump has no previous id).
			-- No `page_size_right' here: the offset formula does not apply to a keyset query.
		require
			available: is_available
			id_positive: a_lemma_id > 0
			corpus_known: has_corpus (a_corpus_code)
			after_non_negative: a_after_token_id >= 0
			limit_bounded: a_limit >= 1 and a_limit <= Max_page_size
		local
			l_sql: STRING_8
		do
			l_sql := Place_select + " WHERE t.lemma_id = ? AND t.corpus_id = ? AND t.token_id > ? ORDER BY t.token_id LIMIT ?"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_lemma_id, corpus_id (a_corpus_code), a_after_token_id, a_limit>>)
			Result := place_result ("place_page_after", l_sql, a_corpus_code, "lemma " + a_lemma_id.out + ", rows after token " + a_after_token_id.out)
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("place_page_after")
			bounded: Result.count <= a_limit
			ascending: across 1 |..| (Result.count - 1) as l_i all Result.item (l_i).token_id < Result.item (l_i + 1).token_id end
			after_respected: across 1 |..| Result.count as l_i all Result.item (l_i).token_id > a_after_token_id end
			fact_closure: Result.is_fact_closed
		end

	english_rows (a_english: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_ENGLISH_ROW]
			-- Candidates behind `a_english', one row per English Bible, original word and book (FR-151;
			-- the SQL of BIB_ENGLISH_INDEX). The word is matched against `token.search' in lowercase;
			-- fuller normalization (diacritics) is settled by debate 01 (D-009), not here.
		require
			available: is_available
			word_not_empty: not a_english.is_empty
		local
			l_sql: STRING_8
			l_rows: ARRAYED_LIST [BIB_ENGLISH_ROW]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_bible_id: INTEGER_64
			l_bad: detachable STRING_8
			l_provenance: BIB_PROVENANCE
		do
			l_sql := "SELECT e.corpus_id AS bible_id, o.lemma_id, l.language AS headword_language, l.headword, l.translit, wb.book_id, count(*) AS n FROM conc.token e JOIN conc.link k ON k.to_token = e.token_id AND k.kind LIKE 'translation:ENG-%%' JOIN conc.token o ON o.token_id = k.from_token JOIN conc.lemma l ON l.lemma_id = o.lemma_id JOIN conc.unit u ON u.unit_id = o.unit_id JOIN conc.work_book wb ON wb.work_id = u.work_id WHERE e.search = ? GROUP BY e.corpus_id, o.lemma_id, wb.book_id ORDER BY e.corpus_id, n DESC, o.lemma_id, wb.book_id"
			run_query (l_sql, {ARRAY [detachable ANY]} <<a_english.to_string_32.as_lower>>)
			if attached last_rows as al_rows then
				create l_rows.make (al_rows.rows.count)
				create l_citations.make (2)
				across al_rows.rows as ic until l_bad /= Void loop
					l_bible_id := ic.integer_64_value ("bible_id")
					if ic.string_value ("translit").is_empty or ic.integer_value ("book_id") <= 0 or ic.integer_64_value ("lemma_id") <= 0 or not is_original (ic.string_value ("headword_language").to_string_8) then
						l_bad := "An English link in the concordance pack leads to no Hebrew, Aramaic or Greek headword with a transliteration and a book (lemma " + ic.integer_64_value ("lemma_id").out + ")."
					else
						l_provenance := provenance_of_id (l_bible_id)
						l_rows.extend (create {BIB_ENGLISH_ROW}.make (a_english, corpus_code_of_id (l_bible_id), ic.integer_64_value ("lemma_id"), ic.string_value ("headword"), ic.string_value ("translit"), ic.integer_value ("book_id"), ic.integer_64_value ("n"), l_provenance))
						cite (l_citations, l_provenance)
					end
				end
				if attached l_bad as al_bad then
					create Result.make_failure (method ("english_rows", l_sql, "", a_english, 0), create {BIB_ERROR}.make ({BIB_ERROR}.Schema_mismatch, al_bad))
				else
					if l_citations.is_empty then
						cite (l_citations, first_provenance)
					end
					create Result.make_success (method ("english_rows", l_sql, "", a_english, l_rows.count), l_citations, l_rows)
				end
			else
				create Result.make_failure (method ("english_rows", l_sql, "", a_english, 0), query_error)
			end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("english_rows")
			every_row_for_word: Result.is_success implies across 1 |..| Result.count as l_i all Result.item (l_i).english.same_string_general (a_english) end
			fact_closure: Result.is_fact_closed
		end

	verse_words (a_ref: BIB_REF; a_corpus_code: READABLE_STRING_8): BIB_LIST_RESULT [BIB_VERSE_WORD]
			-- Every word of `a_ref' in corpus `a_corpus_code', in order (the SQL of BIB_VERSE_WORDS).
			-- Ruling 1.1: the stored `token.lemma_basis' is `<kind>:<source>' (for example
			-- "tagged:MACULA-Hebrew", "computed:spacy-lemma"); each word is built with the KIND
			-- only, the text before the colon, so BIB_VERSE_WORD sees its domain vocabulary
			-- (tagged, computed, aligned, xref, none), never storage spelling. The book is found
			-- through the pack's `work_book' keys (FR-024). The default recension only, for now
			-- (2026-10-26): an LXX book kept only in recensions answers no words yet. The morphemes
			-- of one word share its position (MACULA: Genesis 1:1 begins with two tokens at
			-- position 1), so positions never decrease, and token order breaks the tie.
		require
			available: is_available
			corpus_known: has_corpus (a_corpus_code)
		local
			l_sql: STRING_8
			l_words: ARRAYED_LIST [BIB_VERSE_WORD]
			l_provenance: BIB_PROVENANCE
			l_bad: detachable STRING_8
			l_language, l_kind: STRING_8
			l_surface, l_translit: STRING_32
			l_lemma, l_previous: INTEGER_64
			l_position: INTEGER
		do
			l_sql := "SELECT t.pos, t.language, t.surface, t.translit, t.lemma_id, t.lemma_basis FROM conc.token t JOIN conc.unit u ON u.unit_id = t.unit_id JOIN conc.work_book wb ON wb.work_id = u.work_id WHERE t.corpus_id = ? AND wb.book_id = ? AND u.div1 = ? AND u.div2 = ? AND u.recension = '' ORDER BY t.pos, t.token_id"
			run_query (l_sql, {ARRAY [detachable ANY]} <<corpus_id (a_corpus_code), a_ref.book_id, a_ref.chapter.out, a_ref.verse.out>>)
			l_provenance := provenance_of (a_corpus_code)
			if attached last_rows as al_rows then
				create l_words.make (al_rows.rows.count)
				across al_rows.rows as ic until l_bad /= Void loop
					l_position := ic.integer_value ("pos")
					l_language := ic.string_value ("language").to_string_8
					l_surface := ic.string_value ("surface")
					l_translit := ic.string_value ("translit")
					l_lemma := ic.integer_64_value ("lemma_id").max (0)
					if l_lemma = 0 then
						l_kind := "none"
					else
						l_kind := basis_kind (ic.string_value ("lemma_basis").to_string_8)
					end
					if l_position < 1 or l_position < l_previous or not is_concordance_language (l_language)
						or not is_translit_complete (l_language, l_surface, l_translit)
						or not is_known_basis (l_kind) or (l_kind.same_string ("none") and l_lemma /= 0)
					then
						l_bad := "A word of the verse breaks the pack's rules (position " + l_position.out + ")."
					else
						l_words.extend (create {BIB_VERSE_WORD}.make (l_position, l_language, l_surface, l_translit, l_lemma, l_kind, l_provenance))
						l_previous := l_position
					end
				end
				if attached l_bad as al_bad then
					create Result.make_failure (method ("verse_words", l_sql, a_corpus_code, verse_scope (a_ref), 0), create {BIB_ERROR}.make ({BIB_ERROR}.Schema_mismatch, al_bad))
				else
					create Result.make_success (method ("verse_words", l_sql, a_corpus_code, verse_scope (a_ref), l_words.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_words)
				end
			else
				create Result.make_failure (method ("verse_words", l_sql, a_corpus_code, verse_scope (a_ref), 0), query_error)
			end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("verse_words")
			positions_valid: Result.is_success implies across 1 |..| Result.count as l_i all Result.item (l_i).position >= 1 end
			in_word_order: across 1 |..| (Result.count - 1) as l_i all Result.item (l_i).position <= Result.item (l_i + 1).position end
			fact_closure: Result.is_fact_closed
		end

feature -- Dictionary meanings (P05.5)

	lexicon_entries (a_lemma_id: INTEGER_64): BIB_LIST_RESULT [BIB_LIBRARY_ENTRY]
			-- Every dictionary meaning of headword `a_lemma_id', each source in its own words, sense
			-- by sense: Abbott-Smith and BDB first, then LSJ, the UBS dictionaries and TBESH.
		require
			available: is_available
			id_positive: a_lemma_id > 0
		local
			l_entries: ARRAYED_LIST [BIB_LIBRARY_ENTRY]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_provenance: BIB_PROVENANCE
			l_title: STRING_32
		do
			run_query (Lexicon_sql, <<a_lemma_id>>)
			if attached last_rows as al_rows then
				create l_entries.make (al_rows.rows.count)
				create l_citations.make (4)
				across al_rows.rows as ic loop
					l_provenance := meaning_provenance (ic)
					cite (l_citations, l_provenance)
					l_title := ic.string_value ("gloss")
					if l_title.is_empty then
						l_title := ic.string_value ("label")
					end
					if l_title.is_empty then
						l_title := ic.string_value ("source_name")
					end
					if not l_title.is_empty and not ic.string_value ("source").is_empty then
						l_entries.extend (create {BIB_LIBRARY_ENTRY}.make (ic.string_value ("source").to_string_8, l_title, ic.string_value ("text"), l_provenance))
					end
				end
				if l_citations.is_empty then
					cite (l_citations, first_provenance)
				end
				create Result.make_success (method ("lexicon_entries", Lexicon_sql, "", "lemma " + a_lemma_id.out, l_entries.count), l_citations, l_entries)
			else
				create Result.make_failure (method ("lexicon_entries", Lexicon_sql, "", "lemma " + a_lemma_id.out, 0), query_error)
			end
		ensure
			named: Result.method.engine_feature.same_string_general ("lexicon_entries")
		end

	short_gloss (a_lemma_id: INTEGER_64): STRING_32
			-- A headword's one-line English meaning ("to love"): STEPBible's gloss, else a lexicon's
			-- first sense; empty when the pack has none.
		require
			available: is_available
			id_positive: a_lemma_id > 0
		do
			create Result.make_empty
			run_query (Gloss_sql, <<a_lemma_id>>)
			if attached last_rows as al_rows then
				across al_rows.rows as ic loop
					Result := ic.string_value ("gloss")
				end
			end
		end

feature {BIB_WORD_LOOKUP} -- Method records

	lookup_method (a_feature, a_query: STRING_8; a_corpus_code: READABLE_STRING_8; a_scope: READABLE_STRING_GENERAL; a_count: INTEGER_64): BIB_METHOD
			-- A method record in the pack's own form, for an answer the lookup assembles.
		require
			scope_not_empty: not a_scope.is_empty
		do
			Result := method (a_feature, a_query, a_corpus_code, a_scope, a_count)
		ensure
			named: Result.engine_feature.same_string_general (a_feature)
		end

feature -- Constants

	Pack_alias: STRING_8 = "conc"

	Max_page_size: INTEGER = 200

	Expected_user_version: INTEGER = 2
			-- The `user_version' a valid pack carries (FR-164); FR-165's builder stamps it. Version 2
			-- (2026-10-26) adds `lemma.translit_ascii', which `headwords_for_text' reads.

	Max_text_matches: INTEGER = 50
			-- Headwords `headwords_for_text' lists at most.

	Function_words: ARRAY [STRING_8]
			-- Little English words a word alignment links to a Hebrew or Greek verb or noun along with
			-- its real rendering; English at a glance holds them back.
		once
			Result := <<"a", "an", "the", "and", "or", "but", "of", "to", "in", "on", "at", "by", "for", "from", "with", "as", "into",
				"be", "is", "are", "was", "were", "been", "am", "have", "has", "had", "do", "did", "does", "will", "shall", "would", "should",
				"i", "me", "my", "we", "us", "our", "you", "your", "he", "him", "his", "she", "her", "it", "its", "they", "them", "their",
				"who", "whom", "which", "that", "this", "these", "those", "not", "no", "when", "yet", "so", "then", "there", "one", "about">>
		end

	Required_tables: ARRAY [STRING_8]
			-- Tables of pack schema v1 (research/17); `check_pack' refuses a pack missing one.
		once
			Result := <<"corpus", "work", "work_book", "unit", "lemma", "token", "link", "lemma_xref", "meaning_source", "lex_sense", "lemma_corpus_count", "lemma_english", "meta">>
		end

feature {NONE} -- Implementation

	corpus_codes: ARRAYED_LIST [STRING_8]
			-- The pack's corpus codes, read once by `check_pack'.

	has_meanings: BOOLEAN
			-- Does the pack hold dictionary meanings (`lex_sense' rows)? Read once by `check_pack'.

	edition_label_cache: STRING_32
			-- The pack's `meta' edition_label, read once by `check_pack'.

	first_missing_table (a_schema: SIMPLE_SQL_SCHEMA): detachable STRING_8
			-- The first of `Required_tables' the pack lacks; Void when it has them all.
		do
			across Required_tables as ic until Result /= Void loop
				if not a_schema.table_exists_in (Pack_alias, ic) then
					Result := ic
				end
			end
		end

	read_pack_facts (a_db: SIMPLE_SQL_DATABASE)
			-- Read the corpus codes, whether meanings exist and the edition label, once. A query
			-- SQLite refuses sets `pack_error', so the pack is never accepted with empty facts.
		do
			across a_db.query ("SELECT corpus_id, code, name, license, ship_class FROM " + Pack_alias + ".corpus ORDER BY corpus_id").rows as ic loop
				corpus_codes.extend (ic.string_value ("code").to_string_8)
				corpus_ids.force (ic.integer_64_value ("corpus_id"), corpus_codes.last)
				corpus_code_of.force (corpus_codes.last, ic.integer_64_value ("corpus_id"))
				corpus_names.force (ic.string_value ("name"), corpus_codes.last)
				if ic.integer_64_value ("corpus_id") > 0 and not ic.string_value ("code").is_empty then
					corpus_provenances.force (corpus_provenance (ic.integer_64_value ("corpus_id"), ic.string_value ("code"), ic.string_value ("name"), ic.string_value ("license"), ic.string_value ("ship_class")), ic.integer_64_value ("corpus_id"))
				end
			end
			note_failure (a_db)
			has_meanings := not a_db.query ("SELECT 1 FROM " + Pack_alias + ".lex_sense LIMIT 1").rows.is_empty
			note_failure (a_db)
			across a_db.query ("SELECT value FROM " + Pack_alias + ".meta WHERE key = 'edition_label'").rows as ic loop
				edition_label_cache := ic.string_value ("value")
			end
			note_failure (a_db)
		end

	note_failure (a_db: SIMPLE_SQL_DATABASE)
			-- Keep the first refused query of `check_pack' as `pack_error'.
		do
			if a_db.has_error and pack_error = Void then
				create pack_error.make_with_details ({BIB_ERROR}.Database_problem, "The concordance pack cannot be read.", sqlite_message (a_db, pack_path))
			end
		ensure
			first_kept: old pack_error /= Void implies pack_error = old pack_error
		end

	corpus_ids: HASH_TABLE [INTEGER_64, STRING_8]
			-- Corpus id by code, read once by `check_pack'.

	corpus_code_of: HASH_TABLE [STRING_8, INTEGER_64]
			-- Corpus code by id, read once by `check_pack'.

	corpus_names: HASH_TABLE [STRING_32, STRING_8]
			-- Each corpus's name by code, read once by `check_pack'.

	corpus_provenances: HASH_TABLE [BIB_PROVENANCE, INTEGER_64]
			-- Each corpus's provenance from its own license and ship class (NFR-007), by id.

	corpus_provenance (a_id: INTEGER_64; a_code, a_name, a_license, a_ship_class: STRING_32): BIB_PROVENANCE
			-- Provenance of corpus `a_id': its license text and its ship class as the caveat.
		require
			id_positive: a_id > 0
			code_not_empty: not a_code.is_empty
		local
			l_ship: STRING_32
			l_identifier: STRING_32
			l_license: BIB_LICENSE
		do
			l_ship := a_ship_class.as_lower
			if a_license.is_empty then
				l_identifier := a_code
			else
				l_identifier := a_license
			end
			create l_license.make (l_identifier, l_ship.has_substring ("_nc"), l_ship.has_substring ("share_alike"), l_ship.has_substring ("restricted") or l_ship.has_substring ("verify"), a_license)
			create Result.make (a_id, {STRING_32} "conc:" + a_code, a_name, l_license, a_ship_class)
		end

	corpus_id (a_code: READABLE_STRING_8): INTEGER_64
			-- Id of corpus `a_code'; 0 when the pack does not list it.
		do
			Result := corpus_ids.item (a_code.to_string_8)
		end

	corpus_code_of_id (a_id: INTEGER_64): STRING_8
			-- Code of corpus `a_id', or its number when the pack does not list it.
		do
			if attached corpus_code_of.item (a_id) as al_code then
				Result := al_code
			else
				Result := a_id.out
			end
		end

	provenance_of (a_code: READABLE_STRING_8): BIB_PROVENANCE
			-- Provenance of corpus `a_code'.
		do
			Result := provenance_of_id (corpus_id (a_code))
		end

	provenance_of_id (a_id: INTEGER_64): BIB_PROVENANCE
			-- Provenance of corpus `a_id', or of the pack's first corpus when it does not list it.
		do
			if attached corpus_provenances.item (a_id) as al_provenance then
				Result := al_provenance
			else
				Result := first_provenance
			end
		end

	first_provenance: BIB_PROVENANCE
			-- Provenance of the pack's first corpus (`check_pack' refuses a pack listing none). The
			-- fallback is made once per check, so a citation list de-duplicates it (design scan 29).
		do
			if not corpus_codes.is_empty and then attached corpus_provenances.item (corpus_id (corpus_codes.first)) as al_provenance then
				Result := al_provenance
			elseif attached fallback_provenance as al_fallback then
				Result := al_fallback
			else
				create Result.make (1, {STRING_32} "conc", edition_or_pack, create {BIB_LICENSE}.make ({STRING_32} "unknown", False, False, True, {STRING_32} ""), {STRING_32} "no corpus listed")
				fallback_provenance := Result
			end
		end

	fallback_provenance: detachable BIB_PROVENANCE
			-- `first_provenance' when the pack lists no corpus; cleared by `check_pack'.

	Verse_word_tokens_sql: STRING_8 = "SELECT t.token_id FROM conc.token t JOIN conc.unit u ON u.unit_id = t.unit_id JOIN conc.work_book wb ON wb.work_id = u.work_id WHERE t.corpus_id = ? AND wb.book_id = ? AND u.div1 = ? AND u.div2 = ? AND u.recension = '' AND t.surface = ? ORDER BY t.pos, t.token_id"
			-- One English word's tokens in a verse, in reading order.

	Linked_headwords_sql: STRING_8 = "SELECT DISTINCT l.lemma_id, l.language, l.headword, l.translit, l.pron, l.n_tokens, (SELECT c.corpus_id FROM conc.lemma_corpus_count c WHERE c.lemma_id = l.lemma_id ORDER BY c.n DESC, c.corpus_id LIMIT 1) AS top_corpus FROM conc.link k JOIN conc.token o ON o.token_id = k.from_token JOIN conc.lemma l ON l.lemma_id = o.lemma_id WHERE k.to_token = ? AND k.kind = ? AND l.language IN ('hbo', 'arc', 'grc') ORDER BY l.n_tokens DESC, l.lemma_id"
			-- The headwords an English token translates (the columns of `Entry_columns').

	Entry_columns: STRING_8 = "l.lemma_id, l.language, l.headword, l.translit, l.pron, l.n_tokens, (SELECT c.corpus_id FROM conc.lemma_corpus_count c WHERE c.lemma_id = l.lemma_id ORDER BY c.n DESC, c.corpus_id LIMIT 1) AS top_corpus"
			-- A headword's columns over `conc.lemma l', with the corpus where it occurs most: its
			-- tagging is that corpus's, so that corpus is its provenance. In the same statement, so
			-- the method record holds every query an answer ran (NFR-006; design scan 28).

	entry_from_row (a_row: SIMPLE_SQL_ROW): detachable BIB_WORD_ENTRY
			-- The heading `a_row' (selected with `Entry_columns') holds; Void unless it is an
			-- original-language headword with a headword and a transliteration (BIB_WORD_ENTRY's
			-- creator requires both). Pure: no SQL.
		local
			l_id: INTEGER_64
			l_language: STRING_8
		do
			l_id := a_row.integer_64_value ("lemma_id")
			l_language := a_row.string_value ("language").to_string_8
			if l_id > 0 and is_original (l_language) and not a_row.string_value ("headword").is_empty and not a_row.string_value ("translit").is_empty then
				create Result.make (l_id, l_language, a_row.string_value ("headword"), a_row.string_value ("translit"), a_row.string_value ("pron"), a_row.integer_64_value ("n_tokens").max (0), provenance_of_id (a_row.integer_64_value ("top_corpus")))
			end
		ensure
			same_id: attached Result as r implies r.lemma_id = a_row.integer_64_value ("lemma_id")
		end

	entries_result (a_feature, a_sql: STRING_8; a_scope: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_WORD_ENTRY]
			-- The headwords in `last_rows' (selected with `Entry_columns'), or the failure: a row that
			-- is no original-language headword with a transliteration fails the answer, naming it.
		require
			scope_not_empty: not a_scope.is_empty
		local
			l_entries: ARRAYED_LIST [BIB_WORD_ENTRY]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_bad: detachable STRING_8
		do
			if attached last_rows as al_rows then
				create l_entries.make (al_rows.rows.count)
				create l_citations.make (2)
				across al_rows.rows as ic until l_bad /= Void loop
					if attached entry_from_row (ic) as al_entry then
						l_entries.extend (al_entry)
						cite (l_citations, al_entry.provenance)
					else
						l_bad := "Headword " + ic.integer_64_value ("lemma_id").out + " is not a Hebrew, Aramaic or Greek headword with a transliteration."
					end
				end
				if attached l_bad as al_bad then
					create Result.make_failure (method (a_feature, a_sql, "", a_scope, 0), create {BIB_ERROR}.make ({BIB_ERROR}.Schema_mismatch, al_bad))
				else
					if l_citations.is_empty then
						cite (l_citations, first_provenance)
					end
					create Result.make_success (method (a_feature, a_sql, "", a_scope, l_entries.count), l_citations, l_entries)
				end
			else
				create Result.make_failure (method (a_feature, a_sql, "", a_scope, 0), query_error)
			end
		ensure
			named: Result.method.engine_feature.same_string_general (a_feature)
		end

	without_hebrew_points (a_text: STRING_32): STRING_32
			-- `a_text' without Hebrew points and cantillation marks (U+0591 to U+05C7), as `lemma.search' holds it.
		do
			create Result.make (a_text.count)
			across a_text as ic loop
				if ic.natural_32_code < 0x0591 or ic.natural_32_code > 0x05C7 then
					Result.append_character (ic)
				end
			end
		ensure
			no_longer: Result.count <= a_text.count
		end

	Place_select: STRING_8 = "SELECT t.token_id, t.language, t.surface, t.translit, w.name AS work_name, u.div1, u.div2, u.recension, coalesce(wb.book_id, 0) AS book_id FROM conc.token t JOIN conc.unit u ON u.unit_id = t.unit_id JOIN conc.work w ON w.work_id = u.work_id LEFT JOIN conc.work_book wb ON wb.work_id = u.work_id"
			-- The every-place columns; each query adds its WHERE, ORDER BY and LIMIT.

	place_result (a_feature, a_sql: STRING_8; a_corpus_code: READABLE_STRING_8; a_scope: STRING_8): BIB_LIST_RESULT [BIB_PLACE_ROW]
			-- The place rows in `last_rows', or the failure: a row that breaks BIB_PLACE_ROW's rules
			-- fails the whole answer (Schema_mismatch), never the engine.
		local
			l_rows: ARRAYED_LIST [BIB_PLACE_ROW]
			l_provenance: BIB_PROVENANCE
			l_bad: detachable STRING_8
			l_language: STRING_8
			l_surface, l_translit: STRING_32
		do
			l_provenance := provenance_of (a_corpus_code)
			if attached last_rows as al_rows then
				create l_rows.make (al_rows.rows.count)
				across al_rows.rows as ic until l_bad /= Void loop
					l_language := ic.string_value ("language").to_string_8
					l_surface := ic.string_value ("surface")
					l_translit := ic.string_value ("translit")
					if ic.integer_64_value ("token_id") <= 0 or not is_concordance_language (l_language) or not is_translit_complete (l_language, l_surface, l_translit) then
						l_bad := "Token " + ic.integer_64_value ("token_id").out + " in the concordance pack has no transliteration or a language the engine does not know."
					else
						l_rows.extend (create {BIB_PLACE_ROW}.make (ic.integer_64_value ("token_id"), l_language, reference_text (ic), l_surface, l_translit, l_provenance,
							ic.integer_value ("book_id"), plain_number (ic.string_value ("div1")), plain_number (ic.string_value ("div2"))))
					end
				end
				if attached l_bad as al_bad then
					create Result.make_failure (method (a_feature, a_sql, a_corpus_code, a_scope, 0), create {BIB_ERROR}.make ({BIB_ERROR}.Schema_mismatch, al_bad))
				else
					create Result.make_success (method (a_feature, a_sql, a_corpus_code, a_scope, l_rows.count), {ARRAY [BIB_PROVENANCE]} <<l_provenance>>, l_rows)
				end
			else
				create Result.make_failure (method (a_feature, a_sql, a_corpus_code, a_scope, 0), query_error)
			end
		ensure
			named: Result.method.engine_feature.same_string_general (a_feature)
		end

	plain_number (a_text: STRING_32): INTEGER
			-- `a_text' as a positive whole number (a chapter or verse); 0 when it is not one ("12a").
		do
			if a_text.is_integer and then a_text.to_integer > 0 then
				Result := a_text.to_integer
			end
		ensure
			not_negative: Result >= 0
		end

	reference_text (a_row: SIMPLE_SQL_ROW): STRING_32
			-- "Genesis 1:1", with the recension when the place has one.
		do
			Result := a_row.string_value ("work_name") + {STRING_32} " " + a_row.string_value ("div1") + {STRING_32} ":" + a_row.string_value ("div2")
			if not a_row.string_value ("recension").is_empty then
				Result := Result + {STRING_32} " (" + a_row.string_value ("recension") + {STRING_32} ")"
			end
		ensure
			not_empty: not Result.is_empty
		end

	verse_scope (a_ref: BIB_REF): STRING_8
			-- The method's scope line for a verse lookup.
		do
			Result := "book " + a_ref.book_id.out + ", chapter " + a_ref.chapter.out + ", verse " + a_ref.verse.out
		end

	edition_or_pack: STRING_32
			-- The pack's edition label for the method record, or "concordance pack" before one is read.
		do
			if edition_label_cache.is_empty then
				Result := {STRING_32} "concordance pack"
			else
				Result := edition_label_cache
			end
		end

	query_failed_message: STRING_8 = "A concordance query failed."
	not_open_message: STRING_8 = "The concordance pack is not open."
			-- The pack's words around SQLite's own (BIB_SQLITE_QUERYING).

	method_edition: STRING_32
			-- The pack's edition for its method records.
		do
			Result := edition_or_pack
		end

	meaning_provenance (a_row: SIMPLE_SQL_ROW): BIB_PROVENANCE
			-- The provenance of a dictionary meaning: its `meaning_source' row (keys from 1000).
		local
			l_license_id: STRING_32
		do
			l_license_id := a_row.string_value ("license")
			if l_license_id.is_empty then
				l_license_id := {STRING_32} "unknown"
			end
			create Result.make (1000 + a_row.integer_64_value ("source_row"), {STRING_32} "conc.db meaning_source " + a_row.string_value ("source"),
				edition_text (a_row.string_value ("source_name"), a_row.string_value ("year")),
				create {BIB_LICENSE}.make (l_license_id, False, False, not a_row.string_value ("ship_class").same_string_general ("open"), a_row.string_value ("credit")), "")
		end

	edition_text (a_name, a_year: STRING_32): STRING_32
			-- "Name (year)", or the name alone, or "dictionary" when it has none.
		do
			if a_name.is_empty then
				Result := {STRING_32} "dictionary"
			elseif a_year.is_empty then
				Result := a_name
			else
				Result := a_name + {STRING_32} " (" + a_year + {STRING_32} ")"
			end
		ensure
			not_empty: not Result.is_empty
		end

	Lexicon_sql: STRING_8 = "SELECT s.source, s.seq, coalesce(s.label, '') AS label, coalesce(s.gloss, '') AS gloss, coalesce(s.text, '') AS text, coalesce(m.name, '') AS source_name, coalesce(m.year, '') AS year, coalesce(m.license, '') AS license, coalesce(m.ship_class, '') AS ship_class, coalesce(m.credit, '') AS credit, coalesce(m.rowid, 0) AS source_row FROM conc.lex_sense s LEFT JOIN conc.meaning_source m ON m.code = s.source WHERE s.lemma_id = ? AND s.source <> 'STEP' ORDER BY CASE s.source WHEN 'AS1922' THEN 1 WHEN 'BDB1906' THEN 2 WHEN 'LSJ' THEN 3 WHEN 'ML1889' THEN 4 WHEN 'SDGNT' THEN 5 WHEN 'SDBH' THEN 6 WHEN 'TBESH' THEN 7 ELSE 9 END, s.source, s.seq"

	Gloss_sql: STRING_8 = "SELECT coalesce(gloss, '') AS gloss FROM conc.lex_sense WHERE lemma_id = ? AND coalesce(gloss, '') <> '' AND source IN ('STEP', 'AS1922', 'BDB1906', 'SDGNT', 'SDBH', 'TBESH') ORDER BY CASE source WHEN 'STEP' THEN 1 WHEN 'AS1922' THEN 2 WHEN 'BDB1906' THEN 3 ELSE 4 END, seq LIMIT 1"

	pack_path: STRING_32
			-- The attached pack's file, for error details.
		do
			if attached sources.attached_path (Pack_alias) as al_path then
				Result := al_path
			else
				Result := {STRING_32} "(no pack attached)"
			end
		end

	sources: BIB_SOURCE_SET

end
