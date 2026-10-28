note
	description: "[
		A query's clause tree walked once (design scan 61): the parser's clauses in
		pre-order (BIB_QUERY), OR over its children, AND over its children with the
		NOT children peeled off to be taken away, a leaf handed to the heir. The heir
		says what a leaf is and how parts combine: BIB_VERSE_SEARCH as sets of verse
		places, BIB_WRITINGS_SEARCH as one FTS5 expression. Before, each walked the
		tree itself and the two copies had drifted. A NOT outside an AND, or an AND of
		NOTs alone, is refused by the parser (`check_negations'); here it is refused
		again rather than walked.
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

deferred class
	BIB_CLAUSE_WALKING [G]

feature {NONE} -- Walking

	cursor: INTEGER
			-- The next clause of the query being walked (pre-order).

	walked (a_query: BIB_QUERY; a_negated: BOOLEAN): G
			-- The subtree at `cursor', which moves past it; `a_negated' when it stands under a NOT.
			-- `nothing' once the walk has failed.
		require
			valid: a_query.is_valid
		local
			l_clause: BIB_QUERY_CLAUSE
			l_parts, l_negatives: ARRAYED_LIST [G]
			i: INTEGER
		do
			Result := nothing
			if cursor >= 1 and cursor <= a_query.clause_count and not walk_failed then
				l_clause := a_query.clause (cursor)
				cursor := cursor + 1
				if l_clause.kind = {BIB_QUERY_CLAUSE}.Or_clause then
					create l_parts.make (l_clause.child_count)
					from i := 1 until i > l_clause.child_count loop
						l_parts.extend (walked (a_query, a_negated))
						i := i + 1
					end
					if not walk_failed then
						Result := any_of (l_parts)
					end
				elseif l_clause.kind = {BIB_QUERY_CLAUSE}.And_clause then
					create l_parts.make (l_clause.child_count)
					create l_negatives.make (1)
					from i := 1 until i > l_clause.child_count loop
						if cursor <= a_query.clause_count and then a_query.clause (cursor).kind = {BIB_QUERY_CLAUSE}.Not_clause then
							cursor := cursor + 1
							l_negatives.extend (walked (a_query, not a_negated))
						else
							l_parts.extend (walked (a_query, a_negated))
						end
						i := i + 1
					end
					if l_parts.is_empty then
						refuse ("NOT needs something to take away from.")
					elseif not walk_failed then
						Result := all_of_but (l_parts, l_negatives)
					end
				elseif l_clause.kind = {BIB_QUERY_CLAUSE}.Not_clause then
					refuse ("NOT needs something to take away from.")
				else
					Result := leaf (l_clause, a_negated)
				end
			end
		ensure
			moved_on: cursor >= old cursor
		end

feature {NONE} -- The heir's part

	nothing: G
			-- What an empty or failed walk gives.
		deferred
		end

	leaf (a_clause: BIB_QUERY_CLAUSE; a_negated: BOOLEAN): G
			-- What a word, phrase or key clause finds; `a_negated' under a NOT.
		require
			a_leaf: not a_clause.is_operator
		deferred
		end

	any_of (a_parts: ARRAYED_LIST [G]): G
			-- What any of `a_parts' finds (OR).
		require
			some_part: not a_parts.is_empty
		deferred
		end

	all_of_but (a_parts, a_taken_away: ARRAYED_LIST [G]): G
			-- What every one of `a_parts' finds, less what any of `a_taken_away' finds (AND, NOT).
		require
			some_part: not a_parts.is_empty
		deferred
		end

	walk_failed: BOOLEAN
			-- Has the walk failed?
		deferred
		end

	refuse (a_message: READABLE_STRING_GENERAL)
			-- The walk fails, saying `a_message' (the first failure stands).
		deferred
		ensure
			failed: walk_failed
		end

end
