note
	description: "Divine-name spans by key; surface-form for Swete (I-P08, AC-1a-29: Gen 7:16 marks Elohim and YHWH)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_DIVINE_NAME_MARKER

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_normalizers: BIB_NORMALIZER_SET)
		do
			sources := a_sources
			normalizers := a_normalizers
		end

feature -- Query

	marks (a_mapped: BIB_MAPPED_REF; a_version: STRING_8): BIB_LIST_RESULT [BIB_NAME_MARK]
		do
			check implemented_in_phase_4: False then end
		ensure
			swete_is_surface_form: is_surface_form_version (a_version) implies
				across 1 |..| Result.count as i all Result.item (i).is_surface_form_match end
			method_recorded: Result.method.engine_feature.same_string_general ("divine_names")
			fact_closure: Result.is_fact_closed
		end

feature -- Status

	is_surface_form_version (a_version: STRING_8): BOOLEAN
			-- Must marks in `a_version' be found by surface form (no open morphology)?
		do
			-- Phase 4: not version_info (a_version).has_morphology
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
	normalizers: BIB_NORMALIZER_SET

end
