note
	description: "[
		Every verse a query names (B02 Boolean, B03 root words): the clause tree
		of BIB_QUERY_PARSER evaluated as sets of verse places (BIB_PLACE_PACKING,
		BIB_PLACE_SETS). Words and phrases come from the version's verse index
		(BIB_TEXT_READER); strongs: and lemma: clauses from the concordance pack,
		by key and never by display string (FR-023, FR-024). AND keeps the verses
		every operand names, OR every verse any names, NOT takes its operand's
		verses away. Hebrew roots stand in Hebrew verse numbers until the
		versification map arrives, and Greek roots are read in the concordance's
		critical text; `has_hebrew_roots' and `has_greek_roots' say when a result
		holds them (a root under NOT adds no verse, so it does not count).
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	BIB_VERSE_SEARCH

inherit
	BIB_PLACE_SETS

create
	make

feature {NONE} -- Initialization

	make (a_reader: BIB_TEXT_READER; a_pack: BIB_CONC_PACK)
			-- A search over `a_reader''s versions and `a_pack''s roots.
		do
			reader := a_reader
			pack := a_pack
			create places.make (0)
			create error_message.make_empty
		ensure
			reader_set: reader = a_reader
			pack_set: pack = a_pack
		end

feature -- Access

	reader: BIB_TEXT_READER
			-- The versions and their verse indexes.

	pack: BIB_CONC_PACK
			-- The concordance, for root words.

	places: ARRAYED_LIST [INTEGER_64]
			-- The verses the last `find' named, packed, ascending, each once.

	has_hebrew_roots: BOOLEAN
			-- Did the last `find' add verses through a Hebrew root (Hebrew verse numbers)?

	has_greek_roots: BOOLEAN
			-- Did the last `find' add verses through a Greek root (the critical Greek text)?

	error_message: STRING_32
			-- Why the last `find' failed; empty when it did not.

	has_failed: BOOLEAN
			-- Did the last `find' fail?
		do
			Result := not error_message.is_empty
		end

feature -- Searching

	find (a_query: BIB_QUERY; a_version: READABLE_STRING_8)
			-- Every verse `a_query' names, words read in `a_version'.
		require
			query_valid: a_query.is_valid
			version_known: reader.has_version (a_version)
		do
			create error_message.make_empty
			has_hebrew_roots := False
			has_greek_roots := False
			cursor := 1
			places := within_scope (evaluated (a_query, a_version, False), a_query.scope)
			if has_failed then
				create places.make (0)
			end
		ensure
			ascending_once: is_ascending (places)
			empty_on_failure: has_failed implies places.is_empty
			in_scope: across places as ic all a_query.scope.contains_book (keys.book_part (ic)) end
		end

	verses (a_version: READABLE_STRING_8; a_from, a_limit: INTEGER): BIB_LIST_RESULT [BIB_READING_VERSE]
			-- `places' from the `a_from'th, at most `a_limit', as verses of `a_version'.
		require
			version_known: reader.has_version (a_version)
			from_positive: a_from >= 1
			limit_in_range: a_limit >= 1 and a_limit <= reader.Max_places_per_read
		local
			l_page: ARRAYED_LIST [INTEGER_64]
			i: INTEGER
		do
			create l_page.make (a_limit)
			from i := a_from until i > places.count or l_page.count = a_limit loop
				l_page.extend (places.i_th (i))
				i := i + 1
			end
			Result := reader.verses_at_places (a_version, l_page)
		ensure
			bounded: Result.count <= a_limit
		end

feature {NONE} -- Evaluation

	keys: BIB_VERSE_KEY
			-- Reads the book of a place.
		once ("OBJECT")
			create Result
		end

	within_scope (a_places: ARRAYED_LIST [INTEGER_64]; a_scope: BIB_SEARCH_SCOPE): ARRAYED_LIST [INTEGER_64]
			-- The places of `a_places' whose book lies in `a_scope' (NEEDLE run 7's scope: a book, a
			-- testament, the Gospels, Paul's letters; BIB_SEARCH_SCOPES names them).
		do
			create Result.make (a_places.count)
			across a_places as ic loop
				if a_scope.contains_book (keys.book_part (ic)) then
					Result.extend (ic)
				end
			end
		end

	cursor: INTEGER
			-- The next clause of the query being evaluated (pre-order).

	evaluated (a_query: BIB_QUERY; a_version: READABLE_STRING_8; a_negated: BOOLEAN): ARRAYED_LIST [INTEGER_64]
			-- The places of the subtree at `cursor', which moves past it; `a_negated' when the subtree
			-- stands under a NOT.
		local
			l_clause: BIB_QUERY_CLAUSE
			l_positives, l_negatives: ARRAYED_LIST [ARRAYED_LIST [INTEGER_64]]
			l_roots: BIB_ROOT_PLACES
			i: INTEGER
		do
			create Result.make (0)
			if cursor <= a_query.clause_count and not has_failed then
				l_clause := a_query.clause (cursor)
				cursor := cursor + 1
				inspect l_clause.kind
				when {BIB_QUERY_CLAUSE}.Word, {BIB_QUERY_CLAUSE}.Phrase then
					if attached reader.verse_places_matching (a_version, l_clause.text) as al_places then
						Result := al_places
					else
						error_message := {STRING_32} "The verse index could not be searched."
					end
				when {BIB_QUERY_CLAUSE}.Strongs, {BIB_QUERY_CLAUSE}.Lemma, {BIB_QUERY_CLAUSE}.Morph then
					if not pack.is_available then
						error_message := {STRING_32} "No concordance is attached, so root words cannot be searched."
					elseif attached l_clause.key as al_key then
						l_roots := pack.key_places (al_key)
						if l_roots.has_failed then
								-- Design scan 48: a failed root query read as "no verse matches".
							error_message := {STRING_32} "The concordance could not be searched for " + l_clause.text + {STRING_32} "."
						else
							Result := l_roots.places
							if not a_negated then
								has_hebrew_roots := has_hebrew_roots or l_roots.has_hebrew
								has_greek_roots := has_greek_roots or l_roots.has_greek
							end
						end
					end
				when {BIB_QUERY_CLAUSE}.Or_clause then
					from i := 1 until i > l_clause.child_count loop
						Result := union (Result, evaluated (a_query, a_version, a_negated))
						i := i + 1
					end
				when {BIB_QUERY_CLAUSE}.And_clause then
					create l_positives.make (l_clause.child_count)
					create l_negatives.make (1)
					from i := 1 until i > l_clause.child_count loop
						if cursor <= a_query.clause_count and then a_query.clause (cursor).kind = {BIB_QUERY_CLAUSE}.Not_clause then
							cursor := cursor + 1
							l_negatives.extend (evaluated (a_query, a_version, not a_negated))
						else
							l_positives.extend (evaluated (a_query, a_version, a_negated))
						end
						i := i + 1
					end
					if not l_positives.is_empty then
						Result := l_positives.first
						from i := 2 until i > l_positives.count loop
							Result := intersection (Result, l_positives.i_th (i))
							i := i + 1
						end
						across l_negatives as ic loop
							Result := difference (Result, ic)
						end
					end
				else
						-- A NOT outside an AND: the parser refuses it (`check_negations').
					error_message := {STRING_32} "NOT needs something to take away from."
				end
			end
		end

end
