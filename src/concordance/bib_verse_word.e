note
	description: "[
		One word of a verse in the verse lookup: position, the written form, its
		transliteration, and the headword it is a door to (Void when the lemma
		basis is "none"). `lemma_basis' says how the lemma was reached (tagged,
		aligned, xref, none): a candidate, never "the best".
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_WORD

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_position: INTEGER; a_surface, a_translit: READABLE_STRING_GENERAL; a_lemma_id: INTEGER_64; a_lemma_basis: READABLE_STRING_8; a_provenance: BIB_PROVENANCE)
			-- Word `a_position' of the verse; `a_lemma_id' is 0 when none.
		require
			position_positive: a_position >= 1
			surface_not_empty: not a_surface.is_empty
			translit_not_empty: not a_translit.is_empty
			basis_known: a_lemma_basis.same_string ("tagged") or a_lemma_basis.same_string ("aligned") or a_lemma_basis.same_string ("xref") or a_lemma_basis.same_string ("none")
			none_means_no_lemma: a_lemma_basis.same_string ("none") = (a_lemma_id = 0)
		do
			check implemented_in_phase_4: False then end
		ensure
			position_set: position = a_position
			lemma_set: lemma_id = a_lemma_id
			basis_set: lemma_basis.same_string (a_lemma_basis)
			provenance_set: provenance = a_provenance
		end

feature -- Access

	position: INTEGER
	surface: STRING_32
	translit: STRING_32
	lemma_id: INTEGER_64
			-- 0 when the word has no headword.
	lemma_basis: STRING_8
	provenance: BIB_PROVENANCE

	has_door: BOOLEAN
			-- Does this word open a word view?
		do
			Result := lemma_id > 0
		ensure
			definition: Result = (lemma_id > 0)
		end

invariant
	position_positive: position >= 1
	translit_not_empty: not translit.is_empty
	none_means_no_lemma: lemma_basis.same_string ("none") = (lemma_id = 0)

end
