note
	description: "[
		Versification as data (D-010): TVTMS plus the vault's verified LXX
		Jeremiah concordance plus Swete entries. The ONLY creator of
		BIB_MAPPED_REF (AC-1a-18); every cross-version pairing goes through
		`pair', which names its rules (AC-1a-16) and returns every target of a
		split or merged verse (AC-1a-17).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSIFICATION_MAP

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_books: BIB_BOOK_CATALOG)
			-- Create the map over core.db `versification_map'.
		do
			sources := a_sources
			books := a_books
			create rules.make (0)
		ensure
			books_set: books = a_books
		end

feature -- Access

	books: BIB_BOOK_CATALOG

	rule_count: INTEGER
		do
			Result := rules.count
		ensure
			model_agrees: Result = rules_model.count
		end

feature -- Mapping

	mapped (a_ref: BIB_REF): detachable BIB_MAPPED_REF
			-- Canonical identity of `a_ref', or Void when no row maps it.
		require
			book_known: books.has_book (a_ref.book_id)
		do
			-- Phase 4: look up versification_map; create {BIB_MAPPED_REF}.make (hub, a_ref, rules)
		ensure
			identity_kept: attached Result implies Result.origin ~ a_ref
			rules_from_map: attached Result implies Result.rules_model.range <= rules_model
		end

	pair (a_mapped: BIB_MAPPED_REF; a_target: BIB_VERSIFICATION_SYSTEM): BIB_PAIRING
			-- What `a_mapped' is called in `a_target', with every target and the rule used.
		do
			check implemented_in_phase_4: False then end
		ensure
			same_hub: Result.hub_id = a_mapped.hub_id
			target_system_kept: Result.target_system ~ a_target
			rules_reported: Result.target_count > 0 implies not Result.note_text.is_empty
			identity_when_same_system: a_target ~ a_mapped.origin.system
				implies (Result.target_count = 1 and then Result.target (1) ~ a_mapped.origin)
			every_moved_target_ruled: across 1 |..| Result.target_count as i all
				(not (Result.target (i) ~ a_mapped.origin)) implies Result.rule_for_target (i) /= Void end
			method_names_rules: Result.method.rules_count = Result.rules_count
			method_recorded: Result.method.engine_feature.same_string_general ("pair")
			fact_closure: Result.is_fact_closed
		end

feature -- Model

	rules_model: MML_SET [BIB_MAPPING_RULE]
			-- Every mapping rule known to the map.
		do
			create Result
			across rules as r loop
				Result := Result & r
			end
		end

feature {NONE} -- Implementation

	sources: BIB_SOURCE_SET
	rules: ARRAYED_LIST [BIB_MAPPING_RULE]

end
