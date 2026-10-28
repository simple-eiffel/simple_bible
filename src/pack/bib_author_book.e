note
	description: "[
		One of Larry's books as the books pack holds it (BIB_BOOK_SCHEMA): its title,
		subtitle, status, edition and description, and - when read whole
		(BIB_BOOK_PACK.book) - its chapters in reading order.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AUTHOR_BOOK

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_id, a_title, a_subtitle, a_status, a_edition: READABLE_STRING_GENERAL; a_year: INTEGER; a_description, a_pack_kind: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Book `a_id', titled `a_title', in a pack of kind `a_pack_kind' ("books", "essays": a series).
		require
			id_usable: (create {BIB_BOOK_SCHEMA}).is_book_id (a_id)
			titled: not a_title.is_empty
		do
			id := a_id.to_string_32
			title := a_title.to_string_32
			subtitle := a_subtitle.to_string_32
			status := a_status.to_string_32
			edition := a_edition.to_string_32
			year := a_year
			description := a_description.to_string_32
			pack_kind := a_pack_kind.to_string_32
			provenance := a_provenance
			create chapters.make (16)
		ensure
			id_set: id.same_string_general (a_id)
			title_set: title.same_string_general (a_title)
			no_chapters_yet: chapters.is_empty
		end

feature -- Access

	pack_kind: STRING_32
			-- "books", or "essays" for an essay series.

	id: STRING_32
	title: STRING_32
	subtitle: STRING_32
	status: STRING_32
			-- published, manuscript or draft.
	edition: STRING_32
	year: INTEGER
	description: STRING_32
			-- What the book is about, in two or three plain sentences.

	provenance: BIB_PROVENANCE

	chapters: ARRAYED_LIST [TUPLE [chapter: INTEGER; title, kind: STRING_32]]
			-- Its chapters in reading order (front matter, chapters, back matter).

	full_title: STRING_32
			-- "Title: Subtitle", or the title alone.
		do
			Result := title.twin
			if not subtitle.is_empty then
				Result.append ({STRING_32} ": " + subtitle)
			end
		end

	chapter_title (a_chapter: INTEGER): STRING_32
			-- The title of chapter `a_chapter'; empty when the book has none by that number.
		do
			create Result.make_empty
			across chapters as ic loop
				if ic.chapter = a_chapter then
					Result := ic.title
				end
			end
		end

invariant
	id_present: not id.is_empty
	titled: not title.is_empty
	chapters_attached: chapters /= Void

end
