note
	description: "[
		One tagged claim of a commentary section: SOURCED (Larry's own words,
		`source_ref' names where) or DEDUCED (reasoned from his frameworks, not
		his words). The label travels with the claim everywhere; the window
		shows it on every claim (COMMENTARY and NEEDLE asked, 2026-10-27: sixty
		of Jude's claims are deductions and must never read as his).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_COMMENTARY_CLAIM

create
	make

feature {NONE} -- Initialization

	make (a_id, a_label, a_text, a_summary, a_source_ref: READABLE_STRING_GENERAL)
		require
			id_given: not a_id.is_empty
			labelled: a_label.same_string (Sourced) or a_label.same_string (Deduced)
		do
			claim_id := a_id.to_string_32
			label := a_label.to_string_8
			text := a_text.to_string_32
			summary := a_summary.to_string_32
			source_ref := a_source_ref.to_string_32
		ensure
			id_set: claim_id.same_string_general (a_id)
			label_set: label.same_string_general (a_label)
		end

feature -- Access

	claim_id: STRING_32
			-- As the text cites it, e.g. "S14.1" or "D11.9".
	label: STRING_8
			-- `Sourced' or `Deduced'.
	text: STRING_32
	summary: STRING_32
	source_ref: STRING_32
			-- Where in Larry's writings (private pack only).

	is_sourced: BOOLEAN
		do
			Result := label.same_string (Sourced)
		end

feature -- Constants

	Sourced: STRING_8 = "SOURCED"
	Deduced: STRING_8 = "DEDUCED"

invariant
	id_given: not claim_id.is_empty
	labelled: label.same_string (Sourced) or label.same_string (Deduced)

end
