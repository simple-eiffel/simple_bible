note
	description: "[
		The notes pack (0.7.32, research/21-INGEST-KIT.md): Larry's notes, papers and
		other material brought in through an ingest kit, one note a "book", its
		"# " titles its chapters, "note:<id>/<chapter>#<block>". Built by the books'
		builder from the imported files kept in the reader's data folder, so a
		rebuild never needs the AI again. A note begins at its first title.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_NOTE_SCHEMA

inherit
	BIB_TEXT_PACK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "notes"
			-- `meta.pack_kind' of a notes pack.

	Pack_file_name: STRING_8 = "notes.db"
			-- The notes pack's file in the packs folder.

	Pack_title: STRING_8 = "Larry Rix: Notes"

	Link_prefix: STRING_32 = "note:"
			-- "note:romans8sermon/1#3".

	Manifest_extension: STRING_8 = ".note.json"

	Builder_command: STRING_8 = "Simple Bible: Import prepared notes"

	Starts_at_title: BOOLEAN = True
			-- A note begins at its "# " title.

	Kind_noun: STRING_32 = "Notes"

	Entries_noun: STRING_8 = "notes"

end
