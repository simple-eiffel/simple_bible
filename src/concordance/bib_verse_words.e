note
	description: "The verse lookup (D-021, debate 05b). A reference to every word in the verse, each a door to its word view."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_WORDS

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

	words (a_ref: BIB_REF; a_corpus_code: READABLE_STRING_8): BIB_LIST_RESULT [BIB_VERSE_WORD]
			-- Every word of `a_ref' in corpus `a_corpus_code', in order.
		require
			available: pack.is_available
			corpus_known: pack.has_corpus (a_corpus_code)
		do
			check implemented_in_phase_4: False then end
		ensure
			method_recorded: Result.method.engine_feature.same_string_general ("verse_words")
			positions_valid: Result.is_success implies across 1 |..| Result.count as l_i all Result.item (l_i).position >= 1 end
			fact_closure: Result.is_fact_closed
		end

feature -- Access

	pack: BIB_CONC_PACK
			-- The pack read (exported: preconditions use it).

end
