note
	description: "[
		rix.db, Larry's author library (D-019): search, documents citing a
		passage, reader. No document reaches a face without its status;
		withdrawn documents are excluded from search by default and returned,
		with their banner, when "Include withdrawn" is on (Q-09, AC-1a-34).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AUTHOR_LIBRARY

inherit
	BIB_DATA_SOURCE

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
		require
			path_not_empty: not a_path.is_empty
		do
			path := a_path.to_string_32
			create sqlite_version.make_empty
		ensure
			closed: not is_open
		end

feature -- Access

	alias_name: STRING_8
		do
			Result := "rix"
		end

	expected_schema_version: INTEGER
		do
			Result := Rix_schema_version
		end

feature -- Query

	search (a_query: BIB_QUERY; a_include_withdrawn: BOOLEAN): BIB_LIST_RESULT [BIB_AUTHOR_DOC]
		require
			open: is_open
			query_valid: a_query.is_valid
		do
			check implemented_in_phase_4: False then end
		ensure
			withdrawn_only_if_requested: not a_include_withdrawn implies across 1 |..| Result.count as i all not Result.item (i).status.is_withdrawn end
			current_first: is_current_before_withdrawn (Result)
			method_recorded: Result.method.engine_feature.same_string_general ("author_search")
			fact_closure: Result.is_fact_closed
		end

	citing (a_mapped: BIB_MAPPED_REF; a_include_withdrawn: BOOLEAN): BIB_LIST_RESULT [BIB_AUTHOR_DOC]
		require
			open: is_open
		do
			check implemented_in_phase_4: False then end
		ensure
			cites_verse: across 1 |..| Result.count as i all Result.item (i).cites (a_mapped.hub_id) end
			withdrawn_only_if_requested: not a_include_withdrawn implies across 1 |..| Result.count as i all not Result.item (i).status.is_withdrawn end
			fact_closure: Result.is_fact_closed
		end

	document (a_doc_id: INTEGER_64): BIB_LIST_RESULT [BIB_AUTHOR_DOC]
			-- The document `a_doc_id' (a reader always shows status and banner).
		require
			open: is_open
			id_positive: a_doc_id > 0
		do
			check implemented_in_phase_4: False then end
		ensure
			at_most_one: Result.count <= 1
			same_document: Result.count = 1 implies Result.item (1).doc_id = a_doc_id
			fact_closure: Result.is_fact_closed
		end

feature -- Status

	is_current_before_withdrawn (a_result: BIB_LIST_RESULT [BIB_AUTHOR_DOC]): BOOLEAN
			-- Does no withdrawn document precede a current one?
		do
			Result := across 2 |..| a_result.count as i all
				a_result.item (i - 1).status.is_withdrawn implies a_result.item (i).status.is_withdrawn end
		end

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
		do
			-- Phase 4: attach rix.db read-only; check the R15 schema (docs, verse_refs, docs_fts).
		end

	close
		do
			-- Phase 4
		end

feature -- Constants

	Rix_schema_version: INTEGER = 1

end
