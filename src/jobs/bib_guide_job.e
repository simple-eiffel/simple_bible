note
	description: "Builds guide sections one at a time (one section per chunk); text-first mode excludes commentary, author and lens sections."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GUIDE_JOB

inherit
	BIB_JOB [BIB_GUIDE]

create {BIB_GUIDE_ASSEMBLER}
	make

feature {NONE} -- Initialization

	make (a_kind: INTEGER; a_text_first: BOOLEAN; a_planned_kinds: ITERABLE [INTEGER]; a_bible: SIMPLE_BIBLE)
		require
			kind_valid: a_kind >= {BIB_GUIDE}.Passage_guide and a_kind <= {BIB_GUIDE}.Word_journey
		do
			kind := a_kind
			is_text_first := a_text_first
			bible := a_bible
			create planned_kinds.make (8)
			create excluded_kinds.make (3)
			if a_text_first then
				excluded_kinds.extend ({BIB_GUIDE_SECTION}.Section_library)
				excluded_kinds.extend ({BIB_GUIDE_SECTION}.Section_author)
				excluded_kinds.extend ({BIB_GUIDE_SECTION}.Section_lens)
			end
			across a_planned_kinds as k loop
				if not excluded_kinds.has (k) then
					planned_kinds.extend (k)
				end
			end
			chunk_total := planned_kinds.count
		ensure
			unstarted: not is_started
			text_first_excludes_commentary: a_text_first implies (excluded_kinds_model [{BIB_GUIDE_SECTION}.Section_library]
				and excluded_kinds_model [{BIB_GUIDE_SECTION}.Section_author] and excluded_kinds_model [{BIB_GUIDE_SECTION}.Section_lens])
			nothing_excluded_planned: across planned_kinds as k all not excluded_kinds_model [k] end
		end

feature -- Access

	kind: INTEGER
	is_text_first: BOOLEAN

feature -- Execution

	step
		do
			-- Phase 4: build the next planned section from engine results only.
		end

feature -- Result

	result_value: BIB_GUIDE
		do
			check implemented_in_phase_4: False then end
		ensure then
			text_first_respected: is_text_first implies not (Result.has_section_kind ({BIB_GUIDE_SECTION}.Section_library)
				or Result.has_section_kind ({BIB_GUIDE_SECTION}.Section_author) or Result.has_section_kind ({BIB_GUIDE_SECTION}.Section_lens))
		end

feature -- Model

	excluded_kinds_model: MML_SET [INTEGER]
		do
			create Result
			across excluded_kinds as k loop
				Result := Result & k
			end
		end

	planned_kinds_model: MML_SEQUENCE [INTEGER]
		do
			create Result
			across planned_kinds as k loop
				Result := Result & k
			end
		end

feature {NONE} -- Implementation

	bible: SIMPLE_BIBLE
	planned_kinds: ARRAYED_LIST [INTEGER]
	excluded_kinds: ARRAYED_LIST [INTEGER]

end
