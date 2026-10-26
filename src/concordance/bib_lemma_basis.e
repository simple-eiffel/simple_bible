note
	description: "[
		How a word got its headword (ruling 1.1): the basis KIND, one of tagged,
		computed, aligned, xref or none. The pack stores `<kind>:<source>'
		("tagged:MACULA-Hebrew", "computed:spacy-lemma"); values carry the kind
		only. One home for the vocabulary (design scan 28: it was written twice).
		Stateless; inherit it beside the class's real parent.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_LEMMA_BASIS

feature -- Status

	is_known_basis (a_kind: READABLE_STRING_8): BOOLEAN
			-- Is `a_kind' one of `Basis_kinds'?
		do
			Result := across Basis_kinds as ic some a_kind.same_string (ic) end
		end

	basis_kind (a_stored: READABLE_STRING_8): STRING_8
			-- The kind in a stored `<kind>:<source>' basis: the text before the colon.
		local
			l_stored: STRING_8
		do
			l_stored := a_stored.to_string_8
			if l_stored.has (':') then
				Result := l_stored.substring (1, l_stored.index_of (':', 1) - 1)
			else
				Result := l_stored.twin
			end
		ensure
			no_colon: not Result.has (':')
		end

feature -- Constants

	Basis_kinds: ARRAY [STRING_8]
			-- The basis vocabulary.
		once
			Result := <<"tagged", "computed", "aligned", "xref", "none">>
		end

end
