note
	description: "[
		An immutable query: canonical text, clause tree in pre-order, scope, and
		validity with a positioned error (VR-03..05). Built by BIB_QUERY_PARSER.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUERY

create
	make_valid, make_invalid, make_empty

feature {NONE} -- Initialization

	make_valid (a_text: READABLE_STRING_GENERAL; a_clauses: ITERABLE [BIB_QUERY_CLAUSE]; a_scope: BIB_SEARCH_SCOPE)
			-- Valid query `a_text' with its clause tree.
		require
			text_not_empty: not a_text.is_empty
			has_clauses: across a_clauses as c some True end
		do
			text := a_text.to_string_32
			scope := a_scope
			is_valid := True
			create error_message.make_empty
			create clauses.make (4)
			across a_clauses as c loop
				clauses.extend (c)
			end
		ensure
			valid: is_valid
			scope_set: scope = a_scope
		end

	make_invalid (a_text: READABLE_STRING_GENERAL; a_position: INTEGER; a_message: READABLE_STRING_GENERAL; a_scope: BIB_SEARCH_SCOPE)
			-- Invalid query with the error at `a_position'.
		require
			position_located: a_position >= 1 and a_position <= a_text.count + 1
			message_not_empty: not a_message.is_empty
		do
			text := a_text.to_string_32
			scope := a_scope
			error_position := a_position
			error_message := a_message.to_string_32
			create clauses.make (0)
		ensure
			invalid: not is_valid
			position_set: error_position = a_position
		end

	make_empty (a_scope: BIB_SEARCH_SCOPE)
			-- No criteria yet (a new census definition).
		do
			create text.make_empty
			scope := a_scope
			create error_message.make_empty
			create clauses.make (0)
		ensure
			empty: clause_count = 0 and not is_valid
		end

feature -- Access

	text: STRING_32
	scope: BIB_SEARCH_SCOPE
	error_position: INTEGER
	error_message: STRING_32

	clause_count: INTEGER
		do
			Result := clauses.count
		ensure
			model_agrees: Result = clauses_model.count
		end

	key_clauses: ARRAYED_LIST [BIB_QUERY_CLAUSE]
			-- The lemma, Strong's and morphology clauses, in order.
		do
			create Result.make (2)
			across clauses as c loop
				if c.is_key_clause then
					Result.extend (c)
				end
			end
		ensure
			only_keys: across Result as c all c.is_key_clause end
		end

feature -- Status

	is_valid: BOOLEAN

	has_regex: BOOLEAN
		do
			Result := across clauses as c some c.kind = {BIB_QUERY_CLAUSE}.Regex end
		end

	mentions_key (a_key: BIB_KEY): BOOLEAN
			-- Does any key clause name `a_key'?
		do
			Result := across clauses as c some attached c.key as k and then k ~ a_key end
		end

feature -- Model

	clauses_model: MML_SEQUENCE [BIB_QUERY_CLAUSE]
			-- Clause tree in pre-order.
		do
			create Result
			across clauses as c loop
				Result := Result & c
			end
		end

feature {NONE} -- Representation

	clauses: ARRAYED_LIST [BIB_QUERY_CLAUSE]

invariant
	valid_has_clauses: is_valid implies clause_count > 0
	valid_has_text: is_valid implies not text.is_empty
	invalid_not_parsed: not is_valid implies clause_count = 0

end
