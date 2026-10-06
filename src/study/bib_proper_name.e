note
	description: "A TIPNR person or place with its references."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PROPER_NAME

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_GENERAL; a_kind: INTEGER; a_description: READABLE_STRING_GENERAL; a_references: ITERABLE [BIB_REF]; a_provenance: BIB_PROVENANCE)
		require
			name_not_empty: not a_name.is_empty
			kind_valid: a_kind = Person or a_kind = Place
		do
			name := a_name.to_string_32
			kind := a_kind
			description := a_description.to_string_32
			provenance := a_provenance
			create references.make (4)
			across a_references as r loop
				references.extend (r)
			end
		end

feature -- Access

	name: STRING_32
	kind: INTEGER
	description: STRING_32
	provenance: BIB_PROVENANCE

feature -- Model

	references_model: MML_SEQUENCE [BIB_REF]
		do
			create Result
			across references as r loop
				Result := Result & r
			end
		end

feature -- Constants

	Person: INTEGER = 1
	Place: INTEGER = 2

feature {NONE} -- Representation

	references: ARRAYED_LIST [BIB_REF]

invariant
	name_not_empty: not name.is_empty
	kind_valid: kind = Person or kind = Place

end
