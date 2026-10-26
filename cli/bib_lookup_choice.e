note
	description: "[
		One thing a lookup found, as a face lists it: a label, a detail line, and
		the headword it opens (a verse word, a headword, or the original word
		behind an English one). Face-neutral: the window lists these; tests read them.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LOOKUP_CHOICE

create
	make

feature {NONE} -- Initialization

	make (a_label, a_detail: READABLE_STRING_GENERAL; a_lemma_id: INTEGER_64)
			-- A choice shown as `a_label' and `a_detail' that opens headword `a_lemma_id' (0: opens nothing).
		require
			label_not_empty: not a_label.is_empty
			id_non_negative: a_lemma_id >= 0
		do
			label := a_label.to_string_32
			detail := a_detail.to_string_32
			lemma_id := a_lemma_id
		ensure
			label_set: label.same_string_general (a_label)
			detail_set: detail.same_string_general (a_detail)
			lemma_set: lemma_id = a_lemma_id
		end

feature -- Access

	label: STRING_32
			-- What the list shows first (a Hebrew or Greek word, or a heading).

	detail: STRING_32
			-- The second column (transliteration, counts, the English Bible).

	lemma_id: INTEGER_64
			-- The headword this choice opens; 0 when it opens nothing.

	opens_a_word: BOOLEAN
			-- Does this choice open a word study?
		do
			Result := lemma_id > 0
		ensure
			definition: Result = (lemma_id > 0)
		end

invariant
	label_not_empty: not label.is_empty
	id_non_negative: lemma_id >= 0

end
