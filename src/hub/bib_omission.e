note
	description: "[
		Why a verse has no text in a version; shown in place of the verse, never
		an empty string (FR-009, I-005, AC-1a-19): omitted in this edition (WH),
		absent from the edition, digital-text loss, not in this canon,
		quarantined (defect register class A).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_OMISSION

inherit
	BIB_ENUMERATION

create
	make

feature {NONE} -- Initialization

	make (a_code: INTEGER; a_reason_text: READABLE_STRING_GENERAL)
			-- Omission `a_code' with the text shown in place of the verse.
		require
			valid: is_valid_code (a_code)
			reason_given: not a_reason_text.is_empty
		do
			code := a_code
			reason_text := a_reason_text.to_string_32
		ensure
			code_set: code = a_code
			reason_set: reason_text.same_string_general (a_reason_text)
		end

feature -- Access

	reason_text: STRING_32
			-- e.g. "omitted in this edition (WH)", "not in this canon".

	label: STRING_32
		do
			Result := reason_text
		end

feature -- Status

	is_quarantined: BOOLEAN
		do
			Result := code = Quarantined
		end

	is_valid_code (a_code: INTEGER): BOOLEAN
		do
			Result := a_code >= Edition_omitted and a_code <= Quarantined
		end

feature -- Constants

	Edition_omitted: INTEGER = 1
	Edition_absent: INTEGER = 2
	Digital_text_loss: INTEGER = 3
	Not_in_canon: INTEGER = 4
	Quarantined: INTEGER = 5

invariant
	reason_given: not reason_text.is_empty
	edition_omission_worded: code = Edition_omitted implies reason_text.has_substring ({BIB_TRUST_LABELS}.Omitted_in_edition)
	canon_omission_worded: code = Not_in_canon implies reason_text.has_substring ({BIB_TRUST_LABELS}.Not_in_canon)

end
