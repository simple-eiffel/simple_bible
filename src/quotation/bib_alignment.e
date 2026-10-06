note
	description: "[
		A precomputed token alignment of one quotation with its agreement marks,
		method, review state and the LXX edition it used. Only hand-verified LXX
		spans may carry a verdict (A-001).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ALIGNMENT

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_quotation_id: INTEGER_64; a_marks: ITERABLE [BIB_TEXT_SPAN]; a_method_label, a_lxx_edition: READABLE_STRING_GENERAL;
			a_hand_verified, a_from_uncollated_ocr: BOOLEAN; a_provenance: BIB_PROVENANCE)
		require
			quotation_positive: a_quotation_id > 0
			method_named: not a_method_label.is_empty
			edition_named: not a_lxx_edition.is_empty
		do
			quotation_id := a_quotation_id
			method_label := a_method_label.to_string_32
			lxx_edition := a_lxx_edition.to_string_32
			is_hand_verified := a_hand_verified
			lxx_from_uncollated_ocr := a_from_uncollated_ocr
			provenance := a_provenance
			create marks.make (8)
			across a_marks as m loop
				marks.extend (m)
			end
		end

feature -- Access

	quotation_id: INTEGER_64
	method_label: STRING_32
	lxx_edition: STRING_32
			-- e.g. "Swete".
	provenance: BIB_PROVENANCE

	mark_count: INTEGER
		do
			Result := marks.count
		end

feature -- Status

	is_hand_verified: BOOLEAN
	lxx_from_uncollated_ocr: BOOLEAN

feature -- Model

	marks_model: MML_SEQUENCE [BIB_TEXT_SPAN]
		do
			create Result
			across marks as m loop
				Result := Result & m
			end
		end

feature {NONE} -- Representation

	marks: ARRAYED_LIST [BIB_TEXT_SPAN]

invariant
	quotation_positive: quotation_id > 0
	method_named: not method_label.is_empty
	edition_named: not lxx_edition.is_empty

end
