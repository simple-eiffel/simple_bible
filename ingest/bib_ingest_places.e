note
	description: "[
		Where an import keeps what it brings in (2026-10-30): the notes folder and
		the notes pack it builds, the scholar guides folder and the guides pack it
		builds, and the frameworks pack whose names the builds link. The window
		names the packs to build as ".new" files and puts each in place after.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INGEST_PLACES

create
	make

feature {NONE} -- Initialization

	make (a_notes_folder, a_notes_pack, a_guides_folder, a_guides_pack, a_frameworks_pack: READABLE_STRING_GENERAL)
			-- The places, each as named.
		require
			notes_folder_named: not a_notes_folder.is_empty
			notes_pack_named: not a_notes_pack.is_empty
			guides_folder_named: not a_guides_folder.is_empty
			guides_pack_named: not a_guides_pack.is_empty
		do
			create notes_folder.make_from_string_general (a_notes_folder)
			create notes_pack.make_from_string_general (a_notes_pack)
			create guides_folder.make_from_string_general (a_guides_folder)
			create guides_pack.make_from_string_general (a_guides_pack)
			create frameworks_pack.make_from_string_general (a_frameworks_pack)
		end

feature -- Access

	notes_folder, notes_pack: STRING_32
			-- The notes' files, and the notes pack built from them.

	guides_folder, guides_pack: STRING_32
			-- The scholar guides' files, and the guides pack built from them.

	frameworks_pack: STRING_32
			-- The frameworks pack whose names are linked; empty for none.

invariant
	notes_folder_named: not notes_folder.is_empty
	guides_folder_named: not guides_folder.is_empty
	apart: not notes_folder.same_string (guides_folder) and not notes_pack.same_string (guides_pack)

end
