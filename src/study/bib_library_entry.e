note
	description: "A commentary, lexicon, dictionary or devotional entry (neutral text body in 1a; rich text with GW-13 in 1b) with provenance."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LIBRARY_ENTRY

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_resource: READABLE_STRING_8; a_title, a_body: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
		require
			resource_not_empty: not a_resource.is_empty
			title_not_empty: not a_title.is_empty
		do
			resource_code := a_resource.to_string_8
			title := a_title.to_string_32
			body := a_body.to_string_32
			provenance := a_provenance
		end

feature -- Access

	resource_code: STRING_8
	title: STRING_32
	body: STRING_32
	provenance: BIB_PROVENANCE

invariant
	resource_not_empty: not resource_code.is_empty
	title_not_empty: not title.is_empty

end
