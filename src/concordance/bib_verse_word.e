note
	description: "[
		One word of a verse in the verse lookup: position, the written form, its
		transliteration, and the headword it is a door to (Void when the lemma
		basis is "none"). `lemma_basis' says how the lemma was reached (tagged,
		computed, aligned, xref, none): a candidate, never "the best". The basis is
		the KIND only; the pack stores `<kind>:<source>' and maps it (ruling 1.1).
		`surface' may be empty for a real original-language token (6,435 Hebrew
		tokens in conc.db, ruling 1.2); `translit' is then not required.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_WORD

inherit
	BIB_SOURCED

	BIB_LANGUAGE_CODES

	BIB_LEMMA_BASIS

create
	make

feature {NONE} -- Initialization

	make (a_position: INTEGER; a_language: READABLE_STRING_8; a_surface, a_translit: READABLE_STRING_GENERAL; a_lemma_id: INTEGER_64; a_lemma_basis: READABLE_STRING_8; a_provenance: BIB_PROVENANCE)
			-- Word `a_position' of the verse in language `a_language'; `a_lemma_id' is 0 when none.
		require
			position_positive: a_position >= 1
			language_known: is_concordance_language (a_language)
			translit_when_written: is_translit_complete (a_language, a_surface, a_translit)
			basis_known: is_known_basis (a_lemma_basis)
			none_means_no_lemma: a_lemma_basis.same_string ("none") = (a_lemma_id = 0)
		do
			position := a_position
			language := a_language.to_string_8
			surface := a_surface.to_string_32
			translit := a_translit.to_string_32
			lemma_id := a_lemma_id
			lemma_basis := a_lemma_basis.to_string_8
			provenance := a_provenance
		ensure
			position_set: position = a_position
			language_set: language.same_string (a_language)
			surface_set: surface.same_string_general (a_surface)
			translit_set: translit.same_string_general (a_translit)
			lemma_set: lemma_id = a_lemma_id
			basis_set: lemma_basis.same_string (a_lemma_basis)
			provenance_set: provenance = a_provenance
		end

feature -- Access

	position: INTEGER
			-- The word's place in the verse; the morphemes of one word share it (a Hebrew prefix
			-- and its word: MACULA splits them).
	language: STRING_8
		-- "eng", "hbo", "arc" or "grc".
	surface: STRING_32
		-- The written form; may be empty (see the class note).
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
	translit_when_written: is_translit_complete (language, surface, translit)
	none_means_no_lemma: lemma_basis.same_string ("none") = (lemma_id = 0)

end
