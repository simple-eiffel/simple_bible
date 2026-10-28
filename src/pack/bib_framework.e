note
	description: "[
		One of Larry's FRAMEWORKS(TM) as the frameworks pack holds it (BIB_FRAMEWORK_SCHEMA):
		its name and full title, its tier and review status, the plain-reader hover
		text, and - when read whole (BIB_FRAMEWORK_PACK.framework) - its sections,
		the frameworks related to it and the commentary sections that use it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_FRAMEWORK

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_id, a_name: READABLE_STRING_GENERAL; a_mark: BOOLEAN; a_title, a_tier, a_status, a_hover: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Framework `a_id' named `a_name' (`a_mark': prose writes it with (TM)).
		require
			id_usable: (create {BIB_FRAMEWORK_SCHEMA}).is_framework_id (a_id)
			named: not a_name.is_empty
			status_known: (create {BIB_FRAMEWORK_SCHEMA}).is_status (a_status)
		do
			id := a_id.to_string_32
			name := a_name.to_string_32
			has_mark := a_mark
			title := a_title.to_string_32
			tier := a_tier.to_string_32
			status := a_status.to_string_32
			hover := a_hover.to_string_32
			provenance := a_provenance
			create sections.make (5)
			create related.make (3)
			create uses.make (4)
		ensure
			id_set: id.same_string_general (a_id)
			name_set: name.same_string_general (a_name)
			nothing_read_yet: sections.is_empty and related.is_empty and uses.is_empty
		end

feature -- Access

	id: STRING_32
			-- "kacc": the link target is "framework:kacc".

	name: STRING_32
			-- "KACC", as prose writes it without the mark.

	has_mark: BOOLEAN
			-- Does prose write it with (TM)?

	title: STRING_32
			-- "Kingdom Allegiance in Contested Cosmos".

	tier: STRING_32
			-- cornerstone, master, recovery or sub.

	status: STRING_32
			-- draft or reviewed.

	hover: STRING_32
			-- What it is, in a sentence or two of plain words.

	provenance: BIB_PROVENANCE
			-- The pack it came from.

	sections: ARRAYED_LIST [TUPLE [heading, markdown: STRING_32]]
			-- Its plain-reader sections, in order.

	related: ARRAYED_LIST [STRING_32]
			-- The ids of frameworks to look at next.

	uses: ARRAYED_LIST [TUPLE [section_id, heading: STRING_32; book, chapter, verse, end_chapter, end_verse: INTEGER]]
			-- The commentary sections that name it in their "Frameworks at work".

	display_name: STRING_32
			-- `name', with the mark when prose writes one.
		do
			Result := name.twin
			if has_mark then
				Result.append_code (0x2122)
			end
		end

	is_draft: BOOLEAN
			-- Has Larry not yet approved it?
		do
			Result := status.same_string_general ({BIB_FRAMEWORK_SCHEMA}.Draft)
		end

invariant
		-- (The id's spelling is the creation precondition: an invariant stays O(1).)
	id_present: not id.is_empty
	named: not name.is_empty
	lists_attached: sections /= Void and related /= Void and uses /= Void

end
