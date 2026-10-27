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

inherit
	BIB_SQLITE_QUERYING

create
	make

feature {NONE} -- Initialization

	make (a_sources: BIB_SOURCE_SET; a_books: BIB_BOOK_CATALOG)
			-- Create the map over content.db `versification_map'.
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

	has_hebrew_map: BOOLEAN
			-- Does content.db carry Hebrew-to-English rows (bible_build 0.4.0 with --tvtms)?
		do
			Result := not hebrew_moves.is_empty
		end

	english_place (a_place: INTEGER_64): INTEGER_64
			-- The English (Standard: NRSV, the KJV family) place of Hebrew-numbered place `a_place',
			-- packed by BIB_PLACE_PACKING, from `versification_map' (STEPBible TVTMS, CC BY 4.0):
			-- Malachi 3:19 is 4:1, a Psalm's Hebrew verse 2 is often its verse 1. `a_place' itself when
			-- no row moves it.
		do
			if hebrew_moves.has (a_place) then
				Result := hebrew_moves.item (a_place)
			else
				Result := a_place
			end
		end

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

	hebrew_moves: HASH_TABLE [INTEGER_64, INTEGER_64]
			-- Hebrew place to English place, every row of `versification_map' for "hebrew" (read once;
			-- empty when content.db carries none or the table is absent).
		local
			l_keys: BIB_VERSE_KEY
		once ("OBJECT")
			create Result.make (2048)
			create l_keys
			if sources.is_open then
				run_query ("SELECT from_book, from_chapter, from_verse, to_book, to_chapter, to_verse FROM main.versification_map WHERE system = 'hebrew'", {ARRAY [detachable ANY]} <<>>)
				if attached last_rows as al_rows then
					across al_rows.rows as ic loop
						Result.force (l_keys.packed_place (ic.integer_value ("to_book"), ic.integer_value ("to_chapter"), ic.integer_value ("to_verse")),
							l_keys.packed_place (ic.integer_value ("from_book"), ic.integer_value ("from_chapter"), ic.integer_value ("from_verse")))
					end
				end
			end
		end

	query_failed_message: STRING_8 = "A versification query failed."
	not_open_message: STRING_8 = "content.db is not open."
			-- The map's words around SQLite's own (BIB_SQLITE_QUERYING).

	method_edition: STRING_32
			-- The edition the method records cite.
		do
			Result := {STRING_32} "content.db"
		end
	rules: ARRAYED_LIST [BIB_MAPPING_RULE]

end
