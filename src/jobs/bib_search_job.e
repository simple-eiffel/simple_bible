note
	description: "Streams the hits of a query or a key, one book per chunk, into its mailbox."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SEARCH_JOB

inherit
	BIB_JOB [BIB_SEARCH_RESULT]

create {BIB_SEARCH_ENGINE, BIB_CONCORDANCE}
	make_for_query, make_for_key

feature {NONE} -- Initialization

	make_for_query (a_query: BIB_QUERY; a_sources: BIB_SOURCE_SET)
		require
			query_valid: a_query.is_valid
		do
			query_text := a_query.text
			scope := a_query.scope
			sources := a_sources
			chunk_total := a_query.scope.book_count
		ensure
			unstarted: not is_started
			chunked_by_book: chunk_total = a_query.scope.book_count
		end

	make_for_key (a_key: BIB_KEY; a_scope: BIB_SEARCH_SCOPE; a_sources: BIB_SOURCE_SET)
		do
			query_text := a_key.text
			key := a_key
			scope := a_scope
			sources := a_sources
			chunk_total := a_scope.book_count
		ensure
			unstarted: not is_started
			chunked_by_book: chunk_total = a_scope.book_count
		end

feature -- Access

	query_text: STRING_32
	key: detachable BIB_KEY
	scope: BIB_SEARCH_SCOPE

feature -- Execution

	step
		do
			-- Phase 4: search one book, build a page.
		end

feature -- Result

	result_value: BIB_SEARCH_RESULT
		do
			check implemented_in_phase_4: False then end
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET

end
