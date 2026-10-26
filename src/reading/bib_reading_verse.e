note
	description: "[
		One verse of one version for reading: its place in that version's own
		numbering and its exact text, never edited. An empty text is the
		edition's omission (Westcott-Hort Matthew 17:21), told as such, never
		shown as a blank verse.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_READING_VERSE

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_version: READABLE_STRING_8; a_book, a_chapter, a_verse: INTEGER; a_text: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Verse `a_book' `a_chapter':`a_verse' of `a_version' reading `a_text' (empty: omitted).
		require
			version_not_empty: not a_version.is_empty
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_positive: a_verse > 0
		do
			version_code := a_version.to_string_8
			book_id := a_book
			chapter := a_chapter
			verse := a_verse
			text := a_text.to_string_32
			provenance := a_provenance
		ensure
			version_set: version_code.same_string (a_version)
			place_set: book_id = a_book and chapter = a_chapter and verse = a_verse
			text_kept: text.same_string_general (a_text)
		end

feature -- Access

	version_code: STRING_8
	book_id: INTEGER
	chapter: INTEGER
	verse: INTEGER

	text: STRING_32
			-- The verse exactly as the edition prints it; empty when the edition omits it.

	provenance: BIB_PROVENANCE
			-- The version's source.

	is_omitted: BOOLEAN
			-- Does the edition leave this verse out?
		do
			Result := text.is_empty
		end

	display_text: STRING_32
			-- `text', or a note saying the edition omits the verse.
		do
			if is_omitted then
				Result := {STRING_32} "(This edition omits this verse.)"
			else
				Result := text
			end
		ensure
			never_empty: not Result.is_empty
		end

invariant
	version_not_empty: not version_code.is_empty
	place_positive: book_id > 0 and chapter > 0 and verse > 0

end
