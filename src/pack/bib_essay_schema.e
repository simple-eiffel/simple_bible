note
	description: "[
		The essays pack (2026-10-28): Larry's essays, one manifest per series, which
		the COMMENTARY session writes (a series is a book, an essay a chapter),
		"essay:<series>/<essay>#<block>" - the essay counted in the manifest's
		order, not by its number in the series. Its tables and link grammar are
		BIB_TEXT_PACK_SCHEMA's. An essay begins at its title: a draft note, a
		status line or an image above it is left out.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ESSAY_SCHEMA

inherit
	BIB_TEXT_PACK_SCHEMA

feature -- Constants

	Pack_kind: STRING_8 = "essays"
			-- `meta.pack_kind' of an essays pack.

	Pack_file_name: STRING_8 = "essays.db"
			-- The essays pack's file in the packs folder.

	Pack_title: STRING_8 = "Larry Rix: Essays"

	Link_prefix: STRING_32 = "essay:"
			-- "essay:jesus/6#3".

	Manifest_extension: STRING_8 = ".essay.json"

	Builder_command: STRING_8 = "bible_build --essays"

	Starts_at_title: BOOLEAN = True
			-- An essay begins at its "# " title.

end
