note
	description: "Pages of hits, per-book counts and the full hit count (AC-1a-56), with method and citations (S-29)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_SEARCH_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_success, make_failure

feature {NONE} -- Initialization

	make_success (a_query_text: READABLE_STRING_GENERAL; a_hits: ITERABLE [BIB_HIT]; a_per_book: BIB_COUNT_TABLE; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			cited: across a_citations as c some True end
		do
			query_text := a_query_text.to_string_32
			per_book := a_per_book
			create hits.make (32)
			across a_hits as h loop
				hits.extend (h)
			end
			set_success (a_method, a_citations)
		ensure
			success: is_success
		end

	make_failure (a_query_text: READABLE_STRING_GENERAL; a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			query_text := a_query_text.to_string_32
			create per_book.make
			create hits.make (0)
			set_failure (a_method, a_error)
		ensure
			failed: not is_success
		end

feature -- Access

	query_text: STRING_32
	per_book: BIB_COUNT_TABLE

	hit_count: INTEGER
			-- Hits held in this result.
		do
			Result := hits.count
		end

	total_hits: INTEGER_64
			-- Full hit count over the scope.
		do
			Result := per_book.total
		end

	hit (i: INTEGER): BIB_HIT
		require
			in_range: i >= 1 and i <= hit_count
		do
			Result := hits [i]
		end

feature -- Model

	hits_model: MML_SEQUENCE [BIB_HIT]
		do
			create Result
			across hits as h loop
				Result := Result & h
			end
		end

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		do
			create Result
			across hits as h loop
				Result := Result & h
			end
		end

feature {NONE} -- Representation

	hits: ARRAYED_LIST [BIB_HIT]

invariant
	held_within_total: hit_count <= total_hits

end
