note
	description: "A join or count key (lemma, Strong's, morphology, word id); never a display string. Equal when canonical texts are."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_KEY

inherit
	ANY
		redefine
			is_equal
		end

feature -- Access

	text: STRING_32
			-- Canonical key text, e.g. "H1", "G3056a", "grc:ekklesia", "OSHB:HNcmsa".

	kind_label: STRING_32
			-- Kind of key, e.g. "lemma", "strongs".
		deferred
		ensure
			not_empty: not Result.is_empty
		end

feature -- Comparison

	is_equal (other: like Current): BOOLEAN
			-- Same canonical key?
		do
			Result := text.same_string (other.text)
		end

invariant
	text_not_empty: not text.is_empty

end
