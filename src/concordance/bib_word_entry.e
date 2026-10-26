note
	description: "[
		The heading of a word view (research/14 section 3, item 1): a headword
		keyed by lemma_id, its transliteration and pronunciation, and how many
		tokens carry it. Never keyed by Strong's (research/14 section 1).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD_ENTRY

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_lemma_id: INTEGER_64; a_language: READABLE_STRING_8; a_headword, a_translit, a_pron: READABLE_STRING_GENERAL; a_token_total: INTEGER_64; a_provenance: BIB_PROVENANCE)
			-- Heading of lemma `a_lemma_id'.
		require
			id_positive: a_lemma_id > 0
			language_known: a_language.same_string ("hbo") or a_language.same_string ("arc") or a_language.same_string ("grc")
			headword_not_empty: not a_headword.is_empty
			translit_not_empty: not a_translit.is_empty
			total_non_negative: a_token_total >= 0
		do
			check implemented_in_phase_4: False then end
		ensure
			id_set: lemma_id = a_lemma_id
			language_set: language.same_string (a_language)
			headword_set: headword.same_string_general (a_headword)
			translit_set: translit.same_string_general (a_translit)
			total_set: token_total = a_token_total
			provenance_set: provenance = a_provenance
		end

feature -- Access

	lemma_id: INTEGER_64
	language: STRING_8
	headword: STRING_32
	translit: STRING_32
	pron: STRING_32
	token_total: INTEGER_64
	provenance: BIB_PROVENANCE

invariant
	id_positive: lemma_id > 0
	headword_not_empty: not headword.is_empty
	translit_not_empty: not translit.is_empty
	total_non_negative: token_total >= 0

end
