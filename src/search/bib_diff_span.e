note
	description: "One run of a word diff between two versions of a verse, over normalized token keys (FR-114)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_DIFF_SPAN

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_kind: INTEGER; a_span: BIB_TEXT_SPAN; a_text: READABLE_STRING_32; a_provenance: BIB_PROVENANCE)
		require
			kind_valid: a_kind >= Same and a_kind <= Changed
		do
			kind := a_kind
			span := a_span
			text := a_text.to_string_32
			provenance := a_provenance
		ensure
			kind_set: kind = a_kind
		end

feature -- Access

	kind: INTEGER
	span: BIB_TEXT_SPAN
	text: STRING_32
	provenance: BIB_PROVENANCE

feature -- Constants

	Same: INTEGER = 1
	Added: INTEGER = 2
	Removed: INTEGER = 3
	Changed: INTEGER = 4

invariant
	kind_valid: kind >= Same and kind <= Changed

end
