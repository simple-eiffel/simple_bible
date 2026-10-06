note
	description: "[
		They Chose (FR-030): NT, LXX (Swete) and MT side by side with the
		computed agreement class and an edition note naming Swete, plus the OCR
		note for uncollated text. NO_DATA when not indexed or not aligned.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUOTATION_RESULT

inherit
	BIB_ENGINE_RESULT

create
	make_computed, make_no_data, make_failure

feature {NONE} -- Initialization

	make_computed (a_quotation: BIB_QUOTATION; a_alignment: BIB_ALIGNMENT; a_agreement: BIB_AGREEMENT_CLASS; a_verdict_line, a_edition_note: READABLE_STRING_GENERAL;
			a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
		require
			computed: not a_agreement.is_no_data
			edition_named: not a_edition_note.is_empty
			ocr_flagged: a_alignment.lxx_from_uncollated_ocr implies a_edition_note.has_substring ({BIB_TRUST_LABELS}.Ocr_note)
			cited: across a_citations as c some True end
		do
			quotation := a_quotation
			alignment := a_alignment
			agreement := a_agreement
			verdict_line := a_verdict_line.to_string_32
			edition_note := a_edition_note.to_string_32
			lxx_from_uncollated_ocr := a_alignment.lxx_from_uncollated_ocr
			set_success (a_method, a_citations)
		ensure
			success: is_success
		end

	make_no_data (a_quotation: detachable BIB_QUOTATION; a_edition_note: READABLE_STRING_GENERAL; a_method: BIB_METHOD; a_citations: ITERABLE [BIB_PROVENANCE])
			-- Not indexed, or not aligned: an answer saying there is no data.
		require
			edition_named: not a_edition_note.is_empty
			cited: across a_citations as c some True end
		do
			quotation := a_quotation
			create agreement.make_no_data
			create verdict_line.make_empty
			edition_note := a_edition_note.to_string_32
			set_success (a_method, a_citations)
		ensure
			no_data: agreement.is_no_data
		end

	make_failure (a_method: BIB_METHOD; a_error: BIB_ERROR)
		do
			create agreement.make_no_data
			create verdict_line.make_empty
			edition_note := {STRING_32} "Computed against Swete."
			set_failure (a_method, a_error)
		end

feature -- Access

	quotation: detachable BIB_QUOTATION
	alignment: detachable BIB_ALIGNMENT
	agreement: BIB_AGREEMENT_CLASS
	verdict_line: STRING_32
	edition_note: STRING_32
	lxx_from_uncollated_ocr: BOOLEAN

feature -- Model

	facts_model: MML_SEQUENCE [BIB_SOURCED]
		do
			create Result
			if attached quotation as q then
				Result := Result & q
			end
			if attached alignment as a then
				Result := Result & a
			end
		end

invariant
	edition_note_present: not edition_note.is_empty
	verdict_needs_alignment: not agreement.is_no_data implies alignment /= Void
	ocr_flagged: lxx_from_uncollated_ocr implies edition_note.has_substring ({BIB_TRUST_LABELS}.Ocr_note)

end
