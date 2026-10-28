note
	description: "[
		Search across Larry's writings (research/20, 2026-10-28): the commentary,
		frameworks and books packs, each through its own FTS5 table. A query in
		the Bible search's grammar (BIB_QUERY_PARSER: words, "phrases", word*,
		AND, OR, NOT, parentheses) becomes one FTS5 expression per pack; with
		`fuzzy', every plain word is widened to the pack's own words within an
		edit or two (BIB_EDIT_DISTANCE). `search' leaves the hits in `hits',
		packs in the order added and best first within each, one hit a place a
		reader can open (a commentary section's fields, a framework's sections:
		the best of them, 2026-10-28); a query that does
		not read is `error_message' at `error_position'. A pack built before its
		search table existed is passed over and named in `packs_without_search'.
		The contract NEEDLE asked for: search_writings(query, pack?, within?).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_WRITINGS_SEARCH

create
	make

feature {NONE} -- Initialization

	make (a_parser: BIB_QUERY_PARSER)
			-- A search with no packs yet, reading queries with `a_parser'.
		do
			parser := a_parser
			create packs.make (3)
			create hits.make (0)
			create error_message.make_empty
			create packs_without_search.make (0)
			create edits
		ensure
			no_packs: pack_count = 0
		end

feature -- Packs

	add_pack (a_pack: BIB_PRIVATE_PACK_READER; a_kind: READABLE_STRING_GENERAL)
			-- Search `a_pack' too, as a pack of kind `a_kind' ("commentary", "frameworks", "books").
		require
			kind_given: not a_kind.is_empty
		do
			packs.extend ([a_pack, a_kind.to_string_32])
		ensure
			one_more: pack_count = old pack_count + 1
		end

	pack_count: INTEGER
			-- The packs searched.
		do
			Result := packs.count
		end

feature -- Access

	hits: ARRAYED_LIST [BIB_WRITING_HIT]
			-- What the last `search' found.

	error_message: STRING_32
			-- Why the last query did not read; empty when it did.

	error_position: INTEGER
			-- Where in the query it stopped reading; 0 when it read.

	packs_without_search: ARRAYED_LIST [STRING_32]
			-- The titles of the packs the last `search' passed over: built without a search table.

	last_expression: STRING_32
			-- The last pack's FTS5 expression, for the method record and the tests.
		attribute
			create Result.make_empty
		end

	Max_hits_per_pack: INTEGER = 200
			-- The most hits one pack gives.

	Max_widening: INTEGER = 12
			-- The most words fuzzy search puts in a plain word's place.

feature -- Searching

	search (a_query: READABLE_STRING_GENERAL; a_fuzzy: BOOLEAN; a_pack_kind, a_within: READABLE_STRING_GENERAL)
			-- `hits': what `a_query' finds in every pack of kind `a_pack_kind' (empty: every pack)
			-- whose address begins `a_within' (empty: anywhere); with `a_fuzzy', a plain word also finds
			-- the pack's words an edit or two from it.
		require
			query_given: not a_query.is_empty
		local
			l_query: BIB_QUERY
			l_result: BIB_LIST_RESULT [BIB_WRITING_HIT]
			l_expression: STRING_32
			l_seen: ARRAYED_LIST [STRING_32]
			i: INTEGER
		do
			create hits.make (0)
			create packs_without_search.make (0)
			create error_message.make_empty
			error_position := 0
			l_query := parser.parsed (a_query, scope)
			if not l_query.is_valid then
				error_message := l_query.error_message.twin
				if error_message.is_empty then
					error_message := {STRING_32} "The query does not read."
				end
				error_position := l_query.error_position.max (1)
			else
				across packs as ic until not error_message.is_empty loop
					if (a_pack_kind.is_empty or else ic.kind.same_string_general (a_pack_kind)) and then ic.pack.is_available then
						if not ic.pack.has_search then
							packs_without_search.extend (ic.pack.title)
						else
							index := 1
							l_expression := expression (l_query, a_fuzzy, ic.pack)
							last_expression := l_expression
							if error_message.is_empty and then not l_expression.is_empty then
								l_result := ic.pack.searched (l_expression, a_within, ic.kind, Max_hits_per_pack)
								if l_result.is_success then
									create l_seen.make (l_result.count)
									l_seen.compare_objects
									from i := 1 until i > l_result.count loop
										if not l_seen.has (l_result.item (i).address) then
											l_seen.extend (l_result.item (i).address)
											hits.extend (l_result.item (i))
										end
										i := i + 1
									end
								end
							end
						end
					end
				end
			end
		ensure
			read_or_said: error_message.is_empty = (error_position = 0)
			nothing_on_error: not error_message.is_empty implies hits.is_empty
		end

