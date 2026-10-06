note
	description: "[
		Computes the They Chose verdict from alignment rows (FR-030, AC-1a-27):
		Heb 8:8-12 against LXX (Swete) Jer 38:31-34 against MT Jer 31:31-34. An
		unindexed or unaligned quotation yields NO_DATA.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUOTATION_COMPARER

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_versification: BIB_VERSIFICATION_MAP)
		do
			versification := a_versification
			create index.make (a_sources)
		end

feature -- Access

	index: BIB_QUOTATION_INDEX
	versification: BIB_VERSIFICATION_MAP

feature -- Comparison

	compare (a_nt: BIB_MAPPED_REF): BIB_QUOTATION_RESULT
			-- They Chose for the quotation indexed at `a_nt'.
		do
			check implemented_in_phase_4: False then end
		ensure
			not_indexed_no_data: not index.has_quotation (a_nt) implies Result.agreement.is_no_data
			no_alignment_no_data: (index.has_quotation (a_nt) and not index.is_aligned (a_nt)) implies Result.agreement.is_no_data
			edition_named: not Result.edition_note.is_empty
			ocr_flagged: Result.lxx_from_uncollated_ocr implies Result.edition_note.has_substring ({BIB_TRUST_LABELS}.Ocr_note)
			method_recorded: Result.method.engine_feature.same_string_general ("quote")
			fact_closure: Result.is_fact_closed
		end

end
