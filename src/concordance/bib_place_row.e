note
	description: "[
		One row of the every-place list (research/14 section 3, item 7):
		reference, the whole word and its transliteration, meaning (SDBH/SDGNT)
		or stem, then the BSB, KJV and STEP in context. Corpus license travels in
		`provenance' (corpus.ship_class).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_PLACE_ROW

inherit
	BIB_SOURCED

create
	make

feature {NONE} -- Initialization

	make (a_token_id: INTEGER_64; a_reference_text, a_surface, a_translit: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Row for token `a_token_id'; optional columns are set with `set_context'.
		require
			id_positive: a_token_id > 0
			reference_not_empty: not a_reference_text.is_empty
			surface_not_empty: not a_surface.is_empty
			translit_not_empty: not a_translit.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			id_set: token_id = a_token_id
			reference_set: reference_text.same_string_general (a_reference_text)
			provenance_set: provenance = a_provenance
		end

feature -- Access

	token_id: INTEGER_64
	reference_text: STRING_32
	surface: STRING_32
	translit: STRING_32
	provenance: BIB_PROVENANCE

	meaning: detachable STRING_32
			-- SDBH or SDGNT meaning for this place, when the pack carries one.

	stem: detachable STRING_32
			-- Hebrew stem, when a Hebrew verb.

	bsb, kjv, step: detachable STRING_32
			-- English in context; Void when the pack lacks that layer (conc_dist.db).

feature -- Element change

	set_context (a_meaning, a_stem, a_bsb, a_kjv, a_step: detachable READABLE_STRING_GENERAL)
			-- Set the optional columns.
		do
			check implemented_in_phase_4: False then end
		ensure
			bsb_set: (a_bsb = Void) = (bsb = Void)
			kjv_set: (a_kjv = Void) = (kjv = Void)
			step_set: (a_step = Void) = (step = Void)
		end

invariant
	id_positive: token_id > 0
	translit_not_empty: not translit.is_empty

end
