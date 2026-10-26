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

	BIB_LANGUAGE_CODES

create
	make

feature {NONE} -- Initialization

	make (a_token_id: INTEGER_64; a_language: READABLE_STRING_8; a_reference_text, a_surface, a_translit: READABLE_STRING_GENERAL; a_provenance: BIB_PROVENANCE)
			-- Row for token `a_token_id' in language `a_language'; optional columns are set with `set_context'.
			-- `a_surface' may be empty for a real Hebrew token (Phase 2 review, ruling 1.2).
		require
			id_positive: a_token_id > 0
			language_known: is_concordance_language (a_language)
			reference_not_empty: not a_reference_text.is_empty
			translit_when_written: is_translit_complete (a_language, a_surface, a_translit)
		do
			token_id := a_token_id
			language := a_language.to_string_8
			reference_text := a_reference_text.to_string_32
			surface := a_surface.to_string_32
			translit := a_translit.to_string_32
			provenance := a_provenance
		ensure
			id_set: token_id = a_token_id
			language_set: language.same_string (a_language)
			reference_set: reference_text.same_string_general (a_reference_text)
			surface_set: surface.same_string_general (a_surface)
			translit_set: translit.same_string_general (a_translit)
			provenance_set: provenance = a_provenance
			context_absent: meaning = Void and stem = Void and bsb = Void and kjv = Void and step = Void
		end

feature -- Access

	token_id: INTEGER_64
	language: STRING_8
		-- "eng", "hbo", "arc" or "grc".
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
			meaning := optional (a_meaning)
			stem := optional (a_stem)
			bsb := optional (a_bsb)
			kjv := optional (a_kjv)
			step := optional (a_step)
		ensure
			meaning_set: (a_meaning = Void) = (meaning = Void)
			stem_set: (a_stem = Void) = (stem = Void)
			bsb_set: (a_bsb = Void) = (bsb = Void)
			kjv_set: (a_kjv = Void) = (kjv = Void)
			step_set: (a_step = Void) = (step = Void)
		end

feature {NONE} -- Implementation

	optional (a_text: detachable READABLE_STRING_GENERAL): detachable STRING_32
			-- `a_text' as a new STRING_32, or Void.
		do
			if attached a_text as al_text then
				Result := al_text.to_string_32
			end
		ensure
			void_kept: (a_text = Void) = (Result = Void)
		end

invariant
	id_positive: token_id > 0
	translit_when_written: is_translit_complete (language, surface, translit)

end
