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
			create last_published.make_empty
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

	chapters: ARRAYED_LIST [TUPLE [chapter: INTEGER; title, kind, status, published_on: STRING_32]]
			-- Its chapters in reading order (front matter, chapters, back matter), each with its own
			-- status and the day it was published ("2026-06-14"; empty when not known) (0.7.61).

	is_counted: BOOLEAN
			-- Were its chapters counted by status (`set_publication'; a pack built before 0.7.61 has no
			-- chapter status)?

	chapter_count: INTEGER
			-- How many chapters (essays) it has, when counted.

	published_count: INTEGER
			-- How many of them are published, when counted.

	last_published: STRING_32
			-- The latest day one of its chapters was published ("2026-11-03"); empty when none is known.

	status_text: STRING_32
			-- Its status as a list shows it: "3 of 8 published" while only some of its chapters are
			-- (Larry, 2026-11-03: a series is published once all its essays are), else `status'.
		do
			if is_counted and then published_count > 0 and then published_count < chapter_count then
				Result := published_count.out.to_string_32 + {STRING_32} " of " + chapter_count.out.to_string_32 + {STRING_32} " published"
			else
				Result := status
			end
		end

	set_publication (a_published, a_count: INTEGER; a_last: READABLE_STRING_GENERAL)
			-- `a_published' of its `a_count' chapters published, the latest on `a_last'.
		require
			sane: a_count >= 0 and a_published >= 0 and a_published <= a_count
		do
			published_count := a_published
			chapter_count := a_count
			last_published := a_last.to_string_32
			is_counted := True
		ensure
			counted: is_counted and published_count = a_published and chapter_count = a_count
			last_set: last_published.same_string_general (a_last)
		end

feature -- Access (titles)

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
	counts_sane: published_count >= 0 and published_count <= chapter_count

end
