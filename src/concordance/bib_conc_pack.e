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

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET)
		do
			sources := a_sources
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

	is_available: BOOLEAN
			-- Is a valid pack attached as `Pack_alias'? No SQL here: every lookup
			-- evaluates this, so the check runs once, in `check_pack' (ruling 3.3).
		do
			Result := is_attached and is_pack_valid
		ensure
			definition: Result = (sources.is_attached_alias (Pack_alias) and is_pack_valid)
		end

	has_corpus (a_code: READABLE_STRING_8): BOOLEAN
			-- Does the pack list corpus `a_code'?
		require
			available: is_available
		do
			-- Phase 4
		end

	has_layer (a_layer: READABLE_STRING_8): BOOLEAN
			-- Does the pack carry layer `a_layer' ("lxx", "bsb", "dictionaries")? conc_dist.db may not.
		require
			available: is_available
		do
			-- Phase 4
		end

feature -- Commands

	check_pack
			-- Validate the pack attached as `Pack_alias' once, at attach, and record
			-- the answer in `is_pack_valid' (FR-164).
		require
			pack_attached: is_attached
		do
			-- Phase 4 (2026-10-26): ask the sources' schema for `user_version_of (Pack_alias)'
			-- (simple_sql, ruling 3.3: PRAGMA conc.user_version, never the unqualified
			-- pragma, which reads the main database), compare it with `Expected_user_version',
			-- check the required tables, then set `is_pack_valid'. Until then a pack is
			-- never valid. conc.db reports user_version 0 until FR-165's builder stamp lands.
			is_pack_valid := False
		ensure
			valid_only_when_attached: is_pack_valid implies is_attached
		end

feature -- Access

	edition_label: STRING_32
			-- What the pack says it is (title bar / About); the engine never branches on it.
		require
			available: is_available
		do
			check implemented_in_phase_4: False then end
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

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
