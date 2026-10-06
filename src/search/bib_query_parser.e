note
	description: "Query text to a clause tree or a positioned error (VR-03..05): words, phrases, AND/OR/NOT, regex, lemma:, strongs:, morph:."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUERY_PARSER

feature -- Parsing

	parsed (a_text: READABLE_STRING_GENERAL; a_scope: BIB_SEARCH_SCOPE): BIB_QUERY
			-- Clause tree of `a_text' over `a_scope'.
		require
			text_not_empty: not a_text.is_empty
		do
			check implemented_in_phase_4: False then end
		ensure
			text_kept: Result.text.same_string_general (a_text) or not Result.is_valid
			scope_kept: Result.scope = a_scope
			error_located: not Result.is_valid implies (Result.error_position >= 1 and Result.error_position <= a_text.count + 1)
		end

end
