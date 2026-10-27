note
	description: "Queries, scopes and search guarantees (AC-1a-21, 22, 31)."
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_SEARCH

inherit
	TEST_SET_BASE

feature -- Tests

	test_query_parser_reads_boolean_and_keys
			-- B02 and B03: words side by side are AND; OR binds loosest; NOT takes away; parentheses
			-- group; strongs:, a bare Strong's number and lemma: become keys.
		local
			p: BIB_QUERY_PARSER
			q: BIB_QUERY
		do
			create p.make
			q := p.parsed ("grace peace", parser_scope)
			assert_true ("implicit AND", q.is_valid and then q.clause_count = 3 and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.And_clause)
			q := p.parsed ("grace OR mercy AND peace", parser_scope)
			assert_true ("OR loosest", q.is_valid and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.Or_clause and then q.clause (3).kind = {BIB_QUERY_CLAUSE}.And_clause)
			q := p.parsed ("grace NOT law", parser_scope)
			assert_true ("NOT inside AND", q.is_valid and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.And_clause and then q.clause (3).kind = {BIB_QUERY_CLAUSE}.Not_clause)
			q := p.parsed ("(grace OR mercy) AND peace", parser_scope)
			assert_true ("parentheses", q.is_valid and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.And_clause and then q.clause (2).kind = {BIB_QUERY_CLAUSE}.Or_clause)
			q := p.parsed ("%"in the beginning%"", parser_scope)
			assert_true ("a phrase", q.is_valid and then q.clause_count = 1 and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.Phrase)
			q := p.parsed ("strongs:g5485", parser_scope)
			assert_true ("strongs:, any case", q.is_valid and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.Strongs and then q.clause (1).text.same_string ("G5485"))
			q := p.parsed ("H7225 AND G746", parser_scope)
			assert_true ("bare Strong's numbers", q.is_valid and then q.key_clauses.count = 2)
			q := p.parsed ("lemma:charis", parser_scope)
			assert_true ("lemma:", q.is_valid and then q.clause (1).kind = {BIB_QUERY_CLAUSE}.Lemma)
			q := p.parsed ("and or not", parser_scope)
			assert_true ("lowercase operators are words", q.is_valid and then q.clause_count = 4)
		end

	test_query_parser_locates_errors
			-- VR-03..05: an error names its place.
		local
			p: BIB_QUERY_PARSER
		do
			create p.make
			assert_integers_equal ("dangling AND", 10, p.parsed ("grace AND", parser_scope).error_position)
			assert_integers_equal ("open parenthesis", 1, p.parsed ("(grace OR mercy", parser_scope).error_position)
			assert_integers_equal ("stray close", 6, p.parsed ("grace) peace", parser_scope).error_position)
			assert_integers_equal ("open quote", 7, p.parsed ("grace %"of God", parser_scope).error_position)
			assert_false ("NOT alone", p.parsed ("NOT law", parser_scope).is_valid)
			assert_false ("only NOTs", p.parsed ("NOT law NOT sin", parser_scope).is_valid)
			assert_false ("NOT in an OR branch", p.parsed ("grace OR NOT law", parser_scope).is_valid)
			assert_integers_equal ("operator first", 1, p.parsed ("AND grace", parser_scope).error_position)
			assert_integers_equal ("regex later", 7, p.parsed ("grace /gr.ce/", parser_scope).error_position)
			assert_true ("morph later", p.parsed ("morph:V-AAI-3S", parser_scope).error_message.has_substring ("later"))
			assert_false ("strongs: needs a number", p.parsed ("strongs:X1", parser_scope).is_valid)
			assert_false ("an empty phrase", p.parsed ("%"%"", parser_scope).is_valid)
		end

	test_query_states
		local
			q: BIB_QUERY
			l_key: BIB_LEMMA_KEY
		do
			create l_key.make ("grc", "ekklesia")
			create q.make_valid ("lemma:ekklesia", <<create {BIB_QUERY_CLAUSE}.make_key ({BIB_QUERY_CLAUSE}.Lemma, l_key)>>, nt_scope)
			assert ("valid", q.is_valid)
			assert ("mentions key", q.mentions_key (create {BIB_LEMMA_KEY}.make ("grc", "ekklesia")))
			assert_integers_equal ("one key clause", 1, q.key_clauses.count)
			assert ("no regex", not q.has_regex)
			create q.make_invalid ("lemma:", 7, "lemma expected", nt_scope)
			assert ("invalid", not q.is_valid)
			assert_integers_equal ("located", 7, q.error_position)
		end

	test_scope_contains_book_range
		local
			s: BIB_SEARCH_SCOPE
		do
			s := nt_scope
			assert ("john inside", s.contains (fx.ref (43, 3, 16)))
			assert ("genesis outside", not s.contains (fx.ref (1, 1, 1)))
			assert_integers_equal ("27 books", 27, s.book_count)
			assert ("scope label", not s.label.is_empty)
		end

	test_copied_phrase_finds_its_verse
			-- Skeletal (Phase 5, AC-1a-21): 200 fixed-seed verses per version; each verse's own display text
			-- (curly quotes, final forms, accents) finds that verse.
		do
		end

	test_strongs_padding_is_one_key
			-- AC-1a-22: H1 = H0001 = H00001 (one key); H6743a stays apart from H6743.
		local
			l_one, l_padded, l_more, l_plain, l_split: BIB_STRONGS_KEY
		do
			create l_one.make_from_text ("H1")
			create l_padded.make_from_text ("H0001")
			create l_more.make_from_text ("H00001")
			assert_true ("padded is one key", l_one.is_equal (l_padded) and l_one.is_equal (l_more))
			create l_plain.make_from_text ("H6743")
			create l_split.make_from_text ("H6743a")
			assert_false ("split sense apart", l_plain.is_equal (l_split))
		end

	test_split_senses_reported_apart
			-- Skeletal (Phase 5, AC-1a-22): 6743 and 6743a counted apart; unsplit Strong's count = lemma count.
		do
		end

	test_every_count_states_scope
			-- Skeletal (Phase 5, AC-1a-31): every count result's method has a non-empty scope label.
		do
		end

feature {NONE} -- Fixtures

	fx: TEST_FIXTURES
		once
			create Result
		end

	nt_scope: BIB_SEARCH_SCOPE
		do
			create Result.make ("NT, SBLGNT, word tokens", <<"SBLGNT">>, 40, 66, "word tokens")
		end

feature {NONE} -- Parser scope

	parser_scope: BIB_SEARCH_SCOPE
			-- One version, every book.
		once
			create Result.make ("verses", <<"KJV">>, 1, 66, "verses")
		end

end
