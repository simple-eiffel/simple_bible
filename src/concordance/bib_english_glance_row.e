note
	description: "[
		One line of English at a glance (research/14 section 3): how one English
		Bible renders a headword, and how often, from the builder's summary
		(`lemma_english', FR-162). The book does not matter here, so the line has
		none (BIB_ENGLISH_ROW is the per-book line of the English lookup).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ENGLISH_GLANCE_ROW

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_bible: READABLE_STRING_8; a_english: READABLE_STRING_GENERAL; a_count: INTEGER_64; a_provenance: BIB_PROVENANCE)
			-- `a_bible' renders the headword as `a_english', `a_count' times.
		require
			bible_not_empty: not a_bible.is_empty
			english_not_empty: not a_english.is_empty
			count_positive: a_count > 0
		do
			bible := a_bible.to_string_8
			english := a_english.to_string_32
			count := a_count
			provenance := a_provenance
		ensure
			bible_set: bible.same_string (a_bible)
			english_set: english.same_string_general (a_english)
			count_set: count = a_count
			provenance_set: provenance = a_provenance
		end

feature -- Access

	bible: STRING_8
			-- The English Bible's corpus code.

	english: STRING_32
			-- The English word.

	count: INTEGER_64
			-- How often that Bible renders the headword so.

	provenance: BIB_PROVENANCE

invariant
	count_positive: count > 0
	english_not_empty: not english.is_empty

end
