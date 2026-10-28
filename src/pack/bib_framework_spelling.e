note
	description: "[
		One spelling that links to a framework (BIB_FRAMEWORK_PACK.aliases): "KACC",
		which links only followed by (TM) (`needs_mark'), or an alias such as "the
		JESUS Cornerstone", which links as written.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FRAMEWORK_SPELLING

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_spelling, a_id: READABLE_STRING_GENERAL; a_needs_mark: BOOLEAN; a_provenance: BIB_PROVENANCE)
			-- `a_spelling' links to framework `a_id'.
		require
			spelled: not a_spelling.is_empty
			id_usable: (create {BIB_FRAMEWORK_SCHEMA}).is_framework_id (a_id)
		do
			spelling := a_spelling.to_string_32
			id := a_id.to_string_32
			needs_mark := a_needs_mark
			provenance := a_provenance
		ensure
			spelling_set: spelling.same_string_general (a_spelling)
			id_set: id.same_string_general (a_id)
			mark_set: needs_mark = a_needs_mark
			provenance_set: provenance = a_provenance
		end

feature -- Access

	spelling: STRING_32
	id: STRING_32
	needs_mark: BOOLEAN
			-- Does it link only followed by (TM)?

	provenance: BIB_PROVENANCE

invariant
	spelled: not spelling.is_empty
	id_present: not id.is_empty

end
