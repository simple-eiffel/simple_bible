note
	description: "Runs a census on its own processor; freezes the definition at the first chunk. The face stores the run in user.db."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_CENSUS_JOB

inherit
	BIB_JOB [BIB_CENSUS_RUN]

create {BIB_CENSUS_ENGINE}
	make

feature {NONE} -- Initialization

	make (a_definition: BIB_CENSUS_DEFINITION; a_engine: BIB_CENSUS_ENGINE)
		require
			complete: a_definition.is_complete
			stored: a_definition.is_stored
		do
			definition := a_definition
			engine := a_engine
			chunk_total := a_definition.corpus.book_count
		ensure
			unstarted: not is_started
			chunked_by_book: chunk_total = a_definition.corpus.book_count
		end

feature -- Access

	definition: BIB_CENSUS_DEFINITION

feature -- Execution

	step
		do
			-- Phase 4: freeze on the first chunk; count one book.
		end

feature -- Result

	result_value: BIB_CENSUS_RUN
		do
			check implemented_in_phase_4: False then end
		ensure then
			is_frozen_now: definition.is_frozen
		end

feature {NONE} -- Implementation

	engine: BIB_CENSUS_ENGINE

end
