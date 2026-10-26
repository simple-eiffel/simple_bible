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
		do
			check implemented_in_phase_4: False then end
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

end
