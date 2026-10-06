note
	description: "[
		Unnamed quotations by n-gram shingles over normalized tokens (minimum 6,
		maximum shingle 14), reporting match length (port of scripture_detect.py,
		D-020).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUOTATION_DETECTOR

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_normalizers: BIB_NORMALIZER_SET)
			-- Create a detector over the shipped texts.
		do
			sources := a_sources
			normalizers := a_normalizers
		end

feature -- Detection

	quotations_in (a_text: READABLE_STRING_32; a_language: READABLE_STRING_8): ARRAYED_LIST [BIB_QUOTATION_MATCH]
			-- Candidate quotations in `a_text', in text order.
		require
			language_not_empty: not a_language.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			within_text: across Result as m all m.start + m.length - 1 <= a_text.count end
			never_evidence: across Result as m all not m.is_evidence end
		end

feature -- Constants

	Min_n: INTEGER = 6
	Max_n: INTEGER = 14

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
	normalizers: BIB_NORMALIZER_SET

end
