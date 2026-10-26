note
	description: "[
		The concordance pack reader (debate 05b). One class owns every SQL statement against the
		attached concordance pack (alias "conc"), whichever file it is (conc.db or
		conc_dist.db). BIB_CONCORDANCE is untouched and keeps core-database counts.
		Headwords are keyed by lemma_id (INTEGER_64), never by Strong's.
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
		end

feature -- Status

	is_available: BOOLEAN
			-- Is a pack attached as `Pack_alias'?
		do
			Result := sources.is_attached_alias (Pack_alias)
		ensure
			definition: Result = sources.is_attached_alias (Pack_alias)
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
			page_size_right: Result.is_success implies Result.count = (place_total (a_lemma_id, a_corpus_code).value - a_offset).max (0).min (a_limit)
			fact_closure: Result.is_fact_closed
		end

feature -- Constants

	Pack_alias: STRING_8 = "conc"

	Max_page_size: INTEGER = 200

feature {BIB_ENGLISH_INDEX, BIB_VERSE_WORDS, BIB_WORD_LOOKUP} -- Implementation

	sources: BIB_SOURCE_SET

end
