note
	description: "[
		One node of a query while BIB_QUERY_PARSER builds it: a clause and its
		children. Flattened into BIB_QUERY's pre-order clause list once the parse
		succeeds (BIB_QUERY_CLAUSE.make_operator counts its children).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_QUERY_NODE

create
	make_leaf, make_operator

feature {NONE} -- Initialization

	make_leaf (a_clause: BIB_QUERY_CLAUSE; a_position: INTEGER)
			-- A word, phrase or key, typed at `a_position'.
		require
			leaf: not a_clause.is_operator
			position_positive: a_position >= 1
		do
			position := a_position
			kind := a_clause.kind
			leaf_clause := a_clause
			create children.make (0)
		ensure
			no_children: children.is_empty
		end

	make_operator (a_kind: INTEGER; a_children: ARRAYED_LIST [BIB_QUERY_NODE]; a_position: INTEGER)
			-- AND, OR or NOT over `a_children', starting at `a_position'.
		require
			operator_kind: a_kind = {BIB_QUERY_CLAUSE}.And_clause or a_kind = {BIB_QUERY_CLAUSE}.Or_clause or a_kind = {BIB_QUERY_CLAUSE}.Not_clause
			arity: (a_kind = {BIB_QUERY_CLAUSE}.Not_clause implies a_children.count = 1) and (a_kind /= {BIB_QUERY_CLAUSE}.Not_clause implies a_children.count >= 2)
			position_positive: a_position >= 1
		do
			position := a_position
			kind := a_kind
			children := a_children
		ensure
			children_set: children = a_children
		end

feature -- Access

	kind: INTEGER
			-- A {BIB_QUERY_CLAUSE} kind.

	children: ARRAYED_LIST [BIB_QUERY_NODE]

	position: INTEGER
			-- Where the node starts in the query text (an error about it points there).

	leaf_clause: detachable BIB_QUERY_CLAUSE
			-- The clause of a leaf.

	is_negation: BOOLEAN
			-- Is this a NOT node?
		do
			Result := kind = {BIB_QUERY_CLAUSE}.Not_clause
		end

feature -- Conversion

	flatten_into (a_clauses: ARRAYED_LIST [BIB_QUERY_CLAUSE])
			-- Append this subtree to `a_clauses' in pre-order.
		do
			if attached leaf_clause as al_clause then
				a_clauses.extend (al_clause)
			else
				a_clauses.extend (create {BIB_QUERY_CLAUSE}.make_operator (kind, children.count))
				across children as ic loop
					ic.flatten_into (a_clauses)
				end
			end
		ensure
			grown: a_clauses.count > old a_clauses.count
		end

invariant
	leaf_or_operator: (leaf_clause /= Void) = children.is_empty

end
