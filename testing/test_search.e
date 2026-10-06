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
			-- Skeletal (Phase 5, AC-1a-22): H1 = H0001 = H00001.
		do
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

end