feature {NONE} -- The FTS5 expression

	expression (a_query: BIB_QUERY; a_fuzzy: BOOLEAN; a_pack: BIB_PRIVATE_PACK_READER): STRING_32
			-- `a_query''s clauses (pre-order, from `index') as one FTS5 expression for `a_pack'.
		require
			valid: a_query.is_valid
		local
			l_clause: BIB_QUERY_CLAUSE
			l_positives, l_negatives: ARRAYED_LIST [STRING_32]
			l_part: STRING_32
			k: INTEGER
		do
			create Result.make_empty
			if index <= a_query.clause_count then
				l_clause := a_query.clause (index)
				index := index + 1
				if l_clause.kind = {BIB_QUERY_CLAUSE}.Or_clause then
					Result.append_character ('(')
					from k := 1 until k > l_clause.child_count loop
						if k > 1 then
							Result.append ({STRING_32} " OR ")
						end
						Result.append (expression (a_query, a_fuzzy, a_pack))
						k := k + 1
					end
					Result.append_character (')')
				elseif l_clause.kind = {BIB_QUERY_CLAUSE}.And_clause then
					create l_positives.make (l_clause.child_count)
					create l_negatives.make (1)
					from k := 1 until k > l_clause.child_count loop
						if index <= a_query.clause_count and then a_query.clause (index).kind = {BIB_QUERY_CLAUSE}.Not_clause then
							index := index + 1
							l_negatives.extend (expression (a_query, a_fuzzy, a_pack))
						else
							l_positives.extend (expression (a_query, a_fuzzy, a_pack))
						end
						k := k + 1
					end
					if l_positives.is_empty then
						fail ("NOT takes away from a word beside it: give it one.")
					else
						Result.append_character ('(')
						across l_positives as ic loop
							if not ic.is_empty then
								if Result.count > 1 then
									Result.append ({STRING_32} " AND ")
								end
								Result.append (ic)
							end
						end
						Result.append_character (')')
						across l_negatives as ic loop
							Result.append ({STRING_32} " NOT " + ic)
						end
					end
				elseif l_clause.kind = {BIB_QUERY_CLAUSE}.Not_clause then
					fail ("NOT takes away from a word beside it: give it one.")
				elseif l_clause.kind = {BIB_QUERY_CLAUSE}.Phrase then
					Result := quoted (l_clause.text)
				elseif l_clause.kind = {BIB_QUERY_CLAUSE}.Word then
					l_part := l_clause.text.twin
					if l_part.ends_with ({STRING_32} "*") then
						l_part.remove_tail (1)
						Result := quoted (l_part) + {STRING_32} "*"
					elseif a_fuzzy then
						Result := widened (l_part, a_pack)
					else
						Result := quoted (l_part)
					end
				else
						-- A Strong's number, a lemma, a morphology code: searched as written.
					Result := quoted (l_clause.text)
				end
			end
		end

	widened (a_word: STRING_32; a_pack: BIB_PRIVATE_PACK_READER): STRING_32
			-- `a_word' or the pack's words up to `limit_for' edits from it, closest first, at most
			-- `Max_widening': "(%"remember%" OR %"remembers%")".
		local
			l_word: STRING_32
			l_limit, l_distance, d: INTEGER
			l_near: ARRAYED_LIST [STRING_32]
		do
			l_word := a_word.as_lower
			l_limit := edits.limit_for (l_word)
			create l_near.make (Max_widening)
			l_near.compare_objects
			l_near.extend (l_word)
			if l_limit > 0 then
				from d := 0 until d > l_limit or l_near.count >= Max_widening loop
					across a_pack.words as ic until l_near.count >= Max_widening loop
						l_distance := edits.distance (l_word, ic, l_limit)
						if l_distance = d and then not l_near.has (ic) then
							l_near.extend (ic)
						end
					end
					d := d + 1
				end
			end
			if l_near.count = 1 then
				Result := quoted (l_word)
			else
				create Result.make (l_near.count * 12)
				Result.append_character ('(')
				across l_near as ic loop
					if Result.count > 1 then
						Result.append ({STRING_32} " OR ")
					end
					Result.append (quoted (ic))
				end
				Result.append_character (')')
			end
		end

	quoted (a_text: READABLE_STRING_32): STRING_32
			-- `a_text' as one FTS5 string: in double quotes, a double quote inside doubled.
		do
			create Result.make (a_text.count + 2)
			Result.append_character ('"')
			across a_text as ic loop
				if ic = '"' then
					Result.append_character ('"')
				end
				Result.append_character (ic)
			end
			Result.append_character ('"')
		ensure
			in_quotes: Result.starts_with ({STRING_32} "%"") and Result.ends_with ({STRING_32} "%"")
		end

	fail (a_message: READABLE_STRING_GENERAL)
			-- The query does not read as a writings search: `a_message' (the first failure stands).
		do
			if error_message.is_empty then
				error_message := a_message.to_string_32
				error_position := 1
			end
		end

feature {NONE} -- Implementation

	parser: BIB_QUERY_PARSER
			-- Reads the query.

	packs: ARRAYED_LIST [TUPLE [pack: BIB_PRIVATE_PACK_READER; kind: STRING_32]]
			-- The packs searched, in order.

	edits: BIB_EDIT_DISTANCE

	index: INTEGER
			-- The next clause `expression' reads.

	scope: BIB_SEARCH_SCOPE
			-- The parser's scope: the writings are not a Bible version.
		once
			create Result.make ("Larry's writings", create {ARRAYED_LIST [STRING_8]}.make (0), 1, 66, "passages")
		end

invariant
	error_placed: error_message.is_empty = (error_position = 0)

end
