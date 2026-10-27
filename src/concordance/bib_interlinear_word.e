note
	description: "[
		One cell of the Interlinear tab (P03, C04): the word at one position
		of a verse, its morphemes joined. MACULA splits a Hebrew prefix from
		its word (Genesis 1:1 opens with b and reshit at position 1), so a
		cell is built morpheme by morpheme (`add_morpheme'): the surfaces
		run together as written, transliterations joined by a hyphen
		("b-reshit"), glosses by a space, headwords, Strong's numbers and
		morphology by " + ". The morpheme with the longest surface is the
		word's door (`lemma_id') by BIB_WORD_DOOR's rule, as every face finds it.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_INTERLINEAR_WORD

inherit
	BIB_SOURCED

	BIB_WORD_DOOR
		export
			{NONE} all
		end

create
	make

feature {NONE} -- Initialization

	make (a_verse, a_position: INTEGER; a_language: READABLE_STRING_8; a_provenance: BIB_PROVENANCE)
			-- The word at position `a_position' of verse `a_verse', no morpheme yet.
		require
			verse_positive: a_verse >= 1
			position_positive: a_position >= 1
		do
			verse := a_verse
			position := a_position
			language := a_language.to_string_8
			provenance := a_provenance
			create surface.make_empty
			create translit.make_empty
			create gloss.make_empty
			create lemma_text.make_empty
			create strongs.make_empty
			create morphology.make_empty
		ensure
			verse_set: verse = a_verse
			position_set: position = a_position
			no_door_yet: lemma_id = 0
			no_morpheme_yet: morpheme_count = 0
		end

feature -- Access

	verse: INTEGER
	position: INTEGER
	language: STRING_8
			-- "hbo", "arc" or "grc".
	surface: STRING_32
			-- As written; may be empty (a token with no surface, ruling 1.2).
	translit: STRING_32
	gloss: STRING_32
			-- Word-by-word English (STEPBible); empty where it gives none.
	lemma_text: STRING_32
			-- The headwords of the morphemes.
	strongs: STRING_32
	morphology: STRING_32
			-- In words (BIB_MORPHOLOGY_NAMES).
	lemma_id: INTEGER_64
			-- The headword a click opens; 0 when no morpheme has one.
	provenance: BIB_PROVENANCE
	morpheme_count: INTEGER

	has_door: BOOLEAN
			-- Does a click on this word open a headword?
		do
			Result := lemma_id > 0
		ensure
			definition: Result = (lemma_id > 0)
		end

feature -- Element change

	add_morpheme (a_surface, a_translit, a_gloss, a_headword, a_strongs, a_morphology: READABLE_STRING_GENERAL; a_lemma_id: INTEGER_64; a_letters: INTEGER)
			-- Join one more morpheme of this word, in reading order; `a_letters' is the length of its
			-- search form (BIB_WORD_DOOR).
		require
			lemma_not_negative: a_lemma_id >= 0
			letters_not_negative: a_letters >= 0
		do
			if takes_door (a_lemma_id, a_letters, lemma_id, door_letters) then
				lemma_id := a_lemma_id
				door_letters := a_letters
			end
			surface.append_string_general (a_surface)
			append_joined (translit, a_translit, "-")
			append_joined (gloss, a_gloss, " ")
			append_joined (lemma_text, a_headword, " + ")
			append_joined (strongs, a_strongs, " + ")
			append_joined (morphology, a_morphology, " + ")
			morpheme_count := morpheme_count + 1
		ensure
			one_more: morpheme_count = old morpheme_count + 1
			door_kept_or_taken: a_lemma_id = 0 implies lemma_id = old lemma_id
		end

feature {NONE} -- Implementation

	door_letters: INTEGER
			-- The letters of the morpheme `lemma_id' came from.

	append_joined (a_text: STRING_32; a_part: READABLE_STRING_GENERAL; a_separator: STRING_8)
			-- Append `a_part' to `a_text', after `a_separator' when both have text.
		do
			if not a_part.is_empty then
				if not a_text.is_empty then
					a_text.append_string_general (a_separator)
				end
				a_text.append_string_general (a_part)
			end
		end

invariant
	verse_positive: verse >= 1
	position_positive: position >= 1
	lemma_not_negative: lemma_id >= 0

end
