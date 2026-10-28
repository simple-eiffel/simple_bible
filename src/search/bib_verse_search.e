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

	BIB_CLAUSE_WALKING [ARRAYED_LIST [INTEGER_64]]

create
	make

feature {NONE} -- Initialization

	make (a_reader: BIB_TEXT_READER; a_pack: BIB_CONC_PACK; a_map: BIB_VERSIFICATION_MAP)
			-- A search over `a_reader''s versions and `a_pack''s roots, moving Hebrew places to English
			-- verse numbers by `a_map' where the version read uses them.
		do
			reader := a_reader
			pack := a_pack
			map := a_map
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

	map: BIB_VERSIFICATION_MAP
			-- Hebrew to English verse numbers (STEPBible TVTMS).

	has_moved_hebrew_roots: BOOLEAN
			-- Did the last `find' move Hebrew places to English verse numbers?

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
			has_moved_hebrew_roots := False
			cursor := 1
			walk_version := a_version.to_string_8
			places := within_scope (walked (a_query, False), a_query.scope)
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

	reads_english_numbers (a_version: READABLE_STRING_8): BOOLEAN
			-- Does `a_version' number verses the English (KJV family) way?
		do
			Result := attached reader.version (a_version) as al_version and then al_version.numbers_like_english
		end

	english_places (a_hebrew: ARRAYED_LIST [INTEGER_64]): ARRAYED_LIST [INTEGER_64]
			-- `a_hebrew' moved to English verse numbers, ascending, once each.
		local
			l_moved: ARRAYED_LIST [INTEGER_64]
		do
			create l_moved.make (a_hebrew.count)
			across a_hebrew as ic loop
				l_moved.extend (map.english_place (ic))
			end
			Result := sorted_once (l_moved)
		end

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

	walk_version: STRING_8
			-- The version the query's words are read in, while `find' walks it.
		attribute
			create Result.make_empty
		end

	nothing: ARRAYED_LIST [INTEGER_64]
			-- No places.
		do
			create Result.make (0)
		end

	leaf (a_clause: BIB_QUERY_CLAUSE; a_negated: BOOLEAN): ARRAYED_LIST [INTEGER_64]
			-- The places a word or phrase (in `walk_version') or a key clause names; `a_negated' under
			-- a NOT, where a root's corpus does not count toward the notes.
		local
			l_roots: BIB_ROOT_PLACES
		do
			create Result.make (0)
			if a_clause.kind = {BIB_QUERY_CLAUSE}.Word or a_clause.kind = {BIB_QUERY_CLAUSE}.Phrase then
				if attached reader.verse_places_matching (walk_version, a_clause.text) as al_places then
					Result := al_places
				else
					refuse ("The verse index could not be searched.")
				end
			elseif a_clause.is_key_clause then
				if not pack.is_available then
					refuse ("No concordance is attached, so root words cannot be searched.")
				elseif attached a_clause.key as al_key then
					l_roots := pack.key_places (al_key)
					if l_roots.has_failed then
							-- Design scan 48: a failed root query read as "no verse matches".
						refuse ({STRING_32} "The concordance could not be searched for " + a_clause.text + {STRING_32} ".")
					else
						if l_roots.has_hebrew and then map.has_hebrew_map and then reads_english_numbers (walk_version) then
								-- The version numbers verses the English way: the Hebrew side moves first.
							Result := union (english_places (l_roots.hebrew_places), l_roots.greek_places)
							if not a_negated then
								has_moved_hebrew_roots := True
							end
						else
							Result := l_roots.places
							if not a_negated then
								has_hebrew_roots := has_hebrew_roots or l_roots.has_hebrew
							end
						end
						if not a_negated then
							has_greek_roots := has_greek_roots or l_roots.has_greek
						end
					end
				end
			else
				refuse ("This kind of search is not read yet.")
			end
		end

	any_of (a_parts: ARRAYED_LIST [ARRAYED_LIST [INTEGER_64]]): ARRAYED_LIST [INTEGER_64]
			-- Every place any part names.
		local
			i: INTEGER
		do
			Result := a_parts.first
			from i := 2 until i > a_parts.count loop
				Result := union (Result, a_parts.i_th (i))
				i := i + 1
			end
		end

	all_of_but (a_parts, a_taken_away: ARRAYED_LIST [ARRAYED_LIST [INTEGER_64]]): ARRAYED_LIST [INTEGER_64]
			-- The places every part names, less those any taken-away part names.
		local
			i: INTEGER
		do
			Result := a_parts.first
			from i := 2 until i > a_parts.count loop
				Result := intersection (Result, a_parts.i_th (i))
				i := i + 1
			end
			across a_taken_away as ic loop
				Result := difference (Result, ic)
			end
		end

	walk_failed: BOOLEAN
			-- Has the search failed?
		do
			Result := has_failed
		end

	refuse (a_message: READABLE_STRING_GENERAL)
			-- `error_message' says `a_message', unless a failure already stands.
		do
			if error_message.is_empty then
				error_message := a_message.to_string_32
			end
		end

end
