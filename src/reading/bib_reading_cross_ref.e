note
	description: "[
		One cross-reference from a verse, as the commentary panel's Cross-refs
		tab lists it (content.db `cross_reference`, from the vault's OpenBible
		rows): the target verse or range and its votes, which may be negative.
		Plain numbers in the vault's book ids; the spec's BIB_CROSS_REFERENCE
		adds versification hub ids when the map exists (fold 2026-10-26).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_READING_CROSS_REF

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_book, a_chapter, a_verse_start, a_verse_end, a_votes: INTEGER; a_provenance: BIB_PROVENANCE)
			-- A cross-reference to `a_book' `a_chapter':`a_verse_start'-`a_verse_end' with `a_votes'.
		require
			book_positive: a_book > 0
			chapter_positive: a_chapter > 0
			verse_positive: a_verse_start > 0
		do
			to_book := a_book
			to_chapter := a_chapter
			verse_start := a_verse_start
			verse_end := a_verse_end.max (a_verse_start)
			votes := a_votes
			provenance := a_provenance
		ensure
			target_set: to_book = a_book and to_chapter = a_chapter and verse_start = a_verse_start
			range_ordered: verse_end >= verse_start
			votes_set: votes = a_votes
		end

feature -- Access

	to_book: INTEGER
	to_chapter: INTEGER
	verse_start: INTEGER
	verse_end: INTEGER
			-- The target: one verse, or a range within one chapter.

	votes: INTEGER
			-- How many readers found the link useful (OpenBible; may be negative).

	provenance: BIB_PROVENANCE

	is_range: BOOLEAN
			-- Does the target span more than one verse?
		do
			Result := verse_end > verse_start
		end

	verses_text: STRING_32
			-- "8" or "9-10".
		do
			Result := verse_start.out.to_string_32
			if is_range then
				Result.append ({STRING_32} "-" + verse_end.out)
			end
		end

invariant
	target_positive: to_book > 0 and to_chapter > 0 and verse_start > 0
	range_ordered: verse_end >= verse_start

end
