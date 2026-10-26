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
	BIB_SQLITE_REPORTING

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
			create corpus_codes.make (0)
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
			has_meanings := False
			create edition_label_cache.make_empty
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
			-- Heading of `a_lemma_id'; Void when unknown.
		require
			available: is_available
			id_positive: a_lemma_id > 0
		do
			check implemented_in_phase_4: False then end
		ensure
			same_headword: attached Result as r implies r.lemma_id = a_lemma_id
		end

	headwords_for_strongs (a_key: BIB_STRONGS_KEY): BIB_LIST_RESULT [BIB_WORD_ENTRY]
			-- Headword candidates behind `a_key' through lemma_xref only.
		require
			available: is_available
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("headwords_for_strongs")
			fact_closure: Result.is_fact_closed
		end

	place_total (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8): BIB_FACT [INTEGER_64]
			-- Places of `a_lemma_id' in corpus `a_corpus_code'.
		require
			available: is_available
			id_positive: a_lemma_id > 0
			corpus_known: has_corpus (a_corpus_code)
		do
			check implemented_in_phase_4: False then end
		ensure
			non_negative: Result.value >= 0
		end

	place_page (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8; a_offset, a_limit: INTEGER): BIB_LIST_RESULT [BIB_PLACE_ROW]
			-- One page of the every-place list in token order.
		require
			available: is_available
			id_positive: a_lemma_id > 0
			corpus_known: has_corpus (a_corpus_code)
			offset_non_negative: a_offset >= 0
			limit_bounded: a_limit >= 1 and a_limit <= Max_page_size
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("place_page")
			bounded: Result.count <= a_limit
			ascending: across 1 |..| (Result.count - 1) as l_i all Result.item (l_i).token_id < Result.item (l_i + 1).token_id end
			page_size_right: Result.is_success implies Result.count = (place_total (a_lemma_id, a_corpus_code).value - a_offset).max (0).min (a_limit)
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
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("place_page_after")
			bounded: Result.count <= a_limit
			ascending: across 1 |..| (Result.count - 1) as l_i all Result.item (l_i).token_id < Result.item (l_i + 1).token_id end
			after_respected: across 1 |..| Result.count as l_i all Result.item (l_i).token_id > a_after_token_id end
			fact_closure: Result.is_fact_closed
		end

	english_rows (a_english: READABLE_STRING_GENERAL): BIB_LIST_RESULT [BIB_ENGLISH_ROW]
			-- Candidates behind `a_english', one row per original word and book (the SQL of BIB_ENGLISH_INDEX).
			-- Normalization of `a_english' (case, diacritics) is settled by debate 01 (D-009), not here.
		require
			available: is_available
			word_not_empty: not a_english.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("english_rows")
			every_row_for_word: Result.is_success implies across 1 |..| Result.count as l_i all Result.item (l_i).english.same_string_general (a_english) end
			fact_closure: Result.is_fact_closed
		end

	verse_words (a_ref: BIB_REF; a_corpus_code: READABLE_STRING_8): BIB_LIST_RESULT [BIB_VERSE_WORD]
			-- Every word of `a_ref' in corpus `a_corpus_code', in order (the SQL of BIB_VERSE_WORDS).
			-- Phase 4 (ruling 1.1): the stored `token.lemma_basis' is `<kind>:<source>' (for
			-- example "tagged:MACULA-Hebrew", "computed:spacy-lemma"). Each word is built with
			-- the KIND only, the text before the colon, so BIB_VERSE_WORD sees its domain
			-- vocabulary (tagged, computed, aligned, xref, none), never storage spelling.
		require
			available: is_available
			corpus_known: has_corpus (a_corpus_code)
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("verse_words")
			positions_valid: Result.is_success implies across 1 |..| Result.count as l_i all Result.item (l_i).position >= 1 end
			ascending: across 1 |..| (Result.count - 1) as l_i all Result.item (l_i).position < Result.item (l_i + 1).position end
			fact_closure: Result.is_fact_closed
		end

feature -- Constants

	Pack_alias: STRING_8 = "conc"

	Max_page_size: INTEGER = 200

	Expected_user_version: INTEGER = 1
			-- The `user_version' a valid pack carries (FR-164); FR-165's builder stamps it.

	Required_tables: ARRAY [STRING_8]
			-- Tables of pack schema v1 (research/17); `check_pack' refuses a pack missing one.
		once
			Result := <<"corpus", "work", "unit", "lemma", "token", "link", "lemma_xref", "meaning_source", "lex_sense", "lemma_corpus_count", "lemma_english", "meta">>
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
			across a_db.query ("SELECT code FROM " + Pack_alias + ".corpus ORDER BY corpus_id").rows as ic loop
				corpus_codes.extend (ic.string_value ("code").to_string_8)
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
