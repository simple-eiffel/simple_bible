note
	description: "One rendering of a lemma in one version: the gloss, how often, and example verses (I-P09)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_RENDERING

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_gloss: READABLE_STRING_GENERAL; a_version: READABLE_STRING_8; a_count: INTEGER_64; a_examples: ITERABLE [INTEGER_64]; a_provenance: BIB_PROVENANCE)
		require
			gloss_not_empty: not a_gloss.is_empty
			version_not_empty: not a_version.is_empty
			counted: a_count > 0
		do
			gloss := a_gloss.to_string_32
			version_code := a_version.to_string_8
			count := a_count
			provenance := a_provenance
			create examples.make (3)
			across a_examples as e loop
				examples.extend (e)
			end
		end

feature -- Access

	gloss: STRING_32
	version_code: STRING_8
	count: INTEGER_64
	provenance: BIB_PROVENANCE

feature -- Model

	examples_model: MML_SEQUENCE [INTEGER_64]
			-- Example verses by hub id.
		do
			create Result
			across examples as e loop
				Result := Result & e
			end
		end

feature {NONE} -- Representation

	examples: ARRAYED_LIST [INTEGER_64]

invariant
	gloss_not_empty: not gloss.is_empty
	counted: count > 0

end
