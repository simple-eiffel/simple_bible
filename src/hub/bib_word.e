note
	description: "[
		One token with its keys, morphology (code and English), gloss,
		transliteration and pronunciation (word card, A06), with provenance.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WORD

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_id: BIB_WORD_ID; a_hub_id: INTEGER_64; a_position: INTEGER; a_surface: READABLE_STRING_32;
			a_lemma: detachable BIB_LEMMA_KEY; a_strongs: detachable BIB_STRONGS_KEY; a_morph: detachable BIB_MORPH_CODE;
			a_morph_english, a_gloss, a_transliteration, a_pronunciation: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Create a token.
		require
			hub_positive: a_hub_id > 0
			position_positive: a_position >= 1
			surface_not_empty: not a_surface.is_empty
			morph_expanded: a_morph /= Void implies not a_morph_english.is_empty
		do
			id := a_id
			hub_id := a_hub_id
			position := a_position
			surface := a_surface.to_string_32
			lemma := a_lemma
			strongs := a_strongs
			morph := a_morph
			morph_english := a_morph_english.to_string_32
			gloss := a_gloss.to_string_32
			transliteration := a_transliteration.to_string_32
			pronunciation := a_pronunciation.to_string_32
			provenance := a_provenance
		ensure
			id_set: id = a_id
			surface_kept: surface.same_string (a_surface)
		end

feature -- Access

	id: BIB_WORD_ID
	hub_id: INTEGER_64
	position: INTEGER
	surface: STRING_32
	lemma: detachable BIB_LEMMA_KEY
	strongs: detachable BIB_STRONGS_KEY
	morph: detachable BIB_MORPH_CODE
	morph_english: STRING_32
	gloss: STRING_32
	transliteration: STRING_32
	pronunciation: STRING_32
	provenance: BIB_PROVENANCE

invariant
	hub_positive: hub_id > 0
	position_positive: position >= 1
	surface_not_empty: not surface.is_empty
	morph_expanded: morph /= Void implies not morph_english.is_empty

end
