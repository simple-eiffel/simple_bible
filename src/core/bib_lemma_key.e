note
	description: "A lemma key: language code and lemma text (MACULA/OSHB lemma)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LEMMA_KEY

inherit
	BIB_KEY

create
	make

feature {NONE} -- Initialization

	make (a_language: READABLE_STRING_8; a_lemma: READABLE_STRING_GENERAL)
			-- Create the key of `a_lemma' in `a_language' ("hbo", "grc").
		require
			language_not_empty: not a_language.is_empty
			lemma_not_empty: not a_lemma.is_empty
		do
			language := a_language.to_string_8
			lemma := a_lemma.to_string_32
			text := language.to_string_32 + {STRING_32} ":" + lemma
		ensure
			language_set: language.same_string (a_language)
			lemma_set: lemma.same_string_general (a_lemma)
		end

feature -- Access

	language: STRING_8
	lemma: STRING_32

	kind_label: STRING_32
		do
			Result := {STRING_32} "lemma"
		end

invariant
	language_not_empty: not language.is_empty
	lemma_not_empty: not lemma.is_empty

end
