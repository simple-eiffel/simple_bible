note
	description: "[
		FTS5 over the normalized columns, regex and key search, chunked by book
		(A-002). The query goes through the same normalizer the build used, so a
		copied phrase always finds its own verse (AC-1a-20, AC-1a-21). No AI
		path is reachable from search (Q-14, AC-1a-54).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SEARCH_ENGINE

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_normalizers: BIB_NORMALIZER_SET)
		do
			sources := a_sources
			normalizers := a_normalizers
		ensure
			normalizers_set: normalizers = a_normalizers
		end

feature -- Access

	normalizers: BIB_NORMALIZER_SET

feature -- Search

	start_search (a_query: BIB_QUERY): BIB_SEARCH_JOB
			-- A new, unstarted job streaming the hits of `a_query'.
		require
			query_valid: a_query.is_valid
			scope_bounded_for_regex: a_query.has_regex implies (a_query.scope.version_count = 1 or a_query.scope.is_user_confirmed_wide)
			keys_resolve: across a_query.key_clauses as c all keys_resolve (c) end
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
			chunked_by_book: Result.chunk_total = a_query.scope.book_count
		end

	search_form (a_text: READABLE_STRING_GENERAL; a_language: READABLE_STRING_8): STRING_32
			-- The normalized form of `a_text' the FTS tables are searched with (same normalizer as the build).
		require
			language_not_empty: not a_language.is_empty
		do
			Result := normalizers.for_language (a_language).normalized (a_text)
		ensure
			same_as_build: Result.same_string (normalizers.for_language (a_language).normalized (a_text))
		end

	diff (a_mapped: BIB_MAPPED_REF; a_base, a_other: STRING_8): BIB_LIST_RESULT [BIB_DIFF_SPAN]
			-- Word diff of `a_mapped' between two versions (FR-114).
		require
			different_versions: not a_base.same_string (a_other)
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("diff")
			fact_closure: Result.is_fact_closed
		end

feature -- Status

	keys_resolve (a_clause: BIB_QUERY_CLAUSE): BOOLEAN
			-- Does the key of `a_clause' exist in core.db?
		require
			key_clause: a_clause.is_key_clause
		do
			-- Phase 4
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
