note
	description: "Assembles guides from engine results only (FR-110); text-first mode excludes commentary, author and lens sections (S9)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GUIDE_ASSEMBLER

create
	make

feature {NONE} -- Initialization

	make (a_bible: SIMPLE_BIBLE)
		do
			bible := a_bible
		end

feature -- Guides (factories: new, unstarted jobs)

	passage_guide (a_range: BIB_REF_RANGE; a_text_first: BOOLEAN): BIB_GUIDE_JOB
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
			text_first_excludes_commentary: a_text_first implies (Result.excluded_kinds_model [{BIB_GUIDE_SECTION}.Section_library]
				and Result.excluded_kinds_model [{BIB_GUIDE_SECTION}.Section_author] and Result.excluded_kinds_model [{BIB_GUIDE_SECTION}.Section_lens])
		end

	word_study (a_key: BIB_KEY): BIB_GUIDE_JOB
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
		end

	they_chose (a_mapped: BIB_MAPPED_REF): BIB_GUIDE_JOB
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
		end

	word_journey (a_key: BIB_KEY): BIB_GUIDE_JOB
		do
			check implemented_in_phase_4: False then end
		ensure
			not_started: not Result.is_started
		end

feature {NONE} -- Implementation

	bible: SIMPLE_BIBLE

end
