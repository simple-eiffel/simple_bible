note
	description: "[
		One line of the English lookup: an English word, an original word behind
		it (a candidate, never "the best"), the book it occurs in, and a count.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_ENGLISH_ROW

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_english: READABLE_STRING_GENERAL; a_bible: READABLE_STRING_8; a_lemma_id: INTEGER_64; a_headword, a_translit: READABLE_STRING_GENERAL; a_book_id: INTEGER; a_count: INTEGER_64; a_provenance: BIB_PROVENANCE)
			-- `a_english' renders `a_lemma_id' `a_count' times in book `a_book_id'.
		require
			english_not_empty: not a_english.is_empty
			bible_not_empty: not a_bible.is_empty
			id_positive: a_lemma_id > 0
			book_positive: a_book_id > 0
			count_positive: a_count > 0
			translit_not_empty: not a_translit.is_empty
		do
			english := a_english.to_string_32
			bible := a_bible.to_string_8
			lemma_id := a_lemma_id
			headword := a_headword.to_string_32
			translit := a_translit.to_string_32
			book_id := a_book_id
			count := a_count
			provenance := a_provenance
		ensure
			english_set: english.same_string_general (a_english)
			bible_set: bible.same_string (a_bible)
			id_set: lemma_id = a_lemma_id
			headword_set: headword.same_string_general (a_headword)
			translit_set: translit.same_string_general (a_translit)
			book_set: book_id = a_book_id
			count_set: count = a_count
			provenance_set: provenance = a_provenance
		end

feature -- Access

	english: STRING_32
	bible: STRING_8
			-- The English Bible's corpus code (FR-151: Bible by Bible); readers see its name, never the code.
	lemma_id: INTEGER_64
	headword: STRING_32
	translit: STRING_32
	book_id: INTEGER
	count: INTEGER_64
	provenance: BIB_PROVENANCE

invariant
	count_positive: count > 0
	translit_not_empty: not translit.is_empty

end
