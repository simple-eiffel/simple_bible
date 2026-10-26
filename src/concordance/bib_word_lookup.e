note
	description: "[
		The word view (D-021, debate 05b). Assembles the heading, the place total and the
		first page of places from the pack reader, sections in the approved order.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_LOOKUP

create
	make

feature {NONE} -- Initialization

	make (a_pack: BIB_CONC_PACK)
		do
			pack := a_pack
		ensure
			pack_set: pack = a_pack
		end

feature -- Query

	view (a_lemma_id: INTEGER_64; a_corpus_code: READABLE_STRING_8): BIB_WORD_VIEW
			-- The word view of headword `a_lemma_id'.
		require
			available: pack.is_available
			id_positive: a_lemma_id > 0
			corpus_known: pack.has_corpus (a_corpus_code)
		local
			l_first: BIB_LIST_RESULT [BIB_PLACE_ROW]
			l_citations: ARRAYED_LIST [BIB_PROVENANCE]
			l_scope: STRING_8
			i: INTEGER
		do
			l_scope := "lemma " + a_lemma_id.out
			if attached pack.word_entry (a_lemma_id) as al_entry then
				if attached pack.place_total (a_lemma_id, a_corpus_code) as al_total then
					l_first := pack.place_page (a_lemma_id, a_corpus_code, 0, pack.Max_page_size)
					if not l_first.is_success then
						create Result.make_failure (view_method (a_corpus_code, l_scope, 0), failure_of (l_first))
					elseif l_first.count > al_total.value then
							-- The builder's count disagrees with the pack's rows (design scan 28).
						create Result.make_failure (view_method (a_corpus_code, l_scope, 0), create {BIB_ERROR}.make ({BIB_ERROR}.Schema_mismatch, "The concordance pack's count for this word is smaller than its first page of places."))
					else
						create l_citations.make (l_first.citation_count + 2)
						cite (l_citations, al_entry.provenance)
						cite (l_citations, al_total.provenance)
						from i := 1 until i > l_first.citation_count loop
							cite (l_citations, l_first.citation (i))
							i := i + 1
						end
						create Result.make_success (view_method (a_corpus_code, l_scope, al_total.value), l_citations, al_entry, al_total, l_first)
					end
				else
					create Result.make_failure (view_method (a_corpus_code, l_scope, 0), create {BIB_ERROR}.make ({BIB_ERROR}.Database_problem, "The concordance pack's count for this word cannot be read."))
				end
			else
				create Result.make_failure (view_method (a_corpus_code, l_scope, 0), create {BIB_ERROR}.make ({BIB_ERROR}.Not_found, "The concordance has no Hebrew, Aramaic or Greek headword with this number."))
			end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("word_view")
			same_headword: attached Result.entry as e implies e.lemma_id = a_lemma_id
			first_page_bounded: attached Result.first_places as p implies p.count <= pack.Max_page_size
			approved_order: Result.is_success implies Result.is_in_approved_order
			fact_closure: Result.is_fact_closed
		end

feature -- Access

	pack: BIB_CONC_PACK
			-- The pack read (exported: preconditions use it).

feature {NONE} -- Implementation

	View_query: STRING_8 = "word_entry (lemma); place_total (lemma, corpus); place_page (lemma, corpus, 0, 200)"
			-- The pack queries one word view runs, in order; each answer's own method holds its SQL.

	view_method (a_corpus_code: READABLE_STRING_8; a_scope: STRING_8; a_total: INTEGER_64): BIB_METHOD
			-- The word view's method record.
		do
			Result := pack.lookup_method ("word_view", View_query, a_corpus_code, a_scope, a_total)
		ensure
			named: Result.engine_feature.same_string_general ("word_view")
		end

	failure_of (a_answer: BIB_ENGINE_RESULT): BIB_ERROR
			-- The error of a failed `a_answer'.
		require
			failed: not a_answer.is_success
		do
			if attached a_answer.error as al_error then
				Result := al_error
			else
				create Result.make ({BIB_ERROR}.Database_problem, "A concordance query failed.")
			end
		end

	cite (a_citations: ARRAYED_LIST [BIB_PROVENANCE]; a_provenance: BIB_PROVENANCE)
			-- Add `a_provenance' to `a_citations' unless it is already there.
		do
			if not across a_citations as ic some ic = a_provenance end then
				a_citations.extend (a_provenance)
			end
		ensure
			cited: across a_citations as ic some ic = a_provenance end
		end

end
