note
	description: "[
		A divine-name span with its legend reason. Marks found by surface form
		(Swete: no open morphology) carry the label "surface-form match"
		(AC-1a-29).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NAME_MARK

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_span: BIB_TEXT_SPAN; a_name_key: READABLE_STRING_GENERAL; a_legend_reason: READABLE_STRING_GENERAL; a_surface_form: BOOLEAN; a_provenance: BIB_PROVENANCE)
		require
			name_given: not a_name_key.is_empty
			reason_given: not a_legend_reason.is_empty
			surface_labeled: a_surface_form implies a_legend_reason.has_substring ({BIB_TRUST_LABELS}.Surface_form_label)
		do
			span := a_span
			name_key := a_name_key.to_string_32
			legend_reason := a_legend_reason.to_string_32
			is_surface_form_match := a_surface_form
			provenance := a_provenance
		end

feature -- Access

	span: BIB_TEXT_SPAN
	name_key: STRING_32
			-- "YHWH", "Elohim", "Adonai", "Kyrios", "Theos" ...
	legend_reason: STRING_32
	is_surface_form_match: BOOLEAN
	provenance: BIB_PROVENANCE

invariant
	reason_given: not legend_reason.is_empty
	surface_labeled: is_surface_form_match implies legend_reason.has_substring ({BIB_TRUST_LABELS}.Surface_form_label)

end
