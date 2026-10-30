note
	description: "[
		The scholar guides pack (2026-10-30, Larry: "Go - where they go i will
		leave to you and the kit-importer"): chapter-by-chapter study guides of
		another scholar's books (Heiser's first), brought in through an ingest
		kit with "kind: guide", one section of the work a "book",
		"guide:<id>/<chapter>#<block>". Kept apart from Larry's own writings
		(`Is_kept_apart'): its own folder and pack, its own Scholar Guides tab
		and Study guides list, never in the Author Library, the Writings search
		or a kit's names. Private research: shipped only to the alpha testers
		under NDA, and only when Larry says a book's review is done.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_GUIDE_SCHEMA

inherit
	BIB_TEXT_PACK_SCHEMA
		redefine
			Is_kept_apart
		end

feature -- Constants

	Pack_kind: STRING_8 = "guides"
			-- `meta.pack_kind' of a scholar guides pack.

	Pack_file_name: STRING_8 = "guides.db"
			-- The scholar guides pack's file in the packs folder.

	Pack_title: STRING_8 = "Scholar Guides"

	Link_prefix: STRING_32 = "guide:"
			-- "guide:unseenrealm11/1#4".

	Manifest_extension: STRING_8 = ".guide.json"

	Builder_command: STRING_8 = "Simple Bible: Import prepared guides"

	Starts_at_title: BOOLEAN = True
			-- A guide begins at its "# " title.

	Kind_noun: STRING_32 = "Guide"

	Entries_noun: STRING_8 = "guides"

	Is_kept_apart: BOOLEAN = True
			-- Another scholar's work, kept apart from Larry's writings.

end
