note
	description: "[
		ai_data.db: precomputed related passages, each row with `is_ai_made', a
		method label and a model id (optional, read-only; D-015, D-016). No vector
		table ships in Release 1 (Q-06). Optional sources degrade, never fail:
		without it, related passages carry only non-AI reasons.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_AI_DATA_SOURCE

inherit
	BIB_DATA_SOURCE

create
	make

feature {NONE} -- Initialization

	make (a_path: READABLE_STRING_GENERAL)
			-- Describe ai_data.db at `a_path'.
		require
			path_not_empty: not a_path.is_empty
		do
			path := a_path.to_string_32
			create sqlite_version.make_empty
		ensure
			path_set: path.same_string_general (a_path)
			closed: not is_open
		end

feature -- Access

	alias_name: STRING_8
		do
			Result := "ai"
		end

	expected_schema_version: INTEGER
		do
			Result := Ai_schema_version
		end

feature -- Status

	has_vector_tables: BOOLEAN
			-- Does the file carry embedding vectors? (Never in Release 1.)
		do
			-- Phase 4
		end

feature -- Commands

	open_on (a_set: BIB_SOURCE_SET)
			-- Attach ai_data.db to `a_set'.
		do
			-- Phase 4
		ensure then
			no_vectors_in_release_1: is_open implies not has_vector_tables
		end

	close
		do
			-- Phase 4
		end

feature -- Constants

	Ai_schema_version: INTEGER = 1

end
