note
	description: "[
		Anything the engine hands out that carries its own provenance (RQ-02).
		Every value an engine result exposes is a BIB_SOURCED, so the result's
		`facts_model' can be checked against its citations (fact closure,
		AC-1a-32). Effective descendants define `provenance' as an attribute.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_SOURCED

feature -- Access

	provenance: BIB_PROVENANCE
			-- Where this value came from.
		deferred
		end

feature -- Language (shared by the concordance value classes)

	is_original (a_language: READABLE_STRING_8): BOOLEAN
			-- Is `a_language' an original-language code of the Bible (Hebrew, Aramaic or Greek)?
			-- Pure: English ("eng") is a rendering, not an original (Phase 2 review, ruling 1.2).
		do
			Result := a_language.same_string ("hbo") or a_language.same_string ("arc") or a_language.same_string ("grc")
		ensure
			definition: Result = (a_language.same_string ("hbo") or a_language.same_string ("arc") or a_language.same_string ("grc"))
		end

end
